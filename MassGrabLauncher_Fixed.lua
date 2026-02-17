--[[
    ╔══════════════════════════════════════════════════════════╗
    ║          MASS GRAB LAUNCHER - FIXED EDITION              ║
    ║   Map Parts Orbit + Other Players Get Launched           ║
    ╚══════════════════════════════════════════════════════════╝
]]

local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local TweenService      = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UIS               = game:GetService("UserInputService")

local player    = Players.LocalPlayer
local PlayerGui = player:WaitForChild("PlayerGui")

-- ══════════════════════════════════════════════════════════
-- GRAB EVENTS dari game
-- ══════════════════════════════════════════════════════════
local GrabEvents      = ReplicatedStorage:WaitForChild("GrabEvents")
local SetNetworkOwner = GrabEvents:WaitForChild("SetNetworkOwner")

-- ══════════════════════════════════════════════════════════
-- CONFIG
-- ══════════════════════════════════════════════════════════
local Config = {
    Enabled      = false,
    Mode         = "Orbit",
    Radius       = 50,
    MaxParts     = 40,
    OrbitHeight  = 8,
    OrbitRadius  = 6,
    OrbitSpeed   = 1.5,
    SpinSpeed    = 2,
    Bounce       = true,
    BounceAmp    = 0.5,
    ExplodeForce = 120,
    FloatHeight  = 14,
    LaunchPlayers = true,
    LaunchForce   = 200,
}

local grabbedParts = {}
local connections  = {}
local orbitAngle   = 0
local bounceAngle  = 0

-- ══════════════════════════════════════════════════════════
-- HELPER
-- ══════════════════════════════════════════════════════════

-- Nama part milik SEMUA player (executor + others) → skip semua karakter
local function isAnyPlayerPart(part)
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Character and part:IsDescendantOf(p.Character) then
            return true
        end
    end
    return false
end

local blacklist = {
    "baseplate","spawnlocation","terrain","camera"
}
local function isBlacklisted(part)
    local lname = part.Name:lower()
    for _, bl in ipairs(blacklist) do
        if lname == bl then return true end
    end
    return false
end

local function getHRP()
    local char = player.Character
    if not char then return nil end
    return char:FindFirstChild("HumanoidRootPart")
end

-- Kumpulkan HANYA part dari MAP (bukan dari karakter siapapun)
local function collectMapParts()
    local hrp = getHRP()
    if not hrp then return {} end
    local pos    = hrp.Position
    local result = {}
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart")
            and not isBlacklisted(obj)
            and not isAnyPlayerPart(obj)   -- ← skip SEMUA karakter player
            and not obj.Locked
        then
            if (obj.Position - pos).Magnitude <= Config.Radius then
                table.insert(result, obj)
                if #result >= Config.MaxParts then break end
            end
        end
    end
    return result
end

-- Kumpulkan HRP semua player LAIN (bukan executor)
local function collectOtherPlayerHRPs()
    local hrp = getHRP()
    if not hrp then return {} end
    local pos    = hrp.Position
    local result = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= player and p.Character then
            local otherHRP = p.Character:FindFirstChild("HumanoidRootPart")
            if otherHRP and (otherHRP.Position - pos).Magnitude <= Config.Radius then
                table.insert(result, otherHRP)
            end
        end
    end
    return result
end

local function clearGrabbed(returnParts)
    for _, conn in ipairs(connections) do
        pcall(function() conn:Disconnect() end)
    end
    connections = {}

    if returnParts then
        for _, data in ipairs(grabbedParts) do
            local p = data.part
            if p and p.Parent then
                p.Anchored   = data.origAnchored
                p.CanCollide = data.origCanCollide
                pcall(function()
                    p.CFrame                    = data.origCFrame
                    p.AssemblyLinearVelocity    = Vector3.zero
                    p.AssemblyAngularVelocity   = Vector3.zero
                end)
            end
        end
    end

    grabbedParts = {}
    orbitAngle   = 0
    bounceAngle  = 0
