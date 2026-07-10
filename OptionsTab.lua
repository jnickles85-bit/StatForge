--- StatForge Options tab.

StatForge = StatForge or {}
local SF = StatForge
local C = SF.Colors

local function render(parent)
  local title = SF.UI_CreateLabel(parent, "Options", "GameFontNormalLarge")
  title:SetPoint("TOPLEFT", 20, -18)
  title:SetTextColor(C.accent[1], C.accent[2], C.accent[3])

  local y = -56

  local hideMini = StatForgeDB and StatForgeDB.minimapHide
  local cb1 = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
  cb1:SetPoint("TOPLEFT", 16, y)
  cb1:SetChecked(not hideMini)
  local l1 = SF.UI_CreateLabel(parent, "Show minimap button", "GameFontHighlight")
  l1:SetPoint("LEFT", cb1, "RIGHT", 4, 0)
  cb1:SetScript("OnClick", function(self)
    if not StatForgeDB then return end
    StatForgeDB.minimapHide = not self:GetChecked()
    SF.UpdateMinimapButton()
  end)

  y = y - 36
  local autoLogout = not (StatForgeDB and StatForgeDB.noLogoutExport)
  local cb2 = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
  cb2:SetPoint("TOPLEFT", 16, y)
  cb2:SetChecked(autoLogout)
  local l2 = SF.UI_CreateLabel(parent, "Auto-export on logout", "GameFontHighlight")
  l2:SetPoint("LEFT", cb2, "RIGHT", 4, 0)
  cb2:SetScript("OnClick", function(self)
    if not StatForgeDB then return end
    StatForgeDB.noLogoutExport = not self:GetChecked()
  end)

  y = y - 48
  local about = SF.UI_CreateLabel(parent, "", "GameFontHighlight")
  about:SetPoint("TOPLEFT", 20, y)
  about:SetWidth(840)
  about:SetJustifyH("LEFT")
  about:SetText(
    SF.Accent("About") .. "\n\n" ..
    "StatForge v" .. SF.VERSION .. "  ·  Classic Era / Hardcore\n" ..
    "Exports gear for the StatForge desktop optimizer.\n" ..
    "Commands:  |cffffffff/sf|r  ·  |cffffffff/statforge|r  ·  |cffffffff/sf debug|r\n\n" ..
    "Tip: open your bank once per character so bank items are included in every export."
  )
  about:SetTextColor(C.textMuted[1], C.textMuted[2], C.textMuted[3])
end

local function release()
end

SF.RegisterTab("options", render, release)
