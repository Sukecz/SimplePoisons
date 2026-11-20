local addonName, ns = ...

local Buttons = {}
ns.Buttons = Buttons

local C = ns.Constants
local TEXT_COLOR = { 1, 0.82, 0 }
local ASSET_PATH = "Interface\\AddOns\\" .. addonName .. "\\assets\\"
local STONE_BAR_WIDTH = 38
local STONE_BAR_HEIGHT = 8

local function applyFontStyle(fontString, size)
    local font, _, flags = fontString:GetFont()
    if font then
        fontString:SetFont(font, size, flags)
    end
    fontString:SetTextColor(unpack(TEXT_COLOR))
end

local function setBackdrop(frame, borderColor, backgroundColor)
    if type(frame.SetBackdrop) ~= "function" then
        return
    end
    if not frame.simplePoisonsBackdrop then
        frame:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = false,
            edgeSize = 12,
            insets = { left = 3, right = 3, top = 3, bottom = 3 },
        })
        frame.simplePoisonsBackdrop = true
    end
    frame:SetBackdropColor(unpack(backgroundColor))
    frame:SetBackdropBorderColor(unpack(borderColor))
end

local function setWarning(button, red, green, blue, tintAlpha)
    if not red then
        button.warningTint:Hide()
        button.warningGlow:Hide()
        return
    end
    button.warningTint:SetColorTexture(red, green, blue, tintAlpha)
    button.warningTint:Show()
    button.warningGlow:SetVertexColor(red, green, blue, 1)
    button.warningGlow:SetAlpha(0.95)
    button.warningGlow:Show()
end

local function formatTime(milliseconds)
    local seconds = math.max(0, math.floor((tonumber(milliseconds) or 0) / 1000))
    if seconds >= 3600 then
        return string.format("%dh", math.ceil(seconds / 3600))
    elseif seconds >= 60 then
        return string.format("%dm", math.ceil(seconds / 60))
    end
    return string.format("%ds", seconds)
end

local function formatStoneTime(state)
    if not state.hasExpirationTime then return ns.L.NO_EXPIRATION end
    local seconds = math.max(0, math.floor(state.expirationMS / 1000))
    local time = string.format("%d:%02d", math.floor(seconds / 60), seconds % 60)
    return string.format(ns.L.TIME_LEFT, time)
end

function Buttons:UpdateButtonOpacity(button)
    local dimmed = not button.preview and button.healthyPoison and not button.stoneLow
        and not button.hovered and not self.unlocked
    button.visual:SetAlpha(dimmed and ns.Database:Get("healthyPoisonOpacity") / 100 or 1)
end