end

-- ══════════════════════════════════════════════════════════
-- LAUNCH OTHER PLAYERS
-- ══════════════════════════════════════════════════════════
local function launchOtherPlayers()
    if not Config.LaunchPlayers then return end
    local hrps = collectOtherPlayerHRPs()
    for _, otherHRP in ipairs(hrps) do
        -- Unanchor dan beri velocity ke atas
        pcall(function()
            otherHRP.Anchored = false
            otherHRP.AssemblyLinearVelocity = Vector3.new(
                math.random(-30, 30),
                Config.LaunchForce,
                math.random(-30, 30)
            )
        end)
        -- Coba semua BasePart di karakter lain
        local otherChar = otherHRP.Parent
        if otherChar then
            for _, part in ipairs(otherChar:GetDescendants()) do
                if part:IsA("BasePart") then
                    pcall(function()
                        part.AssemblyLinearVelocity = Vector3.new(
                            math.random(-20, 20),
                            Config.LaunchForce,
                            math.random(-20, 20)
                        )
                    end)
                end
            end
        end
    end
    return #hrps
end

-- ══════════════════════════════════════════════════════════
-- MODE: ORBIT
-- ══════════════════════════════════════════════════════════
local function startOrbit()
    local total    = #grabbedParts
    local perLayer = math.max(1, math.ceil(total / 3))

    local conn = RunService.RenderStepped:Connect(function(dt)
        local hrp = getHRP()
        if not hrp then return end

        orbitAngle  = orbitAngle  + dt * Config.OrbitSpeed
        bounceAngle = bounceAngle + dt * 2

        local base = hrp.Position

        for i, data in ipairs(grabbedParts) do
            local p = data.part
            if p and p.Parent then
                local layer  = math.floor((i - 1) / perLayer)
                local idx    = (i - 1) % perLayer
                local angle  = orbitAngle + (idx / perLayer) * (2 * math.pi)
                local radius = Config.OrbitRadius + layer * 3
                local height = Config.OrbitHeight + layer * 2.5

                local x = base.X + math.cos(angle) * radius
                local z = base.Z + math.sin(angle) * radius
                local y = base.Y + height
                if Config.Bounce then
                    y = y + math.sin(bounceAngle + i * 0.4) * Config.BounceAmp
                end

                p.CFrame = CFrame.new(x, y, z)
                    * CFrame.Angles(
                        orbitAngle * Config.SpinSpeed,
                        orbitAngle * Config.SpinSpeed * 0.7,
                        orbitAngle * Config.SpinSpeed * 0.3
                    )
            end
        end
    end)
    table.insert(connections, conn)
end

-- ══════════════════════════════════════════════════════════
-- MODE: FLOAT
-- ══════════════════════════════════════════════════════════
local function startFloat()
    local total   = #grabbedParts
    local cols    = math.max(1, math.ceil(math.sqrt(total)))
    local spacing = 3

    local conn = RunService.RenderStepped:Connect(function(dt)
        local hrp = getHRP()
        if not hrp then return end
        bounceAngle = bounceAngle + dt * 1.5
        local base  = hrp.Position

        for i, data in ipairs(grabbedParts) do
            local p = data.part
            if p and p.Parent then
                local row = math.floor((i - 1) / cols)
                local col = (i - 1) % cols
                local x   = base.X + (col - cols / 2) * spacing
                local z   = base.Z + (row - cols / 2) * spacing
                local y   = base.Y + Config.FloatHeight
                if Config.Bounce then
                    y = y + math.sin(bounceAngle + i * 0.3) * Config.BounceAmp
                end
                p.CFrame = CFrame.new(x, y, z)
                    * CFrame.Angles(
                        bounceAngle * 0.3 + i,
                        bounceAngle * 0.2 + i,
                        0
                    )
            end
        end
    end)
    table.insert(connections, conn)
end

