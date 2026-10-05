--// MM2 MENU BY ARBUZ v0.9

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")
local TeleportService = game:GetService("TeleportService")

local RAINBOW_SPEED = 0.25

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local S = {
    noclip = false, infinityJump = false, flingOnTouch = false, flingThirdParty = false,
    flyEnabled = false, autoNotifyRoles = false, autoKillAll = false, autoGunTP = false,
    autoSendMurdererChat = false, antiVoidEnabled = false, antiFlingEnabled = false,
    flySpeed = 50, speedhackEnabled = false, speedhackSpeed = 45,
    guiLocked = false, minimized = false, menuVisible = true,
    espEnabled = { Innocent = false, Murderer = false, Sheriff = false, Hero = false },
    gunESPEnabled = false, gunHighlights = {}, originalCollision = {},
    lastChatSentMurderer = nil, roundActive = false, chatSendCooldown = 0,
    flyPanelOpen = false, flingTouchActive = false, flingTouchThread = nil,
    dropdownOpen = false, selectedPlayer = nil,
    resizing = false, dragging = false, reopenDragging = false,
    lastSafePosition = nil, lastSafeUpdate = 0, antiVoidCooldown = false,
    VOID_Y_THRESHOLD = -50, ANTI_FLING_MAX_SPEED = 200, ANTI_FLING_MAX_ANGULAR = 500,
    pendingNotify = false, pendingNotifySince = 0,
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

local function sendNotification(title, text)
    pcall(function() StarterGui:SetCore("SendNotification", {Title=title, Text=text, Duration=5}) end)
end

local function getLayoutOrder()
    currentLayoutOrder = currentLayoutOrder + 1
    return currentLayoutOrder
end

local U = {}

local existing = playerGui:FindFirstChild("MM2MenuByArbuz")
if existing then existing:Destroy() end

U.gui = Instance.new("ScreenGui")
U.gui.Name = "MM2MenuByArbuz"
U.gui.ResetOnSpawn = false
U.gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
U.gui.DisplayOrder = 100
U.gui.Parent = playerGui

U.frame = Instance.new("Frame")
U.frame.Name = "Main"
U.frame.Size = UDim2.fromOffset(460, 380)
U.frame.Position = UDim2.new(0.5, -230, 0.5, -190)
U.frame.BackgroundColor3 = Color3.fromRGB(22, 23, 28)
U.frame.BorderSizePixel = 0
U.frame.Active = true
U.frame.Parent = U.gui
do
    local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 12) c.Parent = U.frame
    U.frameStroke = Instance.new("UIStroke")
    U.frameStroke.Color = Color3.fromRGB(55, 57, 65)
    U.frameStroke.Thickness = 1
    U.frameStroke.Parent = U.frame
end

U.header = Instance.new("Frame")
U.header.Name = "Header"
U.header.Size = UDim2.new(1, 0, 0, 48)
U.header.BackgroundColor3 = Color3.fromRGB(29, 30, 37)
U.header.BorderSizePixel = 0
U.header.Active = true
U.header.Parent = U.frame
do local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 12) c.Parent = U.header end

U.title = Instance.new("TextLabel")
U.title.Size = UDim2.new(1, -120, 1, 0)
U.title.Position = UDim2.fromOffset(10, 0)
U.title.BackgroundTransparency = 1
U.title.Text = "MM2 MENU BY ARBUZ v0.9"
U.title.TextColor3 = Color3.fromRGB(255, 255, 255)
U.title.TextSize = 13
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
U.close.Size = UDim2.fromOffset(30, 30)
U.close.Position = UDim2.new(1, -105, 0.5, -15)
U.close.BackgroundColor3 = Color3.fromRGB(42, 44, 52)
U.close.Text = "X"
U.close.TextSize = 16
U.close.TextColor3 = Color3.fromRGB(255, 200, 200)
U.close.Font = Enum.Font.GothamBold
U.close.BorderSizePixel = 0
U.close.AutoButtonColor = false
U.close.ZIndex = 5
U.close.Parent = U.header
do local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 7) c.Parent = U.close end

