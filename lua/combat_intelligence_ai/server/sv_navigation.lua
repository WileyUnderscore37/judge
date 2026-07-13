CAI.Nav = CAI.Nav or {}
local N = CAI.Nav

function N.MoveTo(data, pos, mode)
    local npc = data.ent
    if not IsValid(npc) or not pos then return false end

    local sched = mode == "walk" and SCHED_FORCED_GO or SCHED_FORCED_GO_RUN
    if data.moveTarget and data.moveTarget:DistToSqr(pos) < 48 * 48
       and CurTime() - (data.moveIssuedAt or 0) < 2
       and npc.IsCurrentSchedule and npc:IsCurrentSchedule(sched) then
        return true
    end

    npc:SetLastPosition(pos)
    npc:SetSchedule(sched)
    data.moveTarget = pos
    data.moveIssuedAt = CurTime()
    data.stuckPos = npc:GetPos()
    data.stuckChecks = 0
    return true
end

function N.Arrived(data, tolerance)
    if not data.moveTarget then return true end
    tolerance = tolerance or 70
    return data.ent:GetPos():DistToSqr(data.moveTarget) < tolerance * tolerance
end

function N.CheckStuck(data)
    local npc = data.ent
    if not data.moveTarget or N.Arrived(data) then
        data.stuckChecks = 0
        return false
    end
    if CurTime() - (data.moveIssuedAt or 0) < 1.5 then return false end

    local moved = npc:GetPos():DistToSqr(data.stuckPos or npc:GetPos())
    data.stuckPos = npc:GetPos()

    if moved < 20 * 20 then
        data.stuckChecks = (data.stuckChecks or 0) + 1
    else
        data.stuckChecks = 0
    end

    if data.stuckChecks >= 3 then
        N.Recover(data)
        return true
    end
    return false
end

function N.Recover(data)
    local npc = data.ent
    data.stuckChecks = 0

    if data.squad then
        CAI.Battlefield.ReportDanger(data.squad, npc:GetPos(), 100, "blocked_path")
        local bp = data.squad.blackboard.blockedPaths
        bp[#bp + 1] = { pos = npc:GetPos(), t = CurTime() }
        if #bp > 10 then table.remove(bp, 1) end
    end

    local area = navmesh.GetNearestNavArea(npc:GetPos())
    if IsValid(area) then
        local neighbors = area:GetAdjacentAreas()
        if neighbors and #neighbors > 0 then
            local pick = neighbors[math.random(#neighbors)]
            if IsValid(pick) then
                data.moveTarget = nil
                N.MoveTo(data, pick:GetRandomPoint(), "run")
                return
            end
        end
    end

    data.moveTarget = nil
    npc:SetSchedule(SCHED_TAKE_COVER_FROM_ENEMY)
end

function N.RandomPointNear(origin, radius)
    local areas = navmesh.Find(origin, radius, 60, 120)
    if not areas or #areas == 0 then return nil end
    local area = areas[math.random(#areas)]
    if not IsValid(area) then return nil end
    return area:GetRandomPoint()
end

function N.EnableDoorUse(npc)
    if npc.CapabilitiesAdd then
        npc:CapabilitiesAdd(bit.bor(CAP_OPEN_DOORS or 0, CAP_AUTO_DOORS or 0, CAP_MOVE_GROUND or 0, CAP_MOVE_JUMP or 0))
    end
end
