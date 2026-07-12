if SERVER then
	util.AddNetworkString("remorseism_ban_notify")

	local function isAdmin(ply)
		if not IsValid(ply) then return false end
		if ply:IsAdmin() or ply:IsSuperAdmin() then return true end
		if ply.CheckGroup and (ply:CheckGroup("admin") or ply:CheckGroup("superadmin")) then return true end
		return false
	end

	local function sendBanNotify(name, steamid, reason, length, adminName, target)
		net.Start("remorseism_ban_notify")
			net.WriteString(name or steamid or "Unknown")
			net.WriteString(steamid or "")
			net.WriteString((reason and reason ~= "") and reason or "No reason given")
			net.WriteString(length or "permanently")
			net.WriteString(adminName or "")
		if IsValid(target) then net.Send(target) else net.Broadcast() end
	end

	local function niceTime(seconds)
		seconds = math.max(math.floor(seconds or 0), 1)
		if seconds >= 86400 then return math.ceil(seconds / 86400) .. " day(s)" end
		if seconds >= 3600 then return math.ceil(seconds / 3600) .. " hour(s)" end
		if seconds >= 60 then return math.ceil(seconds / 60) .. " minute(s)" end
		return seconds .. " second(s)"
	end

	hook.Add("ULibPlayerBanned", "remorseism_ban_notify", function(steamid, data)
		data = data or {}
		local length = "permanently"
		if data.unban and data.unban > 0 then length = "for " .. niceTime(data.unban - os.time()) end
		sendBanNotify(data.name, steamid, data.reason, length, data.admin or data.modified_admin)
	end)

	concommand.Add("remorse_ban_notify_preview", function(ply)
		if IsValid(ply) and not isAdmin(ply) then return end
		sendBanNotify(IsValid(ply) and ply:Nick() or "Preview Player", IsValid(ply) and ply:SteamID() or "STEAM_0:0:000000", "Preview ban notification", "for 1 hour", "Preview Admin", ply)
	end)
end

if CLIENT then
	local banMsg = nil
	local DURATION = 5
	local FADE_IN = 0.4
	local SHAKE_DUR = 0.6

	sound.Add({
		name = "remorseism_banished",
		channel = CHAN_AUTO,
		volume = 1.0,
		level = 80,
		sound = "rem_banished.ogg"
	})

	net.Receive("remorseism_ban_notify", function()
		banMsg = {
			name = net.ReadString(),
			steamid = net.ReadString(),
			reason = net.ReadString(),
			length = net.ReadString(),
			admin = net.ReadString(),
			startTime = CurTime()
		}
		surface.PlaySound("rem_banished.ogg")
	end)

	local fontCache = {}
	local function getFont(name, size, weight)
		if fontCache[name] then return end
		surface.CreateFont(name, { font = "Verily Serif Mono", size = size, weight = weight })
		fontCache[name] = true
	end

	hook.Add("HUDPaint", "remorseism_ban_notify", function()
		if not banMsg then return end

		local elapsed = CurTime() - banMsg.startTime
		if elapsed > DURATION then
			banMsg = nil
			return
		end

		local alpha
		if elapsed < FADE_IN then
			alpha = (elapsed / FADE_IN) * 255
		elseif elapsed > DURATION - 0.5 then
			alpha = ((DURATION - elapsed) / 0.5) * 255
		else
			alpha = 255
		end
		alpha = math.Clamp(alpha, 0, 255)

		local ox, oy = 0, 0
		if elapsed < SHAKE_DUR then
			local intensity = Lerp(elapsed / SHAKE_DUR, 14, 0)
			ox = math.random(-intensity, intensity)
			oy = math.random(-intensity, intensity)
		end

		local sw, sh = ScrW(), ScrH()
		local scale = math.min(sw / 1920, sh / 1080)
		local bigSize = math.Clamp(math.floor(60 * scale), 28, 96)
		local smallSize = math.Clamp(math.floor(34 * scale), 18, 58)
		local bigFont = "RBN_Big_" .. bigSize
		local smallFont = "RBN_Small_" .. smallSize

		getFont(bigFont, bigSize, 900)
		getFont(smallFont, smallSize, 700)

		local line1 = banMsg.name .. " has been banned " .. banMsg.length
		local line2 = "Reason: " .. banMsg.reason
		local line3 = banMsg.admin ~= "" and ("By: " .. banMsg.admin) or banMsg.steamid
		local topY = sh * 0.07

		local blink = (math.sin(elapsed * 4) + 1) / 2
		local r1 = math.floor(Lerp(blink, 120, 220))
		local r2 = math.floor(Lerp(blink, 80,  180))

		local fadeAlpha = alpha
		if elapsed > DURATION - 1.5 then
			fadeAlpha = alpha * ((DURATION - elapsed) / 1.5)
		end
		fadeAlpha = math.Clamp(fadeAlpha, 0, 255)

		local function drawCentered(text, font, y, r, g, b)
			surface.SetFont(font)
			local tw = surface.GetTextSize(text)
			local x = sw / 2 - tw / 2
			draw.SimpleText(text, font, x + ox + 2, y + oy + 2, Color(0, 0, 0, fadeAlpha * 0.7), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
			draw.SimpleText(text, font, x + ox, y + oy, Color(r, g, b, fadeAlpha), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
		end

		drawCentered(line1, bigFont, topY, r1, 0, 0)
		drawCentered(line2, smallFont, topY + bigSize + sh * 0.012, r2, 0, 0)
		drawCentered(line3, smallFont, topY + bigSize + smallSize + sh * 0.02, 180, 0, 0)
	end)
end
