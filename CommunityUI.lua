AshenBuilds = AshenBuilds or {}
local AB = AshenBuilds

local ROWS = 11
local ROW_TOP, ROW_STEP = -110, 36
local ARROW_UP = "Interface\\Buttons\\UI-ScrollBar-ScrollUpButton-Up"
local ARROW_DOWN = "Interface\\Buttons\\UI-ScrollBar-ScrollDownButton-Up"

-- Column x offsets are relative to the row's left edge.
local COLUMNS = {
  {key = "name", label = "BUILD", x = 8, w = 226, numeric = false},
  {key = "class", label = "CLASS", x = 240, w = 86, numeric = false},
  {key = "race", label = "RACE", x = 330, w = 86, numeric = false},
  {key = "level", label = "LEVEL", x = 420, w = 46, numeric = true},
  {key = "spec", label = "SPEC", x = 470, w = 104, numeric = false},
  {key = "votes", label = "VOTES", x = 580, w = 110, numeric = true},
}

local function Button(parent, text, width, height)
  local b = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
  b:SetWidth(width); b:SetHeight(height); b:SetText(text)
  AB:SkinButton(b, "ember")
  return b
end

local function Muted(fs) local m = AB.THEME.muted; fs:SetTextColor(m[1], m[2], m[3]) end

local function ClassColor(class)
  local c = RAID_CLASS_COLORS and RAID_CLASS_COLORS[string.upper(class or "")]
  if c then return c.r, c.g, c.b end
  return 1, 1, 1
end

AB.communitySort = AB.communitySort or "votes"
AB.communityDesc = AB.communityDesc ~= false
AB.communityPage = 1

local function SortValue(e, key)
  if key == "name" or key == "class" or key == "race" or key == "spec" then return string.lower(e[key] or "") end
  return tonumber(e[key]) or 0
end

-- Ties fall back to votes, then name, then id, so the order is always stable.
local function Compare(a, b)
  local key, desc = AB.communitySort, AB.communityDesc
  local x, y = SortValue(a, key), SortValue(b, key)
  if x ~= y then if desc then return x > y end return x < y end
  if a.votes ~= b.votes then return a.votes > b.votes end
  local an, bn = string.lower(a.name), string.lower(b.name)
  if an ~= bn then return an < bn end
  return a.id < b.id
end

function AB:GetFilteredCommunityBuilds()
  local all, out, query, i, e = self:GetCommunityBuilds(), {}, "", nil, nil
  if self.communitySearch then query = string.lower(self.communitySearch:GetText() or "") end
  for i = 1, table.getn(all) do
    e = all[i]
    if query == "" or string.find(string.lower(e.name), query, 1, true) or string.find(string.lower(e.author), query, 1, true) then
      table.insert(out, e)
    end
  end
  table.sort(out, Compare)
  return out
end

function AB:SetCommunitySort(key, numeric)
  if self.communitySort == key then
    self.communityDesc = not self.communityDesc
  else
    -- Numbers start highest-first; text starts A-Z.
    self.communitySort = key; self.communityDesc = numeric and true or false
  end
  self.communityPage = 1
  self:RefreshCommunityList()
end

function AB:ScrollCommunityPage(delta)
  if delta < 0 then self.communityPage = self.communityPage + 1
  elseif self.communityPage > 1 then self.communityPage = self.communityPage - 1
  else return end
  self:RefreshCommunityList()
end

local function ShowRowTooltip(row)
  local e = row.entry; if not e then return end
  GameTooltip:SetOwner(row, "ANCHOR_RIGHT")
  GameTooltip:SetText(e.name, 1, 0.82, 0.28)
  GameTooltip:AddLine("by " .. e.author, 0.85, 0.85, 0.85)
  local r, g, b = ClassColor(e.class)
  GameTooltip:AddLine("Level " .. e.level .. " " .. e.race .. " " .. e.class .. " - " .. e.spec, r, g, b)
  GameTooltip:AddLine(e.votes .. " upvote" .. (e.votes == 1 and "" or "s") .. "  -  published " .. date("%Y-%m-%d", e.ver), 0.85, 0.85, 0.85)
  if not e.confirmed then GameTooltip:AddLine("Passed along by another player; not yet seen from the author.", 1, 0.6, 0.3, 1) end
  GameTooltip:AddLine("Left-click to load into the planner.", 0.4, 1, 0.4)
  GameTooltip:Show()
