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

Note: Executor HTTP/loadstring support is required. Test the loader in each game before release; no live executor test is performed by this change.