local function createArtwork(button)
    -- Fade the artwork independently of the protected button and its hit area.
    local visual = CreateFrame("Frame", nil, button, BackdropTemplateMixin and "BackdropTemplate" or nil)
    visual:SetAllPoints(button)
    visual:SetFrameLevel(button:GetFrameLevel())
    button.visual = visual
    setBackdrop(visual, { 0.28, 0.28, 0.28, 1 }, { 0.02, 0.02, 0.02, 0.92 })

    button.icon = visual:CreateTexture(nil, "ARTWORK")
    button.icon:SetPoint("TOPLEFT", 4, -4)
    button.icon:SetPoint("BOTTOMRIGHT", -4, 4)
    button.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)

    button.warningTint = visual:CreateTexture(nil, "ARTWORK", nil, 1)
    button.warningTint:SetPoint("TOPLEFT", 4, -4)
    button.warningTint:SetPoint("BOTTOMRIGHT", -4, 4)
    button.warningTint:SetBlendMode("ADD")
    button.warningTint:Hide()

    button.warningGlow = visual:CreateTexture(nil, "OVERLAY")
    button.warningGlow:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
    button.warningGlow:SetBlendMode("ADD")
    button.warningGlow:SetSize(76, 76)
    button.warningGlow:SetPoint("CENTER")
    button.warningGlow:Hide()

    button.stoneTrack = visual:CreateTexture(nil, "OVERLAY", nil, 2)
    button.stoneTrack:SetPoint("BOTTOM", button.icon, "BOTTOM", 0, 1)
    button.stoneTrack:SetSize(STONE_BAR_WIDTH, STONE_BAR_HEIGHT)
    button.stoneTrack:Hide()

    button.stoneBar = visual:CreateTexture(nil, "OVERLAY", nil, 3)
    button.stoneBar:SetPoint("BOTTOMLEFT", button.stoneTrack, "BOTTOMLEFT")
    button.stoneBar:SetSize(STONE_BAR_WIDTH, STONE_BAR_HEIGHT)
    button.stoneBar:Hide()

    button.slotText = visual:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    button.slotText:SetPoint("BOTTOMLEFT", button, "TOPLEFT", 2, 2)
    button.slotText:SetText(button.slotLabel)

    button.chargeText = visual:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    button.chargeText:SetPoint("BOTTOMRIGHT", button, "TOPRIGHT", -2, 2)
    button.chargeText:SetJustifyH("RIGHT")

    button.timeText = visual:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    button.timeText:SetPoint("TOP", button, "BOTTOM", 0, -2)
    button.timeText:SetShadowOffset(1, -1)

    button.missingText = visual:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    button.missingText:SetPoint("CENTER", 0, 0)
    button.missingText:SetText(ns.L.MISSING)
    button.missingText:SetTextColor(1, 0.2, 0.2)
    button.missingText:Hide()
end

function Buttons:CreateButton(name, slotID, slotLabel)
    local button = CreateFrame("Button", name, self.anchor, "SecureActionButtonTemplate")
    button:SetSize(C.BUTTON_SIZE, C.BUTTON_SIZE)
    button:RegisterForClicks("AnyUp")
    button.slotID = slotID
    button.slotLabel = slotLabel
    button.availableItems = {}
    createArtwork(button)

    button:SetScript("OnEnter", function(self)
        self.hovered = true
        Buttons:UpdateButtonOpacity(self)
        Buttons:ShowTooltip(self)
    end)
    button:SetScript("OnLeave", function(self)
        self.hovered = false
        Buttons:UpdateButtonOpacity(self)
        if GameTooltip then
            GameTooltip:Hide()
        end
    end)
    button:SetScript("OnHide", function(self) self.hovered = false end)
    button:SetScript("PostClick", function(self, mouseButton)
        local bind = ns.Bindings:Current(mouseButton)
        if not self.availableItems[bind] then
            local familyKey = self.boundChoices[bind]
            if familyKey then
                ns.Core:Print(string.format(ns.L.NO_POISON, ns.ApplicationData:GetLabel(familyKey)))
            end
        end
    end)

    return button
end

function Buttons:CreatePreviewButton(parent)
    local button = CreateFrame("Frame", nil, parent)
    button:SetSize(C.BUTTON_SIZE, C.BUTTON_SIZE)
    button:EnableMouse(true)
    button.slotID = C.MAIN_HAND_SLOT
    button.slotLabel = ns.L.MH
    button.preview = true
    createArtwork(button)
    button:SetScript("OnEnter", function(self) Buttons:ShowTooltip(self) end)
    local function hideTooltip(self)
        if GameTooltip and GameTooltip:IsOwned(self) then GameTooltip:Hide() end
    end
    button:SetScript("OnLeave", hideTooltip)
    button:SetScript("OnHide", hideTooltip)
    return button
end

