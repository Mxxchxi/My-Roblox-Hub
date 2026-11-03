-- My Roblox Hub Loader V2: resolve the latest commit, then load an immutable URL.
if not game:IsLoaded() then game.Loaded:Wait() end
if game.PlaceId ~= 115068315659966 then
    warn("[RAS] This loader supports Roll A Stickman (PlaceId 115068315659966)")
    return
end

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local player = Players.LocalPlayer
local pg = player and player:WaitForChild("PlayerGui", 30)
local noticeGui, notice
local function show(message, failed)
    print("[RAS Loader] " .. message)
    if not pg then return end
    if not noticeGui then
        local old = pg:FindFirstChild("RollStickman_LoaderStatus")
        if old then old:Destroy() end
        noticeGui = Instance.new("ScreenGui")
        noticeGui.Name = "RollStickman_LoaderStatus"
        noticeGui.ResetOnSpawn = false
        noticeGui.DisplayOrder = 1001
        notice = Instance.new("TextLabel")
        notice.Position = UDim2.fromOffset(12, 105)
        notice.Size = UDim2.fromOffset(500, 48)
        notice.TextColor3 = Color3.new(1, 1, 1)
        notice.Font = Enum.Font.Code
        notice.TextSize = 13
        notice.TextWrapped = true
        notice.Parent = noticeGui
        noticeGui.Parent = pg
    end
    notice.BackgroundColor3 = failed and Color3.fromRGB(116, 38, 53)
        or Color3.fromRGB(24, 76, 69)
    notice.Text = "RAS LOADER V2 | " .. message
end
local function feedback(message, failed)
    local ok = pcall(show, message, failed)
    if not ok then warn("[RAS Loader] " .. message) end
end

local ok, err = xpcall(function()
    assert(type(loadstring) == "function", "Executor loadstring is unavailable")
    local nonce = HttpService:GenerateGUID(false)
    feedback("Checking latest GitHub commit...", false)
    local apiOk, head = pcall(function()
        local text = game:HttpGet("https://api.github.com/repos/Mxxchxi/My-Roblox-Hub/git/ref/heads/main?_=" .. nonce)
        return HttpService:JSONDecode(text)
    end)
    local ref = apiOk and type(head) == "table" and head.object and head.object.sha
    if not (type(ref) == "string" and #ref == 40 and ref:match("^%x+$")) then
        ref = "main"
        feedback("Commit lookup unavailable; requesting uncached main...", false)
    end
    local url = "https://raw.githubusercontent.com/Mxxchxi/My-Roblox-Hub/"
        .. ref .. "/Games/RollStickman_Combined_V1_2.lua?_=" .. nonce
    local source = game:HttpGet(url)
    assert(type(source) == "string" and #source > 0, "Downloaded script is empty")
    local revision = tonumber(source:match("Combined Auto V1%.2 R(%d+)"))
    assert(revision and revision >= 10, "Outdated or unexpected script received; expected R10 or newer")
    local run, compileError = loadstring(source, "@RollStickman_Combined_V1_2.lua")
    assert(run, compileError)
    feedback("Loading R" .. revision .. " · " .. ref:sub(1, 7), false)
    local previous = pg and pg:FindFirstChild("RollStickman_Combined_V1_2")
    run()
    local main = pg and pg:FindFirstChild("RollStickman_Combined_V1_2")
    local panel = main and main:FindFirstChild("Panel")
    local title = panel and panel:FindFirstChild("Title")
    local actual = title and tonumber(title.Text:match("|%s*R(%d+)"))
    assert(main and main ~= previous and actual == revision,
        "R" .. revision .. " UI did not start; check the red startup error or executor log")
    feedback("R" .. revision .. " started · " .. ref:sub(1, 7), false)
    if noticeGui then
        local completedNotice = noticeGui
        task.delay(8, function() completedNotice:Destroy() end)
    end
end, function(message)
    return tostring(message)
end)
if not ok then
    feedback("FAILED: " .. err, true)
    warn("[RAS Loader] " .. err)
end
