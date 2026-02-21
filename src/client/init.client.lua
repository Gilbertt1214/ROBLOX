--[[
    UI Client Script
    Initializes and renders the game UI with custom backpack
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- Show loading screen IMMEDIATELY (before loading other modules)
local loadingHandle = nil
local function showLoadingScreen()
    local Shared = ReplicatedStorage:WaitForChild("Shared")
    local LoadingScreen = require(Shared:WaitForChild("Components"):WaitForChild("LoadingScreen"))
    local Roact = require(Shared:WaitForChild("Roact"))
    
    local loadingElement = LoadingScreen.create({
        onComplete = function()
            if loadingHandle then
                Roact.unmount(loadingHandle)
                loadingHandle = nil
            end
        end
    })
    loadingHandle = Roact.mount(loadingElement, PlayerGui, "LoadingScreen")
end

showLoadingScreen()

-- Wait for shared modules
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Roact = require(Shared:WaitForChild("Roact"))
local PlayerDataClient = require(Shared:WaitForChild("PlayerDataClient"))
local App = require(Shared:WaitForChild("Components"):WaitForChild("App"))
local DonateNotification = require(Shared:WaitForChild("Components"):WaitForChild("DonateNotification"))
local CustomBackpack = require(Shared:WaitForChild("Components"):WaitForChild("CustomBackpack"))
local LoadingScreen = require(Shared:WaitForChild("Components"):WaitForChild("LoadingScreen"))
local PlayerInteractMenu = require(Shared:WaitForChild("Components"):WaitForChild("PlayerInteractMenu"))
local CarryUI = require(Shared:WaitForChild("Components"):WaitForChild("CarryUI"))

-- Disable Roblox default GUIs
local function disableDefaultGuis()
    local success = false
    local attempts = 0
    while attempts < 15 do
        success = pcall(function()
            -- Disable PlayerList (Leaderboard) and other common elements
            StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)
            StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
            StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.EmotesMenu, false)
            -- Optional: StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Chat, false) -- Keep chat if wanted
        end)
        
     
        
        task.wait(0.5)
        attempts = attempts + 1
    end
end

task.spawn(disableDefaultGuis)

-- Distance settings
local OVERHEAD_MAX_DISTANCE = 50
local OVERHEAD_FADE_START = 35

-- Initialize PlayerDataClient
PlayerDataClient.init()

-- Hide default Roblox backpack
CustomBackpack.hideDefault()

-- Prevent auto-equip
local function preventAutoEquip()
    local character = LocalPlayer.Character
    if not character then return end
    
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid:UnequipTools()
    end
end

local function setupAutoEquipPrevention()
    local function onCharacterAdded(character)
        task.delay(0.1, function()
            preventAutoEquip()
        end)
        
        character.ChildAdded:Connect(function(child)
            if child:IsA("Tool") then
                local isInHotbar = CustomBackpack.isInHotbar(child.Name)
                if not isInHotbar then
                    task.defer(function()
                        local humanoid = character:FindFirstChildOfClass("Humanoid")
                        if humanoid then
                            humanoid:UnequipTools()
                        end
                    end)
                end
            end
        end)
    end
    
    if LocalPlayer.Character then
        onCharacterAdded(LocalPlayer.Character)
    end
    LocalPlayer.CharacterAdded:Connect(onCharacterAdded)
end

setupAutoEquipPrevention()

-- Create and mount the UI
local function initializeUI()
    local appElement = Roact.createElement(App, {})
    local handle = Roact.mount(appElement, PlayerGui, "GameUI")
    return handle
end

-- Listen for donation broadcasts
local function setupDonationListener()
    local remotes = ReplicatedStorage:WaitForChild("Remotes", 10)
    if remotes then
        local donationEvent = remotes:WaitForChild("DonationMade", 5)
        if donationEvent then
            donationEvent.OnClientEvent:Connect(function(playerName, productName, amount)
                DonateNotification.showDonation(playerName, productName, amount)
            end)
        end
    end
end

