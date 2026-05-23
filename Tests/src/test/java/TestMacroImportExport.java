import static org.junit.jupiter.api.Assertions.*;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.luaj.vm2.*;
import org.luaj.vm2.lib.jse.JsePlatform;

import java.nio.file.Path;
import java.nio.file.Paths;
import java.io.IOException;

public class TestMacroImportExport {
    private Globals globals;
    private LuaValue macroSetsFunctions;

    @BeforeEach
    public void setup() {
        globals = JsePlatform.standardGlobals();
        globals.load(
            """
            MacroSetsFunctions = {}
            lastPrintMessage = nil
            createdMacro = nil
            insertedChatLink = nil
            openedChatText = nil
            importEditBoxText = nil
            combat = false
            generalMacroCount = 0
            characterMacroCount = 0
            MAX_ACCOUNT_MACROS = 120
            MAX_CHARACTER_MACROS = 18
            function print(message) lastPrintMessage = message end
            function InCombatLockdown() return combat end
            function GetNumMacros() return generalMacroCount, characterMacroCount end
            function ChatEdit_InsertLink(link) insertedChatLink = link return true end
            function ChatFrame_OpenChat(text, chatFrame) openedChatText = text end
            function CreateMacro(name, icon, body, perCharacter)
               createdMacro = { name = name, icon = icon, body = body, perCharacter = perCharacter }
               return 1
            end
            function GetMacroInfo(index)
               if index == 3 then return 'Selected', 134402, '/say selected', false end
               return nil
            end
            function CreateFrame(frameType, name)
               local frame = { name = name, text = '' }
               frame.RegisterEvent = function(self, event) self.event = event end
               frame.SetScript = function(self, scriptName, scriptFunction) self[scriptName] = scriptFunction end
               frame.SetSize = function() end
               frame.SetPoint = function() end
               frame.SetBackdrop = function() end
               frame.SetBackdropColor = function() end
               frame.SetFrameLevel = function() end
               frame.GetFrameLevel = function() return 1 end
               frame.SetMovable = function() end
               frame.EnableMouse = function() end
               frame.RegisterForDrag = function() end
               frame.StartMoving = function() end
               frame.StopMovingOrSizing = function() end
               frame.Hide = function() end
               frame.Show = function() end
               frame.HookScript = function() end
               frame.CreateFontString = function() return CreateFrame('FontString') end
               frame.CreateTexture = function() return CreateFrame('Texture') end
               frame.SetMultiLine = function() end
               frame.SetAutoFocus = function() end
               frame.SetMaxLetters = function() end
               frame.SetFont = function() end
               frame.SetEnabled = function() end
               frame.SetChecked = function(self, value) self.checked = value end
               frame.GetChecked = function(self) return self.checked end
               frame.SetText = function(self, value) self.text = value if self.name == 'MacroSetsImportExportEditBox' then importEditBoxText = value end end
               frame.GetText = function(self) return self.text end
               frame.SetFocus = function() end
               frame.ClearFocus = function() end
               frame.HighlightText = function() end
               frame.SetWidth = function() end
               frame.SetJustifyH = function() end
               frame.SetColorTexture = function() end
               frame.GetName = function(self) return self.name or '' end
               return frame
            end
            """
        ).call();

        try {
            Path themePath = Paths.get("../ThemeAdapter.lua").toRealPath();
            globals.loadfile(themePath.toString()).call();
            Path luaPath = Paths.get("../MacroImportExport.lua").toRealPath();
            globals.loadfile(luaPath.toString()).call();
            macroSetsFunctions = globals.get("MacroSetsFunctions");
        } catch (IOException e) {
            failWithException("IOException occurred during setup", e);
        } catch (LuaError e) {
            failWithException("LuaError occurred during setup", e);
        }
    }

