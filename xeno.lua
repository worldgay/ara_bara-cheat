-- ================================================================
--  xeno.lua (Rayfield-подобный GUI)
--  ara_bara hub | 99 Nights + Universal
--  Полностью переписан с собственным стилем Rayfield
-- ================================================================

-- ================================================================
--  СЕРВИСЫ
-- ================================================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- ================================================================
--  СОСТОЯНИЕ
-- ================================================================
local State = {
    ESP = false,
    Aimbot = false,
    Fly = false,
    FlySpeed = 80,
    Speed = false,
    SpeedValue = 16,
    Noclip = false,
    GodMode = false,
    InfiniteJump = false,
    KillAura = false,
    KillAuraRadius = 30,
    ChopAura = false,
    AutoFarm = false,
    ResourceType = "Wood",
    AutoCook = false,
    AutoUpgradeCampfire = false,
    AutoScrap = false,
    AutoPlant = false,
    AutoRescueKids = false,
    AutoEat = false,
    Fullbright = false,
    NoFog = false,
    AntiAFK = false,
}

-- ================================================================
--  УТИЛИТЫ (копия из предыдущей версии)
-- ================================================================
local function getChar()
    return LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
end

local function getHRP()
    local c = getChar()
    return c and c:FindFirstChild("HumanoidRootPart")
end

local function getHumanoid()
    local c = getChar()
    return c and c:FindFirstChildOfClass("Humanoid")
end

local function teleport(cf)
    local hrp = getHRP()
    if hrp then hrp.CFrame = cf end
end

local function isEnemy(model)
    if not model then return false end
    local name = model.Name:lower()
    return name:find("cultist") or name:find("deer") or name:find("wolf") or
           name:find("bear") or name:find("owl") or name:find("ram") or
           name:find("golem") or name:find("corrupt")
end

local function isTree(model)
    if not model then return false end
    local name = model.Name:lower()
    return name:find("tree") or name:find("log") or name:find("stump")
end

local function isItem(model)
    if not model then return false end
    local name = model.Name:lower()
    return name:find("log") or name:find("plank") or name:find("stick") or
           name:find("food") or name:find("berry") or name:find("meat") or
           name:find("fuel") or name:find("medicine") or name:find("diamond")
end

local function isKid(model)
    if not model then return false end
    local name = model.Name:lower()
    return name:find("kid") or name:find("child") or name:find("survivor")
end

local function findNearest(targets, radius)
    local hrp = getHRP()
    if not hrp then return nil end
    local closest, closestDist = nil, radius or 1000
    for _, obj in pairs(targets) do
        local root = obj:FindFirstChildWhichIsA("BasePart") or obj.PrimaryPart
        if root then
            local dist = (root.Position - hrp.Position).Magnitude
            if dist < closestDist then
                closestDist = dist
                closest = obj
            end
        end
    end
    return closest
end

-- ================================================================
--  ФУНКЦИИ (ESP, Aimbot, Fly, ...) — без изменений
-- ================================================================
local espFolder = Instance.new("Folder", game.CoreGui)
espFolder.Name = "ara_bara_ESP"

local function clearESP()
    for _, v in pairs(espFolder:GetChildren()) do v:Destroy() end
end

local function updateESP()
    clearESP()
    if not State.ESP then return end
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local hl = Instance.new("Highlight")
            hl.FillColor = Color3.fromRGB(255, 0, 0)
            hl.OutlineColor = Color3.new(1,1,1)
            hl.FillTransparency = 0.6
            hl.OutlineTransparency = 0.3
            hl.Adornee = player.Character
            hl.Parent = espFolder
        end
    end
end

task.spawn(function()
    while true do
        if State.ESP then updateESP() else clearESP() end
        task.wait(2)
    end
end)

local aimbotConnection
local function startAimbot()
    if aimbotConnection then return end
    aimbotConnection = RunService.Heartbeat:Connect(function()
        if not State.Aimbot then return end
        local char = LocalPlayer.Character
        if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        local closest, closestDist = nil, 90
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character then
                local target = player.Character:FindFirstChild("Head") or player.Character:FindFirstChild("HumanoidRootPart")
                if target then
                    local screenPos, onScreen = Camera:WorldToViewportPoint(target.Position)
                    if onScreen then
                        local mousePos = UserInputService:GetMouseLocation()
                        local dist = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
                        if dist < closestDist then
                            closestDist = dist
                            closest = target
                        end
                    end
                end
            end
        end
        if closest then
            Camera.CFrame = CFrame.new(Camera.CFrame.Position, closest.Position)
        end
    end)
end

local function stopAimbot()
    if aimbotConnection then aimbotConnection:Disconnect(); aimbotConnection = nil end
end

local flyBody, flyConnection
local function startFly()
    if State.Fly then return end
    local hrp = getHRP()
    if not hrp then return end
    flyBody = Instance.new("BodyVelocity")
    flyBody.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    flyBody.Velocity = Vector3.zero
    flyBody.Parent = hrp
    local hum = getHumanoid()
    if hum then hum.PlatformStand = true end
    State.Fly = true
    flyConnection = RunService.Heartbeat:Connect(function()
        if not State.Fly then return end
        local hrp = getHRP()
        if not hrp or not flyBody then return end
        local dir = Vector3.zero
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir = dir + Camera.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir = dir - Camera.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir = dir - Camera.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir = dir + Camera.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir = dir + Vector3.yAxis end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then dir = dir - Vector3.yAxis end
        if dir.Magnitude > 0 then dir = dir.Unit end
        flyBody.Velocity = dir * State.FlySpeed
    end)
end

local function stopFly()
    State.Fly = false
    if flyBody then flyBody:Destroy(); flyBody = nil end
    if flyConnection then flyConnection:Disconnect(); flyConnection = nil end
    local hum = getHumanoid()
    if hum then hum.PlatformStand = false end
end

local function updateSpeed()
    local hum = getHumanoid()
    if hum then
        hum.WalkSpeed = State.Speed and State.SpeedValue or 16
    end
end
RunService.Heartbeat:Connect(updateSpeed)

local function updateNoclip()
    local char = getChar()
    if not char then return end
    for _, part in pairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CanCollide = not State.Noclip
        end
    end
end
RunService.Heartbeat:Connect(function()
    if State.Noclip then updateNoclip() end
end)

local godModeConnection
local function startGodMode()
    if godModeConnection then return end
    godModeConnection = RunService.Heartbeat:Connect(function()
        if not State.GodMode then return end
        local char = getChar()
        if not char then return end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then hum.Health = hum.MaxHealth end
    end)
end
local function stopGodMode()
    if godModeConnection then godModeConnection:Disconnect(); godModeConnection = nil end
end

UserInputService.JumpRequest:Connect(function()
    if State.InfiniteJump then
        local hum = getHumanoid()
        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)

local killAuraConnection
local function startKillAura()
    if killAuraConnection then return end
    killAuraConnection = RunService.Heartbeat:Connect(function()
        if not State.KillAura then return end
        local hrp = getHRP()
        if not hrp then return end
        local enemies = {}
        for _, obj in pairs(Workspace:GetDescendants()) do
            if obj:IsA("Model") and obj:FindFirstChildOfClass("Humanoid") then
                local hum = obj:FindFirstChildOfClass("Humanoid")
                if hum and hum.Health > 0 and isEnemy(obj) then
                    table.insert(enemies, obj)
                end
            end
        end
        local target = findNearest(enemies, State.KillAuraRadius)
        if target then
            local root = target:FindFirstChildWhichIsA("BasePart")
            if root then
                teleport(root.CFrame + Vector3.new(0, 2, 0))
                local char = getChar()
                if char then
                    for _, tool in pairs(char:GetChildren()) do
                        if tool:IsA("Tool") then
                            pcall(tool.Activate, tool)
                        end
                    end
                end
            end
        end
    end)
end
local function stopKillAura()
    if killAuraConnection then killAuraConnection:Disconnect(); killAuraConnection = nil end
end

local chopAuraConnection
local function startChopAura()
    if chopAuraConnection then return end
    chopAuraConnection = RunService.Heartbeat:Connect(function()
        if not State.ChopAura then return end
        local hrp = getHRP()
        if not hrp then return end
        local trees = {}
        for _, obj in pairs(Workspace:GetDescendants()) do
            if obj:IsA("Model") and isTree(obj) then
                local root = obj:FindFirstChildWhichIsA("BasePart")
                if root then table.insert(trees, obj) end
            end
        end
        local target = findNearest(trees, 20)
        if target then
            local root = target:FindFirstChildWhichIsA("BasePart")
            if root then
                teleport(root.CFrame + Vector3.new(0, 2, 0))
                task.wait(0.1)
                local remote = ReplicatedStorage:FindFirstChild("RemoteEvents") and ReplicatedStorage.RemoteEvents:FindFirstChild("ToolDamageObject")
                if remote then
                    local axe = LocalPlayer:FindFirstChild("Inventory") and LocalPlayer.Inventory:FindFirstChild("Old Axe")
                    if axe then
                        pcall(function()
                            remote:InvokeServer(target, axe, "1_" .. LocalPlayer.UserId, root.CFrame)
                        end)
                    end
                end
                task.wait(0.3)
            end
        end
    end)
end
local function stopChopAura()
    if chopAuraConnection then chopAuraConnection:Disconnect(); chopAuraConnection = nil end
end

local farmConnection
local function startAutoFarm()
    if farmConnection then return end
    farmConnection = RunService.Heartbeat:Connect(function()
        if not State.AutoFarm then return end
        local hrp = getHRP()
        if not hrp then return end
        local resourceType = State.ResourceType:lower()
        local targets = {}
        for _, obj in pairs(Workspace:GetDescendants()) do
            if obj:IsA("Model") and obj.Name:lower():find(resourceType) then
                local root = obj:FindFirstChildWhichIsA("BasePart")
                if root then table.insert(targets, obj) end
            end
        end
        local target = findNearest(targets, 50)
        if target then
            local root = target:FindFirstChildWhichIsA("BasePart")
            if root then
                teleport(root.CFrame + Vector3.new(0, 1, 0))
                task.wait(0.2)
                local prompt = target:FindFirstChildOfClass("ProximityPrompt")
                if prompt then
                    pcall(fireproximityprompt, prompt)
                end
                task.wait(0.3)
            end
        end
    end)
end
local function stopAutoFarm()
    if farmConnection then farmConnection:Disconnect(); farmConnection = nil end
end

local cookConnection
local function startAutoCook()
    if cookConnection then return end
    cookConnection = RunService.Heartbeat:Connect(function()
        if not State.AutoCook then return end
        local campfire = Workspace:FindFirstChild("Campfire", true)
        if campfire then
            local prompt = campfire:FindFirstChildOfClass("ProximityPrompt")
            if prompt then
                pcall(fireproximityprompt, prompt)
                task.wait(2)
            end
        end
    end)
end
local function stopAutoCook()
    if cookConnection then cookConnection:Disconnect(); cookConnection = nil end
end

local upgradeConn
local function startAutoUpgradeCampfire()
    if upgradeConn then return end
    upgradeConn = RunService.Heartbeat:Connect(function()
        if not State.AutoUpgradeCampfire then return end
        local campfire = Workspace:FindFirstChild("Campfire", true)
        if campfire then
            local prompt = campfire:FindFirstChildOfClass("ProximityPrompt")
            if prompt then
                pcall(fireproximityprompt, prompt)
                task.wait(1)
            end
        end
    end)
