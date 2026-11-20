# My Anime Mine (v0.10)

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

- **V0.10 troubleshooting:** **COPY EQUIP / UPGRADE TARGETS** now includes all visible game TextButtons and ImageButtons (up to 70), hidden UI candidates (up to 70), button paths/context, and every detected Holder's real distance and MaxActivationDistance. If Equip Best is still not found, open the game's Inventory manually and recopy diagnostics to identify its real button hierarchy; do not guess server remote calls.
- **Auto Upgrade movement:** the script scans all selected-plot `Holders/*/UpgradeClick` detectors directly even when outside activation range and approaches a nearby Holder with bounded natural `Humanoid:MoveTo` (up to 120 studs, 11s no-progress cutoff). Auto Collect is briefly suspended *only during the approach* to avoid conflicting movement commands and resumes afterward. Holder ownership remains based on the auto-selected plot and is not independently verified.
- **AUTO EQUIP BEST** (OFF by default): searches for the game's Equip Best GUI control and triggers its existing click listener periodically. When not visible, tries opening the game's Inventory menu once per enable cycle. No undocumented remote signatures are used. The click and equipment changes require live verification.
- **AUTO UPGRADE STATS** (OFF by default): tries UpgradeClick detectors on miners (Holders) in the selected plot, opens the miner's Stats tab when detected, and selects only character Damage, Speed, and Mining Speed upgrade GUI controls. Excludes candidates with Robux, gamepass, premium, purchase, shop, or research hints, and does not automate Research Tree purchases. Clicking a game UI upgrade can spend in-game currency; no Robux actions are intentionally targeted. The script pauses after three unchanged UI attempts or 80 attempts per cycle. The live GUI hierarchy is not yet confirmed and may require adapting from an in-game diagnostic.
- Two independent toggles leave the previously working Auto Collect behavior unchanged. When a Chest is open these new workflows defer UI actions.
- **COPY EQUIP / UPGRADE TARGETS** reports candidate game GUI paths, readable labels, click listener counts, selected holder, action stages, and dispatch statistics. If a target is missing or an upgrade does not take effect, paste this copied report.


- Scans nearby `ClickDetector` instances associated with rock/ore names.
- Scans nearby `ProximityPrompt` instances associated with collecting/chests.
- Auto Mine attempts nearby `fireclickdetector` interactions on a timer **only when manually enabled**.
- **AUTO PLOT + AUTO WALK:** the script automatically chooses a nearby `MinePlotN` using the closest matching Chest and UpgradeClick marker, provided there is no ambiguous second candidate. It locks the selection for the session; it does **not** prove ownership. On **AUTO COLLECT: ON**, walking to that selected plot Chest is automatically enabled. It uses natural `Humanoid:MoveTo` (no teleport, bounded 145 studs, stops Collect after 11 seconds without movement progress). The manual `SET MY PLOT` and `WALK TO CHEST` controls have been removed.
- Includes SCAN GAME, COPY LOG and **COPY TARGET DIAGNOSTICS** with target/range details, Take All signal connection counts (`Activated` and `MouseButton1Click`), a read-only Chest UI text snapshot, event method, and post-dispatch feedback. When `getconnections` is unavailable, the script alternates these two button signal types after inconclusive attempts.
- Automation toggles and walking start **OFF**. A plot is auto-discovered on startup, retrying when world objects load. Stand within 65 studs of your own upgrade marker and 75 studs of its Chest; if several plots are too close to distinguish, selection stays unset until you move closer. Close with X to stop workers and movement; rerun replaces the previous UI.
- Press **LeftAlt** to minimize or restore the main window. When minimized, click the small **MY ANIME MINE [+]** restore control near the upper-left corner to reopen. Hiding the window leaves active automation toggles untouched. RightAlt does nothing.
- Does **not** invoke undocumented remotes, buy items, sell ores/characters, auto-summon, assign crew, auto-upgrade research, or teleport.
- Plot selection is based on proximity to an `UpgradeClick` detector **and** ChestPrompt, **not verified ownership**. Stand near your own plot and inspect the auto-selected Plot number before enabling Auto Collect; it will not switch plots while operating. If walking stalls or MoveTo fails, automation turns OFF rather than teleporting or repeatedly walking forever.
- A Take All signal call is evaluated after 2.5 seconds. A manually clicked Take All also closes the Chest, so automatic `CHEST_CLOSED_AFTER_TAKE_ALL` is no longer treated as an immediate failure. The script ignores stale closed-GUI values, waits **12 seconds** before attempting to open the selected Plot Chest again, and compares the fresh item count with its pre-click count. A lower count suggests collection but **does not prove inventory credit**; mining may occur concurrently. It pauses after **two inconclusive reopen comparisons** or **six Take All dispatches** per enable cycle, and still pauses after three unchanged open-Chest readings. Re-enable Auto Collect to reset the test cycle.
- Interactions are experimental: the live game might mine through proprietary server remotes/UI rather than exposed detectors/prompts. A detected interaction **is not proof** of an ore/reward gain. The function is a starting point for in-game diagnostics, not a verified auto-farm.
- Auto Mine requires `fireclickdetector`; Auto Collect requires `fireproximityprompt` or `firesignal` executor support. Successful function calls are **not** proof of an ore reward.
- **Manual vs auto comparison:** leave `AUTO COLLECT` OFF, click `WATCH MANUAL TAKE ALL: ON`, open your own Chest and click the game's Take All button **normally with the mouse**. The hub only observes the game button event and Chest UI feedback; it does not send its own click in this mode. Click `COPY TARGET DIAGNOSTICS` for `Manual TakeAll feedback`, `manualClickCount`, before/after counts and window state. A manual click that closes the Chest reports `MANUAL_CHEST_CLOSED` and ignores stale labels. Verify inventory in-game before making conclusions.
- The game normally mines rocks through **placed anime characters**. Rock ClickDetectors may be unrelated selection controls, so Auto Mine (CLICK) is experimental and not guaranteed to mine.
- Test automation in the live game before claiming gameplay success.

