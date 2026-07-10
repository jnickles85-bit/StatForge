--- StatForge main window: chrome, tabs, content host.
--- Pure frames (no Ace) — Classic Era compatible.

StatForge = StatForge or {}
local SF = StatForge

local C = SF.Colors

local mainFrame
local tabButtons = {}
local contentFrame
local contentHost
local activeTab = "export"
local tabRenderers = {}
local tabReleasers = {}

local BACKDROP = {
  bgFile   = "Interface\\Buttons\\WHITE8x8",
  edgeFile = "Interface\\Buttons\\WHITE8x8",
  tile = false, tileSize = 0, edgeSize = 1,
  insets = { left = 1, right = 1, top = 1, bottom = 1 },
}

local function applyBackdrop(frame, bg, border, bgA, borderA)
  frame:SetBackdrop(BACKDROP)
  frame:SetBackdropColor(bg[1], bg[2], bg[3], bgA or 0.97)
  frame:SetBackdropBorderColor(border[1], border[2], border[3], borderA or 1)
end

function SF.UI_CreateButton(parent, text, width, height)
  local btn = CreateFrame("Button", nil, parent, "BackdropTemplate")
  btn:SetSize(width or 120, height or 28)
  applyBackdrop(btn, C.surfaceHover, C.border, 1, 1)
  btn:SetHighlightTexture("Interface\\Buttons\\WHITE8x8")
  local ht = btn:GetHighlightTexture()
  if ht then ht:SetVertexColor(C.accent[1], C.accent[2], C.accent[3], 0.12) end

  local fs = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  fs:SetPoint("CENTER")
  fs:SetText(text or "")
  fs:SetTextColor(C.text[1], C.text[2], C.text[3])
  btn.label = fs

  btn:SetScript("OnEnter", function(self)
    applyBackdrop(self, C.surfaceHover, C.accent, 1, 0.8)
    self.label:SetTextColor(C.accent[1], C.accent[2], C.accent[3])
  end)
  btn:SetScript("OnLeave", function(self)
    if self._primary then
      applyBackdrop(self, C.accentDim, C.accent, 0.35, 1)
      self.label:SetTextColor(C.accent[1], C.accent[2], C.accent[3])
    elseif self._success then
      applyBackdrop(self, { 0.08, 0.35, 0.18 }, C.success, 1, 0.9)
      self.label:SetTextColor(C.success[1], C.success[2], C.success[3])
    else
      applyBackdrop(self, C.surfaceHover, C.border, 1, 1)
      self.label:SetTextColor(C.text[1], C.text[2], C.text[3])
    end
  end)

  function btn:SetPrimary(on)
    self._primary = on
    self._success = false
    if on then
      applyBackdrop(self, C.accentDim, C.accent, 0.35, 1)
      self.label:SetTextColor(C.accent[1], C.accent[2], C.accent[3])
    end
  end

  function btn:SetSuccess(on)
    self._success = on
    self._primary = false
    if on then
      applyBackdrop(self, { 0.08, 0.35, 0.18 }, C.success, 1, 0.9)
      self.label:SetTextColor(C.success[1], C.success[2], C.success[3])
    end
  end

  function btn:SetLabel(t)
    self.label:SetText(t)
  end

  return btn
end

function SF.UI_CreateLabel(parent, text, template)
  local fs = parent:CreateFontString(nil, "OVERLAY", template or "GameFontNormal")
  fs:SetText(text or "")
  fs:SetTextColor(C.text[1], C.text[2], C.text[3])
  fs:SetJustifyH("LEFT")
  return fs
end

function SF.UI_ClearChildren(frame)
  local kids = { frame:GetChildren() }
  for _, child in ipairs(kids) do
    child:Hide()
    child:SetParent(nil)
  end
  -- also clear fontstrings created directly on the frame
  local regions = { frame:GetRegions() }
  for _, r in ipairs(regions) do
    if r.GetObjectType and r:GetObjectType() == "FontString" and r ~= frame.title then
      r:Hide()
      r:SetText("")
    end
  end
