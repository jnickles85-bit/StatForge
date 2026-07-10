--- StatForge Gear tab: imported setups (Phase 2 equip loop).
--- Phase 1: placeholder + currently equipped overview.

StatForge = StatForge or {}
local SF = StatForge
local C = SF.Colors

local function itemNameFromLink(link)
  if not link then return nil end
  local name = link:match("%[(.-)%]")
  return name
end

local function render(parent)
  local title = SF.UI_CreateLabel(parent, "Gear setups", "GameFontNormalLarge")
  title:SetPoint("TOPLEFT", 20, -18)
  title:SetTextColor(C.accent[1], C.accent[2], C.accent[3])

  local sub = SF.UI_CreateLabel(parent,
    "Import optimized sets from the StatForge desktop app, then equip them in one click.",
    "GameFontHighlight")
  sub:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
  sub:SetWidth(840)
  sub:SetTextColor(C.textMuted[1], C.textMuted[2], C.textMuted[3])

  -- Import button (disabled shell for Phase 2)
  local importBtn = SF.UI_CreateButton(parent, "Import setup", 140, 30)
  importBtn:SetPoint("TOPLEFT", sub, "BOTTOMLEFT", 0, -16)
  importBtn:SetScript("OnClick", function()
    SF.Print("Setup import arrives in the next update — optimize in the desktop app for now.")
  end)

  local note = SF.UI_CreateLabel(parent,
    "Coming soon: paste a setup from the app · compare vs equipped · Equip button",
    "GameFontNormalSmall")
  note:SetPoint("LEFT", importBtn, "RIGHT", 14, 0)
  note:SetTextColor(C.textDim[1], C.textDim[2], C.textDim[3])

  -- Currently equipped panel
  local card = CreateFrame("Frame", nil, parent, "BackdropTemplate")
  card:SetPoint("TOPLEFT", importBtn, "BOTTOMLEFT", 0, -16)
  card:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -20, 16)
  card:SetBackdrop({
    bgFile = "Interface\\Buttons\\WHITE8x8",
    edgeFile = "Interface\\Buttons\\WHITE8x8",
    edgeSize = 1,
    insets = { left = 1, right = 1, top = 1, bottom = 1 },
  })
  card:SetBackdropColor(C.bg[1], C.bg[2], C.bg[3], 0.9)
  card:SetBackdropBorderColor(C.border[1], C.border[2], C.border[3], 1)

  local head = SF.UI_CreateLabel(card, "Currently equipped", "GameFontNormal")
  head:SetPoint("TOPLEFT", 16, -12)
  head:SetTextColor(C.text[1], C.text[2], C.text[3])

  local y = -40
  local col2x = 430
  local count = 0
  for _, slotId in ipairs(SF.GEAR_SLOT_ORDER) do
    count = count + 1
    local col = (count <= 9) and 0 or 1
    local rowIdx = (count <= 9) and (count - 1) or (count - 10)
    local x = 16 + col * col2x
    local yy = y - rowIdx * 22

    local slotName = SF.SLOT_NAMES[slotId] or ("Slot " .. slotId)
    local link = GetInventoryItemLink("player", slotId)
    local name = itemNameFromLink(link)

    local rowBtn = CreateFrame("Button", nil, card)
    rowBtn:SetPoint("TOPLEFT", x, yy)
    rowBtn:SetSize(400, 20)
    local lbl = rowBtn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    lbl:SetAllPoints()
    lbl:SetJustifyH("LEFT")
    if name then
      lbl:SetText(string.format("|cff7b8196%-12s|r  %s", slotName, link))
      rowBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetHyperlink(link)
        GameTooltip:Show()
      end)
      rowBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
    else
      lbl:SetText(string.format("|cff4a5066%-12s  —|r", slotName))
      lbl:SetTextColor(C.textDim[1], C.textDim[2], C.textDim[3])
    end
  end
end

local function release()
  if GameTooltip then GameTooltip:Hide() end
end

SF.RegisterTab("gear", render, release)
