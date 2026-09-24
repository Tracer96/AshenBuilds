Ashen Builds v0.7.4 - GitHub Set Tooltip Rebuild

What changed
- Rebuilt all 359 item-set definitions into one reliable load-safe catalog.
- Exported 2,064 visible set members and 1,137 set bonus records.
- Added a direct item ID to set ID index.
- Recreated the website-style set section inside WoW item tooltips.
- Shows the set class restriction, every visible set piece, and exact set bonus text.
- Current hovered item: white.
- Other selected set pieces: green.
- Missing pieces: gray.
- Active bonuses: green.
- Inactive bonuses: gray.
- Added /ab debugset <itemID>.

Belt of Might verification
/ab debugset 16864

Expected:
raw=209, reverse=209, resolved=209, set=Battlegear of Might, members=8, bonuses=3

Install fresh
Delete Interface\AddOns\AshenBuilds before copying this version into Interface\AddOns\, then fully restart Turtle WoW.
