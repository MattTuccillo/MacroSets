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

public class TestRestoreMacroBodies {
    private Globals globals;
    private LuaValue restoreMacroBodiesFunction;

    @BeforeEach
    public void setup() {
        globals = JsePlatform.standardGlobals();
        globals.load("if SlashCmdList == nil then SlashCmdList = {} end").call();

        try {
            // Load Main.lua contents as a string
            Path luaPath = Paths.get("../Main.lua").toRealPath();
            String mainLuaContent = new String(Files.readAllBytes(luaPath), StandardCharsets.UTF_8);

            // Mock testing code to append
            String mockCode = """

            TestExports = {RestoreMacroBodies = RestoreMacroBodies}
            getMacroIndexByNameCounter = 0
            editMacroCounter = 0
            lastEditMacroIndex = nil
            lastEditMacroName = nil
            lastEditMacroIcon = nil
            lastEditMacroBody = nil
            function GetMacroIndexByName(name)
               getMacroIndexByNameCounter = getMacroIndexByNameCounter + 1
               if name == 'testOne' then return 1 end
               if name == 'testTwo' then return 2 end
               return nil
            end
            function EditMacro(index, name, icon, body)
               editMacroCounter = editMacroCounter + 1
               lastEditMacroIndex = index
               lastEditMacroName = name
               lastEditMacroIcon = icon
               lastEditMacroBody = body
            end
            """;

            // Combine the original script with the testing code
            String modifiedScript = mainLuaContent + mockCode;

            // Load the modified script into Lua
            globals.load(modifiedScript).call();

            // Load test function
            LuaValue testExports = globals.get("TestExports");
            restoreMacroBodiesFunction = testExports.get("RestoreMacroBodies");
            assertNotNull(restoreMacroBodiesFunction, "RestoreMacroBodies function should not be null");

        } catch (IOException e) {
            failWithException("IOException occurred during setup", e);
        } catch (LuaError e) {
            failWithException("LuaError occurred during setup", e);
        }
    }

    @Test
    public void testRestoreMacroBodies_Empty() {
        LuaTable macroSetsDB = globals.get("MacroSetsDB").checktable();
        LuaTable testSet = LuaValue.tableOf();
        testSet.set("macros", LuaValue.tableOf());
        macroSetsDB.set("testSet", testSet);

        restoreMacroBodiesFunction.call(LuaValue.valueOf("testSet"));

        assertEquals(0, globals.get("getMacroIndexByNameCounter").toint(), "Expected GetMacroIndexByName to be called 0 times");
        assertEquals(0, globals.get("editMacroCounter").toint(), "Expected EditMacro to be called 0 times");
    }

    @Test
    public void testRestoreMacroBodies_Filled() {
        LuaTable macroSetsDB = globals.get("MacroSetsDB").checktable();
        LuaTable testSet = LuaValue.tableOf();
        LuaTable macros = LuaValue.tableOf();

        LuaTable testMacroOne = LuaValue.tableOf();
        testMacroOne.set("name", LuaValue.valueOf("testOne"));
        testMacroOne.set("icon", LuaValue.valueOf(134400));
        testMacroOne.set("body", LuaValue.valueOf("/say one"));

        LuaTable testMacroTwo = LuaValue.tableOf();
        testMacroTwo.set("name", LuaValue.valueOf("testTwo"));
        testMacroTwo.set("icon", LuaValue.valueOf(134401));
        testMacroTwo.set("body", LuaValue.valueOf("/say two"));

        macros.set(1, testMacroOne);
        macros.set(2, testMacroTwo);
        testSet.set("macros", macros);
        macroSetsDB.set("testSet", testSet);

        restoreMacroBodiesFunction.call(LuaValue.valueOf("testSet"));

        assertEquals(2, globals.get("getMacroIndexByNameCounter").toint(), "Expected GetMacroIndexByName to be called 2 times");
        assertEquals(2, globals.get("editMacroCounter").toint(), "Expected EditMacro to be called 2 times");
        assertEquals(2, globals.get("lastEditMacroIndex").toint(), "Expected last macro index to be 2");
        assertEquals("testTwo", globals.get("lastEditMacroName").tojstring(), "Expected last macro name to be testTwo");
        assertEquals(134401, globals.get("lastEditMacroIcon").toint(), "Expected last macro icon to be 134401");
        assertEquals("/say two", globals.get("lastEditMacroBody").tojstring(), "Expected last macro body to be /say two");
    }

    private void failWithException(String message, Exception e) {
        fail(message, e);
    }
}
