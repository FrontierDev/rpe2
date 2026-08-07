local _, Addon = ...

local UI = Addon.UI or {}
Addon.UI = UI

UI.Popup = UI.Popup or {}
local Popup = UI.Popup
local POPUP_CONTENT_WIDTH = 380
local POPUP_MIN_MESSAGE_HEIGHT = 18
local POPUP_MIN_DESCRIPTION_HEIGHT = 14
local POPUP_ACTIONS_HEIGHT = 20
local POPUP_CHOICE_LABEL_HEIGHT = 12
local POPUP_CHOICE_DROPDOWN_HEIGHT = 18
local POPUP_WINDOW_VERTICAL_INSET = 38
local POPUP_WINDOW_BOTTOM_SLACK = 6
local POPUP_ROOT_SPACING = 4
local POPUP_TRAIT_GRID_COLUMNS = 3
local POPUP_TRAIT_GRID_ROWS = 2
local POPUP_TRAIT_GRID_ENTRY_HEIGHT = 34
local POPUP_TRAIT_GRID_SPACING_X = 8
local POPUP_TRAIT_GRID_SPACING_Y = 8
local POPUP_TRAIT_GRID_SCROLLBAR_WIDTH = 10
local POPUP_TRAIT_GRID_SCROLLBAR_GAP = 4
local POPUP_TRAIT_GRID_LABEL_HEIGHT = 12
local POPUP_TRAIT_GRID_HOST_HEIGHT = (POPUP_TRAIT_GRID_ROWS * POPUP_TRAIT_GRID_ENTRY_HEIGHT) + ((POPUP_TRAIT_GRID_ROWS - 1) * POPUP_TRAIT_GRID_SPACING_Y)
local POPUP_TRAIT_GRID_LABEL_SPACING = 2
local POPUP_TRAIT_GRID_GROUP_HEIGHT = POPUP_TRAIT_GRID_LABEL_HEIGHT + POPUP_TRAIT_GRID_LABEL_SPACING + POPUP_TRAIT_GRID_HOST_HEIGHT
local POPUP_MESSAGE_MAX_HEIGHT = 72
local DEFAULT_ICON = "Interface\\Icons\\INV_Misc_QuestionMark"

local function clamp(value, minimum, maximum)
    local numericValue = tonumber(value) or 0
    if minimum ~= nil and numericValue < minimum then
        numericValue = minimum
    end
    if maximum ~= nil and numericValue > maximum then
        numericValue = maximum
    end
    return numericValue
end

local function measureTextHeight(element, minimumHeight, maximumHeight)
    if not element then
        return minimumHeight or 0
    end

    local textRegion = element.textRegion or nil
    local measuredHeight = textRegion and textRegion.GetStringHeight and textRegion:GetStringHeight() or 0
    measuredHeight = math.ceil(measuredHeight + 4)
    return clamp(measuredHeight, minimumHeight or 0, maximumHeight)
end

local function setElementVisible(element, visible, height)
    if not element then
        return
    end

    local frame = element.GetFrame and element:GetFrame() or nil
    if element.SetHeight then
        element:SetHeight(visible and height or 0)
    elseif element.options then
        element.options.height = visible and height or 0
    end

    if frame and frame.SetHeight then
        frame:SetHeight(visible and height or 0)
    end
    if frame then
        if visible then
            frame:Show()
        else
            frame:Hide()
        end
    end
end

local function copyArray(values)
    local copy = {}
    for index = 1, #(values or {}) do
        copy[index] = values[index]
    end
    return copy
end

