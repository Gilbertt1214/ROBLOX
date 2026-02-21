--[[
    Tools Setup Script
    Creates the Tools folder in ReplicatedStorage
    Tools are added dynamically when players pick up items from the world
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- print("[ToolsSetup] Initializing...")

-- Create Tools folder (tools will be added when picked up from world)
local toolsFolder = ReplicatedStorage:FindFirstChild("Tools")
if not toolsFolder then
    toolsFolder = Instance.new("Folder")
    toolsFolder.Name = "Tools"
    toolsFolder.Parent = ReplicatedStorage
    -- print("[ToolsSetup] Created Tools folder")
end

-- print("[ToolsSetup] Ready - tools will be added when picked up from WorldItems")
