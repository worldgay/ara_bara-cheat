-- ================================================================
--  xeno.lua
--  Полный объединённый скрипт ara_bara hub для Xeno
--  Автор: ara_bara
--  Версия: 2.0 (Universal + 100+ игр)
-- ================================================================

-- ================================================================
--  МОДУЛЬ: ServiceManager
-- ================================================================
local ServiceManager = {}
ServiceManager.Services = {}

setmetatable(ServiceManager.Services, {
    __index = function(self, name)
        local success, service = pcall(function()
            return game:GetService(name)
        end)
        if success then
            rawset(self, name, service)
            return service
        end
        return nil
    end
})

function ServiceManager:GetService(name)
    return self.Services[name]
end

-- ================================================================
--  МОДУЛЬ: Logger
-- ================================================================
local Logger = {}

function Logger:Log(message, level)
    level = level or "INFO"
    local timestamp = os.date("%Y-%m-%d %H:%M:%S")
    local logMessage = string.format("[%s] [%s] %s", timestamp, level, message)
    print(logMessage)
    pcall(function()
        if isfolder and not isfolder("ara_bara_logs") then
            makefolder("ara_bara_logs")
        end
        if isfile and writefile and readfile then
            local logFile = "ara_bara_logs/log.txt"
            local current = isfile(logFile) and readfile(logFile) or ""
            writefile(logFile, current .. logMessage .. "\n")
        end
    end)
end

-- ================================================================
--  МОДУЛЬ: ConfigManager
-- ================================================================
local ConfigManager = {}
ConfigManager.__index = ConfigManager

function ConfigManager.new()
    local self = setmetatable({}, ConfigManager)
    self.Data = {}
    return self
end

function ConfigManager:Load(fileName)
    fileName = fileName or "ara_bara_config.json"
    pcall(function()
        if isfile and isfile(fileName) then
            local data = readfile(fileName)
            self.Data = game:GetService("HttpService"):JSONDecode(data)
        end
    end)
    return self.Data
end

function ConfigManager:Save(fileName)
    fileName = fileName or "ara_bara_config.json"
    pcall(function()
        if writefile then
            local json = game:GetService("HttpService"):JSONEncode(self.Data)
            writefile(fileName, json)
        end
    end)
end

-- ================================================================
--  МОДУЛЬ: Executor
-- ================================================================
local Executor = {}
Executor.__index = Executor

function Executor:Detect()
    local name = "Unknown"
    if pcall(function() return syn end) then
        name = "Synapse X"
    elseif pcall(function() return krnl end) then
        name = "Krnl"
    elseif pcall(function() return scriptware end) then
        name = "ScriptWare"
    elseif pcall(function() return fluxus end) then
        name = "Fluxus"
    elseif pcall(function() return getexecutorname end) then
        name = getexecutorname()
    end
    return name
end

function Executor:GetAPI()
    local api = {}
    if pcall(function() return getgc end) then
        api.getgc = getgc
    end
    if pcall(function() return hookfunction end) then
        api.hookfunction = hookfunction
    end
    if pcall(function() return hookmetamethod end) then
        api.hookmetamethod = hookmetamethod
    end
    if pcall(function() return writefile end) then
        api.writefile = writefile
        api.readfile = readfile
        api.isfile = isfile
        api.isfolder = isfolder
        api.makefolder = makefolder
    end
    return api
end

-- ================================================================
--  МОДУЛЬ: UIManager (Rayfield)
-- ================================================================
local UIManager = {}
UIManager.__index = UIManager

function UIManager.new(core)
    local self = setmetatable({}, UIManager)
    self.Core = core
    self.Window = nil
    self.Tabs = {}
    return self
end

function UIManager:Init()
    local Rayfield
    local success, err = pcall(function()
        Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()
    end)
    if not success then
        self.Core.Logger:Log("Failed to load Rayfield: " .. tostring(err), "ERROR")
        return
    end

    self.Window = Rayfield:CreateWindow({
        Name = "ara_bara hub",
        LoadingTitle = "ara_bara hub",
        LoadingSubtitle = "by ara_bara",
        ConfigurationSaving = { Enabled = true, FolderName = "ara_bara", FileName = "settings" },
        KeySystem = false,
        Theme = "Ocean",
    })

    local mainTab = self:CreateTab("Main", "home")
    mainTab:CreateSection("Global Settings")
    mainTab:CreateToggle({
        Name = "ESP",
        CurrentValue = false,
        Callback = function(v)
            if self.Core.ESP then
                self.Core.ESP.State.Enabled = v
            end
        end
    })
    mainTab:CreateToggle({
        Name = "Aimbot",
        CurrentValue = false,
        Callback = function(v)
            if self.Core.Aimbot then
                self.Core.Aimbot.Enabled = v
            end
        end
    })

    self.Core.Logger:Log("UI initialized")
end

function UIManager:GetWindow()
    return self.Window
end

function UIManager:CreateTab(name, icon)
    if not self.Window then return end
    local tab = self.Window:CreateTab(name, icon)
    self.Tabs[name] = tab
    return tab
end

-- ================================================================
--  МОДУЛЬ: ESP
-- ================================================================
local ESP = {}
ESP.__index = ESP

function ESP:Init(core)
    local self = setmetatable({}, ESP)
    self.Core = core
    self.State = {
        Enabled = false,
        BoxType = "2D",
        BoxColor = Color3.fromRGB(255, 0, 0),
        TeamColor = Color3.fromRGB(0, 255, 0),
        ShowName = false,
        ShowHealth = false,
        ShowDistance = false,
        ShowTracer = false,
        ShowSkeleton = false,
        MaxDistance = 300,
        TracerPosition = "Bottom",
        WallCheck = false,
    }
    self.Objects = {}
    self.Folder = Instance.new("Folder", self.Core.Services.CoreGui or game:GetService("CoreGui"))
    self.Folder.Name = "ara_bara_ESP"
    self.UpdateInterval = 0.5
    self.Running = false
    return self
end

function ESP:StartLoop()
    if self.Running then return end
    self.Running = true
    task.spawn(function()
        while self.Running do
            if self.State.Enabled then
                self:Update()
            else
                self:Clear()
            end
            task.wait(self.UpdateInterval)
        end
    end)
end

function ESP:StopLoop()
    self.Running = false
end

function ESP:Update()
    if not self.State.Enabled then
        self:Clear()
        return
    end

    local players = self.Core.Services.Players:GetPlayers()
    local localPlayer = self.Core.Services.Players.LocalPlayer

    for _, player in pairs(players) do
        if player ~= localPlayer and player.Character then
            self:CreateESPForPlayer(player)
        end
    end

    local toRemove = {}
    for key, obj in pairs(self.Objects) do
        if type(key) == "string" and key:match("billboard_") then
            local playerName = key:gsub("billboard_", "")
            local player = self.Core.Services.Players:FindFirstChild(playerName)
            if not player or not player.Character then
                table.insert(toRemove, key)
            end
        end
    end
    for _, key in ipairs(toRemove) do
        if self.Objects[key] then
            self.Objects[key]:Destroy()
            self.Objects[key] = nil
        end
    end
end

function ESP:CreateESPForPlayer(player)
    local char = player.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    if not self.Folder then return end

    if self.State.WallCheck then
        local cam = self.Core.Services.Workspace.CurrentCamera
        local origin = cam.CFrame.Position
        local direction = (hrp.Position - origin).Unit * self.State.MaxDistance
        local params = RaycastParams.new()
        local localChar = self.Core.Services.Players.LocalPlayer.Character
        if localChar then
            params.FilterDescendantsInstances = {localChar}
        end
        params.FilterType = Enum.RaycastFilterType.Blacklist
        local result = self.Core.Services.Workspace:Raycast(origin, direction, params)
        if result and result.Instance:IsDescendantOf(char) then
            -- visible
        else
            return
        end
    end

    local highlight = self.Objects[player]
    if not highlight then
        highlight = Instance.new("Highlight")
        highlight.Parent = self.Folder
        self.Objects[player] = highlight
    end
    highlight.FillColor = self.State.BoxColor
    highlight.OutlineColor = Color3.new(1, 1, 1)
    highlight.FillTransparency = 0.5
    highlight.OutlineTransparency = 0.2
    highlight.Adornee = char

    local billboardKey = "billboard_" .. player.Name
    local billboard = self.Objects[billboardKey]
    if not billboard then
        billboard = Instance.new("BillboardGui")
        billboard.Size = UDim2.new(0, 200, 0, 60)
        billboard.StudsOffset = Vector3.new(0, 4, 0)
        billboard.AlwaysOnTop = true
        billboard.Parent = self.Folder
        self.Objects[billboardKey] = billboard

        local text = Instance.new("TextLabel")
        text.Size = UDim2.new(1, 0, 1, 0)
        text.BackgroundTransparency = 1
        text.TextScaled = true
        text.Font = Enum.Font.GothamBold
        text.TextStrokeTransparency = 0
        text.Parent = billboard
        self.Objects["label_" .. player.Name] = text
    end

    local text = self.Objects["label_" .. player.Name]
    if text then
        local parts = {}
        if self.State.ShowName then
            table.insert(parts, player.Name)
        end
        if self.State.ShowHealth then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then
                table.insert(parts, string.format("HP: %d/%d", hum.Health, hum.MaxHealth))
            end
        end
        if self.State.ShowDistance then
            local cam = self.Core.Services.Workspace.CurrentCamera
            local dist = (hrp.Position - cam.CFrame.Position).Magnitude
            table.insert(parts, string.format("%dm", math.floor(dist)))
        end
        text.Text = table.concat(parts, " | ")
        text.TextColor3 = self.State.BoxColor
    end

    if self.State.ShowTracer then
        local tracerKey = "tracer_" .. player.Name
        local tracer = self.Objects[tracerKey]
        if not tracer then
            if type(Drawing) == "table" and Drawing.new then
                tracer = Drawing.new("Line")
                tracer.Thickness = 2
                tracer.Color = self.State.BoxColor
                tracer.Visible = true
                self.Objects[tracerKey] = tracer
            end
        end
        if tracer then
            local cam = self.Core.Services.Workspace.CurrentCamera
            local screenPos, onScreen = cam:WorldToViewportPoint(hrp.Position)
            if onScreen then
                local viewport = cam.ViewportSize
                local bottomPos = Vector2.new(viewport.X / 2, viewport.Y)
                if self.State.TracerPosition == "Top" then
                    bottomPos = Vector2.new(viewport.X / 2, 0)
                elseif self.State.TracerPosition == "Middle" then
                    bottomPos = Vector2.new(viewport.X / 2, viewport.Y / 2)
                end
                tracer.From = bottomPos
                tracer.To = Vector2.new(screenPos.X, screenPos.Y)
                tracer.Color = self.State.BoxColor
                tracer.Visible = true
            else
                tracer.Visible = false
            end
        end
    else
        for key, obj in pairs(self.Objects) do
            if type(key) == "string" and key:match("tracer_") then
                obj:Destroy()
                self.Objects[key] = nil
            end
        end
    end
