-- Roll A Stickman Combined Auto V1.2 R61
-- UI-driven automation for PlaceId 115068315659966.
-- Run once in Potassium. Requires executor firesignal for GuiButton.Activated.
-- Auto Execute: add this complete file to your executor's Auto Execute list.
-- Waiting for game/player/UI readiness is handled below; no remote loader needed.

local boot = {phase = "Waiting for game"}
function boot.show(pg, message)
    boot.phase = message
    if not boot.gui then
        local previous = pg:FindFirstChild("RollStickman_BootStatus")
        if previous then previous:Destroy() end
        boot.gui = Instance.new("ScreenGui")
        boot.gui.Name = "RollStickman_BootStatus"
        boot.gui.ResetOnSpawn = false
        boot.gui.DisplayOrder = 1002
        boot.label = Instance.new("TextLabel")
        boot.label.Size = UDim2.fromOffset(550, 80)
        boot.label.Position = UDim2.fromOffset(12, 240)
        boot.label.BackgroundColor3 = Color3.fromRGB(24, 40, 65)
        boot.label.TextColor3 = Color3.new(1, 1, 1)
        boot.label.TextWrapped = true
        boot.label.Parent = boot.gui
        boot.gui.Parent = pg
    end
    boot.label.Text = "ROLL A STICKMAN R61\n" .. message
end
local startupOk, startupError = xpcall(function()

print("[RAS] R61 starting; waiting for game to load")
if not game:IsLoaded() then game.Loaded:Wait() end
assert(game.PlaceId == 115068315659966, "This script requires Roll A Stickman PlaceId 115068315659966")
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
boot.show(pg, "Waiting for RollAStickman game UI (up to 120 seconds)")
assert(pg:WaitForChild("RollAStickman", 120), "RollAStickman UI not ready after 120s")
boot.show(pg, "Reading saved settings")

local SETTINGS_FILE = "RollStickman_Combined_V1_2_settings.json"
local SETTINGS_KEY = "RollStickman_Combined_V1_2_settings"
local settingKeys = {"level", "raid", "arena", "dungeon", "expedition", "guildBoss", "turkeyTrot", "feastDraft", "antiAfk"}
local appConfig = {}
local function settingsEnv()
    if type(getgenv) == "function" then
        local ok, env = pcall(getgenv)
        if ok and type(env) == "table" then return env end
    end
    if type(shared) == "table" then return shared end
    return _G
end
local draftConfig = {
    rarities = {"MYTHIC", "LEGENDARY", "EPIC", "RARE", "UNCOMMON", "COMMON"},
    stats = {"ATK", "SPD", "HP", "SHIELD", "THORNS"},
}
function draftConfig.order(value, fallback)
    local order, seen = {}, {}
    for _, list in ipairs({type(value) == "table" and value or {}, fallback}) do
        for _, name in ipairs(list) do
            if type(name) == "string" and #name <= 32 and name:match("^[%a ]+$") then
                name = name:upper()
                if not seen[name] and #order < 24 then order[#order + 1] = name; seen[name] = true end
            end
        end
    end
    return order
end
local function cleanSettings(value)
    if type(value) ~= "table" or (value.placeId and value.placeId ~= game.PlaceId) then return nil end
    local from = type(value.flags) == "table" and value.flags or value
    local cleaned = {}
    for _, key in ipairs(settingKeys) do cleaned[key] = from[key] == true end
    if from.antiAfk == nil then cleaned.antiAfk = true end
    local position
    if type(value.position) == "table" then
        local x, y = tonumber(value.position.x), tonumber(value.position.y)
        if x and y and x == x and y == y and math.abs(x) < math.huge and math.abs(y) < math.huge then
            position = {x = x, y = y}
        end
    end
    local allowed = {Status=true, Team=true, Fight=true, ["Feast Draft"]=true, Settings=true}
    local tab = allowed[value.activeTab] and value.activeTab or "Fight"
    -- Migrate only the retained farm/draft preferences from legacy settings.
    local source = type(value.config) == "table" and value.config
        or (type(value.potion) == "table" and value.potion or {})
    local config = {
        farmMode = (source.farmMode == "turkeyTrot" or source.farmMode == "endless") and source.farmMode or nil,
        draftChoice = (source.draftChoice == 2 or source.draftChoice == 3) and source.draftChoice or 1,
        draftRarityOrder = draftConfig.order(source.draftRarityOrder, draftConfig.rarities),
        draftStatOrder = draftConfig.order(source.draftStatOrder, draftConfig.stats),
    }
    return cleaned, position, tab, config
end
local function readSettings()
    if type(readfile) == "function" then
        local ok, content = pcall(readfile, SETTINGS_FILE)
        if ok and type(content) == "string" then
            local decodedOK, decoded = pcall(HttpService.JSONDecode, HttpService, content)
            if decodedOK then
                local saved, position, tab, config = cleanSettings(decoded)
                if saved then return saved, "file", position, tab, config end
            end
        end
    end
    local env = settingsEnv()
    local saved, position, tab, config = cleanSettings(type(env) == "table" and env[SETTINGS_KEY] or nil)
    return saved, saved and "session" or nil, position, tab, config
end
local settingsPosition
local settingsTab = "Fight"
local function writeSettings(current)
    local saved = {placeId=game.PlaceId, flags={}, activeTab=settingsTab, position=settingsPosition, config={
        farmMode=appConfig.farmMode, draftChoice=appConfig.draftChoice or 1,
        draftRarityOrder=draftConfig.order(appConfig.draftRarityOrder, draftConfig.rarities),
        draftStatOrder=draftConfig.order(appConfig.draftStatOrder, draftConfig.stats),
    }}
    for _, key in ipairs(settingKeys) do saved.flags[key] = current[key] == true end
    local env = settingsEnv()
    if type(env) == "table" then env[SETTINGS_KEY] = saved end
    if type(writefile) ~= "function" then return "session" end
    local ok = pcall(function() writefile(SETTINGS_FILE, HttpService:JSONEncode(saved)) end)
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
    local names = {level = "LevelToggle", raid = "RaidToggle", arena = "ArenaToggle",
        dungeon = "DungeonToggle", expedition = "ExpeditionToggle", guildBoss = "GuildBossToggle", turkeyTrot = "TurkeyTrotToggle", feastDraft = "FeastDraftToggle",
        antiAfk = "AntiAfkToggle"}
    for key, name in pairs(names) do
        local storedFlag = previous:GetAttribute("Flag_" .. key)
        if type(storedFlag) == "boolean" then previousFlags[key] = storedFlag end
        local obj = previousPanel and previousPanel:FindFirstChild(name)
        if obj and obj:IsA("TextButton") and key ~= "turkeyTrot" then
            previousFlags[key] = obj.Text:upper():match(":%s*ON$") ~= nil
        end
    end
end
if previous then previous:Destroy() end

boot.show(pg, "Building automation UI")
local gui = Instance.new("ScreenGui")
gui.Name = NAME
gui:SetAttribute("StartupReady", false)
gui.ResetOnSpawn = false
gui.DisplayOrder = 240
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui:SetAttribute("UITheme", "Neon V2")
local PANEL_HEIGHT = 460
local neonUI = {width = 670, contentWidth = 464, pageFrames = {}, resumeFlags = {}}
local theme = {
    base = Color3.fromRGB(12, 10, 27), card = Color3.fromRGB(35, 23, 60),
    muted = Color3.fromRGB(175, 153, 207), text = Color3.fromRGB(245, 235, 255),
    accent = Color3.fromRGB(151, 76, 255), off = Color3.fromRGB(35, 23, 60),
    surface = Color3.fromRGB(25, 17, 44),
}
local panel = Instance.new("Frame")
panel.Name = "Panel"
panel.Size = UDim2.fromOffset(neonUI.width, PANEL_HEIGHT)
panel.Position = UDim2.fromOffset(12, 160)
panel.BackgroundColor3 = theme.base
panel.BorderSizePixel = 0
panel.Active = true
panel.Parent = gui
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 12)
corner.Parent = panel
local outline = Instance.new("UIStroke")
outline.Color = theme.accent
outline.Transparency = 0.45
outline.Thickness = 1
outline.Parent = panel
local header = Instance.new("Frame")
header.Name = "Header"
header.Size = UDim2.new(1, 0, 0, 54)
header.BackgroundColor3 = theme.base
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
local title = label("Title", "ROLL A STICKMAN  |  R61  ·  NEON V2", 12, 32)
title.Size = UDim2.fromOffset(550, 32)
title.TextSize = 17
title.Active = true
local minimizeUI = button("Minimize", "-", 589, 14, 28, 28)
local closeUI = button("Close", "X", 626, 14, 28, 28)
local tabPages = {Team = {}, Fight = {}, Status = {}, Settings = {}, ["Feast Draft"] = {}}
local tabButtons = {}
local activeTab = "Status"
neonUI.nav = Instance.new("ScrollingFrame")
neonUI.nav.Name = "Navigation"
neonUI.nav.Position = UDim2.fromOffset(12, 62)
neonUI.nav.Size = UDim2.fromOffset(145, 333)
neonUI.nav.BackgroundColor3 = theme.surface
neonUI.nav.BorderSizePixel = 0
neonUI.nav.ScrollBarThickness = 3
neonUI.nav.CanvasSize = UDim2.fromOffset(0, 221)
neonUI.nav.Parent = panel
neonUI.navRound = Instance.new("UICorner")
neonUI.navRound.CornerRadius = UDim.new(0, 9)
neonUI.navRound.Parent = neonUI.nav
neonUI.icons = {Status = "◉", Team = "♟", Fight = "⚔", Settings = "⚙", ["Feast Draft"] = "▤"}
for i, tab in ipairs({"Status", "Team", "Fight", "Feast Draft", "Settings"}) do
    local container = Instance.new("ScrollingFrame")
    container.Name = "Page" .. tab
    container.Position = UDim2.fromOffset(169, 62)
    container.Size = UDim2.fromOffset(488, 333)
    container.BackgroundColor3 = theme.surface
    container.BorderSizePixel = 0
    container.ScrollBarThickness = 4
    container.AutomaticCanvasSize = Enum.AutomaticSize.Y
    container.CanvasSize = UDim2.new()
    container.Visible = false
    container.Parent = panel
    neonUI.pageFrames[tab] = container
    local rounded = Instance.new("UICorner")
    rounded.CornerRadius = UDim.new(0, 9)
    rounded.Parent = container
    tabButtons[tab] = button("Tab" .. tab, "  " .. neonUI.icons[tab] .. "   " .. tab, 7, 8 + (i - 1) * 41, 131, 36)
    tabButtons[tab].Parent = neonUI.nav
    tabButtons[tab].TextSize = 13
    tabButtons[tab].TextXAlignment = Enum.TextXAlignment.Left