-- Initialize main UI in background to not block loading animations
local appHandle = initializeUI()

-- Setup donation listener
setupDonationListener()

-- Mount Player Interact Menu
pcall(function()
    PlayerInteractMenu.create()
end)

-- Mount Carry UI
pcall(function()
    CarryUI.create()
end)

-- Setup overhead distance-based visibility
local function setupOverheadDistanceVisibility()
    local function updateOverheadVisibility()
        local character = LocalPlayer.Character
        if not character then return end
        
        local hrp = character:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        
        local myPosition = hrp.Position
        
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character then
                local otherHRP = player.Character:FindFirstChild("HumanoidRootPart")
                local head = player.Character:FindFirstChild("Head")
                
                if otherHRP and head then
                    local distance = (myPosition - otherHRP.Position).Magnitude
                    local overhead = head:FindFirstChild("OverheadGui")
                    
                    if overhead then
                        if distance > OVERHEAD_MAX_DISTANCE then
                            overhead.Enabled = false
                        elseif distance > OVERHEAD_FADE_START then
                            overhead.Enabled = true
                            local fadeProgress = (distance - OVERHEAD_FADE_START) / (OVERHEAD_MAX_DISTANCE - OVERHEAD_FADE_START)
                            
                            for _, child in ipairs(overhead:GetDescendants()) do
                                if child:IsA("TextLabel") then
                                    child.TextTransparency = fadeProgress
                                    child.TextStrokeTransparency = 0.5 + (fadeProgress * 0.5)
                                elseif child:IsA("ImageLabel") then
                                    child.ImageTransparency = fadeProgress
                                end
                            end
                        else
                            overhead.Enabled = true
                            for _, child in ipairs(overhead:GetDescendants()) do
                                if child:IsA("TextLabel") then
                                    child.TextTransparency = 0
                                    if child.Name == "DisplayName" then
                                        child.TextStrokeTransparency = 0.3
                                    else
                                        child.TextStrokeTransparency = 0.5
                                    end
                                elseif child:IsA("ImageLabel") then
                                    child.ImageTransparency = 0
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    
    RunService.Heartbeat:Connect(function()
        if tick() % 0.2 < 0.016 then
            updateOverheadVisibility()
        end
    end)
end

setupOverheadDistanceVisibility()

-- Setup TAB hotkey for player list
local function setupPlayerListHotkey()
    local ACTION_NAME = "TogglePlayerList"
    
    -- Create Remotes folder if not exists
    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
    if not remotes then
        remotes = Instance.new("Folder")
        remotes.Name = "Remotes"
        remotes.Parent = ReplicatedStorage
    end
    
    -- Create TogglePlayerList event if not exists
    local toggleEvent = remotes:FindFirstChild("TogglePlayerList")
    if not toggleEvent then
        toggleEvent = Instance.new("BindableEvent")
        toggleEvent.Name = "TogglePlayerList"
        toggleEvent.Parent = remotes
        print("[Client] Created TogglePlayerList BindableEvent")
    end
    
    local function togglePlayerList()
        -- print("[Client] TAB pressed - firing TogglePlayerList")
        toggleEvent:Fire()
    end
    
    local function onKeyPressed(actionName, inputState, inputObject)
        if inputState == Enum.UserInputState.Begin then
            togglePlayerList()
        end
        return Enum.ContextActionResult.Sink
    end
    
    ContextActionService:BindActionAtPriority(
        ACTION_NAME,
        onKeyPressed,
        false,
        3000,
        Enum.KeyCode.Tab
    )
    
    -- print("[Client] TAB hotkey bound for player list")
end

setupPlayerListHotkey()

-- Setup OpenProfileView BindableEvent
local function setupProfileViewEvent()
    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
    if remotes then
        local openProfile = remotes:FindFirstChild("OpenProfileView")
        if not openProfile then
            openProfile = Instance.new("BindableEvent")
            openProfile.Name = "OpenProfileView"
            openProfile.Parent = remotes
        end
    end
end

setupProfileViewEvent()
