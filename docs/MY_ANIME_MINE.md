# My Anime Mine (v0.5)

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
- Auto Collect targets the **explicitly selected plot only**. From near your own plot upgrade marker, click **SET MY PLOT**, and confirm the suggested `MinePlotN`. Enable **AUTO COLLECT**. At close range it attempts the selected plot ChestPrompt and a visible **Take All** button via executor interaction APIs. For a distant chest, separately turn **WALK TO CHEST: ON** to allow bounded natural `Humanoid:MoveTo` (no teleport, limited to 145 studs with blocked detection).
- Includes SCAN GAME, COPY LOG and **COPY TARGET DIAGNOSTICS** with target/range details, Take All signal connection counts (`Activated` and `MouseButton1Click`), a read-only Chest UI text snapshot, event method, and post-dispatch feedback. When `getconnections` is unavailable, the script alternates these two button signal types after inconclusive attempts.
- Automation toggles and walking start **OFF**. The plot selection must be made each session. Close with X to stop workers and movement; rerun replaces the previous UI.
- Press **LeftAlt** to minimize or restore the main window. When minimized, click the small **MY ANIME MINE [+]** restore control near the upper-left corner to reopen. Hiding the window leaves active automation toggles untouched. RightAlt does nothing.
- Does **not** invoke undocumented remotes, buy items, sell ores/characters, auto-summon, assign crew, auto-upgrade research, or teleport.
- Plot selection is based on proximity to an `UpgradeClick` detector, **not verified ownership**. Stand near your own plot and verify the plot number before turning on automation. If the Chest is unreachable, movement times out and turns WALK TO CHEST OFF rather than teleporting.
- A Take All signal call is evaluated after 2.5 seconds. The UI item count is parsed from labels such as `15/183.9K Items` and classified as **decreased**, **increased**, **unchanged** or **unavailable**. Chest item-count decreases may suggest collection but **do not prove inventory credit**, while increases may simply reflect ongoing mining. Auto Collect pauses after 3 consecutive checks without a measured decrease or after 6 Take All dispatches in the enable cycle. Re-enable Auto Collect to reset the cycle. Count 0 suppresses needless Take All clicks.
- Interactions are experimental: the live game might mine through proprietary server remotes/UI rather than exposed detectors/prompts. A detected interaction **is not proof** of an ore/reward gain. The function is a starting point for in-game diagnostics, not a verified auto-farm.
- Auto Mine requires `fireclickdetector`; Auto Collect requires `fireproximityprompt` or `firesignal` executor support. Successful function calls are **not** proof of an ore reward.
- The game normally mines rocks through **placed anime characters**. Rock ClickDetectors may be unrelated selection controls, so Auto Mine (CLICK) is experimental and not guaranteed to mine.
- Test automation in the live game before claiming gameplay success.

## Runtime test

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/Mxxchxi/My-Roblox-Hub/main/Loader.lua"))()
```

For reporting a failure: enter the actual game, select SCAN GAME, select COPY LOG, and paste the log. Confirm that the GUI `MyAnimeMineHub` appeared and the console reported `Started My Anime Mine`.

## Regression checklist

- [ ] UI loads when entering My Anime Mine.
- [ ] All automatic toggles begin OFF.
- [ ] The UI can be closed and the loader can be rerun without duplicate windows.
- [ ] LeftAlt hides and restores the window; restore chip works, and active toggles are retained.
- [ ] SCAN GAME produces useful diagnostics, including prompt hierarchy and Take All detection.
- [ ] COPY TARGET DIAGNOSTICS includes selected plot, Chest range, action signal connections, current Chest item count, before/after/delta, last event and pending feedback.
- [ ] After Take All, verify actual ore balance manually; successful signal calls and visual UI changes alone are not proof.
- [ ] Repeated unchanged GUI dispatches pause Auto Collect instead of endlessly firing signals.
- [ ] SET MY PLOT only selects a nearby upgrade marker; confirm own plot.
- [ ] Auto Collect does not target chests in unselected plots.
- [ ] WALK TO CHEST approaches the selected chest with natural movement or reports a block; OFF stops movement.
- [ ] Executor exposes interaction functions and the selected rock/chest actually changes in-game.
- [ ] Existing Roll A Stickman and Steal An Egg UIs still open from the same loader.
