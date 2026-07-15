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

local function assertContains(actual, expected)
  if not tostring(actual):find(expected, 1, true) then
    error(("expected %s to contain %s"):format(tostring(actual), tostring(expected)), 2)
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
local realParseItemLink = StatForge.ParseItemLink
StatForge.NumSlots = function() return #bagLinks end
StatForge.ItemLinkAt = function(_, slot) return bagLinks[slot] end
StatForge.ParseItemLink = parseTestItemLink

test("real item-link parser preserves enchant and random suffix fields", function()
  local parsed = realParseItemLink(
    "|cff0070dd|Hitem:18820:2504:0:0:0:0:-15:12345:60:0:0:0:0|h[Talisman]|h|r"
  )
  assertEqual(parsed.itemId, 18820)
  assertEqual(parsed.enchantId, 2504)
  assertEqual(parsed.suffixId, -15)
end)

test("setup parser rejects malformed gear tokens instead of silently dropping them", function()
  time = function() return 123456 end
  local setup, err = StatForge.ParseSetupString(
    "SFSETUP1;Test;mage-frost;balanced;1=1001:0:0;not-a-slot"
  )
  assertEqual(setup, nil)
  assertEqual(err, "invalid gear slot token: not-a-slot")
end)

test("setup parser preserves setup metadata and item identity", function()
  local setup, err = StatForge.ParseSetupString(
    "SFSETUP1;Frost set;mage-frost;survival;1=1001:-15:222"
  )
  assertEqual(err, nil)
  assertEqual(setup.label, "Frost set")
  assertEqual(setup.specId, "mage-frost")
  assertEqual(setup.mode, "survival")
  assertEqual(setup.slots[1].itemId, 1001)
  assertEqual(setup.slots[1].suffixId, -15)
  assertEqual(setup.slots[1].enchantId, 222)
end)

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

test("setup matching distinguishes a wrong enchant from a missing item", function()
  bagLinks = {
    "1001:111:0",
  }
  local link, where = StatForge.FindItemForSetup({
    itemId = 1001,
    suffixId = 0,
    enchantId = 222,
  })
  assertEqual(link, nil)
  assertEqual(where, "wrongEnchant")
end)

test("closed bank cache distinguishes a wrong enchant from a matching copy", function()
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
  assertEqual(where, "wrongEnchant")
end)

test("combat lockdown blocks every equip attempt", function()
  StatForge.GEAR_SLOT_ORDER = { 1 }
  InCombatLockdown = function() return true end
  EquipItemByName = function() error("combat lockdown must block equip") end
  local message
  StatForge.PrintError = function(value) message = value end

  StatForge.EquipSetup({
    label = "Combat test",
    slots = { [1] = { itemId = 1001, suffixId = 0, enchantId = 0 } },
  })

  assertEqual(message, "can't swap gear in combat — try again after the fight.")
end)

test("equipped same-item copies with the wrong enchant are not reported missing", function()
  bagLinks = {}
  StatForgeDB.bankCache["Tester-Realm"] = nil
  StatForge.GEAR_SLOT_ORDER = { 1 }
  GetInventoryItemLink = function() return "1001:111:0" end
  InCombatLockdown = function() return false end
  EquipItemByName = function() error("wrong-enchant copy must not be equipped") end
  local message
  StatForge.Print = function(value) message = value end

  StatForge.EquipSetup({
    label = "Equipped enchant test",
    slots = {
      [1] = { itemId = 1001, suffixId = 0, enchantId = 222 },
    },
  })

  assertEqual(message, 'Equip "Equipped enchant test": 0 already on, 0 swapped, 1 wrong enchant')
end)

test("equip summary reports wrong-enchant copies separately", function()
  bagLinks = {
    "1001:111:0",
  }
  StatForge.GEAR_SLOT_ORDER = { 1 }
  GetInventoryItemLink = function() return nil end
  InCombatLockdown = function() return false end
  EquipItemByName = function() error("wrong-enchant copy must not be equipped") end
  local message
  StatForge.Print = function(value) message = value end

  StatForge.EquipSetup({
    label = "Test setup",
    slots = {
      [1] = { itemId = 1001, suffixId = 0, enchantId = 222 },
    },
  })

  assertEqual(message, 'Equip "Test setup": 0 already on, 0 swapped, 1 wrong enchant')
end)

test("empty bank scans preserve the last known non-empty cache", function()
  bagLinks = {}
  StatForgeDB.bankCache["Tester-Realm"] = {
    items = { { itemId = 1001, suffixId = 0, enchantId = 111 } },
    cachedAt = 111,
  }
  local originalScanContainers = StatForge.ScanContainers
  StatForge.ScanContainers = function() return {} end
  StatForge.CacheBank()
  local cache = StatForgeDB.bankCache["Tester-Realm"]
  StatForge.ScanContainers = originalScanContainers

  assertEqual(#cache.items, 1)
  assertEqual(cache.cachedAt, 111)
end)

test("snapshot JSON preserves suffix IDs, bank freshness, and escaped strings", function()
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
      { slot = 1, itemId = 1001, itemLink = "link\\path\"\n", enchantId = 222, suffixId = -15 },
    },
    bags = {},
    bank = {},
  })
  assertEqual(json:match('"suffixId": (%-?%d+)'), "-15")
  assertEqual(json:match('"bankCachedAt": (%d+)'), "123456")
  assertContains(json, [["itemLink": "link\\path\"\n"]])
end)

if failures > 0 then
  print(("FAIL %d of %d tests failed"):format(failures, total))
  os.exit(1)
end
print(("PASS %d tests"):format(total))
