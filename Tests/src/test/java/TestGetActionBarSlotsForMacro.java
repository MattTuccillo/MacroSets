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

public class TestGetActionBarSlotsForMacro {
    private Globals globals;
    private LuaValue getSlotsFunction;

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
                "TestExports = {GetActionBarSlotsForMacro = GetActionBarSlotsForMacro}\n" +
                "function GetActionInfo(slot)\n" +
                "   if slot == 5 then return 'macro', 1 end\n" +
                "   if slot == 10 then return 'macro', 2 end\n" +
                "   if slot == 20 then return 'macro', 1 end\n" +
                "   return nil\n" +
                "end\n" +
                "function GetMacroInfo(id)\n" +
                "   if id == 1 then return 'TestMacro', 134400, 'body' end\n" +
                "   if id == 2 then return 'OtherMacro', 134401, 'body2' end\n" +
                "   return nil\n" +
                "end\n";

            // Combine the original script with the testing code
            String modifiedScript = mainLuaContent + mockCode;

            // Load the modified script into Lua
            globals.load(modifiedScript).call();

            // Load test function
            LuaValue testExports = globals.get("TestExports");
            getSlotsFunction = testExports.get("GetActionBarSlotsForMacro");
            assertNotNull(getSlotsFunction, "GetActionBarSlotsForMacro function should not be null");

        } catch (IOException e) {
            failWithException("IOException occurred during setup", e);
        } catch (LuaError e) {
            failWithException("LuaError occurred during setup", e);
        }
    }

    @Test
    public void testGetActionBarSlotsForMacro_Found() {
        LuaValue result = getSlotsFunction.call(LuaValue.valueOf("TestMacro"));
        assertTrue(result.istable(), "Expected result to be a table");
        assertEquals(2, result.length(), "Expected two slots");
        assertEquals(5, result.get(1).toint(), "Expected first slot to be 5");
        assertEquals(20, result.get(2).toint(), "Expected second slot to be 20");
    }

    @Test
    public void testGetActionBarSlotsForMacro_NotFound() {
        LuaValue result = getSlotsFunction.call(LuaValue.valueOf("MissingMacro"));
        assertTrue(result.istable(), "Expected result to be a table");
        assertEquals(0, result.length(), "Expected empty result for missing macro");
    }

    private void failWithException(String message, Exception e) {
        e.printStackTrace();
        fail(message + ": " + e.getMessage());
    }
}