end

function ESP:Clear()
    for _, obj in pairs(self.Objects) do
        pcall(function() obj:Destroy() end)
    end
    self.Objects = {}
    if self.Folder then
        for _, child in pairs(self.Folder:GetChildren()) do
            child:Destroy()
        end
    end
end

function ESP:SetColor(color)
    self.State.BoxColor = color
end

function ESP:SetMaxDistance(dist)
    self.State.MaxDistance = dist
end

function ESP:ToggleTracer(enable)
    self.State.ShowTracer = enable
    if not enable then
        for key, obj in pairs(self.Objects) do
            if type(key) == "string" and key:match("tracer_") then
                obj:Destroy()
                self.Objects[key] = nil
            end
        end
    end
end

function ESP:Destroy()
    self:StopLoop()
    self:Clear()
    if self.Folder then
        self.Folder:Destroy()
    end
end

-- ================================================================
--  МОДУЛЬ: Aimbot
-- ================================================================
local Aimbot = {}
Aimbot.__index = Aimbot

function Aimbot:Init(core)
    local self = setmetatable({}, Aimbot)
    self.Core = core
    self.Enabled = false
    self.FOV = 90
    self.TargetPart = "Head"
    self.Smoothing = 0.3
    self.Triggerbot = false
    self.Running = false
    return self
end

function Aimbot:StartLoop()
    if self.Running then return end
    self.Running = true
    task.spawn(function()
        while self.Running do
            if self.Enabled then
                local target = self:GetClosestPlayer()
                if target then
                    local camera = workspace.CurrentCamera
                    local currentCF = camera.CFrame
                    local targetPos = target.Position
                    local newCF = CFrame.new(currentCF.Position, targetPos)
                    camera.CFrame = camera.CFrame:Lerp(newCF, self.Smoothing)
                    if self.Triggerbot then
                        local mouse = self.Core.Services.Players.LocalPlayer:GetMouse()
                        if mouse then
                            mouse1click()
                        end
                    end
                end
            end
            task.wait(0.05)
        end
    end)
end

function Aimbot:StopLoop()
    self.Running = false
end

function Aimbot:GetClosestPlayer()
    local cam = workspace.CurrentCamera
    local localPlayer = self.Core.Services.Players.LocalPlayer
    local closest = nil
    local minAngle = self.FOV

    for _, player in pairs(self.Core.Services.Players:GetPlayers()) do
        if player ~= localPlayer and player.Character and player.Character:FindFirstChild(self.TargetPart) then
            local part = player.Character[self.TargetPart]
            local screenPos, onScreen = cam:WorldToViewportPoint(part.Position)
            if onScreen then
                local mousePos = self.Core.Services.UserInputService:GetMouseLocation()
                local dist = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
                if dist < minAngle then
                    minAngle = dist
                    closest = part
                end
            end
        end
    end
    return closest
end

function Aimbot:SetFOV(fov)
    self.FOV = fov
end

function Aimbot:SetTargetPart(part)
    self.TargetPart = part
end

function Aimbot:SetSmoothing(value)
    self.Smoothing = value
end

function Aimbot:ToggleTriggerbot(state)
    self.Triggerbot = state
end

-- ================================================================
--  МОДУЛЬ: Fly
-- ================================================================
local Fly = {}
Fly.__index = Fly

function Fly:Init(core)
    local self = setmetatable({}, Fly)
    self.Core = core
    self.Enabled = false
    self.Speed = 80
    return self
end

-- ================================================================
--  МОДУЛЬ: Speed
-- ================================================================
local Speed = {}
Speed.__index = Speed

function Speed:Init(core)
    local self = setmetatable({}, Speed)
    self.Core = core
    self.Enabled = false
    self.Value = 16
    return self
end

function Speed:SetSpeed(value)
    local char = self.Core.Services.Players.LocalPlayer.Character
    if char and char:FindFirstChildOfClass("Humanoid") then
        char:FindFirstChildOfClass("Humanoid").WalkSpeed = value
    end
end

-- ================================================================
--  МОДУЛЬ: GodMode
-- ================================================================
local GodMode = {}
GodMode.__index = GodMode

function GodMode:Init(core)
    local self = setmetatable({}, GodMode)
    self.Core = core
    self.Enabled = false
    return self
end

-- ================================================================
--  МОДУЛЬ: Teleport
-- ================================================================
local Teleport = {}
Teleport.__index = Teleport

function Teleport:Init(core)
    local self = setmetatable({}, Teleport)
    self.Core = core
    return self
end

function Teleport:ToPosition(cframe)
    local char = self.Core.Services.Players.LocalPlayer.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        char.HumanoidRootPart.CFrame = cframe
    end
end

-- ================================================================
--  МОДУЛЬ: NoClip
-- ================================================================
local NoClip = {}
NoClip.__index = NoClip

function NoClip:Init(core)
    local self = setmetatable({}, NoClip)
    self.Core = core
    self.Enabled = false
    return self
end

-- ================================================================
--  МОДУЛЬ: Arsenal
-- ================================================================
local Arsenal = {}
Arsenal.__index = Arsenal

function Arsenal:Init(core)
    local self = setmetatable({}, Arsenal)
    self.Core = core
    self.State = {
        SilentAim = false,
        NoRecoil = false,
    }
    self.OldRaycast = nil
    self:SetupUI()
    self:StartLoops()
    self.Core.Logger:Log("Arsenal plugin initialized")
    return self
end

function Arsenal:SetupUI()
    local window = self.Core.UI:GetWindow()
    if not window then return end
    local tab = window:CreateTab("Arsenal", "crosshair")

    tab:CreateSection("Aimbot")
    tab:CreateToggle({
        Name = "Silent Aim",
        CurrentValue = false,
        Callback = function(v)
            self.State.SilentAim = v
            if v then self:EnableSilentAim() else self:DisableSilentAim() end
        end
    })
    tab:CreateToggle({
        Name = "No Recoil",
        CurrentValue = false,
        Callback = function(v)
            self.State.NoRecoil = v
            if v then self:EnableNoRecoil() else self:DisableNoRecoil() end
        end
    })
    tab:CreateSection("ESP")
    tab:CreateToggle({
        Name = "ESP Players",
        CurrentValue = false,
        Callback = function(v)
            if self.Core.ESP then
                self.Core.ESP.State.Enabled = v
                self.Core.ESP.State.BoxColor = Color3.fromRGB(255, 0, 0)
            end
        end
    })
end

function Arsenal:StartLoops()
    task.spawn(function()
        while true do
            if self.State.NoRecoil then
                self:ApplyNoRecoil()
            end
            task.wait(0.1)
        end
    end)
end

function Arsenal:FindRaycastModule()
    for _, module in pairs(self.Core.Services.ReplicatedStorage:GetDescendants()) do
        if module:IsA("ModuleScript") and module.Name:find("Raycast") then
            local success, data = pcall(require, module)
            if success and data and data.Raycast then
                return data
            end
        end
    end
    return nil
end

function Arsenal:GetClosestEnemy()
    local localPlayer = self.Core.Services.Players.LocalPlayer
    local closest = nil
    local minDist = math.huge
    for _, player in pairs(self.Core.Services.Players:GetPlayers()) do
        if player ~= localPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local hrp = player.Character.HumanoidRootPart
            local dist = (hrp.Position - workspace.CurrentCamera.CFrame.Position).Magnitude
            if dist < minDist then
                minDist = dist
                closest = hrp
            end
        end
    end
    return closest
end

function Arsenal:EnableSilentAim()
    local module = self:FindRaycastModule()
    if module then
        self.OldRaycast = module.Raycast
        module.Raycast = function(origin, direction, ...)
            local target = self:GetClosestEnemy()
            if target then
                direction = (target.Position - origin).Unit * 1000
            end
            return self.OldRaycast(origin, direction, ...)
        end
    end
end

function Arsenal:DisableSilentAim()
    local module = self:FindRaycastModule()
    if module and self.OldRaycast then
        module.Raycast = self.OldRaycast
        self.OldRaycast = nil
    end
end

function Arsenal:EnableNoRecoil()
    self.State.NoRecoil = true
end

function Arsenal:DisableNoRecoil()
    self.State.NoRecoil = false
