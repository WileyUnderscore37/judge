
if not CLIENT then return end

-- convars
	local hg_runbob_enabled = ConVarExists("hg_runbob_enabled") and GetConVar("hg_runbob_enabled") or CreateClientConVar("hg_runbob_enabled", "1",   true, false, "enable additional running viewbob",                  0, 1)
	local hg_runbob_bob     = ConVarExists("hg_runbob_bob")     and GetConVar("hg_runbob_bob")     or CreateClientConVar("hg_runbob_bob",     "2", true, false, "running viewbob intensity multiplier",          0, 3)
	local hg_runbob_tilt    = ConVarExists("hg_runbob_tilt")    and GetConVar("hg_runbob_tilt")    or CreateClientConVar("hg_runbob_tilt",    "2.0", true, false, "cam tilt (strafe roll) multiplier",   0, 3)
	local hg_runbob_noise   = ConVarExists("hg_runbob_noise")   and GetConVar("hg_runbob_noise")   or CreateClientConVar("hg_runbob_noise",   "2.0", true, false, "random noise shake intensity multiplier",             0, 3)
	local hg_runbob_step    = ConVarExists("hg_runbob_step")    and GetConVar("hg_runbob_step")    or CreateClientConVar("hg_runbob_step",    "1.0", true, false, "footstep based viewpunch intensity multiplier",   0, 3)

-- locals
	local math_sin   = math.sin
	local math_cos   = math.cos
	local math_Rand  = math.Rand
	local math_Clamp = math.Clamp
	local Lerp       = Lerp

	local SPEED_MIN = 160  -- no bob below this
	local SPEED_MAX = 355  -- full intensity at/over this

-- state
	local bobTime     = 0
	local noiseAng    = Angle(0, 0, 0)
	local noiseTarget = Angle(0, 0, 0)
	local noiseTimer  = 0
	local tiltLerp    = 0

	local function speedFactor(vel)
		return math_Clamp((vel:Length2D() - SPEED_MIN) / (SPEED_MAX - SPEED_MIN), 0, 1)
	end

-- viewbob hook
hook.Add("HGAddView", "RunBob_Extra", function(ply, origin, angles)
	if not hg_runbob_enabled:GetBool() then
		tiltLerp = 0
		noiseAng:Zero()
		return
	end

	if not ply:Alive() or ply:InVehicle() then
		tiltLerp = Lerp(FrameTime() * 6, tiltLerp, 0)
		noiseAng[1] = Lerp(FrameTime() * 6, noiseAng[1], 0)
		noiseAng[2] = Lerp(FrameTime() * 6, noiseAng[2], 0)
		angles[3] = angles[3] + tiltLerp
		return
	end

	local ft       = FrameTime()
	local vel      = ply:GetVelocity()
	local onGround = ply:OnGround()
	local sf       = onGround and speedFactor(vel) or 0
	local ts       = game.GetTimeScale()

	local bobMul   = hg_runbob_bob:GetFloat()
	local tiltMul  = hg_runbob_tilt:GetFloat()
	local noiseMul = hg_runbob_noise:GetFloat()

	if onGround and sf > 0.01 then
		bobTime = bobTime + ft * (3.2 + sf * 4.5) * ts
	end

-- cam tilt
	local tiltTarget = 0
	if sf > 0 and onGround then
		local sideVel  = vel:Dot(ply:EyeAngles():Right())
		local strafeLean = math_Clamp(sideVel / SPEED_MAX, -1, 1) * 2 * sf * tiltMul

		local stepLean = math_sin(bobTime) * sf * 1.4 * bobMul

		tiltTarget = strafeLean + stepLean
	end

	tiltLerp = Lerp(ft * (sf > 0.01 and 5 or 9), tiltLerp, tiltTarget)

-- noise
	noiseTimer = noiseTimer - ft
	if noiseTimer <= 0 then
		if sf > 0.01 then
			noiseTimer = math_Rand(0.10, 0.28) * (1 - sf * 0.40)
			noiseTarget[1] = math_Rand(-1, 1) * sf * 0.52 * noiseMul
			noiseTarget[2] = math_Rand(-1, 1) * sf * 0.24 * noiseMul
		else
			noiseTarget[1] = 0
			noiseTarget[2] = 0
		end
	end

	local ns = ft * (sf > 0.01 and 12 or 8)
	noiseAng[1] = Lerp(ns, noiseAng[1], noiseTarget[1])
	noiseAng[2] = Lerp(ns, noiseAng[2], noiseTarget[2])

	if sf < 0.02 then
		angles[3] = angles[3] + tiltLerp
		return
	end

-- sinusoidal bob
	local t = bobTime
	local bobPitch = math_sin(t * 2) * sf * 0.72 * bobMul

	local bobYaw   = math_sin(t) * math_cos(t * 0.35) * sf * 0.30 * bobMul

-- apply
	angles[1] = angles[1] + bobPitch + noiseAng[1]
	angles[2] = angles[2] + bobYaw   + noiseAng[2]
	angles[3] = angles[3] + tiltLerp
end)

-- viewpunch impulse
hook.Add("HG_PlayerFootstep_Notify", "RunBob_StepPulse", function(ply, pos, foot, sound, volume)
	if ply ~= LocalPlayer() then return end
	if not hg_runbob_enabled:GetBool() then return end

	local stepMul = hg_runbob_step:GetFloat()
	if stepMul <= 0 then return end

	local vel = ply:GetVelocity()
	local sf  = speedFactor(vel)
	if sf < 0.06 then return end

	local side = (foot == 0) and -1 or 1

	ViewPunch(Angle(
		math_Rand(0.35, 0.90) * sf * stepMul,
		side * math_Rand(-0.08, 0.08) * sf * stepMul,
		side * math_Rand(0.50, 1.15)  * sf * stepMul
	))
end)
