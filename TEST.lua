--// MM2 MENU BY ARBUZ v1.3.2

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local LocalizationService = game:GetService("LocalizationService")
local TweenService = game:GetService("TweenService")
local Stats = game:GetService("Stats")

local RAINBOW_SPEED = 0.25
local ALARM_TIME_COOLDOWN = 6
local ALARM_DIST_STEP = 5
local SCRIPT_VERSION = "v1.3.2"
local SCRIPT_AUTHOR = "Arbuz"

local CHANGELOG = {
    version = "v1.3.2",
    date = "2026-10-16",
    changes = {
        "Fixed notifications persisting on screen",
        "Restored lock icon",
        "Fixed menu drag (dedicated drag handle)",
        "Top search now filters current tab only",
        "Home tab gets its own cross-tab search",
        "Removed tooltips and hold-to-reorder feature",
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
    return string.format("%02d:%02d:%02d", math.floor(secs/3600), math.floor((secs%3600)/60), secs%60)
end
local function fmtAgo(t)
    local e = tick() - t
    if e < 60 then return math.floor(e) .. "s ago" end
    if e < 3600 then return math.floor(e/60) .. "m ago" end
    return math.floor(e/3600) .. "h ago"
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
    lastTouchPos = nil, activeTouches = {},
    gunDropAlert = false, lastGunDropped = false,
    notifyRoundStart = false, notifyRoundEnd = false,
    playerJoinLeaveNotify = false,
    menuOpacity = 100, menuVolume = 100, killVolume = 100,
    killerTrailOn = false, sheriffTrailOn = false, heroTrailOn = false,
    cameraFollowMurderer = false, killSoundOn = false,
    lastKnownMurderer = nil,
    flySpeed = 50, speedhackEnabled = false, speedhackSpeed = 45,
    guiLocked = false, flyPanelLocked = false, menuVisible = true,
    espEnabled = { Innocent = false, Murderer = false, Sheriff = false, Hero = false },
    gunESPEnabled = false, gunHighlights = {}, originalCollision = {},
    lastChatSentMurderer = nil, lastChatSentSheriff = nil,
    selfNotifyMurderer = false, selfNotifySheriff = false,
    roundActive = false, roundActiveSheriff = false,
    chatSendCooldown = 0, chatSendCooldownSheriff = 0,
    flyPanelOpen = false, flingTouchActive = false, flingTouchThread = nil,
    dropdownOpen = false, selectedPlayer = nil,
    resizing = false, dragging = false, reopenDragging = false, flyDragging = false,
    lastSafePosition = nil, lastSafeUpdate = 0, antiVoidCooldown = false,
    VOID_Y_THRESHOLD = -50, ANTI_FLING_MAX_SPEED = 200, ANTI_FLING_MAX_ANGULAR = 500,
    pendingNotify = false, pendingNotifySince = 0,
    capturingKeybind = false, capturingAction = nil,
    reopenDragDist = 0, hopping = false,
    pvpSnapshot = nil, sessionStart = tick(),
    notificationHistory = {},
    stats = { kills = 0, deaths = 0, rounds = 0, asMurderer = 0, asSheriff = 0 },
    statsCountedMurderer = false, statsCountedSheriff = false,
    whatsNewAutoShown = false, homeRebuildDirty = true,
    reAnnounceEnabled = false, reAnnounceInterval = 30, lastReAnnounceTime = 0,
    lastHero = nil, heroChangeNotify = false,
    autoHideInRound = false, dirIndicatorOn = false,
    compactMode = false, fpsOverlayOn = false,
    currentFPS = 60, currentPing = 0,
    savedConfigs = {},
    tabOrder = {"Home", "Movement", "ESP", "Notifier", "Murderer", "Sheriff", "Teleport", "Keybinds", "Settings", "Utility", "Config"},
    keybinds = {
        fly = Enum.KeyCode.LeftAlt, noclip = Enum.KeyCode.N, speedhack = Enum.KeyCode.Q,
        infinityJump = Enum.KeyCode.J, autoKillAll = Enum.KeyCode.K, gunESP = Enum.KeyCode.G,
        murdererESP = Enum.KeyCode.M, sheriffESP = Enum.KeyCode.H, innocentESP = Enum.KeyCode.I,
        antiVoid = Enum.KeyCode.B, turnOffAll = Enum.KeyCode.Y, panic = Enum.KeyCode.End,
    },
    keybindList = {
        {id = "fly", name = "Toggle Fly"}, {id = "noclip", name = "Toggle Noclip"},
        {id = "speedhack", name = "Toggle Speedhack"}, {id = "infinityJump", name = "Toggle Infinity Jump"},
        {id = "autoKillAll", name = "Toggle Auto Kill All"}, {id = "gunESP", name = "Toggle Gun ESP"},
        {id = "murdererESP", name = "Toggle Murderer ESP"}, {id = "sheriffESP", name = "Toggle Sheriff ESP"},
        {id = "innocentESP", name = "Toggle Innocent ESP"}, {id = "antiVoid", name = "Toggle Anti Void"},
        {id = "turnOffAll", name = "Turn Off All"}, {id = "panic", name = "Panic (silent off + minimize)"},
    },
}

local ROLE_COLORS = {
    Innocent = Color3.fromRGB(50, 210, 90), Murderer = Color3.fromRGB(230, 55, 55),
    Sheriff = Color3.fromRGB(55, 140, 255), Hero = Color3.fromRGB(255, 205, 50),
}
local GUN_COLOR = Color3.fromRGB(170, 90, 230)

local MurdererName, SheriffName, HeroName = nil, nil, nil
local lastNotifiedMurderer, lastNotifiedSheriff, lastNotifiedHero = nil, nil, nil
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

local U = { homeRefs = {} }
local FP = {}
local NotifUI, TutorialUI, DirUI, PerfUI
local showToast, openWhatsNew, showTutorial, showCloseConfirm
local updateHomeUI, rebuildKeybindList, rebuildNotifHistory
local minimizeMenu, showMenu, closeScript
local resetAllToggles, applyPvpPreset, restorePvpSnapshot, silentResetAll
local switchTab, buildSidebarButtons
local stopFly, startFly
local createToggle, createActionButton, createSectionTitle, createInfoCard, addInfoRow
local setOn, setOff, setRed
local notifyAllRoles, sendChat, getRoleMessage, fmtRole
local snapshotFullSettings, applyFullSnapshot
local killAllPlayers, attackTarget

local function getLayoutOrder()
    currentLayoutOrder = currentLayoutOrder + 1
    return currentLayoutOrder
end

-- ═══════════════════════════════════════════════════════════
-- NOTIFICATIONS
-- ═══════════════════════════════════════════════════════════
local NOTIF_COLORS = {
    info = Color3.fromRGB(70, 140, 220), success = Color3.fromRGB(70, 200, 110),
    warn = Color3.fromRGB(230, 180, 60), alert = Color3.fromRGB(230, 70, 70),
    round = Color3.fromRGB(180, 110, 230),
}
local NOTIF_ICONS = { info = "i", success = "+", warn = "!", alert = "x", round = "o" }

NotifUI = {}
NotifUI.gui = Instance.new("ScreenGui")
NotifUI.gui.Name = "MM2Notifs"
NotifUI.gui.ResetOnSpawn = false
NotifUI.gui.DisplayOrder = 300
NotifUI.gui.IgnoreGuiInset = true
NotifUI.gui.Parent = playerGui

NotifUI.container = Instance.new("Frame")
NotifUI.container.Size = UDim2.new(0, mn(260), 0, mn(400))
NotifUI.container.Position = UDim2.new(1, -mn(268), 0, mn(12))
NotifUI.container.BackgroundTransparency = 1
NotifUI.container.Parent = NotifUI.gui
do
    local l = Instance.new("UIListLayout")
    l.Padding = UDim.new(0, 6)
    l.SortOrder = Enum.SortOrder.LayoutOrder
    l.HorizontalAlignment = Enum.HorizontalAlignment.Right
    l.VerticalAlignment = Enum.VerticalAlignment.Top
    l.Parent = NotifUI.container
end

local notifIdCounter = 0

local function inferCategory(soundId)
    if soundId == SOUNDS.alert then return "alert" end
    if soundId == SOUNDS.success then return "success" end
    if soundId == SOUNDS.round then return "round" end
    return "info"
end

local function pushCustomNotification(title, text, category)
    category = category or "info"
    local color = NOTIF_COLORS[category] or NOTIF_COLORS.info
    local icon = NOTIF_ICONS[category] or "."
    notifIdCounter = notifIdCounter + 1
    local id = notifIdCounter
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, mn(52))
    frame.BackgroundColor3 = Color3.fromRGB(30, 32, 40)
    frame.BorderSizePixel = 0
    frame.LayoutOrder = id
    frame.Parent = NotifUI.container
    do
        local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 8) c.Parent = frame
        local st = Instance.new("UIStroke") st.Color = Color3.fromRGB(55, 58, 70) st.Thickness = 1 st.Parent = frame
    end
    local accent = Instance.new("Frame")
    accent.Size = UDim2.new(0, mn(4), 1, 0)
    accent.BackgroundColor3 = color
    accent.BorderSizePixel = 0
    accent.Parent = frame
    do local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 8) c.Parent = accent end
    local iconFrame = Instance.new("Frame")
    iconFrame.Size = msz(24, 24)
    iconFrame.Position = mpos(12, 14)
    iconFrame.BackgroundColor3 = color
    iconFrame.BackgroundTransparency = 0.75
    iconFrame.BorderSizePixel = 0
    iconFrame.Parent = frame
    do local c = Instance.new("UICorner") c.CornerRadius = UDim.new(1, 0) c.Parent = iconFrame end
    local il = Instance.new("TextLabel")
    il.Size = UDim2.new(1, 0, 1, 0)
    il.BackgroundTransparency = 1
    il.Text = icon
    il.TextColor3 = color
    il.TextSize = mn(13)
    il.Font = Enum.Font.GothamBold
    il.Parent = iconFrame
    local tl = Instance.new("TextLabel")
    tl.Size = UDim2.new(1, -mn(48), 0, mn(15))
    tl.Position = mpos(42, 8)
    tl.BackgroundTransparency = 1
    tl.Text = title
    tl.TextColor3 = Color3.fromRGB(245, 245, 250)
    tl.TextSize = mn(12)
    tl.Font = Enum.Font.GothamBold
    tl.TextXAlignment = Enum.TextXAlignment.Left
    tl.TextTruncate = Enum.TextTruncate.AtEnd
    tl.Parent = frame
    local bl = Instance.new("TextLabel")
    bl.Size = UDim2.new(1, -mn(48), 0, mn(22))
    bl.Position = mpos(42, 24)
    bl.BackgroundTransparency = 1
    bl.Text = text
    bl.TextColor3 = Color3.fromRGB(200, 202, 210)
    bl.TextSize = mn(11)
    bl.Font = Enum.Font.Gotham
    bl.TextXAlignment = Enum.TextXAlignment.Left
    bl.TextYAlignment = Enum.TextYAlignment.Top
    bl.TextWrapped = true
    bl.TextTruncate = Enum.TextTruncate.AtEnd
    bl.Parent = frame
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 1, 0)
    btn.BackgroundTransparency = 1
    btn.Text = ""
    btn.Parent = frame
    btn.MouseButton1Click:Connect(function()
        pcall(function() setclipboard(title .. "\n" .. text) end)
        if showToast then showToast("Copied") end
    end)

    -- Simple destroy after 5 seconds (no tween issues)
    task.delay(5, function()
        pcall(function()
            if frame then frame:Destroy() end
        end)
    end)
end

local toastGui = Instance.new("ScreenGui")
toastGui.Name = "MM2Toast"
toastGui.ResetOnSpawn = false
toastGui.DisplayOrder = 310
toastGui.Parent = playerGui
local toastFrame = Instance.new("Frame")
toastFrame.Size = msz(180, 30)
toastFrame.Position = UDim2.new(0.5, -mn(90), 1, -mn(60))
toastFrame.BackgroundColor3 = Color3.fromRGB(30, 32, 40)
toastFrame.BorderSizePixel = 0
toastFrame.BackgroundTransparency = 1
toastFrame.Visible = false
toastFrame.Parent = toastGui
do local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 8) c.Parent = toastFrame end
local toastLbl = Instance.new("TextLabel")
toastLbl.Size = UDim2.new(1, 0, 1, 0)
toastLbl.BackgroundTransparency = 1
toastLbl.Text = ""
toastLbl.TextColor3 = Color3.fromRGB(240, 240, 245)
toastLbl.TextSize = mn(11)
toastLbl.Font = Enum.Font.GothamBold
toastLbl.Parent = toastFrame

showToast = function(text)
    toastLbl.Text = text
    toastFrame.Visible = true
    TweenService:Create(toastFrame, TweenInfo.new(0.2), {BackgroundTransparency = 0.05}):Play()
    task.delay(1.5, function()
        TweenService:Create(toastFrame, TweenInfo.new(0.3), {BackgroundTransparency = 1}):Play()
        task.wait(0.3)
        toastFrame.Visible = false
    end)
end

local function playSound(id, baseVol, isKill)
    baseVol = baseVol or 1
    local vp = isKill and (S.killVolume or 100) or (S.menuVolume or 100)
    local fv = baseVol * (vp / 100)
    if fv <= 0 then return end
    local snd = Instance.new("Sound")
    snd.SoundId = id or SOUNDS.notify
    snd.Volume = fv
    snd.Parent = playerGui
    snd:Play()
    task.delay(4, function() if snd then snd:Destroy() end end)
end

local function sendNotification(title, text, soundId)
    local category = inferCategory(soundId)
    pcall(pushCustomNotification, title, text, category)
    table.insert(S.notificationHistory, 1, {title = title, text = text, time = tick(), category = category})
    while #S.notificationHistory > 10 do table.remove(S.notificationHistory) end
    S.homeRebuildDirty = true
    playSound(soundId or SOUNDS.notify, 1, false)
end

-- ═══════════════════════════════════════════════════════════
-- MAIN UI
-- ═══════════════════════════════════════════════════════════
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

-- Drag handle (transparent, covers header background, below title & buttons)
U.dragHandle = Instance.new("TextButton")
U.dragHandle.Size = UDim2.new(1, 0, 1, 0)
U.dragHandle.BackgroundTransparency = 1
U.dragHandle.Text = ""
U.dragHandle.AutoButtonColor = false
U.dragHandle.ZIndex = 1
U.dragHandle.Parent = U.header

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
    ColorSequenceKeypoint.new(0.25, Color3.fromRGB(255, 220, 90)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(90, 255, 120)),
    ColorSequenceKeypoint.new(0.75, Color3.fromRGB(90, 200, 255)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 90, 90)),
})
U.titleGradient.Parent = U.title

local function makeHeaderBtn(text, xOff, textColor)
    local b = Instance.new("TextButton")
    b.Size = msz(28, 28)
    b.Position = UDim2.new(1, -mn(xOff), 0.5, -mn(14))
    b.BackgroundColor3 = Color3.fromRGB(42, 44, 52)
    b.Text = text
    b.TextSize = mn(15)
    b.TextColor3 = textColor or Color3.new(1, 1, 1)
    b.Font = Enum.Font.GothamBold
    b.BorderSizePixel = 0
    b.AutoButtonColor = false
    b.ZIndex = 10
    b.Parent = U.header
    local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 7) c.Parent = b
    return b
end

U.close = makeHeaderBtn("X", 98, Color3.fromRGB(255, 200, 200))
U.lock = makeHeaderBtn("🔓", 66)
U.minimize = makeHeaderBtn("-", 34)

U.resize = Instance.new("TextButton")
U.resize.Size = msz(18, 18)
U.resize.Position = UDim2.new(1, -mn(18), 1, -mn(18))
U.resize.BackgroundColor3 = Color3.fromRGB(55, 57, 65)
U.resize.BorderSizePixel = 0
U.resize.Text = "◢"
U.resize.TextColor3 = Color3.fromRGB(180, 182, 190)
U.resize.TextSize = mn(12)
U.resize.Font = Enum.Font.GothamBold
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
U.sidebar.Size = UDim2.new(0, mn(96), 1, -mn(58))
U.sidebar.Position = mpos(8, 50)
U.sidebar.BackgroundTransparency = 1
U.sidebar.BorderSizePixel = 0
U.sidebar.ScrollBarThickness = 3
U.sidebar.ScrollBarImageColor3 = Color3.fromRGB(75, 77, 85)
U.sidebar.AutomaticCanvasSize = Enum.AutomaticSize.Y
U.sidebar.ScrollingDirection = Enum.ScrollingDirection.Y
U.sidebar.CanvasSize = UDim2.new(0, 0, 0, 0)
U.sidebar.Parent = U.frame
do
    local l = Instance.new("UIListLayout")
    l.Padding = UDim.new(0, 2)
    l.SortOrder = Enum.SortOrder.LayoutOrder
    l.Parent = U.sidebar
end

U.rightArea = Instance.new("Frame")
U.rightArea.Size = UDim2.new(1, -mn(120), 1, -mn(58))
U.rightArea.Position = mpos(112, 50)
U.rightArea.BackgroundTransparency = 1
U.rightArea.Parent = U.frame

U.searchBox = Instance.new("TextBox")
U.searchBox.Size = UDim2.new(1, 0, 0, mn(26))
U.searchBox.BackgroundColor3 = Color3.fromRGB(34, 36, 43)
U.searchBox.BorderSizePixel = 0
U.searchBox.Text = ""
U.searchBox.PlaceholderText = "Search this tab..."
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

-- UI Helpers
createSectionTitle = function(text)
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

createToggle = function(name, text)
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

createActionButton = function(name, text)
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

createInfoCard = function()
    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, 0, 0, 0)
    card.AutomaticSize = Enum.AutomaticSize.Y
    card.BackgroundColor3 = Color3.fromRGB(28, 30, 36)
    card.BorderSizePixel = 0
    card.LayoutOrder = getLayoutOrder()
    card.Parent = currentParent
    do local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 8) c.Parent = card end
    local p = Instance.new("UIPadding")
    p.PaddingTop = UDim.new(0, 5) p.PaddingBottom = UDim.new(0, 5)
    p.PaddingLeft = UDim.new(0, 8) p.PaddingRight = UDim.new(0, 8)
    p.Parent = card
    local l = Instance.new("UIListLayout")
    l.Padding = UDim.new(0, 2) l.SortOrder = Enum.SortOrder.LayoutOrder l.Parent = card
    return card
end

