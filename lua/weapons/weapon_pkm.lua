SWEP.Base = "homigrad_base"
SWEP.Spawnable = true
SWEP.AdminOnly = false
SWEP.PrintName = "PKM"
SWEP.Author = "Degtyarev plant"
SWEP.Instructions = "Machine gun chambered in 7.62x54 mm\n\nRate of fire 650 rounds per minute"
SWEP.Category = "Weapons - Machineguns"
SWEP.Primary.ClipSize = 100
SWEP.Primary.DefaultClip = 100
SWEP.Primary.Automatic = true
SWEP.Primary.Ammo = "7.62x54 mm"
SWEP.Primary.Cone = 0
SWEP.Primary.Damage = 70
SWEP.Primary.Spread = 0
SWEP.Primary.Force = 70
SWEP.Primary.Sound = {"weapons/darsu_eft/pkm/fire/pkm_indoor_distant_loop1.wav", 75, 100, 110}
SWEP.SupressedSound = {"weapons/darsu_eft/pkm/fire/pkm_indoor_silenced_distant_loop1.wav", 75, 100, 110}
SWEP.Primary.SoundEmpty = {"zcitysnd/sound/weapons/ak47/handling/ak47_empty.wav", 75, 100, 105, CHAN_WEAPON, 2}
SWEP.Primary.Wait = 0.09
SWEP.ReloadTime = 7.5

function SWEP:PostFireBullet(bullet)
	local owner = self:GetOwner()
	if (SERVER or self:IsLocal2()) and owner:OnGround() then
		if IsValid(owner) and owner:IsPlayer() then
			owner:SetVelocity(owner:GetVelocity() - owner:GetVelocity() / 0.45)
		end
	end
end

SWEP.CanSuicide = false

SWEP.PPSMuzzleEffect = "muzzleflash_MINIMI"

SWEP.DeploySnd = {"homigrad/weapons/draw_hmg.mp3", 55, 100, 110}
SWEP.HolsterSnd = {"homigrad/weapons/hmg_holster.mp3", 55, 100, 110}
SWEP.Slot = 2
SWEP.SlotPos = 10
SWEP.ViewModel = ""
SWEP.WorldModel = "models/weapons/w_irifle.mdl"
SWEP.WorldModelFake = "models/weapons/c_pk.mdl"
SWEP.FakeAttachment = "1"
SWEP.FakePos = Vector(-8, 2.85, 6.7)
SWEP.FakeAng = Angle(0, 0, 0)
SWEP.AttachmentPos = Vector(1, 0, 0)
SWEP.AttachmentAng = Angle(0, 0, 90)

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
        [0.10] = function(self) self:EmitSound("weapons/darsu_eft/pkm/pk_cover_open.ogg") end,
        [0.20] = function(self) self:EmitSound("weapons/darsu_eft/pkm/pk_belt_out.wav") end,
		[0.30] = function(self) self:EmitSound("weapons/darsu_eft/pkm/pk_mag_out.ogg") end,
		[0.55] = function(self) self:EmitSound("weapons/darsu_eft/pkm/pk_mag_in.ogg") end,
		[0.65] = function(self) self:EmitSound("weapons/darsu_eft/pkm/pk_belt_in.wav") end,
		[0.75] = function(self) self:EmitSound("weapons/darsu_eft/pkm/pk_cover_close.ogg") end,
    },
    ["reload_empty"] = {
        [0.10] = function(self) self:EmitSound("weapons/darsu_eft/pkm/pk_cover_open.ogg") end,
        [0.20] = function(self) self:EmitSound("weapons/darsu_eft/pkm/pk_belt_out.wav") end,
		[0.30] = function(self) self:EmitSound("weapons/darsu_eft/pkm/pk_mag_out.ogg") end,
		[0.48] = function(self) self:EmitSound("weapons/darsu_eft/pkm/pk_mag_in.ogg") end,
		[0.65] = function(self) self:EmitSound("weapons/darsu_eft/pkm/pk_belt_in.wav") end,
		[0.75] = function(self) self:EmitSound("weapons/darsu_eft/pkm/pk_cover_close.ogg") end,
		[0.82] = function(self) self:EmitSound("weapons/darsu_eft/pkm/pk_charge_full.ogg") end,
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
SWEP.FakeBodyGroups = "0111110131111"
SWEP.FakeViewBobBone = "ValveBiped.Bip01_R_Hand"
SWEP.FakeViewBobBaseBone = "ValveBiped.Bip01_R_UpperArm"
SWEP.ViewPunchDiv = 40
SWEP.NoIdleLoop = true
SWEP.GetDebug = false


SWEP.FakeReloadEvents = {}

SWEP.ScrappersSlot = "Primary"
SWEP.weight = 4.5

SWEP.ShockMultiplier = 2

SWEP.CustomShell = "762x54"
SWEP.CustomSecShell = "m60len"
SWEP.EjectPos = Vector(2, 13, -3)
SWEP.EjectAng = Angle(0, 90, 0)

SWEP.WepSelectIcon2 = Material("entities/arc9_eft_pkm.png")
SWEP.IconOverride = "entities/arc9_eft_pkm.png"

SWEP.weaponInvCategory = 1
SWEP.HoldType = "rpg"
SWEP.ZoomPos = Vector(0, -1.3968, 4.919)
SWEP.RHandPos = Vector(4, -2, 0)
SWEP.LHandPos = Vector(7, -2, -2)
SWEP.ShellEject = "EjectBrass_762Nato"
SWEP.Spray = {}
for i = 1, 100 do
	SWEP.Spray[i] = Angle(-0.05 - math.cos(i) * 0.04, math.cos(i * i) * 0.05, 0) * 2
end

SWEP.LocalMuzzlePos = Vector(0, -1.6, 2)
SWEP.LocalMuzzleAng = Angle(-0.2, -0.05, 0)
SWEP.WeaponEyeAngles = Angle(0, 0, 0)

SWEP.Ergonomics = 0.6
SWEP.OpenBolt = true
SWEP.Penetration = 20
SWEP.WorldPos = Vector(-1, -0.5, 0)
SWEP.WorldAng = Angle(0, 0, 0)
SWEP.UseCustomWorldModel = true
SWEP.attPos = Vector(0, 0, 0)
SWEP.attAng = Angle(-0.05, -0.2, 0)
SWEP.AimHands = Vector(0, 1, -3.5)
SWEP.lengthSub = 15
SWEP.DistSound = "weapons/darsu_eft/pkm/fire/pkm_indoor_distant_loop1.wav"
SWEP.bipodAvailable = true
SWEP.bipodsub = 15

SWEP.availableAttachments = {
	underbarrel = {
		["mount"] = Vector(-4.5, 0.7, -1),
		["mountAngle"] = Angle(0, -0.75, -90),
		["mountType"] = "picatinny_small"
	},
}

SWEP.RecoilMul = 0.3

SWEP.RHPos = Vector(4, -7, 4)
SWEP.RHAng = Angle(0, -12, 90)
SWEP.LHPos = Vector(9, -4, -5)
SWEP.LHAng = Angle(-10, 10, -120)

local ang1 = Angle(30, -15, 0)
local ang2 = Angle(0, 10, 0)

function SWEP:AnimHoldPost()
end
