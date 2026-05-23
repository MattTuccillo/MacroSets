local EXPORT_PREFIX = "MSM2"
local HYPERLINK_PREFIX = "MacroSets"
local ADDON_MESSAGE_PREFIX = "MacroSets"
local DEFAULT_MACRO_ICON = 134400
local MAX_MACRO_BODY_LENGTH = 255
local BASE36_DIGITS = "0123456789abcdefghijklmnopqrstuvwxyz"

MacroSetsFunctions = MacroSetsFunctions or {}

local DeserializeMacro
local ShowImportDialog
local sharedMacroExports = {}
local shareCounter = 0

local function DecodeEscapedValue(value)
    value = tostring(value or "")
    local decoded = string.gsub(value, "%%(%x%x)", function(hex)
        return string.char(tonumber(hex, 16))
    end)
    return decoded
end

local function EncodeCompactValue(value)
    value = tostring(value or "")
    local encoded = string.gsub(value, "[%%~|%[%]:%]\r\n]", function(char)
        return string.format("%%%02X", string.byte(char))
    end)
    return encoded
end

local function DecodeCompactValue(value)
    return DecodeEscapedValue(value)
end

local function TrimTrailingLineEndings(value)
    value = tostring(value or "")
    return string.gsub(value, "[\r\n]+$", "")
end

local function EncodeBase36(number)
    number = tonumber(number) or DEFAULT_MACRO_ICON
    number = math.floor(number)

    if number <= 0 then
        return "0"
    end

    local encoded = ""
    while number > 0 do
        local remainder = number % 36
        encoded = string.sub(BASE36_DIGITS, remainder + 1, remainder + 1) .. encoded
        number = math.floor(number / 36)
    end

    return encoded
end

local function DecodeBase36(value)
    value = string.lower(tostring(value or ""))
    local decoded = 0

    for index = 1, string.len(value) do
        local char = string.sub(value, index, index)
        local digit = string.find(BASE36_DIGITS, char, 1, true)
        if not digit then
            return nil
        end

        decoded = (decoded * 36) + digit - 1
    end

    return decoded
end

local function EscapeHyperlinkText(value)
    return string.gsub(tostring(value or ""), "|", "||")
end

local function TruncateText(value, maxLength)
    value = tostring(value or "")
    if string.len(value) <= maxLength then
        return value
    end

    return string.sub(value, 1, maxLength - 3) .. "..."
end

local function NormalizeExportString(exportString)
    exportString = tostring(exportString or "")
    exportString = string.match(exportString, "^%s*(.-)%s*$") or ""

    local hyperlinkExportString = string.match(exportString, "|H" .. HYPERLINK_PREFIX .. ":([^|]+)|h")
    if hyperlinkExportString then
        return hyperlinkExportString
    end

    hyperlinkExportString = string.match(exportString, "^" .. HYPERLINK_PREFIX .. ":(.+)$")
    if hyperlinkExportString then
        return hyperlinkExportString
    end

    if string.sub(exportString, 1, string.len(EXPORT_PREFIX .. "~")) == EXPORT_PREFIX .. "~" then
        return exportString
    end

    return string.match(exportString, EXPORT_PREFIX .. "~[^\r\n]+") or exportString
end

local function SerializeMacro(name, icon, body, _perCharacter)
    if not name or name == "" then
        return nil, "Cannot export a macro without a name."
    end

    return table.concat({
        EXPORT_PREFIX,
        EncodeCompactValue(name),
        EncodeBase36(icon or DEFAULT_MACRO_ICON),
        EncodeCompactValue(TrimTrailingLineEndings(body))
    }, "~")
end

local function CreateMacroHyperlink(exportString)
    local macro = DeserializeMacro(exportString)
    if not macro then
        return exportString
    end

    local linkText = "MacroSets: " .. TruncateText(macro.name, 32)
    return "|cff00ccff|H" .. HYPERLINK_PREFIX .. ":" .. exportString .. "|h[" .. EscapeHyperlinkText(linkText) .. "]|h|r"
