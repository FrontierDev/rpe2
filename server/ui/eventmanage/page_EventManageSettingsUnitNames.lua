local _, Addon = ...

Addon.Server = Addon.Server or {}
Addon.Server.UI = Addon.Server.UI or {}

local Server = Addon.Server
local EventManage = Addon.Server.UI.EventManage
local EventUnit = Addon.Internal
    and Addon.Internal.Database
    and Addon.Internal.Database.Classes
    and Addon.Internal.Database.Classes.EventUnit
    or nil
local UI = Addon.UI or {}
local C = UI.Constants or {}

if type(EventManage) ~= "table" or type(EventUnit) ~= "table" or EventManage._unitNamesSettingsInstalled == true then
    return
end

local CONTROL_HEIGHT = 20
local BUTTON_FONT_SIZE = 7
local SETTINGS_EDITOR_HEIGHT = 40
local UNIT_NAME_ERROR_TEXT = {
    ["display-name-too-long"] = "Display name is too long.",
    ["display-name-contains-unsafe-characters"] = "Display name contains unsupported markup or control characters.",
    ["display-name-required"] = "Enter a display name.",
    ["event-unit-display-name-broadcast-failed"] = "The rename was not sent to the event.",
    ["event-unit-display-name-broadcast-unavailable"] = "The event rename transport is unavailable.",
    ["local-event-host-required"] = "Only the event host can rename NPCs.",
}

local function trim(value)
    return tostring(value or ""):gsub("^%s+", ""):gsub("%s+$", "")
end

