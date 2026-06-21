local CurTime, IsValid = CurTime, IsValid
local math_min, math_clamp, math_rand, math_random, math_sin = math.min, math.Clamp, math.Rand, math.random, math.sin
local VectorRand = VectorRand

local CHANCE, FORCE, VIBRATION = 0.12, 1200, 150
local extendDur, rigorDur, flexionDur = {4, 10}, {10, 20}, {6, 12}
local RIGOR_DAMP, FLEXION_FORCE = 8, 400
local postureOrder = {"cushing", "lazarus", "decorticate", "fencing"}

local REACTION_DELAY_MIN, REACTION_DELAY_MAX = 1, 2
local REACTION_EASE_IN = 1.5
local SHAKE_FREQ_FENCING, SHAKE_FREQ_DECORT, SHAKE_FREQ_LAZARUS, SHAKE_FREQ_CUSHING = 4, 3, 3.2, 3.5
local SHAKE_AMP_FENCING, SHAKE_AMP_DECORT, SHAKE_AMP_LAZARUS, SHAKE_AMP_CUSHING = 1.2, 0.5, 0.5, 0.5
local SHAKE_ANG_AMP = 0.8

local BRAIN_DEATH_THRESHOLD = 1
local BRAIN_DEATH_GRAV_DELAY = 0.35
local BRAIN_DEATH_GRAV_DURATION = 0.6
local BRAIN_DEATH_GRAV_MULT = 5
local BRAIN_DEATH_GRAV_BONE_FORCE = 1500

local spasmTypes = {[1] = {35, "extend"}, [2] = {25, "rigor"}, [3] = {15,"flexion"}} --;; Че хотите добавляйте изменяйте

local extendBones = {
	["ValveBiped.Bip01_R_Hand"] = true, ["ValveBiped.Bip01_L_Hand"] = true,
	["ValveBiped.Bip01_R_Foot"] = true, ["ValveBiped.Bip01_L_Foot"] = true,
	["ValveBiped.Bip01_R_Forearm"] = true, ["ValveBiped.Bip01_L_Forearm"] = true,
	["ValveBiped.Bip01_R_Calf"] = true, ["ValveBiped.Bip01_L_Calf"] = true,
	["ValveBiped.Bip01_R_UpperArm"] = true, ["ValveBiped.Bip01_L_UpperArm"] = true,
	["ValveBiped.Bip01_R_Thigh"] = true, ["ValveBiped.Bip01_L_Thigh"] = true,
}

local flexionBones = {
	{"ValveBiped.Bip01_R_Hand", "ValveBiped.Bip01_Spine2", 1.2},
	{"ValveBiped.Bip01_L_Hand", "ValveBiped.Bip01_Spine2", 1.2},
	{"ValveBiped.Bip01_R_Forearm", "ValveBiped.Bip01_Spine2", 1.0},
	{"ValveBiped.Bip01_L_Forearm", "ValveBiped.Bip01_Spine2", 1.0},
	{"ValveBiped.Bip01_Head1", "ValveBiped.Bip01_Spine2", 0.6},
}

local rigorBones = {
	"ValveBiped.Bip01_R_Hand", "ValveBiped.Bip01_L_Hand",
	"ValveBiped.Bip01_R_Foot", "ValveBiped.Bip01_L_Foot",
	"ValveBiped.Bip01_R_Forearm", "ValveBiped.Bip01_L_Forearm",
	"ValveBiped.Bip01_R_Calf", "ValveBiped.Bip01_L_Calf",
	"ValveBiped.Bip01_R_UpperArm", "ValveBiped.Bip01_L_UpperArm",
	"ValveBiped.Bip01_R_Thigh", "ValveBiped.Bip01_L_Thigh",
	"ValveBiped.Bip01_Head1", "ValveBiped.Bip01_Spine", "ValveBiped.Bip01_Spine1", "ValveBiped.Bip01_Spine2",
}



