# Changelog for Macro Sets WoW Addon

## Version 2.0.1 - [6/4/2025]

- Changes:
  - Fixed a bug relating to the persistence of backup macro sets across sessions.
- Supports World of Warcraft version 11.0.5.

## Version 2.0.0 - [3/7/2025]

- Features: (*Check **Commands** section for more information on all of the features listed below.*)
  - A configuration screen containing 3 toggles is now available in `Interface>AddOns>MacroSets`.
  - Ability to delete all of your macro sets with a single command.
  - Ability to undo the most recent `save`, `delete`, `deleteall`, or `undo` command.
  - Ability to toggle the default type when saving macro sets without a type flag.
  - In-depth and dynamic help command overhaul that changes content based on current configuration toggles.
- Changes:
  - `/ms bars` command has been removed. 
    - Functionality is now a toggle in the new MacroSets configuration screen.
  - `/ms icons` command has been removed.
    - Functionality is now a toggle in the new MacroSets configuration screen.
  - `/ms help` now prints a list of available commands with short descriptors.
    - `/ms help [command]` prints additional information on usage and functionality of a specific command.
  - `/ms list` now colorizes the set type indicators for easier differentiation.
- Commands:
  - `/ms deleteall`: Delete all macro sets.
    - Wipe them out, all of them.
  - `/ms undo`: Undo the most recent action (save, delete, deleteall, undo).
    - Some example scenarios:
      - Undo a `save` incase you accidentally overwrite an existing macro set.
      - Undo a `delete` incase you accidentally delete an existing macro set.
      - Undo a `deleteall` incase you accidentally deleted all of your existing macro sets.
      - Undo an `undo` incase you accidentally undid the thing you should actually have done.
    - Reiterating for emphasis, you only get **1** undo.
  - `/ms options`: Toggles the MacroSets configuration screen.
    - Contains toggles for:
      - Dynamic macro icons (previously `/ms icons`)
        - Toggled '**ON**':
          - Macros with names that end with `#i` will be saved with the default/dynamic question mark icon.
          - All other macros will be saved with the first icon shown when placed on the action bar.
        - Toggled '**OFF**':
          - Macros with names that end with `#i` will be saved with the first icon shown when placed on the action bar.
          - All other macros will be saved with the default/dynamic question mark icon.
        - Set to '**OFF**' by default.
      - Action bar placements (previously `/ms bars`)
        - Toggled '**ON**':
          - Macros will return to their saved action bar positions on load.
        - Toggled '**OFF**':
          - Macros will not return to their saved action bar positions on load.
        - Set to '**ON**' by default.
      - Default macro set types
        - Toggled '**ON**':
          - Macro sets only save the character specific tab by default.
        - Toggled '**OFF**':
          - Macro sets save both the general and the character specific tabs by default.
        - Set to '**OFF**' by default.
- Supports World of Warcraft version 11.1.0.

## Version 1.2.1 - [9/12/2024]

- Changes:
  - Updated macro slots limit to account for character specific macro slot increase.
- Supports World of Warcraft version 11.0.2.

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
