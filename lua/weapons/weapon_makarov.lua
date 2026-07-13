SWEP.Base = "homigrad_base"
SWEP.Spawnable = true
SWEP.AdminOnly = false
SWEP.PrintName = "PM"
SWEP.Author = "TsNIITochMash"
SWEP.Instructions = "A Soviet combat pistol chambered in 9x18mm Parabellum"
SWEP.Category = "Weapons - Pistols"
SWEP.Slot = 2
SWEP.SlotPos = 10
SWEP.ViewModel = ""
SWEP.WorldModel = "models/weapons/w_pist_p228.mdl"
SWEP.WorldModelFake = "models/weapons/c_pm.mdl"

SWEP.FakePos = Vector(-24, 2.5, 5)
SWEP.FakeAng = Angle(0, 0, 0)
SWEP.AttachmentPos = Vector(0, 0, -0.2)
SWEP.AttachmentAng = Angle(0, 0, 90)
SWEP.FakeAttachment = "1"
SWEP.FakeEjectBrassATT = "2"
SWEP.MagIndex = nil
SWEP.FakeBodyGroups = "1111141"
SWEP.FakeBodyGroupsPresets = {
	"1111141",
}


SWEP.FakeVPShouldUseHand = false
SWEP.FakeViewBobBone = "ValveBiped.Bip01_R_Hand"
SWEP.FakeViewBobBaseBone = "ValveBiped.Bip01_R_Forearm"
SWEP.ViewPunchDiv = 50

SWEP.AnimList = {
	["idle"] = "idle",
	["reload"] = "reload0",
	["reload_empty"] = "reload_empty0",
	["inspect"] = "look",
}

SWEP.AnimsEvents = {
	["inspect"] = {
		[0.01] = function(self) self:EmitSound("weapons/universal/uni_crawl_l_03.wav") end,
	},
    ["reload"] = {
        [0.2] = function(self) self:EmitSound("weapons/darsu_eft/pm/pm_mag_out.ogg") end,
        [0.6] = function(self) self:EmitSound("weapons/darsu_eft/pm/pm_mag_in.ogg") end,
    },
    ["reload_empty"] = {
        [0.005] = function(self) self:EmitSound("weapons/darsu_eft/pm/pm_slider_out.ogg") end,
		[0.15] = function(self) self:EmitSound("weapons/darsu_eft/pm/pm_mag_out.ogg") end,
		[0.48] = function(self) self:EmitSound("weapons/darsu_eft/pm/pm_mag_in.ogg") end,
		[0.68] = function(self) self:EmitSound("weapons/darsu_eft/pm/pm_slider_in.ogg") end,
    },
}

function SWEP:AllowedInspect()
	if not self:CanUse() then return end
	if self.isReloading then return end
	if self:Clip1() < self.Primary.ClipSize then return end
	if self.drawBullet == false then return end
	return true
end

SWEP.availableAttachments = {
	barrel = {
		[1] = {"supressor4", Vector(0, 0, 0), {}},
		["mount"] = Vector(-0.2, 0.8, 0.03),
	},
	underbarrel = {
		["mount"] = Vector(13.5, 1.2, -1),
		["mountAngle"] = Angle(0, -0.75, -90),
		["mountType"] = "picatinny_small"
	},
}

SWEP.FakeMagDropBone = "magazine"
SWEP.MagModel = "models/weapons/upgrades/w_magazine_m45_8.mdl"

SWEP.WepSelectIcon2 = Material("entities/arc9_eft_pm.png")
SWEP.IconOverride = "entities/arc9_eft_pm.png"
SWEP.WepSelectIcon2box = true

SWEP.CustomShell = "9x39"

SWEP.weight = 1
SWEP.ScrappersSlot = "Secondary"
SWEP.weaponInvCategory = 2
SWEP.ShellEject = "EjectBrass_9mm"
SWEP.Primary.ClipSize = 8
SWEP.Primary.DefaultClip = 8
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = "9x18 mm"
SWEP.Primary.Cone = 0
SWEP.Primary.Damage = 26
SWEP.Primary.Sound = {"weapons/darsu_eft/pm/pm_indoor_close1.wav", 75, 90, 100}
SWEP.Primary.SoundEmpty = {"zcitysnd/sound/weapons/m1911/handling/m1911_empty.wav", 75, 100, 105, CHAN_WEAPON, 2}
SWEP.Primary.Force = 26
SWEP.Primary.Wait = PISTOLS_WAIT
SWEP.ReloadTime = 6.5

SWEP.DeploySnd = {"homigrad/weapons/draw_pistol.mp3", 55, 100, 110}
SWEP.HolsterSnd = {"homigrad/weapons/holster_pistol.mp3", 55, 100, 110}
SWEP.HoldType = "revolver"
SWEP.ZoomPos = Vector(-3, -1.8, 2.6)
SWEP.RHandPos = Vector(-5, -1.5, 2)
SWEP.LHandPos = false
SWEP.SprayRand = {Angle(-0.02, -0.02, 0), Angle(-0.03, 0.02, 0)}
SWEP.Ergonomics = 1.2
SWEP.Penetration = 7
SWEP.ShockMultiplier = 1
SWEP.punchmul = 1.5
SWEP.punchspeed = 3

SWEP.LocalMuzzlePos = Vector(0, -1.4, 4)
SWEP.LocalMuzzleAng = Angle(0.398, 0, 0)
SWEP.WeaponEyeAngles = Angle(0, 0, 0)

SWEP.WorldPos = Vector(5.5, -2, -1.5)
SWEP.WorldAng = Angle(0, 0, 0)
SWEP.UseCustomWorldModel = true
SWEP.attPos = Vector(0, 0, 0)
SWEP.attAng = Angle(0.4, 0, 90)
SWEP.lengthSub = 25
SWEP.holsteredBone = "ValveBiped.Bip01_R_Thigh"
SWEP.holsteredPos = Vector(0, -3, 2)
SWEP.holsteredAng = Angle(0, 20, 30)
SWEP.shouldntDrawHolstered = true
SWEP.ImmobilizationMul = 1

--local to head
SWEP.RHPos = Vector(12, -4.5, 3.5)
SWEP.RHAng = Angle(5, -5, 90)
--local to rh
SWEP.LHPos = Vector(-1.2, -1.4, -2.8)
SWEP.LHAng = Angle(5, 9, -100)
SWEP.ShootAnimMul = 3
SWEP.SightSlideOffset = 1.2

SWEP.podkid = 1


function SWEP:DrawPost()
	local wep = self:GetWM()
	if CLIENT and IsValid(wep) then
		self.shooanim = LerpFT(0.4, self.shooanim or 0, (self:Clip1() > 0 or self.reload) and 0 or 1)
		wep:ManipulateBonePosition(54, Vector(0, 1.5 * self.shooanim, 0), false)
	end
end


