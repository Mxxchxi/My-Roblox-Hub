-- My Anime Mine isolated startup and lifecycle smoke test (Lua 5.4).
-- Roblox is not launched: worker loops are intentionally not advanced.
local f = assert(io.open("Games/MyAnimeMine.lua", "r"))
local source = f:read("*a")
f:close()

local function signal()
    local s = {listeners = {}}
    function s:Connect(callback)
        local c = {callback = callback, Connected = true}
        function c:Disconnect() self.Connected = false end
        table.insert(self.listeners, c)
        return c
    end
    function s:Fire(...)
        for _, c in ipairs(self.listeners) do
            if c.Connected then c.callback(...) end
        end
    end
    return s
end

local function instance(className)
    local props = {ClassName = className, Name = className, Visible = true, Enabled = true, children = {}, events = {}}
    local obj = {}
    local methods = {}
    function methods:IsA(kind)
        if kind == props.ClassName then return true end
        if kind == "GuiObject" then
            return props.ClassName == "Frame" or props.ClassName == "TextButton"
                or props.ClassName == "ImageButton" or props.ClassName == "TextLabel"
                or props.ClassName == "ImageLabel"
        end
        return false
    end
    function methods:GetChildren()
        local list = {}
        for _, value in ipairs(props.children) do list[#list + 1] = value end
        return list
    end
    function methods:GetDescendants()
        local list = {}
        local function visit(parent)
            for _, child in ipairs(parent:GetChildren()) do
                list[#list + 1] = child
                visit(child)
            end
        end
        visit(self)
        return list
    end
    function methods:FindFirstChild(name)
        for _, child in ipairs(props.children) do
            if child.Name == name then return child end
        end
        return nil
    end
    function methods:WaitForChild(name) return self:FindFirstChild(name) end
    function methods:FindFirstChildOfClass(name)
        for _, child in ipairs(props.children) do
            if child:IsA(name) then return child end
        end
        return nil
    end
    function methods:IsDescendantOf(parent)
        local current = self.Parent
        while current do
            if current == parent then return true end
            current = current.Parent
        end
        return false
    end
    function methods:Destroy()
        for _, child in ipairs(self:GetChildren()) do child:Destroy() end
        self.Parent = nil
    end
    setmetatable(obj, {
        __index = function(_, key)
            if methods[key] then return methods[key] end
            if key == "Activated" or key == "MouseButton1Click" or key == "InputBegan" or key == "InputChanged" or key == "InputEnded" then
                props.events[key] = props.events[key] or signal()
                return props.events[key]
            end
            return props[key]
        end,
        __newindex = function(_, key, value)
            if key == "Parent" then
                if props.Parent then
                    for i, child in ipairs(props.Parent.children) do
                        if child == obj then table.remove(props.Parent.children, i) break end
                    end
                end
                props.Parent = value
                if value then value.children[#value.children + 1] = obj end
            else
                props[key] = value
            end
        end,
    })
    return obj
end

local playerGui = instance("PlayerGui")
playerGui.Name = "PlayerGui"
local player = instance("Player")
player.Name = "TestPlayer"
playerGui.Parent = player
local workspace = instance("Workspace")
local replicatedStorage = instance("ReplicatedStorage")
local input = instance("UserInputService")
local services = {
    Players = {LocalPlayer = player},
    ReplicatedStorage = replicatedStorage,
    UserInputService = input,
}
local roblox = {
    PlaceId = 79389059854988,
    IsLoaded = function() return true end,
    GetService = function(_, name) return assert(services[name], name) end,
}
local clipboard
-- Simulate the game Chest UI: unlabeled TextButton with a nested "Take All" label.
local gameChestGui = instance("ScreenGui")
gameChestGui.Name = "ChestUI"
gameChestGui.Parent = playerGui
local chestFrame = instance("Frame")
chestFrame.Name = "ChestFrame"
chestFrame.Parent = gameChestGui
local contentFrame = instance("Frame")
contentFrame.Name = "Content"
contentFrame.Parent = chestFrame
local takeAllButton = instance("TextButton")
takeAllButton.Name = "ClaimContents"
takeAllButton.Text = ""
takeAllButton.Visible = true
takeAllButton.Parent = contentFrame
local takeAllLabel = instance("TextLabel")
takeAllLabel.Name = "Caption"
takeAllLabel.Text = "Take All"
takeAllLabel.Parent = takeAllButton
local chestCountLabel = instance("TextLabel")
chestCountLabel.Name = "Label"
chestCountLabel.Text = "15/183.9K Items"
chestCountLabel.Parent = contentFrame
local firedTakeAll = 0
local mouseClickHandled = 0
takeAllButton.MouseButton1Click:Connect(function() mouseClickHandled = mouseClickHandled + 1 end)
local env = setmetatable({
    game = roblox,
    workspace = workspace,
    Instance = {new = instance},
    task = {spawn = function() end, wait = function() end},
    Enum = setmetatable({}, {
        __index = function(_, category)
            return setmetatable({}, {__index = function(_, value) return category .. "." .. value end})
        end,
    }),
    Color3 = {fromRGB = function(...) return {...} end},
    UDim = {new = function(...) return {...} end},
    UDim2 = {
        fromOffset = function(...) return {...} end,
        new = function(...) return {X = {Scale = 0, Offset = 0}, Y = {Scale = 0, Offset = 0}} end,
    },
    fireclickdetector = function() end,
    fireproximityprompt = function() end,
    setclipboard = function(value) clipboard = value end,
    firesignal = function(signalValue) firedTakeAll = firedTakeAll + 1; signalValue:Fire() end,
    getconnections = function(signalValue) return signalValue.listeners end,
    print = function() end,
    warn = function() end,
}, {__index = _G})
env._G = env
env.getgenv = function() return env end

local function run()
    local testSource = source .. "\nreturn {chestSnapshot=chestSnapshot, chestItemCount=chestItemCount, chooseTakeAllEvent=chooseTakeAllEvent, settleTakeAll=settleTakeAll, observeReopenedChest=observeReopenedChest, monitorManualButton=monitorManualButton, settleManualTakeAll=settleManualTakeAll, scanActionButtons=scanActionButtons, isUpgradeAction=isUpgradeAction, statContext=statContext, actionDiagnosticReport=actionDiagnosticReport, dispatchGameButton=dispatchGameButton, resolveUpgradeFeedback=resolveUpgradeFeedback, nextHolderDetector=nextHolderDetector, holderTargets=holderTargets, approachUpgradeHolder=approachUpgradeHolder, stopUpgradeWalking=stopUpgradeWalking, hiddenEquipBestCandidates=hiddenEquipBestCandidates, headlessRemotes=headlessRemotes, tryHeadlessEquip=tryHeadlessEquip, scanNativeAutoSell=scanNativeAutoSell, nativeAutoSellState=nativeAutoSellState, setNativeAutoSell=setNativeAutoSell, tryNativeAutoSell=tryNativeAutoSell, shopsTeleportLauncher=shopsTeleportLauncher, shopsWarpDestination=shopsWarpDestination, sellVendorTargets=sellVendorTargets, oreSellButton=oreSellButton, shopSellStep=shopSellStep, sellStopWalk=sellStopWalk}"
    local helpers = assert(load(testSource, "@Games/MyAnimeMine.lua", "t", env))()
    return assert(env.MyAnimeMineHubController), helpers
end
local function findButton(name)
    for _, child in ipairs(playerGui:GetDescendants()) do
        if child.ClassName == "TextButton" and child.Name == name then return child end
    end
    error("Button not found: " .. name)
end

local function vector(x,y,z)
    return setmetatable({X=x,Y=y,Z=z}, {
        __sub = function(a,b)
            local dx,dy,dz=a.X-b.X,a.Y-b.Y,a.Z-b.Z
            return {Magnitude=math.sqrt(dx*dx+dy*dy+dz*dz)}
        end,
        __tostring=function(a) return ("%.1f, %.1f, %.1f"):format(a.X,a.Y,a.Z) end,
    })
end
local function createPlot(name, chestX, withUpgrade)
    local plot=instance("Folder");plot.Name=name;plot.Parent=workspace
    local chest=instance("Folder");chest.Name="Chest";chest.Parent=plot
    local base=instance("BasePart");base.Name="ChestBase";base.Position=vector(chestX,0,0);base.Parent=chest
    local prompt=instance("ProximityPrompt");prompt.Name="ChestPrompt"
    prompt.ActionText="Open";prompt.MaxActivationDistance=10;prompt.Enabled=true;prompt.Parent=base
    if withUpgrade then
        local upgrade=instance("BasePart");upgrade.Name="UpgradePart"
        upgrade.Position=vector(23,0,0);upgrade.Parent=plot
        local det=instance("ClickDetector");det.Name="UpgradeClick";det.MaxActivationDistance=32;det.Parent=upgrade
    end
end

local first, helpers = run()
assert(playerGui:FindFirstChild("MyAnimeMineHub"), "UI was not mounted")
assert(not first.mine and not first.collect, "auto toggles must start OFF")
assert(#first.detectors == 0 and #first.prompts == 0, "unexpected scan targets")
assert(#first.takeAllButtons == 1, "did not discover Chest Take All button")
local event, counts = helpers.chooseTakeAllEvent(takeAllButton)
assert(event == "MouseButton1Click" and counts.MouseButton1Click == 1
       and counts.Activated == 0, "click event with live connection not selected")
assert(helpers.chestSnapshot(takeAllButton):find("Take All", 1, true),
       "chest snapshot missing Take All label")
assert(helpers.chestItemCount(takeAllButton) == 15, "Chest count parser did not read 15/183.9K Items")
chestCountLabel.Text = "1,250/183.9K Items"
assert(helpers.chestItemCount(takeAllButton) == 1250, "Chest count parser did not support commas")
chestCountLabel.Text = "15/183.9K Items"

-- Mock actual game GUI controls separately from the hub. Equip Best should
-- require no unknown remote, and Stats upgrades must be restricted by context.
local inventoryGui = instance("ScreenGui")
inventoryGui.Name = "InventoryGui"
inventoryGui.Parent = playerGui
local inventoryOpen = instance("TextButton")
inventoryOpen.Name = "InventoryButton"
inventoryOpen.Text = "Inventory"
inventoryOpen.Parent = inventoryGui
local inventoryClicks = 0
inventoryOpen.MouseButton1Click:Connect(function() inventoryClicks = inventoryClicks + 1 end)
local equipBest = instance("TextButton")
equipBest.Name = "EquipBestButton"
equipBest.Text = "Equip Best"
equipBest.Parent = inventoryGui
local equipClicks = 0
equipBest.MouseButton1Click:Connect(function() equipClicks = equipClicks + 1 end)

-- Real V0.10 runtime GUI path supplied by the user: button text is empty,
-- but the clickable TextButton is a descendant of InventoryButton.
local mineGui = instance("ScreenGui"); mineGui.Name = "MineGui"; mineGui.Parent = playerGui

-- Only the game's native Chest Auto Sell control is permitted.
-- Its GUI is deliberately hidden throughout the headless test.
local nativeChest = instance("Frame")
nativeChest.Name = "ChestFrame"; nativeChest.Visible = false; nativeChest.Parent = mineGui
local chestActions = instance("Frame")
chestActions.Name = "Actions"; chestActions.Parent = nativeChest
local autoSellLabel = instance("TextLabel")
autoSellLabel.Name = "AutoSellCaption"; autoSellLabel.Text = "Auto Sell"
autoSellLabel.Parent = chestActions
local nativeSell = instance("TextButton")
nativeSell.Name = "AutoSellButton"; nativeSell.Text = "Auto Sell: OFF"
nativeSell.Parent = chestActions
local nativeSellClicks = 0
nativeSell.MouseButton1Click:Connect(function()
    nativeSellClicks = nativeSellClicks + 1
    nativeSell.Text = nativeSell.Text == "Auto Sell: OFF" and "Auto Sell: ON" or "Auto Sell: OFF"
end)
local paidSell = instance("Frame")
paidSell.Name = "PaidAutoSell"; paidSell.Parent = nativeChest
local paidPrice = instance("TextLabel")
paidPrice.Name = "Price"; paidPrice.Text = "R$199"; paidPrice.Parent = paidSell
local premiumAutoSell = instance("TextButton")
premiumAutoSell.Name = "AutoSellButton"; premiumAutoSell.Text = "Auto Sell"
premiumAutoSell.Parent = paidSell
premiumAutoSell.MouseButton1Click:Connect(function() error("premium action must not run") end)
local unrelatedSell = instance("TextButton")
unrelatedSell.Name = "SellAll"; unrelatedSell.Text = "Sell All Characters"
unrelatedSell.Parent = playerGui
unrelatedSell.MouseButton1Click:Connect(function() error("unrelated sale must not run") end)

local hotbarFrame = instance("Frame"); hotbarFrame.Name = "HotbarFrame"
hotbarFrame.Parent = mineGui
local hotbarContent = instance("Frame"); hotbarContent.Name = "Content"
hotbarContent.Parent = hotbarFrame
local hotbarContainer = instance("Frame"); hotbarContainer.Name = "Container"
hotbarContainer.Parent = hotbarContent
local inventoryFolder = instance("Frame"); inventoryFolder.Name = "InventoryButton"
inventoryFolder.Parent = hotbarContainer
local realInventoryLauncher = instance("TextButton")
realInventoryLauncher.Name = "TextButton"; realInventoryLauncher.Text = ""
realInventoryLauncher.Parent = inventoryFolder
local realInventoryClicks = 0
realInventoryLauncher.MouseButton1Click:Connect(function() realInventoryClicks = realInventoryClicks + 1 end)
local leftBar = instance("Frame"); leftBar.Name = "LeftBar"; leftBar.Parent = mineGui
local leftContent = instance("Frame"); leftContent.Name = "Content"; leftContent.Parent = leftBar
local leftContainer = instance("Frame"); leftContainer.Name = "Container"
leftContainer.Parent = leftContent
local baseUpgradeLauncher = instance("TextButton")
baseUpgradeLauncher.Name = "UpgradesButton"; baseUpgradeLauncher.Parent = leftContainer

-- Game-native hidden Equip Best button: simulate a loaded client callback
-- that can be fired without displaying the InventoryFrame.
local hiddenInventoryFrame = instance("Frame")
hiddenInventoryFrame.Name = "InventoryFrame"
hiddenInventoryFrame.Visible = false
hiddenInventoryFrame.Parent = mineGui
local hiddenEquipBest = instance("TextButton")
hiddenEquipBest.Name = "EquipBestButton"
hiddenEquipBest.Text = "Equip Best"
hiddenEquipBest.Parent = hiddenInventoryFrame
local hiddenEquipClicks = 0
hiddenEquipBest.MouseButton1Click:Connect(function()
    hiddenEquipClicks = hiddenEquipClicks + 1
end)
-- Read-only discovery can inspect a remote but must never invoke it.
local candidateRemote = instance("RemoteEvent")
candidateRemote.Name = "EquipBestRemote"
candidateRemote.Parent = replicatedStorage

local statsGui = instance("ScreenGui")
statsGui.Name = "UnitGui"
statsGui.Parent = playerGui
local statsPanel = instance("Frame")
statsPanel.Name = "StatsFrame"
statsPanel.Parent = statsGui
local statsTab = instance("TextButton")
statsTab.Name = "StatsButton"; statsTab.Text = "Stats"; statsTab.Parent = statsPanel
local damageRow = instance("Frame")
damageRow.Name = "DamageRow"; damageRow.Parent = statsPanel
local damageLabel = instance("TextLabel")
damageLabel.Name = "DamageName"; damageLabel.Text = "Damage"; damageLabel.Parent = damageRow
local upgradeDamage = instance("TextButton")
upgradeDamage.Name = "UpgradeButton"; upgradeDamage.Text = "Upgrade"; upgradeDamage.Parent = damageRow
local damageClicks = 0
upgradeDamage.MouseButton1Click:Connect(function() damageClicks = damageClicks + 1 end)
local speedRow = instance("Frame")
speedRow.Name = "SpeedRow"; speedRow.Parent = statsPanel
local upgradeSpeed = instance("TextButton")
upgradeSpeed.Name = "LevelUpButton"; upgradeSpeed.Text = "Upgrade"; upgradeSpeed.Parent = speedRow
local premium = instance("TextButton")
premium.Name = "UpgradeRobux"; premium.Text = "R$199"; premium.Parent = damageRow
local premiumRow = instance("Frame")
premiumRow.Name = "MiningSpeedRow"; premiumRow.Parent = statsPanel
local paidPrice = instance("TextLabel")
paidPrice.Name = "Price"; paidPrice.Text = "R$399"; paidPrice.Parent = premiumRow
local paidButton = instance("TextButton")
paidButton.Name = "UpgradeButton"; paidButton.Text = "Upgrade"; paidButton.Parent = premiumRow
local research = instance("Frame")
research.Name = "ResearchPanel"; research.Parent = statsGui
local researchRow = instance("Frame")
researchRow.Name = "DamageRow"; researchRow.Parent = research
local upgradeResearch = instance("TextButton")
upgradeResearch.Name = "UpgradeButton"; upgradeResearch.Text = "Upgrade"
upgradeResearch.Parent = researchRow

helpers.scanActionButtons()
assert(#first.equipCandidates == 1 and first.equipCandidates[1] == equipBest,
       "did not identify visible Equip Best game button")
assert(#first.inventoryCandidates == 2 and first.inventoryCandidates[1] == inventoryOpen
       and first.inventoryCandidates[2] == realInventoryLauncher,
       "did not identify both named and actual textless Inventory openers")
assert(#first.guiUpgradeMenu == 1 and first.guiUpgradeMenu[1] == baseUpgradeLauncher,
       "found global Upgrades menu should stay read-only (not miner Stats)")
assert(#first.statsCandidates == 1 and first.statsCandidates[1] == statsTab,
       "did not discover Stats tab")
assert(helpers.isUpgradeAction(upgradeDamage) and helpers.isUpgradeAction(upgradeSpeed),
       "legitimate crew Damage and Speed upgrades not detected")
assert(not helpers.isUpgradeAction(premium) and not helpers.isUpgradeAction(paidButton)
       and not helpers.isUpgradeAction(upgradeResearch),
       "Robux/research upgrade must never be selected")
assert(#first.upgradeCandidates == 2 and helpers.statContext(upgradeDamage) == "Damage"
       and helpers.statContext(upgradeSpeed) == "Speed",
       "mixed upgrade targets or wrong stat context")
local okEquip, _, equipEvent = helpers.dispatchGameButton(equipBest)
assert(okEquip and equipEvent == "MouseButton1Click" and equipClicks == 1,
       "Equip Best signal did not trigger real game click handler")
local realOk, _, realEvent = helpers.dispatchGameButton(realInventoryLauncher)
assert(realOk and realEvent == "MouseButton1Click" and realInventoryClicks == 1,
       "actual MineGui Hotbar InventoryButton/TextButton must dispatch GUI click")
local availableHidden = helpers.hiddenEquipBestCandidates()
assert(#availableHidden == 1 and availableHidden[1] == hiddenEquipBest,
       "headless lookup must find a game-native hidden Equip Best callback")
local openerClicksBefore = realInventoryClicks
local hiddenOk, hiddenStatus = helpers.tryHeadlessEquip()
assert(hiddenOk and hiddenStatus:find("HIDDEN_EQUIP_SIGNAL_SENT", 1, true)
       and hiddenEquipClicks == 1 and realInventoryClicks == openerClicksBefore
       and hiddenInventoryFrame.Visible == false,
       "headless equip must NOT open Inventory or use its opener")
local remoteList = helpers.headlessRemotes()
assert(#remoteList == 1 and remoteList[1].name == "EquipBestRemote",
       "headless remote discovery must report real names without invoking them")

local sellCandidates, sellLabels = helpers.scanNativeAutoSell()
assert(#sellCandidates == 1 and sellCandidates[1] == nativeSell and #sellLabels == 1,
       "Chest-only scanner must exclude premium Auto Sell and unrelated Sell All")
assert(helpers.nativeAutoSellState(nativeSell) == "OFF" and not nativeChest.Visible,
       "native hidden Chest Auto Sell state was not read correctly")
local openerBeforeSell = realInventoryClicks
-- Legacy Chest Game Pass toggle remains testable as a helper, but AUTO SELL
-- must NO LONGER invoke it; the user requires Shops warp + ore vendor.
local sellOK, sellStage = helpers.tryNativeAutoSell()
assert(sellOK and sellStage:find("AUTO_SELL_SWITCH_TO_ON_SENT", 1, true)
       and first.sellSent and first.sellAttempts == 1 and first.sellCallsOK == 1
       and nativeSellClicks == 1 and helpers.nativeAutoSellState(nativeSell) == "ON"
       and not nativeChest.Visible and realInventoryClicks == openerBeforeSell,
       "Auto Sell must enable a hidden native Chest control once, without opening any panel")
local alreadyOK, alreadyState = helpers.tryNativeAutoSell()
assert(alreadyOK and alreadyState:find("ALREADY_ON", 1, true)
       and nativeSellClicks == 1, "already ON must never toggle Auto Sell back OFF")
local stopOK, stopStage = helpers.setNativeAutoSell("OFF")
assert(stopOK and stopStage:find("SWITCH_TO_OFF",1,true)
       and nativeSellClicks == 2 and nativeSell.Text == "Auto Sell: OFF",
       "legacy Chest toggle helper still safely respects known ON/OFF state")
nativeSell.Text = "Auto Sell"
local unknownOK, unknownStage = helpers.tryNativeAutoSell()
assert(not unknownOK and unknownStage == "AUTO_SELL_STATE_UNKNOWN (no toggle sent)"
       and nativeSellClicks == 2,
       "unknown state must not risk toggling an already ON or OFF control")
nativeSell.Text = "Auto Sell: OFF"
findButton("ActionDiagnostics").Activated:Fire()
assert(clipboard:find("Chest Auto Sell candidates=1", 1, true)
       and clipboard:find("ChestSellLabel", 1, true)
       and clipboard:find("Native Chest Auto Sell (legacy", 1, true)
       and clipboard:find("AUTO_SELL", 1, true),
       "native Auto Sell target diagnostics missing")

findButton("ActionDiagnostics").Activated:Fire()
assert(clipboard:find("HEADLESS REMOTE DISCOVERY", 1, true)
       and clipboard:find("EquipBestRemote", 1, true)
       and clipboard:find("Headless loaded Equip Best buttons=1", 1, true),
       "headless diagnostic missing remote and hidden-target details")

local okUpgrade, _, upgradeEvent = helpers.dispatchGameButton(upgradeDamage)
assert(okUpgrade and upgradeEvent == "MouseButton1Click" and damageClicks == 1,
       "Upgrade signal did not trigger real game click handler")
findButton("AutoEquip").Activated:Fire()
findButton("AutoUpgrade").Activated:Fire()
assert(first.equip and first.upgrade, "equip and upgrade toggles failed to enable")
findButton("ActionDiagnostics").Activated:Fire()
assert(clipboard:find("EQUIP / UPGRADE TARGETS", 1, true)
       and clipboard:find("EquipBest", 1, true)
       and clipboard:find("statUpgrades=2", 1, true)
       and clipboard:find("ALL VISIBLE GAME GUI BUTTONS", 1, true),
       "equip/upgrade target copy missing candidate details")
findButton("AutoEquip").Activated:Fire()
findButton("AutoUpgrade").Activated:Fire()
assert(not first.equip and not first.upgrade, "equip and upgrade toggles must switch OFF")
-- Icon-only Inventory opener and hidden Equip Best are visible in diagnostic,
-- but hidden controls must not be added to auto dispatch candidates.
local toolbar = instance("Frame")
toolbar.Name = "Toolbar"
toolbar.Parent = inventoryGui
local inventoryText = instance("TextLabel")
inventoryText.Name = "IconTitle"
inventoryText.Text = "Inventory"
inventoryText.Parent = toolbar
local icon = instance("ImageButton")
icon.Name = "Icon"
icon.Parent = toolbar
local hiddenGui = instance("ScreenGui")
hiddenGui.Name = "SecondaryInventory"
hiddenGui.Enabled = false
hiddenGui.Parent = playerGui
local hiddenEquip = instance("TextButton")
hiddenEquip.Name = "EquipBestButton"
hiddenEquip.Text = "Equip Best"
hiddenEquip.Parent = hiddenGui
helpers.scanActionButtons()
assert(#first.inventoryCandidates == 3 and #first.equipCandidates == 1,
       "icon-only Inventory discovery failed or hidden Equip leaked into candidates")
findButton("ActionDiagnostics").Activated:Fire()
assert(clipboard:find("class=ImageButton", 1, true)
       and clipboard:find("HIDDEN GAME GUI CANDIDATES", 1, true)
       and clipboard:find("SecondaryInventory", 1, true)
       and clipboard:find("GameUpgradesMenu", 1, true)
       and clipboard:find("InventoryButton/TextButton", 1, true),
       "expanded button diagnostic omitted real launcher, global Upgrades, or hidden GUI")
findButton("Scan").Activated:Fire()
findButton("CopyLog").Activated:Fire()
assert(clipboard and clipboard:find("PlaceId 79389059854988", 1, true), "copy log unavailable")
findButton("Diagnostics").Activated:Fire()
assert(clipboard and clipboard:find("TakeAll visible: ", 1, true), "target diagnostics missing")
assert(clipboard:find("TakeAll event connections", 1, true),
       "Take All event connections not present in diagnostic")

-- Nearest Chest belongs to Plot8 (no upgrade marker), while Plot7 has both.
-- The automatic selector must choose Plot7, without manual buttons.
assert(not first.selectedPlot, "plot selected without character")
local character=instance("Model");character.Parent=workspace;player.Character=character
local root=instance("BasePart");root.Name="HumanoidRootPart"
root.Position=vector(0,0,0);root.Parent=character
createPlot("MinePlot8", 3, false)
createPlot("MinePlot7", 40, true)
local plot = workspace:FindFirstChild("MinePlot7")
local holderGroup = instance("Folder"); holderGroup.Name="Holders"; holderGroup.Parent=plot
local holder = instance("Model"); holder.Name="M5"; holder.Parent=holderGroup
local upgradePart = instance("BasePart"); upgradePart.Name="UpgradePart"
upgradePart.Position=vector(23,0,0); upgradePart.Parent=holder
local detector = instance("ClickDetector"); detector.Name="UpgradeClick"
detector.MaxActivationDistance=32; detector.Parent=upgradePart
findButton("Scan").Activated:Fire()
assert(first.selectedPlot == "MinePlot7", "auto selector failed to choose the verified near-Plot candidate")
local selectedHolder, holderDist = helpers.nextHolderDetector(true)
assert(selectedHolder == detector and holderDist == 23,
       "selected plot holder upgrade detector not found")
detector.MaxActivationDistance = 8
local noHolder, _, outOfRangeHolder = helpers.nextHolderDetector(true)
assert(noHolder == nil and outOfRangeHolder.detector == detector
       and outOfRangeHolder.distance == 23 and outOfRangeHolder.allowed == 8,
       "out-of-range Holder must be reported rather than called missing")
local humanoid = instance("Humanoid")
humanoid.Health = 100
humanoid.Parent = character
local moveCommands = 0
humanoid.MoveTo = function(_, _) moveCommands = moveCommands + 1 end
local approachStage = helpers.approachUpgradeHolder(outOfRangeHolder, 10)
assert(approachStage:find("Walking to holder", 1, true)
       and first.upgradeWalkTarget == detector and moveCommands > 0,
       "out-of-range Holder should trigger bounded natural MoveTo")
root.Position = vector(20,0,0)
local inRangeHolder, inRangeDist = helpers.nextHolderDetector(true)
assert(inRangeHolder == detector and inRangeDist == 3,
       "Holder should become actionable only after approaching its range")
helpers.stopUpgradeWalking()
assert(first.upgradeWalkTarget == nil, "upgrade navigation not stopped")
root.Position = vector(0,0,0)
detector.MaxActivationDistance = 32

-- User-confirmed route: click Teleport > Shops, walk to Sell Items,
-- then an explicit ore-only Sell action. Do not use the paid Chest Auto Sell.
local teleport = instance("TextButton")
teleport.Name = "TeleportButton"; teleport.Text = ""
teleport.Parent = mineGui
local teleClicks = 0
local teleMenu = instance("Frame")
teleMenu.Name = "TeleportFrame"; teleMenu.Visible = false; teleMenu.Parent = mineGui
local shopsButton
teleport.MouseButton1Click:Connect(function()
    teleClicks = teleClicks + 1
    teleMenu.Visible = true
    if not shopsButton then
        shopsButton = instance("TextButton")
        shopsButton.Name = "ShopsButton"; shopsButton.Text = "Shops"
        shopsButton.Parent = teleMenu
        shopsButton.MouseButton1Click:Connect(function()
            root.Position = vector(500,0,0)
            teleMenu.Visible = false
        end)
    end
end)
local sellStand = instance("BasePart")
sellStand.Name="SellItemsStand"; sellStand.Position=vector(580,0,0)
sellStand.Parent=workspace
local sellPrompt = instance("ProximityPrompt")
sellPrompt.Name="SellItemsPrompt"; sellPrompt.ActionText="Sell Items"
sellPrompt.MaxActivationDistance=10; sellPrompt.Enabled=true
sellPrompt.Parent=sellStand
local sellScreen=instance("Frame")
sellScreen.Name="SellFrame";sellScreen.Visible=false;sellScreen.Parent=mineGui
local oreSell=instance("TextButton")
oreSell.Name="SellOres"; oreSell.Text="Sell Ores";oreSell.Parent=sellScreen
local genericSell=instance("TextButton")
genericSell.Name="SellAll"; genericSell.Text="Sell All";genericSell.Parent=sellScreen
local oreSells,genericSells=0,0
oreSell.MouseButton1Click:Connect(function()
    oreSells=oreSells+1
    sellScreen.Visible=false
end)
genericSell.MouseButton1Click:Connect(function() genericSells=genericSells+1 end)
env.fireproximityprompt=function(target)
    if target==sellPrompt then sellScreen.Visible=true end
end
local nativeClicksBefore=nativeSellClicks
assert(helpers.shopsTeleportLauncher() == teleport, "TeleportButton not found")
findButton("AutoSell").Activated:Fire()
assert(first.sell and first.sellPhase=="TELEPORT_OPEN",
       "Auto Sell must arm Shops route instead of native Chest Game Pass")
helpers.shopSellStep(10)
assert(teleClicks==1 and first.sellPhase=="SHOPS_PICK",
       "route must open Teleport destination")
helpers.shopSellStep(12)
assert(first.sellPhase=="WARP_WAIT" and root.Position.X==500,
       "route must click Shops before moving to vendor")
helpers.shopSellStep(14)
assert(first.sellPhase=="VENDOR_WALK","route did not verify Shops warp")
local vendors=helpers.sellVendorTargets()
assert(#vendors>=1 and vendors[1].target==sellPrompt and vendors[1].distance==80,
       "expected Sell Items vendor prompt at Shops")
helpers.shopSellStep(16)
assert(first.sellMoveTarget==sellPrompt and first.sellWalkAttempts>0,
       "route must walk to Sell Items vendor, never teleport to its coordinate")
root.Position=vector(578,0,0)
helpers.shopSellStep(18)
assert(first.sellPhase=="SELL_MENU" and sellScreen.Visible,
       "sell vendor prompt must open sell interface")
helpers.shopSellStep(20)
assert(first.sellPhase=="DONE" and oreSells==1 and genericSells==0
       and nativeSellClicks==nativeClicksBefore and first.sellCallsOK==1,
       "route may only send explicit Sell Ores action, never Sell All or gamepass")
findButton("ActionDiagnostics").Activated:Fire()
assert(clipboard:find("SHOP SELL ROUTE",1,true)
       and clipboard:find("Sell vendor candidates=",1,true)
       and clipboard:find("Ore-only Sell candidates=",1,true),
       "sale route must expose warp/vendor/sell diagnostics")
findButton("AutoSell").Activated:Fire()
assert(not first.sell and first.sellPhase=="OFF", "sell route OFF did not stop")
root.Position=vector(0,0,0)
sellScreen.Visible=false

findButton("ActionDiagnostics").Activated:Fire()
assert(clipboard:find("Holder[1]", 1, true)
       and clipboard:find("maxRange=32.0", 1, true),
       "Holder diagnostics should report range/position")
findButton("AutoUpgrade").Activated:Fire()
assert(first.upgrade and first.selectedPlot == "MinePlot7",
       "upgrade must work independently with automatically detected plot")
findButton("AutoUpgrade").Activated:Fire()
local hub = playerGui:FindFirstChild("MyAnimeMineHub")
assert(hub:FindFirstChild("Main"):FindFirstChild("AutoPlotStatus"),
       "missing automatic plot/walk status")
for _, name in ipairs({"SetPlot", "WalkToChest"}) do
    for _, child in ipairs(hub:GetDescendants()) do
        assert(child.Name ~= name, "unneeded manual button remains: " .. name)
    end
end
findButton("Diagnostics").Activated:Fire()
assert(clipboard:find("Selected chest=",1,true) and
       clipboard:find("MinePlot7",1,true) and clipboard:find("dist=40.0 maxRange=10.0",1,true),
       "selected plot chest distance/range diagnostics missing")
assert(not first.walkToChest, "walking must remain OFF before Auto Collect")

findButton("AutoMine").Activated:Fire()
findButton("AutoCollect").Activated:Fire()
assert(first.mine and first.collect and first.walkToChest,
       "Auto Collect must automatically enable bounded walking")

local main = assert(playerGui:FindFirstChild("MyAnimeMineHub"):FindFirstChild("Main"))
local restore = findButton("RestoreWindow")
assert(main.Visible and not restore.Visible and not first.minimized, "window should start expanded")
local alt = {KeyCode = env.Enum.KeyCode.LeftAlt}
input.InputBegan:Fire({KeyCode = env.Enum.KeyCode.RightAlt}, false)
assert(main.Visible, "RightAlt must not minimize")
input.InputBegan:Fire(alt, true)
assert(main.Visible, "processed LeftAlt must not minimize")
input.InputBegan:Fire(alt, false)
assert(not main.Visible and restore.Visible and first.minimized, "LeftAlt did not minimize")
assert(first.mine and first.collect, "minimizing must not change automation toggles")
restore.Activated:Fire()
assert(main.Visible and not restore.Visible and not first.minimized, "restore chip did not expand")
input.InputBegan:Fire(alt, false)
input.InputBegan:Fire(alt, false)
assert(main.Visible and not restore.Visible, "LeftAlt must toggle open and closed")
-- A count decrease is useful Chest UI evidence, but NOT confirmed inventory gain.
first.takeAllPending = {
    button = takeAllButton, before = helpers.chestSnapshot(takeAllButton),
    beforeCount = 15, sentAt = 1, event = "MouseButton1Click",
}
first.takeAllAttempts = 1
chestCountLabel.Text = "9/183.9K Items"
helpers.settleTakeAll(10)
assert(first.takeAllOutcome:find("CHEST_COUNT_DECREASED", 1, true)
       and first.lastChestCountDelta == -6 and first.takeAllNotDecreased == 0,
       "count decrease should be recorded without confirming inventory")
chestCountLabel.Text = "12/183.9K Items"
first.takeAllPending = {
    button = takeAllButton, before = helpers.chestSnapshot(takeAllButton),
    beforeCount = 9, sentAt = 11, event = "MouseButton1Click",
}
helpers.settleTakeAll(20)
assert(first.takeAllOutcome:find("CHEST_COUNT_INCREASED", 1, true)
       and first.takeAllNotDecreased == 1 and first.collect,
       "Chest count increase should be treated as ambiguous mining")
for i = 2, 3 do
    first.takeAllPending = {
        button = takeAllButton, before = helpers.chestSnapshot(takeAllButton),
        beforeCount = 12, sentAt = 20 + i, event = "MouseButton1Click",
    }
    helpers.settleTakeAll(30 + i)
end
assert(first.takeAllNotDecreased == 3 and not first.collect,
       "three calls without count decrease must pause Auto Collect")
findButton("Diagnostics").Activated:Fire()
assert(clipboard:find("Chest count before=12 after=12 delta=0", 1, true),
       "count delta not present in copied diagnostics")
findButton("AutoCollect").Activated:Fire()
assert(first.collect and first.walkToChest and first.takeAllNotDecreased == 0
       and first.takeAllOutcome == "NOT TESTED",
       "reenabling Collect must restore automatic walking and reset feedback state")
-- A hidden Chest may still have stale count text. That must never be reported
-- as a live unchanged Chest, and Auto Collect must pause rather than reopen it.
chestCountLabel.Text = "30/183.9K Items"
first.takeAllPending = {
    button = takeAllButton,
    before = helpers.chestSnapshot(takeAllButton),
    beforeCount = 30,
    sentAt = 1,
    event = "MouseButton1Click",
}
gameChestGui.Enabled = false
helpers.settleTakeAll(10)
assert(first.takeAllOutcome:find("CHEST_CLOSED",1,true) and
       first.lastChestCountAfter == nil and first.lastChestCountDelta == nil and
       first.collect and first.takeAllReopenAt == 22,
       "hidden Chest must preserve automation, invalidate count and apply cooldown")
gameChestGui.Enabled = true
chestCountLabel.Text = "2/183.9K Items"
helpers.observeReopenedChest(takeAllButton)
assert(first.takeAllReopenStatus:find("REOPEN_COUNT_LOWER",1,true)
       and first.takeAllUnverifiedReopens == 0 and first.collect,
       "lower Chest count after reopen should be observed without claiming reward")
first.takeAllClosedBeforeCount = 30
chestCountLabel.Text = "30/183.9K Items"
helpers.observeReopenedChest(takeAllButton)
assert(first.takeAllUnverifiedReopens == 1 and first.collect,
       "first unchanged reopen must be inconclusive")
first.takeAllClosedBeforeCount = 30
chestCountLabel.Text = "32/183.9K Items"
helpers.observeReopenedChest(takeAllButton)
assert(first.takeAllUnverifiedReopens == 2 and not first.collect,
       "repeated inconclusive reopen must pause Auto Collect")


-- The manually clicked GUI button is observed only; the hub must not emit signals.
local emittedBefore = firedTakeAll
findButton("ManualWatch").Activated:Fire()
assert(first.watchManual and not first.collect, "manual watch only when Auto Collect OFF")
helpers.monitorManualButton()
assert(first.manualMonitorButton == takeAllButton, "did not attach manual click listener")
takeAllButton.MouseButton1Click:Fire()
assert(first.manualClickCount == 1 and firedTakeAll == emittedBefore,
       "manual watch must observe without emitting executor click")
gameChestGui.Enabled = false
helpers.settleManualTakeAll(os.clock() + 5)
assert(first.manualOutcome:find("MANUAL_CHEST_CLOSED",1,true) and
       first.manualAfter == nil and first.manualDelta == nil,
       "manual hidden Chest must not reuse stale cached count")
gameChestGui.Enabled = true
chestCountLabel.Text = "30/183.9K Items"
takeAllButton.MouseButton1Click:Fire()
assert(first.manualClickCount == 2, "manual click not observed")
chestCountLabel.Text = "12/183.9K Items"
helpers.settleManualTakeAll(os.clock() + 5)
assert(first.manualOutcome == "MANUAL_CHEST_COUNT_DECREASED"
       and first.manualDelta == -18, "manual count decrease not diagnosed")
findButton("Diagnostics").Activated:Fire()
assert(clipboard:find("Manual TakeAll feedback=MANUAL_CHEST_COUNT_DECREASED",1,true),
       "manual diagnostic not included in copied report")
findButton("AutoCollect").Activated:Fire()
assert(not first.collect, "manual watch must block auto collection")
findButton("ManualWatch").Activated:Fire()
assert(not first.watchManual, "manual watch did not stop")
local second = run()
assert(not first.running and second.running, "rerun did not clean up previous controller")
local count = 0
for _, child in ipairs(playerGui:GetChildren()) do
    if child.Name == "MyAnimeMineHub" then count = count + 1 end
end
assert(count == 1, "duplicate UI after rerun")
assert(not second.mine and not second.collect and not second.equip and not second.upgrade
       and not second.sell, "rerun must begin with all auto toggles OFF")
assert(not second.minimized and findButton("RestoreWindow").Visible == false,
    "rerun must restore expanded UI")
assert(second.selectedPlot == "MinePlot7" and not second.walkToChest,
       "rerun should auto-detect the nearby Plot while leaving walking OFF")
findButton("Close").Activated:Fire()
assert(not second.running and not playerGui:FindFirstChild("MyAnimeMineHub"), "close did not stop")
assert(env.MyAnimeMineHubController == nil, "controller leaked after close")
print("PASS My Anime Mine V0.14 Shops warp, Sell Items MoveTo, ore-only sale and Collect lifecycle")
