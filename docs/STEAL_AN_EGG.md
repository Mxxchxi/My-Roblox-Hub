# Steal An Egg — diagnostics v1.4

PlaceId: `107778070777162`. Metadata inspection only; the five gameplay automation features await live game data.

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