local function normalizeSelectedChoices(values)
    local normalized = {}
    local seen = {}

    for index = 1, #(values or {}) do
        local value = tostring(values[index] or "")
        if value ~= "" and not seen[value] then
            normalized[#normalized + 1] = value
            seen[value] = true
        end
    end

    return normalized, seen
end

local function refreshConfirmEnabled()
    local spec = Popup.PendingSpec or {}
    local usesGrid = Popup._hasTraitGrid == true
    local requiresChoice = false
    local enabled = true

    if usesGrid then
        requiresChoice = spec.requireChoice == true and type(spec.gridItems) == "table" and #spec.gridItems > 0
        local selectedChoices = normalizeSelectedChoices(spec.selectedChoices)
        enabled = not requiresChoice or #selectedChoices > 0
    else
        requiresChoice = spec.requireChoice == true and type(spec.choiceItems) == "table" and #spec.choiceItems > 0
        local selectedChoice = type(spec.selectedChoice) == "string" and spec.selectedChoice or ""
        enabled = not requiresChoice or selectedChoice ~= ""
    end

    if Popup.ConfirmButton and Popup.ConfirmButton.SetEnabled then
        Popup.ConfirmButton:SetEnabled(enabled)
    end
end

local function refreshPopupLayout()
    local hasChoices = Popup._hasChoices == true
    local hasTraitGrid = Popup._hasTraitGrid == true
    local messageHeight = Popup._messageHeight or POPUP_MIN_MESSAGE_HEIGHT
    local selectionHeight = hasTraitGrid and (Popup._traitGridGroupHeight or POPUP_TRAIT_GRID_GROUP_HEIGHT)
        or (hasChoices and (Popup._choiceGroupHeight or 0) or 0)
    local hasSelection = hasTraitGrid or hasChoices
    local visibleBlockCount = 1 + (hasSelection and 1 or 0) + 1
    local contentHeight = messageHeight + selectionHeight + POPUP_ACTIONS_HEIGHT
    local spacingHeight = math.max(0, visibleBlockCount - 1) * POPUP_ROOT_SPACING
    local targetHeight = POPUP_WINDOW_VERTICAL_INSET + contentHeight + spacingHeight + POPUP_WINDOW_BOTTOM_SLACK

    if Popup.ChoiceGroup and Popup.ChoiceGroup.RefreshLayout then
        Popup.ChoiceGroup:RefreshLayout()
    end
    if Popup.TraitGridGroup and Popup.TraitGridGroup.RefreshLayout then
        Popup.TraitGridGroup:RefreshLayout()
    end
    if Popup.ActionsLayout and Popup.ActionsLayout.RefreshLayout then
        Popup.ActionsLayout:RefreshLayout()
    end
    if Popup.RootLayout and Popup.RootLayout.RefreshLayout then
        Popup.RootLayout:RefreshLayout()
    end

    local frame = Popup.Window and Popup.Window.GetFrame and Popup.Window:GetFrame() or nil
    if frame and frame.SetHeight then
        frame:SetHeight(targetHeight)
    end
end

function Popup:RefreshMessageText()
    local spec = self.PendingSpec or {}
    local baseMessage = tostring(spec.message or "Are you sure?")
    local summaryText = ""
    local statusText = tostring(spec.selectionStatusText or "")
    local messageParts = { baseMessage }

    if type(spec.getGridStatusText) == "function" then
        summaryText = tostring(spec.getGridStatusText(copyArray(type(spec.selectedChoices) == "table" and spec.selectedChoices or {}), spec) or "")
    end

    if summaryText ~= "" then
        messageParts[#messageParts + 1] = summaryText
    end
    if statusText ~= "" then
        messageParts[#messageParts + 1] = statusText
    end
    local messageText = table.concat(messageParts, "\n")

    if self.MessageText and self.MessageText.SetText then
        self.MessageText:SetText(messageText)
    end

    self._messageHeight = measureTextHeight(self.MessageText, POPUP_MIN_MESSAGE_HEIGHT, POPUP_MESSAGE_MAX_HEIGHT)
    setElementVisible(self.MessageText, true, self._messageHeight)
end

local function refreshChoiceDescription()
    local spec = Popup.PendingSpec or {}
    local selectedChoice = type(spec.selectedChoice) == "string" and spec.selectedChoice or ""
    local descriptionsByValue = type(spec.choiceDescriptionsByValue) == "table" and spec.choiceDescriptionsByValue or nil
    local description = descriptionsByValue and tostring(descriptionsByValue[selectedChoice] or "") or ""
    local hasDescription = description ~= ""
    local descriptionHeight = hasDescription and measureTextHeight(Popup.ChoiceDescriptionText, POPUP_MIN_DESCRIPTION_HEIGHT, 56) or 0
    local choiceGroupHeight = POPUP_CHOICE_LABEL_HEIGHT + 2 + POPUP_CHOICE_DROPDOWN_HEIGHT
    if hasDescription then
        choiceGroupHeight = choiceGroupHeight + 2 + descriptionHeight
    end

    if Popup.ChoiceDescriptionText and Popup.ChoiceDescriptionText.SetText then
        Popup.ChoiceDescriptionText:SetText(description)
    end
    Popup._choiceDescriptionHeight = descriptionHeight
    Popup._choiceGroupHeight = Popup._hasChoices == true and choiceGroupHeight or 0
    setElementVisible(Popup.ChoiceDescriptionText, hasDescription, descriptionHeight)
    setElementVisible(Popup.ChoiceGroup, Popup._hasChoices == true, Popup._choiceGroupHeight)
    refreshPopupLayout()
end

local function getTraitGridMetrics(spec)
    local columns = math.max(1, math.floor(tonumber(spec and spec.gridVisibleColumns) or POPUP_TRAIT_GRID_COLUMNS))
    local rows = math.max(1, math.floor(tonumber(spec and spec.gridVisibleRows) or POPUP_TRAIT_GRID_ROWS))
    local showLabel = spec and spec.hideGridLabel ~= true
    local viewportWidth = POPUP_CONTENT_WIDTH - POPUP_TRAIT_GRID_SCROLLBAR_WIDTH - POPUP_TRAIT_GRID_SCROLLBAR_GAP
    local entryWidth = math.max(84, math.floor((viewportWidth - ((columns - 1) * POPUP_TRAIT_GRID_SPACING_X)) / columns))
    local contentWidth = (entryWidth * columns) + ((columns - 1) * POPUP_TRAIT_GRID_SPACING_X)
    local hostHeight = (rows * POPUP_TRAIT_GRID_ENTRY_HEIGHT) + ((rows - 1) * POPUP_TRAIT_GRID_SPACING_Y)
    local items = type(spec and spec.gridItems) == "table" and spec.gridItems or {}
    local totalRows = math.max(1, math.ceil(#items / columns))
    local contentHeight = math.max(hostHeight, (totalRows * POPUP_TRAIT_GRID_ENTRY_HEIGHT) + ((totalRows - 1) * POPUP_TRAIT_GRID_SPACING_Y))
    local rowStride = POPUP_TRAIT_GRID_ENTRY_HEIGHT + POPUP_TRAIT_GRID_SPACING_Y
    return {
        columns = columns,
        rows = rows,
        visibleItemCount = columns * rows,
        entryWidth = entryWidth,
        viewportWidth = contentWidth,
        hostHeight = hostHeight,
        contentHeight = contentHeight,
        rowStride = rowStride,
        maxScroll = math.max(0, contentHeight - hostHeight),
        groupHeight = (showLabel and (POPUP_TRAIT_GRID_LABEL_HEIGHT + POPUP_TRAIT_GRID_LABEL_SPACING) or 0) + hostHeight,
        showLabel = showLabel,
    }
end

function Popup:SetTraitGridScrollOffset(offset, skipRefresh)
    local spec = self.PendingSpec or {}
    local metrics = getTraitGridMetrics(spec)
    local rowStride = math.max(1, metrics.rowStride)
    local snappedOffset = math.floor(((tonumber(offset) or 0) + (rowStride * 0.5)) / rowStride) * rowStride
    local clampedOffset = clamp(snappedOffset, 0, metrics.maxScroll)

    self.TraitGridScrollOffset = clampedOffset

    if self.TraitGridScrollFrame and self.TraitGridScrollFrame.SetVerticalScroll then
        self.TraitGridScrollFrame:SetVerticalScroll(clampedOffset)
    end
    if self.TraitGridScrollBar and self.TraitGridScrollBar.SetValue and self._traitGridSyncingScroll ~= true then
        local currentValue = self.TraitGridScrollBar.GetValue and self.TraitGridScrollBar:GetValue() or nil
        if currentValue ~= clampedOffset then
            self._traitGridSyncingScroll = true
            self.TraitGridScrollBar:SetValue(clampedOffset)
            self._traitGridSyncingScroll = false
        end
    end

    if skipRefresh ~= true then
        self:RefreshTraitGrid()
    end

    return clampedOffset, metrics
end

function Popup:RefreshTraitGridScrollBounds(resetToSelection)
    local spec = self.PendingSpec or {}
    local items = type(spec.gridItems) == "table" and spec.gridItems or {}
    local selectedChoices = normalizeSelectedChoices(spec.selectedChoices)
    local metrics = getTraitGridMetrics(spec)
    local initialOffset = self.TraitGridScrollOffset or 0

    self.TraitGridMetrics = metrics

    if self.TraitGridHost and self.TraitGridHost.SetHeight then
        self.TraitGridHost:SetHeight(metrics.hostHeight)
    end
    local hostFrame = self.TraitGridHost and self.TraitGridHost.GetFrame and self.TraitGridHost:GetFrame() or nil
    if hostFrame and hostFrame.SetHeight then
        hostFrame:SetHeight(metrics.hostHeight)
    end

    if self.TraitGridScrollFrame then
        self.TraitGridScrollFrame:SetWidth(metrics.viewportWidth)
    end
    if self.TraitGridScrollChild and self.TraitGridScrollChild.SetSize then
        self.TraitGridScrollChild:SetSize(metrics.viewportWidth, metrics.contentHeight)
    end

    if self.TraitGridScrollBar then
        self.TraitGridScrollBar:SetMinMaxValues(0, metrics.maxScroll)
        self.TraitGridScrollBar:SetValueStep(metrics.rowStride)
        if self.TraitGridScrollBar.SetShown then
            self.TraitGridScrollBar:SetShown(metrics.maxScroll > 0)
        elseif metrics.maxScroll > 0 and self.TraitGridScrollBar.Show then
            self.TraitGridScrollBar:Show()
        elseif self.TraitGridScrollBar.Hide then
            self.TraitGridScrollBar:Hide()
        end
    end

    for entryIndex = 1, #(self.TraitGridEntries or {}) do
        local entry = self.TraitGridEntries[entryIndex]
        if entry and entry.SetLayoutMetrics then
            entry:SetLayoutMetrics(metrics.entryWidth, POPUP_TRAIT_GRID_ENTRY_HEIGHT)
        end
    end

    if resetToSelection == true then
        for index = 1, #items do
            local value = tostring(items[index] and items[index].value or "")
            if value ~= "" and selectedChoices[1] == value then
                local rowIndex = math.floor((index - 1) / metrics.columns)
                initialOffset = rowIndex * metrics.rowStride
                break
            end
        end
    end

    self:SetTraitGridScrollOffset(initialOffset, true)
end

function Popup:RefreshTraitGrid()
    local spec = self.PendingSpec or {}
    local items = type(spec.gridItems) == "table" and spec.gridItems or {}
    local selectedChoices, selectedLookup = normalizeSelectedChoices(spec.selectedChoices)
    local metrics = self.TraitGridMetrics or getTraitGridMetrics(spec)
    local scrollOffset = self.TraitGridScrollOffset or 0
    local startRow = math.floor(scrollOffset / math.max(1, metrics.rowStride)) + 1
    local startIndex = ((startRow - 1) * metrics.columns) + 1
    local tooltipProvider = type(spec.gridTooltipProvider) == "function" and spec.gridTooltipProvider or nil
    local disabledProvider = type(spec.gridDisabledProvider) == "function" and spec.gridDisabledProvider or nil
    local visibleRows = {}

    for entryIndex = 1, #(self.TraitGridEntries or {}) do
        local row = items[startIndex + entryIndex - 1]
        local entry = self.TraitGridEntries[entryIndex]
        if entry then
            local frame = entry.GetFrame and entry:GetFrame() or nil
            if row then
                local value = tostring(row.value or "")
                local label = tostring(row.label or "Unknown")
                local icon = tostring(row.icon or "")
                local itemIndex = startIndex + entryIndex - 1
                local columnIndex = (itemIndex - 1) % metrics.columns
                local rowIndex = math.floor((itemIndex - 1) / metrics.columns)
                if (tonumber(row.count) or 0) > 1 then
                    label = ("%s x%d"):format(label, tonumber(row.count) or 0)
                end

                if frame then
                    frame:ClearAllPoints()
                    frame:SetPoint(
                        "TOPLEFT",
                        self.TraitGridScrollChild,
                        "TOPLEFT",
                        columnIndex * (metrics.entryWidth + POPUP_TRAIT_GRID_SPACING_X),
                        -(rowIndex * metrics.rowStride)
                    )
                end
                entry:SetIcon(icon ~= "" and icon or DEFAULT_ICON)
                entry:SetSpellName(label)
                local isDisabled = row.disabled == true
                if disabledProvider then
                    isDisabled = isDisabled or (disabledProvider(row, copyArray(selectedChoices), spec) == true)
                end
                entry:SetEnabled(isDisabled ~= true)
                if tooltipProvider then
                    entry:SetTooltip(function(owner)
                        if not entry.gridItem then
                            return nil
                        end

                        return tooltipProvider(entry.gridItem, owner, spec)
                    end)
                else
                    entry:SetTooltip(nil)
                end
                if isDisabled == true then
                    entry:SetBorderColor(0.32, 0.34, 0.38, 1)
                elseif selectedLookup[value] == true then
                    entry:SetBorderColor(0.94, 0.74, 0.22, 1)
                else
                    entry:SetBorderColor(0.22, 0.72, 0.62, 1)
                end
                entry.gridValue = value
                entry.gridItem = row
                visibleRows[#visibleRows + 1] = row
                if frame and frame.Show then
                    frame:Show()
                end
            else
                entry:SetIcon(DEFAULT_ICON)
                entry:SetSpellName("")
                entry:SetEnabled(false)
                entry:SetTooltip(nil)
                entry:SetBorderColor(0.24, 0.24, 0.28, 1)
                entry.gridValue = nil
                entry.gridItem = nil
                if frame and frame.Hide then
                    frame:Hide()
                end
            end
        end
    end

    self.TraitGridVisibleRows = visibleRows
    spec.selectedChoices = selectedChoices
    self.PendingSpec = spec
    self:RefreshMessageText()
    refreshConfirmEnabled()
    refreshPopupLayout()
end

function Popup:ToggleTraitGridChoice(value)
    local spec = self.PendingSpec or {}
    local normalizedValue = tostring(value or "")
    if normalizedValue == "" then
        return false
    end

    local selectedChoices, selectedLookup = normalizeSelectedChoices(spec.selectedChoices)
    local selecting = selectedLookup[normalizedValue] ~= true
    local nextSelectedChoices = nil
    local statusText = ""

    if type(spec.onGridSelectionChanged) == "function" then
        nextSelectedChoices, statusText = spec.onGridSelectionChanged(normalizedValue, selecting, copyArray(selectedChoices), spec)
    end

    if type(nextSelectedChoices) ~= "table" then
        nextSelectedChoices = copyArray(selectedChoices)
        if selecting then
            nextSelectedChoices[#nextSelectedChoices + 1] = normalizedValue
        else
            for index = #nextSelectedChoices, 1, -1 do
                if tostring(nextSelectedChoices[index] or "") == normalizedValue then
                    table.remove(nextSelectedChoices, index)
                end
            end
        end
    end

    spec.selectedChoices = normalizeSelectedChoices(nextSelectedChoices)
    spec.selectionStatusText = tostring(statusText or "")
    self.PendingSpec = spec
    if type(spec.onChoiceChanged) == "function" then
        spec.onChoiceChanged(copyArray(spec.selectedChoices), spec)
    end
    self:RefreshTraitGrid()
    return true
end

function Popup:Build()
    if self.Window then
        return self.Window
    end

    local window = UI.Window:New({
        name = "RPEPopupWindow",
        width = 420,
        height = 198,
        point = "CENTER",
        relativeTo = UIParent,
        relativePoint = "CENTER",
        frameStrata = "DIALOG",
        frameLevel = 80,
        movable = false,
        clampedToScreen = true,
        toplevel = true,
        hidden = true,
        contentInsetLeft = 10,
        contentInsetRight = 10,
        contentInsetTop = 28,
        contentInsetBottom = 10,
        onClose = function()
            Popup:HandleCancel("close")
        end,
    })
    window:SetTitle("Confirm")
    window:Create()
    self.Window = window

    local root = UI.CreateLayout(UI.VerticalLayoutGroup, window:GetContentFrame(), "RPEPopupRootLayout", {
        spacing = POPUP_ROOT_SPACING,
        fitChildrenWidth = true,
        fitChildrenHeight = false,
    })
    UI.Utils.AnchorFill(root, window:GetContentFrame(), 0, 0, 0, 0)
    self.RootLayout = root

    self.MessageText = UI.CreateText(root:GetFrame(), "RPEPopupMessageText", "", {
        width = POPUP_CONTENT_WIDTH,
        height = POPUP_MIN_MESSAGE_HEIGHT,
        justifyH = "LEFT",
        justifyV = "TOP",
        wordWrap = true,
        textColor = UI.ResolveColor(nil, "text.primary"),
    })
    root:AddChild(self.MessageText)

    self.ChoiceGroup = UI.CreateLayout(UI.VerticalLayoutGroup, root:GetFrame(), "RPEPopupChoiceGroup", {
        spacing = 2,
        fitChildrenWidth = true,
        fitChildrenHeight = false,
        height = POPUP_CHOICE_LABEL_HEIGHT + 2 + POPUP_CHOICE_DROPDOWN_HEIGHT,
    })
    root:AddChild(self.ChoiceGroup)

    self.ChoiceLabel = UI.CreateText(self.ChoiceGroup:GetFrame(), "RPEPopupChoiceLabel", "Select", {
        width = POPUP_CONTENT_WIDTH,
        height = POPUP_CHOICE_LABEL_HEIGHT,
        justifyH = "LEFT",
        textColor = UI.ResolveColor(nil, "text.secondary"),
    })
    self.ChoiceGroup:AddChild(self.ChoiceLabel)

    self.ChoiceDropdown = UI.CreateDropdown(self.ChoiceGroup:GetFrame(), "RPEPopupChoiceDropdown", {
        width = POPUP_CONTENT_WIDTH,
        height = POPUP_CHOICE_DROPDOWN_HEIGHT,
        items = {
            { label = "None", value = "" },
        },
        onValueChanged = function(value)
            local spec = Popup.PendingSpec or {}
            spec.selectedChoice = tostring(value or "")
            Popup.PendingSpec = spec
            refreshConfirmEnabled()
            refreshChoiceDescription()
            if type(spec.onChoiceChanged) == "function" then
                spec.onChoiceChanged(spec.selectedChoice, spec)
            end
        end,
    })
    self.ChoiceGroup:AddChild(self.ChoiceDropdown)

    self.ChoiceDescriptionText = UI.CreateText(self.ChoiceGroup:GetFrame(), "RPEPopupChoiceDescriptionText", "", {
        width = POPUP_CONTENT_WIDTH,
        height = POPUP_MIN_DESCRIPTION_HEIGHT,
        justifyH = "LEFT",
        justifyV = "TOP",
        wordWrap = true,
        textColor = UI.ResolveColor(nil, "text.secondary"),
    })
    self.ChoiceGroup:AddChild(self.ChoiceDescriptionText)
    setElementVisible(self.ChoiceDescriptionText, false, POPUP_MIN_DESCRIPTION_HEIGHT)
    setElementVisible(self.ChoiceGroup, false, POPUP_CHOICE_LABEL_HEIGHT + 2 + POPUP_CHOICE_DROPDOWN_HEIGHT)

    self.TraitGridGroup = UI.CreateLayout(UI.VerticalLayoutGroup, root:GetFrame(), "RPEPopupTraitGridGroup", {
        spacing = POPUP_TRAIT_GRID_LABEL_SPACING,
        fitChildrenWidth = true,
        fitChildrenHeight = false,
        height = POPUP_TRAIT_GRID_GROUP_HEIGHT,
    })
    root:AddChild(self.TraitGridGroup)

    self.TraitGridLabel = UI.CreateText(self.TraitGridGroup:GetFrame(), "RPEPopupTraitGridLabel", "Consumables", {
        width = POPUP_CONTENT_WIDTH,
        height = POPUP_TRAIT_GRID_LABEL_HEIGHT,
        justifyH = "LEFT",
        textColor = UI.ResolveColor(nil, "text.secondary"),
    })
    self.TraitGridGroup:AddChild(self.TraitGridLabel)

    self.TraitGridHost = UI.CreatePanel(self.TraitGridGroup:GetFrame(), "RPEPopupTraitGridHost", {
        width = POPUP_CONTENT_WIDTH,
        height = POPUP_TRAIT_GRID_HOST_HEIGHT,
        showBorder = false,
        panelBackgroundColor = { r = 0, g = 0, b = 0, a = 0 },
    })
    self.TraitGridGroup:AddChild(self.TraitGridHost)

    self.TraitGridScrollFrame = CreateFrame("ScrollFrame", "RPEPopupTraitGridScrollFrame", self.TraitGridHost:GetContentFrame())
    self.TraitGridScrollFrame:SetPoint("TOPLEFT", self.TraitGridHost:GetContentFrame(), "TOPLEFT", 0, 0)
    self.TraitGridScrollFrame:SetPoint("BOTTOMLEFT", self.TraitGridHost:GetContentFrame(), "BOTTOMLEFT", 0, 0)
    self.TraitGridScrollFrame:SetWidth(POPUP_CONTENT_WIDTH - POPUP_TRAIT_GRID_SCROLLBAR_WIDTH - POPUP_TRAIT_GRID_SCROLLBAR_GAP)
    self.TraitGridScrollFrame:EnableMouseWheel(true)
    if self.TraitGridScrollFrame.SetClipsChildren then
        self.TraitGridScrollFrame:SetClipsChildren(true)
    end

    self.TraitGridScrollChild = CreateFrame("Frame", "RPEPopupTraitGridScrollChild", self.TraitGridScrollFrame)
    self.TraitGridScrollChild:SetPoint("TOPLEFT", self.TraitGridScrollFrame, "TOPLEFT", 0, 0)
    self.TraitGridScrollChild:SetSize(POPUP_CONTENT_WIDTH, POPUP_TRAIT_GRID_HOST_HEIGHT)
    self.TraitGridScrollFrame:SetScrollChild(self.TraitGridScrollChild)
    self.TraitGridScrollFrame:SetScript("OnMouseWheel", function(_, delta)
        local rowStride = self.TraitGridMetrics and self.TraitGridMetrics.rowStride or (POPUP_TRAIT_GRID_ENTRY_HEIGHT + POPUP_TRAIT_GRID_SPACING_Y)
        Popup:SetTraitGridScrollOffset((Popup.TraitGridScrollOffset or 0) - ((tonumber(delta) or 0) * rowStride))
    end)

    self.TraitGridScrollBar = CreateFrame("Slider", "RPEPopupTraitGridScrollBar", self.TraitGridHost:GetContentFrame())
    self.TraitGridScrollBar:SetPoint("TOPLEFT", self.TraitGridScrollFrame, "TOPRIGHT", POPUP_TRAIT_GRID_SCROLLBAR_GAP, 0)
    self.TraitGridScrollBar:SetPoint("BOTTOMLEFT", self.TraitGridScrollFrame, "BOTTOMRIGHT", POPUP_TRAIT_GRID_SCROLLBAR_GAP, 0)
    self.TraitGridScrollBar:SetOrientation("VERTICAL")
    self.TraitGridScrollBar:SetMinMaxValues(0, 0)
    self.TraitGridScrollBar:SetValueStep(POPUP_TRAIT_GRID_ENTRY_HEIGHT + POPUP_TRAIT_GRID_SPACING_Y)
    if self.TraitGridScrollBar.SetObeyStepOnDrag then
        self.TraitGridScrollBar:SetObeyStepOnDrag(true)
    end
    self.TraitGridScrollBar:SetWidth(POPUP_TRAIT_GRID_SCROLLBAR_WIDTH)

    self.TraitGridScrollBarTrack = self.TraitGridScrollBarTrack or self.TraitGridScrollBar:CreateTexture(nil, "BACKGROUND")
    self.TraitGridScrollBarTrack:SetAllPoints(self.TraitGridScrollBar)
    do
        local trackColor = UI.ResolveColor(nil, "scrollbar.track")
        self.TraitGridScrollBarTrack:SetColorTexture(trackColor.r or 0.08, trackColor.g or 0.09, trackColor.b or 0.11, trackColor.a or 0.95)
    end

    self.TraitGridScrollBar:SetThumbTexture("Interface\\Buttons\\WHITE8x8")
    do
        local thumb = self.TraitGridScrollBar.GetThumbTexture and self.TraitGridScrollBar:GetThumbTexture() or nil
        if thumb and thumb.SetVertexColor then
            local thumbColor = UI.ResolveColor(nil, "scrollbar.thumb")
            thumb:SetVertexColor(thumbColor.r or 0.42, thumbColor.g or 0.46, thumbColor.b or 0.52, thumbColor.a or 1)
        end
    end
    self.TraitGridScrollBar:SetValue(0)
    self.TraitGridScrollBar:SetScript("OnValueChanged", function(_, value)
        if Popup._traitGridSyncingScroll == true then
            return
        end

        Popup:SetTraitGridScrollOffset(value or 0)
    end)

    local spellbookEntryClass = UI.SpellbookEntry
    if type(spellbookEntryClass) ~= "table" or type(spellbookEntryClass.New) ~= "function" then
        error("Popup trait grid requires UI.SpellbookEntry to be loaded before Popup:Build().", 2)
    end

    self.TraitGridEntries = {}
    for index = 1, POPUP_TRAIT_GRID_COLUMNS * POPUP_TRAIT_GRID_ROWS do
        local entry = spellbookEntryClass:New({
            name = ("RPEPopupTraitGridEntry%d"):format(index),
            width = 96,
            height = POPUP_TRAIT_GRID_ENTRY_HEIGHT,
            iconTexture = DEFAULT_ICON,
            border = false,
        })
        entry:SetParent(self.TraitGridScrollChild)
        entry:Create()
        local frame = entry:GetFrame()
        if frame then
            frame:HookScript("OnMouseUp", function(_, button)
                if button == "LeftButton" and entry.gridValue then
                    Popup:ToggleTraitGridChoice(entry.gridValue)
                end
            end)
        end
        self.TraitGridEntries[#self.TraitGridEntries + 1] = entry
    end
    self._traitGridGroupHeight = POPUP_TRAIT_GRID_GROUP_HEIGHT
    setElementVisible(self.TraitGridGroup, false, POPUP_TRAIT_GRID_GROUP_HEIGHT)

    local actions = UI.CreateLayout(UI.HorizontalLayoutGroup, root:GetFrame(), "RPEPopupActions", {
        spacing = 6,
        width = POPUP_CONTENT_WIDTH,
        fitChildrenWidth = true,
        fitChildrenHeight = false,
        height = POPUP_ACTIONS_HEIGHT,
    })
    root:AddChild(actions)
    self.ActionsLayout = actions

    self.ActionsSpacer = UI.CreatePanel(actions:GetFrame(), "RPEPopupActionsSpacer", {
        width = 0,
        height = POPUP_ACTIONS_HEIGHT,
        expandWidth = true,
        showBorder = false,
        panelBackgroundColor = { r = 0, g = 0, b = 0, a = 0 },
    })
    actions:AddChild(self.ActionsSpacer)

    self.ConfirmButton = UI.CreateButton(actions:GetFrame(), "RPEPopupConfirmButton", "Confirm", 72, function()
        Popup:HandleConfirm()
    end, {
        height = POPUP_ACTIONS_HEIGHT,
        fontSize = 7,
    })
    actions:AddChild(self.ConfirmButton)

    self.CancelButton = UI.CreateButton(actions:GetFrame(), "RPEPopupCancelButton", "Cancel", 72, function()
        Popup:HandleCancel("cancel")
    end, {
        height = POPUP_ACTIONS_HEIGHT,
        fontSize = 7,
    })
    actions:AddChild(self.CancelButton)

    return window
end

function Popup:Hide()
    if self.Window and self.Window.Hide then
        self.Window:Hide()
    end

    return self.Window
end

function Popup:HandleConfirm()
    local spec = self.PendingSpec or {}
    local onConfirm = spec.onConfirm

    self.PendingSpec = nil
    self:Hide()

    if type(onConfirm) == "function" then
        return onConfirm(spec)
    end

    return true
end

function Popup:HandleCancel(reason)
    local spec = self.PendingSpec or {}
    local onCancel = spec.onCancel

    self.PendingSpec = nil
    self:Hide()

    if type(onCancel) == "function" then
        return onCancel(reason, spec)
    end

    return false
end

function Popup:ShowConfirmation(options)
    local spec = options or {}
    local window = self:Build()

    spec.selectionStatusText = tostring(spec.selectionStatusText or "")
    self.PendingSpec = spec

    if window and window.SetTitle then
        window:SetTitle(tostring(spec.title or "Confirm"))
    end

    self:RefreshMessageText()

    local gridItems = type(spec.gridItems) == "table" and spec.gridItems or nil
    local hasTraitGrid = gridItems ~= nil and #gridItems > 0
    local choiceItems = type(spec.choiceItems) == "table" and spec.choiceItems or nil
    local hasChoices = not hasTraitGrid and choiceItems ~= nil and #choiceItems > 0
    self._hasChoices = hasChoices
    self._hasTraitGrid = hasTraitGrid
    if hasChoices and self.ChoiceLabel and self.ChoiceLabel.SetText then
        self.ChoiceLabel:SetText(tostring(spec.choiceLabel or "Select"))
    end
    if hasChoices and self.ChoiceDropdown and self.ChoiceDropdown.SetItems then
        self.ChoiceDropdown:SetItems(choiceItems)
        self.ChoiceDropdown:SetSelectedValue(tostring(spec.selectedChoice or ""), true)
    end
    setElementVisible(self.ChoiceGroup, hasChoices, POPUP_CHOICE_LABEL_HEIGHT + 2 + POPUP_CHOICE_DROPDOWN_HEIGHT)
    refreshChoiceDescription()

    if hasTraitGrid and self.TraitGridLabel and self.TraitGridLabel.SetText then
        self.TraitGridLabel:SetText(tostring(spec.choiceLabel or "Consumables"))
    end
    if hasTraitGrid then
        local metrics = getTraitGridMetrics(spec)
        local selectedChoices = normalizeSelectedChoices(spec.selectedChoices)
        spec.selectedChoices = selectedChoices
        self.PendingSpec = spec
        if self.TraitGridGroup and self.TraitGridGroup.options then
            self.TraitGridGroup.options.spacing = metrics.showLabel and POPUP_TRAIT_GRID_LABEL_SPACING or 0
        end
        setElementVisible(self.TraitGridLabel, metrics.showLabel, POPUP_TRAIT_GRID_LABEL_HEIGHT)
        self._traitGridGroupHeight = metrics.groupHeight
        setElementVisible(self.TraitGridGroup, true, self._traitGridGroupHeight)
        self:RefreshTraitGridScrollBounds(true)
        self:RefreshTraitGrid()
    else
        setElementVisible(self.TraitGridLabel, false, POPUP_TRAIT_GRID_LABEL_HEIGHT)
        setElementVisible(self.TraitGridGroup, false, self._traitGridGroupHeight or POPUP_TRAIT_GRID_GROUP_HEIGHT)
    end

    if self.ConfirmButton and self.ConfirmButton.SetText then
        self.ConfirmButton:SetText(tostring(spec.confirmText or "Confirm"))
    end

    if self.CancelButton and self.CancelButton.SetText then
        self.CancelButton:SetText(tostring(spec.cancelText or "Cancel"))
    end

    refreshConfirmEnabled()
    refreshPopupLayout()

    if window and window.Show then
        window:Show()
    end

    return window
end
