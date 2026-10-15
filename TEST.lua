--// MM2 MENU BY ARBUZ v1.2.1

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local LocalizationService = game:GetService("LocalizationService")

local RAINBOW_SPEED = 0.25
local ALARM_TIME_COOLDOWN = 6
local ALARM_DIST_STEP = 5
local SCRIPT_VERSION = "v1.2.1"
local SCRIPT_AUTHOR = "Arbuz"

-- ═══════════════════════════════════════════════════════════
-- CHANGELOG - add new entries at the TOP
-- ═══════════════════════════════════════════════════════════
local CHANGELOG = {
    {
        version = "v1.2.1",
        date = "2026-10-16",
        changes = {
            "Added Home tab (first tab) with live status card",
            "Added What's New modal with full changelog",
            "Added session stats tracking (kills, deaths, rounds, roles)",
            "Added notification history (last 10)",
            "Added Active Keybinds quick reference on Home",
            "Added Script Info + Server Info cards on Home",
            "Added Copy Loadstring button",
            "Added Panic button (off everything + minimize)",
            "Moved Turn Off All / PVP Ready / Restore to Home tab",
            "Fixed mobile crosshair notification text",
            "Fixed auto chat sending your own name (shows self-notify instead)",
            "Slowed killer alarm (6s cooldown, 5-stud step)",
            "Added Menu Sound + Kill Sound volume sliders",
            "Reduced whitespace across all tabs",
        },
    },
    {
        version = "v1.2",
        date = "2026-10-16",
        changes = {
            "Mobile-responsive UI scaling (0.68x on mobile)",
            "Fixed fly movement on mobile (touch joystick support)",
            "Fixed fly panel +/DOWN button alignment on mobile",
            "Custom crosshair now follows finger (multi-touch aware)",
            "Role notify delay (2.5s) prevents split notifications",
            "Fixed own username not showing when you are Sheriff",
            "Disabled crosshair on mobile with helpful message",
            "Added sound volume sliders in Settings",
            "Killer alarm 6s cooldown + 5-stud step",
            "Added Restore Before PVP button",
            "Added Enable All Notifications button",
        },
    },
    {
        version = "v1.1",
        date = "2026-10-15",
        changes = {
            "Added PVP Ready preset",
            "Added role trails (Killer / Sheriff / Hero)",
            "Added Camera Follow Murderer",
            "Added keybind system",
            "Added Menu Opacity slider",
        },
    },
    {
        version = "v1.0",
        date = "2026-10-15",
        changes = {
            "Initial release",
            "Movement: Noclip, Fly, Speedhack, Infinity Jump, Fling",
            "ESP: Role ESP, Gun ESP, Player distance",
            "Notifier: Auto roles, round events, chat announcements",
            "Murderer: Kill all, kill sheriff/hero",
            "Sheriff: Shoot murderer",
            "Teleport: Player, role, world teleports",
            "Utility: Anti void/fling/afk, killer alarm, crosshair",
            "Server: Rejoin, Server hop",
        },
    },
}

local SOUNDS = {
    notify = "rbxassetid://12221967",
    alert = "rbxassetid://131961136",
    success = "rbxassetid://5801257793",
    round = "rbxassetid://130972023882",
}

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local IS_MOBILE = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
local MS = IS_MOBILE and 0.68 or 1
local function mn(n) return math.floor(n * MS + 0.5) end
local function msz(x, y) return UDim2.fromOffset(mn(x), mn(y)) end
local function mpos(x, y) return UDim2.fromOffset(mn(x), mn(y)) end

local function fmtTime(secs)
    secs = math.max(0, math.floor(secs))
    local h = math.floor(secs / 3600)
    local m = math.floor((secs % 3600) / 60)
    local s = secs % 60
    return string.format("%02d:%02d:%02d", h, m, s)
end

local function fmtAgo(t)
    local elapsed = tick() - t
    if elapsed < 60 then return math.floor(elapsed) .. "s ago" end
    if elapsed < 3600 then return math.floor(elapsed / 60) .. "m ago" end
    return math.floor(elapsed / 3600) .. "h ago"
end

local S = {
    noclip = false, infinityJump = false, flingOnTouch = false, flingThirdParty = false,
    flyEnabled = false, autoNotifyRoles = false, autoKillAll = false, autoGunTP = false,
    autoSendMurdererChat = false, autoSendSheriffChat = false, antiVoidEnabled = false,
    antiFlingEnabled = false, antiAfkEnabled = false, antiAfkConn = nil,
    playerDistanceOn = false, playerDistBillboards = {},
    killerAlarmOn = false, lastAlarmDist = math.huge, lastAlarmTime = 0,
    crosshairOn = false, crosshairGui = nil,
    keybindsEnabled = true, scriptClosed = false,
    lastTouchPos = nil, mousePos = nil,
    activeTouches = {},
    gunDropAlert = false, lastGunDropped = false,
    notifyRoundStart = false, notifyRoundEnd = false,
    playerJoinLeaveNotify = false,
    menuOpacity = 100,
    menuVolume = 100,
    killVolume = 100,
    killerTrailOn = false, sheriffTrailOn = false, heroTrailOn = false,
    cameraFollowMurderer = false,
    killSoundOn = false,
    lastKnownMurderer = nil,
    flySpeed = 50, speedhackEnabled = false, speedhackSpeed = 45,
    guiLocked = false, flyPanelLocked = false, minimized = false, menuVisible = true,
    espEnabled = { Innocent = false, Murderer = false, Sheriff = false, Hero = false },
    gunESPEnabled = false, gunHighlights = {}, originalCollision = {},
    lastChatSentMurderer = nil, lastChatSentSheriff = nil,
    selfNotifyMurderer = false, selfNotifySheriff = false,
    roundActive = false, roundActiveSheriff = false, chatSendCooldown = 0, chatSendCooldownSheriff = 0,
    flyPanelOpen = false, flingTouchActive = false, flingTouchThread = nil,
    dropdownOpen = false, selectedPlayer = nil,
    resizing = false, dragging = false, reopenDragging = false, flyDragging = false,
    lastSafePosition = nil, lastSafeUpdate = 0, antiVoidCooldown = false,
    VOID_Y_THRESHOLD = -50, ANTI_FLING_MAX_SPEED = 200, ANTI_FLING_MAX_ANGULAR = 500,
    pendingNotify = false, pendingNotifySince = 0,
    capturingKeybind = false, capturingAction = nil,
    reopenDragDist = 0,
    hopping = false,
    pvpSnapshot = nil,
    -- Home tab additions
    sessionStart = tick(),
    notificationHistory = {},
    stats = { kills = 0, deaths = 0, rounds = 0, asMurderer = 0, asSheriff = 0 },
    statsCountedMurderer = false,
    statsCountedSheriff = false,
    whatsNewAutoShown = false,
    homeRebuildDirty = true,
    keybinds = {
        fly = Enum.KeyCode.LeftAlt, noclip = Enum.KeyCode.N, speedhack = Enum.KeyCode.Q,
        infinityJump = Enum.KeyCode.J, autoKillAll = Enum.KeyCode.K, gunESP = Enum.KeyCode.G,
        murdererESP = Enum.KeyCode.M, sheriffESP = Enum.KeyCode.H, innocentESP = Enum.KeyCode.I,
        antiVoid = Enum.KeyCode.B, turnOffAll = Enum.KeyCode.Y,
    },
    keybindList = {
        {id = "fly", name = "Toggle Fly"}, {id = "noclip", name = "Toggle Noclip"},
        {id = "speedhack", name = "Toggle Speedhack"}, {id = "infinityJump", name = "Toggle Infinity Jump"},
        {id = "autoKillAll", name = "Toggle Auto Kill All"}, {id = "gunESP", name = "Toggle Gun ESP"},
        {id = "murdererESP", name = "Toggle Murderer ESP"}, {id = "sheriffESP", name = "Toggle Sheriff ESP"},
        {id = "innocentESP", name = "Toggle Innocent ESP"}, {id = "antiVoid", name = "Toggle Anti Void"},
        {id = "turnOffAll", name = "Turn Off All"},
    },
}

local ROLE_COLORS = {
    Innocent = Color3.fromRGB(50, 210, 90), Murderer = Color3.fromRGB(230, 55, 55),
    Sheriff = Color3.fromRGB(55, 140, 255), Hero = Color3.fromRGB(255, 205, 50),
}
local GUN_COLOR = Color3.fromRGB(170, 90, 230)

local MurdererName = nil
local SheriffName = nil
local HeroName = nil
local lastNotifiedMurderer = nil
local lastNotifiedSheriff = nil
local lastNotifiedHero = nil
local noMurdererSince = nil
local ROUND_END_DEBOUNCE = 2.0
local ROLE_NOTIFY_DELAY = 2.5

local GetPlayerData = nil
pcall(function() GetPlayerData = ReplicatedStorage:FindFirstChild("GetPlayerData", true) end)
local warnedNoRemote = false

local cachedSpawns = {}
local highlights = {}
local espButtons = {}
local lastGunScan = 0
local GUN_SCAN_INTERVAL = 0.5
local lastAutoGunTP = 0
local currentLayoutOrder = 0
local currentParent = nil

-- Forward declarations
local resetAllToggles
local applyPvpPreset
local restorePvpSnapshot
local minimizeMenu
local showMenu
local openWhatsNew

local function playSound(id, baseVol, isKill)
    baseVol = baseVol or 1
    local volPercent = isKill and (S.killVolume or 100) or (S.menuVolume or 100)
    local finalVol = baseVol * (volPercent / 100)
    if finalVol <= 0 then return end
    local snd = Instance.new("Sound")
    snd.SoundId = id or SOUNDS.notify
    snd.Volume = finalVol
    snd.Parent = playerGui
    snd:Play()
    task.delay(4, function() if snd then snd:Destroy() end end)
end

local function sendNotification(title, text, soundId)
    pcall(function() StarterGui:SetCore("SendNotification", {Title=title, Text=text, Duration=5}) end)
    table.insert(S.notificationHistory, 1, {title = title, text = text, time = tick()})
    while #S.notificationHistory > 10 do
        table.remove(S.notificationHistory)
    end
    if S.homeRebuildDirty ~= nil then S.homeRebuildDirty = true end
    playSound(soundId or SOUNDS.notify, 1, false)
end

local function getLayoutOrder()
    currentLayoutOrder = currentLayoutOrder + 1
    return currentLayoutOrder
end

local U = {}
U.homeRefs = {}

local existing = playerGui:FindFirstChild("MM2MenuByArbuz")
if existing then existing:Destroy() end

U.gui = Instance.new("ScreenGui")
U.gui.Name = "MM2MenuByArbuz"
U.gui.ResetOnSpawn = false
U.gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
U.gui.DisplayOrder = 100
U.gui.Parent = playerGui

U.canvas = Instance.new("CanvasGroup")
U.canvas.Name = "Canvas"
U.canvas.Size = UDim2.new(1, 0, 1, 0)
U.canvas.BackgroundTransparency = 1
U.canvas.GroupTransparency = 0
U.canvas.Parent = U.gui

U.frame = Instance.new("Frame")
U.frame.Name = "Main"
U.frame.Size = msz(460, 380)
U.frame.Position = UDim2.new(0.5, -mn(230), 0.5, -mn(190))
U.frame.BackgroundColor3 = Color3.fromRGB(22, 23, 28)
U.frame.BorderSizePixel = 0
U.frame.Active = true
U.frame.Parent = U.canvas
do
    local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 12) c.Parent = U.frame
    U.frameStroke = Instance.new("UIStroke")
    U.frameStroke.Color = Color3.fromRGB(55, 57, 65)
    U.frameStroke.Thickness = 1
    U.frameStroke.Parent = U.frame
end

U.header = Instance.new("Frame")
U.header.Name = "Header"
U.header.Size = UDim2.new(1, 0, 0, mn(44))
U.header.BackgroundColor3 = Color3.fromRGB(29, 30, 37)
U.header.BorderSizePixel = 0
U.header.Active = true
U.header.Parent = U.frame
do local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 12) c.Parent = U.header end

U.title = Instance.new("TextLabel")
U.title.Size = UDim2.new(1, -mn(120), 1, 0)
U.title.Position = mpos(10, 0)
U.title.BackgroundTransparency = 1
U.title.Text = "MM2 MENU BY ARBUZ " .. SCRIPT_VERSION
U.title.TextColor3 = Color3.fromRGB(255, 255, 255)
U.title.TextSize = mn(13)
U.title.Font = Enum.Font.GothamBold
U.title.TextXAlignment = Enum.TextXAlignment.Left
U.title.TextYAlignment = Enum.TextYAlignment.Center
U.title.ZIndex = 2
U.title.Parent = U.header

U.titleGradient = Instance.new("UIGradient")
U.titleGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 90, 90)),
    ColorSequenceKeypoint.new(0.2, Color3.fromRGB(255, 220, 90)),
    ColorSequenceKeypoint.new(0.4, Color3.fromRGB(90, 255, 120)),
    ColorSequenceKeypoint.new(0.6, Color3.fromRGB(90, 200, 255)),
    ColorSequenceKeypoint.new(0.8, Color3.fromRGB(210, 110, 255)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 90, 90)),
})
U.titleGradient.Parent = U.title

U.close = Instance.new("TextButton")
U.close.Size = msz(28, 28)
U.close.Position = UDim2.new(1, -mn(98), 0.5, -mn(14))
U.close.BackgroundColor3 = Color3.fromRGB(42, 44, 52)
U.close.Text = "X"
U.close.TextSize = mn(15)
U.close.TextColor3 = Color3.fromRGB(255, 200, 200)
U.close.Font = Enum.Font.GothamBold
U.close.BorderSizePixel = 0
U.close.AutoButtonColor = false
U.close.ZIndex = 5
U.close.Parent = U.header
do local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 7) c.Parent = U.close end

U.lock = Instance.new("TextButton")
U.lock.Size = msz(28, 28)
U.lock.Position = UDim2.new(1, -mn(66), 0.5, -mn(14))
U.lock.BackgroundColor3 = Color3.fromRGB(42, 44, 52)
U.lock.Text = "🔓"
U.lock.TextSize = mn(13)
U.lock.TextColor3 = Color3.new(1, 1, 1)
U.lock.Font = Enum.Font.GothamBold
U.lock.BorderSizePixel = 0
U.lock.AutoButtonColor = false
U.lock.ZIndex = 5
U.lock.Parent = U.header
do local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 7) c.Parent = U.lock end

U.minimize = Instance.new("TextButton")
U.minimize.Size = msz(28, 28)
U.minimize.Position = UDim2.new(1, -mn(34), 0.5, -mn(14))
U.minimize.BackgroundColor3 = Color3.fromRGB(42, 44, 52)
U.minimize.Text = "-"
U.minimize.TextColor3 = Color3.new(1, 1, 1)
U.minimize.TextSize = mn(16)
U.minimize.Font = Enum.Font.GothamBold
U.minimize.BorderSizePixel = 0
U.minimize.AutoButtonColor = false
U.minimize.ZIndex = 5
U.minimize.Parent = U.header
do local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 7) c.Parent = U.minimize end

U.resize = Instance.new("TextButton")
U.resize.Size = msz(16, 16)
U.resize.Position = UDim2.new(1, -mn(16), 1, -mn(16))
U.resize.BackgroundColor3 = Color3.fromRGB(55, 57, 65)
U.resize.BorderSizePixel = 0
U.resize.Text = ""
U.resize.AutoButtonColor = false
U.resize.ZIndex = 30
U.resize.Parent = U.frame
do local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 4) c.Parent = U.resize end

U.reopen = Instance.new("TextButton")
U.reopen.Size = msz(50, 50)
U.reopen.Position = UDim2.new(0, mn(15), 0.5, -mn(25))
U.reopen.BackgroundColor3 = Color3.fromRGB(29, 30, 37)
U.reopen.BorderSizePixel = 0
U.reopen.Text = "MM2"
U.reopen.TextColor3 = Color3.fromRGB(245, 245, 250)
U.reopen.TextSize = mn(13)
U.reopen.Font = Enum.Font.GothamBold
U.reopen.AutoButtonColor = false
U.reopen.Visible = false
U.reopen.ZIndex = 50
U.reopen.Parent = U.gui
do
    local c = Instance.new("UICorner") c.CornerRadius = UDim.new(1, 0) c.Parent = U.reopen
    U.reopenStroke = Instance.new("UIStroke")
    U.reopenStroke.Color = Color3.fromRGB(80, 82, 90)
    U.reopenStroke.Thickness = 2
    U.reopenStroke.Parent = U.reopen
end

U.sidebar = Instance.new("ScrollingFrame")
U.sidebar.Name = "Sidebar"
U.sidebar.Size = UDim2.new(0, mn(96), 1, -mn(58))
U.sidebar.Position = mpos(8, 50)
U.sidebar.BackgroundTransparency = 1
U.sidebar.BorderSizePixel = 0
U.sidebar.ScrollBarThickness = 3
U.sidebar.ScrollBarImageColor3 = Color3.fromRGB(75, 77, 85)
U.sidebar.AutomaticCanvasSize = Enum.AutomaticSize.Y
U.sidebar.ScrollingDirection = Enum.ScrollingDirection.Y
U.sidebar.Parent = U.frame
do
    local l = Instance.new("UIListLayout")
    l.Padding = UDim.new(0, 2)
    l.SortOrder = Enum.SortOrder.LayoutOrder
    l.Parent = U.sidebar
end

U.rightArea = Instance.new("Frame")
U.rightArea.Name = "RightArea"
U.rightArea.Size = UDim2.new(1, -mn(120), 1, -mn(58))
U.rightArea.Position = mpos(112, 50)
U.rightArea.BackgroundTransparency = 1
U.rightArea.Parent = U.frame

U.searchBox = Instance.new("TextBox")
U.searchBox.Size = UDim2.new(1, 0, 0, mn(26))
U.searchBox.BackgroundColor3 = Color3.fromRGB(34, 36, 43)
U.searchBox.BorderSizePixel = 0
U.searchBox.Text = ""
U.searchBox.PlaceholderText = "Search..."
U.searchBox.TextColor3 = Color3.fromRGB(230, 230, 235)
U.searchBox.PlaceholderColor3 = Color3.fromRGB(120, 122, 130)
U.searchBox.TextSize = mn(12)
U.searchBox.Font = Enum.Font.GothamSemibold
U.searchBox.ClearTextOnFocus = false
U.searchBox.TextXAlignment = Enum.TextXAlignment.Left
U.searchBox.Parent = U.rightArea
do
    local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 8) c.Parent = U.searchBox
    local p = Instance.new("UIPadding") p.PaddingLeft = UDim.new(0, 8) p.Parent = U.searchBox
end

U.tabFrames = {}
U.tabs = {}
local tabNames = {"Home", "Movement", "ESP", "Notifier", "Murderer", "Sheriff", "Teleport", "Keybinds", "Settings", "Utility", "Config"}

for _, tabName in ipairs(tabNames) do
    local fr = Instance.new("ScrollingFrame")
    fr.Name = tabName .. "Tab"
    fr.Size = UDim2.new(1, 0, 1, -mn(30))
    fr.Position = mpos(0, 30)
    fr.BackgroundTransparency = 1
    fr.BorderSizePixel = 0
    fr.ScrollBarThickness = 4
    fr.ScrollBarImageColor3 = Color3.fromRGB(75, 77, 85)
    fr.AutomaticCanvasSize = Enum.AutomaticSize.Y
    fr.ScrollingDirection = Enum.ScrollingDirection.Y
    fr.Visible = false
    fr.Parent = U.rightArea
    do
        local l = Instance.new("UIListLayout")
        l.Padding = UDim.new(0, 3)
        l.SortOrder = Enum.SortOrder.LayoutOrder
        l.Parent = fr
    end
    U.tabFrames[tabName] = fr
end

U.activeTab = nil
local function switchTab(name)
    U.activeTab = name
    for k, fr in pairs(U.tabFrames) do
        fr.Visible = (k == name)
    end
    for k, btn in pairs(U.tabs) do
        if k == name then
            btn.BackgroundColor3 = Color3.fromRGB(50, 55, 65)
            btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        else
            btn.BackgroundColor3 = Color3.fromRGB(34, 36, 43)
            btn.TextColor3 = Color3.fromRGB(200, 200, 210)
        end
    end
    if U.searchBox.Text ~= "" then U.searchBox.Text = "" end
    local fr = U.tabFrames[name]
    if fr then
        for _, child in ipairs(fr:GetChildren()) do
            if child:IsA("TextButton") then child.Visible = true end
        end
    end
    if name == "Home" then
        S.homeRebuildDirty = true
    end
