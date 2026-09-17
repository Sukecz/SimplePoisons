# SimplePoisons

![SimplePoisons](assets/logo-wide.png)

SimplePoisons is a focused, dependency-free poison monitor and applicator for
Rogue players in WoW Classic Era, Classic Hardcore, and the WoW Forever beta.
It replaces sprawling poison menus and detached warnings with one compact pair
of weapon buttons.

It keeps everything on two buttons:

- the left button represents the main-hand weapon;
- the right button represents the off-hand weapon;
- weapon labels and charges appear above each button, with remaining time below;
- an orange border means the poison is running low;
- a red border means the weapon has no temporary enchant;
- left, right, and middle click apply three configurable poison families.
- a small gear on the pair and an optional `SP` minimap button open settings.

The addon automatically selects the highest available rank of the configured
poison family from the player's bags.

The default low warning appears below 3 minutes or below 10 charges. Both
thresholds are adjustable in the settings window.

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

## Status

SimplePoisons 0.2.0-beta.1 adds beta support for WoW Forever 1.60.1 while
retaining Classic Era and Hardcore support. Forever uses its modern temporary
enchant API; both clients keep the same secure, hardware-click poison workflow.
Automated Lua, data, metadata, and packaging tests cover the project. Protected
clicks, poison replacement confirmation behavior, and final geometry still
require live verification in each client.
