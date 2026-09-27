Ashen Builds v0.9.6

- Stats now match the in-game sheet (BetterCharacterStats / vmangos formulas): real base stats and base
  health/mana for every class, race and level; stamina counts base stamina (first 20 = 1 HP, then 10 HP);
  racials (Human Spirit, Gnome Intellect, Tauren Endurance, Night Elf dodge); level-scaled crit/dodge per
  agility; class base crit/dodge; 5% base parry/block; defense and weapon-skill bonuses; armor from agility;
  shield block value from equip effects; fixed Hunter ranged attack power.
- Talent bonuses are applied once inside the stat engine (the old override read a missing data table).
- Enchants: click the enchant line on any enchantable slot. 80+ enchants (arcanums, ZG/Naxx shoulders,
  cloak, chest, bracer, glove, boot, weapon, 2H, shield and scopes) with weapon/2H/shield checks.
- Saved builds: Rename and Delete buttons (with confirmation); saving a loaded build under a new name renames
  it instead of creating a copy; "Save As" makes an explicit copy.
- Item database: real dropdowns for slot, source, quality and sort; item level range; multi-stat filters with
  minimum values; usable/class/hidden toggles. Opening a slot or filtering is now near-instant thanks to a
  pre-built search index.