end

function SF.RegisterTab(id, renderer, releaser)
  tabRenderers[id] = renderer
  tabReleasers[id] = releaser
end

local function selectTab(id)
  if activeTab and tabReleasers[activeTab] then
    pcall(tabReleasers[activeTab])
  end
  activeTab = id

  for tid, btn in pairs(tabButtons) do
    if tid == id then
      applyBackdrop(btn, C.surfaceHover, C.accent, 1, 0.9)
      btn.label:SetTextColor(C.accent[1], C.accent[2], C.accent[3])
    else
      applyBackdrop(btn, C.bg, C.border, 0.6, 0.7)
      btn.label:SetTextColor(C.textMuted[1], C.textMuted[2], C.textMuted[3])
    end
  end

  -- replace content host so each tab gets a clean frame tree
  if contentHost then
    contentHost:Hide()
    contentHost:SetParent(nil)
    contentHost = nil
  end
  contentHost = CreateFrame("Frame", nil, contentFrame)
  contentHost:SetAllPoints(contentFrame)

  if tabRenderers[id] then
    tabRenderers[id](contentHost)
  end
end

function SF.SelectTab(id)
  if not mainFrame then
    SF.ShowMain()
  end
  selectTab(id)
end

local function savePosition()
  if not mainFrame or not StatForgeDB then return end
  StatForgeDB.ui = StatForgeDB.ui or {}
  local p = StatForgeDB.ui
  -- store only numbers — GetPoint's relTo is a Frame userdata, which
  -- SavedVariables can't serialize
  local left = mainFrame:GetLeft()
  local top = mainFrame:GetTop()
  if left and top then
    p.left = left
    p.top = top
  end
end

local function restorePosition(frame)
  local p = StatForgeDB and StatForgeDB.ui
  if p and p.left and p.top then
    frame:ClearAllPoints()
    frame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", p.left, p.top)
  else
    frame:SetPoint("CENTER")
  end
end

local function createMainFrame()
  if mainFrame then return mainFrame end

  local f = CreateFrame("Frame", "StatForgeMainFrame", UIParent, "BackdropTemplate")
  f:SetSize(920, 620)
  f:SetFrameStrata("HIGH")
  f:SetToplevel(true)
  f:SetMovable(true)
  f:EnableMouse(true)
  f:SetClampedToScreen(true)
  applyBackdrop(f, C.bg, C.accentDim, 0.97, 0.85)
  restorePosition(f)

  -- title bar (drag handle)
  local titleBar = CreateFrame("Frame", nil, f, "BackdropTemplate")
  titleBar:SetPoint("TOPLEFT", 1, -1)
  titleBar:SetPoint("TOPRIGHT", -1, -1)
  titleBar:SetHeight(40)
  applyBackdrop(titleBar, C.surface, C.border, 1, 0.5)
  titleBar:EnableMouse(true)
  titleBar:RegisterForDrag("LeftButton")
  titleBar:SetScript("OnDragStart", function() f:StartMoving() end)
  titleBar:SetScript("OnDragStop", function()
    f:StopMovingOrSizing()
    savePosition()
  end)

  local title = titleBar:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  title:SetPoint("LEFT", 16, 0)
  title:SetText(SF.Accent("StatForge"))
  title:SetTextColor(C.accent[1], C.accent[2], C.accent[3])

  local subtitle = titleBar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  subtitle:SetPoint("LEFT", title, "RIGHT", 10, 0)
  subtitle:SetText("Classic Hardcore  ·  v" .. SF.VERSION)
  subtitle:SetTextColor(C.textMuted[1], C.textMuted[2], C.textMuted[3])

  local close = CreateFrame("Button", nil, titleBar, "UIPanelCloseButton")
  close:SetPoint("RIGHT", -4, 0)
  close:SetScript("OnClick", function() f:Hide() end)

  -- tab strip
  local tabStrip = CreateFrame("Frame", nil, f)
  tabStrip:SetPoint("TOPLEFT", titleBar, "BOTTOMLEFT", 12, -8)
  tabStrip:SetPoint("TOPRIGHT", titleBar, "BOTTOMRIGHT", -12, -8)
  tabStrip:SetHeight(32)

  local tabs = {
    { id = "export",  label = "Export" },
    { id = "gear",    label = "Gear" },
    { id = "options", label = "Options" },
  }

  local x = 0
  for _, t in ipairs(tabs) do
    local btn = CreateFrame("Button", nil, tabStrip, "BackdropTemplate")
    btn:SetSize(100, 30)
    btn:SetPoint("LEFT", x, 0)
    x = x + 108
    applyBackdrop(btn, C.bg, C.border, 0.6, 0.7)

    local fs = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    fs:SetPoint("CENTER")
    fs:SetText(t.label)
    fs:SetTextColor(C.textMuted[1], C.textMuted[2], C.textMuted[3])
    btn.label = fs

    btn:SetScript("OnClick", function() selectTab(t.id) end)
    tabButtons[t.id] = btn
  end

  -- content area
  contentFrame = CreateFrame("Frame", nil, f, "BackdropTemplate")
  contentFrame:SetPoint("TOPLEFT", tabStrip, "BOTTOMLEFT", 0, -8)
  contentFrame:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -16, 16)
  applyBackdrop(contentFrame, C.surface, C.border, 0.6, 0.5)

  -- ESC close
  tinsert(UISpecialFrames, "StatForgeMainFrame")

  f:SetScript("OnHide", function()
    if activeTab and tabReleasers[activeTab] then
      pcall(tabReleasers[activeTab])
    end
    if GameTooltip then GameTooltip:Hide() end
  end)

  f:Hide()
  mainFrame = f
  return f
