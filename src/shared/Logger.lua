--[[
    Logger Module
    Centralized error logging and debugging utilities
    
    Usage:
    local Logger = require(ReplicatedStorage.Shared.Logger)
    Logger.info("ModuleName", "Message here")
    Logger.error("ModuleName", "Something failed", errorDetails)
    
    -- Safe pcall with automatic logging:
    local success, result = Logger.safeCall("ModuleName", "operationName", function()
        return someRiskyOperation()
    end)
]]

local Logger = {}

-- Log levels
Logger.Level = {
    INFO = "INFO",
    WARN = "WARN",
    ERROR = "ERROR",
    DEBUG = "DEBUG"
}

-- Enable/disable debug logs (can be toggled in production)
Logger.DebugEnabled = false

-- Format log message with timestamp and module
local function formatMessage(level, module, message)
    local timestamp = os.date("%H:%M:%S")
    return string.format("[%s][%s][%s] %s", timestamp, level, module, message)
end

-- Info logging
function Logger.info(module, message)
    -- print(formatMessage(Logger.Level.INFO, module, message))
end

-- Warning logging
function Logger.warn(module, message)
    -- warn(formatMessage(Logger.Level.WARN, module, message))
end

-- Error logging with optional details
function Logger.error(module, message, details)
    -- warn(formatMessage(Logger.Level.ERROR, module, message))
    if details then
        -- warn("  └─ Details:", tostring(details))
    end
end

-- Debug logging (only when enabled)
function Logger.debug(module, message)
    if Logger.DebugEnabled then
        print(formatMessage(Logger.Level.DEBUG, module, message))
    end
end

-- Safe function call with automatic error logging
-- Returns: success (boolean), result (any)
function Logger.safeCall(module, operationName, func)
    local success, result = pcall(func)
    if not success then
        Logger.error(module, operationName .. " failed", result)
    end
    return success, result
end

-- Safe function call that returns default value on error
function Logger.safeCallWithDefault(module, operationName, func, defaultValue)
    local success, result = pcall(func)
    if not success then
        Logger.error(module, operationName .. " failed", result)
        return defaultValue
    end
    return result
end

-- Track performance of a function
function Logger.timed(module, operationName, func)
    local startTime = tick()
    local success, result = pcall(func)
    local elapsed = tick() - startTime
    
    if success then
        Logger.debug(module, string.format("%s completed in %.3fs", operationName, elapsed))
    else
        Logger.error(module, string.format("%s failed after %.3fs", operationName, elapsed), result)
    end
    
    return success, result
end

return Logger
