local Executor = {}
Executor.__index = Executor

function Executor:Detect()
    local name = "Unknown"
    if pcall(function() return syn end) then
        name = "Synapse X"
    elseif pcall(function() return krnl end) then
        name = "Krnl"
    elseif pcall(function() return scriptware end) then
        name = "ScriptWare"
    elseif pcall(function() return fluxus end) then
        name = "Fluxus"
    elseif pcall(function() return getexecutorname end) then
        name = getexecutorname()
    end
    return name
end

function Executor:GetAPI()
    local api = {}
    if pcall(function() return getgc end) then
        api.getgc = getgc
    end
    if pcall(function() return hookfunction end) then
        api.hookfunction = hookfunction
    end
    if pcall(function() return hookmetamethod end) then
        api.hookmetamethod = hookmetamethod
    end
    if pcall(function() return writefile end) then
        api.writefile = writefile
        api.readfile = readfile
        api.isfile = isfile
        api.isfolder = isfolder
        api.makefolder = makefolder
    end
    return api
end

return Executor