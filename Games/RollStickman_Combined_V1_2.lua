-- Roll A Stickman Combined Auto V1.2 R40
-- UI-driven automation for PlaceId 115068315659966.
-- Run once in Potassium. Requires executor firesignal for GuiButton.Activated.
-- Auto Execute: add this complete file to your executor's Auto Execute list.
-- Waiting for game/player/UI readiness is handled below; no remote loader needed.

local startupOk, startupError = xpcall(function()

print("[RAS] R40 starting; waiting for game to load")
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
local settingKeys = {"level", "raid", "arena", "dungeon", "expedition", "moon", "cards", "pet", "antiAfk"}
local potionNames = {luck = "Luck Potion", haste = "Haste Potion", gild = "Gilded Potion"}
-- These seven names are confirmed by the user's in-game MOONS screenshot.
local potionConfig = {when = "Aurora", moons = {AURORA = true}, cardMoons = {AURORA = true}, petLuckMoons = {AURORA = true}, petPlayEveryMinutes = 5, petPlayEnabled = true, moonInspectMinutes = 5, moonHudOnly = false, webhookEnabled = false, webhookUrl = "", available = {"Normal", "Silver", "Harvest", "Blue", "Eclipse", "Starfall", "Aurora"}, multipliers = {NORMAL = 1, SILVER = 1.5, AURORA = 12}, selected = {luck = true, haste = true, gild = true}}
local cardSelection = {stopBelow = 0, loose = true, pouch = true, crate = true, chest = true, requireLuck = true, requirePet = true}
local function minutes(value, fallback)
    local number = tonumber(value)
    if not number or number ~= number or number == math.huge or number == -math.huge then return fallback end
    return math.clamp(math.floor(number), 1, 120)
end
local function validWebhook(value)
    if type(value) ~= "string" then return "" end
    local url = value:match("^%s*(.-)%s*$")
    if #url > 512 then return "" end
    if url:match("^https://discord%.com/api/webhooks/%d+/[%w_%-]+$")
        or url:match("^https://discord%.com/api/v%d+/webhooks/%d+/[%w_%-]+$")
        or url:match("^https://discordapp%.com/api/webhooks/%d+/[%w_%-]+$") then return url end
    return ""
end
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
local function moonSet(value, fallback)
    local result = {}
    for key, selected in pairs(type(value) == "table" and value or fallback) do
        local name = moonIdentity(key, true)
        if name and selected == true then result[name] = true end
    end
    return result
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
    if from.cards == nil then cleaned.cards = from.moon == true end
    local p = value.position
    local position = type(p) == "table" and type(p.x) == "number"
        and type(p.y) == "number" and {x = p.x, y = p.y} or nil
    local tab = value.activeTab
    if tab ~= "Team" and tab ~= "Fight" and tab ~= "Potion" and tab ~= "Pet" and tab ~= "Open Card" and tab ~= "Status" and tab ~= "Moon" and tab ~= "Settings" then
        tab = "Fight"
    end
    local source = type(value.potion) == "table" and value.potion or {}
    local selections = type(source.selected) == "table" and source.selected or {}
    local potion = {when = moonCaption(moonIdentity(source.when, true) or "AURORA"), available = {"Normal", "Silver", "Harvest", "Blue", "Eclipse", "Starfall", "Aurora"}, multipliers = {NORMAL = 1, SILVER = 1.5, AURORA = 12}, selected = {}}
    potion.petCatalog = {}
    for id, record in pairs(type(source.petCatalog) == "table" and source.petCatalog or {}) do
        if type(id) == "string" and id:match("^[%w_]+:%d+$") and type(record) == "table"
            and type(record.name) == "string" and type(record.level) == "string"
            and type(record.luck) == "number" and record.luck >= 0 and record.luck < math.huge
            and type(record.play) == "number" and record.play >= 0 and record.play < math.huge then
            potion.petCatalog[id] = {name = record.name, level = record.level, luck = record.luck, play = record.play, gives = tostring(record.gives or "")}
        end
    end
    potion.moons = moonSet(source.moons, {[moonIdentity(potion.when, true)] = true})
    potion.cardMoons = moonSet(source.cardMoons, potion.moons)
    potion.petLuckMoons = moonSet(source.petLuckMoons, {AURORA = true})
    potion.petPlayEveryMinutes = minutes(source.petPlayEveryMinutes, 5)
    potion.petPlayEnabled = source.petPlayEnabled ~= false
    if source.petPlayEnabled == nil and type(source.petPlayMoons) == "table" then
        potion.petPlayEnabled = next(moonSet(source.petPlayMoons, {})) ~= nil
    end
    potion.moonInspectMinutes = minutes(source.moonInspectMinutes, 5)
    potion.moonHudOnly = false
    potion.webhookUrl = validWebhook(source.webhookUrl)
    potion.webhookEnabled = source.webhookEnabled == true and potion.webhookUrl ~= ""
    for name, amount in pairs(type(source.multipliers) == "table" and source.multipliers or {}) do
        local key = moonIdentity(name, true)
        if key and type(amount) == "number" and amount > 0 and amount < math.huge then
            potion.multipliers[key] = amount
        end
    end
    local known = {NORMAL = true, SILVER = true, HARVEST = true, BLUE = true, ECLIPSE = true, STARFALL = true, AURORA = true}
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
    local cardSource = type(value.openCard) == "table" and value.openCard or {}
    local cards = {}
    for _, id in ipairs({"loose", "pouch", "crate", "chest"}) do cards[id] = cardSource[id] ~= false end
    cards.requireLuck = cardSource.requireLuck ~= false
    cards.requirePet = cardSource.requirePet ~= false
    local threshold = tonumber(cardSource.stopBelow)
    cards.stopBelow = threshold and threshold == threshold and threshold >= 0 and threshold < math.huge
        and math.floor(threshold) or 0
    return cleaned, position, tab, potion, cards
end
local function readSettings()
    if type(readfile) == "function" then
        local ok, content = pcall(readfile, SETTINGS_FILE)
        if ok and type(content) == "string" then
            local valid, decoded = pcall(function()
                return HttpService:JSONDecode(content)
            end)
            if valid then
                local saved, position, tab, potion, cards = cleanSettings(decoded)
                if saved then return saved, "file", position, tab, potion, cards end
            end
        end
    end
    local env = settingsEnv()
    local saved, position, tab, potion, cards
    if type(env) == "table" then
        saved, position, tab, potion, cards = cleanSettings(env[SETTINGS_KEY])
    end
    return saved, saved and "session" or nil, position, tab, potion, cards
end
local settingsPosition
local settingsTab = "Fight"
local function writeSettings(current)
    local saved = {placeId = game.PlaceId, flags = {}, activeTab = settingsTab}
    saved.potion = {when = potionConfig.when, available = {}, multipliers = {}, selected = {}}
    saved.potion.petCatalog = {}
    for id, record in pairs(potionConfig.petCatalog or {}) do
        saved.potion.petCatalog[id] = {name = record.name, level = record.level, luck = record.luck, play = record.play, gives = record.gives}
    end
    saved.potion.petPlayEveryMinutes = potionConfig.petPlayEveryMinutes
    saved.potion.petPlayEnabled = potionConfig.petPlayEnabled
    saved.potion.moonInspectMinutes = potionConfig.moonInspectMinutes
    saved.potion.moonHudOnly = potionConfig.moonHudOnly
    saved.potion.webhookUrl = validWebhook(potionConfig.webhookUrl)
    saved.potion.webhookEnabled = potionConfig.webhookEnabled
    for _, field in ipairs({"moons", "cardMoons", "petLuckMoons"}) do
        saved.potion[field] = moonSet(potionConfig[field], {})
    end
    for key, amount in pairs(potionConfig.multipliers) do saved.potion.multipliers[key] = amount end
    saved.openCard = {}
    for key, selected in pairs(cardSelection) do saved.openCard[key] = selected end
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
    local names = {level = "LevelToggle", raid = "RaidToggle", arena = "ArenaToggle",
        dungeon = "DungeonToggle", expedition = "ExpeditionToggle",
        moon = "MoonToggle", cards = "CardToggle", pet = "PetToggle", antiAfk = "AntiAfkToggle"}
    for key, name in pairs(names) do
        local storedFlag = previous:GetAttribute("Flag_" .. key)
        if type(storedFlag) == "boolean" then previousFlags[key] = storedFlag end
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
local title = label("Title", "ROLL A STICKMAN  |  R40  ·  NEON V2", 12, 32)
title.Size = UDim2.fromOffset(550, 32)
title.TextSize = 17
title.Active = true
local minimizeUI = button("Minimize", "-", 589, 14, 28, 28)
local closeUI = button("Close", "X", 626, 14, 28, 28)
local tabPages = {Team = {}, Fight = {}, Potion = {}, Pet = {}, ["Open Card"] = {}, Status = {}, Moon = {}, Settings = {}}
local tabButtons = {}
local activeTab = "Status"
neonUI.nav = Instance.new("ScrollingFrame")
neonUI.nav.Name = "Navigation"
neonUI.nav.Position = UDim2.fromOffset(12, 62)
neonUI.nav.Size = UDim2.fromOffset(145, 333)
neonUI.nav.BackgroundColor3 = theme.surface
neonUI.nav.BorderSizePixel = 0
neonUI.nav.ScrollBarThickness = 3
neonUI.nav.CanvasSize = UDim2.fromOffset(0, 344)
neonUI.nav.Parent = panel
neonUI.navRound = Instance.new("UICorner")
neonUI.navRound.CornerRadius = UDim.new(0, 9)
neonUI.navRound.Parent = neonUI.nav
neonUI.icons = {Status = "◉", Team = "♟", Fight = "⚔", Potion = "✦", Pet = "◆", ["Open Card"] = "▣", Moon = "☾", Settings = "⚙"}
for i, tab in ipairs({"Status", "Team", "Fight", "Potion", "Pet", "Open Card", "Moon", "Settings"}) do
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
function neonUI.minuteControls(tab, prefix, y)
    local control = {}
    control.minus = pageItem(tab, button(prefix .. "Minus", "-", 12, y, 38, 28))
    control.plus = pageItem(tab, button(prefix .. "Plus", "+", 310, y, 38, 28))
    control.box = Instance.new("TextBox")
    control.box.Name = prefix .. "Minutes"
    control.box.Position = UDim2.fromOffset(56, y)
    control.box.Size = UDim2.fromOffset(248, 28)
    control.box.BackgroundColor3 = theme.card
    control.box.TextColor3 = theme.text
    control.box.Font = Enum.Font.GothamMedium
    control.box.TextSize = 13
    control.box.BorderSizePixel = 0
    control.box.ClearTextOnFocus = false
    pageItem(tab, control.box)
    return control
end
local toggles = {
    level = pageItem("Team", button("LevelToggle", "LEVEL UP: OFF", 12, 116, 336, 36)),
    arena = pageItem("Fight", button("ArenaToggle", "ARENA: OFF", 12, 344, 336, 36)),
    raid = pageItem("Fight", button("RaidToggle", "RAID: OFF", 12, 116, 336, 36)),
    dungeon = pageItem("Fight", button("DungeonToggle", "DUNGEON: OFF", 12, 158, 336, 36)),
    expedition = pageItem("Fight", button("ExpeditionToggle", "EXPEDITIONS: OFF", 12, 200, 336, 36)),
    moon = pageItem("Potion", button("MoonToggle", "USE POTION: OFF", 12, 116, 336, 30)),
    cards = pageItem("Open Card", button("CardToggle", "AUTO OPEN CARD: OFF", 12, 116, 336, 30)),
    pet = pageItem("Pet", button("PetToggle", "AUTO PET: OFF", 12, 116, 336, 30)),
    antiAfk = pageItem("Settings", button("AntiAfkToggle", "ANTI AFK: ON", 12, 116, 336, 36)),
}
pageLabel("Team", "TeamHeading", "TEAM  /  UPGRADES", 90, 20)
pageLabel("Team", "TeamHint", "LEVEL UP uses LEVEL UP ALL when that game button is visible. Open the team upgrade page to use it.", 165, 70)
pageLabel("Fight", "FightHeading", "FIGHT  /  AUTOMATION", 90, 20)
pageLabel("Fight", "DungeonMode", "DUNGEON · ALL TYPES\nNo tickets: check again after 2 hours.", 245, 42)
local dungeonSchedule = pageLabel("Fight", "DungeonSchedule", "Dungeon check: ready", 300, 38)
pageLabel("Potion", "PotionHeading", "POTION  /  CONDITIONS", 90, 20)
local potionUI = {checks = {}, scanRequested = false, entries = {}, iconMap = {}, iconConflicts = {}, probeAt = 0}
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
potionUI.option.BackgroundColor3 = theme.card
potionUI.option.Visible = false
potionUI.primary = {field = "moons", tab = "Potion", button = potionUI.dropdown, list = potionUI.option, entries = {}, maxHeight = 223}
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
pageLabel("Potion", "PotionHint", "x? = press SYNC to read the Moon luck multiplier.", 328, 20).TextSize = 10
pageLabel("Open Card", "CardHeading", "OPEN CARD  /  OWNED ITEMS", 90, 20)
local cardUI = {checks = {}, openReports = {}, names = {loose = "Reward Cards", pouch = "Pouch", crate = "Crate", chest = "Chest"}}
cardUI.condition = pageItem("Open Card", button("CardWhen", "Open Card When: Aurora   v", 12, 152, 336, 30))
cardUI.option = Instance.new("ScrollingFrame")
cardUI.option.Name = "CardWhenList"
cardUI.option.Position = UDim2.fromOffset(12, 184)
cardUI.option.Size = UDim2.fromOffset(336, 158)
cardUI.option.BackgroundColor3 = theme.card
cardUI.option.BorderSizePixel = 0
cardUI.option.ScrollBarThickness = 5
cardUI.option.CanvasSize = UDim2.new()
cardUI.option.ZIndex = 30
cardUI.option.Visible = false
pageItem("Open Card", cardUI.option)
cardUI.primary = {field = "cardMoons", tab = "Open Card", button = cardUI.condition, list = cardUI.option, entries = {}, maxHeight = 223}
cardUI.stock = pageLabel("Open Card", "CardStock", "Reward Cards: not observed", 188, 28)
cardUI.stock.TextSize = 11
cardUI.requireLuck = pageItem("Open Card", button("CardRequireLuck", "[x] Require active Luck Potion", 12, 222, 336, 24))
cardUI.requirePet = pageItem("Open Card", button("CardRequirePet", "[x] Require active Pet Luck", 12, 250, 336, 24))
for i, id in ipairs({"loose", "pouch", "crate", "chest"}) do
    cardUI.checks[id] = pageItem("Open Card", button("CardCheck" .. id,
        "[x]  " .. cardUI.names[id], 12 + ((i - 1) % 2) * 172, 282 + math.floor((i - 1) / 2) * 28, 164, 24))
    cardUI.checks[id].TextXAlignment = Enum.TextXAlignment.Left
end
pageLabel("Open Card", "CardHint", "Uses its own Moon selection. Opens owned items only.", 342, 22).TextSize = 10
pageLabel("Open Card", "StopBelowLabel", "Stop when Rolls less than (Reward Cards; 0 = off)", 370, 22)
cardUI.stopBelow = Instance.new("TextBox")
cardUI.stopBelow.Name = "StopBelow"
cardUI.stopBelow.Position = UDim2.fromOffset(12, 396)
cardUI.stopBelow.Size = UDim2.fromOffset(336, 28)
cardUI.stopBelow.BackgroundColor3 = theme.card
cardUI.stopBelow.TextColor3 = theme.text
cardUI.stopBelow.TextSize = 14
cardUI.stopBelow.ClearTextOnFocus = false
pageItem("Open Card", cardUI.stopBelow)
local petUI = {targets = {}, nextCheck = 0, scanRequested = false, catalog = {}, nextPlayAt = 0}
pageLabel("Pet", "PetHeading", "PET  /  BOOST CONDITIONS", 90, 20)
pageLabel("Pet", "PetLuckLabel", "Pet Luck before cards; restore after cards", 151, 18)

for _, spec in ipairs({{"petLuckMoons", "PetLuckWhen", 171, 201}}) do
    local target = {field = spec[1], tab = "Pet", entries = {}, maxHeight = spec[1] == "petLuckMoons" and 143 or 91}
    target.button = pageItem("Pet", button(spec[2], "Select Moons...", 12, spec[3], 336, 30))
    target.list = Instance.new("ScrollingFrame")
    target.list.Name = spec[2] .. "List"
    target.list.Position = UDim2.fromOffset(12, spec[4])
    target.list.Size = UDim2.fromOffset(336, target.maxHeight)
    target.list.BackgroundColor3 = theme.card
    target.list.BorderSizePixel = 0
    target.list.ScrollBarThickness = 5
    target.list.CanvasSize = UDim2.new()
    target.list.ZIndex = 30
    target.list.Visible = false
    target.list.Parent = panel
    pageItem("Pet", target.list)
    table.insert(petUI.targets, target)
end
petUI.playToggle = pageItem("Pet", button("PetPlayToggle", "[x] Boost cards from play", 12, 203, 336, 22))
pageLabel("Pet", "PetPlayLabel", "Automatic timer disabled", 228, 18)
petUI.every = neonUI.minuteControls("Pet", "PetPlay", 250)
for _, control in pairs(petUI.every) do
    if typeof(control) == "Instance" and control:IsA("GuiObject") then control.Visible = false end
end
for _, target in ipairs(petUI.targets) do target.button.Visible = false end
petUI.schedule = pageLabel("Pet", "PetPlaySchedule", "Next play pet check: ready", 281, 20)
petUI.help = pageLabel("Pet", "PetHelp", "Selected Moon: Potion > Luck Pet > eligible cards > restore previous pets > battle. AUTO PET must be ON.", 305, 37)
petUI.help.TextSize = 11
petUI.scan = pageItem("Pet", button("ScanPet", "SCAN PET STATS", 12, 349, 164, 32))
petUI.capture = pageItem("Pet", button("CapturePet", "CAPTURE (3s)", 184, 349, 164, 32))
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
    {"aura", "AURA · LAST CONFIRMED"}, {"moonTimer", "SKY COUNTDOWN"},
    {"power", "TEAM POWER"}, {"battle", "BATTLE / STAGE"},
    {"rolls", "TOTAL ROLLS"}, {"autoRoll", "AUTO ROLL"},
    {"dungeon", "DUNGEON / TICKETS"}, {"nextDungeon", "NEXT DUNGEON CHECK"},
    {"expedition", "EXPEDITIONS READY"}, {"cards", "REWARD CARDS"},
    {"luckPotion", "LUCK POTION"}, {"hastePotion", "HASTE POTION"},
    {"gildPotion", "GILDED POTION"}, {"petLuck", "EQUIPPED PET BONUSES"}, {"runtime", "SESSION / SCHEDULER"},
    {"switches", "ENABLED SYSTEMS"}, {"storage", "SETTINGS STORAGE"},
}) do statusRow(spec[1], spec[2]) end
pageLabel("Moon", "MoonHeading", "MOON  /  VERIFIED SKY", 90, 24)
neonUI.sky = pageLabel("Moon", "MoonSky", "No confirmed Moon yet. Press SYNC to inspect.", 126, 58)
neonUI.sky.TextSize = 16
neonUI.sky.TextColor3 = theme.text
neonUI.timer = pageLabel("Moon", "MoonTimer", "Sky countdown: not observed", 185, 22)
neonUI.tracker = pageLabel("Moon", "MoonTracking", "COUNTDOWN TRACKING: unknown / expired Moon is inspected automatically", 211, 28)
pageLabel("Moon", "MoonIntervalLabel", "Retry after a failed Moon read: minutes (1-120)", 244, 18)
neonUI.moonEvery = neonUI.minuteControls("Moon", "MoonInspect", 267)
neonUI.moonSync = pageItem("Moon", button("MoonSync", "SYNC MOON NOW", 12, 306, 336, 30))
neonUI.moonPolicy = pageLabel("Moon", "MoonPolicy", "Reads the active Moon and remaining time once. Checks again when that time expires or the HUD icon changes.", 343, 61)
pageLabel("Settings", "SettingsHeading", "SETTINGS  /  SESSION & LOG", 90, 20)
pageLabel("Settings", "SettingsHint", "Switches, Moon choices and window position save automatically. Alt minimizes this window. RESTORE SWITCHES restores the last STOP ALL selection.", 158, 60)
neonUI.storage = pageLabel("Settings", "StorageInfo", "Settings storage: starting", 225, 24)
neonUI.webhook = {queue = {}, running = false, nextSendAt = 0}
neonUI.webhook.toggle = pageItem("Settings", button("WebhookEnabled", "[ ] Discord webhook: card opens", 12, 258, 336, 28))
neonUI.webhook.url = Instance.new("TextBox")
neonUI.webhook.url.Name = "WebhookUrl"
neonUI.webhook.url.Position = UDim2.fromOffset(12, 294)
neonUI.webhook.url.Size = UDim2.fromOffset(336, 32)
neonUI.webhook.url.BackgroundColor3 = theme.card
neonUI.webhook.url.TextColor3 = theme.text
neonUI.webhook.url.PlaceholderText = "Paste Discord webhook URL here"
neonUI.webhook.url.Text = ""
neonUI.webhook.url.TextSize = 11
neonUI.webhook.url.Font = Enum.Font.Code
neonUI.webhook.url.ClearTextOnFocus = false
neonUI.webhook.url.BorderSizePixel = 0
pageItem("Settings", neonUI.webhook.url)
neonUI.webhook.test = pageItem("Settings", button("WebhookTest", "TEST WEBHOOK", 12, 334, 336, 28))
neonUI.webhook.status = pageLabel("Settings", "WebhookStatus", "Webhook: OFF", 369, 28)
local copyButton = pageItem("Settings", button("CopyLog", "COPY LOG / PET REPORT", 12, 409, 336, 32))
local logHeader = pageLabel("Settings", "LogHeader", "ACTIVITY LOG", 453, 20)
local scroll = Instance.new("ScrollingFrame")
scroll.Name = "ActivityLog"
scroll.Position = UDim2.fromOffset(12, 481)
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
local alive = true
local minimized = false
local savedFlags, settingsSource, savedPosition, savedTab, savedPotion, savedCards = readSettings()
if savedPotion then potionConfig = savedPotion end
potionConfig.petCatalog = potionConfig.petCatalog or {}
petUI.catalog = potionConfig.petCatalog
if savedCards then cardSelection = savedCards end
if not savedFlags and next(previousFlags) then
    savedFlags, settingsSource = previousFlags, "previous UI"
