--[[
    UI Sounds Module
    Centralized sound effects for UI interactions
]]

local SoundService = game:GetService("SoundService")

local UISounds = {}

-- Sound IDs (Roblox library sounds - verified working)
local SoundIds = {
    click = "rbxassetid://421058925",       -- Button click
    open = "rbxassetid://421058925",        -- Open (same as click)
    close = "rbxassetid://421058925",       -- Close (same as click)
    hover = "rbxassetid://421058925",       -- Hover
    success = "rbxassetid://421058925",     -- Success
    error = "rbxassetid://421058925",       -- Error
    notification = "rbxassetid://421058925", -- Notification
    equip = "rbxassetid://421058925",       -- Equip
    purchase = "rbxassetid://421058925",    -- Purchase
}

-- Volume settings
local Volumes = {
    click = 0.3,
    open = 0.4,
    close = 0.35,
    hover = 0.15,
    success = 0.5,
    error = 0.4,
    notification = 0.45,
    equip = 0.4,
    purchase = 0.5,
}

-- Create sound folder in SoundService
local soundFolder = SoundService:FindFirstChild("UISounds")
if not soundFolder then
    soundFolder = Instance.new("Folder")
    soundFolder.Name = "UISounds"
    soundFolder.Parent = SoundService
end

-- Pre-create sound instances for faster playback
local sounds = {}
for name, id in pairs(SoundIds) do
    local sound = Instance.new("Sound")
    sound.Name = name
    sound.SoundId = id
    sound.Volume = Volumes[name] or 0.3
    sound.Parent = soundFolder
    sounds[name] = sound
end

-- Play a sound by name
function UISounds.play(soundName)
    local sound = sounds[soundName]
    if sound then
        -- Clone and play to allow overlapping sounds
        local clone = sound:Clone()
        clone.Parent = soundFolder
        clone:Play()
        
        -- Cleanup after playing
        clone.Ended:Connect(function()
            clone:Destroy()
        end)
        
        return clone
    else
        warn("[UISounds] Sound not found:", soundName)
    end
end

-- Play click sound
function UISounds.click()
    UISounds.play("click")
end

-- Play open sound (for panels/views)
function UISounds.open()
    UISounds.play("open")
end

-- Play close sound
function UISounds.close()
    UISounds.play("close")
end

-- Play hover sound
function UISounds.hover()
    UISounds.play("hover")
end

-- Play success sound
function UISounds.success()
    UISounds.play("success")
end

-- Play error sound
function UISounds.error()
    UISounds.play("error")
end

-- Play notification sound
function UISounds.notification()
    UISounds.play("notification")
end

-- Play equip sound
function UISounds.equip()
    UISounds.play("equip")
end

-- Play purchase sound
function UISounds.purchase()
    UISounds.play("purchase")
end

-- Set master volume for all UI sounds (0-1)
function UISounds.setVolume(volume)
    for name, sound in pairs(sounds) do
        sound.Volume = (Volumes[name] or 0.3) * volume
    end
end

-- Mute/unmute all UI sounds
function UISounds.setMuted(muted)
    for _, sound in pairs(sounds) do
        sound.Volume = muted and 0 or (Volumes[sound.Name] or 0.3)
    end
end

return UISounds
