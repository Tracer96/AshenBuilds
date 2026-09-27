AshenBuilds = AshenBuilds or {}
local AB = AshenBuilds

-- Community builds: players publish saved builds, everyone running the addon
-- keeps a copy of what they have heard, and upvotes travel the same way.
--
-- There is no server, so data moves peer to peer over two transports:
--   * addon messages to GUILD (and RAID/PARTY when grouped), invisible to players;
--   * a realm-wide custom channel, joined automatically and hidden from chat.
-- Turtle WoW shares custom channels (and parties/raids) between Horde and
-- Alliance, so the list is server-wide.
--
-- Messages are "~"-separated fields. The sender name comes from the chat event
-- (set by the server), which is what makes authorship and votes trustworthy:
--   P~ver~name~code~sum      author publishes or updates one of their builds
--   U~ver~name               author withdraws a build
--   V~author~name~1|0        sender upvotes (1) or removes their upvote (0)
--   Q                        sender just came online and wants the catalog
--   R~requester              sender is answering requester's Q (others stand down)
--   F~author~ver~name~code~sum  relayed copy of someone else's build
-- "sum" is a checksum of name+code: if a message is altered in transit (e.g.
-- cross-faction language scrambling) the build is dropped instead of loading
-- the wrong items.
--   W~author~name~a,b,c      relayed voter list for a build
-- Relayed data (F/W) cannot be verified, so it never overrides what an author
-- sent directly; an author's own P always wins.

local PREFIX = "ASHB"
local CHANNEL = "AshenBuilds"
local MARK = "~ASHB1~"
local SEND_INTERVAL = 1.1      -- seconds between outgoing messages (chat throttle safety)
local QUERY_COOLDOWN = 120     -- minimum seconds between our own sync requests
local ANNOUNCE_COOLDOWN = 60   -- minimum seconds between re-announcing our own builds
local RELAY_COOLDOWN = 600     -- minimum seconds between relays we perform
local RELAY_LIMIT = 60         -- builds relayed per answer
local MAX_BUILDS = 1000
local MAX_VOTERS = 500
local EXPIRE = 60 * 86400      -- forget builds nobody has mentioned for 60 days
local MAX_NAME = 32
local MAX_CLOCK_SKEW = 86400

local Enc, Dec = AB.EncodeNumber, AB.DecodeNumber
local MAX_QUEUE = 300

local function Now() return time() end
local function Me() return UnitName("player") or "" end

-- Strips characters that would break the wire format or chat links.
function AB:CleanCommunityText(text)
  text = string.gsub(tostring(text or ""), "[~|,%c]", "")
  text = string.gsub(text, "^%s+", ""); text = string.gsub(text, "%s+$", "")
  if string.len(text) > MAX_NAME then text = string.sub(text, 1, MAX_NAME) end
  return text
end
local function Clean(text) return AB:CleanCommunityText(text) end

local function Split(msg)
  local out, start, pos = {}, 1, nil
  while true do
    pos = string.find(msg, "~", start, true)
    if not pos then table.insert(out, string.sub(msg, start)); return out end
    table.insert(out, string.sub(msg, start, pos - 1)); start = pos + 1
  end
end

local function Checksum(name, code)
  local text, sum, i = name .. "~" .. code, 0, nil
  for i = 1, string.len(text) do sum = math.mod(sum * 31 + string.byte(text, i), 16777213) end
  return Enc(sum)
end

local function BuildId(author, name) return author .. ":" .. name end

local function DB()
  AshenBuildsDB = AshenBuildsDB or {}
  local c = AshenBuildsDB.community
  if not c then c = {}; AshenBuildsDB.community = c end
  c.builds = c.builds or {}; c.mine = c.mine or {}; c.votes = c.votes or {}; c.tomb = c.tomb or {}
  return c
end

local function CountKeys(t) local n = 0; local k; for k in pairs(t or {}) do n = n + 1 end; return n end

local function RefreshViews()
  if AB.RefreshCommunityList then AB:RefreshCommunityList() end
  if AB.RefreshBuildList then AB:RefreshBuildList() end
end

---------------------------------------------------------------------------
-- Scheduling and outgoing queue
---------------------------------------------------------------------------
local timers, queue, sinceSend = {}, {}, SEND_INTERVAL
local clock = CreateFrame("Frame")

local function After(delay, key, fn)
  timers[key] = {at = GetTime() + delay, fn = fn}
end
local function Cancel(key) timers[key] = nil end

local function ChannelId()
  local id = GetChannelName(CHANNEL)
  return tonumber(id) or 0
end

