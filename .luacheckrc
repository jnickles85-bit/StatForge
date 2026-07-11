std = "lua51"
max_line_length = false
self = false

-- variables the addon itself defines/writes
globals = {
    "StatForge",
    "StatForgeDB",
    "SlashCmdList",
    "SLASH_STATFORGE1",
    "SLASH_STATFORGE2",
}

-- WoW API (read-only)
read_globals = {
    "_G",
    -- frames & UI
    "CreateFrame", "UIParent", "UISpecialFrames", "tinsert",
    "GameTooltip", "Minimap", "GetCursorPosition",
    -- containers
    "C_Container", "GetContainerNumSlots", "GetContainerItemLink",
    -- unit info
    "UnitName", "GetRealmName", "UnitClass", "UnitLevel", "UnitRace",
    "UnitStat", "UnitHealthMax", "UnitPowerType", "UnitPowerMax",
    "UnitArmor", "UnitDefense", "UnitAttackPower", "UnitRangedAttackPower",
    -- character sheet
    "GetCritChance", "GetRangedCritChance", "GetSpellCritChance",
    "GetDodgeChance", "GetParryChance", "GetBlockChance",
    "GetSpellBonusDamage", "GetSpellBonusHealing",
    -- items & talents
    "GetInventoryItemLink", "GetNumTalentTabs", "GetNumTalents", "GetTalentInfo",
    "GetItemInfo", "EquipItemByName", "InCombatLockdown",
    -- misc
    "GetBuildInfo", "date", "time",
}
