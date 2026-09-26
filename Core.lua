AshenBuilds = AshenBuilds or {}
AshenBuilds.VERSION = "0.9.4"

AshenBuilds.SLOTS = {
  "HEAD","NECK","SHOULDER","BACK","CHEST","SHIRT","TABARD","WRIST","HANDS","WAIST","LEGS","FEET",
  "FINGER1","FINGER2","TRINKET1","TRINKET2","MAINHAND","OFFHAND","RANGED"
}
AshenBuilds.SLOT_LABELS = {
  HEAD="Head", NECK="Neck", SHOULDER="Shoulder", BACK="Back", CHEST="Chest", SHIRT="Shirt", TABARD="Tabard", WRIST="Wrist",
  HANDS="Hands", WAIST="Waist", LEGS="Legs", FEET="Feet", FINGER1="Ring 1", FINGER2="Ring 2",
  TRINKET1="Trinket 1", TRINKET2="Trinket 2", MAINHAND="Main Hand", OFFHAND="Off Hand", RANGED="Ranged"
}
AshenBuilds.INVENTORY_SLOTS = {
  HEAD=1, NECK=2, SHOULDER=3, BACK=15, CHEST=5, SHIRT=4, TABARD=19, WRIST=9, HANDS=10, WAIST=6, LEGS=7, FEET=8,
  FINGER1=11, FINGER2=12, TRINKET1=13, TRINKET2=14, MAINHAND=16, OFFHAND=17, RANGED=18
}
AshenBuilds.CLASSES = {"Warrior","Paladin","Hunter","Rogue","Priest","Shaman","Mage","Warlock","Druid"}
AshenBuilds.RACES = {"Human","Dwarf","Night Elf","Gnome","Orc","Tauren","Troll","Undead","High Elf","Goblin"}
AshenBuilds.SPECS = {
  Warrior={"Arms","Fury","Protection","Custom"}, Paladin={"Holy","Protection","Retribution","Custom"},
  Hunter={"Beast Mastery","Marksmanship","Survival","Custom"}, Rogue={"Assassination","Combat","Subtlety","Custom"},
  Priest={"Discipline","Holy","Shadow","Custom"}, Shaman={"Elemental","Enhancement","Restoration","Custom"},
  Mage={"Arcane","Fire","Frost","Custom"}, Warlock={"Affliction","Demonology","Destruction","Custom"},
  Druid={"Balance","Feral","Restoration","Custom"}
}
AshenBuilds.STAT_LABELS = {
  str="Strength", agi="Agility", sta="Stamina", int="Intellect", spi="Spirit", armor="Armor",
  ap="Attack Power", rap="Ranged Attack Power", spellPower="Spell Power", healing="Healing", hit="Hit", spellHit="Spell Hit",
  crit="Crit", spellCrit="Spell Crit", defense="Defense", dodge="Dodge", parry="Parry", block="Block", blockValue="Block Value",
  mp5="Mana per 5", hp5="Health per 5", fireRes="Fire Resist", frostRes="Frost Resist",
  natureRes="Nature Resist", shadowRes="Shadow Resist", arcaneRes="Arcane Resist",
  swordSkill="Sword Skill", axeSkill="Axe Skill", daggerSkill="Dagger Skill", maceSkill="Mace Skill", fistSkill="Fist Skill", polearmSkill="Polearm Skill", bowSkill="Bow Skill", gunSkill="Gun Skill", crossbowSkill="Crossbow Skill", thrownSkill="Thrown Skill",
  firePower="Fire Power", frostPower="Frost Power", naturePower="Nature Power", shadowPower="Shadow Power", arcanePower="Arcane Power", holyPower="Holy Power", spellPen="Spell Penetration", armorPen="Armor Penetration", haste="Haste"
}
AshenBuilds.GEAR_STAT_ORDER = {
  "str","agi","sta","int","spi","armor","ap","rap","spellPower","healing","hit","spellHit","crit","spellCrit",
  "defense","dodge","parry","block","blockValue","mp5","hp5","fireRes","frostRes","natureRes","shadowRes","arcaneRes",
  "swordSkill","axeSkill","daggerSkill","maceSkill"
}
AshenBuilds.QUALITY_LABELS = {[0]="Poor",[1]="Common",[2]="Uncommon",[3]="Rare",[4]="Epic",[5]="Legendary"}
AshenBuilds.ARMOR_LABELS = {"All","Cloth","Leather","Mail","Plate","Shield","Misc"}
AshenBuilds.DB_PACK = AshenBuildsDBPack or {name="Starter Pack",version="starter",count=0}

