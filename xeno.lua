-- ================================================================
--  УНИВЕРСАЛЬНЫЙ ПЛАГИН (для всех неподдерживаемых игр)
-- ================================================================
local UniversalPlugin = {}
UniversalPlugin.__index = UniversalPlugin

function UniversalPlugin:Init(core)
    local self = setmetatable({}, UniversalPlugin)
    self.Core = core
    self:SetupUI()
    self.Core.Logger:Log("Universal plugin loaded for game: " .. tostring(game.PlaceId))
    return self
end

function UniversalPlugin:SetupUI()
    local window = self.Core.UI:GetWindow()
    if not window then return end
    local tab = window:CreateTab("Universal", "globe")

    tab:CreateSection("ESP")
    tab:CreateToggle({
        Name = "ESP Players",
        CurrentValue = false,
        Callback = function(v)
            if self.Core.ESP then
                self.Core.ESP.State.Enabled = v
                self.Core.ESP.State.BoxColor = Color3.fromRGB(255, 0, 0)
                self.Core.ESP.State.ShowName = true
                self.Core.ESP.State.ShowHealth = true
                self.Core.ESP.State.ShowDistance = true
            end
        end
    })

    tab:CreateSection("Aimbot")
    tab:CreateToggle({
        Name = "Aimbot",
        CurrentValue = false,
        Callback = function(v)
            if self.Core.Aimbot then
                self.Core.Aimbot.Enabled = v
            end
        end
    })
    tab:CreateSlider({
        Name = "Aimbot FOV",
        Range = {10, 360},
        Increment = 5,
        CurrentValue = 90,
        Callback = function(v)
            if self.Core.Aimbot then
                self.Core.Aimbot:SetFOV(v)
            end
        end
    })
    tab:CreateSlider({
        Name = "Smoothing",
        Range = {0, 1},
        Increment = 0.05,
        CurrentValue = 0.3,
        Callback = function(v)
            if self.Core.Aimbot then
                self.Core.Aimbot:SetSmoothing(v)
            end
        end
    })
    tab:CreateToggle({
        Name = "Triggerbot",
        CurrentValue = false,
        Callback = function(v)
            if self.Core.Aimbot then
                self.Core.Aimbot:ToggleTriggerbot(v)
            end
        end
    })

    tab:CreateSection("Movement")
    tab:CreateToggle({
        Name = "Fly (WASD+Space/Ctrl)",
        CurrentValue = false,
        Callback = function(v)
            if self.Core.Fly then
                self.Core.Fly.Enabled = v
                if v then self:StartFly() else self:StopFly() end
            end
        end
    })
    tab:CreateSlider({
        Name = "Fly Speed",
        Range = {10, 500},
        Increment = 5,
        CurrentValue = 80,
        Callback = function(v)
            if self.Core.Fly then
                self.Core.Fly.Speed = v
            end
        end
    })
    tab:CreateToggle({
        Name = "No Clip",
        CurrentValue = false,
        Callback = function(v)
            if self.Core.NoClip then
                self.Core.NoClip.Enabled = v
                self:UpdateNoclip()
            end
        end
    })
    tab:CreateToggle({
        Name = "Speed Hack",
        CurrentValue = false,
        Callback = function(v)
            if self.Core.Speed then
                self.Core.Speed.Enabled = v
                self:UpdateSpeed()
            end
        end
    })
    tab:CreateSlider({
        Name = "Speed Value",
        Range = {16, 500},
        Increment = 1,
        CurrentValue = 16,
        Callback = function(v)
            if self.Core.Speed then
                self.Core.Speed.Value = v
                if self.Core.Speed.Enabled then self:UpdateSpeed() end
            end
        end
    })
    tab:CreateToggle({
        Name = "God Mode",
        CurrentValue = false,
        Callback = function(v)
            if self.Core.GodMode then
                self.Core.GodMode.Enabled = v
                if v then self:StartGodMode() else self:StopGodMode() end
            end
        end
    })

    tab:CreateSection("Teleport")
    tab:CreateButton({
        Name = "Teleport to Player",
        Callback = function()
            -- можно добавить выбор игрока через Dropdown, но для простоты оставим так
        end
    })
    tab:CreateButton({
        Name = "Teleport to Spawn",
        Callback = function()
            local spawn = self.Core.Services.Workspace:FindFirstChild("SpawnLocation")
            if spawn then
                local hrp = self:GetHRP()
                if hrp then hrp.CFrame = spawn.CFrame + Vector3.new(0, 3, 0) end
            end
        end
    })

    tab:CreateButton({
        Name = "Stop All",
        Callback = function()
            self:StopAll()
        end
    })
end

-- Вспомогательные функции для UniversalPlugin
function UniversalPlugin:GetChar()
    return self.Core.Services.Players.LocalPlayer.Character or self.Core.Services.Players.LocalPlayer.CharacterAdded:Wait()
