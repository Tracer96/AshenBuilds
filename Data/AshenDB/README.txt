ASHENDB ITEMS v0.1.0

AshenDB is a shared Turtle WoW item database addon.

BUILD THE FULL DATABASE
1. Open AshenDB\tools.
2. Double-click Build-AshenDB.bat.
3. The builder downloads the current immutable Tortoise-WoW SQLite database,
   decompresses it, and converts every equippable item into Vanilla-safe Lua shards.
4. Copy the finished AshenDB folder to Interface\AddOns\.

DATA INCLUDED
- Item ID and name
- Quality, slot, required level, item level, icon
- Armor/weapon class and subclass
- Weapon type, speed, damage range
- Class/race restrictions
- Set ID, binding and uniqueness
- Base stats, resistances, AP/RAP, spell/healing power, hit, crit,
  spell hit/crit, defense, avoidance, haste, weapon skills, regeneration,
  school-specific spell power and other derived equip-spell stats
- Acquisition source categories

FORMAT
AshenDB.Items[itemID] is a compact positional array.
Use AshenDB:GetItem(id) rather than reading files directly.

SOURCE
Generated from the public Tortoise-WoW database project by Xian55.
The database is fetched from its immutable CDN tag discovered via version.json.
AshenDB is not affiliated with Turtle WoW or the upstream database project.
