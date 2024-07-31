# Changelog for Macro Sets WoW Addon

## Version 1.2.0 - [7/30/2024]

- Features:
  - Ability to toggle action bar placements on set load.
  - Alphabetization of macro sets list.
  - Added color to text for easier readability.
- Changes:
  - Alphabetized macro set list for easier referencing.
  - Removed the "MacroSets loaded Successfully" message on addon initialization.
  - Added help information for `/ms bars` to `/ms help`.
- Commands:
  - `/ms bars`: Toggles whether the macros will be placed on their saved action bar positions on load.
    - Toggled '**ON**':
      - Macros will return to their saved action bar positions on load.
    - Toggled '**OFF**':
      - All macros pertaining to the sets scope will be removed from the action bars on load.
    - Set to '**ON**' by default.
- Supports World of Warcraft version 11.0.0.

## Version 1.1.0 - [12/18/2023]

- Features:
  - Macro action bar positions are saved with set.
  - Macros are placed on action bars on set load.
  - Confirmed working with Bartender4 and ElvUI.
- Changes:
  - Macro set name character limit increased from **25** to **50**.
  - Checks to restrict addon usage during combat.
  - Checks for duplicate macro names when saving a set.
  - Added help information for `/ms icons` to `/ms help`.
- Commands:
  - `/ms icons`: Toggles what the `#i` flag does at the end of macro names
    - Toggled '**ON**':
      - Macros with names that end with `#i` will be saved with the default/dynamic question mark icon.
      - All other macros will be saved with the first icon shown when placed on the action bar.
    - Toggled '**OFF**':
      - Macros with names that end with `#i` will be saved with the first icon shown when placed on the action bar.
      - All other macros will be saved with the default/dynamic question mark icon.
    - Set to '**OFF**' by default.
- Added simple testing framework to aid with debugging.
- Substantial code refactoring.

## Version 1.0.0 - [12/2/2023]

- Initial release of the addon.
- Features:
  - Save and load macro sets.
  - Separate handling for general and character-specific macros.
  - Validation for macro set names.
- Commands:
  - `/ms save [name] [type]`: Save macros as a set, with type options 'g', 'c', or 'both'.
  - `/ms load [name]`: Load a macro set.
  - `/ms delete [name]`: Delete a macro set.
  - `/ms list`: List all saved macro sets.
  - `/ms help`: Display help message.
- Supports World of Warcraft version 10.2.0.
