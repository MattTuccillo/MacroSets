import static org.junit.jupiter.api.Assertions.*;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.luaj.vm2.*;
import org.luaj.vm2.lib.jse.JsePlatform;

import java.nio.file.Path;
import java.nio.file.Paths;
import java.io.IOException;

public class TestToggleCharSpecific {
    private Globals globals;
    LuaValue macroSetsFunctions;
    LuaValue macroSetsDB;

    @BeforeEach
    public void setup() {
        globals = JsePlatform.standardGlobals();
        globals.load("testingEnabled = true").call();
        globals.load("if SlashCmdList == nil then SlashCmdList = {} end").call();

        try {
            // Load Main.lua
            Path luaPath = Paths.get("../Main.lua").toRealPath();
            globals.loadfile(luaPath.toString()).call();

            macroSetsFunctions = globals.get("MacroSetsFunctions");
            macroSetsDB = globals.get("MacroSetsDB");

            assertNotNull(macroSetsFunctions, "MacroSetsFunctions should not be null");
            assertNotNull(macroSetsDB, "MacroSetsDB should not be null");
            assertTrue(macroSetsDB.istable(), "MacroSetsDB should be a table");

        } catch (IOException e) {
            failWithException("IOException occurred during setup", e);
        } catch (LuaError e) {
            failWithException("LuaError occurred during setup", e);
        }
    }

    @Test
    public void testToggleCharSpecific_FromFalseToTrue() {
        LuaValue toggleFunction = macroSetsFunctions.get("ToggleCharSpecific");
        assertNotNull(toggleFunction, "ToggleCharSpecific function should not be null");

        // Ensure charSpecific exists in MacroSetsDB
        macroSetsDB.set("charSpecific", LuaValue.FALSE);
        assertFalse(macroSetsDB.get("charSpecific").toboolean(), "Expected charSpecific to be OFF initially");

        // Call ToggleCharSpecific()
        LuaValue result = toggleFunction.call();
        assertNotNull(result, "ToggleCharSpecific should return a value");
        assertTrue(macroSetsDB.get("charSpecific").toboolean(), "Expected charSpecific to be ON after toggle");
    }

    @Test
    public void testToggleCharSpecific_FromTrueToFalse() {
        LuaValue toggleFunction = macroSetsFunctions.get("ToggleCharSpecific");
        assertNotNull(toggleFunction, "ToggleCharSpecific function should not be null");

        // Ensure charSpecific exists in MacroSetsDB
        macroSetsDB.set("charSpecific", LuaValue.TRUE);
        assertTrue(macroSetsDB.get("charSpecific").toboolean(), "Expected charSpecific to be ON initially");

        // Call ToggleCharSpecific()
        LuaValue result = toggleFunction.call();
        assertNotNull(result, "ToggleCharSpecific should return a value");
        assertFalse(macroSetsDB.get("charSpecific").toboolean(), "Expected charSpecific to be OFF after toggle");
    }

    private void failWithException(String message, Exception e) {
        e.printStackTrace();
        fail(message + ": " + e.getMessage());
    }
}
