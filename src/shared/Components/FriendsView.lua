--[[
    FriendsView Component
    Displays REAL friend list from Roblox API with Invite functionality
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SocialService = game:GetService("SocialService")
local Players = game:GetService("Players")
local Roact = require(ReplicatedStorage.Shared.Roact)
local Theme = require(ReplicatedStorage.Shared.Theme)
local ResponsiveUtil = require(ReplicatedStorage.Shared.ResponsiveUtil)

local FriendsView = {}

local function createFriendItem(props)
    local friend = props.friend
    local friendId = friend.Id or friend.VisitorId or 0
    local name = friend.DisplayName or friend.Username or "Unknown"
    local username = friend.Username or ""
    local isOnline = friend.IsOnline or false
    local localPlayer = Players.LocalPlayer
    local itemHeight = props.itemHeight or 60
    local isPhone = props.isPhone or false
    local avatarSize = isPhone and 32 or 40
    
    return Roact.createElement("Frame", {
        Size = UDim2.new(1, 0, 0, itemHeight),
        BackgroundColor3 = Theme.BackgroundLight,
        BackgroundTransparency = 0.5,
    }, {
        Corner = Roact.createElement("UICorner", { CornerRadius = UDim.new(0, 8) }),
        Avatar = Roact.createElement("ImageLabel", {
            Size = UDim2.new(0, avatarSize, 0, avatarSize),
            Position = UDim2.new(0, isPhone and 6 or 10, 0.5, 0),
            AnchorPoint = Vector2.new(0, 0.5),
            BackgroundColor3 = Theme.BackgroundCard,
            Image = friendId > 0 and ("rbxthumb://type=AvatarHeadShot&id=" .. tostring(friendId) .. "&w=48&h=48") or "",
            BackgroundTransparency = 0
        }, {
            Corner = Roact.createElement("UICorner", { CornerRadius = UDim.new(1, 0) })
        }),
        NameLabel = Roact.createElement("TextLabel", {
            Size = UDim2.new(1, isPhone and -120 or -180, 0, 18),
            Position = UDim2.new(0, avatarSize + (isPhone and 12 or 20), 0.5, isPhone and -8 or -10),
            Text = name,
            TextColor3 = Theme.TextPrimary,
            TextSize = isPhone and 12 or 14,
            Font = Theme.FontMedium,
            TextXAlignment = Enum.TextXAlignment.Left,
            BackgroundTransparency = 1,
            TextTruncate = Enum.TextTruncate.AtEnd
        }),
        StatusLabel = Roact.createElement("TextLabel", {
            Size = UDim2.new(0, 80, 0, 16),
            Position = UDim2.new(0, avatarSize + (isPhone and 12 or 20), 0.5, isPhone and 6 or 10),
            Text = isOnline and "Online" or "Offline",
            TextColor3 = isOnline and Theme.Success or Theme.TextMuted,
            TextSize = isPhone and 9 or 10,
            Font = Theme.FontRegular,
            TextXAlignment = Enum.TextXAlignment.Left,
            BackgroundTransparency = 1
        }),
        
        Buttons = Roact.createElement("Frame", {
            Size = UDim2.new(0, isPhone and 55 or 120, 1, 0),
            Position = UDim2.new(1, -6, 0, 0),
            AnchorPoint = Vector2.new(1, 0),
            BackgroundTransparency = 1
        }, {
            Layout = Roact.createElement("UIListLayout", {
                FillDirection = Enum.FillDirection.Horizontal,
                HorizontalAlignment = Enum.HorizontalAlignment.Right,
                VerticalAlignment = Enum.VerticalAlignment.Center,
                Padding = UDim.new(0, 5)
            }),
            InviteButton = Roact.createElement("TextButton", {
                Size = UDim2.new(0, isPhone and 50 or 60, 0, isPhone and 24 or 28),
                BackgroundColor3 = Theme.Primary,
                Text = "Invite",
                TextColor3 = Theme.TextPrimary,
                Font = Theme.FontBold,
                TextSize = isPhone and 10 or 11,
                Event = {
                    MouseButton1Click = function()
                        -- print("[UI] Inviting:", name)
                        pcall(function()
                            SocialService:PromptGameInvite(localPlayer)
                        end)
                    end
                }
            }, {
                Corner = Roact.createElement("UICorner", { CornerRadius = UDim.new(0, 6) })
            })
        })
    })
end

function FriendsView.create(props)
    props = props or {}
    local friends = props.friends or {}
    
    local sizes = ResponsiveUtil.getSizes()
    local isPhone = ResponsiveUtil.isPhone()
    local isMobile = ResponsiveUtil.isMobile()
    
    -- Responsive sizes - smaller for phone to avoid overlap
    local panelWidth = isPhone and 240 or (isMobile and 320 or 360)
    local panelHeight = isPhone and 280 or (isMobile and 340 or 380)
    local itemHeight = isPhone and 48 or 56
    local titleSize = sizes.fontSize.title
    
    local children = {
        Layout = Roact.createElement("UIListLayout", {
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, isPhone and 6 or 10)
        }),
    }
    
    -- Sort: Online friends first
    local sortedFriends = {}
    for _, f in ipairs(friends) do table.insert(sortedFriends, f) end
    table.sort(sortedFriends, function(a, b) 
        if a.IsOnline == b.IsOnline then
            return (a.DisplayName or "") < (b.DisplayName or "")
        end
        return a.IsOnline and not b.IsOnline
    end)
    
    for i, friend in ipairs(sortedFriends) do
        local friendId = friend.Id or friend.VisitorId or i
        children["Friend_" .. tostring(friendId)] = createFriendItem({ 
            friend = friend,
            itemHeight = itemHeight,
            isPhone = isPhone
        })
    end
    
    if #friends == 0 then
        children.Loading = Roact.createElement("TextLabel", {
            Size = UDim2.new(1, 0, 0, 50),
            Text = "Memuat daftar teman...",
            TextColor3 = Theme.TextSecondary,
            TextSize = sizes.fontSize.medium,
            Font = Theme.FontMedium,
            BackgroundTransparency = 1
        })
    end
    
    return Roact.createElement("Frame", {
        Name = "FriendsView",
        Size = UDim2.new(0, panelWidth, 0, panelHeight),
        Position = UDim2.new(0.5, 0, 0.5, isPhone and -30 or -40),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = Theme.Background,
        BackgroundTransparency = 0.1,
    }, {
        Corner = Roact.createElement("UICorner", { CornerRadius = UDim.new(0, isPhone and 12 or 16) }),
        Title = Roact.createElement("TextLabel", {
            Size = UDim2.new(1, 0, 0, isPhone and 40 or 50),
            Text = "FRIENDS (" .. #friends .. ")",
            TextColor3 = Color3.fromRGB(168, 85, 247),
            TextSize = titleSize,
            Font = Theme.FontBold,
            BackgroundTransparency = 1
        }),
        Container = Roact.createElement("ScrollingFrame", {
            Size = UDim2.new(1, -20, 1, isPhone and -50 or -70),
            Position = UDim2.new(0, 10, 0, isPhone and 45 or 60),
            BackgroundTransparency = 1,
            ScrollBarThickness = 2,
            CanvasSize = UDim2.new(0, 0, 0, 0),
            AutomaticCanvasSize = Enum.AutomaticSize.Y
        }, children)
    })
end

return FriendsView
