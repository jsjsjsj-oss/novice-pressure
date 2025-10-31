-- Pressure物品透视脚本 - 只透视物品版
-- 卡密: 粉丝NB

local correctPassword = "粉丝NB"
local authenticated = false

-- 先定义 InitializeScript 函数
local function InitializeScript()
    -- 这里放置之前的所有主脚本内容
    -- 先初始化所有变量
    local Workspace = game:GetService("Workspace")
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local UserInputService = game:GetService("UserInputService")
    local localPlayer = Players.LocalPlayer

    -- 初始化功能变量
    local espEnabled = false
    local nightVisionEnabled = false
    local highlightEnabled = true
    local lastAlert = 0
    local alertCooldown = 2.5
    local highlightedObjects = {}

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

    -- 只保留物品透视配置，移除所有怪物
    local objectTypes = {
        DOOR = {
            keywords = {"door", "门", "entrance", "exit", "gate"},
            color = Color3.fromRGB(0, 255, 255),
            label = "🚪 可开门",
            enabled = true
        },
        LOCKER = {
            keywords = {"locker", "储物柜", "cabinet", "hide", "躲藏", "closet", "storage", "cab", "lockers"},
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
            keywords = {"key", "钥匙", "card", "卡", "access"},
            color = Color3.fromRGB(255, 215, 0),
            label = "🔑 钥匙",
            enabled = true
        },
        ITEM = {
            keywords = {"item", "物品", "object", "道具", "pickup"},
            color = Color3.fromRGB(50, 205, 50),
            label = "📦 物品",
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
        VALVE = {
            keywords = {"valve", "阀门", "wheel", "轮"},
            color = Color3.fromRGB(30, 144, 255),
            label = "🎛️ 阀门",
            enabled = true
        },
        LEVER = {
            keywords = {"lever", "杠杆", "switch", "开关"},
            color = Color3.fromRGB(138, 43, 226),
            label = "⚡ 开关",
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
        Title.Text = config.Name or "Pressure物品透视"
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
        
        local TabContainer = Instance.new("Frame")
        TabContainer.Name = "TabContainer"
        TabContainer.Parent = MainFrame
        TabContainer.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        TabContainer.BorderSizePixel = 0
        TabContainer.Position = UDim2.new(0, 120, 0, 30)
        TabContainer.Size = UDim2.new(0, 380, 0, 320)
        
        function Window:MakeTab(config)
            local Tab = {}
            local Sections = {}
            
            local TabButton = Instance.new("TextButton")
            TabButton.Name = "TabButton_" .. config.Name
            TabButton.Parent = TabButtons
            TabButton.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
            TabButton.BorderSizePixel = 0
            TabButton.Size = UDim2.new(0, 110, 0, 30)
            TabButton.Font = Enum.Font.Gotham
            TabButton.Text = config.Name
            TabButton.TextColor3 = Color3.fromRGB(255, 255, 255)
            TabButton.TextSize = 12
            
            local TabFrame = Instance.new("ScrollingFrame")
            TabFrame.Name = "TabFrame_" .. config.Name
            TabFrame.Parent = TabContainer
            TabFrame.Active = true
            TabFrame.BackgroundTransparency = 1
            TabFrame.BorderSizePixel = 0
            TabFrame.Size = UDim2.new(1, 0, 1, 0)
            TabFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
            TabFrame.ScrollBarThickness = 3
            TabFrame.Visible = false
            
            local TabLayout = Instance.new("UIListLayout")
            TabLayout.Parent = TabFrame
            TabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
            TabLayout.SortOrder = Enum.SortOrder.LayoutOrder
            TabLayout.Padding = UDim.new(0, 10)
            
            TabLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                TabFrame.CanvasSize = UDim2.new(0, 0, 0, TabLayout.AbsoluteContentSize.Y)
            end)
            
            TabButton.MouseButton1Click:Connect(function()
                for _, child in ipairs(TabContainer:GetChildren()) do
                    if child:IsA("ScrollingFrame") then
                        child.Visible = false
                    end
                end
                TabFrame.Visible = true
            end)
            
            if #TabContainer:GetChildren() == 1 then
                TabFrame.Visible = true
            end
            
            function Tab:AddToggle(config)
                local Toggle = {}
                local value = config.Default or false
                
                local ToggleFrame = Instance.new("Frame")
                ToggleFrame.Name = "ToggleFrame"
                ToggleFrame.Parent = TabFrame
                ToggleFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
                ToggleFrame.BorderSizePixel = 0
                ToggleFrame.Size = UDim2.new(0, 350, 0, 40)
                
                local ToggleLabel = Instance.new("TextLabel")
                ToggleLabel.Name = "ToggleLabel"
                T
