local addonName, ns = ...

local Options = {}
ns.Options = Options

local function createBackdropFrame(frameType, name, parent, template)
    local backdropTemplate = BackdropTemplateMixin and "BackdropTemplate" or nil
    return CreateFrame(frameType, name, parent, template or backdropTemplate)
end

local function setPanelBackdrop(frame, alpha)
    if type(frame.SetBackdrop) ~= "function" then
        return
    end
    frame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    frame:SetBackdropColor(0.03, 0.03, 0.03, alpha or 0.96)
end

local function createSection(parent, text, y)
    local title = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOPLEFT", 20, y)
    title:SetText(text)
    local line = parent:CreateTexture(nil, "ARTWORK")
    line:SetColorTexture(0.45, 0.35, 0.16, 0.8)
    line:SetPoint("LEFT", title, "RIGHT", 10, 0)
    line:SetPoint("RIGHT", parent, "RIGHT", -20, 0)
    line:SetHeight(1)
end

local function createCheckButton(parent, labelText, y, getValue, setValue)
    local button = CreateFrame("CheckButton", nil, parent, "InterfaceOptionsCheckButtonTemplate")
    button:SetPoint("TOPLEFT", 18, y)
    button.Text:SetText(labelText)
    button:SetScript("OnClick", function(self)
        setValue(self:GetChecked() and true or false)
    end)
    button.Refresh = function(self)
        self:SetChecked(getValue() and true or false)
    end
    button:Refresh()
    return button
end

local function createDropdown(parent, labelText, y, width, items, getValue, setValue)
    local label = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    label:SetPoint("TOPLEFT", 24, y)
    label:SetText(labelText)
    local dropdown = CreateFrame("Frame", nil, parent, "UIDropDownMenuTemplate")
    dropdown:SetPoint("TOPRIGHT", -15, y + 8)
    UIDropDownMenu_SetWidth(dropdown, width)

    local function refresh()
        local value = getValue()
        for _, item in ipairs(items) do
            if item.value == value then
                UIDropDownMenu_SetSelectedValue(dropdown, value)
                UIDropDownMenu_SetText(dropdown, item.label)
                return
            end
        end
    end
    UIDropDownMenu_Initialize(dropdown, function()
        local current = getValue()
        for _, item in ipairs(items) do
            local selected = item
            local info = UIDropDownMenu_CreateInfo()
            info.text = selected.label
            info.value = selected.value
            info.checked = current == selected.value
            info.func = function()
                if ns.ApiCompat:IsCombatLocked() then
                    ns.Core:Print(ns.L.COMBAT_LOCKED)
                    return
                end
                setValue(selected.value)
                refresh()
                ns.SecureActions:RefreshAll()
                ns.Buttons:Refresh()
            end
            UIDropDownMenu_AddButton(info)
        end
    end)
    dropdown.Refresh = refresh
    refresh()
    return dropdown
end

local function createSlider(parent, name, labelText, y, minValue, maxValue, step, getValue, setValue, formatter)
    local slider = CreateFrame("Slider", name, parent, "OptionsSliderTemplate")
    slider:SetPoint("TOPLEFT", 26, y)
    slider:SetWidth(210)
    slider:SetMinMaxValues(minValue, maxValue)
    slider:SetValueStep(step)
    slider:SetObeyStepOnDrag(true)
    _G[name .. "Low"]:SetText(tostring(minValue))
    _G[name .. "High"]:SetText(tostring(maxValue))
    local function updateText(value)
        _G[name .. "Text"]:SetText(labelText .. ": " .. formatter(value))
    end
    slider:SetScript("OnValueChanged", function(self, value)
        value = math.floor((value / step) + 0.5) * step
        updateText(value)
        if not self.refreshing then
            setValue(value)
            ns.Buttons:ApplyLayout()
            ns.Buttons:Refresh()
        end
    end)
    slider.Refresh = function(self)
        self.refreshing = true
        local value = getValue()
        self:SetValue(value)
        updateText(value)
        self.refreshing = false
    end
    slider:Refresh()
    return slider
end