-- ══════════════════════════════════════════════════════════
-- MODE: EXPLODE
-- ══════════════════════════════════════════════════════════
local function doExplode()
    local hrp = getHRP()
    if not hrp then return end
    local origin = hrp.Position

    for _, data in ipairs(grabbedParts) do
        local p = data.part
        if p and p.Parent then
            p.Anchored   = false
            p.CanCollide = false
            local dir = (p.Position - origin)
            if dir.Magnitude < 0.1 then
                dir = Vector3.new(math.random() - 0.5, 1, math.random() - 0.5)
            end
            dir = dir.Unit
            local force = Config.ExplodeForce * (1 + math.random() * 0.5)
            p.AssemblyLinearVelocity  = dir * force + Vector3.new(0, 60, 0)
            p.AssemblyAngularVelocity = Vector3.new(
                math.random(-15, 15),
                math.random(-15, 15),
                math.random(-15, 15)
            )
        end
    end
end

-- ══════════════════════════════════════════════════════════
-- MAIN START
-- ══════════════════════════════════════════════════════════
local function startGrab()
    clearGrabbed(false)
    Config.Enabled = true

    local parts = collectMapParts()
    if #parts == 0 then
        Config.Enabled = false
        return 0, 0
    end

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

    local launchedCount = 0
    if Config.LaunchPlayers then
        launchedCount = launchOtherPlayers() or 0
    end

    if Config.Mode == "Orbit" then
        startOrbit()
    elseif Config.Mode == "Float" then
        startFloat()
    elseif Config.Mode == "Explode" then
        for _, data in ipairs(grabbedParts) do
            data.part.Anchored = false
        end
        doExplode()
        Config.Enabled = false
    end

    return #parts, launchedCount
end

local function stopGrab(returnParts)
    Config.Enabled = false
    clearGrabbed(returnParts)
end

-- ══════════════════════════════════════════════════════════
-- UI
-- ══════════════════════════════════════════════════════════
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "MassGrab_UI"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = PlayerGui

local Main = Instance.new("Frame")
Main.Size = UDim2.new(0, 390, 0, 540)
Main.Position = UDim2.new(0.02, 0, 0.5, -270)
Main.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
Main.BorderSizePixel = 0
Main.Active = true
Main.Draggable = true
Main.Parent = ScreenGui

do
    local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0,12) c.Parent = Main
    local g = Instance.new("UIGradient")
    g.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(25,25,35)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(15,15,22))
    }
    g.Rotation = 45
    g.Parent = Main
end

-- Header
local Hdr = Instance.new("Frame")
Hdr.Size = UDim2.new(1,0,0,65)
Hdr.BackgroundColor3 = Color3.fromRGB(30,30,45)
Hdr.BorderSizePixel = 0
Hdr.Parent = Main
do local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0,12) c.Parent = Hdr end

local TitleLbl = Instance.new("TextLabel")
TitleLbl.Size = UDim2.new(1,-100,0,28)
TitleLbl.Position = UDim2.new(0,15,0,8)
TitleLbl.BackgroundTransparency = 1
TitleLbl.Text = "🧲 MASS GRAB LAUNCHER"
TitleLbl.TextColor3 = Color3.fromRGB(255,255,255)
TitleLbl.Font = Enum.Font.GothamBold
TitleLbl.TextSize = 18
TitleLbl.TextXAlignment = Enum.TextXAlignment.Left
TitleLbl.Parent = Hdr

local SubLbl = Instance.new("TextLabel")
SubLbl.Size = UDim2.new(1,-100,0,16)
SubLbl.Position = UDim2.new(0,15,0,38)
SubLbl.BackgroundTransparency = 1
SubLbl.Text = "Map Parts Orbit | Other Players Launched"
SubLbl.TextColor3 = Color3.fromRGB(150,150,180)
SubLbl.Font = Enum.Font.Gotham
SubLbl.TextSize = 11
SubLbl.TextXAlignment = Enum.TextXAlignment.Left
SubLbl.Parent = Hdr