addInfoRow = function(card, key, initial, valueColor)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, mn(16))
    row.BackgroundTransparency = 1
    row.LayoutOrder = getLayoutOrder()
    row.Parent = card
    local k = Instance.new("TextLabel")
    k.Size = UDim2.new(0.55, 0, 1, 0)
    k.BackgroundTransparency = 1
    k.Text = key
    k.TextColor3 = Color3.fromRGB(150, 153, 165)
    k.TextSize = mn(11)
    k.Font = Enum.Font.GothamSemibold
    k.TextXAlignment = Enum.TextXAlignment.Left
    k.Parent = row
    local v = Instance.new("TextLabel")
    v.Size = UDim2.new(0.45, 0, 1, 0)
    v.Position = UDim2.new(0.55, 0, 0, 0)
    v.BackgroundTransparency = 1
    v.Text = initial or "-"
    v.TextColor3 = valueColor or Color3.fromRGB(230, 230, 235)
    v.TextSize = mn(11)
    v.Font = Enum.Font.GothamBold
    v.TextXAlignment = Enum.TextXAlignment.Right
    v.TextTruncate = Enum.TextTruncate.AtEnd
    v.Parent = row
    return v
end

setOn = function(b, i) b.BackgroundColor3 = Color3.fromRGB(35, 70, 45) i.BackgroundColor3 = Color3.fromRGB(50, 210, 90) end
setOff = function(b, i) b.BackgroundColor3 = Color3.fromRGB(34, 36, 43) i.BackgroundColor3 = Color3.fromRGB(80, 82, 90) end
setRed = function(b, i) b.BackgroundColor3 = Color3.fromRGB(70, 32, 32) i.BackgroundColor3 = Color3.fromRGB(230, 55, 55) end

-- ═══════════════════════════════════════════════════════════
-- TAB SYSTEM (no reorder)
-- ═══════════════════════════════════════════════════════════
switchTab = function(name)
    U.activeTab = name
    for k, fr in pairs(U.tabFrames) do fr.Visible = (k == name) end
    for k, btn in pairs(U.tabs) do
        if k == name then
            btn.BackgroundColor3 = Color3.fromRGB(50, 55, 65)
            btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        else
            btn.BackgroundColor3 = Color3.fromRGB(34, 36, 43)
            btn.TextColor3 = Color3.fromRGB(200, 200, 210)
        end
    end
    -- Clear the top search when switching tabs
    if U.searchBox.Text ~= "" then U.searchBox.Text = "" end
    if name == "Home" then S.homeRebuildDirty = true end
end

buildSidebarButtons = function()
    for _, tb in pairs(U.tabs) do if tb then tb:Destroy() end end
    U.tabs = {}
    for idx, tabName in ipairs(S.tabOrder) do
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
        tb.LayoutOrder = idx
        tb.Parent = U.sidebar
        do
            local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 6) c.Parent = tb
            local p = Instance.new("UIPadding") p.PaddingLeft = UDim.new(0, 8) p.Parent = tb
        end
        U.tabs[tabName] = tb
        tb.MouseButton1Click:Connect(function() switchTab(tabName) end)
    end
end

for _, tabName in ipairs(S.tabOrder) do
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
    fr.CanvasSize = UDim2.new(0, 0, 0, 0)
    fr.Visible = false
    fr.Parent = U.rightArea
    do
        local l = Instance.new("UIListLayout")
        l.Padding = UDim.new(0, 3) l.SortOrder = Enum.SortOrder.LayoutOrder l.Parent = fr
    end
    U.tabFrames[tabName] = fr
end

buildSidebarButtons()
switchTab("Home")

-- Top search: current-tab-only filtering (as before)
U.searchBox:GetPropertyChangedSignal("Text"):Connect(function()
    local q = U.searchBox.Text:lower()
    local fr = U.tabFrames[U.activeTab]
    if not fr then return end
    for _, child in ipairs(fr:GetChildren()) do
        if child:IsA("TextButton") then
            child.Visible = (q == "" or child.Text:lower():find(q, 1, true) ~= nil)
        end
    end
end)

