--[[
    PopupMenuView Component
    Displays actions for a specific player from the dropdown list.
    With pop-in animation on mount.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Roact = require(ReplicatedStorage.Shared.Roact)
local Theme = require(ReplicatedStorage.Shared.Theme)
local ZIndex = require(ReplicatedStorage.Shared.ZIndex)
local Icons = require(ReplicatedStorage.Shared.Icons)

local PopupMenuView = Roact.Component:extend("PopupMenuView")

local function TextActionButton(props)
    local isPhone = props.isPhone
    return Roact.createElement("TextButton", {
        Size = UDim2.new(1, 0, 0, isPhone and 36 or 32),
        BackgroundTransparency = 1,
        Text = props.text,
        TextColor3 = props.color or Theme.TextPrimary,
        TextSize = isPhone and 14 or 14,
        Font = Enum.Font.GothamBold,
        TextXAlignment = isPhone and Enum.TextXAlignment.Center or Enum.TextXAlignment.Left,
        LayoutOrder = props.layoutOrder,
        ZIndex = ZIndex.MODAL_ACTIONS,
        [Roact.Event.Activated] = function()
            if props.onClick then props.onClick() end
        end
    })
end

function PopupMenuView:init()
    self.onFrameCreated = function(frame)
        if not frame then return end
        
        -- Create UIScale for animation
        local uiScale = Instance.new("UIScale")
        uiScale.Name = "PopupScale"
        uiScale.Scale = 0.5
        uiScale.Parent = frame
        
        -- Animate scale to 1
        task.defer(function()
            local tweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
            local tween = TweenService:Create(uiScale, tweenInfo, {
                Scale = 1
            })
            tween:Play()
        end)
    end
end


function PopupMenuView:render()
    local props = self.props
    local player = props.player
    local onClose = props.onClose
    local onAction = props.onAction
    local isPhone = props.isPhone or false
    local isMobile = props.isMobile or false
    local isFriendWithPlayer = props.isFriendWithPlayer
    
    if not player then return nil end
    
    -- Larger popup for mobile centered view
    local popupWidth = isPhone and 220 or (isMobile and 200 or 160)
    local avatarSize = isPhone and 64 or 55
    
    -- Calculate popup height based on content
    local buttonCount = 2 -- View Profile + Carry always
    if not isFriendWithPlayer then buttonCount = buttonCount + 1 end -- Add Friend
    if isFriendWithPlayer then buttonCount = buttonCount + 1 end -- Teleport
    
    -- Padding and spacing
    local titleHeight = isPhone and 45 or 40
    local footerPadding = isPhone and 20 or 14
    local popupHeight = avatarSize + titleHeight + (buttonCount * (isPhone and 40 or 32)) + (isPhone and 40 or 30)
    
    local LocalPlayer = game:GetService("Players").LocalPlayer
    local isSelf = (player.UserId == LocalPlayer.UserId)
    
    local actionButtons = {
        Layout = Roact.createElement("UIListLayout", {
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, isPhone and 6 or 2),
            HorizontalAlignment = Enum.HorizontalAlignment.Center
        }),
        
        -- View Profile
        ProfileBtn = Roact.createElement(TextActionButton, {
            text = isSelf and "My Profile" or "View Profile",
            layoutOrder = 1,
            isPhone = isPhone,
            onClick = function()
                if onAction then onAction("profile", player) end
            end
        }),
    }

    -- Other actions (only if NOT self)
    if not isSelf then
        -- Carry
        actionButtons.CarryBtn = Roact.createElement(TextActionButton, {
            text = "Carry",
            layoutOrder = 2,
            isPhone = isPhone,
            onClick = function()
                if onAction then onAction("carry", player) end
            end
        })

        -- Add Friend (only if NOT friend)
        if not isFriendWithPlayer then
            actionButtons.AddFriendBtn = Roact.createElement(TextActionButton, {
                text = "Add Friend",
                layoutOrder = 3,
                isPhone = isPhone,
                onClick = function()
                    if onAction then onAction("friend", player) end
                end
            })
        end

        -- Teleport (only if friend)
        if isFriendWithPlayer then
            actionButtons.TeleportBtn = Roact.createElement(TextActionButton, {
                text = "Teleport",
                layoutOrder = 4,
                isPhone = isPhone,
                onClick = function()
                    if onAction then onAction("teleport", player) end
                end
            })
        end
    end
    
    -- Position logic: Stay within parent bounds (PlayerDropdownRoot)
    local popupPosition = UDim2.new(0, 0, 0, 0)
    local popupAnchor = Vector2.new(0, 0)
    
    return Roact.createElement("Frame", {
        Size = UDim2.new(0, popupWidth, 0, popupHeight),
        Position = popupPosition,
        AnchorPoint = popupAnchor,
        BackgroundColor3 = Theme.Background,
        BackgroundTransparency = 0.05,
        Active = true, -- Block input to things behind
        ZIndex = ZIndex.MODAL_BACKGROUND,
        ref = self.onFrameCreated
    }, {
        Corner = Roact.createElement("UICorner", { CornerRadius = UDim.new(0, isPhone and 16 or 12) }),
        Stroke = Roact.createElement("UIStroke", {
            Color = Theme.Primary,
            Thickness = 1.5,
            Transparency = 0.6
        }),
        
        
        -- Content (Padded container)
        Content = Roact.createElement("Frame", {
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            ClipsDescendants = false,
            ZIndex = ZIndex.MODAL_CONTENT
        }, {
            Padding = Roact.createElement("UIPadding", {
                PaddingTop = UDim.new(0, isPhone and 20 or 14),
                PaddingBottom = UDim.new(0, isPhone and 20 or 14),
                PaddingLeft = UDim.new(0, isPhone and 12 or 14),
                PaddingRight = UDim.new(0, isPhone and 12 or 14)
            }),
            
            -- Header
            Header = Roact.createElement("Frame", {
                Size = UDim2.new(1, 0, 0, avatarSize + titleHeight),
                BackgroundTransparency = 1
            }, {
                Avatar = Roact.createElement("ImageLabel", {
                    Size = UDim2.new(0, avatarSize, 0, avatarSize),
                    Position = UDim2.new(0.5, 0, 0, 0),
                    AnchorPoint = Vector2.new(0.5, 0),
                    BackgroundColor3 = Theme.BackgroundCard,
                    Image = "rbxthumb://type=AvatarHeadShot&id=" .. tostring(player.UserId) .. "&w=150&h=150"
                }, {
                    Corner = Roact.createElement("UICorner", { CornerRadius = UDim.new(0.5, 0) }),
                    Stroke = Roact.createElement("UIStroke", { Color = Theme.Primary, Thickness = 2, Transparency = 0.7 })
                }),
                
                DisplayName = Roact.createElement("TextLabel", {
                    Size = UDim2.new(1, 0, 0, 20),
                    Position = UDim2.new(0.5, 0, 0, avatarSize + 8),
                    AnchorPoint = Vector2.new(0.5, 0),
                    BackgroundTransparency = 1,
                    Text = player.DisplayName,
                    TextColor3 = Theme.TextPrimary,
                    TextSize = isPhone and 15 or 14,
                    Font = Enum.Font.GothamBold,
                    TextXAlignment = Enum.TextXAlignment.Center,
                    TextTruncate = Enum.TextTruncate.AtEnd
                }),
                
                Username = Roact.createElement("TextLabel", {
                    Size = UDim2.new(1, 0, 0, 14),
                    Position = UDim2.new(0.5, 0, 0, avatarSize + 28),
                    AnchorPoint = Vector2.new(0.5, 0),
                    BackgroundTransparency = 1,
                    Text = "@" .. player.Name,
                    TextColor3 = Theme.TextMuted,
                    TextSize = isPhone and 12 or 11,
                    Font = Enum.Font.Gotham,
                    TextXAlignment = Enum.TextXAlignment.Center,
                    TextTruncate = Enum.TextTruncate.AtEnd
                })
            }),
            
            -- Actions
            Actions = Roact.createElement("Frame", {
                Size = UDim2.new(1, 0, 1, -avatarSize - titleHeight - 10),
                Position = UDim2.new(0, 0, 0, avatarSize + titleHeight + 10),
                BackgroundTransparency = 1,
                ZIndex = ZIndex.MODAL_ACTIONS
            }, actionButtons)
        })
    })
end

-- Keep backward compatibility with .render() function calls
PopupMenuView.render_static = PopupMenuView.render

return PopupMenuView

