print("MacroSets loaded Successfully!")

MacroSetsDB = MacroSetsDB or {}

local function IsValidSetName(setName)
    if not setName or setName == "" then
        print("Please provide a valid macro set name.")
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

local function SaveMacroSet(setName, macroType)
    if not IsValidSetName(setName) then return end
    -- Default to both if no macroType is specified
    macroType = macroType or "both"

    if not setName or setName == "" then
        print("Please provide a name for the macro set.")
        return
    end

    local startSlot, endSlot
    if macroType == "g" then
        startSlot, endSlot = 1, 120
    elseif macroType == "c" then
        startSlot, endSlot = 121, 138
    else  -- both
        startSlot, endSlot = 1, 138
    end

    MacroSetsDB[setName] = {macros = {}, type = macroType}
    for i = startSlot, endSlot do
        local name, icon, body = GetMacroInfo(i)
        if name then
            table.insert(MacroSetsDB[setName].macros, {name = name, icon = icon, body = body})
        end
    end

    if (macroType == "g") then
        print("General Macro set saved as '" .. setName .. "'.")
    elseif (macroType == "c") then
        print("Character Specific Macro set saved as '" .. setName .. "'.")
    elseif (macroType == "both") then
        print("Macro set saved as '" .. setName .. "'.")
    else
        print("Invalid macro set type.")
    end
end


local function LoadMacroSet(setName)
    if not IsValidSetName(setName) then return end
    local macroFrameWasOpen = MacroFrame and MacroFrame:IsVisible()
    if macroFrameWasOpen then
        HideUIPanel(MacroFrame)
    end

    if not setName or setName == "" or not MacroSetsDB[setName] then
        print("Invalid macro set name or set does not exist.")
        return
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

    local macroSlot = startSlot
    for _, macro in ipairs(macroSet) do
        if macroSlot > 138 then
            print("Not enough character-specific macro slots available.")
            break
        end
        CreateMacro(macro.name, macro.icon, macro.body, 1)  -- The 1 indicates a per-character macro
        macroSlot = macroSlot + 1
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
        print("- " .. setName .. " (Type: " .. setType .. ")")
    end
end



local function DisplayHelp()
    print("Macro Sets Addon - Help")
    print("/ms save [name] [type] - Save the current macro set with the specified name. Type can be 'g' for general, 'c' for character, or 'both'. Default is 'both'.")
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
