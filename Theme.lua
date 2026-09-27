AshenBuilds = AshenBuilds or {}
local AB = AshenBuilds

-- Ember-stone background shared with LeafVillageLegends (ab_bg_01..32).
-- The source art is 2048x1024, cut into an 8x4 grid of 256px tiles so it stays
-- within the 1.12 texture size limits.
local EMBER_PATH = "Interface\\AddOns\\AshenBuilds\\Textures\\Ember\\ab_bg_"
local EMBER_W, EMBER_H, EMBER_TILE, EMBER_COLS, EMBER_ROWS = 2048, 1024, 256, 8, 4

-- Palette. Text colors are chosen for at least 4.5:1 contrast against the
-- darkened background (effective luminance around #120f0c).
AB.THEME = {
  panelBg = {0.055, 0.045, 0.038, 0.92},
  -- Lighter panel so the sigil behind the stats area ghosts through; the art is
  -- dark enough that light text keeps better than 6:1 contrast either way.
  sheerBg = {0.055, 0.045, 0.038, 0.80},
  cardBg = {0.03, 0.025, 0.022, 0.50},
  slotBg = {0.06, 0.05, 0.042, 0.94},
  border = {0.62, 0.42, 0.22, 1},
  borderSoft = {0.42, 0.29, 0.16, 0.95},
  frameBorder = {1, 0.72, 0.48, 1},
  ember = {1, 0.45, 0.16},
  divider = {0.78, 0.5, 0.24, 0.45},
  muted = {0.74, 0.72, 0.68},
  empty = {0.64, 0.66, 0.72},
}

local function Clamp(v, lo, hi) if v < lo then return lo elseif v > hi then return hi end return v end

-- Covers the region inside `frame` (inset on every side) with the ember art,
-- cropping instead of stretching so the stone and sigil keep their proportions.
-- focusX/focusY (0..1) choose which part of the art stays visible when cropped.
function AB:ApplyEmberBackground(frame, inset, focusX, focusY, scrimAlpha)
  inset = inset or 10
  local w = frame:GetWidth() - inset * 2
  local h = frame:GetHeight() - inset * 2
  local scale = math.max(w / EMBER_W, h / EMBER_H)
  local sw, sh = w / scale, h / scale
  local sx = Clamp((focusX or 0.5) * EMBER_W - sw / 2, 0, EMBER_W - sw)
  local sy = Clamp((focusY or 0.5) * EMBER_H - sh / 2, 0, EMBER_H - sh)
  frame.emberTiles = frame.emberTiles or {}
  local row, col, i, tx, ty, x0, x1, y0, y1, tex, suffix
  for row = 1, EMBER_ROWS do
    for col = 1, EMBER_COLS do
      i = (row - 1) * EMBER_COLS + col
      tex = frame.emberTiles[i]
      tx = (col - 1) * EMBER_TILE; ty = (row - 1) * EMBER_TILE
      x0 = math.max(tx, sx); x1 = math.min(tx + EMBER_TILE, sx + sw)
      y0 = math.max(ty, sy); y1 = math.min(ty + EMBER_TILE, sy + sh)
      if x1 - x0 > 0.01 and y1 - y0 > 0.01 then
        if not tex then
          tex = frame:CreateTexture(nil, "BACKGROUND"); frame.emberTiles[i] = tex
          suffix = i < 10 and ("0" .. i) or tostring(i)
          tex:SetTexture(EMBER_PATH .. suffix)
        end
        tex:ClearAllPoints()
        tex:SetPoint("TOPLEFT", frame, "TOPLEFT", inset + (x0 - sx) * scale, -inset - (y0 - sy) * scale)
        tex:SetWidth((x1 - x0) * scale); tex:SetHeight((y1 - y0) * scale)
        tex:SetTexCoord((x0 - tx) / EMBER_TILE, (x1 - tx) / EMBER_TILE, (y0 - ty) / EMBER_TILE, (y1 - ty) / EMBER_TILE)
        tex:Show()
      elseif tex then
        tex:Hide()
      end
    end
  end

  -- Scrim keeps the art atmospheric and stops brighter ember cracks from
  -- competing with text drawn straight on the background.
  if not frame.emberScrim then
    frame.emberScrim = frame:CreateTexture(nil, "BORDER")
    frame.emberScrim:SetPoint("TOPLEFT", frame, "TOPLEFT", inset, -inset)
    frame.emberScrim:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -inset, inset)
  end
  frame.emberScrim:SetTexture(0, 0, 0, scrimAlpha or 0.30)
  frame:SetBackdropBorderColor(self.THEME.frameBorder[1], self.THEME.frameBorder[2], self.THEME.frameBorder[3], self.THEME.frameBorder[4])
end

-- Darkened header band with a glowing ember rule underneath, so titles and the
-- controls that sit directly on the art always have a solid backing.
function AB:AddEmberHeader(frame, height, inset)
  inset = inset or 10
  local band = frame:CreateTexture(nil, "BORDER")
  band:SetTexture(1, 1, 1, 1)
  band:SetGradientAlpha("VERTICAL", 0.02, 0.015, 0.01, 0.30, 0.02, 0.015, 0.01, 0.50)
  band:SetPoint("TOPLEFT", frame, "TOPLEFT", inset, -inset)
  band:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -inset, -inset)
  band:SetHeight(height)
  local e = self.THEME.ember
  local glow = frame:CreateTexture(nil, "ARTWORK")
  glow:SetTexture(1, 1, 1, 1)
  glow:SetGradientAlpha("VERTICAL", e[1], e[2], e[3], 0.22, e[1], e[2], e[3], 0)
  glow:SetPoint("BOTTOMLEFT", band, "BOTTOMLEFT", 0, 0)
  glow:SetPoint("BOTTOMRIGHT", band, "BOTTOMRIGHT", 0, 0)
  glow:SetHeight(10)
  local rule = frame:CreateTexture(nil, "ARTWORK")
  rule:SetTexture(e[1], e[2], e[3], 0.8)
  rule:SetPoint("TOPLEFT", band, "BOTTOMLEFT", 0, 0)
  rule:SetPoint("TOPRIGHT", band, "BOTTOMRIGHT", 0, 0)
  rule:SetHeight(1)
  return band
