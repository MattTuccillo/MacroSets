-- Color codes
local COLOR_PURPLE = "|cFFCC79A7" -- testing messages
local COLOR_SKY_BLUE = "|cFF56B4E9" -- help section text
local COLOR_LIGHT_BLUE = "|cFFADD8E6" -- help section bullets
local COLOR_PINK = "|cFFF4B183" -- help section examples
local COLOR_YELLOW = "|cFFF0E442" -- help section commands
local COLOR_ORANGE = "|cFFE69F00" -- help section parameters
local COLOR_BLUE = "|cFF0072B2" -- headings
local COLOR_VERMILLION = "|cFFD55E00" -- error message
local COLOR_GREEN = "|cFF009E73" -- success message
local COLOR_RESET = "|r" -- reset back to original color

-- testing toggles for debugging --
local test = {
    allFunctions = false,
    alphabetizeMacroSets = false,
    saveMacroSet = false,
    loadMacroSet = false,
    deleteMacroSet = false,
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
    handleSlashCommands = false,
    toggleDynamicIcons = false,
    toggleActionBarPlacements = false,
}

local actionBarSlotLimit = 180
MacroSetsDB = MacroSetsDB or {}
MacroSetsDB.dynamicIcons = MacroSetsDB.dynamicIcons or false
MacroSetsDB.placeOnBars = MacroSetsDB.placeOnBars or true

-- Create alphabetized macro set list for easier reference when listed --
local sortedSetNames = {}

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

local function ToggleDynamicIcons()
    if test.toggleDynamicIcons or test.allFunctions then
        print(COLOR_PURPLE .. "ToggleDynamicIcons(): Function called." .. COLOR_RESET)
    end

    MacroSetsDB.dynamicIcons = not MacroSetsDB.dynamicIcons
    local status = MacroSetsDB.dynamicIcons and 'ON' or 'OFF'
    print("Dynamic macro icons toggled " .. COLOR_ORANGE .. "'" .. status .. "'" .. COLOR_RESET .. ".")
    if test.toggleDynamicIcons or test.allFunctions then
        print(COLOR_PURPLE .. "ToggleDynamicIcons(): Toggled to " .. tostring(MacroSetsDB.dynamicIcons) .. "." .. COLOR_RESET)
    end
end

local function ToggleActionBarPlacements()
    if test.toggleActionBarPlacements or test.allFunctions then
        print(COLOR_PURPLE .. "ToggleActionBarPlacements(): Function called." .. COLOR_RESET)
    end

    MacroSetsDB.placeOnBars = not MacroSetsDB.placeOnBars
    local status = MacroSetsDB.placeOnBars and 'OFF' or 'ON'
    print("Action bar placements on load toggled " .. COLOR_ORANGE .. "'" .. status .. "'" .. COLOR_RESET .. ".")
    if test.toggleActionBarPlacements or test.allFunctions then
        print(COLOR_PURPLE .. "ToggleActionBarPlacements(): Toggled to " .. tostring(MacroSetsDB.placeOnBars) .. "." .. COLOR_RESET)
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
        return 121, 138
    else
        return 1, 138
    end
end

local function MacroSetIsEmpty(generalCount, characterCount, macroType)
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
        print(COLOR_VERMILLION .. "No macros to save." .. COLOR_RESET)
        return false
    end

    return true
end

local function DisplaySetSavedMessage(setName, macroType)
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
        MacroSetsDB[setName] = nil  -- Remove the macro set from the database
        print(COLOR_GREEN .. "Macro set '" .. setName .. "' has been deleted." .. COLOR_RESET)
    else
        print(COLOR_VERMILLION .. "Macro set '" .. setName .. "' not found." .. COLOR_RESET)
    end

    if test.deleteMacroSet or test.allFunctions then
        if MacroSetsDB[setName] == nil then
            print(COLOR_PURPLE .. "DeleteMacroSet(): Successfully deleted " .. setName .. "." .. COLOR_RESET)
        end
    end
end

local function DuplicateNames(array)
    if test.duplicateNames or test.allFunctions then
        print(COLOR_PURPLE .. "DuplicateNames(): Function called." .. COLOR_RESET)
    end

    local seen = {}
    for _, value in ipairs(array) do
        if seen[value] then
            if test.duplicateNames or test.allFunctions then
                print(COLOR_PURPLE .. "DuplicateNames(): Duplicate found: " .. value .. "." .. COLOR_RESET)
            end
            return true
        end
        seen[value] = true
    end

    if test.duplicateNames or test.allFunctions then
        print(COLOR_PURPLE .. "DuplicateNames(): No duplicates found." .. COLOR_RESET)
    end

    return false
end

