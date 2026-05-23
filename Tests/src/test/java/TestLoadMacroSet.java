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

public class TestLoadMacroSet {
    private static final String COLOR_VERMILLION = "|cFFD55E00";
    private static final String COLOR_GREEN = "|cFF009E73";
    private static final String COLOR_RESET = "|r";

    private Globals globals;
    private LuaValue loadMacroSetFunction;

    @BeforeEach
    public void setup() {
        globals = JsePlatform.standardGlobals();
        globals.load("if SlashCmdList == nil then SlashCmdList = {} end").call();
        globals.load(
            """
            lastPrintMessage = nil
            function print(...)
                local args = {...}
                local parts = {}
                for i = 1, #args do
                    parts[i] = tostring(args[i])
                end
                lastPrintMessage = table.concat(parts, ' ')
            end
            """
        ).call();

        try {
            // Load Main.lua contents as a string
            Path luaPath = Paths.get("../Main.lua").toRealPath();
            String mainLuaContent = new String(Files.readAllBytes(luaPath), StandardCharsets.UTF_8);

            // Mock testing code to append
            String mockCode = """

            TestExports = {LoadMacroSet = LoadMacroSet}
            testScenario = nil
            macroFrameVisible = false
            inCombatLockdownCounter = 0
            deleteMacrosInRangeCounter = 0
            createMacroCounter = 0
            placeMacroInActionBarSlotsCounter = 0
            restoreMacroBodiesCounter = 0
            hideUIPanelCounter = 0
            showUIPanelCounter = 0
            lastDeleteStartSlot = nil
            lastDeleteEndSlot = nil
            lastCreatedName = nil
            lastCreatedIcon = nil
            lastCreatedPerCharacter = nil
            lastPlacedMacroIndex = nil
            lastPlacedPositionCount = nil
            lastRestoredSetName = nil
            MacroFrame = { IsVisible = function(self) return macroFrameVisible end }
            function InCombatLockdown()
               inCombatLockdownCounter = inCombatLockdownCounter + 1
               return testScenario == 'combat'
            end
            DeleteMacrosInRange = function(startSlot, endSlot)
               deleteMacrosInRangeCounter = deleteMacrosInRangeCounter + 1
               lastDeleteStartSlot = startSlot
               lastDeleteEndSlot = endSlot
            end
            CreateMacro = function(name, icon, body, perCharacter)
               createMacroCounter = createMacroCounter + 1
               lastCreatedName = name
               lastCreatedIcon = icon
               lastCreatedPerCharacter = perCharacter
               return 100 + createMacroCounter
            end
            PlaceMacroInActionBarSlots = function(macroIndex, positions)
               placeMacroInActionBarSlotsCounter = placeMacroInActionBarSlotsCounter + 1
               lastPlacedMacroIndex = macroIndex
               lastPlacedPositionCount = #positions
            end
            RestoreMacroBodies = function(setName)
               restoreMacroBodiesCounter = restoreMacroBodiesCounter + 1
               lastRestoredSetName = setName
            end
            function HideUIPanel(frame)
               hideUIPanelCounter = hideUIPanelCounter + 1
            end
            function ShowUIPanel(frame)
               showUIPanelCounter = showUIPanelCounter + 1
            end
            """;

            // Combine the original script with the testing code
            String modifiedScript = mainLuaContent + mockCode;

            // Load the modified script into Lua
            globals.load(modifiedScript).call();

            // Load test function
            LuaValue testExports = globals.get("TestExports");
            loadMacroSetFunction = testExports.get("LoadMacroSet");
            assertNotNull(loadMacroSetFunction, "LoadMacroSet function should not be null");

        } catch (IOException e) {
            failWithException("IOException occurred during setup", e);
        } catch (LuaError e) {
            failWithException("LuaError occurred during setup", e);
        }
    }

