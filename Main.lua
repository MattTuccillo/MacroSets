print("Macro Sets loaded Successfully!")

-- testing toggles for debugging --
local test = {
    allFunctions = false,
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
    toggleDynamicIcons = false
}

local actionBarSlotLimit = 180
MacroSetsDB = MacroSetsDB or {}
MacroSetsDB.dynamicIcons = MacroSetsDB.dynamicIcons or false

-- Create alphabetized macro set list for easier reference when listed --
local sortedSetNames = {}
local function AlphabetizeMacroSets()
    sortedSetNames = {}
    for setName in pairs(MacroSetsDB) do
        table.insert(sortedSetNames, setName)
    end
    table.sort(sortedSetNames)
end
AlphabetizeMacroSets()

local function ToggleDynamicIcons()

    if test.toggleDynamicIcons or test.allFunctions then
        print("ToggleDynamicIcons(): Function called.")
    end

    MacroSetsDB.dynamicIcons = not MacroSetsDB.dynamicIcons
    local status = MacroSetsDB.dynamicIcons and 'ON' or 'OFF'
    print("Dynamic macro icons toggled '" .. status .. "'.")
    if test.toggleDynamicIcons or test.allFunctions then
        print("ToggleDynamicIcons(): Toggled to " .. tostring(MacroSetsDB.dynamicIcons) .. ".")
    end

end

local function IsValidSetName(setName)

    if test.isValidSetName or test.allFunctions then
        print("IsValidSetName(): Function called.")
        print("IsValidSetName(): setName = " .. setName .. ".")
    end

    if not setName or setName == "" then
        print("Please enter a macro set name.")
        return false
    end

    if string.len(setName) > 50 then
        print("Macro set name is too long. There is a 50 character limit.")
        return false
    end

    if string.match(setName, "^[a-zA-Z0-9_-]+$") == nil then
        print("Invalid macro set name. Please use only alphanumeric characters, hyphens, and underscores.")
        return false
    end

    return true

end

local function GetActionBarSlotsForMacro(macroName)

    if test.getActionBarSlotsForMacro or test.allFunctions then
        print("GetActionBarSlotsForMacro(): Function called.")
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
            print("GetActionBarSlotsForMacro(): No slots found for " .. macroName .. ".")
        else
            local slotsString = "{"
            for i, slot in ipairs(slots) do
                slotsString = slotsString .. slot
                if i < #slots then
                    slotsString = slotsString .. ", "
                end
            end
            slotsString = slotsString .. "}"
            print("GetActionBarSlotsForMacro(): " .. macroName .. " found in slots: " .. slotsString)
        end
    end
    
    return slots

end

local function PlaceMacroInActionBarSlots(macroIndex, positions)

    local name, icon, body = GetMacroInfo(macroIndex)

    if test.placeMacroInActionBarSlots or test.allFunctions then
        print("PlaceMacroInActionBarSlots(): Function called.")
        print("PlaceMacroInActionBarSlots(): Placing " .. name .. ".")
    end

    for _, slot in ipairs(positions) do

        if test.placeMacroInActionBarSlots or test.allFunctions then
            print("PlaceMacroInActionBarSlots(): Trying slot: " .. slot .. ".")
        end

        if slot < 1 or slot > actionBarSlotLimit then
            print("Action bar slot " .. slot .. " is out of range.")
        else
            PickupMacro(macroIndex)
            PlaceAction(slot)
            ClearCursor()

            if test.placeMacroInActionBarSlots or test.allFunctions then
                local actionType, id = GetActionInfo(slot)
                if id == macroIndex then
                    print("PlaceMacroInActionBarSlots(): " .. name .. " successfully found slot " .. slot .. ".")
                else
                    print("PlaceMacroInActionBarSlots(): " .. name .. " failed to find slot " .. slot .. ".")
                end
            end

        end
    end

end

local function SetMacroSlotRanges(macroType)

    if test.setMacroSlotRanges or test.allFunctions then
        print("SetMacroSlotRanges(): Function called.")
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
        print("MacroSetIsEmpty(): Function called.")
        print("MacroSetIsEmpty(): " .. generalCount .. " general macros found.")
        print("MacroSetIsEmpty(): " .. characterCount .. " character macros found.")
        print("MacroSetIsEmpty(): " .. total .. " total macros found.")
    end

    if (macroType == "g" and generalCount == 0) or
        (macroType == "c" and characterCount == 0) or
        (generalCount == 0 and characterCount == 0) then
        print("No macros to save.")
        return false
    end

    return true

