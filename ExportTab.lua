--- StatForge Export tab: status, export-now, advanced JSON copy.

StatForge = StatForge or {}
local SF = StatForge
local C = SF.Colors

local statusLabels = {}
local jsonEditBox
local jsonScroll
local showJson = false

local function setStatusLine(key, text, color)
  local fs = statusLabels[key]
  if not fs then return end
  fs:SetText(text)
  if color then
    fs:SetTextColor(color[1], color[2], color[3])
  end
end

local function refreshStatus()
  local name = UnitName("player") or "?"
  local realm = GetRealmName() or "?"
  local _, class = UnitClass("player")
  local level = UnitLevel("player") or 0

  setStatusLine("char",
    string.format("%s-%s  ·  Level %d %s", name, realm, level, class or "?"),
    C.text)

  local lastAt = SF.GetLastExportAt()
  if lastAt then
    setStatusLine("export", "Last export:  " .. SF.FormatAge(lastAt) .. "  (saved for desktop app)", C.success)
  else
    setStatusLine("export", "Last export:  never — click Export now", C.warning)
  end

  local bankAt = SF.GetBankCachedAt()
  if SF.bankOpen then
    setStatusLine("bank", "Bank:  open now (live scan)", C.success)
  elseif bankAt then
    local n = 0
    local cache = StatForgeDB and StatForgeDB.bankCache and StatForgeDB.bankCache[SF.CharKey()]
    if cache and cache.items then n = #cache.items end
    setStatusLine("bank",
      string.format("Bank cache:  %s  ·  %d items  (visit bank to refresh)", SF.FormatAge(bankAt), n),
      C.textMuted)
  else
    setStatusLine("bank", "Bank cache:  empty — open your bank once so exports include it", C.warning)
  end

  setStatusLine("help",
    "Desktop app watches WTF/.../SavedVariables/StatForge.lua after /reload or logout.",
    C.textDim)
end

local function doExport(opts)
  opts = opts or {}
  local json, snap = SF.DoExport()
  if not json then
    setStatusLine("result", "Export failed — see chat for details.", C.danger)
    return
  end

  local bagN = snap and snap.bags and #snap.bags or 0
  local bankN = snap and snap.bank and #snap.bank or 0
  local eqN = snap and snap.equipped and #snap.equipped or 0
  setStatusLine("result",
    string.format("Exported  ·  %d equipped  ·  %d bags  ·  %d bank", eqN, bagN, bankN),
    C.success)
  refreshStatus()

  if jsonEditBox and (opts.fillJson or showJson) then
    jsonEditBox:SetText(json)
    if opts.focus then
      jsonEditBox:HighlightText(0, #json)
      jsonEditBox:SetFocus()
    end
  end

  if opts.chat ~= false then
    SF.Print("export ready — /reload (or log out) for the desktop app, or Copy JSON below.")
  end
end

local function render(parent)
  statusLabels = {}
  jsonEditBox = nil
  jsonScroll = nil

  local title = SF.UI_CreateLabel(parent, "Export character", "GameFontNormalLarge")
  title:SetPoint("TOPLEFT", 20, -18)
  title:SetTextColor(C.accent[1], C.accent[2], C.accent[3])

  local sub = SF.UI_CreateLabel(parent,
    "Snapshot your gear, bags, bank, talents, and character sheet for the StatForge optimizer.",
    "GameFontHighlight")
  sub:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
  sub:SetWidth(840)
  sub:SetTextColor(C.textMuted[1], C.textMuted[2], C.textMuted[3])

  -- status card
  local card = CreateFrame("Frame", nil, parent, "BackdropTemplate")
  card:SetPoint("TOPLEFT", sub, "BOTTOMLEFT", 0, -16)
  card:SetSize(860, 120)
  card:SetBackdrop({
    bgFile = "Interface\\Buttons\\WHITE8x8",
    edgeFile = "Interface\\Buttons\\WHITE8x8",
    edgeSize = 1,
    insets = { left = 1, right = 1, top = 1, bottom = 1 },
  })
  card:SetBackdropColor(C.bg[1], C.bg[2], C.bg[3], 0.9)
  card:SetBackdropBorderColor(C.border[1], C.border[2], C.border[3], 1)

  local y = -14
  for _, key in ipairs({ "char", "export", "bank", "help" }) do
    local fs = SF.UI_CreateLabel(card, "", "GameFontHighlight")
    fs:SetPoint("TOPLEFT", 16, y)
    fs:SetWidth(820)
    statusLabels[key] = fs
    y = y - 22
  end

  -- actions
  local exportBtn = SF.UI_CreateButton(parent, "Export now", 140, 32)
  exportBtn:SetPoint("TOPLEFT", card, "BOTTOMLEFT", 0, -16)
  exportBtn:SetPrimary(true)
  exportBtn:SetScript("OnClick", function()
    doExport({ fillJson = showJson })
  end)

  local copyBtn = SF.UI_CreateButton(parent, "Show / Copy JSON", 150, 32)
  copyBtn:SetPoint("LEFT", exportBtn, "RIGHT", 12, 0)
  copyBtn:SetScript("OnClick", function()
    showJson = not showJson
    if jsonScroll then
      if showJson then
        jsonScroll:Show()
        doExport({ fillJson = true, focus = true, chat = false })
        copyBtn:SetLabel("Hide JSON")
      else
        jsonScroll:Hide()
        if jsonEditBox then jsonEditBox:ClearFocus() end
        copyBtn:SetLabel("Show / Copy JSON")
      end
    end
  end)

  local result = SF.UI_CreateLabel(parent, "", "GameFontHighlight")
  result:SetPoint("LEFT", copyBtn, "RIGHT", 16, 0)
  result:SetWidth(400)
  statusLabels["result"] = result

  -- JSON area (hidden by default)
  local scroll = CreateFrame("ScrollFrame", "StatForgeExportScroll", parent, "UIPanelScrollFrameTemplate")
  scroll:SetPoint("TOPLEFT", exportBtn, "BOTTOMLEFT", 0, -16)
  scroll:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -36, 16)
  scroll:Hide()

  local edit = CreateFrame("EditBox", nil, scroll)
  edit:SetMultiLine(true)
  edit:SetFontObject("ChatFontNormal")
  edit:SetWidth(820)
  edit:SetAutoFocus(false)
  edit:SetMaxLetters(0)
  edit:SetTextInsets(8, 8, 8, 8)
  edit:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
  scroll:SetScrollChild(edit)

  jsonEditBox = edit
  jsonScroll = scroll

  if showJson then
    scroll:Show()
    copyBtn:SetLabel("Hide JSON")
  end

  refreshStatus()

  -- auto-export when opening the tab so SV stays fresh (AMR-like always-current export)
  doExport({ fillJson = showJson, chat = false })
end

local function release()
  statusLabels = {}
  if jsonEditBox then
    jsonEditBox:ClearFocus()
    jsonEditBox = nil
  end
  jsonScroll = nil
end

SF.RegisterTab("export", render, release)
