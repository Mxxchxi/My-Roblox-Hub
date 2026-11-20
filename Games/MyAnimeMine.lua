-- My Roblox Hub | My Anime Mine v0.1 (discovery + conservative automation)
-- PlaceId: 79389059854988
-- This module does not guess or fire undocumented server remotes.
-- Auto Mine uses nearby rock ClickDetectors where provided by the game.
-- Auto Collect uses nearby chest/ore ProximityPrompts where provided by the game.
-- Both are OFF by default; no purchases, selling, or teleporting are performed.

if game.PlaceId ~= 79389059854988 then
    warn("[My Anime Mine] Wrong PlaceId: " .. tostring(game.PlaceId))
    return
end
if not game:IsLoaded() then game.Loaded:Wait() end

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local player = Players.LocalPlayer
assert(player, "LocalPlayer unavailable")
local playerGui = assert(player:WaitForChild("PlayerGui", 15), "PlayerGui unavailable")

local environment = _G
if type(getgenv) == "function" then
    local ok, env = pcall(getgenv)
    if ok and type(env) == "table" then environment = env end
end

local previous = environment.MyAnimeMineHubController
if type(previous) == "table" and type(previous.Stop) == "function" then
    pcall(function() previous:Stop() end)
end
local staleGui = playerGui:FindFirstChild("MyAnimeMineHub")
if staleGui then staleGui:Destroy() end

local controller = {
    running = true,
    mine = false,
    collect = false,
    mineActions = 0,
    collectActions = 0,
    detectors = {},
    prompts = {},
    logs = {},
    connections = {},
}
environment.MyAnimeMineHubController = controller

local function connect(signal, callback)
    local connection = signal:Connect(callback)
    table.insert(controller.connections, connection)
    return connection
end

