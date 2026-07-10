--- StatForge snapshot builder: bags, bank, equipped, talents, JSON export.

StatForge = StatForge or {}
local SF = StatForge

local function jsonEscape(s)
  return tostring(s or "")
    :gsub("\\", "\\\\")
    :gsub('"', '\\"')
    :gsub("\r", "\\r")
    :gsub("\n", "\\n")
    :gsub("\t", "\\t")
end

-- ---------------------------------------------------------------------------
-- Bag API wrappers (C_Container preferred, classic globals fallback)
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

SF.NumSlots = NumSlots
SF.ItemLinkAt = ItemLinkAt

-- ---------------------------------------------------------------------------
-- Item link parser
-- item:itemId:enchantId:gem1:gem2:gem3:gem4:suffixId:uniqueId:...
-- fields[1]=item [2]=id [3]=enchant [8]=suffix (empty-field-preserving split)
-- ---------------------------------------------------------------------------
function SF.ParseItemLink(itemLink)
  if not itemLink then return nil end
  local id = tonumber(itemLink:match("|Hitem:(%d+)"))
  if not id then return nil end
  local suffixId, enchantId = 0, 0
  local itemString = itemLink:match("|H(item:[^|]+)|h")
  if itemString then
    local fields = {}
    for f in (itemString .. ":"):gmatch("([^:]*):") do
      fields[#fields + 1] = f
    end
    enchantId = tonumber(fields[3]) or 0
    suffixId = tonumber(fields[8]) or 0
  end
  return {
    itemId = id,
    itemLink = itemLink,
    suffixId = suffixId,
    enchantId = enchantId,
  }
end

-- ---------------------------------------------------------------------------
-- Tooltip scanner (random-suffix items)
-- ---------------------------------------------------------------------------
local scanTip = CreateFrame("GameTooltip", "StatForgeScanTip", nil, "GameTooltipTemplate")
scanTip:SetOwner(UIParent, "ANCHOR_NONE")

function SF.ScanTooltipLines(itemLink)
  local ok, lines = pcall(function()
    scanTip:ClearLines()
    scanTip:SetHyperlink(itemLink)
    local out = {}
    for i = 1, scanTip:NumLines() do
      local fs = _G["StatForgeScanTipTextLeft" .. i]
      local text = fs and fs:GetText()
      if text and text ~= "" then
        out[#out + 1] = text
      end
    end
    return out
  end)
  if ok then return lines end
  return nil
end

local function itemEntry(parsed, bag, slot)
  local entry = {
    bag = bag,
    slot = slot,
    itemId = parsed.itemId,
    itemLink = parsed.itemLink,
    enchantId = parsed.enchantId or 0,
    suffixId = parsed.suffixId or 0,
  }
  if parsed.suffixId and parsed.suffixId ~= 0 then
    entry.tooltip = SF.ScanTooltipLines(parsed.itemLink)
  end
  return entry
end

function SF.ScanContainers(bagList)
  local out = {}
  for _, bag in ipairs(bagList) do
    local numSlots = NumSlots(bag)
    for slot = 1, numSlots do
      local link = ItemLinkAt(bag, slot)
      if link then
        local parsed = SF.ParseItemLink(link)
        if parsed then
          out[#out + 1] = itemEntry(parsed, bag, slot)
        end
      end
    end
  end
  return out
end

-- ---------------------------------------------------------------------------
-- Bank cache
-- ---------------------------------------------------------------------------
SF.bankOpen = false

function SF.CacheBank()
  if not StatForgeDB then return end
  StatForgeDB.bankCache = StatForgeDB.bankCache or {}
  local items = SF.ScanContainers(SF.BANK_BAGS)
  if #items == 0 and StatForgeDB.bankCache[SF.CharKey()] then return end
  StatForgeDB.bankCache[SF.CharKey()] = {
    items = items,
    cachedAt = time(),
  }
end

function SF.GetBankItems()
  if SF.bankOpen then
    return SF.ScanContainers(SF.BANK_BAGS), time()
  end
  local cache = StatForgeDB and StatForgeDB.bankCache and StatForgeDB.bankCache[SF.CharKey()]
  if cache then
    return cache.items or {}, cache.cachedAt
  end
  return {}, nil
end

function SF.GetBankCachedAt()
  local cache = StatForgeDB and StatForgeDB.bankCache and StatForgeDB.bankCache[SF.CharKey()]
  return cache and cache.cachedAt or nil
end

-- ---------------------------------------------------------------------------
-- Character sheet stats
-- ---------------------------------------------------------------------------
local function BuildCharacterStats()
  local ok, out = pcall(function()
    local s = {}
    local function eff(i)
      local _, effective = UnitStat("player", i)
      return effective or 0
    end
    s.strength, s.agility, s.stamina, s.intellect, s.spirit =
      eff(1), eff(2), eff(3), eff(4), eff(5)

    s.health = UnitHealthMax("player") or 0
    if UnitPowerType("player") == 0 then
      s.mana = UnitPowerMax("player", 0) or 0
    end

    local _, effArmor = UnitArmor("player")
    s.armor = effArmor or 0

    if UnitDefense then
      local base, modifier = UnitDefense("player")
      s.defense = (base or 0) + (modifier or 0)
    end

    local apBase, apPos, apNeg = UnitAttackPower("player")
    s.attackPower = (apBase or 0) + (apPos or 0) + (apNeg or 0)
    local rapBase, rapPos, rapNeg = UnitRangedAttackPower("player")
    s.rangedAttackPower = (rapBase or 0) + (rapPos or 0) + (rapNeg or 0)

    if GetCritChance then s.meleeCrit = GetCritChance() end
    if GetRangedCritChance then s.rangedCrit = GetRangedCritChance() end
    if GetSpellCritChance then
      local best = 0
      for school = 2, 7 do
        local c = GetSpellCritChance(school)
        if c and c > best then best = c end
      end
      s.spellCrit = best
    end

    if GetDodgeChance then s.dodge = GetDodgeChance() end
    if GetParryChance then s.parry = GetParryChance() end
    if GetBlockChance then s.block = GetBlockChance() end

    if GetSpellBonusDamage then
      local best = 0
      for school = 2, 7 do
        local d = GetSpellBonusDamage(school)
        if d and d > best then best = d end
      end
      s.spellDamage = best
    end
    if GetSpellBonusHealing then s.healingBonus = GetSpellBonusHealing() end

    return s
  end)
  if ok then return out end
  return nil
end

-- ---------------------------------------------------------------------------
-- Snapshot
-- ---------------------------------------------------------------------------
function SF.BuildSnapshot()
  local ok, snap = pcall(function()
    local name, realm = UnitName("player"), GetRealmName()
    local _, class = UnitClass("player")
    local level = UnitLevel("player")
    local _, race = UnitRace("player")

    local talents = ""
    local talentPoints = {}
    local numTabs = GetNumTalentTabs() or 3
    for tab = 1, numTabs do
      local numTalents = GetNumTalents(tab) or 0
      local spent = 0
      for i = 1, numTalents do
        local ok2, rank = pcall(function()
          return select(5, GetTalentInfo(tab, i))
        end)
        local r = (ok2 and rank) or 0
        talents = talents .. ((r > 0) and "1" or "0")
        spent = spent + r
      end
      talentPoints[#talentPoints + 1] = spent
    end

    local equipped = {}
    for slot = 1, 19 do
      local link = GetInventoryItemLink("player", slot)
      if link then
        local parsed = SF.ParseItemLink(link)
        if parsed then
          local entry = {
            slot = slot,
            itemId = parsed.itemId,
            itemLink = link,
            enchantId = parsed.enchantId or 0,
            suffixId = parsed.suffixId or 0,
          }
          if parsed.suffixId ~= 0 then
            entry.tooltip = SF.ScanTooltipLines(link)
          end
          equipped[#equipped + 1] = entry
        end
      end
    end

    local bank, bankCachedAt = SF.GetBankItems()

    return {
      meta = {
        exportedAt = date("!%Y-%m-%dT%H:%M:%SZ"),
        addonVersion = SF.VERSION,
        format = SF.FORMAT,
        bankCachedAt = bankCachedAt,
      },
      character = {
        name = name,
        realm = realm,
        class = class,
        level = level,
        race = race,
        talents = talents,
        talentPoints = talentPoints,
        stats = BuildCharacterStats(),
      },
      equipped = equipped,
      bags = SF.ScanContainers(SF.PLAYER_BAGS),
      bank = bank,
    }
  end)
  if ok then return snap end
  SF.PrintError("export failed — " .. tostring(snap))
  return nil
end

-- ---------------------------------------------------------------------------
-- JSON
-- ---------------------------------------------------------------------------
local function ItemJson(item, includeBag)
  local s = "    {"
  if includeBag then
    s = s .. ('"bag": %d, '):format(item.bag or 0)
  end
  s = s .. ('"slot": %d, "itemId": %d, "itemLink": "%s", "enchantId": %d, "upgradeId": 0, "bonusIds": []')
    :format(item.slot, item.itemId, jsonEscape(item.itemLink), item.enchantId or 0)
  if item.tooltip and #item.tooltip > 0 then
    local esc = {}
    for i, line in ipairs(item.tooltip) do
      esc[i] = '"' .. jsonEscape(line) .. '"'
    end
    s = s .. ', "tooltip": [' .. table.concat(esc, ", ") .. ']'
  end
  return s .. "}"
end

local function ItemArrayJson(items, includeBag)
  local lines = {}
  for i, item in ipairs(items) do
    lines[#lines + 1] = ItemJson(item, includeBag) .. (i < #items and "," or "")
  end
  return table.concat(lines, "\n")
end

function SF.BuildJson(snap)
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
  local tp = snap.character.talentPoints
  if tp and #tp > 0 then
    local nums = {}
    for i, v in ipairs(tp) do nums[i] = tostring(v) end
    parts[#parts + 1] = ('    "talentPoints": [%s],'):format(table.concat(nums, ", "))
  end
  local st = snap.character.stats
  parts[#parts + 1] = ('    "talents": "%s"%s'):format(jsonEscape(snap.character.talents), st and "," or "")
  if st then
    local fields = {}
    local function add(key, value, isPercent)
      if value ~= nil then
        local fmt = isPercent and "%.2f" or "%d"
        fields[#fields + 1] = ('"%s": ' .. fmt):format(key, value)
      end
    end
    add("health", st.health)
    add("mana", st.mana)
    add("strength", st.strength)
    add("agility", st.agility)
    add("stamina", st.stamina)
    add("intellect", st.intellect)
    add("spirit", st.spirit)
    add("armor", st.armor)
    add("defense", st.defense)
    add("attackPower", st.attackPower)
    add("rangedAttackPower", st.rangedAttackPower)
    add("meleeCrit", st.meleeCrit, true)
    add("rangedCrit", st.rangedCrit, true)
    add("spellCrit", st.spellCrit, true)
    add("dodge", st.dodge, true)
    add("parry", st.parry, true)
    add("block", st.block, true)
    add("spellDamage", st.spellDamage)
    add("healingBonus", st.healingBonus)
    parts[#parts + 1] = '    "stats": {' .. table.concat(fields, ", ") .. '}'
  end
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

function SF.SaveExport(json)
  if not StatForgeDB then return end
  StatForgeDB.exports = StatForgeDB.exports or {}
  StatForgeDB.exports[SF.CharKey()] = json
  StatForgeDB.lastExportAt = StatForgeDB.lastExportAt or {}
  StatForgeDB.lastExportAt[SF.CharKey()] = time()
end

--- Build, save, return json (or nil on failure).
function SF.DoExport()
  local snap = SF.BuildSnapshot()
  if not snap then return nil, nil end
  local json = SF.BuildJson(snap)
  SF.SaveExport(json)
  return json, snap
end

function SF.GetLastExportAt()
  local t = StatForgeDB and StatForgeDB.lastExportAt and StatForgeDB.lastExportAt[SF.CharKey()]
  return t
end

function SF.DebugContainers()
  local version = GetBuildInfo() or "?"
  SF.Print(("container debug (client %s):"):format(tostring(version)))
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
