SWEP.Base = "homigrad_base"
SWEP.Spawnable = true
SWEP.AdminOnly = false
SWEP.PrintName = "M249"
SWEP.Author = "FN Herstal"
SWEP.Instructions = "Machine gun chambered in 5.56x45 mm\n\nRate of fire 775 rounds per minute"
SWEP.Category = "Weapons - Machineguns"
SWEP.Primary.ClipSize = 150
SWEP.Primary.DefaultClip = 150
SWEP.Primary.Automatic = true
SWEP.Primary.Ammo = "5.56x45 mm"
SWEP.Primary.Cone = 0
SWEP.Primary.Damage = 44
SWEP.Primary.Spread = 0
SWEP.Primary.Force = 44
SWEP.Primary.Sound = {"weapons/zwei/m249/fire/m249_outdoor_close1.wav", 75, 90, 100}
SWEP.SupressedSound = {"weapons/zwei/m249/fire/m249_outdoor_suppressed_close4.wav", 75, 90, 100}
SWEP.Primary.SoundEmpty = {"zcitysnd/sound/weapons/fnfal/handling/fnfal_empty.wav", 75, 100, 105, CHAN_WEAPON, 2}
SWEP.Primary.Wait = 0.06
SWEP.ReloadTime = 7.5

function SWEP:PostFireBullet(bullet)
	if CLIENT then
		self:PlayAnim("base_fire_3", 1.5, nil, false)
	end
	local owner = self:GetOwner()
	if (SERVER or self:IsLocal2()) and owner:OnGround() then
		if IsValid(owner) and owner:IsPlayer() then
			owner:SetVelocity(owner:GetVelocity() - owner:GetVelocity() / 0.45)
		end
	end
end

SWEP.CanSuicide = false

SWEP.PPSMuzzleEffect = "muzzleflash_m14"

SWEP.DeploySnd = {"homigrad/weapons/draw_hmg.mp3", 55, 100, 110}
SWEP.HolsterSnd = {"homigrad/weapons/hmg_holster.mp3", 55, 100, 110}
SWEP.Slot = 2
SWEP.SlotPos = 10
SWEP.ViewModel = ""
SWEP.WorldModel = "models/weapons/w_mach_m249para.mdl"
SWEP.WorldModelFake = "models/weapons/arc9/zwei/c_m249.mdl"
SWEP.FakeAttachment = "1"
SWEP.FakeScale = 1
SWEP.FakePos = Vector(-15, 3.53, 9.45)
SWEP.FakeAng = Angle(0.19, 0.04, 0)
SWEP.AttachmentPos = Vector(0, 0.7, 0.2)
SWEP.AttachmentAng = Angle(0, 0, 0)

SWEP.FakeEjectBrassATT = "2"

SWEP.FakeVPShouldUseHand = true
SWEP.AnimList = {
	["idle"] = "idle",
	["reload"] = "reload",
	["reload_empty"] = "reload_empty",
	["inspect"] = "inspect",
}

SWEP.AnimsEvents = {
	["inspect"] = {
		[0.01] = function(self) self:EmitSound("weapons/darsu_eft/pkm/pk_gun_flip_3.ogg") end,
		[0.4] = function(self) self:EmitSound("weapons/darsu_eft/pkm/pk_gun_flip_5.ogg") end,
	},
	["reload"] = {
		[0.01] = function(self) self:EmitSound("weapons/zwei/m249/m249_dust_open.ogg") end,
		[0.1] = function(self) self:EmitSound("weapons/zwei/m249/m249_belt_out.ogg") end,
		[0.17] = function(self) self:EmitSound("weapons/m249/m249_magout.wav") end,
		[0.37] = function(self) self:EmitSound("weapons/m249/m249_magin.wav") end,
		[0.45] = function(self) self:EmitSound("weapons/zwei/m249/m249_belt_roll.ogg") end,
		[0.6] = function(self) self:EmitSound("weapons/zwei/m249/m249_dust_close1.ogg") end,

	},
	["reload_empty"] = {
		[0.01] = function(self) self:EmitSound("weapons/zwei/m249/m249_dust_open.ogg") end,
		[0.15] = function(self) self:EmitSound("weapons/m249/m249_magout.wav") end,
		[0.35] = function(self) self:EmitSound("weapons/m249/m249_magin.wav") end,
		[0.39] = function(self) self:EmitSound("weapons/zwei/m249/m249_belt_roll.ogg") end,
		[0.5] = function(self) self:EmitSound("weapons/zwei/m249/m249_dust_close1.ogg") end,
		[0.75] = function(self) self:EmitSound("weapons/zwei/m249/m249_charge_out.ogg") end,
		[0.8] = function(self) self:EmitSound("weapons/zwei/m249/m249_charge_in.ogg") end,
	},
}

