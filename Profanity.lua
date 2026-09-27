local AB = AshenBuilds

-- Profanity filter for community build names.
--  * Own names containing profanity can't be published.
--  * Names heard from other players are shown with the offending word masked
--    ("F******", "A**"), including leetspeak and spaced-out spellings.
--
-- ANYWHERE roots are long enough to be unambiguous, so they match inside other
-- text ("Fucking", "f.u.c.k", "sh1tty"). WORD roots are short and appear inside
-- ordinary words (Assassination, Class, Peacock, Grapes), so they only match as
-- a whole word, optionally with a plural/verb ending.

local ANYWHERE = {"fuck", "fuk", "fck", "shit", "cunt", "nigger", "nigga", "faggot", "bitch", "whore", "twat",
  "retard", "bastard", "dildo", "porn", "penis", "vagina", "pussy", "slut", "asshole", "motherf", "cocksuck", "jerkoff",
  "piss", "tranny"}
local WORD = {"ass", "arse", "dick", "cock", "cum", "tit", "tits", "fag", "rape", "rapist", "nazi", "kys", "sex", "boob",
  "boobs", "hoe", "coon", "wank", "kike", "spic", "chink"}
local ENDINGS = {"", "s", "es", "ed", "er", "ers", "ing"}

local LEET = {["0"] = "o", ["1"] = "i", ["!"] = "i", ["3"] = "e", ["4"] = "a", ["@"] = "a", ["5"] = "s", ["$"] = "s", ["7"] = "t", ["+"] = "t", ["8"] = "b", ["9"] = "g"}

-- Lower-cases letters and maps leetspeak, remembering where each kept character
-- came from so matches can be masked in the original text. Separators such as
-- "." "-" "_" and spaces are dropped from the squashed form so "f.u.c.k" matches.
local function Normalize(text)
  local squashed, from, words = {}, {}, {}
  local i, ch, low, n, word = 1, nil, nil, 0, nil
  for i = 1, string.len(text) do
    ch = string.sub(text, i, i); low = LEET[ch] or string.lower(ch)
    if string.find(low, "^%a$") then
      n = n + 1; squashed[n] = low; from[n] = i
      if not word then word = {start = i, text = ""}; table.insert(words, word) end
      word.text = word.text .. low; word.stop = i
    else
      -- Only whitespace ends a word; "a.s.s" is still one word.
      if string.find(ch, "^%s$") then word = nil end
    end
  end
  return table.concat(squashed), from, words
end

local function IsWordMatch(word)
  local i, j
  for i = 1, table.getn(WORD) do
    for j = 1, table.getn(ENDINGS) do
      if word == WORD[i] .. ENDINGS[j] then return true end
    end
  end
  return false
end

-- Returns a list of {first, last} character ranges in `text` that are profane.
local function FindProfanity(text)
  local squashed, from, words = Normalize(tostring(text or ""))
  local hits = {}
  local i, root, s, e
  for i = 1, table.getn(ANYWHERE) do
    root = ANYWHERE[i]; s = 1
    while true do
      s, e = string.find(squashed, root, s, true)
      if not s then break end
      table.insert(hits, {from[s], from[e]}); s = e + 1
    end
  end
  for i = 1, table.getn(words) do
    if IsWordMatch(words[i].text) then table.insert(hits, {words[i].start, words[i].stop}) end
  end
  return hits
end

function AB:IsProfane(text) return table.getn(FindProfanity(text)) > 0 end

-- Masks every profane word, keeping its first letter: "Kame Fucking Sucks Ass" -> "Kame F****** Sucks A**".
function AB:MaskProfanity(text)
  text = tostring(text or "")
  local hits = FindProfanity(text)
  if table.getn(hits) == 0 then return text end
  local mask, i, h, p = {}, nil, nil, nil
  for i = 1, table.getn(hits) do
    h = hits[i]
    -- Widen the hit to the whole word it sits in.
    local first, last = h[1], h[2]
    while first > 1 and not string.find(string.sub(text, first - 1, first - 1), "^%s$") do first = first - 1 end
    while last < string.len(text) and not string.find(string.sub(text, last + 1, last + 1), "^%s$") do last = last + 1 end
    for p = first + 1, last do mask[p] = true end
  end
  local out = {}
  for p = 1, string.len(text) do out[p] = mask[p] and "*" or string.sub(text, p, p) end
  return table.concat(out)
end
