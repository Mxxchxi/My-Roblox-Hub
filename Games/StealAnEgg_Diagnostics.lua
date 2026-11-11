-- Steal An Egg: structure diagnostics v1.0
-- Collects local object metadata only. Does not invoke remotes or buy items.
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
local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0.9, 0, 0.7, 0)
frame.Position = UDim2.new(0.05, 0, 0.15, 0)
frame.BackgroundColor3 = Color3.fromRGB(22, 25, 34)
local function button(label, x, w)
    local b = Instance.new("TextButton", frame)
    b.Position = UDim2.new(x, 0, 0, 8)
    b.Size = UDim2.new(w, 0, 0, 38)
    b.Text = label
    b.TextSize = 14
    return b
end
local scan = button("Scan / Refresh", 0.01, 0.3)
local copy = button("Copy report", 0.32, 0.3)
local close = button("Close", 0.89, 0.1)
local status = Instance.new("TextLabel", frame)
status.Position = UDim2.new(0.01, 0, 0, 48)
status.Size = UDim2.new(0.98, 0, 0, 38)
status.BackgroundTransparency = 1
status.TextColor3 = Color3.new(1, 1, 1)
status.TextWrapped = true
status.Text = "Diagnostics only. All five automation features await game data."
local box = Instance.new("TextBox", frame)
box.Position = UDim2.new(0.01, 0, 0, 90)
box.Size = UDim2.new(0.98, 0, 1, -100)
box.MultiLine = true
box.ClearTextOnFocus = false
box.TextEditable = true
box.TextXAlignment = Enum.TextXAlignment.Left
box.TextYAlignment = Enum.TextYAlignment.Top
box.TextSize = 12
box.TextWrapped = false
box.Text = "Loading..."
local reportText = ""
local busy = false
local active = true
local function path(obj)
    return obj:GetFullName()
end
local function collect()
    if busy or not active then return end
    busy = true
    scan.Text = "Scanning..."
    local ok, err = pcall(function()
        local report = {version = "1.0", placeId = game.PlaceId,
            jobId = game.JobId, scanned = 0, truncated = false,
            gui = {}, prompts = {}, remotes = {}, candidates = {}}
        local roots = {pg, workspace, game:GetService("ReplicatedStorage")}
        local keywords = {"egg", "hatch", "collect", "cash", "money", "upgrade", "tread", "train", "speed", "base", "plot"}
        local stack = {}
        for _, root in ipairs(roots) do table.insert(stack, root) end
        local function add(bucket, value)
            if #bucket < 400 then table.insert(bucket, value) else report.truncated = true end
        end
        while #stack > 0 and report.scanned < 12000 and active do
            local obj = table.remove(stack)
            report.scanned = report.scanned + 1
            if not obj:IsDescendantOf(gui) and obj ~= gui then
                local item = {path = path(obj), class = obj.ClassName}
                if obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox") then
                    item.text = string.sub(obj.Text, 1, 180)
                    item.visible = obj.Visible
                    add(report.gui, item)
                elseif obj:IsA("ProximityPrompt") then
                    item.action = obj.ActionText
                    item.object = obj.ObjectText
                    item.enabled = obj.Enabled
                    item.distance = obj.MaxActivationDistance
                    add(report.prompts, item)
                elseif obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") or obj:IsA("UnreliableRemoteEvent") then
                    add(report.remotes, item)
                else
                    local name = string.lower(obj.Name)
                    for _, word in ipairs(keywords) do
                        if string.find(name, word, 1, true) then
                            add(report.candidates, item)
                            break
                        end
                    end
                end
                for _, child in ipairs(obj:GetChildren()) do table.insert(stack, child) end
            end
            if report.scanned % 150 == 0 then task.wait() end
        end
        if #stack > 0 then report.truncated = true end
        reportText = Http:JSONEncode(report)
        if not active then return end
        box.Text = reportText
        status.Text = string.format("Scanned %d | GUI %d | Prompts %d | Remotes %d | Limited: %s", report.scanned, #report.gui, #report.prompts, #report.remotes, tostring(report.truncated))
    end)
    busy = false
    if active then
        scan.Text = "Scan / Refresh"
        if not ok then status.Text = "Scan failed: " .. tostring(err) end
    end
end
scan.Activated:Connect(function() task.spawn(collect) end)
copy.Activated:Connect(function()
    if reportText == "" then return end
    if type(setclipboard) == "function" then
        local ok = pcall(setclipboard, reportText)
        status.Text = ok and "Copied. Paste the report into chat." or "Copy failed. Select report text manually."
    else
        status.Text = "Clipboard unavailable. Select report text and copy manually."
        box:CaptureFocus()
        box.CursorPosition = #box.Text + 1
        box.SelectionStart = 1
    end
end)
close.Activated:Connect(function() active = false; gui:Destroy() end)
task.spawn(collect)
