SWEP.Base = "homigrad_base"
SWEP.Spawnable = true
SWEP.AdminOnly = false
SWEP.PrintName = "M60"
SWEP.Author = "Saco Defense"
SWEP.Instructions = "Machine gun chambered in 7.62x51 mm\n\nRate of fire 550 rounds per minute"
SWEP.Category = "Weapons - Machineguns"
SWEP.Primary.ClipSize = 200
SWEP.Primary.DefaultClip = 200
SWEP.Primary.Automatic = true
SWEP.Primary.Ammo = "7.62x51 mm"
SWEP.Primary.Cone = 0
SWEP.Primary.Damage = 65
SWEP.Primary.Spread = 0
SWEP.Primary.Force = 65
SWEP.Primary.Sound = {"homigrad/weapons/rifle/hmg2.wav", 75, 100, 110}
SWEP.SupressedSound = {"homigrad/weapons/rifle/hmg2.wav", 75, 100, 110}
SWEP.Primary.SoundEmpty = {"zcitysnd/sound/weapons/fnfal/handling/fnfal_empty.wav", 75, 100, 105, CHAN_WEAPON, 2}
SWEP.Primary.Wait = 0.11
SWEP.ReloadTime = 7.9

function SWEP:PostFireBullet(bullet)
	local owner = self:GetOwner()
	if (SERVER or self:IsLocal2()) and owner:OnGround() then
		if IsValid(owner) and owner:IsPlayer() then
			owner:SetVelocity(owner:GetVelocity() - owner:GetVelocity() / 0.45)
		end
	end
end

SWEP.CanSuicide = false
SWEP.PPSMuzzleEffect = "muzzleflash_m24"

SWEP.DeploySnd = {"homigrad/weapons/draw_hmg.mp3", 55, 100, 110}
SWEP.HolsterSnd = {"homigrad/weapons/hmg_holster.mp3", 55, 100, 110}
SWEP.Slot = 2
SWEP.SlotPos = 10
SWEP.ViewModel = ""
SWEP.WorldModel = "models/weapons/w_mach_m249para.mdl"
SWEP.WorldModelFake = "models/weapons/c_m60.mdl"
SWEP.FakeAttachment = "1"
SWEP.FakePos = Vector(-15, 2.32, 7.3)
SWEP.FakeAng = Angle(0, 0, 0)
SWEP.AttachmentPos = Vector(0, -1, -6.5)
SWEP.AttachmentAng = Angle(0, 0, 0)

SWEP.FakeVPShouldUseHand = true
SWEP.AnimList = {
	["idle"] = "idle",
	["reload"] = "reload",
	["reload_empty"] = "reload_empty",
	["inspect"] = "look",
}