-- ═══════════════════════════════════════════════════════════
-- HOME TAB
-- ═══════════════════════════════════════════════════════════
local function populateHome()
    currentParent = U.tabFrames.Home

    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, mn(30))
    row.BackgroundTransparency = 1
    row.LayoutOrder = getLayoutOrder()
    row.Parent = currentParent
    do
        local l = Instance.new("UIListLayout")
        l.FillDirection = Enum.FillDirection.Horizontal
        l.Padding = UDim.new(0, 4)
        l.SortOrder = Enum.SortOrder.LayoutOrder
        l.Parent = row
    end
    local backup = currentParent
    currentParent = row
    local wnBtn = createActionButton("WhatsNewBtn", "What's New")
    wnBtn.Size = UDim2.new(0.5, -2, 1, 0)
    wnBtn.BackgroundColor3 = Color3.fromRGB(50, 70, 115)
    wnBtn.TextColor3 = Color3.fromRGB(220, 235, 255)
    wnBtn.MouseButton1Click:Connect(function() openWhatsNew() end)
    local tutBtn = createActionButton("TutorialBtn", "Tutorial")
    tutBtn.Size = UDim2.new(0.5, -2, 1, 0)
    tutBtn.BackgroundColor3 = Color3.fromRGB(55, 60, 85)
    tutBtn.TextColor3 = Color3.fromRGB(220, 225, 245)
    tutBtn.MouseButton1Click:Connect(function() if showTutorial then showTutorial() end end)
    currentParent = backup

    createSectionTitle("SEARCH ALL TABS")
    local crossSearch = Instance.new("TextBox")
    crossSearch.Size = UDim2.new(1, 0, 0, mn(26))
    crossSearch.BackgroundColor3 = Color3.fromRGB(34, 36, 43)
    crossSearch.BorderSizePixel = 0
    crossSearch.Text = ""
    crossSearch.PlaceholderText = "Search every tab..."
    crossSearch.TextColor3 = Color3.fromRGB(230, 230, 235)
    crossSearch.PlaceholderColor3 = Color3.fromRGB(120, 122, 130)
    crossSearch.TextSize = mn(12)
    crossSearch.Font = Enum.Font.GothamSemibold
    crossSearch.ClearTextOnFocus = false
    crossSearch.TextXAlignment = Enum.TextXAlignment.Left
    crossSearch.LayoutOrder = getLayoutOrder()
    crossSearch.Parent = currentParent
    do
        local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 8) c.Parent = crossSearch
        local p = Instance.new("UIPadding") p.PaddingLeft = UDim.new(0, 8) p.Parent = crossSearch
    end

    local crossResults = Instance.new("Frame")
    crossResults.Size = UDim2.new(1, 0, 0, 0)
    crossResults.AutomaticSize = Enum.AutomaticSize.Y
    crossResults.BackgroundColor3 = Color3.fromRGB(28, 30, 36)
    crossResults.BorderSizePixel = 0
    crossResults.LayoutOrder = getLayoutOrder()
    crossResults.Parent = currentParent
    do
        local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 8) c.Parent = crossResults
        local p = Instance.new("UIPadding")
        p.PaddingTop = UDim.new(0, 4) p.PaddingBottom = UDim.new(0, 4)
        p.PaddingLeft = UDim.new(0, 4) p.PaddingRight = UDim.new(0, 4)
        p.Parent = crossResults
        local l = Instance.new("UIListLayout")
        l.Padding = UDim.new(0, 2) l.SortOrder = Enum.SortOrder.LayoutOrder l.Parent = crossResults
    end

    crossSearch:GetPropertyChangedSignal("Text"):Connect(function()
        for _, ch in ipairs(crossResults:GetChildren()) do
            if ch:IsA("TextButton") or ch:IsA("TextLabel") then ch:Destroy() end
        end
        local q = crossSearch.Text:lower()
        if q == "" then return end
        local count = 0
        for _, tabName in ipairs(S.tabOrder) do
            local fr = U.tabFrames[tabName]
            if fr then
                for _, child in ipairs(fr:GetChildren()) do
                    if child:IsA("TextButton") and child.Text:lower():find(q, 1, true) then
                        count = count + 1
                        if count > 25 then return end
                        local o = Instance.new("TextButton")
                        o.Size = UDim2.new(1, 0, 0, mn(26))
                        o.BackgroundColor3 = Color3.fromRGB(34, 36, 43)
                        o.BorderSizePixel = 0
                        o.Text = "[" .. tabName .. "] " .. child.Text
                        o.TextColor3 = Color3.fromRGB(230, 230, 235)
                        o.TextSize = mn(11)
                        o.Font = Enum.Font.GothamSemibold
                        o.AutoButtonColor = false
                        o.TextXAlignment = Enum.TextXAlignment.Left
                        o.LayoutOrder = count
                        o.Parent = crossResults
                        do
                            local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 6) c.Parent = o
                            local p = Instance.new("UIPadding") p.PaddingLeft = UDim.new(0, 8) p.Parent = o
                        end
                        local captured = tabName
                        o.MouseButton1Click:Connect(function()
                            crossSearch.Text = ""
                            switchTab(captured)
                        end)
                    end
                end
            end
        end
        if count == 0 then
            local e = Instance.new("TextLabel")
            e.Size = UDim2.new(1, 0, 0, mn(22))
            e.BackgroundTransparency = 1
            e.Text = "No matches"
            e.TextColor3 = Color3.fromRGB(140, 142, 150)
            e.TextSize = mn(11)
            e.Font = Enum.Font.Gotham
            e.LayoutOrder = 999
            e.Parent = crossResults
        end
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
        U.homeRefs.murdDistLbl = addInfoRow(card, "Distance to Murderer", "-", ROLE_COLORS.Murderer)
    end

    createSectionTitle("QUICK ACTIONS")
    local pvpBtn = createActionButton("HomePvpBtn", "Apply PVP Ready")
    pvpBtn.BackgroundColor3 = Color3.fromRGB(45, 65, 45)
    pvpBtn.MouseButton1Click:Connect(function() if applyPvpPreset then applyPvpPreset() end end)
    local resBtn = createActionButton("HomeRestoreBtn", "Restore Before PVP")
    resBtn.BackgroundColor3 = Color3.fromRGB(60, 50, 35)
    resBtn.MouseButton1Click:Connect(function() if restorePvpSnapshot then restorePvpSnapshot() end end)
    local offBtn = createActionButton("HomeTurnOffBtn", "Turn Off All")
    offBtn.BackgroundColor3 = Color3.fromRGB(70, 40, 40)
    offBtn.TextColor3 = Color3.fromRGB(255, 200, 200)
    offBtn.MouseButton1Click:Connect(function() if resetAllToggles then resetAllToggles() end end)
    local panicBtn = createActionButton("HomePanicBtn", "PANIC (silent off + minimize)")
    panicBtn.BackgroundColor3 = Color3.fromRGB(120, 30, 30)
    panicBtn.TextColor3 = Color3.fromRGB(255, 220, 220)
    panicBtn.MouseButton1Click:Connect(function()
        if silentResetAll then silentResetAll() end
        if minimizeMenu then minimizeMenu() end
    end)

    createSectionTitle("PERFORMANCE")
    do
        local card = createInfoCard()
        U.homeRefs.fpsLbl = addInfoRow(card, "FPS", "--")
        U.homeRefs.pingLbl = addInfoRow(card, "Ping", "--")
    end
    local fpsToggle, fpsInd = createToggle("HomeFpsToggle", "Show FPS/Ping Overlay")
    fpsToggle.MouseButton1Click:Connect(function()
        S.fpsOverlayOn = not S.fpsOverlayOn
        if S.fpsOverlayOn then setOn(fpsToggle, fpsInd) else setOff(fpsToggle, fpsInd) end
        if PerfUI and PerfUI.gui then PerfUI.gui.Enabled = S.fpsOverlayOn end
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
        U.homeRefs.keybindsPlaceholder = addInfoRow(card, "Status", "Loading...")
    end

    createSectionTitle("SCRIPT INFO")
    do
        local card = createInfoCard()
        addInfoRow(card, "Version", SCRIPT_VERSION)
        addInfoRow(card, "Author", SCRIPT_AUTHOR)
        addInfoRow(card, "Updated", CHANGELOG.date or "?")
        U.homeRefs.placeIdLbl = addInfoRow(card, "Place ID", tostring(game.PlaceId))
        U.homeRefs.jobIdLbl = addInfoRow(card, "Job ID", string.sub(game.JobId, 1, 12) .. "...")
        U.homeRefs.regionLbl = addInfoRow(card, "Region", "Loading...")
    end

    local copyBtn = createActionButton("CopyLsBtn", "Copy Loadstring")
    copyBtn.MouseButton1Click:Connect(function()
        local ls = 'loadstring(game:HttpGet("https://raw.githubusercontent.com/arbuz181pl/TEST/refs/heads/main/TEST.lua"))()'
        local ok = pcall(function() setclipboard(ls) end)
        if ok then showToast("Loadstring copied")
        else sendNotification("MM2 Menu", "Clipboard not supported", SOUNDS.alert) end
    end)

    createSectionTitle("NOTIFICATION HISTORY (click to copy)")
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
        l.Padding = UDim.new(0, 3) l.SortOrder = Enum.SortOrder.LayoutOrder l.Parent = U.homeRefs.notifScroll
    end
end

-- ═══════════════════════════════════════════════════════════
-- MOVEMENT
-- ═══════════════════════════════════════════════════════════
local function populateMovement()
    currentParent = U.tabFrames.Movement
    createSectionTitle("MOVEMENT")

    local noclipBtn, noclipInd = createToggle("Noclip", "Noclip")
    U.noclipBtn, U.noclipInd = noclipBtn, noclipInd
    noclipBtn.MouseButton1Click:Connect(function()
        S.noclip = not S.noclip
        if S.noclip then
            setOn(noclipBtn, noclipInd)
            S.originalCollision = {}
            if player.Character then
                for _, o in ipairs(player.Character:GetDescendants()) do
                    if o:IsA("BasePart") then S.originalCollision[o] = o.CanCollide o.CanCollide = false end
                end
            end
        else
            setOff(noclipBtn, noclipInd)
            for o, v in pairs(S.originalCollision) do if o and o.Parent then o.CanCollide = v end end
            S.originalCollision = {}
        end
    end)

    local flyBtn, flyInd = createToggle("Fly", "Fly")
    U.flyBtn, U.flyInd = flyBtn, flyInd

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
    local fh = Instance.new("Frame")
    fh.Size = UDim2.new(1, 0, 0, mn(42))
    fh.BackgroundColor3 = Color3.fromRGB(29, 30, 37)
    fh.BorderSizePixel = 0
    fh.Active = true
    fh.ZIndex = 21
    fh.Parent = FP.panel
    do local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 12) c.Parent = fh end
    FP.header = fh
    local fl = Instance.new("TextLabel")
    fl.Size = UDim2.new(1, -mn(60), 1, 0)
    fl.Position = mpos(10, 0)
    fl.BackgroundTransparency = 1
    fl.Text = "FLY"
    fl.TextColor3 = Color3.fromRGB(245, 245, 250)
    fl.TextSize = mn(13)
    fl.Font = Enum.Font.GothamBold
    fl.TextXAlignment = Enum.TextXAlignment.Left
    fl.ZIndex = 22
    fl.Parent = fh
    local flk = Instance.new("TextButton")
    flk.Size = msz(24, 24)
    flk.Position = UDim2.new(1, -mn(30), 0.5, -mn(12))
    flk.BackgroundColor3 = Color3.fromRGB(42, 44, 52)
    flk.Text = "🔓"
    flk.TextSize = mn(11)
    flk.TextColor3 = Color3.new(1, 1, 1)
    flk.Font = Enum.Font.GothamBold
    flk.BorderSizePixel = 0
    flk.AutoButtonColor = false
    flk.ZIndex = 22
    flk.Parent = fh
    do local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 6) c.Parent = flk end
    FP.lock = flk
    local fen = Instance.new("TextButton")
    fen.Size = UDim2.new(1, -mn(20), 0, mn(36))
    fen.Position = mpos(10, 52)
    fen.BackgroundColor3 = Color3.fromRGB(34, 36, 43)
    fen.BorderSizePixel = 0
    fen.Text = "Enable Fly"
    fen.TextColor3 = Color3.fromRGB(230, 230, 235)
    fen.TextSize = mn(13)
    fen.Font = Enum.Font.GothamSemibold
    fen.AutoButtonColor = false
    fen.ZIndex = 21
    fen.Parent = FP.panel
    do local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 8) c.Parent = fen end
    FP.enable = fen
    local fei = Instance.new("Frame")
    fei.Size = msz(5, 20)
    fei.Position = mpos(8, 8)
    fei.BackgroundColor3 = Color3.fromRGB(80, 82, 90)
    fei.BorderSizePixel = 0
    fei.ZIndex = 22
    fei.Parent = fen
    do local c = Instance.new("UICorner") c.CornerRadius = UDim.new(1, 0) c.Parent = fei end
    FP.enableInd = fei
    local fsl = Instance.new("TextLabel")
    fsl.Size = UDim2.new(1, -mn(20), 0, mn(20))
    fsl.Position = mpos(10, 98)
    fsl.BackgroundTransparency = 1
    fsl.Text = "Speed: 50"
    fsl.TextColor3 = Color3.fromRGB(150, 153, 165)
    fsl.TextSize = mn(11)
    fsl.Font = Enum.Font.GothamBold
    fsl.TextXAlignment = Enum.TextXAlignment.Left
    fsl.ZIndex = 21
    fsl.Parent = FP.panel
    FP.speedLbl = fsl
    local fm = Instance.new("TextButton")
    fm.Size = msz(36, 32)
    fm.Position = mpos(10, 123)
    fm.BackgroundColor3 = Color3.fromRGB(34, 36, 43)
    fm.BorderSizePixel = 0
    fm.Text = "-"
    fm.TextColor3 = Color3.fromRGB(235, 235, 240)
    fm.TextSize = mn(18)
    fm.Font = Enum.Font.GothamBold
    fm.AutoButtonColor = false
    fm.ZIndex = 21
    fm.Parent = FP.panel
    do local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 7) c.Parent = fm end
    FP.minus = fm
    local fsb = Instance.new("TextBox")
    fsb.Size = UDim2.new(1, -mn(96), 0, mn(32))
    fsb.Position = mpos(52, 123)
    fsb.BackgroundColor3 = Color3.fromRGB(34, 36, 43)
    fsb.BorderSizePixel = 0
    fsb.Text = "50"
    fsb.TextColor3 = Color3.fromRGB(235, 235, 240)
    fsb.TextSize = mn(12)
    fsb.Font = Enum.Font.GothamSemibold
    fsb.ClearTextOnFocus = false
    fsb.ZIndex = 21
    fsb.Parent = FP.panel
    do local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 7) c.Parent = fsb end
    FP.speedBox = fsb
    local fp = Instance.new("TextButton")
    fp.Size = msz(36, 32)
    fp.Position = UDim2.new(1, -mn(46), 0, mn(123))
    fp.BackgroundColor3 = Color3.fromRGB(34, 36, 43)
    fp.BorderSizePixel = 0
    fp.Text = "+"
    fp.TextColor3 = Color3.fromRGB(235, 235, 240)
    fp.TextSize = mn(18)
    fp.Font = Enum.Font.GothamBold
    fp.AutoButtonColor = false
    fp.ZIndex = 21
    fp.Parent = FP.panel
    do local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 7) c.Parent = fp end
    FP.plus = fp
    local fu = Instance.new("TextButton")
    fu.Size = msz(85, 32)
    fu.Position = mpos(10, 168)
    fu.BackgroundColor3 = Color3.fromRGB(34, 36, 43)
    fu.BorderSizePixel = 0
    fu.Text = "UP"
    fu.TextColor3 = Color3.fromRGB(230, 230, 235)
    fu.TextSize = mn(12)
    fu.Font = Enum.Font.GothamBold
    fu.AutoButtonColor = false
    fu.ZIndex = 21
    fu.Parent = FP.panel
    do local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 7) c.Parent = fu end
    FP.up = fu
    local fd = Instance.new("TextButton")
    fd.Size = msz(85, 32)
    fd.Position = UDim2.new(1, -mn(95), 0, mn(168))
    fd.BackgroundColor3 = Color3.fromRGB(34, 36, 43)
    fd.BorderSizePixel = 0
    fd.Text = "DOWN"
    fd.TextColor3 = Color3.fromRGB(230, 230, 235)
    fd.TextSize = mn(12)
    fd.Font = Enum.Font.GothamBold
    fd.AutoButtonColor = false
    fd.ZIndex = 21
    fd.Parent = FP.panel
    do local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 7) c.Parent = fd end
    FP.down = fd

    local flyState = { BV = nil, BG = nil, upFlag = 0, downFlag = 0 }

    local function updateFlySpeed(v)
        v = tonumber(v) or S.flySpeed
        v = math.clamp(math.floor(v), 1, 500)
        S.flySpeed = v
        fsl.Text = "Speed: " .. tostring(v)
        fsb.Text = tostring(v)
    end
    fm.MouseButton1Click:Connect(function() updateFlySpeed(S.flySpeed - 1) end)
    fp.MouseButton1Click:Connect(function() updateFlySpeed(S.flySpeed + 1) end)
    fsb.FocusLost:Connect(function() updateFlySpeed(fsb.Text) end)

    stopFly = function()
        S.flyEnabled = false
        if flyState.BV then flyState.BV:Destroy() flyState.BV = nil end
        if flyState.BG then flyState.BG:Destroy() flyState.BG = nil end
        local c = player.Character
        if c then
            local h = c:FindFirstChildOfClass("Humanoid")
            if h then h.PlatformStand = false end
        end
        fen.Text = "Enable Fly"
        setOff(fen, fei)
        setOff(flyBtn, flyInd)
    end

    startFly = function()
        local c = player.Character
        if not c then return end
        local h = c:FindFirstChildOfClass("Humanoid")
        local r = c:FindFirstChild("HumanoidRootPart")
        if not h or not r then return end
        if flyState.BV then flyState.BV:Destroy() end
        if flyState.BG then flyState.BG:Destroy() end
        S.flyEnabled = true
        h.PlatformStand = true
        flyState.BG = Instance.new("BodyGyro")
        flyState.BG.P = 90000
        flyState.BG.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
        flyState.BG.CFrame = r.CFrame
        flyState.BG.Parent = r
        flyState.BV = Instance.new("BodyVelocity")
        flyState.BV.Velocity = Vector3.zero
        flyState.BV.MaxForce = Vector3.new(9e9, 9e9, 9e9)
        flyState.BV.Parent = r
        fen.Text = "Disable Fly"
        setOn(fen, fei)
        setOn(flyBtn, flyInd)
    end

    fen.MouseButton1Click:Connect(function()
        if S.flyEnabled then stopFly() else startFly() end
    end)
    flk.MouseButton1Click:Connect(function()
        S.flyPanelLocked = not S.flyPanelLocked
        if S.flyPanelLocked then
            flk.Text = "🔒"
            flk.BackgroundColor3 = Color3.fromRGB(70, 45, 45)
        else
            flk.Text = "🔓"
            flk.BackgroundColor3 = Color3.fromRGB(42, 44, 52)
        end
    end)
    flyBtn.MouseButton1Click:Connect(function()
        S.flyPanelOpen = not S.flyPanelOpen
        FP.panel.Visible = S.flyPanelOpen
        if S.flyPanelOpen then
            flyBtn.BackgroundColor3 = Color3.fromRGB(45, 47, 56)
        else
            if S.flyEnabled then setOn(flyBtn, flyInd) else setOff(flyBtn, flyInd) end
        end
    end)

    local flyDragStart, flyDragStartPos
    fh.InputBegan:Connect(function(i)
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
        if not S.flyEnabled or not flyState.BV or not flyState.BG then return end
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
        if hum and hum.MoveDirection.Magnitude > 0.05 then dir = dir + hum.MoveDirection end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) or flyState.upFlag == 1 then dir = dir + Vector3.new(0, 1, 0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or flyState.downFlag == -1 then dir = dir - Vector3.new(0, 1, 0) end
        if dir.Magnitude > 0 then flyState.BV.Velocity = dir.Unit * S.flySpeed else flyState.BV.Velocity = Vector3.zero end
        flyState.BG.CFrame = cam.CFrame
    end)

    fu.MouseButton1Down:Connect(function() flyState.upFlag = 1 end)
    fu.MouseButton1Up:Connect(function() flyState.upFlag = 0 end)
    fd.MouseButton1Down:Connect(function() flyState.downFlag = -1 end)
    fd.MouseButton1Up:Connect(function() flyState.downFlag = 0 end)

    local infBtn, infInd = createToggle("InfinityJump", "Infinity Jump")
    U.infBtn, U.infInd = infBtn, infInd
    infBtn.MouseButton1Click:Connect(function()
        S.infinityJump = not S.infinityJump
        if S.infinityJump then setOn(infBtn, infInd) else setOff(infBtn, infInd) end
    end)
    UserInputService.JumpRequest:Connect(function()
        if not S.infinityJump then return end
        local c = player.Character
        if not c then return end
        local h = c:FindFirstChildOfClass("Humanoid")
        if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
    end)

    local f3Btn, f3Ind = createToggle("FlingOnTouch", "Fling 3rd party")
    U.f3Btn, U.f3Ind = f3Btn, f3Ind
    f3Btn.MouseButton1Click:Connect(function()
        S.flingThirdParty = not S.flingThirdParty
        if S.flingThirdParty then
            f3Btn.BackgroundColor3 = Color3.fromRGB(70, 45, 35)
            f3Ind.BackgroundColor3 = Color3.fromRGB(230, 100, 55)
            local ok = pcall(function() loadstring(game:HttpGet("https://rawscripts.net/raw/Universal-Script-Ultimate-Fling-GUI-41909"))() end)
            if not ok then sendNotification("MM2 Menu", "Failed to load fling script.") end
        else
            setOff(f3Btn, f3Ind)
        end
    end)

    local function flingLoop()
        local c, hrp, vel, movel = nil, nil, nil, 0.1
        while S.flingTouchActive do
            RunService.Heartbeat:Wait()
            c = player.Character
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

    local fib, fii = createToggle("FlingOnTouchIntegrated", "Fling On Touch")
    U.fib, U.fii = fib, fii
    fib.MouseButton1Click:Connect(function()
        S.flingOnTouch = not S.flingOnTouch
        if S.flingOnTouch then
            fib.BackgroundColor3 = Color3.fromRGB(70, 45, 35)
            fii.BackgroundColor3 = Color3.fromRGB(230, 100, 55)
            S.flingTouchActive = true
            S.flingTouchThread = coroutine.create(flingLoop)
            coroutine.resume(S.flingTouchThread)
        else
            setOff(fib, fii)
            S.flingTouchActive = false
        end
    end)

    createSectionTitle("SPEEDHACK")
    local shBtn, shInd = createToggle("Speedhack", "Speedhack")
    U.shBtn, U.shInd = shBtn, shInd
    local shRow = Instance.new("Frame")
    shRow.Size = UDim2.new(1, 0, 0, mn(30))
    shRow.BackgroundTransparency = 1
    shRow.LayoutOrder = getLayoutOrder()
    shRow.Parent = currentParent

    local shMinus = Instance.new("TextButton")
    shMinus.Size = msz(34, 30)
    shMinus.BackgroundColor3 = Color3.fromRGB(34, 36, 43)
    shMinus.BorderSizePixel = 0
    shMinus.Text = "-"
    shMinus.TextColor3 = Color3.fromRGB(235, 235, 240)
    shMinus.TextSize = mn(18)
    shMinus.Font = Enum.Font.GothamBold
    shMinus.AutoButtonColor = false
    shMinus.Parent = shRow
    do local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 7) c.Parent = shMinus end

    local shBox = Instance.new("TextBox")
    shBox.Size = msz(50, 30)
    shBox.Position = mpos(40, 0)
    shBox.BackgroundColor3 = Color3.fromRGB(34, 36, 43)
    shBox.BorderSizePixel = 0
    shBox.Text = "45"
    shBox.TextColor3 = Color3.fromRGB(235, 235, 240)
    shBox.TextSize = mn(12)
    shBox.Font = Enum.Font.GothamSemibold
    shBox.ClearTextOnFocus = false
    shBox.Parent = shRow
    do local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 7) c.Parent = shBox end

    local shPlus = Instance.new("TextButton")
    shPlus.Size = msz(34, 30)
    shPlus.Position = mpos(96, 0)
    shPlus.BackgroundColor3 = Color3.fromRGB(34, 36, 43)
    shPlus.BorderSizePixel = 0
    shPlus.Text = "+"
    shPlus.TextColor3 = Color3.fromRGB(235, 235, 240)
    shPlus.TextSize = mn(18)
    shPlus.Font = Enum.Font.GothamBold
    shPlus.AutoButtonColor = false
    shPlus.Parent = shRow
    do local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 7) c.Parent = shPlus end

    local shLbl = Instance.new("TextLabel")
    shLbl.Size = UDim2.new(1, -mn(138), 0, mn(30))
    shLbl.Position = mpos(138, 0)
    shLbl.BackgroundTransparency = 1
    shLbl.Text = "WalkSpeed"
    shLbl.TextColor3 = Color3.fromRGB(150, 153, 165)
    shLbl.TextSize = mn(11)
    shLbl.Font = Enum.Font.GothamBold
    shLbl.TextXAlignment = Enum.TextXAlignment.Left
    shLbl.Parent = shRow

    local function updateSH(v)
        v = tonumber(v) or S.speedhackSpeed
        v = math.clamp(math.floor(v), 1, 100)
        S.speedhackSpeed = v
        shBox.Text = tostring(v)
    end
    shMinus.MouseButton1Click:Connect(function() updateSH(S.speedhackSpeed - 5) end)
    shPlus.MouseButton1Click:Connect(function() updateSH(S.speedhackSpeed + 5) end)
    shBox.FocusLost:Connect(function() updateSH(shBox.Text) end)

    shBtn.MouseButton1Click:Connect(function()
        S.speedhackEnabled = not S.speedhackEnabled
        if S.speedhackEnabled then
            setOn(shBtn, shInd)
            local c = player.Character
            if c then local h = c:FindFirstChildOfClass("Humanoid") if h then h.WalkSpeed = S.speedhackSpeed end end
        else
            setOff(shBtn, shInd)
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
end

-- ═══════════════════════════════════════════════════════════
-- ESP
-- ═══════════════════════════════════════════════════════════
local function populateESP()
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
    local gunBtn, gunInd = createToggle("GunESP", "Gun ESP")
    U.gunBtn, U.gunInd = gunBtn, gunInd
    gunBtn.MouseButton1Click:Connect(function()
        S.gunESPEnabled = not S.gunESPEnabled
        if S.gunESPEnabled then
            gunBtn.BackgroundColor3 = GUN_COLOR:Lerp(Color3.fromRGB(20, 20, 25), 0.65)
            gunInd.BackgroundColor3 = GUN_COLOR
        else
            setOff(gunBtn, gunInd)
            for g, hl in pairs(S.gunHighlights) do if hl then pcall(function() hl:Destroy() end) end end
            S.gunHighlights = {}
        end
    end)

    createSectionTitle("PLAYER INFO")
    local distBtn, distInd = createToggle("PlayerDistance", "Player Distance (studs)")
    U.distBtn, U.distInd = distBtn, distInd
    distBtn.MouseButton1Click:Connect(function()
        S.playerDistanceOn = not S.playerDistanceOn
        if S.playerDistanceOn then
            setOn(distBtn, distInd)
        else
            setOff(distBtn, distInd)
            for p, bg in pairs(S.playerDistBillboards) do if bg then bg:Destroy() end end
            S.playerDistBillboards = {}
        end
    end)
end

-- ═══════════════════════════════════════════════════════════
-- NOTIFIER
-- ═══════════════════════════════════════════════════════════
fmtRole = function(r, n)
    if not n then return r .. ": None" end
    local t = Players:FindFirstChild(n)
    if t then return r .. ": " .. t.DisplayName .. " (@" .. t.Name .. ")" end
    return r .. ": " .. n
end

notifyAllRoles = function()
    sendNotification("MM2 Roles", fmtRole("Murderer", MurdererName) .. "\n" .. fmtRole("Sheriff", SheriffName) .. "\n" .. fmtRole("Hero", HeroName))
end

sendChat = function(msg)
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

getRoleMessage = function(role, name)
    if not name then return role .. ": Unknown" end
    local t = Players:FindFirstChild(name)
    if t then return role .. " is: " .. t.DisplayName .. " (@" .. t.Name .. ")" end
    return role .. " is: " .. name
end

local function populateNotifier()
    currentParent = U.tabFrames.Notifier
    createSectionTitle("NOTIFIER")

    local nBtn = createActionButton("NotifyRoles", "Notify Roles")
    nBtn.MouseButton1Click:Connect(function() notifyAllRoles() end)

    local autoNotBtn, autoNotInd = createToggle("AutoNotifyRound", "Auto Notify Round (Roles)")
    U.autoNotBtn, U.autoNotInd = autoNotBtn, autoNotInd
    autoNotBtn.MouseButton1Click:Connect(function()
        S.autoNotifyRoles = not S.autoNotifyRoles
        if S.autoNotifyRoles then
            setOn(autoNotBtn, autoNotInd)
        else
            setOff(autoNotBtn, autoNotInd)
            lastNotifiedMurderer = nil; lastNotifiedSheriff = nil; lastNotifiedHero = nil
            S.pendingNotify = false
        end
    end)

    local reAnnBtn, reAnnInd = createToggle("ReAnnounce", "Re-announce Roles Every 30s")
    U.reAnnBtn, U.reAnnInd = reAnnBtn, reAnnInd
    reAnnBtn.MouseButton1Click:Connect(function()
        S.reAnnounceEnabled = not S.reAnnounceEnabled
        if S.reAnnounceEnabled then setOn(reAnnBtn, reAnnInd) S.lastReAnnounceTime = 0
        else setOff(reAnnBtn, reAnnInd) end
    end)

    local heroBtn, heroInd = createToggle("HeroChangeNotify", "Notify When Hero Changes")
    U.heroChangeBtn, U.heroChangeInd = heroBtn, heroInd
    heroBtn.MouseButton1Click:Connect(function()
        S.heroChangeNotify = not S.heroChangeNotify
        if S.heroChangeNotify then setOn(heroBtn, heroInd) else setOff(heroBtn, heroInd) end
    end)

    createSectionTitle("ROUND EVENTS")
    local rStartBtn, rStartInd = createToggle("NotifyRoundStart", "Notify Round Start")
    U.rStartBtn, U.rStartInd = rStartBtn, rStartInd
    rStartBtn.MouseButton1Click:Connect(function()
        S.notifyRoundStart = not S.notifyRoundStart
        if S.notifyRoundStart then setOn(rStartBtn, rStartInd) else setOff(rStartBtn, rStartInd) end
    end)

    local rEndBtn, rEndInd = createToggle("NotifyRoundEnd", "Notify Round End")
    U.rEndBtn, U.rEndInd = rEndBtn, rEndInd
    rEndBtn.MouseButton1Click:Connect(function()
        S.notifyRoundEnd = not S.notifyRoundEnd
        if S.notifyRoundEnd then setOn(rEndBtn, rEndInd) else setOff(rEndBtn, rEndInd) end
    end)

    local plBtn, plInd = createToggle("PlayerJoinLeaveNotify", "Player Join/Leave Alerts")
    U.plBtn, U.plInd = plBtn, plInd
    plBtn.MouseButton1Click:Connect(function()
        S.playerJoinLeaveNotify = not S.playerJoinLeaveNotify
        if S.playerJoinLeaveNotify then setOn(plBtn, plInd) else setOff(plBtn, plInd) end
    end)

    local autoHideBtn, autoHideInd = createToggle("AutoHideInRound", "Auto-hide UI When Round Starts")
    U.autoHideBtn, U.autoHideInd = autoHideBtn, autoHideInd
    autoHideBtn.MouseButton1Click:Connect(function()
        S.autoHideInRound = not S.autoHideInRound
        if S.autoHideInRound then setOn(autoHideBtn, autoHideInd) else setOff(autoHideBtn, autoHideInd) end
    end)

    createSectionTitle("CHAT ANNOUNCEMENTS")
    local sendMBtn = createActionButton("SendMurdererChat", "Send Murderer In Chat")
    sendMBtn.MouseButton1Click:Connect(function()
        if not MurdererName then sendNotification("MM2 Menu", "Murderer not found", SOUNDS.alert) return end
        if MurdererName == player.Name then sendNotification("MM2 Menu", "You are the Murderer!", SOUNDS.alert) return end
        sendChat(getRoleMessage("Murderer", MurdererName))
    end)
    local sendSBtn = createActionButton("SendSheriffChat", "Send Sheriff In Chat")
    sendSBtn.MouseButton1Click:Connect(function()
        if not SheriffName then sendNotification("MM2 Menu", "Sheriff not found", SOUNDS.alert) return end
        if SheriffName == player.Name then sendNotification("MM2 Menu", "You are the Sheriff!", SOUNDS.alert) return end
        sendChat(getRoleMessage("Sheriff", SheriffName))
    end)
    local autoChatBtn, autoChatInd = createToggle("AutoMurdererChat", "Auto Send Murderer In Chat")
    U.autoChatBtn, U.autoChatInd = autoChatBtn, autoChatInd
    autoChatBtn.MouseButton1Click:Connect(function()
        S.autoSendMurdererChat = not S.autoSendMurdererChat
        if S.autoSendMurdererChat then
            setOn(autoChatBtn, autoChatInd)
            S.lastChatSentMurderer = nil S.roundActive = false S.selfNotifyMurderer = false
        else
            setOff(autoChatBtn, autoChatInd)
            S.lastChatSentMurderer = nil S.roundActive = false S.selfNotifyMurderer = false
        end
    end)
    local autoSBtn, autoSInd = createToggle("AutoSheriffChat", "Auto Send Sheriff In Chat")
    U.autoSheriffChatBtn, U.autoSheriffChatInd = autoSBtn, autoSInd
    autoSBtn.MouseButton1Click:Connect(function()
        S.autoSendSheriffChat = not S.autoSendSheriffChat
        if S.autoSendSheriffChat then
            setOn(autoSBtn, autoSInd)
            S.lastChatSentSheriff = nil S.roundActiveSheriff = false S.selfNotifySheriff = false
        else
            setOff(autoSBtn, autoSInd)
            S.lastChatSentSheriff = nil S.roundActiveSheriff = false S.selfNotifySheriff = false
        end
    end)
end

-- ═══════════════════════════════════════════════════════════
-- MURDERER
-- ═══════════════════════════════════════════════════════════
local function populateMurderer()
    currentParent = U.tabFrames.Murderer
    createSectionTitle("MURDERER")

    local autoKillBtn, autoKillInd = createToggle("AutoKillAll", "Auto Kill All")
    U.autoKillBtn, U.autoKillInd = autoKillBtn, autoKillInd
    autoKillBtn.MouseButton1Click:Connect(function()
        S.autoKillAll = not S.autoKillAll
        if S.autoKillAll then setOn(autoKillBtn, autoKillInd) else setOff(autoKillBtn, autoKillInd) end
    end)

    local killAllBtn = createActionButton("KillAllNow", "Kill All Now")
    killAllBtn.MouseButton1Click:Connect(function() if killAllPlayers then killAllPlayers() end end)

    local killSBtn = createActionButton("KillSheriffNow", "Kill Sheriff Now")
    killSBtn.MouseButton1Click:Connect(function()
        if SheriffName then local t = Players:FindFirstChild(SheriffName) if t and attackTarget then attackTarget(t) end end
    end)

    local killHBtn = createActionButton("KillHeroNow", "Kill Hero Now")
    killHBtn.MouseButton1Click:Connect(function()
        if HeroName then local t = Players:FindFirstChild(HeroName) if t and attackTarget then attackTarget(t) end end
    end)

    local killSoundBtn, killSoundInd = createToggle("KillSound", "Kill Sound")
    U.killSoundBtn, U.killSoundInd = killSoundBtn, killSoundInd
    killSoundBtn.MouseButton1Click:Connect(function()
        S.killSoundOn = not S.killSoundOn
        if S.killSoundOn then setOn(killSoundBtn, killSoundInd) else setOff(killSoundBtn, killSoundInd) end
    end)
end

-- ═══════════════════════════════════════════════════════════
-- SHERIFF
-- ═══════════════════════════════════════════════════════════
local function populateSheriff()
    currentParent = U.tabFrames.Sheriff
    createSectionTitle("SHERIFF")

    local killMurdererBtn = createActionButton("KillMurdererNow", "Kill Murderer Now")
    killMurdererBtn.MouseButton1Click:Connect(function()
        if not MurdererName then sendNotification("MM2 Menu", "Murderer not found yet!", SOUNDS.alert) return end
        local t = Players:FindFirstChild(MurdererName)
        if not t or not t.Character then return end
        if isPlayerInSpawn(t) then sendNotification("MM2 Menu", "Murderer is in spawn/lobby!", SOUNDS.alert) return end
        local tr = t.Character:FindFirstChild("HumanoidRootPart")
        local mr = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        if tr and mr then
            local c = player.Character
            local g = c:FindFirstChild("Gun")
            if not g then
                local bp = player:FindFirstChild("Backpack")
                if bp then g = bp:FindFirstChild("Gun") if g then g.Parent = c end end
            end
            if g then
                mr.CFrame = tr.CFrame * CFrame.new(0, 0, 5)
                task.wait(0.05)
                local sr = g:FindFirstChild("Shoot") or ReplicatedStorage:FindFirstChild("Shoot", true)
                if sr and sr:IsA("RemoteEvent") then sr:FireServer(tr.CFrame, tr.Position) else g:Activate() end
            else
                sendNotification("MM2 Menu", "You do not have a Gun equipped!", SOUNDS.alert)
            end
        end
    end)
end

-- ═══════════════════════════════════════════════════════════
-- TELEPORT
-- ═══════════════════════════════════════════════════════════
local function populateTeleport()
    currentParent = U.tabFrames.Teleport
    createSectionTitle("PLAYER ACTIONS")

    local pDrop = Instance.new("TextButton")
    pDrop.Size = UDim2.new(1, 0, 0, mn(30))
    pDrop.BackgroundColor3 = Color3.fromRGB(34, 36, 43)
    pDrop.BorderSizePixel = 0
    pDrop.Text = "Select Player"
    pDrop.TextColor3 = Color3.fromRGB(230, 230, 235)
    pDrop.TextSize = mn(12)
    pDrop.Font = Enum.Font.GothamSemibold
    pDrop.AutoButtonColor = false
    pDrop.LayoutOrder = getLayoutOrder()
    pDrop.Parent = currentParent
    do local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 8) c.Parent = pDrop end
    U.pDropdown = pDrop

    local pList = Instance.new("ScrollingFrame")
    pList.Size = UDim2.new(1, 0, 0, 0)
    pList.BackgroundColor3 = Color3.fromRGB(29, 30, 37)
    pList.BorderSizePixel = 0
    pList.Visible = false
    pList.ClipsDescendants = true
    pList.AutomaticCanvasSize = Enum.AutomaticSize.Y
    pList.ScrollingDirection = Enum.ScrollingDirection.Y
    pList.ScrollBarThickness = 5
    pList.ScrollBarImageColor3 = Color3.fromRGB(75, 77, 85)
    pList.LayoutOrder = getLayoutOrder()
    pList.Parent = currentParent
    do
        local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 8) c.Parent = pList
        local l = Instance.new("UIListLayout") l.Padding = UDim.new(0, 2) l.SortOrder = Enum.SortOrder.Name l.Parent = pList
    end

    local function refreshPList()
        for _, ch in ipairs(pList:GetChildren()) do if ch:IsA("TextButton") then ch:Destroy() end end
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
                o.Parent = pList
                do local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 6) c.Parent = o end
                o.MouseButton1Click:Connect(function()
                    S.selectedPlayer = t
                    pDrop.Text = "Selected: " .. t.Name
                    S.dropdownOpen = false
                    pList.Visible = false
                    pList.Size = UDim2.new(1, 0, 0, 0)
                end)
            end
        end
    end

    pDrop.MouseButton1Click:Connect(function()
        S.dropdownOpen = not S.dropdownOpen
        if S.dropdownOpen then
            refreshPList()
            pList.Visible = true
            pList.Size = UDim2.new(1, 0, 0, mn(120))
        else
            pList.Visible = false
            pList.Size = UDim2.new(1, 0, 0, 0)
        end
    end)

    Players.PlayerAdded:Connect(function() if S.dropdownOpen then refreshPList() end end)
    Players.PlayerRemoving:Connect(function(t)
        if S.selectedPlayer == t then S.selectedPlayer = nil pDrop.Text = "Select Player" end
        if S.dropdownOpen then refreshPList() end
    end)

    local tpBtn = createActionButton("PlayerTeleport", "Teleport To Player")
    tpBtn.MouseButton1Click:Connect(function()
        if not S.selectedPlayer or not S.selectedPlayer.Character then return end
        local tr = S.selectedPlayer.Character:FindFirstChild("HumanoidRootPart")
        local c = player.Character
        if c and tr then
            local mr = c:FindFirstChild("HumanoidRootPart")
            if mr then mr.CFrame = tr.CFrame + Vector3.new(0, 3, 0) end
        end
    end)

    local killSelBtn = createActionButton("KillSelectedPlayer", "Kill Selected Player")
    killSelBtn.MouseButton1Click:Connect(function()
        if S.selectedPlayer and attackTarget then attackTarget(S.selectedPlayer) end
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
    local tpM = createActionButton("TeleportMurderer", "Teleport To Murderer")
    tpM.MouseButton1Click:Connect(function() tpByName(MurdererName) end)
    local tpS = createActionButton("TeleportSheriff", "Teleport To Sheriff")
    tpS.MouseButton1Click:Connect(function() tpByName(SheriffName) end)
    local tpH = createActionButton("TeleportHero", "Teleport To Hero")
    tpH.MouseButton1Click:Connect(function() tpByName(HeroName) end)

    createSectionTitle("WORLD TELEPORTS")
    local autoGunBtn, autoGunInd = createToggle("AutoGunTP", "Auto Teleport To Gun")
    U.autoGunBtn, U.autoGunInd = autoGunBtn, autoGunInd
    autoGunBtn.MouseButton1Click:Connect(function()
        S.autoGunTP = not S.autoGunTP
        if S.autoGunTP then setOn(autoGunBtn, autoGunInd) else setOff(autoGunBtn, autoGunInd) end
    end)

    local spawnBtn = createActionButton("SpawnTeleport", "Teleport To Spawn")
    spawnBtn.MouseButton1Click:Connect(function()
        local c = player.Character
        if not c then return end
        local mr = c:FindFirstChild("HumanoidRootPart")
        if not mr then return end
        local sl = workspace:FindFirstChildOfClass("SpawnLocation")
        if sl then mr.CFrame = sl.CFrame + Vector3.new(0, 3, 0) return end
        local sp = workspace:FindFirstChild("Spawn", true)
        if sp and sp:IsA("BasePart") then mr.CFrame = sp.CFrame + Vector3.new(0, 3, 0) end
    end)

    local gunBtn2 = createActionButton("GunTeleport", "Teleport To Gun")
    gunBtn2.MouseButton1Click:Connect(function()
        local c = player.Character
        if not c then return end
        local mr = c:FindFirstChild("HumanoidRootPart")
        if not mr then return end
        local gd = workspace:FindFirstChild("GunDrop", true) or workspace:FindFirstChild("Gun", true)
        if not gd then sendNotification("MM2 Menu", "No dropped gun found!", SOUNDS.alert) return end
        local tp
        if gd:IsA("BasePart") then tp = gd
        elseif gd:IsA("Model") then tp = gd.PrimaryPart or gd:FindFirstChildOfClass("BasePart")
        elseif gd:IsA("Tool") then tp = gd:FindFirstChild("Handle") or gd:FindFirstChildOfClass("BasePart") end
        if not tp then return end
        local orig = mr.CFrame
        mr.CFrame = tp.CFrame + Vector3.new(0, 3, 0)
        task.wait(0.35)
        mr.CFrame = orig
    end)
end

-- ═══════════════════════════════════════════════════════════
-- KEYBINDS
-- ═══════════════════════════════════════════════════════════
local function populateKeybinds()
    currentParent = U.tabFrames.Keybinds
    createSectionTitle("KEYBINDS")

    local kbEnabledBtn, kbEnabledInd = createToggle("KeybindsEnabled", "All Keybinds Enabled")
    U.kbEnabledBtn, U.kbEnabledInd = kbEnabledBtn, kbEnabledInd
    setOn(kbEnabledBtn, kbEnabledInd)
    kbEnabledBtn.MouseButton1Click:Connect(function()
        S.keybindsEnabled = not S.keybindsEnabled
        if S.keybindsEnabled then setOn(kbEnabledBtn, kbEnabledInd) else setRed(kbEnabledBtn, kbEnabledInd) end
        S.homeRebuildDirty = true
    end)

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

    U.endCapture = function()
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
        kb.MouseButton1Click:Connect(function() startCapture(entry.id, kb) end)
    end
end

-- ═══════════════════════════════════════════════════════════
-- SETTINGS
-- ═══════════════════════════════════════════════════════════
local function populateSettings()
    currentParent = U.tabFrames.Settings
    createSectionTitle("MENU SETTINGS")

    local compactBtn, compactInd = createToggle("CompactMode", "Compact Mode")
    U.compactBtn, U.compactInd = compactBtn, compactInd
    compactBtn.MouseButton1Click:Connect(function()
        S.compactMode = not S.compactMode
        if S.compactMode then setOn(compactBtn, compactInd) else setOff(compactBtn, compactInd) end
        local factor = S.compactMode and 0.88 or 1
        for _, d in ipairs(U.frame:GetDescendants()) do
            if d:IsA("TextLabel") or d:IsA("TextButton") or d:IsA("TextBox") then
                local base = d:GetAttribute("BaseTextSize")
                if not base then base = d.TextSize d:SetAttribute("BaseTextSize", base) end
                d.TextSize = math.max(8, math.floor(base * factor))
            end
        end
    end)

    createSectionTitle("MENU OPACITY")
    local opLbl = Instance.new("TextLabel")
    opLbl.Size = UDim2.new(1, 0, 0, mn(18))
    opLbl.BackgroundTransparency = 1
    opLbl.Text = "Menu Opacity: 100%"
    opLbl.TextColor3 = Color3.fromRGB(150, 153, 165)
    opLbl.TextSize = mn(11)
    opLbl.Font = Enum.Font.GothamBold
    opLbl.TextXAlignment = Enum.TextXAlignment.Left
    opLbl.LayoutOrder = getLayoutOrder()
    opLbl.Parent = currentParent

    local opSlider = Instance.new("TextButton")
    opSlider.Size = UDim2.new(1, 0, 0, mn(30))
    opSlider.BackgroundColor3 = Color3.fromRGB(34, 36, 43)
    opSlider.BorderSizePixel = 0
    opSlider.Text = ""
    opSlider.AutoButtonColor = false
    opSlider.LayoutOrder = getLayoutOrder()
    opSlider.Parent = currentParent
    do local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 8) c.Parent = opSlider end
    local opFill = Instance.new("Frame")
    opFill.Size = UDim2.new(1, 0, 1, 0)
    opFill.BackgroundColor3 = Color3.fromRGB(60, 130, 80)
    opFill.BorderSizePixel = 0
    opFill.Parent = opSlider
    do local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 8) c.Parent = opFill end
    local opHandle = Instance.new("Frame")
    opHandle.Size = msz(6, 24)
    opHandle.Position = UDim2.new(1, -mn(6), 0.5, -mn(12))
    opHandle.BackgroundColor3 = Color3.fromRGB(220, 220, 230)
    opHandle.BorderSizePixel = 0
    opHandle.ZIndex = 2
    opHandle.Parent = opSlider
    do local c = Instance.new("UICorner") c.CornerRadius = UDim.new(1, 0) c.Parent = opHandle end

    local opDragging = false
    local function applyOpacity(pct)
        pct = math.clamp(pct, 10, 100)
        S.menuOpacity = pct
        opLbl.Text = "Menu Opacity: " .. tostring(pct) .. "%"
        opFill.Size = UDim2.new(pct / 100, 0, 1, 0)
        opHandle.Position = UDim2.new(pct / 100, -mn(6), 0.5, -mn(12))
        U.canvas.GroupTransparency = 1 - (pct / 100)
    end
    opSlider.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            opDragging = true
        end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if not opDragging then return end
        if i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch then
            local rel = (i.Position.X - opSlider.AbsolutePosition.X) / opSlider.AbsoluteSize.X
            applyOpacity(math.floor(rel * 100))
        end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            opDragging = false
        end
    end)
    applyOpacity(100)

    local function makeSlider(labelText, color, onApply, onRelease)
        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, 0, 0, mn(18))
        lbl.BackgroundTransparency = 1
        lbl.Text = labelText .. ": 100%"
        lbl.TextColor3 = Color3.fromRGB(150, 153, 165)
        lbl.TextSize = mn(11)
        lbl.Font = Enum.Font.GothamBold
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.LayoutOrder = getLayoutOrder()
        lbl.Parent = currentParent
        local sl = Instance.new("TextButton")
        sl.Size = UDim2.new(1, 0, 0, mn(30))
        sl.BackgroundColor3 = Color3.fromRGB(34, 36, 43)
        sl.BorderSizePixel = 0
        sl.Text = ""
        sl.AutoButtonColor = false
        sl.LayoutOrder = getLayoutOrder()
        sl.Parent = currentParent
        do local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 8) c.Parent = sl end
        local fill = Instance.new("Frame")
        fill.Size = UDim2.new(1, 0, 1, 0)
        fill.BackgroundColor3 = color
        fill.BorderSizePixel = 0
        fill.Parent = sl
        do local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 8) c.Parent = fill end
        local handle = Instance.new("Frame")
        handle.Size = msz(6, 24)
        handle.Position = UDim2.new(1, -mn(6), 0.5, -mn(12))
        handle.BackgroundColor3 = Color3.fromRGB(220, 220, 230)
        handle.BorderSizePixel = 0
        handle.ZIndex = 2
        handle.Parent = sl
        do local c = Instance.new("UICorner") c.CornerRadius = UDim.new(1, 0) c.Parent = handle end
        local dragging = false
        local function apply(pct)
            pct = math.clamp(pct, 0, 100)
            lbl.Text = labelText .. ": " .. tostring(pct) .. "%"
            fill.Size = UDim2.new(pct / 100, 0, 1, 0)
            handle.Position = UDim2.new(pct / 100, -mn(6), 0.5, -mn(12))
            onApply(pct)
        end
        sl.InputBegan:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
                dragging = true
            end
        end)
        UserInputService.InputChanged:Connect(function(i)
            if not dragging then return end
            if i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch then
                local rel = (i.Position.X - sl.AbsolutePosition.X) / sl.AbsoluteSize.X
                apply(math.floor(rel * 100))
            end
        end)
        UserInputService.InputEnded:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
                if dragging and onRelease then onRelease() end
                dragging = false
            end
        end)
        return apply
    end

    local applyMenuSound = makeSlider("Menu Sound Volume", Color3.fromRGB(70, 110, 160),
        function(pct) S.menuVolume = pct end,
        function() playSound(SOUNDS.notify, 1, false) end)
    applyMenuSound(100)
    local applyKillSound = makeSlider("Kill Sound Volume", Color3.fromRGB(160, 70, 70),
        function(pct) S.killVolume = pct end,
        function() playSound(SOUNDS.success, 1.5, true) end)
    applyKillSound(100)
