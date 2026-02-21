--[[
    App Component (Class-based)
    Manages global UI state, routing, and real-time player data
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local SocialService = game:GetService("SocialService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Roact = require(ReplicatedStorage.Shared.Roact)
local Theme = require(ReplicatedStorage.Shared.Theme)
local Icons = require(ReplicatedStorage.Shared.Icons)
local UIAnimations = require(ReplicatedStorage.Shared.UIAnimations)
local PlayerDataClient = require(ReplicatedStorage.Shared.PlayerDataClient)
local UISounds = require(ReplicatedStorage.Shared.UISounds)
local ResponsiveUtil = require(ReplicatedStorage.Shared.ResponsiveUtil)
local LoadingScreen = require(ReplicatedStorage.Shared.Components.LoadingScreen)

-- Components
local LeftSidebar = require(ReplicatedStorage.Shared.Components.LeftSidebar)
local TopRightStatus = require(ReplicatedStorage.Shared.Components.TopRightStatus)
local PlayerDropdown = require(ReplicatedStorage.Shared.Components.PlayerDropdown)
local CustomBackpack = require(ReplicatedStorage.Shared.Components.CustomBackpack)
local BackpackInventory = require(ReplicatedStorage.Shared.Components.BackpackInventory)

-- Views
local ShopView = require(ReplicatedStorage.Shared.Components.ShopView)
local MusicView = require(ReplicatedStorage.Shared.Components.MusicView)
local FriendsView = require(ReplicatedStorage.Shared.Components.FriendsView)
local StatsView = require(ReplicatedStorage.Shared.Components.StatsView)
local SettingsView = require(ReplicatedStorage.Shared.Components.SettingsView)
local NotificationView = require(ReplicatedStorage.Shared.Components.NotificationView)
local EmotesView = require(ReplicatedStorage.Shared.Components.EmotesView)
local DonateView = require(ReplicatedStorage.Shared.Components.DonateView)
local ProfileView = require(ReplicatedStorage.Shared.Components.ProfileView)

-- Animated View Wrapper Component
local AnimatedView = Roact.Component:extend("AnimatedView")

function AnimatedView:init()
    self.animated = false
end

function AnimatedView:didMount()
    self:runAnimation()
end

function AnimatedView:runAnimation()
    if self.animated then return end
    self.animated = true
    
    -- Get the wrapper frame from handle
    local wrapper = self._handle and self._handle.instance
    if not wrapper then return end
    
    -- Find the actual panel (first Frame child that's not a layout)
    task.defer(function()
        local panel = nil
        for _, child in pairs(wrapper:GetChildren()) do
            if child:IsA("Frame") then
                panel = child
                break
            end
        end
        
        if panel then
            UIAnimations.animatePanel(panel, self.props.animation or "popIn", 0.35)
        end
    end)
end

function AnimatedView:render()
    local child = self.props.child
    if not child then return nil end
    
    return Roact.createElement("Frame", {
        Name = "AnimatedViewWrapper",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1
    }, {
        Content = child
    })
end

local App = Roact.Component:extend("App")

-- Blur effect management (safe version)
local currentBlurState = false
local function setBlurEnabled(enabled)
    if currentBlurState == enabled then return end
    currentBlurState = enabled
    
    task.spawn(function()
        local Lighting = game:GetService("Lighting")
        local blurName = "UIBlur"
        local existingBlur = Lighting:FindFirstChild(blurName)
        
        if enabled then
            if not existingBlur then
                local blur = Instance.new("BlurEffect")
                blur.Name = blurName
                blur.Size = 0
                blur.Parent = Lighting
                existingBlur = blur
            end
            -- Animate blur in
            TweenService:Create(existingBlur, TweenInfo.new(0.2), { Size = 12 }):Play()
        else
            if existingBlur then
                -- Animate blur out then destroy
                local tween = TweenService:Create(existingBlur, TweenInfo.new(0.2), { Size = 0 })
                tween:Play()
                tween.Completed:Connect(function()
                    if existingBlur and existingBlur.Parent and existingBlur.Size == 0 then
                        existingBlur:Destroy()
                    end
                end)
            end
        end
    end)
end

function App:init()
    self.state = {
        activeTab = "none",
        dropdownOpen = false,
        notificationOpen = false,
        donateOpen = false,
        profileOpen = false, -- For ProfileView
        profilePlayer = nil, -- Player to show in ProfileView
        selectedPlayer = false, -- For PlayerDropdown popup (false = no selection)
        dropdownRefresh = 0, -- Trigger to refresh player data
        isLoading = true, -- Track loading state locally
        players = Players:GetPlayers(),
        friends = {},
        currency = 0,
        notifications = NotificationView.getNewCount(),
        -- Music state
        musicPlaying = false,
        currentTrack = 1,
        musicVolume = 0.5,
        musicTimePosition = 0,
        musicTimeLength = 0,
        -- Settings (with new privacy options)
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
            shadows = true,
            particles = true,
            bloom = true,
            sunRays = true,
            clouds = true
        }
    }
    
    -- Load settings from server
    self:loadSettingsFromServer()
    
    -- Fetch friends list
    self:fetchFriends()
    
    -- Music progress update connection (throttled to avoid performance issues)
    local RunService = game:GetService("RunService")
    local lastMusicUpdate = 0
    self.musicUpdateConn = RunService.Heartbeat:Connect(function()
        -- Update when music tab is active
        if self.state.activeTab == "music" then
            local now = tick()
            -- Update every 0.1 seconds (10 times per second)
            if now - lastMusicUpdate >= 0.1 then
                lastMusicUpdate = now
                local info = MusicView.getPlaybackInfo()
                -- Always update state when we have any info
                self:setState({
                    musicTimePosition = info.timePosition,
                    musicTimeLength = info.timeLength,
                    musicPlaying = info.isPlaying
                })
            end
        end
    end)
    
    -- Setup auto-play next track when current track ends
    MusicView.setOnTrackEnded(function(currentIndex)
        local playlist = MusicView.getPlaylist()
        local nextIndex = currentIndex + 1
        if nextIndex > #playlist then nextIndex = 1 end
        
        -- Find next valid track (skip tracks with id = 0)
        local attempts = 0
        while playlist[nextIndex] and playlist[nextIndex].id == "rbxassetid://0" and attempts < #playlist do
            nextIndex = nextIndex + 1
            if nextIndex > #playlist then nextIndex = 1 end
            attempts = attempts + 1
        end
        
        -- Update state and play next track
        self:setState({
            currentTrack = nextIndex,
            musicPlaying = true,
            musicTimePosition = 0,
            musicTimeLength = 0
        })
        MusicView.playTrack(nextIndex, self.state.musicVolume)
    end)
    
    -- Listen for player changes
    self.playerAddedConn = Players.PlayerAdded:Connect(function(player)
        self:setState({ players = Players:GetPlayers() })
    end)
    
    self.playerRemovedConn = Players.PlayerRemoving:Connect(function(player)
        task.defer(function()
            self:setState({ players = Players:GetPlayers() })
        end)
    end)
    
    -- Initial player list update
    task.spawn(function()
        task.wait(1)
        local currentPlayers = Players:GetPlayers()
        self:setState({ players = currentPlayers })
    end)
    
    -- Store reference for loading complete callback
    _G.OnLoadingComplete = function()
        self:setState({ isLoading = false })
    end
    
    -- Listen for TAB hotkey from BindableEvent
    task.spawn(function()
        -- Create Remotes folder if not exists
        local remotes = ReplicatedStorage:FindFirstChild("Remotes")
        if not remotes then
            remotes = Instance.new("Folder")
            remotes.Name = "Remotes"
            remotes.Parent = ReplicatedStorage
        end
        
        -- Create TogglePlayerList event if not exists
        local togglePlayerList = remotes:FindFirstChild("TogglePlayerList")
        if not togglePlayerList then
            togglePlayerList = Instance.new("BindableEvent")
            togglePlayerList.Name = "TogglePlayerList"
            togglePlayerList.Parent = remotes
        end
        
        -- print("[App] Listening for TogglePlayerList event")
        
        togglePlayerList.Event:Connect(function()
            -- print("[App] TogglePlayerList event received")
            if self.state.isLoading then return end
            
            self:setState(function(state)
                local isOpening = not state.dropdownOpen
                if isOpening then
                    UISounds.open()
                else
                    UISounds.close()
                end
                return {
                    dropdownOpen = not state.dropdownOpen,
                    selectedPlayer = nil,
                    dropdownRefresh = (state.dropdownRefresh or 0) + 1,
                    players = Players:GetPlayers(),
                    notificationOpen = false,
                    donateOpen = false,
                    activeTab = "none"
                }
            end)
        end)
        
        -- Listen for OpenProfileView event (from PlayerInteractMenu)
        local openProfile = remotes:FindFirstChild("OpenProfileView")
        if not openProfile then
            openProfile = Instance.new("BindableEvent")
            openProfile.Name = "OpenProfileView"
            openProfile.Parent = remotes
        end
        
        openProfile.Event:Connect(function(player)
            if self.state.isLoading then return end
            if not player then return end
            
            UISounds.open()
            self:setState({
                profileOpen = true,
                profilePlayer = player,
                dropdownOpen = false,
                selectedPlayer = nil,
                notificationOpen = false,
                donateOpen = false,
                activeTab = "none"
            })
        end)
    end)
end

function App:loadSettingsFromServer()
    task.spawn(function()
        local data = PlayerDataClient.getData()
        if data and data.settings then
            self:setState(function(state)
                local newSettings = {}
                for k, v in pairs(state.settings) do
                    newSettings[k] = v
                end
                for k, v in pairs(data.settings) do
                    newSettings[k] = v
                end
                return { settings = newSettings }
            end)
        end
    end)
end

function App:willUnmount()
    if self.playerAddedConn then self.playerAddedConn:Disconnect() end
    if self.playerRemovedConn then self.playerRemovedConn:Disconnect() end
    if self.musicUpdateConn then self.musicUpdateConn:Disconnect() end
    if self.tabHotkeyConn then self.tabHotkeyConn:Disconnect() end
end

function App:fetchFriends()
    task.spawn(function()
        local success, friends = pcall(function()
            local localPlayer = Players.LocalPlayer
            return localPlayer:GetFriendsOnline(50)
        end)
        
        if success and friends then
            self:setState({ friends = friends })
        else
            -- Fallback: try to get all friends
            local success2, allFriends = pcall(function()
                local localPlayer = Players.LocalPlayer
                local friendPages = localPlayer:GetFriendsAsync()
                local friendsList = {}
                
                while true do
                    for _, friend in ipairs(friendPages:GetCurrentPage()) do
                        table.insert(friendsList, {
                            Id = friend.Id,
                            Username = friend.Username,
                            DisplayName = friend.DisplayName or friend.Username,
                            IsOnline = friend.IsOnline or false
                        })
                    end
                    if friendPages.IsFinished then break end
                    friendPages:AdvanceToNextPageAsync()
                end
                
                return friendsList
            end)
            
            if success2 and allFriends then
                self:setState({ friends = allFriends })
            else
                warn("[App] Failed to fetch friends")
                self:setState({ friends = {} })
            end
        end
    end)
end

function App:render()
    local activeTab = self.state.activeTab
    
    -- Use local state for loading
    local isLoading = self.state.isLoading
    
    local statusActiveId = self.state.notificationOpen and "notification" or (self.state.donateOpen and "donate" or (self.state.dropdownOpen and "profile" or nil))
    -- print("[App] Render activeId:", statusActiveId)
    
    -- Check if any panel is open
    local hasOpenPanel = activeTab ~= "none" or self.state.dropdownOpen or self.state.notificationOpen or self.state.donateOpen or self.state.profileOpen
    setBlurEnabled(hasOpenPanel and not isLoading)
    
    local sidebarItems = {
        { id = "inventory", tooltip = "Inventory" },
        { id = "shop", tooltip = "Shop" },
        { id = "music", tooltip = "Music" },
        { id = "friends", tooltip = "Friends" },
        { id = "emotes", tooltip = "Emotes" },
        { id = "settings", tooltip = "Settings" },
    }

    local statusIcons = {
        { id = "notification", value = self.state.notifications },
        { id = "donate" },
        { id = "profile" },
    }

    -- Determine which view to show with real data
    local currentView = nil
    if activeTab == "inventory" then
        -- Use new BackpackInventory that syncs with Roblox Backpack
        currentView = BackpackInventory.create()
    elseif activeTab == "shop" then
        currentView = ShopView.create()
    elseif activeTab == "music" then
        currentView = MusicView.create({
            currentTrack = self.state.currentTrack,
            isPlaying = self.state.musicPlaying,
            volume = self.state.musicVolume,
            timePosition = self.state.musicTimePosition,
            timeLength = self.state.musicTimeLength,
            onPlay = function()
                self:setState({ musicPlaying = true })
                MusicView.playTrack(self.state.currentTrack, self.state.musicVolume)
            end,
            onPause = function()
                self:setState({ musicPlaying = false })
                MusicView.stopMusic()
            end,
            onNext = function()
                self:setState(function(state)
                    local playlist = MusicView.getPlaylist()
                    local next = state.currentTrack + 1
                    if next > #playlist then next = 1 end
                    -- Play next track if currently playing
                    if state.musicPlaying then
                        MusicView.playTrack(next, state.musicVolume)
                    end
                    return { currentTrack = next, musicTimePosition = 0, musicTimeLength = 0 }
                end)
            end,
            onPrev = function()
                self:setState(function(state)
                    local playlist = MusicView.getPlaylist()
                    local prev = state.currentTrack - 1
                    if prev < 1 then prev = #playlist end
                    -- Play prev track if currently playing
                    if state.musicPlaying then
                        MusicView.playTrack(prev, state.musicVolume)
                    end
                    return { currentTrack = prev, musicTimePosition = 0, musicTimeLength = 0 }
                end)
            end,
            onSelectTrack = function(index)
                self:setState({ currentTrack = index, musicPlaying = true, musicTimePosition = 0, musicTimeLength = 0 })
                MusicView.playTrack(index, self.state.musicVolume)
            end,
            onVolumeChange = function(vol)
                self:setState({ musicVolume = vol })
                MusicView.setVolume(vol)
            end,
            onSeek = function(time)
                MusicView.seekTo(time)
                self:setState({ musicTimePosition = time })
            end
        })
    elseif activeTab == "friends" then
        currentView = FriendsView.create({ friends = self.state.friends or {} })
    elseif activeTab == "emotes" then
        currentView = EmotesView.create()
    elseif activeTab == "settings" then
        currentView = SettingsView.create({
            settings = self.state.settings,
            onSettingChanged = function(key, val)
                -- Update locally
                self:setState(function(state)
                    local newSettings = {}
                    for k, v in pairs(state.settings) do newSettings[k] = v end
                    newSettings[key] = val
                    return { settings = newSettings }
                end)
                -- Sync to server
                PlayerDataClient.updateSetting(key, val)
            end
        })
    end

    return Roact.createElement("ScreenGui", {
        Name = "GameUI",
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        IgnoreGuiInset = true
    }, {
        -- UIScale for auto-scaling based on screen size
        AutoScale = Roact.createElement("UIScale", {
            Scale = ResponsiveUtil.getUIScaleValue(0.6, 1.25)
        }),
        
        -- Hide all UI during loading
        Sidebar = not isLoading and LeftSidebar.create({
            items = sidebarItems,
            activeId = activeTab,
            onItemClick = function(id)
                -- Friends button opens Roblox invite popup directly
                if id == "friends" then
                    UISounds.click()
                    pcall(function()
                        SocialService:PromptGameInvite(Players.LocalPlayer)
                    end)
                    return
                end
                
                self:setState(function(state)
                    local isOpening = state.activeTab ~= id
                    if isOpening then
                        UISounds.open()
                    else
                        UISounds.close()
                    end
                    return { 
                        activeTab = (state.activeTab == id) and "none" or id,
                        dropdownOpen = false,
                        notificationOpen = false
                    }
                end)
            end
        }) or nil,
        
        StatusBar = not isLoading and TopRightStatus.create({
            currency = self.state.currency,
            icons = statusIcons,
            activeId = statusActiveId,
            onIconClick = function(id)
                if id == "notification" then
                    self:setState(function(state)
                        local isOpening = not state.notificationOpen
                        if isOpening then
                            UISounds.open()
                        else
                            UISounds.close()
                        end
                        return { 
                            notificationOpen = not state.notificationOpen,
                            dropdownOpen = false,
                            donateOpen = false,
                            activeTab = "none"
                        }
                    end)
                elseif id == "donate" then
                    self:setState(function(state)
                        local isOpening = not state.donateOpen
                        if isOpening then
                            UISounds.open()
                        else
                            UISounds.close()
                        end
                        return { 
                            donateOpen = not state.donateOpen,
                            dropdownOpen = false,
                            notificationOpen = false,
                            activeTab = "none"
                        }
                    end)
                elseif id == "profile" then
                    self:setState(function(state)
                        local isOpening = not state.dropdownOpen
                        if isOpening then
                            UISounds.open()
                        else
                            UISounds.close()
                        end
                        return { 
                            dropdownOpen = not state.dropdownOpen,
                            selectedPlayer = nil,
                            dropdownRefresh = (state.dropdownRefresh or 0) + 1,
                            players = Players:GetPlayers(),
                            notificationOpen = false,
                            donateOpen = false,
                            profileOpen = false
                        }
                    end)
                end
            end
        }) or nil,
        
        PlayerList = not isLoading and self.state.dropdownOpen and Roact.createElement(AnimatedView, {
            animation = "slideDown",
            child = PlayerDropdown.create({
                players = self.state.players,
                selectedPlayer = self.state.selectedPlayer,
                refreshTrigger = self.state.dropdownRefresh or 0,
                onSelectPlayer = function(player)
                    local currentUserId = self.state.selectedPlayer and self.state.selectedPlayer.UserId
                    local newUserId = player.UserId
                    
                    if currentUserId == newUserId then
                        self:setState({ selectedPlayer = false })
                    else
                        self:setState({ selectedPlayer = player })
                    end
                end,
                onClosePopup = function()
                    -- Use false to clear selection
                    self:setState({ selectedPlayer = false })
                end,
                onViewProfile = function(player)
                    self:setState({
                        profileOpen = true,
                        profilePlayer = player,
                        dropdownOpen = false,
                        selectedPlayer = nil
                    })
                end
            })
        }) or nil,
        
        -- Profile View
        ProfilePanel = not isLoading and self.state.profileOpen and self.state.profilePlayer and Roact.createElement(AnimatedView, {
            animation = "popIn",
            child = ProfileView.create({
                player = self.state.profilePlayer,
                onClose = function()
                    self:setState({ profileOpen = false, profilePlayer = nil })
                end
            })
        }) or nil,
        
        NotificationPanel = not isLoading and self.state.notificationOpen and Roact.createElement(AnimatedView, {
            animation = "slideDown",
            child = NotificationView.create({
                onClose = function()
                    self:setState({ notificationOpen = false, notifications = 0 })
                end
            })
        }) or nil,
        
        DonatePanel = not isLoading and self.state.donateOpen and Roact.createElement(AnimatedView, {
            animation = "slideDown",
            child = DonateView.create({
                onClose = function()
                    self:setState({ donateOpen = false })
                end
            })
        }) or nil,
        
        -- Use dynamic key to force re-mount on tab change
        ["MainView_" .. activeTab] = not isLoading and currentView and Roact.createElement(AnimatedView, {
            animation = "popIn",
            child = currentView
        }) or nil,
        
        -- Custom Backpack/Hotbar at bottom - syncs with Roblox Backpack
        Backpack = not isLoading and CustomBackpack.create() or nil
    })
end

return App
