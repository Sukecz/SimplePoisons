# SimplePoisons

![SimplePoisons](assets/logo-wide.png)

SimplePoisons is a focused, dependency-free poison and sharpening-stone monitor
and click-to-apply helper for Rogues, Warriors, and other weapon users in WoW Classic Era, Classic Hardcore, Burning Crusade Classic,
and the WoW Forever beta.
It replaces sprawling poison menus and detached warnings with one compact pair
of weapon buttons.

It keeps everything on two buttons:

- the left button represents the main-hand weapon;
- the right button represents the off-hand weapon;
- weapon labels and charges appear above each button, with remaining time below;
- an orange border means the poison is running low;
- a red border means the weapon has no temporary enchant;
- a gray border and weapon icon indicate an unidentified or other temporary enchant;
- active sharpening stones show their own icon and remaining time with a gray border;
- left, right, and middle click apply three configurable poison families or stones;
- show both weapon buttons, only the main hand, or only the off hand.
- a small gear on the pair and an optional `SP` minimap button open settings;
  both can be hidden independently in settings. `/sp` always opens settings.
  When LibDBIcon and LibDataBroker are supplied by another addon (such as
  Leatrix Plus), SimplePoisons registers a standard launcher so minimap-button
  collectors receive the correct logo, click action and tooltip. Otherwise
  the addon creates its own button; no additional addon installation is needed.

The addon automatically selects the highest owned rank of the configured
poison family that meets the Rogue's level requirement. While item data is
loading, the highest owned rank stays bound and Blizzard validates its use;
the selection updates when the data arrives. Temporary unusability, including
death, does not remove click assignments. Each click's tooltip shows the exact
bound rank and its own stock, including assignments waiting for a combat refresh.

The default low warning appears below 3 minutes or below 10 charges. Both
thresholds are adjustable in the settings window.

Sharpening stones are detected on both weapons: Rough, Coarse, Heavy, Solid,
Dense, Elemental, Consecrated, Blackfathom where present, and Fel/Adamantite in
TBC. Each stone is selectable separately under `/sp` → Click assignments,
with the catalog duration beside its name. Era/Forever regular stones last
30 minutes; TBC stones last 60 minutes; Consecrated is listed as 60 minutes.
Timers always use the client's actual remaining time. Forever's additional
Elemental item ID is supported; Blackfathom and the alternate Consecrated item
are selectable on Season of Discovery only. A database record does not imply
that an event item can currently be obtained.

Under Appearance → Visible weapons choose Both hands, Main hand only, or
Off hand only. One-hand mode also works with a tank's weapon and shield or a
two-handed weapon, and the choice survives `/reload`. The addon and minimap
button are available to Warriors and other classes. Only Rogues see poison
choices; other classes start with Auto: max damage, including when migrating
old poison defaults. Existing explicit stone selections stay saved. Explicit stone selections keep their strength when stock runs out. Choose
`Sharpening Stone (Auto: max damage)` to select the strongest stocked stone
meeting your level requirement: Adamantite → Fel → Dense → Solid → Heavy →
Coarse → Rough, filtered for the client. It switches after bag changes, or after
combat if necessary. Elemental (crit), Consecrated (undead) and Blackfathom
(BFD only) remain manual choices because their value depends on the situation. See the [full item, enchant and duration audit](docs/sharpening-stones.md).

## Commands

- `/sp` opens settings.
- `/sp move` unlocks the two-button anchor.
- `/sp lock` saves the current position.
- `/sp reset` restores defaults after confirmation.
- `/sp api` prints a short compatibility report.

Poison application always requires a hardware click. Secure click assignments
cannot be rebuilt during combat; bag or settings changes made during combat are
applied after combat ends. Blizzard replacement confirmations and errors remain
untouched.
Sliders cannot change protected button layout during combat, even if settings
were opened beforehand. Timer updates run only while a weapon has a timed enchant;
inventory and character events refresh idle buttons.

## Status

SimplePoisons 0.2.8 supports Classic Era, Hardcore, and Burning Crusade Classic
2.5.6. TBC includes Instant Poison VII, Deadly Poison VI and VII, Wound Poison V,
and Anesthetic Poison. The separate Forever 1.60.1 support remains beta pending
live server testing and uses its modern temporary-enchant API. Every client
keeps the same secure, hardware-click application workflow. Automated Lua, data,
metadata, and packaging tests cover the project. Protected clicks, poison
replacement confirmation behavior, and final geometry still require live
verification in each client.

## Local Windows deployment

Shared deployment is maintained in
`/home/msminipc/projects/wow-addon-deployer`; this repository does not keep a
private copy. Run `/home/msminipc/bin/deploy-wow-addons-pc` on MINIPC. The
central registry installs SimplePoisons into Classic Era, Burning Crusade
Classic, and, when present, the Forever beta while preserving
`SimplePoisonsDB`. Deployment does not publish a release.
