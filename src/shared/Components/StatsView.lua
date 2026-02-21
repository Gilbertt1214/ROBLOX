--[[
    StatsView Component
    Displays real player statistics
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Roact = require(ReplicatedStorage.Shared.Roact)
local Theme = require(ReplicatedStorage.Shared.Theme)
local ResponsiveUtil = require(ReplicatedStorage.Shared.ResponsiveUtil)

local StatsView = {}

local function formatPlaytime(seconds)
    local hours = math.floor(seconds / 3600)
    local minutes = math.floor((seconds % 3600) / 60)
    return string.format("%dh %dm", hours, minutes)
end

local function createStatRow(props)
    local label = props.label
    local value = props.value
    local rowHeight = props.rowHeight or 40
    local isPhone = props.isPhone or false
    
    return Roact.createElement("Frame", {
        Size = UDim2.new(1, 0, 0, rowHeight),
        BackgroundTransparency = 1,
    }, {
        Label = Roact.createElement("TextLabel", {
            Size = UDim2.new(0.6, 0, 1, 0),
            Text = label,
            TextColor3 = Theme.TextSecondary,
            TextSize = isPhone and 12 or 14,
            Font = Theme.FontMedium,
            TextXAlignment = Enum.TextXAlignment.Left,
            BackgroundTransparency = 1
        }),
        Value = Roact.createElement("TextLabel", {
            Size = UDim2.new(0.4, 0, 1, 0),
            Position = UDim2.new(1, 0, 0, 0),
            AnchorPoint = Vector2.new(1, 0),
            Text = tostring(value),
            TextColor3 = Theme.TextPrimary,
            TextSize = isPhone and 14 or 16,
            Font = Theme.FontBold,
            TextXAlignment = Enum.TextXAlignment.Right,
            BackgroundTransparency = 1
        }),
        Line = Roact.createElement("Frame", {
            Size = UDim2.new(1, 0, 0, 1),
            Position = UDim2.new(0, 0, 1, 0),
            BackgroundColor3 = Theme.StrokeColor,
            BackgroundTransparency = 0.8
        })
    })
end

function StatsView.create(props)
    local stats = props.stats or {}
    local level = stats.level or 1
    local xp = stats.xp or 0
    local xpMax = stats.xpMax or 100
    local kills = stats.kills or 0
    local deaths = stats.deaths or 0
    local playtime = stats.playtime or 0
    
    local kdr = deaths > 0 and string.format("%.2f", kills / deaths) or tostring(kills)
    
    local sizes = ResponsiveUtil.getSizes()
    local isPhone = ResponsiveUtil.isPhone()
    local isMobile = ResponsiveUtil.isMobile()
    
    -- Responsive sizes - smaller for phone
    local panelWidth = isPhone and 260 or (isMobile and 320 or 400)
    local panelHeight = isPhone and 250 or (isMobile and 300 or 350)
    local rowHeight = isPhone and 32 or 40
    
    local children = {
        Layout = Roact.createElement("UIListLayout", {
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, isPhone and 3 or 5)
        }),
        Level = createStatRow({ label = "Level", value = level, rowHeight = rowHeight, isPhone = isPhone }),
        XP = createStatRow({ label = "Experience", value = xp .. " / " .. xpMax, rowHeight = rowHeight, isPhone = isPhone }),
        Kills = createStatRow({ label = "Total Kills", value = kills, rowHeight = rowHeight, isPhone = isPhone }),
        Deaths = createStatRow({ label = "Total Deaths", value = deaths, rowHeight = rowHeight, isPhone = isPhone }),
        KDR = createStatRow({ label = "K/D Ratio", value = kdr, rowHeight = rowHeight, isPhone = isPhone }),
        Playtime = createStatRow({ label = "Playtime", value = formatPlaytime(playtime), rowHeight = rowHeight, isPhone = isPhone }),
    }
    
    return Roact.createElement("Frame", {
        Name = "StatsView",
        Size = UDim2.new(0, panelWidth, 0, panelHeight),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = Theme.Background,
        BackgroundTransparency = 0.1,
    }, {
        Corner = Roact.createElement("UICorner", { CornerRadius = UDim.new(0, isPhone and 12 or 16) }),
        Title = Roact.createElement("TextLabel", {
            Size = UDim2.new(1, 0, 0, isPhone and 40 or 50),
            Text = "STATISTICS",
            TextColor3 = Theme.PrimaryLight,
            TextSize = sizes.fontSize.title,
            Font = Theme.FontBold,
            BackgroundTransparency = 1
        }),
        Container = Roact.createElement("Frame", {
            Size = UDim2.new(1, -30, 1, isPhone and -55 or -80),
            Position = UDim2.new(0, 15, 0, isPhone and 45 or 60),
            BackgroundTransparency = 1,
        }, children)
    })
end

return StatsView
