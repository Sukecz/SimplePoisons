local addonName, ns = ...

local Options = { page = 1, PAGE_SIZE = 8 }
ns.Options = Options

local function panel(parent, name, width, height, x, y)
    local frame = CreateFrame("Frame", name, parent, BackdropTemplateMixin and "BackdropTemplate" or nil)
    frame:SetSize(width, height)
    frame:SetPoint("TOPLEFT", x, y)
    frame:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 12, insets = { left = 3, right = 3, top = 3, bottom = 3 } })
    frame:SetBackdropColor(0.035, 0.045, 0.04, 0.98)
    frame:SetBackdropBorderColor(0.22, 0.29, 0.22, 1)
    return frame
end

local function text(parent, value, x, y, width, font)
    local label = parent:CreateFontString(nil, "OVERLAY", font or "GameFontHighlight")
    label:SetPoint("TOPLEFT", x, y)
    label:SetWidth(width)
    label:SetJustifyH("LEFT")
    label:SetText(value)
    return label
end

local function button(parent, value, width, height, x, y, callback)
    local frame = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    frame:SetSize(width, height)
    frame:SetPoint("TOPLEFT", x, y)
    frame:SetText(value)
    frame:SetScript("OnClick", callback)
    return frame
end

local function enabled(control, value)
    if value then control:Enable() else control:Disable() end
end

local function allowed()
    if ns.ApiCompat:IsCombatLocked() then
        ns.Core:Print(ns.L.COMBAT_LOCKED)
        return false
    end
    return true
end

local function apply()
    ns.SecureActions:RefreshAll()
    ns.Buttons:Refresh()
end

local function tooltip(frame, itemID, label)
    if not GameTooltip then return end
    GameTooltip:SetOwner(frame, "ANCHOR_RIGHT")
    if itemID and type(GameTooltip.SetHyperlink) == "function" then
        GameTooltip:SetHyperlink("item:" .. itemID)
    else
        GameTooltip:SetText(label, 1, 0.82, 0)
    end
    GameTooltip:Show()
end

local function hideTooltip()
    if GameTooltip then GameTooltip:Hide() end
end

local function dropdown(parent, label, y, width, items, getter, setter)
    text(parent, label, 18, y, 115, "GameFontNormalSmall")
    local frame = CreateFrame("Frame", nil, parent, "UIDropDownMenuTemplate")
    frame:SetPoint("TOPRIGHT", -7, y + 7)
    UIDropDownMenu_SetWidth(frame, width)
    frame.Refresh = function()
        for _, item in ipairs(items) do
            if item.value == getter() then
                UIDropDownMenu_SetSelectedValue(frame, item.value)
                UIDropDownMenu_SetText(frame, item.label)
            end
        end
    end
    UIDropDownMenu_Initialize(frame, function(_, level)
        for _, item in ipairs(items) do
            local selected = item
            local info = UIDropDownMenu_CreateInfo()
            info.text, info.value, info.checked = selected.label, selected.value, selected.value == getter()
            info.func = function()
                if not allowed() then return end
                setter(selected.value)
                frame:Refresh()
                apply()
            end
            UIDropDownMenu_AddButton(info, level)
        end
    end)
    frame:Refresh()
    return frame
end

local function slider(parent, name, label, y, key, formatter, layout)
    local range = ns.Ranges[key]
    local step = key == "scale" and 0.1 or 1
    local frame = CreateFrame("Slider", name, parent, "OptionsSliderTemplate")
    frame:SetPoint("TOPLEFT", 25, y)
    frame:SetWidth(278)
    frame:SetMinMaxValues(range.min, range.max)
    frame:SetValueStep(step)
    frame:SetObeyStepOnDrag(true)
    _G[name .. "Low"]:SetText(tostring(range.min))
    _G[name .. "High"]:SetText(tostring(range.max))
    local function update(value)
        _G[name .. "Text"]:SetText(label .. ": " .. formatter(value))
    end
    frame.Refresh = function(self)
        self.refreshing = true
        local value = ns.Database:Get(key)
        self:SetValue(value)
        update(value)
        self.refreshing = false
    end
    frame:SetScript("OnValueChanged", function(self, value)
        if self.refreshing then return end
        if not allowed() then self:Refresh(); return end
        value = math.floor(value / step + 0.5) * step
        ns.Database:Set(key, value)
        update(value)
        if layout then ns.Buttons:ApplyTextStyle() end
        ns.Buttons:Refresh()
    end)
    frame:Refresh()
    return frame
