-- Color codes
local COLOR_PURPLE = "|cFFCC79A7" -- testing messages
local COLOR_SKY_BLUE = "|cFF56B4E9" -- help section text
local COLOR_LIGHT_BLUE = "|cFFADD8E6" -- help section bullets
local COLOR_PINK = "|cFFF4B183" -- help section examples
local COLOR_YELLOW = "|cFFF0E442" -- help section commands
local COLOR_ORANGE = "|cFFE69F00" -- help section parameters
local COLOR_BLUE = "|cFF0072B2" -- heading dividers
local COLOR_VERMILLION = "|cFFD55E00" -- error message
local COLOR_GREEN = "|cFF009E73" -- success message
local COLOR_RESET = "|r" -- reset back to original color

-- Testing toggles for debugging --
local test = {
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
    displayDefault = false,
    isValidSetName = false,
    getActionBarSlotsForMacro = false,
    placeMacroInActionBarSlots = false,
    setMacroSlotRanges = false,
    macroSetIsEmpty = false,
    displaySetSavedMessage = false,
    deleteMacrosInRange = false,
    restoreMacroBodies = false,
    duplicateNames = false,
    optionsScreenToggle = false,
    handleSlashCommands = false,
}

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

-- Create alphabetized macro set list for easier reference when listed --
local sortedSetNames = {}
local actionBarSlotLimit = 180
MacroSetsFunctions = MacroSetsFunctions or {}
MacroSetsDB = MacroSetsDB or {}

if MacroSetsDB.dynamicIcons == nil then
    MacroSetsDB.dynamicIcons = false
end
if MacroSetsDB.replaceBars == nil then
    MacroSetsDB.replaceBars = true
end
if MacroSetsDB.charSpecific == nil then
    MacroSetsDB.charSpecific = false
end

MacroSetsBackup = MacroSetsBackup or {}

function MacroSetsFunctions.ToggleDynamicIcons()
    if test.toggleDynamicIcons or test.allFunctions then
        print(COLOR_PURPLE .. "ToggleDynamicIcons(): Function called." .. COLOR_RESET)
    end

    MacroSetsDB.dynamicIcons = not MacroSetsDB.dynamicIcons
    local status = MacroSetsDB.dynamicIcons and 'ON' or 'OFF'
    if test.toggleDynamicIcons or test.allFunctions then
        print(COLOR_PURPLE .. "ToggleDynamicIcons(): Toggled to " .. tostring(MacroSetsDB.dynamicIcons) .. "." .. COLOR_RESET)
    end
end

function MacroSetsFunctions.ToggleActionBarPlacements()
    if test.toggleActionBarPlacements or test.allFunctions then
        print(COLOR_PURPLE .. "ToggleActionBarPlacements(): Function called." .. COLOR_RESET)
    end

    MacroSetsDB.replaceBars = not MacroSetsDB.replaceBars
    local status = MacroSetsDB.replaceBars and 'ON' or 'OFF'
    if test.toggleActionBarPlacements or test.allFunctions then
        print(COLOR_PURPLE .. "ToggleActionBarPlacements(): Toggled to " .. tostring(MacroSetsDB.replaceBars) .. "." .. COLOR_RESET)
    end
end

function MacroSetsFunctions.ToggleCharSpecific()
    if test.toggleCharSpecific or test.allFunctions then
        print(COLOR_PURPLE .. "ToggleCharSpecific(): Function called." .. COLOR_RESET)
    end

    MacroSetsDB.charSpecific = not MacroSetsDB.charSpecific
    local status = MacroSetsDB.charSpecific and 'ON' or 'OFF'
    if test.toggleCharSpecific or test.allFunctions then
        print(COLOR_PURPLE .. "ToggleCharSpecific(): Toggled to " .. tostring(MacroSetsDB.charSpecific) .. "." .. COLOR_RESET)
    end
end

