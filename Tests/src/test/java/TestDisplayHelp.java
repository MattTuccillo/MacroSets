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

public class TestDisplayHelp {
    private static final String COLOR_VERMILLION = "|cFFD55E00";
    private static final String COLOR_YELLOW = "|cFFF0E442";
    private static final String COLOR_RESET = "|r";

    private Globals globals;
    private LuaValue displayHelpFunction;

    @BeforeEach
    public void setup() {
        globals = JsePlatform.standardGlobals();
        globals.load("if SlashCmdList == nil then SlashCmdList = {} end").call();
        globals.load(
            """
            printCounter = 0
            lastPrintMessage = nil
            function print(...)
                printCounter = printCounter + 1
                local args = {...}
                local parts = {}
                for i = 1, #args do
                    parts[i] = tostring(args[i])
                end
                lastPrintMessage = table.concat(parts, ' ')
            end
            """
        ).call();

        try {
            // Load Main.lua contents as a string
            Path luaPath = Paths.get("../Main.lua").toRealPath();
            String mainLuaContent = new String(Files.readAllBytes(luaPath), StandardCharsets.UTF_8);

            // Mock testing code to append
            String mockCode = """

            TestExports = {DisplayHelp = DisplayHelp}
            """;

            // Combine the original script with the testing code
            String modifiedScript = mainLuaContent + mockCode;

            // Load the modified script into Lua
            globals.load(modifiedScript).call();

            // Load test function
            LuaValue testExports = globals.get("TestExports");
            displayHelpFunction = testExports.get("DisplayHelp");
            assertNotNull(displayHelpFunction, "DisplayHelp function should not be null");

        } catch (IOException e) {
            failWithException("IOException occurred during setup", e);
        } catch (LuaError e) {
            failWithException("LuaError occurred during setup", e);
        }
    }

    @Test
    public void testDisplayHelp_General() {
        displayHelpFunction.call();
        assertEquals(12, globals.get("printCounter").toint(), "Expected print to be called 12 times");
    }

    @Test
    public void testDisplayHelp_Save() {
        globals.load(
            """
            MacroSetsDB.charSpecific = false
            MacroSetsDB.dynamicIcons = false
            """
        ).call();

        displayHelpFunction.call(LuaValue.valueOf("save"));

        assertEquals(13, globals.get("printCounter").toint(), "Expected print to be called 13 times");
    }

    @Test
    public void testDisplayHelp_Load() {
        globals.load("MacroSetsDB.replaceBars = true").call();

        displayHelpFunction.call(LuaValue.valueOf("load"));

        assertEquals(8, globals.get("printCounter").toint(), "Expected print to be called 8 times");
    }

    @Test
    public void testDisplayHelp_Delete() {
        displayHelpFunction.call(LuaValue.valueOf("delete"));
        assertEquals(7, globals.get("printCounter").toint(), "Expected print to be called 7 times");
    }

    @Test
    public void testDisplayHelp_DeleteAll() {
        displayHelpFunction.call(LuaValue.valueOf("deleteall"));
        assertEquals(6, globals.get("printCounter").toint(), "Expected print to be called 6 times");
    }

    @Test
    public void testDisplayHelp_Undo() {
        displayHelpFunction.call(LuaValue.valueOf("undo"));
        assertEquals(12, globals.get("printCounter").toint(), "Expected print to be called 12 times");
    }

    @Test
    public void testDisplayHelp_List() {
        displayHelpFunction.call(LuaValue.valueOf("list"));
        assertEquals(10, globals.get("printCounter").toint(), "Expected print to be called 10 times");
    }

    @Test
    public void testDisplayHelp_Options() {
        displayHelpFunction.call(LuaValue.valueOf("options"));
        assertEquals(8, globals.get("printCounter").toint(), "Expected print to be called 8 times");
    }

    @Test
    public void testDisplayHelp_Invalid() {
        displayHelpFunction.call(LuaValue.valueOf("invalid"));

        String expectedMessage = COLOR_VERMILLION +
            "Invalid Command: Type " +
            COLOR_YELLOW +
            "'/ms help'" +
            COLOR_VERMILLION +
            " for a list of valid commands." +
            COLOR_RESET;
        assertEquals(1, globals.get("printCounter").toint(), "Expected print to be called 1 time");
        assertEquals(expectedMessage, globals.get("lastPrintMessage").tojstring(), "Expected invalid command message to be printed");
    }

    private void failWithException(String message, Exception e) {
        fail(message, e);
    }
}
