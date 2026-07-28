local Teleport = {}
Teleport.__index = Teleport

function Teleport:Init(core)
    self.Core = core
end

function Teleport:ToPosition(cframe)
    local char = self.Core.Services.Players.LocalPlayer.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        char.HumanoidRootPart.CFrame = cframe
    end
end

return Teleport