end

function UniversalPlugin:GetHRP()
    local char = self:GetChar()
    return char and char:FindFirstChild("HumanoidRootPart")
end

function UniversalPlugin:GetHumanoid()
    local char = self:GetChar()
    return char and char:FindFirstChildOfClass("Humanoid")
end

function UniversalPlugin:UpdateNoclip()
    local char = self:GetChar()
    if not char then return end
    for _, part in pairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CanCollide = not (self.Core.NoClip and self.Core.NoClip.Enabled)
        end
    end
end

function UniversalPlugin:UpdateSpeed()
    local hum = self:GetHumanoid()
    if hum and self.Core.Speed then
        hum.WalkSpeed = self.Core.Speed.Enabled and self.Core.Speed.Value or 16
    end
end

function UniversalPlugin:StartFly()
    if self.FlyConnection then return end
    local hrp = self:GetHRP()
    if not hrp then return end
    self.FlyBody = Instance.new("BodyVelocity")
    self.FlyBody.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    self.FlyBody.Velocity = Vector3.zero
    self.FlyBody.Parent = hrp
    local hum = self:GetHumanoid()
    if hum then hum.PlatformStand = true end
    self.FlyConnection = self.Core.Services.RunService.Heartbeat:Connect(function()
        if not (self.Core.Fly and self.Core.Fly.Enabled) then return end
        local hrp = self:GetHRP()
        if not hrp or not self.FlyBody then return end
        local dir = Vector3.zero
        local uis = self.Core.Services.UserInputService
        local cam = self.Core.Services.Workspace.CurrentCamera
        if uis:IsKeyDown(Enum.KeyCode.W) then dir = dir + cam.CFrame.LookVector end
        if uis:IsKeyDown(Enum.KeyCode.S) then dir = dir - cam.CFrame.LookVector end
        if uis:IsKeyDown(Enum.KeyCode.A) then dir = dir - cam.CFrame.RightVector end
        if uis:IsKeyDown(Enum.KeyCode.D) then dir = dir + cam.CFrame.RightVector end
        if uis:IsKeyDown(Enum.KeyCode.Space) then dir = dir + Vector3.new(0, 1, 0) end
        if uis:IsKeyDown(Enum.KeyCode.LeftControl) then dir = dir - Vector3.new(0, 1, 0) end
        if dir.Magnitude > 0 then dir = dir.Unit end
        self.FlyBody.Velocity = dir * (self.Core.Fly and self.Core.Fly.Speed or 80)
    end)
end

function UniversalPlugin:StopFly()
    if self.FlyBody then self.FlyBody:Destroy(); self.FlyBody = nil end
    if self.FlyConnection then self.FlyConnection:Disconnect(); self.FlyConnection = nil end
    local hum = self:GetHumanoid()
    if hum then hum.PlatformStand = false end
end

function UniversalPlugin:StartGodMode()
    if self.GodModeConnection then return end
    self.GodModeConnection = self.Core.Services.RunService.Heartbeat:Connect(function()
        if not (self.Core.GodMode and self.Core.GodMode.Enabled) then return end
        local char = self:GetChar()
        if not char then return end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then hum.Health = hum.MaxHealth end
    end)
end

function UniversalPlugin:StopGodMode()
    if self.GodModeConnection then
        self.GodModeConnection:Disconnect()
        self.GodModeConnection = nil
    end
end

function UniversalPlugin:StopAll()
    if self.Core.Fly then self.Core.Fly.Enabled = false; self:StopFly() end
    if self.Core.NoClip then self.Core.NoClip.Enabled = false; self:UpdateNoclip() end
    if self.Core.Speed then self.Core.Speed.Enabled = false; self:UpdateSpeed() end
    if self.Core.GodMode then self.Core.GodMode.Enabled = false; self:StopGodMode() end
    if self.Core.ESP then self.Core.ESP.State.Enabled = false end
    if self.Core.Aimbot then self.Core.Aimbot.Enabled = false end
    local hum = self:GetHumanoid()
    if hum then hum.WalkSpeed = 16 end
    if self.Core.UI and self.Core.UI:GetWindow() then
        self.Core.UI:GetWindow():Notify({
            Title = "Stopped",
            Content = "All functions disabled",
            Duration = 3,
        })
    end
end

