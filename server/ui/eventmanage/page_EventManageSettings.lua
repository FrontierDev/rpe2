local _, Addon = ...

Addon.Server = Addon.Server or {}
Addon.Server.UI = Addon.Server.UI or {}
Addon.Client = Addon.Client or {}

local Server = Addon.Server
local ServerUI = Addon.Server.UI
local Client = Addon.Client
local Database = Addon.Internal and Addon.Internal.Database or {}
local EventClass = Addon.Internal and Addon.Internal.Database and Addon.Internal.Database.Classes and Addon.Internal.Database.Classes.Event or nil
local Registry = Addon.Internal and Addon.Internal.Registry or {}
local Ruleset = Addon.Internal and Addon.Internal.Ruleset or {}
local Common = Addon.Utils and Addon.Utils.Common or {}
local UI = Addon.UI or {}
local C = UI.Constants or {}

ServerUI.EventManage = ServerUI.EventManage or {}
local EventManage = ServerUI.EventManage

local CONTROL_HEIGHT = 20
local DROPDOWN_HEIGHT = 18
local LABEL_HEIGHT = 18
local BUTTON_FONT_SIZE = 7
local LABEL_WIDTH = 72
local PREVIEW_SIZE = 16
local TABLE_ROW_HEIGHT = 18
local TABLE_HEADER_HEIGHT = 14
local EVENT_DIFFICULTY_ORDER = { "normal", "heroic", "mythic" }

local function deepCopy(value)
    if type(value) ~= "table" then
        return value
    end

    local copy = {}
    for key, nestedValue in pairs(value) do
        copy[key] = deepCopy(nestedValue)
    end

    return copy
end

local function copyColor(color)
    return {
        r = tonumber(color and color.r) or 0,
        g = tonumber(color and color.g) or 0,
        b = tonumber(color and color.b) or 0,
        a = tonumber(color and color.a) or 1,
    }
end

local function getDefaultTeamColors()
    if EventClass and EventClass.GetDefaultTeamColors then
        return EventClass.GetDefaultTeamColors()
    end

    return {
        [1] = { r = 0.35, g = 0.65, b = 1.00, a = 1.00 },
        [2] = { r = 1.00, g = 0.40, b = 0.35, a = 1.00 },
        [3] = { r = 0.40, g = 0.90, b = 0.45, a = 1.00 },
        [4] = { r = 0.75, g = 0.55, b = 1.00, a = 1.00 },
    }
end