end

local iOrder = 0
for _, tabName in ipairs(tabNames) do
    iOrder = iOrder + 1
    local tb = Instance.new("TextButton")
    tb.Size = UDim2.new(1, -4, 0, mn(24))
    tb.BackgroundColor3 = Color3.fromRGB(34, 36, 43)
    tb.BorderSizePixel = 0
    tb.Text = tabName
    tb.TextColor3 = Color3.fromRGB(200, 200, 210)
    tb.TextSize = mn(11)
    tb.Font = Enum.Font.GothamSemibold
    tb.AutoButtonColor = false
    tb.TextXAlignment = Enum.TextXAlignment.Left
    tb.LayoutOrder = iOrder
    tb.Parent = U.sidebar
    do
        local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 6) c.Parent = tb
        local p = Instance.new("UIPadding") p.PaddingLeft = UDim.new(0, 8) p.Parent = tb
    end
    U.tabs[tabName] = tb
    tb.MouseButton1Click:Connect(function() switchTab(tabName) end)
end

switchTab("Home")

U.searchBox:GetPropertyChangedSignal("Text"):Connect(function()
    local q = U.searchBox.Text:lower()
    local fr = U.tabFrames[U.activeTab]
    if not fr then return end
    for _, child in ipairs(fr:GetChildren()) do
        if child:IsA("TextButton") then
            if q == "" then
                child.Visible = true
            else
                child.Visible = child.Text:lower():find(q, 1, true) ~= nil
            end
        end
    end
end)

local function createSectionTitle(text)
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1, 0, 0, mn(14))
    l.BackgroundTransparency = 1
    l.Text = text
    l.TextColor3 = Color3.fromRGB(150, 153, 165)
    l.TextSize = mn(11)
    l.Font = Enum.Font.GothamBold
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.LayoutOrder = getLayoutOrder()
    l.Parent = currentParent
end

local function createToggle(name, text)
    local b = Instance.new("TextButton")
    b.Name = name
    b.Size = UDim2.new(1, 0, 0, mn(30))
    b.BackgroundColor3 = Color3.fromRGB(34, 36, 43)
    b.BorderSizePixel = 0
    b.Text = text
    b.TextColor3 = Color3.fromRGB(230, 230, 235)
    b.TextSize = mn(12)
    b.Font = Enum.Font.GothamSemibold
    b.AutoButtonColor = false
    b.LayoutOrder = getLayoutOrder()
    b.Parent = currentParent
    do local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 8) c.Parent = b end
    local ind = Instance.new("Frame")
    ind.Size = msz(5, 16)
    ind.Position = mpos(7, 7)
    ind.BackgroundColor3 = Color3.fromRGB(80, 82, 90)
    ind.BorderSizePixel = 0
    ind.Parent = b
    do local c = Instance.new("UICorner") c.CornerRadius = UDim.new(1, 0) c.Parent = ind end
    return b, ind
end

local function createActionButton(name, text)
    local b = Instance.new("TextButton")
    b.Name = name
    b.Size = UDim2.new(1, 0, 0, mn(30))
    b.BackgroundColor3 = Color3.fromRGB(34, 36, 43)
    b.BorderSizePixel = 0
    b.Text = text
    b.TextColor3 = Color3.fromRGB(230, 230, 235)
    b.TextSize = mn(12)
    b.Font = Enum.Font.GothamSemibold
    b.AutoButtonColor = false
    b.LayoutOrder = getLayoutOrder()
    b.Parent = currentParent
    do local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 8) c.Parent = b end
    return b
end

local function createInfoCard()
    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, 0, 0, 0)
    card.AutomaticSize = Enum.AutomaticSize.Y
    card.BackgroundColor3 = Color3.fromRGB(28, 30, 36)
    card.BorderSizePixel = 0
    card.LayoutOrder = getLayoutOrder()
    card.Parent = currentParent
    do local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 8) c.Parent = card end
    local p = Instance.new("UIPadding")
    p.PaddingTop = UDim.new(0, 5)
    p.PaddingBottom = UDim.new(0, 5)
    p.PaddingLeft = UDim.new(0, 8)
    p.PaddingRight = UDim.new(0, 8)
    p.Parent = card
    local l = Instance.new("UIListLayout")
    l.Padding = UDim.new(0, 2)
    l.SortOrder = Enum.SortOrder.LayoutOrder
    l.Parent = card
    return card
end

local function addInfoRow(card, key, initial, valueColor)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, mn(16))
    row.BackgroundTransparency = 1
    row.LayoutOrder = getLayoutOrder()
    row.Parent = card
    local k = Instance.new("TextLabel")
    k.Size = UDim2.new(0.5, 0, 1, 0)
    k.BackgroundTransparency = 1
    k.Text = key
    k.TextColor3 = Color3.fromRGB(150, 153, 165)
    k.TextSize = mn(11)
    k.Font = Enum.Font.GothamSemibold
    k.TextXAlignment = Enum.TextXAlignment.Left
    k.Parent = row
    local v = Instance.new("TextLabel")
    v.Size = UDim2.new(0.5, 0, 1, 0)
    v.Position = UDim2.new(0.5, 0, 0, 0)
    v.BackgroundTransparency = 1
    v.Text = initial or "-"
    v.TextColor3 = valueColor or Color3.fromRGB(230, 230, 235)
    v.TextSize = mn(11)
    v.Font = Enum.Font.GothamBold
    v.TextXAlignment = Enum.TextXAlignment.Right
    v.Parent = row
    return v
end

local function setOn(b, i)
    b.BackgroundColor3 = Color3.fromRGB(35, 70, 45)
    i.BackgroundColor3 = Color3.fromRGB(50, 210, 90)
end
local function setOff(b, i)
    b.BackgroundColor3 = Color3.fromRGB(34, 36, 43)
    i.BackgroundColor3 = Color3.fromRGB(80, 82, 90)
end
local function setRed(b, i)
    b.BackgroundColor3 = Color3.fromRGB(70, 32, 32)
    i.BackgroundColor3 = Color3.fromRGB(230, 55, 55)
end

local function refreshSpawnCache()
    local nc = {}
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("SpawnLocation") or (obj:IsA("BasePart") and obj.Name == "SpawnPoint") then
            table.insert(nc, obj)
        end
    end
    cachedSpawns = nc
end

local function isPlayerInSpawn(target)
    if not target or not target.Character then return true end
    local lobby = workspace:FindFirstChild("Lobby") or workspace:FindFirstChild("LobbyMap")
    if lobby and target.Character:IsDescendantOf(lobby) then return true end
    local root = target.Character:FindFirstChild("HumanoidRootPart")
    if not root then return true end
    for _, sp in ipairs(cachedSpawns) do
        if sp and sp.Parent and (root.Position - sp.Position).Magnitude < 35 then return true end
    end
    return false
end

refreshSpawnCache()
task.spawn(function()
    while U.gui.Parent do
        pcall(refreshSpawnCache)
        task.wait(10)
    end
end)

-- ═══════════════════════════════════════════════════════════
-- WHAT'S NEW MODAL
-- ═══════════════════════════════════════════════════════════
U.whatsNewOverlay = Instance.new("TextButton")
U.whatsNewOverlay.Name = "WhatsNewOverlay"
U.whatsNewOverlay.Size = UDim2.new(1, 0, 1, 0)
U.whatsNewOverlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
U.whatsNewOverlay.BackgroundTransparency = 0.5
U.whatsNewOverlay.Text = ""
U.whatsNewOverlay.AutoButtonColor = false
U.whatsNewOverlay.Visible = false
U.whatsNewOverlay.ZIndex = 100
U.whatsNewOverlay.Parent = U.gui

U.whatsNewPanel = Instance.new("Frame")
U.whatsNewPanel.Size = msz(360, 340)
U.whatsNewPanel.Position = UDim2.new(0.5, -mn(180), 0.5, -mn(170))
U.whatsNewPanel.BackgroundColor3 = Color3.fromRGB(22, 23, 28)
U.whatsNewPanel.BorderSizePixel = 0
U.whatsNewPanel.Active = true
U.whatsNewPanel.ZIndex = 101
U.whatsNewPanel.Parent = U.whatsNewOverlay
do
    local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 12) c.Parent = U.whatsNewPanel
    local st = Instance.new("UIStroke")
    st.Color = Color3.fromRGB(70, 72, 82)
    st.Thickness = 1
    st.Parent = U.whatsNewPanel
end

U.wnHeader = Instance.new("Frame")
U.wnHeader.Size = UDim2.new(1, 0, 0, mn(36))
U.wnHeader.BackgroundColor3 = Color3.fromRGB(29, 30, 37)
U.wnHeader.BorderSizePixel = 0
U.wnHeader.ZIndex = 102
U.wnHeader.Parent = U.whatsNewPanel
do local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 12) c.Parent = U.wnHeader end

U.wnTitle = Instance.new("TextLabel")
U.wnTitle.Size = UDim2.new(1, -mn(48), 1, 0)
U.wnTitle.Position = mpos(12, 0)
U.wnTitle.BackgroundTransparency = 1
U.wnTitle.Text = "WHAT'S NEW"
U.wnTitle.TextColor3 = Color3.fromRGB(245, 245, 250)
U.wnTitle.TextSize = mn(13)
U.wnTitle.Font = Enum.Font.GothamBold
U.wnTitle.TextXAlignment = Enum.TextXAlignment.Left
U.wnTitle.ZIndex = 103
U.wnTitle.Parent = U.wnHeader

U.wnClose = Instance.new("TextButton")
U.wnClose.Size = msz(26, 26)
U.wnClose.Position = UDim2.new(1, -mn(32), 0.5, -mn(13))
U.wnClose.BackgroundColor3 = Color3.fromRGB(42, 44, 52)
U.wnClose.Text = "X"
U.wnClose.TextSize = mn(14)
U.wnClose.TextColor3 = Color3.fromRGB(255, 200, 200)
U.wnClose.Font = Enum.Font.GothamBold
U.wnClose.BorderSizePixel = 0
U.wnClose.AutoButtonColor = false
U.wnClose.ZIndex = 103
U.wnClose.Parent = U.wnHeader
do local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 6) c.Parent = U.wnClose end

U.wnScroll = Instance.new("ScrollingFrame")
U.wnScroll.Size = UDim2.new(1, -mn(16), 1, -mn(48))
U.wnScroll.Position = mpos(8, 42)
U.wnScroll.BackgroundTransparency = 1
U.wnScroll.BorderSizePixel = 0
U.wnScroll.ScrollBarThickness = 4
U.wnScroll.ScrollBarImageColor3 = Color3.fromRGB(75, 77, 85)
U.wnScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
U.wnScroll.ScrollingDirection = Enum.ScrollingDirection.Y
U.wnScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
U.wnScroll.ZIndex = 102
U.wnScroll.Parent = U.whatsNewPanel
do
    local l = Instance.new("UIListLayout")
    l.Padding = UDim.new(0, 4)
    l.SortOrder = Enum.SortOrder.LayoutOrder
    l.Parent = U.wnScroll
end

for _, entry in ipairs(CHANGELOG) do
    local verHdr = Instance.new("Frame")
    verHdr.Size = UDim2.new(1, 0, 0, mn(18))
    verHdr.BackgroundColor3 = Color3.fromRGB(35, 40, 52)
    verHdr.BorderSizePixel = 0
    verHdr.LayoutOrder = getLayoutOrder()
    verHdr.Parent = U.wnScroll
    do local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 5) c.Parent = verHdr end
    local vl = Instance.new("TextLabel")
    vl.Size = UDim2.new(1, -mn(10), 1, 0)
    vl.Position = mpos(6, 0)
    vl.BackgroundTransparency = 1
    vl.Text = entry.version .. "   •   " .. entry.date
    vl.TextColor3 = Color3.fromRGB(90, 200, 255)
    vl.TextSize = mn(11)
    vl.Font = Enum.Font.GothamBold
    vl.TextXAlignment = Enum.TextXAlignment.Left
    vl.Parent = verHdr
    for _, change in ipairs(entry.changes) do
        local cl = Instance.new("TextLabel")
        cl.Size = UDim2.new(1, -mn(8), 0, 0)
        cl.AutomaticSize = Enum.AutomaticSize.Y
        cl.BackgroundTransparency = 1
        cl.Text = "  • " .. change
        cl.TextColor3 = Color3.fromRGB(200, 202, 210)
        cl.TextSize = mn(11)
        cl.Font = Enum.Font.Gotham
        cl.TextXAlignment = Enum.TextXAlignment.Left
        cl.TextWrapped = true
        cl.TextYAlignment = Enum.TextYAlignment.Top
        cl.LayoutOrder = getLayoutOrder()
        cl.Parent = U.wnScroll
    end
    local spacer = Instance.new("Frame")
    spacer.Size = UDim2.new(1, 0, 0, mn(6))
    spacer.BackgroundTransparency = 1
    spacer.LayoutOrder = getLayoutOrder()
    spacer.Parent = U.wnScroll
end

openWhatsNew = function()
    U.whatsNewOverlay.Visible = true
end

U.wnClose.MouseButton1Click:Connect(function()
    U.whatsNewOverlay.Visible = false
end)
U.whatsNewOverlay.MouseButton1Click:Connect(function()
    U.whatsNewOverlay.Visible = false
end)

-- ═══════════════════════════════════════════════════════════
-- HOME TAB
-- ═══════════════════════════════════════════════════════════
currentParent = U.tabFrames.Home

U.whatsNewBtn = createActionButton("WhatsNewBtn", "📢   WHAT'S NEW")
U.whatsNewBtn.BackgroundColor3 = Color3.fromRGB(50, 70, 115)
U.whatsNewBtn.TextColor3 = Color3.fromRGB(220, 235, 255)
U.whatsNewBtn.MouseButton1Click:Connect(function()
    openWhatsNew()
end)

createSectionTitle("LIVE STATUS")
do
    local card = createInfoCard()
    U.homeRefs.yourRoleLbl = addInfoRow(card, "Your Role", "Innocent", ROLE_COLORS.Innocent)
    U.homeRefs.murdererLbl = addInfoRow(card, "Murderer", "None")
    U.homeRefs.sheriffLbl = addInfoRow(card, "Sheriff", "None")
    U.homeRefs.heroLbl = addInfoRow(card, "Hero", "None")
    U.homeRefs.roundLbl = addInfoRow(card, "Round", "Waiting")
    U.homeRefs.playersLbl = addInfoRow(card, "Players", "0 / 0")
end

createSectionTitle("QUICK ACTIONS")
U.homePvpBtn = createActionButton("HomePvpBtn", "Apply PVP Ready")
U.homePvpBtn.BackgroundColor3 = Color3.fromRGB(45, 65, 45)
U.homePvpBtn.MouseButton1Click:Connect(function()
    if applyPvpPreset then applyPvpPreset() end
end)

U.homeRestoreBtn = createActionButton("HomeRestoreBtn", "Restore Before PVP")
U.homeRestoreBtn.BackgroundColor3 = Color3.fromRGB(60, 50, 35)
U.homeRestoreBtn.MouseButton1Click:Connect(function()
    if restorePvpSnapshot then restorePvpSnapshot() end
end)

U.homeTurnOffBtn = createActionButton("HomeTurnOffBtn", "Turn Off All")
U.homeTurnOffBtn.BackgroundColor3 = Color3.fromRGB(70, 40, 40)
U.homeTurnOffBtn.TextColor3 = Color3.fromRGB(255, 200, 200)
U.homeTurnOffBtn.MouseButton1Click:Connect(function()
    if resetAllToggles then resetAllToggles() end
end)

U.homePanicBtn = createActionButton("HomePanicBtn", "⚠  PANIC  (off + minimize)")
U.homePanicBtn.BackgroundColor3 = Color3.fromRGB(120, 30, 30)
U.homePanicBtn.TextColor3 = Color3.fromRGB(255, 220, 220)
U.homePanicBtn.MouseButton1Click:Connect(function()
    if resetAllToggles then pcall(resetAllToggles) end
    if minimizeMenu then pcall(minimizeMenu) end
end)

createSectionTitle("SESSION STATS")
do
    local card = createInfoCard()
    U.homeRefs.killsLbl = addInfoRow(card, "Kills", "0", ROLE_COLORS.Murderer)
    U.homeRefs.deathsLbl = addInfoRow(card, "Deaths", "0")
    U.homeRefs.roundsLbl = addInfoRow(card, "Rounds Played", "0")
    U.homeRefs.asMurdererLbl = addInfoRow(card, "Times as Murderer", "0", ROLE_COLORS.Murderer)
    U.homeRefs.asSheriffLbl = addInfoRow(card, "Times as Sheriff", "0", ROLE_COLORS.Sheriff)
    U.homeRefs.sessionLbl = addInfoRow(card, "Session Duration", "00:00:00")
end

createSectionTitle("ACTIVE KEYBINDS")
do
    local card = createInfoCard()
    U.homeRefs.keybindsCard = card
    U.homeRefs.keybindLabels = {}
    -- Populated by updateHomeUI when tab opens
    U.homeRefs.keybindsPlaceholder = addInfoRow(card, "Status", "Loading...")
end

createSectionTitle("SCRIPT INFO")
do
    local card = createInfoCard()
    addInfoRow(card, "Version", SCRIPT_VERSION)
    addInfoRow(card, "Author", SCRIPT_AUTHOR)
    addInfoRow(card, "Updated", CHANGELOG[1] and CHANGELOG[1].date or "?")
    U.homeRefs.placeIdLbl = addInfoRow(card, "Place ID", tostring(game.PlaceId))
    U.homeRefs.jobIdLbl = addInfoRow(card, "Job ID", string.sub(game.JobId, 1, 12) .. "...")
    U.homeRefs.regionLbl = addInfoRow(card, "Region", "Loading...")
end

U.copyLsBtn = createActionButton("CopyLsBtn", "Copy Loadstring")
U.copyLsBtn.MouseButton1Click:Connect(function()
    local ls = 'loadstring(game:HttpGet("https://raw.githubusercontent.com/arbuz181pl/TEST/refs/heads/main/TEST.lua"))()'
    local ok = pcall(function() setclipboard(ls) end)
    if ok then
        sendNotification("MM2 Menu", "Loadstring copied to clipboard")
    else
        sendNotification("MM2 Menu", "Clipboard not supported on this executor", SOUNDS.alert)
    end
end)

createSectionTitle("NOTIFICATION HISTORY")
U.homeRefs.notifCard = Instance.new("Frame")
U.homeRefs.notifCard.Size = UDim2.new(1, 0, 0, mn(120))
U.homeRefs.notifCard.BackgroundColor3 = Color3.fromRGB(28, 30, 36)
U.homeRefs.notifCard.BorderSizePixel = 0
U.homeRefs.notifCard.LayoutOrder = getLayoutOrder()
U.homeRefs.notifCard.Parent = currentParent
do local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 8) c.Parent = U.homeRefs.notifCard end

U.homeRefs.notifScroll = Instance.new("ScrollingFrame")
U.homeRefs.notifScroll.Size = UDim2.new(1, -mn(12), 1, -mn(12))
U.homeRefs.notifScroll.Position = mpos(6, 6)
U.homeRefs.notifScroll.BackgroundTransparency = 1
U.homeRefs.notifScroll.BorderSizePixel = 0
U.homeRefs.notifScroll.ScrollBarThickness = 3
U.homeRefs.notifScroll.ScrollBarImageColor3 = Color3.fromRGB(75, 77, 85)
U.homeRefs.notifScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
U.homeRefs.notifScroll.ScrollingDirection = Enum.ScrollingDirection.Y
U.homeRefs.notifScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
U.homeRefs.notifScroll.Parent = U.homeRefs.notifCard
do
    local l = Instance.new("UIListLayout")
    l.Padding = UDim.new(0, 3)
    l.SortOrder = Enum.SortOrder.LayoutOrder
    l.Parent = U.homeRefs.notifScroll
end

