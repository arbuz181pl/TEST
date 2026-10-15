--//==================================================
--// SCRIPTS BY ARBUZ - Launcher
--//==================================================

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")
local MarketplaceService = game:GetService("MarketplaceService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

--==================================================
-- MM2 GAME IDS
--==================================================

local MM2_PLACE_IDS = {
	[142823291] = true,
	[121787682648572] = true,
}

--==================================================
-- NOTIFICATION UTILITY
--==================================================

local function sendNotification(title, text)
	pcall(function()
		StarterGui:SetCore("SendNotification", {
			Title = title,
			Text = text,
			Duration = 5
		})
	end)
end

--==================================================
-- GAME CHECK
--==================================================

local function isInMM2()
	if MM2_PLACE_IDS[game.PlaceId] then
		return true, "PlaceId matched"
	end

	local ok, result = pcall(function()
		return MarketplaceService:GetProductInfo(game.PlaceId).Name
	end)

	if ok and result then
		if string.find(string.lower(result), "murder mystery 2", 1, true) then
			return true, "Name matched"
		end
		return false, "Current game: " .. tostring(result)
	end

	return false, "Could not verify game name"
end

--==================================================
-- CLEANUP
--==================================================

local function destroyExistingGuis()
	local names = { "ScriptsByArbuz", "MM2MenuByArbuz" }
	for _, name in ipairs(names) do
		local existing = playerGui:FindFirstChild(name)
		if existing then
			existing:Destroy()
		end
	end
end

destroyExistingGuis()

--==================================================
-- GUI
--==================================================

local gui = Instance.new("ScreenGui")
gui.Name = "ScriptsByArbuz"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.IgnoreGuiInset = false
gui.Enabled = true
gui.DisplayOrder = 100
gui.Parent = playerGui

--==================================================
-- MAIN FRAME
--==================================================

local frame = Instance.new("Frame")
frame.Name = "Main"
frame.Size = UDim2.fromOffset(280, 330)
frame.Position = UDim2.new(0.5, -140, 0.5, -165)
frame.BackgroundColor3 = Color3.fromRGB(22, 23, 28)
frame.BorderSizePixel = 0
frame.Visible = true
frame.Active = true
frame.Parent = gui

local frameCorner = Instance.new("UICorner")
frameCorner.CornerRadius = UDim.new(0, 12)
frameCorner.Parent = frame

local frameStroke = Instance.new("UIStroke")
frameStroke.Color = Color3.fromRGB(55, 57, 65)
frameStroke.Thickness = 1
frameStroke.Parent = frame

--==================================================
-- HEADER
--==================================================

local header = Instance.new("Frame")
header.Name = "Header"
header.Size = UDim2.new(1, 0, 0, 48)
header.BackgroundColor3 = Color3.fromRGB(29, 30, 37)
header.BorderSizePixel = 0
header.Active = true
header.Parent = frame

local headerCorner = Instance.new("UICorner")
headerCorner.CornerRadius = UDim.new(0, 12)
headerCorner.Parent = header

--==================================================
-- TITLE
--==================================================

local title = Instance.new("TextLabel")
title.Name = "Title"
title.Size = UDim2.new(1, -120, 1, 0)
title.Position = UDim2.fromOffset(10, 0)
title.BackgroundTransparency = 1
title.Text = "SCRIPTS BY ARBUZ"
title.TextColor3 = Color3.fromRGB(245, 245, 250)
title.TextSize = 12
title.Font = Enum.Font.GothamBold
title.TextXAlignment = Enum.TextXAlignment.Left
title.TextYAlignment = Enum.TextYAlignment.Center
title.ZIndex = 2
title.Parent = header

--==================================================
-- CLOSE BUTTON
--==================================================

local closeButton = Instance.new("TextButton")
closeButton.Name = "Close"
closeButton.Size = UDim2.fromOffset(30, 30)
closeButton.Position = UDim2.new(1, -105, 0.5, -15)
closeButton.BackgroundColor3 = Color3.fromRGB(42, 44, 52)
closeButton.Text = "X"
closeButton.TextSize = 16
closeButton.TextColor3 = Color3.fromRGB(255, 200, 200)
closeButton.Font = Enum.Font.GothamBold
closeButton.BorderSizePixel = 0
closeButton.AutoButtonColor = false
closeButton.Active = true
closeButton.ZIndex = 5
closeButton.Parent = header

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 7)
closeCorner.Parent = closeButton

