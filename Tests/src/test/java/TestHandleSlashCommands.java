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

public class TestHandleSlashCommands {
    private Globals globals;
    private LuaValue handleSlashCommandsFunction;

    @BeforeEach
    public void setup() {
        globals = JsePlatform.standardGlobals();
        globals.load("if SlashCmdList == nil then SlashCmdList = {} end").call();
        globals.load("print = function() end").call();
        globals.load(
            """
            function strsplit(delim, str)
                if not str or str == '' then return '' end
                local result = {}
                for match in (str .. delim):gmatch('(.-)' .. delim) do
                    table.insert(result, match)
                end
                return table.unpack(result)
            end
            """
        ).call();

        try {
            // Load Main.lua contents as a string
            Path luaPath = Paths.get("../Main.lua").toRealPath();
            String mainLuaContent = new String(Files.readAllBytes(luaPath), StandardCharsets.UTF_8);

            // Mock testing code to append
            String mockCode = """

            TestExports = {HandleSlashCommands = HandleSlashCommands}
            saveMacroSetCalled = false
            loadMacroSetCalled = false
            deleteMacroSetCalled = false
            deleteAllMacroSetsCalled = false
            undoLastOperationCalled = false
            alphabetizeMacroSetsCalled = false
            listMacroSetsCalled = false
            displayHelpCalled = false
            optionsScreenToggleCalled = false
            SaveMacroSet = function(arg1, arg2) saveMacroSetCalled = true end
            LoadMacroSet = function(arg1) loadMacroSetCalled = true end
            DeleteMacroSet = function(arg1) deleteMacroSetCalled = true end
            DeleteAllMacroSets = function() deleteAllMacroSetsCalled = true end
            UndoLastOperation = function() undoLastOperationCalled = true end
            AlphabetizeMacroSets = function() alphabetizeMacroSetsCalled = true end
            ListMacroSets = function() listMacroSetsCalled = true end
            DisplayHelp = function(arg1) displayHelpCalled = true end
            OptionsScreenToggle = function() optionsScreenToggleCalled = true end
            """;

            // Combine the original script with the testing code
            String modifiedScript = mainLuaContent + mockCode;

            // Load the modified script into Lua
            globals.load(modifiedScript).call();

            // Load test function
            LuaValue testExports = globals.get("TestExports");
            handleSlashCommandsFunction = testExports.get("HandleSlashCommands");
            assertNotNull(handleSlashCommandsFunction, "HandleSlashCommands function should not be null");

        } catch (IOException e) {
            failWithException("IOException occurred during setup", e);
        } catch (LuaError e) {
            failWithException("LuaError occurred during setup", e);
        }
    }
    
    @Test
    public void testHandleSlashCommands_Save() {
        handleSlashCommandsFunction.invoke(LuaValue.varargsOf(new LuaValue[] {
            LuaValue.valueOf("save"),
            LuaValue.valueOf("test")
        }));        
        assertTrue(globals.get("saveMacroSetCalled").toboolean(), "Expected SaveMacroSet to be called");
        assertFalse(globals.get("loadMacroSetCalled").toboolean(), "Expected LoadMacroSet to not be called");
        assertFalse(globals.get("deleteMacroSetCalled").toboolean(), "Expected DeleteMacroSet to not be called");
        assertFalse(globals.get("deleteAllMacroSetsCalled").toboolean(), "Expected DeleteAllMacroSets to not be called");
        assertFalse(globals.get("undoLastOperationCalled").toboolean(), "Expected UndoLastOperation to not be called");
        assertFalse(globals.get("alphabetizeMacroSetsCalled").toboolean(), "Expected AlphabetizeMacroSets to not be called");
        assertFalse(globals.get("listMacroSetsCalled").toboolean(), "Expected ListMacroSets to not be called");
        assertFalse(globals.get("displayHelpCalled").toboolean(), "Expected DisplayHelp to not be called");
        assertFalse(globals.get("optionsScreenToggleCalled").toboolean(), "Expected OptionsScreenToggle to not be called");
    }

    @Test
    public void testHandleSlashCommands_Load() {
        handleSlashCommandsFunction.invoke(LuaValue.varargsOf(new LuaValue[] {
            LuaValue.valueOf("load"),
            LuaValue.valueOf("test")
        }));        
        assertFalse(globals.get("saveMacroSetCalled").toboolean(), "Expected SaveMacroSet to not be called");
        assertTrue(globals.get("loadMacroSetCalled").toboolean(), "Expected LoadMacroSet to be called");
        assertFalse(globals.get("deleteMacroSetCalled").toboolean(), "Expected DeleteMacroSet to not be called");
        assertFalse(globals.get("deleteAllMacroSetsCalled").toboolean(), "Expected DeleteAllMacroSets to not be called");
        assertFalse(globals.get("undoLastOperationCalled").toboolean(), "Expected UndoLastOperation to not be called");
        assertFalse(globals.get("alphabetizeMacroSetsCalled").toboolean(), "Expected AlphabetizeMacroSets to not be called");
        assertFalse(globals.get("listMacroSetsCalled").toboolean(), "Expected ListMacroSets to not be called");
        assertFalse(globals.get("displayHelpCalled").toboolean(), "Expected DisplayHelp to not be called");
        assertFalse(globals.get("optionsScreenToggleCalled").toboolean(), "Expected OptionsScreenToggle to not be called");
    }

