AshenBuilds = AshenBuilds or {}
local AB = AshenBuilds

local function backdrop(frame)
  frame:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true,
    tileSize = 32,
    edgeSize = 32,
    insets = {left = 11, right = 12, top = 12, bottom = 11}
  })
end

local function button(parent, text, width, height)
  local result = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
  result:SetWidth(width)
  result:SetHeight(height)
  result:SetText(text)
  return result
end

local function createTreePanel(parent, treeIndex)
  local panel = CreateFrame("Frame", nil, parent)
  panel:SetWidth(310)
  panel:SetHeight(590)
  panel:SetPoint("TOPLEFT", parent, "TOPLEFT", 30 + ((treeIndex - 1) * 330), -92)
  panel:SetFrameLevel(parent:GetFrameLevel() + 1)
  panel:SetBackdrop({
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    edgeSize = 16,
    insets = {left = 4, right = 4, top = 4, bottom = 4}
  })
  panel:SetBackdropBorderColor(0.58, 0.43, 0.22, 1)

  panel.tiles = {}
  local tileFiles = {
    "UniversalSpecPanel_01", "UniversalSpecPanel_02",
    "UniversalSpecPanel_03", "UniversalSpecPanel_04",
    "UniversalSpecPanel_05", "UniversalSpecPanel_06",
    "UniversalSpecPanel_07", "UniversalSpecPanel_08",
    "UniversalSpecPanel_09", "UniversalSpecPanel_10"
  }
  local tileIndex = 1
  local row = 1
  local col = 1
  local tile = nil
  for row = 1, 5 do
    for col = 1, 2 do
      tile = panel:CreateTexture(nil, "BACKGROUND")
      tile:SetTexture("Interface\\AddOns\\AshenBuilds\\Textures\\SpecPanels\\" .. tileFiles[tileIndex])
      tile:SetWidth(151)
      tile:SetHeight(116)
      tile:SetPoint("TOPLEFT", panel, "TOPLEFT", 4 + ((col - 1) * 151), -4 - ((row - 1) * 116))
      tile:SetTexCoord(0, 1, 0, 1)
      tile:SetVertexColor(1, 1, 1, 1)
      panel.tiles[tileIndex] = tile
      tileIndex = tileIndex + 1
    end
  end

  panel.shade = panel:CreateTexture(nil, "BORDER")
  panel.shade:SetTexture(0, 0, 0, 0.40)
  panel.shade:SetPoint("TOPLEFT", panel, "TOPLEFT", 4, -4)
  panel.shade:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -4, 4)

  panel.headerShade = panel:CreateTexture(nil, "ARTWORK")
  panel.headerShade:SetTexture(0.06, 0.035, 0.015, 0.80)
  panel.headerShade:SetPoint("TOPLEFT", panel, "TOPLEFT", 5, -5)
  panel.headerShade:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -5, -5)
  panel.headerShade:SetHeight(38)

  panel.title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  panel.title:SetPoint("TOP", panel, "TOP", 0, -14)
  panel.title:SetText("Tree " .. treeIndex)

  panel.points = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  panel.points:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -14, -15)
  panel.points:SetText("0")

  return panel
end

function AB:CreateTalentUI()
  if self.talentFrame then return end

  local open = button(self.frame, "TALENTS", 105, 24)
  open:SetPoint("TOPRIGHT", self.frame, "TOPRIGHT", -300, -108)
  open:SetScript("OnClick", function()
    AB.talentFrame:Show()
    AB:RefreshTalentUI()
  end)
  self.talentOpenButton = open

  local frame = CreateFrame("Frame", nil, UIParent)
  frame:SetWidth(1060)
  frame:SetHeight(730)
  frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
  frame:SetFrameStrata("FULLSCREEN_DIALOG")
  backdrop(frame)
  frame:Hide()
  self.talentFrame = frame

  local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  title:SetPoint("TOP", frame, "TOP", 0, -18)
  title:SetText("ASHEN TALENTS")

  local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
  close:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -5, -5)

  self.talentSummary = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  self.talentSummary:SetPoint("TOP", title, "BOTTOM", 0, -8)

  local reset = button(frame, "Reset Talents", 120, 22)
  reset:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -45, -48)
  reset:SetScript("OnClick", function() AB:ResetTalents() end)

  self.talentTreePanels = {}
  self.talentTreeTitles = {}
  self.talentButtons = {}

  local tree = 1
  local col = 1
  local row = 1
  local x = 0
  local y = 0
  local talentButton = nil
  local panel = nil

  for tree = 1, 3 do
    panel = createTreePanel(frame, tree)
    self.talentTreePanels[tree] = panel
    self.talentTreeTitles[tree] = panel.title
    self.talentButtons[tree] = {}

    for row = 1, 7 do
      for col = 1, 4 do
        x = 24 + ((col - 1) * 70)
        y = -56 - ((row - 1) * 74)

        talentButton = CreateFrame("Button", nil, panel)
        talentButton:SetWidth(50)
        talentButton:SetHeight(50)
        talentButton:SetPoint("TOPLEFT", panel, "TOPLEFT", x, y)
        talentButton:SetFrameLevel(panel:GetFrameLevel() + 4)

        talentButton.icon = talentButton:CreateTexture(nil, "ARTWORK")
        talentButton.icon:SetAllPoints(talentButton)
        talentButton.icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")

        talentButton.border = talentButton:CreateTexture(nil, "OVERLAY")
        talentButton.border:SetTexture("Interface\\Buttons\\UI-Quickslot2")
        talentButton.border:SetWidth(64)
        talentButton.border:SetHeight(64)
        talentButton.border:SetPoint("CENTER", talentButton, "CENTER", 0, 0)

        talentButton.rank = talentButton:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
        talentButton.rank:SetPoint("BOTTOMRIGHT", talentButton, "BOTTOMRIGHT", 2, -2)

        talentButton:RegisterForClicks("LeftButtonUp", "RightButtonUp")
        talentButton:SetScript("OnClick", function()
          if arg1 == "RightButton" then
            AB:RemoveTalentPoint(this.treeIndex, this.talentIndex)
          else
            AB:AddTalentPoint(this.treeIndex, this.talentIndex)
          end
        end)
        talentButton:SetScript("OnEnter", function() AB:ShowTalentTooltip(this) end)
        talentButton:SetScript("OnLeave", function() GameTooltip:Hide() end)

        table.insert(self.talentButtons[tree], talentButton)
      end
    end
  end