function Buttons:Create()
    if self.anchor then
        return self.anchor
    end

    self.anchor = CreateFrame("Frame", "SimplePoisonsAnchor", UIParent)
    self.anchor:SetMovable(true)
    self.anchor:SetClampedToScreen(true)

    self.mainButton = self:CreateButton(C.SECURE_MAIN_NAME, C.MAIN_HAND_SLOT, ns.L.MH)
    self.offButton = self:CreateButton(C.SECURE_OFF_NAME, C.OFF_HAND_SLOT, ns.L.OH)

    self.settingsButton = CreateFrame("Button", "SimplePoisonsSettingsButton", self.anchor)
    self.settingsButton:SetSize(16, 16)
    self.settingsButton:SetNormalTexture("Interface\\Buttons\\UI-OptionsButton")
    self.settingsButton:SetHighlightTexture("Interface\\Buttons\\UI-OptionsButton")
    self.settingsButton:GetHighlightTexture():SetAlpha(0.35)
    self.settingsButton:SetScript("OnClick", function()
        ns.Options:Open()
    end)
    self.settingsButton:SetScript("OnEnter", function(self)
        if GameTooltip then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(ns.L.SETTINGS, 1, 0.82, 0)
            GameTooltip:Show()
        end
    end)
    self.settingsButton:SetScript("OnLeave", function()
        if GameTooltip then GameTooltip:Hide() end
    end)

    self.moveControls = CreateFrame("Frame", nil, self.anchor)
    self.moveControls:SetSize(150, 24)
    self.moveControls:SetPoint("TOP", self.anchor, "BOTTOM", 0, -21)
    self.moveControls:SetFrameStrata("HIGH")

    self.moveHandle = CreateFrame("Button", nil, self.moveControls,
        BackdropTemplateMixin and "BackdropTemplate" or nil)
    self.moveHandle:SetSize(96, 24)
    self.moveHandle:SetPoint("LEFT")
    self.moveHandle:RegisterForDrag("LeftButton")
    self.moveHandle:EnableMouse(true)
    setBackdrop(self.moveHandle, { 1, 0.82, 0, 1 }, { 0.05, 0.05, 0.05, 0.78 })
    self.moveHandle.text = self.moveHandle:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    self.moveHandle.text:SetPoint("CENTER")
    self.moveHandle.text:SetText(ns.L.MOVE_HELP)
    self.moveHandle:SetScript("OnDragStart", function()
        if not ns.ApiCompat:IsCombatLocked() then
            Buttons.anchor:StartMoving()
            Buttons.moving = true
        end
    end)
    self.moveHandle:SetScript("OnDragStop", function()
        if ns.ApiCompat:IsCombatLocked() then
            Buttons.dragStopPending = true
            return
        end
        Buttons:FinishMoving()
    end)

    self.lockButton = CreateFrame("Button", nil, self.moveControls, "UIPanelButtonTemplate")
    self.lockButton:SetSize(50, 24)
    self.lockButton:SetPoint("LEFT", self.moveHandle, "RIGHT", 4, 0)
    self.lockButton:SetText(ns.L.LOCK_SHORT)
    self.lockButton:SetScript("OnClick", function()
        if Buttons:SetUnlocked(false) then
            ns.Options:Open()
        end
    end)
    self.moveControls:Hide()

    self:ApplyLayout()
    self:ApplyTextStyle()
    self:ApplyPosition()
    self:SetUnlocked(false)
    self:Refresh()
    return self.anchor
end

