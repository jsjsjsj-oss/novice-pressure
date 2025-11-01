-- Pressure透视辅助脚本 - 完整修复版
-- 卡密: 粉丝NB

local correctPassword = "粉丝NB"
local authenticated = false

-- 创建验证界面
local AuthGui = Instance.new("ScreenGui")
AuthGui.Parent = game.CoreGui

local AuthFrame = Instance.new("Frame")
AuthFrame.Size = UDim2.new(0, 350, 0, 250)
AuthFrame.Position = UDim2.new(0.35, 0, 0.35, 0)
AuthFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
AuthFrame.Parent = AuthGui

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 50)
Title.Position = UDim2.new(0, 0, 0, 10)
Title.BackgroundTransparency = 1
Title.Text = "Pressure完整透视系统\n物品+怪物检测与警报"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 18
Title.Font = Enum.Font.GothamBold
Title.TextWrapped = true
Title.Parent = AuthFrame

local PasswordBox = Instance.new("TextBox")
PasswordBox.Size = UDim2.new(0.8, 0, 0, 35)
PasswordBox.Position = UDim2.new(0.1, 0, 0.4, 0)
PasswordBox.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
PasswordBox.TextColor3 = Color3.fromRGB(255, 255, 255)
PasswordBox.PlaceholderText = "输入卡密: 粉丝NB"
PasswordBox.Text = ""
PasswordBox.Parent = AuthFrame

local SubmitButton = Instance.new("TextButton")
SubmitButton.Size = UDim2.new(0.5, 0, 0, 35)
SubmitButton.Position = UDim2.new(0.25, 0, 0.65, 0)
SubmitButton.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
SubmitButton.Text = "验证卡密"
SubmitButton.TextColor3 = Color3.fromRGB(255, 255, 255)
SubmitButton.Parent = AuthFrame

local StatusLabel = Instance.new("TextLabel")
StatusLabel.Size = UDim2.new(1, 0, 0, 20)
StatusLabel.Position = UDim2.new(0, 0, 0.85, 0)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Text = "等待验证..."
StatusLabel.TextColor3 = Color3.fromRGB(255, 255, 0)
StatusLabel.Parent = AuthFrame

-- 验证函数
local function checkPassword()
    local input = PasswordBox.Text
    if input == correctPassword then
        StatusLabel.Text = "验证成功！加载中..."
        StatusLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
        wait(1)
        AuthGui:Destroy()
        authenticated = true
        InitializeScript()
    else
        StatusLabel.Text = "卡密错误！3秒后踢出"
        StatusLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
        wait(3)
        game.Players.LocalPlayer:Kick("卡密不匹配")
    end
end

SubmitButton.MouseButton1Click:Connect(checkPassword)

PasswordBox.FocusLost:Connect(function(enterPressed)
    if enterPressed then
        checkPassword()
    end
end)

