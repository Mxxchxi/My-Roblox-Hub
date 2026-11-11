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
function character:FindFirstChild() return root end
function character:FindFirstChildOfClass() return humanoid end
local env = setmetatable({pg = pg, workspace = {}, player = {Character = character},
    active = true, busy = false, hatchRunning = false, collectRunning = false,
    collectEgg = {enabled = true, attempts = 0}, collectAttempts = {}, promptCache = {},
    os = {clock = function() return clock end, time = function() return 123 end},
    task = {wait = function() end}, promptPosition = function(p) return p.position end}, {__index = _G})
env.RaycastParams = {new=function() return {} end}
env.Vector3 = {new=position}
env.Enum = {RaycastFilterType={Exclude="Exclude"},EasingStyle={Linear="Linear"},PlaybackState={Playing="Playing",Completed="Completed",Cancelled="Cancelled"}}
env.TweenInfo = {new=function(duration) return {duration=duration} end}
env.collectLabel = {}
env.math = setmetatable({clamp=function(n,lo,hi) return math.max(lo,math.min(hi,n)) end},{__index=math})
local obstacle, movement, onWait
function env.workspace:Raycast() return obstacle and {} or nil end
env.TweenService = {Create=function(_,target,info,goal)
    local t = {target=target,goal=goal,info=info}
    function t:Play() self.PlaybackState="Playing"; movement=self end
    function t:Cancel() self.PlaybackState="Cancelled" end
    return t
end}
env.task.wait = function()
    clock=clock+0.1
    if onWait then onWait() end
    if movement and movement.PlaybackState == "Playing" then
        root.Position,root.CFrame = movement.goal.CFrame,movement.goal.CFrame
        movement.PlaybackState="Completed"
    end
end
local funcs = assert(load(engine .. "\nreturn {candidate=collectCandidate,approach=approachCandidate,cancel=cancelCollectTween,step=collectStep,dispatch=dispatchCollect,snapshot=collectSnapshot,mark=setManualCarry}", "collect-engine", "t", env))()
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
    env.promptCache, env.collectAttempts = {}, {}
    env.collectEgg = {enabled = true, attempts = 0}
    env.active, env.busy, env.hatchRunning = true, false, false
    carrying, failInput, clock = false, false, 10
    humanoid.Health = 100
    root.Position,root.CFrame = position(0),position(0)
    obstacle,movement,onWait = false,nil,nil
    env.collectRunning=false
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
    function character:GetChildren() return {{Name="ObservedObject", ClassName="Model"}} end
    function character:GetDescendants() return {} end
    function character:GetAttributes() return {SampleState="held"} end
    local e=funcs.snapshot(true).carryEvidence
    assert(e and e.characterAttributes.SampleState == "held")
    assert(e.characterChildren[1].name == "ObservedObject")
    assert(e.manualMarker == false)
end)
print(string.format("%d Auto Collect tests passed", tests))