end

-- Faint ember heat rising from the bottom edge.
function AB:AddEmberFloor(frame, height, inset)
  inset = inset or 10
  local e = self.THEME.ember
  local heat = frame:CreateTexture(nil, "BORDER")
  heat:SetTexture(1, 1, 1, 1)
  heat:SetGradientAlpha("VERTICAL", e[1], e[2], e[3], 0.14, e[1], e[2], e[3], 0)
  heat:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", inset, inset)
  heat:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -inset, inset)
  heat:SetHeight(height)
  return heat
end

-- Dark inset panel for lists that would otherwise sit directly on the art.
-- Built from the frame's own textures so it always draws beneath child rows.
function AB:AddEmberWell(frame, left, top, right, bottom)
  local t = self.THEME
  local well = frame:CreateTexture(nil, "ARTWORK")
  well:SetTexture(t.panelBg[1], t.panelBg[2], t.panelBg[3], t.panelBg[4])
  well:SetPoint("TOPLEFT", frame, "TOPLEFT", left, top)
  well:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", right, bottom)
  local edges = {{"TOPLEFT", "TOPRIGHT", nil, 1}, {"BOTTOMLEFT", "BOTTOMRIGHT", nil, 1}, {"TOPLEFT", "BOTTOMLEFT", 1, nil}, {"TOPRIGHT", "BOTTOMRIGHT", 1, nil}}
  local i, edge
  for i = 1, 4 do
    edge = frame:CreateTexture(nil, "ARTWORK")
    edge:SetTexture(t.borderSoft[1], t.borderSoft[2], t.borderSoft[3], 0.8)
    edge:SetPoint(edges[i][1], well, edges[i][1], 0, 0)
    edge:SetPoint(edges[i][2], well, edges[i][2], 0, 0)
    if edges[i][3] then edge:SetWidth(edges[i][3]) else edge:SetHeight(edges[i][4]) end
  end
  return well
end

-- Button art shared with LeafVillageLegends. Files are padded to 256x64, so each
-- state carries the texcoords of its opaque region.
local BUTTON_PATH = "Interface\\AddOns\\AshenBuilds\\Textures\\Buttons\\"
local BUTTON_STYLES = {
  -- Ember-red plate for ordinary actions.
  ember = {
    normal = {"ashen_button_red", 0, 179 / 256, 0, 48 / 64},
    hover = {"ashen_button_red_hover", 0, 195 / 256, 0, 48 / 64},
    down = {"ashen_button_red_down", 0, 180 / 256, 0, 48 / 64},
  },
  -- Pointed plate for the class/race/build selectors, hinting that they cycle.
  cycle = {
    normal = {"dossier_spec_button", 9 / 256, 247 / 256, 6 / 64, 59 / 64},
    hover = {"dossier_spec_button_hover", 9 / 256, 247 / 256, 6 / 64, 59 / 64},
    down = {"dossier_spec_button_down", 9 / 256, 247 / 256, 6 / 64, 59 / 64},
  },
}

local function SetButtonState(button, setter, getter, art)
  if not button[setter] or not button[getter] then return end
  button[setter](button, BUTTON_PATH .. art[1])
  local tex = button[getter](button)
  -- UIPanelButtonTemplate's own texcoords survive a texture swap, so always reset them.
  if tex then tex:SetTexCoord(art[2], art[3], art[4], art[5]); return tex end
end

function AB:SkinButton(button, style)
  local s = BUTTON_STYLES[style or "ember"]
  SetButtonState(button, "SetNormalTexture", "GetNormalTexture", s.normal)
  SetButtonState(button, "SetPushedTexture", "GetPushedTexture", s.down)
  -- The highlight draws additively over the normal plate, so hover reads as the plate igniting.
  SetButtonState(button, "SetHighlightTexture", "GetHighlightTexture", s.hover)
  local disabled = SetButtonState(button, "SetDisabledTexture", "GetDisabledTexture", s.normal)
  if disabled then disabled:SetVertexColor(0.45, 0.45, 0.45) end
  -- Gold on the dark plate is ~10:1; hover goes white, and disabled text stays
  -- a light grey (not the template's dim grey) so it remains legible.
  if button.SetTextColor then button:SetTextColor(1, 0.82, 0.28) end
  if button.SetHighlightTextColor then button:SetHighlightTextColor(1, 1, 1) end
  if button.SetDisabledTextColor then button:SetDisabledTextColor(0.66, 0.64, 0.6) end
end

function AB:StylePanel(frame, kind)
  local t = self.THEME
  local bg = (kind == "card" and t.cardBg) or (kind == "slot" and t.slotBg) or (kind == "sheer" and t.sheerBg) or t.panelBg
  local border = kind == "card" and t.borderSoft or t.border
  frame:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", tile = true, tileSize = 16, edgeSize = kind == "card" and 8 or 12, insets = {left = 3, right = 3, top = 3, bottom = 3}})
  frame:SetBackdropColor(bg[1], bg[2], bg[3], bg[4])
  frame:SetBackdropBorderColor(border[1], border[2], border[3], border[4])
end
