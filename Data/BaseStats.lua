-- Ashen Builds universal stat data.
-- Values are isolated here so Turtle-specific corrections can be updated without touching the engine.
AshenBuildsBaseStats = {
  -- Level 60 class baseline before race offsets. Lower levels scale between level-1 and level-60 anchors.
  class60 = {
    Warrior={str=110,agi=70,sta=100,int=30,spi=45,health=1689,mana=0},
    Paladin={str=95,agi=55,sta=90,int=65,spi=70,health=1381,mana=1512},
    Hunter={str=65,agi=105,sta=85,int=55,spi=60,health=1467,mana=1720},
    Rogue={str=70,agi=120,sta=75,int=30,spi=50,health=1523,mana=0},
    Priest={str=35,agi=40,sta=55,int=105,spi=110,health=1209,mana=1820},
    Shaman={str=85,agi=60,sta=85,int=75,spi=85,health=1280,mana=1520},
    Mage={str=30,agi=40,sta=50,int=120,spi=105,health=1100,mana=1900},
    Warlock={str=35,agi=40,sta=65,int=105,spi=100,health=1300,mana=1800},
    Druid={str=60,agi=55,sta=75,int=90,spi=100,health=1250,mana=1650},
  },
  class1 = {
    Warrior={str=20,agi=15,sta=20,int=10,spi=10,health=80,mana=0},
    Paladin={str=20,agi=10,sta=20,int=15,spi=15,health=68,mana=80},
    Hunter={str=15,agi=20,sta=20,int=15,spi=15,health=76,mana=85},
    Rogue={str=15,agi=25,sta=15,int=10,spi=10,health=75,mana=0},
    Priest={str=10,agi=10,sta=15,int=20,spi=20,health=52,mana=110},
    Shaman={str=20,agi=15,sta=20,int=20,spi=20,health=70,mana=95},
    Mage={str=10,agi=10,sta=15,int=25,spi=20,health=45,mana=120},
    Warlock={str=10,agi=10,sta=20,int=20,spi=20,health=53,mana=110},
    Druid={str=15,agi=15,sta=20,int=20,spi=20,health=55,mana=100},
  },
  raceOffsets = {
    Human={str=0,agi=0,sta=0,int=0,spi=0}, Dwarf={str=2,agi=-4,sta=3,int=-1,spi=0},
    NightElf={str=-4,agi=5,sta=-1,int=0,spi=0}, Gnome={str=-5,agi=2,sta=-3,int=4,spi=2},
    Orc={str=3,agi=-3,sta=2,int=-3,spi=1}, Tauren={str=5,agi=-5,sta=3,int=-3,spi=0},
    Troll={str=1,agi=2,sta=1,int=-4,spi=0}, Undead={str=-1,agi=-2,sta=1,int=-2,spi=4},
    HighElf={str=-3,agi=3,sta=-2,int=3,spi=1}, Goblin={str=-3,agi=3,sta=-2,int=2,spi=0},
  },
  racialWeaponSkill = {
    Human={Sword=5,TwoHandSword=5,Mace=5,TwoHandMace=5},
    Orc={Axe=5,TwoHandAxe=5},
    Dwarf={Gun=5},
    Troll={Bow=5,Thrown=5},
    HighElf={Bow=5},
    Goblin={Dagger=5,Mace=5},
  },
  critPerAgi = {Warrior=20,Rogue=29,Hunter=53,Paladin=20,Shaman=20,Druid=20,Priest=20,Mage=20,Warlock=20},
  spellCritPerInt = {Mage=59.5,Warlock=60.6,Priest=59.2,Druid=60,Shaman=59.5,Paladin=54,Hunter=60,Warrior=0,Rogue=0},
  baseMeleeCrit = {Warrior=0,Rogue=0,Hunter=0,Paladin=0,Shaman=0,Druid=0,Priest=0,Mage=0,Warlock=0},
  baseSpellCrit = {Mage=0,Warlock=0,Priest=0,Druid=0,Shaman=0,Paladin=0,Hunter=0,Warrior=0,Rogue=0},
}
