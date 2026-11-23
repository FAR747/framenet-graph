local _, addon = ...

local MinimapLauncher = {}
addon.Minimap = MinimapLauncher

local BROKER_NAME = "FrameNetGraph"

function MinimapLauncher:Initialize()
    local broker = LibStub("LibDataBroker-1.1", true)
    local icons = LibStub("LibDBIcon-1.0", true)
    if not broker or not icons then
        return
    end

    local launcher = broker:NewDataObject(BROKER_NAME, {
        type = "launcher",
        label = "FrameNet Graph",
        text = "FrameNet Graph",
        icon = "Interface\\Icons\\INV_Gizmo_02",
        OnClick = function(_, button)
            if button == "LeftButton" then
                addon.Window:Toggle()
            elseif button == "RightButton" then
                addon.Settings:Open()
            end
        end,
        OnTooltipShow = function(tooltip)
            tooltip:AddLine("FrameNet Graph")
            tooltip:AddLine("Left-click: toggle monitoring window", 1, 1, 1)
            tooltip:AddLine("Right-click: open settings", 1, 1, 1)
            tooltip:AddLine("Drag: move the minimap button", 1, 1, 1)
        end,
    })

    -- LibDBIcon writes its drag position directly into this SavedVariables table.
    icons:Register(BROKER_NAME, launcher, addon.Config:GetMinimapState())
    self.icons = icons
end

function MinimapLauncher:SetVisible(visible)
    addon.Config:GetMinimapState().hide = not visible
    if self.icons then
        if visible then
            self.icons:Show(BROKER_NAME)
        else
            self.icons:Hide(BROKER_NAME)
        end
    end
end
