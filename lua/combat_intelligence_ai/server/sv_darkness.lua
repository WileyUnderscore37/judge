net.Receive(CAI.Net.Light, function(_, ply)
    if not IsValid(ply) then return end
    local now = CurTime()
    if (ply.CAI_LightAt or 0) + 0.4 > now then return end
    ply.CAI_LightAt = now
    ply.CAI_Light = math.Clamp(net.ReadFloat() or 1, 0, 1)
end)

local function PlayerLight(ply)
    if ply.FlashlightIsOn and ply:FlashlightIsOn() then return 1 end
    return ply.CAI_Light or 1
end
CAI.PlayerLight = PlayerLight

function CAI.ApplyDarknessVision(data)
    local npc = data.ent
    if not npc.SetMaxLookDistance then return end
    if not data.baseLookDist then
        data.baseLookDist = (npc.GetMaxLookDistance and npc:GetMaxLookDistance()) or 2048
    end
    if not CAI.CVBool("cai_darkness") then
        npc:SetMaxLookDistance(data.baseLookDist)
        return
    end
    local ply = CAI.Util.NearestPlayer(npc:GetPos())
    if not IsValid(ply) then return end
    local light = PlayerLight(ply)
    local dist = Lerp(math.Clamp(light * 2.2, 0, 1), 400, data.baseLookDist)
    npc:SetMaxLookDistance(dist)
end