local fencingArmBones = {
	{"ValveBiped.Bip01_R_Hand", "ValveBiped.Bip01_R_UpperArm", 1.0},     
	{"ValveBiped.Bip01_L_Hand", "ValveBiped.Bip01_L_UpperArm", 1.0},
	{"ValveBiped.Bip01_R_Forearm", "ValveBiped.Bip01_Spine2", 0.8},       
	{"ValveBiped.Bip01_L_Forearm", "ValveBiped.Bip01_Spine2", 0.8},
	{"ValveBiped.Bip01_R_UpperArm", "ValveBiped.Bip01_Spine2", 0.5},      
	{"ValveBiped.Bip01_L_UpperArm", "ValveBiped.Bip01_Spine2", 0.5},
}
local fencingLegBones = {
	{"ValveBiped.Bip01_R_Foot", "ValveBiped.Bip01_R_Thigh", 0.6},         
	{"ValveBiped.Bip01_R_Calf", "ValveBiped.Bip01_R_Thigh", 0.4},         
}

local function getRandomSpasm()
	local _, stype = hg.WeightedRandomSelect(spasmTypes, 1)

	return stype
end

hg.getRandomSpasm = getRandomSpasm

local function applySpasm(rag, stype)
	if not IsValid(rag) then return end
	local dur = stype == "extend" and extendDur or stype == "rigor" and rigorDur or stype == "fencing" and {6, 12} or stype == "decorticate" and {10, 20} or flexionDur
	dur = math_rand(dur[1], dur[2])
	
	rag.spasm, rag.spasmType, rag.spasmDur, rag.spasmForce = true, stype, dur, FORCE
	rag.spasmEnd, rag.spasmStart = CurTime() + dur, CurTime()
	
	if stype == "rigor" then
		rag.rigorActive = true
	end
	--rag:EmitSound("physics/body/body_medium_break" .. math_random(2, 4) .. ".wav", 60, math_random(70, 90), 0.4)
end

hg.applySpasm = applySpasm

local function processExtend(rag, fade)
	local force, pulse = rag.spasmForce or FORCE, 0.7 + math_sin(CurTime() * 8) * 0.3
	local pelvis = rag:LookupBone("ValveBiped.Bip01_Pelvis")
	if not pelvis then return end
	local pelvisPos = rag:GetBonePosition(pelvis)
	
	for name in pairs(extendBones) do
		local bone = rag:LookupBone(name)
		if not bone then continue end
		local phys = rag:GetPhysicsObjectNum(rag:TranslateBoneToPhysBone(bone))
		if not IsValid(phys) then continue end
		local dir = (rag:GetBonePosition(bone) - pelvisPos):GetNormalized()
		phys:ApplyForceCenter((dir * force * fade * pulse) + VectorRand(-VIBRATION, VIBRATION) * fade)
	end
end

local function processRigor(rag, fade)
	if not rag.rigorActive then return end
	local damp = RIGOR_DAMP * fade + 0.5
	
	for i = 1, #rigorBones do
		local bone = rag:LookupBone(rigorBones[i])
		if not bone then continue end
		local phys = rag:GetPhysicsObjectNum(rag:TranslateBoneToPhysBone(bone))
		if not IsValid(phys) then continue end
		--phys:SetDamping(damp, damp * 2)
		if fade > 0.3 then phys:ApplyForceCenter(VectorRand(-45, 45) * fade) end
	end
end

local function processFlexion(rag, fade)
	local force, pulse = FLEXION_FORCE, 0.8 + math_sin(CurTime() * 5) * 0.2
	for i = 1, #flexionBones do
		local d = flexionBones[i]
		local bone, targetBone = rag:LookupBone(d[1]), rag:LookupBone(d[2])
		if not bone or not targetBone then continue end
		local phys = rag:GetPhysicsObjectNum(rag:TranslateBoneToPhysBone(bone))
		if not IsValid(phys) then continue end
		local dir = (rag:GetBonePosition(targetBone) - rag:GetBonePosition(bone)):GetNormalized()
		phys:ApplyForceCenter((dir * force * d[3] * fade * pulse) + VectorRand(-30, 30) * fade)
	end