U.lock = Instance.new("TextButton")
U.lock.Size = UDim2.fromOffset(30, 30)
U.lock.Position = UDim2.new(1, -70, 0.5, -15)
U.lock.BackgroundColor3 = Color3.fromRGB(42, 44, 52)
U.lock.Text = "🔓"
U.lock.TextSize = 14
U.lock.TextColor3 = Color3.new(1, 1, 1)
U.lock.Font = Enum.Font.GothamBold
U.lock.BorderSizePixel = 0
U.lock.AutoButtonColor = false
U.lock.ZIndex = 5
U.lock.Parent = U.header
do local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 7) c.Parent = U.lock end

U.minimize = Instance.new("TextButton")
U.minimize.Size = UDim2.fromOffset(30, 30)
U.minimize.Position = UDim2.new(1, -35, 0.5, -15)
U.minimize.BackgroundColor3 = Color3.fromRGB(42, 44, 52)
U.minimize.Text = "-"
U.minimize.TextColor3 = Color3.new(1, 1, 1)
U.minimize.TextSize = 17
U.minimize.Font = Enum.Font.GothamBold
U.minimize.BorderSizePixel = 0
U.minimize.AutoButtonColor = false
U.minimize.ZIndex = 5
U.minimize.Parent = U.header
do local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 7) c.Parent = U.minimize end

U.resize = Instance.new("TextButton")
U.resize.Size = UDim2.fromOffset(16, 16)
U.resize.Position = UDim2.new(1, -16, 1, -16)
U.resize.BackgroundColor3 = Color3.fromRGB(55, 57, 65)
U.resize.BorderSizePixel = 0
U.resize.Text = ""
U.resize.AutoButtonColor = false
U.resize.ZIndex = 30
U.resize.Parent = U.frame
do local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 4) c.Parent = U.resize end

U.reopen = Instance.new("TextButton")
U.reopen.Size = UDim2.fromOffset(50, 50)
U.reopen.Position = UDim2.new(0, 15, 0.5, -25)
U.reopen.BackgroundColor3 = Color3.fromRGB(29, 30, 37)
U.reopen.BorderSizePixel = 0
U.reopen.Text = "MM2"
U.reopen.TextColor3 = Color3.fromRGB(245, 245, 250)
U.reopen.TextSize = 13
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

U.sidebar = Instance.new("Frame")
U.sidebar.Name = "Sidebar"
U.sidebar.Size = UDim2.new(0, 100, 1, -66)
U.sidebar.Position = UDim2.fromOffset(10, 55)
U.sidebar.BackgroundTransparency = 1
U.sidebar.Parent = U.frame
do
    local l = Instance.new("UIListLayout")
    l.Padding = UDim.new(0, 4)
    l.SortOrder = Enum.SortOrder.LayoutOrder
    l.Parent = U.sidebar
end

U.rightArea = Instance.new("Frame")
U.rightArea.Name = "RightArea"
U.rightArea.Size = UDim2.new(1, -128, 1, -66)
U.rightArea.Position = UDim2.fromOffset(118, 55)
U.rightArea.BackgroundTransparency = 1
U.rightArea.Parent = U.frame

U.searchBox = Instance.new("TextBox")
U.searchBox.Size = UDim2.new(1, 0, 0, 28)
U.searchBox.BackgroundColor3 = Color3.fromRGB(34, 36, 43)
U.searchBox.BorderSizePixel = 0
U.searchBox.Text = ""
U.searchBox.PlaceholderText = "Search..."
U.searchBox.TextColor3 = Color3.fromRGB(230, 230, 235)
U.searchBox.PlaceholderColor3 = Color3.fromRGB(120, 122, 130)
U.searchBox.TextSize = 12
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
local tabNames = {"Movement", "ESP", "Notifier", "Murderer", "Sheriff", "Teleport", "Utility"}

for _, tabName in ipairs(tabNames) do
    local fr = Instance.new("ScrollingFrame")
    fr.Name = tabName .. "Tab"
    fr.Size = UDim2.new(1, 0, 1, -36)
    fr.Position = UDim2.fromOffset(0, 34)
    fr.BackgroundTransparency = 1
    fr.BorderSizePixel = 0
    fr.ScrollBarThickness = 5
    fr.ScrollBarImageColor3 = Color3.fromRGB(75, 77, 85)
    fr.AutomaticCanvasSize = Enum.AutomaticSize.Y
    fr.ScrollingDirection = Enum.ScrollingDirection.Y
    fr.Visible = false
    fr.Parent = U.rightArea
    do
        local l = Instance.new("UIListLayout")
        l.Padding = UDim.new(0, 6)
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
    if U.searchBox.Text ~= "" then
        U.searchBox.Text = ""
    end
    local fr = U.tabFrames[name]
    if fr then
        for _, child in ipairs(fr:GetChildren()) do
            if child:IsA("TextButton") then child.Visible = true end
        end
    end
