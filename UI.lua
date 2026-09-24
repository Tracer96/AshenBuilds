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
  frame:SetScript("OnHide",function() ClearWindowFocus(this) end)
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
  b.enchantText=b:CreateFontString(nil,"OVERLAY","GameFontDisableSmall"); b.enchantText:SetPoint("TOP",b.itemText,"BOTTOM",0,-2); b.enchantText:SetWidth(105); b.enchantText:SetJustifyH("CENTER")
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
  local new=MakeButton(f,"New",58,22); new:SetPoint("LEFT",save,"RIGHT",4,0); new:SetScript("OnClick",function() AB.current=AB.NewBuildData("New Build"); AshenBuildsDB.current=AB.current; AB.selectedBuild=nil; AB:RefreshUI() end)
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
  local browse=MakeButton(f,"ITEM DATABASE",130,25); browse:SetPoint("TOPRIGHT",f,"TOPRIGHT",-28,-86); browse:SetScript("OnClick",function() AB:OpenItemBrowser("HEAD") end)
  local saved=MakeButton(f,"SAVED BUILDS",118,25); saved:SetPoint("RIGHT",browse,"LEFT",-8,0); saved:SetScript("OnClick",function() AB:OpenBuildBrowser() end)

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
  local id=self.current.items[button.slot] or 0; if id>0 then self:ShowItemTooltip(button,id) else GameTooltip:SetOwner(button,"ANCHOR_RIGHT"); GameTooltip:SetText(self.SLOT_LABELS[button.slot].." - Empty",.6,.65,.75); GameTooltip:Show() end
end

function AB:RefreshUI()
  if not self.frame then return end
  self.nameBox:SetText(self.current.name or "New Build"); self.classButton:SetText(self.current.class); self.raceButton:SetText(self.current.race); self.specButton:SetText(self.current.spec); self.levelBox:SetText(self:GetBuildLevel())
  local slot,b,id,item,c,enchant
  for slot,b in pairs(self.slotButtons) do id=self.current.items[slot]; item=id and self:GetItem(id); enchant=AshenBuildsEnchants[(self.current.enchants and self.current.enchants[slot]) or 0]; if item then b.icon:SetTexture(item.icon or "Interface\\Icons\\INV_Misc_QuestionMark"); b.itemText:SetText(item.n); c=qualityColors[item.q] or qualityColors[1]; b.itemText:SetTextColor(c[1],c[2],c[3]) else b.icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark"); b.itemText:SetText("Empty"); b.itemText:SetTextColor(AB.THEME.empty[1],AB.THEME.empty[2],AB.THEME.empty[3]) end; b.enchantText:SetText(enchant and enchant.n or "No enchant"); if enchant then b.enchantText:SetTextColor(.2,1,.2) else b.enchantText:SetTextColor(AB.THEME.muted[1],AB.THEME.muted[2],AB.THEME.muted[3]) end end
  self:RefreshStats(); self:RefreshSetBonuses()
end

function AB:ClearStatColumns() local i,c,j for i=1,6 do c=self.statsColumns[i]; if c.lines then for j=1,table.getn(c.lines) do c.lines[j]:Hide() end end; c.lines={} end end
function AB:PutStat(col,label,value,y,color)
  local c=self.statsColumns[col]; local a,b=StatLine(c,label,value,y,color); table.insert(c.lines,a); table.insert(c.lines,b)
end

