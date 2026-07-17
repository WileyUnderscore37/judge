TOOL.Name	= "OptiWeld"
TOOL.Category = "Constraints"
TOOL.Command = nil
TOOL.LastClick = 0
TOOL.BasicColor = {180, 30, 220, 255}
TOOL.BasicMaterial = "No_Material"
TOOL.BasicHalos = 20
TOOL.ClientConVar["weld"] = "1"
TOOL.ClientConVar["nocollide"] = "1"
TOOL.ClientConVar["scale"] = "1.5"
TOOL.ClientConVar["strength"] = "0"
TOOL.ClientConVar["improved"] = "0"
TOOL.ClientConVar["showconstraints"] = "0"
TOOL.ClientConVar["color_red"] = TOOL.BasicColor[1]
TOOL.ClientConVar["color_green"] = TOOL.BasicColor[2]
TOOL.ClientConVar["color_blue"] = TOOL.BasicColor[3]
TOOL.ClientConVar["color_alpha"] = TOOL.BasicColor[4]
TOOL.ClientConVar["material"] = TOOL.BasicMaterial
TOOL.ClientConVar["halos"] = TOOL.BasicHalos

if(CLIENT) then

	language.Add("tool.optiweld.name", "OptiWeld")
	language.Add("tool.optiweld.desc", "Finds the best Weld and NoCollide structure to optimize the amount of constraints and reduce server lag.")
	language.Add("tool.optiweld.desc1", "Finds the best Weld and NoCollide structure to optimize\nthe amount of constraints and reduce server lag.")
	language.Add("tool.optiweld.0", "Primary: Select/Unselect entity (Hold to select faster). Secondary: Apply the constraints. Reload: Clear the selection.")

	language.Add("tool.optiweld.weld", "Weld")
	language.Add("tool.optiweld.nocollide", "NoCollide")

	language.Add("tool.optiweld.scale", "Scale:")
	language.Add("tool.optiweld.scale.help", "Scales up the AABB (Hitbox if Improved is checked) to\ncheck which ones intersect with eachother.\nThe higher the more constraints.")

	language.Add("tool.optiweld.strength", "Strength:")
	language.Add("tool.optiweld.strength.help", "Force required before the constraint breaks\n0 = Never Breaks")

	language.Add("tool.optiweld.improved", "Improved")
	language.Add("tool.optiweld.improved.help", "Utilizes the HitBox instead of the AABB, increasing\nthe quality of intricate constraints and reducing useless\nones at the cost of more computing power.")

	language.Add("tool.optiweld.showconstraints", "Show Constraints")
	language.Add("tool.optiweld.showconstraints.help", "Shows the constraints on the entity you're aiming at.\nRed = Weld, Blue = NoCollide, Green = Both")

	language.Add("tool.optiweld.visuals", "Selected Entity Visuals")

	language.Add("tool.optiweld.reset", "Reset Settings")

	language.Add("tool.optiweld.halos", "Halos:")
	language.Add("tool.optiweld.halos.help", "How many halos get rendered around the selected \nentities, might cause lag on computers with no GPU.")

	net.Receive("OptiWeldEntity", function()

		local EntIndex = net.ReadInt(32)
		local Type = net.ReadInt(32)
		local Ply = LocalPlayer()
		local Ent = Entity(EntIndex)

		if(!istable(Ply.EntTable)) then

			Ply.EntTable = {}

		end

		if(Type == 1) then

			Ply.EntTable[EntIndex] = Ent
			Ent.OptiWeldSelected = Ply.EntTable

		else

			Ply.EntTable[EntIndex] = nil
			Ent.OptiWeldSelected[Ent:EntIndex()] = nil

		end

	end)

	net.Receive("OptiWeldSound", function()

		local String = net.ReadString()

		surface.PlaySound(String)

	end)

else

	util.AddNetworkString("OptiWeldEntity")
	util.AddNetworkString("OptiWeldSound")

end

