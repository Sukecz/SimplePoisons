local ns = {
    Constants = { MAIN_HAND_SLOT = 16 },
    PoisonData = { GetFamilyByEnchantID = function(_, enchantID)
        return enchantID == 625 and "instant" or nil
    end },
}
local requested

C_Item = {
    RequestLoadItemDataByID = function(itemID) requested = itemID end,
}

assert(loadfile("ApiCompat.lua"))("SimplePoisons", ns)
ns.ApiCompat:RequestItemData(8928)
assert(requested == 8928)

C_PaperDollInfo = {
    GetTemporaryEnchantmentInfo = function(slotID)
        assert(slotID == 16)
        return {
            remainingTimeMs = 123000,
            chargesRemaining = 42,
            enchantID = 625,
        }
    end,
}
GetInventoryItemID = function() return 12345 end
local state = ns.ApiCompat:GetWeaponState(16)
assert(state.hasEnchant == true)
assert(state.expirationMS == 123000)
assert(state.charges == 42)
assert(state.enchantID == 625)
assert(state.hasExpirationTime == true)
C_PaperDollInfo.GetTemporaryEnchantmentInfo = function()
    return { remainingTimeMs = 0, chargesRemaining = 0, enchantID = 625, hasExpirationTime = false }
end
state = ns.ApiCompat:GetWeaponState(16)
assert(state.hasEnchant and not state.hasExpirationTime)
C_PaperDollInfo.GetTemporaryEnchantmentInfo = function() return nil end
assert(not ns.ApiCompat:GetWeaponState(16).hasEnchant)

C_PaperDollInfo = nil
GetWeaponEnchantInfo = function()
    return true, 60000, 12, 323, false, nil, nil, nil
end
state = ns.ApiCompat:GetWeaponState(16)
assert(state.hasEnchant == true and state.enchantID == 323)
assert(state.hasExpirationTime == true)
assert(not ns.ApiCompat:GetWeaponState(17).hasEnchant)

assert(ns.ApiCompat:DetectPoisonFamily(16, 625) == "instant")

C_Item = nil
local fallbackRequested
GetItemInfo = function(itemID) fallbackRequested = itemID end
ns.ApiCompat:RequestItemData(9187)
assert(fallbackRequested == 9187)

IsUsableItem = function(itemID) return itemID == 6947, false end
assert(ns.ApiCompat:IsItemUsable(6947))
assert(not ns.ApiCompat:IsItemUsable(8928))
C_Item = { IsUsableItem = function(itemID) return itemID == 8928, false end }
assert(ns.ApiCompat:IsItemUsable(8928))
assert(not ns.ApiCompat:IsItemUsable(6947), "prefer the modern API")
C_Item = nil
IsUsableItem = nil
assert(not ns.ApiCompat:IsItemUsable(6947), "do not assume unknown usability")
WOW_PROJECT_BURNING_CRUSADE_CLASSIC = 5
WOW_PROJECT_ID = 5
assert(ns.ApiCompat:IsTBC())
WOW_PROJECT_ID = 2
assert(not ns.ApiCompat:IsTBC())

print("API compatibility tests passed")
