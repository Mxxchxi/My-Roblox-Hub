-- Steal An Egg: structure diagnostics v1.20
-- Auto Hatch test via nearby enabled prompts; Auto Collect tests nearby CarryAreaEgg prompts; remaining systems await mapping.
local Players = game:GetService("Players")
local Http = game:GetService("HttpService")
local player = Players.LocalPlayer
assert(player, "Run on the game client")
assert(game.PlaceId == 107778070777162, "Wrong map: " .. tostring(game.PlaceId))
local pg = player:WaitForChild("PlayerGui", 20)
assert(pg, "PlayerGui is not ready; rerun after loading")
local old = pg:FindFirstChild("EggDiagnostics")
if old then old:Destroy() end
local gui = Instance.new("ScreenGui")
gui.Name = "EggDiagnostics"
gui.ResetOnSpawn = false
gui.Parent = pg
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local PathfindingService = game:GetService("PathfindingService")
local colors = {bg = Color3.fromRGB(13, 17, 32), panel = Color3.fromRGB(22, 28, 48),
    purple = Color3.fromRGB(153, 100, 255), cyan = Color3.fromRGB(67, 218, 246),
    text = Color3.fromRGB(235, 240, 255), muted = Color3.fromRGB(151, 164, 190)}
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
local function create(class, parent, props)
    local obj = Instance.new(class)
    for k, v in pairs(props or {}) do obj[k] = v end
    obj.Parent = parent
    return obj
end
local function round(obj, radius)
    create("UICorner", obj, {CornerRadius = UDim.new(0, radius or 10)})
end
local function label(parent, text, x, y, w, h, size, color)
    return create("TextLabel", parent, {Position = UDim2.fromOffset(x,y), Size = UDim2.fromOffset(w,h),
        BackgroundTransparency = 1, Text = text, Font = Enum.Font.Gotham,
        TextSize = size or 14, TextColor3 = color or colors.text, TextXAlignment = Enum.TextXAlignment.Left})
end
local function control(parent, text, x, y, w, h)
    local b = create("TextButton", parent, {Position = UDim2.fromOffset(x,y), Size = UDim2.fromOffset(w,h or 34),
        BackgroundColor3 = colors.panel, Text = text, Font = Enum.Font.GothamMedium,
        TextSize = 13, TextColor3 = colors.text, AutoButtonColor = true})
    round(b, 8)
    return b
end
local frame = create("Frame", gui, {Size = UDim2.fromOffset(760,540),
    Active = true, AnchorPoint = Vector2.new(0.5,0.5), Position = UDim2.fromScale(0.5,0.5), BackgroundColor3 = colors.bg})
round(frame, 14)
local border = create("UIStroke", frame, {Thickness = 1.5, Color = colors.purple})
create("UIGradient", border, {Color = ColorSequence.new(colors.purple, colors.cyan)})
local scale = create("UIScale", frame, {Scale = 1})
local function fit()
    local camera = workspace.CurrentCamera
    if camera then scale.Scale = math.min(1, (camera.ViewportSize.X-24)/760, (camera.ViewportSize.Y-64)/540) end
end
fit()
local title = label(frame, "YUU HUB", 20,12,200,28,22,colors.cyan)
label(frame, "STEAL AN EGG  /  v1.20", 20,40,300,20,11,colors.muted)
local minimize = control(frame, "—", 670,16,32,30)
local close = control(frame, "X", 710,16,32,30)
local sidebar = create("Frame", frame, {Position = UDim2.fromOffset(12,76), Size = UDim2.fromOffset(148,382), BackgroundColor3 = colors.panel})
round(sidebar)
label(sidebar, "WORKSPACE",12,10,125,22,10,colors.muted)
local automation = create("Frame", frame, {Position = UDim2.fromOffset(176,76), Size = UDim2.fromOffset(568,382), BackgroundTransparency = 1})
local diagnostics = create("Frame", frame, {Position = automation.Position, Size = automation.Size, BackgroundTransparency = 1, Visible = false})
local settings = create("Frame", frame, {Position = automation.Position, Size = automation.Size, BackgroundTransparency = 1, Visible = false})
local tabs = {}
local function showTab(name)
    automation.Visible = name == "Automation"
    diagnostics.Visible = name == "Diagnostics"
    settings.Visible = name == "Settings"
    for key, b in pairs(tabs) do
        b.BackgroundColor3 = key == name and colors.purple or colors.panel
    end
end
for i, name in ipairs({"Automation", "Diagnostics", "Settings"}) do
    local b = control(sidebar,name,8,42+(i-1)*44,132,36)
    tabs[name] = b
    b.Activated:Connect(function() showTab(name) end)
end
label(sidebar,"By Yuu Walker",12,344,130,22,11,colors.muted)
label(automation,"Automation",0,0,400,30,22)
label(automation,"Egg collection with Tween • remaining systems in development",0,32,565,22,12,colors.muted)
local rows = {}
for i, name in ipairs({"Auto Hatch", "Collect Eggs", "Collect Coins", "Upgrade Base", "Speed Training"}) do
    local row = create("Frame",automation,{Position = UDim2.fromOffset(0,60+(i-1)*54), Size = UDim2.fromOffset(568,50), BackgroundColor3 = colors.panel})
    round(row,8)
    label(row,name,14,0,280,50,14,i <= 2 and colors.text or colors.muted)
    label(row,i <= 2 and "TEST" or "SOON",316,0,62,50,11,i <= 2 and colors.cyan or colors.muted)
    if i > 2 then label(row,"Unavailable",422,0,130,50,12,colors.muted) end
    rows[i] = row
end
local scan = control(diagnostics,"Scan / Refresh",0,0,136)
local copy = control(diagnostics,"Copy all",146,0,128)
local save = control(diagnostics,"Save file",284,0,128)
local selectText = control(diagnostics,"Select ALL",422,0,146)
local previous = control(diagnostics,"< Page",0,42,88)
local following = control(diagnostics,"Page >",98,42,88)
local shortCopy = control(diagnostics,"Copy short",196,42,110)
local pageLabel = label(diagnostics,"v1.20 | Waiting for scan",316,42,252,34,11,colors.muted)
local reportScroll = create("ScrollingFrame",diagnostics,{Position = UDim2.fromOffset(0,86), Size = UDim2.fromOffset(568,296),
    BackgroundColor3 = colors.panel, BorderSizePixel = 0, ScrollBarThickness = 5,
    AutomaticCanvasSize = Enum.AutomaticSize.XY, CanvasSize = UDim2.new()})
round(reportScroll,8)
local box = create("TextBox",reportScroll,{Position = UDim2.fromOffset(10,8), Size = UDim2.fromOffset(546,278),
    AutomaticSize = Enum.AutomaticSize.XY, BackgroundTransparency = 1, MultiLine = true, ClearTextOnFocus = false,
    TextEditable = true, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top,
    Font = Enum.Font.Code, TextSize = 12, TextColor3 = colors.text, TextWrapped = false, Text = "Loading..."})
local collectLabel = label(automation,"Collect OFF • Tween to nearest egg",0,340,568,18,11,colors.muted)
local status = label(frame,"Preparing diagnostics...",176,472,568,52,12,colors.muted)
status.TextWrapped = true
label(settings,"Settings",0,0,400,30,22)
label(settings,"Interface",0,50,400,24,14,colors.cyan)
label(settings,"Drag header to move. Alt or RightShift toggles the window.",0,88,568,24,12)
label(settings,"Close stops all automation. Minimize keeps it running.",0,118,568,24,12)
label(settings,"Hatch and Collect start OFF. Other systems are unavailable.",0,148,568,24,12,colors.muted)
label(settings,"Collect: Tween within 250 studs, speed up to 24 studs/s.",0,190,568,24,12,colors.cyan)
label(settings,"Set a delivery point below to enable automatic return.",0,220,568,24,12,colors.muted)
local restore = control(gui,"YUU HUB",16,120,108,36)
restore.Visible = false
local function setShown(shown)
    frame.Visible = shown
    restore.Visible = not shown
