-- Steal An Egg: automation v1.54
-- Auto Hatch test via nearby enabled prompts; Auto Collect tests nearby CarryAreaEgg prompts; remaining systems await mapping.
local AUTO_PLACE_ENABLED = false -- Disabled after user-confirmed BAC kick reports.
local Players = game:GetService("Players")
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
gui.DisplayOrder = 1000
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
    if camera then scale.Scale = math.max(0.1, math.min(1, (camera.ViewportSize.X-24)/760, (camera.ViewportSize.Y-64)/540)) end
end
fit()
local title = label(frame, "YUU HUB", 20,12,200,28,22,colors.cyan)
label(frame, "STEAL AN EGG  /  v1.54", 20,40,300,20,11,colors.muted)
local minimize = control(frame, "—", 670,16,32,30)
local close = control(frame, "X", 710,16,32,30)
local sidebar = create("Frame", frame, {Position = UDim2.fromOffset(12,76), Size = UDim2.fromOffset(148,382), BackgroundColor3 = colors.panel})
round(sidebar)
label(sidebar, "WORKSPACE",12,10,125,22,10,colors.muted)
local automation = create("Frame", frame, {Position = UDim2.fromOffset(176,76), Size = UDim2.fromOffset(568,382), BackgroundTransparency = 1})
local settings = create("Frame", frame, {Position = automation.Position, Size = automation.Size, BackgroundTransparency = 1, Visible = false})
local tabs = {}
local function showTab(name)
    automation.Visible = name == "Automation"
    settings.Visible = name == "Settings"
    for key, b in pairs(tabs) do
        b.BackgroundColor3 = key == name and colors.purple or colors.panel
    end
end
for i, name in ipairs({"Automation", "Settings"}) do
    local b = control(sidebar,name,8,42+(i-1)*44,132,36)
    tabs[name] = b
    b.Activated:Connect(function() showTab(name) end)
end
label(sidebar,"By Yuu Walker",12,344,130,22,11,colors.muted)
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
local collectLabel = label(automation,"Collect OFF",0,282,568,68,12,colors.muted)
collectLabel.TextWrapped=true;collectLabel.TextYAlignment=Enum.TextYAlignment.Top
local status = label(frame,"Ready. Turn Collect ON to detect eggs automatically.",176,472,568,52,12,colors.muted)
status.TextWrapped = true
label(settings,"Settings",0,0,400,30,22)
label(settings,"Interface",0,50,400,24,14,colors.cyan)
label(settings,"Drag header to move. Alt or RightShift toggles the window.",0,88,568,24,12)
label(settings,"Close stops all automation. Minimize keeps it running.",0,118,568,24,12)
label(settings,"All automation starts OFF. Upgrades use game currency only.",0,148,568,24,12,colors.muted)
label(settings,"Collect: WALK default, optional Tween; range 250 studs.",0,190,568,24,12,colors.cyan)
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
local active = true
local function capability(name)
    local direct = ({firesignal=firesignal,getconnections=getconnections})[name]
    if type(direct) == "function" then return direct end
    for _, getter in pairs({getgenv = getgenv, getrenv = getrenv}) do
        if type(getter) == "function" then
            local ok, env = pcall(getter)
            if ok and type(env) == "table" and type(env[name]) == "function" then return env[name] end
        end
    end
    if type(_G) == "table" and type(_G[name]) == "function" then return _G[name] end
end
local busy = false
-- AUTO_HATCH_BEGIN
local hatchButton = control(rows[1], "Auto Hatch: OFF", 410,8,146,34)
local testHatch = control(automation,"Test Hatch once",0,358,150,24)
local hatchLabel = label(automation,"Auto approaches ready eggs in your base.",160,354,408,28,11,colors.muted)
hatchLabel.TextWrapped = true
local carryMarker = control(settings,"Mark: I am carrying an egg",0,268,270,34)
local approachButton=control(settings,"Approach: WALK",0,310,270,30)
local priorityButton=control(settings,"Priority: RARITY",280,310,250,30)
local setHomeButton = control(settings,"Set delivery point here",0,346,260,30)
local clearHomeButton = control(settings,"Auto home: ON",270,346,260,30)
local upgradeToggle=control(rows[3],"Upgrade: OFF",410,8,146,34)
local trainToggle=control(rows[4],"Train: OFF",410,8,146,34)
local collectButton = control(rows[2], "Collect: OFF", 410,8,146,34)
local collectEgg = {enabled = false, attempts = 0, last = "OFF", approachMode="Walk"}
local eggSelect={mode="Rarity",preferred={},catalog={entries={}},fieldSamples={}}
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
    local _,currentPlot=hatchResolvePlot()
    if currentPlot~=ownedPlot then hatch.last="Plot ownership changed; Hatch waits";hatchLabel.Text=hatch.last;return end
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
        hatch.enabled=false;hatchButton.Text="Auto Hatch: OFF"
        if hatchWalking then
            local character=player.Character;local root=character and character:FindFirstChild("HumanoidRootPart")
            if root then pcall(function() hatchWalking:MoveTo(root.Position) end) end
            hatchWalking=nil
        end
        if holding then pcall(function() holding:InputHoldEnd() end);holding=nil end
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
eggLogic.sourceEvents={}
eggLogic.sourceFields={"IncomePerSecond","CashPerSecond","MoneyPerSecond","CoinsPerSecond","ValuePerSecond",
    "Rarity","RarityName","RarityId","Tier","Income","BaseIncome","BaseValue","Value","Price","SellPrice","Rate",
    "AssetCategory","DisplayName","EggName","AreaId","Uid","UID","EggUid","EggUID","BaseMutation","Mutations"}
