SWEP.Base = "homigrad_base"
SWEP.Spawnable = true
SWEP.AdminOnly = false
SWEP.PrintName = "SVD"
SWEP.Author = "Kalashnikov Concern"
SWEP.Instructions = "Semi-automatic Marksman rifle chambered in 7.62x54 mm"
SWEP.Category = "Weapons - Sniper Rifles"
SWEP.Slot = 2
SWEP.SlotPos = 10
SWEP.ViewModel = ""
SWEP.WorldModel = "models/weapons/w_snip_g3sg1.mdl"
SWEP.WorldModelFake = "models/weapons/c_svd.mdl"

SWEP.FakeAttachment = "1"
SWEP.FakeEjectBrassATT = "2"

SWEP.FakeBodyGroups = "11101001010111111"
SWEP.FakePos = Vector(-15, 2.02, 5.25)
SWEP.FakeAng = Angle(0, 0, 0)
SWEP.AttachmentPos = Vector(0.5, 0.1, 0.3)
SWEP.AttachmentAng = Angle(0, 0, 0)

SWEP.MagModel = "models/kali/weapons/10rd m14 magazine.mdl"
SWEP.FakeMagDropBone = "Magazine"
SWEP.lmagpos = Vector(0, 0, 0)
SWEP.lmagang = Angle(0, 0, 0)
SWEP.lmagpos2 = Vector(0, 0.3, 0)
SWEP.lmagang2 = Angle(0, 0, 0)
SWEP.ViewPunchDiv = 1000

local vector_full = Vector(1, 1, 1)
local vecPochtiZero = Vector(0.01, 0.01, 0.01)
if CLIENT then
	SWEP.FakeReloadEvents = {
		[0.35] = function(self, timeMul)
			if self:Clip1() < 1 then
				self:GetOwner():PullLHTowards("ValveBiped.Bip01_Spine2", 1.1 * timeMul)
			end
		end,
		[0.36] = function(self, timeMul)
			if self:Clip1() < 1 then
				hg.CreateMag(self, Vector(0, 0, -50), "111111")
				self:GetWM():ManipulateBoneScale(67, vecPochtiZero)
			end
		end,
		[0.6] = function(self, timeMul)
			if self:Clip1() < 1 then
				self:GetWM():ManipulateBoneScale(67, vector_full)
			end
		end,
	}
end

SWEP.AnimList = {
	["idle"] = "base_idle",
	["reload"] = "reload0",
	["reload_empty"] = "reload_empty0_0",
	["inspect"] = "look",
}

local path = "weapons/darsu_eft/svds/"

SWEP.AnimsEvents = {
	["reload"] = {
		[0.10] = function(self) self:EmitSound(path .. "svd_mag_button.ogg") end,
		[0.2] = function(self) self:EmitSound(path .. "svd_mag_out.ogg") end,
		[0.53] = function(self) self:EmitSound(path .. "svd_mag_in.ogg") end,
	},
	["reload_empty"] = {
		[0.10] = function(self) self:EmitSound(path .. "svd_mag_button.ogg") end,
		[0.2] = function(self) self:EmitSound(path .. "svd_mag_out_quick.ogg") end,
		[0.4] = function(self) self:EmitSound(path .. "svd_mag_in.ogg") end,
		[0.6] = function(self) self:EmitSound(path .. "svd_slider_out.ogg") end,
	},
	["inspect"] = {
		[0.01] = function(self) self:EmitSound("weapons/universal/uni_crawl_l_03.wav") end,
	},
}


function SWEP:AllowedInspect()
	if not self:CanUse() then return end
	if self.isReloading then return end
	if self:Clip1() < self.Primary.ClipSize then return end
	if self.drawBullet == false then return end
	return true
end

SWEP.ScrappersSlot = "Primary"
SWEP.WepSelectIcon2 = Material("entities/arc9_eft_svd.png")
SWEP.WepSelectIcon2box = true
SWEP.IconOverride = "entities/arc9_eft_svd.png"
SWEP.weight = 4
SWEP.weaponInvCategory = 1
SWEP.CustomShell = "762x54"

