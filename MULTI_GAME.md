# Universal Loader (Multi-Game)

Run the same loader in any supported Roblox place:

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/Mxxchxi/My-Roblox-Hub/main/Loader.lua"))()
```

## Add a game

1. Add a new script file under `Games/`.
2. Add a numeric PlaceId entry to `GameRegistry.lua`:

```lua
[123456789] = {
    name = "Example Game",
    script = "Games/ExampleGame.lua",
},
```

3. If a game has multiple compatible places, register each PlaceId with the same script.
4. Merge the changes to `main`. The public loader URL does not change.

The loader downloads the registry and selected script from the same Git commit when GitHub's API is available. When the API is unavailable it falls back to uncached `main`. Unknown places show an unsupported-game notice and run nothing. Each script must handle its own UI initialization. Existing Roll A Stickman script is preserved.

Note: Executor HTTP/loadstring support is required. Test the loader in each game before release; Roll A Stickman V3 including UI verification passed a user-run Potassium smoke test at commit 5129cee. This does not validate every automation feature.

## Architecture rules

- `Loader.lua` must remain game-agnostic: do not add per-game branches or game UI logic.
- `GameRegistry.lua` is the only PlaceId routing table. Use numeric keys and repository-relative script paths under `Games/`.
- Put all game-specific automation, UI, and persistence in that game's own file(s).
- Do not register an unverified PlaceId. Do not load a different game's script as a fallback.
- Keep the existing public loader URL stable when adding games.
- Review and test changes on a feature branch before merging to `main`.

## Known limitations

- `loadstring` and HTTP retrieval depend on executor support.
- The GitHub API may fail or be rate-limited; fallback to `main` is not an atomic snapshot if files change between requests.
- A successful return from a game script does not guarantee that its UI initialized correctly. Verify in-game.
- Only Roll A Stickman is currently registered. More games require real scripts and confirmed PlaceIds.

## Potassium regression checklist (feature branch)

Run in Roll A Stickman (PlaceId `115068315659966`):

```lua
getgenv().MyRobloxHubRef = "feature/universal-multi-game-loader"
loadstring(game:HttpGet("https://raw.githubusercontent.com/Mxxchxi/My-Roblox-Hub/feature/universal-multi-game-loader/Loader.lua"))()
```

- [x] Loader reports Roll A Stickman and selected commit (reported smoke test)
- [x] UI `RollStickman_Combined_V1_2` is visible without a startup failure (reported smoke test)
- [ ] Existing settings and toggles restore as expected
- [ ] Raid, Arena, Dungeon and Expeditions work individually
- [ ] Unknown PlaceId shows unsupported and does not run a game script
- [ ] Re-running loader does not create duplicate windows

If the console reports `expected UI is missing`, capture the output and verify the current script's UI name. A successful dispatch is not proof that all automation features work.

## Static contract checks

Run from the repository root:

```bash
python -m unittest discover -s tests -v
```

These tests check registry paths, loader dispatch, revision metadata, and error-handling contracts without starting Roblox. They do not replace a Potassium runtime test. The user-reported smoke test passed at commit `5129cee`; automated test execution has not yet been verified.
