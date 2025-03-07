-- Create a configuration frame for the addon settings UI
macroSetsOptionsPanel = CreateFrame("Frame", "MacroSetsOptionsPanel", UIParent, "BackdropTemplate")

macroSetsOptionsPanel.name = "MacroSets"
local screenWidth = GetScreenWidth()
local screenHeight = GetScreenHeight()
macroSetsOptionsPanel:SetSize(screenWidth * 0.4, screenHeight * 0.6)
macroSetsOptionsPanel:SetPoint("CENTER")

-- Title for the options panel
local title = macroSetsOptionsPanel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
title:SetPoint("TOPLEFT", 16, -16)
title:SetText("MacroSets Configuration")

-- Create a sub-frame for the checkboxes
local checkboxesFrame = CreateFrame("Frame", "CheckboxesFrame", macroSetsOptionsPanel)
checkboxesFrame:SetSize(screenWidth * 0.9 * 0.4, screenHeight * 0.7 * 0.6)
checkboxesFrame:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -20)

-- Helper function to create a checkbox with a label and tooltip
local function CreateCheckbox(parent, name, labelText, tooltipText, offsetX, offsetY)
    local checkbox = CreateFrame("CheckButton", name, parent, "InterfaceOptionsCheckButtonTemplate")
    checkbox:SetPoint("TOPLEFT", parent, "TOPLEFT", offsetX, offsetY)
    checkbox.text = _G[checkbox:GetName() .. "Text"]
    checkbox.text:SetFontObject("GameFontNormalLarge")
    checkbox.text:SetText(labelText)
    checkbox.tooltip = tooltipText
    return checkbox
end

-- Helper function to create help text under checkboxes
local function CreateHelpText(parent, referenceCheckbox, helpText, offsetX, offsetY)
    local help = parent:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    help:SetWidth(screenWidth * 0.35 * 0.9)
    help:SetWordWrap(true)
    help:SetJustifyH("LEFT")
    help:SetPoint("TOPLEFT", referenceCheckbox, "BOTTOMLEFT", offsetX, offsetY)
    help:SetText(helpText)
    return help
end

-- Create checkboxes for addon settings with accompanying help text
local dynamicIconsCheckbox = CreateCheckbox(checkboxesFrame, "DynamicIconsCheckbox", "Save initial macro icon", "Toggle whether macro icons should default to the question mark dynamic icon or the first icon that is set when saved", 10, -10)
local dynamicIconsHelpText = CreateHelpText(checkboxesFrame, dynamicIconsCheckbox, "", 0, -5)

local replaceBarsCheckbox = CreateCheckbox(checkboxesFrame, "ReplaceBarsCheckbox", "Place loaded macros on action bars", "Toggle whether macros should be placed on action bars when a macro set is loaded.", 10, -80)
local replaceBarsHelpText = CreateHelpText(checkboxesFrame, replaceBarsCheckbox, "", 0, -5)

local charSpecificCheckbox = CreateCheckbox(checkboxesFrame, "CharSpecificCheckbox", "Save as character-specific macro set by default", "Toggle whether macro sets are saved as character-specific sets when not specified.", 10, -150)
local charSpecificHelpText = CreateHelpText(checkboxesFrame, charSpecificCheckbox, "", 0, -5)

-- Function to initialize settings if they are not already defined
local function initializeSettings()
    if MacroSetsDB.dynamicIcons == nil then
        MacroSetsDB.dynamicIcons = false
    end
    if MacroSetsDB.replaceBars == nil then
        MacroSetsDB.replaceBars = true
    end
    if MacroSetsDB.charSpecific == nil then
        MacroSetsDB.charSpecific = false
    end
end

-- Function to save the current values of the checkboxes
local function saveSettings()
    if not MacroSetsDB then MacroSetsDB = {} end
    MacroSetsDB.dynamicIcons = dynamicIconsCheckbox:GetChecked()
    MacroSetsDB.replaceBars = replaceBarsCheckbox:GetChecked()
    MacroSetsDB.charSpecific = charSpecificCheckbox:GetChecked()
end

-- Function to update help text descriptions based on current checkbox states
local function updateHelpText()
    if MacroSetsDB.dynamicIcons then
        dynamicIconsHelpText:SetText("All macros are saved with the currently shown icon unless there is a '#i' at the end of the macro name.")
    else
        dynamicIconsHelpText:SetText("All macros are saved with the |T134400:0|t icon unless there is a '#i' at the end of the macro name.")
    end

    if MacroSetsDB.replaceBars then
        replaceBarsHelpText:SetText("Macros will be placed on your action bars when a macro set is loaded.")
    else
        replaceBarsHelpText:SetText("Macros will not be placed on your action bars when a macro set is loaded.")
    end

    if MacroSetsDB.charSpecific then
        charSpecificHelpText:SetText("Macro sets will be saved as character-specific by default when not specified.")
    else
        charSpecificHelpText:SetText("Macro sets will be saved as account-wide by default when not specified.")
    end
end

-- Function to load saved settings into the checkboxes
local function loadSettings()
    initializeSettings()
    dynamicIconsCheckbox:SetChecked(MacroSetsDB.dynamicIcons)
    replaceBarsCheckbox:SetChecked(MacroSetsDB.replaceBars)
    charSpecificCheckbox:SetChecked(MacroSetsDB.charSpecific)
    updateHelpText()
end

-- Set scripts for checkbox interactions
dynamicIconsCheckbox:SetScript("OnClick", function(self)
    MacroSetsFunctions.ToggleDynamicIcons()
    saveSettings()
    updateHelpText()
end)

replaceBarsCheckbox:SetScript("OnClick", function(self)
    MacroSetsFunctions.ToggleActionBarPlacements()
    saveSettings()
    updateHelpText()
end)

charSpecificCheckbox:SetScript("OnClick", function(self)
    MacroSetsFunctions.ToggleCharSpecific()
    saveSettings()
    updateHelpText()
end)

-- Register the options panel with the WoW interface to manage addon settings
macroSetsOptionsPanel.okay = saveSettings
macroSetsOptionsPanel.cancel = loadSettings
macroSetsOptionsPanel.default = function()
    dynamicIconsCheckbox:SetChecked(false)
    replaceBarsCheckbox:SetChecked(true)
    charSpecificCheckbox:SetChecked(false)
    saveSettings()
    loadSettings()
    updateHelpText()
end

-- Properly register the options panel with the WoW Settings API
macroSetsCategory = Settings.RegisterCanvasLayoutCategory(macroSetsOptionsPanel, macroSetsOptionsPanel.name)
Settings.RegisterAddOnCategory(macroSetsCategory)


-- Load settings when the options panel is shown
macroSetsOptionsPanel:SetScript("OnShow", function()
    loadSettings()
    updateHelpText()
end)

-- Event handling to ensure settings are loaded when the addon is initialized
local function onEvent(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == "MacroSets" then
        loadSettings()
    end
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:SetScript("OnEvent", onEvent)

-- Add the options panel to the list of special frames
-- This ensures the panel can be closed with the Escape key
table.insert(UISpecialFrames, macroSetsOptionsPanel:GetName())