end

local iOrder = 0
for _, tabName in ipairs(tabNames) do
    iOrder = iOrder + 1
    local tb = Instance.new("TextButton")
    tb.Size = UDim2.new(1, 0, 0, 32)
    tb.BackgroundColor3 = Color3.fromRGB(34, 36, 43)
    tb.BorderSizePixel = 0
    tb.Text = tabName
    tb.TextColor3 = Color3.fromRGB(200, 200, 210)
    tb.TextSize = 11
    tb.Font = Enum.Font.GothamSemibold
    tb.AutoButtonColor = false
    tb.TextXAlignment = Enum.TextXAlignment.Left
    tb.LayoutOrder = iOrder
    tb.Parent = U.sidebar
    do
        local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 7) c.Parent = tb
        local p = Instance.new("UIPadding") p.PaddingLeft = UDim.new(0, 8) p.Parent = tb
    end
    U.tabs[tabName] = tb
    tb.MouseButton1Click:Connect(function() switchTab(tabName) end)
end

switchTab("Movement")

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
    l.Size = UDim2.new(1, 0, 0, 20)
    l.BackgroundTransparency = 1
    l.Text = text
    l.TextColor3 = Color3.fromRGB(150, 153, 165)
    l.TextSize = 11
    l.Font = Enum.Font.GothamBold
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.LayoutOrder = getLayoutOrder()
    l.Parent = currentParent
end

local function createToggle(name, text)
    local b = Instance.new("TextButton")
    b.Name = name
    b.Size = UDim2.new(1, 0, 0, 34)
    b.BackgroundColor3 = Color3.fromRGB(34, 36, 43)
    b.BorderSizePixel = 0
    b.Text = text
    b.TextColor3 = Color3.fromRGB(230, 230, 235)
    b.TextSize = 12
    b.Font = Enum.Font.GothamSemibold
    b.AutoButtonColor = false
    b.LayoutOrder = getLayoutOrder()
    b.Parent = currentParent
    do local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 8) c.Parent = b end
    local ind = Instance.new("Frame")
    ind.Size = UDim2.fromOffset(5, 18)
    ind.Position = UDim2.fromOffset(8, 8)
    ind.BackgroundColor3 = Color3.fromRGB(80, 82, 90)
    ind.BorderSizePixel = 0
    ind.Parent = b
    do local c = Instance.new("UICorner") c.CornerRadius = UDim.new(1, 0) c.Parent = ind end
    return b, ind
end

local function createActionButton(name, text)
    local b = Instance.new("TextButton")
    b.Name = name
    b.Size = UDim2.new(1, 0, 0, 34)
    b.BackgroundColor3 = Color3.fromRGB(34, 36, 43)
    b.BorderSizePixel = 0
    b.Text = text
    b.TextColor3 = Color3.fromRGB(230, 230, 235)
    b.TextSize = 12
    b.Font = Enum.Font.GothamSemibold
    b.AutoButtonColor = false
    b.LayoutOrder = getLayoutOrder()
    b.Parent = currentParent
    do local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 8) c.Parent = b end
    return b
end

local function setOn(b, i)
    b.BackgroundColor3 = Color3.fromRGB(35, 70, 45)
    i.BackgroundColor3 = Color3.fromRGB(50, 210, 90)
end
local function setOff(b, i)
    b.BackgroundColor3 = Color3.fromRGB(34, 36, 43)
    i.BackgroundColor3 = Color3.fromRGB(80, 82, 90)
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

-- ============================================================
-- MOVEMENT TAB
-- ============================================================
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
FP.panel.Size = UDim2.fromOffset(210, 220)
FP.panel.Position = UDim2.new(0.5, 150, 0.5, -110)
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

