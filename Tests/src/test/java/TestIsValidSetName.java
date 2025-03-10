import static org.junit.jupiter.api.Assertions.*;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.luaj.vm2.*;
import org.luaj.vm2.lib.jse.JsePlatform;

import java.nio.file.Path;
import java.nio.file.Paths;
import java.io.IOException;

public class TestIsValidSetName {
    private Globals globals;
    private LuaValue isValidSetNameFunction;

    @BeforeEach
    public void setup() {
        // Initialize Lua environment
        globals = JsePlatform.standardGlobals();

        try {
            // Load WoW mock first
            Path mockPath = Paths.get("src/resources/wow_mock.lua").toRealPath();
            globals.loadfile(mockPath.toString()).call();

            // Load Main.lua after the WoW mock
            Path luaPath = Paths.get("../Main.lua").toRealPath();
            globals.loadfile(luaPath.toString()).call();

            // Get function reference from TestExports
            LuaValue testExports = globals.get("TestExports");
            assertNotNull(testExports, "TestExports table should not be null");

            isValidSetNameFunction = testExports.get("IsValidSetName");
            assertNotNull(isValidSetNameFunction, "IsValidSetName function should not be null");

        } catch (IOException e) {
            failWithException("IOException occurred during setup", e);
        } catch (LuaError e) {
            failWithException("LuaError occurred during setup", e);
        }
    }

    @Test
    public void testValidName_Normal() {
        assertTrue(isValidSetNameFunction.call(LuaValue.valueOf("ValidName")).toboolean(), "Expected 'ValidName' to be valid");
    }

    @Test
    public void testValidName_WithUnderscore() {
        assertTrue(isValidSetNameFunction.call(LuaValue.valueOf("valid_name")).toboolean(), "Expected 'valid_name' to be valid");
    }

    @Test
    public void testValidName_WithHyphen() {
        assertTrue(isValidSetNameFunction.call(LuaValue.valueOf("valid-name")).toboolean(), "Expected 'valid-name' to be valid");
    }

    @Test
    public void testValidName_WithNumbers() {
        assertTrue(isValidSetNameFunction.call(LuaValue.valueOf("MacroSet_01")).toboolean(), "Expected 'MacroSet_01' to be valid");
    }

    @Test
    public void testInvalidName_EmptyString() {
        assertFalse(isValidSetNameFunction.call(LuaValue.valueOf("")).toboolean(), "Expected empty string to be invalid");
    }

    @Test
    public void testInvalidName_SingleSpace() {
        assertFalse(isValidSetNameFunction.call(LuaValue.valueOf(" ")).toboolean(), "Expected whitespace to be invalid");
    }

    @Test
    public void testInvalidName_ContainsSpecialCharacter() {
        assertFalse(isValidSetNameFunction.call(LuaValue.valueOf("Invalid@Name")).toboolean(), "Expected 'Invalid@Name' to be invalid");
    }

    @Test
    public void testInvalidName_TooLong() {
        assertFalse(isValidSetNameFunction.call(LuaValue.valueOf("TooLongName_111111111111111111111111111111111111111")).toboolean(), 
            "Expected overly long name to be invalid");
    }

    @Test
    public void testInvalidName_ContainsSpaces() {
        assertFalse(isValidSetNameFunction.call(LuaValue.valueOf("Name With Spaces")).toboolean(), "Expected 'Name With Spaces' to be invalid");
    }

    private void failWithException(String message, Exception e) {
        e.printStackTrace();
        fail(message + ": " + e.getMessage());
    }
}