    @Test
    public void testSerializeDeserialize_RoundTrip() {
        LuaValue exportString = macroSetsFunctions.get("SerializeMacro").invoke(LuaValue.varargsOf(new LuaValue[] {
            LuaValue.valueOf("Storm#i"),
            LuaValue.valueOf(134400),
            LuaValue.valueOf("#showtooltip\n/cast Lightning Bolt"),
            LuaValue.TRUE
        })).arg1();

        assertTrue(exportString.tojstring().startsWith("MSM2~"), "Expected compact Macro Sets export prefix");

        LuaTable macro = macroSetsFunctions.get("DeserializeMacro").call(exportString).checktable();
        assertEquals("Storm#i", macro.get("name").tojstring(), "Expected macro name to round-trip");
        assertEquals(134400, macro.get("icon").toint(), "Expected icon to round-trip");
        assertEquals("#showtooltip\n/cast Lightning Bolt", macro.get("body").tojstring(), "Expected body to round-trip");
        assertFalse(macro.get("perCharacter").toboolean(), "Expected compact exports to leave scope to the import choice");
    }

    @Test
    public void testSerializeMacro_UsesCompactChatFriendlyFormat() {
        LuaValue exportString = macroSetsFunctions.get("SerializeMacro").invoke(LuaValue.varargsOf(new LuaValue[] {
            LuaValue.valueOf("Test"),
            LuaValue.valueOf(538569),
            LuaValue.valueOf("#showtooltip\n/cast Hearthstone"),
            LuaValue.FALSE
        })).arg1();

        assertEquals("MSM2~Test~bjk9~#showtooltip%0A/cast Hearthstone", exportString.tojstring(), "Expected compact export string");
    }

    @Test
    public void testSerializeMacro_TrimsTrailingNewline() {
        LuaValue exportString = macroSetsFunctions.get("SerializeMacro").invoke(LuaValue.varargsOf(new LuaValue[] {
            LuaValue.valueOf("Test"),
            LuaValue.valueOf(538569),
            LuaValue.valueOf("/say hello\n"),
            LuaValue.FALSE
        })).arg1();

        assertEquals("MSM2~Test~bjk9~/say hello", exportString.tojstring(), "Expected trailing newline to be omitted");
    }

    @Test
    public void testDeserializeMacro_TrimsTrailingNewlineBeforeLengthCheck() {
        String body = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa";
        LuaTable macro = macroSetsFunctions.get("DeserializeMacro").call(LuaValue.valueOf("MSM2~Test~bjk9~" + body + "%0A")).checktable();

        assertEquals(255, macro.get("body").tojstring().length(), "Expected trailing newline to be trimmed before length validation");
    }

    @Test
    public void testCreateMacroHyperlink_UsesItemStyleChatLink() {
        LuaValue exportString = macroSetsFunctions.get("SerializeMacro").invoke(LuaValue.varargsOf(new LuaValue[] {
            LuaValue.valueOf("Test"),
            LuaValue.valueOf(538569),
            LuaValue.valueOf("/say hello"),
            LuaValue.FALSE
        })).arg1();

        String hyperlink = macroSetsFunctions.get("CreateMacroHyperlink").call(exportString).tojstring();

        assertTrue(hyperlink.startsWith("|cff00ccff|HMacroSets:"), "Expected colored MacroSets hyperlink");
        assertTrue(hyperlink.contains("|h[MacroSets: Test]|h|r"), "Expected readable MacroSets link text");

        LuaTable macro = macroSetsFunctions.get("DeserializeMacro").call(LuaValue.valueOf(hyperlink)).checktable();
        assertEquals("Test", macro.get("name").tojstring(), "Expected macro name from hyperlink");
        assertEquals("/say hello", macro.get("body").tojstring(), "Expected macro body from hyperlink");
    }

