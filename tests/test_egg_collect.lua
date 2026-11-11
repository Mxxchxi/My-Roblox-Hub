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
local obstacle, movement, onWait, mockRoute, walkGoal, tweenCreated
function humanoid:MoveTo(goal) walkGoal=goal end
function env.workspace:Raycast(origin,delta)
    if type(obstacle) == "function" then return obstacle(origin,delta) and {} or nil end
    return obstacle and {} or nil
end
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
local funcs = assert(load(engine .. "\nreturn {candidate=collectCandidate,approach=approachCandidate,cancel=cancelCollectTween,step=collectStep,dispatch=dispatchCollect,snapshot=collectSnapshot,mark=setManualCarry,inventory=eggInventory,diff=newInventoryEggs,home=setDeliveryPoint,returnHome=returnHome,navigate=pathMove,record=recordGameEvent,updateCarry=updateServerCarry,resetServer=function() serverCarry=nil end}", "collect-engine", "t", env))()
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
    funcs.mark(false)
    funcs.resetServer()
    equippedChildren,backpackChildren = {},{}
    function character:GetChildren() return equippedChildren end
    env.promptCache, env.collectAttempts = {}, {}
    env.collectEgg = {enabled = true, attempts = 0}
    env.active, env.busy, env.hatchRunning = true, false, false
    carrying, failInput, clock = false, false, 10
    humanoid.Health = 100
    root.Position,root.CFrame = position(0),position(0)
    obstacle,movement,onWait,mockRoute,walkGoal,tweenCreated = false,nil,nil,nil,nil,0
    env.collectRunning=false
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
    humanoid.Health = 100; p.HoldDuration = 6; assert(funcs.candidate(p,root,humanoid) == nil)
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
print(string.format("%d Auto Collect tests passed", tests))
