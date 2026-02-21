--[[
    DayNightCycle Server Script
    Ultra-Realistic Day-Night Cycle v2.0
    Uses shared module for logic to ensure consistency.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DayNightCycle = require(ReplicatedStorage.Shared.DayNightCycle)

print("[DayNightCycle] Initializing server-side day-night cycle...")

-- Start the cycle on the server
DayNightCycle.Start()

-- Optional: You can override config here if needed for server
-- DayNightCycle.SetTimeSpeed(0.001)

print("[DayNightCycle] Server-side day-night cycle started via Shared Module!")
