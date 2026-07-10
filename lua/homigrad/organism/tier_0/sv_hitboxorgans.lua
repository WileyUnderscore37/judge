hg.organism = hg.organism or {}
local empty = {}
local Vector = Vector --ыыы
local vecZero, angZero = Vector(0, 0, 0), Angle(0, 0, 0)
local box, _mins = Vector(0, 0, 0), Vector(0, 0, 0)
local center

local LocalToWorld = LocalToWorld

local util_IntersectRayWithOBB = util.IntersectRayWithOBB
local util_IsOBBIntersectingOBB = util.IsOBBIntersectingOBB
local math_ceil = math.ceil
local stepDiv = 1
local tracePos = Vector(0, 0, 0)

function hg.organism.Trace(pos, dir, size, maxpen, boxs, center, endDis, organs, ricochetable, funcInput, ...)
	local endDisSqr = endDis * endDis
	tracePos:Set(pos)

	local hitBoxs = {}
	local tracePoses = {}
	local inputHole, outputHole = {}, {}
	local inBody, hitSomething
	local box

	local distance = math_ceil(dir:Length())
	distance = math.Clamp(distance, 0, 512)
	dir:Normalize()

	local segLen = 12
	local passMax = distance
	local passing = 0
	local maxtries = 120

	while passing < passMax and maxtries > 0 do
		maxtries = maxtries - 1

		if maxpen ~= 0 and passing >= maxpen then break end

		local frac = 1
		local iHit, normal, hit
		local segDir = dir * segLen

		for i = 1, #boxs do
			if hitBoxs[i] then continue end

			box = boxs[i]
			if not organs[box[6]] then continue end

			local hit_, normal_, frac_ = util_IntersectRayWithOBB(tracePos, segDir, box[1], box[2], box[3], box[4])

			if hit_ and frac_ < frac then
				iHit = i
				frac = frac_
				normal = normal_
				hit = tracePos + segDir * frac_
			end
		end

		if iHit then
			hitBoxs[iHit] = true
			hitSomething = true

			local box = boxs[iHit]

			local dirSub = funcInput(box, tracePos, false, ...)

			if dirSub then
				distance = distance - dirSub * distance
				passMax = math.min(passMax, passing + distance)
			end

			if not inBody then
				inBody = true
				inputHole[#inputHole + 1] = Vector(tracePos[1], tracePos[2], tracePos[3])
			end

			tracePos = hit
			tracePoses[#tracePoses + 1] = Vector(tracePos[1], tracePos[2], tracePos[3])

			passing = passing + segLen * frac
		else
			if inBody then
				inBody = nil
				outputHole[#outputHole + 1] = Vector(tracePos[1], tracePos[2], tracePos[3])
			end

			tracePos:Add(segDir)
			tracePoses[#tracePoses + 1] = Vector(tracePos[1], tracePos[2], tracePos[3])

			passing = passing + segLen
		end

		if (tracePos - center):LengthSqr() > endDisSqr then break end
	end

	if not hitSomething then
		inputHole[1] = Vector(pos[1], pos[2], pos[3])
		outputHole[1] = Vector(tracePos[1], tracePos[2], tracePos[3])
	end

	dir:Normalize()

	return tracePos, hitBoxs, inputHole, outputHole, dir, distance, tracePoses
end

function hg.organism.BlastTrace(pos, size, dmg, boxs, organs, funcInput, ...)
	local box
	local center
	
	local size = size
	for i = 1, #boxs do
		box = boxs[i]
		center = box[1]

		local dist = pos:Distance(center)
		--size = size * 999
		local amt = dmg / dist * (1 - (organs[box[6]] and organs[box[6]][box[7]][2] or 0)) / size
		
		local dirSub = funcInput(box, amt, ...)
		
		size = size * (dirSub * 0.01 + 1)
	end
end