-- Pressure透视辅助脚本 - 完整修复版
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
    local monsterAlertEnabled = true
    local lastMonsterAlert = 0
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

    -- 压力游戏完整怪物透视配置
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
        -- 主要怪物分类
        ANGLER = {
            keywords = {
                "angler", "垂钓者", "钓鱼者", "pinkie", "小指", "froger", "青蛙", 
                "chainsmoker", "链吸烟者", "blitz", "闪电战", "rush", "ambush"
            },
            color = Color3.fromRGB(255, 0, 0),
            label = "🎣 垂钓者",
            enabled = true,
            alertText = "灯光闪烁+尖叫 → 立即躲藏"
        },
        SQUIDDLE = {
            keywords = {"squiddle", "鱿鱼", "squid", "tentacle"},
            color = Color3.fromRGB(75, 0, 130),
            label = "🦑 鱿鱼", 
            enabled = true,
            alertText = "关手电筒，保持距离"
        },
        VOID_MASS = {
            keywords = {"void", "mass", "puddle", "空隙质量", "黑水", "voidmass"},
            color = Color3.fromRGB(25, 25, 25),
            label = "🌌 空隙质量",
            enabled = true,
            alertText = "储物柜中紫黑生物 → 勿开"
        },
        EYE = {
            keywords = {"eye", "infestation", "眼神", "鲨鱼", "stare"},
            color = Color3.fromRGB(255, 215, 0),
            label = "👁️ 眼神",
            enabled = true,
            alertText = "勿直视，看地面移动"
        },
        TURRET = {
            keywords = {"turret", "炮塔", "gun", "laser", "ceiling"},
            color = Color3.fromRGB(100, 100, 100),
            label = "🔫 炮塔",
            enabled = true,
            alertText = "趁激光空档移动"
        },
        PANDEMONIUM = {
            keywords = {"pandemonium", "潘德蒙", "panic", "minigame"},
            color = Color3.fromRGB(220, 20, 60),
            label = "😱 潘德蒙",
            enabled = true,
            alertText = "保持相机在中心"
        },
        WALL_DWELLER = {
            keywords = {"wall", "dweller", "墙壁居民", "crack", "裂缝"},
            color = Color3.fromRGB(139, 69, 19),
            label = "🧱 墙壁居民", 
            enabled = true,
            alertText = "注视它可推开"
        },
        GOOD_PEOPLE = {
            keywords = {"good", "people", "好人", "假门", "fakedoor"},
            color = Color3.fromRGB(0, 255, 0),
            label = "👥 好二人",
            enabled = true,
            alertText = "假门发光 → 找其他路"
        },
        MULTI_GUNNER = {
            keywords = {"multi", "gunner", "多枪手", "multigun"},
            color = Color3.fromRGB(255, 69, 0),
            label = "🔫 多枪手",
            enabled = true,
            alertText = "红屏警告 → 立即躲藏"
        },
        DEATH_ANGEL = {
            keywords = {"death", "angel", "divine", "死亡天使", "buzz"},
            color = Color3.fromRGB(255, 255, 255),
            label = "👼 死亡天使",
            enabled = true,
            alertText = "嗡嗡声 → 立即躲藏"
        },
        FINAL_BOSS = {
            keywords = {"final", "boss", "大结局", "endboss"},
            color = Color3.fromRGB(128, 0, 128),
            label = "💀 大结局",
            enabled = true,
            alertText = "仅声音预警 → 利用躲藏点"
        },
        STAN = {
            keywords = {"stan", "斯坦", "roblox", "redeye"},
            color = Color3.fromRGB(255, 0, 0),
            label = "👀 斯坦",
            enabled = true,
            alertText = "红眼不动 → 远离"
        },
        MR_LOPEE = {
            keywords = {"lopee", "洛佩", "mr.lopee", "落单"},
            color = Color3.fromRGB(100, 100, 100),
            label = "👻 洛佩先生",
            enabled = true,
            alertText = "追击落单者 → 勿被抛下"
        },
        PARASITE = {
            keywords = {"parasite", "寄生虫", "hadal", "black"},
            color = Color3.fromRGB(0, 100, 0),
            label = "🐛 寄生虫",
            enabled = true,
            alertText = "紧贴光源"
        },
        CANDLE_BEARER = {
            keywords = {"candle", "bearer", "烛台", "烛光"},
            color = Color3.fromRGB(255, 140, 0),
            label = "🕯️ 烛台持有者",
            enabled = true,
            alertText = "攻击光源 → 25伤害"
        },
        REDEEMER = {
            keywords = {"redeemer", "救赎者", "hanger", "吊架", "gun"},
            color = Color3.fromRGB(200, 200, 0),
            label = "⚖️ 救赎者",
            enabled = true,
            alertText = "抽屉中枪形 → 拾取触发"
        },
        BOTTOMFEEDER = {
            keywords = {"bottomfeeder", "底层", "feeder", "疏浚"},
            color = Color3.fromRGB(70, 130, 180),
            label = "🐟 底层feeder",
            enabled = true,
            alertText = "每秒10伤害 → 远离光源"
        },
        APRIL_FOOLS = {
            keywords = {"sebastian", "赛巴斯帝安", "corpse", "尸体", "ai", "人工智能"},
            color = Color3.fromRGB(255, 105, 180),
            label = "🎭 愚人节怪物",
            enabled = true,
            alertText = "特殊模式 → 注意变体"
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

    -- 检查门是否可以开启
    local function IsDoorUsable(door)
        -- 检查是否有锁相关的组件
        if door:FindFirstChild("Lock") or door:FindFirstChild("Key") then
            return false
        end
        
        -- 检查名称中是否包含锁相关词汇
        local name = door.Name:lower()
        if name:find("lock") or name:find("locked") or name:find("broken") or name:find("destroyed") then
            return false
        end
        
        -- 检查是否有破坏状态
        if door:FindFirstChild("Broken") or door:FindFirstChild("Destroyed") then
            return false
        end
        
        -- 检查是否可以交互
        if door:FindFirstChild("ClickDetector") or door:FindFirstChild("ProximityPrompt") then
            return true
        end
        
        -- 默认认为是可开启的门
        return true
    end

    -- 检查储物柜附近是否有门
    local function HasDoorNearby(position)
        for _, obj in pairs(Workspace:GetDescendants()) do
            if obj:IsA("Model") or obj:IsA("BasePart") then
                local name = obj.Name:lower()
                if name:find("door") or name:find("门") then
                    local part = obj:IsA("Model") and obj.PrimaryPart or obj
                    if part then
                        local distance = (part.Position - position).Magnitude
                        if distance <= 3 then  -- 3米范围内有门
                            return true
                        end
                    end
                end
            end
        end
        return false
    end

    -- 增强怪物提醒功能
    local function MonsterAlert(monsterName, monsterType)
        if not monsterAlertEnabled then return end
        if tick() - lastMonsterAlert < alertCooldown then return end
        
        lastMonsterAlert = tick()
        
        local alertText = monsterName
        if monsterType and monsterType.alertText then
            alertText = alertText .. "\n" .. monsterType.alertText
        end
        
        -- 屏幕中央大警告
        local alertGui = Instance.new("ScreenGui")
        local alertFrame = Instance.new("Frame")
        local alertLabel = Instance.new("TextLabel")
        
        alertGui.Name = "MonsterAlert"
        alertGui.Parent = game.CoreGui
        alertGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        
        alertFrame.Name = "AlertFrame"
        alertFrame.Parent = alertGui
        alertFrame.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
        alertFrame.BackgroundTransparency = 0.3
        alertFrame.BorderSizePixel = 0
        alertFrame.Position = UDim2.new(0.3, 0, 0.4, 0)
        alertFrame.Size = UDim2.new(0, 450, 0, 100)
        
        alertLabel.Name = "AlertLabel"
        alertLabel.Parent = alertFrame
        alertLabel.BackgroundTransparency = 1
        alertLabel.Size = UDim2.new(1, 0, 1, 0)
        alertLabel.Font = Enum.Font.GothamBold
        alertLabel.Text = "⚠️ " .. alertText .. " ⚠️"
        alertLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        alertLabel.TextSize = 16
        alertLabel.TextStrokeTransparency = 0
        alertLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
        
        -- 2.5秒后自动消失
        spawn(function()
            wait(2.5)
            alertGui:Destroy()
        end)
        
        -- 声音提醒
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "🚨 怪物警报",
            Text = alertText,
            Duration = 2.5
        })
    end

    -- 透视功能
    local function CreateESP(object, objType)
        if highlightedObjects[object] then return end
        
        local part = object:IsA("Model") and object.PrimaryPart or object
        if not part then return end
        
        -- 只有高亮开启时才创建视觉效果
        if highlightEnabled then
            -- 创建高亮
            local highlight = Instance.new("Highlight")
            highlight.Name = "PressureESP"
            highlight.FillColor = objType.color
            highlight.FillTransparency = 0.5
            highlight.OutlineColor = objType.color
            highlight.OutlineTransparency = 0
            highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            highlight.Parent = part
            
            -- 创建文字标签
            local billboard = Instance.new("BillboardGui")
            billboard.Name = "ESPLabel"
            billboard.Size = UDim2.new(0, 200, 0, 50)
            billboard.AlwaysOnTop = true
            billboard.Adornee = part
            billboard.MaxDistance = 100
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
            
            billboard.Parent = part
            
            highlightedObjects[object] = {
                Highlight = highlight,
                Billboard = billboard,
                Type = objType.label
            }
        else
            -- 高亮关闭时，只记录对象但不创建视觉效果
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

    -- 修改扫描函数，使用精确的怪物分类
    local function ScanObjects()
        if not espEnabled then return end
        
        for _, obj in pairs(Workspace:GetDescendants()) do
            if obj:IsA("Model") or obj:IsA("BasePart") then
                local name = obj.Name:lower()
                local monsterFound = false
                
                -- 先检查具体怪物类型
                for typeName, config in pairs(objectTypes) do
                    if config.enabled then
                        for _, keyword in ipairs(config.keywords) do
                            if name:find(keyword:lower()) then
                                
                                if typeName == "DOOR" then
                                    if IsDoorUsable(obj) then
                                        CreateESP(obj, config)
                                    end
                                elseif typeName == "LOCKER" then
                                    local part = obj:IsA("Model") and obj.PrimaryPart or obj
                                    if part and HasDoorNearby(part.Position) then
                                        CreateESP(obj, objectTypes.DRAWER)
                                    else
                                        CreateESP(obj, config)
                                    end
                                else
                                    -- 怪物类对象
                                    monsterFound = true
                                    if not highlightedObjects[obj] then
                                        MonsterAlert(obj.Name, config)
                                    end
                                    CreateESP(obj, config)
                                end
                                break
                            end
                        end
                    end
                end
                
                -- 通用怪物检测（备用）
                if not monsterFound then
                    local genericMonsterWords = {"monster", "enemy", "entity", "creature", "boss"}
                    for _, word in ipairs(genericMonsterWords) do
                        if name:find(word) then
                            if not highlightedObjects[obj] then
                                MonsterAlert(obj.Name, objectTypes.ANGLER)
                            end
                            CreateESP(obj, objectTypes.ANGLER)
                            break
                        end
                    end
                end
            end
        end
    end

    -- 夜视功能
    local function ToggleNightVision()
        if nightVisionEnabled then
            -- 关闭夜视
            if game.Lighting then
                game.Lighting.Ambient = Color3.new(0, 0, 0)
                game.Lighting.Brightness = 1
                game.Lighting.ClockTime = 14
                game.Lighting.GlobalShadows = true
            end
        else
            -- 开启夜视
            if game.Lighting then
                game.Lighting.Ambient = Color3.new(0.3, 0.3, 0.3)
                game.Lighting.Brightness = 2
                game.Lighting.ClockTime = 12
                game.Lighting.GlobalShadows = false
            end
        end
        nightVisionEnabled = not nightVisionEnabled
    end

    -- 创建标签页
    local ESPTab = Window:MakeTab({Name = "透视功能"})
    local VisualTab = Window:MakeTab({Name = "视觉功能"})
    local AlertTab = Window:MakeTab({Name = "提醒设置"})
    local MonsterTab = Window:MakeTab({Name = "怪物管理"})

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

    -- 提醒设置
    AlertTab:AddButton({
        Name = (monsterAlertEnabled and "✅ " or "❌ ") .. "来怪提醒",
        Callback = function()
            monsterAlertEnabled = not monsterAlertEnabled
            Notify("来怪提醒 " .. (monsterAlertEnabled and "开启" or "关闭"))
        end
    })

    AlertTab:AddButton({
        Name = "测试来怪警报",
        Callback = function()
            MonsterAlert("测试怪物", objectTypes.ANGLER)
        end
    })

    -- 怪物管理
    MonsterTab:AddButton({
        Name = "显示所有怪物名称",
        Callback = function()
            local monsterCount = 0
            for _, obj in pairs(Workspace:GetDescendants()) do
                if obj:IsA("Model") or obj:IsA("BasePart") then
                    local name = obj.Name:lower()
                    for typeName, config in pairs(objectTypes) do
                        if typeName ~= "DOOR" and typeName ~= "LOCKER" and typeName ~= "DRAWER" and typeName ~= "BATTERY" then
                            for _, keyword in ipairs(config.keywords) do
                                if name:find(keyword:lower()) then
                                    print("发现怪物: " .. obj.Name .. " | 类型: " .. config.label)
                                    monsterCount = monsterCount + 1
                                    break
                                end
                            end
                        end
                    end
                end
            end
            Notify("找到 " .. monsterCount .. " 个怪物对象\n查看控制台输出")
        end
    })

    -- 定期扫描
    spawn(function()
        while true do
            if espEnabled then
                ScanObjects()
            end
            wait(5)
        end
    end)

    Notify("Pressure透视辅助加载完成！\n卡密: 粉丝NB")
end

-- 创建卡密输入界面
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
        -- 卡密错误直接踢出游戏
        game.Players.LocalPlayer:Kick("输入错误，卡密不匹配")
    end
end

SubmitButton.MouseButton1Click:Connect(CheckPassword)
PasswordBox.FocusLost:Connect(function(enterPressed)
    if enterPressed then
        CheckPassword()
    end
end)
