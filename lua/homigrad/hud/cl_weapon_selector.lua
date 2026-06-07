hg = hg or {}
hg.WeaponSelector = hg.WeaponSelector or {}
local WS = hg.WeaponSelector

function WS.GetPrintName( self )
	local class = self:GetClass()
	local phrase = language.GetPhrase(class)
	return phrase ~= class and phrase or self:GetPrintName()
end

WS.Show = 0
WS.Transparent = 0
WS.LastSelectedSlot = 0
WS.LastSelectedSlotPos = 0

WS.SelectedSlot = 0
WS.SelectedSlotPos = 0

WS.HighlightProgress = WS.HighlightProgress or {}
WS.StackProgress = WS.StackProgress or {}
WS.StackState = WS.StackState or {}

local WS_OutlineColor = Color(255, 255, 255)
local WS_OutlineBlinkSpeed = 1.5
local WS_OutlineBlinkMin = 80
local WS_OutlineBlinkMax = 220
local WS_SwitchAnimSpeed = 0.25
local WS_FadeSpeed = 0.2
local WS_CarouselSpeed = 0.35
local WS_GradientAlpha = 25
local WS_CardWidth = 0.12
local WS_CardHeight = 0.17
local WS_CardSpacing = 0.12
local WS_CardYOffset = 0.05
local WS_CardDepthYOffset = 0.035
local WS_CardSideScale = 0.78
local WS_CardFarScale = 0.62
local WS_CardSideAlpha = 0.45
local WS_CardFarAlpha = 0.22
local WS_CardNumberY = 0.035
local WS_CardNameY = 0.13
local WS_CardIconY = 0.35
local WS_CardIconBottom = 0.03
local WS_IconSwingAngle = 21
local WS_IconSwingSpeed = 1.5
local WS_IconSwingLerp = 0.18
local WS_StackTextY = 0.02
local WS_StackTextAlpha = 0.8
local WS_StackMax = 3
local WS_StackOffsetY = 0.016
local WS_StackInset = 0.035
local WS_StackAlpha = 0.42
local WS_StackAnimTime = 0.32
local WS_StackFadeSplit = 0.55
local WS_StackRise = 0.03

function WS.DrawText(text, font, posX, posY, color, textAlign)
    local alpha = color.a or 255
    draw.DrawText( text, font, posX + 2, posY + 2, ColorAlpha(color_black, alpha), textAlign )
    draw.DrawText( text, font, posX, posY, ColorAlpha(color, alpha), textAlign )
end

function WS.GetSelectedWeapon()
    if not IsValid( LocalPlayer() ) or not LocalPlayer():Alive() then return end
    local Weapons = WS.GetWeaponTable( LocalPlayer() )
    return Weapons[WS.SelectedSlot] and Weapons[WS.SelectedSlot][WS.SelectedSlotPos] or Weapons[WS.LastSelectedSlot][WS.LastSelectedSlotPos] or Weapons[0][0]
end

