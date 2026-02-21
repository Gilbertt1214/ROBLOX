--[[
    SyncDanceHandler Server
    Manages sync dance between players
    Player 2 can sync to Player 1's dances
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Remote
local REMOTE_NAME = "SyncDanceRemote"
local SyncDanceRemote = ReplicatedStorage:FindFirstChild(REMOTE_NAME) or Instance.new("RemoteEvent")
SyncDanceRemote.Name = REMOTE_NAME
SyncDanceRemote.Parent = ReplicatedStorage

-- Config
local MAX_DISTANCE = 25

-- State
-- syncPairs[followerId] = leaderId (a follower can only sync to 1 leader)
local syncPairs: {[number]: number} = {}
-- currentDance[leaderId] = danceId (track what dance leader is playing)
local currentDance: {[number]: string} = {}

-- Helpers
local function getHRP(p: Player)
    local char = p.Character
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function getDistance(p1: Player, p2: Player): number
    local hrp1 = getHRP(p1)
    local hrp2 = getHRP(p2)
    if not (hrp1 and hrp2) then return math.huge end
    return (hrp1.Position - hrp2.Position).Magnitude
end

local function isFollowing(player: Player): boolean
    return syncPairs[player.UserId] ~= nil
end

local function isLeading(player: Player): boolean
    for _, leaderId in pairs(syncPairs) do
        if leaderId == player.UserId then
            return true
        end
    end
    return false
end

local function getFollowers(leader: Player): {Player}
    local followers = {}
    for followerId, leaderId in pairs(syncPairs) do
        if leaderId == leader.UserId then
            local follower = Players:GetPlayerByUserId(followerId)
            if follower then
                table.insert(followers, follower)
            end
        end
    end
    return followers
end

local function getLeader(follower: Player): Player?
    local leaderId = syncPairs[follower.UserId]
    if leaderId then
        return Players:GetPlayerByUserId(leaderId)
    end
    return nil
end

-- Sync start
local function startSync(leader: Player, follower: Player)
    syncPairs[follower.UserId] = leader.UserId
    
    -- Notify both players
    SyncDanceRemote:FireClient(leader, "SyncStarted", {
        followerId = follower.UserId,
        followerName = follower.DisplayName,
        isLeader = true
    })
    SyncDanceRemote:FireClient(follower, "SyncStarted", {
        leaderId = leader.UserId,
        leaderName = leader.DisplayName,
        isLeader = false
    })
    
    -- If leader is currently dancing, sync follower immediately
    local danceId = currentDance[leader.UserId]
    if danceId then
        SyncDanceRemote:FireClient(follower, "PlayDance", {
            danceId = danceId,
            leaderId = leader.UserId
        })
    end
end

-- Sync stop
local function stopSync(follower: Player, reason: string?)
    local leaderId = syncPairs[follower.UserId]
    if not leaderId then return end
    
    local leader = Players:GetPlayerByUserId(leaderId)
    syncPairs[follower.UserId] = nil
    
    -- Notify follower
    SyncDanceRemote:FireClient(follower, "SyncEnded", {
        reason = reason or "unsync"
    })
    
    -- Notify leader
    if leader then
        SyncDanceRemote:FireClient(leader, "FollowerLeft", {
            followerId = follower.UserId,
            followerName = follower.DisplayName,
            reason = reason or "unsync"
        })
    end
end

-- Stop all followers when leader stops
local function stopAllFollowers(leader: Player, reason: string?)
    local followers = getFollowers(leader)
    for _, follower in ipairs(followers) do
        stopSync(follower, reason)
    end
end

-- Broadcast dance to followers
local function broadcastDance(leader: Player, danceId: string?)
    currentDance[leader.UserId] = danceId
    
    local followers = getFollowers(leader)
    for _, follower in ipairs(followers) do
        if danceId then
            SyncDanceRemote:FireClient(follower, "PlayDance", {
                danceId = danceId,
                leaderId = leader.UserId
            })
        else
            SyncDanceRemote:FireClient(follower, "StopDance", {
                leaderId = leader.UserId
            })
        end
    end
end


-- Remote Handlers
SyncDanceRemote.OnServerEvent:Connect(function(player: Player, action: string, data)
    if action == "Request" then
        -- Player wants to sync to target (auto-sync, no prompt needed)
        local targetId = data and data.targetId
        if type(targetId) ~= "number" then return end
        
        local target = Players:GetPlayerByUserId(targetId)
        if not target or target == player then return end
        
        -- Check distance
        if getDistance(player, target) > MAX_DISTANCE then
            SyncDanceRemote:FireClient(player, "TooFar", {})
            return
        end
        
        -- Check if already synced to this target
        if syncPairs[player.UserId] == targetId then
            -- Already synced, unsync instead
            stopSync(player, "unsync")
            return
        end
        
        -- If synced to someone else, unsync first
        if isFollowing(player) then
            stopSync(player, "switch")
        end
        
        -- Auto-sync: player becomes follower, target becomes leader
        startSync(target, player)
        

    elseif action == "Unsync" then
        -- Player wants to unsync
        if isFollowing(player) then
            stopSync(player, "unsync")
        elseif isLeading(player) then
            -- Leader can kick a specific follower or all
            local followerId = data and data.followerId
            if type(followerId) == "number" then
                local follower = Players:GetPlayerByUserId(followerId)
                if follower and syncPairs[followerId] == player.UserId then
                    stopSync(follower, "kicked")
                end
            else
                stopAllFollowers(player, "leader_unsync")
            end
        end
        
    elseif action == "PlayDance" then
        -- Record dance state even if no followers yet (for instant sync later)
        local danceId = data and data.danceId
        if type(danceId) ~= "string" then return end
        
        currentDance[player.UserId] = danceId
        
        -- Broadcast to followers if any
        local followers = getFollowers(player)
        for _, follower in ipairs(followers) do
            SyncDanceRemote:FireClient(follower, "PlayDance", {
                danceId = danceId,
                leaderId = player.UserId
            })
        end
        
    elseif action == "StopDance" then
        -- Clear dance state
        currentDance[player.UserId] = nil
        
        -- Broadcast to followers if any
        local followers = getFollowers(player)
        for _, follower in ipairs(followers) do
            SyncDanceRemote:FireClient(follower, "StopDance", {
                leaderId = player.UserId
            })
        end
        
    elseif action == "GetSyncStatus" then
        -- Client requests current sync status
        local targetId = data and data.targetId
        if type(targetId) ~= "number" then return end
        
        local isSynced = syncPairs[player.UserId] == targetId
        SyncDanceRemote:FireClient(player, "SyncStatus", {
            targetId = targetId,
            isSynced = isSynced
        })
    end
end)

-- Cleanup on player leaving
Players.PlayerRemoving:Connect(function(player: Player)
    -- If player was following someone
    if isFollowing(player) then
        stopSync(player, "left")
    end
    
    -- If player was leading others
    if isLeading(player) then
        stopAllFollowers(player, "leader_left")
    end
    
    currentDance[player.UserId] = nil
end)

-- Helper to setup character listeners
local function setupCharacter(player: Player, character: Model)
    local humanoid = character:WaitForChild("Humanoid", 5)
    if humanoid then
        humanoid.Died:Connect(function()
            -- Auto unsync on death as requested
            if isFollowing(player) then
                stopSync(player, "died")
            end
            
            if isLeading(player) then
                stopAllFollowers(player, "leader_died")
            end
            
            currentDance[player.UserId] = nil
        end)
    end
end

Players.PlayerAdded:Connect(function(player: Player)
    player.CharacterAdded:Connect(function(character)
        setupCharacter(player, character)
    end)
end)

-- Setup for existing players
for _, player in ipairs(Players:GetPlayers()) do
    if player.Character then
        task.spawn(setupCharacter, player, player.Character)
    end
    player.CharacterAdded:Connect(function(character)
        setupCharacter(player, character)
    end)
end

print("[SyncDanceHandler] Server ready")
