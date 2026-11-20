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
    local props = {ClassName = className, Name = className, children = {}, events = {}}
    local obj = {}
    local methods = {}
    function methods:IsA(kind) return kind == props.ClassName end
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
            if key == "Activated" or key == "InputBegan" or key == "InputChanged" or key == "InputEnded" then
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
local takeAllButton = instance("TextButton")
takeAllButton.Name = "ClaimContents"
takeAllButton.Text = ""
takeAllButton.Visible = true
takeAllButton.Parent = gameChestGui
local takeAllLabel = instance("TextLabel")
takeAllLabel.Name = "Caption"
takeAllLabel.Text = "Take All"
takeAllLabel.Parent = takeAllButton
local firedTakeAll = 0
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
    print = function() end,
    warn = function() end,
}, {__index = _G})
env._G = env
env.getgenv = function() return env end

local function run()
    assert(load(source, "@Games/MyAnimeMine.lua", "t", env))()
    return assert(env.MyAnimeMineHubController)
end
local function findButton(name)
    for _, child in ipairs(playerGui:GetDescendants()) do
        if child.ClassName == "TextButton" and child.Name == name then return child end
    end
    error("Button not found: " .. name)
end

local first = run()
assert(playerGui:FindFirstChild("MyAnimeMineHub"), "UI was not mounted")
assert(not first.mine and not first.collect, "auto toggles must start OFF")
assert(#first.detectors == 0 and #first.prompts == 0, "unexpected scan targets")
assert(#first.takeAllButtons == 1, "did not discover Chest Take All button")
findButton("Scan").Activated:Fire()
findButton("CopyLog").Activated:Fire()
assert(clipboard and clipboard:find("PlaceId 79389059854988", 1, true), "copy log unavailable")
findButton("Diagnostics").Activated:Fire()
assert(clipboard and clipboard:find("TakeAll visible: ", 1, true), "target diagnostics missing")

findButton("AutoMine").Activated:Fire()
findButton("AutoCollect").Activated:Fire()
assert(first.mine and first.collect, "toggles not responsive")
local second = run()
assert(not first.running and second.running, "rerun did not clean up previous controller")
local count = 0
for _, child in ipairs(playerGui:GetChildren()) do
    if child.Name == "MyAnimeMineHub" then count = count + 1 end
end
assert(count == 1, "duplicate UI after rerun")
assert(not second.mine and not second.collect, "rerun must begin OFF")
findButton("Close").Activated:Fire()
assert(not second.running and not playerGui:FindFirstChild("MyAnimeMineHub"), "close did not stop")
assert(env.MyAnimeMineHubController == nil, "controller leaked after close")
print("PASS My Anime Mine GUI startup, chest discovery, diagnostics, toggle, rerun, and cleanup")
