# Steal An Egg — diagnostics v1.1

PlaceId: `107778070777162`. Metadata inspection only; the five gameplay automation features await live game data.

Use the same universal loader in Potassium after the game loads:

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/Mxxchxi/My-Roblox-Hub/main/Loader.lua"))()
```

If a prior test set a branch override, clear it once with `getgenv().MyRobloxHubRef = nil` before running the loader.

Press **Copy report** and return the JSON for review. Scan again after opening hatch, upgrade and treadmill interfaces.

v1.1 fixes the v1.0 shared-budget depth-first traversal: separate FIFO scans reserve 6,000 objects for PlayerGui, 12,000 for Workspace and 6,000 for ReplicatedStorage. ReplicatedStorage.Assets is intentionally excluded and listed in root skipped metadata. Each root has a five-second limit and 30,000 queue entries; each category is limited to 300 results per root. Per-root metadata records limits and dropped results. Scans yield every 150 objects. Candidate classes exclude cosmetic constraints. PlayerGui visibility checks ancestor Visible/Enabled flags; it does not establish on-screen occlusion or clipping. Remote names alone do not establish argument contracts.

Validation: Lua 5.4 syntax check, simulated 13,000-asset starvation regression, result-overflow regression, and all 4 existing loader contract tests passed locally. Roblox APIs and Potassium execution require in-game verification.
