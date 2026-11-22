-- My Roblox Hub | Universal Multi-Game Loader V4
-- The registry and selected script are fetched from the same Git commit.
-- Show startup status before waiting on game or network readiness.

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local player = Players.LocalPlayer
local playerDeadline = os.clock() + 30
while not player and os.clock() < playerDeadline do
    task.wait(0.1)
    player = Players.LocalPlayer
end
assert(player, "LocalPlayer unavailable after 30s; execute again inside the game")
local playerGui = player:WaitForChild("PlayerGui", 30)
assert(playerGui, "PlayerGui unavailable after 30s; execute again inside the game")
local ROOT = "https://raw.githubusercontent.com/Mxxchxi/My-Roblox-Hub/"
local API_ROOT = "https://api.github.com/repos/Mxxchxi/My-Roblox-Hub/git/ref/heads/"
-- Optional test override: getgenv().MyRobloxHubRef = "feature/universal-multi-game-loader"
local environment = _G
if type(getgenv) == "function" then
    local envOk, env = pcall(getgenv)
    if envOk and type(env) == "table" then environment = env end
end
local requestedRef = type(environment) == "table" and environment.MyRobloxHubRef or nil
if type(requestedRef) ~= "string" or not requestedRef:match("^[%w_%-/]+$") or requestedRef:find("..", 1, true) then
    requestedRef = "main"
end
local gui, label, copyButton
local history = {}
local stage = "BOOT"

local function status(message, failed)
    local prefix = "[My Roblox Hub] "
    table.insert(history, tostring(message))
    if #history > 40 then table.remove(history, 1) end
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
        label.Size = UDim2.fromOffset(510, 90)
        label.Font = Enum.Font.Code
        label.TextSize = 13
        label.TextWrapped = true
        label.TextColor3 = Color3.new(1, 1, 1)
        label.Parent = gui
        copyButton = Instance.new("TextButton")
        copyButton.Size = UDim2.fromOffset(200, 30)
        copyButton.Position = UDim2.fromOffset(12, 198)
        copyButton.Text = "COPY LOADER REPORT"
        copyButton.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
        copyButton.TextColor3 = Color3.new(1, 1, 1)
        copyButton.Parent = gui
        copyButton.Activated:Connect(function()
            local report = "MY ROBLOX HUB LOADER V4\nPlaceId=" .. tostring(game.PlaceId)
                .. "\nStage=" .. stage .. "\n" .. table.concat(history, "\n")
            if type(setclipboard) == "function" and pcall(setclipboard, report) then
                copyButton.Text = "COPIED"
            else
                local box = gui:FindFirstChild("Report")
                if not box then
                    box = Instance.new("TextBox")
                    box.Name = "Report"
                    box.Size = UDim2.fromOffset(510, 180)
                    box.Position = UDim2.fromOffset(12, 234)
                    box.MultiLine = true
                    box.TextWrapped = true
                    box.ClearTextOnFocus = false
                    box.Parent = gui
                end
                box.Text = report
                box:CaptureFocus()
                box.CursorPosition = #report + 1
                box.SelectionStart = 1
                copyButton.Text = "PRESS CTRL+C"
            end
        end)
        gui.Parent = playerGui
    end
    label.BackgroundColor3 = failed and Color3.fromRGB(116, 38, 53)
        or Color3.fromRGB(24, 76, 69)
    label.Text = "MY ROBLOX HUB | " .. message
end

