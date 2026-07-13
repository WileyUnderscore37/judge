SWEP.Base = "homigrad_base"
SWEP.Spawnable = true
SWEP.AdminOnly = true
SWEP.PrintName = "RSHG2"
SWEP.Author = ""
SWEP.Instructions = ""
SWEP.Category = "Weapons - Grenade Launchers"
SWEP.Slot = 2
SWEP.SlotPos = 10
SWEP.ViewModel = ""
SWEP.WorldModel = "models/weapons/w_rshg2_dropped.mdl"
SWEP.WorldModelFake = "models/weapons/c_rshg.mdl"

SWEP.FakePos = Vector(-18, 3.5, 2.5)
SWEP.FakeAng = Angle(-21.2, 2.2, -11)
SWEP.AttachmentPos = Vector(0,0,0)
SWEP.AttachmentAng = Angle(0,0,0)
SWEP.FakeAttachment = "1"

SWEP.ScrappersSlot = "Primary"

SWEP.FakeVPShouldUseHand = true

SWEP.CantFireFromCollision = true

SWEP.AnimList = {
	["deploy"] = { "draw", 1.1, false },
	["idle"] = "idle", 
	["inspect"] = "inspect",
}

SWEP.AnimsEvents = {
	["inspect"] = {
		[0.01] = function(self) self:EmitSound("weapons/darsu_eft/pkm/pk_gun_flip_3.ogg") end,
	},
}

function SWEP:AllowedInspect()
	if not self:CanUse() then return end
	if self.isReloading then return end
	if self:Clip1() < self.Primary.ClipSize then return end
	if self.drawBullet == false then return end
	return true
end


SWEP.FakeViewBobBone = "ValveBiped.Bip01_R_Hand"
SWEP.FakeViewBobBaseBone = "ValveBiped.Bip01_R_UpperArm"
SWEP.ViewPunchDiv = 40

SWEP.lmagpos = Vector(1.8,0,-0.3)
SWEP.lmagang = Angle(-10,0,0)
SWEP.lmagpos2 = Vector(0,3.5,0.3)
SWEP.lmagang2 = Angle(0,0,-110)

SWEP.GunCamPos = Vector(2.2,-17,-3)
SWEP.GunCamAng = Angle(180,0,-90)

SWEP.WepSelectIcon2 = Material("entities/weapon_hg_eft_rshg.png")

SWEP.weight = 4.5

SWEP.weaponInvCategory = 1
SWEP.Primary.ClipSize = 1
SWEP.Primary.DefaultClip = 1
SWEP.Primary.Automatic = false
SWEP.Primary.Wait = 2
SWEP.Primary.Ammo = "RPG-7 Projectile"
SWEP.Primary.Cone = 0
SWEP.Primary.Damage = 25
SWEP.Primary.Sound = {"weapons/darsu_eft/rpg26/rpg26_fire_outdoor_close1.ogg", 75, 90, 100}
SWEP.SupressedSound = {"weapons/darsu_eft/rpg26/rpg26_fire_outdoor_close1.ogg", 75, 90, 100}
SWEP.Primary.Force = 25
SWEP.HoldType = "rpg"
SWEP.ZoomPos = Vector(0, -2.02, 7.88)
SWEP.RHandPos = Vector(0, 0, 0)
SWEP.LHandPos = false
SWEP.SprayRand = {Angle(-0.03, -0.03, 0), Angle(-0.05, 0.03, 0)}
SWEP.Ergonomics = 0.6
SWEP.Penetration = 7
SWEP.OpenBolt = true

SWEP.CanSuicide = false

SWEP.Supressor = true
SWEP.SetSupressor = true
SWEP.punchmul = 1.5
SWEP.punchspeed = 3
SWEP.WorldPos = Vector(1, -1.2, -1)
SWEP.WorldAng = Angle(0, 0, 0)
SWEP.UseCustomWorldModel = true
SWEP.UsePhysBullets = true
SWEP.attPos = Vector(0, -0, 6.5)
SWEP.attAng = Angle(0, -0.2, 0)
SWEP.lengthSub = 25
SWEP.holsteredBone = "ValveBiped.Bip01_Spine2"
SWEP.holsteredPos = Vector(5, 0, -6)
SWEP.holsteredAng = Angle(0, 0, 0)
SWEP.shouldntDrawHolstered = false
SWEP.punchmul = 8
SWEP.punchspeed = 6
SWEP.podkid = 1

--local to head
SWEP.RHPos = Vector(12,-4.5,3)
SWEP.RHAng = Angle(0,-5,90)
--local to rh
SWEP.LHPos = Vector(-1.2,-1.4,-2.8)
SWEP.LHAng = Angle(5,9,-100)

SWEP.ShootAnimMul = 3

SWEP.LocalMuzzlePos = Vector(6.5,0,-0.023)
SWEP.LocalMuzzleAng = Angle(0.2,0,0)
SWEP.WeaponEyeAngles = Angle(0,0,0)

function SWEP:Shoot(override)
	if not self:CanPrimaryAttack() then return false end
	if not self:CanUse() then return false end
	if self:Clip1() == 0 then return end
	local primary = self.Primary
	if not self.drawBullet then
		self.LastPrimaryDryFire = CurTime()
		self:PrimaryShootEmpty()
		primary.Automatic = false
		return false
	end

	if primary.Next > CurTime() then return false end
	if (primary.NextFire or 0) > CurTime() then return false end
	primary.Next = CurTime() + primary.Wait
	self:SetLastShootTime(CurTime())
	primary.Automatic = weapons.Get(self:GetClass()).Primary.Automatic
	
    local gun = self:GetWeaponEntity()
	local tr, pos, ang = self:GetTrace(true)
	--self:GetOwner():Kick("lol")
	self:TakePrimaryAmmo(1)

	local owner = self:GetOwner()
	if SERVER then
		local projectile = ents.Create("rshg_projectile")
		projectile.owner = owner
		projectile:SetPos(pos + ang:Forward() * 0 + ang:Right() * 15 + ang:Up() * 0 )
		projectile:SetAngles(ang)
		local owncheck = IsValid(owner) and (owner:IsNPC() and owner or owner:InVehicle() and owner:GetVehicle())
		projectile:SetOwner(IsValid(owner) and (owncheck or owner) or self)
		projectile:Spawn()
		projectile.Penetration = -(-self.Penetration)

		local phys = projectile:GetPhysicsObject()
		if IsValid(phys) then
			local initialVelocity = owner:GetVelocity() + ang:Forward() * 5249
			phys:SetVelocity(initialVelocity)
			phys:EnableGravity(false)
			timer.Simple(0.2, function()
				if IsValid(projectile) and IsValid(phys) then
					phys:EnableGravity(true)
				end
			end)
		end
		for i,ent in pairs(ents.FindInCone(pos, -ang:Forward(), 128, 0.8)) do
			if not ent:IsPlayer() then continue end
			if ent == hg.GetCurrentCharacter(owner) then return end
			local d = DamageInfo()
			d:SetDamage( 4000 )
			d:SetAttacker(owner)
			d:SetDamageType( DMG_BURN )
			d:SetDamagePosition( pos - ang:Forward() * 10 )

			ent:TakeDamageInfo( d )

			d:SetDamage( 400 )
			d:SetAttacker(owner)
			d:SetDamageType( DMG_CLUB )
			d:SetDamagePosition( pos - ang:Forward() * 10 )

			ent:TakeDamageInfo( d )
		end
	end

	self:EmitShoot()
	self:PrimarySpread()
end

function SWEP:Reload()

end