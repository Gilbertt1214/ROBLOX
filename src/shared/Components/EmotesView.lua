--[[
    EmotesView Component
    Displays emotes and dances - click to play, click again to stop
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Roact = require(ReplicatedStorage.Shared.Roact)
local Theme = require(ReplicatedStorage.Shared.Theme)
local ResponsiveUtil = require(ReplicatedStorage.Shared.ResponsiveUtil)

local EmotesView = {}

-- Current state
local currentAnimTrack = nil
local currentEmoteId = nil
local isSyncLeader = false -- Track if this player is leading sync dances

--[[
    EMOTES LIST - Edit here!
    Format: { id = "rbxassetid://ANIMATION_ID", name = "Name", category = "emote"/"dance" }
]]
local EmotesList = {
    -- EMOTES
    { id = "rbxassetid://137704682075613", name = "Aura", category = "emote" },
    { id = "rbxassetid://116819742540173", name = "Fish", category = "emote" },
    { id = "rbxassetid://124729247977888", name = "Head", category = "emote" },
    { id = "rbxassetid://96472136646078", name = "Kungfu", category = "emote" },
    { id = "rbxassetid://82658426526777", name = "Sit 1", category = "emote" },
    { id = "rbxassetid://126899447275562", name = "Sit 2", category = "emote" },
    { id = "rbxassetid://95825103583419", name = " Sit 3", category = "emote"},
    { id = "rbxassetid://88108361500125", name = "Sleeping", category = "emote"},
    { id = "rbxassetid://104428851742579", name = "Boss", category = "emote"},
    -- DANCES  
    { id = "rbxassetid://126275747804327", name = "Confidence", category = "dance" },
    { id = "rbxassetid://81858338047717", name = "Poke", category = "dance" },
    { id = "rbxassetid://106534063593882", name = "Macarena", category = "dance" },
    { id = "rbxassetid://119873789876488", name = "Rat", category = "dance" },
    { id = "rbxassetid://80621140833482", name = "Vibin", category = "dance" },
    { id = "rbxassetid://110014784361452", name = "Belly", category = "dance" },
    { id = "rbxassetid://137068880594650", name = "Goofy", category = "dance"},
    { id = "rbxassetid://110649378042569", name = "Ishowspeed", category = "dabce"},
    { id = "rbxassetid://140045473880554", name = "popular", category = "dance"},
    { id = "rbxassetid://102806389992264", name = "Doggie", category = "dance"},
    { id = "rbxassetid://116880211354619", name = "Caramell", category = "dance"},
    { id = "rbxassetid://117991470645633", name = "Nonchalant", category = "dance"},
     { id = "rbxassetid://101758039233408", name = "Dance06", category = "dance"},
      { id = "rbxassetid://109890018648278", name = "Hakari Dance", category = "dance"},
      { id = "rbxassetid://76416861894218", name = "WIBU", category = "dance"},
       { id = "rbxassetid://96147994216119", name = "MOSH", category = "dance"},
       { id = "rbxassetid://121992329752005", name = " Exciting ", category = "dance"},
}

-- Toggle emote - play if not playing, stop if same emote clicked
function EmotesView.toggleEmote(emoteId, isFromSync)
    local player = Players.LocalPlayer
    if not player or not player.Character then return end
    
    local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end
    
    -- If same emote is playing, stop it
    if currentEmoteId == emoteId and currentAnimTrack and currentAnimTrack.IsPlaying then
        currentAnimTrack:Stop()
        currentAnimTrack = nil
        currentEmoteId = nil
        
        -- Broadcast stop to server (for followers and instant sync tracking)
        if not isFromSync then
            local SyncDanceRemote = ReplicatedStorage:FindFirstChild("SyncDanceRemote")
            if SyncDanceRemote then
                SyncDanceRemote:FireServer("StopDance", {})
            end
        end
        return
    end
    
    -- Stop current if different
    if currentAnimTrack and currentAnimTrack.IsPlaying then
        currentAnimTrack:Stop()
    end
    
    -- Don't play if no valid ID
    if emoteId == "rbxassetid://0" then
        warn("[Emotes] No animation ID set")
        return
    end
    
    -- Play new animation
    local animator = humanoid:FindFirstChildOfClass("Animator")
    if not animator then
        animator = Instance.new("Animator")
        animator.Parent = humanoid
    end
    
    local animation = Instance.new("Animation")
    animation.AnimationId = emoteId
    
    local success, track = pcall(function()
        return animator:LoadAnimation(animation)
    end)
    
    if success and track then
        currentAnimTrack = track
        currentEmoteId = emoteId
        track.Priority = Enum.AnimationPriority.Action
        track:Play()
        animation:Destroy()
        
        -- Broadcast to server (for followers and instant sync tracking)
        if not isFromSync then
            local SyncDanceRemote = ReplicatedStorage:FindFirstChild("SyncDanceRemote")
            if SyncDanceRemote then
                SyncDanceRemote:FireServer("PlayDance", {danceId = emoteId})
            end
        end
    end
end

-- Stop current emote
function EmotesView.stopEmote()
    if currentAnimTrack and currentAnimTrack.IsPlaying then
        currentAnimTrack:Stop()
    end
    currentAnimTrack = nil
    currentEmoteId = nil
end

-- Set sync leader status
function EmotesView.setSyncLeader(isLeader)
    isSyncLeader = isLeader
end

-- Get EmotesList for external use
function EmotesView.getEmotesList()
    return EmotesList
end

function EmotesView.create(props)
    local sizes = ResponsiveUtil.getSizes()
    local isPhone = ResponsiveUtil.isPhone()
    local isMobile = ResponsiveUtil.isMobile()
    
    -- Responsive sizes - smaller to avoid hotbar
    local panelWidth = isPhone and 260 or (isMobile and 280 or 300)
    local panelHeight = isPhone and 320 or (isMobile and 360 or 400)
    local cellWidth = isPhone and 70 or (isMobile and 78 or 85)
    local cellHeight = isPhone and 50 or (isMobile and 58 or 65)
    local titleSize = sizes.fontSize.large
    
    -- Separate by category
    local emotes = {}
    local dances = {}
    for _, e in ipairs(EmotesList) do
        if e.category == "dance" then
            table.insert(dances, e)
        else
            table.insert(emotes, e)
        end
    end
    
    -- Create emote buttons with hover animation
    local function makeButtons(list)
        local buttons = {
            Layout = Roact.createElement("UIGridLayout", {
                CellSize = UDim2.new(0, cellWidth, 0, cellHeight),
                CellPadding = UDim2.new(0, isPhone and 5 or 8, 0, isPhone and 5 or 8),
                SortOrder = Enum.SortOrder.LayoutOrder
            })
        }
        for i, emote in ipairs(list) do
            buttons["E"..i] = Roact.createElement("TextButton", {
                BackgroundColor3 = Theme.BackgroundLight,
                BackgroundTransparency = 0.3,
                Text = "",
                LayoutOrder = i,
                Event = {
                    MouseButton1Click = function(rbx)
                        EmotesView.toggleEmote(emote.id)
                        -- Click animation
                        TweenService:Create(rbx, TweenInfo.new(0.1), {
                            Size = UDim2.new(0, cellWidth - 5, 0, cellHeight - 5)
                        }):Play()
                        task.delay(0.1, function()
                            TweenService:Create(rbx, TweenInfo.new(0.15, Enum.EasingStyle.Back), {
                                Size = UDim2.new(0, cellWidth, 0, cellHeight)
                            }):Play()
                        end)
                    end,
                    MouseEnter = function(rbx)
                        TweenService:Create(rbx, TweenInfo.new(0.15, Enum.EasingStyle.Quad), {
                            BackgroundTransparency = 0.1,
                            BackgroundColor3 = Theme.Primary
                        }):Play()
                    end,
                    MouseLeave = function(rbx)
                        TweenService:Create(rbx, TweenInfo.new(0.15, Enum.EasingStyle.Quad), {
                            BackgroundTransparency = 0.3,
                            BackgroundColor3 = Theme.BackgroundLight
                        }):Play()
                    end
                }
            }, {
                Corner = Roact.createElement("UICorner", { CornerRadius = UDim.new(0, 10) }),
                Name = Roact.createElement("TextLabel", {
                    Size = UDim2.new(1, 0, 1, 0),
                    BackgroundTransparency = 1,
                    Text = emote.name,
                    TextColor3 = Theme.TextPrimary,
                    TextSize = isPhone and 10 or 12,
                    Font = Theme.FontMedium
                })
            })
        end
        return buttons
    end
    
    local emoteRows = math.ceil(#emotes / 3) * (cellHeight + 8)
    local danceRows = math.ceil(#dances / 3) * (cellHeight + 8)
    
    return Roact.createElement("Frame", {
        Name = "EmotesView",
        Size = UDim2.new(0, panelWidth, 0, panelHeight),
        Position = UDim2.new(0.5, 0, 0.5, isPhone and -30 or -40),
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
        
        Title = Roact.createElement("TextLabel", {
            Size = UDim2.new(1, 0, 0, isPhone and 35 or 45),
            BackgroundTransparency = 1,
            Text = "EMOTES & DANCES",
            TextColor3 = Theme.TextPrimary,
            TextSize = titleSize,
            Font = Theme.FontBold
        }),
        
        Content = Roact.createElement("ScrollingFrame", {
            Size = UDim2.new(1, -16, 1, isPhone and -40 or -55),
            Position = UDim2.new(0, 8, 0, isPhone and 38 or 50),
            BackgroundTransparency = 1,
            ScrollBarThickness = 3,
            ScrollBarImageColor3 = Theme.Primary,
            CanvasSize = UDim2.new(0, 0, 0, emoteRows + danceRows + 80),
            AutomaticCanvasSize = Enum.AutomaticSize.Y
        }, {
            Layout = Roact.createElement("UIListLayout", {
                SortOrder = Enum.SortOrder.LayoutOrder,
                Padding = UDim.new(0, isPhone and 6 or 10)
            }),
            
            -- Emotes Section
            EmoteHeader = Roact.createElement("TextLabel", {
                Size = UDim2.new(1, 0, 0, isPhone and 18 or 22),
                BackgroundTransparency = 1,
                Text = "EMOTE",
                TextColor3 = Theme.Primary,
                TextSize = sizes.fontSize.small,
                Font = Theme.FontBold,
                TextXAlignment = Enum.TextXAlignment.Left,
                LayoutOrder = 1
            }),
            EmoteGrid = Roact.createElement("Frame", {
                Size = UDim2.new(1, 0, 0, emoteRows),
                BackgroundTransparency = 1,
                LayoutOrder = 2
            }, makeButtons(emotes)),
            
            -- Dances Section
            DanceHeader = Roact.createElement("TextLabel", {
                Size = UDim2.new(1, 0, 0, isPhone and 18 or 22),
                BackgroundTransparency = 1,
                Text = "DANCE",
                TextColor3 = Theme.Primary,
                TextSize = sizes.fontSize.small,
                Font = Theme.FontBold,
                TextXAlignment = Enum.TextXAlignment.Left,
                LayoutOrder = 3
            }),
            DanceGrid = Roact.createElement("Frame", {
                Size = UDim2.new(1, 0, 0, danceRows),
                BackgroundTransparency = 1,
                LayoutOrder = 4
            }, makeButtons(dances))
        })
    })
end

return EmotesView
