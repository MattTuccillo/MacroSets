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

public class TestSetMacroSlotRanges {
    private Globals globals;
    private LuaValue setMacroSlotRangesFunction;

    @BeforeEach
    public void setup() {
        // Initialize Lua environment
        globals = JsePlatform.standardGlobals();
        globals.load("if SlashCmdList == nil then SlashCmdList = {} end").call();

        try {
            // Load Main.lua contents as a string
            Path luaPath = Paths.get("../Main.lua").toRealPath();
            String mainLuaContent = new String(Files.readAllBytes(luaPath), StandardCharsets.UTF_8);

            // Mock testing code to append
            String mockCode = "\n" +
            "TestExports = {SetMacroSlotRanges = SetMacroSlotRanges}\n";

            // Combine the original script with the testing code
            String modifiedScript = mainLuaContent + mockCode;

            // Load the modified script into Lua
            globals.load(modifiedScript).call();

            // Load test function
            LuaValue testExports = globals.get("TestExports");
            setMacroSlotRangesFunction = testExports.get("SetMacroSlotRanges");
            assertNotNull(setMacroSlotRangesFunction, "SetMacroSlotRanges function should not be null");

        } catch (IOException e) {
            failWithException("IOException occurred during setup", e);
        } catch (LuaError e) {
            failWithException("LuaError occurred during setup", e);
        }
    }

    @Test
    public void testSetMacroSlotRanges_General() {
        Varargs result = setMacroSlotRangesFunction.invoke(LuaValue.valueOf("g"));
        assertEquals(1, result.arg1().toint(), "Expected start slot to be 1");
        assertEquals(120, result.arg(2).toint(), "Expected end slot to be 120");
    }

    @Test
    public void testSetMacroSlotRanges_Character() {
        Varargs result = setMacroSlotRangesFunction.invoke(LuaValue.valueOf("c"));
        assertEquals(121, result.arg1().toint(), "Expected start slot to be 121");
        assertEquals(150, result.arg(2).toint(), "Expected end slot to be 150");
    }

    @Test
    public void testSetMacroSlotRanges_Default() {
        Varargs result = setMacroSlotRangesFunction.invoke(LuaValue.valueOf("unknown"));
        assertEquals(1, result.arg1().toint(), "Expected start slot to be 1");
        assertEquals(150, result.arg(2).toint(), "Expected end slot to be 150");
    }

    private void failWithException(String message, Exception e) {
        e.printStackTrace();
        fail(message + ": " + e.getMessage());
    }
}
