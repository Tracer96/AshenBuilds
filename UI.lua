local AB=AshenBuilds
local qualityColors={[0]={0.62,0.62,0.62},[1]={1,1,1},[2]={0.12,1,0},[3]={0,0.44,0.87},[4]={0.64,0.21,0.93},[5]={1,0.5,0}}
local function MakeButton(parent,text,width,height) local b=CreateFrame("Button",nil,parent,"UIPanelButtonTemplate"); b:SetWidth(width or 90); b:SetHeight(height or 22); b:SetText(text); AB:SkinButton(b,"ember"); return b end
local function MakeBackdrop(frame) frame:SetBackdrop({bgFile="Interface\\DialogFrame\\UI-DialogBox-Background",edgeFile="Interface\\DialogFrame\\UI-DialogBox-Border",tile=true,tileSize=32,edgeSize=24,insets={left=8,right=8,top=8,bottom=8}}) end
-- WoW's screen is only 768 units tall at UI scale 1.0, so the larger windows
-- shrink to fit on open and stay clamped on-screen while dragged.
function AB:FitToScreen(frame)
  local s=math.min(1,(UIParent:GetWidth()*0.96)/frame:GetWidth(),(UIParent:GetHeight()*0.94)/frame:GetHeight())
  frame:SetScale(s)
end

-- Clears keyboard focus from every EditBox inside a window. Not cached: windows
-- are hidden (firing OnHide) before their children are built.
local function ClearWindowFocus(frame)
  local kids={frame:GetChildren()}; local i
  for i=1,table.getn(kids) do if kids[i]:GetObjectType()=="EditBox" then kids[i]:ClearFocus() end; ClearWindowFocus(kids[i]) end
end

-- Brings a window in front of the other AshenBuilds windows and takes keyboard
-- focus away from text boxes in the windows behind it, so typing never lands
-- in a window you are no longer looking at.
function AB:FocusWindow(frame)
  if frame.Raise then frame:Raise() end
  local i,w
  for i=1,table.getn(self.windows) do w=self.windows[i]; if w~=frame then ClearWindowFocus(w) end end
end

-- Shared window behaviour:
--  * all windows share one strata so raising can put any of them in front
--    (toplevel also raises a window when anything inside it is clicked);
--  * draggable by any empty area and clamped on-screen;
--  * swallows the mouse wheel so scrolling never zooms the camera (scroll
--    frames inside still get the wheel first because they enable it themselves);
--  * registered with UISpecialFrames so Escape closes it.
-- opts.fit shrinks the window to fit the screen on open; opts.wheel handles scrolling.
function AB:SetupWindow(frame,opts)
  opts=opts or {}; self.windows=self.windows or {}; table.insert(self.windows,frame)
  frame:SetFrameStrata("DIALOG"); if frame.SetToplevel then frame:SetToplevel(true) end
  frame:EnableMouse(true); frame:SetMovable(true); frame:RegisterForDrag("LeftButton")
  if frame.SetClampedToScreen then frame:SetClampedToScreen(true) end
  frame:SetScript("OnMouseDown",function() AB:FocusWindow(this) end)
  frame:SetScript("OnDragStart",function() AB:FocusWindow(this); this:StartMoving() end)
  frame:SetScript("OnDragStop",function() this:StopMovingOrSizing() end)
  frame:SetScript("OnShow",function() if opts.fit then AB:FitToScreen(this) end; AB:FocusWindow(this) end)
  frame:SetScript("OnHide",function() ClearWindowFocus(this); if AB.CloseDropdown then AB.CloseDropdown() end end)
  frame:EnableMouseWheel(true); frame:SetScript("OnMouseWheel",opts.wheel or function() end)
  tinsert(UISpecialFrames,frame:GetName())
end
local function Cycle(list,current,delta) local i=AB.IndexOf(list,current)+delta; if i<1 then i=table.getn(list) elseif i>table.getn(list) then i=1 end; return list[i] end
local function F(n) if not n then return "0" end if math.floor(n)==n then return tostring(n) end return string.format("%.2f",n) end
local function Section(parent,title,y)
  local t=parent:CreateFontString(nil,"OVERLAY","GameFontNormalSmall"); t:SetPoint("TOPLEFT",parent,"TOPLEFT",12,y); t:SetText(title); t:SetTextColor(1,.82,0)
  local line=parent:CreateTexture(nil,"ARTWORK"); local d=AB.THEME.divider; line:SetTexture(d[1],d[2],d[3],d[4]); line:SetPoint("TOPLEFT",parent,"TOPLEFT",10,y-13); line:SetWidth(190); line:SetHeight(1)
end
local function StatLine(parent,left,right,y,color)
  local a=parent:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); a:SetPoint("TOPLEFT",parent,"TOPLEFT",14,y); a:SetText(left); a:SetTextColor(.72,.78,.88)
  local b=parent:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); b:SetPoint("TOPRIGHT",parent,"TOPRIGHT",-14,y); b:SetText(right or ""); if color then b:SetTextColor(color[1],color[2],color[3]) end
  return a,b
end

function AB:CreateGearSlot(parent,slot,x,y,side)
  local b=CreateFrame("Button",nil,parent); b:SetWidth(155); b:SetHeight(54); b:SetPoint("TOPLEFT",parent,"TOPLEFT",x,y); b.slot=slot
  AB:StylePanel(b,"slot")
  b.icon=b:CreateTexture(nil,"ARTWORK"); b.icon:SetWidth(42); b.icon:SetHeight(42); b.icon:SetPoint(side=="right" and "RIGHT" or "LEFT",b,side=="right" and "RIGHT" or "LEFT",side=="right" and -5 or 5,0)
  b.label=b:CreateFontString(nil,"OVERLAY","GameFontNormalSmall"); b.label:SetPoint("TOP",b,"TOP",side=="right" and -25 or 25,-6); b.label:SetText(self.SLOT_LABELS[slot]); b.label:SetTextColor(.72,.68,1)
  b.itemText=b:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); b.itemText:SetPoint("TOP",b.label,"BOTTOM",0,-3); b.itemText:SetWidth(102); b.itemText:SetJustifyH("CENTER")
  -- The enchant line is its own button so enchanting is one click away.
  local eb=CreateFrame("Button",nil,b); eb:SetWidth(108); eb:SetHeight(13); eb:SetPoint("TOP",b.itemText,"BOTTOM",0,-1); eb.slot=slot; b.enchantButton=eb
  eb:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
  b.enchantText=eb:CreateFontString(nil,"OVERLAY","GameFontDisableSmall"); b.enchantText:SetAllPoints(eb); b.enchantText:SetJustifyH("CENTER")
  eb:SetScript("OnClick",function() AB:OpenEnchantBrowser(this.slot) end)
  eb:SetScript("OnEnter",function() GameTooltip:SetOwner(this,"ANCHOR_RIGHT"); GameTooltip:SetText("Click to choose an enchant",1,.82,0); GameTooltip:Show() end)
  eb:SetScript("OnLeave",function() GameTooltip:Hide() end)
  if not AshenBuildsEnchantSlots[slot] then eb:Hide() end
  b:RegisterForClicks("LeftButtonUp","RightButtonUp"); b:SetScript("OnClick",function() if arg1=="RightButton" then AB:RemoveItem(this.slot) elseif IsShiftKeyDown() then AB:OpenEnchantBrowser(this.slot) else AB:OpenItemBrowser(this.slot) end end)
  b:SetScript("OnEnter",function() AB:ShowSlotTooltip(this) end); b:SetScript("OnLeave",function() GameTooltip:Hide() end)
  self.slotButtons[slot]=b
end

