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
                or props.ClassName == "ImageLabel" or props.ClassName == "TextBox"
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
            if key == "Activated" or key == "FocusLost" or key == "MouseButton1Click" or key == "InputBegan" or key == "InputChanged" or key == "InputEnded" then
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
    local testSource = source .. "\nreturn {chestSnapshot=chestSnapshot, chestItemCount=chestItemCount, chooseTakeAllEvent=chooseTakeAllEvent, settleTakeAll=settleTakeAll, observeReopenedChest=observeReopenedChest, monitorManualButton=monitorManualButton, settleManualTakeAll=settleManualTakeAll, scanActionButtons=scanActionButtons, isUpgradeAction=isUpgradeAction, statContext=statContext, actionDiagnosticReport=actionDiagnosticReport, dispatchGameButton=dispatchGameButton, resolveUpgradeFeedback=resolveUpgradeFeedback, nextHolderDetector=nextHolderDetector, holderTargets=holderTargets, approachUpgradeHolder=approachUpgradeHolder, stopUpgradeWalking=stopUpgradeWalking, hiddenEquipBestCandidates=hiddenEquipBestCandidates, headlessRemotes=headlessRemotes, tryHeadlessEquip=tryHeadlessEquip, scanNativeAutoSell=scanNativeAutoSell, nativeAutoSellState=nativeAutoSellState, setNativeAutoSell=setNativeAutoSell, tryNativeAutoSell=tryNativeAutoSell, shopsTeleportLauncher=shopsTeleportLauncher, shopsWarpDestination=shopsWarpDestination, sellVendorTargets=sellVendorTargets, oreSellButton=oreSellButton, shopSellStep=shopSellStep, baseReturnDestination=baseReturnDestination, returnBaseStep=returnBaseStep, returnBaseDistance=returnBaseDistance, finishVerifiedBaseReturn=finishVerifiedBaseReturn, sellStopWalk=sellStopWalk, recentTakeAllForHandoff=recentTakeAllForHandoff, canCollectDuringSell=canCollectDuringSell, gameChestFrame=gameChestFrame, teleportLauncherCandidates=teleportLauncherCandidates, validatedSellStandSession=validatedSellStandSession, isExactSellStandButton=isExactSellStandButton, sellSelectAllButton=sellSelectAllButton, knownOreSellFrame=knownOreSellFrame, armSellRoute=armSellRoute, updateCycleMinutes=updateCycleMinutes, beginCollectionCycle=beginCollectionCycle, updateFarmCycle=updateFarmCycle, setFarmCycleEnabled=setFarmCycleEnabled}"
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
       and clipboard:find("Native Chest Auto Sell (legacy", 1, true),
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
env.baseReturnTest={button=nil, clicks=0, before=0, teleBefore=0, target=nil, count=0}
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
    if not env.baseReturnTest.button then
        env.baseReturnTest.button = instance("TextButton")
        env.baseReturnTest.button.Name="BaseButton";env.baseReturnTest.button.Text="Base"
        env.baseReturnTest.button.Parent=teleMenu
        env.baseReturnTest.button.MouseButton1Click:Connect(function()
            env.baseReturnTest.clicks=env.baseReturnTest.clicks+1
            root.Position=vector(0,0,0)
            teleMenu.Visible=false
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
local selectContent=instance("Frame")
selectContent.Name="Content";selectContent.Parent=sellScreen
local selectAll=instance("TextButton")
selectAll.Name="SelectAllButton";selectAll.Text="Select All";selectAll.Parent=selectContent
local selectClicks=0
local sellOrder={}
selectAll.MouseButton1Click:Connect(function()
    selectClicks=selectClicks+1
    sellOrder[#sellOrder+1]="Select All"
end)
local unrelatedSelect=instance("TextButton")
unrelatedSelect.Name="SelectAllButton";unrelatedSelect.Text="Select All"
unrelatedSelect.Parent=inventoryGui
local unrelatedOreSell=instance("TextButton")
unrelatedOreSell.Name="SellOres";unrelatedOreSell.Text="Sell Ores"
unrelatedOreSell.Parent=inventoryGui
local unrelatedSellOreClicks=0
unrelatedOreSell.MouseButton1Click:Connect(function()
    unrelatedSellOreClicks=unrelatedSellOreClicks+1
end)
local unrelatedSelectClicks=0
unrelatedSelect.MouseButton1Click:Connect(function()
    unrelatedSelectClicks=unrelatedSelectClicks+1
end)
local oreSell=instance("TextButton")
oreSell.Name="SellOres"; oreSell.Text="Sell Ores";oreSell.Parent=sellScreen
local genericSell=instance("TextButton")
genericSell.Name="SellAll"; genericSell.Text="Sell All";genericSell.Parent=sellScreen
local oreSells,genericSells=0,0
oreSell.MouseButton1Click:Connect(function()
    oreSells=oreSells+1
    sellOrder[#sellOrder+1]="Sell"
    assert(selectClicks >= oreSells, "Sell must never precede Select All")
    sellScreen.Visible=false
end)
genericSell.MouseButton1Click:Connect(function() genericSells=genericSells+1 end)
env.fireproximityprompt=function(target)
    if target==sellPrompt then sellScreen.Visible=true end
end
local nativeClicksBefore=nativeSellClicks
assert(helpers.shopsTeleportLauncher() == teleport, "TeleportButton not found")
findButton("AutoSell").Activated:Fire()
assert(first.sell and first.sellPhase=="CHEST_HANDOFF",
       "Auto Sell must check for an open Chest before touching Teleport")
helpers.shopSellStep(8)
assert(first.sellPhase=="TELEPORT_OPEN",
       "no visible MineGui Chest and no pending Take All should permit Teleport")
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
assert(first.sellPhase=="SELECT_ALL" and sellScreen.Visible,
       "sell vendor prompt must enter Select All phase first")
local sellEarly=first.sellCallsOK
helpers.shopSellStep(20)
assert(first.sellPhase=="SELL_MENU" and selectClicks==1 and oreSells==0
       and first.sellSelectAllCallsOK==1 and first.sellSelectAllSent
       and first.sellCallsOK==sellEarly and unrelatedSelectClicks==0,
       "Select All must be dispatched once before Sell, only inside SellFrame")
helpers.shopSellStep(22)
assert(first.sellPhase=="RETURN_BASE_OPEN" and oreSells==1 and genericSells==0
       and unrelatedSellOreClicks==0
       and nativeSellClicks==nativeClicksBefore and first.sellCallsOK==1
       and sellOrder[1]=="Select All" and sellOrder[2]=="Sell",
       "after ordered Select All then Sell, return navigation must start")
findButton("Scan").Activated:Fire()
assert(findButton("AutoSell").Text=="AUTO SELL ORES: RETURNING"
       and first.sell, "after Sell, UI must show RETURNING rather than implying a verified sale")
findButton("ActionDiagnostics").Activated:Fire()
assert(clipboard:find("SHOP SELL ROUTE",1,true)
       and clipboard:find("Sell vendor candidates=",1,true)
       and clipboard:find("Ore-only Sell candidates=",1,true),
       "sale route must expose warp/vendor/sell diagnostics")
findButton("SellDiagnostics").Activated:Fire()
assert(clipboard:find("V0.22 SHOP SELL ROUTE",1,true)
       and clipboard:find("Shops destination candidates=",1,true)
       and clipboard:find("Explicit ore-only Sell controls=",1,true)
       and clipboard:find("Select All clicks=1/1",1,true)
       and clipboard:find("Sell Ores clicks=1/1",1,true),
       "dedicated COPY SELL ROUTE diagnostic missing route outcomes")
assert(clipboard:find("Return Base: originalPlot=MinePlot7",1,true)
       and clipboard:find("verified=false",1,true),
       "return diagnostics must identify plot and pending validation")
env.baseReturnTest.teleBefore=teleClicks
helpers.shopSellStep(24)
assert(first.sellPhase=="RETURN_BASE_WAIT" and teleClicks==env.baseReturnTest.teleBefore+1
       and first.sellReturnClicks==1 and not first.sellReturnVerified,
       "after Sell, game must dispatch the native Base/Shops toggle once")
env.baseReturnTest.target,env.baseReturnTest.count=helpers.baseReturnDestination()
assert(env.baseReturnTest.target==env.baseReturnTest.button
       and env.baseReturnTest.count==1,
       "visible Base choice from TeleportFrame must be recognized")
helpers.shopSellStep(26)
assert(first.sellPhase=="RETURN_BASE_WAIT" and env.baseReturnTest.clicks==1
       and first.sellReturnChoiceClicks==1,
       "Base destination should be clicked only once")
first.collect=true
helpers.shopSellStep(28)
assert(first.sellPhase=="RETURNED_BASE" and not first.sell
       and first.sellReturnVerified and first.sellReturnCurrentDistance==40
       and helpers.canCollectDuringSell(),
       "confirmed return to selected MinePlot must safely release Auto Collect")
findButton("Scan").Activated:Fire()
assert(findButton("AutoSell").Text=="AUTO SELL ORES: RETURNED",
       "after confirmed return, display RETURNED and stop one-shot Sell")
findButton("SellDiagnostics").Activated:Fire()
assert(clipboard:find("verified=true",1,true)
       and clipboard:find("status=VERIFIED_NEAR_SELECTED_PLOT",1,true),
       "return diagnostics must retain verified plot after a completed sale")
first.collect=false
teleMenu.Visible=false

-- A return toggle that teleports directly, with no Base submenu,
-- should still pass once the selected Chest is near.
first.sell=true
first.sellPhase="RETURN_BASE_WAIT"
first.sellReturnOriginalPlot="MinePlot7"
first.sellReturnStartDistance=538
first.sellReturnVerified=false
first.sellReturnChoiceClicks=0
root.Position=vector(578,0,0)
env.baseReturnTest.before=env.baseReturnTest.clicks
root.Position=vector(0,0,0)
helpers.returnBaseStep(32,"RETURN_BASE_WAIT")
assert(first.sellPhase=="RETURNED_BASE" and not first.sell
       and first.sellReturnVerified
       and env.baseReturnTest.clicks==env.baseReturnTest.before,
       "Base/Shops direct toggle must verify return without an extra destination click")

-- A click that leaves the player at Shops cannot unlock Collect.
root.Position=vector(578,0,0)
first.sell=true
first.sellPhase="RETURN_BASE_WAIT"
first.sellReturnOriginalPlot="MinePlot7"
first.sellReturnStartDistance=538
first.sellReturnVerified=false
first.sellReturnChoiceClicks=1
first.sellPhaseAt=33
first.collect=true
helpers.returnBaseStep(52,"RETURN_BASE_WAIT")
assert(first.sellPhase=="PAUSED" and first.sell
       and not first.sellReturnVerified and not helpers.canCollectDuringSell()
       and first.sellReturnStatus=="RETURN_UNVERIFIED",
       "wrong destination must pause; Auto Collect stays locked")
findButton("SellDiagnostics").Activated:Fire()
assert(clipboard:find("status=RETURN_UNVERIFIED",1,true)
       and clipboard:find("verified=false",1,true),
       "failed return diagnostic must show unverified state")
findButton("AutoSell").Activated:Fire()
first.collect=false
root.Position=vector(0,0,0)

-- LIVE V0.17 REGRESSION: Auto Collect just opened MineGui/ChestFrame,
-- then Auto Sell was enabled. Chest modal makes TeleportButton hidden.
-- Allow Take All to settle instead of prematurely declaring Teleport missing.
local activeChest=nativeChest
activeChest.Visible=true
local teleBeforeHandoff=teleClicks
teleport.Visible=false
findButton("AutoSell").Activated:Fire()
assert(first.sell and first.sellPhase=="CHEST_HANDOFF", "initial Chest handoff phase missing")
first.sellPhaseAt=29 -- simulated elapsed time; preserve the real 24-second grace
helpers.shopSellStep(30)
assert(first.sellPhase=="CHEST_HANDOFF" and first.sellWarpAttempts==0
       and teleClicks==teleBeforeHandoff and first.sellChestHandoffState=="CHEST_OPEN",
       "must wait while Chest is open, not click or fail Teleport")
findButton("SellDiagnostics").Activated:Fire()
assert(clipboard:find("chestOpen=true",1,true)
       and clipboard:find("TeleportButton candidates=1",1,true)
       and clipboard:find("visible=false",1,true),
       "copy sell route should show open Chest and hidden Teleport control")
activeChest.Visible=false
first.takeAllPending={sentAt=30}
helpers.shopSellStep(32)
assert(first.sellPhase=="CHEST_HANDOFF"
       and first.sellChestHandoffState=="TAKE_ALL_PENDING"
       and teleClicks==teleBeforeHandoff,
       "must not interrupt unfinished Take All feedback after Chest closes")
first.takeAllPending=nil
teleport.Visible=true
helpers.shopSellStep(34)
assert(first.sellPhase=="TELEPORT_OPEN" and first.sellChestHandoffState=="CHEST_CLOSED",
       "Chest closed and Take All settled should release Shops teleport")
helpers.shopSellStep(36)
assert(first.sellPhase=="SHOPS_PICK" and teleClicks==teleBeforeHandoff+1,
       "after handoff, actual Teleport should be clicked normally")
findButton("AutoSell").Activated:Fire()
assert(not first.sell and first.sellPhase=="OFF", "sell handoff did not cancel safely")
teleMenu.Visible=false

-- If TeleportButton still exists but another panel hides it,
-- diagnose that distinction instead of falsely saying NOT FOUND.
teleport.Visible=false
findButton("AutoSell").Activated:Fire()
helpers.shopSellStep(43)
assert(first.sellPhase=="TELEPORT_OPEN", "closed Chest should advance to Teleport")
helpers.shopSellStep(45)
assert(first.sellPhase=="TELEPORT_OPEN"
       and first.sellStage:find("exists but hidden",1,true),
       "hidden Teleport should be distinguished from an absent one")
helpers.shopSellStep(61)
assert(first.sellPhase=="PAUSED" and first.sellStage:find("hidden",1,true),
       "hidden Teleport should safely pause after a bounded timeout")
findButton("AutoSell").Activated:Fire()
teleport.Visible=true

-- LIVE V0.18 REGRESSION: Sell armed while Collect is WALKING to Chest
-- with no ChestFrame open. The old handoff treated that as "Chest clear"
-- and abandoned Collect without a Take All attempt.
first.collect=true
first.walkToChest=true
first.moveTarget=instance("ProximityPrompt")
local walkingTarget=first.moveTarget
local baseline=first.takeAllActions
local beforeCollectHandoffTele=teleClicks
findButton("AutoSell").Activated:Fire()
assert(first.sell and first.sellPhase=="CHEST_HANDOFF"
    and first.sellHandoffNeedsCollect
    and first.sellHandoffBaselineTakeAllActions==baseline
    and first.moveTarget==walkingTarget
    and helpers.canCollectDuringSell(),
    "selling must NOT cancel ongoing Chest walking while Collect is active")
first.sellPhaseAt=51
helpers.shopSellStep(53)
assert(first.sellPhase=="CHEST_HANDOFF" and first.sellWarpAttempts==0
    and first.sellChestHandoffState=="COLLECT_WALKING_TO_CHEST"
    and teleClicks==beforeCollectHandoffTele
    and helpers.canCollectDuringSell(),
    "handoff must keep Auto Collect walking before the first Take All")
-- Simulate the existing Collect worker reaching and dispatching Take All.
first.takeAllActions=baseline+1
first.takeAllPending={sentAt=53}
activeChest.Visible=true
helpers.shopSellStep(55)
assert(first.sellPhase=="CHEST_HANDOFF"
    and first.sellHandoffTakeAllObserved
    and not helpers.canCollectDuringSell()
    and teleClicks==beforeCollectHandoffTele,
    "after Take All dispatch, new walking/Chest opens must stop while pending feedback settles")
first.takeAllPending=nil
activeChest.Visible=false
helpers.shopSellStep(57)
assert(first.sellPhase=="TELEPORT_OPEN"
    and first.sellChestHandoffState=="COLLECT_FINISHED"
    and first.moveTarget==nil,
    "only the completed Take All and closed Chest can authorize Shops teleport")
helpers.shopSellStep(59)
assert(first.sellPhase=="SHOPS_PICK" and teleClicks==beforeCollectHandoffTele+1,
    "after Collect handoff, normal Teleport must resume")
findButton("AutoSell").Activated:Fire()
assert(not first.sell and helpers.canCollectDuringSell(),
    "sell toggle should stop Shops routing and restore normal Collect eligibility")
teleMenu.Visible=false
first.collect=false

-- A blocked ongoing Collect must not silently warp to the vendor.
first.collect=true
findButton("AutoSell").Activated:Fire()
first.sellPhaseAt=100
local beforeBlocked=teleClicks
helpers.shopSellStep(101)
assert(first.sellPhase=="CHEST_HANDOFF"
    and first.sellWarpAttempts==0 and teleClicks==beforeBlocked,
    "fresh Collect ON with no Chest must wait before warp")
helpers.shopSellStep(144)
assert(first.sellPhase=="PAUSED"
    and first.sellStage:find("No Take All within 42s",1,true)
    and teleClicks==beforeBlocked,
    "bounded handoff timeout must pause rather than abandon Collect")
findButton("AutoSell").Activated:Fire()
first.collect=false
first.walkToChest=false -- restore OFF-by-default test fixture after Collect handoff

-- LIVE V0.19 REGRESSION: user enabled Sell just as a Take All had
-- finished. It was unnecessarily reopened after the 12-second cooldown.
-- Reuse only recent same-plot Take All; do not claim inventory credit.
local plotBeforeRecent=first.selectedPlot
first.selectedPlot="MinePlot5"
first.collect=true
activeChest.Visible=false
first.takeAllPending=nil
first.takeAllOutcome="CHEST_CLOSED_AFTER_TAKE_ALL (matches manual UI; inventory unknown)"
first.takeAllLastDispatchAt=os.clock()
first.takeAllLastDispatchPlot="MinePlot5"
local recentValid, recentAge=helpers.recentTakeAllForHandoff(os.clock())
assert(recentValid and recentAge>=0 and recentAge<8,
       "same-plot closed Take All within 8s should be eligible")
local priorTakeAll=first.takeAllActions
local teleBeforeRecent=teleClicks
findButton("AutoSell").Activated:Fire()
assert(first.sellPhase=="CHEST_HANDOFF" and first.sellHandoffRecentTakeAll
    and first.sellHandoffTakeAllObserved
    and not helpers.canCollectDuringSell(),
    "recent Take All must stop further Chest reopen and be reused for sale")
first.sellPhaseAt=80
helpers.shopSellStep(82)
assert(first.sellPhase=="TELEPORT_OPEN" and first.takeAllActions==priorTakeAll
    and first.sellChestHandoffState=="RECENT_TAKE_ALL_REUSED",
    "reused closed Take All should permit Shops without another collection")
helpers.shopSellStep(84)
assert(first.sellPhase=="SHOPS_PICK" and teleClicks==teleBeforeRecent+1,
    "reuse must preserve normal Shops teleport")
findButton("SellDiagnostics").Activated:Fire()
assert(clipboard:find("reusedRecentTakeAll=true",1,true)
    and clipboard:find("lastTakeAllPlot=MinePlot5",1,true),
    "reuse diagnostic missing Take All plot/evidence")
findButton("AutoSell").Activated:Fire()
teleMenu.Visible=false

-- A just-fired Take All must still wait for its pending UI feedback.
local at=os.clock()
first.takeAllLastDispatchAt=at
first.takeAllLastDispatchPlot="MinePlot5"
first.takeAllPending={sentAt=at}
first.takeAllOutcome="NOT TESTED"
findButton("AutoSell").Activated:Fire()
assert(first.sellHandoffRecentTakeAll and first.sellHandoffTakeAllObserved
    and not helpers.canCollectDuringSell(),
    "pending same-plot Take All should count as already dispatched")
first.sellPhaseAt=90
helpers.shopSellStep(92)
assert(first.sellPhase=="CHEST_HANDOFF" and first.sellChestHandoffState=="TAKE_ALL_PENDING",
    "pending Take All must not allow early warp")
first.takeAllPending=nil
first.takeAllOutcome="CHEST_CLOSED_AFTER_TAKE_ALL (matches manual UI; inventory unknown)"
helpers.shopSellStep(94)
assert(first.sellPhase=="TELEPORT_OPEN", "settled pending Take All should release warp")
findButton("AutoSell").Activated:Fire()

-- Stale or another Plot's Take All cannot satisfy the handoff.
first.takeAllLastDispatchAt=os.clock()-20
first.takeAllLastDispatchPlot="MinePlot5"
local staleEligible=helpers.recentTakeAllForHandoff(os.clock())
assert(not staleEligible,"20-second-old Take All is not recent")
first.takeAllLastDispatchAt=os.clock()
first.takeAllLastDispatchPlot="MinePlot6"
local otherPlotEligible=helpers.recentTakeAllForHandoff(os.clock())
assert(not otherPlotEligible,"another plot's Take All may not be reused")
findButton("AutoSell").Activated:Fire()
assert(not first.sellHandoffRecentTakeAll and helpers.canCollectDuringSell(),
    "wrong-plot Take All must leave Auto Collect handoff armed")
findButton("AutoSell").Activated:Fire()

first.takeAllLastDispatchAt=0
first.takeAllLastDispatchPlot=nil
first.takeAllPending=nil
first.collect=false
first.selectedPlot=plotBeforeRecent

-- V0.14 REAL RUNTIME LOG: GingerbreadKeeper's SellPrompt opens a
-- visible MineGui/SellFrame/Content/SellButton with one MouseButton1Click
-- listener and EMPTY button text. That is the permitted context-specific
-- exception, never a generic Sell All or a wrong-panel SellButton.
local ginger=instance("Model")
ginger.Name="GingerbreadKeeper"
local stand=instance("Folder"); stand.Name="SellStand";stand.Parent=workspace
ginger.Parent=stand
local torso=instance("BasePart")
torso.Name="UpperTorso"; torso.Position=vector(578,0,0);torso.Parent=ginger
local realSellPrompt=instance("ProximityPrompt")
realSellPrompt.Name="SellPrompt";realSellPrompt.ActionText="Sell"
realSellPrompt.MaxActivationDistance=14;realSellPrompt.Parent=torso
local exactContent=instance("Frame")
exactContent.Name="Content";exactContent.Parent=sellScreen
local exactButton=instance("TextButton")
exactButton.Name="SellButton";exactButton.Text="";exactButton.Parent=exactContent
local exactClicks=0
exactButton.MouseButton1Click:Connect(function() exactClicks=exactClicks+1 end)
local wrongPanel=instance("Frame")
wrongPanel.Name="ShopFrame";wrongPanel.Parent=mineGui
local wrongContent=instance("Frame")
wrongContent.Name="Content";wrongContent.Parent=wrongPanel
local wrongSell=instance("TextButton")
wrongSell.Name="SellButton";wrongSell.Text="";wrongSell.Parent=wrongContent
local wrongClicks=0
wrongSell.MouseButton1Click:Connect(function() wrongClicks=wrongClicks+1 end)
oreSell.Visible=false
sellScreen.Visible=true
first.sell=true
first.sellPhase="SELL_MENU"
first.sellVendorPath="Workspace/SellItemsStand/SellItemsPrompt"
first.sellVendorAttempts=1
assert(not helpers.validatedSellStandSession()
       and not helpers.isExactSellStandButton(exactButton),
       "wrong vendor must not authorize a generic SellButton")
local noneWrong=helpers.oreSellButton()
assert(noneWrong==nil, "unverified vendor must not click generic SellButton")
first.sellVendorPath="Workspace/SellStand/GingerbreadKeeper/UpperTorso/SellPrompt"
first.sellVendorAttempts=0
assert(not helpers.validatedSellStandSession()
       and not helpers.isExactSellStandButton(exactButton),
       "being near the vendor without prompt interaction is insufficient")
first.sellVendorAttempts=1
assert(helpers.validatedSellStandSession()
       and helpers.isExactSellStandButton(exactButton),
       "verified vendor and exact GUI hierarchy must unlock SellButton")
local validButton,validCount,validMode=helpers.oreSellButton()
assert(validButton==exactButton and validCount==1 and validMode=="CONFIRMED_SELL_STAND",
       "must prefer only exact SellFrame/Content/SellButton at real vendor")
local beforeAll=genericSells
local exactBefore=exactClicks
first.sellSelectAllSent=false
first.sellPhase="SELL_MENU"
helpers.shopSellStep(25)
assert(first.sellPhase=="PAUSED" and exactClicks==exactBefore,
       "Seller must refuse to click SellButton without Select All")
first.sellPhase="SELECT_ALL"
first.sellPhaseAt=26
helpers.shopSellStep(27)
assert(first.sellPhase=="SELL_MENU" and selectClicks==2 and exactClicks==exactBefore,
       "real SellStand menu must dispatch Select All before SellButton")
helpers.shopSellStep(29)
assert(first.sellPhase=="RETURN_BASE_OPEN" and first.sellActionKind=="CONFIRMED_SELL_STAND"
       and exactClicks==exactBefore+1 and wrongClicks==0
       and genericSells==beforeAll and unrelatedSelectClicks==0,
       "SellButton should dispatch after Select All; never wrong-context or generic Sell All")
findButton("SellDiagnostics").Activated:Fire()
assert(clipboard:find("Last sale mode=CONFIRMED_SELL_STAND",1,true),
       "post-sale diagnostics must preserve last confirmed SellStand action mode")
local forbidden=instance("TextLabel")
forbidden.Name="ForbiddenSale";forbidden.Text="Sell Characters";forbidden.Parent=sellScreen
first.sellPhase="SELL_MENU"
assert(not helpers.isExactSellStandButton(exactButton),
       "non-ore sell control in SellFrame must block generic SellButton")
forbidden.Parent=nil

-- Missing Select All must pause before ANY sale.
first.sell=true
first.sellPhase="SELECT_ALL"
first.sellPhaseAt=30
first.sellSelectAllSent=false
local lastExact=exactClicks
selectAll.Parent=nil
helpers.shopSellStep(31)
assert(first.sellPhase=="SELECT_ALL" and exactClicks==lastExact,
       "missing Select All must wait without clicking Sell")
helpers.shopSellStep(46)
assert(first.sellPhase=="PAUSED" and exactClicks==lastExact,
       "missing Select All must pause; no silent Sell")
-- A Select All label inside a nested control is also supported.
local nestedSelect=instance("TextButton")
nestedSelect.Name="ActionButton";nestedSelect.Text="";nestedSelect.Parent=selectContent
local nestedLabel=instance("TextLabel")
nestedLabel.Name="Text";nestedLabel.Text="Select All";nestedLabel.Parent=nestedSelect
local nestedClicks=0
nestedSelect.MouseButton1Click:Connect(function() nestedClicks=nestedClicks+1 end)
first.sellPhase="SELECT_ALL"
local foundNested,nestedCount=helpers.sellSelectAllButton()
assert(foundNested==nestedSelect and nestedCount==1,
       "nested TextLabel Select All should be resolved within seller Content")
local duplicate=instance("TextButton")
duplicate.Name="SelectAllButton";duplicate.Parent=selectContent
duplicate.MouseButton1Click:Connect(function() error("ambiguous Select All must not click") end)
local beforeNested=nestedClicks
helpers.shopSellStep(47)
assert(first.sellPhase=="PAUSED" and nestedClicks==beforeNested and exactClicks==lastExact,
       "ambiguous Select All must pause with no button dispatched")
duplicate.Parent=nil
nestedSelect.Parent=nil
selectAll.Parent=selectContent
first.sell=false
first.sellPhase="OFF"
sellScreen.Visible=false

-- Regression: touch-only Sell Items stand (NO sell prompts anywhere).
-- Old V0.16 tests only checked entry to SELECT_ALL and missed that the
-- authorization required a prompt, blocking actual Select All / Sell.
sellPrompt.Parent=nil
realSellPrompt.Parent=nil
stand.Parent=nil
first.sell=true
first.sellPhase="VENDOR_WALK"
first.sellSent=false
first.sellVendorAttempts=0
first.sellVendorTouched=false
first.sellSelectAllSent=false
first.sellSelectAllCallsOK=0
first.sellSelectAllAt=0
oreSell.Visible=true
sellScreen.Visible=true
root.Position=vector(579,0,0)
local initialOreSells=oreSells
local initialSelectClicks=selectClicks
helpers.shopSellStep(24)
assert(first.sellPhase=="SELECT_ALL" and first.sellVendorTouched
       and first.sellVendorAttempts==0,
       "touch-only stand must be authorized by actual 3-stud marker approach, not a prompt")
helpers.shopSellStep(26)
assert(first.sellPhase=="SELL_MENU" and selectClicks==initialSelectClicks+1
       and not first.sellSent, "touch-only stand must click Select All before Sell")
helpers.shopSellStep(28)
assert(first.sellPhase=="RETURN_BASE_OPEN" and oreSells==initialOreSells+1
       and unrelatedSellOreClicks==0 and genericSells==beforeAll,
       "touch-only stand must finish explicit Sell Ores, never unrelated inventory sales")
first.sell=false
first.sellPhase="OFF"
root.Position=vector(0,0,0)
sellScreen.Visible=false

-- V0.22 timed farming: the simplified public UI exposes one Farm Cycle
-- toggle plus editable minutes. Legacy test-only controls are hidden.
env.timerTest = {}
env.timerTest.main = assert(playerGui:FindFirstChild("MyAnimeMineHub"):FindFirstChild("Main"))
env.timerTest.legacy = assert(env.timerTest.main:FindFirstChild("LegacyHiddenControls"))
env.timerTest.input = assert(env.timerTest.main:FindFirstChild("IntervalMinutes"))
assert(not env.timerTest.legacy.Visible
       and findButton("AutoUpgrade").Parent==env.timerTest.legacy
       and findButton("ManualWatch").Parent==env.timerTest.legacy
       and findButton("AutoCollect").Parent==env.timerTest.legacy,
       "unused Upgrade/Manual/old Collect buttons must be hidden from main UI")
assert(findButton("FarmCycle").Parent==env.timerTest.main
       and findButton("MinuteMinus").Parent==env.timerTest.main
       and findButton("MinutePlus").Parent==env.timerTest.main,
       "timed Farm and minute controls must be directly accessible")
assert(not first.cycleEnabled and first.cycleMinutes==5 and first.cyclePhase=="OFF",
       "timed Farm must begin OFF with a five-minute default")
env.timerTest.input.Text="2"
env.timerTest.input.FocusLost:Fire(false)
assert(first.cycleMinutes==2, "manual interval textbox must accept minutes")
findButton("MinutePlus").Activated:Fire()
assert(first.cycleMinutes==3 and env.timerTest.input.Text=="3",
       "minute plus must increment interval")
findButton("MinuteMinus").Activated:Fire()
assert(first.cycleMinutes==2 and env.timerTest.input.Text=="2",
       "minute minus must decrement interval")
env.timerTest.input.Text="oops"
env.timerTest.input.FocusLost:Fire(false)
assert(first.cycleMinutes==2 and env.timerTest.input.Text=="2",
       "invalid minutes must not change scheduled farming")
first.takeAllPending=nil
first.collect=false
first.sell=false
first.sellPhase="OFF"
first.selectedPlot="MinePlot7"
activeChest.Visible=false
findButton("FarmCycle").Activated:Fire()
assert(first.cycleEnabled and first.cyclePhase=="COLLECTING"
       and first.collect and first.walkToChest and first.cycleRun==1
       and helpers.canCollectDuringSell(),
       "enabling timed farm must start exactly one collection now")
first.takeAllActions=first.cycleCollectionBaseline+1
first.takeAllLastDispatchAt=120
first.takeAllLastDispatchPlot="MinePlot7"
first.takeAllOutcome="CHEST_CLOSED_AFTER_TAKE_ALL (matches manual UI; inventory unknown)"
first.takeAllPending={sentAt=120}
helpers.updateFarmCycle(121)
assert(first.cyclePhase=="COLLECTING" and not first.sell,
       "pending Take All cannot trigger Shops sale")
first.takeAllPending=nil
helpers.updateFarmCycle(122)
assert(first.cyclePhase=="SELLING" and first.sell
       and first.sellPhase=="CHEST_HANDOFF"
       and first.sellHandoffTakeAllObserved
       and not helpers.canCollectDuringSell()
       and first.cycleNextAt==240,
       "one settled Take All must arm Shops Sell once and schedule next collection 2min later")
helpers.updateFarmCycle(124)
assert(first.cyclePhase=="SELLING" and first.sellAttempts==0,
       "timed cycle may not accidentally restart another Sell")
helpers.finishVerifiedBaseReturn(40,130)
assert(first.cyclePhase=="WAITING" and not first.sell
       and first.sellReturnVerified and not helpers.canCollectDuringSell(),
       "verified return must enter WAITING instead of immediately opening Chest again")
helpers.updateFarmCycle(239)
assert(first.cyclePhase=="WAITING" and first.cycleRun==1,
       "scheduled Collect cannot begin before minute deadline")
env.timerTest.input.Text="3"
env.timerTest.input.FocusLost:Fire(false)
assert(first.cycleNextAt==300 and first.cycleMinutes==3,
       "changing minutes during WAITING must reschedule from last Take All")
helpers.updateFarmCycle(299)
assert(first.cyclePhase=="WAITING", "rescheduled interval must not fire early")
helpers.updateFarmCycle(300)
assert(first.cyclePhase=="COLLECTING" and first.cycleRun==2
       and helpers.canCollectDuringSell(),
       "after due time, a NEW Take All collection attempt must start")
first.cyclePhase="SELLING"
first.sell=true
first.sellPhase="PAUSED"
first.sellStage="Base return unverified"
helpers.updateFarmCycle(305)
assert(first.cyclePhase=="PAUSED" and first.cycleEnabled
       and not helpers.canCollectDuringSell(),
       "failed shop/Base route must pause timed farm and prevent unsafe Collect")
findButton("FarmCycle").Activated:Fire()
assert(not first.cycleEnabled and first.cyclePhase=="OFF"
       and not first.collect and not first.sell and helpers.canCollectDuringSell(),
       "switching timed farm OFF must stop all scheduled Collect/Sell routes")
env.timerTest.input.Text="5"
env.timerTest.input.FocusLost:Fire(false)

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
print("PASS My Anime Mine V0.22 timed Collect-Sell-Base cycles, interval UI and hidden legacy tools; existing seller regressions")
