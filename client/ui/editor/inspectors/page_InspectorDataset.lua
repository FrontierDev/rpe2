local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Client.UI = Addon.Client.UI or {}
Addon.Client.UI.Editor = Addon.Client.UI.Editor or {}

local DataEditor = Addon.Client.UI.Editor
local UI = Addon.UI or {}
local INSPECTOR_SIDE_PADDING = 8

function DataEditor:BuildDatasetInspectorPage(parent)
    if self.DatasetInspectorPage then
        return self.DatasetInspectorPage
    end

    self.DatasetInspectorPage = CreateFrame("Frame", "RPEDataEditorDatasetInspectorPage", parent)

    local root = UI.CreateLayout(UI.VerticalLayoutGroup, self.DatasetInspectorPage, "RPEDataEditorDatasetInspectorLayout", {
        spacing = 8,
        fitChildrenWidth = true,
    })
    UI.Utils.AnchorFill(root, self.DatasetInspectorPage, INSPECTOR_SIDE_PADDING, 0, INSPECTOR_SIDE_PADDING, 0)

    self.DatasetInspectorIdText = UI.CreateText(root:GetFrame(), "RPEDataEditorDatasetInspectorIdText", "ID: -", {
        fontFile = (UI.Constants and UI.Constants.FontFiles and UI.Constants.FontFiles.Default) or "Fonts\\FRIZQT__.TTF",
        fontSize = (UI.Constants and UI.Constants.FontSizes and UI.Constants.FontSizes.Body) or 8,
        textColor = UI.ResolveColor(nil, "text.secondary"),
        width = 208,
        height = 14,
        justifyH = "LEFT",
    })
    root:AddChild(self.DatasetInspectorIdText)

    self.DatasetInspectorEmptyText = UI.CreateText(root:GetFrame(), "RPEDataEditorDatasetInspectorEmptyText", "", {
        fontFile = (UI.Constants and UI.Constants.FontFiles and UI.Constants.FontFiles.Default) or "Fonts\\FRIZQT__.TTF",
        fontSize = (UI.Constants and UI.Constants.FontSizes and UI.Constants.FontSizes.Body) or 8,
        textColor = UI.ResolveColor(nil, "text.secondary"),
        width = 208,
        height = 40,
        justifyH = "LEFT",
        wordWrap = true,
    })
    root:AddChild(self.DatasetInspectorEmptyText)

    self:RefreshDatasetInspectorPage()
    return self.DatasetInspectorPage
end

function DataEditor:RefreshDatasetInspectorPage()
    local dataset = self:GetSelectedDataset()

    if self.DatasetInspectorIdText and self.DatasetInspectorIdText.SetText then
        self.DatasetInspectorIdText:SetText(("ID: %s"):format(dataset and dataset.id or "-"))
    end

    if self.DatasetInspectorEmptyText and self.DatasetInspectorEmptyText.SetText then
        if dataset then
            self.DatasetInspectorEmptyText:SetText("Dataset naming is handled in the left pane.")
        else
            self.DatasetInspectorEmptyText:SetText("Select a dataset to inspect it.")
        end
    end
end