function AB:CreateUI()
  if self.frame then return end
  local f=CreateFrame("Frame","AshenBuildsFrame",UIParent); f:SetWidth(980); f:SetHeight(900); f:SetPoint("CENTER",UIParent,"CENTER",0,0); MakeBackdrop(f); self:SetupWindow(f,{fit=true}); f:Hide(); self.frame=f
  -- Focus keeps the Ashen sigil centred behind the title, cropping rather than stretching the art.
  self:ApplyEmberBackground(f,10,0.33,0.45,0.30); self:AddEmberHeader(f,116); self:AddEmberFloor(f,44)
  local title=f:CreateFontString(nil,"OVERLAY","GameFontNormalLarge"); title:SetPoint("TOP",f,"TOP",0,-16); title:SetText("ASHEN BUILDS  |cff8d96a8v"..self.VERSION.."|r"); title:SetTextColor(1,.45,.16)
  local close=CreateFrame("Button",nil,f,"UIPanelCloseButton"); close:SetPoint("TOPRIGHT",f,"TOPRIGHT",-4,-4)

  local nameBox=CreateFrame("EditBox","AshenBuildsNameBox",f,"InputBoxTemplate"); nameBox:SetWidth(220); nameBox:SetHeight(24); nameBox:SetPoint("TOPLEFT",f,"TOPLEFT",24,-48); nameBox:SetAutoFocus(false); self.nameBox=nameBox
  local save=MakeButton(f,"Save",58,22); save:SetPoint("LEFT",nameBox,"RIGHT",6,0); save:SetScript("OnClick",function() AB:SaveBuild(AB.nameBox:GetText()) end)
  local saveAs=MakeButton(f,"Save As",70,22); saveAs:SetPoint("LEFT",save,"RIGHT",4,0); saveAs:SetScript("OnClick",function() AB:ShowPrompt({title="SAVE AS NEW BUILD",text="Name for the copy:",edit=true,default=AB.nameBox:GetText(),accept="Save",onAccept=function(text) AB:SaveBuild(text,true) end}) end)
  nameBox:SetScript("OnEnterPressed",function() this:ClearFocus(); AB:SaveBuild(this:GetText()) end); nameBox:SetScript("OnEscapePressed",function() this:ClearFocus() end)
  local new=MakeButton(f,"New",58,22); new:SetPoint("LEFT",saveAs,"RIGHT",4,0); new:SetScript("OnClick",function() AB.current=AB.NewBuildData("New Build"); AshenBuildsDB.current=AB.current; AB.selectedBuild=nil; AB:RefreshUI() end)
  local clear=MakeButton(f,"Clear Gear",82,22); clear:SetPoint("LEFT",new,"RIGHT",4,0); clear:SetScript("OnClick",function() AB.current.items={}; AB.current.enchants={}; AB:RefreshUI() end)
  local export=MakeButton(f,"Export",62,22); export:SetPoint("LEFT",clear,"RIGHT",4,0); export:SetScript("OnClick",function() AB:ShowCodeDialog("Export Build",AB:ExportBuild(),false) end)
  local import=MakeButton(f,"Import",62,22); import:SetPoint("LEFT",export,"RIGHT",4,0); import:SetScript("OnClick",function() AB:ShowCodeDialog("Import Build","",true) end)

  local function Profile(label,x,w,listFn,getFn,setFn)
    local fs=f:CreateFontString(nil,"OVERLAY","GameFontNormalSmall"); fs:SetPoint("TOPLEFT",f,"TOPLEFT",x,-82); fs:SetText(label)
    local b=MakeButton(f,"",w,22); AB:SkinButton(b,"cycle"); b:SetPoint("TOPLEFT",f,"TOPLEFT",x,-98); b:RegisterForClicks("LeftButtonUp","RightButtonUp"); b:SetScript("OnClick",function() setFn(Cycle(listFn(),getFn(),arg1=="RightButton" and -1 or 1)) end); return b
  end
  self.classButton=Profile("CLASS",24,105,function() return AB.CLASSES end,function() return AB.current.class end,function(v) AB:SetClass(v) end)
  self.raceButton=Profile("RACE",136,105,function() return AB.RACES end,function() return AB.current.race end,function(v) AB:SetRace(v) end)
  self.specButton=Profile("BUILD",248,125,function() return AB.SPECS[AB.current.class] end,function() return AB.current.spec end,function(v) AB:SetSpec(v) end)
  local lf=f:CreateFontString(nil,"OVERLAY","GameFontNormalSmall"); lf:SetPoint("TOPLEFT",f,"TOPLEFT",380,-82); lf:SetText("LEVEL")
  local level=CreateFrame("EditBox",nil,f,"InputBoxTemplate"); level:SetWidth(42); level:SetHeight(22); level:SetPoint("TOPLEFT",f,"TOPLEFT",380,-98); level:SetNumeric(true); level:SetMaxLetters(2); level:SetAutoFocus(false); level:SetScript("OnEnterPressed",function() AB:SetLevel(this:GetText()); this:ClearFocus() end); level:SetScript("OnEditFocusLost",function() AB:SetLevel(this:GetText()) end); self.levelBox=level
  local browse=MakeButton(f,"ITEM DATABASE",130,25); browse:SetPoint("TOPRIGHT",f,"TOPRIGHT",-28,-86); browse:SetScript("OnClick",function() AB:OpenItemBrowser("ALL") end)
  local saved=MakeButton(f,"SAVED BUILDS",118,25); saved:SetPoint("RIGHT",browse,"LEFT",-8,0); saved:SetScript("OnClick",function() AB:OpenBuildBrowser() end)
  local community=MakeButton(f,"COMMUNITY",104,25); community:SetPoint("RIGHT",saved,"LEFT",-8,0); community:SetScript("OnClick",function() AB:OpenCommunity() end); self.communityButton=community

  self.slotButtons={}
  local leftSlots={"HEAD","NECK","SHOULDER","BACK","CHEST","SHIRT","TABARD","WRIST"}; local rightSlots={"HANDS","WAIST","LEGS","FEET","FINGER1","FINGER2","TRINKET1","TRINKET2"}; local i
  for i=1,table.getn(leftSlots) do self:CreateGearSlot(f,leftSlots[i],50,-140-(i-1)*58,"left") end
  for i=1,table.getn(rightSlots) do self:CreateGearSlot(f,rightSlots[i],775,-140-(i-1)*58,"right") end

  local stats=CreateFrame("Frame",nil,f); stats:SetWidth(520); stats:SetHeight(490); stats:SetPoint("TOP",f,"TOP",0,-132); self:StylePanel(stats,"sheer"); self.statsPanel=stats
  local st=stats:CreateFontString(nil,"OVERLAY","GameFontNormal"); st:SetPoint("TOP",stats,"TOP",0,-10); st:SetText("CHARACTER TOTALS")
  self.statsColumns={}
  local cardPositions={{10,-34,245,125},{265,-34,245,125},{10,-165,245,170},{265,-165,245,170},{10,-341,245,137},{265,-341,245,137}}
  for i=1,6 do
    local pos=cardPositions[i]; local c=CreateFrame("Frame",nil,stats); c:SetWidth(pos[3]); c:SetHeight(pos[4]); c:SetPoint("TOPLEFT",stats,"TOPLEFT",pos[1],pos[2]);
    self:StylePanel(c,"card"); self.statsColumns[i]=c
  end

  self:CreateGearSlot(f,"MAINHAND",0,0,"left"); self.slotButtons.MAINHAND:ClearAllPoints(); self.slotButtons.MAINHAND:SetPoint("TOPLEFT",stats,"BOTTOMLEFT",17,-10)
  self:CreateGearSlot(f,"OFFHAND",0,0,"left"); self.slotButtons.OFFHAND:ClearAllPoints(); self.slotButtons.OFFHAND:SetPoint("LEFT",self.slotButtons.MAINHAND,"RIGHT",10,0)
  self:CreateGearSlot(f,"RANGED",0,0,"left"); self.slotButtons.RANGED:ClearAllPoints(); self.slotButtons.RANGED:SetPoint("LEFT",self.slotButtons.OFFHAND,"RIGHT",10,0)

  local setPanel=CreateFrame("Frame",nil,f); setPanel:SetWidth(880); setPanel:SetHeight(148); setPanel:SetPoint("TOP",self.slotButtons.OFFHAND,"BOTTOM",0,-10); self:StylePanel(setPanel,"panel"); self.setPanel=setPanel
  local sh=setPanel:CreateFontString(nil,"OVERLAY","GameFontNormalSmall"); sh:SetPoint("TOPLEFT",setPanel,"TOPLEFT",12,-9); sh:SetText("SET BONUSES")
  local scroll=CreateFrame("ScrollFrame","AshenBuildsSetScrollFrame",setPanel,"UIPanelScrollFrameTemplate"); scroll:SetPoint("TOPLEFT",setPanel,"TOPLEFT",10,-26); scroll:SetPoint("BOTTOMRIGHT",setPanel,"BOTTOMRIGHT",-29,9); self.setScroll=scroll
  local child=CreateFrame("Frame",nil,scroll); child:SetWidth(826); child:SetHeight(105); scroll:SetScrollChild(child); self.setScrollChild=child
  self.setColumnTexts={}
  for i=1,2 do local txt=child:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); txt:SetPoint("TOPLEFT",child,"TOPLEFT",(i-1)*413,0); txt:SetWidth(397); txt:SetJustifyH("LEFT"); txt:SetJustifyV("TOP"); self.setColumnTexts[i]=txt end
  scroll:EnableMouseWheel(true); scroll:SetScript("OnMouseWheel",function() local cur=this:GetVerticalScroll() or 0; local max=this:GetVerticalScrollRange() or 0; cur=cur-(arg1*28); if cur<0 then cur=0 elseif cur>max then cur=max end; this:SetVerticalScroll(cur) end)

  self:CreateBuildBrowser(); self:CreateItemBrowser(); self:CreateSourcePanel(); self:CreateEnchantBrowser(); self:CreateCodeDialog(); self:RefreshUI()
end

function AB:ShowSlotTooltip(button)
  local id=self.current.items[button.slot] or 0; if id>0 then self:ShowItemTooltip(button,id); local e=AshenBuildsEnchants[self.current.enchants[button.slot] or 0]; if e then GameTooltip:AddLine(" "); GameTooltip:AddLine("Enchanted: "..e.n,0.1,1,0.1); local sum=self:StatSummary(e.stats); if sum~="" then GameTooltip:AddLine(sum,0.1,1,0.1,true) end; GameTooltip:Show() end else GameTooltip:SetOwner(button,"ANCHOR_RIGHT"); GameTooltip:SetText(self.SLOT_LABELS[button.slot].." - Empty",.6,.65,.75); GameTooltip:Show() end
end

function AB:RefreshUI()
  if not self.frame then return end
  self.nameBox:SetText(self.current.name or "New Build"); self.classButton:SetText(self.current.class); self.raceButton:SetText(self.current.race); self.specButton:SetText(self.current.spec); self.levelBox:SetText(self:GetBuildLevel())
  local slot,b,id,item,c,enchant
  for slot,b in pairs(self.slotButtons) do id=self.current.items[slot]; item=id and self:GetItem(id); enchant=AshenBuildsEnchants[(self.current.enchants and self.current.enchants[slot]) or 0]; if item then b.icon:SetTexture(item.icon or "Interface\\Icons\\INV_Misc_QuestionMark"); b.itemText:SetText(item.n); c=qualityColors[item.q] or qualityColors[1]; b.itemText:SetTextColor(c[1],c[2],c[3]) else b.icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark"); b.itemText:SetText("Empty"); b.itemText:SetTextColor(AB.THEME.empty[1],AB.THEME.empty[2],AB.THEME.empty[3]) end; b.enchantText:SetText(enchant and enchant.n or (item and "+ Add enchant" or "No enchant")); if enchant then b.enchantText:SetTextColor(.2,1,.2) else b.enchantText:SetTextColor(AB.THEME.muted[1],AB.THEME.muted[2],AB.THEME.muted[3]) end end
  self:RefreshStats(); self:RefreshSetBonuses()
end

-- Stat lines are pooled per column: refreshing reuses the same font strings
-- instead of creating new ones every time the build changes.
function AB:ClearStatColumns()
  local i,c,j
  for i=1,6 do c=self.statsColumns[i]; c.used=0; if c.lines then for j=1,table.getn(c.lines) do c.lines[j][1]:Hide(); c.lines[j][2]:Hide() end else c.lines={} end end
