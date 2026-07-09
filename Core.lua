--- StatForge: /statforge (or /sf) opens a copyable export panel.
--- Bank contents are cached to SavedVariables (StatForgeDB) whenever you
--- visit the bank, so exports include bank items even away from the banker.

local addonName = "StatForge"
local ADDON_VERSION = "0.2.0"

local function jsonEscape(s)
  return tostring(s or "")
    :gsub("\\", "\\\\")
    :gsub('"', '\\"')
    :gsub("\r", "\\r")
    :gsub("\n", "\\n")
    :gsub("\t", "\\t")
end

-- ---------------------------------------------------------------------------
-- Compatibility wrappers for Classic Era bag APIs.
-- Dual-path: prefer C_Container, but fall back to the classic globals PER BAG
-- if the namespaced API returns nothing (some Era builds answer 0 slots for
-- bags 1-4 through one path but not the other).
-- ---------------------------------------------------------------------------
local function NumSlots(bag)
  local n = 0
  if C_Container and C_Container.GetContainerNumSlots then
    n = C_Container.GetContainerNumSlots(bag) or 0
  end
  if n == 0 and _G.GetContainerNumSlots then
    n = _G.GetContainerNumSlots(bag) or 0
  end
  return n
end

local function ItemLinkAt(bag, slot)
  local link
  if C_Container and C_Container.GetContainerItemLink then
    link = C_Container.GetContainerItemLink(bag, slot)
  end
  if not link and _G.GetContainerItemLink then
    link = _G.GetContainerItemLink(bag, slot)
  end
  return link
end

local function CharKey()
  return (UnitName("player") or "?") .. "-" .. (GetRealmName() or "?")
end

-- ---------------------------------------------------------------------------
-- Item link parser
-- Classic Era items carry no bonus IDs or upgrade IDs, so the item ID is all
-- we need. (The old field-splitting parser used gmatch("[^:]+"), which skips
-- empty fields and shifts every index — it read garbage on real links.)
-- ---------------------------------------------------------------------------
local function ParseItemLink(itemLink)
  if not itemLink then return nil end
  local id = tonumber(itemLink:match("|Hitem:(%d+)"))
  if not id then return nil end
  return { itemId = id, itemLink = itemLink }
end

-- ---------------------------------------------------------------------------
-- Container scanning
-- ---------------------------------------------------------------------------
local function ScanContainers(bagList)
  local out = {}
  for _, bag in ipairs(bagList) do
    local numSlots = NumSlots(bag)
    for slot = 1, numSlots do
      local link = ItemLinkAt(bag, slot)
      if link then
        local parsed = ParseItemLink(link)
        if parsed then
          out[#out + 1] = {
            bag = bag,
            slot = slot,
            itemId = parsed.itemId,
            itemLink = link,
          }
        end
      end
    end
  end
  return out
end

local PLAYER_BAGS = { 0, 1, 2, 3, 4 }
-- container -1 holds the fixed bank slots; bags 5-11 are bank bags
local BANK_BAGS = { -1, 5, 6, 7, 8, 9, 10, 11 }

local bankOpen = false

local function CacheBank()
  if not StatForgeDB then return end
  StatForgeDB.bankCache = StatForgeDB.bankCache or {}
  local items = ScanContainers(BANK_BAGS)
  -- An empty scan usually means the bank data is no longer readable (e.g.
  -- BANKFRAME_CLOSED fired late) — don't clobber a good cache with nothing.
  if #items == 0 and StatForgeDB.bankCache[CharKey()] then return end
  StatForgeDB.bankCache[CharKey()] = {
    items = items,
    cachedAt = time(),
  }
end

-- Live scan while the bank is open; otherwise fall back to the cached copy
-- from the last bank visit.
local function GetBankItems()
  if bankOpen then
    return ScanContainers(BANK_BAGS), time()
  end
  local cache = StatForgeDB and StatForgeDB.bankCache
    and StatForgeDB.bankCache[CharKey()]
  if cache then
    return cache.items or {}, cache.cachedAt
  end
  return {}, nil
end

