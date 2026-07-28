local ServiceManager = {}
ServiceManager.Services = {}

setmetatable(ServiceManager.Services, {
    __index = function(self, name)
        local success, service = pcall(function()
            return game:GetService(name)
        end)
        if success then
            rawset(self, name, service)
            return service
        end
        return nil
    end
})

function ServiceManager:GetService(name)
    return self.Services[name]
end

return ServiceManager