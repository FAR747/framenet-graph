local _, addon = ...

local NetworkCollector = {}
addon.NetworkCollector = NetworkCollector

function NetworkCollector:Collect()
    -- The first two returns are bandwidth; latency occupies the third and fourth.
    local _, _, home, world = GetNetStats()
    addon.buffers.network:Push({
        time = GetTime(),
        home = home,
        world = world,
    })

    if self.OnSample then
        self:OnSample()
    end
end

function NetworkCollector:RestartTimer()
    if self.timer then
        self.timer:Cancel()
    end

    self.timer = C_Timer.NewTicker(addon.Config:Get("networkInterval"), function()
        self:Collect()
    end)
end

function NetworkCollector:Start()
    if self.timer then
        return
    end

    self:Collect()
    self:RestartTimer()
end
