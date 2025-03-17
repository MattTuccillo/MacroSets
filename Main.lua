-- Color codes
local COLOR_PURPLE = "|cFFCC79A7" -- debugging messages
local COLOR_SKY_BLUE = "|cFF56B4E9" -- help section text
local COLOR_LIGHT_BLUE = "|cFFADD8E6" -- help section bullets
local COLOR_PINK = "|cFFF4B183" -- help section examples
local COLOR_YELLOW = "|cFFF0E442" -- help section commands
local COLOR_ORANGE = "|cFFE69F00" -- help section parameters
local COLOR_BLUE = "|cFF0072B2" -- heading dividers
local COLOR_VERMILLION = "|cFFD55E00" -- error message
local COLOR_GREEN = "|cFF009E73" -- success message
local COLOR_RESET = "|r" -- reset back to original color

-- toggles for debugging
local debug = {
    allFunctions = false,
    toggleDynamicIcons = false,
    toggleActionBarPlacements = false,
    toggleCharSpecific = false,
    backupMacroSets = false,
    alphabetizeMacroSets = false,
    saveMacroSet = false,
    loadMacroSet = false,
    deleteMacroSet = false,
    deleteAllMacroSets = false,
    undoLastOperation = false,
    listMacroSets = false,
    displayHelp = false,
    isValidSetName = false,
    getActionBarSlotsForMacro = false,
    placeMacroInActionBarSlots = false,
    setMacroSlotRanges = false,
    isMacroSetEmpty = false,
    deleteMacrosInRange = false,
    restoreMacroBodies = false,
    duplicateNames = false,
    optionsScreenToggle = false,
    handleSlashCommands = false,
}

local function DebugMessage(message, func)
    if debug.allFunctions or func then
        print(COLOR_PURPLE .. message .. COLOR_RESET)
    end
end

