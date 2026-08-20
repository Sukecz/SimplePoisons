local addonName, ns = ...

local MinimapButton = {}
ns.MinimapButton = MinimapButton

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
    if not self.button or not Minimap then
        return
    end
    local angle = math.rad(ns.Database:Get("minimapAngle") or ns.Defaults.minimapAngle)
    local radius = 80
    self.button:ClearAllPoints()
    self.button:SetPoint("CENTER", Minimap, "CENTER", math.cos(angle) * radius, math.sin(angle) * radius)
end

function MinimapButton:RefreshVisibility()
    if not self.button then
        return
    end
    if ns.Database:Get("showMinimap") and ns.ApiCompat:IsRogue() then
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

    button.icon = button:CreateTexture(nil, "ARTWORK")
    button.icon:SetSize(22, 22)
    button.icon:SetPoint("CENTER")
    button.icon:SetTexture("Interface\\AddOns\\SimplePoisons\\assets\\minimap-icon.tga")
    button.icon:SetTexCoord(0, 1, 0, 1)

    button.border = button:CreateTexture(nil, "OVERLAY")
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
