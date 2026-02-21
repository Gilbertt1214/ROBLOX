local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")
local CollectionService = game:GetService("CollectionService")

----------------------------------------------------
-- REMOTE EVENT
----------------------------------------------------
local REMOTE_NAME = "ThrowRemote"
local ThrowRemote = ReplicatedStorage:FindFirstChild(REMOTE_NAME) or Instance.new("RemoteEvent")
ThrowRemote.Name = REMOTE_NAME
ThrowRemote.Parent = ReplicatedStorage

----------------------------------------------------
-- CONFIG
----------------------------------------------------
local MAX_DISTANCE = 20
local THROW_FORCE = 175 -- Increased to match user script
local THROW_UP_FORCE = 25 -- Adjusted to match user script
local HOLD_DURATION = 1.5

----------------------------------------------------
-- ANIMATIONS
----------------------------------------------------
-- Parented to script for better loading
local ThrowAnimR15 = Instance.new("Animation")
ThrowAnimR15.Name = "ThrowAnimR15"
ThrowAnimR15.AnimationId = "rbxassetid://73402712528458"
ThrowAnimR15.Parent = script

local ThrowAnimR6 = Instance.new("Animation")
ThrowAnimR6.Name = "ThrowAnimR6"
ThrowAnimR6.AnimationId = "rbxassetid://129024115143940"
ThrowAnimR6.Parent = script

----------------------------------------------------
-- STATE
----------------------------------------------------
local holdingTarget: {[number]: Player} = {} -- carrier UserId -> target Player
local holdingCarrier: {[number]: Player} = {} -- target UserId -> carrier Player
local activeTracks: {[number]: AnimationTrack} = {} -- carrier UserId -> active AnimationTrack

----------------------------------------------------
-- SAVE/RESTORE
----------------------------------------------------
local savedProps: {[number]: {[BasePart]: {cc: boolean, ml: boolean}}} = {}
local savedHum: {[number]: {ws: number, useJP: boolean, jp: number, jh: number, autoRotate: boolean, ps: boolean}} = {}

----------------------------------------------------
-- HELPERS
----------------------------------------------------
local function getCharHRP(p: Player)
    local char = p.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart") :: BasePart?
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not (hrp and hum) then return end
    return char, hrp, hum
end