local function SaveMacroSet(setName, macroType)
    if test.saveMacroSet or test.allFunctions then
        print(COLOR_PURPLE .. "SaveMacroSet(): Function called." .. COLOR_RESET)
    end

    if InCombatLockdown() then
        print(COLOR_VERMILLION .. "Cannot perform this action during combat." .. COLOR_RESET)
        return
    end

    if not IsValidSetName(setName) then 
        return 
    end

    local macroType = macroType
    if macroType ~= "c" and macroType ~= "g" then
        macroType = "both"
    end
    local startSlot, endSlot = SetMacroSlotRanges(macroType)
    local generalMacroCount = 0
    local characterMacroCount = 0
    local dupes = false
    local namesCache = {}
    MacroSetsDB[setName] = {macros = {}, type = macroType, generalCount = 0, characterCount = 0, dupes = dupes}
    for i = startSlot, endSlot do
        if InCombatLockdown() then
            print(COLOR_VERMILLION .. "Save interrupted. Please try again after leaving combat." .. COLOR_RESET)
            return
        end
        local name, icon, body = GetMacroInfo(i)
        if name then
            local endsWithD = string.sub(name, -2) == "#i"
            if MacroSetsDB.dynamicIcons and endsWithD then
                -- If dynamic icons are enabled and the name ends with "#i"
                icon = 134400
                if test.saveMacroSet or test.allFunctions then
                    print(COLOR_PURPLE .. "SaveMacroSet(): Dynamic icon set for macro: " .. name .. "." .. COLOR_RESET)
                end
            elseif not MacroSetsDB.dynamicIcons and not endsWithD then
                -- If dynamic icons are disabled and the name does not end with "#i"
                icon = 134400
                if test.saveMacroSet or test.allFunctions then
                    print(COLOR_PURPLE .. "SaveMacroSet(): Dynamic icon set for macro: " .. name .. "." .. COLOR_RESET)
                end
            end
            EditMacro(i, name, icon, "", 1)
            local actionBarSlots = GetActionBarSlotsForMacro(name)
            EditMacro(i, name, icon, body, 1)
            table.insert(MacroSetsDB[setName].macros, {name = name, icon = icon, body = body, position = actionBarSlots})
            table.insert(namesCache, name)
            if i <= 120 then
                generalMacroCount = generalMacroCount + 1
            else
                characterMacroCount = characterMacroCount + 1
            end
        end
    end
    MacroSetsDB[setName].dupes = DuplicateNames(namesCache)
    MacroSetsDB[setName].generalCount = generalMacroCount
    MacroSetsDB[setName].characterCount = characterMacroCount

    if MacroSetsDB[setName].dupes == true then
        print(COLOR_VERMILLION .. "Failed to save set. All macros in a set must have unique names." .. COLOR_RESET)
    end
    if not MacroSetIsEmpty(generalMacroCount, characterMacroCount, macroType) or MacroSetsDB[setName].dupes == true then
        MacroSetsDB[setName] = nil
        return
    end

    DisplaySetSavedMessage(setName, macroType)
    AlphabetizeMacroSets()
    
    if test.saveMacroSet or test.allFunctions then
        if MacroSetsDB[setName] == nil then
            print(COLOR_PURPLE .. "SaveMacroSet(): Failed to save " .. setName .."." .. COLOR_RESET)
        else
            print(COLOR_PURPLE .. "SaveMacroSet(): Successfully saved " .. setName .."." .. COLOR_RESET)
        end
    end
end

local function LoadMacroSet(setName)
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
        if MacroSetsDB.placeOnBars == false then
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

local function ListMacroSets()
    if test.listMacroSets or test.allFunctions then
        print(COLOR_PURPLE .. "ListMacroSets(): Function called." .. COLOR_RESET)
    end

    if #sortedSetNames == 0 then
        print(COLOR_VERMILLION .. "No macro sets saved." .. COLOR_RESET)
        return
    end

    print(COLOR_GREEN .. "Saved Macro Sets:" .. COLOR_RESET)
    for _, setName in ipairs(sortedSetNames) do
        local setDetails = MacroSetsDB[setName]
        if type(setDetails) == 'table' and setDetails.macros then
            local setType = setDetails.type
            local setTypeIndicator = setType == 'c' and "(C)" or setType == 'g' and "(G)" or "(B)"
            print(COLOR_GREEN .. "- " .. COLOR_RESET .. setTypeIndicator .. setName)
        end
    end
end