function AB:RefreshStats()
  self:ClearStatColumns(); local ok,d=pcall(function() return AB:GetDerivedStats(self.current) end); if not ok or not d then self:PutStat(1,"Calculation error",tostring(d),-8,{1,.2,.2}); return end
  local function heading(col,title) Section(self.statsColumns[col],title,-8) end
  local y
  heading(1,"BASE STATS"); y=-34; self:PutStat(1,"Strength",F(d.str),y); y=y-16; self:PutStat(1,"Agility",F(d.agi),y); y=y-16; self:PutStat(1,"Stamina",F(d.sta),y); y=y-16; self:PutStat(1,"Intellect",F(d.int),y); y=y-16; self:PutStat(1,"Spirit",F(d.spi),y)
  heading(2,"RESOURCES"); y=-34; self:PutStat(2,"Health",F(d.health),y); y=y-17; if d.mana and d.mana>0 then self:PutStat(2,"Mana",F(d.mana),y); y=y-17 end; self:PutStat(2,"Armor",F(d.armor),y)
  heading(3,"MELEE & RANGED"); y=-34; self:PutStat(3,"Attack Power",F(d.attackPower),y); y=y-16; self:PutStat(3,"Ranged AP",F(d.rangedAttackPower),y); y=y-16; self:PutStat(3,"Melee Crit",F(d.meleeCrit).."%",y); y=y-16; self:PutStat(3,"Ranged Crit",F(d.rangedCrit).."%",y); y=y-16; self:PutStat(3,"Melee Hit",F(d.hit).."%",y); y=y-16; self:PutStat(3,"Ranged Hit",F(d.rangedHit).."%",y); y=y-16; if d.mainSkill then self:PutStat(3,"MH "..d.mainSkill.type,F(d.mainSkill.total),y); y=y-16 end; if d.rangedSkill then self:PutStat(3,"Ranged "..d.rangedSkill.type,F(d.rangedSkill.total),y) end
  heading(4,"SPELLS & HEALING"); y=-34; self:PutStat(4,"Spell Power",F(d.spellPower),y); y=y-17; self:PutStat(4,"Healing",F(d.healing),y); y=y-17; self:PutStat(4,"Spell Crit",F(d.spellCrit).."%",y); y=y-17; self:PutStat(4,"Spell Hit",F(d.spellHit).."%",y); y=y-17; self:PutStat(4,"MP5",F(d.mp5),y)
  heading(5,"DEFENSE"); y=-34; self:PutStat(5,"Defense",F(d.defense),y); y=y-17; self:PutStat(5,"Dodge",F(d.dodge).."%",y); y=y-17; self:PutStat(5,"Parry",F(d.parry).."%",y); y=y-17; self:PutStat(5,"Block",F(d.block).."%",y); y=y-17; self:PutStat(5,"Block Value",F(d.blockValue),y)
  heading(6,"RESISTANCES"); y=-34; self:PutStat(6,"Fire",F(d.resistances.fire),y); y=y-17; self:PutStat(6,"Frost",F(d.resistances.frost),y); y=y-17; self:PutStat(6,"Nature",F(d.resistances.nature),y); y=y-17; self:PutStat(6,"Shadow",F(d.resistances.shadow),y); y=y-17; self:PutStat(6,"Arcane",F(d.resistances.arcane),y)
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

function AB:RefreshBuildList()
  if not self.buildRows then return end
  local names={}; local name
  for name in pairs(AshenBuildsDB.builds or {}) do table.insert(names,name) end
  table.sort(names)
  local i,row
  for i=1,table.getn(self.buildRows) do
    row=self.buildRows[i]; name=names[i]
    if name then row.buildName=name; row.text:SetText(name); row:Show() else row.buildName=nil; row:Hide() end
  end
  if self.buildCountText then self.buildCountText:SetText(table.getn(names).." saved build"..(table.getn(names)==1 and "" or "s")) end
end

function AB:CreateBuildBrowser()
  local f=CreateFrame("Frame","AshenBuildsBuildBrowser",UIParent); f:SetWidth(430); f:SetHeight(500); f:SetPoint("CENTER",UIParent,"CENTER",260,0); MakeBackdrop(f); self:SetupWindow(f); f:Hide(); self.buildBrowser=f
  self:ApplyEmberBackground(f,10,0.33,0.4,0.4); self:AddEmberHeader(f,34); self:AddEmberWell(f,28,-72,-36,58)
  local t=f:CreateFontString(nil,"OVERLAY","GameFontNormalLarge"); t:SetPoint("TOP",f,"TOP",0,-18); t:SetText("SAVED BUILDS")
  local close=CreateFrame("Button",nil,f,"UIPanelCloseButton"); close:SetPoint("TOPRIGHT",f,"TOPRIGHT",-4,-4)
  self.buildCountText=f:CreateFontString(nil,"OVERLAY","GameFontDisableSmall"); self.buildCountText:SetPoint("TOP",f,"TOP",0,-50); self.buildCountText:SetTextColor(AB.THEME.muted[1],AB.THEME.muted[2],AB.THEME.muted[3])
  self.buildRows={}; local i
  for i=1,10 do
    local r=CreateFrame("Button",nil,f); r:SetWidth(350); r:SetHeight(32); r:SetPoint("TOPLEFT",f,"TOPLEFT",36,-78-(i-1)*36); r:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
    r.text=r:CreateFontString(nil,"OVERLAY","GameFontHighlight"); r.text:SetPoint("LEFT",r,"LEFT",10,0); r.text:SetWidth(250); r.text:SetJustifyH("LEFT")
    r:RegisterForClicks("LeftButtonUp","RightButtonUp")
    r:SetScript("OnClick",function() if not this.buildName then return end; if arg1=="RightButton" then AB.selectedBuild=this.buildName; AB:DeleteBuild(this.buildName) else AB:LoadBuild(this.buildName); f:Hide() end end)
    self.buildRows[i]=r
  end
  local help=f:CreateFontString(nil,"OVERLAY","GameFontDisableSmall"); help:SetPoint("BOTTOM",f,"BOTTOM",0,24); help:SetText("Left-click to load  -  Right-click to delete"); help:SetTextColor(AB.THEME.muted[1],AB.THEME.muted[2],AB.THEME.muted[3])