--==================================================
-- LOCK BUTTON
--==================================================

local lockButton = Instance.new("TextButton")
lockButton.Name = "Lock"
lockButton.Size = UDim2.fromOffset(30, 30)
lockButton.Position = UDim2.new(1, -70, 0.5, -15)
lockButton.BackgroundColor3 = Color3.fromRGB(42, 44, 52)
lockButton.Text = "🔓"
lockButton.TextSize = 14
lockButton.TextColor3 = Color3.new(1, 1, 1)
lockButton.Font = Enum.Font.GothamBold
lockButton.BorderSizePixel = 0
lockButton.AutoButtonColor = false
lockButton.Active = true
lockButton.ZIndex = 5
lockButton.Parent = header

local lockCorner = Instance.new("UICorner")
lockCorner.CornerRadius = UDim.new(0, 7)
lockCorner.Parent = lockButton

--==================================================
-- MINIMIZE BUTTON
--==================================================

local minimizeButton = Instance.new("TextButton")
minimizeButton.Name = "Minimize"
minimizeButton.Size = UDim2.fromOffset(30, 30)
minimizeButton.Position = UDim2.new(1, -35, 0.5, -15)
minimizeButton.BackgroundColor3 = Color3.fromRGB(42, 44, 52)
minimizeButton.Text = "-"
minimizeButton.TextColor3 = Color3.new(1, 1, 1)
minimizeButton.TextSize = 17
minimizeButton.Font = Enum.Font.GothamBold
minimizeButton.BorderSizePixel = 0
minimizeButton.AutoButtonColor = false
minimizeButton.Active = true
minimizeButton.ZIndex = 5
minimizeButton.Parent = header

local minimizeCorner = Instance.new("UICorner")
minimizeCorner.CornerRadius = UDim.new(0, 7)
minimizeCorner.Parent = minimizeButton

--==================================================
-- RESIZE HANDLE
--==================================================

local resizeHandle = Instance.new("TextButton")
resizeHandle.Name = "ResizeHandle"
resizeHandle.Size = UDim2.fromOffset(16, 16)
resizeHandle.Position = UDim2.new(1, -16, 1, -16)
resizeHandle.BackgroundColor3 = Color3.fromRGB(55, 57, 65)
resizeHandle.BorderSizePixel = 0
resizeHandle.Text = ""
resizeHandle.AutoButtonColor = false
resizeHandle.Active = true
resizeHandle.ZIndex = 30
resizeHandle.Parent = frame

local resizeCorner = Instance.new("UICorner")
resizeCorner.CornerRadius = UDim.new(0, 4)
resizeCorner.Parent = resizeHandle

local MIN_WIDTH = 240
local MIN_HEIGHT = 200

local resizing = false
local resizeStart
local resizeStartSize

resizeHandle.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		resizing = true
		resizeStart = input.Position
		resizeStartSize = frame.AbsoluteSize
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if not resizing then return end
	if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
		local delta = input.Position - resizeStart
		local newWidth = math.max(MIN_WIDTH, resizeStartSize.X + delta.X)
		local newHeight = math.max(MIN_HEIGHT, resizeStartSize.Y + delta.Y)
		frame.Size = UDim2.fromOffset(newWidth, newHeight)
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		resizing = false
	end
end)

--==================================================
-- REOPEN BUTTON
--==================================================

local reopenButton = Instance.new("TextButton")
reopenButton.Name = "Reopen"
reopenButton.Size = UDim2.fromOffset(50, 50)
reopenButton.Position = UDim2.new(0, 15, 0.5, -25)
reopenButton.BackgroundColor3 = Color3.fromRGB(29, 30, 37)
reopenButton.BorderSizePixel = 0
reopenButton.Text = "ARB"
reopenButton.TextColor3 = Color3.fromRGB(245, 245, 250)
reopenButton.TextSize = 13
reopenButton.Font = Enum.Font.GothamBold
reopenButton.AutoButtonColor = false
reopenButton.Active = true
reopenButton.Visible = false
reopenButton.ZIndex = 50
reopenButton.Parent = gui

local reopenCorner = Instance.new("UICorner")
reopenCorner.CornerRadius = UDim.new(1, 0)
reopenCorner.Parent = reopenButton

local reopenStroke = Instance.new("UIStroke")
reopenStroke.Color = Color3.fromRGB(80, 82, 90)
reopenStroke.Thickness = 2
reopenStroke.Parent = reopenButton

