-- Roll A Stickman Combined Auto V1.2 R13
-- UI-driven automation for PlaceId 115068315659966.
-- Run once in Potassium. Requires executor firesignal for GuiButton.Activated.
-- Auto Execute: add this complete file to your executor's Auto Execute list.
-- Waiting for game/player/UI readiness is handled below; no remote loader needed.

local startupOk, startupError = xpcall(function()

print("[RAS] R13 starting; waiting for game to load")
if not game:IsLoaded() then game.Loaded:Wait() end
if game.PlaceId ~= 115068315659966 then return end
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local player = Players.LocalPlayer
local playerDeadline = os.clock() + 120
while not player and os.clock() < playerDeadline do
    task.wait(0.2)
    player = Players.LocalPlayer
end
assert(player, "LocalPlayer not ready after 120s; run again after joining")
local pg = player:WaitForChild("PlayerGui", 120)
assert(pg, "PlayerGui not ready after 120s")
assert(pg:WaitForChild("RollAStickman", 120), "RollAStickman UI not ready after 120s")

local SETTINGS_FILE = "RollStickman_Combined_V1_2_settings.json"
local SETTINGS_KEY = "RollStickman_Combined_V1_2_settings"
local settingKeys = {"level", "raid", "dungeon", "expedition", "moon", "antiAfk"}
local potionNames = {luck = "Luck Potion", haste = "Haste Potion", gild = "Gilded Potion"}
local potionConfig = {when = "Aurora", available = {"Aurora"}, selected = {luck = true, haste = true, gild = true}}
local function moonIdentity(value, allowShort)
    if type(value) ~= "string" then return nil end
    local name = value:gsub("<[^>]*>", ""):upper():gsub("%s+", " ")
    name = name:gsub("·", "|"):gsub("•", "|")
    name = name:match("^([^|]+)") or name
    name = name:gsub("^[^A-Z]+", "")
    name = name:gsub("^SUMMON%s+AN?%s+", ""):gsub("^SUMMON%s+", "")
    name = name:match("^(.-)%s+[X×]%s*%d") or name
    name = name:match("^%s*(.-)%s*$")
    local hasMoon = name:match(" MOON$") ~= nil
    name = name:gsub(" MOON$", "")
    if #name < 2 or #name > 40 or not name:match("^[A-Z][A-Z '%-]*$") then return nil end
    if hasMoon or name == "ECLIPSE" or name == "STARFALL" or allowShort then return name end
end
local function moonCaption(key)
    return (key:lower():gsub("%a[%a']*", function(word)
        return word:sub(1, 1):upper() .. word:sub(2)
    end))
end
local function settingsEnv()
    if type(getgenv) == "function" then
        local ok, env = pcall(getgenv)
        if ok and type(env) == "table" then return env end
    end
    if type(shared) == "table" then return shared end
    return _G
end
local function cleanSettings(value)
    if type(value) ~= "table" then return nil end
    if value.placeId and value.placeId ~= game.PlaceId then return nil end
    local from = type(value.flags) == "table" and value.flags or value
    local cleaned = {}
    for _, key in ipairs(settingKeys) do
        cleaned[key] = from[key] == true
    end
    if from.antiAfk == nil then cleaned.antiAfk = true end
    local p = value.position
    local position = type(p) == "table" and type(p.x) == "number"
        and type(p.y) == "number" and {x = p.x, y = p.y} or nil
    local tab = value.activeTab
    if tab ~= "Team" and tab ~= "Fight" and tab ~= "Potion" and tab ~= "Status" then
        tab = "Fight"
    end
    local source = type(value.potion) == "table" and value.potion or {}
    local selections = type(source.selected) == "table" and source.selected or {}
    local potion = {when = moonCaption(moonIdentity(source.when, true) or "AURORA"), available = {"Aurora"}, selected = {}}
    local known = {AURORA = true}
    for _, value in ipairs(type(source.available) == "table" and source.available or {}) do
        local key = moonIdentity(value, true)
        if key and not known[key] then
            known[key] = true
            table.insert(potion.available, moonCaption(key))
        end
    end
    if not known[moonIdentity(potion.when, true)] then table.insert(potion.available, potion.when) end
    for _, id in ipairs({"luck", "haste", "gild"}) do
        potion.selected[id] = selections[id] ~= false
    end
    return cleaned, position, tab, potion
end
local function readSettings()
    if type(readfile) == "function" then
        local ok, content = pcall(readfile, SETTINGS_FILE)
        if ok and type(content) == "string" then
            local valid, decoded = pcall(function()
                return HttpService:JSONDecode(content)
            end)
            if valid then
                local saved, position, tab, potion = cleanSettings(decoded)
                if saved then return saved, "file", position, tab, potion end
            end
        end
    end
    local env = settingsEnv()
    local saved, position, tab, potion
    if type(env) == "table" then
        saved, position, tab, potion = cleanSettings(env[SETTINGS_KEY])
    end
    return saved, saved and "session" or nil, position, tab, potion
end
local settingsPosition
local settingsTab = "Fight"
local function writeSettings(current)
    local saved = {placeId = game.PlaceId, flags = {}, activeTab = settingsTab}
    saved.potion = {when = potionConfig.when, available = {}, selected = {}}
    for _, name in ipairs(potionConfig.available) do table.insert(saved.potion.available, name) end
    for _, id in ipairs({"luck", "haste", "gild"}) do
        saved.potion.selected[id] = potionConfig.selected[id] == true
    end
    if settingsPosition then saved.position = settingsPosition end
    for _, key in ipairs(settingKeys) do
        saved.flags[key] = current[key] == true
    end
    local env = settingsEnv()
    if type(env) == "table" then env[SETTINGS_KEY] = saved end
    if type(writefile) ~= "function" then return "session" end
    local ok = pcall(function()
        writefile(SETTINGS_FILE, HttpService:JSONEncode(saved))
    end)
    return ok and "file" or "session"
end

local OLD = pg:FindFirstChild("RollStickman_Combined_V1_1")
if OLD then
    local stop
    for _, obj in ipairs(OLD:GetDescendants()) do
        if obj:IsA("TextButton") and obj.Text:upper():find("STOP ALL", 1, true) then
            stop = obj
            break
        end
    end
    if not stop or type(firesignal) ~= "function"
        or not pcall(firesignal, stop.Activated, nil, 1) then
        warn("[RAS] Press STOP ALL on V1.1, then run V1.2 again")
        return
    end
    task.wait(0.3)
    for _, obj in ipairs(OLD:GetDescendants()) do
        if obj:IsA("TextButton") and
            (obj.Text:match("^LEVEL UP: ON")
            or obj.Text:match("^RAID: ON")
            or obj.Text:match("^DUNGEON: ON")
            or obj.Text:match("^EXPEDITIONS: ON")
            or obj.Text:match("^AURORA BOOST: ON")) then
            warn("[RAS] V1.1 remains ON; press STOP ALL before V1.2")
            return
        end
    end
    OLD:Destroy()
end
local oldRecovery = pg:FindFirstChild("RollStickman_DungeonModalRecovery_V1")
if oldRecovery then oldRecovery:Destroy() end
local NAME = "RollStickman_Combined_V1_2"
local previous = pg:FindFirstChild(NAME)
local previousFlags = {}
if previous then
    local previousPanel = previous:FindFirstChild("Panel")
    local names = {level = "LevelToggle", raid = "RaidToggle",
        dungeon = "DungeonToggle", expedition = "ExpeditionToggle",
        moon = "MoonToggle", antiAfk = "AntiAfkToggle"}
    for key, name in pairs(names) do
        local obj = previousPanel and previousPanel:FindFirstChild(name)
        if obj and obj:IsA("TextButton") then
            previousFlags[key] = obj.Text:upper():match(":%s*ON$") ~= nil
        end
    end
end
if previous then previous:Destroy() end

local gui = Instance.new("ScreenGui")
gui.Name = NAME
gui.ResetOnSpawn = false
gui.DisplayOrder = 240
local PANEL_HEIGHT = 600
local theme = {
    base = Color3.fromRGB(18, 22, 32), card = Color3.fromRGB(28, 34, 48),
    muted = Color3.fromRGB(154, 169, 194), text = Color3.fromRGB(234, 241, 252),
    accent = Color3.fromRGB(46, 188, 163), off = Color3.fromRGB(43, 51, 70),
}
local panel = Instance.new("Frame")
panel.Name = "Panel"
panel.Size = UDim2.fromOffset(360, PANEL_HEIGHT)
panel.Position = UDim2.fromOffset(12, 160)
panel.BackgroundColor3 = theme.base
panel.BorderSizePixel = 0
panel.Active = true
panel.Parent = gui
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 10)
corner.Parent = panel
local outline = Instance.new("UIStroke")
outline.Color = Color3.fromRGB(61, 76, 101)
outline.Thickness = 1
outline.Parent = panel
local header = Instance.new("Frame")
header.Name = "Header"
header.Size = UDim2.new(1, 0, 0, 42)
header.BackgroundColor3 = theme.card
header.BorderSizePixel = 0
header.Parent = panel
local function label(name, value, y, height)
    local obj = Instance.new("TextLabel")
    obj.Name = name
    obj.Position = UDim2.fromOffset(12, y)
    obj.Size = UDim2.new(1, -24, 0, height)
    obj.BackgroundTransparency = 1
    obj.TextColor3 = theme.text
    obj.TextXAlignment = Enum.TextXAlignment.Left
    obj.TextSize = 13
    obj.Font = Enum.Font.Gotham
    obj.Text = value
    obj.Parent = panel
    return obj
