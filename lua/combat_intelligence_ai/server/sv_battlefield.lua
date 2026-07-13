CAI.Battlefield = CAI.Battlefield or {}
local B = CAI.Battlefield

function B.New()
    return {
        enemies = {},
        dangers = {},
        goodCover = {},
        badCover = {},
        deadAllies = {},
        suppressedAt = {},
        blockedPaths = {},
    }
end

local function posKey(pos)
    return math.floor(pos.x / 64) .. ":" .. math.floor(pos.y / 64) .. ":" .. math.floor(pos.z / 64)
end
B.PosKey = posKey

function B.ReportEnemy(squad, enemy, pos, spotter)
    if not squad then return end
    if not CAI.Util.IsTargetable(enemy) then return end
    if enemy:GetClass() == "npc_bullseye" then return end
    squad.blackboard.enemies[enemy] = { pos = pos, t = CurTime(), spotter = spotter }
    if CAI.CVBool("cai_comms") then
        for _, member in ipairs(squad.members) do
            local d = CAI.Manager and CAI.Manager.Get(member)
            if d and member ~= spotter then
                CAI.Memory.HearEnemy(d, enemy, pos)
            end
        end
    end
end

function B.ReportDanger(squad, pos, radius, reason)
    if not squad then return end
    local d = squad.blackboard.dangers
    d[#d + 1] = { pos = pos, radius = radius, t = CurTime(), reason = reason }
    if #d > 16 then table.remove(d, 1) end
    if CAI.CVBool("cai_comms") then
        for _, member in ipairs(squad.members) do
            local md = CAI.Manager and CAI.Manager.Get(member)
            if md then CAI.Memory.AddDanger(md, pos, radius, reason) end
        end
    end
end

function B.MarkCover(squad, pos, success)
    if not squad then return end
    local key = posKey(pos)
    local map = success and squad.blackboard.goodCover or squad.blackboard.badCover
    map[key] = (map[key] or 0) + 1
end

function B.CoverHistory(squad, pos)
    if not squad then return 0 end
    local key = posKey(pos)
    local good = squad.blackboard.goodCover[key] or 0
    local bad = squad.blackboard.badCover[key] or 0
    if good + bad == 0 then return 0 end
    return math.Clamp((good - bad) / math.max(good + bad, 1), -1, 1)
end

function B.Prune(squad)
    local now = CurTime()
    for ent, rec in pairs(squad.blackboard.enemies) do
        if not IsValid(ent) or now - rec.t > CAI.Config.Memory.EnemyTTL then
            squad.blackboard.enemies[ent] = nil
        end
    end
    for i = #squad.blackboard.dangers, 1, -1 do
        if now - squad.blackboard.dangers[i].t > CAI.Config.Memory.DangerTTL then
            table.remove(squad.blackboard.dangers, i)
        end
    end
end
