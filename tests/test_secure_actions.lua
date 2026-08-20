local ns = {
    ApiCompat = { IsCombatLocked = function() return false end },
    Database = { GetClick = function(_, button) return button end },
    PoisonData = { GetAvailableItem = function(_, family) return family == "LeftButton" and 6947 or nil end },
    Buttons = {},
}

assert(loadfile("SecureActions.lua"))("SimplePoisons", ns)
assert(ns.SecureActions:BuildMacro(6947, 16) == "/use item:6947\n/use 16")
assert(ns.SecureActions:BuildMacro(nil, 16) == nil)

local attributes = {}
local button = {
    slotID = 17,
    SetAttribute = function(_, key, value) attributes[key] = value end,
}
ns.SecureActions:ConfigureButton(button)
assert(attributes.type1 == "macro")
assert(attributes.macrotext1 == "/use item:6947\n/use 17")
assert(attributes.type2 == nil and attributes.macrotext2 == nil)
assert(button.availableItems.LeftButton == 6947)

ns.ApiCompat.IsCombatLocked = function() return true end
ns.SecureActions:ConfigureButton(button)
assert(ns.SecureActions.refreshPending == true)

print("secure action tests passed")
