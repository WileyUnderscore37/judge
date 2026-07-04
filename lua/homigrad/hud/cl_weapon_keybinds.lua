if true then return end --scrapped, cant be bothered with this. doubt anyone will use it

hg = hg or {}
hg.WeaponKeybinds = hg.WeaponKeybinds or {}

local WK = hg.WeaponKeybinds

local panelXMul = 0.79
local panelYMul = 0.68
local panelMinWidth = 300
local panelPadding = 14
local rowGap = 8
local titleGap = 10
local keyBoxPaddingX = 12
local keyBoxPaddingY = 6
local keyActionGap = 12
local outlineThickness = 1
local screenRightPadding = 14
local displayTime = 5
local fadeSpeed = 12
local panelBg = Color(0, 0, 0, 220)
local panelOutline = Color(255, 255, 255, 255)
local textColor = Color(255, 255, 255, 255)
local faintTextColor = Color(255, 255, 255, 220)

surface.CreateFont("HGWeaponKeybindsTitle", {
	font = "Verily Serif Mono",
	size = 22,
	weight = 700,
	antialias = true
})

surface.CreateFont("HGWeaponKeybindsText", {
	font = "Verily Serif Mono",
	size = 18,
	weight = 500,
	antialias = true
})

surface.CreateFont("HGWeaponKeybindsKey", {
	font = "Verily Serif Mono",
	size = 18,
	weight = 700,
	antialias = true
})

local tokenBindingMap = {
	["R"] = "+reload",
	["RELOAD"] = "+reload",
	["LMB"] = "+attack",
	["RMB"] = "+attack2",
	["MMB"] = "mouse3",
	["E"] = "+use",
	["USE"] = "+use",
	["SHIFT"] = "+speed",
	["SPEED"] = "+speed",
	["ALT"] = "+walk",
	["WALK"] = "+walk",
	["SPACE"] = "+jump",
	["JUMP"] = "+jump"
}

local prettyBindingMap = {
	["MOUSE1"] = "LMB",
	["MOUSE2"] = "RMB",
	["MOUSE3"] = "MMB",
	["ENTER"] = "LMB",
	["MWHEELUP"] = "MWHEELUP",
	["MWHEELDOWN"] = "MWHEELDOWN",
	["KP_INS"] = "KP0",
	["KP_END"] = "KP1",
	["KP_DOWNARROW"] = "KP2",
	["KP_PGDN"] = "KP3",
	["KP_LEFTARROW"] = "KP4",
	["KP_5"] = "KP5",
	["KP_RIGHTARROW"] = "KP6",
	["KP_HOME"] = "KP7",
	["KP_UPARROW"] = "KP8",
	["KP_PGUP"] = "KP9",
	["KP_ENTER"] = "LMB",
	["KP_PLUS"] = "KP +",
	["KP_MINUS"] = "KP -",
	["KP_DEL"] = "KP .",
	["KP_SLASH"] = "KP /",
	["KP_MULTIPLY"] = "KP *"
}

local specialActionByClass = {
	["weapon_hammer"] = {
		["R + LMB"] = "Change attack mode",
		["RMB + LMB"] = "Nail / pull nails"
	}
}

local derivedActionsByClass = {
	["weapon_ducttape"] = {
		{"LMB", "Tape objects"}
	},
	["weapon_matches"] = {
		{"LMB", "Ignite match"}
	},
	["weapon_walkie_talkie"] = {
		{"LMB", "Radio menu"},
		{"R", "Toggle radio"}
	},
	["weapon_bloodbag"] = {
		{"LMB", "Use on self"},
		{"RMB", "Use on target"},
		{"R", "Change mode"}
	}
}

local derivedActionsByBase = {
	["weapon_bandage_sh"] = {
		{"LMB", "Use on self"},
		{"RMB", "Use on target"},
		{"R", "Change mode"}
	},
	["weapon_hg_medicine_base"] = {
		{"LMB", "Use on self"}
	},
	["weapon_bigconsumable"] = {
		{"LMB", "Consume"}
	}
}

local function formatBindingToken(token)
	token = string.Trim(string.upper(token or ""))
	if token == "" then return "" end
	token = string.Replace(token, "+", "")
	token = string.Replace(token, "\"", "")
	token = string.Replace(token, "'", "")
	token = string.Replace(token, "_", " ")
	token = prettyBindingMap[token] or token
	return token
end

local function resolveBindingToken(token)
	token = formatBindingToken(token)
	local bindKey = tokenBindingMap[token]
	if bindKey then
		local bound = input.LookupBinding(bindKey)
		if bound and bound ~= "" then
			return formatBindingToken(bound)
		end
	end
	return token
