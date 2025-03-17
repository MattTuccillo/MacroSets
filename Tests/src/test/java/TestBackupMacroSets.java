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

public class TestBackupMacroSets {
    private Globals globals;
    private LuaValue backupMacroSetsFunction;

    @BeforeEach
    public void setup() {
        globals = JsePlatform.standardGlobals();
        globals.load("if SlashCmdList == nil then SlashCmdList = {} end").call();
        try {
            // Load Main.lua contents as a string
            Path luaPath = Paths.get("../Main.lua").toRealPath();
            String mainLuaContent = new String(Files.readAllBytes(luaPath), StandardCharsets.UTF_8);

            // Mock testing code to append
            String mockCode = "\n" +
                "TestExports = {BackupMacroSets = BackupMacroSets}\n" +
                
                "deepCopyTableCounter = 0\n" +
                "DeepCopyTable = function(table) deepCopyTableCounter = deepCopyTableCounter + 1 end\n";

            // Combine the original script with the testing code
            String modifiedScript = mainLuaContent + mockCode;

            // Load the modified script into Lua
            globals.load(modifiedScript).call();

            // Load test function
            LuaValue testExports = globals.get("TestExports");
            backupMacroSetsFunction = testExports.get("BackupMacroSets");
            assertNotNull(backupMacroSetsFunction, "BackupMacroSets function should not be null");

        } catch (IOException e) {
            failWithException("IOException occurred during setup", e);
        } catch (LuaError e) {
            failWithException("LuaError occurred during setup", e);
        }
    }
    
    @Test
    public void testBackupMacroSets_Empty() {
        backupMacroSetsFunction.call();
        assertEquals(0, globals.get("deepCopyTableCounter").toint(),  "printCounter expected to be 0");
    }
    
    @Test
    public void testBackupMacroSets_Filled() {
        LuaTable macroSetsDB = globals.get("MacroSetsDB").checktable();
        LuaTable testSetOne = LuaValue.tableOf();
        LuaTable testSetTwo = LuaValue.tableOf();
        macroSetsDB.set("testOne", testSetOne);
        macroSetsDB.set("testTwo", testSetTwo);
        backupMacroSetsFunction.call();
        assertEquals(2, globals.get("deepCopyTableCounter").toint(),  "printCounter expected to be 2");
    }

    private void failWithException(String message, Exception e) {
        e.printStackTrace();
        fail(message + ": " + e.getMessage());
    }
}