local function selectEntity(Ply, Ent, FastMode)

	if(!istable(Ply.EntTable)) then

		Ply.EntTable = {}

	end

	if(Ent:IsValid() && Ent:GetClass() == "worldspawn") then return end

	if(istable(FPP)) then

		if(!Ent:CPPICanTool(Ply)) then return end

	end

	if(!isentity(Ply.EntTable[Ent:EntIndex()])) then

		local Tool = Ply:GetTool("optiweld")

		local Red = Tool:GetClientNumber("color_red")
		local Green = Tool:GetClientNumber("color_green")
		local Blue = Tool:GetClientNumber("color_blue")
		local Alpha = Tool:GetClientNumber("color_alpha")
		local Mat = Tool:GetClientInfo("material")

		Ply.EntTable[Ent:EntIndex()] = Ent
		Ent.OptiWeldSelected = Ply.EntTable
		Ent.OriginalColor = Ent:GetColor()
		Ent.OriginalRenderMode = Ent:GetRenderMode()
		Ent.OriginalMaterial = Ent:GetMaterial()
		Ent:SetColor(Color(Red, Green, Blue, Alpha))
		Ent:SetRenderMode(RENDERMODE_TRANSALPHA)

		if(Mat != "No_Material") then

			Ent:SetMaterial(Mat)

		end

		net.Start("OptiWeldEntity")
			net.WriteInt(Ent:EntIndex(), 32)
			net.WriteInt(1, 32)
		net.Send(Ply)

		net.Start("OptiWeldSound")
			net.WriteString("buttons/button22.wav")
		net.Send(Ply)

	else

		if(!FastMode) then

			Ply.EntTable[Ent:EntIndex()] = nil
			Ent.OptiWeldSelected = nil
			Ent:SetColor(Ent.OriginalColor)
			Ent:SetRenderMode(Ent.OriginalRenderMode)
			Ent:SetMaterial(Ent.OriginalMaterial)

			net.Start("OptiWeldEntity")
				net.WriteInt(Ent:EntIndex(), 32)
				net.WriteInt(0, 32)
			net.Send(Ply)

			net.Start("OptiWeldSound")
				net.WriteString("buttons/button22.wav")
			net.Send(Ply)

		end

	end

end

local function intersectBoundingBoxes(Ent1, Ent2, Mul)

	local AABBMin1, AABBMax1 = Ent1:GetRotatedAABB(Ent1:OBBMins(), Ent1:OBBMaxs())
	local AABBMin2, AABBMax2 = Ent2:GetRotatedAABB(Ent2:OBBMins(), Ent2:OBBMaxs())

	AABBMin1:Mul(Mul)
	AABBMax1:Mul(Mul)
	AABBMin2:Mul(Mul)
	AABBMax2:Mul(Mul)

	AABBMin1 = Ent1:GetPos() + AABBMin1
	AABBMax1 = Ent1:GetPos() + AABBMax1
	AABBMin2 = Ent2:GetPos() + AABBMin2
	AABBMax2 = Ent2:GetPos() + AABBMax2

	if(AABBMin1.X <= AABBMax2.X && AABBMax1.X >= AABBMin2.X && AABBMin1.Y <= AABBMax2.Y && AABBMax1.Y >= AABBMin2.Y && AABBMin1.Z <= AABBMax2.Z && AABBMax1.Z >= AABBMin2.Z) then

		return true

	else

		return false

	end


end

