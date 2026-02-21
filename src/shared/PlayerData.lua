--[[
    PlayerData Module (Server-Side)
    
    ⚠️ IMPORTANT: This module is SERVER-ONLY despite being in /shared folder.
    It's placed here for easier require path but should NEVER be required by client.
    Client should use PlayerDataClient.lua instead.
    
    Manages player data: inventory, stats, currency, friends
    Uses DataStoreService for persistent storage
    Uses ReplicatedStorage RemoteEvents to sync with clients
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local Logger = require(ReplicatedStorage.Shared.Logger)

local PlayerData = {}
PlayerData.__index = PlayerData

-- DataStore setup
local DATA_STORE_NAME = "PlayerData_v2" -- Changed version to reset old data
local AUTO_SAVE_INTERVAL = 60 -- Auto-save every 60 seconds

local dataStore = nil
local playerDataStore = {} -- In-memory cache

-- Initialize DataStore (only in real game, not in Studio test without API)
local function initDataStore()
    local success, result = Logger.safeCall("PlayerData", "initDataStore", function()
        return DataStoreService:GetDataStore(DATA_STORE_NAME)
    end)
    
    if success then
        dataStore = result
        -- print("[PlayerData] DataStore initialized:", DATA_STORE_NAME)
    else
        -- warn("[PlayerData] DataStore not available (Studio without API access?):", result)
    end
end

-- Default data structure (empty inventory - items come from world pickup)
local function getDefaultData()
    return {
        currency = 500,
        level = 1,
        xp = 0,
        xpMax = 100,
        kills = 0,
        deaths = 0,
        combatWins = 0,
        playtime = 0,
        inventory = {}, -- Empty! Items come from picking up in world
        hotbar = {},
        hotbarSlotCount = 3,
        currentToolSlot = nil,
        settings = {
            music = true,
            sfx = true,
            graphicsPreset = "mid",
            dayNightCycle = true,
            timeSpeed = 0.001,
            showPlayerInfo = true,
            masterVolume = 0.8,
            fov = 70,
            hideStreak = false,
            hideUsername = false,
            disableTeleport = false,
            shadows = true,
            particles = true,
            bloom = true,
            sunRays = true,
            clouds = true
        },
        quests = {
            { id = "monster_hunter", title = "Monster Hunter", progress = 0, target = 10, reward = 500 },
            { id = "daily_login", title = "Daily Login", progress = 1, target = 1, reward = 100 },
            { id = "explorer", title = "Explorer", progress = 0, target = 5, reward = 250 },
        }
    }
end

-- Load player data from DataStore
-- Tool ID mapping for migration (kept for backwards compatibility)
local toolIdMapping = {
    ["Sword"] = "Sword",
    ["Pickaxe"] = "Pickaxe",
    ["Axe"] = "Axe",
    ["Magic Staff"] = "MagicStaff",
    ["Shield"] = "Shield",
    ["Bow"] = "Bow",
}

-- Migrate old data
local function migrateData(data)
    if not data then return data end
    
    -- Ensure inventory exists
    if not data.inventory then
        data.inventory = {}
    end
    
    -- Ensure hotbar exists
    if not data.hotbar then
        data.hotbar = {}
    end
    
    -- Ensure hotbarSlotCount exists (minimum 3)
    if not data.hotbarSlotCount or data.hotbarSlotCount < 3 then
        data.hotbarSlotCount = 3
    end
    
    -- Ensure combatWins exists
    if data.combatWins == nil then
        data.combatWins = 0
    end
    
    -- Update toolId for old items
    for _, item in ipairs(data.inventory) do
        if item.toolId == nil and toolIdMapping[item.name] then
            item.toolId = toolIdMapping[item.name]
        end
    end
    
    return data
end

local function loadPlayerData(player)
    local userId = player.UserId
    local data = nil
    
    if dataStore then
        local success, result = Logger.safeCall("PlayerData", "loadData", function()
            return dataStore:GetAsync("Player_" .. userId)
        end)
        
        if success and result then
            data = result
            -- print("[PlayerData] Loaded data from DataStore for", player.Name)
            -- Migrate old data
            data = migrateData(data)
        elseif not success then
            -- warn("[PlayerData] Failed to load data for", player.Name, ":", result)
        end
    end
    
    -- Use default data if no saved data
    if not data then
        data = getDefaultData()
        -- print("[PlayerData] Using default data for", player.Name)
    end
    
    return data
end

-- Save player data to DataStore
local function savePlayerData(player)
    local userId = player.UserId
    local data = playerDataStore[userId]
    
    if not data then return false end
    if not dataStore then 
        -- print("[PlayerData] DataStore not available, data not saved")
        return false 
    end
    
    local success, result = Logger.safeCall("PlayerData", "saveData", function()
        dataStore:SetAsync("Player_" .. userId, data)
    end)
    
    if success then
        -- print("[PlayerData] Saved data for", player.Name)
        return true
    else
        -- warn("[PlayerData] Failed to save data for", player.Name, ":", result)
        return false
    end
end

-- Auto-save all players periodically
local function startAutoSave()
    task.spawn(function()
        while true do
            task.wait(AUTO_SAVE_INTERVAL)
            for _, player in pairs(Players:GetPlayers()) do
                savePlayerData(player)
            end
        end
    end)
end

-- Setup RemoteEvents
local function setupRemotes()
    local remoteFolder = ReplicatedStorage:FindFirstChild("Remotes")
    if not remoteFolder then
        remoteFolder = Instance.new("Folder")
        remoteFolder.Name = "Remotes"
        remoteFolder.Parent = ReplicatedStorage
    end
    
    local events = {"GetPlayerData", "UpdateCurrency", "UpdateInventory", "UpdateStats", "UpdateSettings", "UpdateQuests", "EquipItem", "UnequipItem", "SelectHotbarSlot", "UseItem", "GetPlayerSettings"}
    for _, eventName in ipairs(events) do
        if not remoteFolder:FindFirstChild(eventName) then
            local remote = Instance.new("RemoteFunction")
            remote.Name = eventName
            remote.Parent = remoteFolder
        end
    end
    
    -- Event for real-time updates
    if not remoteFolder:FindFirstChild("DataChanged") then
        local event = Instance.new("RemoteEvent")
        event.Name = "DataChanged"
        event.Parent = remoteFolder
    end
    
    -- Event for overhead setting changes (broadcast to all)
    if not remoteFolder:FindFirstChild("OverheadSettingChanged") then
        local event = Instance.new("RemoteEvent")
        event.Name = "OverheadSettingChanged"
        event.Parent = remoteFolder
    end
    
    return remoteFolder
end

-- Initialize
function PlayerData.init()
    -- Initialize DataStore
    initDataStore()
    
    local remotes = setupRemotes()
    
    -- Handle GetPlayerData
    remotes.GetPlayerData.OnServerInvoke = function(player)
        return playerDataStore[player.UserId] or getDefaultData()
    end
    
    -- Handle GetPlayerSettings (for other players to check visibility settings)
    remotes.GetPlayerSettings.OnServerInvoke = function(requestingPlayer, targetUserId)
        local data = playerDataStore[targetUserId]
        if data and data.settings then
            return {
                hideStreak = data.settings.hideStreak or false,
                hideUsername = data.settings.hideUsername or false,
                disableTeleport = data.settings.disableTeleport or false
            }
        end
        return { hideStreak = false, hideUsername = false, disableTeleport = false }
    end
    
    -- Handle UpdateCurrency
    remotes.UpdateCurrency.OnServerInvoke = function(player, amount)
        local data = playerDataStore[player.UserId]
        if data then
            data.currency = math.max(0, data.currency + amount)
            remotes.DataChanged:FireClient(player, "currency", data.currency)
            return data.currency
        end
        return 0
    end
    
    -- Handle UpdateSettings
    remotes.UpdateSettings.OnServerInvoke = function(player, key, value)
        local data = playerDataStore[player.UserId]
        if data then
            -- Allow new settings keys
            if data.settings[key] == nil then
                -- Initialize new setting
                data.settings[key] = value
            else
                data.settings[key] = value
            end
            remotes.DataChanged:FireClient(player, "settings", data.settings)
            
            -- Update overhead visibility if relevant setting changed
            if key == "hideStreak" or key == "hideUsername" then
                -- Call global function to update overhead
                if _G.UpdateOverheadVisibility then
                    _G.UpdateOverheadVisibility(player.UserId, key, value)
                end
            end
            
            return true
        end
        return false
    end
    
    -- Handle UpdateStats (for kills, deaths, etc.)
    remotes.UpdateStats.OnServerInvoke = function(player, statName, value)
        local data = playerDataStore[player.UserId]
        if data and data[statName] ~= nil then
            data[statName] = value
            remotes.DataChanged:FireClient(player, statName, value)
            return true
        end
        return false
    end
    
    -- Handle EquipItem - equip item from inventory to hotbar
    remotes.EquipItem.OnServerInvoke = function(player, itemIndex)
        local data = playerDataStore[player.UserId]
        if not data then return false end
        
        local item = data.inventory[itemIndex]
        if not item or item.equipped then return false end
        
        -- Find first empty slot
        local targetSlot = nil
        for i = 1, data.hotbarSlotCount do
            if not data.hotbar[i] then
                targetSlot = i
                break
            end
        end
        
        -- Expand hotbar if needed (max 9)
        if not targetSlot and data.hotbarSlotCount < 9 then
            data.hotbarSlotCount = data.hotbarSlotCount + 1
            targetSlot = data.hotbarSlotCount
        end
        
        if not targetSlot then return false end
        
        -- Equip item
        item.equipped = true
        item.hotbarSlot = targetSlot
        data.hotbar[targetSlot] = {
            name = item.name,
            emoji = item.emoji,
            icon = item.icon,
            count = item.count,
            toolId = item.toolId, -- Include toolId for equipping
            inventoryIndex = itemIndex
        }
        
        -- print("[PlayerData] Equipped", item.name, "to slot", targetSlot, "toolId:", item.toolId)
        
        -- Notify client
        remotes.DataChanged:FireClient(player, "inventory", data.inventory)
        remotes.DataChanged:FireClient(player, "hotbar", data.hotbar)
        remotes.DataChanged:FireClient(player, "hotbarSlotCount", data.hotbarSlotCount)
        
        return true, targetSlot
    end
    
    -- Handle UnequipItem - unequip item from hotbar back to inventory
    remotes.UnequipItem.OnServerInvoke = function(player, itemIndex)
        local data = playerDataStore[player.UserId]
        if not data then return false end
        
        local item = data.inventory[itemIndex]
        if not item or not item.equipped then return false end
        
        -- Remove from hotbar
        local removedSlot = item.hotbarSlot
        if removedSlot then
            data.hotbar[removedSlot] = nil
        end
        
        item.equipped = false
        item.hotbarSlot = nil
        
        -- Shrink hotbar if last slots are empty (minimum 3)
        while data.hotbarSlotCount > 3 and not data.hotbar[data.hotbarSlotCount] do
            data.hotbarSlotCount = data.hotbarSlotCount - 1
        end
        
        -- print("[PlayerData] Unequipped", item.name, "from slot", removedSlot, "- hotbar now has", data.hotbarSlotCount, "slots")
        
        -- Notify client
        remotes.DataChanged:FireClient(player, "inventory", data.inventory)
        remotes.DataChanged:FireClient(player, "hotbar", data.hotbar)
        remotes.DataChanged:FireClient(player, "hotbarSlotCount", data.hotbarSlotCount)
        
        return true
    end
    
    -- Handle SelectHotbarSlot - equip tool to character's hand (0 = unequip)
    remotes.SelectHotbarSlot.OnServerInvoke = function(player, slotIndex)
        local data = playerDataStore[player.UserId]
        if not data then 
            -- warn("[PlayerData] No data for player")
            return false 
        end
        
        local character = player.Character
        if not character then 
            -- warn("[PlayerData] No character for player")
            return false 
        end
        
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if not humanoid then 
            -- warn("[PlayerData] No humanoid for player")
            return false 
        end
        
        -- Unequip current tool first
        for _, tool in pairs(character:GetChildren()) do
            if tool:IsA("Tool") then
                tool.Parent = player.Backpack
            end
        end
        
        -- If slotIndex is 0 or nil, just unequip (don't equip anything)
        if not slotIndex or slotIndex == 0 then
            -- print("[PlayerData] Unequipped tool for", player.Name)
            data.currentToolSlot = nil
            return true
        end
        
        -- print("[PlayerData] SelectHotbarSlot:", slotIndex, "for", player.Name)
        
        -- Get item from hotbar
        local hotbarItem = data.hotbar[slotIndex]
        if not hotbarItem then 
            -- print("[PlayerData] Slot", slotIndex, "is empty")
            data.currentToolSlot = nil
            return true
        end
        
        -- Check if item has a tool
        if not hotbarItem.toolId then
            -- print("[PlayerData] Item has no toolId (consumable?)")
            data.currentToolSlot = slotIndex
            return true
        end
        
        -- Find tools folder
        local toolsFolder = ReplicatedStorage:FindFirstChild("Tools")
        if not toolsFolder then
            -- warn("[PlayerData] Tools folder not found in ReplicatedStorage!")
            return false
        end
        
        -- Find tool template
        local toolTemplate = toolsFolder:FindFirstChild(hotbarItem.toolId)
        if not toolTemplate then
            -- warn("[PlayerData] Tool template not found:", hotbarItem.toolId)
            return false
        end
        
        -- print("[PlayerData] Found tool template:", toolTemplate.Name)
        
        -- Check if player already has this tool in backpack
        local existingTool = player.Backpack:FindFirstChild(hotbarItem.toolId)
        if not existingTool then
            existingTool = toolTemplate:Clone()
            existingTool.Parent = player.Backpack
            -- print("[PlayerData] Cloned tool to backpack")
        end
        
        -- Equip the tool
        humanoid:EquipTool(existingTool)
        -- print("[PlayerData] Equipped tool:", existingTool.Name)
        
        data.currentToolSlot = slotIndex
        return true
    end
    
    -- Handle UseItem - use consumable item
    remotes.UseItem.OnServerInvoke = function(player, slotIndex)
        local data = playerDataStore[player.UserId]
        if not data then return false end
        
        local hotbarItem = data.hotbar[slotIndex]
        if not hotbarItem then return false end
        
        local invItem = data.inventory[hotbarItem.inventoryIndex]
        if not invItem then return false end
        
        -- Check if consumable (has count > 1 and no toolId)
        if invItem.count and invItem.count > 0 and not invItem.toolId then
            -- Use the item
            invItem.count = invItem.count - 1
            hotbarItem.count = invItem.count
            
            -- Apply effect based on item name
            local character = player.Character
            if character then
                local humanoid = character:FindFirstChildOfClass("Humanoid")
                if humanoid then
                    if invItem.name == "Health Potion" then
                        humanoid.Health = math.min(humanoid.Health + 50, humanoid.MaxHealth)
                        -- print("[PlayerData]", player.Name, "used Health Potion, healed 50 HP")
                    elseif invItem.name == "Cooked Meat" then
                        humanoid.Health = math.min(humanoid.Health + 20, humanoid.MaxHealth)
                        -- print("[PlayerData]", player.Name, "ate Cooked Meat, healed 20 HP")
                    end
                end
            end
            
            -- Remove from hotbar if count is 0
            if invItem.count <= 0 then
                data.hotbar[slotIndex] = nil
                invItem.equipped = false
                invItem.hotbarSlot = nil
            end
            
            -- Notify client
            remotes.DataChanged:FireClient(player, "inventory", data.inventory)
            remotes.DataChanged:FireClient(player, "hotbar", data.hotbar)
            
            return true
        end
        
        return false
    end
    
    -- Player joined - load data from DataStore
    Players.PlayerAdded:Connect(function(player)
        -- Load data from DataStore
        local data = loadPlayerData(player)
        playerDataStore[player.UserId] = data
        -- print("[PlayerData] Initialized data for", player.Name)
        
        -- Track playtime
        task.spawn(function()
            while player.Parent do
                task.wait(1)
                local pData = playerDataStore[player.UserId]
                if pData then
                    pData.playtime = pData.playtime + 1
                end
            end
        end)
    end)
    
    -- Player left - save data to DataStore
    Players.PlayerRemoving:Connect(function(player)
        -- Save data before cleanup
        savePlayerData(player)
        playerDataStore[player.UserId] = nil
        -- print("[PlayerData] Saved and cleaned up data for", player.Name)
    end)
    
    -- Start auto-save
    startAutoSave()
    
    -- Save all data when server shuts down
    game:BindToClose(function()
        -- print("[PlayerData] Server shutting down, saving all player data...")
        for _, player in pairs(Players:GetPlayers()) do
            savePlayerData(player)
        end
        task.wait(2) -- Give time for saves to complete
    end)
    
    -- print("[PlayerData] Server module initialized with DataStore")
end

-- Get data for a player
function PlayerData.get(player)
    return playerDataStore[player.UserId]
end

-- Add item to inventory
function PlayerData.addItem(player, item)
    local data = playerDataStore[player.UserId]
    if data then
        table.insert(data.inventory, item)
        local remotes = ReplicatedStorage:FindFirstChild("Remotes")
        if remotes then
            remotes.DataChanged:FireClient(player, "inventory", data.inventory)
        end
    end
end

-- Add currency
function PlayerData.addCurrency(player, amount)
    local data = playerDataStore[player.UserId]
    if data then
        data.currency = data.currency + amount
        local remotes = ReplicatedStorage:FindFirstChild("Remotes")
        if remotes then
            remotes.DataChanged:FireClient(player, "currency", data.currency)
        end
    end
end

-- Increment combat wins
function PlayerData.incrementCombatWins(player)
    local data = playerDataStore[player.UserId]
    if data then
        data.combatWins = (data.combatWins or 0) + 1
        local remotes = ReplicatedStorage:FindFirstChild("Remotes")
        if remotes then
            remotes.DataChanged:FireClient(player, "combatWins", data.combatWins)
        end
        return data.combatWins
    end
    return 0
end

-- Update quest progress
function PlayerData.updateQuest(player, questId, progress)
    local data = playerDataStore[player.UserId]
    if data then
        for _, quest in ipairs(data.quests) do
            if quest.id == questId then
                quest.progress = math.min(progress, quest.target)
                local remotes = ReplicatedStorage:FindFirstChild("Remotes")
                if remotes then
                    remotes.DataChanged:FireClient(player, "quests", data.quests)
                end
                break
            end
        end
    end
end

-- Force save player data (call this after important changes)
function PlayerData.save(player)
    return savePlayerData(player)
end

-- Save all players data
function PlayerData.saveAll()
    for _, player in pairs(Players:GetPlayers()) do
        savePlayerData(player)
    end
end

return PlayerData
