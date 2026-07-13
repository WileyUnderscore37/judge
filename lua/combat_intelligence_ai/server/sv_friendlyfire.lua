CAI.FriendlyFire = CAI.FriendlyFire or {}
local FF = CAI.FriendlyFire

local function AllyBlocking(npc, enemy)
    local from = npc.GetShootPos and npc:GetShootPos() or CAI.Util.EyePos(npc)
    local to = CAI.Util.EyePos(enemy)
    local tr = util.TraceLine({ start = from, endpos = to, filter = npc })
    local hit = tr.Entity
    if IsValid(hit) and hit:IsNPC() and npc:Disposition(hit) == D_LI then
        return true
    end
    return false
end

local function Sidestep(data, enemy)
    local npc = data.ent
    local dir = (enemy:GetPos() - npc:GetPos()); dir.z = 0; dir:Normalize()
    local right = Vector(-dir.y, dir.x, 0)
    local side = math.random() < 0.5 and 1 or -1
    for _, mult in ipairs({ side, -side }) do
        local target = npc:GetPos() + right * mult * 120
        local area = navmesh.GetNearestNavArea(target)
        if IsValid(area) then
            data.moveTarget = nil
            CAI.Nav.MoveTo(data, area:GetClosestPointOnArea(target), "run")
            return true
        end
    end
    return false
end

function FF.Update(data)
    if not CAI.CVBool("cai_friendlyfire_avoid") then return end
    local npc = data.ent
    local enemy = npc.GetEnemy and npc:GetEnemy()

    if IsValid(enemy) and CAI.Util.Alive(enemy) then
        data.ffCheckAt = data.ffCheckAt or 0
        if CurTime() > data.ffCheckAt then
            data.ffCheckAt = CurTime() + 1.0
            if AllyBlocking(npc, enemy) then
                Sidestep(data, enemy)
                return
            end
        end
    end

    if data.squad then
        data.spaceCheckAt = data.spaceCheckAt or 0
        if CurTime() > data.spaceCheckAt then
            data.spaceCheckAt = CurTime() + 2.0
            for _, m in ipairs(data.squad.members) do
                if IsValid(m) and m ~= npc
                   and m:GetPos():DistToSqr(npc:GetPos()) < 70 * 70 then
                    local away = (npc:GetPos() - m:GetPos()); away.z = 0
                    if away:LengthSqr() < 1 then away = VectorRand(); away.z = 0 end
                    away:Normalize()
                    data.moveTarget = nil
                    CAI.Nav.MoveTo(data, npc:GetPos() + away * 130, "walk")
                    break
                end
            end
        end
    end
end