local function intersectHitBoxes(Ent1, Ent2, Mul)

	local BoundsMin1, BoundsMax1 = Ent1:GetCollisionBounds()
	local BoundsMin2, BoundsMax2 = Ent2:GetCollisionBounds()
	local Ang1 = Ent1:GetAngles()
	local Ang2 = Ent2:GetAngles()
	local Pos1 = Ent1:GetPos()
	local Pos2 = Ent2:GetPos()

	BoundsMin1:Mul(Mul)
	BoundsMax1:Mul(Mul)
	BoundsMin2:Mul(Mul)
	BoundsMax2:Mul(Mul)

	local Points1 = {}

	Points1[1] = Vector(BoundsMin1.X, BoundsMin1.Y, BoundsMin1.Z)
	Points1[2] = Vector(BoundsMin1.X, BoundsMin1.Y, BoundsMax1.Z)
	Points1[3] = Vector(BoundsMin1.X, BoundsMax1.Y, BoundsMin1.Z)
	Points1[4] = Vector(BoundsMin1.X, BoundsMax1.Y, BoundsMax1.Z)
	Points1[5] = Vector(BoundsMax1.X, BoundsMin1.Y, BoundsMin1.Z)
	Points1[6] = Vector(BoundsMax1.X, BoundsMin1.Y, BoundsMax1.Z)
	Points1[7] = Vector(BoundsMax1.X, BoundsMax1.Y, BoundsMin1.Z)
	Points1[8] = Vector(BoundsMax1.X, BoundsMax1.Y, BoundsMax1.Z)

	local Rays1 = {}

	Rays1[1] = {Points1[1], Points1[2] - Points1[1]}
	Rays1[2] = {Points1[1], Points1[3] - Points1[1]}
	Rays1[3] = {Points1[1], Points1[5] - Points1[1]}
	Rays1[4] = {Points1[3], Points1[4] - Points1[3]}
	Rays1[5] = {Points1[3], Points1[7] - Points1[3]}
	Rays1[6] = {Points1[4], Points1[8] - Points1[4]}
	Rays1[7] = {Points1[7], Points1[8] - Points1[7]}
	Rays1[8] = {Points1[7], Points1[5] - Points1[7]}
	Rays1[9] = {Points1[5], Points1[6] - Points1[5]}
	Rays1[10] = {Points1[8], Points1[6] - Points1[8]}
	Rays1[11] = {Points1[2], Points1[6] - Points1[2]}
	Rays1[12] = {Points1[2], Points1[4] - Points1[2]}

	local Points2 = {}

	Points2[1] = Vector(BoundsMin2.X, BoundsMin2.Y, BoundsMin2.Z)
	Points2[2] = Vector(BoundsMin2.X, BoundsMin2.Y, BoundsMax2.Z)
	Points2[3] = Vector(BoundsMin2.X, BoundsMax2.Y, BoundsMin2.Z)
	Points2[4] = Vector(BoundsMin2.X, BoundsMax2.Y, BoundsMax2.Z)
	Points2[5] = Vector(BoundsMax2.X, BoundsMin2.Y, BoundsMin2.Z)
	Points2[6] = Vector(BoundsMax2.X, BoundsMin2.Y, BoundsMax2.Z)
	Points2[7] = Vector(BoundsMax2.X, BoundsMax2.Y, BoundsMin2.Z)
	Points2[8] = Vector(BoundsMax2.X, BoundsMax2.Y, BoundsMax2.Z)

	local Rays2 = {}

	Rays2[1] = {Points2[1], Points2[2] - Points2[1]}
	Rays2[2] = {Points2[1], Points2[3] - Points2[1]}
	Rays2[3] = {Points2[1], Points2[5] - Points2[1]}
	Rays2[4] = {Points2[3], Points2[4] - Points2[3]}
	Rays2[5] = {Points2[3], Points2[7] - Points2[3]}
	Rays2[6] = {Points2[4], Points2[8] - Points2[4]}
	Rays2[7] = {Points2[7], Points2[8] - Points2[7]}
	Rays2[8] = {Points2[7], Points2[5] - Points2[7]}
	Rays2[9] = {Points2[5], Points2[6] - Points2[5]}
	Rays2[10] = {Points2[8], Points2[6] - Points2[8]}
	Rays2[11] = {Points2[2], Points2[6] - Points2[2]}
	Rays2[12] = {Points2[2], Points2[4] - Points2[2]}

	for k, v in pairs(Rays1) do

		local StartPoint = v[1]
		local Delta = v[2]

		local Result = util.IntersectRayWithOBB(StartPoint, Delta, Ent1:WorldToLocal(Pos2), Ent1:WorldToLocalAngles(Ang2), BoundsMin2, BoundsMax2)
		local Bool = isvector(Result)

		if(Bool) then

			return true

		end

	end

	for k, v in pairs(Rays2) do

		local StartPoint = v[1]
		local Delta = v[2]

		local Result = util.IntersectRayWithOBB(StartPoint, Delta, Ent2:WorldToLocal(Pos1), Ent2:WorldToLocalAngles(Ang1), BoundsMin1, BoundsMax1)
		local Bool = isvector(Result)

		if(Bool) then

			return true

		end

	end

	return false

end

local function notifyPlayer(Ply, Msg)

	Ply:SendLua("GAMEMODE:AddNotify( '"..Msg.."', 0, 2 )\nsurface.PlaySound('buttons/button16.wav')")

end

function TOOL:Deploy()

	local Owner = self:GetOwner()

	if(!istable(Owner.EntTable)) then

		Owner.EntTable = {}

	end

end

