local _, Addon = ...

Addon = type(Addon) == "table" and Addon or {}
Addon.Client = Addon.Client or {}

local Client = Addon.Client
local SpellEvaluator = Client.AutopilotSpellEvaluator or {}

Client.AutopilotActionEconomy = Client.AutopilotActionEconomy or {}
local ActionEconomy = Client.AutopilotActionEconomy

local COOLDOWN_CHANNEL_MIN_ID = 1
local COOLDOWN_CHANNEL_MAX_ID = 10

local function normalizeNonNegative(value)
    return math.max(0, tonumber(value) or 0)
end

local function normalizePositiveTurnCount(value)
    local turns = tonumber(value)
    if turns == nil or turns <= 0 then
        return nil
    end
    return math.max(1, math.floor(turns))
end

local function normalizeRef(value)
    local ref = tostring(value or "")
    return ref ~= "" and ref or nil
end

local function normalizeCooldownGroup(value)
    local group = tostring(value or "")
    return group ~= "" and group or nil
end

local function normalizeCooldownChannelId(value)
    local channelId = tonumber(value)
    if channelId == nil
        or channelId % 1 ~= 0
        or channelId < COOLDOWN_CHANNEL_MIN_ID
        or channelId > COOLDOWN_CHANNEL_MAX_ID
    then
        return nil
    end
    return channelId
end

local function normalizeCooldownChannelName(value)
    local name = tostring(value or ""):gsub("^%s+", ""):gsub("%s+$", "")
    return name ~= "" and name or nil
end

local function copyResourceMap(values)
    local copied = {}
    for resourceRef, amount in pairs(type(values) == "table" and values or {}) do
        local ref = normalizeRef(resourceRef)
        local numericAmount = normalizeNonNegative(amount)
        if ref and numericAmount > 0 then
            copied[ref] = (copied[ref] or 0) + numericAmount
        end
    end
    return copied
end

local function copyAvailableResourceMap(values)
    local copied = {}
    for resourceRef, amount in pairs(type(values) == "table" and values or {}) do
        local ref = normalizeRef(resourceRef)
        if ref and tonumber(amount) ~= nil then
            copied[ref] = normalizeNonNegative(amount)
        end
    end
    return copied
end

local function copyMap(values)
    local copied = {}
    for key, value in pairs(type(values) == "table" and values or {}) do
        copied[key] = value
    end
    return copied
end

local function getComparable(entry)
    if type(entry) ~= "table" then
        return nil
    end
    return type(entry.candidate) == "table" and entry.candidate or entry
end

local function isUsefulCandidate(candidate)
    return type(candidate) == "table"
        and (
            candidate.urgentHealing == true
            or candidate.urgentInterrupt == true
            or normalizeNonNegative(candidate.totalUtility or candidate.utility) > 0
        )
end

local function compareEntries(left, right, compareCandidates)
    local comparator = type(compareCandidates) == "function"
        and compareCandidates
        or type(SpellEvaluator.CompareCandidates) == "function" and SpellEvaluator.CompareCandidates
        or nil
    if type(comparator) ~= "function" then
        return nil
    end

    local compared = tonumber(comparator(getComparable(left), getComparable(right))) or 0
    if compared ~= 0 then
        return compared > 0 and 1 or -1
    end

    local leftRef = tostring(left and left.spellRef or "")
    local rightRef = tostring(right and right.spellRef or "")
    if leftRef ~= rightRef then
        return leftRef < rightRef and 1 or -1
    end

    local leftIndex = math.max(0, math.floor(tonumber(left and left.inputIndex) or 0))
    local rightIndex = math.max(0, math.floor(tonumber(right and right.inputIndex) or 0))
    if leftIndex ~= rightIndex then
        return leftIndex < rightIndex and 1 or -1
    end
    return 0
end

