-- ================================================================
--  Arsenal.lua
--  Полный код плагина для игры Arsenal
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

return Arsenal