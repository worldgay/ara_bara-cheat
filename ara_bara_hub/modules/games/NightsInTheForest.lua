-- ================================================================
--  99 Nights in the Forest | Плагин для ara_bara hub
--  Основан на открытых скриптах: Echo Hub, REZO HUB, AVESTIX
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
        AutoStunDeer = false,
        AutoFeed = false,
        AutoRescueKids = false,
        AutoFarmResources = false,
        ResourceType = "Wood",
        ESPEnabled = false,
        ESPPlayers = false,
        ESPEnemies = false,
        ESPItems = false,
        ESPKids = false,
        ESPAnimals = false,
        Fly = false,
        FlySpeed = 80,
        NoClip = false,
        SpeedHack = false,
        SpeedValue = 16,
        InfiniteJump = false,
        Fullbright = false,
        NoFog = false,
        AntiAFK = false,
        BringItems = false,
        BringType = "Wood",
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

    -- Combat
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

    -- Farming
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
        Callback = function(v)
            self.State.ResourceType = v[1]
        end
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
    tab:CreateToggle({
        Name = "Auto Feed Animals",
        CurrentValue = false,
        Callback = function(v)
            self.State.AutoFeed = v
            if v then self:StartAutoFeed() else self:StopAutoFeed() end
        end
    })

    -- ESP
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

    -- Movement
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

    -- Visuals
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

    -- Teleports
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

    -- Misc
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

-- ================================================================
--  UTILITY FUNCTIONS
-- ================================================================
function NightsInTheForest:GetChar()
    return self.Core.Services.Players.LocalPlayer.Character or
           self.Core.Services.Players.LocalPlayer.CharacterAdded:Wait()
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

-- ================================================================
--  KILL AURA
-- ================================================================
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

-- ================================================================
--  CHOP AURA
-- ================================================================
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

-- ================================================================
--  GOD MODE
-- ================================================================
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

-- ================================================================
--  AUTO FARM
-- ================================================================
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

-- ================================================================
--  AUTO COOK
-- ================================================================
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

-- ================================================================
--  AUTO UPGRADE CAMPFIRE
-- ================================================================
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

-- ================================================================
--  AUTO SCRAP
-- ================================================================
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

-- ================================================================
--  AUTO PLANT SAPLINGS
-- ================================================================
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

-- ================================================================
--  AUTO RESCUE KIDS
-- ================================================================
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

-- ================================================================
--  AUTO EAT
-- ================================================================
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

-- ================================================================
--  AUTO FEED ANIMALS
-- ================================================================
function NightsInTheForest:StartAutoFeed()
    if self.AutoFeedConnection then return end
    self.AutoFeedConnection = self.Core.Services.RunService.Heartbeat:Connect(function()
        if not self.State.AutoFeed then return end
        -- Можно реализовать позже
    end)
end

function NightsInTheForest:StopAutoFeed()
    if self.AutoFeedConnection then
        self.AutoFeedConnection:Disconnect()
        self.AutoFeedConnection = nil
    end
end

-- ================================================================
--  ESP
-- ================================================================
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

-- ================================================================
--  FLY
-- ================================================================
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

-- ================================================================
--  NO CLIP
-- ================================================================
function NightsInTheForest:UpdateNoclip()
    local char = self:GetChar()
    if not char then return end
    for _, part in pairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CanCollide = not self.State.NoClip
        end
    end
end

-- ================================================================
--  SPEED
-- ================================================================
function NightsInTheForest:UpdateSpeed()
    local hum = self:GetHumanoid()
    if hum then
        hum.WalkSpeed = self.State.SpeedHack and self.State.SpeedValue or 16
    end
end

-- ================================================================
--  INFINITE JUMP
-- ================================================================
function NightsInTheForest:UpdateInfiniteJump()
    if self.State.InfiniteJump then
        local uis = self.Core.Services.UserInputService
        uis.JumpRequest:Connect(function()
            local hum = self:GetHumanoid()
            if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
        end)
    end
end

-- ================================================================
--  FULLBRIGHT
-- ================================================================
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

-- ================================================================
--  NO FOG
-- ================================================================
function NightsInTheForest:UpdateNoFog()
    local lighting = self.Core.Services.Lighting
    if self.State.NoFog then
        lighting.FogEnd = 1e6
    else
        lighting.FogEnd = OriginalLighting.FogEnd or 1000
    end
end

-- ================================================================
--  ANTI-AFK
-- ================================================================
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

-- ================================================================
--  TELEPORTS
-- ================================================================
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

-- ================================================================
--  STOP ALL
-- ================================================================
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
    self.State.AutoFeed = false; self:StopAutoFeed()
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
    self.Core.UI:GetWindow():Notify({
        Title = "Stopped",
        Content = "All functions disabled for 99 Nights",
        Duration = 3,
    })
end

return NightsInTheForest