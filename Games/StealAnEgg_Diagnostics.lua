-- Steal An Egg: structure diagnostics v1.2
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
local scan = button("Scan", 0.01, 0.18)
local copy = button("Copy all", 0.20, 0.19)
local save = button("Save file", 0.40, 0.19)
local selectText = button("Select page", 0.60, 0.23)
local close = button("Close", 0.84, 0.15)
local previous = button("< Page", 0.01, 0.18)
local following = button("Page >", 0.20, 0.19)
previous.Position = UDim2.new(0.01, 0, 0, 50)
following.Position = UDim2.new(0.20, 0, 0, 50)
local pageLabel = Instance.new("TextLabel", frame)
pageLabel.Position = UDim2.new(0.40, 0, 0, 50)
pageLabel.Size = UDim2.new(0.59, 0, 0, 38)
pageLabel.BackgroundTransparency = 1
pageLabel.TextColor3 = Color3.new(1, 1, 1)
pageLabel.Text = "v1.2 | Waiting for scan"
local status = Instance.new("TextLabel", frame)
status.Position = UDim2.new(0.01, 0, 0, 90)
status.Size = UDim2.new(0.98, 0, 0, 38)
status.BackgroundTransparency = 1
status.TextColor3 = Color3.new(1, 1, 1)
status.TextWrapped = true
status.Text = "Diagnostics only. All five automation features await game data."
local box = Instance.new("TextBox", frame)
box.Position = UDim2.new(0.01, 0, 0, 135)
box.Size = UDim2.new(0.98, 0, 1, -145)
box.MultiLine = true
box.ClearTextOnFocus = false
box.TextEditable = true
box.TextXAlignment = Enum.TextXAlignment.Left
box.TextYAlignment = Enum.TextYAlignment.Top
box.TextSize = 12
box.TextWrapped = false
box.Text = "Loading..."
local reportText = ""
local active = true
local pages, pageIndex = {}, 1
local function showPage()
    box.Text = pages[pageIndex] or "No report yet"
    pageLabel.Text = string.format("v1.2 | Page %d/%d | %d bytes", pageIndex, #pages, #reportText)
end
local function splitPages(text)
    pages, pageIndex = {}, 1
    local start = 1
    while start <= #text do
        local finish = math.min(start + 5999, #text)
        -- Do not split a UTF-8 codepoint between pages.
        while finish < #text do
            local byte = text:byte(finish + 1)
            if byte < 128 or byte >= 192 then break end
            finish = finish - 1
        end
        table.insert(pages, text:sub(start, finish))
        start = finish + 1
    end
    showPage()
end
local function capability(name)
    local direct = ({setclipboard = setclipboard, toclipboard = toclipboard,
        set_clipboard = set_clipboard, writefile = writefile, readfile = readfile})[name]
    if type(direct) == "function" then return direct end
    if type(getgenv) == "function" then
        local ok, env = pcall(getgenv)
        if ok and type(env) == "table" and type(env[name]) == "function" then return env[name] end
    end
end
local function selectPage()
    if #pages == 0 then status.Text = "Wait for scan to finish."; return end
    showPage()
    box:CaptureFocus()
    task.defer(function()
        if not active then return end
        box.CursorPosition = #box.Text + 1
        box.SelectionStart = 1
    end)
    status.Text = "Selected this page. Press Ctrl+C; paste into a text file. Append each page in order."
end
local busy = false
local lifetime = gui.AncestryChanged:Connect(function(_, parent)
    if parent == nil then active = false end
end)
local function path(obj)
    return obj:GetFullName()
end
local function collect()
    if busy or not active then return end
    busy = true
    scan.Text = "Scanning..."
    local ok, err = pcall(function()
        local report = {version = "1.2", placeId = game.PlaceId,
            scanned = 0, truncated = false, roots = {},
            gui = {}, prompts = {}, remotes = {}, candidates = {}}
        local roots = {
            {object = pg, label = "PlayerGui", budget = 6000},
            {object = workspace, label = "Workspace", budget = 12000},
            {object = game:GetService("ReplicatedStorage"), label = "ReplicatedStorage", budget = 6000},
        }
        local keywords = {"egg", "hatch", "collect", "cash", "money", "upgrade", "tread", "train", "speed", "base", "plot"}
        local function relevant(name)
            name = string.lower(name)
            for _, word in ipairs(keywords) do
                if string.find(name, word, 1, true) then return true end
            end
            return false
        end
        local function visible(obj)
            local node = obj
            while node and node ~= pg do
                if node:IsA("GuiObject") and not node.Visible then return false end
                if node:IsA("LayerCollector") and not node.Enabled then return false end
                node = node.Parent
            end
            return node == pg
        end
        for _, root in ipairs(roots) do
            if not active then return end
            local info = {name = root.label, scanned = 0, dropped = {},
                topLevel = {}, skipped = {}, truncated = false}
            table.insert(report.roots, info)
            local counts = {}
            local function add(kind, item)
                counts[kind] = counts[kind] or 0
                if counts[kind] < 300 then
                    counts[kind] = counts[kind] + 1
                    table.insert(report[kind], item)
                else
                    info.dropped[kind] = (info.dropped[kind] or 0) + 1
                    info.truncated = true
                end
            end
            -- FIFO plus separate budgets prevent large asset trees starving live UI/world.
            local queue, head = {root.object}, 1
            local deadline = os.clock() + 5
            while head <= #queue and info.scanned < root.budget and active do
                if os.clock() > deadline then info.timeLimit = true; break end
                local obj = queue[head]
                head = head + 1
                info.scanned = info.scanned + 1
                local excluded = obj == gui or obj:IsDescendantOf(gui)
                local asset = root.label == "ReplicatedStorage"
                    and obj.Parent == root.object and obj.Name == "Assets"
                if asset then table.insert(info.skipped, path(obj)) end
                if not excluded and not asset then
                    local item = {path = path(obj), class = obj.ClassName}
                    if obj.Parent == root.object and #info.topLevel < 100 then
                        table.insert(info.topLevel, item)
                    end
                    if root.label == "PlayerGui" and
                        (obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox")) then
                        item.text = string.sub(obj.Text, 1, 180)
                        item.visible = visible(obj)
                        add("gui", item)
                    elseif root.label == "Workspace" and obj:IsA("ProximityPrompt") then
                        item.action = obj.ActionText
                        item.object = obj.ObjectText
                        item.enabled = obj.Enabled
                        item.distance = obj.MaxActivationDistance
                        add("prompts", item)
                    elseif obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") or obj:IsA("UnreliableRemoteEvent") then
                        add("remotes", item)
                    elseif (obj:IsA("Model") or obj:IsA("Folder") or obj:IsA("BasePart")
                        or obj:IsA("ValueBase") or obj:IsA("ModuleScript"))
                        and relevant(obj.Name) then
                        if obj:IsA("BasePart") then
                            local pos = obj.Position
                            item.position = {x = pos.X, y = pos.Y, z = pos.Z}
                        end
                        if obj:IsA("ValueBase") then
                            local value = obj.Value
                            if type(value) == "number" or type(value) == "boolean" or type(value) == "string" then
                                item.value = value
                            end
                        end
                        local attrs = {}
                        for key, value in pairs(obj:GetAttributes()) do
                            local lower = string.lower(key)
                            if (lower:find("owner", 1, true) or lower:find("plot", 1, true))
                                and (type(value) == "number" or type(value) == "string" or type(value) == "boolean") then
                                attrs[key] = value
                            end
                        end
                        item.ownership = attrs
                        add("candidates", item)
                    end
                    for _, child in ipairs(obj:GetChildren()) do
                        if #queue < 30000 then table.insert(queue, child)
                        else info.queueLimit = true; info.truncated = true end
                    end
                end
                if info.scanned % 150 == 0 then task.wait() end
            end
            if head <= #queue then info.truncated = true end
            report.scanned = report.scanned + info.scanned
            report.truncated = report.truncated or info.truncated
        end
        reportText = Http:JSONEncode(report)
        if not active then return end
        splitPages(reportText)
        status.Text = string.format("v1.2 | Scanned %d | GUI %d | Prompts %d | Remotes %d | Limited: %s", report.scanned, #report.gui, #report.prompts, #report.remotes, tostring(report.truncated))
    end)
    busy = false
    if active then
        scan.Text = "Scan / Refresh"
        if not ok then status.Text = "Scan failed: " .. tostring(err) end
    end
end
scan.Activated:Connect(function() task.spawn(collect) end)
copy.Activated:Connect(function()
    if busy then status.Text = "Scanning. Wait for completion."; return end
    if reportText == "" then status.Text = "No report. Press Scan first."; return end
    for _, name in ipairs({"setclipboard", "toclipboard", "set_clipboard"}) do
        local fn = capability(name)
        if fn then
            local ok, result = pcall(fn, reportText)
            if ok and result ~= false then
                status.Text = "Copy requested via " .. name .. ". Paste to check. If empty, use Save file or Select page."
                return
            end
        end
    end
    selectPage()
end)
save.Activated:Connect(function()
    if busy then status.Text = "Scanning. Wait for completion."; return end
    if reportText == "" then status.Text = "No report. Press Scan first."; return end
    local writer = capability("writefile")
    if not writer then
        selectPage()
        status.Text = "File saving unavailable. Use Select page, then Ctrl+C for each page."
        return
    end
    local filename = "StealAnEgg_Report_" .. tostring(os.time()) .. ".json"
    local ok, result = pcall(writer, filename, reportText)
    if not ok or result == false then
        status.Text = "File save failed. Use Select page and Ctrl+C."
        return
    end
    local reader = capability("readfile")
    if reader then
        local readOK, saved = pcall(reader, filename)
        if not readOK or saved ~= reportText then
            status.Text = "Could not verify saved file. Use Select page as fallback."
            return
        end
    end
    status.Text = "Saved " .. filename .. " in your executor workspace. Upload that file to chat."
end)
selectText.Activated:Connect(selectPage)
previous.Activated:Connect(function() pageIndex = math.max(1, pageIndex - 1); showPage() end)
following.Activated:Connect(function() pageIndex = math.max(1, math.min(#pages, pageIndex + 1)); showPage() end)
close.Activated:Connect(function() active = false; lifetime:Disconnect(); gui:Destroy() end)
task.spawn(collect)


