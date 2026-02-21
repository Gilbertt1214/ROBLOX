--[[
    InventoryView Component
    Displays player items from backpack
    Click item to equip/unequip to hotbar
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Roact = require(ReplicatedStorage.Shared.Roact)
local Theme = require(ReplicatedStorage.Shared.Theme)
local ResponsiveUtil = require(ReplicatedStorage.Shared.ResponsiveUtil)

local InventoryView = {}

local function createItemCard(props)
    local item = props.item
    local index = props.index
    local name = item.name or "Unknown"
    local rarity = item.rarity or "Common"
    local equipped = item.equipped or false
    local hotbarSlot = item.hotbarSlot
    local onEquip = props.onEquip
    local onUnequip = props.onUnequip
    
    local rarityColor = Theme.TextSecondary
    if rarity == "Rare" then rarityColor = Theme.PrimaryLight
    elseif rarity == "Epic" then rarityColor = Color3.fromRGB(168, 85, 247)
    elseif rarity == "Legendary" then rarityColor = Theme.Warning
    end

    return Roact.createElement("TextButton", {
        Size = UDim2.new(0, 90, 0, 110),
        BackgroundColor3 = Theme.BackgroundLight,
        BackgroundTransparency = 0.5,
        Text = "",
        AutoButtonColor = false,
        Event = {
            MouseButton1Click = function(rbx)
                if equipped then
                    if onUnequip then onUnequip(index, item) end
                else
                    if onEquip then onEquip(index, item) end
                end
                -- Click animation
                TweenService:Create(rbx, TweenInfo.new(0.1), {
                    Size = UDim2.new(0, 85, 0, 105)
                }):Play()
                task.delay(0.1, function()
                    TweenService:Create(rbx, TweenInfo.new(0.15, Enum.EasingStyle.Back), {
                        Size = UDim2.new(0, 90, 0, 110)
                    }):Play()
                end)
            end,
            MouseEnter = function(rbx)
                TweenService:Create(rbx, TweenInfo.new(0.1), {
                    BackgroundTransparency = 0.3
                }):Play()
            end,
            MouseLeave = function(rbx)
                TweenService:Create(rbx, TweenInfo.new(0.1), {
                    BackgroundTransparency = 0.5
                }):Play()
            end
        }
    }, {
        Corner = Roact.createElement("UICorner", { CornerRadius = UDim.new(0, 8) }),
        Stroke = Roact.createElement("UIStroke", { 
            Color = equipped and Theme.Primary or rarityColor, 
            Thickness = equipped and 2 or 1,
            Transparency = equipped and 0 or 0.5 
        }),
        
        -- Item icon area
        IconArea = Roact.createElement("Frame", {
            Size = UDim2.new(1, -10, 0, 50),
            Position = UDim2.new(0.5, 0, 0, 5),
            AnchorPoint = Vector2.new(0.5, 0),
            BackgroundColor3 = Theme.BackgroundCard,
            BackgroundTransparency = 0.5
        }, {
            Corner = Roact.createElement("UICorner", { CornerRadius = UDim.new(0, 6) }),
            -- Show image icon if available, otherwise emoji
            Icon = (item.icon and item.icon ~= "" and item.icon ~= "rbxassetid://0") and Roact.createElement("ImageLabel", {
                Size = UDim2.new(0, 40, 0, 40),
                Position = UDim2.new(0.5, 0, 0.5, 0),
                AnchorPoint = Vector2.new(0.5, 0.5),
                BackgroundTransparency = 1,
                Image = item.icon,
                ScaleType = Enum.ScaleType.Fit
            }) or Roact.createElement("TextLabel", {
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                Text = item.emoji or "📦",
                TextSize = 28,
                Font = Theme.FontRegular,
                TextColor3 = Color3.new(1, 1, 1)
            }),
            -- Item count badge
            CountBadge = (item.count and item.count > 1) and Roact.createElement("TextLabel", {
                Size = UDim2.new(0, 20, 0, 16),
                Position = UDim2.new(1, -2, 1, -2),
                AnchorPoint = Vector2.new(1, 1),
                BackgroundColor3 = Theme.Primary,
                BackgroundTransparency = 0.2,
                Text = tostring(item.count),
                TextColor3 = Color3.new(1, 1, 1),
                TextSize = 10,
                Font = Theme.FontBold
            }, {
                Corner = Roact.createElement("UICorner", { CornerRadius = UDim.new(0, 4) })
            }) or nil
        }),
        
        -- Item name
        Title = Roact.createElement("TextLabel", {
            Size = UDim2.new(1, -6, 0, 18),
            Position = UDim2.new(0, 3, 0, 58),
            BackgroundTransparency = 1,
            Text = name,
            TextColor3 = Theme.TextPrimary,
            TextSize = 11,
            Font = Theme.FontMedium,
            TextTruncate = Enum.TextTruncate.AtEnd
        }),
        
        -- Rarity
        Rarity = Roact.createElement("TextLabel", {
            Size = UDim2.new(1, -6, 0, 14),
            Position = UDim2.new(0, 3, 0, 76),
            BackgroundTransparency = 1,
            Text = rarity,
            TextColor3 = rarityColor,
            TextSize = 9,
            Font = Theme.FontBold
        }),
        
        -- Equip button hint
        EquipHint = Roact.createElement("TextLabel", {
            Size = UDim2.new(1, -6, 0, 14),
            Position = UDim2.new(0, 3, 1, -16),
            BackgroundTransparency = 1,
            Text = equipped and ("Slot " .. (hotbarSlot or "?") .. " ✓") or "Click to Equip",
            TextColor3 = equipped and Theme.Primary or Theme.TextMuted,
            TextSize = 9,
            Font = Theme.FontMedium
        }),
        
        -- Equipped badge
        EquippedBadge = equipped and Roact.createElement("Frame", {
            Size = UDim2.new(0, 20, 0, 20),
            Position = UDim2.new(1, -5, 0, 5),
            AnchorPoint = Vector2.new(1, 0),
            BackgroundColor3 = Theme.Primary
        }, {
            Corner = Roact.createElement("UICorner", { CornerRadius = UDim.new(1, 0) }),
            Check = Roact.createElement("TextLabel", {
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                Text = "✓",
                TextColor3 = Color3.new(1, 1, 1),
                TextSize = 12,
                Font = Theme.FontBold
            })
        }) or nil
    })
end

function InventoryView.create(props)
    local inventory = props.inventory or {}
    local onEquipItem = props.onEquipItem
    local onUnequipItem = props.onUnequipItem
    
    local sizes = ResponsiveUtil.getSizes()
    local isPhone = ResponsiveUtil.isPhone()
    local isMobile = ResponsiveUtil.isMobile()
    
    -- Responsive sizes - smaller for phone
    local panelWidth = isPhone and 260 or (isMobile and 340 or 450)
    local panelHeight = isPhone and 280 or (isMobile and 340 or 400)
    local cellSize = isPhone and 75 or (isMobile and 82 or 90)
    local cellHeight = isPhone and 95 or (isMobile and 102 or 110)
    local titleSize = sizes.fontSize.title
    
    local children = {
        Layout = Roact.createElement("UIGridLayout", {
            CellSize = UDim2.new(0, cellSize, 0, cellHeight),
            CellPadding = UDim2.new(0, isPhone and 6 or 10, 0, isPhone and 6 or 10),
            SortOrder = Enum.SortOrder.LayoutOrder
        }),
    }
    
    for i, item in ipairs(inventory) do
        children["Item_" .. i] = createItemCard({ 
            item = item, 
            index = i,
            onEquip = onEquipItem,
            onUnequip = onUnequipItem,
            cellSize = cellSize,
            cellHeight = cellHeight
        })
    end
    
    if #inventory == 0 then
        children.EmptyMessage = Roact.createElement("TextLabel", {
            Size = UDim2.new(1, 0, 1, 0),
            Text = "No items in inventory",
            TextColor3 = Theme.TextSecondary,
            TextSize = sizes.fontSize.medium,
            Font = Theme.FontMedium,
            BackgroundTransparency = 1
        })
    end
    
    local equippedCount = 0
    for _, item in ipairs(inventory) do
        if item.equipped then equippedCount = equippedCount + 1 end
    end
    
    return Roact.createElement("Frame", {
        Name = "InventoryView",
        Size = UDim2.new(0, panelWidth, 0, panelHeight),
        Position = UDim2.new(0.5, 0, 0.5, 0),
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
            Size = UDim2.new(1, 0, 0, isPhone and 32 or 40),
            Text = "INVENTORY",
            TextColor3 = Theme.TextPrimary,
            TextSize = titleSize,
            Font = Theme.FontBold,
            BackgroundTransparency = 1
        }),
        
        Subtitle = Roact.createElement("TextLabel", {
            Size = UDim2.new(1, 0, 0, 18),
            Position = UDim2.new(0, 0, 0, isPhone and 28 or 35),
            Text = #inventory .. " items - " .. equippedCount .. " equipped",
            TextColor3 = Theme.TextMuted,
            TextSize = sizes.fontSize.small,
            Font = Theme.FontRegular,
            BackgroundTransparency = 1
        }),
        
        Container = Roact.createElement("ScrollingFrame", {
            Size = UDim2.new(1, -16, 1, isPhone and -55 or -70),
            Position = UDim2.new(0, 8, 0, isPhone and 50 or 60),
            BackgroundTransparency = 1,
            ScrollBarThickness = 3,
            ScrollBarImageColor3 = Theme.Primary,
            CanvasSize = UDim2.new(0, 0, 0, 0),
            AutomaticCanvasSize = Enum.AutomaticSize.Y
        }, children)
    })
end

return InventoryView
