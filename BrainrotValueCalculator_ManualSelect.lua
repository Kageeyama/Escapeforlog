--[[
    ╔══════════════════════════════════════════════════════════╗
    ║       BRAINROT VALUE CALCULATOR - MANUAL SELECT          ║
    ║         Select Item Manually, Calculate Level 1          ║
    ╚══════════════════════════════════════════════════════════╝
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer
local PlayerGui = player:WaitForChild("PlayerGui")

local Config = {
    UpgradeMultiplier = 1.25,
    SelectedItem = nil
}

local detectedItems = {}

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ValueCalculator_UI"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = PlayerGui

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 520, 0, 680)
MainFrame.Position = UDim2.new(0.5, -260, 0.5, -340)
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
Header.Size = UDim2.new(1, 0, 0, 75)
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
Subtitle.Text = "Select Item → Calculate Level 1 Value"
Subtitle.TextColor3 = Color3.fromRGB(150, 150, 150)
Subtitle.Font = Enum.Font.Gotham
Subtitle.TextSize = 12
Subtitle.TextXAlignment = Enum.TextXAlignment.Left
Subtitle.Parent = Header

local MultiplierLabel = Instance.new("TextLabel")
MultiplierLabel.Size = UDim2.new(1, -100, 0, 14)
MultiplierLabel.Position = UDim2.new(0, 15, 0, 58)
MultiplierLabel.BackgroundTransparency = 1
MultiplierLabel.Text = "⚙️ Multiplier: 1.25x per level"
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

local ScanBtn = Instance.new("TextButton")
ScanBtn.Size = UDim2.new(1, -20, 0, 50)
ScanBtn.Position = UDim2.new(0, 10, 0, 85)
ScanBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
ScanBtn.Text = "🔍 DETECT ITEMS IN INVENTORY"
ScanBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ScanBtn.Font = Enum.Font.GothamBold
ScanBtn.TextSize = 16
ScanBtn.Parent = MainFrame

local ScanBtnCorner = Instance.new("UICorner")
ScanBtnCorner.CornerRadius = UDim.new(0, 8)
ScanBtnCorner.Parent = ScanBtn

local SelectionTitle = Instance.new("TextLabel")
SelectionTitle.Size = UDim2.new(1, -20, 0, 30)
SelectionTitle.Position = UDim2.new(0, 10, 0, 145)
SelectionTitle.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
SelectionTitle.Text = "📋 SELECT ITEM TO CALCULATE"
SelectionTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
SelectionTitle.Font = Enum.Font.GothamBold
SelectionTitle.TextSize = 14
SelectionTitle.Parent = MainFrame

local SelectTitleCorner = Instance.new("UICorner")
SelectTitleCorner.CornerRadius = UDim.new(0, 8)
SelectTitleCorner.Parent = SelectionTitle

local ItemListFrame = Instance.new("ScrollingFrame")
ItemListFrame.Size = UDim2.new(1, -20, 0, 300)
ItemListFrame.Position = UDim2.new(0, 10, 0, 185)
ItemListFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
ItemListFrame.BorderSizePixel = 0
ItemListFrame.ScrollBarThickness = 6
ItemListFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
ItemListFrame.Parent = MainFrame

local ListCorner = Instance.new("UICorner")
ListCorner.CornerRadius = UDim.new(0, 8)
ListCorner.Parent = ItemListFrame

local ItemListLayout = Instance.new("UIListLayout")
ItemListLayout.SortOrder = Enum.SortOrder.LayoutOrder
ItemListLayout.Padding = UDim.new(0, 5)
ItemListLayout.Parent = ItemListFrame

local ResultFrame = Instance.new("Frame")
ResultFrame.Size = UDim2.new(1, -20, 0, 165)
ResultFrame.Position = UDim2.new(0, 10, 0, 495)
ResultFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
ResultFrame.BorderSizePixel = 0
ResultFrame.Visible = false
ResultFrame.Parent = MainFrame

local ResultCorner = Instance.new("UICorner")
ResultCorner.CornerRadius = UDim.new(0, 8)
ResultCorner.Parent = ResultFrame

local ResultTitle = Instance.new("TextLabel")
ResultTitle.Size = UDim2.new(1, -10, 0, 25)
ResultTitle.Position = UDim2.new(0, 5, 0, 5)
ResultTitle.BackgroundTransparency = 1
ResultTitle.Text = "📊 CALCULATION RESULT"
ResultTitle.TextColor3 = Color3.fromRGB(255, 215, 0)
ResultTitle.Font = Enum.Font.GothamBold
ResultTitle.TextSize = 14
ResultTitle.Parent = ResultFrame

local ResultItemName = Instance.new("TextLabel")
ResultItemName.Size = UDim2.new(1, -10, 0, 22)
ResultItemName.Position = UDim2.new(0, 5, 0, 32)
ResultItemName.BackgroundTransparency = 1
ResultItemName.Text = "📦 Item Name"
ResultItemName.TextColor3 = Color3.fromRGB(255, 255, 255)
ResultItemName.Font = Enum.Font.GothamBold
ResultItemName.TextSize = 15
ResultItemName.TextXAlignment = Enum.TextXAlignment.Left
ResultItemName.Parent = ResultFrame

local ResultDivider1 = Instance.new("Frame")
ResultDivider1.Size = UDim2.new(1, -20, 0, 2)
ResultDivider1.Position = UDim2.new(0, 10, 0, 60)
ResultDivider1.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
ResultDivider1.BorderSizePixel = 0
ResultDivider1.Parent = ResultFrame

local ResultCurrentLevel = Instance.new("TextLabel")
ResultCurrentLevel.Size = UDim2.new(1, -10, 0, 20)
ResultCurrentLevel.Position = UDim2.new(0, 5, 0, 68)
ResultCurrentLevel.BackgroundTransparency = 1
ResultCurrentLevel.Text = "⭐ Current: Level 0 = $0"
ResultCurrentLevel.TextColor3 = Color3.fromRGB(100, 200, 255)
ResultCurrentLevel.Font = Enum.Font.Gotham
ResultCurrentLevel.TextSize = 13
ResultCurrentLevel.TextXAlignment = Enum.TextXAlignment.Left
ResultCurrentLevel.Parent = ResultFrame

local ResultDivider2 = Instance.new("Frame")
ResultDivider2.Size = UDim2.new(1, -20, 0, 2)
ResultDivider2.Position = UDim2.new(0, 10, 0, 95)
ResultDivider2.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
ResultDivider2.BorderSizePixel = 0
ResultDivider2.Parent = ResultFrame

local ResultLevel1Value = Instance.new("TextLabel")
ResultLevel1Value.Size = UDim2.new(1, -10, 0, 25)
ResultLevel1Value.Position = UDim2.new(0, 5, 0, 103)
ResultLevel1Value.BackgroundTransparency = 1
ResultLevel1Value.Text = "💎 Level 1 Value: $0"
ResultLevel1Value.TextColor3 = Color3.fromRGB(100, 255, 100)
ResultLevel1Value.Font = Enum.Font.GothamBold
ResultLevel1Value.TextSize = 16
ResultLevel1Value.TextXAlignment = Enum.TextXAlignment.Left
ResultLevel1Value.Parent = ResultFrame

local ResultGrowth = Instance.new("TextLabel")
ResultGrowth.Size = UDim2.new(1, -10, 0, 20)
ResultGrowth.Position = UDim2.new(0, 5, 0, 135)
ResultGrowth.BackgroundTransparency = 1
ResultGrowth.Text = "📈 Growth: 0x"
ResultGrowth.TextColor3 = Color3.fromRGB(150, 150, 150)
ResultGrowth.Font = Enum.Font.Gotham
ResultGrowth.TextSize = 12
ResultGrowth.TextXAlignment = Enum.TextXAlignment.Left
ResultGrowth.Parent = ResultFrame

local isMinimized = false
MinimizeBtn.MouseButton1Click:Connect(function()
    isMinimized = not isMinimized
    if isMinimized then
        TweenService:Create(MainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {Size = UDim2.new(0, 520, 0, 75)}):Play()
        MinimizeBtn.Text = "+"
        ScanBtn.Visible = false
        SelectionTitle.Visible = false
        ItemListFrame.Visible = false
        ResultFrame.Visible = false
    else
        TweenService:Create(MainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {Size = UDim2.new(0, 520, 0, 680)}):Play()
        MinimizeBtn.Text = "−"
        task.wait(0.3)
        ScanBtn.Visible = true
        SelectionTitle.Visible = true
        ItemListFrame.Visible = true
        if Config.SelectedItem then
            ResultFrame.Visible = true
        end
    end
end)

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

local function parseValue(text)
    if not text then return 0 end
    text = text:gsub(",", ""):gsub("%s+", "")
    
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
    
    local level1Value = currentValue / (Config.UpgradeMultiplier ^ (currentLevel - 1))
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

local function clearItemList()
    for _, child in pairs(ItemListFrame:GetChildren()) do
        if child:IsA("TextButton") then
            child:Destroy()
        end
    end
end

local function createItemButton(itemData, index)
    local ItemBtn = Instance.new("TextButton")
    ItemBtn.Size = UDim2.new(1, -10, 0, 70)
    ItemBtn.Position = UDim2.new(0, 5, 0, (index - 1) * 75)
    ItemBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    ItemBtn.Text = ""
    ItemBtn.AutoButtonColor = false
    ItemBtn.Parent = ItemListFrame
    
    local BtnCorner = Instance.new("UICorner")
    BtnCorner.CornerRadius = UDim.new(0, 8)
    BtnCorner.Parent = ItemBtn
    
    local categoryLower = itemData.Category:lower()
    local categoryColor = rarityColors[categoryLower] or Color3.fromRGB(150, 150, 150)
    
    local ColorBar = Instance.new("Frame")
    ColorBar.Size = UDim2.new(0, 5, 1, -8)
    ColorBar.Position = UDim2.new(0, 4, 0, 4)
    ColorBar.BackgroundColor3 = categoryColor
    ColorBar.BorderSizePixel = 0
    ColorBar.Parent = ItemBtn
    
    local ColorCorner = Instance.new("UICorner")
    ColorCorner.CornerRadius = UDim.new(0, 3)
    ColorCorner.Parent = ColorBar
    
    local ItemName = Instance.new("TextLabel")
    ItemName.Size = UDim2.new(1, -100, 0, 20)
    ItemName.Position = UDim2.new(0, 15, 0, 8)
    ItemName.BackgroundTransparency = 1
    ItemName.Text = "📦 " .. itemData.Name
    ItemName.TextColor3 = Color3.fromRGB(255, 255, 255)
    ItemName.Font = Enum.Font.GothamBold
    ItemName.TextSize = 14
    ItemName.TextXAlignment = Enum.TextXAlignment.Left
    ItemName.Parent = ItemBtn
    
    local CategoryBadge = Instance.new("TextLabel")
    CategoryBadge.Size = UDim2.new(0, 80, 0, 20)
    CategoryBadge.Position = UDim2.new(1, -85, 0, 8)
    CategoryBadge.BackgroundColor3 = categoryColor
    CategoryBadge.Text = itemData.Category:upper()
    CategoryBadge.TextColor3 = Color3.fromRGB(255, 255, 255)
    CategoryBadge.Font = Enum.Font.GothamBold
    CategoryBadge.TextSize = 10
    CategoryBadge.Parent = ItemBtn
    
    local BadgeCorner = Instance.new("UICorner")
    BadgeCorner.CornerRadius = UDim.new(0, 4)
    BadgeCorner.Parent = CategoryBadge
    
    local ItemInfo = Instance.new("TextLabel")
    ItemInfo.Size = UDim2.new(1, -15, 0, 35)
    ItemInfo.Position = UDim2.new(0, 15, 0, 32)
    ItemInfo.BackgroundTransparency = 1
    ItemInfo.Text = string.format("Level %d | %s", itemData.Level, itemData.ValueStr)
    ItemInfo.TextColor3 = Color3.fromRGB(150, 200, 255)
    ItemInfo.Font = Enum.Font.Gotham
    ItemInfo.TextSize = 13
    ItemInfo.TextXAlignment = Enum.TextXAlignment.Left
    ItemInfo.Parent = ItemBtn
    
    ItemBtn.MouseButton1Click:Connect(function()
        Config.SelectedItem = itemData
        
        for _, btn in pairs(ItemListFrame:GetChildren()) do
            if btn:IsA("TextButton") then
                btn.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
            end
        end
        ItemBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
        
        local level1Value = calculateLevel1Value(itemData.Level, itemData.ValueRaw)
        local growth = itemData.ValueRaw / level1Value
        
        ResultItemName.Text = "📦 " .. itemData.Name
        ResultCurrentLevel.Text = string.format("⭐ Current: Level %d = %s", itemData.Level, itemData.ValueStr)
        ResultLevel1Value.Text = "💎 Level 1 Value: " .. formatValue(level1Value)
        ResultGrowth.Text = string.format("📈 Growth: %.1fx (%.0f%%)", growth, (growth - 1) * 100)
        
        ResultFrame.Visible = true
    end)
end

local function scanInventory()
    clearItemList()
    detectedItems = {}
    ResultFrame.Visible = false
    Config.SelectedItem = nil
    
    ScanBtn.Text = "🔄 SCANNING..."
    ScanBtn.BackgroundColor3 = Color3.fromRGB(255, 150, 0)
    
    task.wait(0.5)
    
    for _, gui in pairs(PlayerGui:GetDescendants()) do
        if gui:IsA("TextLabel") and gui.Visible and gui.Parent then
            local text = gui.Text
            
            if text:match("Level%s*%d+") then
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
                        local exists = false
                        for _, item in pairs(detectedItems) do
                            if item.Name == itemName and item.Level == level then
                                exists = true
                                break
                            end
                        end
                        
                        if not exists then
                            table.insert(detectedItems, {
                                Name = itemName,
                                Level = level,
                                ValueRaw = valueRaw,
                                ValueStr = formatValue(valueRaw),
                                Category = category
                            })
                        end
                    end
                end
            end
        end
    end
    
    table.sort(detectedItems, function(a, b) 
        return a.ValueRaw > b.ValueRaw 
    end)
    
    for i, item in ipairs(detectedItems) do
        createItemButton(item, i)
    end
    
    ItemListFrame.CanvasSize = UDim2.new(0, 0, 0, ItemListLayout.AbsoluteContentSize.Y + 10)
    
    ScanBtn.Text = string.format("✅ FOUND %d ITEMS - CLICK TO RESCAN", #detectedItems)
    ScanBtn.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
    
    task.wait(2)
    ScanBtn.Text = "🔍 DETECT ITEMS IN INVENTORY"
    ScanBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
end

ScanBtn.MouseButton1Click:Connect(function()
    scanInventory()
end)

print("╔══════════════════════════════════════════════════════╗")
print("║   VALUE CALCULATOR - Successfully Loaded!            ║")
print("║   Multiplier: 1.25x per level                        ║")
print("║   1. Click DETECT ITEMS                              ║")
print("║   2. Select item from list                           ║")
print("║   3. See Level 1 value calculation                   ║")
print("╚══════════════════════════════════════════════════════╝")