end
local function stopAutoUpgradeCampfire()
    if upgradeConn then upgradeConn:Disconnect(); upgradeConn = nil end
end

local scrapConn
local function startAutoScrap()
    if scrapConn then return end
    scrapConn = RunService.Heartbeat:Connect(function()
        if not State.AutoScrap then return end
        local workbench = Workspace:FindFirstChild("Workbench", true) or Workspace:FindFirstChild("CraftingBench", true)
        if workbench then
            local prompt = workbench:FindFirstChildOfClass("ProximityPrompt")
            if prompt then
                pcall(fireproximityprompt, prompt)
                task.wait(1)
            end
        end
    end)
end
local function stopAutoScrap()
    if scrapConn then scrapConn:Disconnect(); scrapConn = nil end
end

local plantConn
local function startAutoPlant()
    if plantConn then return end
    plantConn = RunService.Heartbeat:Connect(function()
        if not State.AutoPlant then return end
        local backpack = LocalPlayer.Backpack
        local sapling = nil
        for _, tool in pairs(backpack:GetChildren()) do
            if tool:IsA("Tool") and tool.Name:lower():find("sapling") then
                sapling = tool
                break
            end
        end
        if sapling then
            local hum = getHumanoid()
            if hum then
                hum:EquipTool(sapling)
                task.wait(0.2)
                pcall(sapling.Activate, sapling)
                task.wait(0.5)
            end
        end
    end)
end
local function stopAutoPlant()
    if plantConn then plantConn:Disconnect(); plantConn = nil end
end

local rescueConn
local function startAutoRescueKids()
    if rescueConn then return end
    rescueConn = RunService.Heartbeat:Connect(function()
        if not State.AutoRescueKids then return end
        local hrp = getHRP()
        if not hrp then return end
        local kids = {}
        for _, obj in pairs(Workspace:GetDescendants()) do
            if obj:IsA("Model") and isKid(obj) then
                local root = obj:FindFirstChildWhichIsA("BasePart")
                if root then table.insert(kids, obj) end
            end
        end
        local kid = findNearest(kids, 50)
        if kid then
            local root = kid:FindFirstChildWhichIsA("BasePart")
            if root then
                teleport(root.CFrame + Vector3.new(0, 2, 0))
                task.wait(0.3)
                local prompt = kid:FindFirstChildOfClass("ProximityPrompt")
                if prompt then
                    pcall(fireproximityprompt, prompt)
                end
                task.wait(1)
            end
        end
    end)
end
local function stopAutoRescueKids()
    if rescueConn then rescueConn:Disconnect(); rescueConn = nil end
end

local eatConn
local function startAutoEat()
    if eatConn then return end
    eatConn = RunService.Heartbeat:Connect(function()
        if not State.AutoEat then return end
        local hum = getHumanoid()
        if hum and hum.Health < hum.MaxHealth * 0.7 then
            local foodKeywords = {"chowder","fish","meat","potato","fruit","food","pizza","coconut","banana","apple","steak","egg","berry"}
            for _, tool in pairs(LocalPlayer.Backpack:GetChildren()) do
                if tool:IsA("Tool") then
                    local tName = tool.Name:lower()
                    for _, kw in ipairs(foodKeywords) do
                        if tName:find(kw) then
                            hum:EquipTool(tool)
                            task.wait(0.1)
                            pcall(tool.Activate, tool)
                            task.wait(0.3)
                            break
                        end
                    end
                end
            end
        end
    end)
end
local function stopAutoEat()
    if eatConn then eatConn:Disconnect(); eatConn = nil end
end

local origLighting = {}
local function toggleFullbright()
    if State.Fullbright then
        origLighting.Ambient = Lighting.Ambient
        origLighting.Brightness = Lighting.Brightness
        origLighting.ClockTime = Lighting.ClockTime
        Lighting.Ambient = Color3.new(1,1,1)
        Lighting.Brightness = 2
        Lighting.ClockTime = 14
    else
        for k,v in pairs(origLighting) do Lighting[k] = v end
    end
end
RunService.Heartbeat:Connect(function()
    if State.Fullbright then toggleFullbright() end
end)

local function toggleNoFog()
    if State.NoFog then
        Lighting.FogEnd = 1e6
    else
        Lighting.FogEnd = origLighting.FogEnd or 1000
    end
end
RunService.Heartbeat:Connect(function()
    if State.NoFog then toggleNoFog() end
end)

local antiAFKConn
local function startAntiAFK()
    if antiAFKConn then return end
    local vu = game:GetService("VirtualUser")
    antiAFKConn = LocalPlayer.Idled:Connect(function()
        vu:Button2Down(Vector2.zero, Camera.CFrame)
        task.wait(1)
        vu:Button2Up(Vector2.zero, Camera.CFrame)
    end)
end
local function stopAntiAFK()
    if antiAFKConn then antiAFKConn:Disconnect(); antiAFKConn = nil end
end

local function teleportTo(name)
    local target = Workspace:FindFirstChild(name, true)
    if target then
        local root = target:FindFirstChildWhichIsA("BasePart") or target
        teleport(root.CFrame + Vector3.new(0, 3, 0))
    end
end

local function teleportToNearestKid()
    local hrp = getHRP()
    if not hrp then return end
    local kids = {}
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") and isKid(obj) then
            local root = obj:FindFirstChildWhichIsA("BasePart")
            if root then table.insert(kids, obj) end
        end
    end
    local kid = findNearest(kids, 100)
    if kid then
        local root = kid:FindFirstChildWhichIsA("BasePart")
        if root then teleport(root.CFrame + Vector3.new(0, 2, 0)) end
    end
end

-- ================================================================
--  GUI (Rayfield-подобный)
-- ================================================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ara_bara_hub"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

-- Основное окно
local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 450, 0, 500)
mainFrame.Position = UDim2.new(0.5, -225, 0.5, -250)
mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
mainFrame.BackgroundTransparency = 0.05
mainFrame.BorderSizePixel = 0
mainFrame.ClipsDescendants = true
mainFrame.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 12)
corner.Parent = mainFrame

-- Тень
local shadow = Instance.new("ImageLabel")
shadow.Size = UDim2.new(1, 20, 1, 20)
shadow.Position = UDim2.new(0, -10, 0, -10)
shadow.BackgroundTransparency = 1
shadow.Image = "rbxassetid://1316047257"
shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
shadow.ImageTransparency = 0.6
shadow.ZIndex = 0
shadow.Parent = mainFrame

-- Заголовок
local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 40)
titleBar.Position = UDim2.new(0, 0, 0, 0)
titleBar.BackgroundTransparency = 1
titleBar.Parent = mainFrame

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(0.8, 0, 1, 0)
titleLabel.Position = UDim2.new(0, 10, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "ara_bara hub"
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextSize = 18
titleLabel.Parent = titleBar

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 30, 0, 30)
closeBtn.Position = UDim2.new(1, -35, 0, 5)
closeBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
closeBtn.Text = "✕"
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.TextSize = 18
closeBtn.Font = Enum.Font.GothamBold
closeBtn.BorderSizePixel = 0
closeBtn.Parent = titleBar
local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 6)
closeCorner.Parent = closeBtn
closeBtn.MouseButton1Click:Connect(function()
    screenGui:Destroy()
end)

-- Tab Bar
local tabBar = Instance.new("Frame")
tabBar.Size = UDim2.new(1, 0, 0, 40)
tabBar.Position = UDim2.new(0, 0, 0, 40)
tabBar.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
tabBar.BackgroundTransparency = 0.3
tabBar.BorderSizePixel = 0
tabBar.Parent = mainFrame

local tabButtons = {}
local tabFrames = {}
local selectedTab = nil

local tabNames = {"Main", "Combat", "Farming", "Movement", "Visuals", "Teleports"}
local tabIcons = {"home", "sword", "pickaxe", "zap", "eye", "map-pin"} -- не используются, но для порядка

local function createTab(name, index)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1 / #tabNames, 0, 1, 0)
    btn.Position = UDim2.new((index - 1) / #tabNames, 0, 0, 0)
    btn.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
    btn.BackgroundTransparency = 0.5
    btn.Text = name
    btn.TextColor3 = Color3.fromRGB(200, 200, 200)
    btn.TextSize = 14
    btn.Font = Enum.Font.Gotham
    btn.BorderSizePixel = 0
    btn.Parent = tabBar
    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 0)
    btnCorner.Parent = btn

    local tabFrame = Instance.new("Frame")
    tabFrame.Size = UDim2.new(1, 0, 1, -80)
    tabFrame.Position = UDim2.new(0, 0, 0, 80)
    tabFrame.BackgroundTransparency = 1
    tabFrame.Visible = (index == 1)
    tabFrame.Parent = mainFrame

    -- Scroll для содержимого вкладки
    local scroll = Instance.new("ScrollingFrame")
    scroll.Size = UDim2.new(1, -20, 1, -10)
    scroll.Position = UDim2.new(0, 10, 0, 5)
    scroll.BackgroundTransparency = 1
    scroll.CanvasSize = UDim2.new(0, 0, 0, 10)
    scroll.ScrollBarThickness = 6
    scroll.ScrollBarImageColor3 = Color3.fromRGB(80, 80, 90)
    scroll.Parent = tabFrame

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 5)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = scroll

    tabButtons[name] = btn
    tabFrames[name] = {frame = tabFrame, scroll = scroll, layout = layout}

    btn.MouseButton1Click:Connect(function()
        for _, tb in pairs(tabButtons) do
            tb.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
            tb.BackgroundTransparency = 0.5
            tb.TextColor3 = Color3.fromRGB(200, 200, 200)
        end
        btn.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
        btn.BackgroundTransparency = 0
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        for _, tf in pairs(tabFrames) do
            tf.frame.Visible = false
        end
        tabFrames[name].frame.Visible = true
    end)

    return tabFrames[name]
end

-- Создаем вкладки
for i, name in ipairs(tabNames) do
    createTab(name, i)
end

-- Утилиты для добавления элементов в вкладку
local function addElement(tabName, element)
    local scroll = tabFrames[tabName].scroll
    element.Parent = scroll
    tabFrames[tabName].scroll.CanvasSize = UDim2.new(0, 0, 0, tabFrames[tabName].scroll.CanvasSize.Y.Offset + 40)
end

local function createSection(tabName, title)
    local section = Instance.new("TextLabel")
    section.Size = UDim2.new(1, 0, 0, 25)
    section.BackgroundTransparency = 1
    section.Text = title
    section.TextColor3 = Color3.fromRGB(150, 150, 160)
    section.TextSize = 14
    section.Font = Enum.Font.GothamBold
    section.TextXAlignment = Enum.TextXAlignment.Left
    section.Parent = tabFrames[tabName].scroll
    tabFrames[tabName].scroll.CanvasSize = UDim2.new(0, 0, 0, tabFrames[tabName].scroll.CanvasSize.Y.Offset + 30)
    return section
end

