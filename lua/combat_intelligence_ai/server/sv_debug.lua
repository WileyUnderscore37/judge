timer.Create("CAI_DebugNet", 0.35, 0, function()
    if not CAI.Enabled() or not CAI.CVBool("cai_debug") then return end

    local admins = {}
    for _, ply in ipairs(player.GetAll()) do
        if ply:IsAdmin() then admins[#admins + 1] = ply end
    end
    if #admins == 0 then return end

    for _, ply in ipairs(admins) do
        local eye = ply:GetPos()
        local near = {}
        for npc, data in pairs(CAI.Manager.All()) do
            if IsValid(npc) then
                local d = eye:DistToSqr(npc:GetPos())
                if d < 2500 * 2500 then
                    near[#near + 1] = { npc = npc, data = data, d = d }
                end
            end
        end
        table.sort(near, function(a, b) return a.d < b.d end)

        local rows = {}
        for i = 1, math.min(#near, 24) do
            local npc, data = near[i].npc, near[i].data
            do
                local enemy = npc.GetEnemy and npc:GetEnemy()
                rows[#rows + 1] = {
                    idx = npc:EntIndex(),
                    state = data.state,
                    role = data.role or 0,
                    morale = math.Round(data.morale),
                    supp = math.Round(data.suppression),
                    squad = data.squad and data.squad.id or 0,
                    plan = data.squadPlan or "",
                    why = data.lastDecision or "",
                    cover = data.cover and data.cover.pos or nil,
                    move = data.moveTarget,
                    target = IsValid(enemy) and enemy:EntIndex() or 0,
                    memE = table.Count(data.memory.enemies),
                    memD = #data.memory.dangers,
                    lod = data.lodInterval or 0,
                }
            end
        end

        net.Start(CAI.Net.Debug)
            net.WriteUInt(#rows, 6)
            for _, r in ipairs(rows) do
                net.WriteUInt(r.idx, 14)
                net.WriteUInt(r.state, 5)
                net.WriteUInt(r.role, 4)
                net.WriteUInt(r.morale, 7)
                net.WriteUInt(r.supp, 7)
                net.WriteUInt(r.squad % 256, 8)
                net.WriteString(r.plan)
                net.WriteString(r.why)
                net.WriteBool(r.cover ~= nil)
                if r.cover then net.WriteVector(r.cover) end
                net.WriteBool(r.move ~= nil)
                if r.move then net.WriteVector(r.move) end
                net.WriteUInt(r.target, 14)
                net.WriteUInt(math.min(r.memE, 15), 4)
                net.WriteUInt(math.min(r.memD, 15), 4)
                net.WriteFloat(r.lod)
            end
        net.Send(ply)
    end
end)

concommand.Add("cai_dump", function(ply)
    if IsValid(ply) and not ply:IsAdmin() then return end
    print("===== Combat Intelligence AI dump =====")
    print("Managed NPCs: " .. CAI.Perf.Stats.managed)
    print("Thinks/sec:   " .. CAI.Perf.Stats.thinksPerSecond)
    print("Avg think ms: " .. string.format("%.3f", CAI.Perf.Stats.avgThinkMs))
    local byClass = {}
    for npc in pairs(CAI.Manager.All()) do
        if IsValid(npc) then
            local c = npc:GetClass()
            byClass[c] = (byClass[c] or 0) + 1
        end
    end
    for c, n in SortedPairs(byClass) do
        print(("  %s x%d"):format(c, n))
    end
    for id, squad in pairs(CAI.Squad.Squads) do
        print(("Squad %d [%s] members=%d plan=%s formation=%s")
            :format(id, squad.faction, #squad.members, squad.plan or "?", squad.formation))
    end
end, nil, "Print AI statistics and squad list to console.")
