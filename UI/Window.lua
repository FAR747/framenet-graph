local _, addon = ...

local Window = {}
addon.Window = Window

function Window:Create()
    local frame = CreateFrame("Frame", "FrameNetGraphWindow", UIParent, "BackdropTemplate")
    frame:Hide()
    frame:SetSize(640, 360)
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
    title:SetText("FrameNet Graph - FPS")

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

    local summary = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    summary:SetPoint("TOPLEFT", 20, -42)
    self.summary = summary

    local graph = addon.Graph:Create(frame)
    graph.frame:ClearAllPoints()
    graph.frame:SetPoint("TOPLEFT", 60, -70)
    graph.frame:SetPoint("BOTTOMRIGHT", -24, 54)
    self.graph = graph

    local axisLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    axisLabel:SetPoint("BOTTOM", 0, 16)
    axisLabel:SetText("Time before latest sample (seconds)")

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
    if not self.frame or not self.frame:IsVisible() then
        return
    end

    local buffer = addon.buffers.fps
    local interval = addon.Config:Get("fpsInterval")
    local latest = buffer:Get(buffer:GetCount())
    if latest then
        self.summary:SetText(string.format("FPS: %.1f  |  History: %d/%d  |  Interval: %g s",
            latest.value, buffer:GetCount(), buffer:GetCapacity(), interval))
    else
        self.summary:SetText("FPS: waiting for the first sample")
    end
    self.graph:Update(buffer, interval)
end
