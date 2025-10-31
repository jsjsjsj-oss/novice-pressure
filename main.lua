-- Pressure透视辅助脚本 - 修复透视和快速跑步版
-- 卡密: 粉丝NB

local correctPassword = "粉丝NB"
local authenticated = false

-- 先定义 InitializeScript 函数
local function InitializeScript()
    local Workspace = game:GetService("Workspace")
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local UserInputService = game:GetService("UserInputService")
    local localPlayer = Players.LocalPlayer

    -- 初始化功能变量
    local espEnabled = false
    local nightVisionEnabled = false
    local highlightEnabled = true
    local monsterAlertEnabled = true
    local fastRunEnabled = false
    local lastMonsterAlert = 0
    local alertCooldown = 2.5
    local highlightedObjects = {}
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

    -- 简化的物品配置 - 只保留有用的物品
    local objectTypes = {
        DOOR = {
            keywords = {"door", "门", "entrance", "exit", "gate"},
            color = Color3.fromRGB(0, 255, 255),
            label = "🚪 门",
            enabled = true
        },
        LOCKER = {
            keywords = {"locker", "储物柜", "cabinet", "hide", "躲藏", "closet", "storage"},
            color = Color3.fromRGB(148, 0, 211),
            label = "🗄️ 储物柜", 
            enabled = true
        },
        DRAWER = {
            keywords = {"drawer", "抽屉", "desk", "桌子"},
            color = Color3.fromRGB(255, 105, 180),
            label = "📦 抽屉",
            enabled = true
        },
        BATTERY = {
            keywords = {"battery", "电池", "power", "energy"},
            color = Color3.fromRGB(255, 165, 0),
            label = "🔋 电池",
            enabled = true
        },
        KEY = {
            keywords = {"key", "钥匙", "card", "卡"},
            color = Color3.fromRGB(255, 215, 0),
            label = "🔑 钥匙",
            enabled = true
        },
        EXIT = {
            keywords = {"exit", "出口", "escape", "leave"},
            color = Color3.fromRGB(0, 255, 0),
            label = "🚪 出口",
            enabled = true
        },
        GENERATOR = {
            keywords = {"generator", "发电机", "power", "gen"},
            color = Color3.fromRGB(255, 69, 0),
            label = "🔌 发电机",
            enabled = true
        },
        FAKE_LOCKER = {
            keywords = {"fake", "trap", "假", "陷阱"},
            color = Color3.fromRGB(255, 0, 0),
            label = "❌ 假柜子",
            enabled = true
        }
    }

    -- 简单UI库
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
                Button.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
                Button.BorderSizePixel = 0
                Button.Size = UDim2.new(0, 350, 0, 35)
                Button.Font = Enum.Font.Gotham
                Button.Text = buttonConfig.Name
                Button.TextColor3 = Color3.fromRGB(255, 255, 255)
                Button.TextSize = 12
                
                Button.MouseButton1Click:Connect(function()
                    if buttonConfig.Callback then
                        pcall(buttonConfig.Callback)
                    end
                end)
                
                spawn(function()
                    wait()
                    if TabContent and ContentLayout then
                        TabContent.CanvasSize = UDim2.new(0, 0, 0, ContentLayout.AbsoluteContentSize.Y + 10)
                    end
                end)
            end
            
            return Tab
        end
        
        -- 拖动功能
        local dragging, dragInput, dragStart, startPos
        
        local function update(input)
            local delta = input.Position - dragStart
            MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
        
        TopBar.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                dragStart = input.Position
                startPos = MainFrame.Position
            end
        end)
        
        TopBar.InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
                dragInput = input
            end
        end)
        
        UserInputService.InputChanged:Connect(function(input)
            if input == dragInput and dragging then
                update(input)
            end
        end)
        
        return Window
    end

    -- 创建窗口
    local Window = OrionLib:MakeWindow({
        Name = "Pressure透视辅助 - 粉丝NB", 
        HidePremium = false,
        SaveConfig = false,
        IntroText = "卡密验证成功 - 加载完成"
    })

    -- 通知函数
    local function Notify(msg)
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "Pressure透视辅助",
            Text = msg,
            Duration = 3
        })
    end

    -- 修复的透视功能
    local function CreateESP(object, objType)
        if highlightedObjects[object] then return end
        
        -- 直接使用对象本身，不找PrimaryPart
        if not object:IsA("BasePart") then return end
        
        if highlightEnabled then
            -- 创建高亮
            local highlight = Instance.new("Highlight")
            highlight.Name = "PressureESP"
            highlight.FillColor = objType.color
            highlight.FillTransparency = 0.3
            highlight.OutlineColor = objType.color
            highlight.OutlineTransparency = 0
            highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            highlight.Parent = object
            
            -- 创建文字标签
            local billboard = Instance.new("BillboardGui")
            billboard.Name = "ESPLabel"
            billboard.Size = UDim2.new(0, 200, 0, 50)
            billboard.AlwaysOnTop = true
            billboard.Adornee = object
            billboard.MaxDistance = 500
            billboard.StudsOffset = Vector3.new(0, 3, 0)
            
            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(1, 0, 1, 0)
            label.BackgroundTransparency = 1
            label.Text = objType.label
            label.TextColor3 = objType.color
            label.TextSize = 14
            label.TextStrokeTransparency = 0
            label.TextStrokeColor3 = Color3.new(0, 0, 0)
            label.Font = Enum.Font.GothamBold
            label.Parent = billboard
            
            billboard.Parent = object
            
            highlightedObjects[object] = {
                Highlight = highlight,
                Billboard = billboard,
                Type = objType.label
            }
        else
            highlightedObjects[object] = {
                Type = objType.label
            }
        end
    end

    local function ClearESP()
        for obj, data in pairs(highlightedObjects) do
            if data.Highlight then
                data.Highlight:Destroy()
            end
            if data.Billboard then
                data.Billboard:Destroy()
            end
        end
        highlightedObjects = {}
    end

    -- 修复的扫描函数 - 简化版本
    local function ScanObjects()
        if not espEnabled then return end
        
        local foundCount = 0
        
        for _, obj in pairs(Workspace:GetDescendants()) do
            if obj:IsA("BasePart") then
                local name = obj.Name:lower()
                
                for typeName, config in pairs(objectTypes) do
                    if config.enabled then
                        for _, keyword in ipairs(config.keywords) do
                            if name:find(keyword:lower()) then
                                CreateESP(obj, config)
                                foundCount = foundCount + 1
                                break
                            end
                        end
                    end
                end
            end
        end
        
        print("扫描完成，找到 " .. foundCount .. " 个物体")
    end

    -- 夜视功能
    local function ToggleNightVision()
        if nightVisionEnabled then
            -- 关闭夜视
            if game.Lighting then
                game.Lighting.Ambient = Color3.new(0, 0, 0)
                game.Lighting.Brightness = 1
            end
        else
            -- 开启夜视
            if game.Lighting then
                game.Lighting.Ambient = Color3.new(0.5, 0.5, 0.5)
                game.Lighting.Brightness = 2
            end
        end
        nightVisionEnabled = not nightVisionEnabled
    end

    -- 快速跑步功能
    local function ToggleFastRun()
        if fastRunEnabled then
            -- 关闭快速跑步
            setPlayerSpeed(originalWalkSpeed)
        else
            -- 开启快速跑步 (1倍速度 = 50)
            getPlayerSpeed() -- 先获取原速度
            setPlayerSpeed(50)
        end
        fastRunEnabled = not fastRunEnabled
    end

    -- 创建标签页
    local ESPTab = Window:MakeTab({Name = "透视功能"})
    local VisualTab = Window:MakeTab({Name = "视觉功能"})
    local OtherTab = Window:MakeTab({Name = "其他功能"})

    -- ESP分类开关
    for typeName, config in pairs(objectTypes) do
        ESPTab:AddButton({
            Name = (config.enabled and "✅ " or "❌ ") .. config.label,
            Callback = function()
                config.enabled = not config.enabled
                Notify(config.label .. " " .. (config.enabled and "开启" or "关闭"))
                ClearESP()
                if espEnabled then
                    ScanObjects()
                end
            end
        })
    end

    -- 基础透视按钮
    ESPTab:AddButton({
        Name = "开启全部透视",
        Callback = function()
            espEnabled = true
            for typeName, config in pairs(objectTypes) do
                config.enabled = true
            end
            ScanObjects()
            Notify("全部透视已开启")
        end
    })

    ESPTab:AddButton({
        Name = "关闭全部透视",
        Callback = function()
            espEnabled = false
            ClearESP()
            Notify("全部透视已关闭")
        end
    })

    ESPTab:AddButton({
        Name = "重新扫描",
        Callback = function()
            ClearESP()
            ScanObjects()
            Notify("重新扫描完成")
        end
    })

    -- 视觉功能
    VisualTab:AddButton({
        Name = (highlightEnabled and "✅ " or "❌ ") .. "ESP高亮",
        Callback = function()
            highlightEnabled = not highlightEnabled
            Notify("ESP高亮 " .. (highlightEnabled and "开启" or "关闭"))
            ClearESP()
            if espEnabled then
                ScanObjects()
            end
        end
    })

    VisualTab:AddButton({
        Name = (nightVisionEnabled and "✅ " or "❌ ") .. "夜视模式",
        Callback = function()
            ToggleNightVision()
            Notify("夜视模式 " .. (nightVisionEnabled and "开启" or "关闭"))
        end
    })

    -- 其他功能
    OtherTab:AddButton({
        Name = (fastRunEnabled and "✅ " or "❌ ") .. "快速跑步 (1倍)",
        Callback = function()
            ToggleFastRun()
            Notify("快速跑步 " .. (fastRunEnabled and "开启" or "关闭"))
        end
    })

    OtherTab:AddButton({
        Name = "显示物体信息",
        Callback = function()
            local objectCount = 0
            for _, obj in pairs(Workspace:GetDescendants()) do
                if obj:IsA("BasePart") then
                    local name = obj.Name:lower()
                    for typeName, config in pairs(objectTypes) do
                        for _, keyword in ipairs(config.keywords) do
                            if name:find(keyword:lower()) then
                                objectCount = objectCount + 1
                                break
                            end
                        end
                    end
                end
            end
            Notify("找到 " .. objectCount .. " 个可透视物体")
        end
    })

    -- 定期扫描
    spawn(function()
        while true do
            if espEnabled then
                ScanObjects()
            end
            wait(3)  -- 每3秒扫描一次
        end
    end)

    -- 玩家重生时重置速度
    localPlayer.CharacterAdded:Connect(function(character)
        wait(1)
        if fastRunEnabled then
            setPlayerSpeed(50)
        else
            setPlayerSpeed(originalWalkSpeed)
        end
    end)

    Notify("Pressure透视辅助加载完成！\n快速跑步1倍已添加")
