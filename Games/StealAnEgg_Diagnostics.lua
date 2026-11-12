-- Steal An Egg: structure diagnostics v1.44
-- Auto Hatch test via nearby enabled prompts; Auto Collect tests nearby CarryAreaEgg prompts; remaining systems await mapping.
local AUTO_PLACE_ENABLED = false -- Disabled after user-confirmed BAC kick reports.
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
label(frame, "STEAL AN EGG  /  v1.44", 20,40,300,20,11,colors.muted)
local minimize = control(frame, "—", 670,16,32,30)
local close = control(frame, "X", 710,16,32,30)
local sidebar = create("Frame", frame, {Position = UDim2.fromOffset(12,76), Size = UDim2.fromOffset(148,382), BackgroundColor3 = colors.panel})
round(sidebar)
label(sidebar, "WORKSPACE",12,10,125,22,10,colors.muted)
local automation = create("Frame", frame, {Position = UDim2.fromOffset(176,76), Size = UDim2.fromOffset(568,382), BackgroundTransparency = 1})
local diagnostics = create("Frame", frame, {Position = automation.Position, Size = automation.Size, BackgroundTransparency = 1, Visible = false})
local settings = create("Frame", frame, {Position = automation.Position, Size = automation.Size, BackgroundTransparency = 1, Visible = false})
local placement = create("Frame", frame, {Position=automation.Position,Size=automation.Size,BackgroundTransparency=1,Visible=false})
local eggUI={}
eggUI.page = create("Frame",frame,{Position=automation.Position,Size=automation.Size,BackgroundTransparency=1,Visible=false})
local tabs = {}
local function showTab(name)
    automation.Visible = name == "Automation"
    diagnostics.Visible = name == "Diagnostics"
    settings.Visible = name == "Settings"
    placement.Visible = name == "Placement"
    eggUI.page.Visible = name == "Eggs"
    for key, b in pairs(tabs) do
        b.BackgroundColor3 = key == name and colors.purple or colors.panel
    end
end
for i, name in ipairs({"Automation", "Eggs", "Placement", "Diagnostics", "Settings"}) do
    local b = control(sidebar,name,8,42+(i-1)*44,132,36)
    tabs[name] = b
    b.Activated:Connect(function() showTab(name) end)
end
label(sidebar,"By Yuu Walker",12,344,130,22,11,colors.muted)
label(eggUI.page,"Egg data & selection",0,0,560,30,22)
eggUI.scanButton=control(eggUI.page,"Scan eggs",0,42,120,34)
eggUI.modeButton=control(eggUI.page,"Mode: NEAREST",130,42,200,34)
eggUI.countLabel=label(eggUI.page,"Not scanned",340,42,220,34,11,colors.muted)
label(eggUI.page,"Preferred egg names, best first (comma separated)",0,84,560,22,12)
eggUI.preferredBox=create("TextBox",eggUI.page,{Position=UDim2.fromOffset(0,110),Size=UDim2.fromOffset(568,30),
    BackgroundColor3=colors.panel,TextColor3=colors.text,Font=Enum.Font.Gotham,TextSize=12,
    ClearTextOnFocus=false,Text="",PlaceholderText="Whale Shark Egg, Bear Egg",TextXAlignment=Enum.TextXAlignment.Left})
round(eggUI.preferredBox,6)
eggUI.applyButton=control(eggUI.page,"Apply names",0,150,120,32)
eggUI.copyButton=control(eggUI.page,"Copy eggs",130,150,120,32)
eggUI.hint=label(eggUI.page,"Income / Preferred skip unknown data. Stop Collect to change mode.",260,146,300,42,11,colors.muted)
eggUI.hint.TextWrapped=true
eggUI.scroll=create("ScrollingFrame",eggUI.page,{Position=UDim2.fromOffset(0,198),Size=UDim2.fromOffset(568,184),
    BackgroundColor3=colors.panel,BorderSizePixel=0,ScrollBarThickness=5,AutomaticCanvasSize=Enum.AutomaticSize.XY,CanvasSize=UDim2.new()})
eggUI.listLabel=label(eggUI.scroll,"Scan to inspect nearby eggs. Unknown values stay unknown.",8,6,548,24,12,colors.text)
eggUI.listLabel.AutomaticSize=Enum.AutomaticSize.XY;eggUI.listLabel.TextYAlignment=Enum.TextYAlignment.Top
label(automation,"Automation",0,0,400,30,22)
label(automation,"Egg collection • native ground return",0,32,565,22,12,colors.muted)
local rows = {}
for i, name in ipairs({"Auto Hatch", "Collect Eggs", "Upgrade Base / Treadmill", "Speed Training"}) do
    local row = create("Frame",automation,{Position = UDim2.fromOffset(0,60+(i-1)*54), Size = UDim2.fromOffset(568,50), BackgroundColor3 = colors.panel})
    round(row,8)
    label(row,name,14,0,280,50,14,i <= 2 and colors.text or colors.muted)
    label(row,i <= 2 and "TEST" or "",316,0,62,50,11,i <= 2 and colors.cyan or colors.muted)
    if i > 2 then label(row,"SETUP / TEST",316,0,100,50,10,colors.muted) end
    rows[i] = row
