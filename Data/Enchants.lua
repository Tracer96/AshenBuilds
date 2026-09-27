-- Enchant catalog. IDs are part of exported build codes, so existing numbers must never change;
-- add new enchants with new IDs and list them in AshenBuildsEnchantOrder.
-- req: "weapon" (any weapon), "twohand" (two-handed weapon only), "shield" (shield only).
local ALL5 = function(n) return {fireRes=n,frostRes=n,natureRes=n,shadowRes=n,arcaneRes=n} end
local HL = {HEAD=true,LEGS=true}
local WEP = {MAINHAND=true,OFFHAND=true}

AshenBuildsEnchants = {
  -- Head / Legs: arcanums and Zul'Gurub librams
  [1]={n="Arcanum of Rapidity", slots=HL, stats={haste=1}},
  [2]={n="Arcanum of Protection", slots=HL, stats={dodge=1}},
  [3]={n="Arcanum of Focus", slots=HL, stats={healing=8,spellPower=8}},
  [15]={n="Lesser Arcanum of Voracity (Str)", slots=HL, stats={str=8}},
  [16]={n="Lesser Arcanum of Voracity (Agi)", slots=HL, stats={agi=8}},
  [17]={n="Lesser Arcanum of Voracity (Sta)", slots=HL, stats={sta=8}},
  [18]={n="Lesser Arcanum of Voracity (Int)", slots=HL, stats={int=8}},
  [19]={n="Lesser Arcanum of Voracity (Spi)", slots=HL, stats={spi=8}},
  [20]={n="Lesser Arcanum of Constitution", slots=HL, stats={health=100}},
  [21]={n="Lesser Arcanum of Rumination", slots=HL, stats={mana=150}},
  [22]={n="Lesser Arcanum of Tenacity", slots=HL, stats={armor=125}},
  [23]={n="Lesser Arcanum of Resilience", slots=HL, stats={fireRes=20}},
  [25]={n="Presence of Might (Warrior)", slots=HL, stats={sta=10,defense=7,blockValue=15}},
  [26]={n="Presence of Sight (Mage)", slots=HL, stats={spellPower=18,healing=18,spellHit=1}},
  [27]={n="Falcon's Call (Hunter)", slots=HL, stats={rap=24,sta=10,hit=1}},
  [28]={n="Death's Embrace (Rogue)", slots=HL, stats={ap=28,dodge=1}},
  [29]={n="Hoodoo Hex (Warlock)", slots=HL, stats={spellPower=18,healing=18,sta=10}},
  [30]={n="Prophetic Aura (Priest)", slots=HL, stats={healing=24,mp5=4,sta=10}},
  [31]={n="Animist's Caress (Druid)", slots=HL, stats={healing=24,int=10,sta=10}},
  [32]={n="Syncretist's Sigil (Paladin)", slots=HL, stats={healing=24,defense=7,sta=10}},
  [33]={n="Vodouisant Charm (Shaman)", slots=HL, stats={healing=24,int=10,sta=10}},

  -- Shoulder
  [34]={n="Zandalar Signet of Might", slots={SHOULDER=true}, stats={ap=30}},
  [35]={n="Zandalar Signet of Mojo", slots={SHOULDER=true}, stats={spellPower=18,healing=18}},
  [36]={n="Zandalar Signet of Serenity", slots={SHOULDER=true}, stats={healing=33}},
  [37]={n="Might of the Scourge", slots={SHOULDER=true}, stats={ap=26,crit=1}},
  [38]={n="Power of the Scourge", slots={SHOULDER=true}, stats={spellPower=15,healing=15,spellCrit=1}},
  [39]={n="Resilience of the Scourge", slots={SHOULDER=true}, stats={healing=31,mp5=5}},
  [40]={n="Fortitude of the Scourge", slots={SHOULDER=true}, stats={sta=16,armor=100}},
  [41]={n="Inscription of Resistance (Argent Dawn)", slots={SHOULDER=true}, stats=ALL5(5)},

  -- Back
  [42]={n="Greater Resistance", slots={BACK=true}, stats=ALL5(5)},
  [43]={n="Superior Defense", slots={BACK=true}, stats={armor=70}},
  [44]={n="Lesser Agility", slots={BACK=true}, stats={agi=3}},
  [45]={n="Greater Fire Resistance", slots={BACK=true}, stats={fireRes=15}},
  [46]={n="Greater Nature Resistance", slots={BACK=true}, stats={natureRes=15}},
  [47]={n="Dodge", slots={BACK=true}, stats={dodge=1}},
  [48]={n="Subtlety", slots={BACK=true}, stats={}, desc="-2% threat"},
  [49]={n="Fire Resistance", slots={BACK=true}, stats={fireRes=7}},

  -- Chest
  [4]={n="Greater Stats", slots={CHEST=true}, stats={str=4,agi=4,sta=4,int=4,spi=4}},
  [50]={n="Stats", slots={CHEST=true}, stats={str=3,agi=3,sta=3,int=3,spi=3}},
  [51]={n="Major Health", slots={CHEST=true}, stats={health=100}},
  [52]={n="Major Mana", slots={CHEST=true}, stats={mana=100}},
  [53]={n="Superior Health", slots={CHEST=true}, stats={health=50}},

  -- Wrist
  [5]={n="Superior Stamina", slots={WRIST=true}, stats={sta=9}},
  [54]={n="Superior Strength", slots={WRIST=true}, stats={str=9}},
  [55]={n="Healing", slots={WRIST=true}, stats={healing=24}},
  [56]={n="Mana Regeneration", slots={WRIST=true}, stats={mp5=4}},
  [57]={n="Greater Intellect", slots={WRIST=true}, stats={int=7}},
  [58]={n="Superior Spirit", slots={WRIST=true}, stats={spi=9}},
  [59]={n="Greater Strength", slots={WRIST=true}, stats={str=7}},
  [60]={n="Greater Stamina", slots={WRIST=true}, stats={sta=7}},

  -- Hands
  [6]={n="Greater Strength", slots={HANDS=true}, stats={str=7}},
  [7]={n="Greater Agility", slots={HANDS=true}, stats={agi=7}},
  [61]={n="Superior Agility", slots={HANDS=true}, stats={agi=15}},
  [62]={n="Healing Power", slots={HANDS=true}, stats={healing=30}},
  [63]={n="Fire Power", slots={HANDS=true}, stats={firePower=20}},
  [64]={n="Frost Power", slots={HANDS=true}, stats={frostPower=20}},
  [65]={n="Shadow Power", slots={HANDS=true}, stats={shadowPower=20}},
  [66]={n="Threat", slots={HANDS=true}, stats={}, desc="+2% threat"},
  [67]={n="Minor Haste", slots={HANDS=true}, stats={haste=1}},

  -- Feet
  [8]={n="Minor Speed", slots={FEET=true}, stats={}, desc="Slight movement speed increase"},
  [9]={n="Greater Agility", slots={FEET=true}, stats={agi=7}},
  [68]={n="Greater Stamina", slots={FEET=true}, stats={sta=7}},
  [69]={n="Spirit", slots={FEET=true}, stats={spi=5}},
  [70]={n="Agility", slots={FEET=true}, stats={agi=5}},

  -- Weapons
  [10]={n="Crusader", slots=WEP, req="weapon", stats={}, desc="Chance on hit: +100 Strength"},
  [11]={n="Strength", slots=WEP, req="weapon", stats={str=15}},
  [12]={n="Agility", slots=WEP, req="weapon", stats={agi=15}},
  [71]={n="Spell Power", slots=WEP, req="weapon", stats={spellPower=30,healing=30}},
  [72]={n="Healing Power", slots=WEP, req="weapon", stats={healing=55}},
  [73]={n="Mighty Intellect", slots=WEP, req="weapon", stats={int=22}},
  [74]={n="Mighty Spirit", slots=WEP, req="weapon", stats={spi=20}},
  [75]={n="Superior Striking", slots=WEP, req="weapon", stats={}, desc="+5 weapon damage"},
  [76]={n="Fiery Weapon", slots=WEP, req="weapon", stats={}, desc="Chance on hit: fire damage"},
  [77]={n="Lifestealing", slots=WEP, req="weapon", stats={}, desc="Chance on hit: drain life"},
  [78]={n="Icy Chill", slots=WEP, req="weapon", stats={}, desc="Chance on hit: slows target"},
  [79]={n="Unholy Weapon", slots=WEP, req="weapon", stats={}, desc="Chance on hit: shadow damage"},
  [80]={n="Demonslaying", slots=WEP, req="weapon", stats={}, desc="Chance on hit vs demons"},
  [81]={n="2H Agility", slots={MAINHAND=true}, req="twohand", stats={agi=25}},
  [82]={n="2H Major Intellect", slots={MAINHAND=true}, req="twohand", stats={int=9}},
  [83]={n="2H Major Spirit", slots={MAINHAND=true}, req="twohand", stats={spi=9}},
  [84]={n="2H Superior Impact", slots={MAINHAND=true}, req="twohand", stats={}, desc="+9 weapon damage"},

  -- Shield
  [13]={n="Greater Stamina", slots={OFFHAND=true}, req="shield", stats={sta=7}},
  [14]={n="Thorium Shield Spike", slots={OFFHAND=true}, req="shield", stats={}, desc="Damages attackers when you block"},
  [85]={n="Frost Resistance", slots={OFFHAND=true}, req="shield", stats={frostRes=8}},
  [86]={n="Greater Spirit", slots={OFFHAND=true}, req="shield", stats={spi=7}},
  [87]={n="Stamina", slots={OFFHAND=true}, req="shield", stats={sta=5}},

  -- Ranged
  [88]={n="Biznicks 247x128 Accurascope", slots={RANGED=true}, stats={rangedHit=3}},
  [89]={n="Deadly Scope", slots={RANGED=true}, stats={}, desc="+10 ranged damage"},
  [90]={n="Sniper Scope", slots={RANGED=true}, stats={}, desc="+7 ranged damage"},
}

AshenBuildsEnchantOrder = {
  1,2,3,15,16,17,18,19,20,21,22,23,25,26,27,28,29,30,31,32,33,
  34,35,36,37,38,39,40,41,
  42,43,44,45,46,47,48,49,
  4,50,51,52,53,
  5,54,55,56,57,58,59,60,
  6,7,61,62,63,64,65,66,67,
  8,9,68,69,70,
  10,11,12,71,72,73,74,75,76,77,78,79,80,81,82,83,84,
  13,14,85,86,87,
  88,89,90,
}

-- Slots that can carry an enchant at all (rings, trinkets, neck, shirt and tabard cannot).
AshenBuildsEnchantSlots = {HEAD=true,SHOULDER=true,BACK=true,CHEST=true,WRIST=true,HANDS=true,LEGS=true,FEET=true,MAINHAND=true,OFFHAND=true,RANGED=true}
