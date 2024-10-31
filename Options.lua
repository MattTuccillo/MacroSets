-- Create a configuration frame for the addon
local macroSetsOptionsPanel = CreateFrame("Frame", "MacroSetsOptionsPanel", UIParent, "BackdropTemplate")
macroSetsOptionsPanel.name = "MacroSets"
local screenWidth = GetScreenWidth()
local screenHeight = GetScreenHeight()
macroSetsOptionsPanel:SetSize(screenWidth * 0.4, screenHeight * 0.6)
macroSetsOptionsPanel:SetPoint("CENTER")

-- Title for the panel
local title = macroSetsOptionsPanel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
title:SetPoint("TOPLEFT", 16, -16)
title:SetText("MacroSets Configuration")

-- Create a sub-frame for checkboxes with a border
local checkboxesFrame = CreateFrame("Frame", "CheckboxesFrame", macroSetsOptionsPanel)
checkboxesFrame:SetSize(screenWidth * 0.9 * 0.4, screenHeight * 0.7 * 0.6)
checkboxesFrame:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -20)

-- Create checkbox for "Show Icons"
local dynamicIconsCheckbox = CreateFrame("CheckButton", "DynamicIconsCheckbox", checkboxesFrame, "InterfaceOptionsCheckButtonTemplate")
dynamicIconsCheckbox:SetPoint("TOPLEFT", checkboxesFrame, "TOPLEFT", 10, -10)
dynamicIconsCheckbox.text = _G[dynamicIconsCheckbox:GetName() .. "Text"]
dynamicIconsCheckbox.text:SetFontObject("GameFontNormalLarge")
dynamicIconsCheckbox.text:SetText("Save initial macro icon")
dynamicIconsCheckbox.tooltip = "Toggle whether macro icons should default to the question mark dynamic icon or the first icon that is set when saved"

-- Help text for "Show Icons"
local dynamicIconsHelpText = checkboxesFrame:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
dynamicIconsHelpText:SetWidth(screenWidth * 0.35 * 0.9)
dynamicIconsHelpText:SetWordWrap(true)
dynamicIconsHelpText:SetJustifyH("LEFT")
dynamicIconsHelpText:SetPoint("TOPLEFT", dynamicIconsCheckbox, "BOTTOMLEFT", 0, -5)

-- Create checkbox for "Show Bars"
local replaceBarsCheckbox = CreateFrame("CheckButton", "ReplaceBarsCheckbox", checkboxesFrame, "InterfaceOptionsCheckButtonTemplate")
replaceBarsCheckbox:SetPoint("TOPLEFT", dynamicIconsCheckbox, "BOTTOMLEFT", 0, -30)
replaceBarsCheckbox.text = _G[replaceBarsCheckbox:GetName() .. "Text"]
replaceBarsCheckbox.text:SetFontObject("GameFontNormalLarge")
replaceBarsCheckbox.text:SetText("Place loaded macros on action bars")
replaceBarsCheckbox.tooltip = "Toggle whether macros should be placed on action bars when a macro set is loaded."

-- Help text for "Show Bars"
local replaceBarsHelpText = checkboxesFrame:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
replaceBarsHelpText:SetWidth(screenWidth * 0.35 * 0.9)
replaceBarsHelpText:SetWordWrap(true)
replaceBarsHelpText:SetJustifyH("LEFT")
replaceBarsHelpText:SetPoint("TOPLEFT", replaceBarsCheckbox, "BOTTOMLEFT", 0, -5)

-- Function to save the values of the checkboxes
local function saveSettings()
    if not MacroSetsDB then MacroSetsDB = {} end
    MacroSetsDB.dynamicIcons = dynamicIconsCheckbox:GetChecked()
    MacroSetsDB.replaceBars = replaceBarsCheckbox:GetChecked()
end

-- Function to update help text based on current settings
local function updateHelpText()
    if MacroSetsDB.dynamicIcons then
        dynamicIconsHelpText:SetText("All macros are saved with the currently shown icon unless there is a '#i' at the end of the macro name.")
    else
        dynamicIconsHelpText:SetText("All macros are saved with the dynamic question mark icon unless there is a '#i' at the end of the macro name.")
    end

    if MacroSetsDB.replaceBars then
        replaceBarsHelpText:SetText("Macros will be placed on your action bars when a macro set is loaded.")
    else
        replaceBarsHelpText:SetText("Macros will not be placed on your action bars when a macro set is loaded.")
    end
end

-- Function to load the values of the checkboxes
local function loadSettings()
    if not MacroSetsDB then MacroSetsDB = {} end
    dynamicIconsCheckbox:SetChecked(MacroSetsDB.dynamicIcons)
    replaceBarsCheckbox:SetChecked(MacroSetsDB.replaceBars)
    updateHelpText()
end

-- Add scripts to handle checkbox toggles
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

-- Register the options panel with the WoW interface
macroSetsOptionsPanel.okay = function()
    saveSettings()
end

macroSetsOptionsPanel.cancel = function()
    loadSettings()
end

macroSetsOptionsPanel.default = function()
    dynamicIconsCheckbox:SetChecked(false)
    replaceBarsCheckbox:SetChecked(true)
    saveSettings()
    loadSettings()
    updateHelpText()
end

-- Register the options panel properly with the older, reliable method
Settings.RegisterAddOnCategory(Settings.RegisterCanvasLayoutCategory(macroSetsOptionsPanel, macroSetsOptionsPanel.name))

-- Load settings when the addon is loaded
macroSetsOptionsPanel:SetScript("OnShow", function()
    loadSettings()
    updateHelpText()
end)

-- Event handling to ensure panel is properly registered
local function onEvent(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == "MacroSets" then
        loadSettings()
    end
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:SetScript("OnEvent", onEvent)

-- Ensure the frame is added to the Interface AddOns list
table.insert(UISpecialFrames, macroSetsOptionsPanel:GetName())