local function BackupMacroSets()
    if test.backupMacroSets or test.allFunctions then
        print(COLOR_PURPLE .. "BackupMacroSets(): Function called." .. COLOR_RESET)
    end

    MacroSetsBackup = {}
    for setName, setData in pairs(MacroSetsDB) do
        MacroSetsBackup[setName] = DeepCopyTable(setData)
    end

    if test.backupMacroSets or test.allFunctions then
        if next(MacroSetsBackup) == nil then
            print(COLOR_VERMILLION .. "BackupMacroSets(): Backup failed. No data copied." .. COLOR_RESET)
        else
            print(COLOR_GREEN .. "BackupMacroSets(): Backup successful. Macro sets copied." .. COLOR_RESET)
        end
    end
end

local function AlphabetizeMacroSets()
    if test.alphabetizeMacroSets or test.allFunctions then
        print(COLOR_PURPLE .. "AlphabetizeMacroSets(): Function called." .. COLOR_RESET)
    end
    sortedSetNames = {}
    for setName, setDetails in pairs(MacroSetsDB) do
        if type(setDetails) == 'table' and setDetails.macros then
            table.insert(sortedSetNames, setName)
        end
    end
    table.sort(sortedSetNames, function(a, b)
        return string.lower(a) < string.lower(b)
    end)
    if test.alphabetizeMacroSets or test.allFunctions then
        print(COLOR_PURPLE .. "AlphabetizeMacroSets():" .. COLOR_RESET)
        for _, setName in ipairs(sortedSetNames) do
            print(COLOR_PURPLE .. setName .. COLOR_RESET)
        end
    end
end

local function IsValidSetName(setName)
    if test.isValidSetName or test.allFunctions then
        print(COLOR_PURPLE .. "IsValidSetName(): Function called." .. COLOR_RESET)
        print(COLOR_PURPLE .. "IsValidSetName(): setName = " .. setName .. "." .. COLOR_RESET)
    end

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
    if test.getActionBarSlotsForMacro or test.allFunctions then
        print(COLOR_PURPLE .. "GetActionBarSlotsForMacro(): Function called." .. COLOR_RESET)
    end

    local slots = {}
    for i = 1, actionBarSlotLimit do
        local actionType, id = GetActionInfo(i)
        local name, icon, body = GetMacroInfo(id)
        if name == macroName then
            table.insert(slots, i)
        end
    end

    if test.getActionBarSlotsForMacro or test.allFunctions then
        if #slots == 0 then
            print(COLOR_PURPLE .. "GetActionBarSlotsForMacro(): No slots found for " .. macroName .. "." .. COLOR_RESET)
        else
            local slotsString = "{"
            for i, slot in ipairs(slots) do
                slotsString = slotsString .. slot
                if i < #slots then
                    slotsString = slotsString .. ", "
                end
            end
            slotsString = slotsString .. "}"
            print(COLOR_PURPLE .. "GetActionBarSlotsForMacro(): " .. macroName .. " found in slots: " .. slotsString .. COLOR_RESET)
        end
    end
    
    return slots
end

local function PlaceMacroInActionBarSlots(macroIndex, positions)
    local name, icon, body = GetMacroInfo(macroIndex)

    if test.placeMacroInActionBarSlots or test.allFunctions then
        print(COLOR_PURPLE .. "PlaceMacroInActionBarSlots(): Function called." .. COLOR_RESET)
        print(COLOR_PURPLE .. "PlaceMacroInActionBarSlots(): Placing " .. name .. "." .. COLOR_RESET)
    end

    for _, slot in ipairs(positions) do
        if test.placeMacroInActionBarSlots or test.allFunctions then
            print(COLOR_PURPLE .. "PlaceMacroInActionBarSlots(): Trying slot: " .. slot .. "." .. COLOR_RESET)
        end

        if slot < 1 or slot > actionBarSlotLimit then
            print(COLOR_VERMILLION .. "Action bar slot " .. slot .. " is out of range." .. COLOR_RESET)
        else
            PickupMacro(macroIndex)
            PlaceAction(slot)
            ClearCursor()

            if test.placeMacroInActionBarSlots or test.allFunctions then
                local actionType, id = GetActionInfo(slot)
                if id == macroIndex then
                    print(COLOR_PURPLE .. "PlaceMacroInActionBarSlots(): " .. name .. " successfully found slot " .. slot .. "." .. COLOR_RESET)
                else
                    print(COLOR_PURPLE .. "PlaceMacroInActionBarSlots(): " .. name .. " failed to find slot " .. slot .. "." .. COLOR_RESET)
                end
            end
        end
    end
