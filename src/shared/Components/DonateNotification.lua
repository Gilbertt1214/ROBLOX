--[[
    DonateNotification Component
    Elegant notifications for donations
    Shows at top of screen with smooth animations
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local Players = game:GetService("Players")
local Roact = require(ReplicatedStorage.Shared.Roact)
local Theme = require(ReplicatedStorage.Shared.Theme)
local ResponsiveUtil = require(ReplicatedStorage.Shared.ResponsiveUtil)

local DonateNotification = {}

-- Notification queue
local notificationQueue = {}
local isShowing = false
local currentGui = nil

-- Sound effects
local donationSounds = {
    small = "rbxassetid://6026984224",
    medium = "rbxassetid://5153734236",
    large = "rbxassetid://4612373233",
}

-- Play donation sound based on amount
local function playDonationSound(amount)
    local soundId = donationSounds.small
    local volume = 0.5
    
    if amount >= 500 then
        soundId = donationSounds.large
        volume = 0.7
    elseif amount >= 100 then
        soundId = donationSounds.medium
        volume = 0.6
    end
    
    local sound = Instance.new("Sound")
    sound.SoundId = soundId
    sound.Volume = volume
    sound.PlayOnRemove = false
    sound.Parent = SoundService
    
    sound:Play()
    
    sound.Ended:Connect(function()
        sound:Destroy()
    end)
    
    task.delay(5, function()
        if sound and sound.Parent then
            sound:Destroy()
        end
    end)
end

-- Create the notification GUI
local function createNotificationGui()
    local player = Players.LocalPlayer
    if not player then return nil end
    
    local playerGui = player:FindFirstChild("PlayerGui")
    if not playerGui then return nil end
    
    local existing = playerGui:FindFirstChild("DonateNotificationGui")
    if existing then
        existing:Destroy()
    end
    
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "DonateNotificationGui"
    screenGui.ResetOnSpawn = false
    screenGui.DisplayOrder = 100
    screenGui.IgnoreGuiInset = true
    screenGui.Parent = playerGui
    
    return screenGui
end

-- Show a single notification with animation
local function showNotification(data)
    if isShowing then
        table.insert(notificationQueue, data)
        return
    end
    
    isShowing = true
    
    local gui = currentGui or createNotificationGui()
    if not gui then 
        isShowing = false
        return 
    end
    currentGui = gui
    
    -- Clear previous
    for _, child in pairs(gui:GetChildren()) do
        child:Destroy()
    end
    
    local playerName = data.playerName or "Someone"
    local amount = data.amount or 0
    local productName = data.productName or "Donation"
    
    -- Responsive sizes
    local isPhone = ResponsiveUtil.isPhone()
    local isTablet = ResponsiveUtil.isTablet()
    local isMobile = ResponsiveUtil.isMobile()
    
    -- Container sizes based on device
    local containerWidth = isPhone and 280 or (isTablet and 340 or 400)
    local containerHeight = isPhone and 65 or (isTablet and 72 or 80)
    
    -- Top offset to avoid Roblox buttons on mobile
    local topOffset = isPhone and 50 or (isTablet and 45 or 20)
    
    -- Font sizes
    local tierFontSize = isPhone and 9 or (isTablet and 10 or 11)
    local nameFontSize = isPhone and 13 or (isTablet and 14 or 16)
    local detailFontSize = isPhone and 10 or (isTablet and 11 or 12)
    local amountFontSize = isPhone and 10 or (isTablet and 11 or 13)
    
    -- Element sizes
    local tierBadgeWidth = isPhone and 65 or (isTablet and 72 or 80)
    local tierBadgeHeight = isPhone and 18 or (isTablet and 20 or 22)
    local amountBadgeWidth = isPhone and 50 or (isTablet and 58 or 65)
    local amountBadgeHeight = isPhone and 26 or (isTablet and 28 or 32)
    
    -- Spacing
    local leftPadding = isPhone and 16 or 20
    local tierTopOffset = isPhone and 8 or (isTablet and 10 or 12)
    local nameTopOffset = isPhone and 28 or (isTablet and 32 or 36)
    local detailTopOffset = isPhone and 46 or (isTablet and 52 or 58)
    
    -- Colors based on amount (tier system)
    local accentColor = Theme.Primary
    local tierText = "Supporter"
    if amount >= 500 then
        accentColor = Color3.fromRGB(255, 200, 50) -- Gold
        tierText = "Super Fan"
    elseif amount >= 200 then
        accentColor = Color3.fromRGB(180, 100, 255) -- Purple
        tierText = "Big Supporter"
    elseif amount >= 100 then
        accentColor = Color3.fromRGB(100, 180, 255) -- Blue
        tierText = "Supporter"
    elseif amount >= 50 then
        accentColor = Color3.fromRGB(100, 220, 150) -- Green
        tierText = "Helper"
    end
    
    -- Main container
    local container = Instance.new("Frame")
    container.Name = "NotificationContainer"
    container.Size = UDim2.new(0, containerWidth, 0, containerHeight)
    container.Position = UDim2.new(0.5, 0, 0, -100)
    container.AnchorPoint = Vector2.new(0.5, 0)
    container.BackgroundColor3 = Color3.fromRGB(25, 28, 35)
    container.BackgroundTransparency = 0.05
    container.Parent = gui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, isPhone and 10 or 12)
    corner.Parent = container
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = accentColor
    stroke.Thickness = isPhone and 1.5 or 2
    stroke.Transparency = 0.2
    stroke.Parent = container
    
    -- Left accent bar
    local accentBar = Instance.new("Frame")
    accentBar.Size = UDim2.new(0, isPhone and 3 or 4, 1, -16)
    accentBar.Position = UDim2.new(0, isPhone and 6 or 8, 0.5, 0)
    accentBar.AnchorPoint = Vector2.new(0, 0.5)
    accentBar.BackgroundColor3 = accentColor
    accentBar.Parent = container
    
    local accentCorner = Instance.new("UICorner")
    accentCorner.CornerRadius = UDim.new(0, 2)
    accentCorner.Parent = accentBar
    
    -- Tier badge
    local tierBadge = Instance.new("Frame")
    tierBadge.Size = UDim2.new(0, tierBadgeWidth, 0, tierBadgeHeight)
    tierBadge.Position = UDim2.new(0, leftPadding, 0, tierTopOffset)
    tierBadge.BackgroundColor3 = accentColor
    tierBadge.BackgroundTransparency = 0.3
    tierBadge.Parent = container
    
    local tierCorner = Instance.new("UICorner")
    tierCorner.CornerRadius = UDim.new(0, 4)
    tierCorner.Parent = tierBadge
    
    local tierLabel = Instance.new("TextLabel")
    tierLabel.Size = UDim2.new(1, 0, 1, 0)
    tierLabel.BackgroundTransparency = 1
    tierLabel.Text = tierText
    tierLabel.TextColor3 = Color3.new(1, 1, 1)
    tierLabel.TextSize = tierFontSize
    tierLabel.Font = Enum.Font.GothamBold
    tierLabel.Parent = tierBadge
    
    -- Player name
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, -(leftPadding + amountBadgeWidth + 20), 0, 20)
    nameLabel.Position = UDim2.new(0, leftPadding, 0, nameTopOffset)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = playerName .. " donated!"
    nameLabel.TextColor3 = Color3.new(1, 1, 1)
    nameLabel.TextSize = nameFontSize
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
    nameLabel.Parent = container
    
    -- Product and amount
    local detailLabel = Instance.new("TextLabel")
    detailLabel.Size = UDim2.new(1, -(leftPadding + amountBadgeWidth + 20), 0, 16)
    detailLabel.Position = UDim2.new(0, leftPadding, 0, detailTopOffset)
    detailLabel.BackgroundTransparency = 1
    detailLabel.Text = productName .. " - R$ " .. amount
    detailLabel.TextColor3 = Theme.TextMuted
    detailLabel.TextSize = detailFontSize
    detailLabel.Font = Enum.Font.GothamMedium
    detailLabel.TextXAlignment = Enum.TextXAlignment.Left
    detailLabel.TextTruncate = Enum.TextTruncate.AtEnd
    detailLabel.Parent = container
    
    -- Amount badge on right
    local amountBadge = Instance.new("Frame")
    amountBadge.Size = UDim2.new(0, amountBadgeWidth, 0, amountBadgeHeight)
    amountBadge.Position = UDim2.new(1, -10, 0.5, 0)
    amountBadge.AnchorPoint = Vector2.new(1, 0.5)
    amountBadge.BackgroundColor3 = accentColor
    amountBadge.Parent = container
    
    local amountCorner = Instance.new("UICorner")
    amountCorner.CornerRadius = UDim.new(0, isPhone and 5 or 6)
    amountCorner.Parent = amountBadge
    
    local amountLabel = Instance.new("TextLabel")
    amountLabel.Size = UDim2.new(1, 0, 1, 0)
    amountLabel.BackgroundTransparency = 1
    amountLabel.Text = "R$ " .. amount
    amountLabel.TextColor3 = Color3.new(1, 1, 1)
    amountLabel.TextSize = amountFontSize
    amountLabel.Font = Enum.Font.GothamBold
    amountLabel.Parent = amountBadge
    
    -- Play sound effect
    playDonationSound(amount)
    
    -- Animate in (with responsive top offset)
    local slideIn = TweenService:Create(container, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Position = UDim2.new(0.5, 0, 0, topOffset)
    })
    slideIn:Play()
    
    -- Accent bar pulse animation
    task.spawn(function()
        for i = 1, 3 do
            TweenService:Create(accentBar, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {
                Size = UDim2.new(0, isPhone and 5 or 6, 1, -12)
            }):Play()
            task.wait(0.3)
            TweenService:Create(accentBar, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {
                Size = UDim2.new(0, isPhone and 3 or 4, 1, -16)
            }):Play()
            task.wait(0.3)
        end
    end)
    
    -- Wait and animate out
    task.wait(4)
    
    local slideOut = TweenService:Create(container, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
        Position = UDim2.new(0.5, 0, 0, -100)
    })
    slideOut:Play()
    slideOut.Completed:Wait()
    
    container:Destroy()
    isShowing = false
    
    -- Show next in queue
    if #notificationQueue > 0 then
        local nextNotif = table.remove(notificationQueue, 1)
        showNotification(nextNotif)
    end
end

-- Public API
function DonateNotification.showDonation(playerName, productName, amount)
    showNotification({
        playerName = playerName,
        productName = productName,
        amount = amount or 0
    })
end

-- Initialize GUI on load
task.spawn(function()
    task.wait(1)
    currentGui = createNotificationGui()
end)

return DonateNotification
