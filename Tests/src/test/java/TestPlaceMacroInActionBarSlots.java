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

public class TestPlaceMacroInActionBarSlots {
    private Globals globals;
    private LuaValue placeMacroInActionBarSlotsFunction;
    private LuaValue actionBarSlotLimit;

@BeforeEach
public void setup() {
    globals = JsePlatform.standardGlobals();
    globals.load("if SlashCmdList == nil then SlashCmdList = {} end").call();

    // Mock print function call
    globals.load("printCalled = false");
    globals.load("print = function() printCalled = true end").call();

    try {
        // Load Main.lua contents as a string
        Path luaPath = Paths.get("../Main.lua").toRealPath();
        String mainLuaContent = new String(Files.readAllBytes(luaPath), StandardCharsets.UTF_8);

        // Mock testing code to append
        String mockCode = "\n" +
            "TestExports = {\n" +
            "   PlaceMacroInActionBarSlots = PlaceMacroInActionBarSlots,\n" +
            "   actionBarSlotLimit = actionBarSlotLimit\n" +
            "}\n" +

            "getMacroInfoCalled = false\n" +
            "pickupMacroCalled = false\n" +
            "placeActionCalled = false\n" +
            "clearCursorCalled = false\n" +

            "function GetMacroInfo(macroIndex)\n" +
            "   getMacroInfoCalled = true\n" +
            "   return 'test', 134400, 'test'\n" +
            "end\n" +

            "function PickupMacro(macroIndex)\n" +
            "   pickupMacroCalled = true\n" +
            "end\n" +

            "function PlaceAction(slot)\n" +
            "   placeActionCalled = true\n" +
            "end\n" +

            "function ClearCursor()\n" +
            "   clearCursorCalled = true\n" + 
            "end\n";

        // Combine the original script with the testing code
        String modifiedScript = mainLuaContent + mockCode;

        // Load the modified script into Lua
        globals.load(modifiedScript).call();

        // Load test function
        LuaValue testExports = globals.get("TestExports");
        placeMacroInActionBarSlotsFunction = testExports.get("PlaceMacroInActionBarSlots");
        actionBarSlotLimit = testExports.get("actionBarSlotLimit");
        assertNotNull(placeMacroInActionBarSlotsFunction, "PlaceMacroInActionBarSlots function should not be null");
        assertNotNull(actionBarSlotLimit, "actionBarSlotLimit should not be null");

    } catch (IOException e) {
        failWithException("IOException occurred during setup", e);
    } catch (LuaError e) {
        failWithException("LuaError occurred during setup", e);
    }
}
    

    
    @Test
    public void testPlaceMacroInActionBarSlots_Success() {
        LuaTable table = new LuaTable();
        table.set(1, LuaValue.valueOf(1));
        placeMacroInActionBarSlotsFunction.invoke(LuaValue.varargsOf(new LuaValue[] {
            LuaValue.valueOf(1),
            table
        }));
        assertTrue(globals.get("getMacroInfoCalled").toboolean(), "Expected GetMacroInfo to be called");     
        assertTrue(globals.get("pickupMacroCalled").toboolean(), "Expected PickupMacro to be called");
        assertTrue(globals.get("placeActionCalled").toboolean(), "Expected PlaceAction to be called");
        assertTrue(globals.get("clearCursorCalled").toboolean(), "Expected ClearCursor to be called");
        assertFalse(globals.get("printCalled").toboolean(), "Expected print to not be called");
    }

    @Test
    public void testPlaceMacroInActionBarSlots_FailLowBound() {
        LuaTable table = new LuaTable();
        table.set(1, LuaValue.valueOf(0));
        placeMacroInActionBarSlotsFunction.invoke(LuaValue.varargsOf(new LuaValue[] {
            LuaValue.valueOf(1),
            table
        }));
        assertTrue(globals.get("getMacroInfoCalled").toboolean(), "Expected GetMacroInfo to be called");     
        assertFalse(globals.get("pickupMacroCalled").toboolean(), "Expected PickupMacro to not be called");
        assertFalse(globals.get("placeActionCalled").toboolean(), "Expected PlaceAction to not be called");
        assertFalse(globals.get("clearCursorCalled").toboolean(), "Expected ClearCursor to not be called");
        assertTrue(globals.get("printCalled").toboolean(), "Expected print to be called");
    }

    @Test
    public void testPlaceMacroInActionBarSlots_FailHighBound() {
        LuaTable table = new LuaTable();
        table.set(1, LuaValue.valueOf(actionBarSlotLimit.toint() + 1));
        placeMacroInActionBarSlotsFunction.invoke(LuaValue.varargsOf(new LuaValue[] {
            LuaValue.valueOf(1),
            table
        }));
        assertTrue(globals.get("getMacroInfoCalled").toboolean(), "Expected GetMacroInfo to be called");     
        assertFalse(globals.get("pickupMacroCalled").toboolean(), "Expected PickupMacro to not be called");
        assertFalse(globals.get("placeActionCalled").toboolean(), "Expected PlaceAction to not be called");
        assertFalse(globals.get("clearCursorCalled").toboolean(), "Expected ClearCursor to not be called");
        assertTrue(globals.get("printCalled").toboolean(), "Expected print to be called");
    }

    private void failWithException(String message, Exception e) {
        e.printStackTrace();
        fail(message + ": " + e.getMessage());
    }
}
