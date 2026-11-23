local addonName, addon = ...

-- Keep configuration and live buffer sizes in sync through one update entry point.
function addon:SetSetting(name, value)
    local valid, message = self.Config:Set(name, value)
    if not valid then
        return false, message
    end

    if name == "fpsCapacity" then
        self.buffers.fps:Resize(value)
    elseif name == "networkCapacity" then
        self.buffers.network:Resize(value)
    end

    return true
end

local function PrintStatus()
    local fpsBuffer = addon.buffers.fps
    local networkBuffer = addon.buffers.network

    print("FrameNet Graph: loaded. Data collection is not implemented yet.")
    print(string.format("FPS: interval %g s, history %d/%d.",
        addon.Config:Get("fpsInterval"), fpsBuffer:GetCount(), fpsBuffer:GetCapacity()))
    print(string.format("Network: interval %g s, history %d/%d.",
        addon.Config:Get("networkInterval"), networkBuffer:GetCount(), networkBuffer:GetCapacity()))
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
eventFrame:SetScript("OnEvent", function(self, event, loadedAddonName)
    if loadedAddonName ~= addonName then
        return
    end

    Initialize()
    self:UnregisterEvent(event)
end)
