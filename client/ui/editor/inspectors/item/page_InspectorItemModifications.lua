local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Client.UI = Addon.Client.UI or {}
Addon.Client.UI.Editor = Addon.Client.UI.Editor or {}

local DataEditor = Addon.Client.UI.Editor
local UI = Addon.UI or {}
local Shared = DataEditor.ItemInspectorShared or {}
local FIELD_WIDTH = Shared.FIELD_WIDTH or 236
local CONTROL_HEIGHT = Shared.CONTROL_HEIGHT or 20
local MODIFICATION_ARMOR_WEIGHT_ITEMS = Shared.MODIFICATION_ARMOR_WEIGHT_ITEMS or {}
local SOCKET_TYPE_ITEMS = Shared.SOCKET_TYPE_ITEMS or {}
local MODIFICATION_KIND_ITEMS = Shared.MODIFICATION_KIND_ITEMS or {}
local copyTable = Shared.copyTable
local ensureString = Shared.ensureString
local buildLabel = Shared.buildLabel
local createHorizontalFieldLabels = Shared.createHorizontalFieldLabels
local normalizeSocketColor = Shared.normalizeSocketColor
local buildItemSocketRows = Shared.buildItemSocketRows
local applyItemSocketRows = Shared.applyItemSocketRows
local getItemGenericLimitMap = Shared.getItemGenericLimitMap
local applyItemGenericLimitMap = Shared.applyItemGenericLimitMap