function WS.GetWeaponTable( ply )
    if not IsValid( ply ) or not ply:Alive() then return end
    local WeaponsGet = ply:GetWeapons()
    local FormatedTable = {
        [0] = {}, [1] = {}, [2] = {}, [3] = {}, [4] = {}, [5] = {},
    }

    table.sort(WeaponsGet, function(a, b) return (a.SlotPos or 0) > (b.SlotPos or 0) end)

    for k,wep in ipairs(WeaponsGet) do
        local tTbl = FormatedTable[wep.Slot or 0]
        local iMinPos = math.min( (wep.SlotPos and wep.SlotPos) or 1, ((#tTbl or 0) + 1)) - 1
        local iPos = tTbl[ iMinPos ] and #tTbl + 1 or iMinPos
        tTbl[ iPos ] = wep
    end
    return FormatedTable
end

local scrW, scrH = ScrW(), ScrH()

local gradient_u = Material("vgui/gradient-d")

local function WS_GetOrderedSlotWeapons(slotTbl, slotID, activeWep, selectedWep)
    local ordered = {}
    local added = {}

    local function addWeapon(wep)
        if not IsValid(wep) or added[wep] then return end
        ordered[#ordered + 1] = wep
        added[wep] = true
    end

    if slotID == WS.SelectedSlot then
        addWeapon(selectedWep)
    end

    if IsValid(activeWep) and (activeWep.Slot or 0) == slotID then
        addWeapon(activeWep)
    end

    for i = 0, #slotTbl do
        addWeapon(slotTbl[i])
    end

    return ordered
end

local function WS_CopyWeaponList(list)
    local copied = {}

    for i, wep in ipairs(list) do
        copied[i] = wep
    end

    return copied
end

local function WS_GetWeaponIndex(list, wep)
    if not IsValid(wep) then return end

    for i, testWep in ipairs(list or {}) do
        if testWep == wep then
            return i
        end
    end
end

local function WS_GetStackSignature(list)
    local parts = {}

    for i, wep in ipairs(list) do
        parts[i] = IsValid(wep) and wep:EntIndex() or 0
    end

    return table.concat(parts, ":")
end

local function WS_GetStackState(slotID, stack)
    local signature = WS_GetStackSignature(stack)
    local state = WS.StackState[slotID]

    if not state then
        state = {
            signature = signature,
            from = WS_CopyWeaponList(stack),
            to = WS_CopyWeaponList(stack),
            start = CurTime() - WS_StackAnimTime
        }
        WS.StackState[slotID] = state
    elseif state.signature ~= signature then
        state.signature = signature
        state.from = WS_CopyWeaponList(state.to or stack)
        state.to = WS_CopyWeaponList(stack)
        state.start = CurTime()
    end

    local raw = math.Clamp((CurTime() - state.start) / WS_StackAnimTime, 0, 1)
    local eased = 1 - (1 - raw) ^ 3

    if raw >= 1 then
        state.from = WS_CopyWeaponList(state.to)
    end

    return state, raw, eased
end

local function WS_GetStackRect(posX, posY, width, height, scale, appear, layer)
    local inset = width * WS_StackInset * layer
    local offsetY = scrH * WS_StackOffsetY * scale * layer * appear

    return posX + inset, posY + offsetY, math.max(width - inset * 2, 1), math.max(height - offsetY * 0.35, 1)
end

local function WS_DrawStackBox(x, y, w, h, alpha)
    if alpha <= 0 then return end

    draw.RoundedBox(0, x, y, w, h, ColorAlpha(color_black, alpha))
    surface.SetDrawColor(WS_OutlineColor.r, WS_OutlineColor.g, WS_OutlineColor.b, alpha * 0.45)
    surface.DrawOutlinedRect(x, y, w, h, 1)
end

local function WS_DrawWeaponIcon(wep, x, y, w, h, alpha, angle)
    if h <= 0 then return end

    local drawX = x
    local drawY = y
    local drawW = w
    local drawH = h
    local useFilter = false

    surface.SetDrawColor(255, 255, 255, alpha)

    if wep.IconOverride and wep.IconOverride ~= "" and wep.WepSelectIcon2 then
        useFilter = true
        surface.SetMaterial(wep.WepSelectIcon2)
        if wep.WepSelectIcon2box then
            drawW = w / 1.95
            drawH = drawW
            drawX = x + w * 0.5 - drawW * 0.5
            drawY = y
        else
            drawW = w
            drawH = w / 2
        end
    elseif isnumber(wep.WepSelectIcon) then
        surface.SetTexture(wep.WepSelectIcon)
        drawX = x + 10
        drawY = y + 10
        drawW = math.max(w - 20, 1)
        drawH = drawW / 2
    elseif wep.WepSelectIcon then
        surface.SetMaterial(wep.WepSelectIcon)
        drawX = x + 10
        drawY = y + 10
        drawW = math.max(w - 20, 1)
        drawH = drawW / 2
    elseif wep.DrawWeaponSelection then
        wep:DrawWeaponSelection(x, y, w, h, alpha)
        return
    else
        return
    end

    if useFilter then
        render.PushFilterMag(TEXFILTER.ANISOTROPIC)
        render.PushFilterMin(TEXFILTER.ANISOTROPIC)
    end

    surface.DrawTexturedRectRotated(drawX + drawW * 0.5, drawY + drawH * 0.5, drawW, drawH, angle)

    if useFilter then
        render.PopFilterMin()
        render.PopFilterMag()
    end
end

function WS.WeaponSelectorDraw( ply )
    if not IsValid( ply ) or not ply:Alive() or GetGlobalBool("RadialInventory", false) then return end
    if WS.Show < CurTime() then
        WS.SelectedSlot = WS.LastSelectedSlot
        WS.SelectedSlotPos = -1

        return
    end
    local Weapons = WS.GetWeaponTable( ply )
    local SelectedWep = WS.GetSelectedWeapon()
    local ActiveWep = ply:GetActiveWeapon()
    if not IsValid(SelectedWep) then return end
    WS.Transparent = LerpFT( WS_FadeSpeed, WS.Transparent, math.min( WS.Show - CurTime(), 1 ) )
    local visibleSlots = {}
    local targetIndex = 1

    for i = 0, #Weapons do
        local slotTbl = Weapons[i]
        if table.Count(slotTbl) < 1 then continue end
        local orderedWeapons = WS_GetOrderedSlotWeapons(slotTbl, i, ActiveWep, SelectedWep)
        local displayWep = orderedWeapons[1]
        if not IsValid(displayWep) then continue end
        visibleSlots[#visibleSlots + 1] = {
            slot = i,
            wep = displayWep,
            stack = orderedWeapons
        }
        if i == WS.SelectedSlot then
            targetIndex = #visibleSlots
        end
    end

    if #visibleSlots < 1 then return end

    WS.CarouselPos = WS.CarouselPos or targetIndex
    WS.CarouselPos = LerpFT( WS_CarouselSpeed, WS.CarouselPos, targetIndex )

    local blinkAlpha = Lerp( WS_OutlineBlinkMin / 255, WS_OutlineBlinkMax / 255, (math.sin( CurTime() * WS_OutlineBlinkSpeed ) + 1) / 2 )
    local appear = 1 - (1 - math.Clamp(WS.Transparent, 0, 1)) ^ 3
    local cards = {}

    for idx, data in ipairs(visibleSlots) do
        local offset = idx - WS.CarouselPos
        if math.abs(offset) > 2.25 then continue end
        cards[#cards + 1] = {
            offset = offset,
            slot = data.slot,
            wep = data.wep,
            stack = data.stack
        }
    end

    table.sort(cards, function(a, b)
        return math.abs(a.offset) > math.abs(b.offset)
    end)

    for _, data in ipairs(cards) do
        local depth = math.abs(data.offset)
        local sideLerp = math.min(depth, 1)
        local farLerp = math.min(math.max(depth - 1, 0), 1)
        local scale
        local alphaMul

        if depth <= 1 then
            scale = Lerp(sideLerp, 1, WS_CardSideScale)
            alphaMul = Lerp(sideLerp, 1, WS_CardSideAlpha)
        else
            scale = Lerp(farLerp, WS_CardSideScale, WS_CardFarScale)
            alphaMul = Lerp(farLerp, WS_CardSideAlpha, WS_CardFarAlpha)
        end

        local width = scrW * WS_CardWidth * scale * appear
        local height = scrH * WS_CardHeight * scale * appear
        local centerX = scrW * 0.5 + data.offset * scrW * WS_CardSpacing * appear
        local posX = centerX - width * 0.5
        local posY = scrH * WS_CardYOffset + depth * scrH * WS_CardDepthYOffset + (1 - appear) * scrH * 0.03
        local baseAlpha = WS.Transparent * 255 * alphaMul
        local stackTotal = math.max(#data.stack - 1, 0)
        local stackCount = math.min(stackTotal, WS_StackMax)
        local state, stackRaw, stackEase = WS_GetStackState(data.slot, data.stack)
        local oldTop = state.from[1]
        local newTop = state.to[1]
        local mainX, mainY, mainW, mainH = posX, posY, width, height

        WS.StackProgress[data.slot] = WS.StackProgress[data.slot] or 0
        WS.StackProgress[data.slot] = LerpFT(WS_SwitchAnimSpeed, WS.StackProgress[data.slot], stackCount)

        local currentTopPrevIndex = WS_GetWeaponIndex(state.from, newTop)
        if currentTopPrevIndex and currentTopPrevIndex > 1 and stackRaw < 1 then
            local fromLayer = math.min(currentTopPrevIndex - 1, WS_StackMax)
            local fromX, fromY, fromW, fromH = WS_GetStackRect(posX, posY, width, height, scale, appear, fromLayer)
            mainX = Lerp(stackEase, fromX, posX)
            mainY = Lerp(stackEase, fromY, posY)
            mainW = Lerp(stackEase, fromW, width)
            mainH = Lerp(stackEase, fromH, height)
        end

        for layer = WS_StackMax, 1, -1 do
            local targetIndex = layer + 1
            local targetWep = data.stack[targetIndex]
            local showFrac = math.Clamp(WS.StackProgress[data.slot] - (layer - 1), 0, 1)

            if not IsValid(targetWep) or showFrac <= 0 then continue end
            if stackRaw < 1 and oldTop == targetWep and oldTop ~= newTop then continue end

            local targetX, targetY, targetW, targetH = WS_GetStackRect(posX, posY, width, height, scale, appear, layer)
            local prevIndex = WS_GetWeaponIndex(state.from, targetWep)
            local drawX, drawY, drawW, drawH = targetX, targetY, targetW, targetH
            local alphaFrac = showFrac

            if prevIndex and prevIndex > 1 and stackRaw < 1 then
                local fromLayer = math.min(prevIndex - 1, WS_StackMax)
                local fromX, fromY, fromW, fromH = WS_GetStackRect(posX, posY, width, height, scale, appear, fromLayer)
                drawX = Lerp(stackEase, fromX, targetX)
                drawY = Lerp(stackEase, fromY, targetY)
                drawW = Lerp(stackEase, fromW, targetW)
                drawH = Lerp(stackEase, fromH, targetH)
            elseif (not prevIndex or prevIndex == 1) and stackRaw < 1 then
                local fadeIn = math.max((stackRaw - WS_StackFadeSplit) / (1 - WS_StackFadeSplit), 0)
                alphaFrac = alphaFrac * fadeIn
            end

            local layerAlpha = baseAlpha * WS_StackAlpha * (1 - (layer - 1) * 0.14) * alphaFrac
            WS_DrawStackBox(drawX, drawY, drawW, drawH, layerAlpha)
        end

        if stackRaw < 1 and IsValid(oldTop) and oldTop ~= newTop then
            local oldTargetIndex = WS_GetWeaponIndex(data.stack, oldTop)

            if stackRaw < WS_StackFadeSplit then
                local ghostFrac = stackRaw / WS_StackFadeSplit
                local ghostY = posY - scrH * WS_StackRise * scale * ghostFrac
                local ghostW = Lerp(ghostFrac, width, width * 0.94)
                local ghostH = Lerp(ghostFrac, height, height * 0.94)
                local ghostX = posX + (width - ghostW) * 0.5
                local ghostAlpha = baseAlpha * (1 - ghostFrac)
                WS_DrawStackBox(ghostX, ghostY, ghostW, ghostH, ghostAlpha * 0.8)
            elseif oldTargetIndex and oldTargetIndex > 1 then
                local settleFrac = (stackRaw - WS_StackFadeSplit) / (1 - WS_StackFadeSplit)
                local targetLayer = math.min(oldTargetIndex - 1, WS_StackMax)
                local targetX, targetY, targetW, targetH = WS_GetStackRect(posX, posY, width, height, scale, appear, targetLayer)
                local startY = targetY - scrH * WS_StackRise * scale * 0.5
                local ghostAlpha = baseAlpha * WS_StackAlpha * (1 - (targetLayer - 1) * 0.14) * settleFrac
                WS_DrawStackBox(targetX, Lerp(settleFrac, startY, targetY), targetW, targetH, ghostAlpha)
            end
        end

        local outlineAlpha = data.slot == WS.SelectedSlot and baseAlpha * blinkAlpha or baseAlpha * 0.5
        local textAlpha = data.slot == WS.SelectedSlot and baseAlpha or baseAlpha * 0.9
        local slotY = mainY + mainH * WS_CardNumberY
        local nameY = mainY + mainH * WS_CardNameY
        local iconY = mainY + mainH * WS_CardIconY
        local iconH = math.max(mainH - mainH * WS_CardIconBottom - (iconY - mainY), 0)
        WS.HighlightProgress[data.slot] = WS.HighlightProgress[data.slot] or 0
        WS.HighlightProgress[data.slot] = LerpFT(WS_IconSwingLerp, WS.HighlightProgress[data.slot], data.slot == WS.SelectedSlot and 1 or 0)
        local iconAngle = math.sin(CurTime() * WS_IconSwingSpeed) * WS_IconSwingAngle * WS.HighlightProgress[data.slot]

        draw.RoundedBox(0, mainX, mainY, mainW, mainH, ColorAlpha(color_black, baseAlpha * 0.9))
        surface.SetDrawColor(255, 255, 255, baseAlpha * WS_GradientAlpha / 255)
        surface.SetMaterial(gradient_u)
        surface.DrawTexturedRect(mainX, mainY, mainW, mainH)
        surface.SetDrawColor(WS_OutlineColor.r, WS_OutlineColor.g, WS_OutlineColor.b, outlineAlpha)
        surface.DrawOutlinedRect(mainX, mainY, mainW, mainH, 1)

        WS.DrawText(data.slot + 1, "HomigradFontSmall", mainX + mainW * 0.5, slotY, ColorAlpha(color_white, textAlpha), TEXT_ALIGN_CENTER)
        WS.DrawText(WS.GetPrintName(data.wep), "HomigradFontSmall", mainX + mainW * 0.5, nameY, ColorAlpha(color_white, textAlpha), TEXT_ALIGN_CENTER)

        if stackTotal > 0 then
            local moreY = mainY + mainH + scrH * WS_StackTextY
            local moreAlpha = textAlpha * WS_StackTextAlpha * math.min(WS.StackProgress[data.slot], 1)
            WS.DrawText("+" .. stackTotal .. " more", "HomigradFontSmall", mainX + mainW * 0.5, moreY, ColorAlpha(color_white, moreAlpha), TEXT_ALIGN_CENTER)
        end

        WS_DrawWeaponIcon(data.wep, mainX + 6, iconY, mainW - 12, iconH, baseAlpha, iconAngle)
    end
end

-- Changer
local tAcceptKeys = {
    ["slot1"] = 1,
    ["slot2"] = 2,
    ["slot3"] = 3,
    ["slot4"] = 4,
    ["slot5"] = 5,
    ["slot6"] = 6,
}

--[[
    Table:
        [1]	=	Weapon [52][weapon_hands_sh]
        [2]	=	Weapon [117][weapon_bigconsumable]
        [3]	=	Weapon [121][weapon_handcuffs_key]
        [4]	=	Weapon [122][weapon_handcuffs]
        [5]	=	Weapon [123][weapon_traitor_poison1]
        [6]	=	Weapon [124][weapon_traitor_suit]
        [7]	=	Weapon [125][weapon_matches]

    TableFormated:
    [0]:
		[0]	=	Weapon [126][weapon_physgun]
		[1]	=	Weapon [52][weapon_hands_sh]
    [1]:
    [2]:
    [3]:
		[1]	=	Weapon [117][weapon_bigconsumable]
		[2]	=	Weapon [121][weapon_handcuffs_key]
		[3]	=	Weapon [122][weapon_handcuffs]
		[4]	=	Weapon [123][weapon_traitor_poison1]
		[5]	=	Weapon [125][weapon_matches]
    [4]:
    [5]:
		[1]	=	Weapon [124][weapon_traitor_suit]
--]]

local function GetUpper(Weapons)
    if #LocalPlayer():GetWeapons() < 1 then return end
    WS.SelectedSlot = WS.SelectedSlot < 0 and #Weapons or WS.SelectedSlot - 1
    WS.SelectedSlotPos = Weapons[WS.SelectedSlot] and #Weapons[WS.SelectedSlot] or 0

    --print(WS.SelectedSlot, WS.SelectedSlotPos)

    if Weapons[WS.SelectedSlot] == nil or Weapons[WS.SelectedSlot][WS.SelectedSlotPos] == nil then
        GetUpper(Weapons)
    end
end

local function GetDown(Weapons)
    if #LocalPlayer():GetWeapons() < 1 then return end
    WS.SelectedSlot = WS.SelectedSlot > #Weapons and 0 or WS.SelectedSlot + 1
    WS.SelectedSlotPos = 0

    --print(WS.SelectedSlot, WS.SelectedSlotPos)

    if Weapons[WS.SelectedSlot] == nil or Weapons[WS.SelectedSlot][WS.SelectedSlotPos] == nil then
        GetDown(Weapons)
    end
end

local LastSelected = 0

local function get_active_tool(ply, tool)
    local activeWep = ply:GetActiveWeapon()
    if not IsValid(activeWep) or activeWep:GetClass() ~= "gmod_tool" or activeWep.Mode ~= tool then return end
    return activeWep:GetToolObject(tool)
end

local function canUseSelector(ply)
    local wep = ply:GetActiveWeapon()
    local tool = get_active_tool(ply, "submaterial")
    if tool and IsValid(ply:GetEyeTraceNoCursor().Entity) then
        return true
    end

    return IsAiming(ply) or (IsValid(wep) and wep:GetClass() == "weapon_physgun" and ply:KeyDown(IN_ATTACK)) or (lply.organism and lply.organism.pain and lply.organism.pain > 100) or GetGlobalBool("RadialInventory", false)
end

function WS.ChangeSelectionWep( ply, key )
    if not IsValid( ply ) or not ply:Alive() or GetGlobalBool("RadialInventory", false) then return end
    if ply.organism and ply.organism.otrub then return end
    if canUseSelector( ply ) then return end
    --print(canUseSelector( ply ))
    --print("Table")
    --PrintTable( WS.GetWeaponTable( ply ) )
    local iPos = tAcceptKeys[ key ]
    if iPos or key == "invnext" or key == "invprev" or key == "lastinv" then

        local Weapons = WS.GetWeaponTable( ply )

        WS.Show = CurTime() + 4
        --print(key)
        surface.PlaySound("arc9_eft_shared/weapon_generic_rifle_spin"..math.random(10)..".ogg")
        if iPos then
            iPos = iPos - 1
            if LastSelected ~= iPos then
                WS.SelectedSlotPos = -1
            end
            WS.SelectedSlotPos = (Weapons[iPos] and LastSelected == iPos and WS.SelectedSlotPos + 1 > #Weapons[iPos] and 0 or math.min( WS.SelectedSlotPos + 1, #Weapons[iPos] )) or 0
            WS.SelectedSlot = iPos
            LastSelected = iPos
            --print(WS.SelectedSlotPos)
            --print(iPos)
            --print( Weapons[WS.SelectedSlot][WS.SelectedSlotPos] )
        elseif key == "invprev" then
            WS.SelectedSlotPos = WS.SelectedSlotPos - 1
            --print(WS.SelectedSlotPos)
            if Weapons[WS.SelectedSlot] and WS.SelectedSlotPos < 0  then
                GetUpper(Weapons)
            end
            --WS.SelectedSlot = Weapons[WS.SelectedSlot] and #Weapons[WS.SelectedSlot] > (WS.SelectedSlotPos + 1) and WS.SelectedSlot + 1 or WS.SelectedSlot + 1 > #Weapons - 1 and 0 or 0
        elseif key == "invnext" then
            WS.SelectedSlotPos = WS.SelectedSlotPos + 1
            --print(WS.SelectedSlotPos)
            if Weapons[WS.SelectedSlot] and WS.SelectedSlotPos > #Weapons[WS.SelectedSlot] then
                GetDown(Weapons)
            end
        elseif key == "lastinv" and IsValid(WS.LastInv) then
            WS.Show = 0
            WS.LastInv = WS.LastInv or "weapon_hands_sh"
            local oldwep = ply:GetActiveWeapon()
            input.SelectWeapon( WS.LastInv )
            WS.LastInv = oldwep
        end

    end
end

function WS.SetActuallyWeapon( ply, cmd )
    if not IsValid( ply ) or not ply:Alive() or GetGlobalBool("RadialInventory", false) then return end
    if (cmd:KeyDown( IN_ATTACK ) or cmd:KeyDown( IN_ATTACK2 )) and WS.Show > CurTime() then

        if WS.Selected and WS.Selected > CurTime() then
            cmd:RemoveKey(IN_ATTACK)
            cmd:RemoveKey(IN_ATTACK2)
        else
            cmd:RemoveKey(IN_ATTACK)
            cmd:RemoveKey(IN_ATTACK2)
            --print(WS.GetSelectedWeapon())

            if IsValid(WS.GetSelectedWeapon()) then
                WS.LastInv = WS.LastInv ~= ply:GetActiveWeapon() and WS.LastInv or ply:GetActiveWeapon()
                input.SelectWeapon( WS.GetSelectedWeapon() )
            end
            cmd:RemoveKey(IN_ATTACK)
            cmd:RemoveKey(IN_ATTACK2)

            WS.LastSelectedSlot = WS.SelectedSlot
            WS.LastSelectedSlotPos = WS.SelectedSlotPos
            WS.Selected = CurTime() + 0.2
            WS.Show = CurTime() + 0.2
            surface.PlaySound("arc9_eft_shared/weapon_generic_spin"..math.random(1,10)..".ogg")
        end
    end
end

hook.Add( "PlayerBindPress", "WeaponSelector_PlayerBindPress", WS.ChangeSelectionWep )

hook.Add( "HUDPaint", "WeaponSelector_Draw", function()
    WS.WeaponSelectorDraw( LocalPlayer() )
end)

hook.Add( "StartCommand", "WeaponSelector_StartCommand", WS.SetActuallyWeapon )

local tHideElements = {
    ["CHudWeaponSelection"] = true
}

hook.Add("HUDShouldDraw", "WeaponSelector_HUDShouldDraw", function(sElementName)
    if tHideElements[sElementName] then return false end
end)

-- Я ТАК ЗАДОЛБАЛСЯ ПРОСТО УБЕЙТЕ МЕНЯ ХАХАХАХАХАХАХАХАХАХААХАХАХАХАХАХА
-- ПОЛЧАСА Я ПЫТАЛСЯ СДЕЛАТЬ НОРМЛАЬНОЕ ПЕРЕКЛЮЧЕНИЕ ГОВНА!!!
-- ЗАТО ПОЛУЧИЛОСЬ!!!!
-- УЭЭЭЭЭЭЭЭЭЭЭЭЭЭЭЭЭЭЭЭЭЭЭЭЭЭЭЭЭЭЭЭЭЭЭЭЭЭЭЭЭЭЭЭЭ
--[[
    /\_/\
    |_ _|
    |   |__
   /_|_____\ -- IT'S SO OVER
--]]
