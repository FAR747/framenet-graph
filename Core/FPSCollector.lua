local _, addon = ...

local FPSCollector = {}
addon.FPSCollector = FPSCollector

function FPSCollector:Collect()
    addon.buffers.fps:Push({
        time = GetTime(),
        value = GetFramerate(),
    })

    -- Consumers can subscribe without coupling collection to the graphical interface.
    if self.OnSample then
        self:OnSample()
    end
end

function FPSCollector:RestartTimer()
    if self.timer then
        self.timer:Cancel()
    end

    self.timer = C_Timer.NewTicker(addon.Config:Get("fpsInterval"), function()
        self:Collect()
    end)
end

-- Repeated world-entry events must not create extra timers or samples.
function FPSCollector:Start()
    if self.timer then
        return
    end

    self:Collect()
    self:RestartTimer()
end
