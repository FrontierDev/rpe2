local _, Addon = ...

Addon.Server = Addon.Server or {}
Addon.Server.UI = Addon.Server.UI or {}
Addon.Internal = Addon.Internal or {}
Addon.Internal.Database = Addon.Internal.Database or {}
Addon.Internal.Database.Classes = Addon.Internal.Database.Classes or {}

local ServerUI = Addon.Server.UI
local Classes = Addon.Internal.Database.Classes
local EventUnitClass = Classes.EventUnit
local EventUnitWindow = ServerUI.EventUnit

if type(EventUnitWindow) ~= "table" then
    return
end

local function normalizeVariantIndex(value)
    if EventUnitClass and type(EventUnitClass.NormalizeVariantIndex) == "function" then
        return EventUnitClass.NormalizeVariantIndex(value)
    end

    local numericValue = tonumber(value)
    if numericValue == nil or numericValue ~= numericValue or numericValue == math.huge or numericValue == -math.huge then
        return 0
    end

    return math.max(0, math.floor(numericValue))
end

local function cloneRuntimeEventUnit(unit)
    if type(unit) ~= "table" then
        return nil
    end

    if EventUnitClass and type(EventUnitClass.FromTable) == "function" then
        local source = type(unit.ToTable) == "function" and unit:ToTable() or unit
        return EventUnitClass.FromTable(source)
    end

    return unit
end

local function resolveBaseUnit(window, runtimeUnit)
    if type(runtimeUnit) == "table" and type(runtimeUnit.GetResolvedUnit) == "function" then
        local ok, unit = pcall(runtimeUnit.GetResolvedUnit, runtimeUnit)
        if ok and type(unit) == "table" then
            return unit
        end
    end

    if type(window.ResolveUnitDefinition) == "function" then
        local _, unit = window:ResolveUnitDefinition(runtimeUnit and runtimeUnit.registryID or nil)
        return unit
    end

    return nil
end

local function resolvePresetName(runtimeUnit, presetIndex)
    if presetIndex <= 0 then
        return "Base"
    end

    if type(runtimeUnit) == "table" and type(runtimeUnit.GetResolvedPreset) == "function" then
        local ok, preset = pcall(runtimeUnit.GetResolvedPreset, runtimeUnit)
        if ok and type(preset) == "table" then
            local name = tostring(preset.name or ""):gsub("^%s+", ""):gsub("%s+$", "")
            if name ~= "" then
                return name
            end
        end
    end

    return ("Unavailable (#%d)"):format(presetIndex)
end

local function resolveRuntimeName(runtimeUnit)
    local runtimeName = tostring(runtimeUnit and runtimeUnit.name or "")
    if runtimeName ~= "" then
        return runtimeName
    end

    if type(runtimeUnit) == "table" and type(runtimeUnit.GetResolvedVariantName) == "function" then
        local ok, name = pcall(runtimeUnit.GetResolvedVariantName, runtimeUnit)
        if ok and tostring(name or "") ~= "" then
            return tostring(name)
        end
    end

    return "Unnamed Unit"
end

local function buildProvenanceText(window, runtimeUnit)
    local baseUnit = resolveBaseUnit(window, runtimeUnit)
    local baseName = tostring(baseUnit and baseUnit.name or ""):gsub("^%s+", ""):gsub("%s+$", "")
    if baseName == "" then
        baseName = "Unavailable"
    end

    local presetIndex = normalizeVariantIndex(runtimeUnit and runtimeUnit.presetIndex)
    local presetName = resolvePresetName(runtimeUnit, presetIndex)
    return ("Base: %s | Preset: %s"):format(baseName, presetName), baseUnit, presetIndex
end

local baseOpenForAdd = EventUnitWindow.OpenForAdd
function EventUnitWindow:OpenForAdd(callback)
    self.viewRuntimeUnit = nil
    self.viewBaseUnit = nil
    if baseOpenForAdd then
        return baseOpenForAdd(self, callback)
    end
end

function EventUnitWindow:OpenForView(unit)
    local runtimeUnit = cloneRuntimeEventUnit(unit)
    local registryId = runtimeUnit and runtimeUnit.registryID or (type(unit) == "table" and unit.registryID or nil)
    local dataset, baseUnit = nil, nil
    if type(self.ResolveUnitDefinition) == "function" then
        dataset, baseUnit = self:ResolveUnitDefinition(registryId)
    end

    self.mode = "view"
    self.callback = nil
    self.selectedRegistryId = registryId
    self.sourceDatasetName = dataset and (type(dataset.name) == "string" and dataset.name ~= "" and dataset.name or dataset.id) or nil
    self.selectedUnit = runtimeUnit
    self.viewRuntimeUnit = runtimeUnit
    self.viewBaseUnit = baseUnit
    self.selectedPresetIndex = normalizeVariantIndex(runtimeUnit and runtimeUnit.presetIndex)
    self.selectedTeam = tonumber(runtimeUnit and runtimeUnit.team) or 1
    self.selectedActive = runtimeUnit and runtimeUnit.active ~= false or false
    self.selectedHidden = runtimeUnit and runtimeUnit.hidden == true or false
    self.selectedBoss = runtimeUnit and runtimeUnit.boss == true or false
    self.selectedRaidMarker = tonumber(runtimeUnit and runtimeUnit.raidMarker) or 0
    self:Show()
end

local baseRefresh = EventUnitWindow.Refresh
function EventUnitWindow:Refresh()
    if baseRefresh then
        baseRefresh(self)
    end

    if self.mode ~= "view" then
        return
    end

    local runtimeUnit = self.viewRuntimeUnit or self.selectedUnit
    if type(runtimeUnit) ~= "table" then
        return
    end

    local provenanceText, baseUnit, presetIndex = buildProvenanceText(self, runtimeUnit)
    self.viewBaseUnit = baseUnit
    self.selectedPresetIndex = presetIndex

    if self.previewPortrait and type(self.previewPortrait.SetUnit) == "function" then
        self.previewPortrait:SetUnit(runtimeUnit)
    end

    if self.previewNameText and type(self.previewNameText.SetText) == "function" then
        self.previewNameText:SetText(resolveRuntimeName(runtimeUnit))
    end

    if self.previewSummaryText and type(self.previewSummaryText.SetText) == "function" then
        self.previewSummaryText:SetText(provenanceText)
    end

    if self.previewHealthText and type(self.previewHealthText.SetText) == "function" then
        self.previewHealthText:SetText(self:BuildUnitHealthText(runtimeUnit))
    end

    self:RefreshSpellPreview(runtimeUnit)

    if self.presetDropdown then
        if type(self.presetDropdown.SetItems) == "function" then
            self.presetDropdown:SetItems(self:BuildPresetItems(baseUnit))
        end
        if type(self.presetDropdown.SetSelectedValue) == "function" then
            self.presetDropdown:SetSelectedValue(presetIndex, true)
        end
        if type(self.presetDropdown.SetEnabled) == "function" then
            self.presetDropdown:SetEnabled(false)
        end
    end

    if self.previewTextColumn and type(self.previewTextColumn.RefreshLayout) == "function" then
        self.previewTextColumn:RefreshLayout()
    end
    if self.previewSection and type(self.previewSection.RefreshLayout) == "function" then
        self.previewSection:RefreshLayout()
    end
    if self.rootLayout and type(self.rootLayout.RefreshLayout) == "function" then
        self.rootLayout:RefreshLayout()
    end
end