end

local function DisplaySetSavedMessage(setName, macroType)

    if test.displaySetSavedMessage or test.allFunctions then
        print("DisplaySetSavedMessage(): Function called.")
        print("DisplaySetSavedMessage(): macroType = " .. macroType .. ".")
    end

    if macroType == "g" then
        print("General Macro set saved as '" .. setName .. "'.")
    elseif macroType == "c" then
        print("Character Macro set saved as '" .. setName .. "'.")
    elseif macroType == "both" then
        print("Macro set saved as '" .. setName .. "'.")
    else
        print("Invalid macro set type.")
    end

end

local function DeleteMacrosInRange(startSlot, endSlot)

    if test.deleteMacrosInRange or test.allFunctions then
        print("DeleteMacrosInRange(): Function called.")
    end

    for i = endSlot, startSlot, -1 do
        local macroName = GetMacroInfo(i)
        if macroName then
            DeleteMacro(i)
        end
    end

    if test.deleteMacrosInRange or test.allFunctions then
        for i = startSlot, endSlot  do
            remainingMacros = {}
            local macroName = GetMacroInfo(i)
            if macroName then
                table.insert(remainingMacros, macroName)
            end
        end
        if #remainingMacros > 0 then
            print("DeleteMacrosInRange(): Remaining macros:")
            for i, name in ipairs(remainingMacros) do
                print("" .. name .. " found in slot " .. i .. ".")
            end
        else
            print("DeleteMacrosInRange(): Macros deleted successfully.")
        end
    end

end

local function RestoreMacroBodies(setName)

    if test.restoreMacroBodies or test.allFunctions then
        print("RestoreMacroBodies(): Function called.")
    end

    for _, macroDetails in ipairs(MacroSetsDB[setName].macros) do
        EditMacro(GetMacroIndexByName(macroDetails.name), macroDetails.name, macroDetails.icon, macroDetails.body)

        if test.restoreMacroBodies or test.allFunctions then
            if GetMacroBody(macroDetails.name) ~= macroDetails.body then
                print("RestoreMacroBodies(): Failes to restore macro body to " .. macroDetails.name .. ".")
            end
        end

    end

end

local function DeleteMacroSet(setName)

    if test.deleteMacroSet or test.allFunctions then
        print("DeleteMacroSet(): Function called.")
    end

    if not IsValidSetName(setName) then 
        return 
    end

    if not setName or setName == "" then
        print("Please provide a valid macro set name to delete.")
        return
    end

    if MacroSetsDB[setName] then
        MacroSetsDB[setName] = nil  -- Remove the macro set from the database
        print("Macro set '" .. setName .. "' has been deleted.")
        AlphabetizeMacroSets()
    else
        print("Macro set '" .. setName .. "' not found.")
    end

    if test.deleteMacroSet or test.allFunctions then
        if MacroSetsDB[setName] == nil then
            print("DeleteMacroSet(): Successfully deleted " .. setName .. ".")
        end
    end

end

local function DuplicateNames(array)

    if test.duplicateNames or test.allFunctions then
        print("DuplicateNames(): Function called.")
    end

    local seen = {}
    for _, value in ipairs(array) do
        if seen[value] then

            if test.duplicateNames or test.allFunctions then
                print("DuplicateNames(): Duplicate found: " .. value .. ".")
            end

            return true
        end
        seen[value] = true
    end

    if test.duplicateNames or test.allFunctions then
        print("DuplicateNames(): No duplicates found.")
    end

    return false

end

local function SaveMacroSet(setName, macroType)

    if test.saveMacroSet or test.allFunctions then
        print("SaveMacroSet(): Function called.")
    end

    if InCombatLockdown() then
        print("Cannot perform this action during combat.")
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
            print("Save interrupted. Please try again after leaving combat.")
            return
        end
        local name, icon, body = GetMacroInfo(i)
        if name then
            local endsWithD = string.sub(name, -2) == "#i"
            if MacroSetsDB.dynamicIcons and endsWithD then
                -- If dynamic icons are enabled and the name ends with "#i"
                icon = 134400
                if test.saveMacroSet or test.allFunctions then
                    print("SaveMacroSet(): Dynamic icon set for macro: " .. name ..".")
                end
            elseif not MacroSetsDB.dynamicIcons and not endsWithD then
                -- If dynamic icons are disabled and the name does not end with "#i"
                icon = 134400
                if test.saveMacroSet or test.allFunctions then
                    print("SaveMacroSet(): Dynamic icon set for macro: " .. name ..".")
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
        print("Failed to save set. All macros in a set must have unique names.")
    end
    if not MacroSetIsEmpty(generalMacroCount, characterMacroCount, macroType) or MacroSetsDB[setName].dupes == true then
        MacroSetsDB[setName] = nil
        return
    end

    DisplaySetSavedMessage(setName, macroType)
    AlphabetizeMacroSets()
    
    if test.saveMacroSet or test.allFunctions then
        if MacroSetsDB[setName] == nil then
            print("SaveMacroSet(): Failed to save " .. setName ..".")
        else
            print("SaveMacroSet(): Successfully saved " .. setName ..".")
        end
    end

