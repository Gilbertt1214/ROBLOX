--[[
    PlayerInteractMenu Component
    Shows interaction menu when clicking on another player's avatar
    Clean design with smooth animations
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local React = require(ReplicatedStorage.Shared.Roact)
local Theme = require(ReplicatedStorage.Shared.Theme)
local ResponsiveUtil = require(ReplicatedStorage.Shared.ResponsiveUtil)
local ZIndex = require(ReplicatedStorage.Shared.ZIndex)

local LocalPlayer = Players.LocalPlayer

local PlayerInteractMenu = {}

local MAX_CLICK_DISTANCE = 20

-- Helper functions (outside component)
local function getHRP()
    local char = LocalPlayer.Character
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function targetIsCarried(pTarget)
    local char = pTarget.Character
    if not char then return false end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    return hrp and hrp:FindFirstChild("CarryWeld") ~= nil
end

local function isBeingCarried()
    local char = LocalPlayer.Character
    if not char then return false end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    return hrp and hrp:FindFirstChild("CarryWeld") ~= nil
end

local function pickPlayerAt(px, py)
    local camera = workspace.CurrentCamera
    if not camera then return nil end
    
    -- Use ViewportPointToRay as it is more consistent with GetMouseLocation
    local ray = camera:ViewportPointToRay(px, py)
    
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {LocalPlayer.Character} -- Exclude self
    
    local rc = workspace:Raycast(ray.Origin, ray.Direction * 1000, params)
    if not rc or not rc.Instance then return nil end
    
    local hitInstance = rc.Instance
    local model = hitInstance:FindFirstAncestorOfClass("Model")
    if not model then
        -- Manual parent check
        local current = hitInstance.Parent
        while current and current ~= workspace do
            if current:IsA("Model") and current:FindFirstChildOfClass("Humanoid") then
                model = current
                break
            end
            current = current.Parent
        end
    end
    
    if not model then return nil end
    local pTarget = Players:GetPlayerFromCharacter(model)
    if not pTarget or pTarget == LocalPlayer then return nil end
    if targetIsCarried(pTarget) then return nil end
    
    local myHRP = getHRP()
    local tHRP = pTarget.Character and pTarget.Character:FindFirstChild("HumanoidRootPart")
    if not (myHRP and tHRP) then return nil end
    
    local dist = (myHRP.Position - tHRP.Position).Magnitude
    if dist > MAX_CLICK_DISTANCE then return nil end
    
    return pTarget
end

-- Action Button Component (list style)
local function ActionButton(props)
    local isPhone = ResponsiveUtil.isPhone()
    local hovered, setHovered = React.useState(false)
    
    return React.createElement("TextButton", {
        Size = UDim2.new(1, 0, 0, isPhone and 40 or 46),
        BackgroundColor3 = hovered and (props.color or Theme.Primary) or Theme.BackgroundLight,
        BackgroundTransparency = hovered and 0.1 or 0.4,
        Text = props.text or "Action",
        TextColor3 = Theme.TextPrimary,
        TextSize = isPhone and 13 or 15,
        Font = Enum.Font.GothamMedium,
        AutoButtonColor = false,
        Active = true,
        LayoutOrder = props.layoutOrder,
        [React.Event.Activated] = props.onClick,
        Event = {
            MouseEnter = function() setHovered(true) end,
            MouseLeave = function() setHovered(false) end
        }
    }, {
        Corner = React.createElement("UICorner", { CornerRadius = UDim.new(0, 10) }),
        Stroke = React.createElement("UIStroke", {
            Color = props.color or Theme.Primary,
            Thickness = 1,
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
            Transparency = 0.7
        })
    })
end

-- Main UI Component
local function InteractMenuUI()
    local visible, setVisible = React.useState(false)
    local targetPlayer, setTargetPlayer = React.useState(nil)
    local menuPosition, setMenuPosition = React.useState(UDim2.new(0.5, 0, 0.5, 0))
    local animScale, setAnimScale = React.useState(1)
    local animTransparency, setAnimTransparency = React.useState(0)
    local isSyncedWithTarget, setIsSyncedWithTarget = React.useState(false)
    
    local isPhone = ResponsiveUtil.isPhone()
    
    -- Cleaner sizing
    local menuWidth = isPhone and 200 or 240
    local headerHeight = isPhone and 130 or 150
    local buttonHeight = isPhone and 38 or 44
    local buttonSpacing = 6
    local padding = 12
    
    -- Actions list
    local currentLeaderId = _G._SyncLeaderId
    
    local actions = {}
    table.insert(actions, { text = "Carry", key = "carry" })
    
    if not currentLeaderId then
        table.insert(actions, { text = "Sync Dance", key = "syncDance", color = Theme.Primary })
    end
    
    table.insert(actions, { text = "Throw", key = "throw" })
    table.insert(actions, { text = "View Profile", key = "profile" })
    
    -- Calculate scroll area height
    local totalButtonsHeight = #actions * buttonHeight + (#actions - 1) * buttonSpacing
    local scrollAreaHeight = math.min(totalButtonsHeight, 4 * buttonHeight + 3 * buttonSpacing)
    local menuHeight = headerHeight + scrollAreaHeight + padding * 2 + 10
    
    -- Animate in/out
    React.useEffect(function()
        if visible then
            setAnimScale(0.9)
            setAnimTransparency(0.3)
            task.delay(0.02, function()
                setAnimScale(1)
                setAnimTransparency(0)
            end)
        end
    end, {visible})
    
    -- Input Handling
    React.useEffect(function()
        local isMenuOpen = false
        _G._InteractMenuState = function(v) isMenuOpen = v end
        
        local function handleClick(px, py)
            if isMenuOpen then return end
            if isBeingCarried() then return end
            
            local pTarget = pickPlayerAt(px, py)
            if pTarget then
                local camera = workspace.CurrentCamera
                local tHRP = pTarget.Character and pTarget.Character:FindFirstChild("HumanoidRootPart")
                if tHRP and camera then
                    -- WorldToViewportPoint because ScreenGui is now IgnoreGuiInset = true
                    local screenPos = camera:WorldToViewportPoint(tHRP.Position)
                    setMenuPosition(UDim2.new(0, screenPos.X, 0, screenPos.Y))
                end
                setTargetPlayer(pTarget)
                setVisible(true)
            end
        end
        
        -- Mouse Input
        local conn1 = UserInputService.InputBegan:Connect(function(input, gameProcessed)
            if gameProcessed then return end
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                local pos = UserInputService:GetMouseLocation()
                handleClick(pos.X, pos.Y)
            end
        end)
        
        -- Touch Input (Standard Tap)
        local touchStart = {}
        local conn2 = UserInputService.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.Touch then
                touchStart[input] = {pos = input.Position, time = tick()}
            end
        end)
        
        local conn3 = UserInputService.InputEnded:Connect(function(input)
            local start = touchStart[input]
            if not start then return end
            touchStart[input] = nil
            
            local duration = tick() - start.time
            local dist = (Vector2.new(input.Position.X, input.Position.Y) - Vector2.new(start.pos.X, start.pos.Y)).Magnitude
            
            if duration < 0.5 and dist < 20 then
                handleClick(input.Position.X, input.Position.Y)
            end
        end)
        
        return function()
            conn1:Disconnect()
            conn2:Disconnect()
            conn3:Disconnect()
            _G._InteractMenuState = nil
        end
    end, {})
    
    React.useEffect(function()
        if _G._InteractMenuState then
            _G._InteractMenuState(visible)
        end
    end, {visible})
    
    React.useEffect(function()
        local conn = UserInputService.InputBegan:Connect(function(input, processed)
            if processed then return end
            if input.KeyCode == Enum.KeyCode.Escape and visible then
                setVisible(false)
                setTargetPlayer(nil)
            end
        end)
        return function() conn:Disconnect() end
    end, {visible})
    
    -- Handlers
    local function handleClose()
        setAnimScale(0.9)
        setAnimTransparency(0.3)
        task.delay(0.08, function()
            setVisible(false)
            setTargetPlayer(nil)
        end)
    end
    
    local function handleAction(key)
        if not targetPlayer then return end
        
        if key == "carry" then
            local CarryRemote = ReplicatedStorage:FindFirstChild("CarryRemote")
            if CarryRemote then
                CarryRemote:FireServer("Request", {targetId = targetPlayer.UserId})
            end
        elseif key == "syncDance" then
            local SyncDanceRemote = ReplicatedStorage:FindFirstChild("SyncDanceRemote")
            if SyncDanceRemote then
                SyncDanceRemote:FireServer("Request", {targetId = targetPlayer.UserId})
            end
        elseif key == "throw" then
            local ThrowRemote = ReplicatedStorage:FindFirstChild("ThrowRemote")
            if ThrowRemote then
                ThrowRemote:FireServer("Pickup", {targetId = targetPlayer.UserId})
            end
        elseif key == "profile" then
            local remotes = ReplicatedStorage:FindFirstChild("Remotes")
            if remotes then
                local openProfile = remotes:FindFirstChild("OpenProfileView")
                if openProfile then openProfile:Fire(targetPlayer) end
            end
        end
        handleClose()
    end
    
    -- Avatar URL
    local avatarUrl = targetPlayer and string.format("rbxthumb://type=AvatarHeadShot&id=%d&w=150&h=150", targetPlayer.UserId) or ""
    
    -- Safe position calculation
    local viewportSize = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1920, 1080)
    local sizes = ResponsiveUtil.getSizes()
    local sidebarWidth = sizes.sidebarWidth + sizes.margin * 2
    local hotbarHeight = sizes.hotbarSlotSize + sizes.margin * 2 + 20
    
    -- Calculate clamp bounds with safety check (max must be >= min)
    local minX = sidebarWidth + menuWidth/2 + 10
    local maxX = math.max(minX, viewportSize.X - menuWidth/2 - 10)
    local minY = menuHeight/2 + 10
    local maxY = math.max(minY, viewportSize.Y - hotbarHeight - menuHeight/2 - 10)
    
    local posX = math.clamp(menuPosition.X.Offset, minX, maxX)
    local posY = math.clamp(menuPosition.Y.Offset, minY, maxY)
    local safePosition = UDim2.new(0, posX, 0, posY)
    
    -- Build action buttons
    local actionButtons = {}
    for i, action in ipairs(actions) do
        actionButtons[action.key] = React.createElement(ActionButton, {
            text = action.text,
            layoutOrder = i,
            color = action.color,
            onClick = function() handleAction(action.key) end
        })
    end
    
    local renderedButtons = {}
    for _, action in ipairs(actions) do
        renderedButtons[action.key] = actionButtons[action.key]
    end
    
    return React.createElement("ScreenGui", {
        Name = "PlayerInteractMenu",
        ResetOnSpawn = false,
        DisplayOrder = 100,
        IgnoreGuiInset = true, -- Align with mouse/touch coordinates
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    }, {
        Menu = visible and React.createElement("Frame", {
            Size = UDim2.new(0, menuWidth * animScale, 0, menuHeight * animScale),
            Position = safePosition,
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundColor3 = Theme.Background,
            BackgroundTransparency = 0.02 + animTransparency,
            ZIndex = ZIndex.POPUP,
            Active = true -- Block input to world
        }, {
            Corner = React.createElement("UICorner", { CornerRadius = UDim.new(0, 14) }),
            Stroke = React.createElement("UIStroke", { 
                Color = Theme.BackgroundLight, 
                Thickness = 1.5, 
                Transparency = animTransparency 
            }),
            
            -- Close button
            CloseBtn = React.createElement("TextButton", {
                Size = UDim2.new(0, 24, 0, 24),
                Position = UDim2.new(1, -10, 0, 10),
                AnchorPoint = Vector2.new(1, 0),
                BackgroundTransparency = 1,
                Text = "X",
                TextColor3 = Theme.TextMuted,
                TextSize = 16,
                Font = Enum.Font.GothamBold,
                ZIndex = ZIndex.POPUP_CONTENT,
                Active = true,
                [React.Event.Activated] = handleClose
            }),
            
            -- Header Section
            Header = React.createElement("Frame", {
                Size = UDim2.new(1, 0, 0, headerHeight),
                BackgroundTransparency = 1
            }, {
                -- Avatar
                AvatarFrame = React.createElement("Frame", {
                    Size = UDim2.new(0, isPhone and 64 or 72, 0, isPhone and 64 or 72),
                    Position = UDim2.new(0.5, 0, 0, isPhone and 16 or 20),
                    AnchorPoint = Vector2.new(0.5, 0),
                    BackgroundColor3 = Theme.BackgroundCard
                }, {
                    Corner = React.createElement("UICorner", { CornerRadius = UDim.new(0.5, 0) }),
                    Stroke = React.createElement("UIStroke", { Color = Theme.Primary, Thickness = 2, Transparency = 0.5 }),
                    Avatar = React.createElement("ImageLabel", {
                        Size = UDim2.new(1, -4, 1, -4),
                        Position = UDim2.new(0.5, 0, 0.5, 0),
                        AnchorPoint = Vector2.new(0.5, 0.5),
                        BackgroundTransparency = 1,
                        Image = avatarUrl,
                        ScaleType = Enum.ScaleType.Fit
                    }, {
                        Corner = React.createElement("UICorner", { CornerRadius = UDim.new(0.5, 0) })
                    })
                }),
                
                -- Display Name
                DisplayName = React.createElement("TextLabel", {
                    Size = UDim2.new(1, -20, 0, 20),
                    Position = UDim2.new(0.5, 0, 0, isPhone and 86 or 98),
                    AnchorPoint = Vector2.new(0.5, 0),
                    BackgroundTransparency = 1,
                    Text = targetPlayer and targetPlayer.DisplayName or "Player",
                    TextColor3 = Theme.TextPrimary,
                    TextSize = isPhone and 14 or 16,
                    Font = Enum.Font.GothamBold,
                    TextTruncate = Enum.TextTruncate.AtEnd
                }),
                
                -- Username
                Username = React.createElement("TextLabel", {
                    Size = UDim2.new(1, -20, 0, 14),
                    Position = UDim2.new(0.5, 0, 0, isPhone and 104 or 118),
                    AnchorPoint = Vector2.new(0.5, 0),
                    BackgroundTransparency = 1,
                    Text = targetPlayer and ("@" .. targetPlayer.Name) or "@username",
                    TextColor3 = Theme.TextMuted,
                    TextSize = isPhone and 10 or 12,
                    Font = Enum.Font.Gotham
                })
            }),
            
            -- Divider
            Divider = React.createElement("Frame", {
                Size = UDim2.new(1, -24, 0, 1),
                Position = UDim2.new(0.5, 0, 0, headerHeight),
                AnchorPoint = Vector2.new(0.5, 0),
                BackgroundColor3 = Theme.BackgroundLight,
                BackgroundTransparency = 0.5,
                BorderSizePixel = 0
            }),
            
            -- Scrollable Actions
            ActionsScroll = React.createElement("ScrollingFrame", {
                Size = UDim2.new(1, -padding * 2, 0, scrollAreaHeight),
                Position = UDim2.new(0.5, 0, 0, headerHeight + 8),
                AnchorPoint = Vector2.new(0.5, 0),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                ScrollBarThickness = 3,
                ScrollBarImageColor3 = Theme.TextMuted,
                ScrollBarImageTransparency = 0.5,
                CanvasSize = UDim2.new(0, 0, 0, 0),
                ScrollingDirection = Enum.ScrollingDirection.Y,
                AutomaticCanvasSize = Enum.AutomaticSize.Y
            }, (function()
                local children = {
                    UIListLayout = React.createElement("UIListLayout", {
                        FillDirection = Enum.FillDirection.Vertical,
                        HorizontalAlignment = Enum.HorizontalAlignment.Center,
                        Padding = UDim.new(0, buttonSpacing),
                        SortOrder = Enum.SortOrder.LayoutOrder
                    })
                }
                
                -- Merge buttons into children
                for key, element in pairs(renderedButtons) do
                    children[key] = element
                end
                
                return children
            end)())
        }) or nil
    })
end

function PlayerInteractMenu.create()
    local playerGui = LocalPlayer:WaitForChild("PlayerGui")
    local element = React.createElement(InteractMenuUI)
    return React.mount(element, playerGui, "PlayerInteractMenu")
end

return PlayerInteractMenu
