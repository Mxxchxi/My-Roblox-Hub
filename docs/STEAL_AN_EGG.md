# Steal An Egg — diagnostics

PlaceId: `107778070777162`. This module inspects local object metadata; it does not automate gameplay yet. Egg collection, hatching, cash collection, upgrades and speed training await in-game diagnostics.

Run in Potassium after the game loads:

```lua
getgenv().MyRobloxHubRef = "feature/steal-an-egg-diagnostics"
loadstring(game:HttpGet("https://raw.githubusercontent.com/Mxxchxi/My-Roblox-Hub/feature/steal-an-egg-diagnostics/Loader.lua"))()
```

Press **Copy report** and return the JSON report for review. Scan again after opening the hatch, upgrade and treadmill interfaces. Scans yield every 150 objects, stop at 12,000 objects, and cap each result list at 400 entries; `truncated` indicates incomplete results. UI `visible` is the object's own flag, not effective ancestor visibility. Remote names do not establish their argument contracts.

Static loader contract checks: 4 passed locally. Potassium execution and in-game behavior have not been verified.

For normal main-branch use after testing, clear the override with `getgenv().MyRobloxHubRef = nil`.