local function createToggle(tabName, labelText, stateKey, callback)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 35)
    frame.BackgroundTransparency = 1
    frame.Parent = tabFrames[tabName].scroll

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.7, 0, 1, 0)
    label.Position = UDim2.new(0, 5, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = labelText
    label.TextColor3 = Color3.fromRGB(220, 220, 220)
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Font = Enum.Font.Gotham
    label.TextSize = 15
    label.Parent = frame

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.2, 0, 0.8, 0)
    btn.Position = UDim2.new(0.78, 0, 0.1, 0)
    btn.BackgroundColor3 = Color3.fromRGB(80, 80, 90)
    btn.Text = "OFF"
    btn.TextColor3 = Color3.fromRGB(255,255,255)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 14
    btn.BorderSizePixel = 0
    btn.Parent = frame
    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 6)
    btnCorner.Parent = btn

    btn.MouseButton1Click:Connect(function()
        State[stateKey] = not State[stateKey]
        btn.BackgroundColor3 = State[stateKey] and Color3.fromRGB(60, 180, 100) or Color3.fromRGB(80, 80, 90)
        btn.Text = State[stateKey] and "ON" or "OFF"
        if callback then callback(State[stateKey]) end
    end)

    tabFrames[tabName].scroll.CanvasSize = UDim2.new(0, 0, 0, tabFrames[tabName].scroll.CanvasSize.Y.Offset + 40)
    return frame
end

local function createSlider(tabName, labelText, stateKey, min, max, default, callback)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 45)
    frame.BackgroundTransparency = 1
    frame.Parent = tabFrames[tabName].scroll

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.6, 0, 0.5, 0)
    label.Position = UDim2.new(0, 5, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = labelText .. ": " .. tostring(default)
    label.TextColor3 = Color3.fromRGB(220, 220, 220)
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Font = Enum.Font.Gotham
    label.TextSize = 14
    label.Parent = frame

    local valueDisplay = Instance.new("TextLabel")
    valueDisplay.Size = UDim2.new(0.2, 0, 0.5, 0)
    valueDisplay.Position = UDim2.new(0.78, 0, 0, 0)
    valueDisplay.BackgroundTransparency = 1
    valueDisplay.Text = tostring(default)
    valueDisplay.TextColor3 = Color3.fromRGB(255, 255, 255)
    valueDisplay.TextXAlignment = Enum.TextXAlignment.Right
    valueDisplay.Font = Enum.Font.GothamBold
    valueDisplay.TextSize = 14
    valueDisplay.Parent = frame

    local minus = Instance.new("TextButton")
    minus.Size = UDim2.new(0.08, 0, 0.3, 0)
    minus.Position = UDim2.new(0.7, 0, 0.6, 0)
    minus.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
    minus.Text = "-"
    minus.TextColor3 = Color3.fromRGB(255,255,255)
    minus.Font = Enum.Font.GothamBold
    minus.TextSize = 18
    minus.BorderSizePixel = 0
    minus.Parent = frame
    local minusCorner = Instance.new("UICorner")
    minusCorner.CornerRadius = UDim.new(0, 6)
    minusCorner.Parent = minus

    local plus = Instance.new("TextButton")
    plus.Size = UDim2.new(0.08, 0, 0.3, 0)
    plus.Position = UDim2.new(0.85, 0, 0.6, 0)
    plus.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
    plus.Text = "+"
    plus.TextColor3 = Color3.fromRGB(255,255,255)
    plus.Font = Enum.Font.GothamBold
    plus.TextSize = 18
    plus.BorderSizePixel = 0
    plus.Parent = frame
    local plusCorner = Instance.new("UICorner")
    plusCorner.CornerRadius = UDim.new(0, 6)
    plusCorner.Parent = plus

    local currentVal = default
    State[stateKey] = default

    local function updateValue(delta)
        currentVal = math.clamp(currentVal + delta, min, max)
        valueDisplay.Text = tostring(currentVal)
        State[stateKey] = currentVal
        label.Text = labelText .. ": " .. tostring(currentVal)
        if callback then callback(currentVal) end
    end

    minus.MouseButton1Click:Connect(function() updateValue(-1) end)
    plus.MouseButton1Click:Connect(function() updateValue(1) end)

    tabFrames[tabName].scroll.CanvasSize = UDim2.new(0, 0, 0, tabFrames[tabName].scroll.CanvasSize.Y.Offset + 50)
    return frame
end

local function createButton(tabName, labelText, callback)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 35)
    frame.BackgroundTransparency = 1
    frame.Parent = tabFrames[tabName].scroll

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.9, 0, 1, 0)
    btn.Position = UDim2.new(0.05, 0, 0, 0)
    btn.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
    btn.Text = labelText
    btn.TextColor3 = Color3.fromRGB(255,255,255)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 16
    btn.BorderSizePixel = 0
    btn.Parent = frame
    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 8)
    btnCorner.Parent = btn

    btn.MouseButton1Click:Connect(callback)

    tabFrames[tabName].scroll.CanvasSize = UDim2.new(0, 0, 0, tabFrames[tabName].scroll.CanvasSize.Y.Offset + 40)
    return frame
end

-- ================================================================
--  ЗАПОЛНЕНИЕ ВКЛАДОК
-- ================================================================

-- Main
createSection("Main", "Global")
createToggle("Main", "ESP", "ESP", function(v) if not v then clearESP() end end)
createToggle("Main", "Aimbot", "Aimbot", function(v) if v then startAimbot() else stopAimbot() end end)

-- Combat
createSection("Combat", "Combat")
createToggle("Combat", "Kill Aura", "KillAura", function(v) if v then startKillAura() else stopKillAura() end end)
createSlider("Combat", "Kill Aura Radius", "KillAuraRadius", 5, 100, 30)
createToggle("Combat", "Chop Aura", "ChopAura", function(v) if v then startChopAura() else stopChopAura() end end)
createToggle("Combat", "God Mode", "GodMode", function(v) if v then startGodMode() else stopGodMode() end end)

-- Farming
createSection("Farming", "Auto Farm")
createToggle("Farming", "Auto Farm Resources", "AutoFarm", function(v) if v then startAutoFarm() else stopAutoFarm() end end)
createToggle("Farming", "Auto Cook", "AutoCook", function(v) if v then startAutoCook() else stopAutoCook() end end)
createToggle("Farming", "Auto Upgrade Campfire", "AutoUpgradeCampfire", function(v) if v then startAutoUpgradeCampfire() else stopAutoUpgradeCampfire() end end)
createToggle("Farming", "Auto Scrap", "AutoScrap", function(v) if v then startAutoScrap() else stopAutoScrap() end end)
createToggle("Farming", "Auto Plant Saplings", "AutoPlant", function(v) if v then startAutoPlant() else stopAutoPlant() end end)
createToggle("Farming", "Auto Rescue Kids", "AutoRescueKids", function(v) if v then startAutoRescueKids() else stopAutoRescueKids() end end)
createToggle("Farming", "Auto Eat (hunger < 70%)", "AutoEat", function(v) if v then startAutoEat() else stopAutoEat() end end)

-- Movement
createSection("Movement", "Movement")
createToggle("Movement", "Fly (WASD+Space/Ctrl)", "Fly", function(v) if v then startFly() else stopFly() end end)
createSlider("Movement", "Fly Speed", "FlySpeed", 10, 500, 80)
createToggle("Movement", "NoClip", "Noclip")
createToggle("Movement", "Speed Hack", "Speed", function() updateSpeed() end)
createSlider("Movement", "Speed Value", "SpeedValue", 16, 500, 16, function() updateSpeed() end)
createToggle("Movement", "Infinite Jump", "InfiniteJump")

-- Visuals
createSection("Visuals", "Visuals")
createToggle("Visuals", "Fullbright", "Fullbright")
createToggle("Visuals", "No Fog", "NoFog")
createToggle("Visuals", "Anti-AFK", "AntiAFK", function(v) if v then startAntiAFK() else stopAntiAFK() end end)

-- Teleports
createSection("Teleports", "Teleports")
createButton("Teleports", "Teleport to Campfire", function() teleportTo("Campfire") end)
createButton("Teleports", "Teleport to Stronghold", function() teleportTo("Stronghold") end)
createButton("Teleports", "Teleport to Trader", function() teleportTo("Trader") end)
createButton("Teleports", "Teleport to Safe Zone", function() teleportTo("SafeZone") end)
createButton("Teleports", "Teleport to Nearest Kid", teleportToNearestKid)

-- Stop All (добавляем в Main)
createSection("Main", "Controls")
createButton("Main", "Stop All", function()
    State.ESP = false; clearESP()
    State.Aimbot = false; stopAimbot()
    State.Fly = false; stopFly()
    State.Speed = false; updateSpeed()
    State.Noclip = false; updateNoclip()
    State.GodMode = false; stopGodMode()
    State.KillAura = false; stopKillAura()
    State.ChopAura = false; stopChopAura()
    State.AutoFarm = false; stopAutoFarm()
    State.AutoCook = false; stopAutoCook()
    State.AutoUpgradeCampfire = false; stopAutoUpgradeCampfire()
    State.AutoScrap = false; stopAutoScrap()
    State.AutoPlant = false; stopAutoPlant()
    State.AutoRescueKids = false; stopAutoRescueKids()
    State.AutoEat = false; stopAutoEat()
    State.Fullbright = false; toggleFullbright()
    State.NoFog = false; toggleNoFog()
    State.AntiAFK = false; stopAntiAFK()
    local hum = getHumanoid()
    if hum then hum.WalkSpeed = 16 end
    -- Обновляем все кнопки (пройдём по всем вкладкам и сбросим состояние)
    StarterGui:SetCore("SendNotification", {
        Title = "Stopped",
        Text = "All functions disabled",
        Duration = 3,
    })
end)

-- ================================================================
--  ОПРЕДЕЛЕНИЕ ИГРЫ
-- ================================================================
local placeId = game.PlaceId
local gameName = "Unknown"

local supportedGames = {
    [7326934954] = "99 Nights in the Forest",
    [79546208627805] = "99 Nights in the Forest (alt)",
    [286090429] = "Arsenal",
    [6872265039] = "BedWars",
    [2753915549] = "Blox Fruits",
    [3260590327] = "Tower Defense Simulator",
    [142823291] = "Murder Mystery 2",
    [2933628366] = "Anime Fighting Simulator",
}

if supportedGames[placeId] then
    gameName = supportedGames[placeId]
else
    gameName = "Universal (not supported)"
end

titleLabel.Text = "ara_bara hub | " .. gameName

StarterGui:SetCore("SendNotification", {
    Title = "ara_bara hub",
    Text = "Loaded for: " .. gameName,
    Duration = 4,
})

print("✅ ara_bara hub loaded for:", gameName, "PlaceId:", placeId)local function getHumanoid()
    local c = getChar()
    return c and c:FindFirstChildOfClass("Humanoid")
end

local function teleport(cf)
    local hrp = getHRP()
    if hrp then hrp.CFrame = cf end
end

local function isEnemy(model)
    if not model then return false end
    local name = model.Name:lower()
    return name:find("cultist") or name:find("deer") or name:find("wolf") or
           name:find("bear") or name:find("owl") or name:find("ram") or
           name:find("golem") or name:find("corrupt")
end

local function isTree(model)
    if not model then return false end
    local name = model.Name:lower()
    return name:find("tree") or name:find("log") or name:find("stump")
end

local function isItem(model)
    if not model then return false end
    local name = model.Name:lower()
    return name:find("log") or name:find("plank") or name:find("stick") or
           name:find("food") or name:find("berry") or name:find("meat") or
           name:find("fuel") or name:find("medicine") or name:find("diamond")
end