local MinBtn = Instance.new("TextButton")
MinBtn.Size = UDim2.new(0,40,0,40)
MinBtn.Position = UDim2.new(1,-50,0,12)
MinBtn.BackgroundColor3 = Color3.fromRGB(40,40,55)
MinBtn.Text = "−"
MinBtn.TextColor3 = Color3.fromRGB(255,255,255)
MinBtn.Font = Enum.Font.GothamBold
MinBtn.TextSize = 22
MinBtn.Parent = Hdr
do local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0,8) c.Parent = MinBtn end

-- Content
local Content = Instance.new("Frame")
Content.Size = UDim2.new(1,-20,1,-145)
Content.Position = UDim2.new(0,10,0,75)
Content.BackgroundTransparency = 1
Content.Parent = Main

-- Slider factory
local function makeSlider(label, yPos, mn, mx, cur, cb)
    local Row = Instance.new("Frame")
    Row.Size = UDim2.new(1,0,0,55)
    Row.Position = UDim2.new(0,0,0,yPos)
    Row.BackgroundColor3 = Color3.fromRGB(30,30,42)
    Row.BorderSizePixel = 0
    Row.Parent = Content
    do local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0,8) c.Parent = Row end

    local Lbl = Instance.new("TextLabel")
    Lbl.Size = UDim2.new(0.6,0,0,20)
    Lbl.Position = UDim2.new(0,10,0,6)
    Lbl.BackgroundTransparency = 1
    Lbl.Text = label
    Lbl.TextColor3 = Color3.fromRGB(220,220,220)
    Lbl.Font = Enum.Font.GothamBold
    Lbl.TextSize = 13
    Lbl.TextXAlignment = Enum.TextXAlignment.Left
    Lbl.Parent = Row

    local Val = Instance.new("TextLabel")
    Val.Size = UDim2.new(0.35,0,0,20)
    Val.Position = UDim2.new(0.63,0,0,6)
    Val.BackgroundTransparency = 1
    Val.Text = tostring(cur)
    Val.TextColor3 = Color3.fromRGB(100,200,255)
    Val.Font = Enum.Font.GothamBold
    Val.TextSize = 13
    Val.TextXAlignment = Enum.TextXAlignment.Right
    Val.Parent = Row

    local Bg = Instance.new("Frame")
    Bg.Size = UDim2.new(1,-20,0,8)
    Bg.Position = UDim2.new(0,10,0,38)
    Bg.BackgroundColor3 = Color3.fromRGB(50,50,65)
    Bg.BorderSizePixel = 0
    Bg.Parent = Row
    do local c = Instance.new("UICorner") c.CornerRadius = UDim.new(1,0) c.Parent = Bg end

    local pct  = math.clamp((cur - mn) / (mx - mn), 0, 1)

    local Fill = Instance.new("Frame")
    Fill.Size = UDim2.new(pct,0,1,0)
    Fill.BackgroundColor3 = Color3.fromRGB(100,150,255)
    Fill.BorderSizePixel = 0
    Fill.Parent = Bg
    do local c = Instance.new("UICorner") c.CornerRadius = UDim.new(1,0) c.Parent = Fill end

    local Handle = Instance.new("TextButton")
    Handle.Size = UDim2.new(0,16,0,16)
    Handle.Position = UDim2.new(pct,-8,0.5,-8)
    Handle.BackgroundColor3 = Color3.fromRGB(150,180,255)
    Handle.Text = ""
    Handle.ZIndex = 5
    Handle.Parent = Bg
    do local c = Instance.new("UICorner") c.CornerRadius = UDim.new(1,0) c.Parent = Handle end

    local dragging = false
    Handle.MouseButton1Down:Connect(function() dragging = true end)
    Handle.MouseButton1Up:Connect(function()   dragging = false end)
    UIS.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    RunService.RenderStepped:Connect(function()
        if not dragging then return end
        local mx2 = UIS:GetMouseLocation().X
        local ap  = Bg.AbsolutePosition.X
        local aw  = Bg.AbsoluteSize.X
        local np  = math.clamp((mx2 - ap) / aw, 0, 1)
        local nv  = math.clamp(math.floor(mn + np * (mx - mn) + 0.5), mn, mx)
        local sp  = (nv - mn) / (mx - mn)
        Fill.Size            = UDim2.new(sp, 0, 1, 0)
        Handle.Position      = UDim2.new(sp, -8, 0.5, -8)
        Val.Text             = tostring(nv)
        cb(nv)
    end)