local function AB_Print(msg)
  DEFAULT_CHAT_FRAME:AddMessage("|cffd76b2aAshen Builds:|r " .. msg)
end
AshenBuilds.Print = AB_Print

local function AB_IndexOf(list, value)
  local i
  for i=1,table.getn(list) do if list[i] == value then return i end end
  return 1
end
AshenBuilds.IndexOf = AB_IndexOf

local function AB_PlayerClass()
  local localized, token = UnitClass("player")
  return localized or token or "Warrior"
end

local function AB_ValidLevel(value)
  value = tonumber(value)
  if not value or value < 1 or value > 60 then return 60 end
  return math.floor(value)
end
AshenBuilds.ValidLevel = AB_ValidLevel

local function AB_PlayerLevel()
  return AB_ValidLevel(UnitLevel("player"))
end

local function AB_NewBuild(name)
  local class = AB_PlayerClass()
  if not AshenBuilds.SPECS[class] then class = "Warrior" end
  return {
    name = name or "New Build",
    class = class,
    race = UnitRace("player") or "Human",
    level = AB_PlayerLevel(),
    spec = AshenBuilds.SPECS[class][1],
    notes = "",
    items = {},
    enchants = {},
    base = nil,
    created = time(),
    updated = time()
  }
end
AshenBuilds.NewBuildData = AB_NewBuild

function AshenBuilds:InitializeDB()
  if not AshenBuildsDB then AshenBuildsDB = {} end
  if not AshenBuildsDB.builds then AshenBuildsDB.builds = {} end
  if not AshenBuildsDB.current then AshenBuildsDB.current = AB_NewBuild("My First Build") end
  if not AshenBuildsDB.settings then AshenBuildsDB.settings = {scale=1, locked=false} end
  self.current = AshenBuildsDB.current
  self:MigrateBuild(self.current)
  local name, build
  for name, build in pairs(AshenBuildsDB.builds) do self:MigrateBuild(build) end
end

function AshenBuilds:MigrateBuild(build)
  if not build.class or not self.SPECS[build.class] then build.class = "Warrior" end
  if not build.race then build.race = "Human" end
  build.level = AB_ValidLevel(build.level)
  if not build.spec then build.spec = (self.SPECS[build.class] and self.SPECS[build.class][1]) or "Custom" end
  if not build.items then build.items = {} end
  if not build.enchants then build.enchants = {} end
end

function AshenBuilds:GetBuildLevel(build)
  build = build or self.current
  local level = AB_ValidLevel(build and build.level)
  if build and build.level ~= level then build.level = level end
  return level
end

function AshenBuilds:NormalizeSlot(slot, item)
  if not item then return nil end
  local s=item.slot
  if s == "FINGER" then
    if slot == "FINGER1" or slot == "FINGER2" then return slot end
  elseif s == "TRINKET" then
    if slot == "TRINKET1" or slot == "TRINKET2" then return slot end
  elseif s == "ROBE" then
    if slot == "CHEST" then return slot end
  elseif s == "WEAPON" then
    if slot == "MAINHAND" or slot == "OFFHAND" then return slot end
  elseif s == "TWOHAND" or s == "MAINHAND" then
    if slot == "MAINHAND" then return slot end
  elseif s == "OFFHAND" or s == "SHIELD" or s == "HOLDABLE" then
    if slot == "OFFHAND" then return slot end
  elseif s == "RANGED" or s == "RANGEDRIGHT" or s == "THROWN" or s == "RELIC" then
    if slot == "RANGED" then return slot end
  elseif s == slot then return slot end
  return nil