end

local applyPostureToPlayer

--;; when furfag
local function applyFencingToPlayer(ply, org)
	applyPostureToPlayer(ply, org, "fencing", 3, 8)
end

hg.applyFencingToPlayer = applyFencingToPlayer

local function processFencing(rag, fade, ease)
	local boneSpine2 = rag:LookupBone("ValveBiped.Bip01_Spine2")
	if not boneSpine2 then return end
	local spine2 = rag:GetPhysicsObjectNum(rag:TranslateBoneToPhysBone(boneSpine2))
	if not IsValid(spine2) then return end

	local spineAng = spine2:GetAngles()
	local spinePos = spine2:GetPos()

	local t = math_clamp((fade - 0.1) / 0.9, 0, 1) * (ease or 1)

	local chestPos = spinePos + spineAng:Forward() * 5 + spineAng:Up() * 10
	local restPos = spinePos + spineAng:Up() * 5
	local extendPos = spinePos + spineAng:Forward() * 15 + spineAng:Up() * 20

	local targetPosChest = LerpVector(t, restPos, chestPos)
	local targetPosExt = LerpVector(t, restPos, extendPos)
	local shake = Vector(
		math.sin(CurTime() * SHAKE_FREQ_FENCING) * SHAKE_AMP_FENCING,
		math.sin(CurTime() * (SHAKE_FREQ_FENCING + 0.7)) * SHAKE_AMP_FENCING,
		math.sin(CurTime() * (SHAKE_FREQ_FENCING + 1.3)) * SHAKE_AMP_FENCING
	) * t
	targetPosChest = targetPosChest + shake
	targetPosExt = targetPosExt + shake
	
	local mul = 800 * t
	local legEase = t * t * (3 - 2 * t)
	local legMul = 800 * legEase
	local damp = 40

	local legAng = spine2:GetAngles()
	legAng:RotateAroundAxis(legAng:Up(), 180)

	hg.ShadowControl(rag, 8, 0.001, legAng, legMul, damp, vector_origin, 0, 0)
	hg.ShadowControl(rag, 9, 0.001, legAng, legMul, damp, vector_origin, 0, 0)
	hg.ShadowControl(rag, 11, 0.001, legAng, legMul, damp, vector_origin, 0, 0)
	hg.ShadowControl(rag, 12, 0.001, legAng, legMul, damp, vector_origin, 0, 0)

	if rag:EntIndex() % 2 == 0 then
		hg.ShadowControl(rag, 5, 0.001, nil, 0, 0, targetPosChest - spineAng:Right() * 6, mul * 1.6, damp)
		hg.ShadowControl(rag, 4, 0.001, nil, 0, 0, targetPosChest - spineAng:Right() * 8, mul * 1.2, damp)

		hg.ShadowControl(rag, 7, 0.001, nil, 0, 0, targetPosExt + spineAng:Right() * 6, mul * 1.6, damp)
		hg.ShadowControl(rag, 6, 0.001, nil, 0, 0, targetPosExt + spineAng:Right() * 8, mul * 1.2, damp)
	else
		hg.ShadowControl(rag, 5, 0.001, nil, 0, 0, targetPosExt - spineAng:Right() * 6, mul * 1.6, damp)
		hg.ShadowControl(rag, 4, 0.001, nil, 0, 0, targetPosExt - spineAng:Right() * 8, mul * 1.2, damp)

		hg.ShadowControl(rag, 7, 0.001, nil, 0, 0, targetPosChest + spineAng:Right() * 6, mul * 1.6, damp)
		hg.ShadowControl(rag, 6, 0.001, nil, 0, 0, targetPosChest + spineAng:Right() * 8, mul * 1.2, damp)
	end

	hg.ShadowControl(rag, 2, 0.001, spineAng, legMul * 0.5, damp, vector_origin, 0, 0)
	hg.ShadowControl(rag, 3, 0.001, spineAng, legMul * 0.5, damp, vector_origin, 0, 0)