local function isKid(model)
    if not model then return false end
    local name = model.Name:lower()
    return name:find("kid") or name:find("child") or name:find("survivor")
end

local function findNearest(targets, radius)
    local hrp = getHRP()
    if not hrp then return nil end
    local closest, closestDist = nil, radius or 1000
    for _, obj in pairs(targets) do
        local root = obj:FindFirstChildWhichIsA("BasePart") or obj.PrimaryPart
        if root then
            local dist = (root.Position - hrp.Position).Magnitude
            if dist < closestDist then
                closestDist = dist
                closest = obj
            end
        end
    end
    return closest
end

-- ================================================================
--  ФУНКЦИИ (ESP, Aimbot, Fly, ...) — без изменений
-- ================================================================
local espFolder = Instance.new("Folder", game.CoreGui)
espFolder.Name = "ara_bara_ESP"

local function clearESP()
    for _, v in pairs(espFolder:GetChildren()) do v:Destroy() end
end

local function updateESP()
    clearESP()
    if not State.ESP then return end
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local hl = Instance.new("Highlight")
            hl.FillColor = Color3.fromRGB(255, 0, 0)
            hl.OutlineColor = Color3.new(1,1,1)
            hl.FillTransparency = 0.6
            hl.OutlineTransparency = 0.3
            hl.Adornee = player.Character
            hl.Parent = espFolder
        end
    end
end

task.spawn(function()
    while true do
        if State.ESP then updateESP() else clearESP() end
        task.wait(2)
    end
end)

local aimbotConnection
local function startAimbot()
    if aimbotConnection then return end
    aimbotConnection = RunService.Heartbeat:Connect(function()
        if not State.Aimbot then return end
        local char = LocalPlayer.Character
        if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        local closest, closestDist = nil, 90
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character then
                local target = player.Character:FindFirstChild("Head") or player.Character:FindFirstChild("HumanoidRootPart")
                if target then
                    local screenPos, onScreen = Camera:WorldToViewportPoint(target.Position)
                    if onScreen then
                        local mousePos = UserInputService:GetMouseLocation()
                        local dist = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
                        if dist < closestDist then
                            closestDist = dist
                            closest = target
                        end
                    end
                end
            end
        end
        if closest then
            Camera.CFrame = CFrame.new(Camera.CFrame.Position, closest.Position)
        end
    end)
end

local function stopAimbot()
    if aimbotConnection then aimbotConnection:Disconnect(); aimbotConnection = nil end
end

local flyBody, flyConnection
local function startFly()
    if State.Fly then return end
    local hrp = getHRP()
    if not hrp then return end
    flyBody = Instance.new("BodyVelocity")
    flyBody.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    flyBody.Velocity = Vector3.zero
    flyBody.Parent = hrp
    local hum = getHumanoid()
    if hum then hum.PlatformStand = true end
    State.Fly = true
    flyConnection = RunService.Heartbeat:Connect(function()
        if not State.Fly then return end
        local hrp = getHRP()
        if not hrp or not flyBody then return end
        local dir = Vector3.zero
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir = dir + Camera.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir = dir - Camera.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir = dir - Camera.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir = dir + Camera.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir = dir + Vector3.yAxis end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then dir = dir - Vector3.yAxis end
        if dir.Magnitude > 0 then dir = dir.Unit end
        flyBody.Velocity = dir * State.FlySpeed
    end)
end

local function stopFly()
    State.Fly = false
    if flyBody then flyBody:Destroy(); flyBody = nil end
    if flyConnection then flyConnection:Disconnect(); flyConnection = nil end
    local hum = getHumanoid()
    if hum then hum.PlatformStand = false end
end

local function updateSpeed()
    local hum = getHumanoid()
    if hum then
        hum.WalkSpeed = State.Speed and State.SpeedValue or 16
    end
end
RunService.Heartbeat:Connect(updateSpeed)

local function updateNoclip()
    local char = getChar()
    if not char then return end
    for _, part in pairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CanCollide = not State.Noclip
        end
    end
end
RunService.Heartbeat:Connect(function()
    if State.Noclip then updateNoclip() end
end)

local godModeConnection
local function startGodMode()
    if godModeConnection then return end
    godModeConnection = RunService.Heartbeat:Connect(function()
        if not State.GodMode then return end
        local char = getChar()
        if not char then return end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then hum.Health = hum.MaxHealth end
    end)
end
local function stopGodMode()
    if godModeConnection then godModeConnection:Disconnect(); godModeConnection = nil end
end

UserInputService.JumpRequest:Connect(function()
    if State.InfiniteJump then
        local hum = getHumanoid()
        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)

local killAuraConnection
local function startKillAura()
    if killAuraConnection then return end
    killAuraConnection = RunService.Heartbeat:Connect(function()
        if not State.KillAura then return end
        local hrp = getHRP()
        if not hrp then return end
        local enemies = {}
        for _, obj in pairs(Workspace:GetDescendants()) do
            if obj:IsA("Model") and obj:FindFirstChildOfClass("Humanoid") then
                local hum = obj:FindFirstChildOfClass("Humanoid")
                if hum and hum.Health > 0 and isEnemy(obj) then
                    table.insert(enemies, obj)
                end
            end
        end
        local target = findNearest(enemies, State.KillAuraRadius)
        if target then
            local root = target:FindFirstChildWhichIsA("BasePart")
            if root then
                teleport(root.CFrame + Vector3.new(0, 2, 0))
                local char = getChar()
                if char then
                    for _, tool in pairs(char:GetChildren()) do
                        if tool:IsA("Tool") then
                            pcall(tool.Activate, tool)
                        end
                    end
                end
            end
        end
    end)
end
local function stopKillAura()
    if killAuraConnection then killAuraConnection:Disconnect(); killAuraConnection = nil end
end

local chopAuraConnection
local function startChopAura()
    if chopAuraConnection then return end
    chopAuraConnection = RunService.Heartbeat:Connect(function()
        if not State.ChopAura then return end
        local hrp = getHRP()
        if not hrp then return end
        local trees = {}
        for _, obj in pairs(Workspace:GetDescendants()) do
            if obj:IsA("Model") and isTree(obj) then
                local root = obj:FindFirstChildWhichIsA("BasePart")
                if root then table.insert(trees, obj) end
            end
        end
        local target = findNearest(trees, 20)
        if target then
            local root = target:FindFirstChildWhichIsA("BasePart")
            if root then
                teleport(root.CFrame + Vector3.new(0, 2, 0))
                task.wait(0.1)
                local remote = ReplicatedStorage:FindFirstChild("RemoteEvents") and ReplicatedStorage.RemoteEvents:FindFirstChild("ToolDamageObject")
                if remote then
                    local axe = LocalPlayer:FindFirstChild("Inventory") and LocalPlayer.Inventory:FindFirstChild("Old Axe")
                    if axe then
                        pcall(function()
                            remote:InvokeServer(target, axe, "1_" .. LocalPlayer.UserId, root.CFrame)
                        end)
                    end
                end
                task.wait(0.3)
            end
        end
    end)
end
local function stopChopAura()
    if chopAuraConnection then chopAuraConnection:Disconnect(); chopAuraConnection = nil end
end

local farmConnection
local function startAutoFarm()
    if farmConnection then return end
    farmConnection = RunService.Heartbeat:Connect(function()
        if not State.AutoFarm then return end
        local hrp = getHRP()
        if not hrp then return end
        local resourceType = State.ResourceType:lower()
        local targets = {}
        for _, obj in pairs(Workspace:GetDescendants()) do
            if obj:IsA("Model") and obj.Name:lower():find(resourceType) then
                local root = obj:FindFirstChildWhichIsA("BasePart")
                if root then table.insert(targets, obj) end
            end
        end
        local target = findNearest(targets, 50)
        if target then
            local root = target:FindFirstChildWhichIsA("BasePart")
            if root then
                teleport(root.CFrame + Vector3.new(0, 1, 0))
                task.wait(0.2)
                local prompt = target:FindFirstChildOfClass("ProximityPrompt")
                if prompt then
                    pcall(fireproximityprompt, prompt)
                end
                task.wait(0.3)
            end
        end
    end)
end
local function stopAutoFarm()
    if farmConnection then farmConnection:Disconnect(); farmConnection = nil end
end

local cookConnection
local function startAutoCook()
    if cookConnection then return end
    cookConnection = RunService.Heartbeat:Connect(function()
        if not State.AutoCook then return end
        local campfire = Workspace:FindFirstChild("Campfire", true)
        if campfire then
            local prompt = campfire:FindFirstChildOfClass("ProximityPrompt")
            if prompt then
                pcall(fireproximityprompt, prompt)
                task.wait(2)
            end
        end
    end)
end
local function stopAutoCook()
    if cookConnection then cookConnection:Disconnect(); cookConnection = nil end
end

local upgradeConn
local function startAutoUpgradeCampfire()
    if upgradeConn then return end
    upgradeConn = RunService.Heartbeat:Connect(function()
        if not State.AutoUpgradeCampfire then return end
        local campfire = Workspace:FindFirstChild("Campfire", true)
        if campfire then
            local prompt = campfire:FindFirstChildOfClass("ProximityPrompt")
            if prompt then
                pcall(fireproximityprompt, prompt)
                task.wait(1)
            end
        end
    end)
end
local function stopAutoUpgradeCampfire()
    if upgradeConn then upgradeConn:Disconnect(); upgradeConn = nil end
end

local scrapConn
local function startAutoScrap()
    if scrapConn then return end
    scrapConn = RunService.Heartbeat:Connect(function()
        if not State.AutoScrap then return end
        local workbench = Workspace:FindFirstChild("Workbench", true) or Workspace:FindFirstChild("CraftingBench", true)
        if workbench then
            local prompt = workbench:FindFirstChildOfClass("ProximityPrompt")
            if prompt then
                pcall(fireproximityprompt, prompt)
                task.wait(1)
            end
        end
    end)
end
local function stopAutoScrap()
    if scrapConn then scrapConn:Disconnect(); scrapConn = nil end
end

local plantConn
local function startAutoPlant()
    if plantConn then return end
    plantConn = RunService.Heartbeat:Connect(function()
        if not State.AutoPlant then return end
        local backpack = LocalPlayer.Backpack
        local sapling = nil
        for _, tool in pairs(backpack:GetChildren()) do
            if tool:IsA("Tool") and tool.Name:lower():find("sapling") then
                sapling = tool
                break
            end
        end
        if sapling then
            local hum = getHumanoid()
            if hum then
                hum:EquipTool(sapling)
                task.wait(0.2)
                pcall(sapling.Activate, sapling)
                task.wait(0.5)
            end
        end
    end)
end
local function stopAutoPlant()
    if plantConn then plantConn:Disconnect(); plantConn = nil end
end

local rescueConn
local function startAutoRescueKids()
    if rescueConn then return end
    rescueConn = RunService.Heartbeat:Connect(function()
        if not State.AutoRescueKids then return end
        local hrp = getHRP()
        if not hrp then return end
        local kids = {}
        for _, obj in pairs(Workspace:GetDescendants()) do
            if obj:IsA("Model") and isKid(obj) then
                local root = obj:FindFirstChildWhichIsA("BasePart")
                if root then table.insert(kids, obj) end
            end
        end
        local kid = findNearest(kids, 50)
        if kid then
            local root = kid:FindFirstChildWhichIsA("BasePart")
            if root then
                teleport(root.CFrame + Vector3.new(0, 2, 0))
                task.wait(0.3)
                local prompt = kid:FindFirstChildOfClass("ProximityPrompt")
                if prompt then
                    pcall(fireproximityprompt, prompt)
                end
                task.wait(1)
            end
        end
    end)