local function copyIds(values)
    local result = {}
    for index = 1, #(values or {}) do
        result[#result + 1] = math.floor(tonumber(values[index]) or 0)
    end
    table.sort(result)
    return result
end

local function formatAffectedUnits(eventIds)
    local parts = {}
    for index = 1, #(eventIds or {}) do
        parts[#parts + 1] = "#" .. tostring(eventIds[index])
    end
    return table.concat(parts, ", ")
end

local function resolveDerivedName(unit)
    if type(unit) == "table" and type(unit.GetResolvedVariantName) == "function" then
        local ok, name = pcall(unit.GetResolvedVariantName, unit)
        if ok and trim(name) ~= "" then
            return trim(name)
        end
    end
    return trim(unit and unit.name) ~= "" and trim(unit.name) or "Unnamed Unit"
end

local function resolveDisplayName(unit)
    local override = type(EventUnit.NormalizeDisplayNameOverride) == "function"
        and EventUnit.NormalizeDisplayNameOverride(unit and unit.displayNameOverride)
        or trim(unit and unit.displayNameOverride)
    return override or ""
end

local function buildRows(eventState)
    local groups = {}
    local groupByKey = {}
    local units = eventState and eventState.units or {}

    for index = 1, #units do
        local unit = units[index]
        local eventId = math.floor(tonumber(unit and unit.eventID) or 0)
        local displayName = resolveDisplayName(unit)
        if eventId > 0 and unit and unit.isPlayer ~= true and displayName ~= "" then
            local derivedName = resolveDerivedName(unit)
            local key = derivedName .. string.char(31) .. displayName
            local group = groupByKey[key]
            if not group then
                group = {
                    groupKey = key,
                    derivedName = derivedName,
                    displayName = displayName,
                    eventIds = {},
                }
                groupByKey[key] = group
                groups[#groups + 1] = group
            end
            group.eventIds[#group.eventIds + 1] = eventId
        end
    end

    table.sort(groups, function(left, right)
        local leftDerived = string.lower(left.derivedName)
        local rightDerived = string.lower(right.derivedName)
        if leftDerived ~= rightDerived then
            return leftDerived < rightDerived
        end
        if left.displayName ~= right.displayName then
            return string.lower(left.displayName) < string.lower(right.displayName)
        end
        return (left.eventIds[1] or 0) < (right.eventIds[1] or 0)
    end)

    local rows = {}
    for index = 1, #groups do
        local group = groups[index]
        table.sort(group.eventIds)
        rows[#rows + 1] = {
            rowIndex = index,
            groupKey = group.groupKey,
            derivedName = group.derivedName,
            displayName = group.displayName,
            affectedUnits = formatAffectedUnits(group.eventIds),
            eventIds = copyIds(group.eventIds),
        }
    end
    return rows
end

local function buildNpcPickerItems(eventState)
    local values = {}
    for index = 1, #((eventState and eventState.units) or {}) do
        local unit = eventState.units[index]
        local eventId = math.floor(tonumber(unit and unit.eventID) or 0)
        if eventId > 0 and unit and unit.isPlayer ~= true then
            values[#values + 1] = {
                eventId = eventId,
                label = ("#%d - %s"):format(eventId, resolveDerivedName(unit)),
                value = tostring(eventId),
            }
        end
    end
    table.sort(values, function(left, right)
        return left.eventId < right.eventId
    end)
    return values
end

local function createLabel(parent, name, text, width)
    return UI.CreateText(parent, name, text, {
        width = width,
        height = CONTROL_HEIGHT,
        fontFile = (C.FontFiles and C.FontFiles.Default) or "Fonts\\FRIZQT__.TTF",
        fontSize = (C.FontSizes and C.FontSizes.Body) or 8,
        textColor = UI.ResolveColor(nil, "text.secondary"),
        justifyH = "LEFT",
        justifyV = "MIDDLE",
        wordWrap = false,
    })
end

local function createRow(parent, name, width, height)
    return UI.CreateLayout(UI.HorizontalLayoutGroup, parent, name, {
        width = width,
        height = height or CONTROL_HEIGHT,
        spacing = 4,
        autoSize = false,
        fitChildrenWidth = false,
        fitChildrenHeight = false,
    })
end

local function setValidation(self, message, isError)
    if self.SettingsUnitNameValidationText and self.SettingsUnitNameValidationText.SetText then
        self.SettingsUnitNameValidationText:SetText(tostring(message or ""))
        local color = UI.ResolveColor(nil, isError == true and "danger" or "text.secondary")
        if color and self.SettingsUnitNameValidationText.SetTextColor then
            self.SettingsUnitNameValidationText:SetTextColor(color.r, color.g, color.b, color.a)
        end
    end
end

local function formatUnitNameError(reason)
    local normalized = tostring(reason or "Unable to update display name.")
    return UNIT_NAME_ERROR_TEXT[normalized] or normalized
end

function EventManage:SetSelectedSettingsUnitNameIndex(index)
    local eventState = Server.GetEditableEventState and Server:GetEditableEventState() or nil
    local rows = buildRows(eventState)
    local row = rows[math.floor(tonumber(index) or 0)]
    self.SelectedEventUnitNameKey = row and row.groupKey or nil
    self:RefreshSettingsPage()
end

function EventManage:BuildUnitNameRows()
    local eventState = Server.GetEditableEventState and Server:GetEditableEventState() or nil
    return buildRows(eventState)
end

local baseGetSettingsSections = EventManage.GetSettingsSectionPageDefinitions
function EventManage:GetSettingsSectionPageDefinitions()
    local pages = type(baseGetSettingsSections) == "function"
        and baseGetSettingsSections(self)
        or {}
    pages[#pages + 1] = {
        key = "unitNames",
        label = "Unit Names",
        columns = self.SettingsUnitNameColumns,
        editor = self.SettingsUnitNameEditor,
    }
    return pages
end

local baseBuildSettingsRows = EventManage.BuildSettingsSharedRows
function EventManage:BuildSettingsSharedRows(sectionKey, eventState)
    if sectionKey == "unitNames" then
        local authoritativeState = Server.GetEditableEventState and Server:GetEditableEventState() or eventState
        local rows = buildRows(authoritativeState)
        local selectedIndex = nil
        for index = 1, #rows do
            if rows[index].groupKey == self.SelectedEventUnitNameKey then
                selectedIndex = index
                break
            end
        end
        return rows, selectedIndex, function(index)
            self:SetSelectedSettingsUnitNameIndex(index)
        end
    end
    return baseBuildSettingsRows(self, sectionKey, eventState)
end

function EventManage:RefreshUnitNameEditor()
    local eventState = Server.GetEditableEventState and Server:GetEditableEventState() or nil
    local rows = buildRows(eventState)
    local unitNamesActive = self.GetActiveSettingsSectionKey
        and self:GetActiveSettingsSectionKey() == "unitNames"
    if unitNamesActive and self.SettingsEditorHost then
        self.SettingsEditorHost._visibleHeight = SETTINGS_EDITOR_HEIGHT
        if self.SettingsEditorHost.SetHeight then
            self.SettingsEditorHost:SetHeight(SETTINGS_EDITOR_HEIGHT)
        end
        local hostFrame = self.SettingsEditorHost.GetFrame and self.SettingsEditorHost:GetFrame() or nil
        if hostFrame and hostFrame.SetHeight then
            hostFrame:SetHeight(SETTINGS_EDITOR_HEIGHT)
        end
    end
    local selectedRow = nil
    for index = 1, #rows do
        if rows[index].groupKey == self.SelectedEventUnitNameKey then
            selectedRow = rows[index]
            break
        end
    end
    if not selectedRow then
        self.SelectedEventUnitNameKey = nil
    end

    if self.SettingsUnitNameDisplayInput and self.SettingsUnitNameDisplayInput.SetText then
        self.SettingsUnitNameDisplayInput:SetText(selectedRow and selectedRow.displayName or "")
    end

    local pickerItems = buildNpcPickerItems(eventState)
    if self.SettingsUnitNameUnitsDropdown and self.SettingsUnitNameUnitsDropdown.SetItems then
        self.SettingsUnitNameUnitsDropdown:SetItems(pickerItems)
        local selectedIds = selectedRow and selectedRow.eventIds or {}
        local available = {}
        for index = 1, #pickerItems do
            available[tonumber(pickerItems[index].value)] = true
        end
        local selectedValues = {}
        for index = 1, #selectedIds do
            if available[selectedIds[index]] then
                selectedValues[#selectedValues + 1] = tostring(selectedIds[index])
            end
        end
        self.SettingsUnitNameUnitsDropdown:SetSelectedValues(selectedValues, true)
    end

    if self.SettingsUnitNameApplyButton and self.SettingsUnitNameApplyButton.SetText then
        self.SettingsUnitNameApplyButton:SetText(selectedRow and "Apply" or "Add")
    end
    if self.SettingsUnitNameResetButton and self.SettingsUnitNameResetButton.SetEnabled then
        self.SettingsUnitNameResetButton:SetEnabled(selectedRow ~= nil)
    end

    if self.SettingsRootLayout and self.SettingsRootLayout.RefreshLayout then
        self.SettingsRootLayout:RefreshLayout()
    end
end

function EventManage:ApplyUnitNameEditor()
    local selectedValues = self.SettingsUnitNameUnitsDropdown
        and self.SettingsUnitNameUnitsDropdown.GetSelectedValues
        and self.SettingsUnitNameUnitsDropdown:GetSelectedValues()
        or {}
    if #selectedValues == 0 then
        setValidation(self, "Select at least one NPC.", true)
        return false
    end

    local displayName = trim(self.SettingsUnitNameDisplayInput and self.SettingsUnitNameDisplayInput.GetText
        and self.SettingsUnitNameDisplayInput:GetText() or "")
    if displayName == "" then
        setValidation(self, "Enter a display name.", true)
        return false
    end

    local previousRow = nil
    local rows = self:BuildUnitNameRows()
    for index = 1, #rows do
        if rows[index].groupKey == self.SelectedEventUnitNameKey then
            previousRow = rows[index]
            break
        end
    end

    local eventIds = {}
    for index = 1, #selectedValues do
        eventIds[#eventIds + 1] = tonumber(selectedValues[index]) or selectedValues[index]
    end
    local ok, reason = Server:SetEventUnitDisplayNameOverrides(eventIds, displayName, {
        previousEventIds = previousRow and previousRow.eventIds or nil,
        previousDisplayName = previousRow and previousRow.displayName or nil,
    })
    if ok ~= true then
        setValidation(self, formatUnitNameError(reason), true)
        return false
    end

    self.SelectedEventUnitNameKey = nil
    setValidation(self, "Display name applied.", false)
    self:RefreshSettingsPage()
    return true
end

function EventManage:ResetSelectedUnitName()
    local rows = self:BuildUnitNameRows()
    local selectedRow = nil
    for index = 1, #rows do
        if rows[index].groupKey == self.SelectedEventUnitNameKey then
            selectedRow = rows[index]
            break
        end
    end
    if not selectedRow then
        setValidation(self, "Select a configured name to reset.", true)
        return false
    end

    local ok, reason = Server:SetEventUnitDisplayNameOverrides(selectedRow.eventIds, nil, {
        reset = true,
        previousEventIds = selectedRow.eventIds,
        previousDisplayName = selectedRow.displayName,
    })
    if ok ~= true then
        setValidation(self, formatUnitNameError(reason), true)
        return false
    end

    self.SelectedEventUnitNameKey = nil
    setValidation(self, "Display name reset.", false)
    self:RefreshSettingsPage()
    return true
end

local baseRefreshSettingsPage = EventManage.RefreshSettingsPage
function EventManage:RefreshSettingsPage(...)
    local result = type(baseRefreshSettingsPage) == "function" and baseRefreshSettingsPage(self, ...) or nil
    self:RefreshUnitNameEditor()
    return result
end

local function buildEditor(self)
    if self.SettingsUnitNameEditor or not self.SettingsEditorHost then
        return
    end

    local width = self.Layout and (self.Layout.SettingsWidth or self.Layout.PageContentWidth) or 480
    local parent = self.SettingsEditorHost.GetContentFrame and self.SettingsEditorHost:GetContentFrame() or self.SettingsEditorHost:GetFrame()
    local editor = UI.CreateLayout(UI.VerticalLayoutGroup, parent, "RPEServerEventManageSettingsUnitNameEditor", {
        width = width,
        height = SETTINGS_EDITOR_HEIGHT,
        spacing = 2,
        autoSize = false,
        fitChildrenWidth = false,
        fitChildrenHeight = false,
    })
    editor._visibleHeight = SETTINGS_EDITOR_HEIGHT
    editor:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, 0)
    editor:SetPoint("TOPRIGHT", parent, "TOPRIGHT", 0, 0)
    self.SettingsUnitNameEditor = editor

    local firstRow = createRow(editor:GetFrame(), "RPEServerEventManageSettingsUnitNameEditorRow", width)
    firstRow:AddChild(createLabel(firstRow:GetFrame(), "RPEServerEventManageSettingsUnitNameDisplayLabel", "Display", 40))
    self.SettingsUnitNameDisplayInput = UI.CreateTextInput(firstRow:GetFrame(), "RPEServerEventManageSettingsUnitNameDisplayInput", {
        width = 118,
        height = CONTROL_HEIGHT,
        text = "",
        borderColor = UI.ResolveColor(nil, "panel.border"),
    })
    firstRow:AddChild(self.SettingsUnitNameDisplayInput)
    firstRow:AddChild(createLabel(firstRow:GetFrame(), "RPEServerEventManageSettingsUnitNameUnitsLabel", "NPCs", 28))
    self.SettingsUnitNameUnitsDropdown = UI.CreateDropdown(firstRow:GetFrame(), "RPEServerEventManageSettingsUnitNameUnitsDropdown", {
        width = 160,
        height = CONTROL_HEIGHT,
        items = {},
        multiSelect = true,
        selectedValues = {},
        placeholder = "Select NPCs",
        onValueChanged = function(values)
            self.SelectedEventUnitNameIds = values or {}
        end,
    })
    firstRow:AddChild(self.SettingsUnitNameUnitsDropdown)
    self.SettingsUnitNameApplyButton = UI.CreateButton(firstRow:GetFrame(), "RPEServerEventManageSettingsUnitNameApplyButton", "Add", 42, function()
        self:ApplyUnitNameEditor()
    end, { height = CONTROL_HEIGHT, fontSize = BUTTON_FONT_SIZE })
    firstRow:AddChild(self.SettingsUnitNameApplyButton)
    self.SettingsUnitNameResetButton = UI.CreateButton(firstRow:GetFrame(), "RPEServerEventManageSettingsUnitNameResetButton", "Reset", 48, function()
        self:ResetSelectedUnitName()
    end, { height = CONTROL_HEIGHT, fontSize = BUTTON_FONT_SIZE })
    firstRow:AddChild(self.SettingsUnitNameResetButton)
    editor:AddChild(firstRow)

    self.SettingsUnitNameValidationText = UI.CreateText(editor:GetFrame(), "RPEServerEventManageSettingsUnitNameValidationText", "", {
        width = width,
        height = 16,
        fontFile = (C.FontFiles and C.FontFiles.Default) or "Fonts\\FRIZQT__.TTF",
        fontSize = (C.FontSizes and C.FontSizes.Body) or 8,
        textColor = UI.ResolveColor(nil, "text.secondary"),
        justifyH = "LEFT",
        justifyV = "MIDDLE",
        wordWrap = false,
    })
    editor:AddChild(self.SettingsUnitNameValidationText)
end

local baseBuildSettingsPage = EventManage.BuildSettingsPage
function EventManage:BuildSettingsPage(page, ...)
    local result = type(baseBuildSettingsPage) == "function" and baseBuildSettingsPage(self, page, ...) or nil
    self.SettingsUnitNameColumns = {
        { key = "derivedName", label = "Derived Unit Name", width = 150, justifyH = "LEFT" },
        { key = "displayName", label = "Display Name", width = 150, justifyH = "LEFT" },
        { key = "affectedUnits", label = "Affected Units", width = 166, justifyH = "LEFT" },
    }
    buildEditor(self)
    self:RefreshSettingsPage()
    return result
end

EventManage._unitNamesSettingsInstalled = true