end
local function button(name, value, x, y, w, h)
    local obj = Instance.new("TextButton")
    obj.Name = name
    obj.Position = UDim2.fromOffset(x, y)
    obj.Size = UDim2.fromOffset(w, h)
    obj.Text = value
    obj.TextSize = 12
    obj.Font = Enum.Font.GothamMedium
    obj.TextColor3 = theme.text
    obj.BorderSizePixel = 0
    obj.BackgroundColor3 = theme.off
    local round = Instance.new("UICorner")
    round.CornerRadius = UDim.new(0, 7)
    round.Parent = obj
    obj.Parent = panel
    return obj
end
local title = label("Title", "ROLL A STICKMAN  |  R13  ·  ALT", 8, 27)
title.Size = UDim2.fromOffset(258, 27)
title.TextSize = 12
title.Active = true
local minimizeUI = button("Minimize", "-", 278, 7, 32, 28)
local closeUI = button("Close", "X", 316, 7, 34, 28)
local tabPages = {Team = {}, Fight = {}, Potion = {}, Status = {}}
local tabButtons = {}
local activeTab = "Fight"
local function pageItem(tab, obj)
    table.insert(tabPages[tab], obj)
    return obj
end
local function pageLabel(tab, name, value, y, height)
    local obj = pageItem(tab, label(name, value, y, height))
    obj.TextWrapped = true
    obj.TextColor3 = theme.muted
    return obj
end
for i, tab in ipairs({"Team", "Fight", "Potion", "Status"}) do
    tabButtons[tab] = button("Tab" .. tab, tab:upper(), 10 + (i - 1) * 87, 53, 79, 30)
end
local toggles = {
    level = pageItem("Team", button("LevelToggle", "LEVEL UP: OFF", 12, 116, 336, 36)),
    raid = pageItem("Fight", button("RaidToggle", "RAID: OFF", 12, 116, 336, 36)),
    dungeon = pageItem("Fight", button("DungeonToggle", "DUNGEON: OFF", 12, 158, 336, 36)),
    expedition = pageItem("Fight", button("ExpeditionToggle", "EXPEDITIONS: OFF", 12, 200, 336, 36)),
    moon = pageItem("Potion", button("MoonToggle", "USE POTION: OFF", 12, 116, 336, 30)),
    antiAfk = pageItem("Status", button("AntiAfkToggle", "ANTI AFK: ON", 12, 116, 336, 36)),
}
pageLabel("Team", "TeamHeading", "TEAM  /  UPGRADES", 90, 20)
pageLabel("Team", "TeamHint", "LEVEL UP uses LEVEL UP ALL when that game button is visible. Open the team upgrade page to use it.", 165, 70)
pageLabel("Fight", "FightHeading", "FIGHT  /  AUTOMATION", 90, 20)
pageLabel("Fight", "DungeonMode", "DUNGEON · ALL TYPES\nNo tickets: check again after 2 hours.", 245, 42)
local dungeonSchedule = pageLabel("Fight", "DungeonSchedule", "Dungeon check: ready", 300, 38)
pageLabel("Potion", "PotionHeading", "POTION  /  CONDITIONS", 90, 20)
local potionUI = {checks = {}, scanRequested = false, entries = {}}
potionUI.dropdown = pageItem("Potion", button("PotionWhen", "Use Potion When: Aurora   v", 12, 152, 276, 30))
potionUI.sync = pageItem("Potion", button("PotionSync", "SYNC", 294, 152, 54, 30))
potionUI.option = Instance.new("ScrollingFrame")
potionUI.option.Name = "PotionWhenList"
potionUI.option.Position = UDim2.fromOffset(12, 184)
potionUI.option.Size = UDim2.fromOffset(336, 158)
potionUI.option.ScrollBarThickness = 5
potionUI.option.CanvasSize = UDim2.new()
potionUI.option.BorderSizePixel = 0
potionUI.option.Parent = panel
pageItem("Potion", potionUI.option)
potionUI.option.ZIndex = 30
potionUI.option.BackgroundColor3 = Color3.fromRGB(35, 100, 90)
potionUI.option.Visible = false
local potionLabels = {}
for i, id in ipairs({"luck", "haste", "gild"}) do
    local y = 190 + (i - 1) * 46
    potionUI.checks[id] = pageItem("Potion", button("PotionCheck" .. id,
        "[x]  " .. potionNames[id], 12, y, 336, 24))
    potionUI.checks[id].TextXAlignment = Enum.TextXAlignment.Left
    potionLabels[id] = pageLabel("Potion", "PotionStock" .. id,
        "Stock: not observed", y + 25, 18)
    potionLabels[id].TextSize = 10
end
pageLabel("Potion", "PotionHint", "Checked potions only. Owned cards open afterwards.", 328, 20).TextSize = 10
pageLabel("Status", "StatusHeading", "STATUS  /  LIVE GAME VALUES", 90, 20)
local statusScroll = Instance.new("ScrollingFrame")
statusScroll.Name = "StatusPage"
statusScroll.Position = UDim2.fromOffset(12, 160)
statusScroll.Size = UDim2.fromOffset(336, 186)
statusScroll.BackgroundTransparency = 1
statusScroll.BorderSizePixel = 0
statusScroll.ScrollBarThickness = 4
statusScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
statusScroll.CanvasSize = UDim2.new()
statusScroll.Parent = panel
pageItem("Status", statusScroll)
local statusLayout = Instance.new("UIListLayout")
statusLayout.Padding = UDim.new(0, 6)
statusLayout.SortOrder = Enum.SortOrder.LayoutOrder
statusLayout.Parent = statusScroll
local statusRows = {}
local function statusRow(key, caption)
    local row = Instance.new("TextLabel")
    row.Name = key
    row.LayoutOrder = #statusRows + 1
    row.Size = UDim2.new(1, -8, 0, 56)
    row.BackgroundColor3 = theme.card
    row.BorderSizePixel = 0
    row.Font = Enum.Font.Gotham
    row.TextSize = 12
    row.TextColor3 = theme.text
    row.TextWrapped = true
    row.TextXAlignment = Enum.TextXAlignment.Left
    row.Text = caption .. "\nNot observed"
    row.Parent = statusScroll
    local padding = Instance.new("UIPadding")
    padding.PaddingLeft = UDim.new(0, 10)
    padding.PaddingRight = UDim.new(0, 8)
    padding.Parent = row
    local round = Instance.new("UICorner")
    round.CornerRadius = UDim.new(0, 7)
    round.Parent = row
    statusRows[key] = {obj = row, caption = caption}
    table.insert(statusRows, key)