end

function AshenBuilds:EquipItem(slot, itemID)
  local item = self:GetItem(itemID)
  if not item then AB_Print("Item not found in the local database.") return end
  if not self:NormalizeSlot(slot, item) then AB_Print(item.n .. " does not fit " .. self.SLOT_LABELS[slot] .. ".") return end
  self.current.items[slot] = itemID
  self.current.updated = time()
  AshenBuildsDB.current = self.current
  self:RefreshUI()
end

function AshenBuilds:ApplyEnchant(slot, enchantID)
  if enchantID == 0 then self.current.enchants[slot] = nil
  elseif AshenBuildsEnchants and AshenBuildsEnchants[enchantID] then self.current.enchants[slot] = enchantID
  else AB_Print("Enchant not found.") return end
  self.current.updated = time()
  self:RefreshUI()
end

function AshenBuilds:RemoveItem(slot)
  self.current.items[slot] = nil
  self.current.enchants[slot] = nil
  self.current.updated = time()
  self:RefreshUI()
end

local function AddStats(target, stats)
  local stat, value
  if not stats then return end
  for stat, value in pairs(stats) do target[stat] = (target[stat] or 0) + value end
end

function AshenBuilds:GetGearTotals(build)
  build = build or self.current
  local totals = {}
  local i, slot, id, item, enchantID, enchant
  for i=1,table.getn(self.SLOTS) do
    slot = self.SLOTS[i]
    id = build.items[slot]
    item = id and self:GetItem(id)
    if item then AddStats(totals, item.stats) end
    enchantID = build.enchants and build.enchants[slot]
    enchant = enchantID and AshenBuildsEnchants and AshenBuildsEnchants[enchantID]
    if enchant then AddStats(totals, enchant.stats) end
  end
  return totals
end

function AshenBuilds:GetSetCounts(build)
  build = build or self.current
  local counts = {}
  local i, item
  for i=1,table.getn(self.SLOTS) do
    item = self:GetItem(build.items[self.SLOTS[i]] or 0)
    if item and item.set then local setId=tonumber(item.set); if setId then counts[setId] = (counts[setId] or 0) + 1 end end
  end
  return counts
end

function AshenBuilds:SetClass(value)
  self.current.class = value
  self.current.spec = self.SPECS[value][1]
  self.current.updated = time(); self:RefreshUI()
end
function AshenBuilds:SetRace(value) self.current.race=value; self.current.updated=time(); self:RefreshUI() end
function AshenBuilds:SetSpec(value) self.current.spec=value; self.current.updated=time(); self:RefreshUI() end
function AshenBuilds:SetLevel(value)
  value=AB_ValidLevel(value)
  self.current.level=value; self.current.updated=time(); self:RefreshUI()
end

function AshenBuilds:ImportEquipped()
  local found, missing = 0, 0
  local i, slot, inv, link, id
  for i=1,table.getn(self.SLOTS) do
    slot=self.SLOTS[i]; inv=self.INVENTORY_SLOTS[slot]; link=GetInventoryItemLink("player",inv)
    if link then
      id=tonumber(string.match(link,"item:(%d+)"))
      if id and self:GetItem(id) then self.current.items[slot]=id; found=found+1 else missing=missing+1 end
    else self.current.items[slot]=nil end
  end
  self.current.class=AB_PlayerClass(); self.current.race=UnitRace("player") or self.current.race; self.current.level=AB_PlayerLevel()
  self.current.updated=time(); self:RefreshUI()
  AB_Print("Imported "..found.." database items. "..missing.." equipped items are not in the current data pack.")
end

function AshenBuilds:SaveBuild(name)
  name = name or self.current.name or "Unnamed Build"; if name == "" then name = "Unnamed Build" end
  self.current.name=name; self.current.updated=time(); AshenBuildsDB.builds[name]=self:DeepCopy(self.current); AshenBuildsDB.current=self.current
  AB_Print("Saved |cffffffff"..name.."|r."); self:RefreshBuildList()
  if self.OnBuildSaved then self:OnBuildSaved(name) end