function ActionEconomy.CreateInput(candidate, activationMetadata)
    if type(candidate) ~= "table" then
        return nil, "candidate-unavailable"
    end
    local metadata = type(activationMetadata) == "table" and activationMetadata or {}
    local activationSnapshot = type(metadata.activationSnapshot) == "table"
        and metadata.activationSnapshot
        or type(candidate.activationSnapshot) == "table" and candidate.activationSnapshot
        or nil

    local canCast = metadata.canCast
    if canCast == nil and type(activationSnapshot) == "table" then
        canCast = activationSnapshot.canCast
    end

    local spellRef = normalizeRef(metadata.spellRef or candidate.spellRef)
    if not spellRef then
        return nil, "spell-ref-unavailable"
    end

    local cooldownChannelId = normalizeCooldownChannelId(
        metadata.cooldownChannelId
            or type(activationSnapshot) == "table" and activationSnapshot.cooldownChannelId
    )
    local cooldownChannelTriggersGCD = metadata.cooldownChannelTriggersGCD
    if cooldownChannelTriggersGCD == nil and type(activationSnapshot) == "table" then
        cooldownChannelTriggersGCD = activationSnapshot.cooldownChannelTriggersGCD
    end
    if type(cooldownChannelTriggersGCD) ~= "boolean" then
        cooldownChannelTriggersGCD = nil
    end
    local cooldownChannelConfigured = metadata.cooldownChannelConfigured
    if cooldownChannelConfigured == nil and type(activationSnapshot) == "table" then
        cooldownChannelConfigured = activationSnapshot.cooldownChannelId ~= nil
            and type(activationSnapshot.cooldownChannelTriggersGCD) == "boolean"
            and normalizeCooldownChannelName(activationSnapshot.cooldownChannelName) ~= nil
    end
    if type(cooldownChannelConfigured) ~= "boolean" then
        cooldownChannelConfigured = cooldownChannelId ~= nil and cooldownChannelTriggersGCD ~= nil
    end

    return {
        candidate = candidate,
        spellRef = spellRef,
        canCast = canCast == true,
        persistentCastTurns = normalizePositiveTurnCount(metadata.persistentCastTurns),
        cooldownChannelId = cooldownChannelId,
        cooldownChannelName = normalizeCooldownChannelName(
            metadata.cooldownChannelName
                or type(activationSnapshot) == "table" and activationSnapshot.cooldownChannelName
        ),
        cooldownChannelTriggersGCD = cooldownChannelTriggersGCD,
        cooldownChannelConfigured = cooldownChannelConfigured == true,
        cooldownChannelReason = tostring(metadata.cooldownChannelReason or ""),
        cooldownGroup = normalizeCooldownGroup(metadata.cooldownGroup),
        resourceCommitments = copyResourceMap(metadata.resourceCommitments),
        inputIndex = 0,
    }
end

function ActionEconomy.ClassifyInput(entry)
    if type(entry) ~= "table" then
        return nil, "candidate-unavailable"
    end
    if normalizeRef(entry.spellRef) == nil then
        return nil, "spell-ref-unavailable"
    end
    if entry.cooldownChannelConfigured ~= true
        or normalizeCooldownChannelId(entry.cooldownChannelId) == nil
        or type(entry.cooldownChannelTriggersGCD) ~= "boolean"
    then
        return nil, entry.cooldownChannelReason ~= "" and entry.cooldownChannelReason or "invalid-cooldown-channel"
    end
    if entry.canCast ~= true then
        return nil, "illegal-activation"
    end
    if not isUsefulCandidate(getComparable(entry)) then
        return nil, "not-useful"
    end

    if normalizePositiveTurnCount(entry.persistentCastTurns) ~= nil then
        return "terminal"
    end

    return "action"
end

function ActionEconomy.CreateLedger(availableResources)
    return {
        availableResources = copyAvailableResourceMap(availableResources),
        reservedResources = {},
        reservedCooldownGroups = {},
        reservedSpellRefs = {},
        reservedCooldownChannels = {},
        terminalCastCommitted = false,
    }