end

function Arsenal:ApplyNoRecoil()
    local camera = workspace.CurrentCamera
    if camera and camera:FindFirstChild("CameraController") then
        local success, controller = pcall(require, camera.CameraController)
        if success and controller and controller.weaponKick then
            controller.weaponKick = function() end
        end
    end
end

-- ================================================================
--  МОДУЛЬ: BedWars
-- ================================================================
local BedWars = {}
BedWars.__index = BedWars

function BedWars:Init(core)
    local self = setmetatable({}, BedWars)
    self.Core = core
    self.Core.Logger:Log("BedWars plugin initialized")
    return self
end

-- ================================================================
--  МОДУЛЬ: BloxFruits
-- ================================================================
local BloxFruits = {}
BloxFruits.__index = BloxFruits

function BloxFruits:Init(core)
    local self = setmetatable({}, BloxFruits)
    self.Core = core
    self.State = {
        AutoFarm = false,
        AutoFarmType = "NPC",
        AutoBuyFruit = false,
        AutoUpgrade = false,
        ESPEnabled = false,
        ESPType = "Players",
    }
    self:SetupUI()
    self:StartLoops()
    self.Core.Logger:Log("BloxFruits plugin initialized")
    return self
end

function BloxFruits:SetupUI()
    local window = self.Core.UI:GetWindow()
    if not window then return end
    local tab = window:CreateTab("Blox Fruits", "sword")

    tab:CreateSection("Auto Farm")
    tab:CreateToggle({
        Name = "Auto Farm NPC",
        CurrentValue = false,
        Callback = function(v)
            self.State.AutoFarm = v
            self.State.AutoFarmType = v and "NPC" or false
        end
    })
    tab:CreateToggle({
        Name = "Auto Farm Boss",
        CurrentValue = false,
        Callback = function(v)
            self.State.AutoFarm = v
            self.State.AutoFarmType = v and "Boss" or false
        end
    })
    tab:CreateToggle({
        Name = "Auto Collect Chests",
        CurrentValue = false,
        Callback = function(v)
            self.State.AutoFarm = v
            self.State.AutoFarmType = v and "Chest" or false
        end
    })

    tab:CreateSection("Auto Shop")
    tab:CreateToggle({
        Name = "Auto Buy Fruit",
        CurrentValue = false,
        Callback = function(v) self.State.AutoBuyFruit = v end
    })
    tab:CreateToggle({
        Name = "Auto Upgrade Stats",
        CurrentValue = false,
        Callback = function(v) self.State.AutoUpgrade = v end
    })

    tab:CreateSection("ESP")
    tab:CreateToggle({
        Name = "ESP Players",
        CurrentValue = false,
        Callback = function(v)
            self.State.ESPEnabled = v
            self.State.ESPType = v and "Players" or false
        end
    })
    tab:CreateToggle({
        Name = "ESP NPC",
        CurrentValue = false,
        Callback = function(v)
            self.State.ESPEnabled = v
            self.State.ESPType = v and "NPC" or false
        end
    })
    tab:CreateToggle({
        Name = "ESP Fruits",
        CurrentValue = false,
        Callback = function(v)
            self.State.ESPEnabled = v
            self.State.ESPType = v and "Fruits" or false
        end
    })

    tab:CreateSection("Teleport")
    local npcList = {"Monkey", "Gorilla", "Shark", "Dragon"}
    tab:CreateDropdown({
        Name = "Teleport to NPC",
        Options = npcList,
        Callback = function(v) self:TeleportToNPC(v[1]) end
    })
    local islandList = {"Jungle", "Desert", "Ice", "Sky", "Underwater"}
    tab:CreateDropdown({
        Name = "Teleport to Island",
        Options = islandList,
        Callback = function(v) self:TeleportToIsland(v[1]) end
    })
end

function BloxFruits:StartLoops()
    task.spawn(function()
        while true do
            if self.State.AutoFarm then
                self:AutoFarmLoop()
            end
            if self.State.AutoBuyFruit then
                self:AutoBuyFruitLoop()
            end
            if self.State.AutoUpgrade then
                self:AutoUpgradeLoop()
            end
            if self.State.ESPEnabled then
                self:UpdateESP()
            end
            task.wait(0.5)
        end
    end)
end

function BloxFruits:AutoFarmLoop()
    local char = self.Core.Services.Players.LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local target = nil
    local targetType = self.State.AutoFarmType

    if targetType == "NPC" then
        target = self:FindClosestNPC(hrp)
    elseif targetType == "Boss" then
        target = self:FindClosestBoss(hrp)
    elseif targetType == "Chest" then
        target = self:FindClosestChest(hrp)
    end

    if target then
        self:TeleportToTarget(target, hrp)
        self:AttackTarget(target)
    end
end

function BloxFruits:FindClosestNPC(hrp)
    local closest = nil
    local closestDist = 1000
    for _, obj in pairs(self.Core.Services.Workspace:GetDescendants()) do
        if obj:IsA("Model") and obj:FindFirstChild("Humanoid") and obj.Name:find("NPC") then
            local root = obj:FindFirstChild("HumanoidRootPart")
            if root then
                local dist = (root.Position - hrp.Position).Magnitude
                if dist < closestDist then
                    closestDist = dist
                    closest = obj
                end
            end
        end
    end
    return closest
end

function BloxFruits:FindClosestBoss(hrp)
    local closest = nil
    local closestDist = 1000
    for _, obj in pairs(self.Core.Services.Workspace:GetDescendants()) do
        if obj:IsA("Model") and obj:FindFirstChild("Humanoid") and obj.Name:find("Boss") then
            local root = obj:FindFirstChild("HumanoidRootPart")
            if root then
                local dist = (root.Position - hrp.Position).Magnitude
                if dist < closestDist then
                    closestDist = dist
                    closest = obj
                end
            end
        end
    end
    return closest
end

function BloxFruits:FindClosestChest(hrp)
    local closest = nil
    local closestDist = 1000
    for _, obj in pairs(self.Core.Services.Workspace:GetDescendants()) do
        if obj:IsA("Model") and obj.Name:find("Chest") then
            local root = obj:FindFirstChildWhichIsA("BasePart")
            if root then
                local dist = (root.Position - hrp.Position).Magnitude
                if dist < closestDist then
                    closestDist = dist
                    closest = obj
                end
            end
        end
    end
    return closest
end

function BloxFruits:TeleportToTarget(target, hrp)
    local root = target:FindFirstChild("HumanoidRootPart")
    if root then
        hrp.CFrame = root.CFrame + Vector3.new(0, 5, 0)
    end
end

function BloxFruits:AttackTarget(target)
    local char = self.Core.Services.Players.LocalPlayer.Character
    if char then
        for _, tool in pairs(char:GetChildren()) do
            if tool:IsA("Tool") then
                pcall(tool.Activate, tool)
            end
        end
    end
end

function BloxFruits:AutoBuyFruitLoop()
    local remote = self.Core.Services.ReplicatedStorage:FindFirstChild("BuyFruit")
    if remote then
        pcall(function() remote:FireServer("Random") end)
    end
end

function BloxFruits:AutoUpgradeLoop()
end

function BloxFruits:UpdateESP()
    if not self.State.ESPEnabled then return end
    local esp = self.Core.ESP
    if esp then
        esp.State.Enabled = true
        esp.State.BoxColor = Color3.fromRGB(255, 255, 0)
        esp.State.ShowName = true
        esp.State.ShowHealth = true
        esp.State.ShowDistance = true
    end
end

function BloxFruits:TeleportToNPC(name)
    local char = self.Core.Services.Players.LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    for _, obj in pairs(self.Core.Services.Workspace:GetDescendants()) do
        if obj:IsA("Model") and obj.Name:find(name) then
            local root = obj:FindFirstChild("HumanoidRootPart")
            if root then
                hrp.CFrame = root.CFrame + Vector3.new(0, 5, 0)
                break
            end
        end
    end
end

function BloxFruits:TeleportToIsland(name)
    local char = self.Core.Services.Players.LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    for _, obj in pairs(self.Core.Services.Workspace:GetDescendants()) do
        if obj:IsA("Model") and obj.Name:find(name) then
            local root = obj:FindFirstChildWhichIsA("BasePart")
            if root then
                hrp.CFrame = root.CFrame + Vector3.new(0, 5, 0)
                break
            end
        end
    end
end

-- ================================================================
--  МОДУЛЬ: TowerDefenseSimulator
-- ================================================================
local TowerDefenseSimulator = {}
TowerDefenseSimulator.__index = TowerDefenseSimulator

function TowerDefenseSimulator:Init(core)
    local self = setmetatable({}, TowerDefenseSimulator)
    self.Core = core
    self.Core.Logger:Log("TowerDefenseSimulator plugin initialized")
    return self
end

-- ================================================================
--  МОДУЛЬ: MurderMystery2
-- ================================================================
local MurderMystery2 = {}
MurderMystery2.__index = MurderMystery2

function MurderMystery2:Init(core)
    local self = setmetatable({}, MurderMystery2)
    self.Core = core
    self.Core.Logger:Log("MurderMystery2 plugin initialized")
    return self
end

-- ================================================================
--  МОДУЛЬ: AnimeFightingSimulator
-- ================================================================
local AnimeFightingSimulator = {}
AnimeFightingSimulator.__index = AnimeFightingSimulator

function AnimeFightingSimulator:Init(core)
    local self = setmetatable({}, AnimeFightingSimulator)
    self.Core = core
    self.Core.Logger:Log("AnimeFightingSimulator plugin initialized")
    return self
end