end
function AshenBuilds:LoadBuild(name)
  local build=AshenBuildsDB.builds[name]; if not build then return end
  self.current=self:DeepCopy(build); self:MigrateBuild(self.current); AshenBuildsDB.current=self.current; self:RefreshUI(); AB_Print("Loaded |cffffffff"..name.."|r.")
end
function AshenBuilds:DeleteBuild(name)
  if self.OnBuildDeleted then self:OnBuildDeleted(name) end
  AshenBuildsDB.builds[name]=nil; if self.selectedBuild==name then self.selectedBuild=nil end; self:RefreshBuildList(); AB_Print("Deleted |cffffffff"..name.."|r.")
end
function AshenBuilds:DeepCopy(value)
  if type(value)~="table" then return value end
  local result={},k,v; for k,v in pairs(value) do result[self:DeepCopy(k)]=self:DeepCopy(v) end; return result
end

local AB_CHARS="0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-_"
local function Enc(n) n=tonumber(n) or 0; if n==0 then return "0" end; local out=""; while n>0 do local r=math.mod(n,64); out=string.sub(AB_CHARS,r+1,r+1)..out; n=math.floor(n/64) end; return out end
local function Dec(s) local n=0; for i=1,string.len(s) do local p=string.find(AB_CHARS,string.sub(s,i,i),1,true); if not p then return nil end; n=n*64+(p-1) end; return n end

AshenBuilds.EncodeNumber=Enc
AshenBuilds.DecodeNumber=Dec

function AshenBuilds:ExportBuild(build)
  build=build or self.current
  local parts={"AB2",Enc(AB_IndexOf(self.CLASSES,build.class)),Enc(AB_IndexOf(self.RACES,build.race)),Enc(build.level),Enc(AB_IndexOf(self.SPECS[build.class],build.spec))}
  local i,slot
  for i=1,table.getn(self.SLOTS) do slot=self.SLOTS[i]; table.insert(parts,Enc(build.items[slot] or 0)); table.insert(parts,Enc((build.enchants and build.enchants[slot]) or 0)) end
  return table.concat(parts,".")
end

function AshenBuilds:ImportBuild(code)
  if not code then AB_Print("Invalid build code.") return false end
  if string.sub(code,1,4)=="AB1." then return self:ImportLegacyBuild(code) end
  local build,err=self:DecodeBuild(code)
  if not build then AB_Print(err) return false end
  self.current=build; AshenBuildsDB.current=build; self:RefreshUI(); AB_Print("Build imported."); return true
end

-- Parses an AB2 code into a build table without touching the planner.
-- Returns nil plus a message when the code is malformed.
function AshenBuilds:DecodeBuild(code)
  if type(code)~="string" or string.sub(code,1,4)~="AB2." then return nil,"Invalid build code." end
  local tokens={}; for token in string.gfind(code,"[^%.]+") do table.insert(tokens,token) end
  local legacy17={"HEAD","NECK","SHOULDER","BACK","CHEST","WRIST","HANDS","WAIST","LEGS","FEET","FINGER1","FINGER2","TRINKET1","TRINKET2","MAINHAND","OFFHAND","RANGED"}
  local newCount=5+(table.getn(self.SLOTS)*2)
  local legacyCount=5+(table.getn(legacy17)*2)
  local slots=self.SLOTS
  if table.getn(tokens)==legacyCount then slots=legacy17
  elseif table.getn(tokens)~=newCount then return nil,"Incomplete build code." end
  local build=AB_NewBuild("Imported Build")
  build.class=self.CLASSES[Dec(tokens[2]) or 1] or "Warrior"; build.race=self.RACES[Dec(tokens[3]) or 1] or "Human"; build.level=AB_ValidLevel(Dec(tokens[4]) or 60)
  build.spec=(self.SPECS[build.class] or {"Custom"})[Dec(tokens[5]) or 1] or "Custom"
  local i,id,enchantID,pos=1,nil,nil,6
  for i=1,table.getn(slots) do id=Dec(tokens[pos]); enchantID=Dec(tokens[pos+1]); if id and self:GetItem(id) then build.items[slots[i]]=id end; if enchantID and enchantID>0 and AshenBuildsEnchants[enchantID] then build.enchants[slots[i]]=enchantID end; pos=pos+2 end
  return build
