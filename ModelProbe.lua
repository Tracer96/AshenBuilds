local AB = AshenBuilds

-- /ab model probe: shows what this client's Dressing Room actually does.
-- Server scripts (AIO) and client mods can replace DressUpItemLink, so this
-- watches every model frame and the panel functions while calling it the way
-- Atlas does, then prints each call with its frame and arguments.

local WATCHED = {"TryOn", "SetUnit", "Undress", "Dress", "SetModel", "SetCreature", "SetDisplayInfo", "SetItem", "SetItemAppearance"}
local MODEL_TYPES = {DressUpModel = true, PlayerModel = true, Model = true, TabardModel = true, CinematicModel = true}

local function Describe(v)
  if type(v) == "string" then return '"' .. v .. '"' end
  if type(v) == "table" and v.GetName then return v:GetName() or "<unnamed frame>" end
  return tostring(v)
end

local function Args(list)
  local out, i = {}, nil
  for i = 1, table.getn(list) do table.insert(out, Describe(list[i])) end
  return table.concat(out, ", ")
end

local function ModelFrames()
  local frames, f = {}, nil
  if EnumerateFrames then
    f = EnumerateFrames()
    while f do
      if f.GetObjectType and MODEL_TYPES[f:GetObjectType()] then table.insert(frames, f) end
      f = EnumerateFrames(f)
    end
  elseif DressUpModel then
    table.insert(frames, DressUpModel)
  end
  return frames
end

function AB:ProbeDressingRoom()
  local id = self.current.items.CHEST or self.current.items.HEAD or 16963
  local link = "item:" .. id .. ":0:0:0"
  local log, wrapped, i, j = {}, {}, nil, nil
  local frames = ModelFrames()

  -- Wrap the watched methods on every model frame (instance fields shadow the shared methods).
  for i = 1, table.getn(frames) do
    local f = frames[i]
    for j = 1, table.getn(WATCHED) do
      local name = WATCHED[j]
      local original = f[name]
      if type(original) == "function" then
        f[name] = function(self, a1, a2, a3, a4)
          table.insert(log, Describe(self) .. ":" .. name .. "(" .. Args({a1, a2, a3, a4}) .. ")")
          return original(self, a1, a2, a3, a4)
        end
        table.insert(wrapped, {f, name})
      end
    end
  end
  local oldShow = ShowUIPanel
  if oldShow then ShowUIPanel = function(frame, a2) table.insert(log, "ShowUIPanel(" .. Describe(frame) .. ")"); return oldShow(frame, a2) end end

  self.Print("Model probe: " .. table.getn(frames) .. " model frames watched. DressUpItemLink is a " .. type(DressUpItemLink) .. ".")
  self:ReturnModel()
  local ok, err = pcall(function() DressUpItemLink(link) end)

  for i = 1, table.getn(wrapped) do wrapped[i][1][wrapped[i][2]] = nil end
  ShowUIPanel = oldShow

  if not ok then self.Print("DressUpItemLink(" .. link .. ") raised: " .. tostring(err)) end
  if table.getn(log) == 0 then self.Print("DressUpItemLink(" .. link .. ") made no model calls.") end
  for i = 1, table.getn(log) do self.Print("  " .. i .. ". " .. log[i]) end
  self.Print("Please screenshot these lines. The Dressing Room should now be showing that item.")
end
