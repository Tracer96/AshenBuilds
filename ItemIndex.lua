local AB = AshenBuilds

-- Search index for the item database. Everything the filters need is computed once
-- (lower-case names, source categories, hidden flags) and items are pre-bucketed by
-- planner slot and pre-sorted by item level, so a filter pass only walks one slot's
-- items and allocates nothing per item. The index builds in small chunks after login
-- so opening the database never has to wait for it.

local IDX = {pos = 0, done = false}
AB.ItemIndex = IDX

-- Source filter bits (turtlelootline categories).
AB.SOURCE_FILTERS = {
  {value = 0, text = "All Sources"},
  {value = 1, text = "Dungeon"},
  {value = 2, text = "Raid"},
  {value = 4, text = "Quest"},
  {value = 8, text = "World Boss"},
  {value = 16, text = "Crafted"},
  {value = 32, text = "Reputation"},
  {value = 64, text = "PvP"},
  {value = 128, text = "World Drop"},
  {value = 256, text = "Vendor"},
}

local RAIDS = {}
local DUNGEONS = {}
local WORLD_BOSSES = {}
local function Set(t, list) local i for i = 1, table.getn(list) do t[list[i]] = true end end
Set(RAIDS, {"Molten Core", "Onyxia's Lair", "Blackwing Lair", "Zul'Gurub", "Ruins of Ahn'Qiraj", "Ahn'Qiraj", "Temple of Ahn'Qiraj",
  "Naxxramas", "The Upper Necropolis", "Emerald Sanctum", "Karazhan", "Lower Karazhan Halls", "Tower of Karazhan"})
Set(DUNGEONS, {"Ragefire Chasm", "Wailing Caverns", "The Deadmines", "Shadowfang Keep", "Blackfathom Deeps", "The Stockade", "Gnomeregan",
  "Razorfen Kraul", "Scarlet Monastery", "Scarlet Monastery Graveyard", "Scarlet Monastery Library", "Scarlet Monastery Armory",
  "Scarlet Monastery Cathedral", "Razorfen Downs", "Uldaman", "Zul'Farrak", "Maraudon", "The Temple of Atal'Hakkar", "Blackrock Depths",
  "Blackrock Spire", "Dire Maul", "Stratholme", "Scholomance", "Gilneas City", "Crescent Grove", "Karazhan Crypt", "Hateforge Quarry",
  "The Black Morass", "Dragonmaw Retreat", "Stormwrought Ruins", "Windhorn Canyon", "Stormwind Vault", "Frostmane Hollow"})
Set(WORLD_BOSSES, {"Azuregos", "Lord Kazzak", "Emeriss", "Lethon", "Ysondre", "Taerar", "Nerubian Overseer", "Dark Reaver of Karazhan",
  "Ostarius", "Concavius", "Moo", "Cla'ckora"})

local function HasBit(mask, bit) return math.mod(math.floor(mask / bit), 2) == 1 end
AB.HasBit = HasBit

local function SourceInfo(id, r)
  local mask, words = 0, {}
  local cats = r[20] or {}
  local i, c
  for i = 1, table.getn(cats) do
    c = cats[i]
    if c == "quest" then mask = mask + (HasBit(mask, 4) and 0 or 4)
    elseif c == "crafted" then mask = mask + (HasBit(mask, 16) and 0 or 16)
    elseif c == "pvp" then mask = mask + (HasBit(mask, 64) and 0 or 64)
    elseif c == "worlddrop" then mask = mask + (HasBit(mask, 128) and 0 or 128)
    elseif c == "vendor" then mask = mask + (HasBit(mask, 256) and 0 or 256) end
  end
  local ss = AshenDB and AshenDB.ItemSources and AshenDB.ItemSources[id]
  if ss then
    local s, bit
    for i = 1, table.getn(ss) do
      s = ss[i]; bit = 0
      if s[1] == "drop" then
        if WORLD_BOSSES[s[3] or ""] then bit = 8
        elseif RAIDS[s[4] or ""] then bit = 2
        elseif DUNGEONS[s[4] or ""] then bit = 1
        else bit = 128 end
      elseif s[1] == "vendor" and s[3] and (string.find(s[3], "Quartermaster", 1, true) or string.find(s[3], "Provisioner", 1, true)) then bit = 32
      elseif s[1] == "quest" then bit = 4
      elseif s[1] == "craft" then bit = 16 end
      if bit > 0 and not HasBit(mask, bit) then mask = mask + bit end
      if type(s[3]) == "string" and s[3] ~= "" then table.insert(words, s[3]) end
      if s[1] ~= "craft" and type(s[4]) == "string" and s[4] ~= "" then table.insert(words, s[4]) end
    end
  end
  return mask, string.lower(table.concat(words, " "))
end

local HIDDEN_WORDS = {"TEST", "OLD", "DEPRECATED", "UNUSED", "PLACEHOLDER", "INTERNAL", "DEBUG", "GAMEMASTER", "GM ONLY", "QA ", "NPC ONLY"}
local function IsHidden(name)
  local n = string.upper(name or ""); local i
  for i = 1, table.getn(HIDDEN_WORDS) do if string.find(n, HIDDEN_WORDS[i], 1, true) then return true end end
  return false
end

