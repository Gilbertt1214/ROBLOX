--[[
    Player Overhead Display
    Shows player display name, role, and streak
    Role is determined by daily login streak
    Login once per day = +1 streak
    Supports hiding streak and username based on player settings
]]

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local LocalizationService = game:GetService("LocalizationService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Icons = require(ReplicatedStorage.Shared.Icons)

-- print("[Overhead] Initializing player overhead system...")

-- DataStore with error handling
local PlayerDataStore = nil
local dataStoreAvailable = false

local function initDataStore()
    local success, result = pcall(function()
        return DataStoreService:GetDataStore("PlayerOverhead_v2")
    end)
    
    if success then
        PlayerDataStore = result
        dataStoreAvailable = true
        -- print("[Overhead] DataStore initialized successfully")
    else
        warn("[Overhead] DataStore not available:", result)
        dataStoreAvailable = false
    end
end

initDataStore()

-- Player visibility settings cache
local playerVisibilitySettings = {}

-- Role Configuration (ordered by streak requirement)
local ROLES = {
    { name = "Commoner", color = Color3.fromRGB(150, 150, 150), minStreak = 0 },
    { name = "Hufflepuff", color = Color3.fromRGB(236, 185, 57), minStreak = 7 },
    { name = "Ravenclaw", color = Color3.fromRGB(34, 47, 91), minStreak = 14 },
    { name = "Slytherin", color = Color3.fromRGB(26, 71, 42), minStreak = 30 },
    { name = "Gryffindor", color = Color3.fromRGB(174, 0, 1), minStreak = 60 },
    { name = "Head of House", color = Color3.fromRGB(255, 215, 0), minStreak = 100 }, -- Gold color for highest streak
}

-- Country flag icon keys
local CountryFlagKeys = {
    ID = "flagID", US = "flagUS", GB = "flagGB", JP = "flagJP",
    KR = "flagKR", BR = "flagBR", PH = "flagPH", MY = "flagMY",
    SG = "flagSG", AU = "flagAU", DE = "flagDE", FR = "flagFR",
    TH = "flagTH", VN = "flagVN", RU = "flagRU", IN = "flagIN",
}

-- Cache player data
local playerData = {}

-- Get today's date as string (YYYY-MM-DD)
local function getTodayDate()
    local now = os.time()
    return os.date("%Y-%m-%d", now)
end

-- Get yesterday's date
local function getYesterdayDate()
    local now = os.time()
    return os.date("%Y-%m-%d", now - 86400)
end

-- Get player's country code
local function getPlayerCountry(player)
    local success, result = pcall(function()
        return LocalizationService:GetCountryRegionForPlayerAsync(player)
    end)
    return success and result or nil
end

-- Get role based on streak
local function getRoleByStreak(streak)
    local role = ROLES[1] -- Default Commoner
    for _, r in ipairs(ROLES) do
        if streak >= r.minStreak then
            role = r
        end
    end
    return role
end

-- Load player data from DataStore
local function loadPlayerData(player)
    local data = {
        streak = 0,
        lastLogin = nil,
    }
    
    -- Only try to load if DataStore is available
    if dataStoreAvailable and PlayerDataStore then
        local success, result = pcall(function()
            return PlayerDataStore:GetAsync("Player_" .. player.UserId)
        end)
        
        if success and result then
            data = result
            -- Remove old adminRole field if exists
            data.adminRole = nil
        elseif not success then
            warn("[Overhead] Failed to load data for", player.Name, "- using defaults")
        end
    end
    
    -- Check daily login streak
    local today = getTodayDate()
    local yesterday = getYesterdayDate()
    
    if data.lastLogin == today then
        -- Already logged in today, no change
    elseif data.lastLogin == yesterday then
        -- Consecutive day, increase streak
        data.streak = (data.streak or 0) + 1
        data.lastLogin = today
        -- print("[Overhead]", player.Name, "streak increased to", data.streak)
    else
        -- Streak broken or first login
        if data.lastLogin then
            -- print("[Overhead]", player.Name, "streak reset (was", data.streak, ")")
        end
        data.streak = 1
        data.lastLogin = today
    end
    
    -- Save updated data (only if DataStore available)
    if dataStoreAvailable and PlayerDataStore then
        pcall(function()
            PlayerDataStore:SetAsync("Player_" .. player.UserId, data)
        end)
    end
    
    playerData[player.UserId] = data
    return data
end

-- Get player role (streak-based)
local function getPlayerRole(player)
    local data = playerData[player.UserId]
    if not data then return ROLES[1], 0 end
    
    -- Get role by streak
    return getRoleByStreak(data.streak), data.streak
end

-- Create overhead GUI
local function createOverheadGui(player, character)
    local head = character:WaitForChild("Head", 5)
    if not head then return end
    
    -- Remove existing
    local existing = head:FindFirstChild("OverheadGui")
    if existing then existing:Destroy() end
    
    -- Get info
    local username = "@" .. player.Name
    local displayName = player.DisplayName
    local role, streak = getPlayerRole(player)
    
    -- Get visibility settings
    local visSettings = playerVisibilitySettings[player.UserId] or { hideStreak = false, hideUsername = false }
    local hideStreak = visSettings.hideStreak
    local hideUsername = visSettings.hideUsername
    
    -- Determine streak color based on amount
    local streakColor
    if streak >= 60 then
        streakColor = Color3.fromRGB(255, 70, 70) -- Red
    elseif streak >= 30 then
        streakColor = Color3.fromRGB(80, 220, 120) -- Green
    elseif streak >= 14 then
        streakColor = Color3.fromRGB(120, 180, 255) -- Blue
    elseif streak >= 7 then
        streakColor = Color3.fromRGB(255, 210, 80) -- Yellow
    else
        streakColor = Color3.fromRGB(255, 160, 80) -- Orange
    end
    
    -- Create BillboardGui
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "OverheadGui"
    billboard.Size = UDim2.new(0, 180, 0, 70)
    billboard.StudsOffset = Vector3.new(0, 3.2, 0)
    billboard.AlwaysOnTop = false
    billboard.MaxDistance = 50  -- Max distance to see overhead info (50 studs)
    billboard.LightInfluence = 0
    billboard.Parent = head
    
    -- Container
    local container = Instance.new("Frame")
    container.Name = "Container"
    container.Size = UDim2.new(1, 0, 1, 0)
    container.BackgroundTransparency = 1
    container.Parent = billboard
    
    local layout = Instance.new("UIListLayout")
    layout.FillDirection = Enum.FillDirection.Vertical
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    layout.VerticalAlignment = Enum.VerticalAlignment.Top
    layout.Padding = UDim.new(0, 1)
    layout.Parent = container
    
    -- Row 1: @username (small, gray) - only if not hidden
    if not hideUsername then
        local usernameLabel = Instance.new("TextLabel")
        usernameLabel.Name = "Username"
        usernameLabel.Size = UDim2.new(1, 0, 0, 14)
        usernameLabel.BackgroundTransparency = 1
        usernameLabel.Text = username
        usernameLabel.TextColor3 = Color3.fromRGB(160, 160, 160)
        usernameLabel.TextSize = 11
        usernameLabel.Font = Enum.Font.GothamMedium
        usernameLabel.TextStrokeTransparency = 0.6
        usernameLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
        usernameLabel.LayoutOrder = 1
        usernameLabel.Parent = container
    end
    
    -- Row 2: Role (colored) - always show
    local roleLabel = Instance.new("TextLabel")
    roleLabel.Name = "Role"
    roleLabel.Size = UDim2.new(1, 0, 0, 14)
    roleLabel.BackgroundTransparency = 1
    roleLabel.Text = role.name
    roleLabel.TextColor3 = role.color
    roleLabel.TextSize = 11
    roleLabel.Font = Enum.Font.GothamBold
    roleLabel.TextStrokeTransparency = 0.5
    roleLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
    roleLabel.LayoutOrder = 2
    roleLabel.Parent = container
    
    -- Row 3: DisplayName + fire icon + streak number (nickname always shown)
    local nameRow = Instance.new("Frame")
    nameRow.Name = "NameRow"
    nameRow.Size = UDim2.new(1, 0, 0, 26)
    nameRow.BackgroundTransparency = 1
    nameRow.LayoutOrder = 3
    nameRow.Parent = container
    
    local nameRowLayout = Instance.new("UIListLayout")
    nameRowLayout.FillDirection = Enum.FillDirection.Horizontal
    nameRowLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    nameRowLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    nameRowLayout.Padding = UDim.new(0, 3)
    nameRowLayout.Parent = nameRow
    
    -- Country Flag
    local countryCode = getPlayerCountry(player)
    local flagIconName = CountryFlagKeys[countryCode] or "flagUS" -- Fallback to US if not found
    local flagImage = Icons.Get(flagIconName)
    
    if flagImage and flagImage ~= "rbxassetid://0" then
        local flagLabel = Instance.new("ImageLabel")
        flagLabel.Name = "CountryFlag"
        flagLabel.Size = UDim2.new(0, 22, 0, 16) -- Standard flag aspect ratio
        flagLabel.BackgroundTransparency = 1
        flagLabel.Image = flagImage
        flagLabel.ScaleType = Enum.ScaleType.Fit
        flagLabel.LayoutOrder = 0 -- First in row
        flagLabel.Parent = nameRow
        
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 2)
        corner.Parent = flagLabel
    end
    
    -- Display name (nickname) - always shown
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Name = "DisplayName"
    nameLabel.Size = UDim2.new(0, 0, 1, 0)
    nameLabel.AutomaticSize = Enum.AutomaticSize.X
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = displayName
    nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    nameLabel.TextSize = 18
    nameLabel.Font = Enum.Font.FredokaOne
    nameLabel.TextStrokeTransparency = 0.3
    nameLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
    nameLabel.LayoutOrder = 1
    nameLabel.Parent = nameRow
    
    -- Fire icon + streak number (if streak > 0 and not hidden)
    if streak > 0 and not hideStreak then
        local fireIcon = Instance.new("ImageLabel")
        fireIcon.Name = "FireIcon"
        fireIcon.Size = UDim2.new(0, 18, 0, 18)
        fireIcon.BackgroundTransparency = 1
        fireIcon.Image = "rbxassetid://91012672710878"
        fireIcon.ImageColor3 = streakColor
        fireIcon.ScaleType = Enum.ScaleType.Fit
        fireIcon.LayoutOrder = 2
        fireIcon.Parent = nameRow
        
        local streakLabel = Instance.new("TextLabel")
        streakLabel.Name = "StreakNum"
        streakLabel.Size = UDim2.new(0, 0, 1, 0)
        streakLabel.AutomaticSize = Enum.AutomaticSize.X
        streakLabel.BackgroundTransparency = 1
        streakLabel.Text = tostring(streak)
        streakLabel.TextColor3 = streakColor
        streakLabel.TextSize = 16
        streakLabel.Font = Enum.Font.GothamBlack
        streakLabel.TextStrokeTransparency = 0.4
        streakLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
        streakLabel.LayoutOrder = 3
        streakLabel.Parent = nameRow
    end
    
    -- Hide default name
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
    end
    
    -- print("[Overhead] Created for:", player.Name, "Role:", role.name, "Streak:", streak, "HideStreak:", hideStreak, "HideUsername:", hideUsername)
