import static org.junit.jupiter.api.Assertions.*;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.luaj.vm2.*;
import org.luaj.vm2.lib.jse.JsePlatform;

import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.io.IOException;

public class TestOptionsSettings {
    private Globals globals;
    private LuaValue initializeSettingsFunction;
    private LuaValue saveSettingsFunction;
    private LuaValue updateHelpTextFunction;
    private LuaValue loadSettingsFunction;
    private LuaValue onEventFunction;
    private LuaValue testExports;

    @BeforeEach
    public void setup() {
        globals = JsePlatform.standardGlobals();
        globals.load("if SlashCmdList == nil then SlashCmdList = {} end").call();
        globals.load(
            "MacroSetsDB = {}\n" +
            "MacroSetsFunctions = {\n" +
            "   ToggleDynamicIcons = function() MacroSetsDB.dynamicIcons = not MacroSetsDB.dynamicIcons end,\n" +
            "   ToggleActionBarPlacements = function() MacroSetsDB.replaceBars = not MacroSetsDB.replaceBars end,\n" +
            "   ToggleCharSpecific = function() MacroSetsDB.charSpecific = not MacroSetsDB.charSpecific end\n" +
            "}\n" +
            "UIParent = {}\n" +
            "UISpecialFrames = {}\n" +
            "function GetScreenWidth() return 1920 end\n" +
            "function GetScreenHeight() return 1080 end\n" +
            "function CreateMockFontString()\n" +
            "   return {\n" +
            "       text = nil,\n" +
            "       SetPoint = function(self, ...) end,\n" +
            "       SetText = function(self, text) self.text = text end,\n" +
            "       SetFontObject = function(self, fontObject) self.fontObject = fontObject end,\n" +
            "       SetWidth = function(self, width) self.width = width end,\n" +
            "       SetWordWrap = function(self, wordWrap) self.wordWrap = wordWrap end,\n" +
            "       SetJustifyH = function(self, justifyH) self.justifyH = justifyH end\n" +
            "   }\n" +
            "end\n" +
            "function CreateFrame(frameType, name, parent, template)\n" +
            "   local frame = {\n" +
            "       frameType = frameType,\n" +
            "       name = name,\n" +
            "       parent = parent,\n" +
            "       template = template,\n" +
            "       checked = false,\n" +
            "       scripts = {},\n" +
            "       registeredEvents = {},\n" +
            "       SetSize = function(self, width, height) self.width = width; self.height = height end,\n" +
            "       SetPoint = function(self, ...) self.point = {...} end,\n" +
            "       CreateFontString = function(self, ...) return CreateMockFontString() end,\n" +
            "       GetName = function(self) return self.name end,\n" +
            "       SetChecked = function(self, checked) self.checked = checked end,\n" +
            "       GetChecked = function(self) return self.checked end,\n" +
            "       SetScript = function(self, scriptName, scriptFunction) self.scripts[scriptName] = scriptFunction end,\n" +
            "       RegisterEvent = function(self, event) self.registeredEvents[event] = true end\n" +
            "   }\n" +
            "   if name then\n" +
            "       _G[name] = frame\n" +
            "       if frameType == 'CheckButton' then\n" +
            "           _G[name .. 'Text'] = CreateMockFontString()\n" +
            "       end\n" +
            "   end\n" +
            "   return frame\n" +
            "end\n" +
            "Settings = {\n" +
            "   registerCanvasLayoutCategoryCounter = 0,\n" +
            "   registerAddOnCategoryCounter = 0,\n" +
            "   RegisterCanvasLayoutCategory = function(panel, name)\n" +
            "       Settings.registerCanvasLayoutCategoryCounter = Settings.registerCanvasLayoutCategoryCounter + 1\n" +
            "       return { id = 42, GetID = function(self) return self.id end }\n" +
            "   end,\n" +
            "   RegisterAddOnCategory = function(category)\n" +
            "       Settings.registerAddOnCategoryCounter = Settings.registerAddOnCategoryCounter + 1\n" +
            "   end\n" +
            "}\n"
        ).call();

        try {
            // Load Options.lua contents as a string
            Path luaPath = Paths.get("../Options.lua").toRealPath();
            String optionsLuaContent = new String(Files.readAllBytes(luaPath), StandardCharsets.UTF_8);

            // Mock testing code to append
            String mockCode = "\n" +
                "TestExports = {\n" +
                "   InitializeSettings = InitializeSettings,\n" +
                "   SaveSettings = SaveSettings,\n" +
                "   UpdateHelpText = UpdateHelpText,\n" +
                "   LoadSettings = LoadSettings,\n" +
                "   OnEvent = OnEvent,\n" +
                "   dynamicIconsCheckbox = dynamicIconsCheckbox,\n" +
                "   replaceBarsCheckbox = replaceBarsCheckbox,\n" +
                "   charSpecificCheckbox = charSpecificCheckbox,\n" +
                "   dynamicIconsHelpText = dynamicIconsHelpText,\n" +
                "   replaceBarsHelpText = replaceBarsHelpText,\n" +
                "   charSpecificHelpText = charSpecificHelpText,\n" +
                "   macroSetsOptionsPanel = macroSetsOptionsPanel,\n" +
                "   eventFrame = eventFrame\n" +
                "}\n";

            // Combine the original script with the testing code
            String modifiedScript = optionsLuaContent + mockCode;

            // Load the modified script into Lua
            globals.load(modifiedScript).call();

            // Load test functions
            testExports = globals.get("TestExports");
            initializeSettingsFunction = testExports.get("InitializeSettings");
            saveSettingsFunction = testExports.get("SaveSettings");
            updateHelpTextFunction = testExports.get("UpdateHelpText");
            loadSettingsFunction = testExports.get("LoadSettings");
            onEventFunction = testExports.get("OnEvent");
            assertNotNull(initializeSettingsFunction, "InitializeSettings function should not be null");
            assertNotNull(saveSettingsFunction, "SaveSettings function should not be null");
            assertNotNull(updateHelpTextFunction, "UpdateHelpText function should not be null");
            assertNotNull(loadSettingsFunction, "LoadSettings function should not be null");
            assertNotNull(onEventFunction, "OnEvent function should not be null");

        } catch (IOException e) {
            failWithException("IOException occurred during setup", e);
        } catch (LuaError e) {
            failWithException("LuaError occurred during setup", e);
        }
    }

