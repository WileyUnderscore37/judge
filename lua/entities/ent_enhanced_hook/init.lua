AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

ENT.Model = "models/props_junk/cardboard_box004a.mdl"
ENT.SnapModel = "models/phobias/general/snaphook/snap_hook.mdl"
ENT.RopeMat = "cable/cable2"
ENT.DetachCD = 2

util.PrecacheModel(ENT.SnapModel)

local clr = Color(10, 10, 10, 255)
local ropeclr = Color(20, 20, 20)
local badclass = {
	prop_ragdoll = true,
	ent_enhanced_hook = true,
	keyframe_rope = true,
	gmod_anchor = true
}

local stickyrope = CreateConVar("enh_hook_stickyrope", "1", FCVAR_ARCHIVE, "Advanced rope bending: props/entities, hook-side bends, edge slip-off checks. 0 = simple brush-only bends")

local trdat = {}

local function RopeTr(a, b, hook, target)
	trdat.start = a
	trdat.endpos = b
	trdat.mask = stickyrope:GetBool() and MASK_SOLID or MASK_SOLID_BRUSHONLY
	trdat.filter = function(ent)
		if ent == hook or ent == target or ent == hook.WeldEnt then return false end
		if ent:IsPlayer() or badclass[ent:GetClass()] then return false end
		return true
	end
	return util.TraceLine(trdat)
end

local function FindBend(a, b, hook, target)
	local Tr = RopeTr(a, b, hook, target)
	if not Tr.Hit or Tr.Fraction > .97 then return end

	if not Tr.StartSolid then
		local p = Tr.HitPos + Tr.HitNormal * 3
		if p:Distance(a) > 15 and p:Distance(b) > 15 then return p end
	end

	Tr = RopeTr(b, a, hook, target)
	if Tr.Hit and not Tr.StartSolid then
		local p = Tr.HitPos + Tr.HitNormal * 3
		if p:Distance(a) > 15 and p:Distance(b) > 15 then return p end
	end
end

function ENT:Initialize()
	self:SetModel(self.Model)
	self:SetMaterial("models/shiny")
	self:SetColor(clr)
	self:PhysicsInit(SOLID_VPHYSICS)
	self:PhysicsInitBox(Vector(-4, -4, -4), Vector(4, 4, 4))
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)
	self:DrawShadow(true)
	self:SetCollisionGroup(COLLISION_GROUP_NONE)
	self:UseTriggerBounds(true, 24)

	local phys = self:GetPhysicsObject()
	if IsValid(phys) then
		phys:Wake()
		phys:SetMass(100)
		phys:SetMaterial("metal")
		phys:SetDragCoefficient(0)
	end

	self.Stillness = 0
	self.Locked = false
	self.Len = 1500
	self.Fixed = 0
	self.Wraps = {}
	self:SetUseType(SIMPLE_USE)
	self:SetNWBool("Impacted", false)
	self:SetNWBool("IsSnapHook", false)
	self:SetModelScale(1, 0)
end

function ENT:AttachTo(ply, len)
	self.Ply = ply
	self.Len = math.Clamp(len, self.Fixed + 50, 5000)
	self.NextDetach = CurTime() + self.DetachCD
	self.NextMove = CurTime() + 1
	self.Ramp = 0
	self.wasrag = false
	if IsValid(self.SafetyRope) then self.SafetyRope:Remove() end
	self.SafetyRope = nil
end