end

function ActionEconomy.CloneLedger(ledger)
    local source = type(ledger) == "table" and ledger or {}
    return {
        availableResources = copyAvailableResourceMap(source.availableResources),
        reservedResources = copyResourceMap(source.reservedResources),
        reservedCooldownGroups = copyMap(source.reservedCooldownGroups),
        reservedSpellRefs = copyMap(source.reservedSpellRefs),
        reservedCooldownChannels = copyMap(source.reservedCooldownChannels),
        terminalCastCommitted = source.terminalCastCommitted == true,
    }
end

local function reserveEntry(ledger, entry)
    ledger.reservedSpellRefs[entry.spellRef] = true

    for resourceRef, amount in pairs(entry.resourceCommitments or {}) do
        ledger.reservedResources[resourceRef] = normalizeNonNegative(ledger.reservedResources[resourceRef])
            + normalizeNonNegative(amount)
    end

    if entry.cooldownGroup then
        ledger.reservedCooldownGroups[entry.cooldownGroup] = entry.spellRef
    end
    if entry.cooldownChannelTriggersGCD == true then
        ledger.reservedCooldownChannels[entry.cooldownChannelId] = entry.spellRef
    end
    if entry.actionClass == "terminal" then
        ledger.terminalCastCommitted = true
    end
end

local function resourceConflictReason(ledger, entry)
    for resourceRef, amount in pairs(entry.resourceCommitments or {}) do
        local existing = normalizeNonNegative(ledger.reservedResources[resourceRef])
        local required = normalizeNonNegative(amount)
        if existing > 0 and required > 0 then
            local available = tonumber(ledger.availableResources[resourceRef])
            if available == nil then
                return "resource-capacity-unavailable:" .. resourceRef
            end
            if existing + required > math.max(0, available) then
                return "resource-conflict:" .. resourceRef
            end
        end
    end
    return nil
end

function ActionEconomy.CanReserve(ledger, entry)
    if type(ledger) ~= "table" or type(entry) ~= "table" then
        return false, "reservation-context-unavailable"
    end
    local actionClass, classReason = ActionEconomy.ClassifyInput(entry)
    if not actionClass then
        return false, classReason or "unclassified"
    end
    if ledger.reservedSpellRefs[entry.spellRef] == true then
        return false, "spell-already-reserved"
    end
    if entry.cooldownGroup and ledger.reservedCooldownGroups[entry.cooldownGroup] ~= nil then
        return false, "cooldown-group-conflict"
    end
    if entry.cooldownChannelTriggersGCD == true
        and ledger.reservedCooldownChannels[entry.cooldownChannelId] ~= nil
    then
        return false, "cooldown-channel-conflict"
    end
    if actionClass == "terminal" and ledger.terminalCastCommitted == true then
        return false, "terminal-cast-conflict"
    end

    local resourceReason = resourceConflictReason(ledger, entry)
    if resourceReason then
        return false, resourceReason
    end
    return true
end

local function appendRejected(rejected, entry, reason)
    rejected[#rejected + 1] = {
        spellRef = tostring(type(entry) == "table" and entry.spellRef or ""),
        inputIndex = math.max(0, math.floor(tonumber(type(entry) == "table" and entry.inputIndex or 0) or 0)),
        reason = tostring(reason or "rejected"),
    }
end

local function sortEntries(entries, compareCandidates)
    if #entries <= 1 then
        return true
    end
    local comparatorAvailable = true
    table.sort(entries, function(left, right)
        local compared = compareEntries(left, right, compareCandidates)
        if compared == nil then
            comparatorAvailable = false
            return false
        end
        return compared > 0
    end)
    return comparatorAvailable
end

