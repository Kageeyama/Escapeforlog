--[[
    ╔══════════════════════════════════════════════════════════╗
    ║         BRAINROT VALUE CALCULATOR - FIXED EDITION        ║
    ║          Calculate Level 1 Value from Any Level          ║
    ╚══════════════════════════════════════════════════════════╝
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer
local PlayerGui = player:WaitForChild("PlayerGui")

local Config = {
    ScanInterval = 3,
    AutoScan = false,
    UpgradeMultiplier = 1.5,
    DebugMode = true
}

local scannedItems = {}
local isScanning = false

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ValueCalculator_UI"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = PlayerGui

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 500, 0, 650)
MainFrame.Position = UDim2.new(0.5, -250, 0.5, -325)
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 12)
MainCorner.Parent = MainFrame

local Gradient = Instance.new("UIGradient")
Gradient.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Color3.fromRGB(25, 25, 30)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(15, 15, 20))
}
Gradient.Rotation = 45
Gradient.Parent = MainFrame

local Header = Instance.new("Frame")
Header.Name = "Header"
Header.Size = UDim2.new(1, 0, 0, 80)
Header.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
Header.BorderSizePixel = 0
Header.Parent = MainFrame

local HeaderCorner = Instance.new("UICorner")
HeaderCorner.CornerRadius = UDim.new(0, 12)
HeaderCorner.Parent = Header

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -100, 0, 28)
Title.Position = UDim2.new(0, 15, 0, 10)
Title.BackgroundTransparency = 1
Title.Text = "💎 VALUE CALCULATOR"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 20
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Header

local Subtitle = Instance.new("TextLabel")
Subtitle.Size = UDim2.new(1, -100, 0, 16)
Subtitle.Position = UDim2.new(0, 15, 0, 40)
Subtitle.BackgroundTransparency = 1
Subtitle.Text = "Calculate Level 1 Value | Auto-Detect Categories"
Subtitle.TextColor3 = Color3.fromRGB(150, 150, 150)
Subtitle.Font = Enum.Font.Gotham
Subtitle.TextSize = 12
Subtitle.TextXAlignment = Enum.TextXAlignment.Left
Subtitle.Parent = Header

local MultiplierLabel = Instance.new("TextLabel")
MultiplierLabel.Size = UDim2.new(1, -100, 0, 16)
MultiplierLabel.Position = UDim2.new(0, 15, 0, 58)
MultiplierLabel.BackgroundTransparency = 1
MultiplierLabel.Text = "⚙️ Multiplier: 1.5x (adjust if needed)"
MultiplierLabel.TextColor3 = Color3.fromRGB(100, 200, 255)
MultiplierLabel.Font = Enum.Font.Gotham
MultiplierLabel.TextSize = 11
MultiplierLabel.TextXAlignment = Enum.TextXAlignment.Left
MultiplierLabel.Parent = Header

local MinimizeBtn = Instance.new("TextButton")
MinimizeBtn.Size = UDim2.new(0, 40, 0, 40)
MinimizeBtn.Position = UDim2.new(1, -50, 0, 15)
MinimizeBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
MinimizeBtn.Text = "−"
MinimizeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
MinimizeBtn.Font = Enum.Font.GothamBold
MinimizeBtn.TextSize = 22
MinimizeBtn.Parent = Header

local MinBtnCorner = Instance.new("UICorner")
MinBtnCorner.CornerRadius = UDim.new(0, 8)
MinBtnCorner.Parent = MinimizeBtn

local ControlFrame = Instance.new("Frame")
ControlFrame.Size = UDim2.new(1, -20, 0, 120)
ControlFrame.Position = UDim2.new(0, 10, 0, 90)
ControlFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
ControlFrame.BorderSizePixel = 0
ControlFrame.Parent = MainFrame

local ControlCorner = Instance.new("UICorner")
ControlCorner.CornerRadius = UDim.new(0, 8)
ControlCorner.Parent = ControlFrame

local MultiplierInput = Instance.new("Frame")
MultiplierInput.Size = UDim2.new(1, -20, 0, 40)
MultiplierInput.Position = UDim2.new(0, 10, 0, 10)
MultiplierInput.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
MultiplierInput.BorderSizePixel = 0
MultiplierInput.Parent = ControlFrame

local MultInputCorner = Instance.new("UICorner")
MultInputCorner.CornerRadius = UDim.new(0, 6)
MultInputCorner.Parent = MultiplierInput

