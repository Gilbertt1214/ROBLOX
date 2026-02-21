--[[
    ResponsiveUtil
    Utility for responsive UI across different devices
    Supports auto-scaling based on screen size
]]

local GuiService = game:GetService("GuiService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local ResponsiveUtil = {}

-- Base resolution for scaling (design resolution)
local BASE_RESOLUTION = Vector2.new(1920, 1080)

-- Device types
ResponsiveUtil.DeviceType = {
    PHONE = "phone",
    TABLET = "tablet",
    DESKTOP = "desktop"
}

-- Get screen size using Camera ViewportSize (more reliable)
function ResponsiveUtil.getScreenSize()
    local camera = Workspace.CurrentCamera
    if camera then
        return camera.ViewportSize
    end
    
    local player = Players.LocalPlayer
    if not player then return Vector2.new(1920, 1080) end
    
    local playerGui = player:FindFirstChild("PlayerGui")
    if not playerGui then return Vector2.new(1920, 1080) end
    
    local screenGui = playerGui:FindFirstChildOfClass("ScreenGui")
    if screenGui then
        return screenGui.AbsoluteSize
    end
    
    return Vector2.new(1920, 1080)
end

-- Check if touch device
function ResponsiveUtil.isTouchDevice()
    return UserInputService.TouchEnabled
end

-- Detect device type based on screen size and input type
function ResponsiveUtil.getDeviceType()
    local size = ResponsiveUtil.getScreenSize()
    local width = size.X
    local height = size.Y
    local isTouchEnabled = UserInputService.TouchEnabled
    local hasKeyboard = UserInputService.KeyboardEnabled
    
    -- Use smaller dimension for orientation-independent detection
    local smallerDim = math.min(width, height)
    local largerDim = math.max(width, height)
    
    -- Touch device detection
    if isTouchEnabled then
        -- Phone: smaller dimension typically < 600, or aspect ratio suggests phone
        if smallerDim < 600 or (largerDim / smallerDim > 1.8 and smallerDim < 800) then
            return ResponsiveUtil.DeviceType.PHONE
        -- Tablet: touch enabled but larger screen
        elseif smallerDim < 1000 then
            return ResponsiveUtil.DeviceType.TABLET
        end
    end
    
    -- Desktop: has keyboard and not primarily touch, or large screen
    if hasKeyboard and not isTouchEnabled then
        return ResponsiveUtil.DeviceType.DESKTOP
    end
    
    -- Fallback based on screen width
    if width <= 700 then
        return ResponsiveUtil.DeviceType.PHONE
    elseif width <= 1200 then
        return ResponsiveUtil.DeviceType.TABLET
    else
        return ResponsiveUtil.DeviceType.DESKTOP
    end
end

-- Check if mobile (phone or tablet)
function ResponsiveUtil.isMobile()
    local deviceType = ResponsiveUtil.getDeviceType()
    return deviceType == ResponsiveUtil.DeviceType.PHONE or deviceType == ResponsiveUtil.DeviceType.TABLET
end

-- Check if phone
function ResponsiveUtil.isPhone()
    return ResponsiveUtil.getDeviceType() == ResponsiveUtil.DeviceType.PHONE
end

-- Check if tablet
function ResponsiveUtil.isTablet()
    return ResponsiveUtil.getDeviceType() == ResponsiveUtil.DeviceType.TABLET
end

-- Scale value based on device
function ResponsiveUtil.scale(desktopValue, tabletValue, phoneValue)
    local deviceType = ResponsiveUtil.getDeviceType()
    
    if deviceType == ResponsiveUtil.DeviceType.PHONE then
        return phoneValue or (desktopValue * 0.7)
    elseif deviceType == ResponsiveUtil.DeviceType.TABLET then
        return tabletValue or (desktopValue * 0.85)
    else
        return desktopValue
    end
end

-- Get responsive sizes for common UI elements
function ResponsiveUtil.getSizes()
    local deviceType = ResponsiveUtil.getDeviceType()
    
    if deviceType == ResponsiveUtil.DeviceType.PHONE then
        return {
            sidebarWidth = 45,
            sidebarIconSize = 32,
            sidebarPadding = 6,
            topBarHeight = 36,
            topBarIconSize = 26,
            hotbarSlotSize = 42,
            hotbarPadding = 4,
            fontSize = {
                small = 10,
                medium = 12,
                large = 16,
                title = 20
            },
            padding = {
                small = 4,
                medium = 8,
                large = 12
            },
            margin = 8
        }
    elseif deviceType == ResponsiveUtil.DeviceType.TABLET then
        return {
            sidebarWidth = 52,
            sidebarIconSize = 36,
            sidebarPadding = 6,
            topBarHeight = 40,
            topBarIconSize = 28,
            hotbarSlotSize = 46,
            hotbarPadding = 5,
            fontSize = {
                small = 11,
                medium = 13,
                large = 17,
                title = 22
            },
            padding = {
                small = 6,
                medium = 10,
                large = 14
            },
            margin = 12
        }
    else
        return {
            sidebarWidth = 72,
            sidebarIconSize = 48,
            sidebarPadding = 10,
            topBarHeight = 52,
            topBarIconSize = 36,
            hotbarSlotSize = 64,
            hotbarPadding = 8,
            fontSize = {
                small = 14,
                medium = 16,
                large = 20,
                title = 28
            },
            padding = {
                small = 10,
                medium = 14,
                large = 20
            },
            margin = 20
        }
    end
end

-- Get auto-scale factor based on screen size
-- Returns a scale factor relative to base resolution (1920x1080)
function ResponsiveUtil.getScaleFactor()
    local screenSize = ResponsiveUtil.getScreenSize()
    local scaleX = screenSize.X / BASE_RESOLUTION.X
    local scaleY = screenSize.Y / BASE_RESOLUTION.Y
    -- Use the smaller scale to ensure UI fits on screen
    return math.min(scaleX, scaleY)
end

-- Get scale factor with min/max bounds
function ResponsiveUtil.getClampedScaleFactor(minScale, maxScale)
    minScale = minScale or 0.5
    maxScale = maxScale or 1.5
    local scale = ResponsiveUtil.getScaleFactor()
    return math.clamp(scale, minScale, maxScale)
end

-- Create UIScale instance for auto-scaling
-- Use this in your ScreenGui to auto-scale all children
function ResponsiveUtil.createUIScale(minScale, maxScale)
    local Roact = require(game:GetService("ReplicatedStorage").Shared.Roact)
    local scale = ResponsiveUtil.getClampedScaleFactor(minScale, maxScale)
    
    return Roact.createElement("UIScale", {
        Scale = scale
    })
end

-- Get scale value for UIScale component
function ResponsiveUtil.getUIScaleValue(minScale, maxScale)
    return ResponsiveUtil.getClampedScaleFactor(minScale, maxScale)
end

-- Auto-scale a pixel value based on screen size
function ResponsiveUtil.autoScale(pixelValue)
    local scale = ResponsiveUtil.getClampedScaleFactor(0.5, 1.2)
    return math.floor(pixelValue * scale)
end

-- Get responsive panel size with auto-scale
function ResponsiveUtil.getPanelSize(baseWidth, baseHeight)
    local isPhone = ResponsiveUtil.isPhone()
    local isMobile = ResponsiveUtil.isMobile()
    
    -- Apply device-specific multiplier first
    local multiplier = 1
    if isPhone then
        multiplier = 0.65
    elseif isMobile then
        multiplier = 0.8
    end
    
    -- Then apply screen-based auto-scale
    local scale = ResponsiveUtil.getClampedScaleFactor(0.6, 1.0)
    
    local finalWidth = math.floor(baseWidth * multiplier * scale)
    local finalHeight = math.floor(baseHeight * multiplier * scale)
    
    return finalWidth, finalHeight
end

return ResponsiveUtil
