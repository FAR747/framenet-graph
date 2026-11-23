local addonName, addon = ...

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:SetScript("OnEvent", function(self, event, loadedAddonName)
    if loadedAddonName ~= addonName then
        return
    end

    -- SavedVariables are available only after this addon's ADDON_LOADED event.
    if type(FrameNetGraphDB) ~= "table" then
        FrameNetGraphDB = {}
    end

    addon.db = FrameNetGraphDB
    addon.initialized = true

    SLASH_FRAMENETGRAPH1 = "/fng"
    SlashCmdList.FRAMENETGRAPH = function()
        print("FrameNet Graph: loaded. Data collection is not implemented yet.")
    end

    self:UnregisterEvent(event)
end)
