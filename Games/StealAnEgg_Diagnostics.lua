-- Steal An Egg: structure diagnostics v1.6
-- Auto Hatch test via nearby enabled prompts; other automation awaits argument mapping.
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
local selectText = button("Select ALL", 0.60, 0.23)
local close = button("Close", 0.84, 0.15)
local previous = button("< Page", 0.01, 0.18)
local following = button("Page >", 0.20, 0.19)
previous.Position = UDim2.new(0.01, 0, 0, 50)
following.Position = UDim2.new(0.20, 0, 0, 50)
local shortCopy = button("Copy short", 0.40, 0.19)
shortCopy.Position = UDim2.new(0.40, 0, 0, 50)
local pageLabel = Instance.new("TextLabel", frame)
pageLabel.Position = UDim2.new(0.60, 0, 0, 50)
pageLabel.Size = UDim2.new(0.39, 0, 0, 38)
pageLabel.BackgroundTransparency = 1
pageLabel.TextColor3 = Color3.new(1, 1, 1)
pageLabel.Text = "v1.6 | Waiting for scan"
local status = Instance.new("TextLabel", frame)
status.Position = UDim2.new(0.01, 0, 0, 137)
status.Size = UDim2.new(0.98, 0, 0, 38)
status.BackgroundTransparency = 1
status.TextColor3 = Color3.new(1, 1, 1)
status.TextWrapped = true
status.Text = "Auto Hatch test available (OFF). Other four systems await action mapping."
local box = Instance.new("TextBox", frame)
box.Position = UDim2.new(0.01, 0, 0, 182)
box.Size = UDim2.new(0.98, 0, 1, -192)
box.MultiLine = true
box.ClearTextOnFocus = false
box.TextEditable = true
box.TextXAlignment = Enum.TextXAlignment.Left
box.TextYAlignment = Enum.TextYAlignment.Top
box.TextSize = 12
box.TextWrapped = false
box.Text = "Loading..."
local reportText = ""
local shortReportText = ""
local active = true
local pages, pageIndex = {}, 1
local function showPage()
    box.Text = pages[pageIndex] or "No report yet"
    pageLabel.Text = string.format("v1.6 | Page %d/%d | %d bytes", pageIndex, #pages, #reportText)
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
        set_clipboard = set_clipboard, getclipboard = getclipboard,
        readclipboard = readclipboard, writefile = writefile, readfile = readfile})[name]
    if type(direct) == "function" then return direct end
    for _, getter in pairs({getgenv = getgenv, getrenv = getrenv}) do
        if type(getter) == "function" then
            local ok, env = pcall(getter)
            if ok and type(env) == "table" and type(env[name]) == "function" then return env[name] end
        end
    end
    if type(_G) == "table" and type(_G[name]) == "function" then return _G[name] end
end
local function nativeSelect(text)
    -- Full report, never just the currently displayed page.
    box:CaptureFocus()
    box.Text = text
    if box.Text ~= text then
        status.Text = "TextBox could not hold full report. Try Copy short."
        return false
    end
    task.defer(function()
        if not active then return end
        box.CursorPosition = #box.Text + 1
        box.SelectionStart = 1
    end)
    pageLabel.Text = "v1.6 | ALL selected | " .. #text .. " bytes"
    return true
end
local function selectAll()
    if reportText == "" then status.Text = "Wait for scan to finish."; return end
    if nativeSelect(reportText) then
        status.Text = "ALL selected. Press Ctrl+C on TEST PC, then paste. Remote clipboard sync must be enabled."
    end
