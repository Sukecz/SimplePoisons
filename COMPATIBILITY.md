# Compatibility

SimplePoisons targets WoW Classic Era, Classic Hardcore, Burning Crusade
Classic, and the WoW Forever beta with a Lua 5.1-compatible codebase. TBC
support targets client 2.5.6 (Interface 20506) and the `tbc` game type. Forever
support begins with client 1.60.1 (Interface 16001) and uses the client's
`camelot` game type.

The addon prefers `C_Item.GetWeaponEnchantInfo()` where available on current
Forever builds, with `C_PaperDollInfo.GetTemporaryEnchantmentInfo()` for older
Forever builds and the legacy `GetWeaponEnchantInfo()` fallback on Era and TBC.
The current API uses `Enum.WeaponSlot` rather than inventory slot IDs; permanent
enchants are ignored and a known poison takes priority over other imbues.
Dedicated `WEAPON_ENCHANT_CHANGED` and `WEAPON_SLOT_CHANGED` events refresh the
monitor even when neither button has an active timer. Known poison
enchant IDs identify the displayed family directly, with a hidden inventory
tooltip as a fallback. Protected macro buttons keep application user-initiated.

Run `/sp api` in each client and record the reported build before treating a
client as verified. Static tests and file deployment do not prove live secure
click behavior, poison replacement confirmation behavior, or rendered
geometry. Forever is beta software and its API or poison data can still change.

## Poison catalog audit (2026-09-19)

All 20 Era/Forever items and their enchant IDs, and all 25 TBC items and their
enchant IDs, were checked against the corresponding Wowhead client database.
The complete catalog is covered by `tests/test_poison_data.lua`.

- Era and Forever: Instant I-VI, Deadly I-V, Crippling I-II, Wound I-IV,
  and Mind-numbing I-III.
- TBC additionally has Instant VII, Deadly VI-VII, Wound V, and Anesthetic I.
- Duration and charges come from the client API, not catalog constants. For
  example, Instant VI currently has 115 charges in Era and 175 in Forever;
  TBC poisons last one hour without charges.

Reference records: [Era Instant VI](https://www.wowhead.com/classic/item=8928),
[Forever Instant VI](https://www.wowhead.com/forever/spell=11340),
[TBC Instant VII](https://www.wowhead.com/tbc/spell=26891).
Forever API signatures and secure macro support were checked in Blizzard's
[exported UI sources](https://github.com/Gethe/wow-ui-source/tree/forever/Interface/AddOns).

## Live client checks still required

Repeat on Era, TBC, and Forever with `/sp api` recorded:

1. Apply each configured click to MH and OH; verify replacement confirmation
   and cancel a cast to confirm the displayed poison does not change early.
2. Carry usable and too-high-level ranks together; confirm the bound rank and
   its stock in the tooltip, including after leveling up or running out.
3. Open settings before entering combat; try every slider. Confirm values
   stay unchanged, and bag changes refresh click assignments after combat.
4. Apply an oil or sharpening stone; verify the neutral weapon icon and border.
5. Start with no poison, apply one, and let it expire or exhaust its charges;
   verify the timer wakes up and the missing state returns. Check TBC without
   charge warnings and Forever with the client's current charge counts.
