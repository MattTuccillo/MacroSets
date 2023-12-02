print("MacroSets loaded Successfully!")

local function DisplayHelp()
    print("Macro Sets Addon - Help")
    print("/ms save [name] - Save the current macro set with the specified name.")
    print("/ms load [name] - Load the macro set with the specified name.")
    print("/ms delete [name] - Delete the macro set with the specified name.")
    print("/ms list - List all saved macro sets.")
    print("/ms help - Display this help message.")
end

local function DisplayDefault()
    print("Invalid Command: Type '/ms help' for a list of valid commands.")
end

local function HandleSlashCommands(msg)
    local command, setName = strsplit(" ", msg, 2)

    if command == 'save' and setName then
        print("/ms save path")
    elseif command == 'load' and setName then
        print("/ms load path")
    elseif command == 'delete' and setName then
        print("/ms delete path")
    elseif command == 'list' then
        print("/ms list path")
    elseif command == 'help' then
        DisplayHelp()
    else
        DisplayDefault()
    end
end

SLASH_MACROSETS1 = '/ms'
SlashCmdList['MACROSETS'] = HandleSlashCommands
