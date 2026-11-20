-- My Roblox Hub | My Anime Mine v0.7 (chest close/reopen outcome tracking)
-- PlaceId: 79389059854988
-- This module does not guess or fire undocumented server remotes.
-- Auto Mine uses nearby rock ClickDetectors where provided by the game.
-- Auto Collect uses only the player's explicitly selected plot, then opens its chest and clicks Take All.
-- Mining in this game is normally performed by placed characters.
-- All automatic features start OFF. Auto Walk is separately opt-in; no purchases, selling, or teleporting.

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
    minimized = false,
    walkToChest = false,
    selectedPlot = nil,
    collectionStage = "Set your plot near its UpgradeClick",
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
    self.walkToChest = false
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
    Name = "Main", Size = UDim2.fromOffset(510, 536),
    Position = UDim2.new(0.5, -255, 0.5, -268),
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
    Text = "V0.7 | Manual Take All closes Chest normally. Reopen checks after cooldown; no reward proof.",
})
local mineButton = button("AutoMine", "AUTO MINE (CLICK): OFF", 16, 104, 230, 41)
local collectButton = button("AutoCollect", "AUTO COLLECT: OFF", 264, 104, 230, 41)
local scanButton = button("Scan", "SCAN GAME", 16, 158, 230, 38)
local copyButton = button("CopyLog", "COPY LOG", 264, 158, 230, 38)
local detailButton = button("Diagnostics", "COPY TARGET DIAGNOSTICS", 16, 205, 478, 38)
local setPlotButton = button("SetPlot", "SET MY PLOT", 16, 250, 230, 38)
local walkButton = button("WalkToChest", "WALK TO CHEST: OFF", 264, 250, 230, 38)
local manualWatchButton = button("ManualWatch", "WATCH MANUAL TAKE ALL: OFF", 16, 298, 478, 38)
local statusLabel = make("TextLabel", panel, {
    Name = "Status", Position = UDim2.fromOffset(17, 346),
    Size = UDim2.fromOffset(478, 51),
    BackgroundTransparency = 1, Font = Enum.Font.Code, TextSize = 12,
    TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left,
    TextColor3 = palette.accent, Text = "Discovering...",
})
make("TextLabel", panel, {
    Name = "LogTitle", Position = UDim2.fromOffset(16, 413),
    Size = UDim2.fromOffset(478, 20),
    BackgroundTransparency = 1, Font = Enum.Font.GothamBold, TextSize = 13,
    TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = palette.text,
    Text = "LOG / DIAGNOSTICS",
})
local logFrame = make("Frame", panel, {
    Name = "LogPanel", Position = UDim2.fromOffset(16, 436),
    Size = UDim2.fromOffset(478, 88), BackgroundColor3 = palette.panel,
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

local function choosePlotNearPlayer()
    local root = rootPart()
    if not root then return nil, nil, "Character/HumanoidRootPart missing" end
    local best, bestDistance = nil, 65
    for _, detector in ipairs(controller.detectors) do
        if detector.Parent and detector.Name:lower():find("upgrade", 1, true) then
            local plotName = minePlotName(detector)
            local pos = positionOf(detector)
            if plotName and pos then
                local dist = (pos - root.Position).Magnitude
                if dist < bestDistance then
                    best, bestDistance = plotName, dist
                end
            end
        end
    end
    if not best then
        return nil, nil, "No UpgradeClick within 65 studs. Stand near your own plot then SCAN GAME."
    end
    return best, bestDistance, nil
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
        return "WALK BLOCKED after 11s. Walk OFF; move closer manually."
    end
    if now - (controller.lastMoveCommand or 0) >= 1.8 then
        controller.lastMoveCommand = now
        controller.moveAttempts = controller.moveAttempts + 1
        local ok, err = pcall(function() humanoid:MoveTo(pos) end)
        if not ok then
            stopWalking()
            controller.walkToChest = false
            return "MoveTo failed: " .. tostring(err)
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

local function diagnosticReport()
    local out = {}
    local function append(v) out[#out + 1] = v end
    append("MY ANIME MINE | V0.7 TARGET DIAGNOSTICS | " .. os.date("%H:%M:%S"))
    append("PlaceId=" .. tostring(game.PlaceId) .. " | autoMine=" ..
        tostring(controller.mine) .. " autoCollect=" .. tostring(controller.collect))
    append(("Targets: rocks=%d prompts=%d TakeAll=%d"):format(
        #controller.detectors, #controller.prompts, #controller.takeAllButtons))
    local root = rootPart()
    append("Root=" .. (root and tostring(root.Position) or "NOT FOUND"))
    local nearPlot, plotDistance, plotReason = choosePlotNearPlayer()
    append("Plot selected=" .. tostring(controller.selectedPlot) ..
        " (manual proximity selection; ownership NOT verified)")
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
    setPlotButton.Text = "MY PLOT: " .. tostring(controller.selectedPlot or "NOT SET")
    walkButton.Text = "WALK TO CHEST: " .. (controller.walkToChest and "ON" or "OFF")
    walkButton.BackgroundColor3 = controller.walkToChest and palette.accent or palette.button
    manualWatchButton.Text = "WATCH MANUAL TAKE ALL: " .. (controller.watchManual and "ON" or "OFF")
    manualWatchButton.BackgroundColor3 = controller.watchManual and palette.accent or palette.button
    statusLabel.Text = ("Rock: %d | Chest prompt: %d | TakeAll: %d | calls %d/%d/%d\nStage: %s"):format(
        #controller.detectors, #controller.prompts, #controller.takeAllButtons,
        controller.mineActions, controller.collectActions, controller.takeAllActions,
        tostring(controller.collectionStage):sub(1, 86))
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
connect(setPlotButton.Activated, function()
    scan(false)
    local plotName, distance, reason = choosePlotNearPlayer()
    if plotName then
        controller.selectedPlot = plotName
        controller.collectionStage = "Plot set: " .. plotName .. " (check ownership yourself)"
        stopWalking()
        writeLog(("Plot marked: %s (upgrade marker %.1f studs away; ownership NOT verified)"):format(
            plotName, distance))
    else
        writeLog("Set plot failed: " .. tostring(reason))
    end
    refreshStatus()
end)
connect(walkButton.Activated, function()
    controller.walkToChest = not controller.walkToChest
    if not controller.walkToChest then stopWalking() end
    writeLog("Walk to Chest " .. (controller.walkToChest and "ON" or "OFF") ..
        " | no teleport; only selected plot")
    refreshStatus()
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
    if controller.collect then
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
        " | tries collection prompts and visible Take All buttons")
    refreshStatus()
end)
connect(scanButton.Activated, function()
    writeLog("Manual scan requested")
    scan(true)
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

writeLog("My Anime Mine v0.7 started | toggles OFF | PlaceId 79389059854988")
writeLog("Set your plot near UpgradeClick, then enable Auto Collect; enable Walk to Chest to approach.")
writeLog("No undocumented remotes fired. Dispatch OK does not prove a reward.")
scan(true)
refreshStatus()

task.spawn(function()
    local lastScan, lastMine, lastCollect, lastStatus = os.clock(), 0, 0, 0
    local lastMineReason, lastCollectReason = "", ""
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
        if controller.watchManual then monitorManualButton() end
        if controller.manualPending then settleManualTakeAll(now) end
        if controller.takeAllPending then settleTakeAll(now) end
        if controller.collect and now - lastCollect >= 1.25 then
            lastCollect = now
            local action = "none"
            local button = findTakeAll()
            if not controller.selectedPlot then
                controller.collectionStage = "Select MY PLOT near your UpgradeClick first"
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
