--[[
    ╔══════════════════════════════════════════════════════════╗
    ║           MASS GRAB LAUNCHER - PREMIUM EDITION           ║
    ║     Use Game's Own GrabEvents to Launch All Parts        ║
    ╚══════════════════════════════════════════════════════════╝
    
    Cara kerja:
    - Pakai RemoteEvent yang ada di game (SetNetworkOwner, DestroyGrabLine)
    - Set NetworkOwner semua part ke local player
    - Lalu kasih velocity ke atas biar terbang
    - Bisa juga orbit pakai CFrame
]]

local Players         = game:GetService("Players")
local RunService      = game:GetService("RunService")
local TweenService    = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player    = Players.LocalPlayer
local PlayerGui = player:WaitForChild("PlayerGui")

-- ══════════════════════════════════════════════════════════
-- GRAB EVENTS (dari game asli)
-- ══════════════════════════════════════════════════════════
local GrabEvents         = ReplicatedStorage:WaitForChild("GrabEvents")
local SetNetworkOwner    = GrabEvents:WaitForChild("SetNetworkOwner")
local DestroyGrabLine    = GrabEvents:WaitForChild("DestroyGrabLine")
local ExtendGrabLine     = GrabEvents:WaitForChild("ExtendGrabLine")

-- ══════════════════════════════════════════════════════════
-- CONFIG
-- ══════════════════════════════════════════════════════════
local Config = {
    Enabled      = false,
    Mode         = "Orbit",   -- "Orbit" | "Explode" | "Float"
    Radius       = 50,        -- radius scan part dari player
    MaxParts     = 60,
    OrbitHeight  = 8,
    OrbitRadius  = 6,
    OrbitSpeed   = 1.5,
    SpinSpeed    = 2,
    Bounce       = true,
    BounceAmp    = 0.6,
    ExplodeForce = 150,
    FloatHeight  = 15,
}

local grabbedParts  = {}   -- { part, origCFrame, origAnchored, origCanCollide }
local connections   = {}
local orbitAngle    = 0
local bounceAngle   = 0

-- ══════════════════════════════════════════════════════════
-- HELPER
-- ══════════════════════════════════════════════════════════
local blacklistNames = {
    "baseplate","spawnlocation","terrain","camera",
    "humanoidrootpart","head","torso","leftleg","rightleg",
    "leftarm","rightarm","lowertorso","uppertorso",
    "leftupperleg","rightupperleg","leftlowerleg","rightlowerleg",
    "leftfoot","rightfoot","leftupperarm","rightupperarm",
    "leftlowerarm","rightlowerarm","lefthand","righthand"
}

local function isBlacklisted(part)
    local lname = part.Name:lower()
    for _, bl in ipairs(blacklistNames) do
        if lname == bl then return true end
    end
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Character and part:IsDescendantOf(p.Character) then
            return true
        end
    end
    return false
end

local function getCharRoot()
    local char = player.Character
    if not char then return nil end
    return char:FindFirstChild("HumanoidRootPart")
end

local function collectNearbyParts()
    local hrp = getCharRoot()
    if not hrp then return {} end
    local pos     = hrp.Position
    local result  = {}
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") and not isBlacklisted(obj) and not obj.Locked then
            if (obj.Position - pos).Magnitude <= Config.Radius then
                table.insert(result, obj)
                if #result >= Config.MaxParts then break end
            end
        end
    end
    return result
end

local function clearGrabbed(returnParts)
    for _, conn in ipairs(connections) do
        conn:Disconnect()
    end
    connections = {}

    if returnParts then
        for _, data in ipairs(grabbedParts) do
            local p = data.part
            if p and p.Parent then
                p.Anchored    = data.origAnchored
                p.CanCollide  = data.origCanCollide
                p.CFrame      = data.origCFrame
                p.AssemblyLinearVelocity  = Vector3.zero
                p.AssemblyAngularVelocity = Vector3.zero
            end
        end
    end

    grabbedParts = {}
    orbitAngle   = 0
    bounceAngle  = 0