    @Test
    public void testHandleSlashCommands_Delete() {
        handleSlashCommandsFunction.invoke(LuaValue.varargsOf(new LuaValue[] {
            LuaValue.valueOf("delete"),
            LuaValue.valueOf("test")
        }));        
        assertFalse(globals.get("saveMacroSetCalled").toboolean(), "Expected SaveMacroSet to not be called");
        assertFalse(globals.get("loadMacroSetCalled").toboolean(), "Expected LoadMacroSet to not be called");
        assertTrue(globals.get("deleteMacroSetCalled").toboolean(), "Expected DeleteMacroSet to be called");
        assertFalse(globals.get("deleteAllMacroSetsCalled").toboolean(), "Expected DeleteAllMacroSets to not be called");
        assertFalse(globals.get("undoLastOperationCalled").toboolean(), "Expected UndoLastOperation to not be called");
        assertFalse(globals.get("alphabetizeMacroSetsCalled").toboolean(), "Expected AlphabetizeMacroSets to not be called");
        assertFalse(globals.get("listMacroSetsCalled").toboolean(), "Expected ListMacroSets to not be called");
        assertFalse(globals.get("displayHelpCalled").toboolean(), "Expected DisplayHelp to not be called");
        assertFalse(globals.get("optionsScreenToggleCalled").toboolean(), "Expected OptionsScreenToggle to not be called");
    }

    @Test
    public void testHandleSlashCommands_DeleteAll() {
        handleSlashCommandsFunction.invoke(LuaValue.varargsOf(new LuaValue[] {
            LuaValue.valueOf("deleteall")
        }));        
        assertFalse(globals.get("saveMacroSetCalled").toboolean(), "Expected SaveMacroSet to not be called");
        assertFalse(globals.get("loadMacroSetCalled").toboolean(), "Expected LoadMacroSet to not be called");
        assertFalse(globals.get("deleteMacroSetCalled").toboolean(), "Expected DeleteMacroSet to not be called");
        assertTrue(globals.get("deleteAllMacroSetsCalled").toboolean(), "Expected DeleteAllMacroSets to be called");
        assertFalse(globals.get("undoLastOperationCalled").toboolean(), "Expected UndoLastOperation to not be called");
        assertFalse(globals.get("alphabetizeMacroSetsCalled").toboolean(), "Expected AlphabetizeMacroSets to not be called");
        assertFalse(globals.get("listMacroSetsCalled").toboolean(), "Expected ListMacroSets to not be called");
        assertFalse(globals.get("displayHelpCalled").toboolean(), "Expected DisplayHelp to not be called");
        assertFalse(globals.get("optionsScreenToggleCalled").toboolean(), "Expected OptionsScreenToggle to not be called");
    }

    @Test
    public void testHandleSlashCommands_Undo() {
        handleSlashCommandsFunction.invoke(LuaValue.varargsOf(new LuaValue[] {
            LuaValue.valueOf("undo")
        }));        
        assertFalse(globals.get("saveMacroSetCalled").toboolean(), "Expected SaveMacroSet to not be called");
        assertFalse(globals.get("loadMacroSetCalled").toboolean(), "Expected LoadMacroSet to not be called");
        assertFalse(globals.get("deleteMacroSetCalled").toboolean(), "Expected DeleteMacroSet to not be called");
        assertFalse(globals.get("deleteAllMacroSetsCalled").toboolean(), "Expected DeleteAllMacroSets to not be called");
        assertTrue(globals.get("undoLastOperationCalled").toboolean(), "Expected UndoLastOperation to be called");
        assertFalse(globals.get("alphabetizeMacroSetsCalled").toboolean(), "Expected AlphabetizeMacroSets to not be called");
        assertFalse(globals.get("listMacroSetsCalled").toboolean(), "Expected ListMacroSets to not be called");
        assertFalse(globals.get("displayHelpCalled").toboolean(), "Expected DisplayHelp to not be called");
        assertFalse(globals.get("optionsScreenToggleCalled").toboolean(), "Expected OptionsScreenToggle to not be called");
    }