function TOOL:LeftClick(tr)

	if(CLIENT) then return end

	local Owner = self:GetOwner()
	self.FastMode = false

	if(self.LastClick >= CurTime()) then return end
	self.LastClick = CurTime()

	local Ent = tr.Entity

	selectEntity(Owner, Ent, false)

	timer.Create("OptiWeld_FastMode", 0.5, 1, function()

		if(self != nil) then

			if(Owner:KeyDown(IN_ATTACK)) then

				self.FastMode = true
				notifyPlayer(Owner, "Fast Mode is ON")

			end

		end

	end)

end

function TOOL:RightClick(tr)

	if(CLIENT) then return end

	local Owner = self:GetOwner()
	local ConstraintTable = {}
	local Mul = self:GetClientNumber("scale")
	local Weld = self:GetClientNumber("weld")
	local NoCollide = self:GetClientNumber("nocollide")
	local Strength = self:GetClientNumber("strength")
	local Improved = self:GetClientNumber("improved")

	if(self.LastClick >= CurTime()) then return end
	self.LastClick = CurTime()

	if(Improved == 0) then

		if(istable(Owner.EntTable) && table.Count(Owner.EntTable) > 1) then

			for _, v in pairs(Owner.EntTable) do

					for _, v1 in pairs(Owner.EntTable) do

						if(v != v1) then

							if(intersectBoundingBoxes(v, v1, Mul)) then

								local LastWeld1 = constraint.Find(v, v1, "Weld", 0, 0)
								local LastWeld2 = constraint.Find(v1, v, "Weld", 0, 0)
								local LastNoCollide1 = constraint.Find(v, v1, "NoCollide", 0, 0)
								local LastNoCollide2 = constraint.Find(v1, v, "NoCollide", 0, 0)
								local Constraint = nil

								if(Weld == 1 && NoCollide == 1) then

									if((LastWeld1 == nil && LastWeld2 == nil) || (LastNoCollide1 == nil && LastNoCollide2 == nil)) then

										Constraint = constraint.Weld(v, v1, 0, 0, Strength, true)

									end

								elseif(Weld == 1 && NoCollide == 0) then

									if(LastWeld1 == nil && LastWeld2 == nil) then

										Constraint = constraint.Weld(v, v1, 0, 0, Strength, false)

									end

								elseif(Weld == 0 && NoCollide == 1) then

									if(LastNoCollide1 == nil && LastNoCollide2 == nil) then

										Constraint = constraint.NoCollide(v, v1, 0, 0)
										print(v)
										print(v1)

									end

								elseif(Weld == 0 && NoCollide == 0) then

									Owner:SendLua("GAMEMODE:AddNotify( 'Please select the type of constraint.', 1, 4 )\nsurface.PlaySound('buttons/button10.wav')")

									return

								end

								table.insert(ConstraintTable, Constraint)

							end

						end

					end

				selectEntity(Owner, v, false)

				v:SetColor(v.OriginalColor)

				Owner.EntTable[v:EntIndex()] = nil
				v.OptiWeldSelected = nil
				v = nil

			end

			net.Start("OptiWeldSound")
				net.WriteString("buttons/button24.wav")
			net.Send(Owner)

			Owner:SendLua("GAMEMODE:AddNotify( '"..tostring(table.Count(ConstraintTable)).." constraints made.', 0, 4 )")

			if(table.Count(ConstraintTable) > 0) then

				undo.Create("OptiWeld")

					undo.AddFunction(function()

						for k, v in pairs(ConstraintTable) do

							if(v && v:IsValid()) then

								if(v:GetClass() == "logic_collision_pair") then

									v:Input("EnableCollisions", nil, nil, nil)

								end

								v:Remove()

							end

						end

					end)

					undo.SetPlayer(Owner)
					undo.SetCustomUndoText("Undone constraints")

				undo.Finish()

			end

		end

	else

		if(istable(Owner.EntTable) && table.Count(Owner.EntTable) > 1) then

			for _, v in pairs(Owner.EntTable) do

					for _, v1 in pairs(Owner.EntTable) do

						if(v != v1) then

							if(intersectHitBoxes(v, v1, Mul)) then

								local LastWeld1 = constraint.Find(v, v1, "Weld", 0, 0)
								local LastWeld2 = constraint.Find(v1, v, "Weld", 0, 0)
								local LastNoCollide1 = constraint.Find(v, v1, "NoCollide", 0, 0)
								local LastNoCollide2 = constraint.Find(v1, v, "NoCollide", 0, 0)
								local Constraint = nil

								if(Weld == 1 && NoCollide == 1) then

									if((LastWeld1 == nil && LastWeld2 == nil) || (LastNoCollide1 == nil && LastNoCollide2 == nil)) then

										Constraint = constraint.Weld(v, v1, 0, 0, Strength, true)

									end

								elseif(Weld == 1 && NoCollide == 0) then

									if(LastWeld1 == nil && LastWeld2 == nil) then

										Constraint = constraint.Weld(v, v1, 0, 0, Strength, false)

									end

								elseif(Weld == 0 && NoCollide == 1) then

									if(LastNoCollide1 == nil && LastNoCollide2 == nil) then

										Constraint = constraint.NoCollide(v, v1, 0, 0)
										print(v)
										print(v1)

									end

								elseif(Weld == 0 && NoCollide == 0) then

									Owner:SendLua("GAMEMODE:AddNotify( 'Please select the type of constraint.', 1, 4 )\nsurface.PlaySound('buttons/button10.wav')")

									return

								end

								table.insert(ConstraintTable, Constraint)

							end

						end

					end

				selectEntity(Owner, v, false)

				v:SetColor(v.OriginalColor)

				Owner.EntTable[v:EntIndex()] = nil
				v.OptiWeldSelected = nil
				v = nil

			end

			net.Start("OptiWeldSound")
				net.WriteString("buttons/button24.wav")
			net.Send(Owner)

			Owner:SendLua("GAMEMODE:AddNotify( '"..tostring(table.Count(ConstraintTable)).." constraints made.', 0, 4 )")

			if(table.Count(ConstraintTable) > 0) then

				undo.Create("OptiWeld")

					undo.AddFunction(function()

						for k, v in pairs(ConstraintTable) do

							if(v && v:IsValid()) then

								if(v:GetClass() == "logic_collision_pair") then

									v:Input("EnableCollisions", nil, nil, nil)

								end

								v:Remove()

							end

						end

					end)

					undo.SetPlayer(Owner)
					undo.SetCustomUndoText("Undone constraints")

				undo.Finish()

			end

		end

	end

