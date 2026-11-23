local _, addon = ...

local RingBuffer = {}
RingBuffer.__index = RingBuffer
addon.RingBuffer = RingBuffer

local function ValidateCapacity(capacity)
    assert(type(capacity) == "number" and capacity >= 1 and capacity < math.huge
        and capacity == math.floor(capacity), "Capacity must be a positive finite integer.")
end

function RingBuffer:New(capacity)
    ValidateCapacity(capacity)

    return setmetatable({
        capacity = capacity,
        count = 0,
        oldestIndex = 1,
        records = {},
    }, self)
end

function RingBuffer:GetCount()
    return self.count
end

function RingBuffer:GetCapacity()
    return self.capacity
end

-- Logical indices always run from the oldest sample (1) to the newest (count).
function RingBuffer:Get(index)
    if type(index) ~= "number" or index ~= math.floor(index) or index < 1 or index > self.count then
        return nil
    end

    -- Convert the logical position to a physical slot, wrapping at capacity.
    local slot = (self.oldestIndex + index - 2) % self.capacity + 1
    return self.records[slot]
end

-- Insertion overwrites the oldest slot in O(1), without shifting stored samples.
function RingBuffer:Push(sample)
    assert(sample ~= nil, "A sample cannot be nil.")

    local slot = (self.oldestIndex + self.count - 1) % self.capacity + 1
    self.records[slot] = sample

    if self.count == self.capacity then
        self.oldestIndex = self.oldestIndex % self.capacity + 1
    else
        self.count = self.count + 1
    end
end

-- Resizing is O(n) and retains the newest samples in chronological order.
function RingBuffer:Resize(capacity)
    ValidateCapacity(capacity)
    if capacity == self.capacity then
        return
    end

    local keptCount = math.min(self.count, capacity)
    local firstKeptIndex = self.count - keptCount + 1
    local records = {}
    for index = 1, keptCount do
        records[index] = self:Get(firstKeptIndex + index - 1)
    end

    self.capacity = capacity
    self.count = keptCount
    self.oldestIndex = 1
    self.records = records
end
