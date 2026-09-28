-- Non-English clients: race and class are stored with their English names.
local AB = AshenBuilds
UnitRace = function() return "Mensch", "Human" end
UnitClass = function() return "Krieger", "WARRIOR" end
local b = AB.NewBuildData("German")
check("German client: race stored as Human", b.race == "Human")
check("German client: class stored as Warrior", b.class == "Warrior")
UnitRace = function() return "Nachtelf", "NightElf" end
check("Night Elf token maps to the race list name", AB.PlayerRace() == "Night Elf")
UnitRace = function() return "Untoter", "Scourge" end
check("Scourge token maps to Undead", AB.PlayerRace() == "Undead")
UnitRace = function() return "Hochelf", "BloodElf" end
check("Turtle High Elf token maps to High Elf", AB.PlayerRace() == "High Elf")
