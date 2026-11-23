local _, addon = ...

local Config = {}
addon.Config = Config

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

    self.settings = settings
    return settings
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
