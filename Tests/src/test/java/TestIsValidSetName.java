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

public class TestIsValidSetName {
    private Globals globals;
    private LuaValue isValidSetNameFunction;

    @BeforeEach
    public void setup() {
        // Initialize Lua environment
        globals = JsePlatform.standardGlobals();
        // Overrides
        globals.load("if SlashCmdList == nil then SlashCmdList = {} end").call();
        globals.load("print = function() end").call();

        try {
            // Load Main.lua contents as a string
            Path luaPath = Paths.get("../Main.lua").toRealPath();
            String mainLuaContent = new String(Files.readAllBytes(luaPath), StandardCharsets.UTF_8);

            // Mock testing code to append
            String mockCode = "\n" +
            "TestExports = {IsValidSetName = IsValidSetName}\n";

            // Combine the original script with the testing code
            String modifiedScript = mainLuaContent + mockCode;

            // Load the modified script into Lua
            globals.load(modifiedScript).call();

            // Load test function
            LuaValue testExports = globals.get("TestExports");
            isValidSetNameFunction = testExports.get("IsValidSetName");
            assertNotNull(isValidSetNameFunction, "IsValidSetName function should not be null");

        } catch (IOException e) {
            failWithException("IOException occurred during setup", e);
        } catch (LuaError e) {
            failWithException("LuaError occurred during setup", e);
        }
    }

    @Test
    public void testIsValidSetName_Normal() {
        assertTrue(isValidSetNameFunction.call(LuaValue.valueOf("ValidName")).toboolean(), "Expected 'ValidName' to be valid");
    }

    @Test
    public void testIsValidSetName_WithUnderscore() {
        assertTrue(isValidSetNameFunction.call(LuaValue.valueOf("valid_name")).toboolean(), "Expected 'valid_name' to be valid");
    }

    @Test
    public void testIsValidSetName_WithHyphen() {
        assertTrue(isValidSetNameFunction.call(LuaValue.valueOf("valid-name")).toboolean(), "Expected 'valid-name' to be valid");
    }

    @Test
    public void testIsValidSetName_WithNumbers() {
        assertTrue(isValidSetNameFunction.call(LuaValue.valueOf("MacroSet_01")).toboolean(), "Expected 'MacroSet_01' to be valid");
    }

    @Test
    public void testIsValidSetName_EmptyString() {
        assertFalse(isValidSetNameFunction.call(LuaValue.valueOf("")).toboolean(), "Expected empty string to be invalid");
    }

    @Test
    public void testIsValidSetName_SingleSpace() {
        assertFalse(isValidSetNameFunction.call(LuaValue.valueOf(" ")).toboolean(), "Expected whitespace to be invalid");
    }

    @Test
    public void testIsValidSetName_ContainsSpecialCharacter() {
        assertFalse(isValidSetNameFunction.call(LuaValue.valueOf("Invalid@Name")).toboolean(), "Expected 'Invalid@Name' to be invalid");
    }

    @Test
    public void testIsValidSetName_TooLong() {
        assertFalse(isValidSetNameFunction.call(LuaValue.valueOf("TooLongName_111111111111111111111111111111111111111")).toboolean(), 
            "Expected overly long name to be invalid");
    }

    @Test
    public void testIsValidSetName_ContainsSpaces() {
        assertFalse(isValidSetNameFunction.call(LuaValue.valueOf("Name With Spaces")).toboolean(), "Expected 'Name With Spaces' to be invalid");
    }

    private void failWithException(String message, Exception e) {
        e.printStackTrace();
        fail(message + ": " + e.getMessage());
    }
}
