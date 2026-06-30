--- StatForge: /statforge opens a copyable export panel.
--- No SavedVariables — no file writes. In-game only, ToS-safe.

local addonName = "StatForge"

-- ---------------------------------------------------------------------------
-- Item link parser: extracts id, bonusIds, upgradeId from itemString
-- ---------------------------------------------------------------------------
local function ParseItemLink(itemLink)
  if not itemLink then return nil end
  local itemString = itemLink:match("^|H(.+)|h")
  if not itemString then return nil end
  local parts = {}
  for part in itemString:gmatch("[^:]+") do
    parts[#parts + 1] = part
  end
  local id = tonumber(parts[2]) or 0
  local bonusStr = parts[15] or ""
  local upgradeId = tonumber(parts[16]) or 0
  local bonusIds = {}
  if bonusStr ~= "" then
    for num in bonusStr:gmatch("[^,]+") do
      bonusIds[#bonusIds + 1] = tonumber(num) or 0
    end
  end
  local quality = select(3, GetItemInfo(id)) or 0
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
  local name, realm = UnitName("player"), GetRealmName()
  local _, class = UnitClass("player")
  local level = UnitLevel("player")
  local _, race = UnitRace("player")

  -- talents: 30-char binary
  local talents = ""
  for tab = 1, GetNumTalents() do
    for i = 1, GetNumTalents(tab) do
      talents = talents .. (select(5, GetTalentInfo(tab, i)) > 0 and "1" or "0")
    end
  end

  -- equipped
  local equipped = {}
  for slot = 1, 19 do
    local link = GetInventoryItemLink("player", slot)
    if link then
      equipped[#equipped + 1] = {
        slot = slot,
        itemId = ParseItemLink(link).itemId,
        itemLink = link,
        bonusIds = ParseItemLink(link).bonusIds,
        upgradeId = ParseItemLink(link).upgradeId,
      }
    end
  end

  -- bags
  local bags = {}
  for bag = 0, 4 do
    for slot = 1, GetContainerNumSlots(bag) do
      local link = GetContainerItemLink(bag, slot)
      if link then
        bags[#bags + 1] = {
          bag = bag,
          slot = slot,
          itemId = ParseItemLink(link).itemId,
          itemLink = link,
          bonusIds = ParseItemLink(link).bonusIds,
          upgradeId = ParseItemLink(link).upgradeId,
        }
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

  -- Edit box for selectable JSON
  local eb = CreateFrame("EditBox", nil, panel)
  eb:SetMultiLine(true)
  eb:SetSize(660, 420)
  eb:SetPoint("TOP", 0, -35)
  eb:SetMaxLetters(0)
  eb:SetTextInsets(8, 8, 8, 8)
  eb:SetAutoFocus(false)
  eb:SetScript("OnEscapePressed", function()
    eb:ClearFocus()
    panel:Hide()
  end)
  panel:SetScript("OnHide", function()
    eb:ClearFocus()
  end)

  -- Scroll frame wrapper
  local scroll = CreateFrame("ScrollFrame", "StatForgeESF", panel, "UIPanelScrollFrameTemplate")
  scroll:SetPoint("TOPLEFT", 6, -30)
  scroll:SetSize(672, 425)
  scroll:SetScrollChild(eb)

  -- Build and set text
  local snap = BuildSnapshot()
  local json = ""
  -- Simple JSON encoder without serialize()
  json = json .. "{\n"
  -- meta
  json = json .. '  "meta": {\n'
  json = json .. ('    "exportedAt": "%s",\n'):format(snap.meta.exportedAt)
  json = json .. ('    "addonVersion": "%s",\n'):format(snap.meta.addonVersion)
  json = json .. ('    "format": "%s"\n'):format(snap.meta.format)
  json = json .. "  },\n"
  -- character
  json = json .. '  "character": {\n'
  json = json .. ('    "name": "%s",\n'):format(snap.character.name or "")
  json = json .. ('    "realm": "%s",\n'):format(snap.character.realm or "")
  json = json .. ('    "class": "%s",\n'):format(snap.character.class or "")
  json = json .. ('    "level": %s,\n'):format(tostring(snap.character.level or 0))
  json = json .. ('    "race": "%s",\n'):format(snap.character.race or "")
  json = json .. ('    "talents": "%s"\n'):format(snap.character.talents or "")
  json = json .. "  },\n"
  -- equipped
  json = json .. ('  "equipped": [\n')
  for i, item in ipairs(snap.equipped) do
    json = json .. '    {'
    json = json .. ('"slot": %d, '):format(item.slot)
    json = json .. ('"itemId": %d, '):format(item.itemId)
    json = json .. ('"itemLink": "%s", '):format(item.itemLink:gsub('"', '\\"'))
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
    json = json .. ('"itemLink": "%s", '):format(item.itemLink:gsub('"', '\\"'))
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

  -- Close button
  local close = CreateFrame("Button", nil, panel, "UIPanelCloseButton")
  close:SetPoint("TOPRIGHT", -6, -6)

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
