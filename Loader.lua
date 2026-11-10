-- My Roblox Hub | Universal Multi-Game Loader V3
-- The registry and selected script are fetched from the same Git commit.
if not game:IsLoaded() then game.Loaded:Wait() end

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local player = Players.LocalPlayer
local playerGui = player and player:WaitForChild("PlayerGui", 15)
local ROOT = "https://raw.githubusercontent.com/Mxxchxi/My-Roblox-Hub/"
local API = "https://api.github.com/repos/Mxxchxi/My-Roblox-Hub/git/ref/heads/main"
local gui, label

local function status(message, failed)
    local prefix = "[My Roblox Hub] "
    if failed then warn(prefix .. message) else print(prefix .. message) end
    if not playerGui then return end
    if not gui then
        local old = playerGui:FindFirstChild("MyRobloxHub_LoaderStatus")
        if old then old:Destroy() end
        gui = Instance.new("ScreenGui")
        gui.Name = "MyRobloxHub_LoaderStatus"
        gui.ResetOnSpawn = false
        gui.DisplayOrder = 1001
        label = Instance.new("TextLabel")
        label.Position = UDim2.fromOffset(12, 105)
        label.Size = UDim2.fromOffset(510, 50)
        label.Font = Enum.Font.Code
        label.TextSize = 13
        label.TextWrapped = true
        label.TextColor3 = Color3.new(1, 1, 1)
        label.Parent = gui
        gui.Parent = playerGui
    end
    label.BackgroundColor3 = failed and Color3.fromRGB(116, 38, 53)
        or Color3.fromRGB(24, 76, 69)
    label.Text = "MY ROBLOX HUB | " .. message
end

local function fetch(url)
    local content = game:HttpGet(url)
    assert(type(content) == "string" and #content > 0, "Empty response")
    return content
end

local function compile(source, name)
    assert(type(loadstring) == "function", "Executor loadstring unavailable")
    local fn, err = loadstring(source, "@" .. name)
    assert(fn, err)
    return fn
end

local ok, err = xpcall(function()
    local nonce = HttpService:GenerateGUID(false)
    status("Checking game " .. tostring(game.PlaceId) .. "...")
    local ref = "main"
    local apiOk, head = pcall(function()
        return HttpService:JSONDecode(fetch(API .. "?_=" .. nonce))
    end)
    local sha = apiOk and type(head) == "table" and head.object and head.object.sha
    if type(sha) == "string" and #sha == 40 and sha:match("^%x+$") then
        ref = sha
    else
        status("Commit lookup unavailable; using uncached main")
    end
    local function download(path)
        return fetch(ROOT .. ref .. "/" .. path .. "?_=" .. nonce)
    end
    local registry = compile(download("GameRegistry.lua"), "GameRegistry.lua")()
    assert(type(registry) == "table", "Invalid game registry")
    local entry = registry[game.PlaceId]
    if not entry then
        status("Unsupported game (PlaceId " .. tostring(game.PlaceId) .. ")", true)
        return
    end
    assert(type(entry) == "table" and type(entry.script) == "string", "Invalid registry entry")
    assert(entry.script:match("^Games/[%w_%-/]+%.lua$")
        and not entry.script:find("%.%.", 1, true), "Unsafe script path")
    local source = download(entry.script)
    if entry.revisionPattern then
        local rev = tonumber(source:match(entry.revisionPattern))
        assert(rev and rev >= (entry.minRevision or 0), "Script revision check failed")
    end
    local run = compile(source, entry.script)
    status("Starting " .. tostring(entry.name or game.PlaceId) .. "...")
    run()
    status("Started " .. tostring(entry.name or game.PlaceId) .. " · " .. ref:sub(1, 7))
    if gui then
        local completed = gui
        task.delay(8, function()
            if completed and completed.Parent then completed:Destroy() end
        end)
    end
end, function(message)
    return tostring(message)
end)
if not ok then status("FAILED: " .. err, true) end
