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

public class TestListMacroSets {
    private Globals globals;
    private LuaValue listMacroSetsFunction;
    private LuaValue sortedSetNames;

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
            String mockCode = "\n" +
                "TestExports = {\n" +
                "   ListMacroSets = ListMacroSets,\n" +
                "   sortedSetNames = sortedSetNames\n" +
                "}\n";

            // Combine the original script with the testing code
            String modifiedScript = mainLuaContent + mockCode;

            // Load the modified script into Lua
            globals.load(modifiedScript).call();

            // Load test function
            LuaValue testExports = globals.get("TestExports");
            listMacroSetsFunction = testExports.get("ListMacroSets");
            sortedSetNames = testExports.get("sortedSetNames");
            assertNotNull(listMacroSetsFunction, "ListMacroSets function should not be null");
            assertNotNull(sortedSetNames, "sortedSetNames should not be null");


        } catch (IOException e) {
            failWithException("IOException occurred during setup", e);
        } catch (LuaError e) {
            failWithException("LuaError occurred during setup", e);
        }
    }
    
    @Test
    public void TestListMacroSets_Empty() {
        listMacroSetsFunction.call();
        assertEquals(1, globals.get("printCounter").toint(), "printCounter expected to be 1");
    }

    @Test
    public void TestListMacroSets_Filled() {
        LuaTable macroSetsDB = globals.get("MacroSetsDB").checktable();

        LuaTable testSetOne = LuaValue.tableOf();
        testSetOne.set("macros", LuaValue.tableOf());
        testSetOne.set("type", LuaValue.valueOf("c"));

        LuaTable testSetTwo = LuaValue.tableOf();
        testSetTwo.set("macros", LuaValue.tableOf());
        testSetTwo.set("type", LuaValue.valueOf("g"));

        macroSetsDB.set("testOne", testSetOne);
        macroSetsDB.set("testTwo", testSetTwo);

        sortedSetNames.set(1, LuaValue.valueOf("testOne"));
        sortedSetNames.set(2, LuaValue.valueOf("testTwo"));

        listMacroSetsFunction.call();
        assertEquals(6, globals.get("printCounter").toint(),  "printCounter expected to be 6");
    }

    private void failWithException(String message, Exception e) {
        e.printStackTrace();
        fail(message + ": " + e.getMessage());
    }
}
