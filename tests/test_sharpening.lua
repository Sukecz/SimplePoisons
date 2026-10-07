local ns = { Constants = { MAIN_HAND_SLOT = 16 }, L = { NONE = "None" } }
for _, path in ipairs({ "ApiCompat.lua", "PoisonData.lua", "SharpeningData.lua", "Buttons.lua" }) do
    assert(loadfile(path))("SimplePoisons", ns)
end

local expected = {
    { 40, 2862 }, { 13, 2863 }, { 14, 2871 }, { 483, 7964 },
    { 1643, 12404 }, { 2506, 18262 }, { 2684, 23122 },
    { 2712, 23528 }, { 2713, 23529 }, { 7098, 211845 },
}
GetInventoryItemID = function() return 12345 end
GetInventoryItemTexture = function(slot) return "weapon" end
GetItemIcon = function(id) return "icon:" .. id end
GetItemCount = function() error("stone detection must not depend on bags") end
IsUsableItem = function() error("stone detection must not depend on usability") end
WOW_PROJECT_BURNING_CRUSADE_CLASSIC = 5

for _, project in ipairs({ 2, 5, 99 }) do
    WOW_PROJECT_ID = project
    for _, row in ipairs(expected) do
        local enchant, item = unpack(row)
        local available = project == 5 or (enchant ~= 2712 and enchant ~= 2713)
        for _, api in ipairs({ "legacy", "paperDoll", "item" }) do
            C_Item, C_PaperDollInfo, Enum = nil, nil, nil
            GetWeaponEnchantInfo = function()
                return true, 123000, 0, enchant, true, 65000, 0, enchant
            end
            if api == "paperDoll" then
                C_PaperDollInfo = { GetTemporaryEnchantmentInfo = function(slot)
                    return { enchantID = enchant, remainingTimeMs = slot == 16 and 123000 or 65000,
                        chargesRemaining = 0, hasExpirationTime = true }
                end }
            elseif api == "item" then
                Enum = { WeaponSlot = { MainHand = 0, OffHand = 1 },
                    ItemEnchantType = { Permanent = 1, Temporary = 2, Imbue = 3 } }
                C_Item = { GetWeaponEnchantInfo = function(slot)
                    return {
                        { hasEnchant = true, enchantType = 1, enchantID = 1900 },
                        { hasEnchant = true, enchantType = 3, enchantID = 999999, timeLeft = 10000 },
                        { hasEnchant = true, enchantType = 2, enchantID = enchant,
                            timeLeft = slot == 0 and 123000 or 65000, charges = 0 },
                    }
                end }
            end
            for _, slot in ipairs({ 16, 17 }) do
                local state = ns.ApiCompat:GetWeaponState(slot)
                assert(state.hasEnchant and state.hasExpirationTime and state.charges == 0)
                assert(state.expirationMS == (slot == 16 and 123000 or 65000))
                assert(ns.ApiCompat:DetectPoisonFamily(slot, enchant) == nil)
                local stone = ns.SharpeningData:GetByEnchantID(tostring(enchant))
                assert((stone ~= nil) == available)
                if available then
                    assert(stone.itemID == item)
                    assert(ns.Buttons:ResolveIcon(state, nil, slot) == "icon:" .. item)
                else
                    assert(ns.Buttons:ResolveIcon(state, nil, slot) == "weapon")
                end
            end
        end
    end
end
WOW_PROJECT_ID = 5
GetItemIcon = function() return nil end
for _, row in ipairs(expected) do
    local stone = ns.SharpeningData:GetByEnchantID(row[1])
    assert(ns.SharpeningData:GetIcon(stone) == "Interface\\Icons\\" .. stone.icon)
    assert(not ns.PoisonData:IsValidFamily(stone.label))
end
assert(not ns.SharpeningData:GetByEnchantID(nil))
assert(not ns.SharpeningData:GetByEnchantID(2626), "oils are not sharpening stones")
assert(not ns.SharpeningData:GetByEnchantID(1703), "weightstones are not sharpening stones")
assert(not ns.SharpeningData:GetByEnchantID(1900), "permanent enchants are not sharpening stones")
print("Sharpening stones: all 10 types, three APIs, both hands, empty bags and icon fallbacks passed")