end

function SF.ShowMain(tabId)
  createMainFrame()
  mainFrame:Show()
  mainFrame:Raise()
  selectTab(tabId or activeTab or "export")

  -- first-use splash (once)
  if StatForgeDB and StatForgeDB.firstUse ~= false then
    SF.ShowFirstUseSplash()
  end
end

function SF.HideMain()
  if mainFrame then mainFrame:Hide() end
end

function SF.ToggleMain()
  if mainFrame and mainFrame:IsShown() then
    SF.HideMain()
  else
    SF.ShowMain()
  end
end

function SF.IsMainShown()
  return mainFrame and mainFrame:IsShown()
end

function SF.GetContentFrame()
  return contentFrame
end

function SF.RefreshActiveTab()
  if mainFrame and mainFrame:IsShown() then
    selectTab(activeTab)
  end
end

-- ---------------------------------------------------------------------------
-- First-use splash overlay
-- ---------------------------------------------------------------------------
local splashFrame

function SF.ShowFirstUseSplash()
  if not mainFrame then return end
  if splashFrame then
    splashFrame:Show()
    return
  end

  local cover = CreateFrame("Frame", nil, mainFrame, "BackdropTemplate")
  cover:SetAllPoints(mainFrame)
  cover:SetFrameLevel(mainFrame:GetFrameLevel() + 50)
  applyBackdrop(cover, C.black, C.border, 0.78, 0)
  cover:EnableMouse(true)

  local panel = CreateFrame("Frame", nil, cover, "BackdropTemplate")
  panel:SetSize(520, 320)
  panel:SetPoint("CENTER")
  applyBackdrop(panel, C.surface, C.accent, 1, 0.6)

  local h = SF.UI_CreateLabel(panel, SF.Accent("Welcome to StatForge"), "GameFontNormalLarge")
  h:SetPoint("TOP", 0, -24)
  h:SetJustifyH("CENTER")

  local body = SF.UI_CreateLabel(panel, "", "GameFontHighlight")
  body:SetPoint("TOP", h, "BOTTOM", 0, -20)
  body:SetWidth(460)
  body:SetJustifyH("LEFT")
  body:SetText(
    "StatForge exports your gear for the desktop optimizer — and will soon import optimized sets back in-game.\n\n" ..
    "|cff66fcf11.|r  Open your |cffffffffbank|r once so we can cache it for exports anywhere.\n\n" ..
    "|cff66fcf12.|r  Click |cffffffffExport now|r (or just log out) — the desktop app picks it up after |cffffffff/reload|r.\n\n" ..
    "|cff66fcf13.|r  Use the |cffffffffGear|r tab later to import and equip recommended setups."
  )
  body:SetTextColor(C.text[1], C.text[2], C.text[3])

  local ok = SF.UI_CreateButton(panel, "Got it", 140, 32)
  ok:SetPoint("BOTTOM", 0, 24)
  ok:SetPrimary(true)
  ok:SetScript("OnClick", function()
    if StatForgeDB then StatForgeDB.firstUse = false end
    cover:Hide()
  end)

  splashFrame = cover
