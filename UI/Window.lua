local _, addon = ...

local Window = {}
addon.Window = Window

local FPS_SERIES = {
    { key = "value", color = { 0.3, 0.85, 0.55, 1 } },
}
local NETWORK_SERIES = {
    { key = "home", name = "Home", color = { 0.3, 0.7, 1, 1 } },
    { key = "world", name = "World", color = { 1, 0.65, 0.25, 1 } },
}

local function CreateSection(parent, title, topOffset, series, waitingText)
    local section = CreateFrame("Frame", nil, parent)
    section:SetPoint("TOPLEFT", 20, -topOffset)
    section:SetSize(600, 244)

    local heading = section:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    heading:SetPoint("TOPLEFT")
    heading:SetText(title)

    for index, dataSeries in ipairs(series) do
        if dataSeries.name then
            local legend = section:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            legend:SetPoint("TOPRIGHT", -((#series - index) * 70), 0)
            legend:SetText(dataSeries.name)
            legend:SetTextColor(unpack(dataSeries.color))
        end
    end

    local summary = section:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    summary:SetPoint("TOPLEFT", 0, -20)

    local graph = addon.Graph:Create(section, series, waitingText)
    graph.frame:ClearAllPoints()
    graph.frame:SetPoint("TOPLEFT", 40, -52)
    graph.frame:SetSize(548, 164)

    local axisLabel = section:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    axisLabel:SetPoint("TOP", 0, -240)
    axisLabel:SetText("Time before latest sample (seconds)")

    return graph, summary
end

function Window:Create()
    local frame = CreateFrame("Frame", "FrameNetGraphWindow", UIParent, "BackdropTemplate")
    frame:Hide()
    frame:SetSize(640, 580)
    frame:SetPoint("CENTER")
    frame:SetFrameStrata("DIALOG")
    frame:SetMovable(true)
    frame:SetClampedToScreen(true)
    frame:EnableMouse(true)
    frame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = false,
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 },
    })
    frame:SetBackdropColor(0.04, 0.05, 0.07, 0.96)
    frame:SetBackdropBorderColor(0.4, 0.45, 0.5, 1)
    self.frame = frame

    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 18, -16)
    title:SetText("FrameNet Graph")

    local dragArea = CreateFrame("Frame", nil, frame)
    dragArea:SetPoint("TOPLEFT", 8, -6)
    dragArea:SetPoint("TOPRIGHT", -36, -6)
    dragArea:SetHeight(32)
    dragArea:EnableMouse(true)
    dragArea:RegisterForDrag("LeftButton")
    dragArea:SetScript("OnDragStart", function() frame:StartMoving() end)
    dragArea:SetScript("OnDragStop", function() frame:StopMovingOrSizing() end)

    local closeButton = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    closeButton:SetPoint("TOPRIGHT", -4, -4)
    closeButton:SetScript("OnClick", function() frame:Hide() end)
    table.insert(UISpecialFrames, "FrameNetGraphWindow")

    self.networkGraph, self.networkSummary = CreateSection(frame, "Network latency (ms)", 46,
        NETWORK_SERIES, "Waiting for network samples...")
    self.fpsGraph, self.fpsSummary = CreateSection(frame, "FPS", 310,
        FPS_SERIES, "Waiting for FPS samples...")

    frame:SetScript("OnShow", function() self:Refresh() end)
    frame:SetScript("OnHide", function() frame:StopMovingOrSizing() end)
end

function Window:Toggle()
    if not self.frame then
        self:Create()
    end

    if self.frame:IsShown() then
        self.frame:Hide()
    else
        self.frame:Show()
    end
end

function Window:Refresh()
    self:RefreshFPS()
    self:RefreshNetwork()
end

function Window:RefreshFPS()
    if not self.frame or not self.frame:IsVisible() then
        return
    end

    local buffer = addon.buffers.fps
    local interval = addon.Config:Get("fpsInterval")
    local latest = buffer:Get(buffer:GetCount())
    if latest then
        self.fpsSummary:SetText(string.format("FPS: %.1f  |  History: %d/%d  |  Interval: %g s",
            latest.value, buffer:GetCount(), buffer:GetCapacity(), interval))
    else
        self.fpsSummary:SetText("FPS: waiting for the first sample")
    end
    self.fpsGraph:Update(buffer, interval)
end

function Window:RefreshNetwork()
    if not self.frame or not self.frame:IsVisible() then
        return
    end

    local buffer = addon.buffers.network
    local interval = addon.Config:Get("networkInterval")
    local latest = buffer:Get(buffer:GetCount())
    if latest then
        self.networkSummary:SetText(string.format("Home: %d ms  |  World: %d ms  |  History: %d/%d  |  Interval: %g s",
            latest.home, latest.world, buffer:GetCount(), buffer:GetCapacity(), interval))
    else
        self.networkSummary:SetText("Network: waiting for the first sample")
    end
    self.networkGraph:Update(buffer, interval)
end
