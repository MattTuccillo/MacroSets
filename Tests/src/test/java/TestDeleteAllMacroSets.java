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
            String mockCode = """

            TestExports = {DeleteAllMacroSets = DeleteAllMacroSets}
            backupMacroSetsCalled = false
            function BackupMacroSets()
               backupMacroSetsCalled = true
            end
            """;

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
        LuaTable testSetOne = LuaValue.tableOf();
        LuaTable testSetTwo = LuaValue.tableOf();
        testSetOne.set("macros", LuaValue.tableOf());
        testSetTwo.set("macros", LuaValue.tableOf());
        macroSetsDB.set("testOne", testSetOne);
        macroSetsDB.set("testTwo", testSetTwo);
        macroSetsDB.set("dynamicIcons", LuaValue.TRUE);
        assertFalse(globals.load("return next(MacroSetsDB) == nil").call().toboolean(), "MacroSetsDB expected to not be empty.");
        deleteAllMacroSetsFunction.call();
        assertTrue(macroSetsDB.get("testOne").isnil(), "MacroSetsDB should not include testOne after delete all.");
        assertTrue(macroSetsDB.get("testTwo").isnil(), "MacroSetsDB should not include testTwo after delete all.");
        assertTrue(macroSetsDB.get("dynamicIcons").toboolean(), "Delete all should preserve settings.");
        assertTrue(globals.get("backupMacroSetsCalled").toboolean(), "Expected BackupMacroSets to be called");
    }

    private void failWithException(String message, Exception e) {
        fail(message, e);
    }
}
