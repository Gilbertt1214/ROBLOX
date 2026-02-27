--[[
    MusicView Component
    Music player UI with playlist, controls, and visualizer
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Roact = require(ReplicatedStorage.Shared.Roact)
local Theme = require(ReplicatedStorage.Shared.Theme)
local Icons = require(ReplicatedStorage.Shared.Icons)
local ResponsiveUtil = require(ReplicatedStorage.Shared.ResponsiveUtil)

local MusicView = {}

-- Current playing sound reference
local currentSound = nil
local currentTrackIndex = 1
local onTrackEndedCallback = nil

-- Set callback for when track ends (for auto-play next)
function MusicView.setOnTrackEnded(callback)
    onTrackEndedCallback = callback
end

-- Get current track index
function MusicView.getCurrentTrackIndex()
    return currentTrackIndex
end

-- Format time (seconds to MM:SS)
local function formatTime(seconds)
    if not seconds or seconds ~= seconds then return "0:00" end
    local mins = math.floor(seconds / 60)
    local secs = math.floor(seconds % 60)
    return string.format("%d:%02d", mins, secs)
end

-- Get current playback info
function MusicView.getPlaybackInfo()
    -- Make sure we have the current sound reference
    local player = Players.LocalPlayer
    if player then
        local playerGui = player:FindFirstChild("PlayerGui")
        if playerGui then
            local sound = playerGui:FindFirstChild("MusicPlayerSound")
            if sound and sound:IsA("Sound") then
                currentSound = sound
                local info = {
                    timePosition = sound.TimePosition or 0,
                    timeLength = sound.TimeLength or 0,
                    isPlaying = sound.IsPlaying or sound.Playing
                }
                return info
            end
        end
    end
    return { timePosition = 0, timeLength = 0, isPlaying = false }
end

-- Seek to position
function MusicView.seekTo(position)
    local sound = currentSound
    if sound and sound:IsA("Sound") and sound.TimeLength > 0 then
        sound.TimePosition = math.clamp(position, 0, sound.TimeLength)
    end
end

--[[
    PLAYLIST - Edit your songs here!
    Format: { id = "rbxassetid://SOUND_ID", title = "Song Name", artist = "Artist Name" }
]]
local Playlist = {
    { id = "rbxassetid://91687115034068", title = "Ngapain repot", artist = "Unknow" },
    { id = "rbxassetid://99108133872447", title = "Nikah kapan", artist = "Unknow" },
    { id = "rbxassetid://117876050823385", title = "Lucky (Jason Mraz ft. Colbie Caillat)", artist = "Cover by Arthur Miguel" },
      { id = "rbxassetid://109372606200579", title = "SEJATUH JATUHNYA ", artist = "ANNETH" },
    { id = "rbxassetid://132505088537732", title = "Gelora asmara", artist = "Chrisye" },
    { id = "rbxassetid://97165813231210", title = "Secukupnya", artist = "Hindia" },
    { id = "rbxassetid://105321285923749", title = "Everything u are", artist = "Hindia" },
    { id = "rbxassetid://139918915803262", title = "Multo", artist = "Cup of joe" },
     { id = "rbxassetid://122847240547275", title = "More Than Just A Friend", artist = "Ruth Garcia"},
       { id = "rbxassetid://88503824524164", title = "Lepaskan Diriku", artist = "Jrock"},
     { id = "rbxassetid://96748964400139", title = "Introvert", artist = "SHA"},
    { id = "rbxassetid://124235353672143", title = "Langit tak seharusnya biru", artist ="The jansen"},
     { id = "rbxassetid://124235353672143", title = "Its Only Me", artist ="Kaleb J"},
      { id = "rbxassetid://98142706604637", title = "Kita Lawan Mereka", artist ="SHA"},
       { id = "rbxassetid://95448262774903", title = "Lebih Indah", artist ="Adera"},
        { id = "rbxassetid://118970699459895", title = "GENIT ", artist ="Tipe X"},
          { id = "rbxassetid://118544070738828", title = "KAMU NGGA SENDIRIAN ", artist ="Tipe X"},
           { id = "rbxassetid://86424835789311", title = "Sedia aku sebelum hujan", artist ="Idgitaf"},
            { id = "rbxassetid://73122152208489", title = "Missing You", artist ="Cover by Baila Fauri and Acel"},
            { id = "rbxassetid://122095487407036", title = "kota ini tak sama tanpamu", artist ="Nadhif Basalamah"},
            { id = "rbxassetid://120218066951257", title = " Where Do Broken Hearts Go ", artist =" Soundrift "},
       
}

-- Get or create the music sound object
local function getMusicSound()
    local player = Players.LocalPlayer
    if not player then return nil end
    
    local playerGui = player:FindFirstChild("PlayerGui")
    if not playerGui then return nil end
    
    local sound = playerGui:FindFirstChild("MusicPlayerSound")
    if not sound then
        sound = Instance.new("Sound")
        sound.Name = "MusicPlayerSound"
        sound.Parent = playerGui
        sound.Looped = false
    end
    
    currentSound = sound
    return sound
end

-- Play a track
function MusicView.playTrack(trackIndex, volume)
    local track = Playlist[trackIndex]
    if not track or track.id == "rbxassetid://0" then
        warn("[MusicView] Invalid track or no sound ID set for track " .. trackIndex)
        return
    end
    
    local sound = getMusicSound()
    if sound then
        -- Store current track index
        currentTrackIndex = trackIndex
        
        -- Disconnect previous Ended connection if exists
        if sound:GetAttribute("EndedConnection") then
            local conn = sound:FindFirstChild("EndedConnectionMarker")
            if conn then conn:Destroy() end
        end
        
        sound.SoundId = track.id
        sound.Volume = volume or 0.5
        
        -- Play immediately, TimeLength will be available after loading
        task.spawn(function()
            if not sound.IsLoaded then
                local startTime = tick()
                repeat
                    task.wait(0.1)
                until sound.IsLoaded or (tick() - startTime > 15)
            end
            
            if sound.IsLoaded then
                sound:Play()
                -- print("[MusicView] Playing track:", track.title, "Length:", sound.TimeLength)
                
                -- Setup auto-play next when track ends
                local endedConn
                endedConn = sound.Ended:Connect(function()
                    endedConn:Disconnect()
                    -- print("[MusicView] Track ended:", track.title)
                    
                    -- Call the callback to play next track
                    if onTrackEndedCallback then
                        task.defer(function()
                            onTrackEndedCallback(currentTrackIndex)
                        end)
                    end
                end)
            else
                warn("[MusicView] Sound failed to load:", track.title, "ID:", track.id)
            end
        end)
    end
end

-- Stop music
function MusicView.stopMusic()
    local sound = getMusicSound()
    if sound then
        sound:Stop()
    end
end

-- Set volume
function MusicView.setVolume(volume)
    local sound = getMusicSound()
    if sound then
        sound.Volume = math.clamp(volume, 0, 1)
    end
end

-- Get playlist
function MusicView.getPlaylist()
    return Playlist
end

local function createTrackItem(props)
    local track = props.track
    local index = props.index
    local isPlaying = props.isPlaying
    local onSelect = props.onSelect
    local itemHeight = props.itemHeight or 50
    local isPhone = props.isPhone or false
    
    return Roact.createElement("TextButton", {
        Size = UDim2.new(1, 0, 0, itemHeight),
        BackgroundColor3 = isPlaying and Theme.Primary or Theme.BackgroundLight,
        BackgroundTransparency = isPlaying and 0.3 or 0.7,
        Text = "",
        AutoButtonColor = false,
        LayoutOrder = index,
        Event = {
            MouseButton1Click = function()
                if onSelect then onSelect(index) end
            end,
            MouseEnter = function(rbx)
                if not isPlaying then
                    TweenService:Create(rbx, TweenInfo.new(0.15), {
                        BackgroundTransparency = 0.4,
                        BackgroundColor3 = Theme.BackgroundCard
                    }):Play()
                end
            end,
            MouseLeave = function(rbx)
                if not isPlaying then
                    TweenService:Create(rbx, TweenInfo.new(0.15), {
                        BackgroundTransparency = 0.7,
                        BackgroundColor3 = Theme.BackgroundLight
                    }):Play()
                end
            end
        }
    }, {
        Corner = Roact.createElement("UICorner", { CornerRadius = UDim.new(0, 8) }),
        
        TrackNumber = Roact.createElement("TextLabel", {
            Size = UDim2.new(0, isPhone and 24 or 30, 1, 0),
            Position = UDim2.new(0, isPhone and 6 or 10, 0, 0),
            BackgroundTransparency = 1,
            Text = isPlaying and ">" or tostring(index),
            TextColor3 = isPlaying and Theme.Primary or Theme.TextMuted,
            TextSize = isPhone and 12 or 14,
            Font = Theme.FontBold
        }),
        
        TrackInfo = Roact.createElement("Frame", {
            Size = UDim2.new(1, isPhone and -35 or -50, 1, 0),
            Position = UDim2.new(0, isPhone and 32 or 45, 0, 0),
            BackgroundTransparency = 1
        }, {
            Title = Roact.createElement("TextLabel", {
                Size = UDim2.new(1, 0, 0.5, 0),
                Position = UDim2.new(0, 0, 0, isPhone and 4 or 5),
                BackgroundTransparency = 1,
                Text = track.title,
                TextColor3 = Theme.TextPrimary,
                TextSize = isPhone and 11 or 13,
                Font = Theme.FontMedium,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextTruncate = Enum.TextTruncate.AtEnd
            }),
            Artist = Roact.createElement("TextLabel", {
                Size = UDim2.new(1, 0, 0.5, 0),
                Position = UDim2.new(0, 0, 0.5, isPhone and -4 or -5),
                BackgroundTransparency = 1,
                Text = track.artist,
                TextColor3 = Theme.TextMuted,
                TextSize = isPhone and 9 or 11,
                Font = Theme.FontRegular,
                TextXAlignment = Enum.TextXAlignment.Left
            })
        })
    })
end

local function createControlButton(props)
    local icon = props.icon
    local imageId = props.iconName and Icons.Get(props.iconName) or nil
    
    local children = {
        Corner = Roact.createElement("UICorner", { CornerRadius = UDim.new(1, 0) })
    }
    
    if props.iconName and imageId and not Icons.IsTextIcon(props.iconName) then
        children.Icon = Roact.createElement("ImageLabel", {
            Size = UDim2.new(0, 20, 0, 20),
            Position = UDim2.new(0.5, 0, 0.5, 0),
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundTransparency = 1,
            Image = imageId,
            ImageColor3 = Theme.TextPrimary,
            ScaleType = Enum.ScaleType.Fit
        })
    end
    
    return Roact.createElement("TextButton", {
        Size = props.size or UDim2.new(0, 40, 0, 40),
        BackgroundColor3 = props.primary and Theme.Primary or Theme.BackgroundCard,
        BackgroundTransparency = props.primary and 0 or 0.5,
        Text = (props.iconName and not Icons.IsTextIcon(props.iconName)) and "" or icon,
        TextColor3 = Theme.TextPrimary,
        TextSize = props.textSize or 18,
        Font = Theme.FontBold,
        Event = {
            MouseButton1Click = props.onClick or function() end,
            MouseEnter = function(rbx)
                TweenService:Create(rbx, TweenInfo.new(0.1), {
                    Size = UDim2.new(0, (props.size and props.size.X.Offset or 40) + 4, 0, (props.size and props.size.Y.Offset or 40) + 4)
                }):Play()
            end,
            MouseLeave = function(rbx)
                TweenService:Create(rbx, TweenInfo.new(0.1), {
                    Size = props.size or UDim2.new(0, 40, 0, 40)
                }):Play()
            end
        }
    }, children)
end

-- Progress bar component
local function createProgressBar(props)
    local timePosition = props.timePosition or 0
    local timeLength = props.timeLength or 0
    local onSeek = props.onSeek
    local isPhone = props.isPhone
    
    local progress = timeLength > 0 and (timePosition / timeLength) or 0
    
    return Roact.createElement("Frame", {
        Size = UDim2.new(1, 0, 0, isPhone and 28 or 32),
        BackgroundTransparency = 1
    }, {
        TimeLeft = Roact.createElement("TextLabel", {
            Size = UDim2.new(0, isPhone and 32 or 38, 1, 0),
            Position = UDim2.new(0, 0, 0, 0),
            BackgroundTransparency = 1,
            Text = formatTime(timePosition),
            TextColor3 = Theme.TextMuted,
            TextSize = isPhone and 10 or 11,
            Font = Theme.FontMedium,
            TextXAlignment = Enum.TextXAlignment.Left
        }),
        
        ProgressBg = Roact.createElement("TextButton", {
            Size = UDim2.new(1, isPhone and -70 or -84, 0, isPhone and 6 or 8),
            Position = UDim2.new(0.5, 0, 0.5, 0),
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundColor3 = Theme.BackgroundCard,
            Text = "",
            AutoButtonColor = false,
            Event = {
                MouseButton1Click = function(rbx)
                    if timeLength > 0 and onSeek then
                        local UserInputService = game:GetService("UserInputService")
                        local mousePos = UserInputService:GetMouseLocation()
                        local relativeX = mousePos.X - rbx.AbsolutePosition.X
                        local seekProgress = math.clamp(relativeX / rbx.AbsoluteSize.X, 0, 1)
                        local seekTime = seekProgress * timeLength
                        onSeek(seekTime)
                    end
                end
            }
        }, {
            Corner = Roact.createElement("UICorner", { CornerRadius = UDim.new(1, 0) }),
            Fill = Roact.createElement("Frame", {
                Size = UDim2.new(progress, 0, 1, 0),
                BackgroundColor3 = Theme.Primary
            }, {
                Corner = Roact.createElement("UICorner", { CornerRadius = UDim.new(1, 0) }),
                Knob = Roact.createElement("Frame", {
                    Size = UDim2.new(0, isPhone and 10 or 12, 0, isPhone and 10 or 12),
                    Position = UDim2.new(1, 0, 0.5, 0),
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    BackgroundColor3 = Theme.TextPrimary
                }, {
                    Corner = Roact.createElement("UICorner", { CornerRadius = UDim.new(1, 0) })
                })
            })
        }),
        
        TimeRight = Roact.createElement("TextLabel", {
            Size = UDim2.new(0, isPhone and 32 or 38, 1, 0),
            Position = UDim2.new(1, 0, 0, 0),
            AnchorPoint = Vector2.new(1, 0),
            BackgroundTransparency = 1,
            Text = formatTime(timeLength),
            TextColor3 = Theme.TextMuted,
            TextSize = isPhone and 10 or 11,
            Font = Theme.FontMedium,
            TextXAlignment = Enum.TextXAlignment.Right
        })
    })
end

function MusicView.create(props)
    props = props or {}
    local currentTrack = props.currentTrack or 1
    local isPlaying = props.isPlaying or false
    local volume = props.volume or 0.5
    local onPlay = props.onPlay
    local onPause = props.onPause
    local onNext = props.onNext
    local onPrev = props.onPrev
    local onSelectTrack = props.onSelectTrack
    local onVolumeChange = props.onVolumeChange
    
    local track = Playlist[currentTrack] or Playlist[1]
    
    local sizes = ResponsiveUtil.getSizes()
    local isPhone = ResponsiveUtil.isPhone()
    local isMobile = ResponsiveUtil.isMobile()
    
    -- Responsive sizes - smaller to avoid hotbar collision
    local panelWidth = isPhone and 260 or (isMobile and 300 or 340)
    local panelHeight = isPhone and 300 or (isMobile and 360 or 400)
    local headerHeight = isPhone and 65 or 85
    local controlsHeight = isPhone and 42 or 52
    local volumeHeight = isPhone and 20 or 24
    local trackItemHeight = isPhone and 38 or 46
    
    -- Build playlist children
    local playlistChildren = {
        Layout = Roact.createElement("UIListLayout", {
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, isPhone and 5 or 6)
        })
    }
    
    for i, t in ipairs(Playlist) do
        playlistChildren["Track" .. i] = createTrackItem({
            track = t,
            index = i,
            isPlaying = (i == currentTrack and isPlaying),
            onSelect = onSelectTrack,
            itemHeight = trackItemHeight,
            isPhone = isPhone
        })
    end
    
    -- Calculate positions (no progress bar)
    local contentPadding = isPhone and 10 or 14
    local sectionGap = isPhone and 8 or 10
    local controlsY = headerHeight + sectionGap
    local volumeY = controlsY + controlsHeight + sectionGap
    local playlistLabelY = volumeY + volumeHeight + sectionGap
    local playlistY = playlistLabelY + 18
    local playlistHeight = panelHeight - playlistY - contentPadding
    
    -- Calculate bottom offset to avoid hotbar
    local hotbarOffset = isPhone and 70 or (isMobile and 80 or 90)
    
    return Roact.createElement("Frame", {
        Name = "MusicView",
        Size = UDim2.new(0, panelWidth, 0, panelHeight),
        Position = UDim2.new(0.5, 0, 0.5, isPhone and -35 or -45),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = Theme.Background,
        BackgroundTransparency = 0.05
    }, {
        Corner = Roact.createElement("UICorner", { CornerRadius = UDim.new(0, isPhone and 12 or 16) }),
        Stroke = Roact.createElement("UIStroke", {
            Color = Theme.Primary,
            Thickness = isPhone and 1 or 2,
            Transparency = 0.5
        }),
        
        -- Header with gradient
        Header = Roact.createElement("Frame", {
            Size = UDim2.new(1, 0, 0, headerHeight),
            BackgroundColor3 = Theme.Primary,
            BackgroundTransparency = 0.3
        }, {
            Corner = Roact.createElement("UICorner", { CornerRadius = UDim.new(0, isPhone and 12 or 16) }),
            Gradient = Roact.createElement("UIGradient", {
                Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0, Color3.fromRGB(139, 92, 246)),
                    ColorSequenceKeypoint.new(1, Color3.fromRGB(59, 130, 246))
                }),
                Rotation = 45
            }),
            
            MusicIcon = Icons.IsTextIcon("musicNote") and Roact.createElement("TextLabel", {
                Size = UDim2.new(0, isPhone and 28 or 36, 0, isPhone and 28 or 36),
                Position = UDim2.new(0.5, 0, 0, isPhone and 8 or 12),
                AnchorPoint = Vector2.new(0.5, 0),
                BackgroundTransparency = 1,
                Text = "Music",
                TextSize = isPhone and 24 or 30
            }) or Roact.createElement("ImageLabel", {
                Size = UDim2.new(0, isPhone and 28 or 36, 0, isPhone and 28 or 36),
                Position = UDim2.new(0.5, 0, 0, isPhone and 8 or 12),
                AnchorPoint = Vector2.new(0.5, 0),
                BackgroundTransparency = 1,
                Image = Icons.Get("musicNote"),
                ImageColor3 = Color3.new(1, 1, 1),
                ScaleType = Enum.ScaleType.Fit
            }),
            
            Title = Roact.createElement("TextLabel", {
                Size = UDim2.new(1, -24, 0, 20),
                Position = UDim2.new(0.5, 0, 0, isPhone and 38 or 52),
                AnchorPoint = Vector2.new(0.5, 0),
                BackgroundTransparency = 1,
                Text = track.title,
                TextColor3 = Theme.TextPrimary,
                TextSize = isPhone and 14 or 16,
                Font = Theme.FontBold,
                TextTruncate = Enum.TextTruncate.AtEnd
            }),
            
            Artist = Roact.createElement("TextLabel", {
                Size = UDim2.new(1, -24, 0, 16),
                Position = UDim2.new(0.5, 0, 0, isPhone and 56 or 72),
                AnchorPoint = Vector2.new(0.5, 0),
                BackgroundTransparency = 1,
                Text = track.artist,
                TextColor3 = Color3.fromRGB(200, 200, 220),
                TextSize = isPhone and 10 or 12,
                Font = Theme.FontRegular
            })
        }),
        
        -- Controls
        Controls = Roact.createElement("Frame", {
            Size = UDim2.new(1, -contentPadding * 2, 0, controlsHeight),
            Position = UDim2.new(0.5, 0, 0, controlsY),
            AnchorPoint = Vector2.new(0.5, 0),
            BackgroundTransparency = 1
        }, {
            Layout = Roact.createElement("UIListLayout", {
                FillDirection = Enum.FillDirection.Horizontal,
                HorizontalAlignment = Enum.HorizontalAlignment.Center,
                VerticalAlignment = Enum.VerticalAlignment.Center,
                Padding = UDim.new(0, isPhone and 12 or 18)
            }),
            
            PrevBtn = createControlButton({
                icon = "Prev",
                iconName = "previous",
                onClick = onNext,
                size = UDim2.new(0, isPhone and 36 or 44, 0, isPhone and 36 or 44)
            }),
            
            PlayBtn = createControlButton({
                icon = isPlaying and "Pause" or "Play",
                iconName = isPlaying and "pause" or "play",
                size = UDim2.new(0, isPhone and 50 or 60, 0, isPhone and 50 or 60),
                textSize = isPhone and 20 or 24,
                primary = true,
                onClick = isPlaying and onPause or onPlay
            }),
            
            NextBtn = createControlButton({
                icon = "Next",
                iconName = "next",
                onClick = onPrev,
                size = UDim2.new(0, isPhone and 36 or 44, 0, isPhone and 36 or 44)
            })
        }),
        
        -- Volume slider
        VolumeSection = Roact.createElement("Frame", {
            Size = UDim2.new(1, -contentPadding * 2, 0, volumeHeight),
            Position = UDim2.new(0.5, 0, 0, volumeY),
            AnchorPoint = Vector2.new(0.5, 0),
            BackgroundTransparency = 1
        }, {
            VolumeIcon = (function()
                local iconName = volume > 0 and "volume" or "volumeMute"
                local isText = Icons.IsTextIcon(iconName)
                
                return Roact.createElement("TextButton", {
                    Size = UDim2.new(0, 24, 0, 24),
                    Position = UDim2.new(0, 0, 0.5, 0),
                    AnchorPoint = Vector2.new(0, 0.5),
                    BackgroundColor3 = Theme.BackgroundCard,
                    BackgroundTransparency = 0.5,
                    Text = isText and Icons.Get(iconName) or "",
                    TextColor3 = Theme.TextMuted,
                    TextSize = isPhone and 14 or 16,
                    Font = Theme.FontMedium,
                    Event = {
                        MouseButton1Click = function()
                            local newVol = volume > 0 and 0 or 0.5
                            if onVolumeChange then onVolumeChange(newVol) end
                            MusicView.setVolume(newVol)
                        end
                    }
                }, {
                    Corner = Roact.createElement("UICorner", { CornerRadius = UDim.new(0, 6) }),
                    IconImage = (not isText) and Roact.createElement("ImageLabel", {
                        Size = UDim2.new(0.65, 0, 0.65, 0),
                        Position = UDim2.new(0.5, 0, 0.5, 0),
                        AnchorPoint = Vector2.new(0.5, 0.5),
                        BackgroundTransparency = 1,
                        Image = Icons.Get(iconName),
                        ImageColor3 = Theme.TextMuted,
                        ScaleType = Enum.ScaleType.Fit
                    }) or nil
                })
            end)(),
            
            SliderBg = Roact.createElement("TextButton", {
                Size = UDim2.new(1, -80, 0, 6),
                Position = UDim2.new(0, 30, 0.5, 0),
                AnchorPoint = Vector2.new(0, 0.5),
                BackgroundColor3 = Theme.BackgroundCard,
                Text = "",
                AutoButtonColor = false,
                Event = {
                    MouseButton1Click = function(rbx)
                        local UserInputService = game:GetService("UserInputService")
                        local mousePos = UserInputService:GetMouseLocation()
                        local relativeX = mousePos.X - rbx.AbsolutePosition.X
                        local newVol = math.clamp(relativeX / rbx.AbsoluteSize.X, 0, 1)
                        if onVolumeChange then onVolumeChange(newVol) end
                        MusicView.setVolume(newVol)
                    end
                }
            }, {
                Corner = Roact.createElement("UICorner", { CornerRadius = UDim.new(1, 0) }),
                Fill = Roact.createElement("Frame", {
                    Size = UDim2.new(volume, 0, 1, 0),
                    BackgroundColor3 = Theme.Primary
                }, {
                    Corner = Roact.createElement("UICorner", { CornerRadius = UDim.new(1, 0) })
                })
            }),
            
            VolumePercent = Roact.createElement("TextLabel", {
                Size = UDim2.new(0, 40, 1, 0),
                Position = UDim2.new(1, 0, 0.5, 0),
                AnchorPoint = Vector2.new(1, 0.5),
                BackgroundTransparency = 1,
                Text = math.floor(volume * 100) .. "%",
                TextColor3 = Theme.Primary,
                TextSize = isPhone and 10 or 12,
                Font = Theme.FontBold,
                TextXAlignment = Enum.TextXAlignment.Right
            })
        }),
        
        -- Playlist label
        PlaylistLabel = Roact.createElement("TextLabel", {
            Size = UDim2.new(1, -contentPadding * 2, 0, 18),
            Position = UDim2.new(0.5, 0, 0, playlistLabelY),
            AnchorPoint = Vector2.new(0.5, 0),
            BackgroundTransparency = 1,
            Text = "PLAYLIST",
            TextColor3 = Theme.TextMuted,
            TextSize = isPhone and 10 or 11,
            Font = Theme.FontBold,
            TextXAlignment = Enum.TextXAlignment.Left
        }),
        
        -- Playlist container
        PlaylistContainer = Roact.createElement("ScrollingFrame", {
            Size = UDim2.new(1, -contentPadding * 2, 0, playlistHeight),
            Position = UDim2.new(0.5, 0, 0, playlistY),
            AnchorPoint = Vector2.new(0.5, 0),
            BackgroundTransparency = 1,
            ScrollBarThickness = 3,
            ScrollBarImageColor3 = Theme.Primary,
            CanvasSize = UDim2.new(0, 0, 0, #Playlist * (trackItemHeight + 6)),
            AutomaticCanvasSize = Enum.AutomaticSize.Y
        }, playlistChildren)
    })
end

return MusicView