local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Client.UI = Addon.Client.UI or {}
Addon.Client.UI.Editor = Addon.Client.UI.Editor or {}

local DataEditor = Addon.Client.UI.Editor
local UI = Addon.UI or {}
local Client = Addon.Client or {}

local INSPECTOR_SIDE_PADDING = 8
local CONTROL_HEIGHT = 20

local function copyTable(values)
    local output = {}
    for index = 1, #(values or {}) do
        output[index] = values[index]
    end
    return output
end

local function commitSelectedWeaponType(self, mutate)
    local weaponType = self:GetSelectedWeaponType()
    local dataset = self:GetSelectedDataset()
    if not dataset or not weaponType or type(mutate) ~= "function" then
        return
    end

    mutate(weaponType, dataset)
    if self.Database and self.Database.NotifyDatasetEntryChanged then
        self.Database.NotifyDatasetEntryChanged(dataset.id, "weaponTypes", {
            deferConfigurationChanged = true,
        })
    end
    self:RefreshAfterDatasetEntryChanged("weaponTypes")
end

function DataEditor:BuildWeaponTypeInspectorPage(parent)
    if self.WeaponTypeInspectorPage then
        return self.WeaponTypeInspectorPage
    end

    self.WeaponTypeInspectorPage = CreateFrame("Frame", "RPEDataEditorWeaponTypeInspectorPage", parent)

    local root = UI.CreateLayout(UI.VerticalLayoutGroup, self.WeaponTypeInspectorPage, "RPEDataEditorWeaponTypeInspectorLayout", {
        spacing = 6,
        fitChildrenWidth = true,
        fitChildrenHeight = false,
    })
    UI.Utils.AnchorFill(root, self.WeaponTypeInspectorPage, INSPECTOR_SIDE_PADDING, 0, INSPECTOR_SIDE_PADDING, 0)

    root:AddChild(UI.CreateText(root:GetFrame(), "RPEDataEditorWeaponTypeInspectorNameLabel", "Name", {
        width = 236, height = 12, justifyH = "LEFT", textColor = UI.ResolveColor(nil, "text.secondary"),
    }))
    self.WeaponTypeInspectorNameInput = UI.CreateTextInput(root:GetFrame(), "RPEDataEditorWeaponTypeInspectorNameInput", {
        width = 236, height = CONTROL_HEIGHT, text = "", borderColor = UI.ResolveColor(nil, "panel.border"),
    })
    self.WeaponTypeInspectorNameInput:SetScript("OnEnterPressed", function()
        commitSelectedWeaponType(self, function(weaponType)
            weaponType.name = self.WeaponTypeInspectorNameInput:GetText()
        end)
    end)
    self.WeaponTypeInspectorNameInput:SetScript("OnEditFocusLost", function()
        commitSelectedWeaponType(self, function(weaponType)
            weaponType.name = self.WeaponTypeInspectorNameInput:GetText()
        end)
    end)
    root:AddChild(self.WeaponTypeInspectorNameInput)

    self.WeaponTypeInspectorIdText = UI.CreateText(root:GetFrame(), "RPEDataEditorWeaponTypeInspectorIdText", "ID: -", {
        width = 236, height = 12, justifyH = "LEFT", textColor = UI.ResolveColor(nil, "text.secondary"),
    })
    root:AddChild(self.WeaponTypeInspectorIdText)

    root:AddChild(UI.CreateText(root:GetFrame(), "RPEDataEditorWeaponTypeInspectorIconLabel", "Icon", {
        width = 236, height = 12, justifyH = "LEFT", textColor = UI.ResolveColor(nil, "text.secondary"),
    }))
    self.WeaponTypeInspectorIconField = UI.EditorIconField:New({
        name = "RPEDataEditorWeaponTypeInspectorIconField",
        width = 236,
        height = CONTROL_HEIGHT,
        buttonText = "Select Icon",
        labelText = "-",
        iconTexture = "Interface\\Icons\\INV_Misc_QuestionMark",
        border = false,
    })
    self.WeaponTypeInspectorIconField:SetParent(root:GetFrame())
    self.WeaponTypeInspectorIconField:Create()
    local iconButton = self.WeaponTypeInspectorIconField:GetButton()
    if iconButton and iconButton.SetScript then
        iconButton:SetScript("OnClick", function()
            local weaponType = self:GetSelectedWeaponType()
            if not weaponType or not Client.OpenIconFinder then
                return
            end

            Client:OpenIconFinder(function(_, filePath)
                commitSelectedWeaponType(self, function(selectedWeaponType)
                    selectedWeaponType.icon = filePath or ""
                end)
            end, {
                filter = weaponType.icon or "",
            })
        end)
    end
    root:AddChild(self.WeaponTypeInspectorIconField)

    root:AddChild(UI.CreateText(root:GetFrame(), "RPEDataEditorWeaponTypeInspectorSlotsLabel", "Allowed Slots", {
        width = 236, height = 12, justifyH = "LEFT", textColor = UI.ResolveColor(nil, "text.secondary"),
    }))
    self.WeaponTypeInspectorAllowedSlotsDropdown = UI.CreateDropdown(root:GetFrame(), "RPEDataEditorWeaponTypeInspectorAllowedSlotsDropdown", {
        width = 236,
        height = 18,
        items = self:BuildItemInspectorItemSlotItems(),
        multiSelect = true,
        showSelectionActions = false,
        onValueChanged = function(values)
            commitSelectedWeaponType(self, function(weaponType)
                weaponType.allowedSlotRefs = copyTable(values or {})
            end)
        end,
    })
    root:AddChild(self.WeaponTypeInspectorAllowedSlotsDropdown)

    self.WeaponTypeInspectorHintText = UI.CreateText(root:GetFrame(), "RPEDataEditorWeaponTypeInspectorHintText", "", {
        width = 236, height = 28, justifyH = "LEFT", wordWrap = true, textColor = UI.ResolveColor(nil, "text.secondary"),
    })
    root:AddChild(self.WeaponTypeInspectorHintText)

    self.WeaponTypeInspectorIconInput = {
        SetText = function(_, value)
            local iconPath = value ~= nil and tostring(value) or ""
            self.WeaponTypeInspectorIconField:SetIcon(iconPath ~= "" and iconPath or "Interface\\Icons\\INV_Misc_QuestionMark")
            self.WeaponTypeInspectorIconField:SetLabelText(iconPath ~= "" and iconPath or "-")
        end,
        SetEnabled = function(_, enabled)
            self.WeaponTypeInspectorIconField:SetEnabled(enabled)
        end,
        SetReadOnly = function(_, readOnly)
            self.WeaponTypeInspectorIconField:SetEnabled(readOnly ~= true)
        end,
    }

    self.WeaponTypeInspectorEmptyText = UI.CreateText(root:GetFrame(), "RPEDataEditorWeaponTypeInspectorEmptyText", "", {
        width = 236, height = 20, justifyH = "LEFT", textColor = UI.ResolveColor(nil, "text.secondary"),
    })
    root:AddChild(self.WeaponTypeInspectorEmptyText)

    self:RefreshWeaponTypeInspectorPage()
    return self.WeaponTypeInspectorPage