end
function AB:PutStat(col,label,value,y,color)
  local c=self.statsColumns[col]; c.used=c.used+1
  local line=c.lines[c.used]
  if not line then local a,b=StatLine(c,"","",y); line={a,b}; c.lines[c.used]=line end
  line[1]:ClearAllPoints(); line[1]:SetPoint("TOPLEFT",c,"TOPLEFT",14,y); line[1]:SetText(label); line[1]:Show()
  line[2]:ClearAllPoints(); line[2]:SetPoint("TOPRIGHT",c,"TOPRIGHT",-14,y); line[2]:SetText(value or "")
  if color then line[2]:SetTextColor(color[1],color[2],color[3]) else line[2]:SetTextColor(1,1,1) end
  line[2]:Show()
end

local STAT_HEADINGS={"BASE STATS","RESOURCES","MELEE & RANGED","SPELLS & HEALING","DEFENSE","RESISTANCES"}
function AB:RefreshStats()
  local i
  if not self.statHeadings then self.statHeadings=true; for i=1,6 do Section(self.statsColumns[i],STAT_HEADINGS[i],-8) end end
  self:ClearStatColumns(); local ok,d=pcall(function() return AB:GetDerivedStats(self.current) end); if not ok or not d then self:PutStat(1,"Calculation error",tostring(d),-34,{1,.2,.2}); return end
  local y
  y=-34; self:PutStat(1,"Strength",F(d.str),y); y=y-16; self:PutStat(1,"Agility",F(d.agi),y); y=y-16; self:PutStat(1,"Stamina",F(d.sta),y); y=y-16; self:PutStat(1,"Intellect",F(d.int),y); y=y-16; self:PutStat(1,"Spirit",F(d.spi),y)
  y=-34; self:PutStat(2,"Health",F(d.health),y); y=y-17; if d.mana and d.mana>0 then self:PutStat(2,"Mana",F(d.mana),y); y=y-17 end; self:PutStat(2,"Armor",F(d.armor),y); y=y-17; if d.haste and d.haste>0 then self:PutStat(2,"Haste",F(d.haste).."%",y) end
  y=-34; self:PutStat(3,"Attack Power",F(d.attackPower),y); y=y-16; self:PutStat(3,"Ranged AP",F(d.rangedAttackPower),y); y=y-16; self:PutStat(3,"Melee Crit",F(d.meleeCrit).."%",y); y=y-16; self:PutStat(3,"Ranged Crit",F(d.rangedCrit).."%",y); y=y-16; self:PutStat(3,"Melee Hit",F(d.hit).."%",y); y=y-16; self:PutStat(3,"Ranged Hit",F(d.rangedHit).."%",y); y=y-16; if d.mainSkill then self:PutStat(3,"MH "..d.mainSkill.type,F(d.mainSkill.total),y); y=y-16 end; if d.rangedSkill then self:PutStat(3,"Ranged "..d.rangedSkill.type,F(d.rangedSkill.total),y) end
  y=-34; self:PutStat(4,"Spell Power",F(d.spellPower),y); y=y-17; self:PutStat(4,"Healing",F(d.healing),y); y=y-17; self:PutStat(4,"Spell Crit",F(d.spellCrit).."%",y); y=y-17; self:PutStat(4,"Spell Hit",F(d.spellHit).."%",y); y=y-17; self:PutStat(4,"MP5 (items)",F(d.mp5),y); y=y-17; if d.spiritRegen and d.spiritRegen>0 then self:PutStat(4,"MP5 (spirit, not casting)",F(d.spiritRegen),y) end
  y=-34; self:PutStat(5,"Defense",F(d.defense),y); y=y-17; self:PutStat(5,"Dodge",F(d.dodge).."%",y); y=y-17; self:PutStat(5,"Parry",F(d.parry).."%",y); y=y-17; self:PutStat(5,"Block",F(d.block).."%",y); y=y-17; self:PutStat(5,"Block Value",F(d.blockValue),y)
  y=-34; self:PutStat(6,"Fire",F(d.resistances.fire),y); y=y-17; self:PutStat(6,"Frost",F(d.resistances.frost),y); y=y-17; self:PutStat(6,"Nature",F(d.resistances.nature),y); y=y-17; self:PutStat(6,"Shadow",F(d.resistances.shadow),y); y=y-17; self:PutStat(6,"Arcane",F(d.resistances.arcane),y)
end

function AB:RefreshSetBonuses()
  local counts={}; local slot,id,item,setId
  for slot,id in pairs(self.current.items or {}) do item=self:GetItem(id); setId=self:GetItemSetId(id,item); if setId then counts[setId]=(counts[setId] or 0)+1 end end
  local ids={}; for setId in pairs(counts) do table.insert(ids,setId) end; table.sort(ids)
  local cols={{},{}}
  local lineCounts={0,0}
  local index,count,set,i,b,total,col,block
  for index=1,table.getn(ids) do
    setId=ids[index]; count=counts[setId]; set=self:GetItemSet(setId); col=math.mod(index-1,2)+1; block={}
    if set then
      total=table.getn(set.items or {}); table.insert(block,"|cffffd100"..(set.name or "Item Set").." ("..count.."/"..total..")|r")
      for i=1,table.getn(set.bonuses or {}) do b=set.bonuses[i]; if b and b[3] and b[3]~="" then table.insert(block,(count>=(b[1] or 0) and "|cff33ff66" or "|cff9ea5b2").."("..(b[1] or 0)..") Set: "..b[3].."|r") end end
    else
      local loaded=(self.SetCatalogMeta and self.SetCatalogMeta.setCount) or (AshenDB and AshenDB.GetSetCount and AshenDB:GetSetCount()) or 0; table.insert(block,"|cffff3333Set data missing for #"..setId.." ("..loaded.." definitions loaded)|r")
    end
    table.insert(cols[col],table.concat(block,"\n")); lineCounts[col]=lineCounts[col]+table.getn(block)+1
  end
  if table.getn(ids)==0 then cols[1]={"|cff9ea5b2No item set pieces equipped.|r"}; cols[2]={}; lineCounts[1]=1; lineCounts[2]=0 end
  self.setColumnTexts[1]:SetText(table.concat(cols[1],"\n\n")); self.setColumnTexts[2]:SetText(table.concat(cols[2],"\n\n"))
  local maxLines=math.max(lineCounts[1],lineCounts[2]); local h=math.max(105,maxLines*15+8); self.setScrollChild:SetHeight(h); self.setColumnTexts[1]:SetHeight(h); self.setColumnTexts[2]:SetHeight(h); self.setScroll:SetVerticalScroll(0); if self.setScroll.UpdateScrollChildRect then self.setScroll:UpdateScrollChildRect() end
end

---------------------------------------------------------------------------
-- Saved builds
---------------------------------------------------------------------------
local BUILD_ROWS=10
function AB:GetSavedBuildNames()
  local names={}; local name
  for name in pairs(AshenBuildsDB.builds or {}) do table.insert(names,name) end
  table.sort(names,function(a,b) return string.lower(a)<string.lower(b) end)
  return names
end

function AB:RefreshBuildList()
  if not self.buildRows then return end
  local names=self:GetSavedBuildNames(); local total=table.getn(names)
  local maxOffset=math.max(0,total-BUILD_ROWS)
  if (self.buildOffset or 0)>maxOffset then self.buildOffset=maxOffset end
  local i,row,name,pub
  for i=1,BUILD_ROWS do
    row=self.buildRows[i]; name=names[(self.buildOffset or 0)+i]
    if name then
      row.buildName=name; pub=self.IsBuildPublished and self:IsBuildPublished(name)
      local label=name
      if self.current.savedName==name then label="|cffffd100> |r"..label end
      if pub then label=label.."  |cffffd100public|r" end
      row.text:SetText(label); row.publish:SetText(pub and "Unpublish" or "Publish"); row:Show()
    else row.buildName=nil; row:Hide() end
  end
  if self.buildCountText then
    local shown=total>BUILD_ROWS and ("  -  showing "..((self.buildOffset or 0)+1).."-"..math.min(total,(self.buildOffset or 0)+BUILD_ROWS).." (scroll for more)") or ""
    self.buildCountText:SetText(total.." saved build"..(total==1 and "" or "s")..shown)
  end
end

function AB:PromptRenameBuild(name)
  self:ShowPrompt({title="RENAME BUILD",text="New name for |cffffffff"..name.."|r:",edit=true,default=name,accept="Rename",
    onAccept=function(text) AB:RenameBuild(name,text) end})
end

function AB:PromptDeleteBuild(name)
  self:ShowPrompt({title="DELETE BUILD",text="Delete |cffffffff"..name.."|r?\nThis can't be undone.",accept="Delete",
    onAccept=function() AB:DeleteBuild(name) end})
end

