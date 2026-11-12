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

local function validChoice(value, fallback)
    if ns.ApplicationData:IsAvailableChoice(value) then return value end
    return ns.ApiCompat:IsRogue() and fallback or ns.SharpeningData.AUTO_KEY
end

function Database:Initialize(saved)
    saved = type(saved) == "table" and saved or {}
    local clicks = type(saved.clicks) == "table" and saved.clicks or {}
    local position = type(saved.position) == "table" and saved.position or {}
    local defaults = ns.Defaults

    self.data = {
        schemaVersion = ns.Constants.SCHEMA_VERSION,
        clicks = {
            LeftButton = validChoice(clicks.LeftButton, defaults.clicks.LeftButton),
            RightButton = validChoice(clicks.RightButton, defaults.clicks.RightButton),
            MiddleButton = validChoice(clicks.MiddleButton, defaults.clicks.MiddleButton),
        },
        lowMinutes = clamp(saved.lowMinutes, ns.Ranges.lowMinutes, defaults.lowMinutes),
        lowCharges = clamp(saved.lowCharges, ns.Ranges.lowCharges, defaults.lowCharges),
        scale = clamp(saved.scale, ns.Ranges.scale, defaults.scale),
        textSize = clamp(saved.textSize, ns.Ranges.textSize, defaults.textSize),
        orientation = saved.orientation == "VERTICAL" and "VERTICAL" or "HORIZONTAL",
        hands = (saved.hands == "MAIN" or saved.hands == "OFF") and saved.hands or "BOTH",
        showMinimap = saved.showMinimap ~= false,
        showSettingsIcon = saved.showSettingsIcon ~= false,
        showHandLabels = saved.showHandLabels ~= false,
        minimapAngle = math.max(0, math.min(359, tonumber(saved.minimapAngle) or defaults.minimapAngle)),
        position = {
            point = VALID_POINTS[position.point] and position.point or defaults.position.point,
            relativePoint = VALID_POINTS[position.relativePoint] and position.relativePoint or defaults.position.relativePoint,
            x = math.max(-5000, math.min(5000, tonumber(position.x) or defaults.position.x)),
            y = math.max(-5000, math.min(5000, tonumber(position.y) or defaults.position.y)),
        },
    }

    self.data.slots = {}
    local seen = {}
    if type(saved.slots) == "table" then
        for _, slot in ipairs(saved.slots) do
            if type(slot) == "table" and ns.Bindings:IsValid(slot.bind) and (slot.bind == "" or not seen[slot.bind]) then
                self.data.slots[#self.data.slots + 1] = {
                    bind = slot.bind, choice = validChoice(slot.choice, defaults.clicks.LeftButton),
                    target = slot.target == 17 and 17 or 16,
                }
                seen[slot.bind] = true
            end
        end
    end
    if #self.data.slots == 0 then
        for _, bind in ipairs({ "LeftButton", "RightButton", "MiddleButton" }) do
            self.data.slots[#self.data.slots + 1] = { bind = bind, choice = self.data.clicks[bind] }
        end
    end
    self:SyncClicks()
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
    elseif key == "textSize" then
        value = clamp(value, ns.Ranges.textSize, ns.Defaults.textSize)
    elseif key == "orientation" then
        value = value == "VERTICAL" and "VERTICAL" or "HORIZONTAL"
    elseif key == "hands" then
        value = (value == "MAIN" or value == "OFF") and value or "BOTH"
    elseif key == "showMinimap" or key == "showSettingsIcon" or key == "showHandLabels" then
        value = value and true or false
    elseif key == "minimapAngle" then
        value = math.max(0, math.min(359, tonumber(value) or ns.Defaults.minimapAngle))
    else
        return false
    end
    self.data[key] = value
    return true
end

-- Legacy accessors remain for callers; slots are authoritative after migration.
function Database:SyncClicks()
    self.data.clicks = {}
    for _, slot in ipairs(self.data.slots) do
        if slot.bind ~= "" then self.data.clicks[slot.bind] = slot.choice end
    end
end

function Database:GetSlots()
    return self.data.slots
end

function Database:GetClick(bind)
    return self.data and self.data.clicks[bind]
end

function Database:SetSlot(index, bind, choice, target)
    if ns.ApiCompat.IsCombatLocked and ns.ApiCompat:IsCombatLocked() then return false end
    local slots = self.data.slots
    if not slots[index] or not ns.Bindings:IsValid(bind)
        or not ns.ApplicationData:IsAvailableChoice(choice) then return false end
    for other, slot in ipairs(slots) do
        if bind ~= "" and other ~= index and slot.bind == bind then return false end
    end
    slots[index] = { bind = bind, choice = choice,
        target = (target or slots[index].target) == 17 and 17 or 16 }
    self:SyncClicks()
    return true
end

function Database:SetClick(bind, choice)
    for index, slot in ipairs(self.data.slots) do
        if slot.bind == bind then return self:SetSlot(index, bind, choice) end
    end
    return false
end

function Database:AddSlot()
    if ns.ApiCompat.IsCombatLocked and ns.ApiCompat:IsCombatLocked() then return false end
    if #self.data.slots >= 40 then return false end
    self.data.slots[#self.data.slots + 1] = {
        bind = "", choice = validChoice(ns.Defaults.clicks.LeftButton, ns.Defaults.clicks.LeftButton), target = 16,
    }
    self:SyncClicks()
    return true
end

function Database:RemoveSlot(index)
    if (ns.ApiCompat.IsCombatLocked and ns.ApiCompat:IsCombatLocked()) or #self.data.slots <= 1 or not self.data.slots[index] then return false end
    table.remove(self.data.slots, index)
    self:SyncClicks()
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