end
minimize.Activated:Connect(function() setShown(false) end)
restore.Activated:Connect(function() setShown(true) end)
showTab("Automation")
local reportText = ""
local shortReportText = ""
local active = true
local pages, pageIndex = {}, 1
local function showPage()
    box.Text = pages[pageIndex] or "No report yet"
    pageLabel.Text = string.format("v1.20 | Page %d/%d | %d bytes", pageIndex, #pages, #reportText)
end
local function splitPages(text)
    pages, pageIndex = {}, 1
    local start = 1
    while start <= #text do
        local finish = math.min(start + 5999, #text)
        -- Do not split a UTF-8 codepoint between pages.
        while finish < #text do
            local byte = text:byte(finish + 1)
            if byte < 128 or byte >= 192 then break end
            finish = finish - 1
        end
        table.insert(pages, text:sub(start, finish))
        start = finish + 1
    end
    showPage()
end
local function capability(name)
    local direct = ({setclipboard = setclipboard, toclipboard = toclipboard,
        set_clipboard = set_clipboard, getclipboard = getclipboard,
        readclipboard = readclipboard, writefile = writefile, readfile = readfile})[name]
    if type(direct) == "function" then return direct end
    for _, getter in pairs({getgenv = getgenv, getrenv = getrenv}) do
        if type(getter) == "function" then
            local ok, env = pcall(getter)
            if ok and type(env) == "table" and type(env[name]) == "function" then return env[name] end
        end
    end
    if type(_G) == "table" and type(_G[name]) == "function" then return _G[name] end
end
local function nativeSelect(text)
    showTab("Diagnostics")
    -- Full report, never just the currently displayed page.
    box:CaptureFocus()
    box.Text = text
    if box.Text ~= text then
        status.Text = "TextBox could not hold full report. Try Copy short."
        return false
    end
    task.defer(function()
        if not active then return end
        box.CursorPosition = #box.Text + 1
        box.SelectionStart = 1
    end)
    pageLabel.Text = "v1.20 | ALL selected | " .. #text .. " bytes"
    return true
end
local function selectAll()
    if reportText == "" then status.Text = "Wait for scan to finish."; return end
    if nativeSelect(reportText) then
        status.Text = "ALL selected. Press Ctrl+C on TEST PC, then paste. Remote clipboard sync must be enabled."
    end
end
local function copyPayload(text, label)
    local errors = {}
    local reader = capability("getclipboard") or capability("readclipboard")
    local unverified = false
    local writers = {}
    local seen = {}
    local function add(name, fn)
        if type(fn) == "function" and not seen[fn] then
            seen[fn] = true
            table.insert(writers, {name = name, fn = fn})
        end
    end
    for _, name in ipairs({"setclipboard", "toclipboard", "set_clipboard"}) do add(name, capability(name)) end
    if type(clipboard) == "table" then
        add("clipboard.set", clipboard.set)
        add("clipboard.setclipboard", clipboard.setclipboard)
    end
    if type(syn) == "table" then add("syn.write_clipboard", syn.write_clipboard) end
    for _, writer in ipairs(writers) do
        local ok, result = pcall(writer.fn, text)
        if ok and result ~= false then
            local readable, matched = false, false
            if reader then
                for attempt = 1, 3 do
                    task.wait(0.08)
                    if not active then return end
                    local readOK, value = pcall(reader)
                    if readOK and type(value) == "string" then
                        readable = true
                        if value == text then matched = true; break end
                    end
                end
            end
            if matched then
                status.Text = label .. " VERIFIED on TEST PC (" .. #text .. " bytes). Remote clipboard sync is separate."
                return
            end
            if not readable then unverified = true end
            table.insert(errors, writer.name .. (readable and ": readback mismatch" or ": cannot verify"))
        else
            table.insert(errors, writer.name .. ": failed")
        end
    end
    -- Even a no-op executor API now leaves a real, full selection for native Ctrl+C.
    if not active then return end
    local selected = nativeSelect(text)
    if selected then
        local reason = #writers == 0 and "No clipboard API" or (unverified and "Copy API unverified" or "Clipboard write failed")
        status.Text = reason .. ". ALL selected: press Ctrl+C on TEST PC. " .. label .. " (" .. #text .. " bytes)."
    end
    warn("[Egg Diagnostics] " .. table.concat(errors, "; "))
end
local busy = false
-- AUTO_HATCH_BEGIN
local hatchButton = control(rows[1], "Auto Hatch: OFF", 410,8,146,34)
local testHatch = control(automation,"Test Hatch once",0,358,150,24)
local hatchLabel = label(automation,"Stand within 7 studs of your ready egg.",160,354,408,28,11,colors.muted)
hatchLabel.TextWrapped = true
local carryMarker = control(settings,"Mark: I am carrying an egg",0,268,270,34)
label(settings,"Clear this marker after delivering or dropping the egg.",0,310,568,24,12,colors.muted)
local setHomeButton = control(settings,"Set delivery point here",0,346,260,30)
local clearHomeButton = control(settings,"Clear delivery point",270,346,260,30)
local collectButton = control(rows[2], "Collect: OFF", 410,8,146,34)
local collectEgg = {enabled = false, attempts = 0, last = "OFF"}
local collectRunning = false
local collectAttempts = setmetatable({}, {__mode = "k"})
local hatch = {enabled = false, attempts = 0, last = "OFF"}
local promptCache = setmetatable({}, {__mode = "k"})
local attemptState = setmetatable({}, {__mode = "k"})
local connections = {}
local dragging, dragStart, initialPosition
local altPending = false
connections[#connections + 1] = UIS.InputBegan:Connect(function(input, processed)
    if input.KeyCode == Enum.KeyCode.LeftAlt or input.KeyCode == Enum.KeyCode.RightAlt then
        altPending = not processed and not UIS:GetFocusedTextBox()
    else
        -- Alt+Tab and other combinations must not also hide the hub.
        altPending = false
    end
    if input.KeyCode == Enum.KeyCode.RightShift and not processed and not UIS:GetFocusedTextBox() then
        setShown(not frame.Visible)
    end
end)
connections[#connections + 1] = frame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        local relative = input.Position.Y - frame.AbsolutePosition.Y
        if relative <= 68 * scale.Scale and input.Position.X < minimize.AbsolutePosition.X then
            dragging, dragStart, initialPosition = true, input.Position, frame.Position
        end
    end
end)
connections[#connections + 1] = UIS.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - dragStart
        frame.Position = initialPosition + UDim2.fromOffset(delta.X,delta.Y)
    end
end)
connections[#connections + 1] = UIS.InputEnded:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.LeftAlt or input.KeyCode == Enum.KeyCode.RightAlt then
        if altPending and not UIS:GetFocusedTextBox() then setShown(not frame.Visible) end
        altPending = false
    end
    if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
end)
local camera = workspace.CurrentCamera
local cameraConnection
local function watchCamera()
    if cameraConnection then cameraConnection:Disconnect() end
    camera = workspace.CurrentCamera
    if camera then cameraConnection = camera:GetPropertyChangedSignal("ViewportSize"):Connect(fit) end
    fit()
end
connections[#connections + 1] = workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(watchCamera)
watchCamera()
local holding
local function trackPrompt(obj)
    if obj:IsA("ProximityPrompt") then promptCache[obj] = true end
end
local function promptPosition(prompt)
    local parent = prompt.Parent
    if parent and parent:IsA("Attachment") then return parent.WorldPosition end
    if parent and parent:IsA("BasePart") then return parent.Position end
    if parent and parent:IsA("Model") then return parent:GetPivot().Position end
end
local function eligible(prompt, root, humanoid)
    if not prompt.Parent or not prompt:IsDescendantOf(workspace) then return false end
    -- Only the exact action observed in the report. Never target Steal/Skip/Mutation.
    if prompt.ActionText ~= "Hatch!" or not prompt.Enabled then return false end
    if not root or not humanoid or humanoid.Health <= 0 then return false end
    if prompt.HoldDuration < 0 or prompt.HoldDuration > 5 then return false end
    local position = promptPosition(prompt)
    if not position then return false end
    return (root.Position - position).Magnitude <= math.min(prompt.MaxActivationDistance, 7)
end
local function hatchStep(manual)
    if not active or (not hatch.enabled and not manual) then return end
    if collectRunning then return end
    if busy then hatch.last = "Paused during scan"; hatchLabel.Text = hatch.last; return end
    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if not root or not humanoid then hatch.last = "Waiting for character"; return end
    for prompt in pairs(promptCache) do
        if eligible(prompt, root, humanoid) then
            local state = attemptState[prompt] or {count = 0, time = -math.huge}
            attemptState[prompt] = state
            if state.count < 3 and os.clock() - state.time >= 4 then
                state.count = state.count + 1
                state.time = os.clock()
                hatch.attempts = hatch.attempts + 1
                local ok, err = pcall(function()
                    holding = prompt
                    prompt:InputHoldBegin()
                    task.wait(prompt.HoldDuration + 0.1)
                    prompt:InputHoldEnd()
                    holding = nil
                end)
                if holding then pcall(function() holding:InputHoldEnd() end); holding = nil end
                if not active then return end
                hatch.last = ok and "Hatch input sent; check game result" or ("Input failed: " .. tostring(err):sub(1, 80))
                hatchLabel.Text = hatch.last .. " | Attempts " .. hatch.attempts
                return
            end
        end
    end
    hatch.last = "Waiting for nearby Hatch! (max 3 attempts per prompt per toggle)"
    hatchLabel.Text = hatch.last
end
connections[#connections + 1] = workspace.DescendantAdded:Connect(trackPrompt)
connections[#connections + 1] = workspace.DescendantRemoving:Connect(function(obj)
    promptCache[obj] = nil
    attemptState[obj] = nil
end)
connections[#connections + 1] = game:GetService("ProximityPromptService").PromptShown:Connect(trackPrompt)
hatchButton.Activated:Connect(function()
    hatch.enabled = not hatch.enabled
    attemptState = setmetatable({}, {__mode = "k"})
    hatchButton.Text = hatch.enabled and "Auto Hatch: ON" or "Auto Hatch: OFF"
    hatch.last = hatch.enabled and "Waiting for nearby Hatch!" or "OFF"
    hatchLabel.Text = hatch.last
    if not hatch.enabled and holding then pcall(function() holding:InputHoldEnd() end); holding = nil end
end)
local hatchRunning = false
local function dispatchHatch(manual)
    if hatchRunning then return end
    hatchRunning = true
    local ok, err = pcall(hatchStep, manual)
    hatchRunning = false
    if not ok and active then
        hatch.last = "Hatch test error: " .. tostring(err):sub(1, 100)
        hatchLabel.Text = hatch.last
    end
end
testHatch.Activated:Connect(function() task.spawn(dispatchHatch, true) end)
local function liveHatchSnapshot()
    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    local snapshot = {enabled = hatch.enabled, attempts = hatch.attempts, last = hatch.last,
        scanning = busy, inputInProgress = hatchRunning, cacheCount = 0,
        result = "Input attempts only; hatch success is not verified"}
    if root then snapshot.characterPosition = {x = root.Position.X, y = root.Position.Y, z = root.Position.Z} end
    snapshot.alive = humanoid ~= nil and humanoid.Health > 0
    local nearestDistance = math.huge
    for prompt in pairs(promptCache) do
        snapshot.cacheCount = snapshot.cacheCount + 1
        if prompt.Parent and prompt.ActionText == "Hatch!" and prompt:IsDescendantOf(workspace) then
            local position = promptPosition(prompt)
            local distance = position and root and (root.Position - position).Magnitude or math.huge
            if not snapshot.nearest or distance < nearestDistance then
                nearestDistance = distance
                local state = attemptState[prompt]
                local reason = "Ready to attempt"
                if not snapshot.alive then reason = "Character unavailable/dead"
                elseif not prompt.Enabled then reason = "Prompt disabled"
                elseif not position then reason = "Prompt location unavailable"
                elseif distance > math.min(prompt.MaxActivationDistance, 7) then reason = "Outside activation range"
                elseif prompt.HoldDuration < 0 or prompt.HoldDuration > 5 then reason = "Unsupported hold duration"
                elseif state and state.count >= 3 then reason = "Attempt cap reached; toggle OFF/ON to reset"
                elseif state and os.clock() - state.time < 4 then reason = "Cooldown"
                elseif busy then reason = "Scan in progress"
                elseif hatchRunning then reason = "Input in progress"
                elseif not hatch.enabled then reason = "Auto Hatch OFF; Test Hatch once is available" end
                snapshot.nearest = {path = prompt:GetFullName(), enabled = prompt.Enabled,
                    allowedDistance = math.min(prompt.MaxActivationDistance, 7),
                    holdDuration = prompt.HoldDuration, attempts = state and state.count or 0, reason = reason}
                if distance < math.huge then snapshot.nearest.distance = distance end
            end
        end
    end
    if not snapshot.nearest then snapshot.blocked = "No Hatch! prompt in cache" end
    return snapshot
end
-- AUTO_COLLECT_ENGINE_BEGIN
local collectTween
local walkingHumanoid
local deliveryPoint
local function cancelCollectTween(reason)
    if walkingHumanoid then
        local character=player.Character
        local root=character and character:FindFirstChild("HumanoidRootPart")
        if root then pcall(function() walkingHumanoid:MoveTo(root.Position) end) end
        walkingHumanoid=nil
    end
    if collectTween then collectTween:Cancel(); collectTween = nil end
    if collectEgg.moving then
        collectEgg.moving = false
        if collectEgg.lastMovement and collectEgg.phase ~= "RETURNING" then collectEgg.lastMovement.status = reason or "Cancelled" end
    end
end
local manualCarry = false
local serverCarry
local function dropCarryVisible()
    -- This UI was observed in the report. Inspect all ancestors, not just the label.
    local node = pg:FindFirstChild("DropHeldEgg")
    node = node and node:FindFirstChild("Button")
    if not node then return false end
    while node and node ~= pg do
        if node:IsA("GuiObject") and not node.Visible then return false end
        if node:IsA("LayerCollector") and not node.Enabled then return false end
        node = node.Parent
    end
    return node == pg
end
local function updateServerCarry(payload)
    if type(payload)~="table" or type(payload.IsCarrying)~="boolean" then return end
    serverCarry={isCarrying=payload.IsCarrying,character=player.Character,at=os.time(),clock=os.clock()}
    if type(payload.Uid)=="string" then serverCarry.uid=payload.Uid end
    if type(payload.RunBackWakeDelayRequired)=="boolean" then serverCarry.runBackWakeDelayRequired=payload.RunBackWakeDelayRequired end
end
local function fieldCarryActive()
    if serverCarry and serverCarry.character==player.Character then return serverCarry.isCarrying end
    return dropCarryVisible()
end
local function carryState()
    local state = {manualMarker = manualCarry, fieldCarryUI = dropCarryVisible(), fieldCarrying=fieldCarryActive(), equippedEgg = false,
        source = "none", pickupVerified = false}
    local character = player.Character
    if character then
        for _, child in ipairs(character:GetChildren()) do
            -- Observed ItemType, not a name match. Backpack eggs do not block collection.
            if child:IsA("Tool") and child:GetAttribute("ItemType") == "AssetEgg" then
                state.equippedEgg = true
                state.tool = {name = child.Name, uid = child:GetAttribute("UID")}
                break
            end
        end
    end
    state.blocked = state.manualMarker or state.fieldCarrying or state.equippedEgg
    if serverCarry and serverCarry.character==player.Character then
        state.serverCarrying=serverCarry.isCarrying;state.fieldEggUid=serverCarry.uid
        state.runBackWakeDelayRequired=serverCarry.runBackWakeDelayRequired
    end
    if state.fieldCarrying then state.source = serverCarry and serverCarry.character==player.Character and "field_carry_event" or "field_carry_ui"
    elseif state.equippedEgg then state.source = "equipped_asset_egg"
    elseif state.manualMarker then state.source = "user_marker" end
    return state
end
local function carryVisible()
    return carryState().blocked
end
local gameEvents = {}
local eventObserver = {hooked = {}, errors = {}}
local function eventValue(value, depth, seen)
    local kind=type(value)
    if kind=="nil" then return "<nil>" end
    if kind=="string" then return value:sub(1,180) end
    if kind=="number" then return value==value and value~=math.huge and value~=-math.huge and value or tostring(value) end
    if kind=="boolean" then return value end
    if typeof(value)=="Instance" then return {instance=value:GetFullName(),class=value.ClassName} end
    if typeof(value)=="Vector3" then return {x=value.X,y=value.Y,z=value.Z} end
    if kind~="table" then return "<"..kind..">" end
    if depth>=2 then return "<depth limit>" end
    if seen[value] then return "<cycle>" end
    seen[value]=true
    local result,count={},0
    for key,item in pairs(value) do
        if count>=8 then result.__truncated=true; break end
        if type(key)=="string" or type(key)=="number" then
            result[tostring(key):sub(1,80)]=eventValue(item,depth+1,seen);count=count+1
        end
    end
    seen[value]=nil
    return result
end
local function recordGameEvent(name, ...)
    if name=="RE/EggWorld/FieldEggCarry" then updateServerCarry((...)) end
    local args={}
    for i=1,math.min(select("#",...),6) do args[i]=eventValue(select(i,...),0,{}) end
    local state=carryState()
    local item={at=os.time(),clock=os.clock(),name=name,args=args,
        phase=collectEgg.phase or "IDLE",fieldCarryUI=state.fieldCarryUI,equippedEgg=state.equippedEgg}
    local character=player.Character
    local root=character and character:FindFirstChild("HumanoidRootPart")
    if root then item.position={x=root.Position.X,y=root.Position.Y,z=root.Position.Z} end
    gameEvents[#gameEvents+1]=item
    if #gameEvents>16 then table.remove(gameEvents,1) end
end
local function eggInventory()
    local snapshot = {items = {}, complete = true, count = 0}
    local backpack = player:FindFirstChildOfClass("Backpack")
    for _, container in pairs({character = player.Character, backpack = backpack}) do
        for i, child in ipairs(container:GetChildren()) do
            if i > 1000 then snapshot.complete = false; break end
            if child:IsA("Tool") and child:GetAttribute("ItemType") == "AssetEgg" then
                local uid = child:GetAttribute("UID")
                if type(uid) == "string" and uid ~= "" then
                    if not snapshot.items[uid] then snapshot.count = snapshot.count + 1 end
                    snapshot.items[uid] = {uid = uid, name = child.Name}
                else snapshot.complete = false end
            end
        end
    end
    return snapshot
end
local function newInventoryEggs(before, after)
    local added = {}
    if not before.complete or not after.complete then return added end
    for uid, item in pairs(after.items) do
        if not before.items[uid] then added[#added+1] = item end
    end
    table.sort(added,function(a,b) return a.uid < b.uid end)
    return added
end
local function collectCandidate(prompt, root, humanoid)
    if not prompt.Parent or not prompt:IsDescendantOf(workspace) then return nil, "Removed" end
    -- Exact prompt name/action/object observed in game. Do not guess Remote arguments.
    if prompt.Name ~= "CarryAreaEgg" or prompt.ActionText ~= "Steal" or prompt.ObjectText ~= "Egg" then
        return nil, "Different action"
    end
    if not prompt.Enabled then return nil, "Prompt disabled" end
    if not root or not humanoid or humanoid.Health <= 0 then return nil, "Character unavailable/dead" end
    if prompt.HoldDuration < 0 or prompt.HoldDuration > 5 then return nil, "Unsupported hold duration" end
    local position = promptPosition(prompt)
    if not position then return nil, "Prompt location unavailable" end
    local distance = (root.Position - position).Magnitude
    if distance > math.min(prompt.MaxActivationDistance, 8) then return nil, "Outside activation range" end
    return distance, "Ready to attempt"
end
local function approachCandidate(prompt, root, humanoid)
    if not prompt.Parent or not prompt:IsDescendantOf(workspace) then return nil end
    if prompt.Name ~= "CarryAreaEgg" or prompt.ActionText ~= "Steal" or prompt.ObjectText ~= "Egg"
        or prompt.HoldDuration < 0 or prompt.HoldDuration > 5 then return nil end
    if not root or not humanoid or humanoid.Health <= 0 or prompt.MaxActivationDistance < 1 then return nil end
    local position = promptPosition(prompt)
    if not position or math.abs(position.Y - root.Position.Y) > 6 then return nil end
    local distance = (root.Position - position).Magnitude
    if distance > 250 then return nil end
    local state = collectAttempts[prompt]
    if state and (state.count >= 3 or os.clock() - state.time < 4) then return nil end
    return distance, position
end
local function inCollectRange(prompt, root)
    local position = prompt.Parent and promptPosition(prompt)
    return position and root and (root.Position-position).Magnitude <= math.min(prompt.MaxActivationDistance,8)
end
local function pathMove(root, humanoid, character, destination, requireCarry, target)
    local record={at=os.time(),status="Computing path",waypoints=0,completed=0}
    collectEgg.lastNavigation=record
    local ok, route=pcall(function()
        local path=PathfindingService:CreatePath({AgentRadius=2,AgentHeight=5,AgentCanJump=true,WaypointSpacing=5})
        path:ComputeAsync(root.Position,destination)
        if path.Status ~= Enum.PathStatus.Success then return nil end
        return path:GetWaypoints()
    end)
    if not ok or not route or #route<2 or #route>80 then
        record.status=ok and "No path found within waypoint limit" or ("Pathfinding failed: "..tostring(route):sub(1,100))
        return false,record.status
    end
    local lift=math.clamp(root.Position.Y-route[1].Position.Y,0,6)
    local distance=0
    local last=root.Position
    for i,point in ipairs(route) do
        local goal=i==#route and destination or point.Position+Vector3.new(0,lift,0)
        distance=distance+(goal-last).Magnitude; last=goal
    end
    record.waypoints,record.routeDistance=#route,distance
    if distance>600 then record.status="Route exceeds 600 studs"; return false,record.status end
    local function stop(reason)
        record.status=reason
        recordGameEvent("navigation.stop",reason)
        cancelCollectTween(reason)
        return false,reason
    end
    local params=RaycastParams.new()
    params.FilterType=Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances={character}
    params.RespectCanCollide=true
    for i,point in ipairs(route) do
        if not active or not collectEgg.enabled then return stop("Route cancelled") end
        if busy then return stop("Route interrupted by scan") end
        if player.Character~=character or not root.Parent or humanoid.Health<=0 then return stop("Character changed during route") end
        if target and (not target.Parent or not target:IsDescendantOf(workspace)) then return stop("Route target removed") end
        if requireCarry and not fieldCarryActive() and (root.Position-destination).Magnitude>4 then return stop("Field carry disappeared during route") end
        if not requireCarry and carryVisible() then return stop("Holding state detected during route") end
        local goal=i==#route and destination or point.Position+Vector3.new(0,lift,0)
        local delta=goal-root.Position
        if delta.Magnitude>1.5 then
            if point.Action==Enum.PathWaypointAction.Jump then humanoid.Jump=true end
            record.status="Following path";record.currentWaypoint=i
            collectLabel.Text=string.format("Following path %d/%d",i,#route)
            local duration=delta.Magnitude/math.clamp(humanoid.WalkSpeed,8,24)
            collectEgg.moving=true
            collectTween=TweenService:Create(root,TweenInfo.new(duration,Enum.EasingStyle.Linear),{CFrame=root.CFrame+delta})
            collectTween:Play()
            local started=os.clock()
            while (root.Position-goal).Magnitude>1.5 do
                if not active or not collectEgg.enabled then return stop("Route cancelled") end
                if busy then return stop("Route interrupted by scan") end
                if player.Character~=character or not root.Parent or humanoid.Health<=0 then return stop("Character changed during route") end
                if target and not target.Parent then return stop("Route target removed") end
                if requireCarry and not dropCarryVisible() and (root.Position-destination).Magnitude>4 then return stop("Field carry disappeared during route") end
                if not requireCarry and carryVisible() then return stop("Holding state detected during route") end
                local ahead=goal-root.Position
                if workspace:Raycast(root.Position,ahead.Unit*math.min(2,ahead.Magnitude),params) then return stop("Route segment obstructed") end
                if os.clock()-started>duration+1 then return stop("Route segment timed out") end
                if not collectTween or collectTween.PlaybackState~=Enum.PlaybackState.Playing then return stop("Tween ended before waypoint") end
                task.wait(0.1)
            end
            cancelCollectTween("Waypoint reached")
        end
        record.completed=i
    end
    if not active or not collectEgg.enabled then return stop("Route cancelled") end
    if player.Character~=character or humanoid.Health<=0 then return stop("Character changed during route") end
    record.status="Route destination reached"
    return (root.Position-destination).Magnitude<=4,record.status
end
local function approachEgg(root, humanoid)
    if not root or not humanoid then return false end
    local choices = {}
    for prompt in pairs(promptCache) do
        local distance, position = approachCandidate(prompt, root, humanoid)
        if distance then choices[#choices + 1] = {prompt = prompt, distance = distance, position = position} end
    end
    table.sort(choices, function(a,b) return a.distance < b.distance end)
    local character = player.Character
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {character}
    params.RespectCanCollide = true
    local routeAttempts=0
    for _, choice in ipairs(choices) do
        local prompt, position = choice.prompt, choice.position
        local horizontal = Vector3.new(position.X-root.Position.X, 0, position.Z-root.Position.Z)
        local radius = math.min(prompt.MaxActivationDistance, 8)
        -- Stay at the character's current height; skip targets on another floor.
        local vertical = math.abs(position.Y-root.Position.Y)
        if vertical < radius then
            local stop = math.min(5, math.sqrt(radius*radius - vertical*vertical) * 0.8)
            local travel = math.max(0,horizontal.Magnitude-stop)
            if inCollectRange(prompt,root) and not prompt.Enabled then
                collectEgg.last = "In range; waiting for game to enable prompt"
                return false
            end
            if travel > 0.2 then
                local offset = horizontal.Unit * travel
                local obstacle = workspace:Raycast(root.Position, offset, params)
                if obstacle and routeAttempts<2 then
                    routeAttempts=routeAttempts+1
                    local reached,reason=pathMove(root,humanoid,character,root.Position+offset,false,prompt)
                    collectEgg.last=reason
                    if reached then
                        collectEgg.last=prompt.Enabled and "In pickup range" or "In range; waiting for game to enable prompt"
                        return inCollectRange(prompt,root) and prompt.Enabled
                    end
                    if not active or not collectEgg.enabled or carryVisible() then return false end
                end
                if not obstacle then
                    local speed = math.clamp(humanoid.WalkSpeed,8,24)
                    local duration = travel/speed
                    local record = {path = prompt:GetFullName(), distance = choice.distance,
                        speed = speed, at = os.time(), status = "Moving"}
                    collectEgg.lastMovement, collectEgg.moving = record, true
                    collectEgg.last = "Tweening to nearest reachable egg"
                    collectLabel.Text = collectEgg.last
                    collectTween = TweenService:Create(root,TweenInfo.new(duration,Enum.EasingStyle.Linear),
                        {CFrame = root.CFrame + offset})
                    collectTween:Play()
                    local started = os.clock()
                    local stopReason
                    while active and collectEgg.enabled and not busy and player.Character == character
                        and root.Parent and humanoid.Health > 0 and prompt.Parent
                        and not carryVisible() and os.clock()-started < duration+1 do
                        if inCollectRange(prompt,root) then break end
                        if not collectTween or collectTween.PlaybackState ~= Enum.PlaybackState.Playing then stopReason="Tween no longer playing"; break end
                        local current = promptPosition(prompt)
                        if not current or (current-position).Magnitude > 3 then stopReason="Target moved or disappeared"; break end
                        -- Recheck the next short segment for obstacles appearing during motion.
                        local ahead = offset.Unit * math.min(3, (position-root.Position).Magnitude)
                        if workspace:Raycast(root.Position,ahead,params) then stopReason="Obstacle appeared on approach"; break end
                        task.wait(0.1)
                    end
                    local arrived = active and collectEgg.enabled and player.Character == character
                        and humanoid.Health > 0 and inCollectRange(prompt,root)
                    local message = arrived and (prompt.Enabled and "In pickup range"
                        or "In range; waiting for game to enable prompt") or "Stopped before pickup range"
                    if not arrived then
                        if not active or not collectEgg.enabled then stopReason="Collect cancelled"
                        elseif player.Character ~= character or humanoid.Health<=0 then stopReason="Character changed or died"
                        elseif carryVisible() then stopReason="Holding state detected during approach"
                        elseif busy then stopReason="Scan interrupted approach"
                        elseif not prompt.Parent then stopReason="Target removed" end
                    end
                    record.stopReason=stopReason or message
                    record.endDistance=prompt.Parent and (root.Position-position).Magnitude or nil
                    cancelCollectTween(message)
                    collectEgg.last = record.status
                    return arrived and prompt.Enabled
                end
            end
        end
    end
    collectEgg.last = routeAttempts>0 and ("No reachable route: "..(collectEgg.lastNavigation and collectEgg.lastNavigation.status or "unknown"))
        or "No reachable egg within 250 studs on this level"
    return false
end
local function carryEvidence()
    -- Read fresh state on export, independently of the capped generic GUI scan.
    local evidence = {manualMarker = manualCarry, detector = "Field carry UI + equipped Tool ItemType=AssetEgg + explicit marker",
        characterChildren = {}, characterLinks = {}, truncated = false}
    local function attributes(obj)
        local values = {}
        if not obj then return values end
        local ok, attrs = pcall(function() return obj:GetAttributes() end)
        if ok then
            local count = 0
            for key,value in pairs(attrs) do
                if count >= 40 then evidence.truncated = true; break end
                if type(value) == "string" or type(value) == "boolean" or type(value) == "number" then
                    values[key] = type(value) == "string" and value:sub(1,160) or value
                    count = count + 1
                end
            end
        end
        return values
    end
    local character = player.Character
    evidence.playerAttributes, evidence.characterAttributes = attributes(player), attributes(character)
    evidence.dropGui = {found = false, ancestry = {}}
    local drop = pg:FindFirstChild("DropHeldEgg")
    local button = drop and drop:FindFirstChild("Button")
    evidence.dropGui.found = drop ~= nil
    evidence.dropGui.buttonFound = button ~= nil
    local node = button or drop
    while node and node ~= pg do
        local item = {name = node.Name, class = node.ClassName}
        if node:IsA("GuiObject") then item.visible = node.Visible end
        if node:IsA("LayerCollector") then item.enabled = node.Enabled end
        evidence.dropGui.ancestry[#evidence.dropGui.ancestry+1] = item
        node = node.Parent
    end
    if character then
        for i, child in ipairs(character:GetChildren()) do
            if i > 50 then evidence.truncated = true; break end
            evidence.characterChildren[#evidence.characterChildren+1] = {
                name = child.Name, class = child.ClassName, attributes = attributes(child)}
        end
        for i, obj in ipairs(character:GetDescendants()) do
            if i > 400 then evidence.truncated = true; break end
            if obj:IsA("WeldConstraint") or obj:IsA("JointInstance") then
                if #evidence.characterLinks >= 40 then evidence.truncated = true; break end
                local item = {name = obj.Name, class = obj.ClassName}
                if obj.Part0 then item.part0 = obj.Part0:GetFullName() end
                if obj.Part1 then item.part1 = obj.Part1:GetFullName() end
                evidence.characterLinks[#evidence.characterLinks+1] = item
            end
        end
    end
    return evidence
end
local function pauseCollect(reason)
    cancelCollectTween(reason)
    collectEgg.enabled = false
    collectEgg.pausedReason, collectEgg.last, collectEgg.phase = reason, reason, "PAUSED"
    if collectButton then collectButton.Text = "Collect: PAUSED"; collectButton.BackgroundColor3 = colors.panel end
end
local function setDeliveryPoint(position)
    if collectRunning then return false, "Stop Collect before changing the delivery point" end
    deliveryPoint = position
    return true
end
local function walkReturn(root,humanoid,character,destination)
    local nav={at=os.time(),mode="Humanoid.MoveTo",status="Planning ground return",completed=0}
    collectEgg.lastNavigation=nav
    local params=RaycastParams.new()
    params.FilterType=Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances={character}
    params.RespectCanCollide=true
    local route
    if workspace:Raycast(root.Position,destination-root.Position,params) then
        local ok,result=pcall(function()
            local path=PathfindingService:CreatePath({AgentRadius=2,AgentHeight=5,AgentCanJump=false,WaypointSpacing=5})
            path:ComputeAsync(root.Position,destination)
            if path.Status~=Enum.PathStatus.Success then return nil end
            return path:GetWaypoints()
        end)
        if not ok or not result or #result<2 or #result>80 then nav.status="No ground return path";return false,nav.status end
        route=result
    else route={{Position=destination}} end
    nav.waypoints=#route
    local total=0
    local previous=root.Position
    for _,point in ipairs(route) do total=total+(point.Position-previous).Magnitude;previous=point.Position end
    if total>600 then nav.status="Ground route exceeds 600 studs";return false,nav.status end
    nav.routeDistance=total
    local function stop(reason)
        nav.status=reason
        cancelCollectTween(reason)
        recordGameEvent("return.walk.stop",reason)
        return false,reason
    end
    for i,point in ipairs(route) do
        local goal=i==#route and destination or point.Position
        local started=os.clock()
        local deadline=(root.Position-goal).Magnitude/math.max(humanoid.WalkSpeed,1)+5
        nav.currentWaypoint=i
        if not active or not collectEgg.enabled then return stop("Return cancelled") end
        if player.Character~=character or not root.Parent or humanoid.Health<=0 then return stop("Character changed during return") end
        if not fieldCarryActive() and (root.Position-destination).Magnitude>4 then return stop("Game no longer reports field egg carrying") end
        walkingHumanoid=humanoid
        collectEgg.moving=true
        humanoid:MoveTo(goal)
        local refreshed=os.clock()
        -- Waypoints lie on the floor; compare horizontal arrival without lifting the root.
        local function reached()
            local offset=root.Position-goal
            local radius=i==#route and 1.5 or 2.5
            return math.sqrt(offset.X*offset.X+offset.Z*offset.Z)<=radius and math.abs(offset.Y)<=6
        end
        -- MoveTo handles physics and natural height. Never tween CFrame or force a jump while carrying.
        while not reached() do
            if not active or not collectEgg.enabled then return stop("Return cancelled") end
            if player.Character~=character or not root.Parent or humanoid.Health<=0 then return stop("Character changed during return") end
            if busy then return stop("Return interrupted by scan") end
            if not fieldCarryActive() and (root.Position-destination).Magnitude>4 then return stop("Game no longer reports field egg carrying") end
            if os.clock()-started>deadline then return stop("Ground return stalled at waypoint "..i) end
            if os.clock()-refreshed>=1 then humanoid:MoveTo(goal);refreshed=os.clock() end
            nav.status="Walking home";collectLabel.Text=string.format("Walking home %d/%d",i,#route)
            task.wait(0.1)
        end
        nav.completed=i
    end
    if not active or not collectEgg.enabled then return stop("Return cancelled") end
    cancelCollectTween("At delivery point")
    nav.status="Ground return reached delivery point"
    return true,nav.status
end
local function returnHome(root, humanoid, character)
    if not deliveryPoint then pauseCollect("Holding field egg: set your delivery point in Settings"); return end
    if not root or not humanoid or humanoid.Health <= 0 then pauseCollect("Character unavailable during return"); return end
    collectEgg.phase = "RETURNING"
    collectLabel.Text = "Returning field egg to configured delivery point"
    local delta = deliveryPoint-root.Position
    local record = {at = os.time(), status = "Returning", startDistance = delta.Magnitude,
        destination = {x=deliveryPoint.X,y=deliveryPoint.Y,z=deliveryPoint.Z}}
    collectEgg.lastReturn = record
    record.startedClock=os.clock()
    if serverCarry and serverCarry.character==character and serverCarry.isCarrying then
        record.confirmationToReturnMs=math.max(0,(record.startedClock-serverCarry.clock)*1000)
    end
    if delta.Magnitude > 600 then pauseCollect("Delivery point beyond 600 studs"); record.status=collectEgg.last; return end
    if delta.Magnitude > 1.5 then
        local reached,reason=walkReturn(root,humanoid,character,deliveryPoint)
        record.status,record.endDistance=reason,(root.Position-deliveryPoint).Magnitude
        if not reached then
            record.routeReason=reason
            if active and collectEgg.enabled then pauseCollect(reason) end
            return
        end
    end
    collectEgg.phase = "DELIVERING"
    collectLabel.Text = "At delivery point; waiting for game result"
    local before = collectEgg.tripInventory
    local deadline = os.clock()+5
    local clearSince
    while active and collectEgg.enabled and player.Character == character and humanoid.Health > 0 and os.clock()<deadline do
        if (root.Position-deliveryPoint).Magnitude > 6 then pauseCollect("Moved away from delivery point"); record.status=collectEgg.last; return end
        if fieldCarryActive() then clearSince=nil else clearSince=clearSince or os.clock() end
        if clearSince and os.clock()-clearSince>=1 then
            local added = before and newInventoryEggs(before,eggInventory()) or {}
            record.inventoryAdded = added
            if #added>0 then
                record.status="Delivery inferred: carry cleared and new egg UID observed at home"
                collectEgg.deliveriesObserved=(collectEgg.deliveriesObserved or 0)+1
                collectEgg.tripInventory=nil
                collectEgg.phase="SEEKING"
                collectEgg.last=record.status
            else
                record.status="Carry cleared at home but inventory delivery unconfirmed"
                pauseCollect(record.status)
            end
            return
        end
        task.wait(0.1)
    end
    record.status="Home reached but game did not accept the egg"
    if active and collectEgg.enabled then pauseCollect(record.status .. "; check delivery point") end
end
local function collectSnapshot(includeEvidence)
    local snapshot = {enabled = collectEgg.enabled, attempts = collectEgg.attempts,
        last = collectEgg.last, lastInput = collectEgg.lastInput, scanning = busy,
        unconfirmed = collectEgg.unconfirmed or 0, pausedReason = collectEgg.pausedReason,
        inventoryAdditionsObserved = collectEgg.inventoryAdditionsObserved or 0,
        phase = collectEgg.phase or "IDLE", deliveriesObserved = collectEgg.deliveriesObserved or 0,
        gameEvents = gameEvents, eventObserver = eventObserver,
        lastReturn = collectEgg.lastReturn, lastNavigation = collectEgg.lastNavigation, deliveryPointSet = deliveryPoint ~= nil,
        inputInProgress = collectRunning, carrying = carryVisible(), carryState = carryState(), matchingPrompts = 0,
        scope = "Tween pickup within 250 studs; native ground walking return within 600 studs",
        moving = collectEgg.moving == true, lastMovement = collectEgg.lastMovement,
        result = "Input attempts only; pickup success is not verified"}
    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    local nearestDistance = math.huge
    for prompt in pairs(promptCache) do
        if prompt.Parent and prompt.Name == "CarryAreaEgg" and prompt.ActionText == "Steal"
            and prompt.ObjectText == "Egg" and prompt:IsDescendantOf(workspace) then
            snapshot.matchingPrompts = snapshot.matchingPrompts + 1
            local pos = promptPosition(prompt)
            local distance = pos and root and (root.Position - pos).Magnitude or math.huge
            if not snapshot.nearest or distance < nearestDistance then
                nearestDistance = distance
                local _, reason = collectCandidate(prompt, root, humanoid)
                local state = collectAttempts[prompt]
                if snapshot.carrying then reason = "Egg held/equipped; collection paused"
                elseif busy then reason = "Scan in progress"
                elseif state and state.count >= 3 then reason = "Attempt cap reached; toggle OFF/ON to reset"
                elseif state and os.clock() - state.time < 4 then reason = "Cooldown" end
                snapshot.nearest = {path = prompt:GetFullName(), enabled = prompt.Enabled,
                    allowedDistance = math.min(prompt.MaxActivationDistance, 8),
                    holdDuration = prompt.HoldDuration, attempts = state and state.count or 0, reason = reason}
                if pos and root then
                    snapshot.nearest.heightDifference = math.abs(pos.Y-root.Position.Y)
                    snapshot.nearest.approachHeightLimit = 6
                    snapshot.nearest.approachDistanceLimit = 250
                end
                if distance < math.huge then snapshot.nearest.distance = distance end
            end
        end
    end
    if includeEvidence then snapshot.carryEvidence = carryEvidence() end
    if snapshot.matchingPrompts == 0 then snapshot.blocked = "No CarryAreaEgg / Steal prompt in cache" end
    return snapshot
end
local function collectStep()
    if not active or not collectEgg.enabled or busy or hatchRunning then return end
    local carrying = carryState()
    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if carrying.manualMarker then collectEgg.last="User carrying marker active"; return end
    if carrying.fieldCarrying then returnHome(root,humanoid,character); return end
    if carrying.equippedEgg then collectEgg.last="Inventory egg equipped; unequip to collect field eggs"; return end
    collectEgg.phase="SEEKING"
    local best, bestDistance
    for prompt in pairs(promptCache) do
        local distance = collectCandidate(prompt, root, humanoid)
        local state = collectAttempts[prompt]
        if distance and (not state or state.count < 3 and os.clock() - state.time >= 4)
            and (not bestDistance or distance < bestDistance) then
            best, bestDistance = prompt, distance
        end
    end
    if not best then
        if approachEgg(root, humanoid) and active and collectEgg.enabled and not busy and not carryVisible() then
            -- Re-evaluate range and target after movement, never press from a stale snapshot.
            for prompt in pairs(promptCache) do
                local distance = collectCandidate(prompt,root,humanoid)
                local state = collectAttempts[prompt]
                if distance and (not state or state.count < 3 and os.clock()-state.time >= 4)
                    and (not bestDistance or distance < bestDistance) then best,bestDistance = prompt,distance end
            end
        end
        if not best then return end
    end
    collectEgg.phase="PICKUP"
    local inventoryBefore = eggInventory()
    local state = collectAttempts[best] or {count = 0, time = -math.huge}
    collectAttempts[best] = state
    state.count, state.time = state.count + 1, os.clock()
    collectEgg.attempts = collectEgg.attempts + 1
    local record = {path = best:GetFullName(), distance = bestDistance, at = os.time(), status = "Started"}
    collectEgg.lastInput = record
    recordGameEvent("collect.input.begin",best:GetFullName())
    local ok, err = pcall(function()
        holding = best
        best:InputHoldBegin()
        task.wait(best.HoldDuration + 0.1)
        best:InputHoldEnd()
        holding = nil
    end)
    if holding then pcall(function() holding:InputHoldEnd() end); holding = nil end
    record.status = ok and "Input sent; pickup unverified" or "Input failed"
    if not ok then record.error = tostring(err):sub(1,120) end
    if ok and active and collectEgg.enabled then
        collectEgg.last = "Waiting for pickup result"
        local deadline = os.clock() + 3
        while active and collectEgg.enabled and player.Character == character and humanoid.Health > 0
            and not carryVisible() and os.clock() < deadline do
            if #newInventoryEggs(inventoryBefore, eggInventory()) > 0 then break end
            task.wait(0.1)
        end
    end
    local inventoryAfter = eggInventory()
    record.inventoryAdded = newInventoryEggs(inventoryBefore, inventoryAfter)
    record.inventoryBeforeCount, record.inventoryAfterCount = inventoryBefore.count, inventoryAfter.count
    record.inventoryComparisonComplete = inventoryBefore.complete and inventoryAfter.complete
    record.carryStateAfter = carryState()
    if record.carryStateAfter.fieldCarrying then collectEgg.tripInventory=inventoryBefore end
    record.carryVisibleAfter = record.carryStateAfter.blocked
    if #record.inventoryAdded > 0 then
        record.outcome = "New egg UID observed after input; acquisition source not verified"
        collectEgg.inventoryAdditionsObserved = (collectEgg.inventoryAdditionsObserved or 0) + #record.inventoryAdded
        collectEgg.unconfirmed = 0
    elseif record.carryVisibleAfter then
        record.outcome = record.carryStateAfter.fieldCarrying and (record.carryStateAfter.serverCarrying and "Game reported field egg carrying" or "Field carry UI detected; pickup inferred from UI")
            or record.carryStateAfter.equippedEgg and "Egg tool equipped; field pickup not verified"
            or "User marked carrying; game pickup not verified"
        collectEgg.unconfirmed = 0
    elseif not active or not collectEgg.enabled then
        record.outcome = "Cancelled before pickup confirmation"
    else
        record.outcome = "No carry state or new egg UID detected after input"
        collectEgg.unconfirmed = (collectEgg.unconfirmed or 0) + 1
        if collectEgg.unconfirmed >= 1 then
            collectEgg.enabled = false
            collectEgg.pausedReason = "Pickup state uncertain; paused after one input to avoid moving while carrying"
            if collectButton then
                collectButton.Text = "Collect: PAUSED"
                collectButton.BackgroundColor3 = colors.panel
            end
        end
    end
    recordGameEvent("collect.input.outcome",record.outcome)
    if active then collectEgg.last = collectEgg.pausedReason or record.outcome end
    -- Continue the pickup/return cycle in this same dispatch, without waiting
    -- for the next one-second scheduler tick.
    if active and collectEgg.enabled and not busy and player.Character==character
        and humanoid.Health>0 and not manualCarry and fieldCarryActive() then
        record.returnDispatchedClock=os.clock()
        returnHome(root,humanoid,character)
    end
end
local function dispatchCollect()
    if collectRunning or hatchRunning then return end
    collectRunning = true
    local ok, err = pcall(collectStep)
    collectRunning = false
    if not ok then cancelCollectTween("Movement error") end
    if not ok and active then collectEgg.last = "Collect error: " .. tostring(err):sub(1,100) end
end
local function setManualCarry(value)
    manualCarry = value == true
    if manualCarry then
        cancelCollectTween("User marked carrying")
        collectEgg.enabled = false
        collectEgg.last = "User marked carrying; Collect OFF"
    end
end
-- AUTO_COLLECT_ENGINE_END
-- Read-only event observations. Payloads are bounded and are not interpreted as
-- authoritative carry state until the event contract is established.
local watchedEvents = {
    ["RE/EggWorld/FieldEggCarry"]=true, ["RE/EggWorld/FieldEggGone"]=true,
    ["RE/EggWorld/FieldEggRedeemVerdict"]=true, ["RE/EggWorld/OwnerDropped"]=true,
    ["RE/EggWorld/OwnerShifted"]=true, ["RE/GuardPatrol/SpeedTollWarning"]=true,
}
local hookedEvents=setmetatable({}, {__mode="k"})
local storage=game:GetService("ReplicatedStorage")
local function observeGameEvent(obj)
    if not obj:IsA("RemoteEvent") or not watchedEvents[obj.Name] or hookedEvents[obj] then return end
    local packages=storage:FindFirstChild("Packages")
    local networking=packages and packages:FindFirstChild("Networking")
    if not networking or not obj:IsDescendantOf(networking) then return end
    local ok,connection=pcall(function()
        return obj.OnClientEvent:Connect(function(...)
            if not active then return end
            local success,err=pcall(recordGameEvent,obj.Name,...)
            if not success then eventObserver.lastError=tostring(err):sub(1,100) end
        end)
    end)
    if ok then
        hookedEvents[obj]=true
        connections[#connections+1]=connection
        eventObserver.hooked[#eventObserver.hooked+1]=obj.Name
    else eventObserver.errors[#eventObserver.errors+1]=tostring(connection):sub(1,100) end
end
connections[#connections+1]=storage.DescendantAdded:Connect(observeGameEvent)
local packages=storage:FindFirstChild("Packages")
local networking=packages and packages:FindFirstChild("Networking")
if networking then
    for _, obj in ipairs(networking:GetDescendants()) do observeGameEvent(obj) end
end

setHomeButton.Activated:Connect(function()
    local character=player.Character
    local root=character and character:FindFirstChild("HumanoidRootPart")
    if not root then status.Text="Character unavailable; cannot set delivery point"; return end
    local ok,err=setDeliveryPoint(root.Position)
    status.Text=ok and "Delivery point set at your current position for this session" or err
    if ok then setHomeButton.Text="Delivery point SET • click to replace" end
end)
clearHomeButton.Activated:Connect(function()
    local ok,err=setDeliveryPoint(nil)
    status.Text=ok and "Delivery point cleared" or err
    if ok then setHomeButton.Text="Set delivery point here" end
end)
carryMarker.Activated:Connect(function()
    setManualCarry(not manualCarry)
    carryMarker.Text = manualCarry and "Carrying marker ON • click to clear" or "Mark: I am carrying an egg"
    collectButton.Text = collectEgg.enabled and "Collect: ON" or "Collect: OFF"
    collectLabel.Text = manualCarry and "Carrying (marked by user); deliver manually" or "Carrying marker cleared"
end)
connections[#connections+1] = player.CharacterAdded:Connect(function()
    cancelCollectTween("Character changed")
    serverCarry=nil
    collectEgg.enabled=false
    collectEgg.tripInventory=nil
    collectEgg.phase="PAUSED"
    collectButton.Text="Collect: OFF"
    setManualCarry(false)
    carryMarker.Text = "Mark: I am carrying an egg"
end)
collectButton.Activated:Connect(function()
    collectEgg.enabled = not collectEgg.enabled
    collectEgg.phase=collectEgg.enabled and "SEEKING" or "IDLE"
    collectAttempts = setmetatable({}, {__mode = "k"})
    collectEgg.unconfirmed, collectEgg.pausedReason = 0, nil
    collectButton.Text = collectEgg.enabled and "Collect: ON" or "Collect: OFF"
    collectButton.BackgroundColor3 = collectEgg.enabled and colors.purple or colors.panel
    collectEgg.last = collectEgg.enabled and "Waiting for nearby egg" or "OFF"
    collectLabel.Text = collectEgg.last
    if not collectEgg.enabled then cancelCollectTween("Collect OFF") end
    if not collectEgg.enabled and collectRunning and holding then
        pcall(function() holding:InputHoldEnd() end); holding = nil
    end
end)
-- Seed existing prompts independently of the capped diagnostic scan. Subsequent
-- changes use the existing DescendantAdded/Removing listeners; no per-tick scan.
task.spawn(function()
    local queue, head = {workspace}, 1
    while active and head <= #queue do
        local obj = queue[head]
        queue[head] = false
        head = head + 1
        if obj == workspace or obj:IsDescendantOf(workspace) then
            trackPrompt(obj)
            for _, child in ipairs(obj:GetChildren()) do queue[#queue + 1] = child end
        end
        if head % 250 == 0 then task.wait() end
    end
end)
local function refreshExportState()
    if reportText == "" then return end
    local snapshot = liveHatchSnapshot()
    -- Replace the old scan-time snapshot at copy/save time, without rescanning.
    local full = Http:JSONDecode(reportText)
    full.autoHatch = snapshot
    full.autoCollect = collectSnapshot(true)
    reportText = Http:JSONEncode(full)
    local short = Http:JSONDecode(shortReportText)
    short.autoHatch = snapshot
    short.autoCollect = full.autoCollect
    shortReportText = Http:JSONEncode(short)
    splitPages(reportText)
end
local function stopHatch()
    active = false
    hatch.enabled = false
    collectEgg.enabled = false
    cancelCollectTween("UI closed")
    if cameraConnection then cameraConnection:Disconnect() end
    if holding then pcall(function() holding:InputHoldEnd() end); holding = nil end
    for _, connection in ipairs(connections) do connection:Disconnect() end
end
local lifetime = gui.AncestryChanged:Connect(function(_, parent)
    if parent == nil then stopHatch() end
end)
task.spawn(function()
    while active do
        task.wait(1)
        dispatchCollect()
        dispatchHatch(false)
        if active and collectEgg.enabled then
            local ok, snapshot = pcall(collectSnapshot)
            if ok then
                local n = snapshot.nearest
                collectLabel.Text = "Collect: " .. (snapshot.carrying and "Egg held/equipped; collection paused"
                    or n and (n.reason .. (n.distance and string.format(" | %.1f/%.1f studs",n.distance,n.allowedDistance) or ""))
                    or snapshot.blocked or collectEgg.last) .. " | Attempts " .. collectEgg.attempts
            end
        end
        if active and hatch.enabled and not hatchRunning then
            local ok, snapshot = pcall(liveHatchSnapshot)
            if ok then
                local nearest = snapshot.nearest
                hatchLabel.Text = nearest and (nearest.reason .. (nearest.distance and string.format(" | %.1f/%.1f studs", nearest.distance, nearest.allowedDistance) or ""))
                    or (snapshot.blocked or hatch.last)
            end
        end
    end
end)
-- AUTO_HATCH_END
local function path(obj)
    return obj:GetFullName()
end
local function collect()
    if busy or not active then return end
    busy = true
    scan.Text = "Scanning..."
    local ok, err = pcall(function()
        local report = {version = "1.20", placeId = game.PlaceId,
            scanned = 0, truncated = false, roots = {},
            gui = {}, prompts = {}, remotes = {}, candidates = {}}
        local roots = {
            {object = pg, label = "PlayerGui", budget = 6000},
            {object = workspace, label = "Workspace", budget = 12000},
            {object = game:GetService("ReplicatedStorage"), label = "ReplicatedStorage", budget = 6000},
        }
        local keywords = {"egg", "hatch", "collect", "cash", "money", "upgrade", "tread", "train", "speed", "base", "plot"}
        local function relevant(name)
            name = string.lower(name)
            for _, word in ipairs(keywords) do
                if string.find(name, word, 1, true) then return true end
            end
            return false
        end
        local function visible(obj)
            local node = obj
            while node and node ~= pg do
                if node:IsA("GuiObject") and not node.Visible then return false end
                if node:IsA("LayerCollector") and not node.Enabled then return false end
                node = node.Parent
            end
            return node == pg
        end
        for _, root in ipairs(roots) do
            if not active then return end
            local info = {name = root.label, scanned = 0, dropped = {},
                topLevel = {}, skipped = {}, truncated = false}
            table.insert(report.roots, info)
            local counts = {}
            local function add(kind, item)
                counts[kind] = counts[kind] or 0
                if counts[kind] < 300 then
                    counts[kind] = counts[kind] + 1
                    table.insert(report[kind], item)
                else
                    info.dropped[kind] = (info.dropped[kind] or 0) + 1
                    info.truncated = true
                end
            end
            -- FIFO plus separate budgets prevent large asset trees starving live UI/world.
            local queue, head = {root.object}, 1
            local deadline = os.clock() + 5
            while head <= #queue and info.scanned < root.budget and active do
                if os.clock() > deadline then info.timeLimit = true; break end
                local obj = queue[head]
                head = head + 1
                info.scanned = info.scanned + 1
                local excluded = obj == gui or obj:IsDescendantOf(gui)
                local asset = root.label == "ReplicatedStorage"
                    and obj.Parent == root.object and obj.Name == "Assets"
                if asset then table.insert(info.skipped, path(obj)) end
                if not excluded and not asset then
                    local item = {path = path(obj), class = obj.ClassName}
                    if obj.Parent == root.object and #info.topLevel < 100 then
                        table.insert(info.topLevel, item)
                    end
                    if root.label == "PlayerGui" and
                        (obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox")) then
                        item.text = string.sub(obj.Text, 1, 180)
                        item.visible = visible(obj)
                        add("gui", item)
                    elseif root.label == "Workspace" and obj:IsA("ProximityPrompt") then
                        trackPrompt(obj)
                        item.action = obj.ActionText
                        item.object = obj.ObjectText
                        item.enabled = obj.Enabled
                        item.distance = obj.MaxActivationDistance
                        item.holdDuration = obj.HoldDuration
                        local parent = obj.Parent
                        local location
                        if parent and parent:IsA("Attachment") then location = parent.WorldPosition
                        elseif parent and parent:IsA("BasePart") then location = parent.Position
                        elseif parent and parent:IsA("Model") then location = parent:GetPivot().Position end
                        if location then item.position = {x = location.X, y = location.Y, z = location.Z} end
                        add("prompts", item)
                    elseif obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") or obj:IsA("UnreliableRemoteEvent") then
                        add("remotes", item)
                    elseif (obj:IsA("Model") or obj:IsA("Folder") or obj:IsA("BasePart")
                        or obj:IsA("ValueBase") or obj:IsA("ModuleScript"))
                        and relevant(obj.Name) then
                        if obj:IsA("BasePart") then
                            local pos = obj.Position
                            item.position = {x = pos.X, y = pos.Y, z = pos.Z}
                        end
                        if obj:IsA("ValueBase") then
                            local value = obj.Value
                            if type(value) == "number" or type(value) == "boolean" or type(value) == "string" then
                                item.value = value
                            end
                        end
                        local attrs = {}
                        for key, value in pairs(obj:GetAttributes()) do
                            local lower = string.lower(key)
                            if (lower:find("owner", 1, true) or lower:find("plot", 1, true))
                                and (type(value) == "number" or type(value) == "string" or type(value) == "boolean") then
                                attrs[key] = value
                            end
                        end
                        item.ownership = attrs
                        add("candidates", item)
                    end
                    for _, child in ipairs(obj:GetChildren()) do
                        if #queue < 30000 then table.insert(queue, child)
                        else info.queueLimit = true; info.truncated = true end
                    end
                end
                if info.scanned % 150 == 0 then task.wait() end
            end
            if head <= #queue then info.truncated = true end
            report.scanned = report.scanned + info.scanned
            report.truncated = report.truncated or info.truncated
        end
        -- Inventory the observed networking folder directly, bypassing the generic
        -- result cap. This only reads Instances; no Remote is invoked.
        local storage = game:GetService("ReplicatedStorage")
        local packages = storage:FindFirstChild("Packages")
        local networking = packages and packages:FindFirstChild("Networking")
        report.networking = {found = networking ~= nil, scanned = 0, truncated = false}
        if networking then
            local known = {}
            for _, item in ipairs(report.remotes) do known[item.path] = true end
            local queue, head = {networking}, 1
            while head <= #queue and report.networking.scanned < 4000 and active do
                local obj = queue[head]
                head = head + 1
                report.networking.scanned = report.networking.scanned + 1
                if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") or obj:IsA("UnreliableRemoteEvent") then
                    local fullPath = path(obj)
                    if not known[fullPath] then
                        table.insert(report.remotes, {path = fullPath, name = obj.Name, class = obj.ClassName})
                        known[fullPath] = true
                    end
                end
                for _, child in ipairs(obj:GetChildren()) do
                    if #queue < 8000 then table.insert(queue, child)
                    else report.networking.truncated = true end
                end
                if report.networking.scanned % 150 == 0 then task.wait() end
            end
            if head <= #queue then report.networking.truncated = true end
        end
        -- Rank gameplay systems ahead of unrelated live events and cosmetics.
        local function rank(item, kind)
            local name = string.lower((item.path or "") .. " " .. (item.text or "") .. " " .. (item.action or ""))
            local score = 0
            for _, word in ipairs({"hatch", "treadmill", "upgrade", "egg", "plot", "base", "cash", "money", "coin", "speed", "penroster"}) do
                if name:find(word, 1, true) then score = score + 10 end
            end
            if name:find("trainevent", 1, true) or name:find("liveevents", 1, true)
                or name:find("sammy", 1, true) or name:find("lightvsdarkness", 1, true)
                or name:find("beanstalk", 1, true) or name:find("observability", 1, true)
                or name:find("adgrowth", 1, true) or name:find("adegg", 1, true)
                or name:find("cmdr", 1, true) or name:find("ghostboss", 1, true) then score = score - 100 end
            if kind == "gui" and item.visible then score = score + 3 end
            if kind == "prompts" and item.enabled then score = score + 5 end
            return score
        end
        local function sorted(kind)
            local items = {}
            for _, item in ipairs(report[kind]) do table.insert(items, item) end
            table.sort(items, function(a, b)
                local ar, br = rank(a, kind), rank(b, kind)
                if ar ~= br then return ar > br end
                return a.path < b.path
            end)
            return items
        end
        report.autoHatch = liveHatchSnapshot()
        report.autoCollect = collectSnapshot(true)
        reportText = Http:JSONEncode(report)
        local summary = {version = "1.20", placeId = report.placeId, summaryOnly = true,
            scanned = report.scanned, truncated = report.truncated, networking = report.networking, autoHatch = report.autoHatch, autoCollect = report.autoCollect,
            gui = {}, prompts = {}, remotes = {}, candidates = {},
            omitted = {gui = 0, prompts = 0, remotes = 0, candidates = 0}}
        -- Each category owns its own space: remote spam cannot erase GUI/prompts.
        local limits = {remotes = 6000, gui = 3000, prompts = 2000, candidates = 3000}
        for _, kind in ipairs({"remotes", "gui", "prompts", "candidates"}) do
            local seen, used = {}, 0
            for _, item in ipairs(sorted(kind)) do
                local useful = rank(item, kind) > 0 or kind == "prompts" and item.enabled
                local small = {}
                for key, value in pairs(item) do small[key] = value end
                -- Ownership/position retained on candidates; duplicates retain count.
                local key = Http:JSONEncode(item)
                if useful and seen[key] then
                    seen[key].count = (seen[key].count or 1) + 1
                    summary.omitted[kind] = summary.omitted[kind] + 1
                elseif useful then
                    local bytes = #Http:JSONEncode(small) + 24
                    if used + bytes <= limits[kind] then
                        table.insert(summary[kind], small)
                        seen[key] = small
                        used = used + bytes
                    else summary.omitted[kind] = summary.omitted[kind] + 1 end
                else summary.omitted[kind] = summary.omitted[kind] + 1 end
            end
        end
        shortReportText = Http:JSONEncode(summary)
        if not active then return end
        splitPages(reportText)
        status.Text = string.format("v1.20 | Scanned %d | GUI %d | Prompts %d | Remotes %d | Limited: %s", report.scanned, #report.gui, #report.prompts, #report.remotes, tostring(report.truncated))
    end)
    busy = false
    if active then
        scan.Text = "Scan / Refresh"
        if not ok then status.Text = "Scan failed: " .. tostring(err) end
    end
end
scan.Activated:Connect(function() task.spawn(collect) end)
local copying = false
local function exportCopy(short)
    if busy or copying then status.Text = "Please wait for scan/copy to finish."; return end
    if reportText == "" then status.Text = "No report. Press Scan first."; return end
    copying = true
    status.Text = "Copying on TEST PC..."
    task.spawn(function()
        local ok, err = pcall(function()
            refreshExportState()
            copyPayload(short and shortReportText or reportText, short and "SHORT report" or "FULL report")
        end)
        copying = false
        if not ok and active then
            status.Text = "Copy error: " .. tostring(err):sub(1, 120) .. ". Try Select ALL, then Ctrl+C."
        end
    end)
end
copy.Activated:Connect(function() exportCopy(false) end)
shortCopy.Activated:Connect(function() exportCopy(true) end)
save.Activated:Connect(function()
    if busy then status.Text = "Scanning. Wait for completion."; return end
    if reportText == "" then status.Text = "No report. Press Scan first."; return end
    local refreshed, refreshError = pcall(refreshExportState)
    if not refreshed then status.Text = "Export refresh failed: " .. tostring(refreshError):sub(1, 100); return end
    local writer = capability("writefile")
    if not writer then
        selectAll()
        status.Text = "File saving unavailable. Use Select ALL, then Ctrl+C for the full report."
        return
    end
    local filename = "StealAnEgg_Report_" .. tostring(os.time()) .. ".json"
    local ok, result = pcall(writer, filename, reportText)
    if not ok or result == false then
        status.Text = "File save failed. Use Select ALL and Ctrl+C."
        return
    end
    local reader = capability("readfile")
    if reader then
        local readOK, saved = pcall(reader, filename)
        if not readOK or saved ~= reportText then
            status.Text = "Could not verify saved file. Use Select ALL as fallback."
            return
        end
    end
    status.Text = "Saved " .. filename .. " in your executor workspace. Upload that file to chat."
end)
selectText.Activated:Connect(selectAll)
previous.Activated:Connect(function() pageIndex = math.max(1, pageIndex - 1); showPage() end)
following.Activated:Connect(function() pageIndex = math.max(1, math.min(#pages, pageIndex + 1)); showPage() end)
close.Activated:Connect(function() stopHatch(); lifetime:Disconnect(); gui:Destroy() end)
task.spawn(collect)