end
function AB:OpenBuildBrowser() self:RefreshBuildList(); self.buildBrowser:Show() end

function AB:CreateItemBrowser()
  local f=CreateFrame("Frame","AshenBuildsItemBrowser",UIParent); f:SetWidth(880); f:SetHeight(650); f:SetPoint("CENTER",UIParent,"CENTER",0,0); MakeBackdrop(f); self:SetupWindow(f,{fit=true,wheel=function() AB:ScrollItemPage(arg1) end}); f:Hide(); self.itemBrowser=f
  self:ApplyEmberBackground(f,10,0.55,0.5,0.4); self:AddEmberHeader(f,34); self:AddEmberWell(f,22,-114,-36,48)
  local t=f:CreateFontString(nil,"OVERLAY","GameFontNormalLarge"); t:SetPoint("TOP",f,"TOP",0,-17); t:SetText("ITEM DATABASE")
  local close=CreateFrame("Button",nil,f,"UIPanelCloseButton"); close:SetPoint("TOPRIGHT",f,"TOPRIGHT",-4,-4)
  local search=CreateFrame("EditBox",nil,f,"InputBoxTemplate"); search:SetWidth(390); search:SetHeight(24); search:SetPoint("TOPLEFT",f,"TOPLEFT",26,-52); search:SetAutoFocus(false); self.itemSearch=search; search:SetScript("OnTextChanged",function() AB.itemPage=1; AB:RefreshItemResults() end)
  local clear=MakeButton(f,"Clear",58,22); clear:SetPoint("LEFT",search,"RIGHT",7,0); clear:SetScript("OnClick",function() search:SetText("") end)
  self.qualityFilter=-1; self.usableOnly=true; self.classOnly=true; self.showHidden=false; self.armorFilter="All"; self.weaponFilter="All"; self.sourceFilter=""
  self.qualityButton=MakeButton(f,"Quality: All",112,22); self.qualityButton:SetPoint("TOPLEFT",f,"TOPLEFT",26,-82); self.qualityButton:SetScript("OnClick",function() AB.qualityFilter=AB.qualityFilter+1; if AB.qualityFilter>5 then AB.qualityFilter=-1 end; AB.qualityButton:SetText(AB.qualityFilter<0 and "Quality: All" or "Quality: "..AB.QUALITY_LABELS[AB.qualityFilter]); AB.itemPage=1; AB:RefreshItemResults() end)
  self.usableButton=MakeButton(f,"Level: Usable",105,22); self.usableButton:SetPoint("LEFT",self.qualityButton,"RIGHT",7,0); self.usableButton:SetScript("OnClick",function() AB.usableOnly=not AB.usableOnly; AB.usableButton:SetText(AB.usableOnly and "Level: Usable" or "Level: All"); AB.itemPage=1; AB:RefreshItemResults() end)
  self.classButtonFilter=MakeButton(f,"Class: On",90,22); self.classButtonFilter:SetPoint("LEFT",self.usableButton,"RIGHT",7,0); self.classButtonFilter:SetScript("OnClick",function() AB.classOnly=not AB.classOnly; AB.classButtonFilter:SetText(AB.classOnly and "Class: On" or "Class: Off"); AB:RefreshItemResults() end)
  self.hiddenButton=MakeButton(f,"Hidden: Off",92,22); self.hiddenButton:SetPoint("LEFT",self.classButtonFilter,"RIGHT",7,0); self.hiddenButton:SetScript("OnClick",function() AB.showHidden=not AB.showHidden; AB.hiddenButton:SetText(AB.showHidden and "Hidden: On" or "Hidden: Off"); AB:RefreshItemResults() end)
  self.itemRows={}; local i
  for i=1,12 do local r=CreateFrame("Button",nil,f); r:SetWidth(810); r:SetHeight(36); r:SetPoint("TOPLEFT",f,"TOPLEFT",28,-120-(i-1)*40); r:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight"); r.icon=r:CreateTexture(nil,"ARTWORK"); r.icon:SetWidth(30); r.icon:SetHeight(30); r.icon:SetPoint("LEFT",r,"LEFT",2,0); r.name=r:CreateFontString(nil,"OVERLAY","GameFontHighlight"); r.name:SetPoint("TOPLEFT",r.icon,"TOPRIGHT",8,-1); r.name:SetWidth(330); r.name:SetJustifyH("LEFT"); r.stats=r:CreateFontString(nil,"OVERLAY","GameFontDisableSmall"); r.stats:SetTextColor(AB.THEME.muted[1],AB.THEME.muted[2],AB.THEME.muted[3]); r.stats:SetPoint("BOTTOMLEFT",r.icon,"BOTTOMRIGHT",8,2); r.stats:SetWidth(735); r.stats:SetJustifyH("LEFT"); r:RegisterForClicks("LeftButtonUp","RightButtonUp"); r:SetScript("OnClick",function() if this.itemID then if arg1=="RightButton" or IsControlKeyDown() then AB:OpenSourcePanel(this.itemID) else AB:EquipItem(AB.browserSlot,this.itemID); AB.itemBrowser:Hide() end end end); r:SetScript("OnEnter",function() if this.itemID then AB:ShowItemTooltip(this,this.itemID) end end); r:SetScript("OnLeave",function() GameTooltip:Hide() end); self.itemRows[i]=r end
  self.prevItem=MakeButton(f,"Previous",82,22); self.prevItem:SetPoint("BOTTOMLEFT",f,"BOTTOMLEFT",28,18); self.prevItem:SetScript("OnClick",function() if AB.itemPage>1 then AB.itemPage=AB.itemPage-1; AB:RefreshItemResults() end end)
  self.nextItem=MakeButton(f,"Next",82,22); self.nextItem:SetPoint("LEFT",self.prevItem,"RIGHT",8,0); self.nextItem:SetScript("OnClick",function() AB.itemPage=AB.itemPage+1; AB:RefreshItemResults() end)
  self.pageText=f:CreateFontString(nil,"OVERLAY","GameFontHighlight"); self.pageText:SetPoint("LEFT",self.nextItem,"RIGHT",12,0); self.packText=f:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); self.packText:SetPoint("BOTTOMRIGHT",f,"BOTTOMRIGHT",-26,22)
