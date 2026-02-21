--[[
    NotificationView Component
    Shows game updates and changelogs
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Roact = require(ReplicatedStorage.Shared.Roact)
local Theme = require(ReplicatedStorage.Shared.Theme)
local UISounds = require(ReplicatedStorage.Shared.UISounds)
local ResponsiveUtil = require(ReplicatedStorage.Shared.ResponsiveUtil)

local NotificationView = {}

--[[
    UPDATE LOG - Edit your updates here!
    Format: { version = "x.x.x", date = "DD/MM/YYYY", title = "Title", changes = {"change1", "change2"} }
]]
local Updates = {
    {
        version = "1.2.0",
        date = "05 January 2026",
        title = "Music Update",
        isNew = true,
        changes = {
            "Added Music Player with playlist",
            "New UI improvements",
            "Bug fixes and performance improvements",
        }
    },
    {
        version = "1.1.0",
        date = "01 January 2026",
        title = "New Year Update",
        isNew = false,
        changes = {
            "Added Friends system",
            "New Shop items",
            "Improved inventory system",
        }
    },
    {
        version = "1.0.0",
        date = "25 December 2025",
        title = "Initial Release",
        isNew = false,
        changes = {
            "Game launched",
            "Basic UI system",
            "Player data saving",
        }
    },
}

local function createUpdateCard(props)
    local update = props.update
    local index = props.index
    
    local changeChildren = {
        Layout = Roact.createElement("UIListLayout", {
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 6)
        })
    }
    
    for i, change in ipairs(update.changes) do
        changeChildren["Change" .. i] = Roact.createElement("Frame", {
            Size = UDim2.new(1, 0, 0, 20),
            BackgroundTransparency = 1,
            LayoutOrder = i
        }, {
            Bullet = Roact.createElement("Frame", {
                Size = UDim2.new(0, 6, 0, 6),
                Position = UDim2.new(0, 0, 0, 7),
                BackgroundColor3 = update.isNew and Theme.Primary or Theme.TextMuted
            }, {
                Corner = Roact.createElement("UICorner", { CornerRadius = UDim.new(1, 0) })
            }),
            Text = Roact.createElement("TextLabel", {
                Size = UDim2.new(1, -14, 1, 0),
                Position = UDim2.new(0, 14, 0, 0),
                BackgroundTransparency = 1,
                Text = change,
                TextColor3 = Theme.TextSecondary,
                TextSize = 12,
                Font = Enum.Font.Gotham,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextWrapped = true
            })
        })
    end
    
    return Roact.createElement("Frame", {
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = Theme.BackgroundCard,
        BackgroundTransparency = 0.3,
        LayoutOrder = index
    }, {
        Corner = Roact.createElement("UICorner", { CornerRadius = UDim.new(0, 12) }),
        Stroke = update.isNew and Roact.createElement("UIStroke", {
            Color = Theme.Primary,
            Thickness = 1,
            Transparency = 0.5
        }) or nil,
        Padding = Roact.createElement("UIPadding", {
            PaddingTop = UDim.new(0, 14),
            PaddingBottom = UDim.new(0, 14),
            PaddingLeft = UDim.new(0, 14),
            PaddingRight = UDim.new(0, 14)
        }),
        
        Content = Roact.createElement("Frame", {
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1
        }, {
            Layout = Roact.createElement("UIListLayout", {
                SortOrder = Enum.SortOrder.LayoutOrder,
                Padding = UDim.new(0, 10)
            }),
            
            -- Header row: Title + Version + NEW badge
            Header = Roact.createElement("Frame", {
                Size = UDim2.new(1, 0, 0, 22),
                BackgroundTransparency = 1,
                LayoutOrder = 1
            }, {
                Title = Roact.createElement("TextLabel", {
                    Size = UDim2.new(0.6, 0, 1, 0),
                    BackgroundTransparency = 1,
                    Text = update.title,
                    TextColor3 = Theme.TextPrimary,
                    TextSize = 15,
                    Font = Enum.Font.GothamBold,
                    TextXAlignment = Enum.TextXAlignment.Left
                }),
                VersionBadge = Roact.createElement("Frame", {
                    Size = UDim2.new(0, 50, 0, 20),
                    Position = UDim2.new(1, 0, 0, 1),
                    AnchorPoint = Vector2.new(1, 0),
                    BackgroundColor3 = update.isNew and Theme.Primary or Theme.BackgroundLight,
                    BackgroundTransparency = update.isNew and 0.3 or 0.5
                }, {
                    Corner = Roact.createElement("UICorner", { CornerRadius = UDim.new(0, 6) }),
                    Label = Roact.createElement("TextLabel", {
                        Size = UDim2.new(1, 0, 1, 0),
                        BackgroundTransparency = 1,
                        Text = "v" .. update.version,
                        TextColor3 = update.isNew and Color3.new(1, 1, 1) or Theme.TextMuted,
                        TextSize = 11,
                        Font = Enum.Font.GothamBold
                    })
                }),
                NewBadge = update.isNew and Roact.createElement("Frame", {
                    Size = UDim2.new(0, 36, 0, 18),
                    Position = UDim2.new(1, -56, 0, 2),
                    AnchorPoint = Vector2.new(1, 0),
                    BackgroundColor3 = Color3.fromRGB(220, 60, 60)
                }, {
                    Corner = Roact.createElement("UICorner", { CornerRadius = UDim.new(0, 4) }),
                    Label = Roact.createElement("TextLabel", {
                        Size = UDim2.new(1, 0, 1, 0),
                        BackgroundTransparency = 1,
                        Text = "NEW",
                        TextColor3 = Color3.new(1, 1, 1),
                        TextSize = 10,
                        Font = Enum.Font.GothamBold
                    })
                }) or nil
            }),
            
            -- Date
            DateRow = Roact.createElement("TextLabel", {
                Size = UDim2.new(1, 0, 0, 14),
                BackgroundTransparency = 1,
                Text = update.date,
                TextColor3 = Theme.TextMuted,
                TextSize = 11,
                Font = Enum.Font.GothamMedium,
                TextXAlignment = Enum.TextXAlignment.Left,
                LayoutOrder = 2
            }),
            
            -- Divider
            Divider = Roact.createElement("Frame", {
                Size = UDim2.new(1, 0, 0, 1),
                BackgroundColor3 = Theme.StrokeColor,
                BackgroundTransparency = 0.7,
                LayoutOrder = 3
            }),
            
            -- Changes list
            Changes = Roact.createElement("Frame", {
                Size = UDim2.new(1, 0, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundTransparency = 1,
                LayoutOrder = 4
            }, changeChildren)
        })
    })
end

function NotificationView.create(props)
    props = props or {}
    local onClose = props.onClose
    
    local sizes = ResponsiveUtil.getSizes()
    local isPhone = ResponsiveUtil.isPhone()
    local isMobile = ResponsiveUtil.isMobile()
    
    -- Responsive sizes - smaller for phone to avoid overlap
    local panelWidth = isPhone and 280 or (isMobile and 340 or 400)
    local panelHeight = isPhone and 340 or (isMobile and 400 or 480)
    
    local updateChildren = {
        Layout = Roact.createElement("UIListLayout", {
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, isPhone and 8 or 12)
        })
    }
    
    for i, update in ipairs(Updates) do
        updateChildren["Update" .. i] = createUpdateCard({
            update = update,
            index = i,
            isPhone = isPhone
        })
    end
    
    return Roact.createElement("Frame", {
        Name = "NotificationView",
        Size = UDim2.new(0, panelWidth, 0, panelHeight),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = Theme.Background,
        BackgroundTransparency = 0.02
    }, {
        Corner = Roact.createElement("UICorner", { CornerRadius = UDim.new(0, isPhone and 12 or 16) }),
        Stroke = Roact.createElement("UIStroke", {
            Color = Theme.Primary,
            Thickness = isPhone and 1 or 2,
            Transparency = 0.5
        }),
        
        -- Header
        Header = Roact.createElement("Frame", {
            Size = UDim2.new(1, 0, 0, isPhone and 45 or 55),
            BackgroundTransparency = 1
        }, {
            Title = Roact.createElement("TextLabel", {
                Size = UDim2.new(1, -50, 0, 22),
                Position = UDim2.new(0, isPhone and 12 or 18, 0, isPhone and 12 or 16),
                BackgroundTransparency = 1,
                Text = "UPDATES",
                TextColor3 = Theme.TextPrimary,
                TextSize = isPhone and 16 or 18,
                Font = Enum.Font.GothamBold,
                TextXAlignment = Enum.TextXAlignment.Left
            }),
            Subtitle = Roact.createElement("TextLabel", {
                Size = UDim2.new(1, -50, 0, 12),
                Position = UDim2.new(0, isPhone and 12 or 18, 0, isPhone and 32 or 38),
                BackgroundTransparency = 1,
                Text = "Latest changes",
                TextColor3 = Theme.TextMuted,
                TextSize = isPhone and 10 or 11,
                Font = Enum.Font.Gotham,
                TextXAlignment = Enum.TextXAlignment.Left
            }),
            CloseBtn = Roact.createElement("TextButton", {
                Size = UDim2.new(0, isPhone and 28 or 32, 0, isPhone and 28 or 32),
                Position = UDim2.new(1, isPhone and -12 or -18, 0, isPhone and 10 or 12),
                AnchorPoint = Vector2.new(1, 0),
                BackgroundColor3 = Theme.BackgroundLight,
                BackgroundTransparency = 0.5,
                Text = "X",
                TextColor3 = Theme.TextMuted,
                TextSize = isPhone and 12 or 14,
                Font = Enum.Font.GothamBold,
                Event = {
                    MouseButton1Click = function()
                        UISounds.close()
                        if onClose then onClose() end
                    end
                }
            }, {
                Corner = Roact.createElement("UICorner", { CornerRadius = UDim.new(0, 8) })
            })
        }),
        
        -- Divider line
        HeaderDivider = Roact.createElement("Frame", {
            Size = UDim2.new(1, -24, 0, 1),
            Position = UDim2.new(0, 12, 0, isPhone and 45 or 55),
            BackgroundColor3 = Theme.StrokeColor,
            BackgroundTransparency = 0.7
        }),
        
        -- Updates List
        UpdatesContainer = Roact.createElement("ScrollingFrame", {
            Size = UDim2.new(1, -20, 1, isPhone and -55 or -75),
            Position = UDim2.new(0, 10, 0, isPhone and 50 or 65),
            BackgroundTransparency = 1,
            ScrollBarThickness = 3,
            ScrollBarImageColor3 = Theme.Primary,
            CanvasSize = UDim2.new(0, 0, 0, 0),
            AutomaticCanvasSize = Enum.AutomaticSize.Y
        }, updateChildren)
    })
end

-- Get count of new updates (for badge)
function NotificationView.getNewCount()
    local count = 0
    for _, update in ipairs(Updates) do
        if update.isNew then
            count = count + 1
        end
    end
    return count
end

return NotificationView