end

local function LoadMacroSet(setName)

    if test.loadMacroSet or test.allFunctions then
        print("LoadMacroSet(): Function called.")
    end

    if InCombatLockdown() then
        print("Cannot perform this action during combat.")
        return
    end

    if not IsValidSetName(setName) then 
        return 
    end

    if not MacroSetsDB[setName] then
        print("Set does not exist.")
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
            print("Load interrupted. Please try again after leaving combat.")
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
            print("No more macro slots available for this type.")
            break
        end
        positions = macro.position or {}
        if macroIndex and #positions ~= 0 then
            PlaceMacroInActionBarSlots(macroIndex, positions)
        end
    end

    if test.loadMacroSet or test.allFunctions then
        for _, macro in ipairs(macroSet) do
            local name, icon, body = GetMacroInfo(macro.name)
            if macro.name ~= name then
                print("LoadMacroSet(): " .. macro.name .. " failed to load.")
            end
        end
    end

    RestoreMacroBodies(setName)

    if macroFrameWasOpen then 
        ShowUIPanel(MacroFrame) 
    end

    print("Macro set '" .. setName .. "' loaded.")

end

local function ListMacroSets()
    if test.listMacroSets or test.allFunctions then
        print("ListMacroSets(): Function called.")
    end

    if #sortedSetNames == 0 then
        print("No macro sets saved.")
        return
    end

    print("Saved Macro Sets:")
    for _, setName in ipairs(sortedSetNames) do
        local setDetails = MacroSetsDB[setName]
        if type(setDetails) == 'table' then
            local setType = setDetails.type
            local setTypeIndicator = setType == 'c' and "(C)" or setType == 'g' and "(G)" or "(B)"
            print("- " .. setTypeIndicator .. setName)
        end
    end
end



local function DisplayHelp()

    if test.displayHelp or test.allFunctions then
        print("DisplayHelp(): Function called.")
    end

    print("Macro Sets Addon - Help")
    print("/ms save [name] [type] - Save the current macro set with the specified name. Example: /ms save mySet g")
    print("- [name] 50 characters limit. No spaces.")
    print("- [type] Defaults to 'both' if omitted.")
    print("  - 'g' for general macros tab.")
    print("  - 'c' for character macros tab.")
    print("/ms load [name] - Load the macro set with the specified name.")
    print("/ms delete [name] - Delete the macro set with the specified name.")
    print("/ms list - List all saved macro sets.")
    print("- Sets will note the tab type they encompass.")
    print("/ms icons - Toggle what the '#i' flag does at the end of macro names.")
    print("- Toggled 'ON':")
    print("  - Macros with names that end with '#i' will be saved with the default/dynamic question mark icon.")
    print("  - All other macros will be saved with the first icon shown when placed on the action bar.")
    print("- Toggled 'OFF':")
    print("  - Macros with names that end with '#i' will be saved with the first icon shown when placed on the action bar.")
    print("  - All other macros will be saved with the default/dynamic question mark icon.")
    print("- Set to 'OFF' by default.")
    print("/ms help - Display this help message.")

end

local function DisplayDefault()

    if test.displayDefault or test.allFunctions then
        print("DisplayDefault(): Function called.")
    end

    print("Invalid Command: Type '/ms help' for a list of valid commands.")

end

local function HandleSlashCommands(msg)

    if test.handleSlashCommands or test.allFunctions then
        print("HandleSlashCommands(): Function called.")
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
        ListMacroSets()
    elseif command == 'icons' then
        ToggleDynamicIcons()
    elseif command == 'help' then
        DisplayHelp()
    else
        DisplayDefault()
    end

end

SLASH_MACROSETS1 = '/ms'
SlashCmdList['MACROSETS'] = HandleSlashCommands