function AB:CreateBuildBrowser()
  local f=CreateFrame("Frame","AshenBuildsBuildBrowser",UIParent); f:SetWidth(560); f:SetHeight(500); f:SetPoint("CENTER",UIParent,"CENTER",260,0); MakeBackdrop(f)
  self:SetupWindow(f,{wheel=function() AB.buildOffset=math.max(0,(AB.buildOffset or 0)-arg1); AB:RefreshBuildList() end}); f:Hide(); self.buildBrowser=f
  self:ApplyEmberBackground(f,10,0.33,0.4,0.4); self:AddEmberHeader(f,34); self:AddEmberWell(f,22,-72,-22,58)
  local t=f:CreateFontString(nil,"OVERLAY","GameFontNormalLarge"); t:SetPoint("TOP",f,"TOP",0,-18); t:SetText("SAVED BUILDS")
  local close=CreateFrame("Button",nil,f,"UIPanelCloseButton"); close:SetPoint("TOPRIGHT",f,"TOPRIGHT",-4,-4)
  self.buildCountText=f:CreateFontString(nil,"OVERLAY","GameFontDisableSmall"); self.buildCountText:SetPoint("TOP",f,"TOP",0,-50); self.buildCountText:SetTextColor(AB.THEME.muted[1],AB.THEME.muted[2],AB.THEME.muted[3])
  self.buildRows={}; local i
  for i=1,BUILD_ROWS do
    local r=CreateFrame("Button",nil,f); r:SetWidth(506); r:SetHeight(32); r:SetPoint("TOPLEFT",f,"TOPLEFT",28,-78-(i-1)*36); r:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
    r.text=r:CreateFontString(nil,"OVERLAY","GameFontHighlight"); r.text:SetPoint("LEFT",r,"LEFT",8,0); r.text:SetWidth(240); r.text:SetJustifyH("LEFT")
    r.publish=MakeButton(r,"Publish",82,22); r.publish:SetPoint("RIGHT",r,"RIGHT",-2,0); r.publish:SetScript("OnClick",function() local n=this:GetParent().buildName; if not n then return end; if AB:IsBuildPublished(n) then AB:UnpublishBuild(n) else AB:PublishBuild(n) end end)
    r.delete=MakeButton(r,"Delete",66,22); r.delete:SetPoint("RIGHT",r.publish,"LEFT",-4,0); r.delete:SetScript("OnClick",function() local n=this:GetParent().buildName; if n then AB:PromptDeleteBuild(n) end end)
    r.rename=MakeButton(r,"Rename",70,22); r.rename:SetPoint("RIGHT",r.delete,"LEFT",-4,0); r.rename:SetScript("OnClick",function() local n=this:GetParent().buildName; if n then AB:PromptRenameBuild(n) end end)
    r:RegisterForClicks("LeftButtonUp","RightButtonUp")
    r:SetScript("OnClick",function() if not this.buildName then return end; if arg1=="RightButton" then AB:PromptDeleteBuild(this.buildName) else AB:LoadBuild(this.buildName); f:Hide() end end)
    self.buildRows[i]=r
  end
  local help=f:CreateFontString(nil,"OVERLAY","GameFontDisableSmall"); help:SetPoint("BOTTOM",f,"BOTTOM",0,24); help:SetText("Click a build to load it  -  Saving a loaded build under a new name renames it"); help:SetTextColor(AB.THEME.muted[1],AB.THEME.muted[2],AB.THEME.muted[3])
end
function AB:OpenBuildBrowser() self.buildOffset=0; self:RefreshBuildList(); self.buildBrowser:Show() end

---------------------------------------------------------------------------
-- Item database
---------------------------------------------------------------------------
local ITEM_ROWS=12
local SLOT_FILTERS={{"ALL","All Slots"},{"HEAD","Head"},{"NECK","Neck"},{"SHOULDER","Shoulder"},{"BACK","Back"},{"CHEST","Chest"},{"SHIRT","Shirt"},{"TABARD","Tabard"},{"WRIST","Wrist"},{"HANDS","Hands"},{"WAIST","Waist"},{"LEGS","Legs"},{"FEET","Feet"},{"FINGER1","Ring"},{"TRINKET1","Trinket"},{"MAINHAND","Main Hand"},{"OFFHAND","Off Hand"},{"RANGED","Ranged"}}
local FILTER_SLOT_OF={FINGER2="FINGER1",TRINKET2="TRINKET1"}
local QUALITY_FILTERS={-1,5,4,3,2,1,0}
local SORTS={{"ilvl","Item Level (high)"},{"ilvlUp","Item Level (low)"},{"name","Name (A-Z)"},{"req","Required Level (high)"}}
local FILTER_STATS={"str","agi","sta","int","spi","armor","ap","rap","crit","hit","haste","spellPower","healing","spellCrit","spellHit","mp5","defense","dodge","parry","block","firePower","frostPower","shadowPower","arcanePower","naturePower","holyPower","fireRes","frostRes","natureRes","shadowRes","arcaneRes"}
local MAX_STAT_FILTERS=4

local function LabelOf(list,value) local i for i=1,table.getn(list) do if list[i][1]==value then return list[i][2] end end return "" end

function AB:ItemFilterDefaults()
  self.itemFilter={slot="ALL",quality=-1,source=0,minIlvl=nil,maxIlvl=nil,stats={},usable=true,classOnly=true,showHidden=false,sort="ilvl"}
end

function AB:QueueItemRefresh(delay) self.itemRefreshAt=GetTime()+(delay or 0) end

