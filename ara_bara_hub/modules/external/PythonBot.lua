local PythonBot = {}
PythonBot.__index = PythonBot

function PythonBot:Init(core)
    self.Core = core
    self.BotPath = "externals/python_bot/main.py"
    self.IsRunning = false
end

function PythonBot:Start()
    if self.IsRunning then return end
    self.IsRunning = true
    
    pcall(function()
        os.execute('start python "' .. self.BotPath .. '"')
        self.Core.Logger:Log("Python bot started")
    end)
end

function PythonBot:Stop()
    self.IsRunning = false
    pcall(function()
        os.execute('taskkill /F /IM python.exe')
        self.Core.Logger:Log("Python bot stopped")
    end)
end

function PythonBot:SendCommand(command)
    pcall(function()
        writefile("ara_bara_bot_command.json", game:GetService("HttpService"):JSONEncode({command = command}))
    end)
end

function PythonBot:ReadOutput()
    pcall(function()
        if isfile("ara_bara_bot_output.json") then
            local data = readfile("ara_bara_bot_output.json")
            return game:GetService("HttpService"):JSONDecode(data)
        end
    end)
    return nil
end

return PythonBot