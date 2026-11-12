# Settings redesign — local implementation

The 1120 × 720 window uses a 728-pixel assignment panel and a separate appearance
and warnings panel. Eight assignments are visible together; lists beyond eight
use explicit pages. Effect selection uses icon cards with native item tooltips.
The window scales to the available screen size and remains movable.

Bindings use a dedicated capture dialog: keyboard, mouse wheel and ordinary
mouse clicks are supported, including modifiers. An ordinary left/right click
is captured using the dialog's capture area rather than confusing the opening
click with the desired binding. Esc cancels. Assign commits the candidate;
Clear retains the row and effect but removes its binding. New rows are unbound.
Duplicate bindings are rejected. Existing saved click assignments are preserved.

Mouse clicks use the main/off-hand button clicked. Keyboard and wheel bindings
have an explicit target hand selected in the binding dialog, only when a
keyboard/wheel candidate is being edited. The assignment table has no Weapon
column. Cancelling the dialog preserves the previous hand. A mouse assignment
and a keyboard assignment can use the same effect simultaneously; the keyboard
shortcut works anywhere, without a hover requirement. Removing it leaves the
mouse assignment intact. They dispatch to named secure action buttons via
`SetOverrideBindingClick`; original game bindings are not modified or saved.
The capture dialog warns about an existing game action before assignment.
Each refresh clears obsolete overrides and secure actions, outside combat.
Bindings remain stable during combat, and updates defer until combat ends.

The game options entry supports both `InterfaceOptions_AddCategory` and modern
`Settings.RegisterCanvasLayoutCategory` / `RegisterAddOnCategory`. Its button
opens the full window, retaining the wider layout instead of squeezing it into
the native options canvas. `/sp` and minimap/gear entry points remain available.

## Implementation references

These projects informed interaction/layout patterns; no claim is made that a
particular third-party release was live-tested on the user's Forever client.

- [AceGUI keybinding widget](https://github.com/WoWUIDev/Ace3/blob/ac3d1225037e0dc74e025a72342c0f7824aae147/AceGUI-3.0/widgets/AceGUIWidget-Keybinding.lua): modifier-aware capture and separate keyboard/mouse/wheel events.
- [ElvUI key binder](https://github.com/ElvUI-WotLK/ElvUI/blob/58ea24f7979740221389ce09685eb445723a6346/ElvUI/Modules/ActionBars/Bind.lua): dedicated binding mode.
- [DBM main frame](https://github.com/DeadlyBossMods/DeadlyBossMods/blob/ec645ccbafd6509adcb53a5933399281b083d89e/DBM-GUI/modules/MainFrame.lua): a broad settings canvas rather than a narrow vertical window.

## Logo asset

The original `assets/logo-wide.png` remains intact. The built-in imagegen tool
produced the transparent cutout saved as `assets/logo-header.png`. Its RGBA alpha
was preserved when converting/padding to the uncompressed 512 × 256 TGA used by
WoW: `assets/logo-header.tga`. The alpha regression test checks both transparent
surroundings and substantial visible artwork.

Exact imagegen prompt:

> Use case: background-extraction. Edit target: the supplied SimplePoisons addon logo. Remove ONLY the solid exterior black background surrounding the ornate emblem. Preserve the original green poison bottle, dagger, entire metallic plaque and its dark interior, exact typography and exact text 'SimplePoisons', metallic details and colors. Do not redesign or reinterpret the logo. Produce a clean antialiased transparent alpha cutout, tightly framed around the complete logo with minimal transparent outer margin. No checkerboard baked into pixels, no new words, no shadows on background. This is a small header asset for a dark World of Warcraft addon settings window.

## Validation and preview

`bash tests/run.sh` verifies the UI callbacks, old/new native options APIs,
eight-row paging, icon selection, key/mouse/wheel capture, duplicate rejection,
hand selection, keyboard capture cleanup, saved-data migration, secure override
cleanup, empty stock and combat deferral. The existing multi-client monitoring,
localization, cold-login and asset suites remain in use.

Reproducible layout preview (requires Lua 5.1 and Python 3):

```sh
mkdir -p tmp/redesign-preview
lua5.1 tools/preview_options.lua tmp/redesign-preview/settings.json
python3 tools/render_options_preview.py tmp/redesign-preview/settings.json
lua5.1 tools/preview_options.lua tmp/redesign-preview/picker.json picker
python3 tools/render_options_preview.py tmp/redesign-preview/picker.json
```

The HTML renderer uses the real Lua widget geometry via the integration-test
mock. It approximates native fonts/templates; it is not a screenshot from WoW.
Icon images for this development preview are fetched from the Wowhead image CDN.
Production runtime uses the client's own icon textures and has no network/image
or library dependency. Actual in-client rendering, hardware key dispatch and
replacement confirmations still require live verification in each client.
