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

public class TestDeleteAllMacroSets {
    private Globals globals;
    private LuaValue deleteAllMacroSetsFunction;

    @BeforeEach
    public void setup() {
        globals = JsePlatform.standardGlobals();
        globals.load("if SlashCmdList == nil then SlashCmdList = {} end").call();
        globals.load("print = function() end").call();

        try {
            // Load Main.lua contents as a string
            Path luaPath = Paths.get("../Main.lua").toRealPath();
            String mainLuaContent = new String(Files.readAllBytes(luaPath), StandardCharsets.UTF_8);

            // Mock testing code to append
            String mockCode = "\n" +
                "TestExports = {DeleteAllMacroSets = DeleteAllMacroSets}\n" +

                "backupMacroSetsCalled = false\n" +

                "function BackupMacroSets()\n" +
                "   backupMacroSetsCalled = true\n" +
                "end\n";

            // Combine the original script with the testing code
            String modifiedScript = mainLuaContent + mockCode;

            // Load the modified script into Lua
            globals.load(modifiedScript).call();

            // Load test function
            LuaValue testExports = globals.get("TestExports");
            deleteAllMacroSetsFunction = testExports.get("DeleteAllMacroSets");
            assertNotNull(deleteAllMacroSetsFunction, "DeleteAllMacroSets function should not be null");

        } catch (IOException e) {
            failWithException("IOException occurred during setup", e);
        } catch (LuaError e) {
            failWithException("LuaError occurred during setup", e);
        }
    }
    
    @Test
    public void testDeleteAllMacroSets() {
        LuaTable macroSetsDB = globals.get("MacroSetsDB").checktable();
        assertTrue(globals.load("return next(MacroSetsDB) == nil").call().toboolean(), "MacroSetsDB expected to be empty.");
        macroSetsDB.set("testOne", LuaValue.tableOf());
        macroSetsDB.set("testTwo", LuaValue.tableOf());
        assertFalse(globals.load("return next(MacroSetsDB) == nil").call().toboolean(), "MacroSetsDB expected to not be empty.");
        deleteAllMacroSetsFunction.call();
        assertTrue(globals.load("return next(MacroSetsDB) == nil").call().toboolean(), "MacroSetsDB expected to be empty.");
    }

    private void failWithException(String message, Exception e) {
        e.printStackTrace();
        fail(message + ": " + e.getMessage());
    }
}