end

local function applyDecorticateToPlayer(ply, org)
	applyPostureToPlayer(ply, org, "decorticate", 10, 20)
end

hg.applyDecorticateToPlayer = applyDecorticateToPlayer

local function applyLazarusToPlayer(ply, org)
	applyPostureToPlayer(ply, org, "lazarus", 8, 18)
end

hg.applyLazarusToPlayer = applyLazarusToPlayer

local function applyCushingToPlayer(ply, org)
	applyPostureToPlayer(ply, org, "cushing", 6, 14)
end

hg.applyCushingToPlayer = applyCushingToPlayer

local function processDecorticate(rag, fade, ease)
	local org = rag.organism
	local boneSpine2 = rag:LookupBone("ValveBiped.Bip01_Spine2")
	if not boneSpine2 then return end
	local spine2 = rag:GetPhysicsObjectNum(rag:TranslateBoneToPhysBone(boneSpine2))
	if not IsValid(spine2) then return end

	local spineAng = spine2:GetAngles()
	local spinePos = spine2:GetPos()

	local t = math_clamp((fade - 0.1) / 0.9, 0, 1) * (ease or 1)

	local dur = org and org.decorticateDur or rag.spasmDur or 15
	local timeElapsed = dur * (1 - fade)
	local easeIn = math_clamp(timeElapsed / 2.5, 0, 1)
	t = t * easeIn

	local chestPos = spinePos + spineAng:Forward() * 5 + spineAng:Up() * 10
	local restPos = spinePos + spineAng:Up() * 5

	local targetPos = LerpVector(t, restPos, chestPos)
	local shake = Vector(
		math.sin(CurTime() * SHAKE_FREQ_DECORT) * SHAKE_AMP_DECORT,
		math.sin(CurTime() * (SHAKE_FREQ_DECORT + 0.7)) * SHAKE_AMP_DECORT,
		math.sin(CurTime() * (SHAKE_FREQ_DECORT + 1.3)) * SHAKE_AMP_DECORT
	) * t
	targetPos = targetPos + shake

	local mul = (org and org.pulse and (600 * org.pulse / 70) or 400) * t
	local damp = 40

	local legAng = spine2:GetAngles()
	legAng:Add(Angle(
		math.sin(CurTime() * 3) * SHAKE_ANG_AMP * t,
		math.sin(CurTime() * 2.5) * SHAKE_ANG_AMP * t,
		math.sin(CurTime() * 2.8) * SHAKE_ANG_AMP * t
	))
	legAng:RotateAroundAxis(legAng:Up(), 180)
	
	hg.ShadowControl(rag, 8, 0.001, legAng, mul, damp, vector_origin, 0, 0)
	hg.ShadowControl(rag, 9, 0.001, legAng, mul, damp, vector_origin, 0, 0)
	hg.ShadowControl(rag, 11, 0.001, legAng, mul, damp, vector_origin, 0, 0)
	hg.ShadowControl(rag, 12, 0.001, legAng, mul, damp, vector_origin, 0, 0)

	hg.ShadowControl(rag, 5, 0.001, nil, 0, 0, targetPos - spineAng:Right() * 6, mul * 1.6, damp)
	hg.ShadowControl(rag, 7, 0.001, nil, 0, 0, targetPos + spineAng:Right() * 6, mul * 1.6, damp)

	hg.ShadowControl(rag, 4, 0.001, nil, 0, 0, targetPos - spineAng:Right() * 8, mul * 1.2, damp)
	hg.ShadowControl(rag, 6, 0.001, nil, 0, 0, targetPos + spineAng:Right() * 8, mul * 1.2, damp)

	hg.ShadowControl(rag, 2, 0.001, spineAng, mul * 0.5, damp, vector_origin, 0, 0)
	hg.ShadowControl(rag, 3, 0.001, spineAng, mul * 0.5, damp, vector_origin, 0, 0)
end

