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

public class TestUndoLastOperation {
    private static final String COLOR_GREEN = "|cFF009E73";
    private static final String COLOR_VERMILLION = "|cFFD55E00";
    private static final String COLOR_RESET = "|r";

    private Globals globals;
    private LuaValue undoLastOperationFunction;

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

            TestExports = {UndoLastOperation = UndoLastOperation}
            """;

            // Combine the original script with the testing code
            String modifiedScript = mainLuaContent + mockCode;

            // Load the modified script into Lua
            globals.load(modifiedScript).call();

            // Load test function
            LuaValue testExports = globals.get("TestExports");
            undoLastOperationFunction = testExports.get("UndoLastOperation");
            assertNotNull(undoLastOperationFunction, "UndoLastOperation function should not be null");

        } catch (IOException e) {
            failWithException("IOException occurred during setup", e);
        } catch (LuaError e) {
            failWithException("LuaError occurred during setup", e);
        }
    }

    @Test
    public void testUndoLastOperation_EmptyBackup() {
        globals.load(
            """
            MacroSetsDB = {
               currentSet = {macros = {}, type = 'g'}
            }
            MacroSetsBackup = {}
            lastPrintMessage = nil
            """
        ).call();

        undoLastOperationFunction.call();

        String expectedMessage = COLOR_VERMILLION +
            "No previous action to undo." +
            COLOR_RESET;
        assertTrue(globals.get("MacroSetsDB").get("currentSet").istable(), "MacroSetsDB should remain unchanged when there is no backup");
        assertTrue(globals.get("MacroSetsBackup").get("currentSet").isnil(), "MacroSetsBackup should remain empty when there is no backup");
        assertEquals(expectedMessage, globals.get("lastPrintMessage").tojstring(), "Expected no-op message to be printed");
    }

    @Test
    public void testUndoLastOperation_RestoresBackup() {
        globals.load(
            """
            MacroSetsDB = {
               currentSet = {macros = {}, type = 'g'},
               dynamicIcons = true,
               replaceBars = false,
               charSpecific = true
            }
            MacroSetsBackup = {
               previousSet = {macros = {{name = 'testOne', icon = 134400, body = '/say one'}}, type = 'c'},
               dynamicIcons = false,
               replaceBars = true,
               charSpecific = false
            }
            lastPrintMessage = nil
            """
        ).call();

        undoLastOperationFunction.call();

        LuaTable macroSetsDB = globals.get("MacroSetsDB").checktable();
        LuaTable macroSetsBackup = globals.get("MacroSetsBackup").checktable();
        LuaTable restoredSet = macroSetsDB.get("previousSet").checktable();
        LuaTable restoredMacro = restoredSet.get("macros").get(1).checktable();

        String expectedMessage = COLOR_GREEN +
            "Previous action successfully undone." +
            COLOR_RESET;
        assertTrue(macroSetsDB.get("currentSet").isnil(), "MacroSetsDB should not include the current set after undo");
        assertTrue(macroSetsBackup.get("currentSet").istable(), "MacroSetsBackup should include the set before undo");
        assertTrue(macroSetsBackup.get("dynamicIcons").isnil(), "MacroSetsBackup should not store settings");
        assertTrue(macroSetsDB.get("dynamicIcons").toboolean(), "Undo should preserve dynamicIcons setting");
        assertFalse(macroSetsDB.get("replaceBars").toboolean(), "Undo should preserve replaceBars setting");
        assertTrue(macroSetsDB.get("charSpecific").toboolean(), "Undo should preserve charSpecific setting");
        assertEquals("c", restoredSet.get("type").tojstring(), "Expected restored set type to be c");
        assertEquals("testOne", restoredMacro.get("name").tojstring(), "Expected restored macro name to be testOne");
        assertEquals(134400, restoredMacro.get("icon").toint(), "Expected restored macro icon to be 134400");
        assertEquals("/say one", restoredMacro.get("body").tojstring(), "Expected restored macro body to be /say one");
        assertEquals(expectedMessage, globals.get("lastPrintMessage").tojstring(), "Expected success message to be printed");
    }

    private void failWithException(String message, Exception e) {
        fail(message, e);
    }
}
