# CurseForge project summary

A lightweight two-button Rogue poison tracker and click-to-apply helper for WoW Classic Era and Hardcore.

# Recommended CurseForge categories

- `Rogue` — primary category
- `Buffs & Debuffs`
- `Action Bars`

# Full description

SimplePoisons keeps your weapon poisons visible, understandable, and one click away without adding a large poison grid or a separate warning frame.

Two compact buttons represent your Main Hand and Off Hand. Each button shows the current temporary enchant, remaining duration, and remaining charges in the same place where you apply the next poison.

## Simple click controls

The weapon button chooses the target hand. The mouse button chooses the poison:

- Left Click applies your first configured poison.
- Right Click applies your second configured poison.
- Middle Click applies your third configured poison.

For example, if Left Click is assigned to Instant Poison, Left Click on `MH` applies it to the main hand and Left Click on `OH` applies it to the off hand.

SimplePoisons automatically uses the highest available rank of the selected poison family found in your bags.

## Clear weapon status

- A neutral green border means the weapon poison is healthy.
- An orange border means its duration or charges are running low.
- A red border and `MISSING` mean the weapon has no temporary enchant.
- The default warning thresholds are below 3 minutes or below 10 charges.
- Both warning thresholds are fully configurable.

## Focused configuration

- Configure Left, Right, and Middle Click independently.
- Choose horizontal or vertical button layout.
- Adjust the scale.
- Move and lock the paired buttons.
- Open settings from the small gear, the optional draggable green `SP` minimap button, or `/sp`.
- No external libraries or dependencies.

## Commands

- `/sp` opens settings.
- `/sp move` unlocks the button pair.
- `/sp lock` saves its position.
- `/sp reset` restores defaults after confirmation.
- `/sp api` prints a short client compatibility report.

## Compatibility

The initial release targets WoW Classic Era and Classic Hardcore. Support for TBC and other WoW versions is planned for later releases and will be added only after separate client-specific testing.

Poison application always requires a real mouse click. SimplePoisons does not automate gameplay, suppress Blizzard errors, or bypass poison replacement confirmations.
