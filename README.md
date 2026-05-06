# Macro Sets Addon for Retail World of Warcraft

![Macro Sets Logo](/Media/Textures/LogoAddon.png)

## Description

Macro Sets is an addon for Retail World of Warcraft that allows players to manage and switch between sets of macros easily. This addon is particularly useful for players who use different sets of macros for various activities like PvE, PvP, roles, and/or specializations.

## Features

- Save and load macro sets.
- Ability to have macros automatically placed in their saved action bar slots when loading a set.
- Separate handling for general and character-specific macros.
- Easy-to-use slash commands for managing macro sets.
- Control over how macro icons are stored and set.
- Undo command in case you make a mistake.
- Import and export individual macros from the macro window.

## Installation

1. Download the addon.
2. Extract the ZIP file.
3. Place the `MacroSets` folder into your `World of Warcraft\_retail_\Interface\AddOns` directory.
4. Reload your UI or restart World of Warcraft

## Usage

- `/ms save [name] [type]`: Save the current macro set with the specified name. 
- `/ms load [name]`: Load the macro set with the specified name.
- `/ms delete [name]`: Delete the macro set with the specified name.
- `/ms deleteall`: Delete all saved macro sets.
- `/ms undo`: Undo the last eligible action.
- `/ms list`: List all saved macro sets.
- `/ms options`: Toggle the options screen.
- `/ms help`: Display this list of available commands.
- `/ms help [command]`: Display detailed information about a specific command.

The macro window also includes Macro Sets import and export buttons. Export selects a shareable string for the currently selected macro. Import opens a text box where you can paste a Macro Sets export string and create the macro.

## Explanation for dynamic icon toggle setting

In this section I'll provide a visual example of the way the dynamic icon toggle setting affects the addon's functionality as well as an explanation for why it had to exist in the first place.

### Why it was necessary

Due to the limitations of WOW's API I was unable to devise a method that would allow me to save the user's chosen icon, only the icon that is shown when the macro is placed on the action bar. My thinking was that the next best approach would be to manually set all icons to the default question mark icon so they would naturally retake the most fitting icon. Unfortunately, that would cause issues for people who choose specific icons for their macros. As a final solution I opted for the `#i` tag. It's a minor inconvenience however I implemented the toggle that would invert the flags rules so that if you are a person who prefers to use the dynamic icon 9 times out of 10, then you can pick the option that defaults to the dynamic icon. If you are a person who prefers to use their own chosen icon 9 times out of 10, then you can pick the option that defaults to the displayed icon when saved. I'm aware it's not as user friendly of a solution and I've supplied examples to provide a better understanding of the way it works but I did my best to handle this in as graceful a manner as I could while retaining functionality and customizability for the user.

### Example

#### Initial macros

- ![Example Initial](/Media/Textures/ExINIT.jpg)
- both macros are using a custom selected icon
- both macro bodies are the same
  - ```
    #showtooltip
    /cast Lightning Bolt
    ```
- the macro 'B' on the right has the `#i` flag at the end of the name

#### Saved while toggled 'ON'

- ![Example ON](/Media/Textures/ExON.jpg)
- macro without #i flag retained its chosen icon
- macro with #i flag was given the dynamic icon and it defaulted to the Lightning Bolt icon

#### Saved while toggled 'OFF'

- ![Example OFF](/Media/Textures/ExOFF.jpg)
- macro with #i flag retained its chosen icon
- macro without #i flag was given the dynamic icon and it defaulted to the Lightning Bolt icon

## Development checks

This repository includes a luacheck configuration for the addon Lua files and a small Java/LuaJ test harness for internal validation. These checks are for development only and are excluded from release ZIP artifacts.

Run Lua linting from the repository root:

```
luacheck Main.lua Options.lua
```

Run the internal Java/LuaJ tests from the `Tests` directory:

```
mvn test
```

## Author

Created by MattTuccillo

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- Fulgerul, author of the addon "Profiles: Macros" which hasn't been updated in many years, for providing the inspiration for this project.
- ChatGPT for troubleshooting.
- Dall-E for logo.
