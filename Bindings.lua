local addonName, ns = ...

-- Secure mouse bindings: canonical modifier order matches SecureTemplates.
ns.Bindings = { order = {}, attributes = {} }
for _, modifier in ipairs({ "", "shift-", "ctrl-", "alt-", "ctrl-shift-", "alt-shift-", "alt-ctrl-", "alt-ctrl-shift-" }) do
    for index, mouse in ipairs({ "LeftButton", "RightButton", "MiddleButton", "Button4", "Button5" }) do
        local bind = modifier .. mouse
        ns.Bindings.order[#ns.Bindings.order + 1] = bind
        ns.Bindings.attributes[bind] = { prefix = modifier, suffix = tostring(index) }
    end
end

function ns.Bindings:GetLabel(bind)
    local label = bind:gsub("LeftButton", ns.L.LEFT_CLICK):gsub("RightButton", ns.L.RIGHT_CLICK)
        :gsub("MiddleButton", ns.L.MIDDLE_CLICK):gsub("Button4", ns.L.BUTTON4):gsub("Button5", ns.L.BUTTON5)
    return (label:gsub("alt%-", "Alt + "):gsub("ctrl%-", "Ctrl + "):gsub("shift%-", "Shift + "))
end

function ns.Bindings:Current(mouse)
    return ((IsAltKeyDown and IsAltKeyDown()) and "alt-" or "")
        .. ((IsControlKeyDown and IsControlKeyDown()) and "ctrl-" or "")
        .. ((IsShiftKeyDown and IsShiftKeyDown()) and "shift-" or "") .. mouse
end

local SPECIAL_KEYS = {}
for key in ("SPACE TAB ENTER BACKSPACE INSERT DELETE HOME END PAGEUP PAGEDOWN UP DOWN LEFT RIGHT CAPSLOCK NUMLOCK SCROLLLOCK PRINTSCREEN PAUSE MOUSEWHEELUP MOUSEWHEELDOWN NUMPADPLUS NUMPADMINUS NUMPADMULTIPLY NUMPADDIVIDE NUMPADDECIMAL NUMPADENTER"):gmatch("%S+") do
    SPECIAL_KEYS[key] = true
end
for index = 1, 24 do SPECIAL_KEYS["F" .. index] = true end
for index = 0, 9 do SPECIAL_KEYS["NUMPAD" .. index] = true end
for index = 6, 31 do SPECIAL_KEYS["BUTTON" .. index] = true end

function ns.Bindings:IsKeyboard(bind)
    return type(bind) == "string" and bind:sub(1, 4) == "key:"
end

function ns.Bindings:IsValid(bind)
    if bind == "" or self.attributes[bind] then return true end
    if not self:IsKeyboard(bind) then return false end
    local key = bind:sub(5):gsub("^ALT%-", ""):gsub("^CTRL%-", ""):gsub("^SHIFT%-", "")
    if key == "ESCAPE" or key == "UNKNOWN" or key:match("^BUTTON[1-5]$")
        or key:match("^[LR]SHIFT$") or key:match("^[LR]CTRL$") or key:match("^[LR]ALT$") then return false end
    return SPECIAL_KEYS[key] == true or key:match("^[A-Z][A-Z0-9_]+$") ~= nil
        or (#key >= 1 and #key <= 4 and not key:find("[%c%s|:]"))
end

function ns.Bindings:Capture(key, mouse)
    if mouse and ({ LeftButton = true, RightButton = true, MiddleButton = true, Button4 = true, Button5 = true })[key] then
        return self:Current(key)
    end
    if mouse then key = key:gsub("^Button", "BUTTON") end
    if key == "LSHIFT" or key == "RSHIFT" or key == "LCTRL" or key == "RCTRL"
        or key == "LALT" or key == "RALT" or key == "UNKNOWN" or key == "ESCAPE" then return nil end
    local prefix = self:Current(""):upper()
    local bind = "key:" .. prefix .. key
    return self:IsValid(bind) and bind or nil
end

local mouseLabel = ns.Bindings.GetLabel
function ns.Bindings:GetLabel(bind)
    if not bind or bind == "" then return ns.L.SET_BINDING end
    if self:IsKeyboard(bind) then
        local key = bind:sub(5)
        return type(GetBindingText) == "function" and GetBindingText(key, "KEY_") or key
    end
    return mouseLabel(self, bind)
end
