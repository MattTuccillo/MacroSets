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

public class TestDeepCopyTable {
    private Globals globals;
    private LuaValue deepCopyTableFunction;

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
                "TestExports = {DeepCopyTable = DeepCopyTable}\n";

            // Combine the original script with the testing code
            String modifiedScript = mainLuaContent + mockCode;

            // Load the modified script into Lua
            globals.load(modifiedScript).call();

            // Load test function
            LuaValue testExports = globals.get("TestExports");
            deepCopyTableFunction = testExports.get("DeepCopyTable");
            assertNotNull(deepCopyTableFunction, "DeepCopyTable function should not be null");

        } catch (IOException e) {
            failWithException("IOException occurred during setup", e);
        } catch (LuaError e) {
            failWithException("LuaError occurred during setup", e);
        }
    }

    @Test
    public void testDeepCopyTable_FlatTable() {
        LuaTable original = new LuaTable();
        original.set("a", LuaValue.valueOf(1));
        original.set("b", LuaValue.valueOf(2));

        LuaValue copy = deepCopyTableFunction.call(original);

        assertEquals(original.get("a"), copy.get("a"));
        assertEquals(original.get("b"), copy.get("b"));
        assertNotSame(original, copy, "copy expected to be a different table");
    }

    @Test
    public void testDeepCopyTable_NestedTable() {
        LuaTable nested = new LuaTable();
        nested.set("x", LuaValue.valueOf(10));

        LuaTable original = new LuaTable();
        original.set("nested", nested);

        LuaValue copy = deepCopyTableFunction.call(original);
        LuaValue copiedNested = copy.get("nested");

        assertTrue(copiedNested.istable());
        assertEquals(LuaValue.valueOf(10), copiedNested.get("x"));
        assertNotSame(nested, copiedNested, "copy expected to be a different nested table");
    }

    @Test
    public void testDeepCopyTable_MetaTable() {
        LuaTable meta = new LuaTable();
        meta.set("__index", LuaValue.valueOf("meta_value"));

        LuaTable original = new LuaTable();
        original.setmetatable(meta);

        LuaValue copy = deepCopyTableFunction.call(original);
        LuaValue copiedMeta = copy.getmetatable();

        assertNotNull(copiedMeta, "copiedMeta table expected to retain metatable");
        assertNotSame(meta, copiedMeta, "copiedMeta expected to be a deep copy");
        assertEquals("meta_value", copiedMeta.get("__index").tojstring());
    }

    @Test
    public void testDeepCopyTable_NotTable() {
        LuaValue number = LuaValue.valueOf(42);
        LuaValue copy = deepCopyTableFunction.call(number);

        assertEquals(number, copy, "copy expected to be primitive value equal to the original input");
    }

    @Test
    public void testDeepCopyTable_EmptyTable() {
        LuaTable original = new LuaTable();
        LuaValue copy = deepCopyTableFunction.call(original);

        assertTrue(copy.istable(), "copy expected to be an empty table");
        assertNotSame(original, copy);
    }

    private void failWithException(String message, Exception e) {
        e.printStackTrace();
        fail(message + ": " + e.getMessage());
    }
}