end

-- ══════════════════════════════════════════════════════════
-- MODE: ORBIT (berputar di atas player)
-- ══════════════════════════════════════════════════════════
local function startOrbit(parts)
    local total      = #parts
    local perLayer   = math.max(1, math.ceil(total / 3))

    local conn = RunService.RenderStepped:Connect(function(dt)
        local hrp = getCharRoot()
        if not hrp then return end

        orbitAngle  = orbitAngle  + dt * Config.OrbitSpeed
        bounceAngle = bounceAngle + dt * 2

        local base = hrp.Position

        for i, data in ipairs(grabbedParts) do
            local p = data.part
            if p and p.Parent then
                local layer   = math.floor((i - 1) / perLayer)
                local idx     = (i - 1) % perLayer
                local angle   = orbitAngle + (idx / perLayer) * (2 * math.pi)
                local radius  = Config.OrbitRadius + layer * 3
                local height  = Config.OrbitHeight + layer * 2.5

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
-- MODE: EXPLODE (terbang ke segala arah)
-- ══════════════════════════════════════════════════════════
local function doExplode(parts)
    local hrp = getCharRoot()
    if not hrp then return end
    local origin = hrp.Position

    for _, data in ipairs(parts) do
        local p = data.part
        if p and p.Parent then
            p.Anchored   = false
            p.CanCollide = false
            local dir = (p.Position - origin)
            if dir.Magnitude < 0.1 then
                dir = Vector3.new(math.random()-0.5, 1, math.random()-0.5)
            end
            dir = dir.Unit
            local force = Config.ExplodeForce * (1 + math.random() * 0.5)
            p.AssemblyLinearVelocity = dir * force + Vector3.new(0, 50, 0)
            p.AssemblyAngularVelocity = Vector3.new(
                math.random(-10, 10),
                math.random(-10, 10),
                math.random(-10, 10)
            )
        end
    end
end

-- ══════════════════════════════════════════════════════════
-- MODE: FLOAT (melayang diam di atas)
-- ══════════════════════════════════════════════════════════
local function startFloat(parts)
    local total = #parts
    local cols  = math.ceil(math.sqrt(total))
    local spacing = 3

    local conn = RunService.RenderStepped:Connect(function(dt)
        local hrp = getCharRoot()
        if not hrp then return end
        bounceAngle = bounceAngle + dt * 1.5
        local base  = hrp.Position

        for i, data in ipairs(grabbedParts) do
            local p = data.part
            if p and p.Parent then
                local row = math.floor((i-1) / cols)
                local col = (i-1) % cols
                local x = base.X + (col - cols/2) * spacing
                local z = base.Z + (row - cols/2) * spacing
                local y = base.Y + Config.FloatHeight
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
-- MAIN START
-- ══════════════════════════════════════════════════════════
local function startGrab()
    clearGrabbed(false)
    Config.Enabled = true

    local parts = collectNearbyParts()
    if #parts == 0 then
        warn("[MassGrab] Tidak ada part ditemukan di radius " .. Config.Radius)
        Config.Enabled = false
        return 0
    end

    for _, p in ipairs(parts) do
        -- Coba kasih NetworkOwnership ke local player lewat remote asli
        pcall(function()
            SetNetworkOwner:FireServer(p)
        end)

        table.insert(grabbedParts, {
            part         = p,
            origCFrame   = p.CFrame,
            origAnchored = p.Anchored,
            origCanCollide = p.CanCollide
        })

        -- Anchored biar bisa digerak client-side
        p.Anchored   = true
        p.CanCollide = false
    end

    if Config.Mode == "Orbit" then
        startOrbit(grabbedParts)
    elseif Config.Mode == "Explode" then
        -- Unanchor dulu buat explode
        for _, data in ipairs(grabbedParts) do
            data.part.Anchored = false
        end
        doExplode(grabbedParts)
        Config.Enabled = false  -- explode tidak perlu loop
    elseif Config.Mode == "Float" then
        startFloat(grabbedParts)
    end

    print(string.format("[MassGrab] Mode: %s | Parts: %d", Config.Mode, #grabbedParts))
    return #grabbedParts
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
Main.Size = UDim2.new(0, 380, 0, 490)
Main.Position = UDim2.new(0.02, 0, 0.5, -245)
Main.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
Main.BorderSizePixel = 0
Main.Active = true
Main.Draggable = true
Main.Parent = ScreenGui

local MC = Instance.new("UICorner")
MC.CornerRadius = UDim.new(0, 12)
MC.Parent = Main

local MG = Instance.new("UIGradient")
MG.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Color3.fromRGB(25, 25, 35)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(15, 15, 22))
}
MG.Rotation = 45
MG.Parent = Main

-- Header
local Hdr = Instance.new("Frame")
Hdr.Size = UDim2.new(1, 0, 0, 65)
Hdr.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
Hdr.BorderSizePixel = 0
Hdr.Parent = Main
local HC = Instance.new("UICorner") HC.CornerRadius = UDim.new(0, 12) HC.Parent = Hdr

local TitleLbl = Instance.new("TextLabel")
TitleLbl.Size = UDim2.new(1, -100, 0, 28)
TitleLbl.Position = UDim2.new(0, 15, 0, 8)
TitleLbl.BackgroundTransparency = 1
TitleLbl.Text = "🧲 MASS GRAB LAUNCHER"
TitleLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleLbl.Font = Enum.Font.GothamBold
TitleLbl.TextSize = 18
TitleLbl.TextXAlignment = Enum.TextXAlignment.Left
TitleLbl.Parent = Hdr

local SubLbl = Instance.new("TextLabel")
SubLbl.Size = UDim2.new(1, -100, 0, 16)
SubLbl.Position = UDim2.new(0, 15, 0, 38)
SubLbl.BackgroundTransparency = 1
SubLbl.Text = "Grab & Launch All Nearby Parts"
SubLbl.TextColor3 = Color3.fromRGB(150, 150, 180)
SubLbl.Font = Enum.Font.Gotham
SubLbl.TextSize = 11
SubLbl.TextXAlignment = Enum.TextXAlignment.Left
SubLbl.Parent = Hdr

local MinBtn = Instance.new("TextButton")
MinBtn.Size = UDim2.new(0, 40, 0, 40)
MinBtn.Position = UDim2.new(1, -50, 0, 12)
MinBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
MinBtn.Text = "−"
MinBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
MinBtn.Font = Enum.Font.GothamBold
MinBtn.TextSize = 22
MinBtn.Parent = Hdr
local MBC = Instance.new("UICorner") MBC.CornerRadius = UDim.new(0, 8) MBC.Parent = MinBtn

-- Content
local Content = Instance.new("Frame")
Content.Size = UDim2.new(1, -20, 1, -145)
Content.Position = UDim2.new(0, 10, 0, 75)
Content.BackgroundTransparency = 1
Content.Parent = Main

local UIS = game:GetService("UserInputService")

local function makeSlider(label, yPos, mn, mx, cur, cb)
    local Row = Instance.new("Frame")
    Row.Size = UDim2.new(1, 0, 0, 55)
    Row.Position = UDim2.new(0, 0, 0, yPos)
    Row.BackgroundColor3 = Color3.fromRGB(30, 30, 42)
    Row.BorderSizePixel = 0
    Row.Parent = Content
    local RC = Instance.new("UICorner") RC.CornerRadius = UDim.new(0, 8) RC.Parent = Row

    local Lbl = Instance.new("TextLabel")
    Lbl.Size = UDim2.new(0.6, 0, 0, 20)
    Lbl.Position = UDim2.new(0, 10, 0, 6)
    Lbl.BackgroundTransparency = 1
    Lbl.Text = label
    Lbl.TextColor3 = Color3.fromRGB(220, 220, 220)
    Lbl.Font = Enum.Font.GothamBold
    Lbl.TextSize = 13
    Lbl.TextXAlignment = Enum.TextXAlignment.Left
    Lbl.Parent = Row

    local Val = Instance.new("TextLabel")
    Val.Size = UDim2.new(0.35, 0, 0, 20)
    Val.Position = UDim2.new(0.63, 0, 0, 6)
    Val.BackgroundTransparency = 1
    Val.Text = tostring(cur)
    Val.TextColor3 = Color3.fromRGB(100, 200, 255)
    Val.Font = Enum.Font.GothamBold
    Val.TextSize = 13
    Val.TextXAlignment = Enum.TextXAlignment.Right
    Val.Parent = Row

    local Bg = Instance.new("Frame")
    Bg.Size = UDim2.new(1, -20, 0, 8)
    Bg.Position = UDim2.new(0, 10, 0, 38)
    Bg.BackgroundColor3 = Color3.fromRGB(50, 50, 65)
    Bg.BorderSizePixel = 0
    Bg.Parent = Row
    local BgC = Instance.new("UICorner") BgC.CornerRadius = UDim.new(1, 0) BgC.Parent = Bg

    local pct = (cur - mn) / (mx - mn)
    local Fill = Instance.new("Frame")
    Fill.Size = UDim2.new(pct, 0, 1, 0)
    Fill.BackgroundColor3 = Color3.fromRGB(100, 150, 255)
    Fill.BorderSizePixel = 0
    Fill.Parent = Bg
    local FC = Instance.new("UICorner") FC.CornerRadius = UDim.new(1, 0) FC.Parent = Fill

    local Handle = Instance.new("TextButton")
    Handle.Size = UDim2.new(0, 16, 0, 16)
    Handle.Position = UDim2.new(pct, -8, 0.5, -8)
    Handle.BackgroundColor3 = Color3.fromRGB(150, 180, 255)
    Handle.Text = ""
    Handle.Parent = Bg
    local HdC = Instance.new("UICorner") HdC.CornerRadius = UDim.new(1, 0) HdC.Parent = Handle

    local drag = false
    Handle.MouseButton1Down:Connect(function() drag = true end)
    UIS.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then drag = false end
    end)
    RunService.RenderStepped:Connect(function()
        if drag then
            local mx2 = UIS:GetMouseLocation().X
            local ap   = Bg.AbsolutePosition.X
            local aw   = Bg.AbsoluteSize.X
            local np   = math.clamp((mx2 - ap) / aw, 0, 1)
            local nv   = math.floor(mn + np * (mx - mn) + 0.5)
            nv = math.clamp(nv, mn, mx)
            local sp = (nv - mn) / (mx - mn)
            Fill.Size = UDim2.new(sp, 0, 1, 0)
            Handle.Position = UDim2.new(sp, -8, 0.5, -8)
            Val.Text = tostring(nv)
            cb(nv)
        end
    end)
end

makeSlider("🎯 Scan Radius",  0,   5,  150, Config.Radius,      function(v) Config.Radius      = v end)
makeSlider("🔢 Max Parts",   60,   1,  100, Config.MaxParts,    function(v) Config.MaxParts    = v end)
makeSlider("⬆️ Orbit Height",120,  2,   25, Config.OrbitHeight, function(v) Config.OrbitHeight = v end)
makeSlider("📏 Orbit Radius",180,  2,   20, Config.OrbitRadius, function(v) Config.OrbitRadius = v end)
makeSlider("⚡ Speed",       240,  1,   10, Config.OrbitSpeed,  function(v) Config.OrbitSpeed  = v end)

-- Mode Selector
local ModeFrame = Instance.new("Frame")
ModeFrame.Size = UDim2.new(1, 0, 0, 44)
ModeFrame.Position = UDim2.new(0, 0, 0, 305)
ModeFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 42)
ModeFrame.BorderSizePixel = 0
ModeFrame.Parent = Content
local MFC = Instance.new("UICorner") MFC.CornerRadius = UDim.new(0, 8) MFC.Parent = ModeFrame

