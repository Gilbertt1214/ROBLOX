--[[
    PlayerDropdown Component
    Displays a list of players with click to expand for actions
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local TweenService = game:GetService("TweenService")
local Roact = require(ReplicatedStorage.Shared.Roact)
local Theme = require(ReplicatedStorage.Shared.Theme)
local ResponsiveUtil = require(ReplicatedStorage.Shared.ResponsiveUtil)
local ZIndex = require(ReplicatedStorage.Shared.ZIndex)
local Logger = require(ReplicatedStorage.Shared.Logger)
local UISounds = require(ReplicatedStorage.Shared.UISounds)
local PopupMenuView = require(script.Parent.PopupMenuView)

local PlayerDropdown = {}

-- Cache for friend status
local friendCache = {}

-- Cache for player settings (disableTeleport)
local settingsCache = {}

-- Cache for player info (role, streak)
local playerInfoCache = {}

-- Toast notification system (positioned at top)
local function showToast(message, isError)
    local player = Players.LocalPlayer
    if not player then return end
    
    local playerGui = player:FindFirstChild("PlayerGui")
    if not playerGui then return end
    
    -- Remove existing toast
    local existing = playerGui:FindFirstChild("ToastNotification")
    if existing then
        existing:Destroy()
    end
    
    local isPhone = ResponsiveUtil.isPhone()
    local toastWidth = isPhone and 260 or 320
    local toastHeight = isPhone and 40 or 50
    
    -- Create toast GUI
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "ToastNotification"
    screenGui.ResetOnSpawn = false
    screenGui.DisplayOrder = ZIndex.TOAST
    screenGui.IgnoreGuiInset = true
    screenGui.Parent = playerGui
    
    local container = Instance.new("Frame")
    container.Name = "Container"
    container.Size = UDim2.new(0, toastWidth, 0, toastHeight)
    container.Position = UDim2.new(0.5, 0, 0, -toastHeight) -- Start above screen
    container.AnchorPoint = Vector2.new(0.5, 0)
    container.BackgroundColor3 = isError and Color3.fromRGB(220, 60, 60) or Color3.fromRGB(34, 197, 94)
    container.BackgroundTransparency = 0.1
    container.Parent = screenGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, isPhone and 10 or 12)
    corner.Parent = container
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = isError and Color3.fromRGB(255, 100, 100) or Color3.fromRGB(100, 255, 150)
    stroke.Thickness = 1.5
    stroke.Transparency = 0.3
    stroke.Parent = container
    
    -- Icon
    local icon = Instance.new("TextLabel")
    icon.Size = UDim2.new(0, isPhone and 24 or 30, 0, isPhone and 24 or 30)
    icon.Position = UDim2.new(0, isPhone and 10 or 14, 0.5, 0)
    icon.AnchorPoint = Vector2.new(0, 0.5)
    icon.BackgroundTransparency = 1
    icon.Text = isError and "X" or "!"
    icon.TextColor3 = Color3.new(1, 1, 1)
    icon.TextSize = isPhone and 16 or 20
    icon.Font = Enum.Font.GothamBold
    icon.Parent = container
    
    -- Message
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, isPhone and -50 or -60, 1, 0)
    label.Position = UDim2.new(0, isPhone and 40 or 50, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = message
    label.TextColor3 = Color3.new(1, 1, 1)
    label.TextSize = isPhone and 12 or 14
    label.Font = Enum.Font.GothamBold
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextWrapped = true
    label.Parent = container
    
    -- Animate in from top
    local topOffset = isPhone and 50 or 20
    local slideIn = TweenService:Create(container, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Position = UDim2.new(0.5, 0, 0, topOffset)
    })
    slideIn:Play()
    
    -- Auto dismiss after 3 seconds
    task.delay(3, function()
        if screenGui and screenGui.Parent then
            local slideOut = TweenService:Create(container, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
                Position = UDim2.new(0.5, 0, 0, -toastHeight) -- Slide out to top
            })
            slideOut:Play()
            slideOut.Completed:Wait()
            screenGui:Destroy()
        end
    end)
end

-- Check if player is friend
local function isFriend(player)
    if friendCache[player.UserId] ~= nil then
        return friendCache[player.UserId]
    end
    
    local success, result = Logger.safeCall("PlayerDropdown", "isFriend", function()
        return Players.LocalPlayer:IsFriendsWith(player.UserId)
    end)
    
    if success then
        friendCache[player.UserId] = result
        return result
    end
    return false