end

local function checkbox(parent, label, y, key, callback)
    local frame = CreateFrame("CheckButton", nil, parent, "InterfaceOptionsCheckButtonTemplate")
    frame:SetPoint("TOPLEFT", 15, y)
    frame.Text:SetText(label)
    frame.Text:SetWidth(275)
    frame.Text:SetJustifyH("LEFT")
    frame.Refresh = function(self) self:SetChecked(ns.Database:Get(key)) end
    frame:SetScript("OnClick", function(self)
        if not allowed() then self:Refresh(); return end
        ns.Database:Set(key, self:GetChecked() and true or false)
        callback()
    end)
    frame:Refresh()
    return frame
end

function Options:ApplyScale()
    if not self.frame then return end
    local width = UIParent.GetWidth and UIParent:GetWidth() or 1280
    local height = UIParent.GetHeight and UIParent:GetHeight() or 900
    self.frame:SetScale(math.min(1, (width - 32) / 1120, (height - 32) / 720))
end

function Options:Create()
    if self.frame then return self.frame end
    local frame = panel(UIParent, "SimplePoisonsOptions", 1120, 720, 0, 0)
    frame:ClearAllPoints()
    frame:SetPoint("CENTER")
    frame:SetFrameStrata("DIALOG")
    frame:SetClampedToScreen(true)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function(self) self:StartMoving() end)
    frame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
    frame.logo = frame:CreateTexture(nil, "ARTWORK")
    frame.logo:SetSize(168, 84)
    frame.logo:SetPoint("TOPLEFT", 25, -10)
    frame.logo:SetTexture("Interface\\AddOns\\SimplePoisons\\assets\\logo-header.tga")
    text(frame, ns.L.SETTINGS, 198, -23, 820, "GameFontNormalLarge")
    text(frame, ns.L.SETTINGS_SUBTITLE, 198, -50, 850, "GameFontHighlightSmall")
    frame.closeTop = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    frame.closeTop:SetPoint("TOPRIGHT", -6, -6)
    frame.closeTop:SetScript("OnClick", function() frame:Hide() end)

    local assignments = panel(frame, nil, 728, 548, 18, -104)
    frame.assignments = assignments
    text(assignments, ns.L.CLICK_ASSIGNMENTS, 18, -17, 485, "GameFontNormalLarge")
    frame.addSlot = button(assignments, ns.L.ADD_SLOT, 157, 26, 551, -12, function()
        if allowed() and ns.Database:AddSlot() then
            self.page = math.ceil(#ns.Database:GetSlots() / self.PAGE_SIZE)
            self:RefreshSlots()
            apply()
        end
    end)
    text(assignments, ns.L.EFFECT, 70, -53, 329, "GameFontNormalSmall")
    text(assignments, ns.L.BINDING, 431, -53, 220, "GameFontNormalSmall")
    frame.slotRows = {}
    frame.previous = button(assignments, "<", 32, 24, 18, -505, function()
        self.page = math.max(1, self.page - 1); self:RefreshSlots()
    end)
    frame.next = button(assignments, ">", 32, 24, 674, -505, function()
        self.page = math.min(math.ceil(#ns.Database:GetSlots() / self.PAGE_SIZE), self.page + 1)
        self:RefreshSlots()
    end)
    frame.pageText = text(assignments, "", 230, -510, 330, "GameFontHighlightSmall")

    local appearance = panel(frame, nil, 338, 548, 764, -104)
    text(appearance, ns.L.APPEARANCE, 18, -17, 300, "GameFontNormalLarge")
    frame.hands = dropdown(appearance, ns.L.VISIBLE_HANDS, -60, 150, {
        { value = "BOTH", label = ns.L.BOTH_HANDS }, { value = "MAIN", label = ns.L.MAIN_HAND_ONLY },
        { value = "OFF", label = ns.L.OFF_HAND_ONLY },
    }, function() return ns.Database:Get("hands") end,
    function(value) ns.Database:Set("hands", value); ns.Buttons:ApplyLayout() end)
    frame.orientation = dropdown(appearance, ns.L.ORIENTATION, -100, 150, {
        { value = "HORIZONTAL", label = ns.L.HORIZONTAL }, { value = "VERTICAL", label = ns.L.VERTICAL },
    }, function() return ns.Database:Get("orientation") end,
    function(value) ns.Database:Set("orientation", value); ns.Buttons:ApplyLayout() end)
    frame.scale = slider(appearance, "SimplePoisonsScale", ns.L.SCALE, -157, "scale",
        function(value) return string.format("%.1fx", value) end, true)
    frame.textSize = slider(appearance, "SimplePoisonsTextSize", ns.L.TEXT_SIZE, -213, "textSize",
        function(value) return tostring(math.floor(value)) end, true)
    frame.showHandLabels = checkbox(appearance, ns.L.SHOW_HAND_LABELS, -249, "showHandLabels",
        function() ns.Buttons:ApplyTextStyle() end)
    frame.showMinimap = checkbox(appearance, ns.L.SHOW_MINIMAP, -280, "showMinimap",
        function() ns.MinimapButton:RefreshVisibility() end)
    frame.showSettingsIcon = checkbox(appearance, ns.L.SHOW_SETTINGS_ICON, -311, "showSettingsIcon",
        function() ns.Buttons:ApplyLayout() end)
    text(appearance, ns.L.WARNING_THRESHOLDS, 18, -361, 300, "GameFontNormal")
    frame.lowTime = slider(appearance, "SimplePoisonsLowTime", ns.L.LOW_TIME, -410, "lowMinutes",
        function(value) return string.format(ns.L.MINUTES, math.floor(value)) end)
    frame.lowCharges = slider(appearance, "SimplePoisonsLowCharges", ns.L.LOW_CHARGES, -473, "lowCharges",
        function(value) return tostring(math.floor(value)) end)

    frame.move = button(frame, ns.L.UNLOCK, 156, 26, 20, -674, function()
        if ns.Buttons:SetUnlocked(not ns.Buttons.unlocked) and ns.Buttons.unlocked then
            frame.keepButtonsUnlocked = true; frame:Hide()
        end
    end)
    frame.resetPosition = button(frame, ns.L.RESET_POSITION, 156, 26, 185, -674, function()
        if not allowed() then return end
        ns.Database:ResetPosition(); ns.Buttons:ApplyPosition()
    end)
    text(frame, ns.L.BINDING_HINT, 366, -671, 610, "GameFontHighlightSmall")
    frame.close = button(frame, ns.L.CLOSE, 105, 26, 995, -674, function() frame:Hide() end)
    frame:SetScript("OnHide", function()
        self:CancelCapture()
        if self.picker then self.picker:Hide() end
        if frame.keepButtonsUnlocked then frame.keepButtonsUnlocked = nil; return end
        if ns.Buttons.unlocked then
            if ns.ApiCompat:IsCombatLocked() then ns.Buttons.lockPending = true
            else ns.Buttons:SetUnlocked(false) end
        end
    end)
    self.frame = frame
    if UISpecialFrames then table.insert(UISpecialFrames, "SimplePoisonsOptions") end
    frame:Hide()
    return frame
end

function Options:SelectChoice(index, value)
    if not allowed() then return end
    local slot = ns.Database:GetSlots()[index]
    if slot and ns.Database:SetSlot(index, slot.bind, value) then
        self:RefreshSlots(); apply()
    end
end

function Options:RefreshSlots()
    if not self.frame then return end
    local frame, slots = self.frame, ns.Database:GetSlots()
    local pages = math.max(1, math.ceil(#slots / self.PAGE_SIZE))
    self.page = math.max(1, math.min(self.page, pages))
    for index, slot in ipairs(slots) do
        local row = frame.slotRows[index]
        if not row then
            row = panel(frame.assignments, nil, 692, 48, 18, -77)
            row.number = text(row, tostring(index), 6, -16, 20, "GameFontDisableSmall")
            row.choice = CreateFrame("Button", nil, row)
            row.choice:SetSize(387, 46)
            row.choice:SetPoint("TOPLEFT", 25, -1)
            row.choice.icon = row.choice:CreateTexture(nil, "ARTWORK")
            row.choice.icon:SetSize(36, 36)
            row.choice.icon:SetPoint("TOPLEFT", 6, -5)
            row.choice.name = text(row.choice, "", 50, -6, 329, "GameFontHighlightSmall")
            row.choice.name:SetHeight(18)
            row.choice.stock = text(row.choice, "", 50, -26, 329, "GameFontHighlightSmall")
            row.choice:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
            row.choice:SetScript("OnClick", function() self:OpenPicker(index) end)
            row.choice.Select = function(_, value) self:SelectChoice(index, value) end
            row.choice:SetScript("OnEnter", function(widget)
                local current = ns.Database:GetSlots()[index]
                if current then
                    local _, itemID = ns.ApplicationData:GetPreview(current.choice, current.target)
                    tooltip(widget, itemID, ns.ApplicationData:GetLabel(current.choice))
                end
            end)
            row.choice:SetScript("OnLeave", hideTooltip)
            row.bind = button(row, "", 220, 30, 413, -9, function() self:BeginCapture(index) end)
            row.remove = button(row, "-", 27, 27, 651, -10, function()
                if allowed() and ns.Database:RemoveSlot(index) then self:RefreshSlots(); apply() end
            end)
            frame.slotRows[index] = row
        end
        local visible = index > (self.page - 1) * self.PAGE_SIZE and index <= self.page * self.PAGE_SIZE
        if visible then
            row:ClearAllPoints()
            row:SetPoint("TOPLEFT", 18, -77 - ((index - 1) % self.PAGE_SIZE) * 52)
            row:Show()
            local icon, itemID = ns.ApplicationData:GetPreview(slot.choice, slot.target)
            row.choice.icon:SetTexture(icon)
            row.choice.name:SetText(ns.ApplicationData:GetLabel(slot.choice))
            row.choice.stock:SetText(string.format(ns.L.STOCK, itemID and ns.ApiCompat:GetItemCount(itemID) or 0))
            row.bind:SetText(ns.Bindings:GetLabel(slot.bind))
            enabled(row.remove, #slots > 1)
        else row:Hide() end
    end
    for index = #slots + 1, #frame.slotRows do frame.slotRows[index]:Hide() end
    frame.pageText:SetText(string.format(ns.L.SLOT_PAGE, self.page, pages, #slots))
    enabled(frame.previous, self.page > 1)
    enabled(frame.next, self.page < pages)
    enabled(frame.addSlot, #slots < 40)
    frame.leftClick = frame.slotRows[1] and frame.slotRows[1].choice
    frame.rightClick = frame.slotRows[2] and frame.slotRows[2].choice
    frame.middleClick = frame.slotRows[3] and frame.slotRows[3].choice
end

function Options:OpenPicker(index)
    if not allowed() then return end
    self:CancelCapture()
    if not self.picker then
        local picker = panel(self.frame, nil, 760, 500, 180, -106)
        picker:SetFrameStrata("FULLSCREEN_DIALOG")
        picker:EnableMouse(true)
        text(picker, ns.L.CHOOSE_EFFECT, 20, -18, 670, "GameFontNormalLarge")
        text(picker, ns.L.EFFECT_HINT, 20, -47, 714, "GameFontHighlightSmall")
        button(picker, ns.L.CLOSE, 90, 25, 650, -17, function() picker:Hide() end)
        picker.cards = {}
        self.picker = picker
    end
    local picker = self.picker
    self.pickerIndex = index
    local options = ns.ApplicationData:GetOptions()
    for _, card in ipairs(picker.cards) do card:Hide() end
    for number, option in ipairs(options) do
        local card = picker.cards[number]
        if not card then
            card = CreateFrame("Button", nil, picker, BackdropTemplateMixin and "BackdropTemplate" or nil)
            card:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
                edgeSize = 10, insets = { left = 3, right = 3, top = 3, bottom = 3 } })
            card:SetBackdropColor(0.055, 0.075, 0.055, 1)
            card:SetSize(140, 72)
            card:SetPoint("TOPLEFT", 18 + ((number - 1) % 5) * 145, -80 - math.floor((number - 1) / 5) * 80)
            card:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
            card.icon = card:CreateTexture(nil, "ARTWORK")
            card.icon:SetSize(32, 32)
            card.icon:SetPoint("TOPLEFT", 5, -8)
            card.label = text(card, "", 42, -8, 94, "GameFontHighlightSmall")
            card.label:SetHeight(58)
            card:SetScript("OnClick", function(widget)
                if not allowed() then return end
                self:SelectChoice(self.pickerIndex, widget.value)
                hideTooltip()
                picker:Hide()
            end)
            card:SetScript("OnEnter", function(widget) tooltip(widget, widget.itemID, widget.labelText) end)
            card:SetScript("OnLeave", hideTooltip)
            picker.cards[number] = card
        end
        local slot = ns.Database:GetSlots()[index]
        card:SetBackdropBorderColor(slot.choice == option.value and 0.55 or 0.2, 0.5, 0.15, 1)
        card.value, card.labelText = option.value, option.label
        local icon, itemID = ns.ApplicationData:GetPreview(option.value, slot.target)
        card.itemID = itemID
        card.icon:SetTexture(icon)
        card.label:SetText(option.label)
        card:Show()
    end
    picker:Show()
end

function Options:CancelCapture()
    self.captureIndex, self.candidate, self.captureTarget = nil, nil, nil
    if self.capture then
        self.capture:EnableKeyboard(false)
        self.capture:EnableMouseWheel(false)
        self.capture:Hide()
    end
end

function Options:SetCandidate(bind)
    if not self.captureIndex or not allowed() then self:CancelCapture(); return end
    self.candidate = bind
    self.capture.value:SetText(ns.Bindings:GetLabel(bind))
    if ns.Bindings:IsKeyboard(bind) then
        self.capture.targetLabel:Show()
        self.capture.target:Show()
        self.capture.target:SetText(self.captureTarget == 17 and ns.L.OFF_HAND or ns.L.MAIN_HAND)
    else
        self.capture.targetLabel:Hide()
        self.capture.target:Hide()
    end
    local conflict
    if ns.Bindings:IsKeyboard(bind) and type(GetBindingAction) == "function" then
        conflict = GetBindingAction(bind:sub(5))
    end
    local action = conflict and (_G["BINDING_NAME_" .. conflict] or ns.L.EXISTING_BINDING)
    self.capture.warning:SetText(conflict and conflict ~= "" and string.format(ns.L.BIND_CONFLICT, action) or ns.L.BIND_SAVE_HINT)
end

function Options:BeginCapture(index)
    if not allowed() then return end
    if self.picker then self.picker:Hide() end
    if not self.capture then
        local capture = panel(self.frame, nil, 620, 300, 250, -195)
        capture:SetFrameStrata("FULLSCREEN_DIALOG")
        capture:EnableMouse(true)
        text(capture, ns.L.SET_BINDING, 22, -18, 575, "GameFontNormalLarge")
        text(capture, ns.L.CAPTURE_HINT, 22, -53, 575, "GameFontHighlightSmall")
        capture.value = text(capture, ns.L.NONE, 30, -118, 300, "GameFontNormalLarge")
        capture.targetLabel = text(capture, ns.L.TARGET, 350, -92, 240, "GameFontNormalSmall")
        capture.target = button(capture, "", 240, 30, 350, -112, function()
            if not self.captureIndex or not allowed() or not ns.Bindings:IsKeyboard(self.candidate) then return end
            self.captureTarget = self.captureTarget == 17 and 16 or 17
            self:SetCandidate(self.candidate)
        end)
        capture.warning = text(capture, "", 22, -164, 575, "GameFontHighlightSmall")
        capture.area = button(capture, ns.L.CLICK_TO_CAPTURE, 570, 42, 22, -210, nil)
        capture.area:RegisterForClicks("AnyDown")
        capture.area:SetScript("OnMouseDown", function(_, mouse)
            local bind = ns.Bindings:Capture(mouse, true)
            if bind then self:SetCandidate(bind) end
        end)
        capture:SetScript("OnKeyDown", function(_, key)
            if key == "ESCAPE" then self:CancelCapture(); return end
            local bind = ns.Bindings:Capture(key)
            if bind then self:SetCandidate(bind) end
        end)
        capture:SetScript("OnMouseWheel", function(_, direction)
            self:SetCandidate(ns.Bindings:Capture(direction > 0 and "MOUSEWHEELUP" or "MOUSEWHEELDOWN"))
        end)
        capture.save = button(capture, ns.L.ASSIGN, 125, 25, 463, -264, function()
            if not self.captureIndex or self.candidate == nil or not allowed() then return end
            local slot = ns.Database:GetSlots()[self.captureIndex]
            if slot and ns.Database:SetSlot(self.captureIndex, self.candidate, slot.choice, self.captureTarget) then
                self:CancelCapture(); self:RefreshSlots(); apply()
            else capture.warning:SetText(ns.L.DUPLICATE_BIND) end
        end)
        capture.clear = button(capture, ns.L.CLEAR_BINDING, 140, 25, 22, -264, function() self:SetCandidate("") end)
        capture.cancel = button(capture, ns.L.CANCEL, 125, 25, 327, -264, function() self:CancelCapture() end)
        self.capture = capture
    end
    self.captureIndex = index
    self.captureTarget = ns.Database:GetSlots()[index].target or 16
    self.capture:Show()
    self.capture:EnableKeyboard(true)
    self.capture:EnableMouseWheel(true)
    if self.capture.SetPropagateKeyboardInput then self.capture:SetPropagateKeyboardInput(false) end
    self:SetCandidate(ns.Database:GetSlots()[index].bind)
end

function Options:Refresh()
    if not self.frame then return end
    self:RefreshSlots()
    for _, key in ipairs({ "lowTime", "lowCharges", "hands", "orientation", "scale", "textSize",
        "showMinimap", "showSettingsIcon", "showHandLabels" }) do self.frame[key]:Refresh() end
    self.frame.move:SetText(ns.Buttons.unlocked and ns.L.LOCK or ns.L.UNLOCK)
end

function Options:Open()
    if not allowed() then return end
    self:Create()
    self:ApplyScale()
    self:Refresh()
    self.frame:Show()
end


function Options:RegisterCategory()
    if self.category then return end
    local category = CreateFrame("Frame", nil, UIParent)
    category.name = ns.L.ADDON_NAME
    category:Hide()
    text(category, ns.L.ADDON_NAME, 20, -20, 600, "GameFontNormalLarge")
    text(category, ns.L.NATIVE_OPTIONS, 20, -58, 600, "GameFontHighlight")
    category.open = button(category, ns.L.OPEN_SETTINGS, 220, 32, 20, -110, function() self:Open() end)
    self.categoryPanel = category
    if Settings and type(Settings.RegisterCanvasLayoutCategory) == "function"
        and type(Settings.RegisterAddOnCategory) == "function" then
        self.category = Settings.RegisterCanvasLayoutCategory(category, ns.L.ADDON_NAME)
        Settings.RegisterAddOnCategory(self.category)
    elseif type(InterfaceOptions_AddCategory) == "function" then
        InterfaceOptions_AddCategory(category)
        self.category = category
    else
        category:Hide()
    end
end