end
local function stopAutoRescueKids()
    if rescueConn then rescueConn:Disconnect(); rescueConn = nil end
end

local eatConn
local function startAutoEat()
    if eatConn then return end
    eatConn = RunService.Heartbeat:Connect(function()
        if not State.AutoEat then return end
        local hum = getHumanoid()
        if hum and hum.Health < hum.MaxHealth * 0.7 then
            local foodKeywords = {"chowder","fish","meat","potato","fruit","food","pizza","coconut","banana","apple","steak","egg","berry"}
            for _, tool in pairs(LocalPlayer.Backpack:GetChildren()) do
                if tool:IsA("Tool") then
                    local tName = tool.Name:lower()
                    for _, kw in ipairs(foodKeywords) do
                        if tName:find(kw) then
                            hum:EquipTool(tool)
                            task.wait(0.1)
                            pcall(tool.Activate, tool)
                            task.wait(0.3)
                            break
                        end
                    end
                end
            end
        end
    end)
end
local function stopAutoEat()
    if eatConn then eatConn:Disconnect(); eatConn = nil end
end

local origLighting = {}
local function toggleFullbright()
    if State.Fullbright then
        origLighting.Ambient = Lighting.Ambient
        origLighting.Brightness = Lighting.Brightness
        origLighting.ClockTime = Lighting.ClockTime
        Lighting.Ambient = Color3.new(1,1,1)
        Lighting.Brightness = 2
        Lighting.ClockTime = 14
    else
        for k,v in pairs(origLighting) do Lighting[k] = v end
    end
end
RunService.Heartbeat:Connect(function()
    if State.Fullbright then toggleFullbright() end
end)

local function toggleNoFog()
    if State.NoFog then
        Lighting.FogEnd = 1e6
    else
        Lighting.FogEnd = origLighting.FogEnd or 1000
    end
end
RunService.Heartbeat:Connect(function()
    if State.NoFog then toggleNoFog() end
end)

local antiAFKConn
local function startAntiAFK()
    if antiAFKConn then return end
    local vu = game:GetService("VirtualUser")
    antiAFKConn = LocalPlayer.Idled:Connect(function()
        vu:Button2Down(Vector2.zero, Camera.CFrame)
        task.wait(1)
        vu:Button2Up(Vector2.zero, Camera.CFrame)
    end)
end
local function stopAntiAFK()
    if antiAFKConn then antiAFKConn:Disconnect(); antiAFKConn = nil end
end

local function teleportTo(name)
    local target = Workspace:FindFirstChild(name, true)
    if target then
        local root = target:FindFirstChildWhichIsA("BasePart") or target
        teleport(root.CFrame + Vector3.new(0, 3, 0))
    end
end

local function teleportToNearestKid()
    local hrp = getHRP()
    if not hrp then return end
    local kids = {}
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") and isKid(obj) then
            local root = obj:FindFirstChildWhichIsA("BasePart")
            if root then table.insert(kids, obj) end
        end
    end
    local kid = findNearest(kids, 100)
    if kid then
        local root = kid:FindFirstChildWhichIsA("BasePart")
        if root then teleport(root.CFrame + Vector3.new(0, 2, 0)) end
    end
end

-- ================================================================
--  GUI (Rayfield-подобный)
-- ================================================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ara_bara_hub"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

-- Основное окно
local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 450, 0, 500)
mainFrame.Position = UDim2.new(0.5, -225, 0.5, -250)
mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
mainFrame.BackgroundTransparency = 0.05
mainFrame.BorderSizePixel = 0
mainFrame.ClipsDescendants = true
mainFrame.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 12)
corner.Parent = mainFrame

-- Тень
local shadow = Instance.new("ImageLabel")
shadow.Size = UDim2.new(1, 20, 1, 20)
shadow.Position = UDim2.new(0, -10, 0, -10)
shadow.BackgroundTransparency = 1
shadow.Image = "rbxassetid://1316047257"
shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
shadow.ImageTransparency = 0.6
shadow.ZIndex = 0
shadow.Parent = mainFrame

-- Заголовок
local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 40)
titleBar.Position = UDim2.new(0, 0, 0, 0)
titleBar.BackgroundTransparency = 1
titleBar.Parent = mainFrame

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(0.8, 0, 1, 0)
titleLabel.Position = UDim2.new(0, 10, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "ara_bara hub"
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextSize = 18
titleLabel.Parent = titleBar

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 30, 0, 30)
closeBtn.Position = UDim2.new(1, -35, 0, 5)
closeBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
closeBtn.Text = "✕"
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.TextSize = 18
closeBtn.Font = Enum.Font.GothamBold
closeBtn.BorderSizePixel = 0
closeBtn.Parent = titleBar
local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 6)
closeCorner.Parent = closeBtn
closeBtn.MouseButton1Click:Connect(function()
    screenGui:Destroy()
end)

-- Tab Bar
local tabBar = Instance.new("Frame")
tabBar.Size = UDim2.new(1, 0, 0, 40)
tabBar.Position = UDim2.new(0, 0, 0, 40)
tabBar.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
tabBar.BackgroundTransparency = 0.3
tabBar.BorderSizePixel = 0
tabBar.Parent = mainFrame

local tabButtons = {}
local tabFrames = {}
local selectedTab = nil

local tabNames = {"Main", "Combat", "Farming", "Movement", "Visuals", "Teleports"}
local tabIcons = {"home", "sword", "pickaxe", "zap", "eye", "map-pin"} -- не используются, но для порядка

local function createTab(name, index)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1 / #tabNames, 0, 1, 0)
    btn.Position = UDim2.new((index - 1) / #tabNames, 0, 0, 0)
    btn.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
    btn.BackgroundTransparency = 0.5
    btn.Text = name
    btn.TextColor3 = Color3.fromRGB(200, 200, 200)
    btn.TextSize = 14
    btn.Font = Enum.Font.Gotham
    btn.BorderSizePixel = 0
    btn.Parent = tabBar
    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 0)
    btnCorner.Parent = btn

    local tabFrame = Instance.new("Frame")
    tabFrame.Size = UDim2.new(1, 0, 1, -80)
    tabFrame.Position = UDim2.new(0, 0, 0, 80)
    tabFrame.BackgroundTransparency = 1
    tabFrame.Visible = (index == 1)
    tabFrame.Parent = mainFrame

    -- Scroll для содержимого вкладки
    local scroll = Instance.new("ScrollingFrame")
    scroll.Size = UDim2.new(1, -20, 1, -10)
    scroll.Position = UDim2.new(0, 10, 0, 5)
    scroll.BackgroundTransparency = 1
    scroll.CanvasSize = UDim2.new(0, 0, 0, 10)
    scroll.ScrollBarThickness = 6
    scroll.ScrollBarImageColor3 = Color3.fromRGB(80, 80, 90)
    scroll.Parent = tabFrame

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 5)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = scroll

    tabButtons[name] = btn
    tabFrames[name] = {frame = tabFrame, scroll = scroll, layout = layout}

    btn.MouseButton1Click:Connect(function()
        for _, tb in pairs(tabButtons) do
            tb.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
            tb.BackgroundTransparency = 0.5
            tb.TextColor3 = Color3.fromRGB(200, 200, 200)
        end
        btn.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
        btn.BackgroundTransparency = 0
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        for _, tf in pairs(tabFrames) do
            tf.frame.Visible = false
        end
        tabFrames[name].frame.Visible = true
    end)

    return tabFrames[name]
end

-- Создаем вкладки
for i, name in ipairs(tabNames) do
    createTab(name, i)
end

-- Утилиты для добавления элементов в вкладку
local function addElement(tabName, element)
    local scroll = tabFrames[tabName].scroll
    element.Parent = scroll
    tabFrames[tabName].scroll.CanvasSize = UDim2.new(0, 0, 0, tabFrames[tabName].scroll.CanvasSize.Y.Offset + 40)
end

local function createSection(tabName, title)
    local section = Instance.new("TextLabel")
    section.Size = UDim2.new(1, 0, 0, 25)
    section.BackgroundTransparency = 1
    section.Text = title
    section.TextColor3 = Color3.fromRGB(150, 150, 160)
    section.TextSize = 14
    section.Font = Enum.Font.GothamBold
    section.TextXAlignment = Enum.TextXAlignment.Left
    section.Parent = tabFrames[tabName].scroll
    tabFrames[tabName].scroll.CanvasSize = UDim2.new(0, 0, 0, tabFrames[tabName].scroll.CanvasSize.Y.Offset + 30)
    return section
end

local function createToggle(tabName, labelText, stateKey, callback)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 35)
    frame.BackgroundTransparency = 1
    frame.Parent = tabFrames[tabName].scroll

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.7, 0, 1, 0)
    label.Position = UDim2.new(0, 5, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = labelText
    label.TextColor3 = Color3.fromRGB(220, 220, 220)
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Font = Enum.Font.Gotham
    label.TextSize = 15
    label.Parent = frame

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.2, 0, 0.8, 0)
    btn.Position = UDim2.new(0.78, 0, 0.1, 0)
    btn.BackgroundColor3 = Color3.fromRGB(80, 80, 90)
    btn.Text = "OFF"
    btn.TextColor3 = Color3.fromRGB(255,255,255)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 14
    btn.BorderSizePixel = 0
    btn.Parent = frame
    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 6)
    btnCorner.Parent = btn

    btn.MouseButton1Click:Connect(function()
        State[stateKey] = not State[stateKey]
        btn.BackgroundColor3 = State[stateKey] and Color3.fromRGB(60, 180, 100) or Color3.fromRGB(80, 80, 90)
        btn.Text = State[stateKey] and "ON" or "OFF"
        if callback then callback(State[stateKey]) end
    end)

    tabFrames[tabName].scroll.CanvasSize = UDim2.new(0, 0, 0, tabFrames[tabName].scroll.CanvasSize.Y.Offset + 40)
    return frame
end