    @Test
    public void testHandleSlashCommands_List() {
        handleSlashCommandsFunction.invoke(LuaValue.varargsOf(new LuaValue[] {
            LuaValue.valueOf("list")
        }));        
        assertFalse(globals.get("saveMacroSetCalled").toboolean(), "Expected SaveMacroSet to not be called");
        assertFalse(globals.get("loadMacroSetCalled").toboolean(), "Expected LoadMacroSet to not be called");
        assertFalse(globals.get("deleteMacroSetCalled").toboolean(), "Expected DeleteMacroSet to not be called");
        assertFalse(globals.get("deleteAllMacroSetsCalled").toboolean(), "Expected DeleteAllMacroSets to not be called");
        assertFalse(globals.get("undoLastOperationCalled").toboolean(), "Expected UndoLastOperation to not be called");
        assertTrue(globals.get("alphabetizeMacroSetsCalled").toboolean(), "Expected AlphabetizeMacroSets to be called");
        assertTrue(globals.get("listMacroSetsCalled").toboolean(), "Expected ListMacroSets to be called");
        assertFalse(globals.get("displayHelpCalled").toboolean(), "Expected DisplayHelp to not be called");
        assertFalse(globals.get("optionsScreenToggleCalled").toboolean(), "Expected OptionsScreenToggle to not be called");
    }

    @Test
    public void testHandleSlashCommands_Help() {
        handleSlashCommandsFunction.invoke(LuaValue.varargsOf(new LuaValue[] {
            LuaValue.valueOf("help"),
            LuaValue.valueOf("save")
        }));            
        assertFalse(globals.get("saveMacroSetCalled").toboolean(), "Expected SaveMacroSet to not be called");
        assertFalse(globals.get("loadMacroSetCalled").toboolean(), "Expected LoadMacroSet to not be called");
        assertFalse(globals.get("deleteMacroSetCalled").toboolean(), "Expected DeleteMacroSet to not be called");
        assertFalse(globals.get("deleteAllMacroSetsCalled").toboolean(), "Expected DeleteAllMacroSets to not be called");
        assertFalse(globals.get("undoLastOperationCalled").toboolean(), "Expected UndoLastOperation to not be called");
        assertFalse(globals.get("alphabetizeMacroSetsCalled").toboolean(), "Expected AlphabetizeMacroSets to not be called");
        assertFalse(globals.get("listMacroSetsCalled").toboolean(), "Expected ListMacroSets to not be called");
        assertTrue(globals.get("displayHelpCalled").toboolean(), "Expected DisplayHelp to be called");
        assertFalse(globals.get("optionsScreenToggleCalled").toboolean(), "Expected OptionsScreenToggle to not be called");
    }

    @Test
    public void testHandleSlashCommands_Options() {
        handleSlashCommandsFunction.invoke(LuaValue.varargsOf(new LuaValue[] {
            LuaValue.valueOf("options")
        }));        
        assertFalse(globals.get("saveMacroSetCalled").toboolean(), "Expected SaveMacroSet to not be called");
        assertFalse(globals.get("loadMacroSetCalled").toboolean(), "Expected LoadMacroSet to not be called");
        assertFalse(globals.get("deleteMacroSetCalled").toboolean(), "Expected DeleteMacroSet to not be called");
        assertFalse(globals.get("deleteAllMacroSetsCalled").toboolean(), "Expected DeleteAllMacroSets to not be called");
        assertFalse(globals.get("undoLastOperationCalled").toboolean(), "Expected UndoLastOperation to not be called");
        assertFalse(globals.get("alphabetizeMacroSetsCalled").toboolean(), "Expected AlphabetizeMacroSets to not be called");
        assertFalse(globals.get("listMacroSetsCalled").toboolean(), "Expected ListMacroSets to not be called");
        assertFalse(globals.get("displayHelpCalled").toboolean(), "Expected DisplayHelp to not be called");
        assertTrue(globals.get("optionsScreenToggleCalled").toboolean(), "Expected OptionsScreenToggle to be called");
    }

    @Test
    public void testHandleSlashCommands_Invalid() {
        handleSlashCommandsFunction.invoke(LuaValue.varargsOf(new LuaValue[] {
            LuaValue.valueOf("invalid")
        }));        
        assertFalse(globals.get("saveMacroSetCalled").toboolean(), "Expected SaveMacroSet to not be called");
        assertFalse(globals.get("loadMacroSetCalled").toboolean(), "Expected LoadMacroSet to not be called");
        assertFalse(globals.get("deleteMacroSetCalled").toboolean(), "Expected DeleteMacroSet to not be called");
        assertFalse(globals.get("deleteAllMacroSetsCalled").toboolean(), "Expected DeleteAllMacroSets to not be called");
        assertFalse(globals.get("undoLastOperationCalled").toboolean(), "Expected UndoLastOperation to not be called");
        assertFalse(globals.get("alphabetizeMacroSetsCalled").toboolean(), "Expected AlphabetizeMacroSets to not be called");
        assertFalse(globals.get("listMacroSetsCalled").toboolean(), "Expected ListMacroSets to not be called");
        assertFalse(globals.get("displayHelpCalled").toboolean(), "Expected DisplayHelp to not be called");
        assertFalse(globals.get("optionsScreenToggleCalled").toboolean(), "Expected OptionsScreenToggle to not be called");
    }

    private void failWithException(String message, Exception e) {
        fail(message, e);
    }
}
