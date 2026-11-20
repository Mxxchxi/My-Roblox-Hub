# My Anime Mine (v0.2)

- Roblox game: https://www.roblox.com/games/79389059854988/My-Anime-Mine
- PlaceId: `79389059854988`
- Game module: `Games/MyAnimeMine.lua`
- Registry: `GameRegistry.lua`
- Expected PlayerGui: `MyAnimeMineHub`

Use the **same** loader as the other games:

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/Mxxchxi/My-Roblox-Hub/main/Loader.lua"))()
```

## Features and limitations

- Scans nearby `ClickDetector` instances associated with rock/ore names.
- Scans nearby `ProximityPrompt` instances associated with collecting/chests.
- Auto Mine attempts nearby `fireclickdetector` interactions on a timer **only when manually enabled**.
- Auto Collect attempts nearby `fireproximityprompt` interactions, then tries a visible Chest **Take All** / Claim All / Collect All button through `firesignal` (where supported). Both methods require live verification.
- Includes SCAN GAME (lists prompt paths and named UI buttons), COPY LOG, and **COPY TARGET DIAGNOSTICS** with range/target/reason information. Repeated unchanged scan logs are suppressed.
- Both toggles start **OFF**. The UI and loading should work regardless of these optional executor APIs. Close with X to stop workers; rerun replaces the previous UI.
- Does **not** invoke undocumented remotes, buy items, sell ores/characters, auto-summon, assign crew, auto-upgrade research, or teleport.
- Interactions are experimental: the live game might mine through proprietary server remotes/UI rather than exposed detectors/prompts. A detected interaction **is not proof** of an ore/reward gain. The function is a starting point for in-game diagnostics, not a verified auto-farm.
- Auto Mine requires `fireclickdetector`; Auto Collect requires `fireproximityprompt` or `firesignal` executor support. Successful function calls are **not** proof of an ore reward.
- The game normally mines rocks through **placed anime characters**. Rock ClickDetectors may be unrelated selection controls, so Auto Mine (CLICK) is experimental and not guaranteed to mine.
- Test automation in the live game before claiming gameplay success.

## Feature branch test (before merge)

```lua
getgenv().MyRobloxHubRef = "feature/my-anime-mine"
loadstring(game:HttpGet("https://raw.githubusercontent.com/Mxxchxi/My-Roblox-Hub/feature/my-anime-mine/Loader.lua"))()
```

For reporting a failure: enter the actual game, select SCAN GAME, select COPY LOG, and paste the log. Confirm that the GUI `MyAnimeMineHub` appeared and the console reported `Started My Anime Mine`.

## Regression checklist

- [ ] UI loads when entering My Anime Mine.
- [ ] All automatic toggles begin OFF.
- [ ] The UI can be closed and the loader can be rerun without duplicate windows.
- [ ] SCAN GAME produces useful diagnostics, including prompt hierarchy and Take All detection.
- [ ] COPY TARGET DIAGNOSTICS includes a candidate target/distance or missing-target reason.
- [ ] Executor exposes interaction functions and the selected rock/chest actually changes in-game.
- [ ] Existing Roll A Stickman and Steal An Egg UIs still open from the same loader.
