--[[
    AnimatedPanel Component
    Wrapper that adds cool entrance/exit animations to panels
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Roact = require(ReplicatedStorage.Shared.Roact)

local AnimatedPanel = Roact.Component:extend("AnimatedPanel")

-- Animation presets
AnimatedPanel.Animations = {
    SlideUp = "slideUp",
    SlideDown = "slideDown",
    SlideLeft = "slideLeft",
    SlideRight = "slideRight",
    ScaleBounce = "scaleBounce",
    FadeScale = "fadeScale",
    PopIn = "popIn"
}

function AnimatedPanel:init()
    self.panelRef = Roact.createRef()
end

function AnimatedPanel:didMount()
    local panel = self.panelRef:getValue()
    if not panel then return end
    
    local animType = self.props.animation or "popIn"
    local duration = self.props.duration or 0.35
    
    -- Store original values
    local originalSize = panel.Size
    local originalPos = panel.Position
    local originalTransparency = panel.BackgroundTransparency
    
    -- Set initial state based on animation type
    if animType == "slideUp" then
        panel.Position = UDim2.new(
            originalPos.X.Scale, originalPos.X.Offset,
            originalPos.Y.Scale + 0.1, originalPos.Y.Offset + 50
        )
        panel.BackgroundTransparency = 1
        
    elseif animType == "slideDown" then
        panel.Position = UDim2.new(
            originalPos.X.Scale, originalPos.X.Offset,
            originalPos.Y.Scale - 0.1, originalPos.Y.Offset - 50
        )
        panel.BackgroundTransparency = 1
        
    elseif animType == "slideLeft" then
        panel.Position = UDim2.new(
            originalPos.X.Scale + 0.1, originalPos.X.Offset + 50,
            originalPos.Y.Scale, originalPos.Y.Offset
        )
        panel.BackgroundTransparency = 1
        
    elseif animType == "slideRight" then
        panel.Position = UDim2.new(
            originalPos.X.Scale - 0.1, originalPos.X.Offset - 50,
            originalPos.Y.Scale, originalPos.Y.Offset
        )
        panel.BackgroundTransparency = 1
        
    elseif animType == "scaleBounce" then
        panel.Size = UDim2.new(0, 0, 0, 0)
        panel.BackgroundTransparency = 1
        
    elseif animType == "fadeScale" then
        panel.Size = UDim2.new(
            originalSize.X.Scale * 0.8, originalSize.X.Offset * 0.8,
            originalSize.Y.Scale * 0.8, originalSize.Y.Offset * 0.8
        )
        panel.BackgroundTransparency = 1
        
    else -- popIn (default)
        panel.Size = UDim2.new(
            originalSize.X.Scale * 0.5, originalSize.X.Offset * 0.5,
            originalSize.Y.Scale * 0.5, originalSize.Y.Offset * 0.5
        )
        panel.BackgroundTransparency = 1
        panel.Rotation = -5
    end
    
    -- Hide all children initially
    for _, child in pairs(panel:GetDescendants()) do
        if child:IsA("GuiObject") then
            child:SetAttribute("_origBgTrans", child.BackgroundTransparency)
            if child.BackgroundTransparency < 1 then
                child.BackgroundTransparency = 1
            end
        end
        if child:IsA("TextLabel") or child:IsA("TextButton") then
            child:SetAttribute("_origTextTrans", child.TextTransparency)
            child.TextTransparency = 1
        end
        if child:IsA("ImageLabel") or child:IsA("ImageButton") then
            child:SetAttribute("_origImgTrans", child.ImageTransparency)
            child.ImageTransparency = 1
        end
    end
    
    -- Animate panel
    local easingStyle = Enum.EasingStyle.Back
    local easingDir = Enum.EasingDirection.Out
    
    if animType == "slideUp" or animType == "slideDown" or animType == "slideLeft" or animType == "slideRight" then
        easingStyle = Enum.EasingStyle.Quint
    end
    
    local tweenInfo = TweenInfo.new(duration, easingStyle, easingDir)
    
    local targetProps = {
        Size = originalSize,
        Position = originalPos,
        BackgroundTransparency = originalTransparency
    }
    
    if animType == "popIn" then
        targetProps.Rotation = 0
    end
    
    local mainTween = TweenService:Create(panel, tweenInfo, targetProps)
    mainTween:Play()
    
    -- Staggered children animation
    task.delay(duration * 0.3, function()
        local delay = 0
        local childDelay = 0.03
        
        for _, child in pairs(panel:GetDescendants()) do
            task.delay(delay, function()
                if child:IsA("GuiObject") then
                    local origBg = child:GetAttribute("_origBgTrans") or 0
                    if origBg < 1 then
                        TweenService:Create(child, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
                            BackgroundTransparency = origBg
                        }):Play()
                    end
                end
                if child:IsA("TextLabel") or child:IsA("TextButton") then
                    local origText = child:GetAttribute("_origTextTrans") or 0
                    TweenService:Create(child, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
                        TextTransparency = origText
                    }):Play()
                end
                if child:IsA("ImageLabel") or child:IsA("ImageButton") then
                    local origImg = child:GetAttribute("_origImgTrans") or 0
                    TweenService:Create(child, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
                        ImageTransparency = origImg
                    }):Play()
                end
            end)
            delay = delay + childDelay
        end
    end)
end

function AnimatedPanel:render()
    local props = self.props
    local children = props.children or props[Roact.Children] or {}
    
    return Roact.createElement("Frame", {
        Name = props.Name or "AnimatedPanel",
        Size = props.Size or UDim2.new(0, 300, 0, 400),
        Position = props.Position or UDim2.new(0.5, 0, 0.5, 0),
        AnchorPoint = props.AnchorPoint or Vector2.new(0.5, 0.5),
        BackgroundColor3 = props.BackgroundColor3,
        BackgroundTransparency = props.BackgroundTransparency or 0.05,
        ClipsDescendants = props.ClipsDescendants,
        [Roact.Ref] = self.panelRef
    }, children)
end

return AnimatedPanel
