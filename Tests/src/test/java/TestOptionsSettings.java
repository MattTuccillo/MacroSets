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
            """
            MacroSetsDB = {}
            MacroSetsFunctions = {
               ToggleDynamicIcons = function() MacroSetsDB.dynamicIcons = not MacroSetsDB.dynamicIcons end,
               ToggleActionBarPlacements = function() MacroSetsDB.replaceBars = not MacroSetsDB.replaceBars end,
               ToggleCharSpecific = function() MacroSetsDB.charSpecific = not MacroSetsDB.charSpecific end
            }
            UIParent = {}
            UISpecialFrames = {}
            function GetScreenWidth() return 1920 end
            function GetScreenHeight() return 1080 end
            function CreateMockFontString()
               return {
                   text = nil,
                   SetPoint = function(self, ...) end,
                   SetText = function(self, text) self.text = text end,
                   SetFontObject = function(self, fontObject) self.fontObject = fontObject end,
                   SetWidth = function(self, width) self.width = width end,
                   SetWordWrap = function(self, wordWrap) self.wordWrap = wordWrap end,
                   SetJustifyH = function(self, justifyH) self.justifyH = justifyH end
               }
            end
            function CreateFrame(frameType, name, parent, template)
               local frame = {
                   frameType = frameType,
                   name = name,
                   parent = parent,
                   template = template,
                   checked = false,
                   scripts = {},
                   registeredEvents = {},
                   SetSize = function(self, width, height) self.width = width; self.height = height end,
                   SetPoint = function(self, ...) self.point = {...} end,
                   SetBackdrop = function(self, backdrop) self.backdrop = backdrop end,
                   CreateFontString = function(self, ...) return CreateMockFontString() end,
                   GetName = function(self) return self.name end,
                   SetChecked = function(self, checked) self.checked = checked end,
                   GetChecked = function(self) return self.checked end,
                   SetScript = function(self, scriptName, scriptFunction) self.scripts[scriptName] = scriptFunction end,
                   RegisterEvent = function(self, event) self.registeredEvents[event] = true end
               }
               if name then
                   _G[name] = frame
                   if frameType == 'CheckButton' then
                       _G[name .. 'Text'] = CreateMockFontString()
                   end
               end
               return frame
            end
            Settings = {
               registerCanvasLayoutCategoryCounter = 0,
               registerAddOnCategoryCounter = 0,
               RegisterCanvasLayoutCategory = function(panel, name)
                   Settings.registerCanvasLayoutCategoryCounter = Settings.registerCanvasLayoutCategoryCounter + 1
                   return { id = 42, GetID = function(self) return self.id end }
               end,
               RegisterAddOnCategory = function(category)
                   Settings.registerAddOnCategoryCounter = Settings.registerAddOnCategoryCounter + 1
               end
            }
            """
        ).call();

        try {
            Path themePath = Paths.get("../ThemeAdapter.lua").toRealPath();
            globals.loadfile(themePath.toString()).call();

            // Load Options.lua contents as a string
            Path luaPath = Paths.get("../Options.lua").toRealPath();
            String optionsLuaContent = new String(Files.readAllBytes(luaPath), StandardCharsets.UTF_8);

            // Mock testing code to append
            String mockCode = """

            TestExports = {
               InitializeSettings = InitializeSettings,
               SaveSettings = SaveSettings,
               UpdateHelpText = UpdateHelpText,
               LoadSettings = LoadSettings,
               OnEvent = OnEvent,
               dynamicIconsCheckbox = dynamicIconsCheckbox,
               replaceBarsCheckbox = replaceBarsCheckbox,
               charSpecificCheckbox = charSpecificCheckbox,
               dynamicIconsHelpText = dynamicIconsHelpText,
               replaceBarsHelpText = replaceBarsHelpText,
               charSpecificHelpText = charSpecificHelpText,
               macroSetsOptionsPanel = macroSetsOptionsPanel,
               eventFrame = eventFrame
            }
            """;

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
            """
            MacroSetsDB = {
               dynamicIcons = true,
               replaceBars = false,
               charSpecific = true
            }
            """
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
            """
            MacroSetsDB.dynamicIcons = true
            MacroSetsDB.replaceBars = false
            MacroSetsDB.charSpecific = true
            """
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
    public void testUpdateHelpText_CharSpecificDisabled() {
        globals.load(
            """
            MacroSetsDB.dynamicIcons = false
            MacroSetsDB.replaceBars = true
            MacroSetsDB.charSpecific = false
            """
        ).call();

        updateHelpTextFunction.call();

        assertEquals(
            "Macro sets will save both general and character-specific macros by default when not specified.",
            testExports.get("charSpecificHelpText").get("text").tojstring(),
            "Expected charSpecific help text to match disabled state"
        );
    }

    @Test
    public void testLoadSettings() {
        globals.load(
            """
            MacroSetsDB.dynamicIcons = true
            MacroSetsDB.replaceBars = false
            MacroSetsDB.charSpecific = true
            """
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
        fail(message, e);
    }
}