end

function AshenBuilds:ImportLegacyBuild(code)
  local tokens={}; for token in string.gfind(code,"[^%.]+") do table.insert(tokens,token) end
  local legacy17={"HEAD","NECK","SHOULDER","BACK","CHEST","WRIST","HANDS","WAIST","LEGS","FEET","FINGER1","FINGER2","TRINKET1","TRINKET2","MAINHAND","OFFHAND","RANGED"}
  local newCount=table.getn(self.SLOTS)+1
  local legacyCount=table.getn(legacy17)+1
  local slots=self.SLOTS
  if table.getn(tokens)==legacyCount then slots=legacy17
  elseif table.getn(tokens)~=newCount then AB_Print("Incomplete legacy build code.") return false end
  local build=AB_NewBuild("Imported Build")
  local i,id; for i=1,table.getn(slots) do id=Dec(tokens[i+1]); if id and id>0 and self:GetItem(id) then build.items[slots[i]]=id end end
  self.current=build; AshenBuildsDB.current=build; self:RefreshUI(); AB_Print("Legacy build imported."); return true
end


-- Universal stat engine. Base data is resolved defensively because older
-- SavedVariables and some 1.12 clients can expose localized names or miss a data file.
local AB=AshenBuilds

local AB_FALLBACK_BASE_STATS = {
  class60 = {
    Warrior={str=110,agi=70,sta=100,int=30,spi=45,health=1689,mana=0},
    Paladin={str=95,agi=55,sta=90,int=65,spi=70,health=1381,mana=1512},
    Hunter={str=65,agi=105,sta=85,int=55,spi=60,health=1467,mana=1720},
    Rogue={str=70,agi=120,sta=75,int=30,spi=50,health=1523,mana=0},
    Priest={str=35,agi=40,sta=55,int=105,spi=110,health=1209,mana=1820},
    Shaman={str=85,agi=60,sta=85,int=75,spi=85,health=1280,mana=1520},
    Mage={str=30,agi=40,sta=50,int=120,spi=105,health=1100,mana=1900},
    Warlock={str=35,agi=40,sta=65,int=105,spi=100,health=1300,mana=1800},
    Druid={str=60,agi=55,sta=75,int=90,spi=100,health=1250,mana=1650}
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
    Druid={str=15,agi=15,sta=20,int=20,spi=20,health=55,mana=100}
  },
  raceOffsets = {
    Human={str=0,agi=0,sta=0,int=0,spi=0}, Dwarf={str=2,agi=-4,sta=3,int=-1,spi=0},
    NightElf={str=-4,agi=5,sta=-1,int=0,spi=0}, Gnome={str=-5,agi=2,sta=-3,int=4,spi=2},
    Orc={str=3,agi=-3,sta=2,int=-3,spi=1}, Tauren={str=5,agi=-5,sta=3,int=-3,spi=0},
    Troll={str=1,agi=2,sta=1,int=-4,spi=0}, Undead={str=-1,agi=-2,sta=1,int=-2,spi=4},
    HighElf={str=-3,agi=3,sta=-2,int=3,spi=1}, Goblin={str=-3,agi=3,sta=-2,int=2,spi=0}
  },
  racialWeaponSkill = {
    Human={Sword=5,TwoHandSword=5,Mace=5,TwoHandMace=5}, Orc={Axe=5,TwoHandAxe=5},
    Dwarf={Gun=5}, Troll={Bow=5,Thrown=5}, HighElf={Bow=5}, Goblin={Dagger=5,Mace=5}
  },
  critPerAgi = {Warrior=20,Rogue=29,Hunter=53,Paladin=20,Shaman=20,Druid=20,Priest=20,Mage=20,Warlock=20},
  spellCritPerInt = {Mage=59.5,Warlock=60.6,Priest=59.2,Druid=60,Shaman=59.5,Paladin=54,Hunter=60,Warrior=0,Rogue=0},
  baseMeleeCrit = {}, baseSpellCrit = {}
}