function Buttons:ApplyLayout()
    if ns.ApiCompat:IsCombatLocked() then
        self.layoutPending = true
        return
    end
    self.layoutPending = false
    if not self.anchor then
        return
    end
    local size = C.BUTTON_SIZE
    local gap = C.BUTTON_GAP
    local textSize = ns.Database:Get("textSize")
    self.mainButton:ClearAllPoints()
    self.offButton:ClearAllPoints()
    self.moveControls:ClearAllPoints()
    self.moveControls:SetPoint("TOP", self.anchor, "BOTTOM", 0, -(textSize + 8))
    self.settingsButton:ClearAllPoints()
    self.settingsButton:SetPoint("LEFT", self.anchor, "RIGHT", 4, 0)
    if ns.Database:Get("showSettingsIcon") then
        self.settingsButton:Show()
    else
        self.settingsButton:Hide()
    end
    local hands = ns.Database:Get("hands")
    if hands == "OFF" then self.mainButton:Hide() else self.mainButton:Show() end
    if hands == "MAIN" then self.offButton:Hide() else self.offButton:Show() end
    if hands == "MAIN" or hands == "OFF" then
        self.anchor:SetSize(size, size)
        local visible = hands == "MAIN" and self.mainButton or self.offButton
        visible:SetPoint("CENTER", self.anchor, "CENTER")
    elseif ns.Database:Get("orientation") == "VERTICAL" then
        local verticalGap = (textSize * 2) + 7
        self.anchor:SetSize(size, (size * 2) + verticalGap)
        self.mainButton:SetPoint("TOP", self.anchor, "TOP")
        self.offButton:SetPoint("TOP", self.mainButton, "BOTTOM", 0, -verticalGap)
    else
        self.anchor:SetSize((size * 2) + gap, size)
        self.mainButton:SetPoint("LEFT", self.anchor, "LEFT")
        self.offButton:SetPoint("LEFT", self.mainButton, "RIGHT", gap, 0)
    end
    self.anchor:SetScale(ns.Database:Get("scale"))
    if self.mainButton.state then self:UpdateTimer() end
end

local function styleButtonText(button)
    local size = ns.Database:Get("textSize")
    button.slotText:SetText(ns.Database:Get("showHandLabels") and button.slotLabel or "")
    applyFontStyle(button.slotText, size)
    applyFontStyle(button.chargeText, size)
    applyFontStyle(button.timeText, size)
end

function Buttons:ApplyTextStyle()
    if ns.ApiCompat:IsCombatLocked() then
        self.textStylePending = true
        return
    end
    self.textStylePending = false
    if not self.mainButton then
        return
    end
    styleButtonText(self.mainButton)
    styleButtonText(self.offButton)
    self:ApplyLayout()
end

function Buttons:ApplyPosition()
    if ns.ApiCompat:IsCombatLocked() then
        self.positionPending = true
        return
    end
    self.positionPending = false
    local position = ns.Database:Get("position")
    self.anchor:ClearAllPoints()
    self.anchor:SetPoint(position.point, UIParent, position.relativePoint, position.x, position.y)
end

function Buttons:FinishMoving()
    if self.moving then
        self.anchor:StopMovingOrSizing()
        self.moving = false
        ns.Database:SavePosition(self.anchor)
    end
    self.dragStopPending = false
end

function Buttons:OnCombatEnded()
    if self.dragStopPending then self:FinishMoving() end
    if self.lockPending then
        self.lockPending = false
        self:SetUnlocked(false)
    end
    if self.textStylePending then
        self:ApplyTextStyle()
    elseif self.layoutPending then
        self:ApplyLayout()
    end
    if self.positionPending then
        self:ApplyPosition()
    end
end

function Buttons:SetUnlocked(unlocked)
    if ns.ApiCompat:IsCombatLocked() then
        ns.Core:Print(ns.L.COMBAT_LOCKED)
        return false
    end
    self.unlocked = unlocked and true or false
    if self.unlocked then
        self.moveControls:Show()
    else
        self:FinishMoving()
        self.moveControls:Hide()
        ns.Database:SavePosition(self.anchor)
    end
    self:UpdateButtonOpacity(self.mainButton)
    self:UpdateButtonOpacity(self.offButton)
    return true
end

function Buttons:ResolveIcon(state, familyKey, slotID)
    if state.hasEnchant then
        if familyKey then
            return ns.PoisonData:GetRepresentativeIcon(familyKey, state.enchantID)
        end
        local stone = ns.SharpeningData:GetByEnchantID(state.enchantID)
        if stone then
            return ns.SharpeningData:GetIcon(stone)
        end
        return ns.ApiCompat:GetWeaponTexture(slotID)
            or "Interface\\Icons\\INV_Misc_QuestionMark"
    end
    return ns.ApiCompat:GetWeaponTexture(slotID)
        or "Interface\\Icons\\INV_Misc_QuestionMark"