end
local function pageItem(tab, obj)
    table.insert(tabPages[tab], obj)
    local pos, size = obj.Position, obj.Size
    obj.Position = UDim2.new(pos.X.Scale, math.floor(12 + (pos.X.Offset - 12) * neonUI.contentWidth / 336),
        pos.Y.Scale, pos.Y.Offset - 78)
    if size.X.Scale == 0 then
        obj.Size = UDim2.new(0, math.floor(size.X.Offset * neonUI.contentWidth / 336), size.Y.Scale, size.Y.Offset)
    end
    obj.Parent = neonUI.pageFrames[tab]
    return obj
end
local function pageLabel(tab, name, value, y, height)
    local obj = pageItem(tab, label(name, value, y, height))
    obj.TextWrapped = true
    obj.TextColor3 = name:find("Heading") and theme.accent or theme.muted
    return obj
end
local toggles = {
    level = pageItem("Team", button("LevelToggle", "LEVEL UP: OFF", 12, 116, 336, 36)),
    arena = pageItem("Fight", button("ArenaToggle", "ARENA: OFF", 12, 158, 336, 36)),
    raid = pageItem("Fight", button("RaidToggle", "RAID: OFF", 12, 116, 336, 36)),
    dungeon = pageItem("Fight", button("DungeonToggle", "DUNGEON: OFF", 12, 200, 336, 36)),
    expedition = pageItem("Fight", button("ExpeditionToggle", "EXPEDITIONS: OFF", 12, 242, 336, 36)),
    guildBoss = pageItem("Fight", button("GuildBossToggle", "GUILD BOSS: OFF", 12, 284, 336, 36)),
    turkeyTrot = pageItem("Fight", button("TurkeyTrotToggle", "FARM MODE: ENDLESS", 12, 326, 336, 36)),
    feastDraft = pageItem("Feast Draft", button("FeastDraftToggle", "FEAST DRAFT: OFF", 12, 116, 336, 36)),
    antiAfk = pageItem("Settings", button("AntiAfkToggle", "ANTI AFK: ON", 12, 116, 336, 36)),
}
pageLabel("Team", "TeamHeading", "TEAM  /  UPGRADES", 90, 20)
pageLabel("Team", "TeamHint", "LEVEL UP uses LEVEL UP ALL when that game button is visible. Open the team upgrade page to use it.", 165, 70)
pageLabel("Fight", "FightHeading", "FIGHT  /  AUTOMATION", 90, 20)
pageLabel("Fight", "DungeonMode", "DUNGEON · ALL TYPES\nNo tickets: check again after 2 hours.", 458, 42)
local dungeonSchedule = pageLabel("Fight", "DungeonSchedule", "Dungeon check: ready", 508, 38)
pageLabel("Fight", "ArenaHint", "ARENA · Continuous while available\nEmpty quota: check in 1 hour.", 558, 44)
neonUI.guildHint = pageLabel("Fight", "GuildBossHint", "GUILD BOSS · Checks when idle, then every 5 minutes.\nRaid has priority. COPY LOG includes battle snapshots.", 610, 60)
neonUI.trotHint = pageLabel("Fight", "TurkeyTrotHint", "FARM MODE · Click to select Turkey Trot / Endless. Activities return to the selected mode; no fallback.", 678, 44)
neonUI.draftChoice = pageItem("Feast Draft", button("DraftChoice", "TIEBREAK: LEFT", 12, 770, 336, 32))
pageLabel("Feast Draft", "DraftHeading", "FEAST DRAFT / CARD PRIORITIES", 90, 20)
pageLabel("Feast Draft", "DraftRules", "Rank 1 wins. Use arrows to reorder. Rarity first, then stat priority, then larger value. Unknown rarity ranks last; SET bonuses are not scored.", 164, 66)
pageLabel("Feast Draft", "RarityHeading", "1. RARITY PRIORITY", 240, 22)
pageLabel("Feast Draft", "StatHeading", "2. STAT PRIORITY", 498, 22)
neonUI.draftHint = pageLabel("Feast Draft", "DraftHint", "Default: rarity first, then ATK / SPD / HP / SHIELD / THORNS. Equal scores use the chosen tiebreak position.", 814, 64)
pageLabel("Fight", "DraftShortcutHint", "FEAST DRAFT settings and automation are on the Feast Draft page.", 410, 40)
pageLabel("Status", "StatusHeading", "STATUS  /  LIVE GAME VALUES", 90, 20)
local statusScroll = Instance.new("ScrollingFrame")
statusScroll.Name = "StatusPage"
statusScroll.Position = UDim2.fromOffset(12, 126)
statusScroll.Size = UDim2.fromOffset(336, 277)
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
    
    {"power", "TEAM POWER"}, {"battle", "BATTLE / STAGE"},
    {"rolls", "TOTAL ROLLS"}, {"autoRoll", "AUTO ROLL"},
    {"dungeon", "DUNGEON / TICKETS"}, {"nextDungeon", "NEXT DUNGEON CHECK"},
    {"expedition", "EXPEDITIONS READY"},
    {"runtime", "SESSION / SCHEDULER"},
    {"switches", "ENABLED SYSTEMS"}, {"storage", "SETTINGS STORAGE"},
}) do statusRow(spec[1], spec[2]) end
pageLabel("Settings", "SettingsHeading", "SETTINGS  /  SESSION & LOG", 90, 20)
pageLabel("Settings", "SettingsHint", "Switches, farm mode, draft priorities and window position save automatically. Alt minimizes this window. RESTORE SWITCHES restores the last STOP ALL selection.", 158, 60)
neonUI.storage = pageLabel("Settings", "StorageInfo", "Settings storage: starting", 225, 24)
local copyButton = pageItem("Settings", button("CopyLog", "COPY LOG / UI REPORT", 12, 258, 336, 32))
local logHeader = pageLabel("Settings", "LogHeader", "ACTIVITY LOG", 302, 20)
local scroll = Instance.new("ScrollingFrame")
scroll.Name = "ActivityLog"
scroll.Position = UDim2.fromOffset(12, 330)
scroll.Size = UDim2.fromOffset(336, 190)
scroll.BackgroundColor3 = theme.base
scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 4
scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
scroll.CanvasSize = UDim2.new()
pageItem("Settings", scroll)
local status = label("Status", "Starting...", 396, 14)
status.Position = UDim2.fromOffset(169, 396)
status.Size = UDim2.fromOffset(488, 14)
status.TextSize = 10
status.TextTruncate = Enum.TextTruncate.AtEnd
neonUI.resume = button("Resume", "RESTORE SWITCHES", 12, 412, 316, 36)
neonUI.resume.BackgroundColor3 = theme.accent
local stopButton = button("StopAll", "STOP ALL", 342, 412, 316, 36)
stopButton.BackgroundColor3 = theme.card
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
boot.show(pg, "Applying settings and starting automation")
local alive = true
local minimized = false
local savedFlags, settingsSource, savedPosition, savedTab, savedConfig = readSettings()
if savedConfig then appConfig = savedConfig end
appConfig.draftRarityOrder = draftConfig.order(appConfig.draftRarityOrder, draftConfig.rarities)
appConfig.draftStatOrder = draftConfig.order(appConfig.draftStatOrder, draftConfig.stats)
if not savedFlags and next(previousFlags) then
    savedFlags, settingsSource = previousFlags, "previous UI"