SWEP.AnimsEvents = {
	["inspect"] = {
		[0.01] = function(self) self:EmitSound("weapons/darsu_eft/pkm/pk_gun_flip_3.ogg") end,
		[0.4] = function(self) self:EmitSound("weapons/darsu_eft/pkm/pk_gun_flip_5.ogg") end,
	},
    ["reload"] = {
        [0.05] = function(self) self:EmitSound("weapons/darsu_eft/m60/m60_dust_open.ogg") end,
		[0.15] = function(self) self:EmitSound("weapons/darsu_eft/pkm/pk_belt_out.wav") end,
		[0.25] = function(self) self:EmitSound("weapons/darsu_eft/m60/m60_mag_out.ogg") end,
		[0.4] = function(self) self:EmitSound("weapons/darsu_eft/m60/m60_mag_in.ogg") end,
		[0.45] = function(self) self:EmitSound("weapons/darsu_eft/pkm/pk_belt_in.wav") end,
		[0.68] = function(self) self:EmitSound("weapons/darsu_eft/m60/m60_close_cover.ogg") end,
    },
    ["reload_empty"] = {
		[0.05] = function(self) self:EmitSound("weapons/darsu_eft/m60/m60_dust_open.ogg") end,
		[0.15] = function(self) self:EmitSound("weapons/darsu_eft/m60/m60_mag_out_fast.ogg") end,
		[0.3] = function(self) self:EmitSound("weapons/darsu_eft/m60/m60_mag_in.ogg") end,
		[0.4] = function(self) self:EmitSound("weapons/darsu_eft/pkm/pk_belt_in.wav") end,
		[0.6] = function(self) self:EmitSound("weapons/darsu_eft/m60/m60_close_cover.ogg") end,
		[0.75] = function(self) self:EmitSound("weapons/darsu_eft/m60/rpd_charge_full.ogg") end,
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
SWEP.FakeBodyGroups = "111141322121"
SWEP.FakeViewBobBone = "ValveBiped.Bip01_R_Hand"
SWEP.FakeViewBobBaseBone = "ValveBiped.Bip01_R_UpperArm"
SWEP.ViewPunchDiv = 40
SWEP.NoIdleLoop = true
SWEP.GetDebug = false

SWEP.FakeReloadEvents = {
	[0.73] = function(self)
		if CLIENT and self:Clip1() < 1 then
			self:GetWM():SetBodygroup(1, 1)
		end
	end,
}

SWEP.RestPosition = Vector(25, -1, 4)

SWEP.ScrappersSlot = "Primary"
SWEP.weight = 5

SWEP.ShockMultiplier = 2

SWEP.CustomShell = "762x51"
SWEP.CustomSecShell = "m60len"

SWEP.WepSelectIcon2 = Material("entities/arc9_eft_m60e4.png")
SWEP.IconOverride = "entities/arc9_eft_m60e4.png"

SWEP.weaponInvCategory = 1
SWEP.HoldType = "rpg"
SWEP.ZoomPos = Vector(0, -1.9718, 7.1107)
SWEP.RHandPos = Vector(-4, -2, 0)
SWEP.LHandPos = Vector(7, -2, -2)
SWEP.ShellEject = "EjectBrass_762Nato"
SWEP.Spray = {}
for i = 1, 200 do
	SWEP.Spray[i] = Angle(-0.05 - math.cos(i) * 0.04, math.cos(i * i) * 0.05, 0) * 2
end

SWEP.LocalMuzzlePos = Vector(30.382, -1.8, 6.1)
SWEP.LocalMuzzleAng = Angle(0.15, 0, 0)
SWEP.WeaponEyeAngles = Angle(0, 0, 0)

SWEP.Ergonomics = 0.6
SWEP.OpenBolt = true
SWEP.Penetration = 20
SWEP.WorldPos = Vector(4, 0, 0)
SWEP.WorldAng = Angle(0, 0, 0)
SWEP.UseCustomWorldModel = true
SWEP.attPos = Vector(0, 0, 0)
SWEP.attAng = Angle(0, -0.1, 0)
SWEP.AimHands = Vector(0, 1.75, -4.2)
SWEP.lengthSub = 15
SWEP.DistSound = "m249/m249_dist.wav"
SWEP.bipodAvailable = true
SWEP.bipodsub = 15
SWEP.RecoilMul = 0.3

SWEP.availableAttachments = {
	barrel = {
		[1] = {"supressor8", Vector(0, 0, 0), {}},
		["mount"] = Vector(3, 0.9, 6.5),
	},
	underbarrel = {
		["mount"] = Vector(1.5, -0.5, 5.75),
		["mountAngle"] = Angle(0, -0.75, 90),
		["mountType"] = "picatinny_small"
	},
}

--local to head
SWEP.RHPos = Vector(7, -7, 5)
SWEP.RHAng = Angle(0, 0, 90)
--local to rh
SWEP.LHPos = Vector(4, 0, -9)
SWEP.LHAng = Angle(-20, 0, -90)

local ang1 = Angle(20, -20, 0)
local ang2 = Angle(0, 60, 0)

function SWEP:AnimHoldPost()
	self:BoneSet("l_finger0", vector_origin, ang1)
	self:BoneSet("l_finger02", vector_origin, ang2)
	if not self.reload then
		self:GetWM():SetBodygroup(1, math.min(self:Clip1() - 1, 1))
	end
end
