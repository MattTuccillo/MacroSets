import static org.junit.jupiter.api.Assertions.*;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.luaj.vm2.*;
import org.luaj.vm2.lib.jse.JsePlatform;

import java.nio.file.Path;
import java.nio.file.Paths;
import java.io.IOException;

public class TestToggleDynamicIcons {
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
    public void testToggleDynamicIcons_FromFalseToTrue() {
        LuaValue toggleFunction = macroSetsFunctions.get("ToggleDynamicIcons");
        assertNotNull(toggleFunction, "ToggleDynamicIcons function should not be null");

        // Ensure dynamicIcons exists in MacroSetsDB
        macroSetsDB.set("dynamicIcons", LuaValue.FALSE);
        assertFalse(macroSetsDB.get("dynamicIcons").toboolean(), "Expected dynamicIcons to be OFF initially");

        // Call ToggleDynamicIcons()
        LuaValue result = toggleFunction.call();
        assertNotNull(result, "ToggleDynamicIcons should return a value");
        assertTrue(macroSetsDB.get("dynamicIcons").toboolean(), "Expected dynamicIcons to be ON after toggle");
    }

    @Test
    public void testToggleDynamicIcons_FromTrueToFalse() {
        LuaValue toggleFunction = macroSetsFunctions.get("ToggleDynamicIcons");
        assertNotNull(toggleFunction, "ToggleDynamicIcons function should not be null");

        // Ensure dynamicIcons exists in MacroSetsDB
        macroSetsDB.set("dynamicIcons", LuaValue.TRUE);
        assertTrue(macroSetsDB.get("dynamicIcons").toboolean(), "Expected dynamicIcons to be ON initially");

        // Call ToggleDynamicIcons()
        LuaValue result = toggleFunction.call();
        assertNotNull(result, "ToggleDynamicIcons should return a value");
        assertFalse(macroSetsDB.get("dynamicIcons").toboolean(), "Expected dynamicIcons to be OFF after toggle");
    }

    private void failWithException(String message, Exception e) {
        e.printStackTrace();
        fail(message + ": " + e.getMessage());
    }
}