local function GetStatData()
  local data=AshenBuildsBaseStats
  if type(data)~="table" or type(data.class1)~="table" or type(data.class60)~="table" then
    return AB_FALLBACK_BASE_STATS
  end
  if type(data.raceOffsets)~="table" then data.raceOffsets=AB_FALLBACK_BASE_STATS.raceOffsets end
  if type(data.racialWeaponSkill)~="table" then data.racialWeaponSkill=AB_FALLBACK_BASE_STATS.racialWeaponSkill end
  if type(data.critPerAgi)~="table" then data.critPerAgi=AB_FALLBACK_BASE_STATS.critPerAgi end
  if type(data.spellCritPerInt)~="table" then data.spellCritPerInt=AB_FALLBACK_BASE_STATS.spellCritPerInt end
  if type(data.baseMeleeCrit)~="table" then data.baseMeleeCrit={} end
  if type(data.baseSpellCrit)~="table" then data.baseSpellCrit={} end
  return data
end

local function NormalizeClassName(value)
  local v=tostring(value or "Warrior")
  local lower=string.lower(v)
  local i,name
  for i=1,table.getn(AB.CLASSES) do
    name=AB.CLASSES[i]
    if string.lower(name)==lower then return name end
  end
  return "Warrior"
end

local function NormalizeRaceKey(value)
  local v=tostring(value or "Human")
  v=string.gsub(v,"%s+","")
  if v=="Nightelf" then return "NightElf" end
  if v=="Highelf" then return "HighElf" end
  return v
end

local function Add(dst,src)
  if not src then return end
  local k,v for k,v in pairs(src) do dst[k]=(dst[k] or 0)+v end
end

local function Lerp(a,b,t) return a + ((b-a)*t) end

function AB:GetBaseProfile(build)
  build=build or self.current or {}
  local data=GetStatData()
  local className=NormalizeClassName(build.class)
  local raceKey=NormalizeRaceKey(build.race)
  local level=tonumber(build.level) or 60
  if level<1 then level=1 elseif level>60 then level=60 end
  local one=(data.class1 and data.class1[className]) or AB_FALLBACK_BASE_STATS.class1[className] or AB_FALLBACK_BASE_STATS.class1.Warrior
  local sixty=(data.class60 and data.class60[className]) or AB_FALLBACK_BASE_STATS.class60[className] or AB_FALLBACK_BASE_STATS.class60.Warrior
  local t=(level-1)/59
  local out={}
  local fields={"str","agi","sta","int","spi","health","mana"}
  local i,k
  for i=1,table.getn(fields) do
    k=fields[i]
    out[k]=math.floor(Lerp(tonumber(one[k]) or 0,tonumber(sixty[k]) or 0,t)+0.5)
  end
  Add(out,(data.raceOffsets and data.raceOffsets[raceKey]) or nil)
  out.className=className
  out.raceKey=raceKey
  return out
end

function AB:GetWeaponInfo(build,slot)
  local item=self:GetItem(build.items[slot] or 0)
  if not item then return nil end
  local wt=item.weaponType
  if item.twoHand and wt then wt="TwoHand"..wt end
  return {name=item.n,type=wt or (item.shield and "Shield" or "Unknown")}
end

function AB:GetWeaponSkill(build,slot,gear)
  local w=self:GetWeaponInfo(build,slot)
  if not w or w.type=="Shield" or w.type=="Unknown" then return nil end
  local base=(tonumber(build.level) or 60)*5
  local data=GetStatData()
  local raceKey=NormalizeRaceKey(build.race)
  local racial=(((data.racialWeaponSkill or {})[raceKey] or {})[w.type] or 0)
  local map={Sword="swordSkill",TwoHandSword="swordSkill",Axe="axeSkill",TwoHandAxe="axeSkill",Dagger="daggerSkill",Mace="maceSkill",TwoHandMace="maceSkill",Fist="fistSkill",Polearm="polearmSkill",Bow="bowSkill",Gun="gunSkill",Crossbow="crossbowSkill",Thrown="thrownSkill"}
  local gearBonus=gear[map[w.type] or ""] or 0
  return {type=w.type,base=base,racial=racial,gear=gearBonus,total=base+racial+gearBonus}
