local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Client.Spellcasting = Addon.Client.Spellcasting or {}
Addon.Internal = Addon.Internal or {}

local Client = Addon.Client
local Spellcasting = Client.Spellcasting
local Conditions = Client.Conditions or {}
local Profile = Addon.Internal and Addon.Internal.Profile or {}
local Registry = Addon.Internal and Addon.Internal.Registry or {}
local COOLDOWN_CHANNEL_MIN_ID = 1
local COOLDOWN_CHANNEL_MAX_ID = 10
local function getAuraManager()
    return Addon.Client and Addon.Client.Spellcasting and Addon.Client.Spellcasting.AuraManager or nil
end
local function getEventClass()
    return Addon.Internal
        and Addon.Internal.Database
        and Addon.Internal.Database.Classes
        and Addon.Internal.Database.Classes.Event
        or nil
end

Client.CooldownsByEventId = Client.CooldownsByEventId or {}
Client.ActionBarRefreshQueued = Client.ActionBarRefreshQueued or false

local function getTasks()
    return Addon.Internal and Addon.Internal.Tasks or nil
end

local function enqueueActionBarWork(fn, ...)
    local tasks = getTasks()
    if tasks and tasks.Enqueue then
        tasks:Enqueue(fn, ...)
        return
    end

    if C_Timer and C_Timer.After then
        local args = { ... }
        local argCount = select("#", ...)
        C_Timer.After(0, function()
            fn(unpack(args, 1, argCount))
        end)
        return
    end

    fn(...)
end

local function bumpEventTooltipContextRevision(eventId, casterEventId)
    local builder = Addon.Client and Addon.Client.Spellcasting and Addon.Client.Spellcasting.DescriptionBuilder or nil
    if type(builder) == "table" and type(builder.BumpEventTooltipContextRevision) == "function" then
        builder.BumpEventTooltipContextRevision(eventId, casterEventId)
    end
end

local function bumpAllEventTooltipContextRevisions(eventState)
    local builder = Addon.Client and Addon.Client.Spellcasting and Addon.Client.Spellcasting.DescriptionBuilder or nil
    if type(builder) == "table" and type(builder.BumpEventTooltipContextRevisionForAllUnits) == "function" then
        builder.BumpEventTooltipContextRevisionForAllUnits(eventState)
    end
end

local function getNowMilliseconds()
    if type(GetTimePreciseSec) == "function" then
        return GetTimePreciseSec() * 1000
    end

    return (GetTime and GetTime() or 0) * 1000
end

local function isSpellcastTimingEnabled()
    return type(Addon.Debug) == "table" and Addon.Debug.SpellcastTiming == true
end

local function startTiming(label, thresholdMs, context)
    local timings = Addon.Debug and Addon.Debug.Timings or nil
    if timings and type(timings.Start) == "function" then
        if type(timings.IsEnabled) == "function" and not timings:IsEnabled() then
            return nil
        end
        return timings:Start(label, {
            thresholdMs = thresholdMs,
            context = context,
        })
    end
    return nil
end

local function stopTiming(timer, cardinality)
    if not timer then
        return
    end

    local timings = Addon.Debug and Addon.Debug.Timings or nil
    if timings and type(timings.Stop) == "function" then
        timings:Stop(timer, { cardinality = cardinality })
    end
end

local function countCooldownEntries(bucket)
    local units = 0
    local spells = 0
    if type(bucket) == "table" then
        for _, unitState in pairs(bucket) do
            if type(unitState) == "table" then
                units = units + 1
                for _ in pairs(unitState.spells or {}) do
                    spells = spells + 1
                end
            end
        end
    end
    return units, spells
end

local function logSpellcastTiming(phase, context, detail)
    local Debug = Addon.Debug or {}
    if not isSpellcastTimingEnabled() or type(Debug.Internal) ~= "function" then
        return false
    end

    if type(Debug.EnsureInternalLevelEnabled) == "function" then
        Debug.EnsureInternalLevelEnabled()
    end

    local message = ("Cooldown timing [%s]: %s - %s"):format(
        tostring(context or "unknown"),
        tostring(phase or "unknown"),
        tostring(detail or "")
    )
    return Debug.Internal("%s", message)
end

local function normalizeEventId(eventId)
    return type(eventId) == "string" and eventId or ""
end

local function normalizeCooldownChannelId(channelId)
    local numericChannelId = tonumber(channelId)
    if numericChannelId == nil
        or numericChannelId ~= numericChannelId
        or numericChannelId == math.huge
        or numericChannelId == -math.huge
        or numericChannelId % 1 ~= 0
        or numericChannelId < COOLDOWN_CHANNEL_MIN_ID
        or numericChannelId > COOLDOWN_CHANNEL_MAX_ID
    then
        return nil
    end

    return numericChannelId
end

local function buildSignature(...)
    local parts = {}
    for index = 1, select("#", ...) do
        local value = select(index, ...)
        parts[index] = tostring(value == nil and "" or value)
    end

    return table.concat(parts, "\31")
end

local function buildResourceSignature(resources)
    local parts = {}
    for index = 1, #(resources or {}) do
        local entry = resources[index]
        parts[#parts + 1] = buildSignature(
            entry and entry.resourceRef or "",
            tonumber(entry and entry.currentValue) or 0,
            tonumber(entry and entry.maxValue) or 0
        )
    end
    return table.concat(parts, "\30")
end

local function buildSpellStateSignature(spellState)
    if type(spellState) ~= "table" then
        return ""
    end

    return buildSignature(
        tonumber(spellState.remainingTurns) or 0,
        tonumber(spellState.lockoutRemainingTurns) or 0,
        tonumber(spellState.currentCharges) or 0,
        tonumber(spellState.maxCharges) or 0,
        spellState.usesCharges == true and 1 or 0,
        tonumber(spellState.cooldownTurns) or 0
    )
end

