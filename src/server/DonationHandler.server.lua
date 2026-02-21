--[[
    Donation Handler
    Processes Developer Product purchases and broadcasts to all players
]]

local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Create remote event for broadcasting donations
local remotesFolder = ReplicatedStorage:WaitForChild("Remotes", 10)
if not remotesFolder then
    remotesFolder = Instance.new("Folder")
    remotesFolder.Name = "Remotes"
    remotesFolder.Parent = ReplicatedStorage
end

local donationEvent = remotesFolder:FindFirstChild("DonationMade")
if not donationEvent then
    donationEvent = Instance.new("RemoteEvent")
    donationEvent.Name = "DonationMade"
    donationEvent.Parent = remotesFolder
end

-- Product info cache
local productCache = {}

-- Get product info
local function getProductInfo(productId)
    if productCache[productId] then
        return productCache[productId]
    end
    
    local success, info = pcall(function()
        return MarketplaceService:GetProductInfo(productId, Enum.InfoType.Product)
    end)
    
    if success and info then
        productCache[productId] = {
            name = info.Name,
            price = info.PriceInRobux or 0
        }
        return productCache[productId]
    end
    
    return { name = "Donation", price = 0 }
end

-- Handle product purchase
MarketplaceService.ProcessReceipt = function(receiptInfo)
    local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
    if not player then
        return Enum.ProductPurchaseDecision.NotProcessedYet
    end
    
    local productId = receiptInfo.ProductId
    local productInfo = getProductInfo(productId)
    
    print("[Donation]", player.Name, "purchased", productInfo.name, "for R$", productInfo.price)
    
    -- Broadcast to ALL players
    for _, p in pairs(Players:GetPlayers()) do
        donationEvent:FireClient(p, player.Name, productInfo.name, productInfo.price)
    end
    
    -- You can add rewards here
    -- Example: Give the donor some in-game currency bonus
    local PlayerData = require(ReplicatedStorage.Shared.PlayerData)
    local data = PlayerData.get(player)
    if data then
        -- Give 10% of Robux spent as in-game currency bonus
        local bonus = math.floor(productInfo.price * 10)
        PlayerData.addCurrency(player, bonus)
        print("[Donation] Gave", player.Name, bonus, "bonus currency")
    end
    
    return Enum.ProductPurchaseDecision.PurchaseGranted
end

print("[DonationHandler] Initialized")