local function getDefaultTeamColor(index)
    local defaults = getDefaultTeamColors()
    local normalizedIndex = math.max(1, math.floor(tonumber(index) or 1))
    return copyColor(defaults[((normalizedIndex - 1) % #defaults) + 1])
end

local function formatColorHex(color)
    local resolved = copyColor(color)
    return ("#%02X%02X%02X"):format(
        math.floor(math.max(0, math.min(255, resolved.r * 255)) + 0.5),
        math.floor(math.max(0, math.min(255, resolved.g * 255)) + 0.5),
        math.floor(math.max(0, math.min(255, resolved.b * 255)) + 0.5)
    )
end

local function formatInlineColorHex(color)
    local resolved = copyColor(color)
    local red = math.floor(math.max(0, math.min(255, resolved.r * 255)) + 0.5)
    local green = math.floor(math.max(0, math.min(255, resolved.g * 255)) + 0.5)
    local blue = math.floor(math.max(0, math.min(255, resolved.b * 255)) + 0.5)
    local hex = ("#%02X%02X%02X"):format(red, green, blue)
    return ("|cff%02X%02X%02X%s|r"):format(red, green, blue, hex)
end

local function parseColorHex(value, fallback)
    local text = tostring(value or ""):gsub("%s+", ""):gsub("^#", "")
    if text == "" then
        return copyColor(fallback)
    end

    if #text == 6 then
        local red = tonumber(text:sub(1, 2), 16)
        local green = tonumber(text:sub(3, 4), 16)
        local blue = tonumber(text:sub(5, 6), 16)
        if red and green and blue then
            return {
                r = red / 255,
                g = green / 255,
                b = blue / 255,
                a = tonumber(fallback and fallback.a) or 1,
            }
        end
    end

    return copyColor(fallback)
end

local function ensureString(value)
    if value == nil then
        return ""
    end

    return tostring(value)
end

local function trimString(value)
    return ensureString(value):gsub("^%s+", ""):gsub("%s+$", "")
end

local function syncInputValue(input, value)
    local editBox = input and input.GetEditBox and input:GetEditBox() or nil
    if editBox and editBox.HasFocus and editBox:HasFocus() then
        return
    end

    if input and input.SetText then
        input:SetText(value)
    end
end

local function syncDropdownValue(dropdown, value)
    if dropdown and dropdown.SetSelectedValue then
        dropdown:SetSelectedValue(value, true)
    end
end

local function syncDropdownValues(dropdown, values)
    if dropdown and dropdown.SetSelectedValues then
        dropdown:SetSelectedValues(values or {}, true)
    end
end

local function isLevelSystemEnabled()
    local activeRuleset = Ruleset.GetActiveRuleset and Ruleset.GetActiveRuleset() or nil
    local ruleDefinition = Ruleset.GetRulesetRuleDefinition and Ruleset.GetRulesetRuleDefinition("character", "use_level_system") or nil
    return Ruleset.GetRulesetRuleValue and Ruleset.GetRulesetRuleValue(activeRuleset, "character", ruleDefinition) == true
end

local function normalizeEventLevel(value)
    if not isLevelSystemEnabled() then
        return 1
    end

    local level = math.floor(tonumber(value) or 1)
    if level < 1 then
        level = 1
    end

    return level
end

local function getAllowedEventDifficulties()
    local activeRuleset = Ruleset.GetActiveRuleset and Ruleset.GetActiveRuleset() or nil
    local ruleDefinition = Ruleset.GetRulesetRuleDefinition and Ruleset.GetRulesetRuleDefinition("event", "allowed_event_difficulties") or nil
    local configured = Ruleset.GetRulesetRuleValue and Ruleset.GetRulesetRuleValue(activeRuleset, "event", ruleDefinition) or nil
    local allowed = {}
    local seen = {}

    for index = 1, #(type(configured) == "table" and configured or {}) do
        local value = string.lower(tostring(configured[index] or ""))
        for orderIndex = 1, #EVENT_DIFFICULTY_ORDER do
            if value == EVENT_DIFFICULTY_ORDER[orderIndex] and not seen[value] then
                seen[value] = true
                allowed[#allowed + 1] = value
            end
        end
    end

    if #allowed == 0 then
        allowed[1] = "normal"
        seen.normal = true
    end

    return allowed, seen
end

local function normalizeEventDifficulty(value)
    local allowed, allowedLookup = getAllowedEventDifficulties()
    local normalized = string.lower(tostring(value or "normal"))
    if allowedLookup[normalized] then
        return normalized
    end

    for index = 1, #EVENT_DIFFICULTY_ORDER do
        local candidate = EVENT_DIFFICULTY_ORDER[index]
        if allowedLookup[candidate] then
            return candidate
        end
    end

    return allowed[1] or "normal"
end

local function titleCaseDifficulty(value)
    local normalized = trimString(value):lower()
    if normalized == "" then
        return "Normal"
    end

    return (normalized:gsub("(%a)([%w']*)", function(first, rest)
        return string.upper(first) .. string.lower(rest)
    end))
end

local function setPreviewColor(panel, color)
    if not panel then
        return
    end

    local resolved = copyColor(color)
    if panel.SetOption then
        panel:SetOption("panelBackgroundColor", resolved)
    end
    if panel.panelBackgroundTexture and panel.panelBackgroundTexture.SetColorTexture then
        panel.panelBackgroundTexture:SetColorTexture(resolved.r, resolved.g, resolved.b, resolved.a)
    end
end

local function createLabel(parent, name, text, width)
    return UI.CreateText(parent, name, text, {
        width = width or LABEL_WIDTH,
        height = LABEL_HEIGHT,
        fontFile = (C.FontFiles and C.FontFiles.Default) or "Fonts\\FRIZQT__.TTF",
        fontSize = (C.FontSizes and C.FontSizes.Body) or 8,
        textColor = UI.ResolveColor(nil, "text.secondary"),
        justifyH = "LEFT",
        justifyV = "MIDDLE",
        wordWrap = false,
    })
end

local function createSectionHeader(parent, name, text)
    return UI.CreateText(parent, name, text, {
        width = 480,
        height = 16,
        fontFile = (C.FontFiles and C.FontFiles.Default) or "Fonts\\FRIZQT__.TTF",
        fontSize = (C.FontSizes and C.FontSizes.Body) or 8,
        textColor = UI.ResolveColor(nil, "warning"),
        justifyH = "LEFT",
        justifyV = "MIDDLE",
        wordWrap = false,
    })
end

local function createSettingsRow(parent, name, width)
    return UI.CreateLayout(UI.HorizontalLayoutGroup, parent, name, {
        width = width,
        height = CONTROL_HEIGHT,
        spacing = 6,
        autoSize = false,
        fitChildrenWidth = false,
        fitChildrenHeight = false,
    })
end

local function createStretchSpacer(parent, name)
    return UI.CreatePanel(parent, name, {
        width = 0,
        height = CONTROL_HEIGHT,
        contentInset = 0,
        showBackground = false,
        showBorder = false,
        panelBackgroundColor = { r = 0, g = 0, b = 0, a = 0 },
        backdropColor = { r = 0, g = 0, b = 0, a = 0 },
        expandWidth = true,
        weight = 1,
    })
end

local function createTablePanel(parent, name, width, height)
    return UI.CreatePanel(parent, name, {
        width = width,
        height = height,
        contentInset = 2,
    })
end

local function createSettingsTableHeader(parent, name, width, columns)
    local header = UI.CreateLayout(UI.HorizontalLayoutGroup, parent, name, {
        width = width,
        height = TABLE_HEADER_HEIGHT,
        spacing = 2,
        fitChildrenWidth = false,
        fitChildrenHeight = false,
    })

    header.columnTexts = header.columnTexts or {}
    for index = 1, math.max(3, #(columns or {})) do
        local column = columns and columns[index] or nil
        local text = UI.CreateText(header:GetFrame(), name .. "Column" .. index, tostring(column and column.label or ""), {
            width = tonumber(column and column.width) or 0,
            height = 12,
            justifyH = column and column.justifyH or "LEFT",
            textColor = UI.ResolveColor(nil, "text.secondary"),
            wordWrap = false,
        })
        header.columnTexts[index] = text
        header:AddChild(text)
    end

    return header
end

local function setSettingsTableHeaderColumns(header, columns)
    if not header or not header.columnTexts then
        return
    end

    for index = 1, #header.columnTexts do
        local column = columns and columns[index] or nil
        local text = header.columnTexts[index]
        local frame = text and text.GetFrame and text:GetFrame() or nil
        if text and text.SetText then
            text:SetText(column and tostring(column.label or "") or "")
        end
        if text and text.SetWidth then
            text:SetWidth(tonumber(column and column.width) or 0)
        end
        if frame and frame.SetShown then
            frame:SetShown(column ~= nil)
        elseif frame then
            if column ~= nil then
                frame:Show()
            else
                frame:Hide()
            end
        end
    end

    if header.RefreshLayout then
        header:RefreshLayout()
    end
end

local function setElementVisible(element, visible)
    if not element then
        return
    end

    local frame = element.GetFrame and element:GetFrame() or nil
    local targetHeight = visible and (element._visibleHeight or 0) or 0
    if element.SetHeight then
        element:SetHeight(targetHeight)
    elseif element.options then
        element.options.height = targetHeight
    end
    if frame and frame.SetHeight then
        frame:SetHeight(targetHeight)
    end
    if frame and frame.SetShown then
        frame:SetShown(visible == true)
    elseif frame then
        if visible then
            frame:Show()
        else
            frame:Hide()
        end
    end
end

local function getActivatedDatasets()
    return Registry.GetActivatedDatasets and Registry:GetActivatedDatasets() or {}
end

local function findActivatedDataset(datasetId)
    local normalizedId = trimString(datasetId)
    if normalizedId == "" then
        return nil
    end

    local datasets = getActivatedDatasets()
    for index = 1, #datasets do
        local dataset = datasets[index]
        if dataset and dataset.id == normalizedId then
            return dataset
        end
    end

    return nil
end

local function buildDatasetItems(collectionKey, emptyLabel)
    local items = {
        { label = emptyLabel or "Select Dataset", value = "" },
    }

    local datasets = getActivatedDatasets()
    for index = 1, #datasets do
        local dataset = datasets[index]
        local entries = dataset and dataset[collectionKey] or nil
        if dataset and type(entries) == "table" and #entries > 0 then
            items[#items + 1] = {
                label = trimString(dataset.name) ~= "" and trimString(dataset.name) or tostring(dataset.id),
                value = tostring(dataset.id),
            }
        end
    end

    return items
end

local function buildDatasetEntryItems(datasetId, collectionKey, emptyLabel)
    local items = {
        { label = emptyLabel or "Select", value = "" },
    }

    local dataset = findActivatedDataset(datasetId)
    local entries = dataset and dataset[collectionKey] or nil
    for index = 1, #(entries or {}) do
        local entry = entries[index]
        if entry and entry.id then
            items[#items + 1] = {
                label = trimString(entry.name) ~= "" and trimString(entry.name) or tostring(entry.id),
                value = ("%s:%s"):format(dataset.id, entry.id),
            }
        end
    end

    return items
end

local function parseDatasetQualifiedRef(value)
    local text = trimString(value)
    local separatorIndex = string.find(text, ":", 1, true)
    if not separatorIndex then
        return "", ""
    end

    local datasetId = string.sub(text, 1, separatorIndex - 1)
    local entryId = string.sub(text, separatorIndex + 1)
    return datasetId, entryId
end

local function resolveDatasetEntryRef(ref, collectionKey)
    local datasetId, entryId = parseDatasetQualifiedRef(ref)
    if datasetId == "" or entryId == "" then
        return nil, nil
    end

    local dataset = findActivatedDataset(datasetId)
    local entries = dataset and dataset[collectionKey] or nil
    for index = 1, #(entries or {}) do
        local entry = entries[index]
        if entry and tostring(entry.id) == entryId then
            return dataset, entry
        end
    end

    return dataset, nil
end

local function cloneTeamIndexList(values, teamCount)
    local cloned = {}
    local seen = {}

    for index = 1, #(values or {}) do
        local numericValue = math.floor(tonumber(values[index]) or 0)
        if numericValue > 0 and not seen[numericValue] and (not teamCount or numericValue <= teamCount) then
            seen[numericValue] = true
            cloned[#cloned + 1] = numericValue
        end
    end

    table.sort(cloned)
    return cloned
end

local function parseTeamSelectionInput(value, teamCount)
    local text = trimString(value)
    if text == "" then
        return {}
    end

    local parsed = {}
    for token in string.gmatch(text, "[^,%s]+") do
        parsed[#parsed + 1] = tonumber(token) or 0
    end
    return cloneTeamIndexList(parsed, teamCount)
end

local function buildTeamSelectionInputValue(teamIndices)
    local values = cloneTeamIndexList(teamIndices)
    local parts = {}
    for index = 1, #values do
        parts[#parts + 1] = tostring(values[index])
    end
    return table.concat(parts, ",")
end

local function buildEventAuraTeamSummary(eventState, teamIndices)
    local teams = eventState and eventState.teams or {}
    local values = cloneTeamIndexList(teamIndices, #teams)
    if #values == 0 or #values >= #teams then
        return "All Teams"
    end

    local labels = {}
    for index = 1, #values do
        local teamIndex = values[index]
        local team = teams[teamIndex]
        labels[#labels + 1] = trimString(team and team.name) ~= "" and trimString(team.name) or ("Team %d"):format(teamIndex)
    end
    return table.concat(labels, ", ")
end

local function buildEventAuraTeamItems(eventState)
    local items = {}
    local teams = eventState and eventState.teams or {}
    for index = 1, #teams do
        local team = teams[index]
        items[#items + 1] = {
            label = trimString(team and team.name) ~= "" and trimString(team.name) or ("Team %d"):format(index),
            value = tostring(index),
        }
    end
    return items
end

local function getGlobalSettings()
    local globalSettings = Database.EnsureGlobalSettings and Database.EnsureGlobalSettings() or Database.GlobalSettings or {}
    globalSettings.settings = type(globalSettings.settings) == "table" and globalSettings.settings or {}
    globalSettings.settings.eventPresets = type(globalSettings.settings.eventPresets) == "table" and globalSettings.settings.eventPresets or {}
    return globalSettings.settings
end

local function buildPresetSnapshot(eventState)
    local stateTable = eventState and eventState.ToTable and eventState:ToTable() or deepCopy(eventState) or {}
    local snapshot = {
        name = trimString(stateTable.name),
        subtext = trimString(stateTable.subtext),
        description = trimString(stateTable.description),
        difficulty = normalizeEventDifficulty(stateTable.difficulty),
        level = normalizeEventLevel(stateTable.level),
        teams = deepCopy(stateTable.teams or {}),
        eventAuras = deepCopy(stateTable.eventAuras or {}),
        lootRefs = deepCopy(stateTable.lootRefs or {}),
    }

    return snapshot
end

local function buildPresetNpcUnitSnapshot(units)
    local snapshot = {}

    for index = 1, #(units or {}) do
        local unit = units[index]
        if type(unit) == "table" and unit.isPlayer ~= true then
            local copy = unit.ToTable and unit:ToTable() or deepCopy(unit)
            copy.eventID = nil
            copy.summonedByEventID = nil
            if tonumber(copy.controllerID) then
                copy.controllerID = nil
            end
            snapshot[#snapshot + 1] = copy
        end
    end

    return snapshot
end

local function getNextPresetUnitEventId(units)
    local nextEventId = 1

    for index = 1, #(units or {}) do
        local eventId = math.floor(tonumber(units[index] and units[index].eventID) or 0)
        if eventId >= nextEventId then
            nextEventId = eventId + 1
        end
    end

    return nextEventId
end

local function buildLoadedPresetUnits(currentUnits, presetUnits, hostName)
    local merged = {}
    local normalizedHostName = Common.NormalizeName and Common.NormalizeName(hostName) or tostring(hostName or "")

    for index = 1, #(currentUnits or {}) do
        local unit = currentUnits[index]
        if type(unit) == "table" and unit.isPlayer == true then
            merged[#merged + 1] = unit.ToTable and unit:ToTable() or deepCopy(unit)
        end
    end

    local nextEventId = getNextPresetUnitEventId(merged)
    for index = 1, #(presetUnits or {}) do
        local unit = presetUnits[index]
        if type(unit) == "table" and unit.isPlayer ~= true then
            local copy = unit.ToTable and unit:ToTable() or deepCopy(unit)
            copy.isPlayer = false
            copy.eventID = nextEventId
            copy.summonedByEventID = nil
            copy.ownerID = tostring(copy.ownerID or normalizedHostName or "")
            if trimString(copy.ownerID) == "" then
                copy.ownerID = normalizedHostName
            end
            copy.controllerID = trimString(copy.controllerID) ~= "" and copy.controllerID or copy.ownerID
            merged[#merged + 1] = copy
            nextEventId = nextEventId + 1
        end
    end

    return merged
end

local function buildTeamRows(eventState)
    local rows = {}
    local teams = eventState and eventState.teams or {}
    for index = 1, #teams do
        local team = teams[index]
        rows[#rows + 1] = {
            rowIndex = index,
            order = tostring(index),
            name = trimString(team and team.name) ~= "" and trimString(team.name) or ("Team %d"):format(index),
            color = formatInlineColorHex(team and team.color or getDefaultTeamColor(index)),
        }
    end
    return rows
end

local function buildAffixRows(eventState)
    local rows = {}
    for index = 1, #(eventState and eventState.eventAuras or {}) do
        local entry = eventState.eventAuras[index]
        local ref = trimString(entry and entry.auraRef)
        local dataset, aura = resolveDatasetEntryRef(ref, "auras")
        rows[#rows + 1] = {
            rowIndex = index,
            ref = ref,
            datasetId = dataset and dataset.id or "",
            dataset = dataset and (trimString(dataset.name) ~= "" and trimString(dataset.name) or dataset.id) or "-",
            aura = aura and (trimString(aura.name) ~= "" and trimString(aura.name) or aura.id) or select(2, parseDatasetQualifiedRef(ref)),
            teams = buildEventAuraTeamSummary(eventState, entry and entry.teamIndices or nil),
        }
    end
    return rows
end

local function buildLootRows(eventState)
    local rows = {}
    for index = 1, #(eventState and eventState.lootRefs or {}) do
        local ref = eventState.lootRefs[index]
        local dataset, loot = resolveDatasetEntryRef(ref, "loot")
        rows[#rows + 1] = {
            rowIndex = index,
            ref = ref,
            datasetId = dataset and dataset.id or "",
            dataset = dataset and (trimString(dataset.name) ~= "" and trimString(dataset.name) or dataset.id) or "-",
            loot = loot and (trimString(loot.name) ~= "" and trimString(loot.name) or loot.id) or select(2, parseDatasetQualifiedRef(ref)),
        }
    end
    return rows
end

function EventManage:BuildEditableSettingsStateSnapshot()
    local sourceState = Server.GetEditableEventState and Server:GetEditableEventState() or nil
    local sourceTable = sourceState and sourceState.ToTable and sourceState:ToTable() or deepCopy(sourceState) or {}
    local normalized = EventClass and EventClass.FromTable and EventClass.FromTable(sourceTable) or sourceTable
    local normalizedTable = normalized and normalized.ToTable and normalized:ToTable() or deepCopy(normalized) or {}
    normalizedTable.name = trimString(normalizedTable.name)
    normalizedTable.subtext = trimString(normalizedTable.subtext)
    normalizedTable.description = trimString(normalizedTable.description)
    normalizedTable.difficulty = normalizeEventDifficulty(normalizedTable.difficulty)
    normalizedTable.level = normalizeEventLevel(normalizedTable.level)
    normalizedTable.teams = deepCopy(normalizedTable.teams or {})
    normalizedTable.eventAuras = deepCopy(normalizedTable.eventAuras or {})
    normalizedTable.lootRefs = deepCopy(normalizedTable.lootRefs or {})
    normalizedTable.units = deepCopy(normalizedTable.units or {})
    return normalizedTable
end

function EventManage:InvalidateEditableSettingsState()
    self.EditableSettingsState = nil
end

function EventManage:GetEditableSettingsState()
    if not self.EditableSettingsState then
        self.EditableSettingsState = self:BuildEditableSettingsStateSnapshot()
    end
    return self.EditableSettingsState
end

function EventManage:PushEditableSettingsState()
    local stateTable = self:GetEditableSettingsState()
    if not stateTable then
        return false
    end

    local normalized = EventClass and EventClass.FromTable and EventClass.FromTable(stateTable) or stateTable
    local normalizedTable = normalized and normalized.ToTable and normalized:ToTable() or deepCopy(normalized) or {}
    self.EditableSettingsState = normalizedTable

    local liveState = Server.GetEditableEventState and Server:GetEditableEventState() or nil
    if liveState and liveState.Merge then
        liveState:Merge(normalizedTable)
        if liveState.active == true then
            Server.EventState = liveState
        else
            Server.EventDraftState = liveState
        end
        return true
    end

    if EventClass and EventClass.FromTable then
        local rebuiltState = EventClass.FromTable(normalizedTable)
        if rebuiltState and rebuiltState.active == true then
            Server.EventState = rebuiltState
        else
            Server.EventDraftState = rebuiltState
        end
        return true
    end

    return false
end

function EventManage:QueueActiveEventWidgetRefresh(reason)
    if Client and Client.QueueEventWidgetRefresh and Client.IsEventActive and Client:IsEventActive() then
        Client:QueueEventWidgetRefresh(reason or "event-settings")
    end
end

function EventManage:CommitEventSettings(mutator)
    local eventState = self:GetEditableSettingsState()
    if not eventState or type(mutator) ~= "function" then
        return false
    end

    mutator(eventState)
    self:PushEditableSettingsState()

    self:RefreshDashboard()
    self:RefreshUnitsPage()
    self:RefreshSettingsPage()
    self:QueueActiveEventWidgetRefresh("event-settings")
    return true
end

function EventManage:GetSettingsPresetCollection()
    return getGlobalSettings().eventPresets
end

function EventManage:GetSelectedPresetName()
    local selected = trimString(self.SelectedEventPresetName)
    if selected ~= "" then
        return selected
    end

    return trimString(self.PresetNameInput and self.PresetNameInput.GetText and self.PresetNameInput:GetText() or "")
end

function EventManage:BuildPresetItems()
    local items = {
        { label = "Select Preset", value = "" },
    }

    local names = {}
    for name in pairs(self:GetSettingsPresetCollection()) do
        names[#names + 1] = tostring(name)
    end
    table.sort(names, function(left, right)
        return string.lower(left) < string.lower(right)
    end)

    for index = 1, #names do
        items[#items + 1] = {
            label = names[index],
            value = names[index],
        }
    end

    return items
end

function EventManage:RefreshPresetToolbar()
    local selectedPresetName = trimString(self.SelectedEventPresetName)
    if self.PresetDropdown and self.PresetDropdown.SetItems then
        self.PresetDropdown:SetItems(self:BuildPresetItems())
        self.PresetDropdown:SetSelectedValue(selectedPresetName, true)
    end

    if self.PresetNameInput and self.PresetNameInput.SetText and selectedPresetName ~= "" then
        syncInputValue(self.PresetNameInput, selectedPresetName)
    end

    local hasSelection = selectedPresetName ~= "" and self:GetSettingsPresetCollection()[selectedPresetName] ~= nil
    if self.LoadPresetButton and self.LoadPresetButton.SetEnabled then
        self.LoadPresetButton:SetEnabled(hasSelection)
    end
    if self.DeletePresetButton and self.DeletePresetButton.SetEnabled then
        self.DeletePresetButton:SetEnabled(hasSelection)
    end
    if self.SavePresetUnitsCheckbox and self.SavePresetUnitsCheckbox.SetChecked then
        self.SavePresetUnitsCheckbox:SetChecked(self.SavePresetUnits == true, true)
    end
end

function EventManage:HandlePresetSelected(value)
    self.SelectedEventPresetName = trimString(value)
    if self.PresetNameInput and self.PresetNameInput.SetText then
        syncInputValue(self.PresetNameInput, self.SelectedEventPresetName)
    end
    self:RefreshPresetToolbar()
end

function EventManage:SaveSelectedPreset()
    local presetName = self:GetSelectedPresetName()
    local eventState = self:GetEditableSettingsState()
    if presetName == "" or not eventState then
        return false
    end

    local presets = self:GetSettingsPresetCollection()
    local snapshot = buildPresetSnapshot(eventState)
    if self.SavePresetUnits == true then
        local liveState = Server.GetEditableEventState and Server:GetEditableEventState() or eventState
        snapshot.units = buildPresetNpcUnitSnapshot(liveState and liveState.units or eventState.units or {})
        snapshot.includesUnits = true
    else
        snapshot.units = nil
        snapshot.includesUnits = false
    end
    presets[presetName] = snapshot
    self.SelectedEventPresetName = presetName
    self:RefreshPresetToolbar()
    return true
end

function EventManage:LoadSelectedPreset()
    local presetName = self:GetSelectedPresetName()
    local preset = presetName ~= "" and self:GetSettingsPresetCollection()[presetName] or nil
    if type(preset) ~= "table" then
        return false
    end

    self.SelectedEventPresetName = presetName
    self:CommitEventSettings(function(eventState)
        eventState.name = trimString(preset.name)
        eventState.subtext = trimString(preset.subtext)
        eventState.description = trimString(preset.description)
        eventState.difficulty = normalizeEventDifficulty(preset.difficulty)
        eventState.level = normalizeEventLevel(preset.level)
        eventState.teams = deepCopy(preset.teams or {})
        eventState.eventAuras = deepCopy(preset.eventAuras or {})
        eventState.lootRefs = deepCopy(preset.lootRefs or {})

        if preset.includesUnits == true then
            local liveState = Server.GetEditableEventState and Server:GetEditableEventState() or eventState
            local liveHostName = trimString(liveState and liveState.hostName or eventState.hostName or Common.GetPlayerName and Common.GetPlayerName() or "")
            eventState.units = buildLoadedPresetUnits(liveState and liveState.units or eventState.units or {}, preset.units or {}, liveHostName)
        end
    end)
    return true
end

function EventManage:DeleteSelectedPreset()
    local presetName = self:GetSelectedPresetName()
    if presetName == "" then
        return false
    end

    local presets = self:GetSettingsPresetCollection()
    if presets[presetName] == nil then
        return false
    end

    presets[presetName] = nil
    self.SelectedEventPresetName = ""
    if self.PresetNameInput and self.PresetNameInput.SetText then
        syncInputValue(self.PresetNameInput, "")
    end
    self:RefreshPresetToolbar()
    return true
end

function EventManage:SetSelectedSettingsTeamIndex(index)
    local eventState = self:GetEditableSettingsState()
    local teams = eventState and eventState.teams or {}
    local normalizedIndex = math.floor(tonumber(index) or 0)
    if normalizedIndex <= 0 or normalizedIndex > #teams then
        normalizedIndex = #teams > 0 and 1 or nil
    end

    self.SelectedEventTeamIndex = normalizedIndex
    self:RefreshSettingsPage()
end

function EventManage:SetSelectedSettingsAffixIndex(index)
    local eventState = self:GetEditableSettingsState()
    local refs = eventState and eventState.eventAuras or {}
    local normalizedIndex = math.floor(tonumber(index) or 0)
    if normalizedIndex <= 0 or normalizedIndex > #refs then
        normalizedIndex = nil
    end

    self.SelectedEventAffixIndex = normalizedIndex
    self:RefreshSettingsPage()
end

function EventManage:SetSelectedSettingsLootIndex(index)
    local eventState = self:GetEditableSettingsState()
    local refs = eventState and eventState.lootRefs or {}
    local normalizedIndex = math.floor(tonumber(index) or 0)
    if normalizedIndex <= 0 or normalizedIndex > #refs then
        normalizedIndex = nil
    end

    self.SelectedEventLootIndex = normalizedIndex
    self:RefreshSettingsPage()
end

function EventManage:ApplySettingsRowSelection(tableObject, selectedIndex)
    local rows = tableObject and (tableObject.rows or (tableObject.bodyScroll and tableObject.bodyScroll.rows)) or nil
    if not rows then
        return
    end

    for visibleIndex = 1, #rows do
        local row = rows[visibleIndex]
        local rowData = row and row.rowData or nil
        local isSelected = tonumber(rowData and rowData.rowIndex) == tonumber(selectedIndex)
        if row and row.background and row.background.SetColorTexture then
            local color = UI.ResolveColor(nil, isSelected and "list.rowHover" or "list.rowBackground")
            row.background:SetColorTexture(color.r or 0.08, color.g or 0.09, color.b or 0.11, color.a or 0.85)
        end
    end
end

function EventManage:ConfigureSettingsScrollRow(row, item, itemIndex, columns, onSelect, selectedIndex)
    if row and row.SetColumns then
        row:SetColumns(columns or {})
    end
    if row and row.SetRowData then
        row:SetRowData(item, itemIndex or 0)
    end
    if row and row.SetRowMouseUpHandler then
        row:SetRowMouseUpHandler(function(_, button, rowData)
            if button == "LeftButton" and type(onSelect) == "function" then
                onSelect(rowData and rowData.rowIndex or itemIndex or nil)
            end
        end)
    end

    local isSelected = tonumber(item and item.rowIndex) == tonumber(selectedIndex)
    if row and row.background and row.background.SetColorTexture then
        local color = UI.ResolveColor(nil, isSelected and "list.rowHover" or "list.rowBackground")
        row.background:SetColorTexture(color.r or 0.08, color.g or 0.09, color.b or 0.11, color.a or 0.85)
    end
end

function EventManage:RefreshTeamEditor()
    local eventState = self:GetEditableSettingsState()
    local teams = eventState and eventState.teams or {}
    local selectedIndex = tonumber(self.SelectedEventTeamIndex)
    if not selectedIndex or not teams[selectedIndex] then
        selectedIndex = #teams > 0 and 1 or nil
        self.SelectedEventTeamIndex = selectedIndex
    end

    local team = selectedIndex and teams[selectedIndex] or nil
    syncInputValue(self.TeamNameInput, trimString(team and team.name) ~= "" and trimString(team.name) or (selectedIndex and ("Team %d"):format(selectedIndex) or ""))
    syncInputValue(self.TeamColorInput, formatColorHex(team and team.color or getDefaultTeamColor(selectedIndex or 1)))
    setPreviewColor(self.TeamColorPreview, team and team.color or getDefaultTeamColor(selectedIndex or 1))

    if self.SaveTeamButton and self.SaveTeamButton.SetEnabled then
        self.SaveTeamButton:SetEnabled(team ~= nil)
    end
    if self.RemoveTeamButton and self.RemoveTeamButton.SetEnabled then
        self.RemoveTeamButton:SetEnabled(team ~= nil and #teams > 1)
    end
end

function EventManage:RefreshAffixEditor()
    local eventState = self:GetEditableSettingsState()
    local entries = eventState and eventState.eventAuras or {}
    local selectedIndex = tonumber(self.SelectedEventAffixIndex)
    local selectedEntry = selectedIndex and entries[selectedIndex] or nil
    local selectedRef = trimString(selectedEntry and selectedEntry.auraRef)
    local selectedDatasetId = trimString(self.SelectedEventAffixDatasetId)

    if selectedRef ~= "" then
        selectedDatasetId = select(1, parseDatasetQualifiedRef(selectedRef))
    end

    self.SelectedEventAffixDatasetId = selectedDatasetId
    if self.AffixDatasetDropdown and self.AffixDatasetDropdown.SetItems then
        self.AffixDatasetDropdown:SetItems(buildDatasetItems("auras", "Dataset"))
        syncDropdownValue(self.AffixDatasetDropdown, selectedDatasetId)
    end
    if self.AffixTraitDropdown and self.AffixTraitDropdown.SetItems then
        self.AffixTraitDropdown:SetItems(buildDatasetEntryItems(selectedDatasetId, "auras", "Aura"))
        syncDropdownValue(self.AffixTraitDropdown, selectedRef or self.SelectedEventAffixRef or "")
    end
    self.SelectedEventAffixRef = selectedRef or self.SelectedEventAffixRef or ""
    self.SelectedEventAuraTeamIndices = cloneTeamIndexList(selectedEntry and selectedEntry.teamIndices or nil, #(eventState and eventState.teams or {}))
    if self.EventAuraTeamsDropdown and self.EventAuraTeamsDropdown.SetItems then
        self.EventAuraTeamsDropdown:SetItems(buildEventAuraTeamItems(eventState))
        syncDropdownValues(self.EventAuraTeamsDropdown, self.SelectedEventAuraTeamIndices)
    end

    if self.RemoveAffixButton and self.RemoveAffixButton.SetEnabled then
        self.RemoveAffixButton:SetEnabled(selectedIndex ~= nil)
    end
end

function EventManage:RefreshLootEditor()
    local eventState = self:GetEditableSettingsState()
    local refs = eventState and eventState.lootRefs or {}
    local selectedIndex = tonumber(self.SelectedEventLootIndex)
    local selectedRef = selectedIndex and refs[selectedIndex] or nil
    local selectedDatasetId = trimString(self.SelectedEventLootDatasetId)

    if selectedRef then
        selectedDatasetId = select(1, parseDatasetQualifiedRef(selectedRef))
    end

    self.SelectedEventLootDatasetId = selectedDatasetId
    if self.LootDatasetDropdown and self.LootDatasetDropdown.SetItems then
        self.LootDatasetDropdown:SetItems(buildDatasetItems("loot", "Dataset"))
        syncDropdownValue(self.LootDatasetDropdown, selectedDatasetId)
    end
    if self.LootRefDropdown and self.LootRefDropdown.SetItems then
        self.LootRefDropdown:SetItems(buildDatasetEntryItems(selectedDatasetId, "loot", "Loot"))
        syncDropdownValue(self.LootRefDropdown, selectedRef or self.SelectedEventLootRef or "")
    end
    self.SelectedEventLootRef = selectedRef or self.SelectedEventLootRef or ""

    if self.RemoveLootButton and self.RemoveLootButton.SetEnabled then
        self.RemoveLootButton:SetEnabled(selectedIndex ~= nil)
    end
end

function EventManage:RefreshTeamsTable()
    if self:GetActiveSettingsSectionKey() == "teams" then
        self:RefreshSettingsSharedTable()
    end
end

function EventManage:RefreshAffixesTable()
    if self:GetActiveSettingsSectionKey() == "auras" then
        self:RefreshSettingsSharedTable()
    end
end

function EventManage:RefreshLootTable()
    if self:GetActiveSettingsSectionKey() == "loot" then
        self:RefreshSettingsSharedTable()
    end
end

function EventManage:GetSettingsSectionPageDefinitions()
    return {
        {
            key = "teams",
            label = "Teams",
            columns = self.SettingsTeamColumns,
            editor = self.SettingsTeamEditorRow,
        },
        {
            key = "auras",
            label = "Event Auras",
            columns = self.SettingsAffixColumns,
            editor = self.SettingsAffixEditorRow,
        },
        {
            key = "loot",
            label = "Global Loot",
            columns = self.SettingsLootColumns,
            editor = self.SettingsLootEditorRow,
        },
    }
end

function EventManage:GetActiveSettingsSectionDefinition()
    local pages = self:GetSettingsSectionPageDefinitions()
    local activeIndex = self:SetActiveSettingsSectionPage(self.ActiveSettingsSectionPage or 1)
    return pages[activeIndex] or pages[1] or nil
end

function EventManage:GetActiveSettingsSectionKey()
    local activePage = self:GetActiveSettingsSectionDefinition()
    return activePage and activePage.key or "teams"
end

function EventManage:BuildSettingsSharedRows(sectionKey, eventState)
    if sectionKey == "auras" then
        return buildAffixRows(eventState), self.SelectedEventAffixIndex, function(index)
            self:SetSelectedSettingsAffixIndex(index)
        end
    end
    if sectionKey == "loot" then
        return buildLootRows(eventState), self.SelectedEventLootIndex, function(index)
            self:SetSelectedSettingsLootIndex(index)
        end
    end
    return buildTeamRows(eventState), self.SelectedEventTeamIndex, function(index)
        self:SetSelectedSettingsTeamIndex(index)
    end
end

function EventManage:RefreshSettingsSharedTable()
    local activePage = self:GetActiveSettingsSectionDefinition()
    local eventState = self:GetEditableSettingsState()
    local rows, selectedIndex = self:BuildSettingsSharedRows(activePage and activePage.key or "teams", eventState)

    setSettingsTableHeaderColumns(self.SettingsTableHeader, activePage and activePage.columns or nil)
    if self.SettingsTable and self.SettingsTable.SetItems then
        self.SettingsTable:SetItems(rows)
    end
    self:ApplySettingsRowSelection(self.SettingsTable, selectedIndex)
end

function EventManage:SetActiveSettingsSectionPage(index)
    local pages = self:GetSettingsSectionPageDefinitions()
    local pageCount = #pages
    if pageCount <= 0 then
        self.ActiveSettingsSectionPage = 1
        return 1
    end

    local nextIndex = math.floor(tonumber(index) or 1)
    if nextIndex < 1 then
        nextIndex = pageCount
    elseif nextIndex > pageCount then
        nextIndex = 1
    end

    self.ActiveSettingsSectionPage = nextIndex
    return nextIndex
end

function EventManage:CycleSettingsSectionPage(delta)
    self:SetActiveSettingsSectionPage((self.ActiveSettingsSectionPage or 1) + (tonumber(delta) or 0))
    self:RefreshSettingsPage()
end

function EventManage:RefreshSettingsSectionPager()
    local pages = self:GetSettingsSectionPageDefinitions()
    local activeIndex = self:SetActiveSettingsSectionPage(self.ActiveSettingsSectionPage or 1)

    if self.SettingsSectionPageText and self.SettingsSectionPageText.SetText then
        self.SettingsSectionPageText:SetText(("%d / %d"):format(activeIndex, math.max(1, #pages)))
    end
    if self.SettingsSectionTitleText and self.SettingsSectionTitleText.SetText then
        self.SettingsSectionTitleText:SetText((pages[activeIndex] and pages[activeIndex].label) or "Tables")
    end
    for index = 1, #pages do
        local page = pages[index]
        setElementVisible(page and page.editor, index == activeIndex)
    end
    self:RefreshSettingsSharedTable()

    if self.SettingsRootLayout and self.SettingsRootLayout.RefreshLayout then
        self.SettingsRootLayout:RefreshLayout()
    end
end

function EventManage:RefreshSettingsPage()
    local eventState = self:GetEditableSettingsState()
    local levelSystemEnabled = isLevelSystemEnabled()
    local allowedDifficulties = getAllowedEventDifficulties()

    syncInputValue(self.EventNameInput, tostring(eventState and eventState.name or ""))
    syncInputValue(self.EventSubtextInput, tostring(eventState and eventState.subtext or ""))
    if self.EventDifficultyDropdown and self.EventDifficultyDropdown.SetItems then
        local difficultyItems = {}
        for index = 1, #allowedDifficulties do
            difficultyItems[#difficultyItems + 1] = {
                label = titleCaseDifficulty(allowedDifficulties[index]),
                value = allowedDifficulties[index],
            }
        end
        self.EventDifficultyDropdown:SetItems(difficultyItems)
        syncDropdownValue(self.EventDifficultyDropdown, normalizeEventDifficulty(eventState and eventState.difficulty or "normal"))
    end
    syncInputValue(self.EventLevelInput, tostring(normalizeEventLevel(eventState and eventState.level or 1)))
    if self.EventLevelInput and self.EventLevelInput.SetEnabled then
        self.EventLevelInput:SetEnabled(levelSystemEnabled)
    end

    self:RefreshPresetToolbar()
    self:RefreshTeamEditor()
    self:RefreshAffixEditor()
    self:RefreshLootEditor()
    self:RefreshSettingsSectionPager()
end

function EventManage:BuildSettingsPage(page)
    if self.SettingsRootLayout then
        return self.SettingsRootLayout
    end

    local layout = self.Layout or {}
    local settingsWidth = layout.SettingsWidth or layout.PageContentWidth or 480
    local nameInputWidth = 140
    local subtextInputWidth = 192
    local toolbarDropdownWidth = 116
    local smallButtonWidth = 46
    local removeButtonWidth = 56
    local presetUnitsCheckboxWidth = 96
    local toolbarSpacing = 6
    local toolbarNameWidth = math.max(92, settingsWidth - toolbarDropdownWidth - presetUnitsCheckboxWidth - smallButtonWidth - smallButtonWidth - removeButtonWidth - (toolbarSpacing * 5))
    local sectionTableWidth = settingsWidth - 4

    self.SettingsPage = self.SettingsPage or page
    self.ActiveSettingsSectionPage = self.ActiveSettingsSectionPage or 1

    self.SettingsRootLayout = UI.CreateLayout(UI.VerticalLayoutGroup, page, "RPEServerEventManageSettingsRootLayout", {
        spacing = 6,
        paddingLeft = 0,
        paddingTop = 0,
        fitChildrenWidth = true,
        fitChildrenHeight = false,
    })
    self.SettingsRootLayout:SetPoint("TOPLEFT", page, "TOPLEFT", 0, 0)
    self.SettingsRootLayout:SetPoint("TOPRIGHT", page, "TOPRIGHT", 0, 0)
    self.SettingsRootLayout:SetPoint("BOTTOMLEFT", page, "BOTTOMLEFT", 0, 0)
    self.SettingsRootLayout:SetPoint("BOTTOMRIGHT", page, "BOTTOMRIGHT", 0, 0)

    local toolbar = UI.CreateLayout(UI.HorizontalLayoutGroup, self.SettingsRootLayout:GetFrame(), "RPEServerEventManageSettingsPresetToolbar", {
        width = settingsWidth,
        height = CONTROL_HEIGHT,
        spacing = 6,
        autoSize = false,
        fitChildrenWidth = true,
        fitChildrenHeight = false,
    })
    self.PresetDropdown = UI.CreateDropdown(toolbar:GetFrame(), "RPEServerEventManageSettingsPresetDropdown", {
        width = toolbarDropdownWidth,
        height = DROPDOWN_HEIGHT,
        items = self:BuildPresetItems(),
        selectedValue = "",
        onValueChanged = function(value)
            self:HandlePresetSelected(value)
        end,
    })
    toolbar:AddChild(self.PresetDropdown)

    self.PresetNameInput = UI.CreateTextInput(toolbar:GetFrame(), "RPEServerEventManageSettingsPresetNameInput", {
        width = toolbarNameWidth,
        height = CONTROL_HEIGHT,
        text = "",
        borderColor = UI.ResolveColor(nil, "panel.border"),
    })
    self.PresetNameInput:SetScript("OnEditFocusLost", function(input)
        self.SelectedEventPresetName = trimString(input:GetText())
        self:RefreshPresetToolbar()
    end)
    self.PresetNameInput:SetScript("OnEnterPressed", function(input)
        self.SelectedEventPresetName = trimString(input:GetText())
        self:RefreshPresetToolbar()
    end)
    toolbar:AddChild(self.PresetNameInput)
    toolbar:AddChild(createStretchSpacer(toolbar:GetFrame(), "RPEServerEventManageSettingsPresetToolbarSpacer"))

    self.SavePresetUnitsCheckbox = UI.Checkbox:New({
        name = "RPEServerEventManageSettingsPresetUnitsCheckbox",
        width = presetUnitsCheckboxWidth,
        height = CONTROL_HEIGHT,
        text = "Save Units",
        checked = self.SavePresetUnits == true,
        onValueChanged = function(value)
            self.SavePresetUnits = value == true
        end,
    })
    self.SavePresetUnitsCheckbox:SetParent(toolbar:GetFrame())
    self.SavePresetUnitsCheckbox:Create()
    toolbar:AddChild(self.SavePresetUnitsCheckbox)

    self.SavePresetButton = UI.CreateButton(toolbar:GetFrame(), "RPEServerEventManageSettingsPresetSaveButton", "Save", smallButtonWidth, function()
        self:SaveSelectedPreset()
    end, {
        height = CONTROL_HEIGHT,
        fontSize = BUTTON_FONT_SIZE,
    })
    toolbar:AddChild(self.SavePresetButton)

    self.LoadPresetButton = UI.CreateButton(toolbar:GetFrame(), "RPEServerEventManageSettingsPresetLoadButton", "Load", smallButtonWidth, function()
        self:LoadSelectedPreset()
    end, {
        height = CONTROL_HEIGHT,
        fontSize = BUTTON_FONT_SIZE,
    })
    toolbar:AddChild(self.LoadPresetButton)

    self.DeletePresetButton = UI.CreateButton(toolbar:GetFrame(), "RPEServerEventManageSettingsPresetDeleteButton", "Delete", removeButtonWidth, function()
        self:DeleteSelectedPreset()
    end, {
        height = CONTROL_HEIGHT,
        fontSize = BUTTON_FONT_SIZE,
    })
    toolbar:AddChild(self.DeletePresetButton)
    self.SettingsRootLayout:AddChild(toolbar)

    local detailsRow = createSettingsRow(self.SettingsRootLayout:GetFrame(), "RPEServerEventManageSettingsDetailsRow", settingsWidth)
    detailsRow:AddChild(createLabel(detailsRow:GetFrame(), "RPEServerEventManageSettingsNameLabel", "Event Name", 64))
    self.EventNameInput = UI.CreateTextInput(detailsRow:GetFrame(), "RPEServerEventManageSettingsNameInput", {
        width = nameInputWidth,
        height = CONTROL_HEIGHT,
        text = "",
        borderColor = UI.ResolveColor(nil, "panel.border"),
    })
    self.EventNameInput:SetScript("OnEnterPressed", function(input)
        self:CommitEventSettings(function(eventState)
            eventState.name = input:GetText()
        end)
    end)
    self.EventNameInput:SetScript("OnEditFocusLost", function(input)
        self:CommitEventSettings(function(eventState)
            eventState.name = input:GetText()
        end)
    end)
    detailsRow:AddChild(self.EventNameInput)

    detailsRow:AddChild(createLabel(detailsRow:GetFrame(), "RPEServerEventManageSettingsSubtextLabel", "Subtext", 48))
    self.EventSubtextInput = UI.CreateTextInput(detailsRow:GetFrame(), "RPEServerEventManageSettingsSubtextInput", {
        width = subtextInputWidth,
        height = CONTROL_HEIGHT,
        text = "",
        borderColor = UI.ResolveColor(nil, "panel.border"),
    })
    self.EventSubtextInput:SetScript("OnEnterPressed", function(input)
        self:CommitEventSettings(function(eventState)
            eventState.subtext = input:GetText()
        end)
    end)
    self.EventSubtextInput:SetScript("OnEditFocusLost", function(input)
        self:CommitEventSettings(function(eventState)
            eventState.subtext = input:GetText()
        end)
    end)
    detailsRow:AddChild(self.EventSubtextInput)
    self.SettingsRootLayout:AddChild(detailsRow)

    local metaRow = createSettingsRow(self.SettingsRootLayout:GetFrame(), "RPEServerEventManageSettingsMetaRow", settingsWidth)
    metaRow:AddChild(createLabel(metaRow:GetFrame(), "RPEServerEventManageSettingsDifficultyLabel", "Difficulty", 56))
    self.EventDifficultyDropdown = UI.CreateDropdown(metaRow:GetFrame(), "RPEServerEventManageSettingsDifficultyDropdown", {
        width = 112,
        height = CONTROL_HEIGHT,
        items = {},
        selectedValue = "normal",
        onValueChanged = function(value)
            self:CommitEventSettings(function(eventState)
                eventState.difficulty = normalizeEventDifficulty(value)
            end)
        end,
    })
    metaRow:AddChild(self.EventDifficultyDropdown)

    metaRow:AddChild(createLabel(metaRow:GetFrame(), "RPEServerEventManageSettingsLevelLabel", "Event Level", 64))
    self.EventLevelInput = UI.CreateTextInput(metaRow:GetFrame(), "RPEServerEventManageSettingsLevelInput", {
        width = 66,
        height = CONTROL_HEIGHT,
        text = "1",
        borderColor = UI.ResolveColor(nil, "panel.border"),
    })
    self.EventLevelInput:SetScript("OnEnterPressed", function(input)
        self:CommitEventSettings(function(eventState)
            eventState.level = normalizeEventLevel(input:GetText())
        end)
    end)
    self.EventLevelInput:SetScript("OnEditFocusLost", function(input)
        self:CommitEventSettings(function(eventState)
            eventState.level = normalizeEventLevel(input:GetText())
        end)
    end)
    metaRow:AddChild(self.EventLevelInput)
    self.SettingsRootLayout:AddChild(metaRow)

    local sectionPagerRow = createSettingsRow(self.SettingsRootLayout:GetFrame(), "RPEServerEventManageSettingsSectionPagerRow", settingsWidth)
    self.SettingsSectionTitleText = createSectionHeader(sectionPagerRow:GetFrame(), "RPEServerEventManageSettingsSectionTitle", "Teams")
    self.SettingsSectionTitleText:SetWidth(160)
    sectionPagerRow:AddChild(self.SettingsSectionTitleText)
    sectionPagerRow:AddChild(createStretchSpacer(sectionPagerRow:GetFrame(), "RPEServerEventManageSettingsSectionPagerSpacer"))
    self.SettingsPreviousSectionButton = UI.CreateButton(sectionPagerRow:GetFrame(), "RPEServerEventManageSettingsSectionPreviousButton", "Prev", 44, function()
        self:CycleSettingsSectionPage(-1)
    end, {
        height = CONTROL_HEIGHT,
        fontSize = BUTTON_FONT_SIZE,
    })
    sectionPagerRow:AddChild(self.SettingsPreviousSectionButton)
    self.SettingsSectionPageText = UI.CreateText(sectionPagerRow:GetFrame(), "RPEServerEventManageSettingsSectionPageText", "1 / 3", {
        width = 48,
        height = LABEL_HEIGHT,
        fontFile = (C.FontFiles and C.FontFiles.Default) or "Fonts\\FRIZQT__.TTF",
        fontSize = (C.FontSizes and C.FontSizes.Body) or 8,
        textColor = UI.ResolveColor(nil, "text.secondary"),
        justifyH = "CENTER",
        justifyV = "MIDDLE",
        wordWrap = false,
    })
    sectionPagerRow:AddChild(self.SettingsSectionPageText)
    self.SettingsNextSectionButton = UI.CreateButton(sectionPagerRow:GetFrame(), "RPEServerEventManageSettingsSectionNextButton", "Next", 44, function()
        self:CycleSettingsSectionPage(1)
    end, {
        height = CONTROL_HEIGHT,
        fontSize = BUTTON_FONT_SIZE,
    })
    sectionPagerRow:AddChild(self.SettingsNextSectionButton)
    self.SettingsRootLayout:AddChild(sectionPagerRow)

    self.SettingsTeamColumns = {
        { key = "order", label = "#", width = 24, justifyH = "LEFT" },
        { key = "name", label = "Team", width = 182, justifyH = "LEFT" },
        { key = "color", label = "Colour", width = 172, justifyH = "LEFT" },
    }
    self.SettingsAffixColumns = {
        { key = "dataset", label = "Dataset", width = 110, justifyH = "LEFT" },
        { key = "aura", label = "Aura", width = 190, justifyH = "LEFT" },
        { key = "teams", label = "Teams", width = 78, justifyH = "LEFT" },
    }
    self.SettingsLootColumns = {
        { key = "dataset", label = "Dataset", width = 128, justifyH = "LEFT" },
        { key = "loot", label = "Loot", width = 250, justifyH = "LEFT" },
    }

    self.SettingsTablePanel = createTablePanel(self.SettingsRootLayout:GetFrame(), "RPEServerEventManageSettingsSharedPanel", settingsWidth, 88)
    self.SettingsTablePanel._visibleHeight = 88
    self.SettingsTableHeader = createSettingsTableHeader(self.SettingsTablePanel:GetContentFrame(), "RPEServerEventManageSettingsSharedHeaderRow", sectionTableWidth, self.SettingsTeamColumns)
    self.SettingsTableHeader:GetFrame():SetPoint("TOPLEFT", self.SettingsTablePanel:GetContentFrame(), "TOPLEFT", 0, 0)
    self.SettingsTableHeader:GetFrame():SetPoint("TOPRIGHT", self.SettingsTablePanel:GetContentFrame(), "TOPRIGHT", 0, 0)
    self.SettingsTableHeader:RefreshLayout()
    self.SettingsTable = UI.ScrollLayout:New({
        name = "RPEServerEventManageSettingsSharedTable",
        width = sectionTableWidth,
        height = 72,
        visibleRows = 4,
        rowHeight = TABLE_ROW_HEIGHT,
        rowSpacing = 0,
        border = false,
        rowElementClass = UI.TableRow,
    })
    self.SettingsTable:SetParent(self.SettingsTablePanel:GetContentFrame())
    self.SettingsTable:SetRowRenderer(function(row, item, itemIndex)
        local activePage = self:GetActiveSettingsSectionDefinition()
        local rows, selectedIndex, onSelect = self:BuildSettingsSharedRows(activePage and activePage.key or "teams", self:GetEditableSettingsState())
        local selectedRow = rows and rows[itemIndex] or item
        self:ConfigureSettingsScrollRow(row, selectedRow, itemIndex, activePage and activePage.columns or self.SettingsTeamColumns, onSelect, selectedIndex)
    end)
    self.SettingsTable:Create()
    self.SettingsTable:GetFrame():SetPoint("TOPLEFT", self.SettingsTableHeader:GetFrame(), "BOTTOMLEFT", 0, -2)
    self.SettingsTable:GetFrame():SetPoint("TOPRIGHT", self.SettingsTableHeader:GetFrame(), "BOTTOMRIGHT", 0, -2)
    self.SettingsTable:GetFrame():SetPoint("BOTTOMLEFT", self.SettingsTablePanel:GetContentFrame(), "BOTTOMLEFT", 0, 0)
    self.SettingsTable:GetFrame():SetPoint("BOTTOMRIGHT", self.SettingsTablePanel:GetContentFrame(), "BOTTOMRIGHT", 0, 0)
    self.SettingsRootLayout:AddChild(self.SettingsTablePanel)

    self.SettingsEditorHost = UI.CreatePanel(self.SettingsRootLayout:GetFrame(), "RPEServerEventManageSettingsEditorHost", {
        width = settingsWidth,
        height = CONTROL_HEIGHT,
        contentInset = 0,
        showBackground = false,
        showBorder = false,
        panelBackgroundColor = { r = 0, g = 0, b = 0, a = 0 },
        backdropColor = { r = 0, g = 0, b = 0, a = 0 },
    })
    self.SettingsEditorHost._visibleHeight = CONTROL_HEIGHT
    self.SettingsRootLayout:AddChild(self.SettingsEditorHost)

    local editorParent = self.SettingsEditorHost.GetContentFrame and self.SettingsEditorHost:GetContentFrame() or self.SettingsEditorHost:GetFrame()

    local teamEditorRow = createSettingsRow(editorParent, "RPEServerEventManageSettingsTeamEditorRow", settingsWidth)
    self.SettingsTeamEditorRow = teamEditorRow
    self.SettingsTeamEditorRow._visibleHeight = CONTROL_HEIGHT
    self.SettingsTeamEditorRow:SetPoint("TOPLEFT", editorParent, "TOPLEFT", 0, 0)
    self.SettingsTeamEditorRow:SetPoint("TOPRIGHT", editorParent, "TOPRIGHT", 0, 0)
    teamEditorRow:AddChild(createLabel(teamEditorRow:GetFrame(), "RPEServerEventManageSettingsTeamNameEditorLabel", "Name", 32))
    self.TeamNameInput = UI.CreateTextInput(teamEditorRow:GetFrame(), "RPEServerEventManageSettingsTeamNameInput", {
        width = 140,
        height = CONTROL_HEIGHT,
        text = "",
        borderColor = UI.ResolveColor(nil, "panel.border"),
    })
    teamEditorRow:AddChild(self.TeamNameInput)

    teamEditorRow:AddChild(createLabel(teamEditorRow:GetFrame(), "RPEServerEventManageSettingsTeamColorEditorLabel", "Hex", 24))
    self.TeamColorInput = UI.CreateTextInput(teamEditorRow:GetFrame(), "RPEServerEventManageSettingsTeamColorInput", {
        width = 86,
        height = CONTROL_HEIGHT,
        text = "",
        borderColor = UI.ResolveColor(nil, "panel.border"),
    })
    self.TeamColorInput:SetScript("OnTextChanged", function(input)
        setPreviewColor(self.TeamColorPreview, parseColorHex(input:GetText(), getDefaultTeamColor(self.SelectedEventTeamIndex or 1)))
    end)
    teamEditorRow:AddChild(self.TeamColorInput)

    self.TeamColorPreview = UI.CreatePanel(teamEditorRow:GetFrame(), "RPEServerEventManageSettingsTeamColorPreview", {
        width = PREVIEW_SIZE,
        height = PREVIEW_SIZE,
        contentInset = 0,
        showBorder = true,
        panelBorderSize = 1,
        panelBackgroundColor = getDefaultTeamColor(1),
        panelBorderColor = UI.ResolveColor(nil, "panel.border"),
    })
    teamEditorRow:AddChild(self.TeamColorPreview)

    self.AddTeamButton = UI.CreateButton(teamEditorRow:GetFrame(), "RPEServerEventManageSettingsAddTeamButton", "Add", smallButtonWidth, function()
        local eventState = self:GetEditableSettingsState()
        local nextIndex = #(eventState and eventState.teams or {}) + 1
        self:CommitEventSettings(function(state)
            state.teams = state.teams or {}
            state.teams[#state.teams + 1] = {
                id = ("team%d"):format(nextIndex),
                name = ("Team %d"):format(nextIndex),
                color = getDefaultTeamColor(nextIndex),
            }
        end)
        self.SelectedEventTeamIndex = nextIndex
        self:RefreshTeamsTable()
        self:RefreshSettingsPage()
    end, {
        height = CONTROL_HEIGHT,
        fontSize = BUTTON_FONT_SIZE,
    })
    teamEditorRow:AddChild(self.AddTeamButton)

    self.SaveTeamButton = UI.CreateButton(teamEditorRow:GetFrame(), "RPEServerEventManageSettingsSaveTeamButton", "Save", smallButtonWidth, function()
        local selectedIndex = tonumber(self.SelectedEventTeamIndex)
        if not selectedIndex then
            return
        end

        local teamName = trimString(self.TeamNameInput and self.TeamNameInput.GetText and self.TeamNameInput:GetText() or "")
        local teamColorText = self.TeamColorInput and self.TeamColorInput.GetText and self.TeamColorInput:GetText() or ""
        self:CommitEventSettings(function(state)
            local team = state.teams and state.teams[selectedIndex] or nil
            if not team then
                return
            end

            team.name = teamName ~= "" and teamName or ("Team %d"):format(selectedIndex)
            team.color = parseColorHex(teamColorText, team.color or getDefaultTeamColor(selectedIndex))
        end)
        self:RefreshTeamsTable()
        self:RefreshTeamEditor()
        self:RefreshSettingsPage()
    end, {
        height = CONTROL_HEIGHT,
        fontSize = BUTTON_FONT_SIZE,
    })
    teamEditorRow:AddChild(self.SaveTeamButton)

    self.RemoveTeamButton = UI.CreateButton(teamEditorRow:GetFrame(), "RPEServerEventManageSettingsRemoveTeamButton", "Remove", removeButtonWidth, function()
        local selectedIndex = tonumber(self.SelectedEventTeamIndex)
        if not selectedIndex then
            return
        end

        self:CommitEventSettings(function(state)
            local teams = state.teams or {}
            if #teams <= 1 or not teams[selectedIndex] then
                return
            end

            table.remove(teams, selectedIndex)
            local replacementIndex = math.max(1, selectedIndex - 1)
            for unitIndex = 1, #(state.units or {}) do
                local unit = state.units[unitIndex]
                local unitTeam = math.floor(tonumber(unit and unit.team) or 1)
                if unitTeam == selectedIndex then
                    unit.team = replacementIndex
                elseif unitTeam > selectedIndex then
                    unit.team = unitTeam - 1
                end
            end
            for auraIndex = 1, #(state.eventAuras or {}) do
                local entry = state.eventAuras[auraIndex]
                if type(entry) == "table" then
                    local sourceTeams = cloneTeamIndexList(entry.teamIndices, #teams)
                    local remappedTeams = {}
                    for teamIndex = 1, #sourceTeams do
                        local numericTeam = sourceTeams[teamIndex]
                        if numericTeam == selectedIndex then
                            remappedTeams[#remappedTeams + 1] = replacementIndex
                        elseif numericTeam > selectedIndex then
                            remappedTeams[#remappedTeams + 1] = numericTeam - 1
                        else
                            remappedTeams[#remappedTeams + 1] = numericTeam
                        end
                    end
                    entry.teamIndices = cloneTeamIndexList(remappedTeams, #teams)
                end
            end
        end)
        local teamCount = #(self:GetEditableSettingsState() and self:GetEditableSettingsState().teams or {})
        self.SelectedEventTeamIndex = teamCount > 0 and math.max(1, math.min(selectedIndex - 1, teamCount)) or nil
        self:RefreshTeamsTable()
        self:RefreshTeamEditor()
        self:RefreshSettingsPage()
    end, {
        height = CONTROL_HEIGHT,
        fontSize = BUTTON_FONT_SIZE,
    })
    teamEditorRow:AddChild(self.RemoveTeamButton)

    local affixEditorRow = createSettingsRow(editorParent, "RPEServerEventManageSettingsAffixEditorRow", settingsWidth)
    self.SettingsAffixEditorRow = affixEditorRow
    self.SettingsAffixEditorRow._visibleHeight = CONTROL_HEIGHT
    self.SettingsAffixEditorRow:SetPoint("TOPLEFT", editorParent, "TOPLEFT", 0, 0)
    self.SettingsAffixEditorRow:SetPoint("TOPRIGHT", editorParent, "TOPRIGHT", 0, 0)
    self.AffixDatasetDropdown = UI.CreateDropdown(affixEditorRow:GetFrame(), "RPEServerEventManageSettingsAffixDatasetDropdown", {
        width = 110,
        height = DROPDOWN_HEIGHT,
        items = buildDatasetItems("auras", "Dataset"),
        selectedValue = "",
        onValueChanged = function(value)
            self.SelectedEventAffixDatasetId = trimString(value)
            self.SelectedEventAffixRef = ""
            self.SelectedEventAffixIndex = nil
            self:RefreshAffixEditor()
            self:RefreshAffixesTable()
        end,
    })
    affixEditorRow:AddChild(self.AffixDatasetDropdown)

    self.AffixTraitDropdown = UI.CreateDropdown(affixEditorRow:GetFrame(), "RPEServerEventManageSettingsAffixTraitDropdown", {
        width = 156,
        height = DROPDOWN_HEIGHT,
        items = buildDatasetEntryItems("", "auras", "Aura"),
        selectedValue = "",
        onValueChanged = function(value)
            self.SelectedEventAffixRef = trimString(value)
        end,
    })
    affixEditorRow:AddChild(self.AffixTraitDropdown)

    self.EventAuraTeamsDropdown = UI.CreateDropdown(affixEditorRow:GetFrame(), "RPEServerEventManageSettingsEventAuraTeamsDropdown", {
        width = 110,
        height = DROPDOWN_HEIGHT,
        items = {},
        multiSelect = true,
        selectedValues = {},
        placeholder = "All Teams",
        onValueChanged = function(values)
            self.SelectedEventAuraTeamIndices = values or {}
        end,
    })
    affixEditorRow:AddChild(self.EventAuraTeamsDropdown)

    self.AddAffixButton = UI.CreateButton(affixEditorRow:GetFrame(), "RPEServerEventManageSettingsAddAffixButton", "Add", smallButtonWidth, function()
        local auraRef = trimString(self.SelectedEventAffixRef)
        if auraRef == "" then
            return
        end

        local teamCount = #(self:GetEditableSettingsState() and self:GetEditableSettingsState().teams or {})
        local teamIndices = cloneTeamIndexList(self.EventAuraTeamsDropdown and self.EventAuraTeamsDropdown.GetSelectedValues and self.EventAuraTeamsDropdown:GetSelectedValues() or self.SelectedEventAuraTeamIndices or {}, teamCount)
        self:CommitEventSettings(function(state)
            state.eventAuras = state.eventAuras or {}
            local normalizedTeams = cloneTeamIndexList(teamIndices, #(state.teams or {}))
            local teamSignature = table.concat(normalizedTeams, ",")
            for index = 1, #state.eventAuras do
                local existing = state.eventAuras[index]
                if trimString(existing and existing.auraRef) == auraRef
                    and table.concat(cloneTeamIndexList(existing and existing.teamIndices or nil, #(state.teams or {})), ",") == teamSignature
                then
                    return
                end
            end
            state.eventAuras[#state.eventAuras + 1] = {
                auraRef = auraRef,
                teamIndices = normalizedTeams,
            }
        end)
        self.SelectedEventAffixIndex = #(self:GetEditableSettingsState() and self:GetEditableSettingsState().eventAuras or {})
        self:RefreshAffixesTable()
        self:RefreshAffixEditor()
        self:RefreshSettingsPage()
    end, {
        height = CONTROL_HEIGHT,
        fontSize = BUTTON_FONT_SIZE,
    })
    affixEditorRow:AddChild(self.AddAffixButton)

    self.RemoveAffixButton = UI.CreateButton(affixEditorRow:GetFrame(), "RPEServerEventManageSettingsRemoveAffixButton", "Remove", removeButtonWidth, function()
        local selectedIndex = tonumber(self.SelectedEventAffixIndex)
        if not selectedIndex then
            return
        end

        self:CommitEventSettings(function(state)
            if state.eventAuras and state.eventAuras[selectedIndex] then
                table.remove(state.eventAuras, selectedIndex)
            end
        end)
        self.SelectedEventAffixIndex = nil
        self:RefreshAffixesTable()
        self:RefreshAffixEditor()
        self:RefreshSettingsPage()
    end, {
        height = CONTROL_HEIGHT,
        fontSize = BUTTON_FONT_SIZE,
    })
    affixEditorRow:AddChild(self.RemoveAffixButton)

    local lootEditorRow = createSettingsRow(editorParent, "RPEServerEventManageSettingsLootEditorRow", settingsWidth)
    self.SettingsLootEditorRow = lootEditorRow
    self.SettingsLootEditorRow._visibleHeight = CONTROL_HEIGHT
    self.SettingsLootEditorRow:SetPoint("TOPLEFT", editorParent, "TOPLEFT", 0, 0)
    self.SettingsLootEditorRow:SetPoint("TOPRIGHT", editorParent, "TOPRIGHT", 0, 0)
    self.LootDatasetDropdown = UI.CreateDropdown(lootEditorRow:GetFrame(), "RPEServerEventManageSettingsLootDatasetDropdown", {
        width = 116,
        height = DROPDOWN_HEIGHT,
        items = buildDatasetItems("loot", "Dataset"),
        selectedValue = "",
        onValueChanged = function(value)
            self.SelectedEventLootDatasetId = trimString(value)
            self.SelectedEventLootRef = ""
            self.SelectedEventLootIndex = nil
            self:RefreshLootEditor()
            self:RefreshLootTable()
        end,
    })
    lootEditorRow:AddChild(self.LootDatasetDropdown)

    self.LootRefDropdown = UI.CreateDropdown(lootEditorRow:GetFrame(), "RPEServerEventManageSettingsLootRefDropdown", {
        width = 222,
        height = DROPDOWN_HEIGHT,
        items = buildDatasetEntryItems("", "loot", "Loot"),
        selectedValue = "",
        onValueChanged = function(value)
            self.SelectedEventLootRef = trimString(value)
        end,
    })
    lootEditorRow:AddChild(self.LootRefDropdown)

    self.AddLootButton = UI.CreateButton(lootEditorRow:GetFrame(), "RPEServerEventManageSettingsAddLootButton", "Add", smallButtonWidth, function()
        local lootRef = trimString(self.SelectedEventLootRef)
        if lootRef == "" then
            return
        end

        self:CommitEventSettings(function(state)
            state.lootRefs = state.lootRefs or {}
            for index = 1, #state.lootRefs do
                if state.lootRefs[index] == lootRef then
                    return
                end
            end
            state.lootRefs[#state.lootRefs + 1] = lootRef
        end)
        self.SelectedEventLootIndex = #(self:GetEditableSettingsState() and self:GetEditableSettingsState().lootRefs or {})
        self:RefreshLootTable()
        self:RefreshLootEditor()
        self:RefreshSettingsPage()
    end, {
        height = CONTROL_HEIGHT,
        fontSize = BUTTON_FONT_SIZE,
    })
    lootEditorRow:AddChild(self.AddLootButton)

    self.RemoveLootButton = UI.CreateButton(lootEditorRow:GetFrame(), "RPEServerEventManageSettingsRemoveLootButton", "Remove", removeButtonWidth, function()
        local selectedIndex = tonumber(self.SelectedEventLootIndex)
        if not selectedIndex then
            return
        end

        self:CommitEventSettings(function(state)
            if state.lootRefs and state.lootRefs[selectedIndex] then
                table.remove(state.lootRefs, selectedIndex)
            end
        end)
        self.SelectedEventLootIndex = nil
        self:RefreshLootTable()
        self:RefreshLootEditor()
        self:RefreshSettingsPage()
    end, {
        height = CONTROL_HEIGHT,
        fontSize = BUTTON_FONT_SIZE,
    })
    lootEditorRow:AddChild(self.RemoveLootButton)

    self:RefreshSettingsPage()
    return self.SettingsRootLayout
end