end

local function isLowTime(state, limit)
    return state.hasExpirationTime and state.expirationMS < limit
end

local function updateStoneBar(button, state, stone)
    if not stone then
        button.stoneTrack:Hide()
        button.stoneBar:Hide()
        return
    end

    local fraction = state.hasExpirationTime
        and math.min(1, state.expirationMS / (ns.SharpeningData:GetDuration(stone) * 1000)) or 1
    button.stoneBar:SetWidth(math.max(2, STONE_BAR_WIDTH * fraction))
    if button.stoneLow then
        button.stoneTrack:SetColorTexture(0.16, 0.09, 0.05, 1)
        button.stoneBar:SetColorTexture(1, 0.54, 0.21, 1)
    else
        button.stoneTrack:SetColorTexture(0.08, 0.16, 0.24, 1)
        button.stoneBar:SetColorTexture(0.35, 0.76, 1, 1)
    end
    button.stoneTrack:Show()
    button.stoneBar:Show()
end

local function renderButton(button, state, familyKey)
    local lowTimeLimit = ns.Database:Get("lowMinutes") * 60000
    local lowTime = isLowTime(state, lowTimeLimit)
    local lowCharges = state.charges > 0 and state.charges < ns.Database:Get("lowCharges")
    local poisonLow = familyKey and (lowTime or lowCharges)
    local secondary = familyKey and state.secondaryStone
    local secondaryStone = secondary and ns.SharpeningData:GetByEnchantID(secondary.enchantID)
    button.healthyPoison = familyKey ~= nil and not poisonLow
    button.stoneLow = secondaryStone and isLowTime(secondary, lowTimeLimit)
    local icon = Buttons:ResolveIcon(state, familyKey, button.slotID)
    button.icon:SetTexture(icon)
    button.familyKey = familyKey
    button.state = state
    updateStoneBar(button, secondary, secondaryStone)
    Buttons:UpdateButtonOpacity(button)

    if not state.hasWeapon then
        button.icon:SetDesaturated(true)
        button.icon:SetAlpha(0.35)
        button.timeText:SetText("")
        button.chargeText:SetText("")
        button.missingText:SetText(ns.L.NO_WEAPON)
        button.missingText:SetTextColor(0.85, 0.85, 0.85)
        button.missingText:Show()
        setWarning(button)
        setBackdrop(button.visual, { 0.45, 0.45, 0.45, 1 }, { 0.02, 0.02, 0.02, 0.92 })
    elseif not state.hasEnchant then
        button.icon:SetDesaturated(true)
        button.icon:SetAlpha(0.45)
        button.timeText:SetText("")
        button.chargeText:SetText("")
        button.missingText:SetText(ns.L.MISSING)
        button.missingText:SetTextColor(1, 1, 1)
        button.missingText:Show()
        setWarning(button, 1, 0.02, 0.02, 0.38)
        setBackdrop(button.visual, { 1, 0.03, 0.03, 1 }, { 0.52, 0.005, 0.005, 0.98 })
    else
        local stone = ns.SharpeningData:GetByEnchantID(state.enchantID)
        button.icon:SetDesaturated(false)
        button.icon:SetAlpha(1)
        button.timeText:SetText(state.hasExpirationTime and formatTime(state.expirationMS) or "")
        button.chargeText:SetText(state.charges > 0 and tostring(state.charges) or "")
        button.missingText:Hide()
        if poisonLow or (stone and lowTime) then
            setWarning(button, 1, 0.32, 0.01, 0.30)
            setBackdrop(button.visual, { 1, 0.32, 0.01, 1 }, { 0.48, 0.10, 0.005, 0.98 })
        elseif not familyKey then
            setWarning(button)
            setBackdrop(button.visual, { 0.55, 0.55, 0.55, 1 }, { 0.02, 0.02, 0.02, 0.92 })
        else
            setWarning(button)
            setBackdrop(button.visual, { 0.28, 0.72, 0.32, 1 }, { 0.02, 0.02, 0.02, 0.92 })
        end
    end

    return poisonLow