local ModeLbl = Instance.new("TextLabel")
ModeLbl.Size = UDim2.new(0.35, 0, 1, 0)
ModeLbl.Position = UDim2.new(0, 10, 0, 0)
ModeLbl.BackgroundTransparency = 1
ModeLbl.Text = "🔀 Mode:"
ModeLbl.TextColor3 = Color3.fromRGB(220, 220, 220)
ModeLbl.Font = Enum.Font.GothamBold
ModeLbl.TextSize = 13
ModeLbl.TextXAlignment = Enum.TextXAlignment.Left
ModeLbl.Parent = ModeFrame

local modes = {"Orbit", "Float", "Explode"}
local modeColors = {
    Orbit   = Color3.fromRGB(80,  140, 255),
    Float   = Color3.fromRGB(80,  200, 100),
    Explode = Color3.fromRGB(255, 80,  80),
}
local modeBtns = {}

for i, mode in ipairs(modes) do
    local Btn = Instance.new("TextButton")
    Btn.Size = UDim2.new(0, 75, 0, 30)
    Btn.Position = UDim2.new(0, 115 + (i-1) * 82, 0.5, -15)
    Btn.BackgroundColor3 = mode == Config.Mode and modeColors[mode] or Color3.fromRGB(50, 50, 65)
    Btn.Text = mode
    Btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    Btn.Font = Enum.Font.GothamBold
    Btn.TextSize = 13
    Btn.Parent = ModeFrame
    local BC = Instance.new("UICorner") BC.CornerRadius = UDim.new(0, 6) BC.Parent = Btn
    modeBtns[mode] = Btn

    Btn.MouseButton1Click:Connect(function()
        Config.Mode = mode
        for m, b in pairs(modeBtns) do
            b.BackgroundColor3 = m == mode and modeColors[m] or Color3.fromRGB(50, 50, 65)
        end
    end)