--==================================================
-- CONTENT
--==================================================

local content = Instance.new("ScrollingFrame")
content.Name = "Content"
content.Size = UDim2.new(1, -20, 1, -58)
content.Position = UDim2.fromOffset(10, 53)
content.BackgroundTransparency = 1
content.BorderSizePixel = 0
content.ScrollBarThickness = 5
content.ScrollBarImageColor3 = Color3.fromRGB(75, 77, 85)
content.CanvasSize = UDim2.fromOffset(0, 0)
content.AutomaticCanvasSize = Enum.AutomaticSize.Y
content.ScrollingDirection = Enum.ScrollingDirection.Y
content.Parent = frame

local contentLayout = Instance.new("UIListLayout")
contentLayout.Padding = UDim.new(0, 6)
contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
contentLayout.Parent = content

local currentLayoutOrder = 0
local function getLayoutOrder()
	currentLayoutOrder = currentLayoutOrder + 1
	return currentLayoutOrder
end

--==================================================
-- HELPERS
--==================================================

local function createSectionTitle(text)
	local label = Instance.new("TextLabel")
	label.Name = text .. "Header"
	label.Size = UDim2.new(1, 0, 0, 20)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = Color3.fromRGB(150, 153, 165)
	label.TextSize = 11
	label.Font = Enum.Font.GothamBold
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.LayoutOrder = getLayoutOrder()
	label.Parent = content
	return label
end

local function createScriptButton(name, text)
	local button = Instance.new("TextButton")
	button.Name = name
	button.Size = UDim2.new(1, 0, 0, 40)
	button.BackgroundColor3 = Color3.fromRGB(34, 36, 43)
	button.BorderSizePixel = 0
	button.Text = text
	button.TextColor3 = Color3.fromRGB(230, 230, 235)
	button.TextSize = 13
	button.Font = Enum.Font.GothamSemibold
	button.AutoButtonColor = false
	button.LayoutOrder = getLayoutOrder()
	button.Parent = content

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = button

	local indicator = Instance.new("Frame")
	indicator.Name = "Indicator"
	indicator.Size = UDim2.fromOffset(5, 20)
	indicator.Position = UDim2.fromOffset(8, 10)
	indicator.BackgroundColor3 = Color3.fromRGB(80, 82, 90)
	indicator.BorderSizePixel = 0
	indicator.Parent = button

	local indicatorCorner = Instance.new("UICorner")
	indicatorCorner.CornerRadius = UDim.new(1, 0)
	indicatorCorner.Parent = indicator

	button.MouseEnter:Connect(function()
		button.BackgroundColor3 = Color3.fromRGB(45, 47, 56)
	end)

	button.MouseLeave:Connect(function()
		button.BackgroundColor3 = Color3.fromRGB(34, 36, 43)
	end)

	return button, indicator
end

--==================================================
-- SEARCH BAR
--==================================================

local searchBox = Instance.new("TextBox")
searchBox.Name = "SearchBox"
searchBox.Size = UDim2.new(1, 0, 0, 36)
searchBox.BackgroundColor3 = Color3.fromRGB(34, 36, 43)
searchBox.BorderSizePixel = 0
searchBox.Text = ""
searchBox.PlaceholderText = "Search scripts..."
searchBox.PlaceholderColor3 = Color3.fromRGB(150, 153, 165)
searchBox.TextColor3 = Color3.fromRGB(230, 230, 235)
searchBox.TextSize = 13
searchBox.Font = Enum.Font.GothamSemibold
searchBox.ClearTextOnFocus = false
searchBox.LayoutOrder = getLayoutOrder()
searchBox.Parent = content

local searchCorner = Instance.new("UICorner")
searchCorner.CornerRadius = UDim.new(0, 8)
searchCorner.Parent = searchBox

local searchPadding = Instance.new("UIPadding")
searchPadding.PaddingLeft = UDim.new(0, 10)
searchPadding.PaddingRight = UDim.new(0, 10)
searchPadding.Parent = searchBox

--==================================================
-- SCRIPT LIST
--==================================================

createSectionTitle("SCRIPTS")

local scriptButtons = {}

local function registerScriptButton(name, button)
	table.insert(scriptButtons, { Name = name, Button = button })
end

--==================================================
-- CLOSE / REOPEN LOGIC
--==================================================

local menuVisible = true