end

-- Check if player has teleport disabled
local function canTeleportTo(player)
    -- Check cache first
    if settingsCache[player.UserId] ~= nil then
        return not settingsCache[player.UserId].disableTeleport
    end
    
    -- Try to get from server
    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
    if remotes then
        local getSettings = remotes:FindFirstChild("GetPlayerSettings")
        if getSettings then
            local success, settings = Logger.safeCall("PlayerDropdown", "getSettings", function()
                return getSettings:InvokeServer(player.UserId)
            end)
            
            if success and settings then
                settingsCache[player.UserId] = settings
                return not settings.disableTeleport
            end
        end
    end
    
    return true -- Default allow if can't check
end

-- Get player role and streak from overhead or server
local function getPlayerInfo(player)
    -- Check cache first
    if playerInfoCache[player.UserId] then
        local cached = playerInfoCache[player.UserId]
        -- Cache valid for 5 seconds
        if tick() - cached.timestamp < 5 then
            return cached.role, cached.streak
        end
    end
    
    local role = "Player"
    local streak = 0
    
    -- Try to get from server remote
    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
    if remotes then
        local getPlayerInfo = remotes:FindFirstChild("GetPlayerInfo")
        if getPlayerInfo then
            local success, info = Logger.safeCall("PlayerDropdown", "getPlayerInfo", function()
                return getPlayerInfo:InvokeServer(player.UserId)
            end)
            if success and info then
                role = info.role or "Player"
                streak = info.streak or 0
                -- Cache the result
                playerInfoCache[player.UserId] = {
                    role = role,
                    streak = streak,
                    timestamp = tick()
                }
                return role, streak
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
                        role = roleLabel.Text
                    end
                    
                    -- Try to get streak from NameRow
                    local nameRow = container:FindFirstChild("NameRow")
                    if nameRow then
                        local streakNum = nameRow:FindFirstChild("StreakNum")
                        if streakNum and streakNum.Text then
                            streak = tonumber(streakNum.Text) or 0
                        end
                    end
                end
            end
        end
    end
    
    -- Cache the result
    playerInfoCache[player.UserId] = {
        role = role,
        streak = streak,
        timestamp = tick()
    }
    
    return role, streak
end

-- Clear cache for a specific player (call when player list updates)
local function clearPlayerCache(userId)
    playerInfoCache[userId] = nil
    friendCache[userId] = nil
    settingsCache[userId] = nil
end

-- Clear all caches
local function clearAllCaches()
    playerInfoCache = {}
    friendCache = {}
    settingsCache = {}
end

local function createPlayerRow(props)
    local player = props.player
    local isLocal = props.isLocal
    local onToggle = props.onToggle
    local layoutOrder = props.layoutOrder or 0
    local rowHeight = props.rowHeight or 50
    local isPhone = props.isPhone or false
    
    local avatarSize = isPhone and 30 or 38
    
    local children = {
        Corner = Roact.createElement("UICorner", { CornerRadius = UDim.new(0, 8) }),
        
        -- Clickable area
        ClickArea = Roact.createElement("TextButton", {
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            Text = "",
            ZIndex = ZIndex.CONTENT,
            AutoButtonColor = false,

            [Roact.Event.Activated] = function()
                if onToggle then
                    UISounds.click()
                    onToggle(player)
                end
            end
        }),
        
        -- Avatar
        Avatar = Roact.createElement("ImageLabel", {
            Size = UDim2.new(0, avatarSize, 0, avatarSize),
            Position = UDim2.new(0, isPhone and 5 or 8, 0.5, 0),
            AnchorPoint = Vector2.new(0, 0.5),
            BackgroundColor3 = Theme.BackgroundCard,
            Image = "rbxthumb://type=AvatarHeadShot&id=" .. tostring(player.UserId) .. "&w=150&h=150",
            BackgroundTransparency = 0,
            ZIndex = ZIndex.BASE
        }, {
            Corner = Roact.createElement("UICorner", { CornerRadius = UDim.new(1, 0) })
        }),
        
        -- Player Info
        DisplayName = Roact.createElement("TextLabel", {
            Size = UDim2.new(1, isPhone and -50 or -60, 0, 14),
            Position = UDim2.new(0, avatarSize + (isPhone and 10 or 16), 0, isPhone and 6 or 8),
            BackgroundTransparency = 1,
            Text = player.DisplayName .. (isLocal and " (You)" or ""),
            TextColor3 = isLocal and Color3.new(1, 1, 1) or Theme.TextPrimary,
            TextSize = isPhone and 11 or 13,
            Font = Enum.Font.GothamBold,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
            ZIndex = ZIndex.BASE
        }),
        
        Username = Roact.createElement("TextLabel", {
            Size = UDim2.new(1, isPhone and -50 or -60, 0, 10),
            Position = UDim2.new(0, avatarSize + (isPhone and 10 or 16), 0, isPhone and 20 or 24),
            BackgroundTransparency = 1,
            Text = "@" .. player.Name,
            TextColor3 = isLocal and Color3.fromRGB(200, 200, 200) or Theme.TextMuted,
            TextSize = isPhone and 8 or 10,
            Font = Enum.Font.Gotham,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = ZIndex.BASE
        })
    }
    
    return Roact.createElement("Frame", {
        Size = UDim2.new(1, 0, 0, rowHeight),
        BackgroundColor3 = isLocal and Theme.Primary or Theme.BackgroundLight,
        BackgroundTransparency = isLocal and 0.7 or 0.5,
        LayoutOrder = layoutOrder
    }, children)
