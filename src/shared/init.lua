-- Shared module example
-- This can be required by both server and client (ReplicatedStorage)

local Shared = {}

Shared.GameName = "Jawir Hangout"
Shared.Version = "1.0.0"

function Shared.formatTime(seconds)
	local minutes = math.floor(seconds / 60)
	local secs = seconds % 60
	return string.format("%02d:%02d", minutes, secs)
end

return Shared