local function Transmit(msg)
  if IsInGuild() then SendAddonMessage(PREFIX, msg, "GUILD") end
  if GetNumRaidMembers() > 0 then SendAddonMessage(PREFIX, msg, "RAID")
  elseif GetNumPartyMembers() > 0 then SendAddonMessage(PREFIX, msg, "PARTY") end
  local id = ChannelId()
  if id > 0 then SendChatMessage(MARK .. msg, "CHANNEL", nil, id) end
end

local function Send(msg) if table.getn(queue) < MAX_QUEUE then table.insert(queue, msg) end end

clock:SetScript("OnUpdate", function()
  -- Collect due timers first: callbacks may schedule new ones, and adding keys
  -- while iterating with pairs is undefined in Lua 5.0.
  local now, due, key, t, i = GetTime(), {}, nil, nil, nil
  for key, t in pairs(timers) do if now >= t.at then table.insert(due, key) end end
  for i = 1, table.getn(due) do t = timers[due[i]]; timers[due[i]] = nil; if t then t.fn() end end
  sinceSend = sinceSend + arg1
  if sinceSend >= SEND_INTERVAL and table.getn(queue) > 0 then
    sinceSend = 0
    Transmit(table.remove(queue, 1))
  end
end)

---------------------------------------------------------------------------
-- Catalog
---------------------------------------------------------------------------
-- Stores a build heard from the network (confirmed = sent by its author).
local function ApplyBuild(author, name, ver, code, confirmed)
  if not ver or name == "" or author == "" then return end
  -- Versions are the author's clock; reject far-future ones so a forged relay
  -- can't pin a build with a version nobody can ever beat.
  if ver > Now() + MAX_CLOCK_SKEW then return end
  local c = DB(); local id = BuildId(author, name)
  local tomb = c.tomb[id]
  if tomb and tomb.ver >= ver then return end
  local e = c.builds[id]
  if e then
    e.seen = Now()
    if e.confirmed and not confirmed then return end
    if confirmed == (e.confirmed and true or false) and ver <= e.ver then return end
  elseif not confirmed and CountKeys(c.builds) >= MAX_BUILDS then
    return
  end
  local build = AB:DecodeBuild(code)
  if not build then return end
  e = e or {}
  e.id = id; e.author = author; e.name = name; e.ver = ver; e.code = code; e.confirmed = confirmed and true or false; e.seen = Now()
  e.class = build.class; e.race = build.race; e.level = build.level; e.spec = build.spec
  c.builds[id] = e
  RefreshViews()
end

local function RemoveBuild(id, ver)
  local c = DB()
  c.tomb[id] = {ver = ver, t = Now()}
  c.builds[id] = nil; c.votes[id] = nil
  RefreshViews()
end

local function SetVote(id, voter, on)
  local c = DB(); local e = c.builds[id]
  if e and e.author == voter then return end
  local v = c.votes[id]
  if on then
    if not v then v = {}; c.votes[id] = v end
    if not v[voter] and CountKeys(v) >= MAX_VOTERS then return end
    v[voter] = true
  elseif v then
    v[voter] = nil
  end
end

local function PruneCatalog()
  local c, cutoff, id, e = DB(), Now() - EXPIRE, nil, nil
  local me = Me()
  for id, e in pairs(c.builds) do
    if e.author ~= me and (e.seen or 0) < cutoff then c.builds[id] = nil; c.votes[id] = nil end
  end
  for id, e in pairs(c.tomb) do if (e.t or 0) < cutoff then c.tomb[id] = nil end end
end

---------------------------------------------------------------------------
-- Publishing and voting (local actions)
---------------------------------------------------------------------------
function AB:IsBuildPublished(name) return DB().mine[name] ~= nil end

local function AnnounceOwn(name)
  local c, me = DB(), Me()
  local e = c.builds[BuildId(me, name)]
  if e then Send("P~" .. Enc(e.ver) .. "~" .. e.name .. "~" .. e.code .. "~" .. Checksum(e.name, e.code)) end
end

function AB:PublishBuild(name)
  local saved = AshenBuildsDB.builds[name]; if not saved then return end
  local wire = Clean(name)
  if wire ~= name then
    self:Print("Build names used for publishing can't contain ~ | or commas, or exceed " .. MAX_NAME .. " characters. Rename the build and save it again.")
    return
  end
  local c, me = DB(), Me()
  local id, ver = BuildId(me, name), Now()
  local old = c.builds[id]
  if old and old.ver >= ver then ver = old.ver + 1 end
  c.tomb[id] = nil
  c.mine[name] = true
  local code = self:ExportBuild(saved)
  c.builds[id] = {id = id, author = me, name = name, ver = ver, code = code, confirmed = true, seen = Now(),
    class = saved.class, race = saved.race, level = self:GetBuildLevel(saved), spec = saved.spec}
  AnnounceOwn(name)
  self:Print("Published |cffffffff" .. name .. "|r to community builds.")
  RefreshViews()