do
    local hd = Instance.new("Frame")
    hd.Size = UDim2.new(1, 0, 0, 42)
    hd.BackgroundColor3 = Color3.fromRGB(29, 30, 37)
    hd.BorderSizePixel = 0
    hd.ZIndex = 21
    hd.Parent = FP.panel
    do local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 12) c.Parent = hd end
    local t = Instance.new("TextLabel")
    t.Size = UDim2.new(1, -20, 1, 0)
    t.Position = UDim2.fromOffset(10, 0)
    t.BackgroundTransparency = 1
    t.Text = "FLY"
    t.TextColor3 = Color3.fromRGB(245, 245, 250)
    t.TextSize = 13
    t.Font = Enum.Font.GothamBold
    t.TextXAlignment = Enum.TextXAlignment.Left
    t.ZIndex = 22
    t.Parent = hd
end

FP.enable = Instance.new("TextButton")
FP.enable.Size = UDim2.new(1, -20, 0, 36)
FP.enable.Position = UDim2.fromOffset(10, 52)
FP.enable.BackgroundColor3 = Color3.fromRGB(34, 36, 43)
FP.enable.BorderSizePixel = 0
FP.enable.Text = "Enable Fly"
FP.enable.TextColor3 = Color3.fromRGB(230, 230, 235)
FP.enable.TextSize = 13
FP.enable.Font = Enum.Font.GothamSemibold
FP.enable.AutoButtonColor = false
FP.enable.ZIndex = 21
FP.enable.Parent = FP.panel
do local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 8) c.Parent = FP.enable end

FP.enableInd = Instance.new("Frame")
FP.enableInd.Size = UDim2.fromOffset(5, 20)
FP.enableInd.Position = UDim2.fromOffset(8, 8)
FP.enableInd.BackgroundColor3 = Color3.fromRGB(80, 82, 90)
FP.enableInd.BorderSizePixel = 0
FP.enableInd.ZIndex = 22
FP.enableInd.Parent = FP.enable
do local c = Instance.new("UICorner") c.CornerRadius = UDim.new(1, 0) c.Parent = FP.enableInd end

FP.speedLbl = Instance.new("TextLabel")
FP.speedLbl.Size = UDim2.new(1, -20, 0, 20)
FP.speedLbl.Position = UDim2.fromOffset(10, 98)
FP.speedLbl.BackgroundTransparency = 1
FP.speedLbl.Text = "Speed: 50"
FP.speedLbl.TextColor3 = Color3.fromRGB(150, 153, 165)
FP.speedLbl.TextSize = 11
FP.speedLbl.Font = Enum.Font.GothamBold
FP.speedLbl.TextXAlignment = Enum.TextXAlignment.Left
FP.speedLbl.ZIndex = 21
FP.speedLbl.Parent = FP.panel

FP.minus = Instance.new("TextButton")
FP.minus.Size = UDim2.fromOffset(36, 32)
FP.minus.Position = UDim2.fromOffset(10, 123)
FP.minus.BackgroundColor3 = Color3.fromRGB(34, 36, 43)
FP.minus.BorderSizePixel = 0
FP.minus.Text = "-"
FP.minus.TextColor3 = Color3.fromRGB(235, 235, 240)
FP.minus.TextSize = 18
FP.minus.Font = Enum.Font.GothamBold
FP.minus.AutoButtonColor = false
FP.minus.ZIndex = 21
FP.minus.Parent = FP.panel
do local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 7) c.Parent = FP.minus end

FP.speedBox = Instance.new("TextBox")
FP.speedBox.Size = UDim2.new(1, -96, 0, 32)
FP.speedBox.Position = UDim2.fromOffset(52, 123)
FP.speedBox.BackgroundColor3 = Color3.fromRGB(34, 36, 43)
FP.speedBox.BorderSizePixel = 0
FP.speedBox.Text = "50"
FP.speedBox.TextColor3 = Color3.fromRGB(235, 235, 240)
FP.speedBox.TextSize = 12
FP.speedBox.Font = Enum.Font.GothamSemibold
FP.speedBox.ClearTextOnFocus = false
FP.speedBox.ZIndex = 21
FP.speedBox.Parent = FP.panel
do local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 7) c.Parent = FP.speedBox end

FP.plus = Instance.new("TextButton")
FP.plus.Size = UDim2.fromOffset(36, 32)
FP.plus.Position = UDim2.new(1, -46, 0, 123)
FP.plus.BackgroundColor3 = Color3.fromRGB(34, 36, 43)
FP.plus.BorderSizePixel = 0
FP.plus.Text = "+"
FP.plus.TextColor3 = Color3.fromRGB(235, 235, 240)
FP.plus.TextSize = 18
FP.plus.Font = Enum.Font.GothamBold
FP.plus.AutoButtonColor = false
FP.plus.ZIndex = 21
FP.plus.Parent = FP.panel
do local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 7) c.Parent = FP.plus end