end
local flags = {}
for _, key in ipairs(settingKeys) do
    flags[key] = savedFlags and savedFlags[key] == true or false
end
if not savedFlags or savedFlags.antiAfk == nil then flags.antiAfk = true end
if savedFlags and savedFlags.cards == nil then flags.cards = savedFlags.moon == true end
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
local versions = {level = 0, raid = 0, arena = 0, dungeon = 0, expedition = 0, moon = 0, cards = 0, pet = 0, antiAfk = 0}
local titles = {level = "LEVEL UP", raid = "RAID", arena = "ARENA", dungeon = "DUNGEON",
    expedition = "EXPEDITIONS", moon = "USE POTION", cards = "AUTO OPEN CARD", pet = "AUTO PET", antiAfk = "ANTI AFK"}
local function paintToggle(key)
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
    potionUI.option.Visible = false
    cardUI.option.Visible = false
    for _, target in ipairs(petUI.targets) do target.list.Visible = false end
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
local function validMoon(version)
    return alive and (flags.moon or flags.cards) and versions.moon == version
end
local function run(key, operation)
    if busy then return end
    busy = true
    local version = versions[key]
    task.spawn(function()
        local ok, err = pcall(operation, version)
        busy = false
        if not ok then
            if key == "moon" then
                flags.cards = false
                toggles.cards.Text = titles.cards .. ": OFF"
                paintToggle("cards")
            end
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
        if key == "cards" then versions.moon = versions.moon + 1 end
        if key == "moon" or key == "cards" then potionUI.completedEvent = nil end
        if key == "pet" then petUI.nextCheck = 0; petUI.applied = nil end
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
copyButton.Activated:Connect(function()
    local value = table.concat(logs, "\n")
    if #cardUI.openReports > 0 then
        value = value .. "\n\nCARD OPEN REPORT (latest 500 presses)\n" .. table.concat(cardUI.openReports, "\n")
    end
    if petUI.report and #petUI.report > 0 then
        value = value .. "\n\nFULL PET UI REPORT\n" .. table.concat(petUI.report, "\n")
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
        neonUI.nextArena = math.max(neonUI.nextArena or 0, os.clock() + 60)
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
local moonUsed = {}
local moonCardsDone = false
local function closeModal(key)
    return fire(key, child(modalPanel(), {"Close"}), "X", 1)
end
local function moreMenu()
    local function rows() return get({"Frame", "Hud", "MoreMenu", "Rows"}) end
    if visible(rows()) then return rows() end
    if not fire("moon.more", get({"Frame", "Hud", "UtilMore"}), nil, 1) then return nil end
    local deadline = os.clock() + 4
    repeat
        task.wait(0.2)
        -- Resolve again: the menu can be created/replaced after clicking More.
        local menu = rows()
        if visible(menu) then return menu end
    until not alive or os.clock() >= deadline
    log("MORE menu unavailable after opening UtilMore")
end
local function openPotions()
    if modalTitle() == "POTIONS" then return true end
    if modalOpen() then return false end
    local menu = moreMenu()
    if not menu then return false end
    local entry = child(menu, {"potions"})
    if not ready(entry) then
        for _, obj in ipairs(menu:GetDescendants()) do
            if ready(obj) and buttonText(obj) == "POTIONS" then entry = obj; break end
        end
    end
    if not fire("moon.potions", entry, "POTIONS", 2) then
        return false
    end
    local deadline = os.clock() + 4
    repeat task.wait(0.2) until modalTitle() == "POTIONS" or not alive or os.clock() >= deadline
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
    if value == "" and modalTitle() == "POTIONS" and row then
        local parts = {}
        for _, node in ipairs(row:GetDescendants()) do
            local text = visible(node) and textOf(node) or ""
            if text:find("IN STASH", 1, true) or text:find(" LEFT", 1, true) then
                table.insert(parts, text)
            end
        end
        value = table.concat(parts, " | ")
    end
    if value ~= "" then rememberStatus(id .. "Potion", value) end
    return value
end
local function usePotion(id)
    if not flags.moon or not potionConfig.selected[id] then return true end
    if moonUsed[id] then return true end
    local function report(reason)
        cardUI.diagnose("POTION_" .. id:upper() .. "_" .. reason, "status=" .. potionStatus(id))
    end
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
        report("EMPTY")
        log(potionNames[id] .. " empty; skipped")
        moonUsed[id] = true
        return true
    end
    if not count then
        report("STATUS_UNREADABLE")
        log(potionNames[id] .. " stock unreadable; waiting")
        return false
    end
    local drink = child(modalPanel(), {"Content", "Inner", id, "Drink"})
    if not fire("moon.drink." .. id, drink, "DRINK", 2) then
        report("DRINK_UNAVAILABLE")
        return false
    end
    report("DRINK_PRESSED")
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
        -- Pet preparation leaves the PETS page active; reveal the battle dock first.
        if not fire("cards.back.battle", get({"Frame", "Nav", "Row", "endless"}), nil, 1) then
            cardUI.diagnose("CARD_BATTLE_NAV_UNAVAILABLE")
            return false
        end
        local deadline = os.clock() + 4
        local instant
        repeat
            task.wait(0.2)
            instant = get({"Frame", "Battle", "Dock", "Instant"})
        until ready(instant) or os.clock() >= deadline or not alive
        if not alive or not flags.cards or not potionUI.cycleValid() then return false end
        if not fire("moon.cards.open", instant, "OPEN", 2) then
            cardUI.diagnose("CARD_SHORTCUT_UNAVAILABLE", "visible=" .. tostring(visible(instant)) .. " caption=" .. buttonText(instant))
            return false
        end
    end
    local waitUntil = os.clock() + 4
    repeat task.wait(0.2) until modalTitle() == "CARD PACKS" or os.clock() >= waitUntil or not alive
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
function cardUI.openSnapshot(kind, stock, batch)
    local luck = sampleStatus("luck", get({"Frame", "Hud", "Luck", "Pill", "Value"}))
    local battle = sampleStatus("battleLuck", get({"Frame", "Battle", "Dock", "LuckTab", "Pill", "Value"}))
    local timer = sampleStatus("moonTimer", get({"Frame", "Buffs", "Moon", "Pill", "Value"}))
    local aura = cachedStatus("aura")
    local icon = potionUI.icon()
    local key = icon and not potionUI.iconConflicts[icon] and potionUI.iconMap[icon]
    if key then aura = moonCaption(key) .. " | verified HUD icon" end
    local pets = petUI.equippedStats()
    return {kind = kind, stock = stock, batch = batch, at = os.date("!%Y-%m-%dT%H:%M:%SZ"),
        luck = luck, battleLuck = battle, aura = aura, timer = timer,
        pets = pets and (pets.text .. " | observed " .. math.floor(os.clock() - pets.at) .. "s ago") or "Not confirmed",
        potions = "Luck: " .. cachedStatus("luckPotion") .. "; Haste: " .. cachedStatus("hastePotion") .. "; Gilded: " .. cachedStatus("gildPotion")}
end
function cardUI.recordOpen(snapshot)
    local message = "CARD OPEN PRESSED | " .. snapshot.at .. " | " .. snapshot.kind
        .. " | batch=" .. snapshot.batch .. " | stock=" .. snapshot.stock
        .. " | Luck HUD=" .. snapshot.luck .. " | Luck battle=" .. snapshot.battleLuck
        .. " | Moon=" .. snapshot.aura .. " | Sky timer=" .. snapshot.timer
        .. " | Pet=" .. snapshot.pets .. " | Potions=" .. snapshot.potions
    table.insert(cardUI.openReports, message)
    if #cardUI.openReports > 500 then table.remove(cardUI.openReports, 1) end
    log(message)
    neonUI.queueWebhook(message)
end
-- Compare meaningful diagnostic state, not timestamps/countdowns/cache ages.
function cardUI.shouldSendDiagnostic(reason, detail, key, event)
    if cardUI.webhookAuditEvent ~= event then
        cardUI.webhookAuditEvent = event
        cardUI.webhookAudit = {}
    end
    cardUI.webhookAudit = cardUI.webhookAudit or {}
    local clean = tostring(detail or ""):gsub("%d+%s*[HhMmSs]", "#")
        :gsub("%d+:%d+", "#"):gsub("last seen %d+s ago", "last seen #")
    local parts = {key, clean, modalTitle()}
    for _, value in ipairs({flags.moon == true, flags.cards == true,
        potionConfig.moons[key] == true, potionConfig.cardMoons[key] == true,
        potionConfig.selected.luck == true, cardSelection.requireLuck == true,
        cardSelection.requirePet == true, cardUI.luckActive() == true, petUI.luckActive() == true}) do
        table.insert(parts, tostring(value))
    end
    local state = table.concat(parts, "|")
    if cardUI.webhookAudit[reason] == state then return false end
    cardUI.webhookAudit[reason] = state
    return true
end
-- Bounded, local + webhook diagnostics; never navigates to PETS.
function cardUI.diagnose(reason, detail)
    local now = os.clock()
    local confirmed = potionUI.confirmed
    local key = confirmed and confirmed.key or "UNKNOWN"
    local signature = tostring(confirmed and confirmed.serial) .. ":" .. reason
    if cardUI.auditEvent ~= (confirmed and confirmed.serial) then
        cardUI.auditTimes = {}
        cardUI.auditEvent = confirmed and confirmed.serial
    end
    cardUI.auditTimes = cardUI.auditTimes or {}
    if cardUI.auditTimes[signature] and now - cardUI.auditTimes[signature] < 30 then return end
    cardUI.auditTimes[signature] = now
    if #cardUI.openReports >= 500 then table.remove(cardUI.openReports, 1) end
    local message = "CARD CHECK | " .. os.date("!%Y-%m-%dT%H:%M:%SZ")
        .. " | reason=" .. reason .. " | " .. tostring(detail or "")
        .. " | Moon=" .. key .. " | event=" .. tostring(confirmed and confirmed.serial)
        .. " | remaining=" .. tostring(confirmed and math.max(0, math.floor(confirmed.untilTime - now)) or 0)
        .. " | potionEnabled=" .. tostring(flags.moon)
        .. " | potionMoonSelected=" .. tostring(potionConfig.moons[key] == true)
        .. " | luckSelected=" .. tostring(potionConfig.selected.luck)
        .. " | luckStatus=" .. cachedStatus("luckPotion")
        .. " | cardsEnabled=" .. tostring(flags.cards)
        .. " | moonSelected=" .. tostring(potionConfig.cardMoons[key] == true)
        .. " | requireLuck=" .. tostring(cardSelection.requireLuck)
        .. " | luckPotionConfirmed=" .. tostring(cardUI.luckActive())
        .. " | requirePet=" .. tostring(cardSelection.requirePet)
        .. " | petLuckConfirmed=" .. tostring(petUI.luckActive())
        .. " | Luck=" .. cachedStatus("luck") .. " | Pet=" .. cachedStatus("petLuck")
        .. " | Cards=" .. cachedStatus("cards") .. " | modal=" .. modalTitle()
    table.insert(cardUI.openReports, message)
    log(message)
    if cardUI.shouldSendDiagnostic(reason, detail, key, confirmed and confirmed.serial) then
        neonUI.queueWebhook(message)
    end
end
local function openOwnedCardsWorker(version)
    if not flags.cards or not validMoon(version) then return false end
    if not openCardPacks() then
        cardUI.diagnose("CARD_PAGE_UNAVAILABLE")
        note("CARD PACKS entry unavailable; retrying")
        return false
    end
    local function cardRunValid()
        local buffsReady = (not cardSelection.requireLuck or cardUI.luckActive())
            and (not cardSelection.requirePet or petUI.luckActive())
        if flags.cards and validMoon(version) and potionUI.cycleValid() and buffsReady then return true end
        if not buffsReady then log("Open Card stopped: a required Luck Potion / Pet Luck condition expired") end
        if alive and modalTitle() == "CARD PACKS" then closeModal("moon.cards.cancel.close") end
        return false
    end
    if not cardRunValid() then return false end
    local initial = 0
    if cardSelection.loose then initial = cardCount() end
    if initial == nil then
        cardUI.diagnose("CARD_COUNT_UNREADABLE")
        note("Reward Cards count unreadable; retrying")
        return false
    end
    local thresholdCount = cardCount()
    if cardSelection.stopBelow > 0 and thresholdCount == nil then return false end
    if cardUI.belowLimit(thresholdCount) then
        cardUI.diagnose("CARD_THRESHOLD_REACHED", "remaining=" .. thresholdCount)
        return true
    end
    local count, opened, rounds = initial, 0, 0
    -- The observed OPEN ALL processed roughly 1.26 million cards per press.
    -- Repeat only after a measured decrease, never while a prior batch is pending.
    while count > 0 and rounds < 120 and cardRunValid() do
        local all = child(modalPanel(), {"Content", "Inner", "Loose",
            "Row", "Open", "All"})
        local caption = buttonText(all)
        if not caption:match("^OPEN [%d,]+$") then
            log("Reward Cards OPEN unavailable: " .. caption)
            return false
        end
        local snapshot = cardUI.openSnapshot("Reward Cards", count, rounds + 1)
        if not fire("moon.cards.all", all, caption, 4) then return false end
        if potionUI.cycle then potionUI.cycle.cardsDispatched = true end
        cardUI.recordOpen(snapshot)
        rounds = rounds + 1
        local before = count
        local deadline = os.clock() + 15
        repeat
            task.wait(0.5)
            if modalTitle() == "YOUR HAUL" then
                if not potionUI.closeCycleWindow() then return false end
                if not cardRunValid() or not openCardPacks() then return false end
            end
            count = cardCount()
        until (count and count < before) or os.clock() >= deadline
        if not cardRunValid() then return false end
        if not count or count >= before then
            cardUI.diagnose("CARD_BATCH_UNCONFIRMED", "before=" .. before .. " after=" .. tostring(count or "unknown"))
            log("Reward Cards batch unconfirmed: " .. before .. " -> "
                .. tostring(count or "window closed"))
            return false
        end
        cardUI.diagnose("CARD_BATCH_CONFIRMED", "before=" .. before .. " after=" .. count)
        opened = opened + before - count
        log("Reward Cards batch " .. rounds .. ": " .. before .. " -> "
            .. count .. " | measured decrease=" .. opened)
        if cardUI.belowLimit(count) then
            cardUI.diagnose("CARD_THRESHOLD_REACHED", "remaining=" .. count)
            return true
        end
        if count == 0 then break end
        task.wait(4.2)
    end
    if count > 0 then
        note("Aurora: Reward Cards remain " .. count .. "; retrying")
        return false
    end
    log("Reward Cards backlog: " .. initial .. " -> " .. count
        .. " after " .. rounds .. " batch(es)")
    if not cardRunValid() then return false end
    -- Pack buttons may be GET MORE when owned=0. Never press a purchase link.
    for _, id in ipairs({"pouch", "crate", "chest"}) do
        local attempts = 0
        while cardRunValid() and cardSelection[id] and modalTitle() == "CARD PACKS"
            and attempts < 120 do
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
            local snapshot = cardUI.openSnapshot(cardUI.names[id], owned, attempts + 1)
            if not fire("moon.pack." .. id, open, caption, 2) then break end
            if potionUI.cycle then potionUI.cycle.cardsDispatched = true end
        cardUI.recordOpen(snapshot)
            attempts = attempts + 1
            task.wait(2.2)
            if modalTitle() == "YOUR HAUL" then
                if not potionUI.closeCycleWindow() then return false end
                if not cardRunValid() or not openCardPacks() then return false end
            end
            local afterSub = child(child(modalPanel(), {"Content", "Inner",
                "Packs", id, "Open"}), {"Face", "Sub"})
            local after = numeric(textOf(afterSub):match("([%d,]+)%s+OWNED"))
            log(id .. " owned: " .. owned .. " -> " .. tostring(after or "unconfirmed"))
            if not after or after >= owned then break end
        end
    end
    if not cardRunValid() then return false end
    if cardSelection.loose and cardCount() ~= 0 then
        cardUI.diagnose("CARDS_REMAIN", "Reward Cards not confirmed zero; retry after cooldown")
        return false
    end
    for _, id in ipairs({"pouch", "crate", "chest"}) do
        if cardSelection[id] then
            local sub = child(modalPanel(), {"Content", "Inner", "Packs", id, "Open", "Face", "Sub"})
            local owned = numeric(textOf(sub):match("([%d,]+)%s+OWNED"))
            if owned ~= 0 then
                cardUI.diagnose("CARDS_REMAIN", id .. "=" .. tostring(owned or "unknown"))
                return false
            end
        end
    end
    if modalTitle() == "CARD PACKS" then closeModal("moon.cards.close") end
    moonCardsDone = true
    note("Selected card inventory confirmed empty")
    return true
end
local function openOwnedCards(version)
    local ok, result = pcall(openOwnedCardsWorker, version)
    if alive and (modalTitle() == "CARD PACKS" or modalTitle() == "YOUR HAUL") then potionUI.closeCycleWindow() end
    if not ok then cardUI.diagnose("WORKER_ERROR", tostring(result)); return false end
    cardUI.diagnose(result and "WORKER_FINISHED" or "WORKER_STOPPED", "dispatched=" .. tostring(potionUI.cycle and potionUI.cycle.cardsDispatched))
    return result
end
local function moonTick(version)
    if not validMoon(version) then return end
    if flags.cards and modalTitle() == "YOUR HAUL" then
        if not potionUI.closeCycleWindow() then return end
    end
    if modalOpen() and modalTitle() ~= "MOONS" then
        if flags.cards then cardUI.diagnose("BLOCKING_WINDOW") end
        nextMoon = os.clock() + 3; return end
    local sky, openedHere = potionUI.resolveSky(version)
    if not sky or not validMoon(version) then
        if flags.cards then cardUI.diagnose("MOON_UNCONFIRMED") end
        return end
    rememberStatus("aura", sky)
    local currentKey = moonIdentity(sky, true)
    local confirmed = potionUI.confirmed
    nextMoon = math.min(os.clock() + 5, confirmed.untilTime)
    if openedHere or modalTitle() == "MOONS" then
        if not potionUI.closeCycleWindow() then return end
    end
    local potionMatch = flags.moon and potionConfig.moons[currentKey]
    local cardMatch = flags.cards and potionConfig.cardMoons[currentKey]
    if flags.cards and not cardMatch then cardUI.diagnose("MOON_NOT_SELECTED") end
    if not (potionMatch or cardMatch) or potionUI.completedEvent == confirmed.serial then return end
    if potionUI.cardRetryAt and os.clock() < potionUI.cardRetryAt then return end
    cardUI.diagnose("CYCLE_CHECK")
    local petVersion = versions.pet
    local function active() return validMoon(version) and potionUI.cycleValid() end
    potionUI.cycle = {serial = confirmed.serial, key = currentKey, cardsDispatched = false, cardsFinished = false, potionPending = false}
    if potionUI.potionEvent ~= confirmed.serial then
        potionUI.potionEvent = confirmed.serial
        potionUI.potionUsed = {}
    end
    moonUsed, moonCardsDone = potionUI.potionUsed, false
    log("CYCLE START | " .. currentKey .. " | event=" .. confirmed.serial)
    local ok, errorText = pcall(function()
        if potionMatch and active() then
            local selected = false
            for _, id in ipairs({"luck", "haste", "gild"}) do if potionConfig.selected[id] then selected = true end end
            if selected and openPotions() then
                for _, id in ipairs({"luck", "haste", "gild"}) do
                    if not active() then break end
                    if potionConfig.selected[id] and not usePotion(id) then potionUI.cycle.potionPending = true end
                end
                potionUI.closeCycleWindow()
            elseif selected then
                potionUI.cycle.potionPending = true
                cardUI.diagnose("POTION_PAGE_UNAVAILABLE", "More > Potions not ready")
            end
        end
        if potionUI.cycle.potionPending then return end
        -- Resolve the required potion before temporarily changing pets.
        if cardMatch and cardSelection.requireLuck and active() and not cardUI.checkLuck(version) then return end
        if modalTitle() == "POTIONS" and not potionUI.closeCycleWindow() then return end
        if cardMatch and flags.pet and active() and versions.pet == petVersion then
            log("CYCLE prepare Luck Pet")
            if not petUI.ensureRole("luck", currentKey, function()
                return active() and flags.pet and versions.pet == petVersion
            end) then
                cardUI.diagnose("PET_PREPARE_FAILED")
                return
            end
        end
        if cardMatch and flags.cards and active() then
            if cardUI.ready(version, currentKey) and active() then
                log("CYCLE Open Card")
                potionUI.cycle.cardsFinished = openOwnedCards(version) == true
            else log("CYCLE Open Card skipped: configured conditions are not met") end
        else cardUI.diagnose(not cardMatch and "MOON_NOT_SELECTED" or "CARD_DISABLED_OR_MOON_EXPIRED") end
    end)
    if not ok then cardUI.diagnose("CYCLE_ERROR", tostring(errorText)) end
    local closed = potionUI.closeCycleWindow()
    if closed and alive and flags.pet and versions.pet == petVersion and potionUI.cycle.petRestore then
        local restoreOk, restored = pcall(petUI.restoreCycle, function()
            return alive and flags.pet and versions.pet == petVersion
        end)
        cardUI.diagnose(restoreOk and restored and "PET_RESTORED" or "PET_RESTORE_UNCONFIRMED")
    end
    potionUI.closeCycleWindow()
    if alive and not modalOpen() then
        fire("cycle.back.battle", get({"Frame", "Nav", "Row", "endless"}), nil, 1)
    end
    local retry = active() and (potionUI.cycle.potionPending
        or (cardMatch and flags.cards and not potionUI.cycle.cardsFinished
        ))
    potionUI.completedEvent = not retry and versions.moon == version and confirmed.serial or nil
    potionUI.cardRetryAt = retry and (os.clock() + 30) or nil
    if retry then cardUI.diagnose("RETRY_PENDING", "Retry in 30s; no repeated potions") end
    potionUI.cycle = nil
    log("CYCLE FINISHED | " .. currentKey .. " | cards UI closed=" .. tostring(modalTitle() ~= "CARD PACKS"))
end

function potionUI.caption(name)
    local amount = potionConfig.multipliers[moonIdentity(name, true)]
    return name .. " (x" .. (amount and string.format("%g", amount) or "?") .. ")"
end
function potionUI.summary(field)
    local names = {}
    for _, name in ipairs(potionConfig.available) do
        if potionConfig[field][moonIdentity(name, true)] then table.insert(names, potionUI.caption(name)) end
    end
    if #names == 0 then return "None selected" end
    return #names == 1 and names[1] or (#names .. " Moons selected")
end
function potionUI.menus()
    return {potionUI.primary, cardUI.primary, petUI.targets[1]}
end
function potionUI.paintMenus()
    for _, target in ipairs(potionUI.menus()) do
        for _, entry in ipairs(target.entries) do
            local key = entry:GetAttribute("MoonKey")
            local selected = potionConfig[target.field][key] == true
            entry.Text = (selected and "[x] " or "[ ] ") .. potionUI.caption(moonCaption(key))
            entry.BackgroundColor3 = selected and theme.accent or theme.off
            entry.TextColor3 = theme.text
        end
    end
end
function potionUI.multiplier(text)
    local value = text:upper():gsub("×", "X"):gsub(",", "")
    local number = value:match("X%s*(%d+%.?%d*)%s*LUCK")
        or value:match("LUCK%s*X%s*(%d+%.?%d*)")
    number = tonumber(number)
    return number and number > 0 and number < math.huge and number or nil
end
function potionUI.readMultiplier(obj)
    local own = potionUI.multiplier(statusPlain(obj))
    if own then return own end
    local found
    for _, sibling in ipairs(obj.Parent and obj.Parent:GetChildren() or {}) do
        if sibling ~= obj then
            local amount = potionUI.multiplier(statusPlain(sibling))
            if amount then
                if found and found ~= amount then return nil end
                found = amount
            end
        end
    end
    return found
end
function potionUI.seconds(value)
    local upper = value:upper()
    local m, s = upper:match("(%d+):(%d+)%s*$")
    if m then return tonumber(m) * 60 + tonumber(s) end
    local h = tonumber(upper:match("(%d+)%s*H")) or 0
    m = tonumber(upper:match("(%d+)%s*M")) or 0
    s = tonumber(upper:match("(%d+)%s*S")) or 0
    local total = h * 3600 + m * 60 + s
    return total > 0 and total or nil
end
function potionUI.icon()
    local obj = get({"Frame", "Buffs", "Moon", "Circle", "Icon"})
    if visible(obj) and (obj:IsA("ImageLabel") or obj:IsA("ImageButton")) and obj.Image ~= "" then return obj.Image end
end
function potionUI.confirmSky(value)
    local key = moonIdentity(value, true)
    if not key then return false end
    local remaining = potionUI.seconds(value)
    if not remaining then
        local detail = child(modalPanel(), {"Content", "Inner", "Now", "Sub"})
        local nextRoll = visible(detail) and statusPlain(detail):lower():match("sky rolls again in%s+(%d+:%d+)")
        remaining = nextRoll and potionUI.seconds(nextRoll)
    end
    if not remaining then
        local timer = get({"Frame", "Buffs", "Moon", "Pill", "Value"})
        remaining = visible(timer) and potionUI.seconds(statusPlain(timer))
    end
    if not remaining or remaining <= 0 then return false end
    local icon = potionUI.icon()
    if icon then
        if potionUI.iconMap[icon] and potionUI.iconMap[icon] ~= key then potionUI.iconConflicts[icon] = true end
        potionUI.iconMap[icon] = key
    end
    local previous = potionUI.confirmed
    local same = previous and previous.key == key and previous.untilTime > os.clock()
    if not same then
        potionUI.eventSerial = (potionUI.eventSerial or 0) + 1
        log("MOON WINDOW | " .. key .. " | remaining=" .. remaining .. "s | event=" .. potionUI.eventSerial)
    end
    potionUI.confirmed = {key = key, icon = icon, untilTime = os.clock() + remaining,
        label = value:gsub("%s*·%s*%d+:%d+%s*$", ""), serial = potionUI.eventSerial}
    potionUI.lastProbeAt, potionUI.retryAt = os.clock(), 0
    potionUI.probeAt = potionUI.confirmed.untilTime
    gui:SetAttribute("MoonKnownUntil", potionUI.confirmed.untilTime)
    return true
end
function potionUI.cachedSky()
    local value = potionUI.confirmed
    if not value or value.untilTime <= os.clock() then return nil end
    local icon = potionUI.icon()
    if icon and value.icon and icon ~= value.icon then return nil end
    local left = math.max(0, math.ceil(value.untilTime - os.clock()))
    return value.label .. string.format(" · %d:%02d", math.floor(left / 60), left % 60)
end
function potionUI.resolveSky(version, check)
    if modalTitle() == "MOONS" then
        local obj = child(modalPanel(), {"Content", "Inner", "Now", "Title"})
        local value = visible(obj) and statusPlain(obj) or ""
        if value ~= "" and potionUI.confirmSky(value) then return potionUI.cachedSky(), false end
    end
    local cached = potionUI.cachedSky()
    if cached then return cached, false end
    if os.clock() < (potionUI.retryAt or 0) then nextMoon = math.min(os.clock() + 5, potionUI.retryAt); return nil end
    if modalOpen() then nextMoon = os.clock() + 3; return nil end
    if not fire("moon.tab", get({"Frame", "Buffs", "Moon"}), nil, 3) then nextMoon = os.clock() + 5; return nil end
    potionUI.lastProbeAt = os.clock()
    task.wait(0.7)
    local obj = child(modalPanel(), {"Content", "Inner", "Now", "Title"})
    local value = modalTitle() == "MOONS" and visible(obj) and statusPlain(obj) or ""
    local valid = check and check() or (not check and validMoon(version))
    local confirmed = valid and value ~= "" and potionUI.confirmSky(value)
    if not confirmed then
        if alive and modalTitle() == "MOONS" then closeModal("moon.cancel.close") end
        potionUI.retryAt = os.clock() + potionConfig.moonInspectMinutes * 60
        nextMoon = potionUI.retryAt
        note("Moon/time read not confirmed; will retry, no boost or cards sent")
        return nil
    end
    if potionUI.discover() > 0 then potionUI.rebuild() end
    return potionUI.cachedSky(), true
end
function potionUI.cycleValid()
    local value, cycle = potionUI.confirmed, potionUI.cycle
    return not cycle or (value and value.serial == cycle.serial and potionUI.cachedSky() ~= nil)
end
function potionUI.closeCycleWindow()
    if not alive then return false end
    local title = modalTitle()
    if title == "PET" and petUI.lastDetail and petUI.detail(petUI.lastDetail) then
        return petUI.closeDetail(petUI.lastDetail, function() return alive end)
    end
    if title ~= "YOUR HAUL" and title ~= "CARD PACKS" and title ~= "POTIONS" and title ~= "MOONS" then return not modalOpen() end
    local deadline = os.clock() + 4
    repeat
        closeModal("cycle.close." .. title)
        task.wait(0.3)
        if not modalOpen() then return true end
        if title == "YOUR HAUL" and modalTitle() == "CARD PACKS" then return true end
        if modalTitle() ~= title then return false end
    until not alive or os.clock() >= deadline
    log("CYCLE window close unconfirmed: " .. title)
    return false
end
function petUI.equippedStats()
    local screen = page()
    local header = child(screen, {"OnHead"})
    local hint = statusPlain(child(screen, {"SlotHint"})):lower()
    local value = visible(header) and statusPlain(header) or ""
    if hint:find("pet", 1, true) and value:upper():match("^EQUIPPED%s+%d+/%d+") then
        local lower = value:lower()
        petUI.equipped = {
            count = tonumber(lower:match("^equipped%s+(%d+)/")) or 0,
            luck = tonumber(lower:match("%+([%d.]+)%%%s*luck")) or 0,
            rolls = tonumber(lower:match("%+([%d.]+)%%%s*rolls from play")) or 0,
            text = value, at = os.clock(),
        }
    end
    local stats = petUI.equipped
    if stats and os.clock() - stats.at <= 300 then return stats end
end
function petUI.inspectEquipped(version)
    if petUI.equippedStats() then return end
    if inDungeon() or modalOpen() or os.clock() < (petUI.nextInspect or 0) then return end
    petUI.nextInspect = os.clock() + 300
    local root = pg:FindFirstChild("RollAStickman")
    local function findEntry()
        for _, obj in ipairs(root and root:GetDescendants() or {}) do
            if ready(obj) then
                local name = obj.Name:lower()
                if buttonText(obj) == "PETS" or name == "pets" or name == "utilpets" then return obj end
            end
        end
    end
    local entry = findEntry()
    if not entry then moreMenu(); entry = findEntry() end
    if not entry then return end
    local backToBattle = battleTitle() ~= ""
    if not fire("pet.inspect.open", entry, nil, 5) then return end
    task.wait(0.8)
    if not validMoon(version) then return end
    local stats = petUI.equippedStats()
    if stats then
        log("PET EQUIPPED | " .. stats.text)
        if backToBattle then fire("pet.inspect.back", get({"Frame", "Nav", "Row", "endless"}), nil, 3) end
    end
end
function petUI.luckActive()
    local stats = petUI.equippedStats()
    if stats and stats.count > 0 and stats.luck > 0 then return true end
    local root = get({"Frame", "Buffs"})
    for _, widget in ipairs(root and root:GetChildren() or {}) do
        if visible(widget) then
            local found, active = false, false
            local nodes = {widget}
            for _, obj in ipairs(widget:GetDescendants()) do table.insert(nodes, obj) end
            for _, obj in ipairs(nodes) do
                if visible(obj) then
                    local name = obj.Name:upper():gsub("[_%s]", "")
                    local text = statusPlain(obj):upper()
                    if name == "PETLUCK" or name == "LUCKPET" or text:find("PET LUCK", 1, true) or text:find("LUCK PET", 1, true) then found = true end
                    if potionUI.seconds(text) or text == "ACTIVE" then active = true end
                end
            end
            if found and active then return true end
        end
    end
    return false
end
-- The PET detail binding below is grounded in the supplied R17 UI report.
function petUI.nameOf(value)
    return value:gsub("<[^>]*>", ""):gsub("·", "|"):match("^([^|]+)"):gsub("%s+", " "):match("^%s*(.-)%s*$"):upper()
end
function petUI.roleFor(key)
    local confirmed = potionUI.confirmed
    local finished = confirmed and potionUI.completedEvent == confirmed.serial
        and (potionConfig.moons[key] or potionConfig.cardMoons[key])
    if key and not finished and potionConfig.petLuckMoons[key] then return "luck" end
    if key and (finished or key ~= "AURORA") and potionConfig.petPlayEnabled
        and os.clock() >= petUI.nextPlayAt then return "play" end
end
function petUI.pageReady()
    return visible(child(page(), {"OnHead"}))
        and statusPlain(child(page(), {"SlotHint"})):lower():find("pet", 1, true) ~= nil
        and child(page(), {"Grid"}) ~= nil
end
function petUI.openPage(check)
    if petUI.pageReady() then return true, false end
    if modalOpen() then return false end
    local root = pg:FindFirstChild("RollAStickman")
    local function findEntry()
        for _, obj in ipairs(root and root:GetDescendants() or {}) do
            if ready(obj) then
                local name = obj.Name:lower()
                if buttonText(obj) == "PETS" or name == "pets" or name == "utilpets" then return obj end
            end
        end
    end
    local entry = findEntry()
    if not entry then moreMenu(); entry = findEntry() end
    if not entry or not check() then return false end
    local back = battleTitle() ~= ""
    if not fire("pet.auto.open", entry, nil, 3) then return false end
    local deadline = os.clock() + 4
    repeat
        if not check() then return false end
        if petUI.pageReady() then return true, back end
        task.wait(0.2)
    until os.clock() >= deadline
    return false
end
function petUI.owned()
    local list = {}
    local grid = child(page(), {"Grid"})
    for _, obj in ipairs(grid and grid:GetChildren() or {}) do
        local name = statusPlain(child(obj, {"Name"}))
        if obj:IsA("GuiButton") and obj.Name:match("^[%w_]+:%d+$") and name ~= "" then
            table.insert(list, {id = obj.Name, name = petUI.nameOf(name),
                level = statusPlain(child(obj, {"Level"})), button = obj})
        end
    end
    table.sort(list, function(a, b) return a.id < b.id end)
    return list
end
function petUI.detail(item)
    if modalTitle() ~= "PET" then return nil end
    local inner = child(modalPanel(), {"Content", "Inner"})
    local name = child(inner, {"Name"})
    local gives = child(inner, {"Gives"})
    local equip = child(inner, {"Buttons", "Equip"})
    if not visible(name) or not visible(gives) or not ready(equip) then return nil end
    if petUI.nameOf(statusPlain(name)) ~= item.name then return nil end
    local text = statusPlain(gives)
    if text == "" then return nil end
    local lower = text:lower()
    local luck = tonumber(lower:match("%+([%d.]+)%%%s*luck"))
    local play = tonumber(lower:match("%+([%d.]+)%%%s*rolls from play"))
    if (lower:find("luck", 1, true) and not luck)
        or (lower:find("rolls from play", 1, true) and not play) then return nil end
    local caption = buttonText(equip)
    if caption ~= "EQUIP" and caption ~= "UNEQUIP" then return nil end
    return {name = item.name, level = item.level, luck = luck or 0, play = play or 0,
        gives = text}, equip, caption
end
function petUI.openDetail(item, check)
    if not check() then return nil end
    local wasOn = visible(child(item.button, {"Tag"})) and textOf(child(item.button, {"Tag"})) == "ON"
    petUI.lastDetail = item
    if not fire("pet.detail." .. item.id, item.button, nil, 0.5) then return nil end
    local deadline = os.clock() + 4
    local previous
    repeat
        if not check() then return nil end
        local record, equip, caption = petUI.detail(item)
        if record then
            local isOn = visible(child(item.button, {"Tag"})) and textOf(child(item.button, {"Tag"})) == "ON"
            if isOn ~= wasOn then
                note("Pet detail click changed equipment unexpectedly; inspection stopped")
                return nil
            end
            local stamp = record.gives .. "|" .. caption
            if previous == stamp then return record, equip, caption end
            previous = stamp
        end
        task.wait(0.2)
    until os.clock() >= deadline
end
function petUI.closeDetail(item, check)
    if check() and petUI.detail(item) then
        if fire("pet.detail.close", child(modalPanel(), {"Close"}), "X", 0.2) then
            local deadline = os.clock() + 3
            repeat
                if not check() or not modalOpen() then return not modalOpen() end
                task.wait(0.15)
            until os.clock() >= deadline
        end
    end
    return not modalOpen()
end
function petUI.scanCatalog(items, check, force)
    for i, item in ipairs(items) do
        if not check() then return false end
        local saved = petUI.catalog[item.id]
        if force or not saved or saved.name ~= item.name or saved.level ~= item.level then
            if modalOpen() then return false end
            note("Reading pet " .. i .. "/" .. #items .. ": " .. item.name)
            local record = petUI.openDetail(item, check)
            if not record then
                note("Pet stats not confirmed for " .. item.name .. "; no equip sent")
                return false
            end
            petUI.catalog[item.id] = record
            settingsStorage = writeSettings(flags)
            log("PET STAT | " .. item.id .. " | " .. record.name .. " | " .. record.gives)
            if not petUI.closeDetail(item, check) then return false end
        end
    end
    return true
end
function petUI.best(items, role)
    local best, amount
    for _, item in ipairs(items) do
        local record = petUI.catalog[item.id]
        if record and record.name == item.name and record.level == item.level and record[role] > 0 then
            local on = visible(child(item.button, {"Tag"})) and textOf(child(item.button, {"Tag"})) == "ON"
            if not best or record[role] > amount
                or (record[role] == amount and on and not best.on) then
                best, amount = {item = item, record = record, on = on}, record[role]
            end
        end
    end
    return best
end
function petUI.apply(best, role, check)
    if modalOpen() or not check() then return false end
    local record, equip, caption = petUI.openDetail(best.item, check)
    if not record then return false end
    petUI.catalog[best.item.id] = record
    if record[role] <= 0 then petUI.closeDetail(best.item, check); return false end
    if caption == "UNEQUIP" then
        local stats = petUI.equippedStats()
        local tagged = visible(child(best.item.button, {"Tag"})) and textOf(child(best.item.button, {"Tag"})) == "ON"
        if not stats or stats.count <= 0 or not tagged
            or (role == "luck" and stats.luck or stats.rolls) < record[role] - 0.01 then
            note("Pet says equipped but its total bonus is not confirmed; no toggle sent")
            petUI.closeDetail(best.item, check)
            return false
        end
        log("PET READY | already equipped | " .. best.item.id .. " | " .. record.gives)
        petUI.closeDetail(best.item, check)
        return true
    end
    if not check() or buttonText(equip) ~= "EQUIP" or not petUI.detail(best.item) then return false end
    if not fire("pet.equip." .. best.item.id, equip, "EQUIP", 5) then return false end
    local deadline = os.clock() + 6
    repeat
        if not check() then return false end
        local current, _, state = petUI.detail(best.item)
        local tagged = visible(child(best.item.button, {"Tag"})) and textOf(child(best.item.button, {"Tag"})) == "ON"
        if current and state == "UNEQUIP" and tagged then
            local stats = petUI.equippedStats()
            if stats and stats.count > 0 and (role == "luck" and stats.luck or stats.rolls) >= record[role] - 0.01 then
                log("PET EQUIP CONFIRMED | " .. best.item.id .. " | " .. record.gives .. " | " .. stats.text)
                petUI.closeDetail(best.item, check)
                return true
            end
        end
        task.wait(0.3)
    until os.clock() >= deadline
    note("Pet equip unconfirmed: " .. best.item.name .. "; COPY LOG")
    petUI.closeDetail(best.item, check)
    return false
end
function petUI.ensureRole(role, key, check)
    if not check() or modalOpen() then return false end
    local ok, result = pcall(function()
        if not petUI.openPage(check) then return false end
        local items = petUI.owned()
        if #items == 0 or not petUI.scanCatalog(items, check, false) or not check() then return false end
        local best = petUI.best(items, role)
        if not best then log("No verified " .. role .. " pet found"); return false end
        if role == "luck" and potionUI.cycle and not potionUI.cycle.petRestore then
            local snapshot = {before = {}, boosted = best.item.id}
            for _, item in ipairs(items) do
                if visible(child(item.button, {"Tag"})) and textOf(child(item.button, {"Tag"})) == "ON" then
                    snapshot.before[item.id] = true
                end
            end
            potionUI.cycle.petRestore = snapshot
        end
        if not petUI.apply(best, role, check) then return false end
        petUI.applied = {role = role, id = best.item.id, moon = key, at = os.clock()}
        if role == "play" then
            petUI.lastPlayAt = os.clock()
            petUI.nextPlayAt = petUI.lastPlayAt + potionConfig.petPlayEveryMinutes * 60
        end
        note("Pet ready: " .. best.item.name .. " | " .. best.record.gives)
        return true
    end)
    if alive and modalTitle() == "PET" and petUI.lastDetail and petUI.detail(petUI.lastDetail) then
        petUI.closeDetail(petUI.lastDetail, function() return alive end)
    end
    if not ok then log("Pet " .. role .. " step error: " .. tostring(result)); return false end
    return result == true
end
function petUI.restoreCycle(check)
    local snapshot = potionUI.cycle and potionUI.cycle.petRestore
    if not snapshot or not check() or not petUI.openPage(check) then return false end
    local items = petUI.owned()
    local function tagged(item)
        return visible(child(item.button, {"Tag"})) and textOf(child(item.button, {"Tag"})) == "ON"
    end
    -- Remove only the Luck pet this cycle added. Never toggle a pre-existing pet.
    for _, item in ipairs(items) do
        if item.id == snapshot.boosted and not snapshot.before[item.id] and tagged(item) then
            local record, equip, caption = petUI.openDetail(item, check)
            if not record or caption ~= "UNEQUIP" or not check() then return false end
            if not fire("pet.restore.remove." .. item.id, equip, "UNEQUIP", 2) then return false end
            local deadline = os.clock() + 6
            repeat task.wait(0.3) until not tagged(item) or not check() or os.clock() >= deadline
            petUI.closeDetail(item, function() return alive end)
            if tagged(item) or not check() then return false end
        end
    end
    for _, item in ipairs(items) do
        if snapshot.before[item.id] and not tagged(item) then
            local record = petUI.catalog[item.id]
            local role = record and (record.luck > 0 and "luck" or record.play > 0 and "play")
            if not role or not petUI.apply({item=item, record=record}, role, check) then return false end
        end
    end
    local found = {}
    for _, item in ipairs(petUI.owned()) do
        if tagged(item) then found[item.id] = true end
    end
    for id in pairs(snapshot.before) do if not found[id] then return false end end
    if not snapshot.before[snapshot.boosted] and found[snapshot.boosted] then return false end
    petUI.applied = nil
    return true
end
function petUI.tick(version, manual)
    local function check() return alive and versions.pet == version and (manual or flags.pet) end
    if not check() then return end
    petUI.nextCheck = os.clock() + 30
    if modalOpen() then
        note("Close the current game window to allow AUTO PET / pet scanning")
        return
    end
    local key, role
    if not manual then
        local sky, openedHere = potionUI.resolveSky(version, check)
        if not sky then petUI.nextCheck = os.clock() + 10; return end
        key = moonIdentity(sky, true)
        role = petUI.roleFor(key)
        if openedHere and modalTitle() == "MOONS" then closeModal("pet.moon.close"); task.wait(0.3) end
        if not role then return end
        if role == "luck" and petUI.applied and petUI.applied.role == role and os.clock() - petUI.applied.at < 300 then
            petUI.applied.moon = key
            return
        end
    end
    local opened, back = petUI.openPage(check)
    if not opened then note("PETS page unavailable; open PETS and retry"); return end
    local items = petUI.owned()
    if #items == 0 then note("No owned pet cards found"); return end
    local scanned = petUI.scanCatalog(items, check, manual == true)
    if not scanned or not check() then return end
    local luckBest, playBest = petUI.best(items, "luck"), petUI.best(items, "play")
    petUI.help.Text = "Luck: " .. (luckBest and (luckBest.item.name .. " +" .. luckBest.record.luck .. "%") or "none")
        .. "\nPlay: " .. (playBest and (playBest.item.name .. " +" .. playBest.record.play .. "%") or "none")
    if manual then
        note("Pet stats scanned: " .. #items .. "; no equipment changed")
    else
        local sky, openedHere = potionUI.resolveSky(version, check)
        local freshKey = sky and moonIdentity(sky, true)
        if openedHere and modalTitle() == "MOONS" then closeModal("pet.moon.recheck.close"); task.wait(0.3) end
        if not check() or not freshKey or petUI.roleFor(freshKey) ~= role then
            petUI.nextCheck = 0
            note("Pet stats saved; Moon condition changed before equip, checking again")
            return
        end
        key = freshKey
        local best = role == "luck" and luckBest or playBest
        if not best then note("No verified pet found for " .. role)
        elseif petUI.apply(best, role, check) then
            petUI.applied = {role = role, id = best.item.id, moon = key, at = os.clock()}
            if role == "play" then
                petUI.lastPlayAt = os.clock()
                petUI.nextPlayAt = petUI.lastPlayAt + potionConfig.petPlayEveryMinutes * 60
                log("PET PLAY TIMER | confirmed; next check in " .. potionConfig.petPlayEveryMinutes .. " minutes")
            end
            note("AUTO PET ready: " .. best.item.name .. " | " .. best.record.gives)
        end
    end
    if check() and back and not modalOpen() then
        fire("pet.auto.back", get({"Frame", "Nav", "Row", "endless"}), nil, 3)
    end
end
petUI.scan.Activated:Connect(function()
    petUI.scanRequested = true
    petUI.nextCheck = 0
    note("Pet stats scan queued; details are read without Equip/Fuse/Buy clicks")
end)
function cardUI.luckActive()
    local entry = statusCache.luckPotion
    if not entry or not entry.value:upper():find("LEFT", 1, true) then return false end
    local left = potionUI.seconds(entry.value:upper():match("^(.-)LEFT") or "")
    return left and entry.at + left > os.clock() or false
end
function cardUI.ready(version, currentKey)
    if cardSelection.requirePet and not petUI.luckActive() then
        -- Only use existing Pet bonus evidence; never open PETS before cards.
        if not petUI.luckActive() then
            cardUI.diagnose("PET_LUCK_UNCONFIRMED", "Required Pet bonus missing or unknown; no pre-card Pet visit")
            note("Open Card waiting: equipped Pet Luck bonus is not confirmed; see PET tab")
            return false
        end
    end
    local confirmed = cardUI.checkLuck(version)
    if modalTitle() == "POTIONS" and not potionUI.closeCycleWindow() then return false end
    return confirmed
end
function cardUI.checkLuck(version)
    if cardSelection.requireLuck and not cardUI.luckActive() then
        if modalTitle() == "POTIONS" then
            potionStatus("luck")
        elseif not modalOpen() and os.clock() >= (cardUI.nextBuffInspect or 0) then
            cardUI.nextBuffInspect = os.clock() + 60
            if openPotions() then
                potionStatus("luck")
                if modalTitle() == "POTIONS" then closeModal("cards.buff.check.close") end
            end
        end
        if not cardUI.luckActive() then cardUI.diagnose("LUCK_POTION_UNCONFIRMED", "Inspect luckStatus, potionEnabled, potionMoonSelected and luckSelected"); note("Open Card waiting: Luck Potion must be active"); return false end
    end
    return validMoon(version)
end
local function paintPotionChoices()
    potionUI.dropdown.Text = "Use Potion When: " .. potionUI.summary("moons") .. "   v"
    cardUI.condition.Text = "Open Card When: " .. potionUI.summary("cardMoons") .. "   v"
    for _, target in ipairs(petUI.targets) do target.button.Text = potionUI.summary(target.field) .. "   v" end
    potionUI.paintMenus()
    for _, id in ipairs({"luck", "haste", "gild"}) do
        potionUI.checks[id].Text = (potionConfig.selected[id] and "[x]  " or "[ ]  ") .. potionNames[id]
        potionUI.checks[id].BackgroundColor3 = potionConfig.selected[id]
            and theme.accent or theme.off
    end
end
paintPotionChoices()
function potionUI.sortChoices()
    local order = {NORMAL = 1, SILVER = 2, HARVEST = 3, BLUE = 4, ECLIPSE = 5, STARFALL = 6, AURORA = 1000}
    table.sort(potionConfig.available, function(a, b)
        local ma = potionConfig.multipliers[moonIdentity(a, true)] or math.huge
        local mb = potionConfig.multipliers[moonIdentity(b, true)] or math.huge
        if ma ~= mb then return ma < mb end
        local ra = order[moonIdentity(a, true)] or 900
        local rb = order[moonIdentity(b, true)] or 900
        return ra == rb and a < b or ra < rb
    end)
end
function potionUI.discover()
    local known = {}
    for _, name in ipairs(potionConfig.available) do known[moonIdentity(name, true)] = true end
    local root = pg:FindFirstChild("RollAStickman")
    local header = statusPlain(child(modalPanel(), {"Header", "Title"})):upper()
    local catalogModal = header:find("MOON", 1, true) or header:find("SHOP", 1, true)
    local currentTitle = header == "MOONS" and child(modalPanel(), {"Content", "Inner", "Now", "Title"})
    if currentTitle and visible(currentTitle) and modalTitle() == "MOONS" then potionUI.confirmSky(statusPlain(currentTitle)) end
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
        if key then
            local context = text:upper():match("^SUMMON ") ~= nil
            local ancestor = obj.Parent
            while ancestor and ancestor ~= root and not context do
                local name = ancestor.Name:lower()
                context = name:find("moon", 1, true) or name:find("shop", 1, true)
                    or (catalogModal and ancestor == modalPanel())
                ancestor = ancestor.Parent
            end
            if context then
                if not known[key] then
                    known[key] = true
                    table.insert(potionConfig.available, moonCaption(key))
                    added = added + 1
                end
                local amount = potionUI.readMultiplier(obj)
                if amount and potionConfig.multipliers[key] ~= amount then
                    potionConfig.multipliers[key] = amount
                    added = added + 1
                end
            end
        end
    end
    if added > 0 then
        potionUI.sortChoices()
        paintPotionChoices()
        settingsStorage = writeSettings(flags)
        log("Moon choices discovered from game UI: " .. table.concat(potionConfig.available, ", "))
    end
    return added
end
function potionUI.rebuild()
    potionUI.sortChoices()
    for _, target in ipairs(potionUI.menus()) do
        for _, entry in ipairs(target.entries) do entry:Destroy() end
        target.entries = {}
        for i, name in ipairs(potionConfig.available) do
            local key = moonIdentity(name, true)
            local entry = Instance.new("TextButton")
            entry.Name = "MoonOption_" .. key
            entry:SetAttribute("MoonKey", key)
            entry.Position = UDim2.fromOffset(4, (i - 1) * 31 + 3)
            entry.Size = UDim2.new(1, -14, 0, 28)
            entry.ZIndex = 31
            entry.BorderSizePixel = 0
            entry.Font = Enum.Font.GothamMedium
            entry.TextSize = 12
            entry.Parent = target.list
            table.insert(target.entries, entry)
            entry.Activated:Connect(function()
                if not alive then return end
                local selected = potionConfig[target.field]
                selected[key] = not selected[key] or nil
                if target.field == "moons" or target.field == "cardMoons" then
                    potionUI.completedEvent = nil
                    if target.field == "moons" then potionConfig.when = name end
                    versions.moon = versions.moon + 1
                    nextMoon = 0
                else
                    versions.pet = versions.pet + 1
                    petUI.nextCheck = 0
                    petUI.applied = nil
                end
                paintPotionChoices()
                settingsStorage = writeSettings(flags)
                log(target.field .. ": " .. name .. (selected[key] and " checked" or " unchecked"))
            end)
        end
        local height = math.min(target.maxHeight, #target.entries * 31 + 6)
        target.list.CanvasSize = UDim2.fromOffset(0, #target.entries * 31 + 6)
        target.list.Size = UDim2.fromOffset(neonUI.contentWidth, height)
        local selected = 1
        for i, name in ipairs(potionConfig.available) do
            if potionConfig[target.field][moonIdentity(name, true)] then selected = i; break end
        end
        local maximum = math.max(0, #target.entries * 31 + 6 - height)
        target.list.CanvasPosition = Vector2.new(0, math.clamp((selected - 1) * 31 - math.floor(height / 2), 0, maximum))
    end
    potionUI.entries = potionUI.primary.entries
    potionUI.paintMenus()
end
potionUI.discover()
potionUI.rebuild()
for _, target in ipairs(potionUI.menus()) do
    target.button.Activated:Connect(function()
        if alive and not minimized and activeTab == target.tab then
            potionUI.discover()
            potionUI.rebuild()
            local opening = not target.list.Visible
            for _, other in ipairs(potionUI.menus()) do other.list.Visible = false end
            target.list.Visible = opening
        end
    end)
end
function neonUI.paintWebhook()
    neonUI.webhook.toggle.Text = (potionConfig.webhookEnabled and "[x] " or "[ ] ") .. "Discord webhook: card opens"
    neonUI.webhook.toggle.BackgroundColor3 = potionConfig.webhookEnabled and theme.accent or theme.off
end
function neonUI.humanWebhook(message)
    local function field(key)
        return message:match("| " .. key .. "=([^|]+)") or "ไม่ทราบ"
    end
    local reasons = {
        CARD_BATCH_CONFIRMED="เปิดชุดการ์ดสำเร็จ ยอดคงเหลือลดลง",
        CARD_BATCH_UNCONFIRMED="ยังอ่านยอดหลังเปิดชุดล่าสุดไม่ได้ จะรอตรวจใหม่",
        MOON_NOT_SELECTED="ข้ามการ์ด: Moon นี้ไม่ได้อยู่ในรายการที่เลือก",
        CYCLE_CHECK="เริ่มตรวจเงื่อนไขเปิดการ์ด", RETRY_PENDING="รอลองใหม่ใน 30 วินาที",
        BLOCKING_WINDOW="งานรออยู่: มีหน้าต่างเกมขวาง", POTION_PAGE_UNAVAILABLE="ยังเปิดหน้า Potion ไม่สำเร็จ",
        LUCK_POTION_UNCONFIRMED="รอให้ยืนยันบัฟ Luck Potion ได้", PET_LUCK_UNCONFIRMED="ยังยืนยันบัฟ Pet Luck ไม่ได้",
        PET_PREPARE_FAILED="เตรียม Pet Luck ไม่สำเร็จ", PET_RESTORED="คืน Pet ชุดเดิมสำเร็จ",
        PET_RESTORE_UNCONFIRMED="ยังยืนยันการคืน Pet ไม่ได้", CARD_PAGE_UNAVAILABLE="เปิดหน้าการ์ดไม่สำเร็จ",
        CARD_THRESHOLD_REACHED="หยุดเปิดการ์ด: จำนวนคงเหลือต่ำกว่าค่าที่ตั้ง",
        CARDS_REMAIN="ยังมีการ์ดเหลือ หรืออ่านจำนวนคงเหลือไม่ได้",
        WORKER_STOPPED="รอบเปิดการ์ดหยุดก่อนเสร็จ", WORKER_FINISHED="รอบเปิดการ์ดเสร็จแล้ว",
        MOON_UNCONFIRMED="กำลังรอยืนยัน Moon", CARD_COUNT_UNREADABLE="อ่านจำนวนการ์ดไม่ได้",
        CARD_DISABLED_OR_MOON_EXPIRED="ข้ามการ์ด: ปิดระบบหรือ Moon หมดเวลา",
        DAILY_POPUP_CLOSED="ปิดหน้าต่างรางวัลรายวันแล้ว ทำงานต่อได้",
        DAILY_POPUP_CLOSE_FAILED="ยังปิดหน้าต่างรางวัลรายวันไม่ได้",
    }
    if message:match("^CARD CHECK") then
        local reason = field("reason"):match("^%s*(.-)%s*$")
        local potion, action = reason:match("^POTION_(%u+)_(.+)$")
        local title = reasons[reason]
        if potion then
            local actions={DRINK_PRESSED="ส่งคำสั่งใช้ยาแล้ว", EMPTY="ยาหมด", STATUS_UNREADABLE="อ่านสถานะยาไม่ได้", DRINK_UNAVAILABLE="ปุ่มใช้ยายังไม่พร้อม"}
            title = (actions[action] or "ตรวจสอบยา") .. ": " .. potion
        end
        title = title or "พบปัญหาระหว่างทำงาน"
        local function yes(key) return field(key):match("true") and "ผ่าน" or "ยังไม่ยืนยัน" end
        return "🎮 " .. title .. "\nMoon: " .. field("Moon") .. "| เหลือ " .. field("remaining") .. "วินาที"
            .. "\nLuck Potion: " .. yes("luckPotionConfirmed") .. " | Pet Luck: " .. yes("petLuckConfirmed")
            .. "\nค่า Luck: " .. field("Luck") .. "\nหน้าต่างปัจจุบัน: " .. field("modal")
            .. "\nรายละเอียด: " .. (message:match("reason=[^|]+| ([^|]*)") or "")
            .. "\nรหัสตรวจสอบ: " .. reason
    end
    if message:match("^CARD OPEN PRESSED") then
        return "🃏 ส่งคำสั่งเปิดการ์ดแล้ว (รอยืนยันยอดหลังเปิด)\n"
            .. (message:match("| ([^|]+) | batch=") or "การ์ด")
            .. " | ชุดที่ " .. field("batch") .. "\nจำนวนก่อนเปิด: " .. field("stock")
            .. "\nLuck ตอนเปิด: " .. field("Luck HUD") .. "\nMoon: " .. field("Moon")
            .. "\nPet: " .. field("Pet")
    end
    return message
end
function neonUI.queueWebhook(message, manual)
    message = neonUI.humanWebhook(message)
    local url = validWebhook(potionConfig.webhookUrl)
    if url == "" or (not manual and not potionConfig.webhookEnabled) then return false end
    if #neonUI.webhook.queue >= 50 then
        if not neonUI.webhook.fullLogged then log("WEBHOOK queue full; local card logs are retained"); neonUI.webhook.fullLogged = true end
        return false
    end
    table.insert(neonUI.webhook.queue, {url = url, manual = manual, content = message:sub(1, 1900), attempts = 0})
    if neonUI.webhook.running then return true end
    neonUI.webhook.running = true
    task.spawn(function()
        local function waitUntil(deadline)
            while alive and os.clock() < deadline do task.wait(math.min(1, deadline - os.clock())) end
        end
        local ok = pcall(function()
            while alive and #neonUI.webhook.queue > 0 do
                waitUntil(neonUI.webhook.nextSendAt)
                if not alive then break end
                local job = table.remove(neonUI.webhook.queue, 1)
                if job.url == validWebhook(potionConfig.webhookUrl) and (job.manual or potionConfig.webhookEnabled) then
                    local transport = type(request) == "function" and request
                        or type(http_request) == "function" and http_request
                        or type(syn) == "table" and type(syn.request) == "function" and syn.request
                        or type(http) == "table" and type(http.request) == "function" and http.request
                    if not transport then
                        neonUI.webhook.status.Text = "Webhook: executor HTTP request unavailable"
                        log("WEBHOOK unavailable: executor HTTP request missing")
                        neonUI.webhook.queue = {}
                        break
                    end
                    job.attempts = job.attempts + 1
                    local sent, response = pcall(transport, {Url = job.url, Method = "POST",
                        Headers = {["Content-Type"] = "application/json"},
                        Body = HttpService:JSONEncode({content = job.content, allowed_mentions = {parse = {}}})})
                    local code = sent and type(response) == "table" and tonumber(response.StatusCode or response.Status) or nil
                    local headers = {}
                    for key, value in pairs(sent and type(response) == "table" and type(response.Headers) == "table" and response.Headers or {}) do headers[tostring(key):lower()] = value end
                    neonUI.webhook.nextSendAt = os.clock() + 0.5
                    if code and code >= 200 and code < 300 then
                        neonUI.webhook.status.Text = "Webhook: sent (HTTP " .. code .. ")"
                        log("WEBHOOK sent | HTTP " .. code)
                        if tonumber(headers["x-ratelimit-remaining"]) == 0 then
                            neonUI.webhook.nextSendAt = os.clock() + math.max(0.5, tonumber(headers["x-ratelimit-reset-after"]) or 2)
                        end
                    elseif code == 429 then
                        local decoded, body = pcall(function() return HttpService:JSONDecode(response.Body or "{}") end)
                        local delay = tonumber(headers["retry-after"]) or (decoded and type(body) == "table" and tonumber(body.retry_after)) or 3
                        if delay ~= delay or delay == math.huge or delay < 0 then delay = 3 end
                        neonUI.webhook.nextSendAt = os.clock() + math.max(0.5, delay)
                        if job.attempts < 3 then
                            table.insert(neonUI.webhook.queue, 1, job)
                            neonUI.webhook.status.Text = "Webhook: Discord rate limit; queued"
                        else
                            neonUI.webhook.status.Text = "Webhook: retry limit; local card logs retained"
                        end
                        log("WEBHOOK rate limited; waiting " .. delay .. "s")
                    else
                        neonUI.webhook.status.Text = "Webhook: " .. (code and ("HTTP " .. code) or "transport failed")
                        log("WEBHOOK failed | " .. (code and ("HTTP " .. code) or "transport error"))
                        if code == 401 or code == 403 or code == 404 then
                            potionConfig.webhookEnabled = false
                            neonUI.webhook.queue = {}
                            neonUI.paintWebhook()
                            settingsStorage = writeSettings(flags)
                        end
                    end
                end
            end
        end)
        neonUI.webhook.running = false
        neonUI.webhook.fullLogged = false
        if not ok and alive then
            neonUI.webhook.status.Text = "Webhook: worker error; local card logs retained"
            log("WEBHOOK worker failed; URL and response details omitted")
        end
    end)
    return true
end
function neonUI.saveWebhookUrl()
    local typed = neonUI.webhook.url.Text
    local url = validWebhook(typed)
    if url == "" and typed:match("%S") then
        potionConfig.webhookEnabled = false
        neonUI.webhook.queue = {}
        neonUI.paintWebhook()
        settingsStorage = writeSettings(flags)
        neonUI.webhook.status.Text = "Webhook: enter a valid Discord webhook URL"
        return false
    end
    potionConfig.webhookUrl = url
    if url == "" then potionConfig.webhookEnabled = false end
    neonUI.paintWebhook()
    settingsStorage = writeSettings(flags)
    return url ~= ""
end
neonUI.webhook.url.Text = potionConfig.webhookUrl
neonUI.paintWebhook()
neonUI.webhook.status.Text = potionConfig.webhookEnabled and "Webhook: ON; card-open reports enabled" or "Webhook: OFF"
neonUI.webhook.url.FocusLost:Connect(neonUI.saveWebhookUrl)
neonUI.webhook.toggle.Activated:Connect(function()
    if potionConfig.webhookEnabled then potionConfig.webhookEnabled = false
    elseif neonUI.saveWebhookUrl() then potionConfig.webhookEnabled = true end
    neonUI.paintWebhook()
    neonUI.webhook.status.Text = potionConfig.webhookEnabled and "Webhook: ON; card-open reports enabled" or "Webhook: OFF"
    settingsStorage = writeSettings(flags)
end)
neonUI.webhook.test.Activated:Connect(function()
    if neonUI.saveWebhookUrl() then
        neonUI.queueWebhook("Roll A Stickman R40 | Webhook test | " .. os.date("!%Y-%m-%dT%H:%M:%SZ"), true)
        neonUI.webhook.status.Text = "Webhook: test queued"
    end
end)
function neonUI.paintIntervals()
    petUI.every.box.Text = tostring(potionConfig.petPlayEveryMinutes)
    petUI.playToggle.Text = (potionConfig.petPlayEnabled and "[x] " or "[ ] ") .. "Boost cards from play"
    petUI.playToggle.BackgroundColor3 = potionConfig.petPlayEnabled and theme.accent or theme.off
    neonUI.moonEvery.box.Text = tostring(potionConfig.moonInspectMinutes)
    gui:SetAttribute("MoonHudOnly", false)
    gui:SetAttribute("MoonCountdownTracking", true)
    gui:SetAttribute("MoonInspectMinutes", potionConfig.moonInspectMinutes)
end
function neonUI.changeInterval(field, value)
    local updated = minutes(value, potionConfig[field])
    if updated ~= potionConfig[field] then
        potionConfig[field] = updated
        if field == "petPlayEveryMinutes" then
            petUI.nextPlayAt = petUI.lastPlayAt and petUI.lastPlayAt + updated * 60 or 0
            petUI.nextCheck = 0
            versions.pet = versions.pet + 1
        else
            potionUI.retryAt = potionUI.retryAt and math.min(potionUI.retryAt, os.clock() + updated * 60) or 0
            nextMoon, petUI.nextCheck = 0, 0
            versions.moon, versions.pet = versions.moon + 1, versions.pet + 1
        end
        settingsStorage = writeSettings(flags)
        log(field .. " = " .. updated .. " minutes")
    end
    neonUI.paintIntervals()
end
for _, spec in ipairs({{petUI.every, "petPlayEveryMinutes"}, {neonUI.moonEvery, "moonInspectMinutes"}}) do
    local control, field = spec[1], spec[2]
    control.minus.Activated:Connect(function() neonUI.changeInterval(field, potionConfig[field] - 1) end)
    control.plus.Activated:Connect(function() neonUI.changeInterval(field, potionConfig[field] + 1) end)
    control.box.FocusLost:Connect(function() neonUI.changeInterval(field, control.box.Text) end)
end
petUI.playToggle.Activated:Connect(function()
    potionConfig.petPlayEnabled = not potionConfig.petPlayEnabled
    petUI.nextCheck = 0
    versions.pet = versions.pet + 1
    neonUI.paintIntervals()
    settingsStorage = writeSettings(flags)
end)
neonUI.paintIntervals()
neonUI.moonSync.Activated:Connect(function()
    if not alive then return end
    potionUI.scanRequested = true
    note("Manual Moon inspection queued")
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
        nextMoon, petUI.nextCheck = 0, 0
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
        potionUI.completedEvent = nil
        nextMoon = 0
        paintPotionChoices()
        settingsStorage = writeSettings(flags)
        log(potionNames[id] .. (potionConfig.selected[id] and " selected" or " unchecked"))
    end)
end

function cardUI.belowLimit(count)
    return count ~= nil and cardSelection.stopBelow > 0 and count < cardSelection.stopBelow
end
cardUI.stopBelow.Text = tostring(cardSelection.stopBelow)
cardUI.stopBelow.FocusLost:Connect(function()
    local value = tonumber(cardUI.stopBelow.Text:gsub(",", ""))
    if value and value == value and value >= 0 and value < math.huge then
        cardSelection.stopBelow = math.floor(value)
        potionUI.completedEvent = nil
        versions.moon = versions.moon + 1
        nextMoon = 0
        settingsStorage = writeSettings(flags)
    end
    cardUI.stopBelow.Text = tostring(cardSelection.stopBelow)
end)
function cardUI.paint()
    for _, id in ipairs({"loose", "pouch", "crate", "chest"}) do
        cardUI.checks[id].Text = (cardSelection[id] and "[x]  " or "[ ]  ") .. cardUI.names[id]
        cardUI.checks[id].BackgroundColor3 = cardSelection[id] and theme.accent or theme.off
    end
    cardUI.requireLuck.Text = (cardSelection.requireLuck and "[x] " or "[ ] ") .. "Require active Luck Potion"
    cardUI.requirePet.Text = (cardSelection.requirePet and "[x] " or "[ ] ") .. "Require active Pet Luck"
end
cardUI.paint()
for _, field in ipairs({"requireLuck", "requirePet"}) do
    cardUI[field].Activated:Connect(function()
        cardSelection[field] = not cardSelection[field]
        versions.moon = versions.moon + 1
        potionUI.completedEvent = nil
        nextMoon = 0
        cardUI.paint()
        settingsStorage = writeSettings(flags)
        log("Open Card " .. field .. "=" .. tostring(cardSelection[field]))
    end)
end
for _, id in ipairs({"loose", "pouch", "crate", "chest"}) do
    cardUI.checks[id].Activated:Connect(function()
        cardSelection[id] = not cardSelection[id]
        versions.moon = versions.moon + 1
        potionUI.completedEvent = nil
        moonCardsDone = false
        nextMoon = 0
        cardUI.paint()
        settingsStorage = writeSettings(flags)
        log(cardUI.names[id] .. (cardSelection[id] and " selected for Open Card" or " unchecked for Open Card"))
    end)
end

petUI.capture.Activated:Connect(function()
    if petUI.capturePending then return end
    petUI.capturePending = true
    petUI.capture.Text = "HOVER A PET NOW..."
    note("Capturing Pet UI in 3s; hover a pet to show its bonus stats")
    task.delay(3, function()
    petUI.capturePending = false
    if not alive then return end
    petUI.capture.Text = "CAPTURE (3s)"
    petUI.report = petUI.report or {}
    petUI.captureCount = (petUI.captureCount or 0) + 1
    local function pathOf(obj)
        local parts = {}
        while obj and obj ~= pg do table.insert(parts, 1, obj.Name); obj = obj.Parent end
        return table.concat(parts, ".")
    end
    local function report(value)
        if #petUI.report >= 2000 then return end
        table.insert(petUI.report, value)
        log(value)
    end
    local function attributes(obj)
        local ok, attrs = pcall(function() return obj:GetAttributes() end)
        if ok and type(attrs) == "table" and next(attrs) then
            local encoded, value = pcall(function() return HttpService:JSONEncode(attrs) end)
            if encoded then return " | attrs=" .. value end
        end
        return ""
    end
    local function capture(root, prefix, skipGrid)
        local count = 0
        for _, obj in ipairs(root and root:GetDescendants() or {}) do
            local excluded = false
            local ancestor = obj
            while ancestor and ancestor ~= root do
                if ancestor.Name == "Eggs" or (skipGrid and ancestor.Name == "Grid") then excluded = true; break end
                ancestor = ancestor.Parent
            end
            if not excluded and visible(obj) then
                local value = statusPlain(obj)
                if value ~= "" or obj:IsA("ImageLabel") or obj:IsA("ImageButton") then
                    local owner = obj
                    while owner and owner ~= pg and not owner:IsA("GuiButton") do owner = owner.Parent end
                    local text = value ~= "" and value:sub(1, 500) or ("Image=" .. tostring(obj.Image))
                    report(prefix .. " | " .. pathOf(obj) .. " | " .. text
                        .. (owner and owner:IsA("GuiButton") and (" | button=" .. pathOf(owner) .. " Active=" .. tostring(owner.Active)) or "")
                        .. attributes(obj))
                    count = count + 1
                    if count >= 250 then report(prefix .. " | limited to 250 fields"); break end
                end
            end
        end
    end
    report("PET CAPTURE " .. petUI.captureCount .. " | modal=" .. modalTitle() .. " | Pet Luck active=" .. tostring(petUI.luckActive()))
    local stats = petUI.equippedStats()
    if stats then report("PET EQUIPPED | " .. stats.text) end
    local screen = page()
    local grid = child(screen, {"Grid"})
    for _, obj in ipairs(grid and grid:GetChildren() or {}) do
        if obj:IsA("GuiButton") then
            report("PET OWNED | " .. pathOf(obj)
                .. " | name=" .. statusPlain(child(obj, {"Name"}))
                .. " | level=" .. statusPlain(child(obj, {"Level"}))
                .. " | copies=" .. statusPlain(child(obj, {"Copies"}))
                .. " | tag=" .. statusPlain(child(obj, {"Tag"}))
                .. attributes(obj))
        end
    end
    capture(screen, "PET PAGE", true)
    if modalOpen() then capture(modalPanel(), "PET DETAIL", false) end
    local root = pg:FindFirstChild("RollAStickman")
    local function isDetail(obj)
        local name = obj.Name:lower()
        return name:find("tooltip", 1, true) or name:find("preview", 1, true)
            or name:find("inspect", 1, true) or name:find("detail", 1, true)
    end
    for _, obj in ipairs(root and root:GetDescendants() or {}) do
        if obj:IsA("GuiObject") and visible(obj) and isDetail(obj) then
            local parent, nested = obj.Parent, false
            while parent and parent ~= root do
                if isDetail(parent) then nested = true; break end
                parent = parent.Parent
            end
            if not nested then capture(obj, "PET TOOLTIP", false) end
        end
    end
    capture(get({"Frame", "Buffs"}), "PET BUFF", false)
    if type(writefile) == "function" then
        local ok = pcall(writefile, "RollStickman_PetUI_Report.txt", table.concat(petUI.report, "\n"))
        if ok then log("Pet report also saved to RollStickman_PetUI_Report.txt") end
    end
    petUI.help.Text = "Pet report captured. Select another pet to show its stats and capture again; COPY LOG includes every capture."
    note("Pet detail report captured; COPY LOG")
    end)
end)

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
    neonUI.sky.Text = statusCache.aura and cachedStatus("aura") or "No confirmed Moon yet. Press SYNC to inspect."
    neonUI.timer.Text = "Sky countdown: " .. cachedStatus("moonTimer")
    petUI.schedule.Text = flags.pet and potionConfig.petPlayEnabled
        and "Pet: Luck before cards, restore after cards" or "Pet cycle: OFF"
    local confirmed = potionUI.confirmed
    local left = confirmed and math.max(0, math.ceil(confirmed.untilTime - now)) or 0
    neonUI.moonPolicy.Text = left > 0 and ("Moon confirmed; next inspection in " .. left .. "s. No repeated window while the countdown is valid.")
        or "Moon unknown / expired: inspect automatically. The minute setting is used only after a failed read."
    neonUI.storage.Text = "Settings storage: " .. settingsStorage .. " | Dungeon recheck: 2 hours"
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
    local pets = petUI.equippedStats()
    put("petLuck", pets and (pets.text .. " | observed " .. math.floor(now - pets.at) .. "s ago")
        or "Open PETS to read equipped luck / rolls-from-play bonuses")
    cardUI.stock.Text = cachedStatus("cards")
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

function neonUI.dismissDaily(now)
    local title = modalTitle()
    local daily = {['DAILY REWARDS']=true, ['DAILY REWARD']=true, ['DAILY LOGIN']=true, ['DAILY LOGIN REWARDS']=true}
    if not daily[title] or now < (neonUI.nextDailyClose or 0) then return end
    neonUI.nextDailyClose = now + 10
    if closeModal("daily.close") then
        task.wait(0.4)
        cardUI.diagnose(modalTitle() ~= title and "DAILY_POPUP_CLOSED" or "DAILY_POPUP_CLOSE_FAILED", title)
    else
        cardUI.diagnose("DAILY_POPUP_CLOSE_FAILED", title)
    end
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
log("Combined V1.2 R40 Neon V2 ready | restored from " .. (settingsSource or "defaults")
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
            if not busy then neonUI.dismissDaily(now) end
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
            if not busy and flags.raid and not modalOpen() and now >= nextRaid then
                raidTick()
            end
            if not busy and flags.arena and not inDungeon() and not modalOpen()
                and now >= (neonUI.nextArena or 0) then
                neonUI.nextArena = now + 7200
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
                        if not waveBattle() then return end
                        if not fire("arena.tab", get({"Frame","Nav","Row","arena"}), "ARENA") then return end
                    end
                    local function returnToBattle()
                        local untilTime = os.clock() + 9
                        repeat
                            fire("arena.back", get({"Frame","Nav","Row","endless"}), nil, 1)
                            task.wait(0.25)
                            if waveBattle() then return end
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
                    local deadline = os.clock() + 12
                    repeat
                        task.wait(0.25)
                        if not valid("arena", version) or modalOpen() then return end
                        local screen = get({"Frame","Page","Column","Screen"})
                        local confirmed = false
                        if visible(screen) then
                            if quotaEmpty(screen) then
                                neonUI.nextArena = os.clock() + 7200
                                note("Arena quota empty; next check in 2h")
                                returnToBattle()
                                return
                            end
                            for _, item in ipairs(screen:GetDescendants()) do
                                if visible(item) and textOf(item):find("ARENA", 1, true) then confirmed = true break end
                            end
                            for _, item in ipairs(screen:GetDescendants()) do
                                if ready(item) then
                                    local name = buttonText(item)
                                    if name ~= "" then labels[name] = true end
                                    if name == "FIND OPPONENTS" and not opponentsRequested then
                                        if fire("arena.find", item, name, 10) then
                                            opponentsRequested = true
                                            neonUI.nextArena = os.clock() + 120
                                            deadline = os.clock() + 12
                                            note("Arena finding opponents")
                                            break
                                        end
                                    end
                                    if (confirmed or opponentsRequested) and (name == "FIGHT" or name == "BATTLE" or name == "CHALLENGE"
                                        or name == "JOIN" or name == "START" or name == "FIGHT AGAIN") then
                                        if fire("arena.fight", item, name) then
                                            neonUI.nextArena = os.clock() + 120
                                            note("Arena quota available; next check in 2m")
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
                                            local finishDeadline = os.clock() + 120
                                            repeat
                                                task.wait(0.5)
                                                if not valid("arena", version) then return end
                                                if not modalOpen() and (arenaPage() or waveBattle()) then
                                                    note("Arena returned; result not verified")
                                                    if arenaPage() then
                                                        fire("arena.back", get({"Frame","Nav","Row","endless"}))
                                                    end
                                                    neonUI.nextArena = os.clock() + 120
                                                    return
                                                end
                                            until os.clock() >= finishDeadline
                                            note("Arena return timeout; inspect current battle or result window")
                                            neonUI.nextArena = os.clock() + 120
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
                    fire("arena.back", get({"Frame","Nav","Row","endless"}))
                end)
            end
            if not busy and flags.level and not modalOpen() and now >= nextLevel then
                run("level", levelTick)
            end
            if not busy and (flags.moon or flags.cards) and not inDungeon() and
                now >= nextMoon then
                run("moon", moonTick)
            end
            if not busy and flags.pet and not inDungeon() and not modalOpen()
                and not potionUI.cycle and not petUI.scanRequested and now >= petUI.nextCheck then
                petUI.nextCheck = now + 300
                run("pet", function(version)
                    local function check() return alive and flags.pet and versions.pet == version and not potionUI.cycle end
                    local ok = petUI.ensureRole("play", "IDLE", check)
                    if not ok then petUI.nextCheck = os.clock() + 30 end
                    potionUI.closeCycleWindow()
                    if check() and not modalOpen() then
                        fire("pet.idle.back", get({"Frame", "Nav", "Row", "endless"}), nil, 1)
                    end
                end)
            end
            if not busy and not inDungeon() and petUI.scanRequested then
                local manual = petUI.scanRequested
                petUI.scanRequested = false
                run("pet", function(version) petUI.tick(version, manual) end)
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