end

-- ═══════════════════════════════════════════════════════════
-- UTILITY
-- ═══════════════════════════════════════════════════════════
local function populateUtility()
    currentParent = U.tabFrames.Utility
    createSectionTitle("UTILITY")

    local avBtn, avInd = createToggle("AntiVoid", "Anti Fall Down (Void)")
    U.avBtn, U.avInd = avBtn, avInd
    avBtn.MouseButton1Click:Connect(function()
        S.antiVoidEnabled = not S.antiVoidEnabled
        if S.antiVoidEnabled then setOn(avBtn, avInd) else setOff(avBtn, avInd) end
    end)

    local afBtn, afInd = createToggle("AntiFling", "Anti Fling")
    U.afBtn, U.afInd = afBtn, afInd
    afBtn.MouseButton1Click:Connect(function()
        S.antiFlingEnabled = not S.antiFlingEnabled
        if S.antiFlingEnabled then setOn(afBtn, afInd) else setOff(afBtn, afInd) end
    end)

    local afkBtn, afkInd = createToggle("AntiAfk", "Anti AFK")
    U.afkBtn, U.afkInd = afkBtn, afkInd
    afkBtn.MouseButton1Click:Connect(function()
        S.antiAfkEnabled = not S.antiAfkEnabled
        if S.antiAfkEnabled then
            setOn(afkBtn, afkInd)
            if S.antiAfkConn then S.antiAfkConn:Disconnect() end
            S.antiAfkConn = player.Idled:Connect(function()
                local VU = game:GetService("VirtualUser")
                VU:CaptureController()
                VU:ClickButton2(Vector2.new())
            end)
        else
            setOff(afkBtn, afkInd)
            if S.antiAfkConn then S.antiAfkConn:Disconnect() S.antiAfkConn = nil end
        end
    end)

    local gdBtn, gdInd = createToggle("GunDropAlert", "Gun Drop Alert")
    U.gunAlertBtn, U.gunAlertInd = gdBtn, gdInd
    gdBtn.MouseButton1Click:Connect(function()
        S.gunDropAlert = not S.gunDropAlert
        if S.gunDropAlert then setOn(gdBtn, gdInd) else setOff(gdBtn, gdInd) end
    end)

    createSectionTitle("OVERLAYS")
    local kaBtn, kaInd = createToggle("KillerAlarm", "Killer Alarm (30 studs)")
    U.killerAlarmBtn, U.killerAlarmInd = kaBtn, kaInd
    kaBtn.MouseButton1Click:Connect(function()
        S.killerAlarmOn = not S.killerAlarmOn
        if S.killerAlarmOn then
            setOn(kaBtn, kaInd)
            S.lastAlarmDist = math.huge S.lastAlarmTime = 0
        else
            setOff(kaBtn, kaInd)
            S.lastAlarmDist = math.huge
        end
    end)

    local dirBtn, dirInd = createToggle("DirIndicator", "Direction Arrow to Murderer")
    U.dirBtn, U.dirInd = dirBtn, dirInd
    dirBtn.MouseButton1Click:Connect(function()
        S.dirIndicatorOn = not S.dirIndicatorOn
        if S.dirIndicatorOn then
            setOn(dirBtn, dirInd)
        else
            setOff(dirBtn, dirInd)
            if DirUI and DirUI.gui then DirUI.gui.Enabled = false end
        end
    end)

    local camBtn, camInd = createToggle("CameraFollowMurderer", "Camera Follow Murderer")
    U.camFollowBtn, U.camFollowInd = camBtn, camInd
    camBtn.MouseButton1Click:Connect(function()
        S.cameraFollowMurderer = not S.cameraFollowMurderer
        if S.cameraFollowMurderer then setOn(camBtn, camInd) else setOff(camBtn, camInd) end
    end)

    local chBtn, chInd = createToggle("Crosshair", "Rainbow Crosshair")
    U.crosshairBtn, U.crosshairInd = chBtn, chInd
    chBtn.MouseButton1Click:Connect(function()
        if IS_MOBILE then
            sendNotification("MM2 Menu", "Crosshair is not needed on mobile - your finger is the crosshair.", SOUNDS.alert)
            return
        end
        S.crosshairOn = not S.crosshairOn
        if S.crosshairOn then
            setOn(chBtn, chInd)
            if S.crosshairGui then S.crosshairGui.Enabled = true end
        else
            setOff(chBtn, chInd)
            if S.crosshairGui then S.crosshairGui.Enabled = false end
        end
    end)

    createSectionTitle("TRAILS")
    local ktBtn, ktInd = createToggle("KillerTrail", "Killer Trail")
    U.killerTrailBtn, U.killerTrailInd = ktBtn, ktInd
    ktBtn.MouseButton1Click:Connect(function()
        S.killerTrailOn = not S.killerTrailOn
        if S.killerTrailOn then setOn(ktBtn, ktInd) else setOff(ktBtn, ktInd) end
    end)

    local stBtn, stInd = createToggle("SheriffTrail", "Sheriff Trail")
    U.sheriffTrailBtn, U.sheriffTrailInd = stBtn, stInd
    stBtn.MouseButton1Click:Connect(function()
        S.sheriffTrailOn = not S.sheriffTrailOn
        if S.sheriffTrailOn then setOn(stBtn, stInd) else setOff(stBtn, stInd) end
    end)

    local htBtn, htInd = createToggle("HeroTrail", "Hero Trail")
    U.heroTrailBtn, U.heroTrailInd = htBtn, htInd
    htBtn.MouseButton1Click:Connect(function()
        S.heroTrailOn = not S.heroTrailOn
        if S.heroTrailOn then setOn(htBtn, htInd) else setOff(htBtn, htInd) end
    end)

    createSectionTitle("SERVER")
    local rejoinBtn = createActionButton("Rejoin", "Rejoin Server")
    rejoinBtn.MouseButton1Click:Connect(function()
        sendNotification("MM2 Menu", "Rejoining server...")
        task.wait(0.5)
        local ok = pcall(function() TeleportService:Teleport(game.PlaceId, player) end)
        if not ok then pcall(function() TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, player) end) end
    end)
    local hopBtn = createActionButton("ServerHop", "Server Hop")
    hopBtn.MouseButton1Click:Connect(function()
        if S.hopping then return end
        S.hopping = true
        sendNotification("MM2 Menu", "Searching servers...", SOUNDS.notify)
        task.spawn(function()
            local ok = pcall(function()
                local url = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Desc&limit=100"
                local data = HttpService:JSONDecode(game:HttpGet(url))
                if not data or not data.data then sendNotification("MM2 Menu", "No servers available", SOUNDS.alert) return end
                local cands = {}
                for _, s in ipairs(data.data) do
                    if s.id ~= game.JobId and s.playing < s.maxPlayers then table.insert(cands, s) end
                end
                if #cands == 0 then sendNotification("MM2 Menu", "All servers full", SOUNDS.alert) return end
                local pick = cands[math.random(1, #cands)]
                sendNotification("MM2 Menu", "Hopping to " .. pick.playing .. "/" .. pick.maxPlayers .. " server...", SOUNDS.notify)
                task.wait(0.5)
                TeleportService:TeleportToPlaceInstance(game.PlaceId, pick.id, player)
            end)
            if not ok then sendNotification("MM2 Menu", "Server hop failed", SOUNDS.alert) end
            S.hopping = false
        end)
    end)
end

-- ═══════════════════════════════════════════════════════════
-- CONFIG
-- ═══════════════════════════════════════════════════════════
snapshotFullSettings = function()
    return {
        antiAfkEnabled = S.antiAfkEnabled, antiVoidEnabled = S.antiVoidEnabled, antiFlingEnabled = S.antiFlingEnabled,
        esp = {Innocent = S.espEnabled.Innocent, Murderer = S.espEnabled.Murderer, Sheriff = S.espEnabled.Sheriff, Hero = S.espEnabled.Hero},
        gunESPEnabled = S.gunESPEnabled, noclip = S.noclip, autoNotifyRoles = S.autoNotifyRoles,
        autoKillAll = S.autoKillAll, killerAlarmOn = S.killerAlarmOn, crosshairOn = S.crosshairOn,
        gunDropAlert = S.gunDropAlert, notifyRoundStart = S.notifyRoundStart, notifyRoundEnd = S.notifyRoundEnd,
        playerJoinLeaveNotify = S.playerJoinLeaveNotify, killSoundOn = S.killSoundOn,
        dirIndicatorOn = S.dirIndicatorOn, autoHideInRound = S.autoHideInRound,
        reAnnounceEnabled = S.reAnnounceEnabled, heroChangeNotify = S.heroChangeNotify,
    }
end

applyFullSnapshot = function(snap)
    if not snap then return end
    if snap.antiAfkEnabled ~= S.antiAfkEnabled then
        S.antiAfkEnabled = snap.antiAfkEnabled
        if S.antiAfkEnabled then
            if U.afkBtn then setOn(U.afkBtn, U.afkInd) end
            if not S.antiAfkConn then
                S.antiAfkConn = player.Idled:Connect(function()
                    local VU = game:GetService("VirtualUser")
                    VU:CaptureController()
                    VU:ClickButton2(Vector2.new())
                end)
            end
        else
            if U.afkBtn then setOff(U.afkBtn, U.afkInd) end
            if S.antiAfkConn then S.antiAfkConn:Disconnect() S.antiAfkConn = nil end
        end
    end
    S.antiVoidEnabled = snap.antiVoidEnabled
    if U.avBtn then if S.antiVoidEnabled then setOn(U.avBtn, U.avInd) else setOff(U.avBtn, U.avInd) end end
    S.antiFlingEnabled = snap.antiFlingEnabled
    if U.afBtn then if S.antiFlingEnabled then setOn(U.afBtn, U.afInd) else setOff(U.afBtn, U.afInd) end end
    for role, state in pairs(snap.esp or {}) do
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
    S.gunESPEnabled = snap.gunESPEnabled
    if U.gunBtn then
        if S.gunESPEnabled then
            U.gunBtn.BackgroundColor3 = GUN_COLOR:Lerp(Color3.fromRGB(20, 20, 25), 0.65)
            U.gunInd.BackgroundColor3 = GUN_COLOR
        else
            setOff(U.gunBtn, U.gunInd)
            for g, hl in pairs(S.gunHighlights) do if hl then pcall(function() hl:Destroy() end) end end
            S.gunHighlights = {}
        end
    end
    S.noclip = snap.noclip
    if U.noclipBtn then
        if S.noclip then
            setOn(U.noclipBtn, U.noclipInd)
            S.originalCollision = {}
            if player.Character then
                for _, o in ipairs(player.Character:GetDescendants()) do
                    if o:IsA("BasePart") then S.originalCollision[o] = o.CanCollide o.CanCollide = false end
                end
            end
        else
            setOff(U.noclipBtn, U.noclipInd)
            for o, v in pairs(S.originalCollision) do if o and o.Parent then o.CanCollide = v end end
            S.originalCollision = {}
        end
    end
    S.autoNotifyRoles = snap.autoNotifyRoles
    if U.autoNotBtn then if S.autoNotifyRoles then setOn(U.autoNotBtn, U.autoNotInd) else setOff(U.autoNotBtn, U.autoNotInd) end end
    S.autoKillAll = snap.autoKillAll
    if U.autoKillBtn then if S.autoKillAll then setOn(U.autoKillBtn, U.autoKillInd) else setOff(U.autoKillBtn, U.autoKillInd) end end
    S.killerAlarmOn = snap.killerAlarmOn
    if U.killerAlarmBtn then
        if S.killerAlarmOn then setOn(U.killerAlarmBtn, U.killerAlarmInd) S.lastAlarmDist = math.huge S.lastAlarmTime = 0
        else setOff(U.killerAlarmBtn, U.killerAlarmInd) S.lastAlarmDist = math.huge end
    end
    S.crosshairOn = snap.crosshairOn
    if U.crosshairBtn then
        if S.crosshairOn then
            setOn(U.crosshairBtn, U.crosshairInd)
            if S.crosshairGui then S.crosshairGui.Enabled = true end
        else
            setOff(U.crosshairBtn, U.crosshairInd)
            if S.crosshairGui then S.crosshairGui.Enabled = false end
        end
    end
    S.gunDropAlert = snap.gunDropAlert
    if U.gunAlertBtn then if S.gunDropAlert then setOn(U.gunAlertBtn, U.gunAlertInd) else setOff(U.gunAlertBtn, U.gunAlertInd) end end
    S.notifyRoundStart = snap.notifyRoundStart
    if U.rStartBtn then if S.notifyRoundStart then setOn(U.rStartBtn, U.rStartInd) else setOff(U.rStartBtn, U.rStartInd) end end
    S.notifyRoundEnd = snap.notifyRoundEnd
    if U.rEndBtn then if S.notifyRoundEnd then setOn(U.rEndBtn, U.rEndInd) else setOff(U.rEndBtn, U.rEndInd) end end
    S.playerJoinLeaveNotify = snap.playerJoinLeaveNotify
    if U.plBtn then if S.playerJoinLeaveNotify then setOn(U.plBtn, U.plInd) else setOff(U.plBtn, U.plInd) end end
    S.killSoundOn = snap.killSoundOn
    if U.killSoundBtn then if S.killSoundOn then setOn(U.killSoundBtn, U.killSoundInd) else setOff(U.killSoundBtn, U.killSoundInd) end end
    S.dirIndicatorOn = snap.dirIndicatorOn
    if U.dirBtn then
        if S.dirIndicatorOn then setOn(U.dirBtn, U.dirInd) else setOff(U.dirBtn, U.dirInd) end
        if not S.dirIndicatorOn and DirUI and DirUI.gui then DirUI.gui.Enabled = false end
    end
    S.autoHideInRound = snap.autoHideInRound
    if U.autoHideBtn then if S.autoHideInRound then setOn(U.autoHideBtn, U.autoHideInd) else setOff(U.autoHideBtn, U.autoHideInd) end end
    S.reAnnounceEnabled = snap.reAnnounceEnabled
    if U.reAnnBtn then if S.reAnnounceEnabled then setOn(U.reAnnBtn, U.reAnnInd) else setOff(U.reAnnBtn, U.reAnnInd) end end
    S.heroChangeNotify = snap.heroChangeNotify
    if U.heroChangeBtn then if S.heroChangeNotify then setOn(U.heroChangeBtn, U.heroChangeInd) else setOff(U.heroChangeBtn, U.heroChangeInd) end end
end

local function populateConfig()
    currentParent = U.tabFrames.Config

    local allNotifyBtn = createActionButton("EnableAllNotify", "Enable All Notifications")
    allNotifyBtn.BackgroundColor3 = Color3.fromRGB(40, 60, 85)
    allNotifyBtn.MouseButton1Click:Connect(function()
        if not S.notifyRoundStart then S.notifyRoundStart = true if U.rStartBtn then setOn(U.rStartBtn, U.rStartInd) end end
        if not S.notifyRoundEnd then S.notifyRoundEnd = true if U.rEndBtn then setOn(U.rEndBtn, U.rEndInd) end end
        if not S.playerJoinLeaveNotify then S.playerJoinLeaveNotify = true if U.plBtn then setOn(U.plBtn, U.plInd) end end
        if not S.gunDropAlert then S.gunDropAlert = true if U.gunAlertBtn then setOn(U.gunAlertBtn, U.gunAlertInd) end end
        if not S.autoNotifyRoles then S.autoNotifyRoles = true if U.autoNotBtn then setOn(U.autoNotBtn, U.autoNotInd) end end
        sendNotification("MM2 Menu", "All notifications enabled")
    end)

    createSectionTitle("SAVED CONFIGS (3 slots)")

    local function buildSlot(idx)
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, 0, 0, mn(32))
        row.BackgroundColor3 = Color3.fromRGB(34, 36, 43)
        row.BorderSizePixel = 0
        row.LayoutOrder = getLayoutOrder()
        row.Parent = currentParent
        do local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 8) c.Parent = row end
        local nameBox = Instance.new("TextBox")
        nameBox.Size = UDim2.new(0.4, -mn(4), 1, 0)
        nameBox.Position = mpos(4, 0)
        nameBox.BackgroundTransparency = 1
        nameBox.Text = "Slot " .. idx
        nameBox.TextColor3 = Color3.fromRGB(230, 230, 235)
        nameBox.TextSize = mn(11)
        nameBox.Font = Enum.Font.GothamSemibold
        nameBox.ClearTextOnFocus = false
        nameBox.TextXAlignment = Enum.TextXAlignment.Left
        nameBox.Parent = row
        do local p = Instance.new("UIPadding") p.PaddingLeft = UDim.new(0, 6) p.Parent = nameBox end
        local saveBtn = Instance.new("TextButton")
        saveBtn.Size = msz(50, 24)
        saveBtn.Position = UDim2.new(0.4, mn(2), 0.5, -mn(12))
        saveBtn.BackgroundColor3 = Color3.fromRGB(50, 80, 50)
        saveBtn.Text = "Save"
        saveBtn.TextColor3 = Color3.fromRGB(220, 240, 220)
        saveBtn.TextSize = mn(11)
        saveBtn.Font = Enum.Font.GothamBold
        saveBtn.BorderSizePixel = 0
        saveBtn.AutoButtonColor = false
        saveBtn.Parent = row
        do local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 6) c.Parent = saveBtn end
        local loadBtn = Instance.new("TextButton")
        loadBtn.Size = msz(50, 24)
        loadBtn.Position = UDim2.new(0.4, mn(56), 0.5, -mn(12))
        loadBtn.BackgroundColor3 = Color3.fromRGB(50, 70, 110)
        loadBtn.Text = "Load"
        loadBtn.TextColor3 = Color3.fromRGB(220, 230, 255)
        loadBtn.TextSize = mn(11)
        loadBtn.Font = Enum.Font.GothamBold
        loadBtn.BorderSizePixel = 0
        loadBtn.AutoButtonColor = false
        loadBtn.Parent = row
        do local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 6) c.Parent = loadBtn end
        local delBtn = Instance.new("TextButton")
        delBtn.Size = msz(30, 24)
        delBtn.Position = UDim2.new(1, -mn(34), 0.5, -mn(12))
        delBtn.BackgroundColor3 = Color3.fromRGB(90, 40, 40)
        delBtn.Text = "X"
        delBtn.TextColor3 = Color3.fromRGB(255, 210, 210)
        delBtn.TextSize = mn(12)
        delBtn.Font = Enum.Font.GothamBold
        delBtn.BorderSizePixel = 0
        delBtn.AutoButtonColor = false
        delBtn.Parent = row
        do local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 6) c.Parent = delBtn end
        saveBtn.MouseButton1Click:Connect(function()
            S.savedConfigs[idx] = {name = nameBox.Text, data = snapshotFullSettings()}
            showToast("Saved: " .. nameBox.Text)
        end)
        loadBtn.MouseButton1Click:Connect(function()
            local slot = S.savedConfigs[idx]
            if not slot or not slot.data then showToast("Slot " .. idx .. " is empty") return end
            applyFullSnapshot(slot.data)
            showToast("Loaded: " .. (slot.name or ("Slot " .. idx)))
        end)
        delBtn.MouseButton1Click:Connect(function()
            S.savedConfigs[idx] = nil
            showToast("Cleared slot " .. idx)
        end)
    end

    for i = 1, 3 do buildSlot(i) end

    createSectionTitle("PRESET INFO")
    local info = Instance.new("TextLabel")
    info.Size = UDim2.new(1, 0, 0, mn(80))
    info.BackgroundTransparency = 1
    info.Text = "PVP Ready (Home) turns on a curated set.\nRestore Before PVP reverts to prior settings.\nSaved Configs store your current toggles\nin one of 3 slots."
    info.TextColor3 = Color3.fromRGB(180, 182, 190)
    info.TextSize = mn(11)
    info.Font = Enum.Font.Gotham
    info.TextXAlignment = Enum.TextXAlignment.Left
    info.TextYAlignment = Enum.TextYAlignment.Top
    info.LayoutOrder = getLayoutOrder()
    info.Parent = currentParent
