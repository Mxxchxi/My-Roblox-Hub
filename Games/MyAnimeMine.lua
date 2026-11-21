-- My Roblox Hub | My Anime Mine v0.23 (safe native Stats Auto Upgrade)
-- PlaceId: 79389059854988
-- This module does not guess or fire undocumented server remotes.
-- Auto Mine uses nearby rock ClickDetectors where provided by the game.
-- Auto Collect uses only the player's explicitly selected plot, then opens its chest and clicks Take All.
-- Mining in this game is normally performed by placed characters.
-- Auto Collect starts OFF. When enabled it auto-detects a nearby plot and walks to its Chest without teleporting.

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
    cycleEnabled = false,
    cycleMinutes = 5,
    cyclePhase = "OFF",
    cycleRun = 0,
    cycleCollectionBaseline = 0,
    cycleCollectionAt = 0,
    cycleStartedAt = 0,
    cycleNextAt = 0,
    cycleLastReturnAt = 0,
    cycleLastError = "none",
    cycleLastMessage = "",
    sell = false,
    sellStage = "OFF",
    sellPhase = "OFF",
    sellWarpAttempts = 0,
    sellChestHandoffAttempts = 0,
    sellChestHandoffState = "NOT_STARTED",
    sellHandoffNeedsCollect = false,
    sellHandoffBaselineTakeAllActions = 0,
    sellHandoffTakeAllObserved = false,
    sellHandoffRecentTakeAll = false,
    sellHandoffRecentAge = nil,
    sellHandoffChestEmpty = false,
    sellShopsAttempts = 0,
    sellVendorAttempts = 0,
    sellVendorTouched = false,
    sellWalkAttempts = 0,
    sellStartedAt = 0,
    sellPhaseAt = 0,
    sellWarpOrigin = nil,
    sellVendorPath = "none",
    sellVendorDistance = nil,
    sellReturnTarget = "none",
    sellReturnOriginalPlot = nil,
    sellReturnOrigin = nil,
    sellReturnStartDistance = nil,
    sellReturnCurrentDistance = nil,
    sellReturnClicks = 0,
    sellReturnChoiceClicks = 0,
    sellReturnVerified = false,
    sellReturnStatus = "NOT_STARTED",
    sellReturnCloseSent = false,
    sellReturnAt = 0,
    sellMenuButtons = {},
    sellLastMoveAt = 0,
    sellLastProgressAt = 0,
    sellLastDistance = nil,
    sellMoveTarget = nil,
    sellActionTarget = "none",
    sellSelectAllTarget = "none",
    sellSelectAllAttempts = 0,
    sellSelectAllCallsOK = 0,
    sellSelectAllSent = false,
    sellSelectAllAt = 0,
    sellSelectAllEvent = "none",
    sellNoGameUIPurchase = true,
    sellCandidates = {},
    sellLabels = {},
    sellAttempts = 0,
    sellCallsOK = 0,
    sellSent = false,
    sellTarget = "none",
    sellEvent = "none",
    sellInitialState = "UNKNOWN",
    sellLastObservedState = "UNKNOWN",
    sellNextScanAt = 0,
    sellLastStageLog = "",
    equip = false,
    upgrade = false,
    headlessOnly = true,
    headlessEquipStatus = "NOT TESTED",
    headlessUpgradeStatus = "NOT TESTED",
    headlessEquipTarget = "none",
    headlessRemoteTargets = {},
    equipAttempts = 0,
    equipActions = 0,
    inventoryOpenAttempts = 0,
    inventoryLastTarget = "none",
    equipStage = "OFF",
    upgradeAttempts = 0,
    upgradeActions = 0,
    upgradeNoChange = 0,
    upgradeIndex = 1,
    upgradeLastConfirmedUI = "NOT_TESTED",
    upgradeLastTarget = "none",
    upgradeLastStat = "none",
    upgradeLastEvent = "none",
    upgradeSafeCandidates = 0,
    upgradeBlockedReason = "none",
    upgradeStage = "OFF",
    upgradePending = nil,
    holderAttempts = 0,
    holderActions = 0,
    openedHolder = nil,
    openedHolderAt = 0,
    upgradeWalkTarget = nil,
    upgradeWalkProgressAt = 0,
    upgradeWalkLastDistance = nil,
    upgradeWalkAttempts = 0,
    upgradeWalkLastCommand = 0,
    upgradeWalkLastTarget = "none",
    lastHolderProbe = "none",
    lastHolderProbeInRange = "none",
    holderIndex = 1,
    holderNextAt = 0,
    statsTabAttempted = false,
    equipCandidates = {},
    inventoryCandidates = {},
    guiButtonSamples = {},
    guiHiddenSamples = {},
    guiUpgradeMenu = {},
    upgradeCandidates = {},
    statsCandidates = {},
    minimized = false,
    walkToChest = false,
    selectedPlot = nil,
    plotSelectionReason = "WAITING",
    collectionStage = "Detecting nearby plot automatically",
    moveTarget = nil,
    moveStarted = 0,
    movePreviousDistance = nil,
    moveProgressAt = 0,
    moveAttempts = 0,
    mineActions = 0,
    collectActions = 0,
    takeAllActions = 0,
    mineAttempts = 0,
    collectAttempts = 0,
    takeAllAttempts = 0,
    takeAllPending = nil,
    takeAllLastDispatchAt = 0,
    takeAllLastDispatchPlot = nil,
    takeAllNoChange = 0,
    takeAllNotDecreased = 0,
    lastChestCountBefore = nil,
    lastChestCountAfter = nil,
    lastChestCountDelta = nil,
    takeAllOutcome = "NOT TESTED",
    watchManual = false,
    manualClickCount = 0,
    manualPending = nil,
    manualOutcome = "NOT TESTED",
    manualBefore = nil,
    manualAfter = nil,
    manualDelta = nil,
    manualMonitorButton = nil,
    manualMonitorConnection = nil,
    takeAllLastEvent = "none",
    takeAllMethodIndex = 1,
    takeAllNextAt = 0,
    takeAllReopenAt = 0,
    takeAllClosedBeforeCount = nil,
    takeAllReopenStatus = "NOT TESTED",
    takeAllUnverifiedReopens = 0,
    takeAllCooldownSeconds = 12,
    detectors = {},
    prompts = {},
    takeAllButtons = {},
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
    self.sell = false
    if self.sellMoveTarget then
        local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
        local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        if humanoid and root then pcall(function() humanoid:MoveTo(root.Position) end) end
        self.sellMoveTarget = nil
    end
    self.equip = false
    self.upgrade = false
    self.walkToChest = false
    if self.upgradeWalkTarget then
        local char = player.Character
        local humanoid = char and char:FindFirstChildOfClass("Humanoid")
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if humanoid and root then pcall(function() humanoid:MoveTo(root.Position) end) end
        self.upgradeWalkTarget = nil
    end
    self.watchManual = false
    self.manualPending = nil
    if self.manualMonitorConnection then
        pcall(function() self.manualMonitorConnection:Disconnect() end)
        self.manualMonitorConnection = nil
    end
    if self.moveTarget then
        local character = player.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        local root = character and character:FindFirstChild("HumanoidRootPart")
        if humanoid and root then pcall(function() humanoid:MoveTo(root.Position) end) end
        self.moveTarget = nil
    end
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
    Name = "Main", Size = UDim2.fromOffset(510, 712),
    Position = UDim2.new(0.5, -255, 0.5, -356),
    BackgroundColor3 = palette.background, BorderSizePixel = 0,
})
make("UICorner", panel, { CornerRadius = UDim.new(0, 12) })

-- Keep the restore control outside Main so it remains usable while Main is hidden.
local restoreButton = make("TextButton", gui, {
    Name = "RestoreWindow",
    Position = UDim2.fromOffset(12, 110),
    Size = UDim2.fromOffset(168, 39),
    BackgroundColor3 = palette.panel,
    BorderSizePixel = 0,
    TextColor3 = palette.text,
    Font = Enum.Font.GothamBold,
    TextSize = 12,
    Text = "MY ANIME MINE  [+]",
    Visible = false,
    AutoButtonColor = true,
})
make("UICorner", restoreButton, { CornerRadius = UDim.new(0, 8) })

local function setMinimized(minimized)
    if not controller.running then return end
    controller.minimized = minimized
    panel.Visible = not minimized
    restoreButton.Visible = minimized
end

