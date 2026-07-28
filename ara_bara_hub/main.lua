-- ================================================================
--  main.lua
--  Главный загрузчик хаба ara_bara hub
--  Автор: ara_bara
--  Версия: 1.0.0
-- ================================================================
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local LocalPlayer = Players.LocalPlayer

local Core = {}
Core.Services = {}
Core.Plugins = {}
Core.Config = {}
Core.Logger = {}
Core.Version = "1.0.0"

setmetatable(Core.Services, {
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

function Core.Logger:Log(message, level)
    level = level or "INFO"
    local timestamp = os.date("%Y-%m-%d %H:%M:%S")
    local logMessage = string.format("[%s] [%s] %s\n", timestamp, level, message)
    print(logMessage)
    pcall(function()
        if not isfolder("ara_bara_logs") then makefolder("ara_bara_logs") end
        local logFile = "ara_bara_logs/log.txt"
        local current = isfile(logFile) and readfile(logFile) or ""
        writefile(logFile, current .. logMessage)
    end)
end

function Core.Config:Load()
    pcall(function()
        if isfile("ara_bara_config.json") then
            local data = readfile("ara_bara_config.json")
            self.Data = game:GetService("HttpService"):JSONDecode(data)
        else
            self.Data = {}
        end
    end)
    if not self.Data then self.Data = {} end
end

function Core.Config:Save()
    pcall(function()
        local json = game:GetService("HttpService"):JSONEncode(self.Data)
        writefile("ara_bara_config.json", json)
    end)
end

function Core:RegisterPlugin(gameId, plugin)
    self.Plugins[gameId] = plugin
end

function Core:Start()
    self.Config:Load()
    local placeId = game.PlaceId

    local UIManager = require(script.Parent.modules.core.UIManager)
    self.UI = UIManager.new(self)
    self.UI:Init()

    local ESP = require(script.Parent.modules.features.ESP)
    self.ESP = ESP:Init(self)
    self.ESP:StartLoop()

    local Aimbot = require(script.Parent.modules.features.Aimbot)
    self.Aimbot = Aimbot:Init(self)
    self.Aimbot:StartLoop()

    local plugin = self.Plugins[placeId]
    if plugin then
        self.Logger:Log("Loading plugin for game: " .. tostring(placeId))
        pcall(function()
            plugin:Init(self)
        end)
    else
        self.Logger:Log("Game not supported: " .. tostring(placeId), "WARN")
        StarterGui:SetCore("SendNotification", {
            Title = "ara_bara hub",
            Text = "Game not supported! PlaceId: " .. tostring(placeId),
            Duration = 5,
        })
    end

    if self.Config.Data.EnablePythonBot then
        local PythonBot = require(script.Parent.modules.external.PythonBot)
        PythonBot:Init(self)
        PythonBot:Start()
    end

    if self.Config.Data.EnableCppMacro then
        local CppMacro = require(script.Parent.modules.external.CppMacro)
        CppMacro:Init(self)
        CppMacro:Start()
    end

    self.Logger:Log("ara_bara hub v" .. self.Version .. " loaded")
end

local plugins = {
    [286090429] = require(script.Parent.modules.games.Arsenal),
    [6872265039] = require(script.Parent.modules.games.BedWars),
    [2753915549] = require(script.Parent.modules.games.BloxFruits),
    [3260590327] = require(script.Parent.modules.games.TowerDefenseSimulator),
    [142823291] = require(script.Parent.modules.games.MurderMystery2),
    [2933628366] = require(script.Parent.modules.games.AnimeFightingSimulator),
    [7326934954] = require(script.Parent.modules.games.NightsInTheForest),
}

for id, plugin in pairs(plugins) do
    Core:RegisterPlugin(id, plugin)
end

Core:Start()

return Core