-- Region lookup
task.spawn(function()
    local ok, region = pcall(function()
        return LocalizationService:GetCountryRegionForPlayerAsync(player)
    end)
    if ok and region and region ~= "" then
        if U.homeRefs.regionLbl then U.homeRefs.regionLbl.Text = region end
    else
        if U.homeRefs.regionLbl then U.homeRefs.regionLbl.Text = "Unknown" end
    end
end)

-- Home UI updater
local function rebuildKeybindList()
    if not U.homeRefs.keybindsCard then return end
    for _, child in ipairs(U.homeRefs.keybindsCard:GetChildren()) do
        if child:IsA("Frame") then child:Destroy() end
    end
    local shown = 0
    for _, entry in ipairs(S.keybindList) do
        local kb = S.keybinds[entry.id]
        if kb then
            local row = Instance.new("Frame")
            row.Size = UDim2.new(1, 0, 0, mn(16))
            row.BackgroundTransparency = 1
            row.LayoutOrder = getLayoutOrder()
            row.Parent = U.homeRefs.keybindsCard
            local k = Instance.new("TextLabel")
            k.Size = UDim2.new(0.65, 0, 1, 0)
            k.BackgroundTransparency = 1
            k.Text = entry.name
            k.TextColor3 = Color3.fromRGB(150, 153, 165)
            k.TextSize = mn(11)
            k.Font = Enum.Font.GothamSemibold
            k.TextXAlignment = Enum.TextXAlignment.Left
            k.Parent = row
            local v = Instance.new("TextLabel")
            v.Size = UDim2.new(0.35, 0, 1, 0)
            v.Position = UDim2.new(0.65, 0, 0, 0)
            v.BackgroundTransparency = 1
            v.Text = kb.Name or "None"
            v.TextColor3 = Color3.fromRGB(230, 230, 235)
            v.TextSize = mn(11)
            v.Font = Enum.Font.GothamBold
            v.TextXAlignment = Enum.TextXAlignment.Right
            v.Parent = row
            shown = shown + 1
        end
    end
    if shown == 0 and U.homeRefs.keybindsPlaceholder then
        U.homeRefs.keybindsPlaceholder.Visible = true
    elseif U.homeRefs.keybindsPlaceholder then
        U.homeRefs.keybindsPlaceholder.Visible = false
    end
end

local function rebuildNotifHistory()
    if not U.homeRefs.notifScroll then return end
    for _, child in ipairs(U.homeRefs.notifScroll:GetChildren()) do
        if child:IsA("Frame") or child:IsA("TextLabel") then child:Destroy() end
    end
    if #S.notificationHistory == 0 then
        local empty = Instance.new("TextLabel")
        empty.Size = UDim2.new(1, 0, 0, mn(20))
        empty.BackgroundTransparency = 1
        empty.Text = "No notifications yet"
        empty.TextColor3 = Color3.fromRGB(120, 122, 130)
        empty.TextSize = mn(11)
        empty.Font = Enum.Font.Gotham
        empty.TextXAlignment = Enum.TextXAlignment.Center
        empty.LayoutOrder = getLayoutOrder()
        empty.Parent = U.homeRefs.notifScroll
        return
    end
    for _, notif in ipairs(S.notificationHistory) do
        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(1, 0, 0, mn(30))
        frame.BackgroundColor3 = Color3.fromRGB(34, 36, 43)
        frame.BorderSizePixel = 0
        frame.LayoutOrder = getLayoutOrder()
        frame.Parent = U.homeRefs.notifScroll
        do local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 5) c.Parent = frame end
        local t = Instance.new("TextLabel")
        t.Size = UDim2.new(1, -mn(8), 0, mn(13))
        t.Position = mpos(4, 1)
        t.BackgroundTransparency = 1
        t.Text = notif.title
        t.TextColor3 = Color3.fromRGB(230, 230, 235)
        t.TextSize = mn(10)
        t.Font = Enum.Font.GothamBold
        t.TextXAlignment = Enum.TextXAlignment.Left
        t.Parent = frame
        local b = Instance.new("TextLabel")
        b.Size = UDim2.new(1, -mn(55), 0, mn(12))
        b.Position = mpos(4, 14)
        b.BackgroundTransparency = 1
        b.Text = notif.text
        b.TextColor3 = Color3.fromRGB(160, 162, 170)
        b.TextSize = mn(10)
        b.Font = Enum.Font.Gotham
        b.TextXAlignment = Enum.TextXAlignment.Left
        b.TextTruncate = Enum.TextTruncate.AtEnd
        b.Parent = frame
        local ago = Instance.new("TextLabel")
        ago.Size = mpos(50, 12)
        ago.Position = UDim2.new(1, -mn(50), 0, 14)
        ago.BackgroundTransparency = 1
        ago.Text = fmtAgo(notif.time)
        ago.TextColor3 = Color3.fromRGB(120, 122, 130)
        ago.TextSize = mn(9)
        ago.Font = Enum.Font.Gotham
        ago.TextXAlignment = Enum.TextXAlignment.Right
        ago.Parent = frame
    end
end

local function updateHomeUI(rebuildLists)
    if not U.homeRefs.yourRoleLbl then return end
    local yourRole = "Innocent"
    if MurdererName == player.Name then yourRole = "Murderer"
    elseif SheriffName == player.Name then yourRole = "Sheriff"
    elseif HeroName == player.Name then yourRole = "Hero" end
    U.homeRefs.yourRoleLbl.Text = yourRole
    U.homeRefs.yourRoleLbl.TextColor3 = ROLE_COLORS[yourRole] or Color3.fromRGB(230, 230, 235)

    U.homeRefs.murdererLbl.Text = MurdererName or "None"
    U.homeRefs.murdererLbl.TextColor3 = MurdererName and ROLE_COLORS.Murderer or Color3.fromRGB(140, 142, 150)
    U.homeRefs.sheriffLbl.Text = SheriffName or "None"
    U.homeRefs.sheriffLbl.TextColor3 = SheriffName and ROLE_COLORS.Sheriff or Color3.fromRGB(140, 142, 150)
    U.homeRefs.heroLbl.Text = HeroName or "None"
    U.homeRefs.heroLbl.TextColor3 = HeroName and ROLE_COLORS.Hero or Color3.fromRGB(140, 142, 150)
    U.homeRefs.roundLbl.Text = MurdererName and "Active" or "Waiting"
    U.homeRefs.roundLbl.TextColor3 = MurdererName and Color3.fromRGB(50, 210, 90) or Color3.fromRGB(200, 180, 90)

    local total = #Players:GetPlayers()
    local maxP = Players.MaxPlayers or 0
    U.homeRefs.playersLbl.Text = tostring(total) .. " / " .. tostring(maxP)

    U.homeRefs.killsLbl.Text = tostring(S.stats.kills)
    U.homeRefs.deathsLbl.Text = tostring(S.stats.deaths)
    U.homeRefs.roundsLbl.Text = tostring(S.stats.rounds)
    U.homeRefs.asMurdererLbl.Text = tostring(S.stats.asMurderer)
    U.homeRefs.asSheriffLbl.Text = tostring(S.stats.asSheriff)
    U.homeRefs.sessionLbl.Text = fmtTime(tick() - S.sessionStart)

    if rebuildLists or S.homeRebuildDirty then
        rebuildKeybindList()
        rebuildNotifHistory()
        S.homeRebuildDirty = false
    end
end

-- home loop
task.spawn(function()
    while U.gui.Parent and not S.scriptClosed do
        if U.activeTab == "Home" then
            pcall(updateHomeUI, false)
        end
        task.wait(0.5)
    end
end)

-- ═══════════════════════════════════════════════════════════
-- MOVEMENT TAB
-- ═══════════════════════════════════════════════════════════
currentParent = U.tabFrames.Movement
createSectionTitle("MOVEMENT")

U.noclipBtn, U.noclipInd = createToggle("Noclip", "Noclip")
U.noclipBtn.MouseButton1Click:Connect(function()
    S.noclip = not S.noclip
    if S.noclip then
        setOn(U.noclipBtn, U.noclipInd)
        S.originalCollision = {}
        if player.Character then
            for _, o in ipairs(player.Character:GetDescendants()) do
                if o:IsA("BasePart") then
                    S.originalCollision[o] = o.CanCollide
                    o.CanCollide = false
                end
            end
        end
    else
        setOff(U.noclipBtn, U.noclipInd)
        for o, v in pairs(S.originalCollision) do
            if o and o.Parent then o.CanCollide = v end
        end
        S.originalCollision = {}
    end
end)

U.flyBtn, U.flyInd = createToggle("Fly", "Fly")

local FP = {}
FP.panel = Instance.new("Frame")
FP.panel.Size = msz(210, 220)
FP.panel.Position = UDim2.new(0.5, mn(150), 0.5, -mn(110))
FP.panel.BackgroundColor3 = Color3.fromRGB(22, 23, 28)
FP.panel.BorderSizePixel = 0
FP.panel.Visible = false
FP.panel.ZIndex = 20
FP.panel.Parent = U.gui
do
    local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 12) c.Parent = FP.panel
    FP.stroke = Instance.new("UIStroke")
    FP.stroke.Color = Color3.fromRGB(55, 57, 65)
    FP.stroke.Thickness = 1
    FP.stroke.Parent = FP.panel
end

FP.header = Instance.new("Frame")
FP.header.Size = UDim2.new(1, 0, 0, mn(42))
FP.header.BackgroundColor3 = Color3.fromRGB(29, 30, 37)
FP.header.BorderSizePixel = 0
FP.header.Active = true
FP.header.ZIndex = 21
FP.header.Parent = FP.panel
do local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 12) c.Parent = FP.header end

FP.titleLbl = Instance.new("TextLabel")
FP.titleLbl.Size = UDim2.new(1, -mn(60), 1, 0)
FP.titleLbl.Position = mpos(10, 0)
FP.titleLbl.BackgroundTransparency = 1
FP.titleLbl.Text = "FLY"
FP.titleLbl.TextColor3 = Color3.fromRGB(245, 245, 250)
FP.titleLbl.TextSize = mn(13)
FP.titleLbl.Font = Enum.Font.GothamBold
FP.titleLbl.TextXAlignment = Enum.TextXAlignment.Left
FP.titleLbl.ZIndex = 22
FP.titleLbl.Parent = FP.header

FP.lock = Instance.new("TextButton")
FP.lock.Size = msz(24, 24)
FP.lock.Position = UDim2.new(1, -mn(30), 0.5, -mn(12))
FP.lock.BackgroundColor3 = Color3.fromRGB(42, 44, 52)
FP.lock.Text = "🔓"
FP.lock.TextSize = mn(11)
FP.lock.TextColor3 = Color3.new(1, 1, 1)
FP.lock.Font = Enum.Font.GothamBold
FP.lock.BorderSizePixel = 0
FP.lock.AutoButtonColor = false
FP.lock.ZIndex = 22
FP.lock.Parent = FP.header
do local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 6) c.Parent = FP.lock end

FP.enable = Instance.new("TextButton")
FP.enable.Size = UDim2.new(1, -mn(20), 0, mn(36))
FP.enable.Position = mpos(10, 52)
FP.enable.BackgroundColor3 = Color3.fromRGB(34, 36, 43)
FP.enable.BorderSizePixel = 0
FP.enable.Text = "Enable Fly"
FP.enable.TextColor3 = Color3.fromRGB(230, 230, 235)
FP.enable.TextSize = mn(13)
FP.enable.Font = Enum.Font.GothamSemibold
FP.enable.AutoButtonColor = false
FP.enable.ZIndex = 21
FP.enable.Parent = FP.panel
do local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 8) c.Parent = FP.enable end

FP.enableInd = Instance.new("Frame")
FP.enableInd.Size = msz(5, 20)
FP.enableInd.Position = mpos(8, 8)
FP.enableInd.BackgroundColor3 = Color3.fromRGB(80, 82, 90)
FP.enableInd.BorderSizePixel = 0
FP.enableInd.ZIndex = 22
FP.enableInd.Parent = FP.enable
do local c = Instance.new("UICorner") c.CornerRadius = UDim.new(1, 0) c.Parent = FP.enableInd end

FP.speedLbl = Instance.new("TextLabel")
FP.speedLbl.Size = UDim2.new(1, -mn(20), 0, mn(20))
FP.speedLbl.Position = mpos(10, 98)
FP.speedLbl.BackgroundTransparency = 1
FP.speedLbl.Text = "Speed: 50"
FP.speedLbl.TextColor3 = Color3.fromRGB(150, 153, 165)
FP.speedLbl.TextSize = mn(11)
FP.speedLbl.Font = Enum.Font.GothamBold
FP.speedLbl.TextXAlignment = Enum.TextXAlignment.Left
FP.speedLbl.ZIndex = 21
FP.speedLbl.Parent = FP.panel

FP.minus = Instance.new("TextButton")
FP.minus.Size = msz(36, 32)
FP.minus.Position = mpos(10, 123)
FP.minus.BackgroundColor3 = Color3.fromRGB(34, 36, 43)
FP.minus.BorderSizePixel = 0
FP.minus.Text = "-"
FP.minus.TextColor3 = Color3.fromRGB(235, 235, 240)
FP.minus.TextSize = mn(18)
FP.minus.Font = Enum.Font.GothamBold
FP.minus.AutoButtonColor = false
FP.minus.ZIndex = 21
FP.minus.Parent = FP.panel
do local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 7) c.Parent = FP.minus end

FP.speedBox = Instance.new("TextBox")
FP.speedBox.Size = UDim2.new(1, -mn(96), 0, mn(32))
FP.speedBox.Position = mpos(52, 123)
FP.speedBox.BackgroundColor3 = Color3.fromRGB(34, 36, 43)
FP.speedBox.BorderSizePixel = 0
FP.speedBox.Text = "50"
FP.speedBox.TextColor3 = Color3.fromRGB(235, 235, 240)
FP.speedBox.TextSize = mn(12)
FP.speedBox.Font = Enum.Font.GothamSemibold
FP.speedBox.ClearTextOnFocus = false
FP.speedBox.ZIndex = 21
FP.speedBox.Parent = FP.panel
do local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 7) c.Parent = FP.speedBox end

FP.plus = Instance.new("TextButton")
FP.plus.Size = msz(36, 32)
FP.plus.Position = UDim2.new(1, -mn(46), 0, mn(123))
FP.plus.BackgroundColor3 = Color3.fromRGB(34, 36, 43)
FP.plus.BorderSizePixel = 0
FP.plus.Text = "+"
FP.plus.TextColor3 = Color3.fromRGB(235, 235, 240)
FP.plus.TextSize = mn(18)
FP.plus.Font = Enum.Font.GothamBold
FP.plus.AutoButtonColor = false
FP.plus.ZIndex = 21
FP.plus.Parent = FP.panel
do local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 7) c.Parent = FP.plus end

FP.up = Instance.new("TextButton")
FP.up.Size = msz(85, 32)
FP.up.Position = mpos(10, 168)
FP.up.BackgroundColor3 = Color3.fromRGB(34, 36, 43)
FP.up.BorderSizePixel = 0
FP.up.Text = "UP"
FP.up.TextColor3 = Color3.fromRGB(230, 230, 235)
FP.up.TextSize = mn(12)
FP.up.Font = Enum.Font.GothamBold
FP.up.AutoButtonColor = false
FP.up.ZIndex = 21
FP.up.Parent = FP.panel
do local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 7) c.Parent = FP.up end

FP.down = Instance.new("TextButton")
FP.down.Size = msz(85, 32)
FP.down.Position = UDim2.new(1, -mn(95), 0, mn(168))
FP.down.BackgroundColor3 = Color3.fromRGB(34, 36, 43)
FP.down.BorderSizePixel = 0
FP.down.Text = "DOWN"
FP.down.TextColor3 = Color3.fromRGB(230, 230, 235)
FP.down.TextSize = mn(12)
FP.down.Font = Enum.Font.GothamBold
FP.down.AutoButtonColor = false
FP.down.ZIndex = 21
FP.down.Parent = FP.panel
do local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 7) c.Parent = FP.down end

local flyBV, flyBG, flyChar, flyHum, flyRoot = nil, nil, nil, nil, nil
local flyUpFlag, flyDownFlag = 0, 0

local function updateFlySpeed(v)
    v = tonumber(v) or S.flySpeed
    v = math.clamp(math.floor(v), 1, 500)
    S.flySpeed = v
    FP.speedLbl.Text = "Speed: " .. tostring(v)
    FP.speedBox.Text = tostring(v)
end

FP.minus.MouseButton1Click:Connect(function() updateFlySpeed(S.flySpeed - 1) end)
FP.plus.MouseButton1Click:Connect(function() updateFlySpeed(S.flySpeed + 1) end)
FP.speedBox.FocusLost:Connect(function() updateFlySpeed(FP.speedBox.Text) end)

local function stopFly()
    S.flyEnabled = false
    if flyBV then flyBV:Destroy() flyBV = nil end
    if flyBG then flyBG:Destroy() flyBG = nil end
    flyChar = nil flyHum = nil flyRoot = nil
    local c = player.Character
    if c then
        local h = c:FindFirstChildOfClass("Humanoid")
        if h then h.PlatformStand = false end
    end
    FP.enable.Text = "Enable Fly"
    setOff(FP.enable, FP.enableInd)
    setOff(U.flyBtn, U.flyInd)
end

local function startFly()
    local c = player.Character
    if not c then return end
    local h = c:FindFirstChildOfClass("Humanoid")
    local r = c:FindFirstChild("HumanoidRootPart")
    if not h or not r then return end
    if flyBV then flyBV:Destroy() end
    if flyBG then flyBG:Destroy() end
    S.flyEnabled = true
    flyChar = c flyHum = h flyRoot = r
    h.PlatformStand = true
    flyBG = Instance.new("BodyGyro")
    flyBG.P = 90000 flyBG.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
    flyBG.CFrame = r.CFrame flyBG.Parent = r
    flyBV = Instance.new("BodyVelocity")
    flyBV.Velocity = Vector3.zero
    flyBV.MaxForce = Vector3.new(9e9, 9e9, 9e9)
    flyBV.Parent = r
    FP.enable.Text = "Disable Fly"
    setOn(FP.enable, FP.enableInd)
    setOn(U.flyBtn, U.flyInd)
end

FP.enable.MouseButton1Click:Connect(function()
    if S.flyEnabled then stopFly() else startFly() end
end)

FP.lock.MouseButton1Click:Connect(function()
    S.flyPanelLocked = not S.flyPanelLocked
    if S.flyPanelLocked then
        FP.lock.Text = "🔒"
        FP.lock.BackgroundColor3 = Color3.fromRGB(70, 45, 45)
    else
        FP.lock.Text = "🔓"
        FP.lock.BackgroundColor3 = Color3.fromRGB(42, 44, 52)
    end
end)

U.flyBtn.MouseButton1Click:Connect(function()
    S.flyPanelOpen = not S.flyPanelOpen
    FP.panel.Visible = S.flyPanelOpen
    if S.flyPanelOpen then
        U.flyBtn.BackgroundColor3 = Color3.fromRGB(45, 47, 56)
    else
        if S.flyEnabled then setOn(U.flyBtn, U.flyInd) else setOff(U.flyBtn, U.flyInd) end
    end
end)

local flyDragStart, flyDragStartPos
FP.header.InputBegan:Connect(function(i)
    if S.flyPanelLocked then return end
    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
        S.flyDragging = true
        flyDragStart = i.Position
        flyDragStartPos = FP.panel.Position
    end
end)
UserInputService.InputChanged:Connect(function(i)
    if not S.flyDragging then return end
    if i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch then
        local d = i.Position - flyDragStart
        FP.panel.Position = UDim2.new(flyDragStartPos.X.Scale, flyDragStartPos.X.Offset + d.X, flyDragStartPos.Y.Scale, flyDragStartPos.Y.Offset + d.Y)
    end
end)
UserInputService.InputEnded:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
        S.flyDragging = false
    end
end)