end

local function SetMacroSlotRanges(macroType)
    if test.setMacroSlotRanges or test.allFunctions then
        print(COLOR_PURPLE .. "SetMacroSlotRanges(): Function called." .. COLOR_RESET)
    end

    if macroType == "g" then
        return 1, 120
    elseif macroType == "c" then
        return 121, 150
    else
        return 1, 150
    end
end

local function MacroSetIsEmpty(generalCount, characterCount, macroType)
    -- Test callback
    if test.macroSetIsEmpty or test.allFunctions then
        local total = generalCount + characterCount
        print(COLOR_PURPLE .. "MacroSetIsEmpty(): Function called." .. COLOR_RESET)
        print(COLOR_PURPLE .. "MacroSetIsEmpty(): " .. generalCount .. " general macros found." .. COLOR_RESET)
        print(COLOR_PURPLE .. "MacroSetIsEmpty(): " .. characterCount .. " character macros found." .. COLOR_RESET)
        print(COLOR_PURPLE .. "MacroSetIsEmpty(): " .. total .. " total macros found." .. COLOR_RESET)
    end

    if (macroType == "g" and generalCount == 0) or
        (macroType == "c" and characterCount == 0) or
        (generalCount == 0 and characterCount == 0) then
        return false
    end

    return true
end

local function DisplaySetSavedMessage(setName, macroType)
    -- Test callback
    if test.displaySetSavedMessage or test.allFunctions then
        print(COLOR_PURPLE .. "DisplaySetSavedMessage(): Function called." .. COLOR_RESET)
        print(COLOR_PURPLE .. "DisplaySetSavedMessage(): macroType = " .. macroType .. "." .. COLOR_RESET)
    end

    if macroType == "g" then
        print(COLOR_GREEN .. "General Macro set saved as '" .. setName .. "'." .. COLOR_RESET)
    elseif macroType == "c" then
        print(COLOR_GREEN .. "Character Macro set saved as '" .. setName .. "'." .. COLOR_RESET)
    elseif macroType == "both" then
        print(COLOR_GREEN .. "Macro set saved as '" .. setName .. "'." .. COLOR_GREEN)
    else
        print(COLOR_VERMILLION .. "Invalid macro set type." .. COLOR_RESET)
    end
end

local function DeleteMacrosInRange(startSlot, endSlot)
    if test.deleteMacrosInRange or test.allFunctions then
        print(COLOR_PURPLE .. "DeleteMacrosInRange(): Function called." .. COLOR_RESET)
    end

    for i = endSlot, startSlot, -1 do
        local macroName = GetMacroInfo(i)
        if macroName then
            DeleteMacro(i)
        end
    end

    if test.deleteMacrosInRange or test.allFunctions then
        local remainingMacros = {}
        for i = startSlot, endSlot do
            local macroName = GetMacroInfo(i)
            if macroName then
                table.insert(remainingMacros, macroName)
            end
        end
        if #remainingMacros > 0 then
            print(COLOR_PURPLE .. "DeleteMacrosInRange(): Remaining macros:" .. COLOR_RESET)
            for i, name in ipairs(remainingMacros) do
                print(COLOR_PURPLE .. name .. " found in slot " .. i .. "." .. COLOR_RESET)
            end
        else
            print(COLOR_PURPLE .. "DeleteMacrosInRange(): Macros deleted successfully." .. COLOR_RESET)
        end
    end
end

local function RestoreMacroBodies(setName)
    if test.restoreMacroBodies or test.allFunctions then
        print(COLOR_PURPLE .. "RestoreMacroBodies(): Function called." .. COLOR_RESET)
    end

    for _, macroDetails in ipairs(MacroSetsDB[setName].macros) do
        EditMacro(GetMacroIndexByName(macroDetails.name), macroDetails.name, macroDetails.icon, macroDetails.body)

        if test.restoreMacroBodies or test.allFunctions then
            if GetMacroBody(macroDetails.name) ~= macroDetails.body then
                print(COLOR_PURPLE .. "RestoreMacroBodies(): Failed to restore macro body to " .. macroDetails.name .. "." .. COLOR_RESET)
            end
        end
    end
end

