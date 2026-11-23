local _, addon = ...

local Window = {}
addon.Window = Window

local MINIMUM_WIDTH = 640
local MINIMUM_HEIGHT = 500

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

    local summary = section:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    summary:SetPoint("TOPLEFT", 0, -20)

    local statisticsLabels = {}
    for index, dataSeries in ipairs(series) do
        local label = section:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        label:SetPoint("TOPLEFT", 0, -(36 + (index - 1) * 16))
        label:SetTextColor(unpack(dataSeries.color))
        statisticsLabels[index] = label
    end

    local graph = addon.Graph:Create(section, series, waitingText)
    graph.frame:ClearAllPoints()
    graph.frame:SetPoint("TOPLEFT", 40, -84)
    graph.frame:SetSize(548, 132)

    local axisLabel = section:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    axisLabel:SetPoint("TOP", graph.frame, "BOTTOM", 0, -22)
    axisLabel:SetText("Time before latest sample (seconds)")

    return graph, summary, section, statisticsLabels
end

local function UpdateStatistics(labels, series, buffer, unit)
    for index, dataSeries in ipairs(series) do
        local name = dataSeries.name or "FPS"
        local statistics = addon.Statistics:Calculate(buffer, dataSeries.key)
        if statistics then
            labels[index]:SetText(string.format("%s Min/Avg/Max: %.1f / %.1f / %.1f %s",
                name, statistics.minimum, statistics.average, statistics.maximum, unit))
        else
            labels[index]:SetText(name .. " Min/Avg/Max: - / - / - " .. unit)
        end
    end
end

function Window:Create()
    local frame = CreateFrame("Frame", "FrameNetGraphWindow", UIParent, "BackdropTemplate")
    frame:Hide()
    frame:SetSize(640, 580)
    frame:SetPoint("CENTER")
    frame:SetFrameStrata("DIALOG")
    frame:SetMovable(true)
    frame:SetResizable(true)
    frame:SetClampedToScreen(true)
    frame:SetUserPlaced(false)
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
    dragArea:SetScript("OnDragStop", function() self:FinishInteraction() end)

    local closeButton = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    closeButton:SetPoint("TOPRIGHT", -4, -4)
    closeButton:SetScript("OnClick", function() frame:Hide() end)
    table.insert(UISpecialFrames, "FrameNetGraphWindow")

    self.networkGraph, self.networkSummary, self.networkSection, self.networkStatistics = CreateSection(frame, "Network latency (ms)", 46,
        NETWORK_SERIES, "Waiting for network samples...")
    self.fpsGraph, self.fpsSummary, self.fpsSection, self.fpsStatistics = CreateSection(frame, "FPS", 310,
        FPS_SERIES, "Waiting for FPS samples...")

    local resizeGrip = CreateFrame("Button", nil, frame)
    resizeGrip:SetSize(20, 20)
    resizeGrip:SetPoint("BOTTOMRIGHT", 0, 0)
    resizeGrip:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    resizeGrip:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
    resizeGrip:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
    resizeGrip:SetScript("OnMouseDown", function(_, button)
        if button == "LeftButton" then
            frame:StartSizing("BOTTOMRIGHT")
        end
    end)
    resizeGrip:SetScript("OnMouseUp", function(_, button)
        if button == "LeftButton" then
            self:FinishInteraction()
        end
    end)

    frame:SetScript("OnSizeChanged", function(_, width, height) self:Layout(width, height) end)
    self:Layout(frame:GetWidth(), frame:GetHeight())
    frame:SetScript("OnShow", function()
        self:RestoreGeometry()
        self:Refresh()
    end)
    frame:SetScript("OnHide", function() self:FinishInteraction() end)
    frame:RegisterEvent("PLAYER_LOGOUT")
    frame:SetScript("OnEvent", function() self:FinishInteraction() end)
end

function Window:RestoreGeometry()
    local state = addon.Config:GetWindowState()
    local screenWidth = UIParent:GetWidth()
    local screenHeight = UIParent:GetHeight()
    local minimumWidth = math.min(MINIMUM_WIDTH, screenWidth)
    local minimumHeight = math.min(MINIMUM_HEIGHT, screenHeight)
    local width = math.min(screenWidth, math.max(minimumWidth, state.width))
    local height = math.min(screenHeight, math.max(minimumHeight, state.height))

    -- Center-relative offsets use UIParent coordinates and remain independent of drag anchors.
    local maximumX = (screenWidth - width) / 2
    local maximumY = (screenHeight - height) / 2
    local x = math.max(-maximumX, math.min(maximumX, state.x))
    local y = math.max(-maximumY, math.min(maximumY, state.y))

    self.frame:SetResizeBounds(minimumWidth, minimumHeight, screenWidth, screenHeight)
    self.frame:SetSize(width, height)
    self.frame:ClearAllPoints()
    self.frame:SetPoint("CENTER", UIParent, "CENTER", x, y)
end

function Window:FinishInteraction()
    self.frame:StopMovingOrSizing()
    self.frame:SetUserPlaced(false)

    local centerX, centerY = self.frame:GetCenter()
    local screenX, screenY = UIParent:GetCenter()
    if not centerX or not centerY or not screenX or not screenY then
        return
    end

    addon.Config:SaveWindowState(self.frame:GetWidth(), self.frame:GetHeight(),
        centerX - screenX, centerY - screenY)
end

function Window:Layout(width, height)
    local sectionWidth = width - 40
    local sectionHeight = (height - 92) / 2

    self.networkSection:SetSize(sectionWidth, sectionHeight)
    self.fpsSection:SetSize(sectionWidth, sectionHeight)
    self.fpsSection:ClearAllPoints()
    self.fpsSection:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 20, -(46 + sectionHeight + 20))

    local graphWidth = sectionWidth - 52
    local graphHeight = sectionHeight - 112
    self.networkGraph:Resize(graphWidth, graphHeight)
    self.fpsGraph:Resize(graphWidth, graphHeight)
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
    UpdateStatistics(self.fpsStatistics, FPS_SERIES, buffer, "FPS")
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
    UpdateStatistics(self.networkStatistics, NETWORK_SERIES, buffer, "ms")
    self.networkGraph:Update(buffer, interval)
end