end
local flags = {}
for _, key in ipairs(settingKeys) do
    flags[key] = savedFlags and savedFlags[key] == true or false
end
if not savedFlags or savedFlags.antiAfk == nil then flags.antiAfk = true end
appConfig.farmMode = appConfig.farmMode or (flags.turkeyTrot and "turkeyTrot" or "endless")
local function clampPosition(x, y)
    local camera = workspace.CurrentCamera
    local viewport = camera and camera.ViewportSize or Vector2.new(1920, 1080)
    return math.clamp(x, 0, math.max(0, viewport.X - neonUI.width)),
        math.clamp(y, 0, math.max(0, viewport.Y - panel.Size.Y.Offset))
end
if savedPosition then
    local ok, x, y = pcall(clampPosition, savedPosition.x, savedPosition.y)
    if ok then panel.Position = UDim2.fromOffset(x, y) end
end
settingsPosition = {x = panel.Position.X.Offset, y = panel.Position.Y.Offset}
local versions = {level = 0, raid = 0, arena = 0, dungeon = 0, expedition = 0, guildBoss = 0, turkeyTrot = 0, feastDraft = 0, antiAfk = 0}
local titles = {level = "LEVEL UP", raid = "RAID", arena = "ARENA", dungeon = "DUNGEON", guildBoss = "GUILD BOSS", turkeyTrot = "FARM MODE", feastDraft = "FEAST DRAFT",
    expedition = "EXPEDITIONS", antiAfk = "ANTI AFK"}
local function paintToggle(key)
    if key == "turkeyTrot" then
        toggles[key].Text = "FARM MODE: " .. (appConfig.farmMode == "turkeyTrot" and "TURKEY TROT" or "ENDLESS")
            .. (flags[key] and "" or " (PAUSED)")
    end
    gui:SetAttribute("Flag_" .. key, flags[key] == true)
    toggles[key].BackgroundColor3 = flags[key]
        and theme.accent or theme.off
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
        tabButtons[tab].TextColor3 = theme.text
        neonUI.pageFrames[tab].Visible = tab == name
    end
    settingsStorage = writeSettings(flags)
    gui:SetAttribute("ActiveTab", name)
end
for name, tabButton in pairs(tabButtons) do
    tabButton.Activated:Connect(function() setTab(name) end)
end
setTab(savedTab or "Status")
-- Only fold this panel. The scheduler and enabled switches keep running.
local foldedVisibility = {}
local function toggleMinimized()
    if not alive then return end
    minimized = not minimized
    for _, obj in ipairs(panel:GetChildren()) do
        if obj:IsA("GuiObject") and obj ~= minimizeUI then
            if minimized then
                foldedVisibility[obj] = obj.Visible
                obj.Visible = false
            else
                obj.Visible = foldedVisibility[obj] ~= false
            end
        end
    end
    panel.Size = minimized and UDim2.fromOffset(24, 24) or UDim2.fromOffset(neonUI.width, PANEL_HEIGHT)
    panel.ClipsDescendants = minimized
    minimizeUI.Position = minimized and UDim2.fromOffset(0, 0) or UDim2.fromOffset(589, 14)
    minimizeUI.Size = minimized and UDim2.fromOffset(24, 24) or UDim2.fromOffset(28, 28)
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
    local result = textOf(value)
    if result == "" and obj then
        for _, item in ipairs(obj:GetDescendants()) do
            if visible(item) then
                result = textOf(item)
                if result ~= "" then return result end
            end
        end
    end
    return result
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
    if busy or os.clock() < (neonUI.raidPriorityUntil or 0) then return end
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
        if key == "turkeyTrot" then
            appConfig.farmMode = appConfig.farmMode == "turkeyTrot" and "endless" or "turkeyTrot"
            flags[key] = true
            versions[key] = versions[key] + 1
            if neonUI.trot then neonUI.trot.nextCheck = 0; neonUI.trot.observed = false end
            paintToggle(key)
            settingsStorage = writeSettings(flags)
            note("Farm mode selected: " .. (appConfig.farmMode == "turkeyTrot" and "TURKEY TROT" or "ENDLESS"))
            return
        end
        flags[key] = not flags[key]
        versions[key] = versions[key] + 1
        if key == "guildBoss" and neonUI.guild then neonUI.guild.nextCheck = 0 end
        if key == "feastDraft" and neonUI.draft then
            neonUI.draft.nextCheck = 0
            neonUI.draft.engaged, neonUI.draft.blocked = false, false
            neonUI.draft.pending = nil
        end
        if key == "turkeyTrot" and neonUI.trot then neonUI.trot.nextCheck = 0; neonUI.trot.observed = false end
        local title = titles[key]
        obj.Text = title .. (flags[key] and ": ON" or ": OFF")
        paintToggle(key)
        settingsStorage = writeSettings(flags)
        note(title .. (flags[key] and " enabled" or " disabled"))
    end)