    @Test
    public void testInsertMacroHyperlinkIntoChat_UsesSendableChatToken() {
        LuaValue exportString = macroSetsFunctions.get("SerializeMacro").invoke(LuaValue.varargsOf(new LuaValue[] {
            LuaValue.valueOf("Test"),
            LuaValue.valueOf(538569),
            LuaValue.valueOf("/say hello"),
            LuaValue.FALSE
        })).arg1();

        assertTrue(macroSetsFunctions.get("InsertMacroHyperlinkIntoChat").call(exportString).toboolean(), "Expected chat insertion to succeed");
        assertTrue(globals.get("openedChatText").tojstring().matches("\\[MacroSets:[A-Za-z0-9]+:[^\\]]+\\]"), "Expected opened chat to use readable sendable chat token");
        assertTrue(globals.get("insertedChatLink").isnil(), "Expected chat open path to avoid edit-box insertion");
    }

    @Test
    public void testInsertMacroHyperlinkIntoChat_UsesShortTokenForLongPayload() {
        String longBody = "thsisisad235ifsj askdjfasljdflamsdmemakejajlthsisisadifsj askdj    fasljdflams   dmema345234kejajlt   hsisisadifsj askdjfaslj   dflamsdmem5akejajlthsisisadifsj ask34543452d5435jfasljdflamsdme  dfdf askdjfasljdfla   msdm24455ema   kejaj53453453lthsisisad43\n";
        LuaValue exportString = macroSetsFunctions.get("SerializeMacro").invoke(LuaValue.varargsOf(new LuaValue[] {
            LuaValue.valueOf("sadfsdfasdfsadfa"),
            LuaValue.valueOf(136823),
            LuaValue.valueOf(longBody),
            LuaValue.FALSE
        })).arg1();

        assertTrue(macroSetsFunctions.get("InsertMacroHyperlinkIntoChat").call(exportString).toboolean(), "Expected chat insertion to succeed for long payload");
        assertTrue(globals.get("openedChatText").tojstring().matches("\\[MacroSets:[A-Za-z0-9]+:[^\\]]+\\]"), "Expected long payload to still use readable chat token");
        assertFalse(globals.get("openedChatText").tojstring().startsWith("MSM2~"), "Expected long payload not to fall back to raw export string");
    }

    @Test
    public void testReplaceMacroSetsChatTokens_ConvertsTokenToHyperlink() {
        LuaValue exportString = macroSetsFunctions.get("SerializeMacro").invoke(LuaValue.varargsOf(new LuaValue[] {
            LuaValue.valueOf("Test"),
            LuaValue.valueOf(538569),
            LuaValue.valueOf("/say hello"),
            LuaValue.FALSE
        })).arg1();

        String token = macroSetsFunctions.get("CreateMacroChatToken").call(exportString).tojstring();
        String message = macroSetsFunctions.get("ReplaceMacroSetsChatTokens").invoke(LuaValue.varargsOf(new LuaValue[] {
            LuaValue.valueOf("import " + token),
            LuaValue.valueOf("Sender-Realm")
        })).arg1().tojstring();

        assertTrue(message.contains("|cff00ccff|HMacroSets:"), "Expected chat token to render as MacroSets hyperlink");
        assertTrue(message.contains("share~Sender-Realm~"), "Expected hyperlink to include sender for addon transfer");
        assertTrue(message.contains("|h[MacroSets: Test]|h|r"), "Expected readable MacroSets link text");
    }

    @Test
    public void testReplaceMacroSetsChatTokens_ConvertsRemoteShortTokenToGenericHyperlink() {
        String message = macroSetsFunctions.get("ReplaceMacroSetsChatTokens").invoke(LuaValue.varargsOf(new LuaValue[] {
            LuaValue.valueOf("import [MS:abc123]"),
            LuaValue.valueOf("Sender-Realm")
        })).arg1().tojstring();

        assertTrue(message.contains("|cff00ccff|HMacroSets:share~Sender-Realm~abc123|h"), "Expected short token hyperlink with sender and id");
        assertTrue(message.contains("|h[MacroSets: Macro]|h|r"), "Expected generic link text without local share metadata");
    }

