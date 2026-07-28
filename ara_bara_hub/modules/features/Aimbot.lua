-- ================================================================
--  Aimbot.lua
--  Полный код модуля Aimbot
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

return Aimbot