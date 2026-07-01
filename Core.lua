--- StatForge: /statforge opens a copyable export panel.
--- No SavedVariables — no file writes. In-game only, ToS-safe.

local addonName = "StatForge"

local function jsonEscape(s)
  return tostring(s or "")
    :gsub("\\", "\\\\")
    :gsub('"', '\\"')
    :gsub("\n", "\\n")
    :gsub("\t", "\\t")
end

local DEBUG = false

-- ---------------------------------------------------------------------------
-- Item link parser: extracts id, bonusIds, upgradeId from itemString
-- ---------------------------------------------------------------------------
-- Compatibility wrappers for Classic Era bag APIs (some builds lack C_Container)
local GetContainerNumSlotsCompat = C_Container and C_Container.GetContainerNumSlots
  or GetContainerNumSlots
local GetContainerItemLinkCompat = C_Container and C_Container.GetContainerItemLink
  or GetContainerItemLink

local function ParseItemLink(itemLink)
  if not itemLink then return nil end
  -- Item links may be preceded by color codes; remove ^ anchor, use non-greedy
  local itemString = itemLink:match("|H(.-)|h")
  if not itemString then return nil end
  local parts = {}
  for part in itemString:gmatch("[^:]+") do
    parts[#parts + 1] = part
  end
  local id = tonumber(parts[2]) or 0
  -- Classic Era 1.15.5 itemString:
  --   parts[13] = numBonusIDs (count of subsequent bonus ID fields)
  --   bonus IDs follow immediately as individual colon-separated fields
  local bonusIds = {}
  local upgradeId = 0
  local numBonus = tonumber(parts[13]) or 0
  if numBonus > 0 and #parts >= 13 + numBonus then
    for i = 1, numBonus do
      local val = tonumber(parts[13 + i]) or 0
      bonusIds[#bonusIds + 1] = val
    end
    upgradeId = tonumber(parts[14 + numBonus]) or 0
  end
  if DEBUG then
    print("StatForge debug raw itemString: " .. itemString)
    print("StatForge debug parts count: " .. #parts .. ", numBonusIDs: " .. numBonus)
  end
  local quality = 0
  if id and id > 0 then
    quality = select(3, GetItemInfo(id)) or 0
  end
  return {
    itemId = id,
    itemLink = itemLink,
    quality = quality,
    bonusIds = bonusIds,
    upgradeId = upgradeId,
  }
end

-- ---------------------------------------------------------------------------
-- Snapshot builder: character, equipped, bags, talents
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
            bonusIds = parsed.bonusIds,
            upgradeId = parsed.upgradeId,
          }
        else
          if DEBUG then print("StatForge debug: ParseItemLink returned nil for equipped slot " .. slot .. " link = " .. tostring(link)) end
        end
      else
        if DEBUG then print("StatForge debug: equipped slot " .. slot .. " returned nil link") end
      end
    end

    -- bags
    local bags = {}
    for bag = 0, 4 do
      local numSlots = GetContainerNumSlotsCompat(bag) or 0
      if DEBUG then print("StatForge debug: bag " .. bag .. " has " .. numSlots .. " slots") end
      for slot = 1, numSlots do
        local link = GetContainerItemLinkCompat(bag, slot)
        if link then
          local parsed = ParseItemLink(link)
          if parsed then
            bags[#bags + 1] = {
              bag = bag,
              slot = slot,
              itemId = parsed.itemId,
              itemLink = link,
              bonusIds = parsed.bonusIds,
              upgradeId = parsed.upgradeId,
            }
          else
            if DEBUG then print("StatForge debug: ParseItemLink returned nil for bag " .. bag .. " slot " .. slot .. " link = " .. tostring(link)) end
          end
        else
          if DEBUG then print("StatForge debug: bag " .. bag .. " slot " .. slot .. " returned nil link") end
        end
      end
    end

    return {
      meta = {
        exportedAt = date("!%Y-%m-%dT%H:%M:%SZ"),
        addonVersion = "0.1.0",
        format = "StatForge-v1",
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
      bags = bags,
      bank = {},
    }
  end)
  if ok then return snap else
    print("|cffff0000StatForge:|r " .. tostring(snap))
    return nil
  end
end

-- ---------------------------------------------------------------------------
-- In-game copy panel
-- ---------------------------------------------------------------------------
local panel = nil

local function ShowPanel()
  if panel then
    panel:Show()
    return
  end

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

  -- Title
  local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  title:SetPoint("TOP", 0, -12)
  title:SetText("|cff33ff99StatForge|r Export")

  -- Scroll frame wrapper (must exist before EditBox)
  local scroll = CreateFrame("ScrollFrame", "StatForgeESF", panel, "UIPanelScrollFrameTemplate")
  scroll:SetPoint("TOPLEFT", 6, -30)
  scroll:SetSize(672, 425)

  -- Edit box for selectable JSON
  local eb = CreateFrame("EditBox", nil, scroll)
  eb:SetMultiLine(true)
  eb:SetPoint("TOPLEFT", scroll, "TOPLEFT", 8, -8)
  eb:SetPoint("BOTTOMRIGHT", scroll, "BOTTOMRIGHT", -8, 8)
  eb:SetMaxLetters(0)
  eb:SetTextInsets(8, 8, 8, 8)
  eb:SetAutoFocus(false)
  eb:SetFontObject("ChatFontNormal")
  eb:SetScript("OnEscapePressed", function()
    eb:ClearFocus()
    panel:Hide()
  end)
  panel:SetScript("OnHide", function()
    eb:ClearFocus()
  end)

  scroll:SetScrollChild(eb)

  -- Close button (created early so panel is always closeable)
  local close = CreateFrame("Button", nil, panel, "UIPanelCloseButton")
  close:SetPoint("TOPRIGHT", -6, -6)

  -- Build and set text
  local snap = BuildSnapshot()
  if not snap then
    panel:Hide()
    panel = nil
    return
  end
  local json = ""
  -- Simple JSON encoder without serialize()
  json = json .. "{\n"
  -- meta
  json = json .. '  "meta": {\n'
  json = json .. ('    "exportedAt": "%s",\n'):format(jsonEscape(snap.meta.exportedAt))
  json = json .. ('    "addonVersion": "%s",\n'):format(jsonEscape(snap.meta.addonVersion))
  json = json .. ('    "format": "%s"\n'):format(jsonEscape(snap.meta.format))
  json = json .. "  },\n"
  -- character
  json = json .. '  "character": {\n'
  json = json .. ('    "name": "%s",\n'):format(jsonEscape(snap.character.name))
  json = json .. ('    "realm": "%s",\n'):format(jsonEscape(snap.character.realm))
  json = json .. ('    "class": "%s",\n'):format(jsonEscape(snap.character.class))
  json = json .. ('    "level": %s,\n'):format(tostring(snap.character.level or 0))
  json = json .. ('    "race": "%s",\n'):format(jsonEscape(snap.character.race))
  json = json .. ('    "talents": "%s"\n'):format(jsonEscape(snap.character.talents))
  json = json .. "  },\n"
  -- equipped
  json = json .. ('  "equipped": [\n')
  for i, item in ipairs(snap.equipped) do
    json = json .. '    {'
    json = json .. ('"slot": %d, '):format(item.slot)
    json = json .. ('"itemId": %d, '):format(item.itemId)
    json = json .. ('"itemLink": "%s", '):format(jsonEscape(item.itemLink))
    json = json .. ('"upgradeId": %d, '):format(item.upgradeId)
    json = json .. '"bonusIds": ['
    local first = true
    for _, bid in ipairs(item.bonusIds) do
      if not first then json = json .. ", " end
      json = json .. tostring(bid)
      first = false
    end
    json = json .. "]}"
    if i < #snap.equipped then json = json .. "," end
    json = json .. "\n"
  end
  json = json .. "  ],\n"
  -- bags
  json = json .. ('  "bags": [\n')
  for i, item in ipairs(snap.bags) do
    json = json .. '    {'
    json = json .. ('"bag": %d, '):format(item.bag)
    json = json .. ('"slot": %d, '):format(item.slot)
    json = json .. ('"itemId": %d, '):format(item.itemId)
    json = json .. ('"itemLink": "%s", '):format(jsonEscape(item.itemLink))
    json = json .. ('"upgradeId": %d, '):format(item.upgradeId)
    json = json .. '"bonusIds": ['
    local first = true
    for _, bid in ipairs(item.bonusIds) do
      if not first then json = json .. ", " end
      json = json .. tostring(bid)
      first = false
    end
    json = json .. "]}"
    if i < #snap.bags then json = json .. "," end
    json = json .. "\n"
  end
  json = json .. "  ],\n"
  -- bank (empty)
  json = json .. '  "bank": []\n'
  json = json .. "}\n"

  eb:SetText(json)

  -- Focus the box and select all so Ctrl+C works immediately
  eb:HighlightText(0, json:len())
  eb:SetFocus()

  panel:Show()
end

-- ---------------------------------------------------------------------------
-- Slash commands
-- ---------------------------------------------------------------------------
function SlashCmdList.STATFORGE(msg)
  ShowPanel()
end
SLASH_STATFORGE1 = "/statforge"
SLASH_STATFORGE2 = "/sf"