end

-- Update overhead
local function updateOverhead(player)
    if player.Character then
        createOverheadGui(player, player.Character)
    end
end

-- Setup player
local function setupPlayer(player)
    loadPlayerData(player)
    
    -- Initialize visibility settings
    playerVisibilitySettings[player.UserId] = { hideStreak = false, hideUsername = false }
    
    -- Try to get settings from PlayerData
    task.spawn(function()
        task.wait(1) -- Wait for PlayerData to initialize
        local Remotes = ReplicatedStorage:FindFirstChild("Remotes")
        if Remotes then
            local GetPlayerSettings = Remotes:FindFirstChild("GetPlayerSettings")
            if GetPlayerSettings then
                local success, settings = pcall(function()
                    return GetPlayerSettings:InvokeServer(player.UserId)
                end)
                if success and settings then
                    playerVisibilitySettings[player.UserId] = settings
                    updateOverhead(player)
                end
            end
        end
    end)
    
    local function onCharacterAdded(character)
        -- Robust monitoring loop to ensure overhead stays active
        -- This handles morphs that might swap body parts or remove the GUI
        task.spawn(function()
            local connection
            
            -- Detect if Head is replaced
            connection = character.ChildAdded:Connect(function(child)
                if child.Name == "Head" then
                    task.wait(0.1)
                    createOverheadGui(player, character)
                end
            end)
            
            -- Periodic check loop
            while character and character.Parent and player and player.Parent do
                local head = character:FindFirstChild("Head")
                if head then
                    if not head:FindFirstChild("OverheadGui") then
                        -- print("[Overhead] Overhead missing from", player.Name, " - Re-applying")
                        createOverheadGui(player, character)
                    end
                end
                task.wait(2) -- Check every 2 seconds
            end
            
            if connection then connection:Disconnect() end
        end)
        
        -- Initial application
        task.wait(0.3)
        createOverheadGui(player, character)
    end

    -- Connect to future character spawns
    player.CharacterAdded:Connect(onCharacterAdded)
    
    -- Handle current character if already exists
    if player.Character then
        onCharacterAdded(player.Character)
    end