function AB:CreateItemBrowser()
  self:ItemFilterDefaults()
  local f=CreateFrame("Frame","AshenBuildsItemBrowser",UIParent); f:SetWidth(880); f:SetHeight(700); f:SetPoint("CENTER",UIParent,"CENTER",0,0); MakeBackdrop(f); self:SetupWindow(f,{fit=true,wheel=function() AB:ScrollItemPage(arg1) end}); f:Hide(); self.itemBrowser=f
  self:ApplyEmberBackground(f,10,0.55,0.5,0.4); self:AddEmberHeader(f,34); self:AddEmberWell(f,22,-190,-22,48)
  local t=f:CreateFontString(nil,"OVERLAY","GameFontNormalLarge"); t:SetPoint("TOP",f,"TOP",0,-17); t:SetText("ITEM DATABASE"); self.itemBrowserTitle=t
  local close=CreateFrame("Button",nil,f,"UIPanelCloseButton"); close:SetPoint("TOPRIGHT",f,"TOPRIGHT",-4,-4)
  -- Search typing is debounced; everything else refreshes on the next frame.
  f:SetScript("OnUpdate",function() if AB.itemRefreshAt and GetTime()>=AB.itemRefreshAt then AB.itemRefreshAt=nil; AB.itemPage=1; AB:RefreshItemResults() end end)

  -- Row 1: search and toggles
  local search=CreateFrame("EditBox",nil,f,"InputBoxTemplate"); search:SetWidth(330); search:SetHeight(24); search:SetPoint("TOPLEFT",f,"TOPLEFT",32,-66); search:SetAutoFocus(false); self.itemSearch=search
  search:SetScript("OnTextChanged",function() AB:QueueItemRefresh(0.25) end); search:SetScript("OnEnterPressed",function() this:ClearFocus(); AB:QueueItemRefresh(0) end); search:SetScript("OnEscapePressed",function() this:ClearFocus() end)
  self:Caption(f,"Search (name, NPC or zone)",search,-6,4)
  local clear=MakeButton(f,"Clear Filters",96,22); clear:SetPoint("LEFT",search,"RIGHT",8,0); clear:SetScript("OnClick",function() local slot=AB.itemFilter.slot; AB:ItemFilterDefaults(); AB.itemFilter.slot=slot; AB.itemSearch:SetText(""); AB:SyncItemFilterControls(); AB:QueueItemRefresh(0) end)
  self.usableCheck=self:CreateCheck(f,"Usable at build level",function(v) AB.itemFilter.usable=v; AB:QueueItemRefresh(0) end); self.usableCheck:SetPoint("LEFT",clear,"RIGHT",10,0)
  self.classCheck=self:CreateCheck(f,"My class",function(v) AB.itemFilter.classOnly=v; AB:QueueItemRefresh(0) end); self.classCheck:SetPoint("LEFT",self.usableCheck,"RIGHT",128,0)
  self.hiddenCheck=self:CreateCheck(f,"Show hidden",function(v) AB.itemFilter.showHidden=v; AB:QueueItemRefresh(0) end); self.hiddenCheck:SetPoint("LEFT",self.classCheck,"RIGHT",62,0)

  -- Row 2: dropdowns and item level range
  local y=-118
  self.slotDrop=self:CreateDropdown(f,140,{
    items=function() local out={}; local i; for i=1,table.getn(SLOT_FILTERS) do table.insert(out,{value=SLOT_FILTERS[i][1],text=SLOT_FILTERS[i][2]}) end; return out end,
    getText=function() return LabelOf(SLOT_FILTERS,AB.itemFilter.slot) end,
    isChecked=function(v) return AB.itemFilter.slot==v end,
    onSelect=function(v) AB.itemFilter.slot=v; AB.browserSlot=v; AB:QueueItemRefresh(0) end})
  self.slotDrop:SetPoint("TOPLEFT",f,"TOPLEFT",26,y); self:Caption(f,"Equipment Slot",self.slotDrop)

  local function LevelBox(anchor,x)
    local e=CreateFrame("EditBox",nil,f,"InputBoxTemplate"); e:SetWidth(44); e:SetHeight(24); e:SetPoint("LEFT",anchor,"RIGHT",x,0); e:SetAutoFocus(false); e:SetNumeric(true); e:SetMaxLetters(3)
    e:SetScript("OnTextChanged",function() AB:QueueItemRefresh(0.35) end); e:SetScript("OnEnterPressed",function() this:ClearFocus() end); e:SetScript("OnEscapePressed",function() this:ClearFocus() end)
    return e
  end
  self.minIlvlBox=LevelBox(self.slotDrop,20); self:Caption(f,"Item Level",self.minIlvlBox,-6,4)
  local dash=f:CreateFontString(nil,"OVERLAY","GameFontHighlight"); dash:SetPoint("LEFT",self.minIlvlBox,"RIGHT",4,0); dash:SetText("-")
  self.maxIlvlBox=LevelBox(self.minIlvlBox,18)

  self.sourceDrop=self:CreateDropdown(f,140,{
    items=function() local out={}; local i,s; for i=1,table.getn(AB.SOURCE_FILTERS) do s=AB.SOURCE_FILTERS[i]; table.insert(out,{value=s.value,text=s.text}) end; return out end,
    getText=function() local i; for i=1,table.getn(AB.SOURCE_FILTERS) do if AB.SOURCE_FILTERS[i].value==AB.itemFilter.source then return AB.SOURCE_FILTERS[i].text end end; return "All Sources" end,
    isChecked=function(v) return AB.itemFilter.source==v end,
    onSelect=function(v) AB.itemFilter.source=v; AB:QueueItemRefresh(0) end})
  self.sourceDrop:SetPoint("LEFT",self.maxIlvlBox,"RIGHT",16,0); self:Caption(f,"Source",self.sourceDrop)

  self.qualityDrop=self:CreateDropdown(f,130,{
    items=function() local out={}; local i,q,c; for i=1,table.getn(QUALITY_FILTERS) do q=QUALITY_FILTERS[i]; c=q>=0 and qualityColors[q] or nil; table.insert(out,{value=q,text=q<0 and "All Qualities" or AB.QUALITY_LABELS[q],color=c}) end; return out end,
    getText=function() local q=AB.itemFilter.quality; return q<0 and "All Qualities" or AB.QUALITY_LABELS[q] end,
    isChecked=function(v) return AB.itemFilter.quality==v end,
    onSelect=function(v) AB.itemFilter.quality=v; AB:QueueItemRefresh(0) end})
  self.qualityDrop:SetPoint("LEFT",self.sourceDrop,"RIGHT",12,0); self:Caption(f,"Quality",self.qualityDrop)

  self.sortDrop=self:CreateDropdown(f,150,{
    items=function() local out={}; local i; for i=1,table.getn(SORTS) do table.insert(out,{value=SORTS[i][1],text=SORTS[i][2]}) end; return out end,
    getText=function() return LabelOf(SORTS,AB.itemFilter.sort) end,
    isChecked=function(v) return AB.itemFilter.sort==v end,
    onSelect=function(v) AB.itemFilter.sort=v; AB:QueueItemRefresh(0) end})
  self.sortDrop:SetPoint("LEFT",self.qualityDrop,"RIGHT",12,0); self:Caption(f,"Sort",self.sortDrop)

  -- Row 3: stat filters (multi-select) with a minimum per stat
  self.statDrop=self:CreateDropdown(f,140,{multi=true,listWidth=170,
    items=function() local out={}; local i; for i=1,table.getn(FILTER_STATS) do table.insert(out,{value=FILTER_STATS[i],text=AB.STAT_LABELS[FILTER_STATS[i]] or FILTER_STATS[i]}) end; return out end,
    getText=function() local n=table.getn(AB.itemFilter.stats); if n==0 then return "Select stats..." end; return n.." stat"..(n==1 and "" or "s").." selected" end,
    isChecked=function(v) local i; for i=1,table.getn(AB.itemFilter.stats) do if AB.itemFilter.stats[i][1]==v then return true end end; return false end,
    onSelect=function(v) AB:ToggleStatFilter(v) end})
  self.statDrop:SetPoint("TOPLEFT",f,"TOPLEFT",26,-160); self:Caption(f,"Stats",self.statDrop)
  self.statChips={}; local i
  for i=1,MAX_STAT_FILTERS do
    local c=CreateFrame("Frame",nil,f); c:SetWidth(158); c:SetHeight(24); self:StylePanel(c,"card"); c:SetBackdropColor(.12,.09,.07,.95)
    if i==1 then c:SetPoint("LEFT",self.statDrop,"RIGHT",12,0) else c:SetPoint("LEFT",self.statChips[i-1],"RIGHT",8,0) end
    c.label=c:CreateFontString(nil,"OVERLAY","GameFontNormalSmall"); c.label:SetPoint("LEFT",c,"LEFT",8,0); c.label:SetWidth(70); c.label:SetJustifyH("LEFT")
    local ge=c:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); ge:SetPoint("LEFT",c,"LEFT",80,0); ge:SetText(">=")
    c.edit=CreateFrame("EditBox",nil,c,"InputBoxTemplate"); c.edit:SetWidth(34); c.edit:SetHeight(18); c.edit:SetPoint("LEFT",ge,"RIGHT",8,0); c.edit:SetAutoFocus(false); c.edit:SetNumeric(true); c.edit:SetMaxLetters(3); c.index=i
    c.edit:SetScript("OnTextChanged",function() local s=AB.itemFilter.stats[this:GetParent().index]; if s then s[2]=tonumber(this:GetText()) or 0; AB:QueueItemRefresh(0.35) end end)
    c.edit:SetScript("OnEnterPressed",function() this:ClearFocus() end); c.edit:SetScript("OnEscapePressed",function() this:ClearFocus() end)
    c.remove=CreateFrame("Button",nil,c); c.remove:SetWidth(16); c.remove:SetHeight(16); c.remove:SetPoint("RIGHT",c,"RIGHT",-4,0)
    local x=c.remove:CreateFontString(nil,"OVERLAY","GameFontNormal"); x:SetAllPoints(c.remove); x:SetText("x"); c.remove:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
    c.remove:SetScript("OnClick",function() local s=AB.itemFilter.stats[this:GetParent().index]; if s then AB:ToggleStatFilter(s[1]) end end)
    c:Hide(); self.statChips[i]=c
  end

  -- Results
  self.itemRows={}
  for i=1,ITEM_ROWS do
    local r=CreateFrame("Button",nil,f); r:SetWidth(820); r:SetHeight(36); r:SetPoint("TOPLEFT",f,"TOPLEFT",28,-196-(i-1)*38); r:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
    r.icon=r:CreateTexture(nil,"ARTWORK"); r.icon:SetWidth(30); r.icon:SetHeight(30); r.icon:SetPoint("LEFT",r,"LEFT",2,0)
    r.name=r:CreateFontString(nil,"OVERLAY","GameFontHighlight"); r.name:SetPoint("TOPLEFT",r.icon,"TOPRIGHT",8,-1); r.name:SetWidth(520); r.name:SetJustifyH("LEFT")
    r.meta=r:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); r.meta:SetPoint("TOPRIGHT",r,"TOPRIGHT",-6,-3); r.meta:SetWidth(250); r.meta:SetJustifyH("RIGHT"); r.meta:SetTextColor(.64,.67,.72)
    r.stats=r:CreateFontString(nil,"OVERLAY","GameFontDisableSmall"); r.stats:SetTextColor(AB.THEME.muted[1],AB.THEME.muted[2],AB.THEME.muted[3]); r.stats:SetPoint("BOTTOMLEFT",r.icon,"BOTTOMRIGHT",8,2); r.stats:SetWidth(770); r.stats:SetJustifyH("LEFT")
    r:RegisterForClicks("LeftButtonUp","RightButtonUp")
    r:SetScript("OnClick",function()
      if not this.itemID then return end
      if arg1=="RightButton" or IsControlKeyDown() then AB:OpenSourcePanel(this.itemID); return end
      AB:EquipItem(AB.browserSlot,this.itemID)
      if AB.browserSlot~="ALL" then AB.itemBrowser:Hide() end
    end)
    r:SetScript("OnEnter",function() if this.itemID then AB:ShowItemTooltip(this,this.itemID) end end); r:SetScript("OnLeave",function() GameTooltip:Hide() end)
    self.itemRows[i]=r
  end
  self.prevItem=MakeButton(f,"Previous",82,22); self.prevItem:SetPoint("BOTTOMLEFT",f,"BOTTOMLEFT",28,18); self.prevItem:SetScript("OnClick",function() AB:ScrollItemPage(1) end)
  self.nextItem=MakeButton(f,"Next",82,22); self.nextItem:SetPoint("LEFT",self.prevItem,"RIGHT",8,0); self.nextItem:SetScript("OnClick",function() AB:ScrollItemPage(-1) end)
  self.pageText=f:CreateFontString(nil,"OVERLAY","GameFontHighlight"); self.pageText:SetPoint("LEFT",self.nextItem,"RIGHT",12,0)
  self.packText=f:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); self.packText:SetPoint("BOTTOMRIGHT",f,"BOTTOMRIGHT",-26,22)
  local hint=f:CreateFontString(nil,"OVERLAY","GameFontDisableSmall"); hint:SetPoint("BOTTOM",f,"BOTTOM",60,22); hint:SetText("Click to equip  -  Right-click for sources"); hint:SetTextColor(AB.THEME.muted[1],AB.THEME.muted[2],AB.THEME.muted[3])
  self:SyncItemFilterControls()
end

function AB:ToggleStatFilter(key)
  local stats=self.itemFilter.stats; local i
  for i=1,table.getn(stats) do if stats[i][1]==key then table.remove(stats,i); self:SyncItemFilterControls(); self:QueueItemRefresh(0); return end end
  if table.getn(stats)>=MAX_STAT_FILTERS then self.Print("You can filter on up to "..MAX_STAT_FILTERS.." stats at once."); return end
  table.insert(stats,{key,0}); self:SyncItemFilterControls(); self:QueueItemRefresh(0)
end

-- Pushes self.itemFilter into every filter control.
function AB:SyncItemFilterControls()
  local fl=self.itemFilter
  self.slotDrop:Refresh(); self.sourceDrop:Refresh(); self.qualityDrop:Refresh(); self.sortDrop:Refresh(); self.statDrop:Refresh()
  self.usableCheck:SetChecked(fl.usable and 1 or nil); self.classCheck:SetChecked(fl.classOnly and 1 or nil); self.hiddenCheck:SetChecked(fl.showHidden and 1 or nil)
  self.minIlvlBox:SetText(fl.minIlvl and tostring(fl.minIlvl) or ""); self.maxIlvlBox:SetText(fl.maxIlvl and tostring(fl.maxIlvl) or "")
  local i,c,s
  for i=1,MAX_STAT_FILTERS do
    c=self.statChips[i]; s=fl.stats[i]
    if s then c.label:SetText(self.STAT_LABELS[s[1]] or s[1]); c.edit:SetText(s[2]>0 and tostring(s[2]) or ""); c:Show() else c:Hide() end
  end
end

-- Wheel down / Next = next page, wheel up / Previous = previous page.
function AB:ScrollItemPage(delta)
  local pages=self.itemPages or 1
  if delta<0 and self.itemPage<pages then self.itemPage=self.itemPage+1
  elseif delta>0 and self.itemPage>1 then self.itemPage=self.itemPage-1
  else return end
  self:RenderItemPage()
end

function AB:OpenItemBrowser(slot)
  slot=slot or "ALL"
  self.browserSlot=slot; self.itemFilter.slot=FILTER_SLOT_OF[slot] or slot; self.itemPage=1
  self.itemBrowserTitle:SetText(slot=="ALL" and "ITEM DATABASE" or ("ITEM DATABASE  |cff8d96a8-  "..self.SLOT_LABELS[slot].."|r"))
  self.itemSearch:SetText("")
  self:SyncItemFilterControls()
  self.itemBrowser:Show()
  self.itemRefreshAt=nil; self:RefreshItemResults()
end

