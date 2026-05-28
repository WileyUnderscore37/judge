-- RunConsoleCommand("net_compresspackets", "1")
-- RunConsoleCommand("net_maxcleartime", "4")
-- RunConsoleCommand("vfire_light_brightness", "0.1")

-- RunConsoleCommand("filesystem_max_stdio_read", "16")
-- RunConsoleCommand("net_splitpacket_maxrate", "1048576")
-- RunConsoleCommand("net_udp_rcvbuf", "131072")


--\\ Fuel system for glide
	local function override()
		if BlackterioExtraFunctions and BlackterioExtraFunctions.UpdateFuel then
			function BlackterioExtraFunctions:UpdateFuel(vehicle, config)
				if vehicle.GetFuel and vehicle.GetMaxFuel then
					local fuel = (vehicle:GetFuel() / vehicle:GetMaxFuel())

					if not vehicle.fuel then
						vehicle.fuel = 0
					end

					if vehicle:GetEngineState() > 1 then
						local rpmFraction = vehicle:GetEngineRPM() / vehicle:GetMaxRPM()
						local fuel2 = (vehicle:GetFuel() <= 0 and rpmFraction) or fuel

						vehicle.fuel = Lerp(config.fuelLerpRate, vehicle.fuel, fuel2)
					else
						vehicle.fuel = Lerp(config.fuelLerpRate, vehicle.fuel, 0)
					end

					vehicle:SetPoseParameter(config.poseParameters.fuel, vehicle.fuel)
				else
					if not vehicle.fuel then
						vehicle.fuel = self:GetFuel()
					end

					if vehicle:GetEngineState() > 0 then
						vehicle.fuel = Lerp(config.fuelLerpRate, vehicle.fuel, 1)
					else
						vehicle.fuel = Lerp(config.fuelLerpRate, vehicle.fuel, 0)
					end

					vehicle:SetPoseParameter(config.poseParameters.fuel, vehicle.fuel)
				end
			end
		end
	end

	hook.Add("InitPostEntity", "OverrideBlackterio", function()
		override()
	end)

	override()
--//

-- local seqOverride = {
-- 	["run_all_01"] = "jump_slam", ["run_all_02"] = "jump_slam", ["run_all_panicked_01"] = "jump_slam", ["run_all_panicked_02"] = "jump_slam", ["run_all_protected"] = "jump_slam", ["run_all_charging"] = "jump_slam",
-- 	["run_ar2"] = "jump_ar2", ["run_camera"] = "jump_camera", ["run_crossbow"] = "jump_crossbow", ["run_dual"] = "jump_dual", ["run_fist"] = "jump_fist", ["run_knife"] = "jump_knife",
-- 	["run_magic"] = "jump_magic", ["run_melee2"] = "jump_melee2", ["run_passive"] = "jump_passive", ["run_physgun"] = "jump_physgun", ["run_revolver"] = "jump_revolver", ["run_rpg"] = "jump_rpg",
-- 	["run_shotgun"] = "jump_shotgun", ["run_smg1"] = "jump_smg1", ["run_grenade"] = "jump_grenade", ["run_melee"] = "jump_melee", ["run_pistol"] = "jump_pistol", ["run_slam"] = "jump_slam",

-- 	["cwalk_ar2"] = "jump_ar2", ["cwalk_camera"] = "jump_camera", ["cwalk_crossbow"] = "jump_crossbow", ["cwalk_dual"] = "jump_dual", ["cwalk_fist"] = "jump_fist", ["cwalk_knife"] = "jump_knife",
-- 	["cwalk_magic"] = "jump_magic", ["cwalk_melee2"] = "jump_melee2", ["cwalk_passive"] = "jump_passive", ["cwalk_pistol"] = "jump_pistol", ["cwalk_physgun"] = "jump_physgun", ["cwalk_revolver"] = "jump_revolver",
-- 	["cwalk_rpg"] = "jump_rpg", ["cwalk_shotgun"] = "jump_shotgun", ["cwalk_smg1"] = "jump_smg1", ["cwalk_grenade"] = "jump_grenade", ["cwalk_melee"] = "jump_melee", ["cwalk_slam"] = "jump_slam",
-- 	["cwalk_all"] = "jump_slam",

-- 	["walk_ar2"] = "jump_ar2", ["walk_camera"] = "jump_camera", ["walk_crossbow"] = "jump_crossbow", ["walk_dual"] = "jump_dual", ["walk_fist"] = "jump_fist", ["walk_knife"] = "jump_knife",
-- 	["walk_magic"] = "jump_magic", ["walk_melee2"] = "jump_melee2", ["walk_passive"] = "jump_passive", ["walk_physgun"] = "jump_physgun", ["walk_revolver"] = "jump_revolver", ["walk_rpg"] = "jump_rpg",
-- 	["walk_shotgun"] = "jump_shotgun", ["walk_smg1"] = "jump_smg1", ["walk_grenade"] = "jump_grenade", ["walk_melee"] = "jump_melee", ["walk_pistol"] = "jump_pistol", ["walk_slam"] = "jump_slam",
-- 	["walk_all"] = "jump_slam"
-- }

