local addonName, addon = ...

-- Keep configuration and live buffer sizes in sync through one update entry point.
function addon:SetSetting(name, value)
    local previousValue = self.Config:Get(name)
    local valid, message = self.Config:Set(name, value)
    if not valid then
        return false, message
    end

    if value == previousValue then
        return true
    end

    if name == "fpsCapacity" then
        self.buffers.fps:Resize(value)
    elseif name == "networkCapacity" then
        self.buffers.network:Resize(value)
    elseif name == "fpsInterval" and self.FPSCollector.timer then
        self.FPSCollector:RestartTimer()
    elseif name == "networkInterval" and self.NetworkCollector.timer then
        self.NetworkCollector:RestartTimer()
    end

    return true
end

local function PrintStatus()
    local fpsBuffer = addon.buffers.fps
    local networkBuffer = addon.buffers.network

    if addon.FPSCollector.timer and addon.NetworkCollector.timer then
        print("FrameNet Graph: collecting.")
    else
        print("FrameNet Graph: waiting to enter the world.")
    end

    print(string.format("FPS: interval %g s, history %d/%d.",
        addon.Config:Get("fpsInterval"), fpsBuffer:GetCount(), fpsBuffer:GetCapacity()))
    print(string.format("Network: interval %g s, history %d/%d.",
        addon.Config:Get("networkInterval"), networkBuffer:GetCount(), networkBuffer:GetCapacity()))

    local fpsSample = fpsBuffer:Get(fpsBuffer:GetCount())
    if fpsSample then
        print(string.format("Latest FPS: %.1f (%.1f s ago).",
            fpsSample.value, GetTime() - fpsSample.time))
    end

    local networkSample = networkBuffer:Get(networkBuffer:GetCount())
    if networkSample then
        print(string.format("Latest latency: Home %d ms, World %d ms (%.1f s ago).",
            networkSample.home, networkSample.world, GetTime() - networkSample.time))
    end
end

local function HandleCommand(message)
    local command = message:match("^%s*(.-)%s*$")
    if command == "" or command == "status" or command == "settings" then
        PrintStatus()
        return
    end

    local name, value = command:match("^set%s+(%S+)%s+(%S+)$")
    if name then
        local valid, errorMessage = addon:SetSetting(name, tonumber(value))
        if valid then
            print("FrameNet Graph: " .. name .. " = " .. addon.Config:Get(name))
        else
            print("FrameNet Graph: " .. errorMessage)
        end
        return
    end

    print("FrameNet Graph: /fng status | /fng settings | /fng set <setting> <value>")
    print("Settings: fpsInterval, networkInterval, fpsCapacity, networkCapacity")
end

local function Initialize()
    -- SavedVariables are available only after this addon's ADDON_LOADED event.
    FrameNetGraphDB = addon.Config:Initialize(FrameNetGraphDB)
    addon.db = FrameNetGraphDB
    addon.buffers = {
        fps = addon.RingBuffer:New(addon.Config:Get("fpsCapacity")),
        network = addon.RingBuffer:New(addon.Config:Get("networkCapacity")),
    }
    addon.initialized = true

    SLASH_FRAMENETGRAPH1 = "/fng"
    SlashCmdList.FRAMENETGRAPH = HandleCommand
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:SetScript("OnEvent", function(self, event, loadedAddonName)
    if event == "ADDON_LOADED" then
        if loadedAddonName ~= addonName then
            return
        end

        Initialize()
        self:UnregisterEvent(event)
    elseif event == "PLAYER_ENTERING_WORLD" and addon.initialized then
        addon.FPSCollector:Start()
        addon.NetworkCollector:Start()
        self:UnregisterEvent(event)
    end
end)
