-- A small explicit UI mock: unknown methods fail instead of silently succeeding.
local combat = false
local methods = {}
local function widget(name)
    local object = setmetatable({ scripts = {}, name = name }, { __index = methods })
    if name then _G[name] = object end
    if SIMPLEPOISONS_WIDGETS then
        object.id = #SIMPLEPOISONS_WIDGETS + 1
        SIMPLEPOISONS_WIDGETS[object.id] = object
    end
    return object
end
local function protectedChange(self)
    assert(not (combat and self.protected), "protected layout mutated during combat")
end
function methods:Enable() self.enabled = true end
function methods:Disable() self.enabled = false end
function methods:EnableKeyboard(value) self.keyboardEnabled = value end
function methods:EnableMouseWheel(value) self.wheelEnabled = value end
function methods:SetPropagateKeyboardInput(value) self.propagate = value end
function methods:SetVerticalScroll(value) self.scroll = value end
function methods:GetVerticalScroll() return self.scroll or 0 end
function methods:SetScrollChild(child) self.scrollChild = child end
function methods:SetScript(event, callback) self.scripts[event] = callback end
function methods:RegisterEvent(event) self.events = self.events or {}; self.events[event] = true end
function methods:UnregisterEvent(event) self.events[event] = nil end
function methods:SetPoint(...) protectedChange(self); self.point = { ... } end
function methods:GetPoint() return "CENTER", UIParent, "CENTER", 0, 0 end
function methods:ClearAllPoints() protectedChange(self) end
function methods:SetSize(width, height) protectedChange(self); self.width, self.height = width, height end
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
function methods:CreateTexture(name, layer)
    local texture = widget(name)
    texture.parent, texture.kind = self, "Texture"
    texture.layer = layer
    return texture
end
function methods:CreateFontString(_, _, font)
    local label = widget(); label.parent, label.kind, label.font = self, "Text", font; return label
end
function methods:GetHighlightTexture() return widget() end
for _, name in ipairs({
    "SetMovable", "SetClampedToScreen", "RegisterForClicks", "RegisterForDrag", "EnableMouse",
    "SetFrameStrata", "SetFrameLevel", "SetNormalTexture", "SetHighlightTexture", "SetAlpha", "SetTexCoord",
    "SetBlendMode", "SetColorTexture", "SetVertexColor", "SetTextColor", "SetJustifyH",
    "SetShadowOffset", "SetBackdrop", "SetBackdropColor", "SetDesaturated", "SetWidth",
    "SetHeight", "SetMinMaxValues", "SetValueStep", "SetObeyStepOnDrag", "StartMoving",
    "StopMovingOrSizing",
}) do methods[name] = function() end end

function methods:SetWidth(value) self.width = value end
function methods:SetHeight(value) self.height = value end
function methods:SetAlpha(value) self.alpha = value end
function methods:SetFrameStrata(value) self.strata = value end
function methods:SetBackdrop(value) self.backdrop = value end
function methods:SetBackdropColor(...) self.background = { ... } end
function methods:SetTextColor(...) self.color = { ... } end
function methods:StartMoving() protectedChange(self); self.moving = true end
function methods:StopMovingOrSizing() protectedChange(self); self.moving = false end

UIParent = widget()
Minimap = widget()
BackdropTemplateMixin = {}
CreateFrame = function(kind, name, parent, template)
    local frame = widget(name)
    frame.kind, frame.parent, frame.template = kind, parent, template
    if template and template:find("SecureActionButtonTemplate", 1, true) then
        frame.protected = true
        parent.protected = true
    elseif template == "OptionsSliderTemplate" then
        frame.height = 16
        for _, suffix in ipairs({ "Low", "High", "Text" }) do
            local label = widget(name .. suffix)
            label.kind, label.parent, label.font = "Text", frame, "GameFontHighlightSmall"
            label.width, label.height = suffix == "Text" and 278 or 35, 18
            label:SetPoint(suffix == "High" and "TOPRIGHT" or "TOPLEFT", 0, suffix == "Text" and 23 or -17)
        end
    elseif template == "InterfaceOptionsCheckButtonTemplate" then
        frame.width, frame.height = 26, 26
        frame.Text = widget()
        frame.Text.kind, frame.Text.parent, frame.Text.font = "Text", frame, "GameFontHighlightSmall"
        frame.Text:SetPoint("LEFT", frame, "RIGHT", 0, 0)
    end
    return frame
end
UIDropDownMenu_SetWidth = function(frame, width) frame.width, frame.height = width + 50, 32 end
UIDropDownMenu_SetSelectedValue = function() end
UIDropDownMenu_SetText = function(frame, value) frame.text = value end
local menuItems
UIDropDownMenu_Initialize = function(frame, initialize)
    frame.initialize = initialize
    local previous = menuItems
    menuItems = {}
    -- Blizzard immediately calls (self, level, menuList), even during creation.
    initialize(frame, nil, nil)
    menuItems = previous