end

local function CreateMacroShare(exportString)
    exportString = NormalizeExportString(exportString)

    local encodedName = string.match(exportString, "^" .. EXPORT_PREFIX .. "~([^~]*)~[^~]*~.*$")
    if not encodedName then
        return nil
    end
    local name = DecodeCompactValue(encodedName)
    if name == "" then
        name = "Macro"
    end

    shareCounter = shareCounter + 1
    local timeValue = 0
    if GetServerTime then
        timeValue = GetServerTime()
    elseif time and type(time) == "function" then
        timeValue = time()
    elseif os and os.time then
        timeValue = os.time()
    end

    local shareId = EncodeBase36(timeValue) .. EncodeBase36(shareCounter)
    sharedMacroExports[shareId] = {
        exportString = exportString,
        name = name
    }

    return shareId, name
end

local function CreateMacroChatToken(exportString)
    local shareId, name = CreateMacroShare(exportString)
    if not shareId then
        return NormalizeExportString(exportString)
    end

    return "[MacroSets:" .. EncodeCompactValue(name) .. ":" .. shareId .. "]"
end

local function CreateMacroShareHyperlink(sender, shareId, encodedName)
    local share = sharedMacroExports[shareId]
    local name = share and share.name or DecodeCompactValue(encodedName)
    if name == "" then
        name = "Macro"
    end

    local linkData = "share~" .. EncodeCompactValue(sender or "") .. "~" .. shareId
    return "|cff00ccff|H" .. HYPERLINK_PREFIX .. ":" .. linkData .. "|h[" .. EscapeHyperlinkText("MacroSets: " .. TruncateText(name, 32)) .. "]|h|r"
end

local function ReplaceMacroSetsChatTokens(message, sender)
    if not message then
        return ""
    end

    sender = sender or ""

    local success, result = pcall(function()
        local replacedMessage = string.gsub(tostring(message), "%[MS:([A-Za-z0-9]+)%]", function(shareId)
            return CreateMacroShareHyperlink(sender, shareId, "")
        end)

        replacedMessage = string.gsub(replacedMessage, "%[MacroSets:([^:%]]+):([A-Za-z0-9]+)%]", function(encodedName, shareId)
            return CreateMacroShareHyperlink(sender, shareId, encodedName)
        end)

        return string.gsub(replacedMessage, "%[MacroSets:([A-Za-z0-9]+):([^%]]+)%]", function(shareId, encodedName)
            return CreateMacroShareHyperlink(sender, shareId, encodedName)
        end)
    end)

    if not success then
        return tostring(message)
    end

    return result or tostring(message)
end

local function InsertMacroHyperlinkIntoChat(exportString)
    local chatToken = CreateMacroChatToken(exportString)

    if ChatFrame_OpenChat then
        if importExportEditBox and importExportEditBox.ClearFocus then
            importExportEditBox:ClearFocus()
        end
        ChatFrame_OpenChat(chatToken, DEFAULT_CHAT_FRAME)
        return true
    end

    if ChatEdit_InsertLink and ChatEdit_InsertLink(chatToken) then
        return true
    end

    return false
end

function DeserializeMacro(exportString)
    exportString = NormalizeExportString(exportString)

    if not exportString or exportString == "" then
        return nil, "Paste a Macro Sets export string first."
    end

    local encodedName, encodedIcon, encodedBody = string.match(exportString, "^" .. EXPORT_PREFIX .. "~([^~]*)~([^~]*)~(.*)$")
    if not encodedName then
        return nil, "Invalid macro export string."
    end

    local name = DecodeCompactValue(encodedName)
    local body = TrimTrailingLineEndings(DecodeCompactValue(encodedBody))
    local icon = DecodeBase36(encodedIcon) or DEFAULT_MACRO_ICON

    if name == "" then
        return nil, "That export string has no macro name. Re-export the macro and copy the full string."
    end

    if string.len(body) > MAX_MACRO_BODY_LENGTH then
        return nil, "Imported macro body is longer than 255 characters."
    end

    return {
        name = name,
        icon = icon,
        body = body,
        perCharacter = false
    }
