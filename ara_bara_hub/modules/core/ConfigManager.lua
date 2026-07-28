local ConfigManager = {}
ConfigManager.__index = ConfigManager

function ConfigManager.new()
    local self = setmetatable({}, ConfigManager)
    self.Data = {}
    return self
end

function ConfigManager:Load(fileName)
    fileName = fileName or "ara_bara_config.json"
    pcall(function()
        if isfile and isfile(fileName) then
            local data = readfile(fileName)
            self.Data = game:GetService("HttpService"):JSONDecode(data)
        end
    end)
    return self.Data
end

function ConfigManager:Save(fileName)
    fileName = fileName or "ara_bara_config.json"
    pcall(function()
        if writefile then
            local json = game:GetService("HttpService"):JSONEncode(self.Data)
            writefile(fileName, json)
        end
    end)
end

return ConfigManager