end

function AB:UnpublishBuild(name)
  local c, me = DB(), Me()
  if not c.mine[name] then return end
  local id = BuildId(me, name)
  local ver = Now(); local e = c.builds[id]
  if e and e.ver >= ver then ver = e.ver + 1 end
  c.mine[name] = nil
  RemoveBuild(id, ver)
  Send("U~" .. Enc(ver) .. "~" .. name)
  self:Print("Withdrew |cffffffff" .. name .. "|r from community builds.")
end

-- Re-saving a published build republishes it; deleting withdraws it.
function AB:OnBuildSaved(name) if self:IsBuildPublished(name) then self:PublishBuild(name) end end
function AB:OnBuildDeleted(name) if self:IsBuildPublished(name) then self:UnpublishBuild(name) end end

function AB:HasVoted(id) local v = DB().votes[id]; return v and v[Me()] and true or false end
function AB:GetVoteCount(id) return CountKeys(DB().votes[id]) end

function AB:ToggleVote(id)
  local c, me = DB(), Me(); local e = c.builds[id]
  if not e or e.author == me then return end
  local on = not self:HasVoted(id)
  SetVote(id, me, on)
  Send("V~" .. e.author .. "~" .. e.name .. "~" .. (on and "1" or "0"))
  RefreshViews()
end

function AB:GetCommunityBuilds()
  local list, me, id, e = {}, Me(), nil, nil
  for id, e in pairs(DB().builds) do
    e.votes = self:GetVoteCount(id); e.mine = (e.author == me); e.voted = self:HasVoted(id)
    table.insert(list, e)
  end
  return list
end

function AB:LoadCommunityBuild(id)
  local e = DB().builds[id]; if not e then return end
  local build = self:DecodeBuild(e.code); if not build then return end
  build.name = e.name .. " (" .. e.author .. ")"
  self.current = build; AshenBuildsDB.current = build; self:RefreshUI()
  self:Print("Loaded |cffffffff" .. e.name .. "|r by " .. e.author .. ". Save it to keep a copy.")
end

---------------------------------------------------------------------------
-- Sync
---------------------------------------------------------------------------
-- Start far in the past: GetTime() counts from computer boot, so it can be small.
local NEVER = -1e9
local lastQuery, lastAnnounce, lastRelay = NEVER, NEVER, NEVER

function AB:RequestCommunitySync(force)
  local now = GetTime()
  if not force and now - lastQuery < QUERY_COOLDOWN then return false end
  lastQuery = now
  Send("Q")
  return true
end

local function AnnounceAllOwn()
  local now = GetTime()
  if now - lastAnnounce < ANNOUNCE_COOLDOWN then return end
  lastAnnounce = now
  local c, me, name, id, t = DB(), Me(), nil, nil, nil
  for name in pairs(c.mine) do AnnounceOwn(name) end
  -- Repeat our recent withdrawals so players who were offline drop them too.
  local prefix = me .. ":"
  for id, t in pairs(c.tomb) do
    if string.sub(id, 1, string.len(prefix)) == prefix then Send("U~" .. Enc(t.ver) .. "~" .. string.sub(id, string.len(prefix) + 1)) end
  end
end

local function Relay(requester)
  lastRelay = GetTime()
  local list, me, i, e, voters, v, chunk = AB:GetCommunityBuilds(), Me(), nil, nil, nil, nil, nil
  table.sort(list, function(a, b) if a.votes ~= b.votes then return a.votes > b.votes end return a.seen > b.seen end)
  Send("R~" .. requester)
  local sent = 0
  for i = 1, table.getn(list) do
    e = list[i]
    if sent >= RELAY_LIMIT then break end
    if e.author ~= me and e.author ~= requester then
      Send("F~" .. e.author .. "~" .. Enc(e.ver) .. "~" .. e.name .. "~" .. e.code .. "~" .. Checksum(e.name, e.code))
      -- Voter lists are split so every message stays under the chat length limit.
      chunk = ""
      for v in pairs(DB().votes[e.id] or {}) do
        if string.len(chunk) + string.len(v) > 150 then Send("W~" .. e.author .. "~" .. e.name .. "~" .. chunk); chunk = "" end
        chunk = (chunk == "" and v) or (chunk .. "," .. v)
      end
      if chunk ~= "" then Send("W~" .. e.author .. "~" .. e.name .. "~" .. chunk) end
      sent = sent + 1
    end
  end
end

