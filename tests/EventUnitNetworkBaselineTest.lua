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
    Utils = { Common = { SplitPreservingEmpty = splitPreservingEmpty } },
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
power.value = power.value + 17
power.currentValue = power.currentValue + 17
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