-- Runs the filters against the search index and shows page 1.
function AB:RefreshItemResults()
  if not self.itemRows or not AshenDB or not AshenDB.Items then return end
  local fl=self.itemFilter
  fl.minIlvl=tonumber(self.minIlvlBox:GetText() or ""); fl.maxIlvl=tonumber(self.maxIlvlBox:GetText() or "")
  local idx=self.ItemIndex
  local matches=idx:Query({slot=fl.slot,query=string.lower(self.itemSearch:GetText() or ""),quality=fl.quality,minIlvl=fl.minIlvl,maxIlvl=fl.maxIlvl,source=fl.source,stats=fl.stats,
    maxReq=fl.usable and self:GetBuildLevel() or nil,class=fl.classOnly and self.current.class or nil,showHidden=fl.showHidden})
  if fl.sort=="ilvlUp" then
    local n=table.getn(matches); local i; for i=1,math.floor(n/2) do matches[i],matches[n-i+1]=matches[n-i+1],matches[i] end
  elseif fl.sort=="name" then
    local names=idx.name; table.sort(matches,function(a,b) return names[a]<names[b] end)
  elseif fl.sort=="req" then
    local req,ilvl=idx.req,idx.ilvl; table.sort(matches,function(a,b) if req[a]~=req[b] then return req[a]>req[b] end return ilvl[a]>ilvl[b] end)
  end
  self.itemMatches=matches
  self:RenderItemPage()
end

local SLOT_TEXT={HEAD="Head",NECK="Neck",SHOULDER="Shoulder",BACK="Back",CHEST="Chest",ROBE="Chest",SHIRT="Shirt",TABARD="Tabard",WRIST="Wrist",HANDS="Hands",WAIST="Waist",LEGS="Legs",FEET="Feet",FINGER="Finger",TRINKET="Trinket",WEAPON="One-Hand",MAINHAND="Main Hand",OFFHAND="Off Hand",TWOHAND="Two-Hand",SHIELD="Shield",HOLDABLE="Held In Off-hand",RANGED="Ranged",RANGEDRIGHT="Ranged",THROWN="Thrown",RELIC="Relic"}
local ARMOR_TEXT={[1]="Cloth",[2]="Leather",[3]="Mail",[4]="Plate"}

function AB:RenderItemPage()
  local matches=self.itemMatches or {}; local total=table.getn(matches)
  local pages=math.max(1,math.ceil(total/ITEM_ROWS)); self.itemPages=pages
  if self.itemPage>pages then self.itemPage=pages end
  local idx=self.ItemIndex
  local i,row,id,item,c,kind
  for i=1,ITEM_ROWS do
    row=self.itemRows[i]; id=matches[(self.itemPage-1)*ITEM_ROWS+i]; id=id and idx.id[id]; item=id and self:GetItem(id)
    if item then
      row.itemID=id; row.icon:SetTexture(item.icon); row.name:SetText(item.n)
      c=qualityColors[item.q] or qualityColors[1]; row.name:SetTextColor(c[1],c[2],c[3])
      kind=SLOT_TEXT[item.slot] or ""
      if item.itemClass==4 and ARMOR_TEXT[item.subclass] then kind=ARMOR_TEXT[item.subclass].." "..kind elseif item.itemClass==2 and item.weaponType then kind=kind.." "..item.weaponType end
      row.meta:SetText(kind.."   |cffd9c9a3iLvl "..(item.ilvl or 0).."|r"..((item.req or 0)>0 and ("   Req "..item.req) or ""))
      local text=self:StatSummary(item.stats); local direct=self:GetDirectSourceSummary(id)
      if direct~="" then text=(text~="" and (text.."  -  ") or "")..direct end
      row.stats:SetText(text); row:Show()
    else row.itemID=nil; row:Hide() end
  end
  self.pageText:SetText("Page "..self.itemPage.." / "..pages.."  ("..total.." items)")
  if self.itemPage>1 then self.prevItem:Enable() else self.prevItem:Disable() end
  if self.itemPage<pages then self.nextItem:Enable() else self.nextItem:Disable() end
  local pack=AshenBuildsDBPack; self.packText:SetText((pack and pack.name or "AshenDB").." - "..(pack and pack.count or 0).." items")
end

-- "+12 Stamina, +8 Strength" in a fixed stat order.
local SUMMARY_ORDER={"str","agi","sta","int","spi","health","mana","ap","rap","feralAp","crit","hit","rangedHit","haste","spellPower","healing","spellCrit","spellHit","mp5","hp5","defense","dodge","parry","block","blockValue","firePower","frostPower","shadowPower","arcanePower","naturePower","holyPower","fireRes","frostRes","natureRes","shadowRes","arcaneRes","armor"}
local PCT_STATS={crit=true,hit=true,rangedHit=true,haste=true,spellCrit=true,spellHit=true,dodge=true,parry=true,block=true}
function AB:StatSummary(stats)
  if not stats then return "" end
  local parts={}; local i,k,v
  for i=1,table.getn(SUMMARY_ORDER) do
    k=SUMMARY_ORDER[i]; v=stats[k]
    if v and v~=0 then table.insert(parts,"+"..v..(PCT_STATS[k] and "% " or " ")..(self.STAT_LABELS[k] or k)) end
  end
  return table.concat(parts,", ")
end

---------------------------------------------------------------------------
-- Enchants
---------------------------------------------------------------------------
local ENCHANT_ROWS=10
function AB:CreateEnchantBrowser()
  local f=CreateFrame("Frame","AshenBuildsEnchantBrowser",UIParent); f:SetWidth(520); f:SetHeight(500); f:SetPoint("CENTER",UIParent,"CENTER",0,0); MakeBackdrop(f)
  self:SetupWindow(f,{wheel=function() AB.enchantOffset=math.max(0,(AB.enchantOffset or 0)-arg1); AB:RenderEnchantRows() end}); f:Hide(); self.enchantBrowser=f
  self:ApplyEmberBackground(f,10,0.5,0.5,0.4); self:AddEmberHeader(f,34); self:AddEmberWell(f,22,-84,-22,44)
  f.title=f:CreateFontString(nil,"OVERLAY","GameFontNormalLarge"); f.title:SetPoint("TOP",f,"TOP",0,-18)
  local close=CreateFrame("Button",nil,f,"UIPanelCloseButton"); close:SetPoint("TOPRIGHT",f,"TOPRIGHT",-4,-4)
  f.item=f:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); f.item:SetPoint("TOPLEFT",f,"TOPLEFT",28,-58); f.item:SetWidth(300); f.item:SetJustifyH("LEFT")
  local none=MakeButton(f,"Remove Enchant",130,22); none:SetPoint("TOPRIGHT",f,"TOPRIGHT",-26,-52); none:SetScript("OnClick",function() AB:ApplyEnchant(AB.enchantSlot,0); f:Hide() end)
  self.enchantRows={}; local i
  for i=1,ENCHANT_ROWS do
    local r=CreateFrame("Button",nil,f); r:SetWidth(466); r:SetHeight(36); r:SetPoint("TOPLEFT",f,"TOPLEFT",26,-90-(i-1)*38); r:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
    r.text=r:CreateFontString(nil,"OVERLAY","GameFontHighlight"); r.text:SetPoint("TOPLEFT",r,"TOPLEFT",8,-3); r.text:SetWidth(450); r.text:SetJustifyH("LEFT")
    r.desc=r:CreateFontString(nil,"OVERLAY","GameFontDisableSmall"); r.desc:SetPoint("BOTTOMLEFT",r,"BOTTOMLEFT",8,3); r.desc:SetWidth(450); r.desc:SetJustifyH("LEFT"); r.desc:SetTextColor(.3,.95,.3)
    r:SetScript("OnClick",function() if this.enchantID then AB:ApplyEnchant(AB.enchantSlot,this.enchantID); f:Hide() end end)
    self.enchantRows[i]=r
  end
  f.more=f:CreateFontString(nil,"OVERLAY","GameFontDisableSmall"); f.more:SetPoint("BOTTOM",f,"BOTTOM",0,22); f.more:SetTextColor(AB.THEME.muted[1],AB.THEME.muted[2],AB.THEME.muted[3])
end

function AB:OpenEnchantBrowser(slot)
  if not AshenBuildsEnchantSlots[slot] then self.Print(self.SLOT_LABELS[slot].." can't be enchanted."); return end
  local item=self:GetItem(self.current.items[slot] or 0)
  if not item then self.Print("Equip an item in "..self.SLOT_LABELS[slot].." before choosing an enchant."); return end
  self.enchantSlot=slot; self.enchantOffset=0; self.enchantMatches={}
  local i,id
  for i=1,table.getn(AshenBuildsEnchantOrder) do id=AshenBuildsEnchantOrder[i]; if self:IsEnchantAllowed(slot,id,item) then table.insert(self.enchantMatches,id) end end
  local f=self.enchantBrowser; f.title:SetText("ENCHANT "..string.upper(self.SLOT_LABELS[slot]))
  local c=qualityColors[item.q] or qualityColors[1]; f.item:SetText(item.n); f.item:SetTextColor(c[1],c[2],c[3])
  self:RenderEnchantRows(); f:Show()
end

function AB:RenderEnchantRows()
  local matches=self.enchantMatches or {}; local total=table.getn(matches)
  local maxOffset=math.max(0,total-ENCHANT_ROWS); if self.enchantOffset>maxOffset then self.enchantOffset=maxOffset end
  local current=self.current.enchants[self.enchantSlot]
  local i,id,e,r,desc
  for i=1,ENCHANT_ROWS do
    r=self.enchantRows[i]; id=matches[self.enchantOffset+i]; e=id and AshenBuildsEnchants[id]
    if e then
      r.enchantID=id; r.text:SetText((id==current and "|cffffd100> |r" or "")..e.n)
      desc=self:StatSummary(e.stats); if e.desc then desc=(desc~="" and (desc..", ") or "")..e.desc end
      r.desc:SetText(desc); r:Show()
    else r.enchantID=nil; r:Hide() end
  end
  self.enchantBrowser.more:SetText(total>ENCHANT_ROWS and ("Showing "..(self.enchantOffset+1).."-"..math.min(total,self.enchantOffset+ENCHANT_ROWS).." of "..total.." - scroll for more") or (total.." enchants"))
