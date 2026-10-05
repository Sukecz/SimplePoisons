-- A small explicit UI mock: unknown methods fail instead of silently succeeding.
local combat = false
local methods = {}
local function widget(name)
    local object = setmetatable({ scripts = {}, name = name }, { __index = methods })
    if name then _G[name] = object end
    return object
end
local function protectedChange(self)
    assert(not (combat and self.protected), "protected layout mutated during combat")
end
function methods:SetScript(event, callback) self.scripts[event] = callback end
function methods:RegisterEvent(event) self.events = self.events or {}; self.events[event] = true end
function methods:UnregisterEvent(event) self.events[event] = nil end
function methods:SetPoint(...) protectedChange(self); self.point = { ... } end
function methods:GetPoint() return "CENTER", UIParent, "CENTER", 0, 0 end
function methods:ClearAllPoints() protectedChange(self) end
function methods:SetSize() protectedChange(self) end
function methods:SetScale() protectedChange(self) end
function methods:Show() protectedChange(self); self.shown = true end
function methods:Hide()
    protectedChange(self)
    self.shown = false
    if self.scripts.OnHide then self.scripts.OnHide(self) end
end
function methods:IsShown() return self.shown end
function methods:SetText(value) self.text = value end
function methods:SetTexture(value) self.texture = value end
function methods:SetChecked(value) self.checked = value end
function methods:GetChecked() return self.checked end
function methods:SetFont(_, size) self.fontSize = size end
function methods:GetFont() return "font", self.fontSize or 13, "" end
function methods:SetBackdropBorderColor(...) self.border = { ... } end
function methods:SetValue(value)
    self.value = value
    if self.scripts.OnValueChanged then self.scripts.OnValueChanged(self, value) end
end
function methods:SetAttribute(key, value)
    assert(not combat, "secure attributes mutated during combat")
    self.attributes = self.attributes or {}
    self.attributes[key] = value
end
function methods:CreateTexture() return widget() end
function methods:CreateFontString() return widget() end
function methods:GetHighlightTexture() return widget() end
for _, name in ipairs({
    "SetMovable", "SetClampedToScreen", "RegisterForClicks", "RegisterForDrag", "EnableMouse",
    "SetFrameStrata", "SetNormalTexture", "SetHighlightTexture", "SetAlpha", "SetTexCoord",
    "SetBlendMode", "SetColorTexture", "SetVertexColor", "SetTextColor", "SetJustifyH",
    "SetShadowOffset", "SetBackdrop", "SetBackdropColor", "SetDesaturated", "SetWidth",
    "SetHeight", "SetMinMaxValues", "SetValueStep", "SetObeyStepOnDrag", "StartMoving",
    "StopMovingOrSizing",
}) do methods[name] = function() end end

UIParent = widget()
BackdropTemplateMixin = {}
CreateFrame = function(_, name, parent, template)
    local frame = widget(name)
    if template and template:find("SecureActionButtonTemplate", 1, true) then
        frame.protected = true
        parent.protected = true
    elseif template == "OptionsSliderTemplate" then
        widget(name .. "Low"); widget(name .. "High"); widget(name .. "Text")
    elseif template == "InterfaceOptionsCheckButtonTemplate" then
        frame.Text = widget()
    end
    return frame
end
UIDropDownMenu_SetWidth = function() end
UIDropDownMenu_SetSelectedValue = function() end
UIDropDownMenu_SetText = function() end
UIDropDownMenu_Initialize = function() end
StaticPopupDialogs = {}
SlashCmdList = {}

local ns = {}
for _, path in ipairs({ "Locales/enUS.lua", "Defaults.lua", "PoisonData.lua", "ApiCompat.lua",
    "Database.lua", "SecureActions.lua", "Buttons.lua", "MinimapButton.lua", "Options.lua",
    "SlashCommands.lua", "Core.lua" }) do
    assert(loadfile(path))("SimplePoisons", ns)
end
local states = {
    [16] = { hasWeapon = true, hasEnchant = false, expirationMS = 0, charges = 0 },
    [17] = { hasWeapon = true, hasEnchant = false, expirationMS = 0, charges = 0 },
}
local counts = { [8927] = 3, [8928] = 2 }
local usable = { [8927] = true, [8928] = true }
local reads = 0
ns.ApiCompat.IsCombatLocked = function() return combat end
ns.ApiCompat.IsRogue = function() return true end
ns.ApiCompat.GetWeaponState = function(_, slot) reads = reads + 1; return states[slot] end
ns.ApiCompat.GetWeaponTexture = function(_, slot) return "weapon:" .. slot end
ns.ApiCompat.DetectPoisonFamily = function(_, _, enchant) return ns.PoisonData:GetFamilyByEnchantID(enchant) end
ns.ApiCompat.GetItemCount = function(_, id) return counts[id] or 0 end
ns.ApiCompat.IsItemUsable = function(_, id) return usable[id] end
ns.ApiCompat.GetItemIcon = function(_, id) return "poison:" .. id end
ns.ApiCompat.GetItemName = function(_, id) return id == 8928 and "Instant Poison VI" or nil end
ns.ApiCompat.RequestItemData = function() end
ns.Core.Print = function() end
ns.Core:OnEvent("ADDON_LOADED", "SimplePoisons")
ns.Options:Open()
local main = ns.Buttons.mainButton
local anchor = ns.Buttons.anchor
assert(not anchor.scripts.OnUpdate and not ns.Core.frame.scripts.OnUpdate, "idle means no polling")
assert(main.missingText.shown)

