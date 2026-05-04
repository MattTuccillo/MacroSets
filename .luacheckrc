std = "lua51"
max_line_length = false

globals = {
    "ClearCursor",
    "CreateFrame",
    "CreateMacro",
    "DeleteMacro",
    "EditMacro",
    "GetActionInfo",
    "GetMacroIndexByName",
    "GetMacroInfo",
    "GetScreenHeight",
    "GetScreenWidth",
    "HideUIPanel",
    "InCombatLockdown",
    "MacroFrame",
    "MacroSetsBackup",
    "MacroSetsDB",
    "MacroSetsFunctions",
    "PickupMacro",
    "PlaceAction",
    "Settings",
    "SettingsPanel",
    "ShowUIPanel",
    "SlashCmdList",
    "SLASH_MACROSETS1",
    "UIParent",
    "UISpecialFrames",
    "macroSetsCategory",
    "macroSetsOptionsPanel",
    "print",
    "strsplit",
}

ignore = {
    "211", -- unused local variable
    "212", -- unused argument
    "213", -- unused loop variable
}