end
neonUI.resume.Activated:Connect(function()
    local restored = 0
    for key, selected in pairs(neonUI.resumeFlags) do
        if selected and not flags[key] then
            flags[key] = true
            versions[key] = versions[key] + 1
            toggles[key].Text = titles[key] .. ": ON"
            paintToggle(key)
            restored = restored + 1
        end
    end
    settingsStorage = writeSettings(flags)
    note(restored > 0 and ("Restored " .. restored .. " switch(es)") or "Choose a system switch to start; RESTORE SWITCHES recalls the last STOP ALL")
end)
stopButton.Activated:Connect(function()
    local selected = {}
    for key, enabled in pairs(flags) do if enabled then selected[key] = true end end
    if next(selected) then neonUI.resumeFlags = selected end
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
-- Capture the game UI at the moment COPY LOG is pressed. No game actions,
-- remotes, or user-entered TextBox contents are included in this report.
function neonUI.captureGameUI()
    local root = pg:FindFirstChild("RollAStickman")
    local lines = {"GAME UI REPORT | R61 | " .. os.date("!%Y-%m-%dT%H:%M:%SZ"),
        "PlaceId=" .. tostring(game.PlaceId) .. " | busy=" .. tostring(busy),
        "Open Guild > Boss before copying; paths are relative to RollAStickman."}
    if not root then
        table.insert(lines, "Game UI root missing")
        return table.concat(lines, "\n")
    end
    local total = 0
    for _, obj in ipairs(root:GetDescendants()) do
        if visible(obj) and (obj:IsA("GuiButton") or obj:IsA("TextLabel")) then
            local value = textOf(obj)
            if obj:IsA("GuiButton") or value ~= "" then
                if total >= 600 then
                    table.insert(lines, "TRUNCATED: more than 600 visible controls")
                    break
                end
                local parts, current = {}, obj
                while current and current ~= root do
                    table.insert(parts, 1, current.Name)
                    current = current.Parent
                end
                local detail = obj:IsA("GuiButton")
                    and (" | button=" .. buttonText(obj):sub(1, 180)
                        .. " | active=" .. tostring(obj.Active)
                        .. " | ready=" .. tostring(ready(obj) == true)) or ""
                table.insert(lines, table.concat(parts, "/") .. " | " .. obj.ClassName
                    .. " | text=" .. value:sub(1, 180) .. detail)
                total = total + 1
            end
        end
    end
    table.insert(lines, "END GAME UI REPORT | controls=" .. total)
    return table.concat(lines, "\n")
end
copyButton.Activated:Connect(function()
    local value = table.concat(logs, "\n")
    local reportOK, report = pcall(neonUI.captureGameUI)
    value = value .. "\n\n" .. (reportOK and report or ("GAME UI REPORT ERROR: " .. tostring(report)))
    if neonUI.draft and neonUI.draft.report then
        value = value .. "\n\n" .. neonUI.draft.report
    end
    if neonUI.trot and neonUI.trot.report then
        value = value .. "\n\n" .. neonUI.trot.report
    end
    if neonUI.guild and #neonUI.guild.reports > 0 then
        value = value .. "\n\nGUILD BOSS HISTORY\n" .. table.concat(neonUI.guild.reports, "\n\n")
    end
    if type(setclipboard) == "function" and pcall(setclipboard, value) then
        copyButton.Text = "COPIED"
    else
        if minimized then toggleMinimized() end
        setTab("Settings")
        neonUI.pageFrames.Settings.CanvasPosition = Vector2.new(0, scroll.Position.Y.Offset)
        logBox.Text = value
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
-- Search only the current game page/modal; never click matching shop/nav text.
local function uiButton(root, labels)
    if not root then return nil end
    for _, obj in ipairs(root:GetDescendants()) do
        if ready(obj) then
            local value = buttonText(obj)
            if labels[value] then return obj end
            for _, labelObj in ipairs(obj:GetDescendants()) do
                if visible(labelObj) and labels[textOf(labelObj)] then return obj end
            end
        end
    end
end
local function uiSummary(root)
    local found, seen = {}, {}
    if root then
        for _, obj in ipairs(root:GetDescendants()) do
            local value = visible(obj) and textOf(obj) or ""
            if value ~= "" and not seen[value] and #found < 30 then
                seen[value] = true
                table.insert(found, value)
            end
        end
    end
    return table.concat(found, " | ")
end
-- Every activity returns directly to the user's selected farm mode.
neonUI.farm = {}
function neonUI.farm.key()
    return appConfig.farmMode == "turkeyTrot" and "trot" or "endless"
end
function neonUI.farm.name()
    return appConfig.farmMode == "turkeyTrot" and "TURKEY TROT" or "ENDLESS"
end
function neonUI.farm.tab()
    return get({"Frame", "Nav", "Row", neonUI.farm.key()})
end
function neonUI.farm.active()
    local label = child(neonUI.farm.tab(), {"Label"})
    local value = visible(label) and textOf(label) or ""
    local navKind, navNumber = value:match("^(%u+) (%d+)$")
    local battleKind, battleNumber = battleTitle():match("^(%u+) (%d+)")
    return (navKind == "WAVE" or navKind == "BOSS")
        and navKind == battleKind and navNumber == battleNumber
        and visible(get({"Frame", "Battle"})) and not visible(page())
end

-- Feast Draft page/CONTINUE and three Dish buttons verified in R56 UI report.
neonUI.draft = {nextCheck = 0, engaged = false, blocked = false}
function neonUI.draft.page()
    local root = child(page(), {"Scroll"})
    local title = child(root, {"Hero", "Plate", "Title"})
    return visible(title) and textOf(title) == "FEAST DRAFT" and root or nil
end
function neonUI.draft.modal()
    return modalTitle() == "FEAST DRAFT"
end
function neonUI.draft.pause(reason)
    local draft = neonUI.draft
    draft.engaged, draft.blocked, draft.nextCheck = true, true, math.huge
    local ok, report = pcall(neonUI.captureGameUI)
    if ok then draft.report = "FEAST DRAFT | " .. reason .. "\n" .. report end
    neonUI.draftHint.Text = "FEAST DRAFT · " .. reason .. ". COPY LOG; switch OFF to release other tasks."
    note("Feast Draft paused: " .. reason .. "; COPY LOG")
end
function neonUI.draft.choices()
    if not neonUI.draft.modal() then return nil end
    local root = child(modalPanel(), {"Content", "Inner", "Scroll"})
    local dishes = child(root, {"Dishes"})
    if not visible(dishes) then return nil end
    local choices = {}
    for _, obj in ipairs(dishes:GetChildren()) do
        if ready(obj) and obj.Name:match("^Dish") then table.insert(choices, obj) end
    end
    if #choices ~= 3 then return nil end
    table.sort(choices, function(a, b)
        if a.AbsolutePosition.X == b.AbsolutePosition.X then return a.Name < b.Name end
        return a.AbsolutePosition.X < b.AbsolutePosition.X
    end)
    local header = child(root, {"Head", "Name"})
    local value = visible(header) and textOf(header) or ""
    local stage = tonumber(value:match("^WAVE (%d+)$") or value:match("^WAVE (%d+)%s"))
    local signature = value
    for _, obj in ipairs(choices) do signature = signature .. "|" .. obj.Name end
    return choices, stage, signature
end
function neonUI.draft.cardInfo(obj)
    local rarity = child(obj, {"SizeWord"})
    local info = {rarity = visible(rarity) and textOf(rarity) or "UNKNOWN", stats = {},
        name = textOf(child(obj, {"Name"})), set = textOf(child(obj, {"Set"}))}
    local buffs = child(obj, {"Buff"})
    for _, item in ipairs(buffs and buffs:GetDescendants() or {}) do
        if visible(item) and item.Name == "Amount" then
            local text = textOf(item)
            local amount, stat = text:match("^([%+%-]?%d+%.?%d*)%%?%s+([A-Z ]+)$")
            amount = tonumber(amount)
            if amount and stat then
                stat = stat:gsub("%s+$", "")
                info.stats[stat] = (info.stats[stat] or 0) + amount
            end
        end
    end
    return info
end
function neonUI.draft.choose(choices)
    local draft = neonUI.draft
    local rank = {}
    for i, name in ipairs(appConfig.draftRarityOrder) do rank[name] = i end
    local infos = {}
    for i, obj in ipairs(choices) do
        infos[i] = draft.cardInfo(obj)
        infos[i].rank = rank[infos[i].rarity] or math.huge
    end
    local function better(a, b)
        if a.rank ~= b.rank then return a.rank < b.rank end
        for _, stat in ipairs(appConfig.draftStatOrder) do
            local av, bv = a.stats[stat], b.stats[stat]
            if (av ~= nil) ~= (bv ~= nil) then return av ~= nil end
            if av and av ~= bv then return av > bv end
        end
        return false
    end
    local best = math.clamp(appConfig.draftChoice or 1, 1, #choices)
    for i = 1, #choices do if better(infos[i], infos[best]) then best = i end end
    for i, info in ipairs(infos) do
        local buffs = {}
        for _, stat in ipairs(appConfig.draftStatOrder) do
            if info.stats[stat] then buffs[#buffs + 1] = stat .. "=" .. info.stats[stat] end
        end
        log("Draft option " .. i .. " | " .. info.rarity .. " | " .. info.name
            .. " | " .. table.concat(buffs, ", ") .. (i == best and " | SELECTED" or ""))
    end
    return best
end

function neonUI.draft.tick(version)
    local draft = neonUI.draft
    if not valid("feastDraft", version) or draft.blocked then return end
    draft.nextCheck = os.clock() + 1
    if draft.modal() then
        draft.engaged = true
        local choices, stage, signature = draft.choices()
        if not choices or not stage or stage < 1 or stage > 50 then
            draft.pause("Unknown Feast Draft screen"); return
        end
        if draft.pending == signature then return end
        local index = draft.choose(choices)
        local selected = choices[index]
        draft.pending = signature
        if not valid("feastDraft", version) then return end
        if not fire("draft.card." .. stage, selected, nil, 1) then
            draft.pending = nil; return
        end
        local name = textOf(child(selected, {"Name"}))
        note("Feast Draft card sent | stage=" .. stage .. "/50 | choice=" .. index
            .. " | " .. name .. " | " .. buttonText(selected))
        local deadline = os.clock() + 8
        repeat
            task.wait(0.25)
            if not valid("feastDraft", version) then return end
            local _, _, current = draft.choices()
            if not draft.modal() or (current and current ~= signature) then
                draft.pending = nil
                draft.lastProgress = os.clock()
                neonUI.draftHint.Text = "FEAST DRAFT · Choice screen advanced; stage " .. stage .. "/50"
                return
            end
        until os.clock() >= deadline
        draft.pause("Card selection unconfirmed"); return
    end
    if modalOpen() then return end
    local draftPick = get({"Frame", "Calls", "Draft", "Pick"})
    if draft.engaged and battleTitle():find("FEAST DRAFT", 1, true)
        and ready(draftPick) and buttonText(draftPick) == "PICK" then
        if not valid("feastDraft", version) then return end
        if fire("draft.pick", draftPick, "PICK", 3) then
            draft.lastProgress = os.clock()
            local deadline = os.clock() + 4
            repeat
                task.wait(0.25)
                if not valid("feastDraft", version) then return end
                if draft.modal() then return end
            until os.clock() >= deadline
            draft.pause("PICK did not open choices")
        end
        return
    end
    local root = draft.page()
    if not root then
        if draft.engaged then
            if os.clock() - (draft.lastProgress or os.clock()) > 300 then
                draft.pause("No stage progress for 5 minutes")
            end
            return
        end
        if not neonUI.draft.canStart() then return end
        if not fire("draft.dungeon", get({"Frame", "Nav", "Row", "dungeon"}), nil, 3) then return end
        task.wait(0.5)
        if not valid("feastDraft", version) then return end
        local screen = page()
        local scroll = screen and screen:FindFirstChild("Scroll")
        local pick = child(scroll, {"Pick", "draft"})
        if not draft.page() then
            if not fire("draft.tab", pick, "FEAST DRAFT", 3) then
                draft.nextCheck = os.clock() + 60
                note("Feast Draft selector unavailable")
                fire("draft.back", neonUI.farm.tab(), nil, 2)
                return
            end
            task.wait(0.5)
        end
        if not valid("feastDraft", version) then return end
        root = draft.page()
        if not root then draft.pause("Feast Draft page not confirmed"); return end
    end
    draft.engaged = true
    local go = child(root, {"Buttons", "Go"})
    local action, actionKey = "CONTINUE", "draft.continue"
    if not (ready(go) and buttonText(go) == "CONTINUE") then
        local start = child(root, {"Start", "Button"})
        if ready(start) and buttonText(start) == "START RUN" then
            local sub = child(start, {"Face", "Sub"})
            local quota = visible(sub) and textOf(sub) or ""
            local left = tonumber(quota:match("^(%d+)%s*/%s*%d+%s+LEFT$"))
            if not left then draft.pause("START RUN quota unreadable"); return end
            if left == 0 then
                draft.engaged = false
                draft.nextCheck = os.clock() + 300
                neonUI.draftHint.Text = "FEAST DRAFT · No runs left; check again in 5 minutes"
                note("Feast Draft quota empty; returning to selected farm mode")
                if valid("feastDraft", version) then fire("draft.back", neonUI.farm.tab(), nil, 2) end
                return
            end
            go, action, actionKey = start, "START RUN", "draft.start"
            log("Feast Draft starting new run | " .. quota)
        end
    end
    if ready(go) and buttonText(go) == action then
        local deadline = os.clock() + 6
        if not valid("feastDraft", version) then return end
        if not fire(actionKey, go, action, 2) then return end
        draft.lastProgress = os.clock()
        repeat
            task.wait(0.25)
            if not valid("feastDraft", version) then return end
            if draft.modal() or not draft.page() then return end
            local continue = child(draft.page(), {"Buttons", "Go"})
            if action == "START RUN" and ready(continue) and buttonText(continue) == "CONTINUE" then return end
        until os.clock() >= deadline
        draft.pause(action .. " not confirmed")
    else
        draft.pause("Start/result action not yet identified")
    end
end
function neonUI.draft.paintChoice()
    neonUI.draftChoice.Text = "TIEBREAK: " .. ({"LEFT", "MIDDLE", "RIGHT"})[appConfig.draftChoice or 1]
end
function neonUI.draft.paintRanks()
    for _, group in ipairs(neonUI.draft.rankRows) do
        local order = appConfig[group.field]
        for i, row in ipairs(group.rows) do row.Text = i .. ". " .. order[i] end
    end
end
function neonUI.draft.buildRanks()
    neonUI.draft.rankRows = {}
    for _, spec in ipairs({{field = "draftRarityOrder", y = 268}, {field = "draftStatOrder", y = 528}}) do
        local group = {field = spec.field, rows = {}}
        table.insert(neonUI.draft.rankRows, group)
        for i = 1, #appConfig[spec.field] do
            local index = i
            local y = spec.y + (i - 1) * 36
            group.rows[i] = pageItem("Feast Draft", button(spec.field .. i, "", 12, y, 236, 30))
            for _, direction in ipairs({-1, 1}) do
                local delta = direction
                local arrow = pageItem("Feast Draft", button(spec.field .. i .. direction,
                    direction == -1 and "↑" or "↓", direction == -1 and 254 or 302, y, 44, 30))
                arrow.Activated:Connect(function()
                    local order = appConfig[group.field]
                    local target = index + delta
                    if target < 1 or target > #order then return end
                    order[index], order[target] = order[target], order[index]
                    neonUI.draft.paintRanks()
                    settingsStorage = writeSettings(flags)
                end)
            end
        end
    end
    neonUI.draft.paintRanks()
end
neonUI.draft.buildRanks()

neonUI.draft.paintChoice()
neonUI.draftChoice.Activated:Connect(function()
    appConfig.draftChoice = (appConfig.draftChoice or 1) % 3 + 1
    neonUI.draft.paintChoice()
    settingsStorage = writeSettings(flags)
end)

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
local dungeonUI = {}
function dungeonUI.hero()
    local root = page()
    return root and root:FindFirstChild("Hero", true)
end
function dungeonUI.tickets()
    local hero = dungeonUI.hero()
    local tickets = hero and hero:FindFirstChild("Tickets", true)
    if not tickets or not visible(tickets) then return nil, "unreadable" end
    for _, obj in ipairs(tickets:GetDescendants()) do
        local value = visible(obj) and textOf(obj) or ""
        local count = tonumber(value:match("^(%d+)%s*/%s*%d+"))
        if count then return count, value end
    end
    return nil, "unreadable"
end
function dungeonUI.idleBattle()
    local value = battleTitle()
    return value:match("^WAVE %d+") ~= nil or value:match("^BOSS %d+") ~= nil
end
local function dungeonTypeOnPage()
    local hero = dungeonUI.hero()
    local title = hero and hero:FindFirstChild("Title", true)
    local value = visible(title) and textOf(title) or ""
    if value == "" then
        local root = page()
        if root then
            for _, obj in ipairs(root:GetDescendants()) do
                if visible(obj) and obj.Name == "Title" then
                    local candidate = textOf(obj)
                    local parent = obj.Parent
                    local isButton = false
                    while parent and parent ~= root do
                        if parent:IsA("GuiButton") then isButton = true; break end
                        parent = parent.Parent
                    end
                    if not isButton and (candidate:find("DEEP HALLS", 1, true)
                        or candidate:find("KEY CRYPT", 1, true)) then
                        value = candidate; break
                    end
                end
            end
        end
    end
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
    if dungeonSeen and dungeonUI.idleBattle() then
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
    local eligible = flags.dungeon and dungeonUI.idleBattle() and not dungeonStarted
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
    local endless = neonUI.farm.tab()
    if fire("dungeon.back", endless, nil, 3) then
        log("Dungeon return to battle requested")
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
        local deadline = os.clock() + 5
        repeat
            task.wait(0.25)
            if not valid("dungeon", version) then return end
        until dungeonTypeOnPage() or uiButton(page(), {["OPEN A PARTY"] = true,
            ["START SOLO"] = true, ["DEEP HALLS"] = true, ["KEY CRYPT"] = true})
            or os.clock() >= deadline
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
        local count, value = dungeonUI.tickets()
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
        local leave = uiButton(page(), {["LEAVE PARTY"] = true})
        if ready(leave) and buttonText(leave) == "LEAVE PARTY" then
            if fire("dungeon.leave", leave, "LEAVE PARTY", 3) then task.wait(1) end
        end
        if not valid("dungeon", version) then return end
        screen = page()
        local pick = child(screen, {"Pick", selectedDungeon})
            or uiButton(screen, {[dungeonName(selectedDungeon)] = true,
                ["THE " .. dungeonName(selectedDungeon)] = true})
        if ready(pick) then
            fire("dungeon.pick." .. selectedDungeon, pick, nil, 3)
            task.wait(1)
        end
        current = dungeonTypeOnPage()
        if current ~= selectedDungeon then
            -- If the other type is positively identified, run it rather than
            -- waiting forever for a selector that may be hidden in a party.
            if current then
                selectedDungeon = current
                log("Dungeon selector hidden; using visible " .. dungeonName(current))
            else
                nextDungeon = os.clock() + 30
                note("Dungeon type unreadable | " .. uiSummary(page()))
                returnToBattle()
                return
            end
        end
    end
    screen = page()
    local available, ticketValue = dungeonUI.tickets()
    if available == nil then
        nextDungeon = os.clock() + 10
        note(dungeonName(selectedDungeon) .. " tickets not readable | " .. uiSummary(screen))
        returnToBattle()
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
    log("Dungeon ready | " .. dungeonName(selectedDungeon) .. " | tickets=" .. ticketValue)
    noTicketsUntil[selectedDungeon] = 0
    local start = uiButton(screen, {["START SOLO"] = true})
    if not (ready(start) and buttonText(start) == "START SOLO") then
        local open = uiButton(screen, {["OPEN A PARTY"] = true})
        if not fire("dungeon.open", open, "OPEN A PARTY", 4) then
            nextDungeon = os.clock() + 10
            note("Dungeon party unavailable; retrying")
            return
        end
        task.wait(1)
    end
    if not valid("dungeon", version) then return end
    start = uiButton(page(), {["START SOLO"] = true})
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

function neonUI.draft.canStart()
    return dungeonUI.idleBattle() and not dungeonStarted and not inDungeon()
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
        neonUI.raidPriorityUntil = os.clock() + 60
        for key in pairs(versions) do
            if key ~= "raid" then versions[key] = versions[key] + 1 end
        end
        nextRaid = os.clock() + 8
        neonUI.nextArena = math.max(neonUI.nextArena or 0, os.clock() + 60)
        if neonUI.draft then
            neonUI.draft.engaged = false
            neonUI.draft.pending = nil
            neonUI.draft.nextCheck = os.clock() + 60
        end
        note("RAID JOIN pressed")
    end
end

-- Poll independently so waiting workers cannot delay a Raid notification.
task.spawn(function()
    while alive do
        if flags.raid then
            local ok, err = pcall(raidTick)
            if not ok then
                log("Raid priority check error: " .. tostring(err))
                task.wait(1)
            end
        end
        task.wait(0.1)
    end
end)

local expeditionIds = {"Epatrol", "Esupply", "Eruins", "Ewastes", "Estarfall"}
local sendLocked = {}
local function expRow(id)
    local root = modalPanel()
    return root and root:FindFirstChild(id, true)
end
local function expControl(row, name, label)
    local direct = row and row:FindFirstChild(name, true)
    if ready(direct) and buttonText(direct) == label then return direct end
    return uiButton(row, {[label] = true})
end
local function expClock(row)
    return row and row:FindFirstChild("Clock", true)
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
neonUI.expeditionSchedule = {lastBadge = 0}
function neonUI.expeditionSchedule.seconds(value)
    value = tostring(value or ""):upper():gsub("^%s+", ""):gsub("%s+$", "")
    local h, m, sec = value:match("^(%d+):(%d%d):(%d%d)$")
    if h then return tonumber(h) * 3600 + tonumber(m) * 60 + tonumber(sec), 2 end
    m, sec = value:match("^(%d+):(%d%d)$")
    if m then return tonumber(m) * 60 + tonumber(sec), 2 end
    local total, count, smallest = 0, 0, 3600
    for amount, unit in value:gmatch("(%d+)%s*([HMS])") do
        local scale = unit == "H" and 3600 or (unit == "M" and 60 or 1)
        total = total + tonumber(amount) * scale
        smallest = math.min(smallest, scale)
        count = count + 1
    end
    local remainder = value:gsub("%d+%s*[HMS]", ""):gsub("%s", "")
    if count > 0 and remainder == "" then return total, smallest == 1 and 2 or smallest end
end
function neonUI.expeditionSchedule.nextCheck(ids)
    local earliest
    for _, id in ipairs(ids) do
        local row = expRow(id)
        if expReady(expControl(row, "Recall", "RECALL"), "RECALL") then
            local clock = expClock(row)
            local seconds, margin = neonUI.expeditionSchedule.seconds(visible(clock) and textOf(clock) or "")
            if seconds then
                local due = os.clock() + seconds + margin
                earliest = earliest and math.min(earliest, due) or due
            end
        end
    end
    return earliest or math.huge
end

local function expeditionTick(version)
    if not valid("expedition", version) then return end
    if modalTitle() ~= "EXPEDITIONS" then
        if modalOpen() then return end
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
    local ids, seen = {}, {}
    for _, id in ipairs(expeditionIds) do
        if expRow(id) then table.insert(ids, id); seen[id] = true end
    end
    for _, obj in ipairs(modalPanel():GetDescendants()) do
        if obj.Name:match("^E%l") and not seen[obj.Name]
            and uiButton(obj, {["CLAIM"] = true, ["SEND AGAIN"] = true,
                ["SEND"] = true, ["RECALL"] = true}) then
            seen[obj.Name] = true; table.insert(ids, obj.Name)
        end
    end
    local observed, active = 0, 0
    for _, id in ipairs(ids) do
        if not valid("expedition", version) then return end
        local row = expRow(id)
        local claim = expControl(row, "Claim", "CLAIM")
        local again = expControl(row, "Again", "SEND AGAIN")
        local recall = expControl(row, "Recall", "RECALL")
        local clock = expClock(row)
        if claim or again or recall or uiButton(row, {["SEND"] = true}) then observed = observed + 1 end
        if expReady(recall, "RECALL") and visible(clock) then
            active = active + 1
            sendLocked[id] = nil
        elseif expReady(claim, "CLAIM") then
            sendLocked[id] = nil
            if fire("exp.claim." .. id, claim, "CLAIM", 3) then
                note(id .. " claimed")
                waitUntil(version, 6, function()
                    return expReady(expControl(expRow(id), "Again", "SEND AGAIN"), "SEND AGAIN")
                end)
            end
        end
        again = expControl(expRow(id), "Again", "SEND AGAIN")
            or expControl(expRow(id), "Send", "SEND")
        local sendLabel = again and buttonText(again)
        if not sendLocked[id] and again then
            -- Lock before dispatch: SEND AGAIN can remain visible for ~3s.
            sendLocked[id] = true
            if fire("exp.again." .. id, again, sendLabel, 6) then
                note(id .. " " .. sendLabel)
                local confirmed = waitUntil(version, 10, function()
                    local r = expRow(id)
                    local c = expClock(r)
                    return expReady(expControl(r, "Recall", "RECALL"), "RECALL")
                        and visible(c) and textOf(c) ~= ""
                end)
                if confirmed then
                    local clock = expClock(expRow(id))
                    log(id .. " dispatch confirmed: " .. textOf(clock))
                elseif valid("expedition", version) then
                    note(id .. " dispatch unconfirmed; locked against duplicate")
                end
            else
                sendLocked[id] = nil
            end
        end
    end
    if observed == 0 then
        note("Expeditions controls unreadable | " .. uiSummary(modalPanel()))
    else
        log("Expeditions checked | rows=" .. observed .. " | running=" .. active)
    end
    -- Read fresh clocks after all claims/dispatches; never reuse pre-dispatch time.
    nextExpedition = neonUI.expeditionSchedule.nextCheck(ids)
    neonUI.expeditionSchedule.lastBadge = expeditionBadgeCount()
    if nextExpedition < math.huge then
        log("Expeditions waiting for cooldown | next check in " .. math.ceil(nextExpedition - os.clock()) .. "s")
    else
        log("Expeditions timer unreadable or no running rows; waiting for a new ready badge")
    end
    if valid("expedition", version) then
        fire("exp.close", child(modalPanel(), {"Close"}), "X", 3)
    end
end

-- Guild paths verified by R49 GAME UI REPORT from 2026-11-19.
-- Week counters are guild statistics, not confirmed personal attack quota.
neonUI.guild = {nextCheck = 0, reports = {}}
function neonUI.guild.scroll()
    return child(page(), {"Scroll"})
end
function neonUI.guild.isPage()
    return visible(child(neonUI.guild.scroll(), {"Tabs", "war"}))
end
function neonUI.guild.isBoss()
    local title = child(neonUI.guild.scroll(), {"War", "Title"})
    return visible(title) and textOf(title) == "THE GUILD BOSS"
end
function neonUI.guild.fight()
    if not neonUI.guild.isBoss() then return nil end
    local button = child(neonUI.guild.scroll(), {"Fight"})
    return ready(button) and buttonText(button) == "FIGHT" and button or nil
end
function neonUI.guild.result()
    if modalTitle() ~= "GUILD BOSS" then return nil end
    local scroll = child(modalPanel(), {"Content", "Inner", "Scroll"})
    local done = child(scroll, {"Buttons", "Done"})
    local points = child(scroll, {"Points"})
    if visible(scroll) and visible(points) and textOf(points):find("DAMAGE TO THE GUILD BOSS", 1, true)
        and ready(done) and buttonText(done) == "NICE!" then return scroll end
end
function neonUI.guild.capture(reason)
    local ok, report = pcall(neonUI.captureGameUI)
    if ok then
        table.insert(neonUI.guild.reports, "GUILD BOSS | " .. reason .. "\n" .. report)
        if #neonUI.guild.reports > 4 then table.remove(neonUI.guild.reports, 1) end
    end
end
function neonUI.guild.wait(version, seconds, predicate)
    local deadline = os.clock() + seconds
    repeat
        if not valid("guildBoss", version) then return false end
        if predicate() then return true end
        task.wait(0.25)
    until os.clock() >= deadline
    return valid("guildBoss", version) and predicate()
end
function neonUI.guild.back(version)
    if not valid("guildBoss", version) or not neonUI.guild.isPage() then return end
    if fire("guild.back", neonUI.farm.tab(), nil, 2) then
        local returned = neonUI.guild.wait(version, 4, function()
            return not neonUI.guild.isPage() and neonUI.farm.active()
        end)
        if valid("guildBoss", version) then
            log(returned and "Guild Boss returned to battle"
                or "Guild Boss return unconfirmed; COPY LOG")
        end
    end
end
function neonUI.guild.finish(version)
    local guild = neonUI.guild
    if not valid("guildBoss", version) then return end
    local scroll = guild.result()
    if not scroll then return end
    local sub = child(scroll, {"Buttons", "Again", "Face", "Sub"})
    local remaining = visible(sub) and tonumber(textOf(sub):match("^(%d+)%s+LEFT TODAY$")) or nil
    local damage = textOf(child(scroll, {"Points"}))
    local reward = textOf(child(scroll, {"Headline"}))
    guild.capture("RESULT_CONFIRMED")
    log("Guild Boss result confirmed | " .. damage .. " | " .. reward
        .. " | leftToday=" .. tostring(remaining or "unreadable"))
    -- Close the verified result first; do not repeatedly press FIGHT AGAIN
    -- while the previous result remains visible or Raid cancels this worker.
    guild.nextCheck = math.huge
    if not valid("guildBoss", version) then return end
    if not fire("guild.result.done", child(scroll, {"Buttons", "Done"}), "NICE!", 2)
        or not guild.wait(version, 4, function() return not modalOpen() end) then
        if valid("guildBoss", version) then
            neonUI.guildHint.Text = "GUILD BOSS · Result close unconfirmed; retrying close only"
            note("Guild Boss result close unconfirmed; no new FIGHT sent")
        end
        return
    end
    if not valid("guildBoss", version) then return end
    guild.back(version)
    if not valid("guildBoss", version) then return end
    guild.nextCheck = os.clock() + (remaining and remaining > 0 and 1 or 300)
    neonUI.guildHint.Text = remaining and remaining > 0
        and ("GUILD BOSS · " .. remaining .. " left today; next round when idle")
        or "GUILD BOSS · No confirmed remaining attempts; check in 5 minutes"
end
function neonUI.guild.tick(version)
    local guild = neonUI.guild
    if not valid("guildBoss", version) then return end
    guild.nextCheck = os.clock() + 300
    neonUI.guildHint.Text = "GUILD BOSS · Checking Guild > WAR"
    if not guild.isPage() then
        if not fire("guild.open", get({"Frame", "Hud", "Utilguild"}), nil, 3) then
            note("Guild button unavailable; next check in 5 minutes")
            return
        end
        if not guild.wait(version, 5, guild.isPage) then
            if valid("guildBoss", version) then
                guild.capture("GUILD_PAGE_UNCONFIRMED")
                note("Guild page unconfirmed; COPY LOG")
            end
            return
        end
    end
    if not valid("guildBoss", version) then return end
    if not guild.isBoss() then
        if not fire("guild.war", child(guild.scroll(), {"Tabs", "war"}), "WAR", 3)
            or not guild.wait(version, 5, guild.isBoss) then
            if valid("guildBoss", version) then
                guild.capture("WAR_UNCONFIRMED")
                note("Guild Boss WAR page unconfirmed; COPY LOG")
                guild.back(version)
            end
            return
        end
    end
    if not valid("guildBoss", version) then return end
    local fight = guild.fight()
    if not fight then
        guild.capture("FIGHT_UNAVAILABLE")
        note("Guild Boss FIGHT unavailable; quota unverified; next check in 5 minutes")
        neonUI.guildHint.Text = "GUILD BOSS · FIGHT unavailable; retry in 5 minutes"
        guild.back(version)
        return
    end
    guild.capture("BEFORE_FIGHT")
    if not valid("guildBoss", version) then return end
    if not fire("guild.fight", fight, "FIGHT", 10) then return end
    note("Guild Boss FIGHT dispatched; waiting for page transition")
    if not guild.wait(version, 10, function() return not guild.isPage() end) then
        if valid("guildBoss", version) then
            guild.capture("START_UNCONFIRMED")
            guild.nextCheck = math.huge
            neonUI.guildHint.Text = "GUILD BOSS · Start unconfirmed. COPY LOG; toggle OFF/ON to retry."
            note("Guild Boss start unconfirmed; automatic retries paused; COPY LOG")
            guild.back(version)
        end
        return
    end
    if not valid("guildBoss", version) then return end
    guild.capture("AFTER_PAGE_TRANSITION")
    note("Guild Boss page changed; waiting for stable return; result not verified")
    neonUI.guildHint.Text = "GUILD BOSS · Waiting for return (result unverified)"
    local started, stable, deadline = os.clock(), nil, os.clock() + 180
    repeat
        task.wait(0.5)
        if not valid("guildBoss", version) then return end
        if guild.result() then
            guild.finish(version)
            return
        end
        local returned = not modalOpen() and (guild.isPage() or dungeonUI.idleBattle())
        if returned and os.clock() - started >= 5 then
            stable = stable or os.clock()
        else
            stable = nil
        end
        if stable and os.clock() - stable >= 3 then
            guild.capture("RETURN_OBSERVED_RESULT_UNVERIFIED")
            note("Guild Boss return observed; result not verified; next check in 5 minutes")
            neonUI.guildHint.Text = "GUILD BOSS · Return observed; check again in 5 minutes"
            guild.nextCheck = os.clock() + 300
            guild.back(version)
            return
        end
    until os.clock() >= deadline
    guild.capture("RETURN_TIMEOUT")
    guild.nextCheck = math.huge
    neonUI.guildHint.Text = "GUILD BOSS · Return timeout. COPY LOG; toggle OFF/ON to retry."
    note("Guild Boss return timeout; automatic retries paused; COPY LOG")
end

-- Turkey Trot navigation and active WAVE label verified by R53 UI report.
neonUI.trot = {nextCheck = 0, observed = false, report = nil}
function neonUI.trot.active()
    local label = get({"Frame", "Nav", "Row", "trot", "Label"})
    local wave = visible(label) and textOf(label):match("^WAVE (%d+)$")
    local battleWave = battleTitle():match("^WAVE (%d+)")
    return wave ~= nil and wave == battleWave and visible(get({"Frame", "Battle"}))
        and not visible(page())
end
function neonUI.trot.capture(reason)
    local ok, report = pcall(neonUI.captureGameUI)
    if ok then neonUI.trot.report = "FARM MODE " .. neonUI.farm.name() .. " | " .. reason .. "\n" .. report end
end
function neonUI.trot.tick(version)
    local trot = neonUI.trot
    if not valid("turkeyTrot", version) then return end
    trot.nextCheck = os.clock() + 5
    if not neonUI.farm.active() and not dungeonUI.idleBattle() then return end
    if not neonUI.farm.active() then
        trot.observed = false
        local tab = neonUI.farm.tab()
        local label = child(tab, {"Label"})
        local value = visible(label) and textOf(label) or ""
        local expected = neonUI.farm.name()
        if not ready(tab) or (value ~= expected and not value:match("^WAVE %d+$")
            and not value:match("^BOSS %d+$")) then
            trot.nextCheck = os.clock() + 60
            neonUI.trotHint.Text = expected .. " · Selected tab unavailable; no mode fallback"
            note(expected .. " tab unavailable; keeping selected farm mode")
            return
        end
        if not fire("farm.tab", tab, nil, 5) then return end
        local deadline = os.clock() + 6
        repeat
            task.wait(0.25)
            if not valid("turkeyTrot", version) then return end
        until neonUI.farm.active() or modalOpen() or os.clock() >= deadline
        if not neonUI.farm.active() then
            trot.nextCheck = math.huge
            trot.capture("SELECTED_FARM_ENTRY_UNCONFIRMED")
            neonUI.trotHint.Text = expected .. " · Entry unconfirmed; COPY LOG. No mode fallback."
            note(expected .. " entry unconfirmed; retries paused; COPY LOG")
            return
        end
    end
    if not valid("turkeyTrot", version) then return end
    if not trot.observed then
        trot.observed = true
        note("Selected farm active: " .. neonUI.farm.name() .. " | " .. battleTitle())
    end
    neonUI.trotHint.Text = neonUI.farm.name() .. " · " .. battleTitle()
    local auto = get({"Frame", "Battle", "Dock", "Auto"})
    local autoState = child(auto, {"Face", "Sub"})
    if visible(autoState) and textOf(autoState) == "OFF" then
        fire("farm.auto", auto, "AUTO", 5)
    end
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
    neonUI.storage.Text = "Settings storage: " .. settingsStorage .. " | Dungeon recheck: 2 hours"
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
    put("runtime", string.format("%dm %02ds · %s", math.floor((now - startedAt) / 60),
        math.floor(now - startedAt) % 60, busy and "Working" or "Waiting"))
    local enabled = {}
    for _, key in ipairs(settingKeys) do
        if flags[key] then table.insert(enabled, titles[key]) end
    end
    put("switches", #enabled > 0 and table.concat(enabled, " · ") or "All OFF")
    put("storage", settingsStorage == "file" and "File · restores across restarts" or "Session only")
end

function neonUI.dismissDaily(now)
    local title = modalTitle()
    local daily = {["DAILY REWARDS"]=true, ["DAILY REWARD"]=true, ["DAILY LOGIN"]=true, ["DAILY LOGIN REWARDS"]=true}
    if not daily[title] or now < (neonUI.nextDailyClose or 0) then return end
    neonUI.nextDailyClose = now + 10
    if fire("daily.close", child(modalPanel(), {"Close"}), "X", 1) then log("Daily popup close requested") end
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
log("Combined V1.2 R61 Neon V2 ready | restored from " .. (settingsSource or "defaults")
    .. " | saving to " .. settingsStorage .. " | ON: "
    .. (#enabledNames > 0 and table.concat(enabledNames, ", ") or "none"))
boot.ready = true
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
            if now < (neonUI.raidPriorityUntil or 0) then return end
            if not busy then neonUI.dismissDaily(now) end
            local blockingDungeonResult = recoverDungeonModal(now)
            if not busy and flags.raid and not modalOpen() and now >= nextRaid then
                raidTick()
            end
            if flags.feastDraft and (neonUI.draft.engaged or neonUI.draft.page() or neonUI.draft.modal()) then
                if not busy and now >= neonUI.draft.nextCheck then run("feastDraft", neonUI.draft.tick) end
                return
            end
            if not busy and flags.feastDraft and not dungeonStarted and not inDungeon()
                and not modalOpen() and now >= neonUI.draft.nextCheck and dungeonUI.idleBattle() then
                run("feastDraft", neonUI.draft.tick)
            end
            if not busy and flags.guildBoss and neonUI.guild.result() then
                -- Also recover a result left open by an older script or Raid.
                run("guildBoss", neonUI.guild.finish)
            elseif not busy and flags.guildBoss and not dungeonStarted and not inDungeon()
                and not modalOpen() and now >= neonUI.guild.nextCheck
                and (dungeonUI.idleBattle() or neonUI.guild.isPage()) then
                run("guildBoss", neonUI.guild.tick)
            end
            -- Give a due Dungeon one turn before Arena immediately repeats.
            -- Raid retains its independent preemption and priority hold.
            if not busy and flags.dungeon and not dungeonStarted and
                not inDungeon() and not modalOpen() and now >= nextDungeon then
                local screen = page()
                if dungeonUI.idleBattle() or dungeonTypeOnPage()
                    or (screen and screen:FindFirstChild("Pick", true)) then
                    log("Dungeon scheduled | target=" .. dungeonName(selectedDungeon))
                    run("dungeon", runDungeon)
                end
            end
            if not busy and flags.arena and not dungeonStarted and not inDungeon() and not modalOpen()
                and now >= (neonUI.nextArena or 0) then
                neonUI.nextArena = now + 3600
                run("arena", function(version)
                    local function arenaPage()
                        local screen = page()
                        if not visible(screen) then return false end
                        for _, item in ipairs(screen:GetDescendants()) do
                            if visible(item) and (textOf(item) == "FIND OPPONENTS"
                                or textOf(item) == "ARENA") then return true end
                        end
                        return false
                    end
                    if not arenaPage() then
                        if not waveBattle() then
                            neonUI.nextArena = 0
                            return
                        end
                        if not fire("arena.tab", get({"Frame","Nav","Row","arena"}), "ARENA") then return end
                    end
                    local function returnToBattle()
                        local untilTime = os.clock() + 4
                        repeat
                            fire("arena.back", neonUI.farm.tab(), nil, 1)
                            task.wait(0.25)
                            if neonUI.farm.active() and not arenaPage() then
                                note("Arena returned to battle")
                                return
                            end
                        until not valid("arena", version) or os.clock() >= untilTime
                        note("Arena return not confirmed within 10s")
                    end
                    local function quotaEmpty(screen)
                        for _, item in ipairs(screen:GetDescendants()) do
                            if visible(item) then
                                local value = textOf(item)
                                local path = item:GetFullName():lower()
                                local relevant = path:find("ticket", 1, true) or path:find("attempt", 1, true)
                                    or path:find("quota", 1, true) or value:find("TICKET", 1, true)
                                    or value:find("ATTEMPT", 1, true) or value:find("FIGHT", 1, true)
                                if value == "NO TICKETS" or value == "NO ATTEMPTS LEFT"
                                    or value == "NO FIGHTS LEFT" or value == "DAILY LIMIT REACHED"
                                    or (relevant and value:match("^0%s*/%s*%d+"))
                                    or (relevant and value:match("%f[%d]0%s+LEFT")) then
                                    return true
                                end
                            end
                        end
                        return false
                    end
                    local labels = {}
                    local opponentsRequested = false
                    local deadline = os.clock() + 5
                    repeat
                        task.wait(0.25)
                        if not valid("arena", version) or modalOpen() then return end
                        local screen = get({"Frame","Page","Column","Screen"})
                        local confirmed = false
                        if visible(screen) then
                            local findButton
                            for _, item in ipairs(screen:GetDescendants()) do
                                if ready(item) and buttonText(item) == "FIND OPPONENTS" then
                                    findButton = item
                                    break
                                end
                            end
                            if not findButton and quotaEmpty(screen) then
                                neonUI.nextArena = os.clock() + 3600
                                note("Arena quota empty; next check in 1h")
                                returnToBattle()
                                return
                            end
                            for _, item in ipairs(screen:GetDescendants()) do
                                if visible(item) and textOf(item):find("ARENA", 1, true) then confirmed = true break end
                            end
                            if findButton and not opponentsRequested then
                                if fire("arena.find", findButton, "FIND OPPONENTS", 10) then
                                    opponentsRequested = true
                                    neonUI.nextArena = os.clock()
                                    deadline = os.clock() + 12
                                    note("Arena finding opponents; waiting for FIGHT")
                                end
                            end
                            for _, item in ipairs(screen:GetDescendants()) do
                                if ready(item) then
                                    local name = buttonText(item)
                                    if name ~= "" then labels[name] = true end
                                    if (confirmed or opponentsRequested) and (name == "FIGHT" or name == "BATTLE" or name == "CHALLENGE"
                                        or name == "JOIN" or name == "START" or name == "FIGHT AGAIN") then
                                        if fire("arena.fight", item, name) then
                                            neonUI.nextArena = os.clock()
                                            note("Arena quota available; next check when idle")
                                            note("Arena FIGHT dispatched; waiting for battle")
                                            local startDeadline = os.clock() + 10
                                            local started = false
                                            repeat
                                                task.wait(0.25)
                                                if not valid("arena", version) then return end
                                                started = not visible(page()) or modalOpen()
                                            until started or os.clock() >= startDeadline
                                            if not started then
                                                note("Arena start unconfirmed; fight page remained visible")
                                                return
                                            end
                                            note("Arena page changed; waiting for return")
                                            local battleStartedAt = os.clock()
                                            local returnSince
                                            local finishDeadline = os.clock() + 120
                                            repeat
                                                task.wait(0.5)
                                                if not valid("arena", version) then return end
                                                local returned = not modalOpen() and (arenaPage() or waveBattle())
                                                if returned and os.clock() - battleStartedAt >= 5 then
                                                    returnSince = returnSince or os.clock()
                                                else
                                                    returnSince = nil
                                                end
                                                if returnSince and os.clock() - returnSince >= 3 then
                                                    note("Arena return stable for 3s; result not verified")
                                                    if arenaPage() then returnToBattle() end
                                                    neonUI.nextArena = os.clock()
                                                    return
                                                end
                                            until os.clock() >= finishDeadline
                                            note("Arena return timeout; retry after 1 minute")
                                            neonUI.nextArena = os.clock() + 60
                                            return
                                        end
                                    end
                                end
                            end
                        end
                    until os.clock() >= deadline
                    local found = {}
                    for name in pairs(labels) do table.insert(found, name) end
                    table.sort(found)
                    note("Arena: no confirmed fight button. Visible buttons: " .. table.concat(found, ", "))
                    neonUI.nextArena = os.clock() + 3600
                    returnToBattle()
                end)
            end
            if not busy and flags.level and not modalOpen() and now >= nextLevel then
                run("level", levelTick)
            end
            if not busy and flags.expedition and not blockingDungeonResult
                and (now >= nextExpedition or (nextExpedition == math.huge
                    and expeditionBadgeCount() > neonUI.expeditionSchedule.lastBadge)) then
                if modalTitle() == "EXPEDITIONS" or not modalOpen() then
                    run("expedition", expeditionTick)
                else
                    nextExpedition = now + 8
                end
            end
            if not busy and flags.turkeyTrot and not dungeonStarted and not inDungeon()
                and not modalOpen() and not visible(page()) and now >= neonUI.trot.nextCheck
                and (dungeonUI.idleBattle() or neonUI.farm.active()) then
                run("turkeyTrot", neonUI.trot.tick)
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
if startupOk and not boot.ready then
    startupOk, startupError = false, "Startup stopped before UI was ready; phase=" .. boot.phase
end
if boot.gui then boot.gui:Destroy() end
if startupOk then
    local player = game:GetService("Players").LocalPlayer
    local pg = player and player:FindFirstChild("PlayerGui")
    local mainUI = pg and pg:FindFirstChild("RollStickman_Combined_V1_2")
    if mainUI then mainUI:SetAttribute("StartupReady", true) end
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