local function showMenu()
	menuVisible = true
	frame.Visible = true
	reopenButton.Visible = false
end

local function hideMenu()
	menuVisible = false
	frame.Visible = false
	reopenButton.Visible = true
end

--==================================================
-- MM2 SCRIPT BUTTON
--==================================================

local mm2Button, mm2Indicator = createScriptButton("MM2", "MM2")
mm2Indicator.BackgroundColor3 = Color3.fromRGB(230, 55, 55)

local mm2SubLabel = Instance.new("TextLabel")
mm2SubLabel.Name = "SubLabel"
mm2SubLabel.Size = UDim2.new(1, -30, 0, 12)
mm2SubLabel.Position = UDim2.new(0, 22, 1, -14)
mm2SubLabel.BackgroundTransparency = 1
mm2SubLabel.Text = "Murder Mystery 2 only"
mm2SubLabel.TextColor3 = Color3.fromRGB(150, 153, 165)
mm2SubLabel.TextSize = 10
mm2SubLabel.Font = Enum.Font.GothamBold
mm2SubLabel.TextXAlignment = Enum.TextXAlignment.Left
mm2SubLabel.ZIndex = 3
mm2SubLabel.Parent = mm2Button

local function resetMm2Button()
	mm2Button.Text = "MM2"
	mm2Button.TextColor3 = Color3.fromRGB(230, 230, 235)
	mm2Indicator.BackgroundColor3 = Color3.fromRGB(230, 55, 55)
end

mm2Button.MouseButton1Click:Connect(function()
	--==================================================
	-- STEP 1: GAME CHECK
	--==================================================
	local inMM2, reason = isInMM2()
	if not inMM2 then
		mm2Button.Text = "Wrong game"
		mm2Button.TextColor3 = Color3.fromRGB(255, 100, 100)
		mm2Indicator.BackgroundColor3 = Color3.fromRGB(255, 100, 100)
		sendNotification("Scripts by Arbuz", "MM2 only works in Murder Mystery 2.\n" .. tostring(reason))
		warn("[Scripts by Arbuz] Not in MM2 - " .. tostring(reason))
		task.wait(2)
		resetMm2Button()
		return
	end

	--==================================================
	-- STEP 2: DOWNLOAD
	--==================================================
	mm2Button.Text = "Downloading..."
	mm2Button.TextColor3 = Color3.fromRGB(255, 205, 50)
	mm2Indicator.BackgroundColor3 = Color3.fromRGB(255, 205, 50)

	local url = "https://raw.githubusercontent.com/arbuz181pl/MM2-MENU-BY-ARBUZ/refs/heads/main/MM2MENU.lua"
	local downloadOk, content = pcall(function()
		return game:HttpGet(url .. "?v=" .. tick())
	end)

	if not downloadOk then
		mm2Button.Text = "Download failed"
		mm2Button.TextColor3 = Color3.fromRGB(255, 100, 100)
		mm2Indicator.BackgroundColor3 = Color3.fromRGB(255, 100, 100)
		sendNotification("Scripts by Arbuz", "Failed to download MM2 script.\n" .. tostring(content))
		warn("[Scripts by Arbuz] HttpGet failed:", content)
		task.wait(3)
		resetMm2Button()
		return
	end

	if not content or #content == 0 then
		mm2Button.Text = "Empty file"
		mm2Button.TextColor3 = Color3.fromRGB(255, 100, 100)
		mm2Indicator.BackgroundColor3 = Color3.fromRGB(255, 100, 100)
		sendNotification("Scripts by Arbuz", "Downloaded file is empty. Check the URL.")
		warn("[Scripts by Arbuz] Downloaded content is empty")
		task.wait(3)
		resetMm2Button()
		return
	end

	--==================================================
	-- STEP 3: COMPILE
	--==================================================
	mm2Button.Text = "Compiling..."
	mm2Button.TextColor3 = Color3.fromRGB(255, 205, 50)
	mm2Indicator.BackgroundColor3 = Color3.fromRGB(255, 205, 50)

	local fn, compileErr = loadstring(content)
	if not fn then
		mm2Button.Text = "Compile error"
		mm2Button.TextColor3 = Color3.fromRGB(255, 100, 100)
		mm2Indicator.BackgroundColor3 = Color3.fromRGB(255, 100, 100)
		sendNotification("Scripts by Arbuz", "MM2 script has a syntax error. Check F9.")
		warn("[Scripts by Arbuz] Compile error:", compileErr)
		task.wait(3)
		resetMm2Button()
		return
	end

	--==================================================
	-- STEP 4: CLOSE LAUNCHER FIRST, THEN RUN MM2
	--==================================================
	-- We destroy the launcher BEFORE running MM2 so it disappears
	-- immediately, regardless of whether MM2 yields, errors, or blocks.
	sendNotification("Scripts by Arbuz", "Loading MM2...")
	gui:Destroy()

	-- Give one frame for the GUI to actually disappear
	task.wait(0.1)

	-- Run MM2 in a separate thread so the launcher's click handler
	-- doesn't block on it and errors are logged cleanly.
	task.spawn(function()
		local runOk, runErr = pcall(fn)
		if not runOk then
			warn("[Scripts by Arbuz] MM2 runtime error:", runErr)
			pcall(function()
				StarterGui:SetCore("SendNotification", {
					Title = "Scripts by Arbuz",
					Text = "MM2 script crashed. Check F9.",
					Duration = 5
				})
			end)
		end
	end)
end)