end

-- Status Label
local StatusLbl = Instance.new("TextLabel")
StatusLbl.Size = UDim2.new(1, 0, 0, 30)
StatusLbl.Position = UDim2.new(0, 0, 0, 358)
StatusLbl.BackgroundTransparency = 1
StatusLbl.Text = "⏸ Idle"
StatusLbl.TextColor3 = Color3.fromRGB(150, 150, 150)
StatusLbl.Font = Enum.Font.GothamBold
StatusLbl.TextSize = 13
StatusLbl.Parent = Content

-- Action Buttons
local StartBtn = Instance.new("TextButton")
StartBtn.Size = UDim2.new(0.57, -5, 0, 48)
StartBtn.Position = UDim2.new(0, 10, 1, -58)
StartBtn.BackgroundColor3 = Color3.fromRGB(80, 180, 80)
StartBtn.Text = "🧲 GRAB & LAUNCH"
StartBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
StartBtn.Font = Enum.Font.GothamBold
StartBtn.TextSize = 15
StartBtn.Parent = Main
local SBC = Instance.new("UICorner") SBC.CornerRadius = UDim.new(0, 10) SBC.Parent = StartBtn

local ReturnBtn = Instance.new("TextButton")
ReturnBtn.Size = UDim2.new(0.4, -5, 0, 48)
ReturnBtn.Position = UDim2.new(0.6, 0, 1, -58)
ReturnBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
ReturnBtn.Text = "↩ RETURN"
ReturnBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ReturnBtn.Font = Enum.Font.GothamBold
ReturnBtn.TextSize = 15
ReturnBtn.Parent = Main
local RBC = Instance.new("UICorner") RBC.CornerRadius = UDim.new(0, 10) RBC.Parent = ReturnBtn