end

function DataEditor:RefreshWeaponTypeInspectorPage()
    local weaponType = self:GetSelectedWeaponType()
    local hasWeaponType = weaponType ~= nil

    if self.WeaponTypeInspectorNameInput then
        self.WeaponTypeInspectorNameInput:SetText(weaponType and (weaponType.name or "") or "")
        self.WeaponTypeInspectorNameInput:SetEnabled(hasWeaponType)
        self.WeaponTypeInspectorNameInput:SetReadOnly(not hasWeaponType)
    end
    if self.WeaponTypeInspectorIdText then
        self.WeaponTypeInspectorIdText:SetText(("ID: %s"):format(weaponType and tostring(weaponType.id or "") or "-"))
    end
    if self.WeaponTypeInspectorIconInput then
        self.WeaponTypeInspectorIconInput:SetText(weaponType and (weaponType.icon or "") or "")
        self.WeaponTypeInspectorIconInput:SetEnabled(hasWeaponType)
    end
    if self.WeaponTypeInspectorAllowedSlotsDropdown then
        self.WeaponTypeInspectorAllowedSlotsDropdown:SetItems(self:BuildItemInspectorItemSlotItems())
        self.WeaponTypeInspectorAllowedSlotsDropdown:SetSelectedValues(weaponType and weaponType.allowedSlotRefs or {}, true)
        self.WeaponTypeInspectorAllowedSlotsDropdown:SetEnabled(hasWeaponType)
    end
    if self.WeaponTypeInspectorHintText then
        self.WeaponTypeInspectorHintText:SetText(hasWeaponType and "Allowed slots are authoritative for items that use this weapon type." or "")
    end
    if self.WeaponTypeInspectorEmptyText then
        self.WeaponTypeInspectorEmptyText:SetText(hasWeaponType and "Adjust the selected weapon type here." or "Select a weapon type to inspect it.")
    end
end