-- Planner slots each raw item slot can go into ("ALL" collects every equippable item).
local SLOT_TARGETS = {}
local function TargetsFor(rawSlot)
  local t = SLOT_TARGETS[rawSlot]
  if t then return t end
  t = {}
  local i, slot
  for i = 1, table.getn(AB.SLOTS) do
    slot = AB.SLOTS[i]
    if AB:NormalizeSlot(slot, {slot = rawSlot}) then table.insert(t, slot) end
  end
  SLOT_TARGETS[rawSlot] = t
  return t
end

local function Reset()
  IDX.pos = 0; IDX.done = false; IDX.n = 0
  IDX.id, IDX.name, IDX.q, IDX.req, IDX.ilvl, IDX.hidden, IDX.class, IDX.src, IDX.srcText, IDX.stats = {}, {}, {}, {}, {}, {}, {}, {}, {}, {}
  IDX.bySlot = {ALL = {}}
  local i; for i = 1, table.getn(AB.SLOTS) do IDX.bySlot[AB.SLOTS[i]] = {} end
end
Reset()

local function SortBuckets()
  local ilvl, name = IDX.ilvl, IDX.name
  local function cmp(a, b) if ilvl[a] ~= ilvl[b] then return ilvl[a] > ilvl[b] end return name[a] < name[b] end
  local _, bucket
  for _, bucket in pairs(IDX.bySlot) do table.sort(bucket, cmp) end
end

-- Indexes up to `budget` more items; returns true once everything is indexed.
function IDX:Step(budget)
  if self.done then return true end
  local order = AshenBuildsItemOrder or {}
  local total = table.getn(order)
  local last = math.min(total, self.pos + (budget or total))
  local i, id, r, n, targets, k, mask, text
  for i = self.pos + 1, last do
    id = order[i]; r = AB:GetRawItem(id)
    if r then
      targets = TargetsFor(r[3])
      if table.getn(targets) > 0 then
        n = self.n + 1; self.n = n
        mask, text = SourceInfo(id, r)
        self.id[n] = id; self.name[n] = string.lower(r[1] or ""); self.q[n] = r[2] or 1; self.req[n] = r[4] or 0; self.ilvl[n] = r[5] or 0
        self.hidden[n] = IsHidden(r[1]); self.class[n] = tonumber(r[11]) or -1; self.src[n] = mask; self.srcText[n] = text; self.stats[n] = r[19] or {}
        for k = 1, table.getn(targets) do table.insert(self.bySlot[targets[k]], n) end
        table.insert(self.bySlot.ALL, n)
      end
    end
  end
  self.pos = last
  if last >= total then SortBuckets(); self.done = true end
  return self.done
end

function IDX:Finish() return self:Step(nil) end

local CLASS_BITS = {Warrior = 1, Paladin = 2, Hunter = 4, Rogue = 8, Priest = 16, Shaman = 64, Mage = 128, Warlock = 256, Druid = 1024}
local STAT_ALIASES = {strength = "str", agility = "agi", stamina = "sta", intellect = "int", spirit = "spi", crit = "crit", hit = "hit",
  healing = "healing", spell = "spellPower", defense = "defense", dodge = "dodge", parry = "parry", block = "block", haste = "haste", armor = "armor"}

-- f = {slot, query, quality (-1 any), minIlvl, maxIlvl, source (bit, 0 any), stats = {{key,min},...},
--      maxReq (nil any), class (nil any), showHidden}. Returns index positions in item-level order.
function IDX:Query(f)
  self:Finish()
  local out = {}
  local bucket = self.bySlot[f.slot or "ALL"] or self.bySlot.ALL
  local query = f.query or ""
  local alias = STAT_ALIASES[query]
  local cbit = f.class and CLASS_BITS[f.class]
  local quality, minI, maxI, src, maxReq = f.quality or -1, f.minIlvl, f.maxIlvl, f.source or 0, f.maxReq
  local statList = f.stats or {}
  local nStats = table.getn(statList)
  local qs, ilvl, req, hidden, cls, srcm, names, srcText, stats = self.q, self.ilvl, self.req, self.hidden, self.class, self.src, self.name, self.srcText, self.stats
  local i, p, ok, j, st, v, mask
  for i = 1, table.getn(bucket) do
    p = bucket[i]; ok = true
    if quality >= 0 and qs[p] ~= quality then ok = false
    elseif minI and ilvl[p] < minI then ok = false
    elseif maxI and ilvl[p] > maxI then ok = false
    elseif maxReq and req[p] > maxReq then ok = false
    elseif not f.showHidden and hidden[p] then ok = false
    elseif src > 0 and not HasBit(srcm[p], src) then ok = false end
    if ok and cbit then mask = cls[p]; if mask >= 0 and not HasBit(mask, cbit) then ok = false end end
    if ok and nStats > 0 then
      st = stats[p]
      for j = 1, nStats do v = st[statList[j][1]]; if not v or v <= 0 or v < (statList[j][2] or 0) then ok = false; break end end
    end
    if ok and query ~= "" then
      ok = string.find(names[p], query, 1, true) or string.find(srcText[p], query, 1, true) or (alias and stats[p][alias] and stats[p][alias] ~= 0)
    end
    if ok then table.insert(out, p) end
  end
  return out
end

-- Background build: a few hundred items per frame after login.
local builder = CreateFrame("Frame")
builder:RegisterEvent("PLAYER_ENTERING_WORLD")
builder:SetScript("OnEvent", function()
  this:UnregisterEvent("PLAYER_ENTERING_WORLD")
  this:SetScript("OnUpdate", function() if IDX:Step(400) then this:SetScript("OnUpdate", nil) end end)
end)