end

-- Player Popup Menu Component is now handled by PopupMenuView.lua

function PlayerDropdown.create(props)
    local playerList = props.players or {}
    local localPlayer = Players.LocalPlayer
    local selectedPlayer = props.selectedPlayer
    local onSelectPlayer = props.onSelectPlayer
    local onClosePopup = props.onClosePopup
    local onViewProfile = props.onViewProfile -- Callback for viewing profile
    local refreshTrigger = props.refreshTrigger or 0
    
    -- Clear cache when refresh is triggered
    if refreshTrigger > 0 then
        playerInfoCache = {}
    end
    
    local sizes = ResponsiveUtil.getSizes()
    local isPhone = ResponsiveUtil.isPhone()
    local isMobile = ResponsiveUtil.isMobile()
    
    -- Responsive sizes
    local panelWidth = isPhone and 200 or (isMobile and 220 or 240)
    local rowHeight = isPhone and 42 or 50
    
    -- Action handler
    local function handleAction(action, targetPlayer)
        if action == "profile" then
            -- Open ProfileView instead of friend request
            if onViewProfile then
                onViewProfile(targetPlayer)
            end
            if onClosePopup then onClosePopup() end
            
        elseif action == "friend" then
            Logger.safeCall("PlayerDropdown", "sendFriendRequest", function()
                StarterGui:SetCore("PromptSendFriendRequest", targetPlayer)
            end)
            friendCache[targetPlayer.UserId] = nil
            if onClosePopup then onClosePopup() end
            
        elseif action == "carry" then
            -- CarrySystem uses CarryRemote in ReplicatedStorage root
            local carryRemote = ReplicatedStorage:FindFirstChild("CarryRemote")
            if carryRemote then
                carryRemote:FireServer("Request", {targetId = targetPlayer.UserId})
                showToast("Carry request sent to " .. targetPlayer.DisplayName, false)
            else
                showToast("Carry system not available", true)
            end
            if onClosePopup then onClosePopup() end
            
        elseif action == "teleport" then
            if not canTeleportTo(targetPlayer) then
                showToast(targetPlayer.DisplayName .. " has disabled teleport", true)
                return
            end
            
            local character = localPlayer.Character
            local targetCharacter = targetPlayer.Character
            
            if character and targetCharacter then
                local humanoid = character:FindFirstChildOfClass("Humanoid")
                local targetHRP = targetCharacter:FindFirstChild("HumanoidRootPart")
                
                if targetHRP then
                    -- Unsit if needed
                    if humanoid and humanoid.Sit then
                        humanoid.Sit = false
                        task.wait(0.1)
                    end
                    
                    -- Teleport to 3.5 studs in front of them and face them
                    local targetCF = targetHRP.CFrame
                    local destination = targetCF * CFrame.new(0, 0, -3.5) * CFrame.Angles(0, math.pi, 0)
                    character:PivotTo(destination)
                    
                    if onClosePopup then onClosePopup() end
                end
            else
                showToast("Cannot teleport - player not found", true)
                warn("[PlayerDropdown] Cannot teleport - character not found")
            end
        end
    end
    
    local children = {
        Layout = Roact.createElement("UIListLayout", {
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, isPhone and 3 or 4)
        }),
        Padding = Roact.createElement("UIPadding", {
            PaddingTop = UDim.new(0, isPhone and 6 or 8),
            PaddingBottom = UDim.new(0, isPhone and 6 or 8),
            PaddingLeft = UDim.new(0, isPhone and 6 or 8),
            PaddingRight = UDim.new(0, isPhone and 6 or 8)
        }),
        
        -- Header
        Header = Roact.createElement("TextLabel", {
            Size = UDim2.new(1, 0, 0, isPhone and 16 or 20),
            BackgroundTransparency = 1,
            Text = "Players (" .. #playerList .. ")",
            TextColor3 = Theme.TextPrimary,
            TextSize = isPhone and 10 or 12,
            Font = Enum.Font.GothamBold,
            TextXAlignment = Enum.TextXAlignment.Left,
            LayoutOrder = 0
        })
    }
    
    -- Sort: Local player first
    local sortedPlayers = {}
    for _, player in ipairs(playerList) do
        if player == localPlayer then
            table.insert(sortedPlayers, 1, player)
        else
            table.insert(sortedPlayers, player)
        end
    end
    
    for i, player in ipairs(sortedPlayers) do
        local isSelected = (selectedPlayer and selectedPlayer.UserId == player.UserId)
        
        children["Player_" .. player.UserId] = createPlayerRow({
            player = player,
            isLocal = (player == localPlayer),
            onToggle = function(p)
                if onSelectPlayer then 
                    onSelectPlayer(p) 
                end
            end,
            isSelected = isSelected,
            layoutOrder = i,
            rowHeight = rowHeight,
            isPhone = isPhone
        })
    end
    
    -- Calculate height
    local baseHeight = isPhone and 28 or 36
    for _ in ipairs(sortedPlayers) do
        baseHeight = baseHeight + rowHeight + 4
    end
    local listHeight = math.min(baseHeight, isPhone and 280 or 350)
    
    -- Top offset to position below TopRightStatus (which has offset for Roblox buttons)
    local topOffset = isPhone and 100 or (isMobile and 95 or 80)
    
    -- Calculate total width to include popup (must match PopupMenuView sizing)
    local popupWidth = isPhone and 220 or (isMobile and 200 or 160)
    local totalWidth = panelWidth + (selectedPlayer and (popupWidth + 10) or 0)
    
    return Roact.createElement("Frame", {
        Name = "PlayerDropdownRoot",
        Size = UDim2.new(0, totalWidth, 0, listHeight),
        Position = UDim2.new(1, -12, 0, topOffset),
        AnchorPoint = Vector2.new(1, 0),
        BackgroundTransparency = 1, -- Invisible root
        ZIndex = ZIndex.MODAL
    }, {
        -- The actual styled player list
        ListFrame = Roact.createElement("Frame", {
            Name = "ListFrame",
            Size = UDim2.new(0, panelWidth, 1, 0),
            Position = UDim2.new(1, 0, 0, 0),
            AnchorPoint = Vector2.new(1, 0),
            BackgroundColor3 = Theme.Background,
            BackgroundTransparency = 0.05,
            BorderSizePixel = 0,
        }, {
            Corner = Roact.createElement("UICorner", { CornerRadius = UDim.new(0, isPhone and 10 or 12) }),
            Stroke = Roact.createElement("UIStroke", {
                Color = Theme.Primary,
                Thickness = isPhone and 1 or 2,
                Transparency = 0.5
            }),
            Container = Roact.createElement("ScrollingFrame", {
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                ScrollBarThickness = 3,
                ScrollBarImageColor3 = Theme.Primary,
                CanvasSize = UDim2.new(0, 0, 0, 0),
                AutomaticCanvasSize = Enum.AutomaticSize.Y
            }, children),
        }),
        
        -- Player Popup (Now handled by standalone component)
        PlayerPopup = selectedPlayer and Roact.createElement(PopupMenuView, {
            player = selectedPlayer,
            onClose = onClosePopup,
            onAction = handleAction,
            isPhone = isPhone,
            isMobile = isMobile,
            isFriendWithPlayer = isFriend(selectedPlayer)
        }) or nil
    })
end

return PlayerDropdown
