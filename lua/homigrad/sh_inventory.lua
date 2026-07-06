hg.TraitorLoot = {
	["weapon_sogknife"] = 10,
	["weapon_buck200knife"] = 10,
	["weapon_hg_shuriken"] = 9,
	["weapon_p22"] = 9,
	["weapon_traitor_ied"] = 8,
	["weapon_traitor_poison1"] = 7,
	["weapon_traitor_poison2"] = 6,
	["weapon_traitor_poison3"] = 5,
	["weapon_hg_smokenade_tpik"] = 4,
	["weapon_hg_rgd_tpik"] = 3,
	["weapon_walkie_talkie"] = 2,
	["weapon_adrenaline"] = 1,
	["hg_flashlight"] = 1,
}

if CLIENT then
	hook.Add("Player_Death","foundloot",function(ply)
		if IsValid(ply.FakeRagdoll) then ply.FakeRagdoll.foundloot = table.Copy(ply.foundloot) end
		ply.foundloot = {}
	end)

	local OpenInv
	net.Receive("should_open_inv", function()
		local ent = net.ReadEntity()
		OpenInv(ent)
	end)

	local colRed = Color(255, 0, 0, 255)
	local colBlack2 = Color(100, 100, 100)
	local colBlack3 = Color(50, 50, 50, 120)
	local colBlue = Color(150, 150, 150)
	local flashlightIcon = Material("vgui/hud/hmcd_flash")
	local slingIcon = Material("vgui/inventory/tactical_sling")
	local brassKnucklesIcon = Material("vgui/inventory/weapon_brassknuckles")
	local ammoIcons = {}
	local buttons = {}
	local function nameThings(i, thing)
		local weps = weapons.Get(i)
		local entss = scripted_ents.Get(i)
		if weps then return weps.PrintName end
		if entss then return entss.PrintName end
		if hg.armor and hg.armor[i] and hg.armor[i][thing] then return thing end
		if hg.attachmentslaunguage and hg.attachmentslaunguage[thing] then return thing end
		if i == "Money" then return "Money, " .. tostring(thing) .. "$" end
		return tostring(i)
	end

	local function getAmmoIcon(i)
		local ammoName = game.GetAmmoName(tonumber(i) or i) or tostring(i)
		local ammoKey = string.lower(string.gsub(ammoName, "%s+", ""))
		local ammoData = hg.ammoents and hg.ammoents[ammoKey]
		local icon = ammoData and ammoData.Icon
		if not icon then
			local entData = scripted_ents.Get("ent_ammo_" .. ammoKey)
			icon = entData and entData.IconOverride
		end
		icon = icon or "vgui/hud/bullets/high_caliber.png"
		ammoIcons[icon] = ammoIcons[icon] or Material(icon)
		return ammoIcons[icon]
	end

	local function getIconThing(i, thing, tab)
		if i == "hg_flashlight" then
			return flashlightIcon, true, false, true
		end
		if i == "hg_sling" then
			return slingIcon, true, false, true
		end
		if i == "hg_brassknuckles" then
			return brassKnucklesIcon, true, false, true
		end
		if tab == "Ammo" then
			return getAmmoIcon(i), true, false, true
		end

		if tab == "Weapons" and weapons.Get(i) then
			local GunTable = weapons.Get(i)
			--print(GunTable.WepSelectIcon2)
			local Icon = (GunTable.WepSelectIcon2 ~= nil and GunTable.WepSelectIcon2) or GunTable.WepSelectIcon
			local Overide = GunTable.WepSelectIcon2 == nil and true or false
			local HaveIcon = true
			return Icon, HaveIcon, Overide, GunTable.WepSelectIcon2box
		end

		if tab == "Attachments" and hg.attachmentsIcons[thing] then
			local AttIcon = hg.attachmentsIcons[thing]
			local HaveIcon = true
			return AttIcon, HaveIcon, false, true
		end

		if tab == "Armor" then
			local AttIcon = hg.armorIcons[thing]
			local HaveIcon = true
			return AttIcon, HaveIcon, false, true
		end

		if tab == "Money" then
			local AttIcon = "scrappers/money_icon.png"
			local HaveIcon = true
			return AttIcon, HaveIcon, false
		end
	end

	local functions2 = {
		["Weapons"] = function(ply, ent, wep)
			if true then return true end
		end,
		["Ammo"] = function(ply, ent, ammo, amt)
			if true then return true end
		end,
		["Armor"] = function(ply, ent, placement, armor)
			if hg.armor[placement][armor].nodrop then return false end
			if true then return true end
		end,
		["Attachments"] = function(ply, ent, att, tbl)
			if true then return true end
		end,
		["Money"] = function(ply, ent)
			if true then return true end
		end,
	}

	local functions = {
		["Weapons"] = function(ply, ent, wep)
			local weapon = weapons.Get(wep)
			if (ent:IsPlayer() and IsValid(ent:GetActiveWeapon()) and ent:GetActiveWeapon() == wep) then return end
			--if not hg.weaponInv.CanInsert(ply, weapon) or ply:HasWeapon(wep) then return false end
			return true
		end,
		["Ammo"] = function(ply, ent, ammo, amt)
			if true then return true end
		end,
		["Armor"] = function(ply, ent, placement, armor)
			local armors = ply:GetNetVar("Armor",{})
			if armors[placement] then return false end
			if true then return true end
		end,
		["Attachments"] = function(ply, ent, att, tbl)
			if true then return true end
		end,
		["Money"] = function(ply, ent)
			if true then return true end
		end,
	}

	local cooldown = 0

	local function TakeItem(tblIndex, thing, item, owner)
		local item = istable(item) and item or {item}

		net.Start("ply_take_item")
			net.WriteString(tblIndex)
			net.WriteString(thing)
			net.WriteTable(item)
			net.WriteEntity(owner)
		net.SendToServer()
	end

	local plyMenu
	local chosen
	local chooseButton
	local chooseButtonHuy
	local blurMat = Material("pp/blurscreen")
	local lootMenuGradient = Material("vgui/gradient-d")
	local Dynamic = 0
	BlurBackground = BlurBackground or hg.DrawBlur

	hook.Add("OnNetVarSet","inventory_netvar",function(index,key,var)
		if key == "Inventory" then
			local ent = Entity(index)

			if IsValid(plyMenu) and plyMenu.entindex == index then
				timer.Simple(0,function()
					--OpenInv(ent)
				end)
			end
		end
	end)

	local clr_text = Color(255,255,255,45)
	local function drawBouncingText(pnl, text, font, x, y, maxW, col)
		surface.SetFont(font)
		local textW, textH = surface.GetTextSize(text)
		if textW <= maxW then
			draw.SimpleText(text, font, x, y, col, TEXT_ALIGN_CENTER)
			return
		end

		local left = x - maxW / 2
		local sx, sy = pnl:LocalToScreen(left, y)
		local offset = (textW - maxW) * ((1 - math.cos(CurTime() * 1.4)) / 2)
		render.SetScissorRect(sx, sy, sx + maxW, sy + textH, true)
		surface.SetTextColor(col)
		surface.SetTextPos(left - offset, y)
		surface.DrawText(text)
		render.SetScissorRect(0, 0, 0, 0, false)
	end
	OpenInv = function(ent)
		if IsValid(plyMenu) then
			plyMenu:Remove()
			plyMenu = nil
		end
		
		cooldown = CurTime() + 0

		if not IsValid(ent) then return end

		local ply = LocalPlayer()
		Dynamic = 0
		local inv = ent:GetNetVar("Inventory")
		if not inv then return end
		inv["Money"] = {}
		-- local entmoney = ent:GetNetVar("zb_Scrappers_RaidMoney") or 0
		-- if entmoney > 0 then inv["Money"]["Money"] = entmoney end
		local armor = ent:GetNetVar("Armor")
		inv["Armor"] = armor
		ent.foundloot = ent.foundloot or {}

		local nameStr = "Container"
		local isBodyInventory = false
		if IsValid(ent) then
			if (ent:IsPlayer() or ent:IsRagdoll()) then
				isBodyInventory = true
				nameStr = ent:GetPlayerName() or string.NiceName(ent:GetClass())
			end
		end
		local name = isBodyInventory and (nameStr .. "'s inventory") or nameStr
		local sizeX = math.floor(math.min(math.max(ScrW() * 0.62, 420), ScrW() - 20, 980))
		local sizeY = math.floor(math.min(math.max(ScrH() * 0.74, 360), ScrH() - 20, 760))
		plyMenu = vgui.Create("ZFrame")
		plyMenu.ent = ent
		plyMenu.entindex = ent:EntIndex()

		plyMenu:SetTitle("")
		plyMenu:SetSize(sizeX, sizeY)
		plyMenu:Center()
		plyMenu:MakePopup()
		plyMenu:SetKeyBoardInputEnabled(false)
		plyMenu:ShowCloseButton(true)
		plyMenu:SetVisible(true)
		plyMenu:SetColorBG(Color(0, 0, 0, 245))
		plyMenu:SetColorBR(Color(255, 255, 255, 255))
		plyMenu.Created = CurTime()
		plyMenu.Paint = function(self, w, h)
			hg.DrawBlur(self, 2)
			surface.SetDrawColor(0, 0, 0, 245)
			surface.DrawRect(0, 0, w, h)
			surface.SetDrawColor(40, 40, 40, 55)
			surface.SetMaterial(lootMenuGradient)
			surface.DrawTexturedRect(0, 0, w, h)
			surface.SetDrawColor(255, 255, 255, 255)
			surface.DrawOutlinedRect(0, 0, w, h, 1)
		end
		if IsValid(plyMenu.btnClose) then
			plyMenu.btnClose:SetVisible(false)
			plyMenu.btnClose:SetMouseInputEnabled(false)
		end
		local close = plyMenu:Add("DButton")
		close:SetPos(sizeX - 38, 10)
		close:SetSize(28, 28)
		close:SetText("X")
		close.Paint = function(self, w, h)
			surface.SetDrawColor(self:IsHovered() and Color(34, 34, 34, 235) or Color(20, 20, 20, 235))
			surface.DrawRect(0, 0, w, h)
			surface.SetDrawColor(255, 255, 255, 255)
			surface.DrawOutlinedRect(0, 0, w, h, 1)
			draw.SimpleText(self:GetText(), "ZCity_Menu_Settings_Small", w * 0.5, h * 0.5, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		end
		close.DoClick = function()
			plyMenu:Close()
		end
		plyMenu.PaintOver = function(self, w, h)
			draw.DrawText(name, "ZCity_Menu_Settings_Small", 14, 12, color_white, TEXT_ALIGN_LEFT)

			draw.DrawText("Hold LMB - Search | LMB - Take | RMB - Item menu", "ZCity_Tiny", w / 2, h - h*0.04 , clr_text, TEXT_ALIGN_CENTER)
		end
		function plyMenu:Think()
			local ent = self.ent
			if not IsValid(ent) then self:Close() return end
			if LocalPlayer().organism.otrub or not LocalPlayer():Alive() then self:Remove() return end
			if (ent:GetPos() - LocalPlayer():GetPos()):LengthSqr() > 125^2 then self:Remove() return end
			if ent:IsPlayer() and not IsValid(ent.FakeRagdoll) then self:Remove() return end
			if input.IsKeyDown(KEY_R) then
				self:Close()
			end
		end

		local cols = ScrW() < 900 and 5 or 6
		local gap = math.max(math.floor(ScrH() * 0.004), 4)
		local scrollLane = 16
		local minRows = ScrH() < 720 and 6 or 7
		local boardMaxW = sizeX - 28 - scrollLane
		local boardMaxH = sizeY - 88
		local cell = math.floor(math.max(math.min((boardMaxW - (cols + 1) * gap) / cols, (boardMaxH - (minRows + 1) * gap) / minRows), 42))
		local boardW = cols * cell + (cols + 1) * gap
		local boardH = minRows * cell + (minRows + 1) * gap
		local DScrollPanel = vgui.Create("DScrollPanel", plyMenu)
		DScrollPanel:SetPos(math.floor((sizeX - boardW - scrollLane) / 2), 44)
		DScrollPanel:SetSize(boardW + scrollLane, boardH)
		DScrollPanel.Paint = function(self, w, h)
			surface.SetDrawColor(0, 0, 0, 245)
			surface.DrawRect(0, 0, boardW, boardH)
			surface.SetDrawColor(40, 40, 40, 55)
			surface.SetMaterial(lootMenuGradient)
			surface.DrawTexturedRect(0, 0, boardW, boardH)
			surface.SetDrawColor(255, 255, 255, 255)
			surface.DrawOutlinedRect(0, 0, boardW, boardH, 1)
		end

		local sbar = DScrollPanel:GetVBar()
		sbar:SetHideButtons(true)
		sbar.Paint = function(self, w, h) draw.RoundedBox(0, w - 4, 0, 4, h, Color(30, 30, 30, 180)) end
		sbar.btnGrip.Paint = function(self, w, h) draw.RoundedBox(0, w - 4, 0, 4, h, Color(115, 115, 115, 230)) end

		local grid = vgui.Create("DPanel", DScrollPanel)
		local used = {}
		local maxRow = 1
		ent.lootGridLayout = ent.lootGridLayout or {real = {}, fake = nil}
		local lootLayout = ent.lootGridLayout
		grid:SetWide(boardW)
		grid.Paint = function(self, w, h)
			draw.RoundedBox(0, 0, 0, w, h, Color(24, 24, 24, 245))
			for y = 0, math.ceil(h / (cell + gap)) do
				for x = 0, cols - 1 do
					surface.SetDrawColor(42, 42, 42, 175)
					surface.DrawOutlinedRect(gap + x * (cell + gap), gap + y * (cell + gap), cell, cell, 1)
				end
			end
			surface.SetDrawColor(85, 85, 85, 230)
			surface.DrawOutlinedRect(0, 0, w, h, 1)
		end
		DScrollPanel:AddItem(grid)

		local function getLootWeight(tab, i, thing)
			if tab == "Weapons" then
				local wep = weapons.Get(i)
				if wep then return wep.weight or wep.Weight or ((wep.weaponInvCategory == 1) and 8 or 3) end
				return 3
			elseif tab == "Ammo" then
				local amt = tonumber(istable(thing) and thing[1] or thing) or 1
				return math.Clamp((game.GetAmmoForce(tonumber(i) or 0) * amt) / 1500, 0.8, 6)
			elseif tab == "Armor" then
				return (hg.armor and hg.armor[i] and hg.armor[i][thing] and hg.armor[i][thing].mass) or 4
			elseif tab == "Attachments" then
				return 1
			end
			return 1
		end

		local function getLootSize(weight)
			if weight == "armor" then return 2, 2 end
			if weight >= 8 then return 3, 2 end
			if weight >= 5 then return 2, 2 end
			if weight >= 2.5 then return 2, 1 end
			return 1, 1
		end

		local function canPlace(x, y, w, h)
			if x + w - 1 > cols then return false end
			for yy = y, y + h - 1 do
				for xx = x, x + w - 1 do
					if used[yy] and used[yy][xx] then return false end
				end
			end
			return true
		end

		local function occupyBlock(x, y, w, h)
			for yy = y, y + h - 1 do
				used[yy] = used[yy] or {}
				for xx = x, x + w - 1 do
					used[yy][xx] = true
				end
			end
			maxRow = math.max(maxRow, y + h - 1)
		end

		local function placeBlock(w, h)
			local candidates = {}
			local rows = math.max(minRows, maxRow + 3)
			for y = 1, rows do
				for x = 1, cols do
					if canPlace(x, y, w, h) then candidates[#candidates + 1] = {x, y} end
				end
			end
			if #candidates > 0 then
				local pos = candidates[math.random(#candidates)]
				occupyBlock(pos[1], pos[2], w, h)
				return pos[1], pos[2]
			end

			for y = rows + 1, 80 do
				for x = 1, cols do
					if canPlace(x, y, w, h) then
						occupyBlock(x, y, w, h)
						return x, y
					end
				end
			end
			occupyBlock(1, maxRow + 1, w, h)
			return 1, maxRow
		end

		local realCount = 0
		
		for tab, things in pairs(inv) do
			if not istable(things) then continue end
			local keys = table.GetKeys(things)
			table.sort(keys,function(a,b)
				local atbl = weapons.Get(a)
				local wep = atbl and atbl.holsteredBone and not atbl.shouldntDrawHolstered
				return (ent.foundloot[a] and 1 or 0) > (ent.foundloot[b] and 1 or 0)//(hg.TraitorLoot[a] or 0) < (hg.TraitorLoot[b] or (wep and 1 or 0) or 0)
			end)
			
			for k, i in ipairs(keys) do
				local thing = things[i]
				local thing1 = istable(thing) and thing or {thing}

				if not functions2[tab](ply, ent, i, unpack(thing1)) then continue end

				--ent.foundloot = {}
				ent.foundloot = ent.foundloot or {}

				if ent:IsPlayer() and IsValid(ent:GetActiveWeapon()) and ent:GetActiveWeapon():GetClass() == i then continue end
				realCount = realCount + 1
				local revealWeight = getLootWeight(tab, i, thing)
				local sizeWeight = (tab == "Armor" and "armor") or revealWeight
				if i == "hg_flashlight" or i == "hg_brassknuckles" then sizeWeight = 1 revealWeight = 1 end
				local blockW, blockH = getLootSize(sizeWeight)
				local layoutKey = tab .. ":" .. tostring(i)
				local saved = lootLayout.real[layoutKey]
				local blockX, blockY
				if saved and canPlace(saved.x, saved.y, blockW, blockH) then
					blockX, blockY = saved.x, saved.y
					occupyBlock(blockX, blockY, blockW, blockH)
				else
					blockX, blockY = placeBlock(blockW, blockH)
					lootLayout.real[layoutKey] = {x = blockX, y = blockY}
				end

				local button = vgui.Create("DButton", grid)
				button:SetText("")
				button:SetPos(gap + (blockX - 1) * (cell + gap), gap + (blockY - 1) * (cell + gap))
				button:SetSize(blockW * cell + (blockW - 1) * gap, blockH * cell + (blockH - 1) * gap)
				button.RevealTime = math.Clamp(0.45 + revealWeight * 0.24, 0.65, 4)
				button.Think = function(self)
					if ent.foundloot[i] then return end
					if self:IsHovered() and input.IsMouseDown(MOUSE_LEFT) then
						self.RevealStart = self.RevealStart or CurTime()
						self.RevealProgress = math.Clamp((CurTime() - self.RevealStart) / self.RevealTime, 0, 1)
						if self.RevealProgress >= 1 then
							ent.foundloot[i] = true
							self.HoldLock = true
							surface.PlaySound("arc9_eft_shared/generic_mag_pouch_in" .. math.random(7) .. ".ogg")
						end
					else
						self.RevealStart = nil
						self.RevealProgress = 0
						if not input.IsMouseDown(MOUSE_LEFT) then self.HoldLock = nil end
					end
				end
				
				button.DoClick = function()
					if button.HoldLock then button.HoldLock = nil return end
					if not ent.foundloot[i] then return end
					if cooldown > CurTime() then return end

					cooldown = CurTime() + 0.5
					
					if not functions[tab](ply, ent, i, unpack(thing1)) then
						local OptionsMenu = DermaMenu() 
							OptionsMenu:AddOption( "You have item like this", function() end )
						OptionsMenu:Open()
						return
					end
					if istable(thing) then
						thing["render"] = {}
					end
					
					surface.PlaySound("arc9_eft_shared/generic_mag_pouch_in" .. math.random(7) .. ".ogg")
					grid.SoundKD = CurTime() + 0.2
					button:Remove()
					TakeItem(tab, i, thing, ent)
					--timer.Simple(0.5 * math.max(ply:Ping() / 50,1),function()
					--	--OpenInv(ent)
					--end)
				end

				button.DoRightClick = function()
					if not ent.foundloot[i] then return end
					if cooldown > CurTime() then return end

					cooldown = CurTime() + 0.5

					
					if not functions[tab](ply, ent, i, unpack(thing1)) then
						local OptionsMenu = DermaMenu() 
							OptionsMenu:AddOption( "You have item like this", function() end )
						OptionsMenu:Open()
						return
					end
					if istable(thing) then
						thing["render"] = {}
					end
					
					surface.PlaySound("arc9_eft_shared/generic_mag_pouch_in" .. math.random(7) .. ".ogg")
					grid.SoundKD = CurTime() + 0.2
					--button:Remove()
					local OptionsMenu = DermaMenu() 
						OptionsMenu:AddOption( "Take", function() button:Remove() TakeItem(tab, i, thing, ent) end )
					OptionsMenu:Open()
					--timer.Simple(0.5 * math.max(ply:Ping() / 50,1),function()
					--	--OpenInv(ent)
					--end)
				end

				local name = nameThings(i, thing)
				button.col1 = 100
				button.Paint = function(self, w, h)
					local found = ent.foundloot[i]
					button.col1 = Lerp(0.1, button.col1, button:IsHovered() and 180 or 100)
					if button:IsHovered() then
						button.SoundKD = button.SoundKD or 0
						if (grid.SoundKD or 0) < CurTime() and button.SoundKD < CurTime() then surface.PlaySound("arc9_eft_shared/generic_mag_pouch_out" .. math.random(7) .. ".ogg") end
						button.SoundKD = CurTime() + 0.1
					end

					surface.SetDrawColor(38 + button.col1 / 8, 38 + button.col1 / 8, 38 + button.col1 / 8, 235)
					surface.DrawRect(0, 0, w, h)
					for yy = 0, blockH - 1 do
						for xx = 0, blockW - 1 do
							surface.SetDrawColor(70, 70, 70, 145)
							surface.DrawOutlinedRect(xx * (cell + gap), yy * (cell + gap), cell, cell, 1)
						end
					end
					if not found then
						draw.SimpleText("?", "ZCity_Small", w / 2, h / 2, Color(225, 225, 225), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
						if (button.RevealProgress or 0) > 0 then
							surface.SetDrawColor(150, 150, 150, 210)
							surface.DrawRect(6, h - 10, (w - 12) * button.RevealProgress, 4)
						end
						surface.SetDrawColor(button.col1, button.col1, button.col1, 210)
						surface.DrawOutlinedRect(0, 0, w, h, 1)
						return
					end
					local Icon, HaveIcon, Overide, Quad = getIconThing(i, thing, tab)
					if Icon then
						button.Icon = button.Icon or (isstring(Icon) and Material(Icon)) or Icon -- Ну тут так, без выбора если что материал будет
					end

					if HaveIcon then
						if Overide and isnumber( Icon ) then
							surface.SetTexture(button.Icon)
						else
							surface.SetMaterial(button.Icon)
						end

						surface.SetDrawColor(255, 255, 255)
						surface.DrawTexturedRect(Quad and w / 5 + 5 or 0 - 5, 5, Quad and (w / 2 + 2.5) or (w + 10), Quad and h / 1.3 or h - 10)
					end

					surface.SetDrawColor(button.col1, button.col1, button.col1, button.col1)
					surface.DrawOutlinedRect(0, 0, w, h, 1)
					local Text = (tab == "Ammo" and game.GetAmmoName(name)) or language.GetPhrase(name)
					drawBouncingText(self, Text, "ZCity_Tiny", w / 2, (HaveIcon and h / 1.3) or h / 3, w - 10, color_white)
				end
			end
		end

		if not lootLayout.fake then
			lootLayout.fake = {}
			local fakeCount = realCount > 0 and math.random(0, math.Clamp(math.ceil(realCount * 0.35), 1, 5)) or 0
			for i = 1, fakeCount do
				local blockW, blockH = math.random(1, 3) == 1 and 2 or 1, math.random(1, 4) == 1 and 2 or 1
				local blockX, blockY = placeBlock(blockW, blockH)
				lootLayout.fake[i] = {x = blockX, y = blockY, w = blockW, h = blockH, revealed = false}
			end
		end

		for i, fake in ipairs(lootLayout.fake) do
			if fake.revealed then continue end
			local blockW, blockH = fake.w, fake.h
			local blockX, blockY = fake.x, fake.y
			if not canPlace(blockX, blockY, blockW, blockH) then continue end
			occupyBlock(blockX, blockY, blockW, blockH)
			local button = vgui.Create("DButton", grid)
			button:SetText("")
			button:SetPos(gap + (blockX - 1) * (cell + gap), gap + (blockY - 1) * (cell + gap))
			button:SetSize(blockW * cell + (blockW - 1) * gap, blockH * cell + (blockH - 1) * gap)
			button.RevealTime = math.Rand(0.7, 1.8)
			button.Think = function(self)
				if self.Revealed then return end
				if self:IsHovered() and input.IsMouseDown(MOUSE_LEFT) then
					self.RevealStart = self.RevealStart or CurTime()
					self.RevealProgress = math.Clamp((CurTime() - self.RevealStart) / self.RevealTime, 0, 1)
					if self.RevealProgress >= 1 then
						self.Revealed = true
						fake.revealed = true
						self:AlphaTo(0, 0.2, 0, function(_, pnl) if IsValid(pnl) then pnl:Remove() end end)
						surface.PlaySound("arc9_eft_shared/generic_mag_pouch_out" .. math.random(7) .. ".ogg")
					end
				else
					self.RevealStart = nil
					self.RevealProgress = 0
				end
			end
			button.Paint = function(self, w, h)
				surface.SetDrawColor(self:IsHovered() and 62 or 45, self:IsHovered() and 62 or 45, self:IsHovered() and 62 or 45, 235)
				surface.DrawRect(0, 0, w, h)
				for yy = 0, blockH - 1 do
					for xx = 0, blockW - 1 do
						surface.SetDrawColor(70, 70, 70, 145)
						surface.DrawOutlinedRect(xx * (cell + gap), yy * (cell + gap), cell, cell, 1)
					end
				end
				draw.SimpleText("?", "ZCity_Small", w / 2, h / 2, Color(225, 225, 225), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
				if (self.RevealProgress or 0) > 0 then
					surface.SetDrawColor(150, 150, 150, 210)
					surface.DrawRect(6, h - 10, (w - 12) * self.RevealProgress, 4)
				end
				surface.SetDrawColor(120, 120, 120, 210)
				surface.DrawOutlinedRect(0, 0, w, h, 1)
			end
		end
		grid:SetTall(math.max(maxRow, minRows) * cell + (math.max(maxRow, minRows) + 1) * gap)
	--plyMenu:SlideDown(0.5)
	end
end
