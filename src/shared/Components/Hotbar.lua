--[[
    Hotbar Component
    Bottom screen hotbar with dynamic slots
    Supports keyboard shortcuts (1-9) and click selection
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Roact = require(ReplicatedStorage.Shared.Roact)
local Theme = require(ReplicatedStorage.Shared.Theme)
local ResponsiveUtil = require(ReplicatedStorage.Shared.ResponsiveUtil)

local Hotbar = {}

-- Hotbar configuration
local MAX_SLOTS = 9

-- Key codes for slots 1-9
local SLOT_KEYS = {
    [Enum.KeyCode.One] = 1,
    [Enum.KeyCode.Two] = 2,
    [Enum.KeyCode.Three] = 3,
    [Enum.KeyCode.Four] = 4,
    [Enum.KeyCode.Five] = 5,
    [Enum.KeyCode.Six] = 6,
    [Enum.KeyCode.Seven] = 7,
    [Enum.KeyCode.Eight] = 8,
    [Enum.KeyCode.Nine] = 9,
}

-- Global state for keyboard handling
local currentCallback = nil
local currentSlotCount = 3
local inputConnection = nil

-- Setup global keyboard listener (once)
local function setupKeyboardListener()
    if inputConnection then return end
    
    inputConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        
        local slotIndex = SLOT_KEYS[input.KeyCode]
        if slotIndex and slotIndex <= currentSlotCount and currentCallback then
            currentCallback(slotIndex)
        end
    end)
end

local function createSlot(props)
    local index = props.index
    local item = props.item
    local isSelected = props.isSelected
    local onClick = props.onClick
    local slotSize = props.slotSize
    
    local hasItem = item ~= nil
    local bgColor = isSelected and Theme.Primary or Theme.BackgroundCard
    local strokeColor = isSelected and Theme.PrimaryLight or Theme.StrokeColor
    local strokeThickness = isSelected and 2 or 1
    
    return Roact.createElement("TextButton", {
        Name = "Slot" .. index,
        Size = UDim2.new(0, slotSize, 0, slotSize),
        BackgroundColor3 = bgColor,
        BackgroundTransparency = 0.2,
        Text = "",
        AutoButtonColor = false,
        LayoutOrder = index,
        Event = {
            MouseButton1Click = function(rbx)
                if onClick then onClick(index) end
                TweenService:Create(rbx, TweenInfo.new(0.1), {
                    Size = UDim2.new(0, slotSize - 6, 0, slotSize - 6)
                }):Play()
                task.delay(0.1, function()
                    TweenService:Create(rbx, TweenInfo.new(0.15, Enum.EasingStyle.Back), {
                        Size = UDim2.new(0, slotSize, 0, slotSize)
                    }):Play()
                end)
            end,
            MouseEnter = function(rbx)
                TweenService:Create(rbx, TweenInfo.new(0.1), {
                    BackgroundTransparency = 0
                }):Play()
            end,
            MouseLeave = function(rbx)
                TweenService:Create(rbx, TweenInfo.new(0.1), {
                    BackgroundTransparency = 0.2
                }):Play()
            end
        }
    }, {
        Corner = Roact.createElement("UICorner", { CornerRadius = UDim.new(0, 8) }),
        Stroke = Roact.createElement("UIStroke", {
            Color = strokeColor,
            Thickness = strokeThickness,
            Transparency = isSelected and 0 or 0.5
        }),
        
        SlotNumber = Roact.createElement("TextLabel", {
            Size = UDim2.new(0, 14, 0, 14),
            Position = UDim2.new(0, 2, 0, 2),
            BackgroundColor3 = Theme.Background,
            BackgroundTransparency = 0.3,
            Text = tostring(index),
            TextColor3 = isSelected and Theme.Primary or Theme.TextMuted,
            TextSize = 9,
            Font = Theme.FontBold
        }, {
            Corner = Roact.createElement("UICorner", { CornerRadius = UDim.new(0, 4) })
        }),
        
        ItemIcon = hasItem and (item.icon and item.icon ~= "" and item.icon ~= "rbxassetid://0" and Roact.createElement("ImageLabel", {
            Size = UDim2.new(0, math.floor(slotSize * 0.6), 0, math.floor(slotSize * 0.6)),
            Position = UDim2.new(0.5, 0, 0.5, 0),
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundTransparency = 1,
            Image = item.icon,
            ImageColor3 = Color3.new(1, 1, 1)
        }) or Roact.createElement("TextLabel", {
            Size = UDim2.new(0, math.floor(slotSize * 0.6), 0, math.floor(slotSize * 0.6)),
            Position = UDim2.new(0.5, 0, 0.5, 0),
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundTransparency = 1,
            Text = item.emoji or "?",
            TextSize = math.floor(slotSize * 0.45),
            Font = Theme.FontRegular,
            TextColor3 = Color3.new(1, 1, 1)
        })) or nil,
        
        ItemCount = (hasItem and item.count and item.count > 1) and Roact.createElement("TextLabel", {
            Size = UDim2.new(0, 18, 0, 12),
            Position = UDim2.new(1, -2, 1, -2),
            AnchorPoint = Vector2.new(1, 1),
            BackgroundColor3 = Theme.Background,
            BackgroundTransparency = 0.2,
            Text = tostring(item.count),
            TextColor3 = Theme.TextPrimary,
            TextSize = 9,
            Font = Theme.FontBold
        }, {
            Corner = Roact.createElement("UICorner", { CornerRadius = UDim.new(0, 4) })
        }) or nil
    })
end

-- Functional component
function Hotbar.create(props)
    local items = props.items or {}
    local selectedSlot = props.selectedSlot or 1
    local slotCount = props.slotCount or 3
    local onSlotSelect = props.onSlotSelect
    local onUseItem = props.onUseItem
    
    local sizes = ResponsiveUtil.getSizes()
    local slotSize = sizes.hotbarSlotSize
    local slotPadding = sizes.hotbarPadding
    local margin = sizes.margin
    
    -- Update global slot count for keyboard
    currentSlotCount = math.min(slotCount, MAX_SLOTS)
    
    -- Setup keyboard listener and callback
    setupKeyboardListener()
    currentCallback = function(index)
        if onSlotSelect then
            onSlotSelect(index, items[index])
        end
        if onUseItem and items[index] then
            onUseItem(index, items[index])
        end
    end
    
    local slots = {
        Layout = Roact.createElement("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            HorizontalAlignment = Enum.HorizontalAlignment.Center,
            VerticalAlignment = Enum.VerticalAlignment.Center,
            Padding = UDim.new(0, slotPadding),
            SortOrder = Enum.SortOrder.LayoutOrder
        })
    }
    
    -- Create only the number of slots needed
    for i = 1, currentSlotCount do
        slots["Slot" .. i] = createSlot({
            index = i,
            item = items[i],
            isSelected = selectedSlot == i,
            slotSize = slotSize,
            onClick = function(idx)
                if onSlotSelect then
                    onSlotSelect(idx, items[idx])
                end
                if onUseItem and items[idx] then
                    onUseItem(idx, items[idx])
                end
            end
        })
    end
    
    local hotbarWidth = (slotSize + slotPadding) * currentSlotCount + 16
    local hotbarHeight = slotSize + 12
    
    return Roact.createElement("Frame", {
        Name = "Hotbar",
        Size = UDim2.new(0, hotbarWidth, 0, hotbarHeight),
        Position = UDim2.new(0.5, 0, 1, -margin),
        AnchorPoint = Vector2.new(0.5, 1),
        BackgroundColor3 = Theme.Background,
        BackgroundTransparency = 0.3
    }, {
        Corner = Roact.createElement("UICorner", { CornerRadius = UDim.new(0, 10) }),
        Stroke = Roact.createElement("UIStroke", {
            Color = Theme.StrokeColor,
            Thickness = 1,
            Transparency = 0.5
        }),
        Padding = Roact.createElement("UIPadding", {
            PaddingLeft = UDim.new(0, 8),
            PaddingRight = UDim.new(0, 8),
            PaddingTop = UDim.new(0, 6),
            PaddingBottom = UDim.new(0, 6)
        }),
        
        SlotsContainer = Roact.createElement("Frame", {
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1
        }, slots)
    })
end

return Hotbar
