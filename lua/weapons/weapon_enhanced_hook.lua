if SERVER then
	AddCSLuaFile()
elseif CLIENT then
	SWEP.DrawAmmo = false
	SWEP.DrawCrosshair = false
	SWEP.Slot = 2
	SWEP.SlotPos = 1

	function SWEP:DrawViewModel()
		return false
	end
end

SWEP.PrintName = "Enhanced Grappling Hook"
SWEP.Instructions = "LMB - throw the hook.\nRMB - attach the rope tightly (without throwing).\nRope control only in ragdoll:\nSHIFT - lift | ALT - lower | W/S - swing | SPACE - release"

if CLIENT then
	SWEP.WepSelectIcon = Material("vgui/wep_jack_hmcd_grapl")
	SWEP.IconOverride = "vgui/wep_jack_hmcd_grapl"
	SWEP.BounceWeaponIcon = false
end

SWEP.ViewModel = "models/weapons/c_models/c_grappling_hook/c_grappling_hook.mdl"
SWEP.WorldModel = "models/weapons/c_models/c_grappling_hook/c_grappling_hook.mdl"

SWEP.AutoSwitchTo = true
SWEP.AutoSwitchFrom = false
SWEP.Category = "ZCity Other"
SWEP.Spawnable = true
SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic = true
SWEP.Primary.Ammo = "none"

SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = true
SWEP.Secondary.Ammo = "none"

SWEP.HomicideSWEP = true
SWEP.JustThrew = false
SWEP.ThrowAbility = 1.5
SWEP.ThrowChargeSpeed = .15
SWEP.NextThinkTime = 0
SWEP.DrawTime = .5
SWEP.NextSpinWhooshTime = 0
SWEP.ENT = "ent_enhanced_hook"
SWEP.WorkWithFake = true
SWEP.weight = 5

function SWEP:SetupDataTables()
	self:NetworkVar("String", 0, "CurrentState")
	self:NetworkVar("Float", 0, "Hidden")
	self:NetworkVar("Float", 1, "Back")
	self:NetworkVar("Float", 2, "ThrowPower")
	self:NetworkVar("Float", 3, "Spin")
	self:NetworkVar("Bool", 0, "ShouldHideWorldModel")
end

function SWEP:Initialize()
	self:SetSpin(0)
	self.NextThinkTime = CurTime() + .01
	self:SetHoldType("normal")
	self:SetCurrentState("Hidden")
	self:SetHidden(100)
	self:SetShouldHideWorldModel(false)
end

function SWEP:OnDrop()
	if self:GetCurrentState() ~= "Nothing" then
		local Ent = ents.Create(self.ENT)
		Ent:SetPos(self:GetPos())
		Ent:SetAngles(self:GetAngles())
		Ent:SetOwner(self:GetOwner())
		Ent:Spawn()
		Ent:Activate()
		local phys = Ent:GetPhysicsObject()
		if IsValid(phys) then phys:SetVelocity(self:GetVelocity() / 2) end
	end

	if SERVER then self:Remove() end
end

function SWEP:PrimaryAttack()
	if CLIENT then return end
	local owner = self:GetOwner()
	if not IsValid(owner) or not owner:IsPlayer() then return end
	if IsValid(owner.FakeRagdoll) then return end

	self.NextSpinWhooshTime = CurTime() + 1
	self:SetCurrentState("Winding")
end