end
for _, spec in ipairs({
    {"luck", "LUCK · HUD"}, {"battleLuck", "LUCK · BATTLE"},
    {"aura", "AURA · LAST CONFIRMED"}, {"moonTimer", "SKY COUNTDOWN"},
    {"power", "TEAM POWER"}, {"battle", "BATTLE / STAGE"},
    {"rolls", "TOTAL ROLLS"}, {"autoRoll", "AUTO ROLL"},
    {"dungeon", "DUNGEON / TICKETS"}, {"nextDungeon", "NEXT DUNGEON CHECK"},
    {"expedition", "EXPEDITIONS READY"}, {"cards", "REWARD CARDS"},
    {"luckPotion", "LUCK POTION"}, {"hastePotion", "HASTE POTION"},
    {"gildPotion", "GILDED POTION"}, {"runtime", "SESSION / SCHEDULER"},
    {"switches", "ENABLED SYSTEMS"}, {"storage", "SETTINGS STORAGE"},
}) do statusRow(spec[1], spec[2]) end
local statusHeader = label("StatusHeader", "ACTIVITY", 360, 18)
statusHeader.TextColor3 = theme.accent
local status = label("Status", "Starting...", 381, 40)
status.TextSize = 12
status.TextWrapped = true
local stopButton = button("StopAll", "STOP ALL", 12, 428, 160, 32)
stopButton.BackgroundColor3 = Color3.fromRGB(139, 56, 72)
local copyButton = button("CopyLog", "COPY LOG", 180, 428, 168, 32)
local logHeader = label("LogHeader", "ACTIVITY LOG", 470, 17)
logHeader.TextColor3 = theme.muted
local scroll = Instance.new("ScrollingFrame")
scroll.Name = "ActivityLog"
scroll.Position = UDim2.fromOffset(12, 494)
scroll.Size = UDim2.new(1, -24, 0, 94)
scroll.BackgroundColor3 = Color3.fromRGB(13, 16, 24)
scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 4
scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
scroll.CanvasSize = UDim2.new()
scroll.Parent = panel
local logBox = Instance.new("TextBox")
logBox.Size = UDim2.new(1, -10, 0, 0)
logBox.AutomaticSize = Enum.AutomaticSize.Y
logBox.BackgroundTransparency = 1
logBox.TextColor3 = theme.muted
logBox.Font = Enum.Font.Code
logBox.TextSize = 11
logBox.TextWrapped = true
logBox.MultiLine = true
logBox.ClearTextOnFocus = false
logBox.TextXAlignment = Enum.TextXAlignment.Left
logBox.TextYAlignment = Enum.TextYAlignment.Top
logBox.Parent = scroll
gui.Parent = pg
local alive = true
local minimized = false
local savedFlags, settingsSource, savedPosition, savedTab, savedPotion = readSettings()
if savedPotion then potionConfig = savedPotion end
if not savedFlags and next(previousFlags) then
    savedFlags, settingsSource = previousFlags, "previous UI"
end
local flags = {}
for _, key in ipairs(settingKeys) do
    flags[key] = savedFlags and savedFlags[key] == true or false
end
if not savedFlags or savedFlags.antiAfk == nil then flags.antiAfk = true end
local function clampPosition(x, y)
    local camera = workspace.CurrentCamera
    local viewport = camera and camera.ViewportSize or Vector2.new(1920, 1080)
    return math.clamp(x, 0, math.max(0, viewport.X - 360)),
        math.clamp(y, 0, math.max(0, viewport.Y - panel.Size.Y.Offset))
end
if savedPosition then
    local ok, x, y = pcall(clampPosition, savedPosition.x, savedPosition.y)
    if ok then panel.Position = UDim2.fromOffset(x, y) end
end
settingsPosition = {x = panel.Position.X.Offset, y = panel.Position.Y.Offset}
local versions = {level = 0, raid = 0, dungeon = 0, expedition = 0, moon = 0, antiAfk = 0}
local titles = {level = "LEVEL UP", raid = "RAID", dungeon = "DUNGEON",
    expedition = "EXPEDITIONS", moon = "USE POTION", antiAfk = "ANTI AFK"}
local function paintToggle(key)
    gui:SetAttribute("Flag_" .. key, flags[key] == true)
    toggles[key].BackgroundColor3 = flags[key]
        and Color3.fromRGB(31, 114, 102) or theme.off
    toggles[key].TextColor3 = Color3.fromRGB(255, 255, 255)
end
for key, obj in pairs(toggles) do
    obj.Text = titles[key] .. (flags[key] and ": ON" or ": OFF")
    paintToggle(key)
end
local settingsStorage = writeSettings(flags)
local dragging, dragStart, panelStart = false, nil, nil
title.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        dragging, dragStart, panelStart = true, input.Position,
            Vector2.new(panel.Position.X.Offset, panel.Position.Y.Offset)
    end
end)
local dragChanged = UserInputService.InputChanged:Connect(function(input)
    if not dragging or not dragStart or not panelStart then return end
    if input.UserInputType ~= Enum.UserInputType.MouseMovement
        and input.UserInputType ~= Enum.UserInputType.Touch then return end
    local delta = input.Position - dragStart
    local x, y = clampPosition(panelStart.X + delta.X, panelStart.Y + delta.Y)
    panel.Position = UDim2.fromOffset(x, y)
end)
local dragEnded = UserInputService.InputEnded:Connect(function(input)
    if not dragging then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
        settingsPosition = {x = panel.Position.X.Offset, y = panel.Position.Y.Offset}
        settingsStorage = writeSettings(flags)
    end
end)
local busy = false
local logs = {}
local startedAt = os.clock()
local function log(message)
    local entry = string.format("[%5.1fs] %s", os.clock() - startedAt, message)
    table.insert(logs, entry)
    if #logs > 250 then table.remove(logs, 1) end
    if alive then logBox.Text = table.concat(logs, "\n") end
    print("[RAS] " .. entry)
end
local function note(value)
    if alive and status.Text ~= value then
        status.Text = value
        log(value)
    end
end
local function setTab(name)
    if not alive or minimized or not tabPages[name] then return end
    activeTab, settingsTab = name, name
    for tab, objects in pairs(tabPages) do
        for _, obj in ipairs(objects) do obj.Visible = tab == name end
        tabButtons[tab].BackgroundColor3 = tab == name and theme.accent or theme.off
        tabButtons[tab].TextColor3 = tab == name and theme.base or theme.text
    end
    potionUI.option.Visible = false
    settingsStorage = writeSettings(flags)
    gui:SetAttribute("ActiveTab", name)
end
for name, tabButton in pairs(tabButtons) do
    tabButton.Activated:Connect(function() setTab(name) end)
end
setTab(savedTab or "Fight")
-- Only fold this panel. The scheduler and enabled switches keep running.
local foldedVisibility = {}
local function toggleMinimized()
    if not alive then return end
    minimized = not minimized
    for _, obj in ipairs(panel:GetChildren()) do
        if obj:IsA("GuiObject") and obj ~= header and obj ~= title
            and obj ~= minimizeUI and obj ~= closeUI then
            if minimized then
                foldedVisibility[obj] = obj.Visible
                obj.Visible = false
            else
                obj.Visible = foldedVisibility[obj] ~= false
            end
        end
    end
    panel.Size = UDim2.fromOffset(360, minimized and 42 or PANEL_HEIGHT)
    minimizeUI.Text = minimized and "+" or "-"
    gui:SetAttribute("Minimized", minimized)
    local x, y = clampPosition(panel.Position.X.Offset, panel.Position.Y.Offset)
    panel.Position = UDim2.fromOffset(x, y)
    settingsPosition = {x = x, y = y}
    settingsStorage = writeSettings(flags)
    log(minimized and "UI minimized; automation continues" or "UI expanded")
end
minimizeUI.Activated:Connect(toggleMinimized)
local minimizeHotkey = UserInputService.InputBegan:Connect(function(input, processed)
    if processed or UserInputService:GetFocusedTextBox() then return end
    if input.KeyCode == Enum.KeyCode.LeftAlt
        or input.KeyCode == Enum.KeyCode.RightAlt then
        toggleMinimized()
    end
end)
local function get(parts)
    local obj = pg:FindFirstChild("RollAStickman")
    for _, name in ipairs(parts) do
        obj = obj and obj:FindFirstChild(name)
    end
    return obj
end
local function child(obj, names)
    for _, name in ipairs(names) do
        obj = obj and obj:FindFirstChild(name)
    end
    return obj
end
local function visible(obj)
    if not obj then return false end
    local current = obj
    while current and current ~= pg do
        if current:IsA("GuiObject") and not current.Visible then return false end
        if current:IsA("ScreenGui") and not current.Enabled then return false end
        current = current.Parent
    end
    return current == pg
end
local function textOf(obj)
    if not obj or not (obj:IsA("TextLabel") or obj:IsA("TextButton")) then
        return ""
    end
    return obj.Text:gsub("<[^>]*>", ""):gsub("%s+", " ")
        :match("^%s*(.-)%s*$"):upper()
end
local function buttonText(obj)
    local face = obj and obj:FindFirstChild("Face")
    local value = child(face, {"Label"}) or child(obj, {"Label"}) or obj
    return textOf(value)
