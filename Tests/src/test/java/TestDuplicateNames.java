import static org.junit.jupiter.api.Assertions.*;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.luaj.vm2.*;
import org.luaj.vm2.lib.jse.JsePlatform;

import java.nio.file.Path;
import java.nio.file.Paths;
import java.io.IOException;

public class TestDuplicateNames {
    private Globals globals;
    private LuaValue duplicateNamesFunction;

    @BeforeEach
    public void setup() {
        // Initialize Lua environment
        globals = JsePlatform.standardGlobals();
        globals.load("if SlashCmdList == nil then SlashCmdList = {} end").call();

        try {
            // Load Main.lua
            Path luaPath = Paths.get("../Main.lua").toRealPath();
            globals.loadfile(luaPath.toString()).call();

            // Get function reference from TestExports
            LuaValue testExports = globals.get("TestExports");
            assertNotNull(testExports, "TestExports table should not be null");

            duplicateNamesFunction = testExports.get("DuplicateNames");
            assertNotNull(duplicateNamesFunction, "DuplicateNames function should not be null");

        } catch (IOException e) {
            failWithException("IOException occurred during setup", e);
        } catch (LuaError e) {
            failWithException("LuaError occurred during setup", e);
        }
    }
    
    @Test
    public void testDuplicateNames_True() {
        String luaScript = "macroNames = {'Macro1', 'Macro1'}";
        globals.load(luaScript).call();
        LuaValue dupeNames = globals.get("macroNames");
        assertTrue(duplicateNamesFunction.call(dupeNames).toboolean(), "Expected to be true");
    }

    @Test
    public void testDuplicateNames_False() {
        String luaScript = "macroNames = {'Macro1', 'Macro2'}";
        globals.load(luaScript).call();
        LuaValue noDupeNames = globals.get("macroNames");
        assertFalse(duplicateNamesFunction.call(noDupeNames).toboolean(), "Expected to be false");
    }

    private void failWithException(String message, Exception e) {
        e.printStackTrace();
        fail(message + ": " + e.getMessage());
    }
}
