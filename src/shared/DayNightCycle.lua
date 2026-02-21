--[[
    DayNightCycle Module
    Ultra-Realistic Day-Night Cycle v2.0
    Can be controlled from Settings UI
]]

local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")

local DayNightCycle = {}

-- ========================================
-- ⚙️ CONFIGURATION (can be changed via Settings)
-- ========================================
DayNightCycle.Config = {
    Enabled = true,
    TimeSpeed = 0.001,
    EnableDynamicSky = true,
    EnableWeather = true,
    EnableBloom = true,
    EnableSunRays = true,
    EnableClouds = true,
}

-- ========================================
-- 🎨 TIME PRESETS
-- ========================================
local TIME_PRESETS = {
    MidnightBlue = {
        time = {0, 3},
        fogColor = Color3.fromRGB(15, 20, 45),
        ambient = Color3.fromRGB(25, 35, 60),
        outdoor = Color3.fromRGB(45, 60, 95),
        brightness = 1.0,
        fogStart = 20,
        fogEnd = 500,
        atmosphereColor = Color3.fromRGB(60, 80, 130),
        atmosphereDensity = 0.45,
        atmosphereHaze = 2.0,
        shadowSoftness = 0.5,
        bloomIntensity = 0.15,
        bloomThreshold = 0.85,
        sunRaysIntensity = 0.08,
        exposure = 0.05,
        cloudColor = Color3.fromRGB(80, 100, 140),
        starCount = 25000,
        colorCorrection = {
            brightness = 0.02,
            contrast = 0.12,
            saturation = 0.0,
            tint = Color3.fromRGB(180, 200, 240),
        }
    },
    PreDawn = {
        time = {3, 5},
        fogColor = Color3.fromRGB(80, 60, 100),
        ambient = Color3.fromRGB(50, 40, 70),
        outdoor = Color3.fromRGB(100, 80, 130),
        brightness = 0.8,
        fogStart = 30,
        fogEnd = 450,
        atmosphereColor = Color3.fromRGB(120, 100, 150),
        atmosphereDensity = 0.4,
        atmosphereHaze = 1.8,
        shadowSoftness = 0.45,
        bloomIntensity = 0.2,
        bloomThreshold = 0.8,
        sunRaysIntensity = 0.1,
        exposure = 0.1,
        cloudColor = Color3.fromRGB(120, 110, 160),
        starCount = 18000,
        colorCorrection = {
            brightness = 0.05,
            contrast = 0.1,
            saturation = 0.05,
            tint = Color3.fromRGB(200, 180, 220),
        }
    },
    GoldenDawn = {
        time = {5, 7},
        fogColor = Color3.fromRGB(255, 150, 100),
        ambient = Color3.fromRGB(120, 80, 90),
        outdoor = Color3.fromRGB(255, 190, 150),
        brightness = 1.5,
        fogStart = 40,
        fogEnd = 600,
        atmosphereColor = Color3.fromRGB(255, 170, 140),
        atmosphereDensity = 0.38,
        atmosphereHaze = 1.5,
        shadowSoftness = 0.35,
        bloomIntensity = 0.4,
        bloomThreshold = 0.75,
        sunRaysIntensity = 0.25,
        exposure = 0.25,
        cloudColor = Color3.fromRGB(255, 160, 110),
        starCount = 8000,
        colorCorrection = {
            brightness = 0.15,
            contrast = 0.08,
            saturation = 0.25,
            tint = Color3.fromRGB(255, 220, 180),
        }
    },
    CrispMorning = {
        time = {7, 10},
        fogColor = Color3.fromRGB(200, 220, 245),
        ambient = Color3.fromRGB(160, 180, 200),
        outdoor = Color3.fromRGB(230, 245, 255),
        brightness = 2.2,
        fogStart = 80,
        fogEnd = 1000,
        atmosphereColor = Color3.fromRGB(210, 230, 255),
        atmosphereDensity = 0.3,
        atmosphereHaze = 1.2,
        shadowSoftness = 0.25,
        bloomIntensity = 0.35,
        bloomThreshold = 0.88,
        sunRaysIntensity = 0.3,
        exposure = 0.05,
        cloudColor = Color3.fromRGB(245, 250, 255),
        starCount = 2000,
        colorCorrection = {
            brightness = 0.05,
            contrast = 0.1,
            saturation = 0.15,
            tint = Color3.fromRGB(255, 250, 245),
        }
    },
    BrightNoon = {
        time = {10, 15},
        fogColor = Color3.fromRGB(190, 225, 255),
        ambient = Color3.fromRGB(170, 190, 210),
        outdoor = Color3.fromRGB(240, 250, 255),
        brightness = 3.0,
        fogStart = 150,
        fogEnd = 1800,
        atmosphereColor = Color3.fromRGB(200, 230, 255),
        atmosphereDensity = 0.25,
        atmosphereHaze = 1.0,
        shadowSoftness = 0.15,
        bloomIntensity = 0.3,
        bloomThreshold = 0.92,
        sunRaysIntensity = 0.35,
        exposure = 0.15,
        cloudColor = Color3.fromRGB(255, 255, 255),
        starCount = 0,
        colorCorrection = {
            brightness = 0.1,
            contrast = 0.12,
            saturation = 0.18,
            tint = Color3.fromRGB(255, 255, 255),
        }
    },
    WarmAfternoon = {
        time = {15, 17},
        fogColor = Color3.fromRGB(255, 200, 160),
        ambient = Color3.fromRGB(180, 140, 120),
        outdoor = Color3.fromRGB(255, 230, 190),
        brightness = 2.5,
        fogStart = 100,
        fogEnd = 1200,
        atmosphereColor = Color3.fromRGB(255, 210, 170),
        atmosphereDensity = 0.3,
        atmosphereHaze = 1.3,
        shadowSoftness = 0.2,
        bloomIntensity = 0.38,
        bloomThreshold = 0.85,
        sunRaysIntensity = 0.4,
        exposure = 0.2,
        cloudColor = Color3.fromRGB(255, 240, 210),
        starCount = 0,
        colorCorrection = {
            brightness = 0.12,
            contrast = 0.1,
            saturation = 0.22,
            tint = Color3.fromRGB(255, 245, 220),
        }
    },
    GoldenHour = {
        time = {17, 18.5},
        fogColor = Color3.fromRGB(255, 180, 120),
        ambient = Color3.fromRGB(180, 120, 100),
        outdoor = Color3.fromRGB(255, 210, 160),
        brightness = 2.0,
        fogStart = 60,
        fogEnd = 800,
        atmosphereColor = Color3.fromRGB(255, 190, 140),
        atmosphereDensity = 0.35,
        atmosphereHaze = 1.6,
        shadowSoftness = 0.3,
        bloomIntensity = 0.45,
        bloomThreshold = 0.7,
        sunRaysIntensity = 0.5,
        exposure = 0.3,
        cloudColor = Color3.fromRGB(255, 180, 130),
        starCount = 1000,
        colorCorrection = {
            brightness = 0.2,
            contrast = 0.12,
            saturation = 0.35,
            tint = Color3.fromRGB(255, 230, 190),
        }
    },
    MagicDusk = {
        time = {18.5, 20},
        fogColor = Color3.fromRGB(180, 100, 140),
        ambient = Color3.fromRGB(80, 50, 90),
        outdoor = Color3.fromRGB(200, 120, 160),
        brightness = 1.2,
        fogStart = 40,
        fogEnd = 550,
        atmosphereColor = Color3.fromRGB(200, 130, 180),
        atmosphereDensity = 0.4,
        atmosphereHaze = 1.8,
        shadowSoftness = 0.4,
        bloomIntensity = 0.35,
        bloomThreshold = 0.75,
        sunRaysIntensity = 0.15,
        exposure = 0.25,
        cloudColor = Color3.fromRGB(180, 140, 200),
        starCount = 10000,
        colorCorrection = {
            brightness = 0.15,
            contrast = 0.15,
            saturation = 0.3,
            tint = Color3.fromRGB(220, 180, 230),
        }
    },
    MoonlitNight = {
        time = {20, 24},
        fogColor = Color3.fromRGB(30, 40, 70),
        ambient = Color3.fromRGB(40, 50, 75),
        outdoor = Color3.fromRGB(70, 90, 130),
        brightness = 1.3,
        fogStart = 35,
        fogEnd = 650,
        atmosphereColor = Color3.fromRGB(90, 110, 160),
        atmosphereDensity = 0.42,
        atmosphereHaze = 1.8,
        shadowSoftness = 0.45,
        bloomIntensity = 0.25,
        bloomThreshold = 0.8,
        sunRaysIntensity = 0.12,
        exposure = 0.08,
        cloudColor = Color3.fromRGB(110, 130, 170),
        starCount = 22000,
        colorCorrection = {
            brightness = 0.05,
            contrast = 0.1,
            saturation = 0.08,
            tint = Color3.fromRGB(190, 210, 250),
        }
    },
}

