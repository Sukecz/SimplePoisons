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

## Weapon stone catalog audit (2026-11-06)

The [complete catalog and duration sources](docs/sharpening-stones.md) cover
Era/Hardcore, TBC, Forever's additional Elemental item, and SoD variants.
`SharpeningData.lua` owns stone data; `ApplicationData.lua` combines click
choices without changing poison rank selection. Stone clicks have no Rogue
class restriction. The existing hardware-click macros target inventory slot
16 or 17 and remain frozen in combat. Stones can be chosen explicitly or
through Auto, which selects the stone family independently for each weapon.
All five Classic Weightstones are supported on Era/Hardcore and Forever;
TBC additionally supports Fel and Adamantite Weightstones.

Monitoring retains exact icon fallbacks, the neutral gray border and no poison
charge/low-time warnings. Actual remaining time always comes from the client;
catalog durations label the settings choices only. Single-hand visibility and
layout changes defer in combat; hidden-hand timers do not keep polling active.

`tests/test_stone_application.lua` covers every selectable type, all clicks,
both hands, three clients, per-client durations, alternate item IDs, Warrior
class eligibility, cold metadata and stock exhaustion. `tests/test_sharpening.lua`
retains all seventeen enchant mappings and three API paths. UI tests exercise the real
dropdown callbacks, single-hand geometry, persistence, combat guards and timers.
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

7. On a Warrior, select a stone for each mouse button and apply it to the
   intended hand. Test Main hand only with a shield/2H, Off hand only, and Both
   hands in both orientations; reload and confirm saved selections/visibility.
   Open settings before combat and verify neither visibility nor click choices
   can change until combat ends. Test Forever Elemental with item 287980 too.

## Minimap collectors

The installed Leatrix Plus replaces custom minimap buttons and guesses an icon
from their texture regions. SimplePoisons' highlight could be selected instead
of its logo, producing the empty-looking replacement and a custom-button warning.
The launcher now uses existing LibDataBroker/LibDBIcon libraries when available,
with the explicit icon and tooltip. It retries at PLAYER_LOGIN for libraries
loaded after SimplePoisons. The standalone button has a named Icon region for
collectors that inspect it. No external library addon is required.

LibDBIcon position/hide settings bridge to existing per-character values;
negative drag angles normalize to 0–359 and reset follows the new database table.
Library-managed positioning is left to its public API. Reference:
[LibDBIcon registration and visibility API](https://www.wowace.com/projects/libdbicon-1-0).
