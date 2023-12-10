print("MacroSets loaded Successfully!")

local testMode = false
local actionBarSlotLimit = 180

MacroSetsDB = MacroSetsDB or {}

local function IsValidSetName(setName)
    if not setName or setName == "" then
        print("Please enter a macro set name.")
        return false
    end

    if string.len(setName) > 25 then
        print("Macro set name is too long. There is a 25 character limit.")
        return false
    end

    if string.match(setName, "^[a-zA-Z0-9_-]+$") == nil then
        print("Invalid macro set name. Please use only alphanumeric characters, hyphens, and underscores.")
        return false
    end

    return true
end

local function GetActionBarSlotsForMacro(macroName)
    local slots = {}
    for i = 1, actionBarSlotLimit do
        local actionType, id = GetActionInfo(i)
        local name, icon, body = GetMacroInfo(id)
        if name == macroName then
            table.insert(slots, i)  -- Add the slot number where the macro is found
        end
    end
    if testMode then
        if #slots == 0 then
            print("No slots found for macro:", macroName)
        end
    end
    return slots
end

local function PlaceMacroInActionBarSlots(macroIndex, positions)
    local name, icon, body = GetMacroInfo(macroIndex)
    for _, slot in ipairs(positions) do
        if slot < 1 or slot > actionBarSlotLimit then
            print("Action bar slot " .. slot .. " is out of range.")
        else
            PickupMacro(macroIndex)
            PlaceAction(slot)
            ClearCursor()
        end
    end
end

local function SetMacroSlotRanges(macroType)
    if macroType == "g" then
        return 1, 120
    elseif macroType == "c" then
        return 121, 138
    else
        return 1, 138
    end
end

local function GenerateUniqueMacroName(index, name)
    local hexIdentifier = string.format("%02X", index)
    local truncatedName = string.sub(name, 1, 14)  -- Truncate the name to 14 characters
    local paddingLength = 14 - string.len(truncatedName)
    local paddedName = truncatedName .. string.rep("_", paddingLength)
    return paddedName .. hexIdentifier
end

local function EmptyMacroSet(generalCount, characterCount, macroType)
    if (macroType == "g" and generalCount == 0) or
        (macroType == "c" and characterCount == 0) or
        (generalCount == 0 and characterCount == 0) then
        print("No macros to save.")
        return false
    end
    return true  
end

local function DisplaySetSavedMessage(setName, macroType)
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
    for i = endSlot, startSlot, -1 do
        local macroName = GetMacroInfo(i)
        if macroName then
            DeleteMacro(i)
        end
    end
end

local function FixMacroBodies(setName)
    for _, macroDetails in ipairs(MacroSetsDB[setName].macros) do
        EditMacro(GetMacroIndexByName(macroDetails.name), macroDetails.name, macroDetails.icon, macroDetails.body)
    end
end

local function DeleteMacroSet(setName)
    if not IsValidSetName(setName) then return end
    if not setName or setName == "" then
        print("Please provide a valid macro set name to delete.")
        return
    end

    if MacroSetsDB[setName] then
        MacroSetsDB[setName] = nil  -- Remove the macro set from the database
        print("Macro set '" .. setName .. "' has been deleted.")
    else
        print("Macro set '" .. setName .. "' not found.")
    end
end

local function SaveMacroSet(setName, macroType)
    if not IsValidSetName(setName) then 
        return 
    end
    local macroType = macroType or "both"
    local startSlot, endSlot = SetMacroSlotRanges(macroType)
    local generalMacroCount = 0
    local characterMacroCount = 0
    MacroSetsDB[setName] = {macros = {}, type = macroType, generalCount = 0, characterCount = 0}
    for i = startSlot, endSlot do
        local name, icon, body = GetMacroInfo(i)
        local stashedChar = ""
        if name then
            local newName = GenerateUniqueMacroName(i, name)
            EditMacro(i, newName, icon, "", 1)
            local actionBarSlots = GetActionBarSlotsForMacro(newName)
            table.insert(MacroSetsDB[setName].macros, {name = newName, icon = icon, body = body, position = actionBarSlots})
            if i <= 120 then
                generalMacroCount = generalMacroCount + 1
            else
                characterMacroCount = characterMacroCount + 1
            end
        end
    end
    MacroSetsDB[setName].generalCount = generalMacroCount
    MacroSetsDB[setName].characterCount = characterMacroCount
    if not EmptyMacroSet(generalMacroCount, characterMacroCount, macroType) then
        MacroSetsDB[setName] = nil
        return
    end
    DisplaySetSavedMessage(setName, macroType)
