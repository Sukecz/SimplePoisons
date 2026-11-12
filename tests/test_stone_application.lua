local ns = {}
for _, path in ipairs({ "Locales/enUS.lua", "Defaults.lua", "Bindings.lua", "ApiCompat.lua", "PoisonData.lua",
    "SharpeningData.lua", "ApplicationData.lua", "Database.lua", "SecureActions.lua" }) do
    assert(loadfile(path))("SimplePoisons", ns)
end
local counts, levels, level = {}, {}, 70
UnitClass = function() return "Warrior", "WARRIOR" end
UnitLevel = function() return level end
GetItemCount = function(id) return counts[id] or 0 end
GetItemInfo = function(id) return nil, nil, nil, nil, levels[id] end
IsUsableItem = function() return false end
WOW_PROJECT_BURNING_CRUSADE_CLASSIC, WOW_PROJECT_CAMELOT = 5, 18
-- Independent item fixtures from each client's tooltips, not generated from the catalog.
local rows = {
    { 40, 2862, 1800 }, { 13, 2863, 1800 }, { 14, 2871, 1800 },
    { 483, 7964, 1800 }, { 1643, 12404, 1800 }, { 2506, 18262, 1800 },
    { 19, 3239, 1800 }, { 20, 3240, 1800 }, { 21, 3241, 1800 },
    { 484, 7965, 1800 }, { 1703, 12643, 1800 },
    { 2954, 28420, 3600 }, { 2955, 28421, 3600 },
    { 2684, 23122, 3600 }, { 2712, 23528, 3600 }, { 2713, 23529, 3600 },
}
for _, project in ipairs({ 2, 5, 18 }) do
    WOW_PROJECT_ID = project
    ns.Database:Initialize({})
    assert(#ns.SharpeningData:GetOptions() == (project == 5 and 18 or 14))
    assert(not ns.ApplicationData:GetAvailableItem("instant"), "Warriors cannot bind poisons")
    for _, row in ipairs(rows) do
        local key, id = "stone:" .. row[1], row[2]
        local valid = project == 5 or (id ~= 23528 and id ~= 23529 and id ~= 28420 and id ~= 28421)
        assert(ns.Database:SetClick("LeftButton", key) == valid)
        if valid then
            assert(ns.SharpeningData:GetDuration(ns.SharpeningData:GetChoice(key))
                == (project == 5 and 3600 or row[3]))
            counts[id] = 5
            for _, click in ipairs({ "LeftButton", "RightButton", "MiddleButton" }) do
                assert(ns.Database:SetClick(click, key))
            end
            for _, slot in ipairs({ 16, 17 }) do
                local attrs = {}
                local button = { slotID = slot, SetAttribute = function(_, k, v) attrs[k] = v end }
                ns.SecureActions:ConfigureButton(button)
                for suffix = 1, 3 do
                    assert(attrs["macrotext" .. suffix] == string.format("/use item:%d\n/use %d", id, slot))
                end
            end
            counts[id] = 0
            assert(not ns.ApplicationData:GetAvailableItem(key))
        end
    end
end
WOW_PROJECT_ID = 18
counts[287980], counts[18262] = 5, 5
assert(ns.ApplicationData:GetAvailableItem("stone:2506") == 287980)
levels[287980], level = 50, 49
assert(ns.ApplicationData:GetAvailableItem("stone:2506") == 18262, "metadata excludes an ineligible variant")
levels[287980] = nil
assert(ns.ApplicationData:GetAvailableItem("stone:2506") == 287980, "cold cache retains hardware click")
WOW_PROJECT_ID = 2
assert(ns.ApplicationData:GetAvailableItem("stone:2506") == 18262, "Forever ID must not leak into Era")
assert(not ns.ApplicationData:IsAvailableChoice("stone:7098"), "SoD stone must not appear on normal Era/Forever")
Enum = { SeasonID = { SeasonOfDiscovery = 2 } }
C_Seasons = { GetActiveSeason = function() return 2 end }
counts[238241] = 5
assert(ns.ApplicationData:GetAvailableItem("stone:2684") == 238241)
assert(ns.ApplicationData:IsAvailableChoice("stone:7098"))
assert(ns.SharpeningData:GetDuration(ns.SharpeningData:GetChoice("stone:7098")) == 1800)
assert(#ns.SharpeningData:GetOptions() == 15)
print("Stone application: full Era/TBC/Forever catalog, durations, aliases, Warrior, all clicks and hands passed")

-- Mixed bags: max flat damage ignores situational crit/undead/BFD stones.
C_Seasons, Enum = nil, nil
counts = { [23529] = 2, [23528] = 2, [12404] = 2, [7964] = 2, [2862] = 2,
    [18262] = 2, [23122] = 2, [211845] = 2 }
levels = { [23529] = 60, [23528] = 50, [12404] = 35, [7964] = 25 }
level = 70
for _, project in ipairs({ 2, 18, 5 }) do
    WOW_PROJECT_ID = project
    ns.Database:Initialize({})
    assert(ns.Database:SetClick("LeftButton", "stone:auto"))
    assert(ns.Database:Initialize(SimplePoisonsDB).clicks.LeftButton == "stone:auto")
    assert(ns.ApplicationData:GetAvailableItem("stone:auto") == (project == 5 and 23529 or 12404))
end
level = 59
assert(ns.ApplicationData:GetAvailableItem("stone:auto") == 23528)
level = 49
assert(ns.ApplicationData:GetAvailableItem("stone:auto") == 12404)
counts[12404] = 0
assert(ns.ApplicationData:GetAvailableItem("stone:auto") == 7964)
level = 24
assert(ns.ApplicationData:GetAvailableItem("stone:auto") == 2862)
counts[2862] = 0
assert(not ns.ApplicationData:GetAvailableItem("stone:auto"))
assert(ns.ApplicationData:GetItemLabel("stone:auto", 23529) == "Adamantite Sharpening Stone")
assert(ns.ApplicationData:GetLabel("stone:auto") == ns.SharpeningData.AUTO_LABEL)
print("Auto stone: mixed stock, client and level restrictions, fallback, persistence and exact item label passed")

-- Weightstone auto has independent stock/level fallback on every client.
counts = { [28421] = 2, [28420] = 2, [12643] = 2, [7965] = 2, [3239] = 2, [12404] = 2 }
levels = { [28421] = 60, [28420] = 50, [12643] = 35, [7965] = 25 }
level = 70
for _, project in ipairs({ 2, 5, 18 }) do
    WOW_PROJECT_ID = project
    ns.Database:Initialize({})
    assert(ns.Database:SetClick("LeftButton", "weight:auto"))
    assert(ns.Database:Initialize(SimplePoisonsDB).clicks.LeftButton == "weight:auto")
    assert(ns.ApplicationData:GetAvailableItem("weight:auto") == (project == 5 and 28421 or 12643))
end
WOW_PROJECT_ID = 5
level = 59
assert(ns.ApplicationData:GetAvailableItem("weight:auto") == 28420)
level = 49
assert(ns.ApplicationData:GetAvailableItem("weight:auto") == 12643)
counts[12643] = 0
assert(ns.ApplicationData:GetAvailableItem("weight:auto") == 7965)
level = 24
assert(ns.ApplicationData:GetAvailableItem("weight:auto") == 3239)
counts[3239] = 0
assert(not ns.ApplicationData:GetAvailableItem("weight:auto"), "never substitute a sharpening stone")
assert(ns.ApplicationData:GetItemLabel("weight:auto", 28421) == "Adamantite Weightstone")
print("Weightstone auto: all clients, persistence, level and stock fallback passed")

-- Only Rogues can see or persist poison selections; old Warrior defaults migrate.
for _, class in ipairs({ "WARRIOR", "PALADIN", "HUNTER", "SHAMAN", "DRUID", "MAGE" }) do
    UnitClass = function() return class, class end
    local data = ns.Database:Initialize({ clicks = {
        LeftButton = "instant", RightButton = "stone:483", MiddleButton = "wound" },
        hands = "MAIN", scale = 1.2 })
    assert(data.clicks.LeftButton == "stone:auto" and data.clicks.MiddleButton == "stone:auto")
    assert(data.clicks.RightButton == "stone:483" and data.hands == "MAIN" and data.scale == 1.2)
    assert(not ns.Database:SetClick("LeftButton", "instant"))
    for _, option in ipairs(ns.ApplicationData:GetOptions()) do
        assert(not ns.PoisonData:IsValidFamily(option.value), class .. " must see stones only")
    end
end
UnitClass = function() return "Rogue", "ROGUE" end
ns.Database:Initialize({})
assert(ns.Database:GetClick("LeftButton") == "instant")
assert(ns.Database:SetClick("LeftButton", "deadly"))
local poisonSeen, stoneSeen = false, false
for _, option in ipairs(ns.ApplicationData:GetOptions()) do
    poisonSeen = poisonSeen or option.value == "instant"
    stoneSeen = stoneSeen or option.value == "stone:auto"
end
assert(poisonSeen and stoneSeen, "Rogues retain both poisons and stones")
print("Class choices: non-Rogues see stones only, old defaults migrate, Rogue poisons preserved")
