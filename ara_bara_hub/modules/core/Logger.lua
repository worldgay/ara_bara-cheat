local Logger = {}

function Logger:Log(message, level)
    level = level or "INFO"
    local timestamp = os.date("%Y-%m-%d %H:%M:%S")
    local logMessage = string.format("[%s] [%s] %s", timestamp, level, message)
    print(logMessage)
    pcall(function()
        if isfolder and not isfolder("ara_bara_logs") then
            makefolder("ara_bara_logs")
        end
        if isfile and writefile and readfile then
            local logFile = "ara_bara_logs/log.txt"
            local current = isfile(logFile) and readfile(logFile) or ""
            writefile(logFile, current .. logMessage .. "\n")
        end
    end)
end

return Logger