local MultiplierLabelInput = Instance.new("TextLabel")
MultiplierLabelInput.Size = UDim2.new(0, 150, 1, 0)
MultiplierLabelInput.Position = UDim2.new(0, 10, 0, 0)
MultiplierLabelInput.BackgroundTransparency = 1
MultiplierLabelInput.Text = "🔧 Upgrade Multiplier:"
MultiplierLabelInput.TextColor3 = Color3.fromRGB(255, 255, 255)
MultiplierLabelInput.Font = Enum.Font.GothamBold
MultiplierLabelInput.TextSize = 13
MultiplierLabelInput.TextXAlignment = Enum.TextXAlignment.Left
MultiplierLabelInput.Parent = MultiplierInput

local MultiplierBox = Instance.new("TextBox")
MultiplierBox.Size = UDim2.new(0, 80, 0, 28)
MultiplierBox.Position = UDim2.new(1, -90, 0.5, -14)
MultiplierBox.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
MultiplierBox.Text = "1.5"
MultiplierBox.TextColor3 = Color3.fromRGB(100, 255, 100)
MultiplierBox.Font = Enum.Font.GothamBold
MultiplierBox.TextSize = 14
MultiplierBox.PlaceholderText = "1.5"
MultiplierBox.Parent = MultiplierInput

local MultBoxCorner = Instance.new("UICorner")
MultBoxCorner.CornerRadius = UDim.new(0, 6)
MultBoxCorner.Parent = MultiplierBox

MultiplierBox.FocusLost:Connect(function()
    local newMult = tonumber(MultiplierBox.Text)
    if newMult and newMult > 1 and newMult < 10 then
        Config.UpgradeMultiplier = newMult
        MultiplierLabel.Text = string.format("⚙️ Multiplier: %.2fx", newMult)
    else
        MultiplierBox.Text = tostring(Config.UpgradeMultiplier)
    end
end)

local AutoScanFrame = Instance.new("Frame")
AutoScanFrame.Size = UDim2.new(0.48, -5, 0, 32)
AutoScanFrame.Position = UDim2.new(0, 10, 0, 60)
AutoScanFrame.BackgroundTransparency = 1
AutoScanFrame.Parent = ControlFrame

local AutoScanToggle = Instance.new("TextButton")
AutoScanToggle.Size = UDim2.new(1, 0, 1, 0)
AutoScanToggle.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
AutoScanToggle.Text = "🔄 AUTO SCAN: OFF"
AutoScanToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
AutoScanToggle.Font = Enum.Font.GothamBold
AutoScanToggle.TextSize = 13
AutoScanToggle.Parent = AutoScanFrame

local AutoToggleCorner = Instance.new("UICorner")
AutoToggleCorner.CornerRadius = UDim.new(0, 6)
AutoToggleCorner.Parent = AutoScanToggle

local ScanNowBtn = Instance.new("TextButton")
ScanNowBtn.Size = UDim2.new(0.48, -5, 0, 32)
ScanNowBtn.Position = UDim2.new(0.52, 0, 0, 60)
ScanNowBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
ScanNowBtn.Text = "🔍 SCAN NOW"
ScanNowBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ScanNowBtn.Font = Enum.Font.GothamBold
ScanNowBtn.TextSize = 13
ScanNowBtn.Parent = ControlFrame

local ScanBtnCorner = Instance.new("UICorner")
ScanBtnCorner.CornerRadius = UDim.new(0, 6)
ScanBtnCorner.Parent = ScanNowBtn

local ResultsFrame = Instance.new("ScrollingFrame")
ResultsFrame.Size = UDim2.new(1, -20, 1, -310)
ResultsFrame.Position = UDim2.new(0, 10, 0, 220)
ResultsFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
ResultsFrame.BorderSizePixel = 0
ResultsFrame.ScrollBarThickness = 6
ResultsFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
ResultsFrame.Parent = MainFrame

local ResultsCorner = Instance.new("UICorner")
ResultsCorner.CornerRadius = UDim.new(0, 8)
ResultsCorner.Parent = ResultsFrame

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout.Padding = UDim.new(0, 8)
UIListLayout.Parent = ResultsFrame

local StatusLabel = Instance.new("TextLabel")
StatusLabel.Size = UDim2.new(1, -20, 0, 90)
StatusLabel.Position = UDim2.new(0, 10, 1, -100)
StatusLabel.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
StatusLabel.Text = "📊 Ready to Scan\n💎 Items Found: 0\n⚡ Click SCAN NOW to start"
StatusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
StatusLabel.Font = Enum.Font.GothamBold
StatusLabel.TextSize = 13
StatusLabel.TextYAlignment = Enum.TextYAlignment.Top
StatusLabel.Parent = MainFrame

