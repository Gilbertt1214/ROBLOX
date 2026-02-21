--[[
    SettingsView Component
    Displays game settings with functional toggles and sliders
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local SoundService = game:GetService("SoundService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Roact = require(ReplicatedStorage.Shared.Roact)
local Theme = require(ReplicatedStorage.Shared.Theme)
local ResponsiveUtil = require(ReplicatedStorage.Shared.ResponsiveUtil)

-- Try to load DayNightCycle module
local DayNightCycle = nil
pcall(function()
    DayNightCycle = require(ReplicatedStorage.Shared.DayNightCycle)
end)

local SettingsView = {}

-- Graphics preset configurations
local GraphicsPresets = {
    low = {
        shadows = false,
        particles = false,
        bloom = false,
        sunRays = false,
        clouds = false
    },
    mid = {
        shadows = true,
        particles = true,
        bloom = true,
        sunRays = false,
        clouds = true
    },
    high = {
        shadows = true,
        particles = true,
        bloom = true,
        sunRays = true,
        clouds = true
    }
}

-- Apply graphics preset
local function applyGraphicsPreset(preset)
    local config = GraphicsPresets[preset]
    if not config then return end
    
    -- print("[Settings] Applying graphics preset:", preset)
    
    -- Shadows
    Lighting.GlobalShadows = config.shadows
    
    -- Particles
    for _, particle in pairs(workspace:GetDescendants()) do
        if particle:IsA("ParticleEmitter") or particle:IsA("Fire") or particle:IsA("Smoke") or particle:IsA("Sparkles") then
            particle.Enabled = config.particles
        end
    end
    
    -- Bloom
    local bloom = Lighting:FindFirstChildOfClass("BloomEffect")
    if bloom then bloom.Enabled = config.bloom end
    
    -- Sun Rays
    local sunRays = Lighting:FindFirstChildOfClass("SunRaysEffect")
    if sunRays then sunRays.Enabled = config.sunRays end
    if DayNightCycle then DayNightCycle.SetSunRaysEnabled(config.sunRays) end
    
    -- Clouds
    local clouds = Lighting:FindFirstChildOfClass("Clouds")
    if clouds then clouds.Enabled = config.clouds end
    if DayNightCycle then DayNightCycle.SetCloudsEnabled(config.clouds) end
end

-- Apply settings to game
local function applySettings(settingKey, value)
    -- print("[Settings] Applying:", settingKey, "=", value)
    local LocalPlayer = Players.LocalPlayer
    
    if settingKey == "graphicsPreset" then
        applyGraphicsPreset(value)
        
    elseif settingKey == "shadows" then
        -- Toggle advanced shadows
        if Lighting:FindFirstChildOfClass("ShadowMap") then
            Lighting.GlobalShadows = value
        end
        Lighting.GlobalShadows = value
        
    elseif settingKey == "sfx" then
        -- Toggle sound effects
        local sfxGroup = SoundService:FindFirstChild("SFX") or SoundService:FindFirstChild("Effects")
        if sfxGroup then
            sfxGroup.Volume = value and 1 or 0
        end
        -- Also mute all sounds tagged as SFX
        for _, sound in pairs(workspace:GetDescendants()) do
            if sound:IsA("Sound") and sound:GetAttribute("IsSFX") then
                sound.Volume = value and sound:GetAttribute("OriginalVolume") or 0
            end
        end
        
    elseif settingKey == "music" then
        -- Toggle music
        local musicGroup = SoundService:FindFirstChild("Music") or SoundService:FindFirstChild("BGM")
        if musicGroup then
            musicGroup.Volume = value and 1 or 0
        end
        -- Also control workspace music
        for _, sound in pairs(workspace:GetDescendants()) do
            if sound:IsA("Sound") and sound:GetAttribute("IsMusic") then
                sound.Volume = value and sound:GetAttribute("OriginalVolume") or 0
            end
        end
        
    elseif settingKey == "masterVolume" then
        -- Master volume (0-1)
        SoundService.AmbientReverb = Enum.ReverbType.NoReverb
        -- Apply to all sound groups
        for _, child in pairs(SoundService:GetChildren()) do
            if child:IsA("SoundGroup") then
                child.Volume = value
            end
        end
        
    elseif settingKey == "graphics" then
        -- Graphics quality (1-10)
        settings().Rendering.QualityLevel = value
        
    elseif settingKey == "particles" then
        -- Toggle particles
        for _, particle in pairs(workspace:GetDescendants()) do
            if particle:IsA("ParticleEmitter") or particle:IsA("Fire") or particle:IsA("Smoke") or particle:IsA("Sparkles") then
                particle.Enabled = value
            end
        end
        
    elseif settingKey == "bloom" then
        -- Toggle bloom effect
        local bloom = Lighting:FindFirstChildOfClass("BloomEffect")
        if bloom then
            bloom.Enabled = value
        end
        
    elseif settingKey == "blur" then
        -- Toggle blur effect
        local blur = Lighting:FindFirstChildOfClass("BlurEffect")
        if blur then
            blur.Enabled = value
        end
        
    elseif settingKey == "colorCorrection" then
        -- Toggle color correction
        local cc = Lighting:FindFirstChildOfClass("ColorCorrectionEffect")
        if cc then
            cc.Enabled = value
        end
        
    elseif settingKey == "sunRays" then
        -- Toggle sun rays
        local sunRays = Lighting:FindFirstChildOfClass("SunRaysEffect")
        if sunRays then
            sunRays.Enabled = value
        end
        -- Also update DayNightCycle if available
        if DayNightCycle then
            DayNightCycle.SetSunRaysEnabled(value)
        end
        
    elseif settingKey == "dayNightCycle" then
        -- Toggle day-night cycle
        if DayNightCycle then
            DayNightCycle.SetEnabled(value)
        end
        
    elseif settingKey == "timeSpeed" then
        -- Set time speed (0.0001 to 0.01)
        if DayNightCycle then
            DayNightCycle.SetTimeSpeed(value)
        end
        
    elseif settingKey == "clouds" then
        -- Toggle clouds
        local clouds = Lighting:FindFirstChildOfClass("Clouds")
        if clouds then
            clouds.Enabled = value
        end
        if DayNightCycle then
            DayNightCycle.SetCloudsEnabled(value)
        end
        
    elseif settingKey == "fov" then
        -- Field of view (60-120)
        local camera = workspace.CurrentCamera
        if camera then
            camera.FieldOfView = value
        end
        
    elseif settingKey == "cameraSensitivity" then
        -- Camera sensitivity
        UserInputService.MouseDeltaSensitivity = value
        
    elseif settingKey == "showPlayerInfo" then
        -- Show/hide player overhead info (username, role, streak) except nickname
        -- This is client-side only - affects what YOU see on other players
        local function updatePlayerOverhead(player)
            if player == Players.LocalPlayer then return end
            if not player.Character then return end
            
            local head = player.Character:FindFirstChild("Head")
            if not head then return end
            
            local overheadGui = head:FindFirstChild("OverheadGui")
            if not overheadGui then return end
            
            local container = overheadGui:FindFirstChild("Container")
            if not container then return end
            
            -- Hide/show username
            local usernameLabel = container:FindFirstChild("Username")
            if usernameLabel then
                usernameLabel.Visible = value
            end
            
            -- Hide/show role
            local roleLabel = container:FindFirstChild("Role")
            if roleLabel then
                roleLabel.Visible = value
            end
            
            -- Hide/show streak (fire icon and number in NameRow)
            local nameRow = container:FindFirstChild("NameRow")
            if nameRow then
                local fireIcon = nameRow:FindFirstChild("FireIcon")
                local streakNum = nameRow:FindFirstChild("StreakNum")
                if fireIcon then fireIcon.Visible = value end
                if streakNum then streakNum.Visible = value end
            end
            
            -- Also check StreakRow (when names are hidden)
            local streakRow = container:FindFirstChild("StreakRow")
            if streakRow then
                streakRow.Visible = value
            end
        end
        
        -- Apply to all current players
        for _, player in pairs(Players:GetPlayers()) do
            updatePlayerOverhead(player)
        end
        
        -- Store setting globally for new players
        _G.ShowPlayerInfoSetting = value
        
        -- Setup listener for new players and character respawns
        if not _G.ShowPlayerInfoListenerSetup then
            _G.ShowPlayerInfoListenerSetup = true
            
            Players.PlayerAdded:Connect(function(player)
                player.CharacterAdded:Connect(function()
                    task.wait(1) -- Wait for overhead to be created
                    if _G.ShowPlayerInfoSetting == false then
                        updatePlayerOverhead(player)
                    end
                end)
            end)
            
            -- Also listen for existing players' character respawns
            for _, player in pairs(Players:GetPlayers()) do
                if player ~= Players.LocalPlayer then
                    player.CharacterAdded:Connect(function()
                        task.wait(1)
                        if _G.ShowPlayerInfoSetting == false then
                            updatePlayerOverhead(player)
                        end
                    end)
                end
            end
        end
        
    elseif settingKey == "showPlayerNames" then
        -- Legacy - redirect to showPlayerInfo
        applySettings("showPlayerInfo", value)
        
    elseif settingKey == "fullscreen" then
        -- Note: Fullscreen is controlled by Roblox client, not scriptable
        -- print("[Settings] Fullscreen toggle - controlled by Roblox client (F11)")
    end
end

local function createToggleSetting(props)
    local label = props.label
    local description = props.description
    local enabled = props.enabled or false
    local onToggle = props.onToggle
    local layoutOrder = props.layoutOrder or 0
    
    return Roact.createElement("Frame", {
        Size = UDim2.new(1, 0, 0, description and 55 or 40),
        BackgroundColor3 = Theme.BackgroundLight,
        BackgroundTransparency = 0.7,
        LayoutOrder = layoutOrder
    }, {
        Corner = Roact.createElement("UICorner", { CornerRadius = UDim.new(0, 8) }),
        Padding = Roact.createElement("UIPadding", {
            PaddingLeft = UDim.new(0, 12),
            PaddingRight = UDim.new(0, 12)
        }),
        
        Label = Roact.createElement("TextLabel", {
            Size = UDim2.new(0.7, 0, 0, 20),
            Position = UDim2.new(0, 0, 0, description and 8 or 10),
            Text = label,
            TextColor3 = Theme.TextPrimary,
            TextSize = 14,
            Font = Theme.FontMedium,
            TextXAlignment = Enum.TextXAlignment.Left,
            BackgroundTransparency = 1
        }),
        
        Description = description and Roact.createElement("TextLabel", {
            Size = UDim2.new(0.7, 0, 0, 14),
            Position = UDim2.new(0, 0, 0, 28),
            Text = description,
            TextColor3 = Theme.TextMuted,
            TextSize = 10,
            Font = Theme.FontRegular,
            TextXAlignment = Enum.TextXAlignment.Left,
            BackgroundTransparency = 1
        }) or nil,
        
        ToggleButtonBG = Roact.createElement("TextButton", {
            Size = UDim2.new(0, 48, 0, 26),
            Position = UDim2.new(1, -12, 0.5, 0),
            AnchorPoint = Vector2.new(1, 0.5),
            BackgroundColor3 = enabled and Theme.Primary or Theme.BackgroundCard,
            Text = "",
            Event = {
                MouseButton1Click = function(rbx)
                    if onToggle then onToggle(not enabled) end
                    -- Click animation
                    TweenService:Create(rbx, TweenInfo.new(0.1), {
                        Size = UDim2.new(0, 44, 0, 24)
                    }):Play()
                    task.delay(0.1, function()
                        TweenService:Create(rbx, TweenInfo.new(0.15, Enum.EasingStyle.Back), {
                            Size = UDim2.new(0, 48, 0, 26)
                        }):Play()
                    end)
                end,
                MouseEnter = function(rbx)
                    TweenService:Create(rbx, TweenInfo.new(0.1), {
                        Size = UDim2.new(0, 50, 0, 28)
                    }):Play()
                end,
                MouseLeave = function(rbx)
                    TweenService:Create(rbx, TweenInfo.new(0.1), {
                        Size = UDim2.new(0, 48, 0, 26)
                    }):Play()
                end
            }
        }, {
            Corner = Roact.createElement("UICorner", { CornerRadius = UDim.new(1, 0) }),
            Knob = Roact.createElement("Frame", {
                Size = UDim2.new(0, 20, 0, 20),
                Position = UDim2.new(enabled and 1 or 0, enabled and -3 or 3, 0.5, 0),
                AnchorPoint = Vector2.new(enabled and 1 or 0, 0.5),
                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            }, {
                Corner = Roact.createElement("UICorner", { CornerRadius = UDim.new(1, 0) })
            })
        })
    })
end

local function createSliderSetting(props)
    local label = props.label
    local value = props.value or 0.5
    local minVal = props.min or 0
    local maxVal = props.max or 1
    local suffix = props.suffix or ""
    local onValueChanged = props.onValueChanged
    local layoutOrder = props.layoutOrder or 0
    
    local percentage = (value - minVal) / (maxVal - minVal)
    local displayValue = math.floor(value * 100) / 100
    if suffix == "%" then
        displayValue = math.floor(value * 100)
    elseif suffix == "°" then
        displayValue = math.floor(value)
    end
    
    return Roact.createElement("Frame", {
        Size = UDim2.new(1, 0, 0, 55),
        BackgroundColor3 = Theme.BackgroundLight,
        BackgroundTransparency = 0.7,
        LayoutOrder = layoutOrder
    }, {
        Corner = Roact.createElement("UICorner", { CornerRadius = UDim.new(0, 8) }),
        Padding = Roact.createElement("UIPadding", {
            PaddingLeft = UDim.new(0, 12),
            PaddingRight = UDim.new(0, 12)
        }),
        
        Label = Roact.createElement("TextLabel", {
            Size = UDim2.new(0.6, 0, 0, 20),
            Position = UDim2.new(0, 0, 0, 8),
            Text = label,
            TextColor3 = Theme.TextPrimary,
            TextSize = 14,
            Font = Theme.FontMedium,
            TextXAlignment = Enum.TextXAlignment.Left,
            BackgroundTransparency = 1
        }),
        
        ValueLabel = Roact.createElement("TextLabel", {
            Size = UDim2.new(0.3, 0, 0, 20),
            Position = UDim2.new(1, -12, 0, 8),
            AnchorPoint = Vector2.new(1, 0),
            Text = tostring(displayValue) .. suffix,
            TextColor3 = Theme.Primary,
            TextSize = 14,
            Font = Theme.FontBold,
            TextXAlignment = Enum.TextXAlignment.Right,
            BackgroundTransparency = 1
        }),
        
        -- Minus button
        MinusBtn = Roact.createElement("TextButton", {
            Size = UDim2.new(0, 24, 0, 24),
            Position = UDim2.new(0, 0, 0, 28),
            BackgroundColor3 = Theme.BackgroundCard,
            Text = "−",
            TextColor3 = Theme.TextPrimary,
            TextSize = 18,
            Font = Theme.FontBold,
            Event = {
                MouseButton1Click = function()
                    local step = (maxVal - minVal) / 10
                    local newVal = math.clamp(value - step, minVal, maxVal)
                    if onValueChanged then onValueChanged(newVal) end
                end
            }
        }, {
            Corner = Roact.createElement("UICorner", { CornerRadius = UDim.new(0, 6) })
        }),
        
        SliderBg = Roact.createElement("TextButton", {
            Size = UDim2.new(1, -70, 0, 12),
            Position = UDim2.new(0, 30, 0, 34),
            BackgroundColor3 = Theme.BackgroundCard,
            Text = "",
            AutoButtonColor = false,
            Event = {
                MouseButton1Click = function(rbx)
                    local mousePos = UserInputService:GetMouseLocation()
                    local relativeX = mousePos.X - rbx.AbsolutePosition.X
                    local pct = math.clamp(relativeX / rbx.AbsoluteSize.X, 0, 1)
                    local newVal = minVal + (maxVal - minVal) * pct
                    if onValueChanged then onValueChanged(newVal) end
                end
            }
        }, {
            Corner = Roact.createElement("UICorner", { CornerRadius = UDim.new(1, 0) }),
            Fill = Roact.createElement("Frame", {
                Size = UDim2.new(percentage, 0, 1, 0),
                BackgroundColor3 = Theme.Primary
            }, {
                Corner = Roact.createElement("UICorner", { CornerRadius = UDim.new(1, 0) })
            }),
            Knob = Roact.createElement("Frame", {
                Size = UDim2.new(0, 16, 0, 16),
                Position = UDim2.new(percentage, 0, 0.5, 0),
                AnchorPoint = Vector2.new(0.5, 0.5),
                BackgroundColor3 = Color3.new(1, 1, 1)
            }, {
                Corner = Roact.createElement("UICorner", { CornerRadius = UDim.new(1, 0) })
            })
        }),
        
        -- Plus button
        PlusBtn = Roact.createElement("TextButton", {
            Size = UDim2.new(0, 24, 0, 24),
            Position = UDim2.new(1, -12, 0, 28),
            AnchorPoint = Vector2.new(1, 0),
            BackgroundColor3 = Theme.BackgroundCard,
            Text = "+",
            TextColor3 = Theme.TextPrimary,
            TextSize = 18,
            Font = Theme.FontBold,
            Event = {
                MouseButton1Click = function()
                    local step = (maxVal - minVal) / 10
                    local newVal = math.clamp(value + step, minVal, maxVal)
                    if onValueChanged then onValueChanged(newVal) end
                end
            }
        }, {
            Corner = Roact.createElement("UICorner", { CornerRadius = UDim.new(0, 6) })
        })
    })
end

local function createSectionHeader(props)
    return Roact.createElement("TextLabel", {
        Size = UDim2.new(1, 0, 0, 30),
        BackgroundTransparency = 1,
        Text = props.text,
        TextColor3 = Theme.Primary,
        TextSize = 12,
        Font = Theme.FontBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        LayoutOrder = props.layoutOrder or 0
    })
end

local function createGraphicsPresetSelector(props)
    local currentPreset = props.currentPreset or "mid"
    local onPresetChange = props.onPresetChange
    local layoutOrder = props.layoutOrder or 0
    
    local presets = {
        { id = "low", label = "LOW", desc = "Best performance" },
        { id = "mid", label = "MID", desc = "Balanced" },
        { id = "high", label = "HIGH", desc = "Best quality" }
    }
    
    local buttons = {}
    for i, preset in ipairs(presets) do
        local isActive = currentPreset == preset.id
        buttons["Btn" .. i] = Roact.createElement("TextButton", {
            Size = UDim2.new(1/3, -6, 1, 0),
            Position = UDim2.new((i-1)/3, 3, 0, 0),
            BackgroundColor3 = isActive and Theme.Primary or Theme.BackgroundCard,
            Text = "",
            AutoButtonColor = false,
            Event = {
                MouseButton1Click = function(rbx)
                    if onPresetChange then onPresetChange(preset.id) end
                    -- Click animation
                    TweenService:Create(rbx, TweenInfo.new(0.1), {
                        Size = UDim2.new(1/3, -10, 0.9, 0)
                    }):Play()
                    task.delay(0.1, function()
                        TweenService:Create(rbx, TweenInfo.new(0.15, Enum.EasingStyle.Back), {
                            Size = UDim2.new(1/3, -6, 1, 0)
                        }):Play()
                    end)
                end,
                MouseEnter = function(rbx)
                    if not isActive then
                        TweenService:Create(rbx, TweenInfo.new(0.1), {
                            BackgroundColor3 = Theme.BackgroundLight
                        }):Play()
                    end
                end,
                MouseLeave = function(rbx)
                    if not isActive then
                        TweenService:Create(rbx, TweenInfo.new(0.1), {
                            BackgroundColor3 = Theme.BackgroundCard
                        }):Play()
                    end
                end
            }
        }, {
            Corner = Roact.createElement("UICorner", { CornerRadius = UDim.new(0, 8) }),
            Label = Roact.createElement("TextLabel", {
                Size = UDim2.new(1, 0, 0, 20),
                Position = UDim2.new(0, 0, 0, 8),
                Text = preset.label,
                TextColor3 = isActive and Color3.new(1,1,1) or Theme.TextPrimary,
                TextSize = 14,
                Font = Theme.FontBold,
                BackgroundTransparency = 1
            }),
            Desc = Roact.createElement("TextLabel", {
                Size = UDim2.new(1, 0, 0, 12),
                Position = UDim2.new(0, 0, 0, 28),
                Text = preset.desc,
                TextColor3 = isActive and Color3.fromRGB(200,200,200) or Theme.TextMuted,
                TextSize = 10,
                Font = Theme.FontRegular,
                BackgroundTransparency = 1
            })
        })
    end
    
    return Roact.createElement("Frame", {
        Size = UDim2.new(1, 0, 0, 70),
        BackgroundColor3 = Theme.BackgroundLight,
        BackgroundTransparency = 0.7,
        LayoutOrder = layoutOrder
    }, {
        Corner = Roact.createElement("UICorner", { CornerRadius = UDim.new(0, 8) }),
        Padding = Roact.createElement("UIPadding", {
            PaddingLeft = UDim.new(0, 8),
            PaddingRight = UDim.new(0, 8),
            PaddingTop = UDim.new(0, 8),
            PaddingBottom = UDim.new(0, 8)
        }),
        ButtonContainer = Roact.createElement("Frame", {
            Size = UDim2.new(1, 0, 0, 50),
            BackgroundTransparency = 1
        }, buttons)
    })
end

function SettingsView.create(props)
    local settings = props.settings or {
        music = true,
        sfx = true,
        shadows = true,
        particles = true,
        bloom = true,
        sunRays = true,
        clouds = true,
        showPlayerInfo = true,
        masterVolume = 0.8,
        fov = 70,
        hideStreak = false,
        hideUsername = false,
        graphicsPreset = "mid",
        dayNightCycle = true,
        timeSpeed = 0.001
    }
    local onSettingChanged = props.onSettingChanged
    
    local isPhone = ResponsiveUtil.isPhone()
    local isMobile = ResponsiveUtil.isMobile()
    
    -- Responsive sizes - smaller for phone
    local panelWidth = isPhone and 260 or (isMobile and 320 or 400)
    local panelHeight = isPhone and 320 or (isMobile and 380 or 460)
    
    local function handleChange(key, value)
        -- print("[Settings] Changing:", key, "to", value)
        -- Apply setting immediately
        applySettings(key, value)
        -- Notify parent
        if onSettingChanged then
            onSettingChanged(key, value)
        end
    end
    
    local children = {
        Layout = Roact.createElement("UIListLayout", {
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 8)
        }),
        
        -- Audio Section
        AudioHeader = createSectionHeader({ text = "AUDIO", layoutOrder = 1 }),
        
        MasterVolume = createSliderSetting({
            label = "Master Volume",
            value = settings.masterVolume or 0.8,
            min = 0,
            max = 1,
            suffix = "%",
            onValueChanged = function(val) handleChange("masterVolume", val) end,
            layoutOrder = 2
        }),
        
        Music = createToggleSetting({
            label = "Music",
            description = "Background music",
            enabled = settings.music,
            onToggle = function(val) handleChange("music", val) end,
            layoutOrder = 3
        }),
        
        SFX = createToggleSetting({
            label = "Sound Effects",
            description = "Game sound effects",
            enabled = settings.sfx,
            onToggle = function(val) handleChange("sfx", val) end,
            layoutOrder = 4
        }),
        
        -- Graphics Section
        GraphicsHeader = createSectionHeader({ text = "GRAPHICS", layoutOrder = 10 }),
        
        GraphicsPreset = createGraphicsPresetSelector({
            currentPreset = settings.graphicsPreset or "mid",
            onPresetChange = function(preset) handleChange("graphicsPreset", preset) end,
            layoutOrder = 11
        }),
        
        Shadows = createToggleSetting({
            label = "Shadows",
            description = "Enable global shadows",
            enabled = settings.shadows ~= false,
            onToggle = function(val) handleChange("shadows", val) end,
            layoutOrder = 12
        }),
        
        Particles = createToggleSetting({
            label = "Particles",
            description = "Enable particle effects",
            enabled = settings.particles ~= false,
            onToggle = function(val) handleChange("particles", val) end,
            layoutOrder = 13
        }),
        
        Bloom = createToggleSetting({
            label = "Bloom",
            description = "Enable bloom lighting effect",
            enabled = settings.bloom ~= false,
            onToggle = function(val) handleChange("bloom", val) end,
            layoutOrder = 14
        }),
        
        SunRays = createToggleSetting({
            label = "Sun Rays",
            description = "Enable sun rays effect",
            enabled = settings.sunRays ~= false,
            onToggle = function(val) handleChange("sunRays", val) end,
            layoutOrder = 15
        }),
        
        Clouds = createToggleSetting({
            label = "Clouds",
            description = "Enable cloud rendering",
            enabled = settings.clouds ~= false,
            onToggle = function(val) handleChange("clouds", val) end,
            layoutOrder = 16
        }),
        
        -- Day/Night Section
        DayNightHeader = createSectionHeader({ text = "DAY/NIGHT CYCLE", layoutOrder = 20 }),
        
        DayNightCycle = createToggleSetting({
            label = "Day-Night Cycle",
            description = "Enable automatic time progression",
            enabled = settings.dayNightCycle ~= false,
            onToggle = function(val) handleChange("dayNightCycle", val) end,
            layoutOrder = 21
        }),
        
        TimeSpeed = createSliderSetting({
            label = "Time Speed",
            value = settings.timeSpeed or 0.001,
            min = 0.0001,
            max = 0.01,
            suffix = "x",
            onValueChanged = function(val) handleChange("timeSpeed", val) end,
            layoutOrder = 22
        }),
        
        -- Gameplay Section
        GameplayHeader = createSectionHeader({ text = "GAMEPLAY", layoutOrder = 30 }),
        
        FOV = createSliderSetting({
            label = "Field of View",
            value = settings.fov or 70,
            min = 60,
            max = 120,
            suffix = "°",
            onValueChanged = function(val) handleChange("fov", val) end,
            layoutOrder = 31
        }),
        
        ShowPlayerInfo = createToggleSetting({
            label = "Show Player Info",
            description = "Show @username, role, streak above other players",
            enabled = settings.showPlayerInfo ~= false,
            onToggle = function(val) handleChange("showPlayerInfo", val) end,
            layoutOrder = 32
        }),
        
        -- Privacy Section
        PrivacyHeader = createSectionHeader({ text = "PRIVACY", layoutOrder = 40 }),
        
        HideStreak = createToggleSetting({
            label = "Hide My Streak",
            description = "Hide your login streak from other players",
            enabled = settings.hideStreak == true,
            onToggle = function(val) handleChange("hideStreak", val) end,
            layoutOrder = 41
        }),
        
        HideUsername = createToggleSetting({
            label = "Hide My Username",
            description = "Hide your @username from other players",
            enabled = settings.hideUsername == true,
            onToggle = function(val) handleChange("hideUsername", val) end,
            layoutOrder = 42
        }),
        
        DisableTeleport = createToggleSetting({
            label = "Disable Teleport",
            description = "Prevent other players from teleporting to you",
            enabled = settings.disableTeleport == true,
            onToggle = function(val) handleChange("disableTeleport", val) end,
            layoutOrder = 43
        }),
    }
    
    return Roact.createElement("Frame", {
        Name = "SettingsView",
        Size = UDim2.new(0, panelWidth, 0, panelHeight),
        Position = UDim2.new(0.5, 0, 0.5, isPhone and -30 or -40),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = Theme.Background,
        BackgroundTransparency = 0.05,
    }, {
        Corner = Roact.createElement("UICorner", { CornerRadius = UDim.new(0, isPhone and 12 or 16) }),
        Stroke = Roact.createElement("UIStroke", {
            Color = Theme.Primary,
            Thickness = isPhone and 1 or 2,
            Transparency = 0.5
        }),
        
        Title = Roact.createElement("TextLabel", {
            Size = UDim2.new(1, 0, 0, isPhone and 36 or 46),
            Text = "SETTINGS",
            TextColor3 = Theme.TextPrimary,
            TextSize = ResponsiveUtil.getSizes().fontSize.title,
            Font = Theme.FontBold,
            BackgroundTransparency = 1
        }),
        
        Container = Roact.createElement("ScrollingFrame", {
            Size = UDim2.new(1, -20, 1, isPhone and -46 or -66),
            Position = UDim2.new(0, 10, 0, isPhone and 40 or 52),
            BackgroundTransparency = 1,
            ScrollBarThickness = 3,
            ScrollBarImageColor3 = Theme.Primary,
            CanvasSize = UDim2.new(0, 0, 0, 0),
            AutomaticCanvasSize = Enum.AutomaticSize.Y
        }, children)
    })
end

return SettingsView
