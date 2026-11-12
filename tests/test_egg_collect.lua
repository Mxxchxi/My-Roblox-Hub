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
env.typeof=function(v) return type(v)=="table" and rawget(v,"__type") or type(v) end
env.RaycastParams = {new=function() return {} end}
env.OverlapParams = {new=function() return {} end}
env.Vector3 = {new=position}
env.Enum = {RaycastFilterType={Exclude="Exclude"},EasingStyle={Linear="Linear"},PlaybackState={Playing="Playing",Completed="Completed",Cancelled="Cancelled"}}
env.TweenInfo = {new=function(duration) return {duration=duration} end}
env.collectLabel = {}
env.math = setmetatable({clamp=function(n,lo,hi) return math.max(lo,math.min(hi,n)) end},{__index=math})
local obstacle, movement, onWait, mockRoute, walkGoal, tweenCreated, plotFixture, worldParts, placedRenderRoot
function env.workspace:FindFirstChild(name) if name == "Plots" then return plotFixture elseif name=="PlacedEggRenders" then return placedRenderRoot end end
env.player.UserId=42;env.player.Name="TestPlayer"
function humanoid:MoveTo(goal) walkGoal=goal end
function env.workspace:GetPartBoundsInRadius(origin,radius,params)
    assert(radius==32 and params.MaxParts==129)
    return worldParts or {}
end
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
env.eggSelect={mode="Nearest",preferred={},catalog={entries={}},fieldSamples={}};env.placementRecord={enabled=false,last="OFF",records={}};env.placeState={enabled=false,slots={},attempts=0,observed=0};env.upgrades={mode="Off",observed=0,lastAction=-math.huge};env.training={enabled=false,last="OFF",events=0};env.AUTO_PLACE_ENABLED=true;env.hatch={enabled=true,last=""};env.hatchLabel={};env.attemptState={}
local eligibleSource=assert(source:match("(local function eligible.-)\nlocal function hatchStep"))
env.eligible=assert(load(eligibleSource.."\nreturn eligible","hatch-eligible","t",env))()
local funcs = assert(load(engine .. "\nreturn {candidate=collectCandidate,approach=approachCandidate,cancel=cancelCollectTween,step=collectStep,dispatch=dispatchCollect,snapshot=collectSnapshot,mark=setManualCarry,inventory=eggInventory,diff=newInventoryEggs,home=setDeliveryPoint,returnHome=returnHome,navigate=pathMove,record=recordGameEvent,updateCarry=updateServerCarry,resetServer=function() serverCarry=nil;lastRedeem=nil end,resolveHome=resolveAutoHome,inspectBase=inspectOwnedBase,hatchOwned=hatchOwned,hatchApproach=hatchApproach,recover=recoverWalking,bindPlace=addPlacementSlot,selectPlaceEgg=selectPlacementEgg,uidGone=placementUIDGone,place=placeStep,autoMark=autoMarkSlots,emptySlot=emptySlotEvidence,placeRay=placementRaycast,vacancies=areaVacancies,cost=parseSoftCost,cash=readCash,upgrade=upgradeStep,train=trainingStep,manualPlace=prepareManualPlacement,startRecord=beginPlacementRecording,stopRecord=stopPlacementRecording,captureRecord=capturePlacementClick,tickRecord=tickPlacementRecording,worldScan=scanPlacementWorld,worldCompare=comparePlacementWorld,eggMeta=eggLogic.metadata,eggRank=eggLogic.choices,eggCatalog=eggLogic.refresh,eggPrefs=eggLogic.apply,resetField=eggLogic.resetField,fieldRecord=eggLogic.fieldRecord,fieldIndex=function() return eggLogic.field end,eggExport=eggLogic.export,toolRead=eggLogic.toolMetadata,toolCatalog=eggLogic.toolCatalog,definitions=eggLogic.inspectDefinitions,definitionSnapshot=eggLogic.definitionSnapshot,definitionTarget=eggLogic.definitionTarget,sourceScan=eggLogic.scanSources,sourceScalar=eggLogic.sourceScalar,sourceReset=function() eggLogic.sources=nil;eggLogic.sourceRunning=false;eggLogic.sourceEvents={};eggLogic.definitions=nil;eggLogic.definitionRunning=false;eggLogic.definitionPending=nil end}", "collect-engine", "t", env))()
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
    funcs.resetField();funcs.sourceReset();env.gui=nil;env.game={PlaceId=107778070777162};env.require=nil;env.task.spawn=function(fn) fn() end
    env.eggSelect={mode="Nearest",preferred={},catalog={entries={}},fieldSamples={}}
    funcs.stopRecord("reset");env.placementRecord={enabled=false,last="OFF",records={}}
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
    plotFixture=nil;worldParts={};placedRenderRoot=nil
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
    function obj:GetPivot() return {Position=self.Position} end
    function obj:FindFirstChildOfClass(kind) for _,child in ipairs(self.children) do if child:IsA(kind) then return child end end end
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
local function setupRecorder()
    local camera,original,clicks,egg=setupPlaceClick(false)
    equippedChildren={egg};backpackChildren={};egg.Parent=character
    assert(funcs.startRecord())
    assert(not env.collectEgg.enabled and not env.hatch.enabled and not env.placeState.enabled)
    return env.placeState.slots[1].part,egg,camera,original,clicks
end
local function finishRecording()
    for i=1,82 do clock=clock+0.1;funcs.tickRecord() end