FP.up = Instance.new("TextButton")
FP.up.Size = UDim2.fromOffset(85, 32)
FP.up.Position = UDim2.fromOffset(10, 168)
FP.up.BackgroundColor3 = Color3.fromRGB(34, 36, 43)
FP.up.BorderSizePixel = 0
FP.up.Text = "UP"
FP.up.TextColor3 = Color3.fromRGB(230, 230, 235)
FP.up.TextSize = 12
FP.up.Font = Enum.Font.GothamBold
FP.up.AutoButtonColor = false
FP.up.ZIndex = 21
FP.up.Parent = FP.panel
do local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 7) c.Parent = FP.up end

FP.down = Instance.new("TextButton")
FP.down.Size = UDim2.fromOffset(85, 32)
FP.down.Position = UDim2.new(1, -95, 0, 168)
FP.down.BackgroundColor3 = Color3.fromRGB(34, 36, 43)
FP.down.BorderSizePixel = 0
FP.down.Text = "DOWN"
FP.down.TextColor3 = Color3.fromRGB(230, 230, 235)
FP.down.TextSize = 12
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

U.flyBtn.MouseButton1Click:Connect(function()
    S.flyPanelOpen = not S.flyPanelOpen
    FP.panel.Visible = S.flyPanelOpen
    if S.flyPanelOpen then
        U.flyBtn.BackgroundColor3 = Color3.fromRGB(45, 47, 56)
    else
        if S.flyEnabled then setOn(U.flyBtn, U.flyInd) else setOff(U.flyBtn, U.flyInd) end
    end
end)

RunService.RenderStepped:Connect(function()
    if not S.flyEnabled or not flyBV or not flyBG then return end
    local c = player.Character
    if not c then stopFly() return end
    local r = c:FindFirstChild("HumanoidRootPart")
    local cam = workspace.CurrentCamera
    if not r or not cam then return end
    local dir = Vector3.zero
    if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir = dir + cam.CFrame.LookVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir = dir - cam.CFrame.LookVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir = dir - cam.CFrame.RightVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir = dir + cam.CFrame.RightVector end
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
U.shRow.Size = UDim2.new(1, 0, 0, 32)
U.shRow.BackgroundTransparency = 1
U.shRow.LayoutOrder = getLayoutOrder()
U.shRow.Parent = currentParent

U.shMinus = Instance.new("TextButton")
U.shMinus.Size = UDim2.fromOffset(36, 32)
U.shMinus.BackgroundColor3 = Color3.fromRGB(34, 36, 43)
U.shMinus.BorderSizePixel = 0
U.shMinus.Text = "-"
U.shMinus.TextColor3 = Color3.fromRGB(235, 235, 240)
U.shMinus.TextSize = 18
U.shMinus.Font = Enum.Font.GothamBold
U.shMinus.AutoButtonColor = false
U.shMinus.Parent = U.shRow
do local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 7) c.Parent = U.shMinus end

U.shBox = Instance.new("TextBox")
U.shBox.Size = UDim2.fromOffset(50, 32)
U.shBox.Position = UDim2.fromOffset(42, 0)
U.shBox.BackgroundColor3 = Color3.fromRGB(34, 36, 43)
U.shBox.BorderSizePixel = 0
U.shBox.Text = "45"
U.shBox.TextColor3 = Color3.fromRGB(235, 235, 240)
U.shBox.TextSize = 12
U.shBox.Font = Enum.Font.GothamSemibold
U.shBox.ClearTextOnFocus = false
U.shBox.Parent = U.shRow
do local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 7) c.Parent = U.shBox end

U.shPlus = Instance.new("TextButton")
U.shPlus.Size = UDim2.fromOffset(36, 32)
U.shPlus.Position = UDim2.fromOffset(100, 0)
U.shPlus.BackgroundColor3 = Color3.fromRGB(34, 36, 43)
U.shPlus.BorderSizePixel = 0
U.shPlus.Text = "+"
U.shPlus.TextColor3 = Color3.fromRGB(235, 235, 240)
U.shPlus.TextSize = 18
U.shPlus.Font = Enum.Font.GothamBold
U.shPlus.AutoButtonColor = false
U.shPlus.Parent = U.shRow
do local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 7) c.Parent = U.shPlus end

