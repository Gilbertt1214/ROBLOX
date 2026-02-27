-- --[[
--     Custom Cursor Client Script
--     Implementasi kursor kustom menggunakan ScreenGui agar bisa dikontrol ukuran, 
--     warna, dan perilakunya saat berada di atas tombol.
-- ]]

-- local Players = game:GetService("Players")
-- local RunService = game:GetService("RunService")
-- local UserInputService = game:GetService("UserInputService")

-- local LocalPlayer = Players.LocalPlayer
-- local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- -- Configuration
-- local CURSOR_ID = "rbxassetid://114676072354170" -- ID cursor baru dari user
-- local CURSOR_SIZE = UDim2.new(0, 7, 0, 7)        -- Ukuran kecil (7x7)

-- -- Create Cursor GUI
-- local function createCursor()
--     -- Hapus cursor lama jika ada
--     local oldCursor = PlayerGui:FindFirstChild("CustomCursorGui")
--     if oldCursor then oldCursor:Destroy() end

--     local screenGui = Instance.new("ScreenGui")
--     screenGui.Name = "CustomCursorGui"
--     screenGui.DisplayOrder = 999 -- Pastikan di atas segalanya
--     screenGui.IgnoreGuiInset = true
--     screenGui.ResetOnSpawn = false
--     screenGui.Parent = PlayerGui

--     local cursorImg = Instance.new("ImageLabel")
--     cursorImg.Name = "Cursor"
--     cursorImg.AnchorPoint = Vector2.new(0.5, 0.5)
--     cursorImg.BackgroundTransparency = 1
--     cursorImg.Image = CURSOR_ID
--     cursorImg.Size = CURSOR_SIZE
--     cursorImg.ZIndex = 999
--     cursorImg.Parent = screenGui

--     -- Sembunyikan kursor default
--     UserInputService.MouseIconEnabled = false

--     -- Update posisi kursor setiap frame
--     RunService.RenderStepped:Connect(function()
--         local mousePos = UserInputService:GetMouseLocation()
--         cursorImg.Position = UDim2.new(0, mousePos.X, 0, mousePos.Y)
--     end)

--     -- Pastikan kursor default tetap tersembunyi
--     UserInputService:GetPropertyChangedSignal("MouseIconEnabled"):Connect(function()
--         if UserInputService.MouseIconEnabled then
--             UserInputService.MouseIconEnabled = false
--         end
--     end)

--     return screenGui
-- end

-- -- Initialize
-- createCursor()