end

function Buttons:RenderPreview(button, state, familyKey)
    styleButtonText(button)
    renderButton(button, state, familyKey)
end

function Buttons:RefreshButton(button)
    local previous, previousFamily, wasHealthy = button.state, button.familyKey, button.healthyPoison
    local state = ns.ApiCompat:GetWeaponState(button.slotID)
    local now = type(GetTime) == "function" and GetTime() or 0
    local enchantChanged = state.hasEnchant ~= button.lastHadEnchant
        or state.enchantID ~= button.lastEnchantID
    if not state.hasEnchant then
        button.cachedFamily = nil
    elseif enchantChanged or now >= (button.nextIdentityScan or 0) then
        if enchantChanged then
            button.cachedFamily = nil
        end
        -- Known stones must not be mistaken for poison by a tooltip fallback.
        button.cachedFamily = not ns.SharpeningData:GetByEnchantID(state.enchantID)
            and ns.ApiCompat:DetectPoisonFamily(button.slotID, state.enchantID) or nil
        button.nextIdentityScan = now + 2
    end
    button.lastHadEnchant = state.hasEnchant
    button.lastEnchantID = state.enchantID
    local familyKey = state.hasWeapon and state.hasEnchant and button.cachedFamily or nil
    local poisonLow = renderButton(button, state, familyKey)
    local oldStone, newStone = previous and previous.secondaryStone, state.secondaryStone
    if button.hovered and (oldStone or newStone) and GameTooltip and GameTooltip:IsOwned(button)
        and (not oldStone or not newStone or oldStone.enchantID ~= newStone.enchantID
            or formatStoneTime(oldStone) ~= formatStoneTime(newStone)) then
        self:ShowTooltip(button)
    end
    return poisonLow and wasHealthy and not enchantChanged
        and previous.weaponItemID == state.weaponItemID and previousFamily == familyKey
end

function Buttons:ResetPoisonReminder(slotID)
    if not self.anchor then return end
    if not slotID or slotID == C.MAIN_HAND_SLOT then self.mainButton.healthyPoison = false end
    if not slotID or slotID == C.OFF_HAND_SLOT then self.offButton.healthyPoison = false end
end

function Buttons:PlayPoisonReminder()
    local volume = ns.Database:Get("reminderVolume")
    if volume == 0 or type(PlaySoundFile) ~= "function" then return end
    -- Custom files use gain-adjusted copies so playback leaves the game mixer alone.
    local file = volume == 100 and "poisons-goblin.ogg" or string.format("reminder\\%d.ogg", volume)
    PlaySoundFile(ASSET_PATH .. file, "SFX")
end

function Buttons:Refresh(resetIdentity, quiet)
    if not self.anchor then
        return
    end
    if resetIdentity then
        self.mainButton.nextIdentityScan = 0
        self.offButton.nextIdentityScan = 0
    end
    local mainReminder = self:RefreshButton(self.mainButton)
    local offReminder = self:RefreshButton(self.offButton)
    local hands = ns.Database:Get("hands")
    if not quiet and ns.Database:Get("soundAlerts")
        and ((hands ~= "OFF" and mainReminder) or (hands ~= "MAIN" and offReminder)) then
        self:PlayPoisonReminder()
    end
    self:UpdateTimer()
end

local function updateTimers(_, elapsed)
    Buttons:OnUpdate(elapsed)
end

local function hasRunningTimer(state)
    return state and state.hasEnchant and state.hasExpirationTime and state.expirationMS > 0 or false
end

