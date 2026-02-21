--[[
    CombatController Client Script
    Handles player input for Punch (E) and Block (X).
    Manages animations and remote sync for the combat system.
]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ContextActionService = game:GetService("ContextActionService")

local Icons = require(ReplicatedStorage.Shared.Icons)

local Player = Players.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")
local Animator = Humanoid:WaitForChild("Animator")

-- Configuration
local PUNCH_KEY = Enum.UserInputType.MouseButton1
local BLOCK_KEY = Enum.KeyCode.F
local PUNCH_COOLDOWN = 0.5

-- Block Health Configuration
local BLOCK_MAX_HEALTH = 100
local BLOCK_DECAY_RATE = 15 -- Health lost per second while holding block
local BLOCK_REGEN_RATE = 20 -- Health regained per second while not blocking
local BLOCK_MIN_START_HEALTH = 20 -- Minimum health to start a block
local BLOCK_BROKEN_COOLDOWN = 3 -- Seconds until block can be used again after breaking

-- Combat System Assets
local CombatSystem = ReplicatedStorage:WaitForChild("CombatSystem")
local Animations = CombatSystem:WaitForChild("CombatAnimations")
local PunchRemote = CombatSystem:WaitForChild("Punching")

-- Animation IDs
local RIG_ANIMS = {
    [Enum.HumanoidRigType.R6] = {
        Block = Animations:WaitForChild("Block"),
        Left = Animations:WaitForChild("LeftPunch"),
        Right = Animations:WaitForChild("RightPunch")
    },
    [Enum.HumanoidRigType.R15] = {
        Block = "132984458072182",
        Left = "124920968475982",
        Right = "93508385671912"
    }
}

-- State
local isAttacking = false
local isBlocking = false
local currentCombo = 1 -- 1: Left, 2: Right
local buttonsBound = false

-- Block State
local currentBlockHealth = BLOCK_MAX_HEALTH
local blockBrokenTime = 0
local lastRegenTick = tick()

-- Helper to check if player is in arena
local function isInArena()
    if not Character then return false end
    local hrp = Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end

    local arenaFolder = workspace:FindFirstChild("CombatArena")
    if not arenaFolder then return true end

    for _, part in ipairs(arenaFolder:GetDescendants()) do
        if part:IsA("BasePart") then
            -- Check if HRP position is within part bounds
            local offset = part.CFrame:PointToObjectSpace(hrp.Position)
            local halfSize = part.Size / 2
            if math.abs(offset.X) <= halfSize.X and math.abs(offset.Y) <= halfSize.Y and math.abs(offset.Z) <= halfSize.Z then
                return true
            end
        end
    end
    return false
end

-- Animation Tracks
local trackBlock, trackLeft, trackRight

local function loadAnimations()
    local rigType = Humanoid.RigType
    local anims = RIG_ANIMS[rigType] or RIG_ANIMS[Enum.HumanoidRigType.R15] -- Default to R15 if unsure
    
    local function getAnimObject(key)
        local val = anims[key]
        if typeof(val) == "string" then
            local anim = Instance.new("Animation")
            anim.AnimationId = "rbxassetid://" .. val
            return anim
        end
        return val
    end

    trackBlock = Animator:LoadAnimation(getAnimObject("Block"))
    trackLeft = Animator:LoadAnimation(getAnimObject("Left"))
    trackRight = Animator:LoadAnimation(getAnimObject("Right"))
end

loadAnimations()

local function punch()
    if isAttacking or isBlocking then return end
    if not isInArena() then return end
    
    isAttacking = true
    
    -- Play combo animation
    if currentCombo == 1 then
        trackLeft:Play()
        currentCombo = 2
    else
        trackRight:Play()
        currentCombo = 1
    end
    
    -- Sync with server for sound/VFX trigger
    PunchRemote:FireServer()
    
    task.wait(PUNCH_COOLDOWN)
    isAttacking = false
end

local function startBlock()
    if isAttacking then return end
    if not isInArena() then return end
    if tick() - blockBrokenTime < BLOCK_BROKEN_COOLDOWN then return end
    if currentBlockHealth < BLOCK_MIN_START_HEALTH then return end
    
    isBlocking = true
    trackBlock:Play()
end

local function stopBlock()
    isBlocking = false
    trackBlock:Stop()
end

-- Input Action handlers
local function handlePunchAction(actionName, inputState, inputObject)
    if inputState == Enum.UserInputState.Begin then
        punch()
    end
    return Enum.ContextActionResult.Pass
end

local function handleBlockAction(actionName, inputState, inputObject)
    if inputState == Enum.UserInputState.Begin then
        startBlock()
    elseif inputState == Enum.UserInputState.End then
        stopBlock()
    end
    return Enum.ContextActionResult.Pass
end

local originalJumpPower = Humanoid.JumpPower

-- Mobile Buttons Management
local function toggleCombatButtons(enabled)
    if enabled == buttonsBound then return end
    buttonsBound = enabled
    
    if enabled then
        -- Bind Actions (Creates mobile buttons if 3rd arg is true)
        ContextActionService:BindAction("PunchAction", handlePunchAction, true, PUNCH_KEY)
        ContextActionService:BindAction("BlockAction", handleBlockAction, true, BLOCK_KEY)
        
        -- Style buttons (Titles and Icons from Icons.lua)
        ContextActionService:SetTitle("PunchAction", "Punch")
        ContextActionService:SetImage("PunchAction", Icons.Get("sword"))
        
        ContextActionService:SetTitle("BlockAction", "Block")
        ContextActionService:SetImage("BlockAction", Icons.Get("shield"))
        
        -- Disable Jumping (Hides jump button on mobile)
        originalJumpPower = Humanoid.JumpPower
        Humanoid.JumpPower = 0
        Humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
    else
        -- Unbind Actions (Removes mobile buttons)
        ContextActionService:UnbindAction("PunchAction")
        ContextActionService:UnbindAction("BlockAction")
        
        -- Enable Jumping
        Humanoid.JumpPower = originalJumpPower
        Humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
        
        -- Reset Block state if leaving arena
        if isBlocking then
            stopBlock()
        end
    end
end

-- Position Monitor Loop
local CHECK_INTERVAL = 0.1
local lastCheck = 0

RunService.Heartbeat:Connect(function()
    if not Character or not Humanoid or Humanoid.Health <= 0 then return end
    
    local now = tick()
    local deltaTime = now - lastRegenTick
    lastRegenTick = now

    -- Block Health Logic
    if isBlocking then
        currentBlockHealth = math.max(0, currentBlockHealth - (BLOCK_DECAY_RATE * deltaTime))
        if currentBlockHealth <= 0 then
            stopBlock()
            blockBrokenTime = tick()
        end
    else
        if now - blockBrokenTime >= BLOCK_BROKEN_COOLDOWN then
            currentBlockHealth = math.min(BLOCK_MAX_HEALTH, currentBlockHealth + (BLOCK_REGEN_RATE * deltaTime))
        end
    end

    if now - lastCheck < CHECK_INTERVAL then return end
    lastCheck = now
    
    toggleCombatButtons(isInArena())
end)

-- Re-setup on spawn
Player.CharacterAdded:Connect(function(newChar)
    Character = newChar
    Humanoid = newChar:WaitForChild("Humanoid")
    Animator = Humanoid:WaitForChild("Animator")
    
    loadAnimations()
    
    isAttacking = false
    isBlocking = false
    currentCombo = 1
    buttonsBound = false
end)
