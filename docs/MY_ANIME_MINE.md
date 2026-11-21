# My Anime Mine (v0.24)

- Roblox game: https://www.roblox.com/games/79389059854988/My-Anime-Mine
- PlaceId: `79389059854988`
- Game module: `Games/MyAnimeMine.lua`
- Registry: `GameRegistry.lua`
- Expected PlayerGui: `MyAnimeMineHub`

Use the **same** loader as the other games:

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/Mxxchxi/My-Roblox-Hub/main/Loader.lua"))()
```

## Audit findings: V0.21 (code review, not live sale confirmation)

- The user-supplied V0.16 log shows the exact GingerbreadKeeper seller sequence was dispatched: 1 Shops teleport launcher, 1 SellPrompt interaction, **Select All 1/1**, and **SellButton 1/1**. However **`DONE` means only a client GUI signal was dispatched**. There is no authoritative comparison of inventory ore count or cash balance; therefore `SALE_CONFIRMED` cannot be claimed. When DONE the hub now displays **`AUTO SELL ORES: SENT`** to distinguish it from a verified sale.
- **One-shot route only:** `sell` remains ON after DONE/PAUSED to keep the previous Auto Collect worker from issuing movement commands at Shops. No automatic return-to-Plot navigation or periodic sell cycle exists. The user must verify ore/currency, turn Auto Sell OFF, return to their own Plot, and inspect Collect before using it again. A normal user-facing status is not proof of server success.
- **Scope hardening:** both explicit `Sell Ores` and the vendor-bound generic `SellButton` are now searched only inside the visible, current `MineGui/SellFrame` and after the seller session was opened. Unrelated inventory/store `Sell Ores` controls are not eligible. `Select All` still must precede any Sell action.
- **Touch-only vendor fix:** reaching an identifiable SellStand / SellItemsStand marker within 3 studs now authorizes the selection phase **only when the actual SellFrame is visible**. It does not enable the textless generic SellButton, which remains gated to GingerbreadKeeper's verified `SellPrompt`. The prior simulated test did not complete a touch-only sale after SELECT_ALL; V0.21 adds that full-path regression.
- **Unverified pathways:** the Warp-to-Shops stage treats more than 50 studs of movement as evidence of transport, not proof of landing at Shops. Lack of the live game's inventory/currency schema prevents reliable server-side sale confirmation. No guessed RemoteEvents are used.

## V0.21: Wait for Chest before attempting Shops warp

- **Issue from live V0.17 log (01:51:47–01:52:13):** Auto Collect opened the MinePlot1 Chest at 01:51:51, then Auto Sell was activated in the same second. The game-native `TeleportButton` was absent from the visible UI scan and 15 seconds later the sell route reported `TeleportButton not found`. An open Chest UI is a likely cause because the UI can hide the hotbar. The log does **not** prove that was the only cause.
- **Chest handoff:** starting AUTO SELL ORES now enters `CHEST_HANDOFF` and waits briefly for the Chest UI to settle. If `MineGui/ChestFrame` is open while Auto Collect is ON, only the existing **Take All** action is allowed to continue; the sell route waits until the Chest closes and any pending Take All feedback settles. It does not reopen Chest or navigate back to a Plot during this period.
- **Bounded behavior:** if a Chest remains open or Take All remains pending for more than 24 seconds, the sell route pauses with instructions to finish Take All or close the Chest manually. The script does not guess a Close button or invoke undocumented remotes. When the Chest is closed, it proceeds with the original Teleport > Shops > vendor > Select All > Sell sequence.
- **Improved diagnostics:** `COPY SELL ROUTE` now reports Chest visibility, Take All pending/visible status, handoff state, and every `MineGui/TeleportButton` candidate's visibility and listener counts. An existing but hidden button is distinguished from an absent button; several eligible buttons are never chosen arbitrarily. Shops destination buttons are clicked only when the game's Teleport menu actually shows them; previously cached hidden destinations are ignored.
- **Known remaining limitations:** Remote `ClaimOre`/`SellItems` names in the game do not establish safe argument signatures. Cash and ore changes remain unverified and returning to MinePlot after selling is not yet automated. Auto Upgrade still reports `HEADLESS_PROTOCOL_UNKNOWN`, and headless Equip dispatch is not proof the gear changed.

## V0.21: Finish a current Auto Collect cycle before selling

- **Confirmed by the live V0.18 02:05–02:05:36 log:** at 02:05:09 Auto Collect was **walking to MinePlot1 Chest (19.1 studs away)**, then Auto Sell was switched ON at 02:05:10. At 02:05:12 the old `CHEST_HANDOFF` reported "Chest clear" because no Chest was open yet, and immediately warped to Shops. No `OPEN CHEST` or `Take All` dispatch appeared in that log before the sale. Shops warp, GingerbreadKeeper interaction, Select All and Sell subsequently *dispatched* successfully. The log does **not** prove an actual sale or credited currency.
- **Fix:** when AUTO SELL ORES is turned ON while AUTO COLLECT is ON, the Chest handoff **does not cancel the ongoing Chest walk**. It allows the current Auto Collect worker to reach and open the selected Plot Chest and dispatch **one Take All**, or to observe an explicitly empty Chest, before moving toward Shops. Once Take All was dispatched, no new Chest open/walk is allowed, and the sell worker waits for Take All feedback and Chest closure. This preserves the existing Collect action logic instead of reimplementing or guessing the ClaimOre server protocol.
- **Boundaries and diagnostics:** the collection handoff pauses after 42 seconds without a Take All (or confirmed empty Chest), and also waits for a close of any open Chest / in-flight Take All. It does not teleport if the Collect worker stopped, had no safe Plot, or could not finish. `COPY SELL ROUTE` exposes the Take All dispatch counter at handoff and at present, whether the handoff required collection, whether it observed the dispatch/empty chest, and whether the character is still walking toward Chest.
- **Scope:** if AUTO COLLECT is OFF, the existing V0.18 Chest-open handoff remains. No new premium purchases, server remotes, arbitrary teleport CFrames or auto-return-to-Plot behavior is introduced. A successful Take All GUI dispatch still does not prove items entered the inventory. The sale is one-shot and must be checked manually for actual ore/currency changes.

## V0.21: Reuse a very recent Take All before selling

- **Live evidence:** V0.19 dispatched Take All at 02:38:53 for MinePlot5 (Chest count shown as 4,245) and recorded the Chest closing at 02:38:56. Auto Sell was enabled at 02:38:56, yet the handoff required a NEW Take All dispatch, reopening Chest at 02:39:09 and dispatching another at 02:39:10 (Chest count shown as 857). Only then did the existing route go Shops → GingerbreadKeeper → Select All → Sell. The count change does **not** prove inventory was credited.
- **Improvement:** retain the latest successful **GUI Take All dispatch** time and selected Plot. When Auto Sell is enabled with Auto Collect ON, a dispatch **within the last eight seconds on the same Plot** can satisfy the collection handoff **only if that dispatch is still pending or its last Chest UI outcome was `CHEST_CLOSED_AFTER_TAKE_ALL` and the Chest is closed**. If pending, continue waiting for feedback and closure. This avoids an unnecessary repeat Chest reopening after a just-completed Take All.
- **Safety:** stale dispatches, another Plot's dispatch, absent/invalid feedback, or no Collect toggle do not grant reuse. The existing bounded wait for a new Take All remains; the known Shops → SellStand → Select All → Sell actions and Auto Collect worker are not changed. A closed Chest following a GUI dispatch still does **not** verify an inventory increase or money credit.
- **Diagnostics:** `COPY SELL ROUTE` includes `reusedRecentTakeAll`, the measured `recentTakeAllAge`, and `lastTakeAllPlot` as well as baseline/current dispatch counters.
- **Still unavailable:** there is no authoritative server cash/inventory schema or known verified Plot ownership API. V0.22 offers automatic recurring scheduled collection and sale, conditional on a verified Base return; it requires an actual Potassium playtest.

## V0.21: Return to Base after selling

- The game's developer mentions a native **Base / Shops** button in its October 24, 2026 update. In prior user logs, `MineGui/TeleportButton` successfully took the character from a MinePlot to Shops. This version uses the **same visible button once after the verified seller path sends Select All → Sell** to request return to Base; when the button opens an actual Teleport menu, an unambiguous visible `Base` / `My Base` / `My Plot` destination in that menu can be selected once.
- The return is **not inferred from movement alone**. The script reads the ChestPrompt distance for the SAME `selectedPlot` preserved before the sale, and requires being within 75 studs of that Plot (with clear travel from the shop when the starting distance is large). It never sets CFrame or selects another Plot, and a changed/missing target pauses the route.
- On a **verified near-base return**, Auto Sell ends automatically (its UI shows **RETURNED**) and previously enabled Auto Collect can resume its existing Chest navigation/collection. Auto Sell is still **one-shot**: it does not autonomously start another sale after the player returns. Auto Mine and the legacy Equip/Upgrade diagnostic logic remain unchanged.
- If the native Base/Shops button is hidden, the SellFrame remains open, there are multiple Base destinations, or the character does not approach the original MinePlot within the bounded wait, the sell route pauses and **Auto Collect stays paused**. Use `COPY SELL ROUTE` for the observed original Plot, Base button target, return click count, current distance, and verification status.
- **Important limitation:** selectedPlot was originally chosen by proximity; the game has not exposed a verified ownership field in current logs. Nearness to that Plot is a safety check, **not proof that the Plot belongs to the user**. Likewise, sending a GUI Sell click is **not proof of cash credit or successful ore sale**.

## V0.24: Diagnose and recognize the game's actual miner Stats GUI

- **Live runtime evidence (14:08:33–14:09:05):** the Auto Upgrade switch was ON, but its scanner reported `NO_LOADED_STATS_BUTTON_WITH_LISTENER (frames=0)`. No native Stats upgrade GUI click was sent and no miner stat level-up was observed. The game requires the player to **select a deployed miner and open its Stats tab** to expose the relevant panel. The prior headless scan recognized only a few exact frame names, which could also exclude a valid alternate name.
- **Discovery enhancement:** recognize alternate names such as `CharacterStatsPanel`, `UnitStatsPanel`, and similarly named Stats containers **only inside known game-owned crew/character GUI contexts**, while continuing to require an explicit Damage/Speed/Mining Speed stat row, a real active native click listener, and existing premium/shop exclusions.
- **Detailed read-only capture:** `COPY UPGRADE DIAGNOSTICS` now lists possible Stats panel paths and visibility; potential upgrade buttons' labels, stat contexts, premium status and listener counts. It also displays actionable instructions when the game hasn't loaded any Stats panel. This scanner never opens panels, buys currency or calls undocumented remotes.
- **How to verify:** in the Roblox game, click a **character already placed on your own MinePlot**, select **Stats** in the character window, keep the Stats panel open, then press the hub's **COPY UPGRADE DIAGNOSTICS** and share the complete report. If the button remains unrecognized, that report provides the concrete hierarchy needed for a targeted follow-up patch rather than guessing a purchase.
- **Unchanged safety/limits:** without a sufficiently identified GUI button, Auto Upgrade does **not** purchase anything. Auto Farm Sell/Return and premium safeguards are unchanged; simulated Lua tests do not demonstrate a successful real-game level increase.

## V0.23: Safe native Stats Auto Upgrade

- **Visible interface:** the compact main UI now shows **AUTO UPGRADE STATS: OFF** as a direct opt-in toggle, and **COPY UPGRADE DIAGNOSTICS** next to the existing timed Farm, Auto Mine, Equip Best, Copy Log and Copy Sell Route controls. Upgrade is OFF by default; the user must enable it separately from Auto Farm.
- **What it does:** without opening additional game windows, inspects **already loaded crew/unit Stats GUI frames** and uses a native game `MouseButton1Click` or `Activated` listener attached to a clearly labeled **Damage**, **Speed**, or **Mining Speed** upgrade row. Only controls inside a unique `UnitGui` / `MineGui` / `CrewGui` `StatsFrame` (or explicit unit/character upgrade frame) qualify. Multiple ambiguous Stats panels, duplicate controls, inactive listeners and unrecognized stat rows result in no purchase.
- **No premium or unknown network calls:** game-pass/Robux/paid labels, shop/research menu actions and global Upgrades menus are excluded by the existing context and premium check. No `FireServer`/`InvokeServer`, guessed remote arguments, Holder click or automatic GUI popup is added. Authorized in-game **normal currency** may be spent by the game-native Stats click, so enable the toggle only when desired.
- **Feedback and safety:** one Stats click is sent at a time (at most once per ~8-second worker interval); it waits for a change in the corresponding native Stats row before trying another stat. A changed row is *only UI evidence*, **not confirmation of a level increase or currency deduction**. If the row remains unchanged after feedback settles, upgrades PAUSE after that first unverified call rather than repeatedly spending. An error also pauses.
- **Compatibility with Auto Farm:** upgrading is allowed only when the character is within 75 studs of the currently selected MinePlot's Chest and, if the timed cycle is on, in **WAITING** at Base. It is paused during collection, Shops selling, Base return, and pending Take All. This avoids competing with the existing working Collect → Sell → Return sequence.
- **Live limitation:** prior game logs showed `HEADLESS_PROTOCOL_UNKNOWN` and did not reveal the real loaded Stats button structure. If `COPY UPGRADE DIAGNOSTICS` reports `NO_LOADED_STATS_BUTTON_WITH_LISTENER` or `MULTIPLE_CREW_STATS_PANELS`, **no real upgrade was made**. Provide that report after enabling Auto Upgrade for exact game mapping. Static/Lua simulation is not proof of a real Roblox upgrade.

## V0.22: Timed automatic collection, sale and return

- **Clean main UI:** the visible hub now has **AUTO FARM CYCLE**, an editable **collection interval in minutes** (1–180; default 5), adjacent **−1 / +1** buttons, optional **Auto Mine / Auto Equip Best**, **COPY LOG**, and **COPY SELL ROUTE**. The old manual Take All watcher, diagnostic-only Auto Upgrade, separate Auto Collect/Sell switches, manual scan and duplicate target diagnostics are hidden from the main view for clarity. Their backend test hooks remain to preserve historical regression tests; they are not user-facing.
- **Cycle semantics:** turning on **AUTO FARM CYCLE** begins **one Chest collection immediately**. The scheduler waits until a Take All GUI event is dispatched, Chest closes and its pending UI feedback settles, then automatically runs the already-tested **Shops → GingerbreadKeeper SellPrompt → Select All → Sell → Base/Shops return** route. It accepts only the same MinePlot's proximity-verified return before releasing further collection.
- **Time between collections:** the next Chest collection is due **N minutes after the prior Take All dispatch**, not N minutes after the sale or return. After returning to Base, Auto Collect remains paused until the due time; if selling/return took longer than the interval, the next collection begins as soon as the Base return is verified. The interval can be changed during WAITING and the countdown is recalculated from the preceding collection.
- **Boundaries:** no Take All in 90 seconds, Take All feedback/Chest close pending longer than 25 seconds, or a paused seller/return phase leads to **PAUSED**. The user's Auto Farm ON/OFF switch cancels the schedule, sale route and Chest movement. The script does not continue collecting from Shops or a mismatched Plot. No fabricated server remotes or CFrame teleports are added.
- **Limitations:** the clicked Take All / Select All / Sell buttons and return proximity are checked as client UI and position evidence. There is still **no authoritative confirmation that ore reached inventory, that Sell credited money, or that the nearest Plot is owned by the user**. The game's GUI may change and live Potassium testing is needed to verify the entire repeating loop.

## Features and limitations

Current visible controls in V0.23: Auto Farm timer, Auto Mine, Equip Best, **Auto Upgrade Stats**, Copy Log, Copy Sell Route, and **Copy Upgrade Diagnostics**. The old Manual Watch and manual Scan remain hidden.

- **AUTO SELL ORES — normal Shops route:** uses the user-confirmed path **Teleport → Shops → walk to Sell Items stand → sell ores**. It does not use the 149-Robux Auto Sell Game Pass or the native Chest Auto Sell toggle. The hub tries the existing `MineGui/TeleportButton` listener (or a loaded Shops warp button), detects an explicit `Shops` destination, then waits for actual character movement before finding a sell stand by its own names/ProximityPrompt. It never invents Shops coordinates or teleports by setting CFrame.
- **Natural navigation:** walks with `Humanoid:MoveTo` toward a grounded Sell Items prompt or stall after Shops warp. Navigation has a 185-stud target limit, a 14-second no-progress timeout, and uses only an exposed ProximityPrompt or ClickDetector when in activation range.
- **Select All → Sell (V0.21):** after reaching a sell stand and opening `MineGui/SellFrame`, the hub now requires **Select All** before triggering any Sell control. It looks for `SelectAllButton`, `Select All`, or an equivalent nested TextLabel **inside the same SellFrame Content**, checks for a single eligible button, and sends its existing GUI listener once. Only after the Select All click returns successfully and a short settle interval does the hub call the previously verified `SellButton`. If Select All is absent, ambiguous, belongs to another UI panel, or clicking it fails, the sale is paused without clicking Sell. This does not prove items were selected or money credited.
- **Selling at the confirmed SellStand (V0.21):** the user-provided V0.14 runtime log identifies `Workspace/SellStand/GingerbreadKeeper/UpperTorso/SellPrompt` and the resulting `PlayerGui/MineGui/SellFrame/Content/SellButton` with one MouseButton1Click listener. Auto Sell now recognizes that **exact, empty-text SellButton** only when the same route previously invoked the GingerbreadKeeper's SellPrompt and is in `SELL_MENU`. The SellFrame must be visible; sale buttons in other contexts are never used. If the SellFrame contains characters, pets, units, weapons, or equipment sale labels, clicking the generic button is blocked. A successful event call does not prove an ore sale or money credit.
- **Generic Sell and Sell All remain blocked** unless the target is the exact vendor-bound SellFrame/SellButton verified above; the previous explicit ore-only Sell Ores / Sell All Ores buttons remain supported. When the game's menu is changed, the script pauses instead of guessing. The V0.14 path through Teleport, Shops and walking to SellStand remains unchanged.
- **Interaction with Auto Collect:** during a Shops selling route, Auto Collect's prior worker stays paused as long as Auto Sell remains ON, including after `DONE`; after turning Auto Sell OFF its worker resumes. **Return travel to the player's Plot is not yet automated** because the game's return teleport target has not been identified; from Shops, return to your Plot before resuming the mining loop.
- **Verification:** use the dedicated **COPY SELL ROUTE** button for a compact report of Teleport/Shop options, nearest grounded stand, walking progress, and ore-only Sell controls. The existing **COPY EQUIP / UPGRADE TARGETS** also includes sell details. A dispatched click does not prove that any ore was sold or the cash balance changed.
- The old paid Chest Auto Sell button is documented as a **legacy diagnostic only** and is not used by the new Auto Sell toggle.

- **Headless-only Equip/Upgrade (V0.21):** when AUTO EQUIP BEST or AUTO UPGRADE STATS is ON, the hub never attempts to open the game's Inventory, Stats, Holders, or Upgrades panels. Auto Collect remains unchanged.
- **Equip Best without showing a game panel:** if a *game-native* Equip Best button and a real click listener are already loaded under `MineGui/InventoryFrame` (even when that frame is hidden), the hub can emit that existing signal without displaying Inventory. This is only a best-effort client-side dispatch and may not produce an equipment change; no success is inferred.
- **Upgrade without showing a game panel:** this requires the game's actual server command and parameters. They are **not contained in existing diagnostics**. The hub does NOT make up Remote arguments or silently click Holder/Stats/Buy controls. It reports `HEADLESS_PROTOCOL_UNKNOWN` until the correct API is identified.
- **Remote discovery:** `COPY EQUIP / UPGRADE TARGETS` includes a read-only list of plausible RemoteEvents/RemoteFunctions from ReplicatedStorage. Discovery does not call `FireServer` or `InvokeServer`, and a name alone does not establish a safe argument signature.


- **Historical V0.11 diagnostics:** The game's textless Hotbar Inventory launcher and a separate UpgradesButton were identified, but V0.21 does not automatically click them. A prior Plot inspection found Holder detectors, but V0.21 no longer approaches or clicks them in headless mode.
- **Target diagnostics:** copy visible/hidden GUI control paths and read-only remote names to identify a direct backend protocol without guessing a purchase method.
- **AUTO EQUIP BEST** (OFF by default): checks already-loaded game-native hidden Equip Best listeners without clicking the Inventory opener. Never opens Inventory in V0.21; if no listener exists, reports HEADLESS_TARGET_UNKNOWN. Any equipment change still needs live verification.
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
- Does **not** invoke undocumented remotes, buy premium items, sell characters/equipment, auto-summon, assign crew, auto-upgrade research, or set the character CFrame to teleport. The normal Shops warp button is used for travel when available; server-side ore sale is not yet verified.
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
- [ ] Auto Upgrade logs that no loaded Stats button was found and instructs opening a deployed miner's Stats tab; it sends no upgrade action.
- [ ] COPY UPGRADE DIAGNOSTICS captures alternate Stats panel names and button paths, labels, premium flags and native listener counts.
- [ ] Alternate crew Stats frame names such as CharacterStatsPanel are accepted only when explicit stat row and active listener pass all safety filters.
- [ ] Unknown remotes, Roblox premium buttons, game shop/research windows remain excluded.
- [ ] AUTO UPGRADE STATS and COPY UPGRADE DIAGNOSTICS are visible and OFF is the initial state.
- [ ] The headless upgrade worker calls only a loaded Stats row with exactly one verified native callback; Robux and duplicate panels never trigger clicks.
- [ ] UI row changes are reported as unverified evidence; an unchanged row pauses instead of endlessly repeating purchases.
- [ ] When Auto Farm is SELLING/COLLECTING/PAUSED, no Upgrade is dispatched; only while waiting near the selected Plot can it run.
- [ ] Main UI shows AUTO FARM CYCLE, minutes textbox and -1/+1 buttons, Mine/Equip and Log/Sell Route; test-only/diagnostic-only buttons are hidden.
- [ ] Interval accepts a valid 1-180 minute value, clamps out-of-range values and rejects non-numbers; edits while WAITING reschedule from last Take All.
- [ ] Turning cycle ON starts one Chest collection immediately; pending or unclosed Chest cannot initiate Shops sale.
- [ ] After Take All UI closes, scheduler arms exactly one Shops Sell route, without reopening Chest for a second Take All.
- [ ] On verified return to the same MinePlot, Auto Collect stays paused until the timer expires; then the next collection starts.
- [ ] When seller/return is PAUSED, no further timed Chest interactions happen; OFF cancels the whole cycle.
- [ ] COPY SELL ROUTE shows cycle number, minutes, phase, next due timestamp and seconds remaining.
- [ ] After Select All and Sell are dispatched, route enters RETURN_BASE_OPEN then RETURN_BASE_WAIT instead of stopping at DONE.
- [ ] Return uses the native Base/Shops TeleportButton once; if a visible Base menu destination exists, choose it only if unambiguous.
- [ ] Only return within 75 studs of the same selected Plot Chest can transition to RETURNED_BASE, turn Sell OFF, and release Auto Collect.
- [ ] If warp does not approach selected Plot within 17 seconds, PAUSED keeps Sell ON and Auto Collect locked.
- [ ] COPY SELL ROUTE reports return plot/target, clicks, status, before/after distance and verification flag.
- [ ] Direct-toggle return without a separate Base destination must also pass the bounded near-Plot verification.
- [ ] When Take All was sent and the Chest closed within eight seconds on the selected Plot, enabling Sell reuses it without reopening Chest.
- [ ] When the prior same-Plot Take All is still pending, SELL stays in CHEST_HANDOFF until feedback settles.
- [ ] An older-than-eight-second Take All, a different Plot or missing outcome cannot satisfy a new Sell handoff.
- [ ] COPY SELL ROUTE records reusedRecentTakeAll and its age. No claim of inventory or currency proof is made.
- [ ] Enabling Sell while Collect walks to Chest does not cancel the Chest MoveTo or prematurely launch Teleport.
- [ ] A new Take All dispatch relative to handoff baseline is required while Auto Collect was ON, or the Chest is known empty.
- [ ] Once Take All is dispatched, no new Chest walk/open is attempted while handoff awaits Chest closure/feedback.
- [ ] If no Take All occurs within 42 seconds, handoff pauses and identifies the failure in COPY SELL ROUTE; it does not silently warp.
- [ ] With Collect OFF, old Chest-only handoff still works without forcing an unrequested collection.
- [ ] Opening Auto Sell while MineGui/ChestFrame is visible enters CHEST_HANDOFF and does not click hidden TeleportButton.
- [ ] Pending Take All feedback prevents teleport even after Chest closes; once settled, route may proceed with the original Shops warp.
- [ ] If Chest stays open over 24 seconds, route pauses instead of guessing a close action.
- [ ] With Chest closed and no pending Take All, normal Shops -> SellStand -> Select All -> Sell regression still passes.
- [ ] COPY SELL ROUTE distinguishes hidden versus absent TeleportButton with a full Chest state report.
- [ ] After a simulated successful sell signal, UI shows AUTO SELL ORES: SENT (not ROUTING or SALE CONFIRMED).
- [ ] Explicit Sell Ores in other Inventory/Shop screens is excluded from the active SellFrame action candidates.
- [ ] Touch-only vendor test runs through SELECT_ALL and Sell using only an authentic marker and visible seller frame, with no ProximityPrompt.
- [ ] Auto Collect remains paused while Auto Sell remains ON, including when Sell has reached DONE. User manually returns to Plot after turning Sell OFF.
- [ ] Auto Sell begins OFF and does not invoke the paid native Chest Auto Sell control.
- [ ] Existing TeleportButton is clicked through a verified listener, then a Shops destination is selected only if unambiguous.
- [ ] Vendor is located through a real Sell Items prompt/stand; walking uses Humanoid:MoveTo and refuses distant targets or blocked paths.
- [ ] The sell-menu interaction is bounded to one vendor opening per route.
- [ ] At SellFrame, `Select All` must be clicked once and successfully dispatched **before** `Sell`. Never sell without the Select All step.
- [ ] If Select All is absent/ambiguous, the action pauses without issuing any Sell click.
- [ ] Either an explicitly ore-scoped Sell Ores action, or the exact MineGui/SellFrame/Content/SellButton following a confirmed GingerbreadKeeper SellPrompt may be clicked once after selection. Wrong panel, wrong vendor, missing vendor interaction, and generic Sell All must remain blocked.
- [ ] COPY SELL ROUTE shows separate Select All attempts/dispatches and Sell attempts/dispatches, including the last selection target.
- [ ] Auto Collect logic is unchanged and is paused while Shops route is active, not permanently disabled by this feature.
- [ ] COPY SELL ROUTE includes phase, Shops destination, vendor path/distance, and verified ore-only action, separate from full Equip/Upgrade diagnostics.
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