end

function TOOL:Reload(tr)

	if(CLIENT) then return end

	local Owner = self:GetOwner()

	if(self.LastClick >= CurTime()) then return end
	self.LastClick = CurTime()

	if(istable(Owner.EntTable)) then

		for k, v in pairs(Owner.EntTable) do

			selectEntity(Owner, v, false)

			v:SetColor(v.OriginalColor)

			Owner.EntTable[v:EntIndex()] = nil
			v.OptiWeldSelected = nil
			v = nil

		end

		net.Start("OptiWeldSound")
			net.WriteString("buttons/blip1.wav")
		net.Send(Owner)

	end
end

function TOOL:Holster()

	self.FastMode = false

end

if(CLIENT) then

	CreateMaterial("No_Material", "VertexLitGeneric", {
	 ["$basetexture"] = "models/vortigaunt/pupil",
	 ["$model"] = 1,
	 ["$translucent"] = 1,
	 ["$vertexalpha"] = 1,
	 ["$vertexcolor"] = 1
	})

end

list.Add("OptiWeldMaterials", "No_Material")
list.Add("OptiWeldMaterials", "models/props_c17/metalladder003")
list.Add("OptiWeldMaterials", "models/props_canal/metalwall005b")
list.Add("OptiWeldMaterials", "phoenix_storms/wood")
list.Add("OptiWeldMaterials", "phoenix_storms/bluemetal")
list.Add("OptiWeldMaterials", "phoenix_storms/cube")
list.Add("OptiWeldMaterials", "phoenix_storms/dome")
list.Add("OptiWeldMaterials", "models/props_lab/warp_sheet")
list.Add("OptiWeldMaterials", "phoenix_storms/stripes")
list.Add("OptiWeldMaterials", "hunter/myplastic")
list.Add("OptiWeldMaterials", "models/debug/debugwhite")
list.Add("OptiWeldMaterials", "models/shiny")

