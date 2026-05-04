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
            "lastPrintMessage = nil\n" +
            "function print(...)\n" +
            "    local args = {...}\n" +
            "    local parts = {}\n" +
            "    for i = 1, #args do\n" +
            "        parts[i] = tostring(args[i])\n" +
            "    end\n" +
            "    lastPrintMessage = table.concat(parts, ' ')\n" +
            "end\n"
        ).call();

        try {
            // Load Main.lua contents as a string
            Path luaPath = Paths.get("../Main.lua").toRealPath();
            String mainLuaContent = new String(Files.readAllBytes(luaPath), StandardCharsets.UTF_8);

            // Mock testing code to append
            String mockCode = "\n" +
                "TestExports = {LoadMacroSet = LoadMacroSet}\n" +

                "testScenario = nil\n" +
                "macroFrameVisible = false\n" +
                "inCombatLockdownCounter = 0\n" +
                "deleteMacrosInRangeCounter = 0\n" +
                "createMacroCounter = 0\n" +
                "placeMacroInActionBarSlotsCounter = 0\n" +
                "restoreMacroBodiesCounter = 0\n" +
                "hideUIPanelCounter = 0\n" +
                "showUIPanelCounter = 0\n" +
                "lastDeleteStartSlot = nil\n" +
                "lastDeleteEndSlot = nil\n" +
                "lastCreatedName = nil\n" +
                "lastCreatedIcon = nil\n" +
                "lastCreatedPerCharacter = nil\n" +
                "lastPlacedMacroIndex = nil\n" +
                "lastPlacedPositionCount = nil\n" +
                "lastRestoredSetName = nil\n" +

                "MacroFrame = { IsVisible = function(self) return macroFrameVisible end }\n" +

                "function InCombatLockdown()\n" +
                "   inCombatLockdownCounter = inCombatLockdownCounter + 1\n" +
                "   return testScenario == 'combat'\n" +
                "end\n" +

                "DeleteMacrosInRange = function(startSlot, endSlot)\n" +
                "   deleteMacrosInRangeCounter = deleteMacrosInRangeCounter + 1\n" +
                "   lastDeleteStartSlot = startSlot\n" +
                "   lastDeleteEndSlot = endSlot\n" +
                "end\n" +

                "CreateMacro = function(name, icon, body, perCharacter)\n" +
                "   createMacroCounter = createMacroCounter + 1\n" +
                "   lastCreatedName = name\n" +
                "   lastCreatedIcon = icon\n" +
                "   lastCreatedPerCharacter = perCharacter\n" +
                "   return 100 + createMacroCounter\n" +
                "end\n" +

                "PlaceMacroInActionBarSlots = function(macroIndex, positions)\n" +
                "   placeMacroInActionBarSlotsCounter = placeMacroInActionBarSlotsCounter + 1\n" +
                "   lastPlacedMacroIndex = macroIndex\n" +
                "   lastPlacedPositionCount = #positions\n" +
                "end\n" +

                "RestoreMacroBodies = function(setName)\n" +
                "   restoreMacroBodiesCounter = restoreMacroBodiesCounter + 1\n" +
                "   lastRestoredSetName = setName\n" +
                "end\n" +

                "function HideUIPanel(frame)\n" +
                "   hideUIPanelCounter = hideUIPanelCounter + 1\n" +
                "end\n" +

                "function ShowUIPanel(frame)\n" +
                "   showUIPanelCounter = showUIPanelCounter + 1\n" +
                "end\n";

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
            "MacroSetsDB = {}\n" +
            "MacroSetsDB.testSet = {macros = {}, type = 'g'}\n" +
            "testScenario = 'combat'\n" +
            "lastPrintMessage = nil\n"
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
            "MacroSetsDB = {}\n" +
            "testScenario = nil\n" +
            "lastPrintMessage = nil\n"
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
            "MacroSetsDB = { replaceBars = true }\n" +
            "MacroSetsDB.testSet = {\n" +
            "   type = 'g',\n" +
            "   generalCount = 2,\n" +
            "   characterCount = 0,\n" +
            "   macros = {\n" +
            "       {name = 'testOne', icon = 134400, body = '/say one', position = {5, 10}},\n" +
            "       {name = 'testTwo', icon = 134401, body = '/say two', position = {}}\n" +
            "   }\n" +
            "}\n" +
            "testScenario = nil\n" +
            "macroFrameVisible = true\n" +
            "lastPrintMessage = nil\n"
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
        e.printStackTrace();
        fail(message + ": " + e.getMessage());
    }
}
