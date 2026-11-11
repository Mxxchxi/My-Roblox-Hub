-- Run from repository root with Lua 5.3+.
local file = assert(io.open("Games/StealAnEgg_Diagnostics.lua", "r"))
local source = file:read("*a"); file:close()
local engine = assert(source:match("%-%- AUTO_COLLECT_ENGINE_BEGIN(.-)%-%- AUTO_COLLECT_ENGINE_END"))
local function position(x)
    return setmetatable({x = x}, {__sub = function(a,b) return {Magnitude = math.abs(a.x-b.x)} end})
end
local root, humanoid = {Position = position(0)}, {Health = 100}
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
local funcs = assert(load(engine .. "\nreturn {candidate=collectCandidate,step=collectStep,dispatch=dispatchCollect,snapshot=collectSnapshot}", "collect-engine", "t", env))()
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
    env.promptCache, env.collectAttempts = {}, {}
    env.collectEgg = {enabled = true, attempts = 0}
    env.active, env.busy, env.hatchRunning = true, false, false
    carrying, failInput, clock = false, false, 10
    humanoid.Health = 100
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
    clock=14; funcs.dispatch(); clock=18; funcs.dispatch(); clock=22; funcs.dispatch()
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
print(string.format("%d Auto Collect tests passed", tests))
