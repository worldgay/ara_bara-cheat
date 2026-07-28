local CppMacro = {}
CppMacro.__index = CppMacro

function CppMacro:Init(core)
    self.Core = core
    self.Path = "externals/cpp_macro/macro.exe"
end

function CppMacro:Start()
    pcall(function()
        os.execute('start ' .. self.Path)
    end)
end

return CppMacro