end

-- 卡密验证界面（保持不变）
local PasswordGui = Instance.new("ScreenGui")
local PasswordFrame = Instance.new("Frame")
local PasswordBox = Instance.new("TextBox")
local SubmitButton = Instance.new("TextButton")
local Title = Instance.new("TextLabel")

PasswordGui.Name = "PasswordGUI"
PasswordGui.Parent = game.CoreGui
PasswordGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

PasswordFrame.Name = "PasswordFrame"
PasswordFrame.Parent = PasswordGui
PasswordFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
PasswordFrame.BorderSizePixel = 0
PasswordFrame.Position = UDim2.new(0.35, 0, 0.4, 0)
PasswordFrame.Size = UDim2.new(0, 350, 0, 250)

Title.Name = "Title"
Title.Parent = PasswordFrame
Title.BackgroundTransparency = 1
Title.Position = UDim2.new(0, 0, 0.05, 0)
Title.Size = UDim2.new(1, 0, 0, 60)
Title.Font = Enum.Font.GothamBold
Title.Text = "Pressure透视辅助\n请输入卡密"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 18
Title.TextStrokeTransparency = 0.5
Title.TextWrapped = true
Title.TextYAlignment = Enum.TextYAlignment.Center

PasswordBox.Name = "PasswordBox"
PasswordBox.Parent = PasswordFrame
PasswordBox.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
PasswordBox.BorderSizePixel = 0
PasswordBox.Position = UDim2.new(0.1, 0, 0.35, 0)
PasswordBox.Size = UDim2.new(0.8, 0, 0, 40)
PasswordBox.Font = Enum.Font.Gotham
PasswordBox.PlaceholderText = "请输入卡密..."
PasswordBox.Text = ""
PasswordBox.TextColor3 = Color3.fromRGB(255, 255, 255)
PasswordBox.TextSize = 16
PasswordBox.TextWrapped = true
PasswordBox.ClearTextOnFocus = false

SubmitButton.Name = "SubmitButton"
SubmitButton.Parent = PasswordFrame
SubmitButton.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
SubmitButton.BorderSizePixel = 0
SubmitButton.Position = UDim2.new(0.25, 0, 0.65, 0)
SubmitButton.Size = UDim2.new(0.5, 0, 0, 40)
SubmitButton.Font = Enum.Font.GothamBold
SubmitButton.Text = "验证卡密"
SubmitButton.TextColor3 = Color3.fromRGB(255, 255, 255)
SubmitButton.TextSize = 16

local function CheckPassword()
    local inputPassword = PasswordBox.Text
    if string.lower(inputPassword) == string.lower(correctPassword) then
        authenticated = true
        PasswordGui:Destroy()
        InitializeScript()
    else
        game.Players.LocalPlayer:Kick("输入错误，卡密不匹配")
    end
end

SubmitButton.MouseButton1Click:Connect(CheckPassword)
PasswordBox.FocusLost:Connect(function(enterPressed)
    if enterPressed then
        CheckPassword()
    end
end)
