-- Run from repository root with Lua 5.3+.
local file = assert(io.open("Games/StealAnEgg_Diagnostics.lua", "r"))
local source = file:read("*a"); file:close()
local engine = assert(source:match("%-%- AUTO_COLLECT_ENGINE_BEGIN(.-)%-%- AUTO_COLLECT_ENGINE_END"))
local function position(x,y,z)
    local mt = {}
    mt.__sub = function(a,b) return position(a.X-b.X,a.Y-b.Y,a.Z-b.Z) end
    mt.__add = function(a,b) return position(a.X+b.X,a.Y+b.Y,a.Z+b.Z) end
    mt.__mul = function(a,b) return position(a.X*b,a.Y*b,a.Z*b) end
    mt.__index = function(a,key)
        if key == "Magnitude" then return math.sqrt(a.X*a.X+a.Y*a.Y+a.Z*a.Z) end
        if key == "Unit" then local n=a.Magnitude; return position(a.X/n,a.Y/n,a.Z/n) end
    end
    return setmetatable({X=x,Y=y or 0,Z=z or 0},mt)
end
local root, humanoid = {Position = position(0),CFrame = position(0),Parent = {}}, {Health = 100,WalkSpeed = 16}
local carrying, clock, failInput = false, 10, false
local pg = {}
local drop = {Enabled = true, Parent = pg}
function drop:IsA(kind) return kind == "LayerCollector" end
local button = {Visible = true, Parent = drop}
function button:IsA(kind) return kind == "GuiObject" end
function drop:FindFirstChild() return button end
function pg:FindFirstChild() return carrying and drop or nil end
local character = {}
local equippedChildren = {}
local backpackChildren = {}
local backpack = {GetChildren=function() return backpackChildren end}
function character:GetChildren() return equippedChildren end
function character:FindFirstChild() return root end
function character:FindFirstChildOfClass() return humanoid end
local env = setmetatable({pg = pg, workspace = {}, player = {Character = character},
    active = true, busy = false, hatchRunning = false, collectRunning = false,
    collectEgg = {enabled = true, attempts = 0}, collectAttempts = {}, promptCache = {},
    os = {clock = function() return clock end, time = function() return 123 end},
    task = {wait = function() end}, promptPosition = function(p) return p.position end}, {__index = _G})
function env.player:FindFirstChildOfClass() return backpack end
env.typeof=function(v) return type(v)=="table" and v.__type or type(v) end
env.RaycastParams = {new=function() return {} end}
env.Vector3 = {new=position}
env.Enum = {RaycastFilterType={Exclude="Exclude"},EasingStyle={Linear="Linear"},PlaybackState={Playing="Playing",Completed="Completed",Cancelled="Cancelled"}}
env.TweenInfo = {new=function(duration) return {duration=duration} end}
env.collectLabel = {}
env.math = setmetatable({clamp=function(n,lo,hi) return math.max(lo,math.min(hi,n)) end},{__index=math})
local obstacle, movement, onWait, mockRoute, walkGoal, tweenCreated, plotFixture
function env.workspace:FindFirstChild(name) if name == "Plots" then return plotFixture end end
env.player.UserId=42;env.player.Name="TestPlayer"
function humanoid:MoveTo(goal) walkGoal=goal end
function env.workspace:Raycast(origin,delta)
    if type(obstacle) == "function" then return obstacle(origin,delta) and {} or nil end
    return obstacle and {} or nil
end
env.Enum.Material={Air="Air"}
env.Enum.PathStatus={Success="Success",NoPath="NoPath"}
env.Enum.PathWaypointAction={Walk="Walk",Jump="Jump"}
env.PathfindingService={CreatePath=function()
    return {Status=mockRoute and "Success" or "NoPath",ComputeAsync=function() end,
        GetWaypoints=function() return mockRoute end}
end}
env.TweenService = {Create=function(_,target,info,goal)
    tweenCreated=(tweenCreated or 0)+1
    local t = {target=target,goal=goal,info=info}
    function t:Play() self.PlaybackState="Playing"; movement=self end
    function t:Cancel() self.PlaybackState="Cancelled" end
    return t
end}
env.task.wait = function()
    clock=clock+0.1
    if onWait then onWait() end
    if walkGoal then root.Position=walkGoal;root.CFrame=walkGoal end
    if movement and movement.PlaybackState == "Playing" then
        root.Position,root.CFrame = movement.goal.CFrame,movement.goal.CFrame
        movement.PlaybackState="Completed"
    end
end
env.placeState={enabled=false,slots={},attempts=0,observed=0};env.upgrades={mode="Off",observed=0,lastAction=-math.huge};env.training={enabled=false,last="OFF",events=0};env.AUTO_PLACE_ENABLED=true;env.hatch={enabled=true,last=""};env.hatchLabel={};env.attemptState={}
local eligibleSource=assert(source:match("(local function eligible.-)\nlocal function hatchStep"))
env.eligible=assert(load(eligibleSource.."\nreturn eligible","hatch-eligible","t",env))()
local funcs = assert(load(engine .. "\nreturn {candidate=collectCandidate,approach=approachCandidate,cancel=cancelCollectTween,step=collectStep,dispatch=dispatchCollect,snapshot=collectSnapshot,mark=setManualCarry,inventory=eggInventory,diff=newInventoryEggs,home=setDeliveryPoint,returnHome=returnHome,navigate=pathMove,record=recordGameEvent,updateCarry=updateServerCarry,resetServer=function() serverCarry=nil;lastRedeem=nil end,resolveHome=resolveAutoHome,inspectBase=inspectOwnedBase,hatchOwned=hatchOwned,hatchApproach=hatchApproach,recover=recoverWalking,bindPlace=addPlacementSlot,selectPlaceEgg=selectPlacementEgg,uidGone=placementUIDGone,place=placeStep,autoMark=autoMarkSlots,emptySlot=emptySlotEvidence,placeRay=placementRaycast,vacancies=areaVacancies,cost=parseSoftCost,cash=readCash,upgrade=upgradeStep,train=trainingStep,manualPlace=prepareManualPlacement}", "collect-engine", "t", env))()
local hatchSource=assert(source:match("(local function hatchStep.-)\nconnections%["))
local runHatch=assert(load(hatchSource.."\nreturn hatchStep", "hatch-step", "t", env))()
local function prompt(distance)
    local p = {Parent = {}, Name = "CarryAreaEgg", ActionText = "Steal", ObjectText = "Egg",
        Enabled = true, HoldDuration = 0, MaxActivationDistance = 8, position = position(distance), began = 0, ended = 0}
    function p:IsDescendantOf(w) return self.Parent ~= nil and w == env.workspace end
    function p:GetFullName() return "Workspace.SmartPromptPart.CarryAreaEgg" end
    function p:InputHoldBegin() self.began = self.began + 1; if failInput then error("mock failure") end end
    function p:InputHoldEnd() self.ended = self.ended + 1 end
    return p