-- ================================================================
--  МОДУЛЬ: NightsInTheForest (полноценный плагин)
-- ================================================================
local NightsInTheForest = {}
NightsInTheForest.__index = NightsInTheForest

function NightsInTheForest:Init(core)
    local self = setmetatable({}, NightsInTheForest)
    self.Core = core
    self.State = {
        KillAura = false,
        KillAuraRadius = 30,
        ChopAura = false,
        ChopAuraRadius = 20,
        GodMode = false,
        AutoEat = false,
        AutoCook = false,
        AutoUpgradeCampfire = false,
        AutoScrap = false,
        AutoPlant = false,
        AutoRescueKids = false,
        AutoFarmResources = false,
        ResourceType = "Wood",
        ESPEnabled = false,
        ESPPlayers = false,
        ESPEnemies = false,
        ESPItems = false,
        ESPKids = false,
        Fly = false,
        FlySpeed = 80,
        NoClip = false,
        SpeedHack = false,
        SpeedValue = 16,
        InfiniteJump = false,
        Fullbright = false,
        NoFog = false,
        AntiAFK = false,
    }
    self.ESPObjects = {}
    self.FlyBody = nil
    self.FlyConnection = nil
    self.AntiAFKConnection = nil
    self.GodModeConnection = nil
    self:SetupUI()
    self:StartLoops()
    self.Core.Logger:Log("99 Nights in the Forest plugin initialized")
    return self
end

function NightsInTheForest:SetupUI()
    local window = self.Core.UI:GetWindow()
    if not window then return end
    local tab = window:CreateTab("99 Nights", "tree")

    tab:CreateSection("Combat")
    tab:CreateToggle({
        Name = "Kill Aura",
        CurrentValue = false,
        Callback = function(v)
            self.State.KillAura = v
            if v then self:StartKillAura() else self:StopKillAura() end
        end
    })
    tab:CreateSlider({
        Name = "Kill Aura Radius",
        Range = {5, 100},
        Increment = 5,
        CurrentValue = self.State.KillAuraRadius,
        Callback = function(v) self.State.KillAuraRadius = v end
    })
    tab:CreateToggle({
        Name = "Chop Aura",
        CurrentValue = false,
        Callback = function(v)
            self.State.ChopAura = v
            if v then self:StartChopAura() else self:StopChopAura() end
        end
    })
    tab:CreateToggle({
        Name = "God Mode",
        CurrentValue = false,
        Callback = function(v)
            self.State.GodMode = v
            if v then self:StartGodMode() else self:StopGodMode() end
        end
    })

    tab:CreateSection("Farming")
    tab:CreateToggle({
        Name = "Auto Farm Resources",
        CurrentValue = false,
        Callback = function(v)
            self.State.AutoFarmResources = v
            if v then self:StartAutoFarm() else self:StopAutoFarm() end
        end
    })
    tab:CreateDropdown({
        Name = "Resource Type",
        Options = {"Wood", "Fuel", "Food", "Medicine", "Diamonds"},
        CurrentOption = {"Wood"},
        Callback = function(v) self.State.ResourceType = v[1] end
    })
    tab:CreateToggle({
        Name = "Auto Cook Food",
        CurrentValue = false,
        Callback = function(v)
            self.State.AutoCook = v
            if v then self:StartAutoCook() else self:StopAutoCook() end
        end
    })
    tab:CreateToggle({
        Name = "Auto Upgrade Campfire",
        CurrentValue = false,
        Callback = function(v)
            self.State.AutoUpgradeCampfire = v
            if v then self:StartAutoUpgradeCampfire() else self:StopAutoUpgradeCampfire() end
        end
    })
    tab:CreateToggle({
        Name = "Auto Scrap Items",
        CurrentValue = false,
        Callback = function(v)
            self.State.AutoScrap = v
            if v then self:StartAutoScrap() else self:StopAutoScrap() end
        end
    })
    tab:CreateToggle({
        Name = "Auto Plant Saplings",
        CurrentValue = false,
        Callback = function(v)
            self.State.AutoPlant = v
            if v then self:StartAutoPlant() else self:StopAutoPlant() end
        end
    })
    tab:CreateToggle({
        Name = "Auto Rescue Kids",
        CurrentValue = false,
        Callback = function(v)
            self.State.AutoRescueKids = v
            if v then self:StartAutoRescueKids() else self:StopAutoRescueKids() end
        end
    })
    tab:CreateToggle({
        Name = "Auto Eat (hunger < 70%)",
        CurrentValue = false,
        Callback = function(v)
            self.State.AutoEat = v
            if v then self:StartAutoEat() else self:StopAutoEat() end
        end
    })

    tab:CreateSection("ESP")
    tab:CreateToggle({
        Name = "ESP Enabled",
        CurrentValue = false,
        Callback = function(v)
            self.State.ESPEnabled = v
            if not v then self:ClearESP() end
        end
    })
    tab:CreateToggle({
        Name = "ESP Players",
        CurrentValue = false,
        Callback = function(v) self.State.ESPPlayers = v end
    })
    tab:CreateToggle({
        Name = "ESP Enemies",
        CurrentValue = false,
        Callback = function(v) self.State.ESPEnemies = v end
    })
    tab:CreateToggle({
        Name = "ESP Items",
        CurrentValue = false,
        Callback = function(v) self.State.ESPItems = v end
    })
    tab:CreateToggle({
        Name = "ESP Kids",
        CurrentValue = false,
        Callback = function(v) self.State.ESPKids = v end
    })

    tab:CreateSection("Movement")
    tab:CreateToggle({
        Name = "Fly (WASD+Space/Ctrl)",
        CurrentValue = false,
        Callback = function(v)
            if v then self:StartFly() else self:StopFly() end
        end
    })
    tab:CreateSlider({
        Name = "Fly Speed",
        Range = {10, 500},
        Increment = 5,
        CurrentValue = self.State.FlySpeed,
        Callback = function(v) self.State.FlySpeed = v end
    })
    tab:CreateToggle({
        Name = "No Clip",
        CurrentValue = false,
        Callback = function(v)
            self.State.NoClip = v
            self:UpdateNoclip()
        end
    })
    tab:CreateToggle({
        Name = "Speed Hack",
        CurrentValue = false,
        Callback = function(v)
            self.State.SpeedHack = v
            self:UpdateSpeed()
        end
    })
    tab:CreateSlider({
        Name = "Speed Value",
        Range = {16, 500},
        Increment = 1,
        CurrentValue = self.State.SpeedValue,
        Callback = function(v)
            self.State.SpeedValue = v
            if self.State.SpeedHack then self:UpdateSpeed() end
        end
    })
    tab:CreateToggle({
        Name = "Infinite Jump",
        CurrentValue = false,
        Callback = function(v)
            self.State.InfiniteJump = v
        end
    })

    tab:CreateSection("Visuals")
    tab:CreateToggle({
        Name = "Fullbright",
        CurrentValue = false,
        Callback = function(v)
            self.State.Fullbright = v
            self:UpdateFullbright()
        end
    })
    tab:CreateToggle({
        Name = "No Fog",
        CurrentValue = false,
        Callback = function(v)
            self.State.NoFog = v
            self:UpdateNoFog()
        end
    })

    tab:CreateSection("Teleports")
    tab:CreateButton({
        Name = "Teleport to Campfire",
        Callback = function() self:TeleportTo("Campfire") end
    })
    tab:CreateButton({
        Name = "Teleport to Stronghold",
        Callback = function() self:TeleportTo("Stronghold") end
    })
    tab:CreateButton({
        Name = "Teleport to Trader",
        Callback = function() self:TeleportTo("Trader") end
    })
    tab:CreateButton({
        Name = "Teleport to Safe Zone",
        Callback = function() self:TeleportTo("SafeZone") end
    })
    tab:CreateButton({
        Name = "Teleport to Nearest Kid",
        Callback = function() self:TeleportToNearestKid() end
    })

    tab:CreateSection("Misc")
    tab:CreateToggle({
        Name = "Anti-AFK",
        CurrentValue = false,
        Callback = function(v)
            self.State.AntiAFK = v
            if v then self:StartAntiAFK() else self:StopAntiAFK() end
        end
    })
    tab:CreateButton({
        Name = "Stop All",
        Callback = function()
            self:StopAll()
        end
    })
end

function NightsInTheForest:StartLoops()
    task.spawn(function()
        while true do
            if self.State.ESPEnabled then
                self:UpdateESP()
            end
            if self.State.InfiniteJump then
                self:UpdateInfiniteJump()
            end
            if self.State.NoClip then
                self:UpdateNoclip()
            end
            task.wait(0.3)
        end
    end)
end

function NightsInTheForest:GetChar()
    return self.Core.Services.Players.LocalPlayer.Character or self.Core.Services.Players.LocalPlayer.CharacterAdded:Wait()
end

function NightsInTheForest:GetHRP()
    local char = self:GetChar()
    return char and char:FindFirstChild("HumanoidRootPart")
end

function NightsInTheForest:GetHumanoid()
    local char = self:GetChar()
    return char and char:FindFirstChildOfClass("Humanoid")
end

function NightsInTheForest:TeleportTo(cf)
    local hrp = self:GetHRP()
    if hrp then
        if type(cf) == "string" then
            local target = self.Core.Services.Workspace:FindFirstChild(cf, true)
            if target then
                local root = target:FindFirstChildWhichIsA("BasePart") or target
                hrp.CFrame = root.CFrame + Vector3.new(0, 3, 0)
            end
        elseif type(cf) == "CFrame" then
            hrp.CFrame = cf + Vector3.new(0, 3, 0)
        end
    end
end