end

-- Initialize existing players
for _, player in pairs(Players:GetPlayers()) do
    task.spawn(setupPlayer, player)
end

Players.PlayerAdded:Connect(setupPlayer)

-- Cleanup
Players.PlayerRemoving:Connect(function(player)
    playerData[player.UserId] = nil
    playerVisibilitySettings[player.UserId] = nil
end)

-- Create Remotes folder if not exists
local Remotes = ReplicatedStorage:FindFirstChild("Remotes")
if not Remotes then
    Remotes = Instance.new("Folder")
    Remotes.Name = "Remotes"
    Remotes.Parent = ReplicatedStorage
end

-- Listen for overhead setting changes from PlayerData
local OverheadSettingChanged = Remotes:FindFirstChild("OverheadSettingChanged")
if not OverheadSettingChanged then
    OverheadSettingChanged = Instance.new("RemoteEvent")
    OverheadSettingChanged.Name = "OverheadSettingChanged"
    OverheadSettingChanged.Parent = Remotes
end

-- Handle setting changes (server-side listener)
-- This is triggered when PlayerData broadcasts a setting change
task.spawn(function()
    -- Create a BindableEvent for internal server communication
    local InternalSettingChanged = Instance.new("BindableEvent")
    InternalSettingChanged.Name = "InternalOverheadSettingChanged"
    InternalSettingChanged.Parent = Remotes
    
    InternalSettingChanged.Event:Connect(function(userId, key, value)
        -- print("[Overhead] Setting changed for userId:", userId, key, "=", value)
        
        if not playerVisibilitySettings[userId] then
            playerVisibilitySettings[userId] = { hideStreak = false, hideUsername = false }
        end
        
        if key == "hideStreak" then
            playerVisibilitySettings[userId].hideStreak = value
        elseif key == "hideUsername" then
            playerVisibilitySettings[userId].hideUsername = value
        end
        
        -- Update overhead for this player
        local player = Players:GetPlayerByUserId(userId)
        if player then
            updateOverhead(player)
        end
    end)
end)