SWEP.AutomaticDraw = true
SWEP.UseCustomWorldModel = false
SWEP.Primary.ClipSize = 10
SWEP.Primary.DefaultClip = 10
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = "7.62x54 mm"
SWEP.Primary.Cone = 0
SWEP.Primary.Spread = 0
SWEP.Primary.Damage = 65
SWEP.Primary.Force = 65
SWEP.Primary.Sound = {"weapons/darsu_eft/svds/svd_fire_close.ogg", 85, 100, 100}
SWEP.SupressedSound = {"weapons/darsu_eft/svds/svd_fire_close_silenced.ogg", 65, 100, 100}
SWEP.availableAttachments = {
	barrel = {
		[1] = {"supressor1", Vector(0, 0, 0), {}},
		[2] = {"supressor6", Vector(3, 0, 0), {}},
		["mount"] = Vector(-0.5, 0.6, 0),
	},
	sight = {
		["mountType"] = {"picatinny", "dovetail"},
		["mount"] = {["dovetail"] = Vector(-30.5, 2, -0.45), ["picatinny"] = Vector(-31, 2.35, -0.2)},
	},
	mount = {
		["picatinny"] = {
			"mount3",
			Vector(-28, -0.3, -1.3),
			{},
			["mountType"] = "picatinny",
		},
		["dovetail"] = {
			"empty",
			Vector(0, 0, 0),
			{},
			["mountType"] = "dovetail",
		},
	},
}

SWEP.addSprayMul = 1
SWEP.cameraShakeMul = 2
SWEP.RecoilMul = 0.2

SWEP.LocalMuzzlePos = Vector(39.837, -2.5, 3.758)
SWEP.LocalMuzzleAng = Angle(0, 0, 0)
SWEP.WeaponEyeAngles = Angle(0, 0, 0)

SWEP.PPSMuzzleEffect = "muzzleflash_svd"

SWEP.ShockMultiplier = 2

SWEP.handsAng = Angle(0, 0, 0)
SWEP.handsAng2 = Angle(-3, 1, 0)

SWEP.Primary.Wait = 0.15
SWEP.NumBullet = 1
SWEP.AnimShootMul = 1
SWEP.AnimShootHandMul = 1
SWEP.ReloadTime = 4.8
SWEP.DeploySnd = {"homigrad/weapons/draw_hmg.mp3", 55, 100, 110}
SWEP.HolsterSnd = {"homigrad/weapons/hmg_holster.mp3", 55, 100, 110}
SWEP.HoldType = "rpg"
SWEP.ZoomPos = Vector(0, -2.2656, 3.7901)
SWEP.RHandPos = Vector(-8, -2, 6)
SWEP.LHandPos = Vector(6, -3, 1)
SWEP.AimHands = Vector(-10, 1.8, -6.1)
SWEP.SprayRand = {Angle(0.05, -0.05, 0), Angle(-0.05, 0.05, 0)}
SWEP.Ergonomics = 0.75
SWEP.Penetration = 15
SWEP.ZoomFOV = 20
SWEP.WorldPos = Vector(5.5, -1, -1)
SWEP.WorldAng = Angle(0, 0, 0)
SWEP.UseCustomWorldModel = true
SWEP.handsAng = Angle(-2, -1, 0)
SWEP.scopemat = Material("decals/scope.png")
SWEP.perekrestie = Material("decals/perekrestie8.png", "smooth")
SWEP.localScopePos = Vector(-21, 3.95, -0.2)
SWEP.scope_blackout = 400
SWEP.maxzoom = 3.5
SWEP.rot = 37
SWEP.FOVMin = 3.5
SWEP.FOVMax = 10
SWEP.huyRotate = 25
SWEP.FOVScoped = 40

local vecZero = Vector(0, 0, 0)

SWEP.DistSound = "weapons/tfa_ins2/sks/sks_dist.wav"

SWEP.lengthSub = 15

SWEP.RHPos = Vector(3, -6.5, 4)
SWEP.RHAng = Angle(0, -12, 90)
SWEP.LHPos = Vector(17, 1.3, -3.4)
SWEP.LHAng = Angle(-110, -180, -5)

SWEP.ShootAnimMul = 5

local lfang2 = Angle(-2, -35, -1)
local lfang21 = Angle(0, 35, 20)
local lfang1 = Angle(5, -15, -20)
local lfang0 = Angle(-0, -5, 0)
local vec_zero = Vector(0, 0, 0)
local ang_zero = Angle(0, 0, 0)
function SWEP:AnimHoldPost()
end

function SWEP:DrawPost()
	local wep = self:GetWeaponEntity()
	if CLIENT and IsValid(wep) then
		self.shooanim = LerpFT(0.4, self.shooanim or 0, (self:Clip1() < 1 and not self.reload) and 2.3 or self.ReloadSlideOffset)
		wep:ManipulateBonePosition(70, Vector(-1.8 * self.shooanim, 0, 0), false)
	end
end