function Buttons:UpdateTimer()
    local main = self.mainButton.state
    local off = self.offButton.state
    local hands = ns.Database:Get("hands")
    local active = (hands ~= "OFF" and (hasRunningTimer(main) or hasRunningTimer(main.secondaryStone)))
        or (hands ~= "MAIN" and (hasRunningTimer(off) or hasRunningTimer(off.secondaryStone)))
    if active ~= self.timerActive then
        self.timerActive = active
        self.elapsed = 0
        self.anchor:SetScript("OnUpdate", active and updateTimers or nil)
    end
end

function Buttons:ShowTooltip(button)
    if not GameTooltip then
        return
    end
    GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
    local title = button.previewTitle or (button.slotID == C.MAIN_HAND_SLOT and ns.L.MAIN_HAND or ns.L.OFF_HAND)
    GameTooltip:SetText(title, 1, 0.82, 0)
    local state = button.state or ns.ApiCompat:GetWeaponState(button.slotID)
    if state.hasEnchant then
        local stone = ns.SharpeningData:GetByEnchantID(state.enchantID)
        local activeName = button.familyKey and ns.PoisonData:GetLabel(button.familyKey)
            or (stone and ns.SharpeningData:GetLabel(stone)) or ns.L.UNKNOWN_ENCHANT
        GameTooltip:AddLine(string.format(ns.L.ACTIVE, activeName), 1, 1, 1)
        if not button.familyKey and not stone then
            GameTooltip:AddLine(ns.L.OTHER_ENCHANT, 0.8, 0.8, 0.8, true)
        end
        GameTooltip:AddLine(state.hasExpirationTime
            and string.format(ns.L.TIME_LEFT, formatTime(state.expirationMS)) or ns.L.NO_EXPIRATION, 0.8, 0.8, 0.8)
        if state.charges > 0 then
            GameTooltip:AddLine(string.format(ns.L.CHARGES_LEFT, state.charges), 0.8, 0.8, 0.8)
        end
        local secondary = state.secondaryStone
        local secondaryStone = secondary and ns.SharpeningData:GetByEnchantID(secondary.enchantID)
        if secondaryStone then
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine(string.format(ns.L.ACTIVE, ns.SharpeningData:GetLabel(secondaryStone)), 1, 1, 1)
            GameTooltip:AddLine(formatStoneTime(secondary), 0.8, 0.8, 0.8)
        end
    else
        GameTooltip:AddLine(state.hasWeapon and ns.L.MISSING or ns.L.NO_WEAPON, 1, 0.2, 0.2)
    end
    if button.preview then
        GameTooltip:Show()
        return
    end
    GameTooltip:AddLine(" ")
    for _, slot in ipairs(ns.Database:GetSlots()) do
        local bind = slot.bind
        local entry = ns.SecureActions.keyState and ns.SecureActions.keyState[bind]
        local keyboard = ns.Bindings:IsKeyboard(bind)
        if bind ~= "" and (not keyboard or (entry and entry.target == button.slotID)) then
            local familyKey = keyboard and entry.choice or button.boundChoices[bind]
            local itemID = keyboard and entry.itemID or button.availableItems[bind]
            familyKey = familyKey or slot.choice
            local label
            if itemID then
                label = string.format(ns.L.RANK_STOCK, ns.ApplicationData:GetItemLabel(familyKey, itemID),
                    ns.ApiCompat:GetItemCount(itemID))
            else
                label = string.format(ns.L.NO_USABLE_RANK, ns.ApplicationData:GetLabel(familyKey))
            end
            GameTooltip:AddDoubleLine(ns.Bindings:GetLabel(bind), label, 1, 0.82, 0, 1, 1, 1)
        end
    end
    if ns.SecureActions.refreshPending then
        GameTooltip:AddLine(ns.L.PENDING_REFRESH, 1, 0.82, 0, true)
    end
    GameTooltip:Show()
end

function Buttons:OnUpdate(elapsed)
    self.elapsed = (self.elapsed or 0) + elapsed
    if self.elapsed >= C.UPDATE_INTERVAL then
        self.elapsed = 0
        self:Refresh()
    end
end
