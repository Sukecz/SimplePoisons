local ns = {}

assert(loadfile("Defaults.lua"))("SimplePoisons", ns)
assert(loadfile("Bindings.lua"))("SimplePoisons", ns)
ns.L = { NONE = "None" }
ns.ApiCompat = { IsRogue = function() return true end, IsTBC = function() return false end }
assert(loadfile("PoisonData.lua"))("SimplePoisons", ns)
assert(loadfile("SharpeningData.lua"))("SimplePoisons", ns)
assert(loadfile("ApplicationData.lua"))("SimplePoisons", ns)
assert(loadfile("Database.lua"))("SimplePoisons", ns)

local data = ns.Database:Initialize({
    clicks = { LeftButton = "bad", RightButton = "wound", MiddleButton = "instant" },
    lowMinutes = 999,
    lowCharges = -3,
    scale = 4,
    textSize = 99,
    orientation = "SIDEWAYS",
    position = { point = "INVALID", x = 9000, y = -9000 },
})

assert(data.clicks.LeftButton == "instant")
assert(data.clicks.RightButton == "wound")
assert(data.lowMinutes == 30)
assert(data.lowCharges == 1)
assert(data.scale == 1.6)
assert(data.textSize == 18)
assert(data.orientation == "HORIZONTAL")
assert(data.position.point == "CENTER")
assert(data.position.x == 5000 and data.position.y == -5000)
assert(data.showMinimap == true)
assert(data.showSettingsIcon == true, "existing characters keep the settings icon")
assert(data.showHandLabels == true, "existing characters keep MH/OH labels")
assert(data.soundAlerts == false and data.healthyPoisonOpacity == 100,
    "old characters keep silent reminders and fully visible buttons")
assert(data.reminderVolume == 100)
assert(ns.Database:Set("showHandLabels", false))
assert(ns.Database:Set("showSettingsIcon", false))
assert(ns.Database:Set("soundAlerts", true))
assert(ns.Database:Set("reminderVolume", 43))
assert(ns.Database:Set("healthyPoisonOpacity", -15))
data = ns.Database:Initialize(SimplePoisonsDB)
assert(data.showSettingsIcon == false, "hidden settings icon survives reload")
assert(data.showHandLabels == false, "hidden MH/OH labels survive reload")
assert(data.soundAlerts and data.healthyPoisonOpacity == 0, "reminder preferences survive reload, including 0%")
assert(data.reminderVolume == 40, "volume snaps to an available gain and survives reload")
assert(ns.Database:Set("reminderVolume", -1) and data.reminderVolume == 0)
assert(ns.Database:Set("reminderVolume", 310) and data.reminderVolume == 300)
assert(ns.Database:Set("healthyPoisonOpacity", 150) and data.healthyPoisonOpacity == 100)

assert(ns.Database:SetClick("LeftButton", "deadly"))
assert(ns.Database:GetClick("LeftButton") == "deadly")
assert(not ns.Database:SetClick("Button4", "deadly"))
assert(not ns.Database:SetClick("LeftButton", "invalid"))
assert(not ns.Database:SetClick("LeftButton", "anesthetic"))

local defaults = ns.Database:Reset()
assert(defaults.lowMinutes == 3)
assert(defaults.lowCharges == 10)
assert(defaults.textSize == 13)
assert(defaults.showSettingsIcon == true)
assert(defaults.showHandLabels == true)
assert(not defaults.soundAlerts and defaults.healthyPoisonOpacity == 100)
assert(defaults.reminderVolume == 100)

print("database tests passed")