RunService.RenderStepped:Connect(function()
    if not S.flyEnabled or not flyBV or not flyBG then return end
    local c = player.Character
    if not c then stopFly() return end
    local r = c:FindFirstChild("HumanoidRootPart")
    local hum = c:FindFirstChildOfClass("Humanoid")
    local cam = workspace.CurrentCamera
    if not r or not cam then return end
    local dir = Vector3.zero
    if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir = dir + cam.CFrame.LookVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir = dir - cam.CFrame.LookVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir = dir - cam.CFrame.RightVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir = dir + cam.CFrame.RightVector end
    if hum and hum.MoveDirection.Magnitude > 0.05 then
        dir = dir + hum.MoveDirection
    end
    if UserInputService:IsKeyDown(Enum.KeyCode.Space) or flyUpFlag == 1 then dir = dir + Vector3.new(0, 1, 0) end
    if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or flyDownFlag == -1 then dir = dir - Vector3.new(0, 1, 0) end
    if dir.Magnitude > 0 then flyBV.Velocity = dir.Unit * S.flySpeed else flyBV.Velocity = Vector3.zero end
    flyBG.CFrame = cam.CFrame
end)

FP.up.MouseButton1Down:Connect(function() flyUpFlag = 1 end)
FP.up.MouseButton1Up:Connect(function() flyUpFlag = 0 end)
FP.down.MouseButton1Down:Connect(function() flyDownFlag = -1 end)
FP.down.MouseButton1Up:Connect(function() flyDownFlag = 0 end)

U.infBtn, U.infInd = createToggle("InfinityJump", "Infinity Jump")
U.infBtn.MouseButton1Click:Connect(function()
    S.infinityJump = not S.infinityJump
    if S.infinityJump then setOn(U.infBtn, U.infInd) else setOff(U.infBtn, U.infInd) end
end)
UserInputService.JumpRequest:Connect(function()
    if not S.infinityJump then return end
    local c = player.Character
    if not c then return end
    local h = c:FindFirstChildOfClass("Humanoid")
    if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
end)

U.f3Btn, U.f3Ind = createToggle("FlingOnTouch", "Fling 3rd party")
U.f3Btn.MouseButton1Click:Connect(function()
    S.flingThirdParty = not S.flingThirdParty
    if S.flingThirdParty then
        U.f3Btn.BackgroundColor3 = Color3.fromRGB(70, 45, 35)
        U.f3Ind.BackgroundColor3 = Color3.fromRGB(230, 100, 55)
        local ok = pcall(function()
            loadstring(game:HttpGet("https://rawscripts.net/raw/Universal-Script-Ultimate-Fling-GUI-41909"))()
        end)
        if not ok then sendNotification("MM2 Menu", "Failed to load 3rd party fling script.") end
    else
        setOff(U.f3Btn, U.f3Ind)
    end
end)

local function flingLoop()
    local lp = player
    local c, hrp, vel, movel = nil, nil, nil, 0.1
    while S.flingTouchActive do
        RunService.Heartbeat:Wait()
        c = lp.Character
        hrp = c and c:FindFirstChild("HumanoidRootPart")
        if hrp then
            vel = hrp.Velocity
            hrp.Velocity = vel * 10000 + Vector3.new(0, 10000, 0)
            RunService.RenderStepped:Wait()
            hrp.Velocity = vel
            RunService.Stepped:Wait()
            hrp.Velocity = vel + Vector3.new(0, movel, 0)
            movel = -movel
        end
    end
end

U.fib, U.fii = createToggle("FlingOnTouchIntegrated", "Fling On Touch")
U.fib.MouseButton1Click:Connect(function()
    S.flingOnTouch = not S.flingOnTouch
    if S.flingOnTouch then
        U.fib.BackgroundColor3 = Color3.fromRGB(70, 45, 35)
        U.fii.BackgroundColor3 = Color3.fromRGB(230, 100, 55)
        S.flingTouchActive = true
        S.flingTouchThread = coroutine.create(flingLoop)
        coroutine.resume(S.flingTouchThread)
    else
        setOff(U.fib, U.fii)
        S.flingTouchActive = false
    end
end)

createSectionTitle("SPEEDHACK")

U.shBtn, U.shInd = createToggle("Speedhack", "Speedhack")

U.shRow = Instance.new("Frame")
U.shRow.Size = UDim2.new(1, 0, 0, mn(30))
U.shRow.BackgroundTransparency = 1
U.shRow.LayoutOrder = getLayoutOrder()
U.shRow.Parent = currentParent

U.shMinus = Instance.new("TextButton")
U.shMinus.Size = msz(34, 30)
U.shMinus.BackgroundColor3 = Color3.fromRGB(34, 36, 43)
U.shMinus.BorderSizePixel = 0
U.shMinus.Text = "-"
U.shMinus.TextColor3 = Color3.fromRGB(235, 235, 240)
U.shMinus.TextSize = mn(18)
U.shMinus.Font = Enum.Font.GothamBold
U.shMinus.AutoButtonColor = false
U.shMinus.Parent = U.shRow
do local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 7) c.Parent = U.shMinus end

U.shBox = Instance.new("TextBox")
U.shBox.Size = msz(50, 30)
U.shBox.Position = mpos(40, 0)
U.shBox.BackgroundColor3 = Color3.fromRGB(34, 36, 43)
U.shBox.BorderSizePixel = 0
U.shBox.Text = "45"
U.shBox.TextColor3 = Color3.fromRGB(235, 235, 240)
U.shBox.TextSize = mn(12)
U.shBox.Font = Enum.Font.GothamSemibold
U.shBox.ClearTextOnFocus = false
U.shBox.Parent = U.shRow
do local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 7) c.Parent = U.shBox end

U.shPlus = Instance.new("TextButton")
U.shPlus.Size = msz(34, 30)
U.shPlus.Position = mpos(96, 0)
U.shPlus.BackgroundColor3 = Color3.fromRGB(34, 36, 43)
U.shPlus.BorderSizePixel = 0
U.shPlus.Text = "+"
U.shPlus.TextColor3 = Color3.fromRGB(235, 235, 240)
U.shPlus.TextSize = mn(18)
U.shPlus.Font = Enum.Font.GothamBold
U.shPlus.AutoButtonColor = false
U.shPlus.Parent = U.shRow
do local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 7) c.Parent = U.shPlus end

U.shLbl = Instance.new("TextLabel")
U.shLbl.Size = UDim2.new(1, -mn(138), 0, mn(30))
U.shLbl.Position = mpos(138, 0)
U.shLbl.BackgroundTransparency = 1
U.shLbl.Text = "WalkSpeed"
U.shLbl.TextColor3 = Color3.fromRGB(150, 153, 165)
U.shLbl.TextSize = mn(11)
U.shLbl.Font = Enum.Font.GothamBold
U.shLbl.TextXAlignment = Enum.TextXAlignment.Left
U.shLbl.Parent = U.shRow

local function updateSH(v)
    v = tonumber(v) or S.speedhackSpeed
    v = math.clamp(math.floor(v), 1, 100)
    S.speedhackSpeed = v
    U.shBox.Text = tostring(v)
end
U.shMinus.MouseButton1Click:Connect(function() updateSH(S.speedhackSpeed - 5) end)
U.shPlus.MouseButton1Click:Connect(function() updateSH(S.speedhackSpeed + 5) end)
U.shBox.FocusLost:Connect(function() updateSH(U.shBox.Text) end)

U.shBtn.MouseButton1Click:Connect(function()
    S.speedhackEnabled = not S.speedhackEnabled
    if S.speedhackEnabled then
        setOn(U.shBtn, U.shInd)
        local c = player.Character
        if c then local h = c:FindFirstChildOfClass("Humanoid") if h then h.WalkSpeed = S.speedhackSpeed end end
    else
        setOff(U.shBtn, U.shInd)
        local c = player.Character
        if c then local h = c:FindFirstChildOfClass("Humanoid") if h then h.WalkSpeed = 16 end end
    end
end)

RunService.RenderStepped:Connect(function()
    if not S.speedhackEnabled then return end
    local c = player.Character
    if not c then return end
    local h = c:FindFirstChildOfClass("Humanoid")
    if h and h.WalkSpeed ~= S.speedhackSpeed then h.WalkSpeed = S.speedhackSpeed end
end)

-- ═══════════════════════════════════════════════════════════
-- ESP TAB
-- ═══════════════════════════════════════════════════════════
currentParent = U.tabFrames.ESP
createSectionTitle("ROLE ESP")

local function makeEspBtn(role)
    local b, i = createToggle(role .. "ESP", role .. " ESP")
    espButtons[role] = {Button = b, Indicator = i}
    b.MouseButton1Click:Connect(function()
        S.espEnabled[role] = not S.espEnabled[role]
        if S.espEnabled[role] then
            b.BackgroundColor3 = ROLE_COLORS[role]:Lerp(Color3.fromRGB(20, 20, 25), 0.65)
            i.BackgroundColor3 = ROLE_COLORS[role]
        else
            setOff(b, i)
        end
    end)
end
makeEspBtn("Innocent")
makeEspBtn("Murderer")
makeEspBtn("Sheriff")
makeEspBtn("Hero")

createSectionTitle("ITEM ESP")

U.gunBtn, U.gunInd = createToggle("GunESP", "Gun ESP")
U.gunBtn.MouseButton1Click:Connect(function()
    S.gunESPEnabled = not S.gunESPEnabled
    if S.gunESPEnabled then
        U.gunBtn.BackgroundColor3 = GUN_COLOR:Lerp(Color3.fromRGB(20, 20, 25), 0.65)
        U.gunInd.BackgroundColor3 = GUN_COLOR
    else
        setOff(U.gunBtn, U.gunInd)
        for gun, hl in pairs(S.gunHighlights) do
            if hl then pcall(function() hl:Destroy() end) end
        end
        S.gunHighlights = {}
    end
end)

createSectionTitle("PLAYER INFO")

U.distBtn, U.distInd = createToggle("PlayerDistance", "Player Distance (studs)")
U.distBtn.MouseButton1Click:Connect(function()
    S.playerDistanceOn = not S.playerDistanceOn
    if S.playerDistanceOn then
        setOn(U.distBtn, U.distInd)
    else
        setOff(U.distBtn, U.distInd)
        for p, bg in pairs(S.playerDistBillboards) do
            if bg then bg:Destroy() end
        end
        S.playerDistBillboards = {}
    end
end)

-- ═══════════════════════════════════════════════════════════
-- NOTIFIER TAB
-- ═══════════════════════════════════════════════════════════
currentParent = U.tabFrames.Notifier
createSectionTitle("NOTIFIER")

local function fmtRole(r, n)
    if not n then return r .. ": None" end
    local t = Players:FindFirstChild(n)
    if t then return r .. ": " .. t.DisplayName .. " (@" .. t.Name .. ")" end
    return r .. ": " .. n
end

local function notifyAllRoles()
    sendNotification("MM2 Roles", fmtRole("Murderer", MurdererName) .. "\n" .. fmtRole("Sheriff", SheriffName) .. "\n" .. fmtRole("Hero", HeroName))
end

U.notifyBtn = createActionButton("NotifyRoles", "Notify Roles")
U.notifyBtn.MouseButton1Click:Connect(notifyAllRoles)

U.autoNotBtn, U.autoNotInd = createToggle("AutoNotifyRound", "Auto Notify Round (Roles)")
U.autoNotBtn.MouseButton1Click:Connect(function()
    S.autoNotifyRoles = not S.autoNotifyRoles
    if S.autoNotifyRoles then
        setOn(U.autoNotBtn, U.autoNotInd)
    else
        setOff(U.autoNotBtn, U.autoNotInd)
        lastNotifiedMurderer = nil
        lastNotifiedSheriff = nil
        lastNotifiedHero = nil
        S.pendingNotify = false
    end
end)

createSectionTitle("ROUND EVENTS")

U.rStartBtn, U.rStartInd = createToggle("NotifyRoundStart", "Notify Round Start")
U.rStartBtn.MouseButton1Click:Connect(function()
    S.notifyRoundStart = not S.notifyRoundStart
    if S.notifyRoundStart then setOn(U.rStartBtn, U.rStartInd) else setOff(U.rStartBtn, U.rStartInd) end
end)

U.rEndBtn, U.rEndInd = createToggle("NotifyRoundEnd", "Notify Round End")
U.rEndBtn.MouseButton1Click:Connect(function()
    S.notifyRoundEnd = not S.notifyRoundEnd
    if S.notifyRoundEnd then setOn(U.rEndBtn, U.rEndInd) else setOff(U.rEndBtn, U.rEndInd) end
end)

U.plBtn, U.plInd = createToggle("PlayerJoinLeaveNotify", "Player Join/Leave Alerts")
U.plBtn.MouseButton1Click:Connect(function()
    S.playerJoinLeaveNotify = not S.playerJoinLeaveNotify
    if S.playerJoinLeaveNotify then setOn(U.plBtn, U.plInd) else setOff(U.plBtn, U.plInd) end
end)

createSectionTitle("CHAT ANNOUNCEMENTS")

local function sendChat(msg)
    local sent = false
    pcall(function()
        local TCS = game:GetService("TextChatService")
        if TCS.ChatVersion == Enum.ChatVersion.TextChatService then
            local ch = TCS:FindFirstChild("TextChannels")
            if ch then
                local gen = ch:FindFirstChild("RBXGeneral")
                if gen then gen:SendAsync(msg) sent = true end
            end
        end
    end)
    if sent then return true end
    pcall(function() StarterGui:SetCore("ChatSendMessage", msg) sent = true end)
    return sent
end

local function getRoleMessage(role, name)
    if not name then return role .. ": Unknown" end
    local t = Players:FindFirstChild(name)
    if t then return role .. " is: " .. t.DisplayName .. " (@" .. t.Name .. ")"
    else return role .. " is: " .. name end
end

U.sendMurdererBtn = createActionButton("SendMurdererChat", "Send Murderer In Chat")
U.sendMurdererBtn.MouseButton1Click:Connect(function()
    if not MurdererName then sendNotification("MM2 Menu", "Murderer not found", SOUNDS.alert) return end
    if MurdererName == player.Name then
        sendNotification("MM2 Menu", "You are the Murderer!", SOUNDS.alert)
        return
    end
    sendChat(getRoleMessage("Murderer", MurdererName))
end)

U.sendSheriffBtn = createActionButton("SendSheriffChat", "Send Sheriff In Chat")
U.sendSheriffBtn.MouseButton1Click:Connect(function()
    if not SheriffName then sendNotification("MM2 Menu", "Sheriff not found", SOUNDS.alert) return end
    if SheriffName == player.Name then
        sendNotification("MM2 Menu", "You are the Sheriff!", SOUNDS.alert)
        return
    end
    sendChat(getRoleMessage("Sheriff", SheriffName))
end)

U.autoChatBtn, U.autoChatInd = createToggle("AutoMurdererChat", "Auto Send Murderer In Chat")
U.autoChatBtn.MouseButton1Click:Connect(function()
    S.autoSendMurdererChat = not S.autoSendMurdererChat
    if S.autoSendMurdererChat then
        setOn(U.autoChatBtn, U.autoChatInd)
        S.lastChatSentMurderer = nil
        S.roundActive = false
        S.selfNotifyMurderer = false
    else
        setOff(U.autoChatBtn, U.autoChatInd)
        S.lastChatSentMurderer = nil
        S.roundActive = false
        S.selfNotifyMurderer = false
    end
end)

U.autoSheriffChatBtn, U.autoSheriffChatInd = createToggle("AutoSheriffChat", "Auto Send Sheriff In Chat")
U.autoSheriffChatBtn.MouseButton1Click:Connect(function()
    S.autoSendSheriffChat = not S.autoSendSheriffChat
    if S.autoSendSheriffChat then
        setOn(U.autoSheriffChatBtn, U.autoSheriffChatInd)
        S.lastChatSentSheriff = nil
        S.roundActiveSheriff = false
        S.selfNotifySheriff = false
    else
        setOff(U.autoSheriffChatBtn, U.autoSheriffChatInd)
        S.lastChatSentSheriff = nil
        S.roundActiveSheriff = false
        S.selfNotifySheriff = false
    end
end)

-- ═══════════════════════════════════════════════════════════
-- MURDERER TAB
-- ═══════════════════════════════════════════════════════════
currentParent = U.tabFrames.Murderer
createSectionTitle("MURDERER")

local function getKnife()
    local c = player.Character
    if not c then return nil end
    local k = c:FindFirstChild("Knife")
    if not k then
        local bp = player:FindFirstChild("Backpack")
        if bp then k = bp:FindFirstChild("Knife") if k then k.Parent = c end end
    end
    return k
end

local function attackTarget(t)
    if not t or t == player or not t.Character then return end
    if isPlayerInSpawn(t) then return end
    local tr = t.Character:FindFirstChild("HumanoidRootPart")
    local mr = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if tr and mr then
        local k = getKnife()
        if k then
            mr.CFrame = tr.CFrame * CFrame.new(0, 0, 1.5)
            task.wait(0.05)
            pcall(function() k:Activate() end)
        end
    end
end

local function killAllPlayers()
    local c = player.Character
    if not c then return end
    local mr = c:FindFirstChild("HumanoidRootPart")
    if not mr then return end
    local k = getKnife()
    if not k then sendNotification("MM2 Menu", "No knife equipped!", SOUNDS.alert) return end

    local function getTargets()
        local list = {}
        for _, t in ipairs(Players:GetPlayers()) do
            if t ~= player and t.Character and not isPlayerInSpawn(t) then
                local h = t.Character:FindFirstChildOfClass("Humanoid")
                local tr = t.Character:FindFirstChild("HumanoidRootPart")
                if h and h.Health > 0 and tr then table.insert(list, tr) end
            end
        end
        return list
    end

    for _, tr in ipairs(getTargets()) do
        if tr and tr.Parent then
            mr.CFrame = tr.CFrame * CFrame.new(0, 0, 1.5)
            task.wait(0.03)
            pcall(function() k:Activate() end)
        end
    end
    task.wait(0.15)
    for _, tr in ipairs(getTargets()) do
        if tr and tr.Parent then
            mr.CFrame = tr.CFrame * CFrame.new(0, 0, 1.5)
            task.wait(0.03)
            pcall(function() k:Activate() end)
        end
    end
    task.wait(0.15)
    for _, tr in ipairs(getTargets()) do
        if tr and tr.Parent then
            mr.CFrame = tr.CFrame * CFrame.new(0, 0, 1.5)
            task.wait(0.03)
            pcall(function() k:Activate() end)
        end
    end
end

local function killByName(n)
    if not n then return end
    local t = Players:FindFirstChild(n)
    if t then attackTarget(t) end
end

U.autoKillBtn, U.autoKillInd = createToggle("AutoKillAll", "Auto Kill All")
U.autoKillBtn.MouseButton1Click:Connect(function()
    S.autoKillAll = not S.autoKillAll
    if S.autoKillAll then setOn(U.autoKillBtn, U.autoKillInd) else setOff(U.autoKillBtn, U.autoKillInd) end
end)

U.killAllBtn = createActionButton("KillAllNow", "Kill All Now")
U.killAllBtn.MouseButton1Click:Connect(killAllPlayers)

U.killSheriffBtn = createActionButton("KillSheriffNow", "Kill Sheriff Now")
U.killSheriffBtn.MouseButton1Click:Connect(function() killByName(SheriffName) end)

U.killHeroBtn = createActionButton("KillHeroNow", "Kill Hero Now")
U.killHeroBtn.MouseButton1Click:Connect(function() killByName(HeroName) end)

U.killSoundBtn, U.killSoundInd = createToggle("KillSound", "Kill Sound")
U.killSoundBtn.MouseButton1Click:Connect(function()
    S.killSoundOn = not S.killSoundOn
    if S.killSoundOn then setOn(U.killSoundBtn, U.killSoundInd) else setOff(U.killSoundBtn, U.killSoundInd) end
end)

-- ═══════════════════════════════════════════════════════════
-- SHERIFF TAB
-- ═══════════════════════════════════════════════════════════
currentParent = U.tabFrames.Sheriff
createSectionTitle("SHERIFF")

local function getGun()
    local c = player.Character
    if not c then return nil end
    local g = c:FindFirstChild("Gun")
    if not g then
        local bp = player:FindFirstChild("Backpack")
        if bp then g = bp:FindFirstChild("Gun") if g then g.Parent = c end end
    end
    return g
end

