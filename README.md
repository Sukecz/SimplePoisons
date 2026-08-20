# SimplePoisons

![SimplePoisons](assets/logo-wide.png)

SimplePoisons is a focused, dependency-free poison monitor and applicator for
Rogue players in WoW Classic Era and Classic Hardcore. It replaces sprawling
poison menus and detached warnings with one compact pair of weapon buttons.

It keeps everything on two buttons:

- the left button represents the main-hand weapon;
- the right button represents the off-hand weapon;
- remaining enchant time and charges appear directly on each button;
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

This is an alpha build. Static Lua and data tests cover the local project, but
actual poison application, temporary-enchant identification, combat behavior,
and final geometry require a live Classic Era/Hardcore client check.

Support for TBC and other WoW versions is planned for later releases after
separate client-specific implementation and verification.