end
local function ready(obj)
    return obj and obj:IsA("GuiButton") and obj.Active and visible(obj)
        and obj.AbsoluteSize.X > 0 and obj.AbsoluteSize.Y > 0
end
local lastFire = {}
local function fire(key, obj, required, cooldown)
    if not ready(obj) or type(firesignal) ~= "function" then return false end
    if required and buttonText(obj) ~= required then return false end
    local now = os.clock()
    if now - (lastFire[key] or -100) < (cooldown or 2) then return false end
    local ok, err = pcall(firesignal, obj.Activated, nil, 1)
    if not ok then note("Button error: " .. tostring(err)); return false end
    lastFire[key] = now
    log("CLICK " .. key .. " [" .. buttonText(obj) .. "]")
    return true
end
local function valid(key, version)
    return alive and flags[key] and versions[key] == version
end
local function run(key, operation)
    if busy then return end
    busy = true
    local version = versions[key]
    task.spawn(function()
        local ok, err = pcall(operation, version)
        busy = false
        if not ok then
            flags[key] = false
            versions[key] = versions[key] + 1
            toggles[key].Text = titles[key] .. ": OFF"
            paintToggle(key)
            settingsStorage = writeSettings(flags)
            note(key .. " error: " .. tostring(err))
        end
    end)
end
for key, obj in pairs(toggles) do
    obj.Activated:Connect(function()
        flags[key] = not flags[key]
        versions[key] = versions[key] + 1
        local title = titles[key]
        obj.Text = title .. (flags[key] and ": ON" or ": OFF")
        paintToggle(key)
        settingsStorage = writeSettings(flags)
        note(title .. (flags[key] and " enabled" or " disabled"))
    end)
end
stopButton.Activated:Connect(function()
    for key, obj in pairs(toggles) do
        flags[key] = false
        versions[key] = versions[key] + 1
        local title = titles[key]
        obj.Text = title .. ": OFF"
        paintToggle(key)
    end
    settingsStorage = writeSettings(flags)
    note("All switches OFF")
end)
copyButton.Activated:Connect(function()
    local value = table.concat(logs, "\n")
    if type(setclipboard) == "function" and pcall(setclipboard, value) then
        copyButton.Text = "COPIED"
    else
        logBox:CaptureFocus()
        logBox.CursorPosition = #logBox.Text + 1
        logBox.SelectionStart = 1
        copyButton.Text = "PRESS CTRL+C"
    end
end)
closeUI.Activated:Connect(function() gui:Destroy() end)
local lastIdleAction = -math.huge
local idleConnection = player.Idled:Connect(function(idleSeconds)
    if not alive or not flags.antiAfk then return end
    local now = os.clock()
    if now - lastIdleAction < 60 then return end
    lastIdleAction = now
    local ok, err = pcall(function()
        local virtualUser = game:GetService("VirtualUser")
        virtualUser:CaptureController()
        local camera = workspace.CurrentCamera
        if camera then
            virtualUser:ClickButton2(Vector2.new(0, 0), camera.CFrame)
        else
            virtualUser:ClickButton2(Vector2.new(0, 0))
        end
    end)
    if ok then
        log("ANTI AFK input sent | idle=" .. tostring(idleSeconds) .. "s")
    else
        flags.antiAfk = false
        versions.antiAfk = versions.antiAfk + 1
        toggles.antiAfk.Text = "ANTI AFK: OFF"
        paintToggle("antiAfk")
        settingsStorage = writeSettings(flags)
        note("ANTI AFK unavailable in executor: " .. tostring(err))
    end
end)
gui.Destroying:Connect(function()
    alive = false
    dragChanged:Disconnect()
    dragEnded:Disconnect()
    minimizeHotkey:Disconnect()
    idleConnection:Disconnect()
    for key in pairs(flags) do flags[key] = false end
end)

local function page() return get({"Frame", "Page", "Column", "Screen"}) end
local function battleTitle()
    local obj = get({"Frame", "Battle", "Stage", "Ribbon", "Title"})
    return visible(obj) and textOf(obj) or ""
end
local function waveBattle()
    return battleTitle():match("^WAVE %d+") ~= nil
end
local function inDungeon()
    local nav = get({"Frame", "Nav", "Row", "dungeon", "Label"})
    local navText = visible(nav) and textOf(nav) or ""
    local battle = battleTitle()
    return navText:match("ROOM %d+/%d+") ~= nil or
        (battle:find("ROOM %d+/%d+") ~= nil and
        (battle:find("DEEP HALLS", 1, true) or
        battle:find("KEY CRYPT", 1, true)) ~= nil)
end
local function modalPanel()
    return get({"Frame", "Modal", "Window", "Panel"})
end
local function modalTitle()
    local panelObj = modalPanel()
    local obj = child(panelObj, {"Header", "Title"})
    return visible(obj) and textOf(obj) or ""
end
local function modalOpen() return visible(modalPanel()) end
-- Status reads game UI only. Hidden values are explicitly shown as last seen.
local statusCache = {}
local function statusPlain(obj)
    if not obj or not (obj:IsA("TextLabel") or obj:IsA("TextButton")) then return "" end
    return obj.Text:gsub("<[^>]*>", ""):gsub("%s+", " "):match("^%s*(.-)%s*$")
end
local function rememberStatus(key, value)
    if value and value ~= "" then
        statusCache[key] = {value = value, at = os.clock()}
    end
end
local function cachedStatus(key)
    local entry = statusCache[key]
    if not entry then return "Not observed" end
    return entry.value .. " | last seen " .. math.floor(os.clock() - entry.at) .. "s ago"
end
local function sampleStatus(key, obj)
    local value = visible(obj) and statusPlain(obj) or ""
    if value ~= "" then rememberStatus(key, value); return value end
    return cachedStatus(key)
end
local function dungeonTypeOnPage()
    local title = child(page(), {"Hero", "Plate", "Title"})
    if not visible(title) then return nil end
    local value = textOf(title)
    if value:find("DEEP HALLS", 1, true) then return "halls" end
    if value:find("KEY CRYPT", 1, true) then return "crypt" end
end
local function dungeonName(kind)
    return kind == "halls" and "DEEP HALLS" or "KEY CRYPT"
end
local function otherDungeon(kind)
    return kind == "halls" and "crypt" or "halls"
end
local selectedDungeon = "halls"
local dungeonStarted, dungeonSeen = false, false
local dungeonSentAt, dungeonReturnedAt = 0, nil
local nextDungeon = 0
local DUNGEON_RECHECK_SECONDS = 2 * 60 * 60
local noTicketsUntil = {halls = 0, crypt = 0}
local sharedTicketsEmpty = false
local modalEligibleAt, modalAttempts, modalLastTry = nil, 0, 0

local function observeDungeon(now)
    if not dungeonStarted then return end
    if inDungeon() then
        dungeonSeen = true
        dungeonReturnedAt = nil
        return
    end
    if dungeonSeen and waveBattle() then
        dungeonReturnedAt = dungeonReturnedAt or now
        if now - dungeonReturnedAt >= 5 then
            dungeonStarted, dungeonSeen = false, false
            dungeonReturnedAt = nil
            selectedDungeon = otherDungeon(selectedDungeon)
            nextDungeon = now + 10
            note("Dungeon finished. Next: " .. dungeonName(selectedDungeon))
        end
    elseif not dungeonSeen and now - dungeonSentAt > 20 then
        dungeonStarted = false
        nextDungeon = now + 10
        note("Dungeon start unconfirmed; retrying")
    elseif dungeonSeen and now - dungeonSentAt > 900 then
        dungeonStarted, dungeonSeen = false, false
        nextDungeon = now + 30
        note("Dungeon return timeout; waiting")
    end
end

-- The V1.1 result modal blocked the next dungeon forever. Close only dungeon
-- modals while Endless is visible and Dungeon automation is ON.
local function recoverDungeonModal(now)
    local title = modalTitle()
    local eligible = flags.dungeon and waveBattle() and not dungeonStarted
        and (title == "THE DEEP HALLS" or title == "THE KEY CRYPT")
    if not eligible then
        modalEligibleAt, modalAttempts = nil, 0
        return false
    end
    modalEligibleAt = modalEligibleAt or now
    if now - modalEligibleAt < 12 then return true end
    if modalAttempts >= 3 then
        note("Dungeon result X failed; close it manually")
        return true
    end
    if now - modalLastTry < 20 then return true end
    local close = child(modalPanel(), {"Close"})
    if fire("dungeon.result.close", close, "X", 10) then
        modalAttempts = modalAttempts + 1
        modalLastTry = now
        note("Closing " .. title .. " result")
    end
    return true