end

pcall(populateHome)
pcall(populateMovement)
pcall(populateESP)
pcall(populateNotifier)
pcall(populateMurderer)
pcall(populateSheriff)
pcall(populateTeleport)
pcall(populateKeybinds)
pcall(populateSettings)
pcall(populateUtility)
pcall(populateConfig)

-- ═══════════════════════════════════════════════════════════
-- MODALS
-- ═══════════════════════════════════════════════════════════
U.whatsNewOverlay = Instance.new("TextButton")
U.whatsNewOverlay.Size = UDim2.new(1, 0, 1, 0)
U.whatsNewOverlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
U.whatsNewOverlay.BackgroundTransparency = 0.5
U.whatsNewOverlay.Text = ""
U.whatsNewOverlay.AutoButtonColor = false
U.whatsNewOverlay.Visible = false
U.whatsNewOverlay.ZIndex = 100
U.whatsNewOverlay.Parent = U.gui

local wnPanel = Instance.new("Frame")
wnPanel.Size = msz(360, 340)
wnPanel.Position = UDim2.new(0.5, -mn(180), 0.5, -mn(170))
wnPanel.BackgroundColor3 = Color3.fromRGB(22, 23, 28)
wnPanel.BorderSizePixel = 0
wnPanel.Active = true
wnPanel.ZIndex = 101
wnPanel.Parent = U.whatsNewOverlay
do
    local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 12) c.Parent = wnPanel
    local st = Instance.new("UIStroke") st.Color = Color3.fromRGB(70, 72, 82) st.Thickness = 1 st.Parent = wnPanel