-- Enter combat with settings already open, then drag every slider.
combat = true
local settings = ns.Options.frame
for _, entry in ipairs({
    { settings.scale, "scale", 1.4 }, { settings.textSize, "textSize", 18 },
    { settings.lowTime, "lowMinutes", 8 }, { settings.lowCharges, "lowCharges", 30 },
}) do
    local old = ns.Database:Get(entry[2])
    entry[1]:SetValue(entry[3])
    assert(ns.Database:Get(entry[2]) == old)
    assert(entry[1].value == old, "slider must return to the saved value")
end
ns.Buttons:ApplyLayout()
ns.Buttons:ApplyTextStyle()
ns.Buttons:ApplyPosition()
assert(ns.Buttons.layoutPending and ns.Buttons.textStylePending and ns.Buttons.positionPending)
counts[8928] = 0
ns.Core:OnEvent("BAG_UPDATE_DELAYED")
assert(ns.SecureActions.refreshPending)
assert(main.availableItems.LeftButton == 8928, "combat preserves the exact bound item")

local tooltipLines = {}
GameTooltip = {
    SetOwner = function() tooltipLines = {} end,
    SetText = function() end,
    AddLine = function(_, text) tooltipLines[#tooltipLines + 1] = text end,
    AddDoubleLine = function(_, _, text) tooltipLines[#tooltipLines + 1] = text end,
    Show = function() end,
}
ns.Buttons:ShowTooltip(main)
local tooltip = table.concat(tooltipLines, "\n")
assert(tooltip:find("Instant Poison VI (0 in bags)", 1, true))
assert(tooltip:find(ns.L.PENDING_REFRESH, 1, true))
combat = false
ns.Core:OnEvent("PLAYER_REGEN_ENABLED")
assert(not ns.Buttons.layoutPending and not ns.Buttons.textStylePending and not ns.Buttons.positionPending)
assert(main.availableItems.LeftButton == 8927)
assert(main.attributes.macrotext1 == "/use item:8927\n/use 16")
ns.Buttons:ShowTooltip(main)
assert(table.concat(tooltipLines, "\n"):find("Instant Poison (Rank 5) (3 in bags)", 1, true))
counts[8928] = 2
usable[8928] = false
ns.Core:OnEvent("BAG_UPDATE_DELAYED")
assert(main.availableItems.LeftButton == 8927)
usable[8928] = true
ns.Core:OnEvent("UNIT_LEVEL", "player")
assert(main.availableItems.LeftButton == 8928, "level unlock rebuilds the secure click")

-- Inventory events wake the timer; no ticker remains after expiration.
states[16] = { hasWeapon = true, hasEnchant = true, hasExpirationTime = true,
    expirationMS = 600000, charges = 100, enchantID = 625 }
ns.Core:OnEvent("UNIT_INVENTORY_CHANGED", "player")
assert(anchor.scripts.OnUpdate)
assert(main.familyKey == "instant" and main.icon.texture == "poison:8928")
assert(main.border[2] == 0.72 and not main.warningGlow.shown)
reads = 0
anchor.scripts.OnUpdate(anchor, 0.1)
assert(reads == 0)
anchor.scripts.OnUpdate(anchor, 0.1)
assert(reads == 2)
states[16].expirationMS = 60000
ns.Buttons:Refresh()
assert(main.warningGlow.shown)
states[16] = { hasWeapon = true, hasEnchant = false, expirationMS = 0, charges = 0 }
anchor.scripts.OnUpdate(anchor, 0.2)
assert(not anchor.scripts.OnUpdate and main.missingText.shown)

-- Non-poison enchants stay neutral even when nearly expired.
states[16] = { hasWeapon = true, hasEnchant = true, hasExpirationTime = true,
    expirationMS = 5000, charges = 0, enchantID = 999999 }
ns.Core:OnEvent("UNIT_INVENTORY_CHANGED", "player")
assert(main.familyKey == nil and main.icon.texture == "weapon:16")
assert(main.border[1] == 0.55 and not main.warningGlow.shown)
assert(not main.missingText.shown)
ns.Buttons:ShowTooltip(main)
assert(table.concat(tooltipLines, "\n"):find(ns.L.OTHER_ENCHANT, 1, true))
states[16].hasExpirationTime = false
states[16].expirationMS = 0
ns.Buttons:Refresh()
assert(not anchor.scripts.OnUpdate and main.timeText.text == "")

-- One active off-hand timer is enough; zero charges do not warn in TBC.
states[17] = { hasWeapon = true, hasEnchant = true, hasExpirationTime = true,
    expirationMS = 3600000, charges = 0, enchantID = 625 }
ns.Core:OnEvent("UNIT_INVENTORY_CHANGED", "player")
assert(anchor.scripts.OnUpdate and not ns.Buttons.offButton.warningGlow.shown)
assert(ns.Buttons.offButton.chargeText.text == "")
states[17].hasEnchant = false
ns.Buttons:Refresh()
assert(not anchor.scripts.OnUpdate)

settings.textSize:SetValue(18)
assert(main.timeText.fontSize == 18)
StaticPopupDialogs.SIMPLEPOISONS_CONFIRM_RESET.OnAccept()
assert(main.timeText.fontSize == 13)
print("UI combat, tooltip, rank refresh, enchant state, and timer lifecycle tests passed")