local function writeLog(message)
    local line = os.date("%H:%M:%S") .. " | " .. tostring(message)
    table.insert(controller.logs, line)
    if #controller.logs > 180 then table.remove(controller.logs, 1) end
    print("[My Anime Mine] " .. line)
    if controller.logLabel and controller.running then
        local last = {}
        for i = math.max(1, #controller.logs - 6), #controller.logs do
            last[#last + 1] = controller.logs[i]
        end
        controller.logLabel.Text = table.concat(last, "\n")
    end
end

function controller:Stop()
    if not self.running then return end
    self.running = false
    self.mine = false
    self.collect = false
    for _, connection in ipairs(self.connections) do
        pcall(function() connection:Disconnect() end)
    end
    self.connections = {}
    if self.gui then pcall(function() self.gui:Destroy() end) end
    if environment.MyAnimeMineHubController == self then
        environment.MyAnimeMineHubController = nil
    end
end

local function make(className, parent, properties)
    local object = Instance.new(className)
    for key, value in pairs(properties) do object[key] = value end
    object.Parent = parent
    return object
end
local palette = {
    background = Color3.fromRGB(15, 20, 32),
    panel = Color3.fromRGB(25, 33, 50),
    button = Color3.fromRGB(45, 59, 85),
    accent = Color3.fromRGB(61, 188, 164),
    text = Color3.fromRGB(240, 244, 255),
    subtle = Color3.fromRGB(176, 193, 215),
}
local gui = make("ScreenGui", playerGui, {
    Name = "MyAnimeMineHub",
    ResetOnSpawn = false,
    DisplayOrder = 1000,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
})
controller.gui = gui
local panel = make("Frame", gui, {
    Name = "Main", Size = UDim2.fromOffset(510, 378),
    Position = UDim2.new(0.5, -255, 0.5, -189),
    BackgroundColor3 = palette.background, BorderSizePixel = 0,
})
make("UICorner", panel, { CornerRadius = UDim.new(0, 12) })
local header = make("Frame", panel, {
    Name = "DragHandle", Size = UDim2.new(1, 0, 0, 51),
    BackgroundColor3 = palette.panel, BorderSizePixel = 0, Active = true,
})
make("UICorner", header, { CornerRadius = UDim.new(0, 12) })
make("TextLabel", header, {
    Name = "Title", BackgroundTransparency = 1,
    Position = UDim2.fromOffset(16, 5), Size = UDim2.fromOffset(410, 40),
    Font = Enum.Font.GothamBold, TextSize = 17, TextXAlignment = Enum.TextXAlignment.Left,
    TextColor3 = palette.text, Text = "MY ROBLOX HUB  |  My Anime Mine",
})
local function button(name, text, x, y, width, height)
    local b = make("TextButton", panel, {
        Name = name, Text = text,
        Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(width, height),
        BackgroundColor3 = palette.button, TextColor3 = palette.text,
        Font = Enum.Font.GothamSemibold, TextSize = 13,
        AutoButtonColor = true, BorderSizePixel = 0,
    })
    make("UICorner", b, { CornerRadius = UDim.new(0, 7) })
    return b
end
local close = make("TextButton", header, {
    Name = "Close", Position = UDim2.new(1, -46, 0, 9),
    Size = UDim2.fromOffset(34, 32), Text = "X",
    Font = Enum.Font.GothamBold, TextSize = 15,
    BackgroundColor3 = Color3.fromRGB(119, 45, 65),
    TextColor3 = palette.text, BorderSizePixel = 0,
})
make("UICorner", close, { CornerRadius = UDim.new(0, 7) })
connect(close.Activated, function() controller:Stop() end)

make("TextLabel", panel, {
    Name = "Description", Position = UDim2.fromOffset(16, 61),
    Size = UDim2.fromOffset(480, 34),
    BackgroundTransparency = 1, Font = Enum.Font.Gotham, TextSize = 12,
    TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left,
    TextColor3 = palette.subtle,
    Text = "V0.1 | Nearby interactables only. Toggle features ON to try them. No sell or purchase actions.",
})
local mineButton = button("AutoMine", "AUTO MINE: OFF", 16, 104, 230, 41)
local collectButton = button("AutoCollect", "AUTO COLLECT: OFF", 264, 104, 230, 41)
local scanButton = button("Scan", "SCAN GAME", 16, 156, 230, 38)
local copyButton = button("CopyLog", "COPY LOG", 264, 156, 230, 38)
local statusLabel = make("TextLabel", panel, {
    Name = "Status", Position = UDim2.fromOffset(17, 204),
    Size = UDim2.fromOffset(478, 43),
    BackgroundTransparency = 1, Font = Enum.Font.Code, TextSize = 12,
    TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left,
    TextColor3 = palette.accent, Text = "Discovering...",
})
make("TextLabel", panel, {
    Name = "LogTitle", Position = UDim2.fromOffset(16, 251),
    Size = UDim2.fromOffset(478, 20),
    BackgroundTransparency = 1, Font = Enum.Font.GothamBold, TextSize = 13,
    TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = palette.text,
    Text = "LOG / DIAGNOSTICS",
})
local logFrame = make("Frame", panel, {
    Name = "LogPanel", Position = UDim2.fromOffset(16, 274),
    Size = UDim2.fromOffset(478, 87), BackgroundColor3 = palette.panel,
    BorderSizePixel = 0,
})
make("UICorner", logFrame, { CornerRadius = UDim.new(0, 6) })
controller.logLabel = make("TextLabel", logFrame, {
    Name = "Log", Position = UDim2.fromOffset(8, 5),
    Size = UDim2.new(1, -16, 1, -10), BackgroundTransparency = 1,
    Font = Enum.Font.Code, TextSize = 11,
    TextColor3 = palette.subtle, TextWrapped = false,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextYAlignment = Enum.TextYAlignment.Top, Text = "Ready",
})

local dragging, dragOrigin, panelOrigin
connect(header.InputBegan, function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragOrigin = input.Position
        panelOrigin = panel.Position
    end
end)
connect(UserInputService.InputEnded, function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)
connect(UserInputService.InputChanged, function(input)
    if not dragging then return end
    if input.UserInputType ~= Enum.UserInputType.MouseMovement
        and input.UserInputType ~= Enum.UserInputType.Touch then return end
    local delta = input.Position - dragOrigin
    panel.Position = UDim2.new(
        panelOrigin.X.Scale, panelOrigin.X.Offset + delta.X,
        panelOrigin.Y.Scale, panelOrigin.Y.Offset + delta.Y
    )
end)

local function rootPart()
    local character = player.Character
    return character and character:FindFirstChild("HumanoidRootPart")
end
local function relevant(instance, words)
    local cursor = instance
    for _ = 1, 5 do
        if not cursor or cursor == workspace then break end
        local name = cursor.Name:lower()
        for _, word in ipairs(words) do
            if name:find(word, 1, true) then return true end
        end
        cursor = cursor.Parent
    end
    return false
end
local function positionOf(instance)
    local cursor = instance.Parent
    for _ = 1, 5 do
        if not cursor then break end
        if cursor:IsA("BasePart") then return cursor.Position end
        if cursor:IsA("Model") and cursor.PrimaryPart then return cursor.PrimaryPart.Position end
        cursor = cursor.Parent
    end
    return nil
end

local mineWords = { "rock", "ore", "stone", "mine", "mineral", "crystal" }
local collectWords = { "collect", "claim", "chest", "loot", "ore" }

local function scan()
    local detectors, prompts = {}, {}
    local remoteCount, guiButtons, sampleRemotes, sampleButtons = 0, 0, {}, {}
    local successes, err = pcall(function()
        for _, item in ipairs(workspace:GetDescendants()) do
            if item:IsA("ClickDetector") and relevant(item.Parent, mineWords) then
                detectors[#detectors + 1] = item
            elseif item:IsA("ProximityPrompt") and
                (relevant(item.Parent, collectWords) or
                 relevant(item, collectWords) or
                 relevant({Name = item.ActionText, Parent = nil}, collectWords)) then
                prompts[#prompts + 1] = item
            end
        end
        for _, item in ipairs(game:GetService("ReplicatedStorage"):GetDescendants()) do
            if item:IsA("RemoteEvent") or item:IsA("RemoteFunction") then
                remoteCount = remoteCount + 1
                if #sampleRemotes < 12 then sampleRemotes[#sampleRemotes + 1] = item.Name end
            end
        end
        for _, item in ipairs(playerGui:GetDescendants()) do
            if item:IsA("TextButton") and not item:IsDescendantOf(gui) then
                guiButtons = guiButtons + 1
                if #sampleButtons < 12 then
                    sampleButtons[#sampleButtons + 1] = tostring(item.Text):sub(1, 38)
                end
            end
        end
    end)
    if not successes then writeLog("Scan failed: " .. tostring(err)); return end
    controller.detectors, controller.prompts = detectors, prompts
    writeLog("Scan: rock clicks=" .. #detectors .. ", collection prompts=" .. #prompts)
    writeLog("Scan: remotes=" .. remoteCount .. ", other UI buttons=" .. guiButtons)
    if #sampleRemotes > 0 then writeLog("Remote names (read-only): " .. table.concat(sampleRemotes, ", ")) end
    if #sampleButtons > 0 then writeLog("Game buttons: " .. table.concat(sampleButtons, " | ")) end
end

local function nearest(targets, range)
    local root = rootPart()
    if not root then return nil end
    local chosen, distance = nil, range
    for _, item in ipairs(targets) do
        if item.Parent and item:IsDescendantOf(workspace) then
            local point = positionOf(item)
            if point then
                local length = (point - root.Position).Magnitude
                local maxRange = tonumber(item.MaxActivationDistance) or range
                if length < distance and length <= maxRange then
                    chosen, distance = item, length
                end
            end
        end
    end
    return chosen
end

local function refreshStatus()
    if not controller.running then return end
    mineButton.Text = "AUTO MINE: " .. (controller.mine and "ON" or "OFF")
    collectButton.Text = "AUTO COLLECT: " .. (controller.collect and "ON" or "OFF")
    mineButton.BackgroundColor3 = controller.mine and palette.accent or palette.button
    collectButton.BackgroundColor3 = controller.collect and palette.accent or palette.button
    statusLabel.Text = ("Targets: %d rocks / %d collect | actions: mine %d, collect %d\nExecutor: click %s / prompt %s"):format(
        #controller.detectors, #controller.prompts, controller.mineActions,
        controller.collectActions,
        type(fireclickdetector) == "function" and "YES" or "NO",
        type(fireproximityprompt) == "function" and "YES" or "NO"
    )
end
connect(mineButton.Activated, function()
    if type(fireclickdetector) ~= "function" then
        writeLog("Auto Mine unavailable: executor has no fireclickdetector")
        return
    end
    controller.mine = not controller.mine
    writeLog("Auto Mine " .. (controller.mine and "ON" or "OFF"))
    refreshStatus()
end)
connect(collectButton.Activated, function()
    if type(fireproximityprompt) ~= "function" then
        writeLog("Auto Collect unavailable: executor has no fireproximityprompt")
        return
    end
    controller.collect = not controller.collect
    writeLog("Auto Collect " .. (controller.collect and "ON" or "OFF"))
    refreshStatus()
end)
connect(scanButton.Activated, function()
    writeLog("Manual scan requested")
    scan()
    refreshStatus()
end)
connect(copyButton.Activated, function()
    local report = table.concat(controller.logs, "\n")
    if type(setclipboard) == "function" then
        local ok, err = pcall(setclipboard, report)
        writeLog(ok and "Log copied to clipboard" or ("Copy failed: " .. tostring(err)))
    else
        writeLog("setclipboard unavailable; read executor console")
        print(report)
    end
end)

writeLog("My Anime Mine v0.1 started | toggles OFF | PlaceId 79389059854988")
writeLog("No undocumented remotes used. Nearby game interactables only.")
scan()
refreshStatus()

task.spawn(function()
    local lastScan, lastMine, lastCollect, lastStatus = os.clock(), 0, 0, 0
    while controller.running do
        task.wait(0.35)
        local now = os.clock()
        if now - lastScan >= 6 then
            lastScan = now
            scan()
        end
        if controller.mine and now - lastMine >= 0.85 then
            lastMine = now
            local target = nearest(controller.detectors, 70)
            if target and type(fireclickdetector) == "function" then
                local ok, err = pcall(fireclickdetector, target)
                if ok then controller.mineActions = controller.mineActions + 1
                else writeLog("Mine interaction error: " .. tostring(err)) end
            end
        end
        if controller.collect and now - lastCollect >= 2 then
            lastCollect = now
            local target = nearest(controller.prompts, 30)
            if target and type(fireproximityprompt) == "function" then
                local ok, err = pcall(fireproximityprompt, target)
                if ok then controller.collectActions = controller.collectActions + 1
                else writeLog("Collect interaction error: " .. tostring(err)) end
            end
        end
        if now - lastStatus >= 0.75 then
            lastStatus = now
            refreshStatus()
        end
    end
end)