local function shootMurderer()
    if not MurdererName then sendNotification("MM2 Menu", "Murderer not found yet!", SOUNDS.alert) return end
    local t = Players:FindFirstChild(MurdererName)
    if not t or not t.Character then return end
    if isPlayerInSpawn(t) then sendNotification("MM2 Menu", "Murderer is in spawn/lobby!", SOUNDS.alert) return end
    local tr = t.Character:FindFirstChild("HumanoidRootPart")
    local mr = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if tr and mr then
        local g = getGun()
        if g then
            mr.CFrame = tr.CFrame * CFrame.new(0, 0, 5)
            task.wait(0.05)
            local sr = g:FindFirstChild("Shoot") or ReplicatedStorage:FindFirstChild("Shoot", true)
            if sr and sr:IsA("RemoteEvent") then
                sr:FireServer(tr.CFrame, tr.Position)
            else
                g:Activate()
            end
        else
            sendNotification("MM2 Menu", "You do not have a Gun equipped!", SOUNDS.alert)
        end
    end
end

U.killMurdererBtn = createActionButton("KillMurdererNow", "Kill Murderer Now")
U.killMurdererBtn.MouseButton1Click:Connect(shootMurderer)

-- ═══════════════════════════════════════════════════════════
-- TELEPORT TAB
-- ═══════════════════════════════════════════════════════════
currentParent = U.tabFrames.Teleport
createSectionTitle("PLAYER ACTIONS")

U.pDropdown = Instance.new("TextButton")
U.pDropdown.Size = UDim2.new(1, 0, 0, mn(30))
U.pDropdown.BackgroundColor3 = Color3.fromRGB(34, 36, 43)
U.pDropdown.BorderSizePixel = 0
U.pDropdown.Text = "Select Player"
U.pDropdown.TextColor3 = Color3.fromRGB(230, 230, 235)
U.pDropdown.TextSize = mn(12)
U.pDropdown.Font = Enum.Font.GothamSemibold
U.pDropdown.AutoButtonColor = false
U.pDropdown.LayoutOrder = getLayoutOrder()
U.pDropdown.Parent = currentParent
do local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 8) c.Parent = U.pDropdown end

U.pList = Instance.new("ScrollingFrame")
U.pList.Size = UDim2.new(1, 0, 0, 0)
U.pList.BackgroundColor3 = Color3.fromRGB(29, 30, 37)
U.pList.BorderSizePixel = 0
U.pList.Visible = false
U.pList.ClipsDescendants = true
U.pList.AutomaticCanvasSize = Enum.AutomaticSize.Y
U.pList.ScrollingDirection = Enum.ScrollingDirection.Y
U.pList.ScrollBarThickness = 5
U.pList.ScrollBarImageColor3 = Color3.fromRGB(75, 77, 85)
U.pList.LayoutOrder = getLayoutOrder()
U.pList.Parent = currentParent
do
    local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 8) c.Parent = U.pList
    local l = Instance.new("UIListLayout") l.Padding = UDim.new(0, 2) l.SortOrder = Enum.SortOrder.Name l.Parent = U.pList
end

local function refreshPList()
    for _, ch in ipairs(U.pList:GetChildren()) do
        if ch:IsA("TextButton") then ch:Destroy() end
    end
    for _, t in ipairs(Players:GetPlayers()) do
        if t ~= player then
            local o = Instance.new("TextButton")
            o.Name = t.Name
            o.Size = UDim2.new(1, -mn(10), 0, mn(28))
            o.BackgroundColor3 = Color3.fromRGB(34, 36, 43)
            o.BorderSizePixel = 0
            o.Text = t.DisplayName .. " (@" .. t.Name .. ")"
            o.TextColor3 = Color3.fromRGB(230, 230, 235)
            o.TextSize = mn(12)
            o.Font = Enum.Font.GothamSemibold
            o.AutoButtonColor = false
            o.Parent = U.pList
            do local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 6) c.Parent = o end
            o.MouseButton1Click:Connect(function()
                S.selectedPlayer = t
                U.pDropdown.Text = "Selected: " .. t.Name
                S.dropdownOpen = false
                U.pList.Visible = false
                U.pList.Size = UDim2.new(1, 0, 0, 0)
            end)
        end
    end
end

U.pDropdown.MouseButton1Click:Connect(function()
    S.dropdownOpen = not S.dropdownOpen
    if S.dropdownOpen then
        refreshPList()
        U.pList.Visible = true
        U.pList.Size = UDim2.new(1, 0, 0, mn(120))
    else
        U.pList.Visible = false
        U.pList.Size = UDim2.new(1, 0, 0, 0)
    end
end)

U.playerTpBtn = createActionButton("PlayerTeleport", "Teleport To Player")
U.killSelBtn = createActionButton("KillSelectedPlayer", "Kill Selected Player")

U.playerTpBtn.MouseButton1Click:Connect(function()
    if not S.selectedPlayer or not S.selectedPlayer.Character then return end
    local tr = S.selectedPlayer.Character:FindFirstChild("HumanoidRootPart")
    local c = player.Character
    if c and tr then
        local mr = c:FindFirstChild("HumanoidRootPart")
        if mr then mr.CFrame = tr.CFrame + Vector3.new(0, 3, 0) end
    end
end)

U.killSelBtn.MouseButton1Click:Connect(function()
    if S.selectedPlayer then attackTarget(S.selectedPlayer) end
end)

Players.PlayerAdded:Connect(function() if S.dropdownOpen then refreshPList() end end)
Players.PlayerRemoving:Connect(function(t)
    if S.selectedPlayer == t then S.selectedPlayer = nil U.pDropdown.Text = "Select Player" end
    if S.dropdownOpen then refreshPList() end
end)

createSectionTitle("ROLE TELEPORTS")

local function tpByName(n)
    if not n then return end
    local t = Players:FindFirstChild(n)
    if not t or not t.Character then return end
    local tr = t.Character:FindFirstChild("HumanoidRootPart")
    local c = player.Character
    if c and tr then
        local mr = c:FindFirstChild("HumanoidRootPart")
        if mr then mr.CFrame = tr.CFrame + Vector3.new(0, 3, 0) end
    end
end

U.tpMurdererBtn = createActionButton("TeleportMurderer", "Teleport To Murderer")
U.tpMurdererBtn.MouseButton1Click:Connect(function() tpByName(MurdererName) end)
U.tpSheriffBtn = createActionButton("TeleportSheriff", "Teleport To Sheriff")
U.tpSheriffBtn.MouseButton1Click:Connect(function() tpByName(SheriffName) end)
U.tpHeroBtn = createActionButton("TeleportHero", "Teleport To Hero")
U.tpHeroBtn.MouseButton1Click:Connect(function() tpByName(HeroName) end)

createSectionTitle("WORLD TELEPORTS")

local function findGunPart()
    local gd = workspace:FindFirstChild("GunDrop", true) or workspace:FindFirstChild("Gun", true)
    if not gd then return nil end
    if gd:IsA("BasePart") then return gd end
    if gd:IsA("Model") then return gd.PrimaryPart or gd:FindFirstChildOfClass("BasePart") end
    if gd:IsA("Tool") then return gd:FindFirstChild("Handle") or gd:FindFirstChildOfClass("BasePart") end
    return nil
end

local function tpGunAndBack()
    local c = player.Character
    if not c then return false end
    local mr = c:FindFirstChild("HumanoidRootPart")
    if not mr then return false end
    local tp = findGunPart()
    if not tp then return false end
    local orig = mr.CFrame
    mr.CFrame = tp.CFrame + Vector3.new(0, 3, 0)
    task.wait(0.35)
    mr.CFrame = orig
    return true
end

local function autoTPGunTop()
    local now = tick()
    if now - lastAutoGunTP < 3 then return end
    local c = player.Character
    if not c then return end
    if c:FindFirstChild("Gun") or c:FindFirstChild("Knife") then return end
    local mr = c:FindFirstChild("HumanoidRootPart")
    if not mr then return end
    local tp = findGunPart()
    if not tp then return end
    lastAutoGunTP = now
    mr.CFrame = tp.CFrame + Vector3.new(0, 3, 0)
    task.wait(0.2)
    local safeY = 300
    if MurdererName then
        local murd = Players:FindFirstChild(MurdererName)
        if murd and murd.Character then
            local mRoot = murd.Character:FindFirstChild("HumanoidRootPart")
            if mRoot and (mRoot.Position - tp.Position).Magnitude < 100 then safeY = -100 end
        end
    end
    mr.CFrame = CFrame.new(tp.Position.X, safeY, tp.Position.Z)
    mr.Velocity = Vector3.zero
end

U.autoGunBtn, U.autoGunInd = createToggle("AutoGunTP", "Auto Teleport To Gun")
U.autoGunBtn.MouseButton1Click:Connect(function()
    S.autoGunTP = not S.autoGunTP
    if S.autoGunTP then setOn(U.autoGunBtn, U.autoGunInd) else setOff(U.autoGunBtn, U.autoGunInd) end
end)

U.spawnTpBtn = createActionButton("SpawnTeleport", "Teleport To Spawn")
U.spawnTpBtn.MouseButton1Click:Connect(function()
    local c = player.Character
    if not c then return end
    local mr = c:FindFirstChild("HumanoidRootPart")
    if not mr then return end
    local sl = workspace:FindFirstChildOfClass("SpawnLocation")
    if sl then mr.CFrame = sl.CFrame + Vector3.new(0, 3, 0) return end
    local sp = workspace:FindFirstChild("Spawn", true)
    if sp and sp:IsA("BasePart") then mr.CFrame = sp.CFrame + Vector3.new(0, 3, 0) end
end)

U.gunTpBtn = createActionButton("GunTeleport", "Teleport To Gun")
U.gunTpBtn.MouseButton1Click:Connect(function()
    if not tpGunAndBack() then sendNotification("MM2 Menu", "No dropped gun found on the map!", SOUNDS.alert) end
end)

-- ═══════════════════════════════════════════════════════════
-- KEYBINDS TAB
-- ═══════════════════════════════════════════════════════════
currentParent = U.tabFrames.Keybinds
createSectionTitle("KEYBINDS")

U.kbEnabledBtn, U.kbEnabledInd = createToggle("KeybindsEnabled", "All Keybinds Enabled")
setOn(U.kbEnabledBtn, U.kbEnabledInd)
U.kbEnabledBtn.MouseButton1Click:Connect(function()
    S.keybindsEnabled = not S.keybindsEnabled
    if S.keybindsEnabled then
        setOn(U.kbEnabledBtn, U.kbEnabledInd)
    else
        setRed(U.kbEnabledBtn, U.kbEnabledInd)
    end
    S.homeRebuildDirty = true
end)

local kbInfo = Instance.new("TextLabel")
kbInfo.Size = UDim2.new(1, 0, 0, mn(18))
kbInfo.BackgroundTransparency = 1
kbInfo.Text = "Click a key to rebind. Press ESC to cancel."
kbInfo.TextColor3 = Color3.fromRGB(150, 153, 165)
kbInfo.TextSize = mn(11)
kbInfo.Font = Enum.Font.Gotham
kbInfo.TextXAlignment = Enum.TextXAlignment.Left
kbInfo.LayoutOrder = getLayoutOrder()
kbInfo.Parent = currentParent

U.keyButtons = {}

local function refreshKeyButtons()
    for id, btn in pairs(U.keyButtons) do
        local k = S.keybinds[id]
        btn.Text = k and k.Name or "None"
    end
    S.homeRebuildDirty = true
end

local function startCapture(id, btn)
    S.capturingKeybind = true
    S.capturingAction = id
    btn.Text = "[press key]"
    btn.BackgroundColor3 = Color3.fromRGB(80, 60, 40)
end

local function endCapture()
    S.capturingKeybind = false
    S.capturingAction = nil
    for _, btn in pairs(U.keyButtons) do
        btn.BackgroundColor3 = Color3.fromRGB(50, 55, 65)
    end
    refreshKeyButtons()
end

for _, entry in ipairs(S.keybindList) do
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, mn(30))
    row.BackgroundColor3 = Color3.fromRGB(34, 36, 43)
    row.BorderSizePixel = 0
    row.LayoutOrder = getLayoutOrder()
    row.Parent = currentParent
    do local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 8) c.Parent = row end

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -mn(100), 1, 0)
    lbl.Position = mpos(10, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = entry.name
    lbl.TextColor3 = Color3.fromRGB(230, 230, 235)
    lbl.TextSize = mn(12)
    lbl.Font = Enum.Font.GothamSemibold
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = row

    local kb = Instance.new("TextButton")
    kb.Size = msz(80, 22)
    kb.Position = UDim2.new(1, -mn(90), 0.5, -mn(11))
    kb.BackgroundColor3 = Color3.fromRGB(50, 55, 65)
    kb.BorderSizePixel = 0
    kb.Text = (S.keybinds[entry.id] and S.keybinds[entry.id].Name) or "None"
    kb.TextColor3 = Color3.fromRGB(230, 230, 235)
    kb.TextSize = mn(11)
    kb.Font = Enum.Font.GothamBold
    kb.AutoButtonColor = false
    kb.Parent = row
    do local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 6) c.Parent = kb end

    U.keyButtons[entry.id] = kb
    kb.MouseButton1Click:Connect(function()
        startCapture(entry.id, kb)
    end)
end

-- ═══════════════════════════════════════════════════════════
-- SETTINGS TAB
-- ═══════════════════════════════════════════════════════════
currentParent = U.tabFrames.Settings
createSectionTitle("MENU SETTINGS")

U.opacityLbl = Instance.new("TextLabel")
U.opacityLbl.Size = UDim2.new(1, 0, 0, mn(18))
U.opacityLbl.BackgroundTransparency = 1
U.opacityLbl.Text = "Menu Opacity: 100%"
U.opacityLbl.TextColor3 = Color3.fromRGB(150, 153, 165)
U.opacityLbl.TextSize = mn(11)
U.opacityLbl.Font = Enum.Font.GothamBold
U.opacityLbl.TextXAlignment = Enum.TextXAlignment.Left
U.opacityLbl.LayoutOrder = getLayoutOrder()
U.opacityLbl.Parent = currentParent

U.opacitySlider = Instance.new("TextButton")
U.opacitySlider.Size = UDim2.new(1, 0, 0, mn(30))
U.opacitySlider.BackgroundColor3 = Color3.fromRGB(34, 36, 43)
U.opacitySlider.BorderSizePixel = 0
U.opacitySlider.Text = ""
U.opacitySlider.AutoButtonColor = false
U.opacitySlider.LayoutOrder = getLayoutOrder()
U.opacitySlider.Parent = currentParent
do local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 8) c.Parent = U.opacitySlider end

U.opacityFill = Instance.new("Frame")
U.opacityFill.Size = UDim2.new(1, 0, 1, 0)
U.opacityFill.BackgroundColor3 = Color3.fromRGB(60, 130, 80)
U.opacityFill.BorderSizePixel = 0
U.opacityFill.Parent = U.opacitySlider
do local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 8) c.Parent = U.opacityFill end

U.opacityHandle = Instance.new("Frame")
U.opacityHandle.Size = msz(6, 24)
U.opacityHandle.Position = UDim2.new(1, -mn(6), 0.5, -mn(12))
U.opacityHandle.BackgroundColor3 = Color3.fromRGB(220, 220, 230)
U.opacityHandle.BorderSizePixel = 0
U.opacityHandle.ZIndex = 2
U.opacityHandle.Parent = U.opacitySlider
do local c = Instance.new("UICorner") c.CornerRadius = UDim.new(1, 0) c.Parent = U.opacityHandle end

local opacityDragging = false
local function applyOpacity(pct)
    pct = math.clamp(pct, 10, 100)
    S.menuOpacity = pct
    U.opacityLbl.Text = "Menu Opacity: " .. tostring(pct) .. "%"
    U.opacityFill.Size = UDim2.new(pct / 100, 0, 1, 0)
    U.opacityHandle.Position = UDim2.new(pct / 100, -mn(6), 0.5, -mn(12))
    U.canvas.GroupTransparency = 1 - (pct / 100)
end

U.opacitySlider.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
        opacityDragging = true
    end
end)
UserInputService.InputChanged:Connect(function(i)
    if not opacityDragging then return end
    if i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch then
        local rel = (i.Position.X - U.opacitySlider.AbsolutePosition.X) / U.opacitySlider.AbsoluteSize.X
        applyOpacity(math.floor(rel * 100))
    end
end)
UserInputService.InputEnded:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
        opacityDragging = false
    end
end)

applyOpacity(100)

U.menuSoundLbl = Instance.new("TextLabel")
U.menuSoundLbl.Size = UDim2.new(1, 0, 0, mn(18))
U.menuSoundLbl.BackgroundTransparency = 1
U.menuSoundLbl.Text = "Menu Sound Volume: 100%"
U.menuSoundLbl.TextColor3 = Color3.fromRGB(150, 153, 165)
U.menuSoundLbl.TextSize = mn(11)
U.menuSoundLbl.Font = Enum.Font.GothamBold
U.menuSoundLbl.TextXAlignment = Enum.TextXAlignment.Left
U.menuSoundLbl.LayoutOrder = getLayoutOrder()
U.menuSoundLbl.Parent = currentParent

U.menuSoundSlider = Instance.new("TextButton")
U.menuSoundSlider.Size = UDim2.new(1, 0, 0, mn(30))
U.menuSoundSlider.BackgroundColor3 = Color3.fromRGB(34, 36, 43)
U.menuSoundSlider.BorderSizePixel = 0
U.menuSoundSlider.Text = ""
U.menuSoundSlider.AutoButtonColor = false
U.menuSoundSlider.LayoutOrder = getLayoutOrder()
U.menuSoundSlider.Parent = currentParent
do local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 8) c.Parent = U.menuSoundSlider end

U.menuSoundFill = Instance.new("Frame")
U.menuSoundFill.Size = UDim2.new(1, 0, 1, 0)
U.menuSoundFill.BackgroundColor3 = Color3.fromRGB(70, 110, 160)
U.menuSoundFill.BorderSizePixel = 0
U.menuSoundFill.Parent = U.menuSoundSlider
do local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 8) c.Parent = U.menuSoundFill end

U.menuSoundHandle = Instance.new("Frame")
U.menuSoundHandle.Size = msz(6, 24)
U.menuSoundHandle.Position = UDim2.new(1, -mn(6), 0.5, -mn(12))
U.menuSoundHandle.BackgroundColor3 = Color3.fromRGB(220, 220, 230)
U.menuSoundHandle.BorderSizePixel = 0
U.menuSoundHandle.ZIndex = 2
U.menuSoundHandle.Parent = U.menuSoundSlider
do local c = Instance.new("UICorner") c.CornerRadius = UDim.new(1, 0) c.Parent = U.menuSoundHandle end

local menuSoundDragging = false
local function applyMenuSound(pct)
    pct = math.clamp(pct, 0, 100)
    S.menuVolume = pct
    U.menuSoundLbl.Text = "Menu Sound Volume: " .. tostring(pct) .. "%"
    U.menuSoundFill.Size = UDim2.new(pct / 100, 0, 1, 0)
    U.menuSoundHandle.Position = UDim2.new(pct / 100, -mn(6), 0.5, -mn(12))
end

U.menuSoundSlider.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
        menuSoundDragging = true
    end
end)
UserInputService.InputChanged:Connect(function(i)
    if not menuSoundDragging then return end
    if i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch then
        local rel = (i.Position.X - U.menuSoundSlider.AbsolutePosition.X) / U.menuSoundSlider.AbsoluteSize.X
        applyMenuSound(math.floor(rel * 100))
    end
end)
UserInputService.InputEnded:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
        if menuSoundDragging then
            playSound(SOUNDS.notify, 1, false)
        end
        menuSoundDragging = false
    end
end)

applyMenuSound(100)

U.killSoundLbl = Instance.new("TextLabel")
U.killSoundLbl.Size = UDim2.new(1, 0, 0, mn(18))
U.killSoundLbl.BackgroundTransparency = 1
U.killSoundLbl.Text = "Kill Sound Volume: 100%"
U.killSoundLbl.TextColor3 = Color3.fromRGB(150, 153, 165)
U.killSoundLbl.TextSize = mn(11)
U.killSoundLbl.Font = Enum.Font.GothamBold
U.killSoundLbl.TextXAlignment = Enum.TextXAlignment.Left
U.killSoundLbl.LayoutOrder = getLayoutOrder()
U.killSoundLbl.Parent = currentParent

