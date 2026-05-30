local PANEL = {}
local curent_panel 
local red_select = Color(192,0,0)
local menu_music_path = "sound/rem_mainmenu.mp3"
local menu_music_flags = "noblock noplay"
local menu_music_volume = 0.25
local menu_music_station

DISCORD_URL = "https://discord.gg/475EmEdTgH"

local function StopMainMenuMusic()
    if menu_music_station then
        menu_music_station:Stop()
        menu_music_station = nil
    end
end

local function StartMainMenuMusic(owner)
    StopMainMenuMusic()
    sound.PlayFile(menu_music_path, menu_music_flags, function(station)
        if not station then return end
        if not IsValid(owner) or MainMenu ~= owner then
            station:Stop()
            return
        end

        menu_music_station = station
        station:EnableLooping(true)
        station:SetVolume(menu_music_volume)
        station:Play()
    end)
end

local function MenuUnit(num)
    return math.floor(num * math.min(ScrW(), ScrH()) / 1000)
end

local Selects = {
    {Title = "Disconnect", Func = function(luaMenu) RunConsoleCommand("disconnect") end},
    {Title = "Main Menu", Func = function(luaMenu) gui.ActivateGameUI() luaMenu:Close() end},
    {Title = "Discord", Func = function(luaMenu) luaMenu:Close() gui.OpenURL(DISCORD_URL)  end},
    {Title = "Traitor Role",
    GamemodeOnly = true,
    CreatedFunc = function(self, parent, luaMenu)
        local btnSOE = vgui.Create( "DLabel", self )
        btnSOE:SetText( "###" )
        btnSOE:SetMouseInputEnabled( true )
        btnSOE:SizeToContents()
        btnSOE:SetFont( "ZCity_Small" )
        btnSOE:SetTall( MenuUnit(42) )
        btnSOE:Dock(BOTTOM)
        btnSOE:DockMargin(MenuUnit(20),MenuUnit(10),0,0)
        btnSOE:SetTextColor(Color(255,255,255))
        btnSOE:InvalidateParent()
        btnSOE.RColor = Color(225, 225, 225, 255)
        btnSOE.x = btnSOE:GetX()
        btnSOE.OpenTime = CurTime()
        btnSOE.LineLerp = 0
        btnSOE.strTitle = "SOE"

        function btnSOE:DoClick()
            luaMenu:Close()
            hg.SelectPlayerRole(nil, "soe")
        end
    
        local selfa = self
        function btnSOE:Think()
            local isHovered = self:IsHovered()
            self.LineLerp = LerpFT(0.2, self.LineLerp or 0, isHovered and 1 or 0)
                
            self.HoverLerp = LerpFT(0.2, self.HoverLerp or 0, isHovered and 1 or 0)
            self:SetX(self.x + ScreenScaleH(40) + self.HoverLerp * ScreenScaleH(50))

            local elapsed = CurTime() - self.OpenTime
            local charsToShow = math.floor(elapsed * 15)
            local targetText = self.strTitle
            local len = #targetText
            if charsToShow > len then charsToShow = len end
            local ntxt = ""
            for i = 1, len do
                if i <= charsToShow then
                    ntxt = ntxt .. targetText:sub(i, i)
                else
                    ntxt = ntxt .. "#"
                end
            end
            if self:GetText() ~= ntxt then
                self:SetText(ntxt)
                self:SizeToContents()
            end
        end

        function btnSOE:Paint(w, h)
            local isHovered = self:IsHovered()
            local flash = isHovered and (0.5 + 0.5 * math.sin(CurTime() * 10)) or 0
            
            local textColor = self.RColor
            local outlineColor = Color(0, 0, 0, 255)

            if isHovered then
                local v = flash * 255
                textColor = Color(v, v, v, 255)
                local inv = 255 - v
                outlineColor = Color(inv, inv, inv, 255)
            end

            surface.SetFont(self:GetFont())
            local tw, th = surface.GetTextSize(self:GetText())
            
            draw.SimpleTextOutlined(self:GetText(), self:GetFont(), 0, h / 2, textColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER, 1, outlineColor)

            if self.LineLerp and self.LineLerp > 0.01 then
                surface.SetDrawColor(255, 255, 255, 255 * self.LineLerp)
                surface.DrawRect(0, h / 2 + th / 2, tw * self.LineLerp, math.max(1, MenuUnit(1)))
            end
            return true
        end

        local btnSTD = vgui.Create( "DLabel", btnSOE )
        btnSTD:SetText( "###" )
        btnSTD:SetMouseInputEnabled( true )
        btnSTD:SizeToContents()
        btnSTD:SetFont( "ZCity_Small" )
        btnSTD:SetTall( MenuUnit(42) )
        btnSTD:Dock(BOTTOM)
        btnSTD:DockMargin(0,MenuUnit(2),0,0)
        btnSTD:SetTextColor(Color(255,255,255))
        btnSTD:InvalidateParent()
        btnSTD.RColor = Color(225, 225, 225, 255)
        btnSTD.x = btnSTD:GetX()
        btnSTD.OpenTime = CurTime()
        btnSTD.LineLerp = 0
        btnSTD.strTitle = "STD"

        function btnSTD:DoClick()
            luaMenu:Close()
            hg.SelectPlayerRole(nil, "standard")
        end
    
        function btnSTD:Think()
            local isHovered = self:IsHovered()
            self.LineLerp = LerpFT(0.2, self.LineLerp or 0, isHovered and 1 or 0)
    
            self:SetX(self.x + ScreenScaleH(35))

            local elapsed = CurTime() - self.OpenTime
            local charsToShow = math.floor(elapsed * 15)
            local targetText = self.strTitle
            local len = #targetText
            if charsToShow > len then charsToShow = len end
            local ntxt = ""
            for i = 1, len do
                if i <= charsToShow then
                    ntxt = ntxt .. targetText:sub(i, i)
                else
                    ntxt = ntxt .. "#"
                end
            end
            if self:GetText() ~= ntxt then
                self:SetText(ntxt)
                self:SizeToContents()
            end
        end

        function btnSTD:Paint(w, h)
            local isHovered = self:IsHovered()
            local flash = isHovered and (0.5 + 0.5 * math.sin(CurTime() * 10)) or 0
            
            local textColor = self.RColor
            local outlineColor = Color(0, 0, 0, 255)

            if isHovered then
                local v = flash * 255
                textColor = Color(v, v, v, 255)
                local inv = 255 - v
                outlineColor = Color(inv, inv, inv, 255)
            end

            surface.SetFont(self:GetFont())
            local tw, th = surface.GetTextSize(self:GetText())
            
            draw.SimpleTextOutlined(self:GetText(), self:GetFont(), 0, h / 2, textColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER, 1, outlineColor)

            if self.LineLerp and self.LineLerp > 0.01 then
                surface.SetDrawColor(255, 255, 255, 255 * self.LineLerp)
                surface.DrawRect(0, h / 2 + th / 2, tw * self.LineLerp, math.max(1, MenuUnit(1)))
            end
            return true
        end
    end,
    Func = function(luaMenu)
        
    end,
    },
    {Title = "Achievements", Func = function(luaMenu,pp) 
        hg.DrawAchievmentsMenu(pp)
    end},
    {Title = "Settings", Func = function(luaMenu,pp) 
        hg.DrawSettings(pp) 
    end},
    {Title = "Appearance", Func = function(luaMenu,pp) hg.CreateApperanceMenu(pp) end},
    {Title = "Return", Func = function(luaMenu) luaMenu:Close() end},
}