-- ========================================
-- 🔧 EFFECTS REFERENCES
-- ========================================
local atmosphere, bloom, sunRays, colorCorrection, sky, dof, clouds
local isRunning = false
local connection = nil

-- ========================================
-- ✨ INITIALIZE EFFECTS
-- ========================================
local function initializeEffects()
    atmosphere = Lighting:FindFirstChildOfClass("Atmosphere") or Instance.new("Atmosphere")
    atmosphere.Density = 0.35
    atmosphere.Offset = 0.25
    atmosphere.Color = Color3.fromRGB(199, 199, 199)
    atmosphere.Decay = Color3.fromRGB(106, 106, 106)
    atmosphere.Glare = 0.4
    atmosphere.Haze = 1.2
    atmosphere.Parent = Lighting

    bloom = Lighting:FindFirstChildOfClass("BloomEffect") or Instance.new("BloomEffect")
    bloom.Intensity = 0.3
    bloom.Size = 24
    bloom.Threshold = 0.9
    bloom.Parent = Lighting

    sunRays = Lighting:FindFirstChildOfClass("SunRaysEffect") or Instance.new("SunRaysEffect")
    sunRays.Intensity = 0.05
    sunRays.Spread = 0.3
    sunRays.Parent = Lighting

    colorCorrection = Lighting:FindFirstChildOfClass("ColorCorrectionEffect") or Instance.new("ColorCorrectionEffect")
    colorCorrection.Brightness = 0
    colorCorrection.Contrast = 0.08
    colorCorrection.Saturation = 0.15
    colorCorrection.TintColor = Color3.fromRGB(255, 255, 255)
    colorCorrection.Parent = Lighting

    sky = Lighting:FindFirstChildOfClass("Sky") or Instance.new("Sky")
    sky.SunAngularSize = 18
    sky.MoonAngularSize = 11
    sky.StarCount = 20000
    sky.CelestialBodiesShown = true
    sky.Parent = Lighting

    dof = Lighting:FindFirstChildOfClass("DepthOfFieldEffect") or Instance.new("DepthOfFieldEffect")
    dof.FarIntensity = 0.1
    dof.NearIntensity = 0.3
    dof.FocusDistance = 0.05
    dof.InFocusRadius = 50
    dof.Parent = Lighting

    clouds = Lighting:FindFirstChildOfClass("Clouds") or Instance.new("Clouds")
    clouds.Cover = 0.3
    clouds.Density = 0.4
    clouds.Color = Color3.fromRGB(255, 255, 255)
    clouds.Parent = Lighting