U.shLbl = Instance.new("TextLabel")
U.shLbl.Size = UDim2.new(1, -145, 0, 32)
U.shLbl.Position = UDim2.fromOffset(145, 0)
U.shLbl.BackgroundTransparency = 1
U.shLbl.Text = "WalkSpeed"
U.shLbl.TextColor3 = Color3.fromRGB(150, 153, 165)
U.shLbl.TextSize = 11
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

-- ============================================================
-- ESP TAB (role + gun merged)
-- ============================================================
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

-- ============================================================
-- NOTIFIER TAB
-- ============================================================
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

U.autoNotBtn, U.autoNotInd = createToggle("AutoNotifyRound", "Auto Notify Round")
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

U.autoChatBtn, U.autoChatInd = createToggle("AutoMurdererChat", "Auto Send Murderer In Chat")
U.autoChatBtn.MouseButton1Click:Connect(function()
    S.autoSendMurdererChat = not S.autoSendMurdererChat
    if S.autoSendMurdererChat then
        setOn(U.autoChatBtn, U.autoChatInd)
        S.lastChatSentMurderer = nil
        S.roundActive = false
    else
        setOff(U.autoChatBtn, U.autoChatInd)
        S.lastChatSentMurderer = nil
        S.roundActive = false
    end
end)

-- ============================================================
-- MURDERER TAB
-- ============================================================
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
    if not k then sendNotification("MM2 Menu", "No knife equipped!") return end
    local targets = {}
    for _, t in ipairs(Players:GetPlayers()) do
        if t ~= player and t.Character then
            local h = t.Character:FindFirstChildOfClass("Humanoid")
            local tr = t.Character:FindFirstChild("HumanoidRootPart")
            if h and h.Health > 0 and tr then table.insert(targets, tr) end
        end
    end
    for _, tr in ipairs(targets) do
        mr.CFrame = tr.CFrame * CFrame.new(0, 0, 1.5)
        task.wait()
        pcall(function() k:Activate() end)
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

-- ============================================================
-- SHERIFF TAB
-- ============================================================
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
    if not MurdererName then sendNotification("MM2 Menu", "Murderer not found yet!") return end
    local t = Players:FindFirstChild(MurdererName)
    if not t or not t.Character then return end
    if isPlayerInSpawn(t) then sendNotification("MM2 Menu", "Murderer is in spawn/lobby!") return end
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
            sendNotification("MM2 Menu", "You do not have a Gun equipped!")
        end
    end
end

U.killMurdererBtn = createActionButton("KillMurdererNow", "Kill Murderer Now")
U.killMurdererBtn.MouseButton1Click:Connect(shootMurderer)

-- ============================================================
-- TELEPORT TAB
-- ============================================================
currentParent = U.tabFrames.Teleport
createSectionTitle("TELEPORT")

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
    if c:FindFirstChild("Gun") then return end
    if c:FindFirstChild("Knife") then return end
    local mr = c:FindFirstChild("HumanoidRootPart")
    if not mr then return end
    local tp = findGunPart()
    if not tp then return end
    lastAutoGunTP = now
    mr.CFrame = tp.CFrame + Vector3.new(0, 3, 0)
    task.wait(0.15)
    mr.CFrame = CFrame.new(tp.Position.X, 300, tp.Position.Z)
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
    if not tpGunAndBack() then sendNotification("MM2 Menu", "No dropped gun found on the map!") end
end)

U.playerTpBtn = createActionButton("PlayerTeleport", "Teleport To Player")
U.killSelBtn = createActionButton("KillSelectedPlayer", "Kill Selected Player")

U.pDropdown = Instance.new("TextButton")
U.pDropdown.Size = UDim2.new(1, 0, 0, 34)
U.pDropdown.BackgroundColor3 = Color3.fromRGB(34, 36, 43)
U.pDropdown.BorderSizePixel = 0
U.pDropdown.Text = "Select Player"
U.pDropdown.TextColor3 = Color3.fromRGB(230, 230, 235)
U.pDropdown.TextSize = 12
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
            o.Size = UDim2.new(1, -10, 0, 30)
            o.BackgroundColor3 = Color3.fromRGB(34, 36, 43)
            o.BorderSizePixel = 0
            o.Text = t.DisplayName .. " (@" .. t.Name .. ")"
            o.TextColor3 = Color3.fromRGB(230, 230, 235)
            o.TextSize = 12
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
        U.pList.Size = UDim2.new(1, 0, 0, 120)
    else
        U.pList.Visible = false
        U.pList.Size = UDim2.new(1, 0, 0, 0)
    end
