-- Planner tabs: Talents, Community, Saved Builds and Item Database dock inside the main window.
local AB = AshenBuilds
SlashCmdList["ASHENBUILDS"]("")
local oldSet = AB.SetTabActive
AB.SetTabActive = function(self, b, on) b._tabActive = on; return oldSet(self, b, on) end
AB:RefreshTabStates()
local function planner() return AB.statsPanel:IsShown() and AB.slotButtons.HEAD:IsShown() and AB.simPanel:IsShown() end
local function active(b) return b._tabActive end

check("starts on the planner", planner() and active(AB.plannerTabButton))
check("views are docked in the planner", AB.talentFrame:GetParent() == AB.frame and AB.itemBrowser:GetParent() == AB.frame
  and AB.buildBrowser:GetParent() == AB.frame and AB.communityFrame:GetParent() == AB.frame)
check("docked views have no close button", not AB.talentFrame.closeButton:IsShown() and not AB.itemBrowser.closeButton:IsShown())

Click(AB.talentOpenButton)
check("Talents tab hides the planner", AB.talentFrame:IsShown() and not planner() and active(AB.talentOpenButton))
check("talent tree scaled to the planner width", AB.talentFrame:GetScale() < 1)
Click(AB.communityButton)
check("Community replaces Talents", AB.communityFrame:IsShown() and not AB.talentFrame:IsShown())
Click(AB.savedBuildsButton)
check("Saved Builds replaces Community", AB.buildBrowser:IsShown() and not AB.communityFrame:IsShown())
Click(AB.itemDatabaseButton)
check("Item Database replaces Saved Builds", AB.itemBrowser:IsShown() and not AB.buildBrowser:IsShown())
check("full height while a view is open", AB.frame:GetHeight() == 900)
local pts = {}
for _, q in ipairs(AB.itemBrowser._points or {}) do table.insert(pts, q[1]) end
check("Item Database fills the tab area", table.concat(pts, ",") == "TOPLEFT,BOTTOMRIGHT")
Click(AB.itemDatabaseButton)
check("clicking the open tab returns to the planner", planner() and active(AB.plannerTabButton))
Click(AB.talentOpenButton); Click(AB.plannerTabButton)
check("Planner tab returns to the planner", planner() and not AB.talentFrame:IsShown())

Click(AB.slotButtons.HEAD)
check("a gear slot opens the Item Database for it", AB.itemBrowser:IsShown() and AB.browserSlot == "HEAD")
local row = AB.itemRows[1]
if row and row.itemID then Click(row) end
check("picking an item returns to the planner", planner() and AB.current.items.HEAD ~= nil)

local found = false
for _, n in ipairs(UISpecialFrames) do if n == "AshenBuildsItemBrowser" or n == "AshenBuildsTalentFrame" then found = true end end
check("Escape closes the planner, not a single view", not found)
Click(AB.communityButton); AB.frame:Hide()
check("closing the planner closes the view", not AB.communityFrame:IsShown())
AB.frame:Show()
check("reopening starts on the planner", planner() and active(AB.plannerTabButton))

local function walk(f, lvl, bad)
  for _, k in ipairs({f:GetChildren()}) do
    if k:GetFrameLevel() <= lvl then table.insert(bad, k) end
    walk(k, k:GetFrameLevel(), bad)
  end
end
for _, w in ipairs({AB.talentFrame, AB.communityFrame, AB.buildBrowser, AB.itemBrowser}) do
  local bad = {}; walk(w, w:GetFrameLevel(), bad)
  check(w:GetName() .. " contents draw above its background", table.getn(bad) == 0)
end

local dressed = 0
local oldSV = AB.SetStatsView
AB.SetStatsView = function(self, v) if v == "preview" then dressed = dressed + 1 end; return oldSV(self, v) end
AB:SetStatsView("preview"); dressed = 0
Click(AB.talentOpenButton); Click(AB.plannerTabButton)
check("3D preview is dressed again on return", dressed == 1)
