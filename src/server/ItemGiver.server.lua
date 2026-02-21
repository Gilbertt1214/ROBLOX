--[[
    Item Giver System (Server-Side)
    Auto-gives items from WorldItems folder to player's backpack
]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

-- Track which items each player has received
local playerItems = {}

-- Ensure WorldItems folder exists
local function getWorldItemsFolder()
    local folder = Workspace:FindFirstChild("WorldItems")
    if not folder then
        folder = Instance.new("Folder")
        folder.Name = "WorldItems"
        folder.Parent = Workspace
    end
    return folder
end

-- Give a tool to a player's backpack
local function giveToolToPlayer(player, tool)
    if not player or not tool then return false end
    
    local backpack = player:FindFirstChild("Backpack")
    if not backpack then return false end
    
    if backpack:FindFirstChild(tool.Name) then
        return false
    end
    
    local character = player.Character
    if character and character:FindFirstChild(tool.Name) then
        return false
    end
    
    local toolClone = tool:Clone()
    
    if not toolClone:FindFirstChild("Handle") then
        local handle = toolClone:FindFirstChildWhichIsA("BasePart")
        if handle then
            handle.Name = "Handle"
        else
            toolClone:Destroy()
            return false
        end
    end
    
    toolClone.Enabled = true
    toolClone.CanBeDropped = true
    toolClone.ManualActivationOnly = false
    toolClone.Parent = backpack
    
    return true
end

-- Give all WorldItems to a player
local function giveAllItemsToPlayer(player)
    local folder = getWorldItemsFolder()
    
    if not playerItems[player.UserId] then
        playerItems[player.UserId] = {}
    end
    
    for _, item in pairs(folder:GetChildren()) do
        local toolToGive = nil
        local itemName = item.Name
        
        if item:IsA("Tool") then
            toolToGive = item
        elseif item:IsA("Model") then
            toolToGive = item:FindFirstChildWhichIsA("Tool")
            if toolToGive then
                itemName = toolToGive.Name
            end
        end
        
        if toolToGive and not playerItems[player.UserId][itemName] then
            local success = giveToolToPlayer(player, toolToGive)
            if success then
                playerItems[player.UserId][itemName] = true
            end
        end
    end
end

-- Remove item from player
local function removeItemFromPlayer(player, itemName)
    if not player then return end
    
    local backpack = player:FindFirstChild("Backpack")
    if backpack then
        local tool = backpack:FindFirstChild(itemName)
        if tool then
            tool:Destroy()
        end
    end
    
    local character = player.Character
    if character then
        local tool = character:FindFirstChild(itemName)
        if tool then
            tool:Destroy()
        end
    end
    
    if playerItems[player.UserId] then
        playerItems[player.UserId][itemName] = nil
    end
end

-- Setup WorldItems folder listeners
local function setupWorldItemsListeners()
    local folder = getWorldItemsFolder()
    
    folder.ChildAdded:Connect(function(item)
        task.wait(0.2)
        
        local toolToGive = nil
        local itemName = item.Name
        
        if item:IsA("Tool") then
            toolToGive = item
        elseif item:IsA("Model") or item:IsA("Folder") then
            toolToGive = item:FindFirstChildWhichIsA("Tool")
            if toolToGive then
                itemName = toolToGive.Name
            end
        end
        
        if toolToGive then
            for _, player in pairs(Players:GetPlayers()) do
                if not playerItems[player.UserId] then
                    playerItems[player.UserId] = {}
                end
                
                if not playerItems[player.UserId][itemName] then
                    local success = giveToolToPlayer(player, toolToGive)
                    if success then
                        playerItems[player.UserId][itemName] = true
                    end
                end
            end
        end
    end)
    
    folder.ChildRemoved:Connect(function(item)
        local itemName = item.Name
        
        if item:IsA("Tool") then
            itemName = item.Name
        elseif item:IsA("Model") or item:IsA("Folder") then
            itemName = item.Name
        end
        
        for _, player in pairs(Players:GetPlayers()) do
            removeItemFromPlayer(player, itemName)
        end
    end)
    
    folder.DescendantAdded:Connect(function(descendant)
        if descendant:IsA("Tool") then
            task.wait(0.2)
            
            for _, player in pairs(Players:GetPlayers()) do
                if not playerItems[player.UserId] then
                    playerItems[player.UserId] = {}
                end
                
                if not playerItems[player.UserId][descendant.Name] then
                    local success = giveToolToPlayer(player, descendant)
                    if success then
                        playerItems[player.UserId][descendant.Name] = true
                    end
                end
            end
        end
    end)
end

-- Player setup
local function onPlayerAdded(player)
    playerItems[player.UserId] = {}
    
    local function onCharacterAdded(character)
        task.wait(1)
        playerItems[player.UserId] = {}
        giveAllItemsToPlayer(player)
    end
    
    player.CharacterAdded:Connect(onCharacterAdded)
    
    if player.Character then
        onCharacterAdded(player.Character)
    end
end

local function onPlayerRemoving(player)
    playerItems[player.UserId] = nil
end

-- Initialize
setupWorldItemsListeners()

for _, player in pairs(Players:GetPlayers()) do
    task.spawn(onPlayerAdded, player)
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)
