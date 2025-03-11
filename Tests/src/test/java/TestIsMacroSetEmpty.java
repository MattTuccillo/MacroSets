import static org.junit.jupiter.api.Assertions.*;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.luaj.vm2.*;
import org.luaj.vm2.lib.jse.JsePlatform;

import java.nio.file.Path;
import java.nio.file.Paths;
import java.io.IOException;

public class TestIsMacroSetEmpty {
    private Globals globals;
    private LuaValue isMacroSetEmptyFunction;

    @BeforeEach
    public void setup() {
        // Initialize Lua environment
        globals = JsePlatform.standardGlobals();
        globals.load("testingEnabled = true").call();
        globals.load("if SlashCmdList == nil then SlashCmdList = {} end").call();

        try {
            // Load Main.lua
            Path luaPath = Paths.get("../Main.lua").toRealPath();
            globals.loadfile(luaPath.toString()).call();

            // Get function reference from TestExports
            LuaValue testExports = globals.get("TestExports");
            assertNotNull(testExports, "TestExports table should not be null");

            isMacroSetEmptyFunction = testExports.get("IsMacroSetEmpty");
            assertNotNull(isMacroSetEmptyFunction, "IsMacroSetEmpty function should not be null");

        } catch (IOException e) {
            failWithException("IOException occurred during setup", e);
        } catch (LuaError e) {
            failWithException("LuaError occurred during setup", e);
        }
    }

    @Test
    public void testIsMacroSetEmpty_GeneralEmpty() {
        assertTrue(isMacroSetEmptyFunction.call(
            LuaValue.valueOf(0), 
            LuaValue.valueOf(0), 
            LuaValue.valueOf("g")
            ).toboolean(), "Expected to be true");
    }

    @Test
    public void testIsMacroSetEmpty_CharacterEmpty() {
        assertTrue(isMacroSetEmptyFunction.call(
            LuaValue.valueOf(0), 
            LuaValue.valueOf(0), 
            LuaValue.valueOf("c")
            ).toboolean(), "Expected to be true");
    }

    @Test
    public void testIsMacroSetEmpty_BothEmpty() {
        assertTrue(isMacroSetEmptyFunction.call(
            LuaValue.valueOf(0), 
            LuaValue.valueOf(0), 
            LuaValue.valueOf("both")
            ).toboolean(), "Expected to be true");
    }

    @Test
    public void testIsMacroSetEmpty_CharacterNotEmpty() {
        assertFalse(isMacroSetEmptyFunction.call(
            LuaValue.valueOf(0), 
            LuaValue.valueOf(5), 
            LuaValue.valueOf("c")
            ).toboolean(), "Expected to be false");
    }

    @Test
    public void testIsMacroSetEmpty_GeneralNotEmpty() {
        assertFalse(isMacroSetEmptyFunction.call(
            LuaValue.valueOf(5), 
            LuaValue.valueOf(0), 
            LuaValue.valueOf("g")
            ).toboolean(), "Expected to be false");
    }

    @Test
    public void testIsMacroSetEmpty_BothNotEmpty() {
        assertFalse(isMacroSetEmptyFunction.call(
            LuaValue.valueOf(5), 
            LuaValue.valueOf(5), 
            LuaValue.valueOf("both")
            ).toboolean(), "Expected to be false");
    }

    private void failWithException(String message, Exception e) {
        e.printStackTrace();
        fail(message + ": " + e.getMessage());
    }
}