end

-- Toggle factory
local function makeToggle(label, yPos, configKey, color)
    local Row = Instance.new("Frame")
    Row.Size = UDim2.new(1,0,0,40)
    Row.Position = UDim2.new(0,0,0,yPos)
    Row.BackgroundColor3 = Color3.fromRGB(30,30,42)
    Row.BorderSizePixel = 0
    Row.Parent = Content
    do local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0,8) c.Parent = Row end

    local Lbl = Instance.new("TextLabel")
    Lbl.Size = UDim2.new(1,-80,1,0)
    Lbl.Position = UDim2.new(0,10,0,0)
    Lbl.BackgroundTransparency = 1
    Lbl.Text = label
    Lbl.TextColor3 = Color3.fromRGB(220,220,220)
    Lbl.Font = Enum.Font.GothamBold
    Lbl.TextSize = 13
    Lbl.TextXAlignment = Enum.TextXAlignment.Left
    Lbl.Parent = Row

    local Btn = Instance.new("TextButton")
    Btn.Size = UDim2.new(0,55,0,28)
    Btn.Position = UDim2.new(1,-65,0.5,-14)
    Btn.BackgroundColor3 = Config[configKey] and color or Color3.fromRGB(60,60,70)
    Btn.Text = Config[configKey] and "ON" or "OFF"
    Btn.TextColor3 = Color3.fromRGB(255,255,255)
    Btn.Font = Enum.Font.GothamBold
    Btn.TextSize = 13
    Btn.Parent = Row
    do local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0,6) c.Parent = Btn end

    Btn.MouseButton1Click:Connect(function()
        Config[configKey] = not Config[configKey]
        Btn.Text = Config[configKey] and "ON" or "OFF"
        Btn.BackgroundColor3 = Config[configKey] and color or Color3.fromRGB(60,60,70)
    end)
end

-- Build sliders
makeSlider("🎯 Scan Radius",   0,   5, 150, Config.Radius,       function(v) Config.Radius       = v end)
makeSlider("🔢 Max Parts",    60,   1, 100, Config.MaxParts,     function(v) Config.MaxParts     = v end)
makeSlider("⬆️ Height",      120,   2,  25, Config.OrbitHeight,  function(v) Config.OrbitHeight  = v end)
makeSlider("📏 Orbit Radius", 180,   2,  20, Config.OrbitRadius,  function(v) Config.OrbitRadius  = v end)
makeSlider("⚡ Speed",        240,   1,  10, Config.OrbitSpeed,   function(v) Config.OrbitSpeed   = v end)
makeSlider("💥 Launch Force", 300,  50, 500, Config.LaunchForce,  function(v) Config.LaunchForce  = v end)

-- Toggles
makeToggle("🚀 Launch Other Players", 364, "LaunchPlayers", Color3.fromRGB(255,100,80))
makeToggle("🏀 Bounce Effect",        410, "Bounce",        Color3.fromRGB(100,200,100))

-- Mode selector
local ModeFrame = Instance.new("Frame")
ModeFrame.Size = UDim2.new(1,0,0,44)
ModeFrame.Position = UDim2.new(0,0,0,458)
ModeFrame.BackgroundColor3 = Color3.fromRGB(30,30,42)
ModeFrame.BorderSizePixel = 0
ModeFrame.Parent = Content
do local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0,8) c.Parent = ModeFrame end

