import static org.junit.jupiter.api.Assertions.*;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.luaj.vm2.*;
import org.luaj.vm2.lib.jse.JsePlatform;

import java.nio.file.Path;
import java.nio.file.Paths;
import java.io.IOException;

public class TestToggleActionBarPlacements {
    private Globals globals;
    private LuaValue macroSetsFunctions;
    private LuaValue macroSetsDB;

    @BeforeEach
    public void setup() {
        globals = JsePlatform.standardGlobals();
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
    public void testToggleActionBarPlacements_FromFalseToTrue() {
        LuaValue toggleFunction = macroSetsFunctions.get("ToggleActionBarPlacements");
        assertNotNull(toggleFunction, "ToggleActionBarPlacements function should not be null");

        // Ensure replaceBars exists in MacroSetsDB
        macroSetsDB.set("replaceBars", LuaValue.FALSE);
        assertFalse(macroSetsDB.get("replaceBars").toboolean(), "Expected replaceBars to be OFF initially");

        toggleFunction.call();
        assertTrue(macroSetsDB.get("replaceBars").toboolean(), "Expected replaceBars to be ON after toggle");
    }

    @Test
    public void testToggleActionBarPlacements_FromTrueToFalse() {
        LuaValue toggleFunction = macroSetsFunctions.get("ToggleActionBarPlacements");
        assertNotNull(toggleFunction, "ToggleActionBarPlacements function should not be null");

        // Ensure replaceBars exists in MacroSetsDB
        macroSetsDB.set("replaceBars", LuaValue.TRUE);
        assertTrue(macroSetsDB.get("replaceBars").toboolean(), "Expected replaceBars to be ON initially");

        toggleFunction.call();
        assertFalse(macroSetsDB.get("replaceBars").toboolean(), "Expected replaceBars to be OFF after toggle");
    }

    private void failWithException(String message, Exception e) {
        fail(message, e);
    }
}
