local Speed = {}
Speed.__index = Speed

function Speed:Init(core)
    self.Core = core
    self.Multiplier = 2
end

function Speed:SetSpeed(value)
    local char = self.Core.Services.Players.LocalPlayer.Character
    if char and char:FindFirstChildOfClass("Humanoid") then
        char:FindFirstChildOfClass("Humanoid").WalkSpeed = value
    end
end

return Speed