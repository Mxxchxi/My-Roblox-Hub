-- Roll A Stickman Diagnostics V1.5 R7 | Aura watch
-- PlaceId 115068315659966. Combined V1.2 R18; auto Moon inspection every 5 minutes.
-- Reads the active Moon from MOONS > Now.Title. Never buys, drinks or opens cards.
-- Only opens/closes MOONS when Potion, Open Card and Auto Pet automation are OFF.

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local LogService = game:GetService("LogService")
local player = Players.LocalPlayer
if not player or game.PlaceId ~= 115068315659966 then return end
local pg = player:WaitForChild("PlayerGui", 10)
if not pg then return end

for _, name in ipairs({"RollStickman_Diagnostics_V1", "RollStickman_Diagnostics_V1_2",
    "RollStickman_Diagnostics_V1_3", "RollStickman_Diagnostics_V1_4",
    "RollStickman_Diagnostics_V1_5"}) do
    local old = pg:FindFirstChild(name)
    if old then old:Destroy() end
end

local gui = Instance.new("ScreenGui")
gui.Name = "RollStickman_Diagnostics_V1_5"
gui.ResetOnSpawn = false
gui.DisplayOrder = 300
local panel = Instance.new("Frame")
panel.Name = "Panel"
panel.Position = UDim2.fromOffset(390, 160)
panel.Size = UDim2.fromOffset(430, 430)
panel.BackgroundColor3 = Color3.fromRGB(25, 28, 36)
panel.BorderSizePixel = 0
panel.Active = true
panel.Parent = gui
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 10)
corner.Parent = panel
local outline = Instance.new("UIStroke")
outline.Color = Color3.fromRGB(77, 85, 112)
outline.Parent = panel

local function button(name, value, x, width)
    local obj = Instance.new("TextButton")
    obj.Name = name
    obj.Text = value
    obj.TextSize = 13
    obj.BorderSizePixel = 0
    obj.BackgroundColor3 = Color3.fromRGB(59, 66, 84)
    local round = Instance.new("UICorner")
    round.CornerRadius = UDim.new(0, 7)
    round.Parent = obj
    obj.Position = UDim2.fromOffset(x, 8)
    obj.Size = UDim2.fromOffset(width, 34)
    obj.Parent = panel
    return obj
end
local mark = button("Mark", "MARK", 10, 80)
local stop = button("Stop", "STOP", 95, 80)
local copy = button("Copy", "COPY REPORT", 180, 160)
local close = button("Close", "X", 345, 75)

local status = Instance.new("TextLabel")
status.Name = "Status"
status.Position = UDim2.fromOffset(10, 46)
status.Size = UDim2.new(1, -20, 0, 28)
status.TextColor3 = Color3.new(1, 1, 1)
status.BackgroundTransparency = 1
status.TextSize = 13
status.TextXAlignment = Enum.TextXAlignment.Left
status.Text = "WAITING for active Aurora Moon"
status.Parent = panel

local dragHandle = Instance.new("TextLabel")
dragHandle.Name = "DragHandle"
dragHandle.Position = UDim2.fromOffset(10, 78)
dragHandle.Size = UDim2.new(1, -20, 0, 22)
dragHandle.BackgroundColor3 = Color3.fromRGB(43, 48, 67)
dragHandle.TextColor3 = Color3.fromRGB(229, 224, 250)
dragHandle.TextSize = 13
dragHandle.Text = "DIAGNOSTICS  ·  DRAG HERE"
dragHandle.Active = true
dragHandle.Parent = panel

local scroll = Instance.new("ScrollingFrame")
scroll.Position = UDim2.fromOffset(10, 105)
scroll.Size = UDim2.new(1, -20, 1, -115)
scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
scroll.CanvasSize = UDim2.new()
scroll.ScrollBarThickness = 8
scroll.BackgroundColor3 = Color3.fromRGB(19, 21, 27)
scroll.Parent = panel
local box = Instance.new("TextBox")
box.Size = UDim2.new(1, -16, 0, 0)
box.AutomaticSize = Enum.AutomaticSize.Y
box.Font = Enum.Font.Code
box.TextSize = 13
box.TextWrapped = true
box.MultiLine = true
box.ClearTextOnFocus = false
box.TextXAlignment = Enum.TextXAlignment.Left
box.TextYAlignment = Enum.TextYAlignment.Top
box.TextColor3 = Color3.fromRGB(235, 238, 245)
box.BackgroundTransparency = 1
box.Parent = scroll
gui.Parent = pg

