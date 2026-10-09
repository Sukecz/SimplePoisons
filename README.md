# SimplePoisons

![SimplePoisons](assets/logo-wide.png)

SimplePoisons is a focused, dependency-free poison monitor and applicator for
Rogue players in WoW Classic Era, Classic Hardcore, Burning Crusade Classic,
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
- left, right, and middle click apply three configurable poison families.
- a small gear on the pair and an optional `SP` minimap button open settings.

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
TBC. Their tooltip shows the stone name. This is monitoring only; click
assignments still apply poisons. Timers use the client's remaining time.

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

SimplePoisons 0.2.5 supports Classic Era, Hardcore, and Burning Crusade Classic
2.5.6. TBC includes Instant Poison VII, Deadly Poison VI and VII, Wound Poison V,
and Anesthetic Poison. The separate Forever 1.60.1 support remains beta pending
live server testing and uses its modern temporary-enchant API. Every client
keeps the same secure, hardware-click poison workflow. Automated Lua, data,
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
