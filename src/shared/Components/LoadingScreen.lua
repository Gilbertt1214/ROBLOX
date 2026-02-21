--[[
    LoadingScreen Component
    Cinematic loading with Start Game button
    Background music with fade out effect
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local ContentProvider = game:GetService("ContentProvider")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")

local React = require(ReplicatedStorage.Shared.Roact)
local Theme = require(ReplicatedStorage.Shared.Theme)
local ResponsiveUtil = require(ReplicatedStorage.Shared.ResponsiveUtil)
local Logger = require(ReplicatedStorage.Shared.Logger)
local ZIndex = require(ReplicatedStorage.Shared.ZIndex)

local LocalPlayer = Players.LocalPlayer

-- Sound IDs (replace with your own)
local LOADING_BGM_ID = "rbxassetid://80741397362411" -- Background music saat loading
local START_CLICK_SOUND_ID = "rbxassetid://73542301141709" -- Sound saat klik Start

-- Global state for UI visibility
local LoadingState = {
    isLoading = true
}

-- Background Music Controller
local BGMController = {}
BGMController.sound = nil

function BGMController.create()
    if BGMController.sound then return BGMController.sound end
    
    local sound = Instance.new("Sound")
    sound.Name = "LoadingBGM"
    sound.SoundId = LOADING_BGM_ID
    sound.Volume = 0.5
    sound.Looped = true
    sound.Parent = SoundService
    BGMController.sound = sound
    return sound
end

function BGMController.play()
    local sound = BGMController.create()
    if sound and not sound.IsPlaying then
        sound:Play()
    end
end

function BGMController.fadeOut(duration, callback)
    local sound = BGMController.sound
    if not sound then
        if callback then callback() end
        return
    end
    
    duration = duration or 2
    local startVolume = sound.Volume
    local startTime = tick()
    
    local conn
    conn = RunService.RenderStepped:Connect(function()
        local elapsed = tick() - startTime
        local alpha = math.clamp(elapsed / duration, 0, 1)
        
        sound.Volume = startVolume * (1 - alpha)
        
        if alpha >= 1 then
            conn:Disconnect()
            sound:Stop()
            sound:Destroy()
            BGMController.sound = nil
            if callback then callback() end
        end
    end)
end

function BGMController.stop()
    if BGMController.sound then
        BGMController.sound:Stop()
        BGMController.sound:Destroy()
        BGMController.sound = nil
    end
end

-- Click Sound
local function playStartSound()
    local sound = Instance.new("Sound")
    sound.Name = "StartClickSound"
    sound.SoundId = START_CLICK_SOUND_ID
    sound.Volume = 0.8
    sound.Parent = SoundService
    sound:Play()
    sound.Ended:Connect(function()
        sound:Destroy()
    end)
end

-- Blur effect management
local function setLoadingBlur(enabled)
    task.spawn(function()
        local blurName = "LoadingBlur"
        local existingBlur = Lighting:FindFirstChild(blurName)
        
        if enabled then
            if not existingBlur then
                local blur = Instance.new("BlurEffect")
                blur.Name = blurName
                blur.Size = 0
                blur.Parent = Lighting
                existingBlur = blur
            end
            -- Animate blur in
            TweenService:Create(existingBlur, TweenInfo.new(0.5), { Size = 8 }):Play()
        else
            if existingBlur then
                -- Animate blur out then destroy
                local tween = TweenService:Create(existingBlur, TweenInfo.new(0.3), { Size = 0 })
                tween:Play()
                tween.Completed:Connect(function()
                    if existingBlur and existingBlur.Parent then
                        existingBlur:Destroy()
                    end
                end)
            end
        end
    end)
end

-- Camera Controller
local CameraController = {}
CameraController.connection = nil
CameraController.active = false

function CameraController.startCinematic()
    local camera = Workspace.CurrentCamera
    if not camera then return end
    
    camera.CameraType = Enum.CameraType.Scriptable
    CameraController.active = true
    
    -- Center point at map center (0, 0) with height
    -- This is the middle area with the big tree and building
    local centerPoint = Vector3.new(0, 40, 0)
    
    local radius = 100
    local baseHeight = 100
    
    -- Set initial camera position immediately at center looking at center
    local initialPos = centerPoint + Vector3.new(radius, baseHeight - centerPoint.Y, 0)
    camera.CFrame = CFrame.new(initialPos, centerPoint)
    
    local startTime = tick()
    
    CameraController.connection = RunService.RenderStepped:Connect(function()
        if not CameraController.active then return end
        
        local camera = Workspace.CurrentCamera
        if not camera then return end
        
        if camera.CameraType ~= Enum.CameraType.Scriptable then
            camera.CameraType = Enum.CameraType.Scriptable
        end
        
        local elapsed = tick() - startTime
        local angle = elapsed * 0.05  -- Slow rotation
        
        local x = math.cos(angle) * radius
        local z = math.sin(angle) * radius
        local y = baseHeight + math.sin(elapsed * 0.12) * 10
        
        local camPos = Vector3.new(centerPoint.X + x, y, centerPoint.Z + z)
        camera.CFrame = CFrame.new(camPos, centerPoint)
    end)
end

function CameraController.stopCinematic()
    CameraController.active = false
    if CameraController.connection then
        CameraController.connection:Disconnect()
        CameraController.connection = nil
    end
end

function CameraController.cinematicToCharacter(callback)
    CameraController.stopCinematic()
    
    local camera = Workspace.CurrentCamera
    if not camera then
        if callback then callback() end
        return
    end
    
    local character = LocalPlayer.Character
    if not character then
        character = LocalPlayer.CharacterAdded:Wait()
    end
    
    local hrp = character:WaitForChild("HumanoidRootPart", 5)
    local head = character:WaitForChild("Head", 5)
    
    if not hrp then
        camera.CameraType = Enum.CameraType.Custom
        if callback then callback() end
        return
    end
    
    -- Smooth cinematic to character - slower and more dramatic
    local startCFrame = camera.CFrame
    
    -- Phase 1: Wide shot from above
    local abovePos = hrp.Position + Vector3.new(0, 35, 25)
    local aboveCFrame = CFrame.new(abovePos, hrp.Position)
    
    -- Phase 2: Sweep around to side
    local sidePos = hrp.Position + Vector3.new(15, 6, 15)
    local sideCFrame = CFrame.new(sidePos, hrp.Position + Vector3.new(0, 2, 0))
    
    -- Phase 3: Final position behind character
    local behindPos = hrp.Position + hrp.CFrame.LookVector * -10 + Vector3.new(0, 4, 0)
    local behindCFrame = CFrame.new(behindPos, hrp.Position + Vector3.new(0, 2, 0))
    
    -- Slower duration for smoother transition
    local totalDuration = 4.0
    local startTime = tick()
    
    local zoomConnection
    zoomConnection = RunService.RenderStepped:Connect(function()
        local elapsed = tick() - startTime
        local alpha = math.clamp(elapsed / totalDuration, 0, 1)
        
        -- Very smooth easing (ease in-out)
        local eased = alpha < 0.5 
            and 2 * alpha * alpha 
            or 1 - math.pow(-2 * alpha + 2, 2) / 2
        
        local targetCFrame
        if alpha < 0.35 then
            -- Phase 1: Move to above (slower)
            local phaseAlpha = alpha / 0.35
            local phaseEased = 1 - math.pow(1 - phaseAlpha, 3)
            targetCFrame = startCFrame:Lerp(aboveCFrame, phaseEased)
        elseif alpha < 0.65 then
            -- Phase 2: Sweep to side (slower)
            local phaseAlpha = (alpha - 0.35) / 0.3
            local phaseEased = 1 - math.pow(1 - phaseAlpha, 3)
            targetCFrame = aboveCFrame:Lerp(sideCFrame, phaseEased)
        else
            -- Phase 3: Move behind (slower)
            local phaseAlpha = (alpha - 0.65) / 0.35
            local phaseEased = 1 - math.pow(1 - phaseAlpha, 3)
            targetCFrame = sideCFrame:Lerp(behindCFrame, phaseEased)
        end
        
        camera.CFrame = targetCFrame
        
        if alpha >= 1 then
            zoomConnection:Disconnect()
            task.wait(0.3)
            camera.CameraType = Enum.CameraType.Custom
            if callback then callback() end
        end
    end)
end

function CameraController.restore()
    CameraController.stopCinematic()
    local camera = Workspace.CurrentCamera
    if camera then
        camera.CameraType = Enum.CameraType.Custom
    end
end

-- Collect assets
local function collectAssets()
    local assets = {}
    
    local function addAsset(instance)
        if instance:IsA("Sound") and instance.SoundId ~= "" then
            table.insert(assets, instance)
        elseif instance:IsA("Decal") and instance.Texture ~= "" then
            table.insert(assets, instance)
        elseif instance:IsA("Texture") and instance.Texture ~= "" then
            table.insert(assets, instance)
        elseif instance:IsA("MeshPart") and instance.MeshId ~= "" then
            table.insert(assets, instance)
        elseif instance:IsA("ImageLabel") and instance.Image ~= "" then
            table.insert(assets, instance)
        elseif instance:IsA("ParticleEmitter") and instance.Texture ~= "" then
            table.insert(assets, instance)
        end
    end
    
    Logger.safeCall("LoadingScreen", "preloadWorkspace", function()
        for _, d in ipairs(Workspace:GetDescendants()) do addAsset(d) end
    end)
    Logger.safeCall("LoadingScreen", "preloadStorage", function()
        for _, d in ipairs(ReplicatedStorage:GetDescendants()) do addAsset(d) end
    end)
    Logger.safeCall("LoadingScreen", "preloadLighting", function()
        for _, d in ipairs(Lighting:GetDescendants()) do addAsset(d) end
    end)
    
    return assets
end

-- Main Component
local function LoadingScreen(props)
    local progress, setProgress = React.useState(0)
    local phase, setPhase = React.useState("loading")
    local loaded, setLoaded = React.useState(0)
    local total, setTotal = React.useState(0)
    local visible, setVisible = React.useState(true)
    local canSkip, setCanSkip = React.useState(false)
    local logoOffset, setLogoOffset = React.useState(0)
    local logoScale, setLogoScale = React.useState(0)
    local logoOpacity, setLogoOpacity = React.useState(0)
    local buttonScale, setButtonScale = React.useState(0)
    local buttonOpacity, setButtonOpacity = React.useState(0)
    
    local mountedRef = React.useRef(true)
    local skippedRef = React.useRef(false)
    local logoRef = React.useRef(nil)
    
    -- Responsive sizes
    local sizes = ResponsiveUtil.getSizes()
    local isPhone = ResponsiveUtil.isPhone()
    local isMobile = ResponsiveUtil.isMobile()
    
    -- Get viewport size for better scaling
    local camera = Workspace.CurrentCamera
    local viewportSize = camera and camera.ViewportSize or Vector2.new(1920, 1080)
    local screenWidth = viewportSize.X
    local screenHeight = viewportSize.Y
    
    -- Scale based on screen size
    local scaleFactor = isPhone and 0.85 or (isMobile and 0.9 or 1)
    
    local contentWidth = isPhone and math.min(screenWidth * 0.9, 320) or (isMobile and 400 or 500)
    local contentHeight = isPhone and 180 or (isMobile and 240 or 280)
    local statusFontSize = isPhone and 14 or (isMobile and 18 or 24)
    local barHeight = isPhone and 12 or (isMobile and 16 or 24)
    local buttonWidth = isPhone and math.min(screenWidth * 0.6, 180) or (isMobile and 200 or 250)
    local buttonHeight = isPhone and 44 or (isMobile and 48 or 56)
    local buttonFontSize = isPhone and 14 or (isMobile and 16 or 20)
    local skipWidth = isPhone and math.min(screenWidth * 0.7, 220) or 300
    local skipFontSize = isPhone and 10 or 14
    local logoWidth = isPhone and math.min(screenWidth * 0.85, 280) or (isMobile and 400 or 600)
    local logoHeight = isPhone and math.min(screenWidth * 0.45, 140) or (isMobile and 200 or 300)
    
    -- Entrance animation when phase becomes "ready"
    React.useEffect(function()
        if phase ~= "ready" then return end
        
        local logoConn = nil
        local buttonConn = nil
        
        -- Animate logo first (scale + fade in)
        local logoStartTime = tick()
        local logoDuration = 0.6
        
        logoConn = RunService.RenderStepped:Connect(function()
            if not mountedRef.current then 
                if logoConn then logoConn:Disconnect() end
                return 
            end
            local elapsed = tick() - logoStartTime
            local alpha = math.clamp(elapsed / logoDuration, 0, 1)
            -- Ease out for smooth effect
            local eased = 1 - math.pow(1 - alpha, 3)
            setLogoScale(eased)
            setLogoOpacity(alpha)
            
            if alpha >= 1 then
                if logoConn then logoConn:Disconnect() end
            end
        end)
        
        -- Animate button after logo (delayed)
        task.delay(0.3, function()
            if not mountedRef.current then return end
            local buttonStartTime = tick()
            local buttonDuration = 0.5
            
            buttonConn = RunService.RenderStepped:Connect(function()
                if not mountedRef.current then 
                    if buttonConn then buttonConn:Disconnect() end
                    return 
                end
                local elapsed = tick() - buttonStartTime
                local alpha = math.clamp(elapsed / buttonDuration, 0, 1)
                local eased = 1 - math.pow(1 - alpha, 3)
                setButtonScale(eased)
                setButtonOpacity(alpha)
                
                if alpha >= 1 then
                    if buttonConn then buttonConn:Disconnect() end
                end
            end)
        end)
        
        return function()
            if logoConn then Logger.safeCall("LoadingScreen", "disconnectLogo", function() logoConn:Disconnect() end) end
            if buttonConn then Logger.safeCall("LoadingScreen", "disconnectButton", function() buttonConn:Disconnect() end) end
        end
    end, {phase})
    
    -- Logo floating animation - smooth sine wave (only after entrance animation)
    React.useEffect(function()
        if phase ~= "ready" then return end
        
        local floatConn = nil
        
        -- Wait for entrance animation to complete
        task.delay(0.8, function()
            if not mountedRef.current then return end
            
            local startTime = tick()
            local currentOffset = 0
            local targetOffset = 0
            floatConn = RunService.RenderStepped:Connect(function(dt)
                if not mountedRef.current then 
                    if floatConn then floatConn:Disconnect() end
                    return 
                end
                local elapsed = tick() - startTime
                -- Smooth sine wave: slower speed (1.5), smaller amplitude (6px)
                targetOffset = math.sin(elapsed * 1.5) * 6
                -- Lerp for extra smoothness
                currentOffset = currentOffset + (targetOffset - currentOffset) * math.min(dt * 8, 1)
                setLogoOffset(currentOffset)
            end)
        end)
        
        return function()
            if floatConn then Logger.safeCall("LoadingScreen", "disconnectFloat", function() floatConn:Disconnect() end) end
        end
    end, {phase})

    local function finish()
        if not mountedRef.current then return end
        LoadingState.isLoading = false
        setLoadingBlur(false)
        setVisible(false)
        
        -- Notify server that loading is complete (unanchor player)
        local Remotes = ReplicatedStorage:FindFirstChild("Remotes")
        if Remotes then
            local LoadingComplete = Remotes:FindFirstChild("LoadingComplete")
            if LoadingComplete then
                LoadingComplete:FireServer()
            end
        end
        
        -- Notify App that loading is complete
        if _G.OnLoadingComplete then
            _G.OnLoadingComplete()
        end
        
        if props.onComplete then
            props.onComplete()
        end
    end

    local function onStartGame()
        if phase ~= "ready" then return end
        setPhase("starting")
        
        -- Play click sound
        playStartSound()
        
        -- Fade out background music (2 seconds)
        BGMController.fadeOut(2)
        
        CameraController.cinematicToCharacter(function()
            finish()
        end)
    end

    local function onSkip()
        if phase == "loading" then
            skippedRef.current = true
            setProgress(1)
            setPhase("ready")
        end
    end

    React.useEffect(function()
        mountedRef.current = true
        skippedRef.current = false
        LoadingState.isLoading = true
        
        -- Enable blur
        setLoadingBlur(true)
        
        -- Start background music
        BGMController.play()
        
        task.defer(function()
            CameraController.startCinematic()
        end)
        
        task.spawn(function()
            task.wait(0.8)
            if not mountedRef.current then return end
            
            local assets = collectAssets()
            local totalAssets = #assets
            setTotal(totalAssets)
            
            -- Minimum loading time to show progress bar (4 seconds)
            local minLoadTime = 4.0
            local startTime = tick()
            
            if skippedRef.current then
                setProgress(1)
                setPhase("ready")
                return
            end
            
            if totalAssets > 0 then
                local loadedCount = 0
                
                for i, asset in ipairs(assets) do
                    if skippedRef.current or not mountedRef.current then break end
                    
                    Logger.safeCall("LoadingScreen", "preloadAsset", function()
                        ContentProvider:PreloadAsync({asset})
                    end)
                    
                    loadedCount = loadedCount + 1
                    setLoaded(loadedCount)
                    setProgress(loadedCount / totalAssets)
                    
                    -- Slower loading - wait more often
                    if i % 5 == 0 then task.wait(0.05) end
                end
            else
                -- No assets - simulate loading progress (slower)
                for i = 1, 40 do
                    if skippedRef.current or not mountedRef.current then break end
                    setProgress(i / 40)
                    setLoaded(i)
                    setTotal(40)
                    task.wait(0.08)
                end
            end
            
            if not mountedRef.current then return end
            
            -- Ensure minimum load time
            local elapsed = tick() - startTime
            if elapsed < minLoadTime then
                -- Smoothly fill remaining progress during wait
                local remaining = minLoadTime - elapsed
                local currentProgress = progress
                local steps = math.floor(remaining / 0.05)
                
                for i = 1, steps do
                    if skippedRef.current or not mountedRef.current then break end
                    local newProgress = currentProgress + ((1 - currentProgress) * (i / steps))
                    setProgress(math.min(newProgress, 0.99))
                    task.wait(0.05)
                end
            end
            
            setProgress(1)
            task.wait(0.3) -- Small pause before showing ready
            setPhase("ready")
        end)
        
        task.delay(3, function()
            if mountedRef.current and phase == "loading" then
                setCanSkip(true)
            end
        end)
        
        return function()
            mountedRef.current = false
            setLoadingBlur(false)
            CameraController.restore()
            BGMController.stop() -- Stop BGM on cleanup
        end
    end, {})

    React.useEffect(function()
        local conn = UserInputService.InputBegan:Connect(function(input, processed)
            if processed then return end
            if not canSkip or phase ~= "loading" then return end
            
            if input.UserInputType == Enum.UserInputType.MouseButton1 or
               input.UserInputType == Enum.UserInputType.Touch or
               input.KeyCode == Enum.KeyCode.Space then
                onSkip()
            end
        end)
        
        return function() conn:Disconnect() end
    end, {canSkip, phase})
    
    if not visible then return nil end
    
    -- Use theme colors (blue)
    local barBgColor = Theme.BackgroundCard  -- Slate-700
    local barFillColor = Theme.Primary       -- Blue-500
    
    return React.createElement("ScreenGui", {
        Name = "LoadingScreen",
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
        DisplayOrder = ZIndex.LOADING,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    }, {
        -- Overlay
        Overlay = React.createElement("Frame", {
            Size = UDim2.fromScale(1, 1),
            BackgroundColor3 = Color3.new(0, 0, 0),
            BackgroundTransparency = 0.35,
            BorderSizePixel = 0,
            ZIndex = ZIndex.BASE
        }),
        
        -- Center content
        Content = React.createElement("Frame", {
            Size = UDim2.new(0, contentWidth, 0, contentHeight),
            Position = UDim2.fromScale(0.5, 0.5),
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundTransparency = 1,
            ZIndex = ZIndex.OVERLAY
        }, {
            -- Status text (loading phase only)
            StatusText = phase == "loading" and React.createElement("TextLabel", {
                Size = UDim2.new(2, 0, 0, 36),
                Position = UDim2.new(0.5, 0, 0.5, -(barHeight + 12)),
                AnchorPoint = Vector2.new(0.5, 1),
                BackgroundTransparency = 1,
                Text = "Just a moment…",
                TextColor3 = Color3.new(1, 1, 1),
                TextSize = statusFontSize,
                Font = Enum.Font.GothamBold,
                TextXAlignment = Enum.TextXAlignment.Center,
                TextWrapped = true
            }) or nil,
            
            -- Progress bar (loading phase)
            ProgressBar = phase == "loading" and React.createElement("Frame", {
                Size = UDim2.new(1, 0, 0, barHeight),
                Position = UDim2.new(0.5, 0, 0.5, 0),
                AnchorPoint = Vector2.new(0.5, 0.5),
                BackgroundColor3 = barBgColor,
                BorderSizePixel = 0
            }, {
                Corner = React.createElement("UICorner", { CornerRadius = UDim.new(0, 8) }),
                Fill = React.createElement("Frame", {
                    Size = UDim2.new(math.max(progress, 0.01), 0, 1, 0),
                    BackgroundColor3 = barFillColor,
                    BorderSizePixel = 0
                }, {
                    Corner = React.createElement("UICorner", { CornerRadius = UDim.new(0, 8) })
                })
            }) or nil,
            
            -- Skip button (loading phase) - closer to loading bar
            SkipButton = phase == "loading" and canSkip and React.createElement("TextButton", {
                Size = UDim2.new(0, skipWidth, 0, isPhone and 32 or 38),
                Position = UDim2.new(0.5, 0, 0.5, barHeight / 2 + 12),
                AnchorPoint = Vector2.new(0.5, 0),
                BackgroundColor3 = Color3.fromRGB(60, 60, 70),
                BackgroundTransparency = 0.5,
                Text = "Still loading? You can skip it",
                TextColor3 = Color3.fromRGB(200, 200, 200),
                TextSize = skipFontSize,
                Font = Enum.Font.GothamMedium,
                AutoButtonColor = false,
                Event = {
                    MouseButton1Click = onSkip,
                    MouseEnter = function(rbx)
                        TweenService:Create(rbx, TweenInfo.new(0.2), {
                            BackgroundTransparency = 0.3,
                            TextColor3 = Color3.new(1, 1, 1)
                        }):Play()
                    end,
                    MouseLeave = function(rbx)
                        TweenService:Create(rbx, TweenInfo.new(0.2), {
                            BackgroundTransparency = 0.5,
                            TextColor3 = Color3.fromRGB(200, 200, 200)
                        }):Play()
                    end
                }
            }, {
                Corner = React.createElement("UICorner", { CornerRadius = UDim.new(0, 8) })
            }) or nil,
            
            -- Logo Image (ready phase) - dengan animasi entrance
            LogoImage = phase == "ready" and React.createElement("ImageLabel", {
                Size = UDim2.new(0, logoWidth * logoScale, 0, logoHeight * logoScale),
                Position = UDim2.new(0.5, 0, isPhone and 0.35 or 0.5, isPhone and 0 or (-(buttonHeight / 2) - 5 + logoOffset)),
                AnchorPoint = Vector2.new(0.5, isPhone and 0.5 or 1),
                BackgroundTransparency = 1,
                Image = "rbxassetid://121888151559575",
                ScaleType = Enum.ScaleType.Fit,
                ImageTransparency = 1 - logoOpacity,
                ref = logoRef
            }) or nil,
            
            -- Start Game button (ready phase) - dengan animasi entrance
            StartButton = phase == "ready" and React.createElement("TextButton", {
                Size = UDim2.new(0, buttonWidth * buttonScale, 0, buttonHeight * buttonScale),
                Position = UDim2.new(0.5, 0, isPhone and 0.62 or 0.5, 0),
                AnchorPoint = Vector2.new(0.5, 0.5),
                BackgroundColor3 = Theme.Primary,
                BackgroundTransparency = 1 - buttonOpacity,
                Text = "Start Game",
                TextColor3 = Color3.new(1, 1, 1),
                TextTransparency = 1 - buttonOpacity,
                TextSize = buttonFontSize,
                Font = Enum.Font.GothamBold,
                AutoButtonColor = false,
                Event = {
                    MouseButton1Click = onStartGame,
                    MouseEnter = function(rbx)
                        if buttonScale >= 1 then
                            TweenService:Create(rbx, TweenInfo.new(0.15), {
                                Size = UDim2.new(0, buttonWidth + 8, 0, buttonHeight + 3),
                                BackgroundColor3 = Theme.PrimaryLight
                            }):Play()
                        end
                    end,
                    MouseLeave = function(rbx)
                        if buttonScale >= 1 then
                            TweenService:Create(rbx, TweenInfo.new(0.15), {
                                Size = UDim2.new(0, buttonWidth, 0, buttonHeight),
                                BackgroundColor3 = Theme.Primary
                            }):Play()
                        end
                    end
                }
            }, {
                Corner = React.createElement("UICorner", { CornerRadius = UDim.new(0, isPhone and 10 or 12) }),
                Stroke = React.createElement("UIStroke", {
                    Color = Theme.PrimaryLight,
                    Thickness = isPhone and 1.5 or 2,
                    Transparency = 0.5 + (1 - buttonOpacity) * 0.5
                })
            }) or nil
        })
    })
end

-- Module export
local LoadingScreenModule = {}

function LoadingScreenModule.create(props)
    return React.createElement(LoadingScreen, props or {})
end

function LoadingScreenModule.isLoading()
    return LoadingState.isLoading
end

return LoadingScreenModule