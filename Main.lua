print("MacroSets loaded Successfully!")

MacroSetsDB = MacroSetsDB or {}

local isElvUI = IsAddOnLoaded("ElvUI")
local isBartender4 = IsAddOnLoaded("Bartender4")

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



local function GetActionBarSlotForMacro(macroName)
    for i = 1, 120 do  -- The total number of slots in WoW's default action bars
        local actionType, id = GetActionInfo(i)
        if actionType == "macro" then
            local name = GetMacroInfo(id)
            if name == macroName then
                return i  -- Return the slot number where the macro is found
            end
        end
    end
    return nil  -- Return nil if the macro is not found in any slot
end



local function PlaceMacroInActionBarSlot(macroId, actionBarSlot)
    if not macroId or not actionBarSlot then
        print("Invalid parameters for PlaceMacroInActionBarSlot")
        return
    end

    -- Ensure the slot is within valid range (usually 1-120 for standard action bars)
    if actionBarSlot < 1 or actionBarSlot > 120 then
        print("Action bar slot is out of range.")
        return
    end

    -- The API function PickUpMacro places a macro into the 'cursor' in the UI
    PickupMacro(macroId)

    -- The API function PlaceAction places whatever is on the cursor into a specified action bar slot
    PlaceAction(actionBarSlot)

    -- Clear the cursor after placing the macro
    ClearCursor()
end




local function SaveMacroSet(setName, macroType)
    if not IsValidSetName(setName) then return end
    -- Default to both if no macroType is specified
    macroType = macroType or "both"

    local startSlot, endSlot
    if macroType == "g" then
        startSlot, endSlot = 1, 120
    elseif macroType == "c" then
        startSlot, endSlot = 121, 138
    else  -- both
        startSlot, endSlot = 1, 138
    end

    local generalMacroCount = 0
    local characterMacroCount = 0

    MacroSetsDB[setName] = {macros = {}, type = macroType, generalCount = 0, characterCount = 0}
    for i = startSlot, endSlot do
        local name, icon, body = GetMacroInfo(i)
        if name then
            local actionBarSlot = GetActionBarSlotForMacro(name)

            table.insert(MacroSetsDB[setName].macros, {name = name, icon = icon, body = body, position = actionBarSlot})
            if i <= 120 then
                generalMacroCount = generalMacroCount + 1
            else
                characterMacroCount = characterMacroCount + 1
            end
        end
    end

    if generalMacroCount == 0 and characterMacroCount == 0 then
        print("There are no macros to save.")
        return
    end

    MacroSetsDB[setName].generalCount = generalMacroCount
    MacroSetsDB[setName].characterCount = characterMacroCount

    if (macroType == "g") then
        print("General Macro set saved as '" .. setName .. "'.")
    elseif (macroType == "c") then
        print("Character Macro set saved as '" .. setName .. "'.")
    elseif (macroType == "both") then
        print("Macro set saved as '" .. setName .. "'.")
    else
        print("Invalid macro set type.")
    end
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
    if macroFrameWasOpen then
        HideUIPanel(MacroFrame)
    end

    local macroSetType = MacroSetsDB[setName].type
    local macroSet = MacroSetsDB[setName].macros
    local startSlot, endSlot
    if macroSetType == "g" then
        startSlot, endSlot = 1, 120
    elseif macroSetType == "c" then
        startSlot, endSlot = 121, 138
    else  -- both
        startSlot, endSlot = 1, 138
    end

    -- Clearing macros in the specified range...
    for i = endSlot, startSlot, -1 do
        local macroName = GetMacroInfo(i)
        if macroName then
            DeleteMacro(i)
        end
    end

    local generalMacroCount = MacroSetsDB[setName].generalCount or 0
    local characterMacroCount = MacroSetsDB[setName].characterCount or 0
    for _, macro in ipairs(macroSet) do
        local macroId
        if generalMacroCount > 0 then
            macroId = CreateMacro(macro.name, macro.icon, macro.body)
            generalMacroCount = generalMacroCount - 1
        elseif characterMacroCount > 0 then
            macroId = CreateMacro(macro.name, macro.icon, macro.body, 1)  -- 1 for character-specific
            characterMacroCount = characterMacroCount - 1
        else
            print("No more macro slots available for this type.")
            break
        end
        if macroId and macro.position then
            PlaceMacroInActionBarSlot(macroId, macro.position)
        end
    end  
    
    if macroFrameWasOpen then
        ShowUIPanel(MacroFrame)
    end

    print("Macro set '" .. setName .. "' loaded.")
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
