-- Ashen Builds combat simulator: item and enchant effects shared by every melee class.
--
-- Chance-on-hit data. src says where each entry comes from:
--   DB   proc rate read from the Turtle server item data (Tortoise DB snapshot)
--   REF  taken from the maintained Turtle WarriorSim (thrunk112), not confirmed on the server
--   LIVE a guessed rate in the reference ("assumed"/"unknown"); needs combat-log testing
-- ppm = procs per minute (chance = weapon speed * ppm / 60); chance = flat % per hit.
-- dmg + magic = spell damage (can be resisted, crits for 150%); dmg alone = physical hit.
-- extra = extra main-hand attacks; spell = a buff/debuff from AshenSim.ProcAuras.
-- OH entries replace P entries for the same item when it is in the off hand.

AshenSim = AshenSim or {}
local S = AshenSim

local P, OH = {}, {}
S.ItemProcs, S.OffhandProcs = P, OH

P[81124]={chance=5,dmg=20,magic=true,src="REF"} -- Helmet of the Scarlet Avenger
P[17111]={chance=100,dmg=3,magic=true,src="REF"} -- Blazefury Medallion
P[61010]={chance=1,extra=1,src="REF"} -- Wing of the Time-Lord
P[84035]={chance=5,dmg=60,magic=true,src="REF"} -- Fists of the Red Dawn
P[19289]={chance=2,dmg=250,magic=true,src="LIVE"} -- Darkmoon Card: Maelstrom
P[11815]={chance=2,extra=1,src="DB"} -- Hand of Justice
P[22321]={chance=2,dmg=165,magic=true,src="LIVE"} -- Heart of Wyrmthalak
P[61541]={ppm=2,extra=1,src="DB"} -- Letashaz's Right Claw
P[55494]={ppm=1,dmg=120,magic=true,src="REF"} -- The Abyssal Pincer
P[84030]={ppm=5,dmg=75,magic=true,src="DB"} -- Gauntlet of a Thousand Cuts
P[65008]={ppm=3.5,dmg=150,magic=true,src="DB"} -- Dream's Herald
P[83564]={ppm=0.4,spell="Tempest",src="REF"} -- Tempest's Rage
P[60422]={ppm=4,dmg=25,magic=true,coeff=1,src="DB"} -- The Ripper
P[61042]={ppm=1.5,dmg=59,magic=true,coeff=1,src="DB"} -- Stormfist
P[81288]={ppm=15,dmg=20,src="DB"} -- Mechanist's Bonechopper Replica
P[81003]={ppm=6,dmg=102,src="DB"} -- Ancient Hakkari Flayer
P[13246]={ppm=1,spell="Avenger",src="REF"} -- Argent Avenger
P[19852]={ppm=1,dmg=56,magic=true,coeff=1,src="REF"} -- Ancient Hakkari Manslayer
P[12798]={ppm=1,spell="Annihilator",src="DB"} -- Annihilator
P[13286]={ppm=5,spell="Rivenspike",src="DB"} -- Rivenspike
P[811]={ppm=0.8,dmg=108,magic=true,gcd=true,src="REF"} -- Axe of the Deep Woods
P[17068]={ppm=0.8,dmg=138,magic=true,gcd=true,src="REF"} -- Deathbringer
P[871]={ppm=1.8,extra=1,src="REF"} -- Flurry Axe
P[14555]={ppm=1.3,dmg=99,magic=true,src="DB"} -- Alcor's Sunrazor
P[13984]={ppm=1,dmg=99,magic=true,src="REF"} -- Darrowspike
P[20578]={ppm=1,dmg=97,magic=true,src="REF"} -- Emerald Dragonfang
P[12590]={ppm=1.4,spell="Felstriker",src="DB"} -- Felstriker
P[19099]={ppm=1,dmg=49,magic=true,src="REF"} -- Glacial Blade
P[17071]={ppm=1,dmg=82,magic=true,binary=true,gcd=true,src="REF"} -- Gutgore Ripper
P[18816]={ppm=1.3,dmg=53,magic=true,src="DB"} -- Perdition's Blade
P[19324]={ppm=1,dmg=250,src="REF"} -- The Lobotomizer
P[18203]={ppm=1,spell="Eskhandar",src="REF"} -- Eskhandar's Right Claw
P[19170]={ppm=0.8,dmg=220,magic=true,gcd=true,src="DB"} -- Ebon Hand
P[17112]={ppm=1,spell="Empyrean",src="DB"} -- Empyrean Demolisher
P[11684]={ppm=1,extra=2,src="DB"} -- Ironfoe
P[23221]={ppm=4,dmg=125,magic=true,src="REF"} -- Misplaced Servo Arm
P[19908]={ppm=1,dmg=78,magic=true,coeff=1,src="REF"} -- Sceptre of Smiting
P[6622]={ppm=1.8,spell="Zeal",src="REF"} -- Sword of Zeal
P[19901]={ppm=1,dmg=84,magic=true,coeff=1,src="REF"} -- Zulian Slicer
P[1728]={ppm=1,dmg=165,magic=true,src="REF"} -- Teebu's Blazing Longsword
P[17705]={ppm=1,extra=1,src="REF"} -- Thrash Blade
P[19019]={ppm=8,dmg=300,magic=true,binary=true,src="DB"} -- Thunderfury, Blessed Blade of the Windseeker
P[17075]={ppm=1.3,dmg=240,src="DB"} -- Vis'kag the Bloodletter
P[14487]={ppm=1.7,dmg=99,magic=true,src="REF"} -- Bonechill Hammer
P[58214]={ppm=1,spell="Modrag",src="REF"} -- Modrag'zan, Heart of the Mountain
OH[83564]={ppm=0.6,spell="Tempest",src="REF"} -- Tempest's Rage
OH[19852]={ppm=1,dmg=51,magic=true,coeff=1,src="REF"} -- Ancient Hakkari Manslayer
P[19910]={ppm=4,dmg=77,magic=true,gcd=true,src="DB"} -- Arlokk's Grasp
P[61247]={ppm=2,dmg=286,magic=true,src="DB"} -- Shadowbringer
P[33093]={ppm=1,dmg=212,magic=true,spell="ElementiumChampion",src="REF"} -- Elementium Champion
P[33094]={ppm=1,dmg=650,src="REF"} -- Elementium Reaper
P[61277]={ppm=1,dmg=212,magic=true,spell="ForgottenOrder",src="DB"} -- Fist of the Forgotten Order
P[55495]={chance=5,spell="ZandalariVigil",src="REF"} -- Zandalar Predator's Glaive
P[55504]={ppm=1,dmg=200,magic=true,src="REF"} -- Anchor of the Wavecutter
P[61049]={ppm=0.6,extra=1,src="DB"} -- Chronobreaker
P[9372]={ppm=1.5,dmg=275,magic=true,src="REF"} -- Sul'thraze the Lasher
P[12790]={ppm=1.2,spell="Champion",src="DB"} -- Arcanite Champion
P[1263]={ppm=1,dmg=250,src="REF"} -- Brain Hacker
P[19353]={ppm=2,dmg=240,src="DB"} -- Drake Talon Cleaver
P[21856]={ppm=1.4,dmg=152,magic=true,src="DB"} -- Neretzek, The Blood Drinker
P[13285]={ppm=1,dmg=100,src="REF"} -- The Blackrock Slicer
P[19918]={ppm=4,dmg=210,src="DB"} -- Jeklik's Crusher
P[17182]={ppm=3,dmg=333,magic=true,gcd=true,src="REF"} -- Sulfuras, Hand of Ragnaros
P[17193]={ppm=1,dmg=101,magic=true,gcd=true,src="REF"} -- Sulfuron Hammer
P[12583]={ppm=1,dmg=432,src="REF"} -- Blackhand Doomsaw
P[19874]={ppm=1.2,dmg=564,src="REF"} -- Halberd of Smiting
P[17223]={ppm=1.5,dmg=200,magic=true,src="DB"} -- Thunderstrike
P[17076]={ppm=2,spell="Bonereaver",src="DB"} -- Bonereaver's Edge
P[22691]={ppm=1,dmg=200,magic=true,src="REF"} -- Corrupted Ashbringer
P[647]={ppm=1,spell="Destiny",src="REF"} -- Destiny
P[21679]={ppm=1.75,dmg=258,magic=true,src="REF"} -- Kalimdor's Revenge
P[19334]={ppm=2,spell="Untamed",src="DB"} -- The Untamed Blade
P[13348]={ppm=1,dmg=270,magic=true,src="REF"} -- Demonshear
P[12782]={ppm=3,dmg=90,magic=true,src="DB"} -- Corruption

