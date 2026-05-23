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

public class TestDebugMessage {
    private Globals globals;
    private LuaValue debugMessageFunction;
    private LuaValue debugTable;

    @BeforeEach
    public void setup() {
        globals = JsePlatform.standardGlobals();
        globals.load("if SlashCmdList == nil then SlashCmdList = {} end").call();
        globals.load("printCounter = 0").call();
        globals.load("print = function() printCounter = printCounter + 1 end").call();

        try {
            // Load Main.lua contents as a string
            Path luaPath = Paths.get("../Main.lua").toRealPath();
            String mainLuaContent = new String(Files.readAllBytes(luaPath), StandardCharsets.UTF_8);

            // Mock testing code to append
            String mockCode = """

            TestExports = {   DebugMessage = DebugMessage,   debug = debug}
            """;

            // Combine the original script with the testing code
            String modifiedScript = mainLuaContent + mockCode;

            // Load the modified script into Lua
            globals.load(modifiedScript).call();

            // Load test function
            LuaValue testExports = globals.get("TestExports");
            debugMessageFunction = testExports.get("DebugMessage");
            debugTable = testExports.get("debug");
            assertNotNull(debugMessageFunction, "DebugMessage function should not be null");
            assertNotNull(debugTable, "debug table should not be null");
        } catch (IOException e) {
            failWithException("IOException occurred during setup", e);
        } catch (LuaError e) {
            failWithException("LuaError occurred during setup", e);
        }
    }

    @Test
    public void testDebugMessage_AllFunctionsTrue() {
        debugTable.set("allFunctions", LuaValue.TRUE);
        debugMessageFunction.invoke(LuaValue.varargsOf(new LuaValue[] {
            LuaValue.valueOf("test"), LuaValue.FALSE
        }));
        assertEquals(1, globals.get("printCounter").toint(), "Expected print to be called");
    }

    @Test
    public void testDebugMessage_FlagTrue() {
        debugTable.set("allFunctions", LuaValue.FALSE);
        debugMessageFunction.invoke(LuaValue.varargsOf(new LuaValue[] {
            LuaValue.valueOf("test"), LuaValue.TRUE
        }));
        assertEquals(1, globals.get("printCounter").toint(), "Expected print to be called when flag true");
    }

    @Test
    public void testDebugMessage_NotPrinted() {
        debugTable.set("allFunctions", LuaValue.FALSE);
        debugMessageFunction.invoke(LuaValue.varargsOf(new LuaValue[] {
            LuaValue.valueOf("test"), LuaValue.FALSE
        }));
        assertEquals(0, globals.get("printCounter").toint(), "Expected print to not be called");
    }

    private void failWithException(String message, Exception e) {
        fail(message, e);
    }
}