--[[
    LeftSidebar Component
    Vertical icon list with hover/active states
    Props:
        - items: table of {id, icon, tooltip}
        - activeId: string - currently active item id
        - onItemClick: function(id) - callback when item is clicked
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Roact = require(ReplicatedStorage.Shared.Roact)
local Theme = require(ReplicatedStorage.Shared.Theme)
local Icons = require(ReplicatedStorage.Shared.Icons)
local ResponsiveUtil = require(ReplicatedStorage.Shared.ResponsiveUtil)

local LeftSidebar = {}

-- Create a single sidebar item button
local function createSidebarItem(props)
    local id = props.id
    local icon = Icons.Get(id)
    local isTextIcon = Icons.IsTextIcon(id)
    local isActive = props.isActive or false
    local onClick = props.onClick
    local tooltip = props.tooltip or id
    local sizes = props.sizes
    
    local iconSize = sizes.sidebarIconSize
    
    -- Colors based on state
    local bgColor = isActive and Theme.Primary or Theme.BackgroundLight
    local bgTransparency = isActive and 0 or 0.5
    local strokeColor = isActive and Theme.PrimaryLight or Theme.StrokeColor
    local strokeTransparency = isActive and 0 or 0.7
    
    -- Icon element
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
            Size = UDim2.new(0, math.floor(iconSize * 0.6), 0, math.floor(iconSize * 0.6)),
            Position = UDim2.new(0.5, 0, 0.5, 0),
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundTransparency = 1,
            Image = icon or "",
            ImageColor3 = Color3.new(1, 1, 1),
            ScaleType = Enum.ScaleType.Fit
        })
    end
    
    return Roact.createElement("TextButton", {
        Name = "Item_" .. id,
        Size = UDim2.new(0, iconSize, 0, iconSize),
        BackgroundColor3 = bgColor,
        BackgroundTransparency = bgTransparency,
        BorderSizePixel = 0,
        Text = "",
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
                        TweenInfo.new(0.2, Enum.EasingStyle.Quad),
                        {BackgroundTransparency = 0.3, BackgroundColor3 = Theme.BackgroundCard}
                    ):Play()
                end
            end,
            MouseLeave = function(rbx)
                if not isActive then
                    game:GetService("TweenService"):Create(
                        rbx,
                        TweenInfo.new(0.2, Enum.EasingStyle.Quad),
                        {BackgroundTransparency = 0.5, BackgroundColor3 = Theme.BackgroundLight}
                    ):Play()
                end
            end,
        }
    }, {
        Corner = Roact.createElement("UICorner", {
            CornerRadius = UDim.new(0, 10)
        }),
        Stroke = Roact.createElement("UIStroke", {
            Color = strokeColor,
            Thickness = isActive and 2 or 1,
            Transparency = strokeTransparency
        }),
        Icon = iconElement
    })
end

-- Main Sidebar component
function LeftSidebar.create(props)
    local items = props.items or {}
    local activeId = props.activeId
    local onItemClick = props.onItemClick
    
    local sizes = ResponsiveUtil.getSizes()
    local isPhone = ResponsiveUtil.isPhone()
    local isMobile = ResponsiveUtil.isMobile()
    local sidebarWidth = sizes.sidebarWidth
    local iconSize = sizes.sidebarIconSize
    local padding = sizes.sidebarPadding
    local margin = sizes.margin
    
    local sidebarHeight = (#items * (iconSize + padding)) + (padding * 2)
    
    -- Offset from top to avoid Roblox default buttons
    -- Mobile has buttons at top-left, so we need more offset
    local topOffset = isPhone and 90 or (isMobile and 80 or 0)
    
    local children = {
        Layout = Roact.createElement("UIListLayout", {
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, padding),
            HorizontalAlignment = Enum.HorizontalAlignment.Center,
            VerticalAlignment = Enum.VerticalAlignment.Top
        }),
        Padding = Roact.createElement("UIPadding", {
            PaddingTop = UDim.new(0, padding),
            PaddingBottom = UDim.new(0, padding),
            PaddingLeft = UDim.new(0, padding),
            PaddingRight = UDim.new(0, padding)
        })
    }
    
    -- Add items
    for i, item in ipairs(items) do
        children["Item" .. i] = createSidebarItem({
            id = item.id,
            icon = item.icon,
            tooltip = item.tooltip,
            isActive = (item.id == activeId),
            onClick = onItemClick,
            sizes = sizes
        })
    end
    
    -- Position: center vertically but with offset for mobile to avoid Roblox buttons
    local posY = isMobile and (topOffset + sidebarHeight/2) or 0
    local anchorY = isMobile and 0 or 0.5
    
    return Roact.createElement("Frame", {
        Name = "LeftSidebar",
        Size = UDim2.new(0, sidebarWidth, 0, sidebarHeight),
        Position = UDim2.new(0, margin, 0.5, 0),
        AnchorPoint = Vector2.new(0, 0.5),
        BackgroundColor3 = Theme.Background,
        BackgroundTransparency = 0.2,
        BorderSizePixel = 0
    }, {
        Corner = Roact.createElement("UICorner", {
            CornerRadius = UDim.new(0, 12)
        }),
        Stroke = Roact.createElement("UIStroke", {
            Color = Theme.StrokeColor,
            Thickness = 1,
            Transparency = 0.5
        }),
        Container = Roact.createElement("Frame", {
            Name = "Container",
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1
        }, children)
    })
end

return LeftSidebar
