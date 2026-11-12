local ns, combat = {}, false
for _, path in ipairs({ 'Locales/enUS.lua', 'Defaults.lua', 'Bindings.lua', 'ApiCompat.lua', 'PoisonData.lua',
    'SharpeningData.lua', 'ApplicationData.lua', 'Database.lua', 'SecureActions.lua' }) do
    assert(loadfile(path))('SimplePoisons', ns)
end
UIParent = {}
local function frame()
    return {
        attributes = {},
        SetAttribute = function(self, key, value) assert(not combat); self.attributes[key] = value end,
        RegisterForClicks = function(self, value) self.clicks = value end,
    }
end
CreateFrame = function(_, name) local result = frame(); _G[name] = result; return result end
ns.Buttons = { mainButton = frame(), offButton = frame() }
ns.Buttons.mainButton.slotID, ns.Buttons.offButton.slotID = 16, 17
local overrides, clears = {}, 0
ClearOverrideBindings = function(owner)
    assert(not combat and owner ~= ns.Buttons.mainButton, 'global keys use an independent owner')
    overrides, clears = {}, clears + 1
end
SetOverrideBindingClick = function(_, priority, key, name, mouse)
    assert(not combat and priority and mouse == 'LeftButton')
    overrides[key] = name
end
ns.ApiCompat.IsCombatLocked = function() return combat end
ns.ApiCompat.IsRogue = function() return true end
local stock = 10
ns.ApiCompat.GetItemCount = function() return stock end
ns.Database:Initialize({ clicks = { LeftButton = 'wound', RightButton = 'deadly', MiddleButton = 'instant' } })
assert(ns.Database:GetSlots()[1].bind == 'LeftButton' and ns.Database:GetSlots()[1].choice == 'wound')
assert(ns.Database:SetSlot(1, 'key:CTRL-F8', 'wound', 17))
assert(ns.Database:AddSlot() and ns.Database:AddSlot())
assert(ns.Database:GetSlots()[4].bind == '' and ns.Database:GetSlots()[5].bind == '')
ns.Database:Initialize(SimplePoisonsDB)
assert(#ns.Database:GetSlots() == 5 and ns.Database:GetSlots()[1].target == 17)
assert(not ns.Database:SetSlot(2, 'key:CTRL-F8', 'deadly'))
assert(not ns.Bindings:IsValid('key:BUTTON1') and not ns.Bindings:IsValid('key:ESCAPE'))
IsAltKeyDown = function() return true end
IsControlKeyDown = function() return true end
IsShiftKeyDown = function() return true end
assert(ns.Bindings:Capture('LeftButton', true) == 'alt-ctrl-shift-LeftButton')
assert(ns.Bindings:Capture('F8') == 'key:ALT-CTRL-SHIFT-F8')
assert(ns.Bindings:Capture('MOUSEWHEELUP') == 'key:ALT-CTRL-SHIFT-MOUSEWHEELUP')
assert(not ns.Bindings:Capture('LCTRL') and not ns.Bindings:Capture('UNKNOWN'))
for _, key in ipairs({ 'NUMPAD1', 'OEM_102', 'A', '-', ';', 'ů' }) do assert(ns.Bindings:Capture(key)) end
ns.SecureActions:RefreshAll()
local action = _G[overrides['CTRL-F8']]
assert(action and action.clicks == 'AnyUp' and action.attributes.useOnKeyDown == false)
assert(action.attributes.macrotext == '/use item:10922\n/use 17')
assert(ns.SecureActions.keyState['key:CTRL-F8'].itemID == 10922)
local count = clears
combat = true
stock = 0
ns.SecureActions:RefreshAll()
ns.SecureActions:RefreshKeyboard()
assert(clears == count and action.attributes.macrotext and ns.SecureActions.refreshPending)
combat = false
ns.SecureActions:OnCombatEnded()
assert(not action.attributes.macrotext and overrides['CTRL-F8'], 'keep the binding reserved with empty bags')
stock = 10
assert(ns.Database:SetSlot(1, 'key:SHIFT-MOUSEWHEELUP', 'instant', 16))
ns.SecureActions:RefreshAll()
assert(not overrides['CTRL-F8'])
assert(_G[overrides['SHIFT-MOUSEWHEELUP']].attributes.macrotext == '/use item:8928\n/use 16')
assert(ns.Database:RemoveSlot(1))
ns.SecureActions:RefreshAll()
assert(not next(overrides) and not action.attributes.macrotext, 'removal clears stale global bindings and actions')
print('Keyboard: migration, unbound rows, key/mouse/wheel capture, explicit hand, global binding cleanup, stock and combat deferral passed')


-- Keep the normal weapon-window click and a global keyboard alternative for
-- the same poison at once. Adding/removing the shortcut must preserve clicks.
ns.Database:Initialize({ clicks = { LeftButton = 'instant', RightButton = 'deadly', MiddleButton = 'crippling' } })
assert(ns.Database:AddSlot())
assert(ns.Database:SetSlot(4, 'key:CTRL-F8', 'instant', 17))
ns.Database:Initialize(SimplePoisonsDB)
ns.SecureActions:RefreshAll()
assert(ns.Buttons.mainButton.attributes.macrotext1 == '/use item:8928\n/use 16')
assert(ns.Buttons.offButton.attributes.macrotext1 == '/use item:8928\n/use 17')
assert(_G[overrides['CTRL-F8']].attributes.macrotext == '/use item:8928\n/use 17')
assert(ns.Database:GetSlots()[1].bind == 'LeftButton' and ns.Database:GetSlots()[4].target == 17)
assert(ns.Database:RemoveSlot(4))
ns.SecureActions:RefreshAll()
assert(not overrides['CTRL-F8'])
assert(ns.Buttons.mainButton.attributes.macrotext1 == '/use item:8928\n/use 16')
assert(ns.Buttons.offButton.attributes.macrotext1 == '/use item:8928\n/use 17')
print('Dual input: same poison via both weapon-window clicks and an independent global key, reload and shortcut removal passed')