-- hook.Add("UpdateAnimation", "AirAnimFix", function(ply, vel, maxSeqGroundSpeed)
-- 	if not IsValid(ply) or ply:IsOnGround() or not ply:Alive() then return end

-- 	local targetSeq = seqOverride[ply:GetSequenceName(ply:GetSequence())]
-- 	if targetSeq then
-- 		ply:SetAnimTime( CurTime() )
--     end
-- end)

--\\ Give our guns to NPCs
	hook.Add("PopulateMenuBar", "PopulateNPCweps", function(menubar)
		local bar = menubar:AddOrGetMenu("Z-City Weapon Override")
		local weaponlist = weapons.GetList()

		bar:AddCVar("None", "gmod_npcweapon", "none")
		bar:AddSpacer()

		local buttons = {}
		table.SortByMember(weaponlist, "PrintName", true)

		local based = weapons.IsBasedOn -- RESPECT
		for _, wep in ipairs(weaponlist) do
			local classname = wep.ClassName
			if (based(classname, "homigrad_base") or based(classname, "weapon_melee") or classname == "weapon_melee" or based(classname, "weapon_medkit_sh") or classname == "weapon_medkit_sh") and wep.Spawnable then
				local category = wep.Category or "ZCity Other"
				if !buttons[category] then
					buttons[category] = bar:AddSubMenu(category)
				end

				buttons[category]:SetDeleteSelf(false)

				buttons[category]:AddCVar(wep.PrintName, "gmod_npcweapon", classname)

				list.Add("NPCUsableWeapons", { 
					class = classname,
					title = wep.PrintName,
					category = wep.Category or "ZCity Other"
				})
			end
		end
	end)
--//

--\\ Spawnmenu category icons
	local categories = {
		["Weapons - Assault Rifles"] = "pwb/sprites/akm", -- vgui/inventory/weapon_nam_akm
		["Weapons - Carbines"] = "vgui/wep_jack_hmcd_assaultrifle",
		["Weapons - Explosive"] = "pluv/toosilly.png",
		["Weapons - Grenade Launchers"] = "vgui/inventory/weapon_rpg7",
		["Weapons - Machine-Pistols"] = "vgui/hud/tfa_ins2_mp7", -- vgui/inventory/weapon_uzi
		["Weapons - Machineguns"] = "vgui/hud/tfa_kopter_pkm",
		["Weapons - Melee"] = "vgui/wep_jack_hmcd_hammer",
		["Weapons - Other"] = "vgui/wep_jack_hmcd_crossbow",
		["Weapons - Pistols"] = "entities/arc9_eft_m1911.png",
		["Weapons - Shotguns"] = "pwb/sprites/m590a1",
		["Weapons - Sniper Rifles"] = "vgui/hud/tfa_ins2_sr25_eft",
		["ZCity Medicine"] = "vgui/wep_jack_hmcd_medkit",
		["ZCity Other"] = "pluv/pluv.png",

		["ZCity Ammo"] = "vgui/hud/hmcd_round_4630",
		["ZCity Armor"] = "vgui/icons/armor01",
		["ZCity Attachments Grips"] = "entities/eft_attachments/foregrips/ash12.png",
		["ZCity Attachments Magwells"] = "entities/eft_ak_attachments/mag/545drum.png",
		["ZCity Attachments Muzzles"] = "vgui/icons/silencer_assaultrifle",
		["ZCity Attachments Sights"] = "vgui/icons/sights_aimpoint",
		["ZCity Attachments Underbarrel"] = "vgui/icons/laser_long",
	}

	for cat, icon in pairs(categories) do
		list.Set("ContentCategoryIcons", cat, icon)
	end
--//