end
-- Wheel down = next page, wheel up = previous page; RefreshItemResults clamps past the last page.
function AB:ScrollItemPage(delta) if delta<0 then self.itemPage=self.itemPage+1 elseif self.itemPage>1 then self.itemPage=self.itemPage-1 else return end; self:RefreshItemResults() end
function AB:OpenItemBrowser(slot) self.browserSlot=slot; self.itemPage=1; self.itemSearch:SetText(""); self.itemBrowser:Show(); self:RefreshItemResults() end

function AB:RefreshItemResults()
  if not self.itemRows or not AshenDB or not AshenDB.Items then return end
  local query=string.lower(self.itemSearch:GetText() or ""); local matches={}; local i,id,r,item,armorType,weaponType; local buildLevel=self:GetBuildLevel()
  for i=1,table.getn(AshenBuildsItemOrder) do id=AshenBuildsItemOrder[i]; r=self:GetRawItem(id); if r then armorType=self:GetArmorTypeRaw(r); weaponType=self:GetWeaponTypeRaw(r); if self:NormalizeSlot(self.browserSlot,{slot=r[3]}) and (query=="" or string.find(string.lower(r[1] or ""),query,1,true) or string.find(self:GetSourceSearchText(id),query,1,true) or self:RawStatsMatch(r,query)) and (self.qualityFilter<0 or r[2]==self.qualityFilter) and (not self.usableOnly or (tonumber(r[4]) or 0)<=buildLevel) and (not self.classOnly or self:IsClassAllowedRaw(r,self.current.class)) and (self.showHidden or not self:IsHiddenRaw(r)) then table.insert(matches,id) end end end
  local per=table.getn(self.itemRows); local pages=math.max(1,math.ceil(table.getn(matches)/per)); if self.itemPage>pages then self.itemPage=pages end
  local row,c,parts,stat,value,index
  for i=1,per do index=(self.itemPage-1)*per+i; row=self.itemRows[i]; id=matches[index]; item=id and self:GetItem(id); if item then row.itemID=id; row.icon:SetTexture(item.icon); row.name:SetText(item.n.."  |cffa3abb8L"..(item.req or 0).." / i"..(item.ilvl or 0).."|r"); c=qualityColors[item.q] or qualityColors[1]; row.name:SetTextColor(c[1],c[2],c[3]); parts={}; for stat,value in pairs(item.stats or {}) do if stat~="dps" and value~=0 then table.insert(parts,(self.STAT_LABELS[stat] or stat).." +"..value) end end; local direct=self:GetDirectSourceSummary(id); if direct~="" then table.insert(parts,direct) end; row.stats:SetText(table.concat(parts,"  •  ")); row:Show() else row.itemID=nil; row:Hide() end end
  self.pageText:SetText("Page "..self.itemPage.." / "..pages.."  ("..table.getn(matches).." matches)"); if self.itemPage>1 then self.prevItem:Enable() else self.prevItem:Disable() end; if self.itemPage<pages then self.nextItem:Enable() else self.nextItem:Disable() end; local pack=AshenBuildsDBPack; self.packText:SetText((pack and pack.name or "AshenDB").." - "..(pack and pack.count or 0).." items")