end

local function SetMacroSetsTooltip(tooltip, exportString)
    if not tooltip then
        return false
    end

    local macro = DeserializeMacro(exportString)
    if not macro then
        return false
    end

    if tooltip.ClearLines then
        tooltip:ClearLines()
    end
    if tooltip.SetText then
        tooltip:SetText("MacroSets")
    end
    if tooltip.AddLine then
        tooltip:AddLine(macro.name, 1, 1, 1)
        tooltip:AddLine("Click to import this macro.", 0.75, 0.75, 0.75)
    end
    if tooltip.Show then
        tooltip:Show()
    end

    return true
end

local function HandleMacroSetsHyperlink(linkData)
    local exportString = NormalizeExportString(linkData)
    if string.sub(exportString, 1, string.len(EXPORT_PREFIX .. "~")) ~= EXPORT_PREFIX .. "~" then
        local encodedSender, shareId = string.match(exportString or "", "^share~([^~]*)~([A-Za-z0-9]+)")
        if not shareId then
            return false
        end

        local localShare = sharedMacroExports[shareId]
        if localShare then
            ShowImportDialog(localShare.exportString)
            return true
        end

        local sender = DecodeCompactValue(encodedSender)
        if sender == "" then
            print("|cFFD55E00Macro Sets could not identify who shared this macro.|r")
            return true
        end

        if C_ChatInfo and C_ChatInfo.SendAddonMessage then
            C_ChatInfo.SendAddonMessage(ADDON_MESSAGE_PREFIX, "REQ\t" .. shareId, "WHISPER", sender)
            print("|cFF009E73Requesting Macro Sets import from " .. sender .. ".|r")
        elseif SendAddonMessage then
            SendAddonMessage(ADDON_MESSAGE_PREFIX, "REQ\t" .. shareId, "WHISPER", sender)
            print("|cFF009E73Requesting Macro Sets import from " .. sender .. ".|r")
        else
            print("|cFFD55E00Macro Sets addon messages are unavailable.|r")
        end

        return true
    end

    ShowImportDialog(exportString)
    return true
end

local originalSetItemRef = SetItemRef
SetItemRef = function(link, text, button, chatFrame)
    if HandleMacroSetsHyperlink(link) then
        return
    end

    if originalSetItemRef then
        return originalSetItemRef(link, text, button, chatFrame)
    end
end

local function HookMacroSetsTooltips()
    if not hooksecurefunc then
        return
    end

    local function HookTooltip(tooltip)
        if not tooltip or not tooltip.SetHyperlink then
            return
        end

        pcall(hooksecurefunc, tooltip, "SetHyperlink", function(self, link)
            local success, result = pcall(function()
                local exportString = NormalizeExportString(link)
                if string.sub(exportString, 1, string.len(EXPORT_PREFIX .. "~")) == EXPORT_PREFIX .. "~" then
                    SetMacroSetsTooltip(self, exportString)
                end
            end)

            if not success then
                -- Silently fail - don't want tooltip hooks to break tooltips
                return
            end
        end)
    end

    HookTooltip(GameTooltip)
    HookTooltip(ItemRefTooltip)
end

