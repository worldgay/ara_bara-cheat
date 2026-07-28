-- ================================================================
--  BloxFruits.lua
--  Полный код плагина для игры Blox Fruits
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
    -- Заглушка: можно реализовать позже
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

return BloxFruits