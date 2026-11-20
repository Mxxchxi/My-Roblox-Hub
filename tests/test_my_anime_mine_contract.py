"""Static contracts for the new My Anime Mine module."""
import pathlib
import re
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[1]
REGISTRY = (ROOT / "GameRegistry.lua").read_text(encoding="utf-8")
SOURCE = (ROOT / "Games/MyAnimeMine.lua").read_text(encoding="utf-8")
LOADER = (ROOT / "Loader.lua").read_text(encoding="utf-8")


class MyAnimeMineContracts(unittest.TestCase):
    def test_place_registered_and_loader_unchanged_in_principle(self):
        match = re.search(r"\[79389059854988\]\s*=\s*\{(.*?)\n\s*\},", REGISTRY, re.S)
        self.assertIsNotNone(match)
        self.assertIn('script = "Games/MyAnimeMine.lua"', match.group(1))
        self.assertIn('uiName = "MyAnimeMineHub"', match.group(1))
        self.assertIn("registry[game.PlaceId]", LOADER)
        self.assertNotIn("79389059854988", LOADER)

    def test_safe_startup_and_lifecycle(self):
        self.assertIn("if game.PlaceId ~= 79389059854988 then", SOURCE)
        self.assertIn('Name = "MyAnimeMineHub"', SOURCE)
        self.assertIn("mine = false", SOURCE)
        self.assertIn("collect = false", SOURCE)
        self.assertIn("equip = false", SOURCE)
        self.assertIn("upgrade = false", SOURCE)
        self.assertIn("local function scanActionButtons()", SOURCE)
        self.assertIn("local function isKnownInventoryLauncher(item)", SOURCE)
        self.assertIn('cursor.Name == "HotbarFrame"', SOURCE)
        self.assertIn('cursor.Name == "MineGui"', SOURCE)
        self.assertIn('local looksInventory = isKnownInventoryLauncher(item)', SOURCE)
        self.assertIn("GameUpgradesMenu (read-only, not auto-purchased)", SOURCE)
        self.assertIn('if not controller.selectedPlot then autoSelectPlot() end', SOURCE)
        self.assertIn("controller.upgradeLastTick = now", SOURCE)
        self.assertIn("local function isUpgradeAction(button)", SOURCE)
        self.assertIn("local function nextHolderDetector(peek)", SOURCE)
        self.assertIn("local function holderTargets()", SOURCE)
        self.assertIn("local function approachUpgradeHolder(target, now)", SOURCE)
        self.assertIn("local function nearbyButtonContext(item)", SOURCE)
        self.assertIn("ALL VISIBLE GAME GUI BUTTONS", SOURCE)
        self.assertIn("repeated Cards omitted", SOURCE)
        self.assertIn("HIDDEN GAME GUI CANDIDATES", SOURCE)
        self.assertIn("controller.upgradeWalkTarget", SOURCE)
        self.assertIn("and not controller.upgradeWalkTarget", SOURCE)
        self.assertIn("local function actionDiagnosticReport()", SOURCE)
        self.assertIn("local function resolveUpgradeFeedback(now)", SOURCE)
        self.assertIn("controller.upgradeNoChange >= 3", SOURCE)
        self.assertIn("controller.upgradeAttempts >= 80", SOURCE)
        self.assertIn("function controller:Stop()", SOURCE)
        self.assertIn('connect(close.Activated, function() controller:Stop() end)', SOURCE)
        self.assertIn("previous:Stop()", SOURCE)
        self.assertIn("local function diagnosticReport()", SOURCE)
        self.assertIn("local function findTakeAll()", SOURCE)
        self.assertIn("local function choosePlotNearPlayer()", SOURCE)
        self.assertIn("local function selectedChest()", SOURCE)
        self.assertIn("local function approachChest(", SOURCE)
        self.assertIn("walkToChest = false", SOURCE)
        self.assertIn("selectedPlot = nil", SOURCE)
        self.assertIn("local function autoSelectPlot()", SOURCE)
        self.assertIn("local function choosePlotNearPlayer()", SOURCE)
        self.assertIn("controller.walkToChest = controller.collect", SOURCE)
        self.assertNotIn('button("SetPlot"', SOURCE)
        self.assertNotIn('button("WalkToChest"', SOURCE)
        self.assertIn("local function chestSnapshot(button)", SOURCE)
        self.assertIn("local function takeAllConnections(button)", SOURCE)
        self.assertIn("local function settleTakeAll(now)", SOURCE)
        self.assertIn("local function chestItemCount(button)", SOURCE)
        self.assertIn("local function monitorManualButton()", SOURCE)
        self.assertIn("local function settleManualTakeAll(now)", SOURCE)
        self.assertIn("CHEST_CLOSED_AFTER_TAKE_ALL (matches manual UI", SOURCE)
        self.assertIn("local function observeReopenedChest(button)", SOURCE)
        self.assertIn("takeAllCooldownSeconds = 12", SOURCE)
        self.assertIn("takeAllUnverifiedReopens >= 2", SOURCE)
        self.assertIn("MANUAL_CHEST_CLOSED (stale count ignored)", SOURCE)
        self.assertIn("takeAllNotDecreased >= 3", SOURCE)
        self.assertIn("takeAllAttempts >= 6", SOURCE)

    def test_diagnostic_and_conservative_interactions(self):
        for token in ("SCAN GAME", "COPY LOG", "COPY TARGET DIAGNOSTICS", "PLOT AUTO:", "WALK AUTO:", "WATCH MANUAL TAKE ALL", "AUTO EQUIP BEST", "AUTO UPGRADE STATS", "COPY EQUIP / UPGRADE TARGETS", "MouseButton1Click", "getconnections", "ClickDetector", "ProximityPrompt",
                      "fireclickdetector", "fireproximityprompt", "firesignal", "setclipboard"):
            self.assertIn(token, SOURCE)
        self.assertIn("minePlotName(prompt) == controller.selectedPlot", SOURCE)
        self.assertNotIn(":FireServer(", SOURCE)
        self.assertNotIn(":InvokeServer(", SOURCE)
        self.assertNotIn("loadstring(", SOURCE)


if __name__ == "__main__":
    unittest.main()
