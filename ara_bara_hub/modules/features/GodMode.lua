local GodMode = {}
GodMode.__index = GodMode

function GodMode:Init(core)
    self.Core = core
    self.Enabled = false
end

return GodMode