    @Test
    public void testShowImportDialog_PrefillsExportString() {
        macroSetsFunctions.get("ShowImportDialog").call(LuaValue.valueOf("MSM2~Test~bjk9~/say hello"));

        assertEquals("MSM2~Test~bjk9~/say hello", globals.get("importEditBoxText").tojstring(), "Expected import dialog to be prefilled");
    }

    @Test
    public void testDeserializeMacro_InvalidPrefix() {
        Varargs result = macroSetsFunctions.get("DeserializeMacro").invoke(LuaValue.valueOf("bad|string"));
        assertTrue(result.arg1().isnil(), "Expected invalid string to return nil macro");
        assertEquals("Invalid macro export string.", result.arg(2).tojstring(), "Expected invalid string message");
    }

    @Test
    public void testDeserializeMacro_ExtractsExportStringFromPastedText() {
        LuaTable macro = macroSetsFunctions.get("DeserializeMacro").call(LuaValue.valueOf(" Export Macro\nMSM2~Pasted~2v9c~/say hello \n")).checktable();

        assertEquals("Pasted", macro.get("name").tojstring(), "Expected macro name from embedded export string");
        assertEquals("/say hello", macro.get("body").tojstring(), "Expected macro body from embedded export string");
    }

    @Test
    public void testDeserializeMacro_EmptyNameExplainsReExport() {
        Varargs result = macroSetsFunctions.get("DeserializeMacro").invoke(LuaValue.valueOf("MSM2~~2v9c~body"));

        assertTrue(result.arg1().isnil(), "Expected export string with empty name to fail");
        assertEquals("That export string has no macro name. Re-export the macro and copy the full string.", result.arg(2).tojstring(), "Expected re-export guidance");
    }

    @Test
    public void testImportMacroString_Success() {
        LuaValue exportString = macroSetsFunctions.get("SerializeMacro").invoke(LuaValue.varargsOf(new LuaValue[] {
            LuaValue.valueOf("Test"),
            LuaValue.valueOf(134401),
            LuaValue.valueOf("/say imported"),
            LuaValue.FALSE
        })).arg1();

        assertTrue(macroSetsFunctions.get("ImportMacroString").call(exportString).toboolean(), "Expected import to succeed");

        LuaTable createdMacro = globals.get("createdMacro").checktable();
        assertEquals("Test", createdMacro.get("name").tojstring(), "Expected imported macro name");
        assertEquals(134401, createdMacro.get("icon").toint(), "Expected imported macro icon");
        assertEquals("/say imported", createdMacro.get("body").tojstring(), "Expected imported macro body");
        assertFalse(createdMacro.get("perCharacter").toboolean(), "Expected imported macro to be general");
    }

    @Test
    public void testImportMacroString_GeneralTabFull() {
        globals.set("generalMacroCount", LuaValue.valueOf(120));
        LuaValue exportString = macroSetsFunctions.get("SerializeMacro").invoke(LuaValue.varargsOf(new LuaValue[] {
            LuaValue.valueOf("Test"),
            LuaValue.valueOf(134401),
            LuaValue.valueOf("/say imported"),
            LuaValue.FALSE
        })).arg1();

        assertFalse(macroSetsFunctions.get("ImportMacroString").call(exportString).toboolean(), "Expected import to fail when general macros are full");

        assertTrue(globals.get("createdMacro").isnil(), "Expected no macro to be created when general macros are full");
        assertEquals("|cFFD55E00General macro tab is full. Delete a general macro or import as a character-specific macro.|r", globals.get("lastPrintMessage").tojstring(), "Expected full general tab message");
    }