-- Function to update visibility settings (called from PlayerData)
_G.UpdateOverheadVisibility = function(userId, key, value)
    -- print("[Overhead] UpdateOverheadVisibility called:", userId, key, value)
    
    if not playerVisibilitySettings[userId] then
        playerVisibilitySettings[userId] = { hideStreak = false, hideUsername = false }
    end
    
    if key == "hideStreak" then
        playerVisibilitySettings[userId].hideStreak = value
    elseif key == "hideUsername" then
        playerVisibilitySettings[userId].hideUsername = value
    end
    
    -- Update overhead for this player
    local player = Players:GetPlayerByUserId(userId)
    if player then
        updateOverhead(player)
    end
end

-- Global functions for other scripts
_G.GetPlayerStreak = function(player)
    local data = playerData[player.UserId]
    return data and data.streak or 0
end

_G.GetPlayerRole = function(player)
    local role, streak = getPlayerRole(player)
    return role.name, streak
end

-- Remote function to get player info (for PlayerDropdown sync)
local GetPlayerInfo = Remotes:FindFirstChild("GetPlayerInfo")
if not GetPlayerInfo then
    GetPlayerInfo = Instance.new("RemoteFunction")
    GetPlayerInfo.Name = "GetPlayerInfo"
    GetPlayerInfo.Parent = Remotes
end

GetPlayerInfo.OnServerInvoke = function(requestingPlayer, targetUserId)
    local targetPlayer = Players:GetPlayerByUserId(targetUserId)
    if not targetPlayer then
        return { role = "Player", streak = 0, combatWins = 0 }
    end
    
    local data = playerData[targetUserId]
    if not data then
        return { role = "Player", streak = 0, combatWins = 0 }
    end
    
    -- Get persistent combat wins from PlayerData
    local combatWins = 0
    local sharedPlayerDataFolder = ReplicatedStorage:FindFirstChild("Shared")
    if sharedPlayerDataFolder then
        local PlayerData = require(ReplicatedStorage.Shared.PlayerData)
        local stats = PlayerData.get(targetPlayer)
        if stats then
            combatWins = stats.combatWins or 0
        end
    end
    
    local role, streak = getPlayerRole(targetPlayer)
    return {
        role = role.name,
        streak = streak,
        combatWins = combatWins,
        displayName = targetPlayer.DisplayName,
        username = targetPlayer.Name
    }
end

-- print("[Overhead] System ready!")