end

local function ShowVoteTooltip(button)
  local e = button:GetParent().entry; if not e then return end
  GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
  GameTooltip:SetText(e.voted and "Remove your upvote" or "Upvote this build", 1, 1, 1)
  GameTooltip:Show()
end

function AB:CreateCommunityUI()
  if self.communityFrame then return end
  local f = CreateFrame("Frame", "AshenBuildsCommunity", UIParent)
  f:SetWidth(760); f:SetHeight(580); f:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
  f:SetBackdrop({bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background", edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border", tile = true, tileSize = 32, edgeSize = 24, insets = {left = 8, right = 8, top = 8, bottom = 8}})
  self:SetupWindow(f, {fit = true, wheel = function() AB:ScrollCommunityPage(arg1) end})
  f:Hide(); self.communityFrame = f
  self:ApplyEmberBackground(f, 10, 0.5, 0.5, 0.4); self:AddEmberHeader(f, 34); self:AddEmberWell(f, 22, -80, -22, 48)
  f:SetScript("OnShow", function() AB:FitToScreen(this); AB:FocusWindow(this); AB:RefreshCommunityList() end)

  local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge"); title:SetPoint("TOP", f, "TOP", 0, -17); title:SetText("COMMUNITY BUILDS")
  local close = CreateFrame("Button", nil, f, "UIPanelCloseButton"); close:SetPoint("TOPRIGHT", f, "TOPRIGHT", -4, -4)

  local searchLabel = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall"); searchLabel:SetPoint("TOPLEFT", f, "TOPLEFT", 28, -54); searchLabel:SetText("SEARCH")
  local search = CreateFrame("EditBox", "AshenBuildsCommunitySearch", f, "InputBoxTemplate")
  search:SetWidth(240); search:SetHeight(24); search:SetPoint("LEFT", searchLabel, "RIGHT", 12, 0); search:SetAutoFocus(false)
  search:SetScript("OnTextChanged", function() AB.communityPage = 1; AB:RefreshCommunityList() end)
  self.communitySearch = search
  local clear = Button(f, "Clear", 58, 22); clear:SetPoint("LEFT", search, "RIGHT", 6, 0); clear:SetScript("OnClick", function() search:SetText(""); search:ClearFocus() end)
  local hint = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall"); hint:SetPoint("LEFT", clear, "RIGHT", 10, 0); hint:SetText("build or player name"); Muted(hint)

  local refresh = Button(f, "Refresh", 82, 22); refresh:SetPoint("TOPRIGHT", f, "TOPRIGHT", -30, -50)
  refresh:SetScript("OnClick", function()
    if AB:RequestCommunitySync() then AB.communityNotice = "Asked other players for builds..." else AB.communityNotice = "Already asked recently - new builds still arrive automatically." end
    AB:RefreshCommunityList()
  end)

  -- Column headers double as sort buttons.
  self.communityHeaders = {}
  local i, col, h
  for i = 1, table.getn(COLUMNS) do
    col = COLUMNS[i]
    h = CreateFrame("Button", nil, f); h:SetWidth(col.w); h:SetHeight(20); h:SetPoint("TOPLEFT", f, "TOPLEFT", 30 + col.x, -86)
    h.label = h:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall"); h.label:SetPoint("LEFT", h, "LEFT", 0, 0); h.label:SetText(col.label)
    h.arrow = h:CreateTexture(nil, "OVERLAY"); h.arrow:SetWidth(16); h.arrow:SetHeight(16); h.arrow:SetPoint("LEFT", h.label, "RIGHT", 0, 0)
    h:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
    h.key = col.key; h.numeric = col.numeric
    h:SetScript("OnClick", function() AB:SetCommunitySort(this.key, this.numeric) end)
    h:SetScript("OnEnter", function() GameTooltip:SetOwner(this, "ANCHOR_TOP"); GameTooltip:SetText("Sort by " .. string.lower(this.label:GetText()), 1, 1, 1); GameTooltip:AddLine("Click again to reverse.", 0.85, 0.85, 0.85); GameTooltip:Show() end)
    h:SetScript("OnLeave", function() GameTooltip:Hide() end)
    self.communityHeaders[i] = h
  end
  local rule = f:CreateTexture(nil, "ARTWORK"); local d = self.THEME.divider
  rule:SetTexture(d[1], d[2], d[3], d[4]); rule:SetPoint("TOPLEFT", f, "TOPLEFT", 28, -106); rule:SetWidth(704); rule:SetHeight(1)

  self.communityRows = {}
  local r, fs, j
  for i = 1, ROWS do
    r = CreateFrame("Button", nil, f); r:SetWidth(700); r:SetHeight(32); r:SetPoint("TOPLEFT", f, "TOPLEFT", 30, ROW_TOP - (i - 1) * ROW_STEP)
    r:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
    r.name = r:CreateFontString(nil, "OVERLAY", "GameFontHighlight"); r.name:SetPoint("TOPLEFT", r, "TOPLEFT", COLUMNS[1].x, -2); r.name:SetWidth(COLUMNS[1].w); r.name:SetJustifyH("LEFT")
    r.author = r:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall"); r.author:SetPoint("TOPLEFT", r.name, "BOTTOMLEFT", 0, -1); r.author:SetWidth(COLUMNS[1].w); r.author:SetJustifyH("LEFT"); Muted(r.author)
    r.cells = {}
    for j = 2, 5 do
      fs = r:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall"); fs:SetPoint("LEFT", r, "LEFT", COLUMNS[j].x, 0); fs:SetWidth(COLUMNS[j].w); fs:SetJustifyH("LEFT")
      r.cells[COLUMNS[j].key] = fs
    end
    r.vote = CreateFrame("Button", nil, r); r.vote:SetWidth(24); r.vote:SetHeight(24); r.vote:SetPoint("LEFT", r, "LEFT", COLUMNS[6].x - 4, 0)
    r.vote:SetNormalTexture(ARROW_UP); r.vote:SetPushedTexture("Interface\\Buttons\\UI-ScrollBar-ScrollUpButton-Down")
    r.vote:SetHighlightTexture("Interface\\Buttons\\UI-ScrollBar-ScrollUpButton-Highlight")
    r.vote:SetScript("OnClick", function() local e = this:GetParent().entry; if e then AB:ToggleVote(e.id) end end)
    r.vote:SetScript("OnEnter", function() ShowVoteTooltip(this) end); r.vote:SetScript("OnLeave", function() GameTooltip:Hide() end)
    r.votes = r:CreateFontString(nil, "OVERLAY", "GameFontHighlight"); r.votes:SetPoint("LEFT", r, "LEFT", COLUMNS[6].x + 24, 0); r.votes:SetWidth(COLUMNS[6].w - 24); r.votes:SetJustifyH("LEFT")
    r:SetScript("OnClick", function() if this.entry then AB:LoadCommunityBuild(this.entry.id) end end)
    r:SetScript("OnEnter", function() ShowRowTooltip(this) end); r:SetScript("OnLeave", function() GameTooltip:Hide() end)
    self.communityRows[i] = r
  end

  self.communityEmpty = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight"); self.communityEmpty:SetPoint("TOP", f, "TOP", 0, -200); self.communityEmpty:SetWidth(560); Muted(self.communityEmpty)

  self.communityPrev = Button(f, "Previous", 82, 22); self.communityPrev:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 28, 18); self.communityPrev:SetScript("OnClick", function() AB:ScrollCommunityPage(1) end)
  self.communityNext = Button(f, "Next", 82, 22); self.communityNext:SetPoint("LEFT", self.communityPrev, "RIGHT", 8, 0); self.communityNext:SetScript("OnClick", function() AB:ScrollCommunityPage(-1) end)
  self.communityPageText = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight"); self.communityPageText:SetPoint("LEFT", self.communityNext, "RIGHT", 12, 0)
  self.communityStatus = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall"); self.communityStatus:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -28, 24); self.communityStatus:SetJustifyH("RIGHT"); Muted(self.communityStatus)