    @Test
    public void testInitializeSettings_Defaults() {
        globals.load("MacroSetsDB = {}").call();

        initializeSettingsFunction.call();

        LuaTable macroSetsDB = globals.get("MacroSetsDB").checktable();
        assertFalse(macroSetsDB.get("dynamicIcons").toboolean(), "Expected dynamicIcons to be false");
        assertTrue(macroSetsDB.get("replaceBars").toboolean(), "Expected replaceBars to be true");
        assertFalse(macroSetsDB.get("charSpecific").toboolean(), "Expected charSpecific to be false");
    }

    @Test
    public void testInitializeSettings_PreservesExistingValues() {
        globals.load(
            "MacroSetsDB = {\n" +
            "   dynamicIcons = true,\n" +
            "   replaceBars = false,\n" +
            "   charSpecific = true\n" +
            "}\n"
        ).call();

        initializeSettingsFunction.call();

        LuaTable macroSetsDB = globals.get("MacroSetsDB").checktable();
        assertTrue(macroSetsDB.get("dynamicIcons").toboolean(), "Expected dynamicIcons to remain true");
        assertFalse(macroSetsDB.get("replaceBars").toboolean(), "Expected replaceBars to remain false");
        assertTrue(macroSetsDB.get("charSpecific").toboolean(), "Expected charSpecific to remain true");
    }

