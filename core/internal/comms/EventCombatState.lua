local _, Addon = ...

Addon.Internal = Addon.Internal or {}
Addon.Internal.Comms = Addon.Internal.Comms or {}
Addon.Internal.Comms.EventCombatState = Addon.Internal.Comms.EventCombatState or {}

local Comms = Addon.Internal.Comms
local EventSync = Comms.EventSync or {}
local State = Comms.EventCombatState
local Operations = Comms.Operations or {}

local function normalizeInteger(value, minimum)
    local numeric = tonumber(value)
    if numeric == nil then
        return nil
    end
    numeric = math.floor(numeric)
    if minimum ~= nil and numeric < minimum then
        return nil
    end
    return numeric
end

local function cloneValue(value, seen)
    if type(value) ~= "table" then
        return value
    end
    seen = seen or {}
    if seen[value] then
        return nil
    end
    seen[value] = true
    local copy = {}
    for key, nested in pairs(value) do
        copy[cloneValue(key, seen)] = cloneValue(nested, seen)
    end
    seen[value] = nil
    return copy
end

State.CloneValue = cloneValue

local function isArray(value)
    if type(value) ~= "table" then
        return false, 0
    end
    local count = 0
    local maxIndex = 0
    for key in pairs(value) do
        if type(key) ~= "number" or key <= 0 or math.floor(key) ~= key then
            return false, 0
        end
        count = count + 1
        maxIndex = math.max(maxIndex, key)
    end
    return maxIndex == count, maxIndex
end

