local Fly = {}
Fly.__index = Fly

function Fly:Init(core)
    self.Core = core
    self.Enabled = false
    self.Speed = 50
end

return Fly