end
local function copyPayload(text, label)
    local errors = {}
    local reader = capability("getclipboard") or capability("readclipboard")
    local unverified = false
    local writers = {}
    local seen = {}
    local function add(name, fn)
        if type(fn) == "function" and not seen[fn] then
            seen[fn] = true
            table.insert(writers, {name = name, fn = fn})
        end
    end
    for _, name in ipairs({"setclipboard", "toclipboard", "set_clipboard"}) do add(name, capability(name)) end
    if type(clipboard) == "table" then
        add("clipboard.set", clipboard.set)
        add("clipboard.setclipboard", clipboard.setclipboard)
    end
    if type(syn) == "table" then add("syn.write_clipboard", syn.write_clipboard) end
    for _, writer in ipairs(writers) do
        local ok, result = pcall(writer.fn, text)
        if ok and result ~= false then
            local readable, matched = false, false
            if reader then
                for attempt = 1, 3 do
                    task.wait(0.08)
                    if not active then return end
                    local readOK, value = pcall(reader)
                    if readOK and type(value) == "string" then
                        readable = true
                        if value == text then matched = true; break end
                    end
                end
            end
            if matched then
                status.Text = label .. " VERIFIED on TEST PC (" .. #text .. " bytes). Remote clipboard sync is separate."
                return
            end
            if not readable then unverified = true end
            table.insert(errors, writer.name .. (readable and ": readback mismatch" or ": cannot verify"))
        else
            table.insert(errors, writer.name .. ": failed")
        end
    end
    -- Even a no-op executor API now leaves a real, full selection for native Ctrl+C.
    if not active then return end
    local selected = nativeSelect(text)
    if selected then
        local reason = #writers == 0 and "No clipboard API" or (unverified and "Copy API unverified" or "Clipboard write failed")
        status.Text = reason .. ". ALL selected: press Ctrl+C on TEST PC. " .. label .. " (" .. #text .. " bytes)."
    end
    warn("[Egg Diagnostics] " .. table.concat(errors, "; "))
end
local busy = false
-- AUTO_HATCH_BEGIN
local hatchButton = button("Auto Hatch: OFF", 0.01, 0.27)
hatchButton.Position = UDim2.new(0.01, 0, 0, 94)
local testHatch = button("Test Hatch once", 0.29, 0.23)
testHatch.Position = UDim2.new(0.29, 0, 0, 94)
local hatchLabel = Instance.new("TextLabel", frame)
hatchLabel.Position = UDim2.new(0.54, 0, 0, 94)
hatchLabel.Size = UDim2.new(0.45, 0, 0, 38)
hatchLabel.BackgroundTransparency = 1
hatchLabel.TextColor3 = Color3.new(1, 1, 1)
hatchLabel.TextWrapped = true
hatchLabel.Text = "Stand within 7 studs of your ready egg."
local hatch = {enabled = false, attempts = 0, last = "OFF"}
local promptCache = setmetatable({}, {__mode = "k"})
local attemptState = setmetatable({}, {__mode = "k"})
local connections = {}
local holding
local function trackPrompt(obj)
    if obj:IsA("ProximityPrompt") then promptCache[obj] = true end
end
local function promptPosition(prompt)
    local parent = prompt.Parent
    if parent and parent:IsA("Attachment") then return parent.WorldPosition end
    if parent and parent:IsA("BasePart") then return parent.Position end
    if parent and parent:IsA("Model") then return parent:GetPivot().Position end
end
local function eligible(prompt, root, humanoid)
    if not prompt.Parent or not prompt:IsDescendantOf(workspace) then return false end
    -- Only the exact action observed in the report. Never target Steal/Skip/Mutation.
    if prompt.ActionText ~= "Hatch!" or not prompt.Enabled then return false end
    if not root or not humanoid or humanoid.Health <= 0 then return false end
    if prompt.HoldDuration < 0 or prompt.HoldDuration > 5 then return false end
    local position = promptPosition(prompt)
    if not position then return false end
    return (root.Position - position).Magnitude <= math.min(prompt.MaxActivationDistance, 7)
end
local function hatchStep(manual)
    if not active or (not hatch.enabled and not manual) then return end
    if busy then hatch.last = "Paused during scan"; hatchLabel.Text = hatch.last; return end
    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if not root or not humanoid then hatch.last = "Waiting for character"; return end
    for prompt in pairs(promptCache) do
        if eligible(prompt, root, humanoid) then
            local state = attemptState[prompt] or {count = 0, time = -math.huge}
            attemptState[prompt] = state
            if state.count < 3 and os.clock() - state.time >= 4 then
                state.count = state.count + 1
                state.time = os.clock()
                hatch.attempts = hatch.attempts + 1
                local ok, err = pcall(function()
                    holding = prompt
                    prompt:InputHoldBegin()
                    task.wait(prompt.HoldDuration + 0.1)
                    prompt:InputHoldEnd()
                    holding = nil
                end)
                if holding then pcall(function() holding:InputHoldEnd() end); holding = nil end
                if not active then return end
                hatch.last = ok and "Hatch input sent; check game result" or ("Input failed: " .. tostring(err):sub(1, 80))
                hatchLabel.Text = hatch.last .. " | Attempts " .. hatch.attempts
                return
            end
        end
    end
    hatch.last = "Waiting for nearby Hatch! (max 3 attempts per prompt per toggle)"
    hatchLabel.Text = hatch.last