local function DeepCopyTable(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[DeepCopyTable(orig_key)] = DeepCopyTable(orig_value)
        end
        setmetatable(copy, DeepCopyTable(getmetatable(orig)))
    else
        copy = orig
    end
    return copy
end

-- Create alphabetized macro set list for easier reference when listed
local sortedSetNames = {}
local actionBarSlotLimit = 180
MacroSetsFunctions = MacroSetsFunctions or {}
MacroSetsDB = MacroSetsDB or {}
MacroSetsBackup = MacroSetsBackup or {}

function MacroSetsFunctions.ToggleDynamicIcons()
    DebugMessage("ToggleDynamicIcons(): Function called.", debug.toggleDynamicIcons)
    MacroSetsDB.dynamicIcons = not MacroSetsDB.dynamicIcons
    local status = MacroSetsDB.dynamicIcons and 'ON' or 'OFF'
    DebugMessage("ToggleDynamicIcons(): Toggled to " .. tostring(MacroSetsDB.dynamicIcons) .. ".", debug.toggleDynamicIcons)
end

function MacroSetsFunctions.ToggleActionBarPlacements()
    DebugMessage("ToggleActionBarPlacements(): Function called.", debug.toggleActionBarPlacements)
    MacroSetsDB.replaceBars = not MacroSetsDB.replaceBars
    local status = MacroSetsDB.replaceBars and 'ON' or 'OFF'
    DebugMessage("ToggleActionBarPlacements(): Toggled to " .. tostring(MacroSetsDB.replaceBars) .. ".", debug.toggleActionBarPlacements)
end

function MacroSetsFunctions.ToggleCharSpecific()
    DebugMessage("ToggleCharSpecific(): Function called.", debug.toggleCharSpecific)
    MacroSetsDB.charSpecific = not MacroSetsDB.charSpecific
    local status = MacroSetsDB.charSpecific and 'ON' or 'OFF'
    DebugMessage("ToggleCharSpecific(): Toggled to " .. tostring(MacroSetsDB.charSpecific) .. ".", debug.toggleCharSpecific)
end

local function BackupMacroSets()
    DebugMessage("BackupMacroSets(): Function called.", debug.backupMacroSets)
    MacroSetsBackup = {}
    for setName, setData in pairs(MacroSetsDB) do
        MacroSetsBackup[setName] = DeepCopyTable(setData)
    end
end

local function AlphabetizeMacroSets()
    DebugMessage("AlphabetizeMacroSets(): Function called.", debug.alphabetizeMacroSets)
    sortedSetNames = {}
    for setName, setDetails in pairs(MacroSetsDB) do
        if type(setDetails) == 'table' and setDetails.macros then
            table.insert(sortedSetNames, setName)
        end
    end
    table.sort(sortedSetNames, function(a, b)
        return string.lower(a) < string.lower(b)
    end)
end

local function IsValidSetName(setName)
    DebugMessage("IsValidSetName(): Function called.", debug.isValidSetName)
    DebugMessage("IsValidSetName(): setName = " .. setName .. ".", debug.isValidSetName)
    
    if not setName or setName == "" then
        print("Please enter a macro set name.")
        return false
    end

    if string.len(setName) > 50 then
        print(COLOR_VERMILLION .. "Macro set name is too long. There is a 50 character limit." .. COLOR_RESET)
        return false
    end

    if string.match(setName, "^[a-zA-Z0-9_-]+$") == nil then
        print(COLOR_VERMILLION .. "Invalid macro set name. Please use only alphanumeric characters, hyphens, and underscores." .. COLOR_RESET)
        return false
    end

    return true
end

local function GetActionBarSlotsForMacro(macroName)
    DebugMessage("GetActionBarSlotsForMacro(): Function called.", debug.getActionBarSlotsForMacro)
    local slots = {}
    for i = 1, actionBarSlotLimit do
        local actionType, id = GetActionInfo(i)
        local name, icon, body = GetMacroInfo(id)
        if name == macroName then
            table.insert(slots, i)
        end
    end
    return slots
end

local function PlaceMacroInActionBarSlots(macroIndex, positions)
    local name, icon, body = GetMacroInfo(macroIndex)

    DebugMessage("PlaceMacroInActionBarSlots(): Function called.", debug.placeMacroInActionBarSlots)
    DebugMessage("PlaceMacroInActionBarSlots(): Placing " .. name .. ".", debug.placeMacroInActionBarSlots)
    DebugMessage("PlaceMacroInActionBarSlots(): Macro index = " .. macroIndex .. ".", debug.placeMacroInActionBarSlots)
    DebugMessage("PlaceMacroInActionBarSlots(): Positions = " .. table.concat(positions, ", ") .. ".", debug.placeMacroInActionBarSlots)

    for _, slot in ipairs(positions) do
        if slot < 1 or slot > actionBarSlotLimit then
            print(COLOR_VERMILLION .. "Action bar slot " .. slot .. " is out of range." .. COLOR_RESET)
        else
            PickupMacro(macroIndex)
            PlaceAction(slot)
            ClearCursor()
        end
    end
end

local function SetMacroSlotRanges(macroType)
    DebugMessage("SetMacroSlotRanges(): Function called.", debug.setMacroSlotRanges)
    DebugMessage("SetMacroSlotRanges(): macroType = " .. macroType .. ".", debug.setMacroSlotRanges)
    if macroType == "g" then
        return 1, 120
    elseif macroType == "c" then
        return 121, 150
    else
        return 1, 150
    end
end

local function IsMacroSetEmpty(generalCount, characterCount, macroType)
    DebugMessage("IsMacroSetEmpty(): Function called.", debug.isMacroSetEmpty)
    DebugMessage("IsMacroSetEmpty(): generalCount = " .. generalCount .. ".", debug.isMacroSetEmpty)
    DebugMessage("IsMacroSetEmpty(): characterCount = " .. characterCount .. ".", debug.isMacroSetEmpty)
    DebugMessage("IsMacroSetEmpty():" .. generalCount+characterCount .. " total macros found.", debug.isMacroSetEmpty)
    DebugMessage("IsMacroSetEmpty(): macroType = " .. macroType .. ".", debug.isMacroSetEmpty)

    if (macroType == "g" and generalCount == 0) or
        (macroType == "c" and characterCount == 0) or
        (generalCount == 0 and characterCount == 0) then
        return true
    end

    return false
end

local function DeleteMacrosInRange(startSlot, endSlot)
    DebugMessage("DeleteMacrosInRange(): Function called.", debug.deleteMacrosInRange)
    DebugMessage("DeleteMacrosInRange(): startSlot = " .. startSlot .. ".", debug.deleteMacrosInRange)
    DebugMessage("DeleteMacrosInRange(): endSlot = " .. endSlot .. ".", debug.deleteMacrosInRange)
    for i = endSlot, startSlot, -1 do
        local macroName = GetMacroInfo(i)
        if macroName then
            DeleteMacro(i)
        end
    end
end

local function RestoreMacroBodies(setName)
    DebugMessage("RestoreMacroBodies(): Function called.", debug.restoreMacroBodies)
    DebugMessage("RestoreMacroBodies(): setName = " .. setName .. ".", debug.restoreMacroBodies)
    for _, macroDetails in ipairs(MacroSetsDB[setName].macros) do
        EditMacro(GetMacroIndexByName(macroDetails.name), macroDetails.name, macroDetails.icon, macroDetails.body)
    end
end

local function DeleteMacroSet(setName)
    DebugMessage("DeleteMacroSet(): Function called.", debug.deleteMacroSet)
    DebugMessage("DeleteMacroSet(): setName = " .. setName .. ".", debug.deleteMacroSet)

    if not IsValidSetName(setName) then 
        return 
    end

    if MacroSetsDB[setName] then
        -- Backup current macro sets
        BackupMacroSets()
        -- Remove the macro set from the database
        MacroSetsDB[setName] = nil
        print(COLOR_GREEN .. "Macro set '" .. setName .. "' has been deleted." .. COLOR_RESET)
    else
        print(COLOR_VERMILLION .. "Macro set '" .. setName .. "' not found." .. COLOR_RESET)
    end
end

local function DeleteAllMacroSets()
    DebugMessage("DeleteAllMacroSets(): Function called.", debug.deleteAllMacroSets)

    -- Backup current macro sets
    BackupMacroSets()

    -- Delete all macro sets
    for setName in pairs(MacroSetsDB) do
        if type(MacroSetsDB[setName]) == "table" then
            MacroSetsDB[setName] = nil
        end
    end

    print(COLOR_GREEN .. "All macro sets have been deleted." .. COLOR_RESET)
end

local function DuplicateNames(set)
    DebugMessage("DuplicateNames(): Function called.", debug.duplicateNames)
    local seen = {}
    for _, name in ipairs(set) do
        if seen[name] then
            DebugMessage("DuplicateNames(): Duplicate found: " .. name .. ".", debug.duplicateNames)
            return true
        end
        seen[name] = true
    end
    DebugMessage("DuplicateNames(): No duplicates found.", debug.duplicateNames)
    return false
end

local function SaveMacroSet(setName, macroType)
    DebugMessage("SaveMacroSet(): Function called.", debug.saveMacroSet)

    -- Prevent execution during combat
    if InCombatLockdown() then
        print(COLOR_VERMILLION .. "Cannot perform this action during combat." .. COLOR_RESET)
        return
    end

    -- Validate macro set name
    if not IsValidSetName(setName) then 
        return 
    end

    -- Determine macro set type
    local macroType = macroType
    if macroType ~= "c" and macroType ~= "g" then
        if MacroSetsDB.charSpecific then
            macroType = "c"
        else
            macroType = "both"
        end
    end

    -- Initialize variables
    local startSlot, endSlot = SetMacroSlotRanges(macroType)
    local generalMacroCount = 0
    local characterMacroCount = 0
    local dupes = false
    local namesCache = {}
    -- Store data in a temporary table
    -- MacroSetsDB[setName] = {macros = {}, type = macroType, generalCount = 0, characterCount = 0, dupes = dupes}
    local tempMacroSet = {
        macros = {}, 
        type = macroType, 
        generalCount = 0, 
        characterCount = 0, 
        dupes = dupes
    }
    for i = startSlot, endSlot do
        -- Prevent Execution During Combat
        if InCombatLockdown() then
            print(COLOR_VERMILLION .. "Save interrupted. Please try again after leaving combat." .. COLOR_RESET)
            return
        end
        -- Load macro information
        local name, icon, body = GetMacroInfo(i)
        if name then
            -- Check for macro icon behavior flag
            local endsWithD = string.sub(name, -2) == "#i"
            -- If dynamic icons are enabled and the name ends with "#i"
            if MacroSetsDB.dynamicIcons and endsWithD then
                icon = 134400
                DebugMessage("SaveMacroSet(): Static icon set for macro: " .. name .. ".", debug.saveMacroSet)
            -- If dynamic icons are disabled and the name does not end with "#i"
            elseif not MacroSetsDB.dynamicIcons and not endsWithD then
                icon = 134400
                DebugMessage("SaveMacroSet(): Dynamic icon set for macro: " .. name .. ".", debug.saveMacroSet)
            end
            EditMacro(i, name, icon, "", 1)
            local actionBarSlots = GetActionBarSlotsForMacro(name)
            EditMacro(i, name, icon, body, 1)
            table.insert(tempMacroSet.macros, {name = name, icon = icon, body = body, position = actionBarSlots})
            table.insert(namesCache, name)
            if i <= 120 then
                generalMacroCount = generalMacroCount + 1
            else
                characterMacroCount = characterMacroCount + 1
            end
        end
    end
    tempMacroSet.dupes = DuplicateNames(namesCache)
    tempMacroSet.generalCount = generalMacroCount
    tempMacroSet.characterCount = characterMacroCount

    -- Check duplicate macro names
    if tempMacroSet.dupes then
        print(COLOR_VERMILLION .. "Failed to save set. All macros in a set must have unique names." .. COLOR_RESET)
        return
    end
    -- Check empty macro set
    if IsMacroSetEmpty(generalMacroCount, characterMacroCount, macroType) then
        print(COLOR_VERMILLION .. "No macros to save." .. COLOR_RESET)
        return
    end

    -- Backup current macro sets
    BackupMacroSets()
    -- Insert new set into current database
    MacroSetsDB[setName] = tempMacroSet
    -- Display successful save message
    if macroType == "g" then
        print(COLOR_GREEN .. "General Macro set saved as '" .. setName .. "'." .. COLOR_RESET)
    end
    if macroType == "c" then
        print(COLOR_GREEN .. "Character Macro set saved as '" .. setName .. "'." .. COLOR_RESET)
    end
    if macroType == "both" then
        print(COLOR_GREEN .. "Macro set saved as '" .. setName .. "'." .. COLOR_GREEN)
    end
    -- Alphabetize macro sets
    AlphabetizeMacroSets()
end

local function LoadMacroSet(setName)
    DebugMessage("LoadMacroSet(): Function called.", debug.loadMacroSet)

    if InCombatLockdown() then
        print(COLOR_VERMILLION .. "Cannot perform this action during combat." .. COLOR_RESET)
        return
    end

    if not IsValidSetName(setName) then 
        return 
    end

    if not MacroSetsDB[setName] then
        print(COLOR_VERMILLION .. "Set does not exist." .. COLOR_RESET)
        return
    end

    local macroFrameWasOpen = MacroFrame and MacroFrame:IsVisible()
    if macroFrameWasOpen then 
        HideUIPanel(MacroFrame) 
    end

    local macroSetType = MacroSetsDB[setName].type
    local macroSet = MacroSetsDB[setName].macros
    local startSlot, endSlot = SetMacroSlotRanges(macroSetType)
    DeleteMacrosInRange(startSlot, endSlot)
    local generalMacroCount = MacroSetsDB[setName].generalCount or 0
    local characterMacroCount = MacroSetsDB[setName].characterCount or 0
    for _, macro in ipairs(macroSet) do
        if InCombatLockdown() then
            print(COLOR_VERMILLION .. "Load interrupted. Please try again after leaving combat." .. COLOR_RESET)
            return
        end
        local macroIndex
        local positions
        if generalMacroCount > 0 then
            macroIndex = CreateMacro(macro.name, macro.icon, "")
            generalMacroCount = generalMacroCount - 1
        elseif characterMacroCount > 0 then
            macroIndex = CreateMacro(macro.name, macro.icon, "", 1)  -- 1 for character-specific
            characterMacroCount = characterMacroCount - 1
        else
            print(COLOR_VERMILLION .. "No more macro slots available for this type." .. COLOR_RESET)
            break
        end
        positions = macro.position or {}
        if MacroSetsDB.replaceBars == true then
            if macroIndex and #positions ~= 0 then
                PlaceMacroInActionBarSlots(macroIndex, positions)
            end
        end
    end

    RestoreMacroBodies(setName)

    if macroFrameWasOpen then 
        ShowUIPanel(MacroFrame) 
    end

    print(COLOR_GREEN .. "Macro set '" .. setName .. "' loaded." .. COLOR_RESET)
end

local function UndoLastOperation()
    DebugMessage("UndoLastOperation(): Function called.", debug.undoLastOperation)

    -- Temporarily store backup sets
    local tempMacroSetsDB = {}
    for setName, setData in pairs(MacroSetsBackup) do
        tempMacroSetsDB[setName] = DeepCopyTable(setData)
    end

    -- Update backup to current macro sets
    BackupMacroSets()
    
    -- Clean current macro sets database
    for setName in pairs(MacroSetsDB) do
        if type(MacroSetsDB[setName]) == "table" then
            MacroSetsDB[setName] = nil
        end
    end

    -- Load backup into current macro sets database
    for setName, setData in pairs(tempMacroSetsDB) do
        MacroSetsDB[setName] = DeepCopyTable(setData)
    end
    print(COLOR_GREEN .. "Previous action successfully undone." .. COLOR_RESET)
end

local function ListMacroSets()
    DebugMessage("ListMacroSets(): Function called.", debug.listMacroSets)

    if next(sortedSetNames) == nil then
        print(COLOR_VERMILLION .. "No macro sets saved." .. COLOR_RESET)
        return
    end

    print(COLOR_BLUE .. "==============================" .. COLOR_RESET)
    print("Saved Macro Sets:" .. COLOR_RESET)
    print(COLOR_BLUE .. "==============================" .. COLOR_RESET)
    for _, setName in ipairs(sortedSetNames) do
        local setDetails = MacroSetsDB[setName]
        if type(setDetails) == 'table' and setDetails.macros then
            local setType = setDetails.type
            local COLOR_BOTH_INDICATOR = "|cFFFFFF36(B)|r"
            local COLOR_GENERAL_INDICATOR = "|cFF36FF4C(G)|r"
            local COLOR_CHARACTER_INDICATOR = "|cFF58E5F5(C)|r"
            local setTypeIndicator = setType == 'c' and COLOR_CHARACTER_INDICATOR or setType == 'g' and COLOR_GENERAL_INDICATOR or COLOR_BOTH_INDICATOR
            print(COLOR_GREEN .. "- " .. COLOR_RESET .. setTypeIndicator .. setName)
        end
    end
    print(COLOR_BLUE .. "==============================" .. COLOR_RESET)
end

local function OptionsScreenToggle()
    DebugMessage("OptionsScreenToggle(): Function called.", debug.optionsScreenToggle)
    if SettingsPanel:GetCurrentCategory() == macroSetsCategory and SettingsPanel:IsShown() then
        SettingsPanel:Hide()
        DebugMessage("OptionsScreenToggle(): Options screen hidden.", debug.optionsScreenToggle)
    else
        SettingsPanel:Hide()
        SettingsPanel:Show()
        Settings.OpenToCategory(macroSetsCategory:GetID())
        DebugMessage("OptionsScreenToggle(): Options screen shown.", debug.optionsScreenToggle)
    end
end    

local function DisplayHelp(helpSection)
    DebugMessage("DisplayHelp(): Function called.", debug.displayHelp)
    DebugMessage("DisplayHelp(): helpSection = " .. helpSection .. ".", debug.displayHelp)

    if helpSection == nil then
        print(COLOR_BLUE .. "==============================" .. COLOR_RESET)
        print("Macro Sets - Help: General" .. COLOR_RESET)
        print(COLOR_BLUE .. "==============================" .. COLOR_RESET)
        print(COLOR_YELLOW .. "/ms save [name] [type] " .. COLOR_SKY_BLUE .. "- Save the current macro set with the specified name." .. COLOR_RESET) 
        print(COLOR_YELLOW .. "/ms load [name] " .. COLOR_SKY_BLUE .. "- Load the macro set with the specified name." .. COLOR_RESET)
        print(COLOR_YELLOW .. "/ms delete [name] " .. COLOR_SKY_BLUE .. "- Delete the macro set with the specified name." .. COLOR_RESET)
        print(COLOR_YELLOW .. "/ms deleteall " .. COLOR_SKY_BLUE .. "- Delete all saved macro sets." .. COLOR_RESET)
        print(COLOR_YELLOW .. "/ms undo " .. COLOR_SKY_BLUE .. "- Undo the last eligible action." .. COLOR_RESET)
        print(COLOR_YELLOW .. "/ms list " .. COLOR_SKY_BLUE .. "- List all saved macro sets." .. COLOR_RESET)
        print(COLOR_YELLOW .. "/ms options " .. COLOR_SKY_BLUE .. "- Toggle the options screen." .. COLOR_RESET)
        print(COLOR_YELLOW .. "/ms help [command] " .. COLOR_SKY_BLUE .. "- Display detailed information about a specific command." .. COLOR_RESET)
        print(COLOR_BLUE .. "==============================" .. COLOR_RESET)
    elseif helpSection == "save" then
        print(COLOR_BLUE .. "==============================" .. COLOR_RESET)
        print("Macro Sets - Help: Save" .. COLOR_RESET)
        print(COLOR_BLUE .. "==============================" .. COLOR_RESET)
        print(COLOR_SKY_BLUE .. "- Type " .. COLOR_YELLOW .. "/ms save [name] [type] " .. COLOR_SKY_BLUE .. "to save the current macro set." .. COLOR_RESET)
        print(COLOR_LIGHT_BLUE .. "  - " .. COLOR_ORANGE .. "[name] " .. COLOR_LIGHT_BLUE .. "50 characters limit. No spaces." .. COLOR_RESET)
        if (MacroSetsDB.charSpecific) then
            print(COLOR_LIGHT_BLUE .. "  - " .. COLOR_ORANGE .. "[type] " .. COLOR_LIGHT_BLUE .. "Defaults to " .. COLOR_ORANGE .. "'c' " .. COLOR_LIGHT_BLUE .."if omitted." .. COLOR_RESET)
        else
            print(COLOR_LIGHT_BLUE .. "  - " .. COLOR_ORANGE .. "[type] " .. COLOR_LIGHT_BLUE .. "Defaults to " .. COLOR_ORANGE .. "'both' " .. COLOR_LIGHT_BLUE .."if omitted." .. COLOR_RESET)
        end
        print(COLOR_LIGHT_BLUE .. "    - " .. COLOR_ORANGE .. "'g' " .. COLOR_LIGHT_BLUE .. "for general macros tab." .. COLOR_RESET)
        print(COLOR_LIGHT_BLUE .. "    - " .. COLOR_ORANGE .. "'c' " .. COLOR_LIGHT_BLUE .. "for character macros tab." .. COLOR_RESET)
        if (MacroSetsDB.dynamicIcons) then
            print(COLOR_SKY_BLUE .. "- By default icons are stored with the |T134400:0|t icon when saved." .. COLOR_RESET)
            print(COLOR_LIGHT_BLUE .. "  - Macro names ending with " .. COLOR_RESET .. "'#i' " .. COLOR_LIGHT_BLUE .. "are stored as they appeared when saved." .. COLOR_RESET)
        else
            print(COLOR_SKY_BLUE .. "- By default icons are stored as they appeared when saved." .. COLOR_RESET)
            print(COLOR_LIGHT_BLUE .. "  - Macro names ending with " .. COLOR_RESET .. "'#i' " .. COLOR_LIGHT_BLUE .. "are stored with the |T134400:0|t icon when saved." .. COLOR_RESET)
        end
        print(COLOR_LIGHT_BLUE .. "  - |T134400:0|t icon changes based upon macro text content." .. COLOR_RESET)
        print(COLOR_SKY_BLUE .. "- Saving is an undo-able action." .. COLOR_RESET)
        print(COLOR_BLUE .. "==============================" .. COLOR_RESET)
    elseif helpSection == "load" then
        print(COLOR_BLUE .. "==============================" .. COLOR_RESET)
        print("Macro Sets - Help: Load" .. COLOR_RESET)
        print(COLOR_BLUE .. "==============================" .. COLOR_RESET)
        print(COLOR_SKY_BLUE .. "- Type " .. COLOR_YELLOW .. "/ms load [name] " .. COLOR_SKY_BLUE .. "to load a specific macro set." .. COLOR_RESET)
        print(COLOR_LIGHT_BLUE .. "  - " .. COLOR_ORANGE .. "[name] " .. COLOR_LIGHT_BLUE .. "Must exist to successfully load." .. COLOR_RESET)
        if (MacroSetsDB.replaceBars) then
            print(COLOR_SKY_BLUE .. "- By default macros are placed in the action bar slots they were saved in when loaded." .. COLOR_RESET)
            print(COLOR_LIGHT_BLUE .. "  - Existing items in the action bar slot will be overwritten." .. COLOR_RESET)
        else
            print(COLOR_SKY_BLUE .. "- By default macros are not placed in the action bar slots they were saved in when loaded." .. COLOR_RESET)
            print(COLOR_LIGHT_BLUE .. "  - Macros will only be loaded into the macro frame." .. COLOR_RESET)
        end
        print(COLOR_BLUE .. "==============================" .. COLOR_RESET)
        return
    elseif helpSection == "delete" then
        print(COLOR_BLUE .. "==============================" .. COLOR_RESET)
        print("Macro Sets - Help: Delete" .. COLOR_RESET)
        print(COLOR_BLUE .. "==============================" .. COLOR_RESET)
        print(COLOR_SKY_BLUE .. "- Type " .. COLOR_YELLOW .. "/ms delete [name] " .. COLOR_SKY_BLUE .. "to delete a specific macro set." .. COLOR_RESET)
        print(COLOR_LIGHT_BLUE .. "  - " .. COLOR_ORANGE .. "[name] " .. COLOR_LIGHT_BLUE .. "Must exist to successfully delete." .. COLOR_RESET)
        print(COLOR_SKY_BLUE .. "- Deleting is an undo-able action." .. COLOR_RESET)
        print(COLOR_BLUE .. "==============================" .. COLOR_RESET)
        return
    elseif helpSection == "deleteall" then
        print(COLOR_BLUE .. "==============================" .. COLOR_RESET)
        print("Macro Sets - Help: Delete All" .. COLOR_RESET)
        print(COLOR_BLUE .. "==============================" .. COLOR_RESET)
        print(COLOR_SKY_BLUE .. "- Type " .. COLOR_YELLOW .. "/ms deleteall " .. COLOR_SKY_BLUE .. "to delete all macro sets." .. COLOR_RESET)
        print(COLOR_SKY_BLUE .. "- Deleting all is an undo-able action." .. COLOR_RESET)
        print(COLOR_BLUE .. "==============================" .. COLOR_RESET)
        return
    elseif helpSection == "undo" then
        print(COLOR_BLUE .. "==============================" .. COLOR_RESET)
        print("Macro Sets - Help: Undo" .. COLOR_RESET)
        print(COLOR_BLUE .. "==============================" .. COLOR_RESET)
        print(COLOR_SKY_BLUE .. "- Type " .. COLOR_YELLOW .. "/ms undo " .. COLOR_SKY_BLUE .. "to revert the changes from a previous action." .. COLOR_RESET)
        print(COLOR_LIGHT_BLUE .. "  - Saving can be undone if you save over a macro set accidentally." .. COLOR_RESET)
        print(COLOR_LIGHT_BLUE .. "  - Deleting can be undone if you delete a macro set accidentally." .. COLOR_RESET)
        print(COLOR_LIGHT_BLUE .. "  - Deleting all can be undone if you delete all macro sets accidentally." .. COLOR_RESET)
        print(COLOR_LIGHT_BLUE .. "  - Undoing can be undone if you want to redo something you undid." .. COLOR_RESET)
        print(COLOR_SKY_BLUE .. "- The stored backup persists across sessions." .. COLOR_RESET)
        print(COLOR_LIGHT_BLUE .. "  - You can perform an action, logout, log back in, and then undo the previous action later." .. COLOR_RESET)
        print(COLOR_SKY_BLUE .. "- The stored backup is shared across all characters." .. COLOR_RESET)
        print(COLOR_BLUE .. "==============================" .. COLOR_RESET)
        return
    elseif helpSection == "list" then
        print(COLOR_BLUE .. "==============================" .. COLOR_RESET)
        print("Macro Sets - Help: List" .. COLOR_RESET)
        print(COLOR_BLUE .. "==============================" .. COLOR_RESET)
        print(COLOR_SKY_BLUE .. "- Type " .. COLOR_YELLOW .. "/ms list " .. COLOR_SKY_BLUE .. "to display a list of all existing macro sets." .. COLOR_RESET)
        print(COLOR_SKY_BLUE .. "- Sets will note the set type they encompass." .. COLOR_RESET)
        print(COLOR_LIGHT_BLUE .. "  - " .. COLOR_RESET .. "(G) " .. COLOR_LIGHT_BLUE .. "in green for general macros." .. COLOR_RESET)
        print(COLOR_LIGHT_BLUE .. "  - " .. COLOR_RESET .. "(C) " .. COLOR_LIGHT_BLUE .. "in blue for character-specific macros." .. COLOR_RESET)
        print(COLOR_LIGHT_BLUE .. "  - " .. COLOR_RESET .. "(B) " .. COLOR_LIGHT_BLUE .. "in yellow for both general and character-specific macros." .. COLOR_RESET)
        print(COLOR_SKY_BLUE .. "- Sets will be ordered alphabetically." .. COLOR_RESET)
        print(COLOR_BLUE .. "==============================" .. COLOR_RESET)
        return
    elseif helpSection == "options" then
        print(COLOR_BLUE .. "==============================" .. COLOR_RESET)
        print("Macro Sets - Help: Options" .. COLOR_RESET)
        print(COLOR_BLUE .. "==============================" .. COLOR_RESET)
        print(COLOR_SKY_BLUE .. "- Type " .. COLOR_YELLOW .. "/ms options " .. COLOR_SKY_BLUE .. "to toggle the MacroSets configuration window." .. COLOR_RESET)
        print(COLOR_SKY_BLUE .. "- The configuration window allows you to toggle certain settings in MacroSets." .. COLOR_RESET)
        print(COLOR_LIGHT_BLUE .. "  - Each setting describes the expected functionality based on whether it is checked or not." .. COLOR_RESET)
        print(COLOR_SKY_BLUE .. "- The configuration window toggles are shared across all characters." .. COLOR_RESET)
        print(COLOR_BLUE .. "==============================" .. COLOR_RESET)
        return
    else
        print(COLOR_VERMILLION .. "Invalid Command: Type " .. COLOR_YELLOW .. "'/ms help'" .. COLOR_VERMILLION .. " for a list of valid commands." .. COLOR_RESET)
    end
end

local function HandleSlashCommands(msg)
    DebugMessage("HandleSlashCommands(): Function called.", debug.handleSlashCommands)

    msg = string.match(msg, "^%s*(.-)%s*$")
    local command, arg1, arg2 = strsplit(" ", msg)
    command = string.lower(command)

    if command == 'save' then
        -- arg1 = setName, arg2 = macroType
        SaveMacroSet(arg1, arg2)
    elseif command == 'load' then
        -- arg1 = setName
        LoadMacroSet(arg1)
    elseif command == 'delete' then
        -- arg1 = setName
        DeleteMacroSet(arg1)
    elseif command == 'deleteall' then
        DeleteAllMacroSets()
    elseif command == 'undo' then
        UndoLastOperation()
    elseif command == 'list' then
        AlphabetizeMacroSets()
        ListMacroSets()
    elseif command == 'help' then
        -- arg1 = helpSection
        DisplayHelp(arg1)
    elseif command == 'options' then
        OptionsScreenToggle()
    else
        print(COLOR_VERMILLION .. "Invalid Command: Type " .. COLOR_YELLOW .. "'/ms help'" .. COLOR_VERMILLION .. " for a list of valid commands." .. COLOR_RESET)
    end
end

SLASH_MACROSETS1 = '/ms'
SlashCmdList['MACROSETS'] = HandleSlashCommands