function SWEP:SecondaryAttack()
	if CLIENT then return end
	local owner = self:GetOwner()
	if not IsValid(owner) or not owner:IsPlayer() then return end
	if IsValid(owner.FakeRagdoll) then return end
	if self:GetCurrentState() == "Winding" then return end

	self:SetNextSecondaryFire(CurTime() + 0.5)

	local tr = owner:GetEyeTrace()
	if not tr.Hit or tr.HitSky then return end
	if tr.HitPos:DistToSqr(owner:GetShootPos()) > 130 * 130 then
		owner:EmitSound("buttons/lightswitch2.wav", 50, 90, .4)
		return
	end

	local target = tr.Entity
	if IsValid(target) and target:IsPlayer() then return end

	local hook = ents.Create(self.ENT)
	hook:SetPos(tr.HitPos + tr.HitNormal * 3)
	hook:SetAngles(tr.HitNormal:Angle())
	hook.Owner = owner
	hook:SetOwner(owner)
	hook:Spawn()
	hook:Activate()
	hook.Locked = true
	hook.Stillness = 999
	hook:SetNWBool("Impacted", true)

	if IsValid(target) then
		hook.WeldEnt = target
		local tphys = target:GetPhysicsObjectNum(tr.PhysicsBone or 0)
		if IsValid(tphys) then
			constraint.Weld(hook, target, 0, tr.PhysicsBone or 0, 0, true, false)
		else
			hook:SetParent(target)
		end

		local hphys = hook:GetPhysicsObject()
		if IsValid(hphys) then hphys:SetMass(20) end
	else
		constraint.Weld(hook, game.GetWorld(), 0, 0, 0, true, false)
	end

	sound.Play("snds_jack_hmcd_grapple/lock.wav", hook:GetPos(), 70, 100)
	owner:DoAnimationEvent(ACT_GMOD_GESTURE_MELEE_SHOVE_1HAND)

	hook:AttachTo(owner, math.max((hook:GetPos() - owner:GetPos()):Length() + 100, 200))

	self:SetCurrentState("Nothing")
	self:SetShouldHideWorldModel(true)

	timer.Simple(0, function()
		if IsValid(self) then self:Remove() end
	end)
end

function SWEP:Reload()
end

function SWEP:Think()
	local Time = CurTime()
	local owner = self:GetOwner()
	if not IsValid(owner) or not owner:IsPlayer() then return end

	if self.NextThinkTime <= Time then
		self.NextThinkTime = Time + .025
		local State = self:GetCurrentState()

		if State ~= "Nothing" then
			local HiddenAmt = self:GetHidden()
			local BackAmt = self:GetBack()

			if State == "Idling" then
				if owner:KeyDown(IN_ATTACK) and not IsValid(owner.FakeRagdoll) then self:Windup() end
			elseif State == "Drawing" then
				self:SetHidden(math.Clamp(HiddenAmt - 10 / self.DrawTime, 0, 100))
				if HiddenAmt <= 0 then self:SetCurrentState("Idling") end
			elseif State == "Winding" and not self.JustThrew then
				self:SetHoldType("Grenade")
				if not owner:KeyDown(IN_ATTACK) then
					if self:GetThrowPower() > 0 then
						self:SetCurrentState("Drawing")
						self:SetHidden(100)
						self:SetBack(0)
						self:Throw()
						return
					end
				end

				self:SetBack(math.Clamp(BackAmt + 15, 0, 100))

				local chargeSpeed = 0.15
				if owner.organism and owner.organism.stamina then
					chargeSpeed = (-2.7 + (owner.organism.stamina[1] / 45)) * 0.15
				end
				self:SetThrowPower(math.Clamp(self:GetThrowPower() + 5 * chargeSpeed, 1, 130))
				self.ThrowChargeSpeed = chargeSpeed

				if SERVER then
					if self.NextSpinWhooshTime < CurTime() then
						local Pow = self:GetThrowPower()
						self.NextSpinWhooshTime = CurTime() + math.Clamp(10 / Pow, .3, 1.25)
						sound.Play("weapons/slam/throw.wav", self:GetPos(), 65, math.Clamp(Pow, 60, 130))
						owner:ViewPunch(Angle(-1, 0, 0))
						if owner.organism then owner.organism.stamina.subadd = 1.5 end
					end

					local Spun = self:GetSpin() + 25
					if Spun > 360 then Spun = 0 end
					self:SetSpin(Spun)
				end
			end
		end
	end

	self:NextThink(Time + .025)
	return true
end

function SWEP:Windup()
	if self:GetCurrentState() == "Winding" then return end
	self:SetCurrentState("Winding")
	self:SetThrowPower(1)
	self.JustThrew = false
end