end

local function returnToBattle()
    local endless = get({"Frame", "Nav", "Row", "endless"})
    if fire("dungeon.back", endless, nil, 3) then
        log("Returned to battle while dungeon tickets are empty")
        return true
    end
    note("Cannot return to battle; inspect ENDLESS tab")
    return false
end

local function runDungeon(version)
    if not valid("dungeon", version) then return end
    if not dungeonTypeOnPage() then
        local tab = get({"Frame", "Nav", "Row", "dungeon"})
        if not fire("dungeon.tab", tab, nil, 3) then
            nextDungeon = os.clock() + 10
            return
        end
        task.wait(1)
    end
    if not valid("dungeon", version) then return end
    local screen = page()
    if not screen or not visible(screen) then
        nextDungeon = os.clock() + 10
        note("Dungeon page unavailable; retrying")
        return
    end
    if sharedTicketsEmpty then
        -- Both types previously showed 0/5. Check the current ticket counter
        -- without switching selectors; this leaves the battle page free for RAID.
        local ticket = child(screen, {"Hero", "Tickets", "R1", "Amount"})
        local value = visible(ticket) and textOf(ticket) or ""
        local count = tonumber(value:match("^(%d+)%s*/"))
        if count == nil or count == 0 then
            nextDungeon = os.clock() + (count == 0 and DUNGEON_RECHECK_SECONDS or 20)
            if returnToBattle() then
                note(count == 0 and "Dungeon tickets 0/5; checking again in 2h"
                    or "Dungeon tickets unreadable; checking again soon")
            end
            return
        end
        sharedTicketsEmpty = false
        noTicketsUntil.halls, noTicketsUntil.crypt = 0, 0
        log("Dungeon tickets replenished: " .. value)
    end
    local current = dungeonTypeOnPage()
    if current ~= selectedDungeon then
        local leave = child(screen, {"Leave"})
        if ready(leave) and buttonText(leave) == "LEAVE PARTY" then
            if fire("dungeon.leave", leave, "LEAVE PARTY", 3) then task.wait(1) end
        end
        if not valid("dungeon", version) then return end
        local pick = child(screen, {"Pick", selectedDungeon})
        if ready(pick) then
            fire("dungeon.pick." .. selectedDungeon, pick, nil, 3)
            task.wait(1)
        end
        current = dungeonTypeOnPage()
        if current ~= selectedDungeon then
            nextDungeon = os.clock() + 10
            note("Dungeon selector unavailable; waiting for " .. dungeonName(selectedDungeon))
            return
        end
    end
    local ticket = child(screen, {"Hero", "Tickets", "R1", "Amount"})
    local ticketValue = visible(ticket) and textOf(ticket) or ""
    local available = tonumber(ticketValue:match("^(%d+)%s*/"))
    if available == nil then
        nextDungeon = os.clock() + 10
        note(dungeonName(selectedDungeon) .. " tickets not readable; retrying")
        return
    end
    if available == 0 then
        local now = os.clock()
        noTicketsUntil[selectedDungeon] = now + 60
        local other = otherDungeon(selectedDungeon)
        if noTicketsUntil[other] > now then
            sharedTicketsEmpty = true
            selectedDungeon = other
            nextDungeon = now + DUNGEON_RECHECK_SECONDS
            if returnToBattle() then
                note("Both dungeon types 0/5; checking again in 2h")
            end
        else
            local empty = dungeonName(selectedDungeon)
            selectedDungeon = other
            nextDungeon = now + 4
            note(empty .. " has no tickets. Trying " .. dungeonName(other))
        end
        return
    end
    noTicketsUntil[selectedDungeon] = 0
    local start = child(screen, {"Party", "Action"})
    if not (ready(start) and buttonText(start) == "START SOLO") then
        local open = child(screen, {"Open"})
        if not fire("dungeon.open", open, "OPEN A PARTY", 4) then
            nextDungeon = os.clock() + 10
            note("Dungeon party unavailable; retrying")
            return
        end
        task.wait(1)
    end
    if not valid("dungeon", version) then return end
    start = child(page(), {"Party", "Action"})
    if fire("dungeon.start", start, "START SOLO", 6) then
        dungeonStarted, dungeonSeen = true, false
        dungeonSentAt, dungeonReturnedAt = os.clock(), nil
        nextDungeon = os.clock() + 30
        note("Started " .. dungeonName(selectedDungeon))
    else
        nextDungeon = os.clock() + 10
        note("START SOLO unavailable; retrying")
    end
end

local nextLevel, nextRaid, nextExpedition = 0, 0, 0
local raidJoinLocked = false
local function levelTick()
    local obj = get({"Frame", "Page", "Column", "Screen", "Screen", "LevelAll"})
    if fire("level.all", obj, "LEVEL UP ALL", 5) then
        nextLevel = os.clock() + 5
        note("LEVEL UP ALL pressed")
    else
        nextLevel = os.clock() + 5
    end
end
local function raidTick()
    local join = get({"Frame", "News", "raid", "Action"})
    if not (ready(join) and buttonText(join) == "JOIN") then
        raidJoinLocked = false
        return
    end
    if not raidJoinLocked and fire("raid.join", join, "JOIN", 8) then
        raidJoinLocked = true
        nextRaid = os.clock() + 8
        note("RAID JOIN pressed")
    end
end

local expeditionIds = {"Epatrol", "Esupply", "Eruins", "Ewastes", "Estarfall"}
local sendLocked = {}
local function expRow(id)
    return child(modalPanel(), {"Content", "Inner", id})
end
local function expeditionBadgeCount()
    local badge = get({"Frame", "Nav", "Row", "expeditions", "Badge"})
    if not visible(badge) then return 0 end
    local value = child(badge, {"Text"}) or badge
    return tonumber(textOf(value)) or 0
end
local function expReady(obj, expected)
    return ready(obj) and buttonText(obj) == expected
end
local function waitUntil(version, seconds, predicate)
    local deadline = os.clock() + seconds
    repeat
        if not valid("expedition", version) then return false end
        if predicate() then return true end
        task.wait(0.5)
    until os.clock() >= deadline
    return predicate()
end
local function expeditionTick(version)
    if not valid("expedition", version) then return end
    if modalTitle() ~= "EXPEDITIONS" then
        if modalOpen() then return end
        if expeditionBadgeCount() <= 0 then
            nextExpedition = os.clock() + 8
            return
        end
        if not fire("exp.tab", get({"Frame", "Nav", "Row", "expeditions"}), nil, 4) then
            nextExpedition = os.clock() + 8
            return
        end
        task.wait(1)
    end
    if modalTitle() ~= "EXPEDITIONS" then
        nextExpedition = os.clock() + 8
        return
    end
    for _, id in ipairs(expeditionIds) do
        if not valid("expedition", version) then return end
        local row = expRow(id)
        local claim = child(row, {"Claim"})
        local again = child(row, {"Again"})
        local recall = child(row, {"Recall"})
        local clock = child(row, {"Clock"})
        if expReady(recall, "RECALL") and visible(clock) then
            sendLocked[id] = nil
        elseif expReady(claim, "CLAIM") then
            sendLocked[id] = nil
            if fire("exp.claim." .. id, claim, "CLAIM", 3) then
                note(id .. " claimed")
                waitUntil(version, 6, function()
                    return expReady(child(expRow(id), {"Again"}), "SEND AGAIN")
                end)
            end
        end
        again = child(expRow(id), {"Again"})
        if not sendLocked[id] and expReady(again, "SEND AGAIN") then
            -- Lock before dispatch: SEND AGAIN can remain visible for ~3s.
            sendLocked[id] = true
            if fire("exp.again." .. id, again, "SEND AGAIN", 6) then
                note(id .. " SEND AGAIN")
                local confirmed = waitUntil(version, 10, function()
                    local r = expRow(id)
                    local c = child(r, {"Clock"})
                    return expReady(child(r, {"Recall"}), "RECALL")
                        and visible(c) and textOf(c) ~= ""
                end)
                if confirmed then
                    local clock = child(expRow(id), {"Clock"})
                    log(id .. " dispatch confirmed: " .. textOf(clock))
                elseif valid("expedition", version) then
                    note(id .. " dispatch unconfirmed; locked against duplicate")
                end
            else
                sendLocked[id] = nil
            end
        end
    end
    if valid("expedition", version) then
        fire("exp.close", child(modalPanel(), {"Close"}), "X", 3)
    end
    nextExpedition = os.clock() + 12
