local addonName, ns = ...

local Database = {}
ns.Database = Database

local VALID_POINTS = {
    TOP = true, BOTTOM = true, LEFT = true, RIGHT = true, CENTER = true,
    TOPLEFT = true, TOPRIGHT = true, BOTTOMLEFT = true, BOTTOMRIGHT = true,
}

local function clamp(value, range, fallback)
    value = tonumber(value) or fallback
    return math.max(range.min, math.min(range.max, value))
end

local function validFamily(value, fallback)
    return ns.PoisonData:IsValidFamily(value) and value or fallback
end

function Database:Initialize(saved)
    saved = type(saved) == "table" and saved or {}
    local clicks = type(saved.clicks) == "table" and saved.clicks or {}
    local position = type(saved.position) == "table" and saved.position or {}
    local defaults = ns.Defaults

    self.data = {
        schemaVersion = ns.Constants.SCHEMA_VERSION,
        clicks = {
            LeftButton = validFamily(clicks.LeftButton, defaults.clicks.LeftButton),
            RightButton = validFamily(clicks.RightButton, defaults.clicks.RightButton),
            MiddleButton = validFamily(clicks.MiddleButton, defaults.clicks.MiddleButton),
        },
        lowMinutes = clamp(saved.lowMinutes, ns.Ranges.lowMinutes, defaults.lowMinutes),
        lowCharges = clamp(saved.lowCharges, ns.Ranges.lowCharges, defaults.lowCharges),
        scale = clamp(saved.scale, ns.Ranges.scale, defaults.scale),
        orientation = saved.orientation == "VERTICAL" and "VERTICAL" or "HORIZONTAL",
        showMinimap = saved.showMinimap ~= false,
        minimapAngle = math.max(0, math.min(359, tonumber(saved.minimapAngle) or defaults.minimapAngle)),
        position = {
            point = VALID_POINTS[position.point] and position.point or defaults.position.point,
            relativePoint = VALID_POINTS[position.relativePoint] and position.relativePoint or defaults.position.relativePoint,
            x = math.max(-5000, math.min(5000, tonumber(position.x) or defaults.position.x)),
            y = math.max(-5000, math.min(5000, tonumber(position.y) or defaults.position.y)),
        },
    }

    SimplePoisonsDB = self.data
    return self.data
end

function Database:Get(key)
    return self.data and self.data[key]
end

function Database:Set(key, value)
    if not self.data then
        return false
    end
    if key == "lowMinutes" then
        value = clamp(value, ns.Ranges.lowMinutes, ns.Defaults.lowMinutes)
    elseif key == "lowCharges" then
        value = clamp(value, ns.Ranges.lowCharges, ns.Defaults.lowCharges)
    elseif key == "scale" then
        value = clamp(value, ns.Ranges.scale, ns.Defaults.scale)
    elseif key == "orientation" then
        value = value == "VERTICAL" and "VERTICAL" or "HORIZONTAL"
    elseif key == "showMinimap" then
        value = value and true or false
    elseif key == "minimapAngle" then
        value = math.max(0, math.min(359, tonumber(value) or ns.Defaults.minimapAngle))
    else
        return false
    end
    self.data[key] = value
    return true
end

function Database:GetClick(mouseButton)
    return self.data and self.data.clicks[mouseButton]
end

function Database:SetClick(mouseButton, familyKey)
    if not self.data or not self.data.clicks[mouseButton] or not ns.PoisonData:IsValidFamily(familyKey) then
        return false
    end
    self.data.clicks[mouseButton] = familyKey
    return true
end

function Database:SavePosition(frame)
    if not self.data or not frame then
        return
    end
    local point, _, relativePoint, x, y = frame:GetPoint(1)
    self.data.position.point = VALID_POINTS[point] and point or "CENTER"
    self.data.position.relativePoint = VALID_POINTS[relativePoint] and relativePoint or self.data.position.point
    self.data.position.x = tonumber(x) or 0
    self.data.position.y = tonumber(y) or 0
end

function Database:ResetPosition()
    self.data.position = {
        point = ns.Defaults.position.point,
        relativePoint = ns.Defaults.position.relativePoint,
        x = ns.Defaults.position.x,
        y = ns.Defaults.position.y,
    }
end

function Database:Reset()
    return self:Initialize({})
end