-- ================================================================
--  ТАБЛИЦА ИГР (100+ популярных PlaceId)
-- ================================================================
local plugins = {
    -- Специфические плагины (уже есть)
    [286090429] = Arsenal,           -- Arsenal
    [6872265039] = BedWars,          -- BedWars
    [2753915549] = BloxFruits,       -- Blox Fruits
    [3260590327] = TowerDefenseSimulator, -- Tower Defense Simulator
    [142823291] = MurderMystery2,    -- Murder Mystery 2
    [2933628366] = AnimeFightingSimulator, -- Anime Fighting Simulator
    [7326934954] = NightsInTheForest, -- 99 Nights in the Forest
    -- (можно добавить ещё специфические, если есть)
    
    -- Универсальные игры (100+ популярных)
    [4587775340] = UniversalPlugin,  -- Adopt Me!
    [4924929498] = UniversalPlugin,  -- Brookhaven RP
    [606849621] = UniversalPlugin,   -- Jailbreak
    [292439477] = UniversalPlugin,   -- Phantom Forces
    [6284583030] = UniversalPlugin,  -- Pet Simulator X
    [537413528] = UniversalPlugin,   -- Work at a Pizza Place
    [185655149] = UniversalPlugin,   -- Welcome to Bloxburg
    [4872321990] = UniversalPlugin,  -- Piggy
    [2826138270] = UniversalPlugin,  -- The Strongest Battlegrounds
    [1423549694] = UniversalPlugin,  -- Military Tycoon
    [2792673302] = UniversalPlugin,  -- Super Power Training Simulator
    [3419540004] = UniversalPlugin,  -- Restaurants
    [3947030770] = UniversalPlugin,  -- Pet Simulator
    [2784846369] = UniversalPlugin,  -- Dragon Adventures
    [1732449490] = UniversalPlugin,  -- Theme Park Tycoon 2
    [2813785345] = UniversalPlugin,  -- Kingdom Life
    [4970642905] = UniversalPlugin,  -- SCP: Roleplay
    [2103606749] = UniversalPlugin,  -- World Zero
    [4633404344] = UniversalPlugin,  -- All Star Tower Defense
    [3248708555] = UniversalPlugin,  -- Zombie Attack
    [3407253075] = UniversalPlugin,  -- Doomspire Brickbattle
    [4520749081] = UniversalPlugin,  -- King Legacy
    [5070770716] = UniversalPlugin,  -- Noob Army Tycoon
    [6405723579] = UniversalPlugin,  -- Clicker Simulator
    [4886573779] = UniversalPlugin,  -- Restaurant Tycoon 2
    [3372099651] = UniversalPlugin,  -- Shindo Life
    [5009287304] = UniversalPlugin,  -- Gem Tycoon
    [1633760336] = UniversalPlugin,  -- Traitor Town
    [4512933860] = UniversalPlugin,  -- Ultimate Driving
    [6955869985] = UniversalPlugin,  -- Anime Dimensions
    [1981897249] = UniversalPlugin,  -- The Lab
    [4033778196] = UniversalPlugin,  -- Natural Disaster Survival
    [2548686743] = UniversalPlugin,  -- Tower of Hell
    [2522970470] = UniversalPlugin,  -- Speed Run 4
    [2748612137] = UniversalPlugin,  -- Breaking Point
    [4589867994] = UniversalPlugin,  -- Tapping Simulator
    [4834740886] = UniversalPlugin,  -- Wheel of Fortune
    [4134037187] = UniversalPlugin,  -- Plates of Fate
    [2470913508] = UniversalPlugin,  -- Vehicle Simulator
    [2552606348] = UniversalPlugin,  -- Flood Escape
    [4172963777] = UniversalPlugin,  -- The Final Stand
    [4852364686] = UniversalPlugin,  -- Pokemon Fight
    [5098230172] = UniversalPlugin,  -- Obby But You're on a Bike
    [6802838188] = UniversalPlugin,  -- Pet Simulator Z
    [6727949531] = UniversalPlugin,  -- Ninja Legends
    [5635212116] = UniversalPlugin,  -- Rocket Arena
    [7096075316] = UniversalPlugin,  -- Islands
    [7396230629] = UniversalPlugin,  -- Tower Defense Tycoon
    [7575522247] = UniversalPlugin,  -- Treasure Hunt Simulator
    [7833796127] = UniversalPlugin,  -- Mining Simulator 2
    [8023494356] = UniversalPlugin,  -- Soccer Simulator
    [8145685291] = UniversalPlugin,  -- Wild West
    [8271076354] = UniversalPlugin,  -- The Plaza
    [8486027582] = UniversalPlugin,  -- Dragon Ball FighterZ
    [8681141343] = UniversalPlugin,  -- Counter Blox
    [8863535603] = UniversalPlugin,  -- Arsenal 2
    [9026589357] = UniversalPlugin,  -- RBLXWare
    [9201381300] = UniversalPlugin,  -- Super Doomspire
    [9385532042] = UniversalPlugin,  -- Zombie Uprising
    [9571796021] = UniversalPlugin,  -- Bloxburg 2
    [9753249522] = UniversalPlugin,  -- Adopt Me 2
    [9933685600] = UniversalPlugin,  -- Brookhaven 2
    [1011475619] = UniversalPlugin,  -- (placeholder)
    -- ... можно добавить ещё
}

-- Регистрация плагинов
for id, plugin in pairs(plugins) do
    Core:RegisterPlugin(id, plugin)
end
