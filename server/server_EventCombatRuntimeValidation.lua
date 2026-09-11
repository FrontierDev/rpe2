local _, Addon = ...

local Server = Addon.Server or {}
local Client = Addon.Client or {}
local Comms = Addon.Internal and Addon.Internal.Comms or {}
local EventSync = Comms.EventSync or {}
local Serialization = Comms.Serialization or {}
local CombatState = Comms.EventCombatState or {}
local Operations = Comms.Operations or {}
local Registry = Addon.Internal and Addon.Internal.Registry or {}
local Spellcasting = Client.Spellcasting or {}
local Combat = Client.Combat or {}

local SPELLCAST_START_OPCODE = Operations.GetOpcode and Operations:GetOpcode("SPELLCAST_START") or nil
local SPELLCAST_COMPLETE_OPCODE = Operations.GetOpcode and Operations:GetOpcode("SPELLCAST_COMPLETE") or nil
local SPELLCAST_INTERRUPT_OPCODE = Operations.GetOpcode and Operations:GetOpcode("SPELLCAST_INTERRUPT") or nil

local function findEventUnit(eventState, eventId)
    local numericEventId = tonumber(eventId) or 0
    if numericEventId <= 0 then
        return nil
    end
    for index = 1, #(type(eventState) == "table" and eventState.units or {}) do
        local unit = eventState.units[index]
        if tonumber(unit and unit.eventID) == numericEventId then
            return unit
        end
    end
    return nil
end

local function clone(value)
    return type(CombatState.CloneValue) == "function" and CombatState.CloneValue(value) or value
end

local function normalizeCooldownGroup(value)
    local group = tostring(value or "")
    return group ~= "" and group or nil
end

local function normalizeTargetPolicy(policy)
    if type(policy) ~= "table" then
        return nil
    end
    if type(Combat.NormalizeTarget) == "function" then
        return Combat.NormalizeTarget(policy)
    end
    return clone(policy)
end

local function buildTargetCandidateMap(eventState, casterUnit, spell, spellRef, group)
    if type(Client.BuildSpellActivationTargetCandidates) ~= "function" then
        return nil
    end
    local candidates = Client:BuildSpellActivationTargetCandidates({
        eventState = eventState,
        casterUnit = casterUnit,
        spell = spell,
        spellRef = spellRef,
        targetGroups = { group },
        policy = group and group.policy or nil,
    }, group)
    local byId = {}
    for index = 1, #(candidates or {}) do
        local eventId = tonumber(candidates[index] and candidates[index].eventID) or 0
        if eventId > 0 then
            byId[eventId] = true
        end
    end
    return byId
end

