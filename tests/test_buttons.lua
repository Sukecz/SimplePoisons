local ns = {
    Constants = {},
    PoisonData = {
        GetRepresentativeIcon = function(_, family) return "poison:" .. family end,
    },
    ApiCompat = {
        GetWeaponTexture = function(_, slotID) return "weapon:" .. slotID end,
    },
}

assert(loadfile("Buttons.lua"))("SimplePoisons", ns)

assert(ns.Buttons:ResolveIcon({ hasEnchant = true }, "instant", 16) == "poison:instant")
assert(ns.Buttons:ResolveIcon({ hasEnchant = true }, nil, 16)
    == "Interface\\Icons\\Ability_Poisons")
assert(ns.Buttons:ResolveIcon({ hasEnchant = false }, nil, 16) == "weapon:16")

print("button tests passed")