connect(restoreButton.Activated, function()
    setMinimized(false)
end)
connect(UserInputService.InputBegan, function(input, gameProcessed)
    if gameProcessed or input.KeyCode ~= Enum.KeyCode.LeftAlt then return end
    -- Avoid toggling the window when the user is editing a TextBox.
    if type(UserInputService.GetFocusedTextBox) == "function"
        and UserInputService:GetFocusedTextBox() then return end
    setMinimized(not controller.minimized)
end)
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
    Name = "Description", Position = UDim2.fromOffset(16, 58),
    Size = UDim2.fromOffset(478, 36),
    BackgroundTransparency = 1, Font = Enum.Font.Gotham, TextSize = 12,
    TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left,
    TextColor3 = palette.subtle,
    Text = "V0.23 | Timed farm + safe Stats upgrades (normal game currency only).",
})
local farmCycleButton = button("FarmCycle", "AUTO FARM CYCLE: OFF", 16, 103, 478, 43)
farmCycleButton.TextSize = 14
make("TextLabel", panel, {
    Name = "IntervalTitle", Position = UDim2.fromOffset(16, 152),
    Size = UDim2.fromOffset(478, 23), BackgroundTransparency = 1,
    Font = Enum.Font.GothamSemibold, TextSize = 12,
    TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = palette.subtle,
    Text = "COLLECT EVERY (MINUTES)  |  1-180",
})
local minuteMinusButton = button("MinuteMinus", "- 1", 16, 178, 65, 38)
local intervalInput = make("TextBox", panel, {
    Name = "IntervalMinutes", Position = UDim2.fromOffset(89, 178),
    Size = UDim2.fromOffset(330, 38), BackgroundColor3 = palette.panel,
    BorderSizePixel = 0, Text = "5", ClearTextOnFocus = false,
    Font = Enum.Font.GothamBold, TextSize = 17, TextColor3 = palette.text,
    PlaceholderText = "Minutes (1-180)",
})
make("UICorner", intervalInput, { CornerRadius = UDim.new(0, 7) })
local minutePlusButton = button("MinutePlus", "+ 1", 427, 178, 67, 38)
local mineButton = button("AutoMine", "AUTO MINE (CLICK): OFF", 16, 230, 230, 40)
local equipButton = button("AutoEquip", "AUTO EQUIP BEST: OFF", 264, 230, 230, 40)
local upgradeButton = button("AutoUpgrade", "AUTO UPGRADE STATS: OFF", 16, 280, 478, 40)
local copyButton = button("CopyLog", "COPY LOG", 16, 331, 230, 39)
local sellDiagnosticsButton = button("SellDiagnostics", "COPY SELL ROUTE", 264, 331, 230, 39)
local actionDiagnosticsButton = button("ActionDiagnostics", "COPY UPGRADE DIAGNOSTICS", 16, 379, 478, 39)
local autoPlotLabel = make("TextLabel", panel, {
    Name = "AutoPlotStatus", Position = UDim2.fromOffset(16, 429),
    Size = UDim2.fromOffset(478, 41), BackgroundColor3 = palette.panel,
    BorderSizePixel = 0, Font = Enum.Font.GothamSemibold, TextSize = 12,
    TextXAlignment = Enum.TextXAlignment.Center, TextColor3 = palette.subtle,
    Text = "PLOT: AUTO DETECT  |  COLLECT TIMER: OFF",
})
make("UICorner", autoPlotLabel, { CornerRadius = UDim.new(0, 7) })
local statusLabel = make("TextLabel", panel, {
    Name = "Status", Position = UDim2.fromOffset(17, 477),
    Size = UDim2.fromOffset(478, 75),
    BackgroundTransparency = 1, Font = Enum.Font.Code, TextSize = 12,
    TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left,
    TextColor3 = palette.accent, Text = "Discovering...",
})
make("TextLabel", panel, {
    Name = "LogTitle", Position = UDim2.fromOffset(16, 563),
    Size = UDim2.fromOffset(478, 20),
    BackgroundTransparency = 1, Font = Enum.Font.GothamBold, TextSize = 13,
    TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = palette.text,
    Text = "ACTIVITY / LOG",
})
local logFrame = make("Frame", panel, {
    Name = "LogPanel", Position = UDim2.fromOffset(16, 587),
    Size = UDim2.fromOffset(478, 111), BackgroundColor3 = palette.panel,
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
-- Keep only backwards-compatible diagnostic/test controls hidden.
local legacyPanel = make("Frame", panel, {
    Name = "LegacyHiddenControls", Visible = false,
    BackgroundTransparency = 1, Size = UDim2.fromOffset(1,1),
})
local collectButton = button("AutoCollect", "AUTO COLLECT: OFF", 0, 0, 1, 1)
local sellButton = button("AutoSell", "AUTO SELL ORES: OFF", 0, 0, 1, 1)
local scanButton = button("Scan", "SCAN GAME", 0, 0, 1, 1)
local detailButton = button("Diagnostics", "COPY TARGET DIAGNOSTICS", 0, 0, 1, 1)
local manualWatchButton = button("ManualWatch", "WATCH MANUAL TAKE ALL: OFF", 0, 0, 1, 1)
for _,legacy in ipairs({collectButton,sellButton,scanButton,detailButton,
    manualWatchButton}) do legacy.Parent=legacyPanel end

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
local collectWords = { "collect", "claim", "chest", "loot" }

local function describe(item)
    local pieces = {}
    local cursor = item
    for _ = 1, 6 do
        if not cursor then break end
        table.insert(pieces, 1, tostring(cursor.Name))
        cursor = cursor.Parent
    end
    return table.concat(pieces, "/")
end

local function labelOf(button)
    local parts = { tostring(button.Name), tostring(button.Text or "") }
    if not button.Text or button.Text == "" then
        local count = 0
        for _, child in ipairs(button:GetDescendants()) do
            count = count + 1
            if child:IsA("TextLabel") then
                table.insert(parts, tostring(child.Text or ""))
            end
            table.insert(parts, tostring(child.Name))
            if count >= 16 then break end
        end
    end
    return table.concat(parts, " ")
end

local function isTakeAll(button)
    local normalized = labelOf(button):lower():gsub("[^%w]", "")
    return normalized:find("takeall", 1, true) ~= nil
        or normalized:find("claimall", 1, true) ~= nil
        or normalized:find("collectall", 1, true) ~= nil
end

local function isVisible(button)
    local cursor = button
    while cursor and cursor ~= playerGui do
        if cursor:IsA("GuiObject") and cursor.Visible == false then return false end
        if cursor:IsA("ScreenGui") and cursor.Enabled == false then return false end
        cursor = cursor.Parent
    end
    return cursor == playerGui
end

local function scan(verbose)
    local detectors, prompts, takeAllButtons = {}, {}, {}
    local remoteCount, guiButtons, sampleRemotes, sampleButtons = 0, 0, {}, {}
    local successes, err = pcall(function()
        for _, item in ipairs(workspace:GetDescendants()) do
            if item:IsA("ClickDetector") and relevant(item.Parent, mineWords) then
                detectors[#detectors + 1] = item
            elseif item:IsA("ProximityPrompt") and
                (relevant(item.Parent, collectWords) or
                 relevant(item, collectWords) or
                 relevant({Name = tostring(item.ActionText), Parent = nil}, collectWords)) then
                prompts[#prompts + 1] = item
            end
        end
        for _, item in ipairs(game:GetService("ReplicatedStorage"):GetDescendants()) do
            if item:IsA("RemoteEvent") or item:IsA("RemoteFunction") then
                remoteCount = remoteCount + 1
                if #sampleRemotes < 15 then sampleRemotes[#sampleRemotes + 1] = item.Name end
            end
        end
        for _, item in ipairs(playerGui:GetDescendants()) do
            if item:IsA("TextButton") and not item:IsDescendantOf(gui) then
                guiButtons = guiButtons + 1
                if isTakeAll(item) then
                    table.insert(takeAllButtons, item)
                end
                if #sampleButtons < 12 then
                    local text = tostring(item.Text or "")
                    if text ~= "" and #text <= 50 then
                        sampleButtons[#sampleButtons + 1] = text
                    end
                end
            end
        end
    end)
    if not successes then writeLog("Scan failed: " .. tostring(err)); return end
    local previous = controller.lastCounts
    local changed = not previous or previous.clicks ~= #detectors
        or previous.prompts ~= #prompts
        or previous.takeAll ~= #takeAllButtons
    controller.detectors, controller.prompts, controller.takeAllButtons =
        detectors, prompts, takeAllButtons
    controller.lastCounts = {clicks = #detectors, prompts = #prompts, takeAll = #takeAllButtons}
    if changed or verbose then
        writeLog(("Scan: rock clicks=%d, collection prompts=%d, Take All buttons=%d"):format(
            #detectors, #prompts, #takeAllButtons))
    end
    if verbose then
        writeLog(("Scan: remotes=%d, other UI buttons=%d"):format(remoteCount, guiButtons))
        if #sampleRemotes > 0 then writeLog("Remotes (read-only): " .. table.concat(sampleRemotes, ", ")) end
        if #sampleButtons > 0 then writeLog("Visible text samples: " .. table.concat(sampleButtons, " | ")) end
        for i = 1, math.min(5, #prompts) do
            local prompt = prompts[i]
            writeLog("Prompt[" .. i .. "]: " .. describe(prompt) .. " | action=" ..
                tostring(prompt.ActionText) .. " | object=" .. tostring(prompt.ObjectText))
        end
        for i = 1, math.min(5, #takeAllButtons) do
            local b = takeAllButtons[i]
            writeLog("TakeAll[" .. i .. "]: " .. describe(b) .. " | visible=" ..
                tostring(isVisible(b)) .. " | label=" .. labelOf(b):sub(1, 100))
        end
    end
end

local function nearest(targets, range)
    local root = rootPart()
    if not root then return nil, nil, "Character/HumanoidRootPart missing" end
    local chosen, distance, valid = nil, range, 0
    for _, item in ipairs(targets) do
        if item.Parent and item:IsDescendantOf(workspace) then
            local point = positionOf(item)
            if point then
                valid = valid + 1
                local length = (point - root.Position).Magnitude
                local maxRange = tonumber(item.MaxActivationDistance) or range
                if length < distance and length <= maxRange then
                    chosen, distance = item, length
                end
            end
        end
    end
    if not chosen then
        return nil, nil, valid == 0 and "No positioned targets" or "Targets out of interaction range"
    end
    return chosen, distance, nil
end

local function findTakeAll()
    for _, b in ipairs(controller.takeAllButtons) do
        if b.Parent and isVisible(b) then return b end
    end
    return nil
end


-- A plot is chosen explicitly by standing near its own upgrade marker.
-- This avoids attempting to open other players' chests by accident.
local function minePlotName(instance)
    local cursor = instance
    for _ = 1, 10 do
        if not cursor then break end
        if tostring(cursor.Name):match("^MinePlot%d+$") then
            return tostring(cursor.Name)
        end
        cursor = cursor.Parent
    end
    return nil
end

-- Closest *upgrade marker* plus a matching Chest near the character.
-- There is no confirmed ownership API. Never choose a distant or ambiguous plot.
local function choosePlotNearPlayer()
    local root = rootPart()
    if not root then return nil, nil, "Character/HumanoidRootPart missing" end
    local distances = {}
    for _, detector in ipairs(controller.detectors) do
        if detector.Parent and detector.Name:lower():find("upgrade", 1, true) then
            local plot = minePlotName(detector)
            local pos = positionOf(detector)
            if plot and pos then
                local d = (pos - root.Position).Magnitude
                if d <= 65 and (not distances[plot] or d < distances[plot]) then
                    distances[plot] = d
                end
            end
        end
    end

    local candidate, best, second = nil, math.huge, math.huge
    for plot, markerDistance in pairs(distances) do
        local chestDistance = math.huge
        for _, prompt in ipairs(controller.prompts) do
            if prompt.Parent and minePlotName(prompt) == plot
                and prompt.Name == "ChestPrompt" then
                local pos = positionOf(prompt)
                if pos then
                    local d = (pos - root.Position).Magnitude
                    if d < chestDistance then chestDistance = d end
                end
            end
        end
        if chestDistance <= 75 then
            -- Prefer the plot whose Chest is nearest, then its upgrade marker.
            local score = chestDistance + markerDistance * 0.1
            if score < best then
                second = best
                candidate, best = plot, score
            elseif score < second then
                second = score
            end
        end
    end
    if not candidate then
        return nil, nil, "No nearby plot with both UpgradeClick and ChestPrompt"
    end
    if second - best < 8 then
        return nil, nil, "Ambiguous nearby plots; stand closer to your own Chest"
    end
    return candidate, distances[candidate],
        "Proximity only; plot ownership NOT verified"
end

local function autoSelectPlot()
    if controller.selectedPlot then return true end
    local plot, distance, detail = choosePlotNearPlayer()
    if not plot then
        controller.plotSelectionReason = detail
        controller.collectionStage = "Auto Plot: " .. tostring(detail)
        return false
    end
    controller.selectedPlot = plot
    controller.plotSelectionReason = "Nearby Chest and upgrade marker; ownership NOT verified"
    controller.collectionStage = "Auto Plot: " .. plot
    writeLog(("AUTO PLOT selected %s | upgrade marker %.1f studs | ownership NOT verified"):format(
        plot, distance))
    return true
end
local function selectedChest()
    if not controller.selectedPlot then return nil, nil, "Plot not selected" end
    local root = rootPart()
    if not root then return nil, nil, "Character/HumanoidRootPart missing" end
    local closest, closestDistance = nil, math.huge
    for _, prompt in ipairs(controller.prompts) do
        if prompt.Parent and prompt:IsDescendantOf(workspace)
            and minePlotName(prompt) == controller.selectedPlot
            and (prompt.Name == "ChestPrompt" or
                 tostring(prompt.ActionText):lower() == "open") then
            local pos = positionOf(prompt)
            if pos then
                local d = (pos - root.Position).Magnitude
                if d < closestDistance then
                    closest, closestDistance = prompt, d
                end
            end
        end
    end
    if not closest then
        return nil, nil, "ChestPrompt not found for " .. controller.selectedPlot
    end
    return closest, closestDistance, nil
end

local function chestRange(prompt)
    return math.max(1, tonumber(prompt.MaxActivationDistance) or 10)
end

local function stopWalking()
    if not controller.moveTarget then return end
    controller.moveTarget = nil
    controller.movePreviousDistance = nil
    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    local root = rootPart()
    if humanoid and root then pcall(function() humanoid:MoveTo(root.Position) end) end
end

-- Bounded, natural MoveTo. No teleport and no cross-plot routing.
-- Stop when blocked rather than repeatedly trying to walk forever.
local function approachChest(prompt, distance, now)
    if not controller.walkToChest then return "Walk is OFF" end
    if distance > 145 then return ("Chest %.1f studs away; limit 145"):format(distance) end
    if not prompt.Enabled then return "ChestPrompt disabled" end
    local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
    local pos = positionOf(prompt)
    if not humanoid or not pos or humanoid.Health <= 0 then
        return "Humanoid or chest position unavailable"
    end
    if controller.moveTarget ~= prompt then
        stopWalking()
        controller.moveTarget = prompt
        controller.moveStarted = now
        controller.moveProgressAt = now
        controller.movePreviousDistance = distance
    end
    if distance + 1 < (controller.movePreviousDistance or math.huge) then
        controller.movePreviousDistance = distance
        controller.moveProgressAt = now
    end
    if now - controller.moveProgressAt > 11 then
        stopWalking()
        controller.walkToChest = false
        controller.collect = false
        return "WALK BLOCKED after 11s. Auto Collect OFF; move closer before retry."
    end
    if now - (controller.lastMoveCommand or 0) >= 1.8 then
        controller.lastMoveCommand = now
        controller.moveAttempts = controller.moveAttempts + 1
        local ok, err = pcall(function() humanoid:MoveTo(pos) end)
        if not ok then
            stopWalking()
            controller.walkToChest = false
            controller.collect = false
            return "MoveTo failed; Auto Collect OFF: " .. tostring(err)
        end
    end
    return ("Walking to %s Chest %.1f studs (range %.1f)"):format(
        controller.selectedPlot, distance, chestRange(prompt))
end


-- UI-only evidence. These labels may change for reasons other than item collection.
local function chestSnapshot(button)
    local root = button
    while root and root ~= playerGui and root.Name ~= "ChestFrame" do
        root = root.Parent
    end
    if not root or root == playerGui then return "CHEST_FRAME_MISSING" end
    local fields = {}
    for _, node in ipairs(root:GetDescendants()) do
        if node:IsA("TextLabel") or node:IsA("TextButton") then
            local value = tostring(node.Text or ""):gsub("%s+", " "):sub(1, 65)
            if value ~= "" then
                fields[#fields + 1] = tostring(node.Name) .. "=" .. value
            end
            if #fields >= 55 then break end
        end
    end
    return table.concat(fields, " | ")
end

-- Extract the left-hand item count from the Chest label, e.g. "15/183.9K Items".
-- This is a UI metric, NOT the player's inventory or confirmed reward.
local function chestItemCount(button)
    local root = button
    while root and root ~= playerGui and root.Name ~= "ChestFrame" do
        root = root.Parent
    end
    if not root or root == playerGui then return nil end
    for _, node in ipairs(root:GetDescendants()) do
        if node:IsA("TextLabel") or node:IsA("TextButton") then
            local text = tostring(node.Text or "")
            if text:lower():find("items", 1, true) then
                local count = text:match("^%s*([%d,]+)%s*/")
                if count then
                    local cleaned = count:gsub(",", "")
                    local parsed = tonumber(cleaned)
                    if parsed then return parsed end
                end
            end
        end
    end
    return nil
end

local function takeAllConnections(button)
    local counts = { Activated = "?", MouseButton1Click = "?" }
    if type(getconnections) ~= "function" then return counts end
    for _, name in ipairs({ "Activated", "MouseButton1Click" }) do
        local ok, connections = pcall(getconnections, button[name])
        if ok and type(connections) == "table" then
            local live = 0
            for _, conn in ipairs(connections) do
                if conn.Enabled ~= false then live = live + 1 end
            end
            counts[name] = live
        end
    end
    return counts
end

local function chooseTakeAllEvent(button)
    local counts = takeAllConnections(button)
    if type(counts.Activated) == "number" and type(counts.MouseButton1Click) == "number" then
        if counts.MouseButton1Click > counts.Activated then
            return "MouseButton1Click", counts
        elseif counts.Activated > counts.MouseButton1Click then
            return "Activated", counts
        end
    elseif type(counts.MouseButton1Click) == "number" and counts.MouseButton1Click > 0 then
        return "MouseButton1Click", counts
    elseif type(counts.Activated) == "number" and counts.Activated > 0 then
        return "Activated", counts
    end
    -- Without readable connection information, alternate safely after inconclusive calls.
    return controller.takeAllMethodIndex == 1 and "Activated" or "MouseButton1Click", counts
end

-- A hidden ChestFrame retains old TextLabels in Roblox; never treat their stale
-- values as a live count. No inventory outcome is inferred from a closing UI.
local function settleTakeAll(now)
    local pending = controller.takeAllPending
    if not pending or now - pending.sentAt < 2.5 then return end
    controller.takeAllPending = nil

    local visible = pending.button.Parent and isVisible(pending.button)
    local beforeCount = pending.beforeCount
    local afterCount = visible and chestItemCount(pending.button) or nil
    local afterSnapshot = visible and chestSnapshot(pending.button) or nil
    controller.lastChestCountBefore = beforeCount
    controller.lastChestCountAfter = afterCount
    controller.lastChestCountDelta = nil
    local decreased = false
    local closed = not visible

    if closed then
        controller.takeAllOutcome = "CHEST_CLOSED_AFTER_TAKE_ALL (matches manual UI; inventory unknown)"
        controller.takeAllClosedBeforeCount = beforeCount
        controller.takeAllReopenAt = now + controller.takeAllCooldownSeconds
        controller.takeAllReopenStatus = "WAITING_FOR_REOPEN"
        controller.collectionStage = "Chest closed; cooldown before reopening"
    elseif beforeCount ~= nil and afterCount ~= nil then
        local delta = afterCount - beforeCount
        controller.lastChestCountDelta = delta
        if delta < 0 then
            decreased = true
            controller.takeAllOutcome = "CHEST_COUNT_DECREASED (possible collection, NOT inventory proof)"
        elseif delta > 0 then
            controller.takeAllOutcome = "CHEST_COUNT_INCREASED (possible mining/refill)"
        else
            controller.takeAllOutcome = "CHEST_COUNT_UNCHANGED"
        end
    elseif afterSnapshot ~= pending.before then
        controller.takeAllOutcome = "CHEST_UI_CHANGED (item count unavailable)"
    else
        controller.takeAllOutcome = "NO_CHEST_UI_CHANGE (item count unavailable)"
    end

    if decreased then
        controller.takeAllNotDecreased = 0
        controller.takeAllNoChange = 0
    elseif not closed then
        controller.takeAllNotDecreased = controller.takeAllNotDecreased + 1
        if not closed and afterSnapshot == pending.before then
            controller.takeAllNoChange = controller.takeAllNoChange + 1
        else
            controller.takeAllNoChange = 0
        end
        if type(getconnections) ~= "function" then
            controller.takeAllMethodIndex = controller.takeAllMethodIndex == 1 and 2 or 1
        end
    end

    writeLog("Take All feedback: " .. controller.takeAllOutcome ..
        " | chest count " .. tostring(beforeCount) .. " -> " .. tostring(afterCount) ..
        " | event=" .. pending.event ..
        " | without-count-decrease=" .. controller.takeAllNotDecreased)
    if controller.collect and (controller.takeAllNotDecreased >= 3
        or controller.takeAllAttempts >= 6) then
        controller.collect = false
        stopWalking()
        controller.collectionStage = "PAUSED: Insufficient Chest evidence or max dispatches. Check inventory."
        writeLog("Auto Collect PAUSED after bounded Take All attempts.")
    elseif closed and controller.collect then
        writeLog("Chest closing matches manual Take All. Auto Collect will check the Chest again after cooldown.")
    end
end

-- Check a *freshly reopened* Chest. Unlike the stale hidden UI,
-- this provides a new count that can be compared with the previous session.
local function observeReopenedChest(button)
    if controller.takeAllClosedBeforeCount == nil then return end
    local before = controller.takeAllClosedBeforeCount
    controller.takeAllClosedBeforeCount = nil
    controller.takeAllReopenAt = 0
    local after = chestItemCount(button)
    if after == nil then
        controller.takeAllReopenStatus = "REOPEN_COUNT_UNAVAILABLE"
        controller.takeAllUnverifiedReopens = controller.takeAllUnverifiedReopens + 1
    elseif after < before then
        controller.takeAllReopenStatus = "REOPEN_COUNT_LOWER (possible collection, not inventory proof)"
        controller.takeAllUnverifiedReopens = 0
        controller.takeAllNotDecreased = 0
    else
        controller.takeAllReopenStatus = after == before
            and "REOPEN_COUNT_UNCHANGED" or "REOPEN_COUNT_HIGHER (possible mining)"
        controller.takeAllUnverifiedReopens = controller.takeAllUnverifiedReopens + 1
    end
    controller.lastReopenBefore = before
    controller.lastReopenAfter = after
    writeLog("Chest reopened: " .. controller.takeAllReopenStatus ..
        " | previously " .. tostring(before) .. " now " .. tostring(after) ..
        " | inconclusive=" .. controller.takeAllUnverifiedReopens)
    if controller.collect and controller.takeAllUnverifiedReopens >= 2 then
        controller.collect = false
        stopWalking()
        controller.collectionStage = "PAUSED: Reopened Chest did not show a lower count twice."
        writeLog("Auto Collect PAUSED. Compare actual inventory before continuing.")
    end
end

-- Read-only test: when the player clicks the *game's* Take All button normally,
-- compare UI feedback with the same rules, but do not send a signal or remote.
local function stopManualMonitor()
    if controller.manualMonitorConnection then
        pcall(function() controller.manualMonitorConnection:Disconnect() end)
    end
    controller.manualMonitorConnection = nil
    controller.manualMonitorButton = nil
end

local function monitorManualButton()
    if not controller.watchManual then
        stopManualMonitor()
        return
    end
    local button = findTakeAll()
    if not button then
        stopManualMonitor()
        return
    end
    if controller.manualMonitorButton == button and controller.manualMonitorConnection then
        return
    end
    stopManualMonitor()
    controller.manualMonitorButton = button
    controller.manualMonitorConnection = connect(button.MouseButton1Click, function()
        if not controller.running or not controller.watchManual or controller.collect then return end
        controller.manualClickCount = controller.manualClickCount + 1
        controller.manualPending = {
            button = button,
            sentAt = os.clock(),
            beforeCount = chestItemCount(button),
            before = chestSnapshot(button),
        }
        controller.manualOutcome = "WAITING_FOR_MANUAL_UI_FEEDBACK"
        writeLog("Manual Take All CLICK detected | chest count=" ..
            tostring(controller.manualPending.beforeCount))
    end)
    writeLog("Manual watch armed: click the game's Take All button with your mouse.")
end

local function settleManualTakeAll(now)
    local pending = controller.manualPending
    if not pending or now - pending.sentAt < 2.5 then return end
    controller.manualPending = nil
    local visible = pending.button.Parent and isVisible(pending.button)
    local beforeCount = pending.beforeCount
    local afterCount = visible and chestItemCount(pending.button) or nil
    controller.manualBefore, controller.manualAfter = beforeCount, afterCount
    controller.manualDelta = nil
    if not visible then
        controller.manualOutcome = "MANUAL_CHEST_CLOSED (stale count ignored)"
    elseif beforeCount and afterCount then
        local delta = afterCount - beforeCount
        controller.manualDelta = delta
        if delta < 0 then
            controller.manualOutcome = "MANUAL_CHEST_COUNT_DECREASED"
        elseif delta > 0 then
            controller.manualOutcome = "MANUAL_CHEST_COUNT_INCREASED"
        else
            controller.manualOutcome = "MANUAL_CHEST_COUNT_UNCHANGED"
        end
    elseif chestSnapshot(pending.button) ~= pending.before then
        controller.manualOutcome = "MANUAL_CHEST_UI_CHANGED (count unavailable)"
    else
        controller.manualOutcome = "MANUAL_CHEST_UI_UNCHANGED (count unavailable)"
    end
    writeLog("Manual Take All feedback: " .. controller.manualOutcome ..
        " | chest count " .. tostring(beforeCount) .. " -> " .. tostring(afterCount) ..
        " | delta=" .. tostring(controller.manualDelta) ..
        " | inventory NOT verified")
end


-- GUI-only automation. No undocumented remotes or speculative purchase APIs.
local function gameGuiButton(node)
    return (node:IsA("TextButton") or node:IsA("ImageButton"))
        and not node:IsDescendantOf(gui)
end

local function textOf(node)
    local ok, value = pcall(function() return node.Text end)
    return ok and tostring(value or "") or ""
end

local function normalizeLabel(value)
    return tostring(value or ""):lower():gsub("[^%w]", "")
end

local function actionLabel(button)
    local parts = { tostring(button.Name), textOf(button) }
    local n = 0
    for _, child in ipairs(button:GetDescendants()) do
        n = n + 1
        if child:IsA("TextLabel") or child:IsA("TextButton") then
            parts[#parts + 1] = textOf(child)
        end
        if n >= 24 then break end
    end
    return table.concat(parts, " ")
end

local function statContext(button)
    -- Check the narrowest row first so that one Stats panel with three rows
    -- does not make every upgrade appear to be for Damage.
    local cursor = button
    for _ = 1, 4 do
        if not cursor or cursor == playerGui then break end
        local bits = {tostring(cursor.Name)}
        for _, child in ipairs(cursor:GetChildren()) do
            if child:IsA("TextLabel") then
                bits[#bits + 1] = textOf(child)
            end
        end
        local value = normalizeLabel(table.concat(bits, " "))
        if value:find("miningspeed", 1, true) then return "Mining Speed" end
        if value:find("damage", 1, true) or value:find("dmg", 1, true) then
            return "Damage"
        end
        if value:find("speed", 1, true) then return "Speed" end
        cursor = cursor.Parent
    end
    return nil
end

local function inCrewStats(button)
    local cursor = button
    local hasStats = false
    local excluded = false
    for _ = 1, 7 do
        if not cursor or cursor == playerGui then break end
        local name = normalizeLabel(cursor.Name)
        if name:find("stats", 1, true) or name:find("unitupgrade", 1, true)
            or name:find("characterupgrade", 1, true) or
            name:find("holderupgrade", 1, true) then
            hasStats = true
        end
        if name:find("research", 1, true) or name:find("shop", 1, true)
            or name:find("gamepass", 1, true) or name:find("premium", 1, true)
            or name:find("purchase", 1, true) then
            excluded = true
        end
        cursor = cursor.Parent
    end
    return hasStats and not excluded
end

local function isPremiumAction(button)
    local label = actionLabel(button):lower()
    -- Upgrade prices may be shown in a sibling label rather than on the button.
    local parent = button.Parent
    if parent then
        for _, sibling in ipairs(parent:GetChildren()) do
            if sibling:IsA("TextLabel") then
                label = label .. " " .. textOf(sibling):lower()
            end
        end
    end
    return label:find("robux", 1, true) ~= nil
        or label:find("r$", 1, true) ~= nil
        or label:find("gamepass", 1, true) ~= nil
        or label:find("premium", 1, true) ~= nil
        or label:find("product", 1, true) ~= nil
end

local function isUpgradeAction(button)
    if not inCrewStats(button) or isPremiumAction(button) then return false end
    local stat = statContext(button)
    if not stat then return false end
    local name = normalizeLabel(button.Name)
    local textKey = normalizeLabel(textOf(button))
    if textKey:find("max", 1, true) or textKey:find("locked", 1, true)
        or textKey:find("notenough", 1, true) then return false end
    local action = name:find("upgrade", 1, true) or
        name:find("levelup", 1, true) or name:find("buy", 1, true) or
        textKey:find("upgrade", 1, true) or textKey:find("levelup", 1, true)
    if not action then return false end
    local ok, interactable = pcall(function() return button.Interactable end)
    if ok and interactable == false then return false end
    return true
end

local function isKnownInventoryLauncher(item)
    if item.Name ~= "TextButton" then return false end
    local parent = item.Parent
    if not parent or parent.Name ~= "InventoryButton" then return false end
    local cursor = parent.Parent
    local hasHotbar, hasMineGui = false, false
    for _ = 1, 8 do
        if not cursor or cursor == playerGui then break end
        if cursor.Name == "HotbarFrame" then hasHotbar = true end
        if cursor.Name == "MineGui" then hasMineGui = true end
        cursor = cursor.Parent
    end
    -- Confirm the exact game UI hierarchy found in the V0.10 runtime log.
    return hasHotbar and hasMineGui
end

local function nearbyButtonContext(item)
    local labels = {}
    local cursor = item.Parent
    for i = 1, 3 do
        if not cursor or cursor == playerGui then break end
        labels[#labels + 1] = tostring(cursor.Name)
        -- Keep UI labels next to icon-only buttons discoverable.
        for _, child in ipairs(cursor:GetChildren()) do
            if child:IsA("TextLabel") then
                local t = textOf(child)
                if t ~= "" then labels[#labels + 1] = t:sub(1, 45) end
            end
        end
        cursor = cursor.Parent
    end
    return table.concat(labels, " ")
end

local function scanActionButtons()
    local equip, inventory, upgrades, stats, upgradeMenu = {}, {}, {}, {}, {}
    local visibleSamples, hiddenSamples = {}, {}
    local hiddenOccurrences = {}
    local count = 0
    local ok, err = pcall(function()
        for _, item in ipairs(playerGui:GetDescendants()) do
            if gameGuiButton(item) then
                local visible = isVisible(item)
                local context = nearbyButtonContext(item)
                local label = normalizeLabel(actionLabel(item))
                local named = normalizeLabel(item.Name)
                local buttonText = normalizeLabel(textOf(item))
                local nearby = normalizeLabel(context)
                if visible then
                    count = count + 1
                    if #visibleSamples < 70 then
                        visibleSamples[#visibleSamples + 1] = item
                    end
                    local insideInventory = nearby:find("inventory", 1, true) ~= nil
                    local looksEquip = label:find("equipbest", 1, true)
                        or named:find("bestcrew", 1, true)
                        or (insideInventory and (named == "best" or named == "bestbutton"
                            or buttonText == "best"))
                    local looksInventory = isKnownInventoryLauncher(item)
                        or named == "inventory" or named == "inventorybutton"
                        or named == "openinventory" or named == "inventorytoggle"
                        or named == "inventoryicon" or named == "backpack"
                        or named == "backpackbutton" or named == "itemsbutton"
                        or buttonText == "inventory" or buttonText == "backpack"
                        or (nearby:find("inventory", 1, true)
                            and (nearby:find("toolbar", 1, true)
                                or nearby:find("hotbar", 1, true)
                                or nearby:find("navbar", 1, true))
                            and (named == "button" or named == "icon"))
                    if looksEquip and not isPremiumAction(item) then
                        equip[#equip + 1] = item
                    elseif looksInventory and not isPremiumAction(item) then
                        inventory[#inventory + 1] = item
                    end
                    if isUpgradeAction(item) then upgrades[#upgrades + 1] = item end
                    if named == "upgradesbutton" then
                        upgradeMenu[#upgradeMenu + 1] = item
                    end
                    if named == "stats" or named == "statsbutton"
                        or named == "statstab" or buttonText == "stats" then
                        stats[#stats + 1] = item
                    end
                else
                    if #hiddenSamples < 100 and named ~= "card" then
                        local clue = label .. nearby
                        if clue:find("inventory", 1, true)
                            or clue:find("equip", 1, true)
                            or clue:find("upgrade", 1, true)
                            or clue:find("stats", 1, true)
                            or clue:find("backpack", 1, true) then
                            local signature = describe(item)
                            local occurrences = hiddenOccurrences[signature] or 0
                            if occurrences < 2 then
                                hiddenOccurrences[signature] = occurrences + 1
                                hiddenSamples[#hiddenSamples + 1] = item
                            end
                        end
                    end
                end
            end
        end
    end)
    if not ok then
        writeLog("Equip/Upgrade GUI scan ERROR: " .. tostring(err))
        return
    end
    controller.equipCandidates = equip
    controller.inventoryCandidates = inventory
    controller.guiUpgradeMenu = upgradeMenu
    controller.upgradeCandidates = upgrades
    controller.statsCandidates = stats
    controller.actionGuiCount = count
    controller.guiButtonSamples = visibleSamples
    controller.guiHiddenSamples = hiddenSamples
end

local function firstAvailable(list)
    for _, item in ipairs(list) do
        if item.Parent and isVisible(item) and not isPremiumAction(item) then
            return item
        end
    end
    return nil
end

local function dispatchGameButton(button)
    if type(firesignal) ~= "function" then
        return false, "firesignal unavailable", "none"
    end
    if not button or not button.Parent or not isVisible(button) then
        return false, "GUI button hidden", "none"
    end
    local event, connections = chooseTakeAllEvent(button)
    if connections.Activated == 0 and connections.MouseButton1Click == 0
        or (connections.Activated == "?" and connections.MouseButton1Click == "?") then
        event = "MouseButton1Click"
    end
    local ok, err = pcall(firesignal, button[event])
    return ok, ok and "dispatch only; result unverified" or tostring(err), event
end

local function upgradeRowSnapshot(button)
    local parent = button and button.Parent
    if not parent then return "ROW_GONE" end
    local values = {tostring(parent.Name)}
    for _, child in ipairs(parent:GetDescendants()) do
        if child:IsA("TextLabel") or child:IsA("TextButton") then
            values[#values + 1] = tostring(child.Name) .. "=" .. textOf(child)
        end
        if #values >= 30 then break end
    end
    return table.concat(values, "|"):sub(1, 1200)
end

-- Read holder ClickDetectors directly from the world, not just the rock scan.
-- The game's upgrade detector can be outside its own MaxActivationDistance,
-- in which case report it and approach naturally instead of saying "not found".
local function holderTargets()
    local root = rootPart()
    local items = {}
    if not controller.selectedPlot or not root then return items end
    for _, detector in ipairs(workspace:GetDescendants()) do
        if detector:IsA("ClickDetector") and detector.Name == "UpgradeClick"
            and minePlotName(detector) == controller.selectedPlot then
            local node, isHolder = detector.Parent, false
            for _ = 1, 7 do
                if not node or node == workspace then break end
                if node.Name == "Holders" then isHolder = true; break end
                node = node.Parent
            end
            if isHolder then
                local pos = positionOf(detector)
                if pos then
                    local distance = (pos - root.Position).Magnitude
                    local allowed = tonumber(detector.MaxActivationDistance) or 10
                    items[#items + 1] = {
                        detector = detector, distance = distance,
                        allowed = allowed, inRange = allowed > 0 and distance <= allowed,
                    }
                end
            end
        end
    end
    table.sort(items, function(a, b)
        if a.distance ~= b.distance then return a.distance < b.distance end
        return describe(a.detector) < describe(b.detector)
    end)
    return items
end

local function nextHolderDetector(peek)
    local items = holderTargets()
    local ready = {}
    for _, item in ipairs(items) do
        if item.inRange then ready[#ready + 1] = item end
    end
    if #ready == 0 then return nil, nil, items[1] end
    local index = (controller.holderIndex - 1) % #ready + 1
    if not peek then controller.holderIndex = index + 1 end
    return ready[index].detector, ready[index].distance, items[1]
end

local function stopUpgradeWalking()
    if not controller.upgradeWalkTarget then return end
    controller.upgradeWalkTarget = nil
    controller.upgradeWalkLastDistance = nil
    local char = player.Character
    local humanoid = char and char:FindFirstChildOfClass("Humanoid")
    local root = rootPart()
    if humanoid and root then
        pcall(function() humanoid:MoveTo(root.Position) end)
    end
end

local function approachUpgradeHolder(target, now)
    if not target then
        return "No Holder UpgradeClick on selected plot"
    end
    if target.allowed <= 0 then
        return "Holder UpgradeClick disabled (max range 0)"
    end
    if target.distance > 120 then
        return ("Holder too far (%.1f studs, limit 120)"):format(target.distance)
    end
    local char = player.Character
    local humanoid = char and char:FindFirstChildOfClass("Humanoid")
    local pos = positionOf(target.detector)
    if not humanoid or not pos or humanoid.Health <= 0 then
        return "Cannot walk: Humanoid or holder position missing"
    end
    if controller.upgradeWalkTarget ~= target.detector then
        stopUpgradeWalking()
        stopWalking() -- surrender a previous Chest MoveTo; Auto Collect remains ON
        controller.upgradeWalkTarget = target.detector
        controller.upgradeWalkLastDistance = target.distance
        controller.upgradeWalkProgressAt = now
        controller.upgradeWalkLastCommand = 0
        controller.upgradeWalkLastTarget = describe(target.detector)
        writeLog(("Upgrade walking to %s (%.1f studs, click range %.1f)"):format(
            controller.upgradeWalkLastTarget, target.distance, target.allowed))
    end
    if target.distance + 0.75 < (controller.upgradeWalkLastDistance or math.huge) then
        controller.upgradeWalkLastDistance = target.distance
        controller.upgradeWalkProgressAt = now
    end
    if now - controller.upgradeWalkProgressAt > 11 then
        stopUpgradeWalking()
        controller.upgrade = false
        return "PAUSED: holder walk blocked for 11s (Auto Collect unaffected)"
    end
    if now - controller.upgradeWalkLastCommand >= 1.8 then
        controller.upgradeWalkLastCommand = now
        controller.upgradeWalkAttempts = controller.upgradeWalkAttempts + 1
        local ok, err = pcall(function() humanoid:MoveTo(pos) end)
        if not ok then
            stopUpgradeWalking()
            controller.upgrade = false
            return "PAUSED: Holder MoveTo ERROR: " .. tostring(err)
        end
    end
    controller.upgradeBusyUntil = now + 3.5
    return ("Walking to holder %.1f / %.1f studs"):format(target.distance, target.allowed)
end


-- Never click the Inventory launcher, Holder upgrade detector, Stats tab
-- or the global Upgrades menu in headless mode.
-- A loaded but hidden Equip Best button can still have a usable GUI
-- click listener. This is not a network protocol and may not change gear.
local function gameGuiAncestorNamed(item, name)
    local cursor = item
    while cursor and cursor ~= playerGui do
        if cursor.Name == name then return true end
        cursor = cursor.Parent
    end
    return false
end

local function hiddenEquipBestCandidates()
    local results = {}
    for _, item in ipairs(playerGui:GetDescendants()) do
        if gameGuiButton(item)
            and gameGuiAncestorNamed(item, "MineGui")
            and gameGuiAncestorNamed(item, "InventoryFrame")
            and not gameGuiAncestorNamed(item, "Shop")
            and not gameGuiAncestorNamed(item, "Gamepass")
            and not isPremiumAction(item) then
            local text = normalizeLabel(actionLabel(item))
            if text:find("equipbest", 1, true) or text:find("bestcrew", 1, true) then
                results[#results + 1] = item
            end
        end
    end
    return results
end

local function headlessRemotes()
    local list = {}
    local all = {}
    local ok, remotes = pcall(function()
        return game:GetService("ReplicatedStorage"):GetDescendants()
    end)
    if not ok then return list end
    for _, item in ipairs(remotes) do
        if item:IsA("RemoteEvent") or item:IsA("RemoteFunction") then
            local name = tostring(item.Name):lower()
            local entry = {
                remote = item,
                name = item.Name,
                path = describe(item),
                kind = item.ClassName,
            }
            all[#all + 1] = entry
            if name:find("equip", 1, true) or name:find("upgrade", 1, true)
                or name:find("miner", 1, true) or name:find("unit", 1, true)
                or name:find("inventory", 1, true) or name:find("sell", 1, true) then
                list[#list + 1] = entry
            end
        end
    end
    if #list == 0 then
        for i = 1, math.min(35, #all) do list[#list + 1] = all[i] end
    end
    controller.headlessRemoteTargets = list
    controller.headlessRemoteCount = #all
    return list
end

local function tryHeadlessEquip()
    if type(firesignal) ~= "function" then
        return false, "NO_FIRESIGNAL"
    end
    local candidates = hiddenEquipBestCandidates()
    if #candidates == 0 then return false, "HEADLESS_TARGET_UNKNOWN" end
    for _, button in ipairs(candidates) do
        local counts = takeAllConnections(button)
        local event = nil
        if type(counts.MouseButton1Click) == "number" and counts.MouseButton1Click > 0 then
            event = "MouseButton1Click"
        elseif type(counts.Activated) == "number" and counts.Activated > 0 then
            event = "Activated"
        end
        if event then
            controller.headlessEquipTarget = describe(button)
            local ok, err = pcall(firesignal, button[event])
            if ok then
                return true, "HIDDEN_EQUIP_SIGNAL_SENT; RESULT_UNVERIFIED"
            end
            return false, "HIDDEN_EQUIP_SIGNAL_ERROR: " .. tostring(err)
        end
    end
    return false, "NO_ACTIVE_EQUIP_BEST_LISTENER"
end

-- Upgrade ONLY preloaded native crew Stats controls. They may be hidden,
-- like the confirmed Equip Best callback, but must have an actual listener.
-- Never open an Inventory, click a Holder, buy a Game Pass, or invent a remote.
local function safeHeadlessStatsUpgrades()
    local candidates,frames={},{}
    local frameCount=0
    for _,button in ipairs(playerGui:GetDescendants()) do
        if gameGuiButton(button) and isUpgradeAction(button) then
            local frame=nil
            local cursor=button.Parent
            while cursor and cursor~=playerGui do
                if cursor.Name=="StatsFrame" or cursor.Name=="UnitUpgradeFrame"
                    or cursor.Name=="CharacterUpgradeFrame" then
                    frame=cursor
                    break
                end
                cursor=cursor.Parent
            end
            if frame and (gameGuiAncestorNamed(button,"UnitGui")
                or gameGuiAncestorNamed(button,"MineGui")
                or gameGuiAncestorNamed(button,"CrewGui")) then
                if not frames[frame] then
                    frames[frame]=true
                    frameCount=frameCount+1
                end
                local stat=statContext(button)
                if stat=="Damage" or stat=="Speed" or stat=="Mining Speed" then
                    local connections=takeAllConnections(button)
                    local event=nil
                    if type(connections.MouseButton1Click)=="number"
                        and connections.MouseButton1Click>0 then
                        event="MouseButton1Click"
                    elseif type(connections.Activated)=="number"
                        and connections.Activated>0 then
                        event="Activated"
                    end
                    if event then candidates[#candidates+1]={
                        button=button,stat=stat,event=event,frame=frame,
                        path=describe(button),
                    } end
                end
            end
        end
    end
    if frameCount>1 then return {}, "MULTIPLE_CREW_STATS_PANELS",frameCount end
    if #candidates==0 then
        return {},"NO_LOADED_STATS_BUTTON_WITH_LISTENER",frameCount
    end
    -- Never guess between two potential purchases for the same stat.
    local unique,byStat={},{}
    for _,entry in ipairs(candidates) do
        byStat[entry.stat]=(byStat[entry.stat] or 0)+1
        unique[entry.stat]=entry
    end
    for _,count in pairs(byStat) do
        if count~=1 then return {},"AMBIGUOUS_STAT_UPGRADE_BUTTON",frameCount end
    end
    local ordered={}
    for _,stat in ipairs({"Damage","Speed","Mining Speed"}) do
        if unique[stat] then ordered[#ordered+1]=unique[stat] end
    end
    return ordered,"READY",frameCount
end

local function headlessUpgradeStep(now)
    if not controller.upgrade then return end
    if controller.sell or controller.takeAllPending
        or (controller.cycleEnabled and controller.cyclePhase~="WAITING") then
        controller.upgradeStage="WAITING_FOR_SAFE_BASE_IDLE"
        return
    end
    if type(firesignal)~="function" or type(getconnections)~="function" then
        controller.upgradeStage="NO_SAFE_GUI_LISTENERS"
        return
    end
    if not controller.selectedPlot then
        controller.upgradeStage="WAITING_FOR_SELECTED_PLOT"
        return
    end
    local chest,distance=selectedChest()
    if not chest or type(distance)~="number" or distance>75 then
        controller.upgradeStage="WAITING_FOR_BASE_NEAR_SELECTED_PLOT"
        return
    end
    if controller.upgradePending then return end
    local choices,status,frames=safeHeadlessStatsUpgrades()
    controller.upgradeSafeCandidates=#choices
    if status~="READY" then
        controller.upgradeStage=status.." (frames="..tostring(frames)..")"
        controller.headlessUpgradeStatus=controller.upgradeStage
        return
    end
    local chosen=choices[(controller.upgradeIndex-1)%#choices+1]
    controller.upgradeIndex=controller.upgradeIndex+1
    -- The purchase is made through the game-native GUI listener. Never
    -- dispatch twice while confirmation of the prior click is outstanding.
    controller.upgradeAttempts=controller.upgradeAttempts+1
    controller.upgradeLastTarget=chosen.path
    controller.upgradeLastStat=chosen.stat
    controller.upgradeLastEvent=chosen.event
    local before=upgradeRowSnapshot(chosen.button)
    local ok,err=pcall(firesignal,chosen.button[chosen.event])
    if not ok then
        controller.upgradeStage="GUI_SIGNAL_ERROR: "..tostring(err)
        controller.headlessUpgradeStatus=controller.upgradeStage
        controller.upgrade=false
        writeLog("AUTO UPGRADE paused: "..controller.upgradeStage)
        return
    end
    controller.upgradeActions=controller.upgradeActions+1
    controller.upgradePending={
        button=chosen.button,stat=chosen.stat,event=chosen.event,
        before=before,started=now,
    }
    controller.upgradeStage="STATS_SIGNAL_SENT "..chosen.stat.."; VERIFYING"
    controller.headlessUpgradeStatus=controller.upgradeStage
    writeLog("AUTO UPGRADE: "..chosen.stat.." game GUI listener sent ("..
        chosen.event.."); result NOT verified | "..chosen.path)
end

-- Auto Sell is confined to the game's ChestFrame and never touches
-- inventory cards, pets, character sales, or global shop purchases.
-- It only attempts a preloaded native Chest Auto Sell control, whether
-- its panel happens to be visible or hidden; no new game window is opened.
local function scanNativeAutoSell()
    local buttons, labels = {}, {}
    for _, item in ipairs(playerGui:GetDescendants()) do
        if gameGuiAncestorNamed(item, "MineGui")
            and gameGuiAncestorNamed(item, "ChestFrame") then
            if item:IsA("TextLabel") and
                normalizeLabel(textOf(item)):find("autosell", 1, true) then
                if #labels < 24 then labels[#labels + 1] = item end
            elseif gameGuiButton(item) then
                local named = normalizeLabel(item.Name)
                local label = normalizeLabel(actionLabel(item))
                local parent = item.Parent
                local parentName = parent and normalizeLabel(parent.Name) or ""
                local isSellControl = named:find("autosell", 1, true)
                    or label:find("autosell", 1, true)
                    or parentName:find("autosell", 1, true)
                if isSellControl
                    and not isPremiumAction(item)
                    and not gameGuiAncestorNamed(item, "Shop")
                    and not gameGuiAncestorNamed(item, "Gamepass")
                    and not gameGuiAncestorNamed(item, "Premium") then
                    buttons[#buttons + 1] = item
                end
            end
        end
    end
    controller.sellCandidates, controller.sellLabels = buttons, labels
    return buttons, labels
end

-- Only an explicit UI indication is accepted as ON/OFF. A color or a signal
-- dispatch is not an authoritative sell-state indicator.
local function nativeAutoSellState(button)
    local label = actionLabel(button):lower()
    if label:match("auto%s*sell%s*[:%-]?%s*on%s*$") then return "ON" end
    if label:match("auto%s*sell%s*[:%-]?%s*off%s*$") then return "OFF" end
    local status = textOf(button):lower():gsub("^%s+", ""):gsub("%s+$", "")
    if status == "on" or status == "enabled" then return "ON" end
    if status == "off" or status == "disabled" then return "OFF" end
    local parent = button.Parent
    if parent then
        for _, sibling in ipairs(parent:GetChildren()) do
            if sibling:IsA("TextLabel") then
                local text = textOf(sibling):lower():gsub("^%s+", ""):gsub("%s+$", "")
                if text == "on" or text == "enabled" then return "ON" end
                if text == "off" or text == "disabled" then return "OFF" end
            end
        end
    end
    return "UNKNOWN"
end

-- A toggle is clicked only when its current ON/OFF state is explicitly
-- readable. Without that evidence a click could disable an already active
-- Auto Sell, so report unknown rather than guessing.
local function setNativeAutoSell(desired)
    if type(firesignal) ~= "function" then return false, "FIRESIGNAL_UNAVAILABLE" end
    local buttons, labels = scanNativeAutoSell()
    if #buttons == 0 then
        return false, #labels > 0 and "AUTO_SELL_LABEL_ONLY_NO_BUTTON"
            or "AUTO_SELL_CHEST_CONTROL_NOT_FOUND"
    end
    local ready = {}
    for _, button in ipairs(buttons) do
        local counts = takeAllConnections(button)
        if type(counts.MouseButton1Click) == "number" and counts.MouseButton1Click > 0 then
            ready[#ready + 1] = {button=button, event="MouseButton1Click"}
        elseif type(counts.Activated) == "number" and counts.Activated > 0 then
            ready[#ready + 1] = {button=button, event="Activated"}
        end
    end
    if #ready == 0 then return false, "AUTO_SELL_NO_CONFIRMED_LISTENER" end
    if #ready > 1 then return false, "AUTO_SELL_AMBIGUOUS_ACTIVE_BUTTONS" end
    local choice = ready[1]
    local button = choice.button
    controller.sellTarget = describe(button)
    controller.sellEvent = choice.event
    local state = nativeAutoSellState(button)
    controller.sellInitialState = state
    controller.sellLastObservedState = state

    if state == desired then
        controller.sellSent = true
        return true, "AUTO_SELL_UI_ALREADY_" .. desired .. " (ore sales not verified)"
    end
    if state == "UNKNOWN" then
        return false, "AUTO_SELL_STATE_UNKNOWN (no toggle sent)"
    end

    -- At most one signal per enable/disable action, never assume that pcall
    -- means server accepted the sale or that a currency balance changed.
    controller.sellSent = true
    controller.sellAttempts = controller.sellAttempts + 1
    local ok, err = pcall(firesignal, button[choice.event])
    if ok then
        controller.sellCallsOK = controller.sellCallsOK + 1
        controller.sellLastObservedState = nativeAutoSellState(button)
        return true, "AUTO_SELL_SWITCH_TO_" .. desired .. "_SENT (selling unverified)"
    end
    return false, "AUTO_SELL_SIGNAL_ERROR: " .. tostring(err)
end

local function tryNativeAutoSell()
    return setNativeAutoSell("ON")
end


-- Normal ore sale uses the Shops teleport destination and a physical sell
-- stand. Do not confuse it with the paid native Chest Auto Sell Game Pass.
local function sellSetPhase(phase, message, now)
    controller.sellPhase = phase
    controller.sellPhaseAt = now or os.clock()
    controller.sellStage = message or phase
    writeLog("SHOP SELL: " .. tostring(controller.sellStage))
end

local function sellClick(button)
    if type(firesignal) ~= "function" then return false, "firesignal unavailable" end
    if not button or not button.Parent then return false, "button removed" end
    local counts = takeAllConnections(button)
    local event
    if type(counts.MouseButton1Click) == "number" and counts.MouseButton1Click > 0 then
        event = "MouseButton1Click"
    elseif type(counts.Activated) == "number" and counts.Activated > 0 then
        event = "Activated"
    end
    if not event then return false, "no verified event listener" end
    local ok, err = pcall(firesignal, button[event])
    return ok, ok and event or tostring(err)
end

-- When Take All has just opened the game's chest, its modal may hide the
-- hotbar TeleportButton entirely. Do not mistake this for a missing button.
local function gameChestFrame()
    local mine = playerGui:FindFirstChild("MineGui")
    local chest = mine and mine:FindFirstChild("ChestFrame")
    return chest, chest ~= nil and isVisible(chest)
end

local function teleportLauncherCandidates()
    local matches = {}
    for _, button in ipairs(playerGui:GetDescendants()) do
        if gameGuiButton(button) and button.Name == "TeleportButton"
            and gameGuiAncestorNamed(button, "MineGui") then
            matches[#matches+1] = button
        end
    end
    return matches
end

local function shopsTeleportLauncher()
    local matches = teleportLauncherCandidates()
    local visible = {}
    for _,button in ipairs(matches) do
        if isVisible(button) then visible[#visible+1] = button end
    end
    -- Never arbitrarily choose from multiple Teleport launchers.
    return #visible == 1 and visible[1] or nil
end

local function shopsWarpDestination()
    local candidates = {}
    for _, button in ipairs(playerGui:GetDescendants()) do
        if gameGuiButton(button) then
            local key = normalizeLabel(button.Name)
            local textKey = normalizeLabel(textOf(button))
            local labeled = normalizeLabel(actionLabel(button))
            local explicit = key == "shops" or key == "shopsbutton"
                or key == "shopsdestination" or key == "shopswarp"
                or textKey == "shops" or textKey == "shopsteleport"
                or labeled == "shops"
            if explicit and not isPremiumAction(button)
                and not gameGuiAncestorNamed(button, "ShopPurchase")
                and not gameGuiAncestorNamed(button, "Store")
                and isVisible(button) then
                candidates[#candidates+1] = button
            end
        end
    end
    controller.sellMenuButtons = candidates
    -- Never pick arbitrarily among multiple Shops buttons.
    return #candidates == 1 and candidates[1] or nil, #candidates
end


-- The game's native top Base/Shops toggle is the same MineGui/
-- TeleportButton used for going to Shops. Verify its return destination by
-- the Chest prompt on the selected Plot, not by arbitrary travel distance.
local function baseReturnDestination()
    local candidates={}
    for _,button in ipairs(playerGui:GetDescendants()) do
        if gameGuiButton(button) and isVisible(button) and not isPremiumAction(button)
            and gameGuiAncestorNamed(button,"MineGui")
            and (gameGuiAncestorNamed(button,"TeleportFrame")
                 or gameGuiAncestorNamed(button,"TeleportMenu")
                 or gameGuiAncestorNamed(button,"TeleportGui")) then
            local name=normalizeLabel(button.Name)
            local label=normalizeLabel(textOf(button))
            local valid = name=="base" or name=="basebutton"
                or name=="mybase" or name=="mybasebutton"
                or name=="myplot" or name=="myplotbutton"
                or name=="backtobase" or name=="returntobase"
                or label=="base" or label=="mybase" or label=="myplot"
                or label=="returntobase"
            if valid then candidates[#candidates+1]=button end
        end
    end
    return #candidates==1 and candidates[1] or nil,#candidates
end

local function returnBaseDistance()
    if not controller.selectedPlot or
        controller.sellReturnOriginalPlot~=controller.selectedPlot then
        return nil,"Plot changed during sale"
    end
    local chest,distance,reason=selectedChest()
    if not chest or type(distance)~="number" then
        return nil,reason or "Selected-Plot ChestPrompt unavailable"
    end
    return distance,describe(chest)
end

local function finishVerifiedBaseReturn(distance,now)
    controller.sellReturnVerified=true
    controller.sellReturnCurrentDistance=distance
    controller.sellReturnStatus="VERIFIED_NEAR_SELECTED_PLOT"
    controller.sellReturnAt=now
    controller.sell=false
    controller.sellPhase="RETURNED_BASE"
    controller.sellPhaseAt=now
    if controller.cycleEnabled and controller.cyclePhase=="SELLING" then
        controller.cyclePhase="WAITING"
        controller.cycleLastReturnAt=now
        if controller.cycleNextAt<=0 then
            controller.cycleNextAt=now+controller.cycleMinutes*60
        end
        writeLog(("AUTO FARM: Returned to Base; next Collect in %.0fs"):format(
            math.max(0,controller.cycleNextAt-now)))
    end
    controller.sellStage=("Returned near %s Chest (%.1f studs); Auto Collect %s"):format(
        tostring(controller.selectedPlot),distance,controller.collect and "can resume" or "is OFF")
    writeLog("SHOP SELL: "..controller.sellStage..
        " | previous Sell dispatch does not prove cash credit")
end

local function returnBaseStep(now,phase)
    local root=rootPart()
    if not root then
        controller.sellReturnStatus="WAITING_FOR_CHARACTER"
        return
    end
    local distance,source=returnBaseDistance()
    controller.sellReturnCurrentDistance=distance
    if not distance then
        sellSetPhase("PAUSED","Return Base blocked: "..tostring(source),now)
        controller.sellReturnStatus="PLOT_TARGET_MISSING"
        return
    end

    -- Only a return near the SAME previously selected Plot can release the
    -- Collect worker. This is a proximity check, not ownership proof.
    local originDistance=controller.sellReturnStartDistance
    if distance<=75 and (not originDistance or originDistance<110
        or distance<originDistance-60) then
        finishVerifiedBaseReturn(distance,now)
        return
    end

    if phase=="RETURN_BASE_OPEN" then
        if now-controller.sellPhaseAt<1.3 then
            controller.sellReturnStatus="SELL_BUTTON_SETTLING"
            return
        end
        local _,chestOpen=gameChestFrame()
        if chestOpen then
            controller.sellReturnStatus="CHEST_MODAL_BLOCKING_TELEPORT"
            if now-controller.sellPhaseAt>13 then
                sellSetPhase("PAUSED","Return Base: Chest modal still open",now)
            end
            return
        end
        local mine=playerGui:FindFirstChild("MineGui")
        local frame=mine and mine:FindFirstChild("SellFrame")
        if frame and isVisible(frame) then
            controller.sellReturnStatus="SELLFRAME_STILL_OPEN"
            if now-controller.sellPhaseAt>13 then
                sellSetPhase("PAUSED","Return Base: SellFrame still open; close it manually",now)
            end
            return
        end
        local launcher=shopsTeleportLauncher()
        if not launcher then
            controller.sellReturnStatus="BASE_SHOPS_BUTTON_NOT_VISIBLE"
            if now-controller.sellPhaseAt>14 then
                sellSetPhase("PAUSED","Return Base: TeleportButton hidden or absent (COPY SELL ROUTE)",now)
            end
            return
        end
        controller.sellReturnTarget=describe(launcher)
        controller.sellReturnClicks=controller.sellReturnClicks+1
        controller.sellReturnOrigin=root.Position
        controller.sellReturnStartDistance=distance
        local ok,reason=sellClick(launcher)
        if ok then
            controller.sellReturnStatus="BASE_SHOPS_TOGGLE_SENT"
            sellSetPhase("RETURN_BASE_WAIT",
                "Base/Shops button dispatched ("..reason.."); checking selected Plot",now)
        else
            controller.sellReturnStatus="BASE_SHOPS_CLICK_ERROR"
            sellSetPhase("PAUSED","Return Base button click error: "..reason,now)
        end
        return
    end

    if phase=="RETURN_BASE_WAIT" then
        if controller.sellReturnChoiceClicks==0 then
            local base,count=baseReturnDestination()
            if count>1 then
                controller.sellReturnStatus="AMBIGUOUS_BASE_DESTINATIONS"
                sellSetPhase("PAUSED","Multiple Base destinations; will not guess",now)
                return
            elseif base then
                controller.sellReturnTarget=describe(base)
                controller.sellReturnChoiceClicks=1
                local ok,reason=sellClick(base)
                if not ok then
                    controller.sellReturnStatus="BASE_DESTINATION_CLICK_ERROR"
                    sellSetPhase("PAUSED","Base destination click failed: "..reason,now)
                else
                    controller.sellReturnStatus="BASE_DESTINATION_SENT"
                    controller.sellStage="Base destination dispatched; verifying selected Plot"
                end
                return
            end
        end
        controller.sellReturnStatus="AWAITING_SELECTED_PLOT"
        controller.sellStage=("Returning to %s; Chest distance %.1f studs"):format(
            tostring(controller.selectedPlot),distance)
        if now-controller.sellPhaseAt>17 then
            controller.sellReturnStatus="RETURN_UNVERIFIED"
            sellSetPhase("PAUSED",("Return Base unverified (Chest %.1f studs away); Collect remains paused"):format(distance),now)
        end
    end
end

local function sellNodePosition(item)
    if item:IsA("BasePart") then return item.Position end
    return positionOf(item)
end

local function sellVendorTargets()
    local root = rootPart()
    if not root then return {} end
    local list = {}
    for _, item in ipairs(workspace:GetDescendants()) do
        local prompt = item:IsA("ProximityPrompt")
        local detector = item:IsA("ClickDetector")
        local marker = item:IsA("BasePart")
        if prompt or detector or marker then
            local title = normalizeLabel(item.Name .. " " ..
                (prompt and tostring(item.ActionText or "") or ""))
            local parent = item.Parent
            local parentName = parent and normalizeLabel(parent.Name) or ""
            local grand = parent and parent.Parent
            local grandName = grand and normalizeLabel(grand.Name) or ""
            local context = title .. parentName .. grandName
            local named = context:find("sellitems",1,true)
                or context:find("sellore",1,true)
                or context:find("oreseller",1,true)
                or context:find("sellstall",1,true)
                or context:find("sellstand",1,true)
                or context:find("sellpoint",1,true)
            local contextual = prompt and title == "sell"
                and (parentName:find("shop",1,true)
                    or parentName:find("vendor",1,true)
                    or parentName:find("sell",1,true))
            if (named or contextual) and not context:find("gamepass",1,true)
                and not context:find("premium",1,true)
                and not context:find("characters",1,true) then
                local pos = sellNodePosition(item)
                if pos then
                    local d = (pos - root.Position).Magnitude
                    local maxRange = (prompt or detector)
                        and tonumber(item.MaxActivationDistance) or 10
                    list[#list+1] = {
                        target=item, position=pos, distance=d,
                        type=prompt and "prompt" or detector and "detector" or "marker",
                        maxRange=maxRange,
                    }
                end
            end
        end
    end
    table.sort(list, function(a,b)
        -- Favor actual interaction over signs/marker parts.
        local aa,bb = a.type=="marker", b.type=="marker"
        if aa ~= bb then return not aa end
        if a.distance ~= b.distance then return a.distance < b.distance end
        return describe(a.target) < describe(b.target)
    end)
    return list
end

-- Runtime-confirmed game paths (V0.14):
-- SellStand/GingerbreadKeeper/UpperTorso/SellPrompt opened
-- MineGui/SellFrame/Content/SellButton (MouseButton1Click listener 1).
-- The bare SellButton is only actionable after this exact vendor interaction.
local function sellMenuSessionReady()
    if not controller.sell
        or (controller.sellPhase ~= "SELECT_ALL" and controller.sellPhase ~= "SELL_MENU")
        or type(controller.sellVendorPath) ~= "string" then return false end
    local location=controller.sellVendorPath
    local validPath = location:find("/SellStand/",1,true) ~= nil
        or location:find("/SellItemsStand/",1,true) ~= nil
        or location:match("/SellStand$") ~= nil
        or location:match("/SellItemsStand$") ~= nil
    return validPath
        and (controller.sellVendorAttempts >= 1 or controller.sellVendorTouched == true)
end

local function validatedSellStandSession()
    return sellMenuSessionReady()
        and controller.sellVendorPath:find(
            "SellStand/GingerbreadKeeper/UpperTorso/SellPrompt", 1, true) ~= nil
end

local function knownOreSellFrame()
    local mine = playerGui:FindFirstChild("MineGui")
    local frame = mine and mine:FindFirstChild("SellFrame")
    if not frame or not isVisible(frame) then return nil, nil end
    local content = frame:FindFirstChild("Content")
    if not content or not isVisible(content) then return nil, nil end
    -- The seller must not be reused for pets, equipment, or other inventory.
    for _, item in ipairs(frame:GetDescendants()) do
        if item:IsA("TextLabel") or item:IsA("TextButton") then
            local t=normalizeLabel(item.Name.." "..textOf(item))
            if t:find("sellcharacters",1,true)
                or t:find("sellunits",1,true)
                or t:find("sellpets",1,true)
                or t:find("sellequipment",1,true)
                or t:find("sellweapons",1,true) then return nil,nil end
        end
    end
    return frame, content
end

local function sellSelectAllButton()
    if not sellMenuSessionReady() then return nil, 0 end
    local frame, content = knownOreSellFrame()
    if not frame or not content then return nil,0 end
    local candidates={}
    for _, button in ipairs(content:GetDescendants()) do
        if gameGuiButton(button) and isVisible(button) and not isPremiumAction(button) then
            local name = normalizeLabel(button.Name)
            local label = normalizeLabel(textOf(button))
            local matches = name == "selectall" or name == "selectallbutton"
                or name == "selectallores" or name == "selectalloresbutton"
                or label == "selectall" or label == "selectallores"
            -- Game layouts may render the text on a nested TextLabel.
            if not matches then
                for _, child in ipairs(button:GetDescendants()) do
                    if child:IsA("TextLabel") then
                        local inner = normalizeLabel(textOf(child))
                        if inner == "selectall" or inner == "selectallores" then
                            matches=true
                            break
                        end
                    end
                end
            end
            if matches then candidates[#candidates+1] = button end
        end
    end
    return #candidates==1 and candidates[1] or nil, #candidates
end

local function isExactSellStandButton(button)
    if not button or not gameGuiButton(button) or not isVisible(button)
        or button.Name ~= "SellButton" then return false end
    local content=button.Parent
    local frame=content and content.Parent
    local mine=frame and frame.Parent
    local safeFrame, safeContent=knownOreSellFrame()
    return content and content.Name == "Content"
        and frame and frame.Name == "SellFrame"
        and mine and mine.Name == "MineGui" and mine.Parent == playerGui
        and safeFrame == frame and safeContent ~= nil
        and not isPremiumAction(button)
        and validatedSellStandSession()
end

local function oreSellButton()
    -- Even explicitly named Sell Ores buttons must belong to the current
    -- authorized SellFrame. Do not click a similarly named button in Shop,
    -- Inventory, or another player's UI.
    if not sellMenuSessionReady() then return nil,0,"SESSION_NOT_VERIFIED" end
    local frame=knownOreSellFrame()
    if not frame then return nil,0,"SELLFRAME_NOT_VISIBLE" end
    local candidates={}
    for _,button in ipairs(frame:GetDescendants()) do
        if gameGuiButton(button) and isVisible(button) and not isPremiumAction(button) then
            local name=normalizeLabel(button.Name)
            local label=normalizeLabel(textOf(button))
            local explicit=name=="sellores" or name=="sellore"
                or name=="sellallores" or name=="selloresbutton"
                or label=="sellores" or label=="sellallores"
            if explicit then
                candidates[#candidates+1]={button=button,kind="EXPLICIT_ORES"}
            elseif isExactSellStandButton(button) then
                candidates[#candidates+1]={button=button,kind="CONFIRMED_SELL_STAND"}
            end
        end
    end
    if #candidates==1 then return candidates[1].button,1,candidates[1].kind end
    return nil,#candidates,#candidates>1 and "AMBIGUOUS" or "NONE"
end

local function sellStopWalk()
    if controller.sellMoveTarget then
        local root = rootPart()
        local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
        if root and humanoid then pcall(function() humanoid:MoveTo(root.Position) end) end
        controller.sellMoveTarget = nil
    end
end

-- A user may arm Auto Sell immediately after the previous Chest Take All.
-- Require same selected Plot, short freshness and evidence that this exact
-- dispatch is still pending or closed the Chest. Client UI proof only.
local function recentTakeAllForHandoff(now)
    local at=controller.takeAllLastDispatchAt
    if not controller.collect or type(at)~="number" or at<=0
        or controller.selectedPlot==nil
        or controller.takeAllLastDispatchPlot~=controller.selectedPlot then
        return false,nil
    end
    local age=now-at
    if age<0 or age>8 then return false,age end
    local pending=controller.takeAllPending
    if pending and type(pending.sentAt)=="number"
        and math.abs(pending.sentAt-at)<0.25 then
        return true,age
    end
    local _,chestOpen=gameChestFrame()
    local closedOutcome=type(controller.takeAllOutcome)=="string"
        and controller.takeAllOutcome:find("CHEST_CLOSED_AFTER_TAKE_ALL",1,true)~=nil
    return not chestOpen and closedOutcome,age
end

local function shopSellStep(now)
    if not controller.sell then return end
    local phase = controller.sellPhase
    if phase == "DONE" or phase == "PAUSED" or phase == "RETURNED_BASE" then return end
    if phase=="RETURN_BASE_OPEN" or phase=="RETURN_BASE_WAIT" then
        returnBaseStep(now,phase)
    end
    local root = rootPart()
    if not root then
        controller.sellStage = "Waiting for character"
        return
    end
    if phase == "CHEST_HANDOFF" then
        local _,chestOpen=gameChestFrame()
        local pending=controller.takeAllPending ~= nil
        local elapsed=now-controller.sellPhaseAt
        controller.sellChestHandoffAttempts=controller.sellChestHandoffAttempts+1

        -- V0.18 could teleport while Auto Collect was STILL WALKING to Chest.
        -- If Auto Collect was active when the user requested selling, finish
        -- exactly the current collection attempt before starting travel.
        if controller.sellHandoffNeedsCollect then
            if controller.takeAllActions > controller.sellHandoffBaselineTakeAllActions then
                controller.sellHandoffTakeAllObserved=true
            end
            if not controller.sellHandoffTakeAllObserved
                and not controller.sellHandoffChestEmpty then
                if not controller.collect then
                    sellSetPhase("PAUSED",
                        "Auto Collect stopped before Take All; review Chest before selling",now)
                elseif elapsed > 42 then
                    sellSetPhase("PAUSED",
                        "No Take All within 42s; walk/Chest may be blocked (COPY SELL ROUTE)",now)
                else
                    controller.sellChestHandoffState = controller.moveTarget
                        and "COLLECT_WALKING_TO_CHEST"
                        or chestOpen and "COLLECT_WAITING_FOR_TAKE_ALL"
                        or "COLLECT_WAITING_FOR_CHEST_OPEN"
                    controller.sellStage =
                        "Finishing active Auto Collect before Shops (Take All not sent yet)"
                end
                return
            end
        end
        if chestOpen or pending then
            controller.sellChestHandoffState=chestOpen and "CHEST_OPEN"
                or "TAKE_ALL_PENDING"
            local maxWait=controller.sellHandoffNeedsCollect and 47 or 24
            if elapsed > maxWait then
                sellSetPhase("PAUSED",
                    "Chest still open/pending; finish Take All or close Chest manually",now)
            else
                controller.sellStage=controller.collect and
                    "Waiting for Auto Collect Take All feedback and Chest to close"
                    or "Close the open Chest manually to allow Shops teleport"
            end
            return
        end
        if elapsed < 1.3 then
            controller.sellChestHandoffState="CHEST_RENDER_GRACE"
            controller.sellStage="Waiting briefly for Chest UI to settle"
            return
        end
        if controller.sellHandoffNeedsCollect then
            controller.sellChestHandoffState=controller.sellHandoffChestEmpty
                and "CHEST_EMPTY" or controller.sellHandoffRecentTakeAll
                and "RECENT_TAKE_ALL_REUSED" or "COLLECT_FINISHED"
        else
            controller.sellChestHandoffState="CHEST_CLOSED"
        end
        stopWalking()
        sellSetPhase("TELEPORT_OPEN","Chest clear; searching Teleport > Shops",now)
        return
    end
    if phase == "TELEPORT_OPEN" then
        local chest,chestOpen=gameChestFrame()
        if chestOpen or controller.takeAllPending then
            sellSetPhase("CHEST_HANDOFF","Chest reopened; wait for Take All before Shops teleport",now)
            controller.sellChestHandoffState="CHEST_REOPENED"
            return
        end
        local shops, count = shopsWarpDestination()
        if shops then
            controller.sellWarpOrigin = root.Position
            controller.sellShopsAttempts = controller.sellShopsAttempts + 1
            controller.sellActionTarget = describe(shops)
            local ok, reason = sellClick(shops)
            if ok then
                sellSetPhase("WARP_WAIT", "Shops destination clicked ("..reason..")",now)
            else
                sellSetPhase("PAUSED", "Shops click failed: "..reason,now)
            end
            return
        end
        local button = shopsTeleportLauncher()
        if not button then
            local candidates=teleportLauncherCandidates()
            local _,chestOpen=gameChestFrame()
            controller.sellStage = chestOpen and "Chest is open, Teleport hidden"
                or #candidates>1 and "Multiple TeleportButton candidates; cannot choose"
                or #candidates==1 and "TeleportButton exists but hidden; close other game panels"
                or count>1 and "Multiple Shops options; no automatic selection"
                or "TeleportButton absent from MineGui (not just hidden)"
            if chestOpen then
                sellSetPhase("CHEST_HANDOFF","Chest open; delaying Teleport until collection ends",now)
            elseif now - controller.sellPhaseAt > 15 then
                sellSetPhase("PAUSED",controller.sellStage.." (COPY SELL ROUTE)",now)
            end
            return
        end
        controller.sellWarpOrigin = root.Position
        controller.sellActionTarget = describe(button)
        controller.sellWarpAttempts = controller.sellWarpAttempts + 1
        local ok,reason = sellClick(button)
        if not ok then
            sellSetPhase("PAUSED","Teleport click failed: "..reason,now)
        else
            sellSetPhase("SHOPS_PICK", "Teleport opened; looking for Shops destination",now)
        end
        return
    end
    if phase == "SHOPS_PICK" or phase == "WARP_WAIT" then
        local moved = controller.sellWarpOrigin
            and (root.Position - controller.sellWarpOrigin).Magnitude or 0
        if moved > 50 then
            sellSetPhase("VENDOR_WALK",("Warp movement %.1f studs; searching Sell Items stand"):format(moved),now)
            return
        end
        if phase == "SHOPS_PICK" then
            local shops,count = shopsWarpDestination()
            if shops then
                controller.sellShopsAttempts = controller.sellShopsAttempts + 1
                controller.sellActionTarget = describe(shops)
                local ok,reason = sellClick(shops)
                if ok then
                    sellSetPhase("WARP_WAIT","Shops destination clicked ("..reason..")",now)
                else
                    sellSetPhase("PAUSED","Shops click failed: "..reason,now)
                end
                return
            end
            controller.sellStage = count > 1 and "Multiple Shops targets; diagnostics needed"
                or "Waiting for Shops option after Teleport"
        else
            controller.sellStage = "Waiting to arrive at Shops"
        end
        if now - controller.sellPhaseAt > 14 then
            sellSetPhase("PAUSED","Shops warp not confirmed; copy SELL ROUTE DIAGNOSTICS",now)
        end
        return
    end
    if phase == "VENDOR_WALK" then
        local candidates = sellVendorTargets()
        local vendor = candidates[1]
        if not vendor then
            controller.sellStage = "Shop warp reached; Sell Items stand target not found"
            if now-controller.sellPhaseAt > 18 then
                sellSetPhase("PAUSED",controller.sellStage,now)
            end
            return
        end
        controller.sellVendorPath = describe(vendor.target)
        controller.sellVendorDistance = vendor.distance
        if vendor.distance > 185 then
            sellSetPhase("PAUSED",("Sell stand %.1f studs away (>185 limit)"):format(vendor.distance),now)
            return
        end
        -- A touch-operated Sell stand can show its UI by walking onto its
        -- actual BasePart. Stop only when within 3 studs of a bare marker.
        local required = vendor.type == "marker" and 3
            or math.max(3, math.min(10, vendor.maxRange - 1))
        if vendor.distance <= required then
            sellStopWalk()
            if vendor.type == "marker" then
                controller.sellVendorTouched=true
                sellSetPhase("SELECT_ALL","Reached Sell stand marker; checking for SellFrame Select All",now)
                return
            end
            if vendor.maxRange <= 0 then
                sellSetPhase("PAUSED","Sell stand interaction disabled",now)
                return
            end
            local ok,reason
            if vendor.type == "prompt" and type(fireproximityprompt) == "function" then
                ok,reason = pcall(fireproximityprompt,vendor.target)
            elseif vendor.type == "detector" and type(fireclickdetector) == "function" then
                ok,reason = pcall(fireclickdetector,vendor.target)
            else
                sellSetPhase("PAUSED","Sell stand interaction API missing",now)
                return
            end
            controller.sellVendorAttempts = controller.sellVendorAttempts + 1
            if ok then sellSetPhase("SELECT_ALL","Sell stand opened; locating Select All",now)
            else sellSetPhase("PAUSED","Sell stand action error: "..tostring(reason),now) end
            return
        end
        local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
        if not humanoid or humanoid.Health <= 0 then
            sellSetPhase("PAUSED","No living Humanoid for walking",now)
            return
        end
        if controller.sellMoveTarget ~= vendor.target then
            sellStopWalk()
            controller.sellMoveTarget = vendor.target
            controller.sellLastProgressAt = now
            controller.sellLastDistance = vendor.distance
            controller.sellLastMoveAt = 0
        end
        if vendor.distance < (controller.sellLastDistance or math.huge)-1 then
            controller.sellLastDistance = vendor.distance
            controller.sellLastProgressAt = now
        end
        if now - controller.sellLastProgressAt > 14 then
            sellStopWalk()
            sellSetPhase("PAUSED","Walk to Sell stand blocked for 14s",now)
            return
        end
        if now - controller.sellLastMoveAt > 1.8 then
            controller.sellLastMoveAt = now
            controller.sellWalkAttempts = controller.sellWalkAttempts+1
            local ok,err = pcall(function() humanoid:MoveTo(vendor.position) end)
            if not ok then
                sellStopWalk()
                sellSetPhase("PAUSED","Sell stand MoveTo error: "..tostring(err),now)
                return
            end
        end
        controller.sellStage = ("Walking to Sell Items %.1f studs"):format(vendor.distance)
        return
    end
    if phase == "SELECT_ALL" then
        local selectAll,count=sellSelectAllButton()
        if selectAll then
            controller.sellSelectAllTarget=describe(selectAll)
            controller.sellSelectAllAttempts=controller.sellSelectAllAttempts+1
            local ok,reason=sellClick(selectAll)
            controller.sellSelectAllEvent=reason
            if ok then
                controller.sellSelectAllCallsOK=controller.sellSelectAllCallsOK+1
                controller.sellSelectAllSent=true
                controller.sellSelectAllAt=now
                sellSetPhase("SELL_MENU","Select All click sent ("..reason.."); next: Sell",now)
            else
                sellSetPhase("PAUSED","Select All click error: "..reason,now)
            end
        elseif count>1 then
            sellSetPhase("PAUSED","Multiple Select All controls in SellFrame; no click",now)
        elseif now-controller.sellPhaseAt>14 then
            sellSetPhase("PAUSED","Select All not found in SellFrame/Content; no Sell sent",now)
        else
            controller.sellStage="Waiting for Select All in SellFrame"
        end
        return
    end
    if phase == "SELL_MENU" then
        if not controller.sellSelectAllSent or controller.sellSelectAllCallsOK < 1 then
            sellSetPhase("PAUSED","Sell refused: Select All was not dispatched",now)
            return
        end
        -- Allow the game to apply the selection before selling.
        if now-controller.sellSelectAllAt < 0.8 then
            controller.sellStage="Waiting for Select All selection to settle"
            return
        end
        local action,count,kind = oreSellButton()
        if action then
            controller.sellActionTarget = describe(action)
            controller.sellActionKind = kind
            local ok,reason = sellClick(action)
            controller.sellSent = true
            controller.sellAttempts = controller.sellAttempts+1
            if ok then
                controller.sellCallsOK = controller.sellCallsOK+1
                controller.sellReturnOriginalPlot=controller.selectedPlot
                controller.sellReturnOrigin=root.Position
                controller.sellReturnStartDistance=select(1,returnBaseDistance())
                controller.sellReturnCurrentDistance=controller.sellReturnStartDistance
                controller.sellReturnStatus="READY_TO_RETURN"
                sellSetPhase("RETURN_BASE_OPEN",
                    "Sell "..kind.." sent ("..reason.."); returning to Base (ore/currency UNVERIFIED)",now)
            else
                sellSetPhase("PAUSED","Sell Ores click error: "..reason,now)
            end
        elseif now-controller.sellPhaseAt > 14 then
            sellSetPhase("PAUSED", count>1 and "Ambiguous ore-only Sell buttons"
                or "Sell interface does not expose an ore-only button; no Sell All attempted",now)
        else
            controller.sellStage = "Waiting for Sell Ores or verified SellStand SellButton"
        end
    end
end

local function resolveUpgradeFeedback(now)
    local pending = controller.upgradePending
    if not pending or now - pending.started < 2.7 then return end
    controller.upgradePending = nil
    local current = upgradeRowSnapshot(pending.button)
    if current ~= pending.before then
        controller.upgradeNoChange = 0
        controller.upgradeLastConfirmedUI="STATS_ROW_CHANGED_UNVERIFIED"
        controller.upgradeStage = "Stats row changed; purchase STILL UNVERIFIED"
    else
        controller.upgradeNoChange = controller.upgradeNoChange + 1
        controller.upgradeLastConfirmedUI="STATS_ROW_UNCHANGED"
        controller.upgradeStage = "Stats UI unchanged; no repeated purchase"
    end
    writeLog("Upgrade feedback: " .. controller.upgradeStage ..
        " | " .. pending.stat .. " | event=" .. pending.event)
    if controller.upgradeNoChange >= 1 then
        controller.upgrade = false
        controller.upgradeStage = "PAUSED: no Stats UI change; no repeated purchase"
        writeLog("AUTO UPGRADE paused; press COPY UPGRADE DIAGNOSTICS.")
    end
end

local function actionDiagnosticReport()
    scanActionButtons()
    local lines = {
        "MY ANIME MINE V0.23 EQUIP / UPGRADE TARGETS + SHOP SELL | " .. os.date("%H:%M:%S"),
        "PlaceId=" .. tostring(game.PlaceId) ..
            " | plot=" .. tostring(controller.selectedPlot) ..
            " | equip=" .. tostring(controller.equip) ..
            " upgrade=" .. tostring(controller.upgrade),
        ("GUI visible buttons=%d | equip=%d inventory=%d stats=%d statUpgrades=%d"):format(
            controller.actionGuiCount or 0,
            #controller.equipCandidates, #controller.inventoryCandidates,
            #controller.statsCandidates, #controller.upgradeCandidates),
        "Equip stage=" .. tostring(controller.equipStage) ..
            " | attempts=" .. controller.equipAttempts ..
            " callsOK=" .. controller.equipActions ..
            " inventoryOpens=" .. controller.inventoryOpenAttempts,
        "Upgrade stage=" .. tostring(controller.upgradeStage) ..
            " | lastTick=" .. tostring(controller.upgradeLastTick) ..
            " | attempts=" .. controller.upgradeAttempts ..
            " callsOK=" .. controller.upgradeActions ..
            " unchanged=" .. controller.upgradeNoChange ..
            " holderClicks=" .. controller.holderActions .. "/" .. controller.holderAttempts,
        "Selected holder=" .. (controller.openedHolder and describe(controller.openedHolder) or "none"),
        "Inventory target=" .. tostring(controller.inventoryLastTarget),
        "Headless mode=" .. tostring(controller.headlessOnly) ..
            " | equipStatus=" .. tostring(controller.headlessEquipStatus) ..
            " | upgradeStatus=" .. tostring(controller.headlessUpgradeStatus) ..
            " | equipTarget=" .. tostring(controller.headlessEquipTarget),
        "Upgrade walk=" .. tostring(controller.upgradeWalkTarget ~= nil) ..
            " | attempts=" .. tostring(controller.upgradeWalkAttempts) ..
            " lastTarget=" .. tostring(controller.upgradeWalkLastTarget),
        "Executor: firesignal=" .. tostring(type(firesignal) == "function") ..
            " fireclickdetector=" .. tostring(type(fireclickdetector) == "function") ..
            " getconnections=" .. tostring(type(getconnections) == "function"),
    }
    local function addButtons(name, items)
        for i = 1, math.min(16, #items) do
            local button = items[i]
            local connections = takeAllConnections(button)
            lines[#lines + 1] = name .. "[" .. i .. "]: " .. describe(button)
                .. " | label=" .. actionLabel(button):sub(1, 90)
                .. " | stat=" .. tostring(statContext(button))
                .. " | clickedListeners=" .. tostring(connections.MouseButton1Click)
                .. " activatedListeners=" .. tostring(connections.Activated)
        end
    end
    addButtons("EquipBest", controller.equipCandidates)
    addButtons("Inventory", controller.inventoryCandidates)
    addButtons("Stats", controller.statsCandidates)
    addButtons("Upgrade", controller.upgradeCandidates)
    addButtons("GameUpgradesMenu (read-only, not auto-purchased)", controller.guiUpgradeMenu)
    local sellButtons, sellLabels = scanNativeAutoSell()
    local tele = shopsTeleportLauncher()
    local shopsWarp, shopsCount = shopsWarpDestination()
    local vendorOptions = sellVendorTargets()
    local sellAction, sellActionCount = oreSellButton()
    lines[#lines+1] = "SHOP SELL ROUTE: phase="..tostring(controller.sellPhase)..
        " | stage="..tostring(controller.sellStage)..
        " | warpAttempts="..controller.sellWarpAttempts..
        " | ShopsClicks="..controller.sellShopsAttempts..
        " | walks="..controller.sellWalkAttempts..
        " | vendorInteractions="..controller.sellVendorAttempts..
        " | sells="..controller.sellCallsOK.."/"..controller.sellAttempts
    lines[#lines+1] = "TeleportButton="..(tele and describe(tele) or "NOT FOUND")..
        " | Shops candidates="..shopsCount..
        " | selected Shops="..(shopsWarp and describe(shopsWarp) or "NONE")
    lines[#lines+1] = "Sell vendor candidates="..#vendorOptions
    for i=1,math.min(16,#vendorOptions) do
        local v=vendorOptions[i]
        lines[#lines+1] = ("Vendor[%d]: %s | kind=%s | dist=%.1f | range=%.1f"):format(
            i,describe(v.target),v.type,v.distance,v.maxRange)
    end
    local _,_,sellKind=oreSellButton()
    local selectButton,selectCount=sellSelectAllButton()
    lines[#lines+1] = "Select All candidates="..selectCount..
        " | ready="..(selectButton and describe(selectButton) or "NONE")..
        " | sent="..tostring(controller.sellSelectAllSent)..
        " | callsOK="..controller.sellSelectAllCallsOK.."/"..controller.sellSelectAllAttempts..
        " | lastTarget="..tostring(controller.sellSelectAllTarget)
    lines[#lines+1] = "Ore-only Sell candidates="..sellActionCount..
        " | ready="..(sellAction and describe(sellAction) or "NONE")..
        " | mode="..tostring(sellKind)..
        " | verifiedStand="..tostring(validatedSellStandSession())
    lines[#lines+1] = "Generic Sell/Select All buttons are NOT auto-clicked: they may sell miners."
    lines[#lines + 1] = "Native Chest Auto Sell (legacy, not used by route): enabled=" .. tostring(controller.sell) ..
        " | stage=" .. tostring(controller.sellStage) ..
        " | target=" .. tostring(controller.sellTarget) ..
        " | event=" .. tostring(controller.sellEvent) ..
        " | sent=" .. tostring(controller.sellSent) ..
        " | callsOK=" .. tostring(controller.sellCallsOK) ..
        "/" .. tostring(controller.sellAttempts) ..
        " | initial=" .. tostring(controller.sellInitialState) ..
        " observed=" .. tostring(controller.sellLastObservedState)
    lines[#lines + 1] = ("Chest Auto Sell candidates=%d | matching text labels=%d"):format(
        #sellButtons, #sellLabels)
    for i, button in ipairs(sellButtons) do
        if i > 18 then break end
        local connections = takeAllConnections(button)
        lines[#lines + 1] = ("ChestSell[%d]: %s | visible=%s | label=%s | UIstate=%s | mouse=%s activated=%s"):format(
            i, describe(button), tostring(isVisible(button)), actionLabel(button):sub(1, 110),
            nativeAutoSellState(button), tostring(connections.MouseButton1Click),
            tostring(connections.Activated))
    end
    for i, label in ipairs(sellLabels) do
        if i > 18 then break end
        lines[#lines + 1] = ("ChestSellLabel[%d]: %s | visible=%s | text=%s"):format(
            i, describe(label), tostring(isVisible(label)), textOf(label):sub(1, 100))
    end
    local hiddenBest = hiddenEquipBestCandidates()
    lines[#lines + 1] = "Headless loaded Equip Best buttons=" .. tostring(#hiddenBest)
    for i, button in ipairs(hiddenBest) do
        if i > 12 then break end
        local connections = takeAllConnections(button)
        lines[#lines + 1] = ("HiddenEquip[%d]: %s | visible=%s | mouse=%s activated=%s"):format(
            i, describe(button), tostring(isVisible(button)),
            tostring(connections.MouseButton1Click), tostring(connections.Activated))
    end
    local remotes = headlessRemotes()
    lines[#lines + 1] = ("HEADLESS REMOTE DISCOVERY (read-only; total=%d, listed=%d):"):format(
        controller.headlessRemoteCount or 0, #remotes)
    for i, remote in ipairs(remotes) do
        if i > 60 then break end
        lines[#lines + 1] = ("Remote[%d]: %s | class=%s"):format(
            i, remote.path, remote.kind)
    end
    local holders = holderTargets()
    lines[#lines + 1] = "Holder last probe=" .. tostring(controller.lastHolderProbe) ..
        " | last in range=" .. tostring(controller.lastHolderProbeInRange)
    lines[#lines + 1] = "Holders on plot=" .. tostring(#holders) ..
        " | selectedPlot=" .. tostring(controller.selectedPlot) ..
        " | root=" .. tostring(rootPart() and rootPart().Position)
    for i = 1, math.min(30, #holders) do
        local h = holders[i]
        lines[#lines + 1] = ("Holder[%d]: %s | distance=%.1f maxRange=%.1f inRange=%s"):format(
            i, describe(h.detector), h.distance, h.allowed, tostring(h.inRange))
    end
    local holder, distance, closest = nextHolderDetector(true)
    lines[#lines + 1] = "Holder candidate=" .. (holder and
        (describe(holder) .. (" distance=%.1f"):format(distance)) or
        (closest and (describe(closest.detector) ..
            (" OUT OF RANGE distance=%.1f maxRange=%.1f"):format(
                closest.distance, closest.allowed)) or "NONE FOUND"))
    lines[#lines + 1] = "ALL VISIBLE GAME GUI BUTTONS (read-only):"
    for i, button in ipairs(controller.guiButtonSamples) do
        local connections = takeAllConnections(button)
        lines[#lines + 1] = ("Button[%02d]: %s | class=%s | name=%s | text=%s | context=%s | click=%s activated=%s"):format(
            i, describe(button), tostring(button.ClassName), tostring(button.Name),
            textOf(button):sub(1, 60), nearbyButtonContext(button):sub(1, 90),
            tostring(connections.MouseButton1Click), tostring(connections.Activated))
    end
    lines[#lines + 1] = "HIDDEN GAME GUI CANDIDATES (read-only; repeated Cards omitted):"
    for i, button in ipairs(controller.guiHiddenSamples) do
        lines[#lines + 1] = ("Hidden[%02d]: %s | class=%s | name=%s | text=%s | context=%s"):format(
            i, describe(button), tostring(button.ClassName), tostring(button.Name),
            textOf(button):sub(1, 45), nearbyButtonContext(button):sub(1, 75))
    end
    lines[#lines + 1] =
        "NOTE: Select All must dispatch before Sell; sale requires ore-only button or exact GingerbreadKeeper SellFrame/SellButton. No generic Sell All."
    return table.concat(lines, "\n")
end

local function sellRouteDiagnosticReport()
    local lines={
        "MY ANIME MINE V0.23 SHOP SELL ROUTE | "..os.date("%H:%M:%S"),
        "PlaceId="..tostring(game.PlaceId)..
            " | autoSell="..tostring(controller.sell)..
            " | autoCollect="..tostring(controller.collect)..
            " | plot="..tostring(controller.selectedPlot),
        "Phase="..tostring(controller.sellPhase)..
            " | Stage="..tostring(controller.sellStage),
        "Auto Farm timer="..tostring(controller.cycleEnabled)..
            " | collectEveryMinutes="..tostring(controller.cycleMinutes)..
            " | cyclePhase="..tostring(controller.cyclePhase)..
            " | cycleNumber="..tostring(controller.cycleRun)..
            " | lastTakeAllAt="..tostring(controller.cycleCollectionAt)..
            " | nextCollectAt="..tostring(controller.cycleNextAt)..
            " | secondsUntilNext="..tostring(math.max(0,math.ceil(
                controller.cycleNextAt-os.clock())))..
            " | lastReturnAt="..tostring(controller.cycleLastReturnAt)..
            " | cycleError="..tostring(controller.cycleLastError),
        "Warp button clicks="..controller.sellWarpAttempts..
            " | Shops destination clicks="..controller.sellShopsAttempts..
            " | walk commands="..controller.sellWalkAttempts..
            " | Sell vendor interactions="..controller.sellVendorAttempts..
            " | Select All clicks="..controller.sellSelectAllCallsOK.."/"..controller.sellSelectAllAttempts..
        " | Sell Ores clicks="..controller.sellCallsOK.."/"..controller.sellAttempts,
        "Last target="..tostring(controller.sellActionTarget)..
            " | Last sale mode="..tostring(controller.sellActionKind)..
            " | Select All target="..tostring(controller.sellSelectAllTarget)..
            " | selectEvent="..tostring(controller.sellSelectAllEvent)..
            " | selectSent="..tostring(controller.sellSelectAllSent)..
            " | vendor="..tostring(controller.sellVendorPath)..
            " | vendorDist="..tostring(controller.sellVendorDistance)..
            " | vendorTouched="..tostring(controller.sellVendorTouched),
        "CharacterPos="..tostring(rootPart() and rootPart().Position),
        "Return Base: originalPlot="..tostring(controller.sellReturnOriginalPlot)..
            " | status="..tostring(controller.sellReturnStatus)..
            " | verified="..tostring(controller.sellReturnVerified)..
            " | buttonClicks="..tostring(controller.sellReturnClicks)..
            " | destinationClicks="..tostring(controller.sellReturnChoiceClicks)..
            " | target="..tostring(controller.sellReturnTarget)..
            " | distanceBefore="..tostring(controller.sellReturnStartDistance)..
            " | distanceNow="..tostring(controller.sellReturnCurrentDistance),
    }
    local tele=shopsTeleportLauncher()
    local shops,shopCount=shopsWarpDestination()
    local chest,chestOpen=gameChestFrame()
    local teleportCandidates=teleportLauncherCandidates()
    lines[#lines+1]="Chest handoff="..tostring(controller.sellChestHandoffState)..
        " | handoffTicks="..tostring(controller.sellChestHandoffAttempts)..
        " | collectFirst="..tostring(controller.sellHandoffNeedsCollect)..
        " | reusedRecentTakeAll="..tostring(controller.sellHandoffRecentTakeAll)..
        " | recentTakeAllAge="..tostring(controller.sellHandoffRecentAge)..
        " | lastTakeAllPlot="..tostring(controller.takeAllLastDispatchPlot)..
        " | takeAllBaseline="..tostring(controller.sellHandoffBaselineTakeAllActions)..
        " | takeAllNow="..tostring(controller.takeAllActions)..
        " | takeAllObserved="..tostring(controller.sellHandoffTakeAllObserved)..
        " | chestEmpty="..tostring(controller.sellHandoffChestEmpty)..
        " | collectWalking="..tostring(controller.moveTarget~=nil)..
        " | ChestFrame="..(chest and describe(chest) or "NOT FOUND")..
        " | chestOpen="..tostring(chestOpen)..
        " | TakeAllVisible="..tostring(findTakeAll()~=nil)..
        " | TakeAllPending="..tostring(controller.takeAllPending~=nil)
    lines[#lines+1]="TeleportButton candidates="..#teleportCandidates
    for i,button in ipairs(teleportCandidates) do
        if i>8 then break end
        local c=takeAllConnections(button)
        lines[#lines+1]="TeleportCandidate["..i.."]: "..describe(button)..
            " | visible="..tostring(isVisible(button))..
            " | mouse="..tostring(c.MouseButton1Click)..
            " activated="..tostring(c.Activated)
    end
    local base,baseCount=baseReturnDestination()
    lines[#lines+1]="Return Base visible destination candidates="..baseCount..
        " | selected="..(base and describe(base) or "NONE")
    lines[#lines+1]="Teleport button="..(tele and describe(tele) or "NOT FOUND")
    lines[#lines+1]="Shops destination candidates="..shopCount..
        " | selected="..(shops and describe(shops) or "NONE")
    local vendors=sellVendorTargets()
    lines[#lines+1]="Sell stand targets="..#vendors
    for i=1,math.min(12,#vendors) do
        local v=vendors[i]
        lines[#lines+1]=("Vendor[%d]: %s | kind=%s | distance=%.1f | maxRange=%.1f"):format(
            i,describe(v.target),v.type,v.distance,v.maxRange)
    end
    local selectButton,selectCount=sellSelectAllButton()
    lines[#lines+1]="Select All candidates="..selectCount..
        " | selected="..(selectButton and describe(selectButton) or "NONE")..
        " | selectedFirst="..tostring(controller.sellSelectAllSent)
    local action,count,kind=oreSellButton()
    lines[#lines+1]="Explicit ore-only Sell controls="..count..
        " | selected="..(action and describe(action) or "NONE")..
        " | mode="..tostring(kind)
    lines[#lines+1]="Validated SellStand session="..tostring(validatedSellStandSession())
    lines[#lines+1]="Visible game buttons related to warp/shop/sell:"
    local found=0
    for _,button in ipairs(playerGui:GetDescendants()) do
        if gameGuiButton(button) and isVisible(button) then
            local name=normalizeLabel(button.Name.." "..textOf(button))
            if name:find("teleport",1,true) or name:find("shops",1,true)
                or name:find("sell",1,true) or name:find("ore",1,true) then
                found=found+1
                if found<=35 then
                    local counts=takeAllConnections(button)
                    lines[#lines+1]="GUI["..found.."]: "..describe(button)..
                        " | text="..textOf(button):sub(1,50)..
                        " | mouse="..tostring(counts.MouseButton1Click)..
                        " activated="..tostring(counts.Activated)
                end
            end
        end
    end
    lines[#lines+1]="NOTE: Timed mode: ONE Take All -> Shops Sell -> Base verification -> wait specified minutes. Sale/credit and Plot ownership NOT verified."
    return table.concat(lines,"\n")
end

local function diagnosticReport()
    local out = {}
    local function append(v) out[#out + 1] = v end
    append("MY ANIME MINE | V0.23 TARGET DIAGNOSTICS | " .. os.date("%H:%M:%S"))
    append("PlaceId=" .. tostring(game.PlaceId) .. " | autoMine=" ..
        tostring(controller.mine) .. " autoCollect=" .. tostring(controller.collect) ..
        " autoSell=" .. tostring(controller.sell) ..
        " autoEquip=" .. tostring(controller.equip) .. " autoUpgrade=" .. tostring(controller.upgrade))
    append("Shop Sell=" .. tostring(controller.sell) ..
        " | phase=" .. tostring(controller.sellPhase) ..
        " | stage=" .. tostring(controller.sellStage) ..
        " | warp=" .. tostring(controller.sellWarpAttempts) ..
        " / Shops=" .. tostring(controller.sellShopsAttempts) ..
        " / vendor=" .. tostring(controller.sellVendorAttempts) ..
        " / walk=" .. tostring(controller.sellWalkAttempts) ..
        " | vendorTarget=" .. tostring(controller.sellVendorPath) ..
        " | selectClicks=" .. tostring(controller.sellSelectAllCallsOK)..
        "/" .. tostring(controller.sellSelectAllAttempts)..
        " | sellClicks=" .. tostring(controller.sellCallsOK) ..
        "/" .. tostring(controller.sellAttempts))
    append(("Targets: rocks=%d prompts=%d TakeAll=%d"):format(
        #controller.detectors, #controller.prompts, #controller.takeAllButtons))
    local root = rootPart()
    append("Root=" .. (root and tostring(root.Position) or "NOT FOUND"))
    local nearPlot, plotDistance, plotReason = choosePlotNearPlayer()
    append("Plot selected=" .. tostring(controller.selectedPlot) ..
        " (AUTO proximity selection; ownership NOT verified)")
    append("Plot selection reason=" .. tostring(controller.plotSelectionReason))
    append("Auto Equip=" .. tostring(controller.equip) ..
        " stage=" .. tostring(controller.equipStage) .. " calls=" ..
        tostring(controller.equipActions) .. "/" .. tostring(controller.equipAttempts))
    append("Headless only=" .. tostring(controller.headlessOnly) ..
        " | status=" .. tostring(controller.headlessEquipStatus) ..
        " / " .. tostring(controller.headlessUpgradeStatus))
    append("Auto Upgrade=" .. tostring(controller.upgrade) ..
        " stage=" .. tostring(controller.upgradeStage) .. " calls=" ..
        tostring(controller.upgradeActions) .. "/" .. tostring(controller.upgradeAttempts))
    append("Upgrade move target=" .. tostring(controller.upgradeWalkLastTarget) ..
        " | move attempts=" .. tostring(controller.upgradeWalkAttempts) ..
        " | navigating=" .. tostring(controller.upgradeWalkTarget ~= nil))
    append("Closest upgrade plot=" .. (nearPlot and
        (nearPlot .. (" dist=%.1f"):format(plotDistance)) or tostring(plotReason)))
    local chest, chestDistance, chestReason = selectedChest()
    append("Selected chest=" .. (chest and
        (describe(chest) .. (" dist=%.1f maxRange=%.1f enabled=%s"):format(
            chestDistance, chestRange(chest), tostring(chest.Enabled))) or tostring(chestReason)))
    append("Auto Walk=" .. tostring(controller.walkToChest) .. " | stage=" ..
        tostring(controller.collectionStage) .. " | MoveTo attempts=" .. controller.moveAttempts)
    local nearMine, distMine, whyMine = nearest(controller.detectors, 70)
    local nearCollect, distCollect, whyCollect = nearest(controller.prompts, 30)
    append("Mine candidate: " .. (nearMine and
        (describe(nearMine) .. (" distance=%.1f"):format(distMine)) or tostring(whyMine)))
    append("Collect candidate: " .. (nearCollect and
        (describe(nearCollect) .. (" distance=%.1f"):format(distCollect)) or tostring(whyCollect)))
    local button = findTakeAll()
    append("TakeAll visible: " .. (button and describe(button) or "NONE"))
    append("TakeAll feedback=" .. tostring(controller.takeAllOutcome) ..
        " | lastEvent=" .. tostring(controller.takeAllLastEvent) ..
        " | noChange=" .. tostring(controller.takeAllNoChange) ..
        " | withoutCountDecrease=" .. tostring(controller.takeAllNotDecreased) ..
        " | pending=" .. tostring(controller.takeAllPending ~= nil))
    append("Chest count before=" .. tostring(controller.lastChestCountBefore) ..
        " after=" .. tostring(controller.lastChestCountAfter) ..
        " delta=" .. tostring(controller.lastChestCountDelta))
    append("Reopen status=" .. tostring(controller.takeAllReopenStatus) ..
        " | previousCount=" .. tostring(controller.lastReopenBefore) ..
        " currentCount=" .. tostring(controller.lastReopenAfter) ..
        " | inconclusive=" .. tostring(controller.takeAllUnverifiedReopens))
    append("Reopen cooldown=" .. tostring(controller.takeAllCooldownSeconds) ..
        "s | waiting=" .. tostring(controller.takeAllReopenAt > os.clock()) ..
        " | expectedNextCountFrom=" .. tostring(controller.takeAllClosedBeforeCount))
    append("Manual watch=" .. tostring(controller.watchManual) ..
        " | manualClickCount=" .. tostring(controller.manualClickCount) ..
        " | pending=" .. tostring(controller.manualPending ~= nil))
    append("Manual TakeAll feedback=" .. tostring(controller.manualOutcome) ..
        " | before=" .. tostring(controller.manualBefore) ..
        " after=" .. tostring(controller.manualAfter) ..
        " delta=" .. tostring(controller.manualDelta))
    if button then
        local connections = takeAllConnections(button)
        append("TakeAll event connections (getconnections; '?' means unavailable): Activated=" ..
            tostring(connections.Activated) .. " MouseButton1Click=" ..
            tostring(connections.MouseButton1Click))
        append("Chest count NOW=" .. tostring(chestItemCount(button)) .. " (UI count, not inventory)")
        append("Chest UI labels (read-only, truncated): " .. chestSnapshot(button):sub(1, 1600))
    end
    append("Executor: fireclickdetector=" .. tostring(type(fireclickdetector) == "function")
        .. " fireproximityprompt=" .. tostring(type(fireproximityprompt) == "function")
        .. " firesignal=" .. tostring(type(firesignal) == "function"))
    append(("Dispatch attempts: mine=%d collect=%d TakeAll=%d; call OK: mine=%d collect=%d TakeAll=%d"):format(
        controller.mineAttempts, controller.collectAttempts, controller.takeAllAttempts,
        controller.mineActions, controller.collectActions, controller.takeAllActions))
    for i = 1, math.min(12, #controller.prompts) do
        local item = controller.prompts[i]
        append("Prompt " .. i .. ": " .. describe(item) .. " | action=" .. tostring(item.ActionText))
    end
    for i = 1, math.min(12, #controller.takeAllButtons) do
        local item = controller.takeAllButtons[i]
        append("TakeAll " .. i .. ": " .. describe(item) .. " | visible=" .. tostring(isVisible(item)))
    end
    append("NOTE: manual Take All closes Chest too; post-reopen count is only a proxy. Actual inventory is still unverified.")
    return table.concat(out, "\n")
end

local function refreshStatus()
    if not controller.running then return end
    local timerInfo = controller.cyclePhase
    if controller.cycleEnabled and controller.cyclePhase=="WAITING" then
        local remaining=math.max(0,math.ceil(controller.cycleNextAt-os.clock()))
        timerInfo=("NEXT %02d:%02d"):format(math.floor(remaining/60),remaining%60)
    end
    farmCycleButton.Text = "AUTO FARM: " .. (controller.cycleEnabled
        and (controller.cyclePhase=="PAUSED" and "PAUSED" or "ON / "..timerInfo)
        or "OFF")
    farmCycleButton.BackgroundColor3 = controller.cycleEnabled
        and palette.accent or palette.button
    mineButton.Text = "AUTO MINE (CLICK): " .. (controller.mine and "ON" or "OFF")
    collectButton.Text = "AUTO COLLECT: " .. (controller.collect and "ON" or "OFF")
    mineButton.BackgroundColor3 = controller.mine and palette.accent or palette.button
    collectButton.BackgroundColor3 = controller.collect and palette.accent or palette.button
    autoPlotLabel.Text = "PLOT: " .. tostring(controller.selectedPlot or "SEARCHING") ..
        ("  |  EVERY %d MIN  |  %s"):format(controller.cycleMinutes,timerInfo)
    manualWatchButton.Text = "WATCH TAKE ALL: " .. (controller.watchManual and "ON" or "OFF")
    local sellIndicator = controller.sellPhase == "RETURNED_BASE" and "RETURNED"
        or not controller.sell and "OFF"
        or (controller.sellPhase == "RETURN_BASE_OPEN"
            or controller.sellPhase == "RETURN_BASE_WAIT") and "RETURNING"
        or controller.sellPhase == "DONE" and "SENT"
        or controller.sellPhase == "PAUSED" and "PAUSED" or "ROUTING"
    sellButton.Text = "AUTO SELL ORES: " .. sellIndicator
    sellButton.BackgroundColor3 = controller.sell and palette.accent or palette.button
    manualWatchButton.BackgroundColor3 = controller.watchManual and palette.accent or palette.button
    equipButton.Text = "AUTO EQUIP BEST: " .. (controller.equip and "ON" or "OFF")
    upgradeButton.Text = "AUTO UPGRADE STATS: " ..
        (controller.upgrade and (controller.upgradeStage:find("PAUSED",1,true) and "PAUSED" or "ON") or "OFF")
    equipButton.BackgroundColor3 = controller.equip and palette.accent or palette.button
    upgradeButton.BackgroundColor3 = controller.upgrade and palette.accent or palette.button
    statusLabel.Text = ("Cycle #%d | %s | Take All %d | Sell clicks %d\nCollect: %s\nSell/Base: %s\nUpgrade: %s"):format(
        controller.cycleRun,tostring(controller.cyclePhase),
        controller.takeAllActions,controller.sellCallsOK,
        tostring(controller.collectionStage):sub(1,69),
        tostring(controller.sellStage):sub(1,69),
        tostring(controller.upgradeStage):sub(1,69))
end

connect(mineButton.Activated, function()
    if type(fireclickdetector) ~= "function" then
        writeLog("Auto Mine unavailable: executor has no fireclickdetector")
        return
    end
    controller.mine = not controller.mine
    writeLog("Auto Mine (rock click) " .. (controller.mine and "ON" or "OFF") ..
        " | characters normally mine rocks without clicking them")
    refreshStatus()
end)
connect(equipButton.Activated, function()
    if type(firesignal) ~= "function" then
        writeLog("Auto Equip unavailable: executor has no firesignal")
        return
    end
    controller.equip = not controller.equip
    if controller.equip then
        controller.inventoryOpenAttempts = 0
        controller.equipStage = "Looking for Equip Best"
        scanActionButtons()
    else
        controller.equipStage = "OFF"
    end
    writeLog("AUTO EQUIP BEST " .. (controller.equip and "ON" or "OFF") ..
        " | HEADLESS ONLY: no Inventory UI opens")
    refreshStatus()
end)
connect(upgradeButton.Activated, function()
    if type(firesignal) ~= "function" or type(fireclickdetector) ~= "function" then
        writeLog("Auto Upgrade requires firesignal and fireclickdetector")
        return
    end
    controller.upgrade = not controller.upgrade
    if controller.upgrade then
        stopUpgradeWalking()
        controller.upgradeStage = "Finding selected-plot miner Stats"
        controller.upgradeLastTick = nil
        controller.lastHolderProbe = "none"
        controller.lastHolderProbeInRange = "none"
        controller.upgradeAttempts = 0
        controller.upgradeNoChange = 0
        controller.upgradePending = nil
        controller.upgradeIndex = 1
        controller.holderIndex = 1
        controller.holderNextAt = 0
        controller.openedHolder = nil
        controller.statsTabAttempted = false
        autoSelectPlot()
        scanActionButtons()
    else
        stopUpgradeWalking()
        controller.upgradePending = nil
        controller.upgradeStage = "OFF"
    end
    writeLog("AUTO UPGRADE STATS " .. (controller.upgrade and "ON" or "OFF") ..
        " | HEADLESS ONLY: remote command requires verified protocol; no UI opens")
    refreshStatus()
end)
connect(actionDiagnosticsButton.Activated, function()
    local report = actionDiagnosticReport()
    if type(setclipboard) == "function" then
        local ok, err = pcall(setclipboard, report)
        writeLog(ok and "Equip/Upgrade targets copied" or ("Target copy ERROR: " .. tostring(err)))
    else
        print(report)
        writeLog("Clipboard unavailable; Equip/Upgrade targets printed to console")
    end
end)
-- Single entry point for both manual sell tests and the timed farm.
-- The scheduled path may already have completed the current Chest Take All,
-- so it must not reopen that Chest during handoff.
local function armSellRoute(now,source)
    if controller.sell then return false end
    controller.sell = true
    sellStopWalk()
    controller.sellRouteSource = source or "MANUAL"
    controller.sellSent = false
    controller.sellAttempts = 0
    controller.sellCallsOK = 0
    controller.sellWarpAttempts = 0
    controller.sellChestHandoffAttempts = 0
    controller.sellChestHandoffState = "STARTING"
    controller.sellHandoffNeedsCollect = controller.collect
    controller.sellHandoffBaselineTakeAllActions = controller.takeAllActions
    controller.sellHandoffTakeAllObserved = false
    controller.sellHandoffRecentTakeAll = false
    controller.sellHandoffRecentAge = nil
    controller.sellHandoffChestEmpty = false
    controller.sellShopsAttempts = 0
    controller.sellVendorAttempts = 0
    controller.sellVendorTouched = false
    controller.sellWalkAttempts = 0
    controller.sellVendorPath = "none"
    controller.sellActionTarget = "none"
    controller.sellSelectAllTarget = "none"
    controller.sellSelectAllAttempts = 0
    controller.sellSelectAllCallsOK = 0
    controller.sellSelectAllSent = false
    controller.sellSelectAllAt = 0
    controller.sellSelectAllEvent = "none"
    controller.sellActionKind = nil
    controller.sellReturnTarget = "none"
    controller.sellReturnOriginalPlot = controller.selectedPlot
    controller.sellReturnOrigin = nil
    controller.sellReturnStartDistance = nil
    controller.sellReturnCurrentDistance = nil
    controller.sellReturnClicks = 0
    controller.sellReturnChoiceClicks = 0
    controller.sellReturnVerified = false
    controller.sellReturnStatus = "NOT_STARTED"
    controller.sellReturnCloseSent = false
    controller.sellWarpOrigin = nil
    controller.sellStartedAt = now
    if controller.sellHandoffNeedsCollect then
        local reused,age=recentTakeAllForHandoff(now)
        controller.sellHandoffRecentTakeAll=reused
        controller.sellHandoffRecentAge=age
        if reused then
            controller.sellHandoffTakeAllObserved=true
            writeLog(("SHOP SELL: Reusing recent Take All sent %.1fs ago on %s; inventory still unverified"):format(
                age,tostring(controller.selectedPlot)))
        end
    end
    sellSetPhase("CHEST_HANDOFF",
        controller.sellHandoffRecentTakeAll and
            "Recent Take All dispatched; waiting for Chest and pending feedback to clear"
        or controller.sellHandoffNeedsCollect and
            "Finishing Auto Collect before Shops"
        or "Checking Chest before Shops",now)
    -- Do not cancel an already-running Chest walk. It must finish Take All
    -- (or time out safely) before Shops takes ownership of movement.
    if not controller.sellHandoffNeedsCollect then stopWalking() end
    return true
end

connect(sellButton.Activated, function()
    if controller.sell then
        controller.sell=false
        sellStopWalk()
        controller.sellPhase="OFF"
        controller.sellStage="OFF (shop route stopped)"
        writeLog("SHOP SELL OFF. Auto Collect can resume after returning to your Plot.")
    else
        armSellRoute(os.clock(),"MANUAL")
    end
    refreshStatus()
end)
connect(sellDiagnosticsButton.Activated, function()
    local report=sellRouteDiagnosticReport()
    if type(setclipboard)=="function" then
        local ok,err=pcall(setclipboard,report)
        writeLog(ok and "Sell route diagnostics copied" or ("Sell route copy ERROR: "..tostring(err)))
    else
        print(report)
        writeLog("Clipboard unavailable; sell route report printed to console")
    end
end)
connect(manualWatchButton.Activated, function()
    if not controller.watchManual and controller.collect then
        writeLog("Turn Auto Collect OFF before watching a manual Take All.")
        return
    end
    controller.watchManual = not controller.watchManual
    controller.manualPending = nil
    if controller.watchManual then
        controller.manualOutcome = "WAITING_FOR_GAME_BUTTON"
        writeLog("MANUAL TEST ON. Open Chest manually and click Take All. Auto Collect must remain OFF.")
        monitorManualButton()
    else
        stopManualMonitor()
        writeLog("Manual Take All watch OFF.")
    end
    refreshStatus()
end)
connect(collectButton.Activated, function()
    if type(fireproximityprompt) ~= "function" and type(firesignal) ~= "function" then
        writeLog("Auto Collect unavailable: requires fireproximityprompt or firesignal")
        return
    end
    if controller.watchManual and not controller.collect then
        writeLog("Turn WATCH MANUAL TAKE ALL OFF before enabling Auto Collect.")
        return
    end
    controller.collect = not controller.collect
    controller.walkToChest = controller.collect
    if controller.collect then
        scan(false)
        autoSelectPlot()
        controller.takeAllNoChange = 0
        controller.takeAllNotDecreased = 0
        controller.lastChestCountBefore = nil
        controller.lastChestCountAfter = nil
        controller.lastChestCountDelta = nil
        controller.takeAllPending = nil
        controller.takeAllMethodIndex = 1
        controller.takeAllAttempts = 0
        controller.takeAllOutcome = "NOT TESTED"
        controller.takeAllReopenAt = 0
        controller.takeAllClosedBeforeCount = nil
        controller.takeAllReopenStatus = "NOT TESTED"
        controller.takeAllUnverifiedReopens = 0
        controller.lastReopenBefore = nil
        controller.lastReopenAfter = nil
    end
    if not controller.collect then
        stopWalking()
        controller.collectionStage = "OFF"
    end
    writeLog("Auto Collect " .. (controller.collect and "ON" or "OFF") ..
        " | plot selection and Chest walking are automatic")
    refreshStatus()
end)
connect(scanButton.Activated, function()
    writeLog("Manual scan requested")
    scan(true)
    autoSelectPlot()
    scanActionButtons()
    refreshStatus()
end)
connect(detailButton.Activated, function()
    local report = diagnosticReport()
    if type(setclipboard) == "function" then
        local ok, err = pcall(setclipboard, report)
        writeLog(ok and "Target diagnostics copied" or ("Target copy failed: " .. tostring(err)))
    else
        print(report)
        writeLog("setclipboard unavailable; target diagnostics printed to console")
    end
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

writeLog("My Anime Mine v0.23 started | timed Farm and safe Stats Upgrade | toggles OFF | PlaceId 79389059854988")
writeLog("AUTO PLOT and AUTO WALK are built into Auto Collect; no manual Set Plot or Walk toggle.")
writeLog("No undocumented remotes fired. Dispatch OK does not prove a reward.")
scan(true)
autoSelectPlot()
refreshStatus()

-- Timed mode performs ONE collection attempt per interval. Collection
-- remains paused during selling and while waiting for the next due time.
local function collectIntervalSeconds()
    return controller.cycleMinutes*60
end

local function updateCycleMinutes(value)
    local number=tonumber(value)
    if not number or number~=number then return false end
    local minutes=math.floor(number+0.5)
    if minutes<1 then minutes=1 elseif minutes>180 then minutes=180 end
    controller.cycleMinutes=minutes
    intervalInput.Text=tostring(minutes)
    if controller.cycleEnabled and controller.cycleCollectionAt>0 then
        controller.cycleNextAt=controller.cycleCollectionAt+collectIntervalSeconds()
    end
    writeLog("AUTO FARM interval set to "..minutes.." minute(s)")
    refreshStatus()
    return true
end

local function beginCollectionCycle(now)
    if controller.sell then
        controller.cyclePhase="PAUSED"
        controller.cycleLastError="Cannot collect during active seller route"
        writeLog("AUTO FARM paused: "..controller.cycleLastError)
        return false
    end
    if not controller.selectedPlot then autoSelectPlot() end
    controller.cycleRun=controller.cycleRun+1
    controller.cyclePhase="COLLECTING"
    controller.cycleStartedAt=now
    controller.cycleCollectionBaseline=controller.takeAllActions
    controller.cycleLastError="none"
    controller.collect=true
    controller.walkToChest=true
    controller.takeAllReopenAt=math.min(controller.takeAllReopenAt or 0,now)
    writeLog(("AUTO FARM cycle %d: collecting from %s (every %d min)"):format(
        controller.cycleRun,tostring(controller.selectedPlot),controller.cycleMinutes))
    return true
end

local function updateFarmCycle(now)
    if not controller.cycleEnabled then return end
    if controller.cyclePhase=="COLLECTING" then
        if controller.takeAllActions>controller.cycleCollectionBaseline then
            local sinceDispatch=now-(controller.takeAllLastDispatchAt>0
                and controller.takeAllLastDispatchAt or controller.cycleStartedAt)
            if sinceDispatch>25 then
                controller.cyclePhase="PAUSED"
                controller.cycleLastError="Take All feedback/Chest close exceeded 25s"
                controller.collect=false
                stopWalking()
                writeLog("AUTO FARM paused: "..controller.cycleLastError)
                return
            end
            if controller.takeAllPending then
                controller.cycleLastMessage="Take All dispatched; awaiting Chest close"
                return
            end
            local _,chestOpen=gameChestFrame()
            if chestOpen then
                controller.cycleLastMessage="Waiting for Chest to close"
                return
            end
            if type(controller.takeAllOutcome)~="string" or
                not controller.takeAllOutcome:find("CHEST_CLOSED_AFTER_TAKE_ALL",1,true) then
                if now-controller.cycleStartedAt>100 then
                    controller.cyclePhase="PAUSED"
                    controller.cycleLastError="Take All result not confirmed by Chest UI"
                    controller.collect=false
                    writeLog("AUTO FARM paused: "..controller.cycleLastError)
                end
                return
            end
            controller.cycleCollectionAt=controller.takeAllLastDispatchAt>0
                and controller.takeAllLastDispatchAt or now
            controller.cycleNextAt=controller.cycleCollectionAt+collectIntervalSeconds()
            controller.cyclePhase="SELLING"
            controller.cycleLastMessage="Collect sent; go sell at Shops"
            if not armSellRoute(now,"TIMED_FARM") then
                controller.cyclePhase="PAUSED"
                controller.cycleLastError="Another sale is already active"
                writeLog("AUTO FARM paused: "..controller.cycleLastError)
                return
            end
            -- This cycle already dispatched and settled its Take All. Reusing
            -- it prevents the older manual handoff from reopening Chest.
            controller.sellHandoffTakeAllObserved=true
            controller.sellHandoffNeedsCollect=true
            writeLog(("AUTO FARM cycle %d: Take All UI settled; Shops sale armed; next due in %ds"):format(
                controller.cycleRun,math.max(0,math.floor(controller.cycleNextAt-now))))
            return
        end
        if now-controller.cycleStartedAt>90 then
            controller.cyclePhase="PAUSED"
            controller.cycleLastError="No Chest Take All within 90s"
            controller.collect=false
            stopWalking()
            writeLog("AUTO FARM paused: "..controller.cycleLastError)
        end
    elseif controller.cyclePhase=="SELLING" then
        if controller.sellPhase=="PAUSED" then
            controller.cyclePhase="PAUSED"
            controller.cycleLastError=tostring(controller.sellStage)
            writeLog("AUTO FARM paused at Shops/Base: "..controller.cycleLastError)
        elseif controller.sellPhase=="RETURNED_BASE" and controller.sellReturnVerified then
            controller.cyclePhase="WAITING"
            controller.cycleLastReturnAt=now
            if controller.cycleNextAt<=0 then
                controller.cycleNextAt=now+collectIntervalSeconds()
            end
        end
    elseif controller.cyclePhase=="WAITING" then
        if not controller.sell and now>=controller.cycleNextAt
            and now-controller.cycleLastReturnAt>=1.5 then
            beginCollectionCycle(now)
        end
    end
end

local function setFarmCycleEnabled(enabled,now)
    if enabled==controller.cycleEnabled then return end
    if enabled and controller.sell then
        writeLog("AUTO FARM: stop the current Sell route before enabling timed farming.")
        return
    end
    if enabled and (type(fireproximityprompt)~="function"
        or type(firesignal)~="function") then
        writeLog("AUTO FARM unavailable: executor requires fireproximityprompt and firesignal")
        return
    end
    controller.cycleEnabled=enabled
    if enabled then
        controller.cycleRun=0
        controller.cycleNextAt=0
        controller.cycleCollectionAt=0
        controller.cycleLastReturnAt=0
        scan(false)
        autoSelectPlot()
        beginCollectionCycle(now)
    else
        controller.cyclePhase="OFF"
        controller.cycleNextAt=0
        controller.cycleLastError="none"
        controller.collect=false
        controller.walkToChest=false
        if controller.sell then
            controller.sell=false
            controller.sellPhase="OFF"
            controller.sellStage="Stopped by Auto Farm OFF"
        end
        sellStopWalk()
        stopWalking()
        writeLog("AUTO FARM stopped; all scheduled collection and sale commands OFF")
    end
    refreshStatus()
end

connect(farmCycleButton.Activated,function()
    setFarmCycleEnabled(not controller.cycleEnabled,os.clock())
end)
connect(minuteMinusButton.Activated,function()
    updateCycleMinutes(controller.cycleMinutes-1)
end)
connect(minutePlusButton.Activated,function()
    updateCycleMinutes(controller.cycleMinutes+1)
end)
connect(intervalInput.FocusLost,function()
    if not updateCycleMinutes(intervalInput.Text) then
        intervalInput.Text=tostring(controller.cycleMinutes)
        writeLog("Invalid collection interval; enter 1-180 whole minutes")
    end
end)

local function canCollectDuringSell()
    if controller.cycleEnabled and controller.cyclePhase~="COLLECTING" then
        return false
    end
    return not controller.sell
        or (controller.sellPhase == "CHEST_HANDOFF"
            and controller.sellHandoffNeedsCollect
            and controller.takeAllActions <= controller.sellHandoffBaselineTakeAllActions
            and not controller.sellHandoffTakeAllObserved
            and not controller.sellHandoffChestEmpty)
end

task.spawn(function()
    local lastScan, lastMine, lastCollect, lastStatus = os.clock(), 0, 0, 0
    local lastEquipTick, lastUpgradeTick, lastActionScan = 0, 0, 0
    local lastMineReason, lastCollectReason = "", ""
    local lastAutoPlotCheck = 0
    local lastMineLog, lastCollectLog = 0, 0
    while controller.running do
        task.wait(0.35)
        local now = os.clock()
        if now - lastScan >= 6 then
            lastScan = now
            scan(false)
        end
        if controller.mine and now - lastMine >= 0.85 then
            lastMine = now
            local target, dist, reason = nearest(controller.detectors, 70)
            if target and type(fireclickdetector) == "function" then
                controller.mineAttempts = controller.mineAttempts + 1
                local ok, err = pcall(fireclickdetector, target)
                if ok then controller.mineActions = controller.mineActions + 1
                else writeLog("Mine click ERROR: " .. tostring(err)) end
                if now - lastMineLog >= 7 then
                    lastMineLog = now
                    writeLog(("Mine CLICK dispatched to %s (%.1f studs); attempts=%d; not confirmed reward"):format(
                        describe(target), dist, controller.mineAttempts))
                end
                lastMineReason = ""
            else
                reason = reason or "fireclickdetector not available"
                if reason ~= lastMineReason or now - lastMineLog >= 10 then
                    lastMineLog, lastMineReason = now, reason
                    writeLog("Mine idle: " .. reason .. " | scanned=" .. #controller.detectors)
                end
            end
        end
        if controller.watchManual then
            if controller.equip then controller.equipStage = "Paused for manual Take All test" end
            if controller.upgrade then controller.upgradeStage = "Paused for manual Take All test" end
        end
        if (controller.equip or controller.upgrade) and now - lastActionScan >= 2.8 then
            lastActionScan = now
            scanActionButtons()
        end

        -- Keep Auto Collect's existing implementation intact. Shop
        -- navigation is a separate route and owns movement only while armed.
        if controller.sell and not controller.watchManual
            and now - (controller.sellLastTick or 0) >= 1.7 then
            controller.sellLastTick = now
            shopSellStep(now)
        end

        -- V0.12: no automatic game UI windows. An actual loaded hidden
        -- Equip Best control may be dispatched directly if it has a listener.
        if controller.equip and not controller.watchManual
            and now - lastEquipTick >= 6 then
            lastEquipTick = now
            if now - (controller.lastEquipAt or 0) >= 20 then
                local ok, status = tryHeadlessEquip()
                controller.headlessEquipStatus = status
                controller.equipStage = status
                controller.lastEquipAt = now
                if ok then
                    controller.equipAttempts = controller.equipAttempts + 1
                    controller.equipActions = controller.equipActions + 1
                    writeLog("HEADLESS EQUIP: " .. status ..
                        " | target=" .. controller.headlessEquipTarget ..
                        " | result not verified")
                elseif status ~= controller.lastHeadlessEquipMessage then
                    controller.lastHeadlessEquipMessage = status
                    writeLog("HEADLESS EQUIP: " .. status ..
                        " | no Inventory window opened")
                end
            end
        end

        -- Use only real loaded crew Stats buttons with active native
        -- callbacks. Unknown RemoteEvents and premium/gamepass controls
        -- remain read-only. During Farm, upgrade only while idle at Base.
        if controller.upgradePending then resolveUpgradeFeedback(now) end
        if controller.upgrade and not controller.watchManual
            and now-lastUpgradeTick>=8 then
            lastUpgradeTick=now
            headlessUpgradeStep(now)
            if controller.headlessUpgradeStatus~=controller.lastHeadlessUpgradeMessage then
                controller.lastHeadlessUpgradeMessage=controller.headlessUpgradeStatus
                if controller.upgradeStage:find("NO_LOADED",1,true)
                    or controller.upgradeStage:find("MULTIPLE_",1,true)
                    or controller.upgradeStage:find("AMBIGUOUS_",1,true) then
                    writeLog("AUTO UPGRADE: "..controller.upgradeStage..
                        " | use COPY UPGRADE DIAGNOSTICS; no purchase dispatched")
                end
            end
        end
        if controller.watchManual then monitorManualButton() end
        if controller.manualPending then settleManualTakeAll(now) end
        if controller.takeAllPending then settleTakeAll(now) end
        updateFarmCycle(now)
        if not controller.selectedPlot and now - lastAutoPlotCheck >= 5 then
            lastAutoPlotCheck = now
            autoSelectPlot()
        end
        -- Holder travel gets a short exclusive movement window. The working
        -- Auto Collect loop is otherwise unchanged and resumes afterward.
        -- During handoff only the already-visible Take All control may run.
        -- Do not walk back to Chest or open Chest after sale was requested.
        if controller.collect and canCollectDuringSell()
            and not controller.upgradeWalkTarget
            and now >= (controller.upgradeBusyUntil or 0)
            and now - lastCollect >= 1.25 then
            lastCollect = now
            local action = "none"
            local button = findTakeAll()
            if not controller.selectedPlot then
                controller.collectionStage = "AUTO PLOT SEARCH: " .. tostring(controller.plotSelectionReason)
            elseif now < controller.takeAllReopenAt then
                controller.collectionStage = ("Chest closed normally; reopen in %.1fs"):format(
                    controller.takeAllReopenAt - now)
            elseif button and type(firesignal) == "function" then
                -- A visible Chest after cooldown is the only nonstale count
                -- used to judge the prior Take All attempt.
                if controller.takeAllClosedBeforeCount ~= nil then
                    observeReopenedChest(button)
                end
                if controller.collect then
                -- Do not assume a success return from firesignal means a server-side reward.
                stopWalking()
                controller.collectionStage = controller.takeAllPending and
                    "Waiting for Take All UI feedback" or "Take All visible"
                if not controller.takeAllPending and now >= controller.takeAllNextAt then
                    controller.takeAllNextAt = now + 3.5
                    local eventName, counts = chooseTakeAllEvent(button)
                    controller.takeAllLastEvent = eventName
                    controller.takeAllAttempts = controller.takeAllAttempts + 1
                    local snapshot = chestSnapshot(button)
                    local beforeCount = chestItemCount(button)
                    -- Avoid clicking an already-empty chest.
                    if beforeCount == 0 then
                        controller.takeAllAttempts = controller.takeAllAttempts - 1
                        if controller.sell and controller.sellPhase == "CHEST_HANDOFF"
                            and controller.sellHandoffNeedsCollect then
                            controller.sellHandoffChestEmpty = true
                        end
                        controller.collectionStage = "Chest empty: wait for mined items"
                        action = "CHEST EMPTY, Take All not dispatched"
                    else
                        local ok, err = pcall(firesignal, button[eventName])
                        if ok then
                            controller.takeAllActions = controller.takeAllActions + 1
                            controller.takeAllLastDispatchAt = now
                            controller.takeAllLastDispatchPlot = controller.selectedPlot
                            controller.takeAllPending = {
                                button = button, before = snapshot, beforeCount = beforeCount,
                                sentAt = now, event = eventName,
                            }
                            action = "TAKE ALL dispatched (" .. eventName .. ") " .. describe(button) ..
                                " | connections=" .. tostring(counts[eventName])
                        else
                            action = "Take All " .. eventName .. " ERROR " .. tostring(err)
                            controller.takeAllOutcome = "DISPATCH_ERROR"
                        end
                    end
                end
                end
            else
                local chest, dist, reason = selectedChest()
                if not chest then
                    stopWalking()
                    controller.collectionStage = tostring(reason)
                elseif chest.Enabled == false then
                    stopWalking()
                    controller.collectionStage = "ChestPrompt disabled in " .. controller.selectedPlot
                elseif dist <= chestRange(chest) then
                    stopWalking()
                    controller.collectionStage = "Opening " .. controller.selectedPlot .. " Chest"
                    if type(fireproximityprompt) == "function"
                        and now - (controller.lastOpen or 0) >= 3 then
                        controller.lastOpen = now
                        controller.collectAttempts = controller.collectAttempts + 1
                        local ok, err = pcall(fireproximityprompt, chest)
                        if ok then
                            controller.collectActions = controller.collectActions + 1
                            action = ("OPEN CHEST %s (%.1f studs; waiting for Take All)"):format(
                                describe(chest), dist)
                        else
                            action = "Chest open ERROR " .. tostring(err)
                        end
                    end
                else
                    controller.collectionStage = approachChest(chest, dist, now)
                end
            end
            local message = action ~= "none" and action or controller.collectionStage
            if message ~= lastCollectReason or now - lastCollectLog >= 10 then
                lastCollectLog, lastCollectReason = now, message
                writeLog("Collect: " .. message .. " | prompt-dispatch=" ..
                    controller.collectActions .. " chest-dispatch=" .. controller.takeAllActions)
            end
        end
        if now - lastStatus >= 0.75 then
            lastStatus = now
            refreshStatus()
        end
    end
end)
