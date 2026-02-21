--[[
    ZIndex Constants
    Centralized layer management for UI components
    
    Usage:
    local ZIndex = require(ReplicatedStorage.Shared.ZIndex)
    ZIndex = ZIndex.POPUP
]]

local ZIndex = {
    -- Base layers (0-4)
    BACKGROUND = 0,
    BASE = 1,
    CONTENT = 2,
    
    -- Overlays (5-9)
    OVERLAY = 5,
    DROPDOWN = 8,
    
    -- Popups (10-19)
    POPUP = 10,
    POPUP_CONTENT = 11,
    POPUP_BUTTON = 15,
    
    -- Modals (20-29)
    MODAL = 20,
    MODAL_BACKGROUND = 21,
    MODAL_CONTENT = 22,
    MODAL_ACTIONS = 23,
    
    -- Critical elements (30-49)
    TOAST = 30,
    CLOSE_BUTTON = 40,
    
    -- Loading/Blocking (50)
    LOADING = 50,
}

return ZIndex