end

-- ---------------------------------------------------------------------------
-- Minimap button
-- ---------------------------------------------------------------------------
local minimapBtn

function SF.UpdateMinimapButton()
  local hide = StatForgeDB and StatForgeDB.minimapHide
  if hide then
    if minimapBtn then minimapBtn:Hide() end
    return
  end
  if not minimapBtn then
    SF.CreateMinimapButton()
  end
  if minimapBtn then minimapBtn:Show() end
end

function SF.CreateMinimapButton()
  if minimapBtn then return minimapBtn end
  if not Minimap then return nil end

  local btn = CreateFrame("Button", "StatForgeMinimapButton", Minimap)
  btn:SetSize(32, 32)
  btn:SetFrameStrata("MEDIUM")
  btn:SetFrameLevel(8)
  btn:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

  local overlay = btn:CreateTexture(nil, "OVERLAY")
  overlay:SetSize(54, 54)
  overlay:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
  overlay:SetPoint("TOPLEFT")

  local icon = btn:CreateTexture(nil, "BACKGROUND")
  icon:SetSize(20, 20)
  icon:SetPoint("CENTER", 0, 1)
  -- sword-ish bag icon fallback — classic interface texture
  icon:SetTexture("Interface\\Icons\\INV_Misc_Gear_01")
  btn.icon = icon

  local angle = (StatForgeDB and StatForgeDB.minimapAngle) or 220
  local function updatePos()
    local rad = math.rad(angle)
    local x = math.cos(rad) * 80
    local y = math.sin(rad) * 80
    btn:ClearAllPoints()
    btn:SetPoint("CENTER", Minimap, "CENTER", x, y)
  end
  updatePos()

  btn:RegisterForDrag("LeftButton")
  btn:SetScript("OnDragStart", function(self)
    self:SetScript("OnUpdate", function()
      local mx, my = Minimap:GetCenter()
      local cx, cy = GetCursorPosition()
      local scale = Minimap:GetEffectiveScale()
      cx, cy = cx / scale, cy / scale
      angle = math.deg(math.atan2(cy - my, cx - mx)) % 360
      if StatForgeDB then StatForgeDB.minimapAngle = angle end
      updatePos()
    end)
  end)
  btn:SetScript("OnDragStop", function(self)
    self:SetScript("OnUpdate", nil)
  end)

  btn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
  btn:SetScript("OnClick", function(_, button)
    if button == "LeftButton" then
      SF.ToggleMain()
    end
  end)

  btn:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:AddLine("StatForge", C.accent[1], C.accent[2], C.accent[3])
    GameTooltip:AddLine("Left-click: open window", 0.7, 0.7, 0.7)
    GameTooltip:AddLine("Drag: move button", 0.5, 0.5, 0.5)
    GameTooltip:AddLine("/sf  ·  /statforge", 0.5, 0.5, 0.5)
    GameTooltip:Show()
  end)
  btn:SetScript("OnLeave", function()
    GameTooltip:Hide()
  end)

  minimapBtn = btn
  return btn
end