U.killSoundSlider = Instance.new("TextButton")
U.killSoundSlider.Size = UDim2.new(1, 0, 0, mn(30))
U.killSoundSlider.BackgroundColor3 = Color3.fromRGB(34, 36, 43)
U.killSoundSlider.BorderSizePixel = 0
U.killSoundSlider.Text = ""
U.killSoundSlider.AutoButtonColor = false
U.killSoundSlider.LayoutOrder = getLayoutOrder()
U.killSoundSlider.Parent = currentParent
do local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 8) c.Parent = U.killSoundSlider end

U.killSoundFill = Instance.new("Frame")
U.killSoundFill.Size = UDim2.new(1, 0, 1, 0)
U.killSoundFill.BackgroundColor3 = Color3.fromRGB(160, 70, 70)
U.killSoundFill.BorderSizePixel = 0
U.killSoundFill.Parent = U.killSoundSlider
do local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 8) c.Parent = U.killSoundFill end

U.killSoundHandle = Instance.new("Frame")
U.killSoundHandle.Size = msz(6, 24)
U.killSoundHandle.Position = UDim2.new(1, -mn(6), 0.5, -mn(12))
U.killSoundHandle.BackgroundColor3 = Color3.fromRGB(220, 220, 230)
U.killSoundHandle.BorderSizePixel = 0
U.killSoundHandle.ZIndex = 2
U.killSoundHandle.Parent = U.killSoundSlider
do local c = Instance.new("UICorner") c.CornerRadius = UDim.new(1, 0) c.Parent = U.killSoundHandle end

local killSoundDragging = false
local function applyKillSound(pct)
    pct = math.clamp(pct, 0, 100)
    S.killVolume = pct
    U.killSoundLbl.Text = "Kill Sound Volume: " .. tostring(pct) .. "%"
    U.killSoundFill.Size = UDim2.new(pct / 100, 0, 1, 0)
    U.killSoundHandle.Position = UDim2.new(pct / 100, -mn(6), 0.5, -mn(12))
end

U.killSoundSlider.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
        killSoundDragging = true
    end
end)
UserInputService.InputChanged:Connect(function(i)
    if not killSoundDragging then return end
    if i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch then
        local rel = (i.Position.X - U.killSoundSlider.AbsolutePosition.X) / U.killSoundSlider.AbsoluteSize.X
        applyKillSound(math.floor(rel * 100))
    end
end)
UserInputService.InputEnded:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
        if killSoundDragging then
            playSound(SOUNDS.success, 1.5, true)
        end
        killSoundDragging = false
    end
end)

applyKillSound(100)

-- ═══════════════════════════════════════════════════════════
-- UTILITY TAB
-- ═══════════════════════════════════════════════════════════
currentParent = U.tabFrames.Utility
createSectionTitle("UTILITY")

U.avBtn, U.avInd = createToggle("AntiVoid", "Anti Fall Down (Void)")
U.avBtn.MouseButton1Click:Connect(function()
    S.antiVoidEnabled = not S.antiVoidEnabled
    if S.antiVoidEnabled then setOn(U.avBtn, U.avInd) else setOff(U.avBtn, U.avInd) end
end)

U.afBtn, U.afInd = createToggle("AntiFling", "Anti Fling")
U.afBtn.MouseButton1Click:Connect(function()
    S.antiFlingEnabled = not S.antiFlingEnabled
    if S.antiFlingEnabled then setOn(U.afBtn, U.afInd) else setOff(U.afBtn, U.afInd) end
end)

U.afkBtn, U.afkInd = createToggle("AntiAfk", "Anti AFK")
U.afkBtn.MouseButton1Click:Connect(function()
    S.antiAfkEnabled = not S.antiAfkEnabled
    if S.antiAfkEnabled then
        setOn(U.afkBtn, U.afkInd)
        if S.antiAfkConn then S.antiAfkConn:Disconnect() S.antiAfkConn = nil end
        S.antiAfkConn = player.Idled:Connect(function()
            local VU = game:GetService("VirtualUser")
            VU:CaptureController()
            VU:ClickButton2(Vector2.new())
        end)
    else
        setOff(U.afkBtn, U.afkInd)
        if S.antiAfkConn then S.antiAfkConn:Disconnect() S.antiAfkConn = nil end
    end
end)

U.gunAlertBtn, U.gunAlertInd = createToggle("GunDropAlert", "Gun Drop Alert")
U.gunAlertBtn.MouseButton1Click:Connect(function()
    S.gunDropAlert = not S.gunDropAlert
    if S.gunDropAlert then setOn(U.gunAlertBtn, U.gunAlertInd) else setOff(U.gunAlertBtn, U.gunAlertInd) end
end)

createSectionTitle("OVERLAYS")

U.killerAlarmBtn, U.killerAlarmInd = createToggle("KillerAlarm", "Killer Alarm (30 studs, closer only)")
U.killerAlarmBtn.MouseButton1Click:Connect(function()
    S.killerAlarmOn = not S.killerAlarmOn
    if S.killerAlarmOn then
        setOn(U.killerAlarmBtn, U.killerAlarmInd)
        S.lastAlarmDist = math.huge
        S.lastAlarmTime = 0
    else
        setOff(U.killerAlarmBtn, U.killerAlarmInd)
        S.lastAlarmDist = math.huge
    end
end)

U.camFollowBtn, U.camFollowInd = createToggle("CameraFollowMurderer", "Camera Follow Murderer")
U.camFollowBtn.MouseButton1Click:Connect(function()
    S.cameraFollowMurderer = not S.cameraFollowMurderer
    if S.cameraFollowMurderer then setOn(U.camFollowBtn, U.camFollowInd) else setOff(U.camFollowBtn, U.camFollowInd) end
end)

U.crosshairBtn, U.crosshairInd = createToggle("Crosshair", "Rainbow Crosshair (follows mouse)")
U.crosshairBtn.MouseButton1Click:Connect(function()
    if IS_MOBILE then
        sendNotification("MM2 Menu", "Crosshair is not needed on mobile - your finger is the crosshair.", SOUNDS.alert)
        return
    end
    S.crosshairOn = not S.crosshairOn
    if S.crosshairOn then
        setOn(U.crosshairBtn, U.crosshairInd)
        if S.crosshairGui then S.crosshairGui.Enabled = true end
    else
        setOff(U.crosshairBtn, U.crosshairInd)
        if S.crosshairGui then S.crosshairGui.Enabled = false end
    end
end)

createSectionTitle("TRAILS")

U.killerTrailBtn, U.killerTrailInd = createToggle("KillerTrail", "Killer Trail")
U.killerTrailBtn.MouseButton1Click:Connect(function()
    S.killerTrailOn = not S.killerTrailOn
    if S.killerTrailOn then setOn(U.killerTrailBtn, U.killerTrailInd) else setOff(U.killerTrailBtn, U.killerTrailInd) end
end)

U.sheriffTrailBtn, U.sheriffTrailInd = createToggle("SheriffTrail", "Sheriff Trail")
U.sheriffTrailBtn.MouseButton1Click:Connect(function()
    S.sheriffTrailOn = not S.sheriffTrailOn
    if S.sheriffTrailOn then setOn(U.sheriffTrailBtn, U.sheriffTrailInd) else setOff(U.sheriffTrailBtn, U.sheriffTrailInd) end
end)

U.heroTrailBtn, U.heroTrailInd = createToggle("HeroTrail", "Hero Trail")
U.heroTrailBtn.MouseButton1Click:Connect(function()
    S.heroTrailOn = not S.heroTrailOn
    if S.heroTrailOn then setOn(U.heroTrailBtn, U.heroTrailInd) else setOff(U.heroTrailBtn, U.heroTrailInd) end
end)

createSectionTitle("SERVER")

U.rejoinBtn = createActionButton("Rejoin", "Rejoin Server")
U.rejoinBtn.MouseButton1Click:Connect(function()
    sendNotification("MM2 Menu", "Rejoining server...")
    task.wait(0.5)
    local ok = pcall(function() TeleportService:Teleport(game.PlaceId, player) end)
    if not ok then
        pcall(function() TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, player) end)
    end
end)

