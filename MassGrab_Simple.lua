--[[
    ╔══════════════════════════════════════════════════════════╗
    ║          MASS GRAB LAUNCHER - SIMPLE EDITION             ║
    ║   All Map Parts Orbit + ALL Other Players Launched       ║
    ╚══════════════════════════════════════════════════════════╝
]]

local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local TweenService      = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player    = Players.LocalPlayer
local PlayerGui = player:WaitForChild("PlayerGui")

-- ══════════════════════════════════════════════════════════
-- GRAB REMOTE
-- ══════════════════════════════════════════════════════════
local SetNetworkOwner = ReplicatedStorage:WaitForChild("GrabEvents"):WaitForChild("SetNetworkOwner")

-- ══════════════════════════════════════════════════════════
-- STATE
-- ══════════════════════════════════════════════════════════
local grabbedParts = {}
local connections  = {}
local orbitAngle   = 0
local bounceAngle  = 0
local isRunning    = false

-- ══════════════════════════════════════════════════════════
-- SKIP LIST — SEMUA part milik siapapun yang merupakan karakter
-- ══════════════════════════════════════════════════════════
local function isCharacterPart(part)
    -- Cek apakah part milik karakter player MANAPUN (termasuk executor)
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Character and part:IsDescendantOf(p.Character) then
            return true
        end
    end
    return false
end

local function isBaseBlacklisted(part)
    local n = part.Name:lower()
    return n == "baseplate" or n == "spawnlocation" or n == "terrain"
end

-- ══════════════════════════════════════════════════════════
-- KUMPULKAN SEMUA PART DI MAP (tanpa radius limit)
-- ══════════════════════════════════════════════════════════
local function collectAllMapParts()
    local result = {}
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart")
            and not isBaseBlacklisted(obj)
            and not isCharacterPart(obj)   -- ← skip semua karakter
            and not obj.Locked
            and obj.Parent ~= nil
        then
            table.insert(result, obj)
        end
    end
    return result
end

-- ══════════════════════════════════════════════════════════
-- LAUNCH SEMUA PLAYER LAIN (bukan executor)
-- ══════════════════════════════════════════════════════════
local function launchAllOtherPlayers()
    local count = 0
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= player and p.Character then
            -- Launch setiap BasePart di karakter mereka
            for _, part in ipairs(p.Character:GetDescendants()) do
                if part:IsA("BasePart") then
                    pcall(function()
                        part.Anchored = false
                        part.AssemblyLinearVelocity = Vector3.new(
                            math.random(-40, 40),
                            math.random(300, 600),
                            math.random(-40, 40)
                        )
                        part.AssemblyAngularVelocity = Vector3.new(
                            math.random(-20, 20),
                            math.random(-20, 20),
                            math.random(-20, 20)
                        )
                    end)
                end
            end
            count = count + 1
        end
    end
    return count
end

-- ══════════════════════════════════════════════════════════
-- STOP & CLEANUP
-- ══════════════════════════════════════════════════════════
local function stopAll(returnParts)
    isRunning = false
    for _, c in ipairs(connections) do pcall(function() c:Disconnect() end) end
    connections = {}

    if returnParts then
        for _, data in ipairs(grabbedParts) do
            local p = data.part
            if p and p.Parent then
                pcall(function()
                    p.Anchored   = data.origAnchored
                    p.CanCollide = data.origCanCollide
                    p.CFrame     = data.origCFrame
                    p.AssemblyLinearVelocity  = Vector3.zero
                    p.AssemblyAngularVelocity = Vector3.zero
                end)
            end
        end
    end

    grabbedParts = {}
    orbitAngle   = 0
    bounceAngle  = 0
end

-- ══════════════════════════════════════════════════════════
-- START ORBIT
-- ══════════════════════════════════════════════════════════
local function getHRP()
    local c = player.Character
    return c and c:FindFirstChild("HumanoidRootPart")
end

