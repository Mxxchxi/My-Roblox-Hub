# My Anime Mine (v0.13)

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

- **AUTO SELL ORES (new V0.13, OFF by default):** arms an opt-in interaction with the game's native `Auto Sell` control under `PlayerGui/MineGui/ChestFrame`. It does **not** open the Inventory, Shop, Holder, or a separate selling panel. The control can already exist while the Chest is hidden. Only a single native `MouseButton1Click` or `Activated` listener can be selected, and only when the UI shows an unambiguous current `OFF` state. A button labeled `Auto Sell` without an observable `ON/OFF` state is **not clicked**; instead it reports `AUTO_SELL_STATE_UNKNOWN`.
- **Disable:** switching the hub's AUTO SELL ORES OFF attempts to set the native toggle OFF only if its current state is explicitly ON. If the native state cannot be read, the hub reports this uncertainty rather than firing a blind toggle. The hub OFF switch cannot guarantee the game's native setting was disabled in that case.
- **Scope and verification:** Auto Sell is restricted to `MineGui/ChestFrame`, excluding character/equipment sales, Shops, Gamepasses and controls showing Robux pricing. At most one signal is sent for each requested ON/OFF transition; a successful signal dispatch is **not proof** of sold ores, money credited, or an accepted server operation. No guessed `RemoteEvent:FireServer` is used.
- **Diagnostics:** `COPY EQUIP / UPGRADE TARGETS` now also includes native Chest Auto Sell candidate buttons, matching labels, listener counts, observed ON/OFF state, and action feedback. Use these results to refine the mapping if the game uses a different kind of toggle. 


- **Headless-only Equip/Upgrade (V0.13):** when AUTO EQUIP BEST or AUTO UPGRADE STATS is ON, the hub never attempts to open the game's Inventory, Stats, Holders, or Upgrades panels. Auto Collect remains unchanged.
- **Equip Best without showing a game panel:** if a *game-native* Equip Best button and a real click listener are already loaded under `MineGui/InventoryFrame` (even when that frame is hidden), the hub can emit that existing signal without displaying Inventory. This is only a best-effort client-side dispatch and may not produce an equipment change; no success is inferred.
- **Upgrade without showing a game panel:** this requires the game's actual server command and parameters. They are **not contained in existing diagnostics**. The hub does NOT make up Remote arguments or silently click Holder/Stats/Buy controls. It reports `HEADLESS_PROTOCOL_UNKNOWN` until the correct API is identified.
- **Remote discovery:** `COPY EQUIP / UPGRADE TARGETS` includes a read-only list of plausible RemoteEvents/RemoteFunctions from ReplicatedStorage. Discovery does not call `FireServer` or `InvokeServer`, and a name alone does not establish a safe argument signature.


- **Historical V0.11 diagnostics:** The game's textless Hotbar Inventory launcher and a separate UpgradesButton were identified, but V0.13 does not automatically click them. A prior Plot inspection found Holder detectors, but V0.13 no longer approaches or clicks them in headless mode.
- **Target diagnostics:** copy visible/hidden GUI control paths and read-only remote names to identify a direct backend protocol without guessing a purchase method.
- **AUTO EQUIP BEST** (OFF by default): checks already-loaded game-native hidden Equip Best listeners without clicking the Inventory opener. Never opens Inventory in V0.13; if no listener exists, reports HEADLESS_TARGET_UNKNOWN. Any equipment change still needs live verification.
- **AUTO UPGRADE STATS** (OFF by default): runs in headless discovery mode. It does not open a Holder or Stats window and does not buy upgrades until the game's exact server-side upgrade command and parameters can be verified. This prevents guessing routes for purchases involving game currency or premium products.
- Two independent toggles leave the previously working Auto Collect behavior unchanged. Headless action probes do not navigate to Holder or open any game GUI window.
- **COPY EQUIP / UPGRADE TARGETS** reports candidate game GUI paths, readable labels, click listener counts, selected holder, action stages, and dispatch statistics. If a target is missing or an upgrade does not take effect, paste this copied report.


