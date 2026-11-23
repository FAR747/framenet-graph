local _, addon = ...

local Config = {}
addon.Config = Config

local windowDefaults = { width = 640, height = 580, x = 0, y = 0 }

local function SanitizeWindowState(saved)
    if type(saved) ~= "table" then
        saved = {}
    end

    local state = {}
    for key, default in pairs(windowDefaults) do
        local value = saved[key]
        local valid = type(value) == "number" and value == value
            and value > -math.huge and value < math.huge
        if valid and (key == "width" or key == "height") then
            valid = value > 0
        end
        state[key] = valid and value or default
    end
    return state
end

local rules = {
    fpsInterval = { default = 1, minimum = 1 },
    networkInterval = { default = 30, minimum = 30 },
    fpsCapacity = { default = 200, minimum = 2, maximum = 2000, integer = true },
    networkCapacity = { default = 200, minimum = 2, maximum = 2000, integer = true },
}

local function Validate(name, value)
    local rule = rules[name]
    if not rule then
        return false, "Unknown setting: " .. tostring(name)
    end

    -- NaN is the only number that is not equal to itself.
    if type(value) ~= "number" or value ~= value or value == math.huge or value == -math.huge then
        return false, name .. " must be a finite number."
    end

    if value < rule.minimum then
        return false, name .. " must be at least " .. rule.minimum .. "."
    end

    if rule.maximum and value > rule.maximum then
        return false, name .. " must be at most " .. rule.maximum .. "."
    end

    if rule.integer and value ~= math.floor(value) then
        return false, name .. " must be a whole number."
    end

    return true
end

-- Only known settings are persisted. Invalid saved values fall back to defaults.
function Config:Initialize(saved)
    if type(saved) ~= "table" then
        saved = {}
    end

    local settings = {}
    for name, rule in pairs(rules) do
        local value = saved[name]
        if not Validate(name, value) then
            value = rule.default
        end
        settings[name] = value
    end

    settings.window = SanitizeWindowState(saved.window)
    self.settings = settings
    return settings
end

function Config:GetWindowState()
    return self.settings.window
end

function Config:SaveWindowState(width, height, x, y)
    self.settings.window = SanitizeWindowState({ width = width, height = height, x = x, y = y })
end

function Config:Get(name)
    return self.settings[name]
end

-- Invalid updates leave the current configuration unchanged.
function Config:Set(name, value)
    local valid, message = Validate(name, value)
    if not valid then
        return false, message
    end

    self.settings[name] = value
    return true
end
