hg.achievements = hg.achievements or {}
hg.achievements.achievements_data = hg.achievements.achievements_data or {}
hg.achievements.achievements_data.player_achievements = hg.achievements.achievements_data.player_achievements or {}
hg.achievements.achievements_data.created_achevements = {}

hg.achievements.MenuPanel = hg.achievements.MenuPanel or nil

local curent_panel_ach

concommand.Add("hg_achievements", function()
    print("use esc menu")
end)

BlurBackground = BlurBackground or hg.DrawBlur

local gradient_l = Material("vgui/gradient-l")
local gradient_u = Material("vgui/gradient-u")
local gradient_r = Material("vgui/gradient-r")
local gradient_d = Material("vgui/gradient-d")

local ach_color_bg = Color(18, 18, 22, 235)
local ach_color_bg_dim = Color(10, 10, 19, 235)
local ach_color_bg_hover = Color(20, 20, 30, 235)
local ach_color_text = Color(235, 235, 235)
local ach_color_text_dim = Color(170, 170, 170)
local ach_color_outline = Color(255, 255, 255, 170)
local ach_color_outline_strong = Color(255, 255, 255, 235)
local ach_menu_gradient_right = Color(18, 18, 18, 65)
local ach_menu_gradient_left = Color(10, 10, 19, 235)
local ach_menu_gradient_down = Color(100, 100, 100, 35)
local ach_tex_gradient_d = surface.GetTextureID("vgui/gradient-d")
local ach_tex_gradient_r = surface.GetTextureID("vgui/gradient-r")
local ach_tex_gradient_l = surface.GetTextureID("vgui/gradient-l")

local function MenuUnit(num)
    return math.floor(num * math.min(ScrW(), ScrH()) / 1000)
end

local function CreateAchievementFonts()
    local scale = math.min(ScrW(), ScrH()) / 1000

    surface.CreateFont("HG_Achievement_Medium", {
        font = "Verily Serif Mono",
        size = math.max(18, math.floor(24 * scale)),
        weight = 300,
    })

    surface.CreateFont("HG_Achievement_Small", {
        font = "Verily Serif Mono",
        size = math.max(15, math.floor(20 * scale)),
        weight = 300,
    })

    surface.CreateFont("HG_Achievement_Tiny", {
        font = "Verily Serif Mono",
        size = math.max(13, math.floor(16 * scale)),
        weight = 300,
    })
end
hook.Add("OnScreenSizeChanged", "HG_Achievement_Fonts", CreateAchievementFonts)
CreateAchievementFonts()