    @Test
    public void testImportMacroString_CharacterSpecificTabFull() {
        globals.set("characterMacroCount", LuaValue.valueOf(18));
        LuaValue exportString = macroSetsFunctions.get("SerializeMacro").invoke(LuaValue.varargsOf(new LuaValue[] {
            LuaValue.valueOf("Test"),
            LuaValue.valueOf(134401),
            LuaValue.valueOf("/say imported"),
            LuaValue.TRUE
        })).arg1();

        assertFalse(macroSetsFunctions.get("ImportMacroString").invoke(LuaValue.varargsOf(new LuaValue[] {
            exportString,
            LuaValue.TRUE
        })).arg1().toboolean(), "Expected import to fail when character-specific macros are full");

        assertTrue(globals.get("createdMacro").isnil(), "Expected no macro to be created when character-specific macros are full");
        assertEquals("|cFFD55E00Character-specific macro tab is full. Delete a character-specific macro or import as a general macro.|r", globals.get("lastPrintMessage").tojstring(), "Expected full character-specific tab message");
    }

    @Test
    public void testImportMacroString_UsesCharacterSpecificOverride() {
        LuaValue exportString = macroSetsFunctions.get("SerializeMacro").invoke(LuaValue.varargsOf(new LuaValue[] {
            LuaValue.valueOf("Test"),
            LuaValue.valueOf(134401),
            LuaValue.valueOf("/say imported"),
            LuaValue.FALSE
        })).arg1();
        LuaValue hyperlink = macroSetsFunctions.get("CreateMacroHyperlink").call(exportString);

        assertTrue(macroSetsFunctions.get("ImportMacroString").invoke(LuaValue.varargsOf(new LuaValue[] {
            hyperlink,
            LuaValue.TRUE
        })).arg1().toboolean(), "Expected import to succeed");

        LuaTable createdMacro = globals.get("createdMacro").checktable();
        assertTrue(createdMacro.get("perCharacter").toboolean(), "Expected override to import as character-specific");
    }

    @Test
    public void testImportMacroString_UsesGeneralOverride() {
        LuaValue exportString = macroSetsFunctions.get("SerializeMacro").invoke(LuaValue.varargsOf(new LuaValue[] {
            LuaValue.valueOf("Test"),
            LuaValue.valueOf(134401),
            LuaValue.valueOf("/say imported"),
            LuaValue.TRUE
        })).arg1();

        assertTrue(macroSetsFunctions.get("ImportMacroString").invoke(LuaValue.varargsOf(new LuaValue[] {
            exportString,
            LuaValue.FALSE
        })).arg1().toboolean(), "Expected import to succeed");

        LuaTable createdMacro = globals.get("createdMacro").checktable();
        assertFalse(createdMacro.get("perCharacter").toboolean(), "Expected override to import as general");
    }

    @Test
    public void testImportMacroString_InCombat() {
        globals.set("combat", LuaValue.TRUE);

        assertFalse(macroSetsFunctions.get("ImportMacroString").call(LuaValue.valueOf("MSM2~Test~2v9c~body")).toboolean(), "Expected import to fail in combat");
        assertTrue(globals.get("createdMacro").isnil(), "Expected no macro to be created while in combat");
        assertEquals("|cFFD55E00Cannot import macros during combat.|r", globals.get("lastPrintMessage").tojstring(), "Expected combat message");
    }

    @Test
    public void testGetSelectedMacroExportString_ModernMacroFrameSelection() {
        globals.load(
            """
            MacroFrame = {
               GetSelectedIndex = function(self) return 2 end,
               GetMacroDataIndex = function(self, selectedIndex) return selectedIndex + 1 end
            }
            """
        ).call();

        LuaValue exportString = macroSetsFunctions.get("GetSelectedMacroExportString").call();

        assertTrue(exportString.tojstring().startsWith("MSM2~Selected~"), "Expected selected macro to export through modern MacroFrame selection");
        LuaTable macro = macroSetsFunctions.get("DeserializeMacro").call(exportString).checktable();
        assertEquals("Selected", macro.get("name").tojstring(), "Expected selected macro name");
        assertEquals("/say selected", macro.get("body").tojstring(), "Expected selected macro body");
    }

    private void failWithException(String message, Exception e) {
        fail(message, e);
    }
}
