CAI.Perf = CAI.Perf or {}
local P = CAI.Perf

P.Stats = {
    managed = 0,
    thinksThisSecond = 0,
    thinksPerSecond = 0,
    avgThinkMs = 0,
    _accumMs = 0,
    _accumN = 0,
}

function P.GetThinkInterval(npc)
    local _, distSqr = CAI.Util.NearestPlayer(npc:GetPos())
    local perfMode = CAI.CVBool("cai_performance_mode")
    for _, tier in ipairs(CAI.Config.LOD) do
        if distSqr <= tier.dist * tier.dist then
            local interval = tier.interval
            if perfMode then interval = interval * 1.75 end
            return interval, tier.dist
        end
    end
    return 3.0, math.huge
end

function P.RecordThink(ms)
    P.Stats.thinksThisSecond = P.Stats.thinksThisSecond + 1
    P.Stats._accumMs = P.Stats._accumMs + ms
    P.Stats._accumN = P.Stats._accumN + 1
end

timer.Create("CAI_PerfStats", 1, 0, function()
    local S = P.Stats
    S.thinksPerSecond = S.thinksThisSecond
    S.thinksThisSecond = 0
    S.avgThinkMs = S._accumN > 0 and (S._accumMs / S._accumN) or 0
    S._accumMs, S._accumN = 0, 0
end)
