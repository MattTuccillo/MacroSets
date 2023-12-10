# Macro Sets Addon for Retail World of Warcraft

![Macro Sets Logo](/Media/Textures/LogoAddon.png)

## Description

Macro Sets is an addon for Retail World of Warcraft that allows players to manage and switch between sets of macros easily. This addon is particularly useful for players who use different sets of macros for various activities like PvE, PvP, roles, and/or specializations.

## Features

- Save and load macro sets.
- Automatically place macros in their saved action bar slots when loading a set
- Separate handling for general and character-specific macros.
- Easy-to-use slash commands for managing macro sets.

## Installation

1. Download the addon.
2. Extract the ZIP file.
3. Place the `MacroSets` folder into your `World of Warcraft\_retail_\Interface\AddOns` directory.
4. Restart World of Warcraft or reload your UI.

## Usage

- `/ms save [name] [type]`: Save the current macro set with the specified name. Example: /ms save mySet g.
  - `[name]` 50 characters limit. No spaces.
  - `[type]` Defaults to `"both"` if omitted.
    - `"g"`: Save general macros as a set.
    - `"c"`: Save character-specific macros as a set.
- `/ms load [name]`: Load a saved macro set.
- `/ms delete [name]`: Delete a saved macro set.
- `/ms list`: List all saved macro sets.
- `/ms help`: Display help information for the addon.

## Testing

I've implemented a simple testing framework to assist with debugging. It executes some additional code within each function in order to output useful information while the addon is running. The table below contains a list of booleans denoting whether or not a function should execute its test code. The table is setup so that it is easy to identify which functions are being toggled on or off and exists within Main.lua in the root directory of the addon.

```
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
    handleSlashCommands = false
}
```

## Author

Created by MattTuccillo

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- Fulgerul, author of the addon "Profiles: Macros" which hasn't been updated in many years, for providing the inspiration for this project.
- ChatGPT for troubleshooting.
- Dall-E for logo.
