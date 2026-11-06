local addonName, ns = ...

local MinimapButton = {}
ns.MinimapButton = MinimapButton

local ICON = "Interface\\AddOns\\SimplePoisons\\assets\\minimap-icon.tga"

function MinimapButton:TryUseLibraries()
    if self.library then return true end
    if not LibStub or not Minimap then return false end
    local broker = LibStub("LibDataBroker-1.1", true)
    local library = LibStub("LibDBIcon-1.0", true)
    if not broker or not library then return false end

    -- Bridge the library's settings to the existing per-character fields.
    -- Dynamic access also keeps /sp reset from leaving a stale settings table.
    self.librarySettings = setmetatable({}, {
        __index = function(_, key)
            if key == "minimapPos" then return ns.Database:Get("minimapAngle") end
            if key == "hide" then return not ns.Database:Get("showMinimap") end
        end,
        __newindex = function(settings, key, value)
            if key == "minimapPos" then
                ns.Database:Set("minimapAngle", (tonumber(value) or ns.Defaults.minimapAngle) % 360)
            elseif key == "hide" then
                ns.Database:Set("showMinimap", not value)
            else
                rawset(settings, key, value)
            end
        end,
    })
    self.dataObject = broker:NewDataObject(addonName, {
        type = "launcher",
        icon = ICON,
        iconCoords = { 0, 1, 0, 1 },
        OnClick = function() ns.Options:Open() end,
        OnTooltipShow = function(tooltip)
            tooltip:SetText(ns.L.ADDON_NAME, 1, 0.82, 0)
            tooltip:AddLine(ns.L.MINIMAP_TOOLTIP, 1, 1, 1, true)
        end,
    })
    if self.button then self.button:Hide() end
    self.library = library
    library:Register(addonName, self.dataObject, self.librarySettings)
    self.button = library:GetMinimapButton(addonName)
    return true
end

local function atan2(y, x)
    if math.atan2 then
        return math.atan2(y, x)
    end
    if x > 0 then
        return math.atan(y / x)
    elseif x < 0 and y >= 0 then
        return math.atan(y / x) + math.pi
    elseif x < 0 then
        return math.atan(y / x) - math.pi
    elseif y > 0 then
        return math.pi / 2
    elseif y < 0 then
        return -math.pi / 2
    end
    return 0
end

function MinimapButton:UpdatePosition()
    if self.library then
        self.library:Refresh(addonName, self.librarySettings)
        return
    end
    if not self.button or not Minimap then
        return
    end
    local angle = math.rad(ns.Database:Get("minimapAngle") or ns.Defaults.minimapAngle)
    local radius = 80
    self.button:ClearAllPoints()
    self.button:SetPoint("CENTER", Minimap, "CENTER", math.cos(angle) * radius, math.sin(angle) * radius)
end

function MinimapButton:RefreshVisibility()
    if self.library then
        if ns.Database:Get("showMinimap") then
            self.library:Show(addonName)
        else
            self.library:Hide(addonName)
        end
        return
    end
    if not self.button then
        return
    end
    if ns.Database:Get("showMinimap") then
        self.button:Show()
    else
        self.button:Hide()
    end
end

function MinimapButton:OnDrag()
    if not Minimap or type(GetCursorPosition) ~= "function" then
        return
    end
    local x, y = GetCursorPosition()
    local scale = UIParent:GetEffectiveScale()
    x, y = x / scale, y / scale
    local centerX, centerY = Minimap:GetCenter()
    local degrees = math.deg(atan2(y - centerY, x - centerX))
    if degrees < 0 then
        degrees = degrees + 360
    end
    ns.Database:Set("minimapAngle", degrees)
    self:UpdatePosition()
end

function MinimapButton:Create()
    -- Retry at PLAYER_LOGIN if another addon loads these optional libraries later.
    if self:TryUseLibraries() then return self.button end
    if self.button or not Minimap then
        return self.button
    end
    local button = CreateFrame("Button", "SimplePoisonsMinimapButton", Minimap)
    button:SetSize(32, 32)
    button:SetFrameStrata("MEDIUM")
    button:SetFrameLevel(8)
    button:RegisterForClicks("LeftButtonUp")
    button:RegisterForDrag("LeftButton")

    button.background = button:CreateTexture(nil, "BACKGROUND")
    button.background:SetSize(24, 24)
    button.background:SetPoint("CENTER")
    button.background:SetTexture("Interface\\Minimap\\UI-Minimap-Background")

    button.icon = button:CreateTexture("SimplePoisonsMinimapButtonIcon", "ARTWORK")
    button.icon:SetSize(22, 22)
    button.icon:SetPoint("CENTER")
    button.icon:SetTexture(ICON)
    button.icon:SetTexCoord(0, 1, 0, 1)

    -- Keep the frame behind the logo, including clients with an opaque center.
    button.border = button:CreateTexture(nil, "BORDER")
    button.border:SetSize(53, 53)
    button.border:SetPoint("TOPLEFT")
    button.border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")

    button.highlight = button:CreateTexture(nil, "HIGHLIGHT")
    button.highlight:SetSize(24, 24)
    button.highlight:SetPoint("CENTER")
    button.highlight:SetTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
    button.highlight:SetBlendMode("ADD")

    button:SetScript("OnClick", function()
        ns.Options:Open()
    end)
    button:SetScript("OnDragStart", function()
        button:SetScript("OnUpdate", function() MinimapButton:OnDrag() end)
    end)
    button:SetScript("OnDragStop", function()
        button:SetScript("OnUpdate", nil)
        MinimapButton:OnDrag()
    end)
    button:SetScript("OnEnter", function(self)
        if GameTooltip then
            GameTooltip:SetOwner(self, "ANCHOR_LEFT")
            GameTooltip:SetText(ns.L.ADDON_NAME, 1, 0.82, 0)
            GameTooltip:AddLine(ns.L.MINIMAP_TOOLTIP, 1, 1, 1, true)
            GameTooltip:Show()
        end
    end)
    button:SetScript("OnLeave", function()
        if GameTooltip then GameTooltip:Hide() end
    end)

    self.button = button
    self:UpdatePosition()
    self:RefreshVisibility()
    return button
end
