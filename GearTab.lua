--- StatForge Gear tab: import setups from the desktop app, compare, equip.
--- Setup string format (produced by the app's "Send to Addon" button):
---   SFSETUP1;<label>;<specId>;<mode>;<slot>=<itemId>:<suffixId>:<enchantId>;...

StatForge = StatForge or {}
local SF = StatForge
local C = SF.Colors

-- ---------------------------------------------------------------------------
-- Setup storage & parsing
-- ---------------------------------------------------------------------------
function SF.GetSetups()
  if not StatForgeDB then return {} end
  StatForgeDB.gearSetups = StatForgeDB.gearSetups or {}
  local key = SF.CharKey()
  StatForgeDB.gearSetups[key] = StatForgeDB.gearSetups[key] or {}
  return StatForgeDB.gearSetups[key]
end

function SF.ParseSetupString(s)
  s = tostring(s or ""):gsub("[\r\n]", ";"):match("^%s*(.-)%s*$")
  local parts = {}
  for tok in (s .. ";"):gmatch("([^;]*);") do
    parts[#parts + 1] = tok
  end
  if parts[1] ~= "SFSETUP1" then
    return nil, "not a StatForge setup string (should start with SFSETUP1)"
  end
  local setup = {
    label = (parts[2] and parts[2] ~= "") and parts[2] or "Imported setup",
    specId = parts[3] or "",
    mode = parts[4] or "",
    importedAt = time(),
    slots = {},
  }
  local n = 0
  for i = 5, #parts do
    local slot, item, suffix, ench = parts[i]:match("^(%d+)=(%-?%d+):(%-?%d+):(%-?%d+)$")
    if slot then
      setup.slots[tonumber(slot)] = {
        itemId = tonumber(item),
        suffixId = tonumber(suffix) or 0,
        enchantId = tonumber(ench) or 0,
      }
      n = n + 1
    end
  end
  if n == 0 then return nil, "no gear slots found in the string" end
  return setup
end

-- ---------------------------------------------------------------------------
-- Item matching: itemId always, suffixId/enchantId when the setup specifies them
-- ---------------------------------------------------------------------------
local function linkMatches(link, want)
  local p = SF.ParseItemLink(link)
  if not p or p.itemId ~= want.itemId then return false end
  if want.suffixId and want.suffixId ~= 0 and p.suffixId ~= want.suffixId then
    return false
  end
  if want.enchantId and want.enchantId ~= 0 and p.enchantId ~= want.enchantId then
    return false
  end
  return true
end

--- Returns link, where ("bags"|"bank"|"bankClosed"|nil).
function SF.FindItemForSetup(want)
  for _, bag in ipairs(SF.PLAYER_BAGS) do
    for slot = 1, SF.NumSlots(bag) do
      local link = SF.ItemLinkAt(bag, slot)
      if link and linkMatches(link, want) then
        return link, "bags"
      end
    end
  end
  if SF.bankOpen then
    for _, bag in ipairs(SF.BANK_BAGS) do
      for slot = 1, SF.NumSlots(bag) do
        local link = SF.ItemLinkAt(bag, slot)
        if link and linkMatches(link, want) then
          return link, "bank"
        end
      end
    end
  else
    local cache = StatForgeDB and StatForgeDB.bankCache and StatForgeDB.bankCache[SF.CharKey()]
    if cache and cache.items then
      for _, it in ipairs(cache.items) do
        if it.itemId == want.itemId
          and (not want.suffixId or want.suffixId == 0 or (it.suffixId or 0) == want.suffixId)
          and (not want.enchantId or want.enchantId == 0 or (it.enchantId or 0) == want.enchantId) then
          return nil, "bankClosed"
        end
      end
    end
  end
  return nil, nil
end

local function equippedMatches(slotId, want)
  local link = GetInventoryItemLink("player", slotId)
  if not link then return false end
  return linkMatches(link, want)
end

-- ---------------------------------------------------------------------------
-- Equip (out of combat only; bank items only while the bank is open)
-- ---------------------------------------------------------------------------
function SF.EquipSetup(setup)
  if InCombatLockdown and InCombatLockdown() then
    SF.PrintError("can't swap gear in combat — try again after the fight.")
    return
  end
  local alreadyOn, swapped = 0, 0
  local inBank, missing = 0, 0
  for _, slotId in ipairs(SF.GEAR_SLOT_ORDER) do
    local want = setup.slots[slotId]
    if want then
      if equippedMatches(slotId, want) then
        alreadyOn = alreadyOn + 1
      else
        local link, where = SF.FindItemForSetup(want)
        if link then
          EquipItemByName(link, slotId)
          swapped = swapped + 1
        elseif where == "bankClosed" then
          inBank = inBank + 1
        else
          missing = missing + 1
        end
      end
    end
  end
  local msg = ('Equip "%s": %d already on, %d swapped'):format(setup.label, alreadyOn, swapped)
  if inBank > 0 then msg = msg .. (", %d in bank — visit a banker"):format(inBank) end
  if missing > 0 then msg = msg .. (", %d not found"):format(missing) end
  SF.Print(msg)
end

-- ---------------------------------------------------------------------------
-- Import modal
-- ---------------------------------------------------------------------------
local importModal

local function showImportModal(onImported)
  if importModal then
    importModal:Show()
    importModal.errLabel:SetText("")
    importModal.editBox:SetText("")
    importModal.editBox:SetFocus()
    return
  end

  local parent = _G["StatForgeMainFrame"]
  if not parent then return end

  local cover = CreateFrame("Frame", nil, parent, "BackdropTemplate")
  cover:SetAllPoints(parent)
  cover:SetFrameLevel(parent:GetFrameLevel() + 60)
  cover:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8" })
  cover:SetBackdropColor(0, 0, 0, 0.8)
  cover:EnableMouse(true)

  local panel = CreateFrame("Frame", nil, cover, "BackdropTemplate")
  panel:SetSize(560, 260)
  panel:SetPoint("CENTER")
  panel:SetBackdrop({
    bgFile = "Interface\\Buttons\\WHITE8x8",
    edgeFile = "Interface\\Buttons\\WHITE8x8",
    edgeSize = 1,
    insets = { left = 1, right = 1, top = 1, bottom = 1 },
  })
  panel:SetBackdropColor(C.surface[1], C.surface[2], C.surface[3], 1)
  panel:SetBackdropBorderColor(C.accent[1], C.accent[2], C.accent[3], 0.6)

  local h = SF.UI_CreateLabel(panel, SF.Accent("Import setup"), "GameFontNormalLarge")
  h:SetPoint("TOP", 0, -18)

  local hint = SF.UI_CreateLabel(panel,
    'In the desktop app: Upgrades tab → "Send to Addon", then paste here (Ctrl+V).',
    "GameFontHighlightSmall")
  hint:SetPoint("TOP", h, "BOTTOM", 0, -8)
  hint:SetTextColor(C.textMuted[1], C.textMuted[2], C.textMuted[3])

  local box = CreateFrame("Frame", nil, panel, "BackdropTemplate")
  box:SetPoint("TOPLEFT", 20, -70)
  box:SetPoint("TOPRIGHT", -20, -70)
  box:SetHeight(90)
  box:SetBackdrop({
    bgFile = "Interface\\Buttons\\WHITE8x8",
    edgeFile = "Interface\\Buttons\\WHITE8x8",
    edgeSize = 1,
    insets = { left = 1, right = 1, top = 1, bottom = 1 },
  })
  box:SetBackdropColor(C.bg[1], C.bg[2], C.bg[3], 1)
  box:SetBackdropBorderColor(C.border[1], C.border[2], C.border[3], 1)

  local scroll = CreateFrame("ScrollFrame", "StatForgeImportScroll", box, "UIPanelScrollFrameTemplate")
  scroll:SetPoint("TOPLEFT", 6, -6)
  scroll:SetPoint("BOTTOMRIGHT", -26, 6)

  local edit = CreateFrame("EditBox", nil, scroll)
  edit:SetMultiLine(true)
  edit:SetFontObject("ChatFontNormal")
  edit:SetWidth(480)
  edit:SetAutoFocus(true)
  edit:SetMaxLetters(0)
  edit:SetScript("OnEscapePressed", function() cover:Hide() end)
  scroll:SetScrollChild(edit)

  local errLabel = SF.UI_CreateLabel(panel, "", "GameFontHighlightSmall")
  errLabel:SetPoint("TOPLEFT", box, "BOTTOMLEFT", 0, -8)
  errLabel:SetWidth(520)
  errLabel:SetTextColor(C.danger[1], C.danger[2], C.danger[3])

  local importBtn = SF.UI_CreateButton(panel, "Import", 120, 30)
  importBtn:SetPoint("BOTTOMRIGHT", -20, 16)
  importBtn:SetPrimary(true)
  importBtn:SetScript("OnClick", function()
    local setup, err = SF.ParseSetupString(edit:GetText())
    if not setup then
      errLabel:SetText(err or "could not parse the setup string")
      return
    end
    local setups = SF.GetSetups()
    setups[#setups + 1] = setup
    cover:Hide()
    SF.Print(('imported setup "%s"'):format(setup.label))
    if onImported then onImported(#setups) end
  end)

  local cancelBtn = SF.UI_CreateButton(panel, "Cancel", 100, 30)
  cancelBtn:SetPoint("RIGHT", importBtn, "LEFT", -10, 0)
  cancelBtn:SetScript("OnClick", function() cover:Hide() end)

  cover.editBox = edit
  cover.errLabel = errLabel
  importModal = cover
end

-- ---------------------------------------------------------------------------
-- Rendering
-- ---------------------------------------------------------------------------
local selectedIdx = nil

local function itemDisplayName(want)
  local name, _, quality = GetItemInfo(want.itemId)
  if not name then
    -- not in the client cache yet — request it via a lightweight query
    return ("Item %d"):format(want.itemId), nil
  end
  return name, quality
end

local QUALITY_HEX = {
  [0] = "9d9d9d", [1] = "ffffff", [2] = "1eff00",
  [3] = "0070dd", [4] = "a335ee", [5] = "ff8000",
}

local function render(parent)
  local title = SF.UI_CreateLabel(parent, "Gear setups", "GameFontNormalLarge")
  title:SetPoint("TOPLEFT", 20, -18)
  title:SetTextColor(C.accent[1], C.accent[2], C.accent[3])

  local setups = SF.GetSetups()
  if selectedIdx == nil or selectedIdx > #setups then
    selectedIdx = #setups > 0 and #setups or nil
  end

  local importBtn = SF.UI_CreateButton(parent, "Import setup", 130, 30)
  importBtn:SetPoint("TOPRIGHT", -20, -16)
  importBtn:SetPrimary(true)
  importBtn:SetScript("OnClick", function()
    showImportModal(function(newIdx)
      selectedIdx = newIdx
      SF.RefreshActiveTab()
    end)
  end)

  if #setups == 0 then
    local body = SF.UI_CreateLabel(parent, "", "GameFontHighlight")
    body:SetPoint("TOPLEFT", 20, -70)
    body:SetWidth(840)
    body:SetJustifyH("LEFT")
    body:SetText(
      "No setups imported yet.\n\n" ..
      "|cff66fcf11.|r  In the desktop app, open the |cffffffffUpgrades|r tab.\n" ..
      "|cff66fcf12.|r  Click |cffffffffSend to Addon|r — the recommended set is copied.\n" ..
      "|cff66fcf13.|r  Click |cffffffffImport setup|r here and paste (Ctrl+V).\n" ..
      "|cff66fcf14.|r  Review the list, then |cff22c55eEquip|r — done."
    )
    body:SetTextColor(C.textMuted[1], C.textMuted[2], C.textMuted[3])
    return
  end

  -- setup selector row
  local x = 20
  for i, setup in ipairs(setups) do
    local b = SF.UI_CreateButton(parent, setup.label, math.min(220, 40 + #setup.label * 7), 26)
    b:SetPoint("TOPLEFT", x, -54)
    x = x + b:GetWidth() + 8
    if i == selectedIdx then b:SetPrimary(true) end
    b:SetScript("OnClick", function()
      selectedIdx = i
      SF.RefreshActiveTab()
    end)
  end

  local setup = setups[selectedIdx]
  if not setup then return end

  -- actions for the selected setup
  local equipBtn = SF.UI_CreateButton(parent, "Equip this setup", 150, 30)
  equipBtn:SetPoint("TOPLEFT", 20, -92)
  equipBtn:SetSuccess(true)
  equipBtn:SetScript("OnClick", function()
    SF.EquipSetup(setup)
    SF.RefreshActiveTab()
  end)

  local deleteBtn = SF.UI_CreateButton(parent, "Delete", 80, 30)
  deleteBtn:SetPoint("LEFT", equipBtn, "RIGHT", 10, 0)
  deleteBtn:SetScript("OnClick", function()
    table.remove(setups, selectedIdx)
    selectedIdx = #setups > 0 and math.min(selectedIdx, #setups) or nil
    SF.RefreshActiveTab()
  end)

  local meta = SF.UI_CreateLabel(parent,
    ("%s · %s · imported %s"):format(setup.specId, setup.mode, SF.FormatAge(setup.importedAt)),
    "GameFontHighlightSmall")
  meta:SetPoint("LEFT", deleteBtn, "RIGHT", 14, 0)
  meta:SetTextColor(C.textDim[1], C.textDim[2], C.textDim[3])

  -- slot list
  local card = CreateFrame("Frame", nil, parent, "BackdropTemplate")
  card:SetPoint("TOPLEFT", equipBtn, "BOTTOMLEFT", 0, -12)
  card:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -20, 16)
  card:SetBackdrop({
    bgFile = "Interface\\Buttons\\WHITE8x8",
    edgeFile = "Interface\\Buttons\\WHITE8x8",
    edgeSize = 1,
    insets = { left = 1, right = 1, top = 1, bottom = 1 },
  })
  card:SetBackdropColor(C.bg[1], C.bg[2], C.bg[3], 0.9)
  card:SetBackdropBorderColor(C.border[1], C.border[2], C.border[3], 1)

  local yTop = -12
  local col2x = 430
  local count = 0
  for _, slotId in ipairs(SF.GEAR_SLOT_ORDER) do
    local want = setup.slots[slotId]
    if want then
      count = count + 1
      local col = (count <= 9) and 0 or 1
      local rowIdx = (count <= 9) and (count - 1) or (count - 10)
      local xx = 16 + col * col2x
      local yy = yTop - rowIdx * 24

      local slotName = SF.SLOT_NAMES[slotId] or ("Slot " .. slotId)
      local name, quality = itemDisplayName(want)
      local qhex = QUALITY_HEX[quality] or "e2e4ea"

      local status, statusColor
      if equippedMatches(slotId, want) then
        status, statusColor = "E", "22c55e"
      else
        local link, where = SF.FindItemForSetup(want)
        if link then
          status, statusColor = "bag", "66fcf1"
        elseif where == "bankClosed" then
          status, statusColor = "bank", "f59e0b"
        else
          status, statusColor = "?", "ef4444"
        end
      end

      local rowBtn = CreateFrame("Button", nil, card)
      rowBtn:SetPoint("TOPLEFT", xx, yy)
      rowBtn:SetSize(400, 22)
      local lbl = rowBtn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
      lbl:SetAllPoints()
      lbl:SetJustifyH("LEFT")
      lbl:SetText(("|cff7b8196%-10s|r |cff%s%3s|r  |cff%s%s|r"):format(
        slotName, statusColor, status, qhex, name))

      local tipItemStr = ("item:%d:0:0:0:0:0:%d"):format(want.itemId, want.suffixId or 0)
      rowBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetHyperlink(tipItemStr)
        GameTooltip:Show()
      end)
      rowBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
    end
  end

  local legend = SF.UI_CreateLabel(card,
    "|cff22c55eE|r equipped   |cff66fcf1bag|r in bags   |cfff59e0bbank|r in bank   |cffef4444?|r not found",
    "GameFontHighlightSmall")
  legend:SetPoint("BOTTOMLEFT", 16, 10)
  legend:SetTextColor(C.textDim[1], C.textDim[2], C.textDim[3])
end

local function release()
  if GameTooltip then GameTooltip:Hide() end
end

SF.RegisterTab("gear", render, release)
