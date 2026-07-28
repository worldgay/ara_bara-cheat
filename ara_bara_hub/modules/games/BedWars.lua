local BedWars = {}
BedWars.__index = BedWars

function BedWars:Init(core)
    self.Core = core
    self.Core.Logger:Log("BedWars plugin initialized")
end

return BedWars