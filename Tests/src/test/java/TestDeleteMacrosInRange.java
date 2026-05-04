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

public class TestDeleteMacrosInRange {
    private Globals globals;
    private LuaValue deleteMacrosInRangeFunction;

    @BeforeEach
    public void setup() {
        globals = JsePlatform.standardGlobals();
        globals.load("if SlashCmdList == nil then SlashCmdList = {} end").call();
        globals.load("print = function() end").call();

        try {
            // Load Main.lua contents as a string
            Path luaPath = Paths.get("../Main.lua").toRealPath();
            String mainLuaContent = new String(Files.readAllBytes(luaPath), StandardCharsets.UTF_8);

            // Mock testing code to append
            String mockCode = "\n" +
                "TestExports = {DeleteMacrosInRange = DeleteMacrosInRange}\n" +

                "getMacroInfoCounter = 0\n" +
                "deleteMacroCounter = 0\n" +

                "function GetMacroInfo(macroIndex)\n" +
                "   getMacroInfoCounter = getMacroInfoCounter + 1\n" +
                "   if (macroIndex > 3) then\n" +
                "       return nil\n" +
                "   end\n" +
                "   return 'test', 134400, 'test'\n" +
                "end\n" +

                "function DeleteMacro(macroIndex)\n" +
                "   deleteMacroCounter = deleteMacroCounter + 1\n" +
                "end\n";

            // Combine the original script with the testing code
            String modifiedScript = mainLuaContent + mockCode;

            // Load the modified script into Lua
            globals.load(modifiedScript).call();

            // Load test function
            LuaValue testExports = globals.get("TestExports");
            deleteMacrosInRangeFunction = testExports.get("DeleteMacrosInRange");
            assertNotNull(deleteMacrosInRangeFunction, "DeleteMacrosInRange function should not be null");

        } catch (IOException e) {
            failWithException("IOException occurred during setup", e);
        } catch (LuaError e) {
            failWithException("LuaError occurred during setup", e);
        }
    }
    
    @Test
    public void testDeleteMacrosInRange_Full() {
        deleteMacrosInRangeFunction.invoke(LuaValue.varargsOf(new LuaValue[] {
            LuaValue.valueOf(1),
            LuaValue.valueOf(3)
        }));
        assertEquals(3, globals.get("getMacroInfoCounter").toint(), "Expected GetMacroInfo to be called 3 times");
        assertEquals(3, globals.get("deleteMacroCounter").toint(), "Expected DeleteMacro to be called 3 times");
    }

    @Test
    public void testDeleteMacrosInRange_Half() {
        deleteMacrosInRangeFunction.invoke(LuaValue.varargsOf(new LuaValue[] {
            LuaValue.valueOf(1),
            LuaValue.valueOf(6)
        }));
        assertEquals(6, globals.get("getMacroInfoCounter").toint(), "Expected GetMacroInfo to be called 6 times");
        assertEquals(3, globals.get("deleteMacroCounter").toint(), "Expected DeleteMacro to be called 3 times");
    }

    @Test
    public void testDeleteMacrosInRange_None() {
        deleteMacrosInRangeFunction.invoke(LuaValue.varargsOf(new LuaValue[] {
            LuaValue.valueOf(4),
            LuaValue.valueOf(6)
        }));
        assertEquals(3, globals.get("getMacroInfoCounter").toint(), "Expected GetMacroInfo to be called 3 times");
        assertEquals(0, globals.get("deleteMacroCounter").toint(), "Expected DeleteMacro to be called 0 times");
    }

    private void failWithException(String message, Exception e) {
        e.printStackTrace();
        fail(message + ": " + e.getMessage());
    }
}
