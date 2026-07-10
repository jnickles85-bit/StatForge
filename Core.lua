--- StatForge core: SavedVariables, events, slash commands, lifecycle.
--- UI shell lives in UI.lua + *Tab.lua; snapshot/export in Snapshot.lua.

StatForge = StatForge or {}
local SF = StatForge

local function initDB()
  StatForgeDB = StatForgeDB or {}
  StatForgeDB.bankCache = StatForgeDB.bankCache or {}
  StatForgeDB.exports = StatForgeDB.exports or {}
  StatForgeDB.lastExportAt = StatForgeDB.lastExportAt or {}
  StatForgeDB.gearSetups = StatForgeDB.gearSetups or {}
  StatForgeDB.ui = StatForgeDB.ui or {}
  -- firstUse defaults to true (nil means first use)
  if StatForgeDB.firstUse == nil then
    StatForgeDB.firstUse = true
  end
end

local events = CreateFrame("Frame")
events:RegisterEvent("ADDON_LOADED")
events:RegisterEvent("PLAYER_LOGIN")
events:RegisterEvent("BANKFRAME_OPENED")
events:RegisterEvent("BANKFRAME_CLOSED")
events:RegisterEvent("PLAYER_LOGOUT")
events:SetScript("OnEvent", function(_, event, arg1)
  if event == "ADDON_LOADED" and arg1 == SF.ADDON_NAME then
    initDB()
  elseif event == "PLAYER_LOGIN" then
    initDB()
    SF.CreateMinimapButton()
    SF.UpdateMinimapButton()
  elseif event == "BANKFRAME_OPENED" then
    SF.bankOpen = true
    SF.CacheBank()
    if SF.IsMainShown() then SF.RefreshActiveTab() end
  elseif event == "BANKFRAME_CLOSED" then
    SF.CacheBank()
    SF.bankOpen = false
    if SF.IsMainShown() then SF.RefreshActiveTab() end
  elseif event == "PLAYER_LOGOUT" then
    if StatForgeDB and StatForgeDB.noLogoutExport then return end
    pcall(function()
      SF.DoExport()
    end)
  end
end)

function SlashCmdList.STATFORGE(msg)
  local arg = (msg or ""):match("^%s*(.-)%s*$"):lower()
  if arg == "debug" then
    SF.DebugContainers()
    return
  end
  if arg == "export" then
    local json = SF.DoExport()
    if json then
      SF.Print("exported — /reload for the desktop app")
    end
    return
  end
  if arg == "gear" then
    SF.ShowMain("gear")
    return
  end
  if arg == "options" then
    SF.ShowMain("options")
    return
  end
  SF.ToggleMain()
end
SLASH_STATFORGE1 = "/statforge"
SLASH_STATFORGE2 = "/sf"
