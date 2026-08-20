# Compatibility

SimplePoisons currently targets WoW Classic Era and Classic Hardcore with a
Lua 5.1-compatible codebase. TBC and other game versions are planned but are
not declared supported by this release.

The addon uses `GetWeaponEnchantInfo()` for duration and charges, a hidden
inventory tooltip only to identify the displayed poison family, and protected
macro buttons for user-initiated application. If tooltip identification fails,
the monitor continues to show time and charges with the equipped weapon icon.

Run `/sp api` in each client and record the reported build before treating a
client as verified. Static tests and file deployment do not prove live secure
click behavior, poison replacement confirmation behavior, tooltip parsing, or
rendered geometry.