local dragging, dragStart, panelStart = false, nil, nil
local function clampPosition(x, y)
    local camera = workspace.CurrentCamera
    local viewport = camera and camera.ViewportSize or Vector2.new(1920, 1080)
    return math.clamp(x, 0, math.max(0, viewport.X - 430)),
        math.clamp(y, 0, math.max(0, viewport.Y - 430))
end
dragHandle.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        dragging, dragStart, panelStart = true, input.Position,
            Vector2.new(panel.Position.X.Offset, panel.Position.Y.Offset)
    end
end)
local dragChanged = UserInputService.InputChanged:Connect(function(input)
    if not dragging or not dragStart or not panelStart then return end
    if input.UserInputType ~= Enum.UserInputType.MouseMovement
        and input.UserInputType ~= Enum.UserInputType.Touch then return end
    local delta = input.Position - dragStart
    local x, y = clampPosition(panelStart.X + delta.X, panelStart.Y + delta.Y)
    panel.Position = UDim2.fromOffset(x, y)
end)
local dragEnded = UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)

local alive, observing = true, true
local entries = {}
local seq, started = 0, os.clock()
local eventAt, eventSerial, lastSky, eventSky = nil, 0, nil, nil
local checkpoints = {2, 5, 15, 30, 60}
local checkpointIndex = 1
local nextOpen, lastHeartbeat = 0, os.clock()
local lastFields = {}
local logConnection

local function line(message)
    seq = seq + 1
    local value = string.format("%04d [%6.1fs] %s", seq,
        os.clock() - started, message)
    table.insert(entries, value)
    if #entries > 650 then table.remove(entries, 1) end
    if alive then box.Text = table.concat(entries, "\n") end
end
local function path(parts)
    local obj = pg:FindFirstChild("RollAStickman")
    for _, name in ipairs(parts) do
        obj = obj and obj:FindFirstChild(name)
    end
    return obj
end
local function child(obj, parts)
    for _, name in ipairs(parts) do
        obj = obj and obj:FindFirstChild(name)
    end
    return obj
end
local function visible(obj)
    if not obj then return false end
    while obj and obj ~= pg do
        if obj:IsA("GuiObject") and not obj.Visible then return false end
        if obj:IsA("ScreenGui") and not obj.Enabled then return false end
        obj = obj.Parent
    end
    return obj == pg
end
local function plain(obj)
    if not obj or not (obj:IsA("TextLabel") or obj:IsA("TextButton")) then
        return ""
    end
    return obj.Text:gsub("<[^>]*>", ""):gsub("%s+", " ")
        :match("^%s*(.-)%s*$")
end
local function read(parts)
    local obj = path(parts)
    return visible(obj) and plain(obj) or "(not visible)"
end
local function modal()
    local title = read({"Frame", "Modal", "Window", "Panel", "Header", "Title"})
    return title:upper()
end
local function mainBoostOn()
    local scriptGui = pg:FindFirstChild("RollStickman_Combined_V1_2")
    if not scriptGui or not scriptGui.Enabled then return false end
    local flag = scriptGui:GetAttribute("Flag_moon")
    local cards = scriptGui:GetAttribute("Flag_cards")
    local pet = scriptGui:GetAttribute("Flag_pet")
    if type(flag) == "boolean" or type(cards) == "boolean" or type(pet) == "boolean" then
        return flag == true or cards == true or pet == true
    end
    local panelObj = scriptGui and scriptGui:FindFirstChild("Panel")
    local toggle = panelObj and panelObj:FindFirstChild("MoonToggle")
    return toggle ~= nil and (plain(toggle):upper() == "AURORA BOOST: ON" or plain(toggle):upper() == "USE POTION: ON")