local function HookMacroSetsChatFilters()
    if not ChatFrame_AddMessageEventFilter then
        return
    end

    local function FilterMacroSetsChatMessage(self, event, message, sender, ...)
        -- Wrap in pcall to prevent errors from breaking chat filters
        local success, result = pcall(function()
            return ReplaceMacroSetsChatTokens(message, sender)
        end)

        if not success then
            -- If there's an error, just return the original message
            return false, message, sender, ...
        end

        return false, result, sender, ...
    end

    local chatEvents = {
        "CHAT_MSG_CHANNEL",
        "CHAT_MSG_GUILD",
        "CHAT_MSG_INSTANCE_CHAT",
        "CHAT_MSG_OFFICER",
        "CHAT_MSG_PARTY",
        "CHAT_MSG_PARTY_LEADER",
        "CHAT_MSG_RAID",
        "CHAT_MSG_RAID_LEADER",
        "CHAT_MSG_SAY",
        "CHAT_MSG_WHISPER",
        "CHAT_MSG_WHISPER_INFORM",
        "CHAT_MSG_YELL"
    }

    for _, eventName in ipairs(chatEvents) do
        ChatFrame_AddMessageEventFilter(eventName, FilterMacroSetsChatMessage)
    end
end

local function RegisterMacroSetsAddonMessages()
    if C_ChatInfo and C_ChatInfo.RegisterAddonMessagePrefix then
        C_ChatInfo.RegisterAddonMessagePrefix(ADDON_MESSAGE_PREFIX)
    elseif RegisterAddonMessagePrefix then
        RegisterAddonMessagePrefix(ADDON_MESSAGE_PREFIX)
    end
end

local function SendMacroSetsAddonWhisper(target, message)
    if C_ChatInfo and C_ChatInfo.SendAddonMessage then
        C_ChatInfo.SendAddonMessage(ADDON_MESSAGE_PREFIX, message, "WHISPER", target)
    elseif SendAddonMessage then
        SendAddonMessage(ADDON_MESSAGE_PREFIX, message, "WHISPER", target)
    end
end

local function HandleMacroSetsAddonMessage(prefix, message, sender)
    if prefix ~= ADDON_MESSAGE_PREFIX then
        return
    end

    local command, rest = string.match(tostring(message or ""), "^([^\t]+)\t?(.*)$")
    if command == "REQ" then
        local share = sharedMacroExports[rest]
        if share then
            SendMacroSetsAddonWhisper(sender, "RES\t" .. rest .. "\t" .. share.exportString)
        end
    elseif command == "RES" then
        local _, exportString = string.match(rest, "^([^\t]+)\t(.+)$")
        if exportString then
            ShowImportDialog(exportString)
        end
    end
end

local function GetMacroTabFullMessage(perCharacter)
    if perCharacter then
        return "Character-specific macro tab is full. Delete a character-specific macro or import as a general macro."
    end

    return "General macro tab is full. Delete a general macro or import as a character-specific macro."
end

local function IsMacroTabFull(perCharacter)
    if not GetNumMacros then
        return false
    end

    local generalCount, characterCount = GetNumMacros()
    local maxGeneralMacros = MAX_ACCOUNT_MACROS or 120
    local maxCharacterMacros = MAX_CHARACTER_MACROS or 18

    if perCharacter then
        return (characterCount or 0) >= maxCharacterMacros
    end

    return (generalCount or 0) >= maxGeneralMacros
end

local function ImportMacroString(exportString, perCharacterOverride)
    if InCombatLockdown() then
        print("|cFFD55E00Cannot import macros during combat.|r")
        return false
    end

    local macro, errorMessage = DeserializeMacro(exportString)
    if not macro then
        print("|cFFD55E00" .. errorMessage .. "|r")
        return false
    end

    local perCharacter = macro.perCharacter
    if perCharacterOverride ~= nil then
        perCharacter = perCharacterOverride
    end

    if IsMacroTabFull(perCharacter) then
        print("|cFFD55E00" .. GetMacroTabFullMessage(perCharacter) .. "|r")
        return false
    end

    local macroIndex = CreateMacro(macro.name, macro.icon, macro.body, perCharacter)
    if not macroIndex then
        print("|cFFD55E00Macro import failed. Check that you have an available macro slot.|r")
        return false
    end

    print("|cFF009E73Imported macro '" .. macro.name .. "'.|r")
    return true
