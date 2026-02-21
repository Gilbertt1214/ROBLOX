--[[
    ProfileView Component
    Displays detailed player profile information
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Roact = require(ReplicatedStorage.Shared.Roact)
local Theme = require(ReplicatedStorage.Shared.Theme)
local ResponsiveUtil = require(ReplicatedStorage.Shared.ResponsiveUtil)
local ZIndex = require(ReplicatedStorage.Shared.ZIndex)
local Logger = require(ReplicatedStorage.Shared.Logger)

local ProfileView = {}

-- Get player's current avatar items (accessories, clothing)
local function getAvatarInfo(player)
    local items = {}
    local character = player.Character
    
    if character then
        for _, child in pairs(character:GetChildren()) do
            if child:IsA("Accessory") then
                table.insert(items, {
                    name = child.Name,
                    type = "Accessory"
                })
            elseif child:IsA("Shirt") then
                table.insert(items, {
                    name = "Shirt",
                    type = "Clothing",
                    id = child.ShirtTemplate
                })
            elseif child:IsA("Pants") then
                table.insert(items, {
                    name = "Pants",
                    type = "Clothing",
                    id = child.PantsTemplate
                })
            end
        end
    end
    
    return items
end

-- Get player info from server or overhead
local function getPlayerStats(player)
    local stats = {
        role = "Player",
        streak = 0,
        combatWins = 0,
        playTime = 0
    }
    
    -- Try to get from server remote
    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
    if remotes then
        local getPlayerInfo = remotes:FindFirstChild("GetPlayerInfo")
        if getPlayerInfo then
            local success, info = Logger.safeCall("ProfileView", "getPlayerInfo", function()
                return getPlayerInfo:InvokeServer(player.UserId)
            end)
            if success and info then
                stats.role = info.role or "Player"
                stats.streak = info.streak or 0
                stats.combatWins = info.combatWins or 0
                stats.playTime = info.playTime or 0
            end
        end
    end
    
    -- Fallback: try to read from overhead GUI
    if player.Character then
        local head = player.Character:FindFirstChild("Head")
        if head then
            local overhead = head:FindFirstChild("OverheadGui")
            if overhead then
                local container = overhead:FindFirstChild("Container")
                if container then
                    local roleLabel = container:FindFirstChild("Role")
                    if roleLabel and roleLabel.Text and roleLabel.Text ~= "" then
                        stats.role = roleLabel.Text
                    end
                    
                    local nameRow = container:FindFirstChild("NameRow")
                    if nameRow then
                        local streakNum = nameRow:FindFirstChild("StreakNum")
                        if streakNum and streakNum.Text then
                            stats.streak = tonumber(streakNum.Text) or 0
                        end
                    end
                end
            end
        end
    end
    
    return stats
end

-- Format play time
local function formatPlayTime(minutes)
    if minutes < 60 then
        return minutes .. " min"
    elseif minutes < 1440 then
        local hours = math.floor(minutes / 60)
        local mins = minutes % 60
        if mins > 0 then
            return hours .. "h " .. mins .. "m"
        end
        return hours .. " hours"
    else
        local days = math.floor(minutes / 1440)
        local hours = math.floor((minutes % 1440) / 60)
        if hours > 0 then
            return days .. "d " .. hours .. "h"
        end
        return days .. " days"
    end
end

-- Create avatar item row
local function createAvatarItemRow(props)
    local item = props.item
    local index = props.index
    local isPhone = props.isPhone
    
    return Roact.createElement("Frame", {
        Size = UDim2.new(1, 0, 0, isPhone and 28 or 32),
        BackgroundColor3 = Theme.BackgroundLight,
        BackgroundTransparency = 0.6,
        LayoutOrder = index
    }, {
        Corner = Roact.createElement("UICorner", { CornerRadius = UDim.new(0, 6) }),
        Padding = Roact.createElement("UIPadding", {
            PaddingLeft = UDim.new(0, 10),
            PaddingRight = UDim.new(0, 10)
        }),
        TypeLabel = Roact.createElement("TextLabel", {
            Size = UDim2.new(0, isPhone and 60 or 80, 1, 0),
            Position = UDim2.new(0, 0, 0, 0),
            BackgroundTransparency = 1,
            Text = item.type,
            TextColor3 = Theme.TextMuted,
            TextSize = isPhone and 10 or 11,
            Font = Enum.Font.Gotham,
            TextXAlignment = Enum.TextXAlignment.Left
        }),
        NameLabel = Roact.createElement("TextLabel", {
            Size = UDim2.new(1, isPhone and -60 or -80, 1, 0),
            Position = UDim2.new(0, isPhone and 60 or 80, 0, 0),
            BackgroundTransparency = 1,
            Text = item.name,
            TextColor3 = Theme.TextPrimary,
            TextSize = isPhone and 10 or 11,
            Font = Enum.Font.GothamMedium,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd
        })
    })
end

-- Create stat row
local function createStatRow(props)
    local label = props.label
    local value = props.value
    local color = props.color or Theme.TextPrimary
    local isPhone = props.isPhone
    local layoutOrder = props.layoutOrder
    
    return Roact.createElement("Frame", {
        Size = UDim2.new(1, 0, 0, isPhone and 36 or 42),
        BackgroundTransparency = 1,
        LayoutOrder = layoutOrder
    }, {
        Label = Roact.createElement("TextLabel", {
            Size = UDim2.new(0.5, 0, 1, 0),
            Position = UDim2.new(0, 0, 0, 0),
            BackgroundTransparency = 1,
            Text = label,
            TextColor3 = Theme.TextMuted,
            TextSize = isPhone and 12 or 14,
            Font = Enum.Font.Gotham,
            TextXAlignment = Enum.TextXAlignment.Left
        }),
        Value = Roact.createElement("TextLabel", {
            Size = UDim2.new(0.5, 0, 1, 0),
            Position = UDim2.new(0.5, 0, 0, 0),
            BackgroundTransparency = 1,
            Text = tostring(value),
            TextColor3 = color,
            TextSize = isPhone and 12 or 14,
            Font = Enum.Font.GothamBold,
            TextXAlignment = Enum.TextXAlignment.Right
        })
    })
end

function ProfileView.create(props)
    local player = props.player
    local onClose = props.onClose
    
    if not player then return nil end
    
    local isPhone = ResponsiveUtil.isPhone()
    local isMobile = ResponsiveUtil.isMobile()
    
    -- Get player data
    local stats = getPlayerStats(player)
    local avatarItems = getAvatarInfo(player)
    
    -- Responsive sizes - smaller for phone
    local panelWidth = isPhone and 260 or (isMobile and 320 or 400)
    local panelHeight = isPhone and 420 or (isMobile and 480 or 560)
    local avatarSize = isPhone and 80 or 100
    
    -- Avatar items list
    local avatarItemsList = {
        Layout = Roact.createElement("UIListLayout", {
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 4)
        })
    }
    
    for i, item in ipairs(avatarItems) do
        if i <= 5 then -- Limit to 5 items
            avatarItemsList["Item_" .. i] = createAvatarItemRow({
                item = item,
                index = i,
                isPhone = isPhone
            })
        end
    end
    
    if #avatarItems == 0 then
        avatarItemsList.Empty = Roact.createElement("TextLabel", {
            Size = UDim2.new(1, 0, 0, 30),
            BackgroundTransparency = 1,
            Text = "No avatar items",
            TextColor3 = Theme.TextMuted,
            TextSize = isPhone and 11 or 12,
            Font = Enum.Font.Gotham
        })
    end
    
    return Roact.createElement("Frame", {
        Name = "ProfileView",
        Size = UDim2.new(0, panelWidth, 0, panelHeight),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = Theme.Background,
        BackgroundTransparency = 0.02
    }, {
        Corner = Roact.createElement("UICorner", { CornerRadius = UDim.new(0, isPhone and 14 or 18) }),
        
        -- Close button
        CloseBtn = Roact.createElement("TextButton", {
            Size = UDim2.new(0, 32, 0, 32),
            Position = UDim2.new(1, -8, 0, 8),
            AnchorPoint = Vector2.new(1, 0),
            BackgroundTransparency = 1,
            Text = "x",
            TextColor3 = Theme.TextMuted,
            TextSize = isPhone and 18 or 20,
            Font = Enum.Font.GothamBold,
            ZIndex = ZIndex.CLOSE_BUTTON,
            Event = {
                MouseButton1Click = function()
                    if onClose then onClose() end
                end
            }
        }),
        
        -- Header section
        Header = Roact.createElement("Frame", {
            Size = UDim2.new(1, 0, 0, avatarSize + 70),
            Position = UDim2.new(0, 0, 0, 0),
            BackgroundColor3 = Theme.BackgroundCard,
            BackgroundTransparency = 0.5
        }, {
            Corner = Roact.createElement("UICorner", { CornerRadius = UDim.new(0, isPhone and 14 or 18) }),
            
            -- Avatar
            Avatar = Roact.createElement("ImageLabel", {
                Size = UDim2.new(0, avatarSize, 0, avatarSize),
                Position = UDim2.new(0.5, 0, 0, isPhone and 16 or 20),
                AnchorPoint = Vector2.new(0.5, 0),
                BackgroundColor3 = Theme.BackgroundLight,
                Image = "rbxthumb://type=AvatarHeadShot&id=" .. tostring(player.UserId) .. "&w=150&h=150"
            }, {
                Corner = Roact.createElement("UICorner", { CornerRadius = UDim.new(0, isPhone and 12 or 16) }),
                Stroke = Roact.createElement("UIStroke", {
                    Color = Theme.Primary,
                    Thickness = 3,
                    Transparency = 0.3
                })
            }),
            
            -- Display Name (centered)
            DisplayName = Roact.createElement("TextLabel", {
                Size = UDim2.new(1, -40, 0, isPhone and 24 or 28),
                Position = UDim2.new(0.5, 0, 0, avatarSize + (isPhone and 20 or 24)),
                AnchorPoint = Vector2.new(0.5, 0),
                BackgroundTransparency = 1,
                Text = player.DisplayName,
                TextColor3 = Theme.TextPrimary,
                TextSize = isPhone and 18 or 22,
                Font = Enum.Font.GothamBold,
                TextTruncate = Enum.TextTruncate.AtEnd,
                TextXAlignment = Enum.TextXAlignment.Center
            }),
            
            -- Username (centered)
            Username = Roact.createElement("TextLabel", {
                Size = UDim2.new(1, -40, 0, isPhone and 16 or 18),
                Position = UDim2.new(0.5, 0, 0, avatarSize + (isPhone and 44 or 52)),
                AnchorPoint = Vector2.new(0.5, 0),
                BackgroundTransparency = 1,
                Text = "@" .. player.Name,
                TextColor3 = Theme.TextMuted,
                TextSize = isPhone and 12 or 14,
                Font = Enum.Font.Gotham,
                TextTruncate = Enum.TextTruncate.AtEnd,
                TextXAlignment = Enum.TextXAlignment.Center
            })
        }),
        
        -- Content section
        Content = Roact.createElement("Frame", {
            Size = UDim2.new(1, -24, 1, -(avatarSize + 90)),
            Position = UDim2.new(0, 12, 0, avatarSize + 80),
            BackgroundTransparency = 1
        }, {
            Layout = Roact.createElement("UIListLayout", {
                SortOrder = Enum.SortOrder.LayoutOrder,
                Padding = UDim.new(0, isPhone and 12 or 16)
            }),
            
            -- Stats Section
            StatsSection = Roact.createElement("Frame", {
                Size = UDim2.new(1, 0, 0, isPhone and 180 or 200),
                BackgroundColor3 = Theme.BackgroundCard,
                BackgroundTransparency = 0.6,
                LayoutOrder = 1
            }, {
                Corner = Roact.createElement("UICorner", { CornerRadius = UDim.new(0, 10) }),
                Padding = Roact.createElement("UIPadding", {
                    PaddingTop = UDim.new(0, 10),
                    PaddingBottom = UDim.new(0, 10),
                    PaddingLeft = UDim.new(0, 12),
                    PaddingRight = UDim.new(0, 12)
                }),
                
                Title = Roact.createElement("TextLabel", {
                    Size = UDim2.new(1, 0, 0, isPhone and 20 or 24),
                    BackgroundTransparency = 1,
                    Text = "STATS",
                    TextColor3 = Theme.Primary,
                    TextSize = isPhone and 11 or 12,
                    Font = Enum.Font.GothamBold,
                    TextXAlignment = Enum.TextXAlignment.Left
                }),
                
                StatsContainer = Roact.createElement("Frame", {
                    Size = UDim2.new(1, 0, 1, isPhone and -24 or -28),
                    Position = UDim2.new(0, 0, 0, isPhone and 24 or 28),
                    BackgroundTransparency = 1
                }, {
                    Layout = Roact.createElement("UIListLayout", {
                        SortOrder = Enum.SortOrder.LayoutOrder,
                        Padding = UDim.new(0, 2)
                    }),
                    
                    RoleStat = createStatRow({
                        label = "Role",
                        value = stats.role,
                        color = Theme.Primary,
                        isPhone = isPhone,
                        layoutOrder = 1
                    }),
                    
                    StreakStat = createStatRow({
                        label = "Streak",
                        value = stats.streak .. " days",
                        color = Color3.fromRGB(255, 180, 50),
                        isPhone = isPhone,
                        layoutOrder = 2
                    }),
                    
                    CombatWinsStat = createStatRow({
                        label = "Combat Wins",
                        value = stats.combatWins,
                        color = Color3.fromRGB(255, 100, 100),
                        isPhone = isPhone,
                        layoutOrder = 3
                    }),
                    
                    PlayTimeStat = createStatRow({
                        label = "Play Time",
                        value = formatPlayTime(stats.playTime),
                        color = Theme.TextPrimary,
                        isPhone = isPhone,
                        layoutOrder = 3
                    })
                })
            }),
            
            -- Avatar Items Section
            AvatarSection = Roact.createElement("Frame", {
                Size = UDim2.new(1, 0, 0, isPhone and 130 or 150),
                BackgroundColor3 = Theme.BackgroundCard,
                BackgroundTransparency = 0.6,
                LayoutOrder = 2
            }, {
                Corner = Roact.createElement("UICorner", { CornerRadius = UDim.new(0, 10) }),
                Padding = Roact.createElement("UIPadding", {
                    PaddingTop = UDim.new(0, 10),
                    PaddingBottom = UDim.new(0, 10),
                    PaddingLeft = UDim.new(0, 12),
                    PaddingRight = UDim.new(0, 12)
                }),
                
                Title = Roact.createElement("TextLabel", {
                    Size = UDim2.new(1, 0, 0, isPhone and 20 or 24),
                    BackgroundTransparency = 1,
                    Text = "AVATAR ITEMS",
                    TextColor3 = Theme.Primary,
                    TextSize = isPhone and 11 or 12,
                    Font = Enum.Font.GothamBold,
                    TextXAlignment = Enum.TextXAlignment.Left
                }),
                
                ItemsContainer = Roact.createElement("ScrollingFrame", {
                    Size = UDim2.new(1, 0, 1, isPhone and -24 or -28),
                    Position = UDim2.new(0, 0, 0, isPhone and 24 or 28),
                    BackgroundTransparency = 1,
                    ScrollBarThickness = 3,
                    ScrollBarImageColor3 = Theme.Primary,
                    CanvasSize = UDim2.new(0, 0, 0, 0),
                    AutomaticCanvasSize = Enum.AutomaticSize.Y
                }, avatarItemsList)
            })
        })
    })
end

return ProfileView