-- ---------------------------------------------------------------------------
-- Snapshot builder: character, equipped, bags, bank, talents
-- ---------------------------------------------------------------------------
local function BuildSnapshot()
  local ok, snap = pcall(function()
    local name, realm = UnitName("player"), GetRealmName()
    local _, class = UnitClass("player")
    local level = UnitLevel("player")
    local _, race = UnitRace("player")

    -- talents: binary string (1/0 per talent point spent)
    local talents = ""
    local numTabs = GetNumTalentTabs() or 3
    for tab = 1, numTabs do
      local numTalents = GetNumTalents(tab) or 0
      for i = 1, numTalents do
        local ok2, rank = pcall(function()
          return select(5, GetTalentInfo(tab, i))
        end)
        talents = talents .. ((ok2 and rank and rank > 0) and "1" or "0")
      end
    end

    -- equipped
    local equipped = {}
    for slot = 1, 19 do
      local link = GetInventoryItemLink("player", slot)
      if link then
        local parsed = ParseItemLink(link)
        if parsed then
          equipped[#equipped + 1] = {
            slot = slot,
            itemId = parsed.itemId,
            itemLink = link,
          }
        end
      end
    end

    local bank, bankCachedAt = GetBankItems()

    return {
      meta = {
        exportedAt = date("!%Y-%m-%dT%H:%M:%SZ"),
        addonVersion = ADDON_VERSION,
        format = "StatForge-v1",
        bankCachedAt = bankCachedAt,
      },
      character = {
        name = name,
        realm = realm,
        class = class,
        level = level,
        race = race,
        talents = talents,
      },
      equipped = equipped,
      bags = ScanContainers(PLAYER_BAGS),
      bank = bank,
    }
  end)
  if ok then return snap end
  print("|cffff0000StatForge:|r export failed — " .. tostring(snap))
  return nil
end

-- ---------------------------------------------------------------------------
-- JSON encoding
-- ---------------------------------------------------------------------------
local function ItemJson(item, includeBag)
  local s = "    {"
  if includeBag then
    s = s .. ('"bag": %d, '):format(item.bag)
  end
  -- upgradeId/bonusIds kept as constants for StatForge-v1 format compatibility
  s = s .. ('"slot": %d, "itemId": %d, "itemLink": "%s", "upgradeId": 0, "bonusIds": []}')
    :format(item.slot, item.itemId, jsonEscape(item.itemLink))
  return s
end