end

local function GetSelectedMacroIndex()
    if MacroFrame and MacroFrame.GetSelectedIndex then
        local selectedIndex = MacroFrame:GetSelectedIndex()
        if selectedIndex then
            if MacroFrame.GetMacroDataIndex then
                return MacroFrame:GetMacroDataIndex(selectedIndex)
            end

            return (MacroFrame.macroBase or 0) + selectedIndex
        end
    end

    if MacroFrame and MacroFrame.selectedMacro then
        return MacroFrame.selectedMacro
    end

    return nil
end

local function GetSelectedMacroExportString()
    local macroIndex = GetSelectedMacroIndex()
    if not macroIndex then
        return nil, "Select a macro to export."
    end

    local name, icon, body, perCharacter = GetMacroInfo(macroIndex)
    if not name then
        return nil, "Select a macro to export."
    end

    return SerializeMacro(name, icon, body, perCharacter)
end

local importExportDialog
local importExportEditBox
local importExportAcceptButton
local importCharacterSpecificCheckButton

local function HideImportExportDialog()
    if importExportDialog then
        importExportDialog:Hide()
    end
end

local function EnsureImportExportDialog()
    if importExportDialog then
        return
    end

    importExportDialog = MacroSetsTheme:CreateFrame("Frame", "MacroSetsImportExportDialog", UIParent, "BackdropTemplate")
    importExportDialog:SetSize(520, 208)
    importExportDialog:SetPoint("CENTER")
    importExportDialog:SetMovable(true)
    importExportDialog:EnableMouse(true)
    importExportDialog:RegisterForDrag("LeftButton")
    importExportDialog:SetScript("OnDragStart", importExportDialog.StartMoving)
    importExportDialog:SetScript("OnDragStop", importExportDialog.StopMovingOrSizing)

    -- Apply theme styling to the dialog
    MacroSetsTheme:ApplyFrameStyle(importExportDialog, "Window")

    -- Set backdrop for default style (ElvUI/Tukui will override this)
    if MacroSetsTheme.UIFramework == "Default" then
        importExportDialog:SetBackdrop({
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
            tile = true,
            tileSize = 32,
            edgeSize = 32,
            insets = { left = 8, right = 8, top = 8, bottom = 8 }
        })
    end
    importExportDialog:Hide()

    local title = importExportDialog:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -18)
    importExportDialog.title = title

    local helpText = importExportDialog:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    helpText:SetPoint("TOPLEFT", 24, -44)
    helpText:SetWidth(472)
    helpText:SetJustifyH("LEFT")
    helpText:SetText("")
    importExportDialog.helpText = helpText

    importExportEditBox = CreateFrame("EditBox", "MacroSetsImportExportEditBox", importExportDialog)
    importExportEditBox:SetPoint("TOPLEFT", 24, -66)
    importExportEditBox:SetSize(472, 62)
    importExportEditBox:SetMultiLine(true)
    importExportEditBox:SetAutoFocus(false)
    importExportEditBox:SetMaxLetters(4096)
    importExportEditBox:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
    importExportEditBox:SetScript("OnEscapePressed", function(self)
        self:ClearFocus()
        HideImportExportDialog()
    end)

    -- Apply theme styling to the editbox
    MacroSetsTheme:ApplyEditBoxStyle(importExportEditBox)

    local editBoxBackground = importExportDialog:CreateTexture(nil, "BACKGROUND")
    editBoxBackground:SetPoint("TOPLEFT", importExportEditBox, -6, 6)
    editBoxBackground:SetPoint("BOTTOMRIGHT", importExportEditBox, 6, -6)
    editBoxBackground:SetColorTexture(0, 0, 0, 0.35)

    importExportAcceptButton = CreateFrame("Button", "MacroSetsImportExportAcceptButton", importExportDialog, "UIPanelButtonTemplate")
    importExportAcceptButton:SetSize(90, 24)
    importExportAcceptButton:SetPoint("BOTTOMRIGHT", -112, 14)

    -- Apply theme styling to the button
    MacroSetsTheme:ApplyButtonStyle(importExportAcceptButton)

    importCharacterSpecificCheckButton = CreateFrame("CheckButton", "MacroSetsImportCharacterSpecificCheckButton", importExportDialog, "InterfaceOptionsCheckButtonTemplate")
    importCharacterSpecificCheckButton:SetPoint("TOPLEFT", importExportEditBox, "BOTTOMLEFT", -4, -8)
    importCharacterSpecificCheckButton:SetChecked(false)
    if _G and _G[importCharacterSpecificCheckButton:GetName() .. "Text"] then
        _G[importCharacterSpecificCheckButton:GetName() .. "Text"]:SetText("Character Specific")
    end

    -- Apply theme styling to the checkbox
    MacroSetsTheme:ApplyCheckboxStyle(importCharacterSpecificCheckButton)

    local closeButton = CreateFrame("Button", "MacroSetsImportExportCloseButton", importExportDialog, "UIPanelButtonTemplate")
    closeButton:SetSize(80, 24)
    closeButton:SetPoint("BOTTOMRIGHT", -24, 14)
    closeButton:SetText("Close")
    closeButton:SetScript("OnClick", HideImportExportDialog)

    -- Apply theme styling to the button
    MacroSetsTheme:ApplyButtonStyle(closeButton)
