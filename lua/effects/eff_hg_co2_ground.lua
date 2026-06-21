function EFFECT:Init(data)
	local pos = data:GetOrigin()
	local dir = data:GetNormal()
	local mag = math.Clamp(data:GetMagnitude(), 0.4, 2.5)
	local count = math.max(2, math.floor(4 * mag))
	local emitter = ParticleEmitter(pos)
	for i = 1, count do
		local p = emitter:Add("particle/smokesprites_000" .. math.random(1, 9), pos + VectorRand() * 12)
		if p then
			local flat = VectorRand() * math.Rand(2, 9)
			flat.z = math.Rand(0.2, 1.2)
			p:SetVelocity(flat + dir * math.Rand(1, 4))
			p:SetAirResistance(38)
			p:SetGravity(Vector(0, 0, math.Rand(0.2, 1.2)))
			p:SetDieTime(math.Rand(6.5, 10.5) * mag)
			p:SetStartAlpha(math.random(4, 8))
			p:SetEndAlpha(0)
			p:SetStartSize(math.Rand(12, 22) * mag)
			p:SetEndSize(math.Rand(42, 70) * mag)
			p:SetRoll(math.Rand(-180, 180))
			p:SetRollDelta(math.Rand(-0.12, 0.12))
			p:SetColor(165, 165, 165)
			p:SetLighting(false)
			p:SetCollide(false)
		end
	end
	emitter:Finish()
end

function EFFECT:Think()
	return false
end

function EFFECT:Render()
end
