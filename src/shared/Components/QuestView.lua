--[[
    QuestView Component
    Displays real quest data with progress
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Roact = require(ReplicatedStorage.Shared.Roact)
local Theme = require(ReplicatedStorage.Shared.Theme)
local ResponsiveUtil = require(ReplicatedStorage.Shared.ResponsiveUtil)

local QuestView = {}

local function createQuestItem(props)
    local quest = props.quest
    local title = quest.title or "Unknown Quest"
    local progress = quest.progress or 0
    local target = quest.target or 1
    local reward = quest.reward or 0
    local completed = progress >= target
    local isPhone = props.isPhone or false
    
    local percentage = math.clamp(progress / target, 0, 1)
    local itemHeight = isPhone and 60 or 75

    return Roact.createElement("Frame", {
        Size = UDim2.new(1, 0, 0, itemHeight),
        BackgroundColor3 = Theme.BackgroundLight,
        BackgroundTransparency = completed and 0.7 or 0.5,
    }, {
        Corner = Roact.createElement("UICorner", { CornerRadius = UDim.new(0, 8) }),
        Padding = Roact.createElement("UIPadding", {
            PaddingLeft = UDim.new(0, isPhone and 8 or 12),
            PaddingRight = UDim.new(0, isPhone and 8 or 12),
            PaddingTop = UDim.new(0, isPhone and 4 or 8),
            PaddingBottom = UDim.new(0, isPhone and 4 or 8),
        }),
        Title = Roact.createElement("TextLabel", {
            Size = UDim2.new(0.7, 0, 0, 18),
            Text = title .. (completed and " ✓" or ""),
            TextColor3 = completed and Theme.Success or Theme.TextPrimary,
            TextSize = isPhone and 12 or 14,
            Font = Theme.FontBold,
            TextXAlignment = Enum.TextXAlignment.Left,
            BackgroundTransparency = 1,
            TextTruncate = Enum.TextTruncate.AtEnd
        }),
        Reward = Roact.createElement("TextLabel", {
            Size = UDim2.new(0.3, 0, 0, 18),
            Position = UDim2.new(1, 0, 0, 0),
            AnchorPoint = Vector2.new(1, 0),
            Text = "+" .. tostring(reward) .. " Rp.",
            TextColor3 = Theme.Warning,
            TextSize = isPhone and 10 or 12,
            Font = Theme.FontMedium,
            TextXAlignment = Enum.TextXAlignment.Right,
            BackgroundTransparency = 1
        }),
        ProgressBarBG = Roact.createElement("Frame", {
            Size = UDim2.new(1, 0, 0, isPhone and 8 or 10),
            Position = UDim2.new(0, 0, 0, isPhone and 22 or 30),
            BackgroundColor3 = Color3.fromRGB(0, 0, 0),
            BackgroundTransparency = 0.5,
        }, {
            Corner = Roact.createElement("UICorner", { CornerRadius = UDim.new(1, 0) }),
            Fill = Roact.createElement("Frame", {
                Size = UDim2.new(percentage, 0, 1, 0),
                BackgroundColor3 = completed and Theme.Success or Theme.Primary,
            }, {
                Corner = Roact.createElement("UICorner", { CornerRadius = UDim.new(1, 0) })
            })
        }),
        ProgressText = Roact.createElement("TextLabel", {
            Size = UDim2.new(1, 0, 0, 14),
            Position = UDim2.new(0, 0, 0, isPhone and 32 or 45),
            Text = progress .. " / " .. target,
            TextColor3 = Theme.TextSecondary,
            TextSize = isPhone and 9 or 10,
            Font = Theme.FontMedium,
            TextXAlignment = Enum.TextXAlignment.Center,
            BackgroundTransparency = 1
        })
    })
end

function QuestView.create(props)
    local quests = props.quests or {}
    
    local sizes = ResponsiveUtil.getSizes()
    local isPhone = ResponsiveUtil.isPhone()
    local isMobile = ResponsiveUtil.isMobile()
    
    -- Responsive sizes - smaller for phone
    local panelWidth = isPhone and 260 or (isMobile and 340 or 450)
    local panelHeight = isPhone and 260 or (isMobile and 300 or 350)
    local titleSize = sizes.fontSize.title
    
    local children = {
        Layout = Roact.createElement("UIListLayout", {
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, isPhone and 6 or 10)
        }),
    }
    
    for i, quest in ipairs(quests) do
        children["Quest_" .. i] = createQuestItem({ 
            quest = quest,
            isPhone = isPhone
        })
    end
    
    if #quests == 0 then
        children.EmptyMessage = Roact.createElement("TextLabel", {
            Size = UDim2.new(1, 0, 1, 0),
            Text = "No active quests",
            TextColor3 = Theme.TextSecondary,
            TextSize = sizes.fontSize.medium,
            Font = Theme.FontMedium,
            BackgroundTransparency = 1
        })
    end
    
    return Roact.createElement("Frame", {
        Name = "QuestView",
        Size = UDim2.new(0, panelWidth, 0, panelHeight),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = Theme.Background,
        BackgroundTransparency = 0.1,
    }, {
        Corner = Roact.createElement("UICorner", { CornerRadius = UDim.new(0, isPhone and 12 or 16) }),
        Title = Roact.createElement("TextLabel", {
            Size = UDim2.new(1, 0, 0, isPhone and 40 or 50),
            Text = "QUESTS",
            TextColor3 = Color3.fromRGB(34, 197, 94),
            TextSize = titleSize,
            Font = Theme.FontBold,
            BackgroundTransparency = 1
        }),
        Container = Roact.createElement("ScrollingFrame", {
            Size = UDim2.new(1, -20, 1, isPhone and -50 or -70),
            Position = UDim2.new(0, 10, 0, isPhone and 45 or 60),
            BackgroundTransparency = 1,
            ScrollBarThickness = 2,
            CanvasSize = UDim2.new(0, 0, 0, 0),
            AutomaticCanvasSize = Enum.AutomaticSize.Y
        }, children)
    })
end

return QuestView