local splasheh = {
    'LIKE HOMICIDED',
    'PLUV PLUV PLUVISKI',
    'LULU IS NOT DEAD | !PLUV',
    'THE TRAITOR WAS KILLED',
    'NAB HOMICIDE SERVER',
    'ALSO TRY MODDED HOMICIDE 2',
    'HOP ON Z-CITY',
    'JOHN Z-CITY',
    ':pluvrare:',
    'SAW51 IS REAL',
    'MORE SMALLTOWN',
    'MORE CLUE2022',
    'BACKROOMS == CLUE',
    'HELL IS NEAR',
    'I WISH YOU GOOD HEALTH, JASON STATHAM'
}

--print(string.upper('I wish you good health, Jason Statham'))
surface.CreateFont("ZC_MM_Title", {
    font = "Verily Serif Mono",
    size = ScreenScale(40),
    weight = 800,
    antialias = true
})
-- local Title = markup.Parse("error")

local Pluv = Material("pluv/pluvkid.jpg")
local LogoistMat = Material("vgui/logoist.png", "noclamp smooth")

function PANEL:InitializeMarkup()
	local mapname = game.GetMap()
	local prefix = string.find(mapname, "_")
	if prefix then
		mapname = string.sub(mapname, prefix + 1)
	end
	local gm = splasheh[math.random(#splasheh)] .. " | " .. string.NiceName(mapname) 

    if hg.PluvTown.Active then
        local text = "<font=ZC_MM_Title><colour=199,2,2>    </colour>City</font>\n<font=ZCity_Tiny><colour=105,105,105>" .. gm .. "</colour></font>"

        self.SelectedPluv = table.Random(hg.PluvTown.PluvMats)

        return markup.Parse(text)
    end

    local text = "<font=ZC_MM_Title><colour=199,2,2,255>Z</colour>-City</font>\n<font=ZCity_Tiny><colour=105,105,105>" .. gm .. "</colour></font>"
    return markup.Parse(text)
end

local color_red = Color(255,25,25,45)
local clr_gray = Color(255,255,255,25)
local clr_verygray = Color(10,10,19,235)
local appearance_preview = {
    width = 340,
    height = 920,
    right = 0,
    top = 210,
    enter_time = 0.4,
    enter_delay = 0.08,
    ambient = Color(0, 0, 0, 255),
    light_right = Color(115, 115, 115, 255),
    light_left = Color(85, 85, 85, 255),
    light_front = Color(92, 92, 92, 255),
    light_back = Color(0, 0, 0, 255),
    light_top = Color(55, 55, 55, 255),
    light_bottom = Color(0, 0, 0, 255),
    fov = 13,
    cam_pos = Vector(100, 0, 65),
    look_ang = Angle(11, 180, 0),
    entity_ang = Angle(0, 0, 0),
    head_yaw = -45,
    head_pitch = 0,
    head_mouse_yaw = 7,
    head_mouse_pitch = 4,
    sequence = "idle_suitcase"
}
local menu_profile = {
    left = 30,
    top = 90,
    min_width = 360,
    height = 160,
    medal_size = 50
}
local menu_title = {
    width = 500,
    offset_x = -11,
    spacing = 55
}
local menu_live = {
    drift_x = 14,
    drift_y = 10,
    shake_x = 1,
    shake_y = 1,
    title_x = 30,
    title_y = 25,
    title_mouse_x = 10,
    title_mouse_y = 7,
    title_float_x = 4,
    title_float_y = 3,
    title_hover_scale = 0.08,
    button_hover_scale = 0.02,
    button_drift_x = 4,
    button_drift_y = 1,
    button_shake_x = 0,
    button_shake_y = 0,
    profile_drift_x = 9,
    profile_drift_y = 6,
    bottom_drift_x = 10,
    bottom_drift_y = 6,
    logo_drift_x = 7,
    logo_drift_y = 4,
    enter_x = 18,
    enter_y = 12
}
local menu_profile_fallback_band = {
    icon = Material("vgui/mats_jack_awards/10")
}
local menu_profile_fallback_medal = {
    icon = Material("vgui/mats_jack_awards/pt")
}

local function CleanupPreviewAccessories(ent)
    if not IsValid(ent) or not ent.modelAccess then return end
    for k, v in pairs(ent.modelAccess) do
        if IsValid(v) then
            v:Remove()
        end
        ent.modelAccess[k] = nil
    end
end

function PANEL:GetPreviewAppearance()
    if not hg or not hg.Appearance then return end
    local appearance
    if hg.Appearance.LoadAppearanceFile and hg.Appearance.SelectedAppearance then
        appearance = hg.Appearance.LoadAppearanceFile(hg.Appearance.SelectedAppearance:GetString())
    end
    appearance = appearance or (hg.Appearance.GetRandomAppearance and hg.Appearance.GetRandomAppearance())
    if not appearance or not hg.Appearance.PlayerModels then return end
    local tMdl = hg.Appearance.PlayerModels[1][appearance.AModel] or hg.Appearance.PlayerModels[2][appearance.AModel]
    if not tMdl or not tMdl.mdl then return end
    return table.Copy(appearance), tMdl
end

function PANEL:GetProfileInfo()
    local ply = LocalPlayer()
    if not IsValid(ply) then
        return "Unknown", "0 XP", nil
    end

    local username = ply:GetNWString("PlayerName", "")
    if username == "" then
        username = ply:Nick()
    end

    local xp = tostring(math.floor(tonumber(ply.exp) or 0)) .. " XP"
    return username, xp, ply
end

function PANEL:GetLiveMouse()
    local mx, my = gui.MouseX(), gui.MouseY()
    if mx <= 0 and my <= 0 then
        mx = ScrW() * 0.5
        my = ScrH() * 0.5
    end
    local nx = math.Clamp((mx / ScrW() - 0.5) * 2, -1, 1)
    local ny = math.Clamp((my / ScrH() - 0.5) * 2, -1, 1)
    return mx, my, nx, ny
end

function PANEL:GetLiveOffset(xAmount, yAmount)
    local _, _, nx, ny = self:GetLiveMouse()
    return nx * xAmount, ny * yAmount
end

function PANEL:GetLiveShake(seedX, seedY, xAmount, yAmount)
    local t = RealTime()
    return math.sin(t * 1.8 + seedX) * xAmount, math.cos(t * 2.4 + seedY) * yAmount
end

function PANEL:Think()
    self.LiveLerp = LerpFT(0.08, self.LiveLerp or 0, 1)
    self.LogoHoverLerp = LerpFT(0.12, self.LogoHoverLerp or 0, IsValid(self.logoPanel) and self.logoPanel:IsHovered() and 1 or 0)

    local enter = 1 - (self.LiveLerp or 0)
    local dockMouseX, dockMouseY = self:GetLiveOffset(MenuUnit(menu_live.drift_x), MenuUnit(menu_live.drift_y))
    local dockShakeX, dockShakeY = self:GetLiveShake(0.6, 1.1, MenuUnit(menu_live.shake_x), MenuUnit(menu_live.shake_y))

    if IsValid(self.lDock) and self.lDockBaseMargins then
        self.lDock:DockMargin(
            math.Round(self.lDockBaseMargins[1] + dockMouseX + dockShakeX - MenuUnit(menu_live.enter_x) * enter),
            math.Round(self.lDockBaseMargins[2] + dockMouseY + dockShakeY + MenuUnit(menu_live.enter_y) * enter),
            self.lDockBaseMargins[3],
            self.lDockBaseMargins[4]
        )
    end

    if IsValid(self.logoPanel) and self.logoBaseMargin then
        local logoMouseX, logoMouseY = self:GetLiveOffset(MenuUnit(menu_live.logo_drift_x), MenuUnit(menu_live.logo_drift_y))
        self.logoPanel:DockMargin(
            math.Round(logoMouseX),
            0,
            0,
            math.Round(self.logoBaseMargin + logoMouseY)
        )
    end

    if IsValid(self.profileInfo) and self.profileBasePos then
        local profileMouseX, profileMouseY = self:GetLiveOffset(MenuUnit(menu_live.profile_drift_x), MenuUnit(menu_live.profile_drift_y))
        local profileShakeX, profileShakeY = self:GetLiveShake(1.7, 2.3, MenuUnit(menu_live.shake_x), MenuUnit(menu_live.shake_y))
        self.profileInfo:SetPos(
            math.Round(self.profileBasePos[1] + profileMouseX + profileShakeX - MenuUnit(menu_live.enter_x) * enter),
            math.Round(self.profileBasePos[2] + profileMouseY + profileShakeY + MenuUnit(menu_live.enter_y) * enter)
        )
    end

    if IsValid(self.bottomDock) and self.bottomDockBasePos then
        local bottomMouseX, bottomMouseY = self:GetLiveOffset(MenuUnit(menu_live.bottom_drift_x), MenuUnit(menu_live.bottom_drift_y))
        local bottomShakeX, bottomShakeY = self:GetLiveShake(2.8, 3.1, MenuUnit(menu_live.shake_x), MenuUnit(menu_live.shake_y))
        self.bottomDock:SetPos(
            math.Round(self.bottomDockBasePos[1] + bottomMouseX + bottomShakeX - MenuUnit(menu_live.enter_x) * enter),
            math.Round(self.bottomDockBasePos[2] + bottomMouseY + bottomShakeY + MenuUnit(menu_live.enter_y) * enter)
        )
    end
end

function PANEL:CreateProfileInfo()
    local profile = vgui.Create("DPanel", self)
    self.profileInfo = profile
    profile:SetSize(MenuUnit(menu_profile.min_width), MenuUnit(menu_profile.height))
    profile:SetPos(MenuUnit(menu_profile.left), MenuUnit(menu_profile.top))
    self.profileBasePos = {MenuUnit(menu_profile.left), MenuUnit(menu_profile.top)}
    profile:SetMouseInputEnabled(false)
    profile:SetAlpha(0)
    profile.Paint = function() end

    local username = vgui.Create("DLabel", profile)
    username:SetPos(0, 0)
    username:SetFont("ZCity_Small")
    username:SetTextColor(color_white)
    username:SetContentAlignment(7)
    username:SetExpensiveShadow(1, Color(0, 0, 0, 225))

    local medal = vgui.Create("DPanel", profile)
    medal:SetPos(0, MenuUnit(28))
    medal:SetSize(MenuUnit(menu_profile.medal_size), MenuUnit(menu_profile.medal_size))
    medal.Band = nil
    medal.Medal = nil
    medal.Paint = function(this, w, h)
        if this.Band and this.Band.icon then
            surface.SetMaterial(this.Band.icon)
            surface.SetDrawColor(255,255,255,255)
            surface.DrawTexturedRect(0, 0, w, h)
        end
        if this.Medal and this.Medal.icon then
            surface.SetMaterial(this.Medal.icon)
            surface.SetDrawColor(255,255,255,255)
            surface.DrawTexturedRect(0, 0, w, h)
        end
    end

    local xp = vgui.Create("DLabel", profile)
    xp:SetPos(MenuUnit(30), MenuUnit(31))
    xp:SetFont("ZCity_Small")
    xp:SetTextColor(Color(175, 175, 175))
    xp:SetContentAlignment(7)
    xp:SetExpensiveShadow(1, Color(0, 0, 0, 225))

    local lastExp = -1
    local lastSkill = -1
    function profile:Think()
        local nameText, xpText, ply = self:GetParent():GetProfileInfo()
        if username:GetText() != nameText then
            username:SetText(nameText)
            username:SizeToContents()
        end
        if xp:GetText() != xpText then
            xp:SetText(xpText)
            xp:SizeToContents()
        end
        if IsValid(ply) and (lastExp != (ply.exp or 0) or lastSkill != (ply.skill or 0) or not medal.Band or not medal.Medal) then
            if ply.GetAwards then
                medal.Band, medal.Medal = ply:GetAwards()
            else
                medal.Band, medal.Medal = menu_profile_fallback_band, menu_profile_fallback_medal
            end
            medal.Band = medal.Band or menu_profile_fallback_band
            medal.Medal = medal.Medal or menu_profile_fallback_medal
            lastExp = ply.exp or 0
            lastSkill = ply.skill or 0
        end
        local medalSize = MenuUnit(menu_profile.medal_size)
        medal:SetSize(medalSize, medalSize)
        medal:SetPos(0, username:GetTall() + MenuUnit(3))
        xp:SetPos(medalSize + MenuUnit(4), username:GetTall() + MenuUnit(5))
        profile:SetWide(math.max(MenuUnit(menu_profile.min_width), username:GetWide() + MenuUnit(8), xp:GetX() + xp:GetWide() + MenuUnit(8)))
    end

    timer.Simple(0, function()
        if not IsValid(profile) then return end
        profile:AlphaTo(255, appearance_preview.enter_time * 0.75, appearance_preview.enter_delay)
    end)
end

function PANEL:CreateAppearancePreview()
    local tbl, tMdl = self:GetPreviewAppearance()
    if not tbl or not tMdl then return end

    if hg.Appearance and hg.Appearance.PrecacheModels then
        hg.Appearance.PrecacheModels()
    end

    local holderW = MenuUnit(appearance_preview.width)
    local holderH = MenuUnit(appearance_preview.height)
    local targetX = ScrW() - holderW - MenuUnit(appearance_preview.right)
    local targetY = MenuUnit(appearance_preview.top)

    self.previewHolder = vgui.Create("DPanel", self)
    local holder = self.previewHolder
    holder:SetSize(holderW, holderH)
    holder:SetPos(targetX, ScrH())
    holder:SetAlpha(0)
    holder:SetMouseInputEnabled(false)
    holder.Paint = function() end

    local preview = vgui.Create("DModelPanel", holder)
    self.previewModel = preview
    preview.OwnerMenu = self
    preview:Dock(FILL)
    preview:SetModel(util.IsValidModel(tostring(tMdl.mdl)) and tostring(tMdl.mdl) or "models/player/group01/female_01.mdl")
    preview:SetFOV(appearance_preview.fov)
    preview:SetLookAng(appearance_preview.look_ang)
    preview:SetCamPos(appearance_preview.cam_pos)
    preview:SetAmbientLight(appearance_preview.ambient)
    preview:SetDirectionalLight(BOX_RIGHT, appearance_preview.light_right)
    preview:SetDirectionalLight(BOX_LEFT, appearance_preview.light_left)
    preview:SetDirectionalLight(BOX_FRONT, appearance_preview.light_front)
    preview:SetDirectionalLight(BOX_BACK, appearance_preview.light_back)
    preview:SetDirectionalLight(BOX_TOP, appearance_preview.light_top)
    preview:SetDirectionalLight(BOX_BOTTOM, appearance_preview.light_bottom)
    preview:SetMouseInputEnabled(false)
    preview.AppearanceTable = tbl

    function preview:LayoutEntity(ent)
        local appearance = self.AppearanceTable
        if not appearance or not hg or not hg.Appearance or not hg.Appearance.PlayerModels then return end

        local modelData = hg.Appearance.PlayerModels[1][appearance.AModel] or hg.Appearance.PlayerModels[2][appearance.AModel]
        if not modelData or not modelData.mdl then return end

        local colorData = appearance.AColor or color_white
        ent:SetNWVector("PlayerColor", Vector((colorData.r or 255) / 255, (colorData.g or 255) / 255, (colorData.b or 255) / 255))

        self.EntityAngle = LerpAngle(FrameTime() * 6, self.EntityAngle or appearance_preview.entity_ang, appearance_preview.entity_ang)
        ent:SetAngles(self.EntityAngle)

        local seq = ent:LookupSequence(appearance_preview.sequence)
        if seq and seq >= 0 then
            ent:SetSequence(seq)
        end

        local owner = self.OwnerMenu
        local nx, ny = 0, 0
        if IsValid(owner) and owner.GetLiveMouse then
            local _, _, newNX, newNY = owner:GetLiveMouse()
            nx, ny = newNX, newNY
        end
        local targetYaw = appearance_preview.head_yaw - nx * appearance_preview.head_mouse_yaw
        local targetPitch = appearance_preview.head_pitch - ny * appearance_preview.head_mouse_pitch
        self.HeadYawLerp = LerpFT(0.08, self.HeadYawLerp or appearance_preview.head_yaw, targetYaw)
        self.HeadPitchLerp = LerpFT(0.08, self.HeadPitchLerp or appearance_preview.head_pitch, targetPitch)
        ent:SetPoseParameter("head_yaw", self.HeadYawLerp)
        ent:SetPoseParameter("head_pitch", self.HeadPitchLerp)
        ent:SetSubMaterial()
        self:SetCamPos(appearance_preview.cam_pos)
        self:SetFOV(appearance_preview.fov)
        self:SetLookAng(appearance_preview.look_ang)

        if ent:GetModel() != modelData.mdl then
            CleanupPreviewAccessories(ent)
            ent:SetModel(modelData.mdl)
            self:SetModel(modelData.mdl)
        end

        local clothes = appearance.AClothes or {}
        local mats = ent:GetMaterials()
        for k, v in SortedPairs(modelData.submatSlots or {}) do
            local slot = 1
            for i = 1, #mats do
                if mats[i] == v then
                    slot = i - 1
                    break
                end
            end
            local sexID = modelData.sex and 2 or 1
            local clothMat = hg.Appearance.Clothes[sexID] and hg.Appearance.Clothes[sexID][clothes[k]]
            ent:SetSubMaterial(slot, clothMat or (hg.Appearance.Clothes[sexID] and hg.Appearance.Clothes[sexID].normal) or nil)
        end

        local facemapSlot = hg.Appearance.FacemapsModels and hg.Appearance.FacemapsModels[modelData.mdl]
        for i = 1, #mats do
            if facemapSlot and hg.Appearance.FacemapsSlots[mats[i]] and hg.Appearance.FacemapsSlots[mats[i]][appearance.AFacemap] then
                ent:SetSubMaterial(i - 1, hg.Appearance.FacemapsSlots[mats[i]][appearance.AFacemap])
            end
        end

        appearance.ABodygroups = appearance.ABodygroups or {}
        for k, v in SortedPairs(ent:GetBodyGroups()) do
            if not appearance.ABodygroups[v.name] then continue end
            local bodygroupData = hg.Appearance.Bodygroups[v.name]
            local bodygroupSet = bodygroupData and bodygroupData[modelData.sex and 2 or 1] and bodygroupData[modelData.sex and 2 or 1][appearance.ABodygroups[v.name]]
            if not bodygroupSet then continue end
            for i = 0, #v.submodels do
                if bodygroupSet[1] == v.submodels[i] then
                    ent:SetBodygroup(k - 1, i)
                    break
                end
            end
        end
    end

    function preview:PostDrawModel(ent)
        local appearance = self.AppearanceTable
        if not appearance or not appearance.AAttachments then return end
        for _, attach in ipairs(appearance.AAttachments) do
            local accessoryData = hg.Accessories and hg.Accessories[attach]
            if accessoryData then
                DrawAccesories(ent, ent, attach, accessoryData, false, true)
            end
        end
        ent:SetupBones()
    end

    function preview:OnRemove()
        if IsValid(self.Entity) then
            CleanupPreviewAccessories(self.Entity)
        end
    end

    timer.Simple(0, function()
        if not IsValid(holder) then return end
        holder:MoveTo(targetX, targetY, appearance_preview.enter_time, 0, appearance_preview.enter_delay)
        holder:AlphaTo(255, appearance_preview.enter_time * 0.75, appearance_preview.enter_delay)
    end)
end

function PANEL:Init()
    self:SetAlpha(0)
    self:SetSize(ScrW(), ScrH())
    self:Center()
    self:SetTitle("")
    self:SetDraggable(false)
    self:SetBorder(false)
    self:SetColorBG(clr_verygray)
    self:SetDraggable(false)
    self:ShowCloseButton(false)
    curent_panel = nil
    self.Title, self.TitleShadow = self:InitializeMarkup()
    self.LiveLerp = 0
    self.LogoHoverLerp = 0
    StartMainMenuMusic(self)

    timer.Simple(0, function()
        if self.First then
            self:First()
        end
    end)

    self.lDock = vgui.Create("DPanel", self)
    local lDock = self.lDock
    lDock:Dock(LEFT)
    lDock:SetSize(ScrW() / 3, ScrH())
    lDock:DockMargin(0, MenuUnit(90), MenuUnit(10), MenuUnit(90))
    self.lDockBaseMargins = {0, MenuUnit(90), MenuUnit(10), MenuUnit(90)}
    lDock.Paint = function(this, w, h)
        if hg.PluvTown.Active then
            surface.SetDrawColor(color_white)
            surface.SetMaterial(self.SelectedPluv or Pluv)
            surface.DrawTexturedRect(0, MenuUnit(27), MenuUnit(35), MenuUnit(27))
        end
    end

    self:CreateAppearancePreview()
    self:CreateProfileInfo()

    self.Buttons = {}
    for k, v in ipairs(Selects) do
        if v.GamemodeOnly and engine.ActiveGamemode() != "zcity" then continue end
        self:AddSelect(lDock, v.Title, v)
    end

    local logoPanel = vgui.Create("DPanel", lDock)
    local logoW = MenuUnit(menu_title.width)
    local logoH = logoW * (math.max(1, LogoistMat:Height()) / math.max(1, LogoistMat:Width()))
    self.logoPanel = logoPanel
    logoPanel:Dock(BOTTOM)
    logoPanel:SetTall(math.ceil(logoH))
    logoPanel:SetMouseInputEnabled(true)
    logoPanel:DockMargin(0, 0, 0, MenuUnit(menu_title.spacing))
    self.logoBaseMargin = MenuUnit(menu_title.spacing)
    logoPanel.Paint = function(this, w, h)
        local driftX, driftY = self:GetLiveOffset(MenuUnit(menu_live.logo_drift_x), MenuUnit(menu_live.logo_drift_y))
        local shakeX, shakeY = self:GetLiveShake(6.4, 7.2, MenuUnit(menu_live.shake_x), MenuUnit(menu_live.shake_y))
        local scale = 1 + (self.LogoHoverLerp or 0) * menu_live.title_hover_scale
        local drawX = MenuUnit(menu_title.offset_x) + driftX + shakeX
        local drawY = driftY + shakeY
        local matrix = Matrix()
        matrix:Translate(Vector(drawX - logoW * (scale - 1) * 0.5, drawY - logoH * (scale - 1) * 0.5, 0))
        matrix:Scale(Vector(scale, scale, 1))
        cam.PushModelMatrix(matrix)
        surface.SetDrawColor(255, 255, 255, 255)
        surface.SetMaterial(LogoistMat)
        surface.DrawTexturedRect(0, 0, logoW, logoH)
        cam.PopModelMatrix()
    end


    local bottomDock = vgui.Create("DPanel", self)
    self.bottomDock = bottomDock
    bottomDock:SetPos(ScreenScale(1), ScrH() - ScrH()/10)
    bottomDock:SetSize(ScreenScale(190), ScreenScaleH(40))
    self.bottomDockBasePos = {ScreenScale(1), ScrH() - ScrH()/10}
    bottomDock.Paint = function(this, w, h) end
    self.panelparrent = vgui.Create("DPanel", self)
    self.panelparrent:SetPos(0, 0)
    self.panelparrent:SetSize(ScrW(), ScrH())
    self.panelparrent:MoveToBack()
    self.panelparrent.Paint = function(this, w, h) end
    
    local git = vgui.Create("DLabel", bottomDock)
    git:Dock(BOTTOM)
    git:DockMargin(ScreenScale(10), 0, 0, 0)
    git:SetFont("ZCity_Tiny")
    git:SetTextColor(clr_gray)
    git:SetText("GitHub: github.com/" .. hg.GitHub_ReposOwner .. "/" .. hg.GitHub_ReposName)
    git:SetContentAlignment(4)
    git:SetMouseInputEnabled(true)
    git:SizeToContents()

    function git:DoClick()
        gui.OpenURL("https://github.com/" .. hg.GitHub_ReposOwner .. "/" .. hg.GitHub_ReposName)
    end

    local version = vgui.Create("DLabel", bottomDock)
    version:Dock(BOTTOM)
    version:DockMargin(ScreenScale(10), 0, 0, 0)
    version:SetFont("ZCity_Tiny")
    version:SetTextColor(clr_gray)
    version:SetText(hg.Version)
    version:SetContentAlignment(4)
    version:SizeToContents()

    local zteam = vgui.Create("DLabel", bottomDock)
    zteam:Dock(BOTTOM)
    zteam:DockMargin(ScreenScale(10), 0, 0, 0)
    zteam:SetFont("ZCity_Tiny")
    zteam:SetTextColor(clr_gray)
    zteam:SetText("EARLY-ACCESS")
    zteam:SetContentAlignment(4)
    zteam:SizeToContents()
end

function PANEL:First( ply )
    self:AlphaTo( 255, 0.1, 0, nil )
end

local gradient_d = surface.GetTextureID("vgui/gradient-d")
local gradient_r = surface.GetTextureID("vgui/gradient-r")
local gradient_l = surface.GetTextureID("vgui/gradient-l")
local menu_gradient_right = Color(18,18,18,65)

local clr_1 = Color(100,100,100,35)
function PANEL:Paint(w,h)
    draw.RoundedBox( 0, 0, 0, w, h, self.ColorBG )
    hg.DrawBlur(self, 5)
    surface.SetDrawColor( menu_gradient_right )
    surface.SetTexture( gradient_r )
    surface.DrawTexturedRect(0,0,w,h)
    surface.SetDrawColor( self.ColorBG )
    surface.SetTexture( gradient_l )
    surface.DrawTexturedRect(0,0,w,h)
    surface.SetDrawColor( clr_1 )
    surface.SetTexture( gradient_d )
    surface.DrawTexturedRect(0,0,w,h)
end

function PANEL:AddSelect( pParent, strTitle, tbl )
    local id = #self.Buttons + 1
    self.Buttons[id] = vgui.Create( "DLabel", pParent )
    local btn = self.Buttons[id]
    btn:SetText( string.rep("#", #(curent_panel == string.lower(strTitle) and strTitle ~= 'Traitor Role' and '[ '..strTitle..' ]' or strTitle)) )
    btn:SetMouseInputEnabled( true )
    btn:SizeToContents()
    btn:SetFont( "ZCity_Small" )
    btn:SetTall( MenuUnit(42) )
    btn:Dock(BOTTOM)
    btn:DockMargin(MenuUnit(15),MenuUnit(2),0,0)
    btn.Func = tbl.Func
    btn.HoveredFunc = tbl.HoveredFunc
    local luaMenu = self 
    if tbl.CreatedFunc then tbl.CreatedFunc(btn, self, luaMenu) end
    btn.RColor = Color(225,225,225)
    btn.OpenTime = CurTime()
    btn.LineLerp = 0
    btn.HoverLerp = 0
    function btn:DoClick()
		for i = 1, 3 do
			surface.PlaySound("shitty/tap_depress.wav")
		end

        for _, child in ipairs(luaMenu:GetChildren()) do
            if child ~= luaMenu.panelparrent then
                child:AlphaTo(0, 0.2, 0, function()
                    if IsValid(child) then child:SetVisible(false) end
                end)
            end
        end

        luaMenu.panelparrent:AlphaTo(0,0.2,0,function()
            if IsValid(luaMenu.panelparrent) then
                luaMenu.panelparrent:Remove()
            end
            luaMenu.panelparrent = vgui.Create("DPanel", luaMenu)
            
            luaMenu.panelparrent:SetPos(0, 0)
            luaMenu.panelparrent:SetSize(ScrW(), ScrH())
            luaMenu.panelparrent:MoveToFront()
            luaMenu.panelparrent.Paint = function(this, w, h) end
            btn.Func(luaMenu,luaMenu.panelparrent)
            curent_panel = string.lower(strTitle)
        end)
    end

    function btn:Think()
        local isHovered = self:IsHovered() or (IsValid(self:GetChild(0)) and self:GetChild(0):IsHovered()) or (IsValid(self:GetChild(0)) and IsValid(self:GetChild(0):GetChild(0)) and self:GetChild(0):GetChild(0):IsHovered())

        self.HoverLerp = LerpFT(0.2, self.HoverLerp or 0, isHovered and 1 or 0)
        self.LineLerp = LerpFT(0.2, self.LineLerp or 0, isHovered and 1 or 0)
        local mouseX, mouseY = luaMenu:GetLiveOffset(MenuUnit(menu_live.button_drift_x), MenuUnit(menu_live.button_drift_y))
        local shakeX, shakeY = luaMenu:GetLiveShake(id * 0.91, id * 1.27, MenuUnit(menu_live.button_shake_x), MenuUnit(menu_live.button_shake_y))
        self:DockMargin(
            math.Round(MenuUnit(15) + mouseX * 0.3 + shakeX + self.HoverLerp * MenuUnit(2)),
            math.Round(MenuUnit(2) + mouseY * 0.1 + shakeY),
            0,
            0
        )

        local elapsed = CurTime() - self.OpenTime
        local charsToShow = math.floor(elapsed * 15)
        local targetText = (curent_panel == string.lower(strTitle) and strTitle ~= 'Traitor Role') and '[ '..strTitle..' ]' or strTitle
        local len = #targetText

        if charsToShow > len then charsToShow = len end

        local ntxt = ""
        for i = 1, len do
            if i <= charsToShow then
                ntxt = ntxt .. targetText:sub(i, i)
            else
                ntxt = ntxt .. "#"
            end
        end

        if self:GetText() ~= ntxt then
            surface.PlaySound("shitty/tap-resonant.wav")
            self:SetText(ntxt)
            self:SizeToContents()
        end
    end

    function btn:Paint(w, h)
        local isHovered = self:IsHovered() or (IsValid(self:GetChild(0)) and self:GetChild(0):IsHovered()) or (IsValid(self:GetChild(0)) and IsValid(self:GetChild(0):GetChild(0)) and self:GetChild(0):GetChild(0):IsHovered())
        local flash = isHovered and (0.5 + 0.5 * math.sin(CurTime() * 10)) or 0
        
        local textColor = self.RColor
        local outlineColor = Color(0, 0, 0, 255)

        if isHovered then
            local v = flash * 255
            textColor = Color(v, v, v, 255)
            local inv = 255 - v
            outlineColor = Color(inv, inv, inv, 255)
        end

        surface.SetFont(self:GetFont())
        local tw, th = surface.GetTextSize(self:GetText())
        local scale = 1 + (self.HoverLerp or 0) * menu_live.button_hover_scale
        local matrix = Matrix()
        matrix:Translate(Vector(0, h * (1 - scale) * 0.5, 0))
        matrix:Scale(Vector(scale, scale, 1))
        cam.PushModelMatrix(matrix)
        draw.SimpleTextOutlined(self:GetText(), self:GetFont(), 0, h / 2, textColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER, 1, outlineColor)

        if self.LineLerp and self.LineLerp > 0.01 then
            surface.SetDrawColor(255, 255, 255, 255 * self.LineLerp)
            surface.DrawRect(0, h / 2 + th / 2, tw * self.LineLerp, math.max(1, MenuUnit(1)))
        end
        cam.PopModelMatrix()
        return true
    end
end

function PANEL:Close()
    StopMainMenuMusic()
    if IsValid(self.previewModel) and IsValid(self.previewModel.Entity) then
        CleanupPreviewAccessories(self.previewModel.Entity)
    end
    self:AlphaTo( 0, 0.1, 0, function() self:Remove() end)
    self:SetKeyboardInputEnabled(false)
    self:SetMouseInputEnabled(false)
end

function PANEL:OnRemove()
    StopMainMenuMusic()
end

vgui.Register( "ZMainMenu", PANEL, "ZFrame")

hook.Add("OnPauseMenuShow","OpenMainMenu",function()
    local run = hook.Run("OnShowZCityPause")
    if run != nil then
        return run
    end

    if MainMenu and IsValid(MainMenu) then
        MainMenu:Close()
        MainMenu = nil
        return false
    end

    MainMenu = vgui.Create("ZMainMenu")
    MainMenu:MakePopup()
    return false
end)
