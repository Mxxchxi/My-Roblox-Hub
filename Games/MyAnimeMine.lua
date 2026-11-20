-- My Roblox Hub | My Anime Mine v0.11 (live Inventory launcher and Holder action diagnostics)
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
    equip = false,
    upgrade = false,
    equipAttempts = 0,
    equipActions = 0,
    inventoryOpenAttempts = 0,
    inventoryLastTarget = "none",
    equipStage = "OFF",
    upgradeAttempts = 0,
    upgradeActions = 0,
    upgradeNoChange = 0,
    upgradeIndex = 1,
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
    Name = "Main", Size = UDim2.fromOffset(510, 648),
    Position = UDim2.new(0.5, -255, 0.5, -324),
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
    Name = "Description", Position = UDim2.fromOffset(16, 61),
    Size = UDim2.fromOffset(480, 34),
    BackgroundTransparency = 1, Font = Enum.Font.Gotham, TextSize = 12,
    TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left,
    TextColor3 = palette.subtle,
    Text = "V0.11 | Detect Inventory hotbar button and verify Holder upgrade actions. Auto Collect preserved.",
})
local mineButton = button("AutoMine", "AUTO MINE (CLICK): OFF", 16, 104, 230, 41)
local collectButton = button("AutoCollect", "AUTO COLLECT: OFF", 264, 104, 230, 41)
local scanButton = button("Scan", "SCAN GAME", 16, 158, 230, 38)
local copyButton = button("CopyLog", "COPY LOG", 264, 158, 230, 38)
local detailButton = button("Diagnostics", "COPY TARGET DIAGNOSTICS", 16, 205, 478, 38)
local autoPlotLabel = make("TextLabel", panel, {
    Name = "AutoPlotStatus", Position = UDim2.fromOffset(16, 250),
    Size = UDim2.fromOffset(478, 38),
    BackgroundColor3 = palette.panel,
    BorderSizePixel = 0,
    Font = Enum.Font.GothamSemibold, TextSize = 12,
    TextXAlignment = Enum.TextXAlignment.Center,
    TextColor3 = palette.subtle,
    Text = "PLOT: AUTO DETECT  |  WALK: AUTO WITH COLLECT",
})
make("UICorner", autoPlotLabel, { CornerRadius = UDim.new(0, 7) })
local equipButton = button("AutoEquip", "AUTO EQUIP BEST: OFF", 16, 298, 230, 38)
local upgradeButton = button("AutoUpgrade", "AUTO UPGRADE STATS: OFF", 264, 298, 230, 38)
local manualWatchButton = button("ManualWatch", "WATCH MANUAL TAKE ALL: OFF", 16, 345, 478, 38)
local actionDiagnosticsButton = button("ActionDiagnostics", "COPY EQUIP / UPGRADE TARGETS", 16, 393, 478, 38)
local statusLabel = make("TextLabel", panel, {
    Name = "Status", Position = UDim2.fromOffset(17, 437),
    Size = UDim2.fromOffset(478, 65),
    BackgroundTransparency = 1, Font = Enum.Font.Code, TextSize = 12,
    TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left,
    TextColor3 = palette.accent, Text = "Discovering...",
})
make("TextLabel", panel, {
    Name = "LogTitle", Position = UDim2.fromOffset(16, 507),
    Size = UDim2.fromOffset(478, 20),
    BackgroundTransparency = 1, Font = Enum.Font.GothamBold, TextSize = 13,
    TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = palette.text,
    Text = "LOG / DIAGNOSTICS",
})
local logFrame = make("Frame", panel, {
    Name = "LogPanel", Position = UDim2.fromOffset(16, 531),
    Size = UDim2.fromOffset(478, 101), BackgroundColor3 = palette.panel,
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

local function resolveUpgradeFeedback(now)
    local pending = controller.upgradePending
    if not pending or now - pending.started < 2.7 then return end
    controller.upgradePending = nil
    local current = upgradeRowSnapshot(pending.button)
    if current ~= pending.before then
        controller.upgradeNoChange = 0
        controller.upgradeStage = "Stats UI changed (upgrade not verified)"
    else
        controller.upgradeNoChange = controller.upgradeNoChange + 1
        controller.upgradeStage = "Stats UI unchanged " .. controller.upgradeNoChange .. "/3"
    end
    writeLog("Upgrade feedback: " .. controller.upgradeStage ..
        " | " .. pending.stat .. " | event=" .. pending.event)
    if controller.upgradeNoChange >= 3 then
        controller.upgrade = false
        controller.upgradeStage = "PAUSED: no Stats UI change after 3 attempts"
        writeLog("AUTO UPGRADE paused; use COPY EQUIP / UPGRADE TARGETS.")
    end
end

local function actionDiagnosticReport()
    scanActionButtons()
    local lines = {
        "MY ANIME MINE V0.11 EQUIP / UPGRADE TARGETS | " .. os.date("%H:%M:%S"),
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
        "NOTE: no game UI path has been verified live; dispatch is not proof of equip/stat gains. No premium actions targeted."
    return table.concat(lines, "\n")
end

local function diagnosticReport()
    local out = {}
    local function append(v) out[#out + 1] = v end
    append("MY ANIME MINE | V0.11 TARGET DIAGNOSTICS | " .. os.date("%H:%M:%S"))
    append("PlaceId=" .. tostring(game.PlaceId) .. " | autoMine=" ..
        tostring(controller.mine) .. " autoCollect=" .. tostring(controller.collect) ..
        " autoEquip=" .. tostring(controller.equip) .. " autoUpgrade=" .. tostring(controller.upgrade))
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
    mineButton.Text = "AUTO MINE (CLICK): " .. (controller.mine and "ON" or "OFF")
    collectButton.Text = "AUTO COLLECT: " .. (controller.collect and "ON" or "OFF")
    mineButton.BackgroundColor3 = controller.mine and palette.accent or palette.button
    collectButton.BackgroundColor3 = controller.collect and palette.accent or palette.button
    autoPlotLabel.Text = "PLOT AUTO: " .. tostring(controller.selectedPlot or "SEARCHING") ..
        "  |  WALK AUTO: " .. (controller.walkToChest and "ON" or "OFF")
    manualWatchButton.Text = "WATCH MANUAL TAKE ALL: " .. (controller.watchManual and "ON" or "OFF")
    manualWatchButton.BackgroundColor3 = controller.watchManual and palette.accent or palette.button
    equipButton.Text = "AUTO EQUIP BEST: " .. (controller.equip and "ON" or "OFF")
    upgradeButton.Text = "AUTO UPGRADE STATS: " .. (controller.upgrade and "ON" or "OFF")
    equipButton.BackgroundColor3 = controller.equip and palette.accent or palette.button
    upgradeButton.BackgroundColor3 = controller.upgrade and palette.accent or palette.button
    statusLabel.Text = ("Rock %d | Chest %d | TakeAll %d | collect calls %d/%d\nEquip: %s (%d OK) | Upgrade: %s (%d OK)\nCollect: %s"):format(
        #controller.detectors, #controller.prompts, #controller.takeAllButtons,
        controller.collectActions, controller.takeAllActions,
        tostring(controller.equipStage):sub(1, 35), controller.equipActions,
        tostring(controller.upgradeStage):sub(1, 35), controller.upgradeActions,
        tostring(controller.collectionStage):sub(1, 67))
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
        " | uses visible game Inventory button only")
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
        " | miner Damage, Speed, Mining Speed; game currency only")
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

writeLog("My Anime Mine v0.11 started | toggles OFF | PlaceId 79389059854988")
writeLog("AUTO PLOT and AUTO WALK are built into Auto Collect; no manual Set Plot or Walk toggle.")
writeLog("No undocumented remotes fired. Dispatch OK does not prove a reward.")
scan(true)
autoSelectPlot()
refreshStatus()

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

        -- Equip Best is a low-frequency action. One inventory-open attempt
        -- per cycle avoids toggling a game menu open/closed repeatedly.
        if controller.equip and not controller.watchManual and now - lastEquipTick >= 6 then
            lastEquipTick = now
            if findTakeAll() then
                controller.equipStage = "Waiting for Chest UI to close"
            else
                local best = firstAvailable(controller.equipCandidates)
                local inventory = firstAvailable(controller.inventoryCandidates)
                if best and now - (controller.lastEquipAt or 0) >= 20 then
                    controller.lastEquipAt = now
                    controller.equipAttempts = controller.equipAttempts + 1
                    local ok, result, event = dispatchGameButton(best)
                    if ok then controller.equipActions = controller.equipActions + 1 end
                    controller.equipStage = ok and "Equip Best click dispatched" or ("Equip: " .. result)
                    writeLog("AUTO EQUIP " .. controller.equipStage ..
                        " | event=" .. event .. " | " .. describe(best) ..
                        " | equip result NOT verified")
                elseif not best and inventory and controller.inventoryOpenAttempts < 1 then
                    controller.inventoryOpenAttempts = controller.inventoryOpenAttempts + 1
                    controller.inventoryLastTarget = describe(inventory)
                    local ok, result, event = dispatchGameButton(inventory)
                    controller.equipStage = ok and "Inventory click sent; scanning for Equip Best"
                        or ("Inventory click ERROR: " .. result)
                    writeLog("AUTO EQUIP: " .. controller.equipStage .. " | event=" .. event ..
                        " | " .. controller.inventoryLastTarget .. " | NOT proof Inventory opened")
                elseif not best then
                    controller.equipStage = "Equip Best not visible; COPY EQUIP / UPGRADE TARGETS"
                end
            end
        end

        if controller.upgradePending then resolveUpgradeFeedback(now) end
        if controller.upgrade and not controller.watchManual and now - lastUpgradeTick >= 3.5 then
            lastUpgradeTick = now
            controller.upgradeLastTick = now
            if not controller.selectedPlot then autoSelectPlot() end
            if not controller.selectedPlot then
                controller.upgradeStage = "Waiting for nearby plot (not acquired)"
            elseif findTakeAll() then
                controller.upgradeStage = "Waiting for Chest to close"
            elseif controller.upgradePending then
                controller.upgradeStage = "Waiting for Stats UI feedback"
            elseif controller.upgradeAttempts >= 80 then
                controller.upgrade = false
                controller.upgradeStage = "PAUSED: 80 attempted stat upgrades per cycle"
                writeLog("AUTO UPGRADE paused after 80 attempts; inspect results before restarting.")
            else
                local valid = {}
                for _, item in ipairs(controller.upgradeCandidates) do
                    if item.Parent and isVisible(item) and isUpgradeAction(item) then
                        valid[#valid + 1] = item
                    end
                end
                if controller.openedHolder and #valid > 0 then
                    local index = (controller.upgradeIndex - 1) % #valid + 1
                    controller.upgradeIndex = index + 1
                    local target = valid[index]
                    controller.upgradeAttempts = controller.upgradeAttempts + 1
                    local signature = upgradeRowSnapshot(target)
                    local stat = statContext(target) or "unknown"
                    local ok, result, event = dispatchGameButton(target)
                    if ok then
                        controller.upgradeActions = controller.upgradeActions + 1
                        controller.upgradePending = {
                            button = target, before = signature, started = now,
                            stat = stat, event = event,
                        }
                    end
                    controller.upgradeStage = ok and ("Upgrading " .. stat .. " (check pending)")
                        or ("Upgrade ERROR: " .. result)
                    writeLog("AUTO UPGRADE " .. controller.upgradeStage ..
                        " | " .. describe(target) .. " | game currency only")
                elseif controller.openedHolder and not controller.statsTabAttempted
                    and now - controller.openedHolderAt < 25
                    and firstAvailable(controller.statsCandidates) then
                    local tab = firstAvailable(controller.statsCandidates)
                    controller.statsTabAttempted = true
                    local ok, result, event = dispatchGameButton(tab)
                    controller.upgradeStage = ok and "Opening character Stats tab"
                        or ("Stats tab ERROR: " .. result)
                    writeLog("AUTO UPGRADE " .. controller.upgradeStage .. " | event=" ..
                        event .. " | " .. describe(tab))
                elseif now >= controller.holderNextAt then
                    local detector, distance = nextHolderDetector()
                    if detector then
                        stopUpgradeWalking()
                        controller.upgradeBusyUntil = now + 6
                        controller.holderNextAt = now + 23
                        controller.holderAttempts = controller.holderAttempts + 1
                        controller.lastHolderProbe = describe(detector)
                        controller.lastHolderProbeInRange = ("%.1f studs"):format(distance)
                        local ok, err = pcall(fireclickdetector, detector)
                        if ok then
                            controller.holderActions = controller.holderActions + 1
                            controller.openedHolder = detector
                            controller.openedHolderAt = now
                            controller.statsTabAttempted = false
                            controller.upgradeNoChange = 0
                            controller.upgradeStage = ("Opening miner at %.1f studs"):format(distance)
                        else
                            controller.upgradeStage = "UpgradeClick ERROR: " .. tostring(err)
                        end
                        writeLog("AUTO UPGRADE " .. controller.upgradeStage ..
                            " | " .. describe(detector) .. " | result NOT verified")
                    else
                        local allHolders = holderTargets()
                        if #allHolders == 0 then
                            controller.upgradeStage = "No Holders/UpgradeClick found on selected Plot"
                        else
                            controller.upgradeStage = approachUpgradeHolder(allHolders[1], now)
                            if controller.upgradeStage:find("PAUSED:", 1, true) then
                                writeLog("AUTO UPGRADE " .. controller.upgradeStage)
                            end
                        end
                    end
                else
                    controller.upgradeStage = "Waiting for miner Stats panel"
                end
            end
        end
        if controller.watchManual then monitorManualButton() end
        if controller.manualPending then settleManualTakeAll(now) end
        if controller.takeAllPending then settleTakeAll(now) end
        if not controller.selectedPlot and now - lastAutoPlotCheck >= 5 then
            lastAutoPlotCheck = now
            autoSelectPlot()
        end
        -- Holder travel gets a short exclusive movement window. The working
        -- Auto Collect loop is otherwise unchanged and resumes afterward.
        if controller.collect and not controller.upgradeWalkTarget
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
                        controller.collectionStage = "Chest empty: wait for mined items"
                        action = "CHEST EMPTY, Take All not dispatched"
                    else
                        local ok, err = pcall(firesignal, button[eventName])
                        if ok then
                            controller.takeAllActions = controller.takeAllActions + 1
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
