local TowerDefenseSimulator = {}
TowerDefenseSimulator.__index = TowerDefenseSimulator

function TowerDefenseSimulator:Init(core)
    self.Core = core
    self.Core.Logger:Log("TowerDefenseSimulator plugin initialized")
end

return TowerDefenseSimulator