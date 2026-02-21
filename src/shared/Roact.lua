--[[
    React Lua Implementation
    Modern React-style library with hooks support
    
    Supports:
    - Functional Components with Hooks
    - Class Components (legacy support)
    - useState, useEffect, useRef, useMemo, useCallback
    - Managed event handling
]]

local React = {}
React.__index = React

-- Event key for bracket syntax [React.Event.EventName]
React.Event = setmetatable({}, {
    __index = function(_, eventName)
        return { __eventKey = eventName }
    end
})

-- Current component context for hooks
local currentFiber = nil
local hookIndex = 0

--============================================
-- HOOKS IMPLEMENTATION
--============================================

function React.useState(initialValue)
    local fiber = currentFiber
    local idx = hookIndex
    hookIndex = hookIndex + 1
    
    -- Initialize state if first render
    if fiber.hooks[idx] == nil then
        fiber.hooks[idx] = {
            state = type(initialValue) == "function" and initialValue() or initialValue
        }
    end
    
    local hook = fiber.hooks[idx]
    
    local function setState(newValue)
        local nextState
        if type(newValue) == "function" then
            nextState = newValue(hook.state)
        else
            nextState = newValue
        end
        
        if nextState ~= hook.state then
            hook.state = nextState
            -- Trigger re-render
            if fiber._handle then
                task.spawn(function()
                    React.update(fiber._handle, fiber._handle.element)
                end)
            end
        end
    end
    
    return hook.state, setState
end

function React.useEffect(callback, deps)
    local fiber = currentFiber
    local idx = hookIndex
    hookIndex = hookIndex + 1
    
    local hook = fiber.hooks[idx]
    local hasChanged = true
    
    if hook then
        if deps then
            hasChanged = false
            local oldDeps = hook.deps or {}
            for i, dep in ipairs(deps) do
                if dep ~= oldDeps[i] then
                    hasChanged = true
                    break
                end
            end
        end
    else
        fiber.hooks[idx] = {}
        hook = fiber.hooks[idx]
    end
    
    if hasChanged then
        -- Cleanup previous effect
        if hook.cleanup then
            hook.cleanup()
        end
        
        hook.deps = deps
        
        -- Run effect after render
        task.defer(function()
            local cleanup = callback()
            if type(cleanup) == "function" then
                hook.cleanup = cleanup
            end
        end)
    end
end

function React.useRef(initialValue)
    local fiber = currentFiber
    local idx = hookIndex
    hookIndex = hookIndex + 1
    
    if fiber.hooks[idx] == nil then
        fiber.hooks[idx] = { current = initialValue }
    end
    
    return fiber.hooks[idx]
end

function React.useMemo(factory, deps)
    local fiber = currentFiber
    local idx = hookIndex
    hookIndex = hookIndex + 1
    
    local hook = fiber.hooks[idx]
    local hasChanged = true
    
    if hook then
        if deps then
            hasChanged = false
            local oldDeps = hook.deps or {}
            for i, dep in ipairs(deps) do
                if dep ~= oldDeps[i] then
                    hasChanged = true
                    break
                end
            end
        end
    else
        fiber.hooks[idx] = {}
        hook = fiber.hooks[idx]
    end
    
    if hasChanged then
        hook.value = factory()
        hook.deps = deps
    end
    
    return hook.value
end

function React.useCallback(callback, deps)
    return React.useMemo(function()
        return callback
    end, deps)
end

--============================================
-- COMPONENT BASE CLASS (Legacy Support)
--============================================

local Component = {}
Component.__index = Component

function Component:extend(name)
    local NewComponent = setmetatable({}, Component)
    NewComponent.__index = NewComponent
    NewComponent.className = name or "Component"
    NewComponent._isClassComponent = true
    return NewComponent
end

function Component:setState(newState)
    if type(newState) == "function" then
        newState = newState(self.state)
    end
    for key, value in pairs(newState) do
        self.state[key] = value
    end
    
    if self._handle then
        task.spawn(function()
            React.update(self._handle, self:render())
        end)
    end
end

function Component:init() end
function Component:render() return nil end
function Component:didMount() end
function Component:willUnmount() end

React.Component = Component

--============================================
-- CORE FUNCTIONS
--============================================

local function applyProps(instance, props, oldProps, eventConnections)
    oldProps = oldProps or {}
    
    for propName, propValue in pairs(props) do
        -- Handle [React.Event.EventName] syntax
        if type(propName) == "table" and propName.__eventKey then
            local eventName = propName.__eventKey
            local connectionKey = eventName
            if eventConnections[connectionKey] then
                eventConnections[connectionKey]:Disconnect()
            end
            eventConnections[connectionKey] = instance[eventName]:Connect(function(...)
                propValue(instance, ...)
            end)
        elseif propName == "Event" then
            for eventName, callback in pairs(propValue) do
                local connectionKey = eventName
                if eventConnections[connectionKey] then
                    eventConnections[connectionKey]:Disconnect()
                end
                eventConnections[connectionKey] = instance[eventName]:Connect(function(...)
                    callback(instance, ...)
                end)
            end
        elseif propName == "ref" then
            -- Handle refs
            if type(propValue) == "table" and propValue.current ~= nil then
                propValue.current = instance
            elseif type(propValue) == "function" then
                propValue(instance)
            end
        elseif propName ~= "children" then
            if propValue ~= oldProps[propName] then
                pcall(function()
                    instance[propName] = propValue
                end)
            end
        end
    end
    
    -- Cleanup old Event table events
    if oldProps.Event then
        for eventName, _ in pairs(oldProps.Event) do
            if not props.Event or not props.Event[eventName] then
                if eventConnections[eventName] then
                    eventConnections[eventName]:Disconnect()
                    eventConnections[eventName] = nil
                end
            end
        end
    end
    
    -- Cleanup old [React.Event.X] events
    for propName, _ in pairs(oldProps) do
        if type(propName) == "table" and propName.__eventKey then
            local eventName = propName.__eventKey
            local hasNewEvent = false
            for newPropName, _ in pairs(props) do
                if type(newPropName) == "table" and newPropName.__eventKey == eventName then
                    hasNewEvent = true
                    break
                end
            end
            if not hasNewEvent and eventConnections[eventName] then
                eventConnections[eventName]:Disconnect()
                eventConnections[eventName] = nil
            end
        end
    end