end

function AB:RefreshCommunityList()
  if not self.communityFrame or not self.communityFrame:IsShown() then return end
  local list = self:GetFilteredCommunityBuilds()
  local total, pages = table.getn(list), nil
  pages = math.max(1, math.ceil(total / ROWS))
  if self.communityPage > pages then self.communityPage = pages end

  local i, h
  for i = 1, table.getn(self.communityHeaders) do
    h = self.communityHeaders[i]
    if h.key == self.communitySort then
      h.label:SetTextColor(1, 1, 1); h.arrow:SetTexture(self.communityDesc and ARROW_DOWN or ARROW_UP); h.arrow:Show()
    else
      h.label:SetTextColor(1, 0.82, 0); h.arrow:Hide()
    end
  end

  local row, e, r, g, b, t
  for i = 1, ROWS do
    row = self.communityRows[i]; e = list[(self.communityPage - 1) * ROWS + i]; row.entry = e
    if e then
      row.name:SetText(e.name)
      row.author:SetText("by " .. e.author .. (e.mine and "  (you)" or ""))
      r, g, b = ClassColor(e.class); row.cells.class:SetText(e.class); row.cells.class:SetTextColor(r, g, b)
      row.cells.race:SetText(e.race); row.cells.level:SetText(tostring(e.level)); row.cells.spec:SetText(e.spec)
      if e.mine then
        row.vote:Hide(); row.votes:SetText(e.votes .. "  |cffbdb8adyours|r"); row.votes:SetTextColor(1, 1, 1)
      else
        row.vote:Show()
        t = row.vote:GetNormalTexture()
        -- Voted state is shown by both colour and the word "voted", not colour alone.
        if e.voted then
          t:SetVertexColor(1, 0.82, 0.28); row.votes:SetText(e.votes .. "  voted"); row.votes:SetTextColor(1, 0.82, 0.28)
        else
          t:SetVertexColor(1, 1, 1); row.votes:SetText(e.votes); row.votes:SetTextColor(1, 1, 1)
        end
      end
      row:Show()
    else
      row:Hide()
    end
  end

  local query = self.communitySearch:GetText() or ""
  if total > 0 then self.communityEmpty:Hide()
  else
    self.communityEmpty:SetText(query ~= "" and "No builds match \"" .. query .. "\"." or "No community builds yet.\n\nPublish one from Saved Builds, or press Refresh to ask other players.")
    self.communityEmpty:Show()
  end

  self.communityPageText:SetText("Page " .. self.communityPage .. " / " .. pages .. "  (" .. total .. " builds)")
  if self.communityPage > 1 then self.communityPrev:Enable() else self.communityPrev:Disable() end
  if self.communityPage < pages then self.communityNext:Enable() else self.communityNext:Disable() end

  local channel, guild = self:GetCommunityStatus()
  local reach = (channel and "realm channel" or "") .. ((channel and guild) and " + " or "") .. (guild and "guild" or "")
  if reach == "" then reach = "offline - connecting" end
  self.communityStatus:SetText((self.communityNotice and (self.communityNotice .. "\n") or "") .. "Sharing via " .. reach)
end

function AB:OpenCommunity()
  self.communityNotice = nil
  if self.communityFrame:IsShown() then self:FocusWindow(self.communityFrame) else self.communityFrame:Show() end
  self:RequestCommunitySync()
end

local oldCreate = AB.CreateUI
function AB:CreateUI()
  oldCreate(self)
  self:CreateCommunityUI()
end
