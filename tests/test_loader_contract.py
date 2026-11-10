"""Static contract checks for the multi-game loader. Run: python -m unittest discover -s tests -v"""
import pathlib
import re
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[1]
LOADER = (ROOT / "Loader.lua").read_text(encoding="utf-8")
REGISTRY = (ROOT / "GameRegistry.lua").read_text(encoding="utf-8")


class LoaderContractTests(unittest.TestCase):
    def test_loader_is_game_agnostic(self):
        self.assertNotIn("115068315659966", LOADER)
        self.assertIn("registry[game.PlaceId]", LOADER)
        self.assertIn('download("GameRegistry.lua")', LOADER)

    def test_registry_entries_point_to_existing_scripts(self):
        entries = re.findall(
            r"\[(\d+)\]\s*=\s*\{(.*?)\n\s*\},", REGISTRY, flags=re.S
        )
        self.assertTrue(entries, "No games registered")
        ids = set()
        for place_id, body in entries:
            self.assertNotIn(place_id, ids, "Duplicate PlaceId")
            ids.add(place_id)
            match = re.search(r'script\s*=\s*"([^"]+)"', body)
            self.assertIsNotNone(match, f"No script for {place_id}")
            path = match.group(1)
            self.assertRegex(path, r"^Games/[A-Za-z0-9_/-]+\.lua$")
            self.assertNotIn("..", path)
            self.assertTrue((ROOT / path).is_file(), f"Missing script: {path}")

    def test_roll_stickman_contract(self):
        self.assertRegex(REGISTRY, r"\[115068315659966\]")
        self.assertIn('uiName = "RollStickman_Combined_V1_2"', REGISTRY)
        script = (ROOT / "Games/RollStickman_Combined_V1_2.lua").read_text(encoding="utf-8")
        revision = re.search(r"Combined Auto V1\.2 R(\d+)", script)
        self.assertIsNotNone(revision)
        self.assertGreaterEqual(int(revision.group(1)), 10)

    def test_branch_override_and_error_handling(self):
        self.assertIn("MyRobloxHubRef", LOADER)
        self.assertIn("xpcall(function()", LOADER)
        self.assertIn("expected UI is missing", LOADER)
        self.assertIn("Unsupported game", LOADER)


if __name__ == "__main__":
    unittest.main()