end

function AB:ShowTalentTooltip(btn)
  local data = self:GetTalentData(self.current.class)
  local talent = data and data[btn.treeIndex] and data[btn.treeIndex][btn.talentIndex]
  if not talent then return end

  local rank = self:GetTalentRank(self.current, btn.treeIndex, btn.talentIndex)
  local max = table.getn(talent.ranks or {})
  GameTooltip:SetOwner(btn, "ANCHOR_RIGHT")
  GameTooltip:ClearLines()
  GameTooltip:AddLine(talent.name, 1, 0.82, 0)
  GameTooltip:AddLine("Rank " .. rank .. " / " .. max, 1, 1, 1)
  GameTooltip:AddLine(talent.desc or "No description available.", 1, 1, 1, true)

  local mods = self:GetTalentModifiers(self.current)
  local i = 1
  local source = nil
  for i = 1, table.getn(mods.sources or {}) do
    source = mods.sources[i]
    if source.name == talent.name then
      GameTooltip:AddLine(" ")
      GameTooltip:AddLine("Calculated Effects", 0.3, 0.8, 1)
      GameTooltip:AddLine(source.effects, 0.2, 1, 0.2, true)
      break
    end
  end

  local ok = nil
  local message = nil
  ok, message = self:CanAddTalent(self.current, btn.treeIndex, btn.talentIndex)
  if not ok and rank < max then
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine(message, 1, 0.2, 0.2, true)
  end
  GameTooltip:Show()
end

function AB:RefreshTalentUI()
  if not self.talentFrame then return end

  local data = nil
  local token = nil
  data, token = self:GetTalentData(self.current.class)
  local names = self.TREE_NAMES[token] or {"Tree 1", "Tree 2", "Tree 3"}

  self.talentSummary:SetText(self.current.class .. "  •  " .. self:GetTalentPointsSpent(self.current) .. " / " .. self:GetTalentBudget(self.current) .. " points")

  local tree = 1
  local i = 1
  local talentButton = nil
  local talent = nil
  local slot = 1
  local rank = 0
  local max = 0
  local points = 0

  for tree = 1, 3 do
    points = self:GetTalentPointsInTree(self.current, tree)
    self.talentTreeTitles[tree]:SetText(names[tree] or ("Tree " .. tree))
    if self.talentTreePanels and self.talentTreePanels[tree] then
      self.talentTreePanels[tree].points:SetText("(" .. points .. ")")
    end

    for i = 1, table.getn(self.talentButtons[tree]) do
      self.talentButtons[tree][i]:Hide()
    end

    for i = 1, table.getn(data and data[tree] or {}) do
      talent = data[tree][i]
      slot = ((tonumber(talent.row) or 1) - 1) * 4 + (tonumber(talent.column) or 1)
      talentButton = self.talentButtons[tree][slot]
      if talentButton then
        talentButton.treeIndex = tree
        talentButton.talentIndex = i
        talentButton.icon:SetTexture(talent.icon or "Interface\\Icons\\INV_Misc_QuestionMark")
        rank = self:GetTalentRank(self.current, tree, i)
        max = table.getn(talent.ranks or {})
        talentButton.rank:SetText(rank .. "/" .. max)
        if rank > 0 then
          talentButton.icon:SetVertexColor(1, 1, 1)
        else
          talentButton.icon:SetVertexColor(0.35, 0.35, 0.35)
        end
        talentButton:Show()
      end
    end
  end
end

local oldCreate = AB.CreateUI
function AB:CreateUI()
  oldCreate(self)
  self:CreateTalentUI()
end

local oldRefresh = AB.RefreshUI
function AB:RefreshUI()
  oldRefresh(self)
  if self.talentFrame and self.talentFrame:IsShown() then
    self:RefreshTalentUI()
  end
end