end

local function normalizeCombo(combo)
	local tokens = {}
	for token in string.gmatch(combo or "", "[^%+]+") do
		local resolved = resolveBindingToken(token)
		if resolved ~= "" then
			tokens[#tokens + 1] = resolved
		end
	end
	return table.concat(tokens, " + ")
end

local function normalizeAction(action)
	action = string.Trim(action or "")
	action = string.gsub(action, "%.$", "")
	if action == "" then return "" end
	local lower = string.lower(action)
	if lower == "apply on others" or lower == "use on someone else" then
		action = "Use on target"
	elseif lower == "change use mode" or lower == "change treatment mode" then
		action = "Change mode"
	elseif lower == "open radio menu" then
		action = "Radio menu"
	elseif lower == "toggle power" then
		action = "Toggle radio"
	elseif lower == "hold to tape objects" then
		action = "Tape objects"
	elseif lower == "hold to ignite a match" then
		action = "Ignite match"
	elseif lower == "hold to consume" then
		action = "Consume"
	end
	local first = string.upper(string.sub(action, 1, 1))
	return first .. string.sub(action, 2)
end

local function bindPatternFound(text)
	local lower = string.lower(text or "")
	return string.find(lower, "lmb", 1, true)
		or string.find(lower, "rmb", 1, true)
		or string.find(lower, "%f[%a]reload%f[%A]")
		or string.find(lower, "r +", 1, true)
		or string.find(lower, "r+", 1, true)
		or string.find(lower, "%f[%a]r%f[%A]")
		or string.find(lower, "%f[%a]shift%f[%A]")
		or string.find(lower, "%f[%a]walk%f[%A]")
		or string.find(lower, "%f[%a]alt%f[%A]")
		or string.find(lower, "%f[%a]space%f[%A]")
		or string.find(lower, "%f[%a]use%f[%A]")
		or string.find(lower, "%f[%a]e%f[%A]")
end

local function splitInstructionChunk(chunk)
	local lowerChunk = string.lower(chunk or "")
	local bindStart = math.huge
	local candidates = {
		string.find(lowerChunk, "%f[%a]lmb%f[%A]"),
		string.find(lowerChunk, "%f[%a]rmb%f[%A]"),
		string.find(lowerChunk, "%f[%a]reload%f[%A]"),
		string.find(lowerChunk, "%f[%a]shift%f[%A]"),
		string.find(lowerChunk, "%f[%a]walk%f[%A]"),
		string.find(lowerChunk, "%f[%a]alt%f[%A]"),
		string.find(lowerChunk, "%f[%a]space%f[%A]"),
		string.find(lowerChunk, "%f[%a]use%f[%A]"),
		string.find(lowerChunk, "%f[%a]e%f[%A]"),
		string.find(lowerChunk, "%f[%a]r%f[%A]"),
		string.find(lowerChunk, "r +", 1, true),
		string.find(lowerChunk, "r+", 1, true)
	}
	for _, startPos in ipairs(candidates) do
		if startPos and startPos < bindStart then
			bindStart = startPos
		end
	end
	if bindStart == math.huge then return end
	chunk = string.Trim(string.sub(chunk, bindStart))
	local combo, action = string.match(chunk, "^(.-)%s+[Tt][Oo]%s+(.+)$")
	if not combo then
		combo, action = string.match(chunk, "^(.-)%s*%-%s*(.+)$")
	end
	if not combo or not action then return end
	combo = string.Trim(combo)
	action = string.Trim(action)
	local lowerCombo = string.lower(combo)
	if string.sub(lowerCombo, 1, 5) == "hold " then
		combo = string.Trim(string.sub(combo, 6))
		action = "Hold to " .. action
	elseif string.sub(lowerCombo, 1, 6) == "press " then
		combo = string.Trim(string.sub(combo, 7))
	end
	return combo, action
end

local function actionExists(existing, action)
	for part in string.gmatch(existing or "", "[^/]+") do
		if string.Trim(part) == action then
			return true
		end
	end
	return false
end

local function upsertBind(rows, seen, combo, action)
	combo = normalizeCombo(combo)
	action = normalizeAction(action)
	if combo == "" or action == "" then return end
	if seen[combo] then
		local row = rows[seen[combo]]
		if not actionExists(row.action, action) then
			row.action = row.action .. " / " .. action
		end
		return
	end
	rows[#rows + 1] = {
		combo = combo,
		action = action
	}
	seen[combo] = #rows
end

local function extractInstructionBinds(wep, rows, seen)
	local instructions = wep.Instructions
	if not isstring(instructions) or instructions == "" then return end

	local context

	for rawLine in string.gmatch(instructions, "[^\n]+") do
		local line = string.Trim(rawLine)
		if line == "" then
			context = nil
		elseif string.sub(line, -1) == ":" and not bindPatternFound(line) then
			context = string.sub(line, 1, -2)
		else
			local inlineContext, inlineContent = string.match(line, "^(.-):%s*(.+)$")
			local activeContext = context
			if inlineContext and inlineContent and bindPatternFound(inlineContent) then
				activeContext = string.Trim(inlineContext)
				line = string.Trim(inlineContent)
			end

			for segment in string.gmatch(line, "[^,]+") do
				local chunk = string.Trim(segment)
				local combo, action = splitInstructionChunk(chunk)
				if combo and action and bindPatternFound(combo) then
					action = string.Trim(action)
					if activeContext and activeContext ~= "" then
						action = activeContext .. " - " .. action
					end
					upsertBind(rows, seen, combo, action)
				end
			end
		end
	end
end

local function addDerivedMappedBinds(wep, rows, seen)
	local classActions = derivedActionsByClass[wep:GetClass()]
	if classActions then
		for _, entry in ipairs(classActions) do
			upsertBind(rows, seen, entry[1], entry[2])
		end
	end

	local baseActions = derivedActionsByBase[wep.Base]
	if baseActions then
		for _, entry in ipairs(baseActions) do
			upsertBind(rows, seen, entry[1], entry[2])
		end
	end
end

local function isMeleeWeapon(wep)
	return wep.ismelee or wep.ismelee2 or wep.Base == "weapon_melee"
end

local function canCallMethod(wep, name)
	return wep and isfunction(wep[name])
end

local function getMethodBool(wep, name, fallback)
	if not canCallMethod(wep, name) then
		return fallback
	end
	local ok, value = pcall(wep[name], wep)
	if not ok then
		return fallback
	end
	if value == nil then
		return fallback
	end
	return value and true or false
end

local function addDerivedMeleeBinds(wep, rows, seen)
	upsertBind(rows, seen, "LMB", "Attack")

	if getMethodBool(wep, "CanBlock", true) then
		upsertBind(rows, seen, "RMB", "Block")
	end

	if wep.canchargeattack then
		upsertBind(rows, seen, "R + LMB", "Charge attack")
	end

	if getMethodBool(wep, "CanSecondaryAttack", false) then
		upsertBind(rows, seen, "RMB + LMB", "Secondary attack")
	end
end

local function addDerivedGunBinds(wep, rows, seen)
	upsertBind(rows, seen, "LMB", "Fire")
	upsertBind(rows, seen, "RMB", "Aim")
	upsertBind(rows, seen, "R", wep.CockSound and "Reload / pump" or "Reload")
	upsertBind(rows, seen, "ALT + R", "Check ammo")
	upsertBind(rows, seen, "E + LMB", "Buttstroke")
end

local function applySpecialActions(wep, rows, seen)
	local special = specialActionByClass[wep:GetClass()]
	if not special then return end
	for combo, action in pairs(special) do
		upsertBind(rows, seen, combo, action)
	end
end

local function collectWeaponBinds(wep)
	local rows = {}
	local seen = {}

	extractInstructionBinds(wep, rows, seen)

	if isMeleeWeapon(wep) then
		addDerivedMeleeBinds(wep, rows, seen)
	elseif wep.ishgweapon or wep.Base == "homigrad_base" then
		addDerivedGunBinds(wep, rows, seen)
	end

	addDerivedMappedBinds(wep, rows, seen)
	applySpecialActions(wep, rows, seen)

	return rows
end

local function getWeaponTitle(wep)
	if wep.GetPrintName then
		local name = wep:GetPrintName()
		if name and name ~= "" then
			return name
		end
	end
	return wep:GetClass()
end

local function measureText(font, text)
	surface.SetFont(font)
	return surface.GetTextSize(text)
end

local function drawText(text, font, x, y, color)
	draw.SimpleText(text, font, x, y, color, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
end

local function setDisplayWeapon(wep)
	if IsValid(wep) then
		WK.rows = collectWeaponBinds(wep)
		WK.title = getWeaponTitle(wep)
		WK.showUntil = CurTime() + displayTime
	else
		WK.rows = nil
		WK.title = nil
		WK.showUntil = 0
	end
end

local function findPickedUpWeapon(ply, activeWep)
	local current = {}
	local picked

	for _, ownedWep in ipairs(ply:GetWeapons()) do
		if IsValid(ownedWep) then
			local entIndex = ownedWep:EntIndex()
			current[entIndex] = true
			if WK.knownWeapons and not WK.knownWeapons[entIndex] then
				picked = picked or ownedWep
				if ownedWep == activeWep then
					picked = ownedWep
				end
			end
		end
	end

	if not WK.knownWeapons then
		WK.knownWeapons = current
		return
	end

	WK.knownWeapons = current
	return picked
end

local function drawPanel(alpha)
	local rows = WK.rows
	if not rows or #rows < 1 then return end

	local title = WK.title or "Weapon Keybinds"
	local titleW, titleH = measureText("HGWeaponKeybindsTitle", title)
	local width = math.max(panelMinWidth, titleW + panelPadding * 2)
	local rowHeight = 0
	local comboHeights = {}
	local comboWidths = {}
	local boxHeights = {}
	local boxWidths = {}
	local actionWidths = {}

	for index, row in ipairs(rows) do
		local comboW, comboH = measureText("HGWeaponKeybindsKey", row.combo)
		local actionW, actionH = measureText("HGWeaponKeybindsText", row.action)
		local boxW = comboW + keyBoxPaddingX * 2
		local boxH = comboH + keyBoxPaddingY * 2
		comboWidths[index] = comboW
		comboHeights[index] = comboH
		boxWidths[index] = boxW
		boxHeights[index] = boxH
		actionWidths[index] = actionW
		rowHeight = math.max(rowHeight, math.max(boxH, actionH))
		width = math.max(width, panelPadding * 2 + actionW + keyActionGap + boxW)
	end

	local height = panelPadding * 2 + titleH + titleGap
	if #rows > 0 then
		height = height + (#rows * rowHeight) + ((#rows - 1) * rowGap)
	end

	local x = ScrW() - width - screenRightPadding
	local y = ScrH() * panelYMul - height * 0.5
	local bgAlpha = panelBg.a * alpha
	local lineAlpha = panelOutline.a * alpha
	local textAlpha = textColor.a * alpha
	local faintAlpha = faintTextColor.a * alpha

	draw.SimpleText(title, "HGWeaponKeybindsTitle", x + width - panelPadding, y + panelPadding, Color(textColor.r, textColor.g, textColor.b, textAlpha), TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)

	local rowY = y + panelPadding + titleH + titleGap
	for index, row in ipairs(rows) do
		local comboH = comboHeights[index]
		local boxW = boxWidths[index]
		local boxH = boxHeights[index]
		local actionH = select(2, measureText("HGWeaponKeybindsText", row.action))
		local boxY = rowY + (rowHeight - boxH) * 0.5
		local actionY = rowY + (rowHeight - actionH) * 0.5
		local keyX = x + width - panelPadding
		local boxX = keyX - boxW

		drawText(row.action, "HGWeaponKeybindsText", x + panelPadding, actionY, Color(faintTextColor.r, faintTextColor.g, faintTextColor.b, faintAlpha))
		surface.SetDrawColor(panelBg.r, panelBg.g, panelBg.b, bgAlpha)
		surface.DrawRect(boxX, boxY, boxW, boxH)
		surface.SetDrawColor(panelOutline.r, panelOutline.g, panelOutline.b, lineAlpha)
		surface.DrawOutlinedRect(boxX, boxY, boxW, boxH, outlineThickness)
		draw.SimpleText(row.combo, "HGWeaponKeybindsKey", boxX + boxW * 0.5, boxY + boxH * 0.5, Color(textColor.r, textColor.g, textColor.b, textAlpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

		rowY = rowY + rowHeight + rowGap
	end
end

hook.Add("HUDPaint", "HGWeaponKeybinds_Draw", function()
	local ply = LocalPlayer()
	if not IsValid(ply) or not ply:Alive() then
		WK.activeWeapon = nil
		WK.knownWeapons = nil
		WK.rows = nil
		WK.title = nil
		WK.showUntil = 0
		WK.alpha = Lerp(FrameTime() * fadeSpeed, WK.alpha or 0, 0)
		return
	end

	local wep = ply:GetActiveWeapon()
	local pickedWep = findPickedUpWeapon(ply, wep)

	local changed = wep ~= WK.activeWeapon

	if changed then
		WK.activeWeapon = wep
		setDisplayWeapon(wep)
	end

	if IsValid(pickedWep) then
		setDisplayWeapon(pickedWep)
	end

	local shouldShow = WK.rows and #WK.rows > 0 and (WK.showUntil or 0) > CurTime()
	WK.alpha = Lerp(FrameTime() * fadeSpeed, WK.alpha or 0, shouldShow and 1 or 0)

	if (WK.alpha or 0) <= 0.01 then return end

	drawPanel(WK.alpha)
end)