end
local function activeMoon()
    if modal() ~= "MOONS" then return nil end
    local obj = path({"Frame", "Modal", "Window", "Panel", "Content",
        "Inner", "Now", "Title"})
    if not visible(obj) then return nil end
    local value = plain(obj)
    return value ~= "" and value or nil
end
local function fireButton(obj)
    if not (obj and obj:IsA("GuiButton") and visible(obj)
        and obj.Active and type(firesignal) == "function") then
        return false
    end
    return pcall(firesignal, obj.Activated, nil, 1)
end
local function moonIcon()
    local image = path({"Frame", "Buffs", "Moon", "Circle", "Icon"})
    return image and (image:IsA("ImageLabel") or image:IsA("ImageButton"))
        and tostring(image.Image) or "(not found)"
end
local function field(name, value)
    if lastFields[name] ~= value then
        line("UI " .. name .. " = " .. value)
        lastFields[name] = value
    end
end
local function snapshot(label)
    line("SNAPSHOT " .. label .. " | event=" .. tostring(eventSerial))
    line("  moon.active=" .. tostring(activeMoon() or "(window closed)"))
    line("  moon.timer=" .. read({"Frame", "Buffs", "Moon", "Pill", "Value"})
        .. " | icon=" .. moonIcon())
    line("  moon.detail=" .. read({"Frame", "Modal", "Window", "Panel",
        "Content", "Inner", "Now", "Sub"}))
    line("  luck.hud=" .. read({"Frame", "Hud", "Luck", "Pill", "Value"})
        .. " | luck.battle=" .. read({"Frame", "Battle", "Dock",
            "LuckTab", "Pill", "Value"}))
    line("  rolls=" .. read({"Frame", "Hud", "Rolls", "Pill", "Value"})
        .. " | auto.roll=" .. read({"Frame", "Battle", "Dock", "RollBreath",
            "Roll", "Face", "Sub"}))
    line("  modal=" .. modal() .. " | main.boost=" .. tostring(mainBoostOn()))
    if modal() == "POTIONS" then
        for _, id in ipairs({"luck", "haste", "gild"}) do
            line("  potion." .. id .. "=" .. read({"Frame", "Modal", "Window",
                "Panel", "Content", "Inner", id, "Status"}))
        end
    elseif modal() == "CARD PACKS" then
        line("  cards=" .. read({"Frame", "Modal", "Window", "Panel",
            "Content", "Inner", "Loose", "Row", "Label"}))
        for _, id in ipairs({"pouch", "crate", "chest"}) do
            line("  pack." .. id .. "=" .. read({"Frame", "Modal", "Window",
                "Panel", "Content", "Inner", "Packs", id, "Open", "Face", "Sub"}))
        end
    end
end
local function observe()
    field("main.boost", tostring(mainBoostOn()))
    local sky = activeMoon()
    if sky then
        local upper = sky:upper()
        -- Now.Title contains a countdown. Compare the Moon's type so the
        -- same five-minute Aura remains one event across repeated checks.
        local kind = upper:match("^AURORA MOON")
            or upper:match("^BLUE MOON")
            or upper:match("^STARFALL MOON")
            or upper:match("^ECLIPSE")
            or upper:match("^NORMAL MOON")
            or upper
        if kind ~= lastSky then
            line("ACTIVE SKY = " .. sky)
            lastSky = kind
        end
        local isAura = kind == "AURORA MOON" or kind == "BLUE MOON"
            or kind == "STARFALL MOON" or kind == "ECLIPSE"
        if isAura and (not eventAt or eventSky ~= kind) then
            if eventAt then
                line("AURA CHANGED: " .. tostring(eventSky) .. " -> " .. kind)
            end
            eventSerial = eventSerial + 1
            eventAt, eventSky, checkpointIndex = os.clock(), kind, 1
            line("AURA DETECTED: " .. sky)
            if kind == "AURORA MOON" then
                line("HIGHEST AURA: Aurora Moon detected")
                if not mainBoostOn() then
                    line("Potion and Open Card switches are OFF; combined script will not use potions/cards")
                end
            end
            snapshot("AURA START")
            status.Text = "AURA DETECTED | collecting follow-up logs"
        elseif not isAura and eventAt then
            line("AURA ENDED: " .. sky)
            snapshot("AURA END")
            eventAt, eventSky = nil, nil
            status.Text = "AURA recorded | COPY REPORT"
        end
    end
    if eventAt and checkpointIndex <= #checkpoints
        and os.clock() - eventAt >= checkpoints[checkpointIndex] then
        snapshot("AURA +" .. checkpoints[checkpointIndex] .. "s")
        checkpointIndex = checkpointIndex + 1
        if checkpointIndex > #checkpoints then
            line("AURA 60s follow-up complete; COPY REPORT is ready")
            status.Text = "AURA recorded | COPY REPORT"
        end
    end
    local title = modal()
    if title == "POTIONS" then
        for _, id in ipairs({"luck", "haste", "gild"}) do
            field("potion." .. id .. ".stock", read({"Frame", "Modal", "Window",
                "Panel", "Content", "Inner", id, "Status"}))
        end
    elseif title == "CARD PACKS" then
        field("cards.owned", read({"Frame", "Modal", "Window", "Panel",
            "Content", "Inner", "Loose", "Row", "Label"}))
        for _, id in ipairs({"pouch", "crate", "chest"}) do
            field("pack." .. id .. ".owned", read({"Frame", "Modal",
                "Window", "Panel", "Content", "Inner", "Packs", id,
                "Open", "Face", "Sub"}))
        end
    end