local function sanitizeTargetSelections(eventState, casterUnit, spell, spellRef, candidateEntry)
    local groups, groupError = type(Spellcasting.BuildSpellTargetGroups) == "function"
        and Spellcasting.BuildSpellTargetGroups(spell) or {}, nil
    if groups == nil then
        return nil, groupError or "invalid-target-groups"
    end

    local candidateSelections = type(candidateEntry) == "table" and candidateEntry.targetSelections or nil
    candidateSelections = type(candidateSelections) == "table" and candidateSelections or {}

    local allowedGroups = {}
    for index = 1, #groups do
        allowedGroups[tostring(groups[index] and groups[index].key or "")] = true
    end
    for groupKey in pairs(candidateSelections) do
        if allowedGroups[tostring(groupKey or "")] ~= true then
            return nil, "unknown-target-group"
        end
    end

    local selections = {}
    local order = {}
    for index = 1, #groups do
        local group = groups[index]
        local groupKey = tostring(group and group.key or "")
        local policy = normalizeTargetPolicy(group and group.policy) or {}
        local source = candidateSelections[groupKey]
        source = type(source) == "table" and source or {}
        local validTargets = buildTargetCandidateMap(eventState, casterUnit, spell, spellRef, group)
        if validTargets == nil then
            return nil, "target-candidate-validation-unavailable"
        end

        local ids = {}
        local seen = {}
        for targetIndex = 1, #(source.targetEventIds or {}) do
            local targetEventId = tonumber(source.targetEventIds[targetIndex]) or 0
            if targetEventId <= 0 or validTargets[targetEventId] ~= true or seen[targetEventId] == true then
                return nil, "invalid-target-selection"
            end
            seen[targetEventId] = true
            ids[#ids + 1] = targetEventId
        end

        local minTargets = math.max(0, math.floor(tonumber(policy.minTargets) or 0))
        local maxTargets = math.max(0, math.floor(tonumber(policy.maxTargets) or 0))
        if policy.requiresTarget == true and minTargets <= 0 then
            minTargets = 1
        end
        if #ids < minTargets or (maxTargets > 0 and #ids > maxTargets) then
            return nil, "invalid-target-count"
        end

        local focusedTargetEventId = tonumber(source.focusedTargetEventId) or 0
        if focusedTargetEventId > 0 and seen[focusedTargetEventId] ~= true then
            return nil, "invalid-focused-target"
        end
        if focusedTargetEventId <= 0 and #ids > 0 then
            focusedTargetEventId = ids[1]
        end

        selections[groupKey] = {
            groupKey = groupKey,
            targetEventIds = ids,
            focusedTargetEventId = focusedTargetEventId,
            policy = policy,
        }
        order[#order + 1] = groupKey
    end

    local primary = #order > 0 and selections[order[1]] or nil
    return {
        targetSelections = selections,
        targetSelectionOrder = order,
        targetEventIds = clone(primary and primary.targetEventIds or {}),
        focusedTargetEventId = tonumber(primary and primary.focusedTargetEventId) or 0,
        targetPolicy = clone(primary and primary.policy or nil),
    }
end

local function findResourceEntry(resources, resourceRef)
    for index = 1, #(resources or {}) do
        local entry = resources[index]
        if tostring(entry and entry.resourceRef or "") == tostring(resourceRef or "") then
            return entry
        end
    end
    return nil
end

local function sanitizeResolvedStartCosts(casterUnit, spell, candidateEntry)
    local costs = type(Spellcasting.GetSpellResourceCostsForPhase) == "function"
        and Spellcasting.GetSpellResourceCostsForPhase(spell, "on_cast_start") or {}
    if #costs == 0 then
        return {}
    end
    local supplied = type(candidateEntry) == "table" and candidateEntry.resolvedStartCostAmounts or nil
    supplied = type(supplied) == "table" and supplied or {}
    local resolved = {}
    for index = 1, #costs do
        local cost = costs[index]
        local amountMode = tostring(type(cost) == "table" and cost.amountMode or "flat")
        local authoredAmount = math.max(0, tonumber(type(cost) == "table" and cost.amount or 0) or 0)
        if amountMode == "flat" then
            resolved[index] = authoredAmount
        else
            local resourceRef = tostring(type(cost) == "table" and cost.resourceRef or "")
            local resource = findResourceEntry(casterUnit and casterUnit.resources, resourceRef)
            local maxValue = math.max(0, tonumber(resource and (resource.maxValue or resource.currentValue)) or 0)
            local upperBound = math.max(0, math.ceil(maxValue * authoredAmount / 100))
            local proposedAmount = tonumber(supplied[index])
            if proposedAmount == nil or proposedAmount < 0 or proposedAmount > upperBound then
                return nil, "invalid-resolved-start-cost"
            end
            -- Percentage costs for player resources may depend on profile-derived
            -- base values which are not present on the host for another player.
            -- Accept only the bounded resolved amount; never accept arbitrary
            -- extra entries or a value greater than the event-unit maximum.
            resolved[index] = proposedAmount
        end
    end
    for key in pairs(supplied) do
        local numericKey = tonumber(key)
        if numericKey == nil or numericKey < 1 or numericKey > #costs or math.floor(numericKey) ~= numericKey then
            return nil, "unexpected-resolved-start-cost"
        end
    end
    return resolved
end

local function relationLockoutTurns(triggerSpell, candidateSpell)
    if type(triggerSpell) ~= "table" or type(candidateSpell) ~= "table" then
        return 0
    end
    local lockout = 0
    local group = normalizeCooldownGroup(triggerSpell.cooldownGroup)
    if group and group == normalizeCooldownGroup(candidateSpell.cooldownGroup) then
        lockout = math.max(lockout, math.max(0, math.floor(tonumber(
            type(Spellcasting.NormalizeTurnCount) == "function" and Spellcasting.NormalizeTurnCount(triggerSpell.cooldown) or triggerSpell.cooldown
        ) or 0)))
    end
    if triggerSpell.ignoreGCD == true and candidateSpell.ignoreGCD == true then
        lockout = math.max(lockout, 1)
    end
    return lockout
end

local function buildDefaultCooldownSpellState(spell)
    local usesCharges = type(spell) == "table" and spell.useCooldownCharges == true
    local maxCharges = usesCharges and math.max(1, math.floor(tonumber(spell.charges) or 1)) or nil
    return {
        remainingTurns = 0,
        lockoutRemainingTurns = 0,
        currentCharges = usesCharges and maxCharges or nil,
        maxCharges = maxCharges,
        usesCharges = usesCharges,
        cooldownTurns = usesCharges and math.max(1, math.floor(tonumber(spell.cooldown) or 1)) or nil,
    }
end

local function deriveAuthoritativeCooldownUnitState(eventState, casterUnit, spellRef, spell, candidateRuntime)
    local eventId = tostring(eventState and eventState.id or "")
    local casterEventId = tonumber(casterUnit and casterUnit.eventID) or 0
    local runtime = Server.EventRuntime
    local authoritativeBucket = type(runtime) == "table" and runtime.cooldowns or {}
    local authoritativeUnit = type(CombatState.CloneCooldownUnitState) == "function"
        and CombatState.CloneCooldownUnitState(authoritativeBucket and authoritativeBucket[casterEventId]) or nil
    authoritativeUnit = authoritativeUnit or {
        globalCooldownRemaining = 0,
        lastAdvancedTurnNumber = math.max(0, math.floor(tonumber(eventState and eventState.turnNumber) or 0)),
        spells = {},
    }

    local savedBucket = Client.CooldownsByEventId and Client.CooldownsByEventId[eventId] or nil
    local savedQueued = Client.ActionBarRefreshQueued
    local savedReason = Client.PendingActionBarRefreshReason
    Client.CooldownsByEventId = Client.CooldownsByEventId or {}
    Client.CooldownsByEventId[eventId] = {
        [casterEventId] = type(CombatState.CloneCooldownUnitState) == "function"
            and CombatState.CloneCooldownUnitState(authoritativeUnit) or clone(authoritativeUnit),
    }
    if type(Client.ApplyLocalSpellCooldown) ~= "function"
        or Client:ApplyLocalSpellCooldown(eventState, casterUnit, spellRef, spell) ~= true
    then
        -- A spell without an authored cooldown can legitimately return false;
        -- the resulting unit state still contains the authoritative GCD state.
    end
    local derived = type(CombatState.CloneCooldownUnitState) == "function"
        and CombatState.CloneCooldownUnitState(Client.CooldownsByEventId[eventId][casterEventId]) or clone(Client.CooldownsByEventId[eventId][casterEventId])
    Client.CooldownsByEventId[eventId] = savedBucket
    Client.ActionBarRefreshQueued = savedQueued
    Client.PendingActionBarRefreshReason = savedReason

    derived = derived or authoritativeUnit
    derived.spells = derived.spells or {}

    local candidateUnit = type(candidateRuntime) == "table" and type(candidateRuntime.cooldowns) == "table"
        and candidateRuntime.cooldowns[casterEventId] or nil
    local candidateSpells = type(candidateUnit) == "table" and candidateUnit.spells or {}

    local relatedRefs = {}
    for ref in pairs(authoritativeUnit.spells or {}) do
        relatedRefs[tostring(ref)] = true
    end
    relatedRefs[spellRef] = true
    for ref in pairs(candidateSpells or {}) do
        local candidateRef = tostring(ref or "")
        if candidateRef ~= "" and type(Registry.ResolveSpellReference) == "function" then
            local _, candidateSpell = Registry:ResolveSpellReference(candidateRef)
            if relationLockoutTurns(spell, candidateSpell) > 0 then
                relatedRefs[candidateRef] = true
            end
        end
    end

    for ref in pairs(derived.spells) do
        if relatedRefs[tostring(ref)] ~= true then
            derived.spells[ref] = nil
        end
    end

    for ref in pairs(relatedRefs) do
        if ref ~= spellRef and type(Registry.ResolveSpellReference) == "function" then
            local _, relatedSpell = Registry:ResolveSpellReference(ref)
            local lockoutTurns = relationLockoutTurns(spell, relatedSpell)
            if lockoutTurns > 0 then
                local state = derived.spells[ref]
                    or (type(CombatState.CloneCooldownSpellState) == "function" and CombatState.CloneCooldownSpellState(authoritativeUnit.spells and authoritativeUnit.spells[ref]))
                    or buildDefaultCooldownSpellState(relatedSpell)
                state.lockoutRemainingTurns = math.max(math.max(0, tonumber(state.lockoutRemainingTurns) or 0), lockoutTurns)
                derived.spells[ref] = state
            end
        end
    end

    return derived
end

local function sanitizeSpellStartRequest(request, proposal)
    local arguments = Serialization:DeserializeArguments(proposal.domainPayload or "")
    local eventState = Server.EventState
    local casterEventId = tonumber(arguments and arguments[3]) or 0
    local spellRef = tostring(arguments and arguments[4] or "")
    local casterUnit = findEventUnit(eventState, casterEventId)
    local dataset, spell = nil, nil
    if type(Registry.ResolveSpellReference) == "function" then
        dataset, spell = Registry:ResolveSpellReference(spellRef)
    end
    if type(eventState) ~= "table" or eventState.active ~= true or not casterUnit or not dataset or not spell then
        return nil, "invalid-spell-start"
    end

    local canonicalTurns = type(Spellcasting.ResolvePersistentCastTurns) == "function"
        and Spellcasting.ResolvePersistentCastTurns(spell, nil) or nil
    if canonicalTurns == nil then
        return nil, "instant-spell-cannot-start-persistent-cast"
    end
    arguments[5] = canonicalTurns

    local candidateRuntime = type(proposal.runtimeState) == "table"
        and CombatState.CloneRuntimeState(proposal.runtimeState) or CombatState.CloneRuntimeState({})
    local candidateEntry = candidateRuntime.spellcasts and candidateRuntime.spellcasts[casterEventId] or nil
    local targets, targetReason = sanitizeTargetSelections(eventState, casterUnit, spell, spellRef, candidateEntry)
    if not targets then
        return nil, targetReason
    end
    local startCosts, costReason = sanitizeResolvedStartCosts(casterUnit, spell, candidateEntry)
    if not startCosts then
        return nil, costReason
    end

    candidateRuntime.spellcasts = candidateRuntime.spellcasts or {}
    candidateRuntime.spellcasts[casterEventId] = {
        spellRef = spellRef,
        spellName = tostring(spell.name or ""),
        authorityType = tostring(arguments[6] or ""),
        casterEventId = casterEventId,
        turnsTotal = canonicalTurns,
        turnsElapsed = 0,
        turnsRemaining = canonicalTurns,
        startedOnTurnNumber = math.max(1, math.floor(tonumber(eventState.turnNumber) or 1)),
        lastAdvancedTurnNumber = math.max(1, math.floor(tonumber(eventState.turnNumber) or 1)),
        targetSelections = targets.targetSelections,
        targetSelectionOrder = targets.targetSelectionOrder,
        targetEventIds = targets.targetEventIds,
        focusedTargetEventId = targets.focusedTargetEventId,
        targetPolicy = targets.targetPolicy,
        resolvedStartCostAmounts = startCosts,
    }
    candidateRuntime.cooldowns = candidateRuntime.cooldowns or {}
    candidateRuntime.cooldowns[casterEventId] = deriveAuthoritativeCooldownUnitState(
        eventState,
        casterUnit,
        spellRef,
        spell,
        candidateRuntime
    )

    return {
        domainPayload = Serialization:SerializeArguments(arguments),
        runtimeState = candidateRuntime,
    }
end

local function sanitizeNonStartSpellProposal(proposal)
    local runtimeState = type(proposal.runtimeState) == "table"
        and CombatState.CloneRuntimeState(proposal.runtimeState) or CombatState.CloneRuntimeState({})
    runtimeState.cooldowns = type(CombatState.CloneCooldownBucket) == "function"
        and CombatState.CloneCooldownBucket(Server.EventRuntime and Server.EventRuntime.cooldowns or {}) or {}
    return {
        domainPayload = proposal.domainPayload,
        runtimeState = runtimeState,
    }
end

local baseHandleEventMutationRequest = Server.HandleEventMutationRequest
if type(baseHandleEventMutationRequest) == "function" then
    function Server:HandleEventMutationRequest(payload, sender)
        local request = type(EventSync.DeserializeMutationRequest) == "function"
            and EventSync.DeserializeMutationRequest(payload) or nil
        if type(request) ~= "table"
            or (request.opcode ~= SPELLCAST_START_OPCODE
                and request.opcode ~= SPELLCAST_COMPLETE_OPCODE
                and request.opcode ~= SPELLCAST_INTERRUPT_OPCODE)
        then
            return baseHandleEventMutationRequest(self, payload, sender)
        end

        local proposal, reason = type(CombatState.DeserializeDomainProposal) == "function"
            and CombatState.DeserializeDomainProposal(request.payload) or nil, "proposal-codec-unavailable"
        if not proposal then
            return false
        end

        local sanitized, sanitizeReason
        if request.opcode == SPELLCAST_START_OPCODE then
            sanitized, sanitizeReason = sanitizeSpellStartRequest(request, proposal)
        else
            sanitized = sanitizeNonStartSpellProposal(proposal)
        end
        if not sanitized then
            if type(Addon.Debug) == "table" and type(Addon.Debug.Internal) == "function" then
                Addon.Debug.Internal("Event combat spell proposal rejected during authority validation: %s", tostring(sanitizeReason or reason or "invalid"))
            end
            return false
        end

        local sanitizedProposalPayload = CombatState.SerializeDomainProposal(sanitized.domainPayload, sanitized.runtimeState)
        local sanitizedRequestPayload = EventSync.SerializeMutationRequest({
            protocolVersion = request.protocolVersion,
            channelName = request.channelName,
            eventId = request.eventId,
            opcode = request.opcode,
            payload = sanitizedProposalPayload,
        })
        if not sanitizedRequestPayload then
            return false
        end
        return baseHandleEventMutationRequest(self, sanitizedRequestPayload, sender)
    end
end

return Server