local function createSlider(tabName, labelText, stateKey, min, max, default, callback)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 45)
    frame.BackgroundTransparency = 1
    frame.Parent = tabFrames[tabName].scroll

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.6, 0, 0.5, 0)
    label.Position = UDim2.new(0, 5, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = labelText .. ": " .. tostring(default)
    label.TextColor3 = Color3.fromRGB(220, 220, 220)
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Font = Enum.Font.Gotham
    label.TextSize = 14
    label.Parent = frame

    local valueDisplay = Instance.new("TextLabel")
    valueDisplay.Size = UDim2.new(0.2, 0, 0.5, 0)
    valueDisplay.Position = UDim2.new(0.78, 0, 0, 0)
    valueDisplay.BackgroundTransparency = 1
    valueDisplay.Text = tostring(default)
    valueDisplay.TextColor3 = Color3.fromRGB(255, 255, 255)
    valueDisplay.TextXAlignment = Enum.TextXAlignment.Right
    valueDisplay.Font = Enum.Font.GothamBold
    valueDisplay.TextSize = 14
    valueDisplay.Parent = frame

    local minus = Instance.new("TextButton")
    minus.Size = UDim2.new(0.08, 0, 0.3, 0)
    minus.Position = UDim2.new(0.7, 0, 0.6, 0)
    minus.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
    minus.Text = "-"
    minus.TextColor3 = Color3.fromRGB(255,255,255)
    minus.Font = Enum.Font.GothamBold
    minus.TextSize = 18
    minus.BorderSizePixel = 0
    minus.Parent = frame
    local minusCorner = Instance.new("UICorner")
    minusCorner.CornerRadius = UDim.new(0, 6)
    minusCorner.Parent = minus

    local plus = Instance.new("TextButton")
    plus.Size = UDim2.new(0.08, 0, 0.3, 0)
    plus.Position = UDim2.new(0.85, 0, 0.6, 0)
    plus.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
    plus.Text = "+"
    plus.TextColor3 = Color3.fromRGB(255,255,255)
    plus.Font = Enum.Font.GothamBold
    plus.TextSize = 18
    plus.BorderSizePixel = 0
    plus.Parent = frame
    local plusCorner = Instance.new("UICorner")
    plusCorner.CornerRadius = UDim.new(0, 6)
    plusCorner.Parent = plus

    local currentVal = default
    State[stateKey] = default

    local function updateValue(delta)
        currentVal = math.clamp(currentVal + delta, min, max)
        valueDisplay.Text = tostring(currentVal)
        State[stateKey] = currentVal
        label.Text = labelText .. ": " .. tostring(currentVal)
        if callback then callback(currentVal) end
    end

    minus.MouseButton1Click:Connect(function() updateValue(-1) end)
    plus.MouseButton1Click:Connect(function() updateValue(1) end)

    tabFrames[tabName].scroll.CanvasSize = UDim2.new(0, 0, 0, tabFrames[tabName].scroll.CanvasSize.Y.Offset + 50)
    return frame
end

local function createButton(tabName, labelText, callback)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 35)
    frame.BackgroundTransparency = 1
    frame.Parent = tabFrames[tabName].scroll

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.9, 0, 1, 0)
    btn.Position = UDim2.new(0.05, 0, 0, 0)
    btn.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
    btn.Text = labelText
    btn.TextColor3 = Color3.fromRGB(255,255,255)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 16
    btn.BorderSizePixel = 0
    btn.Parent = frame
    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 8)
    btnCorner.Parent = btn

    btn.MouseButton1Click:Connect(callback)

    tabFrames[tabName].scroll.CanvasSize = UDim2.new(0, 0, 0, tabFrames[tabName].scroll.CanvasSize.Y.Offset + 40)
    return frame
end

-- ================================================================
--  ЗАПОЛНЕНИЕ ВКЛАДОК
-- ================================================================

-- Main
createSection("Main", "Global")
createToggle("Main", "ESP", "ESP", function(v) if not v then clearESP() end end)
createToggle("Main", "Aimbot", "Aimbot", function(v) if v then startAimbot() else stopAimbot() end end)

-- Combat
createSection("Combat", "Combat")
createToggle("Combat", "Kill Aura", "KillAura", function(v) if v then startKillAura() else stopKillAura() end end)
createSlider("Combat", "Kill Aura Radius", "KillAuraRadius", 5, 100, 30)
createToggle("Combat", "Chop Aura", "ChopAura", function(v) if v then startChopAura() else stopChopAura() end end)
createToggle("Combat", "God Mode", "GodMode", function(v) if v then startGodMode() else stopGodMode() end end)

-- Farming
createSection("Farming", "Auto Farm")
createToggle("Farming", "Auto Farm Resources", "AutoFarm", function(v) if v then startAutoFarm() else stopAutoFarm() end end)
createToggle("Farming", "Auto Cook", "AutoCook", function(v) if v then startAutoCook() else stopAutoCook() end end)
createToggle("Farming", "Auto Upgrade Campfire", "AutoUpgradeCampfire", function(v) if v then startAutoUpgradeCampfire() else stopAutoUpgradeCampfire() end end)
createToggle("Farming", "Auto Scrap", "AutoScrap", function(v) if v then startAutoScrap() else stopAutoScrap() end end)
createToggle("Farming", "Auto Plant Saplings", "AutoPlant", function(v) if v then startAutoPlant() else stopAutoPlant() end end)
createToggle("Farming", "Auto Rescue Kids", "AutoRescueKids", function(v) if v then startAutoRescueKids() else stopAutoRescueKids() end end)
createToggle("Farming", "Auto Eat (hunger < 70%)", "AutoEat", function(v) if v then startAutoEat() else stopAutoEat() end end)

-- Movement
createSection("Movement", "Movement")
createToggle("Movement", "Fly (WASD+Space/Ctrl)", "Fly", function(v) if v then startFly() else stopFly() end end)
createSlider("Movement", "Fly Speed", "FlySpeed", 10, 500, 80)
createToggle("Movement", "NoClip", "Noclip")
createToggle("Movement", "Speed Hack", "Speed", function() updateSpeed() end)
createSlider("Movement", "Speed Value", "SpeedValue", 16, 500, 16, function() updateSpeed() end)
createToggle("Movement", "Infinite Jump", "InfiniteJump")

-- Visuals
createSection("Visuals", "Visuals")
createToggle("Visuals", "Fullbright", "Fullbright")
createToggle("Visuals", "No Fog", "NoFog")
createToggle("Visuals", "Anti-AFK", "AntiAFK", function(v) if v then startAntiAFK() else stopAntiAFK() end end)

-- Teleports
createSection("Teleports", "Teleports")
createButton("Teleports", "Teleport to Campfire", function() teleportTo("Campfire") end)
createButton("Teleports", "Teleport to Stronghold", function() teleportTo("Stronghold") end)
createButton("Teleports", "Teleport to Trader", function() teleportTo("Trader") end)
createButton("Teleports", "Teleport to Safe Zone", function() teleportTo("SafeZone") end)
createButton("Teleports", "Teleport to Nearest Kid", teleportToNearestKid)

-- Stop All (добавляем в Main)
createSection("Main", "Controls")
createButton("Main", "Stop All", function()
    State.ESP = false; clearESP()
    State.Aimbot = false; stopAimbot()
    State.Fly = false; stopFly()
    State.Speed = false; updateSpeed()
    State.Noclip = false; updateNoclip()
    State.GodMode = false; stopGodMode()
    State.KillAura = false; stopKillAura()
    State.ChopAura = false; stopChopAura()
    State.AutoFarm = false; stopAutoFarm()
    State.AutoCook = false; stopAutoCook()
    State.AutoUpgradeCampfire = false; stopAutoUpgradeCampfire()
    State.AutoScrap = false; stopAutoScrap()
    State.AutoPlant = false; stopAutoPlant()
    State.AutoRescueKids = false; stopAutoRescueKids()
    State.AutoEat = false; stopAutoEat()
    State.Fullbright = false; toggleFullbright()
    State.NoFog = false; toggleNoFog()
    State.AntiAFK = false; stopAntiAFK()
    local hum = getHumanoid()
    if hum then hum.WalkSpeed = 16 end
    -- Обновляем все кнопки (пройдём по всем вкладкам и сбросим состояние)
    StarterGui:SetCore("SendNotification", {
        Title = "Stopped",
        Text = "All functions disabled",
        Duration = 3,
    })
end)

-- ================================================================
--  ОПРЕДЕЛЕНИЕ ИГРЫ
-- ================================================================
local placeId = game.PlaceId
local gameName = "Unknown"

local supportedGames = {
    [7326934954] = "99 Nights in the Forest",
    [79546208627805] = "99 Nights in the Forest (alt)",
    [286090429] = "Arsenal",
    [6872265039] = "BedWars",
    [2753915549] = "Blox Fruits",
    [3260590327] = "Tower Defense Simulator",
    [142823291] = "Murder Mystery 2",
    [2933628366] = "Anime Fighting Simulator",
}

if supportedGames[placeId] then
    gameName = supportedGames[placeId]
else
    gameName = "Universal (not supported)"
end

titleLabel.Text = "ara_bara hub | " .. gameName

StarterGui:SetCore("SendNotification", {
    Title = "ara_bara hub",
    Text = "Loaded for: " .. gameName,
    Duration = 4,
})

print("✅ ara_bara hub loaded for:", gameName, "PlaceId:", placeId)    local c = getChar()
    return c and c:FindFirstChildOfClass("Humanoid")
end

local function teleport(cf)
    local hrp = getHRP()
    if hrp then hrp.CFrame = cf end
end

local function isEnemy(model)
    if not model then return false end
    local name = model.Name:lower()
    return name:find("cultist") or name:find("deer") or name:find("wolf") or
           name:find("bear") or name:find("owl") or name:find("ram") or
           name:find("golem") or name:find("corrupt")
end

local function isTree(model)
    if not model then return false end
    local name = model.Name:lower()
    return name:find("tree") or name:find("log") or name:find("stump")
end

local function isItem(model)
    if not model then return false end
    local name = model.Name:lower()
    return name:find("log") or name:find("plank") or name:find("stick") or
           name:find("food") or name:find("berry") or name:find("meat") or
           name:find("fuel") or name:find("medicine") or name:find("diamond")
end

local function isKid(model)
    if not model then return false end
    local name = model.Name:lower()
    return name:find("kid") or name:find("child") or name:find("survivor")
end

local function findNearest(targets, radius)
    local hrp = getHRP()
    if not hrp then return nil end
    local closest, closestDist = nil, radius or 1000
    for _, obj in pairs(targets) do
        local root = obj:FindFirstChildWhichIsA("BasePart") or obj.PrimaryPart
        if root then
            local dist = (root.Position - hrp.Position).Magnitude
            if dist < closestDist then
                closestDist = dist
                closest = obj
            end
        end
    end
    return closest
end

-- ================================================================
--  ФУНКЦИИ
-- ================================================================

-- ESP (Highlight)
local espFolder = Instance.new("Folder", game.CoreGui)
espFolder.Name = "ara_bara_ESP"

local function clearESP()
    for _, v in pairs(espFolder:GetChildren()) do v:Destroy() end
end

local function updateESP()
    clearESP()
    if not State.ESP then return end
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local hl = Instance.new("Highlight")
            hl.FillColor = Color3.fromRGB(255, 0, 0)
            hl.OutlineColor = Color3.new(1,1,1)
            hl.FillTransparency = 0.6
            hl.OutlineTransparency = 0.3
            hl.Adornee = player.Character
            hl.Parent = espFolder
        end
    end
end

task.spawn(function()
    while true do
        if State.ESP then updateESP() else clearESP() end
        task.wait(2)
    end
end)

-- Aimbot (простой, без Drawing)
local aimbotConnection
local function startAimbot()
    if aimbotConnection then return end
    aimbotConnection = RunService.Heartbeat:Connect(function()
        if not State.Aimbot then return end
        local char = LocalPlayer.Character
        if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        local closest, closestDist = nil, 90
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character then
                local target = player.Character:FindFirstChild("Head") or player.Character:FindFirstChild("HumanoidRootPart")
                if target then
                    local screenPos, onScreen = Camera:WorldToViewportPoint(target.Position)
                    if onScreen then
                        local mousePos = UserInputService:GetMouseLocation()
                        local dist = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
                        if dist < closestDist then
                            closestDist = dist
                            closest = target
                        end
                    end
                end
            end
        end
        if closest then
            Camera.CFrame = CFrame.new(Camera.CFrame.Position, closest.Position)
        end
    end)
end

