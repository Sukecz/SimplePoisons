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

Rank selection uses bag stock, Rogue class and the cached `itemMinLevel` from
`C_Item.GetItemInfo()` or legacy `GetItemInfo()`. It does not gate secure macros
on the transient `IsUsableItem()` result. With uncached metadata, the highest
owned rank stays bound and Blizzard validates the hardware click. Both
`GET_ITEM_INFO_RECEIVED` and `ITEM_DATA_LOAD_RESULT` refresh assignments;
combat delays secure changes until `PLAYER_REGEN_ENABLED`. The modern item
signature and load event are documented in Blizzard's
[exported Classic API source](https://github.com/Gethe/wow-ui-source/blob/classic/Interface/AddOns/Blizzard_APIDocumentationGenerated/ItemDocumentation.lua).

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

## Sharpening stone catalog audit (2026-10-07)

Monitoring uses `SharpeningData.lua`, independently of poison selection and
secure application. Icons have an exact texture fallback when item data is
uncached. Remaining time comes from the same three client API paths as poison;
no duration is inferred from the item description. Stones retain a gray border
and do not receive poison charge or low-time warnings.

| Stone | Item ID | Enchant ID | Catalog |
| --- | --- | --- | --- |
| Rough | 2862 | 40 | Era / TBC / Forever |
| Coarse | 2863 | 13 | Era / TBC / Forever |
| Heavy | 2871 | 14 | Era / TBC / Forever |
| Solid | 7964 | 483 | Era / TBC / Forever |
| Dense | 12404 | 1643 | Era / TBC / Forever |
| Elemental | 18262 | 2506 | Era / TBC / Forever |
| Consecrated | 23122 | 2684 | Era / TBC / Forever; event availability varies |
| Fel | 23528 | 2712 | TBC |
| Adamantite | 23529 | 2713 | TBC |
| Blackfathom | 211845 | 7098 | SoD data; recognized wherever the client exposes it |

Item names, icons and use-spell links were checked in Wowhead's `classic`,
`tbc` and `forever` item tooltip catalogs. Blackfathom exists in the Forever
database too; a database record alone does not prove live server availability.
Effect-to-enchant references:
[Rough](https://www.wowhead.com/classic/spell=2828/sharpen-blade),
[Coarse](https://www.wowhead.com/classic/spell=2829/sharpen-blade-ii),
[Heavy](https://www.wowhead.com/classic/spell=2830/sharpen-blade-iii),
[Solid](https://www.wowhead.com/classic/spell=9900/sharpen-blade-iv),
[Dense](https://www.wowhead.com/classic/spell=16138/sharpen-blade-v),
[Elemental](https://www.wowhead.com/classic/spell=22756/sharpen-weapon-critical),
[Forever Elemental](https://www.wowhead.com/forever/spell=22756/sharpen-weapon-critical),
[Consecrated](https://www.wowhead.com/classic/spell=28891/consecrated-weapon),
[Fel](https://www.wowhead.com/tbc/spell=29452/sharpen-blade),
[Adamantite](https://www.wowhead.com/tbc/spell=29453/sharpen-blade),
[Blackfathom](https://www.wowhead.com/classic/spell=430392/sharpen-weapon-hit).

`tests/test_sharpening.lua` covers all ten records, both hands, all three API
shapes, client gating and uncached icons. UI tests cover combat replacement,
tooltip identity, countdown, expiration and unchanged poison click macros.
These are simulated checks; live client verification remains required.

## Live client checks still required

Repeat on Era, TBC, and Forever with `/sp api` recorded:

1. Apply each configured click to MH and OH; verify replacement confirmation
   and cancel a cast to confirm the displayed poison does not change early.
2. Carry usable and too-high-level ranks together; confirm the bound rank and
   its stock in the tooltip, including after leveling up or running out.
3. Open settings before entering combat; try every slider. Confirm values
   stay unchanged, and bag changes refresh click assignments after combat.
4. Apply a sharpening stone to each hand; verify its exact icon, name, gray
   border and remaining time, including in combat, with empty bags and after
   relog. Replace it with poison and let it expire; check identity and missing
   state. Unrecognized enchants and oils retain the neutral weapon icon.
5. Start with no poison, apply one, and let it expire or exhaust its charges;
   verify the timer wakes up and the missing state returns. Check TBC without
   charge warnings and Forever with the client's current charge counts.
6. Log in or reload with poisons already in bags, including after death and
   while item data is loading. Verify click assignments remain present, work
   after revival, and update too-high-level ranks when metadata arrives.