end
local wnHdr = Instance.new("Frame")
wnHdr.Size = UDim2.new(1, 0, 0, mn(36))
wnHdr.BackgroundColor3 = Color3.fromRGB(29, 30, 37)
wnHdr.BorderSizePixel = 0
wnHdr.ZIndex = 102
wnHdr.Parent = wnPanel
do local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 12) c.Parent = wnHdr end
local wnTitle = Instance.new("TextLabel")
wnTitle.Size = UDim2.new(1, -mn(48), 1, 0)
wnTitle.Position = mpos(12, 0)
wnTitle.BackgroundTransparency = 1
wnTitle.Text = "WHAT'S NEW"
wnTitle.TextColor3 = Color3.fromRGB(245, 245, 250)
wnTitle.TextSize = mn(13)
wnTitle.Font = Enum.Font.GothamBold
wnTitle.TextXAlignment = Enum.TextXAlignment.Left
wnTitle.ZIndex = 103
wnTitle.Parent = wnHdr
local wnClose = Instance.new("TextButton")
wnClose.Size = msz(26, 26)
wnClose.Position = UDim2.new(1, -mn(32), 0.5, -mn(13))
wnClose.BackgroundColor3 = Color3.fromRGB(42, 44, 52)
wnClose.Text = "X"
wnClose.TextSize = mn(14)
wnClose.TextColor3 = Color3.fromRGB(255, 200, 200)
wnClose.Font = Enum.Font.GothamBold
wnClose.BorderSizePixel = 0
wnClose.AutoButtonColor = false
wnClose.ZIndex = 103
wnClose.Parent = wnHdr
do local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 6) c.Parent = wnClose end
local wnScroll = Instance.new("ScrollingFrame")
wnScroll.Size = UDim2.new(1, -mn(16), 1, -mn(48))
wnScroll.Position = mpos(8, 42)
wnScroll.BackgroundTransparency = 1
wnScroll.BorderSizePixel = 0
wnScroll.ScrollBarThickness = 4
wnScroll.ScrollBarImageColor3 = Color3.fromRGB(75, 77, 85)
wnScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
wnScroll.ScrollingDirection = Enum.ScrollingDirection.Y
wnScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
wnScroll.ZIndex = 102
wnScroll.Parent = wnPanel
do local l = Instance.new("UIListLayout") l.Padding = UDim.new(0, 4) l.SortOrder = Enum.SortOrder.LayoutOrder l.Parent = wnScroll end
do
    local hdr = Instance.new("Frame")
    hdr.Size = UDim2.new(1, 0, 0, mn(20))
    hdr.BackgroundColor3 = Color3.fromRGB(35, 40, 52)
    hdr.BorderSizePixel = 0
    hdr.LayoutOrder = 1
    hdr.Parent = wnScroll
    do local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 5) c.Parent = hdr end
    local vl = Instance.new("TextLabel")
    vl.Size = UDim2.new(1, -mn(10), 1, 0)
    vl.Position = mpos(6, 0)
    vl.BackgroundTransparency = 1
    vl.Text = CHANGELOG.version .. "   -   " .. CHANGELOG.date
    vl.TextColor3 = Color3.fromRGB(90, 200, 255)
    vl.TextSize = mn(12)
    vl.Font = Enum.Font.GothamBold
    vl.TextXAlignment = Enum.TextXAlignment.Left
    vl.Parent = hdr
    for i, ch in ipairs(CHANGELOG.changes) do
        local cl = Instance.new("TextLabel")
        cl.Size = UDim2.new(1, -mn(8), 0, 0)
        cl.AutomaticSize = Enum.AutomaticSize.Y
        cl.BackgroundTransparency = 1
        cl.Text = "  - " .. ch
        cl.TextColor3 = Color3.fromRGB(200, 202, 210)
        cl.TextSize = mn(11)
        cl.Font = Enum.Font.Gotham
        cl.TextXAlignment = Enum.TextXAlignment.Left
        cl.TextWrapped = true
        cl.TextYAlignment = Enum.TextYAlignment.Top
        cl.LayoutOrder = i + 1
        cl.Parent = wnScroll
    end
end
openWhatsNew = function() U.whatsNewOverlay.Visible = true end
wnClose.MouseButton1Click:Connect(function() U.whatsNewOverlay.Visible = false end)
U.whatsNewOverlay.MouseButton1Click:Connect(function() U.whatsNewOverlay.Visible = false end)

-- Close confirm
U.closeConfirm = Instance.new("TextButton")
U.closeConfirm.Size = UDim2.new(1, 0, 1, 0)
U.closeConfirm.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
U.closeConfirm.BackgroundTransparency = 0.5
U.closeConfirm.Text = ""
U.closeConfirm.AutoButtonColor = false
U.closeConfirm.Visible = false
U.closeConfirm.ZIndex = 120
U.closeConfirm.Parent = U.gui
local ccPanel = Instance.new("Frame")
ccPanel.Size = msz(280, 130)
ccPanel.Position = UDim2.new(0.5, -mn(140), 0.5, -mn(65))
ccPanel.BackgroundColor3 = Color3.fromRGB(22, 23, 28)
ccPanel.BorderSizePixel = 0
ccPanel.ZIndex = 121
ccPanel.Parent = U.closeConfirm
do
    local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 12) c.Parent = ccPanel
    local st = Instance.new("UIStroke") st.Color = Color3.fromRGB(80, 82, 92) st.Thickness = 1 st.Parent = ccPanel
end
local ccTitle = Instance.new("TextLabel")
ccTitle.Size = UDim2.new(1, 0, 0, mn(30))
ccTitle.Position = mpos(0, 10)
ccTitle.BackgroundTransparency = 1
ccTitle.Text = "Close Script?"
ccTitle.TextColor3 = Color3.fromRGB(245, 245, 250)
ccTitle.TextSize = mn(14)
ccTitle.Font = Enum.Font.GothamBold
ccTitle.ZIndex = 122
ccTitle.Parent = ccPanel
local ccBody = Instance.new("TextLabel")
ccBody.Size = UDim2.new(1, -mn(20), 0, mn(30))
ccBody.Position = mpos(10, 42)
ccBody.BackgroundTransparency = 1
ccBody.Text = "Are you sure? All active features will be turned off."
ccBody.TextColor3 = Color3.fromRGB(180, 182, 190)
ccBody.TextSize = mn(11)
ccBody.Font = Enum.Font.Gotham
ccBody.TextWrapped = true
ccBody.ZIndex = 122
ccBody.Parent = ccPanel
local ccYes = Instance.new("TextButton")
ccYes.Size = msz(120, 32)
ccYes.Position = mpos(14, 86)
ccYes.BackgroundColor3 = Color3.fromRGB(120, 35, 35)
ccYes.Text = "Close"
ccYes.TextColor3 = Color3.fromRGB(255, 210, 210)
ccYes.TextSize = mn(12)
ccYes.Font = Enum.Font.GothamBold
ccYes.BorderSizePixel = 0
ccYes.AutoButtonColor = false
ccYes.ZIndex = 122
ccYes.Parent = ccPanel
do local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 8) c.Parent = ccYes end
local ccNo = Instance.new("TextButton")
ccNo.Size = msz(120, 32)
ccNo.Position = UDim2.new(1, -mn(134), 0, mn(86))
ccNo.BackgroundColor3 = Color3.fromRGB(50, 55, 65)
ccNo.Text = "Cancel"
ccNo.TextColor3 = Color3.fromRGB(230, 230, 235)
ccNo.TextSize = mn(12)
ccNo.Font = Enum.Font.GothamBold
ccNo.BorderSizePixel = 0
ccNo.AutoButtonColor = false
ccNo.ZIndex = 122
ccNo.Parent = ccPanel
do local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 8) c.Parent = ccNo end
showCloseConfirm = function() U.closeConfirm.Visible = true end
U.closeConfirm.MouseButton1Click:Connect(function() U.closeConfirm.Visible = false end)
ccNo.MouseButton1Click:Connect(function() U.closeConfirm.Visible = false end)

-- Tutorial
TutorialUI = {}
TutorialUI.gui = Instance.new("ScreenGui")
TutorialUI.gui.Name = "MM2Tutorial"
TutorialUI.gui.ResetOnSpawn = false
TutorialUI.gui.DisplayOrder = 400
TutorialUI.gui.IgnoreGuiInset = true
TutorialUI.gui.Enabled = false
TutorialUI.gui.Parent = playerGui
local tutOverlay = Instance.new("Frame")
tutOverlay.Size = UDim2.new(1, 0, 1, 0)
tutOverlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
tutOverlay.BackgroundTransparency = 0.4
tutOverlay.BorderSizePixel = 0
tutOverlay.Parent = TutorialUI.gui
local tutPanel = Instance.new("Frame")
tutPanel.Size = msz(400, 260)
tutPanel.Position = UDim2.new(0.5, -mn(200), 0.5, -mn(130))
tutPanel.BackgroundColor3 = Color3.fromRGB(22, 23, 28)
tutPanel.BorderSizePixel = 0
tutPanel.Parent = tutOverlay
do
    local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 12) c.Parent = tutPanel
    local st = Instance.new("UIStroke") st.Color = Color3.fromRGB(80, 82, 92) st.Thickness = 1 st.Parent = tutPanel
end
local tutTitle = Instance.new("TextLabel")
tutTitle.Size = UDim2.new(1, -mn(20), 0, mn(30))
tutTitle.Position = mpos(10, 10)
tutTitle.BackgroundTransparency = 1
tutTitle.TextColor3 = Color3.fromRGB(245, 245, 250)
tutTitle.TextSize = mn(15)
tutTitle.Font = Enum.Font.GothamBold
tutTitle.TextXAlignment = Enum.TextXAlignment.Left
tutTitle.Parent = tutPanel
local tutBody = Instance.new("TextLabel")
tutBody.Size = UDim2.new(1, -mn(20), 0, mn(140))
tutBody.Position = mpos(10, 48)
tutBody.BackgroundTransparency = 1
tutBody.TextColor3 = Color3.fromRGB(200, 202, 210)
tutBody.TextSize = mn(12)
tutBody.Font = Enum.Font.Gotham
tutBody.TextXAlignment = Enum.TextXAlignment.Left
tutBody.TextYAlignment = Enum.TextYAlignment.Top
tutBody.TextWrapped = true
tutBody.Parent = tutPanel
local tutStep = Instance.new("TextLabel")
tutStep.Size = UDim2.new(1, -mn(20), 0, mn(16))
tutStep.Position = mpos(10, 200)
tutStep.BackgroundTransparency = 1
tutStep.TextColor3 = Color3.fromRGB(140, 142, 150)
tutStep.TextSize = mn(10)
tutStep.Font = Enum.Font.Gotham
tutStep.TextXAlignment = Enum.TextXAlignment.Left
tutStep.Parent = tutPanel
local tutSkip = Instance.new("TextButton")
tutSkip.Size = msz(90, 30)
tutSkip.Position = mpos(10, 220)
tutSkip.BackgroundColor3 = Color3.fromRGB(50, 55, 65)
tutSkip.Text = "Skip"
tutSkip.TextColor3 = Color3.fromRGB(200, 200, 210)
tutSkip.TextSize = mn(12)
tutSkip.Font = Enum.Font.GothamBold
tutSkip.BorderSizePixel = 0
tutSkip.AutoButtonColor = false
tutSkip.Parent = tutPanel
do local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 8) c.Parent = tutSkip end
local tutNext = Instance.new("TextButton")
tutNext.Size = msz(120, 30)
tutNext.Position = UDim2.new(1, -mn(130), 0, mn(220))
tutNext.BackgroundColor3 = Color3.fromRGB(60, 90, 140)
tutNext.Text = "Next"
tutNext.TextColor3 = Color3.fromRGB(230, 235, 255)
tutNext.TextSize = mn(12)
tutNext.Font = Enum.Font.GothamBold
tutNext.BorderSizePixel = 0
tutNext.AutoButtonColor = false
tutNext.Parent = tutPanel
do local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 8) c.Parent = tutNext end
local TUTORIAL_PAGES = {
    {title = "Welcome", body = "Every tab on the left groups related features.\n\nThe top search box filters the CURRENT tab only. The Home tab has a separate search that searches EVERY tab.\n\nRight Shift minimizes/restores the menu."},
    {title = "Home Tab", body = "Home is your dashboard:\n\n- Live Status: your role, murderer, sheriff, hero, distance.\n- Quick Actions: PVP Ready, Restore, Turn Off All, Panic.\n- Session Stats.\n- FPS/Ping overlay toggle.\n- Cross-tab search.\n- Notification History (click to copy)."},
    {title = "PVP Ready & Restore", body = "PVP Ready turns on a curated set of features at once.\n\nRestore Before PVP reverts everything back to how it was before you clicked PVP Ready."},
    {title = "Keybinds & Panic", body = "Open the Keybinds tab to set hotkeys.\n\nThe Panic keybind (default End) silently turns everything off and minimizes the menu."},
    {title = "Saved Configs", body = "The Config tab lets you save your current toggle state into one of 3 slots."},
}
local tutIdx = 1
local function renderTut()
    local p = TUTORIAL_PAGES[tutIdx]
    if not p then return end
    tutTitle.Text = p.title
    tutBody.Text = p.body
    tutStep.Text = "Step " .. tutIdx .. " / " .. #TUTORIAL_PAGES
    tutNext.Text = tutIdx == #TUTORIAL_PAGES and "Finish" or "Next"
end
showTutorial = function()
    tutIdx = 1
    renderTut()
    TutorialUI.gui.Enabled = true
end
tutSkip.MouseButton1Click:Connect(function() TutorialUI.gui.Enabled = false end)
tutNext.MouseButton1Click:Connect(function()
    if tutIdx >= #TUTORIAL_PAGES then TutorialUI.gui.Enabled = false
    else tutIdx = tutIdx + 1 renderTut() end
end)

-- ═══════════════════════════════════════════════════════════
-- SUPPORT SYSTEMS
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

DirUI = {}
DirUI.gui = Instance.new("ScreenGui")
DirUI.gui.Name = "MM2DirArrow"
DirUI.gui.ResetOnSpawn = false
DirUI.gui.DisplayOrder = 210
DirUI.gui.IgnoreGuiInset = true
DirUI.gui.Enabled = false
DirUI.gui.Parent = playerGui
DirUI.frame = Instance.new("Frame")
DirUI.frame.Size = msz(30, 30)
DirUI.frame.BackgroundTransparency = 1
DirUI.frame.Visible = false
DirUI.frame.Parent = DirUI.gui
DirUI.arrow = Instance.new("TextLabel")
DirUI.arrow.Size = UDim2.new(1, 0, 1, 0)
DirUI.arrow.BackgroundTransparency = 1
DirUI.arrow.Text = "^"
DirUI.arrow.TextColor3 = ROLE_COLORS.Murderer
DirUI.arrow.TextSize = mn(22)
DirUI.arrow.Font = Enum.Font.GothamBold
DirUI.arrow.Parent = DirUI.frame
DirUI.distLbl = Instance.new("TextLabel")
DirUI.distLbl.Size = msz(50, 14)
DirUI.distLbl.Position = UDim2.new(0.5, -mn(25), 1, 0)
DirUI.distLbl.BackgroundTransparency = 1
DirUI.distLbl.Text = ""
DirUI.distLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
DirUI.distLbl.TextStrokeTransparency = 0
DirUI.distLbl.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
DirUI.distLbl.TextSize = mn(11)
DirUI.distLbl.Font = Enum.Font.GothamBold
DirUI.distLbl.Parent = DirUI.frame