-- 主功能脚本
function InitializeScript()
    local Workspace = game:GetService("Workspace")
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local UserInputService = game:GetService("UserInputService")
    local localPlayer = Players.LocalPlayer

    -- 初始化功能变量
    local espEnabled = false
    local nightVisionEnabled = false
    local highlightEnabled = false  -- 默认关闭，需要手动开启
    local monsterAlertEnabled = true
    local fastRunEnabled = false
    local lastMonsterAlert = 0
    local alertCooldown = 2.5
    local highlightedObjects = {}
    local espLabels = {}  -- 存储ESP文字标签
    local originalWalkSpeed = 16

    -- 获取玩家移动速度
    local function getPlayerSpeed()
        local character = localPlayer.Character
        if character then
            local humanoid = character:FindFirstChild("Humanoid")
            if humanoid then
                originalWalkSpeed = humanoid.WalkSpeed
                return humanoid.WalkSpeed
            end
        end
        return 16
    end

    -- 设置玩家移动速度
    local function setPlayerSpeed(speed)
        local character = localPlayer.Character
        if character then
            local humanoid = character:FindFirstChild("Humanoid")
            if humanoid then
                humanoid.WalkSpeed = speed
            end
        end
    end

    -- 创建彩色时间显示
    local TimeGui = Instance.new("ScreenGui")
    local TimeLabel = Instance.new("TextLabel")
    
    TimeGui.Name = "PressureHelperGUI"
    TimeGui.Parent = game.CoreGui
    TimeGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    
    TimeLabel.Name = "TimeDisplay"
    TimeLabel.Parent = TimeGui
    TimeLabel.BackgroundTransparency = 1
    TimeLabel.BorderSizePixel = 0
    TimeLabel.Position = UDim2.new(0.75, 0, 0.02, 0)
    TimeLabel.Size = UDim2.new(0, 220, 0, 35)
    TimeLabel.Font = Enum.Font.GothamBold
    TimeLabel.Text = "🕒 加载中..."
    TimeLabel.TextColor3 = Color3.new(1, 1, 1)
    TimeLabel.TextSize = 18
    TimeLabel.TextStrokeTransparency = 0.5
    TimeLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
    TimeLabel.TextXAlignment = Enum.TextXAlignment.Center

    -- 彩色渐变文字效果
    spawn(function()
        local colorTransition = 0
        while true do
            colorTransition = (colorTransition + 0.02) % 1
            local currentTime = os.date("*t")
            local timeText = string.format("🕒 %02d:%02d:%02d", currentTime.hour, currentTime.min, currentTime.sec)
            TimeLabel.Text = timeText
            
            local r = math.sin(colorTransition * math.pi * 2 + 0) * 0.5 + 0.5
            local g = math.sin(colorTransition * math.pi * 2 + 2) * 0.5 + 0.5
            local b = math.sin(colorTransition * math.pi * 2 + 4) * 0.5 + 0.5
            
            TimeLabel.TextColor3 = Color3.new(r, g, b)
            wait(0.05)
        end
    end)

    -- 完整的物品配置 - 修复door检测
    local objectTypes = {
        DOOR = {
            keywords = {"door", "doorhandle", "entrance", "exit", "gate"},
            color = Color3.fromRGB(0, 255, 255),
            label = "🚪 门",
            enabled = true
        },
        LOCKER = {
            keywords = {"locker", "lockers", "储物柜", "cabinet", "hide", "躲藏", "closet", "storage"},
            color = Color3.fromRGB(148, 0, 211),
            label = "🗄️ 储物柜", 
            enabled = true
        },
        DRAWER = {
            keywords = {"drawer", "抽屉", "desk", "桌子", "cabinet"},
            color = Color3.fromRGB(255, 105, 180),
            label = "📦 抽屉",
            enabled = true
        },
        BATTERY = {
            keywords = {"battery", "电池", "power", "energy", "cell"},
            color = Color3.fromRGB(255, 165, 0),
            label = "🔋 电池",
            enabled = true
        },
        KEY = {
            keywords = {"key", "钥匙", "card", "卡", "keycard"},
            color = Color3.fromRGB(255, 215, 0),
            label = "🔑 钥匙",
            enabled = true
        },
        EXIT = {
            keywords = {"exit", "出口", "escape", "leave", "escapepod"},
            color = Color3.fromRGB(0, 255, 0),
            label = "🚪 出口",
            enabled = true
        },
        GENERATOR = {
            keywords = {"generator", "发电机", "power", "gen", "engine"},
            color = Color3.fromRGB(255, 69, 0),
            label = "🔌 发电机",
            enabled = true
        },
        FAKE_LOCKER = {
            keywords = {"fake", "trap", "假", "陷阱", "decoy"},
            color = Color3.fromRGB(255, 0, 0),
            label = "❌ 假柜子",
            enabled = true
        }
    }

    -- 修复的UI库
    local OrionLib = {}
    function OrionLib:MakeWindow(config)
        local Window = {}
        local Tabs = {}
        
        local ScreenGui = Instance.new("ScreenGui")
        local MainFrame = Instance.new("Frame")
        local TabButtons = Instance.new("Frame")
        local UIListLayout = Instance.new("UIListLayout")
        
        ScreenGui.Name = "OrionLib"
        ScreenGui.Parent = game.CoreGui
        ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        
        MainFrame.Name = "MainFrame"
        MainFrame.Parent = ScreenGui
        MainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        MainFrame.BorderSizePixel = 0
        MainFrame.Position = UDim2.new(0.3, 0, 0.3, 0)
        MainFrame.Size = UDim2.new(0, 500, 0, 350)
        MainFrame.Active = true
        MainFrame.Draggable = true
        
        local TopBar = Instance.new("Frame")
        TopBar.Name = "TopBar"
        TopBar.Parent = MainFrame
        TopBar.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
        TopBar.BorderSizePixel = 0
        TopBar.Size = UDim2.new(1, 0, 0, 30)
        
        local Title = Instance.new("TextLabel")
        Title.Name = "Title"
        Title.Parent = TopBar
        Title.BackgroundTransparency = 1
        Title.Position = UDim2.new(0, 10, 0, 0)
        Title.Size = UDim2.new(0, 200, 1, 0)
        Title.Font = Enum.Font.GothamBold
        Title.Text = config.Name or "Pressure透视辅助"
        Title.TextColor3 = Color3.fromRGB(255, 255, 255)
        Title.TextSize = 14
        Title.TextXAlignment = Enum.TextXAlignment.Left
        
        local CloseButton = Instance.new("TextButton")
        CloseButton.Name = "CloseButton"
        CloseButton.Parent = TopBar
        CloseButton.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
        CloseButton.BorderSizePixel = 0
        CloseButton.Position = UDim2.new(1, -30, 0, 5)
        CloseButton.Size = UDim2.new(0, 20, 0, 20)
        CloseButton.Font = Enum.Font.GothamBold
        CloseButton.Text = "X"
        CloseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        CloseButton.TextSize = 12
        
        CloseButton.MouseButton1Click:Connect(function()
            ScreenGui:Destroy()
        end)
        
        TabButtons.Name = "TabButtons"
        TabButtons.Parent = MainFrame
        TabButtons.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
        TabButtons.BorderSizePixel = 0
        TabButtons.Position = UDim2.new(0, 0, 0, 30)
        TabButtons.Size = UDim2.new(0, 120, 0, 320)
        
        UIListLayout.Parent = TabButtons
        UIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
        UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
        UIListLayout.Padding = UDim.new(0, 5)
        
        local ContentArea = Instance.new("Frame")
        ContentArea.Name = "ContentArea"
        ContentArea.Parent = MainFrame
        ContentArea.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        ContentArea.BorderSizePixel = 0
        ContentArea.Position = UDim2.new(0, 120, 0, 30)
        ContentArea.Size = UDim2.new(0, 380, 0, 320)
        
        function Window:MakeTab(tabConfig)
            local Tab = {}
            
            local TabButton = Instance.new("TextButton")
            TabButton.Name = tabConfig.Name
            TabButton.Parent = TabButtons
            TabButton.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
            TabButton.BorderSizePixel = 0
            TabButton.Size = UDim2.new(0, 110, 0, 30)
            TabButton.Font = Enum.Font.Gotham
            TabButton.Text = tabConfig.Name
            TabButton.TextColor3 = Color3.fromRGB(255, 255, 255)
            TabButton.TextSize = 12
            
            local TabContent = Instance.new("ScrollingFrame")
            TabContent.Name = tabConfig.Name
            TabContent.Parent = ContentArea
            TabContent.Active = true
            TabContent.BackgroundTransparency = 1
            TabContent.BorderSizePixel = 0
            TabContent.Size = UDim2.new(1, 0, 1, 0)
            TabContent.CanvasSize = UDim2.new(0, 0, 0, 0)
            TabContent.ScrollBarThickness = 3
            TabContent.Visible = false
            
            local ContentLayout = Instance.new("UIListLayout")
            ContentLayout.Parent = TabContent
            ContentLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
            ContentLayout.SortOrder = Enum.SortOrder.LayoutOrder
            ContentLayout.Padding = UDim.new(0, 5)
            
            ContentLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                TabContent.CanvasSize = UDim2.new(0, 0, 0, ContentLayout.AbsoluteContentSize.Y + 10)
            end)
            
            if #Tabs == 0 then
                TabContent.Visible = true
                TabButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
            end
            
            TabButton.MouseButton1Click:Connect(function()
                for _, otherTab in pairs(ContentArea:GetChildren()) do
                    if otherTab:IsA("ScrollingFrame") then
                        otherTab.Visible = false
                    end
                end
                for _, otherButton in pairs(TabButtons:GetChildren()) do
                    if otherButton:IsA("TextButton") then
                        otherButton.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
                    end
                end
                TabContent.Visible = true
                TabButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
            end)
            
            table.insert(Tabs, Tab)
            
            function Tab:AddButton(buttonConfig)
                local Button = Instance.new("TextButton")
                Button.Name = buttonConfig.Name
                Button.Parent = TabContent
                Button.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
                Button.BorderSizePixel = 0
                Button.Size = UDim2.new(0, 350, 0, 35)
                Button.Font = Enum.Font.Gotham
                Button.Text = buttonConfig.Name
                Button.TextColor3 = Color3.fromRGB(255, 255, 255)
                Button.TextSize = 12
                
                if buttonConfig.Callback then
                    Button.MouseButton1Click:Connect(buttonConfig.Callback)
                end
                
                return Button
            end
            
            function Tab:AddToggle(toggleConfig)
                local ToggleFrame = Instance.new("Frame")
                ToggleFrame.Name = toggleConfig.Name
                ToggleFrame.Parent = TabContent
                ToggleFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
                ToggleFrame.BorderSizePixel = 0
                ToggleFrame.Size = UDim2.new(0, 350, 0, 35)
                
                local ToggleLabel = Instance.new("TextLabel")
                ToggleLabel.Name = "Label"
                ToggleLabel.Parent = ToggleFrame
                ToggleLabel.BackgroundTransparency = 1
                ToggleLabel.Position = UDim2.new(0, 10, 0, 0)
                ToggleLabel.Size = UDim2.new(0, 250, 1, 0)
                ToggleLabel.Font = Enum.Font.Gotham
                ToggleLabel.Text = toggleConfig.Name
                ToggleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
                ToggleLabel.TextSize = 12
                ToggleLabel.TextXAlignment = Enum.TextXAlignment.Left
                
                local ToggleButton = Instance.new("TextButton")
                ToggleButton.Name = "Toggle"
                ToggleButton.Parent = ToggleFrame
                ToggleButton.BackgroundColor3 = toggleConfig.Default and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)
                ToggleButton.BorderSizePixel = 0
                ToggleButton.Position = UDim2.new(1, -40, 0, 7)
                ToggleButton.Size = UDim2.new(0, 30, 0, 20)
                ToggleButton.Font = Enum.Font.GothamBold
                ToggleButton.Text = toggleConfig.Default and "ON" or "OFF"
                ToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
                ToggleButton.TextSize = 10
                ToggleButton.AutoButtonColor = false
                
                local state = toggleConfig.Default or false
                
                ToggleButton.MouseButton1Click:Connect(function()
                    state = not state
                    ToggleButton.BackgroundColor3 = state and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)
                    ToggleButton.Text = state and "ON" or "OFF"
                    
                    if toggleConfig.Callback then
                        toggleConfig.Callback(state)
                    end
                end)
                
                return ToggleFrame
            end
            
            function Tab:AddLabel(labelConfig)
                local Label = Instance.new("TextLabel")
                Label.Name = labelConfig.Name
                Label.Parent = TabContent
                Label.BackgroundTransparency = 1
                Label.Size = UDim2.new(0, 350, 0, 25)
                Label.Font = Enum.Font.Gotham
                Label.Text = labelConfig.Name
                Label.TextColor3 = Color3.fromRGB(255, 255, 255)
                Label.TextSize = 12
                
                return Label
            end
            
            return Tab
        end
        
        return Window
    end

    -- 创建主窗口
    local Window = OrionLib:MakeWindow({
        Name = "Pressure透视辅助 v3.0"
    })

    -- 添加功能标签页
    local MainTab = Window:MakeTab({Name = "主要功能"})
    local VisualTab = Window:MakeTab({Name = "视觉设置"})
    local PlayerTab = Window:MakeTab({Name = "玩家设置"})

    -- 主要功能 - 修复第一列
    MainTab:AddLabel({Name = "=== 主要控制 ==="})
    
    local espActive = false
    MainTab:AddToggle({
        Name = "物品透视 ESP (带文字)",
        Default = false,
        Callback = function(state)
            espEnabled = state
            espActive = state
            if state then
                createItemESP()
            else
                clearItemESP()
            end
        end
    })
    
    MainTab:AddToggle({
        Name = "怪物警报系统",
        Default = true,
        Callback = function(state)
            monsterAlertEnabled = state
        end
    })
    
    MainTab:AddToggle({
        Name = "快速跑步 (速度35)",
        Default = false,
        Callback = function(state)
            fastRunEnabled = state
            if state then
                setPlayerSpeed(35)
            else
                setPlayerSpeed(originalWalkSpeed)
            end
        end
    })

    -- 视觉设置 - 修复第二列
    VisualTab:AddLabel({Name = "=== 视觉增强 ==="})
    
    VisualTab:AddToggle({
        Name = "高亮物品 (发光效果)",
        Default = false,
        Callback = function(state)
            highlightEnabled = state
            if not state then
                clearHighlights()
            else
                scanAndHighlightObjects()
            end
        end
    })
    
    VisualTab:AddToggle({
        Name = "夜视模式",
        Default = false,
        Callback = function(state)
            nightVisionEnabled = state
            if state then
                enableNightVision()
            else
                disableNightVision()
            end
        end
    })
    
    VisualTab:AddButton({
        Name = "刷新物品扫描",
        Callback = function()
            if espActive or highlightEnabled then
                clearItemESP()
                clearHighlights()
                wait(0.1)
                if espActive then createItemESP() end
                if highlightEnabled then scanAndHighlightObjects() end
            end
        end
    })

    -- 玩家设置
    PlayerTab:AddLabel({Name = "=== 移动设置 ==="})
    
    PlayerTab:AddButton({
        Name = "重置移动速度",
        Callback = function()
            fastRunEnabled = false
            setPlayerSpeed(originalWalkSpeed)
        end
    })
    
    local speedLabel = PlayerTab:AddLabel({Name = "当前速度: " .. getPlayerSpeed()})
    
    -- 更新速度显示
    spawn(function()
        while true do
            speedLabel.Text = "当前速度: " .. getPlayerSpeed()
            wait(1)
        end
    end)

    -- 修复的物品高亮功能 - 添加文字标签
    local function createESP(object, objectType, config)
        if highlightedObjects[object] then return end
        
        -- 创建高亮效果
        local highlight = Instance.new("Highlight")
        highlight.FillColor = config.color
        highlight.OutlineColor = config.color
        highlight.FillTransparency = 0.3
        highlight.OutlineTransparency = 0
        highlight.Parent = object
        
        -- 创建文字标签
        local billboardGui = Instance.new("BillboardGui")
        billboardGui.Name = "ESPLabel"
        billboardGui.Adornee = object
        billboardGui.Size = UDim2.new(0, 200, 0, 50)
        billboardGui.StudsOffset = Vector3.new(0, 3, 0)
        billboardGui.AlwaysOnTop = true
        billboardGui.MaxDistance = 100
        billboardGui.Parent = object
        
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, 0, 1, 0)
        label.BackgroundTransparency = 1
        label.Text = config.label
        label.TextColor3 = config.color
        label.TextSize = 14
        label.Font = Enum.Font.GothamBold
        label.TextStrokeTransparency = 0
        label.TextStrokeColor3 = Color3.new(0, 0, 0)
        label.Parent = billboardGui
        
        highlightedObjects[object] = {
            highlight = highlight,
            billboard = billboardGui
        }
    end

    local function clearHighlights()
        for object, espData in pairs(highlightedObjects) do
            if espData.highlight then
                espData.highlight:Destroy()
            end
            if espData.billboard then
                espData.billboard:Destroy()
            end
        end
        highlightedObjects = {}
    end

    local function clearItemESP()
        clearHighlights()
    end

    local function createItemESP()
        clearItemESP()
        scanAndHighlightObjects()
    end

    local function enableNightVision()
        local lighting = game:GetService("Lighting")
        lighting.Ambient = Color3.new(1, 1, 1)
        lighting.Brightness = 2
        lighting.ClockTime = 12
    end

    local function disableNightVision()
        local lighting = game:GetService("Lighting")
        lighting.Ambient = Color3.new(0.5, 0.5, 0.5)
        lighting.Brightness = 1
    end

    -- 修复的物品扫描函数
    local function scanAndHighlightObjects()
        for _, obj in pairs(Workspace:GetDescendants()) do
            if obj:IsA("Part") or obj:IsA("MeshPart") or obj:IsA("UnionOperation") or obj:IsA("Model") then
                local objName = obj.Name:lower()
                
                for typeName, config in pairs(objectTypes) do
                    if config.enabled then
                        for _, keyword in pairs(config.keywords) do
                            if string.find(objName, keyword:lower()) then
                                if espEnabled then
                                    createESP(obj, typeName, config)
                                elseif highlightEnabled then
                                    createHighlight(obj, config.color)
                                end
                                break
                            end
                        end
                    end
                end
            end
        end
    end

    -- 简单高亮函数（不带文字）
    local function createHighlight(object, color)
        if highlightedObjects[object] then return end
        
        local highlight = Instance.new("Highlight")
        highlight.FillColor = color
        highlight.OutlineColor = color
        highlight.FillTransparency = 0.3
        highlight.OutlineTransparency = 0
        highlight.Parent = object
        
        highlightedObjects[object] = {
            highlight = highlight,
            billboard = nil
        }
    end

    -- 自动扫描物品
    spawn(function()
        while true do
            if espEnabled or highlightEnabled then
                scanAndHighlightObjects()
            end
            wait(3)  -- 每3秒扫描一次
        end
    end)

    -- 初始化玩家速度
    spawn(function()
        wait(2)
        getPlayerSpeed()
    end)

    -- 怪物检测功能
    spawn(function()
        while true do
            if monsterAlertEnabled then
                checkForMonsters()
            end
            wait(0.5)
        end
    end)

    local function checkForMonsters()
        local currentTime = tick()
        if currentTime - lastMonsterAlert < alertCooldown then return end
        
        for _, obj in pairs(Workspace:GetDescendants()) do
            if obj:IsA("Model") then
                local modelName = obj.Name:lower()
                
                local monsterKeywords = {
                    "angler", "squiddle", "void", "eye", "turret", 
                    "pandemonium", "wall", "good", "multi", "death",
                    "final", "stan", "lopee", "parasite", "candle",
                    "redeemer", "bottomfeeder", "sebastian", "monster"
                }
                
                for _, keyword in pairs(monsterKeywords) do
                    if string.find(modelName, keyword) then
                        lastMonsterAlert = currentTime
                        showMonsterAlert("⚠️ 检测到怪物: " .. obj.Name)
                        break
                    end
                end
            end
        end
    end

    local function showMonsterAlert(message)
        local AlertGui = Instance.new("ScreenGui")
        local AlertFrame = Instance.new("Frame")
        local AlertLabel = Instance.new("TextLabel")
        
        AlertGui.Parent = game.CoreGui
        AlertGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        
        AlertFrame.Parent = AlertGui
        AlertFrame.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
        AlertFrame.BorderSizePixel = 0
        AlertFrame.Position = UDim2.new(0.3, 0, 0.1, 0)
        AlertFrame.Size = UDim2.new(0, 400, 0, 60)
        
        AlertLabel.Parent = AlertFrame
        AlertLabel.BackgroundTransparency = 1
        AlertLabel.Size = UDim2.new(1, 0, 1, 0)
        AlertLabel.Font = Enum.Font.GothamBold
        AlertLabel.Text = message
        AlertLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        AlertLabel.TextSize = 16
        AlertLabel.TextWrapped = true
        
        wait(3)
        AlertGui:Destroy()
    end

    -- 玩家重生时重置速度
    localPlayer.CharacterAdded:Connect(function(character)
        wait(1)
        getPlayerSpeed()
        if fastRunEnabled then
            setPlayerSpeed(35)
        end
    end)

    -- 初始扫描
    wait(2)
    if highlightEnabled then
        scanAndHighlightObjects()
    end
end