local function stopAimbot()
    if aimbotConnection then aimbotConnection:Disconnect(); aimbotConnection = nil end
end

-- Fly
local flyBody, flyConnection
local function startFly()
    if State.Fly then return end
    local hrp = getHRP()
    if not hrp then return end
    flyBody = Instance.new("BodyVelocity")
    flyBody.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    flyBody.Velocity = Vector3.zero
    flyBody.Parent = hrp
    local hum = getHumanoid()
    if hum then hum.PlatformStand = true end
    State.Fly = true
    flyConnection = RunService.Heartbeat:Connect(function()
        if not State.Fly then return end
        local hrp = getHRP()
        if not hrp or not flyBody then return end
        local dir = Vector3.zero
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir = dir + Camera.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir = dir - Camera.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir = dir - Camera.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir = dir + Camera.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir = dir + Vector3.yAxis end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then dir = dir - Vector3.yAxis end
        if dir.Magnitude > 0 then dir = dir.Unit end
        flyBody.Velocity = dir * State.FlySpeed
    end)
end

local function stopFly()
    State.Fly = false
    if flyBody then flyBody:Destroy(); flyBody = nil end
    if flyConnection then flyConnection:Disconnect(); flyConnection = nil end
    local hum = getHumanoid()
    if hum then hum.PlatformStand = false end
end

-- Speed
local function updateSpeed()
    local hum = getHumanoid()
    if hum then
        hum.WalkSpeed = State.Speed and State.SpeedValue or 16
    end
end

RunService.Heartbeat:Connect(updateSpeed)

-- Noclip
local function updateNoclip()
    local char = getChar()
    if not char then return end
    for _, part in pairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CanCollide = not State.Noclip
        end
    end
end

RunService.Heartbeat:Connect(function()
    if State.Noclip then updateNoclip() end
end)

-- GodMode
local godModeConnection
local function startGodMode()
    if godModeConnection then return end
    godModeConnection = RunService.Heartbeat:Connect(function()
        if not State.GodMode then return end
        local char = getChar()
        if not char then return end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then hum.Health = hum.MaxHealth end
    end)
end

local function stopGodMode()
    if godModeConnection then godModeConnection:Disconnect(); godModeConnection = nil end
end

-- Infinite Jump
UserInputService.JumpRequest:Connect(function()
    if State.InfiniteJump then
        local hum = getHumanoid()
        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)

-- Kill Aura (99 Nights)
local killAuraConnection
local function startKillAura()
    if killAuraConnection then return end
    killAuraConnection = RunService.Heartbeat:Connect(function()
        if not State.KillAura then return end
        local hrp = getHRP()
        if not hrp then return end
        local enemies = {}
        for _, obj in pairs(Workspace:GetDescendants()) do
            if obj:IsA("Model") and obj:FindFirstChildOfClass("Humanoid") then
                local hum = obj:FindFirstChildOfClass("Humanoid")
                if hum and hum.Health > 0 and isEnemy(obj) then
                    table.insert(enemies, obj)
                end
            end
        end
        local target = findNearest(enemies, State.KillAuraRadius)
        if target then
            local root = target:FindFirstChildWhichIsA("BasePart")
            if root then
                teleport(root.CFrame + Vector3.new(0, 2, 0))
                local char = getChar()
                if char then
                    for _, tool in pairs(char:GetChildren()) do
                        if tool:IsA("Tool") then
                            pcall(tool.Activate, tool)
                        end
                    end
                end
            end
        end
    end)
end

local function stopKillAura()
    if killAuraConnection then killAuraConnection:Disconnect(); killAuraConnection = nil end
end

-- Chop Aura (99 Nights)
local chopAuraConnection
local function startChopAura()
    if chopAuraConnection then return end
    chopAuraConnection = RunService.Heartbeat:Connect(function()
        if not State.ChopAura then return end
        local hrp = getHRP()
        if not hrp then return end
        local trees = {}
        for _, obj in pairs(Workspace:GetDescendants()) do
            if obj:IsA("Model") and isTree(obj) then
                local root = obj:FindFirstChildWhichIsA("BasePart")
                if root then table.insert(trees, obj) end
            end
        end
        local target = findNearest(trees, 20)
        if target then
            local root = target:FindFirstChildWhichIsA("BasePart")
            if root then
                teleport(root.CFrame + Vector3.new(0, 2, 0))
                task.wait(0.1)
                local remote = ReplicatedStorage:FindFirstChild("RemoteEvents") and ReplicatedStorage.RemoteEvents:FindFirstChild("ToolDamageObject")
                if remote then
                    local axe = LocalPlayer:FindFirstChild("Inventory") and LocalPlayer.Inventory:FindFirstChild("Old Axe")
                    if axe then
                        pcall(function()
                            remote:InvokeServer(target, axe, "1_" .. LocalPlayer.UserId, root.CFrame)
                        end)
                    end
                end
                task.wait(0.3)
            end
        end
    end)
end

local function stopChopAura()
    if chopAuraConnection then chopAuraConnection:Disconnect(); chopAuraConnection = nil end
end

-- Auto Farm Resources (99 Nights)
local farmConnection
local function startAutoFarm()
    if farmConnection then return end
    farmConnection = RunService.Heartbeat:Connect(function()
        if not State.AutoFarm then return end
        local hrp = getHRP()
        if not hrp then return end
        local resourceType = State.ResourceType:lower()
        local targets = {}
        for _, obj in pairs(Workspace:GetDescendants()) do
            if obj:IsA("Model") and obj.Name:lower():find(resourceType) then
                local root = obj:FindFirstChildWhichIsA("BasePart")
                if root then table.insert(targets, obj) end
            end
        end
        local target = findNearest(targets, 50)
        if target then
            local root = target:FindFirstChildWhichIsA("BasePart")
            if root then
                teleport(root.CFrame + Vector3.new(0, 1, 0))
                task.wait(0.2)
                local prompt = target:FindFirstChildOfClass("ProximityPrompt")
                if prompt then
                    pcall(fireproximityprompt, prompt)
                end
                task.wait(0.3)
            end
        end
    end)
end

local function stopAutoFarm()
    if farmConnection then farmConnection:Disconnect(); farmConnection = nil end
end

-- Auto Cook
local cookConnection
local function startAutoCook()
    if cookConnection then return end
    cookConnection = RunService.Heartbeat:Connect(function()
        if not State.AutoCook then return end
        local campfire = Workspace:FindFirstChild("Campfire", true)
        if campfire then
            local prompt = campfire:FindFirstChildOfClass("ProximityPrompt")
            if prompt then
                pcall(fireproximityprompt, prompt)
                task.wait(2)
            end
        end
    end)
end

local function stopAutoCook()
    if cookConnection then cookConnection:Disconnect(); cookConnection = nil end
end

-- Auto Upgrade Campfire
local upgradeConn
local function startAutoUpgradeCampfire()
    if upgradeConn then return end
    upgradeConn = RunService.Heartbeat:Connect(function()
        if not State.AutoUpgradeCampfire then return end
        local campfire = Workspace:FindFirstChild("Campfire", true)
        if campfire then
            local prompt = campfire:FindFirstChildOfClass("ProximityPrompt")
            if prompt then
                pcall(fireproximityprompt, prompt)
                task.wait(1)
            end
        end
    end)
end

local function stopAutoUpgradeCampfire()
    if upgradeConn then upgradeConn:Disconnect(); upgradeConn = nil end
end

-- Auto Scrap
local scrapConn
local function startAutoScrap()
    if scrapConn then return end
    scrapConn = RunService.Heartbeat:Connect(function()
        if not State.AutoScrap then return end
        local workbench = Workspace:FindFirstChild("Workbench", true) or Workspace:FindFirstChild("CraftingBench", true)
        if workbench then
            local prompt = workbench:FindFirstChildOfClass("ProximityPrompt")
            if prompt then
                pcall(fireproximityprompt, prompt)
                task.wait(1)
            end
        end
    end)
end

local function stopAutoScrap()
    if scrapConn then scrapConn:Disconnect(); scrapConn = nil end
end

-- Auto Plant
local plantConn
local function startAutoPlant()
    if plantConn then return end
    plantConn = RunService.Heartbeat:Connect(function()
        if not State.AutoPlant then return end
        local backpack = LocalPlayer.Backpack
        local sapling = nil
        for _, tool in pairs(backpack:GetChildren()) do
            if tool:IsA("Tool") and tool.Name:lower():find("sapling") then
                sapling = tool
                break
            end
        end
        if sapling then
            local hum = getHumanoid()
            if hum then
                hum:EquipTool(sapling)
                task.wait(0.2)
                pcall(sapling.Activate, sapling)
                task.wait(0.5)
            end
        end
    end)
end

local function stopAutoPlant()
    if plantConn then plantConn:Disconnect(); plantConn = nil end
end

-- Auto Rescue Kids
local rescueConn
local function startAutoRescueKids()
    if rescueConn then return end
    rescueConn = RunService.Heartbeat:Connect(function()
        if not State.AutoRescueKids then return end
        local hrp = getHRP()
        if not hrp then return end
        local kids = {}
        for _, obj in pairs(Workspace:GetDescendants()) do
            if obj:IsA("Model") and isKid(obj) then
                local root = obj:FindFirstChildWhichIsA("BasePart")
                if root then table.insert(kids, obj) end
            end
        end
        local kid = findNearest(kids, 50)
        if kid then
            local root = kid:FindFirstChildWhichIsA("BasePart")
            if root then
                teleport(root.CFrame + Vector3.new(0, 2, 0))
                task.wait(0.3)
                local prompt = kid:FindFirstChildOfClass("ProximityPrompt")
                if prompt then
                    pcall(fireproximityprompt, prompt)
                end
                task.wait(1)
            end
        end
    end)
end

local function stopAutoRescueKids()
    if rescueConn then rescueConn:Disconnect(); rescueConn = nil end
end

-- Auto Eat
local eatConn
local function startAutoEat()
    if eatConn then return end
    eatConn = RunService.Heartbeat:Connect(function()
        if not State.AutoEat then return end
        local hum = getHumanoid()
        if hum and hum.Health < hum.MaxHealth * 0.7 then
            local foodKeywords = {"chowder","fish","meat","potato","fruit","food","pizza","coconut","banana","apple","steak","egg","berry"}
            for _, tool in pairs(LocalPlayer.Backpack:GetChildren()) do
                if tool:IsA("Tool") then
                    local tName = tool.Name:lower()
                    for _, kw in ipairs(foodKeywords) do
                        if tName:find(kw) then
                            hum:EquipTool(tool)
                            task.wait(0.1)
                            pcall(tool.Activate, tool)
                            task.wait(0.3)
                            break
                        end
                    end
                end
            end
        end
    end)
end

local function stopAutoEat()
    if eatConn then eatConn:Disconnect(); eatConn = nil end
end

-- Fullbright
local origLighting = {}
local function toggleFullbright()
    if State.Fullbright then
        origLighting.Ambient = Lighting.Ambient
        origLighting.Brightness = Lighting.Brightness
        origLighting.ClockTime = Lighting.ClockTime
        Lighting.Ambient = Color3.new(1,1,1)
        Lighting.Brightness = 2
        Lighting.ClockTime = 14
    else
        for k,v in pairs(origLighting) do Lighting[k] = v end
    end
end

RunService.Heartbeat:Connect(function()
    if State.Fullbright then toggleFullbright() end
end)

