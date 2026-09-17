local ns = {}
local counts = { [8927] = 3, [8928] = 2, [3775] = 4 }
local requested = {}

ns.L = { NONE = "None" }
ns.ApiCompat = {
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

print("poison data tests passed")