local function DeleteMacroSet(setName)
    -- Test callback
    if test.deleteMacroSet or test.allFunctions then
        print(COLOR_PURPLE .. "DeleteMacroSet(): Function called." .. COLOR_RESET)
    end

    if not IsValidSetName(setName) then 
        return 
    end

    if not setName or setName == "" then
        print(COLOR_VERMILLION .. "Please provide a valid macro set name to delete." .. COLOR_RESET)
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

    -- Test callback
    if test.deleteMacroSet or test.allFunctions then
        if MacroSetsDB[setName] == nil then
            print(COLOR_PURPLE .. "DeleteMacroSet(): Successfully deleted " .. setName .. "." .. COLOR_RESET)
        end
    end
end

local function DeleteAllMacroSets()
    -- Test callback
    if test.deleteAllMacroSets or test.allFunctions then
        print(COLOR_PURPLE .. "DeleteAllMacroSets(): Function called." .. COLOR_RESET)
    end

    -- Backup current macro sets
    BackupMacroSets()

    -- Delete all macro sets
    for setName in pairs(MacroSetsDB) do
        if type(MacroSetsDB[setName]) == "table" then
            MacroSetsDB[setName] = nil
        end
    end

    print(COLOR_GREEN .. "All macro sets have been deleted." .. COLOR_RESET)

    -- Test callback
    if test.deleteAllMacroSets or test.allFunctions then
        local foundTable = false
        for setName in pairs(MacroSetsDB) do
            if type(MacroSetsDB[setName]) == "table" then
                foundTable = true
                break
            end
        end
        if foundTable then
            print(COLOR_PURPLE .. "DeleteAllMacroSets(): Failed to delete all macro sets." .. COLOR_RESET)
        else
            print(COLOR_PURPLE .. "DeleteAllMacroSets(): Successfully deleted all macro sets." .. COLOR_RESET)
        end
    end
end

local function DuplicateNames(array)
    -- Test callback
    if test.duplicateNames or test.allFunctions then
        print(COLOR_PURPLE .. "DuplicateNames(): Function called." .. COLOR_RESET)
    end

    local seen = {}
    for _, value in ipairs(array) do
        if seen[value] then
            -- Test callback
            if test.duplicateNames or test.allFunctions then
                print(COLOR_PURPLE .. "DuplicateNames(): Duplicate found: " .. value .. "." .. COLOR_RESET)
            end
            return true
        end
        seen[value] = true
    end

    -- Test callback
    if test.duplicateNames or test.allFunctions then
        print(COLOR_PURPLE .. "DuplicateNames(): No duplicates found." .. COLOR_RESET)
    end

    return false
end

local function SaveMacroSet(setName, macroType)
    -- Test callback
    if test.saveMacroSet or test.allFunctions then
        print(COLOR_PURPLE .. "SaveMacroSet(): Function called." .. COLOR_RESET)
    end

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
                -- Test callback
                if test.saveMacroSet or test.allFunctions then
                    print(COLOR_PURPLE .. "SaveMacroSet(): Dynamic icon set for macro: " .. name .. "." .. COLOR_RESET)
                end
            -- If dynamic icons are disabled and the name does not end with "#i"
            elseif not MacroSetsDB.dynamicIcons and not endsWithD then
                icon = 134400
                -- Test callback
                if test.saveMacroSet or test.allFunctions then
                    print(COLOR_PURPLE .. "SaveMacroSet(): Dynamic icon set for macro: " .. name .. "." .. COLOR_RESET)
                end
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
    if not MacroSetIsEmpty(generalMacroCount, characterMacroCount, macroType) then
        print(COLOR_VERMILLION .. "No macros to save." .. COLOR_RESET)
        return
    end

    -- Backup current macro sets
    BackupMacroSets()
    -- Insert new set into current database
    MacroSetsDB[setName] = tempMacroSet
    -- Display successful save message
    DisplaySetSavedMessage(setName, macroType)
    -- Alphabetize macro sets
    AlphabetizeMacroSets()
    
    -- Test callback
    if test.saveMacroSet or test.allFunctions then
        if MacroSetsDB[setName] == nil then
            print(COLOR_PURPLE .. "SaveMacroSet(): Failed to save " .. setName .."." .. COLOR_RESET)
        else
            print(COLOR_PURPLE .. "SaveMacroSet(): Successfully saved " .. setName .."." .. COLOR_RESET)
        end
    end