end

-- Aurora is read from MOONS > Now.Title. The summoning shop always lists
-- AURORA MOON, even when the active sky is NORMAL MOON; never use that list.
local nextMoon = 0
local moonWasAurora = false
local moonUsed = {}
local moonCardsDone = false
local function closeModal(key)
    return fire(key, child(modalPanel(), {"Close"}), "X", 1)
end
local function moreMenu()
    local menu = get({"Frame", "Hud", "MoreMenu", "Rows"})
    if visible(menu) then return menu end
    if fire("moon.more", get({"Frame", "Hud", "UtilMore"}), nil, 1) then
        task.wait(0.4)
    end
    return visible(menu) and menu or nil
end
local function openPotions()
    if modalTitle() == "POTIONS" then return true end
    if modalOpen() then return false end
    local menu = moreMenu()
    if not menu then return false end
    if not fire("moon.potions", child(menu, {"potions"}), "POTIONS", 2) then
        return false
    end
    task.wait(0.7)
    return modalTitle() == "POTIONS"
end
local function numeric(value)
    if not value then return nil end
    local clean = value:gsub(",", "")
    return tonumber(clean)
end
local function potionStatus(id)
    local row = child(modalPanel(), {"Content", "Inner", id})
    local obj = child(row, {"Status"})
    local value = visible(obj) and textOf(obj) or ""
    if value ~= "" then rememberStatus(id .. "Potion", value) end
    return value
end
local function usePotion(id)
    if not potionConfig.selected[id] then return true end
    if moonUsed[id] then return true end
    if modalTitle() ~= "POTIONS" then return false end
    local statusBefore = potionStatus(id)
    -- Status may be "452 in stash" or "15m 58s left · 451 in stash".
    local count = numeric(statusBefore:match("([%d,]+)%s+IN STASH"))
    if statusBefore:find(" LEFT", 1, true) and count then
        log(potionNames[id] .. " already active: " .. statusBefore)
        moonUsed[id] = true
        return true
    end
    if count == 0 then
        log(potionNames[id] .. " empty; skipped")
        moonUsed[id] = true
        return true
    end
    if not count then
        log(potionNames[id] .. " stock unreadable; waiting")
        return false
    end
    local drink = child(modalPanel(), {"Content", "Inner", id, "Drink"})
    if not fire("moon.drink." .. id, drink, "DRINK", 2) then return false end
    -- Mark before observing; a delayed UI update must never spend twice.
    moonUsed[id] = true
    local deadline = os.clock() + 4
    repeat
        task.wait(0.4)
    until potionStatus(id) ~= statusBefore or os.clock() >= deadline
    log(potionNames[id] .. " stock: " .. statusBefore .. " -> "
        .. potionStatus(id))
    return true
end
local function openCardPacks()
    if modalTitle() == "CARD PACKS" then return true end
    if modalOpen() then return false end
    local menu = moreMenu()
    local entry
    if menu then
        for _, row in ipairs(menu:GetChildren()) do
            if row:IsA("GuiButton") then
                local value = buttonText(row)
                if value == "CARD PACKS" or value == "CARDS" then
                    entry = row
                    break
                end
            end
        end
    end
    if entry then
        fire("moon.cards.menu", entry, buttonText(entry), 2)
    else
        -- The battle dock has an Open shortcut. Verify the resulting title.
        local instant = get({"Frame", "Battle", "Dock", "Instant"})
        if not fire("moon.cards.open", instant, "OPEN", 2) then return false end
    end
    task.wait(0.7)
    if modalTitle() == "CARD PACKS" then return true end
    log("Card Packs entry unconfirmed: " .. modalTitle())
    if modalOpen() then closeModal("moon.cards.wrong.close") end
    return false
end
local function cardCount()
    local obj = child(modalPanel(), {"Content", "Inner", "Loose", "Row", "Label"})
    if not visible(obj) then return nil end
    rememberStatus("cards", statusPlain(obj))
    local digits = textOf(obj):match("^REWARD CARDS%s+([%d,]+)")
    return numeric(digits)
end
local function openOwnedCards(version)
    if not openCardPacks() then
        note("Aurora: CARD PACKS entry unavailable; retrying")
        return false
    end
    local initial = cardCount()
    if initial == nil then
        note("Aurora: Reward Cards count unreadable; retrying")
        return false
    end
    local count, opened, rounds = initial, 0, 0
    local finalSmallBatch = false
    -- The observed OPEN ALL processed roughly 1.26 million cards per press.
    -- Repeat only after a measured decrease, never while a prior batch is pending.
    while count > 0 and rounds < 15 and valid("moon", version) do
        local all = child(modalPanel(), {"Content", "Inner", "Loose",
            "Row", "Open", "All"})
        local caption = buttonText(all)
        if not caption:match("^OPEN [%d,]+$") then
            log("Reward Cards OPEN unavailable: " .. caption)
            return false
        end
        if not fire("moon.cards.all", all, caption, 4) then return false end
        rounds = rounds + 1
        local before = count
        local deadline = os.clock() + 9
        repeat
            task.wait(0.5)
            count = cardCount()
        until (count and count < before) or os.clock() >= deadline
        if not count or count >= before then
            log("Reward Cards batch unconfirmed: " .. before .. " -> "
                .. tostring(count or "window closed"))
            return false
        end
        opened = opened + before - count
        log("Reward Cards batch " .. rounds .. ": " .. before .. " -> "
            .. count .. " | measured decrease=" .. opened)
        -- Press once more after the backlog shrinks below 1,000. Auto Roll
        -- may add a few new cards while the last batch is processing.
        if before <= 1000 then finalSmallBatch = true end
        if count == 0 or opened >= initial or finalSmallBatch then
            break
        end
        task.wait(3.5)
    end
    if count > 0 and opened < initial and not finalSmallBatch then
        note("Aurora: Reward Cards remain " .. count .. "; retrying")
        return false
    end
    log("Reward Cards backlog: " .. initial .. " -> " .. count
        .. " after " .. rounds .. " batch(es)")
    if not valid("moon", version) then return false end
    -- Pack buttons may be GET MORE when owned=0. Never press a purchase link.
    for _, id in ipairs({"pouch", "crate", "chest"}) do
        local attempts = 0
        while valid("moon", version) and modalTitle() == "CARD PACKS"
            and attempts < 120 and os.clock() < nextMoon + 250 do
            local row = child(modalPanel(), {"Content", "Inner", "Packs", id})
            local open = child(row, {"Open"})
            local sub = child(open, {"Face", "Sub"})
            local owned = numeric(textOf(sub):match("([%d,]+)%s+OWNED"))
            if not owned or owned <= 0 then
                log(id .. " owned: " .. tostring(owned or "unreadable"))
                break
            end
            local caption = buttonText(open)
            if caption == "GET MORE" or not caption:match("^OPEN") then
                log(id .. " held " .. owned .. "; OPEN unavailable: " .. caption)
                break
            end
            if not fire("moon.pack." .. id, open, caption, 2) then break end
            attempts = attempts + 1
            task.wait(2.2)
            local afterSub = child(child(modalPanel(), {"Content", "Inner",
                "Packs", id, "Open"}), {"Face", "Sub"})
            local after = numeric(textOf(afterSub):match("([%d,]+)%s+OWNED"))
            log(id .. " owned: " .. owned .. " -> " .. tostring(after or "unconfirmed"))
            if not after or after >= owned then break end
        end
    end
    if not valid("moon", version) then return false end
    if modalTitle() == "CARD PACKS" then closeModal("moon.cards.close") end
    moonCardsDone = true
    note("Selected potions/card opening attempted; see COPY LOG for counts")
    return true