end

function AB:CreateCodeDialog() local f=CreateFrame("Frame","AshenBuildsCodeDialog",UIParent); f:SetWidth(650); f:SetHeight(190); f:SetPoint("CENTER",UIParent,"CENTER",0,0); MakeBackdrop(f); self:SetupWindow(f); f:Hide(); self.codeDialog=f; self:ApplyEmberBackground(f,10,0.5,0.5,0.45); self:AddEmberHeader(f,34); f.title=f:CreateFontString(nil,"OVERLAY","GameFontNormalLarge"); f.title:SetPoint("TOP",f,"TOP",0,-18); local edit=CreateFrame("EditBox",nil,f,"InputBoxTemplate"); edit:SetWidth(580); edit:SetHeight(30); edit:SetPoint("TOP",f,"TOP",0,-62); edit:SetAutoFocus(false); edit:SetMaxLetters(4096); self.codeEdit=edit; local action=MakeButton(f,"Import",90,24); action:SetPoint("BOTTOM",f,"BOTTOM",-50,24); self.codeAction=action; local cancel=MakeButton(f,"Close",90,24); cancel:SetPoint("LEFT",action,"RIGHT",10,0); cancel:SetScript("OnClick",function() f:Hide() end) end
function AB:ShowCodeDialog(title,text,isImport) self.codeDialog.title:SetText(title); self.codeEdit:SetText(text or ""); self.codeDialog:Show(); self.codeEdit:SetFocus(); self.codeEdit:HighlightText(); if isImport then self.codeAction:SetText("Import"); self.codeAction:Show(); self.codeAction:SetScript("OnClick",function() if AB:ImportBuild(AB.codeEdit:GetText()) then AB.codeDialog:Hide() end end) else self.codeAction:Hide() end end
function AB:ToggleUI() if self.frame:IsShown() then self.frame:Hide() else self:RefreshUI(); self.frame:Show() end end

-- v0.6.1 complete item effects and visible sources
local AB_BIND_COLORS={red={1,0.15,0.15},white={1,1,1}}
local AB_SLOT_NAMES={HEAD="Head",NECK="Neck",SHOULDER="Shoulder",BACK="Back",CHEST="Chest",SHIRT="Shirt",TABARD="Tabard",ROBE="Chest",WRIST="Wrist",HANDS="Hands",WAIST="Waist",LEGS="Legs",FEET="Feet",FINGER="Finger",TRINKET="Trinket",WEAPON="One-Hand",MAINHAND="Main Hand",OFFHAND="Off Hand",TWOHAND="Two-Hand",SHIELD="Off Hand",HOLDABLE="Held In Off-hand",RANGED="Ranged",RANGEDRIGHT="Ranged",THROWN="Thrown",RELIC="Relic",WAND="Wand"}
local AB_ARMOR_NAMES={[1]="Cloth",[2]="Leather",[3]="Mail",[4]="Plate",[6]="Shield"}
local AB_STAT_ORDER={"str","agi","sta","int","spi","armor","holyRes","fireRes","natureRes","frostRes","shadowRes","arcaneRes"}
local AB_STAT_TOOLTIP={str="Strength",agi="Agility",sta="Stamina",int="Intellect",spi="Spirit",holyRes="Holy Resistance",fireRes="Fire Resistance",natureRes="Nature Resistance",frostRes="Frost Resistance",shadowRes="Shadow Resistance",arcaneRes="Arcane Resistance"}

function AB:MoneyText(copper)
  copper=tonumber(copper) or 0; local g=math.floor(copper/10000); local s=math.floor(math.mod(copper,10000)/100); local c=math.mod(copper,100); local t={}
  if g>0 then table.insert(t,g.."|cffffd700g|r") end; if s>0 or g>0 then table.insert(t,s.."|cffc7c7cfs|r") end; table.insert(t,c.."|cffeda55fc|r"); return table.concat(t," ")
end

function AB:GetItemDetail(id) return AshenDB and AshenDB.ItemDetails and AshenDB.ItemDetails[tonumber(id)] end
function AB:GetItemSources(id) return (AshenDB and AshenDB.ItemSources and AshenDB.ItemSources[tonumber(id)]) or {} end

function AB:GetDirectSourceSummary(id)
  local ss=self:GetItemSources(id); local s=ss[1]
  if not s then
    local item=self:GetItem(id); local broad=item and item.source or ""
    return broad~="" and ("Source: "..broad) or ""
  end
  if s[1]=="craft" then return "Crafted by "..(s[4] or "Profession") end
  if s[1]=="drop" then return "Dropped by "..(s[3] or "Unknown")..((s[4] and s[4]~="") and " - "..s[4] or "") end
  if s[1]=="vendor" then return "Sold by "..(s[3] or "Unknown")..((s[4] and s[4]~="") and " - "..s[4] or "") end
  if s[1]=="quest" then return "Reward from "..(s[3] or "Unknown") end
  local item=self:GetItem(id); local broad=item and item.source or ""
  return broad~="" and ("Source: "..broad) or ""
end

function AB:AddTooltipDouble(left,right,lr,lg,lb,rr,rg,rb)
  if GameTooltip.AddDoubleLine then GameTooltip:AddDoubleLine(left,right,lr or 1,lg or 1,lb or 1,rr or 1,rg or 1,rb or 1) else GameTooltip:AddLine(left.."                         "..right,lr or 1,lg or 1,lb or 1) end
end

function AB:FormatDropChance(chance)
  chance=tonumber(chance)
  if not chance or chance<=0 then return nil end
  if chance<0.01 then return "<0.01%" end
  if chance<0.1 then return string.format("%.3f%%",chance) end
  return string.format("%.2f%%",chance)
end

function AB:AddSourceTooltipLines(id)
  local ss=self:GetItemSources(id); local count=table.getn(ss); local i,s,reags,j
  GameTooltip:AddLine(" ")
  GameTooltip:AddLine("Ashen Source",1,0.82,0)
  if count==0 then
    local item=self:GetItem(id); local broad=item and item.source or ""; GameTooltip:AddLine(broad~="" and ("Source category: "..broad) or "Direct source details are not available in this database build.",0.55,0.55,0.55,true)
    return
  end
  for i=1,count do
    s=ss[i]
    if s[1]=="craft" then
      GameTooltip:AddLine("Crafted by "..(s[4] or "Profession"),0.3,0.8,1,true)
      if s[3] and s[3]~="" then GameTooltip:AddLine("Recipe: "..s[3],1,1,1,true) end
      if s[5] and s[5]>0 then GameTooltip:AddLine("Requires "..(s[4] or "Skill").." "..s[5],0.75,0.75,0.75,true) end
      reags=s[8] or {}
      if table.getn(reags)>0 then
        local mats={}
        for j=1,math.min(table.getn(reags),5) do table.insert(mats,(reags[j][2] or "Item").." x"..(reags[j][3] or 1)) end
        GameTooltip:AddLine("Materials: "..table.concat(mats,", "),0.75,0.75,0.75,true)
      end
    elseif s[1]=="drop" then
      GameTooltip:AddLine("Dropped by "..(s[3] or "Unknown Creature"),0.3,0.8,1,true)
      if s[4] and s[4]~="" then GameTooltip:AddLine(s[4],1,1,1,true) end
      local chance=self:FormatDropChance(s[5]); if chance then GameTooltip:AddLine("Drop Chance: "..chance,0.75,0.75,0.75) end
    elseif s[1]=="more" then
      GameTooltip:AddLine("+"..(s[2] or 0).." additional creature drop sources",0.55,0.55,0.55,true)
    elseif s[1]=="vendor" then
      GameTooltip:AddLine("Sold by "..(s[3] or "Unknown Vendor"),0.3,0.8,1,true)
      if s[4] and s[4]~="" then GameTooltip:AddLine(s[4],1,1,1,true) end
    elseif s[1]=="quest" then
      GameTooltip:AddLine("Reward from "..(s[3] or "Unknown Quest"),0.3,0.8,1,true)
      if s[4] and s[4]~="" then GameTooltip:AddLine(s[4],1,1,1,true) end
      if s[7] and s[7]>0 then GameTooltip:AddLine("Quest Level: "..s[7]..(s[5]=="choice" and " (Choose one)" or ""),0.75,0.75,0.75,true) end
    end
    if i>=3 and count>3 then GameTooltip:AddLine("+"..(count-3).." additional sources",0.55,0.55,0.55); break end
  end
  GameTooltip:AddLine("Right-click item for full source details",0.5,0.5,0.5,true)
end

function AB:GetEquippedSetCount(setId)
  setId=tonumber(setId)
  if not setId or not self.current or not self.current.items then return 0 end
  local count=0; local slot,itemId,item,itemSetId
  for slot,itemId in pairs(self.current.items) do
    item=self:GetItem(itemId); itemSetId=self:GetItemSetId(itemId,item)
    if itemSetId==setId then count=count+1 end
  end
  return count
end

function AB:IsBuildItemEquipped(itemId)
  itemId=tonumber(itemId)
  if not itemId or not self.current or not self.current.items then return false end
  local _,equippedId
  for _,equippedId in pairs(self.current.items) do if tonumber(equippedId)==itemId then return true end end
  return false
end

