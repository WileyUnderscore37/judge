CAI.Search = CAI.Search or {}
local SE = CAI.Search

function SE.BuildPoints(lkp)
    local cfg = CAI.Config.Search
    local areas = navmesh.Find(lkp, cfg.PointRadius, 200, 250) or {}
    local scored = {}

    for _, area in ipairs(areas) do
        if IsValid(area) then
            local p = area:GetCenter()
            local s = math.Rand(0, 0.3)
            s = s + (1 - math.Clamp(p:Distance(lkp) / cfg.PointRadius, 0, 1))
            s = s + math.min(math.abs(p.z - lkp.z) / 128, 1) * cfg.VerticalBonus
            scored[#scored + 1] = { pos = p, s = s }
        end
    end
    if #scored == 0 then
        for i = 1, 8 do
            local ang = (i / 8) * 360
            local dir = Angle(0, ang, 0):Forward()
            local p = lkp + dir * math.Rand(180, cfg.PointRadius * 0.7)
            local tr = util.TraceLine({
                start = p + Vector(0, 0, 48),
                endpos = p - Vector(0, 0, 160),
                mask = MASK_SOLID_BRUSHONLY,
            })
            if tr.Hit then
                scored[#scored + 1] = { pos = tr.HitPos + Vector(0, 0, 4), s = math.Rand(0, 1) }
            end
        end
    end

    table.sort(scored, function(a, b) return a.s > b.s end)

    local points = { lkp }
    for i = 1, math.min(cfg.MaxPoints - 1, #scored) do
        points[#points + 1] = scored[i].pos
    end
    return points
end

function SE.Begin(data, enemy, lkp)
    if not CAI.CVBool("cai_search") then return false end
    data.search = {
        target = enemy,
        lkp = lkp,
        points = SE.BuildPoints(lkp),
        idx = 1,
        started = CurTime(),
        dwellEnd = 0,
    }

    local npc = data.ent
    if npc.SetTarget then npc:SetSchedule(SCHED_COMBAT_FACE) end
    CAI.Nav.MoveTo(data, data.search.points[1], "run")
    CAI.Voice.Speak(data, "searching")
    if data.squad then
        CAI.Squad.Broadcast(data.squad, "enemy_lost", data.ent, { pos = lkp })
    end
    return true
end

function SE.Abandon(data, s)
    data.search = nil
    local npc = data.ent
    if IsValid(s.target) then
        data.memory.enemies[s.target] = nil
        if npc.ClearEnemyMemory then npc:ClearEnemyMemory(s.target) end
    end
    if npc.SetEnemy then npc:SetEnemy(NULL) end
    if npc.SetNPCState then npc:SetNPCState(NPC_STATE_ALERT) end
end

function SE.Update(data)
    local s = data.search
    if not s then return false end
    local cfg = CAI.Config.Search

    if IsValid(s.target) and CAI.Util.CanSee(data.ent, s.target) then
        data.search = nil
        return false
    end

    if IsValid(s.target) then
        local rec = data.memory.enemies[s.target]
        if rec and rec.pos and s.lkp and rec.pos:DistToSqr(s.lkp) > 300 * 300 then
            return SE.Begin(data, s.target, rec.pos)
        end
    end

    if CurTime() - s.started > cfg.GiveUpAfter then
        SE.Abandon(data, s)
        CAI.Voice.Speak(data, "enemy_lost")
        return false
    end

    if CAI.Nav.Arrived(data, 90) then
        if s.dwellEnd == 0 then

            s.dwellEnd = CurTime() + cfg.DwellTime
            data.ent:SetSchedule(SCHED_COMBAT_FACE)
        elseif CurTime() > s.dwellEnd then
            s.idx = s.idx + 1
            s.dwellEnd = 0
            if s.idx > #s.points then
                SE.Abandon(data, s)
                CAI.Voice.Speak(data, "enemy_lost")
                return false
            end
            CAI.Nav.MoveTo(data, s.points[s.idx], "run")
        end
    end
    return true
end