end

-- ========================================
-- 🌍 HELPER FUNCTIONS
-- ========================================
local function getTimePreset(hour)
    for name, preset in pairs(TIME_PRESETS) do
        local startTime, endTime = preset.time[1], preset.time[2]
        if startTime < endTime then
            if hour >= startTime and hour < endTime then
                return preset, name
            end
        else
            if hour >= startTime or hour < endTime then
                return preset, name
            end
        end
    end
    return TIME_PRESETS.BrightNoon, "BrightNoon"
end

local function lerp(a, b, t)
    return a + (b - a) * math.clamp(t, 0, 1)
end

local function lerpColor(c1, c2, t)
    if not c1 or not c2 then return c2 or c1 or Color3.new(1, 1, 1) end
    t = math.clamp(t, 0, 1)
    return Color3.new(
        lerp(c1.R, c2.R, t),
        lerp(c1.G, c2.G, t),
        lerp(c1.B, c2.B, t)
    )
end

local function easeInOutCubic(t)
    return t < 0.5 and 4 * t * t * t or 1 - math.pow(-2 * t + 2, 3) / 2
end

local function calculateSunPosition(hour)
    local normalizedHour = ((hour - 6) % 24) / 12
    local sunAngle = normalizedHour * math.pi
    local altitude = math.max(math.sin(sunAngle), 0)
    return altitude
end