local function startOrbit(parts)
    local total    = #parts
    local perLayer = math.max(1, math.ceil(total / 4))

    local conn = RunService.RenderStepped:Connect(function(dt)
        local hrp = getHRP()
        if not hrp then return end

        orbitAngle  = orbitAngle  + dt * 1.5
        bounceAngle = bounceAngle + dt * 2.0

        local base = hrp.Position

        for i, data in ipairs(grabbedParts) do
            local p = data.part
            if p and p.Parent then
                local layer  = math.floor((i - 1) / perLayer)
                local idx    = (i - 1) % perLayer
                local angle  = orbitAngle + (idx / perLayer) * (2 * math.pi)
                local radius = 6 + layer * 3.5
                local height = 8 + layer * 2.5

                local x = base.X + math.cos(angle) * radius
                local z = base.Z + math.sin(angle) * radius
                local y = base.Y + height + math.sin(bounceAngle + i * 0.4) * 0.5

                p.CFrame = CFrame.new(x, y, z)
                    * CFrame.Angles(
                        orbitAngle * 2,
                        orbitAngle * 1.4,
                        orbitAngle * 0.6
                    )
            end
        end
    end)
    table.insert(connections, conn)
end

-- ══════════════════════════════════════════════════════════
-- MAIN
-- ══════════════════════════════════════════════════════════
local function startGrab()
    stopAll(false)
    isRunning = true

    -- Kumpulkan semua part map
    local parts = collectAllMapParts()

    for _, p in ipairs(parts) do
        pcall(function() SetNetworkOwner:FireServer(p) end)
        table.insert(grabbedParts, {
            part           = p,
            origCFrame     = p.CFrame,
            origAnchored   = p.Anchored,
            origCanCollide = p.CanCollide
        })
        p.Anchored   = true
        p.CanCollide = false
    end

    -- Launch semua player lain
    local launched = launchAllOtherPlayers()

    -- Mulai orbit
    startOrbit(grabbedParts)

    -- Keep launching player lain yang baru join / respawn
    local keepLaunchConn = RunService.Heartbeat:Connect(function()
        if not isRunning then return end
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= player and p.Character then
                local hrp = p.Character:FindFirstChild("HumanoidRootPart")
                if hrp and hrp.Position.Y < 500 then
                    -- Kalau player lain turun lagi, lempar lagi
                    for _, part in ipairs(p.Character:GetDescendants()) do
                        if part:IsA("BasePart") then
                            pcall(function()
                                part.Anchored = false
                                part.AssemblyLinearVelocity = Vector3.new(
                                    math.random(-30, 30),
                                    math.random(250, 500),
                                    math.random(-30, 30)
                                )
                            end)
                        end
                    end
                end
            end
        end
    end)
    table.insert(connections, keepLaunchConn)

    -- Pastikan executor tetap TIDAK terpengaruh
    local safeConn = RunService.Heartbeat:Connect(function()
        local myChar = player.Character
        if not myChar then return end
        -- Kalau ada part orbit yang SOMEHOW masuk ke karakter executor, skip
        -- (tidak ada logic yang menyentuh karakter executor sama sekali)
    end)
    table.insert(connections, safeConn)

    return #parts, launched
end

-- ══════════════════════════════════════════════════════════
-- UI — SIMPLE
-- ══════════════════════════════════════════════════════════
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "MassGrab_UI"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = PlayerGui

local Main = Instance.new("Frame")
Main.Size = UDim2.new(0, 360, 0, 200)
Main.Position = UDim2.new(0.02, 0, 0.5, -100)
Main.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
Main.BorderSizePixel = 0
Main.Active = true
Main.Draggable = true
Main.Parent = ScreenGui
do
    local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0,12) c.Parent = Main
    local g = Instance.new("UIGradient")
    g.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(28,28,38)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(14,14,20))
    }
    g.Rotation = 45
    g.Parent = Main
end

-- Header
local Hdr = Instance.new("Frame")
Hdr.Size = UDim2.new(1,0,0,55)
Hdr.BackgroundColor3 = Color3.fromRGB(30,30,45)
Hdr.BorderSizePixel = 0
Hdr.Parent = Main
do local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0,12) c.Parent = Hdr end