local function processLazarus(rag, fade, ease)
	local boneSpine2 = rag:LookupBone("ValveBiped.Bip01_Spine2")
	if not boneSpine2 then return end
	local spine2 = rag:GetPhysicsObjectNum(rag:TranslateBoneToPhysBone(boneSpine2))
	if not IsValid(spine2) then return end

	local spineAng = spine2:GetAngles()
	local spinePos = spine2:GetPos()

	local t = math_clamp((fade - 0.1) / 0.9, 0, 1) * (ease or 1)
	local legEase = t * t * (3 - 2 * t)

	local cycleRate = 0.5
	local phase = (CurTime() * cycleRate) % 1
	local lift
	if phase < 0.3 then
		lift = phase / 0.3
	elseif phase < 0.5 then
		lift = 1 - ((phase - 0.3) / 0.2)
	else
		lift = 0
	end
	lift = lift * t

	local upPos = spinePos + spineAng:Up() * 45 + spineAng:Forward() * 6
	local crossedPos = spinePos + spineAng:Forward() * 3 + spineAng:Up() * 8

	local armPos = LerpVector(lift, crossedPos, upPos)
	local shake = Vector(
		math.sin(CurTime() * SHAKE_FREQ_LAZARUS) * SHAKE_AMP_LAZARUS,
		math.sin(CurTime() * (SHAKE_FREQ_LAZARUS + 0.7)) * SHAKE_AMP_LAZARUS,
		math.sin(CurTime() * (SHAKE_FREQ_LAZARUS + 1.3)) * SHAKE_AMP_LAZARUS
	) * t
	armPos = armPos + shake

	local mul = (900 * lift + 120) * t
	local armMul = (900 * lift + 120) * legEase
	local damp = 50

	hg.ShadowControl(rag, 5, 0.001, nil, 0, 0, armPos - spineAng:Right() * 10, mul * 1.6, damp)
	hg.ShadowControl(rag, 6, 0.001, nil, 0, 0, armPos + spineAng:Right() * 10, mul * 1.6, damp)

	hg.ShadowControl(rag, 4, 0.001, nil, 0, 0, armPos - spineAng:Right() * 12, mul * 1.2, damp)
	hg.ShadowControl(rag, 7, 0.001, nil, 0, 0, armPos + spineAng:Right() * 12, mul * 1.2, damp)

	hg.ShadowControl(rag, 2, 0.001, spineAng, armMul * 0.3, damp, vector_origin, 0, 0)
	hg.ShadowControl(rag, 3, 0.001, spineAng, armMul * 0.3, damp, vector_origin, 0, 0)
end

local function processCushing(rag, fade, ease)
	local boneSpine2 = rag:LookupBone("ValveBiped.Bip01_Spine2")
	if not boneSpine2 then return end
	local spine2 = rag:GetPhysicsObjectNum(rag:TranslateBoneToPhysBone(boneSpine2))
	if not IsValid(spine2) then return end

	local spineAng = spine2:GetAngles()
	local spinePos = spine2:GetPos()

	local t = math_clamp((fade - 0.05) / 0.95, 0, 1) * (ease or 1)
	local legEase = t * t * (3 - 2 * t)

	local archAng = Angle(spineAng.pitch + 30 * t, spineAng.yaw, spineAng.roll)
	local legAng = Angle(spineAng.pitch + 18 * t, spineAng.yaw + 180, spineAng.roll)

	local armPos = spinePos + archAng:Up() * 15
	local shake = Vector(
		math.sin(CurTime() * SHAKE_FREQ_CUSHING) * SHAKE_AMP_CUSHING,
		math.sin(CurTime() * (SHAKE_FREQ_CUSHING + 0.7)) * SHAKE_AMP_CUSHING,
		math.sin(CurTime() * (SHAKE_FREQ_CUSHING + 1.3)) * SHAKE_AMP_CUSHING
	) * t
	armPos = armPos + shake

	local mul = (1200 * t + 200) * t
	local armMul = (1000 * t + 150) * legEase
	local damp = 50

	hg.ShadowControl(rag, 8, 0.001, legAng, mul, damp, vector_origin, 0, 0)
	hg.ShadowControl(rag, 9, 0.001, legAng, mul, damp, vector_origin, 0, 0)
	hg.ShadowControl(rag, 11, 0.001, legAng, mul, damp, vector_origin, 0, 0)
	hg.ShadowControl(rag, 12, 0.001, legAng, mul, damp, vector_origin, 0, 0)

	hg.ShadowControl(rag, 2, 0.001, archAng, armMul * 0.5, damp, vector_origin, 0, 0)
	hg.ShadowControl(rag, 3, 0.001, archAng, armMul * 0.5, damp, vector_origin, 0, 0)

	hg.ShadowControl(rag, 5, 0.001, nil, 0, 0, armPos - spineAng:Right() * 20, mul * 1.4, damp)
	hg.ShadowControl(rag, 6, 0.001, nil, 0, 0, armPos + spineAng:Right() * 20, mul * 1.4, damp)

	hg.ShadowControl(rag, 4, 0.001, nil, 0, 0, armPos - spineAng:Right() * 22, mul * 1.1, damp)
	hg.ShadowControl(rag, 7, 0.001, nil, 0, 0, armPos + spineAng:Right() * 22, mul * 1.1, damp)
