local ns = { Constants = { MAIN_HAND_SLOT = 16 }, L = { NONE = "None" } }
assert(loadfile("ApiCompat.lua"))("SimplePoisons", ns)
assert(loadfile("PoisonData.lua"))("SimplePoisons", ns)
assert(loadfile("SharpeningData.lua"))("SimplePoisons", ns)
assert(loadfile("Buttons.lua"))("SimplePoisons", ns)

local ghost = false
local stock = { [3776] = 10 }
GetInventoryItemID = function() return 12345 end
GetItemCount = function(itemID) return stock[itemID] or 0 end
GetItemIcon = function(itemID) return "icon:" .. itemID end
IsUsableItem = function() return not ghost end

local function icon(slot)
    local state = ns.ApiCompat:GetWeaponState(slot)
    local family = ns.ApiCompat:DetectPoisonFamily(slot, state.enchantID)
    return ns.Buttons:ResolveIcon(state, family, slot)
end

-- The hands carry different Crippling Poison ranks, with different textures.
GetWeaponEnchantInfo = function()
    return true, 60000, 12, 22, true, 120000, 20, 603
end
for _, project in ipairs({ 2, 5 }) do
    WOW_PROJECT_BURNING_CRUSADE_CLASSIC = 5
    WOW_PROJECT_ID = project
    C_PaperDollInfo = nil
    for _, dead in ipairs({ false, true }) do
        ghost = dead
        assert(icon(16) == "icon:3775")
        assert(icon(17) == "icon:3776")
    end
end

-- Forever uses the modern slot-specific API and the same rank-to-item mapping.
WOW_PROJECT_ID = nil
C_PaperDollInfo = { GetTemporaryEnchantmentInfo = function(slot)
    return { remainingTimeMs = 60000, chargesRemaining = 12,
        enchantID = slot == 16 and 22 or 603 }
end }
ghost = true
stock = {}
assert(icon(16) == "icon:3775")
assert(icon(17) == "icon:3776")

-- Current Forever uses weapon-slot enums and can return several enchant types.
-- Poison icons must still follow each hand's applied rank, with empty bags.
Enum = {
    WeaponSlot = { MainHand = 0, OffHand = 1 },
    ItemEnchantType = { Permanent = 1, Temporary = 2, Imbue = 3 },
}
C_Item = { GetWeaponEnchantInfo = function(weaponSlot)
    return {
        { hasEnchant = true, enchantType = 1, timeLeft = 0, charges = 0, enchantID = 1900 },
        { hasEnchant = true, enchantType = 2, timeLeft = 60000, charges = 12,
            enchantID = weaponSlot == 0 and 22 or 603 },
    }
end }
assert(icon(16) == "icon:3775")
assert(icon(17) == "icon:3776")
C_Item = nil
Enum = nil

-- Every supported enchant resolves its own item texture, even with no stock.
for _, tbc in ipairs({ false, true }) do
    WOW_PROJECT_ID = tbc and 5 or 2
    for key, family in pairs(ns.PoisonData.families) do
        if ns.PoisonData:IsAvailableFamily(key) then
            for rank, enchant in ipairs(family.enchantIDs) do
                assert(ns.PoisonData:GetRepresentativeIcon(key, enchant)
                    == "icon:" .. family.itemIDs[rank])
            end
            if tbc then
                for rank, enchant in ipairs(family.tbcEnchantIDs or {}) do
                    assert(ns.PoisonData:GetRepresentativeIcon(key, enchant)
                        == "icon:" .. family.tbcItemIDs[rank])
                end
            end
        end
    end
end
WOW_PROJECT_ID = 2
stock[3775] = 3
assert(ns.PoisonData:GetRepresentativeIcon("crippling") == "icon:3775")
GetItemIcon = function() return nil end
assert(ns.PoisonData:GetRepresentativeIcon("crippling", 22)
    == "Interface\\Icons\\Ability_Poisons")
print("Applied poison icons: Era, TBC, Forever, ghost, both hands and all ranks passed")