PerfUI = {}
PerfUI.gui = Instance.new("ScreenGui")
PerfUI.gui.Name = "MM2Perf"
PerfUI.gui.ResetOnSpawn = false
PerfUI.gui.DisplayOrder = 90
PerfUI.gui.IgnoreGuiInset = true
PerfUI.gui.Enabled = false
PerfUI.gui.Parent = playerGui
PerfUI.frame = Instance.new("Frame")
PerfUI.frame.Size = msz(130, 34)
PerfUI.frame.Position = mpos(10, 10)
PerfUI.frame.BackgroundColor3 = Color3.fromRGB(18, 19, 24)
PerfUI.frame.BackgroundTransparency = 0.3
PerfUI.frame.BorderSizePixel = 0
PerfUI.frame.Parent = PerfUI.gui
do local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 6) c.Parent = PerfUI.frame end
PerfUI.label = Instance.new("TextLabel")
PerfUI.label.Size = UDim2.new(1, 0, 1, 0)
PerfUI.label.BackgroundTransparency = 1
PerfUI.label.Text = "FPS: -- | Ping: --"
PerfUI.label.TextColor3 = Color3.fromRGB(220, 220, 230)
PerfUI.label.TextSize = mn(11)
PerfUI.label.Font = Enum.Font.GothamBold
PerfUI.label.Parent = PerfUI.frame

-- ═══════════════════════════════════════════════════════════
-- ESP / TRAILS / GUN
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
    if not t or not t.Character then return false end
    local h = t.Character:FindFirstChildOfClass("Humanoid")
    if not h or h.Health <= 0 then return false end
    if t ~= player and isPlayerInSpawn(t) then return false end
    return true
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

local function refreshSpawnCache()
    local nc = {}
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("SpawnLocation") or (obj:IsA("BasePart") and obj.Name == "SpawnPoint") then
            table.insert(nc, obj)
        end
    end
    cachedSpawns = nc
end

refreshSpawnCache()
task.spawn(function()
    while U.gui.Parent do pcall(refreshSpawnCache) task.wait(10) end
end)

local function roundEvents()
    local wasMurderer = S.lastKnownMurderer
    if MurdererName and not wasMurderer then
        S.stats.rounds = S.stats.rounds + 1
        S.statsCountedMurderer = false
        S.statsCountedSheriff = false
        if S.autoHideInRound and minimizeMenu then pcall(minimizeMenu) end
    end
    if not MurdererName and wasMurderer then
        if S.autoHideInRound and not S.menuVisible and showMenu then pcall(showMenu) end
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
        MurdererName = nM; noMurdererSince = nil
    elseif MurdererName and not validHolder(MurdererName) then
        MurdererName = nil; S.lastChatSentMurderer = nil; S.roundActive = false
        if not noMurdererSince then noMurdererSince = tick() end
    end
    if nS and validHolder(nS) then SheriffName = nS
    elseif SheriffName and not validHolder(SheriffName) then
        SheriffName = nil; S.lastChatSentSheriff = nil; S.roundActiveSheriff = false
    end
    if nH and validHolder(nH) then
        if S.heroChangeNotify and S.lastHero and S.lastHero ~= nH then
            sendNotification("New Hero", "Hero changed: " .. tostring(nH))
        end
        HeroName = nH
    elseif HeroName and not validHolder(HeroName) then HeroName = nil end
    if HeroName then S.lastHero = HeroName end
    if MurdererName == nil and noMurdererSince and (tick() - noMurdererSince) >= ROUND_END_DEBOUNCE then
        MurdererName = nil SheriffName = nil HeroName = nil
        lastNotifiedMurderer = nil lastNotifiedSheriff = nil lastNotifiedHero = nil
        S.lastChatSentMurderer = nil S.lastChatSentSheriff = nil
        S.roundActive = false S.roundActiveSheriff = false
        S.pendingNotify = false S.selfNotifyMurderer = false S.selfNotifySheriff = false
        S.lastHero = nil noMurdererSince = nil
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
    if S.reAnnounceEnabled and MurdererName then
        local now = tick()
        if now - S.lastReAnnounceTime >= (S.reAnnounceInterval or 30) then
            S.lastReAnnounceTime = now
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
    else emit.Color = ColorSequence.new(color) end
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
            if isM and S.killerTrailOn and isAlive(t) then attachTrail(t, ROLE_COLORS.Murderer)
            elseif isS and S.sheriffTrailOn and isAlive(t) then attachTrail(t, ROLE_COLORS.Sheriff)
            elseif isH and S.heroTrailOn and isAlive(t) then attachTrail(t, ROLE_COLORS.Hero)
            else clearTrail(t) end
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
        if MurdererName == player.Name then S.stats.kills = S.stats.kills + 1 end
        if not S.killSoundOn then return end
        if MurdererName ~= player.Name then return end
        playSound(SOUNDS.success, 1.5, true)
    end)
end

for _, t in ipairs(Players:GetPlayers()) do
    if t ~= player then
        t.CharacterAdded:Connect(function()
            task.wait(0.2)
            mkHL(t) updateHL() hookKillSound(t)
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
        mkHL(t) updateHL() hookKillSound(t)
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
        S.playerDistBillboards[t]:Destroy()
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
            S.roundActive = false S.lastChatSentMurderer = nil
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
            S.roundActiveSheriff = false S.lastChatSentSheriff = nil
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

killAllPlayers = function()
    local c = player.Character
    if not c then return end
    local mr = c:FindFirstChild("HumanoidRootPart")
    if not mr then return end
    local k = c:FindFirstChild("Knife")
    if not k then
        local bp = player:FindFirstChild("Backpack")
        if bp then k = bp:FindFirstChild("Knife") if k then k.Parent = c end end
    end
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
    for pass = 1, 3 do
        for _, tr in ipairs(getTargets()) do
            if tr and tr.Parent then
                mr.CFrame = tr.CFrame * CFrame.new(0, 0, 1.5)
                task.wait(0.03)
                pcall(function() k:Activate() end)
            end
        end
        task.wait(0.15)
    end
end

attackTarget = function(t)
    if not t or t == player or not t.Character then return end
    if isPlayerInSpawn(t) then return end
    local tr = t.Character:FindFirstChild("HumanoidRootPart")
    local mr = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if tr and mr then
        local c = player.Character
        local k = c:FindFirstChild("Knife")
        if not k then
            local bp = player:FindFirstChild("Backpack")
            if bp then k = bp:FindFirstChild("Knife") if k then k.Parent = c end end
        end
        if k then
            mr.CFrame = tr.CFrame * CFrame.new(0, 0, 1.5)
            task.wait(0.05)
            pcall(function() k:Activate() end)
        end
    end
end

-- ═══════════════════════════════════════════════════════════
-- DRAG / RESIZE (via dedicated drag handle button)
-- ═══════════════════════════════════════════════════════════
local dragStart, dragStartFramePos
U.dragHandle.MouseButton1Down:Connect(function()
    if S.guiLocked then return end
    dragStart = UserInputService:GetMouseLocation()
    dragStartFramePos = U.frame.Position
    S.dragging = true
end)
U.dragHandle.InputBegan:Connect(function(i)
    if S.guiLocked then return end
    if i.UserInputType == Enum.UserInputType.Touch then
        dragStart = i.Position
        dragStartFramePos = U.frame.Position
        S.dragging = true
    end
end)
UserInputService.InputChanged:Connect(function(i)
    if not S.dragging or S.guiLocked then return end
    local pos
    if i.UserInputType == Enum.UserInputType.MouseMovement then
        pos = UserInputService:GetMouseLocation()
    elseif i.UserInputType == Enum.UserInputType.Touch then
        pos = i.Position
    else return end
    local d = pos - dragStart
    U.frame.Position = UDim2.new(
        dragStartFramePos.X.Scale, dragStartFramePos.X.Offset + d.X,
        dragStartFramePos.Y.Scale, dragStartFramePos.Y.Offset + d.Y
    )
end)
UserInputService.InputEnded:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
        S.dragging = false
    end
end)

local resizeStartPos, resizeStartSize
U.resize.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
        S.resizing = true
        resizeStartPos = i.Position
        resizeStartSize = U.frame.AbsoluteSize
    end
end)
UserInputService.InputChanged:Connect(function(i)
    if not S.resizing then return end
    if i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch then
        local d = i.Position - resizeStartPos
        U.frame.Size = UDim2.fromOffset(math.max(mn(380), resizeStartSize.X + d.X), math.max(mn(280), resizeStartSize.Y + d.Y))
    end
end)

local reopenDragStart, reopenDragStartPos
U.reopen.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
        S.reopenDragging = true
        reopenDragStart = i.Position
        reopenDragStartPos = U.reopen.Position
        S.reopenDragDist = 0
    end
end)
UserInputService.InputChanged:Connect(function(i)
    if not S.reopenDragging then return end
    if i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch then
        local d = i.Position - reopenDragStart
        S.reopenDragDist = math.max(S.reopenDragDist, d.Magnitude)
        U.reopen.Position = UDim2.new(reopenDragStartPos.X.Scale, reopenDragStartPos.X.Offset + d.X, reopenDragStartPos.Y.Scale, reopenDragStartPos.Y.Offset + d.Y)
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

-- Header buttons
U.close.MouseButton1Click:Connect(function() showCloseConfirm() end)
U.close.MouseEnter:Connect(function() U.close.BackgroundColor3 = Color3.fromRGB(180, 55, 55) end)
U.close.MouseLeave:Connect(function() U.close.BackgroundColor3 = Color3.fromRGB(42, 44, 52) end)
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
    if minimizeMenu then minimizeMenu() end
    sendNotification("MM2 Menu", "Menu minimized. Click 'MM2' or press Right Shift to reopen.")
end)
ccYes.MouseButton1Click:Connect(function()
    U.closeConfirm.Visible = false
    if closeScript then closeScript() end
end)

showMenu = function()
    S.menuVisible = true
    U.frame.Visible = true
    U.reopen.Visible = false
end
minimizeMenu = function()
    S.menuVisible = false
    U.frame.Visible = false
    if FP.panel then FP.panel.Visible = false end
    S.flyPanelOpen = false
    U.reopen.Visible = true
end
closeScript = function()
    if resetAllToggles then pcall(resetAllToggles) end
    if stopFly then pcall(stopFly) end
    S.scriptClosed = true
    sendNotification("MM2 Menu", "Script closed.")
    pcall(function() U.gui:Destroy() end)
    pcall(function() S.crosshairGui:Destroy() end)
    pcall(function() NotifUI.gui:Destroy() end)
    pcall(function() TutorialUI.gui:Destroy() end)
    pcall(function() PerfUI.gui:Destroy() end)
    pcall(function() DirUI.gui:Destroy() end)
    pcall(function() toastGui:Destroy() end)
end

-- ═══════════════════════════════════════════════════════════
-- RESET / PVP
-- ═══════════════════════════════════════════════════════════
resetAllToggles = function()
    if S.noclip then
        S.noclip = false
        if U.noclipBtn then setOff(U.noclipBtn, U.noclipInd) end
        for o, v in pairs(S.originalCollision) do if o and o.Parent then o.CanCollide = v end end
        S.originalCollision = {}
    end
    if S.flyEnabled and stopFly then stopFly() end
    S.flyPanelOpen = false
    if FP.panel then FP.panel.Visible = false end
    if S.infinityJump then S.infinityJump = false if U.infBtn then setOff(U.infBtn, U.infInd) end end
    if S.flingThirdParty then S.flingThirdParty = false if U.f3Btn then setOff(U.f3Btn, U.f3Ind) end end
    if S.flingOnTouch then S.flingOnTouch = false S.flingTouchActive = false if U.fib then setOff(U.fib, U.fii) end end
    if S.speedhackEnabled then
        S.speedhackEnabled = false
        if U.shBtn then setOff(U.shBtn, U.shInd) end
        local c = player.Character
        if c then local h = c:FindFirstChildOfClass("Humanoid") if h then h.WalkSpeed = 16 end end
    end
    for r, st in pairs(S.espEnabled) do
        if st then S.espEnabled[r] = false if espButtons[r] then setOff(espButtons[r].Button, espButtons[r].Indicator) end end
    end
    if S.gunESPEnabled then
        S.gunESPEnabled = false
        if U.gunBtn then setOff(U.gunBtn, U.gunInd) end
        for g, hl in pairs(S.gunHighlights) do if hl then pcall(function() hl:Destroy() end) end end
        S.gunHighlights = {}
    end
    if S.playerDistanceOn then
        S.playerDistanceOn = false
        if U.distBtn then setOff(U.distBtn, U.distInd) end
        for p, bg in pairs(S.playerDistBillboards) do if bg then bg:Destroy() end end
        S.playerDistBillboards = {}
    end
    if S.autoNotifyRoles then
        S.autoNotifyRoles = false
        if U.autoNotBtn then setOff(U.autoNotBtn, U.autoNotInd) end
        lastNotifiedMurderer = nil lastNotifiedSheriff = nil lastNotifiedHero = nil S.pendingNotify = false
    end
    if S.reAnnounceEnabled then S.reAnnounceEnabled = false if U.reAnnBtn then setOff(U.reAnnBtn, U.reAnnInd) end end
    if S.heroChangeNotify then S.heroChangeNotify = false if U.heroChangeBtn then setOff(U.heroChangeBtn, U.heroChangeInd) end end
    if S.autoHideInRound then S.autoHideInRound = false if U.autoHideBtn then setOff(U.autoHideBtn, U.autoHideInd) end end
    if S.autoSendMurdererChat then
        S.autoSendMurdererChat = false
        if U.autoChatBtn then setOff(U.autoChatBtn, U.autoChatInd) end
        S.lastChatSentMurderer = nil S.roundActive = false S.selfNotifyMurderer = false
    end
    if S.autoSendSheriffChat then
        S.autoSendSheriffChat = false
        if U.autoSheriffChatBtn then setOff(U.autoSheriffChatBtn, U.autoSheriffChatInd) end
        S.lastChatSentSheriff = nil S.roundActiveSheriff = false S.selfNotifySheriff = false
    end
    if S.autoKillAll then S.autoKillAll = false if U.autoKillBtn then setOff(U.autoKillBtn, U.autoKillInd) end end
    if S.autoGunTP then S.autoGunTP = false if U.autoGunBtn then setOff(U.autoGunBtn, U.autoGunInd) end end
    if S.antiVoidEnabled then S.antiVoidEnabled = false if U.avBtn then setOff(U.avBtn, U.avInd) end end
    if S.antiFlingEnabled then S.antiFlingEnabled = false if U.afBtn then setOff(U.afBtn, U.afInd) end end
    if S.antiAfkEnabled then
        S.antiAfkEnabled = false
        if U.afkBtn then setOff(U.afkBtn, U.afkInd) end
        if S.antiAfkConn then S.antiAfkConn:Disconnect() S.antiAfkConn = nil end
    end
    if S.killerAlarmOn then S.killerAlarmOn = false if U.killerAlarmBtn then setOff(U.killerAlarmBtn, U.killerAlarmInd) end end
    if S.dirIndicatorOn then
        S.dirIndicatorOn = false
        if U.dirBtn then setOff(U.dirBtn, U.dirInd) end
        if DirUI and DirUI.gui then DirUI.gui.Enabled = false end
    end
    if S.cameraFollowMurderer then S.cameraFollowMurderer = false if U.camFollowBtn then setOff(U.camFollowBtn, U.camFollowInd) end end
    if S.crosshairOn then
        S.crosshairOn = false
        if U.crosshairBtn then setOff(U.crosshairBtn, U.crosshairInd) end
        if S.crosshairGui then S.crosshairGui.Enabled = false end
    end
    if S.gunDropAlert then S.gunDropAlert = false if U.gunAlertBtn then setOff(U.gunAlertBtn, U.gunAlertInd) end end
    if S.killerTrailOn then S.killerTrailOn = false if U.killerTrailBtn then setOff(U.killerTrailBtn, U.killerTrailInd) end end
    if S.sheriffTrailOn then S.sheriffTrailOn = false if U.sheriffTrailBtn then setOff(U.sheriffTrailBtn, U.sheriffTrailInd) end end
    if S.heroTrailOn then S.heroTrailOn = false if U.heroTrailBtn then setOff(U.heroTrailBtn, U.heroTrailInd) end end
    if S.killSoundOn then S.killSoundOn = false if U.killSoundBtn then setOff(U.killSoundBtn, U.killSoundInd) end end
    if S.notifyRoundStart then S.notifyRoundStart = false if U.rStartBtn then setOff(U.rStartBtn, U.rStartInd) end end
    if S.notifyRoundEnd then S.notifyRoundEnd = false if U.rEndBtn then setOff(U.rEndBtn, U.rEndInd) end end
    if S.playerJoinLeaveNotify then S.playerJoinLeaveNotify = false if U.plBtn then setOff(U.plBtn, U.plInd) end end
    sendNotification("MM2 Menu", "All features turned off")
end

silentResetAll = function()
    local oldSend = sendNotification
    sendNotification = function() end
    pcall(resetAllToggles)
    sendNotification = oldSend
end

