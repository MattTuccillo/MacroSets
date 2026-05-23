import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.junit.jupiter.api.Assertions.fail;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.luaj.vm2.Globals;
import org.luaj.vm2.LuaError;
import org.luaj.vm2.LuaTable;
import org.luaj.vm2.LuaValue;
import org.luaj.vm2.lib.jse.JsePlatform;

public class TestDeleteMacroSet {
    private static final String COLOR_VERMILLION = "|cFFD55E00";
    private static final String COLOR_GREEN = "|cFF009E73";
    private static final String COLOR_RESET = "|r";

    private Globals globals;
    private LuaValue deleteMacroSetFunction;

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

            TestExports = {DeleteMacroSet = DeleteMacroSet}
            """;

            // Combine the original script with the testing code
            String modifiedScript = mainLuaContent + mockCode;

            // Load the modified script into Lua
            globals.load(modifiedScript).call();

            // Load test function
            LuaValue testExports = globals.get("TestExports");
            deleteMacroSetFunction = testExports.get("DeleteMacroSet");
            assertNotNull(deleteMacroSetFunction, "DeleteMacroSet function should not be null");

        } catch (IOException e) {
            failWithException("IOException occurred during setup", e);
        } catch (LuaError e) {
            failWithException("LuaError occurred during setup", e);
        }
    }

    @Test
    public void testDeleteMacroSet_InvalidName() {
        globals.load(
            """
            MacroSetsDB = {}
            MacroSetsBackup = {}
            lastPrintMessage = nil
            """
        ).call();

        LuaTable macroSetsDB = globals.get("MacroSetsDB").checktable();
        LuaTable existingSet = LuaValue.tableOf();
        macroSetsDB.set("existingSet", existingSet);

        deleteMacroSetFunction.call(LuaValue.valueOf("invalid set"));

        assertTrue(macroSetsDB.get("existingSet").istable(), "Existing macro sets should remain untouched");
        assertTrue(globals.load("return next(MacroSetsBackup) == nil").call().toboolean(), "MacroSetsBackup should remain empty for invalid names");
    }

    @Test
    public void testDeleteMacroSet_SetDoesNotExist() {
        globals.load(
            """
            MacroSetsDB = {}
            MacroSetsBackup = {}
            lastPrintMessage = nil
            """
        ).call();

        LuaTable macroSetsDB = globals.get("MacroSetsDB").checktable();
        LuaTable otherSet = LuaValue.tableOf();
        macroSetsDB.set("otherSet", otherSet);

        deleteMacroSetFunction.call(LuaValue.valueOf("missingSet"));

        assertTrue(macroSetsDB.get("otherSet").istable(), "Other macro sets should remain");

        String expectedMessage = COLOR_VERMILLION +
            "Macro set 'missingSet' not found." +
            COLOR_RESET;
        assertTrue(globals.load("return next(MacroSetsBackup) == nil").call().toboolean(), "MacroSetsBackup should remain empty when the set is missing");
        assertEquals(expectedMessage, globals.get("lastPrintMessage").tojstring(), "Expected not-found message to be printed");
    }

    @Test
    public void testDeleteMacroSet_SetExists() {
        globals.load(
            """
            MacroSetsDB = {}
            MacroSetsBackup = {}
            lastPrintMessage = nil
            """
        ).call();

        LuaTable macroSetsDB = globals.get("MacroSetsDB").checktable();
        LuaTable targetSet = LuaValue.tableOf();
        targetSet.set("macros", LuaValue.tableOf());
        macroSetsDB.set("existingSet", targetSet);

        deleteMacroSetFunction.call(LuaValue.valueOf("existingSet"));

        assertTrue(macroSetsDB.get("existingSet").isnil(), "Existing set should be removed from MacroSetsDB");
        assertTrue(globals.get("MacroSetsBackup").get("existingSet").istable(), "MacroSetsBackup should include the set before deletion");

        String expectedMessage = COLOR_GREEN +
            "Macro set 'existingSet' has been deleted." +
            COLOR_RESET;
        assertEquals(expectedMessage, globals.get("lastPrintMessage").tojstring(), "Expected success message to be printed");
    }

    private void failWithException(String message, Exception e) {
        fail(message, e);
    }
}
