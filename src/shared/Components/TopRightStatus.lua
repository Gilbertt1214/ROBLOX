--[[
    TopRightStatus Component
    Horizontal status bar showing currency and icons
    Props:
        - currency: number - amount to display
        - currencySymbol: string - currency symbol (default: "Rp.")
        - icons: table of {id, icon, value?, onClick?}
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Roact = require(ReplicatedStorage.Shared.Roact)
local Theme = require(ReplicatedStorage.Shared.Theme)
local Icons = require(ReplicatedStorage.Shared.Icons)
local ResponsiveUtil = require(ReplicatedStorage.Shared.ResponsiveUtil)

local TopRightStatus = {}

-- Format number with K/M suffix
local function formatCurrency(amount)
    if amount >= 1000000 then
        return string.format("%.2fM", amount / 1000000)
    elseif amount >= 1000 then
        return string.format("%.2fK", amount / 1000)
    else
        return tostring(math.floor(amount))
    end
end

-- Create currency display
local function createCurrencyDisplay(props)
    local amount = props.amount or 0
    local symbol = props.symbol or "Rp."
    local width = props.width or 120
    local fontSize = props.fontSize or 14
    local formattedAmount = formatCurrency(amount)
    local coinIcon = Icons.Get("coin")
    local isTextIcon = Icons.IsTextIcon("coin")
    
    local coinElement
    if isTextIcon then
        coinElement = Roact.createElement("TextLabel", {
            Name = "CoinIcon",
            Size = UDim2.new(0, 18, 0, 18),
            Position = UDim2.new(0, 6, 0.5, 0),
            AnchorPoint = Vector2.new(0, 0.5),
            BackgroundTransparency = 1,
            Text = coinIcon or "C",
            TextSize = 14
        })
    else
        coinElement = Roact.createElement("ImageLabel", {
            Name = "CoinIcon",
            Size = UDim2.new(0, 18, 0, 18),
            Position = UDim2.new(0, 6, 0.5, 0),
            AnchorPoint = Vector2.new(0, 0.5),
            BackgroundTransparency = 1,
            Image = coinIcon or "",
            ImageColor3 = Theme.Warning,
            ScaleType = Enum.ScaleType.Fit
        })
    end
    
    return Roact.createElement("Frame", {
        Name = "CurrencyDisplay",
        Size = UDim2.new(0, width, 1, -8),
        Position = UDim2.new(0, 4, 0, 4),
        BackgroundColor3 = Theme.Primary,
        BackgroundTransparency = 0.3,
        BorderSizePixel = 0
    }, {
        Corner = Roact.createElement("UICorner", {
            CornerRadius = UDim.new(0, 6)
        }),
        CoinIcon = coinElement,
        AmountLabel = Roact.createElement("TextLabel", {
            Name = "Amount",
            Size = UDim2.new(1, -30, 1, 0),
            Position = UDim2.new(0, 28, 0, 0),
            BackgroundTransparency = 1,
            Text = symbol .. " " .. formattedAmount,
            TextColor3 = Theme.TextPrimary,
            TextSize = fontSize,
            Font = Theme.FontBold,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd
        })
    })
end

-- Create small icon button
local function createIconButton(props)
    local id = props.id
    local value = props.value
    local onClick = props.onClick
    local isActive = props.isActive or false
    local layoutOrder = props.layoutOrder or 0
    local iconSize = props.iconSize or 32
    local icon = Icons.Get(id)
    local isTextIcon = Icons.IsTextIcon(id)
    
    -- Colors matching Sidebar exactly
    local bgColor = isActive and Theme.Primary or Theme.BackgroundLight
    local bgTransparency = isActive and 0 or 0.5
    local strokeColor = isActive and Theme.PrimaryLight or Theme.StrokeColor
    local strokeTransparency = isActive and 0 or 0.7
    
    local iconElement
    if isTextIcon then
        iconElement = Roact.createElement("TextLabel", {
            Name = "Icon",
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            Text = icon or "?",
            TextSize = math.floor(iconSize * 0.5),
            Font = Enum.Font.GothamBold,
            TextColor3 = Color3.new(1, 1, 1)
        })
    else
        iconElement = Roact.createElement("ImageLabel", {
            Name = "Icon",
            Size = UDim2.new(0.6, 0, 0.6, 0),
            Position = UDim2.new(0.5, 0, 0.5, 0),
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundTransparency = 1,
            Image = icon or "",
            ImageColor3 = Color3.new(1, 1, 1),
            ScaleType = Enum.ScaleType.Fit
        })
    end
    
    return Roact.createElement("ImageButton", {
        Name = "Icon_" .. id,
        Size = UDim2.new(0, iconSize, 0, iconSize),
        BackgroundColor3 = bgColor,
        BackgroundTransparency = bgTransparency,
        BorderSizePixel = 0,
        Image = "",
        LayoutOrder = layoutOrder,
        AutoButtonColor = false,
        Event = {
            MouseButton1Click = function()
                if onClick then
                    onClick(id)
                end
            end,
            MouseEnter = function(rbx)
                if not isActive then
                    game:GetService("TweenService"):Create(
                        rbx,
                        TweenInfo.new(0.15, Enum.EasingStyle.Quad),
                        {BackgroundTransparency = 0.3}
                    ):Play()
                end
            end,
            MouseLeave = function(rbx)
                if not isActive then
                    game:GetService("TweenService"):Create(
                        rbx,
                        TweenInfo.new(0.15, Enum.EasingStyle.Quad),
                        {BackgroundTransparency = 0.5}
                    ):Play()
                end
            end,
        }
    }, {
        Corner = Roact.createElement("UICorner", {
            CornerRadius = UDim.new(0, 6)
        }),
        Stroke = Roact.createElement("UIStroke", {
            Color = strokeColor,
            Thickness = isActive and 2 or 1,
            Transparency = strokeTransparency
        }),
        IconImage = iconElement,
        Badge = value and value > 0 and Roact.createElement("TextLabel", {
            Name = "Badge",
            Size = UDim2.new(0, 14, 0, 14),
            Position = UDim2.new(1, -2, 0, -2),
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundColor3 = Theme.Error,
            Text = tostring(value),
            TextColor3 = Theme.TextPrimary,
            TextSize = 9,
            Font = Theme.FontBold
        }, {
            BadgeCorner = Roact.createElement("UICorner", {
                CornerRadius = UDim.new(1, 0)
            })
        }) or nil
    })
end

-- Main TopRightStatus component
function TopRightStatus.create(props)
    local currency = props.currency or 0
    local currencySymbol = props.currencySymbol or "Rp."
    local icons = props.icons or {}
    local onIconClick = props.onIconClick
    local activeId = props.activeId
    
    local sizes = ResponsiveUtil.getSizes()
    local isPhone = ResponsiveUtil.isPhone()
    local isMobile = ResponsiveUtil.isMobile()
    local margin = sizes.margin
    local barHeight = sizes.topBarHeight
    local iconSize = sizes.topBarIconSize
    
    -- Adjust width based on device
    local barWidth = isPhone and 200 or (ResponsiveUtil.getDeviceType() == "tablet" and 240 or 280)
    local currencyWidth = isPhone and 90 or 120
    
    -- Top offset to avoid Roblox buttons on mobile
    local topOffset = isPhone and 50 or (isMobile and 45 or margin)
    
    local iconChildren = {
        Layout = Roact.createElement("UIListLayout", {
            SortOrder = Enum.SortOrder.LayoutOrder,
            FillDirection = Enum.FillDirection.Horizontal,
            Padding = UDim.new(0, isPhone and 4 or 6),
            HorizontalAlignment = Enum.HorizontalAlignment.Right,
            VerticalAlignment = Enum.VerticalAlignment.Center
        })
    }
    
    -- Add icon buttons
    for i, iconData in ipairs(icons) do
        local isActive = (iconData.id == activeId)
        iconChildren["Icon" .. i] = createIconButton({
            id = iconData.id,
            icon = iconData.icon,
            value = iconData.value,
            onClick = onIconClick,
            isActive = isActive,
            layoutOrder = i,
            iconSize = iconSize
        })
    end
    
    return Roact.createElement("Frame", {
        Name = "TopRightStatus",
        Size = UDim2.new(0, barWidth, 0, barHeight),
        Position = UDim2.new(1, -margin, 0, topOffset),
        AnchorPoint = Vector2.new(1, 0),
        BackgroundColor3 = Theme.Background,
        BackgroundTransparency = 0.15,
        BorderSizePixel = 0
    }, {
        Corner = Roact.createElement("UICorner", {
            CornerRadius = UDim.new(0, 10)
        }),
        Stroke = Roact.createElement("UIStroke", {
            Color = Theme.StrokeColor,
            Thickness = 1,
            Transparency = 0.5
        }),
        CurrencySection = createCurrencyDisplay({
            amount = currency,
            symbol = currencySymbol,
            width = currencyWidth,
            fontSize = sizes.fontSize.medium
        }),
        IconsSection = Roact.createElement("Frame", {
            Name = "IconsSection",
            Size = UDim2.new(0, barWidth - currencyWidth - 16, 1, -8),
            Position = UDim2.new(1, -8, 0, 4),
            AnchorPoint = Vector2.new(1, 0),
            BackgroundTransparency = 1
        }, iconChildren)
    })
end

return TopRightStatus
