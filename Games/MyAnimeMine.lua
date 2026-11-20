-- My Roblox Hub | My Anime Mine v0.4 (Take All feedback and click-event diagnostics)
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
    takeAllOutcome = "NOT TESTED",
    takeAllLastEvent = "none",
    takeAllMethodIndex = 1,
    takeAllNextAt = 0,
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
    Name = "Main", Size = UDim2.fromOffset(510, 482),
    Position = UDim2.new(0.5, -255, 0.5, -241),
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
    Text = "V0.4 | Select your plot. Collect tracks Take All UI feedback; no reward proof yet.",
})
local mineButton = button("AutoMine", "AUTO MINE (CLICK): OFF", 16, 104, 230, 41)
local collectButton = button("AutoCollect", "AUTO COLLECT: OFF", 264, 104, 230, 41)
local scanButton = button("Scan", "SCAN GAME", 16, 158, 230, 38)
local copyButton = button("CopyLog", "COPY LOG", 264, 158, 230, 38)
local detailButton = button("Diagnostics", "COPY TARGET DIAGNOSTICS", 16, 205, 478, 38)
local setPlotButton = button("SetPlot", "SET MY PLOT", 16, 250, 230, 38)
local walkButton = button("WalkToChest", "WALK TO CHEST: OFF", 264, 250, 230, 38)
local statusLabel = make("TextLabel", panel, {
    Name = "Status", Position = UDim2.fromOffset(17, 299),
    Size = UDim2.fromOffset(478, 51),
    BackgroundTransparency = 1, Font = Enum.Font.Code, TextSize = 12,
    TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left,
    TextColor3 = palette.accent, Text = "Discovering...",
})
make("TextLabel", panel, {
    Name = "LogTitle", Position = UDim2.fromOffset(16, 360),
    Size = UDim2.fromOffset(478, 20),
    BackgroundTransparency = 1, Font = Enum.Font.GothamBold, TextSize = 13,
    TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = palette.text,
    Text = "LOG / DIAGNOSTICS",
})
local logFrame = make("Frame", panel, {
    Name = "LogPanel", Position = UDim2.fromOffset(16, 383),
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

local function settleTakeAll(now)
    local pending = controller.takeAllPending
    if not pending or now - pending.sentAt < 2.5 then return end
    controller.takeAllPending = nil
    local visible = pending.button.Parent and isVisible(pending.button)
    local newSnapshot = pending.button.Parent and chestSnapshot(pending.button) or "BUTTON_REMOVED"
    if not visible then
        controller.takeAllOutcome = "BUTTON_HIDDEN (not verified ore)"
        controller.takeAllNoChange = 0
    elseif newSnapshot ~= pending.before then
        controller.takeAllOutcome = "CHEST_UI_CHANGED (not verified ore)"
        controller.takeAllNoChange = 0
    else
        controller.takeAllOutcome = "NO_CHEST_UI_CHANGE"
        controller.takeAllNoChange = controller.takeAllNoChange + 1
        controller.takeAllMethodIndex = controller.takeAllMethodIndex == 1 and 2 or 1
    end
    writeLog("Take All feedback: " .. controller.takeAllOutcome ..
        " | event=" .. pending.event .. " | no-change=" .. controller.takeAllNoChange)
    if controller.collect and
        (controller.takeAllNoChange >= 2 or controller.takeAllAttempts >= 6) then
        controller.collect = false
        stopWalking()
        controller.collectionStage = "PAUSED: Take All result unverified. Inspect chest/ore and COPY TARGET DIAGNOSTICS."
        writeLog("Auto Collect PAUSED to avoid repeatedly clicking Take All without confirmed effect.")
    end
end

local function diagnosticReport()
    local out = {}
    local function append(v) out[#out + 1] = v end
    append("MY ANIME MINE | V0.4 TARGET DIAGNOSTICS | " .. os.date("%H:%M:%S"))
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
        " | pending=" .. tostring(controller.takeAllPending ~= nil))
    if button then
        local connections = takeAllConnections(button)
        append("TakeAll event connections (getconnections; '?' means unavailable): Activated=" ..
            tostring(connections.Activated) .. " MouseButton1Click=" ..
            tostring(connections.MouseButton1Click))
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
    append("NOTE: UI feedback is weak evidence only. Verify actual ore/inventory manually.")
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
connect(collectButton.Activated, function()
    if type(fireproximityprompt) ~= "function" and type(firesignal) ~= "function" then
        writeLog("Auto Collect unavailable: requires fireproximityprompt or firesignal")
        return
    end
    controller.collect = not controller.collect
    if controller.collect then
        controller.takeAllNoChange = 0
        controller.takeAllPending = nil
        controller.takeAllMethodIndex = 1
        controller.takeAllAttempts = 0
        controller.takeAllOutcome = "NOT TESTED"
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

writeLog("My Anime Mine v0.4 started | toggles OFF | PlaceId 79389059854988")
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
        if controller.takeAllPending then settleTakeAll(now) end
        if controller.collect and now - lastCollect >= 1.25 then
            lastCollect = now
            local action = "none"
            local button = findTakeAll()
            if not controller.selectedPlot then
                controller.collectionStage = "Select MY PLOT near your UpgradeClick first"
            elseif button and type(firesignal) == "function" then
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
                    local ok, err = pcall(firesignal, button[eventName])
                    if ok then
                        controller.takeAllActions = controller.takeAllActions + 1
                        controller.takeAllPending = {
                            button = button, before = snapshot, sentAt = now, event = eventName,
                        }
                        action = "TAKE ALL dispatched (" .. eventName .. ") " .. describe(button) ..
                            " | connections=" .. tostring(counts[eventName])
                    else
                        action = "Take All " .. eventName .. " ERROR " .. tostring(err)
                        controller.takeAllOutcome = "DISPATCH_ERROR"
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