local TitleLbl = Instance.new("TextLabel")
TitleLbl.Size = UDim2.new(1,-55,0,24)
TitleLbl.Position = UDim2.new(0,14,0,8)
TitleLbl.BackgroundTransparency = 1
TitleLbl.Text = "🧲 MASS GRAB LAUNCHER"
TitleLbl.TextColor3 = Color3.fromRGB(255,255,255)
TitleLbl.Font = Enum.Font.GothamBold
TitleLbl.TextSize = 17
TitleLbl.TextXAlignment = Enum.TextXAlignment.Left
TitleLbl.Parent = Hdr

local SubLbl = Instance.new("TextLabel")
SubLbl.Size = UDim2.new(1,-55,0,14)
SubLbl.Position = UDim2.new(0,14,0,33)
SubLbl.BackgroundTransparency = 1
SubLbl.Text = "All parts orbit · All other players fly"
SubLbl.TextColor3 = Color3.fromRGB(130,130,170)
SubLbl.Font = Enum.Font.Gotham
SubLbl.TextSize = 11
SubLbl.TextXAlignment = Enum.TextXAlignment.Left
SubLbl.Parent = Hdr

local MinBtn = Instance.new("TextButton")
MinBtn.Size = UDim2.new(0,36,0,36)
MinBtn.Position = UDim2.new(1,-46,0,9)
MinBtn.BackgroundColor3 = Color3.fromRGB(40,40,58)
MinBtn.Text = "−"
MinBtn.TextColor3 = Color3.fromRGB(255,255,255)
MinBtn.Font = Enum.Font.GothamBold
MinBtn.TextSize = 22
MinBtn.Parent = Hdr
do local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0,8) c.Parent = MinBtn end

-- Status Label
local StatusLbl = Instance.new("TextLabel")
StatusLbl.Size = UDim2.new(1,-20,0,30)
StatusLbl.Position = UDim2.new(0,10,0,60)
StatusLbl.BackgroundTransparency = 1
StatusLbl.Text = "⏸ Idle — klik GRAB & LAUNCH untuk mulai"
StatusLbl.TextColor3 = Color3.fromRGB(140,140,140)
StatusLbl.Font = Enum.Font.Gotham
StatusLbl.TextSize = 12
StatusLbl.TextXAlignment = Enum.TextXAlignment.Left
StatusLbl.Parent = Main

-- Grab Button
local GrabBtn = Instance.new("TextButton")
GrabBtn.Size = UDim2.new(0.56,-8,0,46)
GrabBtn.Position = UDim2.new(0,10,0,98)
GrabBtn.BackgroundColor3 = Color3.fromRGB(70,170,70)
GrabBtn.Text = "🧲 GRAB & LAUNCH"
GrabBtn.TextColor3 = Color3.fromRGB(255,255,255)
GrabBtn.Font = Enum.Font.GothamBold
GrabBtn.TextSize = 14
GrabBtn.Parent = Main
do local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0,10) c.Parent = GrabBtn end

-- Return Button
local ReturnBtn = Instance.new("TextButton")
ReturnBtn.Size = UDim2.new(0.41,-2,0,46)
ReturnBtn.Position = UDim2.new(0.59,0,0,98)
ReturnBtn.BackgroundColor3 = Color3.fromRGB(55,55,68)
ReturnBtn.Text = "↩ RETURN PARTS"
ReturnBtn.TextColor3 = Color3.fromRGB(255,255,255)
ReturnBtn.Font = Enum.Font.GothamBold
ReturnBtn.TextSize = 13
ReturnBtn.Parent = Main
do local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0,10) c.Parent = ReturnBtn end

-- Info label
local InfoLbl = Instance.new("TextLabel")
InfoLbl.Size = UDim2.new(1,-20,0,30)
InfoLbl.Position = UDim2.new(0,10,0,153)
InfoLbl.BackgroundTransparency = 1
InfoLbl.Text = "ℹ️ Executor tidak terpengaruh • Semua part map"
InfoLbl.TextColor3 = Color3.fromRGB(90,180,255)
InfoLbl.Font = Enum.Font.Gotham
InfoLbl.TextSize = 11
InfoLbl.TextXAlignment = Enum.TextXAlignment.Left
InfoLbl.Parent = Main