local function buildSequenceResult(status, reason, ledger, rejected, actions, selectedByChannel, terminal)
    local selectedActions = type(actions) == "table" and actions or {}
    local selectedTerminal = type(terminal) == "table" and terminal or nil
    local regularActions = {}
    for index = 1, #selectedActions do
        if selectedActions[index] ~= selectedTerminal then
            regularActions[#regularActions + 1] = selectedActions[index]
        end
    end

    return {
        status = status,
        reason = reason,
        actions = selectedActions,
        selectedByChannel = copyMap(selectedByChannel),
        terminal = selectedTerminal,
        ledger = ActionEconomy.CloneLedger(ledger),
        rejected = rejected or {},
        -- Compatibility views. `actions`, `selectedByChannel` and `terminal`
        -- are authoritative for channel-aware planning.
        auxiliaries = regularActions,
        main = selectedTerminal,
    }
end

function ActionEconomy.BuildSequence(inputs, options)
    options = type(options) == "table" and options or {}
    local compareCandidates = options.compareCandidates
    local ledger = ActionEconomy.CreateLedger(options.availableResources)
    local entries = {}
    local rejected = {}

    for index = 1, #(inputs or {}) do
        local source = inputs[index]
        local entry = nil
        local reason = nil
        if type(source) == "table" and type(source.candidate) == "table" and source.spellRef ~= nil then
            entry = {
                candidate = source.candidate,
                spellRef = normalizeRef(source.spellRef),
                canCast = source.canCast == true,
                persistentCastTurns = normalizePositiveTurnCount(source.persistentCastTurns),
                cooldownChannelId = normalizeCooldownChannelId(source.cooldownChannelId),
                cooldownChannelName = normalizeCooldownChannelName(source.cooldownChannelName),
                cooldownChannelTriggersGCD = type(source.cooldownChannelTriggersGCD) == "boolean"
                    and source.cooldownChannelTriggersGCD
                    or nil,
                cooldownChannelConfigured = type(source.cooldownChannelConfigured) == "boolean"
                    and source.cooldownChannelConfigured
                    or (normalizeCooldownChannelId(source.cooldownChannelId) ~= nil
                        and type(source.cooldownChannelTriggersGCD) == "boolean"),
                cooldownChannelReason = tostring(source.cooldownChannelReason or ""),
                cooldownGroup = normalizeCooldownGroup(source.cooldownGroup),
                resourceCommitments = copyResourceMap(source.resourceCommitments),
                inputIndex = index,
            }
        elseif type(source) == "table" then
            entry, reason = ActionEconomy.CreateInput(source, source.actionEconomy)
            if entry then
                entry.inputIndex = index
            end
        end

        if type(entry) ~= "table" then
            appendRejected(rejected, source, reason or "candidate-unavailable")
        else
            local actionClass, classReason = ActionEconomy.ClassifyInput(entry)
            entry.actionClass = actionClass
            if actionClass then
                entries[#entries + 1] = entry
            else
                appendRejected(rejected, entry, classReason or "unclassified")
            end
        end
    end

    if sortEntries(entries, compareCandidates) ~= true then
        return buildSequenceResult("failed", "comparator-unavailable", ledger, rejected, {}, {}, nil)
    end

    local selectedActions = {}
    local selectedByChannel = {}
    local terminal = nil
    for index = 1, #entries do
        local entry = entries[index]
        local compatible, compatibilityReason = ActionEconomy.CanReserve(ledger, entry)
        if compatible then
            reserveEntry(ledger, entry)
            if entry.actionClass == "terminal" then
                terminal = entry
            else
                selectedActions[#selectedActions + 1] = entry
            end
            if entry.cooldownChannelTriggersGCD == true then
                selectedByChannel[entry.cooldownChannelId] = entry.spellRef
            end
        else
            appendRejected(rejected, entry, compatibilityReason)
        end
    end

    if terminal then
        selectedActions[#selectedActions + 1] = terminal
    end

    return buildSequenceResult("ready", nil, ledger, rejected, selectedActions, selectedByChannel, terminal)
end

return ActionEconomy