end

function AB:CreateEnchantBrowser()
  local f=CreateFrame("Frame","AshenBuildsEnchantBrowser",UIParent); f:SetWidth(470); f:SetHeight(480); f:SetPoint("CENTER",UIParent,"CENTER",0,0); MakeBackdrop(f); self:SetupWindow(f); f:Hide(); self.enchantBrowser=f
  self:ApplyEmberBackground(f,10,0.5,0.5,0.4); self:AddEmberHeader(f,34); self:AddEmberWell(f,30,-82,-34,50)
  local t=f:CreateFontString(nil,"OVERLAY","GameFontNormalLarge"); t:SetPoint("TOP",f,"TOP",0,-18); t:SetText("SELECT ENCHANT"); local close=CreateFrame("Button",nil,f,"UIPanelCloseButton"); close:SetPoint("TOPRIGHT",f,"TOPRIGHT",-4,-4)
  self.enchantRows={}; local none=MakeButton(f,"Remove Enchant",150,23); none:SetPoint("TOP",f,"TOP",0,-52); none:SetScript("OnClick",function() AB:ApplyEnchant(AB.enchantSlot,0); f:Hide() end); local i
  for i=1,10 do local r=CreateFrame("Button",nil,f); r:SetWidth(390); r:SetHeight(30); r:SetPoint("TOPLEFT",f,"TOPLEFT",38,-88-(i-1)*34); r.text=r:CreateFontString(nil,"OVERLAY","GameFontHighlight"); r.text:SetAllPoints(r); r.text:SetJustifyH("LEFT"); r:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight"); r:SetScript("OnClick",function() if this.enchantID then AB:ApplyEnchant(AB.enchantSlot,this.enchantID); f:Hide() end end); self.enchantRows[i]=r end
end
function AB:OpenEnchantBrowser(slot) self.enchantSlot=slot; local matches={}; local i,id,e; for i=1,table.getn(AshenBuildsEnchantOrder) do id=AshenBuildsEnchantOrder[i]; e=AshenBuildsEnchants[id]; if e.slots[slot] then table.insert(matches,id) end end; for i=1,table.getn(self.enchantRows) do local r=self.enchantRows[i]; id=matches[i]; e=id and AshenBuildsEnchants[id]; if e then r.enchantID=id; r.text:SetText(e.n); r:Show() else r.enchantID=nil; r:Hide() end end; self.enchantBrowser:Show() end
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

function AB:GetSourceSearchText(id)
  local ss=self:GetItemSources(id); local out={}; local i,j,s
  for i=1,table.getn(ss) do s=ss[i]; for j=1,table.getn(s) do if type(s[j])=="string" then table.insert(out,string.lower(s[j])) end end end
  return table.concat(out," ")
end

function AB:RawStatsMatch(r,q)
  if q=="" then return false end; local st=r[19] or {}; local aliases={strength="str",agility="agi",stamina="sta",intellect="int",spirit="spi",crit="crit",hit="hit",healing="healing",spell="spellPower",defense="defense",dodge="dodge",parry="parry",block="block",haste="haste",armor="armor"}; local k=aliases[q]
  if k and st[k] and st[k]~=0 then return true end; return false
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
