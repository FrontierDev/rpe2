local _, Addon = ...

Addon = type(Addon) == "table" and Addon or {}
Addon.Client = Addon.Client or {}

local Client = Addon.Client
local SpellEvaluator = Client.AutopilotSpellEvaluator or {}

Client.AutopilotActionEconomy = Client.AutopilotActionEconomy or {}
local ActionEconomy = Client.AutopilotActionEconomy

ActionEconomy.MAX_AUXILIARY_ACTIONS_PER_NPC = 2

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

    local usesGlobalCooldown = metadata.usesGlobalCooldown
    local ignoresGlobalCooldown = metadata.ignoresGlobalCooldown
    if type(usesGlobalCooldown) ~= "boolean" then
        usesGlobalCooldown = nil
    end
    if type(ignoresGlobalCooldown) ~= "boolean" then
        ignoresGlobalCooldown = nil
    end

    return {
        candidate = candidate,
        spellRef = spellRef,
        canCast = canCast == true,
        persistentCastTurns = normalizePositiveTurnCount(metadata.persistentCastTurns),
        usesGlobalCooldown = usesGlobalCooldown,
        ignoresGlobalCooldown = ignoresGlobalCooldown,
        cooldownGroup = normalizeCooldownGroup(metadata.cooldownGroup),
        resourceCommitments = copyResourceMap(metadata.resourceCommitments),
        inputIndex = 0,
    }
end

function ActionEconomy.ClassifyInput(entry)
    if type(entry) ~= "table" then
        return nil, "candidate-unavailable"
    end
    if entry.canCast ~= true then
        return nil, "illegal-activation"
    end
    if not isUsefulCandidate(getComparable(entry)) then
        return nil, "not-useful"
    end

    if type(entry.usesGlobalCooldown) ~= "boolean" or type(entry.ignoresGlobalCooldown) ~= "boolean" then
        return nil, "gcd-metadata-unavailable"
    end
    if entry.usesGlobalCooldown == true and entry.ignoresGlobalCooldown == true then
        return nil, "gcd-metadata-conflict"
    end

    if normalizePositiveTurnCount(entry.persistentCastTurns) ~= nil then
        return "terminal"
    end

    if entry.usesGlobalCooldown == true then
        return "primary"
    end
    return "auxiliary"
end

function ActionEconomy.CreateLedger(availableResources)
    return {
        availableResources = copyAvailableResourceMap(availableResources),
        reservedResources = {},
        reservedCooldownGroups = {},
        reservedSpellRefs = {},
        ignoreGCDCommitted = false,
        primaryGCDCommitted = false,
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
        ignoreGCDCommitted = source.ignoreGCDCommitted == true,
        primaryGCDCommitted = source.primaryGCDCommitted == true,
        terminalCastCommitted = source.terminalCastCommitted == true,
    }
end

local function reserveEntry(ledger, entry, actionClass)
    ledger.reservedSpellRefs[entry.spellRef] = true

    for resourceRef, amount in pairs(entry.resourceCommitments or {}) do
        ledger.reservedResources[resourceRef] = normalizeNonNegative(ledger.reservedResources[resourceRef])
            + normalizeNonNegative(amount)
    end

    if entry.cooldownGroup then
        ledger.reservedCooldownGroups[entry.cooldownGroup] = entry.spellRef
    end
    if entry.ignoresGlobalCooldown == true then
        ledger.ignoreGCDCommitted = true
    end
    if actionClass == "primary" then
        ledger.primaryGCDCommitted = true
    elseif actionClass == "terminal" then
        ledger.terminalCastCommitted = true
        if entry.usesGlobalCooldown == true then
            ledger.primaryGCDCommitted = true
        end
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

function ActionEconomy.CanReserveAuxiliary(ledger, entry)
    if type(ledger) ~= "table" or type(entry) ~= "table" then
        return false, "reservation-context-unavailable"
    end
    local actionClass, classReason = ActionEconomy.ClassifyInput(entry)
    if actionClass ~= "auxiliary" then
        return false, classReason or "not-auxiliary"
    end
    if ledger.reservedSpellRefs[entry.spellRef] == true then
        return false, "spell-already-reserved"
    end
    if entry.cooldownGroup and ledger.reservedCooldownGroups[entry.cooldownGroup] ~= nil then
        return false, "cooldown-group-conflict"
    end
    if entry.ignoresGlobalCooldown == true and ledger.ignoreGCDCommitted == true then
        return false, "ignore-gcd-peer-lockout"
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