local function BuildMaskedText(text, startTime, speed)
    text = tostring(text or "")
    local charsToShow = math.floor(math.max(0, CurTime() - (startTime or CurTime())) * (speed or 20))
    charsToShow = math.Clamp(charsToShow, 0, #text)

    local masked = {}
    for i = 1, #text do
        local char = text:sub(i, i)
        if char == "\n" then
            masked[i] = "\n"
        else
            masked[i] = i <= charsToShow and char or "#"
        end
    end

    return table.concat(masked)
end

local function PaintGrayBox(w, h, fillColor, outlineColor)
    surface.SetDrawColor(fillColor)
    surface.DrawRect(0, 0, w, h)
    surface.SetDrawColor(255, 255, 255, 12)
    surface.SetMaterial(gradient_d)
    surface.DrawTexturedRect(0, 0, w, h)
    surface.SetDrawColor(outlineColor)
    surface.DrawOutlinedRect(0, 0, w, h, 1)
end

local function PaintButton(self, w, h)
    local fillColor = self:IsHovered() and ach_color_bg_hover or ach_color_bg_dim
    PaintGrayBox(w, h, fillColor, self:IsHovered() and ach_color_outline_strong or ach_color_outline)
end

local function createButton_2(frame, ach, text, func)
    local button = vgui.Create("DButton", frame)

    ach.img = isstring(ach.img) and Material(ach.img) or ach.img
    button.OpenTime = CurTime()
    button:SetText("")
    button:SetTall(ScreenScale(22))
    button:Dock(TOP)
    button:DockMargin(0, 0, 0, ScreenScale(2.5))
    button:SetCursor("hand")

    function button:Paint(w, h)
        local isActive = curent_panel_ach == ach
        self.HoverLerp = LerpFT(0.2, self.HoverLerp or 0, (isActive or self:IsHovered()) and 1 or 0)

        local bg = isActive and ach_color_bg_hover or ach_color_bg_dim
        PaintGrayBox(w, h, bg, self.HoverLerp > 0.2 and ach_color_outline_strong or ach_color_outline)

        local localach = hg.achievements.GetLocalAchievements() or {}
        local val = localach[ach.key] and localach[ach.key].value or ach.start_value
        local percent = ach.showpercent and math.Round(val / math.max(ach.needed_value, 1) * 100, 1) .. "%" or ""
        local base = ach.name .. (ach.showpercent and " | " .. percent or "")
        local result = BuildMaskedText(base, self.OpenTime, 20)

        surface.SetFont("HG_Achievement_Medium")
        local wt, ht = surface.GetTextSize(result)
        surface.SetTextColor(ach_color_text)
        surface.SetTextPos(MenuUnit(10), h / 2 - ht / 2)
        surface.DrawText(result)

        if self.HoverLerp > 0.01 then
            surface.SetDrawColor(255, 255, 255, 255 * self.HoverLerp)
            surface.DrawRect(MenuUnit(10), h - 2, math.max(wt, MenuUnit(30)) * self.HoverLerp, 1)
        end
    end

    button.DoClick = function(self)
        curent_panel_ach = ach
        func(self)
        for i = 1, 3 do
            surface.PlaySound("shitty/tap_depress.wav")
        end
    end

    return button
end

local function PaintFrame(self, w, h)
    PaintGrayBox(w, h, ach_color_bg, ach_color_outline)
end

function hg.DrawAchievmentsMenu(ParentPanel)
    hg.achievements.LoadAchievements()

    if IsValid(hg.achievements.MenuPanel) then
        hg.achievements.MenuPanel:Remove()
        hg.achievements.MenuPanel = nil
    end

    if ParentPanel then
        ParentPanel:SetAlpha(0)
        ParentPanel.Paint = function(self, w, h)
            if hg.DrawBlur then hg.DrawBlur(self, 5) end
            draw.RoundedBox(0, 0, 0, w, h, ach_menu_gradient_left)
            surface.SetDrawColor(ach_menu_gradient_right)
            surface.SetTexture(ach_tex_gradient_r)
            surface.DrawTexturedRect(0, 0, w, h)
            surface.SetDrawColor(ach_menu_gradient_left)
            surface.SetTexture(ach_tex_gradient_l)
            surface.DrawTexturedRect(0, 0, w, h)
            surface.SetDrawColor(ach_menu_gradient_down)
            surface.SetTexture(ach_tex_gradient_d)
            surface.DrawTexturedRect(0, 0, w, h)
        end
    end

    if hg.DrawBlur then hg.DrawBlur(ParentPanel, 5) end
    ParentPanel:AlphaTo(255, 0.15, 0)

    local frame = vgui.Create("DPanel", ParentPanel)
    frame:SetSize(ParentPanel:GetWide() / 2.5, ScreenScale(22) * 8.25 + ScreenScale(2.5))
    frame.TargetX = 5
    frame.TargetY = ParentPanel:GetTall() / 2 - frame:GetTall() / 2
    frame:SetPos(frame.TargetX - MenuUnit(120), frame.TargetY)
    frame:SetAlpha(0)
    frame.Paint = PaintFrame
    frame.Think = function(self)
        local x, y = self:GetPos()
        self:SetPos(Lerp(FrameTime() * 3.5, x, self.TargetX), Lerp(FrameTime() * 3.5, y, self.TargetY))
        self:SetAlpha(Lerp(FrameTime() * 4.5, self:GetAlpha(), 255))
    end

    hg.achievements.MenuPanel = frame

    local scroll = vgui.Create("DScrollPanel", frame)
    scroll:SetSize(frame:GetWide(), frame:GetTall())
    scroll:SetPos(0, 0)
    frame.scroll = scroll

    local sbar = scroll:GetVBar()
    sbar:SetWide(MenuUnit(4))
    sbar:SetHideButtons(true)
    function sbar:Paint(w, h)
        surface.SetDrawColor(255, 255, 255, 35)
        surface.DrawRect(0, 0, w, h)
    end
    function sbar.btnGrip:Paint(w, h)
        self.lerpcolor = Lerp(FrameTime() * 10, self.lerpcolor or 0.4, self:IsHovered() and 1 or 0.75)
        draw.RoundedBox(1, 0, 0, w, h, Color(255 * self.lerpcolor, 255 * self.lerpcolor, 255 * self.lerpcolor, 180))
    end

    function frame:UpdateValues()
        local selectedKey = curent_panel_ach and curent_panel_ach.key
        local firstAch

        self.scroll:Clear()
        curent_panel_ach = nil

        for _, ach in pairs(hg.achievements.achievements_data.created_achevements) do
            local bbb = createButton_2(self.scroll, ach, ach.name, function()
                self.DetailRevealStart = CurTime()
            end)
            self.scroll:AddItem(bbb)
            firstAch = firstAch or ach
            if selectedKey and ach.key == selectedKey then
                curent_panel_ach = ach
            end
        end

        curent_panel_ach = curent_panel_ach or firstAch
        self.DetailRevealStart = CurTime()
    end

    frame:UpdateValues()

    local frame2 = vgui.Create("DPanel", ParentPanel)
    frame2:SetSize(ParentPanel:GetWide() / 2, ScreenScale(22) * 8.25 + ScreenScale(2.5))
    frame2.TargetY = ParentPanel:GetTall() / 2 - frame2:GetTall() / 2
    frame2.TargetX = frame.TargetX + frame:GetWide()
    frame2:SetPos(frame2.TargetX + MenuUnit(120), frame2.TargetY)
    frame2:SetAlpha(0)
    frame2.Think = function(self)
        local x, y = self:GetPos()
        self.TargetX = frame.TargetX + frame:GetWide()
        self:SetPos(Lerp(FrameTime() * 3.5, x, self.TargetX), Lerp(FrameTime() * 3.5, y, self.TargetY))
        self:SetAlpha(Lerp(FrameTime() * 4.5, self:GetAlpha(), 255))
    end
    frame2.Paint = function(self, w, h)
        PaintGrayBox(w, h, ach_color_bg, ach_color_outline)

        surface.SetDrawColor(255, 255, 255, 18)
        surface.SetTexture(ach_tex_gradient_d)
        surface.DrawTexturedRect(0, math.floor(h * 0.45), w, math.ceil(h * 0.55))
        surface.SetDrawColor(255, 255, 255, 24)
        surface.SetTexture(ach_tex_gradient_d)
        surface.DrawTexturedRect(0, math.floor(h * 0.62), w, math.ceil(h * 0.38))
        surface.SetDrawColor(255, 255, 255, 90)
        surface.DrawRect(0, h - 2, w, 2)

        if curent_panel_ach then
            self.DetailRevealStart = frame.DetailRevealStart or self.DetailRevealStart or CurTime()
            local iconSize = w / 5
            local iconX = w / 2 - iconSize / 2
            local iconY = h * 0.18
            local lineY = h - h / 4.5

            surface.SetDrawColor(255, 255, 255, 255)
            surface.SetMaterial(curent_panel_ach.img)
            surface.DrawTexturedRect(iconX, iconY, iconSize, iconSize)

            surface.SetDrawColor(255, 255, 255, 90)
            surface.DrawRect(MenuUnit(14), lineY, w - MenuUnit(28), 1)

            surface.SetFont("HG_Achievement_Medium")
            local name = string.upper(curent_panel_ach.name or "")
            local res = BuildMaskedText(name, self.DetailRevealStart, 18)
            local wt, ht = surface.GetTextSize(res)
            surface.SetTextColor(ach_color_text)
            surface.SetTextPos(w / 2 - wt / 2, lineY + MenuUnit(10))
            surface.DrawText(res)

            surface.SetFont("HG_Achievement_Tiny")
            local desc = string.Replace(curent_panel_ach.description or "", "\\n", "\n")
            local res2 = BuildMaskedText(desc, self.DetailRevealStart + 0.1, 28)
            local lines = string.Explode("\n", res2)
            surface.SetTextColor(ach_color_text_dim)
            local lineHeight = math.max(ht / 2, MenuUnit(12))
            for i, line in ipairs(lines) do
                local lineW = surface.GetTextSize(line)
                surface.SetTextPos(w / 2 - lineW / 2, lineY + MenuUnit(34) + (i - 1) * lineHeight)
                surface.DrawText(line)
            end
        end
    end

    local backBtn = vgui.Create("DButton", ParentPanel)
    backBtn:SetFont("HG_Achievement_Medium")
    backBtn:SetText("")
    backBtn:SetMouseInputEnabled(true)
    backBtn:SetCursor("hand")
    backBtn.TargetX = MenuUnit(15)
    backBtn.TargetY = ParentPanel:GetTall() - MenuUnit(62)
    backBtn:SetSize(math.max(MenuUnit(180), frame:GetWide() - MenuUnit(30)), MenuUnit(42))
    backBtn:SetPos(backBtn.TargetX, backBtn.TargetY + MenuUnit(48))
    backBtn:SetAlpha(0)
    backBtn:MoveToFront()
    backBtn.OpenTime = CurTime()
    backBtn.HoverLerp = 0

    function backBtn:DoClick()
        if not IsValid(ParentPanel) then return end

        local luaMenu = ParentPanel:GetParent()
        ParentPanel:AlphaTo(0, 0.2, 0, function()
            if IsValid(ParentPanel) then ParentPanel:Remove() end
        end)

        if not IsValid(luaMenu) then return end

        for _, child in ipairs(luaMenu:GetChildren()) do
            if child ~= ParentPanel then
                child:SetVisible(true)
                child:AlphaTo(255, 0.2, 0)
            end
        end

        if luaMenu.panelparrent then
            luaMenu.panelparrent = vgui.Create("DPanel", luaMenu)
            luaMenu.panelparrent:SetPos(0, 0)
            luaMenu.panelparrent:SetSize(ScrW(), ScrH())
            luaMenu.panelparrent:MoveToFront()
            luaMenu.panelparrent:SetMouseInputEnabled(false)
            luaMenu.panelparrent.Paint = function() end
        end

        if luaMenu.ResetCurrentPanel then
            luaMenu:ResetCurrentPanel()
        else
            ParentPanel:Remove()
        end
    end

    function backBtn:Think()
        local isHovered = self:IsHovered()
        self.HoverLerp = LerpFT(0.2, self.HoverLerp or 0, isHovered and 1 or 0)
        local x, y = self:GetPos()
        self:SetPos(Lerp(FrameTime() * 3.5, x, self.TargetX), Lerp(FrameTime() * 3.5, y, self.TargetY))
        self:SetAlpha(Lerp(FrameTime() * 4.5, self:GetAlpha(), 255))
    end

    function backBtn:Paint(w, h)
        local flash = self:IsHovered() and (0.5 + 0.5 * math.sin(CurTime() * 10)) or 0
        local label = BuildMaskedText("<- Return", self.OpenTime, 15)
        local textColor = ach_color_text
        local outlineColor = Color(0, 0, 0, 255)

        if self:IsHovered() then
            local v = flash * 255
            textColor = Color(v, v, v, 255)
            outlineColor = Color(255 - v, 255 - v, 255 - v, 255)
        end

        surface.SetFont(self:GetFont())
        draw.SimpleTextOutlined(label, self:GetFont(), 0, h / 2, textColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER, 1, outlineColor)
        return true
    end
end

local time_wait = 0
function hg.achievements.LoadAchievements()
    if time_wait > CurTime() then return end
    time_wait = CurTime() + 2

    net.Start("req_ach")
    net.SendToServer()
end

function hg.achievements.GetLocalAchievements()
    return hg.achievements.achievements_data.player_achievements[tostring(LocalPlayer():SteamID())]
end

net.Receive("req_ach", function()
    hg.achievements.achievements_data.created_achevements = net.ReadTable()
    hg.achievements.achievements_data.player_achievements[tostring(LocalPlayer():SteamID())] = net.ReadTable()

    if IsValid(hg.achievements.MenuPanel) then
        hg.achievements.MenuPanel:UpdateValues()
    end
end)

hg.achievements.NewAchievements = hg.achievements.NewAchievements or {}
local AchTable = hg.achievements.NewAchievements
net.Receive("hg_NewAchievement", function()
    local Ach = {time = CurTime() + 7.5, name = net.ReadString(), img = net.ReadString()}
    table.insert(AchTable, 1, Ach)
    surface.PlaySound("homigrad/vgui/achievement_earned.wav")
end)

local ach_clr1, ach_clr2 = Color(170, 170, 170), Color(70, 70, 78)
hook.Add("HUDPaint", "hg_NewAchievement", function()
    local frametime = FrameTime() * 10
    for i = 1, #AchTable do
        local ach = AchTable[i]
        if not ach then continue end

        local txt = "Achievement! " .. ach.name
        ach.img = isstring(ach.img) and Material(ach.img) or ach.img
        local wt, _ = surface.GetTextSize(txt)

        ach.Lerp = Lerp(frametime, ach.Lerp or 0, math.min(ach.time - CurTime(), 1) * i)
        WSize, HSize = (ScrW() * 0.1) + wt, ScrH() * 0.05
        local HPos = ScrH() - (HSize * ach.Lerp)
        draw.RoundedBox(0, 2, HPos + 2, WSize - 4, HSize - 4, ach_clr2)

        surface.SetDrawColor(255, 255, 255, 40)
        surface.SetMaterial(gradient_u)
        surface.DrawTexturedRect(0, HPos, WSize, HSize)

        surface.SetDrawColor(255, 255, 255, 180)
        surface.DrawOutlinedRect(0, HPos, WSize, HSize, 2.5)

        surface.SetFont("HomigradFontMedium")
        surface.SetTextColor(255, 255, 255)
        surface.SetTextPos(HSize * 1.25, (HPos + (HSize / 2) - (HSize / 4)))
        surface.DrawText(txt)
        surface.SetDrawColor(255, 255, 255)
        surface.SetMaterial(ach.img)
        surface.DrawTexturedRect(2, HPos + 2, HSize - 4, HSize - 4)

        if ach.time < CurTime() then
            table.remove(AchTable, i)
        end
    end
end)