function TOOL.BuildCPanel(DForm)

	DForm.Label = vgui.Create("DLabel", DForm)
	DForm.Label:SetPos(15, 30)
	DForm.Label:SetText("#tool.optiweld.desc1")
	DForm.Label:SetTextColor(Color(0, 0, 120))
	DForm.Label:SizeToContents()

	DForm.WeldBox = vgui.Create("DCheckBoxLabel")
	DForm.WeldBox:SetParent(DForm)
	DForm.WeldBox:SetPos(15, 70)
	DForm.WeldBox:SetText("#tool.optiweld.weld")
	DForm.WeldBox:SetTextColor(Color(0, 0, 120))
	DForm.WeldBox:SetConVar("optiweld_weld")
	DForm.WeldBox:SizeToContents()

	DForm.NoCollideBox = vgui.Create("DCheckBoxLabel")
	DForm.NoCollideBox:SetParent(DForm)
	DForm.NoCollideBox:SetPos(15, 95)
	DForm.NoCollideBox:SetText("#tool.optiweld.nocollide")
	DForm.NoCollideBox:SetTextColor(Color(0, 0, 120))
	DForm.NoCollideBox:SetConVar("optiweld_nocollide")
	DForm.NoCollideBox:SizeToContents()

	DForm.ScaleSlider = vgui.Create("DNumSlider")
	DForm.ScaleSlider:SetParent(DForm)
	DForm.ScaleSlider:SetSize(400, 30)
	DForm.ScaleSlider:SetPos(-95, 120)
	DForm.ScaleSlider:SetMin(1)
	DForm.ScaleSlider:SetMax(2)
	DForm.ScaleSlider:SetConVar("optiweld_scale")
	DForm.ScaleSlider:SizeToContents()

	DForm.ScaleSliderText = vgui.Create("DLabel", DForm)
	DForm.ScaleSliderText:SetPos(25, 127)
	DForm.ScaleSliderText:SetText("#tool.optiweld.scale")
	DForm.ScaleSliderText:SetTextColor(Color(0, 0, 120))
	DForm.ScaleSliderText:SizeToContents()

	DForm.ScaleSliderHelp = vgui.Create("DLabel", DForm)
	DForm.ScaleSliderHelp:SetPos(15, 145)
	DForm.ScaleSliderHelp:SetText("#tool.optiweld.scale.help")
	DForm.ScaleSliderHelp:SetTextColor(Color(0, 0, 120))
	DForm.ScaleSliderHelp:SizeToContents()

	DForm.StrengthSlider = vgui.Create("DNumSlider")
	DForm.StrengthSlider:SetParent(DForm)
	DForm.StrengthSlider:SetSize(400, 30)
	DForm.StrengthSlider:SetPos(-95, 190)
	DForm.StrengthSlider:SetMin(0)
	DForm.StrengthSlider:SetMax(100000)
	DForm.StrengthSlider:SetDecimals(0)
	DForm.StrengthSlider:SetConVar("optiweld_strength")
	DForm.StrengthSlider:SizeToContents()

	DForm.StrengthSliderText = vgui.Create("DLabel", DForm)
	DForm.StrengthSliderText:SetPos(20, 197)
	DForm.StrengthSliderText:SetText("#tool.optiweld.strength")
	DForm.StrengthSliderText:SetTextColor(Color(0, 0, 120))
	DForm.StrengthSliderText:SizeToContents()

	DForm.StrengthSliderHelp = vgui.Create("DLabel", DForm)
	DForm.StrengthSliderHelp:SetPos(15, 220)
	DForm.StrengthSliderHelp:SetText("#tool.optiweld.strength.help")
	DForm.StrengthSliderHelp:SetTextColor(Color(0, 0, 120))
	DForm.StrengthSliderHelp:SizeToContents()

	DForm.ImprovedBox = vgui.Create("DCheckBoxLabel")
	DForm.ImprovedBox:SetParent(DForm)
	DForm.ImprovedBox:SetPos(15, 255)
	DForm.ImprovedBox:SetText("#tool.optiweld.improved")
	DForm.ImprovedBox:SetTextColor(Color(0, 0, 120))
	DForm.ImprovedBox:SetConVar("optiweld_improved")
	DForm.ImprovedBox:SizeToContents()

	DForm.ImprovedBoxHelp = vgui.Create("DLabel", DForm)
	DForm.ImprovedBoxHelp:SetPos(15, 275)
	DForm.ImprovedBoxHelp:SetText("#tool.optiweld.improved.help")
	DForm.ImprovedBoxHelp:SetTextColor(Color(0, 0, 120))
	DForm.ImprovedBoxHelp:SizeToContents()

	DForm.ShowConstraintsBox = vgui.Create("DCheckBoxLabel")
	DForm.ShowConstraintsBox:SetParent(DForm)
	DForm.ShowConstraintsBox:SetPos(15, 325)
	DForm.ShowConstraintsBox:SetText("#tool.optiweld.showconstraints")
	DForm.ShowConstraintsBox:SetTextColor(Color(0, 0, 120))
	DForm.ShowConstraintsBox:SetConVar("optiweld_showconstraints")
	DForm.ShowConstraintsBox:SizeToContents()

	DForm.ShowConstraintsHelp = vgui.Create("DLabel", DForm)
	DForm.ShowConstraintsHelp:SetPos(15, 345)
	DForm.ShowConstraintsHelp:SetText("#tool.optiweld.showconstraints.help")
	DForm.ShowConstraintsHelp:SetTextColor(Color(0, 0, 120))
	DForm.ShowConstraintsHelp:SizeToContents()

	DForm.VisualCollapsible = vgui.Create("DCollapsibleCategory", DForm)
	DForm.VisualCollapsible:SetPos(15, 390)
	DForm.VisualCollapsible:SetSize(275, 600)
	DForm.VisualCollapsible:SetExpanded(0)
	DForm.VisualCollapsible:SetLabel("#tool.optiweld.visuals")

	DForm.VisualPanel = vgui.Create("DPanelList", DForm.VisualCollapsible)
	DForm.VisualPanel:SetSpacing(10)
	DForm.VisualPanel:EnableHorizontal(false)
	DForm.VisualCollapsible:SetContents(DForm.VisualPanel)

	DForm.ColorMixer = DForm:AddControl("Color", {
		["label"] = "",
		["red"] = "optiweld_color_red",
		["green"] = "optiweld_color_green",
		["blue"] = "optiweld_color_blue",
		["alpha"] = "optiweld_color_alpha"
	})

	DForm.VisualPanel:AddItem(DForm.ColorMixer)

	DForm.Material = DForm:MatSelect("optiweld_material", list.Get("OptiWeldMaterials"), true, 0.25, 0.25)

	DForm.VisualPanel:AddItem(DForm.Material)

	DForm.HaloSliderText = vgui.Create("DLabel", DForm)
	DForm.HaloSliderText:SetText("#tool.optiweld.halos")
	DForm.HaloSliderText:SetTextColor(Color(0, 0, 120))
	DForm.HaloSliderText:SizeToContents()

	DForm.HaloSlider = vgui.Create("DNumSlider")
	DForm.HaloSlider:SetParent(DForm)
	DForm.HaloSlider:SetSize(100, 30)
	DForm.HaloSlider:SetMin(0)
	DForm.HaloSlider:SetMax(100)
	DForm.HaloSlider:SetDecimals(0)
	DForm.HaloSlider:SetConVar("optiweld_halos")
	DForm.HaloSlider:SizeToContents()

	DForm.HaloSliderHelp = vgui.Create("DLabel", DForm)
	DForm.HaloSliderHelp:SetText("#tool.optiweld.halos.help")
	DForm.HaloSliderHelp:SetTextColor(Color(0, 0, 120))
	DForm.HaloSliderHelp:SizeToContents()

	DForm.VisualPanel:AddItem(DForm.HaloSliderText)
	DForm.VisualPanel:AddItem(DForm.HaloSlider)
	DForm.VisualPanel:AddItem(DForm.HaloSliderHelp)

	DForm.ResetButton = vgui.Create("DButton")
	DForm.ResetButton:SetText("#tool.optiweld.reset")
	DForm.ResetButton.DoClick = function()

		local BasicColor = LocalPlayer():GetTool("optiweld").BasicColor
		local BasicMaterial = LocalPlayer():GetTool("optiweld").BasicMaterial
		local BasicHalos = LocalPlayer():GetTool("optiweld").BasicHalos

		RunConsoleCommand("optiweld_color_red", BasicColor[1])
		RunConsoleCommand("optiweld_color_green", BasicColor[2])
		RunConsoleCommand("optiweld_color_blue", BasicColor[3])
		RunConsoleCommand("optiweld_color_alpha", BasicColor[4])
		RunConsoleCommand("optiweld_halos", BasicHalos)
		RunConsoleCommand("optiweld_material", BasicMaterial)

	end

	DForm.VisualPanel:AddItem(DForm.ResetButton)