end
check("placement recorder captures UID and raw target without generating input", function()
    local slot,egg,camera,original,clicks=setupRecorder()
    local oldParent=egg.Parent
    function humanoid:EquipTool() error("Recorder must not equip") end
    env.capability=function() error("Recorder must not call executor APIs") end
    assert(funcs.captureRecord(slot,position(80),position(100,200),false))
    local rec=env.placementRecord.records[1]
    assert(rec.uid==egg:GetAttribute("UID") and rec.target.inOwnedPlot and rec.target.path==slot:GetFullName())
    assert(rec.before.uidPresent and rec.characterPosition.x==80 and rec.screen.x==100)
    assert(egg.Parent==oldParent and clicks()==0 and camera.CFrame==original and tweenCreated==0)
end)
check("recorder observes stable UID removal without claiming world placement", function()
    local slot=setupRecorder();assert(funcs.captureRecord(slot,position(80),position(100),false))
    equippedChildren={};finishRecording()
    local rec=env.placementRecord.records[1]
    assert(not env.placementRecord.enabled and rec.inventoryUIDRemoved and rec.status=="uid_removal_observed")
    assert(not rec.worldPlacementVerified and rec.after.complete and not rec.after.uidPresent)
    assert(funcs.snapshot().placementRecording.records[1]==rec)
end)
check("recorder does not mistake unequipping for successful placement", function()
    local slot,egg=setupRecorder();funcs.captureRecord(slot,position(80),position(100),false)
    equippedChildren={};backpackChildren={egg};finishRecording()
    local rec=env.placementRecord.records[1]
    assert(not rec.inventoryUIDRemoved and rec.after.uidPresent and rec.status=="placement_unconfirmed")
end)
check("recorder refuses processed clicks no target and no equipped egg", function()
    local slot=setupRecorder()
    assert(not funcs.captureRecord(slot,position(80),position(100),true))
    assert(not funcs.captureRecord(nil,position(80),position(100),false))
    equippedChildren={};assert(not funcs.captureRecord(slot,position(80),position(100),false))
    assert(#env.placementRecord.records==0)
end)
check("recorder cannot infer UID removal from incomplete inventory", function()
    local slot=setupRecorder();funcs.captureRecord(slot,position(80),position(100),false)
    local malformed=eggTool("AssetEgg");function malformed:GetAttribute(key) if key=="ItemType" then return "AssetEgg" end end
    equippedChildren={malformed};finishRecording()
    assert(not env.placementRecord.records[1].inventoryUIDRemoved)
end)
check("recorder keeps detached world target ownership uncertain", function()
    setupRecorder();local detached=node("GeneratedEggArea","Part");detached.Parent=node("OtherGeneratedRoot","Folder")
    assert(funcs.captureRecord(detached,position(80),position(100),false))
    assert(not env.placementRecord.records[1].target.inOwnedPlot)
end)
check("additional world clicks do not create overlapping records", function()
    local slot=setupRecorder();funcs.captureRecord(slot,position(80),position(100),false)
    funcs.captureRecord(slot,position(80),position(100),false)
    assert(#env.placementRecord.records==1 and env.placementRecord.records[1].additionalClicks==1)
end)
check("recorder cancels on respawn worker restart or field carry", function()
    local slot=setupRecorder();funcs.captureRecord(slot,position(80),position(100),false)
    env.player.Character=nil;funcs.tickRecord();env.player.Character=character
    assert(not env.placementRecord.enabled and env.placementRecord.records[1].status=="cancelled")
    assert(funcs.startRecord());env.training.enabled=true;funcs.tickRecord();assert(not env.placementRecord.enabled)
    assert(funcs.startRecord());carrying=true;funcs.tickRecord();assert(not env.placementRecord.enabled)
end)
check("recorder waits at most sixty seconds for a manual click", function()
    setupRecorder();clock=clock+61;funcs.tickRecord()
    assert(not env.placementRecord.enabled and #env.placementRecord.records==0)
end)
check("recorder includes bounded event observations with no acceptance claim", function()
    local slot=setupRecorder();funcs.captureRecord(slot,position(80),position(100),false)
    for i=1,20 do funcs.record("manual-placement-test",i) end
    finishRecording();local rec=env.placementRecord.records[1]
    assert(#rec.events==8 and rec.eventsMayBeIncomplete and not rec.worldPlacementVerified)
end)
check("recorder retains only three attempts across separate sessions", function()
    local slot=setupRecorder()
    for i=1,5 do
        if i>1 then assert(funcs.startRecord()) end
        funcs.captureRecord(slot,position(80),position(100),false);finishRecording()
    end
    assert(#env.placementRecord.records==3)
end)
check("recorder preserves a recent sample when game removes egg before input listener", function()
    local slot=setupRecorder();funcs.tickRecord()
    equippedChildren={};clock=clock+0.1
    assert(funcs.captureRecord(slot,position(80),position(100),false))
    finishRecording();local rec=env.placementRecord.records[1]
    assert(rec.equippedSource=="recent_read_only_sample" and rec.before.uidPresent and rec.inventoryUIDRemoved)
    assert(rec.beforeSampleAgeMs>0 and not rec.worldPlacementVerified)
end)
check("recorder refuses an expired equipped-egg sample", function()
    local slot=setupRecorder();funcs.tickRecord();equippedChildren={};clock=clock+0.4
    assert(not funcs.captureRecord(slot,position(80),position(100),false))
    assert(#env.placementRecord.records==0)
end)
local function addWorldEgg(parent,uid,attrs)
    local data=attrs or {};data.UID=uid
    local body=node("EggMesh","Part")
    local egg=node("Whale Shark Egg","Model",data,{body})
    parent.children[#parent.children+1]=egg;egg.Parent=parent
    return egg,body
end
check("world recorder matches exact new egg UID and stable inventory removal", function()
    local slot,egg,_,_,clicks=setupRecorder();funcs.captureRecord(slot,position(80),position(100),false)
    equippedChildren={};addWorldEgg(slot.Parent,egg:GetAttribute("UID"))
    finishRecording();local rec=env.placementRecord.records[1]
    assert(rec.worldEggAppearanceVerified and rec.status=="world_egg_appearance_observed")
    assert(rec.worldResult.matchedCount==1 and not rec.worldPlacementVerified and not rec.worldResult.serverAcceptanceVerified)
    assert(clicks()==0)
end)
check("world recorder does not accept a name-only egg or UID-less object", function()
    local slot=setupRecorder();funcs.captureRecord(slot,position(80),position(100),false);equippedChildren={}
    addWorldEgg(slot.Parent,nil);finishRecording()
    local rec=env.placementRecord.records[1]
    assert(not rec.worldEggAppearanceVerified and rec.worldResult.candidateCount>0)
end)
check("world recorder rejects a different UID and a distant matching UID", function()
    local slot,egg=setupRecorder();funcs.captureRecord(slot,position(80),position(100),false);equippedChildren={}
    addWorldEgg(slot.Parent,"different-uid")
    local far=addWorldEgg(slot.Parent,egg:GetAttribute("UID"));far.Position=position(100)
    finishRecording();assert(not env.placementRecord.records[1].worldEggAppearanceVerified)
end)
check("world recorder excludes an egg already visible before arming", function()
    local slot,egg=setupRecorder();funcs.stopRecord("rearm")
    addWorldEgg(slot.Parent,egg:GetAttribute("UID"));assert(funcs.startRecord())
    funcs.captureRecord(slot,position(80),position(100),false);equippedChildren={};finishRecording()
    assert(not env.placementRecord.records[1].worldEggAppearanceVerified)
end)
check("world recorder rejects foreign ownership even under own plot", function()
    local slot,egg=setupRecorder();funcs.captureRecord(slot,position(80),position(100),false);equippedChildren={}
    addWorldEgg(slot.Parent,egg:GetAttribute("UID"),{OwnerUserId=99});finishRecording()
    assert(not env.placementRecord.records[1].worldEggAppearanceVerified)
end)
check("world recorder requires inventory removal as well as world UID", function()
    local slot,egg=setupRecorder();funcs.captureRecord(slot,position(80),position(100),false)
    addWorldEgg(slot.Parent,egg:GetAttribute("UID"));finishRecording()
    assert(not env.placementRecord.records[1].worldEggAppearanceVerified)
end)
check("world recorder rejects independent objects sharing the same UID", function()
    local slot,egg=setupRecorder();funcs.captureRecord(slot,position(80),position(100),false);equippedChildren={}
    addWorldEgg(slot.Parent,egg:GetAttribute("UID"));addWorldEgg(slot.Parent,egg:GetAttribute("UID"));finishRecording()
    local rec=env.placementRecord.records[1]
    assert(rec.worldResult.matchedCount==2 and not rec.worldEggAppearanceVerified)
end)
check("world recorder groups nested UID copies as one appearance", function()
    local slot,egg=setupRecorder();funcs.captureRecord(slot,position(80),position(100),false);equippedChildren={}
    local _,body=addWorldEgg(slot.Parent,egg:GetAttribute("UID"));body.attrs.UID=egg:GetAttribute("UID")
    finishRecording();assert(env.placementRecord.records[1].worldEggAppearanceVerified)
end)
check("world recorder observes detached eggs with explicit local ownership", function()
    local slot,egg=setupRecorder();funcs.captureRecord(slot,position(80),position(100),false);equippedChildren={}
    local folder=node("GeneratedEggs","Folder")
    local _,body=addWorldEgg(folder,egg:GetAttribute("UID"),{OwnerUserId=42})
    worldParts={body};finishRecording();assert(env.placementRecord.records[1].worldEggAppearanceVerified)
end)
check("world recorder does not assume ownership from proximity alone", function()
    local slot,egg=setupRecorder();funcs.captureRecord(slot,position(80),position(100),false);equippedChildren={}
    local folder=node("GeneratedEggs","Folder");local _,body=addWorldEgg(folder,egg:GetAttribute("UID"))
    worldParts={body};finishRecording();assert(not env.placementRecord.records[1].worldEggAppearanceVerified)
end)
check("world recorder requires the matching egg to remain visible", function()
    local slot,egg=setupRecorder();funcs.captureRecord(slot,position(80),position(100),false);equippedChildren={}
    local model=addWorldEgg(slot.Parent,egg:GetAttribute("UID"))
    for i=1,20 do clock=clock+0.1;funcs.tickRecord() end
    for i=#slot.Parent.children,1,-1 do if slot.Parent.children[i]==model then table.remove(slot.Parent.children,i) end end
    model.Parent=nil;finishRecording();assert(not env.placementRecord.records[1].worldEggAppearanceVerified)
end)
check("world snapshots disclose bounded hierarchy truncation", function()
    local children={}
    for i=1,2050 do children[i]=node("Decoration"..i,"Part") end
    local plot=node("1","Model",{OwnerUserId=42},children)
    local snapshot=funcs.worldScan(plot,position(80))
    assert(not snapshot.treeComplete and snapshot.visited<=2048)
end)
check("world recorder reports incomplete spatial scans without crashing", function()
    local slot=setupRecorder();local saved=env.workspace.GetPartBoundsInRadius
    env.workspace.GetPartBoundsInRadius=function() error("query unavailable") end
    local snapshot=funcs.worldScan(slot.Parent,position(80))
    env.workspace.GetPartBoundsInRadius=saved
    assert(snapshot.treeComplete and not snapshot.spatialComplete and snapshot.spatialError)
end)
check("world recorder rejects invisible egg geometry", function()
    local slot,egg=setupRecorder();funcs.captureRecord(slot,position(80),position(100),false);equippedChildren={}
    local _,body=addWorldEgg(slot.Parent,egg:GetAttribute("UID"));body.Transparency=1
    finishRecording();assert(not env.placementRecord.records[1].worldEggAppearanceVerified)
end)
check("world recorder detects a fresh UID on an existing reused model", function()
    local slot,egg=setupRecorder();funcs.stopRecord("rearm")
    local model=addWorldEgg(slot.Parent,"old-uid");assert(funcs.startRecord())
    funcs.captureRecord(slot,position(80),position(100),false);equippedChildren={};model.attrs.UID=egg:GetAttribute("UID")
    finishRecording();assert(env.placementRecord.records[1].worldEggAppearanceVerified)
end)
check("world recorder excludes tool descendants even when world parent is in own plot", function()
    local slot,egg=setupRecorder();funcs.captureRecord(slot,position(80),position(100),false);equippedChildren={}
    local tool=node("VisualTool","Tool");slot.Parent.children[#slot.Parent.children+1]=tool;tool.Parent=slot.Parent
    addWorldEgg(tool,egg:GetAttribute("UID"));finishRecording()
    assert(not env.placementRecord.records[1].worldEggAppearanceVerified)
end)
check("world recorder refuses detached verification when spatial query hits limit", function()
    local slot,egg=setupRecorder();funcs.captureRecord(slot,position(80),position(100),false);equippedChildren={}
    local folder=node("GeneratedEggs","Folder");local _,body=addWorldEgg(folder,egg:GetAttribute("UID"),{OwnerUserId=42})
    worldParts={body};for i=2,129 do worldParts[i]=node("NearbyDecoration"..i,"Part") end
    finishRecording();local rec=env.placementRecord.records[1]
    assert(not rec.worldResult.after.spatialComplete and not rec.worldEggAppearanceVerified)
end)
check("world recorder cancels when local plot ownership changes", function()
    local slot,egg=setupRecorder();funcs.captureRecord(slot,position(80),position(100),false);equippedChildren={}
    addWorldEgg(slot.Parent,egg:GetAttribute("UID"));slot.Parent.attrs.OwnerUserId=99
    funcs.tickRecord();local rec=env.placementRecord.records[1]
    assert(not env.placementRecord.enabled and rec.status=="cancelled" and not rec.worldEggAppearanceVerified)
end)
check("world recorder matches exact UUID model name without UID attributes", function()
    local slot,egg=setupRecorder();local uid="0123456789abcdef0123456789abcdef"
    function egg:GetAttribute(key) if key=="UID" then return uid elseif key=="ItemType" then return "AssetEgg" end end
    funcs.captureRecord(slot,position(80),position(100),false);equippedChildren={}
    local model=addWorldEgg(slot.Parent,nil);model.Name=uid
    finishRecording();assert(env.placementRecord.records[1].worldEggAppearanceVerified)
end)
local renderTestUid="0123456789abcdef0123456789abcdef"
local function setupNamedRenderRecording()
    local slot,egg=setupRecorder()
    function egg:GetAttribute(key) if key=="UID" then return renderTestUid elseif key=="ItemType" then return "AssetEgg" end end
    assert(funcs.captureRecord(slot,position(80),position(100),false));equippedChildren={}
    return slot,egg
end
local function addNamedRender(owner,uid)
    placedRenderRoot=placedRenderRoot or node("PlacedEggRenders","Folder")
    local model,body=addWorldEgg(placedRenderRoot,nil)
    model.Name=tostring(owner).."_"..(uid or renderTestUid)
    return model,body
end
check("placed render namespace matches owner and UID despite a capped spatial query", function()
    setupNamedRenderRecording();addNamedRender(42)
    worldParts={};for i=1,129 do worldParts[i]=node("Decoration"..i,"Part") end
    finishRecording();local rec=env.placementRecord.records[1]
    assert(rec.worldEggAppearanceVerified and rec.worldResult.matchedCount==1)
    assert(not rec.worldResult.after.spatialComplete and rec.worldResult.after.renderComplete)
    local c=rec.worldResult.candidates[1]
    assert(c.placedRender and c.renderOwnerUserId=="42" and c.uidMatches and c.explicitOwner)
    assert(not rec.worldPlacementVerified and not rec.worldResult.serverAcceptanceVerified)
end)
check("placed render prefix from another user is never accepted", function()
    setupNamedRenderRecording();local _,body=addNamedRender(99);worldParts={body}
    finishRecording();assert(not env.placementRecord.records[1].worldEggAppearanceVerified)
end)
check("owner UID name is only parsed in the observed direct-child namespace", function()
    local slot=setupNamedRenderRecording()
    local model=addWorldEgg(slot.Parent,nil);model.Name="42_"..renderTestUid
    finishRecording();assert(not env.placementRecord.records[1].worldEggAppearanceVerified)
end)
check("placed render with another UID is not matched", function()
    setupNamedRenderRecording();addNamedRender(42,"abcdef0123456789abcdef0123456789")
    finishRecording();assert(not env.placementRecord.records[1].worldEggAppearanceVerified)
end)
check("malformed placed render suffix is not treated as a UID", function()
    setupNamedRenderRecording();local model,body=addNamedRender(42,renderTestUid.."_copy");worldParts={body}
    finishRecording();assert(not env.placementRecord.records[1].worldEggAppearanceVerified)
end)
check("placed render name cannot override conflicting owner attributes", function()
    setupNamedRenderRecording();local model=addNamedRender(42);model.attrs.OwnerUserId=99
    finishRecording();assert(not env.placementRecord.records[1].worldEggAppearanceVerified)
end)
check("placed render already in baseline does not become a new appearance", function()
    local slot,egg=setupNamedRenderRecording();funcs.stopRecord("rearm")
    addNamedRender(42);equippedChildren={egg};assert(funcs.startRecord())
    funcs.captureRecord(slot,position(80),position(100),false);equippedChildren={};finishRecording()
    assert(not env.placementRecord.records[#env.placementRecord.records].worldEggAppearanceVerified)
end)
check("placed render duplicate identities remain ambiguous", function()
    setupNamedRenderRecording();addNamedRender(42);addNamedRender(42)
    finishRecording();local rec=env.placementRecord.records[1]
    assert(not rec.worldEggAppearanceVerified and rec.worldResult.matchedCount==2)
end)
check("placed render root listing truncation is reported and blocks namespace verification", function()
    setupNamedRenderRecording();placedRenderRoot=node("PlacedEggRenders","Folder")
    for i=1,512 do local part=node("Dirt"..i,"Part");part.Parent=placedRenderRoot;placedRenderRoot.children[i]=part end
    addNamedRender(42);finishRecording();local rec=env.placementRecord.records[1]
    assert(not rec.worldResult.after.renderComplete and not rec.worldEggAppearanceVerified)
end)
check("invisible placed render does not count as an observed egg", function()
    setupNamedRenderRecording();local _,body=addNamedRender(42);body.Transparency=1
    finishRecording();assert(not env.placementRecord.records[1].worldEggAppearanceVerified)
end)
local function qualityPrompt(distance,income,name,uid)
    local p=prompt(distance);p.attrs={IncomePerSecond=income,EggName=name,UID=uid}
    function p:GetAttribute(key) return self.attrs[key] end
    function p:GetAttributes() return self.attrs end
    function p:FindFirstChild() return nil end
    env.promptCache[p]=true
    return p
end
check("egg metadata reads exact identity and per-second income with provenance", function()
    local p=qualityPrompt(3,250,"Sample Egg","egg-a");p.attrs.Rarity="Rare"
    local m=funcs.eggMeta(p)
    assert(m.name=="Sample Egg" and m.uid=="egg-a" and m.incomePerSecond==250 and m.rarity=="Rare")
    assert(m.sources.incomePerSecond and #m.raw>0)
end)
check("egg metadata never ranks an unknown egg by name rarity or price", function()
    local p=qualityPrompt(3,nil,"Mythic Egg");p.attrs.Rarity="Mythic";p.attrs.Price=999999999
    local m=funcs.eggMeta(p);assert(m.incomePerSecond==nil)
    env.eggSelect.mode="Income";assert(not funcs.eggRank(root,humanoid,false)[1].accepted)
end)
check("income priority ranks a distant valuable egg above a nearby cheap egg", function()
    local low=qualityPrompt(3,1,"Low Egg");local high=qualityPrompt(40,100,"High Egg")
    env.eggSelect.mode="Income"
    local ranked=funcs.eggRank(root,humanoid,false);assert(ranked[1].prompt==high and ranked[2].prompt==low)
end)
check("income mode actually approaches and collects the better distant target", function()
    local low=qualityPrompt(3,1,"Low Egg");local high=qualityPrompt(40,100,"High Egg")
    env.eggSelect.mode="Income";funcs.dispatch()
    assert(high.began==1 and low.began==0 and root.Position.X>30)
    assert(env.collectEgg.lastInput.eggSelection.metadata.incomePerSecond==100)
end)
check("nearest mode preserves nearby collection even with richer distant targets", function()
    local near=qualityPrompt(3,1,"Near");local far=qualityPrompt(40,100,"Far")
    funcs.dispatch();assert(near.began==1 and far.began==0)
end)
check("income ties prefer the closer egg", function()
    local near=qualityPrompt(3,100,"Near");qualityPrompt(30,100,"Far")
    env.eggSelect.mode="Income";assert(funcs.eggRank(root,humanoid,false)[1].prompt==near)
end)
check("missing income in best mode sends no input and does not fall back to nearest", function()
    local p=qualityPrompt(3,nil,"Unknown")
    env.eggSelect.mode="Income";funcs.dispatch()
    assert(p.began==0 and not movement and env.collectEgg.last:find("Income",1,true))
end)
check("conflicting income fields stay unknown", function()
    local p=qualityPrompt(3,100,"Sample");p.attrs.CashPerSecond=200
    local m=funcs.eggMeta(p);assert(m.conflicts.incomePerSecond and m.incomePerSecond==nil)
end)
check("malformed negative infinite and NaN incomes cannot influence ranking", function()
    for _,value in ipairs({"$100/s",-1,math.huge,0/0}) do
        local p=qualityPrompt(3,value,"Sample");local m=funcs.eggMeta(p)
        assert(m.incomePerSecond==nil)
    end
end)
check("explicit numeric string income is supported but ambiguous units are not", function()
    local p=qualityPrompt(3,"100","Sample");assert(funcs.eggMeta(p).incomePerSecond==100)
    p.attrs.IncomePerSecond="100K";assert(funcs.eggMeta(p).incomePerSecond==nil)
end)
check("preferred names are ordered trimmed and case insensitive", function()
    local ok=funcs.eggPrefs(" Rare Egg, Common Egg, rare egg ");assert(ok and #env.eggSelect.preferred==2)
    local common=qualityPrompt(3,1000,"Common Egg");local rare=qualityPrompt(40,1,"RARE EGG")
    env.eggSelect.mode="Preferred";local ranked=funcs.eggRank(root,humanoid,false)
    assert(ranked[1].prompt==rare and ranked[2].prompt==common)
end)
check("preferred mode skips unknown and unlisted names", function()
    local p=qualityPrompt(3,100,"Other Egg");assert(funcs.eggPrefs("Wanted Egg"))
    env.eggSelect.mode="Preferred";funcs.dispatch();assert(p.began==0)
end)
check("preferred list rejects overlong input atomically", function()
    assert(funcs.eggPrefs("Keep Egg"));assert(not funcs.eggPrefs(string.rep("x",1201)))
    assert(env.eggSelect.preferred[1]=="Keep Egg")
end)
check("quality sorting still respects range cooldown and action guards", function()
    local wrong=qualityPrompt(3,10000,"Wrong");wrong.ActionText="Hatch!"
    local far=qualityPrompt(260,10000,"Far")
    local cooling=qualityPrompt(4,10000,"Cooling");env.collectAttempts[cooling]={count=3,time=0}
    local valid=qualityPrompt(5,10,"Valid")
    env.eggSelect.mode="Income";local ranked=funcs.eggRank(root,humanoid,false)
    assert(#ranked==1 and ranked[1].prompt==valid)
end)
check("metadata changing during travel prevents pickup of a now-unknown target", function()
    local p=qualityPrompt(40,100,"Sample")
    env.eggSelect.mode="Income";onWait=function() p.attrs.IncomePerSecond=nil end
    funcs.dispatch();assert(p.began==0)
end)
check("egg catalog bounds visible report rows and preserves unknown data", function()
    for i=1,20 do qualityPrompt(i+1,nil,"Egg "..i) end
    funcs.eggCatalog();local c=env.eggSelect.catalog
    assert(c.total==20 and c.knownIncome==0 and #c.entries==12 and c.truncated)
    assert(funcs.snapshot().eggSelection.catalog==c)
end)
check("field data samples are read-only bounded observations", function()
    for i=1,10 do funcs.record("RE/EggWorld/FieldEggShifted",{UID="egg-"..i,IncomePerSecond=i}) end
    assert(#env.eggSelect.fieldSamples==3 and env.eggSelect.fieldSamples[1].args[1].UID=="egg-8")
end)
check("UID switching during travel prevents stale-target pickup", function()
    local p=qualityPrompt(40,100,"Sample","old-uid")
    env.eggSelect.mode="Income";onWait=function() p.attrs.UID="new-uid" end
    funcs.dispatch();assert(p.began==0)
end)
check("explicit object references can supply metadata without spatial guessing", function()
    local p=qualityPrompt(3,nil,nil)
    local linked=node("EggModel","Model",{EggName="Linked Egg",UID="linked-id",CashPerSecond=45})
    function linked:IsDescendantOf(root) return root==env.workspace end
    local ref=node("Target","ObjectValue");ref.Value=linked
    function p:FindFirstChild(key) if key=="Target" then return ref end end
    local m=funcs.eggMeta(p)
    assert(m.name=="Linked Egg" and m.uid=="linked-id" and m.incomePerSecond==45)
end)
check("preferred collection follows user order rather than distance or income", function()
    local near=qualityPrompt(3,500,"Near Egg");local wanted=qualityPrompt(40,1,"Wanted Egg")
    assert(funcs.eggPrefs("Wanted Egg, Near Egg"));env.eggSelect.mode="Preferred"
    funcs.dispatch();assert(wanted.began==1 and near.began==0)
end)
check("conflicting identity blocks best-income selection", function()
    local p=qualityPrompt(3,100,"Sample","first");p.attrs.EggUID="second"
    env.eggSelect.mode="Income";local ranked=funcs.eggRank(root,humanoid,false)
    assert(ranked[1].meta.conflicts.uid and not ranked[1].accepted)
end)
check("field sample retains bounded nested egg records for later schema mapping", function()
    funcs.record("RE/EggWorld/FieldEggBatchShifted",{Records={sample={UID="sample",IncomePerSecond=200}}})
    local sample=env.eggSelect.fieldSamples[1]
    assert(#sample.nested==1 and sample.nested[1].value.sample.IncomePerSecond==200)
end)
local function fieldRecord(uid,x,income,name)
    return {Uid=uid,AssetCategory="SampleAnimal",DisplayName=name,IncomePerSecond=income,AreaId="Forest",
        BottomCFrame={__type="CFrame",Position=position(x,-3,0)}}
end
check("field packet captures UID before cosmetic properties and decodes CFrame position", function()
    local payload=fieldRecord("field-a",3,100,"Sample Egg")
    for i=1,40 do payload["Cosmetic"..i]=i end
    funcs.record("RE/EggWorld/FieldEggShifted",payload)
    local sample=env.eggSelect.fieldSamples[1].field.records[1]
    assert(sample.uid=="field-a" and sample.fields.IncomePerSecond==100 and sample.positions.BottomCFrame.x==3)
    assert(sample.fields.BottomCFrame.kind=="CFrame" and sample.fields.BottomCFrame.position.y==-3)
end)
check("observed UpdatedRecords batch shape fills the field index", function()
    funcs.record("RE/EggWorld/FieldEggBatchShifted",{UpdatedRecords={fieldRecord("a",3,10),fieldRecord("b",40,100)},RemovedUids={}})
    assert(funcs.fieldIndex().count==2 and funcs.fieldIndex().records.b.fields.IncomePerSecond==100)
end)
check("bare proxy prompt binds uniquely to a fresh field position", function()
    local p=qualityPrompt(3,nil,nil)
    funcs.record("RE/EggWorld/FieldEggShifted",fieldRecord("a",3,50,"Sample Egg"))
    local m=funcs.eggMeta(p)
    assert(m.uid=="a" and m.name=="Sample Egg" and m.assetCategory=="SampleAnimal" and m.incomePerSecond==50)
    assert(m.fieldBinding.method=="unique_position" and m.fieldBinding.positionSource=="BottomCFrame")
end)
check("income collection uses linked field records instead of nearest empty proxy", function()
    local near=qualityPrompt(3,nil,nil);local far=qualityPrompt(40,nil,nil)
    funcs.record("RE/EggWorld/FieldEggBatchShifted",{UpdatedRecords={fieldRecord("a",3,10),fieldRecord("b",40,100)}})
    env.eggSelect.mode="Income";funcs.dispatch()
    assert(far.began==1 and near.began==0 and env.collectEgg.lastInput.eggSelection.metadata.uid=="b")
end)
check("explicit prompt UID uses exact field identity", function()
    local p=qualityPrompt(3,nil,nil,"a")
    funcs.record("RE/EggWorld/FieldEggShifted",fieldRecord("a",50,75,"Known Egg"))
    local m=funcs.eggMeta(p);assert(m.incomePerSecond==75 and m.fieldBinding.method=="explicit_uid")
end)
check("explicit UID never falls back to another nearby field record", function()
    local p=qualityPrompt(3,nil,nil,"unseen")
    funcs.record("RE/EggWorld/FieldEggShifted",fieldRecord("other",3,100))
    assert(funcs.eggMeta(p).incomePerSecond==nil)
end)
check("two field records at one proxy position remain ambiguous", function()
    local p=qualityPrompt(3,nil,nil)
    funcs.record("RE/EggWorld/FieldEggBatchShifted",{UpdatedRecords={fieldRecord("a",3,10),fieldRecord("b",3,100)}})
    local m=funcs.eggMeta(p);assert(m.uid==nil and m.fieldBinding.candidateCount==2)
end)
check("two prompts at one field position do not share an inferred identity", function()
    local p=qualityPrompt(3,nil,nil);qualityPrompt(3,nil,nil)
    funcs.record("RE/EggWorld/FieldEggShifted",fieldRecord("a",3,100))
    local m=funcs.eggMeta(p);assert(m.uid==nil and m.fieldBinding.method=="ambiguous_prompts")
end)
check("stale field records do not drive quality selection", function()
    local p=qualityPrompt(3,nil,nil);funcs.record("RE/EggWorld/FieldEggShifted",fieldRecord("a",3,100))
    clock=clock+121;assert(funcs.eggMeta(p).uid==nil)
end)
check("FieldEggGone and RemovedUids invalidate field identities", function()
    local p=qualityPrompt(3,nil,nil)
    funcs.record("RE/EggWorld/FieldEggShifted",fieldRecord("a",3,100));funcs.record("RE/EggWorld/FieldEggGone","a")
    assert(funcs.fieldIndex().count==0 and funcs.eggMeta(p).uid==nil)
    funcs.record("RE/EggWorld/FieldEggShifted",fieldRecord("b",3,100))
    funcs.record("RE/EggWorld/FieldEggBatchShifted",{UpdatedRecords={},RemovedUids={"b"}})
    assert(funcs.fieldIndex().count==0 and funcs.eggMeta(p).uid==nil)
end)
check("carried field entries cannot be used for positional matching", function()
    local p=qualityPrompt(3,nil,nil);local payload=fieldRecord("a",3,100);payload.IsCarried=true
    funcs.record("RE/EggWorld/FieldEggShifted",payload);assert(funcs.eggMeta(p).uid==nil)
end)
check("position matching rejects a distant or different-floor field entry", function()
    local p=qualityPrompt(3,nil,nil);funcs.record("RE/EggWorld/FieldEggShifted",fieldRecord("a",6,100))
    assert(funcs.eggMeta(p).uid==nil)
    local payload=fieldRecord("a",3,100);payload.BottomCFrame.Position=position(3,20,0)
    funcs.record("RE/EggWorld/FieldEggShifted",payload);assert(funcs.eggMeta(p).uid==nil)
end)
check("conflicting payload UID fields are diagnosed without indexing", function()
    local payload=fieldRecord("a",3,100);payload.UID="b"
    funcs.record("RE/EggWorld/FieldEggShifted",payload)
    local sample=env.eggSelect.fieldSamples[1].field.records[1]
    assert(sample.identityConflict and not sample.uid and funcs.fieldIndex().count==0)
end)
check("field cache and reports have separate bounds", function()
    for i=1,300 do funcs.record("RE/EggWorld/FieldEggShifted",fieldRecord("id"..i,i,10)) end
    local cache=funcs.fieldIndex();assert(cache.count==256 and #cache.order==256 and not cache.records.id1)
    assert(#env.eggSelect.fieldSamples==3)
end)
check("remove and reinsert cannot leave stale eviction references", function()
    funcs.record("RE/EggWorld/FieldEggShifted",fieldRecord("keep",3,10));funcs.record("RE/EggWorld/FieldEggGone","keep")
    for i=1,255 do funcs.record("RE/EggWorld/FieldEggShifted",fieldRecord("id"..i,i,10)) end
    funcs.record("RE/EggWorld/FieldEggShifted",fieldRecord("keep",3,10))
    funcs.record("RE/EggWorld/FieldEggShifted",fieldRecord("last",4,10))
    assert(funcs.fieldIndex().records.keep and funcs.fieldIndex().count==256)
end)
check("Stats per-second fields survive unrelated nested attributes", function()
    local p=qualityPrompt(3,nil,nil);local payload=fieldRecord("a",3,nil);payload.Stats={CashPerSecond=250}
    for i=1,20 do payload.Stats["Cosmetic"..i]=i end
    funcs.record("RE/EggWorld/FieldEggShifted",payload)
    assert(funcs.eggMeta(p).incomePerSecond==250)
end)
check("prompt and field income conflicts are never silently resolved", function()
    local p=qualityPrompt(3,100,nil,"a");funcs.record("RE/EggWorld/FieldEggShifted",fieldRecord("a",3,200))
    local m=funcs.eggMeta(p);assert(m.conflicts.incomePerSecond and m.incomePerSecond==nil)
end)
check("batch processing and priority packet reports are bounded", function()
    local updates={};for i=1,129 do updates[i]=fieldRecord("id"..i,i,10) end
    funcs.record("RE/EggWorld/FieldEggBatchShifted",{UpdatedRecords=updates})
    local sample=env.eggSelect.fieldSamples[1].field
    assert(sample.processed==128 and #sample.records==4 and sample.updatesTruncated and sample.recordsTruncated)
end)
check("focused egg export includes prompt coordinates and prioritized field samples", function()
    qualityPrompt(3,nil,nil);funcs.record("RE/EggWorld/FieldEggShifted",fieldRecord("a",3,100))
    local result=funcs.eggExport()
    assert(result.kind=="egg_data" and result.version=="1.48")
    assert(result.eggSelection.catalog.entries[1].position.x==3 and result.eggSelection.catalog.fieldLinked==1)
    assert(result.eggSelection.fieldSamples[1].field.records[1].uid=="a")
end)
local function sourceRoot(children,budget,label)
    return {{object=node("ReplicatedStorage","Folder",{},children),label=label or "ReplicatedStorage",budget=budget or 100}}
end
check("source discovery reports modules without reading source or executing them", function()
    local module=node("Catfish","ModuleScript",{Rarity="Rare"})
    setmetatable(module,{__index=function(_,key) if key=="Source" then error("Source must not be read") end end})
    local ok,result=funcs.sourceScan(sourceRoot({node("Data","Folder",{}, {module})}))
    assert(ok and result.status=="complete" and #result.modules==1 and result.modules[1].name=="Catfish")
    assert(result.readableFields[1].fields.Rarity=="Rare" and result.rankingApplied==false)
end)
check("source discovery records named values with parent context without assuming income", function()
    local rate=node("Rate","NumberValue");rate.Value=999
    local price=node("Price","NumberValue");price.Value=5000
    local rarity=node("Rarity","StringValue");rarity.Value="Uncommon"
    local _,result=funcs.sourceScan(sourceRoot({node("Catfish","Folder",{AssetCategory="Catfish"},{rate,price,rarity})}))
    assert(#result.readableFields==4)
    for _,item in ipairs(result.readableFields) do assert(item.parent and item.identityUnverified) end
    local p=qualityPrompt(3,nil,nil);env.eggSelect.mode="Income"
    assert(funcs.eggMeta(p).incomePerSecond==nil and not funcs.eggRank(root,humanoid,false)[1].accepted)
end)
check("source discovery retains explicit rates ahead of identity-only objects at report cap", function()
    local children={}
    for i=1,60 do children[i]=node("A"..i,"Folder",{UID="id"..i}) end
    children[#children+1]=node("ZIncome","Folder",{IncomePerSecond=250,Rarity="Rare"})
    local _,result=funcs.sourceScan(sourceRoot(children,100))
    assert(#result.readableFields==40 and result.fieldsTruncated)
    assert(result.readableFields[1].fields.IncomePerSecond==250)
end)
check("source discovery exposes node and queue truncation", function()
    local children={};for i=1,40 do children[i]=node("Egg"..i,"ModuleScript") end
    local _,result=funcs.sourceScan(sourceRoot(children,10))
    assert(result.visited<=10 and result.truncated and not result.roots[1].complete and result.roots[1].queueLimited)
end)
check("source discovery bounds module candidates and yields during a large scan", function()
    local children={};for i=1,180 do children[i]=node("Egg"..i,"ModuleScript") end
    local before=clock;local _,result=funcs.sourceScan(sourceRoot(children,256))
    assert(result.visited==181 and #result.modules==40 and result.modulesTruncated and clock>before)
end)
check("source discovery skips package networking and visual asset trees", function()
    local _,result=funcs.sourceScan(sourceRoot({node("Packages","Folder",{},{node("EggIncome","ModuleScript")}),
        node("Assets","Folder",{},{node("EggIncome","ModuleScript")}),node("Data","Folder",{},{node("EggData","ModuleScript")})}))
    assert(#result.modules==1 and result.modules[1].name=="EggData" and result.roots[1].skippedVisualAssets)
end)
check("source discovery excludes its own UI", function()
    env.gui=node("Hub","ScreenGui",{},{node("Income","TextLabel")})
    local _,result=funcs.sourceScan(sourceRoot({env.gui}))
    assert(#result.labels==0 and result.roots[1].skippedHub)
end)
check("source discovery marks hidden income labels as observations only", function()
    local label=node("Income","TextLabel");label.Text="$250/s"
    local hidden=node("EggDetails","Frame",{}, {label});hidden.Visible=false
    local _,result=funcs.sourceScan(sourceRoot({hidden}))
    assert(#result.labels==1 and result.labels[1].text=="$250/s" and not result.labels[1].visible and result.labels[1].identityUnverified)
end)
check("source scalar rejects nonfinite and non-scalar values and bounds strings", function()
    assert(funcs.sourceScalar(math.huge)==nil and funcs.sourceScalar(0/0)==nil and funcs.sourceScalar({})==nil)
    assert(funcs.sourceScalar(false)==false and funcs.sourceScalar(0)==0 and #funcs.sourceScalar(string.rep("x",200))==160)
end)
check("rarity event capture prioritizes explicit fields and is separate from field scoring", function()
    local p=qualityPrompt(3,nil,nil)
    local payload={Uid="a",Rarity="Rare",IncomePerSecond=500}
    for i=1,80 do payload["Cosmetic"..i]=i end
    funcs.record("RE/EggWorld/FieldEggRaritiesShown",payload)
    local event=funcs.eggExport().eggSelection.sourceEvents[1]
    assert(event.args[1].Uid=="a" and event.args[1].Rarity=="Rare" and event.args[1].IncomePerSecond==500 and event.observationOnly)
    assert(funcs.eggMeta(p).incomePerSecond==nil and funcs.fieldIndex().count==0)
end)
check("source events handle cycles and retain only four bounded samples", function()
    local payload={Records={{Uid="a",Rarity="Rare"}}};payload.loop=payload
    for i=1,6 do funcs.record("RE/EggWorld/FieldEggRaritiesShown",payload) end
    local events=funcs.eggExport().eggSelection.sourceEvents
    assert(#events==4 and events[1].args[1].loop=="<cycle>" and events[1].args[1].Records["1"].Uid=="a")
end)
check("cancelled source discovery clears running state and reports incomplete scope", function()
    env.active=false
    local ok,result=funcs.sourceScan(sourceRoot({node("EggData","ModuleScript")}))
    assert(not ok and result.status=="cancelled" and result.truncated)
    env.active=true
    assert(funcs.sourceScan(sourceRoot({node("EggData","ModuleScript")})))
end)
check("source discovery errors are recoverable and exported with the focused report", function()
    local ok,result=funcs.sourceScan({{object={},label="Broken",budget=nil}})
    assert(not ok and result.error and result.status=="error")
    assert(funcs.sourceScan(sourceRoot({node("EggIncome","ModuleScript")})))
    local exported=funcs.eggExport()
    assert(exported.eggSelection.sourceDiscovery.status=="complete" and #exported.eggSelection.sourceDiscovery.modules==1)
end)
check("source discovery retains unfamiliar income fields as diagnostic values only", function()
    local multiplier=node("IncomeMultiplier","NumberValue");multiplier.Value=2
    local _,result=funcs.sourceScan(sourceRoot({node("EggSettings","Folder",{RarityWeight=0.2},{multiplier})}))
    assert(#result.readableFields==2)
    local observed={}
    for _,item in ipairs(result.readableFields) do for key,value in pairs(item.fields) do observed[key]=value end end
    assert(observed.RarityWeight==0.2 and observed.IncomeMultiplier==2 and observed.IncomePerSecond==nil)
end)
check("source discovery prioritizes definitions over controllers at the module limit", function()
    local modules={};for i=1,50 do modules[i]=node("EggController"..i,"ModuleScript") end
    local definition=node("EggDefinitions","ModuleScript")
    function definition:GetFullName() return "ReplicatedStorage.Data.EggDefinitions" end
    local data=node("Data","Folder",{}, {definition})
    modules[#modules+1]=data
    local _,result=funcs.sourceScan(sourceRoot(modules))
    assert(#result.modules==40 and result.modules[1].name=="EggDefinitions")
end)
check("large rarity payloads exhaust a bounded observation budget", function()
    local payload={};for i=1,100 do payload[i]={Uid="a"..i,Rarity="Rare",IncomePerSecond=i} end
    funcs.record("RE/EggWorld/FieldEggRaritiesShown",payload)
    local event=funcs.eggExport().eggSelection.sourceEvents[1]
    assert(event.args[1].__truncated and event.args[1]["25"]==nil)
end)
local function configuredTool(name,uid,income,rarity,itemType)
    local config=node("Configuration","Configuration",{perSecond=income,perSecondDisplay=income,rarity=rarity})
    local tool=node(name,"Tool",{UID=uid,ItemType=itemType},{config})
    tool.Parent=backpack;backpackChildren[#backpackChildren+1]=tool
    return tool,config
end
check("configuration rates and rarity bind to the same Tool UID with provenance", function()
    local tool=configuredTool("Whale Shark","whale-1",630673,"Cosmic")
    local result=funcs.toolCatalog();local item=result.entries[1]
    assert(result.total==1 and result.uidLinked==1 and result.eligibleIncome==1 and item.eligibleForIncome)
    assert(item.metadata.uid=="whale-1" and item.metadata.incomePerSecond==630673 and item.metadata.rarity=="Cosmic")
    assert(item.metadata.sources.incomePerSecond:find("Configuration attribute perSecond",1,true))
    assert(item.metadata.sources.uid:find("Whale Shark attribute UID",1,true))
    assert(not result.serverOwnershipVerified and item.uidBinding.scope=="same_tool_in_local_inventory")
end)
check("same-name Tools retain separate UID income and session references", function()
    configuredTool("Bird","bird-a",7,"Uncommon");configuredTool("Bird","bird-b",18,"Uncommon")
    local result=funcs.toolCatalog();local a,b=result.entries[1],result.entries[2]
    assert(result.total==2 and result.uidLinked==2 and a.metadata.uid=="bird-b" and a.metadata.incomePerSecond==18)
    assert(b.metadata.uid=="bird-a" and b.metadata.incomePerSecond==7 and a.ref~=b.ref and a.path==b.path)
end)
check("missing UID retains raw income without eligibility or name matching", function()
    configuredTool("Bird",nil,18,"Uncommon");configuredTool("Bird","bird-a",7,"Uncommon")
    local result=funcs.toolCatalog()
    assert(result.knownIncome==2 and result.eligibleIncome==1 and result.missingUid==1)
    assert(result.entries[1].metadata.uid=="bird-a" and result.entries[2].uidBinding.status=="missing_uid")
end)
check("duplicate UIDs on distinct Tools block both income bindings", function()
    configuredTool("Bird","same",7,"Uncommon");configuredTool("Bird","same",18,"Uncommon")
    local result=funcs.toolCatalog()
    assert(result.duplicateUid==2 and result.uidLinked==0 and result.eligibleIncome==0)
    assert(result.entries[1].uidBinding.status=="duplicate_uid" and result.entries[2].uidBinding.status=="duplicate_uid")
end)
check("conflicting Tool and Configuration UID never pick one silently", function()
    local tool,config=configuredTool("Bird","tool-id",7,"Uncommon");config.attrs.Uid="config-id"
    local result=funcs.toolCatalog();local item=result.entries[1]
    assert(item.metadata.conflicts.uid and not item.metadata.uid and #item.metadata.uidEvidence==2)
    assert(item.uidBinding.status=="conflicting_or_invalid_uid" and not item.eligibleForIncome)
end)
check("UID evidence on a conflicting Tool also invalidates matching peers", function()
    local _,config=configuredTool("Bird","shared",7,"Uncommon");config.attrs.Uid="different"
    configuredTool("Catfish","shared",12,"Uncommon")
    local result=funcs.toolCatalog();assert(result.eligibleIncome==0)
    for _,entry in ipairs(result.entries) do
        if entry.name=="Catfish" then assert(entry.uidBinding.status=="duplicate_uid") end
    end
end)
check("matching UID aliases on one Tool do not count as a duplicate Tool", function()
    local _,config=configuredTool("Bird","same",7,"Uncommon");config.attrs.uid="same"
    assert(funcs.toolCatalog().eligibleIncome==1)
end)
check("UID present only on direct Configuration can be linked locally", function()
    local _,config=configuredTool("Bird",nil,18,"Uncommon");config.attrs.UID="config-only"
    local item=funcs.toolCatalog().entries[1]
    assert(item.metadata.uid=="config-only" and item.eligibleForIncome)
    assert(item.metadata.sources.uid:find("Configuration attribute UID",1,true))
end)
check("unknown UUID fields remain diagnostics without an invented UID mapping", function()
    local tool=configuredTool("Bird",nil,18,"Uncommon");tool.attrs.uuid="unmapped"
    local item=funcs.toolCatalog().entries[1]
    assert(not item.metadata.uid and not item.eligibleForIncome and item.metadata.raw[1].values.uuid=="unmapped")
end)
check("numeric and blank UID values never become synthetic string identities", function()
    configuredTool("Bird",123,18,"Uncommon");configuredTool("Bird","  ",7,"Uncommon")
    local result=funcs.toolCatalog();assert(result.eligibleIncome==0 and result.missingUid==2)
    for _,entry in ipairs(result.entries) do assert(entry.metadata.conflicts.uid) end
end)
check("Configuration named value children preserve exact Tool binding", function()
    local _,config=configuredTool("Bird",nil,nil,nil)
    local uid=node("UID","StringValue");uid.Value="value-id"
    local income=node("perSecond","NumberValue");income.Value=18
    local rarity=node("rarity","StringValue");rarity.Value="Uncommon"
    config.children={uid,income,rarity};for _,child in ipairs(config.children) do child.Parent=config end
    local item=funcs.toolCatalog().entries[1]
    assert(item.metadata.uid=="value-id" and item.metadata.incomePerSecond==18 and item.metadata.rarity=="Uncommon" and item.eligibleForIncome)
end)
check("display income is separate and cannot supply a missing canonical rate", function()
    local _,config=configuredTool("Bird","a",nil,"Uncommon");config.attrs.perSecondDisplay=18
    local item=funcs.toolCatalog().entries[1]
    assert(item.metadata.incomeDisplay==18 and item.metadata.incomePerSecond==nil and not item.eligibleForIncome)
end)
check("display rounding does not override or invalidate the canonical rate", function()
    local _,config=configuredTool("Bird","a",18.1,"Uncommon");config.attrs.perSecondDisplay=18
    local item=funcs.toolCatalog().entries[1]
    assert(item.metadata.incomePerSecond==18.1 and item.metadata.incomeDisplay==18 and item.eligibleForIncome)
end)
check("conflicting explicit rates block income while preserving UID", function()
    local tool=configuredTool("Bird","a",18,"Uncommon");tool.attrs.IncomePerSecond=7
    local item=funcs.toolCatalog().entries[1]
    assert(item.metadata.conflicts.incomePerSecond and item.metadata.incomePerSecond==nil and item.uidBinding.linked and not item.eligibleForIncome)
end)
check("invalid rates do not become zero or a display fallback", function()
    for i,value in ipairs({-1,math.huge,0/0,"$18/s"}) do configuredTool("Bird","a"..i,value,"Uncommon") end
    assert(funcs.toolCatalog().eligibleIncome==0)
end)
check("zero income is a valid observed canonical rate", function()
    configuredTool("Bird","a",0,"Uncommon")
    local item=funcs.toolCatalog().entries[1];assert(item.eligibleForIncome and item.metadata.incomePerSecond==0)
end)
check("multiple direct Configurations make the Tool income binding ambiguous", function()
    local tool=configuredTool("Bird","a",18,"Uncommon")
    local config=node("Configuration","Configuration",{perSecond=18});config.Parent=tool;tool.children[2]=config
    local item=funcs.toolCatalog().entries[1];assert(item.uidBinding.status=="multiple_configurations" and not item.eligibleForIncome)
end)
check("sibling and nested Configurations never supply another Tool's income", function()
    local tool,config=configuredTool("Bird","a",nil,nil)
    tool.children={node("Wrapper","Folder",{},{config})};config.Parent=tool.children[1]
    configuredTool("Bird","b",18,"Uncommon")
    local result=funcs.toolCatalog()
    for _,entry in ipairs(result.entries) do if entry.metadata.uid=="a" then assert(not entry.eligibleForIncome) end end
end)
check("session reference survives equipping while container and path are refreshed", function()
    local tool=configuredTool("Bird","a",18,"Uncommon");local before=funcs.toolCatalog().entries[1]
    backpackChildren={};equippedChildren={tool};tool.Parent=character
    local after=funcs.toolCatalog().entries[1]
    assert(before.ref==after.ref and after.container=="Character" and after.eligibleForIncome)
end)
check("same instance present in both snapshots cannot duplicate its UID", function()
    local tool=configuredTool("Bird","a",18,"Uncommon");equippedChildren={tool}
    local result=funcs.toolCatalog();assert(result.total==1 and result.eligibleIncome==1)
end)
check("Tool removed from its listed container cannot be income eligible", function()
    local tool=configuredTool("Bird","a",18,"Uncommon");tool.Parent=nil
    local item=funcs.toolCatalog().entries[1];assert(item.containmentChanged and not item.eligibleForIncome)
end)
check("explicit foreign owner prevents a local UID income binding", function()
    local _,config=configuredTool("Bird","a",18,"Uncommon");config.attrs.OwnerUserId=99
    local item=funcs.toolCatalog().entries[1];assert(item.uidBinding.status=="foreign_owner" and not item.eligibleForIncome)
end)
check("Tool catalog exposes output caps without merging repeated names", function()
    for i=1,45 do configuredTool("Bird","id"..i,i,"Uncommon") end
    local result=funcs.toolCatalog()
    assert(result.total==45 and #result.entries==40 and result.truncated and not result.complete and result.scanComplete)
    assert(result.entries[1].metadata.incomePerSecond==45 and result.eligibleIncome==45)
end)
check("incomplete inventory traversal prevents claims of unique UID income", function()
    for i=1,257 do configuredTool("Bird","id"..i,i,"Uncommon") end
    local result=funcs.toolCatalog()
    assert(result.total==256 and not result.scanComplete and result.eligibleIncome==0)
end)
check("bounded Configuration child read never silently becomes complete", function()
    local _,config=configuredTool("Bird","a",18,"Uncommon")
    for i=1,65 do config.children[i]=node("Cosmetic"..i,"Folder") end
    local item=funcs.toolCatalog().entries[1]
    assert(not item.metadata.complete and item.uidBinding.status=="incomplete_tool_read" and not item.eligibleForIncome)
end)
check("inventory Configuration observations do not score a nearby field egg of the same kind", function()
    configuredTool("Bird","a",18,"Uncommon");local p=qualityPrompt(3,nil,"Bird")
    env.eggSelect.mode="Income";local exported=funcs.eggExport()
    assert(exported.eggSelection.catalog.tools.eligibleIncome==1 and exported.eggSelection.catalog.knownIncome==0)
    assert(funcs.eggMeta(p).incomePerSecond==nil and not funcs.eggRank(root,humanoid,false)[1].accepted)
end)
check("AssetEgg Tool and other inventory tools retain explicit separate kinds", function()
    configuredTool("Bird Egg","egg-a",nil,nil,"AssetEgg");configuredTool("Bird","pet-a",18,"Uncommon","Asset")
    local result=funcs.toolCatalog()
    assert(result.entries[1].kind=="other_inventory_tool" and result.entries[2].kind=="asset_egg_tool")
end)
check("foreign Owner value blocks stale matching PlotSign",function()
    local owner=node("Owner","IntValue");owner.Value=99
    local label=node("PlayerName","TextLabel");label.Text="TestPlayer"
    plotFixture=node("Plots","Folder",{}, {node("1","Model",{}, {owner,node("PlotSign","Part",{}, {label}),node("SpawnPoint","Part")})})
    assert(not funcs.resolveHome())
end)
check("matching username cannot override a foreign owner attribute",function()
    plotFixture=node("Plots","Folder",{}, {node("1","Model",{OwnerUserId=99,Username="TestPlayer"},{node("SpawnPoint","Part")})})
    assert(not funcs.resolveHome())
end)
check("local Owner value cannot override contradictory plot attributes",function()
    local owner=node("Owner","IntValue");owner.Value=42
    plotFixture=node("Plots","Folder",{}, {node("1","Model",{OwnerUserId=99},{owner,node("SpawnPoint","Part")})})
    assert(not funcs.resolveHome())
end)
check("consistent owner value and attributes still confirm home",function()
    local owner=node("Owner","IntValue");owner.Value=42
    plotFixture=node("Plots","Folder",{}, {node("1","Model",{OwnerUserId=42,Username="TestPlayer"},{owner,node("SpawnPoint","Part")})})
    assert(funcs.resolveHome())
end)
check("foreign owner attributes on PlotSign block stale matching text",function()
    local text=node("PlayerName","TextLabel");text.Text="TestPlayer"
    local sign=node("PlotSign","Part",{OwnerUserId=99},{text})
    plotFixture=node("Plots","Folder",{}, {node("1","Model",{}, {sign,node("SpawnPoint","Part")})})
    assert(not funcs.resolveHome())
end)
check("duplicate AssetEgg UIDs make inventory comparison incomplete",function()
    local before=funcs.inventory();backpackChildren={eggTool("AssetEgg"),eggTool("AssetEgg")}
    local after=funcs.inventory();assert(not after.complete and after.count==1 and #funcs.diff(before,after)==0)
end)
check("same AssetEgg instance in both containers is not a duplicate UID",function()
    local tool=eggTool("AssetEgg");backpackChildren={tool};equippedChildren={tool}
    local inventory=funcs.inventory();assert(inventory.complete and inventory.count==1)
end)
check("blank AssetEgg UID cannot confirm an inventory change",function()
    local tool=eggTool("AssetEgg")
    function tool:GetAttribute(key) if key=="ItemType" then return "AssetEgg" elseif key=="UID" then return " " end end
    backpackChildren={tool};assert(not funcs.inventory().complete)
end)
check("Hatch rechecks plot ownership after movement before sending input",function()
    local center=node("CenterPoint","Part");center.Position=position(40)
    local plot=node("1","Model",{OwnerUserId=42},{center,node("SpawnPoint","Part")})
    plotFixture=node("Plots","Folder",{}, {plot})
    local ready=prompt(40);ready.ActionText="Hatch!";env.promptCache[ready]=true
    onWait=function() plot.attrs.OwnerUserId=99 end
    runHatch(false)
    assert(ready.began==0 and env.hatch.last:find("ownership changed",1,true))
end)
check("nonfinite or negative currency cannot authorize an upgrade",function()
    for _,cash in ipairs({math.huge,0/0,-1}) do
        local calls=setupUpgrade(cash);funcs.upgrade();assert(calls()==0 and not env.upgrades.pending)
    end
end)
check("overflowed currency prices are not valid costs",function()
    assert(funcs.cost("$"..string.rep("9",400))==nil)
end)
check("upgrade never fires a replaced button after approach",function()
    function humanoid:UnequipTools() end
    local calls,_,button=setupUpgrade(3000000);root.Position=position(0)
    onWait=function()
        local price=node("Cost","TextLabel");price.Text="$1M"
        local replacement=node("Upgrade","ImageButton",{}, {price});replacement.Parent=button.Parent
        replacement.MouseButton1Click={};replacement.Activated={}
        button.Parent.children[1]=replacement
    end
    funcs.upgrade();assert(calls()==0 and not env.upgrades.pending)
end)
check("upgrade waits for recheck if soft currency price changes during movement",function()
    function humanoid:UnequipTools() end
    local calls,_,button=setupUpgrade(3000000);root.Position=position(0)
    onWait=function() button:FindFirstChild("Cost").Text="$2M" end
    funcs.upgrade();assert(calls()==0 and not env.upgrades.pending)
end)
check("unexpected Collect error pauses instead of retrying the faulting action",function()
    local p=qualityPrompt(3,nil,nil)
    function p:IsDescendantOf() error("mock candidate fault") end
    funcs.dispatch();assert(not env.collectEgg.enabled and env.collectEgg.phase=="PAUSED" and p.began==0)
    assert(env.collectEgg.pausedReason:find("mock candidate fault",1,true))
end)
local function definitionFixture()
    local assets=node("Assets","ModuleScript")
    local rarity=node("Rarity","ModuleScript")
    local earnings=node("AssetEarnings","ModuleScript")
    local storage=node("ReplicatedStorage","Folder",{}, {node("Data","Folder",{}, {assets,rarity}),node("Shared","Folder",{}, {node("Util","Folder",{}, {earnings})})})
    env.game={PlaceId=107778070777162,GetService=function(_,name) assert(name=="ReplicatedStorage");return storage end}
    return storage,assets,rarity,earnings
end
check("definition reader loads only the three observed allowlisted ModuleScripts",function()
    local _,assets,rarity,earnings=definitionFixture();local called={}
    env.require=function(module)
        assert(module==assets or module==rarity or module==earnings);called[#called+1]=module
        return module==assets and {Catfish={perSecond=12,rarity="Uncommon"}} or {Common={Index=1}}
    end
    local ok,result=funcs.definitions()
    assert(ok and #called==3 and #result.modules==3 and result.modulesInitializedByRequire and not result.rankingApplied)
    assert(result.modules[1].snapshot.data.Catfish.perSecond==12 and not env.busy)
end)
check("exported earnings functions are described without being invoked",function()
    definitionFixture();local invoked=0
    env.require=function() return function() invoked=invoked+1;error("must not be invoked") end end
    local ok,result=funcs.definitions()
    assert(ok and invoked==0 and result.modules[3].snapshot.returnedType=="function" and result.modules[3].snapshot.data=="<function>")
end)
check("definition snapshots prioritize observed category and rate fields before cosmetics",function()
    local data={};for i=1,180 do data["Cosmetic"..i]={Value=i} end
    data.Catfish={perSecond=12,rarity="Uncommon"}
    local snapshot=funcs.definitionSnapshot(data,{"Catfish"})
    assert(snapshot.data.Catfish.perSecond==12 and snapshot.data.Catfish.rarity=="Uncommon" and not snapshot.complete)
end)
check("definition table inspection does not trigger metatable index or pairs functions",function()
    local tableValue=setmetatable({BaseIncome=12},{__index=function() error("index invoked") end,__pairs=function() error("pairs invoked") end})
    local snapshot=funcs.definitionSnapshot(tableValue,{"Catfish"})
    assert(snapshot.data.BaseIncome==12)
end)
check("definition snapshots disclose cycles depth and entry limits",function()
    local data={};data.cycle=data;data.deep={a={b={c={d=1}}}}
    local snapshot=funcs.definitionSnapshot(data,{})
    assert(snapshot.data.cycle=="<cycle>" and not snapshot.complete)
    assert(snapshot.visited<=256)
end)
check("module load failures are reported and do not strand scan state",function()
    definitionFixture();env.require=function() error("mock require failure") end
    local ok,result=funcs.definitions()
    assert(ok and result.modules[1].status=="load_error" and result.modules[1].error:find("mock require failure",1,true) and not env.busy)
    assert(funcs.definitions())
end)
check("duplicate module names reject the path instead of choosing the first",function()
    local storage=definitionFixture();local data=storage:FindFirstChild("Data")
    data.children[#data.children+1]=node("Assets","ModuleScript")
    assert(not funcs.definitionTarget(storage,{"Data","Assets"}))
    env.require=function(module) assert(module.Name~="Assets");return {} end
    local _,result=funcs.definitions();assert(result.modules[1].status=="ambiguous_path")
end)
check("non-module objects and missing definition paths are diagnosed",function()
    local storage,assets=definitionFixture();assets.ClassName="Folder"
    storage:FindFirstChild("Data").children[2]=nil
    env.require=function() return {} end
    local _,result=funcs.definitions();assert(result.modules[1].status=="not_module_script" and result.modules[2].status=="not_found")
end)
check("module read timeout ignores late output without cancelling game initialization",function()
    definitionFixture();local pendingFn
    env.require=function() return {LateIncome=999} end
    env.task.spawn=function(fn) pendingFn=fn end
    local ok,result=funcs.definitions()
    assert(not ok and result.status=="timeout" and result.modules[1].lateResultIgnored and not env.busy)
    local again,message=funcs.definitions();assert(not again and message:find("still loading",1,true))
    pendingFn();assert(result.modules[1].status=="timeout" and not result.modules[1].snapshot)
end)
check("closing hub during a module load cancels observation and clears busy state",function()
    definitionFixture();env.task.spawn=function() end
    onWait=function() env.active=false end
    local ok,result=funcs.definitions()
    assert(not ok and result.status=="cancelled" and not env.busy)
end)
check("definition scanning never overlaps another scan",function()
    definitionFixture();env.busy=true
    local ok,message=funcs.definitions();assert(not ok and message:find("scan",1,true) and env.busy)
end)
check("game module observation errors are recoverable",function()
    env.game={GetService=function() error("mock storage unavailable") end}
    local ok,result=funcs.definitions();assert(not ok and result.status=="error" and not env.busy)
    definitionFixture();env.require=function() return {} end;assert(funcs.definitions())
end)
check("definition exports stay separate from field income selection",function()
    definitionFixture();env.require=function() return {Bird={IncomePerSecond=999,Rarity="Rare"}} end
    assert(funcs.definitions());local p=qualityPrompt(3,nil,"Bird");env.eggSelect.mode="Income"
    local report=funcs.eggExport()
    assert(report.eggSelection.definitionDiscovery and report.eggSelection.catalog.knownIncome==0)
    assert(not funcs.eggRank(root,humanoid,false)[1].accepted and not funcs.eggMeta(p).incomePerSecond)
end)
check("definition sampling uses observed Category rather than Tool names",function()
    definitionFixture();local tool=configuredTool("Misleading name","a",12,"Uncommon");tool.attrs.Category="Catfish"
    env.require=function() return {Catfish={perSecond=12},["Misleading name"]={perSecond=999}} end
    local _,result=funcs.definitions()
    assert(result.categories[1]=="Catfish" and result.categories[2]==nil)
end)
check("definition export string limits preserve UTF-8 boundaries",function()
    local value=funcs.sourceScalar("x"..string.rep("ก",100))
    assert(#value<=160 and utf8.len(value)~=nil)
    local snapshot=funcs.definitionSnapshot({Description="x"..string.rep("ก",100)},{})
    assert(utf8.len(snapshot.data.Description)~=nil)
end)
print(string.format("%d Auto Collect tests passed", tests))