function ENT:AnchEnt()
	local w = self.Wraps[#self.Wraps]
	if w and IsValid(w.anchor) then return w.anchor end
	return self
end

function ENT:AnchPos()
	local w = self.Wraps[#self.Wraps]
	return w and w.pos or self:GetPos()
end

function ENT:OnSurface()
	local pos = self:GetPos()
	local tr = util.TraceLine({
		start = pos,
		endpos = pos - vector_up * (self:BoundingRadius() + 40),
		filter = IsValid(self.WeldEnt) and {self, self.WeldEnt} or {self},
		mask = MASK_SOLID
	})
	if tr.Hit and not tr.HitSky then return tr.HitNormal end
end

function ENT:PullDir(Dir, tpos)
	local w = self.Wraps[1]
	if not w then return -Dir end

	local hpos = self:GetPos()
	local v = w.pos - hpos
	local d = v:Length()
	local dir1 = d > 1 and v / d or vector_up

	local ground = self:OnSurface()
	if not ground then return dir1 * math.Clamp((d - 8) / 12, 0, 1) end

	local nxt = self.Wraps[2] and self.Wraps[2].pos or tpos
	local dir2 = (nxt - w.pos):GetNormalized()
	local blend = 1 - math.Clamp((d - 15) / 45, 0, 1)
	local out = dir1 * (1 - blend) + dir2 * blend
	out = out - ground * math.min(out:Dot(ground), 0)
	if out:LengthSqr() < .01 then return dir2 end
	return out:GetNormalized()
end

function ENT:Anchored()
	return IsValid(self.WeldEnt)
end

function ENT:Think()
	local Time = CurTime()
	local dt = math.Clamp(Time - (self.LastThink or Time), 0, .1)
	self.LastThink = Time

	if self.IsSnap then
		if not IsValid(self.Hook) then self:Remove() return end
		self:NextThink(Time + .5)
		return true
	end

	if not self.Locked then
		local vel, ent = self:GetRelativeVelocity()
		if vel < 50 then
			self.Stillness = self.Stillness + 1
			if self.Stillness > 10 then
				self.Locked = true
				self:LockToSurface(ent)
			end
		else
			self.Stillness = 0
		end
	end

	if self.Ply ~= nil then
		if IsValid(self.Ply) and self.Ply:Alive() then
			self:CustomThink(dt)
		elseif IsValid(self.Ply) then
			local rag = self.Ply.FakeRagdoll
			self:DropToSnap((IsValid(rag) and rag:GetPos() or self.Ply:GetPos()) + Vector(0, 0, 25), IsValid(rag) and rag:GetVelocity() or self.Ply:GetVelocity())
		else
			self:ClearRopes()
			self.Ply = nil
			self.wasrag = false
		end
	end

	self:NextThink(Time)
	return true
end

function ENT:CustomThink(dt)
	local ply = self.Ply
	local rag = ply.FakeRagdoll
	local target = IsValid(rag) and rag or ply
	local tpos = IsValid(rag) and (rag:GetPos() + Vector(0, 0, 5)) or (ply:GetPos() + Vector(0, 0, 40))

	self:UpdateWraps(target, tpos)

	local Vec = self:AnchPos() - tpos
	local Dir = Vec:GetNormalized()
	local Dist = self.Fixed + Vec:Length()

	if IsValid(rag) then
		if not self.wasrag then
			self.wasrag = true
			self.Locked = true
			self.NextDetach = math.max(self.NextDetach or 0, CurTime() + self.DetachCD)
			self.NextMove = math.max(self.NextMove or 0, CurTime() + 1)
			self.Len = math.Clamp(math.min(self.Len, Dist + 20), self.Fixed + 50, 5000)
			self.Ramp = 0
			self:MakeRope(rag)
		end

		if ply:KeyDown(IN_JUMP) then self:TryDetach(ply, rag) return end
		if not IsValid(self.Rope) or self.RopeEnt ~= rag then self:MakeRope(rag) end

		local can = CurTime() > (self.NextMove or 0)
		local up = can and ply:KeyDown(IN_SPEED)
		local down = can and ply:KeyDown(IN_WALK)

		if up ~= down then
			self.Ramp = math.min((self.Ramp or 0) + dt / .7, 1)
		else
			self.Ramp = math.max((self.Ramp or 0) - dt / .35, 0)
		end

		if up and not down then
			self.Len = math.Clamp(math.min(self.Len, Dist + 10) - 110 * self.Ramp * dt, self.Fixed + 50, 5000)
		elseif down and not up then
			self.Len = math.Clamp(self.Len + 150 * self.Ramp * dt, self.Fixed + 50, 5000)
		end

		local fwd = can and ply:KeyDown(IN_FORWARD)
		local back = can and ply:KeyDown(IN_BACK)

		if fwd ~= back then
			local dir = ply:EyeAngles():Forward()
			dir.z = 0
			if dir:LengthSqr() > .01 then
				dir:Normalize()
				if back then dir = -dir end

				local seg = math.max(self.Len - self.Fixed, 20)
				local off = tpos - self:AnchPos()
				off.z = 0
				local devmax = math.Clamp(seg * .15, 40, 120)
				local fade = 1 - math.Clamp(off:Dot(dir) / devmax, 0, 1)
				if rag:GetVelocity():Dot(dir) > 300 then fade = 0 end

				if fade > 0 then
					local scale = 250 * fade * dt
					for i = 0, rag:GetPhysicsObjectCount() - 1 do
						local bone = rag:GetPhysicsObjectNum(i)
						if IsValid(bone) then bone:ApplyForceCenter(dir * bone:GetMass() * scale) end
					end
				end
			end
		end

		local SegLen = math.max(self.Len - self.Fixed, 20)
		if IsValid(self.Rope) then self.Rope:Fire("SetLength", SegLen) end
		if IsValid(self.Spring) then self.Spring:Fire("SetSpringLength", SegLen) end

		if self:Anchored() and #self.Wraps > 0 then
			local phys = self:GetPhysicsObject()
			local stretch = Dist - self.Fixed - SegLen
			if IsValid(phys) and stretch > 0 then
				local m = self.TargetMass or 85
				local imp = math.min(m * 25 * stretch * dt, phys:GetMass() * 80)
				phys:ApplyForceCenter(self:PullDir(Dir, tpos) * imp - phys:GetVelocity() / 40)
			end
		end
	else
		if self.wasrag then
			self.wasrag = false
			self.Ramp = 0
			self:MakeRope(ply)
		end

		if not IsValid(self.Rope) or self.RopeEnt ~= ply then self:MakeRope(ply) end

		local Eff = Dist - self.Len
		if Eff > 0 then
			local Vel = ply:GetVelocity()
			ply:SetGroundEntity(nil)
			ply:SetVelocity(Dir * math.Clamp(Eff * 8, 0, 130) - Dir:Dot(Vel) * Dir / 2)

			local phys = self:GetPhysicsObject()
			if IsValid(phys) then
				if self:Anchored() then
					local imp = math.min((self.TargetMass or 85) * math.Clamp(Eff * 8, 0, 130), phys:GetMass() * 80)
					phys:ApplyForceCenter(self:PullDir(Dir, tpos) * imp - phys:GetVelocity() / 40)

					local jerk = #self.Wraps == 0 and (phys:GetVelocity() - Vel):Length() or -Dir:Dot(Vel)
					if Eff > 20 and not ply:IsOnGround() and jerk > 1200 then
						self:DropToSnap(ply:GetPos() + Vector(0, 0, 30), ply:GetVelocity())
						return
					end
				elseif #self.Wraps == 0 then
					phys:ApplyForceCenter(-Dir * Eff * 100 - phys:GetVelocity() / 40)
					if Eff > 20 and not ply:IsOnGround() and (phys:GetVelocity() - Vel):Length() > 1200 then
						self:DropToSnap(ply:GetPos() + Vector(0, 0, 30), ply:GetVelocity())
						return
					end
				end
			end
		end

		if IsValid(self.Rope) then self.Rope:Fire("SetLength", math.max(self.Len - self.Fixed, 20) + 10) end
	end
end

function ENT:UpdateWraps(target, tpos)
	local sticky = stickyrope:GetBool()

	for i = 1, 3 do
		local Pos = FindBend(self:AnchPos(), tpos, self, target)
		if not Pos then break end
		local n = #self.Wraps
		self:AddWrap(Pos, target, tpos)
		if #self.Wraps == n then break end
	end

	local hpos = self:GetPos()

	local n = #self.Wraps
	if n > 0 then
		local w = self.Wraps[n]
		local prev = n > 1 and self.Wraps[n - 1].pos or hpos
		local open = not (sticky and w.axis) or (w.pos - prev):Cross(tpos - w.pos):Dot(w.axis) < 0
			or prev:Distance(w.pos) + w.pos:Distance(tpos) - prev:Distance(tpos) < 2

		if open and not RopeTr(prev, tpos, self, target).Hit then
			self.ClearT = self.ClearT or CurTime()
			if CurTime() - self.ClearT > .2 then self:RemoveWrap(target) end
		else
			self.ClearT = nil
		end
	end

	local wf = self.Wraps[1]
	if wf then
		local l = hpos:Distance(wf.pos)
		self.Fixed = math.max(self.Fixed + (l - wf.len), 0)
		wf.len = l
		if IsValid(wf.rope) then wf.rope:Fire("SetLength", math.max(l, 20) + 4) end
	end

	if not sticky then self.FClearT = nil return end

	for i = 1, 2 do
		local w1 = self.Wraps[1]
		if not w1 then break end
		local Pos = FindBend(hpos, w1.pos, self, target)
		if not Pos or not self:AddFrontWrap(Pos) then break end
	end

	if #self.Wraps > 1 then
		local w1, w2 = self.Wraps[1], self.Wraps[2]
		local open = not w1.axis or (w1.pos - hpos):Cross(w2.pos - w1.pos):Dot(w1.axis) < 0
			or hpos:Distance(w1.pos) + w1.pos:Distance(w2.pos) - hpos:Distance(w2.pos) < 2

		if open and not RopeTr(hpos, w2.pos, self, target).Hit then
			self.FClearT = self.FClearT or CurTime()
			if CurTime() - self.FClearT > .2 then self:RemoveFrontWrap() end
		else
			self.FClearT = nil
		end
	else
		self.FClearT = nil
	end
end

function ENT:AddFrontWrap(pos)
	if #self.Wraps >= 12 then return false end
	local hpos = self:GetPos()
	local w1 = self.Wraps[1]
	local Len = pos:Distance(hpos)
	if Len < 15 then return false end

	local anch = ents.Create("gmod_anchor")
	if not IsValid(anch) then return false end
	anch:SetPos(pos)
	anch:Spawn()
	self:DeleteOnRemove(anch)

	local axis = (pos - hpos):Cross(w1.pos - pos)
	if axis:LengthSqr() > 100 then axis:Normalize() else axis = nil end

	if IsValid(w1.rope) then w1.rope:Remove() end
	local l = pos:Distance(w1.pos)
	self.Fixed = math.max(self.Fixed + (l - w1.len), 0)
	w1.len = l
	w1.rope = self:MakeSegment(anch, w1.anchor, l + 4)

	local rope = self:MakeSegment(self, anch, Len + 4)
	table.insert(self.Wraps, 1, {pos = pos, anchor = anch, rope = rope, len = Len, axis = axis})
	self.Fixed = self.Fixed + Len
	self.FClearT = nil
	return true
end

function ENT:RemoveFrontWrap()
	if #self.Wraps < 2 then return end
	local w1 = table.remove(self.Wraps, 1)
	self.Fixed = math.max(self.Fixed - w1.len, 0)
	if IsValid(w1.rope) then w1.rope:Remove() end
	if IsValid(w1.anchor) then w1.anchor:Remove() end

	local w2 = self.Wraps[1]
	if IsValid(w2.rope) then w2.rope:Remove() end
	local l = self:GetPos():Distance(w2.pos)
	self.Fixed = math.max(self.Fixed + (l - w2.len), 0)
	w2.len = l
	w2.rope = self:MakeSegment(self, w2.anchor, l + 4)
	self.FClearT = nil
end

function ENT:AddWrap(pos, target, tpos)
	if #self.Wraps >= 12 then return end
	local Prev = self:AnchPos()
	local Len = pos:Distance(Prev)
	if Len < 15 then return end

	local anch = ents.Create("gmod_anchor")
	if not IsValid(anch) then return end
	anch:SetPos(pos)
	anch:Spawn()
	self:DeleteOnRemove(anch)

	local axis = (pos - Prev):Cross(tpos - pos)
	if axis:LengthSqr() > 100 then axis:Normalize() else axis = nil end

	local rope = self:MakeSegment(self:AnchEnt(), anch, Len + 4)
	table.insert(self.Wraps, {pos = pos, anchor = anch, rope = rope, len = Len, axis = axis})
	self.Fixed = self.Fixed + Len
	self.ClearT = nil
	self:MakeRope(target)
end

function ENT:RemoveWrap(target)
	local w = table.remove(self.Wraps)
	if not w then return end
	self.Fixed = math.max(self.Fixed - w.len, 0)
	if IsValid(w.rope) then w.rope:Remove() end
	if IsValid(w.anchor) then w.anchor:Remove() end
	self.ClearT = nil
	self:MakeRope(target)
end

function ENT:MakeRope(target)
	if IsValid(self.Rope) then self.Rope:Remove() end
	if IsValid(self.Spring) then self.Spring:Remove() end
	self.Rope = nil
	self.Spring = nil
	if not IsValid(target) then return end

	self.Rope = self:MakeSegment(self:AnchEnt(), target, math.max(self.Len - self.Fixed, 50))
	self.RopeEnt = target

	if not target:IsPlayer() then
		local m = 0
		for i = 0, target:GetPhysicsObjectCount() - 1 do
			local bone = target:GetPhysicsObjectNum(i)
			if IsValid(bone) then m = m + bone:GetMass() end
		end

		self.TargetMass = m > 0 and m or 85
		self.Spring = constraint.Elastic(self:AnchEnt(), target, 0, 0, vector_origin, vector_origin, m * 25, m * 5, 0, "", 0, true)
		if IsValid(self.Spring) then self.Spring:Fire("SetSpringLength", math.max(self.Len - self.Fixed, 20)) end
	else
		local pm = target:GetPhysicsObject()
		self.TargetMass = IsValid(pm) and pm:GetMass() or 85
	end
end

function ENT:MakeSegment(from, to, len)
	local rope = ents.Create("keyframe_rope")
	if not IsValid(rope) then return end

	rope:SetPos(from:GetPos())
	rope:SetKeyValue("Width", 3)
	rope:SetKeyValue("RopeMaterial", self.RopeMat)
	rope:SetEntity("StartEntity", from)
	rope:SetKeyValue("StartOffset", "0 0 0")
	rope:SetKeyValue("StartBone", 0)
	rope:SetEntity("EndEntity", to)
	rope:SetKeyValue("EndOffset", to:IsPlayer() and "0 0 10" or "0 0 0")
	rope:SetKeyValue("EndBone", 0)
	rope:SetKeyValue("Length", tostring(math.max(len, 20)))
	rope:SetKeyValue("Collide", "0")
	rope:Spawn()
	rope:Activate()
	from:DeleteOnRemove(rope)
	to:DeleteOnRemove(rope)
	return rope
end

function ENT:TryDetach(ply, rag)
	if CurTime() < (self.NextDetach or 0) then
		if (self.NextDeny or 0) < CurTime() then
			self.NextDeny = CurTime() + .5
			ply:EmitSound("buttons/lightswitch2.wav", 50, 90, .4)
		end
		return
	end

	local pos = rag:GetPos() + Vector(0, 0, 25)
	self:DropToSnap(pos, rag:GetVelocity())
	sound.Play("snds_jack_hmcd_grapple/soft.wav", pos, 70, 110)
end

function ENT:DropToSnap(pos, vel)
	if IsValid(self.Rope) then self.Rope:Remove() end
	if IsValid(self.Spring) then self.Spring:Remove() end
	self.Rope = nil
	self.Spring = nil
	self.RopeEnt = nil

	local snap = ents.Create(self:GetClass())
	snap:SetPos(pos)
	snap:SetAngles(Angle(0, math.random(0, 360), 0))
	snap:Spawn()
	snap:Activate()
	snap:MakeSnap(self)

	local phys = snap:GetPhysicsObject()
	if IsValid(phys) and vel then phys:SetVelocity(vel) end

	constraint.Rope(self:AnchEnt(), snap, 0, 0, vector_origin, vector_origin, math.max(self:AnchPos():Distance(pos) + 15, 60), 0, 0, 3, self.RopeMat, false, ropeclr)

	local w1 = self.Wraps[1]
	if self:Anchored() and w1 and IsValid(w1.anchor) then
		if IsValid(self.SafetyRope) then self.SafetyRope:Remove() end
		self.SafetyRope = constraint.Rope(self, w1.anchor, 0, 0, vector_origin, vector_origin, math.max(w1.len, 20) + 10, 0, 0, 0, self.RopeMat, false, ropeclr)
	end

	self.Snap = snap
	self.Ply = nil
	self.wasrag = false
	self.Ramp = 0
	return snap
end

function ENT:ClearRopes()
	if IsValid(self.Rope) then self.Rope:Remove() end
	if IsValid(self.Spring) then self.Spring:Remove() end
	if IsValid(self.SafetyRope) then self.SafetyRope:Remove() end
	self.Rope = nil
	self.Spring = nil
	self.SafetyRope = nil
	self.RopeEnt = nil

	for _, w in ipairs(self.Wraps) do
		if IsValid(w.rope) then w.rope:Remove() end
		if IsValid(w.anchor) then w.anchor:Remove() end
	end
	self.Wraps = {}
	self.Fixed = 0
	self.ClearT = nil
	self.FClearT = nil
end

function ENT:LockToSurface(ent)
	self.WeldEnt = ent
	constraint.Weld(self, ent, 0, 0, 0, true, false)
	local phys = self:GetPhysicsObject()
	if IsValid(phys) then phys:SetMass(IsValid(ent) and not ent:IsWorld() and 20 or 100) end
	sound.Play("snds_jack_hmcd_grapple/lock.wav", self:GetPos(), 75, 100)
end

function ENT:GetRelativeVelocity()
	local SelfPos = self:GetPos()
	local TrDat = {
		start = SelfPos,
		endpos = SelfPos - vector_up * (self:BoundingRadius() + 1),
		filter = {self}
	}

	local Tr = util.TraceLine(TrDat)
	if Tr.Hit and not Tr.HitSky then if IsValid(Tr.Entity) and IsValid(Tr.Entity:GetPhysicsObject()) then return (self:GetPhysicsObject():GetVelocity() - Tr.Entity:GetPhysicsObject():GetVelocity()):Length(), Tr.Entity end end
	return 100, nil
end

function ENT:MakeSnap(hook)
	self.IsSnap = true
	self.Hook = hook
	self.Locked = true
	self:SetNWBool("IsSnapHook", true)
	self:SetMaterial("")
	self:SetColor(color_white)
	self:SetModel(self.SnapModel)
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)

	local phys = self:GetPhysicsObject()
	if not IsValid(phys) then
		self:PhysicsInitBox(Vector(-4, -4, -4), Vector(4, 4, 4))
		phys = self:GetPhysicsObject()
	end

	if IsValid(phys) then
		phys:SetMass(30)
		phys:SetDamping(1, 6)
		phys:SetDragCoefficient(2)
		phys:Wake()
	end
end

function ENT:Use(ply)
	if not IsValid(ply) or not ply:IsPlayer() then return end

	if self.IsSnap then
		local hook = self.Hook
		if not IsValid(hook) then self:Remove() return end
		if IsValid(hook.Ply) then return end

		hook.Snap = nil

		if ply:KeyDown(IN_WALK) and hg and hg.Fake and not IsValid(ply.FakeRagdoll) then
			ply:SetPos(self:GetPos() - Vector(0, 0, 20))
			ply:SetLocalVelocity(vector_origin)
			hg.Fake(ply)
			hook:AttachTo(ply, hook.Fixed + self:GetPos():Distance(hook:AnchPos()) + 30)
		else
			hook:AttachTo(ply, hook.Fixed + ply:GetPos():Distance(hook:AnchPos()) + 50)
		end

		sound.Play("snds_jack_hmcd_grapple/lock.wav", self:GetPos(), 70, 100)
		self:Remove()
		return
	end

	if IsValid(self.Ply) and ply ~= self.Ply then return end

	self:ClearRopes()
	self.Ply = nil
	if IsValid(self.Snap) then self.Snap:Remove() end
	self.Snap = nil
	self.Stillness = 0
	self.Locked = false
	constraint.RemoveAll(self)
	if not ply:HasWeapon("weapon_enhanced_hook") then
		ply:Give("weapon_enhanced_hook")
		ply:SelectWeapon("weapon_enhanced_hook")
	end

	sound.Play("snds_jack_hmcd_grapple/soft.wav", self:GetPos(), 60, 100)
	self:Remove()
end

function ENT:PhysicsCollide(data, physobj)
	if self.IsSnap then return end
	if data.Speed > 20 and data.DeltaTime > .15 then
		if not self:GetNWBool("Impacted", false) then self:SetNWBool("Impacted", true) end
		if data.Speed > 300 then
			sound.Play("snds_jack_hmcd_grapple/hard.wav", self:GetPos(), 70, math.random(90, 110))
			local ent = data.HitEntity
			timer.Simple(0, function()
				if IsValid(ent) and ent:IsPlayer() and ent:Alive() and hg and hg.LightStunPlayer then
					hg.LightStunPlayer(ent)
					hg.velocityDamage(ent, data)
					if IsValid(ent.FakeRagdoll) then
						hg.velocityDamage(ent.FakeRagdoll, data)
					end
				end
			end)
		else
			sound.Play("snds_jack_hmcd_grapple/soft.wav", self:GetPos(), 65, math.random(90, 110))
		end
	end
end

function ENT:OnRemove()
	self:ClearRopes()
end
