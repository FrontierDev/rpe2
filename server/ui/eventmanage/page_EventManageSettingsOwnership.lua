local _, Addon = ...

Addon.Server = Addon.Server or {}
Addon.Server.UI = Addon.Server.UI or {}
Addon.Internal = Addon.Internal or {}
Addon.Internal.Database = Addon.Internal.Database or {}
Addon.Internal.Database.Classes = Addon.Internal.Database.Classes or {}

local Server = Addon.Server
local EventManage = Addon.Server.UI.EventManage
local EventClass = Addon.Internal.Database.Classes.Event

if type(EventManage) ~= "table" or type(EventClass) ~= "table" or EventManage._settingsOwnershipInstalled == true then
    return
end

-- The Settings page intentionally owns only these Event fields. Its cached edit
-- model is allowed to contain a complete Event snapshot for UI/preset purposes,
-- but ordinary settings commits must never write unrelated cached runtime state
-- back over the current draft/live Event.
local SETTINGS_OWNED_EVENT_FIELDS = {
    "name",
    "subtext",
    "description",
    "difficulty",
    "level",
    "teams",
    "eventAuras",
    "lootRefs",
    "endLootGrants",
    "turnMode",
}

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

local function buildSettingsOwnedPatch(normalizedTable, includeUnits)
    local patch = {}
    for index = 1, #SETTINGS_OWNED_EVENT_FIELDS do
        local field = SETTINGS_OWNED_EVENT_FIELDS[index]
        if normalizedTable[field] ~= nil then
            patch[field] = deepCopy(normalizedTable[field])
        end
    end

    if includeUnits == true then
        patch.units = deepCopy(normalizedTable.units or {})
    end

    return patch
end

local function teamId(team)
    return type(team) == "table" and tostring(team.id or "") or ""
end

-- Removing one team is the one ordinary Settings operation that previously
-- adjusted unit-owned data as a consequence: numeric unit.team indices. Detect
-- that exact structural edit from the latest live teams and rebase the index
-- change onto the latest live roster instead of copying cached EventUnits.
local function detectSingleRemovedTeam(previousTeams, nextTeams)
    previousTeams = type(previousTeams) == "table" and previousTeams or {}
    nextTeams = type(nextTeams) == "table" and nextTeams or {}
    if #previousTeams ~= #nextTeams + 1 then
        return nil
    end

    local removedIndex = nil
    local nextIndex = 1
    for previousIndex = 1, #previousTeams do
        local previousId = teamId(previousTeams[previousIndex])
        local nextId = teamId(nextTeams[nextIndex])
        if nextIndex <= #nextTeams and previousId ~= "" and previousId == nextId then
            nextIndex = nextIndex + 1
        elseif removedIndex == nil then
            removedIndex = previousIndex
        else
            return nil
        end
    end

    if removedIndex == nil or nextIndex <= #nextTeams then
        return nil
    end
    return removedIndex
end

local function remapUnitsAfterTeamRemoval(units, removedIndex)
    local replacementIndex = math.max(1, removedIndex - 1)
    for index = 1, #(units or {}) do
        local unit = units[index]
        if type(unit) == "table" then
            local currentTeam = math.max(1, math.floor(tonumber(unit.team) or 1))
            if currentTeam == removedIndex then
                unit.team = replacementIndex
            elseif currentTeam > removedIndex then
                unit.team = currentTeam - 1
            end
        end
    end
end

function EventManage:PushEditableSettingsState()
    local stateTable = self:GetEditableSettingsState()
    if not stateTable then
        return false
    end

    local normalized = EventClass.FromTable and EventClass.FromTable(stateTable) or stateTable
    local normalizedTable = normalized and normalized.ToTable and normalized:ToTable() or deepCopy(normalized) or {}
    self.EditableSettingsState = normalizedTable

    local liveState = Server.GetEditableEventState and Server:GetEditableEventState() or nil
    if type(liveState) ~= "table" then
        return false
    end

    local includeUnits = self._settingsPresetIncludesUnits == true
    local previousTeams = deepCopy(liveState.teams or {})
    local patch = buildSettingsOwnedPatch(normalizedTable, includeUnits)

    if type(liveState.Merge) == "function" then
        liveState:Merge(patch)
    else
        for key, value in pairs(patch) do
            liveState[key] = deepCopy(value)
        end
    end

    if includeUnits ~= true then
        local removedTeamIndex = detectSingleRemovedTeam(previousTeams, liveState.teams)
        if removedTeamIndex then
            remapUnitsAfterTeamRemoval(liveState.units, removedTeamIndex)
        end
    end

    if liveState.active == true then
        Server.EventState = liveState
    else
        Server.EventDraftState = liveState
    end
    return true
end

-- Preset loading is the sole Settings path that intentionally owns the roster.
-- Scope that permission to the existing LoadSelectedPreset call so all ordinary
-- CommitEventSettings callers (including Autopilot and end-loot settings) stay
-- roster-blind.
local baseLoadSelectedPreset = EventManage.LoadSelectedPreset
function EventManage:LoadSelectedPreset(...)
    if type(baseLoadSelectedPreset) ~= "function" then
        return false
    end

    local presetName = self.GetSelectedPresetName and self:GetSelectedPresetName() or ""
    local presets = self.GetSettingsPresetCollection and self:GetSettingsPresetCollection() or nil
    local preset = type(presets) == "table" and presets[presetName] or nil
    local previousIncludeUnits = self._settingsPresetIncludesUnits
    self._settingsPresetIncludesUnits = type(preset) == "table" and preset.includesUnits == true

    local result = baseLoadSelectedPreset(self, ...)

    self._settingsPresetIncludesUnits = previousIncludeUnits
    return result
end

EventManage._settingsOwnershipInstalled = true
