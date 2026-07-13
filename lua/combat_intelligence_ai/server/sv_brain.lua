CAI.Brain = CAI.Brain or {}
local BR = CAI.Brain
local STATE = nil

function BR.SetState(data, newState, reason)
    if data.state == newState then return end
    data.prevState = data.state
    data.state = newState
    data.stateSince = CurTime()
    if reason then data.lastDecision = reason end
end

local function Perceive(data)
    local npc = data.ent

    if CurTime() - (data.darkAt or 0) > 1.0 then
        data.darkAt = CurTime()
        CAI.ApplyDarknessVision(data)
    end

    if CurTime() - (data.aimCheckAt or 0) > 0.4 then
        data.aimCheckAt = CurTime()
        local ply = CAI.Util.NearestPlayer(npc:GetPos())
        if IsValid(ply) and CAI.Util.IsTargetable(ply)
           and npc:Disposition(ply) == D_HT
           and npc:GetPos():DistToSqr(ply:GetPos()) < 1500 * 1500 then
            local toNPC = (npc:WorldSpaceCenter() - ply:EyePos())
            toNPC:Normalize()
            if ply:GetAimVector():Dot(toNPC) > 0.995 and CAI.Util.CanSee(npc, ply) then
                data.aimedSince = data.aimedSince or CurTime()
                if CurTime() - data.aimedSince > 0.35 then
                    CAI.Memory.SeeEnemy(data, ply, ply:GetPos())
                    if data.state == CAI.STATE.COVER and not data.forceRecover
                       and math.random() < 0.35 then
                        data.forceRecover = true
                    end
                end
            else
                data.aimedSince = nil
            end
        else
            data.aimedSince = nil
        end
    end

    local engineEnemy = npc.GetEnemy and npc:GetEnemy()
    if IsValid(engineEnemy) and CAI.Util.IsTargetable(engineEnemy) then
        if CAI.Util.CanSee(npc, engineEnemy) then
            local firstContact = data.memory.enemies[engineEnemy] == nil
            CAI.Memory.SeeEnemy(data, engineEnemy, engineEnemy:GetPos())
            CAI.WeaponIntel.Update(data, engineEnemy)
            if data.squad then
                CAI.Battlefield.ReportEnemy(data.squad, engineEnemy, engineEnemy:GetPos(), npc)
                if firstContact then
                    CAI.Voice.Speak(data, "enemy_spotted")
                    CAI.Squad.Broadcast(data.squad, "enemy_spotted", npc,
                        { enemy = engineEnemy, pos = engineEnemy:GetPos() })
                end
            end
        end
    end

    local wep = npc.GetActiveWeapon and npc:GetActiveWeapon()
    if IsValid(wep) and wep.Clip1 and wep:Clip1() == 0 and not data.saidReload then
        data.saidReload = true
        CAI.Voice.Speak(data, "reload")
        if data.squad then CAI.Squad.Broadcast(data.squad, "reloading", npc) end
        CAI.Morale.Add(data, CAI.Config.Morale.OutOfAmmoClip, "empty_clip")
    elseif IsValid(wep) and wep.Clip1 and wep:Clip1() > 0 then
        data.saidReload = false
    end

    CAI.Morale.CheckHealth(data)
end

