Ashen Builds v0.9.7

- Enchants are generated from the Turtle WoW database (tools/build_enchants.py): 263 enchants with
  exact values, including Turtle's custom ones (Invocations, Sigils, spell penetration and vampirism
  bracers, Holy/Nature/Arcane glove power, armor kits). Rings and necklaces take jewelcrafting
  gemstones, belts take blacksmithing buckles. Item-level limits (e.g. gemstones need item level 25+)
  are enforced. Old enchant IDs still load, so existing builds and codes keep working.
- Community builds sync server-wide: every sync request carries a digest of what the sender knows,
  the best-informed player answers first, players who know more pull from each other, and clients
  re-compare every 20 minutes (every 3 until someone answers). Builds and votes reach players who
  were offline when they happened; an unchanged catalog costs one short message per resync.
- Profanity filter: build names with profanity can't be published, and other players' names are
  shown masked (handles leetspeak and spaced-out spellings without flagging words like Assassination).
- Top-bar tabs toggle: click to open, click again to close; opening one tab closes the others and
  the open tab's button stays lit. The Item Database tab switches a slot picker to all items.
- Fixed edit boxes (item level range, stat minimums, prompts) drawing only their end caps.
- Minimap button: left-click toggles the planner, right-click toggles Community Builds, drag to move
  it around the minimap (position is saved). /ab minimap hides or shows it.
