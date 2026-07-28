local ESP = {}
ESP.__index = ESP

function ESP:Init(core)
    local self = setmetatable({}, ESP)
    self.Core = core
    self.State = {
        Enabled = false,
        BoxType = "2D",           -- "2D", "3D", "Corner"
        BoxColor = Color3.fromRGB(255, 0, 0),
        TeamColor = Color3.fromRGB(0, 255, 0),
        ShowName = false,
        ShowHealth = false,
        ShowDistance = false,
        ShowTracer = false,
        ShowSkeleton = false,
        MaxDistance = 300,
        TracerPosition = "Bottom", -- "Bottom", "Top", "Middle"
        WallCheck = false,
    }
    self.Objects = {}
    self.Folder = Instance.new("Folder", self.Core.Services.CoreGui or game:GetService("CoreGui"))
    self.Folder.Name = "ara_bara_ESP"
    self.UpdateInterval = 0.5
    self.Running = false
    return self
end

function ESP:StartLoop()
    if self.Running then return end
    self.Running = true
    task.spawn(function()
        while self.Running do
            if self.State.Enabled then
                self:Update()
            else
                self:Clear()
            end
            task.wait(self.UpdateInterval)
        end
    end)
end

function ESP:StopLoop()
    self.Running = false
end

function ESP:Update()
    if not self.State.Enabled then
        self:Clear()
        return
    end

    local players = self.Core.Services.Players:GetPlayers()
    local localPlayer = self.Core.Services.Players.LocalPlayer

    for _, player in pairs(players) do
        if player ~= localPlayer and player.Character then
            self:CreateESPForPlayer(player)
        end
    end

    -- Удаляем ESP для игроков, которые вышли или перестали существовать
    local toRemove = {}
    for key, obj in pairs(self.Objects) do
        if type(key) == "string" and key:match("billboard_") then
            local playerName = key:gsub("billboard_", "")
            local player = self.Core.Services.Players:FindFirstChild(playerName)
            if not player or not player.Character then
                table.insert(toRemove, key)
            end
        end
    end
    for _, key in ipairs(toRemove) do
        if self.Objects[key] then
            self.Objects[key]:Destroy()
            self.Objects[key] = nil
        end
    end
end

function ESP:CreateESPForPlayer(player)
    local char = player.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    if not self.Folder then return end

    -- Проверка видимости (WallCheck)
    if self.State.WallCheck then
        local cam = self.Core.Services.Workspace.CurrentCamera
        local origin = cam.CFrame.Position
        local direction = (hrp.Position - origin).Unit * self.State.MaxDistance
        local params = RaycastParams.new()
        local localChar = self.Core.Services.Players.LocalPlayer.Character
        if localChar then
            params.FilterDescendantsInstances = {localChar}
        end
        params.FilterType = Enum.RaycastFilterType.Blacklist
        local result = self.Core.Services.Workspace:Raycast(origin, direction, params)
        if result and result.Instance:IsDescendantOf(char) then
            -- виден
        else
            -- не виден, пропускаем
            return
        end
    end

    -- Создание Highlight
    local highlight = self.Objects[player]
    if not highlight then
        highlight = Instance.new("Highlight")
        highlight.Parent = self.Folder
        self.Objects[player] = highlight
    end
    highlight.FillColor = self.State.BoxColor
    highlight.OutlineColor = Color3.new(1, 1, 1)
    highlight.FillTransparency = 0.5
    highlight.OutlineTransparency = 0.2
    highlight.Adornee = char

    -- Billboard для имени/HP/дистанции
    local billboardKey = "billboard_" .. player.Name
    local billboard = self.Objects[billboardKey]
    if not billboard then
        billboard = Instance.new("BillboardGui")
        billboard.Size = UDim2.new(0, 200, 0, 60)
        billboard.StudsOffset = Vector3.new(0, 4, 0)
        billboard.AlwaysOnTop = true
        billboard.Parent = self.Folder
        self.Objects[billboardKey] = billboard

        local text = Instance.new("TextLabel")
        text.Size = UDim2.new(1, 0, 1, 0)
        text.BackgroundTransparency = 1
        text.TextScaled = true
        text.Font = Enum.Font.GothamBold
        text.TextStrokeTransparency = 0
        text.Parent = billboard
        self.Objects["label_" .. player.Name] = text
    end

    local text = self.Objects["label_" .. player.Name]
    if text then
        local parts = {}
        if self.State.ShowName then
            table.insert(parts, player.Name)
        end
        if self.State.ShowHealth then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then
                table.insert(parts, string.format("HP: %d/%d", hum.Health, hum.MaxHealth))
            end
        end
        if self.State.ShowDistance then
            local cam = self.Core.Services.Workspace.CurrentCamera
            local dist = (hrp.Position - cam.CFrame.Position).Magnitude
            table.insert(parts, string.format("%dm", math.floor(dist)))
        end
        text.Text = table.concat(parts, " | ")
        text.TextColor3 = self.State.BoxColor
    end

    -- Трассеры (если включены) — используем Drawing API, если доступно
    if self.State.ShowTracer then
        local tracerKey = "tracer_" .. player.Name
        local tracer = self.Objects[tracerKey]
        if not tracer then
            if type(Drawing) == "table" and Drawing.new then
                tracer = Drawing.new("Line")
                tracer.Thickness = 2
                tracer.Color = self.State.BoxColor
                tracer.Visible = true
                self.Objects[tracerKey] = tracer
            end
        end
        if tracer then
            local cam = self.Core.Services.Workspace.CurrentCamera
            local screenPos, onScreen = cam:WorldToViewportPoint(hrp.Position)
            if onScreen then
                local viewport = cam.ViewportSize
                local bottomPos = Vector2.new(viewport.X / 2, viewport.Y)
                if self.State.TracerPosition == "Top" then
                    bottomPos = Vector2.new(viewport.X / 2, 0)
                elseif self.State.TracerPosition == "Middle" then
                    bottomPos = Vector2.new(viewport.X / 2, viewport.Y / 2)
                end
                tracer.From = bottomPos
                tracer.To = Vector2.new(screenPos.X, screenPos.Y)
                tracer.Color = self.State.BoxColor
                tracer.Visible = true
            else
                tracer.Visible = false
            end
        end
    else
        -- Удаляем трассеры, если они есть
        for key, obj in pairs(self.Objects) do
            if type(key) == "string" and key:match("tracer_") then
                obj:Destroy()
                self.Objects[key] = nil
            end
        end
    end

    -- Скелет (если включен) — можно добавить позже
end

function ESP:Clear()
    for _, obj in pairs(self.Objects) do
        pcall(function() obj:Destroy() end)
    end
    self.Objects = {}
    -- Очищаем папку на всякий случай
    if self.Folder then
        for _, child in pairs(self.Folder:GetChildren()) do
            child:Destroy()
        end
    end
end

function ESP:SetColor(color)
    self.State.BoxColor = color
end

function ESP:SetMaxDistance(dist)
    self.State.MaxDistance = dist
end

function ESP:ToggleTracer(enable)
    self.State.ShowTracer = enable
    if not enable then
        for key, obj in pairs(self.Objects) do
            if type(key) == "string" and key:match("tracer_") then
                obj:Destroy()
                self.Objects[key] = nil
            end
        end
    end
end

function ESP:ToggleSkeleton(enable)
    self.State.ShowSkeleton = enable
    -- Можно реализовать позже
end

function ESP:Destroy()
    self:StopLoop()
    self:Clear()
    if self.Folder then
        self.Folder:Destroy()
    end
end

return ESP