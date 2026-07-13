CAI.Squad = CAI.Squad or {}
local SQ = CAI.Squad

SQ.Squads = SQ.Squads or {}
local nextID = 1

local GROUP_RADIUS = 900

function SQ.Create(faction)
    local squad = {
        id = nextID, faction = faction,
        members = {}, leader = nil,
        blackboard = CAI.Battlefield.New(),
        formation = "WEDGE",
        lastPlan = 0, plan = "hold",
        lastVoiceAt = 0,
    }
    nextID = nextID + 1
    SQ.Squads[squad.id] = squad
    return squad
end

function SQ.AddMember(squad, npc)
    local data = CAI.Manager.Get(npc)
    if not data then return end
    if data.squad == squad then return end
    if data.squad then SQ.RemoveMember(data.squad, npc) end

    if npc.AddEntityRelationship then
        for _, m in ipairs(squad.members) do
            if IsValid(m) then
                npc:AddEntityRelationship(m, D_LI, 99)
                if m.AddEntityRelationship then
                    m:AddEntityRelationship(npc, D_LI, 99)
                end
            end
        end
    end

    squad.members[#squad.members + 1] = npc
    data.squad = squad
    SQ.AssignRoles(squad)
end

function SQ.RemoveMember(squad, npc)
    for i, m in ipairs(squad.members) do
        if m == npc then table.remove(squad.members, i) break end
    end
    local data = CAI.Manager.Get(npc)
    if data then data.squad, data.role = nil, nil end
    if squad.leader == npc then
        squad.leader = nil
        SQ.AssignRoles(squad)
    end
    if #squad.members == 0 then SQ.Squads[squad.id] = nil end
end

function SQ.Place(npc)
    local data = CAI.Manager.Get(npc)
    if not data then return end
    local classInfo = CAI.Config.NPCClasses[npc:GetClass()]
    local faction = classInfo and classInfo.faction or "custom"

    local best, bestD = nil, GROUP_RADIUS * GROUP_RADIUS
    for _, squad in pairs(SQ.Squads) do
        if squad.faction == faction and IsValid(squad.leader or squad.members[1]) then
            local anchor = (squad.leader or squad.members[1]):GetPos()
            local d = anchor:DistToSqr(npc:GetPos())
            if d < bestD and #squad.members < 8 then best, bestD = squad, d end
        end
    end
    if not best then best = SQ.Create(faction) end
    SQ.AddMember(best, npc)
end

function SQ.AssignRoles(squad)

    for i = #squad.members, 1, -1 do
        if not CAI.Util.Alive(squad.members[i]) then table.remove(squad.members, i) end
    end
    if #squad.members == 0 then return end

    local bestScore, leader = -math.huge, nil
    for _, m in ipairs(squad.members) do
        local d = CAI.Manager.Get(m)
        if d then
            local s = m:Health() / math.max(m:GetMaxHealth(), 1)
                    + (d.personality.stats.courage or 0)
            if s > bestScore then bestScore, leader = s, m end
        end
    end
    squad.leader = leader
    local ld = CAI.Manager.Get(leader)
    if ld then ld.role = CAI.ROLE.LEADER end

    local pool = { CAI.ROLE.SUPPRESSOR, CAI.ROLE.FLANKER, CAI.ROLE.SUPPORT,
                   CAI.ROLE.BREACHER, CAI.ROLE.REAR, CAI.ROLE.GRENADIER }
    local idx = 1
    for _, m in ipairs(squad.members) do
        if m ~= leader then
            local d = CAI.Manager.Get(m)
            if d then
                local st = d.personality.stats
                if (st.aggression or 0) > 0.2 and not squad._hasFlanker then
                    d.role, squad._hasFlanker = CAI.ROLE.FLANKER, true
                elseif (st.patience or 0) > 0.2 and not squad._hasSupp then
                    d.role, squad._hasSupp = CAI.ROLE.SUPPRESSOR, true
                else
                    d.role = pool[math.min(idx, #pool)]
                    idx = idx + 1
                end
            end
        end
    end
    squad._hasFlanker, squad._hasSupp = nil, nil
end

function SQ.Broadcast(squad, event, sender, payload)
    if not squad or not CAI.CVBool("cai_comms") then return end
    for _, m in ipairs(squad.members) do
        if IsValid(m) and m ~= sender then
            local d = CAI.Manager.Get(m)
            if d then SQ.OnComm(d, event, sender, payload) end
        end
    end
end

function SQ.OnComm(data, event, sender, payload)
    if event == "enemy_spotted" and payload then
        CAI.Memory.HearEnemy(data, payload.enemy, payload.pos)
        if data.state == CAI.STATE.IDLE or data.state == CAI.STATE.PATROL then
            CAI.Brain.SetState(data, CAI.STATE.COVER)
        end
    elseif event == "taking_fire" or event == "need_backup" then

        if IsValid(sender) and (data.state == CAI.STATE.IDLE or data.state == CAI.STATE.PATROL) then
            CAI.Nav.MoveTo(data, sender:GetPos(), "run")
            CAI.Brain.SetState(data, CAI.STATE.REGROUP)
        end
    elseif event == "grenade" or event == "rocket_spotted" then
        data.forceRecover = true
    elseif event == "reloading" then

        if data.role == CAI.ROLE.SUPPRESSOR then data.suppressUntil = CurTime() + 2 end
    elseif event == "enemy_lost" and payload then
        data.investigatePos = payload.pos
    elseif event == "retreating" then
        CAI.Morale.Add(data, -4, "ally_retreating")
    end
end

function SQ.FormationSlot(squad, index)
    local leader = squad.leader
    if not IsValid(leader) then return nil end
    local offsets = CAI.Config.Formations[squad.formation] or CAI.Config.Formations.WEDGE
    local o = offsets[math.min(index, #offsets)]
    if not o then return nil end
    local fwd = leader:GetForward(); fwd.z = 0; fwd:Normalize()
    local right = leader:GetRight(); right.z = 0; right:Normalize()
    return leader:GetPos() + fwd * o[1] + right * o[2]
end

function SQ.UpdateFormation(squad, inCombat, indoors)
    if not CAI.CVBool("cai_formations") then return end
    if inCombat then
        squad.formation = "LINE"
    elseif indoors then
        squad.formation = math.random() < 0.5 and "FILE" or "STACK"
    elseif #squad.members >= 5 then
        squad.formation = "DIAMOND"
    else
        squad.formation = "WEDGE"
    end
end

function SQ.Plan(squad)
    local now = CurTime()
    if now - squad.lastPlan < CAI.Config.Plan.Interval then return end
    squad.lastPlan = now

    CAI.Battlefield.Prune(squad)
    SQ.AssignRoles(squad)
    if #squad.members == 0 then return end

    local enemies, moraleSum, ammoLow, injured, withLOS = 0, 0, 0, 0, 0
    for _ in pairs(squad.blackboard.enemies) do enemies = enemies + 1 end
    for _, m in ipairs(squad.members) do
        local d = CAI.Manager.Get(m)
        if d then
            moraleSum = moraleSum + d.morale
            if m:Health() < m:GetMaxHealth() * 0.4 then injured = injured + 1 end
            local wep = m.GetActiveWeapon and m:GetActiveWeapon()
            if IsValid(wep) and wep.Clip1 and wep:Clip1() == 0 then ammoLow = ammoLow + 1 end
            local enemy = m.GetEnemy and m:GetEnemy()
            if IsValid(enemy) and CAI.Util.CanSee(m, enemy) then withLOS = withLOS + 1 end
        end
    end
    local avgMorale = moraleSum / #squad.members
    local inCombat = enemies > 0

    if enemies > 0 and enemies >= #squad.members * 2 then
        for _, m in ipairs(squad.members) do
            local d = CAI.Manager.Get(m)
            if d then CAI.Morale.Add(d, CAI.Config.Morale.Outnumbered, "outnumbered") end
        end
    end

    SQ.UpdateFormation(squad, inCombat, false)

    local cfg = CAI.Config.Plan
    if inCombat and avgMorale < cfg.RetreatMoraleAvg then
        squad.plan = "retreat"
    elseif inCombat and #squad.members >= enemies * cfg.PushAdvantage and withLOS > 0 then
        squad.plan = "push"
    elseif inCombat and #squad.members >= cfg.FlankMinMembers and CAI.CVBool("cai_flanking") then
        squad.plan = "flank"
    elseif inCombat then
        squad.plan = "hold"
    else
        squad.plan = "regroup"
    end

    for _, m in ipairs(squad.members) do
        local d = CAI.Manager.Get(m)
        if d then
            d.squadPlan = squad.plan
            if d.role == CAI.ROLE.SUPPRESSOR and (squad.plan == "push" or squad.plan == "flank" or squad.plan == "hold") then
                d.suppressUntil = now + cfg.Interval * 2
            elseif squad.plan == "flank" and d.role == CAI.ROLE.FLANKER then
                d.wantFlank = true
            elseif squad.plan == "push" and d.role == CAI.ROLE.FLANKER then
                d.wantFlank = true
            end
            if d.role == CAI.ROLE.GRENADIER or d.role == CAI.ROLE.LEADER then
                pcall(function() d.ent:SetSaveValue("m_iNumGrenades", 3) end)
            end
        end
    end
end

timer.Create("CAI_SquadPlans", 0.5, 0, function()
    if not CAI.Enabled() then return end
    for _, squad in pairs(SQ.Squads) do
        SQ.Plan(squad)
    end
end)