end

local function clearPostureState(target, posture)
	if not target then return end
	target[posture], target[posture .. "End"], target[posture .. "Dur"], target[posture .. "Start"], target[posture .. "Delay"] = nil, nil, nil, nil, nil
end

local function clearOtherPostures(org, rag, current)
	for i = 1, #postureOrder do
		local posture = postureOrder[i]
		if posture == current then continue end
		clearPostureState(org, posture)
		if IsValid(rag) then
			clearPostureState(rag, posture)
		end
	end
end

applyPostureToPlayer = function(ply, org, posture, minDur, maxDur)
	if not IsValid(ply) or not ply:Alive() or not org then return end
	if org[posture] then return end

	local rag = ply.FakeRagdoll
	if IsValid(rag) and rag[posture] then return end

	clearOtherPostures(org, IsValid(rag) and rag or nil, posture)

	local dur = math_rand(minDur, maxDur)
	local delay = math_rand(REACTION_DELAY_MIN * 10, REACTION_DELAY_MAX * 10) / 10
	org[posture] = true
	org[posture .. "Start"] = CurTime() + delay
	org[posture .. "End"] = org[posture .. "Start"] + dur
	org[posture .. "Dur"] = dur
	org[posture .. "Delay"] = delay

	if IsValid(rag) then
		rag[posture] = true
		rag[posture .. "Start"] = org[posture .. "Start"]
		rag[posture .. "End"] = org[posture .. "End"]
		rag[posture .. "Dur"] = dur
		rag[posture .. "Delay"] = delay
	end
end

local function processActivePosture(owner, org)
	local rag = IsValid(owner.FakeRagdoll) and owner.FakeRagdoll or (owner:IsRagdoll() and owner or nil)
	if not IsValid(rag) then return end

	local time = CurTime()
	local active

	for i = 1, #postureOrder do
		local posture = postureOrder[i]
		local endTime = org[posture .. "End"]
		if org[posture] and endTime then
			if time > endTime then
				clearPostureState(rag, posture)
				clearPostureState(org, posture)
			elseif not active then
				active = posture
			else
				clearPostureState(rag, posture)
				clearPostureState(org, posture)
			end
		end
	end

	if not active then return end

	local dur = org[active .. "Dur"] or 5
	local start = org[active .. "Start"] or (org[active .. "End"] - dur)
	if time < start then return end

	local easeRaw = math_clamp((time - start) / REACTION_EASE_IN, 0, 1)
	local ease = easeRaw * easeRaw * (3 - 2 * easeRaw)
	local fade = math_clamp((org[active .. "End"] - time) / dur, 0.1, 1)

	if active == "fencing" then
		processFencing(rag, fade, ease)
	elseif active == "decorticate" then
		processDecorticate(rag, fade, ease)
	elseif active == "lazarus" then
		processLazarus(rag, fade, ease)
	elseif active == "cushing" then
		processCushing(rag, fade, ease)
	end
