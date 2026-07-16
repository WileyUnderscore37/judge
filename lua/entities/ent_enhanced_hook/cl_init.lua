include("shared.lua")

ENT.HookModel = "models/weapons/c_models/c_grappling_hook/c_grappling_hook.mdl"

local clr = Color(10, 10, 10, 255)

function ENT:Initialize()
	local use = string.upper(input.LookupBinding("+use") or "e")
	local walk = string.upper(input.LookupBinding("+walk") or "alt")

	self.HookHint = markup.Parse("<font=ZCity_Tiny>Grappling Hook</font>\n<font=ZCity_Tiny><colour=125,125,125>" .. use .. " pick up</colour></font>", 450)
	self.SnapHint = markup.Parse("<font=ZCity_Tiny>Snap Hook</font>\n<font=ZCity_Tiny><colour=125,125,125>" .. use .. " grab the rope\n" .. walk .. " + " .. use .. " hang in ragdoll</colour></font>", 450)
end

function ENT:Draw()
	if self:GetNWBool("IsSnapHook", false) then
		self.HudHintMarkup = self.SnapHint
		if IsValid(self.RModel) then self.RModel:SetNoDraw(true) end
		self:DrawModel()
		return
	end

	self.HudHintMarkup = self.HookHint

	if not self.RModel or not IsValid(self.RModel) then
		self.RModel = ClientsideModel(self.HookModel)
		self.RModel:SetNoDraw(true)
		self.RModel:SetMaterial("models/shiny")
		self.RModel:SetColor(clr)
		self.RModel:SetParent(self)
		self:CallOnRemove("Remove_CLMDL", function()
			if IsValid(self.RModel) then self.RModel:Remove() end
		end)
	end

	local Vel, Ang = self:GetVelocity(), self:GetAngles()
	if Vel:Length() > 100 then
		Ang = Vel:Angle()
		if self:GetNWBool("Impacted") then
			Ang:RotateAroundAxis(Ang:Right(), 90)
		else
			Ang:RotateAroundAxis(Ang:Right(), -90)
		end
	end

	self.RModel:SetRenderAngles(Ang)
	self.RModel:SetRenderOrigin(self:GetPos())
	self.RModel:DrawModel()
end