function eggLogic.sourceScalar(value,limit)
    if type(value)=="string" then
        local finish=math.min(#value,limit or 160)
        while finish<#value do
            local byte=value:byte(finish+1)
            if byte<128 or byte>=192 then break end
            finish=finish-1
        end
        return value:sub(1,finish)
    end
    if type(value)=="number" and value==value and math.abs(value)~=math.huge then return value end
    if type(value)=="boolean" then return value end
end
function eggLogic.sourceValue(value,depth,state)
    local scalar=eggLogic.sourceScalar(value)
    if scalar~=nil then return scalar end
    if type(value)~="table" then return "<"..typeof(value)..">" end
    if state.seen[value] then return "<cycle>" end
    if depth>=4 or state.remaining<=0 then return "<limit>" end
    state.seen[value]=true
    local result,keys,used={},{},{}
    for _,key in ipairs(eggLogic.sourceFields) do if value[key]~=nil then keys[#keys+1]=key;used[key]=true end end
    local examined=0
    for key in pairs(value) do
        examined=examined+1
        if examined>128 then result.__keysTruncated=true;break end
        if not used[key] and (type(key)=="string" or type(key)=="number") then keys[#keys+1]=key end
    end
    for i,key in ipairs(keys) do
        if i>24 or state.remaining<=0 then result.__truncated=true;break end
        state.remaining=state.remaining-1
        result[tostring(key):sub(1,120)]=eggLogic.sourceValue(value[key],depth+1,state)
    end
    state.seen[value]=nil
    return result
end
function eggLogic.observeSource(name,...)
    if name~="RE/EggWorld/FieldEggRaritiesShown" and name~="RE/EggWorld/FieldEggRedeemVerdict" then return end
    local sample={name=name,at=os.time(),args={},observationOnly=true}
    local state={remaining=160,seen={}}
    for i=1,math.min(select("#",...),2) do sample.args[i]=eggLogic.sourceValue(select(i,...),0,state) end
    sample.argumentCount=select("#",...);sample.budgetExhausted=state.remaining<=0
    local events=eggLogic.sourceEvents
    events[#events+1]=sample
    if #events>4 then table.remove(events,1) end
end
function eggLogic.sourceScore(name)
    local lower=name:lower()
    for _,word in ipairs({"income","persecond","rarit","econom","earning"}) do if lower:find(word,1,true) then return 4 end end
    for _,word in ipairs({"egg","asset","pet","animal","creature","mutation"}) do if lower:find(word,1,true) then return 3 end end
    for _,word in ipairs({"data","config","definition","catalog","stat","value","rate","coin","cash","money"}) do
        if lower:find(word,1,true) then return 1 end
    end
    return 0
end
function eggLogic.scanSources(roots)
    if eggLogic.sourceRunning then return false,"Source scan already running" end
    eggLogic.sourceRunning=true
    local result={at=os.time(),roots={},modules={},readableFields={},labels={},
        scope="client_readable_source_discovery",observationOnly=true,rankingApplied=false,visited=0,
        limits={modules=40,readableFields=40,labels=16},errors=0}
    local ok,err=pcall(function()
        if not roots then
            local storage=game:GetService("ReplicatedStorage")
            roots={{object=storage,label="ReplicatedStorage",budget=6000},{object=pg,label="PlayerGui",budget=4000},
                {object=workspace:FindFirstChild("PlacedEggRenders"),label="PlacedEggRenders",budget=2000},
                {object=player:FindFirstChildOfClass("Backpack"),label="Backpack",budget=256},
                {object=player.Character,label="Character",budget=256}}
        end
        local categories={}
        for _,record in pairs(eggLogic.field.records) do
            local category=record.fields.AssetCategory
            if type(category)=="string" then categories[category:lower()]=true end
        end
        for _,root in ipairs(roots) do
            local report={name=root.label,budget=root.budget,visited=0,found=root.object~=nil,complete=true}
            result.roots[#result.roots+1]=report
            local queue=root.object and {{object=root.object,context=0}} or {}
            local index=1
            while index<=#queue and report.visited<root.budget and active do
                local item=queue[index];index=index+1
                local obj=item.object
                report.visited=report.visited+1;result.visited=result.visited+1
                local good=pcall(function()
                    if gui and (obj==gui or obj:IsDescendantOf(gui)) then report.skippedHub=true;return end
                    if root.label=="ReplicatedStorage" and obj.Parent==root.object and obj.Name=="Assets" then
                        report.skippedVisualAssets=true;return
                    end
                    local score=math.max(eggLogic.sourceScore(obj.Name),categories[obj.Name:lower()] and 5 or 0)
                    local relevant=score>0 or item.context>0
                    local path=obj:GetFullName()
                    local fields,fieldScore={},0
                    local attrs=obj:GetAttributes()
                    for _,key in ipairs(eggLogic.sourceFields) do
                        local value=eggLogic.sourceScalar(attrs[key])
                        if value~=nil then fields[key]=value end
                    end
                    local attributeKeys,count={},0
                    for key,value in pairs(attrs) do
                        count=count+1
                        if count>64 then fields.__attributesTruncated=true;break end
                        if relevant then attributeKeys[#attributeKeys+1]=key:sub(1,80) end
                        if eggLogic.sourceScore(key)>=4 then fields[key:sub(1,80)]=eggLogic.sourceScalar(value) end
                    end
                    table.sort(attributeKeys)
                    -- Named values are observations; a price or generic Rate is never a /s score.
                    if obj:IsA("StringValue") or obj:IsA("NumberValue") or obj:IsA("IntValue") then
                        for _,key in ipairs(eggLogic.sourceFields) do
                            if obj.Name==key then fields[key]=eggLogic.sourceScalar(obj.Value);break end
                        end
                        if eggLogic.sourceScore(obj.Name)>=4 then fields[obj.Name:sub(1,80)]=eggLogic.sourceScalar(obj.Value) end
                    end
                    if next(fields) then
                        for key in pairs(fields) do fieldScore=math.max(fieldScore,eggLogic.sourceScore(key)) end
                        result.readableFields[#result.readableFields+1]={path=path,class=obj.ClassName,fields=fields,score=fieldScore,
                            parent=obj.Parent and obj.Parent:GetFullName(),identityUnverified=true}
                        table.sort(result.readableFields,function(a,b) return a.score==b.score and a.path<b.path or a.score>b.score end)
                        if #result.readableFields>40 then table.remove(result.readableFields);result.fieldsTruncated=true end
                    end
                    if obj:IsA("TextLabel") then
                        local text=obj.Text:sub(1,160)
                        if score>=4 or text:find("/s",1,true) or text:lower():find("per second",1,true) then
                            if #result.labels<16 then
                                local visible,node=true,obj
                                while node and node~=root.object do
                                    if node:IsA("GuiObject") and not node.Visible or node:IsA("LayerCollector") and not node.Enabled then visible=false end
                                    node=node.Parent
                                end
                                result.labels[#result.labels+1]={path=path,text=text,visible=visible,identityUnverified=true}
                            else result.labelsTruncated=true end
                        end
                    end
                    if obj:IsA("ModuleScript") and relevant then
                        local definitionPath=path:find(".Data.",1,true) or path:find(".Shared.",1,true)
                        result.modules[#result.modules+1]={path=path,name=obj.Name,score=math.max(score,item.context)+(definitionPath and 2 or 0),
                            attributeKeys=attributeKeys,inspection="path_only; module was not executed"}
                        table.sort(result.modules,function(a,b) return a.score==b.score and a.path<b.path or a.score>b.score end)
                        if #result.modules>40 then table.remove(result.modules);result.modulesTruncated=true end
                    end
                    -- Do not explore libraries, networking, arbitrary GUI scripts or source properties.
                    local skip=obj.Name=="Packages" or obj.Name=="Networking" or obj:IsA("Script") or obj:IsA("LocalScript")
                    if not skip then
                        local children=obj:GetChildren()
                        table.sort(children,function(a,b)
                            local preferred={Data=10,Shared=9,Config=8,Definitions=8}
                            local sa,sb=preferred[a.Name] or 0,preferred[b.Name] or 0
                            return sa==sb and a.Name<b.Name or sa>sb
                        end)
                        for _,child in ipairs(children) do
                            if #queue>=root.budget then report.complete=false;report.queueLimited=true;break end
                            queue[#queue+1]={object=child,context=math.max(score,item.context-1)}
                        end
                    end
                end)
                if not good then result.errors=result.errors+1;report.complete=false end
                if result.visited%128==0 then task.wait() end
            end
            if index<=#queue or not active then report.complete=false end
            if not report.complete then result.truncated=true end
        end
    end)
    eggLogic.sourceRunning=false
    if not ok then result.error=tostring(err):sub(1,160) end
    result.status=not active and "cancelled" or not ok and "error" or "complete"
    result.finishedAt=os.time()
    eggLogic.sources=result
    return ok and active,result
end
eggLogic.definitionPaths={{"Data","Assets"},{"Data","Rarity"},{"Shared","Util","AssetEarnings"}}
function eggLogic.definitionTarget(storage,parts)
    local node=storage
    for _,name in ipairs(parts) do
        local children=node:GetChildren()
        if #children>512 then return nil,"path_scope_limited" end
        local match,count=nil,0
        for _,child in ipairs(children) do if child.Name==name then match=child;count=count+1 end end
        if count~=1 then return nil,count==0 and "not_found" or "ambiguous_path" end
        node=match
    end
    if not node:IsA("ModuleScript") then return nil,"not_module_script" end
    return node
end
function eggLogic.definitionSnapshot(value,categories,omitRootKeys)
    local state={remaining=256,seen={},limited=false,visited=0}
    local priority={"perSecond","perSecondDisplay","rarity","Category","category","BaseEarnings","EarningsPerSecond",
        "BaseIncome","Income","Weight","Scale","Mutations","Configs","configs","Assets","assets","Definitions","definitions",
        "Data","data","Rarities","rarities","Stats","stats","Earnings","earnings","EarningRate","ModelWeight","_id","Rank","Egg","GrowthTime","WeightKg"}
    for _,key in ipairs(eggLogic.sourceFields) do priority[#priority+1]=key end
    local function visit(item,depth)
        if type(item)=="string" and #item>160 then state.limited=true end
        local scalar=eggLogic.sourceScalar(item)
        if scalar~=nil then return scalar end
        if type(item)~="table" then return "<"..typeof(item)..">" end
        if state.seen[item] then return "<cycle>" end
        if depth>=4 or state.remaining<=0 then state.limited=true;return "<limit>" end
        state.seen[item]=true
        local out,keys,used={},{},{}
        local function add(key)
            if depth==0 and omitRootKeys and omitRootKeys[key] then return end
            if not used[key] and rawget(item,key)~=nil then keys[#keys+1]=key;used[key]=true end
        end
        for _,category in ipairs(categories or {}) do add(category) end
        for _,key in ipairs(priority) do add(key) end
        local count=0
        for key in next,item do
            count=count+1
            if count>128 then state.limited=true;out.__keysTruncated=true;break end
            if type(key)=="string" or type(key)=="number" then add(key) end
        end
        for i,key in ipairs(keys) do
            if i>32 or state.remaining<=0 then out.__truncated=true;state.limited=true;break end
            if #tostring(key)>120 then state.limited=true end
            state.remaining=state.remaining-1;state.visited=state.visited+1
            out[eggLogic.sourceScalar(tostring(key),120)]=visit(rawget(item,key),depth+1)
        end
        state.seen[item]=nil
        return out
    end
    local result={returnedType=typeof(value),data=visit(value,0),visited=0,complete=false,
        exportedFunctionsInvoked=false,rankingApplied=false,limits={entries=256,perTable=32,depth=4}}
    result.visited=state.visited;result.complete=not state.limited
    if omitRootKeys and type(value)=="table" then
        result.omittedKeys={}
        for key in pairs(omitRootKeys) do if rawget(value,key)~=nil then result.omittedKeys[#result.omittedKeys+1]=key end end
        table.sort(result.omittedKeys)
        if #result.omittedKeys>0 then result.complete=false;result.omittedByDesign=true end
    end
    if type(value)=="table" then
        result.keys={};local count=0
        for key in next,value do
            count=count+1;if count>96 then result.keysTruncated=true;result.complete=false;break end
            if type(key)=="string" or type(key)=="number" then result.keys[#result.keys+1]={name=eggLogic.sourceScalar(tostring(key),120),keyType=type(key),valueType=typeof(rawget(value,key))} end
        end
        table.sort(result.keys,function(a,b) return a.name<b.name end)
    end
    return result
end
function eggLogic.directoryByteCost(value)
    local kind=type(value)
    if kind=="string" then return 6*#value+2 end
    if kind=="number" then return 64 end
    if kind=="boolean" then return 5 end
    if kind~="table" then return 4 end
    local size=2
    for key,item in next,value do size=size+eggLogic.directoryByteCost(tostring(key))+eggLogic.directoryByteCost(item)+2 end
    return size
end
function eggLogic.assetDirectory(value,shouldContinue)
    local result={sourcePath="ReplicatedStorage.Data.Assets.Directory",entries={},scanned=0,exported=0,
        invalidRecords=0,fieldErrors=0,textTruncated=0,recordsWithMissingFields=0,identityConflicts=0,
        complete=false,traversalComplete=false,requiredFieldsComplete=false,
        limits={entries=4096,conservativeJsonBytes=2097152},estimatedBytes=0,
        rankingApplied=false,earningRateSemantics="catalog_field_only; actual earnings formula unverified"}
    local directory=type(value)=="table" and rawget(value,"Directory")
    if type(directory)~="table" then result.status=directory==nil and "directory_missing" or "directory_not_table";return result end
    result.status="reading"
    local lastKey,ids=nil,{}
    while true do
        if not active or shouldContinue and not shouldContinue() then result.status="cancelled";break end
        local key,definition=next(directory,lastKey)
        if key==nil then result.traversalComplete=true;result.totalEntries=result.scanned;result.status="captured";break end
        lastKey=key
        if result.scanned>=result.limits.entries then result.status="entry_limit";result.observedAtLeast=result.scanned+1;break end
        result.scanned=result.scanned+1
        local entry={keyType=type(key),missingFields={},issues={}}
        if type(key)=="string" or type(key)=="number" then
            entry.categoryKey=eggLogic.sourceScalar(tostring(key))
            if type(key)=="string" and #key>160 then result.textTruncated=result.textTruncated+1;entry.keyTruncated=true end
        else entry.categoryKey="<unsupported key>";entry.issues[#entry.issues+1]="unsupported_directory_key" end
        local function read(obj,name,expected,path,required)
            local raw=rawget(obj,name)
            if raw==nil then if required then entry.missingFields[#entry.missingFields+1]=path end;return nil end
            if type(raw)~=expected or expected=="number" and (raw~=raw or math.abs(raw)==math.huge) then
                entry.issues[#entry.issues+1]=path..": unsupported "..typeof(raw);result.fieldErrors=result.fieldErrors+1;return nil
            end
            if expected=="string" and #raw>160 then
                entry.issues[#entry.issues+1]=path..": text limited";result.textTruncated=result.textTruncated+1
            end
            return eggLogic.sourceScalar(raw)
        end
        if type(definition)=="table" and (type(key)=="string" or type(key)=="number") then
            entry._id=read(definition,"_id","string","_id",true)
            entry.DisplayName=read(definition,"DisplayName","string","DisplayName",true)
            entry.EarningRate=read(definition,"EarningRate","number","EarningRate",true)
            entry.ModelWeight=read(definition,"ModelWeight","number","ModelWeight",false)
            local egg=rawget(definition,"Egg")
            if type(egg)=="table" then
                entry.Egg={DisplayName=read(egg,"DisplayName","string","Egg.DisplayName",true),
                    GrowthTime=read(egg,"GrowthTime","number","Egg.GrowthTime",false),WeightKg=read(egg,"WeightKg","number","Egg.WeightKg",false)}
            elseif egg==nil then entry.missingFields[#entry.missingFields+1]="Egg"
            else entry.issues[#entry.issues+1]="Egg: unsupported "..typeof(egg);result.fieldErrors=result.fieldErrors+1 end
            local rarity=rawget(definition,"Rarity")
            if type(rarity)=="table" then
                entry.Rarity={_id=read(rarity,"_id","string","Rarity._id",true),
                    DisplayName=read(rarity,"DisplayName","string","Rarity.DisplayName",false),Rank=read(rarity,"Rank","number","Rarity.Rank",true)}
            elseif rarity==nil then entry.missingFields[#entry.missingFields+1]="Rarity"
            else entry.issues[#entry.issues+1]="Rarity: unsupported "..typeof(rarity);result.fieldErrors=result.fieldErrors+1 end
            if entry._id and not entry.keyTruncated then
                ids[entry._id]=(ids[entry._id] or 0)+1
                entry.keyIdMismatch=type(key)~="string" or key~=entry._id
            end
        else
            result.invalidRecords=result.invalidRecords+1
            entry.recordType=typeof(definition);entry.issues[#entry.issues+1]="definition_not_supported"
        end
        if #entry.missingFields>0 then result.recordsWithMissingFields=result.recordsWithMissingFields+1 end
        local cost=eggLogic.directoryByteCost(entry)
        if result.estimatedBytes+cost>result.limits.conservativeJsonBytes then result.status="byte_limit";result.observedAtLeast=result.scanned;break end
        result.estimatedBytes=result.estimatedBytes+cost
        result.entries[#result.entries+1]=entry
        if result.scanned%128==0 then task.wait() end
    end
    for _,entry in ipairs(result.entries) do
        if entry._id and (ids[entry._id] or 0)>1 then entry.duplicateDefinitionId=true end
        if entry.duplicateDefinitionId or entry.keyIdMismatch or entry.keyTruncated then result.identityConflicts=result.identityConflicts+1 end
    end
    table.sort(result.entries,function(a,b)
        if a.categoryKey~=b.categoryKey then return a.categoryKey<b.categoryKey end
        return a.keyType<b.keyType
    end)
    result.exported=#result.entries
    result.complete=result.traversalComplete and result.exported==result.scanned and result.invalidRecords==0 and result.fieldErrors==0 and result.textTruncated==0
    result.requiredFieldsComplete=result.complete and result.recordsWithMissingFields==0
    result.finishedAt=os.time()
    return result
end
function eggLogic.directoryStatus()
    for _,module in ipairs(eggLogic.definitions and eggLogic.definitions.modules or {}) do
        local d=module.directory
        if d then
            return string.format("Directory: %d/%s | %s | missing fields: %d",d.exported,tostring(d.totalEntries or "?"),
                d.complete and "all rows captured" or ("limited/invalid: "..d.status),d.recordsWithMissingFields),d
        end
    end
end
function eggLogic.inspectDefinitions(shouldContinue)
    if eggLogic.definitionRunning or busy or eggLogic.sourceRunning then return false,"Another scan is running" end
    if eggLogic.definitionPending and not eggLogic.definitionPending.done then return false,"Previous game module is still loading; no duplicate load started" end
    eggLogic.definitionRunning=true;busy=true
    eggLogic.rarityIndex=nil -- A new observation must not reuse the previous ranks.
    local report={at=os.time(),status="running",modules={},scope="explicit_game_module_exports",loadMethod="require",moduleInitializationMayRun=true,
        trigger=shouldContinue and "collect_on" or "diagnostic",rankingApplied=false,exportedFunctionsInvoked=false,categories={},limits={modules=3,secondsPerModule=5}}
    eggLogic.definitions=report
    local ok,err=pcall(function()
        local seen={}
        local function category(value)
            if type(value)=="string" and #value<=120 and not seen[value] and #report.categories<16 then
                seen[value]=true;report.categories[#report.categories+1]=value
            end
        end
        for _,entry in ipairs(eggSelect.catalog.entries or {}) do category(entry.metadata.assetCategory) end
        local inventory=eggLogic.toolCatalog()
        for _,entry in ipairs(inventory.entries) do
            -- Tool names are not substituted for the game's Category identity.
            for _,container in pairs({player.Character,player:FindFirstChildOfClass("Backpack")}) do
                for i,tool in ipairs(container:GetChildren()) do
                    if i>1000 then break end
                    if tool:IsA("Tool") and eggLogic.toolRefs[tool]==entry.ref then category(tool:GetAttribute("Category")) end
                end
            end
        end
        local storage=game:GetService("ReplicatedStorage")
        for _,parts in ipairs(eggLogic.definitionPaths) do
            local entry={path="ReplicatedStorage."..table.concat(parts,"."),status="not_started"}
            report.modules[#report.modules+1]=entry
            if not active or shouldContinue and not shouldContinue() then report.status="cancelled";break end
            local module,reason=eggLogic.definitionTarget(storage,parts)
            if not module then entry.status=reason
            elseif type(require)~="function" then entry.status="require_unavailable"
            else
                entry.status="loading"
                local pending={done=false,expired=false}
                eggLogic.definitionPending=pending
                task.spawn(function()
                    local loaded,value=pcall(require,module)
                    if not pending.expired and active and (not shouldContinue or shouldContinue()) then pending.ok=loaded;pending.value=value end
                    pending.done=true
                end)
                local deadline=os.clock()+5
                while active and (not shouldContinue or shouldContinue()) and not pending.done and os.clock()<deadline do task.wait(0.05) end
                if not active or shouldContinue and not shouldContinue() or not pending.done then
                    pending.expired=true;entry.status=active and (not shouldContinue or shouldContinue()) and "timeout" or "cancelled"
                    entry.lateResultIgnored=true;report.status=entry.status
                    -- Do not cancel a game's module initialization or invoke exported functions.
                    break
                end
                eggLogic.definitionPending=nil
                if pending.ok then
                    entry.status="loaded"
                    if parts[1]=="Data" and parts[2]=="Assets" then
                        entry.directory=eggLogic.assetDirectory(pending.value,shouldContinue)
                        entry.snapshot=eggLogic.definitionSnapshot(pending.value,report.categories,{Directory=true,ByRarity=true,Personalities=true})
                    else entry.snapshot=eggLogic.definitionSnapshot(pending.value,report.categories) end
                else entry.status="load_error";entry.error=tostring(pending.value):sub(1,180) end
                pending.value=nil
            end
        end
    end)
    eggLogic.definitionRunning=false;busy=false
    report.loaded=0;report.unavailableOrFailed=0
    for _,entry in ipairs(report.modules) do
        if entry.status=="loaded" then report.loaded=report.loaded+1 else report.unavailableOrFailed=report.unavailableOrFailed+1 end
    end
    if not ok then report.status="error";report.error=tostring(err):sub(1,180)
    elseif shouldContinue and not shouldContinue() then report.status="cancelled"
    elseif report.status=="running" then report.status="finished" end
    report.finishedAt=os.time()
    eggLogic.rebuildRarityIndex()
    return ok and report.status=="finished",report
end
function eggLogic.validRank(value)
    return type(value)=="number" and value==value and value>0 and value<math.huge and value%1==0
end
function eggLogic.rebuildRarityIndex()
    local report=eggLogic.definitions
    local index={report=report,byCategory={},summary={ready=false,categories=0,skipped=0,issues={},
        reason="Collect ON loads Rank data automatically",metric="game Rarity.Rank",tieBreak="distance ascending",at=os.time()}}
    eggLogic.rarityIndex=index
    if not report or report.status~="finished" then return index.summary end
    local directory,rarities
    for _,module in ipairs(report.modules or {}) do
        if module.status=="loaded" and module.path=="ReplicatedStorage.Data.Assets" then directory=module.directory end
        if module.status=="loaded" and module.path=="ReplicatedStorage.Data.Rarity" and module.snapshot and module.snapshot.complete then
            rarities=type(module.snapshot.data)=="table" and module.snapshot.data.Rarities
        end
    end
    index.summary.reason="Complete Directory and Rarity observations required; automatic scan will retry"
    if not directory or not directory.traversalComplete or directory.status~="captured" or type(directory.entries)~="table"
        or directory.exported~=#directory.entries or directory.scanned~=directory.exported
        or directory.totalEntries~=directory.exported or type(rarities)~="table" then return index.summary end
    local counts,ids={},{}
    for _,row in ipairs(directory.entries) do
        if type(row.categoryKey)=="string" then counts[row.categoryKey]=(counts[row.categoryKey] or 0)+1 end
        if type(row._id)=="string" then ids[row._id]=(ids[row._id] or 0)+1 end
    end
    for _,row in ipairs(directory.entries) do
        local key,r=row.categoryKey,row.Rarity
        local canonical=type(r)=="table" and type(r._id)=="string" and rarities[r._id]
        local reason,rarityTextLimited
        for _,issue in ipairs(row.issues or {}) do
            if issue:find("Rarity._id:",1,true)==1 then rarityTextLimited=true end
        end
        if row.keyType~="string" or type(key)~="string" or key=="" or #key>160 or row._id~=key
            or counts[key]~=1 or ids[row._id]~=1 or row.keyTruncated or row.keyIdMismatch or row.duplicateDefinitionId then
            reason="Ambiguous category identity"
        elseif type(r)~="table" or rarityTextLimited or not eggLogic.validRank(r.Rank) then reason="Missing or invalid Rank/rarity identity"
        elseif type(canonical)~="table" or canonical._id~=r._id or not eggLogic.validRank(canonical.Rank)
            or canonical.Rank~=r.Rank then reason="Rarity table missing or Rank conflict"
        else
            -- Ignore unrelated missing income/media fields; never infer actual income from EarningRate.
            index.byCategory[key]={category=key,definitionId=row._id,rarityId=r._id,rank=r.Rank,
                rarityName=canonical.DisplayName or r.DisplayName or r._id,definitionRarityName=r.DisplayName,
                eggName=row.Egg and row.Egg.DisplayName,displayName=row.DisplayName,
                source="ReplicatedStorage.Data.Assets.Directory["..key.."].Rarity.Rank",
                verifiedAgainst="ReplicatedStorage.Data.Rarity.Rarities["..r._id.."].Rank"}
            index.summary.categories=index.summary.categories+1
        end
        if reason then
            index.summary.skipped=index.summary.skipped+1
            if #index.summary.issues<16 then index.summary.issues[#index.summary.issues+1]={category=key,reason=reason} end
        end
    end
    index.summary.ready=index.summary.categories>0
    index.summary.reason=index.summary.ready and "UID-linked categories; unknown ranks skipped" or "No unambiguous category has a verified Rank"
    index.summary.sourceAt=report.finishedAt
    return index.summary
end
function eggLogic.rarityStatus()
    if not eggLogic.rarityIndex or eggLogic.rarityIndex.report~=eggLogic.definitions then eggLogic.rebuildRarityIndex() end
    return eggLogic.rarityIndex.summary
end
function eggLogic.ensureCollectData()
    local state=eggLogic.autoDiscovery or {attempts=0,status="idle",nextReadClock=0}
    eggLogic.autoDiscovery=state
    if eggSelect.mode~="Rarity" then state.status="live_prompts";state.reason=nil;return true end
    if eggLogic.rarityStatus().ready then state.status="ready";state.reason=nil;return true end
    if not active or not collectEgg.enabled then return false end
    if os.clock()<state.nextReadClock then
        collectEgg.last=string.format("Rarity data unavailable; automatic scan retries in %.1fs",state.nextReadClock-os.clock())
        collectEgg.phase="DISCOVERING";return false
    end
    if busy or state.running or hatchRunning or systemRunning or placeRunning then return false end
    local epoch=eggLogic.collectEpoch or 0
    state.running=true;state.status="loading";state.attempts=state.attempts+1;state.startedAt=os.time()
    collectEgg.phase="DISCOVERING";collectEgg.last="Automatically reading game Rank data"
    collectLabel.Text=collectEgg.last
    local worked,ok,result=pcall(eggLogic.inspectDefinitions,function()
        return active and collectEgg.enabled and (eggLogic.collectEpoch or 0)==epoch
    end)
    if not worked then result=ok;ok=false;eggLogic.definitionRunning=false;busy=false end
    state.running=false;state.finishedAt=os.time()
    state.lastResult=type(result)=="table" and result.status or tostring(result)
    if not active or not collectEgg.enabled or (eggLogic.collectEpoch or 0)~=epoch then state.status="cancelled";return false end
    if ok and eggLogic.rarityStatus().ready then
        state.status="ready";state.reason=nil;state.nextReadClock=0;collectEgg.last="Automatic Rank scan ready";return true
    end
    state.status="waiting_retry";state.nextReadClock=os.clock()+15
    state.reason=worked and eggLogic.rarityStatus().reason or tostring(result):sub(1,180)
    collectEgg.last="Rarity data unavailable; automatic scan retries in 15s"
    return false
end
function eggLogic.discoveryStatus()
    local state=eggLogic.autoDiscovery or {}
    return {status=state.status or "idle",running=state.running==true,attempts=state.attempts or 0,
        lastResult=state.lastResult,reason=state.reason,startedAt=state.startedAt,finishedAt=state.finishedAt,
        retryInSeconds=math.max(0,(state.nextReadClock or 0)-os.clock())}
end
function eggLogic.bindRarity(data)
    local status=eggLogic.rarityStatus()
    local binding=data.fieldBinding or {}
    local reason
    if not status.ready then reason=status.reason
    elseif data.conflicts.uid or data.conflicts.assetCategory or not data.uid or binding.uid~=data.uid
        or (binding.method~="explicit_uid" and binding.method~="unique_position") then reason="Fresh unique field UID binding required"
    elseif not data.assetCategory then reason="Field AssetCategory missing"
    else
        local definition=eggLogic.rarityIndex.byCategory[data.assetCategory]
        if not definition then reason="Unknown or conflicting Directory category"
        elseif data.conflicts.rarity or data.rarity and data.rarity~=definition.rarityId
            and data.rarity~=definition.rarityName and data.rarity~=definition.definitionRarityName then
            data.conflicts.rarity=true;reason="Explicit rarity conflicts with Directory"
        else
            data.catalogDefinition=definition
            data.rarityRank=definition.rank
            data.sources.rarityRank=definition.source
            data.rarityBinding={status="verified",uid=data.uid,category=data.assetCategory,method=binding.method,
                verifiedAgainst=definition.verifiedAgainst}
            return
        end
    end
    data.rarityBinding={status="unavailable",reason=reason}
end
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
    eggLogic.observeSource(name,...)
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
    local seen={}
    local backpack = player:FindFirstChildOfClass("Backpack")
    for _, container in pairs({character = player.Character, backpack = backpack}) do
        for i, child in ipairs(container:GetChildren()) do
            if i > 1000 then snapshot.complete = false; break end
            if not seen[child] and child:IsA("Tool") and child:GetAttribute("ItemType") == "AssetEgg" then
                seen[child]=true
                local uid = child:GetAttribute("UID")
                if type(uid) == "string" and #uid<=120 and uid:find("%S") then
                    if snapshot.items[uid] then snapshot.complete=false else snapshot.count = snapshot.count + 1 end
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
function eggLogic.attemptBlock(prompt)
    local state=collectAttempts[prompt]
    if not state then return nil end
    local elapsed=os.clock()-state.time
    if state.count>=3 then
        if elapsed>=30 then collectAttempts[prompt]=nil;return nil end
        return string.format("Attempt limit; retry in %.1fs",30-elapsed)
    end
    if elapsed<4 then return "Cooldown" end
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
    if eggLogic.attemptBlock(prompt) then return nil end
    return distance, position
end
local function inCollectRange(prompt, root)
    local position = prompt.Parent and promptPosition(prompt)
    return position and root and (root.Position-position).Magnitude <= math.min(prompt.MaxActivationDistance,8)
end
function eggLogic.waitForRarityPrompt(choice,root,humanoid,character)
    local prompt=choice.prompt
    local record={uid=choice.meta.uid,at=os.time(),timeoutSeconds=2,status="Waiting for game prompt"}
    collectEgg.promptWait=record
    local deadline=os.clock()+2
    while true do
        if not active or not collectEgg.enabled or busy or player.Character~=character or not root.Parent
            or humanoid.Health<=0 or carryVisible() then
            record.status="Interrupted";collectEgg.last="Rarity prompt wait interrupted";return false
        end
        if not prompt.Parent or not prompt:IsDescendantOf(workspace) or not inCollectRange(prompt,root) then
            record.status="Target removed or out of range";collectEgg.last=record.status;return false
        end
        local latest=eggLogic.metadata(prompt)
        if not eggLogic.accepts(latest) or latest.uid~=choice.meta.uid or latest.assetCategory~=choice.meta.assetCategory
            or latest.rarityRank~=choice.meta.rarityRank then
            record.status="Target identity or Rank changed";collectEgg.last=record.status;return false
        end
        if collectCandidate(prompt,root,humanoid) then record.status="Game prompt ready";return true end
        if prompt.Enabled then
            record.status="Activation checks failed";collectEgg.last=record.status;return false
        end
        if os.clock()>=deadline then
            record.status="Game prompt stayed disabled";record.retryAfterSeconds=8
            eggLogic.deferRarity(choice,record.status)
            collectEgg.phase="SEEKING"
            collectEgg.last="Rarity: prompt stayed disabled; trying another egg (retry in 8s)"
            return false
        end
        collectEgg.phase="WAITING_PROMPT"
        collectEgg.last="Rarity: waiting up to 2s for the game to enable prompt"
        collectLabel.Text=collectEgg.last
        task.wait(0.1)
    end
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
        EggName="name",DisplayName="name",Rarity="rarity",RarityName="rarity",AssetCategory="assetCategory",
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
        data.areaId=record.fields.AreaId
        if #data.raw<6 then data.raw[#data.raw+1]={path=source,values=record.fields,keys=record.keys} end
    end
    for group in pairs(data.conflicts) do data[group]=nil;data.sources[group]=nil end
    eggLogic.bindRarity(data)
    return data
end
function eggLogic.preference(name)
    if not name then return nil end
    for i,wanted in ipairs(eggSelect.preferred) do if name:lower()==wanted:lower() then return i end end
end
function eggLogic.less(a,b)
    if a.accepted~=b.accepted then return a.accepted end
    if eggSelect.mode=="Rarity" and a.meta.rarityRank~=b.meta.rarityRank then
        return (a.meta.rarityRank or -1)>(b.meta.rarityRank or -1)
    elseif eggSelect.mode=="Income" and a.meta.incomePerSecond~=b.meta.incomePerSecond then
        return (a.meta.incomePerSecond or -1)>(b.meta.incomePerSecond or -1)
    elseif eggSelect.mode=="Preferred" and a.priority~=b.priority then
        return (a.priority or math.huge)<(b.priority or math.huge)
    end
    if a.distance~=b.distance then return a.distance<b.distance end
    return (a.meta.uid or a.meta.name or "")<(b.meta.uid or b.meta.name or "")
end
function eggLogic.accepts(meta)
    if eggSelect.mode~="Nearest" and meta.conflicts.uid then return false end
    if eggSelect.mode=="Rarity" then
        return meta.rarityBinding and meta.rarityBinding.status=="verified" and eggLogic.validRank(meta.rarityRank) and not meta.conflicts.rarity
    end
    if eggSelect.mode=="Income" then return meta.incomePerSecond~=nil end
    if eggSelect.mode=="Preferred" then return eggLogic.preference(meta.name)~=nil end
    return true
end
function eggLogic.rarityDeferred(meta)
    local deferrals=eggLogic.rarityDeferrals
    local entry=deferrals and meta.uid and deferrals[meta.uid]
    if not entry then return nil end
    if os.clock()>=entry.untilClock or meta.assetCategory~=entry.category or meta.rarityRank~=entry.rank then
        deferrals[meta.uid]=nil;return nil
    end
    return entry.reason..string.format("; retry in %.1fs",entry.untilClock-os.clock())
end
function eggLogic.deferRarity(choice,reason)
    local meta=choice.meta
    if not meta.uid then return end
    local deferrals=eggLogic.rarityDeferrals or {}
    eggLogic.rarityDeferrals=deferrals
    local count,oldest,oldestTime=0,nil,math.huge
    for uid,entry in pairs(deferrals) do
        if entry.untilClock<=os.clock() then deferrals[uid]=nil
        else
            count=count+1
            if entry.untilClock<oldestTime then oldest,oldestTime=uid,entry.untilClock end
        end
    end
    if not deferrals[meta.uid] and count>=64 then deferrals[oldest]=nil end
    deferrals[meta.uid]={category=meta.assetCategory,rank=meta.rarityRank,reason=reason,untilClock=os.clock()+8}
end
function eggLogic.choices(root,humanoid,readyOnly)
    local choices={}
    for prompt in pairs(promptCache) do
        local distance,position
        if readyOnly then
            distance=collectCandidate(prompt,root,humanoid);position=distance and promptPosition(prompt)
            if eggLogic.attemptBlock(prompt) then distance=nil end
        else distance,position=approachCandidate(prompt,root,humanoid) end
        if distance then
            local meta=eggLogic.metadata(prompt)
            local blocked=eggSelect.mode=="Rarity" and eggLogic.rarityDeferred(meta) or nil
            choices[#choices+1]={prompt=prompt,distance=distance,position=position,meta=meta,
                priority=eggLogic.preference(meta.name),accepted=not blocked and eggLogic.accepts(meta),blockedReason=blocked}
        end
    end
    table.sort(choices,eggLogic.less)
    return choices
end
eggLogic.toolRefs=setmetatable({}, {__mode="k"})
eggLogic.nextToolRef=0
function eggLogic.toolRef(tool)
    if not eggLogic.toolRefs[tool] then
        eggLogic.nextToolRef=eggLogic.nextToolRef+1
        eggLogic.toolRefs[tool]="tool_"..eggLogic.nextToolRef
    end
    return eggLogic.toolRefs[tool]
end
function eggLogic.toolMetadata(tool)
    local data={sources={},raw={},conflicts={},complete=true,configurationCount=0,uidEvidence={},attributeKeys={}}
    local groups={UID="uid",Uid="uid",uid="uid",EggUID="uid",EggUid="uid",FieldEggUid="uid",
        perSecond="incomePerSecond",IncomePerSecond="incomePerSecond",CashPerSecond="incomePerSecond",
        MoneyPerSecond="incomePerSecond",CoinsPerSecond="incomePerSecond",perSecondDisplay="incomeDisplay",
        rarity="rarity",Rarity="rarity",RarityName="rarity",OwnerUserId="ownerUserId"}
    local function observe(key,value,path)
        local group=groups[key]
        if group=="uid" then
            data.uidEvidence[#data.uidEvidence+1]={key=key,source=path,value=eggLogic.sourceScalar(value)}
            if type(value)~="string" or #value>120 or not value:find("%S") then data.conflicts.uid=true;return end
            value=value:match("^%s*(.-)%s*$")
        elseif group=="incomePerSecond" or group=="incomeDisplay" or group=="ownerUserId" then
            value=tonumber(value)
            if not value or value~=value or value<0 or value==math.huge then data.conflicts[group]=true;return end
        elseif type(value)~="string" or #value>120 or not value:find("%S") then return end
        if data[group]~=nil and data[group]~=value then data.conflicts[group]=true end
        data[group]=value;data.sources[group]=path
    end
    local function children(obj)
        local ok,list=pcall(function() return obj:GetChildren() end)
        if not ok then data.complete=false;return {} end
        if #list>64 then data.complete=false end
        return list
    end
    local function read(obj,list)
        local path=obj:GetFullName()
        local raw={path=path,values={}}
        local ok,attrs=pcall(function() return obj:GetAttributes() end)
        if not ok then data.complete=false;attrs={} end
        -- Identity/rates are read before the bounded cosmetic key listing.
        for key in pairs(groups) do
            if attrs[key]~=nil then
                raw.values[key]=eggLogic.sourceScalar(attrs[key])
                observe(key,attrs[key],path.." attribute "..key)
            end
        end
        local keys,count={},0
        for key,value in pairs(attrs) do
            count=count+1
            if count>64 then data.attributeKeysTruncated=true;break end
            keys[#keys+1]=key:sub(1,80)
            if key:lower():find("uid",1,true) and not groups[key] then raw.values[key]=eggLogic.sourceScalar(value) end
        end
        table.sort(keys);data.attributeKeys[#data.attributeKeys+1]={path=path,keys=keys}
        for i,child in ipairs(list) do
            if i>64 then break end
            if groups[child.Name] and (child:IsA("StringValue") or child:IsA("NumberValue") or child:IsA("IntValue")) then
                raw.values[child.Name..".Value"]=eggLogic.sourceScalar(child.Value)
                observe(child.Name,child.Value,child:GetFullName().." Value")
            end
        end
        data.raw[#data.raw+1]=raw
    end
    local list=children(tool)
    read(tool,list)
    for i,child in ipairs(list) do
        if i>64 then break end
        if child.Name=="Configuration" then
            data.configurationCount=data.configurationCount+1
            if child:IsA("Configuration") and data.configurationCount<=2 then read(child,children(child))
            else data.complete=false end
        end
    end
    if data.configurationCount>1 then data.configurationAmbiguous=true end
    for group in pairs(data.conflicts) do data[group]=nil;data.sources[group]=nil end
    -- Display income is kept separately, never used as a fallback rate.
    return data
end
function eggLogic.toolCatalog()
    local result={at=os.time(),entries={},roots={},total=0,uidLinked=0,knownIncome=0,eligibleIncome=0,missingUid=0,
        duplicateUid=0,scanComplete=true,metadataIncomplete=0,scope="local_inventory_tool_observations",serverOwnershipVerified=false}
    local all,seen,counts={},{},{}
    local containers={{name="Backpack",object=player:FindFirstChildOfClass("Backpack")},{name="Character",object=player.Character}}
    for _,container in ipairs(containers) do
        local report={name=container.name,found=container.object~=nil,complete=true,visited=0}
        result.roots[#result.roots+1]=report
        if container.object then
            local ok,list=pcall(function() return container.object:GetChildren() end)
            if not ok then report.complete=false;result.scanComplete=false;list={} end
            for i,tool in ipairs(list) do
                if i>1000 or #all>=256 then report.complete=false;result.scanComplete=false;break end
                report.visited=i
                if tool:IsA("Tool") and not seen[tool] then
                    seen[tool]=true
                    local good,meta=pcall(eggLogic.toolMetadata,tool)
                    if not good then meta={sources={},raw={},conflicts={},complete=false,error=tostring(meta):sub(1,120)} end
                    local itemType=tool:GetAttribute("ItemType")
                    local entry={ref=eggLogic.toolRef(tool),name=tool.Name,path=tool:GetFullName(),container=container.name,
                        itemType=eggLogic.sourceScalar(itemType),kind=itemType=="AssetEgg" and "asset_egg_tool" or "other_inventory_tool",metadata=meta}
                    if tool.Parent~=container.object then meta.complete=false;entry.containmentChanged=true end
                    all[#all+1]=entry
                    local identities={}
                    for _,evidence in ipairs(meta.uidEvidence or {}) do
                        local value=evidence.value
                        if type(value)=="string" and #value<=120 and value:find("%S") then
                            identities[value:match("^%s*(.-)%s*$")]=true
                        end
                    end
                    for uid in pairs(identities) do counts[uid]=(counts[uid] or 0)+1 end
                end
            end
        end
    end
    result.total=#all
    for _,entry in ipairs(all) do
        local meta=entry.metadata
        local reason=not meta.complete and "incomplete_tool_read" or meta.configurationAmbiguous and "multiple_configurations"
            or meta.conflicts.uid and "conflicting_or_invalid_uid" or not meta.uid and "missing_uid"
            or counts[meta.uid]>1 and "duplicate_uid" or not result.scanComplete and "incomplete_inventory_scan"
            or meta.conflicts.ownerUserId and "conflicting_owner" or meta.ownerUserId and meta.ownerUserId~=player.UserId and "foreign_owner"
            or "unique_observed_uid"
        entry.uidBinding={status=reason,linked=reason=="unique_observed_uid",scope="same_tool_in_local_inventory",
            serverOwnershipVerified=false}
        entry.eligibleForIncome=entry.uidBinding.linked and meta.incomePerSecond~=nil
        if not meta.complete then result.metadataIncomplete=result.metadataIncomplete+1 end
        if not meta.uid then result.missingUid=result.missingUid+1 end
        if meta.uid and counts[meta.uid]>1 then result.duplicateUid=result.duplicateUid+1 end
        if entry.uidBinding.linked then result.uidLinked=result.uidLinked+1 end
        if meta.incomePerSecond~=nil then result.knownIncome=result.knownIncome+1 end
        if entry.eligibleForIncome then result.eligibleIncome=result.eligibleIncome+1 end
    end
    table.sort(all,function(a,b)
        if a.eligibleForIncome~=b.eligibleForIncome then return a.eligibleForIncome end
        local av,bv=a.metadata.incomePerSecond or -1,b.metadata.incomePerSecond or -1
        if av~=bv then return av>bv end
        if a.name~=b.name then return a.name<b.name end
        return a.ref<b.ref
    end)
    for i=1,math.min(#all,40) do result.entries[i]=all[i] end
    result.truncated=#all>40
    result.complete=result.scanComplete and result.metadataIncomplete==0 and not result.truncated
    return result
end
function eggLogic.refresh()
    local character=player.Character
    local root=character and character:FindFirstChild("HumanoidRootPart")
    local humanoid=character and character:FindFirstChildOfClass("Humanoid")
    local choices=eggLogic.choices(root,humanoid,false)
    local catalog={at=os.time(),mode=eggSelect.mode,entries={},inventory={},total=#choices,knownIncome=0,knownRarity=0,fieldLinked=0,accepted=0,deferred=0,
        rarityRanking=eggLogic.rarityStatus(),rarityRankingApplied=false,
        fieldData={stored=eggLogic.field.count,lastEvent=eggLogic.field.lastEvent,lastAt=eggLogic.field.lastAt,
            missingUid=eggLogic.field.missingUid,evicted=eggLogic.field.evicted}}
    catalog.fieldData.fresh=0
    for _,record in pairs(eggLogic.field.records) do
        if os.clock()-record.clock<=120 then catalog.fieldData.fresh=catalog.fieldData.fresh+1 end
    end
    for i,choice in ipairs(choices) do
        if choice.meta.incomePerSecond~=nil then catalog.knownIncome=catalog.knownIncome+1 end
        if choice.meta.rarityRank~=nil then catalog.knownRarity=catalog.knownRarity+1 end
        if choice.meta.fieldBinding and choice.meta.fieldBinding.uid and choice.meta.fieldBinding.method~="ambiguous_prompts" then catalog.fieldLinked=catalog.fieldLinked+1 end
        if choice.accepted then catalog.accepted=catalog.accepted+1 end
        if choice.blockedReason then catalog.deferred=catalog.deferred+1 end
        if i<=12 then catalog.entries[i]={path=choice.prompt:GetFullName(),distance=choice.distance,
            position={x=choice.position.X,y=choice.position.Y,z=choice.position.Z},
            enabled=choice.prompt.Enabled,eligibleForMode=choice.accepted,priority=choice.priority,blockedReason=choice.blockedReason,metadata=choice.meta} end
    end
    catalog.truncated=#choices>12
    catalog.rarityRankingApplied=eggSelect.mode=="Rarity" and catalog.knownRarity>0
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
    catalog.tools=eggLogic.toolCatalog()
    eggSelect.catalog=catalog
    return choices
end
function eggLogic.export()
    eggLogic.refresh()
    return {version="1.54",kind="egg_data",placeId=game.PlaceId,
        collection={enabled=collectEgg.enabled,phase=collectEgg.phase,last=collectEgg.last,attempts=collectEgg.attempts,
            retry=eggLogic.retryStatus(),promptWait=collectEgg.promptWait,lastMovement=collectEgg.lastMovement,lastInput=collectEgg.lastInput},
        eggSelection={mode=eggSelect.mode,preferred=eggSelect.preferred,catalog=eggSelect.catalog,
            selected=collectEgg.selectedEgg,fieldSamples=eggSelect.fieldSamples,sourceDiscovery=eggLogic.sources,sourceEvents=eggLogic.sourceEvents,
            automaticDiscovery=eggLogic.discoveryStatus(),definitionDiscovery=eggLogic.definitions}}
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
        or #choices==0 and eggSelect.mode~="Nearest" and "No egg has readable data matching the selected mode; see Collect status"
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
local function retryCollect(reason,kind,seconds)
    cancelCollectTween(reason)
    if not active or not collectEgg.enabled then return end
    seconds=seconds or 5
    collectEgg.retry={reason=reason,kind=kind or "state",at=os.time(),untilClock=os.clock()+seconds,delaySeconds=seconds}
    collectEgg.pausedReason=nil
    collectEgg.last=reason..string.format("; retry in %ds",seconds)
    collectEgg.phase="WAITING_RETRY"
    if collectButton then collectButton.Text="Collect: ON";collectButton.BackgroundColor3=colors.purple end
    collectLabel.Text=collectEgg.last
end
function eggLogic.retryStatus()
    local retry=collectEgg.retry
    if not retry then return nil end
    return {reason=retry.reason,kind=retry.kind,at=retry.at,delaySeconds=retry.delaySeconds,
        remainingSeconds=math.max(0,retry.untilClock-os.clock())}
end
local ownerKeys={"OwnerUserId","OwnerId","Owner","UserId","PlayerUserId","Player","Username","OwnerName"}
local function signEvidence(plot)
    local result={texts={},attributes={},usernameMatch=false,truncated=false,foreignOwner=false}
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
                if value~="" and value~=0 and value~=player.UserId and value~=tostring(player.UserId) and value~=player.Name then result.foreignOwner=true end
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
    local explicitOwner,matched,conflict=false,nil,false
    local function observe(value,evidence)
        if value==nil or value=="" or value==0 or value==false then return end
        explicitOwner=true
        if matches(value) then matched=matched or evidence else conflict=true end
    end
    for _,child in ipairs(plot:GetChildren()) do
        if child.Name=="Owner" or child.Name=="OwnerUserId" or child.Name=="OwnerId" then
            if child:IsA("ObjectValue") or child:IsA("StringValue") or child:IsA("IntValue") or child:IsA("NumberValue") then
                observe(child.Value,"value:"..child.Name)
            end
        end
        if child.Name=="Info" or child.Name=="Config" or child.Name=="Settings" then nodes[#nodes+1]=child end
    end
    for _,node in ipairs(nodes) do
        for _,key in ipairs(ownerKeys) do
            local value=node:GetAttribute(key)
            observe(value,"attribute:"..key)
        end
    end
    if conflict then return false,"Conflicting/foreign ownership evidence" end
    if matched then return true,matched end
    if not explicitOwner then
        local sign=signEvidence(plot)
        if sign.usernameMatch and not sign.foreignOwner and not sign.truncated then return true,"PlotSign exact username" end
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
    if not deliveryPoint then retryCollect("Holding field egg: set your delivery point in Settings; "..autoHome.reason); return end
    if not root or not humanoid or humanoid.Health <= 0 then retryCollect("Character unavailable during return"); return end
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
    if delta.Magnitude > 600 then retryCollect("Delivery point beyond 600 studs"); record.status=collectEgg.last; return end
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
            if active and collectEgg.enabled then retryCollect(reason) end
            return
        end
    end
    collectEgg.phase = "DELIVERING"
    collectLabel.Text = "At delivery point; waiting for game result"
    local before = collectEgg.tripInventory
    local deadline = os.clock()+5
    local clearSince
    while active and collectEgg.enabled and player.Character == character and humanoid.Health > 0 and os.clock()<deadline do
        if (root.Position-deliveryPoint).Magnitude > 6 then retryCollect("Moved away from delivery point"); record.status=collectEgg.last; return end
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
                retryCollect(record.status)
            end
            return
        end
        task.wait(0.1)
    end
    record.status="Home reached but game did not accept the egg"
    if active and collectEgg.enabled then retryCollect(record.status .. "; check delivery point") end
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
        last = collectEgg.last, lastInput = collectEgg.lastInput, promptWait=collectEgg.promptWait, scanning = busy,
        unconfirmed = collectEgg.unconfirmed or 0, retry=eggLogic.retryStatus(),
        inventoryAdditionsObserved = collectEgg.inventoryAdditionsObserved or 0,
        phase = collectEgg.phase or "IDLE", deliveriesObserved = collectEgg.deliveriesObserved or 0,
        gameEvents = gameEvents, eventObserver = eventObserver,
        upgrades=upgrades,training=training,placementRecording=placementRecord,
        selectionBlocked=eggSelect.mode~="Nearest" and eggSelect.catalog.accepted==0 and ("No readable egg matches "..eggSelect.mode.."; see Collect status") or nil,
        eggSelection={mode=eggSelect.mode,preferred=eggSelect.preferred,catalog=eggSelect.catalog,selected=collectEgg.selectedEgg,fieldSamples=eggSelect.fieldSamples,sourceDiscovery=eggLogic.sources,sourceEvents=eggLogic.sourceEvents,automaticDiscovery=eggLogic.discoveryStatus(),definitionDiscovery=eggLogic.definitions},
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
                local blocked=eggLogic.attemptBlock(prompt)
                local state=collectAttempts[prompt]
                if snapshot.carrying then reason = "Egg held/equipped; checking delivery"
                elseif busy then reason = "Scan in progress"
                elseif blocked then reason = blocked end
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
    local retry=collectEgg.retry
    if retry then
        local lateAdded=retry.kind=="pickup" and retry.inventoryBefore and retry.character==player.Character
            and newInventoryEggs(retry.inventoryBefore,eggInventory()) or {}
        if retry.kind=="pickup" and fieldCarryActive() and retry.character==player.Character then
            collectEgg.tripInventory=retry.inventoryBefore;collectEgg.unconfirmed=0;collectEgg.retry=nil
            if collectEgg.lastInput then collectEgg.lastInput.lateOutcome="Field carrying observed during retry wait" end
        elseif #lateAdded>0 then
            collectEgg.inventoryAdditionsObserved=(collectEgg.inventoryAdditionsObserved or 0)+#lateAdded
            collectEgg.unconfirmed=0;collectEgg.retry=nil
            if collectEgg.lastInput then collectEgg.lastInput.lateInventoryAdded=lateAdded end
        elseif os.clock()<retry.untilClock then
            collectEgg.phase="WAITING_RETRY"
            collectEgg.last=retry.reason..string.format("; retry in %.1fs",retry.untilClock-os.clock())
            return
        else collectEgg.retry=nil;collectEgg.phase="SEEKING" end
    end
    local carrying = carryState()
    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if carrying.manualMarker then collectEgg.last="User carrying marker active"; return end
    if carrying.fieldCarrying then returnHome(root,humanoid,character); return end
    if carrying.equippedEgg then collectEgg.last="Inventory egg equipped; unequip to collect field eggs"; return end
    if not eggLogic.ensureCollectData() then return end
    if not active or not collectEgg.enabled or player.Character~=character then return end
    if autoHome.enabled and not deliveryPoint then
        refreshAutoHome(true)
        if not deliveryPoint then retryCollect("Auto home not ready: "..autoHome.reason);return end
    end
    collectEgg.phase="SEEKING"
    local all=eggLogic.refresh()
    local best,bestDistance,selected
    local deferredAtSelection={}
    if eggSelect.mode=="Nearest" then
        local ready=eggLogic.choices(root,humanoid,true)
        selected=ready[1]
        if not selected and approachEgg(root,humanoid) and active and collectEgg.enabled and not busy and not carryVisible() then
            selected=eggLogic.choices(root,humanoid,true)[1]
        end
    else
        selected=all[1]
        if eggSelect.mode=="Rarity" then
            for _,choice in ipairs(all) do
                if choice.blockedReason and choice.meta.uid then deferredAtSelection[choice.meta.uid]=true end
            end
        end
        if not selected or not selected.accepted then
            collectEgg.last=eggSelect.mode=="Rarity" and (eggSelect.catalog.deferred or 0)>0
                and "Rarity: game prompts temporarily unavailable; waiting to retry"
                or eggSelect.mode=="Rarity" and eggSelect.catalog.fieldData.fresh==0
                and "Rank data ready; waiting for live egg updates automatically"
                or "No egg has readable data matching "..eggSelect.mode.."; see Collect status"
            return
        end
        if not collectCandidate(selected.prompt,root,humanoid) then
            local reached=approachEgg(root,humanoid,selected.prompt)
            if eggSelect.mode=="Rarity" and inCollectRange(selected.prompt,root) then
                if not eggLogic.waitForRarityPrompt(selected,root,humanoid,character) then return end
            elseif not reached then return end
        end
    end
    if not selected or not active or not collectEgg.enabled or busy or carryVisible() or player.Character~=character then return end
    best=selected.prompt;bestDistance=collectCandidate(best,root,humanoid)
    local latest=eggLogic.metadata(best)
    if eggSelect.mode=="Rarity" then
        local current
        for _,choice in ipairs(eggLogic.choices(root,humanoid,false)) do
            -- A retry timer expiring during travel must not revive a known disabled target and starve this trip.
            if choice.accepted and (not deferredAtSelection[choice.meta.uid] or choice.prompt.Enabled) then current=choice;break end
        end
        if not current or not current.accepted or not eggLogic.accepts(latest) or latest.uid~=selected.meta.uid
            or latest.assetCategory~=selected.meta.assetCategory or latest.rarityRank~=selected.meta.rarityRank
            or current.meta.rarityRank>latest.rarityRank then
            collectEgg.last="Rarity target changed; reselecting next cycle";return
        end
    end
    if eggLogic.attemptBlock(best) then return end
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
        if eggSelect.mode=="Rarity" then eggLogic.deferRarity(selected,"Pickup not confirmed") end
        retryCollect(ok and "Pickup not confirmed; checking carry state before retry"
            or ("Pickup input failed: "..tostring(record.error)),"pickup",5)
        if collectEgg.retry then collectEgg.retry.inventoryBefore=inventoryBefore;collectEgg.retry.character=character end
    end
    recordGameEvent("collect.input.outcome",record.outcome)
    if active and not collectEgg.retry then collectEgg.last = record.outcome end
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
    if not ok and active then
        if holding then pcall(function() holding:InputHoldEnd() end);holding=nil end
        retryCollect("Collect error: " .. tostring(err):sub(1,100))
    end
end
local function setManualCarry(value)
    manualCarry = value == true
    if manualCarry then
        cancelCollectTween("User marked carrying")
        collectEgg.enabled = false
        collectEgg.retry=nil
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
        or "No clear PetArea candidates or explicit empty slots"
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
    collectEgg.retry=nil
    collectEgg.phase="IDLE"
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
    placementRecord.last=record.worldEggAppearanceVerified and "Matching egg UID observed in base. World evidence recorded."
        or record.inventoryUIDRemoved and "UID left inventory; world egg not matched. World candidates recorded."
        or "Placement unconfirmed by inventory; Recording retained internally."
    placementRecord.enabled=false;recordingContext=nil
end
local function parseSoftCost(text)
    local amount,suffix=string.upper(text:gsub("<[^>]*>",""):gsub(",","")):match("^%s*%$%s*([%d%.]+)%s*([KMBT]?)%s*$")
    local number=tonumber(amount)
    if not number or number~=number or number<0 or number==math.huge then return nil end
    local price=number*(({K=1000,M=1000000,B=1000000000,T=1000000000000})[suffix] or 1)
    return price<math.huge and price or nil
end
local function readCash()
    local found
    local function add(value)
        if type(value)~="number" then return true end
        if value~=value or value<0 or value==math.huge then return false end
        if found and value~=found then return false end
        found=value;return true
    end
    local stats=player:FindFirstChild("leaderstats")
    for _,name in ipairs({"Cash","Money","Coins"}) do
        if not add(player:GetAttribute(name)) then return nil,"Conflicting or invalid currency values" end
        local value=stats and stats:FindFirstChild(name)
        if value and (value:IsA("IntValue") or value:IsA("NumberValue")) and not add(value.Value) then return nil,"Conflicting or invalid currency values" end
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
    if not latest or not balance or latest.level~=info.level or latest.price~=info.price or latest.price>balance or latest.button~=info.button then upgrades.last="Upgrade state changed; rechecking next cycle";return end
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
priorityButton.Activated:Connect(function()
    if collectEgg.enabled or collectRunning or busy or placeState.manualPreparing or placementRecord.enabled then
        status.Text="Stop Collect before changing priority";return
    end
    eggSelect.mode=eggSelect.mode=="Rarity" and "Nearest" or "Rarity"
    priorityButton.Text="Priority: "..string.upper(eggSelect.mode)
    status.Text="Collect ON scans eggs automatically ("..eggSelect.mode..")"
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
approachButton.Activated:Connect(function()
    if collectRunning then status.Text="Stop Collect before changing movement mode";return end
    collectEgg.approachMode=collectEgg.approachMode=="Tween" and "Walk" or "Tween"
    approachButton.Text="Approach: "..string.upper(collectEgg.approachMode)
end)
-- Read-only event observations. Payloads are bounded and are not interpreted as
-- authoritative carry state until the event contract is established.
local watchedEvents = {
    ["RE/EggWorld/FieldEggRaritiesShown"]=true,
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
    collectEgg.phase="IDLE"
    collectEgg.retry=nil
    collectButton.Text="Collect: OFF"
    setManualCarry(false)
    carryMarker.Text = "Mark: I am carrying an egg"
end)
collectButton.Activated:Connect(function()
    if placeState.manualPreparing or placementRecord.enabled then status.Text="Stop Record placement before starting other actions";return end
    collectEgg.enabled = not collectEgg.enabled
    eggLogic.collectEpoch=(eggLogic.collectEpoch or 0)+1
    if collectEgg.enabled and eggLogic.autoDiscovery then eggLogic.autoDiscovery.nextReadClock=0 end
    if collectEgg.enabled then eggLogic.rarityDeferrals=nil;collectEgg.promptWait=nil end
    collectEgg.phase=collectEgg.enabled and "SEEKING" or "IDLE"
    collectAttempts = setmetatable({}, {__mode = "k"})
    collectEgg.unconfirmed, collectEgg.pausedReason = 0, nil
    collectEgg.retry=nil
    collectButton.Text = collectEgg.enabled and "Collect: ON" or "Collect: OFF"
    collectButton.BackgroundColor3 = collectEgg.enabled and colors.purple or colors.panel
    collectEgg.last = collectEgg.enabled and "Waiting for nearby egg" or "OFF"
    collectLabel.Text = collectEgg.last
    status.Text=collectEgg.enabled and "Collect ON: detecting eggs automatically" or "Collect OFF"
    if not collectEgg.enabled then cancelCollectTween("Collect OFF") end
    if not collectEgg.enabled and collectRunning and holding then
        pcall(function() holding:InputHoldEnd() end); holding = nil
    end
end)
-- Seed existing prompts for automatic collection. Subsequent
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
        dispatchCollect()
        dispatchHatch(false)
        dispatchSystems()
        if active and collectEgg.enabled then
            local ok, snapshot = pcall(collectSnapshot)
            if ok then
                local catalog=snapshot.eggSelection.catalog
                collectLabel.Text=collectEgg.last..string.format("\n%s | eggs %d / linked %d / ranked %d | input attempts %d",
                    eggSelect.mode,catalog.total or 0,catalog.fieldLinked or 0,catalog.knownRarity or 0,collectEgg.attempts)
                status.Text="Collect ON ("..eggSelect.mode.."): "..collectEgg.last
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
close.Activated:Connect(function() stopHatch();lifetime:Disconnect();gui:Destroy() end)
