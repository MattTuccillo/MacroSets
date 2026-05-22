import static org.junit.jupiter.api.Assertions.*;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.luaj.vm2.*;
import org.luaj.vm2.lib.jse.JsePlatform;

import java.io.IOException;
import java.nio.file.Path;
import java.nio.file.Paths;

public class TestThemeAdapter {
    private Globals globals;
    private LuaValue macroSetsTheme;

    @BeforeEach
    public void setup() {
        globals = JsePlatform.standardGlobals();
        loadWowFrameStubs();
    }

    @Test
    public void testDefaultThemeCreatesBackdropTemplateFrame() {
        loadThemeAdapter();

        LuaTable frame = macroSetsTheme.get("CreateFrame").invoke(LuaValue.varargsOf(new LuaValue[] {
            macroSetsTheme,
            LuaValue.valueOf("Frame"),
            LuaValue.valueOf("TestFrame"),
            LuaValue.NIL,
            LuaValue.NIL
        })).arg1().checktable();

        assertEquals("Default", macroSetsTheme.get("UIFramework").tojstring(), "Expected default framework without ElvUI or Tukui");
        assertEquals("BackdropTemplate", frame.get("template").tojstring(), "Expected default frame template");
        assertFalse(frame.get("backdrop").isnil(), "Expected default styling to apply a backdrop");
        assertEquals("Interface\\DialogFrame\\UI-DialogBox-Border", frame.get("backdrop").get("edgeFile").tojstring(), "Expected default border");
    }

    @Test
    public void testElvUIThemeUsesSkinHandlersForControls() {
        globals.load(
            "elvButtonSkinCount = 0\n" +
            "elvCheckboxSkinCount = 0\n" +
            "elvEditBoxSkinCount = 0\n" +
            "local Skins = {}\n" +
            "Skins.HandleButton = function(self, frame) elvButtonSkinCount = elvButtonSkinCount + 1 frame.elvButtonSkinned = true end\n" +
            "Skins.HandleCheckBox = function(self, frame) elvCheckboxSkinCount = elvCheckboxSkinCount + 1 frame.elvCheckboxSkinned = true end\n" +
            "Skins.HandleEditBox = function(self, frame) elvEditBoxSkinCount = elvEditBoxSkinCount + 1 frame.elvEditBoxSkinned = true end\n" +
            "ElvUI = { { GetModule = function(self, moduleName) if moduleName == 'Skins' then return Skins end end } }\n"
        ).call();
        loadThemeAdapter();

        globals.load(
            "local button = CreateFrame('Button', 'ButtonFrame')\n" +
            "local checkbox = CreateFrame('CheckButton', 'CheckboxFrame')\n" +
            "local editbox = CreateFrame('EditBox', 'EditBoxFrame')\n" +
            "MacroSetsTheme:ApplyButtonStyle(button)\n" +
            "MacroSetsTheme:ApplyCheckboxStyle(checkbox)\n" +
            "MacroSetsTheme:ApplyEditBoxStyle(editbox)\n" +
            "styledButton = button\n" +
            "styledCheckbox = checkbox\n" +
            "styledEditBox = editbox\n"
        ).call();

        assertEquals("ElvUI", macroSetsTheme.get("UIFramework").tojstring(), "Expected ElvUI detection");
        assertEquals(1, globals.get("elvButtonSkinCount").toint(), "Expected ElvUI button skin handler");
        assertEquals(1, globals.get("elvCheckboxSkinCount").toint(), "Expected ElvUI checkbox skin handler");
        assertEquals(1, globals.get("elvEditBoxSkinCount").toint(), "Expected ElvUI editbox skin handler");
        assertTrue(globals.get("styledButton").get("elvButtonSkinned").toboolean(), "Expected button to be marked skinned");
        assertTrue(globals.get("styledCheckbox").get("elvCheckboxSkinned").toboolean(), "Expected checkbox to be marked skinned");
        assertTrue(globals.get("styledEditBox").get("elvEditBoxSkinned").toboolean(), "Expected editbox to be marked skinned");
    }

    @Test
    public void testThemeUpdatesWhenTukuiLoadsAfterAddon() {
        loadThemeAdapter();

        assertEquals("Default", macroSetsTheme.get("UIFramework").tojstring(), "Expected default before Tukui loads");

        globals.load(
            "Tukui = { {} }\n" +
            "createdFrames[1]:OnEvent('ADDON_LOADED', 'Tukui')\n"
        ).call();

        assertEquals("Tukui", macroSetsTheme.get("UIFramework").tojstring(), "Expected framework refresh after Tukui loads");
    }

    private void loadWowFrameStubs() {
        globals.load(
            "createdFrames = {}\n" +
            "function CreateFrame(frameType, name, parent, template)\n" +
            "   local frame = { frameType = frameType, name = name, parent = parent, template = template }\n" +
            "   frame.SetBackdrop = function(self, backdrop) self.backdrop = backdrop end\n" +
            "   frame.SetTemplate = function(self, templateName) self.templateName = templateName end\n" +
            "   frame.RegisterEvent = function(self, event) self.registeredEvent = event end\n" +
            "   frame.SetScript = function(self, scriptName, scriptFunction) self[scriptName] = scriptFunction end\n" +
            "   table.insert(createdFrames, frame)\n" +
            "   return frame\n" +
            "end\n"
        ).call();
    }

    private void loadThemeAdapter() {
        try {
            Path luaPath = Paths.get("../ThemeAdapter.lua").toRealPath();
            globals.loadfile(luaPath.toString()).call();
            macroSetsTheme = globals.get("MacroSetsTheme");
        } catch (IOException e) {
            failWithException("IOException occurred during setup", e);
        } catch (LuaError e) {
            failWithException("LuaError occurred during setup", e);
        }
    }

    private void failWithException(String message, Exception e) {
        e.printStackTrace();
        fail(message + ": " + e.getMessage());
    }
}
