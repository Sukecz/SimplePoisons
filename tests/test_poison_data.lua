local ns = {}
local counts = { [8927] = 3, [8928] = 2, [3775] = 4 }
local requested = {}

ns.L = { NONE = "None" }
ns.ApiCompat = {
    IsItemUsable = function() return true end,
    GetItemName = function() return nil end,
    GetItemCount = function(_, itemID) return counts[itemID] or 0 end,
    GetItemIcon = function(_, itemID) return "icon:" .. itemID end,
    RequestItemData = function(_, itemID) requested[itemID] = true end,
    IsTBC = function() return ns.isTBC end,
}

assert(loadfile("PoisonData.lua"))("SimplePoisons", ns)

assert(ns.PoisonData:GetAvailableItem("instant") == 8928)
assert(ns.PoisonData:GetStock("instant") == 5)
assert(ns.PoisonData:GetAvailableItem("crippling") == 3775)
assert(ns.PoisonData:GetAvailableItem("deadly") == nil)
assert(ns.PoisonData:GetRepresentativeIcon("instant") == "icon:8928")
assert(ns.PoisonData:GetFamilyByEnchantID(625) == "instant")
assert(ns.PoisonData:GetFamilyByEnchantID(706) == "wound")
assert(ns.PoisonData:GetFamilyByEnchantID(2640) == nil)
assert(ns.PoisonData:GetFamilyByEnchantID(999999) == nil)
assert(#ns.PoisonData:GetOptions() == 5)
assert(not ns.PoisonData:IsAvailableFamily("anesthetic"))
ns.PoisonData:RequestItemData()
assert(not requested[21835] and not requested[21927] and not requested[22055])
ns.isTBC = true
assert(ns.PoisonData:IsAvailableFamily("anesthetic") == true)
assert(ns.PoisonData:GetFamilyByEnchantID(2640) == "anesthetic")
assert(ns.PoisonData:GetFamilyByEnchantID(2641) == "instant")
assert(ns.PoisonData:GetFamilyByEnchantID(2642) == "deadly")
assert(ns.PoisonData:GetFamilyByEnchantID(2643) == "deadly")
assert(ns.PoisonData:GetFamilyByEnchantID(2644) == "wound")
assert(#ns.PoisonData:GetOptions() == 6)
ns.PoisonData:RequestItemData()
assert(requested[6947] and requested[8928] and requested[21927])
assert(requested[20844] and requested[22053] and requested[22054])
assert(requested[10922] and requested[22055] and requested[21835])
assert(requested[9186])
assert(not requested[9187])

-- Complete catalog fixtures, cross-checked against each client's item effects.
local expected = {
    instant = { "6947,6949,6950,8926,8927,8928", "323,324,325,623,624,625", "21927", "2641" },
    deadly = { "2892,2893,8984,8985,20844", "7,8,626,627,2630", "22053,22054", "2642,2643" },
    crippling = { "3775,3776", "22,603", "", "" },
    wound = { "10918,10920,10921,10922", "703,704,705,706", "22055", "2644" },
    mindNumbing = { "5237,6951,9186", "35,23,643", "", "" },
    anesthetic = { "21835", "2640", "", "" },
}
for key, fixture in pairs(expected) do
    local family = ns.PoisonData:GetFamily(key)
    assert(table.concat(family.itemIDs, ",") == fixture[1])
    assert(table.concat(family.enchantIDs, ",") == fixture[2])
    assert(table.concat(family.tbcItemIDs or {}, ",") == fixture[3])
    assert(table.concat(family.tbcEnchantIDs or {}, ",") == fixture[4])
    for _, enchantID in ipairs(family.enchantIDs) do
        assert(ns.PoisonData:GetFamilyByEnchantID(enchantID) == key)
    end
    for _, enchantID in ipairs(family.tbcEnchantIDs or {}) do
        assert(ns.PoisonData:GetFamilyByEnchantID(enchantID) == key)
    end
end
ns.isTBC = false
for key, family in pairs(ns.PoisonData.families) do
    for _, enchantID in ipairs(family.enchantIDs) do
        if family.tbcOnly then
            assert(not ns.PoisonData:GetFamilyByEnchantID(enchantID))
        else
            assert(ns.PoisonData:GetFamilyByEnchantID(enchantID) == key)
        end
    end
    for _, enchantID in ipairs(family.tbcEnchantIDs or {}) do
        assert(not ns.PoisonData:GetFamilyByEnchantID(enchantID))
    end
end
ns.isTBC = true

counts[21927] = 10
ns.ApiCompat.IsItemUsable = function(_, itemID) return itemID ~= 21927 and itemID ~= 8928 end
assert(ns.PoisonData:GetAvailableItem("instant") == 8927, "skip unusable higher ranks")
assert(ns.PoisonData:GetStock("instant") == 15, "total stock includes unusable items")
ns.ApiCompat.IsItemUsable = function() return false end
assert(ns.PoisonData:GetAvailableItem("instant") == nil)
ns.ApiCompat.IsItemUsable = function() return true end
assert(ns.PoisonData:GetAvailableItem("instant") == 21927, "rank unlock is reflected")
counts[21927] = 0
assert(ns.PoisonData:GetAvailableItem("instant") == 8928, "fall back after rank runs out")
ns.isTBC = false
counts[21927] = 10
assert(ns.PoisonData:GetAvailableItem("instant") == 8928, "TBC item must not leak into Era/Forever")
ns.L.POISON_RANK = "%s (Rank %d)"
assert(ns.PoisonData:GetItemLabel("instant", 8928) == "Instant Poison (Rank 6)")
ns.ApiCompat.GetItemName = function() return "Localized Instant Poison VI" end
assert(ns.PoisonData:GetItemLabel("instant", 8928) == "Localized Instant Poison VI")

-- Ghost usability must not change either the applied-rank icon or fallback.
ns.ApiCompat.IsItemUsable = function() return false end
assert(ns.PoisonData:GetRepresentativeIcon("instant", 324) == "icon:6949")
assert(ns.PoisonData:GetRepresentativeIcon("crippling", 22) == "icon:3775")
assert(ns.PoisonData:GetRepresentativeIcon("crippling") == "icon:3775")
counts[6949] = 0
assert(ns.PoisonData:GetRepresentativeIcon("instant", 324) == "icon:6949")
ns.isTBC = true
assert(ns.PoisonData:GetRepresentativeIcon("instant", 2641) == "icon:21927")
ns.ApiCompat.GetItemIcon = function() return nil end
assert(ns.PoisonData:GetRepresentativeIcon("instant", 324) == "Interface\\Icons\\Ability_Poisons")

print("poison data tests passed")