## Runtime test

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/Mxxchxi/My-Roblox-Hub/main/Loader.lua"))()
```

For reporting a failure: enter the actual game, select SCAN GAME, select COPY LOG, and paste the log. Confirm that the GUI `MyAnimeMineHub` appeared and the console reported `Started My Anime Mine`.

## Regression checklist

- [ ] UI loads when entering My Anime Mine.
- [ ] If no Equip Best candidate is visible, copy the complete game GUI Button[]/Hidden[] paths; icon-only toolbar inventory controls are detected where their context is identifiable.
- [ ] Out-of-range selected-plot Holder UpgradeClick reports distance/max range and moves within range naturally, without teleporting or entering another plot.
- [ ] Auto Collect V0.8 behavior continues normally whenever upgrade navigation is inactive.
- [ ] AUTO EQUIP BEST and AUTO UPGRADE STATS start OFF, operate independently, and do not interrupt Auto Collect.
- [ ] Equip Best finds an Inventory game button and dispatches its supported click event; verify equipped units in Roblox.
- [ ] Stat upgrades find only the selected plot's Holder UpgradeClick and Damage/Speed/Mining Speed buttons, not Robux or Research purchases.
- [ ] COPY EQUIP / UPGRADE TARGETS lists button and holder paths; hidden game purchase buttons are not clicked.
- [ ] All automatic toggles begin OFF.
- [ ] The UI can be closed and the loader can be rerun without duplicate windows.
- [ ] LeftAlt hides and restores the window; restore chip works, and active toggles are retained.
- [ ] SCAN GAME produces useful diagnostics, including prompt hierarchy and Take All detection.
- [ ] COPY TARGET DIAGNOSTICS includes selected plot, Chest range, action signal connections, current Chest count, before/after/delta, last event, pending feedback, and manual click observations.
- [ ] If a Take All click hides the Chest, outcome is `CHEST_CLOSED_AFTER_TAKE_ALL`, stale after-count is unknown, and a 12s cooldown precedes reopening.
- [ ] A freshly reopened Chest is compared against the prior count; two inconclusive comparisons pause Collect.
- [ ] Manual watch runs while Auto Collect is OFF and does not fire any executor click/Remote.
- [ ] Check the real inventory/ore after manual and automatic Take All; closing and count changes only provide UI evidence.
- [ ] After Take All, verify actual ore balance manually; successful signal calls and visual UI changes alone are not proof.
- [ ] Repeated unchanged GUI dispatches pause Auto Collect instead of endlessly firing signals.
- [ ] Auto Plot requires a nearby UpgradeClick and matching ChestPrompt and leaves ownership unverified. Ambiguous/remote plots remain unselected.
- [ ] Auto Collect does not target chests in unselected plots.
- [ ] Auto Collect ON automatically enables bounded walking; OFF stops walking; blocked or failed movement turns it OFF.
- [ ] Executor exposes interaction functions and the selected rock/chest actually changes in-game.
- [ ] Existing Roll A Stickman and Steal An Egg UIs still open from the same loader.
