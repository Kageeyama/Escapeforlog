--[[
    ╔══════════════════════════════════════════════════════════╗
    ║         BRAINROT VALUE CALCULATOR - PREMIUM EDITION      ║
    ║          Calculate Level 1 Value from Any Level          ║
    ╚══════════════════════════════════════════════════════════╝
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer
local PlayerGui = player:WaitForChild("PlayerGui")

local Config = {
    ScanInterval = 2,
    AutoScan = false,
    SortBy = "Level1Value",
    ShowOnlySelected = false,
    UpgradeMultiplier = 2.5,
    SelectedCategories = {
        Secret = true,
        OG = true,
        God = true,
        Legendary = true,
        Mythic = true,
        Epic = true,
        Rare = true,
        Uncommon = true,
        Common = true,
        Iced = true,
        Candy = true
    }
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
MainFrame.Size = UDim2.new(0, 450, 0, 600)
MainFrame.Position = UDim2.new(0.5, -225, 0.5, -300)
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
Header.Size = UDim2.new(1, 0, 0, 60)
Header.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
Header.BorderSizePixel = 0
Header.Parent = MainFrame

local HeaderCorner = Instance.new("UICorner")
HeaderCorner.CornerRadius = UDim.new(0, 12)
HeaderCorner.Parent = Header

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -100, 0, 25)
Title.Position = UDim2.new(0, 15, 0, 5)
Title.BackgroundTransparency = 1
Title.Text = "💎 VALUE CALCULATOR"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 18
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Header

local Subtitle = Instance.new("TextLabel")
Subtitle.Size = UDim2.new(1, -100, 0, 15)
Subtitle.Position = UDim2.new(0, 15, 0, 30)
Subtitle.BackgroundTransparency = 1
Subtitle.Text = "Calculate Level 1 Value from Any Level"
Subtitle.TextColor3 = Color3.fromRGB(150, 150, 150)
Subtitle.Font = Enum.Font.Gotham
Subtitle.TextSize = 11
Subtitle.TextXAlignment = Enum.TextXAlignment.Left
Subtitle.Parent = Header

local MinimizeBtn = Instance.new("TextButton")
MinimizeBtn.Size = UDim2.new(0, 35, 0, 35)
MinimizeBtn.Position = UDim2.new(1, -45, 0, 12)
MinimizeBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
MinimizeBtn.Text = "−"
MinimizeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
MinimizeBtn.Font = Enum.Font.GothamBold
MinimizeBtn.TextSize = 20
MinimizeBtn.Parent = Header

local MinBtnCorner = Instance.new("UICorner")
MinBtnCorner.CornerRadius = UDim.new(0, 8)
MinBtnCorner.Parent = MinimizeBtn

local ControlFrame = Instance.new("Frame")
ControlFrame.Size = UDim2.new(1, -20, 0, 100)
ControlFrame.Position = UDim2.new(0, 10, 0, 70)
ControlFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
ControlFrame.BorderSizePixel = 0
ControlFrame.Parent = MainFrame

local ControlCorner = Instance.new("UICorner")
ControlCorner.CornerRadius = UDim.new(0, 8)
ControlCorner.Parent = ControlFrame

local AutoScanLabel = Instance.new("TextLabel")
AutoScanLabel.Size = UDim2.new(1, -80, 0, 30)
AutoScanLabel.Position = UDim2.new(0, 10, 0, 10)
AutoScanLabel.BackgroundTransparency = 1
AutoScanLabel.Text = "🔄 AUTO SCAN"
AutoScanLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
AutoScanLabel.Font = Enum.Font.GothamBold
AutoScanLabel.TextSize = 14
AutoScanLabel.TextXAlignment = Enum.TextXAlignment.Left
AutoScanLabel.Parent = ControlFrame

local AutoScanToggle = Instance.new("TextButton")
AutoScanToggle.Size = UDim2.new(0, 60, 0, 30)
AutoScanToggle.Position = UDim2.new(1, -70, 0, 10)
AutoScanToggle.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
AutoScanToggle.Text = "OFF"
AutoScanToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
AutoScanToggle.Font = Enum.Font.GothamBold
AutoScanToggle.TextSize = 12
AutoScanToggle.Parent = ControlFrame

local ToggleCorner = Instance.new("UICorner")
ToggleCorner.CornerRadius = UDim.new(0, 6)
ToggleCorner.Parent = AutoScanToggle

local ScanNowBtn = Instance.new("TextButton")
ScanNowBtn.Size = UDim2.new(1, -20, 0, 35)
ScanNowBtn.Position = UDim2.new(0, 10, 0, 55)
ScanNowBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
ScanNowBtn.Text = "🔍 SCAN INVENTORY"
ScanNowBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ScanNowBtn.Font = Enum.Font.GothamBold
ScanNowBtn.TextSize = 14
ScanNowBtn.Parent = ControlFrame

local ScanBtnCorner = Instance.new("UICorner")
ScanBtnCorner.CornerRadius = UDim.new(0, 8)
ScanBtnCorner.Parent = ScanNowBtn

local FilterFrame = Instance.new("ScrollingFrame")
FilterFrame.Size = UDim2.new(1, -20, 0, 150)
FilterFrame.Position = UDim2.new(0, 10, 0, 180)
FilterFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
FilterFrame.BorderSizePixel = 0
FilterFrame.ScrollBarThickness = 4
FilterFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
FilterFrame.Parent = MainFrame

local FilterCorner = Instance.new("UICorner")
FilterCorner.CornerRadius = UDim.new(0, 8)
FilterCorner.Parent = FilterFrame

local FilterTitle = Instance.new("TextLabel")
FilterTitle.Size = UDim2.new(1, 0, 0, 30)
FilterTitle.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
FilterTitle.Text = "🎯 FILTER BY RARITY"
FilterTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
FilterTitle.Font = Enum.Font.GothamBold
FilterTitle.TextSize = 13
FilterTitle.Parent = FilterFrame

local FilterTitleCorner = Instance.new("UICorner")
FilterTitleCorner.CornerRadius = UDim.new(0, 8)
FilterTitleCorner.Parent = FilterTitle

local FilterList = Instance.new("UIListLayout")
FilterList.SortOrder = Enum.SortOrder.LayoutOrder
FilterList.Padding = UDim.new(0, 5)
FilterList.Parent = FilterFrame

local rarityColors = {
    Secret = Color3.fromRGB(170, 0, 255),
    OG = Color3.fromRGB(200, 200, 200),
    God = Color3.fromRGB(255, 0, 0),
    Legendary = Color3.fromRGB(255, 215, 0),
    Mythic = Color3.fromRGB(255, 100, 0),
    Epic = Color3.fromRGB(150, 0, 255),
    Rare = Color3.fromRGB(0, 150, 255),
    Uncommon = Color3.fromRGB(0, 255, 0),
    Common = Color3.fromRGB(150, 150, 150),
    Iced = Color3.fromRGB(0, 255, 255),
    Candy = Color3.fromRGB(255, 0, 255)
}

local function createFilterToggle(rarity, color, index)
    local FilterBtn = Instance.new("TextButton")
    FilterBtn.Size = UDim2.new(1, -10, 0, 35)
    FilterBtn.Position = UDim2.new(0, 5, 0, 35 + (index * 40))
    FilterBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    FilterBtn.Text = ""
    FilterBtn.Parent = FilterFrame
    
    local BtnCorner = Instance.new("UICorner")
    BtnCorner.CornerRadius = UDim.new(0, 6)
    BtnCorner.Parent = FilterBtn
    
    local ColorBar = Instance.new("Frame")
    ColorBar.Size = UDim2.new(0, 5, 1, -6)
    ColorBar.Position = UDim2.new(0, 3, 0, 3)
    ColorBar.BackgroundColor3 = color
    ColorBar.BorderSizePixel = 0
    ColorBar.Parent = FilterBtn
    
    local ColorCorner = Instance.new("UICorner")
    ColorCorner.CornerRadius = UDim.new(0, 3)
    ColorCorner.Parent = ColorBar
    
    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(1, -70, 1, 0)
    Label.Position = UDim2.new(0, 15, 0, 0)
    Label.BackgroundTransparency = 1
    Label.Text = rarity
    Label.TextColor3 = Color3.fromRGB(255, 255, 255)
    Label.Font = Enum.Font.GothamBold
    Label.TextSize = 13
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = FilterBtn
    
    local CheckBox = Instance.new("Frame")
    CheckBox.Size = UDim2.new(0, 25, 0, 25)
    CheckBox.Position = UDim2.new(1, -35, 0.5, -12.5)
    CheckBox.BackgroundColor3 = Config.SelectedCategories[rarity] and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(60, 60, 70)
    CheckBox.BorderSizePixel = 0
    CheckBox.Parent = FilterBtn
    
    local CheckCorner = Instance.new("UICorner")
    CheckCorner.CornerRadius = UDim.new(0, 4)
    CheckCorner.Parent = CheckBox
    
    local CheckMark = Instance.new("TextLabel")
    CheckMark.Size = UDim2.new(1, 0, 1, 0)
    CheckMark.BackgroundTransparency = 1
    CheckMark.Text = Config.SelectedCategories[rarity] and "✓" or ""
    CheckMark.TextColor3 = Color3.fromRGB(255, 255, 255)
    CheckMark.Font = Enum.Font.GothamBold
    CheckMark.TextSize = 16
    CheckMark.Parent = CheckBox
    
    FilterBtn.MouseButton1Click:Connect(function()
        Config.SelectedCategories[rarity] = not Config.SelectedCategories[rarity]
        if Config.SelectedCategories[rarity] then
            CheckBox.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
            CheckMark.Text = "✓"
        else
            CheckBox.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
            CheckMark.Text = ""
        end
    end)
end

local index = 0
for rarity, color in pairs(rarityColors) do
    createFilterToggle(rarity, color, index)
    index = index + 1
end

FilterFrame.CanvasSize = UDim2.new(0, 0, 0, 35 + (index * 40) + 10)

local ResultsFrame = Instance.new("ScrollingFrame")
ResultsFrame.Size = UDim2.new(1, -20, 1, -430)
ResultsFrame.Position = UDim2.new(0, 10, 0, 340)
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
UIListLayout.Padding = UDim.new(0, 5)
UIListLayout.Parent = ResultsFrame

local StatusLabel = Instance.new("TextLabel")
StatusLabel.Size = UDim2.new(1, -20, 0, 50)
StatusLabel.Position = UDim2.new(0, 10, 1, -60)
StatusLabel.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
StatusLabel.Text = "📊 Ready to Scan\n💎 Items Found: 0"
StatusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
StatusLabel.Font = Enum.Font.GothamBold
StatusLabel.TextSize = 13
StatusLabel.Parent = MainFrame

local StatusCorner = Instance.new("UICorner")
StatusCorner.CornerRadius = UDim.new(0, 8)
StatusCorner.Parent = StatusLabel

local isMinimized = false
MinimizeBtn.MouseButton1Click:Connect(function()
    isMinimized = not isMinimized
    if isMinimized then
        TweenService:Create(MainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {Size = UDim2.new(0, 450, 0, 60)}):Play()
        MinimizeBtn.Text = "+"
        ControlFrame.Visible = false
        FilterFrame.Visible = false
        ResultsFrame.Visible = false
        StatusLabel.Visible = false
    else
        TweenService:Create(MainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {Size = UDim2.new(0, 450, 0, 600)}):Play()
        MinimizeBtn.Text = "−"
        task.wait(0.3)
        ControlFrame.Visible = true
        FilterFrame.Visible = true
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

local function createItemCard(itemName, currentLevel, currentValue, level1Value, rarity)
    local ItemCard = Instance.new("Frame")
    ItemCard.Size = UDim2.new(1, -10, 0, 95)
    ItemCard.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    ItemCard.BorderSizePixel = 0
    ItemCard.Parent = ResultsFrame
    
    local CardCorner = Instance.new("UICorner")
    CardCorner.CornerRadius = UDim.new(0, 8)
    CardCorner.Parent = ItemCard
    
    local rarityColor = rarityColors[rarity] or Color3.fromRGB(150, 150, 150)
    
    local ColorBar = Instance.new("Frame")
    ColorBar.Size = UDim2.new(0, 6, 1, -10)
    ColorBar.Position = UDim2.new(0, 5, 0, 5)
    ColorBar.BackgroundColor3 = rarityColor
    ColorBar.BorderSizePixel = 0
    ColorBar.Parent = ItemCard
    
    local ColorCorner = Instance.new("UICorner")
    ColorCorner.CornerRadius = UDim.new(0, 3)
    ColorCorner.Parent = ColorBar
    
    local ItemName = Instance.new("TextLabel")
    ItemName.Size = UDim2.new(1, -80, 0, 20)
    ItemName.Position = UDim2.new(0, 20, 0, 5)
    ItemName.BackgroundTransparency = 1
    ItemName.Text = "📦 " .. itemName
    ItemName.TextColor3 = Color3.fromRGB(255, 255, 255)
    ItemName.Font = Enum.Font.GothamBold
    ItemName.TextSize = 14
    ItemName.TextXAlignment = Enum.TextXAlignment.Left
    ItemName.Parent = ItemCard
    
    local RarityLabel = Instance.new("TextLabel")
    RarityLabel.Size = UDim2.new(0, 80, 0, 20)
    RarityLabel.Position = UDim2.new(1, -85, 0, 5)
    RarityLabel.BackgroundColor3 = rarityColor
    RarityLabel.Text = rarity
    RarityLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    RarityLabel.Font = Enum.Font.GothamBold
    RarityLabel.TextSize = 11
    RarityLabel.Parent = ItemCard
    
    local RarityCorner = Instance.new("UICorner")
    RarityCorner.CornerRadius = UDim.new(0, 4)
    RarityCorner.Parent = RarityLabel
    
    local CurrentInfo = Instance.new("TextLabel")
    CurrentInfo.Size = UDim2.new(1, -25, 0, 18)
    CurrentInfo.Position = UDim2.new(0, 20, 0, 28)
    CurrentInfo.BackgroundTransparency = 1
    CurrentInfo.Text = string.format("⭐ Current Level %d: %s", currentLevel, currentValue)
    CurrentInfo.TextColor3 = Color3.fromRGB(100, 200, 255)
    CurrentInfo.Font = Enum.Font.Gotham
    CurrentInfo.TextSize = 12
    CurrentInfo.TextXAlignment = Enum.TextXAlignment.Left
    CurrentInfo.Parent = ItemCard
    
    local Divider = Instance.new("Frame")
    Divider.Size = UDim2.new(1, -30, 0, 2)
    Divider.Position = UDim2.new(0, 15, 0, 50)
    Divider.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
    Divider.BorderSizePixel = 0
    Divider.Parent = ItemCard
    
    local Level1Info = Instance.new("TextLabel")
    Level1Info.Size = UDim2.new(1, -25, 0, 35)
    Level1Info.Position = UDim2.new(0, 20, 0, 56)
    Level1Info.BackgroundTransparency = 1
    Level1Info.Text = string.format("💎 Level 1 Value: %s\n📈 Growth: %dx", level1Value, currentLevel)
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
    local num, suffix = text:match("%$?([%d%.]+)([KkMmBbTtQqSsPpNnOo][AaDdXx]?)")
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
            ["K"] = 1e3,
            ["M"] = 1e6,
            ["B"] = 1e9,
            ["T"] = 1e12,
            ["QA"] = 1e15,
            ["QI"] = 1e18,
            ["SX"] = 1e21,
            ["SP"] = 1e24,
            ["OC"] = 1e27,
            ["NO"] = 1e30,
            ["DC"] = 1e33,
            ["UD"] = 1e36,
            ["DD"] = 1e39,
            ["TD"] = 1e42,
            ["QD"] = 1e45,
            ["QID"] = 1e48,
            ["SD"] = 1e51,
            ["SPD"] = 1e54,
            ["OD"] = 1e57,
            ["ND"] = 1e60
        }
        multiplier = suffixMap[suffix] or 1
    end
    return num * multiplier
end

local function formatValue(value)
    local suffixes = {
        {1e60, "ND"},
        {1e57, "OD"},
        {1e54, "SPD"},
        {1e51, "SD"},
        {1e48, "QID"},
        {1e45, "QD"},
        {1e42, "TD"},
        {1e39, "DD"},
        {1e36, "UD"},
        {1e33, "DC"},
        {1e30, "NO"},
        {1e27, "OC"},
        {1e24, "SP"},
        {1e21, "SX"},
        {1e18, "QI"},
        {1e15, "QA"},
        {1e12, "T"},
        {1e9, "B"},
        {1e6, "M"},
        {1e3, "K"}
    }
    for _, data in ipairs(suffixes) do
        if value >= data[1] then
            return string.format("$%.2f%s", value / data[1], data[2])
        end
    end
    return string.format("$%.0f", value)
end

local function calculateLevel1Value(currentLevel, currentValue)
    if currentLevel <= 1 then return currentValue end
    local level1Value = currentValue / (Config.UpgradeMultiplier ^ (currentLevel - 1))
    return level1Value
end

local function detectRarity(text)
    text = text:lower()
    if text:find("secret") then return "Secret"
    elseif text:find("og") then return "OG"
    elseif text:find("god") then return "God"
    elseif text:find("legend") then return "Legendary"
    elseif text:find("myth") then return "Mythic"
    elseif text:find("epic") then return "Epic"
    elseif text:find("rare") then return "Rare"
    elseif text:find("uncommon") then return "Uncommon"
    elseif text:find("iced") then return "Iced"
    elseif text:find("candy") then return "Candy"
    elseif text:find("common") then return "Common"
    end
    return "Common"
end

local function scanInventory()
    if isScanning then return end
    isScanning = true
    clearResults()
    scannedItems = {}
    StatusLabel.Text = "🔄 Scanning Inventory..."
    local itemCount = 0
    for _, gui in pairs(PlayerGui:GetDescendants()) do
        if gui:IsA("TextLabel") and gui.Visible then
            local text = gui.Text
            if text:match("Level%s*(%d+)") then
                local level = tonumber(text:match("Level%s*(%d+)"))
                if level and level > 0 then
                    local parent = gui.Parent
                    if parent then
                        local itemName = "Unknown Item"
                        local value = 0
                        local rarity = "Common"
                        for _, child in pairs(parent:GetDescendants()) do
                            if child:IsA("TextLabel") then
                                local childText = child.Text
                                if not childText:match("Level") and not childText:match("%$") and childText ~= "" and childText:len() > 3 then
                                    itemName = childText
                                    rarity = detectRarity(childText)
                                elseif childText:match("%$") then
                                    local val = parseValue(childText)
                                    if val > value then
                                        value = val
                                    end
                                end
                            end
                        end
                        if value > 0 and Config.SelectedCategories[rarity] then
                            local level1Value = calculateLevel1Value(level, value)
                            table.insert(scannedItems, {
                                Name = itemName,
                                CurrentLevel = level,
                                CurrentValue = value,
                                Level1Value = level1Value,
                                Rarity = rarity
                            })
                            itemCount = itemCount + 1
                        end
                    end
                end
            end
        end
    end
    table.sort(scannedItems, function(a, b) return a.Level1Value > b.Level1Value end)
    for _, item in pairs(scannedItems) do
        createItemCard(
            item.Name,
            item.CurrentLevel,
            formatValue(item.CurrentValue),
            formatValue(item.Level1Value),
            item.Rarity
        )
    end
    ResultsFrame.CanvasSize = UDim2.new(0, 0, 0, UIListLayout.AbsoluteContentSize.Y + 10)
    StatusLabel.Text = string.format("✅ Scan Complete!\n💎 Items Found: %d", itemCount)
    isScanning = false
end

ScanNowBtn.MouseButton1Click:Connect(function()
    scanInventory()
end)

AutoScanToggle.MouseButton1Click:Connect(function()
    Config.AutoScan = not Config.AutoScan
    if Config.AutoScan then
        AutoScanToggle.Text = "ON"
        AutoScanToggle.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
        task.spawn(function()
            while Config.AutoScan do
                scanInventory()
                task.wait(Config.ScanInterval)
            end
        end)
    else
        AutoScanToggle.Text = "OFF"
        AutoScanToggle.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
    end
end)

print("╔══════════════════════════════════════════════════════╗")
print("║   VALUE CALCULATOR - Successfully Loaded!            ║")
print("║   Formula: Level1 = Current ÷ (2.5 ^ (Level-1))     ║")
print("╚══════════════════════════════════════════════════════╝")
