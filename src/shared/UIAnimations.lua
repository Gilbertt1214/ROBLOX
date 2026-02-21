--[[
    UIAnimations Module
    Provides smooth animations for UI elements
]]

local TweenService = game:GetService("TweenService")

local UIAnimations = {}

-- Default tween info presets
UIAnimations.Presets = {
    Fast = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    Normal = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    Smooth = TweenInfo.new(0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
    Bounce = TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
    Spring = TweenInfo.new(0.5, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out),
}

-- Fade in element
function UIAnimations.fadeIn(element, duration)
    duration = duration or 0.25
    element.BackgroundTransparency = 1
    local tween = TweenService:Create(element, TweenInfo.new(duration, Enum.EasingStyle.Quad), {
        BackgroundTransparency = element:GetAttribute("TargetTransparency") or 0.05
    })
    tween:Play()
    return tween
end

-- Scale pop in (from small to normal)
function UIAnimations.popIn(element, duration)
    duration = duration or 0.3
    local originalSize = element.Size
    element.Size = UDim2.new(
        originalSize.X.Scale * 0.8, originalSize.X.Offset * 0.8,
        originalSize.Y.Scale * 0.8, originalSize.Y.Offset * 0.8
    )
    element.BackgroundTransparency = 1
    
    local tween = TweenService:Create(element, TweenInfo.new(duration, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = originalSize,
        BackgroundTransparency = element:GetAttribute("TargetTransparency") or 0.05
    })
    tween:Play()
    return tween
end

-- Slide in from direction
function UIAnimations.slideIn(element, direction, duration)
    duration = duration or 0.3
    direction = direction or "left"
    
    local originalPos = element.Position
    local startPos
    
    if direction == "left" then
        startPos = UDim2.new(originalPos.X.Scale - 0.1, originalPos.X.Offset - 50, originalPos.Y.Scale, originalPos.Y.Offset)
    elseif direction == "right" then
        startPos = UDim2.new(originalPos.X.Scale + 0.1, originalPos.X.Offset + 50, originalPos.Y.Scale, originalPos.Y.Offset)
    elseif direction == "up" then
        startPos = UDim2.new(originalPos.X.Scale, originalPos.X.Offset, originalPos.Y.Scale - 0.1, originalPos.Y.Offset - 50)
    elseif direction == "down" then
        startPos = UDim2.new(originalPos.X.Scale, originalPos.X.Offset, originalPos.Y.Scale + 0.1, originalPos.Y.Offset + 50)
    end
    
    element.Position = startPos
    element.BackgroundTransparency = 1
    
    local tween = TweenService:Create(element, TweenInfo.new(duration, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
        Position = originalPos,
        BackgroundTransparency = element:GetAttribute("TargetTransparency") or 0.05
    })
    tween:Play()
    return tween
end

-- Button hover effect
function UIAnimations.setupButtonHover(button, scaleAmount)
    scaleAmount = scaleAmount or 1.05
    local originalSize = button.Size
    
    button.MouseEnter:Connect(function()
        TweenService:Create(button, UIAnimations.Presets.Fast, {
            Size = UDim2.new(
                originalSize.X.Scale * scaleAmount, originalSize.X.Offset * scaleAmount,
                originalSize.Y.Scale * scaleAmount, originalSize.Y.Offset * scaleAmount
            )
        }):Play()
    end)
    
    button.MouseLeave:Connect(function()
        TweenService:Create(button, UIAnimations.Presets.Fast, {
            Size = originalSize
        }):Play()
    end)
end

-- Button click effect
function UIAnimations.setupButtonClick(button)
    button.MouseButton1Down:Connect(function()
        TweenService:Create(button, UIAnimations.Presets.Fast, {
            Size = UDim2.new(
                button.Size.X.Scale * 0.95, button.Size.X.Offset * 0.95,
                button.Size.Y.Scale * 0.95, button.Size.Y.Offset * 0.95
            )
        }):Play()
    end)
    
    button.MouseButton1Up:Connect(function()
        TweenService:Create(button, UIAnimations.Presets.Fast, {
            Size = button:GetAttribute("OriginalSize") or button.Size
        }):Play()
    end)
end

-- Pulse effect (for notifications, etc)
function UIAnimations.pulse(element, duration)
    duration = duration or 0.5
    local originalSize = element.Size
    
    local expandTween = TweenService:Create(element, TweenInfo.new(duration/2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Size = UDim2.new(
            originalSize.X.Scale * 1.1, originalSize.X.Offset * 1.1,
            originalSize.Y.Scale * 1.1, originalSize.Y.Offset * 1.1
        )
    })
    
    local shrinkTween = TweenService:Create(element, TweenInfo.new(duration/2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
        Size = originalSize
    })
    
    expandTween:Play()
    expandTween.Completed:Connect(function()
        shrinkTween:Play()
    end)
end

-- Shake effect (for errors, etc)
function UIAnimations.shake(element, intensity)
    intensity = intensity or 5
    local originalPos = element.Position
    
    for i = 1, 4 do
        local offset = (i % 2 == 0) and intensity or -intensity
        TweenService:Create(element, TweenInfo.new(0.05), {
            Position = UDim2.new(originalPos.X.Scale, originalPos.X.Offset + offset, originalPos.Y.Scale, originalPos.Y.Offset)
        }):Play()
        task.wait(0.05)
    end
    
    TweenService:Create(element, TweenInfo.new(0.05), {
        Position = originalPos
    }):Play()
end

-- Glow effect
function UIAnimations.glow(stroke, color, duration)
    duration = duration or 0.3
    local originalColor = stroke.Color
    
    TweenService:Create(stroke, TweenInfo.new(duration/2), {
        Color = color,
        Transparency = 0
    }):Play()
    
    task.delay(duration/2, function()
        TweenService:Create(stroke, TweenInfo.new(duration/2), {
            Color = originalColor,
            Transparency = 0.5
        }):Play()
    end)
end

-- Panel entrance animation (call this in didMount or after creating panel)
function UIAnimations.animatePanel(panel, animType, duration)
    if not panel then return end
    
    animType = animType or "popIn"
    duration = duration or 0.35
    
    -- Store original values
    local originalSize = panel.Size
    local originalPos = panel.Position
    local originalTransparency = panel.BackgroundTransparency
    local originalRotation = panel.Rotation
    
    -- Set initial state based on animation type
    if animType == "slideUp" then
        panel.Position = UDim2.new(
            originalPos.X.Scale, originalPos.X.Offset,
            originalPos.Y.Scale + 0.15, originalPos.Y.Offset + 80
        )
        panel.BackgroundTransparency = 1
        
    elseif animType == "slideDown" then
        panel.Position = UDim2.new(
            originalPos.X.Scale, originalPos.X.Offset,
            originalPos.Y.Scale - 0.15, originalPos.Y.Offset - 80
        )
        panel.BackgroundTransparency = 1
        
    elseif animType == "slideLeft" then
        panel.Position = UDim2.new(
            originalPos.X.Scale + 0.15, originalPos.X.Offset + 80,
            originalPos.Y.Scale, originalPos.Y.Offset
        )
        panel.BackgroundTransparency = 1
        
    elseif animType == "slideRight" then
        panel.Position = UDim2.new(
            originalPos.X.Scale - 0.15, originalPos.X.Offset - 80,
            originalPos.Y.Scale, originalPos.Y.Offset
        )
        panel.BackgroundTransparency = 1
        
    elseif animType == "scaleUp" then
        panel.Size = UDim2.new(0, 0, 0, 0)
        panel.BackgroundTransparency = 1
        
    elseif animType == "popIn" then
        panel.Size = UDim2.new(
            originalSize.X.Scale * 0.7, originalSize.X.Offset * 0.7,
            originalSize.Y.Scale * 0.7, originalSize.Y.Offset * 0.7
        )
        panel.BackgroundTransparency = 1
        panel.Rotation = -3
        
    elseif animType == "flipIn" then
        panel.Size = UDim2.new(
            originalSize.X.Scale, originalSize.X.Offset,
            0, 0
        )
        panel.BackgroundTransparency = 1
    end
    
    -- Hide all children initially
    local childrenData = {}
    for _, child in pairs(panel:GetDescendants()) do
        local data = {}
        if child:IsA("GuiObject") then
            data.bgTrans = child.BackgroundTransparency
            if child.BackgroundTransparency < 1 then
                child.BackgroundTransparency = 1
            end
        end
        if child:IsA("TextLabel") or child:IsA("TextButton") then
            data.textTrans = child.TextTransparency
            child.TextTransparency = 1
        end
        if child:IsA("ImageLabel") or child:IsA("ImageButton") then
            data.imgTrans = child.ImageTransparency
            child.ImageTransparency = 1
        end
        if child:IsA("UIStroke") then
            data.strokeTrans = child.Transparency
            child.Transparency = 1
        end
        childrenData[child] = data
    end
    
    -- Animate panel
    local easingStyle = Enum.EasingStyle.Back
    if animType == "slideUp" or animType == "slideDown" or animType == "slideLeft" or animType == "slideRight" then
        easingStyle = Enum.EasingStyle.Quint
    elseif animType == "flipIn" then
        easingStyle = Enum.EasingStyle.Elastic
    end
    
    local tweenInfo = TweenInfo.new(duration, easingStyle, Enum.EasingDirection.Out)
    
    local targetProps = {
        Size = originalSize,
        Position = originalPos,
        BackgroundTransparency = originalTransparency,
        Rotation = originalRotation
    }
    
    local mainTween = TweenService:Create(panel, tweenInfo, targetProps)
    mainTween:Play()
    
    -- Staggered children animation
    task.delay(duration * 0.4, function()
        local delay = 0
        local childDelay = 0.02
        
        for child, data in pairs(childrenData) do
            task.delay(delay, function()
                if not child or not child.Parent then return end
                
                if data.bgTrans and data.bgTrans < 1 then
                    TweenService:Create(child, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
                        BackgroundTransparency = data.bgTrans
                    }):Play()
                end
                if data.textTrans then
                    TweenService:Create(child, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
                        TextTransparency = data.textTrans
                    }):Play()
                end
                if data.imgTrans then
                    TweenService:Create(child, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
                        ImageTransparency = data.imgTrans
                    }):Play()
                end
                if data.strokeTrans then
                    TweenService:Create(child, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
                        Transparency = data.strokeTrans
                    }):Play()
                end
            end)
            delay = delay + childDelay
        end
    end)
    
    return mainTween
end

return UIAnimations
