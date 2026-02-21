--[[
    CombatHandler Server Script
    Manages hit detection, damage, knockback, and VFX for the combat system.
    Refactored from provided logic for better performance.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")

local CombatSystem = ReplicatedStorage:WaitForChild("CombatSystem")
local Animations = CombatSystem:WaitForChild("CombatAnimations")
local Settings = CombatSystem:WaitForChild("Settings")

-- Cache for hit detection to prevent multiple hits per swing
local hitCache = {} -- [Player] = { [Target] = OSTime }
local lastDamageTime = {} -- [Player] = OSTime (Last time they took damage)
local lastAttacker = {} -- [TargetChar] = { Player = Attacker, Time = OSTime }

-- Configuration from settings
local DAMAGE = Settings:WaitForChild("Damage").Value
local THRUST_VALUE = Settings:WaitForChild("ThrustValue").Value
local VISUAL_ENABLED = Settings:WaitForChild("VisualEffectsEnabled").Value
local SOUND_ENABLED = Settings:WaitForChild("SoundEffectsEnabled").Value

-- Block Configuration
local BLOCK_DAMAGE = 20 -- How much block health is removed per hit

-- Health Reward for winning a combat
local WIN_REWARD = 50 -- Currency reward per kill

-- Healing Config
local HEAL_RATE = 5 -- HP per second
local HEAL_COOLDOWN = 5 -- Seconds after taking damage before healing starts

local function getTorso(char)
    return char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso") or char:FindFirstChild("HumanoidRootPart")
end

-- Helper to check if a character is within the CombatArena zone
local function isInArena(char)
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end
    
    local arenaFolder = workspace:FindFirstChild("CombatArena")
    if not arenaFolder then return true end -- Default to true if arena folder is missing
    
    -- Check all parts in the arena folder (supporting multiple arena zones)
    for _, part in ipairs(arenaFolder:GetDescendants()) do
        if part:IsA("BasePart") then
            -- Simple volume check using GetPartBoundsInBox
            local partsInBounds = workspace:GetPartBoundsInBox(part.CFrame, part.Size)
            for _, p in ipairs(partsInBounds) do
                if p:IsDescendantOf(char) then
                    return true
                end
            end
        end
    end
    
    return false
end

-- Valid Animation IDs for hit detection (both R6 and R15)
local ATTACK_IDS = {
    [Animations.LeftPunch.AnimationId] = 1,
    [Animations.RightPunch.AnimationId] = 2,
    ["rbxassetid://124920968475982"] = 1, -- R15 Left
    ["rbxassetid://93508385671912"] = 2,  -- R15 Right
}

local BLOCK_IDS = {
    [Animations.Block.AnimationId] = true,
    ["rbxassetid://132984458072182"] = true, -- R15 Block
}

local playerBlockHealth = {} -- [Player] = CurrentBlockHealth

local function isBlocking(char)
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if not humanoid then return false end
    
    local tracks = humanoid:GetPlayingAnimationTracks()
    for _, track in ipairs(tracks) do
        local id = track.Animation.AnimationId
        if BLOCK_IDS[id] then
            return true
        end
    end
    return false
end

local function handleHit(attacker, targetChar, attackType)
    local targetHumanoid = targetChar:FindFirstChildOfClass("Humanoid")
    local targetHRP = targetChar:FindFirstChild("HumanoidRootPart")
    local attackerHRP = attacker.Character and attacker.Character:FindFirstChild("HumanoidRootPart")
    
    if not (targetHumanoid and targetHRP and attackerHRP) then return end
    if targetHumanoid.Health <= 0 then return end

    local torso = getTorso(targetChar)
    local blocking = isBlocking(targetChar)

    if blocking then
        -- Play Block Effect
        local blockEffect = CombatSystem:FindFirstChild("BlockEffect")
        if blockEffect and torso then
            local clone = blockEffect:Clone()
            clone.Parent = torso
            Debris:AddItem(clone, 2)
        end

        -- Reduce Block Health on Server as well (to prevent exploits)
        local targetPlayer = Players:GetPlayerFromCharacter(targetChar)
        if targetPlayer then
            local currentHealth = playerBlockHealth[targetPlayer] or 100
            currentHealth = math.max(0, currentHealth - BLOCK_DAMAGE)
            playerBlockHealth[targetPlayer] = currentHealth
            
            -- If block health hits 0, the server will treat subsequent hits as normal damage
            -- The client will also break the block via its own heartbeat loop
        end
        return
    end

    -- Apply Damage
    targetHumanoid:TakeDamage(DAMAGE)
    
    -- Track last damage and attacker
    local targetPlayer = Players:GetPlayerFromCharacter(targetChar)
    if targetPlayer then
        lastDamageTime[targetPlayer] = tick()
    end
    lastAttacker[targetChar] = { Player = attacker, Time = tick() }

    -- Apply Knockback
    local bv = Instance.new("BodyVelocity")
    bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    bv.Velocity = attackerHRP.CFrame.LookVector * 50 + Vector3.new(0, THRUST_VALUE, 0)
    bv.Parent = targetHRP
    Debris:AddItem(bv, 0.1)

    -- Visual Effects
    if VISUAL_ENABLED and torso then
        if not torso:FindFirstChild("HitEffect") then
            local hitEffect = CombatSystem:FindFirstChild("HitEffect")
            if hitEffect then
                local clone = hitEffect:Clone()
                clone.Parent = torso
                Debris:AddItem(clone, 2)
            end
        end
    end

    -- Sound Effects
    if SOUND_ENABLED then
        local soundName = (attackType == 1) and "Punched1" or "Punched2"
        local punchSound = CombatSystem:FindFirstChild(soundName)
        if punchSound then
            local clone = punchSound:Clone()
            clone.Parent = attackerHRP
            clone:Play()
            Debris:AddItem(clone, 1)
        end
    end
end

-- Centralized hit detection loop
RunService.Heartbeat:Connect(function()
    for _, player in ipairs(Players:GetPlayers()) do
        local char = player.Character
        if not char then continue end
        
        local humanoid = char:FindFirstChildOfClass("Humanoid")
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not (humanoid and hrp) then continue end

        local animations = humanoid:GetPlayingAnimationTracks()
        local isAttacking = false
        local attackType = 1 -- 1: Left, 2: Right

        for _, anim in ipairs(animations) do
            local id = anim.Animation.AnimationId
            if ATTACK_IDS[id] then
                isAttacking = true
                attackType = ATTACK_IDS[id]
                break
            end
        end

        if isAttacking then
            -- Arena Check
            if not isInArena(char) then continue end
            
            -- Raycast for hit detection
            local rayParam = RaycastParams.new()
            rayParam.FilterDescendantsInstances = {char}
            rayParam.FilterType = Enum.RaycastFilterType.Exclude

            local result = workspace:Raycast(hrp.Position, hrp.CFrame.LookVector * 4, rayParam)
            if result and result.Instance and result.Instance.Parent then
                local targetChar = result.Instance.Parent
                if not targetChar:FindFirstChildOfClass("Humanoid") then
                    targetChar = targetChar.Parent -- Try one level up for accessories
                end

                if targetChar and targetChar:FindFirstChildOfClass("Humanoid") and targetChar ~= char then
                    -- Target must also be in arena
                    if not isInArena(targetChar) then continue end
                    
                    -- Debounce hit for this specific swing
                    if not hitCache[player] then hitCache[player] = {} end
                    
                    if not hitCache[player][targetChar] or (tick() - hitCache[player][targetChar] > 0.6) then
                        hitCache[player][targetChar] = tick()
                        handleHit(player, targetChar, attackType)
                    end
                end
            end
        else
            -- Clear cache when not attacking
            hitCache[player] = nil
        end
    end
end)

-- Healing Loop (Runs every second)
task.spawn(function()
    while true do
        for _, player in ipairs(Players:GetPlayers()) do
            local char = player.Character
            if char and isInArena(char) then
                local humanoid = char:FindFirstChildOfClass("Humanoid")
                if humanoid and humanoid.Health > 0 and humanoid.Health < humanoid.MaxHealth then
                    -- Check if enough time has passed since last damage
                    local lastHit = lastDamageTime[player] or 0
                    if tick() - lastHit > HEAL_COOLDOWN then
                        humanoid.Health = math.min(humanoid.MaxHealth, humanoid.Health + HEAL_RATE)
                    end
                end

                -- Regenerate Block Health
                local bh = playerBlockHealth[player] or 100
                if bh < 100 then
                    -- Server-side regen should be slightly slower or match client
                    playerBlockHealth[player] = math.min(100, bh + 5) 
                end
            end
        end
        task.wait(1)
    end
end)

-- Handle death and win tracking
local function onCharacterAdded(char)
    local humanoid = char:WaitForChild("Humanoid")
    humanoid.Died:Connect(function()
        local attackerInfo = lastAttacker[char]
        if attackerInfo and (tick() - attackerInfo.Time < 10) then
            -- Attacker exists and hit recently
            local attacker = attackerInfo.Player
            if attacker and attacker:IsDescendantOf(Players) then
                -- Award win!
                local PlayerData = require(ReplicatedStorage.Shared.PlayerData)
                PlayerData.incrementCombatWins(attacker)
                PlayerData.addCurrency(attacker, WIN_REWARD)
                
                -- Clear info
                lastAttacker[char] = nil
                -- print("[Combat] " .. attacker.Name .. " won combat against " .. char.Name)
            end
        end
    end)
end

for _, player in ipairs(Players:GetPlayers()) do
    if player.Character then onCharacterAdded(player.Character) end
    player.CharacterAdded:Connect(onCharacterAdded)
end
Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(onCharacterAdded)
end)

-- Handle Swing Sound via Remote
CombatSystem:WaitForChild("Punching").OnServerEvent:Connect(function(player)
    local char = player.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local swingSound = hrp:FindFirstChild("Swing")
    if not swingSound then
        local original = CombatSystem:FindFirstChild("Swing")
        if original then
            swingSound = original:Clone()
            swingSound.Name = "Swing"
            swingSound.Parent = hrp
        end
    end

    if swingSound then
        swingSound:Play()
    end
end)
