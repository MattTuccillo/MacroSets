-- Theme Adapter for MacroSets
-- Automatically detects and applies themes from ElvUI, Tukui, or other UI frameworks
-- Falls back to default WoW styling if no UI framework is detected

MacroSetsTheme = {}

-- Detect available UI frameworks
local function DetectUIFramework()
    if ElvUI and ElvUI[1] then
        return "ElvUI"
    elseif Tukui and Tukui[1] then
        return "Tukui"
    else
        return "Default"
    end
end

MacroSetsTheme.UIFramework = DetectUIFramework()

-- Apply ElvUI styling to a frame
local function ApplyElvUIStyle(frame, frameType)
    frameType = frameType or "Window"
    
    local E = ElvUI and ElvUI[1]
    if not E then return end
    
    local S = E:GetModule("Skins")
    if not S then return end
    
    -- Safely apply styling with error handling
    local success, err = pcall(function()
        if frameType == "Window" then
            -- Apply window skin
            if frame.SetTemplate then
                frame:SetTemplate("Transparent")
            end
        elseif frameType == "Button" and S.HandleButton then
            S:HandleButton(frame)
        elseif frameType == "Checkbox" and S.HandleCheckBox then
            S:HandleCheckBox(frame)
        elseif frameType == "EditBox" and S.HandleEditBox then
            S:HandleEditBox(frame)
        end
    end)
    
    if not success and frame then
        -- If ElvUI styling fails, just use default - don't error out
        return false
    end
    
    return true
end

-- Apply Tukui styling to a frame
local function ApplyTukuiStyle(frame, frameType)
    frameType = frameType or "Window"
    
    local T = Tukui and Tukui[1]
    if not T then return end
    
    if frameType == "Window" then
        frame:SetTemplate("Transparent")
    end
end

-- Apply default WoW styling to a frame
local function ApplyDefaultStyle(frame, frameType)
    frameType = frameType or "Window"
    
    if frameType == "Window" then
        frame:SetBackdrop({
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
            tile = true,
            tileSize = 32,
            edgeSize = 32,
            insets = { left = 8, right = 8, top = 8, bottom = 8 }
        })
    end
end

-- Create a themed frame
function MacroSetsTheme:CreateFrame(frameType, name, parent, template)
    local frame = CreateFrame(frameType, name, parent, template or "BackdropTemplate")
    
    if MacroSetsTheme.UIFramework == "ElvUI" then
        ApplyElvUIStyle(frame, "Window")
    elseif MacroSetsTheme.UIFramework == "Tukui" then
        ApplyTukuiStyle(frame, "Window")
    else
        -- Default styling is already applied by BackdropTemplate
        ApplyDefaultStyle(frame, "Window")
    end
    
    return frame
end

-- Apply theming to an existing frame
function MacroSetsTheme:ApplyFrameStyle(frame, styleType)
    if not frame then return end
    
    styleType = styleType or "Window"
    
    local success, err = pcall(function()
        if MacroSetsTheme.UIFramework == "ElvUI" then
            ApplyElvUIStyle(frame, styleType)
        elseif MacroSetsTheme.UIFramework == "Tukui" then
            ApplyTukuiStyle(frame, styleType)
        else
            ApplyDefaultStyle(frame, styleType)
        end
    end)
    
    if not success then
        -- Fallback to default if theme application fails
        ApplyDefaultStyle(frame, styleType)
    end
end

-- Apply theming to a button
function MacroSetsTheme:ApplyButtonStyle(button)
    if not button then return end
    
    local success, err = pcall(function()
        if MacroSetsTheme.UIFramework == "ElvUI" then
            local E = ElvUI and ElvUI[1]
            if E then
                local S = E:GetModule("Skins")
                if S and S.HandleButton then
                    S:HandleButton(button)
                    return
                end
            end
        end
    end)
    
    -- If ElvUI styling fails or isn't available, default templates handle the styling
end

-- Apply theming to a checkbox
function MacroSetsTheme:ApplyCheckboxStyle(checkbox)
    if not checkbox then return end
    
    local success, err = pcall(function()
        if MacroSetsTheme.UIFramework == "ElvUI" then
            local E = ElvUI and ElvUI[1]
            if E then
                local S = E:GetModule("Skins")
                if S and S.HandleCheckBox then
                    S:HandleCheckBox(checkbox)
                    return
                end
            end
        end
    end)
    
    -- If ElvUI styling fails or isn't available, default templates handle the styling
end

-- Apply theming to an editbox
function MacroSetsTheme:ApplyEditBoxStyle(editbox)
    if not editbox then return end
    
    local success, err = pcall(function()
        if MacroSetsTheme.UIFramework == "ElvUI" then
            local E = ElvUI and ElvUI[1]
            if E then
                local S = E:GetModule("Skins")
                if S and S.HandleEditBox then
                    S:HandleEditBox(editbox)
                    return
                end
            end
        end
    end)
    
    -- If ElvUI styling fails or isn't available, no special styling needed
end

-- Get theme-appropriate colors
function MacroSetsTheme:GetColor(colorType)
    if MacroSetsTheme.UIFramework == "ElvUI" then
        local E = ElvUI and ElvUI[1]
        if E and E.db and E.db.general then
            if colorType == "Primary" then
                return E.db.general.backdropColor
            elseif colorType == "Border" then
                return E.db.general.borderColor
            elseif colorType == "Text" then
                return E.db.general.backdropTextColor
            end
        end
    end
    
    -- Return default colors
    if colorType == "Primary" then
        return { 0.1, 0.1, 0.1 }
    elseif colorType == "Border" then
        return { 0, 0, 0 }
    elseif colorType == "Text" then
        return { 1, 1, 1 }
    end
end

-- Hook into UI framework updates (for when UI framework is loaded after addon)
local themeCheckFrame = CreateFrame("Frame")
themeCheckFrame:RegisterEvent("ADDON_LOADED")
themeCheckFrame:SetScript("OnEvent", function(self, event, addonName)
    if event == "ADDON_LOADED" then
        if addonName == "ElvUI" or addonName == "Tukui" then
            MacroSetsTheme.UIFramework = DetectUIFramework()
        end
    end
end)