-- Minimize
local isMinimized = false
MinBtn.MouseButton1Click:Connect(function()
    isMinimized = not isMinimized
    if isMinimized then
        TweenService:Create(Main, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {Size = UDim2.new(0, 380, 0, 65)}):Play()
        MinBtn.Text = "+"
        Content.Visible = false
        StartBtn.Visible = false
        ReturnBtn.Visible = false
    else
        TweenService:Create(Main, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {Size = UDim2.new(0, 380, 0, 490)}):Play()
        MinBtn.Text = "−"
        task.wait(0.3)
        Content.Visible = true
        StartBtn.Visible = true
        ReturnBtn.Visible = true
    end
end)

-- ══════════════════════════════════════════════════════════
-- BUTTON EVENTS
-- ══════════════════════════════════════════════════════════
StartBtn.MouseButton1Click:Connect(function()
    if Config.Enabled then
        stopGrab(false)
        StartBtn.Text = "🧲 GRAB & LAUNCH"
        StartBtn.BackgroundColor3 = Color3.fromRGB(80, 180, 80)
        StatusLbl.Text = "⏸ Idle"
        StatusLbl.TextColor3 = Color3.fromRGB(150, 150, 150)
        return
    end

    StartBtn.Text = "⏳ Scanning..."
    local count = startGrab()

    if Config.Enabled then
        StartBtn.Text = "⏹ STOP"
        StartBtn.BackgroundColor3 = Color3.fromRGB(220, 60, 60)
        StatusLbl.Text = string.format("✅ %d parts | Mode: %s", count, Config.Mode)
        StatusLbl.TextColor3 = Color3.fromRGB(100, 255, 100)
    elseif Config.Mode == "Explode" then
        StartBtn.Text = "🧲 GRAB & LAUNCH"
        StartBtn.BackgroundColor3 = Color3.fromRGB(80, 180, 80)
        StatusLbl.Text = string.format("💥 Exploded %d parts!", count)
        StatusLbl.TextColor3 = Color3.fromRGB(255, 150, 50)
    else
        StartBtn.Text = "🧲 GRAB & LAUNCH"
        StartBtn.BackgroundColor3 = Color3.fromRGB(80, 180, 80)
        StatusLbl.Text = "⚠ Tidak ada part ditemukan"
        StatusLbl.TextColor3 = Color3.fromRGB(255, 100, 100)
    end
end)