end

hook.Add("PreDrawHalos", "OptiWeldSelectedProps", function()

	local Table = LocalPlayer().EntTable

	if(istable(Table)) then

		local Tool = LocalPlayer():GetTool("optiweld")

		if(istable(Tool)) then

			local Red = Tool:GetClientNumber("color_red")
			local Green = Tool:GetClientNumber("color_green")
			local Blue = Tool:GetClientNumber("color_blue")
			local Alpha = Tool:GetClientNumber("color_alpha")

			local Halos = Tool:GetClientNumber("halos")

			halo.Add(Table, Color(Red, Green, Blue, Alpha), 1, 1, Halos)

		end

	end

end)

function TOOL:Think()

	if(CLIENT) then return end

	local Owner = self:GetOwner()

	if(!self.NextTick) then

		self.NextTick = CurTime()

	end

	if(self.NextTick <= CurTime()) then

		local Show = self:GetClientNumber("showconstraints")
		local KeyDown = Owner:KeyDown(IN_ATTACK)

		if(!KeyDown) then

			self.FastMode = false

		end

		if(Show == 1) then

			local Ent = Owner:GetEyeTrace().Entity
			Owner:SendLua("LocalPlayer().OptiWeld_EntWeld = {}")
			Owner:SendLua("LocalPlayer().OptiWeld_EntNoCollide = {}")

			if(Ent:IsValid()) then

				local Welds = constraint.FindConstraints(Ent, "Weld")
				local NoCollides = constraint.FindConstraints(Ent, "NoCollide")

				for k, v in pairs(Welds) do

					local Type = tostring(v["nocollide"])

					Owner:SendLua("LocalPlayer().OptiWeld_EntWeld["..tostring(k).."] = {"..tostring(v["Ent1"]:EntIndex())..","..tostring(v["Ent2"]:EntIndex())..","..Type.."}")

				end

				for k, v in pairs(NoCollides) do

					Owner:SendLua("LocalPlayer().OptiWeld_EntNoCollide["..tostring(k).."] = {"..tostring(v["Ent1"]:EntIndex())..","..tostring(v["Ent2"]:EntIndex()).."}")

				end

			end

		end

		self.NextTick = CurTime() + 0.1

	end

	if(self.FastMode == true) then

		local Ent = Owner:GetEyeTrace().Entity

		selectEntity(Owner, Ent, true)

	end