local function ItemArrayJson(items, includeBag)
  local lines = {}
  for i, item in ipairs(items) do
    lines[#lines + 1] = ItemJson(item, includeBag) .. (i < #items and "," or "")
  end
  return table.concat(lines, "\n")
end

local function BuildJson(snap)
  local parts = {}
  parts[#parts + 1] = "{"
  parts[#parts + 1] = '  "meta": {'
  parts[#parts + 1] = ('    "exportedAt": "%s",'):format(jsonEscape(snap.meta.exportedAt))
  parts[#parts + 1] = ('    "addonVersion": "%s",'):format(jsonEscape(snap.meta.addonVersion))
  if snap.meta.bankCachedAt then
    parts[#parts + 1] = ('    "bankCachedAt": %d,'):format(snap.meta.bankCachedAt)
  end
  parts[#parts + 1] = ('    "format": "%s"'):format(jsonEscape(snap.meta.format))
  parts[#parts + 1] = "  },"
  parts[#parts + 1] = '  "character": {'
  parts[#parts + 1] = ('    "name": "%s",'):format(jsonEscape(snap.character.name))
  parts[#parts + 1] = ('    "realm": "%s",'):format(jsonEscape(snap.character.realm))
  parts[#parts + 1] = ('    "class": "%s",'):format(jsonEscape(snap.character.class))
  parts[#parts + 1] = ('    "level": %d,'):format(snap.character.level or 0)
  parts[#parts + 1] = ('    "race": "%s",'):format(jsonEscape(snap.character.race))
  parts[#parts + 1] = ('    "talents": "%s"'):format(jsonEscape(snap.character.talents))
  parts[#parts + 1] = "  },"
  parts[#parts + 1] = '  "equipped": ['
  parts[#parts + 1] = ItemArrayJson(snap.equipped, false)
  parts[#parts + 1] = "  ],"
  parts[#parts + 1] = '  "bags": ['
  parts[#parts + 1] = ItemArrayJson(snap.bags, true)
  parts[#parts + 1] = "  ],"
  parts[#parts + 1] = '  "bank": ['
  parts[#parts + 1] = ItemArrayJson(snap.bank, true)
  parts[#parts + 1] = "  ]"
  parts[#parts + 1] = "}"
  return table.concat(parts, "\n")
end

-- ---------------------------------------------------------------------------
-- In-game copy panel (created once, refreshed on every open)
-- ---------------------------------------------------------------------------
local panel, editBox

local function EnsurePanel()
  if panel then return end

  panel = CreateFrame("Frame", "StatForgeExportPanel", UIParent, "BackdropTemplate")
  panel:SetSize(700, 500)
  panel:SetPoint("CENTER")
  panel:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true,
    tileSize = 32,
    edgeSize = 32,
    insets = { left = 8, right = 8, top = 8, bottom = 8 },
  })
  panel:SetBackdropColor(0, 0, 0, 0.9)
  panel:SetMovable(true)
  panel:EnableMouse(true)
  panel:RegisterForDrag("LeftButton")
  panel:SetScript("OnDragStart", panel.StartMoving)
  panel:SetScript("OnDragStop", panel.StopMovingOrSizing)

  -- standard ESC-to-close behavior
  tinsert(UISpecialFrames, "StatForgeExportPanel")

  local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  title:SetPoint("TOP", 0, -12)
  title:SetText("|cff33ff99StatForge|r Export")

  local scroll = CreateFrame("ScrollFrame", "StatForgeESF", panel, "UIPanelScrollFrameTemplate")
  scroll:SetPoint("TOPLEFT", 6, -30)
  scroll:SetSize(672, 425)

  editBox = CreateFrame("EditBox", nil, scroll)
  editBox:SetMultiLine(true)
  editBox:SetWidth(656)
  editBox:SetPoint("TOPLEFT", scroll, "TOPLEFT", 8, -8)
  editBox:SetMaxLetters(0)
  editBox:SetTextInsets(8, 8, 8, 8)
  editBox:SetAutoFocus(false)
  editBox:SetFontObject("ChatFontNormal")
  editBox:SetScript("OnEscapePressed", function()
    editBox:ClearFocus()
    panel:Hide()
  end)
  panel:SetScript("OnHide", function()
    editBox:ClearFocus()
  end)

  scroll:SetScrollChild(editBox)

  local close = CreateFrame("Button", nil, panel, "UIPanelCloseButton")
  close:SetPoint("TOPRIGHT", -6, -6)
end

-- Persist the export in SavedVariables so the StatForge desktop app can
-- auto-import it from WTF/.../SavedVariables/StatForge.lua. The file is only
-- written to disk on /reload or logout.
local function SaveExport(json)
  if not StatForgeDB then return end
  StatForgeDB.exports = StatForgeDB.exports or {}
  StatForgeDB.exports[CharKey()] = json
end

local function ShowPanel()
  -- Build a fresh snapshot on every open (the old code built it once and
  -- showed stale data on every subsequent /sf until a /reload).
  local snap = BuildSnapshot()
  if not snap then return end

  EnsurePanel()
  local json = BuildJson(snap)
  SaveExport(json)
  editBox:SetText(json)
  panel:Show()
  editBox:HighlightText(0, #json)
  editBox:SetFocus()
  print("|cff33ff99StatForge:|r export ready — copy it, or just /reload and the desktop app will pick it up.")
end

-- ---------------------------------------------------------------------------
-- Events: SavedVariables init + bank caching
-- ---------------------------------------------------------------------------
local events = CreateFrame("Frame")
events:RegisterEvent("ADDON_LOADED")
events:RegisterEvent("BANKFRAME_OPENED")
events:RegisterEvent("BANKFRAME_CLOSED")
events:RegisterEvent("PLAYER_LOGOUT")
events:SetScript("OnEvent", function(_, event, arg1)
  if event == "ADDON_LOADED" and arg1 == addonName then
    StatForgeDB = StatForgeDB or {}
    StatForgeDB.bankCache = StatForgeDB.bankCache or {}
    StatForgeDB.exports = StatForgeDB.exports or {}
  elseif event == "BANKFRAME_OPENED" then
    bankOpen = true
    CacheBank()
  elseif event == "BANKFRAME_CLOSED" then
    -- capture final state (deposits/withdrawals made while open)
    CacheBank()
    bankOpen = false
  elseif event == "PLAYER_LOGOUT" then
    -- Auto-export on logout so the desktop app always sees current gear,
    -- even if the player never typed /sf this session.
    pcall(function()
      local snap = BuildSnapshot()
      if snap then SaveExport(BuildJson(snap)) end
    end) -- errors intentionally swallowed — never block logout
  end
end)

-- ---------------------------------------------------------------------------
-- Debug: /sf debug prints what each container API reports per bag
-- ---------------------------------------------------------------------------
local function DebugContainers()
  local version = GetBuildInfo() or "?"
  print(("|cff33ff99StatForge|r container debug (client %s):"):format(tostring(version)))
  for bag = -2, 11 do
    local viaC = "n/a"
    if C_Container and C_Container.GetContainerNumSlots then
      viaC = tostring(C_Container.GetContainerNumSlots(bag))
    end
    local viaG = "n/a"
    if _G.GetContainerNumSlots then
      viaG = tostring(_G.GetContainerNumSlots(bag))
    end
    local link = ItemLinkAt(bag, 1)
    print(("  bag %d: C_Container=%s global=%s slot1Link=%s"):format(
      bag, viaC, viaG, link and "yes" or "nil"))
  end
end

-- ---------------------------------------------------------------------------
-- Slash commands
-- ---------------------------------------------------------------------------
function SlashCmdList.STATFORGE(msg)
  local arg = (msg or ""):match("^%s*(.-)%s*$"):lower()
  if arg == "debug" then
    DebugContainers()
    return
  end
  ShowPanel()
end
SLASH_STATFORGE1 = "/statforge"
SLASH_STATFORGE2 = "/sf"