applyPvpPreset = function()
    if not S.pvpSnapshot then S.pvpSnapshot = snapshotFullSettings() end
    if not S.antiAfkEnabled then
        S.antiAfkEnabled = true
        if U.afkBtn then setOn(U.afkBtn, U.afkInd) end
        if S.antiAfkConn then S.antiAfkConn:Disconnect() end
        S.antiAfkConn = player.Idled:Connect(function()
            local VU = game:GetService("VirtualUser")
            VU:CaptureController()
            VU:ClickButton2(Vector2.new())
        end)
    end
    if not S.antiVoidEnabled then S.antiVoidEnabled = true if U.avBtn then setOn(U.avBtn, U.avInd) end end
    if not S.antiFlingEnabled then S.antiFlingEnabled = true if U.afBtn then setOn(U.afBtn, U.afInd) end end
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
        if U.gunBtn then
            U.gunBtn.BackgroundColor3 = GUN_COLOR:Lerp(Color3.fromRGB(20, 20, 25), 0.65)
            U.gunInd.BackgroundColor3 = GUN_COLOR
        end
    end
    if not S.noclip then
        S.noclip = true
        if U.noclipBtn then setOn(U.noclipBtn, U.noclipInd) end
        S.originalCollision = {}
        if player.Character then
            for _, o in ipairs(player.Character:GetDescendants()) do
                if o:IsA("BasePart") then S.originalCollision[o] = o.CanCollide o.CanCollide = false end
            end
        end
    end
    if not S.autoNotifyRoles then S.autoNotifyRoles = true if U.autoNotBtn then setOn(U.autoNotBtn, U.autoNotInd) end end
    if not S.autoKillAll then S.autoKillAll = true if U.autoKillBtn then setOn(U.autoKillBtn, U.autoKillInd) end end
    if not S.killerAlarmOn then
        S.killerAlarmOn = true
        S.lastAlarmDist = math.huge S.lastAlarmTime = 0
        if U.killerAlarmBtn then setOn(U.killerAlarmBtn, U.killerAlarmInd) end
    end
    if not IS_MOBILE and not S.crosshairOn then
        S.crosshairOn = true
        if U.crosshairBtn then setOn(U.crosshairBtn, U.crosshairInd) end
        if S.crosshairGui then S.crosshairGui.Enabled = true end
    end
    if not S.gunDropAlert then S.gunDropAlert = true if U.gunAlertBtn then setOn(U.gunAlertBtn, U.gunAlertInd) end end
    if not S.notifyRoundStart then S.notifyRoundStart = true if U.rStartBtn then setOn(U.rStartBtn, U.rStartInd) end end
    if not S.notifyRoundEnd then S.notifyRoundEnd = true if U.rEndBtn then setOn(U.rEndBtn, U.rEndInd) end end
    if not S.playerJoinLeaveNotify then S.playerJoinLeaveNotify = true if U.plBtn then setOn(U.plBtn, U.plInd) end end
    if not S.killSoundOn then S.killSoundOn = true if U.killSoundBtn then setOn(U.killSoundBtn, U.killSoundInd) end end
end

restorePvpSnapshot = function()
    if not S.pvpSnapshot then
        sendNotification("MM2 Menu", "No previous settings to restore", SOUNDS.alert)
        return
    end
    applyFullSnapshot(S.pvpSnapshot)
    S.pvpSnapshot = nil
    sendNotification("MM2 Menu", "Restored previous settings")
end

-- ═══════════════════════════════════════════════════════════
-- HOME UPDATER
-- ═══════════════════════════════════════════════════════════
rebuildKeybindList = function()
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
    if U.homeRefs.keybindsPlaceholder then U.homeRefs.keybindsPlaceholder.Visible = (shown == 0) end
end

rebuildNotifHistory = function()
    if not U.homeRefs.notifScroll then return end
    for _, child in ipairs(U.homeRefs.notifScroll:GetChildren()) do
        if child:IsA("Frame") or child:IsA("TextButton") or child:IsA("TextLabel") then child:Destroy() end
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
        empty.LayoutOrder = 1
        empty.Parent = U.homeRefs.notifScroll
        return
    end
    for idx, notif in ipairs(S.notificationHistory) do
        local color = NOTIF_COLORS[notif.category or "info"] or NOTIF_COLORS.info
        local frame = Instance.new("TextButton")
        frame.Size = UDim2.new(1, 0, 0, mn(30))
        frame.BackgroundColor3 = Color3.fromRGB(34, 36, 43)
        frame.BorderSizePixel = 0
        frame.Text = ""
        frame.AutoButtonColor = false
        frame.LayoutOrder = idx
        frame.Parent = U.homeRefs.notifScroll
        do local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 5) c.Parent = frame end
        local accent = Instance.new("Frame")
        accent.Size = UDim2.new(0, mn(3), 1, 0)
        accent.BackgroundColor3 = color
        accent.BorderSizePixel = 0
        accent.Parent = frame
        do local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 3) c.Parent = accent end
        local t = Instance.new("TextLabel")
        t.Size = UDim2.new(1, -mn(14), 0, mn(13))
        t.Position = mpos(8, 1)
        t.BackgroundTransparency = 1
        t.Text = notif.title
        t.TextColor3 = Color3.fromRGB(230, 230, 235)
        t.TextSize = mn(10)
        t.Font = Enum.Font.GothamBold
        t.TextXAlignment = Enum.TextXAlignment.Left
        t.TextTruncate = Enum.TextTruncate.AtEnd
        t.Parent = frame
        local b = Instance.new("TextLabel")
        b.Size = UDim2.new(1, -mn(55), 0, mn(12))
        b.Position = mpos(8, 14)
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
        frame.MouseButton1Click:Connect(function()
            pcall(function() setclipboard(notif.title .. "\n" .. notif.text) end)
            showToast("Copied notification")
        end)
    end
end

updateHomeUI = function(rebuildLists)
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
    U.homeRefs.playersLbl.Text = tostring(#Players:GetPlayers()) .. " / " .. tostring(Players.MaxPlayers or 0)
    if MurdererName and MurdererName ~= player.Name then
        local me = player.Character
        local m = Players:FindFirstChild(MurdererName)
        if me and m and m.Character then
            local myRoot = me:FindFirstChild("HumanoidRootPart")
            local mRoot = m.Character:FindFirstChild("HumanoidRootPart")
            if myRoot and mRoot then
                U.homeRefs.murdDistLbl.Text = tostring(math.floor((myRoot.Position - mRoot.Position).Magnitude)) .. " studs"
            else U.homeRefs.murdDistLbl.Text = "-" end
        else U.homeRefs.murdDistLbl.Text = "-" end
    else
        U.homeRefs.murdDistLbl.Text = MurdererName == player.Name and "You" or "-"
    end
    U.homeRefs.fpsLbl.Text = tostring(S.currentFPS)
    U.homeRefs.pingLbl.Text = tostring(S.currentPing) .. " ms"
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

task.spawn(function()
    while U.gui.Parent and not S.scriptClosed do
        if U.activeTab == "Home" then pcall(updateHomeUI, false) end
        task.wait(0.5)
    end
end)

-- ═══════════════════════════════════════════════════════════
-- KEYBIND ACTIONS
-- ═══════════════════════════════════════════════════════════
local kbActions = {}
kbActions.fly = function() if S.flyEnabled then stopFly() else startFly() end end
kbActions.noclip = function()
    S.noclip = not S.noclip
    if U.noclipBtn then if S.noclip then setOn(U.noclipBtn, U.noclipInd) else setOff(U.noclipBtn, U.noclipInd) end end
    if S.noclip then
        S.originalCollision = {}
        if player.Character then
            for _, o in ipairs(player.Character:GetDescendants()) do
                if o:IsA("BasePart") then S.originalCollision[o] = o.CanCollide o.CanCollide = false end
            end
        end
    else
        for o, v in pairs(S.originalCollision) do if o and o.Parent then o.CanCollide = v end end
        S.originalCollision = {}
    end
end
kbActions.speedhack = function()
    S.speedhackEnabled = not S.speedhackEnabled
    if U.shBtn then if S.speedhackEnabled then setOn(U.shBtn, U.shInd) else setOff(U.shBtn, U.shInd) end end
    local c = player.Character
    if c then local h = c:FindFirstChildOfClass("Humanoid") if h then h.WalkSpeed = S.speedhackEnabled and S.speedhackSpeed or 16 end end
end
kbActions.infinityJump = function()
    S.infinityJump = not S.infinityJump
    if U.infBtn then if S.infinityJump then setOn(U.infBtn, U.infInd) else setOff(U.infBtn, U.infInd) end end
end
kbActions.autoKillAll = function()
    S.autoKillAll = not S.autoKillAll
    if U.autoKillBtn then if S.autoKillAll then setOn(U.autoKillBtn, U.autoKillInd) else setOff(U.autoKillBtn, U.autoKillInd) end end
end
kbActions.gunESP = function()
    S.gunESPEnabled = not S.gunESPEnabled
    if U.gunBtn then
        if S.gunESPEnabled then
            U.gunBtn.BackgroundColor3 = GUN_COLOR:Lerp(Color3.fromRGB(20, 20, 25), 0.65)
            U.gunInd.BackgroundColor3 = GUN_COLOR
        else
            setOff(U.gunBtn, U.gunInd)
            for gun, hl in pairs(S.gunHighlights) do if hl then pcall(function() hl:Destroy() end) end end
            S.gunHighlights = {}
        end
    end
end
local function toggleEspRole(role)
    S.espEnabled[role] = not S.espEnabled[role]
    if espButtons[role] then
        if S.espEnabled[role] then
            espButtons[role].Button.BackgroundColor3 = ROLE_COLORS[role]:Lerp(Color3.fromRGB(20, 20, 25), 0.65)
            espButtons[role].Indicator.BackgroundColor3 = ROLE_COLORS[role]
        else setOff(espButtons[role].Button, espButtons[role].Indicator) end
    end
end
kbActions.murdererESP = function() toggleEspRole("Murderer") end
kbActions.sheriffESP = function() toggleEspRole("Sheriff") end
kbActions.innocentESP = function() toggleEspRole("Innocent") end
kbActions.antiVoid = function()
    S.antiVoidEnabled = not S.antiVoidEnabled
    if U.avBtn then if S.antiVoidEnabled then setOn(U.avBtn, U.avInd) else setOff(U.avBtn, U.avInd) end end
end
kbActions.turnOffAll = function() if resetAllToggles then resetAllToggles() end end
kbActions.panic = function()
    if silentResetAll then silentResetAll() end
    if minimizeMenu then minimizeMenu() end
end

local modifierKeys = {
    [Enum.KeyCode.LeftAlt] = true, [Enum.KeyCode.RightAlt] = true,
    [Enum.KeyCode.LeftControl] = true, [Enum.KeyCode.RightControl] = true,
    [Enum.KeyCode.LeftShift] = true,
}
local pendingModifier = nil

UserInputService.InputBegan:Connect(function(i, processed)
    if S.scriptClosed then return end
    if U.whatsNewOverlay.Visible and i.KeyCode == Enum.KeyCode.Escape then U.whatsNewOverlay.Visible = false return end
    if TutorialUI.gui.Enabled and i.KeyCode == Enum.KeyCode.Escape then TutorialUI.gui.Enabled = false return end
    if U.closeConfirm.Visible and i.KeyCode == Enum.KeyCode.Escape then U.closeConfirm.Visible = false return end
    if S.capturingKeybind then
        if i.KeyCode == Enum.KeyCode.Escape then if U.endCapture then U.endCapture() end return end
        if S.capturingAction then S.keybinds[S.capturingAction] = i.KeyCode end
        if U.endCapture then U.endCapture() end
        return
    end
    if processed then return end
    if i.KeyCode == Enum.KeyCode.RightShift then
        if S.menuVisible then minimizeMenu() else showMenu() end
        return
    end
    if modifierKeys[i.KeyCode] then pendingModifier = i.KeyCode return end
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

-- ═══════════════════════════════════════════════════════════
-- BACKGROUND LOOPS
-- ═══════════════════════════════════════════════════════════
RunService.Heartbeat:Connect(function()
    if S.scriptClosed then return end
    if not S.killerAlarmOn or not MurdererName then S.lastAlarmDist = math.huge return end
    local me = player.Character
    if not me then return end
    local myRoot = me:FindFirstChild("HumanoidRootPart")
    if not myRoot then return end
    local m = Players:FindFirstChild(MurdererName)
    if not m or not m.Character then return end
    local mRoot = m.Character:FindFirstChild("HumanoidRootPart")
    if not mRoot then return end
    local dist = (myRoot.Position - mRoot.Position).Magnitude
    if dist > 30 then S.lastAlarmDist = math.huge return end
    local now = tick()
    if dist < S.lastAlarmDist - ALARM_DIST_STEP and (now - (S.lastAlarmTime or 0)) >= ALARM_TIME_COOLDOWN then
        S.lastAlarmDist = dist
        S.lastAlarmTime = now
        sendNotification("Murderer Near", "Murderer is " .. math.floor(dist) .. " studs away!", SOUNDS.alert)
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
            cx = S.lastTouchPos.X cy = S.lastTouchPos.Y
        elseif UserInputService.MouseEnabled then
            local loc = UserInputService:GetMouseLocation()
            cx = loc.X cy = loc.Y
        else
            local vp = workspace.CurrentCamera.ViewportSize
            cx = vp.X / 2 cy = vp.Y / 2
        end
        U.crosshairH.Position = UDim2.fromOffset(cx - CH_LEN / 2, cy - CH_THICK / 2)
        U.crosshairV.Position = UDim2.fromOffset(cx - CH_THICK / 2, cy - CH_LEN / 2)
        U.crosshairDot.Position = UDim2.fromOffset(cx - CH_DOT / 2, cy - CH_DOT / 2)
    end
    if S.dirIndicatorOn and MurdererName and MurdererName ~= player.Name then
        local m = Players:FindFirstChild(MurdererName)
        local me = player.Character
        local cam = workspace.CurrentCamera
        if m and m.Character and me and cam then
            local mRoot = m.Character:FindFirstChild("HumanoidRootPart")
            local myRoot = me:FindFirstChild("HumanoidRootPart")
            if mRoot and myRoot then
                DirUI.gui.Enabled = true
                DirUI.frame.Visible = true
                local delta = mRoot.Position - myRoot.Position
                local camLook = cam.CFrame.LookVector
                local angle = math.atan2(delta.X, delta.Z) - math.atan2(camLook.X, camLook.Z)
                local vp = cam.ViewportSize
                local cx, cy = vp.X / 2, vp.Y / 2
                local radius = math.min(vp.X, vp.Y) * 0.18
                local ox = math.sin(angle) * radius
                local oy = -math.cos(angle) * radius
                DirUI.frame.Position = UDim2.fromOffset(cx + ox - mn(15), cy + oy - mn(15))
                DirUI.arrow.Rotation = math.deg(angle) + 180
                DirUI.distLbl.Text = math.floor(delta.Magnitude) .. " st"
            end
        else DirUI.frame.Visible = false end
    else if DirUI then DirUI.frame.Visible = false end end
end)

local function refreshLastTouch()
    local bestPos, bestX = nil, -math.huge
    for _, pos in pairs(S.activeTouches) do
        if pos.X > bestX then bestX = pos.X bestPos = pos end
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
    if i.UserInputType == Enum.UserInputType.Touch and S.activeTouches[i] ~= nil then
        S.activeTouches[i] = i.Position
        refreshLastTouch()
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
    if not S.antiFlingEnabled or S.flyEnabled then return end
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

task.spawn(function()
    local frames = 0
    local last = tick()
    RunService.RenderStepped:Connect(function()
        frames = frames + 1
        if tick() - last >= 1 then
            S.currentFPS = frames
            frames = 0
            last = tick()
            pcall(function() S.currentPing = math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue()) end)
            if PerfUI then PerfUI.label.Text = "FPS: " .. tostring(S.currentFPS) .. " | Ping: " .. tostring(S.currentPing) end
        end
    end)
end)

local function hookPlayerDeath(character)
    local hum = character:WaitForChild("Humanoid", 5)
    if hum then hum.Died:Connect(function() S.stats.deaths = S.stats.deaths + 1 end) end
end

if player.Character then hookPlayerDeath(player.Character) end
player.CharacterAdded:Connect(function(character)
    if stopFly then stopFly() end
    S.originalCollision = {}
    S.lastSafePosition = nil
    S.antiVoidCooldown = false
    if S.noclip then
        task.wait(0.1)
        for _, o in ipairs(character:GetDescendants()) do
            if o:IsA("BasePart") then S.originalCollision[o] = o.CanCollide o.CanCollide = false end
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

pcall(function()
    if hookmetamethod and getnamecallmethod then
        local orig = hookmetamethod(game, "__namecall", function(self, ...)
            if getnamecallmethod() == "Kick" and self == player then
                task.spawn(function()
                    task.wait(0.2)
                    pcall(function() TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, player) end)
                end)
            end
            return orig(self, ...)
        end)
    end
end)

RunService.Heartbeat:Connect(function()
    if S.scriptClosed then return end
    local hue = (tick() * RAINBOW_SPEED) % 1
    local color = Color3.fromHSV(hue, 1, 1)
    U.frameStroke.Color = color
    U.reopenStroke.Color = color
    if FP.stroke then FP.stroke.Color = color end
    U.titleGradient.Rotation = (tick() * 60) % 360
    if S.crosshairOn and U.crosshairH and U.crosshairV and U.crosshairDot then
        U.crosshairH.BackgroundColor3 = color
        U.crosshairV.BackgroundColor3 = color
        U.crosshairDot.BackgroundColor3 = Color3.fromHSV((hue + 0.5) % 1, 1, 1)
    end
    if S.dirIndicatorOn and DirUI then DirUI.arrow.TextColor3 = color end
end)

getRoles()
updateHL()
updateGunESP()

task.defer(function()
    task.wait(1)
    if not S.whatsNewAutoShown then
        S.whatsNewAutoShown = true
        pcall(openWhatsNew)
    end
    pcall(updateHomeUI, true)
end)

task.spawn(function()
    task.wait(0.5)
    local hasSeen = false
    if isfile and readfile then
        pcall(function()
            if isfile("mm2_menu_tutorial_seen.txt") then hasSeen = true end
        end)
        if not hasSeen then pcall(function() writefile("mm2_menu_tutorial_seen.txt", "1") end) end
    else
        hasSeen = _G.MM2TutorialSeen == true
        _G.MM2TutorialSeen = true
    end
    if not hasSeen and showTutorial then showTutorial() end
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
            if S.autoGunTP then
                local now = tick()
                if now - lastAutoGunTP >= 3 then
                    local c = player.Character
                    if c and not c:FindFirstChild("Gun") and not c:FindFirstChild("Knife") then
                        local mr = c:FindFirstChild("HumanoidRootPart")
                        local gd = workspace:FindFirstChild("GunDrop", true) or workspace:FindFirstChild("Gun", true)
                        if mr and gd then
                            local tp
                            if gd:IsA("BasePart") then tp = gd
                            elseif gd:IsA("Model") then tp = gd.PrimaryPart or gd:FindFirstChildOfClass("BasePart")
                            elseif gd:IsA("Tool") then tp = gd:FindFirstChild("Handle") end
                            if tp then
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
                        end
                    end
                end
            end
            checkAutoChat()
        end)
        task.wait(0.25)
    end
end)