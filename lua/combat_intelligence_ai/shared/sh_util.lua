CAI.Util = CAI.Util or {}
local U = CAI.Util

function U.Alive(ent)
    return IsValid(ent) and ent:Health() > 0
end

function U.IsTargetable(ent)
    if not U.Alive(ent) then return false end
    if ent:IsPlayer() then
        if ent:IsFlagSet(FL_NOTARGET) then return false end
        local cvIgnorePlayers = GetConVar("ai_ignoreplayers")
        if cvIgnorePlayers and cvIgnorePlayers:GetBool() then return false end
    end
    return true
end

function U.DistSqr(a, b)
    local d = a - b
    return d:LengthSqr()
end

function U.PointSegmentDist(p, a, b)
    local ab = b - a
    local lenSqr = ab:LengthSqr()
    if lenSqr < 1 then return p:Distance(a) end
    local t = math.Clamp((p - a):Dot(ab) / lenSqr, 0, 1)
    return p:Distance(a + ab * t)
end

function U.EyePos(ent)
    if not IsValid(ent) then return vector_origin end
    if ent.EyePos then return ent:EyePos() end
    return ent:GetPos() + Vector(0, 0, 60)
end

local traceCache, traceCacheTime = {}, {}
function U.CanSee(from, to)
    if not (IsValid(from) and IsValid(to)) then return false end

    local key = from:EntIndex() .. ":" .. to:EntIndex()
    local now = CurTime()
    if traceCacheTime[key] and now - traceCacheTime[key] < 0.2 then
        return traceCache[key]
    end
    local tr = util.TraceLine({
        start = U.EyePos(from),
        endpos = U.EyePos(to),
        filter = { from, to },
        mask = MASK_BLOCKLOS,
    })
    local result = not tr.Hit
    traceCache[key], traceCacheTime[key] = result, now
    return result
end

timer.Create("CAI_TraceCacheFlush", 30, 0, function()
    traceCache, traceCacheTime = {}, {}
end)

function U.CanSeePos(viewer, pos)
    if not IsValid(viewer) then return false end
    local tr = util.TraceLine({
        start = U.EyePos(viewer),
        endpos = pos + Vector(0, 0, 40),
        filter = viewer,
        mask = MASK_BLOCKLOS,
    })
    return not tr.Hit
end

function U.NearestPlayer(pos)
    local best, bestD = nil, math.huge
    for _, ply in ipairs(player.GetAll()) do
        if U.Alive(ply) then
            local d = U.DistSqr(pos, ply:GetPos())
            if d < bestD then best, bestD = ply, d end
        end
    end
    return best, bestD
end

function U.WeightedRandom(list)
    local total = 0
    for _, e in ipairs(list) do total = total + e.w end
    local r = math.Rand(0, total)
    for _, e in ipairs(list) do
        r = r - e.w
        if r <= 0 then return e.item end
    end
    return list[#list] and list[#list].item
end

function U.Approach(cur, target, rate)
    return math.Approach(cur, target, rate)
end

local lastHookError = {}
function CAI.SafeHook(event, name, fn)
    hook.Add(event, name, function(...)
        local ok, err = pcall(fn, ...)
        if not ok then
            local now = CurTime()
            if (lastHookError[name] or 0) + 5 < now then
                lastHookError[name] = now
                ErrorNoHalt("[Combat Intelligence AI] error in " .. name .. ": " .. tostring(err) .. "\n")
            end
        end

    end)
end