function AB:AddSetTooltipLines(id,item)
  local set,setId=self:GetItemSetForItem(id,item)
  if not setId then return end
  GameTooltip:AddLine(" ")
  if not set then
    GameTooltip:AddLine("Set data missing (#"..setId..")",1,0.15,0.15,true)
    return
  end

  local equipped=self:GetEquippedSetCount(setId)
  local total=table.getn(set.items or {})
  GameTooltip:AddLine("|cffffd100"..(set.name or "Item Set").." ("..total..")|r",1,0.82,0)

  local classText=self:GetRequiredClassText(set.classMask)
  if classText then GameTooltip:AddLine("Classes: "..classText,1,1,1,true) end

  local i,piece,pieceId,pieceName
  for i=1,total do
    piece=set.items[i]
    pieceId=piece and tonumber(piece[1])
    pieceName=(piece and piece[2]) or "Unknown item"
    if pieceId==tonumber(id) then
      GameTooltip:AddLine(pieceName,1,1,1,true)
    elseif self:IsBuildItemEquipped(pieceId) then
      GameTooltip:AddLine(pieceName,0.1,1,0.1,true)
    else
      GameTooltip:AddLine(pieceName,0.5,0.5,0.5,true)
    end
  end

  local bonuses=set.bonuses or {}; local b,threshold,text,line
  for i=1,table.getn(bonuses) do
    b=bonuses[i]
    threshold=b and tonumber(b[1]) or 0
    text=b and b[3] or ""
    if text~="" then
      if equipped>=threshold then
        line="|cffffffff("..threshold..") Set: |r|cff20ff20"..text.."|r"
      else
        line="|cff777f8f("..threshold..") Set: "..text.."|r"
      end
      GameTooltip:AddLine(line,1,1,1,true)
    end
  end
end

local AB_CLASS_BITS={{"Warrior",1},{"Paladin",2},{"Hunter",4},{"Rogue",8},{"Priest",16},{"Shaman",64},{"Mage",128},{"Warlock",256},{"Druid",1024}}
function AB:GetRequiredClassText(mask)
  mask=tonumber(mask) or -1; if mask<0 then return nil end
  local names={}; local i,p
  for i=1,table.getn(AB_CLASS_BITS) do p=AB_CLASS_BITS[i]; if math.mod(math.floor(mask/p[2]),2)==1 then table.insert(names,p[1]) end end
  if table.getn(names)==0 or table.getn(names)==9 then return nil end
  return table.concat(names,", ")
end

function AB:ShowItemTooltip(owner,id)
  local item=self:GetItem(id); if not item then return end; local d=self:GetItemDetail(id) or {}; local qc=qualityColors[item.q] or qualityColors[1]
  GameTooltip:SetOwner(owner,"ANCHOR_RIGHT"); GameTooltip:ClearLines(); GameTooltip:SetText(item.n,qc[1],qc[2],qc[3])
  if d[1] and d[1]~="" then GameTooltip:AddLine(d[1],1,1,1) end
  local slot=AB_SLOT_NAMES[item.slot] or item.slot or ""; local typeName=""
  if item.itemClass==4 then typeName=AB_ARMOR_NAMES[item.subclass] or "" elseif item.itemClass==2 then typeName=item.weaponType or "" end
  if slot~="" then self:AddTooltipDouble(slot,typeName,1,1,1,1,1,1) end
  if item.itemClass==2 and item.minDamage and item.maxDamage and item.maxDamage>0 then self:AddTooltipDouble(string.format("%d - %d Damage",item.minDamage,item.maxDamage),item.speed and item.speed>0 and string.format("Speed %.2f",item.speed) or "",1,1,1,1,1,1); if item.stats and item.stats.dps then GameTooltip:AddLine(string.format("(%.1f damage per second)",item.stats.dps),1,1,1) end end
  if item.armor and item.armor>0 then GameTooltip:AddLine(item.armor.." Armor",1,1,1) end
  local i,k,v,e,trig,prefix
  for i=1,table.getn(AB_STAT_ORDER) do k=AB_STAT_ORDER[i]; v=item.stats and item.stats[k]; if v and v~=0 and not (k=="armor") then GameTooltip:AddLine("+"..v.." "..(AB_STAT_TOOLTIP[k] or k),1,1,1) end end
  if d[2] and d[2]>0 then GameTooltip:AddLine("Durability "..d[2].." / "..d[2],1,1,1) end
  if item.req and item.req>0 then local usable=self:GetBuildLevel()>=item.req; GameTooltip:AddLine("Requires Level "..item.req,1,usable and 1 or 0.15,usable and 1 or 0.15) end
  local classText=self:GetRequiredClassText(item.classMask); if classText then local allowed=self:IsClassAllowedRaw(self:GetRawItem(id),self.current.class); GameTooltip:AddLine("Classes: "..classText,1,allowed and 1 or 0.15,allowed and 1 or 0.15,true) end
  if d[5] and tostring(d[5])~="" and tostring(d[5])~="0" and tonumber(d[6] or 0)>0 then GameTooltip:AddLine("Requires "..d[5].." ("..d[6]..")",1,0.15,0.15) end
  if d[7] and tostring(d[7])~="" and tostring(d[7])~="0" then local reqText="Requires "..d[7]; if d[8] and tostring(d[8])~="" and tostring(d[8])~="0" then reqText=reqText.." - "..d[8] end; GameTooltip:AddLine(reqText,1,0.15,0.15) end
  if d[9] then
    for i=1,table.getn(d[9]) do
      e=d[9][i]
      if type(e)=="table" then trig=e[1]; v=e[2] else trig=1; v=e end
      if trig==0 then prefix="Use: " elseif trig==2 then prefix="Chance on hit: " elseif trig==4 then prefix="Use: " else prefix="Equip: " end
      if v and v~="" then GameTooltip:AddLine(prefix..v,0.1,1,0.1,true) end
    end
  end
  self:AddSetTooltipLines(id,item)
  if d[4] and d[4]~="" then GameTooltip:AddLine('"'..d[4]..'"',1,0.82,0,true) end
  if d[3] and d[3]>0 then GameTooltip:AddLine("Sell Price: "..self:MoneyText(d[3]),1,1,1) end
  self:AddSourceTooltipLines(id)
  GameTooltip:Show()
end

function AB:CreateSourcePanel()
  local f=CreateFrame("Frame","AshenBuildsSourcePanel",UIParent); f:SetWidth(610); f:SetHeight(650); f:SetPoint("CENTER",UIParent,"CENTER",180,0); MakeBackdrop(f); self:SetupWindow(f,{fit=true}); f:Hide(); self.sourcePanel=f
  self:ApplyEmberBackground(f,10,0.33,0.45,0.4); self:AddEmberHeader(f,36); self:AddEmberWell(f,20,-104,-20,20)
  f.title=f:CreateFontString(nil,"OVERLAY","GameFontNormalLarge"); f.title:SetPoint("TOPLEFT",f,"TOPLEFT",28,-22); f.title:SetWidth(520); f.title:SetJustifyH("LEFT")
  local close=CreateFrame("Button",nil,f,"UIPanelCloseButton"); close:SetPoint("TOPRIGHT",f,"TOPRIGHT",-4,-4)
  f.icon=f:CreateTexture(nil,"ARTWORK"); f.icon:SetWidth(44); f.icon:SetHeight(44); f.icon:SetPoint("TOPLEFT",f,"TOPLEFT",28,-52)
  f.meta=f:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); f.meta:SetPoint("TOPLEFT",f.icon,"TOPRIGHT",10,-2); f.meta:SetWidth(490); f.meta:SetJustifyH("LEFT")
  f.text=f:CreateFontString(nil,"OVERLAY","GameFontHighlight"); f.text:SetPoint("TOPLEFT",f,"TOPLEFT",30,-112); f.text:SetWidth(550); f.text:SetHeight(500); f.text:SetJustifyH("LEFT"); f.text:SetJustifyV("TOP")
end

function AB:OpenSourcePanel(id)
  local item=self:GetItem(id); if not item then return end; local ss=self:GetItemSources(id); local f=self.sourcePanel; local qc=qualityColors[item.q] or qualityColors[1]; f.title:SetText(item.n); f.title:SetTextColor(qc[1],qc[2],qc[3]); f.icon:SetTexture(item.icon); f.meta:SetText("Item #"..id.." - Item Level "..(item.ilvl or 0).." - Requires "..(item.req or 0))
  local lines={}; local i,j,s,reags
  if table.getn(ss)==0 then
    table.insert(lines,"|cffffd100SOURCE|r")
    local broad=item.source or ""
    table.insert(lines,broad~="" and ("Source category: "..broad) or "No direct source relationship is available in AshenDB.")
  end
  for i=1,table.getn(ss) do s=ss[i]; if i>1 then table.insert(lines,"") end
    if s[1]=="craft" then
      table.insert(lines,"|cffffd100CRAFTED|r"); table.insert(lines,"|cffffffffProfession:|r "..(s[4] or "Unknown")); if s[5] and s[5]>0 then table.insert(lines,"|cffffffffRequired Skill:|r "..s[5]) end; table.insert(lines,"|cffffffffRecipe:|r "..(s[3] or item.n)); reags=s[8] or {}; if table.getn(reags)>0 then table.insert(lines,""); table.insert(lines,"|cffffd100MATERIALS|r"); for j=1,table.getn(reags) do table.insert(lines,(reags[j][2] or "Item").." x"..(reags[j][3] or 1)) end end
    elseif s[1]=="drop" then
      table.insert(lines,"|cffffd100DROPPED BY|r"); table.insert(lines,"|cffffffff"..(s[3] or "Unknown Creature").."|r"); if s[4] and s[4]~="" then table.insert(lines,s[4]) end; local chance=self:FormatDropChance(s[5]); if chance then table.insert(lines,"Drop Chance: "..chance) else table.insert(lines,"Drop chance not available") end
    elseif s[1]=="more" then
      table.insert(lines,"|cff9ea5b2+"..(s[2] or 0).." additional creature drop sources omitted from the in-memory pack.|r")
    elseif s[1]=="vendor" then
      table.insert(lines,"|cffffd100SOLD BY|r"); table.insert(lines,"|cffffffff"..(s[3] or "Unknown Vendor").."|r"); if s[4] and s[4]~="" then table.insert(lines,s[4]) end
    elseif s[1]=="quest" then
      table.insert(lines,"|cffffd100QUEST REWARD|r"); table.insert(lines,"|cffffffff"..(s[3] or "Unknown Quest").."|r"); if s[4] and s[4]~="" then table.insert(lines,s[4]) end; if s[7] and s[7]>0 then table.insert(lines,"Quest Level: "..s[7]) end; if s[5]=="choice" then table.insert(lines,"Choose-one reward") end
    end
  end
  f.text:SetText(table.concat(lines,"\n")); f:Show()
end
