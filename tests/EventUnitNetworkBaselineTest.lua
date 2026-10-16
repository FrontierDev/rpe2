local function assertEqual(actual, expected, message)
    if actual ~= expected then
        error(("%s: expected %s, got %s"):format(message, tostring(expected), tostring(actual)), 2)
    end
end

local function assertClose(actual, expected, message)
    if math.abs((tonumber(actual) or 0) - expected) > 0.000001 then
        error(("%s: expected %s, got %s"):format(message, tostring(expected), tostring(actual)), 2)
    end
end

local function splitPreservingEmpty(text, separator)
    local values = {}
    local source = tostring(text or "")
    local startIndex = 1
    while true do
        local separatorIndex = string.find(source, separator, startIndex, true)
        if not separatorIndex then
            values[#values + 1] = string.sub(source, startIndex)
            break
        end
        values[#values + 1] = string.sub(source, startIndex, separatorIndex - 1)
        startIndex = separatorIndex + #separator
    end
    return values
end

local dataset
local Addon = {
    Internal = {
        Comms = { Operations = {} },
        Database = { Classes = {} },
        Registry = {
            GetActivatedDatasets = function()
                return { dataset }
            end,
            ResolveUnitDefinition = function(_, unitRef)
                if type(dataset) ~= "table" or tostring(unitRef or "") ~= "test:npc" then
                    return nil, nil
                end
                for index = 1, #(dataset.units or {}) do
                    local unit = dataset.units[index]
                    if unit and tostring(unit.id or "") == "npc" then
                        return dataset, unit
                    end
                end
                return nil, nil
            end,
        },
        Ruleset = {
            GetRulesetRuleValueByKey = function(_, category, key, fallback)
                if category == "resources" and key == "health_stat" then
                    return "test:health"
                end
                if category == "event" and key == "player_scaling_challenge_levels" then
                    return { "normal" }
                end
                if category == "event" and key == "npc_health_bonus_per_player_percent" then
                    return "20"
                end
                return fallback
            end,
            GetNpcDifficultyModifiers = function(difficulty)
                return { healthPercent = difficulty == "heroic" and 10 or 0 }
            end,
        },
    },
    Utils = { Common = {
        SplitPreservingEmpty = splitPreservingEmpty,
        NormalizeName = function(value)
            return tostring(value or ""):lower():gsub("^%s+", ""):gsub("%s+$", "")
        end,
        GetPlayerName = function()
            return "Host"
        end,
    } },
    Server = {},
}

local function loadAddonFile(path)
    local chunk, loadError = loadfile(path)
    assert(chunk, loadError)
    chunk(nil, Addon)
end

-- Match the addon TOC order: EventUnit is loaded before Unit.
loadAddonFile("core/classes/EventUnit.lua")
loadAddonFile("core/classes/Unit.lua")
loadAddonFile("core/classes/EventUnitVariantIdentity.lua")
loadAddonFile("core/classes/EventUnitResourcePipeline.lua")
loadAddonFile("core/classes/Event.lua")
loadAddonFile("core/classes/EventVariantNetwork.lua")
loadAddonFile("core/classes/EventVariantSpellEquipmentNetwork.lua")
loadAddonFile("core/internal/comms/PrimaryResourceSync.lua")
loadAddonFile("core/internal/comms/SelectedPetSync.lua")
loadAddonFile("core/internal/comms/EventUnitDisplayNameSync.lua")

local Classes = Addon.Internal.Database.Classes
local Unit = Classes.Unit
local Event = Classes.Event
local EventUnit = Classes.EventUnit

local definition = Unit:New({
    id = "npc",
    name = "Progressing NPC",
    challengeLevel = "normal",
    spells = { "test:spell" },
    stats = {
        { statRef = "test:power", initialValue = 100, perLevelValue = 10 },
    },
    resources = {
        { resourceRef = "test:health", initialValue = 100, perLevelValue = 10 },
        { resourceRef = "test:mana", initialValue = 20, perLevelValue = 2 },
    },
    presets = {
        {
            name = "Empowered",
            appearances = {
                { displayId = 123456 },
            },
            statModifiers = {
                { statRef = "test:power", percentBonus = 50, flatBonus = 5 },
            },
            resourceModifiers = {
                { resourceRef = "test:health", percentBonus = 50, flatBonus = 0 },
                { resourceRef = "test:mana", percentBonus = 0, flatBonus = 5 },
            },
        },
    },
}):ToTable()
dataset = { id = "test", name = "Network test", units = { definition } }

local function findRow(rows, key, ref)
    for index = 1, #(rows or {}) do
        if rows[index] and rows[index][key] == ref then
            return rows[index]
        end
    end
    return nil
end

local function materializeNpc(eventId, level, presetIndex, difficulty)
    local npc = EventUnit:New({
        eventID = eventId,
        registryID = "test:npc",
        name = "Progressing NPC",
        presetIndex = presetIndex or 0,
        spells = { "test:spell" },
    })
    local options = { level = level, difficulty = difficulty or "normal", healthResourceRef = "test:health" }
    npc.stats = EventUnit.BuildResolvedStats(npc, nil, options)
    npc.resources = EventUnit.BuildResolvedResources(npc, 2, options)
    return npc
end

local function buildEvent(level, npc, difficulty)
    local event = Event:New({
        id = "network-event",
        name = "Network test",
        channelName = "test-channel",
        hostName = "Host",
        active = true,
        level = level,
        difficulty = difficulty or "normal",
        units = {
            EventUnit:New({ eventID = 1, isPlayer = true, name = "One" }),
            EventUnit:New({ eventID = 2, isPlayer = true, name = "Two" }),
            npc,
        },
    })
    Addon.Server.EventState = event
    return event
end

local function networkFields(serialized)
    local unitRecord = splitPreservingEmpty(serialized, string.char(30))[3]
    return splitPreservingEmpty(unitRecord, string.char(29))
end

local function assertStatsEqual(actual, expected, message)
    assertEqual(#(actual or {}), #(expected or {}), message .. " row count")
    for index = 1, #(expected or {}) do
        local expectedRow = expected[index]
        local actualRow = findRow(actual, "statRef", expectedRow.statRef)
        assert(actualRow, message .. " missing " .. tostring(expectedRow.statRef))
        assertClose(actualRow.value, expectedRow.value, message .. " value for " .. expectedRow.statRef)
        local actualCurrent = actualRow.currentValue ~= nil and actualRow.currentValue or actualRow.value
        local expectedCurrent = expectedRow.currentValue ~= nil and expectedRow.currentValue or expectedRow.value
        assertClose(actualCurrent, expectedCurrent, message .. " current value for " .. expectedRow.statRef)
    end
end

local baseAt60 = materializeNpc(3, 60, 0)
local baseEvent = buildEvent(60, baseAt60)
local untouchedPayload = baseEvent:SerializeUnitsForNetwork()
local untouchedFields = networkFields(untouchedPayload)
assertEqual(untouchedFields[15], "", "untouched base NPC omits level-derived stats")
assertEqual(untouchedFields[20], "inherit", "untouched base NPC inherits level-derived stats")
assertEqual(untouchedFields[11], "", "untouched base NPC omits derived resource rows")
assertEqual(untouchedFields[18], "delta", "base NPC resource state uses a delta")

local baseRoundTrip = Event.DeserializeUnitsFromNetwork(untouchedPayload, {
    level = 60,
    difficulty = "normal",
    playerCount = 2,
})
assertStatsEqual(baseRoundTrip[3].stats, baseAt60.stats, "base NPC stats round trip")
assertClose(findRow(baseRoundTrip[3].resources, "resourceRef", "test:health").maxValue,
    findRow(baseAt60.resources, "resourceRef", "test:health").maxValue, "base NPC health maximum round trip")

local renamedNpc = materializeNpc(5, 60, 0)
renamedNpc.displayNameOverride = "  Elmsport   Citizen  "
local renamedEvent = buildEvent(60, renamedNpc)
local renamedPayload = renamedEvent:SerializeUnitsForNetwork()
local renamedFields = networkFields(renamedPayload)
assertEqual(renamedNpc.name, "Progressing NPC", "display override does not replace the canonical unit name")
assertEqual(renamedNpc:GetResolvedVariantName(), "Progressing NPC", "display override does not replace the resolved variant name")
assertEqual(renamedNpc:GetDisplayName(), "Elmsport Citizen", "display accessor normalizes the override")
assertEqual(renamedFields[34], "0", "display override leaves the existing pet-role field intact")
assertEqual(renamedFields[35], "1:Elmsport Citizen", "display override is appended as network field 35")
local renamedSnapshot = Event.DeserializeUnitsFromNetwork(renamedPayload, {
    level = 60,
    difficulty = "normal",
    playerCount = 2,
})
assertEqual(renamedSnapshot[3].displayNameOverride, "Elmsport Citizen", "snapshot preserves the display override")
assertEqual(renamedSnapshot[3]._networkDisplayNameOverridePresent, true, "snapshot records the explicit display override field")
local invalidOverrideUnit = EventUnit:New({
    eventID = 5,
    registryID = "test:npc",
    name = "Progressing NPC",
    displayNameOverride = "Existing Name",
})
invalidOverrideUnit:Merge({ displayNameOverride = "|cffff0000Unsafe|r" })
assertEqual(invalidOverrideUnit.displayNameOverride, "Existing Name", "invalid direct overrides do not clear an existing display name")

local legacyFields = splitPreservingEmpty(splitPreservingEmpty(renamedPayload, string.char(30))[3], string.char(29))
local legacyPayload = table.concat({ unpack(legacyFields, 1, 34) }, string.char(29))
local legacySnapshot = Event.DeserializeUnitsFromNetwork(legacyPayload, {
    level = 60,
    difficulty = "normal",
    playerCount = 2,
})
assertEqual(legacySnapshot[1].displayNameOverride, nil, "old 34-field snapshots do not invent an override")
assertEqual(legacySnapshot[1]._networkDisplayNameOverridePresent, nil, "old 34-field snapshots remain distinguishable from an explicit clear")

local clearIncoming = EventUnit:New({
    eventID = 5,
    registryID = "test:npc",
    name = "Progressing NPC",
})
local liveRenamed = EventUnit:New({
    eventID = 5,
    registryID = "test:npc",
    name = "Progressing NPC",
    displayNameOverride = "Elmsport Citizen",
})
assertEqual(liveRenamed:MergeLiveNetworkUpdate(clearIncoming), true, "legacy incomplete updates remain mergeable")
assertEqual(liveRenamed.displayNameOverride, "Elmsport Citizen", "legacy incomplete updates preserve the existing display override")
clearIncoming.displayNameOverride = nil
clearIncoming._networkDisplayNameOverridePresent = true
assertEqual(liveRenamed:MergeLiveNetworkUpdate(clearIncoming), true, "explicit display override clears remain mergeable")
assertEqual(liveRenamed.displayNameOverride, nil, "explicit display override clears erase the existing override")

renamedEvent.units[3].displayNameOverride = nil
local clearedPayload = renamedEvent:SerializeUnitsForNetwork()
local clearedFields = networkFields(clearedPayload)
assertEqual(clearedFields[34], "0", "display override clear does not alter the pet-role field")
assertEqual(clearedFields[35], "0", "display override clear is explicit on field 35")
local clearedSnapshot = Event.DeserializeUnitsFromNetwork(clearedPayload, {
    level = 60,
    difficulty = "normal",
    playerCount = 2,
})
assertEqual(clearedSnapshot[3].displayNameOverride, nil, "snapshot explicit clear removes the display override")
assertEqual(clearedSnapshot[3]._networkDisplayNameOverridePresent, true, "snapshot records an explicit display override clear")

local renamedDeltaUnit = materializeNpc(5, 60, 0)
renamedDeltaUnit.displayNameOverride = "Delta Citizen"
local renamedDelta = Event.SerializeUnitDeltaBatchForNetwork({
    { operation = "upsert", eventID = 5, unit = renamedDeltaUnit },
}, {
    level = 60,
    difficulty = "normal",
    playerCount = 2,
})
local renamedDeltaFields = splitPreservingEmpty(splitPreservingEmpty(renamedDelta, string.char(23))[1], string.char(22))
local renamedDeltaUnitFields = splitPreservingEmpty(renamedDeltaFields[3], string.char(29))
assertEqual(renamedDeltaUnitFields[35], "1:Delta Citizen", "display override is appended to live upserts")
local renamedDeltaEntries = Event.DeserializeUnitDeltaBatchFromNetwork(renamedDelta)
assertEqual(renamedDeltaEntries[1].unit.displayNameOverride, "Delta Citizen", "live upsert preserves the display override")
local legacyDeltaUnit = table.concat({ unpack(renamedDeltaUnitFields, 1, 34) }, string.char(29))
local legacyDeltaPayload = table.concat({ "upsert", "5", legacyDeltaUnit }, string.char(22))
local legacyDeltaEntries = Event.DeserializeUnitDeltaBatchFromNetwork(legacyDeltaPayload)
assertEqual(legacyDeltaEntries[1].unit.displayNameOverride, nil, "old 34-field deltas do not invent an override")
assertEqual(legacyDeltaEntries[1].unit._networkDisplayNameOverridePresent, nil, "old 34-field deltas preserve legacy merge semantics")

loadAddonFile("server/server_EventUnitNames.lua")
local nameMutationEvent = Event:New({
    id = "display-name-mutation-event",
    active = true,
    hostName = "Host",
    units = {
        EventUnit:New({ eventID = 1, isPlayer = true, name = "Host" }),
        EventUnit:New({ eventID = 2, registryID = "test:npc", name = "Progressing NPC" }),
        EventUnit:New({
            eventID = 4,
            registryID = "test:npc",
            name = "Progressing NPC",
            ownerID = "Host",
            controllerID = "Host",
            presetIndex = 1,
            team = 2,
            initiative = 17,
            resources = { { resourceRef = "test:health", currentValue = 80, maxValue = 100 } },
            stats = { { statRef = "test:power", value = 42 } },
        }),
        EventUnit:New({ eventID = 5, registryID = "test:npc", name = "Progressing NPC" }),
        EventUnit:New({ eventID = 6, registryID = "test:npc", name = "Progressing NPC" }),
    },
})
local broadcastEntries
local broadcastIncludeState
Addon.Server.GetEditableEventState = function()
    return nameMutationEvent
end
Addon.Server.BroadcastEventDeltaBatch = function(_, entries, includeState)
    broadcastEntries = entries
    broadcastIncludeState = includeState
    return true
end
Addon.Server.CopyLiveEventToDraftState = function()
    nameMutationEvent.draftCopied = true
end
local mutationOk, changedNameIds = Addon.Server:SetEventUnitDisplayNameOverrides({ 2, 4, 5, 6 }, "  Guard   Captain  ")
assertEqual(mutationOk, true, "host display-name mutation succeeds")
assert(type(changedNameIds) == "table", "host display-name mutation returns changed IDs")
assertEqual(#changedNameIds, 4, "host display-name mutation reports every changed NPC")
assertEqual(broadcastIncludeState, false, "display-name mutation broadcasts a delta without a full state")
assertEqual(#broadcastEntries, 4, "display-name mutation broadcasts only changed units")
assertEqual(nameMutationEvent.units[2]:GetDisplayName(), "Guard Captain", "host mutation applies the normalized display name")
assertEqual(nameMutationEvent.units[5].name, "Progressing NPC", "host mutation preserves the canonical name")
assertEqual(nameMutationEvent.units[3].registryID, "test:npc", "host mutation preserves registry identity")
assertEqual(nameMutationEvent.units[3].ownerID, "Host", "host mutation preserves owner identity")
assertEqual(nameMutationEvent.units[3].controllerID, "Host", "host mutation preserves controller identity")
assertEqual(nameMutationEvent.units[3].presetIndex, 1, "host mutation preserves preset identity")
assertEqual(nameMutationEvent.units[3].team, 2, "host mutation preserves team state")
assertEqual(nameMutationEvent.units[3].initiative, 17, "host mutation preserves initiative state")
assertEqual(nameMutationEvent.units[3].resources[1].currentValue, 80, "host mutation preserves resource state")
assertEqual(nameMutationEvent.units[3].stats[1].value, 42, "host mutation preserves stat state")
assertEqual(nameMutationEvent.units[1].displayNameOverride, nil, "host mutation leaves player units untouched")
assertEqual(nameMutationEvent.draftCopied, true, "active display-name mutation refreshes the draft copy")
local reassigned = Addon.Server:SetEventUnitDisplayNameOverrides({ 2, 4, 5 }, "Leader", {
    previousEventIds = { 2, 4, 5, 6 },
    previousDisplayName = "Guard Captain",
})
assertEqual(reassigned, true, "host reassignment succeeds")
assertEqual(nameMutationEvent.units[6].displayNameOverride, nil, "reassignment clears removed NPCs from the previous group")
assertEqual(nameMutationEvent.units[2].displayNameOverride, "Leader", "reassignment applies the new group name")
assertEqual(Addon.Server:SetEventUnitDisplayNameOverrides({ 1 }, "Invalid"), false, "players cannot receive display overrides")
assertEqual(Addon.Server:SetEventUnitDisplayNameOverrides({ 2, 2 }, "Invalid"), false, "duplicate event IDs are rejected")
assertEqual(Addon.Server:SetEventUnitDisplayNameOverrides({ 2 }, nil, { reset = true }), true, "host reset succeeds")
assertEqual(nameMutationEvent.units[2].displayNameOverride, nil, "host reset clears the display override")
assertEqual(Addon.Server:SetEventUnitDisplayNameOverrides({ 4, 5 }, "|cffff0000Unsafe|r"), false, "WoW markup is rejected")
assertEqual(nameMutationEvent.units[4].displayNameOverride, "Leader", "invalid names do not partially mutate the roster")
assertEqual(Addon.Server:SetEventUnitDisplayNameOverrides({ 4 }, string.rep("A", 81)), false, "overlong display names are rejected")
assertEqual(nameMutationEvent.units[4].displayNameOverride, "Leader", "overlong names do not partially mutate the roster")
assertEqual(Addon.Server:SetEventUnitDisplayNameOverrides({ 4 }, "Next", {
    previousEventIds = { 4, 5 },
    previousDisplayName = "|cffff0000Unsafe|r",
}), false, "invalid stale editor names are rejected")
assertEqual(nameMutationEvent.units[4].displayNameOverride, "Leader", "invalid stale editor names do not bypass assignment guards")
local originalGetPlayerName = Addon.Utils.Common.GetPlayerName
Addon.Utils.Common.GetPlayerName = function()
    return "Guest"
end
assertEqual(Addon.Server:SetEventUnitDisplayNameOverrides({ 4 }, "Guest View"), false, "non-host display-name mutations are rejected")
Addon.Utils.Common.GetPlayerName = originalGetPlayerName

local heroicNpc = materializeNpc(3, 60, 0, "heroic")
local heroicPayload = buildEvent(60, heroicNpc, "heroic"):SerializeUnitsForNetwork()
local heroicRoundTrip = Event.DeserializeUnitsFromNetwork(heroicPayload, {
    level = 60,
    difficulty = "heroic",
    playerCount = 2,
})
assertClose(findRow(heroicNpc.resources, "resourceRef", "test:health").maxValue, 1062.6,
    "health baseline includes player-count and difficulty scaling")
assertClose(findRow(heroicRoundTrip[3].resources, "resourceRef", "test:health").maxValue,
    findRow(heroicNpc.resources, "resourceRef", "test:health").maxValue,
    "resource hydration uses the same player-count and difficulty context")

local baseAt1 = materializeNpc(3, 1, 0)
local levelOnePayload = buildEvent(1, baseAt1):SerializeUnitsForNetwork()
assertEqual(levelOnePayload, untouchedPayload, "untouched level 1 and level 60 payloads carry no scaled baselines")

local presetAt60 = materializeNpc(3, 60, 1)
local presetEvent = buildEvent(60, presetAt60)
local presetPayload = presetEvent:SerializeUnitsForNetwork()
local presetFields = networkFields(presetPayload)
assertEqual(presetFields[15], "", "untouched preset NPC omits level-derived stats")
assertEqual(presetFields[20], "inherit", "untouched preset NPC inherits level and preset stats")
assertEqual(presetFields[11], "", "untouched preset NPC omits derived resource rows")
local presetRoundTrip = Event.DeserializeUnitsFromNetwork(presetPayload, {
    level = 60,
    difficulty = "normal",
    playerCount = 2,
})
assertStatsEqual(presetRoundTrip[3].stats, presetAt60.stats, "preset NPC stats round trip")
assertClose(findRow(presetRoundTrip[3].resources, "resourceRef", "test:health").maxValue,
    findRow(presetAt60.resources, "resourceRef", "test:health").maxValue, "preset health modifier survives compaction")
assertClose(findRow(presetRoundTrip[3].resources, "resourceRef", "test:mana").maxValue,
    findRow(presetAt60.resources, "resourceRef", "test:mana").maxValue, "preset mana modifier survives compaction")

local damagedNpc = materializeNpc(3, 60, 0)
findRow(damagedNpc.resources, "resourceRef", "test:health").currentValue = 123
local damagedPayload = buildEvent(60, damagedNpc):SerializeUnitsForNetwork()
local damagedRoundTrip = Event.DeserializeUnitsFromNetwork(damagedPayload, { level = 60, difficulty = "normal", playerCount = 2 })
local damagedHealth = findRow(damagedRoundTrip[3].resources, "resourceRef", "test:health")
assertClose(damagedHealth.currentValue, 123, "damage is synchronized relative to the local baseline")
assertClose(damagedHealth.maxValue, findRow(damagedNpc.resources, "resourceRef", "test:health").maxValue,
    "damage does not replace the derived maximum")

local buffedNpc = materializeNpc(3, 60, 0)
local power = findRow(buffedNpc.stats, "statRef", "test:power")
local powerCurrent = power.currentValue ~= nil and power.currentValue or power.value
power.value = power.value + 17
power.currentValue = powerCurrent + 17
local buffedPayload = buildEvent(60, buffedNpc):SerializeUnitsForNetwork()
local buffedFields = networkFields(buffedPayload)
assertEqual(buffedFields[20], "bonus", "runtime stat change uses a bonus relative to derived stats")
local statBonusRows = EventUnit.DeserializeStatsFromNetwork(buffedFields[21])
assertEqual(#statBonusRows, 1, "only changed stat rows cross the network")
assertClose(statBonusRows[1].value, 17, "runtime stat bonus amount")
local buffedRoundTrip = Event.DeserializeUnitsFromNetwork(buffedPayload, { level = 60, difficulty = "normal", playerCount = 2 })
assertStatsEqual(buffedRoundTrip[3].stats, buffedNpc.stats, "runtime stat bonus round trip")

local startEvent = buildEvent(60, materializeNpc(3, 60, 0))
local startArguments = startEvent:ToStartArguments()
local startedReceiver = Event.FromStartArguments(startArguments)
assertEqual(startedReceiver.level, 60, "start payload retains the Event level")
assertStatsEqual(startedReceiver.units[3].stats, startEvent.units[3].stats, "start hydration uses its Event level")

local snapshotReceiver = Event.DeserializeUnitsFromNetwork(startEvent:SerializeUnitsForNetwork(), {
    level = startEvent.level,
    difficulty = startEvent.difficulty,
    playerCount = 2,
})
assertStatsEqual(snapshotReceiver[3].stats, startEvent.units[3].stats, "rejoin snapshot hydration uses the active Event level")

local selectedPetStats = {
    { statRef = "test:pet-power", value = 42, currentValue = 42 },
}
local selectedPetEvent = Event:New({
    id = "selected-pet-event",
    active = true,
    level = 1,
    units = {
        EventUnit:New({
            eventID = 1,
            isPlayer = true,
            name = "Pet Owner",
            ownerID = "Pet Owner",
            petRef = "test:pet-wolf",
            petStats = selectedPetStats,
        }),
    },
})
local selectedPetFields = splitPreservingEmpty(
    splitPreservingEmpty(selectedPetEvent:SerializeUnitsForNetwork(), string.char(30))[1],
    string.char(29)
)
assertEqual(selectedPetFields[16], "test:pet-wolf", "event snapshot carries the selected pet identity")
assertEqual(selectedPetFields[33] ~= "", true, "event snapshot carries selected pet runtime stats")
assertEqual(selectedPetFields[34], "0", "event snapshot carries the pet-role marker extension")
local selectedPetSnapshot = Event.DeserializeUnitsFromNetwork(selectedPetEvent:SerializeUnitsForNetwork(), {
    level = 1,
    difficulty = "normal",
    playerCount = 1,
})
assertEqual(selectedPetSnapshot[1].petRef, "test:pet-wolf", "rejoin snapshot preserves selected pet identity")
assertStatsEqual(selectedPetSnapshot[1].petStats, selectedPetStats, "rejoin snapshot preserves selected pet runtime stats")
local selectedPetDelta = Event.SerializeUnitDeltaBatchForNetwork({
    { operation = "upsert", eventID = 1, unit = selectedPetEvent.units[1] },
})
local selectedPetDeltaFields = splitPreservingEmpty(
    splitPreservingEmpty(selectedPetDelta, string.char(23))[1],
    string.char(22)
)
local selectedPetDeltaUnitFields = splitPreservingEmpty(selectedPetDeltaFields[3], string.char(29))
assertEqual(selectedPetDeltaUnitFields[16], "test:pet-wolf", "event delta carries the selected pet identity")
local selectedPetDeltaEntries = Event.DeserializeUnitDeltaBatchFromNetwork(selectedPetDelta)
assertEqual(selectedPetDeltaEntries[1].unit.petRef, "test:pet-wolf", "event delta preserves selected pet identity")
assertStatsEqual(selectedPetDeltaEntries[1].unit.petStats, selectedPetStats, "event delta preserves selected pet runtime stats")

local genericSummon = EventUnit:New({
    eventID = 2,
    name = "Spell Guardian",
    registryID = "test:npc",
    ownerID = "Pet Owner",
    controllerID = 1,
    summonedByEventID = 1,
    team = 1,
})
local genericSummonEvent = Event:New({
    id = "generic-summon-event",
    active = true,
    level = 1,
    difficulty = "normal",
    units = {
        EventUnit:New({ eventID = 1, isPlayer = true, name = "Pet Owner" }),
        genericSummon,
    },
})
local genericSummonSnapshot = Event.DeserializeUnitsFromNetwork(genericSummonEvent:SerializeUnitsForNetwork(), {
    level = 1,
    difficulty = "normal",
    playerCount = 1,
})
assertEqual(genericSummonSnapshot[2].petRef, nil, "generic summon snapshots omit profile pet identity")
assertEqual(tonumber(genericSummonSnapshot[2].controllerID), 1, "generic summon snapshots preserve controller identity")
assertEqual(genericSummonSnapshot[2].summonedByEventID, 1, "generic summon snapshots preserve caster identity")

local authoredPet = EventUnit:New({
    eventID = 4,
    name = "Authored Pet",
    registryID = "test:npc",
    ownerID = "Pet Owner",
    controllerID = 1,
    summonedByEventID = 1,
    isPet = true,
})
local authoredPetEvent = Event:New({
    id = "authored-pet-network-event",
    active = true,
    level = 1,
    difficulty = "normal",
    units = {
        EventUnit:New({ eventID = 1, isPlayer = true, name = "Pet Owner" }),
        authoredPet,
    },
})
local authoredPetSnapshot = Event.DeserializeUnitsFromNetwork(authoredPetEvent:SerializeUnitsForNetwork(), {
    level = 1,
    difficulty = "normal",
    playerCount = 1,
})
assertEqual(authoredPetSnapshot[2].isPet, true, "authored pet snapshots preserve the pet-role marker")
local authoredPetFields = splitPreservingEmpty(
    splitPreservingEmpty(authoredPetEvent:SerializeUnitsForNetwork(), string.char(30))[2],
    string.char(29)
)
assertEqual(authoredPetFields[34], "1", "authored pet snapshots serialize the pet-role marker extension")
local authoredPetDelta = Event.SerializeUnitDeltaBatchForNetwork({
    { operation = "upsert", eventID = 4, unit = authoredPet },
}, { level = 1, difficulty = "normal", playerCount = 1 })
local authoredPetDeltaEntries = Event.DeserializeUnitDeltaBatchFromNetwork(authoredPetDelta)
assertEqual(authoredPetDeltaEntries[1].unit.isPet, true, "authored pet deltas preserve the pet-role marker")
local genericSummonDelta = Event.SerializeUnitDeltaBatchForNetwork({
    { operation = "upsert", eventID = 2, unit = genericSummon },
}, { level = 1, difficulty = "normal", playerCount = 1 })
local genericSummonDeltaFields = splitPreservingEmpty(
    splitPreservingEmpty(genericSummonDelta, string.char(23))[1],
    string.char(22)
)
local genericSummonDeltaUnitFields = splitPreservingEmpty(genericSummonDeltaFields[3], string.char(29))
assertEqual(genericSummonDeltaUnitFields[16], "", "generic summon deltas omit profile pet identity")
local genericSummonDeltaEntries = Event.DeserializeUnitDeltaBatchFromNetwork(genericSummonDelta)
assertEqual(genericSummonDeltaEntries[1].unit.petRef, nil, "generic summon deltas preserve the absence of pet identity")
assertEqual(tonumber(genericSummonDeltaEntries[1].unit.controllerID), 1, "generic summon deltas preserve controller identity")
assertEqual(genericSummonDeltaEntries[1].unit.summonedByEventID, 1, "generic summon deltas preserve caster identity")

local nativeHydrate = EventUnit.HydrateNetworkUnit
local receivedOptions
EventUnit.HydrateNetworkUnit = function(unit, options)
    receivedOptions = options
    return unit
end
Event.DeserializeUnitsFromNetwork(startEvent:SerializeUnitsForNetwork(), {
    level = 42,
    playerCount = 7,
    difficulty = "mythic",
    contextMarker = "preserved-through-wrappers",
})
EventUnit.HydrateNetworkUnit = nativeHydrate
assertEqual(receivedOptions.level, 42, "network wrapper preserves Event level context")
assertEqual(receivedOptions.playerCount, 7, "network wrapper preserves explicit player count")
assertEqual(receivedOptions.difficulty, "mythic", "network wrapper preserves difficulty context")
assertEqual(receivedOptions.contextMarker, "preserved-through-wrappers", "network wrapper preserves additional options")

local summon = materializeNpc(4, 60, 1)
summon.summonedByEventID = 1
summon.appearanceIndex = 1
local deltaOptions = { level = 60, difficulty = "normal", playerCount = 2 }
local deltaPayload = Event.SerializeUnitDeltaBatchForNetwork({
    { operation = "upsert", eventID = 4, unit = summon },
}, deltaOptions)
local deltaFields = splitPreservingEmpty(splitPreservingEmpty(deltaPayload, string.char(23))[1], string.char(22))
local upsertUnitFields = splitPreservingEmpty(deltaFields[3], string.char(29))
assertEqual(upsertUnitFields[15], "", "live preset upsert omits derived stat rows")
assertEqual(upsertUnitFields[20], "inherit", "live preset upsert carries inherited stat mode")
assertEqual(upsertUnitFields[24], "1", "live upsert preserves preset identity at field 24")
assertEqual(upsertUnitFields[25], "1", "live upsert preserves appearance identity at field 25")
assertEqual(upsertUnitFields[30], "0", "primary-resource wrapper keeps its metadata after variant identity")
assertEqual(upsertUnitFields[32], "0", "spell-equipment wrapper keeps NPC-mode metadata after primary metadata")
local decodedDelta = Event.DeserializeUnitDeltaBatchFromNetwork(deltaPayload, deltaOptions)
local hydratedSummon = EventUnit.HydrateNetworkUnit(decodedDelta[1].unit, deltaOptions)
assertStatsEqual(hydratedSummon.stats, summon.stats, "live summon upsert uses current Event level and preset")
assertClose(findRow(hydratedSummon.resources, "resourceRef", "test:health").maxValue,
    findRow(summon.resources, "resourceRef", "test:health").maxValue, "live summon upsert preserves preset resources")
assertEqual(hydratedSummon.registryID, summon.registryID, "live summon upsert preserves registry identity")
assertEqual(hydratedSummon.presetIndex, summon.presetIndex, "live summon upsert preserves preset identity")
assertEqual(hydratedSummon.appearanceIndex, summon.appearanceIndex, "live summon upsert preserves appearance identity")
assertEqual(hydratedSummon:GetResolvedAppearance().displayId, 123456, "live summon upsert resolves selected appearance")

local liveUnit = materializeNpc(4, 60, 1)
liveUnit.appearanceIndex = 1
local originalLiveUnit = liveUnit
assertEqual(liveUnit:MergeLiveNetworkUpdate(hydratedSummon), true, "live delta merges into the existing EventUnit")
assertEqual(liveUnit, originalLiveUnit, "live delta keeps the EventUnit object used by the portrait")
assertEqual(liveUnit.registryID, "test:npc", "merged unit retains registry identity")
assertEqual(liveUnit.presetIndex, 1, "merged unit retains preset identity")
assertEqual(liveUnit.appearanceIndex, 1, "merged unit retains appearance identity")
assertEqual(liveUnit:GetResolvedAppearance().displayId, 123456, "merged unit remains renderable as the selected appearance")

local incompleteLegacyUpdate = EventUnit:New({ eventID = 4, registryID = "test:npc", resources = liveUnit.resources })
assertEqual(liveUnit:MergeLiveNetworkUpdate(incompleteLegacyUpdate), true, "incomplete legacy live update is accepted without replacing identity")
assertEqual(liveUnit.presetIndex, 1, "incomplete live update cannot erase preset identity")
assertEqual(liveUnit.appearanceIndex, 1, "incomplete live update cannot erase appearance identity")
assertEqual(liveUnit:GetResolvedAppearance().displayId, 123456, "incomplete live update remains renderable")

dataset = { id = "test", name = "Network test", units = {} }
local missingOk, missingError = pcall(function()
    EventUnit.HydrateNetworkUnit(EventUnit:New({
        registryID = "test:npc",
        _networkStatMode = "inherit",
    }), { level = 60, playerCount = 2, difficulty = "normal" })
end)
assertEqual(missingOk, false, "missing local Unit definitions fail inherited hydration")
assert(tostring(missingError):find("activated Unit definition", 1, true), "missing local Unit error identifies the failure")

print("EventUnitNetworkBaselineTest passed")