end
local function moonTick(version)
    if not valid("moon", version) then return end
    if modalOpen() and modalTitle() ~= "MOONS" then
        nextMoon = os.clock() + 8
        return
    end
    local openedHere = false
    if modalTitle() ~= "MOONS" then
        if not fire("moon.tab", get({"Frame", "Buffs", "Moon"}), nil, 3) then
            nextMoon = os.clock() + 10
            return
        end
        openedHere = true
        task.wait(0.7)
    end
    if not valid("moon", version) then return end
    local nowTitle = child(modalPanel(), {"Content", "Inner", "Now", "Title"})
    local sky = visible(nowTitle) and textOf(nowTitle) or ""
    if modalTitle() ~= "MOONS" or sky == "" then
        nextMoon = os.clock() + 10
        log("Moon active title unreadable")
        if openedHere and modalTitle() == "MOONS" then
            closeModal("moon.close")
        end
        return
    end
    rememberStatus("aura", statusPlain(nowTitle))
    local aurora = moonIdentity(sky, true) == moonIdentity(potionConfig.when, true)
    if not aurora then
        if moonWasAurora then log("Selected Moon ended: " .. sky) end
        moonWasAurora, moonCardsDone = false, false
        moonUsed = {}
        nextMoon = os.clock() + 15
        if openedHere then closeModal("moon.close") end
        return
    end
    if not moonWasAurora then
        log("ACTIVE MOON confirmed: " .. sky)
        moonWasAurora = true
        moonUsed, moonCardsDone = {}, false
    end
    nextMoon = os.clock() + (moonCardsDone and 30 or 12)
    if openedHere then
        closeModal("moon.close")
        task.wait(0.4)
    end
    if not valid("moon", version) then return end
    local pending = false
    for _, id in ipairs({"luck", "haste", "gild"}) do
        if potionConfig.selected[id] and not moonUsed[id] then pending = true end
    end
    if moonCardsDone and not pending then return end
    if modalOpen() then
        note(potionConfig.when .. " active; close MOONS to use selected potions")
        return
    end
    if pending and not openPotions() then
        note(potionConfig.when .. " active; POTIONS entry unavailable; retrying")
        return
    end
    for _, id in ipairs({"luck", "haste", "gild"}) do
        if not valid("moon", version) then return end
        if potionConfig.selected[id] then usePotion(id) end
    end
    if modalTitle() == "POTIONS" then closeModal("moon.potions.close") end
    task.wait(0.5)
    if not valid("moon", version) then return end
    for _, id in ipairs({"luck", "haste", "gild"}) do
        if potionConfig.selected[id] and not moonUsed[id] then
            note(potionConfig.when .. ": " .. potionNames[id] .. " unavailable; retrying")
            return
        end
    end
    if not moonCardsDone then openOwnedCards(version) end
end

local function paintPotionChoices()
    potionUI.dropdown.Text = "Use Potion When: " .. potionConfig.when .. "   v"
    for _, id in ipairs({"luck", "haste", "gild"}) do
        potionUI.checks[id].Text = (potionConfig.selected[id] and "[x]  " or "[ ]  ") .. potionNames[id]
        potionUI.checks[id].BackgroundColor3 = potionConfig.selected[id]
            and Color3.fromRGB(31, 92, 84) or theme.off
    end
end
paintPotionChoices()
function potionUI.discover()
    local known = {}
    for _, name in ipairs(potionConfig.available) do known[moonIdentity(name, true)] = true end
    local root = pg:FindFirstChild("RollAStickman")
    local header = statusPlain(child(modalPanel(), {"Header", "Title"})):upper()
    local catalogModal = header:find("MOON", 1, true) or header:find("SHOP", 1, true)
    local currentTitle = header == "MOONS" and child(modalPanel(), {"Content", "Inner", "Now", "Title"})
    local added = 0
    for _, obj in ipairs(root and root:GetDescendants() or {}) do
        local text = statusPlain(obj)
        local allowShort = obj == currentTitle or text:upper():find("[X×]%s*[%d.,]+%s*LUCK") ~= nil
        -- Some catalog rows put the Moon name and luck multiplier in separate labels.
        if not allowShort and (obj.Name == "Title" or obj.Name == "Name")
            and moonIdentity(text, true) and obj.Parent then
            for _, sibling in ipairs(obj.Parent:GetDescendants()) do
                if sibling ~= obj and statusPlain(sibling):upper():find("[X×]%s*[%d.,]+%s*LUCK") then
                    allowShort = true
                    break
                end
            end
        end
        local key = moonIdentity(text, allowShort)
        if key and not known[key] then
            local context = text:upper():match("^SUMMON ") ~= nil
            local ancestor = obj.Parent
            while ancestor and ancestor ~= root and not context do
                local name = ancestor.Name:lower()
                context = name:find("moon", 1, true) or name:find("shop", 1, true)
                    or (catalogModal and ancestor == modalPanel())
                ancestor = ancestor.Parent
            end
            if context then
                known[key] = true
                table.insert(potionConfig.available, moonCaption(key))
                added = added + 1
            end
        end
    end
    if added > 0 then
        table.sort(potionConfig.available)
        settingsStorage = writeSettings(flags)
        log("Moon choices discovered from game UI: " .. table.concat(potionConfig.available, ", "))
    end
    return added
