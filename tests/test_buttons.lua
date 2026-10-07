local ns = {
    Constants = {},
    PoisonData = {
        GetRepresentativeIcon = function(_, family, enchantID)
            return "poison:" .. family .. (enchantID and ":" .. enchantID or "")
        end,
    },
    ApiCompat = {
        GetWeaponTexture = function(_, slotID) return "weapon:" .. slotID end,
    },
}

assert(loadfile("SharpeningData.lua"))("SimplePoisons", ns)
assert(loadfile("Buttons.lua"))("SimplePoisons", ns)

assert(ns.Buttons:ResolveIcon({ hasEnchant = true }, "instant", 16) == "poison:instant")
assert(ns.Buttons:ResolveIcon({ hasEnchant = true }, nil, 16)
    == "weapon:16")
assert(ns.Buttons:ResolveIcon({ hasEnchant = false }, nil, 16) == "weapon:16")

print("button tests passed")

assert(ns.Buttons:ResolveIcon({ hasEnchant = true, enchantID = 324 }, "instant", 16)
    == "poison:instant:324")