ReturnBtn.MouseButton1Click:Connect(function()
    stopGrab(true)
    StartBtn.Text = "🧲 GRAB & LAUNCH"
    StartBtn.BackgroundColor3 = Color3.fromRGB(80, 180, 80)
    StatusLbl.Text = "↩ Parts dikembalikan"
    StatusLbl.TextColor3 = Color3.fromRGB(100, 200, 255)
    ReturnBtn.BackgroundColor3 = Color3.fromRGB(0, 180, 100)
    ReturnBtn.Text = "✅ RETURNED"
    task.wait(1.5)
    ReturnBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
    ReturnBtn.Text = "↩ RETURN"
end)

-- Handle respawn
player.CharacterAdded:Connect(function()
    stopGrab(false)
    StartBtn.Text = "🧲 GRAB & LAUNCH"
    StartBtn.BackgroundColor3 = Color3.fromRGB(80, 180, 80)
    StatusLbl.Text = "⏸ Idle (respawned)"
    StatusLbl.TextColor3 = Color3.fromRGB(150, 150, 150)
end)

print("╔══════════════════════════════════════════════════════╗")
print("║   MASS GRAB LAUNCHER - Successfully Loaded!          ║")
print("║   3 Mode: Orbit | Float | Explode                    ║")
print("║   Pakai GrabEvents asli dari game                    ║")
print("╚══════════════════════════════════════════════════════╝")