end

function AB:GetClassAttackPower(class,level,str,agi)
  if class=="Warrior" then return (3*level)+(2*str)-20
  elseif class=="Paladin" then return (3*level)+(2*str)-20
  elseif class=="Rogue" then return (2*level)+str+agi-20
  elseif class=="Hunter" then return (2*level)+str+agi-20
  elseif class=="Shaman" then return (2*level)+(2*str)-20
  elseif class=="Druid" then return (2*str)-20
  else return str-10 end
end

function AB:GetClassRangedAttackPower(class,level,agi)
  if class=="Hunter" then return (2*level)+agi-10 end
  if class=="Rogue" or class=="Warrior" then return level+agi-10 end
  return agi-10
end

function AB:GetDerivedStats(build)
  build=build or self.current
  local gear=self:GetGearTotals(build)
  local base=self:GetBaseProfile(build)
  local out={gear=gear,base=base,warnings={}}
  local level=tonumber(build.level) or 60
  out.str=(base.str or 0)+(gear.str or 0)
  out.agi=(base.agi or 0)+(gear.agi or 0)
  out.sta=(base.sta or 0)+(gear.sta or 0)
  out.int=(base.int or 0)+(gear.int or 0)
  out.spi=(base.spi or 0)+(gear.spi or 0)
  out.health=(base.health or 0)+(gear.sta or 0)*10+(gear.health or 0)
  out.mana=(base.mana or 0)+(gear.int or 0)*15+(gear.mana or 0)
  out.armor=(gear.armor or 0)+(gear.bonusArmor or 0)
  local data=GetStatData()
  local className=NormalizeClassName(build.class)
  out.attackPower=self:GetClassAttackPower(className,level,out.str,out.agi)+(gear.ap or 0)
  out.rangedAttackPower=self:GetClassRangedAttackPower(className,level,out.agi)+(gear.rap or 0)
  local agiRatio=(data.critPerAgi and data.critPerAgi[className]) or 20
  out.meleeCrit=((data.baseMeleeCrit and data.baseMeleeCrit[className]) or 0)+(out.agi/agiRatio)+(gear.crit or 0)
  out.rangedCrit=out.meleeCrit+(gear.rangedCrit or 0)
  local intRatio=(data.spellCritPerInt and data.spellCritPerInt[className]) or 0
  out.spellCrit=(gear.spellCrit or 0)+(intRatio>0 and out.int/intRatio or 0)+((data.baseSpellCrit and data.baseSpellCrit[className]) or 0)
  out.hit=gear.hit or 0; out.rangedHit=(gear.rangedHit or 0)+out.hit; out.spellHit=gear.spellHit or 0
  out.defense=(level*5)+(gear.defense or 0)
  out.dodge=5+(out.agi/20)+(gear.dodge or 0)
  out.parry=gear.parry or 0; out.block=gear.block or 0; out.blockValue=(gear.blockValue or 0)+(out.str/20)
  out.spellPower=gear.spellPower or 0; out.healing=gear.healing or 0
  out.arcanePower=out.spellPower+(gear.arcanePower or 0); out.firePower=out.spellPower+(gear.firePower or 0)
  out.frostPower=out.spellPower+(gear.frostPower or 0); out.naturePower=out.spellPower+(gear.naturePower or 0)
  out.shadowPower=out.spellPower+(gear.shadowPower or 0); out.holyPower=out.spellPower+(gear.holyPower or 0)
  out.mp5=gear.mp5 or 0; out.hp5=gear.hp5 or 0; out.haste=gear.haste or 0; out.armorPen=gear.armorPen or 0; out.spellPen=gear.spellPen or 0
  out.mainSkill=self:GetWeaponSkill(build,"MAINHAND",gear); out.offSkill=self:GetWeaponSkill(build,"OFFHAND",gear); out.rangedSkill=self:GetWeaponSkill(build,"RANGED",gear)
  out.resistances={fire=gear.fireRes or 0,frost=gear.frostRes or 0,nature=gear.natureRes or 0,shadow=gear.shadowRes or 0,arcane=gear.arcaneRes or 0}
  if build.spec=="Custom" then table.insert(out.warnings,"Custom talents are not allocated yet") end
  return out