end

local function LoadMacroSet(setName)
    -- Test callback
    if test.loadMacroSet or test.allFunctions then
        print(COLOR_PURPLE .. "LoadMacroSet(): Function called." .. COLOR_RESET)
    end

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

    if test.loadMacroSet or test.allFunctions then
        for _, macro in ipairs(macroSet) do
            local name, icon, body = GetMacroInfo(macro.name)
            if macro.name ~= name then
                print(COLOR_PURPLE .. "LoadMacroSet(): " .. macro.name .. " failed to load." .. COLOR_RESET)
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

    if test.undoLastOperation or test.allFunctions then
        print(COLOR_PURPLE .. "UndoLastOperation(): Function called." .. COLOR_RESET)
    end

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

    if test.undoLastOperation or test.allFunctions then
        print(COLOR_PURPLE .. "UndoLastOperation(): Backup restored." .. COLOR_RESET)
    end
    print(COLOR_GREEN .. "Previous action successfully undone." .. COLOR_RESET)

    
end

local function ListMacroSets()
    if test.listMacroSets or test.allFunctions then
        print(COLOR_PURPLE .. "ListMacroSets(): Function called." .. COLOR_RESET)
    end

    if #sortedSetNames == 0 then
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
            local COLOR_BOTH_INDICATOR = "|cFFFFFF36(B)|r" -- both macro set type indicator
            local COLOR_GENERAL_INDICATOR = "|cFF36FF4C(G)|r" -- general macro set type indicator
            local COLOR_CHARACTER_INDICATOR = "|cFF58E5F5(C)|r" -- character macro set type indicator
            local setTypeIndicator = setType == 'c' and COLOR_CHARACTER_INDICATOR or setType == 'g' and COLOR_GENERAL_INDICATOR or COLOR_BOTH_INDICATOR
            -- local setTypeIndicator = setType == 'c' and "(C)" or setType == 'g' and "(G)" or "(B)"
            print(COLOR_GREEN .. "- " .. COLOR_RESET .. setTypeIndicator .. setName)
        end
    end
    print(COLOR_BLUE .. "==============================" .. COLOR_RESET)
end

local function OptionsScreenToggle()
    if test.optionsScreenToggle or test.allFunctions then
        print(COLOR_PURPLE .. "OptionsScreenToggle(): Function called." .. COLOR_RESET)
    end
    if SettingsPanel:GetCurrentCategory() == macroSetsCategory and SettingsPanel:IsShown() then
        SettingsPanel:Hide()
        if test.optionsScreenToggle or test.allFunctions then
            print(COLOR_PURPLE .. "OptionsScreenToggle(): Options screen hidden." .. COLOR_RESET)
        end
    else
        SettingsPanel:Hide()
        SettingsPanel:Show()
        Settings.OpenToCategory(macroSetsCategory:GetID())
        if test.optionsScreenToggle or test.allFunctions then
            print(COLOR_PURPLE .. "OptionsScreenToggle(): Options screen shown." .. COLOR_RESET)
        end
    end
end    

local function DisplayDefault()
    if test.displayDefault or test.allFunctions then
        print(COLOR_PURPLE .. "DisplayDefault(): Function called." .. COLOR_RESET)
    end

    print(COLOR_VERMILLION .. "Invalid Command: Type " .. COLOR_YELLOW .. "'/ms help'" .. COLOR_VERMILLION .. " for a list of valid commands." .. COLOR_RESET)
end

local function DisplayHelp(helpSection)
    if test.displayHelp or test.allFunctions then
        print(COLOR_PURPLE .. "DisplayHelp(): Function called." .. COLOR_RESET)
    end

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
        DisplayDefault()
    end
end

local function HandleSlashCommands(msg)
    if test.handleSlashCommands or test.allFunctions then
        print(COLOR_PURPLE .. "HandleSlashCommands(): Function called." .. COLOR_RESET)
    end

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
        DisplayDefault()
    end
end

SLASH_MACROSETS1 = '/ms'
SlashCmdList['MACROSETS'] = HandleSlashCommands