-- Minimize
local isMinimized = false
local function setVisible(v)
    StatusLbl.Visible = v
    GrabBtn.Visible   = v
    ReturnBtn.Visible = v
    InfoLbl.Visible   = v
end

MinBtn.MouseButton1Click:Connect(function()
    isMinimized = not isMinimized
    if isMinimized then
        TweenService:Create(Main, TweenInfo.new(0.25, Enum.EasingStyle.Quad), {Size = UDim2.new(0,360,0,55)}):Play()
        MinBtn.Text = "+"
        setVisible(false)
    else
        TweenService:Create(Main, TweenInfo.new(0.25, Enum.EasingStyle.Quad), {Size = UDim2.new(0,360,0,200)}):Play()
        MinBtn.Text = "−"
        task.wait(0.25)
        setVisible(true)
    end
end)

-- ══════════════════════════════════════════════════════════
-- BUTTON EVENTS
-- ══════════════════════════════════════════════════════════
GrabBtn.MouseButton1Click:Connect(function()
    if isRunning then
        stopAll(false)
        GrabBtn.Text = "🧲 GRAB & LAUNCH"
        GrabBtn.BackgroundColor3 = Color3.fromRGB(70,170,70)
        StatusLbl.Text = "⏹ Stopped"
        StatusLbl.TextColor3 = Color3.fromRGB(180,180,180)
        return
    end

    GrabBtn.Text = "⏳ Grabbing..."
    GrabBtn.BackgroundColor3 = Color3.fromRGB(150,130,30)
    StatusLbl.Text = "⏳ Scanning all map parts..."
    StatusLbl.TextColor3 = Color3.fromRGB(255,220,80)

    task.spawn(function()
        local partCount, playerCount = startGrab()

        if partCount == 0 then
            isRunning = false
            GrabBtn.Text = "🧲 GRAB & LAUNCH"
            GrabBtn.BackgroundColor3 = Color3.fromRGB(70,170,70)
            StatusLbl.Text = "⚠️ Tidak ada part ditemukan"
            StatusLbl.TextColor3 = Color3.fromRGB(255,100,100)
            return
        end

        GrabBtn.Text = "⏹ STOP"
        GrabBtn.BackgroundColor3 = Color3.fromRGB(210,55,55)
        StatusLbl.Text = string.format("✅ %d parts orbit · 🚀 %d players launched", partCount, playerCount)
        StatusLbl.TextColor3 = Color3.fromRGB(100,255,120)
    end)
end)

ReturnBtn.MouseButton1Click:Connect(function()
    stopAll(true)
    GrabBtn.Text = "🧲 GRAB & LAUNCH"
    GrabBtn.BackgroundColor3 = Color3.fromRGB(70,170,70)
    StatusLbl.Text = "↩ Semua part dikembalikan ke posisi asal"
    StatusLbl.TextColor3 = Color3.fromRGB(90,200,255)

    ReturnBtn.BackgroundColor3 = Color3.fromRGB(0,160,90)
    ReturnBtn.Text = "✅ RETURNED"
    task.wait(1.5)
    ReturnBtn.BackgroundColor3 = Color3.fromRGB(55,55,68)
    ReturnBtn.Text = "↩ RETURN PARTS"
end)

-- Handle respawn executor
player.CharacterAdded:Connect(function()
    -- Jangan stop, biarkan orbit tetap jalan setelah respawn
    -- Cuma update status
    StatusLbl.Text = isRunning
        and string.format("✅ %d parts orbiting (respawned)", #grabbedParts)
        or "⏸ Idle"
end)

print("╔══════════════════════════════════════════════════════╗")
print("║   MASS GRAB LAUNCHER — Loaded!                       ║")
print("║   ✅ Executor 100% aman                              ║")
print("║   ✅ Semua part map (tanpa radius limit)             ║")
print("║   ✅ Semua player lain terluncur terus               ║")
print("╚══════════════════════════════════════════════════════╝")