U.hopBtn = createActionButton("ServerHop", "Server Hop")
U.hopBtn.MouseButton1Click:Connect(function()
    if S.hopping then return end
    S.hopping = true
    sendNotification("MM2 Menu", "Searching servers...", SOUNDS.notify)

    task.spawn(function()
        local ok, err = pcall(function()
            local url = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Desc&limit=100"
            local response = game:HttpGet(url)
            local data = HttpService:JSONDecode(response)
            if not data or not data.data or #data.data == 0 then
                sendNotification("MM2 Menu", "No other servers available", SOUNDS.alert)
                return
            end

            local candidates = {}
            for _, srv in ipairs(data.data) do
                if srv.id ~= game.JobId and srv.playing < srv.maxPlayers then
                    table.insert(candidates, srv)
                end
            end

            if #candidates == 0 then
                sendNotification("MM2 Menu", "All servers are full", SOUNDS.alert)
                return
            end

            local pick = candidates[math.random(1, #candidates)]
            sendNotification("MM2 Menu", "Hopping to " .. pick.playing .. "/" .. pick.maxPlayers .. " server...", SOUNDS.notify)
            task.wait(0.5)
            TeleportService:TeleportToPlaceInstance(game.PlaceId, pick.id, player)
        end)
        if not ok then
            sendNotification("MM2 Menu", "Server hop failed - try again", SOUNDS.alert)
        end
        S.hopping = false
    end)
end)

resetAllToggles = function()
    if S.noclip then
        S.noclip = false
        setOff(U.noclipBtn, U.noclipInd)
        for o, v in pairs(S.originalCollision) do if o and o.Parent then o.CanCollide = v end end
        S.originalCollision = {}
    end
    if S.flyEnabled then stopFly() end
    S.flyPanelOpen = false
    FP.panel.Visible = false
    if S.infinityJump then S.infinityJump = false setOff(U.infBtn, U.infInd) end
    if S.flingThirdParty then S.flingThirdParty = false setOff(U.f3Btn, U.f3Ind) end
    if S.flingOnTouch then S.flingOnTouch = false S.flingTouchActive = false setOff(U.fib, U.fii) end
    if S.speedhackEnabled then
        S.speedhackEnabled = false
        setOff(U.shBtn, U.shInd)
        local c = player.Character
        if c then local h = c:FindFirstChildOfClass("Humanoid") if h then h.WalkSpeed = 16 end end
    end
    for r, st in pairs(S.espEnabled) do
        if st then
            S.espEnabled[r] = false
            if espButtons[r] then setOff(espButtons[r].Button, espButtons[r].Indicator) end
        end
    end
    if S.gunESPEnabled then
        S.gunESPEnabled = false
        setOff(U.gunBtn, U.gunInd)
        for g, hl in pairs(S.gunHighlights) do if hl then pcall(function() hl:Destroy() end) end end
        S.gunHighlights = {}
    end
    if S.playerDistanceOn then
        S.playerDistanceOn = false
        setOff(U.distBtn, U.distInd)
        for p, bg in pairs(S.playerDistBillboards) do if bg then bg:Destroy() end end
        S.playerDistBillboards = {}
    end
    if S.autoNotifyRoles then
        S.autoNotifyRoles = false
        setOff(U.autoNotBtn, U.autoNotInd)
        lastNotifiedMurderer = nil
        lastNotifiedSheriff = nil
        lastNotifiedHero = nil
        S.pendingNotify = false
    end
    if S.autoSendMurdererChat then
        S.autoSendMurdererChat = false
        setOff(U.autoChatBtn, U.autoChatInd)
        S.lastChatSentMurderer = nil
        S.roundActive = false
        S.selfNotifyMurderer = false
    end
    if S.autoSendSheriffChat then
        S.autoSendSheriffChat = false
        setOff(U.autoSheriffChatBtn, U.autoSheriffChatInd)
        S.lastChatSentSheriff = nil
        S.roundActiveSheriff = false
        S.selfNotifySheriff = false
    end
    if S.autoKillAll then S.autoKillAll = false setOff(U.autoKillBtn, U.autoKillInd) end
    if S.autoGunTP then S.autoGunTP = false setOff(U.autoGunBtn, U.autoGunInd) end
    if S.antiVoidEnabled then S.antiVoidEnabled = false setOff(U.avBtn, U.avInd) end
    if S.antiFlingEnabled then S.antiFlingEnabled = false setOff(U.afBtn, U.afInd) end
    if S.antiAfkEnabled then
        S.antiAfkEnabled = false
        setOff(U.afkBtn, U.afkInd)
        if S.antiAfkConn then S.antiAfkConn:Disconnect() S.antiAfkConn = nil end
    end
    if S.killerAlarmOn then S.killerAlarmOn = false setOff(U.killerAlarmBtn, U.killerAlarmInd) end
    if S.cameraFollowMurderer then S.cameraFollowMurderer = false setOff(U.camFollowBtn, U.camFollowInd) end
    if S.crosshairOn then
        S.crosshairOn = false
        setOff(U.crosshairBtn, U.crosshairInd)
        if S.crosshairGui then S.crosshairGui.Enabled = false end
    end
    if S.gunDropAlert then S.gunDropAlert = false setOff(U.gunAlertBtn, U.gunAlertInd) end
    if S.killerTrailOn then S.killerTrailOn = false setOff(U.killerTrailBtn, U.killerTrailInd) end
    if S.sheriffTrailOn then S.sheriffTrailOn = false setOff(U.sheriffTrailBtn, U.sheriffTrailInd) end
    if S.heroTrailOn then S.heroTrailOn = false setOff(U.heroTrailBtn, U.heroTrailInd) end
    if S.killSoundOn then S.killSoundOn = false setOff(U.killSoundBtn, U.killSoundInd) end
    if S.notifyRoundStart then S.notifyRoundStart = false setOff(U.rStartBtn, U.rStartInd) end
    if S.notifyRoundEnd then S.notifyRoundEnd = false setOff(U.rEndBtn, U.rEndInd) end
    if S.playerJoinLeaveNotify then S.playerJoinLeaveNotify = false setOff(U.plBtn, U.plInd) end
    sendNotification("MM2 Menu", "All features turned off")
end

-- ═══════════════════════════════════════════════════════════
-- CROSSHAIR
-- ═══════════════════════════════════════════════════════════
local CH_LEN = math.max(3, mn(20))
local CH_THICK = math.max(2, mn(2))
local CH_DOT = math.max(3, mn(3))

S.crosshairGui = Instance.new("ScreenGui")
S.crosshairGui.Name = "MM2Crosshair"
S.crosshairGui.ResetOnSpawn = false
S.crosshairGui.DisplayOrder = 200
S.crosshairGui.Enabled = false
S.crosshairGui.Parent = playerGui
do
    U.crosshairH = Instance.new("Frame")
    U.crosshairH.Size = UDim2.fromOffset(CH_LEN, CH_THICK)
    U.crosshairH.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    U.crosshairH.BorderSizePixel = 0
    U.crosshairH.Parent = S.crosshairGui
    U.crosshairV = Instance.new("Frame")
    U.crosshairV.Size = UDim2.fromOffset(CH_THICK, CH_LEN)
    U.crosshairV.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    U.crosshairV.BorderSizePixel = 0
    U.crosshairV.Parent = S.crosshairGui
    U.crosshairDot = Instance.new("Frame")
    U.crosshairDot.Size = UDim2.fromOffset(CH_DOT, CH_DOT)
    U.crosshairDot.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    U.crosshairDot.BorderSizePixel = 0
    U.crosshairDot.Parent = S.crosshairGui
end

-- ═══════════════════════════════════════════════════════════
-- CONFIG TAB
-- ═══════════════════════════════════════════════════════════
currentParent = U.tabFrames.Config
createSectionTitle("NOTIFICATION CONTROLS")

U.allNotifyBtn = createActionButton("EnableAllNotify", "Enable All Notifications")
U.allNotifyBtn.BackgroundColor3 = Color3.fromRGB(40, 60, 85)
U.allNotifyBtn.MouseButton1Click:Connect(function()
    if not S.notifyRoundStart then S.notifyRoundStart = true setOn(U.rStartBtn, U.rStartInd) end
    if not S.notifyRoundEnd then S.notifyRoundEnd = true setOn(U.rEndBtn, U.rEndInd) end
    if not S.playerJoinLeaveNotify then S.playerJoinLeaveNotify = true setOn(U.plBtn, U.plInd) end
    if not S.gunDropAlert then S.gunDropAlert = true setOn(U.gunAlertBtn, U.gunAlertInd) end
    if not S.autoNotifyRoles then S.autoNotifyRoles = true setOn(U.autoNotBtn, U.autoNotInd) end
    sendNotification("MM2 Menu", "All notifications enabled")
end)

createSectionTitle("PRESET INFO")
local pInfo = Instance.new("TextLabel")
pInfo.Size = UDim2.new(1, 0, 0, mn(180))
pInfo.BackgroundTransparency = 1
pInfo.Text = "PVP Ready (Home tab) turns ON:\n- Anti AFK, Anti Void, Anti Fling\n- All 4 ESPs + Gun ESP\n- Noclip\n- Auto Notify Round\n- Auto Kill All\n- Killer Alarm (30 studs)\n- Rainbow Crosshair (PC only)\n- Gun Drop Alert\n- Round Start / End Notify\n- Player Join/Leave Alerts\n- Kill Sound\n\nRestore (Home tab) reverts to\nsettings from before PVP Ready."
pInfo.TextColor3 = Color3.fromRGB(180, 182, 190)
pInfo.TextSize = mn(11)
pInfo.Font = Enum.Font.Gotham
pInfo.TextXAlignment = Enum.TextXAlignment.Left
pInfo.TextYAlignment = Enum.TextYAlignment.Top
pInfo.LayoutOrder = getLayoutOrder()
pInfo.Parent = currentParent

-- snapshot / restore / preset
local function snapshotCurrentSettings()
    return {
        antiAfkEnabled = S.antiAfkEnabled,
        antiVoidEnabled = S.antiVoidEnabled,
        antiFlingEnabled = S.antiFlingEnabled,
        esp = {
            Innocent = S.espEnabled.Innocent,
            Murderer = S.espEnabled.Murderer,
            Sheriff = S.espEnabled.Sheriff,
            Hero = S.espEnabled.Hero,
        },
        gunESPEnabled = S.gunESPEnabled,
        noclip = S.noclip,
        autoNotifyRoles = S.autoNotifyRoles,
        autoKillAll = S.autoKillAll,
        killerAlarmOn = S.killerAlarmOn,
        crosshairOn = S.crosshairOn,
        gunDropAlert = S.gunDropAlert,
        notifyRoundStart = S.notifyRoundStart,
        notifyRoundEnd = S.notifyRoundEnd,
        playerJoinLeaveNotify = S.playerJoinLeaveNotify,
        killSoundOn = S.killSoundOn,
    }
end

local function applySnapshot(snap)
    if snap.antiAfkEnabled then
        if not S.antiAfkEnabled then
            S.antiAfkEnabled = true
            setOn(U.afkBtn, U.afkInd)
            if S.antiAfkConn then S.antiAfkConn:Disconnect() end
            S.antiAfkConn = player.Idled:Connect(function()
                local VU = game:GetService("VirtualUser")
                VU:CaptureController()
                VU:ClickButton2(Vector2.new())
            end)
        end
    else
        if S.antiAfkEnabled then
            S.antiAfkEnabled = false
            setOff(U.afkBtn, U.afkInd)
            if S.antiAfkConn then S.antiAfkConn:Disconnect() S.antiAfkConn = nil end
        end
    end
    if snap.antiVoidEnabled ~= S.antiVoidEnabled then
        S.antiVoidEnabled = snap.antiVoidEnabled
        if S.antiVoidEnabled then setOn(U.avBtn, U.avInd) else setOff(U.avBtn, U.avInd) end
    end
    if snap.antiFlingEnabled ~= S.antiFlingEnabled then
        S.antiFlingEnabled = snap.antiFlingEnabled
        if S.antiFlingEnabled then setOn(U.afBtn, U.afInd) else setOff(U.afBtn, U.afInd) end
    end
    for role, state in pairs(snap.esp) do
        if state ~= S.espEnabled[role] then
            S.espEnabled[role] = state
            if espButtons[role] then
                if state then
                    espButtons[role].Button.BackgroundColor3 = ROLE_COLORS[role]:Lerp(Color3.fromRGB(20, 20, 25), 0.65)
                    espButtons[role].Indicator.BackgroundColor3 = ROLE_COLORS[role]
                else
                    setOff(espButtons[role].Button, espButtons[role].Indicator)
                end
            end
        end
    end
    if snap.gunESPEnabled ~= S.gunESPEnabled then
        S.gunESPEnabled = snap.gunESPEnabled
        if S.gunESPEnabled then
            U.gunBtn.BackgroundColor3 = GUN_COLOR:Lerp(Color3.fromRGB(20, 20, 25), 0.65)
            U.gunInd.BackgroundColor3 = GUN_COLOR
        else
            setOff(U.gunBtn, U.gunInd)
            for g, hl in pairs(S.gunHighlights) do if hl then pcall(function() hl:Destroy() end) end end
            S.gunHighlights = {}
        end
    end
    if snap.noclip ~= S.noclip then
        S.noclip = snap.noclip
        if S.noclip then
            setOn(U.noclipBtn, U.noclipInd)
            S.originalCollision = {}
            if player.Character then
                for _, o in ipairs(player.Character:GetDescendants()) do
                    if o:IsA("BasePart") then
                        S.originalCollision[o] = o.CanCollide
                        o.CanCollide = false
                    end
                end
            end
        else
            setOff(U.noclipBtn, U.noclipInd)
            for o, v in pairs(S.originalCollision) do if o and o.Parent then o.CanCollide = v end end
            S.originalCollision = {}
        end
    end
    if snap.autoNotifyRoles ~= S.autoNotifyRoles then
        S.autoNotifyRoles = snap.autoNotifyRoles
        if S.autoNotifyRoles then
            setOn(U.autoNotBtn, U.autoNotInd)
        else
            setOff(U.autoNotBtn, U.autoNotInd)
            lastNotifiedMurderer = nil
            lastNotifiedSheriff = nil
            lastNotifiedHero = nil
            S.pendingNotify = false
        end
    end
    if snap.autoKillAll ~= S.autoKillAll then
        S.autoKillAll = snap.autoKillAll
        if S.autoKillAll then setOn(U.autoKillBtn, U.autoKillInd) else setOff(U.autoKillBtn, U.autoKillInd) end
    end
    if snap.killerAlarmOn ~= S.killerAlarmOn then
        S.killerAlarmOn = snap.killerAlarmOn
        if S.killerAlarmOn then
            setOn(U.killerAlarmBtn, U.killerAlarmInd)
            S.lastAlarmDist = math.huge
            S.lastAlarmTime = 0
        else
            setOff(U.killerAlarmBtn, U.killerAlarmInd)
            S.lastAlarmDist = math.huge
        end
    end
    if snap.crosshairOn ~= S.crosshairOn then
        S.crosshairOn = snap.crosshairOn
        if S.crosshairOn then
            setOn(U.crosshairBtn, U.crosshairInd)
            if S.crosshairGui then S.crosshairGui.Enabled = true end
        else
            setOff(U.crosshairBtn, U.crosshairInd)
            if S.crosshairGui then S.crosshairGui.Enabled = false end
        end
    end
    if snap.gunDropAlert ~= S.gunDropAlert then
        S.gunDropAlert = snap.gunDropAlert
        if S.gunDropAlert then setOn(U.gunAlertBtn, U.gunAlertInd) else setOff(U.gunAlertBtn, U.gunAlertInd) end
    end
    if snap.notifyRoundStart ~= S.notifyRoundStart then
        S.notifyRoundStart = snap.notifyRoundStart
        if S.notifyRoundStart then setOn(U.rStartBtn, U.rStartInd) else setOff(U.rStartBtn, U.rStartInd) end
    end
    if snap.notifyRoundEnd ~= S.notifyRoundEnd then
        S.notifyRoundEnd = snap.notifyRoundEnd
        if S.notifyRoundEnd then setOn(U.rEndBtn, U.rEndInd) else setOff(U.rEndBtn, U.rEndInd) end
    end
    if snap.playerJoinLeaveNotify ~= S.playerJoinLeaveNotify then
        S.playerJoinLeaveNotify = snap.playerJoinLeaveNotify
        if S.playerJoinLeaveNotify then setOn(U.plBtn, U.plInd) else setOff(U.plBtn, U.plInd) end
    end
    if snap.killSoundOn ~= S.killSoundOn then
        S.killSoundOn = snap.killSoundOn
        if S.killSoundOn then setOn(U.killSoundBtn, U.killSoundInd) else setOff(U.killSoundBtn, U.killSoundInd) end
    end
end

applyPvpPreset = function()
    if not S.pvpSnapshot then
        S.pvpSnapshot = snapshotCurrentSettings()
    end
    if not S.antiAfkEnabled then
        S.antiAfkEnabled = true
        setOn(U.afkBtn, U.afkInd)
        if S.antiAfkConn then S.antiAfkConn:Disconnect() end
        S.antiAfkConn = player.Idled:Connect(function()
            local VU = game:GetService("VirtualUser")
            VU:CaptureController()
            VU:ClickButton2(Vector2.new())
        end)
    end
    if not S.antiVoidEnabled then S.antiVoidEnabled = true setOn(U.avBtn, U.avInd) end
    if not S.antiFlingEnabled then S.antiFlingEnabled = true setOn(U.afBtn, U.afInd) end
    for r, st in pairs(S.espEnabled) do
        if not st then
            S.espEnabled[r] = true
            if espButtons[r] then
                espButtons[r].Button.BackgroundColor3 = ROLE_COLORS[r]:Lerp(Color3.fromRGB(20, 20, 25), 0.65)
                espButtons[r].Indicator.BackgroundColor3 = ROLE_COLORS[r]
            end
        end
    end
    if not S.gunESPEnabled then
        S.gunESPEnabled = true
        U.gunBtn.BackgroundColor3 = GUN_COLOR:Lerp(Color3.fromRGB(20, 20, 25), 0.65)
        U.gunInd.BackgroundColor3 = GUN_COLOR
    end
    if not S.noclip then
        S.noclip = true
        setOn(U.noclipBtn, U.noclipInd)
        S.originalCollision = {}
        if player.Character then
            for _, o in ipairs(player.Character:GetDescendants()) do
                if o:IsA("BasePart") then
                    S.originalCollision[o] = o.CanCollide
                    o.CanCollide = false
                end
            end
        end
    end
    if not S.autoNotifyRoles then S.autoNotifyRoles = true setOn(U.autoNotBtn, U.autoNotInd) end
    if not S.autoKillAll then S.autoKillAll = true setOn(U.autoKillBtn, U.autoKillInd) end
    if not S.killerAlarmOn then
        S.killerAlarmOn = true
        S.lastAlarmDist = math.huge
        S.lastAlarmTime = 0
        setOn(U.killerAlarmBtn, U.killerAlarmInd)
    end
    if not IS_MOBILE and not S.crosshairOn then
        S.crosshairOn = true
        setOn(U.crosshairBtn, U.crosshairInd)
        if S.crosshairGui then S.crosshairGui.Enabled = true end
    end
    if not S.gunDropAlert then S.gunDropAlert = true setOn(U.gunAlertBtn, U.gunAlertInd) end
    if not S.notifyRoundStart then S.notifyRoundStart = true setOn(U.rStartBtn, U.rStartInd) end
    if not S.notifyRoundEnd then S.notifyRoundEnd = true setOn(U.rEndBtn, U.rEndInd) end
    if not S.playerJoinLeaveNotify then S.playerJoinLeaveNotify = true setOn(U.plBtn, U.plInd) end
    if not S.killSoundOn then S.killSoundOn = true setOn(U.killSoundBtn, U.killSoundInd) end
end

restorePvpSnapshot = function()
    if not S.pvpSnapshot then
        sendNotification("MM2 Menu", "No previous settings to restore", SOUNDS.alert)
        return
    end
    applySnapshot(S.pvpSnapshot)
    S.pvpSnapshot = nil
    sendNotification("MM2 Menu", "Restored previous settings")
end

-- ═══════════════════════════════════════════════════════════
-- ESP SYSTEM
-- ═══════════════════════════════════════════════════════════
local function mkHL(t)
    if t == player or not t.Character then return end
    local h = t.Character:FindFirstChild("RoleESP")
    if not h then
        h = Instance.new("Highlight")
        h.Name = "RoleESP"
        h.FillTransparency = 0.45
        h.OutlineTransparency = 0
        h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        h.Parent = t.Character
    end
    highlights[t] = h
end

local function isAlive(t)
    if not t or not t.Character then return false end
    local h = t.Character:FindFirstChildOfClass("Humanoid")
    return h and h.Health > 0
end

local function validHolder(n)
    if not n then return false end
    local t = Players:FindFirstChild(n)
    if not t then return false end
    if not t.Character then return false end
    local h = t.Character:FindFirstChildOfClass("Humanoid")
    if not h or h.Health <= 0 then return false end
    if t ~= player and isPlayerInSpawn(t) then return false end
    return true
end

local function roundEvents()
    local wasMurderer = S.lastKnownMurderer
    if MurdererName and not wasMurderer then
        S.stats.rounds = S.stats.rounds + 1
        S.statsCountedMurderer = false
        S.statsCountedSheriff = false
    end
    if S.notifyRoundStart and MurdererName and MurdererName ~= wasMurderer then
        sendNotification("Round Started", "Murderer: " .. tostring(MurdererName), SOUNDS.round)
    end
    if S.notifyRoundEnd and not MurdererName and wasMurderer then
        sendNotification("Round Ended", "New round starting soon", SOUNDS.round)
    end
    S.lastKnownMurderer = MurdererName
end

local function getRoles()
    if not GetPlayerData then
        if not warnedNoRemote then
            warnedNoRemote = true
            sendNotification("MM2 Menu", "GetPlayerData remote not found - role features disabled", SOUNDS.alert)
        end
        return
    end
    local ok, res = pcall(function() return GetPlayerData:InvokeServer() end)
    if not ok or type(res) ~= "table" then return end
    local nM, nS, nH = nil, nil, nil
    for name, data in pairs(res) do
        if type(data) == "table" then
            local r = data.Role
            if r == "Murderer" then nM = tostring(name)
            elseif r == "Sheriff" then nS = tostring(name)
            elseif r == "Hero" then nH = tostring(name) end
        elseif type(data) == "string" then
            if data == "Murderer" then nM = tostring(name)
            elseif data == "Sheriff" then nS = tostring(name)
            elseif data == "Hero" then nH = tostring(name) end
        end
    end
    for k, data in pairs(res) do
        if typeof(k) == "Instance" and k:IsA("Player") then
            local r = type(data) == "table" and data.Role or (type(data) == "string" and data or nil)
            if r == "Murderer" then nM = k.Name
            elseif r == "Sheriff" then nS = k.Name
            elseif r == "Hero" then nH = k.Name end
        end
    end
    for _, t in ipairs(Players:GetPlayers()) do
        local r = t:GetAttribute("Role")
        if r == "Murderer" then nM = t.Name
        elseif r == "Sheriff" then nS = t.Name
        elseif r == "Hero" then nH = t.Name end
    end

    if nM and validHolder(nM) then
        MurdererName = nM
        noMurdererSince = nil
    elseif MurdererName and not validHolder(MurdererName) then
        MurdererName = nil
        S.lastChatSentMurderer = nil
        S.roundActive = false
        if not noMurdererSince then noMurdererSince = tick() end
    end
    if nS and validHolder(nS) then
        SheriffName = nS
    elseif SheriffName and not validHolder(SheriffName) then
        SheriffName = nil
        S.lastChatSentSheriff = nil
        S.roundActiveSheriff = false
    end
    if nH and validHolder(nH) then
        HeroName = nH
    elseif HeroName and not validHolder(HeroName) then
        HeroName = nil
    end

    if MurdererName == nil and noMurdererSince and (tick() - noMurdererSince) >= ROUND_END_DEBOUNCE then
        MurdererName = nil
        SheriffName = nil
        HeroName = nil
        lastNotifiedMurderer = nil
        lastNotifiedSheriff = nil
        lastNotifiedHero = nil
        S.lastChatSentMurderer = nil
        S.lastChatSentSheriff = nil
        S.roundActive = false
        S.roundActiveSheriff = false
        S.pendingNotify = false
        S.selfNotifyMurderer = false
        S.selfNotifySheriff = false
        noMurdererSince = nil
    end

    roundEvents()

    if MurdererName == player.Name and not S.statsCountedMurderer then
        S.statsCountedMurderer = true
        S.stats.asMurderer = S.stats.asMurderer + 1
    end
    if SheriffName == player.Name and not S.statsCountedSheriff then
        S.statsCountedSheriff = true
        S.stats.asSheriff = S.stats.asSheriff + 1
    end

    if S.autoNotifyRoles and MurdererName and MurdererName ~= lastNotifiedMurderer then
        if not S.pendingNotify then
            S.pendingNotify = true
            S.pendingNotifySince = tick()
        elseif tick() - S.pendingNotifySince >= ROLE_NOTIFY_DELAY then
            lastNotifiedMurderer = MurdererName
            lastNotifiedSheriff = SheriffName
            lastNotifiedHero = HeroName
            S.pendingNotify = false
            notifyAllRoles()
        end
    end
end

local function updateHL()
    for _, t in ipairs(Players:GetPlayers()) do
        if t ~= player and t.Character then
            mkHL(t)
            local h = t.Character:FindFirstChild("RoleESP")
            if h then
                local role
                if MurdererName and t.Name == MurdererName then role = "Murderer"
                elseif SheriffName and t.Name == SheriffName then role = "Sheriff"
                elseif HeroName and t.Name == HeroName then role = "Hero"
                else role = "Innocent" end
                local show = isAlive(t) and not isPlayerInSpawn(t)
                if not show then
                    if S.espEnabled.Innocent then
                        local dc = ROLE_COLORS.Innocent
                        h.FillColor = dc h.OutlineColor = dc
                        h.FillTransparency = 0.7 h.OutlineTransparency = 0.2
                        h.Enabled = true
                    else h.Enabled = false end
                else
                    if S.espEnabled[role] then
                        local c = ROLE_COLORS[role]
                        h.FillColor = c h.OutlineColor = c
                        h.FillTransparency = 0.45 h.OutlineTransparency = 0
                        h.Enabled = true
                    else h.Enabled = false end
                end
            end
        end
    end
end

local function updatePlayerDistance()
    if not S.playerDistanceOn then return end
    local c = player.Character
    if not c then return end
    local myRoot = c:FindFirstChild("HumanoidRootPart")
    if not myRoot then return end
    for _, t in ipairs(Players:GetPlayers()) do
        if t ~= player and t.Character then
            local tr = t.Character:FindFirstChild("HumanoidRootPart")
            if tr then
                local bg = S.playerDistBillboards[t]
                if not bg or not bg.Parent then
                    bg = Instance.new("BillboardGui")
                    bg.Name = "DistBillboard"
                    bg.Size = msz(120, 20)
                    bg.StudsOffset = Vector3.new(0, 3.2, 0)
                    bg.AlwaysOnTop = true
                    bg.Parent = tr
                    S.playerDistBillboards[t] = bg
                    local lbl = Instance.new("TextLabel")
                    lbl.Name = "DistLabel"
                    lbl.Size = UDim2.new(1, 0, 1, 0)
                    lbl.BackgroundTransparency = 1
                    lbl.TextColor3 = Color3.fromRGB(255, 255, 255)
                    lbl.TextStrokeTransparency = 0
                    lbl.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
                    lbl.TextSize = mn(14)
                    lbl.Font = Enum.Font.GothamBold
                    lbl.Parent = bg
                end
                local lbl = bg:FindFirstChild("DistLabel")
                if lbl then
                    lbl.Text = tostring(math.floor((myRoot.Position - tr.Position).Magnitude)) .. " studs"
                end
            end
        end
    end
    for p, bg in pairs(S.playerDistBillboards) do
        if not p.Parent or not p.Character then
            if bg then bg:Destroy() end
            S.playerDistBillboards[p] = nil
        end
    end
end

local function attachTrail(target, color)
    if not target or not target.Character then return end
    local hrp = target.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local att = hrp:FindFirstChild("TrailAtt")
    if not att then
        att = Instance.new("Attachment")
        att.Name = "TrailAtt"
        att.Parent = hrp
    end
    local emit = att:FindFirstChild("TrailEmitter")
    if not emit then
        emit = Instance.new("ParticleEmitter")
        emit.Name = "TrailEmitter"
        emit.Rate = 40
        emit.Lifetime = NumberRange.new(0.7)
        emit.Size = NumberSequence.new(0.7)
        emit.Speed = NumberRange.new(0)
        emit.Rotation = NumberRange.new(0)
        emit.LightEmission = 1
        emit.Color = ColorSequence.new(color)
        emit.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.2),
            NumberSequenceKeypoint.new(1, 1),
        })
        emit.Parent = att
    else
        emit.Color = ColorSequence.new(color)
    end
end

local function clearTrail(target)
    if not target or not target.Character then return end
    local hrp = target.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local att = hrp:FindFirstChild("TrailAtt")
    if att then att:Destroy() end
end

local function updateTrails()
    for _, t in ipairs(Players:GetPlayers()) do
        if t ~= player and t.Character then
            local isM = MurdererName and t.Name == MurdererName
            local isS = SheriffName and t.Name == SheriffName
            local isH = HeroName and t.Name == HeroName
            if isM and S.killerTrailOn and isAlive(t) then
                attachTrail(t, ROLE_COLORS.Murderer)
            elseif isS and S.sheriffTrailOn and isAlive(t) then
                attachTrail(t, ROLE_COLORS.Sheriff)
            elseif isH and S.heroTrailOn and isAlive(t) then
                attachTrail(t, ROLE_COLORS.Hero)
            else
                clearTrail(t)
            end
        end
    end
end

local function rmHL(t)
    if t.Character then
        local h = t.Character:FindFirstChild("RoleESP")
        if h then h:Destroy() end
        clearTrail(t)
    end
    highlights[t] = nil
end

local function hookKillSound(t)
    if not t.Character then return end
    local hum = t.Character:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    hum.Died:Connect(function()
        if MurdererName == player.Name then
            S.stats.kills = S.stats.kills + 1
        end
        if not S.killSoundOn then return end
        if MurdererName ~= player.Name then return end
        playSound(SOUNDS.success, 1.5, true)
    end)
end

for _, t in ipairs(Players:GetPlayers()) do
    if t ~= player then
        t.CharacterAdded:Connect(function()
            task.wait(0.2)
            mkHL(t)
            updateHL()
            hookKillSound(t)
        end)
        if t.Character then mkHL(t) hookKillSound(t) end
    end
end
Players.PlayerAdded:Connect(function(t)
    if S.playerJoinLeaveNotify and t ~= player then
        sendNotification("Player Joined", t.DisplayName .. " (@" .. t.Name .. ")")
    end
    t.CharacterAdded:Connect(function()
        task.wait(0.2)
        mkHL(t)
        updateHL()
        hookKillSound(t)
    end)
end)
Players.PlayerRemoving:Connect(function(t)
    if S.playerJoinLeaveNotify and t ~= player then
        sendNotification("Player Left", t.DisplayName .. " (@" .. t.Name .. ")")
    end
    rmHL(t)
    if MurdererName == t.Name then MurdererName = nil end
    if SheriffName == t.Name then SheriffName = nil end
    if HeroName == t.Name then HeroName = nil end
    if S.playerDistBillboards[t] then
        if S.playerDistBillboards[t] then S.playerDistBillboards[t]:Destroy() end
        S.playerDistBillboards[t] = nil
    end
end)

local function isGunHeld(g)
    for _, p in ipairs(Players:GetPlayers()) do
        local c = p.Character
        if c and g:IsDescendantOf(c) then return true end
    end
    return false
end

local function isDroppedGun(i)
    if not i or not i.Parent then return false end
    if i.Name ~= "Gun" and i.Name ~= "GunDrop" then return false end
    if not (i:IsA("BasePart") or i:IsA("Model") or i:IsA("Tool")) then return false end
    if isGunHeld(i) then return false end
    return true
end