local function encodeValue(value, seen)
    local valueType = type(value)
    if value == nil then
        return EventSync.EncodeFields({ "nil" })
    end
    if valueType == "boolean" then
        return EventSync.EncodeFields({ "bool", value and "1" or "0" })
    end
    if valueType == "number" then
        return EventSync.EncodeFields({ "number", tostring(value) })
    end
    if valueType == "string" then
        return EventSync.EncodeFields({ "string", value })
    end
    if valueType ~= "table" then
        return nil, "unsupported-value-type"
    end

    seen = seen or {}
    if seen[value] then
        return nil, "cyclic-value"
    end
    seen[value] = true

    local array, arrayLength = isArray(value)
    local fields = { array and "array" or "map" }
    if array then
        fields[#fields + 1] = tostring(arrayLength)
        for index = 1, arrayLength do
            local encoded, reason = encodeValue(value[index], seen)
            if not encoded then
                seen[value] = nil
                return nil, reason
            end
            fields[#fields + 1] = encoded
        end
    else
        local encodedEntries = {}
        for key, nested in pairs(value) do
            local encodedKey, keyReason = encodeValue(key, seen)
            if not encodedKey then
                seen[value] = nil
                return nil, keyReason
            end
            local encodedNested, nestedReason = encodeValue(nested, seen)
            if not encodedNested then
                seen[value] = nil
                return nil, nestedReason
            end
            encodedEntries[#encodedEntries + 1] = {
                key = encodedKey,
                value = encodedNested,
            }
        end
        table.sort(encodedEntries, function(left, right)
            return left.key < right.key
        end)
        fields[#fields + 1] = tostring(#encodedEntries)
        for index = 1, #encodedEntries do
            fields[#fields + 1] = encodedEntries[index].key
            fields[#fields + 1] = encodedEntries[index].value
        end
    end

    seen[value] = nil
    return EventSync.EncodeFields(fields)
end

local function decodeValue(payload)
    local fields, reason = EventSync.DecodeFields(payload)
    if not fields then
        return nil, reason
    end
    local kind = fields[1]
    if kind == "nil" then
        return nil, nil, true
    end
    if kind == "bool" and #fields == 2 then
        return fields[2] == "1", nil, true
    end
    if kind == "number" and #fields == 2 then
        local numeric = tonumber(fields[2])
        if numeric == nil then
            return nil, "invalid-number", false
        end
        return numeric, nil, true
    end
    if kind == "string" and #fields == 2 then
        return fields[2], nil, true
    end
    if kind ~= "array" and kind ~= "map" then
        return nil, "invalid-value-kind", false
    end

    local count = normalizeInteger(fields[2], 0)
    if count == nil then
        return nil, "invalid-value-count", false
    end
    local value = {}
    if kind == "array" then
        if #fields ~= count + 2 then
            return nil, "invalid-array-count", false
        end
        for index = 1, count do
            local nested, nestedReason, ok = decodeValue(fields[index + 2])
            if ok ~= true then
                return nil, nestedReason, false
            end
            value[index] = nested
        end
        return value, nil, true
    end

    if #fields ~= (count * 2) + 2 then
        return nil, "invalid-map-count", false
    end
    for index = 1, count do
        local key, keyReason, keyOk = decodeValue(fields[(index * 2) + 1])
        if keyOk ~= true or key == nil then
            return nil, keyReason or "invalid-map-key", false
        end
        local nested, nestedReason, nestedOk = decodeValue(fields[(index * 2) + 2])
        if nestedOk ~= true then
            return nil, nestedReason, false
        end
        value[key] = nested
    end
    return value, nil, true
end

function State.SerializeValue(value)
    return encodeValue(value)
end

function State.DeserializeValue(payload)
    local value, reason, ok = decodeValue(payload)
    if ok ~= true then
        return nil, reason
    end
    return value, nil
end

local function cloneNumberArray(values)
    local cloned = {}
    for index = 1, #(values or {}) do
        local numeric = tonumber(values[index])
        if numeric ~= nil then
            cloned[#cloned + 1] = numeric
        end
    end
    return cloned
end

function State.CloneAuraRecord(entry)
    if type(entry) ~= "table" then
        return nil
    end
    local auraRef = tostring(entry.auraRef or "")
    local casterEventId = normalizeInteger(entry.casterEventId, 1)
    local targetEventId = normalizeInteger(entry.targetEventId, 1)
    if auraRef == "" or casterEventId == nil or targetEventId == nil then
        return nil
    end
    return {
        auraKey = tostring(entry.auraKey or ""),
        auraRef = auraRef,
        datasetId = tostring(entry.datasetId or ""),
        casterEventId = casterEventId,
        targetEventId = targetEventId,
        stacks = math.max(0, normalizeInteger(entry.stacks, 0) or 0),
        turnsRemaining = math.max(0, normalizeInteger(entry.turnsRemaining, 0) or 0),
        powerLevel = tonumber(entry.powerLevel) or 0,
        stackBehavior = tostring(entry.stackBehavior or "refresh_duration"),
        maxStacks = math.max(1, normalizeInteger(entry.maxStacks, 1) or 1),
        lastAdvancedOwnerTurnNumber = normalizeInteger(entry.lastAdvancedOwnerTurnNumber, 0),
        stackTurns = cloneNumberArray(entry.stackTurns),
    }
end

function State.CloneAuraRecords(records)
    local cloned = {}
    for index = 1, #(records or {}) do
        local record = State.CloneAuraRecord(records[index])
        if record and record.stacks > 0 then
            cloned[#cloned + 1] = record
        end
    end
    table.sort(cloned, function(left, right)
        if left.targetEventId ~= right.targetEventId then
            return left.targetEventId < right.targetEventId
        end
        if left.casterEventId ~= right.casterEventId then
            return left.casterEventId < right.casterEventId
        end
        return left.auraRef < right.auraRef
    end)
    return cloned
end

function State.CloneCastEntry(entry)
    if type(entry) ~= "table" then
        return nil
    end
    local casterEventId = normalizeInteger(entry.casterEventId, 1)
    local spellRef = tostring(entry.spellRef or "")
    if casterEventId == nil or spellRef == "" then
        return nil
    end
    return {
        spellRef = spellRef,
        spellName = tostring(entry.spellName or ""),
        authorityType = tostring(entry.authorityType or ""),
        casterEventId = casterEventId,
        turnsTotal = math.max(1, normalizeInteger(entry.turnsTotal, 1) or 1),
        turnsElapsed = math.max(0, normalizeInteger(entry.turnsElapsed, 0) or 0),
        turnsRemaining = math.max(0, normalizeInteger(entry.turnsRemaining, 0) or 0),
        startedOnTurnNumber = math.max(1, normalizeInteger(entry.startedOnTurnNumber, 1) or 1),
        completeOnTurnNumber = math.max(0, normalizeInteger(entry.completeOnTurnNumber, 0) or 0),
        lastAdvancedTurnNumber = math.max(1, normalizeInteger(entry.lastAdvancedTurnNumber, 1) or 1),
        targetSelections = cloneValue(entry.targetSelections),
        targetSelectionOrder = cloneValue(entry.targetSelectionOrder),
        targetEventIds = cloneNumberArray(entry.targetEventIds),
        focusedTargetEventId = normalizeInteger(entry.focusedTargetEventId, 0) or 0,
        targetPolicy = cloneValue(entry.targetPolicy),
        resolvedStartCostAmounts = cloneValue(entry.resolvedStartCostAmounts),
    }
end

function State.CloneCastBucket(bucket)
    local cloned = {}
    for casterEventId, entry in pairs(type(bucket) == "table" and bucket or {}) do
        local record = State.CloneCastEntry(entry)
        if record then
            record.casterEventId = normalizeInteger(casterEventId, 1) or record.casterEventId
            cloned[record.casterEventId] = record
        end
    end
    return cloned
end

function State.CloneCooldownSpellState(entry)
    if type(entry) ~= "table" then
        return nil
    end
    return {
        remainingTurns = math.max(0, normalizeInteger(entry.remainingTurns, 0) or 0),
        lockoutRemainingTurns = math.max(0, normalizeInteger(entry.lockoutRemainingTurns, 0) or 0),
        currentCharges = entry.currentCharges ~= nil and math.max(0, normalizeInteger(entry.currentCharges, 0) or 0) or nil,
        maxCharges = entry.maxCharges ~= nil and math.max(1, normalizeInteger(entry.maxCharges, 1) or 1) or nil,
        usesCharges = entry.usesCharges == true,
        cooldownTurns = entry.cooldownTurns ~= nil and math.max(1, normalizeInteger(entry.cooldownTurns, 1) or 1) or nil,
    }
end

function State.CloneCooldownUnitState(unitState)
    if type(unitState) ~= "table" then
        return nil
    end
    local cloned = {
        globalCooldownRemaining = math.max(0, normalizeInteger(unitState.globalCooldownRemaining, 0) or 0),
        lastAdvancedTurnNumber = math.max(0, normalizeInteger(unitState.lastAdvancedTurnNumber, 0) or 0),
        spells = {},
    }
    for spellRef, entry in pairs(unitState.spells or {}) do
        local spellState = State.CloneCooldownSpellState(entry)
        if spellState then
            cloned.spells[tostring(spellRef)] = spellState
        end
    end
    return cloned
end

function State.CloneCooldownBucket(bucket)
    local cloned = {}
    for unitEventId, unitState in pairs(type(bucket) == "table" and bucket or {}) do
        local numericUnitEventId = normalizeInteger(unitEventId, 1)
        local record = State.CloneCooldownUnitState(unitState)
        if numericUnitEventId and record then
            cloned[numericUnitEventId] = record
        end
    end
    return cloned
end

function State.CloneDefensiveState(value)
    local source = type(value) == "table" and value or {}
    local uses = {}
    for identity, record in pairs(type(source.uses) == "table" and source.uses or {}) do
        if record == true then
            uses[tostring(identity)] = true
        elseif type(record) == "table" then
            uses[tostring(identity)] = cloneValue(record)
        end
    end
    return {
        eventId = tostring(source.eventId or ""),
        turnNumber = math.max(0, normalizeInteger(source.turnNumber, 0) or 0),
        uses = uses,
    }
end

function State.CloneRuntimeState(value)
    local source = type(value) == "table" and value or {}
    return {
        auras = State.CloneAuraRecords(source.auras or {}),
        spellcasts = State.CloneCastBucket(source.spellcasts or {}),
        cooldowns = State.CloneCooldownBucket(source.cooldowns or {}),
        defensiveReactions = State.CloneDefensiveState(source.defensiveReactions or {}),
    }
end

function State.SerializeRuntimeState(value)
    return State.SerializeValue(State.CloneRuntimeState(value))
end

function State.DeserializeRuntimeState(payload)
    local decoded, reason = State.DeserializeValue(payload)
    if type(decoded) ~= "table" then
        return nil, reason or "invalid-runtime-state"
    end
    return State.CloneRuntimeState(decoded), nil
end

function State.SerializeDomainProposal(domainPayload, runtimeState)
    local runtimePayload = ""
    if type(runtimeState) == "table" then
        runtimePayload = State.SerializeRuntimeState(runtimeState) or ""
    end
    return EventSync.EncodeFields({ tostring(domainPayload or ""), runtimePayload })
end

function State.DeserializeDomainProposal(payload)
    local fields, reason = EventSync.DecodeFields(payload)
    if not fields then
        return nil, reason
    end
    if #fields ~= 2 then
        return nil, "invalid-domain-proposal"
    end
    local runtimeState = nil
    if fields[2] ~= "" then
        runtimeState, reason = State.DeserializeRuntimeState(fields[2])
        if not runtimeState then
            return nil, reason
        end
    end
    return {
        domainPayload = fields[1],
        runtimeState = runtimeState,
    }, nil
end

function State.AdvanceCastBucket(bucket, currentTurnNumber, isCasterTurnOnTick)
    local currentTurn = math.max(1, normalizeInteger(currentTurnNumber, 1) or 1)
    local changed = false
    local completed = {}
    for casterEventId, entry in pairs(type(bucket) == "table" and bucket or {}) do
        local turnsTotal = math.max(1, normalizeInteger(entry and entry.turnsTotal, 1) or 1)
        local lastAdvanced = math.max(1, normalizeInteger(entry and (entry.lastAdvancedTurnNumber or entry.startedOnTurnNumber), 1) or currentTurn)
        local due = type(isCasterTurnOnTick) ~= "function" or isCasterTurnOnTick(casterEventId) == true
        if due and currentTurn > lastAdvanced then
            local elapsed = math.max(0, normalizeInteger(entry.turnsElapsed, 0) or 0) + (currentTurn - lastAdvanced)
            entry.turnsElapsed = math.min(turnsTotal, elapsed)
            entry.turnsRemaining = math.max(0, turnsTotal - entry.turnsElapsed)
            entry.lastAdvancedTurnNumber = currentTurn
            changed = true
            if entry.turnsElapsed >= turnsTotal then
                completed[#completed + 1] = tonumber(casterEventId) or casterEventId
            end
        end
    end
    return changed, completed
end

local function shouldClearCooldownSpellState(entry)
    if type(entry) ~= "table" then
        return true
    end
    local remaining = math.max(0, normalizeInteger(entry.remainingTurns, 0) or 0)
    local lockout = math.max(0, normalizeInteger(entry.lockoutRemainingTurns, 0) or 0)
    if entry.usesCharges == true then
        local current = math.max(0, normalizeInteger(entry.currentCharges, 0) or 0)
        local maximum = math.max(1, normalizeInteger(entry.maxCharges, 1) or 1)
        return current >= maximum and remaining <= 0 and lockout <= 0
    end
    return remaining <= 0 and lockout <= 0
end

local function advanceCooldownSpellState(entry, advancedTurns)
    local turns = math.max(0, normalizeInteger(advancedTurns, 0) or 0)
    if type(entry) ~= "table" or turns <= 0 then
        return false
    end
    local changed = false
    if entry.usesCharges == true then
        local current = math.max(0, normalizeInteger(entry.currentCharges, 0) or 0)
        local maximum = math.max(1, normalizeInteger(entry.maxCharges, 1) or 1)
        local cooldownTurns = math.max(1, normalizeInteger(entry.cooldownTurns, 1) or 1)
        local remaining = math.max(0, normalizeInteger(entry.remainingTurns, 0) or 0)
        for _ = 1, turns do
            if current >= maximum and remaining <= 0 then
                break
            end
            if remaining > 0 then
                remaining = remaining - 1
                changed = true
            end
            if remaining <= 0 and current < maximum then
                current = math.min(maximum, current + 1)
                changed = true
                remaining = current < maximum and cooldownTurns or 0
            end
        end
        entry.currentCharges = current
        entry.maxCharges = maximum
        entry.cooldownTurns = cooldownTurns
        entry.remainingTurns = remaining
    else
        local remaining = math.max(0, normalizeInteger(entry.remainingTurns, 0) or 0)
        local nextRemaining = math.max(0, remaining - turns)
        if nextRemaining ~= remaining then
            entry.remainingTurns = nextRemaining
            changed = true
        end
    end
    local lockout = math.max(0, normalizeInteger(entry.lockoutRemainingTurns, 0) or 0)
    local nextLockout = math.max(0, lockout - turns)
    if nextLockout ~= lockout then
        entry.lockoutRemainingTurns = nextLockout
        changed = true
    end
    return changed
end

function State.AdvanceCooldownBucket(bucket, currentTurnNumber, isCasterTurnOnTick)
    local currentTurn = math.max(1, normalizeInteger(currentTurnNumber, 1) or 1)
    local changed = false
    for unitEventId, unitState in pairs(type(bucket) == "table" and bucket or {}) do
        local due = type(isCasterTurnOnTick) ~= "function" or isCasterTurnOnTick(unitEventId) == true
        if due then
            local lastAdvanced = math.max(0, normalizeInteger(unitState.lastAdvancedTurnNumber, 0) or 0)
            if currentTurn > lastAdvanced then
                local advancedTurns = currentTurn - lastAdvanced
                unitState.lastAdvancedTurnNumber = currentTurn
                local gcd = math.max(0, normalizeInteger(unitState.globalCooldownRemaining, 0) or 0)
                local nextGcd = math.max(0, gcd - advancedTurns)
                if nextGcd ~= gcd then
                    unitState.globalCooldownRemaining = nextGcd
                    changed = true
                end
                for spellRef, entry in pairs(unitState.spells or {}) do
                    changed = advanceCooldownSpellState(entry, advancedTurns) or changed
                    if shouldClearCooldownSpellState(entry) then
                        unitState.spells[spellRef] = nil
                        changed = true
                    end
                end
            end
        end
        if math.max(0, normalizeInteger(unitState.globalCooldownRemaining, 0) or 0) <= 0 and next(unitState.spells or {}) == nil then
            bucket[unitEventId] = nil
        end
    end
    return changed
end

local function installOperation(opcode, key, name, handler)
    Operations.Opcodes = Operations.Opcodes or {}
    Operations.Registry = Operations.Registry or {}
    Operations.KeyIndex = Operations.KeyIndex or {}
    local existing = Operations.Opcodes[opcode]
    if type(existing) == "table" and tostring(existing.key or "") ~= key then
        error(("Event combat state opcode %d is already assigned to %s."):format(opcode, tostring(existing.key or "unknown")))
    end
    local definition = existing or {}
    definition.opcode = opcode
    definition.key = key
    definition.name = name
    definition["function"] = handler
    Operations.Opcodes[opcode] = definition
    Operations.Registry[opcode] = definition
    Operations.KeyIndex[string.upper(key)] = opcode
end

installOperation(33, "EVENT_RUNTIME_STATE", "event-runtime-state", function(arguments, sender, distribution, target, message)
    local client = Addon.Client
    if type(client) ~= "table" or type(client.HandleEventRuntimeState) ~= "function" then
        return false
    end
    return client:HandleEventRuntimeState(arguments, sender, distribution, target, message)
end)

installOperation(34, "EVENT_DEFENSIVE_USE", "event-defensive-use", function()
    -- Proposal-only domain. Direct unstamped dispatch is intentionally inert.
    return false
end)

return State