end

local function clearFencing(rag)
	clearPostureState(rag, "fencing")
end

local function clearDecorticate(rag)
	clearPostureState(rag, "decorticate")
end

local function clearLazarus(rag)
	clearPostureState(rag, "lazarus")
end

local function clearCushing(rag)
	clearPostureState(rag, "cushing")
end

local function clearSpasm(rag)
	if rag.spasmType == "rigor" and rag.rigorActive then
		for i = 1, #rigorBones do
			local bone = rag:LookupBone(rigorBones[i])
			if not bone then continue end
			local phys = rag:GetPhysicsObjectNum(rag:TranslateBoneToPhysBone(bone))
			if IsValid(phys) then phys:SetDamping(0.5, 1) end
		end
	end
	rag.spasm, rag.spasmEnd, rag.spasmStart, rag.spasmDur, rag.spasmForce, rag.spasmType, rag.rigorActive = nil, nil, nil, nil, nil, nil, nil
end

local function processBrainDeathGravityBurst(rag)
	if not IsValid(rag) then return end
	local physCount = rag:GetPhysicsObjectCount()
	for i = 0, physCount - 1 do
		local phys = rag:GetPhysicsObjectNum(i)
		if not IsValid(phys) then continue end
		local mass = phys:GetMass()
		phys:ApplyForceCenter(Vector(0, 0, -(BRAIN_DEATH_GRAV_BONE_FORCE + mass * 100 * BRAIN_DEATH_GRAV_MULT)))
	end
end

local function applyBrainDeathGravityBurst(org, rag)
	if org._brainDeathBurstTriggered then return end
	org._brainDeathBurstTriggered = true
	org._brainDeathBurstStart = CurTime() + BRAIN_DEATH_GRAV_DELAY
	org._brainDeathBurstEnd = org._brainDeathBurstStart + BRAIN_DEATH_GRAV_DURATION
	org._brainDeathBurstRag = rag
end

hook.Add("Should Fake Up", "BrainfuckFencing", function(ply)
	local org = ply.organism
	if org and org.fencing and org.fencingEnd and CurTime() < org.fencingEnd then
		return false
	end
	if org and org.decorticate and org.decorticateEnd and CurTime() < org.decorticateEnd then
		return false
	end
	if org and org.lazarus and org.lazarusEnd and CurTime() < org.lazarusEnd then
		return false
	end
	if org and org.cushing and org.cushingEnd and CurTime() < org.cushingEnd then
		return false
	end
	local rag = ply.FakeRagdoll
	if IsValid(rag) and rag.fencing and rag.fencingEnd and CurTime() < rag.fencingEnd then
		return false
	end
	if IsValid(rag) and rag.decorticate and rag.decorticateEnd and CurTime() < rag.decorticateEnd then
		return false
	end
	if IsValid(rag) and rag.lazarus and rag.lazarusEnd and CurTime() < rag.lazarusEnd then
		return false
	end
	if IsValid(rag) and rag.cushing and rag.cushingEnd and CurTime() < rag.cushingEnd then
		return false
	end
end)

hook.Add("RagdollDeath", "BrainfuckStart", function(ply, rag)
	timer.Simple(0.1, function()
		if not IsValid(ply) or not IsValid(rag) then return end
		local org = ply.organism
		if not org then return end
		if rag.noHead or org.noHead or ply.noHead then return end
		
		local hadBrainDamage = org.brain and org.brain > 0
		local hadSkullDamage = org.skull and org.skull > 0
		local hadHeadDamage = org.dmgstack and org.dmgstack[HITGROUP_HEAD] and (org.dmgstack[HITGROUP_HEAD][1] or 0) > 0
		local headshot = hadBrainDamage or hadSkullDamage or hadHeadDamage

		if headshot and math_random() < CHANCE then
			local stype = "fencing"
			applySpasm(rag, stype)
			if rag.organism then rag.organism.spasm, rag.organism.spasmType = true, stype end
		end

		local brainLevel = org.brain or 0
		if brainLevel >= 0.75 and headshot and math_random() < CHANCE then
			hg.applyCushingToPlayer(ply, org)
		end

		if (org.brain or 0) >= BRAIN_DEATH_THRESHOLD then
			applyBrainDeathGravityBurst(org, rag)
		end
	end)
end)

