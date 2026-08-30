local ns = { Constants = { MAIN_HAND_SLOT = 16 } }
local requested

C_Item = {
    RequestLoadItemDataByID = function(itemID) requested = itemID end,
}

assert(loadfile("ApiCompat.lua"))("SimplePoisons", ns)
ns.ApiCompat:RequestItemData(8928)
assert(requested == 8928)

C_Item = nil
local fallbackRequested
GetItemInfo = function(itemID) fallbackRequested = itemID end
ns.ApiCompat:RequestItemData(9187)
assert(fallbackRequested == 9187)

print("API compatibility tests passed")
