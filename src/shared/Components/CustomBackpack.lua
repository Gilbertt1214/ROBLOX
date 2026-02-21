--[[
    Custom Backpack Component (Hotbar)
    Shows tools that are "in hotbar" 
    Click slot = character equip/unequip (hold/drop tool)
    Hotkey 1-9 = select slot
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local StarterGui = game:GetService("StarterGui")

local Roact = require(ReplicatedStorage.Shared.Roact)
local Theme = require(ReplicatedStorage.Shared.Theme)
local ZIndex = require(ReplicatedStorage.Shared.ZIndex)
local Logger = require(ReplicatedStorage.Shared.Logger)

local CustomBackpack = {}

local LocalPlayer = Players.LocalPlayer
local ResponsiveUtil = require(ReplicatedStorage.Shared.ResponsiveUtil)
local MAX_SLOTS = 9

-- Shared state: which tools are in hotbar (by name)
CustomBackpack.hotbarTools = {} -- { "Sword", "Flash Light", ... }

-- Callback for when hotbar changes (set by HotbarUI)
CustomBackpack.onHotbarChanged = nil

-- Hotkey connection (initialized once)
local hotkeyConnection = nil

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

-- Get currently equipped tool name
local function getEquippedToolName()
    local player = LocalPlayer
    if player.Character then
        for _, child in pairs(player.Character:GetChildren()) do
            if child:IsA("Tool") then
                return child.Name
            end
        end
    end
    return nil
end

-- Find which slot has the equipped tool
local function getEquippedSlot()
    local equippedName = getEquippedToolName()
    if not equippedName then return nil end
    
    for i, toolName in ipairs(CustomBackpack.hotbarTools) do
        if toolName == equippedName then
            return i
        end
    end
    return nil
end

-- Toggle slot (equip/unequip) - can be called from hotkey or click
function CustomBackpack.toggleSlot(slotIndex)
    local toolName = CustomBackpack.hotbarTools[slotIndex]
    local player = LocalPlayer
    
    if not player.Character then return end
    local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end
    
    -- If slot is empty, just unequip current tool
    if not toolName then
        humanoid:UnequipTools()
        if CustomBackpack.onHotbarChanged then CustomBackpack.onHotbarChanged() end
        return
    end
    
    local equippedSlot = getEquippedSlot()
    
    -- If clicking same slot that's equipped, unequip
    if equippedSlot == slotIndex then
        humanoid:UnequipTools()
        if CustomBackpack.onHotbarChanged then CustomBackpack.onHotbarChanged() end
        return
    end
    
    -- Equip tool from slot
    local tool = player.Backpack:FindFirstChild(toolName)
    if tool then
        if tool:IsA("Tool") then
            tool.Enabled = true
        end
        humanoid:EquipTool(tool)
    end
    
    if CustomBackpack.onHotbarChanged then CustomBackpack.onHotbarChanged() end
end

-- Initialize hotkey listener (call once)
function CustomBackpack.initHotkeys()
    if hotkeyConnection then return end
    
    hotkeyConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        
        local slotIndex = SLOT_KEYS[input.KeyCode]
        if slotIndex then
            local visibleSlots = math.max(3, math.min(#CustomBackpack.hotbarTools + 1, MAX_SLOTS))
            if slotIndex <= visibleSlots then
                CustomBackpack.toggleSlot(slotIndex)
            end
        end
    end)
end

-- Add tool to hotbar
function CustomBackpack.addToHotbar(toolName)
    if #CustomBackpack.hotbarTools >= MAX_SLOTS then return false end
    if table.find(CustomBackpack.hotbarTools, toolName) then return false end
    table.insert(CustomBackpack.hotbarTools, toolName)
    if CustomBackpack.onHotbarChanged then
        CustomBackpack.onHotbarChanged()
    end
    return true
end

-- Remove tool from hotbar
function CustomBackpack.removeFromHotbar(toolName)
    local index = table.find(CustomBackpack.hotbarTools, toolName)
    if index then
        table.remove(CustomBackpack.hotbarTools, index)
        
        -- Unequip if currently equipped
        local player = LocalPlayer
        if player.Character then
            local tool = player.Character:FindFirstChild(toolName)
            if tool then
                local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
                if humanoid then
                    humanoid:UnequipTools()
                end
            end
        end
        
        if CustomBackpack.onHotbarChanged then
            CustomBackpack.onHotbarChanged()
        end
        return true
    end
    return false
end

-- Check if tool is in hotbar
function CustomBackpack.isInHotbar(toolName)
    return table.find(CustomBackpack.hotbarTools, toolName) ~= nil
end

-- Create a single slot
local function createSlot(props)
    local index = props.index
    local tool = props.tool
    local isEquipped = props.isEquipped
    local onClick = props.onClick
    local sizes = props.sizes
    local slotSize = sizes.hotbarSlotSize
    
    local hasTool = tool ~= nil
    local bgColor = isEquipped and Theme.Primary or Theme.BackgroundCard
    local strokeColor = isEquipped and Theme.PrimaryLight or Theme.StrokeColor
    
    local iconImage = nil
    if tool and tool.TextureId and tool.TextureId ~= "" then
        iconImage = tool.TextureId
    end
    
    local children = {
        Corner = Roact.createElement("UICorner", { CornerRadius = UDim.new(0, 10) }),
        Stroke = Roact.createElement("UIStroke", {
            Color = strokeColor,
            Thickness = isEquipped and 2 or 1,
            Transparency = isEquipped and 0 or 0.5
        }),
        SlotNumber = Roact.createElement("TextLabel", {
            Size = UDim2.new(0, 18, 0, 18),
            Position = UDim2.new(0, 3, 0, 3),
            BackgroundColor3 = Theme.Background,
            BackgroundTransparency = 0.3,
            Text = tostring(index),
            TextColor3 = isEquipped and Theme.Primary or Theme.TextMuted,
            TextSize = 11,
            Font = Theme.FontBold,
            ZIndex = ZIndex.CONTENT
        }, {
            Corner = Roact.createElement("UICorner", { CornerRadius = UDim.new(0, 5) })
        }),
    }
    
    if hasTool then
        if iconImage then
            children.ToolIcon = Roact.createElement("ImageLabel", {
                Size = UDim2.new(0, math.floor(slotSize * 0.7), 0, math.floor(slotSize * 0.7)),
                Position = UDim2.new(0.5, 0, 0.5, 0),
                AnchorPoint = Vector2.new(0.5, 0.5),
                BackgroundTransparency = 1,
                Image = iconImage,
                ScaleType = Enum.ScaleType.Fit
            })
        else
            children.ToolName = Roact.createElement("TextLabel", {
                Size = UDim2.new(1, -6, 0, 20),
                Position = UDim2.new(0.5, 0, 0.5, 0),
                AnchorPoint = Vector2.new(0.5, 0.5),
                BackgroundTransparency = 1,
                Text = string.sub(tool.Name, 1, 6),
                TextColor3 = Color3.new(1, 1, 1),
                TextSize = 10,
                Font = Theme.FontMedium,
                TextTruncate = Enum.TextTruncate.AtEnd
            })
        end
    end
    
    if isEquipped then
        children.EquippedGlow = Roact.createElement("Frame", {
            Size = UDim2.new(1, 6, 1, 6),
            Position = UDim2.new(0.5, 0, 0.5, 0),
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundTransparency = 1,
            ZIndex = ZIndex.BACKGROUND
        }, {
            Corner = Roact.createElement("UICorner", { CornerRadius = UDim.new(0, 12) }),
            Stroke = Roact.createElement("UIStroke", {
                Color = Theme.Primary,
                Thickness = 2,
                Transparency = 0.4
            })
        })
    end
    
    return Roact.createElement("TextButton", {
        Name = "Slot" .. index,
        Size = UDim2.new(0, slotSize, 0, slotSize),
        BackgroundColor3 = bgColor,
        BackgroundTransparency = 0.15,
        Text = "",
        AutoButtonColor = false,
        LayoutOrder = index,
        Event = {
            MouseButton1Click = function(rbx)
                if onClick then onClick() end
                TweenService:Create(rbx, TweenInfo.new(0.06), {
                    Size = UDim2.new(0, slotSize - 8, 0, slotSize - 8)
                }):Play()
                task.delay(0.06, function()
                    TweenService:Create(rbx, TweenInfo.new(0.1, Enum.EasingStyle.Back), {
                        Size = UDim2.new(0, slotSize, 0, slotSize)
                    }):Play()
                end)
            end,
            MouseEnter = function(rbx)
                TweenService:Create(rbx, TweenInfo.new(0.1), {
                    BackgroundTransparency = 0,
                    Size = UDim2.new(0, slotSize + 4, 0, slotSize + 4)
                }):Play()
            end,
            MouseLeave = function(rbx)
                TweenService:Create(rbx, TweenInfo.new(0.1), {
                    BackgroundTransparency = 0.15,
                    Size = UDim2.new(0, slotSize, 0, slotSize)
                }):Play()
            end
        }
    }, children)
end

-- Main Hotbar Component
local HotbarUI = Roact.Component:extend("HotbarUI")

function HotbarUI:init()
    self.state = {
        updateTrigger = 0
    }
    self.connections = {}
end

function HotbarUI:findTool(toolName)
    local player = LocalPlayer
    if player.Character then
        local tool = player.Character:FindFirstChild(toolName)
        if tool and tool:IsA("Tool") then return tool end
    end
    if player.Backpack then
        local tool = player.Backpack:FindFirstChild(toolName)
        if tool and tool:IsA("Tool") then return tool end
    end
    return nil
end

function HotbarUI:updateState()
    self:setState(function(state)
        return { 
            updateTrigger = state.updateTrigger + 1
        }
    end)
end

function HotbarUI:didMount()
    local player = LocalPlayer
    
    -- Register callback for hotbar changes
    CustomBackpack.onHotbarChanged = function()
        self:updateState()
    end
    
    -- Initialize hotkeys (only once globally)
    CustomBackpack.initHotkeys()
    
    local function setupListeners()
        if player.Backpack then
            table.insert(self.connections, player.Backpack.ChildAdded:Connect(function(child)
                task.wait(0.05)
                self:updateState()
            end))
            table.insert(self.connections, player.Backpack.ChildRemoved:Connect(function()
                task.wait(0.05)
                self:updateState()
            end))
        end
    end
    
    local function setupCharacter(character)
        if not character then return end
        table.insert(self.connections, character.ChildAdded:Connect(function(child)
            if child:IsA("Tool") then
                task.wait(0.05)
                self:updateState()
            end
        end))
        table.insert(self.connections, character.ChildRemoved:Connect(function(child)
            if child:IsA("Tool") then
                task.wait(0.05)
                self:updateState()
            end
        end))
    end
    
    setupListeners()
    if player.Character then setupCharacter(player.Character) end
    
    table.insert(self.connections, player.CharacterAdded:Connect(function(char)
        task.wait(0.1)
        setupListeners()
        setupCharacter(char)
        self:updateState()
    end))
    
    self:updateState()
end

function HotbarUI:willUnmount()
    for _, conn in ipairs(self.connections) do
        conn:Disconnect()
    end
end

function HotbarUI:render()
    local hotbarTools = CustomBackpack.hotbarTools
    local equippedSlot = getEquippedSlot() -- Use shared function
    local slotCount = math.max(3, math.min(#hotbarTools + 1, MAX_SLOTS))
    local sizes = ResponsiveUtil.getSizes()
    local slotSize = sizes.hotbarSlotSize
    local slotPadding = sizes.hotbarPadding
    
    local slots = {
        Layout = Roact.createElement("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            HorizontalAlignment = Enum.HorizontalAlignment.Center,
            VerticalAlignment = Enum.VerticalAlignment.Center,
            Padding = UDim.new(0, slotPadding),
            SortOrder = Enum.SortOrder.LayoutOrder
        })
    }
    
    for i = 1, slotCount do
        local toolName = hotbarTools[i]
        local tool = toolName and self:findTool(toolName) or nil
        local isEquipped = (equippedSlot == i)
        
        slots["Slot" .. i] = createSlot({
            index = i,
            tool = tool,
            isEquipped = isEquipped,
            sizes = sizes,
            onClick = function()
                CustomBackpack.toggleSlot(i) -- Use shared function
            end
        })
    end
    
    local hotbarWidth = (slotSize + slotPadding) * slotCount + 24
    
    return Roact.createElement("Frame", {
        Name = "CustomBackpack",
        Size = UDim2.new(0, hotbarWidth, 0, slotSize + 16),
        Position = UDim2.new(0.5, 0, 1, -12),
        AnchorPoint = Vector2.new(0.5, 1),
        BackgroundColor3 = Theme.Background,
        BackgroundTransparency = 0.2
    }, {
        Corner = Roact.createElement("UICorner", { CornerRadius = UDim.new(0, 14) }),
        Stroke = Roact.createElement("UIStroke", {
            Color = Theme.StrokeColor,
            Thickness = 1,
            Transparency = 0.4
        }),
        Padding = Roact.createElement("UIPadding", {
            PaddingLeft = UDim.new(0, 12),
            PaddingRight = UDim.new(0, 12),
            PaddingTop = UDim.new(0, 8),
            PaddingBottom = UDim.new(0, 8)
        }),
        SlotsContainer = Roact.createElement("Frame", {
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1
        }, slots)
    })
end

function CustomBackpack.create()
    return Roact.createElement(HotbarUI)
end

function CustomBackpack.hideDefault()
    local success = false
    local attempts = 0
    while not success and attempts < 10 do
        success = Logger.safeCall("CustomBackpack", "disableCoreGui", function()
            StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
        end)
        if not success then
            task.wait(0.5)
            attempts = attempts + 1
        end
    end
    return success
end

return CustomBackpack
