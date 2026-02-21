--[[
    Theme Configuration
    Blue accent theme for modern Roblox UI
]]

local Theme = {
    -- Primary Colors
    Primary = Color3.fromRGB(59, 130, 246),      -- Blue-500
    PrimaryDark = Color3.fromRGB(37, 99, 235),   -- Blue-600
    PrimaryLight = Color3.fromRGB(96, 165, 250), -- Blue-400
    
    -- Background Colors
    Background = Color3.fromRGB(15, 23, 42),     -- Slate-900
    BackgroundLight = Color3.fromRGB(30, 41, 59), -- Slate-800
    BackgroundCard = Color3.fromRGB(51, 65, 85), -- Slate-700
    
    -- Surface Colors (semi-transparent)
    SurfaceTransparent = 0.3,
    SurfaceSolid = 0.1,
    
    -- Text Colors
    TextPrimary = Color3.fromRGB(248, 250, 252), -- Slate-50
    TextSecondary = Color3.fromRGB(148, 163, 184), -- Slate-400
    TextMuted = Color3.fromRGB(100, 116, 139),   -- Slate-500
    
    -- Accent Colors
    Success = Color3.fromRGB(34, 197, 94),       -- Green-500
    Warning = Color3.fromRGB(234, 179, 8),       -- Yellow-500
    Error = Color3.fromRGB(239, 68, 68),         -- Red-500
    
    -- Stroke
    StrokeColor = Color3.fromRGB(71, 85, 105),   -- Slate-600
    StrokeHighlight = Color3.fromRGB(59, 130, 246), -- Blue-500
    
    -- Sizing
    CornerRadius = UDim.new(0, 12),
    CornerRadiusSmall = UDim.new(0, 8),
    CornerRadiusLarge = UDim.new(0, 16),
    
    -- Spacing
    Padding = UDim.new(0, 12),
    PaddingSmall = UDim.new(0, 8),
    PaddingLarge = UDim.new(0, 16),
    
    -- Icon Sizes
    IconSize = UDim2.new(0, 40, 0, 40),
    IconSizeSmall = UDim2.new(0, 24, 0, 24),
    
    -- Font
    FontBold = Enum.Font.GothamBold,
    FontMedium = Enum.Font.GothamMedium,
    FontRegular = Enum.Font.Gotham,
}

return Theme