end
local function reset()
    env.hatch.enabled=true;env.hatch.attempts=0;env.hatch.lastAttempt=nil;env.attemptState={}
    env.placeState={enabled=false,slots={},attempts=0,observed=0}
    env.upgrades={mode="Off",observed=0,lastAction=-math.huge};env.training={enabled=false,last="OFF",events=0}
    env.AUTO_PLACE_ENABLED=true
    env.frame=nil;env.restore=nil;env.holding=nil;env.hatchWalking=nil;env.systemRunning=false;env.placeRunning=false
    funcs.mark(false)
    funcs.resetServer()
    equippedChildren,backpackChildren = {},{}
    function character:GetChildren() return equippedChildren end
    env.promptCache, env.collectAttempts = {}, {}
    env.collectEgg = {enabled = true, attempts = 0, approachMode="Tween"}
    env.active, env.busy, env.hatchRunning = true, false, false
    carrying, failInput, clock = false, false, 10
    humanoid.Health = 100
    humanoid.Jump=false;humanoid.Sit=false;humanoid.FloorMaterial="Ground"
    root.Position,root.CFrame = position(0),position(0)
    obstacle,movement,onWait,mockRoute,walkGoal,tweenCreated = false,nil,nil,nil,nil,0
    env.collectRunning=false
    plotFixture=nil
    funcs.home(nil)
end
local tests = 0
local function check(name, fn) reset(); fn(); tests = tests + 1; print("PASS " .. name) end
check("reject disabled, unrelated and distant prompts", function()
    local p = prompt(4)
    p.Enabled = false; assert(funcs.candidate(p,root,humanoid) == nil)
    p.Enabled = true; p.ActionText = "Apply Mutation"; assert(funcs.candidate(p,root,humanoid) == nil)
    p.ActionText = "Steal"; p.Name = "Other"; assert(funcs.candidate(p,root,humanoid) == nil)
    p.Name = "CarryAreaEgg"; p.position = position(9); assert(funcs.candidate(p,root,humanoid) == nil)
    p.position = position(5); p.MaxActivationDistance = 3; assert(funcs.candidate(p,root,humanoid) == nil)
end)
check("reject dead character and unsupported hold", function()
    local p = prompt(4); humanoid.Health = 0; assert(funcs.candidate(p,root,humanoid) == nil)
    humanoid.Health = 100
    humanoid.Jump=false;humanoid.Sit=false;humanoid.FloorMaterial="Ground"; p.HoldDuration = 6; assert(funcs.candidate(p,root,humanoid) == nil)
end)
check("choose closest egg and preserve input record", function()
    local a,b = prompt(6),prompt(2); env.promptCache[a],env.promptCache[b] = true,true
    funcs.dispatch(); assert(a.began == 0 and b.began == 1 and b.ended == 1)
    assert(env.collectEgg.attempts == 1 and env.collectEgg.lastInput.distance == 2)
    assert(env.collectEgg.lastInput.status == "Input sent; pickup unverified")
end)
check("pause when carrying, scanning, OFF or hatch busy", function()
    local p=prompt(2); env.promptCache[p] = true
    carrying=true; funcs.dispatch(); carrying=false
    env.busy=true; funcs.dispatch(); env.busy=false
    env.collectEgg.enabled=false; funcs.dispatch(); env.collectEgg.enabled=true
    env.hatchRunning=true; funcs.dispatch(); env.hatchRunning=false
    env.active=false; funcs.dispatch(); assert(p.began == 0)
end)
check("cooldown and three attempt limit", function()
    local p=prompt(2); env.promptCache[p]=true
    funcs.dispatch(); funcs.dispatch(); assert(p.began == 1)
    env.collectEgg.enabled=true; clock=14; funcs.dispatch()
    env.collectEgg.enabled=true; clock=18; funcs.dispatch()
    env.collectEgg.enabled=true; clock=22; funcs.dispatch()
    assert(p.began == 3 and env.collectEgg.attempts == 3)
end)
check("failed input releases hold and records error", function()
    local p=prompt(2); env.promptCache[p]=true; failInput=true
    funcs.dispatch(); assert(p.ended == 1 and env.holding == nil and env.collectRunning == false)
    assert(env.collectEgg.lastInput.status == "Input failed" and env.collectEgg.lastInput.error)
end)
check("hidden carry UI does not block pickup", function()
    carrying=true; button.Visible=false
    assert(funcs.snapshot().carrying == false)
    button.Visible=true; assert(funcs.snapshot().carrying == true)
    drop.Enabled=false; assert(funcs.snapshot().carrying == false); drop.Enabled=true
end)
check("Tween arrives before sending pickup input", function()
    local p=prompt(40); env.promptCache[p]=true
    funcs.dispatch()
    assert(movement and movement.info.duration > 0)
    assert(p.began == 1 and root.Position.X > 30)
    assert(env.collectEgg.lastMovement.status == "In pickup range")
    assert(env.collectEgg.moving == false)
end)
check("wall blocks Tween and pickup", function()
    local p=prompt(40); env.promptCache[p]=true; obstacle=true
    funcs.dispatch(); assert(not movement and p.began == 0)
end)
check("OFF during movement cancels without pickup", function()
    local p=prompt(40); env.promptCache[p]=true
    onWait=function() env.collectEgg.enabled=false; funcs.cancel("Collect OFF") end
    funcs.dispatch(); assert(movement.PlaybackState == "Cancelled" and p.began == 0)
end)
check("skip distant and other-floor eggs", function()
    local p=prompt(251); assert(funcs.approach(p,root,humanoid) == nil)
    p.position=position(20,7,0); assert(funcs.approach(p,root,humanoid) == nil)
end)
check("approach disabled prompt without pressing it", function()
    local p=prompt(75); p.Enabled=false; env.promptCache[p]=true
    funcs.dispatch()
    assert(movement and root.Position.X > 65 and p.began == 0)
    assert(env.collectEgg.lastMovement.status == "In range; waiting for game to enable prompt")
    assert(env.collectEgg.attempts == 0)
    p.Enabled=true; funcs.dispatch(); assert(p.began == 1)
end)
check("disabled prompt nearby waits without input or movement", function()
    local p=prompt(3); p.Enabled=false; env.promptCache[p]=true
    funcs.dispatch(); assert(not movement and p.began == 0)
    assert(env.collectEgg.last == "In range; waiting for game to enable prompt")
end)
check("wait for delayed carry UI before choosing another egg", function()
    local p=prompt(3); env.promptCache[p]=true
    local waits=0
    onWait=function() waits=waits+1; if waits == 3 then carrying=true end end
    funcs.dispatch()
    assert(waits >= 3 and env.collectEgg.lastInput.carryVisibleAfter)
    assert(env.collectEgg.unconfirmed == 0 and p.began == 1)
end)
check("pause after one unconfirmed input", function()
    local p=prompt(3); env.promptCache[p]=true
    funcs.dispatch()
    assert(env.collectEgg.enabled == false and env.collectEgg.unconfirmed == 1)
    assert(env.collectEgg.pausedReason and p.began == 1)
    clock=clock+4; funcs.dispatch(); assert(p.began == 1)
end)
check("manual carry marker stops pickup despite hidden GUI", function()
    local p=prompt(3); env.promptCache[p]=true
    funcs.mark(true)
    assert(funcs.snapshot().carrying == true and env.collectEgg.enabled == false)
    env.collectEgg.enabled=true; funcs.dispatch(); assert(p.began == 0)
    funcs.mark(false); assert(funcs.snapshot().carrying == false)
end)
check("manual carry marker cancels active movement", function()
    local p=prompt(40); env.promptCache[p]=true
    onWait=function() funcs.mark(true) end
    funcs.dispatch()
    assert(movement.PlaybackState == "Cancelled" and p.began == 0)
end)
check("export reads character evidence independently of GUI scan", function()
    function character:GetChildren() return {{Name="ObservedObject", ClassName="Model", IsA=function() return false end}} end
    function character:GetDescendants() return {} end
    function character:GetAttributes() return {SampleState="held"} end
    local e=funcs.snapshot(true).carryEvidence
    assert(e and e.characterAttributes.SampleState == "held")
    assert(e.characterChildren[1].name == "ObservedObject")
    assert(e.manualMarker == false)
end)
local function eggTool(kind)
    return {Name="Raccoon Egg",IsA=function(_,class) return class == "Tool" end,
        GetAttribute=function(_,key) if key == "ItemType" then return kind elseif key == "UID" then return "sample-egg-id" end end}