local ModeLbl = Instance.new("TextLabel")
ModeLbl.Size = UDim2.new(0.3,0,1,0)
ModeLbl.Position = UDim2.new(0,10,0,0)
ModeLbl.BackgroundTransparency = 1
ModeLbl.Text = "🔀 Mode:"
ModeLbl.TextColor3 = Color3.fromRGB(220,220,220)
ModeLbl.Font = Enum.Font.GothamBold
ModeLbl.TextSize = 13
ModeLbl.TextXAlignment = Enum.TextXAlignment.Left
ModeLbl.Parent = ModeFrame

local modes = {"Orbit","Float","Explode"}
local modeColors = {
    Orbit   = Color3.fromRGB(80,140,255),
    Float   = Color3.fromRGB(80,200,100),
    Explode = Color3.fromRGB(255,80,80),
}
local modeBtns = {}
for i, mode in ipairs(modes) do
    local Btn = Instance.new("TextButton")
    Btn.Size = UDim2.new(0,80,0,30)
    Btn.Position = UDim2.new(0, 110 + (i-1)*87, 0.5, -15)
    Btn.BackgroundColor3 = mode == Config.Mode and modeColors[mode] or Color3.fromRGB(50,50,65)
    Btn.Text = mode
    Btn.TextColor3 = Color3.fromRGB(255,255,255)
    Btn.Font = Enum.Font.GothamBold
    Btn.TextSize = 13
    Btn.Parent = ModeFrame
    do local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0,6) c.Parent = Btn end
    modeBtns[mode] = Btn
    Btn.MouseButton1Click:Connect(function()
        Config.Mode = mode
        for m, b in pairs(modeBtns) do
            b.BackgroundColor3 = m == mode and modeColors[m] or Color3.fromRGB(50,50,65)
        end
    end)
end

-- Status
local StatusLbl = Instance.new("TextLabel")
StatusLbl.Size = UDim2.new(1,-20,0,22)
StatusLbl.Position = UDim2.new(0,10,1,-120)
StatusLbl.BackgroundTransparency = 1
StatusLbl.Text = "⏸ Idle — buka UI dan klik GRAB & LAUNCH"
StatusLbl.TextColor3 = Color3.fromRGB(150,150,150)
StatusLbl.Font = Enum.Font.Gotham
StatusLbl.TextSize = 12
StatusLbl.TextXAlignment = Enum.TextXAlignment.Left
StatusLbl.Parent = Main

-- Action Buttons
local StartBtn = Instance.new("TextButton")
StartBtn.Size = UDim2.new(0.57,-8,0,48)
StartBtn.Position = UDim2.new(0,10,1,-62)
StartBtn.BackgroundColor3 = Color3.fromRGB(80,180,80)
StartBtn.Text = "🧲 GRAB & LAUNCH"
StartBtn.TextColor3 = Color3.fromRGB(255,255,255)
StartBtn.Font = Enum.Font.GothamBold
StartBtn.TextSize = 15
StartBtn.Parent = Main
do local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0,10) c.Parent = StartBtn end

local ReturnBtn = Instance.new("TextButton")
ReturnBtn.Size = UDim2.new(0.4,-2,0,48)
ReturnBtn.Position = UDim2.new(0.6,0,1,-62)
ReturnBtn.BackgroundColor3 = Color3.fromRGB(60,60,70)
ReturnBtn.Text = "↩ RETURN"
ReturnBtn.TextColor3 = Color3.fromRGB(255,255,255)
ReturnBtn.Font = Enum.Font.GothamBold
ReturnBtn.TextSize = 15
ReturnBtn.Parent = Main
do local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0,10) c.Parent = ReturnBtn end

