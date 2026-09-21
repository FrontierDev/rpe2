local _, Addon = ...

Addon.Server = Addon.Server or {}
Addon.Server.UI = Addon.Server.UI or {}
Addon.Internal = Addon.Internal or {}

local Server = Addon.Server
local ServerUI = Addon.Server.UI
local Registry = Addon.Internal.Registry or {}
local Ruleset = Addon.Internal and Addon.Internal.Ruleset or {}
local ResourceSync = Addon.Internal and Addon.Internal.Comms and Addon.Internal.Comms.ResourceSync or {}
local UI = Addon.UI or {}
local Inline = UI.Inline or {}
local EventClass = Addon.Internal and Addon.Internal.Database and Addon.Internal.Database.Classes and Addon.Internal.Database.Classes.Event or nil

ServerUI.EventUnit = ServerUI.EventUnit or {}
local EventUnitWindow = ServerUI.EventUnit
EventUnitWindow.__index = EventUnitWindow

local WINDOW_WIDTH = 336
local WINDOW_HEIGHT = 196
local CONTROL_HEIGHT = 22
local SIDE_PAD = 8
local DEFAULT_SPELL_ICON = "Interface\\Icons\\INV_Misc_QuestionMark"
local SPELL_ICON_SIZE = 16

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

local function ensureString(value)
    if value == nil then
        return ""
    end

    return tostring(value)
end

local function trimString(value)
    return ensureString(value):gsub("^%s+", ""):gsub("%s+$", "")
end

local function titleCaseWords(value)
    local text = trimString(value):gsub("[%-%_]+", " "):lower()
    if text == "" then
        return ""
    end

    return (text:gsub("(%a)([%w']*)", function(first, rest)
        return string.upper(first) .. rest
    end))
end

local function getFirstTag(entry)
    if type(entry) ~= "table" or type(entry.tags) ~= "table" then
        return ""
    end

    return trimString(entry.tags[1])
end

local function compareSubgroupLabels(left, right)
    if left == "Other" and right ~= "Other" then
        return false
    end
    if right == "Other" and left ~= "Other" then
        return true
    end

    return string.lower(left) < string.lower(right)
end

local function buildUnitSubgroupInfo(unit)
    local creatureType = trimString(type(unit) == "table" and unit.creatureType or nil)
    if creatureType ~= "" then
        return {
            label = titleCaseWords(creatureType),
            key = "creature:" .. string.lower(creatureType),
        }
    end

    local firstTag = getFirstTag(unit)
    if firstTag ~= "" then
        return {
            label = titleCaseWords(firstTag),
            key = "tag:" .. string.lower(firstTag),
        }
    end

    return {
        label = "Other",
        key = "other",
    }
end

