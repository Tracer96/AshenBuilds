ASHEN BUILDS SET CATALOG GENERATOR

Usage:
python rebuild_set_catalog.py path\to\tortoise.sqlite ..\Data\SetCatalog.lua --data-version VERSION

The generator exports:
- item set names
- visible members ordered by required level and name
- representative class restrictions
- thresholded set bonuses joined to spell data
- resolved spell-description variables
- a direct item ID to set ID reverse map

The output file must load before the item shards, AshenDBAdapter.lua, Core.lua, and UI.lua.