end
local scan = control(diagnostics,"Scan / Refresh",0,0,136)
local copy = control(diagnostics,"Copy all",146,0,128)
local save = control(diagnostics,"Save file",284,0,128)
local selectText = control(diagnostics,"Select ALL",422,0,146)
local previous = control(diagnostics,"< Page",0,42,88)
local following = control(diagnostics,"Page >",98,42,88)
local shortCopy = control(diagnostics,"Copy short",196,42,110)
local pageLabel = label(diagnostics,"v1.44 | Waiting for scan",316,42,252,34,11,colors.muted)
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
label(settings,"All automation starts OFF. Upgrades use game currency only.",0,148,568,24,12,colors.muted)
label(settings,"Collect: WALK default, optional Tween; range 250 studs.",0,190,568,24,12,colors.cyan)
label(settings,"Set a delivery point below to enable automatic return.",0,220,568,24,12,colors.muted)
label(placement,"Auto Place paused after kick reports",0,0,560,30,20)
label(placement,"Place eggs manually. Auto Place will not send input.",0,40,560,24,12,colors.muted)
local placeToggle=control(placement,"Auto Place: DISABLED",0,80,170,36)
local bindSlot=control(placement,"Mark empty slot",180,80,180,36)
local clearSlots=control(placement,"Clear slots",370,80,170,36)
local autoMarkButton=control(placement,"Auto mark empty slots",0,130,260,36)
local manualPlaceButton=control(placement,"Manual placement",270,130,270,36)
local recordPlaceButton=control(placement,"Record placement: OFF",0,180,260,36)
local recordPlaceLabel=label(placement,"Records one manual placement; sends no placement input.",270,180,290,36,11,colors.muted)
recordPlaceLabel.TextWrapped=true
local placeLabel=label(placement,"Manual placement stops automation and hides this window. Equip an egg and click an empty slot yourself.",0,230,560,140,13,colors.muted)
placeLabel.TextWrapped=true;placeLabel.TextYAlignment=Enum.TextYAlignment.Top
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
    pageLabel.Text = string.format("v1.44 | Page %d/%d | %d bytes", pageIndex, #pages, #reportText)
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
    local direct = ({firesignal=firesignal,getconnections=getconnections,setclipboard = setclipboard, toclipboard = toclipboard,
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
    pageLabel.Text = "v1.44 | ALL selected | " .. #text .. " bytes"
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
local hatchLabel = label(automation,"Auto approaches ready eggs in your base.",160,354,408,28,11,colors.muted)
hatchLabel.TextWrapped = true
local carryMarker = control(settings,"Mark: I am carrying an egg",0,268,270,34)
local approachButton=control(settings,"Approach: WALK",0,310,270,30)
local setHomeButton = control(settings,"Set delivery point here",0,346,260,30)
local clearHomeButton = control(settings,"Auto home: ON",270,346,260,30)
local upgradeToggle=control(rows[3],"Upgrade: OFF",410,8,146,34)
local trainToggle=control(rows[4],"Train: OFF",410,8,146,34)
local collectButton = control(rows[2], "Collect: OFF", 410,8,146,34)
local collectEgg = {enabled = false, attempts = 0, last = "OFF", approachMode="Walk"}
local eggSelect={mode="Nearest",preferred={},catalog={entries={}},fieldSamples={}}
local upgrades={mode="Off",observed=0,last="OFF",lastAction=-math.huge}
local training={enabled=false,last="OFF",events=0}
local systemRunning=false
local collectRunning = false
local placeRunning=false
local placeState={enabled=false,binding=false,slots={},attempts=0,observed=0,last="OFF"}
local placementRecord={enabled=false,last="OFF",records={}}
local hatchApproach, hatchOwned, hatchResolvePlot, hatchCarryVisible
local hatchWalking
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
    if collectRunning or placeRunning or systemRunning then return end
    if busy then hatch.last = "Paused during scan"; hatchLabel.Text = hatch.last; return end
    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if not root or not humanoid or humanoid.Health<=0 then hatch.last = "Waiting for living character"; return end
    if not hatchResolvePlot or not hatchCarryVisible then hatch.last="Hatch checks not ready";return end
    if hatchCarryVisible() then hatch.last="Holding an egg; Hatch waits";hatchLabel.Text=hatch.last;return end
    local _,ownedPlot=hatchResolvePlot()
    if not ownedPlot then hatch.last="Hatch needs a confirmed owned plot";hatchLabel.Text=hatch.last;return end
    if not manual then
        if not hatchApproach then hatch.last="Hatch navigation not ready";return end
        local ready,plot=hatchApproach(root,humanoid,character)
        ownedPlot=plot
        if not ready or not active or not hatch.enabled then return end
    end
    if player.Character~=character or humanoid.Health<=0 or hatchCarryVisible() then return end
    for prompt in pairs(promptCache) do
        if hatchOwned(prompt,ownedPlot) and eligible(prompt, root, humanoid) then
            local state = attemptState[prompt] or {count = 0, time = -math.huge}
            attemptState[prompt] = state
            if state.count < 3 and os.clock() - state.time >= 4 then
                state.count = state.count + 1
                state.time = os.clock()
                hatch.attempts = hatch.attempts + 1
                hatch.lastAttempt={at=os.time(),path=prompt:GetFullName(),manualTest=manual==true,ownedPlot=ownedPlot:GetFullName(),inputOK=false,resultVerified=false}
                local ok, err = pcall(function()
                    holding = prompt
                    prompt:InputHoldBegin()
                    task.wait(prompt.HoldDuration + 0.1)
                    prompt:InputHoldEnd()
                    holding = nil
                end)
                if holding then pcall(function() holding:InputHoldEnd() end); holding = nil end
                if not active then return end
                hatch.lastAttempt.inputOK=ok
                if not active or player.Character~=character or humanoid.Health<=0 or not manual and not hatch.enabled then
                    hatch.lastAttempt.cancelled=true;hatch.last="Hatch cancelled after input release";hatchLabel.Text=hatch.last;return
                end
                local deadline=os.clock()+2
                while ok and active and (manual or hatch.enabled) and prompt.Parent and prompt.Enabled
                    and prompt.ActionText=="Hatch!" and os.clock()<deadline do task.wait(0.1) end
                hatch.lastAttempt.promptChanged=not prompt.Parent or not prompt.Enabled or prompt.ActionText~="Hatch!"
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
    if placeState.manualPreparing or placementRecord.enabled then status.Text="Stop Record placement before starting other actions";return end
    hatch.enabled = not hatch.enabled
    attemptState = setmetatable({}, {__mode = "k"})
    hatchButton.Text = hatch.enabled and "Auto Hatch: ON" or "Auto Hatch: OFF"
    hatch.last = hatch.enabled and "Waiting for nearby Hatch!" or "OFF"
    hatchLabel.Text = hatch.last
    if not hatch.enabled and hatchWalking then
        local character=player.Character;local root=character and character:FindFirstChild("HumanoidRootPart")
        if root then pcall(function() hatchWalking:MoveTo(root.Position) end) end
        hatchWalking=nil
    end
    if not hatch.enabled and holding then pcall(function() holding:InputHoldEnd() end); holding = nil end
end)
local hatchRunning = false
local function dispatchHatch(manual)
    if placeState.manualPreparing or placementRecord.enabled then status.Text="Stop Record placement before starting other actions";return end
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
    local snapshot = {enabled = hatch.enabled, attempts = hatch.attempts, last = hatch.last, lastAttempt=hatch.lastAttempt,
        scanning = busy, inputInProgress = hatchRunning, cacheCount = 0,
        result = "Input attempts only; hatch success is not verified"}
    local _,ownedPlot
    if hatchResolvePlot then _,ownedPlot=hatchResolvePlot() end
    snapshot.ownedPlotConfirmed=ownedPlot~=nil
    snapshot.carryBlocked=hatchCarryVisible and hatchCarryVisible() or false
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
                elseif snapshot.carryBlocked then reason = "Holding an egg; Hatch waits"
                elseif not ownedPlot then reason = "Owned plot not confirmed"
                elseif not hatchOwned(prompt,ownedPlot) then reason = "Prompt outside owned base"
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
local eggLogic={}
local recordingContext
local collectTween
local walkReturn
local walkingHumanoid
local deliveryPoint
local autoHome={enabled=true,ready=false,reason="Waiting for plot ownership",lastCheck=-math.huge}
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
local lastRedeem
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
function eggLogic.resetField()
    eggLogic.field={records={},order={},count=0,lastEvent=nil,lastAt=nil,missingUid=0,evicted=0}
end
eggLogic.resetField()
function eggLogic.removeField(uid)
    local field=eggLogic.field
    if not field.records[uid] then return false end
    field.records[uid]=nil;field.count=field.count-1
    for i=#field.order,1,-1 do if field.order[i]==uid then table.remove(field.order,i) end end
    return true
end
function eggLogic.fieldPoint(value)
    local ok,point=pcall(function()
        if typeof(value)=="CFrame" then value=value.Position end
        if typeof(value)~="Vector3" and type(value)~="table" then return nil end
        local x,y,z=value.X or value.x,value.Y or value.y,value.Z or value.z
        for _,n in ipairs({x,y,z}) do if type(n)~="number" or n~=n or math.abs(n)==math.huge then return nil end end
        if x==nil or y==nil or z==nil then return nil end
        return {x=x,y=y,z=z}
    end)
    return ok and point or nil
end
function eggLogic.fieldRecord(payload,source,mapKey)
    if type(payload)~="table" then return nil end
    local record={fields={},positions={},keys={},source=source,clock=os.clock(),at=os.time()}
    local uid
    for _,key in ipairs({"Uid","UID","EggUid","EggUID","FieldEggUid"}) do
        local value=payload[key]
        if type(value)=="string" and value~="" and #value<=120 then
            if uid and uid~=value then record.identityConflict=true end
            uid=value;record.fields[key]=value
        end
    end
    if not uid and type(mapKey)=="string" and #mapKey<=120
        and (mapKey:match("^FirstAreaEgg_") or #mapKey==32 and mapKey:match("^%x+$")) then uid=mapKey;record.uidFromMapKey=true end
    record.uid=not record.identityConflict and uid or nil
    for _,key in ipairs({"DisplayName","EggName","AssetCategory","Rarity","RarityName","AreaId","BaseMutation","Mutations",
        "IncomePerSecond","CashPerSecond","MoneyPerSecond","CoinsPerSecond","Income","Value","BaseValue","Price","ValuePerSecond",
        "OwnerUserId","IsCarried","IsCarrying","CarrierUserId","NestScale","Stats"}) do
        if payload[key]~=nil then record.fields[key]=eventValue(payload[key],0,{}) end
    end
    for _,key in ipairs({"Position","BottomCFrame","BoundsCFrame","CFrame","PivotCFrame"}) do
        if payload[key]~=nil then
            local point=eggLogic.fieldPoint(payload[key])
            record.fields[key]=point and {kind=typeof(payload[key]),position=point} or eventValue(payload[key],0,{})
            if point then record.positions[key]=point end
        end
    end
    if type(payload.Stats)=="table" then
        record.statsRates={}
        for _,key in ipairs({"IncomePerSecond","CashPerSecond","MoneyPerSecond","CoinsPerSecond"}) do
            if payload.Stats[key]~=nil then record.statsRates[key]=eventValue(payload.Stats[key],0,{}) end
        end
    end
    for key in pairs(payload) do
        if #record.keys>=64 then record.keysTruncated=true;break end
        if type(key)=="string" then record.keys[#record.keys+1]=key:sub(1,80) end
    end
    table.sort(record.keys)
    return record
end
function eggLogic.observeField(name,payload)
    local field=eggLogic.field
    if name=="RE/EggWorld/FieldEggGone" then
        if type(payload)=="string" then eggLogic.removeField(payload) end
        return
    end
    if name~="RE/EggWorld/FieldEggShifted" and name~="RE/EggWorld/FieldEggBatchShifted" then return end
    if type(payload)~="table" then return end
    field.lastEvent=name;field.lastAt=os.time()
    local result={records={},processed=0,removed=0}
    local function storeRecord(value,key)
        local record=eggLogic.fieldRecord(value,name,key)
        if not record then return end
        result.processed=result.processed+1
        if #result.records<4 then result.records[#result.records+1]=record end
        if not record.uid then field.missingUid=field.missingUid+1;return end
        if not field.records[record.uid] then
            field.order[#field.order+1]=record.uid;field.count=field.count+1
        end
        field.records[record.uid]=record
        while #field.order>256 do
            local oldest=table.remove(field.order,1)
            if field.records[oldest] then field.records[oldest]=nil;field.count=field.count-1;field.evicted=field.evicted+1 end
        end
    end
    if name=="RE/EggWorld/FieldEggShifted" then storeRecord(payload)
    else
        if type(payload.RemovedUids)=="table" then
            local count=0
            for _,uid in pairs(payload.RemovedUids) do
                count=count+1;if count>128 then result.removalsTruncated=true;break end
                if type(uid)=="string" and eggLogic.removeField(uid) then result.removed=result.removed+1 end
            end
        end
        local updates=payload.UpdatedRecords
        -- Records is retained only as a bounded diagnostic compatibility shape.
        if type(updates)~="table" then updates=payload.Records end
        if type(updates)=="table" then
            local count=0
            for key,value in pairs(updates) do
                count=count+1;if count>128 then result.updatesTruncated=true;break end
                storeRecord(value,key)
            end
        end
    end
    result.recordsTruncated=result.processed>#result.records
    return result
end
function eggLogic.resolveField(subject,metadata)
    if subject.Name~="CarryAreaEgg" or metadata.conflicts.uid then return nil end
    local function usable(record)
        return record and os.clock()-record.clock<=120 and record.fields.IsCarried~=true and record.fields.IsCarrying~=true
            and not (type(record.fields.CarrierUserId)=="number" and record.fields.CarrierUserId>0)
    end
    if metadata.uid then
        local record=eggLogic.field.records[metadata.uid]
        if usable(record) then return record,{method="explicit_uid",uid=record.uid,ageSeconds=os.clock()-record.clock} end
        return nil
    end
    local ok,position=pcall(promptPosition,subject)
    if not ok or not position then return nil end
    local candidates={}
    for _,record in pairs(eggLogic.field.records) do
        if usable(record) then
            local best,key
            for name,point in pairs(record.positions) do
                local dx,dz=position.X-point.x,position.Z-point.z
                local horizontal=math.sqrt(dx*dx+dz*dz)
                if horizontal<=1.5 and math.abs(position.Y-point.y)<=8 and (not best or horizontal<best) then best=horizontal;key=name end
            end
            if best then candidates[#candidates+1]={record=record,horizontal=best,key=key} end
        end
    end
    if #candidates~=1 then return nil,{method="unmatched",candidateCount=#candidates} end
    local match=candidates[1]
    local point=match.record.positions[match.key]
    for prompt in pairs(promptCache) do
        if prompt~=subject and prompt.Name=="CarryAreaEgg" and prompt.Parent then
            local good,p=pcall(promptPosition,prompt)
            if good and p then
                local dx,dz=p.X-point.x,p.Z-point.z
                if math.sqrt(dx*dx+dz*dz)<=1.5 and math.abs(p.Y-point.y)<=8 then
                    return nil,{method="ambiguous_prompts",uid=match.record.uid}
                end
            end
        end
    end
    return match.record,{method="unique_position",uid=match.record.uid,horizontalDistance=match.horizontal,
        positionSource=match.key,ageSeconds=os.clock()-match.record.clock}
end
local function recordGameEvent(name, ...)
    if name=="RE/Treadmill/SpeedGained" then
        training.events=training.events+1;training.lastEventAt=os.time()
    end
    if name=="RE/EggWorld/FieldEggRedeemVerdict" then
        local payload=(...)
        if type(payload)=="table" and type(payload.DisplayName)=="string" then
            lastRedeem={clock=os.clock(),displayName=payload.DisplayName}
        end
    end
    if name=="RE/EggWorld/FieldEggCarry" then updateServerCarry((...)) end
    local fieldObservation=eggLogic.observeField(name,(...))
    local args={}
    for i=1,math.min(select("#",...),6) do args[i]=eventValue(select(i,...),0,{}) end
    if name=="RE/EggWorld/FieldEggShifted" or name=="RE/EggWorld/FieldEggBatchShifted" then
        local sample={at=os.time(),name=name,args=args,nested={},field=fieldObservation}
        for i=1,math.min(select("#",...),2) do
            local payload=select(i,...)
            if type(payload)=="table" then
                local inspected=0
                for key,value in pairs(payload) do
                    inspected=inspected+1
                    if inspected>16 or #sample.nested>=2 then sample.truncated=true;break end
                    if type(value)=="table" and #sample.nested<2 then
                        sample.nested[#sample.nested+1]={argument=i,key=tostring(key):sub(1,80),value=eventValue(value,0,{})}
                    end
                end
            end
        end
        eggSelect.fieldSamples[#eggSelect.fieldSamples+1]=sample
        if #eggSelect.fieldSamples>3 then table.remove(eggSelect.fieldSamples,1) end
    end
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
local function redeemedEggs()
    if fieldCarryActive() or not lastRedeem or not collectEgg.tripStartedClock or not collectEgg.tripInventory
        or lastRedeem.clock<collectEgg.tripStartedClock or os.clock()-lastRedeem.clock>5 then return nil end
    local added=newInventoryEggs(collectEgg.tripInventory,eggInventory())
    for _,egg in ipairs(added) do
        if egg.name==lastRedeem.displayName then return added end
    end
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
function eggLogic.metadata(subject)
    local data={sources={},raw={},conflicts={}}
    local function rawValue(value)
        if type(value)=="string" then return value:sub(1,120) end
        if type(value)=="number" and (value~=value or value==math.huge or value==-math.huge) then return tostring(value) end
        return value
    end
    local groups={UID="uid",Uid="uid",EggUID="uid",EggUid="uid",FieldEggUid="uid",
        EggName="name",DisplayName="name",Rarity="rarity",RarityName="rarity",
        IncomePerSecond="incomePerSecond",CashPerSecond="incomePerSecond",MoneyPerSecond="incomePerSecond",CoinsPerSecond="incomePerSecond"}
    local function observe(group,value,source)
        if group=="incomePerSecond" then
            value=tonumber(value)
            if not value or value~=value or value<0 or value==math.huge then return end
        else
            if type(value)~="string" or #value>120 then return end
            value=value:match("^%s*(.-)%s*$")
            if value=="" or group=="name" and value=="Egg" then return end
        end
        if data[group]~=nil and data[group]~=value then data.conflicts[group]=true end
        data[group]=value;data.sources[group]=source
    end
    local queue,seen={},{}
    local node=subject
    for _=1,4 do
        if not node or node==workspace or node==player.Character then break end
        local ok,stop=pcall(function() return node:IsA("Folder") end)
        if ok and stop then break end
        queue[#queue+1]=node
        local isTool,tool=pcall(function() return node:IsA("Tool") end)
        if isTool and tool then
            observe("name",node.Name,"Inventory Tool.Name");break
        end
        node=node.Parent
    end
    for i=1,math.min(#queue,2) do
        for _,key in ipairs({"Target","Egg","EggModel"}) do
            local ok,linked=pcall(function()
                local ref=queue[i]:FindFirstChild(key)
                return ref and ref:IsA("ObjectValue") and ref.Value or nil
            end)
            if ok and linked and #queue<8 then
                local valid=pcall(function() assert(linked:IsDescendantOf(workspace)) end)
                if valid then queue[#queue+1]=linked end
            end
        end
    end
    for _,obj in ipairs(queue) do
        if not seen[obj] then
            seen[obj]=true
            local ok,path=pcall(function() return obj:GetFullName() end)
            path=ok and path or "Unlabelled source"
            local raw={path=path,values={}}
            for key,group in pairs(groups) do
                local found,value=pcall(function() return obj:GetAttribute(key) end)
                if found and (type(value)=="string" or type(value)=="number") then
                    raw.values[key]=rawValue(value)
                    observe(group,value,path.." attribute "..key)
                end
                local read,v=pcall(function()
                    local child=obj:FindFirstChild(key)
                    if child and (child:IsA("StringValue") or child:IsA("NumberValue") or child:IsA("IntValue")) then return child.Value end
                    if child and child:IsA("TextLabel") then return child.Text end
                end)
                if read and (type(v)=="string" or type(v)=="number") then
                    raw.values[key..".Value/Text"]=rawValue(v)
                    observe(group,v,path.." child "..key)
                end
            end
            local got,attrs=pcall(function() return obj:GetAttributes() end)
            if got then
                local count=0
                for key,value in pairs(attrs) do
                    local lower=key:lower()
                    if count<12 and (lower:find("egg",1,true) or lower:find("rarity",1,true) or lower:find("income",1,true)
                        or lower:find("value",1,true) or lower:find("uid",1,true) or lower:find("money",1,true)
                        or lower:find("cash",1,true) or lower:find("coin",1,true) or lower:find("mutat",1,true)
                        or lower:find("price",1,true) or lower:find("chance",1,true) or lower:find("tier",1,true)) then
                        if type(value)=="string" or type(value)=="number" or type(value)=="boolean" then
                            raw.values[key]=rawValue(value);count=count+1
                        end
                    end
                end
            end
            if next(raw.values) and #data.raw<6 then data.raw[#data.raw+1]=raw end
        end
    end
    local record,binding=eggLogic.resolveField(subject,data)
    data.fieldBinding=binding
    if record then
        local source=record.source.." field "..record.uid
        observe("uid",record.uid,source)
        for key,group in pairs(groups) do
            if record.fields[key]~=nil then observe(group,record.fields[key],source.."."..key) end
            if record.statsRates and record.statsRates[key]~=nil then observe(group,record.statsRates[key],source..".Stats."..key) end
        end
        data.assetCategory=record.fields.AssetCategory;data.areaId=record.fields.AreaId
        if #data.raw<6 then data.raw[#data.raw+1]={path=source,values=record.fields,keys=record.keys} end
    end
    for group in pairs(data.conflicts) do data[group]=nil;data.sources[group]=nil end
    return data
end
function eggLogic.preference(name)
    if not name then return nil end
    for i,wanted in ipairs(eggSelect.preferred) do if name:lower()==wanted:lower() then return i end end
end
function eggLogic.less(a,b)
    if a.accepted~=b.accepted then return a.accepted end
    if eggSelect.mode=="Income" and a.meta.incomePerSecond~=b.meta.incomePerSecond then
        return (a.meta.incomePerSecond or -1)>(b.meta.incomePerSecond or -1)
    elseif eggSelect.mode=="Preferred" and a.priority~=b.priority then
        return (a.priority or math.huge)<(b.priority or math.huge)
    end
    if a.distance~=b.distance then return a.distance<b.distance end
    return (a.meta.uid or a.meta.name or "")<(b.meta.uid or b.meta.name or "")
end
function eggLogic.accepts(meta)
    if eggSelect.mode~="Nearest" and meta.conflicts.uid then return false end
    if eggSelect.mode=="Income" then return meta.incomePerSecond~=nil end
    if eggSelect.mode=="Preferred" then return eggLogic.preference(meta.name)~=nil end
    return true
end
function eggLogic.choices(root,humanoid,readyOnly)
    local choices={}
    for prompt in pairs(promptCache) do
        local distance,position
        if readyOnly then
            distance=collectCandidate(prompt,root,humanoid);position=distance and promptPosition(prompt)
            local state=collectAttempts[prompt]
            if state and (state.count>=3 or os.clock()-state.time<4) then distance=nil end
        else distance,position=approachCandidate(prompt,root,humanoid) end
        if distance then
            local meta=eggLogic.metadata(prompt)
            choices[#choices+1]={prompt=prompt,distance=distance,position=position,meta=meta,
                priority=eggLogic.preference(meta.name),accepted=eggLogic.accepts(meta)}
        end
    end
    table.sort(choices,eggLogic.less)
    return choices
end
function eggLogic.refresh()
    local character=player.Character
    local root=character and character:FindFirstChild("HumanoidRootPart")
    local humanoid=character and character:FindFirstChildOfClass("Humanoid")
    local choices=eggLogic.choices(root,humanoid,false)
    local catalog={at=os.time(),mode=eggSelect.mode,entries={},inventory={},total=#choices,knownIncome=0,fieldLinked=0,accepted=0,
        fieldData={stored=eggLogic.field.count,lastEvent=eggLogic.field.lastEvent,lastAt=eggLogic.field.lastAt,
            missingUid=eggLogic.field.missingUid,evicted=eggLogic.field.evicted}}
    catalog.fieldData.fresh=0
    for _,record in pairs(eggLogic.field.records) do
        if os.clock()-record.clock<=120 then catalog.fieldData.fresh=catalog.fieldData.fresh+1 end
    end
    for i,choice in ipairs(choices) do
        if choice.meta.incomePerSecond~=nil then catalog.knownIncome=catalog.knownIncome+1 end
        if choice.meta.fieldBinding and choice.meta.fieldBinding.uid and choice.meta.fieldBinding.method~="ambiguous_prompts" then catalog.fieldLinked=catalog.fieldLinked+1 end
        if choice.accepted then catalog.accepted=catalog.accepted+1 end
        if i<=12 then catalog.entries[i]={path=choice.prompt:GetFullName(),distance=choice.distance,
            position={x=choice.position.X,y=choice.position.Y,z=choice.position.Z},
            enabled=choice.prompt.Enabled,eligibleForMode=choice.accepted,priority=choice.priority,metadata=choice.meta} end
    end
    catalog.truncated=#choices>12
    local inventory=eggInventory()
    local items={};for _,item in pairs(inventory.items) do items[#items+1]=item end
    table.sort(items,function(a,b) return a.uid<b.uid end)
    for i=1,math.min(#items,8) do catalog.inventory[i]=items[i] end
    local backpack=player:FindFirstChildOfClass("Backpack")
    for _,container in pairs({character=character,backpack=backpack}) do
        for i,tool in ipairs(container:GetChildren()) do
            if i>1000 then break end
            if tool:IsA("Tool") and tool:GetAttribute("ItemType")=="AssetEgg" then
                local uid=tool:GetAttribute("UID")
                for _,item in ipairs(catalog.inventory) do if item.uid==uid then item.metadata=eggLogic.metadata(tool) end end
            end
        end
    end
    catalog.inventoryComplete=inventory.complete and #items<=8
    eggSelect.catalog=catalog
    return choices
end
function eggLogic.export()
    eggLogic.refresh()
    return {version="1.44",kind="egg_data",placeId=game.PlaceId,
        eggSelection={mode=eggSelect.mode,preferred=eggSelect.preferred,catalog=eggSelect.catalog,
            selected=collectEgg.selectedEgg,fieldSamples=eggSelect.fieldSamples}}
end
function eggLogic.apply(text)
    if #text>1200 then return false,"Preferred list is too long" end
    local names,seen={},{}
    for entry in text:gmatch("[^,;\n]+") do
        local name=entry:match("^%s*(.-)%s*$")
        if #name>120 then return false,"An egg name is too long" end
        if name~="" and not seen[name:lower()] then
            if #names>=10 then return false,"Maximum 10 preferred names" end
            names[#names+1]=name;seen[name:lower()]=true
        end
    end
    eggSelect.preferred=names
    return true,"Preferred order saved for this session"
end
local function approachEgg(root, humanoid,preferred)
    if not root or not humanoid then return false end
    local choices = {}
    for _,choice in ipairs(eggLogic.choices(root,humanoid,false)) do
        if choice.accepted and (not preferred or preferred==choice.prompt) then choices[#choices+1]=choice end
    end
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
                if collectEgg.approachMode~="Tween" then
                    local record={at=os.time(),path=prompt:GetFullName(),mode="Walk",distance=choice.distance,status="Walking to egg"}
                    collectEgg.lastMovement=record
                    local reached,reason=walkReturn(root,humanoid,character,root.Position+offset,false,prompt)
                    record.status,record.stopReason=reason,reason
                    record.endDistance=(root.Position-position).Magnitude
                    collectEgg.last=reason
                    return reached and inCollectRange(prompt,root) and prompt.Enabled
                end
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
                    collectEgg.last = "Moving to selected egg ("..eggSelect.mode..")"
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
        or #choices==0 and eggSelect.mode~="Nearest" and "No egg has readable data matching the selected mode; inspect Eggs / Copy short"
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
local ownerKeys={"OwnerUserId","OwnerId","Owner","UserId","PlayerUserId","Player","Username","OwnerName"}
local function signEvidence(plot)
    local result={texts={},attributes={},usernameMatch=false,truncated=false}
    local sign=plot:FindFirstChild("PlotSign")
    if not sign then return result end
    local queue,head={sign},1
    local username=string.lower(player.Name):gsub("([^%w])","%%%1")
    while head<=#queue and head<=200 do
        local obj=queue[head];head=head+1
        for _,key in ipairs(ownerKeys) do
            local value=obj:GetAttribute(key)
            if type(value)=="string" or type(value)=="number" then
                result.attributes[key]=value
                if value==player.UserId or value==tostring(player.UserId) or value==player.Name then result.usernameMatch=true end
            end
        end
        if obj:IsA("TextLabel") or obj:IsA("TextButton") then
            local text=obj.Text:gsub("<[^>]*>","")
            if #result.texts<12 then result.texts[#result.texts+1]=text:sub(1,180) end
            if (" "..string.lower(text).." "):find("[^%w_]"..username.."[^%w_]") then result.usernameMatch=true end
        end
        for _,child in ipairs(obj:GetChildren()) do if #queue<400 then queue[#queue+1]=child else result.truncated=true end end
    end
    if head<=#queue then result.truncated=true end
    return result
end
local function ownerMatch(plot)
    local function matches(value)
        return value==player or type(value)=="number" and value==player.UserId
            or type(value)=="string" and (value==tostring(player.UserId) or value==player.Name)
    end
    local nodes={plot}
    local explicitOwner=false
    for _,child in ipairs(plot:GetChildren()) do
        if child.Name=="Owner" or child.Name=="OwnerUserId" or child.Name=="OwnerId" then
            if child:IsA("ObjectValue") or child:IsA("StringValue") or child:IsA("IntValue") or child:IsA("NumberValue") then
                if matches(child.Value) then return true,"value:"..child.Name end
            end
        end
        if child.Name=="Info" or child.Name=="Config" or child.Name=="Settings" then nodes[#nodes+1]=child end
    end
    for _,node in ipairs(nodes) do
        for _,key in ipairs(ownerKeys) do
            local value=node:GetAttribute(key)
            if matches(value) then return true,"attribute:"..key end
            if value~=nil and value~="" and value~=0 and value~=false then explicitOwner=true end
        end
    end
    if not explicitOwner then
        local sign=signEvidence(plot)
        if sign.usernameMatch and not sign.truncated then return true,"PlotSign exact username" end
    end
    return false
end
local function resolveAutoHome()
    local report={ready=false,plots={},reason="Workspace.Plots unavailable"}
    local plots=workspace:FindFirstChild("Plots")
    if not plots then return nil,nil,nil,report end
    local owned={}
    for i,plot in ipairs(plots:GetChildren()) do
        if i>16 then report.truncated=true;break end
        local match,evidence=ownerMatch(plot)
        local info={path=plot:GetFullName(),ownerMatch=match,children={},ownership={},sign=signEvidence(plot)}
        for _,key in ipairs(ownerKeys) do
            local value=plot:GetAttribute(key)
            if type(value)=="string" or type(value)=="number" or type(value)=="boolean" then info.ownership[key]=value end
        end
        for j,child in ipairs(plot:GetChildren()) do
            if j>24 then break end
            info.children[#info.children+1]={name=child.Name,class=child.ClassName}
        end
        report.plots[#report.plots+1]=info
        if match then owned[#owned+1]={plot=plot,evidence=evidence} end
    end
    if #owned~=1 then
        report.reason=#owned==0 and "No plot with confirmed local ownership" or "More than one plot matches owner; manual setup required"
        return nil,nil,nil,report
    end
    local plot=owned[1].plot
    report.plot=plot:GetFullName();report.ownerEvidence=owned[1].evidence
    local deliveryNames={deliverypoint=true,deliveryzone=true,eggdroppoff=true,eggdropoff=true,
        eggdeposit=true,eggdepositzone=true,eggredeemzone=true,redeemzone=true}
    local spawnNames={spawn=true,spawnpoint=true,playerspawn=true,spawnlocation=true}
    local groups={[1]={},[2]={}}
    local queue,head={plot},1
    while head<=#queue and head<=2000 do
        local obj=queue[head];head=head+1
        if obj:IsA("BasePart") or obj:IsA("Attachment") then
            local name=string.lower(obj.Name):gsub("[^%w]","")
            local rank=deliveryNames[name] and 1 or (spawnNames[name] or obj:IsA("SpawnLocation")) and 2
            if rank then groups[rank][#groups[rank]+1]=obj end
        end
        for _,child in ipairs(obj:GetChildren()) do
            if #queue<4000 then queue[#queue+1]=child else report.truncated=true end
        end
    end
    if head<=#queue then report.truncated=true end
    local candidates=#groups[1]>0 and groups[1] or groups[2]
    if report.truncated or #candidates~=1 then
        report.reason=report.truncated and "Plot scan incomplete; manual setup required"
            or #candidates==0 and "Owned plot found but no unique delivery/spawn point"
            or "Several delivery/spawn points; manual setup required"
        return nil,nil,nil,report
    end
    local target=candidates[1]
    -- A spawn is an explicit fallback, not a claim that its delivery trigger was verified.
    local point=target:IsA("Attachment") and target.WorldPosition or target.Position
    report.ready=true;report.reason=#groups[1]>0 and "Owned plot delivery candidate" or "Owned plot spawn fallback; delivery unverified"
    report.point=target:GetFullName();report.kind=#groups[1]>0 and "delivery_candidate" or "spawn_fallback"
    return point,plot,target,report
end
local function refreshAutoHome(force)
    if not autoHome.enabled then return end
    if not force and os.clock()-autoHome.lastCheck<5 then return end
    autoHome.lastCheck=os.clock()
    local point,plot,target,report=resolveAutoHome()
    autoHome.report=report;autoHome.reason=report.reason;autoHome.ready=point~=nil
    autoHome.plot,autoHome.target=plot,target
    deliveryPoint=point
    if clearHomeButton then clearHomeButton.Text=point and "Auto home: FOUND" or "Auto home: SEARCHING" end
end
local function setDeliveryPoint(position)
    if collectRunning then return false, "Stop Collect before changing the delivery point" end
    deliveryPoint = position
    autoHome.enabled=false;autoHome.ready=false;autoHome.reason="Manual delivery point"
    if clearHomeButton then clearHomeButton.Text="Auto home: OFF" end
    return true
end
local lastWalkingRecovery
local function recoverWalking(tracker,root,humanoid,goal)
    local now=os.clock()
    if (root.Position-goal).Magnitude<=3 then return false end
    if (root.Position-tracker.origin).Magnitude>=0.75 then
        tracker.origin=root.Position;tracker.checked=now
        return false
    end
    if now-tracker.checked<1.1 or now-tracker.lastJump<2 then return false end
    if humanoid.Health<=0 or humanoid.FloorMaterial==Enum.Material.Air then return false end
    if tracker.attempts>=2 then return true end
    tracker.attempts=tracker.attempts+1
    tracker.lastJump=now;tracker.checked=now;tracker.origin=root.Position
    if humanoid.Sit then humanoid.Sit=false end
    humanoid.Jump=true
    humanoid:MoveTo(goal)
    lastWalkingRecovery={at=os.time(),attempt=tracker.attempts,reason="Walking stalled; jump to leave treadmill/obstacle",
        position={x=root.Position.X,y=root.Position.Y,z=root.Position.Z}}
    recordGameEvent("walking.unstick.jump",tracker.attempts)
    return false
end
walkReturn=function(root,humanoid,character,destination,requireCarry,target,allowEquipped)
    local function movementAllowed()
        if allowEquipped=="training" then return training.enabled and not collectEgg.enabled and not hatchRunning end
        if allowEquipped=="upgrade" then return upgrades.mode~="Off" and not collectEgg.enabled and not hatchRunning end
        return allowEquipped and placeState.enabled or not allowEquipped and collectEgg.enabled
    end
    if requireCarry==nil then requireCarry=true end
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
    local function carryEnded()
        cancelCollectTween("Checking redemption")
        local deadline=os.clock()+0.35
        repeat
            local added=redeemedEggs()
            if added then
                collectEgg.earlyDelivery=added
                nav.status="Redeemed before spawnpoint"
                return true,nav.status
            end
            if not active or not movementAllowed() or player.Character~=character then return stop("Return cancelled") end
            task.wait(0.05)
        until os.clock()>=deadline
        return stop("Game no longer reports field egg carrying")
    end
    for i,point in ipairs(route) do
        local goal=i==#route and destination or point.Position
        local started=os.clock()
        local deadline=(root.Position-goal).Magnitude/math.max(humanoid.WalkSpeed,1)+5
        nav.currentWaypoint=i
        if not active or not movementAllowed() then return stop("Return cancelled") end
        if player.Character~=character or not root.Parent or humanoid.Health<=0 then return stop("Character changed during return") end
        if requireCarry and not fieldCarryActive() and (root.Position-destination).Magnitude>4 then return carryEnded() end
        if not requireCarry and (fieldCarryActive() or manualCarry or not allowEquipped and carryVisible()) then return stop("Holding state detected during approach") end
        if target and not target.Parent then return stop("Approach target removed") end
        walkingHumanoid=humanoid
        collectEgg.moving=true
        humanoid:MoveTo(goal)
        local refreshed=os.clock()
        local recovery={origin=root.Position,checked=os.clock(),lastJump=-math.huge,attempts=0}
        -- Waypoints lie on the floor; compare horizontal arrival without lifting the root.
        local function reached()
            local offset=root.Position-goal
            local radius=i==#route and 1.5 or 2.5
            return math.sqrt(offset.X*offset.X+offset.Z*offset.Z)<=radius and math.abs(offset.Y)<=6
        end
        -- MoveTo handles physics and natural height. Never tween CFrame or force a jump while carrying.
        while not reached() do
            if not active or not movementAllowed() then return stop("Return cancelled") end
            if player.Character~=character or not root.Parent or humanoid.Health<=0 then return stop("Character changed during return") end
            if busy then return stop("Return interrupted by scan") end
            if requireCarry and not fieldCarryActive() and (root.Position-destination).Magnitude>4 then return carryEnded() end
        if not requireCarry and (fieldCarryActive() or manualCarry or not allowEquipped and carryVisible()) then return stop("Holding state detected during approach") end
        if target and not target.Parent then return stop("Approach target removed") end
            if recoverWalking(recovery,root,humanoid,goal) then return stop("Walking stuck after two jump attempts") end
            if os.clock()-started>deadline then return stop("Ground return stalled at waypoint "..i) end
            if os.clock()-refreshed>=1 then humanoid:MoveTo(goal);refreshed=os.clock() end
            nav.status=requireCarry and "Walking home" or allowEquipped=="training" and "Walking to treadmill" or allowEquipped=="upgrade" and "Walking to upgrade sign" or "Walking to egg";collectLabel.Text=string.format("%s %d/%d",nav.status,i,#route)
            task.wait(0.1)
        end
        nav.completed=i
    end
    if not active or not movementAllowed() then return stop("Return cancelled") end
    cancelCollectTween("At delivery point")
    nav.status="Ground return reached delivery point"
    return true,nav.status
end
local function returnHome(root, humanoid, character)
    if autoHome.enabled then refreshAutoHome(true) end
    if not deliveryPoint then pauseCollect("Holding field egg: set your delivery point in Settings; "..autoHome.reason); return end
    if not root or not humanoid or humanoid.Health <= 0 then pauseCollect("Character unavailable during return"); return end
    collectEgg.phase = "RETURNING"
    collectLabel.Text = "Returning field egg to configured delivery point"
    local delta = deliveryPoint-root.Position
    local record = {at = os.time(), status = "Returning", startDistance = delta.Magnitude,
        destination = {x=deliveryPoint.X,y=deliveryPoint.Y,z=deliveryPoint.Z}}
    collectEgg.lastReturn = record
    collectEgg.earlyDelivery=nil
    record.startedClock=os.clock()
    if serverCarry and serverCarry.character==character and serverCarry.isCarrying then
        record.confirmationToReturnMs=math.max(0,(record.startedClock-serverCarry.clock)*1000)
    end
    if delta.Magnitude > 600 then pauseCollect("Delivery point beyond 600 studs"); record.status=collectEgg.last; return end
    if delta.Magnitude > 1.5 then
        local reached,reason=walkReturn(root,humanoid,character,deliveryPoint)
        record.status,record.endDistance=reason,(root.Position-deliveryPoint).Magnitude
        if reached and collectEgg.earlyDelivery then
            record.inventoryAdded=collectEgg.earlyDelivery
            record.status="Delivery observed: redeem event and new egg UID before spawnpoint"
            collectEgg.deliveriesObserved=(collectEgg.deliveriesObserved or 0)+1
            local acquired={}
            for _,egg in ipairs(collectEgg.earlyDelivery) do acquired[egg.uid]=true end
            for _,tool in ipairs(character:GetChildren()) do
                if tool:IsA("Tool") and acquired[tool:GetAttribute("UID")] then
                    local ok,err=pcall(function() humanoid:UnequipTools() end)
                    if not ok then record.unequipError=tostring(err):sub(1,100) end
                    break
                end
            end
            collectEgg.tripInventory=nil;collectEgg.earlyDelivery=nil
            collectEgg.phase="SEEKING";collectEgg.last=record.status
            recordGameEvent("return.redeemed",record.status)
            return
        end
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
-- HATCH_NAV_BEGIN
hatchResolvePlot=resolveAutoHome
hatchCarryVisible=carryVisible
hatchOwned=function(prompt,ownPlot)
    if not prompt.Parent or not prompt:IsDescendantOf(workspace) then return false end
    if prompt:IsDescendantOf(ownPlot) then return true end
    local position=promptPosition(prompt)
    local plots=workspace:FindFirstChild("Plots")
    if not position or not plots then return false end
    local nearest,first,second=nil,math.huge,math.huge
    for _,plot in ipairs(plots:GetChildren()) do
        local center=plot:FindFirstChild("CenterPoint") or plot:FindFirstChild("SpawnPoint")
        if center and center:IsA("BasePart") then
            local distance=(position-center.Position).Magnitude
            if distance<first then second=first;first=distance;nearest=plot
            elseif distance<second then second=distance end
        end
    end
    return nearest==ownPlot and first<=35 and second-first>=5
end
hatchApproach=function(root,humanoid,character)
    local _,plot=resolveAutoHome()
    if not plot then hatch.last="Auto Hatch needs a confirmed owned plot";return false,nil end
    if carryVisible() then hatch.last="Holding an egg; Hatch movement waits";return false,plot end
    local target,distance
    for prompt in pairs(promptCache) do
        if prompt.ActionText=="Hatch!" and prompt.Enabled and prompt.HoldDuration>=0 and prompt.HoldDuration<=5
            and hatchOwned(prompt,plot) then
            local state=attemptState[prompt]
            local pos=promptPosition(prompt)
            local d=pos and (root.Position-pos).Magnitude
            if d and d<=150 and (not state or state.count<3 and os.clock()-state.time>=4)
                and (not distance or d<distance) then target,distance=prompt,d end
        end
    end
    if not target then hatch.last="Waiting for ready Hatch! in your base";return false,plot end
    if eligible(target,root,humanoid) then return true,plot end
    local pos=promptPosition(target)
    local offset=Vector3.new(pos.X-root.Position.X,0,pos.Z-root.Position.Z)
    if offset.Magnitude<0.1 then return false,plot end
    local goal=root.Position+offset.Unit*math.max(0,offset.Magnitude-3)
    local params=RaycastParams.new()
    params.FilterType=Enum.RaycastFilterType.Exclude;params.FilterDescendantsInstances={character};params.RespectCanCollide=true
    local route
    if workspace:Raycast(root.Position,goal-root.Position,params) then
        local ok,result=pcall(function()
            local path=PathfindingService:CreatePath({AgentRadius=2,AgentHeight=5,AgentCanJump=false,WaypointSpacing=5})
            path:ComputeAsync(root.Position,goal)
            return path.Status==Enum.PathStatus.Success and path:GetWaypoints() or nil
        end)
        if not ok or not result or #result>60 then hatch.last="No ground path to ready egg";return false,plot end
        route=result
    else route={{Position=goal}} end
    local function stop(reason)
        pcall(function() humanoid:MoveTo(root.Position) end)
        hatchWalking=nil;hatch.last=reason;hatchLabel.Text=reason
        return false,plot
    end
    local started=os.clock()
    for i,point in ipairs(route) do
        if not active or not hatch.enabled or busy or collectRunning or carryVisible() then return stop("Hatch movement paused") end
        if player.Character~=character or humanoid.Health<=0 or not target.Parent or not target.Enabled then return stop("Ready egg or character changed") end
        local nextGoal=i==#route and goal or point.Position
        hatchWalking=humanoid;humanoid:MoveTo(nextGoal)
        local refreshed=os.clock()
        local recovery={origin=root.Position,checked=os.clock(),lastJump=-math.huge,attempts=0}
        while true do
            if not active or not hatch.enabled or busy or collectRunning or carryVisible() then return stop("Hatch movement paused") end
            if player.Character~=character or humanoid.Health<=0 or not target.Parent or not target.Enabled then return stop("Ready egg or character changed") end
            if eligible(target,root,humanoid) then stop("Ready to hatch");return true,plot end
            if recoverWalking(recovery,root,humanoid,nextGoal) then return stop("Hatch approach stuck after two jump attempts") end
            if os.clock()-started>30 then return stop("Hatch approach timed out") end
            local delta=root.Position-nextGoal
            if math.sqrt(delta.X*delta.X+delta.Z*delta.Z)<=2.5 then break end
            if os.clock()-refreshed>=1 then humanoid:MoveTo(nextGoal);refreshed=os.clock() end
            hatch.last="Walking to ready egg in your base";hatchLabel.Text=hatch.last
            task.wait(0.1)
        end
    end
    stop("Hatch approach ended")
    return eligible(target,root,humanoid),plot
end
-- HATCH_NAV_END
local function inspectOwnedBase()
    local _,plot,_,ownership=resolveAutoHome()
    local result={found=plot~=nil,reason=ownership.reason,visited=0,truncated=false,
        touchParts={},prompts={},labels={},systems={}}
    if not plot then return result end
    result.plot=plot:GetFullName()
    local queue,head={plot},1
    local function add(kind,item,limit)
        if #result[kind]<limit then result[kind][#result[kind]+1]=item else result.truncated=true end
    end
    while head<=#queue and result.visited<2000 do
        local obj=queue[head];head=head+1;result.visited=result.visited+1
        local path=obj:GetFullName()
        local lower=string.lower(path)
        local relevant=lower:find("money",1,true) or lower:find("coin",1,true) or lower:find("cash",1,true)
            or lower:find("collect",1,true) or lower:find("upgrade",1,true) or lower:find("treadmill",1,true)
        if obj:IsA("BasePart") then
            local touch=false
            for _,child in ipairs(obj:GetChildren()) do if child:IsA("TouchTransmitter") then touch=true;break end end
            if touch or relevant then
                local item={path=path,name=obj.Name,class=obj.ClassName,touch=touch,
                    position={x=obj.Position.X,y=obj.Position.Y,z=obj.Position.Z}}
                local attrs={}
                for key,value in pairs(obj:GetAttributes()) do
                    local k=string.lower(key)
                    if k:find("coin",1,true) or k:find("money",1,true) or k:find("cash",1,true)
                        or k:find("cost",1,true) or k:find("owner",1,true) then
                        if type(value)=="string" or type(value)=="number" or type(value)=="boolean" then
                            attrs[key]=type(value)=="string" and value:sub(1,100) or value
                        end
                    end
                end
                item.attributes=attrs
                add(touch and "touchParts" or "systems",item,touch and 24 or 20)
            end
        elseif obj:IsA("ProximityPrompt") then
            add("prompts",{path=path,action=obj.ActionText,object=obj.ObjectText,enabled=obj.Enabled},20)
        elseif obj:IsA("TextLabel") or obj:IsA("TextButton") then
            add("labels",{path=path,text=obj.Text:sub(1,140),class=obj.ClassName,visible=obj.Visible},24)
        elseif relevant and obj:IsA("Model") then
            add("systems",{path=path,class=obj.ClassName},20)
        end
        for _,child in ipairs(obj:GetChildren()) do
            if #queue<4000 then queue[#queue+1]=child else result.truncated=true end
        end
    end
    if head<=#queue then result.truncated=true end
    return result
end
local function collectSnapshot(includeEvidence)
    if includeEvidence then eggLogic.refresh() end
    local snapshot = {enabled = collectEgg.enabled, attempts = collectEgg.attempts,
        last = collectEgg.last, lastInput = collectEgg.lastInput, scanning = busy,
        unconfirmed = collectEgg.unconfirmed or 0, pausedReason = collectEgg.pausedReason,
        inventoryAdditionsObserved = collectEgg.inventoryAdditionsObserved or 0,
        phase = collectEgg.phase or "IDLE", deliveriesObserved = collectEgg.deliveriesObserved or 0,
        gameEvents = gameEvents, eventObserver = eventObserver,
        upgrades=upgrades,training=training,placementRecording=placementRecord,
        selectionBlocked=eggSelect.mode~="Nearest" and eggSelect.catalog.accepted==0 and ("No readable egg matches "..eggSelect.mode.."; inspect Eggs / Copy short") or nil,
        eggSelection={mode=eggSelect.mode,preferred=eggSelect.preferred,catalog=eggSelect.catalog,selected=collectEgg.selectedEgg,fieldSamples=eggSelect.fieldSamples},
        autoPlace={available=AUTO_PLACE_ENABLED,manualMode=placeState and placeState.manualMode,manualPreparing=placeState and placeState.manualPreparing,binding=placeState and placeState.binding,preparingBind=placeState and placeState.preparingBind,enabled=placeState and placeState.enabled,attempts=placeState and placeState.attempts,observed=placeState and placeState.observed,last=placeState and placeState.last,lastAttempt=placeState and placeState.lastAttempt,autoMark=placeState and placeState.autoMark,lastSlotPick=placeState and placeState.lastSlotPick},
        autoHome={enabled=autoHome.enabled,ready=autoHome.ready,reason=autoHome.reason,report=includeEvidence and autoHome.report or nil},
        lastReturn = collectEgg.lastReturn, lastNavigation = collectEgg.lastNavigation, lastWalkingRecovery=lastWalkingRecovery, deliveryPointSet = deliveryPoint ~= nil,
        approachMode=collectEgg.approachMode or "Walk", inputInProgress = collectRunning, carrying = carryVisible(), carryState = carryState(), matchingPrompts = 0,
        scope = "Walk/default or Tween pickup within 250 studs; ground return within 600 studs",
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
    if includeEvidence then snapshot.carryEvidence = carryEvidence();snapshot.baseInspection=inspectOwnedBase() end
    if snapshot.matchingPrompts == 0 then snapshot.blocked = "No CarryAreaEgg / Steal prompt in cache" end
    return snapshot
end
local function collectStep()
    if not active or not collectEgg.enabled or busy or hatchRunning or placeRunning or systemRunning then return end
    if autoHome.enabled and not deliveryPoint then
        refreshAutoHome(true)
        if not deliveryPoint then pauseCollect("Auto home not ready: "..autoHome.reason);return end
    end
    local carrying = carryState()
    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if carrying.manualMarker then collectEgg.last="User carrying marker active"; return end
    if carrying.fieldCarrying then returnHome(root,humanoid,character); return end
    if carrying.equippedEgg then collectEgg.last="Inventory egg equipped; unequip to collect field eggs"; return end
    collectEgg.phase="SEEKING"
    local all=eggLogic.refresh()
    local best,bestDistance,selected
    if eggSelect.mode=="Nearest" then
        local ready=eggLogic.choices(root,humanoid,true)
        selected=ready[1]
        if not selected and approachEgg(root,humanoid) and active and collectEgg.enabled and not busy and not carryVisible() then
            selected=eggLogic.choices(root,humanoid,true)[1]
        end
    else
        selected=all[1]
        if not selected or not selected.accepted then
            collectEgg.last="No egg has readable data matching "..eggSelect.mode.."; inspect Eggs / Copy short"
            return
        end
        if not collectCandidate(selected.prompt,root,humanoid) then
            if not approachEgg(root,humanoid,selected.prompt) then return end
        end
    end
    if not selected or not active or not collectEgg.enabled or busy or carryVisible() or player.Character~=character then return end
    best=selected.prompt;bestDistance=collectCandidate(best,root,humanoid)
    local latest=eggLogic.metadata(best)
    local priorAttempt=collectAttempts[best]
    if priorAttempt and (priorAttempt.count>=3 or os.clock()-priorAttempt.time<4) then return end
    if not bestDistance or not eggLogic.accepts(latest) or selected.meta.uid and latest.uid~=selected.meta.uid then
        collectEgg.last="Selected egg changed or no longer matches; rechecking next cycle";return
    end
    collectEgg.selectedEgg={at=os.time(),mode=eggSelect.mode,path=best:GetFullName(),distance=bestDistance,metadata=latest}
    collectEgg.phase="PICKUP"
    collectEgg.tripStartedClock=os.clock()
    local inventoryBefore = eggInventory()
    local state = collectAttempts[best] or {count = 0, time = -math.huge}
    collectAttempts[best] = state
    state.count, state.time = state.count + 1, os.clock()
    collectEgg.attempts = collectEgg.attempts + 1
    local record = {path = best:GetFullName(), distance = bestDistance, at = os.time(), status = "Started",eggSelection=collectEgg.selectedEgg}
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
local function placementRaycast(origin,direction,initialIgnore)
    local ignore={}
    for _,obj in ipairs(initialIgnore or {}) do ignore[#ignore+1]=obj end
    local skipped={}
    for _=1,10 do
        local params=RaycastParams.new()
        params.FilterType=Enum.RaycastFilterType.Exclude
        params.FilterDescendantsInstances=ignore
        local hit=workspace:Raycast(origin,direction,params)
        if not hit then return nil,skipped end
        local part=hit.Instance
        local sensor=part and part:IsA("BasePart") and (part.Name=="SpawnDetector"
            or part.Name~="PetArea" and part.Transparency>=0.95 and not part.CanCollide)
        if not sensor then return hit,skipped end
        skipped[#skipped+1]=part:GetFullName()
        ignore[#ignore+1]=part
    end
    return nil,skipped
end
local function addPlacementSlot(part,point)
    -- Preserve the actual clicked object even if ownership validation rejects
    -- marking. Generated slot objects may live outside the static plot model.
    local pick={at=os.time(),ancestry={},accepted=false}
    placeState.lastSlotPick=pick
    if point then pick.hit={x=point.X,y=point.Y,z=point.Z} end
    local node=part
    for depth=1,5 do
        if not node then break end
        local info={path=node:GetFullName(),name=node.Name,class=node.ClassName,attributes={}}
        local count=0
        for key,value in pairs(node:GetAttributes()) do
            if count>=16 then info.truncated=true;break end
            if type(value)=="number" or type(value)=="boolean" or type(value)=="string" then
                info.attributes[key]=type(value)=="string" and value:sub(1,120) or value
                count=count+1
            end
        end
        pick.ancestry[#pick.ancestry+1]=info
        node=node.Parent
    end
    local _,plot=resolveAutoHome()
    if not plot then return false,"Owned plot not confirmed" end
    if not part or not part:IsA("BasePart") or not part:IsDescendantOf(plot) then return false,"Click a part inside your own plot" end
    if #placeState.slots>=12 then return false,"Maximum 12 marked slots" end
    for _,slot in ipairs(placeState.slots) do if (slot.point-point).Magnitude<4 then return false,"Slot already marked nearby" end end
    placeState.slots[#placeState.slots+1]={part=part,point=point,plot=plot,used=false}
    placeState.lastSlotPick.accepted=true
    return true,"Empty slot marked: "..#placeState.slots
end
local function emptySlotEvidence(obj)
    local name=string.lower(obj.Name)
    if not name:find("slot",1,true) and obj:GetAttribute("SlotId")==nil and obj:GetAttribute("SlotIndex")==nil then return nil end
    local confirmed
    for _,key in ipairs({"Empty","IsEmpty"}) do
        local value=obj:GetAttribute(key)
        if value==false then return nil end
        if value==true then confirmed=key.."=true" end
    end
    for _,key in ipairs({"Occupied","IsOccupied","HasEgg","HasPet"}) do
        local value=obj:GetAttribute(key)
        if value==true then return nil end
        if value==false then confirmed=key.."=false" end
    end
    for _,key in ipairs({"EggUID","EggUid","AssetUID","AssetUid"}) do
        local value=obj:GetAttribute(key)
        if value~=nil and value~="" then return nil end
    end
    return confirmed
end
local function areaVacancies(area)
    local points={}
    local evidence={path=area:GetFullName(),tested=0,blocked=0,groundMissing=0}
    if area.Size.X<6 or area.Size.Z<6 then evidence.reason="PetArea too small";return points,evidence end
    evidence.size={x=area.Size.X,y=area.Size.Y,z=area.Size.Z}
    local ignore={area}
    local characters={}
    for _,p in ipairs(Players:GetPlayers()) do if p.Character then characters[#characters+1]=p.Character;ignore[#ignore+1]=p.Character end end
    local world=workspace:FindFirstChild("World")
    local build=world and world:FindFirstChild("Build")
    if not build then evidence.reason="Static map root unavailable";return points,evidence end
    local overlap=OverlapParams.new()
    overlap.FilterType=Enum.RaycastFilterType.Exclude
    local excluded={build,area}
    for _,character in ipairs(characters) do excluded[#excluded+1]=character end
    overlap.FilterDescendantsInstances=excluded
    local xs,zs=math.floor((area.Size.X-6)/8)+1,math.floor((area.Size.Z-6)/8)+1
    for ix=1,xs do
        for iz=1,zs do
            if evidence.tested>=100 or #points>=12 then return points,evidence end
            local x=(ix-(xs+1)/2)*8
            local z=(iz-(zs+1)/2)*8
            local origin=area.CFrame:PointToWorldSpace(Vector3.new(x,area.Size.Y/2+10,z))
            local hit=placementRaycast(origin,Vector3.new(0,-(area.Size.Y+40),0),ignore)
            evidence.tested=evidence.tested+1
            if hit and hit.Instance:GetFullName():sub(1,#"Workspace.World.Build.MainMap.Bases.")=="Workspace.World.Build.MainMap.Bases." then
                local point=hit.Position
                local occupied=false
                for _,part in ipairs(workspace:GetPartBoundsInBox(CFrame.new(point+Vector3.new(0,3.1,0)),Vector3.new(5.5,6,5.5),overlap)) do
                    if part.Transparency<0.95 or part.CanCollide then occupied=true;break end
                end
                if occupied then evidence.blocked=evidence.blocked+1 else points[#points+1]=point end
            else evidence.groundMissing=evidence.groundMissing+1 end
        end
    end
    return points,evidence
end
local function autoMarkSlots(insidePlacement)
    if insidePlacement and placeState.autoScanAt and os.clock()-placeState.autoScanAt<5 then return false,placeState.autoMark and placeState.autoMark.reason or "Waiting for slot scan" end
    placeState.autoScanAt=os.clock()
    if collectRunning or hatchRunning or placeRunning and not insidePlacement then return false,"Stop other automation before scanning slots" end
    local _,plot=resolveAutoHome()
    if not plot then return false,"Owned plot not confirmed" end
    local report={plot=plot:GetFullName(),candidates={},areas={},confirmed=0,added=0,truncated=false}
    placeState.autoMark=report
    local candidates={}
    local queue,head={plot},1
    while head<=#queue and head<=2000 do
        local obj=queue[head];head=head+1
        local name=string.lower(obj.Name)
        local clue=name=="petarea" or name:find("slot",1,true) or name:find("pad",1,true) or name:find("stand",1,true)
            or obj:GetAttribute("SlotId")~=nil or obj:GetAttribute("SlotIndex")~=nil
        if clue and #report.candidates<40 then
            local attrs={}
            for key,value in pairs(obj:GetAttributes()) do
                if type(value)=="boolean" or type(value)=="number" or type(value)=="string" then
                    attrs[key]=type(value)=="string" and value:sub(1,80) or value
                end
            end
            report.candidates[#report.candidates+1]={path=obj:GetFullName(),class=obj.ClassName,attributes=attrs}
        end
        if obj.Name=="PetArea" and obj:IsA("BasePart") then
            local ok,points,detail=pcall(areaVacancies,obj)
            if ok then
                report.areas[#report.areas+1]=detail
                for _,point in ipairs(points) do candidates[#candidates+1]={part=obj,point=point,evidence="PetArea clear-space candidate",source=obj,spatial=true} end
            else report.areas[#report.areas+1]={path=obj:GetFullName(),error=tostring(points):sub(1,160)} end
        end
        local evidence=emptySlotEvidence(obj)
        if evidence then
            local part=obj:IsA("BasePart") and obj or nil
            if not part and obj:IsA("Model") then
                local parts={}
                for _,child in ipairs(obj:GetChildren()) do if child:IsA("BasePart") then parts[#parts+1]=child end end
                if #parts==1 then part=parts[1] end
            end
            if part then candidates[#candidates+1]={part=part,evidence=evidence,source=obj} end
        end
        for _,child in ipairs(obj:GetChildren()) do
            if #queue<4000 then queue[#queue+1]=child else report.truncated=true end
        end
    end
    if head<=#queue then report.truncated=true end
    if report.truncated then report.reason="Slot scan incomplete; automatic marking skipped";return false,report.reason end
    table.sort(candidates,function(a,b) return a.part:GetFullName()<b.part:GetFullName() end)
    report.confirmed=#candidates
    for _,item in ipairs(candidates) do
        local ok=addPlacementSlot(item.part,item.point or item.part.Position)
        if ok then
            report.added=report.added+1
            placeState.slots[#placeState.slots].autoEvidence=item.evidence
            placeState.slots[#placeState.slots].emptySource=item.source
            placeState.slots[#placeState.slots].spatial=item.spatial
        end
    end
    report.reason=report.added>0 and ("Auto marked "..report.added.." placement candidates")
        or report.confirmed>0 and "Confirmed slots already marked or slot limit reached"
        or "No clear PetArea candidates or explicit empty slots; send Copy short"
    return report.added>0,report.reason
end
local function selectPlacementEgg()
    local candidates={}
    local backpack=player:FindFirstChildOfClass("Backpack")
    for _,container in pairs({character=player.Character,backpack=backpack}) do
        for _,tool in ipairs(container:GetChildren()) do
            local uid=tool:GetAttribute("UID")
            if tool:IsA("Tool") and tool:GetAttribute("ItemType")=="AssetEgg" and type(uid)=="string" and uid~="" then
                candidates[#candidates+1]={tool=tool,uid=uid}
            end
        end
    end
    table.sort(candidates,function(a,b) return a.uid<b.uid end)
    return candidates[1]
end
local function placementUIDGone(uid)
    local inventory=eggInventory()
    return inventory.complete and inventory.items[uid]==nil
end
local function placeStep()
    if not AUTO_PLACE_ENABLED then
        placeState.enabled=false
        if not placeState.manualMode then placeState.last="Auto Place disabled after kick reports. Place eggs manually." end
        return
    end
    if not active or not placeState.enabled or busy or collectRunning or hatchRunning or fieldCarryActive() or manualCarry then return end
    local _,plot=resolveAutoHome()
    if not plot then placeState.last="Owned plot not confirmed";return end
    if #placeState.slots==0 then autoMarkSlots(true) end
    local slot
    for _,item in ipairs(placeState.slots) do if not item.used and item.plot==plot and item.part.Parent then slot=item;break end end
    if not slot then placeState.last=placeState.autoMark and placeState.autoMark.reason or "Mark an empty slot in Placement";return end
    local egg=selectPlacementEgg()
    if not egg then placeState.last="No inventory egg available";return end
    local character=player.Character
    local root=character and character:FindFirstChild("HumanoidRootPart")
    local humanoid=character and character:FindFirstChildOfClass("Humanoid")
    if not root or not humanoid or humanoid.Health<=0 then return end
    humanoid:EquipTool(egg.tool)
    local delta=Vector3.new(slot.point.X-root.Position.X,0,slot.point.Z-root.Position.Z)
    if delta.Magnitude>6 then
        local goal=root.Position+delta.Unit*(delta.Magnitude-4)
        local reached,reason=walkReturn(root,humanoid,character,goal,false,slot.part,true)
        if not reached then placeState.last=reason;placeState.enabled=false;return end
    end
    if not active or not placeState.enabled or player.Character~=character or humanoid.Health<=0 or egg.tool.Parent~=character then return end
    local _,currentPlot=resolveAutoHome()
    if currentPlot~=slot.plot or not slot.part:IsDescendantOf(currentPlot) then placeState.enabled=false;placeState.last="Slot ownership changed";return end
    if slot.autoEvidence and not slot.spatial and (not slot.emptySource.Parent or not emptySlotEvidence(slot.emptySource)) then
        slot.used=true;placeState.last="Automatic slot is no longer confirmed empty; skipped";return
    end
    if slot.spatial then
        local ok,points=pcall(areaVacancies,slot.part)
        local clear=false
        if ok then for _,point in ipairs(points) do if (point-slot.point).Magnitude<1 then clear=true;break end end end
        if not clear then slot.used=true;placeState.last="PetArea candidate is no longer clear; skipped";return end
    end
    local camera=workspace.CurrentCamera
    if not camera then placeState.last="Camera unavailable";return end
    placeState.attempts=placeState.attempts+1
    local record={uid=egg.uid,part=slot.part:GetFullName(),at=os.time(),inputOK=false,worldPlacementVerified=false,cameraMode="unchanged",pressAttempted=false}
    placeState.lastAttempt=record
    local inputManager
    local activationConnection
    record.activatedCount=0;record.activationObserverAvailable=false
    if egg.tool.Activated then
        local observed,connection=pcall(function()
            return egg.tool.Activated:Connect(function() record.activatedCount=record.activatedCount+1 end)
        end)
        if observed then activationConnection=connection;record.activationObserverAvailable=true end
    end
    local previousFrameVisible=frame and frame.Visible
    local previousRestoreVisible=restore and restore.Visible
    local mouseDown=false
    local x,y
    local ok,err=pcall(function()
        if not active or not placeState.enabled then error("Placement cancelled") end
        local screen,onScreen=camera:WorldToScreenPoint(slot.point+Vector3.new(0,0.05,0))
        if not onScreen then error("Face the marked slot with the normal game camera, then enable Auto Place again") end
        local hit=placementRaycast(camera.CFrame.Position,slot.point-camera.CFrame.Position,{character})
        if hit and hit.Instance~=slot.part and (hit.Position-slot.point).Magnitude>1 then error("Marked slot is obstructed") end
        inputManager=game:GetService("VirtualInputManager")
        if frame then frame.Visible=false end
        if restore then restore.Visible=false end
        record.uiHiddenForClick=true
        task.wait(0.05)
        if not active or not placeState.enabled or player.Character~=character then error("Placement cancelled before click") end
        x,y=screen.X,screen.Y
        record.screen={x=x,y=y}
        inputManager:SendMouseMoveEvent(x,y,game)
        task.wait(0.05)
        if not active or not placeState.enabled or player.Character~=character or humanoid.Health<=0 or egg.tool.Parent~=character then error("Placement cancelled or equipped egg changed") end
        if type(player.GetMouse)=="function" then
            local mouse=player:GetMouse()
            record.mouseTargetBeforeClick=mouse.Target and mouse.Target:GetFullName() or nil
        end
        slot.used=true
        record.pressAttempted=true
        mouseDown=true
        inputManager:SendMouseButtonEvent(x,y,0,true,game,0)
        task.wait(0.08)
        inputManager:SendMouseButtonEvent(x,y,0,false,game,0)
        mouseDown=false
    end)
    if mouseDown and inputManager then pcall(function() inputManager:SendMouseButtonEvent(x,y,0,false,game,0) end) end
    if activationConnection then activationConnection:Disconnect() end
    pcall(function()
        if frame then frame.Visible=previousFrameVisible end
        if restore then restore.Visible=previousRestoreVisible end
    end)
    record.inputOK=ok
    if not ok then record.error=tostring(err):sub(1,160);record.slotReserved=slot.used;placeState.last="Placement click failed: "..record.error;placeState.enabled=false;return end
    local deadline=os.clock()+3
    local goneSince
    while active and placeState.enabled and player.Character==character and humanoid.Health>0 and os.clock()<deadline do
        if placementUIDGone(egg.uid) then goneSince=goneSince or os.clock() else goneSince=nil end
        if goneSince and os.clock()-goneSince>=0.5 then
            record.inventoryUIDRemoved=true
            placeState.observed=placeState.observed+1
            placeState.last="Egg UID left inventory after slot click; placement inferred"
            recordGameEvent("placement.observed",egg.uid,record.part)
            return
        end
        task.wait(0.1)
    end
    placeState.enabled=false
    placeState.last="Placement unconfirmed; slot reserved to avoid duplicate clicks"
end
-- This handoff never equips, activates, aims, or clicks a Tool. The player
-- performs the entire placement through the game's normal inventory/input.
local function prepareManualPlacement()
    if placeState.preparingBind then return false,"Finish slot selection preparation before manual placement" end
    placeState.manualMode=true
    placeState.enabled=false;placeState.binding=false;placeState.preparingBind=false
    collectEgg.enabled=false;hatch.enabled=false;upgrades.mode="Off";training.enabled=false
    collectEgg.phase="PAUSED"
    cancelCollectTween("Manual placement handoff")
    if hatchWalking then
        local character=player.Character
        local root=character and character:FindFirstChild("HumanoidRootPart")
        if root then pcall(function() hatchWalking:MoveTo(root.Position) end) end
        hatchWalking=nil
    end
    if holding then
        local ok=pcall(function() holding:InputHoldEnd() end)
        holding=nil
        if not ok then return false,"Could not release the current prompt; close the hub before manual placement" end
    end
    local character=player.Character
    local deadline=os.clock()+8
    -- Allow any input already in flight to release before handing control back.
    repeat
        task.wait(0.1)
        if not active or player.Character~=character then return false,"Character changed or hub closed; retry manual placement" end
        if os.clock()>=deadline and (collectRunning or hatchRunning or placeRunning or systemRunning or busy) then
            return false,"Automation has not stopped; close the hub before manual placement"
        end
    until not (collectRunning or hatchRunning or placeRunning or systemRunning or busy)
    local humanoid=character and character:FindFirstChildOfClass("Humanoid")
    if not humanoid or humanoid.Health<=0 then return false,"Living character required" end
    if fieldCarryActive() then return false,"Deliver the field egg first, then select the inventory egg yourself" end
    return true,"Automation OFF. Equip an inventory egg, walk to your base, and click an empty slot yourself. Alt reopens the hub."
end
-- Read-only observation of a player-controlled placement. No Tool activation,
-- generated input, camera movement, or placement Remote calls exist here.
local function stopPlacementRecording(reason)
    placementRecord.enabled=false
    placementRecord.last=reason or "Recording stopped"
    if recordingContext and recordingContext.record and not recordingContext.record.finishedAt then
        recordingContext.record.status="cancelled"
        recordingContext.record.worldEggAppearanceVerified=false
        recordingContext.record.stopReason=placementRecord.last
        recordingContext.record.finishedAt=os.time()
    end
    recordingContext=nil
end
local function recordEquippedEgg(character)
    local egg
    for _,tool in ipairs(character:GetChildren()) do
        if tool:IsA("Tool") and tool:GetAttribute("ItemType")=="AssetEgg" then
            local uid=tool:GetAttribute("UID")
            if egg or type(uid)~="string" or uid=="" then return nil,true end
            egg={uid=uid,name=tool.Name}
        end
    end
    return egg,false
end
local function placedRenderIdentity(obj,root)
    if not root or obj.Parent~=root or not obj:IsA("Model") then return nil end
    local owner,uid=obj.Name:match("^(%d+)_(%x+)$")
    if owner and #uid==32 then return owner,uid end
end
local function scanPlacementWorld(plot,origin)
    local result={entries={},ids={},visible={},visited=0,treeComplete=true,spatialComplete=false,
        at=os.clock(),origin=origin,radius=32,renderComplete=true,renderVisited=0}
    local plots=workspace:FindFirstChild("Plots")
    local renderRoot=workspace:FindFirstChild("PlacedEggRenders")
    result.renderRootFound=renderRoot~=nil
    local seen={}
    local function add(obj)
        if seen[obj] or obj==plot or obj==plots or obj==workspace then return end
        seen[obj]=true
        if not obj:IsA("BasePart") and not obj:IsA("Model") then return end
        local renderOwner,renderUid=placedRenderIdentity(obj,renderRoot)
        local node,explicitOwner,foreignOwner=obj,false,false
        if renderOwner then
            if renderOwner==tostring(player.UserId) then explicitOwner=true else foreignOwner=true end
        end
        for _=1,12 do
            if not node or node==workspace then break end
            if node==player.Character or node:IsA("Tool")
                or node:IsA("Model") and node:FindFirstChildOfClass("Humanoid") then return end
            if node.Parent==plots and node~=plot then foreignOwner=true end
            local owner=node:GetAttribute("OwnerUserId")
            if owner~=nil and owner~=0 and owner~="" and owner~=false then
                if tostring(owner)==tostring(player.UserId) then explicitOwner=true else foreignOwner=true end
            end
            node=node.Parent
        end
        local ok,position=pcall(function() return obj:IsA("BasePart") and obj.Position or obj:GetPivot().Position end)
        if not ok or not position then return end
        local item={obj=obj,path=obj:GetFullName(),name=obj.Name,class=obj.ClassName,position=position,ids={},attributes={},
            inOwnedPlot=obj:IsDescendantOf(plot),explicitOwner=explicitOwner,foreignOwner=foreignOwner,
            placedRender=renderOwner~=nil,renderOwnerUserId=renderOwner}
        if renderUid then
            item.ids[#item.ids+1]={key="PlacedEggRenderName",value=renderUid};result.ids[renderUid]=true
        end
        for _,key in ipairs({"ItemType","EggId","EggID","DisplayName","OwnerUserId","SlotId","SlotIndex","IsEgg","IsHatching"}) do
            local value=obj:GetAttribute(key)
            if type(value)=="number" or type(value)=="boolean" or type(value)=="string" then
                item.attributes[key]=type(value)=="string" and value:sub(1,120) or value
            end
        end
        for _,key in ipairs({"UID","Uid","EggUID","EggUid","AssetUID","AssetUid"}) do
            local value=obj:GetAttribute(key)
            if type(value)=="string" and value~="" and #value<=120 then
                item.ids[#item.ids+1]={key=key,value=value};result.ids[value]=true
            end
        end
        local compact=obj.Name:gsub("-","")
        if #compact==32 and compact:match("^%x+$") then
            item.ids[#item.ids+1]={key="Name",value=obj.Name};result.ids[obj.Name]=true
        end
        result.entries[obj]=item
    end
    local queue,head={plot},1
    while head<=#queue and result.visited<2048 do
        local obj=queue[head];head=head+1;result.visited=result.visited+1
        add(obj)
        for _,child in ipairs(obj:GetChildren()) do
            if #queue<2048 then queue[#queue+1]=child else result.treeComplete=false end
        end
    end
    if head<=#queue then result.treeComplete=false end
    -- The observed game uses direct Model children named <UserId>_<32hex UID>.
    -- Walk this owned namespace separately so spatial-query caps cannot hide it.
    if renderRoot then
        local renders=renderRoot:GetChildren()
        if #renders>512 then result.renderComplete=false end
        local renderQueue,renderHead={},1
        for i=1,math.min(#renders,512) do
            local owner=placedRenderIdentity(renders[i],renderRoot)
            if owner==tostring(player.UserId) then renderQueue[#renderQueue+1]=renders[i] end
        end
        while renderHead<=#renderQueue and result.renderVisited<2048 do
            local obj=renderQueue[renderHead];renderHead=renderHead+1;result.renderVisited=result.renderVisited+1
            add(obj)
            for _,child in ipairs(obj:GetChildren()) do
                if #renderQueue<2048 then renderQueue[#renderQueue+1]=child else result.renderComplete=false end
            end
        end
        if renderHead<=#renderQueue then result.renderComplete=false end
    end
    local ok,parts=pcall(function()
        local params=OverlapParams.new()
        params.FilterType=Enum.RaycastFilterType.Exclude
        params.FilterDescendantsInstances=player.Character and {player.Character} or {}
        local world=workspace:FindFirstChild("World")
        local build=world and world:FindFirstChild("Build")
        if build then
            local excluded=player.Character and {player.Character,build} or {build}
            params.FilterDescendantsInstances=excluded
        end
        params.MaxParts=129
        return workspace:GetPartBoundsInRadius(origin,32,params)
    end)
    if ok then
        result.spatialComplete=#parts<129
        for i=1,math.min(#parts,128) do
            local obj=parts[i]
            for _=1,8 do
                if not obj or obj==workspace then break end
                add(obj);obj=obj.Parent
            end
        end
    else result.spatialError=tostring(parts):sub(1,160) end
    for obj in pairs(result.entries) do
        if obj:IsA("BasePart") and (1-(obj.Transparency or 0))*(1-(obj.LocalTransparencyModifier or 0))>0.05 then
            local node=obj
            for _=1,12 do
                if not node or node==workspace then break end
                result.visible[node]=true;node=node.Parent
            end
        end
    end
    return result
end
local function placementWorldSummary(snapshot)
    return {at=snapshot.at,visited=snapshot.visited,treeComplete=snapshot.treeComplete,
        renderRootFound=snapshot.renderRootFound,renderComplete=snapshot.renderComplete,renderVisited=snapshot.renderVisited,
        spatialComplete=snapshot.spatialComplete,spatialError=snapshot.spatialError,
        origin={x=snapshot.origin.X,y=snapshot.origin.Y,z=snapshot.origin.Z},radius=32}
end
local function comparePlacementWorld(before,after,record,point)
    local result={scope="client_world_observation",localUserId=player.UserId,serverAcceptanceVerified=false,candidates={},matchedCount=0,
        before=placementWorldSummary(before),after=placementWorldSummary(after),candidateCount=0}
    local candidates,groups={},{}
    for obj,item in pairs(after.entries) do
        local distance=(item.position-point).Magnitude
        if distance<=8 then
            local exact=false
            for _,id in ipairs(item.ids) do if id.value==record.uid then exact=true end end
            local isNew=before.entries[obj]==nil
            if isNew or exact then
                local scopeComplete=item.placedRender and before.renderComplete and after.renderComplete
                    or item.inOwnedPlot and before.treeComplete and after.treeComplete
                    or item.explicitOwner and before.spatialComplete and after.spatialComplete
                    and (point-before.origin).Magnitude<=24
                local eligible=exact and not before.ids[record.uid] and scopeComplete
                    and after.visible[obj] and not item.foreignOwner and (item.inOwnedPlot or item.explicitOwner)
                candidates[#candidates+1]={path=item.path,name=item.name,class=item.class,
                    position={x=item.position.X,y=item.position.Y,z=item.position.Z},distance=distance,
                    uidEvidence=item.ids,uidMatches=exact,newInstance=isNew,uidVisibleBefore=before.ids[record.uid]==true,
                    attributes=item.attributes,visibleGeometry=after.visible[obj]==true,
                    inOwnedPlot=item.inOwnedPlot,explicitOwner=item.explicitOwner,foreignOwner=item.foreignOwner,
                    placedRender=item.placedRender,renderOwnerUserId=item.renderOwnerUserId,
                    baselineCompleteForMatch=scopeComplete==true}
                if eligible then
                    local nested=false
                    for i=#groups,1,-1 do
                        if obj:IsDescendantOf(groups[i]) then nested=true;break
                        elseif groups[i]:IsDescendantOf(obj) then table.remove(groups,i) end
                    end
                    if not nested then groups[#groups+1]=obj end
                end
            end
        end
    end
    table.sort(candidates,function(a,b)
        if a.uidMatches~=b.uidMatches then return a.uidMatches end
        if a.distance~=b.distance then return a.distance<b.distance end
        return a.path<b.path
    end)
    result.candidateCount=#candidates;result.candidatesTruncated=#candidates>6
    for i=1,math.min(#candidates,6) do result.candidates[i]=candidates[i] end
    result.matchedCount=#groups
    result.reason=#groups==1 and "Exact UID appeared near click in confirmed ownership scope"
        or #groups>1 and "Multiple independent objects share the UID; ambiguous"
        or #candidates>0 and "Objects observed but UID, ownership or baseline is not sufficient"
        or "No new nearby world object observed"
    return result,#groups==1 and groups[1] or nil
end
local function beginPlacementRecording()
    if placementRecord.enabled then return false,"Recording already active" end
    local ready,message=prepareManualPlacement()
    if not ready then return false,message end
    local _,plot=resolveAutoHome()
    if not plot then return false,"Recording needs a confirmed owned base" end
    recordingContext={character=player.Character,plot=plot,startedClock=os.clock()}
    local root=player.Character:FindFirstChild("HumanoidRootPart")
    if not root then recordingContext=nil;return false,"Character root unavailable" end
    recordingContext.worldBefore=scanPlacementWorld(plot,root.Position)
    placementRecord.enabled=true
    placementRecord.last="Equip an inventory egg and click an empty slot yourself; one click is recorded"
    return true,placementRecord.last
end
local function placementRecordPosition(value)
    return value and {x=value.X,y=value.Y,z=value.Z} or nil
end
local function capturePlacementClick(part,point,screen,processed)
    if not placementRecord.enabled or not recordingContext or processed then return false end
    local context=recordingContext
    if context.record then
        context.record.additionalClicks=(context.record.additionalClicks or 0)+1
        return false
    end
    local character=player.Character
    local root=character and character:FindFirstChild("HumanoidRootPart")
    local humanoid=character and character:FindFirstChildOfClass("Humanoid")
    if character~=context.character or not root or not humanoid or humanoid.Health<=0 then
        stopPlacementRecording("Character changed; recording cancelled");return false
    end
    if not part or not part.Parent or not point then placementRecord.last="No world target under mouse; waiting";return false end
    local egg,ambiguous=recordEquippedEgg(character)
    if ambiguous then placementRecord.last="Equipped egg UID is ambiguous; waiting";return false end
    local before=eggInventory()
    local source,sampleAge="at_click",0
    -- A game input handler may remove the Tool before this listener runs.
    -- Preserve the recent read-only sample and disclose its age/source.
    if not egg and context.equipped and os.clock()-context.equippedAt<=0.25 then
        egg=context.equipped;before=context.inventory
        source="recent_read_only_sample";sampleAge=(os.clock()-context.equippedAt)*1000
    end
    if not egg then placementRecord.last="No equipped egg captured at click; recording is still waiting";return false end
    local record={at=os.time(),clock=os.clock(),uid=egg.uid,eggName=egg.name,
        target={path=part:GetFullName(),class=part.ClassName,ancestry={}},
        hit=placementRecordPosition(point),screen=placementRecordPosition(screen),
        characterPosition=placementRecordPosition(root.Position),
        before={complete=before.complete,count=before.count,uidPresent=before.items[egg.uid]~=nil},
        status="observing",inputSource="UIS.InputBegan",equippedSource=source,beforeSampleAgeMs=sampleAge,worldPlacementVerified=false,
        worldEggAppearanceVerified=false,worldBefore=placementWorldSummary(context.worldBefore),
        note="World appearance is client evidence only; server acceptance is not verified"}
    record.target.inOwnedPlot=part:IsDescendantOf(context.plot)
    record.ownedPlot=context.plot:GetFullName()
    local node=part
    for _=1,4 do
        if not node then break end
        local item={path=node:GetFullName(),class=node.ClassName,attributes={}}
        for _,key in ipairs({"UID","SlotId","SlotIndex","OwnerUserId","Empty","IsEmpty","Occupied","HasEgg"}) do
            local value=node:GetAttribute(key)
            if type(value)=="number" or type(value)=="boolean" or type(value)=="string" then
                item.attributes[key]=type(value)=="string" and value:sub(1,120) or value
            end
        end
        record.target.ancestry[#record.target.ancestry+1]=item
        node=node.Parent
    end
    context.record=record
    placementRecord.records[#placementRecord.records+1]=record
    if #placementRecord.records>3 then table.remove(placementRecord.records,1) end
    placementRecord.last="Manual click recorded; observing inventory for 8 seconds"
    return true
end
local function tickPlacementRecording()
    local context=recordingContext
    if not placementRecord.enabled or not context then return end
    local character=player.Character
    local humanoid=character and character:FindFirstChildOfClass("Humanoid")
    if not active or character~=context.character or not humanoid or humanoid.Health<=0 then
        stopPlacementRecording("Character changed or hub closed; recording cancelled");return
    end
    if collectEgg.enabled or hatch.enabled or training.enabled or upgrades.mode~="Off"
        or collectRunning or hatchRunning or placeRunning or systemRunning or placeState.binding then
        stopPlacementRecording("Other automation started; recording cancelled");return
    end
    if fieldCarryActive() then stopPlacementRecording("Field carry started; recording cancelled");return end
    local record=context.record
    if not record then
        local egg,ambiguous=recordEquippedEgg(character)
        if egg then context.equipped=egg;context.equippedAt=os.clock();context.inventory=eggInventory()
        elseif ambiguous then context.equipped=nil;context.inventory=nil end
        if os.clock()-context.startedClock>=60 then stopPlacementRecording("No eligible manual click within 60 seconds") end
        return
    end
    local after=eggInventory()
    record.after={complete=after.complete,count=after.count,uidPresent=after.items[record.uid]~=nil}
    if after.complete and not record.after.uidPresent then context.goneSince=context.goneSince or os.clock()
    else context.goneSince=nil end
    record.inventoryUIDRemoved=record.before.complete and record.before.uidPresent
        and context.goneSince~=nil and os.clock()-context.goneSince>=0.5 or false
    if not context.nextWorldCheck or os.clock()>=context.nextWorldCheck or os.clock()-record.clock>=8 then
        local _,currentPlot=resolveAutoHome()
        if currentPlot~=context.plot then stopPlacementRecording("Plot ownership changed; recording cancelled");return end
        local point=Vector3.new(record.hit.x,record.hit.y,record.hit.z)
        local world=scanPlacementWorld(context.plot,point)
        local result,match=comparePlacementWorld(context.worldBefore,world,record,point)
        record.worldResult=result
        if match and context.worldMatch==match then
            context.worldSince=context.worldSince or os.clock()
        else context.worldMatch=match;context.worldSince=match and os.clock() or nil end
        context.nextWorldCheck=os.clock()+0.5
    end
    record.worldEggAppearanceVerified=record.inventoryUIDRemoved and context.worldSince~=nil
        and os.clock()-context.worldSince>=0.5 or false
    if os.clock()-record.clock<8 then return end
    record.events={}
    for _,event in ipairs(gameEvents) do
        if event.clock>=record.clock and #record.events<8 then record.events[#record.events+1]=event end
    end
    record.eventsMayBeIncomplete=true
    record.finishedAt=os.time()
    record.status=record.worldEggAppearanceVerified and "world_egg_appearance_observed"
        or record.inventoryUIDRemoved and "uid_removal_observed" or "placement_unconfirmed"
    placementRecord.last=record.worldEggAppearanceVerified and "Matching egg UID observed in base. Copy short includes world evidence."
        or record.inventoryUIDRemoved and "UID left inventory; world egg not matched. Copy short includes candidates."
        or "Placement unconfirmed by inventory; Copy short includes recording."
    placementRecord.enabled=false;recordingContext=nil
end
local function dispatchPlace()
    if placeState.binding or placeState.preparingBind then return end
    if placeRunning or hatchRunning or collectRunning then return end
    placeRunning=true
    local ok,err=pcall(placeStep)
    placeRunning=false
    if not ok then cancelCollectTween("Placement error");placeState.enabled=false;placeState.last="Place error: "..tostring(err):sub(1,140) end
    placeToggle.Text=not AUTO_PLACE_ENABLED and "Auto Place: DISABLED" or placeState.enabled and "Auto Place: ON" or "Auto Place: OFF"
    placeLabel.Text=placeState.last.."\nMarked slots: "..#placeState.slots.." | Attempts: "..placeState.attempts.." | UID removals: "..placeState.observed
end
local function parseSoftCost(text)
    local amount,suffix=string.upper(text:gsub("<[^>]*>",""):gsub(",","")):match("^%s*%$%s*([%d%.]+)%s*([KMBT]?)%s*$")
    local number=tonumber(amount)
    if not number or number<0 then return nil end
    return number*(({K=1000,M=1000000,B=1000000000,T=1000000000000})[suffix] or 1)
end
local function readCash()
    local found
    local function add(value)
        if type(value)~="number" or value<0 then return true end
        if found and value~=found then return false end
        found=value;return true
    end
    local stats=player:FindFirstChild("leaderstats")
    for _,name in ipairs({"Cash","Money","Coins"}) do
        if not add(player:GetAttribute(name)) then return nil,"Conflicting currency values" end
        local value=stats and stats:FindFirstChild(name)
        if value and (value:IsA("IntValue") or value:IsA("NumberValue")) and not add(value.Value) then return nil,"Conflicting currency values" end
    end
    return found,found and nil or "Currency not mapped: Cash/Money/Coins unavailable"
end
local function upgradeInfo(plot,kind)
    local model=plot:FindFirstChild(kind=="Base" and "PlotUpgrade" or "TreadmillUpgrade")
    local sign=model and model:FindFirstChild("Sign")
    local surface=sign and sign:FindFirstChild("SurfaceGui")
    local frame=surface and surface:FindFirstChild("Frame")
    -- Exact observed soft-currency controls only. Never select RobuxUpgrade.
    local button
    if frame then
        for _,name in ipairs({"Upgrade","FirstUpgrade"}) do
            local candidate=frame:FindFirstChild(name)
            if candidate and candidate:IsA("GuiButton") and candidate.Visible and candidate.Active~=false then button=candidate;break end
        end
    end
    local cost=button and button:FindFirstChild("Cost")
    local level=surface and surface:FindFirstChild("Level")
    if not button or not button:IsA("GuiButton") or not cost or not level then return nil,"Upgrade UI not mapped" end
    local price=parseSoftCost(cost.Text)
    local current=tonumber(level.Text:match("Level%s+(%d+)"))
    if not price or not current then return nil,"Cost/level not recognized; no purchase sent" end
    local node=button
    while node and node~=plot do
        if node:IsA("GuiObject") and not node.Visible or node:IsA("LayerCollector") and not node.Enabled then return nil,"Upgrade UI hidden" end
        node=node.Parent
    end
    if button.Active==false then return nil,"Upgrade button inactive" end
    return {button=button,price=price,level=current,levelLabel=level,sign=sign,kind=kind}
end
local function upgradeSignal(button)
    local fire=capability("firesignal")
    local connections=capability("getconnections")
    if not fire or not connections then return nil,nil,"Executor UI callbacks unavailable; use normal game button" end
    for _,name in ipairs({"MouseButton1Click","Activated"}) do
        local signal=button[name]
        if signal then
            local ok,list=pcall(connections,signal)
            if ok and type(list)=="table" and #list>0 then return signal,fire end
        end
    end
    return nil,nil,"No observed upgrade callback; no purchase sent"
end
local function upgradeStep()
    if upgrades.mode=="Off" or fieldCarryActive() or manualCarry then return end
    local _,plot=resolveAutoHome()
    if not plot then upgrades.last="Owned plot not confirmed";return end
    if upgrades.pending then
        local pending=upgrades.pending
        local info=upgradeInfo(plot,pending.kind)
        if info and info.level>pending.level then
            upgrades.observed=upgrades.observed+1;upgrades.last="Level increase observed: "..pending.kind;upgrades.pending=nil
        elseif os.clock()-pending.clock>10 then
            upgrades.last="Upgrade unconfirmed; stopped without retry";upgrades.mode="Off";upgrades.pending=nil
        else upgrades.last="Waiting for level change: "..pending.kind end
        return
    end
    if os.clock()-upgrades.lastAction<8 then return end
    local cash,reason=readCash()
    if not cash then upgrades.last=reason;return end
    local options={}
    local mapped=false
    for _,kind in ipairs({"Base","Treadmill"}) do
        if upgrades.mode=="Both" or upgrades.mode==kind then
            local info,err=upgradeInfo(plot,kind)
            if info then mapped=true;if info.price<=cash then options[#options+1]=info end elseif err then upgrades.last=err end
        end
    end
    table.sort(options,function(a,b) return a.price<b.price end)
    local info=options[1]
    if not info then if mapped then upgrades.last="Not enough game currency" end;return end
    local signal,fire,why=upgradeSignal(info.button)
    if not signal then upgrades.last=why;return end
    local character=player.Character
    local root=character and character:FindFirstChild("HumanoidRootPart")
    local humanoid=character and character:FindFirstChildOfClass("Humanoid")
    if not root or not humanoid or humanoid.Health<=0 then return end
    if (root.Position-info.sign.Position).Magnitude>12 then
        humanoid:UnequipTools()
        local delta=info.sign.Position-root.Position
        local goal=root.Position+delta.Unit*math.max(0,delta.Magnitude-6)
        local reached,err=walkReturn(root,humanoid,character,goal,false,info.sign,"upgrade")
        if not reached then upgrades.last=err;return end
    end
    if not active or upgrades.mode=="Off" or collectEgg.enabled then return end
    -- Recheck ownership, affordability and level after moving.
    local _,currentPlot=resolveAutoHome()
    local latest=currentPlot==plot and upgradeInfo(plot,info.kind)
    local balance=readCash()
    if not latest or not balance or latest.level~=info.level or latest.price>balance then upgrades.last="Upgrade state changed; rechecking next cycle";return end
    upgrades.lastAction=os.clock()
    local ok,result=pcall(fire,signal)
    if not ok or result==false then upgrades.last="Upgrade callback failed; stopped";upgrades.mode="Off";return end
    upgrades.pending={kind=info.kind,level=info.level,price=info.price,clock=os.clock()}
    upgrades.last="Upgrade input sent; waiting for level increase"
end
local function trainingStep()
    if not training.enabled or fieldCarryActive() or manualCarry or upgrades.pending then return end
    local _,plot=resolveAutoHome()
    local belt=plot and plot:FindFirstChild("TreadmillBottom")
    if not belt or not belt:IsA("BasePart") then training.last="Owned TreadmillBottom unavailable";return end
    local character=player.Character
    local root=character and character:FindFirstChild("HumanoidRootPart")
    local humanoid=character and character:FindFirstChildOfClass("Humanoid")
    if not root or not humanoid or humanoid.Health<=0 then return end
    local height=(humanoid.HipHeight or 2)+(root.Size and root.Size.Y/2 or 1)
    local target=belt.Position+Vector3.new(0,belt.Size.Y/2+height,0)
    local delta=root.Position-target
    if math.sqrt(delta.X*delta.X+delta.Z*delta.Z)>3 then
        humanoid:UnequipTools()
        local reached,err=walkReturn(root,humanoid,character,target,false,belt,"training")
        if not reached then training.last=err;return end
    end
    training.last=training.events>0 and "On treadmill; SpeedGained notification observed" or "On treadmill; waiting for speed notification"
    training.position={x=root.Position.X,y=root.Position.Y,z=root.Position.Z}
end
local function dispatchSystems()
    if systemRunning or collectRunning or hatchRunning or placeRunning or busy then return end
    if collectEgg.enabled then
        if training.enabled then training.last="Paused while Collect is enabled" end
        if upgrades.mode~="Off" then upgrades.last="Paused while Collect is enabled" end
        return
    end
    systemRunning=true
    local ok,err=pcall(function() upgradeStep();trainingStep() end)
    systemRunning=false
    if not ok then
        cancelCollectTween("System error")
        upgrades.mode="Off";training.enabled=false
        training.last="System error: "..tostring(err):sub(1,140)
    end
    upgradeToggle.Text="Upgrade: "..string.upper(upgrades.mode)
    trainToggle.Text=training.enabled and "Train: ON" or "Train: OFF"
    if upgrades.mode~="Off" or training.enabled then status.Text=(upgrades.mode~="Off" and upgrades.last or "").." | "..(training.enabled and training.last or "") end
end
-- AUTO_COLLECT_ENGINE_END
function eggUI.render()
    eggUI.modeButton.Text="Mode: "..string.upper(eggSelect.mode)
    local catalog=eggSelect.catalog
    eggUI.countLabel.Text=string.format("%d eggs / %d linked / %d income",catalog.total or 0,catalog.fieldLinked or 0,catalog.knownIncome or 0)
    local lines={"Nearby eggs (sorted for "..eggSelect.mode..")"}
    for i,entry in ipairs(catalog.entries or {}) do
        local m=entry.metadata
        lines[#lines+1]=string.format("%d. %s | /s: %s | %s | %.1f studs%s",i,m.name or (m.assetCategory and ("Category: "..tostring(m.assetCategory))) or "Unknown egg",
            m.incomePerSecond~=nil and tostring(m.incomePerSecond) or "?",m.rarity or "rarity ?",entry.distance,
            entry.eligibleForMode and "" or " | skipped")
    end
    if #(catalog.entries or {})==0 then lines[#lines+1]="No eligible nearby field prompts found." end
    lines[#lines+1]="";lines[#lines+1]="Inventory names (no quality inferred from names)"
    for _,item in ipairs(catalog.inventory or {}) do lines[#lines+1]=item.name end
    eggUI.listLabel.Text=table.concat(lines,"\n")
end
function eggUI.scan()
    local ok,err=pcall(eggLogic.refresh)
    if not ok then status.Text="Egg scan error: "..tostring(err):sub(1,140);return end
    eggUI.render()
    local catalog=eggSelect.catalog
    status.Text=catalog.fieldData.fresh==0 and "Waiting for fresh field updates from the game. Keep hub open, then Scan / Copy short."
        or catalog.fieldLinked==0 and "Field records received; no unambiguous prompt binding. Copy short includes UID / positions."
        or catalog.knownIncome==0 and "Egg records linked; income is still unknown. Copy short includes prioritized field data."
        or "Egg data refreshed. Copy short includes sources and missing/conflicting fields."
end
eggUI.scanButton.Activated:Connect(eggUI.scan)
eggUI.copyButton.Activated:Connect(function()
    local ok,payload=pcall(function() return Http:JSONEncode(eggLogic.export()) end)
    if not ok then status.Text="Egg export failed: "..tostring(payload):sub(1,140);return end
    task.spawn(copyPayload,payload,"Egg data")
end)
eggUI.modeButton.Activated:Connect(function()
    if collectEgg.enabled or collectRunning or placeState.manualPreparing or placementRecord.enabled then
        status.Text="Stop Collect / Record placement before changing egg selection";return
    end
    eggSelect.mode=({Nearest="Income",Income="Preferred",Preferred="Nearest"})[eggSelect.mode] or "Nearest"
    eggUI.scan()
end)
eggUI.applyButton.Activated:Connect(function()
    if collectEgg.enabled or collectRunning or placeState.manualPreparing or placementRecord.enabled then
        status.Text="Stop Collect / Record placement before editing priorities";return
    end
    local ok,message=eggLogic.apply(eggUI.preferredBox.Text)
    if ok then eggUI.scan() end
    status.Text=message
end)
upgradeToggle.Activated:Connect(function()
    if placeState.manualPreparing or placementRecord.enabled then status.Text="Stop Record placement before starting other actions";return end
    if systemRunning then
        if upgrades.mode~="Off" then upgrades.mode="Off";cancelCollectTween("Upgrade OFF");upgradeToggle.Text="Upgrade: OFF"
        else status.Text="Wait for training movement to stop before changing upgrade mode" end
        return
    end
    local nextMode={Off="Base",Base="Treadmill",Treadmill="Both",Both="Off"}
    upgrades.mode=nextMode[upgrades.mode] or "Off"
    upgradeToggle.Text="Upgrade: "..string.upper(upgrades.mode)
end)
trainToggle.Activated:Connect(function()
    if placeState.manualPreparing or placementRecord.enabled then status.Text="Stop Record placement before starting other actions";return end
    training.enabled=not training.enabled
    trainToggle.Text=training.enabled and "Train: ON" or "Train: OFF"
    if not training.enabled and systemRunning then cancelCollectTween("Training OFF") end
end)
autoMarkButton.Activated:Connect(function()
    if placeState.manualPreparing or placementRecord.enabled then status.Text="Stop Record placement before starting other actions";return end
    local _,message=autoMarkSlots(false)
    placeLabel.Text=message
end)
recordPlaceButton.Activated:Connect(function()
    if placementRecord.enabled then stopPlacementRecording("Stopped by user");return end
    if placeState.manualPreparing or placeState.preparingBind then return end
    placeState.manualPreparing=true
    recordPlaceButton.Text="Preparing recorder..."
    task.spawn(function()
        local ran,ready,message=pcall(beginPlacementRecording)
        placeState.manualPreparing=false
        if not active then return end
        collectButton.Text="Collect: OFF";hatchButton.Text="Auto Hatch: OFF"
        upgradeToggle.Text="Upgrade: OFF";trainToggle.Text="Train: OFF"
        recordPlaceButton.Text=placementRecord.enabled and "Record placement: ON" or "Record placement: OFF"
        recordPlaceLabel.Text=ran and message or "Recorder failed to start"
        status.Text=recordPlaceLabel.Text
        if not ran then stopPlacementRecording("Recorder failed to start") end
        if ran and ready then restore.Text="Recording: open hub";setShown(false) end
    end)
end)
manualPlaceButton.Activated:Connect(function()
    if placeState.manualPreparing or placementRecord.enabled then status.Text="Stop Record placement before starting other actions";return end
    if placeState.preparingBind then placeLabel.Text="Finish slot selection preparation first";return end
    placeState.manualPreparing=true
    manualPlaceButton.Text="Stopping automation..."
    task.spawn(function()
        local ran,ready,message=pcall(prepareManualPlacement)
        placeState.manualPreparing=false
        if not active then return end
        manualPlaceButton.Text="Manual placement"
        collectButton.Text="Collect: OFF";hatchButton.Text="Auto Hatch: OFF"
        upgradeToggle.Text="Upgrade: OFF";trainToggle.Text="Train: OFF"
        placeState.last=ran and message or "Manual handoff failed; close the hub before placement"
        placeLabel.Text=placeState.last;status.Text=placeState.last
        if ran and ready then restore.Text="Return to hub";setShown(false) end
    end)
end)
placeToggle.Activated:Connect(function()
    if placeState.manualPreparing or placementRecord.enabled then status.Text="Stop Record placement before starting other actions";return end
    if not AUTO_PLACE_ENABLED then
        placeState.enabled=false;placeState.last="Auto Place disabled after kick reports. Place eggs manually."
        placeToggle.Text="Auto Place: DISABLED";placeLabel.Text=placeState.last;return
    end
    placeState.enabled=not placeState.enabled
    placeToggle.Text=not AUTO_PLACE_ENABLED and "Auto Place: DISABLED" or placeState.enabled and "Auto Place: ON" or "Auto Place: OFF"
    if not placeState.enabled and placeRunning then cancelCollectTween("Auto Place OFF") end
end)
bindSlot.Activated:Connect(function()
    if placeState.manualPreparing or placementRecord.enabled then status.Text="Stop Record placement before starting other actions";return end
    if placeState.preparingBind then return end
    if fieldCarryActive() or manualCarry then placeLabel.Text="Deliver the field egg or clear the carrying marker before marking";return end
    placeState.preparingBind=true;placeState.binding=false
    placeState.enabled=false;collectEgg.enabled=false;hatch.enabled=false
    placeToggle.Text=not AUTO_PLACE_ENABLED and "Auto Place: DISABLED" or "Auto Place: OFF";collectButton.Text="Collect: OFF";hatchButton.Text="Auto Hatch: OFF"
    cancelCollectTween("Preparing slot selection")
    if hatchWalking then
        local character=player.Character;local root=character and character:FindFirstChild("HumanoidRootPart")
        if root then pcall(function() hatchWalking:MoveTo(root.Position) end) end
        hatchWalking=nil
    end
    if holding then pcall(function() holding:InputHoldEnd() end);holding=nil end
    placeState.last="Preparing slot selection";placeLabel.Text=placeState.last
    task.spawn(function()
        local ok,err=pcall(function()
            local deadline=os.clock()+7
            while active and (placeRunning or collectRunning or hatchRunning) and os.clock()<deadline do task.wait(0.1) end
            if not active then return end
            if placeRunning or collectRunning or hatchRunning then error("Automation is still stopping; press Mark again") end
            local character=player.Character
            local humanoid=character and character:FindFirstChildOfClass("Humanoid")
            if not humanoid then error("Character unavailable") end
            humanoid:UnequipTools()
            task.wait(0.1)
            if carryVisible() then error("An egg is still equipped or carried") end
            placeState.binding=true
            placeState.last="Waiting for your empty-slot click"
            placeLabel.Text=placeState.last
            restore.Text="Pick slot"
            setShown(false)
        end)
        placeState.preparingBind=false
        if not ok and active then placeState.last=tostring(err):sub(1,140);placeLabel.Text=placeState.last;setShown(true) end
    end)
end)
clearSlots.Activated:Connect(function()
    if placeState.manualPreparing or placementRecord.enabled then status.Text="Stop Record placement before starting other actions";return end
    if placeRunning then return end
    placeState.slots={};placeState.binding=false;placeState.enabled=false
    placeToggle.Text=not AUTO_PLACE_ENABLED and "Auto Place: DISABLED" or "Auto Place: OFF";placeLabel.Text="Slots cleared; mark empty slots again"
end)
connections[#connections+1]=UIS.InputBegan:Connect(function(input,processed)
    if not placementRecord.enabled or processed or UIS:GetFocusedTextBox()
        or input.UserInputType~=Enum.UserInputType.MouseButton1 then return end
    for _,obj in ipairs(pg:GetGuiObjectsAtPosition(input.Position.X,input.Position.Y)) do
        if obj:IsDescendantOf(gui) then return end
    end
    local ok,err=pcall(function()
        local mouse=player:GetMouse()
        capturePlacementClick(mouse.Target,mouse.Hit.Position,input.Position,processed)
    end)
    if not ok then stopPlacementRecording("Recorder error: "..tostring(err):sub(1,100)) end
end)
connections[#connections+1]=UIS.InputBegan:Connect(function(input,processed)
    if not placeState.binding or input.UserInputType~=Enum.UserInputType.MouseButton1 then return end
    for _,obj in ipairs(pg:GetGuiObjectsAtPosition(input.Position.X,input.Position.Y)) do
        if obj:IsDescendantOf(gui) then return end
    end
    if carryVisible() then placeState.binding=false;placeState.last="Unequip the egg before marking";placeLabel.Text=placeState.last;setShown(true);restore.Text="YUU HUB";return end
    local mouse=player:GetMouse()
    local ray=mouse.UnitRay
    local character=player.Character
    local hit,skipped=placementRaycast(ray.Origin,ray.Direction*1000,character and {character} or {})
    local ok,message=addPlacementSlot(hit and hit.Instance or nil,hit and hit.Position or mouse.Hit.Position)
    if placeState.lastSlotPick then
        placeState.lastSlotPick.skippedSensors=skipped
        placeState.lastSlotPick.originalMouseTarget=mouse.Target and mouse.Target:GetFullName() or nil
    end
    placeState.last=message
    if placeState.lastSlotPick then placeState.lastSlotPick.gameProcessed=processed;placeState.lastSlotPick.message=message end
    placeLabel.Text=message
    placeState.binding=false
    restore.Text="YUU HUB"
    setShown(true);showTab("Placement")
end)
approachButton.Activated:Connect(function()
    if collectRunning then status.Text="Stop Collect before changing movement mode";return end
    collectEgg.approachMode=collectEgg.approachMode=="Tween" and "Walk" or "Tween"
    approachButton.Text="Approach: "..string.upper(collectEgg.approachMode)
end)
-- Read-only event observations. Payloads are bounded and are not interpreted as
-- authoritative carry state until the event contract is established.
local watchedEvents = {
    ["RE/EggWorld/FieldEggShifted"]=true,["RE/EggWorld/FieldEggBatchShifted"]=true,
    ["RE/EggWorld/FieldEggCarry"]=true, ["RE/EggWorld/FieldEggGone"]=true,
    ["RE/EggWorld/FieldEggRedeemVerdict"]=true, ["RE/EggWorld/OwnerDropped"]=true,
    ["RE/EggWorld/OwnerShifted"]=true, ["RE/GuardPatrol/SpeedTollWarning"]=true, ["RE/Treadmill/SpeedGained"]=true,
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
    if collectRunning then status.Text="Stop Collect before changing home mode";return end
    autoHome.enabled=not autoHome.enabled
    if autoHome.enabled then
        refreshAutoHome(true);status.Text=autoHome.reason
    else
        clearHomeButton.Text="Auto home: OFF";status.Text="Automatic home disabled; current point retained"
    end
end)
carryMarker.Activated:Connect(function()
    setManualCarry(not manualCarry)
    carryMarker.Text = manualCarry and "Carrying marker ON • click to clear" or "Mark: I am carrying an egg"
    collectButton.Text = collectEgg.enabled and "Collect: ON" or "Collect: OFF"
    collectLabel.Text = manualCarry and "Carrying (marked by user); deliver manually" or "Carrying marker cleared"
end)
connections[#connections+1] = player.CharacterAdded:Connect(function()
    if placementRecord.enabled then stopPlacementRecording("Respawn; recording cancelled") end
    cancelCollectTween("Character changed")
    serverCarry=nil
    lastRedeem=nil
    collectEgg.enabled=false
    collectEgg.tripInventory=nil
    collectEgg.phase="PAUSED"
    collectButton.Text="Collect: OFF"
    setManualCarry(false)
    carryMarker.Text = "Mark: I am carrying an egg"
end)
collectButton.Activated:Connect(function()
    if placeState.manualPreparing or placementRecord.enabled then status.Text="Stop Record placement before starting other actions";return end
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
    stopPlacementRecording("UI closed")
    hatch.enabled = false
    placeState.enabled=false;placeState.binding=false
    upgrades.mode="Off";training.enabled=false
    if hatchWalking then
        local character=player.Character;local root=character and character:FindFirstChild("HumanoidRootPart")
        if root then pcall(function() hatchWalking:MoveTo(root.Position) end) end
        hatchWalking=nil
    end
    collectEgg.enabled = false
    cancelCollectTween("UI closed")
    if cameraConnection then cameraConnection:Disconnect() end
    if holding then pcall(function() holding:InputHoldEnd() end); holding = nil end
    for _, connection in ipairs(connections) do connection:Disconnect() end
end
task.spawn(function()
    while active do
        task.wait(0.1)
        if placementRecord.enabled then
            local ok,err=pcall(tickPlacementRecording)
            if not ok then stopPlacementRecording("Recorder error: "..tostring(err):sub(1,100)) end
        end
        if active and not placeState.manualPreparing then
            recordPlaceButton.Text=placementRecord.enabled and "Record placement: ON" or "Record placement: OFF"
            recordPlaceLabel.Text=placementRecord.last
        end
    end
end)
local lifetime = gui.AncestryChanged:Connect(function(_, parent)
    if parent == nil then stopHatch() end
end)
task.spawn(function()
    while active do
        task.wait(1)
        if active and autoHome.enabled then
            local ok,err=pcall(refreshAutoHome,false)
            if not ok then autoHome.ready=false;autoHome.reason="Auto home error: "..tostring(err):sub(1,100);deliveryPoint=nil end
        end
        dispatchPlace()
        dispatchCollect()
        dispatchHatch(false)
        dispatchSystems()
        if eggUI.page.Visible then eggUI.render() end
        if active and collectEgg.enabled then
            local ok, snapshot = pcall(collectSnapshot)
            if ok then
                local n = snapshot.nearest
                collectLabel.Text = "Collect: " .. (snapshot.carrying and "Egg held/equipped; collection paused"
                    or snapshot.selectionBlocked or n and (n.reason .. (n.distance and string.format(" | %.1f/%.1f studs",n.distance,n.allowedDistance) or ""))
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
        local report = {version = "1.44", placeId = game.PlaceId,
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
        local summary = {version = "1.44", placeId = report.placeId, summaryOnly = true,
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
        status.Text = string.format("v1.44 | Scanned %d | GUI %d | Prompts %d | Remotes %d | Limited: %s", report.scanned, #report.gui, #report.prompts, #report.remotes, tostring(report.truncated))
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







