--[[
    CarryUI Component
    Handles carry prompts, status, and carrier UI
    Clean design with smooth animations
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local React = require(ReplicatedStorage.Shared.Roact)
local Theme = require(ReplicatedStorage.Shared.Theme)
local ResponsiveUtil = require(ReplicatedStorage.Shared.ResponsiveUtil)

local LocalPlayer = Players.LocalPlayer

local CarryUI = {}

-- Animation IDs
local SIT_R15_ID = 136287547541684
local SIT_R6_ID = 132926598742957
local CARRY_R15_ID = 96371711028656
local CARRY_R6_ID = 113647890412753

-- Helpers
local function headshotUrl(userId, size)
    size = size or 150
    return string.format("rbxthumb://type=AvatarHeadShot&id=%d&w=%d&h=%d", userId, size, size)
end

local function getHumanoid()
    local char = LocalPlayer.Character
    return char and char:FindFirstChildOfClass("Humanoid")
end

local function getAnimator(hum)
    return hum and (hum:FindFirstChildOfClass("Animator") or Instance.new("Animator", hum))
end

local function rigIsR15(hum)
    return hum and hum.RigType == Enum.HumanoidRigType.R15
end

-- Animation tracks
local sitTrack, carryTrack

local function playSit()
    local hum = getHumanoid()
    if not hum then return end
    hum.Sit = true
    local useId = rigIsR15(hum) and SIT_R15_ID or SIT_R6_ID
    if useId == 0 then return end
    local animator = getAnimator(hum)
    if sitTrack then sitTrack:Stop(0.15) end
    local anim = Instance.new("Animation")
    anim.AnimationId = "rbxassetid://" .. tostring(useId)
    local ok, track = pcall(function() return animator:LoadAnimation(anim) end)
    if ok and track then
        sitTrack = track
        sitTrack.Priority = Enum.AnimationPriority.Action
        sitTrack.Looped = true
        sitTrack:Play(0.2)
    end
end

local function stopSit()
    local hum = getHumanoid()
    if sitTrack then sitTrack:Stop(0.2); sitTrack = nil end
    if hum then hum.Sit = false end
end

local function playCarry()
    local hum = getHumanoid()
    if not hum then return end
    local useId = rigIsR15(hum) and CARRY_R15_ID or CARRY_R6_ID
    if useId == 0 then return end
    local animator = getAnimator(hum)
    if carryTrack then carryTrack:Stop(0.1) end
    local anim = Instance.new("Animation")
    anim.AnimationId = "rbxassetid://" .. tostring(useId)
    local ok, track = pcall(function() return animator:LoadAnimation(anim) end)
    if ok and track then
        carryTrack = track
        carryTrack.Priority = Enum.AnimationPriority.Action
        carryTrack.Looped = true
        carryTrack:Play(0.2)
    end
end

local function stopCarry()
    if carryTrack then carryTrack:Stop(0.2); carryTrack = nil end
end

-- Simple Button Component
local function SimpleButton(props)
    local isPhone = ResponsiveUtil.isPhone()
    local hovered, setHovered = React.useState(false)
    
    return React.createElement("TextButton", {
        Size = props.size or UDim2.new(0, isPhone and 90 or 110, 0, isPhone and 36 or 42),
        Position = props.position,
        AnchorPoint = props.anchorPoint or Vector2.new(0, 0),
        BackgroundColor3 = props.color or Theme.Primary,
        BackgroundTransparency = hovered and 0.15 or 0,
        Text = props.text or "Button",
        TextColor3 = Color3.new(1, 1, 1),
        TextSize = isPhone and 12 or 14,
        Font = Enum.Font.GothamBold,
        AutoButtonColor = false,
        Visible = props.visible ~= false,
        LayoutOrder = props.layoutOrder,
        Event = {
            MouseButton1Click = props.onClick,
            MouseEnter = function() setHovered(true) end,
            MouseLeave = function() setHovered(false) end
        }
    }, {
        Corner = React.createElement("UICorner", { CornerRadius = UDim.new(0, 10) })
    })
end


-- Main UI Component
local function CarryUIComponent()
    local isPhone = ResponsiveUtil.isPhone()
    
    -- States
    local showPrompt, setShowPrompt = React.useState(false)
    local promptFrom, setPromptFrom = React.useState(nil)
    local isCarried, setIsCarried = React.useState(false)
    local carrierInfo, setCarrierInfo = React.useState(nil)
    local carriedList, setCarriedList = React.useState({})
    local carriedIndex, setCarriedIndex = React.useState(1)
    
    -- Animation states
    local promptAnim, setPromptAnim = React.useState(0)
    local statusAnim, setStatusAnim = React.useState(0)
    local carrierAnim, setCarrierAnim = React.useState(0)
    
    -- Remotes
    local CarryRemote = ReplicatedStorage:WaitForChild("CarryRemote", 10)
    local ThrowRemote = ReplicatedStorage:WaitForChild("ThrowRemote", 10)
    
    -- Animate prompt
    React.useEffect(function()
        if showPrompt then
            setPromptAnim(0)
            task.defer(function() setPromptAnim(1) end)
        end
    end, {showPrompt})
    
    -- Animate status
    React.useEffect(function()
        if isCarried then
            setStatusAnim(0)
            task.defer(function() setStatusAnim(1) end)
        end
    end, {isCarried})
    
    -- Animate carrier
    React.useEffect(function()
        if #carriedList > 0 then
            setCarrierAnim(0)
            task.defer(function() setCarrierAnim(1) end)
        end
    end, {#carriedList > 0})
    
    -- Block jump when carried
    React.useEffect(function()
        local conn = UserInputService.JumpRequest:Connect(function()
            if isCarried then
                local h = getHumanoid()
                if h then h.Jump = false end
            end
        end)
        return function() conn:Disconnect() end
    end, {isCarried})
    
    -- Remote event handling (CarryRemote)
    React.useEffect(function()
        if not CarryRemote then return end
        
        local conn = CarryRemote.OnClientEvent:Connect(function(action, data)
            if action == "Prompt" then
                setPromptFrom({id = data.fromId, name = data.fromName})
                setShowPrompt(true)
                
            elseif action == "Start" then
                if data.youAreCarrier then
                    local newList = {}
                    for _, item in ipairs(carriedList) do
                        table.insert(newList, item)
                    end
                    table.insert(newList, {id = data.targetId, name = data.targetName, mode = "carry"})
                    setCarriedList(newList)
                    setCarriedIndex(#newList)
                    if not isCarried then playCarry() end
                else
                    setIsCarried(true)
                    setCarrierInfo({id = data.carrierId, name = data.carrierName, mode = "carry"})
                    playSit()
                    stopCarry()
                end
                
            elseif action == "End" then
                if data.youAreCarrier then
                    if data.removedId then
                        local newList = {}
                        for _, item in ipairs(carriedList) do
                            if item.id ~= data.removedId then
                                table.insert(newList, item)
                            end
                        end
                        setCarriedList(newList)
                        if #newList == 0 then
                            stopCarry()
                        end
                    end
                else
                    setIsCarried(false)
                    setCarrierInfo(nil)
                    stopSit()
                end
                
            elseif action == "CarrierList" then
                local transformed = {}
                for _, item in ipairs(data.list or {}) do
                    table.insert(transformed, {id = item.id, name = item.name, mode = "carry"})
                end
                setCarriedList(transformed)
                if #transformed > 0 and not isCarried then
                    playCarry()
                else
                    stopCarry()
                end
                
            elseif action == "PromptExpire" or action == "PromptClose" then
                setShowPrompt(false)
                setPromptFrom(nil)
            end
        end)
        
        return function() conn:Disconnect() end
    end, {carriedList, isCarried})
    
    -- Remote event handling (ThrowRemote)
    React.useEffect(function()
        if not ThrowRemote then return end
        
        local conn = ThrowRemote.OnClientEvent:Connect(function(action, data)
            if action == "Holding" then
                local newList = {}
                for _, item in ipairs(carriedList) do
                    table.insert(newList, item)
                end
                table.insert(newList, {id = data.targetId, name = data.targetName, mode = "throw"})
                setCarriedList(newList)
                setCarriedIndex(#newList)
                if not isCarried then playCarry() end
                
            elseif action == "BeingHeld" then
                setIsCarried(true)
                setCarrierInfo({id = data.carrierId, name = data.carrierName, mode = "throw"})
                playSit()
                stopCarry()
                
            elseif action == "Thrown" or action == "Dropped" then
                local newList = {}
                for _, item in ipairs(carriedList) do
                    if item.id ~= data.targetId then
                        table.insert(newList, item)
                    end
                end
                setCarriedList(newList)
                if #newList == 0 then stopCarry() end
                
            elseif action == "WasThrown" or action == "WasDropped" then
                setIsCarried(false)
                setCarrierInfo(nil)
                stopSit()
            end
        end)
        
        return function() conn:Disconnect() end
    end, {carriedList, isCarried})
    
    -- Respawn reset
    React.useEffect(function()
        local conn = LocalPlayer.CharacterAdded:Connect(function()
            if sitTrack then sitTrack:Stop(0.1); sitTrack = nil end
            if carryTrack then carryTrack:Stop(0.1); carryTrack = nil end
            setIsCarried(false)
            setCarrierInfo(nil)
            setCarriedList({})
            setCarriedIndex(1)
            setShowPrompt(false)
            setPromptFrom(nil)
        end)
        return function() conn:Disconnect() end
    end, {})
    
    -- Handlers
    local function handleAccept()
        if not promptFrom or not CarryRemote then return end
        CarryRemote:FireServer("Response", {requesterId = promptFrom.id, accept = true})
        setShowPrompt(false)
        setPromptFrom(nil)
    end
    
    local function handleDecline()
        if CarryRemote and promptFrom then
            CarryRemote:FireServer("Response", {requesterId = promptFrom.id, accept = false})
        end
        setShowPrompt(false)
        setPromptFrom(nil)
    end
    
    local function handleGetDown()
        if isCarried and carrierInfo then
            if carrierInfo.mode == "throw" then
                ThrowRemote:FireServer("Drop") -- Use ThrowRemote for throw system
            else
                CarryRemote:FireServer("Stop")
            end
        end
    end
    
    local function handleAction()
        if #carriedList == 0 then return end
        local item = carriedList[1]
        if not item then return end
        
        if item.mode == "throw" then
            ThrowRemote:FireServer("Throw")
        else
            CarryRemote:FireServer("Stop", {targetId = item.id})
        end
    end
    
    local function handlePrevCarried()
        if #carriedList == 0 then return end
        local newIdx = carriedIndex - 1
        if newIdx < 1 then newIdx = #carriedList end
        setCarriedIndex(newIdx)
    end
    
    local function handleNextCarried()
        if #carriedList == 0 then return end
        local newIdx = carriedIndex + 1
        if newIdx > #carriedList then newIdx = 1 end
        setCarriedIndex(newIdx)
    end
    
    -- Sizes
    local promptWidth = isPhone and 280 or 320
    local promptHeight = isPhone and 130 or 150
    local statusHeight = isPhone and 46 or 52
    local carrierHeight = isPhone and 52 or 60
    
    -- Bottom offset to avoid hotbar collision
    local sizes = ResponsiveUtil.getSizes()
    local hotbarOffset = sizes.hotbarSlotSize + sizes.margin * 2 + 20
    
    -- Current carried item
    local currentCarried = carriedList[1]
    local isThrowMode = currentCarried and currentCarried.mode == "throw"

    
    return React.createElement("ScreenGui", {
        Name = "CarryUI",
        ResetOnSpawn = false,
        DisplayOrder = 110,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    }, {
        -- Carry Request Prompt (positioned at top center, below any top UI)
        PromptFrame = showPrompt and React.createElement("Frame", {
            Size = UDim2.new(0, promptWidth, 0, promptHeight),
            Position = UDim2.new(0.5, 0, 0, isPhone and 80 + (1 - promptAnim) * 30 or 100 + (1 - promptAnim) * 30),
            AnchorPoint = Vector2.new(0.5, 0),
            BackgroundColor3 = Theme.Background,
            BackgroundTransparency = 0.05 + (1 - promptAnim) * 0.95
        }, {
            Corner = React.createElement("UICorner", { CornerRadius = UDim.new(0, 14) }),
            Stroke = React.createElement("UIStroke", { 
                Color = Theme.Primary, 
                Thickness = 2, 
                Transparency = 0.4 + (1 - promptAnim) * 0.6 
            }),
            
            Avatar = React.createElement("ImageLabel", {
                Size = UDim2.new(0, isPhone and 60 or 70, 0, isPhone and 60 or 70),
                Position = UDim2.new(0, 16, 0.5, 0),
                AnchorPoint = Vector2.new(0, 0.5),
                BackgroundColor3 = Theme.BackgroundCard,
                Image = promptFrom and headshotUrl(promptFrom.id) or "",
                ImageTransparency = 1 - promptAnim
            }, {
                Corner = React.createElement("UICorner", { CornerRadius = UDim.new(1, 0) })
            }),
            
            ContentContainer = React.createElement("Frame", {
                Size = UDim2.new(1, isPhone and -90 or -105, 1, -24),
                Position = UDim2.new(0, isPhone and 86 or 100, 0.5, 0),
                AnchorPoint = Vector2.new(0, 0.5),
                BackgroundTransparency = 1
            }, {
                Layout = React.createElement("UIListLayout", {
                    FillDirection = Enum.FillDirection.Vertical,
                    VerticalAlignment = Enum.VerticalAlignment.Center,
                    Padding = UDim.new(0, 10)
                }),
                
                Message = React.createElement("TextLabel", {
                    Size = UDim2.new(1, 0, 0, 40),
                    BackgroundTransparency = 1,
                    Text = (promptFrom and promptFrom.name or "Someone") .. " wants to carry you",
                    TextColor3 = Theme.TextPrimary,
                    TextTransparency = 1 - promptAnim,
                    TextSize = isPhone and 14 or 16,
                    Font = Enum.Font.GothamBold,
                    TextWrapped = true,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    LayoutOrder = 1
                }),
                
                ButtonsContainer = React.createElement("Frame", {
                    Size = UDim2.new(1, 0, 0, isPhone and 36 or 42),
                    BackgroundTransparency = 1,
                    LayoutOrder = 2
                }, {
                    Layout = React.createElement("UIListLayout", {
                        FillDirection = Enum.FillDirection.Horizontal,
                        Padding = UDim.new(0, 10)
                    }),
                    AcceptBtn = React.createElement(SimpleButton, {
                        text = "Accept",
                        color = Theme.Success,
                        size = UDim2.new(0, isPhone and 85 or 100, 0, isPhone and 36 or 42),
                        layoutOrder = 1,
                        onClick = handleAccept
                    }),
                    DeclineBtn = React.createElement(SimpleButton, {
                        text = "Decline",
                        color = Theme.Error,
                        size = UDim2.new(0, isPhone and 85 or 100, 0, isPhone and 36 or 42),
                        layoutOrder = 2,
                        onClick = handleDecline
                    })
                })
            })
        }) or nil,
        
        -- Being Carried Status (positioned at bottom right)
        StatusFrame = (isCarried and carrierInfo and carrierInfo.mode ~= "throw") and React.createElement("Frame", {
            Size = UDim2.new(0, isPhone and 120 or 140, 0, isPhone and 38 or 44),
            Position = UDim2.new(1, -12, 1, -(hotbarOffset + (isPhone and 10 or 20))),
            AnchorPoint = Vector2.new(1, 1),
            BackgroundColor3 = Theme.Background,
            BackgroundTransparency = 0.05 + (1 - statusAnim) * 0.95
        }, {
            Corner = React.createElement("UICorner", { CornerRadius = UDim.new(0, 10) }),
            Stroke = React.createElement("UIStroke", { 
                Color = Theme.Primary, 
                Thickness = 1.5, 
                Transparency = 0.4 + (1 - statusAnim) * 0.6 
            }),
            
            GetDownBtn = React.createElement(SimpleButton, {
                text = "Get Down",
                color = Theme.Warning,
                size = UDim2.new(1, -16, 1, -12),
                position = UDim2.new(0.5, 0, 0.5, 0),
                anchorPoint = Vector2.new(0.5, 0.5),
                onClick = handleGetDown
            })
        }) or nil,
        
        -- Carrier Frame (positioned at bottom right)
        CarrierFrame = (#carriedList > 0 and not isCarried) and React.createElement("Frame", {
            Size = UDim2.new(0, isPhone and 100 or 120, 0, isPhone and 38 or 44),
            Position = UDim2.new(1, -12, 1, -(hotbarOffset + (isPhone and 10 or 20))),
            AnchorPoint = Vector2.new(1, 1),
            BackgroundColor3 = Theme.Background,
            BackgroundTransparency = 0.05 + (1 - carrierAnim) * 0.95
        }, {
            Corner = React.createElement("UICorner", { CornerRadius = UDim.new(0, 10) }),
            Stroke = React.createElement("UIStroke", { 
                Color = isThrowMode and Theme.Primary or Theme.Warning, 
                Thickness = 1.5, 
                Transparency = 0.4 + (1 - carrierAnim) * 0.6 
            }),
            
            ActionBtn = React.createElement(SimpleButton, {
                text = isThrowMode and "Throw" or "Drop",
                color = isThrowMode and Theme.Primary or Theme.Error,
                size = UDim2.new(1, -16, 1, -12),
                position = UDim2.new(0.5, 0, 0.5, 0),
                anchorPoint = Vector2.new(0.5, 0.5),
                onClick = handleAction
            })
        }) or nil
    })
end

function CarryUI.create()
    local playerGui = LocalPlayer:WaitForChild("PlayerGui")
    local element = React.createElement(CarryUIComponent)
    return React.mount(element, playerGui, "CarryUI")
end

return CarryUI
