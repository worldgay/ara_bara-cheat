local ValueScanner = {}
ValueScanner.__index = ValueScanner

function ValueScanner:Init(core)
    self.Core = core
    self.FoundValues = {}
    self.Scanning = false
end

function ValueScanner:Scan()
    self.Scanning = true
    self.FoundValues = {}
    
    local objects = {}
    for _, obj in pairs(self.Core.Services.Players.LocalPlayer:GetDescendants()) do
        if obj:IsA("NumberValue") or obj:IsA("IntValue") then
            table.insert(objects, obj)
        end
    end
    for _, obj in pairs(self.Core.Services.Players.LocalPlayer.Character:GetDescendants()) do
        if obj:IsA("NumberValue") or obj:IsA("IntValue") then
            table.insert(objects, obj)
        end
    end
    
    for _, obj in pairs(objects) do
        local name = obj.Name:lower()
        if name:find("health") or name:find("money") or name:find("cash") or name:find("coin") or name:find("diamond") or name:find("gem") or name:find("level") or name:find("xp") then
            self.FoundValues[obj] = {
                Name = obj.Name,
                Value = obj.Value,
                Object = obj
            }
        end
    end
    
    self.Scanning = false
    return self.FoundValues
end

function ValueScanner:CreateUI()
    local values = self:Scan()
    local window = self.Core.UI and self.Core.UI:GetWindow()
    if not window then return end
    
    local tab = window:CreateTab("Value Scanner", "search")
    local section = tab:CreateSection("Found Values")
    
    for obj, data in pairs(values) do
        tab:CreateSlider({
            Name = data.Name,
            Range = {0, data.Value * 2},
            Increment = 1,
            CurrentValue = data.Value,
            Callback = function(v)
                pcall(function() obj.Value = v end)
            end
        })
    end
end

return ValueScanner