-- Improved Animation Handler based on user's script
local function playThrowAnim(player: Player, mode: number) -- 1 = Carry, 2 = Drop/Throw
    local char = player.Character
    if not char then return end
    
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    
    local animator = hum:FindFirstChildOfClass("Animator")
    if not animator then
        animator = Instance.new("Animator")
        animator.Parent = hum
    end
    
    -- Stop existing throw animation for this player
    if activeTracks[player.UserId] then
        activeTracks[player.UserId]:Stop(0.1)
        activeTracks[player.UserId] = nil
    end
    
    local anim = hum.RigType == Enum.HumanoidRigType.R6 and ThrowAnimR6 or ThrowAnimR15
    local track = animator:LoadAnimation(anim)
    track.Priority = Enum.AnimationPriority.Action4
    activeTracks[player.UserId] = track
    
    if mode == 1 then
        -- Play and pause at end (pose)
        track:Play(0, 1, 1)
        -- Wait for length to be available
        task.spawn(function()
            if track.Length == 0 then
                track:GetPropertyChangedSignal("Length"):Wait()
            end
            task.wait(math.max(0, track.Length - 0.05))
            -- Only pause if this is still the active track
            if activeTracks[player.UserId] == track then
                track:AdjustSpeed(0)
            end
        end)
    elseif mode == 2 then
        -- Play in reverse for drop/throw effect
        track:Play(0.1, 1, -1.5)
        -- Stop after finished (it's reversed, so it plays once to the beginning)
        task.spawn(function()
            if track.Length == 0 then
                track:GetPropertyChangedSignal("Length"):Wait()
            end
            task.wait(track.Length / 1.5)
            if activeTracks[player.UserId] == track then
                track:Stop(0.2)
                activeTracks[player.UserId] = nil
            end
        end)
    end
end

local function saveHumState(uid: number, hum: Humanoid)
    savedHum[uid] = {
        ws = hum.WalkSpeed,
        useJP = hum.UseJumpPower,
        jp = hum.JumpPower,
        jh = hum.JumpHeight,
        autoRotate = hum.AutoRotate,
        ps = hum.PlatformStand,
    }
end

local function restoreHumState(uid: number, hum: Humanoid)
    local st = savedHum[uid]
    if st then
        hum.WalkSpeed = st.ws
        hum.AutoRotate = st.autoRotate
        hum.PlatformStand = st.ps
        if st.useJP then hum.JumpPower = st.jp else hum.JumpHeight = st.jh end
        savedHum[uid] = nil
    else
        hum.AutoRotate = true
        hum.WalkSpeed = 16
        hum.PlatformStand = false
        if hum.UseJumpPower then hum.JumpPower = 50 else hum.JumpHeight = 7.2 end
    end
end

local function makeTargetLight(char: Model, userId: number)
    local map: {[BasePart]: {cc: boolean, ml: boolean}} = {}
    for _, d in ipairs(char:GetDescendants()) do
        if d:IsA("BasePart") then
            map[d] = { cc = d.CanCollide, ml = d.Massless }
            d.CanCollide = false
            d.Massless = true
        end
    end
    savedProps[userId] = map
end

local function restoreTargetLight(userId: number)
    local map = savedProps[userId]
    if not map then return end
    for part, st in pairs(map) do
        if part and part.Parent then
            part.CanCollide = st.cc
            part.Massless = st.ml
        end
    end
    savedProps[userId] = nil
end

local function setHRPOwnerTo(p: Player, owner: Player?)
    local _, hrp = getCharHRP(p)
    if not hrp then return end
    pcall(function()
        if owner then
            hrp:SetNetworkOwner(owner)
        else
            hrp:SetNetworkOwnershipAuto()
        end
    end)
end

----------------------------------------------------
-- PICKUP TARGET (for throw)
----------------------------------------------------
local function pickupForThrow(carrier: Player, target: Player): (boolean, string?)
    local cChar, cHRP = getCharHRP(carrier)
    local tChar, tHRP, tHum = getCharHRP(target)
    
    if not (cChar and cHRP and tChar and tHRP and tHum) then
        return false, "character missing"
    end
    
    if (cHRP.Position - tHRP.Position).Magnitude > MAX_DISTANCE then
        return false, "too far"
    end
    
    if holdingTarget[carrier.UserId] then
        return false, "already holding"
    end
    
    if holdingCarrier[target.UserId] then
        return false, "target busy"
    end
    
    -- Check if carrier is busy in either system
    if CollectionService:HasTag(cChar, "IsCarrying") or CollectionService:HasTag(cChar, "Interacting") then
        return false, "carrier busy"
    end
    
    -- Check shared interaction tag for target
    if CollectionService:HasTag(tChar, "Interacting") or CollectionService:HasTag(tChar, "IsCarrying") then
        return false, "target occupied"
    end
    
    -- Save states
    saveHumState(target.UserId, tHum)
    
    -- States based on user's script
    tHum.PlatformStand = true
    tHum.AutoRotate = false
    tHum.WalkSpeed = 0
    if tHum.UseJumpPower then tHum.JumpPower = 0 else tHum.JumpHeight = 0 end
    tHum:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
    
    -- Position target above carrier (similar to user's offset logic)
    -- Using a slightly better position for the weld
    tHRP.CFrame = cHRP.CFrame * CFrame.new(0, 2.5, 0.5)
    
    -- Weld target to carrier
    local weld = Instance.new("WeldConstraint")
    weld.Name = "ThrowWeld"
    weld.Part0 = cHRP
    weld.Part1 = tHRP
    weld.Parent = tHRP
    
    -- Make target light
    makeTargetLight(tChar, target.UserId)
    
    -- Give carrier network ownership
    setHRPOwnerTo(target, carrier)
    
    -- Track state
    holdingTarget[carrier.UserId] = target
    holdingCarrier[target.UserId] = carrier
    
    -- Set shared interaction tag
    CollectionService:AddTag(tChar, "Interacting")
    CollectionService:AddTag(cChar, "IsHolding")
    
    -- Play carry animation (mode 1)
    playThrowAnim(carrier, 1)
    
    -- Notify clients
    ThrowRemote:FireClient(carrier, "Holding", {
        targetId = target.UserId,
        targetName = target.DisplayName
    })
    ThrowRemote:FireClient(target, "BeingHeld", {
        carrierId = carrier.UserId,
        carrierName = carrier.DisplayName
    })
    
    return true
end

----------------------------------------------------
-- THROW TARGET
----------------------------------------------------
local function throwTarget(carrier: Player)
    local target = holdingTarget[carrier.UserId]
    if not target then return end
    
    local cChar, cHRP = getCharHRP(carrier)
    local tChar, tHRP, tHum = getCharHRP(target)
    
    -- Remove weld
    if tHRP then
        local weld = tHRP:FindFirstChild("ThrowWeld")
        if weld then weld:Destroy() end
    end
    
    -- Restore humanoid state
    if tHum then
        restoreHumState(target.UserId, tHum)
        tHum.PlatformStand = false
        tHum:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
        tHum:ChangeState(Enum.HumanoidStateType.Running)
    end
    
    -- Restore network ownership
    setHRPOwnerTo(target, nil)
    
    -- Apply throw velocity (matches user script)
    if tHRP and cHRP then
        local throwVelocity = cHRP.CFrame.LookVector * THROW_FORCE + cHRP.CFrame.UpVector * THROW_UP_FORCE
        
        local bv = Instance.new("BodyVelocity")
        bv.Velocity = throwVelocity
        bv.MaxForce = Vector3.new(1e5, 1e5, 1e5)
        bv.Parent = tHRP
        Debris:AddItem(bv, 0.1)
    end
    
    -- Restore physics
    restoreTargetLight(target.UserId)
    
    -- Remove shared interaction tags
    if tChar then
        CollectionService:RemoveTag(tChar, "Interacting")
    end
    if cChar then
        CollectionService:RemoveTag(cChar, "IsHolding")
    end
    
    -- Play drop/throw animation (mode 2)
    playThrowAnim(carrier, 2)
    
    -- Clear state
    holdingTarget[carrier.UserId] = nil
    holdingCarrier[target.UserId] = nil
    
    -- Notify clients
    ThrowRemote:FireClient(carrier, "Thrown", {
        targetId = target.UserId,
        targetName = target.DisplayName
    })
    ThrowRemote:FireClient(target, "WasThrown", {
        carrierId = carrier.UserId,
        carrierName = carrier.DisplayName
    })
end

----------------------------------------------------
-- DROP TARGET
----------------------------------------------------
local function dropTarget(carrier: Player)
    local target = holdingTarget[carrier.UserId]
    if not target then return end
    
    local tChar, tHRP, tHum = getCharHRP(target)
    
    -- Remove weld
    if tHRP then
        local weld = tHRP:FindFirstChild("ThrowWeld")
        if weld then weld:Destroy() end
        
        pcall(function()
            tHRP.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
            tHRP.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
        end)
    end
    
    -- Restore humanoid state
    if tHum then
        restoreHumState(target.UserId, tHum)
        tHum.PlatformStand = false
        tHum:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
        tHum:ChangeState(Enum.HumanoidStateType.Running)
    end
    
    -- Restore network ownership
    setHRPOwnerTo(target, nil)
    
    -- Restore physics
    restoreTargetLight(target.UserId)
    
    -- Remove shared interaction tags
    local cChar = carrier.Character
    if tChar then
        CollectionService:RemoveTag(tChar, "Interacting")
    end
    if cChar then
        CollectionService:RemoveTag(cChar, "IsHolding")
    end
    
    -- Play drop animation (mode 2)
    playThrowAnim(carrier, 2)
    
    -- Clear state
    holdingTarget[carrier.UserId] = nil
    holdingCarrier[target.UserId] = nil
    
    -- Notify clients
    ThrowRemote:FireClient(carrier, "Dropped", {targetId = target.UserId})
    ThrowRemote:FireClient(target, "WasDropped", {})
end

----------------------------------------------------
-- CLEANUP
----------------------------------------------------
local function cleanupPlayer(p: Player)
    if holdingTarget[p.UserId] then
        dropTarget(p)
    end
    
    local carrier = holdingCarrier[p.UserId]
    if carrier then
        holdingTarget[carrier.UserId] = nil
        holdingCarrier[p.UserId] = nil
        
        -- Also clear tag for carrier if they were holding us
        local cChar = carrier.Character
        if cChar then
            CollectionService:RemoveTag(cChar, "IsHolding")
        end
    end
    
    -- Also clear tag if we were holding someone
    local myChar = p.Character
    if myChar then
        CollectionService:RemoveTag(myChar, "IsHolding")
        CollectionService:RemoveTag(myChar, "Interacting")
    end

    -- Stop and clear any active animation tracks
    if activeTracks[p.UserId] then
        pcall(function() activeTracks[p.UserId]:Stop(0) end)
        activeTracks[p.UserId] = nil
    end
    
    savedProps[p.UserId] = nil
    savedHum[p.UserId] = nil
end

----------------------------------------------------
-- REMOTE HANDLER
----------------------------------------------------
ThrowRemote.OnServerEvent:Connect(function(player: Player, action: string, data)
    if action == "Pickup" then
        local targetId = data and data.targetId
        if type(targetId) ~= "number" then return end
        
        local target = Players:GetPlayerByUserId(targetId)
        if not target or target == player then return end
        
        local ok, err = pickupForThrow(player, target)
        if not ok then
            ThrowRemote:FireClient(player, "Failed", {reason = err})
        end
        
    elseif action == "Throw" then
        throwTarget(player)
        
    elseif action == "Drop" then
        dropTarget(player)
    end
end)

----------------------------------------------------
-- PLAYER EVENTS
----------------------------------------------------
Players.PlayerAdded:Connect(function(p)
    p.CharacterAdded:Connect(function()
        task.wait(0.3)
        cleanupPlayer(p)
    end)
end)

Players.PlayerRemoving:Connect(function(p)
    cleanupPlayer(p)
end)

-- print("[ThrowSystem] Server ready")
