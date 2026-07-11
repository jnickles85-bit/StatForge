--- StatForge constants: version, colors, slot labels.
--- Loaded first; other files attach to the StatForge global table.

StatForge = StatForge or {}
local SF = StatForge

SF.ADDON_NAME = "StatForge"
SF.VERSION = "0.5.0"
SF.FORMAT = "StatForge-v1"

-- Brand palette (matches StatForge-App: cyan accent on near-black)
SF.Colors = {
  accent      = { 0.400, 0.988, 0.945 }, -- #66FCF1
  accentDim   = { 0.271, 0.635, 0.620 }, -- #45A29E
  bg          = { 0.043, 0.047, 0.063 }, -- #0B0C10
  surface     = { 0.075, 0.082, 0.110 }, -- #13151C
  surfaceHover= { 0.102, 0.114, 0.153 }, -- #1A1D27
  border      = { 0.137, 0.149, 0.200 }, -- #232633
  text        = { 0.886, 0.894, 0.918 }, -- #E2E4EA
  textMuted   = { 0.482, 0.506, 0.588 }, -- #7B8196
  textDim     = { 0.290, 0.314, 0.400 }, -- #4A5066
  success     = { 0.133, 0.773, 0.369 }, -- #22C55E
  warning     = { 0.961, 0.620, 0.043 }, -- #F59E0B
  danger      = { 0.937, 0.267, 0.267 }, -- #EF4444
  white       = { 1, 1, 1 },
  black       = { 0, 0, 0 },
}

SF.PLAYER_BAGS = { 0, 1, 2, 3, 4 }
-- container -1 = fixed bank slots; bags 5-11 = bank bags
SF.BANK_BAGS = { -1, 5, 6, 7, 8, 9, 10, 11 }

SF.SLOT_NAMES = {
  [1]  = "Head",
  [2]  = "Neck",
  [3]  = "Shoulder",
  [4]  = "Shirt",
  [5]  = "Chest",
  [6]  = "Waist",
  [7]  = "Legs",
  [8]  = "Feet",
  [9]  = "Wrist",
  [10] = "Hands",
  [11] = "Finger 1",
  [12] = "Finger 2",
  [13] = "Trinket 1",
  [14] = "Trinket 2",
  [15] = "Back",
  [16] = "Main Hand",
  [17] = "Off Hand",
  [18] = "Ranged",
  [19] = "Tabard",
}

-- Gear tab display order (skip shirt/tabard for setup view later)
SF.GEAR_SLOT_ORDER = { 1, 2, 3, 15, 5, 9, 10, 6, 7, 8, 11, 12, 13, 14, 16, 17, 18 }

function SF.ColorText(hex, text)
  return "|cff" .. hex .. text .. "|r"
end

function SF.Accent(text)
  return "|cff66fcf1" .. text .. "|r"
end

function SF.Print(msg)
  print(SF.Accent("StatForge:") .. " " .. tostring(msg))
end

function SF.PrintError(msg)
  print("|cffff4444StatForge:|r " .. tostring(msg))
end

function SF.CharKey()
  return (UnitName("player") or "?") .. "-" .. (GetRealmName() or "?")
end

--- Relative time string from a unix timestamp (or ISO export time via parse).
function SF.FormatAge(unixTs)
  if not unixTs or unixTs == 0 then return "never" end
  local now = time()
  local sec = now - unixTs
  if sec < 0 then sec = 0 end
  if sec < 60 then return "just now" end
  if sec < 3600 then
    local m = math.floor(sec / 60)
    return m .. (m == 1 and " minute ago" or " minutes ago")
  end
  if sec < 86400 then
    local h = math.floor(sec / 3600)
    return h .. (h == 1 and " hour ago" or " hours ago")
  end
  local d = math.floor(sec / 86400)
  return d .. (d == 1 and " day ago" or " days ago")
end

--- Parse ISO-8601 UTC "YYYY-MM-DDTHH:MM:SSZ" to unix (best-effort; Lua 5.1).
function SF.ParseIsoUtc(iso)
  if not iso or type(iso) ~= "string" then return nil end
  local y, mo, d, h, mi, s = iso:match("^(%d+)%-(%d+)%-(%d+)T(%d+):(%d+):(%d+)")
  if not y then return nil end
  -- time() is local; approximate with a rough UTC offset using date("!*t") vs date("*t")
  local t = {
    year = tonumber(y), month = tonumber(mo), day = tonumber(d),
    hour = tonumber(h), min = tonumber(mi), sec = tonumber(s),
  }
  local localGuess = time(t)
  if not localGuess then return nil end
  -- Adjust local → UTC: difference between local and UTC wall clocks at "now"
  local now = time()
  local utcNow = time(date("!*t", now))
  local localNow = time(date("*t", now))
  local offset = localNow - utcNow -- seconds to add to UTC to get local
  return localGuess + offset
end