end

function React.createElement(component, props, children)
    local element = {
        component = component,
        props = props or {},
        children = {}
    }
    
    if children ~= nil then
        if type(children) == "table" and children.component == nil then
            element.children = children
        else
            element.children = { [1] = children }
        end
    end
    
    return element
end

-- Alias for JSX-like syntax
React.create = React.createElement

function React.mount(element, parent, key)
    local handle = {
        element = element,
        instance = nil,
        children = {},
        eventConnections = {},
        componentInstance = nil,
        fiber = nil
    }

    if type(element.component) == "string" then
        -- Host component (Roblox Instance)
        local instance = Instance.new(element.component)
        instance.Name = key or element.component
        handle.instance = instance
        
        applyProps(instance, element.props, nil, handle.eventConnections)
        
        for childKey, child in pairs(element.children) do
            if type(child) == "table" and child.component then
                handle.children[childKey] = React.mount(child, instance, tostring(childKey))
            end
        end
        
        instance.Parent = parent
        
    elseif type(element.component) == "table" and element.component._isClassComponent then
        -- Class Component (legacy)
        local componentInstance = setmetatable({}, element.component)
        componentInstance.props = element.props
        componentInstance.state = {}
        componentInstance._handle = handle
        componentInstance:init()
        handle.componentInstance = componentInstance
        
        local rendered = componentInstance:render()
        if rendered then
            local childHandle = React.mount(rendered, parent, key)
            handle.instance = childHandle.instance
            handle.children["_root"] = childHandle
            componentInstance:didMount()
        end
        
    elseif type(element.component) == "function" then
        -- Functional Component with Hooks
        local fiber = {
            hooks = {},
            _handle = handle
        }
        handle.fiber = fiber
        
        -- Set current fiber for hooks
        currentFiber = fiber
        hookIndex = 0
        
        local rendered = element.component(element.props)
        
        currentFiber = nil
        
        if rendered then
            local childHandle = React.mount(rendered, parent, key)
            handle.instance = childHandle.instance
            handle.children["_root"] = childHandle
        end
    end
    
    return handle
end

function React.update(handle, newElement)
    local oldElement = handle.element
    
    if not newElement then
        if handle.instance and handle.instance.Parent then
            React.unmount(handle)
        end
        return handle
    end
    
    if oldElement.component ~= newElement.component then
        if handle.instance and handle.instance.Parent then
            local parent = handle.instance.Parent
            local key = handle.instance.Name
            React.unmount(handle)
            local newHandle = React.mount(newElement, parent, key)
            for k, v in pairs(newHandle) do handle[k] = v end
        end
        return handle
    end

    handle.element = newElement
    
    if type(newElement.component) == "string" then
        if handle.instance then
            applyProps(handle.instance, newElement.props, oldElement.props, handle.eventConnections)
        end
        
        local newChildren = newElement.children
        local oldChildHandles = handle.children
        
        for childKey, childHandle in pairs(oldChildHandles) do
            if not newChildren[childKey] then
                React.unmount(childHandle)
                oldChildHandles[childKey] = nil
            end
        end
        
        for childKey, childElement in pairs(newChildren) do
            if oldChildHandles[childKey] then
                React.update(oldChildHandles[childKey], childElement)
            elseif type(childElement) == "table" and childElement.component then
                oldChildHandles[childKey] = React.mount(childElement, handle.instance, tostring(childKey))
            end
        end
        
    elseif handle.componentInstance then
        -- Class component
        handle.componentInstance.props = newElement.props
        local rendered = handle.componentInstance:render()
        if rendered and handle.children["_root"] then
            React.update(handle.children["_root"], rendered)
        end
        
    elseif handle.fiber then
        -- Functional component with hooks
        currentFiber = handle.fiber
        hookIndex = 0
        
        local rendered = newElement.component(newElement.props)
        
        currentFiber = nil
        
        if rendered and handle.children["_root"] then
            React.update(handle.children["_root"], rendered)
        end
    end
    
    return handle
end

function React.unmount(handle)
    if handle.eventConnections then
        for _, connection in pairs(handle.eventConnections) do
            connection:Disconnect()
        end
        handle.eventConnections = {}
    end

    -- Cleanup hooks effects
    if handle.fiber then
        for _, hook in pairs(handle.fiber.hooks) do
            if hook.cleanup then
                hook.cleanup()
            end
        end
    end

    if handle.componentInstance then
        handle.componentInstance:willUnmount()
    end
    
    if handle.children then
        for _, childHandle in pairs(handle.children) do
            React.unmount(childHandle)
        end
    end
    
    if handle.instance and handle.instance:IsA("Instance") then
        handle.instance:Destroy()
    end
end

-- Create ref helper
function React.createRef()
    return { current = nil }
end

-- Backward compatibility aliases
local Roact = React
Roact.mount = React.mount
Roact.unmount = React.unmount
Roact.update = React.update
Roact.createElement = React.createElement
Roact.Component = React.Component
Roact.createRef = React.createRef

return Roact
