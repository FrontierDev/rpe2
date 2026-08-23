local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Client.UI = Addon.Client.UI or {}
Addon.Client.UI.Profile = Addon.Client.UI.Profile or {}

local ProfileUI = Addon.Client.UI.Profile
local UI = Addon.UI or {}
local TooltipBuilders = Addon.Client.UI and Addon.Client.UI.Tooltips or {}
local Profile = Addon.Internal and Addon.Internal.Profile or {}
local Database = Addon.Internal and Addon.Internal.Database or {}

local MountsPage = ProfileUI.MountsPage or {}
ProfileUI.MountsPage = MountsPage

local SLOT_SIZE = 34
local SLOT_SPACING = 5
local LEFT_PANEL_WIDTH = 302
local RIGHT_PANEL_WIDTH = 150
local MODEL_WIDTH = 170
local MODEL_HEIGHT = 180
local TRANSPARENT_PANEL_BACKGROUND = { r = 0, g = 0, b = 0, a = 0 }
local STAT_VISIBLE_ROWS = 16
local STAT_ROW_HEIGHT = 18
local STAT_ROW_SPACING = 2
local STAT_SCROLL_WIDTH = 146
local STAT_SCROLL_HEIGHT = (STAT_VISIBLE_ROWS * STAT_ROW_HEIGHT) + (math.max(0, STAT_VISIBLE_ROWS - 1) * STAT_ROW_SPACING)
local STAT_ENTRY_WIDTH = STAT_SCROLL_WIDTH - 14
local STAT_ENTRY_VALUE_WIDTH = 42

local function ensureString(value, fallback)
    if value == nil or value == "" then
        return fallback or ""
    end

    return tostring(value)
end

local function buildMountItems()
    local items = {
        { label = "None", value = "" },
    }

    local mounts = Profile.ListMounts and Profile.ListMounts() or {}
    for index = 1, #mounts do
        local row = mounts[index]
        items[#items + 1] = {
            label = ensureString(row.name, row.ref),
            value = row.ref,
        }
    end

    return items
end

local function buildEmptyTooltip(slotKey)
    return {
        type = "custom",
        title = Profile.GetSlotLabel and Profile.GetSlotLabel(slotKey) or "Mount Slot",
        lines = {
            "No item equipped.",
        },
    }
end

local function buildEquippedTooltip(slotInfo)
    if not slotInfo then
        return buildEmptyTooltip("")
    end

    local item = slotInfo.item
    if not item then
        return {
            type = "custom",
            title = Profile.GetSlotLabel and Profile.GetSlotLabel(slotInfo.slotKey) or "Mount Slot",
            lines = {
                ("Missing item: %s"):format(tostring(slotInfo.itemRef or "-")),
            },
        }
    end

    local datasetName = slotInfo.dataset and Database.GetDatasetDisplayName and Database.GetDatasetDisplayName(slotInfo.dataset) or "Unknown Dataset"
    local builder = TooltipBuilders and TooltipBuilders.Item
    if builder and builder.Build then
        local tooltip = builder:Build(item, {
            dataset = slotInfo.dataset,
            datasetId = slotInfo.dataset and slotInfo.dataset.id or nil,
            datasetName = datasetName,
            itemId = item.id,
            isActive = slotInfo.isActive,
            isMissing = slotInfo.isMissing,
            soulbound = slotInfo.soulbound == true,
            modifications = slotInfo.modifications,
        })
        if tooltip then
            return tooltip
        end
    end

    return {
        type = "custom",
        title = ensureString(item.name, Profile.GetSlotLabel and Profile.GetSlotLabel(slotInfo.slotKey) or "Mount Item"),
        lines = {
            ("Dataset: %s"):format(datasetName),
        },
    }
end