end

local function ShowExportDialog(exportString)
    EnsureImportExportDialog()
    importExportDialog.title:SetText("Export Macro")
    importExportDialog.helpText:SetText("Insert this Macro Sets link into chat, or copy the raw export string.")
    importCharacterSpecificCheckButton:Hide()
    importExportAcceptButton:SetText("Chat")
    importExportAcceptButton:SetScript("OnClick", function()
        if not InsertMacroHyperlinkIntoChat(exportString) then
            importExportEditBox:SetFocus()
            importExportEditBox:HighlightText()
        end
    end)
    importExportEditBox:SetText(exportString)
    importExportDialog:Show()
    importExportEditBox:SetFocus()
    importExportEditBox:HighlightText()
end

function ShowImportDialog(initialExportString)
    EnsureImportExportDialog()
    importExportDialog.title:SetText("Import Macro")
    importExportDialog.helpText:SetText("Paste a Macro Sets export string, then import it.")
    importCharacterSpecificCheckButton:SetChecked(false)
    importCharacterSpecificCheckButton:Show()
    importExportAcceptButton:SetText("Import")
    importExportAcceptButton:SetScript("OnClick", function()
        if ImportMacroString(importExportEditBox:GetText(), importCharacterSpecificCheckButton:GetChecked()) then
            HideImportExportDialog()
        end
    end)
    importExportEditBox:SetText(initialExportString or "")
    importExportDialog:Show()
    importExportEditBox:SetFocus()
end

local function ShowSelectedMacroExport()
    local exportString, errorMessage = GetSelectedMacroExportString()
    if not exportString then
        print("|cFFD55E00" .. errorMessage .. "|r")
        return
    end

    ShowExportDialog(exportString)
end

local macroFrameButtonsCreated = false
local macroSetsExportButton

local function UpdateMacroFrameButtons()
    if macroSetsExportButton then
        local macroIndex = GetSelectedMacroIndex()
        macroSetsExportButton:SetEnabled(macroIndex ~= nil and GetMacroInfo(macroIndex) ~= nil)
    end
end