local function buildModificationsPage(self, page)
    local function handleMouseWheel(_, delta)
        local _, maxValue = self.ItemInspectorModificationsScrollBar:GetMinMaxValues()
        local current = self.ItemInspectorModificationsScrollBar:GetValue() or 0
        local nextValue = math.max(0, math.min(maxValue or 0, current - ((delta or 0) * 24)))
        self.ItemInspectorModificationsScrollBar:SetValue(nextValue)
    end

    local function attachMouseWheel(target)
        local frame = target and target.GetFrame and target:GetFrame() or target
        if not frame then
            return
        end

        if frame.EnableMouseWheel then
            frame:EnableMouseWheel(true)
        end

        if frame.HookScript then
            frame:HookScript("OnMouseWheel", handleMouseWheel)
        elseif frame.SetScript then
            frame:SetScript("OnMouseWheel", handleMouseWheel)
        end
    end

    self.ItemInspectorModificationsScrollFrame = CreateFrame("ScrollFrame", "RPEDataEditorItemInspectorModificationsScrollFrame", page)
    self.ItemInspectorModificationsScrollFrame:SetPoint("TOPLEFT", page, "TOPLEFT", 0, 0)
    self.ItemInspectorModificationsScrollFrame:SetPoint("BOTTOMRIGHT", page, "BOTTOMRIGHT", -20, 0)
    self.ItemInspectorModificationsScrollFrame:EnableMouseWheel(true)
    self.ItemInspectorModificationsScrollFrame:SetClipsChildren(true)
    attachMouseWheel(page)
    attachMouseWheel(self.ItemInspectorModificationsScrollFrame)

    self.ItemInspectorModificationsScrollBar = CreateFrame("Slider", "RPEDataEditorItemInspectorModificationsScrollBar", page)
    self.ItemInspectorModificationsScrollBar:SetPoint("TOPRIGHT", page, "TOPRIGHT", -4, -2)
    self.ItemInspectorModificationsScrollBar:SetPoint("BOTTOMRIGHT", page, "BOTTOMRIGHT", -4, 2)
    self.ItemInspectorModificationsScrollBar:SetOrientation("VERTICAL")
    self.ItemInspectorModificationsScrollBar:SetMinMaxValues(0, 0)
    self.ItemInspectorModificationsScrollBar:SetValueStep(12)
    if self.ItemInspectorModificationsScrollBar.SetObeyStepOnDrag then
        self.ItemInspectorModificationsScrollBar:SetObeyStepOnDrag(true)
    end
    self.ItemInspectorModificationsScrollBar:SetWidth(12)

    self.ItemInspectorModificationsScrollBarTrack = self.ItemInspectorModificationsScrollBarTrack or self.ItemInspectorModificationsScrollBar:CreateTexture(nil, "BACKGROUND")
    self.ItemInspectorModificationsScrollBarTrack:SetAllPoints(self.ItemInspectorModificationsScrollBar)
    do
        local trackColor = UI.ResolveColor(nil, "scrollbar.track")
        self.ItemInspectorModificationsScrollBarTrack:SetColorTexture(trackColor.r or 0.08, trackColor.g or 0.09, trackColor.b or 0.11, trackColor.a or 0.95)
    end

    self.ItemInspectorModificationsScrollBar:SetThumbTexture("Interface\\Buttons\\WHITE8x8")
    do
        local thumb = self.ItemInspectorModificationsScrollBar.GetThumbTexture and self.ItemInspectorModificationsScrollBar:GetThumbTexture() or nil
        if thumb and thumb.SetVertexColor then
            local thumbColor = UI.ResolveColor(nil, "scrollbar.thumb")
            thumb:SetVertexColor(thumbColor.r or 0.42, thumbColor.g or 0.46, thumbColor.b or 0.52, thumbColor.a or 1)
        end
    end
    self.ItemInspectorModificationsScrollBar:SetValue(0)

    local root = UI.CreateLayout(UI.VerticalLayoutGroup, self.ItemInspectorModificationsScrollFrame, "RPEDataEditorItemInspectorModificationsLayout", {
        spacing = 2,
        fitChildrenWidth = true,
        fitChildrenHeight = false,
        autoSize = true,
    })
    root:GetFrame():SetPoint("TOPLEFT", self.ItemInspectorModificationsScrollFrame, "TOPLEFT", 0, 0)
    root:GetFrame():SetPoint("TOPRIGHT", self.ItemInspectorModificationsScrollFrame, "TOPRIGHT", 0, 0)
    self.ItemInspectorModificationsScrollFrame:SetScrollChild(root:GetFrame())
    self.ItemInspectorModificationsScrollBar:SetScript("OnValueChanged", function(_, value)
        self.ItemInspectorModificationsScrollFrame:SetVerticalScroll(value or 0)
    end)
    self.ItemInspectorModificationsScrollFrame:SetScript("OnMouseWheel", handleMouseWheel)
    self.ItemInspectorModificationsScrollFrame:SetScript("OnSizeChanged", function(scrollFrame)
        local width = math.max(1, (scrollFrame:GetWidth() or FIELD_WIDTH) - 4)
        root:GetFrame():SetWidth(width)
        if root.RefreshLayout then
            root:RefreshLayout()
        end
    end)
    attachMouseWheel(root)

    self.ItemInspectorModificationsLayout = root
    self.ItemInspectorModificationsRoot = root
    local function createModificationGroup(name, labelText, contentHeight)
        local groupHeight = 12 + 2 + (contentHeight or CONTROL_HEIGHT)
        local group = UI.CreateLayout(UI.VerticalLayoutGroup, root:GetFrame(), name, {
            width = FIELD_WIDTH,
            height = groupHeight,
            spacing = 2,
            fitChildrenWidth = true,
            fitChildrenHeight = false,
        })
        group._visibleHeight = groupHeight
        root:AddChild(group)
        group:AddChild(buildLabel(group:GetFrame(), name .. "Label", labelText))
        attachMouseWheel(group)
        return group
    end

    self.ItemInspectorModificationKindGroup = createModificationGroup("RPEDataEditorItemInspectorModificationKindGroup", "Modification Type", 18)
    self.ItemInspectorModificationKindDropdown = UI.CreateDropdown(self.ItemInspectorModificationKindGroup:GetFrame(), "RPEDataEditorItemInspectorModificationKindDropdown", {
        width = FIELD_WIDTH,
        height = 18,
        items = MODIFICATION_KIND_ITEMS,
        onValueChanged = function(value)
            if self._refreshingItemInspector then
                return
            end

            self:CommitSelectedItem(function(item)
                item.modificationKind = value or "generic"
                if item.modificationKind ~= "generic" then
                    item.genericModificationKey = ""
                end
                if item.modificationKind ~= "gem" then
                    item.gemColor = "none"
                end
            end)
        end,
    })
    self.ItemInspectorModificationKindGroup:AddChild(self.ItemInspectorModificationKindDropdown)

    self.ItemInspectorModificationTargetSlotsGroup = createModificationGroup("RPEDataEditorItemInspectorModificationTargetSlotsGroup", "Target Slots", 18)
    self.ItemInspectorModificationTargetSlotsDropdown = UI.CreateDropdown(self.ItemInspectorModificationTargetSlotsGroup:GetFrame(), "RPEDataEditorItemInspectorModificationTargetSlotsDropdown", {
        width = FIELD_WIDTH,
        height = 18,
        items = self:BuildItemInspectorItemSlotItems(),
        multiSelect = true,
        showSelectionActions = false,
        onValueChanged = function(values)
            if self._refreshingItemInspector then
                return
            end

            self:CommitSelectedItem(function(item)
                item.targetSlotRefs = copyTable(values or {})
            end)
        end,
    })
    self.ItemInspectorModificationTargetSlotsGroup:AddChild(self.ItemInspectorModificationTargetSlotsDropdown)

    self.ItemInspectorModificationWeaponTypeGroup = createModificationGroup("RPEDataEditorItemInspectorModificationWeaponTypeGroup", "Target Weapon Type", 18)
    self.ItemInspectorModificationWeaponTypeDropdown = UI.CreateDropdown(self.ItemInspectorModificationWeaponTypeGroup:GetFrame(), "RPEDataEditorItemInspectorModificationWeaponTypeDropdown", {
        width = FIELD_WIDTH,
        height = 18,
        items = self:BuildItemInspectorWeaponTypeItems(),
        onValueChanged = function(value)
            if self._refreshingItemInspector then
                return
            end

            self:CommitSelectedItem(function(item)
                item.targetWeaponTypeRef = value ~= "" and value or nil
            end)
        end,
    })
    self.ItemInspectorModificationWeaponTypeGroup:AddChild(self.ItemInspectorModificationWeaponTypeDropdown)

    self.ItemInspectorModificationArmorWeightGroup = createModificationGroup("RPEDataEditorItemInspectorModificationArmorWeightGroup", "Target Armor Weight", 18)
    self.ItemInspectorModificationArmorWeightDropdown = UI.CreateDropdown(self.ItemInspectorModificationArmorWeightGroup:GetFrame(), "RPEDataEditorItemInspectorModificationArmorWeightDropdown", {
        width = FIELD_WIDTH,
        height = 18,
        items = MODIFICATION_ARMOR_WEIGHT_ITEMS,
        onValueChanged = function(value)
            if self._refreshingItemInspector then
                return
            end

            self:CommitSelectedItem(function(item)
                item.targetArmorWeight = value or "none"
            end)
        end,
    })
    self.ItemInspectorModificationArmorWeightGroup:AddChild(self.ItemInspectorModificationArmorWeightDropdown)

    self.ItemInspectorModificationGenericKeyGroup = createModificationGroup("RPEDataEditorItemInspectorModificationGenericKeyGroup", "Generic Key", CONTROL_HEIGHT)
    self.ItemInspectorModificationGenericKeyInput = UI.CreateTextInput(self.ItemInspectorModificationGenericKeyGroup:GetFrame(), "RPEDataEditorItemInspectorModificationGenericKeyInput", {
        width = FIELD_WIDTH,
        height = CONTROL_HEIGHT,
        text = "",
        borderColor = UI.ResolveColor(nil, "panel.border"),
    })
    self.ItemInspectorModificationGenericKeyInput:SetScript("OnEnterPressed", function()
        self:CommitSelectedItem(function(item)
            item.genericModificationKey = string.lower(ensureString(self.ItemInspectorModificationGenericKeyInput:GetText())):gsub("^%s+", ""):gsub("%s+$", "")
        end)
    end)
    self.ItemInspectorModificationGenericKeyInput:SetScript("OnEditFocusLost", function()
        self:CommitSelectedItem(function(item)
            item.genericModificationKey = string.lower(ensureString(self.ItemInspectorModificationGenericKeyInput:GetText())):gsub("^%s+", ""):gsub("%s+$", "")
        end)
    end)
    self.ItemInspectorModificationGenericKeyGroup:AddChild(self.ItemInspectorModificationGenericKeyInput)

    self.ItemInspectorModificationGemColorGroup = createModificationGroup("RPEDataEditorItemInspectorModificationGemColorGroup", "Gem Color", 18)
    self.ItemInspectorModificationGemColorDropdown = UI.CreateDropdown(self.ItemInspectorModificationGemColorGroup:GetFrame(), "RPEDataEditorItemInspectorModificationGemColorDropdown", {
        width = FIELD_WIDTH,
        height = 18,
        items = SOCKET_TYPE_ITEMS,
        onValueChanged = function(value)
            if self._refreshingItemInspector then
                return
            end

            self:CommitSelectedItem(function(item)
                item.gemColor = value or "none"
            end)
        end,
    })
    self.ItemInspectorModificationGemColorGroup:AddChild(self.ItemInspectorModificationGemColorDropdown)

    self.ItemInspectorModificationSocketsLabel = buildLabel(root:GetFrame(), "RPEDataEditorItemInspectorModificationSocketsLabel", "Sockets")
    self.ItemInspectorModificationSocketsLabel._visibleHeight = 12
    root:AddChild(self.ItemInspectorModificationSocketsLabel)

    self.ItemInspectorModificationSocketsHeader = createHorizontalFieldLabels(root, "RPEDataEditorItemInspectorModificationSocketsHeader", {
        { text = "Socket", width = 178, justifyH = "LEFT" },
        { text = "#", width = 46, justifyH = "RIGHT" },
    }, FIELD_WIDTH)

    self.ItemInspectorModificationSocketsPanel = UI.CreatePanel(root:GetFrame(), "RPEDataEditorItemInspectorModificationSocketsPanel", {
        width = FIELD_WIDTH,
        height = 56,
        contentInset = 1,
        showBorder = true,
    })
    self.ItemInspectorModificationSocketsPanel._visibleHeight = 56
    root:AddChild(self.ItemInspectorModificationSocketsPanel)
    attachMouseWheel(self.ItemInspectorModificationSocketsPanel)

    self.ItemInspectorModificationSocketsScroll = UI.ScrollLayout:New({
        name = "RPEDataEditorItemInspectorModificationSocketsScroll",
        width = FIELD_WIDTH,
        height = 54,
        visibleRows = 3,
        rowHeight = 18,
        rowSpacing = 0,
        border = false,
        rowElementClass = UI.TableRow,
    })
    self.ItemInspectorModificationSocketsScroll:SetParent(self.ItemInspectorModificationSocketsPanel:GetContentFrame())
    self.ItemInspectorModificationSocketsScroll:SetRowRenderer(function(row, rowItem, itemIndex)
        if row.SetColumns then
            row:SetColumns({
                { key = "socketColor", width = 178, justifyH = "LEFT" },
                { key = "slotText", width = 46, justifyH = "RIGHT" },
            })
        end
        if row.SetRowData then
            row:SetRowData(rowItem, itemIndex or 0)
        end
        if row.SetRowMouseUpHandler then
            row:SetRowMouseUpHandler(function(_, button, rowData)
                if button == "LeftButton" then
                    self.SelectedItemInspectorSocketIndex = rowData and rowData.rowIndex or nil
                    self:RefreshItemInspectorPage()
                end
            end)
        end
    end)
    self.ItemInspectorModificationSocketsScroll:Create()
    UI.Utils.AnchorFill(self.ItemInspectorModificationSocketsScroll, self.ItemInspectorModificationSocketsPanel:GetContentFrame(), 0, 0, 0, 0)
    attachMouseWheel(self.ItemInspectorModificationSocketsScroll)

    self.ItemInspectorModificationSocketToolbar = UI.CreateLayout(UI.HorizontalLayoutGroup, root:GetFrame(), "RPEDataEditorItemInspectorModificationSocketToolbar", {
        width = FIELD_WIDTH,
        height = 18,
        spacing = 4,
        fitChildrenWidth = false,
        fitChildrenHeight = false,
    })
    self.ItemInspectorModificationSocketToolbar._visibleHeight = 18
    root:AddChild(self.ItemInspectorModificationSocketToolbar)
    attachMouseWheel(self.ItemInspectorModificationSocketToolbar)

    self.ItemInspectorModificationSocketColorDropdown = UI.CreateDropdown(self.ItemInspectorModificationSocketToolbar:GetFrame(), "RPEDataEditorItemInspectorModificationSocketColorDropdown", {
        width = 104,
        height = 18,
        items = SOCKET_TYPE_ITEMS,
    })
    self.ItemInspectorModificationSocketToolbar:AddChild(self.ItemInspectorModificationSocketColorDropdown)
    attachMouseWheel(self.ItemInspectorModificationSocketColorDropdown)

    self.ItemInspectorModificationAddSocketButton = UI.CreateButton(self.ItemInspectorModificationSocketToolbar:GetFrame(), "RPEDataEditorItemInspectorModificationAddSocketButton", "Add", 56, function()
        if self._refreshingItemInspector then
            return
        end

        local color = self.ItemInspectorModificationSocketColorDropdown and self.ItemInspectorModificationSocketColorDropdown.GetSelectedValue and self.ItemInspectorModificationSocketColorDropdown:GetSelectedValue() or "red"
        local normalizedColor = normalizeSocketColor(color)
        if not normalizedColor then
            return
        end

        self:CommitSelectedItem(function(item)
            local sockets = buildItemSocketRows(item)
            sockets[#sockets + 1] = {
                color = normalizedColor,
            }
            applyItemSocketRows(item, sockets)
        end)
    end, {
        height = 18,
        fontSize = 7,
    })
    self.ItemInspectorModificationSocketToolbar:AddChild(self.ItemInspectorModificationAddSocketButton)
    self.ItemInspectorModificationRemoveSocketButton = UI.CreateButton(self.ItemInspectorModificationSocketToolbar:GetFrame(), "RPEDataEditorItemInspectorModificationRemoveSocketButton", "Remove", 68, function()
        local removeIndex = tonumber(self.SelectedItemInspectorSocketIndex)
        if not removeIndex then
            return
        end

        self:CommitSelectedItem(function(item)
            local sockets = buildItemSocketRows(item)
            table.remove(sockets, removeIndex)
            applyItemSocketRows(item, sockets)
        end)
    end, {
        height = 18,
        fontSize = 7,
    })
    self.ItemInspectorModificationSocketToolbar:AddChild(self.ItemInspectorModificationRemoveSocketButton)

    self.ItemInspectorModificationGenericLimitsLabel = buildLabel(root:GetFrame(), "RPEDataEditorItemInspectorModificationGenericLimitsLabel", "Generic Modification Limits")
    self.ItemInspectorModificationGenericLimitsLabel._visibleHeight = 12
    root:AddChild(self.ItemInspectorModificationGenericLimitsLabel)

    self.ItemInspectorModificationGenericLimitsHeader = createHorizontalFieldLabels(root, "RPEDataEditorItemInspectorModificationGenericLimitsHeader", {
        { text = "Key", width = 178, justifyH = "LEFT" },
        { text = "Max", width = 46, justifyH = "RIGHT" },
    }, FIELD_WIDTH)

    self.ItemInspectorModificationGenericLimitPanel = UI.CreatePanel(root:GetFrame(), "RPEDataEditorItemInspectorModificationGenericLimitPanel", {
        width = FIELD_WIDTH,
        height = 56,
        contentInset = 1,
        showBorder = true,
    })
    self.ItemInspectorModificationGenericLimitPanel._visibleHeight = 56
    root:AddChild(self.ItemInspectorModificationGenericLimitPanel)
    attachMouseWheel(self.ItemInspectorModificationGenericLimitPanel)

    self.ItemInspectorModificationGenericLimitScroll = UI.ScrollLayout:New({
        name = "RPEDataEditorItemInspectorModificationGenericLimitScroll",
        width = FIELD_WIDTH,
        height = 54,
        visibleRows = 3,
        rowHeight = 18,
        rowSpacing = 0,
        border = false,
        rowElementClass = UI.TableRow,
    })
    self.ItemInspectorModificationGenericLimitScroll:SetParent(self.ItemInspectorModificationGenericLimitPanel:GetContentFrame())
    self.ItemInspectorModificationGenericLimitScroll:SetRowRenderer(function(row, rowItem, itemIndex)
        if row.SetColumns then
            row:SetColumns({
                { key = "keyText", width = 178, justifyH = "LEFT" },
                { key = "maxCountText", width = 46, justifyH = "RIGHT" },
            })
        end
        if row.SetRowData then
            row:SetRowData(rowItem, itemIndex or 0)
        end
        if row.SetRowMouseUpHandler then
            row:SetRowMouseUpHandler(function(_, button, rowData)
                if button == "LeftButton" then
                    self.SelectedItemInspectorGenericLimitKey = rowData and rowData.key or nil
                    self:RefreshItemInspectorPage()
                end
            end)
        end
    end)
    self.ItemInspectorModificationGenericLimitScroll:Create()
    UI.Utils.AnchorFill(self.ItemInspectorModificationGenericLimitScroll, self.ItemInspectorModificationGenericLimitPanel:GetContentFrame(), 0, 0, 0, 0)
    attachMouseWheel(self.ItemInspectorModificationGenericLimitScroll)

    self.ItemInspectorModificationGenericLimitKeyGroup = createModificationGroup("RPEDataEditorItemInspectorModificationGenericLimitKeyGroup", "Key", CONTROL_HEIGHT)
    self.ItemInspectorModificationGenericLimitKeyInput = UI.CreateTextInput(self.ItemInspectorModificationGenericLimitKeyGroup:GetFrame(), "RPEDataEditorItemInspectorModificationGenericLimitKeyInput", {
        width = FIELD_WIDTH,
        height = CONTROL_HEIGHT,
        text = "",
        borderColor = UI.ResolveColor(nil, "panel.border"),
    })
    self.ItemInspectorModificationGenericLimitKeyGroup:AddChild(self.ItemInspectorModificationGenericLimitKeyInput)

    self.ItemInspectorModificationGenericLimitValueGroup = createModificationGroup("RPEDataEditorItemInspectorModificationGenericLimitValueGroup", "Max Count", CONTROL_HEIGHT)
    self.ItemInspectorModificationGenericLimitValueInput = UI.CreateTextInput(self.ItemInspectorModificationGenericLimitValueGroup:GetFrame(), "RPEDataEditorItemInspectorModificationGenericLimitValueInput", {
        width = FIELD_WIDTH,
        height = CONTROL_HEIGHT,
        text = "1",
        borderColor = UI.ResolveColor(nil, "panel.border"),
    })
    self.ItemInspectorModificationGenericLimitValueGroup:AddChild(self.ItemInspectorModificationGenericLimitValueInput)

    self.ItemInspectorModificationGenericLimitActionRow = UI.CreateLayout(UI.HorizontalLayoutGroup, root:GetFrame(), "RPEDataEditorItemInspectorModificationGenericLimitActionRow", {
        width = FIELD_WIDTH,
        height = 18,
        spacing = 4,
        fitChildrenWidth = false,
        fitChildrenHeight = false,
    })
    self.ItemInspectorModificationGenericLimitActionRow._visibleHeight = 18
    root:AddChild(self.ItemInspectorModificationGenericLimitActionRow)
    attachMouseWheel(self.ItemInspectorModificationGenericLimitActionRow)
    self.ItemInspectorModificationSaveGenericLimitButton = UI.CreateButton(self.ItemInspectorModificationGenericLimitActionRow:GetFrame(), "RPEDataEditorItemInspectorModificationSaveGenericLimitButton", "Save", 56, function()
        if self._refreshingItemInspector then
            return
        end

        local key = string.lower(ensureString(self.ItemInspectorModificationGenericLimitKeyInput and self.ItemInspectorModificationGenericLimitKeyInput:GetText())):gsub("^%s+", ""):gsub("%s+$", "")
        if key == "" then
            return
        end

        local value = math.max(0, math.floor(tonumber(self.ItemInspectorModificationGenericLimitValueInput and self.ItemInspectorModificationGenericLimitValueInput:GetText()) or 0))
        self:CommitSelectedItem(function(item)
            local counts = getItemGenericLimitMap(item)
            counts[key] = value
            applyItemGenericLimitMap(item, counts)
        end)
    end, {
        height = 18,
        fontSize = 7,
    })
    self.ItemInspectorModificationGenericLimitActionRow:AddChild(self.ItemInspectorModificationSaveGenericLimitButton)
    self.ItemInspectorModificationRemoveGenericLimitButton = UI.CreateButton(self.ItemInspectorModificationGenericLimitActionRow:GetFrame(), "RPEDataEditorItemInspectorModificationRemoveGenericLimitButton", "Remove", 68, function()
        local removeKey = string.lower(ensureString(self.SelectedItemInspectorGenericLimitKey))
        if removeKey == "" then
            return
        end

        self:CommitSelectedItem(function(item)
            local counts = getItemGenericLimitMap(item)
            counts[removeKey] = nil
            applyItemGenericLimitMap(item, counts)
        end)
    end, {
        height = 18,
        fontSize = 7,
    })
    self.ItemInspectorModificationGenericLimitActionRow:AddChild(self.ItemInspectorModificationRemoveGenericLimitButton)

    local function refreshScrollBounds()
        local contentHeight = root:GetFrame() and root:GetFrame():GetHeight() or 0
        local viewportHeight = self.ItemInspectorModificationsScrollFrame and self.ItemInspectorModificationsScrollFrame:GetHeight() or 0
        local maxScroll = math.max(0, math.ceil(contentHeight - viewportHeight))

        self.ItemInspectorModificationsScrollBar:SetMinMaxValues(0, maxScroll)
        if self.ItemInspectorModificationsScrollBar.SetShown then
            self.ItemInspectorModificationsScrollBar:SetShown(maxScroll > 0)
        elseif maxScroll > 0 and self.ItemInspectorModificationsScrollBar.Show then
            self.ItemInspectorModificationsScrollBar:Show()
        elseif self.ItemInspectorModificationsScrollBar.Hide then
            self.ItemInspectorModificationsScrollBar:Hide()
        end
        if (self.ItemInspectorModificationsScrollBar:GetValue() or 0) > maxScroll then
            self.ItemInspectorModificationsScrollBar:SetValue(maxScroll)
        end
    end

    self.RefreshItemInspectorModificationsScrollBounds = refreshScrollBounds
    self.ItemInspectorModificationsScrollFrame:SetScript("OnShow", refreshScrollBounds)
end

function DataEditor:BuildItemInspectorModificationsPage(page)
    return buildModificationsPage(self, page)
end