hook.Add("Org Think", "BrainfuckThink", function(owner)
	if not IsValid(owner) then return end
	local org = owner.organism or owner
	processActivePosture(owner, org)
	
	local deathRag = IsValid(owner.FakeRagdoll) and owner.FakeRagdoll or (owner:IsRagdoll() and owner or nil)
	if IsValid(deathRag) and deathRag.spasm and deathRag.spasmEnd then
		if CurTime() > deathRag.spasmEnd then
			clearSpasm(deathRag)
		else
			local fade = math_clamp((deathRag.spasmEnd - CurTime()) / (deathRag.spasmDur or 5), 0.1, 1)
			local stype = deathRag.spasmType or "extend"

			if stype == "extend" then processExtend(deathRag, fade)
			elseif stype == "rigor" then processRigor(deathRag, fade)
			elseif stype == "flexion" then processFlexion(deathRag, fade)
			elseif stype == "fencing" then processFencing(deathRag, fade) end
		end
	end

	if org._brainDeathBurstStart and CurTime() >= org._brainDeathBurstStart and CurTime() < org._brainDeathBurstEnd then
		local burstRag = IsValid(org._brainDeathBurstRag) and org._brainDeathBurstRag or (IsValid(owner.FakeRagdoll) and owner.FakeRagdoll or (owner:IsRagdoll() and owner or nil))
		if IsValid(burstRag) then
			processBrainDeathGravityBurst(burstRag)
		end
	end
end)

hook.Add("Org Clear", "BrainfuckClear", function(org)
	if not org or not org.owner then return end
	if IsValid(org.owner) then
		clearSpasm(org.owner)
		clearFencing(org.owner)
		clearDecorticate(org.owner)
		clearLazarus(org.owner)
		clearCushing(org.owner)
	end
	clearPostureState(org, "fencing")
	clearPostureState(org, "decorticate")
	clearPostureState(org, "lazarus")
	clearPostureState(org, "cushing")
	org._brainDeathBurstTriggered, org._brainDeathBurstStart, org._brainDeathBurstEnd, org._brainDeathBurstRag = nil, nil, nil, nil
end)

hook.Add("HomigradDamage", "DecorticateTrigger", function(ply, dmgInfo, hitgroup, ent, harm, hitBoxs, inputHole)
	local org = ply.organism
	if not org then return end

	local brain = org.brain or 0
	if brain >= 0.20 and (dmgInfo:IsDamageType(DMG_CLUB) or dmgInfo:IsDamageType(DMG_BULLET) or dmgInfo:IsDamageType(DMG_BUCKSHOT)) then
		if not org.fencing and not org.decorticate and not org.lazarus and math_random() < CHANCE then
			hg.applyDecorticateToPlayer(ply, org)
		end
	end

	if brain >= 0.50 and (dmgInfo:IsDamageType(DMG_CLUB) or dmgInfo:IsDamageType(DMG_BULLET) or dmgInfo:IsDamageType(DMG_BUCKSHOT)) then
		if not org.fencing and not org.decorticate and not org.lazarus and not org.cushing and math_random() < CHANCE then
			hg.applyLazarusToPlayer(ply, org)
		end
	end

	if brain >= 0.75 and (dmgInfo:IsDamageType(DMG_CLUB) or dmgInfo:IsDamageType(DMG_BULLET) or dmgInfo:IsDamageType(DMG_BUCKSHOT)) then
		if not org.fencing and not org.decorticate and not org.lazarus and not org.cushing and math_random() < CHANCE then
			hg.applyCushingToPlayer(ply, org)
		end
	end
end)
