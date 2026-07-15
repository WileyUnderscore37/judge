local ACTIVE_ANIMS = {
    ["idle_all_01"]     = true,
    ["idle_all_02"]     = true,
    ["idle_all_angry"]  = true,
    ["idle_all_scared"] = true,
    ["cidle_all"]       = true,
    ["walk_all"]        = true,
    ["run_all_01"]      = true,
    ["run_all_02"]      = true,
    ["cwalk_all"]      = true,
    ["idle_passive"]      = true,
    ["run_passive"]      = true,
}

local RUN_ANIMS = {
    ["run_all_01"] = true,
    ["run_all_02"] = true,
    ["run_passive"]      = true,
}

if SERVER then
    util.AddNetworkString("TR_PitchSync")

    local sendRate  = 0.05
    local lastSend  = {}
    local lastPitch = {}

    hook.Add("Think", "TR_ServerSample", function()
        local now = CurTime()
        for _, ply in ipairs(player.GetAll()) do
            if not IsValid(ply) or not ply:Alive() then continue end

            local idx = ply:EntIndex()
            if (lastSend[idx] or 0) + sendRate > now then continue end

            local seqName  = ply:GetSequenceName(ply:GetSequence())
            local active   = ACTIVE_ANIMS[seqName]
            local sprint   = RUN_ANIMS[seqName] and ply:KeyDown(IN_SPEED)
            local eyePitch = active and not sprint and math.NormalizeAngle(ply:EyeAngles().p) or 0

            if math.abs((lastPitch[idx] or 0) - eyePitch) < 0.2 then continue end

            lastPitch[idx] = eyePitch
            lastSend[idx]  = now

            net.Start("TR_PitchSync")
                net.WriteUInt(ply:EntIndex(), 8)
                net.WriteFloat(eyePitch)
            net.Broadcast()
        end
    end)

    hook.Add("PlayerDisconnected", "TR_Cleanup", function(ply)
        local idx = ply:EntIndex()
        lastSend[idx]  = nil
        lastPitch[idx] = nil
    end)

    return
end

local cv_enabled  = CreateClientConVar("tr_enabled",  "1",  true, false, "", 0, 1)
local cv_tilt_max = CreateClientConVar("tr_tilt_max", "33", true, false, "", 5, 60)
local cv_speed    = CreateClientConVar("tr_speed",    "8",  true, false, "", 1, 30)
local cv_instant  = CreateClientConVar("tr_instant",  "0",  true, false, "", 0, 1)

local SPINE_BONES = {
    { name = "ValveBiped.Bip01_Spine",  pitchW = 0.20 },
    { name = "ValveBiped.Bip01_Spine1", pitchW = 0.30 },
    { name = "ValveBiped.Bip01_Spine2", pitchW = 0.30 },
    { name = "ValveBiped.Bip01_Spine4", pitchW = 0.20 },
}

local boneCache    = {}
local pitches      = {}
local netTargets   = {}

local function LookupBone(ent, name)
    local id = ent:LookupBone(name)
    if id and id ~= -1 then return id end
    id = ent:LookupBone(name:sub(12))
    if id and id ~= -1 then return id end
    return false
end

local function GetCachedBones(ply)
    local mdl = ply:GetModel()
    if boneCache[mdl] then return boneCache[mdl] end
    local spine = {}
    for _, b in ipairs(SPINE_BONES) do
        table.insert(spine, { id = LookupBone(ply, b.name), pitchW = b.pitchW })
    end
    boneCache[mdl] = spine
    return spine
end

local function ClearBones(ply)
    if not IsValid(ply) then return end
    local zero = Angle(0, 0, 0)
    for _, b in ipairs(GetCachedBones(ply)) do
        if b.id then ply:ManipulateBoneAngles(b.id, zero) end
    end
end

local function ApplyPitch(ply, pitch)
    for _, b in ipairs(GetCachedBones(ply)) do
        if b.id then
            ply:ManipulateBoneAngles(b.id, Angle(0, pitch * b.pitchW, 0))
        end
    end
end

net.Receive("TR_PitchSync", function()
    local entIdx = net.ReadUInt(8)
    local pitch  = net.ReadFloat()
    netTargets[entIdx] = pitch
end)

hook.Add("Think", "TR_IdleTilt", function()
    if not cv_enabled:GetBool() then return end

    local dt = FrameTime()
    if dt <= 0 then return end

    local instant = cv_instant:GetBool()
    local speed   = cv_speed:GetFloat()
    local tiltMax = cv_tilt_max:GetFloat()
    local localPly = LocalPlayer()

    for _, ply in ipairs(player.GetAll()) do
        if not IsValid(ply) or not ply:Alive() then continue end

        local idx = ply:EntIndex()
        local target

        if ply == localPly then
            local seqName  = ply:GetSequenceName(ply:GetSequence())
            local active   = ACTIVE_ANIMS[seqName]
            local sprint   = RUN_ANIMS[seqName] and ply:KeyDown(IN_SPEED)
            target = (active and not sprint)
                and math.Clamp(math.NormalizeAngle(ply:EyeAngles().p), -tiltMax, tiltMax)
                or 0
        else
            target = math.Clamp(netTargets[idx] or 0, -tiltMax, tiltMax)
        end

        local current = pitches[idx] or 0

        if instant and ply == localPly then
            current = target
        else
            current = current + (target - current) * math.min(speed * dt, 1)
        end

        pitches[idx] = current

        if math.abs(current) < 0.01 then
            ClearBones(ply)
            continue
        end

        ApplyPitch(ply, current)
    end
end)

cvars.AddChangeCallback("tr_enabled", function(_, _, new)
    if new == "0" then
        for _, ply in ipairs(player.GetAll()) do ClearBones(ply) end
        pitches    = {}
        netTargets = {}
    end
end, "TR_EnabledCB")

hook.Add("EntityRemoved", "TR_Cleanup", function(ent)
    if not IsValid(ent) then return end
    local idx = ent:EntIndex()
    pitches[idx]    = nil
    netTargets[idx] = nil
end)

hook.Add("PlayerSpawn", "TR_Respawn", function(ply)
    if not IsValid(ply) then return end
    local idx = ply:EntIndex()
    pitches[idx]              = nil
    netTargets[idx]           = nil
    boneCache[ply:GetModel()] = nil
end)

hook.Add("PopulateToolMenu", "TR_Menu", function()
    spawnmenu.AddToolMenuOption("Utilities", "Torso Rotation", "tr_settings", "Torso Rotation", "", "", function(panel)
        panel:ClearControls()
        panel:CheckBox("Enable",           "tr_enabled")
        panel:CheckBox("Instant",          "tr_instant")
        panel:NumSlider("Pitch Max (deg)", "tr_tilt_max", 5, 60, 0)
        panel:NumSlider("Speed",           "tr_speed",    1, 30, 1)
        local btn = panel:Button("Reset")
        btn.DoClick = function()
            RunConsoleCommand("tr_enabled",  "1")
            RunConsoleCommand("tr_instant",  "0")
            RunConsoleCommand("tr_tilt_max", "33")
            RunConsoleCommand("tr_speed",    "8")
        end
    end)
end)