-- ========================================
-- ✨ UPDATE EFFECTS
-- ========================================
local function updateDynamicEffects(hour, preset, presetName)
    if not preset then return end
    local config = DayNightCycle.Config
    local sunAltitude = calculateSunPosition(hour)

    if atmosphere then
        atmosphere.Density = preset.atmosphereDensity or 0.35
        atmosphere.Haze = preset.atmosphereHaze or 1.2
        atmosphere.Glare = lerp(0.1, 0.6, sunAltitude)
        atmosphere.Color = preset.atmosphereColor or Color3.fromRGB(199, 199, 199)
    end

    if bloom and config.EnableBloom then
        bloom.Enabled = true
        bloom.Intensity = preset.bloomIntensity or 0.3
        bloom.Threshold = preset.bloomThreshold or 0.9
    elseif bloom then
        bloom.Enabled = false
    end

    if sunRays and config.EnableSunRays then
        sunRays.Enabled = true
        sunRays.Intensity = preset.sunRaysIntensity or 0.1
        sunRays.Spread = 0.3
    elseif sunRays then
        sunRays.Enabled = false
    end

    if colorCorrection and preset.colorCorrection then
        colorCorrection.Brightness = preset.colorCorrection.brightness
        colorCorrection.Contrast = preset.colorCorrection.contrast
        colorCorrection.Saturation = preset.colorCorrection.saturation
        colorCorrection.TintColor = preset.colorCorrection.tint
    end

    if sky then
        sky.StarCount = preset.starCount or 10000
    end

    if clouds and config.EnableClouds then
        clouds.Enabled = true
        clouds.Cover = preset.starCount == 0 and 0.25 or 0.35
        clouds.Density = lerp(0.3, 0.6, 1 - sunAltitude)
        clouds.Color = preset.cloudColor or Color3.fromRGB(255, 255, 255)
    elseif clouds then
        clouds.Enabled = false
    end

    Lighting.ShadowSoftness = preset.shadowSoftness or 0.2
    Lighting.ExposureCompensation = preset.exposure or 0
end

-- ========================================
-- 🔄 MAIN UPDATE LOOP
-- ========================================
local smoothness = 0.015
local lastUpdateTime = tick()
local lastPresetName = nil

local function updateTime()
    if not DayNightCycle.Config.Enabled then return end
    
    local currentTime = tick()
    local delta = currentTime - lastUpdateTime
    lastUpdateTime = currentTime

    local newTime = Lighting.ClockTime + (DayNightCycle.Config.TimeSpeed * delta * 60)
    if newTime >= 24 then
        newTime = 0
    end
    Lighting.ClockTime = newTime

    local currentPreset, currentPresetName = getTimePreset(newTime)
    
    pcall(function()
        if currentPreset then
            local eased = easeInOutCubic(smoothness)
            Lighting.FogColor = lerpColor(Lighting.FogColor, currentPreset.fogColor, eased * 2)
            Lighting.Ambient = lerpColor(Lighting.Ambient, currentPreset.ambient, eased * 1.5)
            Lighting.OutdoorAmbient = lerpColor(Lighting.OutdoorAmbient, currentPreset.outdoor, eased * 1.5)
            Lighting.Brightness = lerp(Lighting.Brightness, currentPreset.brightness, eased)
            Lighting.FogEnd = lerp(Lighting.FogEnd, currentPreset.fogEnd, eased * 0.7)
            Lighting.FogStart = lerp(Lighting.FogStart, currentPreset.fogStart, eased * 0.7)
            updateDynamicEffects(newTime, currentPreset, currentPresetName)
        end
    end)

    lastPresetName = currentPresetName
end

-- ========================================
-- 🚀 PUBLIC API
-- ========================================

function DayNightCycle.Start()
    if isRunning then return end
    
    initializeEffects()
    Lighting.ClockTime = 12
    Lighting.GeographicLatitude = 15
    Lighting.EnvironmentDiffuseScale = 0.65
    Lighting.EnvironmentSpecularScale = 0.45
    Lighting.GlobalShadows = true
    
    isRunning = true
    connection = RunService.Heartbeat:Connect(updateTime)
    -- print("✅ Day-Night Cycle Started")
end

function DayNightCycle.Stop()
    if connection then
        connection:Disconnect()
        connection = nil
    end
    isRunning = false
    -- print("⏹ Day-Night Cycle Stopped")
end

function DayNightCycle.SetEnabled(enabled)
    DayNightCycle.Config.Enabled = enabled
    if enabled and not isRunning then
        DayNightCycle.Start()
    end
end

function DayNightCycle.SetTimeSpeed(speed)
    DayNightCycle.Config.TimeSpeed = speed
end

function DayNightCycle.SetTime(hour)
    Lighting.ClockTime = hour
end

function DayNightCycle.GetTime()
    return Lighting.ClockTime
end

function DayNightCycle.SetBloomEnabled(enabled)
    DayNightCycle.Config.EnableBloom = enabled
    if bloom then
        bloom.Enabled = enabled
    end
end

function DayNightCycle.SetSunRaysEnabled(enabled)
    DayNightCycle.Config.EnableSunRays = enabled
    if sunRays then
        sunRays.Enabled = enabled
    end
end

function DayNightCycle.SetCloudsEnabled(enabled)
    DayNightCycle.Config.EnableClouds = enabled
    if clouds then
        clouds.Enabled = enabled
    end
end

-- Auto-start disabled - now handled by server/DayNightCycle.server.lua
-- DayNightCycle.Start()

return DayNightCycle