function SWEP:Throw()
	local owner = self:GetOwner()
	if not IsValid(owner) or not owner:IsPlayer() then return end

	owner:SetAnimation(PLAYER_ATTACK1)
	if CLIENT then return end

	self.JustThrew = true
	self:SetCurrentState("Nothing")
	self:SetShouldHideWorldModel(true)
	self:SetHoldType("normal")

	local Vec = owner:GetAimVector()
	local Pos = owner:GetShootPos()
	local ThrowPos = Pos + Vec * 30
	local Tr = util.QuickTrace(Pos, Vec * 35, {owner})
	if Tr.Hit then ThrowPos = Pos + Vec * 10 end
	sound.Play("weapons/slam/throw.wav", self:GetPos(), 75, 80)
	sound.Play("weapons/slam/throw.wav", self:GetPos(), 70, 80)
	sound.Play("weapons/slam/throw.wav", self:GetPos(), 65, 80)

	local Gr = ents.Create(self.ENT)
	Gr:SetPos(ThrowPos)
	Gr.Owner = owner
	Gr:SetOwner(owner)
	Gr:SetAngles(VectorRand():Angle())
	Gr:Spawn()
	Gr:Activate()

	local phys = Gr:GetPhysicsObject()
	if IsValid(phys) then
		phys:SetVelocity(owner:GetVelocity() + Vec * self:GetThrowPower() * 6 * self.ThrowAbility)
	end
	Gr:SetPhysicsAttacker(owner)
	Gr:AttachTo(owner, 1500)

	timer.Simple(0, function()
		if IsValid(self) then self:Remove() end
	end)
end

function SWEP:OnRemove()
	local owner = self:GetOwner()
	if SERVER and IsValid(owner) and owner:IsPlayer() and owner.SelectWeapon and owner:HasWeapon("wep_jack_hmcd_hands") then
		owner:SelectWeapon("wep_jack_hmcd_hands")
	end
end

function SWEP:Holster()
	local State = self:GetCurrentState()
	return State == "Idling" or State == "Hidden" or State == "Nothing"
end

function SWEP:Deploy()
	local owner = self:GetOwner()
	if not IsValid(owner) or not owner:IsPlayer() then return end

	self:SetHidden(100)
	self:SetNextPrimaryFire(CurTime() + 0.5)
	self:SetNextSecondaryFire(CurTime() + 0.5)
	self:SetShouldHideWorldModel(false)
end

if CLIENT then
	local TheMat = Material("cable/cable2")
	local clr = Color(10, 10, 10, 255)

	function SWEP:DrawWorldModel()
		local owner = self:GetOwner()
		if not IsValid(owner) or not owner:IsPlayer() then return end
		if IsValid(owner:GetNWEntity("FakeRagdoll")) then return end

		if self:GetCurrentState() ~= "Nothing" then
			local Pos, Ang = owner:GetBonePosition(owner:LookupBone("ValveBiped.Bip01_R_Hand") or 0)
			if IsValid(self.DatWorldModel) then
				if Pos and Ang then
					local ThePos = Pos + Ang:Forward() * 4 + Ang:Right()
					Ang:RotateAroundAxis(Ang:Forward(), 90)
					if self:GetCurrentState() == "Winding" then
						self.Spining = Lerp(FrameTime() * 45, self.Spining or 0, (self.Spining or 0) + (self:GetThrowPower() / 4))
						Ang:RotateAroundAxis(Ang:Forward(), self.Spining)
						ThePos = ThePos + Ang:Up() * 30
						render.SetMaterial(TheMat)
						local Col = render.GetAmbientLightColor(ThePos)
						render.DrawBeam(Pos, ThePos, 2, 1, 0, Color(Col.r * 255, Col.g * 255, Col.b * 255, 255))
					else
						Ang:RotateAroundAxis(Ang:Forward(), 90)
					end

					self.DatWorldModel:SetRenderOrigin(ThePos)
					self.DatWorldModel:SetRenderAngles(Ang)
					local R, G, B = render.GetColorModulation()
					render.SetColorModulation(.1, .1, .1)
					self.DatWorldModel:DrawModel()
					render.SetColorModulation(R, G, B)
				end
			else
				self.DatWorldModel = ClientsideModel("models/weapons/c_models/c_grappling_hook/c_grappling_hook.mdl")
				self.DatWorldModel:SetMaterial("models/shiny")
				self.DatWorldModel:SetColor(clr)
				self.DatWorldModel:SetModelScale(.8, 0)
				self.DatWorldModel:SetPos(self:GetPos())
				self.DatWorldModel:SetParent(self)
				self.DatWorldModel:SetNoDraw(true)
			end
		end
	end
end
