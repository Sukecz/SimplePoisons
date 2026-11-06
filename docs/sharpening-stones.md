# Weapon stone audit — 2026-11-06

Item tooltips were read separately from Wowhead's Era (`dataEnv=4`), TBC
(`dataEnv=5`) and Forever (`dataEnv=16`) datasets. These are catalog values,
not proof of current acquisition or successful application on a live server.
Settings show catalog minutes; monitoring always uses the client API's actual
remaining time, including after reload. No timer is reconstructed from a click.

| Stone | Item ID | Enchant ID | Era / Hardcore | TBC | Forever |
| --- | --- | --- | --- | --- | --- |
| Rough | 2862 | 40 | 30 min | 60 min | 30 min |
| Coarse | 2863 | 13 | 30 min | 60 min | 30 min |
| Heavy | 2871 | 14 | 30 min | 60 min | 30 min |
| Solid | 7964 | 483 | 30 min | 60 min | 30 min |
| Dense | 12404 | 1643 | 30 min | 60 min | 30 min |
| Elemental | 18262 | 2506 | 30 min | 60 min | 30 min |
| Elemental (additional Forever item) | 287980 | 2506 | — | — | 30 min |
| Consecrated | 23122 | 2684 | 60 min | 60 min | 60 min |
| Fel | 23528 | 2712 | — | 60 min | — |
| Adamantite | 23529 | 2713 | — | 60 min | — |
| Blackfathom (SoD, BFD only) | 211845 | 7098 | 30 min, SoD only | — | record exists; acquisition unverified |
| Consecrated (SoD weapon/shield variant) | 238241 | 2684 | 60 min, SoD only | — | — |

Normal Era and Forever choices are Rough through Consecrated. TBC also offers
Fel and Adamantite. Blackfathom is selectable only when the client reports an
active Season of Discovery; its effect is limited to Blackfathom Deeps.
Existing monitoring still recognizes its enchant wherever it is reported.
SoD Consecrated and Forever Elemental prefer the additional ID when stocked,
then accept the original item ID. Equal-effect variants share one selection;
explicit choices never substitute another strength.

The separate `Weapon Stone (Auto: max damage)` choice selects Adamantite,
Fel, Dense, Solid, Heavy, Coarse, then Rough, using the first stocked item that
meets the character's level requirement and exists for the client. Adamantite
wins the equal +12 flat-damage tier because it also grants crit rating.
Elemental, Consecrated and Blackfathom remain manual: crit and conditional
bonuses cannot be universally ranked against flat weapon damage. Inventory
changes refresh the bound item outside combat; changes in combat wait until
combat ends. The tooltip shows the exact item currently bound to the click. The two Elemental IDs share the same icon.

Consecrated's tooltip says 1 hour, while its SoD use-spell effect lists a value
of 1800. The settings label follows the item tooltip; actual duration must be
checked in the client and its reported remaining time always takes precedence.

## Item tooltip sources

Every ID in the table was checked using the following endpoint pattern:
`https://nether.wowhead.com/tooltip/item/ITEM_ID?dataEnv=ENV_ID`.
Missing TBC/Forever variants returned HTTP 404. Relevant examples:

- [Era Rough (30 min)](https://nether.wowhead.com/tooltip/item/2862?dataEnv=4),
  [TBC Rough (60 min)](https://nether.wowhead.com/tooltip/item/2862?dataEnv=5),
  [Forever Rough (30 min)](https://nether.wowhead.com/tooltip/item/2862?dataEnv=16).
- [Era Dense](https://nether.wowhead.com/tooltip/item/12404?dataEnv=4),
  [TBC Dense](https://nether.wowhead.com/tooltip/item/12404?dataEnv=5),
  [Forever Dense](https://nether.wowhead.com/tooltip/item/12404?dataEnv=16).
- [TBC Fel](https://nether.wowhead.com/tooltip/item/23528?dataEnv=5),
  [TBC Adamantite](https://nether.wowhead.com/tooltip/item/23529?dataEnv=5).
- [Forever Elemental 287980](https://www.wowhead.com/forever/item=287980/elemental-sharpening-stone),
  [original Elemental 18262](https://nether.wowhead.com/tooltip/item/18262?dataEnv=16),
  [same enchant 2506](https://www.wowhead.com/forever/spell=22756/sharpen-weapon-critical).
- [Consecrated 23122](https://nether.wowhead.com/tooltip/item/23122?dataEnv=16),
  [SoD Consecrated 238241](https://nether.wowhead.com/tooltip/item/238241?dataEnv=4),
  [SoD use-spell and enchant 2684](https://www.wowhead.com/classic/spell=1224422/consecrated-weapon).
- [Blackfathom](https://nether.wowhead.com/tooltip/item/211845?dataEnv=4).

## Effect-to-enchant sources

[Rough 40](https://www.wowhead.com/classic/spell=2828/sharpen-blade),
[Coarse 13](https://www.wowhead.com/classic/spell=2829/sharpen-blade-ii),
[Heavy 14](https://www.wowhead.com/classic/spell=2830/sharpen-blade-iii),
[Solid 483](https://www.wowhead.com/classic/spell=9900/sharpen-blade-iv),
[Dense 1643](https://www.wowhead.com/classic/spell=16138/sharpen-blade-v),
[Elemental 2506](https://www.wowhead.com/forever/spell=22756/sharpen-weapon-critical),
[Consecrated 2684](https://www.wowhead.com/classic/spell=28891/consecrated-weapon),
[Fel 2712](https://www.wowhead.com/tbc/spell=29452/sharpen-blade),
[Adamantite 2713](https://www.wowhead.com/tbc/spell=29453/sharpen-blade),
[Blackfathom 7098](https://www.wowhead.com/classic/spell=430392/sharpen-weapon-hit).

Grinding stones (crafting reagents), oils, and the Forever Sharpening Wheel
(a camping object) remain outside the selectable stone catalog.


## Weightstones

Weightstones use the same click, persistence, combat deferral and actual-enchant
monitoring paths as sharpening stones. Item tooltip datasets 4, 5 and 16 were
checked independently. Fel/Adamantite return 404 in Era and Forever and are
therefore offered only in TBC.

| Weightstone | Item ID | Enchant ID | Era / Hardcore | TBC | Forever |
| --- | --- | --- | --- | --- | --- |
| Rough | 3239 | 19 | 30 min | 60 min | 30 min |
| Coarse | 3240 | 20 | 30 min | 60 min | 30 min |
| Heavy | 3241 | 21 | 30 min | 60 min | 30 min |
| Solid | 7965 | 484 | 30 min | 60 min | 30 min |
| Dense | 12643 | 1703 | 30 min | 60 min | 30 min |
| Fel | 28420 | 2954 | — | 60 min | — |
| Adamantite | 28421 | 2955 | — | 60 min | — |

Item sources use the same tooltip endpoint pattern above, for example
[Era Dense](https://nether.wowhead.com/tooltip/item/12643?dataEnv=4),
[TBC Dense](https://nether.wowhead.com/tooltip/item/12643?dataEnv=5),
[Forever Dense](https://nether.wowhead.com/tooltip/item/12643?dataEnv=16),
[TBC Fel](https://nether.wowhead.com/tooltip/item/28420?dataEnv=5), and
[TBC Adamantite](https://nether.wowhead.com/tooltip/item/28421?dataEnv=5).
Effect-to-enchant sources:
[Rough 19](https://www.wowhead.com/classic/spell=3112/enhance-blunt-weapon),
[Coarse 20](https://www.wowhead.com/tbc/fr/spell=3113/perfectionnement-darme-contondante-ii),
[Heavy 21](https://www.wowhead.com/spell=3114/enhance-blunt-weapon-iii),
[Solid 484](https://www.wowhead.com/classic/pt/spell=9903/melhorar-arma-contundente-iv),
[Dense 1703](https://www.wowhead.com/classic/spell=16622/enhance-blunt-weapon-v),
[Fel 2954](https://www.wowhead.com/tbc/mx/spell=34339/mejorar-arma-roma),
[Adamantite 2955](https://www.wowhead.com/tbc/fr/spell=34340/equilibrer-larme).

The existing saved `stone:auto` key now displays as Weapon Stone Auto. It uses
weapon class/subclass IDs independently for inventory slots 16 and 17 to select
the sharpening or weightstone ranking. Weightstone Auto (`weight:auto`) is also
available explicitly. Within either family the ranking is Adamantite, Fel,
Dense, Solid, Heavy, Coarse, Rough, filtered by client, stock and character level.
There is no substitution between families when the required stock runs out.
Missing weapon data requests item metadata and leaves Auto unbound until the
item-data event arrives. No polling or optimistic enchant countdown is added.
Explicit stone choices retain their exact item; Blizzard validates each click.
Live application, replacement confirmations and server behavior still need
verification in each client.