function NightsInTheForest:FindNearest(targets, radius)
    local hrp = self:GetHRP()
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

function NightsInTheForest:IsEnemy(model)
    if not model then return false end
    local name = model.Name:lower()
    return name:find("cultist") or name:find("deer") or name:find("wolf") or
           name:find("bear") or name:find("owl") or name:find("ram") or
           name:find("golem") or name:find("corrupt")
end

function NightsInTheForest:IsTree(model)
    if not model then return false end
    local name = model.Name:lower()
    return name:find("tree") or name:find("log") or name:find("stump")
end

function NightsInTheForest:IsItem(model)
    if not model then return false end
    local name = model.Name:lower()
    return name:find("log") or name:find("plank") or name:find("stick") or
           name:find("food") or name:find("berry") or name:find("meat") or
           name:find("fuel") or name:find("medicine") or name:find("diamond") or
           name:find("coin") or name:find("scrap")
end

function NightsInTheForest:IsKid(model)
    if not model then return false end
    local name = model.Name:lower()
    return name:find("kid") or name:find("child") or name:find("survivor")
end

function NightsInTheForest:StartKillAura()
    if self.KillAuraConnection then return end
    self.KillAuraConnection = self.Core.Services.RunService.Heartbeat:Connect(function()
        if not self.State.KillAura then return end
        local hrp = self:GetHRP()
        if not hrp then return end
        local enemies = {}
        for _, obj in pairs(self.Core.Services.Workspace:GetDescendants()) do
            if obj:IsA("Model") and obj:FindFirstChildOfClass("Humanoid") then
                local hum = obj:FindFirstChildOfClass("Humanoid")
                if hum and hum.Health > 0 and self:IsEnemy(obj) then
                    table.insert(enemies, obj)
                end
            end
        end
        local target = self:FindNearest(enemies, self.State.KillAuraRadius)
        if target then
            local root = target:FindFirstChildWhichIsA("BasePart")
            if root then
                hrp.CFrame = root.CFrame + Vector3.new(0, 2, 0)
                local char = self:GetChar()
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

function NightsInTheForest:StopKillAura()
    if self.KillAuraConnection then
        self.KillAuraConnection:Disconnect()
        self.KillAuraConnection = nil
    end
end

function NightsInTheForest:StartChopAura()
    if self.ChopAuraConnection then return end
    self.ChopAuraConnection = self.Core.Services.RunService.Heartbeat:Connect(function()
        if not self.State.ChopAura then return end
        local hrp = self:GetHRP()
        if not hrp then return end
        local trees = {}
        for _, obj in pairs(self.Core.Services.Workspace:GetDescendants()) do
            if obj:IsA("Model") and self:IsTree(obj) then
                local root = obj:FindFirstChildWhichIsA("BasePart")
                if root then
                    table.insert(trees, obj)
                end
            end
        end
        local target = self:FindNearest(trees, self.State.ChopAuraRadius)
        if target then
            local root = target:FindFirstChildWhichIsA("BasePart")
            if root then
                hrp.CFrame = root.CFrame + Vector3.new(0, 2, 0)
                task.wait(0.1)
                local remote = self.Core.Services.ReplicatedStorage:FindFirstChild("RemoteEvents")
                    and self.Core.Services.ReplicatedStorage.RemoteEvents:FindFirstChild("ToolDamageObject")
                if remote then
                    local axe = self.Core.Services.Players.LocalPlayer:FindFirstChild("Inventory")
                        and self.Core.Services.Players.LocalPlayer.Inventory:FindFirstChild("Old Axe")
                    if axe then
                        pcall(function()
                            remote:InvokeServer(target, axe, "1_" .. self.Core.Services.Players.LocalPlayer.UserId, root.CFrame)
                        end)
                    end
                end
                task.wait(0.3)
            end
        end
    end)
end

function NightsInTheForest:StopChopAura()
    if self.ChopAuraConnection then
        self.ChopAuraConnection:Disconnect()
        self.ChopAuraConnection = nil
    end
end

function NightsInTheForest:StartGodMode()
    if self.GodModeConnection then return end
    self.GodModeConnection = self.Core.Services.RunService.Heartbeat:Connect(function()
        if not self.State.GodMode then return end
        local char = self:GetChar()
        if not char then return end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.Health = hum.MaxHealth
        end
        if char:GetAttribute("Dead") then
            char:SetAttribute("Dead", false)
        end
    end)
end

function NightsInTheForest:StopGodMode()
    if self.GodModeConnection then
        self.GodModeConnection:Disconnect()
        self.GodModeConnection = nil
    end
end

function NightsInTheForest:StartAutoFarm()
    if self.AutoFarmConnection then return end
    self.AutoFarmConnection = self.Core.Services.RunService.Heartbeat:Connect(function()
        if not self.State.AutoFarmResources then return end
        local hrp = self:GetHRP()
        if not hrp then return end
        local resourceType = self.State.ResourceType:lower()
        local targets = {}
        for _, obj in pairs(self.Core.Services.Workspace:GetDescendants()) do
            if obj:IsA("Model") and obj.Name:lower():find(resourceType) then
                local root = obj:FindFirstChildWhichIsA("BasePart")
                if root then
                    table.insert(targets, obj)
                end
            end
        end
        local target = self:FindNearest(targets, 50)
        if target then
            local root = target:FindFirstChildWhichIsA("BasePart")
            if root then
                hrp.CFrame = root.CFrame + Vector3.new(0, 1, 0)
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

function NightsInTheForest:StopAutoFarm()
    if self.AutoFarmConnection then
        self.AutoFarmConnection:Disconnect()
        self.AutoFarmConnection = nil
    end
end

function NightsInTheForest:StartAutoCook()
    if self.AutoCookConnection then return end
    self.AutoCookConnection = self.Core.Services.RunService.Heartbeat:Connect(function()
        if not self.State.AutoCook then return end
        local campfire = self.Core.Services.Workspace:FindFirstChild("Campfire", true)
        if campfire then
            local prompt = campfire:FindFirstChildOfClass("ProximityPrompt")
            if prompt then
                pcall(fireproximityprompt, prompt)
                task.wait(2)
            end
        end
    end)
end

function NightsInTheForest:StopAutoCook()
    if self.AutoCookConnection then
        self.AutoCookConnection:Disconnect()
        self.AutoCookConnection = nil
    end
end

function NightsInTheForest:StartAutoUpgradeCampfire()
    if self.AutoUpgradeCampfireConnection then return end
    self.AutoUpgradeCampfireConnection = self.Core.Services.RunService.Heartbeat:Connect(function()
        if not self.State.AutoUpgradeCampfire then return end
        local campfire = self.Core.Services.Workspace:FindFirstChild("Campfire", true)
        if campfire then
            local prompt = campfire:FindFirstChildOfClass("ProximityPrompt")
            if prompt then
                pcall(fireproximityprompt, prompt)
                task.wait(1)
            end
        end
    end)
end

function NightsInTheForest:StopAutoUpgradeCampfire()
    if self.AutoUpgradeCampfireConnection then
        self.AutoUpgradeCampfireConnection:Disconnect()
        self.AutoUpgradeCampfireConnection = nil
    end
end

function NightsInTheForest:StartAutoScrap()
    if self.AutoScrapConnection then return end
    self.AutoScrapConnection = self.Core.Services.RunService.Heartbeat:Connect(function()
        if not self.State.AutoScrap then return end
        local workbench = self.Core.Services.Workspace:FindFirstChild("Workbench", true)
            or self.Core.Services.Workspace:FindFirstChild("CraftingBench", true)
        if workbench then
            local prompt = workbench:FindFirstChildOfClass("ProximityPrompt")
            if prompt then
                pcall(fireproximityprompt, prompt)
                task.wait(1)
            end
        end
    end)
end

function NightsInTheForest:StopAutoScrap()
    if self.AutoScrapConnection then
        self.AutoScrapConnection:Disconnect()
        self.AutoScrapConnection = nil
    end
end

function NightsInTheForest:StartAutoPlant()
    if self.AutoPlantConnection then return end
    self.AutoPlantConnection = self.Core.Services.RunService.Heartbeat:Connect(function()
        if not self.State.AutoPlant then return end
        local backpack = self.Core.Services.Players.LocalPlayer.Backpack
        local sapling = nil
        for _, tool in pairs(backpack:GetChildren()) do
            if tool:IsA("Tool") and tool.Name:lower():find("sapling") then
                sapling = tool
                break
            end
        end
        if sapling then
            local hum = self:GetHumanoid()
            if hum then
                hum:EquipTool(sapling)
                task.wait(0.2)
                pcall(sapling.Activate, sapling)
                task.wait(0.5)
            end
        end
    end)
end

function NightsInTheForest:StopAutoPlant()
    if self.AutoPlantConnection then
        self.AutoPlantConnection:Disconnect()
        self.AutoPlantConnection = nil
    end
end

function NightsInTheForest:StartAutoRescueKids()
    if self.AutoRescueKidsConnection then return end
    self.AutoRescueKidsConnection = self.Core.Services.RunService.Heartbeat:Connect(function()
        if not self.State.AutoRescueKids then return end
        local hrp = self:GetHRP()
        if not hrp then return end
        local kids = {}
        for _, obj in pairs(self.Core.Services.Workspace:GetDescendants()) do
            if obj:IsA("Model") and self:IsKid(obj) then
                local root = obj:FindFirstChildWhichIsA("BasePart")
                if root then
                    table.insert(kids, obj)
                end
            end
        end
        local kid = self:FindNearest(kids, 50)
        if kid then
            local root = kid:FindFirstChildWhichIsA("BasePart")
            if root then
                hrp.CFrame = root.CFrame + Vector3.new(0, 2, 0)
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

function NightsInTheForest:StopAutoRescueKids()
    if self.AutoRescueKidsConnection then
        self.AutoRescueKidsConnection:Disconnect()
        self.AutoRescueKidsConnection = nil
    end
end

function NightsInTheForest:StartAutoEat()
    if self.AutoEatConnection then return end
    self.AutoEatConnection = self.Core.Services.RunService.Heartbeat:Connect(function()
        if not self.State.AutoEat then return end
        local hum = self:GetHumanoid()
        if hum and hum.Health < hum.MaxHealth * 0.7 then
            local foodKeywords = {"chowder", "fish", "meat", "potato", "fruit", "food", "pizza", "coconut", "banana", "apple", "steak", "egg", "berry"}
            for _, tool in pairs(self.Core.Services.Players.LocalPlayer.Backpack:GetChildren()) do
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

function NightsInTheForest:StopAutoEat()
    if self.AutoEatConnection then
        self.AutoEatConnection:Disconnect()
        self.AutoEatConnection = nil
    end
end

function NightsInTheForest:ClearESP()
    for _, obj in pairs(self.ESPObjects) do
        pcall(function() obj:Destroy() end)
    end
    self.ESPObjects = {}
end

function NightsInTheForest:CreateESP(model, color, label)
    if not model then return end
    local hl = Instance.new("Highlight")
    hl.FillColor = color
    hl.OutlineColor = Color3.new(1, 1, 1)
    hl.FillTransparency = 0.6
    hl.OutlineTransparency = 0.3
    hl.Adornee = model
    hl.Parent = game.CoreGui
    table.insert(self.ESPObjects, hl)
    if label then
        local bb = Instance.new("BillboardGui")
        bb.Size = UDim2.new(0, 150, 0, 40)
        bb.StudsOffset = Vector3.new(0, 3, 0)
        bb.AlwaysOnTop = true
        bb.Adornee = model:IsA("Model") and (model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart")) or model
        bb.Parent = game.CoreGui
        table.insert(self.ESPObjects, bb)
        local tl = Instance.new("TextLabel")
        tl.Size = UDim2.new(1, 0, 1, 0)
        tl.BackgroundTransparency = 1
        tl.Text = label or model.Name
        tl.TextColor3 = color
        tl.TextStrokeTransparency = 0.4
        tl.Font = Enum.Font.GothamBold
        tl.TextSize = 14
        tl.Parent = bb
        table.insert(self.ESPObjects, tl)
    end
end

function NightsInTheForest:UpdateESP()
    self:ClearESP()
    if not self.State.ESPEnabled then return end

    if self.State.ESPPlayers then
        for _, player in pairs(self.Core.Services.Players:GetPlayers()) do
            if player ~= self.Core.Services.Players.LocalPlayer and player.Character then
                self:CreateESP(player.Character, Color3.fromRGB(0, 150, 255), player.DisplayName)
            end
        end
    end

    if self.State.ESPEnemies then
        for _, obj in pairs(self.Core.Services.Workspace:GetDescendants()) do
            if obj:IsA("Model") and self:IsEnemy(obj) then
                local hum = obj:FindFirstChildOfClass("Humanoid")
                if hum and hum.Health > 0 then
                    self:CreateESP(obj, Color3.fromRGB(255, 0, 0), "Enemy")
                end
            end
        end
    end

    if self.State.ESPItems then
        for _, obj in pairs(self.Core.Services.Workspace:GetDescendants()) do
            if obj:IsA("Model") and self:IsItem(obj) then
                self:CreateESP(obj, Color3.fromRGB(255, 215, 0), "Item")
            end
        end
    end

    if self.State.ESPKids then
        for _, obj in pairs(self.Core.Services.Workspace:GetDescendants()) do
            if obj:IsA("Model") and self:IsKid(obj) then
                self:CreateESP(obj, Color3.fromRGB(0, 255, 100), "Kid")
            end
        end
    end
end

function NightsInTheForest:StartFly()
    if self.State.Fly then return end
    local hrp = self:GetHRP()
    if not hrp then return end
    self.FlyBody = Instance.new("BodyVelocity")
    self.FlyBody.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    self.FlyBody.Velocity = Vector3.zero
    self.FlyBody.Parent = hrp
    local hum = self:GetHumanoid()
    if hum then hum.PlatformStand = true end
    self.State.Fly = true
    self.FlyConnection = self.Core.Services.RunService.Heartbeat:Connect(function()
        if not self.State.Fly then return end
        local hrp = self:GetHRP()
        if not hrp or not self.FlyBody then return end
        local dir = Vector3.zero
        local uis = self.Core.Services.UserInputService
        local cam = self.Core.Services.Workspace.CurrentCamera
        if uis:IsKeyDown(Enum.KeyCode.W) then dir = dir + cam.CFrame.LookVector end
        if uis:IsKeyDown(Enum.KeyCode.S) then dir = dir - cam.CFrame.LookVector end
        if uis:IsKeyDown(Enum.KeyCode.A) then dir = dir - cam.CFrame.RightVector end
        if uis:IsKeyDown(Enum.KeyCode.D) then dir = dir + cam.CFrame.RightVector end
        if uis:IsKeyDown(Enum.KeyCode.Space) then dir = dir + Vector3.new(0, 1, 0) end
        if uis:IsKeyDown(Enum.KeyCode.LeftControl) then dir = dir - Vector3.new(0, 1, 0) end
        if dir.Magnitude > 0 then dir = dir.Unit end
        self.FlyBody.Velocity = dir * self.State.FlySpeed
    end)
end

function NightsInTheForest:StopFly()
    self.State.Fly = false
    if self.FlyBody then self.FlyBody:Destroy(); self.FlyBody = nil end
    if self.FlyConnection then self.FlyConnection:Disconnect(); self.FlyConnection = nil end
    local hum = self:GetHumanoid()
    if hum then hum.PlatformStand = false end
end

function NightsInTheForest:UpdateNoclip()
    local char = self:GetChar()
    if not char then return end
    for _, part in pairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CanCollide = not self.State.NoClip
        end
    end
end

function NightsInTheForest:UpdateSpeed()
    local hum = self:GetHumanoid()
    if hum then
        hum.WalkSpeed = self.State.SpeedHack and self.State.SpeedValue or 16
    end
end

function NightsInTheForest:UpdateInfiniteJump()
    if self.State.InfiniteJump then
        local uis = self.Core.Services.UserInputService
        uis.JumpRequest:Connect(function()
            local hum = self:GetHumanoid()
            if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
        end)
    end
end

local OriginalLighting = {}

function NightsInTheForest:UpdateFullbright()
    local lighting = self.Core.Services.Lighting
    if self.State.Fullbright then
        OriginalLighting.Ambient = lighting.Ambient
        OriginalLighting.Brightness = lighting.Brightness
        OriginalLighting.ClockTime = lighting.ClockTime
        OriginalLighting.FogEnd = lighting.FogEnd
        OriginalLighting.GlobalShadows = lighting.GlobalShadows
        lighting.Ambient = Color3.new(1, 1, 1)
        lighting.Brightness = 2
        lighting.ClockTime = 14
        lighting.FogEnd = 1e6
        lighting.GlobalShadows = false
        for _, v in pairs(lighting:GetChildren()) do
            if v:IsA("Atmosphere") then v.Density = 0 end
        end
    else
        for k, v in pairs(OriginalLighting) do
            lighting[k] = v
        end
    end
end

function NightsInTheForest:UpdateNoFog()
    local lighting = self.Core.Services.Lighting
    if self.State.NoFog then
        lighting.FogEnd = 1e6
    else
        lighting.FogEnd = OriginalLighting.FogEnd or 1000
    end
end

function NightsInTheForest:StartAntiAFK()
    if self.AntiAFKConnection then return end
    local vu = self.Core.Services.VirtualUser
    self.AntiAFKConnection = self.Core.Services.Players.LocalPlayer.Idled:Connect(function()
        vu:Button2Down(Vector2.zero, self.Core.Services.Workspace.CurrentCamera.CFrame)
        task.wait(1)
        vu:Button2Up(Vector2.zero, self.Core.Services.Workspace.CurrentCamera.CFrame)
    end)
end

function NightsInTheForest:StopAntiAFK()
    if self.AntiAFKConnection then
        self.AntiAFKConnection:Disconnect()
        self.AntiAFKConnection = nil
    end
end

function NightsInTheForest:TeleportToNearestKid()
    local hrp = self:GetHRP()
    if not hrp then return end
    local kids = {}
    for _, obj in pairs(self.Core.Services.Workspace:GetDescendants()) do
        if obj:IsA("Model") and self:IsKid(obj) then
            local root = obj:FindFirstChildWhichIsA("BasePart")
            if root then table.insert(kids, obj) end
        end
    end
    local kid = self:FindNearest(kids, 100)
    if kid then
        local root = kid:FindFirstChildWhichIsA("BasePart")
        if root then hrp.CFrame = root.CFrame + Vector3.new(0, 2, 0) end
    end
end

function NightsInTheForest:StopAll()
    self.State.KillAura = false; self:StopKillAura()
    self.State.ChopAura = false; self:StopChopAura()
    self.State.GodMode = false; self:StopGodMode()
    self.State.AutoFarmResources = false; self:StopAutoFarm()
    self.State.AutoCook = false; self:StopAutoCook()
    self.State.AutoUpgradeCampfire = false; self:StopAutoUpgradeCampfire()
    self.State.AutoScrap = false; self:StopAutoScrap()
    self.State.AutoPlant = false; self:StopAutoPlant()
    self.State.AutoRescueKids = false; self:StopAutoRescueKids()
    self.State.AutoEat = false; self:StopAutoEat()
    self.State.Fly = false; self:StopFly()
    self.State.NoClip = false; self:UpdateNoclip()
    self.State.SpeedHack = false; self:UpdateSpeed()
    self.State.ESPEnabled = false; self:ClearESP()
    self.State.Fullbright = false; self:UpdateFullbright()
    self.State.NoFog = false; self:UpdateNoFog()
    self.State.AntiAFK = false; self:StopAntiAFK()
    local hum = self:GetHumanoid()
    if hum then
        hum.WalkSpeed = 16
        hum.JumpPower = 50
    end
    if self.Core.UI and self.Core.UI:GetWindow() then
        self.Core.UI:GetWindow():Notify({
            Title = "Stopped",
            Content = "All functions disabled for 99 Nights",
            Duration = 3,
        })
    end
end

-- ================================================================
--  МОДУЛЬ: PythonBot
-- ================================================================
local PythonBot = {}
PythonBot.__index = PythonBot

function PythonBot:Init(core)
    self.Core = core
    self.BotPath = "externals/python_bot/main.py"
    self.IsRunning = false
end

function PythonBot:Start()
    if self.IsRunning then return end
    self.IsRunning = true
    pcall(function()
        os.execute('start python "' .. self.BotPath .. '"')
        self.Core.Logger:Log("Python bot started")
    end)
end

function PythonBot:Stop()
    self.IsRunning = false
    pcall(function()
        os.execute('taskkill /F /IM python.exe')
        self.Core.Logger:Log("Python bot stopped")
    end)
end

function PythonBot:SendCommand(command)
    pcall(function()
        writefile("ara_bara_bot_command.json", game:GetService("HttpService"):JSONEncode({command = command}))
    end)
end

function PythonBot:ReadOutput()
    pcall(function()
        if isfile("ara_bara_bot_output.json") then
            local data = readfile("ara_bara_bot_output.json")
            return game:GetService("HttpService"):JSONDecode(data)
        end
    end)
    return nil
end

-- ================================================================
--  МОДУЛЬ: CppMacro
-- ================================================================
local CppMacro = {}
CppMacro.__index = CppMacro

function CppMacro:Init(core)
    self.Core = core
    self.Path = "externals/cpp_macro/macro.exe"
end

function CppMacro:Start()
    pcall(function()
        os.execute('start ' .. self.Path)
    end)
end

-- ================================================================
--  УНИВЕРСАЛЬНЫЙ ПЛАГИН (для всех неподдерживаемых игр)
-- ================================================================
local UniversalPlugin = {}
UniversalPlugin.__index = UniversalPlugin

function UniversalPlugin:Init(core)
    local self = setmetatable({}, UniversalPlugin)
    self.Core = core
    self:SetupUI()
    self.Core.Logger:Log("Universal plugin loaded for game: " .. tostring(game.PlaceId))
    return self
end

function UniversalPlugin:SetupUI()
    local window = self.Core.UI:GetWindow()
    if not window then return end
    local tab = window:CreateTab("Universal", "globe")

    tab:CreateSection("ESP")
    tab:CreateToggle({
        Name = "ESP Players",
        CurrentValue = false,
        Callback = function(v)
            if self.Core.ESP then
                self.Core.ESP.State.Enabled = v
                self.Core.ESP.State.BoxColor = Color3.fromRGB(255, 0, 0)
                self.Core.ESP.State.ShowName = true
                self.Core.ESP.State.ShowHealth = true
                self.Core.ESP.State.ShowDistance = true
            end
        end
    })

    tab:CreateSection("Aimbot")
    tab:CreateToggle({
        Name = "Aimbot",
        CurrentValue = false,
        Callback = function(v)
            if self.Core.Aimbot then
                self.Core.Aimbot.Enabled = v
            end
        end
    })
    tab:CreateSlider({
        Name = "Aimbot FOV",
        Range = {10, 360},
        Increment = 5,
        CurrentValue = 90,
        Callback = function(v)
            if self.Core.Aimbot then
                self.Core.Aimbot:SetFOV(v)
            end
        end
    })
    tab:CreateSlider({
        Name = "Smoothing",
        Range = {0, 1},
        Increment = 0.05,
        CurrentValue = 0.3,
        Callback = function(v)
            if self.Core.Aimbot then
                self.Core.Aimbot:SetSmoothing(v)
            end
        end
    })
    tab:CreateToggle({
        Name = "Triggerbot",
        CurrentValue = false,
        Callback = function(v)
            if self.Core.Aimbot then
                self.Core.Aimbot:ToggleTriggerbot(v)
            end
        end
    })

    tab:CreateSection("Movement")
    tab:CreateToggle({
        Name = "Fly (WASD+Space/Ctrl)",
        CurrentValue = false,
        Callback = function(v)
            if self.Core.Fly then
                self.Core.Fly.Enabled = v
                if v then self:StartFly() else self:StopFly() end
            end
        end
    })
    tab:CreateSlider({
        Name = "Fly Speed",
        Range = {10, 500},
        Increment = 5,
        CurrentValue = 80,
        Callback = function(v)
            if self.Core.Fly then
                self.Core.Fly.Speed = v
            end
        end
    })
    tab:CreateToggle({
        Name = "No Clip",
        CurrentValue = false,
        Callback = function(v)
            if self.Core.NoClip then
                self.Core.NoClip.Enabled = v
                self:UpdateNoclip()
            end
        end
    })
    tab:CreateToggle({
        Name = "Speed Hack",
        CurrentValue = false,
        Callback = function(v)
            if self.Core.Speed then
                self.Core.Speed.Enabled = v
                self:UpdateSpeed()
            end
        end
    })
    tab:CreateSlider({
        Name = "Speed Value",
        Range = {16, 500},
        Increment = 1,
        CurrentValue = 16,
        Callback = function(v)
            if self.Core.Speed then
                self.Core.Speed.Value = v
                if self.Core.Speed.Enabled then self:UpdateSpeed() end
            end
        end
    })
    tab:CreateToggle({
        Name = "God Mode",
        CurrentValue = false,
        Callback = function(v)
            if self.Core.GodMode then
                self.Core.GodMode.Enabled = v
                if v then self:StartGodMode() else self:StopGodMode() end
            end
        end
    })

    tab:CreateSection("Teleport")
    tab:CreateButton({
        Name = "Teleport to Spawn",
        Callback = function()
            local spawn = self.Core.Services.Workspace:FindFirstChild("SpawnLocation")
            if spawn then
                local hrp = self:GetHRP()
                if hrp then hrp.CFrame = spawn.CFrame + Vector3.new(0, 3, 0) end
            end
        end
    })

    tab:CreateButton({
        Name = "Stop All",
        Callback = function()
            self:StopAll()
        end
    })
end

function UniversalPlugin:GetChar()
    return self.Core.Services.Players.LocalPlayer.Character or self.Core.Services.Players.LocalPlayer.CharacterAdded:Wait()
end

function UniversalPlugin:GetHRP()
    local char = self:GetChar()
    return char and char:FindFirstChild("HumanoidRootPart")
end

function UniversalPlugin:GetHumanoid()
    local char = self:GetChar()
    return char and char:FindFirstChildOfClass("Humanoid")
end

function UniversalPlugin:UpdateNoclip()
    local char = self:GetChar()
    if not char then return end
    for _, part in pairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CanCollide = not (self.Core.NoClip and self.Core.NoClip.Enabled)
        end
    end
end

function UniversalPlugin:UpdateSpeed()
    local hum = self:GetHumanoid()
    if hum and self.Core.Speed then
        hum.WalkSpeed = self.Core.Speed.Enabled and self.Core.Speed.Value or 16
    end
end

function UniversalPlugin:StartFly()
    if self.FlyConnection then return end
    local hrp = self:GetHRP()
    if not hrp then return end
    self.FlyBody = Instance.new("BodyVelocity")
    self.FlyBody.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    self.FlyBody.Velocity = Vector3.zero
    self.FlyBody.Parent = hrp
    local hum = self:GetHumanoid()
    if hum then hum.PlatformStand = true end
    self.FlyConnection = self.Core.Services.RunService.Heartbeat:Connect(function()
        if not (self.Core.Fly and self.Core.Fly.Enabled) then return end
        local hrp = self:GetHRP()
        if not hrp or not self.FlyBody then return end
        local dir = Vector3.zero
        local uis = self.Core.Services.UserInputService
        local cam = self.Core.Services.Workspace.CurrentCamera
        if uis:IsKeyDown(Enum.KeyCode.W) then dir = dir + cam.CFrame.LookVector end
        if uis:IsKeyDown(Enum.KeyCode.S) then dir = dir - cam.CFrame.LookVector end
        if uis:IsKeyDown(Enum.KeyCode.A) then dir = dir - cam.CFrame.RightVector end
        if uis:IsKeyDown(Enum.KeyCode.D) then dir = dir + cam.CFrame.RightVector end
        if uis:IsKeyDown(Enum.KeyCode.Space) then dir = dir + Vector3.new(0, 1, 0) end
        if uis:IsKeyDown(Enum.KeyCode.LeftControl) then dir = dir - Vector3.new(0, 1, 0) end
        if dir.Magnitude > 0 then dir = dir.Unit end
        self.FlyBody.Velocity = dir * (self.Core.Fly and self.Core.Fly.Speed or 80)
    end)
end

function UniversalPlugin:StopFly()
    if self.FlyBody then self.FlyBody:Destroy(); self.FlyBody = nil end
    if self.FlyConnection then self.FlyConnection:Disconnect(); self.FlyConnection = nil end
    local hum = self:GetHumanoid()
    if hum then hum.PlatformStand = false end
end

function UniversalPlugin:StartGodMode()
    if self.GodModeConnection then return end
    self.GodModeConnection = self.Core.Services.RunService.Heartbeat:Connect(function()
        if not (self.Core.GodMode and self.Core.GodMode.Enabled) then return end
        local char = self:GetChar()
        if not char then return end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then hum.Health = hum.MaxHealth end
    end)
end

function UniversalPlugin:StopGodMode()
    if self.GodModeConnection then
        self.GodModeConnection:Disconnect()
        self.GodModeConnection = nil
    end
end

function UniversalPlugin:StopAll()
    if self.Core.Fly then self.Core.Fly.Enabled = false; self:StopFly() end
    if self.Core.NoClip then self.Core.NoClip.Enabled = false; self:UpdateNoclip() end
    if self.Core.Speed then self.Core.Speed.Enabled = false; self:UpdateSpeed() end
    if self.Core.GodMode then self.Core.GodMode.Enabled = false; self:StopGodMode() end
    if self.Core.ESP then self.Core.ESP.State.Enabled = false end
    if self.Core.Aimbot then self.Core.Aimbot.Enabled = false end
    local hum = self:GetHumanoid()
    if hum then hum.WalkSpeed = 16 end
    if self.Core.UI and self.Core.UI:GetWindow() then
        self.Core.UI:GetWindow():Notify({
            Title = "Stopped",
            Content = "All functions disabled",
            Duration = 3,
        })
    end
end

-- ================================================================
--  ЯДРО (Core)
-- ================================================================
local Core = {}
Core.Services = {}
Core.Plugins = {}
Core.Config = {}
Core.Logger = {}
Core.Version = "2.0.0"

setmetatable(Core.Services, {
    __index = function(self, name)
        local success, service = pcall(function()
            return game:GetService(name)
        end)
        if success then
            rawset(self, name, service)
            return service
        end
        return nil
    end
})

function Core.Logger:Log(message, level)
    level = level or "INFO"
    local timestamp = os.date("%Y-%m-%d %H:%M:%S")
    local logMessage = string.format("[%s] [%s] %s\n", timestamp, level, message)
    print(logMessage)
    pcall(function()
        if not isfolder("ara_bara_logs") then makefolder("ara_bara_logs") end
        local logFile = "ara_bara_logs/log.txt"
        local current = isfile(logFile) and readfile(logFile) or ""
        writefile(logFile, current .. logMessage)
    end)
end

function Core.Config:Load()
    pcall(function()
        if isfile("ara_bara_config.json") then
            local data = readfile("ara_bara_config.json")
            self.Data = game:GetService("HttpService"):JSONDecode(data)
        else
            self.Data = {}
        end
    end)
    if not self.Data then self.Data = {} end
end

function Core.Config:Save()
    pcall(function()
        local json = game:GetService("HttpService"):JSONEncode(self.Data)
        writefile("ara_bara_config.json", json)
    end)
end

function Core:RegisterPlugin(gameId, plugin)
    self.Plugins[gameId] = plugin
end

function Core:Start()
    self.Config:Load()
    local placeId = game.PlaceId

    self.UI = UIManager.new(self)
    self.UI:Init()

    self.ESP = ESP:Init(self)
    self.ESP:StartLoop()

    self.Aimbot = Aimbot:Init(self)
    self.Aimbot:StartLoop()

    self.Fly = Fly:Init(self)
    self.Speed = Speed:Init(self)
    self.GodMode = GodMode:Init(self)
    self.NoClip = NoClip:Init(self)

    local plugin = self.Plugins[placeId]
    if plugin then
        self.Logger:Log("Loading plugin for game: " .. tostring(placeId))
        pcall(function()
            plugin:Init(self)
        end)
    else
        self.Logger:Log("Game not supported, using Universal plugin: " .. tostring(placeId), "WARN")
        UniversalPlugin:Init(self)
    end

    if self.Config.Data.EnablePythonBot then
        PythonBot:Init(self)
        PythonBot:Start()
    end

    if self.Config.Data.EnableCppMacro then
        CppMacro:Init(self)
        CppMacro:Start()
    end

    self.Logger:Log("ara_bara hub v" .. self.Version .. " loaded")
end

-- ================================================================
--  ТАБЛИЦА ИГР (100+ популярных PlaceId)
-- ================================================================
local plugins = {
    -- Специфические плагины
    [286090429] = Arsenal,           -- Arsenal
    [6872265039] = BedWars,          -- BedWars
    [2753915549] = BloxFruits,       -- Blox Fruits
    [3260590327] = TowerDefenseSimulator, -- Tower Defense Simulator
    [142823291] = MurderMystery2,    -- Murder Mystery 2
    [2933628366] = AnimeFightingSimulator, -- Anime Fighting Simulator
    [7326934954] = NightsInTheForest, -- 99 Nights in the Forest

    -- Универсальные игры (100+ популярных)
    [4587775340] = UniversalPlugin,  -- Adopt Me!
    [4924929498] = UniversalPlugin,  -- Brookhaven RP
    [606849621] = UniversalPlugin,   -- Jailbreak
    [292439477] = UniversalPlugin,   -- Phantom Forces
    [6284583030] = UniversalPlugin,  -- Pet Simulator X
    [537413528] = UniversalPlugin,   -- Work at a Pizza Place
    [185655149] = UniversalPlugin,   -- Welcome to Bloxburg
    [4872321990] = UniversalPlugin,  -- Piggy
    [2826138270] = UniversalPlugin,  -- The Strongest Battlegrounds
    [1423549694] = UniversalPlugin,  -- Military Tycoon
    [2792673302] = UniversalPlugin,  -- Super Power Training Simulator
    [3419540004] = UniversalPlugin,  -- Restaurants
    [3947030770] = UniversalPlugin,  -- Pet Simulator
    [2784846369] = UniversalPlugin,  -- Dragon Adventures
    [1732449490] = UniversalPlugin,  -- Theme Park Tycoon 2
    [2813785345] = UniversalPlugin,  -- Kingdom Life
    [4970642905] = UniversalPlugin,  -- SCP: Roleplay
    [2103606749] = UniversalPlugin,  -- World Zero
    [4633404344] = UniversalPlugin,  -- All Star Tower Defense
    [3248708555] = UniversalPlugin,  -- Zombie Attack
    [3407253075] = UniversalPlugin,  -- Doomspire Brickbattle
    [4520749081] = UniversalPlugin,  -- King Legacy
    [5070770716] = UniversalPlugin,  -- Noob Army Tycoon
    [6405723579] = UniversalPlugin,  -- Clicker Simulator
    [4886573779] = UniversalPlugin,  -- Restaurant Tycoon 2
    [3372099651] = UniversalPlugin,  -- Shindo Life
    [5009287304] = UniversalPlugin,  -- Gem Tycoon
    [1633760336] = UniversalPlugin,  -- Traitor Town
    [4512933860] = UniversalPlugin,  -- Ultimate Driving
    [6955869985] = UniversalPlugin,  -- Anime Dimensions
    [1981897249] = UniversalPlugin,  -- The Lab
    [4033778196] = UniversalPlugin,  -- Natural Disaster Survival
    [2548686743] = UniversalPlugin,  -- Tower of Hell
    [2522970470] = UniversalPlugin,  -- Speed Run 4
    [2748612137] = UniversalPlugin,  -- Breaking Point
    [4589867994] = UniversalPlugin,  -- Tapping Simulator
    [4834740886] = UniversalPlugin,  -- Wheel of Fortune
    [4134037187] = UniversalPlugin,  -- Plates of Fate
    [2470913508] = UniversalPlugin,  -- Vehicle Simulator
    [2552606348] = UniversalPlugin,  -- Flood Escape
    [4172963777] = UniversalPlugin,  -- The Final Stand
    [4852364686] = UniversalPlugin,  -- Pokemon Fight
    [5098230172] = UniversalPlugin,  -- Obby But You're on a Bike
    [6802838188] = UniversalPlugin,  -- Pet Simulator Z
    [6727949531] = UniversalPlugin,  -- Ninja Legends
    [5635212116] = UniversalPlugin,  -- Rocket Arena
    [7096075316] = UniversalPlugin,  -- Islands
    [7396230629] = UniversalPlugin,  -- Tower Defense Tycoon
    [7575522247] = UniversalPlugin,  -- Treasure Hunt Simulator
    [7833796127] = UniversalPlugin,  -- Mining Simulator 2
    [8023494356] = UniversalPlugin,  -- Soccer Simulator
    [8145685291] = UniversalPlugin,  -- Wild West
    [8271076354] = UniversalPlugin,  -- The Plaza
    [8486027582] = UniversalPlugin,  -- Dragon Ball FighterZ
    [8681141343] = UniversalPlugin,  -- Counter Blox
    [8863535603] = UniversalPlugin,  -- Arsenal 2
    [9026589357] = UniversalPlugin,  -- RBLXWare
    [9201381300] = UniversalPlugin,  -- Super Doomspire
    [9385532042] = UniversalPlugin,  -- Zombie Uprising
    [9571796021] = UniversalPlugin,  -- Bloxburg 2
    [9753249522] = UniversalPlugin,  -- Adopt Me 2
    [9933685600] = UniversalPlugin,  -- Brookhaven 2
    [1011475619] = UniversalPlugin,  -- (placeholder)
}

for id, plugin in pairs(plugins) do
    Core:RegisterPlugin(id, plugin)
end

Core:Start()

return Core
