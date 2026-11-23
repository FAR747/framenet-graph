local _, addon = ...

local Statistics = {}
addon.Statistics = Statistics

-- The mean is arithmetic across retained samples, without weighting by time.
function Statistics:Calculate(buffer, key)
    local count = buffer:GetCount()
    if count == 0 then
        return nil
    end

    local minimum = math.huge
    local maximum = -math.huge
    local total = 0
    for index = 1, count do
        local value = buffer:Get(index)[key]
        minimum = math.min(minimum, value)
        maximum = math.max(maximum, value)
        total = total + value
    end

    return {
        minimum = minimum,
        average = total / count,
        maximum = maximum,
    }
end
