--[[
    ShopView Component
    Displays shop items
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Roact = require(ReplicatedStorage.Shared.Roact)
local Theme = require(ReplicatedStorage.Shared.Theme)
local ResponsiveUtil = require(ReplicatedStorage.Shared.ResponsiveUtil)

local ShopView = {}

function ShopView.create()
    local sizes = ResponsiveUtil.getSizes()
    local isPhone = ResponsiveUtil.isPhone()
    local isMobile = ResponsiveUtil.isMobile()
    
    -- Responsive sizes
    local panelWidth = isPhone and 280 or (isMobile and 320 or 360)
    local panelHeight = isPhone and 220 or (isMobile and 250 or 280)
    
    return Roact.createElement("Frame", {
        Name = "ShopView",
        Size = UDim2.new(0, panelWidth, 0, panelHeight),
        Position = UDim2.new(0.5, 0, 0.5, isPhone and -30 or -40),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = Theme.Background,
        BackgroundTransparency = 0.1,
    }, {
        Corner = Roact.createElement("UICorner", { CornerRadius = UDim.new(0, isPhone and 12 or 16) }),
        Title = Roact.createElement("TextLabel", {
            Size = UDim2.new(1, 0, 0, isPhone and 32 or 38),
            Text = "SHOP",
            TextColor3 = Color3.fromRGB(234, 179, 8),
            TextSize = sizes.fontSize.title,
            Font = Theme.FontBold,
            BackgroundTransparency = 1
        }),
        Placeholder = Roact.createElement("TextLabel", {
            Size = UDim2.new(1, 0, 1, isPhone and -32 or -38),
            Position = UDim2.new(0, 0, 0, isPhone and 32 or 38),
            Text = "Daily Deals arriving soon!",
            TextColor3 = Theme.TextSecondary,
            TextSize = sizes.fontSize.medium,
            Font = Theme.FontMedium,
            BackgroundTransparency = 1
        })
    })
end

return ShopView
