import static org.junit.jupiter.api.Assertions.*;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.luaj.vm2.*;
import org.luaj.vm2.lib.jse.JsePlatform;

public class LuaTests {
    private Globals globals;

    @BeforeEach
    public void setup() {
        // Initialize Lua environment before each test
        globals = JsePlatform.standardGlobals();
    }

    @Test
    public void testBasicLuaExecution() {
        LuaValue chunk = globals.load("return 2 + 3");
        LuaValue result = chunk.call();
        assertEquals(5, result.toint(), "2 + 3 should be 5");
    }
}