local function fetch(url, timeout)
    local finished, ok, result = false, false, nil
    task.spawn(function()
        ok, result = pcall(game.HttpGet, game, url)
        finished = true
    end)
    local deadline = os.clock() + (timeout or 20)
    repeat
        task.wait(0.1)
    until finished or os.clock() >= deadline
    assert(finished, "HTTP timeout at " .. stage .. " (try again)")
    assert(ok, "HTTP failed at " .. stage .. ": " .. tostring(result))
    assert(type(result) == "string" and #result > 0, "Empty response at " .. stage)
    return result
end

local function compile(source, name)
    assert(type(loadstring) == "function", "Executor loadstring unavailable")
    local fn, err = loadstring(source, "@" .. name)
    assert(fn, err)
    return fn
end

local ok, err = xpcall(function()
    stage = "WAIT_GAME"
    status("Loader V4 started; waiting for game...")
    local deadline = os.clock() + 60
    while not game:IsLoaded() and os.clock() < deadline do task.wait(0.1) end
    assert(game:IsLoaded(), "Game not loaded after 60s")
    local nonce = HttpService:GenerateGUID(false)
    stage = "COMMIT_LOOKUP"
    status("Checking game " .. tostring(game.PlaceId) .. "...")
    local ref = requestedRef
    local apiOk, head = pcall(function()
        return HttpService:JSONDecode(fetch(API_ROOT .. requestedRef .. "?_=" .. nonce, 4))
    end)
    local sha = apiOk and type(head) == "table" and type(head.object) == "table" and head.object.sha
    if type(sha) == "string" and #sha == 40 and sha:match("^%x+$") then
        ref = sha
    else
        status("Commit lookup unavailable; using " .. requestedRef .. " (non-atomic fallback)")
    end
    local function download(path)
        return fetch(ROOT .. ref .. "/" .. path .. "?_=" .. nonce)
    end
    stage = "REGISTRY"
    status("Downloading game registry...")
    local registry = compile(download("GameRegistry.lua"), "GameRegistry.lua")()
    assert(type(registry) == "table", "Invalid game registry")
    local entry = registry[game.PlaceId]
    if not entry then
        status("Unsupported game (PlaceId " .. tostring(game.PlaceId) .. ")", true)
        return
    end
    assert(type(entry) == "table" and type(entry.script) == "string", "Invalid registry entry")
    assert(entry.script:match("^Games/[%w_%-/]+%.lua$")
        and not entry.script:find("..", 1, true), "Unsafe script path")
    stage = "SCRIPT_DOWNLOAD"
    status("Downloading " .. entry.script .. "...")
    local source = download(entry.script)
    if entry.revisionPattern then
        local rev = tonumber(source:match(entry.revisionPattern))
        assert(rev and rev >= (entry.minRevision or 0), "Script revision check failed")
    end
    stage = "SCRIPT_COMPILE"
    local run = compile(source, entry.script)
    status("Starting " .. tostring(entry.name or game.PlaceId) .. "...")
    stage = "SCRIPT_START"
    local runFinished = false
    task.delay(30, function()
        if not runFinished and stage == "SCRIPT_START" and gui and gui.Parent then
            status("Still waiting for game script UI. COPY LOADER REPORT if this persists.")
        end
    end)
    run()
    runFinished = true
    stage = "UI_VERIFY"
    if entry.uiName then
        assert(type(entry.uiName) == "string" and #entry.uiName > 0, "Invalid UI verification name")
        assert(playerGui, "Cannot verify UI: PlayerGui unavailable")
        local mainUI = playerGui:FindFirstChild(entry.uiName)
        assert(mainUI, "Game script returned but expected UI is missing: " .. entry.uiName)
        assert(mainUI:GetAttribute("StartupReady") ~= false,
            "Game script UI was created but startup failed. Read the STARTUP ERROR panel.")
    end
    stage = "READY"
    status("Started " .. tostring(entry.name or game.PlaceId) .. " · " .. ref:sub(1, 7))
    if gui then
        local completed = gui
        task.delay(8, function()
            if completed and completed.Parent then completed:Destroy() end
        end)
    end
end, function(message)
    if type(debug)=="table" and type(debug.traceback)=="function" then return debug.traceback(tostring(message),2) end
    return tostring(message)
end)
if not ok then
    stage = "FAILED:" .. stage
    status("FAILED: " .. err, true)
end
