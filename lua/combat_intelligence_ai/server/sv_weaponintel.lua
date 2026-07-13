CAI.WeaponIntel = CAI.WeaponIntel or {}
local WI = CAI.WeaponIntel

local archetypeCache = {}

function WI.Classify(wep)
    if not IsValid(wep) then return "rifle" end
    local cls = wep:GetClass()
    local cached = archetypeCache[cls]
    if cached then return cached end
    local lower = string.lower(cls)
    for _, p in ipairs(CAI.Config.WeaponPatterns) do
        if lower:find(p.pattern, 1, true) then
            archetypeCache[cls] = p.archetype
            return p.archetype
        end
    end
    archetypeCache[cls] = "rifle"
    return "rifle"
end

function WI.Update(data, enemy)
    if not CAI.CVBool("cai_weaponintel") then
        data.enemyWeaponResponse = CAI.Config.WeaponResponses.rifle
        return
    end
    if not (IsValid(enemy) and enemy.GetActiveWeapon) then return end
    local archetype = WI.Classify(enemy:GetActiveWeapon())

    if data.enemyWeaponArchetype ~= archetype then
        data.enemyWeaponArchetype = archetype
        data.enemyWeaponResponse = CAI.Config.WeaponResponses[archetype] or CAI.Config.WeaponResponses.rifle

        if archetype == "rocket" and data.squad then
            for _, member in ipairs(data.squad.members) do
                local md = CAI.Manager.Get(member)
                if md then md.forceRecover = true end
            end
            CAI.Squad.Broadcast(data.squad, "rocket_spotted", data.ent)
        end
    end
end

function WI.EffectiveAggression(data)
    local agg = 0.5 + (data.personality.stats.aggression or 0) * 0.5
    agg = agg + (CAI.CVNum("cai_aggression") - 0.5) * 0.9
    if data.enemyWeaponResponse then
        agg = agg + (data.enemyWeaponResponse.aggression or 0)
    end
    if data.morale > 80 then agg = agg + 0.1 end
    if data.morale < CAI.Config.Morale.ShakenThreshold then agg = agg - 0.25 end
    return math.Clamp(agg, 0, 1)
end

local ownIdeal = {
    shotgun = 340, smg = 520, rifle = 650, lmg = 720,
    sniper = 1100, pistol = 500, explosive = 900,
}
function WI.OwnIdeal(npc)
    local wep = npc.GetActiveWeapon and npc:GetActiveWeapon()
    if not IsValid(wep) then return 600 end
    local arch = WI.Classify(wep:GetClass())
    return ownIdeal[arch] or 600
end
