local _, addon = ...

local SettingsPage = {}
addon.Settings = SettingsPage

local fields = {
    { key = "fpsInterval", label = "FPS sampling interval (seconds)",
        description = "At least 1 second. Decimal values are allowed." },
    { key = "networkInterval", label = "Network sampling interval (seconds)",
        description = "At least 30 seconds. Decimal values are allowed." },
    { key = "fpsCapacity", label = "FPS history capacity",
        description = "2-2000 samples. Reducing capacity keeps the newest samples." },
    { key = "networkCapacity", label = "Network history capacity",
        description = "2-2000 samples. Reducing capacity keeps the newest samples." },
}

function SettingsPage:RefreshField(key)
    local input = self.inputs and self.inputs[key]
    if input and not input:HasFocus() then
        input:SetText(tostring(addon.Config:Get(key)))
    end
end

function SettingsPage:Refresh()
    for _, field in ipairs(fields) do
        self.inputs[field.key]:SetText(tostring(addon.Config:Get(field.key)))
    end
    self.minimapCheckbox:SetChecked(not addon.Config:GetMinimapState().hide)
    self.errorLabel:SetText("")
end

function SettingsPage:ApplyField(key, input)
    local valid, message = addon:SetSetting(key, tonumber(input:GetText()))
    if not valid then
        self.errorLabel:SetText(message)
        return false
    end

    input:SetText(tostring(addon.Config:Get(key)))
    self.errorLabel:SetText("")
    return true
end

function SettingsPage:ResetCollection()
    for _, field in ipairs(fields) do
        addon:SetSetting(field.key, addon.Config:GetDefault(field.key))
    end
    self:Refresh()
end

function SettingsPage:Initialize()
    local panel = CreateFrame("Frame")
    panel:Hide()
    self.panel = panel
    self.inputs = {}

    local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText("FrameNet Graph")

    local description = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    description:SetPoint("TOPLEFT", 16, -48)
    description:SetText("Press Enter or leave a field to apply changes. Escape cancels an edit.")

    local errorLabel = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    errorLabel:SetPoint("TOPLEFT", 16, -444)
    errorLabel:SetPoint("TOPRIGHT", -16, -444)
    errorLabel:SetJustifyH("LEFT")
    errorLabel:SetTextColor(1, 0.3, 0.3)
    self.errorLabel = errorLabel

    for index, field in ipairs(fields) do
        local top = 100 + (index - 1) * 68
        local label = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        label:SetPoint("TOPLEFT", 16, -top)
        label:SetText(field.label)

        local help = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        help:SetPoint("TOPLEFT", 16, -(top + 24))
        help:SetText(field.description)

        local key = field.key
        local input = CreateFrame("EditBox", nil, panel, "InputBoxTemplate")
        input:SetSize(130, 24)
        input:SetPoint("TOPLEFT", 360, -(top - 6))
        input:SetAutoFocus(false)
        input:SetMaxLetters(24)
        input:SetScript("OnEnterPressed", function()
            if self:ApplyField(key, input) then
                input:ClearFocus()
            end
        end)
        input:SetScript("OnEditFocusLost", function() self:ApplyField(key, input) end)
        input:SetScript("OnEscapePressed", function()
            input:SetText(tostring(addon.Config:Get(key)))
            input:ClearFocus()
        end)
        self.inputs[key] = input
    end

    local minimapCheckbox = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
    minimapCheckbox:SetSize(24, 24)
    minimapCheckbox:SetPoint("TOPLEFT", 12, -350)
    minimapCheckbox:SetScript("OnClick", function()
        addon.Minimap:SetVisible(minimapCheckbox:GetChecked())
    end)
    self.minimapCheckbox = minimapCheckbox

    local minimapLabel = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    minimapLabel:SetPoint("LEFT", minimapCheckbox, "RIGHT", 6, 0)
    minimapLabel:SetText("Show minimap button")

    local openButton = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    openButton:SetSize(220, 24)
    openButton:SetPoint("TOPLEFT", 16, -400)
    openButton:SetText("Open monitoring window")
    openButton:SetScript("OnClick", function()
        if not addon.Window.frame or not addon.Window.frame:IsShown() then
            addon.Window:Toggle()
        end
    end)

    local resetButton = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    resetButton:SetSize(220, 24)
    resetButton:SetPoint("LEFT", openButton, "RIGHT", 16, 0)
    resetButton:SetText("Reset collection settings")
    resetButton:SetScript("OnClick", function() self:ResetCollection() end)

    panel:SetScript("OnShow", function() self:Refresh() end)
    panel.OnRefresh = function() self:Refresh() end
    panel.OnDefault = function() self:ResetCollection() end
    self.category = Settings.RegisterCanvasLayoutCategory(panel, "FrameNet Graph")
    Settings.RegisterAddOnCategory(self.category)
end

function SettingsPage:Open()
    Settings.OpenToCategory(self.category:GetID())
end
