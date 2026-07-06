

local DURATION   = 6      
local TARGET_FOV = 40     
local SLOW_SCALE = 0.35   



if SERVER then
	util.AddNetworkString("rem_clearround")

	local startSys

	local function TimeScaleThink()
		local e = SysTime() - (startSys or 0)
		local scale

		if e >= DURATION then
			game.SetTimeScale(1)
			hook.Remove("Think", "rem_clearround_timescale")
			return
		elseif e < 0.4 then
			-- slow down fast
			scale = Lerp(e / 0.4, 1, SLOW_SCALE)
		elseif e < DURATION - 1.5 then
			scale = SLOW_SCALE
		else
			-- speed back up over the last 1.5s
			scale = Lerp((e - (DURATION - 1.5)) / 1.5, SLOW_SCALE, 1)
		end

		game.SetTimeScale(scale)
	end

	hook.Add("ZB_EndRound", "rem_clearround", function()
		net.Start("rem_clearround")
		net.Broadcast()

		startSys = SysTime()
		hook.Add("Think", "rem_clearround_timescale", TimeScaleThink)
	end)

	return
end



surface.CreateFont("Rem_ClearRound", {
	font      = "ITC Avant Garde Gothic",
	size      = math.floor(ScrH() * 0.2),
	weight    = 700,
	antialias = true,
	extended  = true,
})

local hg_fov = ConVarExists("hg_fov") and GetConVar("hg_fov")

local active  = false
local startSys = 0
local channel  = nil

local function PlayClearSound()
	if IsValid(channel) then
		channel:Stop()
		channel = nil
	end

	sound.PlayFile("sound/rem_clearround.wav", "", function(chan, errId)
		if IsValid(chan) then
			channel = chan
			chan:SetVolume(1)
			chan:Play()
		else

			surface.PlaySound("rem_clearround.wav")
		end
	end)
end

net.Receive("rem_clearround", function()
	active   = true
	startSys = SysTime()
	PlayClearSound()
end)


local function FovFraction(e)
	if e < 0.35 then
		return math.ease.OutQuad(e / 0.35)
	elseif e < 0.7 then
		return 1
	elseif e < DURATION then
		return 1 - math.ease.InOutSine((e - 0.7) / (DURATION - 0.7))
	end
	return 0
end


hook.Add("HG_CalcView", "rem_clearround_fov", function(ply, origin, angles, fova)
	if not active then return end

	if not istable(fova) then return end

	local frac = FovFraction(SysTime() - startSys)
	if frac <= 0 then return end

	local base = hg_fov and math.Clamp(hg_fov:GetFloat(), 75, 100) or 90
	fova[1] = fova[1] + (TARGET_FOV - base) * frac
end)


hook.Add("Think", "rem_clearround_tick", function()
	if not active then return end

	local e = SysTime() - startSys

	if IsValid(channel) then

		local vol = e < 1 and 1 or math.Clamp(1 - (e - 1) / (DURATION - 1), 0, 1)
		channel:SetVolume(vol)
	end

	if e >= DURATION then
		active = false
		if IsValid(channel) then
			channel:Stop()
			channel = nil
		end
	end
end)

hook.Add("HUDPaint", "rem_clearround_hud", function()
	if not active then return end

	local e = SysTime() - startSys
	if e >= DURATION then return end


	local a
	if e < 0.3 then
		a = e / 0.3
	elseif e < DURATION - 1 then
		a = 1
	else
		a = math.Clamp((DURATION - e) / 1, 0, 1)
	end

	local alpha   = math.floor(a * 255)
	local x, y    = ScrW() * 0.5, ScrH() * 0.5
	local outline = math.max(2, math.floor(ScrH() * 0.004))

	draw.SimpleTextOutlined(
		"CLEAR", "Rem_ClearRound", x, y,
		Color(0, 0, 0, alpha),                
		TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER,
		outline, Color(255, 255, 255, alpha)   
	)
end)