    @Test
    public void testLoadMacroSet_InCombat() {
        globals.load(
            """
            MacroSetsDB = {}
            MacroSetsDB.testSet = {macros = {}, type = 'g'}
            testScenario = 'combat'
            lastPrintMessage = nil
            """
        ).call();

        loadMacroSetFunction.call(LuaValue.valueOf("testSet"));

        String expectedMessage = COLOR_VERMILLION +
            "Cannot perform this action during combat." +
            COLOR_RESET;
        assertEquals(1, globals.get("inCombatLockdownCounter").toint(), "Expected InCombatLockdown to be called 1 time");
        assertEquals(0, globals.get("deleteMacrosInRangeCounter").toint(), "Expected DeleteMacrosInRange to be called 0 times");
        assertEquals(0, globals.get("createMacroCounter").toint(), "Expected CreateMacro to be called 0 times");
        assertEquals(expectedMessage, globals.get("lastPrintMessage").tojstring(), "Expected combat message to be printed");
    }

    @Test
    public void testLoadMacroSet_SetDoesNotExist() {
        globals.load(
            """
            MacroSetsDB = {}
            testScenario = nil
            lastPrintMessage = nil
            """
        ).call();

        loadMacroSetFunction.call(LuaValue.valueOf("missingSet"));

        String expectedMessage = COLOR_VERMILLION +
            "Set does not exist." +
            COLOR_RESET;
        assertEquals(1, globals.get("inCombatLockdownCounter").toint(), "Expected InCombatLockdown to be called 1 time");
        assertEquals(0, globals.get("deleteMacrosInRangeCounter").toint(), "Expected DeleteMacrosInRange to be called 0 times");
        assertEquals(0, globals.get("createMacroCounter").toint(), "Expected CreateMacro to be called 0 times");
        assertEquals(expectedMessage, globals.get("lastPrintMessage").tojstring(), "Expected missing set message to be printed");
    }

    @Test
    public void testLoadMacroSet_GeneralSuccess() {
        globals.load(
            """
            MacroSetsDB = { replaceBars = true }
            MacroSetsDB.testSet = {
               type = 'g',
               generalCount = 2,
               characterCount = 0,
               macros = {
                   {name = 'testOne', icon = 134400, body = '/say one', position = {5, 10}},
                   {name = 'testTwo', icon = 134401, body = '/say two', position = {}}
               }
            }
            testScenario = nil
            macroFrameVisible = true
            lastPrintMessage = nil
            """
        ).call();

        loadMacroSetFunction.call(LuaValue.valueOf("testSet"));

        String expectedMessage = COLOR_GREEN +
            "Macro set 'testSet' loaded." +
            COLOR_RESET;
        assertEquals(1, globals.get("deleteMacrosInRangeCounter").toint(), "Expected DeleteMacrosInRange to be called 1 time");
        assertEquals(1, globals.get("lastDeleteStartSlot").toint(), "Expected delete start slot to be 1");
        assertEquals(120, globals.get("lastDeleteEndSlot").toint(), "Expected delete end slot to be 120");
        assertEquals(2, globals.get("createMacroCounter").toint(), "Expected CreateMacro to be called 2 times");
        assertEquals("testTwo", globals.get("lastCreatedName").tojstring(), "Expected last created macro name to be testTwo");
        assertEquals(134401, globals.get("lastCreatedIcon").toint(), "Expected last created macro icon to be 134401");
        assertFalse(globals.get("lastCreatedPerCharacter").toboolean(), "Expected last created macro to be general");
        assertEquals(1, globals.get("placeMacroInActionBarSlotsCounter").toint(), "Expected PlaceMacroInActionBarSlots to be called 1 time");
        assertEquals(101, globals.get("lastPlacedMacroIndex").toint(), "Expected placed macro index to be 101");
        assertEquals(2, globals.get("lastPlacedPositionCount").toint(), "Expected placed position count to be 2");
        assertEquals(1, globals.get("restoreMacroBodiesCounter").toint(), "Expected RestoreMacroBodies to be called 1 time");
        assertEquals("testSet", globals.get("lastRestoredSetName").tojstring(), "Expected restored set name to be testSet");
        assertEquals(1, globals.get("hideUIPanelCounter").toint(), "Expected HideUIPanel to be called 1 time");
        assertEquals(1, globals.get("showUIPanelCounter").toint(), "Expected ShowUIPanel to be called 1 time");
        assertEquals(expectedMessage, globals.get("lastPrintMessage").tojstring(), "Expected success message to be printed");
    }

    private void failWithException(String message, Exception e) {
        fail(message, e);
    }
}