end
function potionUI.rebuild()
    for _, entry in ipairs(potionUI.entries) do entry:Destroy() end
    potionUI.entries = {}
    for i, name in ipairs(potionConfig.available) do
        local entry = Instance.new("TextButton")
        entry.Name = "MoonOption_" .. moonIdentity(name, true)
        entry.Position = UDim2.fromOffset(4, (i - 1) * 31 + 3)
        entry.Size = UDim2.new(1, -14, 0, 28)
        entry.ZIndex = 31
        entry.BackgroundColor3 = name == potionConfig.when and theme.accent or theme.off
        entry.TextColor3 = name == potionConfig.when and theme.base or theme.text
        entry.BorderSizePixel = 0
        entry.Font = Enum.Font.GothamMedium
        entry.TextSize = 12
        entry.Text = name
        entry.Parent = potionUI.option
        table.insert(potionUI.entries, entry)
        entry.Activated:Connect(function()
            if not alive then return end
            potionConfig.when = name
            potionUI.option.Visible = false
            versions.moon = versions.moon + 1
            moonWasAurora = false
            nextMoon = 0
            paintPotionChoices()
            settingsStorage = writeSettings(flags)
            log("Use Potion When: " .. name)
        end)
    end
    potionUI.option.CanvasSize = UDim2.fromOffset(0, #potionUI.entries * 31 + 6)
end
potionUI.discover()
potionUI.rebuild()
potionUI.dropdown.Activated:Connect(function()
    if alive and not minimized and activeTab == "Potion" then
        potionUI.discover()
        potionUI.rebuild()
        potionUI.option.Visible = not potionUI.option.Visible
    end
end)
potionUI.sync.Activated:Connect(function()
    if not alive then return end
    potionUI.option.Visible = false
    potionUI.scanRequested = true
    potionUI.sync.Text = "..."
end)
function potionUI.inspect()
    if not alive then return end
    if inDungeon() then note("Moon list: wait until the dungeon ends, then press SYNC"); return end
    if modalOpen() and modalTitle() ~= "MOONS" then
        note("Close the current game window, then press SYNC to read MOONS")
        return
    end
    local openedHere = false
    if modalTitle() ~= "MOONS" then
        if not fire("potion.sync.moons", get({"Frame", "Buffs", "Moon"}), nil, 2) then
            note("Cannot open MOONS; open it manually and press SYNC")
            return
        end
        openedHere = true
        task.wait(0.8)
    end
    if not alive then return end
    if modalTitle() == "MOONS" then
        potionUI.discover()
        potionUI.rebuild()
        log("MOON DATA | selected=" .. potionConfig.when .. " | choices=" .. table.concat(potionConfig.available, ", "))
        local root = child(modalPanel(), {"Content", "Inner"})
        local count = 0
        for _, obj in ipairs(root and root:GetDescendants() or {}) do
            local value = statusPlain(obj)
            if value ~= "" then
                local parts, parent = {}, obj
                while parent and parent ~= root do
                    table.insert(parts, 1, parent.Name)
                    parent = parent.Parent
                end
                log("MOON UI | " .. table.concat(parts, ".") .. " | visible=" .. tostring(visible(obj)) .. " | " .. value:sub(1, 200))
                count = count + 1
                if count >= 80 then log("MOON UI report limited to 80 entries"); break end
            end
        end
        note("Moon choices: " .. #potionConfig.available .. " found in game UI")
        if openedHere then closeModal("potion.sync.close") end
    else
        note("MOONS did not open; press SYNC again when ready")
    end
end
for _, id in ipairs({"luck", "haste", "gild"}) do
    potionUI.checks[id].Activated:Connect(function()
        potionConfig.selected[id] = not potionConfig.selected[id]
        potionUI.option.Visible = false
        versions.moon = versions.moon + 1
        nextMoon = 0
        paintPotionChoices()
        settingsStorage = writeSettings(flags)
        log(potionNames[id] .. (potionConfig.selected[id] and " selected" or " unchecked"))
    end)
end

local statusNextPowerScan = 0
local function scanTeamPower()
    -- Accept an explicit team/total-power field, never a random card's POWER.
    for _, root in pairs({get({"Frame", "Hud"}), get({"Frame", "Battle", "Party"}), page()}) do
        if root and visible(root) then
            for _, obj in ipairs(root:GetDescendants()) do
                if visible(obj) then
                    local name = obj.Name:lower():gsub("[%s_]", "")
                    local value = statusPlain(obj)
                    local upper = value:upper()
                    if name == "teampower" or name == "totalpower"
                        or upper:match("^TEAM POWER") or upper:match("^TOTAL POWER") then
                        if value:find("%d") then return value end
                        for _, part in ipairs({"Value", "Amount"}) do
                            local number = child(obj, {part}) or child(obj.Parent, {part})
                            local found = visible(number) and statusPlain(number) or ""
                            if found:find("%d") then return found end
                        end
                    end
                end
            end
        end
    end
end
local function refreshStatus(now)
    local function put(key, value)
        local row = statusRows[key]
        if row then row.obj.Text = row.caption .. "\n" .. tostring(value) end
    end
    put("luck", sampleStatus("luck", get({"Frame", "Hud", "Luck", "Pill", "Value"})))
    put("battleLuck", sampleStatus("battleLuck", get({"Frame", "Battle", "Dock", "LuckTab", "Pill", "Value"})))
    put("rolls", sampleStatus("rolls", get({"Frame", "Hud", "Rolls", "Pill", "Value"})))
    put("autoRoll", sampleStatus("autoRoll", get({"Frame", "Battle", "Dock", "RollBreath", "Roll", "Face", "Sub"})))
    put("battle", sampleStatus("battle", get({"Frame", "Battle", "Stage", "Ribbon", "Title"})))
    put("moonTimer", sampleStatus("moonTimer", get({"Frame", "Buffs", "Moon", "Pill", "Value"})))
    if modalTitle() == "MOONS" then
        if potionUI.discover() > 0 then potionUI.rebuild() end
        local sky = child(modalPanel(), {"Content", "Inner", "Now", "Title"})
        if visible(sky) then rememberStatus("aura", statusPlain(sky)) end
    end
    put("aura", statusCache.aura and cachedStatus("aura") or "Open MOONS to confirm the active sky")
    if activeTab == "Status" and not minimized and now >= statusNextPowerScan then
        statusNextPowerScan = now + 3
        rememberStatus("power", scanTeamPower())
    end
    put("power", statusCache.power and cachedStatus("power") or "Not found in UI · open the team page")
    local screen = page()
    local dungeonTitle = child(screen, {"Hero", "Plate", "Title"})
    local tickets = child(screen, {"Hero", "Tickets", "R1", "Amount"})
    if visible(dungeonTitle) and visible(tickets) then
        rememberStatus("dungeon", statusPlain(dungeonTitle) .. " · " .. statusPlain(tickets))
    end
    put("dungeon", inDungeon() and "Dungeon battle in progress" or cachedStatus("dungeon"))
    local remaining = math.max(0, math.ceil(nextDungeon - now))
    local schedule = not flags.dungeon and "OFF" or dungeonStarted and "Dungeon running"
        or remaining == 0 and "Ready" or string.format("%02dh %02dm %02ds",
        math.floor(remaining / 3600), math.floor(remaining / 60) % 60, remaining % 60)
    put("nextDungeon", schedule)
    dungeonSchedule.Text = "Next dungeon check: " .. schedule
    put("expedition", tostring(expeditionBadgeCount()) .. " (notification badge)")
    if modalTitle() == "CARD PACKS" then
        local cards = child(modalPanel(), {"Content", "Inner", "Loose", "Row", "Label"})
        if visible(cards) then rememberStatus("cards", statusPlain(cards)) end
    end
    put("cards", cachedStatus("cards"))
    for _, id in ipairs({"luck", "haste", "gild"}) do
        local value
        if modalTitle() == "POTIONS" then
            value = sampleStatus(id .. "Potion", child(modalPanel(), {"Content", "Inner", id, "Status"}))
        else
            value = cachedStatus(id .. "Potion")
        end
        put(id .. "Potion", value)
        potionLabels[id].Text = value
    end
    put("runtime", string.format("%dm %02ds · %s", math.floor((now - startedAt) / 60),
        math.floor(now - startedAt) % 60, busy and "Working" or "Waiting"))
    local enabled = {}
    for _, key in ipairs(settingKeys) do
        if flags[key] then table.insert(enabled, titles[key]) end
    end
    put("switches", #enabled > 0 and table.concat(enabled, " · ") or "All OFF")
    put("storage", settingsStorage == "file" and "File · restores across restarts" or "Session only")
end

local enabledNames = {}
for _, key in ipairs(settingKeys) do
    if flags[key] then table.insert(enabledNames, titles[key]) end
end
if #enabledNames > 0 then
    status.Text = "Restored " .. #enabledNames .. " switch(es); see log"
else
    status.Text = "Ready. All switches are OFF."
end
log("Combined V1.2 R13 ready | restored from " .. (settingsSource or "defaults")
    .. " | saving to " .. settingsStorage .. " | ON: "
    .. (#enabledNames > 0 and table.concat(enabledNames, ", ") or "none"))
log("Auto Execute ready: register this complete file in your executor; startup waits for the game UI")
if settingsStorage ~= "file" then
    log("Settings are session-only: readfile/writefile support is needed to restore after restarting Roblox")
end
if type(firesignal) ~= "function" then
    note("Executor firesignal unavailable; no game buttons can be pressed")
end
task.spawn(function()
    while alive do
        local ok, err = pcall(function()
            local now = os.clock()
            local statusOk, statusError = pcall(refreshStatus, now)
            if not statusOk and not statusCache.errorLogged then
                statusCache.errorLogged = true
                log("Status display error: " .. tostring(statusError))
            end
            observeDungeon(now)
            local blockingDungeonResult = recoverDungeonModal(now)
            if not busy and potionUI.scanRequested then
                potionUI.scanRequested = false
                busy = true
                task.spawn(function()
                    local ok, err = pcall(potionUI.inspect)
                    busy = false
                    if alive then
                        potionUI.sync.Text = "SYNC"
                        if not ok then note("Moon list error: " .. tostring(err)) end
                    end
                end)
            end
            if flags.raid and not modalOpen() and now >= nextRaid then
                raidTick()
            end
            if not busy and flags.level and not modalOpen() and now >= nextLevel then
                run("level", levelTick)
            end
            if not busy and flags.moon and not inDungeon() and
                now >= nextMoon then
                run("moon", moonTick)
            end
            if not busy and flags.expedition and not blockingDungeonResult
                and now >= nextExpedition then
                if modalTitle() == "EXPEDITIONS" or expeditionBadgeCount() > 0 then
                    run("expedition", expeditionTick)
                else
                    nextExpedition = now + 8
                end
            end
            if not busy and flags.dungeon and not dungeonStarted and
                not inDungeon() and not modalOpen() and now >= nextDungeon then
                if waveBattle() or dungeonTypeOnPage() then
                    run("dungeon", runDungeon)
                end
            end
        end)
        if not ok then
            note("Scheduler error: " .. tostring(err))
            task.wait(3)
        end
        task.wait(1)
    end
end)
end, function(err)
    return tostring(err)
end)
if startupOk then
    local player = game:GetService("Players").LocalPlayer
    local pg = player and player:FindFirstChild("PlayerGui")
    local old = pg and pg:FindFirstChild("RollStickman_StartupError")
    if old then old:Destroy() end
end
if not startupOk then
    warn("[RAS] Startup error: " .. startupError)
    local ok, pg = pcall(function()
        return game:GetService("Players").LocalPlayer:FindFirstChild("PlayerGui")
    end)
    if ok and pg then
        local old = pg:FindFirstChild("RollStickman_StartupError")
        if old then old:Destroy() end
        local gui = Instance.new("ScreenGui")
        gui.Name = "RollStickman_StartupError"
        gui.ResetOnSpawn = false
        gui.DisplayOrder = 1000
        local message = Instance.new("TextLabel")
        message.Size = UDim2.fromOffset(600, 110)
        message.Position = UDim2.fromOffset(20, 160)
        message.BackgroundColor3 = Color3.fromRGB(90, 27, 35)
        message.TextColor3 = Color3.new(1, 1, 1)
        message.TextWrapped = true
        message.Text = "ROLL A STICKMAN STARTUP ERROR\n" .. startupError
        message.Parent = gui
        gui.Parent = pg
    end
end
