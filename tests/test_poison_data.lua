local ns = {}
local counts = { [8927] = 3, [8928] = 2, [3775] = 4 }
local requested = {}

ns.L = { NONE = "None" }
ns.ApiCompat = {
    GetItemCount = function(_, itemID) return counts[itemID] or 0 end,
    GetItemIcon = function(_, itemID) return "icon:" .. itemID end,
    RequestItemData = function(_, itemID) requested[itemID] = true end,
    IsTBC = function() return false end,
}

assert(loadfile("PoisonData.lua"))("SimplePoisons", ns)

assert(ns.PoisonData:GetAvailableItem("instant") == 8928)
assert(ns.PoisonData:GetStock("instant") == 5)
assert(ns.PoisonData:GetAvailableItem("crippling") == 3775)
assert(ns.PoisonData:GetAvailableItem("deadly") == nil)
assert(ns.PoisonData:GetRepresentativeIcon("instant") == "icon:8928")
assert(#ns.PoisonData:GetOptions() == 6)
ns.PoisonData:RequestItemData()
assert(requested[6947] and requested[8928] and requested[9187])

print("poison data tests passed")
