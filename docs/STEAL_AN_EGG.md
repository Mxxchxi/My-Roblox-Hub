# Steal An Egg — diagnostics + Auto Hatch test v1.6

PlaceId: `107778070777162`. Auto Hatch has an opt-in nearby-prompt test. Egg collection, cash collection, upgrades and speed training await action/argument mapping.

Use the same universal loader in Potassium after the game loads:

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/Mxxchxi/My-Roblox-Hub/main/Loader.lua"))()
```

If a prior test set a branch override, clear it once with `getgenv().MyRobloxHubRef = nil` before running the loader.

Press **Copy report** and return the JSON for review. Scan again after opening hatch, upgrade and treadmill interfaces.

v1.1 fixes the v1.0 shared-budget depth-first traversal: separate FIFO scans reserve 6,000 objects for PlayerGui, 12,000 for Workspace and 6,000 for ReplicatedStorage. ReplicatedStorage.Assets is intentionally excluded and listed in root skipped metadata. Each root has a five-second limit and 30,000 queue entries; each category is limited to 300 results per root. Per-root metadata records limits and dropped results. Scans yield every 150 objects. Candidate classes exclude cosmetic constraints. PlayerGui visibility checks ancestor Visible/Enabled flags; it does not establish on-screen occlusion or clipping. Remote names alone do not establish argument contracts.

Validation: Lua 5.4 syntax check, simulated 13,000-asset starvation regression, result-overflow regression, and all 4 existing loader contract tests passed locally. Roblox APIs and Potassium execution require in-game verification.


## v1.3 clipboard export

**Copy all** always sends the complete report, without silently shortening it. It tries available executor clipboard aliases. When getclipboard/readclipboard can return text, exact readback is required for a VERIFIED message. Mismatches try the next writer. Unreadable clipboard calls are reported as unverified.

If no verified copy succeeds, the full report replaces the page view and is selected for native **Ctrl+C**. **Select ALL** provides the same selection directly. Previous/next page buttons still return to the paged view. If the TextBox cannot hold the full report, the status says so.

**Copy short** explicitly exports an incomplete summary (summaryOnly=true), limited to roughly 10 KB, with active prompts, visible GUI metadata and remote names; candidates are excluded and omitted counts are recorded. It is a fallback for message/clipboard size limits, not the complete diagnostic record. **Save file** continues to save the full report to the executor workspace.

Clipboard operations affect the computer running Potassium. They do not transfer text to a different computer. Paste into ChatGPT on that computer or use the remote-access application\u2019s clipboard sync when available.

Validation: Lua syntax, simulated full-text selection, no-op clipboard detection, failed-writer alias fallback, unreadable clipboard handling, executor/nested aliases, UTF-8 preservation, prior scan regressions and 4 loader contract checks passed. Potassium and remote clipboard synchronization need real-device verification.

## v1.4 focused reports

The v1.3 user report showed all generic scan budgets exhausted and a short report dominated by live-event remotes. v1.4 supplements the generic scan with a read-only inventory of the observed ReplicatedStorage.Packages.Networking folder (4,000 visited objects, 8,000 queue limit). The supplemental scan has its own scanned/truncated metadata; generic scan totals are unchanged.

Copy short now sorts core egg/hatch/treadmill/upgrade/plot/base/cash/coin/speed/PenRoster metadata before unrelated events. It reserves separate JSON budgets for remotes, GUI, prompts and candidates (6,000/3,000/2,000/3,000 bytes plus metadata). Candidate ownership/position is retained; duplicate rows are grouped with a count and omitted totals. The full report remains available through Copy all and Save file. Prompt metadata adds hold duration and position where available to distinguish same-named SmartPromptPart objects. No gameplay remote calls are made.

Validation: supplemental recovery beyond the generic 300-remote cap, priority filtering under a simulated 300-event flood, GUI/prompt preservation, candidate ownership retention and existing clipboard/scan regressions passed. Loader checks passed 4/4. Real-device behavior awaits the next report. Remote names still do not prove call direction or argument contracts.

## v1.5 Auto Hatch test

Run the same universal loader, wait for the initial scan, then enable **Auto Hatch: ON** and stand within seven studs of a ready egg displaying the exact action `Hatch!`. The loop checks once per second and uses ProximityPrompt.InputHoldBegin/InputHoldEnd. It does not invoke guessed remote arguments. Actual hatch success must be observed in-game; input dispatch is not reported as hatch success.

Default OFF; only enabled Hatch! prompts in Workspace are eligible with a living local character and within the smaller of seven studs and MaxActivationDistance. At least four seconds between attempts, maximum three attempts per prompt per toggle. Toggle OFF/ON resets the attempt allowance. Prompts are tracked during scanning and streaming; close/rerun stops the loop, releases held input and disconnects prompt listeners. No movement or egg collection is implemented in this test.

After testing press Scan and Copy short to include attempt counters and status. The current report confirms RF/EggWorld/AskHatch, AskFinishHatch, AskPlaceEgg, RE/Homestead/AskBaseTierRaise and Treadmill-related notification names, but not their argument contracts. Notification names are not treated as client commands. Other four requested systems remain pending.

Validation: syntax and simulated default-OFF, exact action, enabled/alive/range, hold release, cooldown, attempt-cap and closed-loop guards passed. Existing scan/clipboard checks and 4 loader contracts passed. Real Potassium behavior is not verified.

## v1.6 live hatch diagnostics

The v1.5 user report contained enabled=true and attempts=0, but no character distance. That does not establish whether range, timing or another condition blocked input. v1.6 records the nearest cached Hatch! prompt, actual character distance, allowed distance, alive state, cache count, scan/input state and a blocker reason. Copy all, Copy short and Save file refresh this data at export time instead of reusing a scan-time snapshot.

After loading, wait for the initial scan, stand near the egg, press **Test Hatch once**, wait two seconds and press **Copy short** directly without another Scan. The one-shot test works while Auto Hatch is OFF and uses the same enabled/action/alive/range/cooldown/attempt-cap checks. It does not confirm hatch success. Toggle OFF/ON resets the attempt cap if needed.

Validation: distance and blocker reporting, export-time attempt-counter updates, one-shot test with auto OFF, prior hatch/clipboard/scan regressions and 4 loader contract checks passed locally. Potassium execution still requires in-game verification.
