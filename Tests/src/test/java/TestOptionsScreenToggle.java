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

public class TestOptionsScreenToggle {
    private Globals globals;
    private LuaValue optionsScreenToggleFunction;

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

            TestExports = {OptionsScreenToggle = OptionsScreenToggle}
            settingsPanelShown = false
            currentCategoryMatches = false
            hideCounter = 0
            showCounter = 0
            openToCategoryCounter = 0
            lastOpenedCategoryId = nil
            macroSetsCategory = { GetID = function(self) return 42 end }
            otherCategory = { GetID = function(self) return 99 end }
            SettingsPanel = {
               GetCurrentCategory = function(self)
                   if currentCategoryMatches then return macroSetsCategory end
                   return otherCategory
               end,
               IsShown = function(self)
                   return settingsPanelShown
               end,
               Hide = function(self)
                   hideCounter = hideCounter + 1
                   settingsPanelShown = false
               end,
               Show = function(self)
                   showCounter = showCounter + 1
                   settingsPanelShown = true
               end
            }
            Settings = {
               OpenToCategory = function(categoryId)
                   openToCategoryCounter = openToCategoryCounter + 1
                   lastOpenedCategoryId = categoryId
               end
            }
            """;

            // Combine the original script with the testing code
            String modifiedScript = mainLuaContent + mockCode;

            // Load the modified script into Lua
            globals.load(modifiedScript).call();

            // Load test function
            LuaValue testExports = globals.get("TestExports");
            optionsScreenToggleFunction = testExports.get("OptionsScreenToggle");
            assertNotNull(optionsScreenToggleFunction, "OptionsScreenToggle function should not be null");

        } catch (IOException e) {
            failWithException("IOException occurred during setup", e);
        } catch (LuaError e) {
            failWithException("LuaError occurred during setup", e);
        }
    }

    @Test
    public void testOptionsScreenToggle_HideCurrentCategory() {
        globals.load(
            """
            settingsPanelShown = true
            currentCategoryMatches = true
            """
        ).call();

        optionsScreenToggleFunction.call();

        assertEquals(1, globals.get("hideCounter").toint(), "Expected SettingsPanel:Hide to be called 1 time");
        assertEquals(0, globals.get("showCounter").toint(), "Expected SettingsPanel:Show to be called 0 times");
        assertEquals(0, globals.get("openToCategoryCounter").toint(), "Expected Settings.OpenToCategory to be called 0 times");
        assertFalse(globals.get("settingsPanelShown").toboolean(), "Expected settingsPanelShown to be false");
    }

    @Test
    public void testOptionsScreenToggle_ShowCategory() {
        globals.load(
            """
            settingsPanelShown = false
            currentCategoryMatches = false
            """
        ).call();

        optionsScreenToggleFunction.call();

        assertEquals(1, globals.get("hideCounter").toint(), "Expected SettingsPanel:Hide to be called 1 time");
        assertEquals(1, globals.get("showCounter").toint(), "Expected SettingsPanel:Show to be called 1 time");
        assertEquals(1, globals.get("openToCategoryCounter").toint(), "Expected Settings.OpenToCategory to be called 1 time");
        assertEquals(42, globals.get("lastOpenedCategoryId").toint(), "Expected opened category ID to be 42");
        assertTrue(globals.get("settingsPanelShown").toboolean(), "Expected settingsPanelShown to be true");
    }

    private void failWithException(String message, Exception e) {
        fail(message, e);
    }
}
