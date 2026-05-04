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

public class TestAlphabetizeMacroSets {
    private Globals globals;
    private LuaValue alphabetizeMacroSetsFunction;

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
                "TestExports = {AlphabetizeMacroSets = AlphabetizeMacroSets}\n";

            // Combine the original script with the testing code
            String modifiedScript = mainLuaContent + mockCode;

            // Load the modified script into Lua
            globals.load(modifiedScript).call();

            // Load test function
            LuaValue testExports = globals.get("TestExports");
            alphabetizeMacroSetsFunction = testExports.get("AlphabetizeMacroSets");
            assertNotNull(alphabetizeMacroSetsFunction, "AlphabetizeMacroSets function should not be null");
        } catch (IOException e) {
            failWithException("IOException occurred during setup", e);
        } catch (LuaError e) {
            failWithException("LuaError occurred during setup", e);
        }
    }

    @Test
    public void testAlphabetizeMacroSets() {
        LuaTable macroSetsDB = globals.get("MacroSetsDB").checktable();

        LuaTable setA = LuaValue.tableOf();
        setA.set("macros", LuaValue.tableOf());
        LuaTable setB = LuaValue.tableOf();
        setB.set("macros", LuaValue.tableOf());

        macroSetsDB.set("Beta", setA);
        macroSetsDB.set("alpha", setB);
        macroSetsDB.set("invalid", LuaValue.valueOf("ignored"));

        LuaValue result = alphabetizeMacroSetsFunction.call();

        assertTrue(result.istable(), "Result should be a Lua table");

        LuaTable sortedSetNames = result.checktable();

        assertEquals(2, sortedSetNames.length(), "Expected two sorted names");
        assertEquals("alpha", sortedSetNames.get(1).tojstring());
        assertEquals("Beta", sortedSetNames.get(2).tojstring());
    }


    private void failWithException(String message, Exception e) {
        e.printStackTrace();
        fail(message + ": " + e.getMessage());
    }
}
