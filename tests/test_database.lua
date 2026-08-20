local ns = {}

assert(loadfile("Defaults.lua"))("SimplePoisons", ns)
ns.L = { NONE = "None" }
ns.ApiCompat = { IsTBC = function() return false end }
assert(loadfile("PoisonData.lua"))("SimplePoisons", ns)
assert(loadfile("Database.lua"))("SimplePoisons", ns)

local data = ns.Database:Initialize({
    clicks = { LeftButton = "bad", RightButton = "wound", MiddleButton = "instant" },
    lowMinutes = 999,
    lowCharges = -3,
    scale = 4,
    orientation = "SIDEWAYS",
    position = { point = "INVALID", x = 9000, y = -9000 },
})

assert(data.clicks.LeftButton == "instant")
assert(data.clicks.RightButton == "wound")
assert(data.lowMinutes == 30)
assert(data.lowCharges == 1)
assert(data.scale == 1.6)
assert(data.orientation == "HORIZONTAL")
assert(data.position.point == "CENTER")
assert(data.position.x == 5000 and data.position.y == -5000)
assert(data.showMinimap == true)

assert(ns.Database:SetClick("LeftButton", "deadly"))
assert(ns.Database:GetClick("LeftButton") == "deadly")
assert(not ns.Database:SetClick("Button4", "deadly"))
assert(not ns.Database:SetClick("LeftButton", "invalid"))

local defaults = ns.Database:Reset()
assert(defaults.lowMinutes == 3)
assert(defaults.lowCharges == 10)

print("database tests passed")
