# Changelog for Macro Sets WoW Addon

## Version 1.1.0 - [TBD]

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
    - Set all macro icons to the default icon when saved if toggled to `on`.
    - Set all macro icons to the currently displayed icon when saved if toggled `off`.
    - Set to `off` by default.
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