local function Decide(data)
    local S = CAI.STATE
    local npc = data.ent

    if data.forceRecover then
        data.forceRecover = nil
        return S.COVER, "emergency_relocate"
    end

    if data.scatterUntil then
        if CurTime() < data.scatterUntil then
            return S.RETREAT, "grenade_scatter"
        end
        data.scatterFrom, data.scatterUntil = nil, nil
    end

    if CAI.Morale.IsBroken(data) then
        if CAI.CVBool("cai_meleepanic") then
            local ee = npc.GetEnemy and npc:GetEnemy()
            if IsValid(ee) and CAI.Util.IsTargetable(ee)
               and npc:GetPos():DistToSqr(ee:GetPos()) < 110 * 110 then
                local wep = npc:GetActiveWeapon()
                if not IsValid(wep) or (wep.Clip1 and wep:Clip1() == 0) then
                    return S.ENGAGE, "cornered_melee"
                end
            end
        end
        return S.RETREAT, "morale_broken"
    end

    if CAI.Suppression.IsPanicked(data) and (data.personality.stats.courage or 0) < 0.2 then
        return S.RETREAT, "suppression_panic"
    end

    local enemy, rec = CAI.Target.Evaluate(data)
    local visible = IsValid(enemy) and CAI.Util.CanSee(npc, enemy)
    if visible then
        data.lastVisEnemy, data.lastVisAt = enemy, CurTime()
    elseif IsValid(enemy) and data.lastVisEnemy == enemy
       and CurTime() - (data.lastVisAt or 0) < 1.0 then
        visible = true
    end

    if IsValid(enemy) then
        if visible then

            data.search = nil

            if CAI.Suppression.IsPinned(data) then
                return S.COVER, "pinned_by_fire"
            end

            local ownWep = npc:GetActiveWeapon()
            if IsValid(ownWep) and ownWep.Clip1 and ownWep:Clip1() == 0 then
                return S.COVER, "reloading_cover"
            end

            if data.flank then
                return S.FLANK, "flank_in_progress"
            end
            if data.wantFlank then
                data.wantFlank = nil
                return S.FLANK, "squad_flank_order"
            end
            if data.suppressUntil and CurTime() < data.suppressUntil then
                return S.SUPPRESS, "squad_suppress_order"
            end

            local resp = data.enemyWeaponResponse
            local agg = CAI.WeaponIntel.EffectiveAggression(data)
            local dist = npc:GetPos():Distance(enemy:GetPos())
            if resp and resp.scatter then
                return S.COVER, "rocket_threat"
            end
            if resp and resp.keepDistance and dist < resp.idealDist * 0.6 then
                return S.COVER, "shotgun_too_close"
            end
            if data.squadPlan == "push" or agg > 0.72 then
                return S.ENGAGE, "aggressive_push"
            end
            if data.squadPlan == "retreat" then
                return S.RETREAT, "squad_retreat"
            end

            return S.COVER, "fight_from_cover"
        else

            if data.flank then
                return S.FLANK, "flank_in_progress"
            end
            local patience = 1.5 + (data.personality.stats.patience or 0) * 3
            local staleFor = rec and (CurTime() - rec.t) or math.huge
            if staleFor < patience then
                return S.COVER, "await_reacquire"
            end
            if data.search then return S.SEARCH, "search_in_progress" end
            if CAI.CVBool("cai_search") then
                return S.SEARCH, "enemy_vanished"
            end
            return S.COVER, "await_reacquire"
        end
    end

    if data.investigatePos and CurTime() < (data.investigateUntil or 0) then
        return S.INVESTIGATE, "heard_something"
    end
    if data.squad and IsValid(data.squad.leader) and data.squad.leader ~= npc
       and npc:GetPos():DistToSqr(data.squad.leader:GetPos()) > 700 * 700 then
        return S.REGROUP, "rejoin_squad"
    end
    return S.PATROL, "all_quiet"
end

local Exec = {}

Exec[0] = function(data) end

Exec[1] = function(data)
    local npc = data.ent
    if CurTime() - (data.patrolAt or 0) > math.Rand(6, 12) then
        data.patrolAt = CurTime()
        local p
        for try = 1, 4 do
            local cand = CAI.Nav.RandomPointNear(npc:GetPos(), 900)
            if cand and cand:DistToSqr(npc:GetPos()) > 300 * 300
               and (not data.lastPatrolPoint or cand:DistToSqr(data.lastPatrolPoint) > 300 * 300) then
                p = cand
                break
            end
        end
        if p then
            data.lastPatrolPoint = p
            CAI.Nav.MoveTo(data, p, "walk")
        end
        if math.random() < 0.15 then CAI.Voice.Speak(data, "idle") end
    end
end

Exec[2] = function(data)
    local npc = data.ent
    local enemy = npc:GetEnemy()
    if not IsValid(enemy) then return end

    if data.lastDecision == "cornered_melee" then
        if CurTime() - (data.meleeAt or 0) > 1.2 then
            data.meleeAt = CurTime()
            npc:SetSchedule(SCHED_MELEE_ATTACK1)
            CAI.Voice.Speak(data, "panic")
        end
        return
    end
    local ideal = CAI.WeaponIntel.OwnIdeal(npc)
    local resp = data.enemyWeaponResponse
    if resp and resp.keepDistance then ideal = math.max(ideal, resp.idealDist or ideal) end
    local dist = npc:GetPos():Distance(enemy:GetPos())
    if dist < ideal * 0.45 then
        if CurTime() - (data.backoffAt or 0) > 2 then
            data.backoffAt = CurTime()
            local away = npc:GetPos() - enemy:GetPos()
            away.z = 0 away:Normalize()
            CAI.Nav.MoveTo(data, npc:GetPos() + away * 200, "run")
        end
    elseif dist > ideal * 1.2 then

        if CurTime() - (data.advanceAt or 0) > 2 then
            data.advanceAt = CurTime()
            npc:SetSchedule(SCHED_ESTABLISH_LINE_OF_FIRE)
            if math.random() < 0.3 then CAI.Voice.Speak(data, "moving") end
        end
    end
    CAI.FriendlyFire.Update(data)
