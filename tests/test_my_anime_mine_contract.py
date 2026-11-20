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
        self.assertIn("function controller:Stop()", SOURCE)
        self.assertIn('connect(close.Activated, function() controller:Stop() end)', SOURCE)
        self.assertIn("previous:Stop()", SOURCE)
        self.assertIn("local function diagnosticReport()", SOURCE)
        self.assertIn("local function findTakeAll()", SOURCE)

    def test_diagnostic_and_conservative_interactions(self):
        for token in ("SCAN GAME", "COPY LOG", "COPY TARGET DIAGNOSTICS", "ClickDetector", "ProximityPrompt",
                      "fireclickdetector", "fireproximityprompt", "firesignal", "setclipboard"):
            self.assertIn(token, SOURCE)
        self.assertNotIn(":FireServer(", SOURCE)
        self.assertNotIn(":InvokeServer(", SOURCE)
        self.assertNotIn("loadstring(", SOURCE)


if __name__ == "__main__":
    unittest.main()