- Scans nearby `ClickDetector` instances associated with rock/ore names.
- Scans nearby `ProximityPrompt` instances associated with collecting/chests.
- Auto Mine attempts nearby `fireclickdetector` interactions on a timer **only when manually enabled**.
- **AUTO PLOT + AUTO WALK:** the script automatically chooses a nearby `MinePlotN` using the closest matching Chest and UpgradeClick marker, provided there is no ambiguous second candidate. It locks the selection for the session; it does **not** prove ownership. On **AUTO COLLECT: ON**, walking to that selected plot Chest is automatically enabled. It uses natural `Humanoid:MoveTo` (no teleport, bounded 145 studs, stops Collect after 11 seconds without movement progress). The manual `SET MY PLOT` and `WALK TO CHEST` controls have been removed.
- Includes SCAN GAME, COPY LOG and **COPY TARGET DIAGNOSTICS** with target/range details, Take All signal connection counts (`Activated` and `MouseButton1Click`), a read-only Chest UI text snapshot, event method, and post-dispatch feedback. When `getconnections` is unavailable, the script alternates these two button signal types after inconclusive attempts.
- Automation toggles and walking start **OFF**. A plot is auto-discovered on startup, retrying when world objects load. Stand within 65 studs of your own upgrade marker and 75 studs of its Chest; if several plots are too close to distinguish, selection stays unset until you move closer. Close with X to stop workers and movement; rerun replaces the previous UI.
- Press **LeftAlt** to minimize or restore the main window. When minimized, click the small **MY ANIME MINE [+]** restore control near the upper-left corner to reopen. Hiding the window leaves active automation toggles untouched. RightAlt does nothing.
- Does **not** invoke undocumented remotes, buy premium items, sell characters/equipment, auto-summon, assign crew, auto-upgrade research, or teleport. The experimental ore-only Auto Sell toggle is the sole selling-related feature; server-side sale is not verified.
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
- [ ] AUTO SELL ORES starts OFF, can be switched ON/OFF independently, and never sends an unknown Remote or opens extra game windows.
- [ ] Native Chest Auto Sell recognizes an OFF state and fires exactly one confirmed UI listener, then reports the observed state without claiming credited money.
- [ ] An already-ON toggle does not get clicked OFF by enabling the feature; a known ON state is clicked once when the feature is disabled.
- [ ] If the state is UNKNOWN, no click is sent, and diagnostics identify the Chest Auto Sell label/button problem.
- [ ] Global Sell All / Sell Characters / Robux-premium controls are excluded and never clicked.
- [ ] COPY EQUIP / UPGRADE TARGETS includes ChestSell and ChestSellLabel candidates, listener counts, and native sell action status.
- [ ] Enabling Auto Equip/Upgrade does not click InventoryButton, UpgradesButton, Holder UpgradeClick or Stats tab automatically.
- [ ] A hidden native MineGui/InventoryFrame Equip Best button with an attached listener can receive a signal without opening the frame.
- [ ] Unknown headless upgrade commands produce HEADLESS_PROTOCOL_UNKNOWN and do not invoke remotes or spend game currency.
- [ ] COPY EQUIP / UPGRADE TARGETS includes read-only headless Remote names and reports whether a hidden native Equip Best listener exists.
- [ ] Actual MineGui Hotbar InventoryButton/TextButton is recognized and clicked through MouseButton1Click when Auto Equip is ON and an Equip Best button is not already visible.
- [ ] Upgrade continues target discovery immediately after plot selection; the diagnostic records the latest worker tick and Holder click attempted.
- [ ] Base UpgradesButton is identified as a separate read-only target, not purchased automatically from miner Stats mode.
- [ ] Hidden GUI diagnostic skips repeated inventory Card buttons so Equip and upgrade controls remain discoverable.
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
