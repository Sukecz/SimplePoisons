local addonName, ns = ...

local Buttons = {}
ns.Buttons = Buttons

local C = ns.Constants
local TEXT_COLOR = { 1, 0.82, 0 }

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
    frame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = false,
        edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
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

function Buttons:CreateButton(name, slotID, slotLabel)
    local template = BackdropTemplateMixin and "SecureActionButtonTemplate,BackdropTemplate"
        or "SecureActionButtonTemplate"
    local button = CreateFrame("Button", name, self.anchor, template)
    button:SetSize(C.BUTTON_SIZE, C.BUTTON_SIZE)
    button:RegisterForClicks("AnyUp")
    button.slotID = slotID
    button.slotLabel = slotLabel
    button.availableItems = {}
    setBackdrop(button, { 0.28, 0.28, 0.28, 1 }, { 0.02, 0.02, 0.02, 0.92 })

    button.icon = button:CreateTexture(nil, "ARTWORK")
    button.icon:SetPoint("TOPLEFT", 4, -4)
    button.icon:SetPoint("BOTTOMRIGHT", -4, 4)
    button.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)

    button.warningTint = button:CreateTexture(nil, "ARTWORK")
    button.warningTint:SetPoint("TOPLEFT", 4, -4)
    button.warningTint:SetPoint("BOTTOMRIGHT", -4, 4)
    button.warningTint:SetBlendMode("ADD")
    button.warningTint:Hide()

    button.warningGlow = button:CreateTexture(nil, "OVERLAY")
    button.warningGlow:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
    button.warningGlow:SetBlendMode("ADD")
    button.warningGlow:SetSize(76, 76)
    button.warningGlow:SetPoint("CENTER")
    button.warningGlow:Hide()

    button.slotText = button:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    button.slotText:SetPoint("BOTTOMLEFT", button, "TOPLEFT", 2, 2)
    button.slotText:SetText(slotLabel)

    button.chargeText = button:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    button.chargeText:SetPoint("BOTTOMRIGHT", button, "TOPRIGHT", -2, 2)
    button.chargeText:SetJustifyH("RIGHT")

    button.timeText = button:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    button.timeText:SetPoint("TOP", button, "BOTTOM", 0, -2)
    button.timeText:SetShadowOffset(1, -1)

    button.missingText = button:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    button.missingText:SetPoint("CENTER", 0, 0)
    button.missingText:SetText(ns.L.MISSING)
    button.missingText:SetTextColor(1, 0.2, 0.2)
    button.missingText:Hide()

    button:SetScript("OnEnter", function(self)
        Buttons:ShowTooltip(self)
    end)
    button:SetScript("OnLeave", function()
        if GameTooltip then
            GameTooltip:Hide()
        end
    end)
    button:SetScript("PostClick", function(self, mouseButton)
        if not self.availableItems[mouseButton] then
            local familyKey = ns.Database:GetClick(mouseButton)
            if familyKey then
                ns.Core:Print(string.format(ns.L.NO_POISON, ns.PoisonData:GetLabel(familyKey)))
            end
        else
            self.lastAppliedFamily = ns.Database:GetClick(mouseButton)
            self.cachedFamily = nil
            self.nextIdentityScan = 0
        end
    end)

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
    self.settingsButton:SetFrameStrata("HIGH")
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
        end
    end)
    self.moveHandle:SetScript("OnDragStop", function()
        Buttons.anchor:StopMovingOrSizing()
        ns.Database:SavePosition(Buttons.anchor)
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
    if ns.Database:Get("orientation") == "VERTICAL" then
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
end

function Buttons:ApplyTextStyle()
    if not self.mainButton then
        return
    end
    local size = ns.Database:Get("textSize")
    for _, button in ipairs({ self.mainButton, self.offButton }) do
        applyFontStyle(button.slotText, size)
        applyFontStyle(button.chargeText, size)
        applyFontStyle(button.timeText, size)
    end
    self:ApplyLayout()
end

function Buttons:ApplyPosition()
    local position = ns.Database:Get("position")
    self.anchor:ClearAllPoints()
    self.anchor:SetPoint(position.point, UIParent, position.relativePoint, position.x, position.y)
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
        self.moveControls:Hide()
        ns.Database:SavePosition(self.anchor)
    end
    return true
end

function Buttons:RefreshButton(button)
    local state = ns.ApiCompat:GetWeaponState(button.slotID)
    local now = type(GetTime) == "function" and GetTime() or 0
    local enchantChanged = state.hasEnchant ~= button.lastHadEnchant
        or (state.enchantID and state.enchantID ~= button.lastEnchantID)
    if not state.hasEnchant then
        button.cachedFamily = nil
    elseif enchantChanged or now >= (button.nextIdentityScan or 0) then
        if enchantChanged then
            button.cachedFamily = nil
        end
        button.cachedFamily = ns.ApiCompat:DetectPoisonFamily(button.slotID) or button.cachedFamily
        button.nextIdentityScan = now + 2
    end
    button.lastHadEnchant = state.hasEnchant
    button.lastEnchantID = state.enchantID
    local familyKey = state.hasEnchant and (button.cachedFamily or button.lastAppliedFamily) or nil
    local icon = familyKey and ns.PoisonData:GetRepresentativeIcon(familyKey)
        or ns.ApiCompat:GetWeaponTexture(button.slotID)
        or "Interface\\Icons\\INV_Misc_QuestionMark"
    button.icon:SetTexture(icon)
    button.familyKey = familyKey
    button.state = state

    if not state.hasWeapon then
        button.icon:SetDesaturated(true)
        button.icon:SetAlpha(0.35)
        button.timeText:SetText("")
        button.chargeText:SetText("")
        button.missingText:SetText(ns.L.NO_WEAPON)
        button.missingText:SetTextColor(0.85, 0.85, 0.85)
        button.missingText:Show()
        setWarning(button)
        setBackdrop(button, { 0.45, 0.45, 0.45, 1 }, { 0.02, 0.02, 0.02, 0.92 })
    elseif not state.hasEnchant then
        button.icon:SetDesaturated(true)
        button.icon:SetAlpha(0.45)
        button.timeText:SetText("")
        button.chargeText:SetText("")
        button.missingText:SetText(ns.L.MISSING)
        button.missingText:SetTextColor(1, 1, 1)
        button.missingText:Show()
        setWarning(button, 1, 0.02, 0.02, 0.38)
        setBackdrop(button, { 1, 0.03, 0.03, 1 }, { 0.52, 0.005, 0.005, 0.98 })
    else
        local lowTime = state.expirationMS < (ns.Database:Get("lowMinutes") * 60000)
        local lowCharges = state.charges > 0 and state.charges < ns.Database:Get("lowCharges")
        button.icon:SetDesaturated(false)
        button.icon:SetAlpha(1)
        button.timeText:SetText(formatTime(state.expirationMS))
        button.chargeText:SetText(state.charges > 0 and tostring(state.charges) or "")
        button.missingText:Hide()
        if lowTime or lowCharges then
            setWarning(button, 1, 0.32, 0.01, 0.30)
            setBackdrop(button, { 1, 0.32, 0.01, 1 }, { 0.48, 0.10, 0.005, 0.98 })
        else
            setWarning(button)
            setBackdrop(button, { 0.28, 0.72, 0.32, 1 }, { 0.02, 0.02, 0.02, 0.92 })
        end
    end
end

function Buttons:Refresh()
    if not self.anchor then
        return
    end
    self:RefreshButton(self.mainButton)
    self:RefreshButton(self.offButton)
end

function Buttons:ShowTooltip(button)
    if not GameTooltip then
        return
    end
    GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
    GameTooltip:SetText(button.slotID == C.MAIN_HAND_SLOT and ns.L.MAIN_HAND or ns.L.OFF_HAND, 1, 0.82, 0)
    local state = button.state or ns.ApiCompat:GetWeaponState(button.slotID)
    if state.hasEnchant then
        local activeName = button.familyKey and ns.PoisonData:GetLabel(button.familyKey) or ns.L.UNKNOWN_ENCHANT
        GameTooltip:AddLine(string.format(ns.L.ACTIVE, activeName), 1, 1, 1)
        GameTooltip:AddLine(string.format(ns.L.TIME_LEFT, formatTime(state.expirationMS)), 0.8, 0.8, 0.8)
        if state.charges > 0 then
            GameTooltip:AddLine(string.format(ns.L.CHARGES_LEFT, state.charges), 0.8, 0.8, 0.8)
        end
    else
        GameTooltip:AddLine(state.hasWeapon and ns.L.MISSING or ns.L.NO_WEAPON, 1, 0.2, 0.2)
    end
    GameTooltip:AddLine(" ")
    local mappings = {
        { "LeftButton", ns.L.LEFT_CLICK },
        { "RightButton", ns.L.RIGHT_CLICK },
        { "MiddleButton", ns.L.MIDDLE_CLICK },
    }
    for _, mapping in ipairs(mappings) do
        local familyKey = ns.Database:GetClick(mapping[1])
        local label = ns.PoisonData:GetLabel(familyKey)
        local stock = ns.PoisonData:GetStock(familyKey)
        GameTooltip:AddDoubleLine(mapping[2], label .. "  |cffaaaaaa(" .. stock .. ")|r", 1, 0.82, 0, 1, 1, 1)
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