end
connections[#connections + 1] = workspace.DescendantAdded:Connect(trackPrompt)
connections[#connections + 1] = workspace.DescendantRemoving:Connect(function(obj)
    promptCache[obj] = nil
    attemptState[obj] = nil
end)
connections[#connections + 1] = game:GetService("ProximityPromptService").PromptShown:Connect(trackPrompt)
hatchButton.Activated:Connect(function()
    hatch.enabled = not hatch.enabled
    attemptState = setmetatable({}, {__mode = "k"})
    hatchButton.Text = hatch.enabled and "Auto Hatch: ON" or "Auto Hatch: OFF"
    hatch.last = hatch.enabled and "Waiting for nearby Hatch!" or "OFF"
    hatchLabel.Text = hatch.last
    if not hatch.enabled and holding then pcall(function() holding:InputHoldEnd() end); holding = nil end
end)
local hatchRunning = false
local function dispatchHatch(manual)
    if hatchRunning then return end
    hatchRunning = true
    local ok, err = pcall(hatchStep, manual)
    hatchRunning = false
    if not ok and active then
        hatch.last = "Hatch test error: " .. tostring(err):sub(1, 100)
        hatchLabel.Text = hatch.last
    end
end
testHatch.Activated:Connect(function() task.spawn(dispatchHatch, true) end)
local function liveHatchSnapshot()
    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    local snapshot = {enabled = hatch.enabled, attempts = hatch.attempts, last = hatch.last,
        scanning = busy, inputInProgress = hatchRunning, cacheCount = 0,
        result = "Input attempts only; hatch success is not verified"}
    if root then snapshot.characterPosition = {x = root.Position.X, y = root.Position.Y, z = root.Position.Z} end
    snapshot.alive = humanoid ~= nil and humanoid.Health > 0
    local nearestDistance = math.huge
    for prompt in pairs(promptCache) do
        snapshot.cacheCount = snapshot.cacheCount + 1
        if prompt.Parent and prompt.ActionText == "Hatch!" and prompt:IsDescendantOf(workspace) then
            local position = promptPosition(prompt)
            local distance = position and root and (root.Position - position).Magnitude or math.huge
            if not snapshot.nearest or distance < nearestDistance then
                nearestDistance = distance
                local state = attemptState[prompt]
                local reason = "Ready to attempt"
                if not snapshot.alive then reason = "Character unavailable/dead"
                elseif not prompt.Enabled then reason = "Prompt disabled"
                elseif not position then reason = "Prompt location unavailable"
                elseif distance > math.min(prompt.MaxActivationDistance, 7) then reason = "Outside activation range"
                elseif prompt.HoldDuration < 0 or prompt.HoldDuration > 5 then reason = "Unsupported hold duration"
                elseif state and state.count >= 3 then reason = "Attempt cap reached; toggle OFF/ON to reset"
                elseif state and os.clock() - state.time < 4 then reason = "Cooldown"
                elseif busy then reason = "Scan in progress"
                elseif hatchRunning then reason = "Input in progress"
                elseif not hatch.enabled then reason = "Auto Hatch OFF; Test Hatch once is available" end
                snapshot.nearest = {path = prompt:GetFullName(), enabled = prompt.Enabled,
                    allowedDistance = math.min(prompt.MaxActivationDistance, 7),
                    holdDuration = prompt.HoldDuration, attempts = state and state.count or 0, reason = reason}
                if distance < math.huge then snapshot.nearest.distance = distance end
            end
        end
    end
    if not snapshot.nearest then snapshot.blocked = "No Hatch! prompt in cache" end
    return snapshot
end
local function refreshExportState()
    if reportText == "" then return end
    local snapshot = liveHatchSnapshot()
    -- Replace the old scan-time snapshot at copy/save time, without rescanning.
    local full = Http:JSONDecode(reportText)
    full.autoHatch = snapshot
    reportText = Http:JSONEncode(full)
    local short = Http:JSONDecode(shortReportText)
    short.autoHatch = snapshot
    shortReportText = Http:JSONEncode(short)
    splitPages(reportText)
end
local function stopHatch()
    active = false
    hatch.enabled = false
    if holding then pcall(function() holding:InputHoldEnd() end); holding = nil end
    for _, connection in ipairs(connections) do connection:Disconnect() end
end
local lifetime = gui.AncestryChanged:Connect(function(_, parent)
    if parent == nil then stopHatch() end
end)
task.spawn(function()
    while active do
        task.wait(1)
        dispatchHatch(false)
        if active and hatch.enabled and not hatchRunning then
            local ok, snapshot = pcall(liveHatchSnapshot)
            if ok then
                local nearest = snapshot.nearest
                hatchLabel.Text = nearest and (nearest.reason .. (nearest.distance and string.format(" | %.1f/%.1f studs", nearest.distance, nearest.allowedDistance) or ""))
                    or (snapshot.blocked or hatch.last)
            end
        end
    end
end)
-- AUTO_HATCH_END
local function path(obj)
    return obj:GetFullName()
end
local function collect()
    if busy or not active then return end
    busy = true
    scan.Text = "Scanning..."
    local ok, err = pcall(function()
        local report = {version = "1.6", placeId = game.PlaceId,
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
                        trackPrompt(obj)
                        item.action = obj.ActionText
                        item.object = obj.ObjectText
                        item.enabled = obj.Enabled
                        item.distance = obj.MaxActivationDistance
                        item.holdDuration = obj.HoldDuration
                        local parent = obj.Parent
                        local location
                        if parent and parent:IsA("Attachment") then location = parent.WorldPosition
                        elseif parent and parent:IsA("BasePart") then location = parent.Position
                        elseif parent and parent:IsA("Model") then location = parent:GetPivot().Position end
                        if location then item.position = {x = location.X, y = location.Y, z = location.Z} end
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
        -- Inventory the observed networking folder directly, bypassing the generic
        -- result cap. This only reads Instances; no Remote is invoked.
        local storage = game:GetService("ReplicatedStorage")
        local packages = storage:FindFirstChild("Packages")
        local networking = packages and packages:FindFirstChild("Networking")
        report.networking = {found = networking ~= nil, scanned = 0, truncated = false}
        if networking then
            local known = {}
            for _, item in ipairs(report.remotes) do known[item.path] = true end
            local queue, head = {networking}, 1
            while head <= #queue and report.networking.scanned < 4000 and active do
                local obj = queue[head]
                head = head + 1
                report.networking.scanned = report.networking.scanned + 1
                if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") or obj:IsA("UnreliableRemoteEvent") then
                    local fullPath = path(obj)
                    if not known[fullPath] then
                        table.insert(report.remotes, {path = fullPath, name = obj.Name, class = obj.ClassName})
                        known[fullPath] = true
                    end
                end
                for _, child in ipairs(obj:GetChildren()) do
                    if #queue < 8000 then table.insert(queue, child)
                    else report.networking.truncated = true end
                end
                if report.networking.scanned % 150 == 0 then task.wait() end
            end
            if head <= #queue then report.networking.truncated = true end
        end
        -- Rank gameplay systems ahead of unrelated live events and cosmetics.
        local function rank(item, kind)
            local name = string.lower((item.path or "") .. " " .. (item.text or "") .. " " .. (item.action or ""))
            local score = 0
            for _, word in ipairs({"hatch", "treadmill", "upgrade", "egg", "plot", "base", "cash", "money", "coin", "speed", "penroster"}) do
                if name:find(word, 1, true) then score = score + 10 end
            end
            if name:find("trainevent", 1, true) or name:find("liveevents", 1, true)
                or name:find("sammy", 1, true) or name:find("lightvsdarkness", 1, true)
                or name:find("beanstalk", 1, true) or name:find("observability", 1, true)
                or name:find("adgrowth", 1, true) or name:find("adegg", 1, true)
                or name:find("cmdr", 1, true) or name:find("ghostboss", 1, true) then score = score - 100 end
            if kind == "gui" and item.visible then score = score + 3 end
            if kind == "prompts" and item.enabled then score = score + 5 end
            return score
        end
        local function sorted(kind)
            local items = {}
            for _, item in ipairs(report[kind]) do table.insert(items, item) end
            table.sort(items, function(a, b)
                local ar, br = rank(a, kind), rank(b, kind)
                if ar ~= br then return ar > br end
                return a.path < b.path
            end)
            return items
        end
        report.autoHatch = liveHatchSnapshot()
        reportText = Http:JSONEncode(report)
        local summary = {version = "1.6", placeId = report.placeId, summaryOnly = true,
            scanned = report.scanned, truncated = report.truncated, networking = report.networking, autoHatch = report.autoHatch,
            gui = {}, prompts = {}, remotes = {}, candidates = {},
            omitted = {gui = 0, prompts = 0, remotes = 0, candidates = 0}}
        -- Each category owns its own space: remote spam cannot erase GUI/prompts.
        local limits = {remotes = 6000, gui = 3000, prompts = 2000, candidates = 3000}
        for _, kind in ipairs({"remotes", "gui", "prompts", "candidates"}) do
            local seen, used = {}, 0
            for _, item in ipairs(sorted(kind)) do
                local useful = rank(item, kind) > 0 or kind == "prompts" and item.enabled
                local small = {}
                for key, value in pairs(item) do small[key] = value end
                -- Ownership/position retained on candidates; duplicates retain count.
                local key = Http:JSONEncode(item)
                if useful and seen[key] then
                    seen[key].count = (seen[key].count or 1) + 1
                    summary.omitted[kind] = summary.omitted[kind] + 1
                elseif useful then
                    local bytes = #Http:JSONEncode(small) + 24
                    if used + bytes <= limits[kind] then
                        table.insert(summary[kind], small)
                        seen[key] = small
                        used = used + bytes
                    else summary.omitted[kind] = summary.omitted[kind] + 1 end
                else summary.omitted[kind] = summary.omitted[kind] + 1 end
            end
        end
        shortReportText = Http:JSONEncode(summary)
        if not active then return end
        splitPages(reportText)
        status.Text = string.format("v1.6 | Scanned %d | GUI %d | Prompts %d | Remotes %d | Limited: %s", report.scanned, #report.gui, #report.prompts, #report.remotes, tostring(report.truncated))
    end)
    busy = false
    if active then
        scan.Text = "Scan / Refresh"
        if not ok then status.Text = "Scan failed: " .. tostring(err) end
    end
end
scan.Activated:Connect(function() task.spawn(collect) end)
local copying = false
local function exportCopy(short)
    if busy or copying then status.Text = "Please wait for scan/copy to finish."; return end
    if reportText == "" then status.Text = "No report. Press Scan first."; return end
    copying = true
    status.Text = "Copying on TEST PC..."
    task.spawn(function()
        local ok, err = pcall(function()
            refreshExportState()
            copyPayload(short and shortReportText or reportText, short and "SHORT report" or "FULL report")
        end)
        copying = false
        if not ok and active then
            status.Text = "Copy error: " .. tostring(err):sub(1, 120) .. ". Try Select ALL, then Ctrl+C."
        end
    end)
end
copy.Activated:Connect(function() exportCopy(false) end)
shortCopy.Activated:Connect(function() exportCopy(true) end)
save.Activated:Connect(function()
    if busy then status.Text = "Scanning. Wait for completion."; return end
    if reportText == "" then status.Text = "No report. Press Scan first."; return end
    local refreshed, refreshError = pcall(refreshExportState)
    if not refreshed then status.Text = "Export refresh failed: " .. tostring(refreshError):sub(1, 100); return end
    local writer = capability("writefile")
    if not writer then
        selectAll()
        status.Text = "File saving unavailable. Use Select ALL, then Ctrl+C for the full report."
        return
    end
    local filename = "StealAnEgg_Report_" .. tostring(os.time()) .. ".json"
    local ok, result = pcall(writer, filename, reportText)
    if not ok or result == false then
        status.Text = "File save failed. Use Select ALL and Ctrl+C."
        return
    end
    local reader = capability("readfile")
    if reader then
        local readOK, saved = pcall(reader, filename)
        if not readOK or saved ~= reportText then
            status.Text = "Could not verify saved file. Use Select ALL as fallback."
            return
        end
    end
    status.Text = "Saved " .. filename .. " in your executor workspace. Upload that file to chat."
end)
selectText.Activated:Connect(selectAll)
previous.Activated:Connect(function() pageIndex = math.max(1, pageIndex - 1); showPage() end)
following.Activated:Connect(function() pageIndex = math.max(1, math.min(#pages, pageIndex + 1)); showPage() end)
close.Activated:Connect(function() stopHatch(); lifetime:Disconnect(); gui:Destroy() end)
task.spawn(collect)






