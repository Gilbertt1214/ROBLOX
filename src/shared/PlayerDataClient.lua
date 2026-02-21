--[[
    PlayerDataClient Module
    Client-side wrapper for fetching and listening to player data changes
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local PlayerDataClient = {}
PlayerDataClient.__index = PlayerDataClient

local cachedData = nil
local listeners = {}

function PlayerDataClient.init()
    local remotes = ReplicatedStorage:WaitForChild("Remotes", 10)
    if not remotes then
        -- warn("[PlayerDataClient] Remotes folder not found!")
        return
    end
    
    -- Fetch initial data
    local getDataRemote = remotes:WaitForChild("GetPlayerData", 5)
    if getDataRemote then
        cachedData = getDataRemote:InvokeServer()
        -- print("[PlayerDataClient] Initial data loaded")
    end
    
    -- Listen for data changes
    local dataChangedEvent = remotes:WaitForChild("DataChanged", 5)
    if dataChangedEvent then
        dataChangedEvent.OnClientEvent:Connect(function(key, value)
            if cachedData then
                cachedData[key] = value
            end
            -- Notify listeners
            for _, listener in ipairs(listeners) do
                listener(key, value)
            end
        end)
    end
end

function PlayerDataClient.get()
    return cachedData
end

function PlayerDataClient.getData()
    return cachedData
end

function PlayerDataClient.getCurrency()
    return cachedData and cachedData.currency or 0
end

function PlayerDataClient.getInventory()
    return cachedData and cachedData.inventory or {}
end

function PlayerDataClient.getStats()
    if not cachedData then return {} end
    return {
        level = cachedData.level,
        xp = cachedData.xp,
        xpMax = cachedData.xpMax,
        kills = cachedData.kills,
        deaths = cachedData.deaths,
        playtime = cachedData.playtime
    }
end

function PlayerDataClient.getQuests()
    return cachedData and cachedData.quests or {}
end

function PlayerDataClient.getSettings()
    return cachedData and cachedData.settings or {}
end

function PlayerDataClient.updateSetting(key, value)
    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
    if remotes then
        local remote = remotes:FindFirstChild("UpdateSettings")
        if remote then
            remote:InvokeServer(key, value)
        end
    end
end

function PlayerDataClient.equipItem(itemIndex)
    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
    if remotes then
        local remote = remotes:FindFirstChild("EquipItem")
        if remote then
            return remote:InvokeServer(itemIndex)
        end
    end
    return false
end

function PlayerDataClient.unequipItem(itemIndex)
    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
    if remotes then
        local remote = remotes:FindFirstChild("UnequipItem")
        if remote then
            return remote:InvokeServer(itemIndex)
        end
    end
    return false
end

function PlayerDataClient.getHotbar()
    return cachedData and cachedData.hotbar or {}
end

function PlayerDataClient.getHotbarSlotCount()
    return cachedData and cachedData.hotbarSlotCount or 3
end

function PlayerDataClient.selectHotbarSlot(slotIndex)
    -- print("[PlayerDataClient] Selecting hotbar slot:", slotIndex)
    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
    if remotes then
        local remote = remotes:FindFirstChild("SelectHotbarSlot")
        if remote then
            local result = remote:InvokeServer(slotIndex)
            -- print("[PlayerDataClient] Server returned:", result)
            return result
        else
            -- warn("[PlayerDataClient] SelectHotbarSlot remote not found!")
        end
    else
        -- warn("[PlayerDataClient] Remotes folder not found!")
    end
    return false
end

function PlayerDataClient.useItem(slotIndex)
    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
    if remotes then
        local remote = remotes:FindFirstChild("UseItem")
        if remote then
            return remote:InvokeServer(slotIndex)
        end
    end
    return false
end

function PlayerDataClient.onDataChanged(callback)
    table.insert(listeners, callback)
end

return PlayerDataClient