end
local function autoInspect()
    local now = os.clock()
    if now < nextOpen or mainBoostOn() or modal() ~= "(NOT VISIBLE)" then
        return
    end
    nextOpen = now + 300
    local moon = path({"Frame", "Buffs", "Moon"})
    if not fireButton(moon) then
        if type(firesignal) ~= "function" and not lastFields.noSignal then
            line("No firesignal; open MOONS manually for active Aura checks")
            lastFields.noSignal = true
        end
        return
    end
    task.wait(0.65)
    observe()
    if modal() == "MOONS" then
        local panelObj = path({"Frame", "Modal", "Window", "Panel"})
        local closeObj = child(panelObj, {"Close"})
        fireButton(closeObj)
    end
end

logConnection = LogService.MessageOut:Connect(function(message)
    if alive and observing and message:find("%[RAS%]") then
        line("SCRIPT " .. message:gsub("[\r\n]+", " "))
    end
end)
mark.Activated:Connect(function()
    if observing then line("USER MARK"); snapshot("MANUAL") end
end)
stop.Activated:Connect(function()
    if observing then
        snapshot("STOP")
        observing = false
        if logConnection then logConnection:Disconnect() end
        line("Recording stopped by user")
        stop.Text = "STOPPED"
        status.Text = "STOPPED | COPY REPORT"
    end
end)
copy.Activated:Connect(function()
    local result = table.concat(entries, "\n")
    if type(setclipboard) == "function" and pcall(setclipboard, result) then
        copy.Text = "COPIED"
        return
    end
    box:CaptureFocus()
    box.CursorPosition = #box.Text + 1
    box.SelectionStart = 1
    copy.Text = "PRESS CTRL+C"
end)
close.Activated:Connect(function() gui:Destroy() end)
gui.Destroying:Connect(function()
    alive, observing = false, false
    dragChanged:Disconnect()
    dragEnded:Disconnect()
    if logConnection then logConnection:Disconnect() end
end)

line("Diagnostics V1.5 R7 | PlaceId=" .. tostring(game.PlaceId))
line("ACTIVE SKY is read only from MOONS > Now.Title; shop labels are ignored")
line("Watches Aura, potion/card counts and [RAS] logs; no gameplay purchases")
snapshot("INITIAL")

task.spawn(function()
    while alive and observing do
        local ok, err = pcall(function()
            observe()
            autoInspect()
            if os.clock() - lastHeartbeat >= 30 then
                line("HEARTBEAT | waiting=" .. tostring(not eventAt)
                    .. " | modal=" .. modal()
                    .. " | main.boost=" .. tostring(mainBoostOn()))
                lastHeartbeat = os.clock()
            end
        end)
        if not ok then line("WATCH ERROR: " .. tostring(err)) end
        task.wait(0.25)
    end
end)