end

Exec[3] = function(data)
    local npc = data.ent
    local enemy, rec = CAI.Memory.FreshestEnemy(data)
    local enemyPos = rec and rec.pos or (IsValid(enemy) and enemy:GetPos())

    CAI.Cover.UpdateCoverStatus(data, enemy)

    if not data.cover then
        local pos = CAI.Cover.FindBest(data, enemy, enemyPos)
        if not pos and CurTime() - (data.nodeCoverAt or 0) > 3 then
            data.nodeCoverAt = CurTime()
            npc:SetSchedule(SCHED_TAKE_COVER_FROM_ENEMY)
        end
        if pos then
            data.cover = { pos = pos, since = CurTime() }
            CAI.Nav.MoveTo(data, pos, "run")
            if math.random() < 0.25 then CAI.Voice.Speak(data, "cover_me") end
        else

            if CurTime() - (data.engCoverAt or 0) > 3 then
                data.engCoverAt = CurTime()
                npc:SetSchedule(SCHED_TAKE_COVER_FROM_ENEMY)
            end
            return
        end
    end

    if CAI.Nav.Arrived(data, 80) then
        local aggro = CAI.CVNum("cai_aggression")
        if CAI.Suppression.IsPinned(data) and aggro < 0.95 then
            if CurTime() - (data.duckAt or 0) > 2 * (1.3 - aggro) then
                data.duckAt = CurTime()
                npc:SetSchedule(SCHED_TAKE_COVER_FROM_ENEMY)
            end
        else
            if CurTime() - (data.faceAt or 0) > 1.5 * (1.3 - aggro) then
                data.faceAt = CurTime()
                npc:SetSchedule(SCHED_COMBAT_FACE)
            end
        end
    end
    CAI.FriendlyFire.Update(data)
end

Exec[4] = function(data)
    if not data.flank then
        local _, rec = CAI.Memory.FreshestEnemy(data)
        if not rec or not CAI.Flank.Begin(data, rec.pos) then
            BR.SetState(data, CAI.STATE.COVER, "flank_unavailable")
            return
        end
    end
    if not CAI.Flank.Update(data) then
        BR.SetState(data, CAI.STATE.ENGAGE, "flank_complete")
    end
end

local function StopSuppressing(data)
    if IsValid(data.suppBullseye) then data.suppBullseye:Remove() end
    data.suppBullseye = nil
end
BR.StopSuppressing = StopSuppressing

