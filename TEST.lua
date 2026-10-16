-- Replace the old Speedhack section with this:
createSectionTitle("SPEEDHACK")

U.shBtn, U.shInd = createToggle("Speedhack", "Speedhack (Safe)")
local shBV = nil
local SPEEDHACK_MAX = 32 -- Keep it just above default 16
local SPEEDHACK_DEFAULT = 20

U.shRow = Instance.new("Frame")
U.shRow.Size = UDim2.new(1, 0, 0, mn(30))
U.shRow.BackgroundTransparency = 1
U.shRow.LayoutOrder = getLayoutOrder()
U.shRow.Parent = currentParent

-- ... (Keep the minus, box, plus buttons and shLbl UI identical) ...

local function stopSpeedhack()
    S.speedhackEnabled = false
    if shBV then shBV:Destroy() shBV = nil end
    local c = player.Character
    if c then
        local h = c:FindFirstChildOfClass("Humanoid")
        if h then h.WalkSpeed = 16 end
    end
    setOff(U.shBtn, U.shInd)
end

local function startSpeedhack()
    stopSpeedhack()
    local c = player.Character
    if not c then return end
    local h = c:FindFirstChildOfClass("Humanoid")
    local r = c:FindFirstChild("HumanoidRootPart")
    if not h or not r then return end
    S.speedhackEnabled = true
    setOn(U.shBtn, U.shInd)

    shBV = Instance.new("BodyVelocity")
    shBV.MaxForce = Vector3.new(10000, 0, 10000) -- Horizontal only
    shBV.P = 500
    shBV.Parent = r

    -- Apply a safe WalkSpeed in case the BodyVelocity is bypassed
    h.WalkSpeed = 16
end

U.shBtn.MouseButton1Click:Connect(function()
    if S.speedhackEnabled then stopSpeedhack() else startSpeedhack() end
end)

-- Update the loop that applies the body velocity:
RunService.Heartbeat:Connect(function()
    if not S.speedhackEnabled or not shBV then return end
    local c = player.Character
    if not c then return end
    local h = c:FindFirstChildOfClass("Humanoid")
    local r = c:FindFirstChild("HumanoidRootPart")
    if not h or not r then return end

    -- Only apply speed when actively moving on the ground
    if h.MoveDirection.Magnitude > 0 and h.FloorMaterial ~= Enum.Material.Air then
        -- Apply a smooth velocity proportional to the desired speed
        shBV.Velocity = h.MoveDirection * S.speedhackSpeed
    else
        shBV.Velocity = Vector3.zero
    end
end)