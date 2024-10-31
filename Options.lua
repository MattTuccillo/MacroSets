-- Create a configuration frame for the addon
local macroSetsOptionsPanel = CreateFrame("Frame", "MacroSetsOptionsPanel", UIParent, "BackdropTemplate")
macroSetsOptionsPanel.name = "MacroSets"
macroSetsOptionsPanel:SetSize(400, 400)
macroSetsOptionsPanel:SetPoint("CENTER")

-- Title for the panel
local title = macroSetsOptionsPanel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
title:SetPoint("TOPLEFT", 16, -16)
title:SetText("MacroSets Configuration")

-- Create checkbox for "Show Icons"
local dynamicIconsCheckbox = CreateFrame("CheckButton", "DynamicIconsCheckbox", macroSetsOptionsPanel, "InterfaceOptionsCheckButtonTemplate")
dynamicIconsCheckbox:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -20)
dynamicIconsCheckbox.text = _G[dynamicIconsCheckbox:GetName() .. "Text"]
dynamicIconsCheckbox.text:SetText("Show Icons")
dynamicIconsCheckbox.tooltip = "Toggle showing icons."

-- Help text for "Show Icons"
local dynamicIconsHelpText = macroSetsOptionsPanel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
dynamicIconsHelpText:SetPoint("TOPLEFT", dynamicIconsCheckbox, "BOTTOMLEFT", 0, -5)
dynamicIconsHelpText:SetText("Icons are currently OFF.")

-- Create checkbox for "Show Bars"
local replaceBarsCheckbox = CreateFrame("CheckButton", "ReplaceBarsCheckbox", macroSetsOptionsPanel, "InterfaceOptionsCheckButtonTemplate")
replaceBarsCheckbox:SetPoint("TOPLEFT", dynamicIconsCheckbox, "BOTTOMLEFT", 0, -40)
replaceBarsCheckbox.text = _G[replaceBarsCheckbox:GetName() .. "Text"]
replaceBarsCheckbox.text:SetText("Place loaded macros on action bars")
replaceBarsCheckbox.tooltip = "Toggle whether macros should be placed on action bars when a macro set is loaded."

-- Help text for "Show Bars"
local replaceBarsHelpText = macroSetsOptionsPanel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
replaceBarsHelpText:SetPoint("TOPLEFT", replaceBarsCheckbox, "BOTTOMLEFT", 0, -5)
replaceBarsHelpText:SetText("Macros will not be placed on your action bars when a macro set is loaded.")

-- Function to save the values of the checkboxes
local function saveSettings()
    if not MacroSetsDB then MacroSetsDB = {} end
    MacroSetsDB.dynamicIcons = dynamicIconsCheckbox:GetChecked()
    MacroSetsDB.replaceBars = replaceBarsCheckbox:GetChecked()
end

-- Synchronize the checkboxes with MacroSetsDB after saving
dynamicIconsCheckbox:SetChecked(MacroSetsDB.dynamicIcons)
replaceBarsCheckbox:SetChecked(MacroSetsDB.replaceBars)

-- Function to load the values of the checkboxes
local function loadSettings()
    if not MacroSetsDB then MacroSetsDB = {} end
    dynamicIconsCheckbox:SetChecked(MacroSetsDB.dynamicIcons)
    replaceBarsCheckbox:SetChecked(MacroSetsDB.replaceBars)

    -- Update help text based on the loaded settings
    if MacroSetsDB.dynamicIcons then
        dynamicIconsHelpText:SetText("Icons are currently ON.")
    else
        dynamicIconsHelpText:SetText("Icons are currently OFF.")
    end

    if MacroSetsDB.replaceBars then
        replaceBarsHelpText:SetText("Macros will be placed on your action bars when a macro set is loaded.")
    else
        replaceBarsHelpText:SetText("Macros will not be placed on your action bars when a macro set is loaded.")
    end
    
end

-- Add scripts to handle checkbox toggles
dynamicIconsCheckbox:SetScript("OnClick", function(self)
    MacroSetsFunctions.ToggleDynamicIcons()
    saveSettings()
    if MacroSetsDB.dynamicIcons then
        dynamicIconsHelpText:SetText("Icons are currently ON.")
    else
        dynamicIconsHelpText:SetText("Icons are currently OFF.")
    end
end)

replaceBarsCheckbox:SetScript("OnClick", function(self)
    -- Toggle the internal state
    MacroSetsFunctions.ToggleActionBarPlacements()
    saveSettings()
    
    -- Update the help text to match the new state
    if MacroSetsDB.replaceBars then
        replaceBarsHelpText:SetText("Macros will be placed on your action bars when a macro set is loaded.")
    else
        replaceBarsHelpText:SetText("Macros will not be placed on your action bars when a macro set is loaded.")
    end
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
    
    -- Update help text based on default values
    dynamicIconsHelpText:SetText("Icons are currently OFF.")
    replaceBarsHelpText:SetText("Macros will be placed on your action bars when a macro set is loaded.")
end

-- Register the options panel properly with the older, reliable method
Settings.RegisterAddOnCategory(Settings.RegisterCanvasLayoutCategory(macroSetsOptionsPanel, macroSetsOptionsPanel.name))

-- Load settings when the addon is loaded
macroSetsOptionsPanel:SetScript("OnShow", function()
    loadSettings()
    -- Update help text based on initial load
    if MacroSetsDB.dynamicIcons then
        dynamicIconsHelpText:SetText("Icons are currently ON.")
    else
        dynamicIconsHelpText:SetText("Icons are currently OFF.")
    end

    if MacroSetsDB.replaceBars then
        replaceBarsHelpText:SetText("Macros will be placed on your action bars when a macro set is loaded.")
    else
        replaceBarsHelpText:SetText("Macros will not be placed on your action bars when a macro set is loaded.")
    end
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