    @Test
    public void testSaveSettings() {
        testExports.get("dynamicIconsCheckbox").set("checked", LuaValue.TRUE);
        testExports.get("replaceBarsCheckbox").set("checked", LuaValue.FALSE);
        testExports.get("charSpecificCheckbox").set("checked", LuaValue.TRUE);

        saveSettingsFunction.call();

        LuaTable macroSetsDB = globals.get("MacroSetsDB").checktable();
        assertTrue(macroSetsDB.get("dynamicIcons").toboolean(), "Expected dynamicIcons to be true");
        assertFalse(macroSetsDB.get("replaceBars").toboolean(), "Expected replaceBars to be false");
        assertTrue(macroSetsDB.get("charSpecific").toboolean(), "Expected charSpecific to be true");
    }

    @Test
    public void testUpdateHelpText() {
        globals.load(
            "MacroSetsDB.dynamicIcons = true\n" +
            "MacroSetsDB.replaceBars = false\n" +
            "MacroSetsDB.charSpecific = true\n"
        ).call();

        updateHelpTextFunction.call();

        assertEquals(
            "All macros are saved with the currently shown icon unless there is a '#i' at the end of the macro name.",
            testExports.get("dynamicIconsHelpText").get("text").tojstring(),
            "Expected dynamicIcons help text to match enabled state"
        );
        assertEquals(
            "Macros will not be placed on your action bars when a macro set is loaded.",
            testExports.get("replaceBarsHelpText").get("text").tojstring(),
            "Expected replaceBars help text to match disabled state"
        );
        assertEquals(
            "Macro sets will be saved as character-specific by default when not specified.",
            testExports.get("charSpecificHelpText").get("text").tojstring(),
            "Expected charSpecific help text to match enabled state"
        );
    }

    @Test
    public void testLoadSettings() {
        globals.load(
            "MacroSetsDB.dynamicIcons = true\n" +
            "MacroSetsDB.replaceBars = false\n" +
            "MacroSetsDB.charSpecific = true\n"
        ).call();

        loadSettingsFunction.call();

        assertTrue(testExports.get("dynamicIconsCheckbox").get("checked").toboolean(), "Expected dynamicIconsCheckbox to be checked");
        assertFalse(testExports.get("replaceBarsCheckbox").get("checked").toboolean(), "Expected replaceBarsCheckbox to not be checked");
        assertTrue(testExports.get("charSpecificCheckbox").get("checked").toboolean(), "Expected charSpecificCheckbox to be checked");
        assertEquals(
            "Macros will not be placed on your action bars when a macro set is loaded.",
            testExports.get("replaceBarsHelpText").get("text").tojstring(),
            "Expected replaceBars help text to be updated"
        );
    }

    @Test
    public void testOnEvent_AddonLoaded() {
        globals.load("MacroSetsDB = {}").call();

        onEventFunction.invoke(LuaValue.varargsOf(new LuaValue[] {
            LuaValue.NIL,
            LuaValue.valueOf("ADDON_LOADED"),
            LuaValue.valueOf("MacroSets")
        }));

        LuaTable macroSetsDB = globals.get("MacroSetsDB").checktable();
        assertFalse(macroSetsDB.get("dynamicIcons").toboolean(), "Expected dynamicIcons to be false");
        assertTrue(macroSetsDB.get("replaceBars").toboolean(), "Expected replaceBars to be true");
        assertFalse(macroSetsDB.get("charSpecific").toboolean(), "Expected charSpecific to be false");
        assertTrue(testExports.get("replaceBarsCheckbox").get("checked").toboolean(), "Expected replaceBarsCheckbox to be checked");
    }

    @Test
    public void testOnEvent_OtherAddon() {
        globals.load("MacroSetsDB = {}").call();

        onEventFunction.invoke(LuaValue.varargsOf(new LuaValue[] {
            LuaValue.NIL,
            LuaValue.valueOf("ADDON_LOADED"),
            LuaValue.valueOf("OtherAddon")
        }));

        assertTrue(globals.get("MacroSetsDB").get("dynamicIcons").isnil(), "Expected dynamicIcons to remain unset");
        assertFalse(testExports.get("replaceBarsCheckbox").get("checked").toboolean(), "Expected replaceBarsCheckbox to not be checked");
    }

    private void failWithException(String message, Exception e) {
        e.printStackTrace();
        fail(message + ": " + e.getMessage());
    }
}