-- Buffs and debuffs started by the procs above (values from the reference sim).
-- stats: flat additions; haste: % attack speed (multiplies with other haste);
-- dmgBonus: flat weapon damage; armor: target armor removed per stack.
S.ProcAuras = {
  Empyrean = {name = "Empyrean Haste", duration = 10, haste = 20},
  Eskhandar = {name = "Eskhandar's Rage", duration = 5, haste = 30},
  Tempest = {name = "Tempest Haste", duration = 20, haste = 15},
  Zeal = {name = "Zeal", duration = 15, dmgBonus = 10},
  Annihilator = {name = "Armor Shatter", duration = 45, armor = 100, maxStacks = 3},     -- DB 16928: 100 per stack
  Rivenspike = {name = "Puncture Armor", duration = 30, armor = 200, maxStacks = 3},      -- DB 17315
  Bonereaver = {name = "Bonereaver's Edge", duration = 10, armor = 700, maxStacks = 3},
  Destiny = {name = "Destiny", duration = 10, stats = {str = 200}},
  Untamed = {name = "Untamed Fury", duration = 8, stats = {str = 300}},
  Champion = {name = "Strength of the Champion", duration = 30, stats = {str = 120}},
  ZandalariVigil = {name = "Zandalari Vigil", duration = 10, stats = {agi = 75}},
  ForgottenOrder = {name = "Fist of the Forgotten Order", duration = 15, stats = {str = 50}},
  ElementiumChampion = {name = "Elementium Champion", duration = 30, stats = {str = 150}},
  Felstriker = {name = "Felstriker", duration = 3, stats = {crit = 100, hit = 100}},
  Crusader = {name = "Crusader", duration = 15, stats = {str = 100}},
}

-- Weapon enchant procs by enchant spell id (reference values; Crusader matches the enchant text).
S.EnchantProcs = {
  [20034] = {ppm = 1, spell = "Crusader", src = "REF"},
  [13898] = {ppm = 6, dmg = 44, magic = true, src = "REF"},  -- Fiery Weapon
  [20032] = {ppm = 6, dmg = 33, magic = true, src = "REF"},  -- Lifestealing
}

-- "+N damage" from a weapon enchant (Striking/Impact), read from the enchant text.
function S.EnchantWeaponDamage(enchant)
  if not enchant or not enchant.tip then return 0 end
  local tip = enchant.tip
  if string.find(tip, "against") or string.find(tip, " to [A-Z]%a+s%.") then return 0 end  -- slayer enchants
  local _, _, n = string.find(tip, "to do (%d+) additional points? of damage")
  if not n then _, _, n = string.find(tip, "to do %+(%d+) damage") end
  return tonumber(n) or 0
end
