--[[
    DonateView Component
    Shows donation options using Roblox Developer Products
    Prices are fetched from MarketplaceService
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Roact = require(ReplicatedStorage.Shared.Roact)
local Theme = require(ReplicatedStorage.Shared.Theme)
local UISounds = require(ReplicatedStorage.Shared.UISounds)
local ResponsiveUtil = require(ReplicatedStorage.Shared.ResponsiveUtil)

local DonateView = {}

--[[
    DONATION PRODUCTS - Edit here!
    Format: { id = PRODUCT_ID, name = "Name", tier = 1-6 }
    Price will be fetched automatically from Roblox!
]]
local DonationProducts = {
    { id = 3503991801, name = "Small Tip", tier = 1 },
    { id = 3503990734, name = "Coffee", tier = 2 },
    { id = 3503992286, name = "Snack", tier = 3 },
    { id = 3503992585, name = "Meal", tier = 4 },
    { id = 3503994453, name = "Big Support", tier = 5 },
    { id = 3503994803, name = "Super Fan", tier = 6 },
}

-- Cache for product info
local productInfoCache = {}
local cacheLoaded = false

-- Fetch product info from Roblox
local function fetchProductInfo()
    if cacheLoaded then return end
    
    for _, product in ipairs(DonationProducts) do
        task.spawn(function()
            local success, info = pcall(function()
                return MarketplaceService:GetProductInfo(product.id, Enum.InfoType.Product)
            end)
            
            if success and info then
                productInfoCache[product.id] = {
                    price = info.PriceInRobux or 0,
                    name = info.Name or product.name,
                    description = info.Description or ""
                }
            else
                productInfoCache[product.id] = { price = 0, name = product.name }
            end
        end)
    end
    
    cacheLoaded = true
end

-- Get price for a product (from cache or fallback)
local function getProductPrice(productId)
    local cached = productInfoCache[productId]
    if cached then
        return cached.price
    end
    return 0
end

-- Prompt purchase
function DonateView.promptDonation(productId)
    if productId == 0 then
        return
    end
    
    local player = Players.LocalPlayer
    if player then
        pcall(function()
            MarketplaceService:PromptProductPurchase(player, productId)
        end)
    end
end

-- Initialize - fetch product info
fetchProductInfo()

local function createDonateButton(props)
    local product = props.product
    local layoutOrder = props.layoutOrder or 0
    local price = getProductPrice(product.id)
    local priceText = price > 0 and ("R$ " .. price) or "..."
    local itemHeight = props.itemHeight or 52
    local isPhone = props.isPhone or false
    local tier = product.tier or 1
    
    -- Tier colors (gradient from light to premium)
    local tierColors = {
        Theme.BackgroundLight,
        Color3.fromRGB(60, 70, 90),
        Color3.fromRGB(70, 80, 100),
        Color3.fromRGB(80, 90, 110),
        Color3.fromRGB(90, 100, 130),
        Color3.fromRGB(100, 80, 140),
    }
    local bgColor = tierColors[tier] or Theme.BackgroundLight
    
    return Roact.createElement("TextButton", {
        Size = UDim2.new(1, 0, 0, itemHeight),
        BackgroundColor3 = bgColor,
        BackgroundTransparency = 0.3,
        Text = "",
        LayoutOrder = layoutOrder,
        AutoButtonColor = false,
        Event = {
            MouseButton1Click = function(rbx)
                UISounds.click()
                DonateView.promptDonation(product.id)
                -- Click animation
                TweenService:Create(rbx, TweenInfo.new(0.1), {
                    Size = UDim2.new(1, -8, 0, itemHeight - 4)
                }):Play()
                task.delay(0.1, function()
                    TweenService:Create(rbx, TweenInfo.new(0.15, Enum.EasingStyle.Back), {
                        Size = UDim2.new(1, 0, 0, itemHeight)
                    }):Play()
                end)
            end,
            MouseEnter = function(rbx)
                TweenService:Create(rbx, TweenInfo.new(0.15), {
                    BackgroundTransparency = 0.1
                }):Play()
            end,
            MouseLeave = function(rbx)
                TweenService:Create(rbx, TweenInfo.new(0.15), {
                    BackgroundTransparency = 0.3
                }):Play()
            end
        }
    }, {
        Corner = Roact.createElement("UICorner", { CornerRadius = UDim.new(0, 8) }),
        Stroke = Roact.createElement("UIStroke", {
            Color = Theme.StrokeColor,
            Thickness = 1,
            Transparency = 0.7
        }),
        
        -- Tier indicator (small bar on left)
        TierBar = Roact.createElement("Frame", {
            Size = UDim2.new(0, 4, 1, -8),
            Position = UDim2.new(0, 4, 0, 4),
            BackgroundColor3 = Theme.Primary
        }, {
            Corner = Roact.createElement("UICorner", { CornerRadius = UDim.new(0, 2) })
        }),
        
        -- Product name
        ProductName = Roact.createElement("TextLabel", {
            Size = UDim2.new(1, isPhone and -80 or -100, 0, 20),
            Position = UDim2.new(0, 16, 0.5, 0),
            AnchorPoint = Vector2.new(0, 0.5),
            BackgroundTransparency = 1,
            Text = product.name,
            TextColor3 = Theme.TextPrimary,
            TextSize = isPhone and 13 or 14,
            Font = Theme.FontBold,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd
        }),
        
        -- Price tag
        PriceTag = Roact.createElement("Frame", {
            Size = UDim2.new(0, isPhone and 60 or 70, 0, isPhone and 26 or 28),
            Position = UDim2.new(1, -8, 0.5, 0),
            AnchorPoint = Vector2.new(1, 0.5),
            BackgroundColor3 = Theme.Success
        }, {
            Corner = Roact.createElement("UICorner", { CornerRadius = UDim.new(0, 6) }),
            Price = Roact.createElement("TextLabel", {
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                Text = priceText,
                TextColor3 = Color3.new(1, 1, 1),
                TextSize = isPhone and 11 or 12,
                Font = Theme.FontBold
            })
        })
    })
end

function DonateView.create(props)
    props = props or {}
    local onClose = props.onClose
    
    local sizes = ResponsiveUtil.getSizes()
    local isPhone = ResponsiveUtil.isPhone()
    local isMobile = ResponsiveUtil.isMobile()
    
    -- Responsive sizes - smaller to avoid overlap
    local panelWidth = isPhone and 240 or (isMobile and 260 or 280)
    local panelHeight = isPhone and 350 or (isMobile and 400 or 430)
    local itemHeight = isPhone and 44 or 50
    
    local productButtons = {
        Layout = Roact.createElement("UIListLayout", {
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, isPhone and 5 or 6)
        })
    }
    
    for i, product in ipairs(DonationProducts) do
        productButtons["Product" .. i] = createDonateButton({
            product = product,
            layoutOrder = i,
            itemHeight = itemHeight,
            isPhone = isPhone
        })
    end
    
    -- Top offset to position below TopRightStatus and avoid hotbar
    local topOffset = isPhone and 90 or (isMobile and 85 or 80)
    
    return Roact.createElement("Frame", {
        Name = "DonateView",
        Size = UDim2.new(0, panelWidth, 0, panelHeight),
        Position = UDim2.new(1, -10, 0, topOffset),
        AnchorPoint = Vector2.new(1, 0),
        BackgroundColor3 = Theme.Background,
        BackgroundTransparency = 0.05
    }, {
        Corner = Roact.createElement("UICorner", { CornerRadius = UDim.new(0, isPhone and 10 or 12) }),
        Stroke = Roact.createElement("UIStroke", {
            Color = Theme.Primary,
            Thickness = isPhone and 1 or 2,
            Transparency = 0.5
        }),
        
        -- Header
        Header = Roact.createElement("Frame", {
            Size = UDim2.new(1, 0, 0, isPhone and 50 or 60),
            BackgroundColor3 = Theme.Primary,
            BackgroundTransparency = 0.4
        }, {
            Corner = Roact.createElement("UICorner", { CornerRadius = UDim.new(0, isPhone and 12 or 14) }),
            Title = Roact.createElement("TextLabel", {
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                Text = "SUPPORT",
                TextColor3 = Theme.TextPrimary,
                TextSize = isPhone and 16 or 18,
                Font = Theme.FontBold
            })
        }),
        
        -- Subtitle
        Subtitle = Roact.createElement("TextLabel", {
            Size = UDim2.new(1, -16, 0, isPhone and 28 or 32),
            Position = UDim2.new(0, 8, 0, isPhone and 52 or 62),
            BackgroundTransparency = 1,
            Text = "Help us improve the game!",
            TextColor3 = Theme.TextMuted,
            TextSize = isPhone and 10 or 11,
            Font = Theme.FontRegular,
            TextWrapped = true,
            TextXAlignment = Enum.TextXAlignment.Center
        }),
        
        -- Products list
        ProductList = Roact.createElement("ScrollingFrame", {
            Size = UDim2.new(1, -16, 1, isPhone and -88 or -102),
            Position = UDim2.new(0, 8, 0, isPhone and 82 or 96),
            BackgroundTransparency = 1,
            ScrollBarThickness = 3,
            ScrollBarImageColor3 = Theme.Primary,
            CanvasSize = UDim2.new(0, 0, 0, 0),
            AutomaticCanvasSize = Enum.AutomaticSize.Y
        }, productButtons)
    })
end

return DonateView