local StatusCorner = Instance.new("UICorner")
StatusCorner.CornerRadius = UDim.new(0, 8)
StatusCorner.Parent = StatusLabel

local isMinimized = false
MinimizeBtn.MouseButton1Click:Connect(function()
    isMinimized = not isMinimized
    if isMinimized then
        TweenService:Create(MainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {Size = UDim2.new(0, 500, 0, 80)}):Play()
        MinimizeBtn.Text = "+"
        ControlFrame.Visible = false
        ResultsFrame.Visible = false
        StatusLabel.Visible = false
    else
        TweenService:Create(MainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {Size = UDim2.new(0, 500, 0, 650)}):Play()
        MinimizeBtn.Text = "−"
        task.wait(0.3)
        ControlFrame.Visible = true
        ResultsFrame.Visible = true
        StatusLabel.Visible = true
    end
end)

local function clearResults()
    for _, child in pairs(ResultsFrame:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end
end

local rarityColors = {
    ["secret"] = Color3.fromRGB(170, 0, 255),
    ["og"] = Color3.fromRGB(200, 200, 200),
    ["god"] = Color3.fromRGB(255, 0, 0),
    ["legend"] = Color3.fromRGB(255, 215, 0),
    ["myth"] = Color3.fromRGB(255, 100, 0),
    ["epic"] = Color3.fromRGB(150, 0, 255),
    ["rare"] = Color3.fromRGB(0, 150, 255),
    ["uncommon"] = Color3.fromRGB(0, 255, 0),
    ["iced"] = Color3.fromRGB(0, 255, 255),
    ["candy"] = Color3.fromRGB(255, 0, 255),
    ["common"] = Color3.fromRGB(150, 150, 150)
}

local function createItemCard(itemName, currentLevel, currentValueRaw, currentValueStr, level1ValueRaw, level1ValueStr, category)
    local ItemCard = Instance.new("Frame")
    ItemCard.Size = UDim2.new(1, -10, 0, 110)
    ItemCard.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    ItemCard.BorderSizePixel = 0
    ItemCard.Parent = ResultsFrame
    
    local CardCorner = Instance.new("UICorner")
    CardCorner.CornerRadius = UDim.new(0, 8)
    CardCorner.Parent = ItemCard
    
    local categoryLower = category:lower()
    local categoryColor = rarityColors[categoryLower] or Color3.fromRGB(150, 150, 150)
    
    local ColorBar = Instance.new("Frame")
    ColorBar.Size = UDim2.new(0, 6, 1, -10)
    ColorBar.Position = UDim2.new(0, 5, 0, 5)
    ColorBar.BackgroundColor3 = categoryColor
    ColorBar.BorderSizePixel = 0
    ColorBar.Parent = ItemCard
    
    local ColorCorner = Instance.new("UICorner")
    ColorCorner.CornerRadius = UDim.new(0, 3)
    ColorCorner.Parent = ColorBar
    
    local ItemName = Instance.new("TextLabel")
    ItemName.Size = UDim2.new(1, -100, 0, 22)
    ItemName.Position = UDim2.new(0, 20, 0, 8)
    ItemName.BackgroundTransparency = 1
    ItemName.Text = "📦 " .. itemName
    ItemName.TextColor3 = Color3.fromRGB(255, 255, 255)
    ItemName.Font = Enum.Font.GothamBold
    ItemName.TextSize = 15
    ItemName.TextXAlignment = Enum.TextXAlignment.Left
    ItemName.Parent = ItemCard
    
    local CategoryLabel = Instance.new("TextLabel")
    CategoryLabel.Size = UDim2.new(0, 90, 0, 22)
    CategoryLabel.Position = UDim2.new(1, -95, 0, 8)
    CategoryLabel.BackgroundColor3 = categoryColor
    CategoryLabel.Text = category:upper()
    CategoryLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    CategoryLabel.Font = Enum.Font.GothamBold
    CategoryLabel.TextSize = 11
    CategoryLabel.Parent = ItemCard
    
    local CatCorner = Instance.new("UICorner")
    CatCorner.CornerRadius = UDim.new(0, 5)
    CatCorner.Parent = CategoryLabel
    
    local CurrentInfo = Instance.new("TextLabel")
    CurrentInfo.Size = UDim2.new(1, -25, 0, 20)
    CurrentInfo.Position = UDim2.new(0, 20, 0, 35)
    CurrentInfo.BackgroundTransparency = 1
    CurrentInfo.Text = string.format("⭐ Current: Level %d = %s", currentLevel, currentValueStr)
    CurrentInfo.TextColor3 = Color3.fromRGB(100, 200, 255)
    CurrentInfo.Font = Enum.Font.Gotham
    CurrentInfo.TextSize = 13
    CurrentInfo.TextXAlignment = Enum.TextXAlignment.Left
    CurrentInfo.Parent = ItemCard
    
    local Divider = Instance.new("Frame")
    Divider.Size = UDim2.new(1, -30, 0, 2)
    Divider.Position = UDim2.new(0, 15, 0, 60)
    Divider.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
    Divider.BorderSizePixel = 0
    Divider.Parent = ItemCard
    
    local Level1Info = Instance.new("TextLabel")
    Level1Info.Size = UDim2.new(1, -25, 0, 40)
    Level1Info.Position = UDim2.new(0, 20, 0, 67)
    Level1Info.BackgroundTransparency = 1
    local growthPercent = ((currentValueRaw / level1ValueRaw) - 1) * 100
    Level1Info.Text = string.format("💎 Level 1 Value: %s\n📈 Growth: %.0f%% (%.1fx)", level1ValueStr, growthPercent, currentValueRaw / level1ValueRaw)
    Level1Info.TextColor3 = Color3.fromRGB(100, 255, 100)
    Level1Info.Font = Enum.Font.GothamBold
    Level1Info.TextSize = 13
    Level1Info.TextXAlignment = Enum.TextXAlignment.Left
    Level1Info.TextYAlignment = Enum.TextYAlignment.Top
    Level1Info.Parent = ItemCard
end

local function parseValue(text)
    if not text then return 0 end
    text = text:gsub(",", "")
    text = text:gsub("%s+", "")
    
    local num, suffix = text:match("%$?([%d%.]+)([KkMmBbTtQqSsPpNnOoDdUu][AaDdXxIiCc]?)")
    if not num then
        num = text:match("%$?([%d%.]+)")
        suffix = nil
    end
    if not num then return 0 end
    num = tonumber(num)
    if not num then return 0 end
    
    local multiplier = 1
    if suffix then
        suffix = suffix:upper()
        local suffixMap = {
            ["K"] = 1e3, ["M"] = 1e6, ["B"] = 1e9, ["T"] = 1e12,
            ["QA"] = 1e15, ["QI"] = 1e18, ["SX"] = 1e21, ["SP"] = 1e24,
            ["OC"] = 1e27, ["NO"] = 1e30, ["DC"] = 1e33, ["UD"] = 1e36,
            ["DD"] = 1e39, ["TD"] = 1e42, ["QD"] = 1e45, ["QID"] = 1e48,
            ["SD"] = 1e51, ["SPD"] = 1e54, ["OD"] = 1e57, ["ND"] = 1e60
        }
        multiplier = suffixMap[suffix] or 1
    end
    
    return num * multiplier
end

local function formatValue(value)
    if value == 0 then return "$0" end
    
    local suffixes = {
        {1e60, "ND"}, {1e57, "OD"}, {1e54, "SPD"}, {1e51, "SD"},
        {1e48, "QID"}, {1e45, "QD"}, {1e42, "TD"}, {1e39, "DD"},
        {1e36, "UD"}, {1e33, "DC"}, {1e30, "NO"}, {1e27, "OC"},
        {1e24, "SP"}, {1e21, "SX"}, {1e18, "QI"}, {1e15, "QA"},
        {1e12, "T"}, {1e9, "B"}, {1e6, "M"}, {1e3, "K"}
    }
    
    for _, data in ipairs(suffixes) do
        if value >= data[1] then
            return string.format("$%.2f%s", value / data[1], data[2])
        end
    end
    
    if value >= 100 then
        return string.format("$%.0f", value)
    else
        return string.format("$%.2f", value)
    end
end

local function calculateLevel1Value(currentLevel, currentValue)
    if currentLevel <= 1 or currentValue <= 0 then 
        return currentValue 
    end
    
    local multiplier = Config.UpgradeMultiplier
    local level1Value = currentValue / (multiplier ^ (currentLevel - 1))
    
    if Config.DebugMode then
        print(string.format("[DEBUG] Level %d: Current=$%.2f, Mult=%.2f^%d, Level1=$%.2f", 
            currentLevel, currentValue, multiplier, currentLevel - 1, level1Value))
    end
    
    return level1Value
end

local function detectCategory(text)
    if not text then return "Common" end
    text = text:lower()
    
    local patterns = {
        {"secret", "Secret"},
        {"og", "OG"},
        {"god", "God"},
        {"legend", "Legendary"},
        {"myth", "Mythic"},
        {"epic", "Epic"},
        {"rare", "Rare"},
        {"uncommon", "Uncommon"},
        {"iced", "Iced"},
        {"candy", "Candy"}
    }
    
    for _, pattern in ipairs(patterns) do
        if text:find(pattern[1]) then
            return pattern[2]
        end
    end
    
    return "Common"
end

local function scanInventory()
    if isScanning then return end
    isScanning = true
    clearResults()
    scannedItems = {}
    
    StatusLabel.Text = "🔄 Scanning Inventory...\n⏳ Please wait..."
    StatusLabel.TextColor3 = Color3.fromRGB(255, 255, 0)
    
    local itemCount = 0
    local debugCount = 0
    
    task.wait(0.5)
    
    for _, gui in pairs(PlayerGui:GetDescendants()) do
        if gui:IsA("TextLabel") and gui.Visible and gui.Parent then
            local text = gui.Text
            
            if text:match("Level%s*%d+") then
                debugCount = debugCount + 1
                local level = tonumber(text:match("Level%s*(%d+)"))
                
                if level and level > 0 then
                    local parent = gui.Parent
                    local itemName = "Unknown"
                    local valueRaw = 0
                    local category = "Common"
                    
                    for _, sibling in pairs(parent:GetDescendants()) do
                        if sibling:IsA("TextLabel") and sibling ~= gui then
                            local siblingText = sibling.Text
                            
                            if siblingText:match("%$") then
                                local parsed = parseValue(siblingText)
                                if parsed > valueRaw then
                                    valueRaw = parsed
                                end
                            elseif not siblingText:match("Level") and siblingText:len() > 2 then
                                if itemName == "Unknown" or siblingText:len() > itemName:len() then
                                    itemName = siblingText
                                    category = detectCategory(siblingText)
                                end
                            end
                        end
                    end
                    
                    if valueRaw > 0 and itemName ~= "Unknown" then
                        local level1ValueRaw = calculateLevel1Value(level, valueRaw)
                        
                        if level1ValueRaw > 0 then
                            table.insert(scannedItems, {
                                Name = itemName,
                                CurrentLevel = level,
                                CurrentValueRaw = valueRaw,
                                CurrentValueStr = formatValue(valueRaw),
                                Level1ValueRaw = level1ValueRaw,
                                Level1ValueStr = formatValue(level1ValueRaw),
                                Category = category
                            })
                            itemCount = itemCount + 1
                        end
                    end
                end
            end
        end
    end
    
    table.sort(scannedItems, function(a, b) 
        return a.Level1ValueRaw > b.Level1ValueRaw 
    end)
    
    for _, item in pairs(scannedItems) do
        createItemCard(
            item.Name,
            item.CurrentLevel,
            item.CurrentValueRaw,
            item.CurrentValueStr,
            item.Level1ValueRaw,
            item.Level1ValueStr,
            item.Category
        )
    end
    
    ResultsFrame.CanvasSize = UDim2.new(0, 0, 0, UIListLayout.AbsoluteContentSize.Y + 10)
    
    if itemCount > 0 then
        StatusLabel.Text = string.format("✅ Scan Complete!\n💎 Items Found: %d\n📊 Debug: Checked %d labels", itemCount, debugCount)
        StatusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
    else
        StatusLabel.Text = string.format("⚠️ No items found\n🔍 Debug: Checked %d labels\n💡 Try opening your inventory", debugCount)
        StatusLabel.TextColor3 = Color3.fromRGB(255, 150, 0)
    end
    
    isScanning = false
end

ScanNowBtn.MouseButton1Click:Connect(function()
    scanInventory()
end)

AutoScanToggle.MouseButton1Click:Connect(function()
    Config.AutoScan = not Config.AutoScan
    if Config.AutoScan then
        AutoScanToggle.Text = "🔄 AUTO SCAN: ON"
        AutoScanToggle.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
        task.spawn(function()
            while Config.AutoScan do
                scanInventory()
                task.wait(Config.ScanInterval)
            end
        end)
    else
        AutoScanToggle.Text = "🔄 AUTO SCAN: OFF"
        AutoScanToggle.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
    end
end)

print("╔══════════════════════════════════════════════════════╗")
print("║   VALUE CALCULATOR FIXED - Successfully Loaded!      ║")
print("║   Formula: Level1 = Current ÷ (Mult ^ (Level-1))    ║")
print("║   Default Multiplier: 1.5x (adjustable in UI)       ║")
print("╚══════════════════════════════════════════════════════╝")
