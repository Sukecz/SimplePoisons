local ns = {}
local combat = false
for _, path in ipairs({ "Locales/enUS.lua", "Defaults.lua", "Bindings.lua", "PoisonData.lua", "SharpeningData.lua",
    "ApiCompat.lua", "ApplicationData.lua", "Database.lua", "SecureActions.lua" }) do
    assert(loadfile(path))("SimplePoisons", ns)
end
ns.ApiCompat.IsCombatLocked = function() return combat end
ns.ApiCompat.IsRogue = function() return true end
ns.ApiCompat.GetItemCount = function() return 10 end
local legacy = { clicks = { LeftButton = "wound", RightButton = "instant", MiddleButton = "mindNumbing" },
    scale = 1.2, showMinimap = false, position = { point = "TOP", x = 90, y = -80 } }
local data = ns.Database:Initialize(legacy)
assert(#data.slots == 3 and data.slots[1].choice == "wound" and data.slots[3].choice == "mindNumbing")
assert(data.scale == 1.2 and not data.showMinimap and data.position.x == 90)
assert(legacy.slots == nil, "migration does not mutate the input")
for index, bind in ipairs({ "shift-LeftButton", "ctrl-RightButton", "alt-MiddleButton" }) do
    assert(ns.Database:SetSlot(index, bind, data.slots[index].choice), "every default bind is editable")
end
assert(not ns.Database:GetClick("LeftButton"))
assert(not ns.Database:SetSlot(2, "shift-LeftButton", "deadly"), "duplicates must be rejected")
assert(ns.Database:AddSlot())
assert(data.slots[4].bind == "", "new rows wait for an explicit binding")
local function makeButton(slot)
    return { slotID = slot, SetAttribute = function(self, key, value)
        assert(not combat, "secure changes in combat")
        self[key] = value
    end }
end
ns.Buttons = { mainButton = makeButton(16), offButton = makeButton(17) }
ns.SecureActions:RefreshAll()
local main, off = ns.Buttons.mainButton, ns.Buttons.offButton
assert(main['shift-macrotext1'] == '/use item:10922\n/use 16')
assert(off['shift-macrotext1'] == '/use item:10922\n/use 17')
assert(main['ctrl-shift-type1'] == '', "unassigned modifiers must not fall through to plain clicks")
assert(ns.Database:SetSlot(1, 'alt-ctrl-shift-Button5', 'deadly'))
ns.SecureActions:RefreshAll()
assert(main['shift-type1'] == '' and not main['shift-macrotext1'], "clear the old bind")
assert(main['alt-ctrl-shift-macrotext5'] == '/use item:20844\n/use 16')
IsAltKeyDown = function() return true end
IsControlKeyDown = function() return true end
IsShiftKeyDown = function() return true end
assert(ns.Bindings:Current('Button5') == 'alt-ctrl-shift-Button5')
assert(ns.Database:RemoveSlot(1))
ns.SecureActions:RefreshAll()
assert(not main['alt-ctrl-shift-macrotext5'], "remove the old secure action")
local expected = {}
for index, slot in ipairs(data.slots) do expected[index] = slot.bind .. ':' .. slot.choice end
for reload = 1, 3 do
    data = ns.Database:Initialize(SimplePoisonsDB)
    assert(#data.slots == #expected)
    for index, slot in ipairs(data.slots) do assert(slot.bind .. ':' .. slot.choice == expected[index]) end
end
combat = true
assert(not ns.Database:AddSlot() and not ns.Database:RemoveSlot(1))
assert(not ns.Database:SetSlot(1, 'Button5', 'instant'))
ns.SecureActions:RefreshAll()
assert(ns.SecureActions.refreshPending)
combat = false
ns.SecureActions:OnCombatEnded()
while ns.Database:AddSlot() do end
assert(#data.slots == 40 and not ns.Database:AddSlot(), 'finite assignment capacity')
while #data.slots > 1 do assert(ns.Database:RemoveSlot(1)) end
assert(not ns.Database:RemoveSlot(1))
data = ns.Database:Initialize(SimplePoisonsDB)
assert(#data.slots == 1, 'do not recreate three defaults after user removal')
print('Slots: legacy migration, all defaults editable, duplicates, both hands, modifiers, stale attributes, combat, reload and capacity passed')
