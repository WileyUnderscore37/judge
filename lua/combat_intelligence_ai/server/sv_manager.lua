CAI.Manager = CAI.Manager or {}
local MG = CAI.Manager

MG.NPCs = MG.NPCs or {}

function MG.Get(npc) return MG.NPCs[npc] end
function MG.All() return MG.NPCs end

function MG.Register(npc)
    if not IsValid(npc) or MG.NPCs[npc] then return end
    if table.Count(MG.NPCs) >= CAI.CVNum("cai_max_managed") then return end
    if not CAI.Config.NPCClasses[npc:GetClass()] then return end

    local classInfo = CAI.Config.NPCClasses[npc:GetClass()]
    local faction = classInfo and classInfo.faction or "custom"
    if classInfo and classInfo.vj then
        local c = istable(npc.VJ_NPC_Class) and npc.VJ_NPC_Class[1]
        if isstring(c) then
            faction = ({ CLASS_COMBINE = "combine", CLASS_PLAYER_ALLY = "resistance" })[c]
                      or string.lower((string.gsub(c, "^CLASS_", "")))
        else
            faction = "vj"
        end
    end
    local mdl = string.lower(npc:GetModel() or "")
    local data = {
        ent = npc,
        faction = faction,
        voiceGender = (mdl:find("female", 1, true) or mdl:find("alyx", 1, true)
                       or mdl:find("mossman", 1, true)) and "female" or "male",
        personality = CAI.Personality.Generate(),
        memory = CAI.Memory.New(),
        morale = CAI.Config.Morale.Start + math.random(-10, 10),
        suppression = 0,
        state = CAI.STATE.IDLE,
        stateSince = CurTime(),
        nextThink = CurTime() + math.Rand(0, 0.3),
        lastThink = CurTime(),
        lastDecision = "registered",
    }
    if data.faction == "combine" then
        pcall(function() npc:SetSaveValue("m_iNumGrenades", 2) end)
    end
    if CAI.CVBool("cai_simfire") then
        pcall(function() npc:SetKeyValue("squadname", "cai_solo_" .. npc:EntIndex()) end)
    end
    MG.NPCs[npc] = data

    CAI.Nav.EnableDoorUse(npc)
    CAI.Squad.Place(npc)

    npc:CallOnRemove("CAI_Unregister", function() MG.Unregister(npc) end)
end

function MG.Unregister(npc)
    local data = MG.NPCs[npc]
    if not data then return end
    if data.squad then CAI.Squad.RemoveMember(data.squad, npc) end
    MG.NPCs[npc] = nil
end

CAI.SafeHook("OnEntityCreated", "CAI_Register", function(ent)
    timer.Simple(0.1, function()
        if IsValid(ent) and ent:IsNPC() and CAI.Enabled() then
            MG.Register(ent)
        end
    end)
end)

CAI.SafeHook("OnNPCKilled", "CAI_UnregisterDead", function(npc)
    MG.Unregister(npc)
end)

hook.Add("InitPostEntity", "CAI_NavCheck", function()
    timer.Simple(3, function()
        if navmesh.GetNavAreaCount() == 0 then
            print(CAI.PrintPrefix .. "No navmesh on this map. Falling back to ai-node cover schedules and trace-based search/flank routes. For best results run nav_generate once (sv_cheats 1).")
        end
    end)
end)

hook.Add("InitPostEntity", "CAI_AdoptExisting", function()
    timer.Simple(1, function()
        for _, ent in ipairs(ents.GetAll()) do
            if IsValid(ent) and ent:IsNPC() then MG.Register(ent) end
        end
    end)
end)

local cvAIDisabled
timer.Create("CAI_Scheduler", CAI.Config.ManagerTickRate, 0, function()
    if not CAI.Enabled() then return end

    cvAIDisabled = cvAIDisabled or GetConVar("ai_disabled")
    if cvAIDisabled and cvAIDisabled:GetBool() then return end

    local now = CurTime()
    local budget = CAI.Config.MaxBrainThinksPerTick
    if CAI.CVBool("cai_performance_mode") then budget = math.max(6, budget - 4) end

    local count = 0
    for npc, data in pairs(MG.NPCs) do
        if not IsValid(npc) then
            MG.NPCs[npc] = nil
        elseif now >= data.nextThink then
            local t0 = SysTime()
            local dt = now - data.lastThink
            data.lastThink = now

            local ok, err = pcall(CAI.Brain.Think, data, dt)
            if not ok then
                ErrorNoHaltWithStack(CAI.PrintPrefix .. "brain error: " .. tostring(err))
            end

            local interval = CAI.Perf.GetThinkInterval(npc)

            interval = interval / math.max(CAI.Difficulty(), 0.25)
            data.nextThink = now + interval
            data.lodInterval = interval

            CAI.Perf.RecordThink((SysTime() - t0) * 1000)
            count = count + 1
            if count >= budget then break end
        end
    end
    CAI.Perf.Stats.managed = table.Count(MG.NPCs)
end)

cvars.AddChangeCallback("cai_enabled", function(_, _, new)
    if new == "0" then
        for npc, data in pairs(MG.NPCs) do
            if IsValid(npc) then npc:SetSchedule(SCHED_IDLE_STAND) end
        end
        print(CAI.PrintPrefix .. "Disabled - NPCs released to stock AI.")
    end
end, "CAI_Toggle")