end
UIDropDownMenu_CreateInfo = function() return {} end
UIDropDownMenu_AddButton = function(info, level)
    assert(level == nil or type(level) == "number", "dropdown level must not be a frame")
    menuItems[#menuItems + 1] = info
end
local nativeCategories = {}
InterfaceOptions_AddCategory = function(category) nativeCategories[#nativeCategories + 1] = category end
StaticPopupDialogs = {}
SlashCmdList = {}

GetInventoryItemID = function() return 100 end
GetItemInfoInstant = function() return 100, nil, nil, nil, nil, 2, 7 end

local ns = {}
-- Load the shipped runtime order instead of maintaining a second file list.
for line in io.lines("SimplePoisons.toc") do
    if line:match("^[^#%s].*%.lua$") then
        local path = line:gsub("\\", "/")
        assert(loadfile(path))("SimplePoisons", ns)
    end
end
local states = {
    [16] = { hasWeapon = true, hasEnchant = false, expirationMS = 0, charges = 0 },
    [17] = { hasWeapon = true, hasEnchant = false, expirationMS = 0, charges = 0 },
}
local counts = { [8927] = 3, [8928] = 2 }
local playerLevel = 60
local itemLevels = { [8927] = 44, [8928] = 52 }
local itemDataLoaded = false
UnitLevel = function() return playerLevel end
GetItemInfo = function(id)
    if itemDataLoaded then
        return "item:" .. id, nil, nil, nil, itemLevels[id] or 20
    end
end
-- The client can report every poison unusable during login or while dead.
IsUsableItem = function() return false end
C_Item = { IsUsableItem = function() return false end }
local reads = 0
local realGetWeaponState = ns.ApiCompat.GetWeaponState
ns.ApiCompat.IsCombatLocked = function() return combat end
ns.ApiCompat.IsRogue = function() return true end
ns.ApiCompat.GetWeaponState = function(_, slot) reads = reads + 1; return states[slot] end
ns.ApiCompat.GetWeaponTexture = function(_, slot) return "weapon:" .. slot end
ns.ApiCompat.DetectPoisonFamily = function(_, _, enchant) return ns.PoisonData:GetFamilyByEnchantID(enchant) end
ns.ApiCompat.GetItemCount = function(_, id) return counts[id] or 0 end
ns.ApiCompat.GetItemIcon = function(_, id) return "poison:" .. id end
ns.ApiCompat.GetItemName = function(_, id) return id == 8928 and "Instant Poison VI" or nil end
ns.ApiCompat.RequestItemData = function() end
ns.Core.Print = function() end
ns.Core:OnEvent("ADDON_LOADED", "SimplePoisons")
ns.Options:Open()
local main = ns.Buttons.mainButton
local anchor = ns.Buttons.anchor
local settings = ns.Options.frame
local gear = ns.Buttons.settingsButton
local minimap = ns.MinimapButton.button
assert(settings.showHandLabels:GetChecked() and main.slotText.text == "MH")
assert(ns.Buttons.offButton.slotText.text == "OH")
local originalTime, originalCharges = main.timeText.text, main.chargeText.text
settings.showHandLabels:SetChecked(false)
settings.showHandLabels.scripts.OnClick(settings.showHandLabels)
assert(main.slotText.text == "" and ns.Buttons.offButton.slotText.text == "")
assert(main.timeText.text == originalTime and main.chargeText.text == originalCharges)
assert(main:IsShown() and ns.Buttons.offButton:IsShown(), "only the labels are hidden")
settings:Hide()
ns.Options:Open()
assert(not settings.showHandLabels:GetChecked(), "reopening settings preserves the preference")
combat = true
settings.showHandLabels:SetChecked(true)
settings.showHandLabels.scripts.OnClick(settings.showHandLabels)
assert(not settings.showHandLabels:GetChecked() and main.slotText.text == "")
assert(not ns.Database:Get("showHandLabels"), "combat rejects label changes")
combat = false
settings.showHandLabels:SetChecked(true)
settings.showHandLabels.scripts.OnClick(settings.showHandLabels)
assert(main.slotText.text == "MH" and ns.Buttons.offButton.slotText.text == "OH")
local layers = { BACKGROUND = 0, BORDER = 1, ARTWORK = 2, OVERLAY = 3, HIGHLIGHT = 4 }
assert(minimap and minimap:IsShown())
assert(_G.SimplePoisonsMinimapButtonIcon == minimap.icon, "collectors can resolve the named icon")
assert(layers[minimap.background.layer] < layers[minimap.icon.layer])
assert(layers[minimap.border.layer] < layers[minimap.icon.layer],
    "even an opaque stock border must not cover the custom minimap logo")
assert(minimap.icon.texture == "Interface\\AddOns\\SimplePoisons\\assets\\minimap-icon.tga")
assert(gear:IsShown() and settings.showSettingsIcon:GetChecked())
settings.showSettingsIcon:SetChecked(false)
settings.showSettingsIcon.scripts.OnClick(settings.showSettingsIcon)
assert(not gear:IsShown() and not ns.Database:Get("showSettingsIcon"))
assert(ns.Database:Get("showMinimap"), "hiding the gear preserves the minimap preference")
settings:Hide()
ns.SlashCommands:Handle("")
assert(settings:IsShown() and not settings.showSettingsIcon:GetChecked(),
    "/sp must still open settings with the gear hidden")
combat = true
settings.showSettingsIcon:SetChecked(true)
settings.showSettingsIcon.scripts.OnClick(settings.showSettingsIcon)
assert(not gear:IsShown() and not ns.Database:Get("showSettingsIcon"))
assert(not settings.showSettingsIcon:GetChecked(), "combat reverts the checkbox")
combat = false
settings.showSettingsIcon:SetChecked(true)
settings.showSettingsIcon.scripts.OnClick(settings.showSettingsIcon)
assert(gear:IsShown() and ns.Database:Get("showSettingsIcon"))
assert(not anchor.scripts.OnUpdate and not ns.Core.frame.scripts.OnUpdate, "idle means no polling")
assert(main.missingText.shown)
assert(main.availableItems.LeftButton == 8928,
    "cold item data and transient unusability must not remove the owned poison")
assert(main.attributes.macrotext1 == "/use item:8928\n/use 16")
assert(ns.Buttons.offButton.attributes.macrotext1 == "/use item:8928\n/use 17")
for _, family in ipairs({ "instant", "deadly", "crippling", "wound", "mindNumbing" }) do
    local ids = ns.PoisonData:GetItemIDs(family)
    local id = ids[#ids]
    counts[id] = 2
    assert(ns.PoisonData:GetAvailableItem(family) == id,
        "all owned Era poison families stay selectable before item data arrives")
    if family ~= "instant" then counts[id] = nil end
end
itemDataLoaded = true
ns.Core:OnEvent("ITEM_DATA_LOAD_RESULT", 8928, true)
assert(ns.Core.frame.events.ITEM_DATA_LOAD_RESULT)
assert(main.availableItems.LeftButton == 8928)

-- A completed poison application can emit only the dedicated enchant event.
-- It must wake an idle monitor, including in combat, without changing clicks.
states[16] = { hasWeapon = true, hasEnchant = true, hasExpirationTime = true,
    expirationMS = 600000, charges = 100, enchantID = 625 }
combat = true
local boundMacro = main.attributes.macrotext1
ns.Core:OnEvent("WEAPON_ENCHANT_CHANGED")
assert(not main.missingText.shown and main.icon.texture == "poison:8928")
assert(anchor.scripts.OnUpdate, "enchant events wake the idle timer")
assert(main.attributes.macrotext1 == boundMacro)
assert(ns.Core.frame.events.WEAPON_ENCHANT_CHANGED)
assert(ns.Core.frame.events.WEAPON_SLOT_CHANGED)
states[16] = { hasWeapon = true, hasEnchant = false, expirationMS = 0, charges = 0 }
ns.Core:OnEvent("WEAPON_SLOT_CHANGED")
assert(main.missingText.shown and not anchor.scripts.OnUpdate)
combat = false

-- Enter combat with settings already open, then drag every slider.
combat = true
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
    Hide = function() end,
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
playerLevel = 51
ns.Core:OnEvent("BAG_UPDATE_DELAYED")
assert(main.availableItems.LeftButton == 8927)
playerLevel = 52
ns.Core:OnEvent("UNIT_LEVEL", "player")
assert(main.availableItems.LeftButton == 8928, "level unlock rebuilds the secure click")

-- Delayed metadata corrects the chosen rank without waiting for a bag event.
playerLevel = 51
itemDataLoaded = false
ns.Core:OnEvent("PLAYER_ENTERING_WORLD")
assert(main.availableItems.LeftButton == 8928)
itemDataLoaded = true
ns.Core:OnEvent("ITEM_DATA_LOAD_RESULT", 8928, true)
assert(main.availableItems.LeftButton == 8927)
assert(main.attributes.macrotext1 == "/use item:8927\n/use 16")
assert(ns.Buttons.offButton.attributes.macrotext1 == "/use item:8927\n/use 17")
playerLevel = 60
ns.Core:OnEvent("UNIT_LEVEL", "player")
combat = true
playerLevel = 51
ns.Core:OnEvent("ITEM_DATA_LOAD_RESULT", 8928, true)
assert(main.availableItems.LeftButton == 8928 and ns.SecureActions.refreshPending)
combat = false
ns.Core:OnEvent("PLAYER_REGEN_ENABLED")
assert(main.availableItems.LeftButton == 8927)
playerLevel = 60
ns.Core:OnEvent("UNIT_LEVEL", "player")

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

-- Stones replace the poison identity in combat without changing secure clicks.
combat = true
local stoneMacro = main.attributes.macrotext1
states[16] = { hasWeapon = true, hasEnchant = true, hasExpirationTime = true,
    expirationMS = 125000, charges = 0, enchantID = 1643 }
ns.Core:OnEvent("WEAPON_ENCHANT_CHANGED")
assert(main.familyKey == nil and main.icon.texture == "poison:12404")
assert(main.timeText.text == "3m" and main.chargeText.text == "")
assert(not main.missingText.shown and anchor.scripts.OnUpdate)
assert(main.attributes.macrotext1 == stoneMacro)
ns.Buttons:ShowTooltip(main)
tooltip = table.concat(tooltipLines, "\n")
assert(tooltip:find("Dense Sharpening Stone", 1, true))
assert(not tooltip:find(ns.L.UNKNOWN_ENCHANT, 1, true))
assert(not tooltip:find(ns.L.OTHER_ENCHANT, 1, true))
states[16].expirationMS = 5000
anchor.scripts.OnUpdate(anchor, 0.2)
assert(main.timeText.text == "5s" and main.warningGlow.shown and main.border[2] == 0.32)
states[16] = { hasWeapon = true, hasEnchant = false, expirationMS = 0, charges = 0 }
anchor.scripts.OnUpdate(anchor, 0.2)
assert(main.missingText.shown and main.icon.texture == "weapon:16")
assert(not anchor.scripts.OnUpdate and main.timeText.text == "")
assert(main.attributes.macrotext1 == stoneMacro)
combat = false

settings.textSize:SetValue(18)
assert(main.timeText.fontSize == 18)
settings.showSettingsIcon:SetChecked(false)
settings.showSettingsIcon.scripts.OnClick(settings.showSettingsIcon)
settings.showHandLabels:SetChecked(false)
settings.showHandLabels.scripts.OnClick(settings.showHandLabels)
StaticPopupDialogs.SIMPLEPOISONS_CONFIRM_RESET.OnAccept()
assert(main.timeText.fontSize == 13)
assert(gear:IsShown() and settings.showSettingsIcon:GetChecked(), "reset restores the gear")
assert(settings.showHandLabels:GetChecked() and main.slotText.text == "MH",
    "reset restores MH/OH labels")

-- Every supported client's families retain both-hand macros with a cold cache
-- and false usability, and after item-data completion or revival.
WOW_PROJECT_BURNING_CRUSADE_CLASSIC = 5
playerLevel = 70
local clients = {
    { name = "Era/Hardcore", project = 2, modern = false },
    { name = "TBC", project = 5, modern = true },
    { name = "Forever", project = 99, modern = true },
}
for _, client in ipairs(clients) do
    WOW_PROJECT_ID = client.project
    C_Item.GetItemInfo = client.modern and GetItemInfo or nil
    for _, option in ipairs(ns.PoisonData:GetOptions()) do
        local ids = ns.PoisonData:GetItemIDs(option.value)
        local id = ids[#ids]
        counts[id] = 2
        ns.Database:SetClick("LeftButton", option.value)
        ns.Database:SetClick("RightButton", option.value)
        ns.Database:SetClick("MiddleButton", option.value)
        itemDataLoaded = false
        ns.Core:OnEvent("PLAYER_ENTERING_WORLD")
        for _, event in ipairs({ "ITEM_DATA_LOAD_RESULT", "GET_ITEM_INFO_RECEIVED", "PLAYER_ALIVE" }) do
            for _, button in ipairs({ main, ns.Buttons.offButton }) do
                for suffix = 1, 3 do
                    assert(button.attributes["macrotext" .. suffix]
                        == string.format("/use item:%d\n/use %d", id, button.slotID),
                        client.name .. " " .. option.value .. " must retain every hardware-click macro")
                end
            end
            itemDataLoaded = true
            ns.Core:OnEvent(event, id, true)
        end
    end
end
assert(not anchor.scripts.OnUpdate and not ns.Core.frame.scripts.OnUpdate,
    "rank readiness must not add idle polling")
print("Rank readiness: Era/Hardcore, TBC, Forever, all families and clicks, both hands passed")
print("UI combat, tooltip, rank refresh, enchant state, and timer lifecycle tests passed")

-- Exercise the real dropdown callbacks, persisted one-hand layout and combat guard.
local function selectOption(dropdown, value)
    if dropdown.Select then dropdown:Select(value); return end
    menuItems = {}
    dropdown:initialize()
    for _, item in ipairs(menuItems) do
        if item.value == value then item.func(); return end
    end
    error("Missing menu option: " .. value)
end
ns.ApiCompat.IsRogue = function() return false end
WOW_PROJECT_CAMELOT = 18
WOW_PROJECT_ID = 18
counts[12404] = 5
selectOption(settings.leftClick, "stone:1643")
assert(main.attributes.macrotext1 == "/use item:12404\n/use 16")
assert(ns.Buttons.offButton.attributes.macrotext1 == "/use item:12404\n/use 17")
ns.Database:Set("orientation", "VERTICAL")
selectOption(settings.hands, "MAIN")
assert(main:IsShown() and not ns.Buttons.offButton:IsShown())
assert(anchor.width == 48 and anchor.height == 48)
assert(ns.Database:Initialize(SimplePoisonsDB).hands == "MAIN")
assert(ns.Database:GetClick("LeftButton") == "stone:1643")
selectOption(settings.hands, "OFF")
assert(not main:IsShown() and ns.Buttons.offButton:IsShown())
assert(anchor.width == 48 and anchor.height == 48)
assert(ns.Buttons.offButton.point[1] == "CENTER")
combat = true
selectOption(settings.hands, "BOTH")
selectOption(settings.leftClick, "stone:40")
assert(ns.Database:Get("hands") == "OFF" and ns.Database:GetClick("LeftButton") == "stone:1643")
counts[12404] = 0
counts[2862] = 5
ns.Core:OnEvent("BAG_UPDATE_DELAYED")
assert(main.attributes.macrotext1 == "/use item:12404\n/use 16")
ns.Database:Set("hands", "MAIN")
ns.Buttons:ApplyLayout()
assert(ns.Buttons.layoutPending and not main:IsShown())
combat = false
ns.Core:OnEvent("PLAYER_REGEN_ENABLED")
assert(main:IsShown() and not ns.Buttons.offButton:IsShown())
assert(not main.attributes.macrotext1, "an exhausted stone never silently substitutes a different strength")
selectOption(settings.hands, "BOTH")
assert(main:IsShown() and ns.Buttons.offButton:IsShown())
assert(anchor.width == 48 and anchor.height > 96)
selectOption(settings.orientation, "HORIZONTAL")
assert(anchor.width == 101 and anchor.height == 48)
-- A hidden hand's timer alone must not keep polling active.
states[16] = { hasWeapon = true, hasEnchant = false, expirationMS = 0, charges = 0 }
states[17] = { hasWeapon = true, hasEnchant = true, hasExpirationTime = true,
    expirationMS = 123000, charges = 0, enchantID = 1643 }
ns.Buttons:Refresh(true)
assert(anchor.scripts.OnUpdate)
selectOption(settings.hands, "MAIN")
assert(not anchor.scripts.OnUpdate)
selectOption(settings.hands, "OFF")
assert(anchor.scripts.OnUpdate and ns.Buttons.offButton.timeText.text == "3m")
StaticPopupDialogs.SIMPLEPOISONS_CONFIRM_RESET.OnAccept()
assert(ns.Database:Get("hands") == "BOTH" and main:IsShown() and ns.Buttons.offButton:IsShown())
print("Warrior stone clicks, one-hand geometry, persistence, combat deferral and visible timers passed")

-- Auto choices rebind on bag events, preserving the real bound item in combat.
counts[12404], counts[7964], counts[2862] = 2, 3, 4
selectOption(settings.leftClick, "stone:auto")
assert(main.attributes.macrotext1 == "/use item:12404\n/use 16")
ns.Buttons:ShowTooltip(main)
assert(table.concat(tooltipLines, "\n"):find("Dense Sharpening Stone (2 in bags)", 1, true))
combat = true
counts[12404] = 0
ns.Core:OnEvent("BAG_UPDATE_DELAYED")
assert(main.attributes.macrotext1 == "/use item:12404\n/use 16")
ns.Buttons:ShowTooltip(main)
assert(table.concat(tooltipLines, "\n"):find("Dense Sharpening Stone (0 in bags)", 1, true))
combat = false
ns.Core:OnEvent("PLAYER_REGEN_ENABLED")
assert(main.attributes.macrotext1 == "/use item:7964\n/use 16")
assert(ns.Buttons.offButton.attributes.macrotext1 == "/use item:7964\n/use 17")
counts[12404] = 5
ns.Core:OnEvent("BAG_UPDATE_DELAYED")
assert(main.attributes.macrotext1 == "/use item:12404\n/use 16")
print("Auto stone UI: dropdown, exact tooltip, bag upgrades and combat-safe fallback passed")

-- Mixed weapons select independently and equipment swaps respect combat lockdown.
local weaponSubclasses = { [100] = 7, [101] = 4 }
local weapons = { [16] = 100, [17] = 101 }
GetInventoryItemID = function(_, slot) return weapons[slot] end
GetItemInfoInstant = function(id) return id, nil, nil, nil, nil, 2, weaponSubclasses[id] end
counts[12643] = 4
for _, project in ipairs({ 2, 5, 18 }) do
    WOW_PROJECT_ID = project
    ns.Core:OnEvent("PLAYER_EQUIPMENT_CHANGED", 17)
    assert(main.attributes.macrotext1 == "/use item:12404\n/use 16")
    assert(ns.Buttons.offButton.attributes.macrotext1 == "/use item:12643\n/use 17")
end
ns.Buttons:ShowTooltip(ns.Buttons.offButton)
assert(table.concat(tooltipLines, "\n"):find("Dense Weightstone (4 in bags)", 1, true))
combat = true
weapons[16], weapons[17] = 101, 100
ns.Core:OnEvent("PLAYER_EQUIPMENT_CHANGED", 16)
assert(main.attributes.macrotext1 == "/use item:12404\n/use 16")
assert(ns.Buttons.offButton.attributes.macrotext1 == "/use item:12643\n/use 17")
combat = false
ns.Core:OnEvent("PLAYER_REGEN_ENABLED")
assert(main.attributes.macrotext1 == "/use item:12643\n/use 16")
assert(ns.Buttons.offButton.attributes.macrotext1 == "/use item:12404\n/use 17")
weapons[17] = nil
ns.Core:OnEvent("UNIT_INVENTORY_CHANGED", "player")
assert(not ns.Buttons.offButton.attributes.macrotext1, "empty hand has no auto macro")
weapons[17] = 102
ns.Core:OnEvent("PLAYER_EQUIPMENT_CHANGED", 17)
assert(not ns.Buttons.offButton.attributes.macrotext1, "unknown weapon waits for metadata")
weaponSubclasses[102] = 4
ns.Core:OnEvent("ITEM_DATA_LOAD_RESULT", 102, true)
assert(ns.Buttons.offButton.attributes.macrotext1 == "/use item:12643\n/use 17")
selectOption(settings.leftClick, "weight:auto")
assert(main.attributes.macrotext1 == "/use item:12643\n/use 16")
print("Mixed weapons: per-hand Auto, all clients, equipment swaps, combat, empty/cold hand and dropdown passed")

for _, project in ipairs({ 2, 5, 18 }) do
    WOW_PROJECT_ID = project
    for _, row in ipairs({ { 40, 2862 }, { 13, 2863 }, { 14, 2871 }, { 483, 7964 },
        { 1643, 12404 }, { 2506, 18262 }, { 2684, 23122 }, { 7098, 211845 },
        { 2712, 23528 }, { 2713, 23529 }, { 19, 3239 }, { 20, 3240 }, { 21, 3241 },
        { 484, 7965 }, { 1703, 12643 }, { 2954, 28420 }, { 2955, 28421 } }) do
        if ns.SharpeningData:GetByEnchantID(row[1]) then
            for _, slot in ipairs({ 16, 17 }) do
                states[slot] = { hasWeapon = true, hasEnchant = true, hasExpirationTime = true,
                    expirationMS = 180000, charges = 1, enchantID = row[1] }
            end
            ns.Core:OnEvent("WEAPON_ENCHANT_CHANGED")
            for _, button in ipairs({ main, ns.Buttons.offButton }) do
                assert(button.icon.texture == "poison:" .. row[2])
                assert(button.timeText.text == "3m" and button.border[1] == 0.55)
                assert(not button.warningGlow.shown and not button.missingText.shown)
                ns.Buttons:ShowTooltip(button)
                assert(table.concat(tooltipLines, "\n"):find(
                    ns.SharpeningData:GetByEnchantID(row[1]).label, 1, true))
            end
            combat = true
            for _, slot in ipairs({ 16, 17 }) do
                states[slot].expirationMS = 179999
                states[slot].charges = 0
            end
            anchor.scripts.OnUpdate(anchor, 0.2)
            for _, button in ipairs({ main, ns.Buttons.offButton }) do
                assert(button.warningGlow.shown and button.border[2] == 0.32,
                    "every known stone warns below the time threshold, including during combat")
                assert(button.chargeText.text == "")
            end
            combat = false
        end
    end
end
for _, slot in ipairs({ 16, 17 }) do
    states[slot] = { hasWeapon = true, hasEnchant = false, expirationMS = 0, charges = 0 }
end
ns.Core:OnEvent("WEAPON_ENCHANT_CHANGED")
assert(not anchor.scripts.OnUpdate, "weightstone expiration stops timer polling")
print("Stone UI: all clients/types, both hands, threshold boundary, orange glow in combat, tooltip and expiration passed")

-- The collector's standard path must receive the actual logo, not guess a region.
-- Supply the libraries after addon initialization to exercise PLAYER_LOGIN retry.
local legacyMinimap = ns.MinimapButton.button
local registrations, registeredObject, registeredSettings = 0
local libraryButton = widget("LibDBIcon10_SimplePoisons")
libraryButton.icon = widget()
local library = {}
function library:Register(name, object, settings)
    assert(name == "SimplePoisons" and object.type == "launcher")
    registrations = registrations + 1
    registeredObject, registeredSettings = object, settings
    libraryButton.dataObject = object
    libraryButton.icon:SetTexture(object.icon)
end
function library:GetMinimapButton(name) assert(name == "SimplePoisons"); return libraryButton end
function library:Refresh(name, settings)
    assert(name == "SimplePoisons" and settings == registeredSettings)
    libraryButton.angle = settings.minimapPos
    if settings.hide then libraryButton:Hide() else libraryButton:Show() end
end
function library:Show(name) self:Refresh(name, registeredSettings) end
function library:Hide(name) assert(name == "SimplePoisons"); libraryButton:Hide() end
local broker = {}
function broker:NewDataObject(name, object) assert(name == "SimplePoisons"); return object end
LibStub = function(name, silent)
    assert(silent)
    if name == "LibDataBroker-1.1" then return broker end
    if name == "LibDBIcon-1.0" then return library end
end
ns.Core:OnEvent("PLAYER_LOGIN")
assert(registrations == 1 and ns.MinimapButton.button == libraryButton)
assert(not legacyMinimap:IsShown(), "the fallback must not leave a duplicate minimap button")
assert(libraryButton.icon.texture == "Interface\\AddOns\\SimplePoisons\\assets\\minimap-icon.tga")
assert(registeredObject.iconCoords[1] == 0 and registeredObject.iconCoords[2] == 1)
registeredObject.OnClick(libraryButton, "LeftButton")
assert(settings:IsShown(), "standard launcher clicks still open options")
registeredObject.OnTooltipShow(GameTooltip)
assert(table.concat(tooltipLines, "\n"):find(ns.L.MINIMAP_TOOLTIP, 1, true))
settings.showMinimap:SetChecked(false)
settings.showMinimap.scripts.OnClick(settings.showMinimap)
assert(registeredSettings.hide and not libraryButton:IsShown())
registeredSettings.minimapPos = -90
assert(ns.Database:Get("minimapAngle") == 270, "library drag angles preserve the original angle range")
assert(ns.Database:Initialize(SimplePoisonsDB).minimapAngle == 270)
assert(registeredSettings.minimapPos == 270 and registeredSettings.hide)
StaticPopupDialogs.SIMPLEPOISONS_CONFIRM_RESET.OnAccept()
assert(libraryButton:IsShown() and registeredSettings.minimapPos == ns.Defaults.minimapAngle)
assert(not registeredSettings.hide, "reset rebinds to the current database rather than an obsolete table")
ns.Core:OnEvent("PLAYER_LOGIN")
ns.MinimapButton:Create()
assert(registrations == 1, "repeated login/create must not register duplicate launchers")
-- First-load registration also skips creating a custom button entirely.
local fresh = { Database = ns.Database, Defaults = ns.Defaults, Options = ns.Options, L = ns.L }
assert(loadfile("MinimapButton.lua"))("SimplePoisons", fresh)
assert(fresh.MinimapButton:Create() == libraryButton)
assert(fresh.MinimapButton.library == library)
print("LibDBIcon: actual logo, late/early library registration, click/tooltip, visibility, drag, reset and no duplicates passed")

-- Exercise the dynamic slot UI, including the nested modifier menu.
ns.ApiCompat.IsRogue = function() return true end
WOW_PROJECT_ID = 2
ns.Database:Reset()
ns.Options:Refresh()
ns.SecureActions:RefreshAll()
local function selectBind(control, bind)
    control.scripts.OnClick()
    if ns.ApiCompat:IsCombatLocked() then return end
    ns.Options:SetCandidate(bind)
    ns.Options.capture.save.scripts.OnClick()
end
assert(#ns.Database:GetSlots() == 3 and #settings.slotRows == 3)
for index, bind in ipairs({ 'shift-LeftButton', 'ctrl-RightButton', 'alt-MiddleButton' }) do
    selectBind(settings.slotRows[index].bind, bind)
    assert(ns.Database:GetSlots()[index].bind == bind)
end
assert(not main.attributes.macrotext1 and not main.attributes.macrotext2 and not main.attributes.macrotext3)
settings.addSlot.scripts.OnClick()
assert(#ns.Database:GetSlots() == 4 and settings.slotRows[4]:IsShown())
assert(ns.Database:GetSlots()[4].bind == '')
selectBind(settings.slotRows[4].bind, 'LeftButton')
selectOption(settings.slotRows[4].choice, 'wound')
assert(ns.Database:GetClick('LeftButton') == 'wound')
assert(not settings.slotScroll, 'assignments do not use a three-row scrollbar')
combat = true
settings.addSlot.scripts.OnClick()
settings.slotRows[1].remove.scripts.OnClick()
selectBind(settings.slotRows[1].bind, 'Button5')
assert(#ns.Database:GetSlots() == 4 and ns.Database:GetSlots()[1].bind == 'shift-LeftButton')
combat = false
settings.slotRows[4].remove.scripts.OnClick()
assert(#ns.Database:GetSlots() == 3 and not settings.slotRows[4]:IsShown())
assert(ns.Options.page == 1, 'the first page remains visible')
assert(not main.attributes.macrotext1, 'removing a row clears the associated action')
ns.Database:Initialize(SimplePoisonsDB)
ns.Options:Refresh()
assert(ns.Database:GetSlots()[1].bind == 'shift-LeftButton')
settings.slotRows[1].remove.scripts.OnClick()
settings.slotRows[1].remove.scripts.OnClick()
settings.slotRows[1].remove.scripts.OnClick()
assert(#ns.Database:GetSlots() == 1 and settings.slotRows[1]:IsShown())
print('Slot UI: add/remove, every default bind editable, binding capture, choice persistence, wide layout, combat and stale actions passed')


-- Combat can start between the mouse press and release of a move operation.
combat = false
ns.Options:Open()
ns.Buttons:SetUnlocked(true)
ns.Buttons.moveHandle.scripts.OnDragStart()
assert(anchor.moving)
combat = true
ns.Buttons.moveHandle.scripts.OnDragStop()
settings:Hide()
assert(anchor.moving, 'protected move stop must be deferred during combat')
combat = false
ns.Core:OnEvent('PLAYER_REGEN_ENABLED')
assert(not anchor.moving and not ns.Buttons.unlocked and not ns.Buttons.moveControls:IsShown(),
    'finish the drag and lock after combat even if settings were closed')

-- Hiding the fallback minimap button while dragging must stop its polling.
legacyMinimap.scripts.OnDragStart()
assert(legacyMinimap.scripts.OnUpdate)
legacyMinimap:Hide()
assert(not legacyMinimap.scripts.OnUpdate, 'hidden minimap buttons must not keep an OnUpdate')
print('Audit: mid-drag combat, closing settings in combat and minimap drag cleanup passed')

-- Cold first login: equipment becomes available after all initial events,
-- without a subsequent inventory event or active enchant timer to refresh it.
local scheduled = {}
C_Timer = { After = function(delay, callback)
    assert(delay > 0)
    scheduled[#scheduled + 1] = callback
end }
local function runDelayed()
    local pending = scheduled
    scheduled = {}
    for _, callback in ipairs(pending) do callback() end
end
local inventoryLoaded, enchantLoaded = false, false
C_Item, C_PaperDollInfo, Enum = nil, nil, nil
GetInventoryItemID = function(_, slot)
    return inventoryLoaded and slot == 16 and 100 or nil
end
GetWeaponEnchantInfo = function()
    return enchantLoaded, enchantLoaded and 120000 or 0, 0, enchantLoaded and 625 or nil,
        false, 0, 0, nil
end
ns.ApiCompat.GetWeaponState = function(self, slot)
    reads = reads + 1
    return realGetWeaponState(self, slot)
end
ns.Core:OnEvent('PLAYER_LOGIN')
ns.Core:OnEvent('PLAYER_ENTERING_WORLD', true, false)
assert(main.missingText.text == ns.L.NO_WEAPON and not anchor.scripts.OnUpdate)
assert(#scheduled == 1, 'cold login must schedule a bounded equipment recheck')
-- Data appears without an event. Missing poison is different from missing weapon.
inventoryLoaded = true
runDelayed()
assert(main.state.hasWeapon and main.missingText.text == ns.L.MISSING)
-- An actually empty off hand must not keep retrying forever.
local retries = 1
while #scheduled > 0 do
    runDelayed()
    retries = retries + 1
    assert(retries <= 6, 'startup retries must be finite with empty slots')
end
assert(not anchor.scripts.OnUpdate and not ns.Core.frame.scripts.OnUpdate)
-- Repeated world entries invalidate old callbacks; leaving cancels the chain.
ns.Core:OnEvent('PLAYER_ENTERING_WORLD', false, false)
ns.Core:OnEvent('PLAYER_ENTERING_WORLD', false, false)
local before = reads
runDelayed()
assert(reads == before + 2, 'only the newest world entry may refresh equipment')
ns.Core:OnEvent('PLAYER_LEAVING_WORLD')
before = reads
runDelayed()
assert(reads == before and #scheduled == 0)
-- A delayed retry in combat updates the display but defers protected actions.
ns.Core:OnEvent('PLAYER_ENTERING_WORLD', true, false)
combat = true
enchantLoaded = true
runDelayed()
assert(main.familyKey == 'instant' and ns.SecureActions.refreshPending)
combat = false
ns.Core:OnEvent('PLAYER_REGEN_ENABLED')
assert(not ns.SecureActions.refreshPending)
while #scheduled > 0 do runDelayed() end
C_Timer = nil
print('Cold login: delayed equipment without events, bounded retries, empty hand, world transitions and combat passed')


do
    assert(#nativeCategories == 1 and nativeCategories[1].name == 'SimplePoisons')
    settings:Hide()
    nativeCategories[1].open.scripts.OnClick()
    assert(settings:IsShown(), 'the native Interface/AddOns entry opens full settings')
    local modern, registrations = {}, 0
    Settings = {
        RegisterCanvasLayoutCategory = function(canvas, name)
            assert(canvas == ns.Options.categoryPanel and name == 'SimplePoisons')
            return modern
        end,
        RegisterAddOnCategory = function(category) assert(category == modern); registrations = registrations + 1 end,
    }
    ns.Options.category = nil
    ns.Options:RegisterCategory()
    ns.Options:RegisterCategory()
    assert(registrations == 1 and ns.Options.category == modern)
    Settings = nil
    assert(settings.width == 1120 and settings.height == 720 and not settings.slotScroll)
    ns.Database:Reset()
    for index = 1, 6 do ns.Database:AddSlot() end
    ns.Options.page = 1
    ns.Options:Refresh()
    assert(settings.slotRows[8]:IsShown() and not settings.slotRows[9]:IsShown())
    settings.next.scripts.OnClick()
    assert(settings.slotRows[9]:IsShown() and not settings.slotRows[1]:IsShown())
    settings.previous.scripts.OnClick()
    ns.Options:OpenPicker(1)
    assert(ns.Options.picker:IsShown() and ns.Options.picker.cards[1].icon.texture)
    local card = ns.Options.picker.cards[2]
    card.scripts.OnClick(card)
    assert(ns.Database:GetSlots()[1].choice == card.value and not ns.Options.picker:IsShown())
    ns.Options:BeginCapture(1)
    local capture = ns.Options.capture
    assert(capture.keyboardEnabled and capture.propagate == false)
    capture.scripts.OnKeyDown(capture, 'LSHIFT')
    assert(ns.Options.candidate == 'LeftButton', 'a modifier alone does not change the binding')
    capture.scripts.OnKeyDown(capture, 'F8')
    assert(ns.Options.candidate == 'key:F8')
    capture.save.scripts.OnClick()
    assert(ns.Database:GetSlots()[1].bind == 'key:F8' and not capture.keyboardEnabled)
    assert(not settings.slotRows[1].target, 'the assignment table has no Weapon control')
    ns.Options:BeginCapture(1)
    assert(capture.target:IsShown() and capture.targetLabel:IsShown())
    capture.target.scripts.OnClick()
    assert(ns.Database:GetSlots()[1].target == 16, 'editing the hand waits for Assign')
    capture.save.scripts.OnClick()
    assert(ns.Database:GetSlots()[1].target == 17)
    ns.Options:BeginCapture(1)
    capture.target.scripts.OnClick()
    capture.cancel.scripts.OnClick()
    assert(ns.Database:GetSlots()[1].target == 17, 'cancel preserves the saved hand')
    ns.Options:BeginCapture(2)
    assert(not capture.target:IsShown() and not capture.targetLabel:IsShown(), 'mouse bindings have no hand selector')
    capture.scripts.OnKeyDown(capture, 'F8')
    assert(capture.target:IsShown(), 'only a keyboard candidate reveals the hand selector')
    capture.save.scripts.OnClick()
    assert(ns.Database:GetSlots()[2].bind == 'RightButton' and capture.warning.text == ns.L.DUPLICATE_BIND)
    capture.scripts.OnKeyDown(capture, 'ESCAPE')
    assert(not capture.keyboardEnabled and not capture:IsShown())
    ns.Options:BeginCapture(2)
    capture.area.scripts.OnMouseDown(capture.area, 'LeftButton')
    assert(ns.Options.candidate == 'LeftButton', 'ordinary mouse clicks are captured in the dedicated area')
    assert(not capture.target:IsShown(), 'switching to a mouse click hides the hand selector')
    capture.save.scripts.OnClick()
    assert(ns.Database:GetSlots()[2].bind == 'LeftButton')
    ns.Options:BeginCapture(2)
    capture.scripts.OnMouseWheel(capture, -1)
    assert(ns.Options.candidate == 'key:MOUSEWHEELDOWN')
    capture.clear.scripts.OnClick()
    capture.save.scripts.OnClick()
    assert(ns.Database:GetSlots()[2].bind == '')
    ns.Options:BeginCapture(2)
    combat = true
    ns.Core:OnEvent('PLAYER_REGEN_DISABLED')
    assert(not capture.keyboardEnabled and not capture:IsShown())
    combat = false
    ns.Options:BeginCapture(2)
    settings:Hide()
    assert(not capture.keyboardEnabled)
    print('Redesign: native options old/new APIs, 8 visible rows, paging, icon picker, key/click/wheel capture, duplicates, target and capture cleanup passed')
end

if SIMPLEPOISONS_PREVIEW then SIMPLEPOISONS_PREVIEW(ns) end
