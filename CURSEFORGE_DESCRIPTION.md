# CurseForge project summary

A compact poison and sharpening-stone tracker and click-to-apply helper for WoW Classic Era, Hardcore, Burning Crusade Classic, and Forever.

# Recommended CurseForge categories

- `Rogue` — primary category
- `Buffs & Debuffs`
- `Action Bars`

# Full description

SimplePoisons keeps weapon poisons and sharpening stones visible and one click away. Rogues can choose poisons or stones; Warriors and other classes see stone choices only.

Choose both weapon buttons, Main Hand only, or Off Hand only. Each button shows the current temporary enchant, remaining duration, and any remaining charges in the same place where you apply the next poison or stone. Single-hand mode works well for tanks with a weapon and shield or players with a two-handed weapon.

## Simple click controls

The weapon button chooses the target hand. The mouse button chooses the assigned poison or stone:

- Left Click applies your first configured poison or stone.
- Right Click applies your second configured poison or stone.
- Middle Click applies your third configured poison or stone.

For example, if Left Click is assigned to Instant Poison, Left Click on `MH` applies it to the main hand and Left Click on `OH` applies it to the off hand.

SimplePoisons automatically uses the highest available rank of the selected poison family found in your bags.

For stones, choose a specific type or "Sharpening Stone (Auto: max damage)". Auto selects Adamantite, Fel, Dense, Solid, Heavy, Coarse, then Rough, filtered by client, stock and character level. It switches when bags change; combat delays secure updates until combat ends. Elemental crit, Consecrated undead and Blackfathom dungeon bonuses remain manual choices because their value depends on the situation.

Era and Forever regular stones are listed as 30 minutes; TBC stones and Consecrated are listed as 60 minutes. The displayed countdown always follows the client's actual remaining time.

## Clear weapon status

- A neutral green border means the weapon poison is healthy.
- An orange border means its duration or charges are running low.
- A red border and `MISSING` mean the weapon has no temporary enchant.
- Choose both weapon icons, main hand only, or off hand only in settings.
- Active sharpening stones show their own icon, name, and remaining time with a neutral gray border. Click assignments also offer individual sharpening stones with client-specific durations. Warriors and other classes can use stones.
- The default warning thresholds are below 3 minutes or below 10 charges.
- Both warning thresholds are fully configurable.

## Focused configuration

- Configure Left, Right, and Middle Click independently.
- Choose horizontal or vertical button layout.
- Adjust the scale.
- Move and lock the paired buttons.
- Open settings from the small gear, the optional draggable green `SP` minimap button, or `/sp`. Hide the gear independently with the "Show settings icon" option.
- No additional addon installation is required. When another addon supplies LibDBIcon and LibDataBroker, the launcher uses them for compatibility with minimap collectors such as Leatrix Plus.

## Commands

- `/sp` opens settings.
- `/sp move` unlocks the button pair.
- `/sp lock` saves its position.
- `/sp reset` restores defaults after confirmation.
- `/sp api` prints a short client compatibility report.

## Compatibility

SimplePoisons supports WoW Classic Era, Classic Hardcore, and Burning Crusade Classic 2.5.6. TBC support includes Instant Poison VII, Deadly Poison VI and VII, Wound Poison V, and Anesthetic Poison. Separate WoW Forever 1.60.1 support remains beta pending live server testing and uses its modern temporary-enchant API.

Poison and stone application always require a real mouse click. SimplePoisons does not automate gameplay, suppress Blizzard errors, or bypass poison replacement confirmations.