local function selectBestMain(mainCandidates, compareCandidates)
    local best = nil
    for index = 1, #mainCandidates do
        local entry = mainCandidates[index]
        if type(best) ~= "table" then
            best = entry
        else
            local compared = compareEntries(entry, best, compareCandidates)
            if compared == nil then
                return nil, "comparator-unavailable"
            end
            if compared > 0 then
                best = entry
            end
        end
    end
    return best
end

local function sortAuxiliaries(auxiliaries, compareCandidates)
    if #auxiliaries <= 1 then
        return true
    end
    local comparatorAvailable = true
    table.sort(auxiliaries, function(left, right)
        local compared = compareEntries(left, right, compareCandidates)
        if compared == nil then
            comparatorAvailable = false
            return false
        end
        return compared > 0
    end)
    return comparatorAvailable
end

function ActionEconomy.BuildSequence(inputs, options)
    options = type(options) == "table" and options or {}
    local compareCandidates = options.compareCandidates
    local ledger = ActionEconomy.CreateLedger(options.availableResources)
    local mainCandidates = {}
    local auxiliaries = {}
    local rejected = {}

    for index = 1, #(inputs or {}) do
        local source = inputs[index]
        local entry = nil
        local reason = nil
        if type(source) == "table" and type(source.candidate) == "table" and source.spellRef ~= nil then
            local usesGlobalCooldown = nil
            local ignoresGlobalCooldown = nil
            if type(source.usesGlobalCooldown) == "boolean" then
                usesGlobalCooldown = source.usesGlobalCooldown
            end
            if type(source.ignoresGlobalCooldown) == "boolean" then
                ignoresGlobalCooldown = source.ignoresGlobalCooldown
            end
            entry = {
                candidate = source.candidate,
                spellRef = normalizeRef(source.spellRef),
                canCast = source.canCast == true,
                persistentCastTurns = normalizePositiveTurnCount(source.persistentCastTurns),
                usesGlobalCooldown = usesGlobalCooldown,
                ignoresGlobalCooldown = ignoresGlobalCooldown,
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
            if actionClass == "auxiliary" then
                auxiliaries[#auxiliaries + 1] = entry
            elseif actionClass == "primary" or actionClass == "terminal" then
                mainCandidates[#mainCandidates + 1] = entry
            else
                appendRejected(rejected, entry, classReason or "unclassified")
            end
        end
    end

    local main, mainReason = selectBestMain(mainCandidates, compareCandidates)
    if mainReason then
        return {
            status = "failed",
            reason = mainReason,
            actions = {},
            auxiliaries = {},
            main = nil,
            ledger = ActionEconomy.CloneLedger(ledger),
            rejected = rejected,
        }
    end
    if type(main) == "table" then
        reserveEntry(ledger, main, main.actionClass)
    end

    if sortAuxiliaries(auxiliaries, compareCandidates) ~= true then
        return {
            status = "failed",
            reason = "comparator-unavailable",
            actions = {},
            auxiliaries = {},
            main = nil,
            ledger = ActionEconomy.CloneLedger(ledger),
            rejected = rejected,
        }
    end
    local selectedAuxiliaries = {}
    for index = 1, #auxiliaries do
        local entry = auxiliaries[index]
        if #selectedAuxiliaries >= ActionEconomy.MAX_AUXILIARY_ACTIONS_PER_NPC then
            appendRejected(rejected, entry, "auxiliary-cap")
        else
            local compatible, compatibilityReason = ActionEconomy.CanReserveAuxiliary(ledger, entry)
            if compatible then
                reserveEntry(ledger, entry, "auxiliary")
                selectedAuxiliaries[#selectedAuxiliaries + 1] = entry
            else
                appendRejected(rejected, entry, compatibilityReason)
            end
        end
    end

    local actions = {}
    for index = 1, #selectedAuxiliaries do
        actions[#actions + 1] = selectedAuxiliaries[index]
    end
    if type(main) == "table" then
        actions[#actions + 1] = main
    end

    return {
        status = "ready",
        actions = actions,
        auxiliaries = selectedAuxiliaries,
        main = main,
        ledger = ActionEconomy.CloneLedger(ledger),
        rejected = rejected,
    }
end

return ActionEconomy