local function EnsureMacroFrameButtons()
    if macroFrameButtonsCreated or not MacroFrame then
        return
    end

    local sidePanel = MacroSetsTheme:CreateFrame("Frame", "MacroSetsImportExportPanel", MacroFrame, "BackdropTemplate")
    sidePanel:SetSize(86, 58)
    sidePanel:SetPoint("TOPLEFT", MacroFrame, "TOPRIGHT", -4, -82)

    -- Apply theme styling to the side panel
    MacroSetsTheme:ApplyFrameStyle(sidePanel, "Window")

    -- Set backdrop for default style
    if MacroSetsTheme.UIFramework == "Default" then
        sidePanel:SetBackdrop({
            bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true,
            tileSize = 16,
            edgeSize = 12,
            insets = { left = 3, right = 3, top = 3, bottom = 3 }
        })
        sidePanel:SetBackdropColor(0, 0, 0, 0.75)
    end
    sidePanel:SetFrameLevel(MacroFrame:GetFrameLevel() + 4)

    local importButton = CreateFrame("Button", "MacroSetsImportButton", sidePanel, "UIPanelButtonTemplate")
    importButton:SetSize(70, 22)
    importButton:SetPoint("TOP", sidePanel, "TOP", 0, -7)
    importButton:SetText("Import")
    importButton:SetScript("OnClick", function()
        ShowImportDialog()
    end)

    -- Apply theme styling to import button
    MacroSetsTheme:ApplyButtonStyle(importButton)

    macroSetsExportButton = CreateFrame("Button", "MacroSetsExportButton", sidePanel, "UIPanelButtonTemplate")
    macroSetsExportButton:SetSize(70, 22)
    macroSetsExportButton:SetPoint("TOP", importButton, "BOTTOM", 0, -2)
    macroSetsExportButton:SetText("Export")
    macroSetsExportButton:SetScript("OnClick", ShowSelectedMacroExport)

    -- Apply theme styling to export button
    MacroSetsTheme:ApplyButtonStyle(macroSetsExportButton)

    if hooksecurefunc then
        pcall(hooksecurefunc, "MacroFrame_Update", UpdateMacroFrameButtons)
        pcall(hooksecurefunc, "MacroButton_OnClick", UpdateMacroFrameButtons)
        if MacroFrame.UpdateButtons then
            pcall(hooksecurefunc, MacroFrame, "UpdateButtons", UpdateMacroFrameButtons)
        end
        if MacroFrame.SelectMacro then
            pcall(hooksecurefunc, MacroFrame, "SelectMacro", UpdateMacroFrameButtons)
        end
    end

    MacroFrame:HookScript("OnShow", UpdateMacroFrameButtons)
    macroFrameButtonsCreated = true
    UpdateMacroFrameButtons()
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("CHAT_MSG_ADDON")
eventFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "CHAT_MSG_ADDON" then
        local prefix, message, _channel, sender = ...
        -- Wrap addon message handling in pcall to prevent crashes
        pcall(function()
            HandleMacroSetsAddonMessage(prefix, message, sender)
        end)
        return
    end

    local addonName = ...
    if event == "PLAYER_LOGIN" or (event == "ADDON_LOADED" and (addonName == "MacroSets" or addonName == "Blizzard_MacroUI")) then
        EnsureMacroFrameButtons()
        RegisterMacroSetsAddonMessages()
    end
end)

HookMacroSetsTooltips()
HookMacroSetsChatFilters()

MacroSetsFunctions.SerializeMacro = SerializeMacro
MacroSetsFunctions.DeserializeMacro = DeserializeMacro
MacroSetsFunctions.ImportMacroString = ImportMacroString
MacroSetsFunctions.GetSelectedMacroExportString = GetSelectedMacroExportString
MacroSetsFunctions.NormalizeExportString = NormalizeExportString
MacroSetsFunctions.CreateMacroHyperlink = CreateMacroHyperlink
MacroSetsFunctions.CreateMacroChatToken = CreateMacroChatToken
MacroSetsFunctions.ReplaceMacroSetsChatTokens = ReplaceMacroSetsChatTokens
MacroSetsFunctions.InsertMacroHyperlinkIntoChat = InsertMacroHyperlinkIntoChat
MacroSetsFunctions.ShowImportDialog = ShowImportDialog