end)

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

-- ============================================================
-- UTILITY TAB
-- ============================================================
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

U.rejoinBtn = createActionButton("Rejoin", "Rejoin Server")
U.rejoinBtn.MouseButton1Click:Connect(function()
    sendNotification("MM2 Menu", "Rejoining server...")
    task.wait(0.5)
    local ok = pcall(function() TeleportService:Teleport(game.PlaceId, player) end)
    if not ok then
        pcall(function() TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, player) end)
    end
end)

local function resetAllToggles()
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
    if S.autoNotifyRoles then S.autoNotifyRoles = false setOff(U.autoNotBtn, U.autoNotInd) end
    if S.autoSendMurdererChat then
        S.autoSendMurdererChat = false
        setOff(U.autoChatBtn, U.autoChatInd)
        S.lastChatSentMurderer = nil
        S.roundActive = false
    end
    if S.autoKillAll then S.autoKillAll = false setOff(U.autoKillBtn, U.autoKillInd) end
    if S.autoGunTP then S.autoGunTP = false setOff(U.autoGunBtn, U.autoGunInd) end
    if S.antiVoidEnabled then S.antiVoidEnabled = false setOff(U.avBtn, U.avInd) end
    if S.antiFlingEnabled then S.antiFlingEnabled = false setOff(U.afBtn, U.afInd) end
    sendNotification("MM2 Menu", "All features turned off")
end

U.turnOffBtn = Instance.new("TextButton")
U.turnOffBtn.Size = UDim2.new(1, 0, 0, 34)
U.turnOffBtn.BackgroundColor3 = Color3.fromRGB(70, 40, 40)
U.turnOffBtn.BorderSizePixel = 0
U.turnOffBtn.Text = "TURN OFF ALL"
U.turnOffBtn.TextColor3 = Color3.fromRGB(255, 200, 200)
U.turnOffBtn.TextSize = 12
U.turnOffBtn.Font = Enum.Font.GothamBold
U.turnOffBtn.AutoButtonColor = false
U.turnOffBtn.LayoutOrder = getLayoutOrder()
U.turnOffBtn.Parent = currentParent
do local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 8) c.Parent = U.turnOffBtn end
U.turnOffBtn.MouseButton1Click:Connect(resetAllToggles)

-- ============================================================
-- ESP SYSTEM
-- ============================================================
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
    if isPlayerInSpawn(t) then return false end
    return true
end

local function getRoles()
    if not GetPlayerData then
        if not warnedNoRemote then
            warnedNoRemote = true
            sendNotification("MM2 Menu", "GetPlayerData remote not found - role features disabled")
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
        lastNotifiedMurderer = nil
        S.lastChatSentMurderer = nil
        S.roundActive = false
        noMurdererSince = tick()
    end
    if nS and validHolder(nS) then
        SheriffName = nS
    elseif SheriffName and not validHolder(SheriffName) then
        SheriffName = nil
        lastNotifiedSheriff = nil
    end
    if nH and validHolder(nH) then
        HeroName = nH
    elseif HeroName and not validHolder(HeroName) then
        HeroName = nil
        lastNotifiedHero = nil
    end

    if MurdererName == nil and noMurdererSince and (tick() - noMurdererSince) >= ROUND_END_DEBOUNCE then
        MurdererName = nil
        SheriffName = nil
        HeroName = nil
        lastNotifiedMurderer = nil
        lastNotifiedSheriff = nil
        lastNotifiedHero = nil
        S.lastChatSentMurderer = nil
        S.roundActive = false
        S.pendingNotify = false
        noMurdererSince = nil
    end

    if S.autoNotifyRoles then
        local changed = (MurdererName and MurdererName ~= lastNotifiedMurderer)
            or (SheriffName and SheriffName ~= lastNotifiedSheriff)
            or (HeroName and HeroName ~= lastNotifiedHero)
        if changed then
            if not S.pendingNotify then
                S.pendingNotify = true
                S.pendingNotifySince = tick()
            elseif tick() - S.pendingNotifySince >= 0.5 then
                lastNotifiedMurderer = MurdererName
                lastNotifiedSheriff = SheriffName
                lastNotifiedHero = HeroName
                S.pendingNotify = false
                notifyAllRoles()
            end
        else
            S.pendingNotify = false
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

