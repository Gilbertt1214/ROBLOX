--[[
    Item Pickup System (Client-Side)
    DISABLED - Now handled by server/ItemGiver.server.lua
    
    Items are now given from server-side so they are visible to all players.
    This client script is disabled to prevent conflicts.
]]

-- DISABLED: Server-side ItemGiver now handles this
do return end

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer

print("[ItemPickup] Initializing auto-item system...")

-- Track which items we've already given
local givenItems = {}

-- Add tool to player's Roblox Backpack
local function giveToolToBackpack(tool)
    if not LocalPlayer.Backpack then return false end
    
    -- Check if player already has this tool
    if LocalPlayer.Backpack:FindFirstChild(tool.Name) then
        return false
    end
    
    -- Also check character (equipped)
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild(tool.Name) then
        return false
    end
    
    -- Clone the tool and add to backpack
    local toolClone = tool:Clone()
    
    -- Ensure tool has proper properties
    if not toolClone:FindFirstChild("Handle") then
        warn("[ItemPickup] Tool missing Handle:", tool.Name)
        -- Try to find any BasePart to use as Handle
        local handle = toolClone:FindFirstChildWhichIsA("BasePart")
        if handle then
            handle.Name = "Handle"
        else
            warn("[ItemPickup] Cannot create Handle for:", tool.Name)
            toolClone:Destroy()
            return false
        end
    end
    
    -- Make sure tool is enabled
    toolClone.Enabled = true
    toolClone.CanBeDropped = true
    toolClone.ManualActivationOnly = false
    
    -- Parent to backpack
    toolClone.Parent = LocalPlayer.Backpack
    
    print("[ItemPickup] Auto-gave item:", tool.Name)
    return true
end

-- Give all items from WorldItems folder
local function giveAllWorldItems()
    local folder = Workspace:FindFirstChild("WorldItems")
    if not folder then
        print("[ItemPickup] WorldItems folder not found, creating...")
        folder = Instance.new("Folder")
        folder.Name = "WorldItems"
        folder.Parent = Workspace
    end
    
    for _, item in pairs(folder:GetChildren()) do
        if item:IsA("Tool") and not givenItems[item.Name] then
            local success = giveToolToBackpack(item)
            if success then
                givenItems[item.Name] = true
            end
        elseif item:IsA("Model") then
            local toolInModel = item:FindFirstChildWhichIsA("Tool")
            if toolInModel and not givenItems[toolInModel.Name] then
                local success = giveToolToBackpack(toolInModel)
                if success then
                    givenItems[toolInModel.Name] = true
                end
            end
        end
    end
end

-- Setup WorldItems folder listener
local function setupWorldItemsFolder()
    local folder = Workspace:FindFirstChild("WorldItems")
    if not folder then
        folder = Instance.new("Folder")
        folder.Name = "WorldItems"
        folder.Parent = Workspace
    end
    
    -- Give existing items
    giveAllWorldItems()
    
    -- Listen for new items added to WorldItems
    folder.ChildAdded:Connect(function(item)
        task.wait(0.1) -- Small delay to ensure item is fully loaded
        
        if item:IsA("Tool") and not givenItems[item.Name] then
            local success = giveToolToBackpack(item)
            if success then
                givenItems[item.Name] = true
                
                -- Show notification
                local pickupSound = Instance.new("Sound")
                pickupSound.SoundId = "rbxasset://sounds/electronicpingshort.wav"
                pickupSound.Volume = 0.5
                pickupSound.Parent = LocalPlayer.PlayerGui
                pickupSound:Play()
                pickupSound.Ended:Connect(function()
                    pickupSound:Destroy()
                end)
            end
        elseif item:IsA("Model") then
            local toolInModel = item:FindFirstChildWhichIsA("Tool")
            if toolInModel and not givenItems[toolInModel.Name] then
                local success = giveToolToBackpack(toolInModel)
                if success then
                    givenItems[toolInModel.Name] = true
                    
                    -- Show notification
                    local pickupSound = Instance.new("Sound")
                    pickupSound.SoundId = "rbxasset://sounds/electronicpingshort.wav"
                    pickupSound.Volume = 0.5
                    pickupSound.Parent = LocalPlayer.PlayerGui
                    pickupSound:Play()
                    pickupSound.Ended:Connect(function()
                        pickupSound:Destroy()
                    end)
                end
            end
        end
    end)
    
    -- Listen for items removed from WorldItems (optional: remove from backpack)
    folder.ChildRemoved:Connect(function(item)
        local itemName = item.Name
        if item:IsA("Model") then
            local toolInModel = item:FindFirstChildWhichIsA("Tool")
            if toolInModel then
                itemName = toolInModel.Name
            end
        end
        
        -- Remove from tracking
        givenItems[itemName] = nil
        
        -- Optionally remove from backpack
        if LocalPlayer.Backpack then
            local toolInBackpack = LocalPlayer.Backpack:FindFirstChild(itemName)
            if toolInBackpack then
                toolInBackpack:Destroy()
                print("[ItemPickup] Removed item from backpack:", itemName)
            end
        end
        
        -- Also check character
        if LocalPlayer.Character then
            local toolInCharacter = LocalPlayer.Character:FindFirstChild(itemName)
            if toolInCharacter then
                toolInCharacter:Destroy()
            end
        end
    end)
    
    return folder
end

-- Wait for character and give items
local function onCharacterAdded(character)
    task.wait(1) -- Wait for backpack to be ready
    
    -- Re-give all items when character respawns
    givenItems = {} -- Reset tracking
    giveAllWorldItems()
end

-- Setup character listener
if LocalPlayer.Character then
    onCharacterAdded(LocalPlayer.Character)
end

LocalPlayer.CharacterAdded:Connect(onCharacterAdded)

-- Initialize
setupWorldItemsFolder()

print("[ItemPickup] Auto-item system ready!")
print("[ItemPickup] Items in WorldItems folder will automatically be given to all players")
print("[ItemPickup] Add new items to WorldItems folder and they will appear in backpack automatically")

