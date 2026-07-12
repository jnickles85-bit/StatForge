local failures = 0
local total = 0

local function test(name, fn)
  total = total + 1
  local ok, err = pcall(fn)
  if ok then
    print("PASS " .. name)
  else
    failures = failures + 1
    print("FAIL " .. name .. ": " .. tostring(err))
  end
end

local function assertEqual(actual, expected)
  if actual ~= expected then
    error(("expected %s, got %s"):format(tostring(expected), tostring(actual)), 2)
  end
end

StatForgeDB = { bankCache = {} }
StatForge = {
  Colors = {},
  PLAYER_BAGS = { 0 },
  BANK_BAGS = {},
  GEAR_SLOT_ORDER = {},
  SLOT_NAMES = {},
  RegisterTab = function() end,
  CharKey = function() return "Tester-Realm" end,
  ParseItemLink = function(link)
    local itemId, enchantId, suffixId = link:match("^(%d+):(%-?%d+):(%-?%d+)$")
    return {
      itemId = tonumber(itemId),
      enchantId = tonumber(enchantId),
      suffixId = tonumber(suffixId),
    }
  end,
}

UIParent = {}
CreateFrame = function()
  return {
    SetOwner = function() end,
    ClearLines = function() end,
    SetHyperlink = function() end,
    NumLines = function() return 0 end,
  }
end

local function parseTestItemLink(link)
  local itemId, enchantId, suffixId = link:match("^(%d+):(%-?%d+):(%-?%d+)$")
  return itemId and {
    itemId = tonumber(itemId),
    enchantId = tonumber(enchantId),
    suffixId = tonumber(suffixId),
  } or nil
end

local bagLinks = {}
StatForge.NumSlots = function() return #bagLinks end
StatForge.ItemLinkAt = function(_, slot) return bagLinks[slot] end
StatForge.ParseItemLink = parseTestItemLink

dofile("GearTab.lua")
dofile("Snapshot.lua")
StatForge.NumSlots = function() return #bagLinks end
StatForge.ItemLinkAt = function(_, slot) return bagLinks[slot] end
StatForge.ParseItemLink = parseTestItemLink

test("setup matching selects the copy with the requested enchant", function()
  bagLinks = {
    "1001:111:0",
    "1001:222:0",
  }
  local link, where = StatForge.FindItemForSetup({
    itemId = 1001,
    suffixId = 0,
    enchantId = 222,
  })
  assertEqual(link, "1001:222:0")
  assertEqual(where, "bags")
end)

test("closed bank cache only reports a matching enchant", function()
  bagLinks = {}
  StatForgeDB.bankCache["Tester-Realm"] = {
    items = {
      { itemId = 1001, suffixId = 0, enchantId = 111 },
    },
  }
  local link, where = StatForge.FindItemForSetup({
    itemId = 1001,
    suffixId = 0,
    enchantId = 222,
  })
  assertEqual(link, nil)
  assertEqual(where, nil)
end)

test("snapshot JSON preserves suffix IDs and bank cache freshness", function()
  local json = StatForge.BuildJson({
    meta = {
      exportedAt = "2026-07-11T00:00:00Z",
      addonVersion = "0.5.0",
      format = "StatForge-v1",
      bankCachedAt = 123456,
    },
    character = {
      name = "Tester",
      realm = "Realm",
      class = "MAGE",
      level = 17,
      race = "Troll",
      talents = "",
    },
    equipped = {
      { slot = 1, itemId = 1001, itemLink = "link", enchantId = 222, suffixId = -15 },
    },
    bags = {},
    bank = {},
  })
  assertEqual(json:match('"suffixId": (%-?%d+)'), "-15")
  assertEqual(json:match('"bankCachedAt": (%d+)'), "123456")
end)

if failures > 0 then
  print(("FAIL %d of %d tests failed"):format(failures, total))
  os.exit(1)
end
print(("PASS %d tests"):format(total))