local function rmHL(t)
    if t.Character then
        local h = t.Character:FindFirstChild("RoleESP")
        if h then h:Destroy() end
    end
    highlights[t] = nil
end

for _, t in ipairs(Players:GetPlayers()) do
    if t ~= player then
        t.CharacterAdded:Connect(function()
            task.wait(0.2)
            mkHL(t)
            updateHL()
        end)
        if t.Character then mkHL(t) end
    end
end
Players.PlayerAdded:Connect(function(t)
    t.CharacterAdded:Connect(function()
        task.wait(0.2)
        mkHL(t)
        updateHL()
    end)
end)
Players.PlayerRemoving:Connect(function(t)
    rmHL(t)
    if MurdererName == t.Name then MurdererName = nil end
    if SheriffName == t.Name then SheriffName = nil end
    if HeroName == t.Name then HeroName = nil end
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

local function checkAutoChat()
    if not S.autoSendMurdererChat then return end
    if not MurdererName then
        if S.roundActive then S.roundActive = false S.lastChatSentMurderer = nil end
        return
    end
    if not S.roundActive then S.roundActive = true S.lastChatSentMurderer = nil end
    if S.lastChatSentMurderer == MurdererName then return end
    local now = tick()
    if now - S.chatSendCooldown < 1 then return end
    local tp = Players:FindFirstChild(MurdererName)
    local dt = MurdererName
    if tp then dt = tp.DisplayName .. " (@" .. tp.Name .. ")" end
    if sendChat("Murderer is: " .. dt) then
        S.lastChatSentMurderer = MurdererName
        S.chatSendCooldown = now
    end
end

RunService.Stepped:Connect(function()
    if not S.noclip or not player.Character then return end
    for _, o in ipairs(player.Character:GetDescendants()) do
        if o:IsA("BasePart") then o.CanCollide = false end
    end
end)

RunService.Heartbeat:Connect(function()
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
    updateHL()
end)

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
UserInputService.InputEnded:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
        S.dragging = false
        S.resizing = false
        S.reopenDragging = false
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
        U.frame.Size = UDim2.fromOffset(math.max(380, resizeStartSize.X + d.X), math.max(280, resizeStartSize.Y + d.Y))
    end
end)

U.reopen.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
        S.reopenDragging = true
        reopenDragStart = i.Position
        reopenDragStartPosition = U.reopen.Position
    end
end)
UserInputService.InputChanged:Connect(function(i)
    if not S.reopenDragging then return end
    if i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch then
        local d = i.Position - reopenDragStart
        U.reopen.Position = UDim2.new(reopenDragStartPosition.X.Scale, reopenDragStartPosition.X.Offset + d.X, reopenDragStartPosition.Y.Scale, reopenDragStartPosition.Y.Offset + d.Y)
    end
end)

local function showMenu()
    S.menuVisible = true
    U.frame.Visible = true
    U.reopen.Visible = false
end
local function minimizeMenu()
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
    sendNotification("MM2 Menu", "Script closed.")
    pcall(function() U.gui:Destroy() end)
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
U.reopen.MouseButton1Click:Connect(showMenu)
UserInputService.InputBegan:Connect(function(i, p)
    if p then return end
    if i.KeyCode == Enum.KeyCode.RightShift then
        if S.menuVisible then minimizeMenu() else showMenu() end
    end
end)

RunService.Heartbeat:Connect(function()
    local hue = (tick() * RAINBOW_SPEED) % 1
    local color = Color3.fromHSV(hue, 1, 1)
    U.frameStroke.Color = color
    U.reopenStroke.Color = color
    FP.stroke.Color = color
    U.titleGradient.Rotation = (tick() * 60) % 360
end)

getRoles()
updateHL()
updateGunESP()
task.spawn(function()
    while U.gui.Parent do
        pcall(function()
            getRoles()
            updateHL()
            updateGunESP()
            if S.autoKillAll and MurdererName == player.Name then killAllPlayers() end
            if S.autoGunTP then autoTPGunTop() end
            checkAutoChat()
        end)
        task.wait(0.25)
    end
end)