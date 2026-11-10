# Changelog

## 0.2.11

- Move the Show MH/OH labels option below the other appearance toggles to prevent it from overlapping the button layout selector.

## 0.2.10

- Add a per-character "Show MH/OH labels" option under Appearance. Hide only the hand labels while keeping timers, charges and weapon buttons visible. Labels stay enabled by default.
- Fix missing orange low-time warnings for sharpening stones and weightstones. All recognized stones now use the configured time threshold, including during combat; missing enchants still show the red warning.
- Keep unidentified temporary enchants neutral and apply charge warnings only to poisons.

## 0.2.9

- Add Rough, Coarse, Heavy, Solid and Dense Weightstones for Era/Hardcore and Forever, plus Fel and Adamantite for TBC, with individual click choices, exact icons, names and remaining timers.
- Add Weightstone Auto and extend the saved stone Auto choice to select sharpening stones or weightstones independently for each equipped weapon. Refresh on equipment changes, deferring secure updates during combat.
- Cover all seven weightstones, client restrictions, durations, all clicks/hands, stock and level fallback, weapon metadata, mixed weapons and combat swaps in regression tests.

## 0.2.8

- Keep the settings gear on the same frame strata as the weapon buttons so it no longer overlays normal game windows.

## 0.2.7

- Apply sharpening stones with Left, Right, or Middle Click on the selected weapon button, including on Warriors and other non-Rogue classes.
- Add "Sharpening Stone (Auto: max damage)" to choose the strongest stocked flat-damage stone allowed by the client and character level. Update after bag changes, with secure changes deferred until combat ends. Elemental and conditional stones remain explicit choices.
- Show only stone choices to non-Rogues and migrate their old poison defaults to Auto. Rogues keep both poisons and stones.
- Add Both hands, Main hand only, and Off hand only display modes, saved per character, with compact single-button positioning.
- Audit Era, TBC and Forever stone IDs and durations, including the additional Forever Elemental item and SoD-specific variants. Display catalog durations in settings; countdowns use actual client data.
- Fix the missing minimap logo and custom-button warning with Leatrix Plus by registering through existing LibDataBroker/LibDBIcon libraries. Preserve the standalone launcher, visibility preference and saved position when these optional libraries are absent.
- Add regression coverage for stone selection, automatic fallback, class filtering, single-hand layouts, combat safety, minimap integration and texture format.

No additional addon installation is required. Forever support remains beta; live Rogue application and all client-specific replacement confirmations still require verification.

## 0.2.6

- Add a per-character "Show settings icon" option to hide the small gear beside the weapon buttons.
- Keep the gear visible by default and control it independently of the minimap button. Settings remain accessible through `/sp`.

Forever support remains beta pending live rogue testing.

## 0.2.5

- Fix intermittent `no usable rank` and missing poison click actions when the client temporarily reports owned poisons unusable.
- Select ranks by bag stock, Rogue class, and cached minimum level instead of current item usability. Keep the highest owned rank bound while metadata loads, with Blizzard validating the actual click.
- Refresh rank assignments on item-data completion and retain combat deferral without adding polling.
- Add regression coverage for every supported client's poison families and all three clicks, cold item data, level restrictions, both hands, and item-data completion during combat.

This shared application fix covers Classic Era/Hardcore, Burning Crusade Classic, and WoW Forever beta. Forever support remains beta pending live rogue testing.

## 0.2.4

- Show the exact icon, name, and remaining time of active sharpening stones on both weapon buttons.
- Recognize Rough, Coarse, Heavy, Solid, Dense, Elemental, Consecrated, and Blackfathom stones where available, plus Fel and Adamantite in TBC.
- Keep stone monitoring independent of bag contents, item usability, and cached item data.
- Keep sharpening stones monitoring-only with a neutral gray border; click assignments continue to apply poisons.
- Add regression coverage for all ten stone types, both hands, Era/TBC/Forever API paths, combat replacement, and timer expiration.

Forever support remains beta pending live rogue testing.

## 0.2.3

- Refresh poison status on weapon-enchant and weapon-slot changes so an idle monitor does not remain on `MISSING` after poison application.
- Read weapon enchants through the current Forever API, retaining support for earlier Forever builds and Classic Era/Hardcore/TBC.
- Ignore permanent enchants and prefer an applied poison when another temporary imbue is present.
- Extend `/sp api` reporting and regression tests for enchant events, both hands, and current Forever API compatibility.

Forever support remains beta pending live rogue testing.

## 0.2.2

- Display the icon of the poison actually applied to each weapon, including Crippling Poison versus Crippling Poison II.
- Keep applied-poison icons independent of bag contents and item usability while dead or a ghost.
- Apply the shared fixes to Classic Era/Hardcore, Burning Crusade Classic, and WoW Forever beta.

- Blocked slider changes during combat and deferred protected layout refreshes.
- Select the highest usable poison rank and refresh selections on character changes.
- Show the bound poison rank and its stock in each click's tooltip.
- Display unidentified temporary enchants with a neutral border and weapon icon.
- Stop timer updates when no timed weapon enchant is active.
- Respect enchants without expiration and restore font size when resetting settings.
- Added regression coverage for combat settings, poison catalogs, rank selection, and timer lifecycle.

## 0.2.0

- Added a dedicated Burning Crusade Classic TOC for client 2.5.6 / Interface 20506.
- Added Instant Poison VII, Deadly Poison VI and VII, and Wound Poison V.
- Added the TBC-only Anesthetic Poison family.
- Kept the separate WoW Forever client support in beta pending live server testing.

## 0.2.0-beta.1

- Added a dedicated WoW Forever beta TOC for client 1.60.1 / Interface 16001.
- Added the modern temporary-enchant API used by Forever while retaining the Classic Era fallback.
- Added direct poison-family detection from the beta client's weapon enchant IDs.
- Removed the invalid Distracting Poison option; item 9187 is Elixir of Greater Agility.
- Kept poison application on prebuilt secure macros and real hardware clicks.

## 0.1.3

- Kept the displayed poison tied to the actual weapon enchant until application finishes successfully.
- Prevented interrupted or cancelled poison casts from showing the selected poison as active.

## 0.1.2

- Requested poison item data during login so active-poison icons resolve promptly.
- Replaced the misleading weapon-icon fallback with a generic poison icon while poison data is loading.

## 0.1.1

- Made low-poison warnings much more prominent with a bright orange tint and glow.
- Made missing-poison warnings unmistakable with a strong red tint, glow, and white label.
- Kept normal and empty-weapon states free of warning glow.

## 0.1.0

- Promoted SimplePoisons to its first stable Classic Era and Hardcore release.
- Fixed secure poison clicks so Left, Right, and Middle Click run on mouse release.
- Added a movable settings window with a standard close button.
- Added a dedicated drag handle and Lock button for positioning the weapon buttons.
- Separated weapon labels, charges, and timers from the poison icons for readability.
- Added configurable text size with consistent font and color.
- Fixed overlapping appearance controls and improved horizontal and vertical spacing.

## 0.1.0-alpha.1

- Added linked main-hand and off-hand poison buttons.
- Added remaining time, charges, low-warning, and missing states.
- Added configurable Left, Right, and Middle Click poison assignments.
- Added automatic highest-available-rank selection.
- Added compact settings, movement, scale, orientation, and reset controls.
- Added direct gear access and a draggable green `SP` minimap button.
- Added Classic Era and Hardcore metadata and compatibility reporting.