Exec[5] = function(data)
    local npc = data.ent
    local enemy, rec = CAI.Memory.FreshestEnemy(data)
    if not rec then
        StopSuppressing(data)
        BR.SetState(data, CAI.STATE.COVER, "nothing_to_suppress")
        return
    end

    if IsValid(enemy) and CAI.Util.CanSee(npc, enemy) then
        StopSuppressing(data)
        if npc.SetEnemy then npc:SetEnemy(enemy) end
        if npc.UpdateEnemyMemory then npc:UpdateEnemyMemory(enemy, rec.pos) end
    else
        local aim
        for _, h in ipairs({ 55, 90 }) do
            local p = rec.pos + Vector(0, 0, h)
            if CAI.Util.CanSeePos(npc, p) then aim = p break end
        end
        if aim then
            local bull = data.suppBullseye
            if not IsValid(bull) then
                bull = ents.Create("npc_bullseye")
                if IsValid(bull) then
                    bull:SetPos(aim)
                    bull:SetKeyValue("spawnflags", "196608")
                    bull:Spawn()
                    bull:SetNoDraw(true)
                    bull:SetSolid(SOLID_NONE)
                    bull:SetHealth(999999)
                    data.suppBullseye = bull
                    npc:AddEntityRelationship(bull, D_HT, 99)
                end
            else
                bull:SetPos(aim)
            end
            if IsValid(bull) and npc.SetEnemy then
                npc:SetEnemy(bull)
                if npc.UpdateEnemyMemory then npc:UpdateEnemyMemory(bull, aim) end
            end
        end
    end

    if CurTime() - (data.suppFaceAt or 0) > 1.5 then
        data.suppFaceAt = CurTime()
        npc:SetSchedule(SCHED_COMBAT_FACE)
    end
    if not data.saidSuppress then
        data.saidSuppress = true
        CAI.Voice.Speak(data, "suppressing")
        if data.squad then
            local sa = data.squad.blackboard.suppressedAt
            sa[#sa + 1] = { pos = rec.pos, t = CurTime() }
            if #sa > 6 then table.remove(sa, 1) end
        end
    end
    if not data.suppressUntil or CurTime() > data.suppressUntil then
        data.saidSuppress = false
        BR.SetState(data, CAI.STATE.COVER, "suppress_done")
    end
end

Exec[6] = function(data)
    if not data.search then
        local enemy, rec = CAI.Memory.FreshestEnemy(data)
        if not rec or not CAI.Search.Begin(data, enemy, rec.pos) then
            BR.SetState(data, CAI.STATE.PATROL, "nothing_to_search")
            return
        end
    end
    if not CAI.Search.Update(data) then
        BR.SetState(data, CAI.STATE.PATROL, "search_over")
    end
end

Exec[7] = function(data)
    local npc = data.ent
    if data.scatterFrom and data.scatterUntil and CurTime() < data.scatterUntil then
        local away = npc:GetPos() - data.scatterFrom
        away.z = 0
        if away:LengthSqr() < 1 then away = Vector(1, 0, 0) end
        away:Normalize()
        CAI.Nav.MoveTo(data, npc:GetPos() + away * 280, "run")
        return
    end
    if CurTime() - (data.retreatAt or 0) > 3 then
        data.retreatAt = CurTime()
        local _, rec = CAI.Memory.FreshestEnemy(data)
        if rec then
            local away = (npc:GetPos() - rec.pos); away.z = 0; away:Normalize()
            local dest = CAI.Nav.RandomPointNear(npc:GetPos() + away * 800, 400)
                      or npc:GetPos() + away * 600
            CAI.Nav.MoveTo(data, dest, "run")
        else
            npc:SetSchedule(SCHED_RUN_FROM_ENEMY)
        end
        if not data.saidRetreat then
            data.saidRetreat = true
            CAI.Voice.Speak(data, "retreat")
            if data.squad then CAI.Squad.Broadcast(data.squad, "retreating", npc) end
        end
    end

    if data.morale > CAI.Config.Morale.ShakenThreshold + 10 then
        data.saidRetreat = false
        BR.SetState(data, CAI.STATE.COVER, "morale_recovered")
    end
end

Exec[8] = function(data)
    local npc = data.ent
    if not data.investigatePos or CurTime() > (data.investigateUntil or 0) then

        if data.investigatePos then
            data.lastInvestigate = { pos = data.investigatePos, t = CurTime() }
        end
        data.investigatePos = nil
        BR.SetState(data, CAI.STATE.PATROL, "investigation_over")
        return
    end
    CAI.Nav.MoveTo(data, data.investigatePos, "walk")
    if CAI.Nav.Arrived(data, 100) then
        npc:SetSchedule(SCHED_COMBAT_FACE)
        data.investigateUntil = math.min(data.investigateUntil, CurTime() + 3)
    end
end

Exec[9] = function(data)
    local squad = data.squad
    if not squad or not IsValid(squad.leader) or squad.leader == data.ent then
        BR.SetState(data, CAI.STATE.PATROL, "no_squad_to_regroup")
        return
    end

    local idx = 0
    for _, m in ipairs(squad.members) do
        if m ~= squad.leader then
            idx = idx + 1
            if m == data.ent then break end
        end
    end
    local slot = CAI.Squad.FormationSlot(squad, idx)
    if slot and CurTime() - (data.regroupAt or 0) > 1.5 then
        data.regroupAt = CurTime()
        CAI.Nav.MoveTo(data, slot, "run")
    end
    if CAI.Nav.Arrived(data, 90) then
        BR.SetState(data, CAI.STATE.PATROL, "in_formation")
    end
end

function BR.Think(data, dt)
    local npc = data.ent
    if not CAI.Util.Alive(npc) then return end

    local classInfo = CAI.Config.NPCClasses[npc:GetClass()]
    if classInfo and classInfo.lightTouch then
        Perceive(data)
        CAI.Memory.Fade(data)
        CAI.Suppression.Decay(data, dt)
        CAI.Morale.Regen(data, dt)
        return
    end

    Perceive(data)
    CAI.Memory.Fade(data)
    CAI.Suppression.Decay(data, dt)
    CAI.Morale.Regen(data, dt)
    CAI.Personality.ApplyProficiency(data)
    CAI.Nav.CheckStuck(data)

    local newState, reason = Decide(data)
    BR.SetState(data, newState, reason)

    local exec = Exec[data.state]
    if exec then exec(data) end

    if data.state ~= CAI.STATE.SUPPRESS and IsValid(data.suppBullseye) then
        BR.StopSuppressing(data)
    end
end