-- Minimize
local isMinimized = false
MinBtn.MouseButton1Click:Connect(function()
    isMinimized = not isMinimized
    if isMinimized then
        TweenService:Create(Main, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {Size = UDim2.new(0,390,0,65)}):Play()
        MinBtn.Text = "+"
        Content.Visible    = false
        StartBtn.Visible   = false
        ReturnBtn.Visible  = false
        StatusLbl.Visible  = false
    else
        TweenService:Create(Main, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {Size = UDim2.new(0,390,0,540)}):Play()
        MinBtn.Text = "−"
        task.wait(0.3)
        Content.Visible    = true
        StartBtn.Visible   = true
        ReturnBtn.Visible  = true
        StatusLbl.Visible  = true
    end
end)

-- ══════════════════════════════════════════════════════════
-- BUTTON LOGIC
-- ══════════════════════════════════════════════════════════
local function setStatus(txt, color)
    StatusLbl.Text      = txt
    StatusLbl.TextColor3 = color or Color3.fromRGB(150,150,150)
end

StartBtn.MouseButton1Click:Connect(function()
    if Config.Enabled then
        -- Stop orbit/float, jangan kembalikan
        stopGrab(false)
        StartBtn.Text = "🧲 GRAB & LAUNCH"
        StartBtn.BackgroundColor3 = Color3.fromRGB(80,180,80)
        setStatus("⏹ Stopped", Color3.fromRGB(200,200,200))
        return
    end

    StartBtn.Text = "⏳ Scanning..."
    StartBtn.BackgroundColor3 = Color3.fromRGB(150,150,50)

    local partCount, playerCount = startGrab()

    if Config.Mode == "Explode" then
        StartBtn.Text = "🧲 GRAB & LAUNCH"
        StartBtn.BackgroundColor3 = Color3.fromRGB(80,180,80)
        setStatus(
            string.format("💥 Exploded %d parts | 🚀 Launched %d players", partCount, playerCount),
            Color3.fromRGB(255,150,50)
        )
    elseif Config.Enabled then
        StartBtn.Text = "⏹ STOP"
        StartBtn.BackgroundColor3 = Color3.fromRGB(220,60,60)
        setStatus(
            string.format("✅ %d parts orbiting | 🚀 %d players launched", partCount, playerCount),
            Color3.fromRGB(100,255,100)
        )
    else
        StartBtn.Text = "🧲 GRAB & LAUNCH"
        StartBtn.BackgroundColor3 = Color3.fromRGB(80,180,80)
        setStatus("⚠ Tidak ada part di radius " .. Config.Radius, Color3.fromRGB(255,100,100))
    end
end)

ReturnBtn.MouseButton1Click:Connect(function()
    stopGrab(true)
    StartBtn.Text = "🧲 GRAB & LAUNCH"
    StartBtn.BackgroundColor3 = Color3.fromRGB(80,180,80)
    setStatus("↩ Parts dikembalikan ke posisi asal", Color3.fromRGB(100,200,255))
    ReturnBtn.BackgroundColor3 = Color3.fromRGB(0,180,100)
    ReturnBtn.Text = "✅ RETURNED"
    task.wait(1.5)
    ReturnBtn.BackgroundColor3 = Color3.fromRGB(60,60,70)
    ReturnBtn.Text = "↩ RETURN"
end)

player.CharacterAdded:Connect(function()
    stopGrab(false)
    StartBtn.Text = "🧲 GRAB & LAUNCH"
    StartBtn.BackgroundColor3 = Color3.fromRGB(80,180,80)
    setStatus("⏸ Idle (respawned)", Color3.fromRGB(150,150,150))
end)

print("╔══════════════════════════════════════════════════════╗")
print("║   MASS GRAB LAUNCHER FIXED - Loaded!                 ║")
print("║   ✅ Executor tidak terangkat                        ║")
print("║   ✅ Hanya part map (bukan karakter)                 ║")
print("║   ✅ Player lain diluncurkan ke atas                 ║")
print("║   ✅ Tombol & slider fixed                           ║")
print("╚══════════════════════════════════════════════════════╝")
