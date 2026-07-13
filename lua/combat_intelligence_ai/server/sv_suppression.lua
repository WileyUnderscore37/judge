CAI.Suppression = CAI.Suppression or {}
local S = CAI.Suppression

function S.Add(data, amount)
    if not CAI.CVBool("cai_suppression") then return end
    local resist = 1 - math.Clamp(data.personality.stats.suppResist or 0, 0, 0.6)

    if data.morale > 70 then resist = resist * 0.85 end
    data.suppression = math.min(CAI.Config.Suppression.Max, data.suppression + amount * resist)
    data.lastSuppressedAt = CurTime()

    if data.suppression > CAI.Config.Suppression.PinnedAt and not data.saidTakingFire then
        data.saidTakingFire = true
        CAI.Voice.Speak(data, "taking_fire")
        if data.squad then CAI.Squad.Broadcast(data.squad, "taking_fire", data.ent) end
    end
end

function S.Decay(data, dt)
    if data.suppression <= 0 then return end
    data.suppression = math.max(0, data.suppression - CAI.Config.Suppression.Decay * dt)
    if data.suppression < CAI.Config.Suppression.PinnedAt then
        data.saidTakingFire = false
    end
end

function S.IsPinned(data) return data.suppression >= CAI.Config.Suppression.PinnedAt end
function S.IsPanicked(data) return data.suppression >= CAI.Config.Suppression.PanicAt end

local shotQueue = {}
local MAX_QUEUE = 256

CAI.SafeHook("EntityFireBullets", "CAI_Suppression", function(shooter, info)
    if not CAI.Enabled() or not CAI.CVBool("cai_suppression") then return end
    if not IsValid(shooter) then return end
    if #shotQueue >= MAX_QUEUE then return end
    shotQueue[#shotQueue + 1] = {
        shooter = shooter,
        src = Vector(info.Src),
        dir = Vector(info.Dir),
        dist = info.Distance or 8000,
    }
end)

local function ProcessShot(shot)
    local shooter = shot.shooter
    if not IsValid(shooter) then return end
    if shooter:IsPlayer() and not CAI.Util.IsTargetable(shooter) then return end

    local src = shot.src
    local dst = src + shot.dir * shot.dist
    local cfg = CAI.Config.Suppression

    for npc, data in pairs(CAI.Manager.All()) do
        if IsValid(npc) and npc ~= shooter
           and npc:Disposition(shooter) == D_HT then

            if npc:GetPos():DistToSqr(src) < 3000 * 3000 then
                local d = CAI.Util.PointSegmentDist(npc:GetPos() + Vector(0,0,40), src, dst)
                if d < cfg.Radius then
                    S.Add(data, cfg.PerBullet * (1 - d / cfg.Radius))

                    CAI.Memory.HearEnemy(data, shooter, shooter:GetPos())
                end
            end
        end
    end
end

timer.Create("CAI_SuppressionQueue", 0.1, 0, function()
    if #shotQueue == 0 then return end
    local batch = shotQueue
    shotQueue = {}
    for i = 1, #batch do
        local ok = pcall(ProcessShot, batch[i])
    end
end)

CAI.SafeHook("OnEntityCreated", "CAI_GrenadeWatch", function(ent)
    timer.Simple(0, function()
        if not IsValid(ent) or not CAI.Enabled() then return end
        local cls = ent:GetClass()
        if cls == "npc_grenade_frag" or cls == "grenade_hand" or cls:find("grenade") then

            for npc, data in pairs(CAI.Manager.All()) do
                if IsValid(npc) and npc:GetPos():DistToSqr(ent:GetPos()) < 600 * 600 then
                    CAI.Memory.AddDanger(data, ent:GetPos(), 400, "grenade")
                    data.scatterFrom = ent:GetPos()
                    data.scatterUntil = CurTime() + 2.5
                    if data.squad then
                        CAI.Battlefield.ReportDanger(data.squad, ent:GetPos(), 400, "grenade")
                        CAI.Squad.Broadcast(data.squad, "grenade", npc)
                    end
                    CAI.Voice.Speak(data, "grenade")
                end
            end
        end
    end)
end)