-- No Fog
local function toggleNoFog()
    if State.NoFog then
        Lighting.FogEnd = 1e6
    else
        Lighting.FogEnd = origLighting.FogEnd or 1000
    end
end

RunService.Heartbeat:Connect(function()
    if State.NoFog then toggleNoFog() end
end)

-- Anti-AFK
local antiAFKConn
local function startAntiAFK()
    if antiAFKConn then return end
    local vu = game:GetService("VirtualUser")
    antiAFKConn = LocalPlayer.Idled:Connect(function()
        vu:Button2Down(Vector2.zero, Camera.CFrame)
        task.wait(1)
        vu:Button2Up(Vector2.zero, Camera.CFrame)
    end)
end

local function stopAntiAFK()
    if antiAFKConn then antiAFKConn:Disconnect(); antiAFKConn = nil end
end

-- Teleports
local function teleportTo(name)
    local target = Workspace:FindFirstChild(name, true)
    if target then
        local root = target:FindFirstChildWhichIsA("BasePart") or target
        teleport(root.CFrame + Vector3.new(0, 3, 0))
    end
end

local function teleportToNearestKid()
    local hrp = getHRP()
    if not hrp then return end
    local kids = {}
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") and isKid(obj) then
            local root = obj:FindFirstChildWhichIsA("BasePart")
            if root then table.insert(kids, obj) end
        end
    end
    local kid = findNearest(kids, 100)
    if kid then
        local root = kid:FindFirstChildWhichIsA("BasePart")
        if root then teleport(root.CFrame + Vector3.new(0, 2, 0)) end
    end
end

-- ================================================================
--  GUI (встроенный, без Rayfield)
-- ================================================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ara_bara_hub"
screenGui.ResetOnSpawn = false
screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 350, 0, 450)
mainFrame.Position = UDim2.new(0.5, -175, 0.5, -225)
mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
mainFrame.BackgroundTransparency = 0.1
mainFrame.BorderSizePixel = 0
mainFrame.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 12)
corner.Parent = mainFrame

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 40)
title.Position = UDim2.new(0, 0, 0, 5)
title.BackgroundTransparency = 1
title.Text = "ara_bara hub | 99 Nights"
title.TextColor3 = Color3.fromRGB(255,255,255)
title.Font = Enum.Font.GothamBold
title.TextSize = 20
title.Parent = mainFrame

local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.new(1, -10, 1, -50)
scroll.Position = UDim2.new(0, 5, 0, 45)
scroll.BackgroundTransparency = 1
scroll.CanvasSize = UDim2.new(0, 0, 0, 900)
scroll.ScrollBarThickness = 8
scroll.Parent = mainFrame

local function createToggle(name, stateKey, callback)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 30)
    frame.Position = UDim2.new(0, 0, 0, scroll.CanvasSize.Y.Offset)
    frame.BackgroundTransparency = 1
    frame.Parent = scroll

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.7, 0, 1, 0)
    label.Position = UDim2.new(0, 0, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = name
    label.TextColor3 = Color3.fromRGB(220,220,220)
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Font = Enum.Font.Gotham
    label.TextSize = 16
    label.Parent = frame

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.25, 0, 1, 0)
    btn.Position = UDim2.new(0.75, 0, 0, 0)
    btn.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
    btn.Text = "OFF"
    btn.TextColor3 = Color3.fromRGB(255,255,255)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 14
    btn.Parent = frame

    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 6)
    btnCorner.Parent = btn

    btn.MouseButton1Click:Connect(function()
        State[stateKey] = not State[stateKey]
        btn.BackgroundColor3 = State[stateKey] and Color3.fromRGB(0, 200, 80) or Color3.fromRGB(80, 80, 80)
        btn.Text = State[stateKey] and "ON" or "OFF"
        if callback then callback(State[stateKey]) end
    end)

    scroll.CanvasSize = UDim2.new(0, 0, 0, scroll.CanvasSize.Y.Offset + 35)
    return frame
end

local function createSlider(name, stateKey, min, max, default, callback)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 40)
    frame.Position = UDim2.new(0, 0, 0, scroll.CanvasSize.Y.Offset)
    frame.BackgroundTransparency = 1
    frame.Parent = scroll

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.6, 0, 0, 20)
    label.Position = UDim2.new(0, 0, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = name .. ": " .. tostring(default)
    label.TextColor3 = Color3.fromRGB(220,220,220)
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Font = Enum.Font.Gotham
    label.TextSize = 14
    label.Parent = frame

    local slider = Instance.new("TextButton")
    slider.Size = UDim2.new(0.3, 0, 0, 20)
    slider.Position = UDim2.new(0.65, 0, 0, 0)
    slider.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
    slider.Text = tostring(default)
    slider.TextColor3 = Color3.fromRGB(255,255,255)
    slider.Font = Enum.Font.GothamBold
    slider.TextSize = 14
    slider.Parent = frame

    local function updateValue(delta)
        local current = tonumber(slider.Text) or default
        local newVal = math.clamp(current + delta, min, max)
        slider.Text = tostring(newVal)
        State[stateKey] = newVal
        label.Text = name .. ": " .. tostring(newVal)
        if callback then callback(newVal) end
    end

    slider.MouseButton1Click:Connect(function()
        updateValue(1)
    end)
    slider.MouseButton2Click:Connect(function()
        updateValue(-1)
    end)

    scroll.CanvasSize = UDim2.new(0, 0, 0, scroll.CanvasSize.Y.Offset + 45)
    return frame
end

local function createButton(name, callback)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 35)
    frame.Position = UDim2.new(0, 0, 0, scroll.CanvasSize.Y.Offset)
    frame.BackgroundTransparency = 1
    frame.Parent = scroll

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.8, 0, 1, 0)
    btn.Position = UDim2.new(0.1, 0, 0, 0)
    btn.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
    btn.Text = name
    btn.TextColor3 = Color3.fromRGB(255,255,255)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 16
    btn.Parent = frame

    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 8)
    btnCorner.Parent = btn

    btn.MouseButton1Click:Connect(callback)

    scroll.CanvasSize = UDim2.new(0, 0, 0, scroll.CanvasSize.Y.Offset + 40)
    return frame
end

-- ================================================================
--  ПОСТРОЕНИЕ UI
-- ================================================================
createToggle("ESP", "ESP", function(v) if not v then clearESP() end end)
createToggle("Aimbot", "Aimbot", function(v) if v then startAimbot() else stopAimbot() end end)
createToggle("Fly (WASD+Space/Ctrl)", "Fly", function(v) if v then startFly() else stopFly() end end)
createSlider("Fly Speed", "FlySpeed", 10, 500, 80)
createToggle("NoClip", "Noclip")
createToggle("Speed Hack", "Speed", function() updateSpeed() end)
createSlider("Speed Value", "SpeedValue", 16, 500, 16, function() updateSpeed() end)
createToggle("God Mode", "GodMode", function(v) if v then startGodMode() else stopGodMode() end end)
createToggle("Infinite Jump", "InfiniteJump")
createToggle("Kill Aura", "KillAura", function(v) if v then startKillAura() else stopKillAura() end end)
createSlider("Kill Aura Radius", "KillAuraRadius", 5, 100, 30)
createToggle("Chop Aura", "ChopAura", function(v) if v then startChopAura() else stopChopAura() end end)
createToggle("Auto Farm Resources", "AutoFarm", function(v) if v then startAutoFarm() else stopAutoFarm() end end)
createToggle("Auto Cook", "AutoCook", function(v) if v then startAutoCook() else stopAutoCook() end end)
createToggle("Auto Upgrade Campfire", "AutoUpgradeCampfire", function(v) if v then startAutoUpgradeCampfire() else stopAutoUpgradeCampfire() end end)
createToggle("Auto Scrap", "AutoScrap", function(v) if v then startAutoScrap() else stopAutoScrap() end end)
createToggle("Auto Plant Saplings", "AutoPlant", function(v) if v then startAutoPlant() else stopAutoPlant() end end)
createToggle("Auto Rescue Kids", "AutoRescueKids", function(v) if v then startAutoRescueKids() else stopAutoRescueKids() end end)
createToggle("Auto Eat (hunger < 70%)", "AutoEat", function(v) if v then startAutoEat() else stopAutoEat() end end)
createToggle("Fullbright", "Fullbright")
createToggle("No Fog", "NoFog")
createToggle("Anti-AFK", "AntiAFK", function(v) if v then startAntiAFK() else stopAntiAFK() end end)

createButton("Teleport to Campfire", function() teleportTo("Campfire") end)
createButton("Teleport to Stronghold", function() teleportTo("Stronghold") end)
createButton("Teleport to Trader", function() teleportTo("Trader") end)
createButton("Teleport to Safe Zone", function() teleportTo("SafeZone") end)
createButton("Teleport to Nearest Kid", teleportToNearestKid)

createButton("Stop All", function()
    State.ESP = false; clearESP()
    State.Aimbot = false; stopAimbot()
    State.Fly = false; stopFly()
    State.Speed = false; updateSpeed()
    State.Noclip = false; updateNoclip()
    State.GodMode = false; stopGodMode()
    State.KillAura = false; stopKillAura()
    State.ChopAura = false; stopChopAura()
    State.AutoFarm = false; stopAutoFarm()
    State.AutoCook = false; stopAutoCook()
    State.AutoUpgradeCampfire = false; stopAutoUpgradeCampfire()
    State.AutoScrap = false; stopAutoScrap()
    State.AutoPlant = false; stopAutoPlant()
    State.AutoRescueKids = false; stopAutoRescueKids()
    State.AutoEat = false; stopAutoEat()
    State.Fullbright = false; toggleFullbright()
    State.NoFog = false; toggleNoFog()
    State.AntiAFK = false; stopAntiAFK()
    local hum = getHumanoid()
    if hum then hum.WalkSpeed = 16 end
    for _, child in pairs(scroll:GetChildren()) do
        if child:IsA("Frame") then
            local btn = child:FindFirstChildWhichIsA("TextButton")
            if btn and btn.Text == "ON" then
                btn.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
                btn.Text = "OFF"
            end
        end
    end
    StarterGui:SetCore("SendNotification", {
        Title = "Stopped",
        Text = "All functions disabled",
        Duration = 3,
    })
end)

-- ================================================================
--  ОПРЕДЕЛЕНИЕ ИГРЫ И ЗАПУСК
-- ================================================================
local placeId = game.PlaceId
local gameName = "Unknown"

-- Поддерживаемые игры (для 99 Nights используем реальный PlaceId)
local supportedGames = {
    [7326934954] = "99 Nights in the Forest",
    [79546208627805] = "99 Nights in the Forest (alt)", -- ваш реальный PlaceId
    [286090429] = "Arsenal",
    [6872265039] = "BedWars",
    [2753915549] = "Blox Fruits",
    [3260590327] = "Tower Defense Simulator",
    [142823291] = "Murder Mystery 2",
    [2933628366] = "Anime Fighting Simulator",
}

if supportedGames[placeId] then
    gameName = supportedGames[placeId]
else
    gameName = "Universal (not supported)"
end

title.Text = "ara_bara hub | " .. gameName

StarterGui:SetCore("SendNotification", {
    Title = "ara_bara hub",
    Text = "Loaded for: " .. gameName,
    Duration = 4,
})

print("✅ ara_bara hub loaded for:", gameName, "PlaceId:", placeId)
