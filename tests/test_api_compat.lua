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

-- Current Forever exposes a list of weapon enchants. The older slot API can
-- still exist while returning nil, and must not hide an active poison.
Enum = {
    WeaponSlot = { MainHand = 0, OffHand = 1 },
    ItemEnchantType = { Permanent = 1, Temporary = 2, Imbue = 3 },
}
local enchants = {
    [0] = {
        { hasEnchant = true, enchantType = 1, timeLeft = 0, charges = 0, enchantID = 1900 },
        { hasEnchant = true, enchantType = 3, timeLeft = 30000, charges = 0, enchantID = 999999 },
        { hasEnchant = true, enchantType = 2, timeLeft = 123000, charges = 42, enchantID = 625 },
    },
    [1] = {
        { hasEnchant = true, enchantType = 1, timeLeft = 0, charges = 0, enchantID = 1900 },
    },
}
C_Item.GetWeaponEnchantInfo = function(weaponSlot)
    assert(weaponSlot == 0 or weaponSlot == 1, "use WeaponSlot, not inventory slot 16/17")
    return enchants[weaponSlot]
end
C_PaperDollInfo = { GetTemporaryEnchantmentInfo = function() return nil end }
state = ns.ApiCompat:GetWeaponState(16)
assert(state.hasEnchant and state.enchantID == 625,
    "the current weapon API must detect poison even when the older API returns nil")
assert(state.expirationMS == 123000 and state.charges == 42 and state.hasExpirationTime)
assert(not ns.ApiCompat:GetWeaponState(17).hasEnchant, "permanent enchants are not poisons")
enchants[1] = {
    { hasEnchant = false, enchantType = 2, timeLeft = 0, charges = 0, enchantID = 625 },
}
assert(not ns.ApiCompat:GetWeaponState(17).hasEnchant, "ignore inactive enchant entries")
enchants[1] = {
    { hasEnchant = true, enchantType = 2, timeLeft = 60000, charges = 12, enchantID = 323 },
}
state = ns.ApiCompat:GetWeaponState(17)
assert(state.hasEnchant and state.enchantID == 323 and state.expirationMS == 60000)
enchants[0] = { enchants[0][2] }
state = ns.ApiCompat:GetWeaponState(16)
assert(state.hasEnchant and state.enchantID == 999999, "retain neutral non-poison monitoring")
enchants[0] = {}
assert(not ns.ApiCompat:GetWeaponState(16).hasEnchant,
    "an empty current result must not resurrect stale legacy poison data")
C_Item.GetWeaponEnchantInfo = nil
C_PaperDollInfo = nil
Enum = nil

assert(ns.ApiCompat:DetectPoisonFamily(16, 625) == "instant")

C_Item = nil
local fallbackRequested
GetItemInfo = function(itemID) fallbackRequested = itemID end
ns.ApiCompat:RequestItemData(9187)
assert(fallbackRequested == 9187)

UnitClass = function() return "Rogue", "ROGUE" end
local level = 51
UnitLevel = function(unit) assert(unit == "player"); return level end
IsUsableItem = function() error("transient usability must not gate poison macros") end
C_Item = { IsUsableItem = IsUsableItem }
assert(ns.ApiCompat:CanUsePoisonRank(8928), "uncached data keeps the owned rank bound")
GetItemInfo = function() return "Instant Poison VI", nil, nil, 60, 52 end
assert(not ns.ApiCompat:CanUsePoisonRank(8928), "skip a rank above the player's level")
level = 52
assert(ns.ApiCompat:CanUsePoisonRank(8928), "use minimum level, not item level")
C_Item.GetItemInfo = function() return "Instant Poison VI", nil, nil, 60, 53 end
assert(not ns.ApiCompat:CanUsePoisonRank(8928), "prefer modern item metadata")
C_Item.GetItemInfo = function() return nil end
assert(ns.ApiCompat:CanUsePoisonRank(8928), "modern cold cache must not disable clicks")
UnitClass = function() return "Warrior", "WARRIOR" end
assert(not ns.ApiCompat:CanUsePoisonRank(8928), "only Rogues can use poisons")
UnitClass = function() return "Rogue", "ROGUE" end
C_Item = nil
level = -1
assert(ns.ApiCompat:CanUsePoisonRank(8928), "unknown login level keeps the macro")
UnitLevel = nil
GetItemInfo = nil
assert(ns.ApiCompat:CanUsePoisonRank(8928), "missing metadata API keeps Blizzard validation")
WOW_PROJECT_BURNING_CRUSADE_CLASSIC = 5
WOW_PROJECT_ID = 5
assert(ns.ApiCompat:IsTBC())
WOW_PROJECT_ID = 2
assert(not ns.ApiCompat:IsTBC())

print("API compatibility tests passed")