registerScriptButton("MM2", mm2Button)

--==================================================
-- SEARCH FILTER
--==================================================

searchBox:GetPropertyChangedSignal("Text"):Connect(function()
	local query = string.lower(searchBox.Text)

	for _, entry in ipairs(scriptButtons) do
		if entry.Button and entry.Button.Parent then
			local matches = query == "" or string.find(string.lower(entry.Name), query, 1, true)
			entry.Button.Visible = matches
		end
	end
end)

--==================================================
-- DRAG MENU
--==================================================

local guiLocked = false
local dragging = false
local dragStart
local dragStartPosition

header.InputBegan:Connect(function(input)
	if guiLocked then return end
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		dragStart = input.Position
		dragStartPosition = frame.Position
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if not dragging or guiLocked then return end
	if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
		local delta = input.Position - dragStart
		frame.Position = UDim2.new(
			dragStartPosition.X.Scale, dragStartPosition.X.Offset + delta.X,
			dragStartPosition.Y.Scale, dragStartPosition.Y.Offset + delta.Y
		)
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = false
	end
end)

--==================================================
-- LOCK / MINIMIZE / CLOSE / REOPEN
--==================================================

local minimized = false

lockButton.MouseButton1Click:Connect(function()
	guiLocked = not guiLocked
	if guiLocked then
		lockButton.Text = "🔒"
		lockButton.BackgroundColor3 = Color3.fromRGB(70, 45, 45)
	else
		lockButton.Text = "🔓"
		lockButton.BackgroundColor3 = Color3.fromRGB(42, 44, 52)
	end
end)

minimizeButton.MouseButton1Click:Connect(function()
	minimized = not minimized
	if minimized then
		content.Visible = false
		frame.Size = UDim2.fromOffset(280, 48)
		minimizeButton.Text = "+"
	else
		content.Visible = true
		frame.Size = UDim2.fromOffset(280, 330)
		minimizeButton.Text = "-"
	end
end)

closeButton.MouseButton1Click:Connect(function()
	hideMenu()
	sendNotification("Scripts by Arbuz", "Launcher closed. Press Right Shift to reopen.")
end)

closeButton.MouseEnter:Connect(function()
	closeButton.BackgroundColor3 = Color3.fromRGB(180, 55, 55)
end)

closeButton.MouseLeave:Connect(function()
	closeButton.BackgroundColor3 = Color3.fromRGB(42, 44, 52)
end)

reopenButton.MouseButton1Click:Connect(function()
	showMenu()
end)

UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end
	if input.KeyCode == Enum.KeyCode.RightShift then
		if not gui.Parent then return end
		if menuVisible then
			hideMenu()
		else
			showMenu()
		end
	end
end)

local reopenDragging = false
local reopenDragStart
local reopenDragStartPosition

reopenButton.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		reopenDragging = true
		reopenDragStart = input.Position
		reopenDragStartPosition = reopenButton.Position
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if not reopenDragging then return end
	if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
		local delta = input.Position - reopenDragStart
		reopenButton.Position = UDim2.new(
			reopenDragStartPosition.X.Scale, reopenDragStartPosition.X.Offset + delta.X,
			reopenDragStartPosition.Y.Scale, reopenDragStartPosition.Y.Offset + delta.Y
		)
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		reopenDragging = false
	end
end)
