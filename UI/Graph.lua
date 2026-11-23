local _, addon = ...

local Graph = {}
Graph.__index = Graph
addon.Graph = Graph

local GraphLibrary = LibStub("LibGraph-2.0")
local FPS_COLOR = { 0.3, 0.85, 0.55, 1 }

local function FormatAxisLabel(label)
    local value = tonumber(label:GetText())
    if not value then
        return
    end

    -- Keep full precision in the samples; round only the displayed axis labels.
    if math.abs(value) < 0.05 then
        value = 0
    end
    local text = string.format("%.1f", value)
    text = text:gsub("%.0$", "")
    label:SetText(text)
end

function Graph:Create(parent)
    local frame = GraphLibrary:CreateGraphLine(nil, parent, "TOPLEFT", "TOPLEFT", 0, 0, 548, 230)
    frame:SetAutoScale(false)
    frame:SetYLabels(true, false)
    frame:SetGridColor({ 0.25, 0.28, 0.32, 0.5 })
    frame.XLabelsEnabled = true
    frame.LabelHook = FormatAxisLabel

    -- Refresh explicitly when data changes; no per-frame dirty-flag polling is needed.
    frame:SetScript("OnUpdate", nil)

    local placeholder = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    placeholder:SetPoint("CENTER")

    return setmetatable({ frame = frame, placeholder = placeholder }, self)
end

function Graph:Update(buffer, interval)
    if not self.frame:IsVisible() then
        return
    end

    local count = buffer:GetCount()
    local latest = buffer:Get(count)
    local points = {}
    local maximum = 0

    -- Copy in chronological order. LibGraph retains this snapshot by reference.
    for index = 1, count do
        local sample = buffer:Get(index)
        points[index] = { sample.time - latest.time, sample.value }
        maximum = math.max(maximum, sample.value)
    end

    -- Explicit non-zero ranges also handle empty histories, one point, and constant FPS.
    local timeRange = interval
    if count > 1 then
        timeRange = math.max(interval, latest.time - buffer:Get(1).time)
    end
    local upperBound = math.max(10, math.ceil(maximum * 1.1 / 10) * 10)

    local frame = self.frame
    frame:ResetData()
    frame:SetXAxis(-timeRange, 0)
    frame:SetYAxis(0, upperBound)
    frame:SetGridSpacing(timeRange / 4, upperBound / 4)
    if count > 0 then
        frame:AddDataSeries(points, FPS_COLOR, false)
    end
    frame:RefreshGraph()
    frame.NeedsUpdate = false

    if count < 2 then
        self.placeholder:SetText("Waiting for FPS samples...")
        self.placeholder:Show()
    else
        self.placeholder:Hide()
    end
end
