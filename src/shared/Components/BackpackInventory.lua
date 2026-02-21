--[[
    Backpack Inventory Component
    Shows all tools from player's Roblox Backpack
    Click = Add to hotbar / Remove from hotbar
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local Roact = require(ReplicatedStorage.Shared.Roact)
local Theme = require(ReplicatedStorage.Shared.Theme)
local ResponsiveUtil = require(ReplicatedStorage.Shared.ResponsiveUtil)
local CustomBackpack = require(ReplicatedStorage.Shared.Components.CustomBackpack)

local BackpackInventory = {}
local LocalPlayer = Players.LocalPlayer

-- Create item card
local function createItemCard(props)
    local tool = props.tool
    local inHotbar = props.inHotbar
    local onClick = props.onClick
    
    local name = tool.Name
    local icon = (tool.TextureId and tool.TextureId ~= "") and tool.TextureId or nil
    
    local children = {
        Corner = Roact.createElement("UICorner", { CornerRadius = UDim.new(0, 10) }),
        Stroke = Roact.createElement("UIStroke", {
            Color = inHotbar and Theme.Primary or Theme.StrokeColor,
            Thickness = inHotbar and 2 or 1,
            Transparency = inHotbar and 0 or 0.5
        }),
        IconArea = Roact.createElement("Frame", {
            Size = UDim2.new(1, -10, 0, 55),
            Position = UDim2.new(0.5, 0, 0, 5),
            AnchorPoint = Vector2.new(0.5, 0),
            BackgroundColor3 = Theme.BackgroundCard,
            BackgroundTransparency = 0.5
        }, {
            Corner = Roact.createElement("UICorner", { CornerRadius = UDim.new(0, 8) }),
            Icon = icon and Roact.createElement("ImageLabel", {
                Size = UDim2.new(0, 45, 0, 45),
                Position = UDim2.new(0.5, 0, 0.5, 0),
                AnchorPoint = Vector2.new(0.5, 0.5),
                BackgroundTransparency = 1,
                Image = icon,
                ScaleType = Enum.ScaleType.Fit
            }) or Roact.createElement("TextLabel", {
                Size = UDim2.new(1, -4, 1, -4),
                Position = UDim2.new(0.5, 0, 0.5, 0),
                AnchorPoint = Vector2.new(0.5, 0.5),
                BackgroundTransparency = 1,
                Text = string.sub(name, 1, 8),
                TextColor3 = Theme.TextMuted,
                TextSize = 11,
                Font = Theme.FontMedium,
                TextWrapped = true
            })
        }),
        NameLabel = Roact.createElement("TextLabel", {
            Size = UDim2.new(1, -8, 0, 20),
            Position = UDim2.new(0, 4, 0, 62),
            BackgroundTransparency = 1,
            Text = name,
            TextColor3 = Theme.TextPrimary,
            TextSize = 11,
            Font = Theme.FontMedium,
            TextTruncate = Enum.TextTruncate.AtEnd,
            TextXAlignment = Enum.TextXAlignment.Center
        }),
        StatusLabel = Roact.createElement("TextLabel", {
            Size = UDim2.new(1, -8, 0, 16),
            Position = UDim2.new(0, 4, 1, -20),
            BackgroundTransparency = 1,
            Text = inHotbar and "Unuse" or "Use",
            TextColor3 = inHotbar and Theme.Primary or Theme.TextMuted,
            TextSize = 9,
            Font = Theme.FontMedium,
            TextXAlignment = Enum.TextXAlignment.Center
        }),
    }
    
    if inHotbar then
        children.HotbarBadge = Roact.createElement("Frame", {
            Size = UDim2.new(0, 18, 0, 18),
            Position = UDim2.new(1, -4, 0, 4),
            AnchorPoint = Vector2.new(1, 0),
            BackgroundColor3 = Theme.Primary
        }, {
            Corner = Roact.createElement("UICorner", { CornerRadius = UDim.new(1, 0) }),
            Check = Roact.createElement("TextLabel", {
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                Text = "✓",
                TextColor3 = Color3.new(1, 1, 1),
                TextSize = 11,
                Font = Theme.FontBold
            })
        })
    end
    
    return Roact.createElement("TextButton", {
        Size = UDim2.new(0, 95, 0, 105),
        BackgroundColor3 = Theme.BackgroundLight,
        BackgroundTransparency = 0.4,
        Text = "",
        AutoButtonColor = false,
        Event = {
            MouseButton1Click = function(rbx)
                if onClick then onClick() end
                TweenService:Create(rbx, TweenInfo.new(0.06), {
                    Size = UDim2.new(0, 90, 0, 100)
                }):Play()
                task.delay(0.06, function()
                    TweenService:Create(rbx, TweenInfo.new(0.1, Enum.EasingStyle.Back), {
                        Size = UDim2.new(0, 95, 0, 105)
                    }):Play()
                end)
            end,
            MouseEnter = function(rbx)
                TweenService:Create(rbx, TweenInfo.new(0.1), { 
                    BackgroundTransparency = 0.2,
                    Size = UDim2.new(0, 98, 0, 108)
                }):Play()
            end,
            MouseLeave = function(rbx)
                TweenService:Create(rbx, TweenInfo.new(0.1), { 
                    BackgroundTransparency = 0.4,
                    Size = UDim2.new(0, 95, 0, 105)
                }):Play()
            end
        }
    }, children)
end

-- Main component
local InventoryUI = Roact.Component:extend("BackpackInventoryUI")

function InventoryUI:init()
    self.state = {
        tools = {},
        updateTrigger = 0
    }
    self.connections = {}
end

function InventoryUI:getTools()
    local player = LocalPlayer
    local tools = {}
    
    -- Get from character (equipped)
    if player.Character then
        for _, child in pairs(player.Character:GetChildren()) do
            if child:IsA("Tool") then
                table.insert(tools, child)
            end
        end
    end
    
    -- Get from backpack
    if player.Backpack then
        for _, child in pairs(player.Backpack:GetChildren()) do
            if child:IsA("Tool") then
                table.insert(tools, child)
            end
        end
    end
    
    return tools
end

function InventoryUI:updateTools()
    local tools = self:getTools()
    self:setState(function(state)
        return { 
            tools = tools,
            updateTrigger = state.updateTrigger + 1
        }
    end)
end

function InventoryUI:toggleHotbar(toolName)
    if CustomBackpack.isInHotbar(toolName) then
        CustomBackpack.removeFromHotbar(toolName)
    else
        CustomBackpack.addToHotbar(toolName)
    end
    self:updateTools() -- Force re-render
end

function InventoryUI:didMount()
    local player = LocalPlayer
    
    local function connectBackpack()
        if player.Backpack then
            table.insert(self.connections, player.Backpack.ChildAdded:Connect(function(child)
                if child:IsA("Tool") then
                    task.wait(0.05)
                    -- Don't auto-add to hotbar, keep as unused
                    self:updateTools()
                end
            end))
            table.insert(self.connections, player.Backpack.ChildRemoved:Connect(function()
                task.wait(0.05)
                self:updateTools()
            end))
        end
    end
    
    local function setupCharacter(char)
        if not char then return end
        table.insert(self.connections, char.ChildAdded:Connect(function(c)
            if c:IsA("Tool") then 
                task.wait(0.05)
                self:updateTools() 
            end
        end))
        table.insert(self.connections, char.ChildRemoved:Connect(function(c)
            if c:IsA("Tool") then 
                task.wait(0.05)
                self:updateTools() 
            end
        end))
    end
    
    connectBackpack()
    if player.Character then setupCharacter(player.Character) end
    
    table.insert(self.connections, player.CharacterAdded:Connect(function(char)
        task.wait(0.5)
        connectBackpack()
        setupCharacter(char)
        self:updateTools()
    end))
    
    -- Don't auto-add tools to hotbar - let user manually add via "Use" button
    
    self:updateTools()
    -- print("[Inventory] Ready")
end

function InventoryUI:willUnmount()
    for _, c in ipairs(self.connections) do c:Disconnect() end
end

function InventoryUI:render()
    local tools = self.state.tools
    local isPhone = ResponsiveUtil.isPhone()
    local isMobile = ResponsiveUtil.isMobile()
    
    -- Responsive sizes
    local panelWidth = isPhone and 320 or (isMobile and 380 or 440)
    local panelHeight = isPhone and 320 or (isMobile and 350 or 380)
    local cardWidth = isPhone and 80 or 95
    local cardHeight = isPhone and 90 or 105
    
    -- Empty state
    if #tools == 0 then
        return Roact.createElement("Frame", {
            Name = "BackpackInventory",
            Size = UDim2.new(0, panelWidth, 0, panelHeight),
            Position = UDim2.new(0.5, 0, 0.5, isPhone and -30 or -40),
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundColor3 = Theme.Background,
            BackgroundTransparency = 0.05
        }, {
            Corner = Roact.createElement("UICorner", { CornerRadius = UDim.new(0, isPhone and 12 or 16) }),
            Stroke = Roact.createElement("UIStroke", {
                Color = Theme.Primary,
                Thickness = isPhone and 1 or 2,
                Transparency = 0.5
            }),
            Title = Roact.createElement("TextLabel", {
                Size = UDim2.new(1, 0, 0, isPhone and 34 or 40),
                BackgroundTransparency = 1,
                Text = "BACKPACK",
                TextColor3 = Theme.TextPrimary,
                TextSize = isPhone and 16 or 18,
                Font = Theme.FontBold
            }),
            Subtitle = Roact.createElement("TextLabel", {
                Size = UDim2.new(1, 0, 0, 18),
                Position = UDim2.new(0, 0, 0, isPhone and 30 or 35),
                BackgroundTransparency = 1,
                Text = "0 items",
                TextColor3 = Theme.TextMuted,
                TextSize = isPhone and 10 or 11,
                Font = Theme.FontRegular
            }),
            Empty = Roact.createElement("TextLabel", {
                Size = UDim2.new(1, -40, 0, 60),
                Position = UDim2.new(0.5, 0, 0.5, 20),
                AnchorPoint = Vector2.new(0.5, 0.5),
                BackgroundTransparency = 1,
                Text = "No items in backpack\nPick up items from the world!",
                TextColor3 = Theme.TextMuted,
                TextSize = isPhone and 12 or 14,
                Font = Theme.FontMedium,
                TextXAlignment = Enum.TextXAlignment.Center,
                TextYAlignment = Enum.TextYAlignment.Center,
                TextWrapped = true
            })
        })
    end
    
    -- Has items
    local children = {
        Layout = Roact.createElement("UIGridLayout", {
            CellSize = UDim2.new(0, cardWidth, 0, cardHeight),
            CellPadding = UDim2.new(0, isPhone and 8 or 10, 0, isPhone and 8 or 10),
            SortOrder = Enum.SortOrder.LayoutOrder
        })
    }
    
    for i, tool in ipairs(tools) do
        local toolName = tool.Name
        local inHotbar = CustomBackpack.isInHotbar(toolName)
        
        children["Tool_" .. i] = createItemCard({
            tool = tool,
            inHotbar = inHotbar,
            onClick = function()
                self:toggleHotbar(toolName)
            end
        })
    end
    
    return Roact.createElement("Frame", {
        Name = "BackpackInventory",
        Size = UDim2.new(0, panelWidth, 0, panelHeight),
        Position = UDim2.new(0.5, 0, 0.5, isPhone and -30 or -40),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = Theme.Background,
        BackgroundTransparency = 0.05
    }, {
        Corner = Roact.createElement("UICorner", { CornerRadius = UDim.new(0, isPhone and 12 or 16) }),
        Stroke = Roact.createElement("UIStroke", {
            Color = Theme.Primary,
            Thickness = isPhone and 1 or 2,
            Transparency = 0.5
        }),
        Title = Roact.createElement("TextLabel", {
            Size = UDim2.new(1, 0, 0, isPhone and 34 or 40),
            BackgroundTransparency = 1,
            Text = "BACKPACK",
            TextColor3 = Theme.TextPrimary,
            TextSize = isPhone and 16 or 18,
            Font = Theme.FontBold
        }),
        Subtitle = Roact.createElement("TextLabel", {
            Size = UDim2.new(1, 0, 0, 18),
            Position = UDim2.new(0, 0, 0, isPhone and 30 or 35),
            BackgroundTransparency = 1,
            Text = #tools .. " items",
            TextColor3 = Theme.TextMuted,
            TextSize = isPhone and 10 or 11,
            Font = Theme.FontRegular
        }),
        Container = Roact.createElement("ScrollingFrame", {
            Size = UDim2.new(1, -20, 1, isPhone and -55 or -70),
            Position = UDim2.new(0, 10, 0, isPhone and 50 or 60),
            BackgroundTransparency = 1,
            ScrollBarThickness = 4,
            ScrollBarImageColor3 = Theme.Primary,
            CanvasSize = UDim2.new(0, 0, 0, 0),
            AutomaticCanvasSize = Enum.AutomaticSize.Y
        }, children)
    })
end

function BackpackInventory.create()
    return Roact.createElement(InventoryUI)
end

return BackpackInventory
