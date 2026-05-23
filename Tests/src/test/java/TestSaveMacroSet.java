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

public class TestSaveMacroSet {
    private static final String COLOR_VERMILLION = "|cFFD55E00";
    private static final String COLOR_GREEN = "|cFF009E73";
    private static final String COLOR_RESET = "|r";

    private Globals globals;
    private LuaValue saveMacroSetFunction;

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

            TestExports = {SaveMacroSet = SaveMacroSet}
            testScenario = nil
            inCombatLockdownCounter = 0
            getMacroInfoCounter = 0
            editMacroCounter = 0
            function InCombatLockdown()
               inCombatLockdownCounter = inCombatLockdownCounter + 1
               return testScenario == 'combat'
            end
            function GetMacroInfo(index)
               getMacroInfoCounter = getMacroInfoCounter + 1
               if testScenario == 'success' and index == 1 then
                   return 'testOne', 134401, '/say one'
               end
               if testScenario == 'duplicate' and (index == 1 or index == 2) then
                   return 'testDupe', 134401, '/say duplicate'
               end
               return nil
            end
            function GetActionInfo(slot)
               if testScenario == 'success' and slot == 5 then
                   return 'macro', 1
               end
               return nil
            end
            function EditMacro(index, name, icon, body, localFlag)
               editMacroCounter = editMacroCounter + 1
            end
            """;

            // Combine the original script with the testing code
            String modifiedScript = mainLuaContent + mockCode;

            // Load the modified script into Lua
            globals.load(modifiedScript).call();

            // Load test function
            LuaValue testExports = globals.get("TestExports");
            saveMacroSetFunction = testExports.get("SaveMacroSet");
            assertNotNull(saveMacroSetFunction, "SaveMacroSet function should not be null");

        } catch (IOException e) {
            failWithException("IOException occurred during setup", e);
        } catch (LuaError e) {
            failWithException("LuaError occurred during setup", e);
        }
    }

    @Test
    public void testSaveMacroSet_InCombat() {
        globals.load(
            """
            MacroSetsDB = {}
            MacroSetsBackup = {}
            testScenario = 'combat'
            lastPrintMessage = nil
            """
        ).call();

        saveMacroSetFunction.invoke(LuaValue.varargsOf(new LuaValue[] {
            LuaValue.valueOf("testSet"),
            LuaValue.valueOf("g")
        }));

        String expectedMessage = COLOR_VERMILLION +
            "Cannot perform this action during combat." +
            COLOR_RESET;
        assertTrue(globals.get("MacroSetsDB").get("testSet").isnil(), "MacroSetsDB should not include the set while in combat");
        assertEquals(1, globals.get("inCombatLockdownCounter").toint(), "Expected InCombatLockdown to be called 1 time");
        assertEquals(0, globals.get("getMacroInfoCounter").toint(), "Expected GetMacroInfo to be called 0 times");
        assertEquals(expectedMessage, globals.get("lastPrintMessage").tojstring(), "Expected combat message to be printed");
    }

    @Test
    public void testSaveMacroSet_Empty() {
        globals.load(
            """
            MacroSetsDB = {}
            MacroSetsBackup = {}
            testScenario = 'empty'
            lastPrintMessage = nil
            """
        ).call();

        saveMacroSetFunction.invoke(LuaValue.varargsOf(new LuaValue[] {
            LuaValue.valueOf("testSet"),
            LuaValue.valueOf("g")
        }));

        String expectedMessage = COLOR_VERMILLION +
            "No macros to save." +
            COLOR_RESET;
        assertTrue(globals.get("MacroSetsDB").get("testSet").isnil(), "MacroSetsDB should not include an empty set");
        assertTrue(globals.load("return next(MacroSetsBackup) == nil").call().toboolean(), "MacroSetsBackup should remain empty when no macros are saved");
        assertEquals(120, globals.get("getMacroInfoCounter").toint(), "Expected GetMacroInfo to be called 120 times");
        assertEquals(0, globals.get("editMacroCounter").toint(), "Expected EditMacro to be called 0 times");
        assertEquals(expectedMessage, globals.get("lastPrintMessage").tojstring(), "Expected empty macro set message to be printed");
    }

    @Test
    public void testSaveMacroSet_DuplicateNames() {
        globals.load(
            """
            MacroSetsDB = {}
            MacroSetsBackup = {}
            testScenario = 'duplicate'
            lastPrintMessage = nil
            """
        ).call();

        saveMacroSetFunction.invoke(LuaValue.varargsOf(new LuaValue[] {
            LuaValue.valueOf("testSet"),
            LuaValue.valueOf("g")
        }));

        String expectedMessage = COLOR_VERMILLION +
            "Failed to save set. All macros in a set must have unique names." +
            COLOR_RESET;
        assertTrue(globals.get("MacroSetsDB").get("testSet").isnil(), "MacroSetsDB should not include sets with duplicate macro names");
        assertEquals(4, globals.get("editMacroCounter").toint(), "Expected EditMacro to be called 4 times");
        assertEquals(expectedMessage, globals.get("lastPrintMessage").tojstring(), "Expected duplicate names message to be printed");
    }

    @Test
    public void testSaveMacroSet_GeneralSuccess() {
        globals.load(
            """
            MacroSetsDB = { existingSet = {macros = {}, type = 'g'} }
            MacroSetsBackup = {}
            testScenario = 'success'
            lastPrintMessage = nil
            """
        ).call();

        saveMacroSetFunction.invoke(LuaValue.varargsOf(new LuaValue[] {
            LuaValue.valueOf("testSet"),
            LuaValue.valueOf("g")
        }));

        LuaTable savedSet = globals.get("MacroSetsDB").get("testSet").checktable();
        LuaTable savedMacros = savedSet.get("macros").checktable();
        LuaTable savedMacro = savedMacros.get(1).checktable();
        LuaTable savedPositions = savedMacro.get("position").checktable();

        String expectedMessage = COLOR_GREEN +
            "General Macro set saved as 'testSet'." +
            COLOR_RESET;
        assertEquals("g", savedSet.get("type").tojstring(), "Expected saved set type to be g");
        assertEquals(1, savedSet.get("generalCount").toint(), "Expected saved set generalCount to be 1");
        assertEquals(0, savedSet.get("characterCount").toint(), "Expected saved set characterCount to be 0");
        assertFalse(savedSet.get("dupes").toboolean(), "Expected saved set dupes to be false");
        assertTrue(globals.get("MacroSetsBackup").get("existingSet").istable(), "MacroSetsBackup should include the set before save");
        assertEquals("testOne", savedMacro.get("name").tojstring(), "Expected saved macro name to be testOne");
        assertEquals(134400, savedMacro.get("icon").toint(), "Expected saved macro icon to be 134400");
        assertEquals("/say one", savedMacro.get("body").tojstring(), "Expected saved macro body to be /say one");
        assertEquals(1, savedPositions.length(), "Expected saved macro position count to be 1");
        assertEquals(5, savedPositions.get(1).toint(), "Expected saved macro position to be 5");
        assertEquals(2, globals.get("editMacroCounter").toint(), "Expected EditMacro to be called 2 times");
        assertEquals(expectedMessage, globals.get("lastPrintMessage").tojstring(), "Expected success message to be printed");
    }

    private void failWithException(String message, Exception e) {
        fail(message, e);
    }
}
