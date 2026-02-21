--[[
    Server Initialization Script
    Initializes PlayerData and other server systems
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Wait for modules
local Shared = ReplicatedStorage:WaitForChild("Shared")
local PlayerData = require(Shared:WaitForChild("PlayerData"))

-- print("Server script loaded!")

-- Initialize PlayerData system
PlayerData.init()

-- Setup Remotes folder
local Remotes = ReplicatedStorage:FindFirstChild("Remotes")
if not Remotes then
    Remotes = Instance.new("Folder")
    Remotes.Name = "Remotes"
    Remotes.Parent = ReplicatedStorage
end

-- Create LoadingComplete remote
local LoadingComplete = Remotes:FindFirstChild("LoadingComplete")
if not LoadingComplete then
    LoadingComplete = Instance.new("RemoteEvent")
    LoadingComplete.Name = "LoadingComplete"
    LoadingComplete.Parent = Remotes
end

-- Track players who are still loading (first time only)
local LoadingPlayers = {} -- { [userId] = true }
local PlayersLoaded = {} -- { [userId] = true } - players who have completed loading at least once

-- Anchor player during loading (first time only)
local function anchorPlayerForLoading(player)
    -- Only anchor if player hasn't completed loading yet
    if PlayersLoaded[player.UserId] then
        return -- Already loaded before, don't anchor on respawn
    end
    
    local character = player.Character
    if not character then return end
    
    local hrp = character:FindFirstChild("HumanoidRootPart")
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    
    if hrp and humanoid then
        hrp.Anchored = true
        humanoid.WalkSpeed = 0
        humanoid.JumpPower = 0
        LoadingPlayers[player.UserId] = true
        print("[Server] Anchored", player.Name, "for loading")
    end
end

-- Unanchor player after loading complete
local function unanchorPlayerAfterLoading(player)
    if not LoadingPlayers[player.UserId] then return end
    
    local character = player.Character
    if not character then return end
    
    local hrp = character:FindFirstChild("HumanoidRootPart")
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    
    if hrp and humanoid then
        hrp.Anchored = false
        humanoid.WalkSpeed = 16
        humanoid.JumpPower = 50
        LoadingPlayers[player.UserId] = nil
        PlayersLoaded[player.UserId] = true -- Mark as loaded
        print("[Server] Unanchored", player.Name, "- loading complete")
    end
end

-- Handle loading complete from client
LoadingComplete.OnServerEvent:Connect(function(player)
    unanchorPlayerAfterLoading(player)
end)

-- Player join handling
Players.PlayerAdded:Connect(function(player)
    print(player.Name .. " joined the game!")
    
    -- Anchor when character spawns
    local function onCharacterAdded(character)
        -- Wait for character to fully load
        local hrp = character:WaitForChild("HumanoidRootPart", 10)
        local humanoid = character:WaitForChild("Humanoid", 10)
        
        if hrp and humanoid then
            -- Small delay to ensure everything is ready
            task.wait(0.2)
            anchorPlayerForLoading(player)
        end
    end
    
    player.CharacterAdded:Connect(onCharacterAdded)
    
    -- Handle existing character
    if player.Character then
        task.spawn(function()
            onCharacterAdded(player.Character)
        end)
    end
    
    -- Example: Give player bonus currency after 10 seconds
    task.delay(10, function()
        if player.Parent then
            PlayerData.addCurrency(player, 100)
            print("[Server] Gave " .. player.Name .. " 100 bonus currency")
        end
    end)
end)

-- Clean up when player leaves
Players.PlayerRemoving:Connect(function(player)
    LoadingPlayers[player.UserId] = nil
    PlayersLoaded[player.UserId] = nil
end)

-- Example: Award kill/death stats (connect to your combat system)
-- PlayerData.get(player).kills = PlayerData.get(player).kills + 1