end

-- Startup is deliberately registered after every calculation method exists.
local eventFrame=CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:SetScript("OnEvent",function()
  if event=="ADDON_LOADED" and arg1=="AshenBuilds" then
    AshenBuilds:InitializeDB(); AshenBuilds:CreateUI()
    SLASH_ASHENBUILDS1="/ab"; SLASH_ASHENBUILDS2="/ashenbuilds"
    SlashCmdList["ASHENBUILDS"]=function(msg)
      msg=string.lower(msg or "")
      local split=string.find(msg," ",1,true)
      local cmd=split and string.sub(msg,1,split-1) or msg
      local arg=split and string.sub(msg,split+1) or ""
      if cmd=="reset" then AshenBuilds.current=AB_NewBuild("New Build"); AshenBuildsDB.current=AshenBuilds.current; AshenBuilds:RefreshUI()
      elseif cmd=="importgear" then AshenBuilds:ImportEquipped()
      elseif cmd=="community" then if not AshenBuilds.frame:IsShown() then AshenBuilds:ToggleUI() end; AshenBuilds:OpenCommunity()
      elseif cmd=="debugset" then
        local itemId=tonumber(arg)
        if not itemId then
          AB_Print("Usage: /ab debugset <itemID>")
        else
          local item=AshenBuilds:GetItem(itemId)
          local raw=AshenBuilds:GetRawItem(itemId)
          local rawSet=raw and tonumber(raw[10]) or 0
          local reverseSet=(AshenBuilds.ItemToSet and AshenBuilds.ItemToSet[itemId]) or (AshenDB and AshenDB.ItemToSet and AshenDB.ItemToSet[itemId]) or 0
          local setId=AshenBuilds:GetItemSetId(itemId,item) or 0
          local set=AshenBuilds:GetItemSet(setId)
          local members=set and table.getn(set.items or {}) or 0
          local bonuses=set and table.getn(set.bonuses or {}) or 0
          AB_Print("Set debug: item="..itemId.." ("..((item and item.n) or "not found").."), raw="..rawSet..", reverse="..reverseSet..", resolved="..setId..", set="..((set and set.name) or "missing")..", members="..members..", bonuses="..bonuses..".")
        end
      elseif cmd=="debug" then
        local itemCount=(AshenDB and AshenDB.GetItemCount and AshenDB:GetItemCount()) or 0
        local setCount=(AshenBuilds.SetCatalogMeta and AshenBuilds.SetCatalogMeta.setCount) or (AshenDB and AshenDB.GetSetCount and AshenDB:GetSetCount()) or 0
        local memberCount=(AshenBuilds.SetCatalogMeta and AshenBuilds.SetCatalogMeta.memberCount) or 0
        local bonusCount=(AshenBuilds.SetCatalogMeta and AshenBuilds.SetCatalogMeta.bonusCount) or 0
        local sourceCount=(AshenDB and AshenDB.GetSourceItemCount and AshenDB:GetSourceItemCount()) or 0
        AB_Print("Debug: level="..AshenBuilds:GetBuildLevel()..", items="..itemCount..", sets="..setCount..", set members="..memberCount..", set bonuses="..bonusCount..", sourced items="..sourceCount..".")
      else AshenBuilds:ToggleUI() end
    end
    local setCount=(AshenDB and AshenDB.GetSetCount and AshenDB:GetSetCount()) or 0
    AB_Print("v"..AshenBuilds.VERSION.." loaded - "..setCount.." item sets ready. Type |cffffffff/ab|r to open.")
  end
end)

