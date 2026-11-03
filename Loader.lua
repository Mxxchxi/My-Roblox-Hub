-- My Roblox Hub loader. Save this loader in your executor's Auto Execute list.
if not game:IsLoaded() then game.Loaded:Wait() end
if game.PlaceId ~= 115068315659966 then
    warn("[RAS] This loader supports Roll A Stickman (PlaceId 115068315659966)")
    return
end

local url = "https://raw.githubusercontent.com/Mxxchxi/My-Roblox-Hub/main/Games/RollStickman_Combined_V1_2.lua"
local ok, err = xpcall(function()
    assert(type(loadstring) == "function", "Executor loadstring is unavailable")
    local source = game:HttpGet(url)
    assert(type(source) == "string" and #source > 0, "Downloaded script is empty")
    local run, compileError = loadstring(source, "@RollStickman_Combined_V1_2.lua")
    assert(run, compileError)
    run()
end, function(message)
    return tostring(message)
end)
if not ok then
    warn("[RAS] Loader failed: " .. err)
end