local function attachGun(g)
    if S.gunHighlights[g] then return end
    local hl = Instance.new("Highlight")
    hl.FillColor = GUN_COLOR
    hl.OutlineColor = GUN_COLOR
    hl.FillTransparency = 0.4
    hl.OutlineTransparency = 0
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Parent = g
    S.gunHighlights[g] = hl
end

local function removeGun(g)
    local hl = S.gunHighlights[g]
    if hl then pcall(function() hl:Destroy() end) end
    S.gunHighlights[g] = nil
end

local function updateGunESP()
    for g, _ in pairs(S.gunHighlights) do
        if not g or not g.Parent or not isDroppedGun(g) then removeGun(g) end
    end
    if not S.gunESPEnabled then
        for g, _ in pairs(S.gunHighlights) do removeGun(g) end
        return
    end
    local now = tick()
    if now - lastGunScan < GUN_SCAN_INTERVAL then return end
    lastGunScan = now
    for _, i in ipairs(workspace:GetDescendants()) do
        if isDroppedGun(i) and not S.gunHighlights[i] then attachGun(i) end
    end
end

local function checkAutoChat()
    if S.autoSendMurdererChat then
        if not MurdererName then
            if S.roundActive then S.roundActive = false S.lastChatSentMurderer = nil end
            S.selfNotifyMurderer = false
        elseif MurdererName == player.Name then
            S.roundActive = false
            S.lastChatSentMurderer = nil
            if not S.selfNotifyMurderer then
                S.selfNotifyMurderer = true
                sendNotification("MM2 Menu", "You are the Murderer!", SOUNDS.alert)
            end
        else
            S.selfNotifyMurderer = false
            if not S.roundActive then S.roundActive = true S.lastChatSentMurderer = nil end
            if S.lastChatSentMurderer ~= MurdererName and tick() - S.chatSendCooldown >= 1 then
                if sendChat(getRoleMessage("Murderer", MurdererName)) then
                    S.lastChatSentMurderer = MurdererName
                    S.chatSendCooldown = tick()
                end
            end
        end
    end
    if S.autoSendSheriffChat then
        if not SheriffName then
            if S.roundActiveSheriff then S.roundActiveSheriff = false S.lastChatSentSheriff = nil end
            S.selfNotifySheriff = false
        elseif SheriffName == player.Name then
            S.roundActiveSheriff = false
            S.lastChatSentSheriff = nil
            if not S.selfNotifySheriff then
                S.selfNotifySheriff = true
                sendNotification("MM2 Menu", "You are the Sheriff!", SOUNDS.alert)
            end
        else
            S.selfNotifySheriff = false
            if not S.roundActiveSheriff then S.roundActiveSheriff = true S.lastChatSentSheriff = nil end
            if S.lastChatSentSheriff ~= SheriffName and tick() - S.chatSendCooldownSheriff >= 1 then
                if sendChat(getRoleMessage("Sheriff", SheriffName)) then
                    S.lastChatSentSheriff = SheriffName
                    S.chatSendCooldownSheriff = tick()
                end
            end
        end
    end
end

RunService.Heartbeat:Connect(function()
    if S.scriptClosed then return end
    if not S.killerAlarmOn or not MurdererName then
        S.lastAlarmDist = math.huge
        return
    end
    local me = player.Character
    if not me then return end
    local myRoot = me:FindFirstChild("HumanoidRootPart")
    if not myRoot then return end
    local m = Players:FindFirstChild(MurdererName)
    if not m or not m.Character then return end
    local mRoot = m.Character:FindFirstChild("HumanoidRootPart")
    if not mRoot then return end
    local dist = (myRoot.Position - mRoot.Position).Magnitude
    if dist > 30 then
        S.lastAlarmDist = math.huge
        return
    end
    local now = tick()
    if dist < S.lastAlarmDist - ALARM_DIST_STEP and (now - (S.lastAlarmTime or 0)) >= ALARM_TIME_COOLDOWN then
        S.lastAlarmDist = dist
        S.lastAlarmTime = now
        sendNotification("⚠ MURDERER NEAR", "Murderer is " .. math.floor(dist) .. " studs away!", SOUNDS.alert)
    end
end)

RunService.Heartbeat:Connect(function()
    if S.scriptClosed then return end
    if not S.gunDropAlert then return end
    local gd = workspace:FindFirstChild("GunDrop", true)
    local isDropped = gd ~= nil
    if isDropped and not S.lastGunDropped then
        sendNotification("Gun Dropped", "A gun has appeared on the map!", SOUNDS.alert)
    end
    S.lastGunDropped = isDropped
end)

RunService.RenderStepped:Connect(function()
    if S.scriptClosed then return end
    if S.cameraFollowMurderer and MurdererName then
        local m = Players:FindFirstChild(MurdererName)
        if m and m.Character then
            local mRoot = m.Character:FindFirstChild("HumanoidRootPart")
            if mRoot then
                local cam = workspace.CurrentCamera
                cam.CFrame = CFrame.new(mRoot.Position + Vector3.new(0, 8, 12), mRoot.Position)
            end
        end
    end
    if S.crosshairOn then
        local cx, cy
        if UserInputService.TouchEnabled and S.lastTouchPos then
            cx = S.lastTouchPos.X
            cy = S.lastTouchPos.Y
        elseif UserInputService.MouseEnabled then
            local loc = UserInputService:GetMouseLocation()
            cx = loc.X
            cy = loc.Y
        else
            local vp = workspace.CurrentCamera.ViewportSize
            cx = vp.X / 2
            cy = vp.Y / 2
        end
        U.crosshairH.Position = UDim2.fromOffset(cx - CH_LEN / 2, cy - CH_THICK / 2)
        U.crosshairV.Position = UDim2.fromOffset(cx - CH_THICK / 2, cy - CH_LEN / 2)
        U.crosshairDot.Position = UDim2.fromOffset(cx - CH_DOT / 2, cy - CH_DOT / 2)
    end
end)

local function refreshLastTouch()
    local bestPos = nil
    local bestX = -math.huge
    for _, pos in pairs(S.activeTouches) do
        if pos.X > bestX then
            bestX = pos.X
            bestPos = pos
        end
    end
    if bestPos then S.lastTouchPos = bestPos end
end

UserInputService.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.Touch then
        S.activeTouches[i] = i.Position
        refreshLastTouch()
    end
end)
UserInputService.InputChanged:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.Touch then
        if S.activeTouches[i] ~= nil then
            S.activeTouches[i] = i.Position
            refreshLastTouch()
        end
    end
end)
UserInputService.InputEnded:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.Touch then
        S.activeTouches[i] = nil
        refreshLastTouch()
    end
end)

RunService.Stepped:Connect(function()
    if S.scriptClosed then return end
    if not S.noclip or not player.Character then return end
    for _, o in ipairs(player.Character:GetDescendants()) do
        if o:IsA("BasePart") then o.CanCollide = false end
    end
end)

RunService.Heartbeat:Connect(function()
    if S.scriptClosed then return end
    if not S.antiVoidEnabled or S.antiVoidCooldown then return end
    if S.flyEnabled then return end
    local c = player.Character
    if not c then return end
    local r = c:FindFirstChild("HumanoidRootPart")
    if not r then return end
    if r.Position.Y < S.VOID_Y_THRESHOLD then
        S.antiVoidCooldown = true
        local sl = workspace:FindFirstChildOfClass("SpawnLocation")
        if sl then r.CFrame = CFrame.new(sl.Position + Vector3.new(0, 5, 0))
        else r.CFrame = CFrame.new(r.Position.X, 100, r.Position.Z) end
        r.Velocity = Vector3.zero
        task.wait(0.5)
        S.antiVoidCooldown = false
    end
end)

RunService.Heartbeat:Connect(function()
    if S.scriptClosed then return end
    if not S.antiFlingEnabled then return end
    if S.flyEnabled then return end
    local c = player.Character
    if not c then return end
    local r = c:FindFirstChild("HumanoidRootPart")
    if not r then return end
    local now = tick()
    local v = r.AssemblyLinearVelocity
    if v.Magnitude < 100 and r.Position.Y > -50 then
        S.lastSafePosition = r.CFrame
        S.lastSafeUpdate = now
    end
    if v.Magnitude > S.ANTI_FLING_MAX_SPEED then
        r.AssemblyLinearVelocity = Vector3.zero
        r.AssemblyAngularVelocity = Vector3.zero
        r.RotVelocity = Vector3.zero
        if S.lastSafePosition and (now - S.lastSafeUpdate) < 5 then r.CFrame = S.lastSafePosition end
    end
    if r.AssemblyAngularVelocity.Magnitude > S.ANTI_FLING_MAX_ANGULAR then
        r.AssemblyAngularVelocity = Vector3.zero
        r.RotVelocity = Vector3.zero
    end
end)

-- Player death tracking
local function hookPlayerDeath(character)
    local hum = character:WaitForChild("Humanoid", 5)
    if hum then
        hum.Died:Connect(function()
            S.stats.deaths = S.stats.deaths + 1
        end)
    end
end

if player.Character then hookPlayerDeath(player.Character) end
player.CharacterAdded:Connect(function(character)
    stopFly()
    flyUpFlag = 0 flyDownFlag = 0
    S.originalCollision = {}
    S.lastSafePosition = nil
    S.antiVoidCooldown = false
    if S.noclip then
        task.wait(0.1)
        for _, o in ipairs(character:GetDescendants()) do
            if o:IsA("BasePart") then
                S.originalCollision[o] = o.CanCollide
                o.CanCollide = false
            end
        end
    end
    task.wait(0.2)
    local h = character:FindFirstChildOfClass("Humanoid")
    if h then
        h.PlatformStand = false
        if S.speedhackEnabled then h.WalkSpeed = S.speedhackSpeed end
    end
    hookPlayerDeath(character)
    updateHL()
end)

-- ═══════════════════════════════════════════════════════════
-- DRAG / RESIZE
-- ═══════════════════════════════════════════════════════════
local dragStart, dragStartPosition, resizeStart, resizeStartSize, reopenDragStart, reopenDragStartPosition

U.header.InputBegan:Connect(function(i)
    if S.guiLocked then return end
    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
        S.dragging = true
        dragStart = i.Position
        dragStartPosition = U.frame.Position
    end
end)
UserInputService.InputChanged:Connect(function(i)
    if not S.dragging or S.guiLocked then return end
    if i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch then
        local d = i.Position - dragStart
        U.frame.Position = UDim2.new(dragStartPosition.X.Scale, dragStartPosition.X.Offset + d.X, dragStartPosition.Y.Scale, dragStartPosition.Y.Offset + d.Y)
    end
end)

U.resize.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
        S.resizing = true
        resizeStart = i.Position
        resizeStartSize = U.frame.AbsoluteSize
    end
end)
UserInputService.InputChanged:Connect(function(i)
    if not S.resizing then return end
    if i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch then
        local d = i.Position - resizeStart
        U.frame.Size = UDim2.fromOffset(math.max(mn(380), resizeStartSize.X + d.X), math.max(mn(280), resizeStartSize.Y + d.Y))
    end
end)

U.reopen.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
        S.reopenDragging = true
        reopenDragStart = i.Position
        reopenDragStartPosition = U.reopen.Position
        S.reopenDragDist = 0
    end
end)
UserInputService.InputChanged:Connect(function(i)
    if not S.reopenDragging then return end
    if i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch then
        local d = i.Position - reopenDragStart
        S.reopenDragDist = math.max(S.reopenDragDist, d.Magnitude)
        U.reopen.Position = UDim2.new(reopenDragStartPosition.X.Scale, reopenDragStartPosition.X.Offset + d.X, reopenDragStartPosition.Y.Scale, reopenDragStartPosition.Y.Offset + d.Y)
    end
end)
UserInputService.InputEnded:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
        S.dragging = false
        S.resizing = false
        if S.reopenDragging and S.reopenDragDist < 5 then
            U.frame.Visible = true
            U.reopen.Visible = false
            S.menuVisible = true
        end
        S.reopenDragging = false
    end
end)

showMenu = function()
    S.menuVisible = true
    U.frame.Visible = true
    U.reopen.Visible = false
end
minimizeMenu = function()
    S.menuVisible = false
    U.frame.Visible = false
    FP.panel.Visible = false
    S.flyPanelOpen = false
    U.reopen.Visible = true
end
local function closeScript()
    pcall(resetAllToggles)
    pcall(stopFly)
    pcall(function()
        for g, hl in pairs(S.gunHighlights) do if hl then hl:Destroy() end end
    end)
    pcall(function()
        for p, bg in pairs(S.playerDistBillboards) do if bg then bg:Destroy() end end
    end)
    for _, t in ipairs(Players:GetPlayers()) do
        pcall(clearTrail, t)
    end
    S.scriptClosed = true
    sendNotification("MM2 Menu", "Script closed.")
    pcall(function() U.gui:Destroy() end)
    pcall(function() S.crosshairGui:Destroy() end)
end

U.lock.MouseButton1Click:Connect(function()
    S.guiLocked = not S.guiLocked
    if S.guiLocked then
        U.lock.Text = "🔒"
        U.lock.BackgroundColor3 = Color3.fromRGB(70, 45, 45)
    else
        U.lock.Text = "🔓"
        U.lock.BackgroundColor3 = Color3.fromRGB(42, 44, 52)
    end
end)
U.minimize.MouseButton1Click:Connect(function()
    minimizeMenu()
    sendNotification("MM2 Menu", "Menu minimized. Click 'MM2' or press Right Shift to reopen.")
end)
U.close.MouseButton1Click:Connect(closeScript)
U.close.MouseEnter:Connect(function() U.close.BackgroundColor3 = Color3.fromRGB(180, 55, 55) end)
U.close.MouseLeave:Connect(function() U.close.BackgroundColor3 = Color3.fromRGB(42, 44, 52) end)

-- ═══════════════════════════════════════════════════════════
-- KEYBIND ACTIONS
-- ═══════════════════════════════════════════════════════════
local kbActions = {}

kbActions.fly = function()
    if S.flyEnabled then stopFly() else startFly() end
end

kbActions.noclip = function()
    S.noclip = not S.noclip
    if S.noclip then
        setOn(U.noclipBtn, U.noclipInd)
        S.originalCollision = {}
        if player.Character then
            for _, o in ipairs(player.Character:GetDescendants()) do
                if o:IsA("BasePart") then
                    S.originalCollision[o] = o.CanCollide
                    o.CanCollide = false
                end
            end
        end
    else
        setOff(U.noclipBtn, U.noclipInd)
        for o, v in pairs(S.originalCollision) do
            if o and o.Parent then o.CanCollide = v end
        end
        S.originalCollision = {}
    end
end

kbActions.speedhack = function()
    S.speedhackEnabled = not S.speedhackEnabled
    if S.speedhackEnabled then
        setOn(U.shBtn, U.shInd)
        local c = player.Character
        if c then local h = c:FindFirstChildOfClass("Humanoid") if h then h.WalkSpeed = S.speedhackSpeed end end
    else
        setOff(U.shBtn, U.shInd)
        local c = player.Character
        if c then local h = c:FindFirstChildOfClass("Humanoid") if h then h.WalkSpeed = 16 end end
    end
end

kbActions.infinityJump = function()
    S.infinityJump = not S.infinityJump
    if S.infinityJump then setOn(U.infBtn, U.infInd) else setOff(U.infBtn, U.infInd) end
end

kbActions.autoKillAll = function()
    S.autoKillAll = not S.autoKillAll
    if S.autoKillAll then setOn(U.autoKillBtn, U.autoKillInd) else setOff(U.autoKillBtn, U.autoKillInd) end
end

kbActions.gunESP = function()
    S.gunESPEnabled = not S.gunESPEnabled
    if S.gunESPEnabled then
        U.gunBtn.BackgroundColor3 = GUN_COLOR:Lerp(Color3.fromRGB(20, 20, 25), 0.65)
        U.gunInd.BackgroundColor3 = GUN_COLOR
    else
        setOff(U.gunBtn, U.gunInd)
        for gun, hl in pairs(S.gunHighlights) do
            if hl then pcall(function() hl:Destroy() end) end
        end
        S.gunHighlights = {}
    end
end

local function toggleEspRole(role)
    S.espEnabled[role] = not S.espEnabled[role]
    if espButtons[role] then
        if S.espEnabled[role] then
            espButtons[role].Button.BackgroundColor3 = ROLE_COLORS[role]:Lerp(Color3.fromRGB(20, 20, 25), 0.65)
            espButtons[role].Indicator.BackgroundColor3 = ROLE_COLORS[role]
        else
            setOff(espButtons[role].Button, espButtons[role].Indicator)
        end
    end
end

kbActions.murdererESP = function() toggleEspRole("Murderer") end
kbActions.sheriffESP = function() toggleEspRole("Sheriff") end
kbActions.innocentESP = function() toggleEspRole("Innocent") end

kbActions.antiVoid = function()
    S.antiVoidEnabled = not S.antiVoidEnabled
    if S.antiVoidEnabled then setOn(U.avBtn, U.avInd) else setOff(U.avBtn, U.avInd) end
end

kbActions.turnOffAll = function()
    if resetAllToggles then resetAllToggles() end
end

-- ═══════════════════════════════════════════════════════════
-- INPUT HANDLER
-- ═══════════════════════════════════════════════════════════
local modifierKeys = {
    [Enum.KeyCode.LeftAlt] = true, [Enum.KeyCode.RightAlt] = true,
    [Enum.KeyCode.LeftControl] = true, [Enum.KeyCode.RightControl] = true,
    [Enum.KeyCode.LeftShift] = true,
}
local pendingModifier = nil

UserInputService.InputBegan:Connect(function(i, processed)
    if S.scriptClosed then return end
    if U.whatsNewOverlay.Visible and (i.KeyCode == Enum.KeyCode.Escape) then
        U.whatsNewOverlay.Visible = false
        return
    end
    if S.capturingKeybind then
        if i.KeyCode == Enum.KeyCode.Escape then endCapture() return end
        if S.capturingAction then S.keybinds[S.capturingAction] = i.KeyCode end
        endCapture()
        return
    end
    if processed then return end
    if i.KeyCode == Enum.KeyCode.RightShift then
        if S.menuVisible then minimizeMenu() else showMenu() end
        return
    end
    if modifierKeys[i.KeyCode] then
        pendingModifier = i.KeyCode
        return
    end
    if pendingModifier then pendingModifier = nil end
    if not S.keybindsEnabled then return end
    for action, key in pairs(S.keybinds) do
        if i.KeyCode == key then
            local fn = kbActions[action]
            if fn then pcall(fn) return end
        end
    end
end)

UserInputService.InputEnded:Connect(function(i)
    if S.scriptClosed then return end
    if i.KeyCode == pendingModifier then
        if S.keybindsEnabled then
            for action, key in pairs(S.keybinds) do
                if i.KeyCode == key then
                    local fn = kbActions[action]
                    if fn then pcall(fn) end
                    break
                end
            end
        end
        pendingModifier = nil
    end
end)

RunService.Heartbeat:Connect(function()
    if S.scriptClosed then return end
    local hue = (tick() * RAINBOW_SPEED) % 1
    local color = Color3.fromHSV(hue, 1, 1)
    U.frameStroke.Color = color
    U.reopenStroke.Color = color
    FP.stroke.Color = color
    U.titleGradient.Rotation = (tick() * 60) % 360
    if S.crosshairOn and U.crosshairH and U.crosshairV and U.crosshairDot then
        U.crosshairH.BackgroundColor3 = color
        U.crosshairV.BackgroundColor3 = color
        U.crosshairDot.BackgroundColor3 = Color3.fromHSV((hue + 0.5) % 1, 1, 1)
    end
end)

getRoles()
updateHL()
updateGunESP()

-- Initial Home build + auto-show What's New once
task.defer(function()
    task.wait(1)
    if not S.whatsNewAutoShown then
        S.whatsNewAutoShown = true
        pcall(openWhatsNew)
    end
    pcall(updateHomeUI, true)
end)

task.spawn(function()
    while U.gui.Parent do
        pcall(function()
            getRoles()
            updateHL()
            updateGunESP()
            updatePlayerDistance()
            updateTrails()
            if S.autoKillAll and MurdererName == player.Name then killAllPlayers() end
            if S.autoGunTP then autoTPGunTop() end
            checkAutoChat()
        end)
        task.wait(0.25)
    end
end)