function Options:Create()
    if self.frame then
        return self.frame
    end
    local frame = createBackdropFrame("Frame", "SimplePoisonsOptions", UIParent)
    frame:SetSize(560, 640)
    frame:SetPoint("CENTER")
    frame:SetFrameStrata("DIALOG")
    frame:SetClampedToScreen(true)
    frame:EnableMouse(true)
    setPanelBackdrop(frame, 0.97)

    frame.logo = frame:CreateTexture(nil, "ARTWORK")
    frame.logo:SetSize(300, 169)
    frame.logo:SetPoint("TOP", 0, -7)
    frame.logo:SetTexture("Interface\\AddOns\\SimplePoisons\\assets\\logo-wide-ui.tga")

    createSection(frame, ns.L.CLICK_ASSIGNMENTS, -175)
    local poisonOptions = ns.PoisonData:GetOptions()
    frame.leftClick = createDropdown(frame, ns.L.LEFT_CLICK, -203, 220, poisonOptions,
        function() return ns.Database:GetClick("LeftButton") end,
        function(value) ns.Database:SetClick("LeftButton", value) end)
    frame.rightClick = createDropdown(frame, ns.L.RIGHT_CLICK, -243, 220, poisonOptions,
        function() return ns.Database:GetClick("RightButton") end,
        function(value) ns.Database:SetClick("RightButton", value) end)
    frame.middleClick = createDropdown(frame, ns.L.MIDDLE_CLICK, -283, 220, poisonOptions,
        function() return ns.Database:GetClick("MiddleButton") end,
        function(value) ns.Database:SetClick("MiddleButton", value) end)

    createSection(frame, ns.L.WARNING_THRESHOLDS, -330)
    frame.lowTime = createSlider(frame, "SimplePoisonsLowTime", ns.L.LOW_TIME, -365,
        ns.Ranges.lowMinutes.min, ns.Ranges.lowMinutes.max, 1,
        function() return ns.Database:Get("lowMinutes") end,
        function(value) ns.Database:Set("lowMinutes", value) end,
        function(value) return math.floor(value) .. " min" end)
    frame.lowCharges = createSlider(frame, "SimplePoisonsLowCharges", ns.L.LOW_CHARGES, -420,
        ns.Ranges.lowCharges.min, ns.Ranges.lowCharges.max, 1,
        function() return ns.Database:Get("lowCharges") end,
        function(value) ns.Database:Set("lowCharges", value) end,
        function(value) return tostring(math.floor(value)) end)

    createSection(frame, ns.L.APPEARANCE, -475)
    frame.orientation = createDropdown(frame, ns.L.ORIENTATION, -503, 145, {
        { value = "HORIZONTAL", label = ns.L.HORIZONTAL },
        { value = "VERTICAL", label = ns.L.VERTICAL },
    }, function() return ns.Database:Get("orientation") end,
    function(value)
        ns.Database:Set("orientation", value)
        ns.Buttons:ApplyLayout()
    end)

    frame.scale = createSlider(frame, "SimplePoisonsScale", ns.L.SCALE, -510,
        ns.Ranges.scale.min, ns.Ranges.scale.max, 0.1,
        function() return ns.Database:Get("scale") end,
        function(value) ns.Database:Set("scale", value) end,
        function(value) return string.format("%.1fx", value) end)
    frame.scale:ClearAllPoints()
    frame.scale:SetPoint("TOPLEFT", 285, -507)
    frame.scale:SetWidth(170)

    frame.showMinimap = createCheckButton(frame, ns.L.SHOW_MINIMAP, -552,
        function() return ns.Database:Get("showMinimap") end,
        function(value)
            ns.Database:Set("showMinimap", value)
            ns.MinimapButton:RefreshVisibility()
        end)

    frame.move = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    frame.move:SetSize(112, 24)
    frame.move:SetPoint("BOTTOMLEFT", 18, 18)
    frame.move:SetText(ns.L.UNLOCK)
    frame.move:SetScript("OnClick", function()
        local unlock = not ns.Buttons.unlocked
        if ns.Buttons:SetUnlocked(unlock) then
            frame.move:SetText(unlock and ns.L.LOCK or ns.L.UNLOCK)
        end
    end)

    frame.resetPosition = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    frame.resetPosition:SetSize(112, 24)
    frame.resetPosition:SetPoint("LEFT", frame.move, "RIGHT", 7, 0)
    frame.resetPosition:SetText(ns.L.RESET_POSITION)
    frame.resetPosition:SetScript("OnClick", function()
        if ns.ApiCompat:IsCombatLocked() then
            ns.Core:Print(ns.L.COMBAT_LOCKED)
            return
        end
        ns.Database:ResetPosition()
        ns.Buttons:ApplyPosition()
    end)

    frame.close = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    frame.close:SetSize(80, 24)
    frame.close:SetPoint("BOTTOMRIGHT", -18, 18)
    frame.close:SetText(ns.L.CLOSE)
    frame.close:SetScript("OnClick", function() frame:Hide() end)
    frame:SetScript("OnHide", function()
        if ns.Buttons.unlocked then
            ns.Buttons:SetUnlocked(false)
        end
    end)

    self.frame = frame
    frame:Hide()
    return frame
end

function Options:Refresh()
    if not self.frame then
        return
    end
    self.frame.leftClick:Refresh()
    self.frame.rightClick:Refresh()
    self.frame.middleClick:Refresh()
    self.frame.lowTime:Refresh()
    self.frame.lowCharges:Refresh()
    self.frame.orientation:Refresh()
    self.frame.scale:Refresh()
    self.frame.showMinimap:Refresh()
    self.frame.move:SetText(ns.Buttons.unlocked and ns.L.LOCK or ns.L.UNLOCK)
end

function Options:Open()
    if ns.ApiCompat:IsCombatLocked() then
        ns.Core:Print(ns.L.COMBAT_LOCKED)
        return
    end
    self:Create()
    self:Refresh()
    self.frame:Show()
end