local function buildLayoutSignature(layout)
    local parts = {}

    local function append(groupName, slotKeys)
        for index = 1, #(slotKeys or {}) do
            parts[#parts + 1] = ("%s:%d:%s"):format(groupName, index, tostring(slotKeys[index]))
        end
    end

    append("left", layout and layout.left or nil)
    append("right", layout and layout.right or nil)
    append("bottom", layout and layout.bottom or nil)

    return table.concat(parts, "|")
end

local function formatStatValue(row)
    local displayMode = tostring(row and row.displayMode or "signed_value")
    local value = tonumber(row and row.value) or 0
    if displayMode == "value" then
        return ("%g"):format(value)
    end
    if displayMode == "signed_percent" or displayMode == "equip_percent" then
        return ("%g%%"):format(value)
    end
    return ("%g"):format(value)
end

local function updateSlotVisual(page, slotKey)
    local slot = page.SlotWidgets and page.SlotWidgets[slotKey] or nil
    if not slot then
        return
    end

    local slotInfo = Profile.GetEquippedMountItem and Profile.GetEquippedMountItem(slotKey) or nil
    local emptyTexture = Profile.GetSlotTexture and Profile.GetSlotTexture(slotKey) or "Interface\\Icons\\INV_Misc_QuestionMark"
    local icon = emptyTexture
    local tooltip = buildEmptyTooltip(slotKey)

    if slotInfo and slotInfo.item then
        icon = ensureString(slotInfo.item.icon, emptyTexture)
        tooltip = buildEquippedTooltip(slotInfo)
    elseif slotInfo and slotInfo.itemRef ~= nil and slotInfo.itemRef ~= "" then
        icon = "Interface\\Icons\\INV_Misc_QuestionMark"
        tooltip = buildEquippedTooltip(slotInfo)
    end

    slot:SetIcon(icon)
    slot:SetEnabled(true)
    slot:SetTooltip(tooltip)

    local isSelected = page.owner and page.owner.SelectedMountSlotKey == slotKey
    if slot.SetBorderColor then
        if isSelected then
            slot:SetBorderColor(0.24, 0.72, 1, 1)
        else
            slot:SetBorderColor(0.42, 0.46, 0.52, 1)
        end
    end
end

function MountsPage:EnsureSlotWidget(slotKey)
    self.SlotWidgets = self.SlotWidgets or {}
    local slot = self.SlotWidgets[slotKey]
    if slot then
        return slot
    end

    slot = UI.ObjectSlot:New({
        name = "RPEProfileMountSlot" .. slotKey,
        width = SLOT_SIZE,
        height = SLOT_SIZE,
        size = SLOT_SIZE,
        iconTexture = Profile.GetSlotTexture and Profile.GetSlotTexture(slotKey) or "Interface\\Icons\\INV_Misc_QuestionMark",
        border = false,
    })
    slot:SetParent(self.ModelPanel:GetContentFrame())
    slot:Create()

    local owner = self.owner
    local frame = slot:GetFrame()
    if frame then
        frame:HookScript("OnMouseUp", function(_, button)
            if button == "LeftButton" and owner and owner.SetSelectedMountSlotKey then
                owner:SetSelectedMountSlotKey(slotKey)
            elseif button == "RightButton" and Profile.UnequipMountItem then
                local removed = Profile.UnequipMountItem(slotKey)
                if removed and owner and owner.SelectedMountSlotKey == slotKey then
                    owner.SelectedMountSlotKey = nil
                end
            end
        end)
    end

    self.SlotWidgets[slotKey] = slot
    return slot
end

function MountsPage:ApplySlotLayout(layout)
    local body = self.ModelPanel and self.ModelPanel.GetContentFrame and self.ModelPanel:GetContentFrame() or nil
    if not body then
        return
    end

    local visible = {}
    local groupConfigs = {
        left = { point = "TOPLEFT", relativePoint = "TOPLEFT", x = 0, y = -8, horizontal = false },
        right = { point = "TOPRIGHT", relativePoint = "TOPRIGHT", x = 0, y = -8, horizontal = false },
        bottom = { point = "BOTTOM", relativePoint = "BOTTOM", x = 0, y = 8, horizontal = true },
    }

    for _, groupName in ipairs({ "left", "right", "bottom" }) do
        local slotKeys = layout and layout[groupName] or {}
        local config = groupConfigs[groupName]

        for index = 1, #slotKeys do
            local slotKey = slotKeys[index]
            local slot = self:EnsureSlotWidget(slotKey)
            local frame = slot and slot.GetFrame and slot:GetFrame() or nil
            if frame then
                frame:ClearAllPoints()
                if config.horizontal then
                    local totalWidth = (#slotKeys * SLOT_SIZE) + (math.max(0, #slotKeys - 1) * SLOT_SPACING)
                    local startX = -math.floor(totalWidth / 2)
                    local x = startX + ((index - 1) * (SLOT_SIZE + SLOT_SPACING))
                    frame:SetPoint(config.point, body, config.relativePoint, x, config.y)
                else
                    local y = config.y - ((index - 1) * (SLOT_SIZE + SLOT_SPACING))
                    frame:SetPoint(config.point, body, config.relativePoint, config.x, y)
                end
                frame:Show()
            end
            visible[slotKey] = true
        end
    end

    for slotKey, slot in pairs(self.SlotWidgets or {}) do
        local frame = slot and slot.GetFrame and slot:GetFrame() or nil
        if frame and not visible[slotKey] and frame.Hide then
            frame:Hide()
        end
    end
end

function MountsPage:RefreshStatRows(statRows)
    if not self.StatScroll or not self.StatScroll.SetItems then
        return
    end

    self.StatScroll:SetItems(statRows or {})
end

function MountsPage:RefreshSummary()
    local selectedMount = Profile.GetSelectedMount and Profile.GetSelectedMount() or nil
    local isMounted = Profile.IsMounted and Profile.IsMounted() or false
    local movementRangeValue = Profile.GetMovementRangeValue and Profile.GetMovementRangeValue() or nil
    local summaryLines = {}

    summaryLines[#summaryLines + 1] = selectedMount and ("Selected: " .. ensureString(selectedMount.name, "Mount")) or "Selected: None"
    summaryLines[#summaryLines + 1] = isMounted and "Status: Mounted" or "Status: Dismounted"
    if movementRangeValue ~= nil then
        summaryLines[#summaryLines + 1] = ("Movement Range: %g"):format(tonumber(movementRangeValue) or 0)
    end
    summaryLines[#summaryLines + 1] = Profile.ShouldUseMountedActionBar and (Profile.ShouldUseMountedActionBar() and "Mounted Bar: Enabled" or "Mounted Bar: Disabled") or "Mounted Bar: Disabled"

    if self.SummaryText and self.SummaryText.SetText then
        self.SummaryText:SetText(table.concat(summaryLines, "\n"))
    end
end

function MountsPage:RefreshModel()
    local selectedMount = Profile.GetSelectedMount and Profile.GetSelectedMount() or nil
    local mount = selectedMount and selectedMount.mount or nil
    if self.IconPreview then
        self.IconPreview:SetIcon(ensureString(mount and mount.icon, "Interface\\Icons\\INV_Misc_QuestionMark"))
        self.IconPreview:SetEnabled(false)
    end
    if self.DescriptionText and self.DescriptionText.SetText then
        self.DescriptionText:SetText(ensureString(mount and mount.description, selectedMount and selectedMount.name or "Select a mount."))
    end

    local model = self.ModelFrame
    if not model then
        return
    end

    if model.ClearModel then
        model:ClearModel()
    end

    if not mount then
        return
    end

    if mount.displayId and mount.displayId ~= 0 and model.SetDisplayInfo then
        pcall(model.SetDisplayInfo, model, tonumber(mount.displayId))
    elseif mount.fileDataId and mount.fileDataId ~= 0 and model.SetModelByFileID then
        pcall(model.SetModelByFileID, model, tonumber(mount.fileDataId))
    end
    if model.SetRotation then
        pcall(model.SetRotation, model, tonumber(mount.rot) or 0)
    end
    if model.SetCamDistanceScale then
        pcall(model.SetCamDistanceScale, model, tonumber(mount.cam) or 1)
    end
    if model.SetPosition then
        pcall(model.SetPosition, model, 0, 0, tonumber(mount.z) or -0.35)
    end
end

function MountsPage:Build(parent, owner)
    if self.frame then
        self.owner = owner
        return self.frame
    end

    self.owner = owner
    self.frame = CreateFrame("Frame", "RPEProfileMountsPage", parent)
    self.frame:SetAllPoints(parent)
    self.SlotWidgets = {}
    self.LastLayoutSignature = nil

    self.RootLayout = UI.CreateLayout(UI.HorizontalLayoutGroup, self.frame, "RPEProfileMountsRootLayout", {
        spacing = 10,
        fitChildrenWidth = true,
        fitChildrenHeight = true,
    })
    UI.Utils.AnchorFill(self.RootLayout, self.frame, 0, 0, 0, 0)

    self.LeftPanel = UI.CreatePanel(self.RootLayout:GetFrame(), "RPEProfileMountsLeftPanel", {
        width = LEFT_PANEL_WIDTH,
        height = 380,
        contentInset = 0,
        showBorder = false,
        panelBackgroundColor = TRANSPARENT_PANEL_BACKGROUND,
    })
    self.RootLayout:AddChild(self.LeftPanel)

    self.RightPanel = UI.CreatePanel(self.RootLayout:GetFrame(), "RPEProfileMountsRightPanel", {
        width = RIGHT_PANEL_WIDTH,
        height = 380,
        expandWidth = true,
        weight = 1,
        contentInset = 0,
        showBorder = false,
        panelBackgroundColor = TRANSPARENT_PANEL_BACKGROUND,
    })
    self.RootLayout:AddChild(self.RightPanel)

    local leftContent = self.LeftPanel:GetContentFrame()
    self.LeftLayout = UI.CreateLayout(UI.VerticalLayoutGroup, leftContent, "RPEProfileMountsLeftLayout", {
        spacing = 6,
        fitChildrenWidth = true,
        fitChildrenHeight = true,
    })
    UI.Utils.AnchorFill(self.LeftLayout, leftContent, 0, 0, 0, 0)

    self.MountLabel = UI.CreateText(self.LeftLayout:GetFrame(), "RPEProfileMountsSelectorLabel", "Active Mount", {
        width = LEFT_PANEL_WIDTH,
        height = 12,
        justifyH = "LEFT",
        textColor = UI.ResolveColor(nil, "text.secondary"),
    })
    self.LeftLayout:AddChild(self.MountLabel)

    self.MountDropdown = UI.CreateDropdown(self.LeftLayout:GetFrame(), "RPEProfileMountsSelectorDropdown", {
        width = LEFT_PANEL_WIDTH - 8,
        height = 18,
        items = buildMountItems(),
        onValueChanged = function(value)
            if Profile.SetMountRef then
                Profile.SetMountRef(value ~= "" and value or nil)
            end
            self:Refresh()
        end,
    })
    self.LeftLayout:AddChild(self.MountDropdown)

    self.IconPreview = UI.ObjectSlot:New({
        name = "RPEProfileMountIconPreview",
        width = SLOT_SIZE,
        height = SLOT_SIZE,
        size = SLOT_SIZE,
        iconTexture = "Interface\\Icons\\INV_Misc_QuestionMark",
        border = false,
    })
    self.IconPreview:SetParent(self.LeftLayout:GetFrame())
    self.IconPreview:Create()
    self.LeftLayout:AddChild(self.IconPreview)

    self.DescriptionText = UI.CreateText(self.LeftLayout:GetFrame(), "RPEProfileMountDescriptionText", "Select a mount.", {
        width = LEFT_PANEL_WIDTH - 8,
        height = 40,
        justifyH = "LEFT",
        justifyV = "TOP",
        wordWrap = true,
        textColor = UI.ResolveColor(nil, "text.primary"),
    })
    self.LeftLayout:AddChild(self.DescriptionText)

    self.ModelPanel = UI.CreatePanel(self.LeftLayout:GetFrame(), "RPEProfileMountModelPanel", {
        width = LEFT_PANEL_WIDTH,
        height = MODEL_HEIGHT + 46,
        contentInset = 0,
        showBorder = false,
        panelBackgroundColor = TRANSPARENT_PANEL_BACKGROUND,
    })
    self.LeftLayout:AddChild(self.ModelPanel)

    self.ModelFrame = CreateFrame("PlayerModel", "RPEProfileMountModel", self.ModelPanel:GetContentFrame())
    self.ModelFrame:SetSize(MODEL_WIDTH, MODEL_HEIGHT)
    self.ModelFrame:SetPoint("TOP", self.ModelPanel:GetContentFrame(), "TOP", 0, -4)

    local rightContent = self.RightPanel:GetContentFrame()
    self.RightLayout = UI.CreateLayout(UI.VerticalLayoutGroup, rightContent, "RPEProfileMountsRightLayout", {
        spacing = 6,
        fitChildrenWidth = true,
        fitChildrenHeight = true,
    })
    UI.Utils.AnchorFill(self.RightLayout, rightContent, 0, 0, 0, 0)

    self.SummaryText = UI.CreateText(self.RightLayout:GetFrame(), "RPEProfileMountSummaryText", "", {
        width = STAT_SCROLL_WIDTH,
        height = 60,
        justifyH = "LEFT",
        justifyV = "TOP",
        wordWrap = true,
        textColor = UI.ResolveColor(nil, "text.primary"),
    })
    self.RightLayout:AddChild(self.SummaryText)

    self.StatScrollPanel = UI.CreatePanel(self.RightLayout:GetFrame(), "RPEProfileMountStatsScrollPanel", {
        width = STAT_SCROLL_WIDTH,
        height = STAT_SCROLL_HEIGHT,
        contentInset = 0,
        showBorder = false,
        panelBackgroundColor = TRANSPARENT_PANEL_BACKGROUND,
    })
    self.RightLayout:AddChild(self.StatScrollPanel)

    self.StatScroll = UI.ScrollLayout:New({
        name = "RPEProfileMountStatsScroll",
        width = STAT_SCROLL_WIDTH,
        height = STAT_SCROLL_HEIGHT,
        visibleRows = STAT_VISIBLE_ROWS,
        rowHeight = STAT_ROW_HEIGHT,
        rowSpacing = STAT_ROW_SPACING,
        border = false,
        rowElementClass = UI.Text,
    })
    self.StatScroll:SetParent(self.StatScrollPanel:GetContentFrame())
    self.StatScroll:SetRowRenderer(function(row, item, itemIndex)
        if row.SetText then
            row:SetText("")
        end

        local rowFrame = row.GetFrame and row:GetFrame() or nil
        if not rowFrame or not item then
            return
        end

        if not row.StatHeader then
            row.StatHeader = rowFrame:CreateFontString(nil, "OVERLAY")
            row.StatHeader:SetPoint("LEFT", rowFrame, "LEFT", 2, 0)
            row.StatHeader:SetPoint("RIGHT", rowFrame, "RIGHT", -8, 0)
            row.StatHeader:SetJustifyH("LEFT")
            row.StatHeader:SetJustifyV("MIDDLE")
            if UI.Font and UI.Font.Apply then
                UI.Font:Apply(row.StatHeader, {}, { fontSize = 10 })
            end
        end

        if not row.StatEntry then
            row.StatEntry = UI.StatEntry:New({
                name = ("RPEProfileMountStatEntry%d"):format(itemIndex),
                width = STAT_ENTRY_WIDTH,
                height = 14,
                valueWidth = STAT_ENTRY_VALUE_WIDTH,
            })
            row.StatEntry:SetParent(rowFrame)
            row.StatEntry:Create()
            row.StatEntry:GetFrame():SetPoint("LEFT", rowFrame, "LEFT", 0, 0)
            row.StatEntry:GetFrame():SetPoint("RIGHT", rowFrame, "RIGHT", -8, 0)
        end

        if item.rowType == "header" then
            row.StatHeader:SetText(tostring(item.category or ""))
            row.StatHeader:Show()
            row.StatEntry:GetFrame():Hide()
            return
        end

        row.StatHeader:Hide()
        row.StatEntry:GetFrame():Show()
        local statRow = item.statRow
        if not statRow then
            return
        end

        row.StatEntry:SetIcon(ensureString(statRow.icon, "Interface\\Icons\\INV_Misc_QuestionMark"))
        row.StatEntry:SetStatName(ensureString(statRow.name, statRow.statId or "Stat"))
        row.StatEntry:SetStatValue(formatStatValue(statRow))
    end)
    self.StatScroll:Create()
    UI.Utils.AnchorFill(self.StatScroll, self.StatScrollPanel:GetContentFrame(), 0, 0, 0, 0)

    self:Refresh()
    return self.frame
end

function MountsPage:Refresh()
    if not self.frame or not self.owner then
        return nil
    end

    local mountItems = buildMountItems()
    local mountRef = Profile.GetMountRef and Profile.GetMountRef() or nil
    local layout = Profile.GetMountLayout and Profile.GetMountLayout() or { left = {}, right = {}, bottom = {}, ordered = {} }
    local statRows = Profile.ListProfileStatRows and Profile.ListProfileStatRows() or {}
    local layoutSignature = buildLayoutSignature(layout)

    if self.MountDropdown then
        self.MountDropdown:SetItems(mountItems)
        self.MountDropdown:SetSelectedValue(mountRef or "", true)
    end

    if self.LastLayoutSignature ~= layoutSignature then
        self.LastLayoutSignature = layoutSignature
        self:ApplySlotLayout(layout)
    end

    for index = 1, #(layout.ordered or {}) do
        updateSlotVisual(self, layout.ordered[index])
    end

    local selectedSlotKey = self.owner.SelectedMountSlotKey
    if selectedSlotKey and selectedSlotKey ~= "" then
        local found = false
        for index = 1, #(layout.ordered or {}) do
            if layout.ordered[index] == selectedSlotKey then
                found = true
                break
            end
        end
        if not found then
            self.owner.SelectedMountSlotKey = nil
        end
    end

    self:RefreshModel()
    self:RefreshSummary()
    self:RefreshStatRows(statRows)
    return self.frame
end

return MountsPage
