local UIManager = {}
UIManager.__index = UIManager

function UIManager.new(core)
    local self = setmetatable({}, UIManager)
    self.Core = core
    self.Window = nil
    self.Tabs = {}
    return self
end

function UIManager:Init()
    local Rayfield
    local success, err = pcall(function()
        Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()
    end)
    if not success then
        self.Core.Logger:Log("Failed to load Rayfield: " .. tostring(err), "ERROR")
        return
    end
    
    self.Window = Rayfield:CreateWindow({
        Name = "ara_bara hub",
        LoadingTitle = "ara_bara hub",
        LoadingSubtitle = "by ara_bara",
        ConfigurationSaving = { Enabled = true, FolderName = "ara_bara", FileName = "settings" },
        KeySystem = false,
        Theme = "Ocean",
    })
    
    -- Общая вкладка "Main"
    local mainTab = self:CreateTab("Main", "home")
    mainTab:CreateSection("Global Settings")
    mainTab:CreateToggle({
        Name = "ESP",
        CurrentValue = false,
        Callback = function(v)
            if self.Core.ESP then
                self.Core.ESP.State.Enabled = v
            end
        end
    })
    mainTab:CreateToggle({
        Name = "Aimbot",
        CurrentValue = false,
        Callback = function(v)
            if self.Core.Aimbot then
                self.Core.Aimbot.Enabled = v
            end
        end
    })
    
    self.Core.Logger:Log("UI initialized")
end

function UIManager:GetWindow()
    return self.Window
end

function UIManager:CreateTab(name, icon)
    if not self.Window then return end
    local tab = self.Window:CreateTab(name, icon)
    self.Tabs[name] = tab
    return tab
end

return UIManager