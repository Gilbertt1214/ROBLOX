--[[
    SyncDanceController Client
    Handles sync dance events from server
    - Plays dances when leader broadcasts
    - Manages sync state
    - Auto-sync (no prompts needed)
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer

-- Wait for EmotesView
local EmotesView = nil
task.spawn(function()
    local shared = ReplicatedStorage:WaitForChild("Shared", 10)
    if shared then
        local Components = shared:WaitForChild("Components", 10)
        if Components then
            local emotesModule = Components:WaitForChild("EmotesView", 10)
            if emotesModule then
                EmotesView = require(emotesModule)
            end
        end
    end
end)

-- State
local isFollowing = false
local leaderId = nil
local unsyncButtonUI = nil

-- Create standalone Unsync button
local function toggleUnsyncButton(visible)
    if not visible then
        if unsyncButtonUI then
            unsyncButtonUI:Destroy()
            unsyncButtonUI = nil
        end
        return
    end
    
    if unsyncButtonUI then return end
    
    local playerGui = LocalPlayer:WaitForChild("PlayerGui")
    
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "SyncDanceUnsyncUI"
    screenGui.ResetOnSpawn = false
    screenGui.DisplayOrder = 105
    screenGui.Parent = playerGui
    
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(0, 140, 0, 40)
    button.Position = UDim2.new(0.5, 0, 0.85, 0)
    button.AnchorPoint = Vector2.new(0.5, 0.5)
    button.BackgroundColor3 = Color3.fromRGB(180, 80, 80)
    button.BackgroundTransparency = 0.2
    button.Text = "Unsync Dance"
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.TextSize = 14
    button.Font = Enum.Font.GothamBold
    button.AutoButtonColor = true
    button.Parent = screenGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = button
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(255, 255, 255)
    stroke.Thickness = 1
    stroke.Transparency = 0.5
    stroke.Parent = button
    
    button.Activated:Connect(function()
        local SyncDanceRemote = ReplicatedStorage:FindFirstChild("SyncDanceRemote")
        if SyncDanceRemote then
            SyncDanceRemote:FireServer("Unsync", {})
        end
    end)
    
    unsyncButtonUI = screenGui
end

-- Show notification
local function showNotification(message, color)
    local playerGui = LocalPlayer:WaitForChild("PlayerGui")
    
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "SyncDanceNotification"
    screenGui.ResetOnSpawn = false
    screenGui.DisplayOrder = 150
    screenGui.IgnoreGuiInset = true
    screenGui.Parent = playerGui
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0, 300, 0, 40)
    label.Position = UDim2.new(0.5, 0, 0.15, 0)
    label.AnchorPoint = Vector2.new(0.5, 0.5)
    label.BackgroundColor3 = color or Color3.fromRGB(40, 40, 45)
    label.BackgroundTransparency = 0.1
    label.Text = message
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.TextSize = 14
    label.Font = Enum.Font.GothamMedium
    label.Parent = screenGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = label
    
    -- Animate in
    label.Position = UDim2.new(0.5, 0, 0, -50)
    TweenService:Create(label, TweenInfo.new(0.3, Enum.EasingStyle.Back), {
        Position = UDim2.new(0.5, 0, 0.15, 0)
    }):Play()
    
    -- Auto remove
    task.delay(3, function()
        TweenService:Create(label, TweenInfo.new(0.3), {
            Position = UDim2.new(0.5, 0, 0, -50),
            BackgroundTransparency = 1,
            TextTransparency = 1
        }):Play()
        task.delay(0.35, function()
            screenGui:Destroy()
        end)
    end)
end

-- Setup remote handlers
local function setupRemoteHandlers()
    local SyncDanceRemote = ReplicatedStorage:WaitForChild("SyncDanceRemote", 10)
    if not SyncDanceRemote then
        warn("[SyncDanceController] SyncDanceRemote not found")
        return
    end
    
    SyncDanceRemote.OnClientEvent:Connect(function(action, data)
        if action == "SyncStarted" then
            if data.isLeader then
                -- We are the leader
                showNotification("" .. data.followerName .. " synced with you!", Color3.fromRGB(80, 180, 100))
                if EmotesView then
                    EmotesView.setSyncLeader(true)
                end
            else
                -- We are the follower
                isFollowing = true
                leaderId = data.leaderId
                _G._SyncLeaderId = leaderId
                showNotification("synced with " .. data.leaderName .. "!", Color3.fromRGB(80, 180, 100))
                toggleUnsyncButton(true)
            end
            
        elseif action == "SyncEnded" then
            isFollowing = false
            leaderId = nil
            _G._SyncLeaderId = nil
            if EmotesView then
                EmotesView.setSyncLeader(false)
                EmotesView.stopEmote()
            end
            showNotification("Sync ended", Color3.fromRGB(150, 150, 150))
            toggleUnsyncButton(false)
        elseif action == "FollowerLeft" then
            showNotification(data.followerName .. " unsynced", Color3.fromRGB(150, 150, 150))
            
        elseif action == "PlayDance" then
            -- Leader is playing a dance, follow along
            if isFollowing and EmotesView then
                EmotesView.toggleEmote(data.danceId, true) -- true = from sync
            end
            
        elseif action == "StopDance" then
            -- Leader stopped dancing
            if isFollowing and EmotesView then
                EmotesView.stopEmote()
            end
            
        elseif action == "TooFar" then
            showNotification("Too far to sync", Color3.fromRGB(180, 150, 50))
            
        elseif action == "SyncStatus" then
            -- Response to GetSyncStatus query
            _G._SyncDanceStatus = _G._SyncDanceStatus or {}
            _G._SyncDanceStatus[data.targetId] = data.isSynced
        end
    end)
end

-- Initialize
task.spawn(function()
    setupRemoteHandlers()
  
end)