function EventUnitWindow:BuildUnitItems()
    local items = {
        { label = "Select Unit", value = "" },
    }

    local datasets = Registry.GetActivatedDatasets and Registry:GetActivatedDatasets() or {}
    for datasetIndex = 1, #datasets do
        local dataset = datasets[datasetIndex]
        local subgroupMap = {}
        local subgroupOrder = {}

        for unitIndex = 1, #(dataset and dataset.units or {}) do
            local unit = dataset.units[unitIndex]
            if unit and unit.id then
                local registryId = ("%s:%s"):format(dataset.id, unit.id)
                local displayUnit = unit
                local invalidInheritance = false
                if type(Registry.ResolveUnitDefinition) == "function" then
                    local ok, _, resolved = pcall(function()
                        return Registry:ResolveUnitDefinition(registryId)
                    end)
                    if ok and resolved then
                        displayUnit = resolved
                    elseif not ok then
                        invalidInheritance = true
                    end
                end
                local subgroup = buildUnitSubgroupInfo(displayUnit)
                if not subgroupMap[subgroup.key] then
                    subgroupMap[subgroup.key] = {
                        label = subgroup.label,
                        children = {},
                    }
                    subgroupOrder[#subgroupOrder + 1] = subgroup.key
                end

                subgroupMap[subgroup.key].children[#subgroupMap[subgroup.key].children + 1] = {
                    label = (type(displayUnit.name) == "string" and displayUnit.name ~= "" and displayUnit.name or tostring(unit.id))
                        .. (invalidInheritance and " (invalid inheritance)" or ""),
                    value = registryId,
                }
            end
        end

        if #subgroupOrder > 0 then
            table.sort(subgroupOrder, function(leftKey, rightKey)
                local leftGroup = subgroupMap[leftKey]
                local rightGroup = subgroupMap[rightKey]
                return compareSubgroupLabels(leftGroup and leftGroup.label or "", rightGroup and rightGroup.label or "")
            end)

            local children = {}
            for subgroupIndex = 1, #subgroupOrder do
                local subgroupKey = subgroupOrder[subgroupIndex]
                local subgroupGroup = subgroupMap[subgroupKey]
                children[#children + 1] = {
                    label = subgroupGroup.label,
                    value = ("subgroup:units:%s:%s"):format(dataset.id or datasetIndex, subgroupKey),
                    enabled = true,
                    keepShownOnClick = true,
                    notCheckable = true,
                    children = subgroupGroup.children,
                }
            end

            items[#items + 1] = {
                label = type(dataset.name) == "string" and dataset.name ~= "" and dataset.name or tostring(dataset.id),
                value = ("dataset:%s"):format(dataset.id or datasetIndex),
                enabled = true,
                keepShownOnClick = true,
                notCheckable = true,
                children = children,
            }
        end
    end

    return items
end

function EventUnitWindow:BuildTeamItems()
    local items = {}
    local eventState = Server.GetEditableEventState and Server:GetEditableEventState() or nil
    local teams = eventState and eventState.teams or nil

    for team = 1, #(teams or {}) do
        items[#items + 1] = {
            label = EventClass and EventClass.GetTeamName and EventClass.GetTeamName(eventState, team) or ("Team %d"):format(team),
            value = team,
        }
    end

    if #items == 0 then
        items[1] = {
            label = "Team 1",
            value = 1,
        }
    end

    return items
end

function EventUnitWindow:BuildRaidMarkerItems()
    local items = {}

    local noneLabel = "No Raid Marker"
    items[#items + 1] = {
        label = noneLabel,
        value = 0,
    }

    for marker = 1, 8 do
        local label = ("Raid Marker %d"):format(marker)
        if type(Inline.RaidMarker) == "function" then
            label = ("%s %s"):format(Inline:RaidMarker(marker, 12, 12), label)
        end
        items[#items + 1] = {
            label = label,
            value = marker,
        }
    end

    return items
end

local function normalizeHealthLabel(text)
    local normalized = tostring(text or ""):lower()
    normalized = normalized:gsub("[%s_%-]", "")
    return normalized
end

local function formatNumericValue(value)
    local numericValue = tonumber(value)
    if numericValue == nil then
        return nil
    end

    if numericValue == math.floor(numericValue) then
        return tostring(math.floor(numericValue))
    end

    return ("%.1f"):format(numericValue)
end

function EventUnitWindow:GetSelectedTeamLabel()
    local eventState = Server.GetEditableEventState and Server:GetEditableEventState() or nil
    return EventClass and EventClass.GetTeamName and EventClass.GetTeamName(eventState, tonumber(self.selectedTeam) or 1) or ("Team %d"):format(tonumber(self.selectedTeam) or 1)
end

function EventUnitWindow:GetSelectedTeamColor()
    local eventState = Server.GetEditableEventState and Server:GetEditableEventState() or nil
    local color = EventClass and EventClass.GetTeamColor and EventClass.GetTeamColor(eventState, tonumber(self.selectedTeam) or 1) or nil
    return color or UI.ResolveColor(nil, "text.secondary")
end

function EventUnitWindow:ResolveSelectedTeamIndex(value)
    local eventState = Server.GetEditableEventState and Server:GetEditableEventState() or nil
    local teams = eventState and eventState.teams or {}
    local teamCount = #teams
    if teamCount <= 0 then
        return 1
    end

    local numericValue = tonumber(value)
    if numericValue ~= nil then
        numericValue = math.floor(numericValue)
        if numericValue < 1 then
            return 1
        end
        if numericValue > teamCount then
            return teamCount
        end
        return numericValue
    end

    local selectedLabel = tostring(value or "")
    if selectedLabel ~= "" then
        for teamIndex = 1, teamCount do
            local teamLabel = EventClass and EventClass.GetTeamName and EventClass.GetTeamName(eventState, teamIndex) or ("Team %d"):format(teamIndex)
            if tostring(teamLabel) == selectedLabel then
                return teamIndex
            end
        end
    end

    return 1
end

function EventUnitWindow:GetUnitHealthResourceRef()
    local activeRuleset = Ruleset.GetActiveRuleset and Ruleset.GetActiveRuleset() or nil
    local ruleDefinition = Ruleset.GetRulesetRuleDefinition and Ruleset.GetRulesetRuleDefinition("stats", "health_stat") or nil
    local value = Ruleset.GetRulesetRuleValue and Ruleset.GetRulesetRuleValue(activeRuleset, "stats", ruleDefinition) or nil
    if type(value) == "string" and value ~= "" then
        return value
    end

    return nil
end

function EventUnitWindow:ResolveUnitHealthEntry(unit)
    local resources = type(unit) == "table" and unit.resources or nil
    if type(resources) ~= "table" then
        return nil
    end

    local healthResourceRef = self:GetUnitHealthResourceRef()
    if healthResourceRef ~= nil then
        for index = 1, #resources do
            local entry = resources[index]
            if entry and entry.resourceRef == healthResourceRef then
                return entry
            end
        end
    end

    for index = 1, #resources do
        local entry = resources[index]
        local resourceName = type(ResourceSync.ResolveResourceName) == "function" and ResourceSync.ResolveResourceName(entry and entry.resourceRef or nil) or nil
        local normalizedName = normalizeHealthLabel(resourceName)
        if normalizedName == "health" or normalizedName == "hp" or normalizedName == "hitpoints" then
            return entry
        end
    end

    for index = 1, #resources do
        local entry = resources[index]
        if entry and (entry.maxValue ~= nil or entry.currentValue ~= nil or entry.value ~= nil) then
            return entry
        end
    end

    return nil
end

function EventUnitWindow:BuildUnitCreatureSummary(unit)
    if type(unit) ~= "table" then
        return ""
    end

    local creatureSize = titleCaseWords(unit.creatureSize ~= "" and unit.creatureSize or "medium")
    local creatureType = titleCaseWords(unit.creatureType ~= "" and unit.creatureType or "humanoid")
    if creatureSize ~= "" and creatureType ~= "" then
        return ("%s %s"):format(creatureSize, creatureType)
    end

    return creatureSize ~= "" and creatureSize or creatureType
end

function EventUnitWindow:BuildUnitHealthText(unit)
    local healthEntry = self:ResolveUnitHealthEntry(unit)
    if not healthEntry then
        return "HP: -"
    end

    local resolvedValue = healthEntry.maxValue
    if resolvedValue == nil then
        resolvedValue = healthEntry.currentValue
    end
    if resolvedValue == nil then
        resolvedValue = healthEntry.value
    end

    local formattedValue = formatNumericValue(resolvedValue)
    if not formattedValue then
        return "HP: -"
    end

    return ("HP: %s"):format(formattedValue)
end

function EventUnitWindow:ResolveUnitSpellDetails(unit)
    local details = {}
    local spellRefs = type(unit) == "table" and unit.spells or nil
    if type(spellRefs) ~= "table" then
        return details
    end

    for index = 1, #spellRefs do
        local spellRef = spellRefs[index]
        if type(spellRef) == "table" then
            spellRef = spellRef.spellRef or spellRef.spellID or spellRef.id or spellRef.name
        end

        if type(spellRef) == "string" and spellRef ~= "" then
            local spell = nil
            if Registry.ResolveSpellReference then
                _, spell = Registry:ResolveSpellReference(spellRef)
            end

            details[#details + 1] = {
                spellRef = spellRef,
                name = Registry.ResolveSpellName and Registry:ResolveSpellName(spellRef) or spellRef,
                icon = spell and type(spell.icon) == "string" and spell.icon ~= "" and spell.icon or DEFAULT_SPELL_ICON,
            }
        end
    end

    return details
end

function EventUnitWindow:RefreshSpellPreview(unit)
    if not self.previewSpellsGrid then
        return
    end

    local spellDetails = self:ResolveUnitSpellDetails(unit)
    self.previewSpellsGrid:ClearChildren()
    self.previewSpellIcons = self.previewSpellIcons or {}

    for index = 1, #spellDetails do
        local spellDetail = spellDetails[index]
        local icon = self.previewSpellIcons[index]
        if not icon then
            icon = UI.Image:New({
                name = ("RPEServerEventUnitPreviewSpellIcon%d"):format(index),
                width = SPELL_ICON_SIZE,
                height = SPELL_ICON_SIZE,
                expandWidth = false,
                expandHeight = false,
                textureInsetLeft = 0,
                textureInsetTop = 0,
                textureInsetRight = 0,
                textureInsetBottom = 0,
                texture = DEFAULT_SPELL_ICON,
                texCoord = {
                    left = 0.08,
                    right = 0.92,
                    top = 0.08,
                    bottom = 0.92,
                },
            })
            icon:SetParent(self.previewSpellsGrid:GetFrame())
            icon:Create()
            self.previewSpellIcons[index] = icon
        end

        icon:SetTexture(spellDetail.icon or DEFAULT_SPELL_ICON)
        local iconFrame = icon.GetFrame and icon:GetFrame() or nil
        if iconFrame and iconFrame.SetShown then
            iconFrame:SetShown(true)
        end
        self.previewSpellsGrid:AddChild(icon)
    end

    for index = #spellDetails + 1, #(self.previewSpellIcons or {}) do
        local icon = self.previewSpellIcons[index]
        local iconFrame = icon and icon.GetFrame and icon:GetFrame() or nil
        if iconFrame and iconFrame.SetShown then
            iconFrame:SetShown(false)
        end
    end

    local spellsGridFrame = self.previewSpellsGrid.GetFrame and self.previewSpellsGrid:GetFrame() or nil
    if spellsGridFrame and spellsGridFrame.SetShown then
        spellsGridFrame:SetShown(#spellDetails > 0)
    end
    if self.previewSpellsGrid.RefreshLayout then
        self.previewSpellsGrid:RefreshLayout()
    end
end

function EventUnitWindow:ResolveUnitDefinition(registryId)
    if type(Registry.ResolveUnitDefinition) ~= "function" then
        return nil, nil
    end
    return Registry:ResolveUnitDefinition(registryId)
end

function EventUnitWindow:SetViewedUnit(unit, options)
    self.selectedUnit = type(unit) == "table" and deepCopy(unit) or nil
    self.selectedRegistryId = type(options) == "table" and options.registryId or nil
    self.sourceDatasetName = type(options) == "table" and options.datasetName or nil
    self.mode = type(options) == "table" and options.mode or "view"
    self.callback = type(options) == "table" and options.callback or nil
    self.selectedTeam = tonumber(type(options) == "table" and options.team or nil) or tonumber(unit and unit.team) or 1
    if type(options) == "table" and options.active ~= nil then
        self.selectedActive = options.active ~= false
    else
        self.selectedActive = unit and unit.active ~= false or false
    end
    if type(options) == "table" and options.hidden ~= nil then
        self.selectedHidden = options.hidden == true
    else
        self.selectedHidden = unit and unit.hidden == true or false
    end
    if type(options) == "table" and options.boss ~= nil then
        self.selectedBoss = options.boss == true
    else
        self.selectedBoss = unit and unit.boss == true or false
    end
    self.selectedRaidMarker = tonumber(type(options) == "table" and options.raidMarker or nil)
        or tonumber(unit and unit.raidMarker)
        or 0

    if self.unitDropdown then
        self.unitDropdown:SetSelectedValue(self.selectedRegistryId or "", true)
    end
    if self.teamDropdown then
        self.teamDropdown:SetSelectedValue(self.selectedTeam, true)
    end
    if self.activeCheckbox then
        self.activeCheckbox:SetChecked(self.selectedActive, true)
    end
    if self.hiddenCheckbox then
        self.hiddenCheckbox:SetChecked(self.selectedHidden, true)
    end
    if self.bossCheckbox then
        self.bossCheckbox:SetChecked(self.selectedBoss, true)
    end
    if self.raidMarkerDropdown then
        self.raidMarkerDropdown:SetSelectedValue(self.selectedRaidMarker, true)
    end

    self:Refresh()
end

function EventUnitWindow:Refresh()
    local unit = self.selectedUnit
    local hasUnit = unit ~= nil
    local addMode = self.mode == "add"

    if self.unitDropdown and self.unitDropdown.SetItems then
        self.unitDropdown:SetItems(self:BuildUnitItems())
        self.unitDropdown:SetSelectedValue(self.selectedRegistryId or "", true)
    end
    if self.teamDropdown and self.teamDropdown.SetItems then
        self.teamDropdown:SetItems(self:BuildTeamItems())
    end
    if self.raidMarkerDropdown and self.raidMarkerDropdown.SetItems then
        self.raidMarkerDropdown:SetItems(self:BuildRaidMarkerItems())
    end

    if self.unitDropdown and self.unitDropdown.SetEnabled then
        self.unitDropdown:SetEnabled(addMode)
    end
    if self.teamDropdown and self.teamDropdown.SetEnabled then
        self.teamDropdown:SetEnabled(addMode)
    end
    if self.activeCheckbox and self.activeCheckbox.SetEnabled then
        self.activeCheckbox:SetEnabled(addMode)
    end
    if self.hiddenCheckbox and self.hiddenCheckbox.SetEnabled then
        self.hiddenCheckbox:SetEnabled(addMode)
    end
    if self.bossCheckbox and self.bossCheckbox.SetEnabled then
        self.bossCheckbox:SetEnabled(addMode)
    end
    if self.raidMarkerDropdown and self.raidMarkerDropdown.SetEnabled then
        self.raidMarkerDropdown:SetEnabled(addMode)
    end
    if self.teamDropdown then
        self.teamDropdown:SetSelectedValue(tonumber(self.selectedTeam) or 1, true)
    end
    if self.activeCheckbox then
        self.activeCheckbox:SetChecked(self.selectedActive == true, true)
    end
    if self.hiddenCheckbox then
        self.hiddenCheckbox:SetChecked(self.selectedHidden == true, true)
    end
    if self.bossCheckbox then
        self.bossCheckbox:SetChecked(self.selectedBoss == true, true)
    end
    if self.raidMarkerDropdown then
        self.raidMarkerDropdown:SetSelectedValue(tonumber(self.selectedRaidMarker) or 0, true)
    end

    if self.previewPortrait and self.previewPortrait.SetUnit then
        self.previewPortrait:SetUnit(hasUnit and {
            isNPC = true,
            team = tonumber(self.selectedTeam) or 1,
            modelDisplayId = unit.displayId,
            fileDataId = unit.fileDataId,
            cam = unit.cam,
            rot = unit.rot,
            z = unit.z,
        } or nil)
    end
    if self.previewPortrait and self.previewPortrait.SetBorderColor then
        local color = hasUnit and self:GetSelectedTeamColor() or UI.ResolveColor(nil, "panel.border")
        self.previewPortrait:SetBorderColor(color.r or 1, color.g or 1, color.b or 1, color.a or 1)
    end
    if self.previewPortrait and self.previewPortrait.SetRaidMarker then
        self.previewPortrait:SetRaidMarker(hasUnit and (tonumber(self.selectedRaidMarker) or 0) or 0)
    end

    if self.previewNameText and self.previewNameText.SetText then
        self.previewNameText:SetText(hasUnit and (type(unit.name) == "string" and unit.name ~= "" and unit.name or "Unnamed Unit") or "No Unit Selected")
    end
    if self.previewTeamText and self.previewTeamText.SetText then
        self.previewTeamText:SetText(hasUnit and self:GetSelectedTeamLabel() or "")
    end
    if self.previewTeamText and self.previewTeamText.SetTextColor then
        local color = hasUnit and self:GetSelectedTeamColor() or UI.ResolveColor(nil, "text.secondary")
        self.previewTeamText:SetTextColor(color.r or 1, color.g or 1, color.b or 1, color.a or 1)
    end
    if self.previewSummaryText and self.previewSummaryText.SetText then
        self.previewSummaryText:SetText(hasUnit and self:BuildUnitCreatureSummary(unit) or "Select a unit to preview it.")
    end
    if self.previewHealthText and self.previewHealthText.SetText then
        self.previewHealthText:SetText(hasUnit and self:BuildUnitHealthText(unit) or "")
    end

    self:RefreshSpellPreview(unit)

    if self.dropdownRow and self.dropdownRow.RefreshLayout then
        self.dropdownRow:RefreshLayout()
    end
    if self.toggleRow and self.toggleRow.RefreshLayout then
        self.toggleRow:RefreshLayout()
    end
    if self.previewHeaderLayout and self.previewHeaderLayout.RefreshLayout then
        self.previewHeaderLayout:RefreshLayout()
    end
    if self.previewTextColumn and self.previewTextColumn.RefreshLayout then
        self.previewTextColumn:RefreshLayout()
    end
    if self.previewSection and self.previewSection.RefreshLayout then
        self.previewSection:RefreshLayout()
    end
    if self.rootLayout and self.rootLayout.RefreshLayout then
        self.rootLayout:RefreshLayout()
    end

    if self.applyButton and self.applyButton.SetEnabled then
        self.applyButton:SetEnabled(addMode and hasUnit)
    end

    if self.applyButton and self.applyButton.GetFrame and self.applyButton:GetFrame() and self.applyButton:GetFrame().SetShown then
        self.applyButton:GetFrame():SetShown(addMode)
    end
end

function EventUnitWindow:HandleUnitSelection(registryId)
    self.selectedRegistryId = type(registryId) == "string" and registryId or ""
    local dataset, unit = self:ResolveUnitDefinition(self.selectedRegistryId)
    self.sourceDatasetName = dataset and (type(dataset.name) == "string" and dataset.name ~= "" and dataset.name or dataset.id) or nil
    self.selectedUnit = unit and deepCopy(unit) or nil
    self:Refresh()
end

function EventUnitWindow:HandleTeamSelection(team)
    self.selectedTeam = self:ResolveSelectedTeamIndex(team)
    self:Refresh()
end

function EventUnitWindow:HandleActiveSelection(value)
    self.selectedActive = value == true
    self:Refresh()
end

function EventUnitWindow:HandleHiddenSelection(value)
    self.selectedHidden = value == true
    self:Refresh()
end

function EventUnitWindow:HandleBossSelection(value)
    self.selectedBoss = value == true
    self:Refresh()
end

function EventUnitWindow:HandleRaidMarkerSelection(value)
    self.selectedRaidMarker = math.max(0, math.floor(tonumber(value) or 0))
    self:Refresh()
end

function EventUnitWindow:ApplySelection()
    if self.mode ~= "add" or not self.selectedUnit then
        return false
    end

    if type(self.callback) == "function" then
        self.callback(self.selectedRegistryId, deepCopy(self.selectedUnit), {
            team = tonumber(self.selectedTeam) or 1,
            active = self.selectedActive ~= false,
            hidden = self.selectedHidden == true,
            boss = self.selectedBoss == true,
            raidMarker = math.max(0, math.floor(tonumber(self.selectedRaidMarker) or 0)),
        })
    end

    return true
end

function EventUnitWindow:BuildWindow()
    if self.window then
        return self.window
    end

    self.window = UI.Window:New({
        name = "RPEServerEventUnitWindow",
        width = WINDOW_WIDTH,
        height = WINDOW_HEIGHT,
        point = "CENTER",
        relativeTo = UIParent,
        relativePoint = "CENTER",
        x = 0,
        y = 0,
        frameStrata = "HIGH",
        frameLevel = 25,
        movable = true,
        clampedToScreen = true,
        toplevel = true,
        hidden = true,
        contentInsetLeft = SIDE_PAD,
        contentInsetRight = SIDE_PAD,
        contentInsetTop = 28,
        contentInsetBottom = SIDE_PAD,
    })
    self.window:SetTitle("Event Unit")
    self.window:Create()

    local content = self.window:GetContentFrame()

    self.rootLayout = UI.CreateLayout(UI.VerticalLayoutGroup, content, "RPEServerEventUnitRootLayout", {
        spacing = 8,
        fitChildrenWidth = true,
        fitChildrenHeight = false,
    })
    UI.Utils.AnchorFill(self.rootLayout, content, 0, 0, 0, 0)

    self.dropdownRow = UI.CreateLayout(UI.HorizontalLayoutGroup, content, "RPEServerEventUnitDropdownRow", {
        width = WINDOW_WIDTH - (SIDE_PAD * 2),
        height = CONTROL_HEIGHT,
        spacing = 8,
        autoSize = false,
        fitChildrenWidth = false,
        fitChildrenHeight = false,
    })
    self.rootLayout:AddChild(self.dropdownRow)

    self.unitDropdown = UI.CreateDropdown(content, "RPEServerEventUnitDropdown", {
        width = 206,
        items = self:BuildUnitItems(),
        selectedValue = "",
        placeholder = "Select Unit",
        onValueChanged = function(value)
            self:HandleUnitSelection(value)
        end,
    })
    self.dropdownRow:AddChild(self.unitDropdown)

    self.teamDropdown = UI.CreateDropdown(content, "RPEServerEventUnitTeamDropdown", {
        width = 106,
        items = self:BuildTeamItems(),
        selectedValue = 1,
        placeholder = "Select Team",
        onValueChanged = function(value)
            self:HandleTeamSelection(value)
        end,
    })
    self.dropdownRow:AddChild(self.teamDropdown)

    self.toggleRow = UI.CreateLayout(UI.HorizontalLayoutGroup, content, "RPEServerEventUnitToggleRow", {
        width = WINDOW_WIDTH - (SIDE_PAD * 2),
        height = CONTROL_HEIGHT,
        spacing = 8,
        autoSize = false,
        fitChildrenWidth = false,
        fitChildrenHeight = false,
    })
    self.rootLayout:AddChild(self.toggleRow)

    self.activeCheckbox = UI.Checkbox:New({
        name = "RPEServerEventUnitActiveCheckbox",
        width = 76,
        height = CONTROL_HEIGHT,
        text = "Active",
        checked = true,
        onValueChanged = function(value)
            self:HandleActiveSelection(value)
        end,
    })
    self.activeCheckbox:SetParent(content)
    self.activeCheckbox:Create()
    self.toggleRow:AddChild(self.activeCheckbox)

    self.hiddenCheckbox = UI.Checkbox:New({
        name = "RPEServerEventUnitHiddenCheckbox",
        width = 76,
        height = CONTROL_HEIGHT,
        text = "Hidden",
        checked = false,
        onValueChanged = function(value)
            self:HandleHiddenSelection(value)
        end,
    })
    self.hiddenCheckbox:SetParent(content)
    self.hiddenCheckbox:Create()
    self.toggleRow:AddChild(self.hiddenCheckbox)

    self.bossCheckbox = UI.Checkbox:New({
        name = "RPEServerEventUnitBossCheckbox",
        width = 68,
        height = CONTROL_HEIGHT,
        text = "Boss",
        checked = false,
        onValueChanged = function(value)
            self:HandleBossSelection(value)
        end,
    })
    self.bossCheckbox:SetParent(content)
    self.bossCheckbox:Create()
    self.toggleRow:AddChild(self.bossCheckbox)

    self.raidMarkerDropdown = UI.CreateDropdown(content, "RPEServerEventUnitRaidMarkerDropdown", {
        width = 76,
        height = 18,
        items = self:BuildRaidMarkerItems(),
        selectedValue = 0,
        placeholder = "Raid Marker",
        onValueChanged = function(value)
            self:HandleRaidMarkerSelection(value)
        end,
    })
    self.toggleRow:AddChild(self.raidMarkerDropdown)

    self.previewSection = UI.CreateLayout(UI.VerticalLayoutGroup, content, "RPEServerEventUnitPreviewSection", {
        width = WINDOW_WIDTH - (SIDE_PAD * 2),
        height = 60,
        spacing = 0,
        autoSize = false,
        fitChildrenWidth = false,
        fitChildrenHeight = false,
    })
    self.rootLayout:AddChild(self.previewSection)

    self.previewHeaderLayout = UI.CreateLayout(UI.HorizontalLayoutGroup, content, "RPEServerEventUnitPreviewHeader", {
        width = WINDOW_WIDTH - (SIDE_PAD * 2),
        height = 60,
        spacing = 10,
        autoSize = false,
        fitChildrenWidth = false,
        fitChildrenHeight = false,
    })
    self.previewSection:AddChild(self.previewHeaderLayout)

    self.previewPortrait = UI.UnitPortrait:New({
        name = "RPEServerEventUnitPreviewPortrait",
        width = 48,
        height = 48,
        portraitWidth = 48,
        portraitHeight = 48,
        progressHeight = 0,
        progressSpacing = 0,
        border = false,
    })
    self.previewPortrait:SetParent(self.previewHeaderLayout:GetFrame())
    self.previewPortrait:Create()
    self.previewHeaderLayout:AddChild(self.previewPortrait)

    self.previewTextColumn = UI.CreateLayout(UI.VerticalLayoutGroup, self.previewHeaderLayout:GetFrame(), "RPEServerEventUnitPreviewTextColumn", {
        width = 166,
        height = 60,
        spacing = 1,
        autoSize = false,
        fitChildrenWidth = true,
        fitChildrenHeight = false,
    })
    self.previewHeaderLayout:AddChild(self.previewTextColumn)

    self.previewNameText = UI.CreateText(self.previewTextColumn:GetFrame(), "RPEServerEventUnitPreviewNameText", "No Unit Selected", {
        width = 166,
        height = 16,
        justifyH = "LEFT",
        fontSize = 11,
        textColor = UI.ResolveColor(nil, "text.primary"),
    })
    self.previewTextColumn:AddChild(self.previewNameText)

    self.previewTeamText = UI.CreateText(self.previewTextColumn:GetFrame(), "RPEServerEventUnitPreviewTeamText", "", {
        width = 166,
        height = 14,
        justifyH = "LEFT",
        wordWrap = false,
        textColor = UI.ResolveColor(nil, "text.secondary"),
    })
    self.previewTextColumn:AddChild(self.previewTeamText)

    self.previewSummaryText = UI.CreateText(self.previewTextColumn:GetFrame(), "RPEServerEventUnitPreviewSummaryText", "Select a unit to preview it.", {
        width = 166,
        height = 14,
        justifyH = "LEFT",
        wordWrap = false,
        textColor = UI.ResolveColor(nil, "text.secondary"),
    })
    self.previewTextColumn:AddChild(self.previewSummaryText)

    self.previewHealthText = UI.CreateText(self.previewTextColumn:GetFrame(), "RPEServerEventUnitPreviewHealthText", "", {
        width = 166,
        height = 14,
        justifyH = "LEFT",
        wordWrap = false,
        textColor = UI.ResolveColor(nil, "text.secondary"),
    })
    self.previewTextColumn:AddChild(self.previewHealthText)

    self.previewSpellsGrid = UI.CreateLayout(UI.GridLayoutGroup, content, "RPEServerEventUnitPreviewSpellsGrid", {
        width = 76,
        height = 36,
        columns = 4,
        cellWidth = SPELL_ICON_SIZE,
        cellHeight = SPELL_ICON_SIZE,
        spacing = 4,
        autoSize = false,
        fitChildrenWidth = false,
        fitChildrenHeight = false,
    })
    self.previewHeaderLayout:AddChild(self.previewSpellsGrid)

    self.footerLayout = UI.CreateLayout(UI.HorizontalLayoutGroup, content, "RPEServerEventUnitFooterLayout", {
        spacing = 8,
        autoSize = true,
        fitChildrenWidth = false,
        fitChildrenHeight = false,
    })
    self.rootLayout:AddChild(self.footerLayout)

    self.cancelButton = UI.CreateButton(content, "RPEServerEventUnitCancelButton", "Close", 72, function()
        self:Hide()
    end, {
        height = CONTROL_HEIGHT,
        fontSize = 8,
    })
    self.footerLayout:AddChild(self.cancelButton)

    self.applyButton = UI.CreateButton(content, "RPEServerEventUnitApplyButton", "Add To Event", 96, function()
        local applied = self:ApplySelection()
        if not applied then
            return
        end

        if not (IsShiftKeyDown and IsShiftKeyDown()) then
            self:Hide()
        end
    end, {
        height = CONTROL_HEIGHT,
        fontSize = 8,
    })
    self.footerLayout:AddChild(self.applyButton)

    return self.window
end

function EventUnitWindow:Show()
    self:BuildWindow()
    self.window:Show()
    self:Refresh()
end

function EventUnitWindow:Hide()
    if self.window and self.window.Hide then
        self.window:Hide()
    end
end

function EventUnitWindow:OpenForAdd(callback)
    self.mode = "add"
    self.callback = callback
    self.selectedRegistryId = ""
    self.selectedUnit = nil
    self.sourceDatasetName = nil
    self.selectedTeam = 1
    self.selectedActive = true
    self.selectedHidden = false
    self.selectedBoss = false
    self.selectedRaidMarker = 0
    self:Show()
end

function EventUnitWindow:OpenForView(unit)
    local registryId = type(unit) == "table" and unit.registryID or nil
    local dataset, sourceUnit = self:ResolveUnitDefinition(registryId)

    self.mode = "view"
    self.callback = nil
    self.selectedRegistryId = registryId
    self.sourceDatasetName = dataset and (type(dataset.name) == "string" and dataset.name ~= "" and dataset.name or dataset.id) or nil
    self.selectedUnit = sourceUnit and deepCopy(sourceUnit) or (type(unit) == "table" and deepCopy(unit) or nil)
    self.selectedTeam = tonumber(unit and unit.team) or 1
    self.selectedActive = unit and unit.active ~= false or false
    self.selectedHidden = unit and unit.hidden == true or false
    self.selectedBoss = unit and unit.boss == true or false
    self.selectedRaidMarker = tonumber(unit and unit.raidMarker) or 0
    self:Show()
end

function ServerUI:BuildEventUnitWindow()
    return EventUnitWindow:BuildWindow()
end

function ServerUI:ShowEventUnitWindow()
    EventUnitWindow:Show()
end

function ServerUI:HideEventUnitWindow()
    EventUnitWindow:Hide()
end

function ServerUI:OpenEventUnitWindow(callback)
    EventUnitWindow:OpenForAdd(callback)
end