local function DisplayHelp()
    if test.displayHelp or test.allFunctions then
        print(COLOR_PURPLE .. "DisplayHelp(): Function called." .. COLOR_RESET)
    end

    print(COLOR_BLUE .. "Macro Sets Addon - Help" .. COLOR_RESET)
    print(COLOR_YELLOW .. "/ms save [name] [type]" .. COLOR_SKY_BLUE .. " - Save the current macro set with the specified name." .. COLOR_RESET) 
    print(COLOR_PINK .. "  Example: /ms save mySet g" .. COLOR_RESET)
    print(COLOR_LIGHT_BLUE .. "- " .. COLOR_ORANGE .. "[name]" .. COLOR_LIGHT_BLUE .. " 50 characters limit. No spaces." .. COLOR_RESET)
    print(COLOR_LIGHT_BLUE .. "- " .. COLOR_ORANGE .. "[type]" .. COLOR_LIGHT_BLUE .. " Defaults to " .. COLOR_ORANGE .. "'both'" .. COLOR_LIGHT_BLUE .." if omitted." .. COLOR_RESET)
    print(COLOR_LIGHT_BLUE .. "  - " .. COLOR_ORANGE .. "'g'" .. COLOR_LIGHT_BLUE .. " for general macros tab." .. COLOR_RESET)
    print(COLOR_LIGHT_BLUE .. "  - " .. COLOR_ORANGE .. "'c'" .. COLOR_LIGHT_BLUE .. " for character macros tab." .. COLOR_RESET)
    print(COLOR_YELLOW .. "/ms load [name]" .. COLOR_SKY_BLUE .. " - Load the macro set with the specified name." .. COLOR_RESET)
    print(COLOR_YELLOW .. "/ms delete [name]" .. COLOR_SKY_BLUE .. " - Delete the macro set with the specified name." .. COLOR_RESET)
    print(COLOR_YELLOW .. "/ms list" .. COLOR_SKY_BLUE .. " - List all saved macro sets." .. COLOR_RESET)
    print(COLOR_LIGHT_BLUE .. "- Sets will note the tab type they encompass." .. COLOR_RESET)
    print(COLOR_LIGHT_BLUE .. "- Sets will be alphabetized." .. COLOR_RESET)
    print(COLOR_YELLOW .. "/ms bars" .. COLOR_SKY_BLUE .. " - Toggle whether you want the macros to return to their saved action bar positions on load." .. COLOR_RESET)
    print(COLOR_LIGHT_BLUE .. "- Set to " .. COLOR_ORANGE .. "'ON'" .. COLOR_LIGHT_BLUE .. " by default." .. COLOR_RESET)
    print(COLOR_LIGHT_BLUE .. "- Due to the nature of the addon, setting to " .. COLOR_ORANGE .. "'OFF'" .. COLOR_LIGHT_BLUE .. " means all macros will be removed from bars on load." .. COLOR_RESET)
    print(COLOR_YELLOW .. "/ms icons" .. COLOR_SKY_BLUE .. " - Toggle what the '#i' flag does at the end of macro names." .. COLOR_RESET)
    print(COLOR_LIGHT_BLUE .. "- Toggled " .. COLOR_ORANGE .. "'ON'" .. COLOR_LIGHT_BLUE .. ":" .. COLOR_RESET)
    print(COLOR_LIGHT_BLUE .. "  - Macros with names that end with ".. COLOR_ORANGE .. "'#i'" .. COLOR_LIGHT_BLUE .. " will be saved with the default/dynamic question mark icon." .. COLOR_RESET)
    print(COLOR_LIGHT_BLUE .. "  - All other macros will be saved with the first icon shown when placed on the action bar." .. COLOR_RESET)
    print(COLOR_LIGHT_BLUE .. "- Toggled " .. COLOR_ORANGE .. "'OFF'" .. COLOR_LIGHT_BLUE .. ":" .. COLOR_RESET)
    print(COLOR_LIGHT_BLUE .. "  - Macros with names that end with " .. COLOR_ORANGE .. "'#i'" .. COLOR_LIGHT_BLUE .. " will be saved with the first icon shown when placed on the action bar." .. COLOR_RESET)
    print(COLOR_LIGHT_BLUE .. "  - All other macros will be saved with the default/dynamic question mark icon." .. COLOR_RESET)
    print(COLOR_LIGHT_BLUE .. "- Set to " .. COLOR_ORANGE .. "'OFF'" .. COLOR_LIGHT_BLUE .. " by default." .. COLOR_RESET)
    print(COLOR_YELLOW .. "/ms help" .. COLOR_SKY_BLUE .. " - Display this help message." .. COLOR_RESET)
end

local function DisplayDefault()
    if test.displayDefault or test.allFunctions then
        print(COLOR_PURPLE .. "DisplayDefault(): Function called." .. COLOR_RESET)
    end

    print(COLOR_VERMILLION .. "Invalid Command: Type " .. COLOR_YELLOW .. "'/ms help'" .. COLOR_VERMILLION .. " for a list of valid commands." .. COLOR_RESET)
end

local function HandleSlashCommands(msg)
    if test.handleSlashCommands or test.allFunctions then
        print(COLOR_PURPLE .. "HandleSlashCommands(): Function called." .. COLOR_RESET)
    end

    msg = string.match(msg, "^%s*(.-)%s*$")
    local command, setName, macroType = strsplit(" ", msg)
    command = string.lower(command)

    if command == 'save' then
        SaveMacroSet(setName, macroType)
    elseif command == 'load' then
        LoadMacroSet(setName)
    elseif command == 'delete' then
        DeleteMacroSet(setName)
    elseif command == 'list' then
        AlphabetizeMacroSets()
        ListMacroSets()
    elseif command == 'icons' then
        ToggleDynamicIcons()
    elseif command == 'bars' then
        ToggleActionBarPlacements()
    elseif command == 'help' then
        DisplayHelp()
    else
        DisplayDefault()
    end
end

SLASH_MACROSETS1 = '/ms'
SlashCmdList['MACROSETS'] = HandleSlashCommands
