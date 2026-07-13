CAI.Cover = CAI.Cover or {}
local CV = CAI.Cover

local spotCache = {}

local function GatherSpots(origin)
    local cfg = CAI.Config.Cover
    local out = {}
    local areas = navmesh.Find(origin, cfg.SearchRadius, 60, 120) or {}

    for _, area in ipairs(areas) do
        if IsValid(area) then
            local id = area:GetID()
            local cached = spotCache[id]
            if not cached or CurTime() - cached.t > cfg.CacheLifetime then
                local spots = area:GetHidingSpots() or {}

                cached = { spots = spots, t = CurTime() }
                spotCache[id] = cached
            end
            for _, s in ipairs(cached.spots) do out[#out + 1] = s end
        end
    end

    for _, prop in ipairs(ents.FindInSphere(origin, cfg.SearchRadius)) do
        if prop:GetClass() == "prop_physics" and IsValid(prop:GetPhysicsObject()) then
            local mins, maxs = prop:OBBMins(), prop:OBBMaxs()
            local size = (maxs - mins):Length()
            if size > 70 then
                out[#out + 1] = prop:GetPos()
            end
        end
    end
    return out
end

function CV.ScoreSpot(data, spot, enemy, enemyPos)
    local cfg = CAI.Config.Cover
    local W = cfg.Weights
    local npc = data.ent
    local score = 0

    local dSelf = npc:GetPos():Distance(spot)
    score = score + W.distSelf * (1 - math.Clamp(dSelf / cfg.SearchRadius, 0, 1))

    local dEnemy = enemyPos and spot:Distance(enemyPos) or cfg.IdealEnemyDist
    if dEnemy < cfg.MinEnemyDist then
        score = score - W.distEnemy * 1.5
    else
        local ideal = data.enemyWeaponResponse and data.enemyWeaponResponse.idealDist or cfg.IdealEnemyDist
        score = score + W.distEnemy * (1 - math.Clamp(math.abs(dEnemy - ideal) / ideal, 0, 1))
    end

    if IsValid(enemy) and enemyPos then
        local visible = CAI.Util.CanSeePos(enemy, spot)
        score = score + (visible and -W.losBlocked * 0.5 or W.losBlocked)
    end

    if data.squad then
        for _, member in ipairs(data.squad.members) do
            if IsValid(member) and member ~= npc
               and member:GetPos():DistToSqr(spot) < cfg.AllyCrowdDist * cfg.AllyCrowdDist then
                score = score - W.crowding
            end
        end
    end

    if CAI.Memory.InDanger(data, spot) then
        score = score - W.danger
    end

    local open = 0
    for _, dir in ipairs({ Vector(1,0,0), Vector(-1,0,0), Vector(0,1,0), Vector(0,-1,0) }) do
        local tr = util.TraceLine({
            start = spot + Vector(0,0,48),
            endpos = spot + Vector(0,0,48) + dir * 300,
            mask = MASK_SOLID_BRUSHONLY,
        })
        if not tr.Hit then open = open + 1 end
    end
    score = score - W.flankRisk * (open / 4) * 0.8

    score = score + W.history * CAI.Battlefield.CoverHistory(data.squad, spot)

    return score
end

function CV.FindBest(data, enemy, enemyPos)
    if not CAI.CVBool("cai_cover") then return nil end
    local classInfo = CAI.Config.NPCClasses[data.ent:GetClass()]
    if classInfo and classInfo.noCover then return nil end

    local spots = GatherSpots(data.ent:GetPos())
    if #spots == 0 then return nil end

    local best, bestScore = nil, -math.huge

    local step = math.max(1, math.floor(#spots / 24))
    for i = 1, #spots, step do
        local s = CV.ScoreSpot(data, spots[i], enemy, enemyPos)
        if s > bestScore then best, bestScore = spots[i], s end
    end
    return best, bestScore
end

function CV.UpdateCoverStatus(data, enemy)
    if not data.cover then return end
    local cfg = CAI.Config.Cover

    if IsValid(enemy) and CAI.Util.CanSee(enemy, data.ent) then
        data.cover.exposedSince = data.cover.exposedSince or CurTime()
        if CurTime() - data.cover.exposedSince > cfg.CompromiseTime then

            CAI.Battlefield.MarkCover(data.squad, data.cover.pos, false)
            CAI.Memory.AddDanger(data, data.cover.pos, 150, "compromised_cover")
            data.cover = nil
            data.forceRecover = true

            local newPos = CV.FindBest(data, enemy, IsValid(enemy) and enemy:GetPos() or nil)
            if newPos then
                data.cover = { pos = newPos, since = CurTime() }
                data.forceRecover = nil
                CAI.Nav.MoveTo(data, newPos, "run")
                CAI.Brain.SetState(data, CAI.STATE.COVER, "cover_blown_relocate")
            end
        end
    else
        data.cover.exposedSince = nil

        if not data.cover.credited and CurTime() - data.cover.since > 6 then
            CAI.Battlefield.MarkCover(data.squad, data.cover.pos, true)
            data.cover.credited = true
        end
    end
end
