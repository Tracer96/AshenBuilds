ASHEN BUILDS v0.7.4 - GITHUB SET TOOLTIP REBUILD

INSTALL
1. Delete the existing Interface\AddOns\AshenBuilds folder.
2. Copy the included AshenBuilds folder into Interface\AddOns\.
3. Fully restart Turtle WoW. Do not merge this release over an older folder.

OPEN
/ab

VERIFY
/ab debug
/ab debugset 16864

Expected database totals:
- 16,069 equippable items
- 359 item sets
- 2,064 visible set members
- 1,137 set bonus records

Expected Belt of Might diagnostic:
- Item ID: 16864
- Set ID: 209
- Set: Battlegear of Might
- Members: 8
- Bonuses: 3

VERSION 0.7.4
- Rebuilds the complete item-set catalog using the current Tortoise DB viewer query and tooltip-rendering model.
- Loads one compact top-level set catalog before the item database and UI.
- Adds a direct item-to-set reverse index so set detection does not depend only on compact item fields.
- Displays the set name, class restriction, all visible set pieces, and exact set bonus descriptions inside item tooltips.
- Highlights the hovered piece in white, other selected pieces in green, and missing pieces in gray.
- Displays active set bonuses in green and inactive bonuses in gray.
- Keeps the permanent Set Bonuses panel synchronized with selected gear.
- Adds /ab debugset <itemID> for set lookup diagnostics.

DATA NOTES
The set catalog was generated from the bundled Tortoise DB SQLite snapshot ec14bfe00852. The export query, class-mask selection, spell-variable resolution, and tooltip layout mirror the current Xian55/tortoise-db-viewer implementation reviewed on 2026-07-16.

AshenDB remains embedded inside AshenBuilds. No separate AshenDB addon is required.