function SWEP:AllowedInspect()
	if not self:CanUse() then return end
	if self.isReloading then return end
	if self:Clip1() < self.Primary.ClipSize then return end
	if self.drawBullet == false then return end
	return true
end

SWEP.GunCamPos = Vector(6, -17, -4)
SWEP.GunCamAng = Angle(190, 0, -90)
SWEP.FakeBodyGroups = "11252111"
SWEP.FakeViewBobBone = "ValveBiped.Bip01_R_Hand"
SWEP.FakeViewBobBaseBone = "ValveBiped.Bip01_R_UpperArm"
SWEP.ViewPunchDiv = 65

SWEP.NoIdleLoop = true
SWEP.GetDebug = false

SWEP.FakeReloadEvents = {
	[0.73] = function(self)
		if CLIENT then
			self:GetWM():SetBodygroup(1, 1)
		end
	end,
}

SWEP.RestPosition = Vector(10, -1, 4)

SWEP.ScrappersSlot = "Primary"
SWEP.weight = 5

SWEP.ShockMultiplier = 3

SWEP.CustomShell = "556x45"
SWEP.CustomSecShell = "m249len"

SWEP.WepSelectIcon2 = Material("entities/arc9_eft_m249.png")
SWEP.IconOverride = "entities/arc9_eft_m249.png"

SWEP.weaponInvCategory = 1
SWEP.HoldType = "rpg"
SWEP.ZoomPos = Vector(0, -1.9747, 7.3286)
SWEP.RHandPos = Vector(-5, -2, 0)
SWEP.LHandPos = Vector(7, -2, -2)
SWEP.ShellEject = "EjectBrass_762Nato"
SWEP.Spray = {}
for i = 1, 150 do
	SWEP.Spray[i] = Angle(-0.03 - math.cos(i) * 0.02, math.cos(i * i) * 0.04, 0) * 2
end

SWEP.LocalMuzzlePos = Vector(23.632, -2.3, 5.860)
SWEP.LocalMuzzleAng = Angle(0.3, 0.02, 0)
SWEP.WeaponEyeAngles = Angle(0, 0, 0)

SWEP.Ergonomics = 0.75
SWEP.OpenBolt = true
SWEP.Penetration = 15
SWEP.WorldPos = Vector(4, -0.5, 1)
SWEP.WorldAng = Angle(0, 0, 0)
SWEP.UseCustomWorldModel = true
SWEP.attPos = Vector(0, -1, 0)
SWEP.attAng = Angle(0, -0.2, 0)
SWEP.AimHands = Vector(0, 1.65, -3.65)
SWEP.lengthSub = 15
SWEP.DistSound = "m249/m249_dist.wav"

SWEP.availableAttachments = {
	barrel = {
		[1] = {"supressor2", Vector(0, 0, 0), {}},
		["mount"] = Vector(-3, 0.8, 0.15),
	},
	sight = {
		["mount"] = Vector(-15.5, 0.28, 1.4),
		["mountType"] = "picatinny",
		["mountAngle"] = Angle(0, -0.75, 90),
	},
	underbarrel = {
		["mount"] = Vector(1.5, -1.1, -2.3),
		["mountAngle"] = Angle(0, -0.75, 90),
		["mountType"] = "picatinny_small"
	},
}

SWEP.punchmul = 15
SWEP.punchspeed = 0.11
SWEP.podkid = 0.05

SWEP.RecoilMul = 0.1

SWEP.bipodAvailable = true
SWEP.bipodsub = 15

--local to head
SWEP.RHPos = Vector(7, -7, 5)
SWEP.RHAng = Angle(0, 0, 90)
--local to rh
SWEP.LHPos = Vector(8.5, -2, -6)
SWEP.LHAng = Angle(-20, 0, -90)

local ang1 = Angle(20, -20, 0)
local ang2 = Angle(0, 60, 0)

function SWEP:AnimHoldPost()
end