end

local function LoadMacroSet(setName)
    if not IsValidSetName(setName) then 
        return 
    end
    if not MacroSetsDB[setName] then
        print("Set does not exist.")
        return
    end
    local macroFrameWasOpen = MacroFrame and MacroFrame:IsVisible()
    if macroFrameWasOpen then HideUIPanel(MacroFrame) end
    local macroSetType = MacroSetsDB[setName].type
    local macroSet = MacroSetsDB[setName].macros
    local startSlot, endSlot = SetMacroSlotRanges(macroSetType)
    DeleteMacrosInRange(startSlot, endSlot)
    local generalMacroCount = MacroSetsDB[setName].generalCount or 0
    local characterMacroCount = MacroSetsDB[setName].characterCount or 0
    for _, macro in ipairs(macroSet) do
        local macroIndex
        local positions
        if generalMacroCount > 0 then
            macroIndex = CreateMacro(macro.name, macro.icon, macro.body)
            generalMacroCount = generalMacroCount - 1
        elseif characterMacroCount > 0 then
            macroIndex = CreateMacro(macro.name, macro.icon, macro.body, 1)  -- 1 for character-specific
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
    FixMacroBodies(setName)
    if macroFrameWasOpen then 
        ShowUIPanel(MacroFrame) 
    end
    print("Macro set '" .. setName .. "' loaded.")
end

local function ListMacroSets()
    if next(MacroSetsDB) == nil then
        print("No macro sets saved.")
        return
    end

    print("Saved Macro Sets:")
    for setName, setDetails in pairs(MacroSetsDB) do
        local setType = setDetails.type
        if (setType == 'c') then
            print("- (C)" .. setName .. "")
        elseif (setType == 'g') then
            print("- (G)" .. setName .. "")
        else
            print("- (B)" .. setName .. "")
        end
    end
end

local function DisplayHelp()
    print("Macro Sets Addon - Help")
    print("/ms save [name] [type] - Save the current macro set with the specified name. Example: /ms save mySet g")
    print("- [type] options")
    print("  - 'g' for general tab.")
    print("  - 'c' for character tab.")
    print("  - 'both' for both.")
    print("  - Default is 'both'.")
    print("/ms load [name] - Load the macro set with the specified name.")
    print("/ms delete [name] - Delete the macro set with the specified name.")
    print("/ms list - List all saved macro sets.")
    print("- Sets will note the tab type they encompass.")
    print("/ms help - Display this help message.")
end

local function DisplayDefault()
    print("Invalid Command: Type '/ms help' for a list of valid commands.")
end

local function HandleSlashCommands(msg)
    -- Trim leading and trailing spaces
    msg = string.match(msg, "^%s*(.-)%s*$")

    local command, setName, macroType = strsplit(" ", msg)

    -- Converting the command to lower case for consistent comparison
    command = string.lower(command)

    if command == 'save' then
        SaveMacroSet(setName, macroType)
    elseif command == 'load' then
        LoadMacroSet(setName)
    elseif command == 'delete' then
        DeleteMacroSet(setName)
    elseif command == 'list' then
        ListMacroSets()
    elseif command == 'help' then
        DisplayHelp()
    else
        DisplayDefault()
    end
end



SLASH_MACROSETS1 = '/ms'
SlashCmdList['MACROSETS'] = HandleSlashCommands