end

hook.Add("PostDrawTranslucentRenderables", "OptiWeldShowContraints", function()

	local Tool = LocalPlayer():GetTool()
	local Weapon = LocalPlayer():GetActiveWeapon()
	local ToolName = ""
	local WeaponName = ""

	if(Tool != nil) then

		ToolName = Tool.Name

	end

	if(IsValid(Weapon)) then

		WeaponName = Weapon:GetClass()

	end

	if(ToolName == "OptiWeld" && WeaponName == "gmod_tool") then

		local Show = Tool:GetClientNumber("showconstraints")

		if(Show == 1) then

			local Ent = LocalPlayer():GetEyeTrace().Entity

			if(Ent:IsValid()) then

				local Welds = LocalPlayer().OptiWeld_EntWeld
				local NoCollides = LocalPlayer().OptiWeld_EntNoCollide

				if(istable(Welds)) then

					for k, v in pairs(Welds) do

						if(Entity(v[1]) && Entity(v[1]):IsValid() && Entity(v[2]) && Entity(v[2]):IsValid()) then

							local Pos1 = Entity(v[1]):GetPos()
							local Pos2 = Entity(v[2]):GetPos()
							local Type = v[3]
							local Col = Color(255, 0, 0)

							if(Type) then

								Col = Color(0, 255, 0)

							end

							render.DrawLine(Pos1, Pos2, Col)

						end

					end

				end

				if(istable(NoCollides)) then

					for k, v in pairs(NoCollides) do

						if(Entity(v[1]) && Entity(v[1]):IsValid() && Entity(v[2]) && Entity(v[2]):IsValid()) then

							local Pos1 = Entity(v[1]):GetPos()
							local Pos2 = Entity(v[2]):GetPos()
							local Col = Color(0, 0, 255)

							render.DrawLine(Pos1 - Vector(0, 0, 1), Pos2 - Vector(0, 0, 1), Col)

						end

					end

				end

			end

		end

	end

end)

hook.Add("EntityRemoved", "OptiWeldClearList", function(ent)

	if(istable(ent.OptiWeldSelected)) then

		ent.OptiWeldSelected[ent:EntIndex()] = nil

	end

end)