local function buildUnitCooldownSignature(unitState)
    if type(unitState) ~= "table" then
        return ""
    end

    local channelIds = {}
    for channelId, remaining in pairs(unitState.channelCooldowns or {}) do
        local normalizedChannelId = type(channelId) == "number" and normalizeCooldownChannelId(channelId) or nil
        if normalizedChannelId and math.max(0, math.floor(tonumber(remaining) or 0)) > 0 then
            channelIds[#channelIds + 1] = normalizedChannelId
        end
    end
    table.sort(channelIds)

    local spellRefs = {}
    for spellRef in pairs(unitState.spells or {}) do
        spellRefs[#spellRefs + 1] = spellRef
    end
    table.sort(spellRefs)

    local parts = {
        buildSignature(
            tonumber(unitState.lastAdvancedTurnNumber) or 0
        ),
    }
    for index = 1, #channelIds do
        local channelId = channelIds[index]
        parts[#parts + 1] = buildSignature(
            channelId,
            math.max(0, math.floor(tonumber(unitState.channelCooldowns[channelId]) or 0))
        )
    end
    for index = 1, #spellRefs do
        local spellRef = spellRefs[index]
        parts[#parts + 1] = buildSignature(spellRef, buildSpellStateSignature(unitState.spells[spellRef]))
    end

    return table.concat(parts, "\30")
end

local function ensureString(value, fallback)
    local text = tostring(value or "")
    if text == "" then
        return fallback or ""
    end

    return text
end

local function normalizeUnitEventId(unitEventId)
    local numericUnitEventId = tonumber(unitEventId) or 0
    if numericUnitEventId <= 0 then
        return nil
    end

    return numericUnitEventId
end

local function normalizeChargeCount(spell)
    local maxCharges = math.floor(tonumber(spell and spell.charges) or 0)
    if maxCharges <= 0 then
        return 1
    end

    return maxCharges
end

local function normalizeCooldownGroup(value)
    local group = type(value) == "string" and value or tostring(value or "")
    if group == "" then
        return nil
    end

    return group
end

local function getConfigurationRevision()
    return math.max(0, math.floor(tonumber(Addon.Internal and Addon.Internal.ConfigurationRevision) or 0))
end

local function resolveSpellCooldownChannel(spell)
    if type(Spellcasting.ResolveSpellCooldownChannel) ~= "function" then
        return nil, nil, "unavailable", "spell-channel-resolver-unavailable"
    end

    local channelId, channel, source, reason = Spellcasting.ResolveSpellCooldownChannel(spell)
    if not channelId or type(channel) ~= "table" or channel.enabled ~= true then
        return channelId, channel, source, reason or "invalid-cooldown-channel"
    end

    return channelId, channel, source, reason
end

local function normalizeCooldownTurns(spell, requirePositive)
    local turns = Spellcasting.NormalizeTurnCount and Spellcasting.NormalizeTurnCount(spell and spell.cooldown) or nil
    if turns ~= nil then
        return turns
    end

    if requirePositive then
        return 1
    end

    return nil
end

local function formatTurnLabel(turns)
    local numericTurns = math.max(0, math.floor(tonumber(turns) or 0))
    if numericTurns == 1 then
        return "1 turn"
    end

    return ("%d turns"):format(numericTurns)
end

local function buildChannelCooldownText(channelName, turns)
    local numericTurns = math.max(0, math.floor(tonumber(turns) or 0))
    local normalizedName = ensureString(channelName, "")
    if numericTurns <= 0 or normalizedName == "" then
        return nil
    end

    return ("%s cooldown: %s"):format(normalizedName, formatTurnLabel(numericTurns))
end

local function cloneSpellState(state)
    if type(state) ~= "table" then
        return nil
    end

    return {
        remainingTurns = math.max(0, math.floor(tonumber(state.remainingTurns) or 0)),
        lockoutRemainingTurns = math.max(0, math.floor(tonumber(state.lockoutRemainingTurns) or 0)),
        currentCharges = tonumber(state.currentCharges) ~= nil and math.max(0, math.floor(tonumber(state.currentCharges) or 0)) or nil,
        maxCharges = tonumber(state.maxCharges) ~= nil and math.max(1, math.floor(tonumber(state.maxCharges) or 1)) or nil,
        usesCharges = state.usesCharges == true,
        cooldownTurns = tonumber(state.cooldownTurns) ~= nil and math.max(1, math.floor(tonumber(state.cooldownTurns) or 1)) or nil,
    }
end

local function buildTrackedUnitMap(self, eventState)
    local tracked = {}
    if type(self) ~= "table" or type(eventState) ~= "table" or eventState.active ~= true then
        return tracked
    end

    local localUnit = self.ResolveLocalEventUnit and self:ResolveLocalEventUnit(eventState) or nil
    local localUnitEventId = normalizeUnitEventId(localUnit and localUnit.eventID)
    if localUnitEventId then
        tracked[localUnitEventId] = true
    end

    for index = 1, #(eventState.units or {}) do
        local unit = eventState.units[index]
        local unitEventId = normalizeUnitEventId(unit and unit.eventID)
        local eventClass = getEventClass()
        if unitEventId
            and unit
            and unit.isPlayer ~= true
            and (not eventClass or not eventClass.IsUnitActive or eventClass.IsUnitActive(unit))
            and self.CanControlEventUnit
            and self:CanControlEventUnit(unit, eventState)
        then
            tracked[unitEventId] = true
        end
    end

    return tracked
end

local function cleanupEventBucket(self, eventId, bucket)
    if type(bucket) ~= "table" or next(bucket) ~= nil then
        return false
    end

    if type(self.CooldownsByEventId) == "table" then
        self.CooldownsByEventId[eventId] = nil
    end
    return true
end

local function cleanupUnitState(unitState)
    if type(unitState) ~= "table" then
        return true
    end

    local channelCooldowns = type(unitState.channelCooldowns) == "table" and unitState.channelCooldowns or nil
    if channelCooldowns then
        for channelId, remaining in pairs(channelCooldowns) do
            local normalizedChannelId = type(channelId) == "number" and normalizeCooldownChannelId(channelId) or nil
            if not normalizedChannelId or math.max(0, math.floor(tonumber(remaining) or 0)) <= 0 then
                channelCooldowns[channelId] = nil
            end
        end
    end

    if channelCooldowns and next(channelCooldowns) ~= nil then
        return false
    end

    return type(unitState.spells) ~= "table" or next(unitState.spells) == nil
end

local function getSpellCooldownState(unitState, spellRef)
    if type(unitState) ~= "table" or type(unitState.spells) ~= "table" or type(spellRef) ~= "string" or spellRef == "" then
        return nil
    end

    return unitState.spells[spellRef]
end

local function setSpellCooldownState(unitState, spellRef, state)
    if type(unitState) ~= "table" or type(unitState.spells) ~= "table" or type(spellRef) ~= "string" or spellRef == "" then
        return nil
    end

    unitState.spells[spellRef] = state
    return state
end

local function getSpellLockoutRemaining(spellState)
    return math.max(0, math.floor(tonumber(spellState and spellState.lockoutRemainingTurns) or 0))
end

local function shouldClearSpellState(entry)
    if type(entry) ~= "table" then
        return true
    end

    local lockoutRemainingTurns = getSpellLockoutRemaining(entry)
    local remainingTurns = math.max(0, math.floor(tonumber(entry.remainingTurns) or 0))
    if entry.usesCharges == true then
        local currentCharges = math.max(0, math.floor(tonumber(entry.currentCharges) or 0))
        local maxCharges = math.max(1, math.floor(tonumber(entry.maxCharges) or 1))
        return currentCharges >= maxCharges and remainingTurns <= 0 and lockoutRemainingTurns <= 0
    end

    return remainingTurns <= 0 and lockoutRemainingTurns <= 0
end

local function listUnitSpellRefs(casterUnit)
    local spellRefs = type(casterUnit) == "table" and casterUnit.spells or {}
    if type(casterUnit) == "table" and casterUnit.GetResolvedValue then
        spellRefs = casterUnit:GetResolvedValue("spells", spellRefs)
    end

    if type(spellRefs) == "string" then
        return spellRefs ~= "" and { spellRefs } or {}
    end

    if type(spellRefs) ~= "table" then
        return {}
    end

    return spellRefs
end

local function listCasterSpellRefs(self, eventState, casterUnit)
    local timingEnabled = isSpellcastTimingEnabled()
    local totalStartTime = timingEnabled and getNowMilliseconds() or nil
    
    local refs = {}
    local seen = {}

    local function appendSpellRef(spellRef)
        local normalizedRef = type(spellRef) == "string" and spellRef or nil
        if normalizedRef == nil and type(spellRef) == "table" then
            normalizedRef = spellRef.spellRef or spellRef.spellID or spellRef.id or spellRef.name
        end
        if type(normalizedRef) ~= "string" or normalizedRef == "" or seen[normalizedRef] == true then
            return
        end

        seen[normalizedRef] = true
        refs[#refs + 1] = normalizedRef
    end

    if type(casterUnit) == "table" and casterUnit.isPlayer == true then
        -- Optimization: Use cache instead of listing all known spells
        local cacheKey = casterUnit.isPetCaster == true and "_cachedPetSpellRefs" or "_cachedSpellRefs"
        
        -- Check if we have a cached list from the last action bar refresh
        if type(self[cacheKey]) == "table" and #self[cacheKey] > 0 then
            if timingEnabled then
                logSpellcastTiming("cache-hit", "spell-refs", ("%.2fms, cached=%d"):format(0, #self[cacheKey]))
            end
            return self[cacheKey]
        end
        
        -- Cache miss - build from raw action bar bindings instead of resolved slot details
        local listStartTime = timingEnabled and getNowMilliseconds() or nil
        local actionBarBindings = Profile.ListActionBarBindings and Profile.ListActionBarBindings() or {}
        if timingEnabled then
            logSpellcastTiming("list-action-bar", "spell-refs", ("%.2fms, action-bar-bindings=%d"):format(math.max(0, getNowMilliseconds() - listStartTime), #actionBarBindings))
        end
        
        local loopStartTime = timingEnabled and getNowMilliseconds() or nil
        for index = 1, #actionBarBindings do
            appendSpellRef(actionBarBindings[index])
        end
        if timingEnabled then
            logSpellcastTiming("append-action-bar", "spell-refs", ("%.2fms"):format(math.max(0, getNowMilliseconds() - loopStartTime)))
        end

        -- Cache the result for next spell cast
        self[cacheKey] = refs
        
        if timingEnabled then
            logSpellcastTiming("cache-build-total", "spell-refs", ("%.2fms, cached=%d"):format(math.max(0, getNowMilliseconds() - totalStartTime), #refs))
        end
    else
        -- NPC unit path - list their spells
        local unitSpellRefs = listUnitSpellRefs(casterUnit)
        for index = 1, #unitSpellRefs do
            appendSpellRef(unitSpellRefs[index])
        end
    end

    return refs
end

local function buildSpellRefSignature(spellRefs)
    return table.concat(spellRefs or {}, "\31")
end

local function buildCooldownSpellMetadata(self, eventState, casterUnit)
    local spellRefs = listCasterSpellRefs(self, eventState, casterUnit)
    local metadata = {
        spellRefs = spellRefs,
        spellByRef = {},
        cooldownGroups = {},
    }

    for index = 1, #spellRefs do
        local spellRef = spellRefs[index]
        local spell = nil
        if Registry.ResolveSpellReference then
            local _, resolvedSpell = Registry:ResolveSpellReference(spellRef)
            spell = resolvedSpell
        end
        if type(spell) == "table" then
            metadata.spellByRef[spellRef] = spell

            local cooldownGroup = normalizeCooldownGroup(spell.cooldownGroup)
            if cooldownGroup then
                metadata.cooldownGroups[cooldownGroup] = metadata.cooldownGroups[cooldownGroup] or {}
                metadata.cooldownGroups[cooldownGroup][#metadata.cooldownGroups[cooldownGroup] + 1] = spellRef
            end

        end
    end

    return metadata
end

local function getCooldownSpellMetadata(self, eventState, casterUnit)
    if type(casterUnit) ~= "table" or casterUnit.isPlayer ~= true then
        return buildCooldownSpellMetadata(self, eventState, casterUnit)
    end

    local cacheKey = casterUnit.isPetCaster == true and "_cachedPetCooldownSpellMetadata" or "_cachedCooldownSpellMetadata"
    local revision = getConfigurationRevision()
    local spellRefs = listCasterSpellRefs(self, eventState, casterUnit)
    local signature = buildSpellRefSignature(spellRefs)
    local cache = self[cacheKey]
    if type(cache) == "table"
        and tonumber(cache.revision) == revision
        and tostring(cache.signature or "") == signature
        and type(cache.metadata) == "table"
    then
        return cache.metadata
    end

    local metadata = buildCooldownSpellMetadata(self, eventState, casterUnit)
    self[cacheKey] = {
        revision = revision,
        signature = signature,
        metadata = metadata,
    }
    return metadata
end

local function resolveSpellReference(spellRef)
    if type(spellRef) ~= "string" or spellRef == "" or not Registry or not Registry.ResolveSpellReference then
        return nil, nil
    end

    return Registry:ResolveSpellReference(spellRef)
end

local function applyExternalSpellLockout(unitState, spellRef, spell, lockoutTurns)
    local normalizedTurns = math.max(0, math.floor(tonumber(lockoutTurns) or 0))
    if type(unitState) ~= "table" or type(spellRef) ~= "string" or spellRef == "" or type(spell) ~= "table" or normalizedTurns <= 0 then
        return false
    end

    local spellState = cloneSpellState(getSpellCooldownState(unitState, spellRef)) or {
        remainingTurns = 0,
        lockoutRemainingTurns = 0,
        usesCharges = spell.useCooldownCharges == true,
    }

    if spell.useCooldownCharges == true then
        local maxCharges = normalizeChargeCount(spell)
        spellState.currentCharges = tonumber(spellState.currentCharges) ~= nil and math.max(0, math.min(maxCharges, math.floor(tonumber(spellState.currentCharges) or maxCharges))) or maxCharges
        spellState.maxCharges = maxCharges
        spellState.cooldownTurns = normalizeCooldownTurns(spell, true)
        spellState.usesCharges = true
    else
        spellState.currentCharges = nil
        spellState.maxCharges = nil
        spellState.cooldownTurns = nil
        spellState.usesCharges = false
    end

    local nextLockoutRemainingTurns = math.max(getSpellLockoutRemaining(spellState), normalizedTurns)
    if nextLockoutRemainingTurns == getSpellLockoutRemaining(spellState) then
        return false
    end

    spellState.lockoutRemainingTurns = nextLockoutRemainingTurns
    setSpellCooldownState(unitState, spellRef, spellState)
    return true
end

local function buildCooldownText(activationState)
    if type(activationState) ~= "table" then
        return "No Cooldown"
    end

    local currentCharges = tonumber(activationState.currentCharges)
    local maxCharges = tonumber(activationState.maxCharges)
    local cooldownRemaining = math.max(0, math.floor(tonumber(activationState.cooldownRemaining) or 0))
    local rechargeRemaining = math.max(0, math.floor(tonumber(activationState.rechargeRemaining) or 0))
    local lockoutRemaining = math.max(0, math.floor(tonumber(activationState.lockoutRemaining) or 0))
    local channelCooldownRemaining = math.max(0, math.floor(tonumber(activationState.channelCooldownRemaining) or 0))

    local text
    if currentCharges ~= nil and maxCharges ~= nil then
        local normalizedCurrentCharges = math.max(0, math.floor(currentCharges))
        local normalizedMaxCharges = math.max(1, math.floor(maxCharges))
        if rechargeRemaining > 0 and normalizedCurrentCharges < normalizedMaxCharges then
            text = ("%d/%d charges, next in %s"):format(
                normalizedCurrentCharges,
                normalizedMaxCharges,
                formatTurnLabel(rechargeRemaining)
            )
        else
            text = ("%d/%d charges"):format(normalizedCurrentCharges, normalizedMaxCharges)
        end
        if lockoutRemaining > 0 then
            text = ("%s | %s remaining"):format(text, formatTurnLabel(lockoutRemaining))
        end
    elseif cooldownRemaining > 0 then
        text = ("%s remaining"):format(formatTurnLabel(cooldownRemaining))
    else
        text = "No Cooldown"
    end

    local channelText = activationState.cooldownChannelTriggersGCD == true
        and buildChannelCooldownText(activationState.cooldownChannelName, channelCooldownRemaining)
        or nil
    if channelText and channelText ~= "" then
        if text ~= "" then
            return ("%s | %s"):format(text, channelText)
        end
        return channelText
    end

    return text
end

local function buildFailureReason(reason, cooldownRemaining, cooldownChannelName, channelCooldownRemaining, conditionFailureText)
    if reason == "inactive" then
        return "Unavailable"
    end
    if reason == "invalid-spell" then
        return "Unknown Spell"
    end
    if reason == "not-your-turn" then
        return "Not Your Turn"
    end
    if reason == "casting" then
        return "Casting"
    end
    if reason == "channel-cooldown" then
        return buildChannelCooldownText(cooldownChannelName, channelCooldownRemaining) or "On Cooldown"
    end
    if reason == "invalid-cooldown-channel" then
        return "Invalid Cooldown Channel"
    end
    if reason == "cooldown" then
        return ("%s remaining"):format(formatTurnLabel(cooldownRemaining))
    end
    if reason == "no-charges" then
        return "No Charges"
    end
    if reason == "insufficient-resources" then
        return "Insufficient Resources"
    end
    if reason == "no-targets" then
        return "No Valid Targets"
    end
    if reason == "invalid-targeting" then
        return "Invalid Targeting"
    end
    if reason == "requires-mounted" then
        return "Requires Mounted Combat"
    end
    if reason == "conditions" then
        return ensureString(conditionFailureText, "Requirements not met")
    end

    return "Unavailable"
end

local function isBossCaster(casterUnit)
    local eventUnitClass = Addon.Internal
        and Addon.Internal.Database
        and Addon.Internal.Database.Classes
        and Addon.Internal.Database.Classes.EventUnit
        or nil
    if eventUnitClass and eventUnitClass.IsBoss then
        return eventUnitClass.IsBoss(casterUnit)
    end

    return type(casterUnit) == "table" and casterUnit.boss == true
end

local function isControlledNpcCaster(self, activation)
    if type(self) ~= "table" or type(activation) ~= "table" then
        return false
    end

    local casterUnit = activation.casterUnit
    if type(casterUnit) ~= "table" or casterUnit.isPlayer == true then
        return false
    end

    local controlContext = self.GetActionBarControlContext and self:GetActionBarControlContext(activation.eventState) or nil
    if type(controlContext) ~= "table" or controlContext.isControlled ~= true then
        return false
    end

    return tonumber(controlContext.controlledUnit and controlContext.controlledUnit.eventID) == tonumber(casterUnit.eventID)
end

local function evaluateSpellConditionState(self, activation)
    if type(activation) ~= "table" or type(activation.spell) ~= "table" then
        return {
            passed = true,
            failureText = "",
        }
    end

    local context = Conditions.BuildContext and Conditions:BuildContext("spell", activation.spell, {
        ownerRef = activation.spellRef,
        spellRef = activation.spellRef,
        sessionState = activation.sessionState,
        eventState = activation.eventState,
        casterUnit = activation.casterUnit,
        targetUnit = activation.targetUnit or (self.ResolveSpellActivationTargetUnit and self:ResolveSpellActivationTargetUnit(activation) or nil),
    }) or nil
    local authored = Conditions.EvaluateList and Conditions:EvaluateList(activation.spell.conditions, context) or {
        passed = true,
        failureText = "",
    }
    if authored.passed ~= true then
        return authored
    end

    local resourceConditions = {}
    if not isControlledNpcCaster(self, activation) then
        resourceConditions = Conditions.BuildSpellResourceConditions and Conditions:BuildSpellResourceConditions(activation.spell, {
            allowHealth = false,
        }) or {}
    end
    return Conditions.EvaluateList and Conditions:EvaluateList(resourceConditions, context) or {
        passed = true,
        failureText = "",
    }
end

local function advanceChargeState(entry, advancedTurns)
    local normalizedTurns = math.max(0, math.floor(tonumber(advancedTurns) or 0))
    if type(entry) ~= "table" or normalizedTurns <= 0 then
        return false, entry
    end

    local changed = false
    local currentCharges = math.max(0, math.floor(tonumber(entry.currentCharges) or 0))
    local maxCharges = math.max(1, math.floor(tonumber(entry.maxCharges) or 1))
    local cooldownTurns = math.max(1, math.floor(tonumber(entry.cooldownTurns) or 1))
    local remainingTurns = math.max(0, math.floor(tonumber(entry.remainingTurns) or 0))

    for _ = 1, normalizedTurns do
        if currentCharges >= maxCharges and remainingTurns <= 0 then
            break
        end

        if remainingTurns > 0 then
            remainingTurns = remainingTurns - 1
            changed = true
        end

        if remainingTurns <= 0 and currentCharges < maxCharges then
            currentCharges = math.min(maxCharges, currentCharges + 1)
            changed = true
            if currentCharges < maxCharges then
                remainingTurns = cooldownTurns
            else
                remainingTurns = 0
            end
        end
    end

    entry.currentCharges = currentCharges
    entry.maxCharges = maxCharges
    entry.remainingTurns = remainingTurns
    entry.cooldownTurns = cooldownTurns
    return changed, entry
end

local function advanceStandardCooldownState(entry, advancedTurns)
    local normalizedTurns = math.max(0, math.floor(tonumber(advancedTurns) or 0))
    if type(entry) ~= "table" or normalizedTurns <= 0 then
        return false, entry
    end

    local remainingTurns = math.max(0, math.floor(tonumber(entry.remainingTurns) or 0))
    if remainingTurns <= 0 then
        entry.remainingTurns = 0
        return false, entry
    end

    local nextRemainingTurns = math.max(0, remainingTurns - normalizedTurns)
    if nextRemainingTurns == remainingTurns then
        return false, entry
    end

    if nextRemainingTurns <= 0 then
        entry.remainingTurns = 0
        return true, entry
    end

    entry.remainingTurns = nextRemainingTurns
    return true, entry
end

local function advanceSpellLockoutState(entry, advancedTurns)
    local normalizedTurns = math.max(0, math.floor(tonumber(advancedTurns) or 0))
    if type(entry) ~= "table" or normalizedTurns <= 0 then
        return false, entry
    end

    local remainingTurns = getSpellLockoutRemaining(entry)
    if remainingTurns <= 0 then
        entry.lockoutRemainingTurns = 0
        return false, entry
    end

    local nextRemainingTurns = math.max(0, remainingTurns - normalizedTurns)
    if nextRemainingTurns == remainingTurns then
        return false, entry
    end

    entry.lockoutRemainingTurns = nextRemainingTurns
    return true, entry
end

function Client:QueueActionBarRefresh(reason)
    -- Invalidate spell ref caches since action bars changed
    self._cachedSpellRefs = nil
    self._cachedPetSpellRefs = nil
    self._cachedCooldownSpellMetadata = nil
    self._cachedPetCooldownSpellMetadata = nil

    local normalizedReason = tostring(reason or self.PendingActionBarRefreshReason or "cooldown")
    local eventState = self.GetEventState and self:GetEventState() or nil
    local startupPending = type(eventState) == "table"
        and eventState.active == true
        and (eventState.unitsReady ~= true or eventState.startupReady ~= true)
    if startupPending and normalizedReason ~= "startup-ready" then
        self.PendingStartupActionBarRefresh = true
        self.PendingStartupActionBarRefreshReason = tostring(
            self.PendingStartupActionBarRefreshReason or normalizedReason
        )
        return true
    end

    if normalizedReason == "startup-ready" and type(self.PendingStartupActionBarRefreshReason) == "string" then
        normalizedReason = self.PendingStartupActionBarRefreshReason
    end
    self.PendingStartupActionBarRefresh = false
    self.PendingStartupActionBarRefreshReason = nil

    if type(self.MarkActionBarSlotsDirty) == "function" then
        return self:MarkActionBarSlotsDirty(normalizedReason)
    end

    self.PendingActionBarRefreshReason = normalizedReason
    self.ActionBarRefreshQueued = true
    if type(self.QueueVisualRefreshFlush) == "function" then
        return self:QueueVisualRefreshFlush()
    end

    enqueueActionBarWork(function(targetClient, refreshReason)
        if type(targetClient) ~= "table" then
            return
        end

        targetClient.ActionBarRefreshQueued = false
        targetClient.PendingActionBarRefreshReason = nil
        if type(targetClient.RefreshActionBarWidget) == "function" then
            targetClient:RefreshActionBarWidget(refreshReason or "cooldown")
        end
    end, self, self.PendingActionBarRefreshReason or "cooldown")

    return true
end

function Spellcasting.GetEventCooldownBucket(self, eventId, createIfMissing)
    local normalizedEventId = normalizeEventId(eventId)
    if normalizedEventId == "" then
        return nil
    end

    self.CooldownsByEventId = self.CooldownsByEventId or {}
    local bucket = self.CooldownsByEventId[normalizedEventId]
    if bucket or not createIfMissing then
        return bucket
    end

    bucket = {}
    self.CooldownsByEventId[normalizedEventId] = bucket
    return bucket
end

function Spellcasting.GetUnitCooldownState(self, eventId, unitEventId, createIfMissing)
    local numericUnitEventId = normalizeUnitEventId(unitEventId)
    if not numericUnitEventId then
        return nil
    end

    local bucket = Spellcasting.GetEventCooldownBucket(self, eventId, createIfMissing)
    if not bucket then
        return nil
    end

    local unitState = bucket[numericUnitEventId]
    if unitState or not createIfMissing then
        return unitState
    end

    unitState = {
        spells = {},
        channelCooldowns = {},
        lastAdvancedTurnNumber = 0,
    }
    bucket[numericUnitEventId] = unitState
    return unitState
end

function Spellcasting.ResetCooldownState(self, eventId)
    local normalizedEventId = normalizeEventId(eventId)
    if normalizedEventId ~= "" then
        if type(self.CooldownsByEventId) ~= "table" or self.CooldownsByEventId[normalizedEventId] == nil then
            return false
        end

        self.CooldownsByEventId[normalizedEventId] = nil
        bumpEventTooltipContextRevision(normalizedEventId, nil)
        if type(self.QueueActionBarRefresh) == "function" then
            self:QueueActionBarRefresh("cooldown-reset")
        end
        return true
    end

    local changed = type(self.CooldownsByEventId) == "table" and next(self.CooldownsByEventId) ~= nil
    self.CooldownsByEventId = {}
    if changed and type(self.QueueActionBarRefresh) == "function" then
        bumpAllEventTooltipContextRevisions(self.GetEventState and self:GetEventState() or nil)
        self:QueueActionBarRefresh("cooldown-reset")
    end
    return changed
end

function Spellcasting.PruneCooldownState(self, eventState)
    if type(self) ~= "table" then
        return false
    end

    local state = type(eventState) == "table" and eventState or (self.GetEventState and self:GetEventState() or nil)
    local normalizedEventId = normalizeEventId(state and state.id)
    if normalizedEventId == "" then
        return Spellcasting.ResetCooldownState(self, nil)
    end

    local bucket = Spellcasting.GetEventCooldownBucket(self, normalizedEventId, false)
    if type(bucket) ~= "table" then
        return false
    end

    local tracked = buildTrackedUnitMap(self, state)
    local changed = false
    for unitEventId in pairs(bucket) do
        if tracked[unitEventId] ~= true then
            bucket[unitEventId] = nil
            changed = true
        end
    end

    changed = cleanupEventBucket(self, normalizedEventId, bucket) or changed
    if changed and type(self.QueueActionBarRefresh) == "function" then
        bumpEventTooltipContextRevision(normalizedEventId, nil)
        self:QueueActionBarRefresh("cooldown-prune")
    end

    return changed
end

function Spellcasting.AdvanceCooldownState(self, previousTurnNumber, previousTickNumber)
    local eventState = self.GetEventState and self:GetEventState() or nil
    if not eventState or eventState.active ~= true then
        return false
    end

    local eventId = normalizeEventId(eventState.id)
    if eventId == "" then
        return false
    end

    local timer = startTiming("Cooldown advancement", 8, eventId)

    local currentTurnNumber = math.max(1, math.floor(tonumber(eventState.turnNumber) or 1))
    local currentTickNumber = math.max(1, math.floor(tonumber(eventState.tickNumber) or 1))
    local previousTurn = math.max(0, math.floor(tonumber(previousTurnNumber) or 0))
    local previousTick = math.max(0, math.floor(tonumber(previousTickNumber) or 0))
    if previousTurn == currentTurnNumber and previousTick == currentTickNumber then
        if timer then
            stopTiming(timer, { activeCooldowns = 0, activeCooldownUnits = 0, eventUnits = type(eventState.units) == "table" and #eventState.units or 0 })
        end
        return false
    end

    local bucket = Spellcasting.GetEventCooldownBucket(self, eventId, false)
    local changed = Spellcasting.PruneCooldownState(self, eventState)
    if type(bucket) ~= "table" then
        if timer then
            stopTiming(timer, { activeCooldowns = 0, activeCooldownUnits = 0, eventUnits = type(eventState.units) == "table" and #eventState.units or 0 })
        end
        return changed
    end

    for unitEventId, unitState in pairs(bucket) do
        if type(unitState) == "table" and Spellcasting.IsCasterTurnOnTick and Spellcasting.IsCasterTurnOnTick(eventState, unitEventId) then
            local lastAdvancedTurnNumber = math.max(0, math.floor(tonumber(unitState.lastAdvancedTurnNumber) or 0))
            if currentTurnNumber > lastAdvancedTurnNumber then
                local advancedTurns = currentTurnNumber - lastAdvancedTurnNumber
                unitState.lastAdvancedTurnNumber = currentTurnNumber
                local channelCooldowns = type(unitState.channelCooldowns) == "table" and unitState.channelCooldowns or {}
                unitState.channelCooldowns = channelCooldowns
                for channelId, remaining in pairs(channelCooldowns) do
                    local normalizedChannelId = type(channelId) == "number" and normalizeCooldownChannelId(channelId) or nil
                    local currentRemaining = math.max(0, math.floor(tonumber(remaining) or 0))
                    if not normalizedChannelId or currentRemaining <= 0 then
                        channelCooldowns[channelId] = nil
                        changed = true
                    else
                        local nextRemaining = math.max(0, currentRemaining - advancedTurns)
                        if nextRemaining <= 0 then
                            channelCooldowns[channelId] = nil
                        elseif nextRemaining ~= currentRemaining then
                            channelCooldowns[channelId] = nextRemaining
                        end
                        if nextRemaining ~= currentRemaining then
                            changed = true
                        end
                    end
                end

                for spellRef, spellState in pairs(unitState.spells or {}) do
                    local entryChanged, nextSpellState
                    if spellState and spellState.usesCharges == true then
                        entryChanged, nextSpellState = advanceChargeState(spellState, advancedTurns)
                    else
                        entryChanged, nextSpellState = advanceStandardCooldownState(spellState, advancedTurns)
                    end

                    if entryChanged then
                        changed = true
                    end

                    local lockoutChanged
                    lockoutChanged, nextSpellState = advanceSpellLockoutState(nextSpellState, advancedTurns)
                    if lockoutChanged then
                        changed = true
                    end

                    if nextSpellState and not shouldClearSpellState(nextSpellState) then
                        unitState.spells[spellRef] = nextSpellState
                    else
                        unitState.spells[spellRef] = nil
                    end
                end
            end
        end

        if cleanupUnitState(unitState) then
            bucket[unitEventId] = nil
            changed = true
        end
    end

    cleanupEventBucket(self, eventId, bucket)
    if changed and type(self.QueueActionBarRefresh) == "function" then
        bumpEventTooltipContextRevision(eventId, nil)
        self:QueueActionBarRefresh("cooldown-advance")
    end

    if timer then
        local activeCooldownUnits, activeCooldowns = countCooldownEntries(bucket)
        stopTiming(timer, {
            activeCooldowns = activeCooldowns,
            activeCooldownUnits = activeCooldownUnits,
            eventUnits = type(eventState.units) == "table" and #eventState.units or 0,
        })
    end
    return changed
end

function Spellcasting.ApplyLocalSpellCooldown(self, eventState, casterUnit, spellRef, spell)
    local normalizedEventId = normalizeEventId(eventState and eventState.id)
    local numericCasterEventId = normalizeUnitEventId(casterUnit and casterUnit.eventID)
    if normalizedEventId == "" or not numericCasterEventId or type(spellRef) ~= "string" or spellRef == "" or type(spell) ~= "table" then
        return false
    end

    local unitState = Spellcasting.GetUnitCooldownState(self, normalizedEventId, numericCasterEventId, true)
    if not unitState then
        return false
    end

    local changed = false
    unitState.lastAdvancedTurnNumber = math.max(
        math.floor(tonumber(unitState.lastAdvancedTurnNumber) or 0),
        math.max(1, math.floor(tonumber(eventState.turnNumber) or 1))
    )

    if spell.useCooldownCharges == true then
        local maxCharges = normalizeChargeCount(spell)
        local cooldownTurns = normalizeCooldownTurns(spell, true)
        local spellState = cloneSpellState(getSpellCooldownState(unitState, spellRef)) or {
            remainingTurns = 0,
            currentCharges = maxCharges,
            maxCharges = maxCharges,
            usesCharges = true,
            cooldownTurns = cooldownTurns,
        }

        spellState.maxCharges = maxCharges
        spellState.cooldownTurns = cooldownTurns
        spellState.currentCharges = math.max(0, math.min(maxCharges, math.floor(tonumber(spellState.currentCharges) or maxCharges)))
        spellState.usesCharges = true
        spellState.lockoutRemainingTurns = getSpellLockoutRemaining(spellState)

        local nextCharges = math.max(0, spellState.currentCharges - 1)
        if nextCharges ~= spellState.currentCharges then
            changed = true
        end
        spellState.currentCharges = nextCharges

        if spellState.currentCharges < spellState.maxCharges then
            local nextRemainingTurns = math.max(0, math.floor(tonumber(spellState.remainingTurns) or 0))
            if nextRemainingTurns <= 0 then
                nextRemainingTurns = cooldownTurns
            end
            if spellState.remainingTurns ~= nextRemainingTurns then
                changed = true
            end
            spellState.remainingTurns = nextRemainingTurns
        else
            spellState.remainingTurns = 0
        end

        setSpellCooldownState(unitState, spellRef, spellState)
    else
        local cooldownTurns = normalizeCooldownTurns(spell, false)
        if cooldownTurns ~= nil and cooldownTurns > 0 then
            local spellState = cloneSpellState(getSpellCooldownState(unitState, spellRef)) or {
                remainingTurns = 0,
                usesCharges = false,
            }
            if spellState.remainingTurns ~= cooldownTurns or spellState.usesCharges ~= false then
                changed = true
            end
            spellState.remainingTurns = cooldownTurns
            spellState.lockoutRemainingTurns = getSpellLockoutRemaining(spellState)
            spellState.currentCharges = nil
            spellState.maxCharges = nil
            spellState.usesCharges = false
            spellState.cooldownTurns = nil
            setSpellCooldownState(unitState, spellRef, spellState)
        end
    end

    local triggerCooldownTurns = math.max(0, math.floor(tonumber(normalizeCooldownTurns(spell, false)) or 0))
    local cooldownGroup = normalizeCooldownGroup(spell.cooldownGroup)
    local cooldownMetadata = cooldownGroup
        and getCooldownSpellMetadata(self, eventState, casterUnit)
        or nil
    if cooldownGroup and triggerCooldownTurns > 0 then
        local casterSpellRefs = cooldownMetadata and cooldownMetadata.cooldownGroups and cooldownMetadata.cooldownGroups[cooldownGroup] or {}
        for index = 1, #casterSpellRefs do
            local candidateSpellRef = casterSpellRefs[index]
            if candidateSpellRef ~= spellRef then
                local candidateSpell = cooldownMetadata and cooldownMetadata.spellByRef and cooldownMetadata.spellByRef[candidateSpellRef] or nil
                if type(candidateSpell) == "table" and normalizeCooldownGroup(candidateSpell.cooldownGroup) == cooldownGroup then
                    changed = applyExternalSpellLockout(unitState, candidateSpellRef, candidateSpell, triggerCooldownTurns) or changed
                end
            end
        end
    end

    local channelId, channel = resolveSpellCooldownChannel(spell)
    if channelId and channel and channel.enabled == true and channel.triggersGCD == true then
        unitState.channelCooldowns = type(unitState.channelCooldowns) == "table" and unitState.channelCooldowns or {}
        if math.max(0, math.floor(tonumber(unitState.channelCooldowns[channelId]) or 0)) ~= 1 then
            unitState.channelCooldowns[channelId] = 1
            changed = true
        end
    end

    if changed and type(self.QueueActionBarRefresh) == "function" then
        bumpEventTooltipContextRevision(normalizedEventId, numericCasterEventId)
        self:QueueActionBarRefresh("cooldown-apply")
    end

    return changed
end

local function findEventUnitById(units, targetEventId)
    local numericTargetEventId = tonumber(targetEventId) or 0
    if numericTargetEventId <= 0 then
        return nil
    end

    for index = 1, #(units or {}) do
        local unit = units[index]
        if tonumber(unit and unit.eventID) == numericTargetEventId then
            return unit
        end
    end

    return nil
end

local function findRecentCandidateUnit(self, candidates)
    local candidateList = type(candidates) == "table" and candidates or {}
    local history = type(self) == "table" and self.TargetHistoryEventIds or nil
    for historyIndex = 1, #(history or {}) do
        local recentEventId = tonumber(history[historyIndex]) or 0
        if recentEventId > 0 then
            for candidateIndex = 1, #candidateList do
                local candidate = candidateList[candidateIndex]
                if tonumber(candidate and candidate.eventID) == recentEventId then
                    return candidate
                end
            end
        end
    end

    return candidateList[1]
end

local function buildActivationGuard(self, activation, unitState)
    if type(self) ~= "table" or type(activation) ~= "table" then
        return nil
    end

    local eventState = activation.eventState
    local casterUnit = activation.casterUnit
    local auraManager = getAuraManager()
    local controlState = auraManager
        and type(auraManager.BuildControlState) == "function"
        and auraManager:BuildControlState(eventState, casterUnit and casterUnit.eventID)
        or nil

    return {
        spellRef = activation.spellRef,
        eventId = normalizeEventId(eventState and eventState.id),
        turnNumber = math.max(0, math.floor(tonumber(eventState and eventState.turnNumber) or 0)),
        tickNumber = math.max(0, math.floor(tonumber(eventState and eventState.tickNumber) or 0)),
        totalTicks = math.max(0, math.floor(tonumber(eventState and eventState.totalTicks) or 0)),
        casterEventId = normalizeUnitEventId(casterUnit and casterUnit.eventID),
        casterResourceSignature = buildResourceSignature(casterUnit and casterUnit.resources),
        cooldownSignature = buildUnitCooldownSignature(unitState),
        hasActiveCast = self.GetSpellcastEntry and self:GetSpellcastEntry(
            normalizeEventId(eventState and eventState.id),
            normalizeUnitEventId(casterUnit and casterUnit.eventID) or 0
        ) ~= nil,
        controlSignature = buildSignature(
            controlState and controlState.preventCasting == true and 1 or 0,
            controlState and controlState.cancelOnDamage == true and 1 or 0,
            controlState and controlState.forceAutoHitAgainstTarget == true and 1 or 0,
            tonumber(controlState and controlState.movementRangeOverride) or 0
        ),
        configurationRevision = math.max(0, math.floor(tonumber(Addon.Internal and Addon.Internal.ConfigurationRevision) or 0)),
    }
end

local function isActivationGuardValid(self, snapshot)
    if type(self) ~= "table" or type(snapshot) ~= "table" or type(snapshot.guard) ~= "table" then
        return false
    end

    local guard = snapshot.guard
    local eventState = self.GetEventState and self:GetEventState() or nil
    if type(eventState) ~= "table" or eventState.active ~= true then
        return false
    end
    if normalizeEventId(eventState.id) ~= tostring(guard.eventId or "") then
        return false
    end
    if math.max(0, math.floor(tonumber(eventState.turnNumber) or 0)) ~= math.max(0, math.floor(tonumber(guard.turnNumber) or 0))
        or math.max(0, math.floor(tonumber(eventState.tickNumber) or 0)) ~= math.max(0, math.floor(tonumber(guard.tickNumber) or 0))
        or math.max(0, math.floor(tonumber(eventState.totalTicks) or 0)) ~= math.max(0, math.floor(tonumber(guard.totalTicks) or 0))
    then
        return false
    end

    local casterEventId = normalizeUnitEventId(guard.casterEventId)
    local casterUnit = casterEventId and findEventUnitById(eventState.units, casterEventId) or nil
    if type(casterUnit) ~= "table" then
        return false
    end
    if buildResourceSignature(casterUnit.resources) ~= tostring(guard.casterResourceSignature or "") then
        return false
    end

    local unitState = Spellcasting.GetUnitCooldownState(self, normalizeEventId(eventState.id), casterEventId, false)
    if buildUnitCooldownSignature(unitState) ~= tostring(guard.cooldownSignature or "") then
        return false
    end

    local hasActiveCast = self.GetSpellcastEntry and self:GetSpellcastEntry(normalizeEventId(eventState.id), casterEventId) ~= nil or false
    if hasActiveCast ~= (guard.hasActiveCast == true) then
        return false
    end

    local auraManager = getAuraManager()
    local controlState = auraManager
        and type(auraManager.BuildControlState) == "function"
        and auraManager:BuildControlState(eventState, casterEventId)
        or nil
    local controlSignature = buildSignature(
        controlState and controlState.preventCasting == true and 1 or 0,
        controlState and controlState.cancelOnDamage == true and 1 or 0,
        controlState and controlState.forceAutoHitAgainstTarget == true and 1 or 0,
        tonumber(controlState and controlState.movementRangeOverride) or 0
    )
    if controlSignature ~= tostring(guard.controlSignature or "") then
        return false
    end

    local configurationRevision = math.max(0, math.floor(tonumber(Addon.Internal and Addon.Internal.ConfigurationRevision) or 0))
    return configurationRevision == math.max(0, math.floor(tonumber(guard.configurationRevision) or 0))
end

local function buildTargetCandidateState(self, activation, includeTargetCandidates)
    local canCast = true
    local reason = nil
    local targetCandidates = nil
    local targetGroups = activation.targetGroups or {}
    local targetCandidatesByGroup = {}
    local initialTargetUnitByGroup = {}

    if type(self.BuildSpellActivationTargetCandidates) ~= "function" then
        return canCast, reason, targetGroups, targetCandidates, targetCandidatesByGroup, initialTargetUnitByGroup
    end

    if #targetGroups > 0 then
        for index = 1, #targetGroups do
            local group = targetGroups[index]
            local candidates = self:BuildSpellActivationTargetCandidates(activation, group)
            if includeTargetCandidates == true then
                targetCandidatesByGroup[group.key] = candidates
                if index == 1 then
                    targetCandidates = candidates
                end
            end

            local initialTargetUnit = findRecentCandidateUnit(self, candidates)
            if type(initialTargetUnit) == "table" then
                initialTargetUnitByGroup[group.key] = initialTargetUnit
                if index == 1 and type(activation.targetUnit) ~= "table" then
                    activation.targetUnit = initialTargetUnit
                end
            end

            if #(candidates or {}) == 0
                and group.policy
                and (group.policy.requiresTarget == true
                    or group.policy.type == "all_allies"
                    or group.policy.type == "raid_marker")
            then
                canCast = false
                reason = "no-targets"
                break
            end
        end
    else
        local candidates = self:BuildSpellActivationTargetCandidates(activation)
        if includeTargetCandidates == true then
            targetCandidates = candidates
        end
        if activation.policy and activation.policy.type ~= "caster"
            and (activation.policy.requiresTarget == true
                or activation.policy.type == "all_allies"
                or activation.policy.type == "raid_marker")
            and (activation.policy.type == "all_allies"
                or math.max(0, tonumber(activation.policy.maxTargets) or 0) > 0)
            and #(candidates or {}) == 0
        then
            canCast = false
            reason = "no-targets"
        elseif activation.policy and activation.policy.type == "pet" and #(candidates or {}) == 0 then
            canCast = false
            reason = "no-targets"
        end

        local initialTargetUnit = findRecentCandidateUnit(self, candidates)
        if type(initialTargetUnit) == "table" then
            activation.targetUnit = activation.targetUnit or initialTargetUnit
            initialTargetUnitByGroup.default = initialTargetUnit
        end
    end

    return canCast, reason, targetGroups, targetCandidates, targetCandidatesByGroup, initialTargetUnitByGroup
end

function Spellcasting.BuildSpellActivationSnapshot(self, spellRef, options)
    options = type(options) == "table" and options or {}

    local sessionState = self.GetState and self:GetState() or nil
    local eventState = self.GetEventState and self:GetEventState() or nil
    if not sessionState or sessionState.active ~= true or not eventState or eventState.active ~= true then
        return nil
    end

    local activation = self.ResolveSpellActivation and self:ResolveSpellActivation(spellRef) or nil
    if not activation then
        return nil
    end

    local spellRankContext = type(Spellcasting.ResolveSpellRankContext) == "function"
        and Spellcasting.ResolveSpellRankContext(activation.spell, {
            casterUnit = activation.casterUnit,
            eventState = activation.eventState,
        })
        or nil

    local eventId = normalizeEventId(activation.eventState and activation.eventState.id)
    local casterEventId = normalizeUnitEventId(activation.casterUnit and activation.casterUnit.eventID)
    local unitState = casterEventId and Spellcasting.GetUnitCooldownState(self, eventId, casterEventId, false) or nil
    local spellState = getSpellCooldownState(unitState, activation.spellRef)
    local usesCharges = activation.spell and activation.spell.useCooldownCharges == true or false
    local maxCharges = usesCharges and normalizeChargeCount(activation.spell) or nil
    local currentCharges = usesCharges and maxCharges or nil
    local rechargeRemaining = 0
    local lockoutRemaining = 0
    if spellState then
        rechargeRemaining = math.max(0, math.floor(tonumber(spellState.remainingTurns) or 0))
        lockoutRemaining = getSpellLockoutRemaining(spellState)
        if usesCharges then
            currentCharges = math.max(0, math.floor(tonumber(spellState.currentCharges) or maxCharges or 0))
            maxCharges = math.max(1, math.floor(tonumber(spellState.maxCharges) or maxCharges or 1))
        end
    end

    local cooldownRemaining = math.max(rechargeRemaining, lockoutRemaining)
    if usesCharges and currentCharges ~= nil and currentCharges > 0 and lockoutRemaining > 0 then
        cooldownRemaining = lockoutRemaining
    end

    local cooldownChannelId, cooldownChannel = resolveSpellCooldownChannel(activation.spell)
    local cooldownChannelName = cooldownChannel and cooldownChannel.name or nil
    local cooldownChannelConfigured = cooldownChannelId ~= nil
        and type(cooldownChannel) == "table"
        and cooldownChannel.enabled == true
    local cooldownChannelTriggersGCD = cooldownChannel
        and cooldownChannel.enabled == true
        and cooldownChannel.triggersGCD == true
        or false
    local cooldownChannelCanUseOffTurn = cooldownChannelConfigured
        and cooldownChannel.canUseOffTurn == true
        or false
    local channelCooldownRemaining = math.max(
        0,
        math.floor(tonumber(
            unitState
                and type(unitState.channelCooldowns) == "table"
                and cooldownChannelId
                and unitState.channelCooldowns[cooldownChannelId]
                or 0
        ) or 0)
    )
    local reason = nil
    local canCast = true
    local conditionState = {
        passed = true,
        failureText = "",
    }
    local startCosts = Spellcasting.GetSpellResourceCostsForPhase and Spellcasting.GetSpellResourceCostsForPhase(activation.spell, "on_cast_start") or {}
    local endCosts = Spellcasting.GetSpellResourceCostsForPhase and Spellcasting.GetSpellResourceCostsForPhase(activation.spell, "on_cast_end") or {}
    local canAffordStartCosts = true
    local canAffordEndCosts = true

    if type(spellRankContext) ~= "table" then
        canCast = false
        reason = "spell-rank-context-unavailable"
    elseif spellRankContext.eligible ~= true then
        canCast = false
        reason = "level-required"
    elseif not cooldownChannelConfigured then
        canCast = false
        reason = "invalid-cooldown-channel"
    elseif not isBossCaster(activation.casterUnit)
        and not (Spellcasting.IsCasterTurnOnTick and Spellcasting.IsCasterTurnOnTick(activation.eventState, activation.casterUnit.eventID))
        and not cooldownChannelCanUseOffTurn
    then
        canCast = false
        reason = "not-your-turn"
    end

    if canCast and self.GetSpellcastEntry and self:GetSpellcastEntry(eventId, activation.casterUnit.eventID) ~= nil then
        canCast = false
        reason = "casting"
    end

    if canCast then
        local auraManager = getAuraManager()
        if auraManager
            and type(auraManager.CanUnitCast) == "function"
            and auraManager:CanUnitCast(activation.eventState, activation.casterUnit.eventID) ~= true
        then
            canCast = false
            reason = "casting"
        end
    end

    if canCast and activation.spell and activation.spell.mountedCombatOnly == true then
        local localEventUnit = self.ResolveLocalEventUnit and self:ResolveLocalEventUnit(activation.eventState) or nil
        if not localEventUnit
            or tonumber(localEventUnit.eventID) ~= tonumber(activation.casterUnit and activation.casterUnit.eventID)
            or not (Profile.IsMounted and Profile.IsMounted())
        then
            canCast = false
            reason = "requires-mounted"
        end
    end

    if canCast and cooldownChannelTriggersGCD and channelCooldownRemaining > 0 then
        canCast = false
        reason = "channel-cooldown"
    end

    if canCast and lockoutRemaining > 0 then
        canCast = false
        reason = "cooldown"
    end

    if canCast and usesCharges and currentCharges ~= nil and currentCharges <= 0 then
        canCast = false
        reason = "no-charges"
    end

    if canCast and not usesCharges and rechargeRemaining > 0 then
        canCast = false
        reason = "cooldown"
    end

    if canCast then
        conditionState = evaluateSpellConditionState(self, activation)
        if conditionState and conditionState.passed ~= true then
            canCast = false
            reason = "conditions"
        end
    end

    if canCast and #startCosts > 0 then
        if Spellcasting.CanAffordResourceCosts then
            canAffordStartCosts = Spellcasting.CanAffordResourceCosts(activation.casterUnit, startCosts)
        else
            canAffordStartCosts = true
        end
        if canAffordStartCosts ~= true then
            canCast = false
            reason = "insufficient-resources"
        end
    end

    if canCast and #endCosts > 0 then
        if Spellcasting.CanAffordResourceCosts then
            canAffordEndCosts = Spellcasting.CanAffordResourceCosts(activation.casterUnit, endCosts)
        else
            canAffordEndCosts = true
        end
        if canAffordEndCosts ~= true then
            canCast = false
            reason = "insufficient-resources"
        end
    end

    if canCast and type(activation.targetingError) == "string" and activation.targetingError ~= "" then
        canCast = false
        reason = "invalid-targeting"
    end

    local targetCandidates = nil
    local targetCandidatesByGroup = {}
    local initialTargetUnitByGroup = {}
    if canCast then
        local targetCanCast, targetReason, targetGroups, firstCandidates, candidatesByGroup, initialTargets = buildTargetCandidateState(
            self,
            activation,
            options.includeTargetCandidates == true
        )
        activation.targetGroups = targetGroups
        targetCandidates = firstCandidates
        targetCandidatesByGroup = candidatesByGroup
        initialTargetUnitByGroup = initialTargets
        if targetCanCast ~= true then
            canCast = false
            reason = targetReason
        end
    end

    local snapshot = {
        canCast = canCast,
        reason = reason or "ready",
        sessionState = activation.sessionState,
        eventState = activation.eventState,
        casterUnit = activation.casterUnit,
        dataset = activation.dataset,
        spell = activation.spell,
        spellRef = activation.spellRef,
        spellRankContext = spellRankContext,
        spellRank = spellRankContext and spellRankContext.rank or nil,
        spellRankMultiplier = spellRankContext and spellRankContext.multiplier or 1,
        casterLevel = spellRankContext and spellRankContext.casterLevel or nil,
        learnLevel = spellRankContext and spellRankContext.learnLevel or nil,
        rankInterval = spellRankContext and spellRankContext.rankInterval or nil,
        nextRankLevel = spellRankContext and spellRankContext.nextRankLevel or nil,
        useSpellRanks = spellRankContext and spellRankContext.useSpellRanks == true or false,
        usesRanks = not spellRankContext or spellRankContext.usesRanks ~= false,
        policy = activation.policy,
        targetUnit = activation.targetUnit,
        targetGroups = activation.targetGroups or {},
        cooldownRemaining = cooldownRemaining,
        rechargeRemaining = rechargeRemaining,
        lockoutRemaining = lockoutRemaining,
        cooldownChannelId = cooldownChannelId,
        cooldownChannelName = cooldownChannelName,
        cooldownChannelTriggersGCD = cooldownChannelTriggersGCD,
        cooldownChannelCanUseOffTurn = cooldownChannelCanUseOffTurn,
        channelCooldownRemaining = channelCooldownRemaining,
        currentCharges = currentCharges,
        maxCharges = maxCharges,
        targetCandidates = targetCandidates,
        targetCandidatesByGroup = targetCandidatesByGroup,
        initialTargetUnitByGroup = initialTargetUnitByGroup,
        startCosts = startCosts,
        endCosts = endCosts,
        conditionState = conditionState,
        canAffordStartCosts = canAffordStartCosts == true,
        canAffordEndCosts = canAffordEndCosts == true,
    }
    snapshot.guard = buildActivationGuard(self, activation, unitState)
    return snapshot
end

function Spellcasting.IsSpellActivationSnapshotValid(self, snapshot)
    return isActivationGuardValid(self, snapshot)
end

function Spellcasting.ResolveSpellActivationState(self, spellRef, options)
    if type(options) ~= "table" then
        options = {}
    end

    local sessionState = self.GetState and self:GetState() or nil
    local eventState = self.GetEventState and self:GetEventState() or nil
    if not sessionState or sessionState.active ~= true or not eventState or eventState.active ~= true then
        return {
            canCast = false,
            reason = "inactive",
            eventState = eventState,
            casterUnit = nil,
            dataset = nil,
            spell = nil,
            spellRef = spellRef,
            cooldownRemaining = 0,
            cooldownChannelId = nil,
            cooldownChannelName = nil,
            cooldownChannelCanUseOffTurn = false,
            channelCooldownRemaining = 0,
            currentCharges = nil,
            maxCharges = nil,
            cooldownText = "Unavailable",
            failureText = "Unavailable",
        }
    end

    local snapshot = nil
    if type(options.snapshot) == "table" and Spellcasting.IsSpellActivationSnapshotValid(self, options.snapshot) then
        snapshot = options.snapshot
    else
        snapshot = Spellcasting.BuildSpellActivationSnapshot(self, spellRef, {
            includeTargetCandidates = options.includeTargetCandidates == true,
        })
    end
    if not snapshot then
        return {
            canCast = false,
            reason = "invalid-spell",
            eventState = eventState,
            casterUnit = nil,
            dataset = nil,
            spell = nil,
            spellRef = spellRef,
            cooldownRemaining = 0,
            cooldownChannelId = nil,
            cooldownChannelName = nil,
            cooldownChannelCanUseOffTurn = false,
            channelCooldownRemaining = 0,
            currentCharges = nil,
            maxCharges = nil,
            cooldownText = "Unavailable",
            failureText = "Unknown Spell",
        }
    end

    local state = {
        canCast = snapshot.canCast == true,
        reason = snapshot.reason or "ready",
        sessionState = snapshot.sessionState,
        eventState = snapshot.eventState,
        casterUnit = snapshot.casterUnit,
        dataset = snapshot.dataset,
        spell = snapshot.spell,
        spellRef = snapshot.spellRef,
        spellRankContext = snapshot.spellRankContext,
        spellRank = snapshot.spellRank,
        spellRankMultiplier = snapshot.spellRankMultiplier,
        casterLevel = snapshot.casterLevel,
        learnLevel = snapshot.learnLevel,
        rankInterval = snapshot.rankInterval,
        nextRankLevel = snapshot.nextRankLevel,
        useSpellRanks = snapshot.useSpellRanks == true,
        usesRanks = snapshot.usesRanks ~= false,
        policy = snapshot.policy,
        targetUnit = snapshot.targetUnit,
        targetGroups = snapshot.targetGroups or {},
        cooldownRemaining = snapshot.cooldownRemaining,
        rechargeRemaining = snapshot.rechargeRemaining,
        lockoutRemaining = snapshot.lockoutRemaining,
        cooldownChannelId = snapshot.cooldownChannelId,
        cooldownChannelName = snapshot.cooldownChannelName,
        cooldownChannelTriggersGCD = snapshot.cooldownChannelTriggersGCD == true,
        cooldownChannelCanUseOffTurn = snapshot.cooldownChannelCanUseOffTurn == true,
        channelCooldownRemaining = snapshot.channelCooldownRemaining,
        currentCharges = snapshot.currentCharges,
        maxCharges = snapshot.maxCharges,
        targetCandidates = options.includeTargetCandidates == true and snapshot.targetCandidates or nil,
        targetCandidatesByGroup = options.includeTargetCandidates == true and snapshot.targetCandidatesByGroup or {},
        initialTargetUnitByGroup = snapshot.initialTargetUnitByGroup or {},
        conditionState = snapshot.conditionState,
        canAffordStartCosts = snapshot.canAffordStartCosts == true,
        canAffordEndCosts = snapshot.canAffordEndCosts == true,
        startCosts = snapshot.startCosts,
        endCosts = snapshot.endCosts,
        activationSnapshot = snapshot,
    }

    if options.includeText ~= false then
        state.cooldownText = buildCooldownText(state)
        if state.canCast then
            state.failureText = ""
        elseif state.reason == "level-required" then
            state.failureText = ("Requires Level %d"):format(math.max(1, math.floor(tonumber(snapshot.learnLevel) or 1)))
        else
            state.failureText = buildFailureReason(
                state.reason,
                state.cooldownRemaining,
                state.cooldownChannelName,
                state.channelCooldownRemaining,
                snapshot.conditionState and snapshot.conditionState.failureText or ""
            )
        end
    else
        state.cooldownText = nil
        state.failureText = nil
    end
    state.conditionFailureText = snapshot.conditionState and snapshot.conditionState.failureText or ""
    return state
end

function Client:ResetCooldownState(eventId)
    return Spellcasting.ResetCooldownState and Spellcasting.ResetCooldownState(self, eventId) or false
end

function Client:AdvanceCooldownState(previousTurnNumber, previousTickNumber)
    return Spellcasting.AdvanceCooldownState and Spellcasting.AdvanceCooldownState(self, previousTurnNumber, previousTickNumber) or false
end

function Client:PruneCooldownState(eventState)
    return Spellcasting.PruneCooldownState and Spellcasting.PruneCooldownState(self, eventState) or false
end

function Client:ApplyLocalSpellCooldown(eventState, casterUnit, spellRef, spell)
    return Spellcasting.ApplyLocalSpellCooldown and Spellcasting.ApplyLocalSpellCooldown(self, eventState, casterUnit, spellRef, spell) or false
end

function Client:ResolveSpellActivationSnapshot(spellRef, options)
    return Spellcasting.BuildSpellActivationSnapshot and Spellcasting.BuildSpellActivationSnapshot(self, spellRef, options) or nil
end

function Client:ResolveSpellActivationRuntimeState(spellRef, options)
    local resolvedOptions = type(options) == "table" and options or {}
    resolvedOptions.includeText = false
    resolvedOptions.includeTargetCandidates = false
    return Spellcasting.ResolveSpellActivationState and Spellcasting.ResolveSpellActivationState(self, spellRef, resolvedOptions) or nil
end

function Client:ResolveSpellActivationState(spellRef, options)
    return Spellcasting.ResolveSpellActivationState and Spellcasting.ResolveSpellActivationState(self, spellRef, options) or nil
end

return Spellcasting