end
check("detect equipped AssetEgg with hidden drop GUI", function()
    equippedChildren={eggTool("AssetEgg")}
    local snapshot=funcs.snapshot()
    assert(snapshot.carrying and snapshot.carryState.equippedEgg)
    assert(snapshot.carryState.source == "equipped_asset_egg" and not snapshot.carryState.fieldCarryUI)
    assert(snapshot.carryState.pickupVerified == false)
    local p=prompt(3); env.promptCache[p]=true; funcs.dispatch(); assert(p.began == 0)
end)
check("do not mistake another Tool for an egg", function()
    equippedChildren={eggTool("Weapon")}
    assert(funcs.snapshot().carrying == false)
end)
check("unequipping egg clears automatic holding state", function()
    equippedChildren={eggTool("AssetEgg")}; assert(funcs.snapshot().carrying)
    equippedChildren={}; assert(not funcs.snapshot().carrying)
end)
check("equipping egg during Tween stops before pickup", function()
    local p=prompt(40); env.promptCache[p]=true
    onWait=function() equippedChildren={eggTool("AssetEgg")} end
    funcs.dispatch(); assert(p.began == 0 and not env.collectEgg.moving)
end)
check("new backpack egg UID observed after input", function()
    local p=prompt(3); env.promptCache[p]=true
    onWait=function() backpackChildren={eggTool("AssetEgg")} end
    funcs.dispatch()
    assert(env.collectEgg.lastInput.inventoryAdded[1].uid == "sample-egg-id")
    assert(env.collectEgg.inventoryAdditionsObserved == 1 and env.collectEgg.unconfirmed == 0)
end)
check("moving an existing egg between containers is not acquisition", function()
    local egg=eggTool("AssetEgg"); backpackChildren={egg}
    local before=funcs.inventory(); backpackChildren={}; equippedChildren={egg}
    assert(#funcs.diff(before,funcs.inventory()) == 0)
end)
check("non-egg tools never count as inventory additions", function()
    local before=funcs.inventory(); backpackChildren={eggTool("Weapon")}
    assert(#funcs.diff(before,funcs.inventory()) == 0)
end)
check("unknown UID suppresses inventory acquisition claims", function()
    local unknown=eggTool("AssetEgg")
    function unknown:GetAttribute(key) if key == "ItemType" then return "AssetEgg" end end
    backpackChildren={unknown}; local before=funcs.inventory()
    backpackChildren={eggTool("AssetEgg")}
    assert(not before.complete and #funcs.diff(before,funcs.inventory()) == 0)
end)
check("field egg without delivery point pauses instead of wandering", function()
    carrying=true
    funcs.dispatch()
    assert(not movement and env.collectEgg.enabled == false)
    assert(env.collectEgg.pausedReason:find("delivery point",1,true))
end)
check("return to configured home and observe inventory delivery", function()
    funcs.home(position(40)); carrying=true
    env.collectEgg.tripInventory=funcs.inventory()
    onWait=function()
        if walkGoal then carrying=false; backpackChildren={eggTool("AssetEgg")} end
    end
    funcs.dispatch()
    assert(root.Position.X == 40 and env.collectEgg.deliveriesObserved == 1)
    assert(env.collectEgg.phase == "SEEKING" and env.collectEgg.enabled)
end)
check("carry clearing away from home is not delivery", function()
    funcs.home(position(40)); carrying=true
    env.collectEgg.tripInventory=funcs.inventory()
    onWait=function()
        carrying=false
        if walkGoal then walkGoal=position(20) end
    end
    funcs.dispatch()
    assert(not env.collectEgg.deliveriesObserved and not env.collectEgg.enabled)
    assert(env.collectEgg.lastReturn.status == "Game no longer reports field egg carrying")
end)
check("return blocked by wall pauses with no delivery claim", function()
    funcs.home(position(40)); carrying=true; obstacle=true
    funcs.dispatch()
    assert(not movement and not env.collectEgg.enabled and not env.collectEgg.deliveriesObserved)
    assert(env.collectEgg.lastReturn.status == "No ground return path")
end)
check("arrival without game accepting egg pauses", function()
    funcs.home(position(40)); carrying=true
    funcs.dispatch()
    assert(root.Position.X == 40 and not env.collectEgg.enabled)
    assert(env.collectEgg.lastReturn.status == "Home reached but game did not accept the egg")
end)
check("changing home during movement is rejected", function()
    funcs.home(position(40)); env.collectRunning=true
    local ok=funcs.home(position(20)); assert(not ok)
end)
local function detour(endX)
    return {{Position=position(0),Action="Walk"},{Position=position(0,0,10),Action="Walk"},
        {Position=position(endX,0,10),Action="Walk"},{Position=position(endX),Action="Walk"}}
end
check("pathfinding detours around a blocked straight approach", function()
    local p=prompt(40);env.promptCache[p]=true
    obstacle=function(_,delta) return delta.Magnitude>10 end
    mockRoute=detour(35)
    funcs.dispatch()
    assert(p.began == 1 and root.Position.X == 35)
    assert(env.collectEgg.lastNavigation.completed == 4)
end)
check("pathfinding returns home around a blocked straight line", function()
    funcs.home(position(40));carrying=true;env.collectEgg.tripInventory=funcs.inventory()
    obstacle=function(_,delta) return delta.Magnitude>10 end
    mockRoute=detour(40)
    onWait=function()
        if walkGoal and walkGoal.X==40 and walkGoal.Z==0 then
            carrying=false;backpackChildren={eggTool("AssetEgg")}
        end
    end
    funcs.dispatch()
    assert(env.collectEgg.deliveriesObserved == 1 and env.collectEgg.lastNavigation.completed == 4)
end)
check("route cancellation prevents successful arrival result", function()
    mockRoute=detour(40)
    onWait=function() env.collectEgg.enabled=false end
    local ok,reason=funcs.navigate(root,humanoid,character,position(40),false)
    assert(not ok and reason == "Route cancelled")
end)
check("no path result is reported without movement", function()
    local ok,reason=funcs.navigate(root,humanoid,character,position(40),false)
    assert(not ok and reason:find("No path",1,true) and not movement)
end)
check("game event trace preserves primitive payload and phase", function()
    env.collectEgg.phase="RETURNING"
    funcs.record("RE/EggWorld/FieldEggCarry",true,"egg-uid",123)
    local log=funcs.snapshot().gameEvents;local last=log[#log]
    assert(last.name == "RE/EggWorld/FieldEggCarry" and last.args[1] == true and last.args[2] == "egg-uid")
    assert(last.phase == "RETURNING" and last.position)
end)
check("game event trace is bounded to sixteen entries", function()
    for i=1,40 do funcs.record("mock",i) end
    local log=funcs.snapshot().gameEvents
    assert(#log == 16 and log[1].args[1] == 25 and log[16].args[1] == 40)
end)
check("event payload cycles and long strings are bounded", function()
    local cycle={};cycle.self=cycle
    funcs.record("mock",cycle,string.rep("x",1000))
    local log=funcs.snapshot().gameEvents;local last=log[#log]
    assert(last.args[1].self == "<cycle>" and #last.args[2] == 180)
end)
check("observed carry event overrides a stale visible GUI", function()
    carrying=true
    funcs.updateCarry({IsCarrying=false,SpeedMultiplier=1})
    local state=funcs.snapshot().carryState
    assert(state.fieldCarryUI and not state.fieldCarrying and not state.blocked)
end)
check("carry event detects held field egg before UI updates", function()
    funcs.updateCarry({IsCarrying=true,Uid="field-egg",RunBackWakeDelayRequired=true})
    local state=funcs.snapshot().carryState
    assert(state.fieldCarrying and state.serverCarrying and state.source == "field_carry_event")
    assert(not state.fieldCarryUI and state.fieldEggUid == "field-egg")
end)
check("native home return creates no CFrame Tween", function()
    funcs.home(position(40));carrying=true;env.collectEgg.tripInventory=funcs.inventory()
    onWait=function() if walkGoal then carrying=false;backpackChildren={eggTool("AssetEgg")} end end
    funcs.dispatch()
    assert(tweenCreated == 0 and env.collectEgg.deliveriesObserved == 1)
    assert(env.collectEgg.lastNavigation.mode == "Humanoid.MoveTo")
end)
check("invalid carry payload cannot overwrite known server state", function()
    funcs.updateCarry({IsCarrying=true,Uid="field-egg"})
    funcs.updateCarry({IsCarrying="false"})
    assert(funcs.snapshot().carryState.serverCarrying == true)
end)
check("cancelling native walking stops before delivery", function()
    funcs.home(position(40));carrying=true
    onWait=function() env.collectEgg.enabled=false;funcs.cancel("Collect OFF") end
    funcs.dispatch()
    assert(tweenCreated == 0 and not env.collectEgg.deliveriesObserved)
    assert(env.collectEgg.lastNavigation.status == "Return cancelled")
end)
check("server carry state does not survive character replacement", function()
    funcs.updateCarry({IsCarrying=true})
    env.player.Character={GetChildren=function() return {} end,FindFirstChild=function() return nil end,FindFirstChildOfClass=function() return nil end}
    assert(not funcs.snapshot().carryState.serverCarrying)
    env.player.Character=character
end)
check("pickup starts native return inside the same dispatch", function()
    funcs.home(position(40))
    local p=prompt(3);env.promptCache[p]=true
    onWait=function()
        if walkGoal then
            carrying=false;funcs.updateCarry({IsCarrying=false})
            backpackChildren={eggTool("AssetEgg")}
        else
            carrying=true;funcs.updateCarry({IsCarrying=true,Uid="field-egg"})
        end
    end
    funcs.dispatch()
    assert(env.collectEgg.lastReturn and env.collectEgg.deliveriesObserved == 1)
    assert(env.collectEgg.lastReturn.confirmationToReturnMs <= 1)
    assert(env.collectEgg.lastInput.returnDispatchedClock)
end)
local function node(name,class,attrs,children)
    local obj={Name=name,ClassName=class,Position=position(80),children=children or {},attrs=attrs or {},Visible=true,Enabled=true,Active=true}
    function obj:IsDescendantOf(root) local n=self.Parent;while n do if n==root then return true end;n=n.Parent end;return false end
    for _,child in ipairs(obj.children) do child.Parent=obj end
    function obj:GetChildren() return self.children end
    function obj:FindFirstChild(name) for _,v in ipairs(self.children) do if v.Name==name then return v end end end
    function obj:GetAttribute(key) return self.attrs[key] end
    function obj:GetAttributes() return self.attrs end
    function obj:GetFullName() return "Workspace.Plots."..self.Name end
    function obj:IsA(kind) return kind==self.ClassName or kind=="GuiButton" and (self.ClassName=="ImageButton" or self.ClassName=="TextButton") or kind=="GuiObject" and (self.ClassName=="ImageButton" or self.ClassName=="TextButton" or self.ClassName=="TextLabel" or self.ClassName=="Frame") or kind=="LayerCollector" and self.ClassName=="SurfaceGui" or kind=="BasePart" and (self.ClassName=="Part" or self.ClassName=="SpawnLocation") end
    return obj
end
check("auto home selects owned plot delivery before spawn", function()
    local delivery=node("DeliveryPoint","Part")
    local own=node("3","Model",{OwnerUserId=42},{delivery,node("Spawn","SpawnLocation")})
    local other=node("1","Model",{OwnerUserId=99},{node("DeliveryPoint","Part")})
    plotFixture=node("Plots","Folder",nil,{other,own})
    local point,plot,target,report=funcs.resolveHome()
    assert(point and plot==own and target==delivery and report.kind == "delivery_candidate")
end)
check("auto home never chooses an unowned nearest plot", function()
    plotFixture=node("Plots","Folder",nil,{node("1","Model",{}, {node("Spawn","SpawnLocation")})})
    local point,_,_,report=funcs.resolveHome()
    assert(not point and report.reason:find("confirmed local ownership",1,true))
end)
check("auto home refuses ambiguous owner matches", function()
    plotFixture=node("Plots","Folder",nil,{node("1","Model",{OwnerId=42}),node("2","Model",{OwnerId=42})})
    local point,_,_,report=funcs.resolveHome()
    assert(not point and report.reason:find("More than one",1,true))
end)
check("auto home supports explicit owner value and spawn fallback", function()
    local owner=node("Owner","ObjectValue");owner.Value=env.player
    local spawn=node("Spawn","SpawnLocation")
    plotFixture=node("Plots","Folder",nil,{node("2","Model",{}, {owner,spawn})})
    local point,_,target,report=funcs.resolveHome()
    assert(point and target==spawn and report.kind == "spawn_fallback")
end)
check("auto home refuses several candidate delivery points", function()
    plotFixture=node("Plots","Folder",nil,{node("2","Model",{OwnerUserId=42},
        {node("DeliveryPoint","Part"),node("DeliveryZone","Part")})})
    local point=funcs.resolveHome();assert(not point)
end)
check("auto home reads exact username on observed PlotSign", function()
    local text=node("OwnerLabel","TextLabel");text.Text="<b>@TestPlayer</b>'s Base"
    local own=node("3","Model",{}, {node("PlotSign","Part",{}, {text}),node("SpawnPoint","Part")})
    plotFixture=node("Plots","Folder",{}, {own})
    local point,plot,_,report=funcs.resolveHome()
    assert(point and plot==own and report.ownerEvidence == "PlotSign exact username")
end)
check("plot sign does not match username substrings", function()
    local text=node("OwnerLabel","TextLabel");text.Text="TestPlayer123's Base"
    plotFixture=node("Plots","Folder",{}, {node("3","Model",{}, {node("PlotSign","Part",{}, {text}),node("SpawnPoint","Part")})})
    assert(not funcs.resolveHome())
end)
check("explicit other owner overrides stale matching sign", function()
    local text=node("OwnerLabel","TextLabel");text.Text="TestPlayer"
    plotFixture=node("Plots","Folder",{}, {node("3","Model",{OwnerUserId=99}, {node("PlotSign","Part",{}, {text}),node("SpawnPoint","Part")})})
    assert(not funcs.resolveHome())
end)
check("redeem event plus new UID completes before spawn", function()
    funcs.home(position(40));carrying=true
    env.collectEgg.tripInventory=funcs.inventory();env.collectEgg.tripStartedClock=clock
    onWait=function()
        if walkGoal then
            walkGoal=position(20);carrying=false;backpackChildren={eggTool("AssetEgg")}
            funcs.record("RE/EggWorld/FieldEggRedeemVerdict",{DisplayName="Raccoon Egg"})
        end
    end
    funcs.dispatch()
    assert(root.Position.X==20 and env.collectEgg.deliveriesObserved==1 and env.collectEgg.enabled)
    assert(env.collectEgg.phase=="SEEKING")
end)
check("redeem event without new UID does not claim delivery", function()
    funcs.home(position(40));carrying=true
    env.collectEgg.tripInventory=funcs.inventory();env.collectEgg.tripStartedClock=clock
    onWait=function()
        if walkGoal then walkGoal=position(20);carrying=false end
        funcs.record("RE/EggWorld/FieldEggRedeemVerdict",{DisplayName="Raccoon Egg"})
    end
    funcs.dispatch();assert(not env.collectEgg.deliveriesObserved and not env.collectEgg.enabled)
end)
check("base inspection only reads the uniquely owned plot", function()
    local tile=node("CashTile","Part",{Cash=100},{node("TouchInterest","TouchTransmitter")})
    local own=node("3","Model",{OwnerUserId=42},{node("SpawnPoint","Part"),tile})
    local other=node("1","Model",{OwnerUserId=99},{node("OtherCashTile","Part")})
    plotFixture=node("Plots","Folder",{}, {own,other})
    local report=funcs.inspectBase()
    assert(report.found and #report.touchParts==1)
    assert(report.touchParts[1].name == "CashTile" and report.touchParts[1].attributes.Cash == 100)
end)
check("base inspection refuses unknown ownership", function()
    plotFixture=node("Plots","Folder",{}, {node("3","Model",{}, {node("CashTile","Part")})})
    local report=funcs.inspectBase();assert(not report.found and #report.touchParts==0)
end)
check("walk approach reaches egg without creating CFrame tween", function()
    env.collectEgg.approachMode="Walk"
    local p=prompt(40);env.promptCache[p]=true
    funcs.dispatch()
    assert(tweenCreated==0 and p.began==1 and root.Position.X>30)
end)
check("walk approach stops when disabled", function()
    env.collectEgg.approachMode="Walk"
    local p=prompt(40);env.promptCache[p]=true
    onWait=function() env.collectEgg.enabled=false;funcs.cancel("Collect OFF") end
    funcs.dispatch();assert(p.began==0 and tweenCreated==0)
end)
check("auto hatch excludes another plot's ready egg", function()
    local ownCenter=node("CenterPoint","Part");ownCenter.Position=position(40)
    local own=node("1","Model",{OwnerUserId=42},{ownCenter,node("SpawnPoint","Part")})
    local other=node("2","Model",{OwnerUserId=99},{node("CenterPoint","Part")})
    plotFixture=node("Plots","Folder",{}, {own,other})
    local ready=prompt(80);ready.ActionText="Hatch!"
    assert(not funcs.hatchOwned(ready,own))
    ready.position=position(40);assert(funcs.hatchOwned(ready,own))
end)
check("auto hatch walks to a ready egg in own plot", function()
    local center=node("CenterPoint","Part");center.Position=position(40)
    plotFixture=node("Plots","Folder",{}, {node("1","Model",{OwnerUserId=42},{center,node("SpawnPoint","Part")})})
    local ready=prompt(40);ready.ActionText="Hatch!";env.promptCache[ready]=true
    local ok=funcs.hatchApproach(root,humanoid,character)
    assert(ok and root.Position.X>=33 and tweenCreated==0)
end)
check("auto hatch cancels native approach when switched off", function()
    local center=node("CenterPoint","Part");center.Position=position(40)
    plotFixture=node("Plots","Folder",{}, {node("1","Model",{OwnerUserId=42},{center,node("SpawnPoint","Part")})})
    local ready=prompt(40);ready.ActionText="Hatch!";env.promptCache[ready]=true
    onWait=function() env.hatch.enabled=false end
    assert(not funcs.hatchApproach(root,humanoid,character))
end)
check("auto hatch rejects unknown ownership", function()
    local ready=prompt(3);ready.ActionText="Hatch!";env.promptCache[ready]=true
    assert(not funcs.hatchApproach(root,humanoid,character))
end)
check("stuck walking jumps out and repeats MoveTo", function()
    local state={origin=root.Position,checked=clock,lastJump=-math.huge,attempts=0}
    humanoid.Sit=true;clock=clock+1.2
    assert(not funcs.recover(state,root,humanoid,position(40)))
    assert(humanoid.Jump and not humanoid.Sit and state.attempts==1 and walkGoal.X==40)
end)
check("unstick jump is rate limited and capped", function()
    local state={origin=root.Position,checked=clock,lastJump=-math.huge,attempts=0}
    clock=clock+1.2;funcs.recover(state,root,humanoid,position(40))
    clock=clock+0.5;funcs.recover(state,root,humanoid,position(40));assert(state.attempts==1)
    clock=clock+1.6;funcs.recover(state,root,humanoid,position(40));assert(state.attempts==2)
    clock=clock+2.1;assert(funcs.recover(state,root,humanoid,position(40)))
end)
check("walking progress and airborne character do not trigger jumping", function()
    local state={origin=root.Position,checked=clock,lastJump=-math.huge,attempts=0}
    clock=clock+1.2;root.Position=position(2)
    funcs.recover(state,root,humanoid,position(40));assert(not humanoid.Jump)
    humanoid.FloorMaterial="Air";clock=clock+2
    funcs.recover(state,root,humanoid,position(40));assert(not humanoid.Jump and state.attempts==0)
end)
check("placement binds only parts in confirmed owned plot", function()
    local slot=node("EmptySlot","Part")
    local own=node("1","Model",{OwnerUserId=42},{node("SpawnPoint","Part"),slot})
    plotFixture=node("Plots","Folder",{}, {own})
    local ok=funcs.bindPlace(slot,position(80));assert(ok and #env.placeState.slots==1)
    assert(not funcs.bindPlace(node("ForeignSlot","Part"),position(120)))
end)
check("placement rejects duplicate marked slot positions", function()
    local slot=node("Floor","Part")
    plotFixture=node("Plots","Folder",{}, {node("1","Model",{OwnerUserId=42},{node("SpawnPoint","Part"),slot})})
    assert(funcs.bindPlace(slot,position(80)))
    assert(not funcs.bindPlace(slot,position(81)))
end)
check("placement selects only inventory AssetEgg tools", function()
    backpackChildren={eggTool("Weapon"),eggTool("AssetEgg")}
    local selected=funcs.selectPlaceEgg()
    assert(selected and selected.uid=="sample-egg-id")
end)
check("placement never treats unequipping as UID removal", function()
    local egg=eggTool("AssetEgg");equippedChildren={egg}
    assert(not funcs.uidGone("sample-egg-id"))
    equippedChildren={};backpackChildren={egg};assert(not funcs.uidGone("sample-egg-id"))
    backpackChildren={};assert(funcs.uidGone("sample-egg-id"))
end)
local function setupPlaceClick(fail)
    root.Position=position(80)
    local slot=node("EmptySlot","Part")
    plotFixture=node("Plots","Folder",{}, {node("1","Model",{OwnerUserId=42},{node("SpawnPoint","Part"),slot})})
    assert(funcs.bindPlace(slot,position(80)))
    env.placeState.enabled=true
    local egg=eggTool("AssetEgg");backpackChildren={egg}
    function humanoid:EquipTool(tool) equippedChildren={tool};backpackChildren={};tool.Parent=character end
    env.Enum.CameraType={Scriptable="Scriptable"}
    local originalFrame={Position=position(0,12,12)}
    local camera={CameraType="Custom",CFrame=originalFrame,WorldToScreenPoint=function() return position(100,100,1),true end}
    env.workspace.CurrentCamera=camera
    env.CFrame={lookAt=function(eye) return {Position=eye} end}
    local clicks=0
    env.game={GetService=function()
        return {SendMouseMoveEvent=function() end,SendMouseButtonEvent=function(_,x,y,button,down)
            if fail then error("mock input unsupported") end
            if down then clicks=clicks+1 else equippedChildren={};egg.Parent=nil end
        end}
    end}
    return camera,originalFrame,function() return clicks end,egg
end
check("placement clicks once and restores camera after UID removal", function()
    local camera,original,clicks=setupPlaceClick(false)
    funcs.place()
    assert(clicks()==1 and env.placeState.observed==1)
    assert(camera.CFrame==original and camera.CameraType=="Custom")
    funcs.place();assert(clicks()==1)
end)
check("placement input failure restores camera and stops retries", function()
    local camera,original=setupPlaceClick(true)
    funcs.place()
    assert(not env.placeState.enabled and env.placeState.lastAttempt.inputOK==false)
    assert(camera.CFrame==original and camera.CameraType=="Custom")
    assert(env.placeState.slots[1].used)
end)
check("auto mark uses explicit empty slots only", function()
    local empty=node("Slot1","Part",{IsEmpty=true})
    local occupied=node("Slot2","Part",{Occupied=true});occupied.Position=position(90)
    local unknown=node("Slot3","Part");unknown.Position=position(100)
    local own=node("1","Model",{OwnerUserId=42},{node("SpawnPoint","Part"),empty,occupied,unknown})
    plotFixture=node("Plots","Folder",{}, {own})
    local ok=funcs.autoMark(false)
    assert(ok and #env.placeState.slots==1 and env.placeState.slots[1].part==empty)
end)
check("auto mark rejects conflicting or occupied UID evidence", function()
    assert(not funcs.emptySlot(node("Slot1","Part",{Empty=true,Occupied=true})))
    assert(not funcs.emptySlot(node("Slot2","Part",{Empty=true,EggUID="occupied-id"})))
    assert(not funcs.emptySlot(node("Floor","Part",{Empty=true})))
end)
check("auto mark never includes another player's slot", function()
    local own=node("1","Model",{OwnerUserId=42},{node("SpawnPoint","Part")})
    local other=node("2","Model",{OwnerUserId=99},{node("Slot1","Part",{IsEmpty=true})})
    plotFixture=node("Plots","Folder",{}, {own,other})
    assert(not funcs.autoMark(false) and #env.placeState.slots==0)
end)
check("auto mark preserves existing used markers", function()
    local empty=node("Slot1","Part",{IsEmpty=true})
    plotFixture=node("Plots","Folder",{}, {node("1","Model",{OwnerUserId=42},{node("SpawnPoint","Part"),empty})})
    assert(funcs.autoMark(false));env.placeState.slots[1].used=true
    funcs.autoMark(false)
    assert(#env.placeState.slots==1 and env.placeState.slots[1].used)
end)
check("rejected slot clicks preserve object ancestry for mapping", function()
    local part=node("GeneratedTile","Part",{SlotNumber=2})
    assert(not funcs.bindPlace(part,position(80)))
    assert(env.placeState.lastSlotPick.ancestry[1].name=="GeneratedTile")
    assert(env.placeState.lastSlotPick.ancestry[1].attributes.SlotNumber==2)
    assert(not env.placeState.lastSlotPick.accepted and #env.placeState.slots==0)
end)
check("placement ray skips observed SpawnDetector overlay", function()
    local original=env.workspace.Raycast
    local detector=node("SpawnDetector","Part");detector.Transparency=0;detector.CanCollide=true
    local slot=node("Slot1","Part");slot.Transparency=0;slot.CanCollide=true
    local calls=0
    function env.workspace:Raycast(origin,direction,params)
        calls=calls+1
        if calls==1 then return {Instance=detector,Position=position(10)} end
        assert(params.FilterDescendantsInstances[1]==detector)
        return {Instance=slot,Position=position(20)}
    end
    local hit,skipped=funcs.placeRay(position(0),position(100),{})
    assert(hit.Instance==slot and #skipped==1 and calls==2)
    env.workspace.Raycast=original
end)
check("placement ray keeps opaque collidable parts", function()
    local original=env.workspace.Raycast
    local floor=node("Floor","Part");floor.Transparency=0;floor.CanCollide=true
    function env.workspace:Raycast() return {Instance=floor,Position=position(10)} end
    local hit,skipped=funcs.placeRay(position(0),position(100),{})
    assert(hit.Instance==floor and #skipped==0)
    env.workspace.Raycast=original
end)
check("transparent PetArea is retained by placement ray", function()
    local old=env.workspace.Raycast
    local area=node("PetArea","Part");area.Transparency=1;area.CanCollide=false
    function env.workspace:Raycast() return {Instance=area,Position=position(80)} end
    local hit,ignored=funcs.placeRay(position(0),position(100),{})
    assert(hit.Instance==area and #ignored==0)
    env.workspace.Raycast=old
end)
check("PetArea grid excludes occupied volumes and marks owned candidates", function()
    local oldRay,oldFind,oldBounds=env.workspace.Raycast,env.workspace.FindFirstChild,env.workspace.GetPartBoundsInBox
    env.Players={GetPlayers=function() return {env.player} end}
    env.OverlapParams={new=function() return {} end}
    env.CFrame={new=function(p) return {Position=p} end}
    local build=node("Build","Folder")
    local world={FindFirstChild=function(_,name) if name=="Build" then return build end end}
    function env.workspace:FindFirstChild(name) if name=="World" then return world end;return oldFind(self,name) end
    local floor=node("Part","Part");floor.Transparency=0;floor.CanCollide=true
    function floor:GetFullName() return "Workspace.World.Build.MainMap.Bases.Part" end
    function env.workspace:Raycast(origin) return {Instance=floor,Position=position(origin.X,0,origin.Z)} end
    local count=0
    function env.workspace:GetPartBoundsInBox(cf,size,params)
        count=count+1
        assert(#params.FilterDescendantsInstances==3)
        if count==1 then return {{Transparency=0,CanCollide=true}} end
        return {}
    end
    local area=node("PetArea","Part");area.Size=position(20,1,20)
    area.CFrame={PointToWorldSpace=function(_,p) return position(80+p.X,p.Y,p.Z) end}
    plotFixture=node("Plots","Folder",{}, {node("1","Model",{OwnerUserId=42},{node("SpawnPoint","Part"),area})})
    local ok=funcs.autoMark(false)
    assert(ok and #env.placeState.slots==3)
    assert(env.placeState.autoMark.areas[1].blocked==1 and env.placeState.slots[1].spatial)
    env.workspace.Raycast,env.workspace.FindFirstChild,env.workspace.GetPartBoundsInBox=oldRay,oldFind,oldBounds
end)
check("offscreen placement does not reserve or click slot", function()
    local camera,original,clicks=setupPlaceClick(false)
    camera.WorldToScreenPoint=function() return position(100,100,1),false end
    funcs.place()
    assert(clicks()==0 and not env.placeState.slots[1].used)
    assert(camera.CFrame==original and camera.CameraType=="Custom")
    assert(not env.placeState.lastAttempt.pressAttempted)
end)
check("unavailable input service leaves slot available", function()
    local camera,original,clicks=setupPlaceClick(false)
    env.game.GetService=function() error("input service unavailable") end
    funcs.place()
    assert(clicks()==0 and not env.placeState.slots[1].used and not env.placeState.enabled)
    assert(camera.CFrame==original)
end)
check("placement hides Hub during click then restores visibility", function()
    setupPlaceClick(false)
    env.frame={Visible=true};env.restore={Visible=false}
    local previous=env.game.GetService
    env.game.GetService=function(...)
        local service=previous(...)
        local click=service.SendMouseButtonEvent
        service.SendMouseButtonEvent=function(...)
            assert(not env.frame.Visible and not env.restore.Visible)
            return click(...)
        end
        return service
    end
    funcs.place()
    assert(env.frame.Visible and not env.restore.Visible)
    assert(env.placeState.lastAttempt.uiHiddenForClick)
end)
check("placement records real Tool Activated signal", function()
    local _,_,_,egg=setupPlaceClick(false)
    local callback,disconnected
    egg.Activated={Connect=function(_,fn) callback=fn;return {Disconnect=function() disconnected=true end} end}
    local previous=env.game.GetService
    env.game.GetService=function(...)
        local service=previous(...);local click=service.SendMouseButtonEvent
        service.SendMouseButtonEvent=function(self,x,y,button,down,...)
            if down and callback then callback() end
            return click(self,x,y,button,down,...)
        end
        return service
    end
    funcs.place()
    assert(env.placeState.lastAttempt.activatedCount==1 and disconnected)
end)
check("disabled Auto Place performs no equip movement or click", function()
    local camera,original,clicks=setupPlaceClick(false)
    env.AUTO_PLACE_ENABLED=false
    local equipped=false
    function humanoid:EquipTool() equipped=true end
    funcs.place()
    assert(not equipped and not walkGoal and clicks()==0 and not env.placeState.enabled)
    assert(env.placeState.last:find("disabled",1,true))
    assert(camera.CFrame==original)
end)
local function setupUpgrade(cash)
    root.Position=position(80);env.collectEgg.enabled=false
    local level=node("Level","TextLabel");level.Text="Level 1 > Level 2"
    local price=node("Cost","TextLabel");price.Text="$1M"
    local button=node("Upgrade","ImageButton",{}, {price});button.MouseButton1Click={};button.Activated={}
    local robux=node("RobuxUpgrade","ImageButton");robux.MouseButton1Click={}
    local surface=node("SurfaceGui","SurfaceGui",{}, {level,node("Frame","Frame",{}, {button,robux})})
    local own=node("1","Model",{OwnerUserId=42},{node("SpawnPoint","Part"),node("PlotUpgrade","Model",{}, {node("Sign","Part",{}, {surface})})})
    plotFixture=node("Plots","Folder",{}, {own})
    function env.player:GetAttribute(key) if key=="Cash" then return cash end end
    function env.player:FindFirstChild() return nil end
    local fired=0
    env.capability=function(name)
        if name=="getconnections" then return function(signal) return signal==button.MouseButton1Click and {{}} or {} end end
        if name=="firesignal" then return function(signal)
            assert(signal==button.MouseButton1Click and signal~=robux.MouseButton1Click)
            fired=fired+1;level.Text="Level 2 > Level 3"
        end end
    end
    env.upgrades.mode="Base"
    return function() return fired end,level,button
end
check("soft currency parser rejects Robux glyphs and malformed amounts", function()
    assert(funcs.cost("$15K")==15000 and funcs.cost("$75M")==75000000)
    assert(funcs.cost("19 Robux")==nil and funcs.cost("free")==nil and funcs.cost("$bad")==nil)
end)
check("upgrade uses only observed soft button and confirms level increase", function()
    local calls=setupUpgrade(2000000)
    funcs.upgrade();assert(calls()==1 and env.upgrades.pending)
    funcs.upgrade();assert(env.upgrades.observed==1 and not env.upgrades.pending)
end)
check("upgrade does not purchase with insufficient or unknown cash", function()
    local calls=setupUpgrade(500)
    funcs.upgrade();assert(calls()==0)
    calls=setupUpgrade(nil);funcs.upgrade();assert(calls()==0)
end)
check("upgrade without a mapped callback sends no input", function()
    local calls=setupUpgrade(2000000)
    env.capability=function() return nil end
    funcs.upgrade();assert(calls()==0 and not env.upgrades.pending)
end)
check("training stands on owned treadmill and observes speed notification", function()
    root.Position=position(80);env.collectEgg.enabled=false
    local belt=node("TreadmillBottom","Part");belt.Size=position(10,1,10)
    plotFixture=node("Plots","Folder",{}, {node("1","Model",{OwnerUserId=42},{node("SpawnPoint","Part"),belt})})
    env.training.enabled=true
    funcs.train();assert(env.training.last:find("waiting",1,true))
    funcs.record("RE/Treadmill/SpeedGained",1)
    funcs.train();assert(env.training.events==1 and env.training.last:find("observed",1,true))
end)
check("unconfirmed upgrade stops without a second purchase", function()
    local calls,level=setupUpgrade(2000000)
    funcs.upgrade();level.Text="Level 1 > Level 2";clock=clock+11
    funcs.upgrade();assert(calls()==1 and env.upgrades.mode=="Off")
end)
check("conflicting currency signals block purchases", function()
    local calls=setupUpgrade(2000000)
    function env.player:GetAttribute(key) if key=="Cash" then return 2000000 elseif key=="Money" then return 100 end end
    funcs.upgrade();assert(calls()==0)
end)
check("first upgrade uses only its observed soft currency control", function()
    local calls,_,button=setupUpgrade(2000000)
    button.Name="FirstUpgrade"
    funcs.upgrade();assert(calls()==1)
end)
check("training approaches own treadmill by native walking", function()
    root.Position=position(0);env.collectEgg.enabled=false
    function humanoid:UnequipTools() equippedChildren={} end
    local belt=node("TreadmillBottom","Part");belt.Size=position(10,1,10)
    plotFixture=node("Plots","Folder",{}, {node("1","Model",{OwnerUserId=42},{node("SpawnPoint","Part"),belt})})
    env.training.enabled=true
    funcs.train();assert(root.Position.X==80 and tweenCreated==0)
end)
check("manual handoff stops every automation without placement input", function()
    local camera,original,clicks=setupPlaceClick(false)
    env.AUTO_PLACE_ENABLED=false
    env.collectEgg.enabled=true;env.hatch.enabled=true;env.upgrades.mode="Both";env.training.enabled=true
    local equipped=false
    function humanoid:EquipTool() equipped=true end
    function humanoid:UnequipTools() error("Manual handoff must leave tools alone") end
    local ready,message=funcs.manualPlace()
    assert(ready and message:find("click an empty slot yourself",1,true))
    assert(not env.collectEgg.enabled and not env.hatch.enabled and env.upgrades.mode=="Off" and not env.training.enabled)
    assert(not env.placeState.enabled and not equipped and clicks()==0 and tweenCreated==0 and camera.CFrame==original)
    env.placeState.last=message;funcs.place();assert(env.placeState.last==message)
end)
check("manual handoff waits for active work to finish", function()
    env.collectRunning=true;env.systemRunning=true
    local waits=0
    onWait=function() waits=waits+1;if waits==3 then env.collectRunning=false;env.systemRunning=false end end
    assert(funcs.manualPlace() and waits==3)
end)
check("manual handoff refuses a stalled worker", function()
    env.placeRunning=true
    local ready,message=funcs.manualPlace()
    assert(not ready and message:find("has not stopped",1,true) and clock>=18)
end)
check("manual handoff releases pending prompt and stops hatch walking", function()
    local releases,stops=0,0
    env.holding={InputHoldEnd=function() releases=releases+1 end}
    env.hatchWalking={MoveTo=function(_,goal) assert(goal==root.Position);stops=stops+1 end}
    assert(funcs.manualPlace() and releases==1 and stops==1 and not env.holding and not env.hatchWalking)
end)
check("manual handoff rejects changed character and field carry", function()
    onWait=function() env.player.Character={} end
    local ready=funcs.manualPlace();env.player.Character=character;assert(not ready)
    onWait=nil;carrying=true
    local ok,message=funcs.manualPlace();assert(not ok and message:find("Deliver the field egg",1,true))
end)
check("manual handoff cannot overlap slot preparation", function()
    env.placeState.preparingBind=true
    local ready=funcs.manualPlace();assert(not ready and env.placeState.preparingBind)
end)
local function setupHatch()
    env.collectEgg.enabled=false
    local center=node("CenterPoint","Part");center.Position=position(0)
    local own=node("1","Model",{OwnerUserId=42},{center,node("SpawnPoint","Part")})
    plotFixture=node("Plots","Folder",{}, {own})
    local p=prompt(3);p.ActionText="Hatch!";env.promptCache[p]=true
    return p,own
end
check("manual hatch sends one exact owned ready prompt and does not claim pet creation", function()
    local p=setupHatch();env.hatch.enabled=false
    runHatch(true)
    assert(p.began==1 and p.ended==1 and env.hatch.attempts==1)
    assert(env.hatch.lastAttempt.inputOK and not env.hatch.lastAttempt.resultVerified)
    assert(not walkGoal and tweenCreated==0)
end)
check("hatch rejects carrying even within prompt range", function()
    local p=setupHatch();carrying=true
    runHatch(true);runHatch(false);assert(p.began==0)
end)
check("manual hatch refuses an unknown or foreign base", function()
    local p,own=setupHatch();function own:GetAttribute(key) if key=="OwnerUserId" then return 99 end end
    runHatch(true);assert(p.began==0)
end)
check("hatch ignores disabled out of range and wrong actions", function()
    local p=setupHatch();p.Enabled=false;runHatch(true)
    p.Enabled=true;p.ActionText="Skip";runHatch(true)
    p.ActionText="Hatch!";p.position=position(9);runHatch(true)
    assert(p.began==0)
end)
check("hatch pauses for each other worker and scan", function()
    local p=setupHatch()
    for _,key in ipairs({"collectRunning","placeRunning","systemRunning","busy"}) do
        env[key]=true;runHatch(true);env[key]=false
    end
    assert(p.began==0)
end)
check("hatch observes prompt change without verifying pet", function()
    local p=setupHatch();onWait=function() p.Enabled=false end
    runHatch(true)
    assert(p.began==1 and p.ended==1 and env.hatch.lastAttempt.promptChanged and not env.hatch.lastAttempt.resultVerified)
end)
check("hatch releases input after an error", function()
    local p=setupHatch();failInput=true
    runHatch(true);assert(p.began==1 and p.ended==1 and not env.hatch.lastAttempt.inputOK)
end)
check("hatch cooldown and attempt cap prevent repeated input", function()
    local p=setupHatch();env.attemptState[p]={count=1,time=clock}
    runHatch(true);assert(p.began==0)
    env.attemptState[p]={count=3,time=0};runHatch(true);assert(p.began==0)
end)
check("auto hatch stops before input after cancelled approach", function()
    local p=setupHatch();p.position=position(40)
    onWait=function() env.hatch.enabled=false end
    runHatch(false);assert(p.began==0)
end)
print(string.format("%d Auto Collect tests passed", tests))