---------------------------------------------------------------------------
-- Incoming
---------------------------------------------------------------------------
function AB:HandleCommunityMessage(sender, msg)
  if not sender or sender == "" or sender == Me() or not msg then return end
  local f = Split(msg); local kind = f[1]
  if kind == "P" and f[5] then
    if f[5] == Checksum(f[3], f[4]) then ApplyBuild(sender, Clean(f[3]), Dec(f[2]), f[4], true) end
  elseif kind == "F" and f[6] then
    local author = Clean(f[2])
    if author ~= Me() and f[6] == Checksum(f[4], f[5]) then ApplyBuild(author, Clean(f[4]), Dec(f[3]), f[5], false) end
  elseif kind == "U" and f[3] then
    local id, ver = BuildId(sender, Clean(f[3])), Dec(f[2])
    local e = DB().builds[id]
    -- The author outranks any relayed copy; only their own newer P beats a U.
    if ver and ver <= Now() + MAX_CLOCK_SKEW and (not e or not e.confirmed or e.ver <= ver) then RemoveBuild(id, ver) end
  elseif kind == "V" and f[4] then
    SetVote(BuildId(Clean(f[2]), Clean(f[3])), sender, f[4] == "1"); RefreshViews()
  elseif kind == "W" and f[4] then
    local id, voter = BuildId(Clean(f[2]), Clean(f[3])), nil
    for voter in string.gfind(f[4], "[^,]+") do voter = Clean(voter); if voter ~= "" then SetVote(id, voter, true) end end
    RefreshViews()
  elseif kind == "Q" then
    After(1 + math.random() * 3, "announce", AnnounceAllOwn)
    if GetTime() - lastRelay >= RELAY_COOLDOWN and CountKeys(DB().builds) > 0 then
      -- Random delay so one player answers; everyone else hears the R and stands down.
      After(3 + math.random() * 9, "relay", function() Relay(sender) end)
    end
  elseif kind == "R" then
    Cancel("relay")
  end
end

---------------------------------------------------------------------------
-- Channel setup and chat hiding
---------------------------------------------------------------------------
-- arg9 is the bare channel name; arg4 ("5. AshenBuilds") is checked as a fallback.
local function IsOurChannel(name, display)
  local want = string.lower(CHANNEL)
  if name and string.lower(name) == want then return true end
  return display and string.find(string.lower(display), "%. " .. want .. "$") and true or false
end

-- Hides channel traffic from every chat window, the same way LeafVillageLegends
-- hides its channel: drop any rendered line that carries our marker or names
-- our channel (join/leave notices).
local function HideFromChat()
  local i, frame
  local needle = string.lower(". " .. CHANNEL .. "]")
  for i = 1, (NUM_CHAT_WINDOWS or 7) do
    frame = getglobal("ChatFrame" .. i)
    if frame then
      if ChatFrame_RemoveChannel then ChatFrame_RemoveChannel(frame, CHANNEL) end
      if not frame.ashenBuildsWrapped then
        frame.ashenBuildsWrapped = true
        local original = frame.AddMessage
        frame.AddMessage = function(self, text, ...)
          if type(text) == "string" and (string.find(text, MARK, 1, true) or string.find(string.lower(text), needle, 1, true)) then return end
          return original(self, text, unpack(arg))
        end
      end
    end
  end
end

local joinAttempts = 0
local function EnsureChannel()
  HideFromChat()
  if ChannelId() > 0 then
    HideFromChat()
    AB:RequestCommunitySync(true)
    After(5, "announce", AnnounceAllOwn)
    return
  end
  joinAttempts = joinAttempts + 1
  if joinAttempts > 5 then
    -- Guild/party sync still works without the channel.
    AB:RequestCommunitySync(true)
    return
  end
  JoinChannelByName(CHANNEL)
  After(3, "join", EnsureChannel)
end

local events = CreateFrame("Frame")
events:RegisterEvent("ADDON_LOADED")
events:RegisterEvent("PLAYER_ENTERING_WORLD")
events:RegisterEvent("CHAT_MSG_ADDON")
events:RegisterEvent("CHAT_MSG_CHANNEL")
events:SetScript("OnEvent", function()
  if event == "ADDON_LOADED" and arg1 == "AshenBuilds" then
    DB(); PruneCatalog()
  elseif event == "PLAYER_ENTERING_WORLD" then
    -- Joining late keeps General/Trade on their usual channel numbers.
    if not events.started then events.started = true; After(8, "join", EnsureChannel) end
  elseif event == "CHAT_MSG_ADDON" then
    if arg1 == PREFIX then AB:HandleCommunityMessage(arg4, arg2) end
  elseif event == "CHAT_MSG_CHANNEL" then
    if IsOurChannel(arg9, arg4) and type(arg1) == "string" and string.sub(arg1, 1, string.len(MARK)) == MARK then
      AB:HandleCommunityMessage(arg2, string.sub(arg1, string.len(MARK) + 1))
    end
  end
end)

function AB:GetCommunityStatus()
  return ChannelId() > 0, IsInGuild() and true or false, CountKeys(DB().builds)
end
