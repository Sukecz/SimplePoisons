# Compatibility

SimplePoisons targets WoW Classic Era, Classic Hardcore, and the WoW Forever
beta with a Lua 5.1-compatible codebase. Forever support begins with client
1.60.1 (Interface 16001) and uses the client's `camelot` game type.

The addon uses `C_PaperDollInfo.GetTemporaryEnchantmentInfo()` on Forever and
the legacy `GetWeaponEnchantInfo()` fallback on Era. Known poison enchant IDs
identify the displayed family directly, with a hidden inventory tooltip as a
fallback. Protected macro buttons keep application user-initiated.

Run `/sp api` in each client and record the reported build before treating a
client as verified. Static tests and file deployment do not prove live secure
click behavior, poison replacement confirmation behavior, or rendered
geometry. Forever is beta software and its API or poison data can still change.
