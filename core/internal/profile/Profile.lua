local _, Addon = ...

Addon.Internal = Addon.Internal or {}
Addon.Internal.Profile = Addon.Internal.Profile or {}

local Profile = Addon.Internal.Profile

local Database = Addon.Internal.Database or {}
local TraitClass = Database.Classes and Database.Classes.Trait or {}
local Equipment = Profile.Equipment or {}
local Resolver = Profile.Resolver or {}
local Runtime = Addon.Internal and Addon.Internal.Runtime or {}
local RECIPE_PROFILE_INTERNAL_TRACE = false

Profile._skillChangeListeners = Profile._skillChangeListeners or {}
Profile._nextSkillChangeListenerId = Profile._nextSkillChangeListenerId or 0

local function getItemClass()
    return Addon.Internal and Addon.Internal.Database and Addon.Internal.Database.Classes and Addon.Internal.Database.Classes.Item or nil
end

local function ensureString(value)
    if value == nil then
        return ""
    end

    return tostring(value)
end

local function normalizeSkillLevel(value)
    return math.max(0, math.floor(tonumber(value) or 0))
end

local function notifySkillChangeListeners(skillRef, previousLevel, updatedLevel)
    local actualGain = updatedLevel - previousLevel
    if actualGain <= 0 then
        return
    end

    local payload = {
        skillRef = skillRef,
        previousLevel = previousLevel,
        updatedLevel = updatedLevel,
        amount = actualGain,
        source = "profile-skill-change",
    }
    for _, listener in pairs(Profile._skillChangeListeners or {}) do
        if type(listener) == "function" then
            pcall(listener, payload)
        end
    end
end

local function getTimingMilliseconds()
    if type(debugprofilestop) == "function" then
        return tonumber(debugprofilestop()) or 0
    end
    if type(GetTimePreciseSec) == "function" then
        return (tonumber(GetTimePreciseSec()) or 0) * 1000
    end
    return 0
end

local function getElapsedMilliseconds(startedAt)
    local started = tonumber(startedAt) or 0
    return math.max(0, getTimingMilliseconds() - started)
end

local function logProfileInternal(message, ...)
    local debugObject = Addon.Debug or {}
    if RECIPE_PROFILE_INTERNAL_TRACE ~= true then
        return
    end
    if type(debugObject.SetLevelEnabled) == "function" and type(debugObject.IsLevelEnabled) == "function" and not debugObject.IsLevelEnabled("internal") then
        debugObject.SetLevelEnabled("internal", true)
    end
    if type(debugObject.Internal) == "function" then
        debugObject.Internal(message, ...)
    end
end

local function getInventory()
    return Addon.Client and Addon.Client.Inventory or {}
end

local function runProfileEquipmentMutation(reason, mutation)
    if type(Runtime) ~= "table" or type(Runtime.RunTransaction) ~= "function" then
        error("Profile equipment mutation requires the Runtime transaction module.", 2)
    end

    return Runtime:RunTransaction(reason, mutation)
end

local function getDependencies()
    return Database.Dependecies or {}
end

local function getRegistry()
    return Addon.Internal and Addon.Internal.Registry or {}
end

local function findActivatedDatasetById(datasetId)
    local normalizedId = ensureString(datasetId)
    if normalizedId == "" then
        return nil
    end

    local registry = getRegistry()
    local datasets = registry.GetActivatedDatasets and registry:GetActivatedDatasets() or {}
    for index = 1, #datasets do
        local dataset = datasets[index]
        if tostring(dataset and dataset.id or "") == normalizedId then
            return dataset
        end
    end

    return type(Database.GetDatasetByID) == "function" and Database.GetDatasetByID(normalizedId) or nil
end

local function getRuleset()
    return Addon.Internal and Addon.Internal.Ruleset or {}
end

local function getConditions()
    return Addon.Client and Addon.Client.Conditions or {}
end

local function bumpProfileTooltipContextRevision()
    local builder = Addon.Client and Addon.Client.Spellcasting and Addon.Client.Spellcasting.DescriptionBuilder or nil
    if type(builder) == "table" and type(builder.BumpProfileTooltipContextRevision) == "function" then
        builder.BumpProfileTooltipContextRevision()
    end
end

local function trimString(value)
    return tostring(value or ""):gsub("^%s+", ""):gsub("%s+$", "")
end

local function getSpellStatusText(spell)
    if not spell then
        return ""
    end

    if (tonumber(spell.castTime) or 0) > 0 then
        return ("Cast %.1fs"):format(tonumber(spell.castTime) or 0)
    end

    return "Instant"
end

local function getSpellSummaryText(spell)
    if not spell then
        return "This spell definition is missing from its dataset."
    end

    if spell.description and spell.description ~= "" then
        return spell.description
    end

    local componentCount = #(spell.components or {})
    local resourceCostCount = #(spell.resourceCosts or {})
    return ("%d component%s, %d cost%s"):format(
        componentCount,
        componentCount == 1 and "" or "s",
        resourceCostCount,
        resourceCostCount == 1 and "" or "s"
    )
end

local function getSpellCooldownText(spell)
    local cooldown = tonumber(spell and spell.cooldown) or 0
    if cooldown <= 0 then
        return "No Cooldown"
    end

    return ("Cooldown %.1fs"):format(cooldown)
end

local function normalizeTraitPayload(payload)
    if type(TraitClass) == "table" and type(TraitClass.NormalizeRuntimePayload) == "function" then
        return TraitClass.NormalizeRuntimePayload(payload)
    end

    return type(payload) == "table" and payload or {}
end

local function formatSummaryCount(count, singular)
    local numericCount = math.max(0, math.floor(tonumber(count) or 0))
    return ("%d %s%s"):format(numericCount, singular, numericCount == 1 and "" or "s")
end

local function getTraitSummaryText(payload, missingText)
    local normalizedPayload = normalizeTraitPayload(payload)
    if type(payload) ~= "table" then
        return missingText or "This trait definition is missing from its dataset."
    end

    local parts = {}
    local statBonusCount = #(normalizedPayload.statBonuses or {})
    local skillBonusCount = #(normalizedPayload.skillBonuses or {})
    local automaticAuraCount = #(normalizedPayload.automaticAuras or {})
    local eventCount = #(normalizedPayload.events or {})

    if statBonusCount > 0 then
        parts[#parts + 1] = formatSummaryCount(statBonusCount, "stat bonus")
    end
    if skillBonusCount > 0 then
        parts[#parts + 1] = formatSummaryCount(skillBonusCount, "skill bonus")
    end
    if automaticAuraCount > 0 then
        parts[#parts + 1] = formatSummaryCount(automaticAuraCount, "aura")
    end
    if eventCount > 0 then
        parts[#parts + 1] = formatSummaryCount(eventCount, "event")
    end

    if #parts == 0 then
        return missingText or "No effects"
    end

    return table.concat(parts, ", ")
end

local function evaluateDetailConditions(ownerType, owner, options)
    local conditions = getConditions()
    if type(conditions) ~= "table" or type(conditions.EvaluateList) ~= "function" or type(owner) ~= "table" then
        return {
            passed = true,
            failureText = "",
        }
    end

    local values = type(options) == "table" and options or {}
    local context = conditions:BuildContext(ownerType, owner, values)
    return conditions:EvaluateList(owner.conditions, context)
end

local function getActionBarSizeFromRuleset()
    local rulesetLogic = getRuleset()
    local ruleset = rulesetLogic.GetActiveRuleset and rulesetLogic.GetActiveRuleset() or nil
    local ruleDefinition = rulesetLogic.GetRulesetRuleDefinition and rulesetLogic.GetRulesetRuleDefinition("interface", "action_bar_size") or nil
    local rawValue = 5
    if rulesetLogic.GetRulesetRuleValue then
        local value = rulesetLogic.GetRulesetRuleValue(ruleset, "interface", ruleDefinition)
        if value ~= nil then
            rawValue = value
        end
    end
    local size = math.floor(tonumber(rawValue) or 5)
    if size < 0 then
        return 0
    end

    return size
end

local function buildKnownSpellRefs()
    local refs = {}
    local seen = {}

    local manualSpellbook = Database.ListProfileSpellbook and Database.ListProfileSpellbook() or {}
    for index = 1, #manualSpellbook do
        local spellRef = ensureString(manualSpellbook[index])
        if spellRef ~= "" and not seen[spellRef] then
            seen[spellRef] = true
            refs[#refs + 1] = spellRef
        end
    end

    local registry = getRegistry()
    local datasets = registry.GetActivatedDatasets and registry:GetActivatedDatasets() or {}
    for datasetIndex = 1, #datasets do
        local dataset = datasets[datasetIndex]
        local datasetId = ensureString(dataset and dataset.id)
        if datasetId ~= "" then
            for spellIndex = 1, #(dataset and dataset.spells or {}) do
                local spell = dataset.spells[spellIndex]
                if spell and spell.id and tostring(spell.learnMode or "trainer") == "always_learned" then
                    local spellRef = ("%s:%s"):format(datasetId, tostring(spell.id))
                    if not seen[spellRef] then
                        seen[spellRef] = true
                        refs[#refs + 1] = spellRef
                    end
                end
            end
        end
    end

    local selectedMount = Profile.GetSelectedMount and Profile.GetSelectedMount() or nil
    local mount = selectedMount and selectedMount.mount or nil
    for index = 1, #(mount and mount.spells or {}) do
        local spellRef = ensureString(mount.spells[index])
        if spellRef ~= "" and not seen[spellRef] then
            seen[spellRef] = true
            refs[#refs + 1] = spellRef
        end
    end

    return refs
end

local recipeKnowledgeCache = {
    revision = -1,
    data = nil,
}

local function buildRecipeRefSet(refs)
    local set = {}
    for index = 1, #(refs or {}) do
        local recipeRef = ensureString(refs[index])
        if recipeRef ~= "" then
            set[recipeRef] = true
        end
    end
    return set
end

local function buildProfileRecipeKnowledge()
    local revision = math.max(0, math.floor(tonumber(Addon.Internal and Addon.Internal.ConfigurationRevision) or 0))
    local recipeSkillIndex = Addon.Internal and Addon.Internal.RecipeSkillIndex or nil
    local manualRecipebook = Database.ListProfileRecipebook and Database.ListProfileRecipebook() or {}
    local knownRecipeRefs = {}
    local knownRecipeSet = {}
    local knownRecipeRefsBySkill = {}
    local unknownTrainerRecipeRefs = {}
    local unknownTrainerRecipeSet = {}
    local unknownTrainerRecipeRefsBySkill = {}

    local function appendUnique(target, seen, recipeRef)
        local normalizedRef = ensureString(recipeRef)
        if normalizedRef == "" or seen[normalizedRef] then
            return false
        end

        target[#target + 1] = normalizedRef
        seen[normalizedRef] = true
        return true
    end

    local alwaysLearnedRefsBySkill = recipeSkillIndex and recipeSkillIndex.alwaysLearnedRefsBySkill or {}
    for _, skillRefs in pairs(alwaysLearnedRefsBySkill) do
        for index = 1, #(skillRefs or {}) do
            appendUnique(knownRecipeRefs, knownRecipeSet, skillRefs[index])
        end
    end

    for index = 1, #manualRecipebook do
        appendUnique(knownRecipeRefs, knownRecipeSet, manualRecipebook[index])
    end

    local orderedRecipeRefsBySkill = recipeSkillIndex and recipeSkillIndex.orderedRecipeRefsBySkill or {}
    for skillRef, recipeRefs in pairs(orderedRecipeRefsBySkill) do
        local normalizedSkillRef = ensureString(skillRef)
        if normalizedSkillRef ~= "" then
            local bucket = {}
            for index = 1, #(recipeRefs or {}) do
                local recipeRef = ensureString(recipeRefs[index])
                if recipeRef ~= "" and knownRecipeSet[recipeRef] then
                    bucket[#bucket + 1] = recipeRef
                end
            end
            knownRecipeRefsBySkill[normalizedSkillRef] = bucket
        end
    end

    local trainerRecipeRefsBySkill = recipeSkillIndex and recipeSkillIndex.trainerRecipeRefsBySkill or {}
    for skillRef, recipeRefs in pairs(trainerRecipeRefsBySkill) do
        local normalizedSkillRef = ensureString(skillRef)
        if normalizedSkillRef ~= "" then
            local bucket = {}
            for index = 1, #(recipeRefs or {}) do
                local recipeRef = ensureString(recipeRefs[index])
                if recipeRef ~= "" and knownRecipeSet[recipeRef] ~= true then
                    bucket[#bucket + 1] = recipeRef
                    appendUnique(unknownTrainerRecipeRefs, unknownTrainerRecipeSet, recipeRef)
                end
            end
            unknownTrainerRecipeRefsBySkill[normalizedSkillRef] = bucket
        end
    end

    return {
        revision = revision,
        knownRecipeRefs = knownRecipeRefs,
        unknownTrainerRecipeRefs = unknownTrainerRecipeRefs,
        knownRecipeRefsBySkill = knownRecipeRefsBySkill,
        unknownTrainerRecipeRefsBySkill = unknownTrainerRecipeRefsBySkill,
    }
end

local function invalidateRecipeKnowledgeCache()
    recipeKnowledgeCache.revision = -1
    recipeKnowledgeCache.data = nil
end

local function getRecipeKnowledgeState()
    local revision = math.max(0, math.floor(tonumber(Addon.Internal and Addon.Internal.ConfigurationRevision) or 0))
    local cached = recipeKnowledgeCache.data
    if recipeKnowledgeCache.revision == revision and type(cached) == "table" then
        return cached
    end

    local stored = Database.GetProfileRecipeKnowledge and Database.GetProfileRecipeKnowledge() or nil
    if type(stored) ~= "table" or tonumber(stored.revision) ~= revision then
        stored = buildProfileRecipeKnowledge()
        if Database.SetProfileRecipeKnowledge then
            stored = Database.SetProfileRecipeKnowledge(stored)
        end
    end

    stored.knownRecipeSet = buildRecipeRefSet(stored.knownRecipeRefs)
    stored.unknownTrainerRecipeSet = buildRecipeRefSet(stored.unknownTrainerRecipeRefs)
    recipeKnowledgeCache.revision = revision
    recipeKnowledgeCache.data = stored
    return stored
end

function Profile.RebuildPersistedRecipeKnowledge()
    local startedAt = getTimingMilliseconds()
    local stored = buildProfileRecipeKnowledge()
    if Database.SetProfileRecipeKnowledge then
        stored = Database.SetProfileRecipeKnowledge(stored)
    end
    invalidateRecipeKnowledgeCache()
    logProfileInternal(
        "Profile: RebuildPersistedRecipeKnowledge revision=%d known=%d unknownTrainer=%d took=%.2fms",
        tonumber(stored and stored.revision) or 0,
        #(stored and stored.knownRecipeRefs or {}),
        #(stored and stored.unknownTrainerRecipeRefs or {}),
        getElapsedMilliseconds(startedAt)
    )
    return getRecipeKnowledgeState()
end

local function getProfileConfigurationRevision()
    return math.max(0, math.floor(tonumber(Addon.Internal and Addon.Internal.ConfigurationRevision) or 0))
end

local function getProfileRuntimeRevision()
    local builder = Addon.Client and Addon.Client.Spellcasting and Addon.Client.Spellcasting.DescriptionBuilder or nil
    return math.max(1, math.floor(tonumber(builder and builder.ProfileTooltipContextRevision) or 1))
end

local function getProfileRevision(domain)
    local runtime = Addon.Internal and Addon.Internal.Runtime or nil
    if type(runtime) == "table" and type(runtime.GetRevision) == "function" then
        return math.max(0, math.floor(tonumber(runtime:GetRevision(domain)) or 0))
    end

    return 0
end

local function getProfileDynamicResolverRevisionKey()
    local client = Addon.Client or {}
    local eventState = type(client.GetEventState) == "function" and client:GetEventState() or client.EventState
    if type(eventState) ~= "table" or eventState.active ~= true then
        return "inactive"
    end

    local eventId = tostring(eventState.id or "")
    local localUnit = type(client.ResolveLocalEventUnit) == "function"
        and client:ResolveLocalEventUnit(eventState)
        or nil
    local unitEventId = tonumber(localUnit and localUnit.eventID) or 0
    local auraRevision = 0
    local auraManager = client.Spellcasting and client.Spellcasting.AuraManager or nil
    if type(auraManager) == "table" and type(auraManager.GetEventAuraRevision) == "function" then
        auraRevision = math.max(0, math.floor(tonumber(auraManager:GetEventAuraRevision(client, eventId)) or 0))
    end

    local combat = client.Combat or nil
    local combatRevision = type(combat) == "table"
        and math.max(0, math.floor(tonumber(combat.CombatRuntimeRevision) or 0))
        or 0

    return table.concat({
        eventId,
        tostring(unitEventId),
        tostring(auraRevision),
        tostring(getProfileRevision("EventRuntimeRevision")),
        tostring(combatRevision),
    }, ":")
end

local function getProfileResolverRevisionKey()
    return table.concat({
        tostring(getProfileRuntimeRevision()),
        tostring(getProfileRevision("ProfileStateRevision")),
        tostring(getProfileRevision("ProfileStatsRevision")),
        tostring(getProfileRevision("ProfileResourcesRevision")),
        tostring(getProfileRevision("EquipmentRevision")),
        tostring(getProfileRevision("ResolvedProfileRevision")),
        getProfileDynamicResolverRevisionKey(),
    }, ":")
end

function Profile.GetResolvedPresentationRevisionKey()
    return getProfileResolverRevisionKey()
end

local function getProfileIdentityKey()
    if type(Database.ResolveCurrentCharacterIdentity) == "function" then
        local characterKey, _, isStable = Database.ResolveCurrentCharacterIdentity()
        if isStable == true then
            return tostring(characterKey or "")
        end
    end

    return ""
end

function Profile.InvalidateResolvedLookupCaches()
    Profile.ResolvedStatLookupCache = nil
    Profile.ResolvedResourceLookupCache = nil
    Profile.ProfilePresentationSnapshotCache = nil
    Profile.MountListCache = nil
    Profile.PetListCache = nil
end

local function getResolvedBootstrapReadiness()
    local identityKey = getProfileIdentityKey()
    local activeProfile = type(Database.GetActiveProfile) == "function" and Database.GetActiveProfile() or nil
    local rulesetLogic = getRuleset()
    local activeRuleset = type(rulesetLogic.GetActiveRuleset) == "function" and rulesetLogic:GetActiveRuleset() or nil
    local activatedDatasetIds = type(Database.ListActivatedDatasetIds) == "function" and Database.ListActivatedDatasetIds() or {}
    local hasActivatedDatasets = type(activatedDatasetIds) == "table" and #activatedDatasetIds > 0
    local ready = identityKey ~= ""
        and type(activeProfile) == "table"
        and type(activeRuleset) == "table"
        and hasActivatedDatasets

    return {
        ready = ready,
        identityKey = identityKey,
        hasProfile = type(activeProfile) == "table",
        hasRuleset = type(activeRuleset) == "table",
        hasActivatedDatasets = hasActivatedDatasets,
    }
end

local function refreshResolvedBootstrapReadiness()
    local readiness = getResolvedBootstrapReadiness()
    local nextReady = readiness.ready == true
    local nextIdentityKey = nextReady and tostring(readiness.identityKey or "") or ""
    local previousReady = Profile.ResolvedBootstrapReady == true
    local previousIdentityKey = tostring(Profile.ResolvedBootstrapIdentityKey or "")

    if previousReady ~= nextReady or previousIdentityKey ~= nextIdentityKey then
        Profile.InvalidateResolvedLookupCaches()
    end

    Profile.ResolvedBootstrapReady = nextReady
    Profile.ResolvedBootstrapIdentityKey = nextIdentityKey
    return readiness
end

function Profile.IsBootstrapResolvedStateReady()
    return refreshResolvedBootstrapReadiness().ready == true
end

local getCachedResolvedStatLookup
local getCachedResolvedResourceLookup

function Profile.WarmResolvedBootstrapState(_)
    local readiness = refreshResolvedBootstrapReadiness()
    if readiness.ready ~= true then
        return false, readiness
    end

    getCachedResolvedStatLookup(nil)
    getCachedResolvedResourceLookup(nil)
    return true, readiness
end

local function canUseDefaultResolvedStatCache(options)
    if options == nil then
        return true
    end

    if type(options) ~= "table" then
        return false
    end

    local sawAuraOption = false
    for key, value in pairs(options) do
        if key == "includeAuraBonuses" and type(value) == "boolean" then
            sawAuraOption = true
        else
            return false
        end
    end

    return sawAuraOption or next(options) == nil
end

local function canUseDefaultResolvedResourceCache(options)
    return canUseDefaultResolvedStatCache(options)
end

local function getResolvedCacheVariant(options)
    if type(options) == "table" and options.includeAuraBonuses == false then
        return "base"
    end

    return "aura"
end

local function cloneResolvedResourceRow(row)
    if type(row) ~= "table" then
        return nil
    end

    local cloned = {}
    for key, value in pairs(row) do
        if type(value) == "table" then
            local child = {}
            for childKey, childValue in pairs(value) do
                child[childKey] = childValue
            end
            cloned[key] = child
        else
            cloned[key] = value
        end
    end
    return cloned
end

local cloneResolvedStatRow = cloneResolvedResourceRow

local function buildResolvedStatRowsByRef(rows)
    local rowsByRef = {}
    for index = 1, #(rows or {}) do
        local row = rows[index]
        local statRef = ensureString(row and row.ref)
        if statRef ~= "" then
            rowsByRef[statRef] = row
        end
    end

    return rowsByRef
end

getCachedResolvedStatLookup = function(options)
    if not canUseDefaultResolvedStatCache(options) then
        local rows = Resolver.ListResolvedStats and Resolver.ListResolvedStats(options) or {}
        return rows, buildResolvedStatRowsByRef(rows)
    end

    local readiness = refreshResolvedBootstrapReadiness()
    local configurationRevision = getProfileConfigurationRevision()
    local runtimeRevision = getProfileResolverRevisionKey()
    local identityKey = getProfileIdentityKey()
    local cacheKey = ("%d:%s:%s:%s"):format(
        configurationRevision,
        runtimeRevision,
        identityKey,
        getResolvedCacheVariant(options)
    )
    local cache = Profile.ResolvedStatLookupCache
    if type(cache) == "table"
        and tostring(cache.key or "") == cacheKey
        and type(cache.rows) == "table"
        and type(cache.rowsByRef) == "table"
    then
        return cache.rows, cache.rowsByRef
    end

    local rows = Resolver.ListResolvedStats and Resolver.ListResolvedStats(options) or {}
    local rowsByRef = buildResolvedStatRowsByRef(rows)
    if readiness.ready == true then
        Profile.ResolvedStatLookupCache = {
            key = cacheKey,
            configurationRevision = configurationRevision,
            runtimeRevision = runtimeRevision,
            identityKey = identityKey,
            rows = rows,
            rowsByRef = rowsByRef,
        }
    end
    return rows, rowsByRef
end

local function buildResolvedResourceRowsByRef(rows)
    local rowsByRef = {}
    for index = 1, #(rows or {}) do
        local row = rows[index]
        local resourceRef = ensureString(row and row.ref)
        if resourceRef ~= "" then
            rowsByRef[resourceRef] = row
        end
    end

    return rowsByRef
end

getCachedResolvedResourceLookup = function(options, resolvedStatRows)
    if not canUseDefaultResolvedResourceCache(options) then
        resolvedStatRows = resolvedStatRows or select(1, getCachedResolvedStatLookup(options))
        local rows = Resolver.ListResolvedResources and Resolver.ListResolvedResources(options, resolvedStatRows) or {}
        return rows, buildResolvedResourceRowsByRef(rows)
    end

    local readiness = refreshResolvedBootstrapReadiness()
    local configurationRevision = getProfileConfigurationRevision()
    local runtimeRevision = getProfileResolverRevisionKey()
    local identityKey = getProfileIdentityKey()
    local cacheKey = ("%d:%s:%s:%s"):format(
        configurationRevision,
        runtimeRevision,
        identityKey,
        getResolvedCacheVariant(options)
    )
    local cache = Profile.ResolvedResourceLookupCache
    if type(cache) == "table"
        and tostring(cache.key or "") == cacheKey
        and type(cache.rows) == "table"
        and type(cache.rowsByRef) == "table"
    then
        return cache.rows, cache.rowsByRef
    end

    resolvedStatRows = resolvedStatRows or select(1, getCachedResolvedStatLookup(options))
    local rows = Resolver.ListResolvedResources and Resolver.ListResolvedResources(options, resolvedStatRows) or {}
    local rowsByRef = buildResolvedResourceRowsByRef(rows)
    if readiness.ready == true then
        Profile.ResolvedResourceLookupCache = {
            key = cacheKey,
            configurationRevision = configurationRevision,
            runtimeRevision = runtimeRevision,
            identityKey = identityKey,
            rows = rows,
            rowsByRef = rowsByRef,
        }
    end
    return rows, rowsByRef
end

local function getResolvedStateContinuationIdentity(options)
    local readiness = refreshResolvedBootstrapReadiness()
    local configurationRevision = getProfileConfigurationRevision()
    local runtimeRevision = getProfileResolverRevisionKey()
    local identityKey = getProfileIdentityKey()
    local variant = getResolvedCacheVariant(options)
    local cacheKey = ("%d:%s:%s:%s"):format(
        configurationRevision,
        runtimeRevision,
        identityKey,
        variant
    )

    return {
        readiness = readiness,
        configurationRevision = configurationRevision,
        runtimeRevision = runtimeRevision,
        identityKey = identityKey,
        variant = variant,
        cacheKey = cacheKey,
    }
end

local function isResolvedStateContinuationCurrent(continuation)
    if type(continuation) ~= "table" then
        return false
    end

    local current = getResolvedStateContinuationIdentity(continuation.options)
    return tostring(current.cacheKey or "") == tostring(continuation.cacheKey or "")
end

function Profile.CreateResolvedStateContinuation(options)
    if not canUseDefaultResolvedStatCache(options) or not canUseDefaultResolvedResourceCache(options) then
        return nil
    end

    local identity = getResolvedStateContinuationIdentity(options)
    local continuation = {
        options = options,
        cacheKey = identity.cacheKey,
        configurationRevision = identity.configurationRevision,
        runtimeRevision = identity.runtimeRevision,
        identityKey = identity.identityKey,
        variant = identity.variant,
        cacheReady = identity.readiness.ready == true,
    }
    local statCache = Profile.ResolvedStatLookupCache
    local resourceCache = Profile.ResolvedResourceLookupCache
    if type(statCache) == "table"
        and tostring(statCache.key or "") == identity.cacheKey
        and type(statCache.rows) == "table"
        and type(resourceCache) == "table"
        and tostring(resourceCache.key or "") == identity.cacheKey
        and type(resourceCache.rows) == "table"
    then
        continuation.statRows = statCache.rows
        continuation.resourceRows = resourceCache.rows
        continuation.completed = true
        return continuation
    end

    if type(Resolver.CreateResolvedStateContinuation) ~= "function" then
        return nil
    end

    continuation.resolverContinuation = Resolver.CreateResolvedStateContinuation(options)
    return continuation
end

function Profile.IsResolvedStateContinuationCurrent(continuation)
    return isResolvedStateContinuationCurrent(continuation)
end

function Profile.StepResolvedStateContinuation(continuation, deadlineMs)
    if type(continuation) ~= "table" then
        return true
    end
    if not isResolvedStateContinuationCurrent(continuation) then
        return nil, "stale"
    end
    if continuation.completed == true then
        return true
    end
    if type(Resolver.StepResolvedStateContinuation) ~= "function" then
        return nil, "missing-resolver"
    end

    local completed, reason = Resolver.StepResolvedStateContinuation(
        continuation.resolverContinuation,
        deadlineMs
    )
    if completed == nil then
        return nil, reason or "resolver-stale"
    end
    if not completed then
        return false
    end

    continuation.statRows = type(continuation.resolverContinuation) == "table"
        and continuation.resolverContinuation.statRows
        or {}
    continuation.statRowsByRef = type(continuation.resolverContinuation) == "table"
        and continuation.resolverContinuation.statRowsByRef
        or {}
    continuation.resourceRows = type(continuation.resolverContinuation) == "table"
        and continuation.resolverContinuation.resourceRows
        or {}
    continuation.resourceRowsByRef = type(continuation.resolverContinuation) == "table"
        and continuation.resolverContinuation.resourceRowsByRef
        or {}
    continuation.resolverContinuation = nil
    continuation.completed = true

    if continuation.cacheReady == true then
        Profile.ResolvedStatLookupCache = {
            key = continuation.cacheKey,
            configurationRevision = continuation.configurationRevision,
            runtimeRevision = continuation.runtimeRevision,
            identityKey = continuation.identityKey,
            rows = continuation.statRows,
            rowsByRef = continuation.statRowsByRef,
        }
        Profile.ResolvedResourceLookupCache = {
            key = continuation.cacheKey,
            configurationRevision = continuation.configurationRevision,
            runtimeRevision = continuation.runtimeRevision,
            identityKey = continuation.identityKey,
            rows = continuation.resourceRows,
            rowsByRef = continuation.resourceRowsByRef,
        }
    end

    return true
end

function Profile.ReleaseResolvedStateContinuation(continuation)
    if type(continuation) ~= "table" then
        return false
    end

    continuation.resolverContinuation = nil
    continuation.statRows = nil
    continuation.statRowsByRef = nil
    continuation.resourceRows = nil
    continuation.resourceRowsByRef = nil
    return true
end

local function canUseDefaultResolvedSkillCache(options)
    return options == nil or (type(options) == "table" and next(options) == nil)
end

local function buildResolvedWeaponSkillRowsByWeaponType(rows)
    local rowsByWeaponTypeRef = {}
    for index = 1, #(rows or {}) do
        local row = rows[index]
        local weaponTypeRef = ensureString(type(row) == "table" and row.weaponTypeRef)
        if weaponTypeRef ~= "" and tostring(row and row.skillType or "") == "weapon" then
            local bucket = rowsByWeaponTypeRef[weaponTypeRef]
            if type(bucket) ~= "table" then
                bucket = {}
                rowsByWeaponTypeRef[weaponTypeRef] = bucket
            end
            bucket[#bucket + 1] = row
        end
    end
    return rowsByWeaponTypeRef
end

local function getCachedResolvedWeaponSkillLookup(options)
    if not canUseDefaultResolvedSkillCache(options) then
        local rows = Resolver.ListResolvedSkills and Resolver.ListResolvedSkills(options) or {}
        return rows, buildResolvedWeaponSkillRowsByWeaponType(rows)
    end

    local revision = getProfileConfigurationRevision()
    local cache = Profile.ResolvedWeaponSkillLookupCache
    if type(cache) == "table"
        and tonumber(cache.revision) == revision
        and type(cache.rows) == "table"
        and type(cache.rowsByWeaponTypeRef) == "table"
    then
        return cache.rows, cache.rowsByWeaponTypeRef
    end

    local rows = Resolver.ListResolvedSkills and Resolver.ListResolvedSkills(options) or {}
    local rowsByWeaponTypeRef = buildResolvedWeaponSkillRowsByWeaponType(rows)
    Profile.ResolvedWeaponSkillLookupCache = {
        revision = revision,
        rows = rows,
        rowsByWeaponTypeRef = rowsByWeaponTypeRef,
    }
    return rows, rowsByWeaponTypeRef
end

local function getSpellRefFallbackName(spellRef)
    local normalizedRef = ensureString(spellRef)
    local _, spellId = normalizedRef:match("^([^:]+):(.+)$")
    if spellId and spellId ~= "" then
        return spellId
    end

    return normalizedRef
end

local isSpellProvidedBySelectedMount

local function buildKnownSpellLightweightRow(spellRef, rowIndex)
    local normalizedRef = ensureString(spellRef)
    if normalizedRef == "" then
        return nil
    end

    local registry = getRegistry()
    local dataset, spell = nil, nil
    if registry.ResolveSpellReference then
        dataset, spell = registry:ResolveSpellReference(normalizedRef)
    end

    return {
        rowIndex = rowIndex,
        spellRef = normalizedRef,
        name = type(spell) == "table" and trimString(spell.name) ~= "" and spell.name or getSpellRefFallbackName(normalizedRef),
        isMissing = spell == nil,
        dataset = dataset,
        spell = spell,
        spellbookCategory = isSpellProvidedBySelectedMount(normalizedRef) and "Mounted" or (spell and trimString(spell.spellbookCategory) or ""),
    }
end

function isSpellProvidedBySelectedMount(spellRef)
    local normalizedRef = ensureString(spellRef)
    if normalizedRef == "" then
        return false
    end

    local selectedMount = Profile.GetSelectedMount and Profile.GetSelectedMount() or nil
    local mount = selectedMount and selectedMount.mount or nil
    for index = 1, #(mount and mount.spells or {}) do
        if ensureString(mount.spells[index]) == normalizedRef then
            return true
        end
    end

    return false
end

local DEFAULT_TALENT_TRAIT_CATEGORY = "General"

local function getRulesetValue(categoryKey, ruleKey, fallback)
    local rulesetLogic = getRuleset()
    local ruleset = rulesetLogic.GetActiveRuleset and rulesetLogic.GetActiveRuleset() or nil
    local ruleDefinition = rulesetLogic.GetRulesetRuleDefinition and rulesetLogic.GetRulesetRuleDefinition(categoryKey, ruleKey) or nil
    local value = nil
    if rulesetLogic.GetRulesetRuleValue then
        value = rulesetLogic.GetRulesetRuleValue(ruleset, categoryKey, ruleDefinition)
    end
    if value == nil then
        return fallback
    end

    return value
end

local function getTraitRuleValue(ruleKey, fallback)
    return getRulesetValue("traits", ruleKey, fallback)
end

local function getMountRuleValue(ruleKey, fallback)
    return getRulesetValue("mounts", ruleKey, fallback)
end

local function getInterfaceRuleValue(ruleKey, fallback)
    return getRulesetValue("interface", ruleKey, fallback)
end

local function refreshVisibleProfileWindow()
    local profileWindow = Addon.Client and Addon.Client.UI and Addon.Client.UI.Profile and Addon.Client.UI.Profile.Window or nil
    if not (profileWindow and profileWindow.Get) then
        return false
    end

    local instance = profileWindow:Get()
    local window = instance and instance.window or nil
    local frame = window and window.GetFrame and window:GetFrame() or nil
    if not (frame and frame.IsShown and frame:IsShown() == true) then
        return false
    end

    if instance and instance.Refresh then
        instance:Refresh()
        return true
    end

    return false
end

local function refreshMountedUi(reason)
    local client = Addon.Client or nil
    if type(client) == "table" and type(client.RefreshActionBarWidget) == "function" then
        client:RefreshActionBarWidget(reason or "profile-mount")
    end

    refreshVisibleProfileWindow()
    return true
end

local function getTraitSourceCategory(trait)
    if type(trait) ~= "table" then
        return "talent"
    end

    if trait.isClass == true then
        return "class"
    end
    if trait.isRacial == true then
        return "race"
    end

    return "talent"
end

local function getTraitCategoryFromDefinition(trait)
    if type(trait) ~= "table" then
        return DEFAULT_TALENT_TRAIT_CATEGORY
    end

    local category = trimString(trait.category)
    if category ~= "" then
        return category
    end

    return DEFAULT_TALENT_TRAIT_CATEGORY
end

local function getTraitDisplayCategory(origin, typeCategory, trait)
    if origin == "class" then
        if typeCategory == "talent" then
            return "class_talents"
        end
        return "class_passives"
    end
    if origin == "race" then
        return "race_passives"
    end

    return getTraitCategoryFromDefinition(trait)
end

local function getTraitUnlockLevel(trait)
    if type(trait) ~= "table" then
        return 1
    end

    return math.max(1, math.floor(tonumber(trait.unlockLevel) or 1))
end

local function appendUniqueRef(target, seen, reference)
    local normalizedRef = ensureString(reference)
    if normalizedRef == "" or seen[normalizedRef] then
        return false
    end

    seen[normalizedRef] = true
    target[#target + 1] = normalizedRef
    return true
end

local function buildManualKnownTraitRefs()
    local refs = {}
    local seen = {}
    local manualTraits = Database.ListProfileTraits and Database.ListProfileTraits() or {}

    for index = 1, #manualTraits do
        appendUniqueRef(refs, seen, manualTraits[index])
    end

    return refs
end

local function buildManualActiveTraitRefs()
    local refs = {}
    local seen = {}
    local profile = Database.GetActiveProfile and Database.GetActiveProfile() or nil
    local hasPersistedActiveTraits = type(profile) == "table" and profile.activeTraits ~= nil
    local activeTraits = Database.ListProfileActiveTraits and Database.ListProfileActiveTraits() or {}
    if not hasPersistedActiveTraits then
        activeTraits = Database.ListProfileTraits and Database.ListProfileTraits() or {}
    end

    for index = 1, #activeTraits do
        appendUniqueRef(refs, seen, activeTraits[index])
    end

    return refs
end

local function buildInactiveTraitRefs()
    local refs = {}
    local seen = {}
    local inactiveTraits = Database.ListProfileInactiveTraits and Database.ListProfileInactiveTraits() or {}

    for index = 1, #inactiveTraits do
        appendUniqueRef(refs, seen, inactiveTraits[index])
    end

    return refs
end

local function resolveProfileDefinition(reference, collectionKey)
    local normalizedRef = ensureString(reference)
    if normalizedRef == "" then
        return nil, nil
    end

    local dependencies = getDependencies()
    local datasetId, entryId = nil, nil
    if type(dependencies.ParseSourceStatRef) == "function" then
        datasetId, entryId = dependencies.ParseSourceStatRef(normalizedRef)
    else
        datasetId, entryId = normalizedRef:match("^([^:]+):(.+)$")
    end
    if not datasetId or not entryId then
        return nil, nil
    end

    local dataset = Database.GetDatasetByID and Database.GetDatasetByID(datasetId) or nil
    if not dataset then
        return nil, nil
    end

    for index = 1, #(dataset[collectionKey] or {}) do
        local entry = dataset[collectionKey][index]
        if entry and tostring(entry.id or "") == tostring(entryId) then
            return dataset, entry
        end
    end

    return dataset, nil
end

local function buildSelectedOriginTraitRefs(kind)
    local refs = {}
    local seen = {}

    if kind == "race" then
        if getTraitRuleValue("allow_race_traits", true) == false then
            return refs
        end
        local profileRaceRef = Database.GetProfileRaceRef and Database.GetProfileRaceRef() or nil
        local _, race = resolveProfileDefinition(profileRaceRef, "races")
        local raceTraitRefs = type(race) == "table" and race.traitRefs or nil
        for index = 1, #(raceTraitRefs or {}) do
            appendUniqueRef(refs, seen, raceTraitRefs[index])
        end
        return refs
    end

    if getTraitRuleValue("allow_class_traits", true) == false then
        return refs
    end
    local profileClassRef = Database.GetProfileClassRef and Database.GetProfileClassRef() or nil
    local _, class = resolveProfileDefinition(profileClassRef, "classes")
    local classTraitRefs = type(class) == "table" and class.traitRefs or nil
    for index = 1, #(classTraitRefs or {}) do
        appendUniqueRef(refs, seen, classTraitRefs[index])
    end

    return refs
end

local function buildAutoGrantedTraitRefs(kind)
    local refs = {}
    local seen = {}
    local selectedRefs = buildSelectedOriginTraitRefs(kind)

    if kind == "race" and getTraitRuleValue("auto_enable_race_traits", true) == false then
        return refs
    end
    if kind == "class" and getTraitRuleValue("auto_enable_class_traits", true) == false then
        return refs
    end

    for index = 1, #selectedRefs do
        appendUniqueRef(refs, seen, selectedRefs[index])
    end

    return refs
end

local function getKnownTraitOrigin(traitRef)
    local normalizedRef = ensureString(traitRef)
    if normalizedRef == "" then
        return nil
    end

    local raceRefs = buildSelectedOriginTraitRefs("race")
    for index = 1, #raceRefs do
        if raceRefs[index] == normalizedRef then
            return "race"
        end
    end

    local classRefs = buildSelectedOriginTraitRefs("class")
    for index = 1, #classRefs do
        if classRefs[index] == normalizedRef then
            return "class"
        end
    end

    local manualRefs = buildManualKnownTraitRefs()
    for index = 1, #manualRefs do
        if manualRefs[index] == normalizedRef then
            return "manual"
        end
    end

    return nil
end

local function buildEffectiveKnownTraitRefs()
    local refs = {}
    local seen = {}
    local manualRefs = buildManualKnownTraitRefs()
    local raceRefs = buildSelectedOriginTraitRefs("race")
    local classRefs = buildSelectedOriginTraitRefs("class")

    for index = 1, #manualRefs do
        appendUniqueRef(refs, seen, manualRefs[index])
    end
    for index = 1, #raceRefs do
        appendUniqueRef(refs, seen, raceRefs[index])
    end
    for index = 1, #classRefs do
        appendUniqueRef(refs, seen, classRefs[index])
    end

    return refs
end

local function pruneSelectedOriginTraitRef(kind, traitRef)
    local normalizedRef = ensureString(traitRef)
    if normalizedRef == "" then
        return false
    end

    local profileDefinitionRef = nil
    local collectionKey = nil
    if kind == "race" then
        profileDefinitionRef = Database.GetProfileRaceRef and Database.GetProfileRaceRef() or nil
        collectionKey = "races"
    elseif kind == "class" then
        profileDefinitionRef = Database.GetProfileClassRef and Database.GetProfileClassRef() or nil
        collectionKey = "classes"
    else
        return false
    end

    local dataset, definition = resolveProfileDefinition(profileDefinitionRef, collectionKey)
    if type(definition) ~= "table" then
        return false
    end

    local keptTraitRefs = {}
    local removed = false
    for index = 1, #(definition.traitRefs or {}) do
        local currentRef = ensureString(definition.traitRefs[index])
        if currentRef == normalizedRef then
            removed = true
        elseif currentRef ~= "" then
            keptTraitRefs[#keptTraitRefs + 1] = currentRef
        end
    end

    if not removed then
        return false
    end

    definition.traitRefs = keptTraitRefs
    if Database.RemoveProfileActiveTrait then
        Database.RemoveProfileActiveTrait(normalizedRef)
    end
    if Database.RemoveProfileInactiveTrait then
        Database.RemoveProfileInactiveTrait(normalizedRef)
    end
    if Database.NotifyDatasetEntryChanged and dataset and dataset.id then
        Database.NotifyDatasetEntryChanged(dataset.id, collectionKey)
    end

    return true
end

local function buildEffectiveActiveTraitRefs()
    local refs = {}
    local seen = {}
    local manualRefs = buildManualActiveTraitRefs()
    local inactiveRefs = buildInactiveTraitRefs()
    local raceRefs = buildAutoGrantedTraitRefs("race")
    local classRefs = buildAutoGrantedTraitRefs("class")
    local inactiveLookup = {}

    for index = 1, #inactiveRefs do
        inactiveLookup[inactiveRefs[index]] = true
    end

    for index = 1, #manualRefs do
        appendUniqueRef(refs, seen, manualRefs[index])
    end
    for index = 1, #raceRefs do
        appendUniqueRef(refs, seen, raceRefs[index])
    end
    for index = 1, #classRefs do
        local traitRef = classRefs[index]
        local registry = getRegistry()
        local trait = nil
        if type(registry.ResolveTraitReference) == "function" then
            local _, resolvedTrait = registry:ResolveTraitReference(traitRef)
            trait = resolvedTrait
        end
        local origin = getKnownTraitOrigin(traitRef)
        local typeCategory = getTraitSourceCategory(trait)
        if origin == "class" and typeCategory == "talent" then
            if inactiveLookup[traitRef] ~= true then
                appendUniqueRef(refs, seen, traitRef)
            end
        else
            appendUniqueRef(refs, seen, traitRef)
        end
    end

    return refs
end

local function getProfileLevel()
    return math.max(1, math.floor(tonumber(Database.GetProfileLevel and Database.GetProfileLevel() or 1) or 1))
end

local function isTraitDetailVisibleToProfile(detail)
    if type(detail) ~= "table" then
        return false
    end

    if detail.isMissing == true then
        return true
    end

    if detail.typeCategory == "race" and detail.origin ~= "race" then
        return false
    end
    if detail.typeCategory == "class" and detail.origin ~= "class" then
        return false
    end

    return (tonumber(detail.unlockLevel) or 1) <= getProfileLevel()
end

local function isTraitRefVisibleToProfileWithoutConditions(traitRef)
    local normalizedRef = ensureString(traitRef)
    if normalizedRef == "" then
        return false
    end

    local registry = getRegistry()
    local trait = nil
    if type(registry.ResolveTraitReference) == "function" then
        local _, resolvedTrait = registry:ResolveTraitReference(normalizedRef)
        trait = resolvedTrait
    end
    if type(trait) ~= "table" then
        return true
    end
    if trait.isEnvironmental == true then
        return false
    end

    local origin = getKnownTraitOrigin(normalizedRef) or "manual"
    local typeCategory = getTraitSourceCategory(trait)
    if typeCategory == "race" and origin ~= "race" then
        return false
    end
    if typeCategory == "class" and origin ~= "class" then
        return false
    end

    return getTraitUnlockLevel(trait) <= getProfileLevel()
end

local function buildTraitCountSummary()
    local manualRefs = buildManualKnownTraitRefs()
    local effectiveKnownRefs = {}
    local raceRefs = {}
    local classRefs = {}
    local countedTotalRefs = {}
    local countedSeen = {}
    local manualCount = 0
    local manualTalentCount = 0

    for index = 1, #manualRefs do
        local detail = Profile.GetKnownTraitDetails and Profile.GetKnownTraitDetails(manualRefs[index]) or nil
        if detail and detail.isEnvironmental ~= true and detail.isVisibleToProfile == true then
            manualCount = manualCount + 1
            if detail.typeCategory == "talent" then
                manualTalentCount = manualTalentCount + 1
            end
            appendUniqueRef(countedTotalRefs, countedSeen, detail.traitRef)
        end
    end

    local effectiveKnownCandidates = buildEffectiveKnownTraitRefs()
    for index = 1, #effectiveKnownCandidates do
        local detail = Profile.GetKnownTraitDetails and Profile.GetKnownTraitDetails(effectiveKnownCandidates[index]) or nil
        if detail and detail.isEnvironmental ~= true and detail.isVisibleToProfile == true then
            effectiveKnownRefs[#effectiveKnownRefs + 1] = effectiveKnownCandidates[index]
        end
    end

    local raceCandidates = buildAutoGrantedTraitRefs("race")
    for index = 1, #raceCandidates do
        local detail = Profile.GetKnownTraitDetails and Profile.GetKnownTraitDetails(raceCandidates[index]) or nil
        if detail and detail.isEnvironmental ~= true and detail.isVisibleToProfile == true then
            raceRefs[#raceRefs + 1] = raceCandidates[index]
        end
    end

    local classCandidates = buildAutoGrantedTraitRefs("class")
    for index = 1, #classCandidates do
        local detail = Profile.GetKnownTraitDetails and Profile.GetKnownTraitDetails(classCandidates[index]) or nil
        if detail and detail.isEnvironmental ~= true and detail.isVisibleToProfile == true then
            classRefs[#classRefs + 1] = classCandidates[index]
        end
    end

    local level = getProfileLevel()
    local baseTalentTraits = math.max(0, math.floor(tonumber(getTraitRuleValue("base_talent_traits", 0)) or 0))
    local talentTraitsPerLevel = math.max(0, tonumber(getTraitRuleValue("talent_traits_per_level", 0)) or 0)
    local maxTotalTraits = math.max(0, math.floor(tonumber(getTraitRuleValue("max_total_traits", 0)) or 0))
    local maxTalentTraits = math.max(0, math.floor(baseTalentTraits + ((level - 1) * talentTraitsPerLevel)))
    local countRaceTowardTotal = getTraitRuleValue("count_race_traits_toward_total", false) == true
    local countClassTowardTotal = getTraitRuleValue("count_class_traits_toward_total", false) == true
    if countRaceTowardTotal then
        for index = 1, #raceRefs do
            appendUniqueRef(countedTotalRefs, countedSeen, raceRefs[index])
        end
    end
    if countClassTowardTotal then
        for index = 1, #classRefs do
            appendUniqueRef(countedTotalRefs, countedSeen, classRefs[index])
        end
    end

    return {
        level = level,
        manualCount = manualCount,
        manualTalentCount = manualTalentCount,
        maxTotalTraits = maxTotalTraits,
        maxTalentTraits = maxTalentTraits,
        effectiveTotalCount = #countedTotalRefs,
        effectiveKnownCount = #effectiveKnownRefs,
        autoRaceCount = #raceRefs,
        autoClassCount = #classRefs,
        countRaceTowardTotal = countRaceTowardTotal,
        countClassTowardTotal = countClassTowardTotal,
    }
end

local PROFILE_STAT_CATEGORY_ORDER = {
    "Primary",
    "Secondary",
    "Melee",
    "Ranged",
    "Spell",
    "Defense",
    "Resistances",
    "Utility",
    "Mounted",
    "Special",
}

local function buildProfileStatCategoryOrderLookup()
    local lookup = {}
    for index = 1, #PROFILE_STAT_CATEGORY_ORDER do
        lookup[PROFILE_STAT_CATEGORY_ORDER[index]] = index
    end
    return lookup
end

local PROFILE_STAT_CATEGORY_ORDER_LOOKUP = buildProfileStatCategoryOrderLookup()

local function appendSortedSlotEntries(entries, bucket)
    table.sort(bucket, function(left, right)
        local leftPriority = tonumber(left.priority) or 0
        local rightPriority = tonumber(right.priority) or 0
        if leftPriority == rightPriority then
            local leftName = string.lower(tostring(left.name or left.slotKey or ""))
            local rightName = string.lower(tostring(right.name or right.slotKey or ""))
            if leftName == rightName then
                return tostring(left.slotKey or "") < tostring(right.slotKey or "")
            end
            return leftName < rightName
        end
        return leftPriority < rightPriority
    end)

    local values = {}
    for index = 1, #bucket do
        values[#values + 1] = bucket[index].slotKey
        entries[#entries + 1] = bucket[index]
    end

    return values
end

local function buildSlotLayoutFromRefs(slotRefs)
    local groups = {
        left = {},
        right = {},
        bottom = {},
    }
    local ordered = {}
    local seen = {}

    for index = 1, #(slotRefs or {}) do
        local slotRef = ensureString(slotRefs[index])
        local itemSlot, dataset = nil, nil
        if Equipment.ResolveSlotDefinition then
            itemSlot, dataset = Equipment.ResolveSlotDefinition(slotRef)
        end
        if itemSlot and dataset then
            local slotKey = Equipment.NormalizeSlotKey and Equipment.NormalizeSlotKey(itemSlot.name ~= "" and itemSlot.name or itemSlot.id) or tostring(itemSlot.id)
            if slotKey ~= "" and not seen[slotKey] then
                local panelSide = tostring(itemSlot.panelSide or "left")
                if panelSide ~= "right" and panelSide ~= "bottom" then
                    panelSide = "left"
                end

                seen[slotKey] = true
                groups[panelSide][#groups[panelSide] + 1] = {
                    slotKey = slotKey,
                    slotRef = slotRef,
                    slotId = itemSlot.id,
                    datasetId = dataset.id,
                    name = itemSlot.name,
                    priority = tonumber(itemSlot.priority) or 0,
                }
            end
        end
    end

    for _, key in ipairs({ "left", "right", "bottom" }) do
        groups[key] = appendSortedSlotEntries(ordered, groups[key])
    end

    return {
        left = groups.left,
        right = groups.right,
        bottom = groups.bottom,
        ordered = (function()
            local values = {}
            for index = 1, #ordered do
                values[#values + 1] = ordered[index].slotKey
            end
            return values
        end)(),
        entries = ordered,
    }
end

local function buildSlotLayoutForScope(scope)
    local normalizedScope = Equipment.NormalizeSlotType and Equipment.NormalizeSlotType(scope) or tostring(scope or "character")
    local groups = {
        left = {},
        right = {},
        bottom = {},
    }
    local ordered = {}
    local seen = {}
    local registry = getRegistry()
    local datasets = registry.GetActivatedDatasets and registry:GetActivatedDatasets() or {}

    for datasetIndex = 1, #datasets do
        local dataset = datasets[datasetIndex]
        local itemSlots = dataset and dataset.itemSlots or {}
        for slotIndex = 1, #itemSlots do
            local itemSlot = itemSlots[slotIndex]
            if itemSlot and itemSlot.id and (Equipment.NormalizeSlotType and Equipment.NormalizeSlotType(itemSlot.slotType) or "character") == normalizedScope then
                local slotKey = Equipment.NormalizeSlotKey and Equipment.NormalizeSlotKey(itemSlot.name ~= "" and itemSlot.name or itemSlot.id) or tostring(itemSlot.id)
                local dependencies = getDependencies()
                local slotRef = dependencies.ComposeSourceStatRef and dependencies.ComposeSourceStatRef(dataset.id, itemSlot.id) or nil
                if slotKey ~= "" and not seen[slotKey] then
                    local panelSide = tostring(itemSlot.panelSide or "left")
                    if panelSide ~= "right" and panelSide ~= "bottom" then
                        panelSide = "left"
                    end

                    seen[slotKey] = true
                    groups[panelSide][#groups[panelSide] + 1] = {
                        slotKey = slotKey,
                        slotRef = slotRef,
                        slotId = itemSlot.id,
                        datasetId = dataset.id,
                        name = itemSlot.name,
                        priority = tonumber(itemSlot.priority) or 0,
                    }
                end
            end
        end
    end

    for _, key in ipairs({ "left", "right", "bottom" }) do
        groups[key] = appendSortedSlotEntries(ordered, groups[key])
    end

    return {
        left = groups.left,
        right = groups.right,
        bottom = groups.bottom,
        ordered = (function()
            local values = {}
            for index = 1, #ordered do
                values[#values + 1] = ordered[index].slotKey
            end
            return values
        end)(),
        entries = ordered,
    }
end

function Profile.GetActiveProfile()
    if Database.GetActiveProfile then
        return Database.GetActiveProfile()
    end

    return nil
end

function Profile.GetEquipmentLayoutByScope(scope)
    local normalizedScope = Equipment.NormalizeSlotType and Equipment.NormalizeSlotType(scope) or tostring(scope or "character")
    if normalizedScope == "pet" then
        return Profile.GetPetLayout and Profile.GetPetLayout() or buildSlotLayoutFromRefs({})
    end

    return buildSlotLayoutForScope(scope)
end

function Profile.GetEquipmentLayout()
    return Profile.GetEquipmentLayoutByScope("character")
end

function Profile.ListMounts()
    local configurationRevision = getProfileConfigurationRevision()
    local cached = Profile.MountListCache
    if type(cached) == "table"
        and tonumber(cached.configurationRevision) == configurationRevision
        and type(cached.rows) == "table"
    then
        return cached.rows
    end

    local rows = {}
    local registry = getRegistry()
    local dependencies = getDependencies()
    local datasets = registry.GetActivatedDatasets and registry:GetActivatedDatasets() or {}

    for datasetIndex = 1, #datasets do
        local dataset = datasets[datasetIndex]
        for mountIndex = 1, #(dataset and dataset.mounts or {}) do
            local mount = dataset.mounts[mountIndex]
            if mount and mount.id then
                local mountRef = dependencies.ComposeSourceStatRef and dependencies.ComposeSourceStatRef(dataset.id, mount.id) or nil
                if mountRef then
                    rows[#rows + 1] = {
                        ref = mountRef,
                        dataset = dataset,
                        datasetId = dataset.id,
                        mount = mount,
                        name = trimString(mount.name) ~= "" and trimString(mount.name) or tostring(mount.id),
                        icon = ensureString(mount.icon),
                        description = ensureString(mount.description),
                    }
                end
            end
        end
    end

    table.sort(rows, function(left, right)
        local leftName = string.lower(ensureString(left and left.name))
        local rightName = string.lower(ensureString(right and right.name))
        if leftName == rightName then
            return ensureString(left and left.ref) < ensureString(right and right.ref)
        end
        return leftName < rightName
    end)

    Profile.MountListCache = {
        configurationRevision = configurationRevision,
        rows = rows,
    }
    return rows
end

function Profile.ListPets()
    local configurationRevision = getProfileConfigurationRevision()
    local cached = Profile.PetListCache
    if type(cached) == "table"
        and tonumber(cached.configurationRevision) == configurationRevision
        and type(cached.rows) == "table"
    then
        return cached.rows
    end

    local rows = {}
    local registry = getRegistry()
    local dependencies = getDependencies()
    local datasets = registry.GetActivatedDatasets and registry:GetActivatedDatasets() or {}

    for datasetIndex = 1, #datasets do
        local dataset = datasets[datasetIndex]
        for petIndex = 1, #(dataset and dataset.pets or {}) do
            local pet = dataset.pets[petIndex]
            if pet and pet.id then
                local petRef = dependencies.ComposeSourceStatRef and dependencies.ComposeSourceStatRef(dataset.id, pet.id) or nil
                if petRef then
                    local unitDataset, unit = resolveProfileDefinition(pet.unitRef, "units")
                    local unitName = trimString(unit and unit.name)
                    local petName = trimString(pet.name)
                    rows[#rows + 1] = {
                        ref = petRef,
                        dataset = dataset,
                        datasetId = dataset.id,
                        pet = pet,
                        unit = unit,
                        unitDataset = unitDataset,
                        name = petName ~= "" and petName or (unitName ~= "" and unitName or tostring(pet.id)),
                        description = ensureString(unit and unit.description),
                        unitRef = ensureString(pet.unitRef),
                    }
                end
            end
        end
    end

    table.sort(rows, function(left, right)
        local leftName = string.lower(ensureString(left and left.name))
        local rightName = string.lower(ensureString(right and right.name))
        if leftName == rightName then
            return ensureString(left and left.ref) < ensureString(right and right.ref)
        end
        return leftName < rightName
    end)

    Profile.PetListCache = {
        configurationRevision = configurationRevision,
        rows = rows,
    }
    return rows
end

function Profile.GetSelectedMount()
    local mountRef = Database.GetProfileMountRef and Database.GetProfileMountRef() or nil
    local normalizedRef = ensureString(mountRef)
    if normalizedRef == "" then
        return nil
    end

    local dataset, mount = resolveProfileDefinition(normalizedRef, "mounts")
    if not mount then
        return nil
    end

    return {
        ref = normalizedRef,
        dataset = dataset,
        datasetId = dataset and dataset.id or nil,
        mount = mount,
        name = trimString(mount.name) ~= "" and trimString(mount.name) or tostring(mount.id or normalizedRef),
        description = ensureString(mount.description),
        icon = ensureString(mount.icon),
        isActive = dataset and Database.IsDatasetActivated and Database.IsDatasetActivated(dataset.id) or false,
    }
end

function Profile.GetSelectedPet()
    local petRef = Database.GetProfilePetRef and Database.GetProfilePetRef() or nil
    local normalizedRef = ensureString(petRef)
    if normalizedRef == "" then
        return nil
    end

    local dataset, pet = resolveProfileDefinition(normalizedRef, "pets")
    if not pet then
        return nil
    end

    local unitDataset, unit = resolveProfileDefinition(pet.unitRef, "units")
    local petName = trimString(pet.name)
    local unitName = trimString(unit and unit.name)
    return {
        ref = normalizedRef,
        dataset = dataset,
        datasetId = dataset and dataset.id or nil,
        pet = pet,
        unit = unit,
        unitDataset = unitDataset,
        unitRef = ensureString(pet.unitRef),
        name = petName ~= "" and petName or (unitName ~= "" and unitName or tostring(pet.id or normalizedRef)),
        description = ensureString(unit and unit.description),
        isActive = dataset and Database.IsDatasetActivated and Database.IsDatasetActivated(dataset.id) or false,
        hasUnit = unit ~= nil,
    }
end

function Profile.GetMountLayout()
    return Profile.GetEquipmentLayoutByScope("mount")
end

function Profile.GetPetLayout()
    local selectedPet = Profile.GetSelectedPet and Profile.GetSelectedPet() or nil
    local pet = selectedPet and selectedPet.pet or nil
    return buildSlotLayoutFromRefs(pet and pet.equipmentSlotRefs or {})
end

function Profile.GetMountRef()
    return Database.GetProfileMountRef and Database.GetProfileMountRef() or nil
end

function Profile.GetPetRef()
    return Database.GetProfilePetRef and Database.GetProfilePetRef() or nil
end

function Profile.SetMountRef(mountRef)
    local result = Database.SetProfileMountRef and Database.SetProfileMountRef(mountRef) or nil
    refreshMountedUi("profile-mount-ref")
    return result
end

function Profile.SetPetRef(petRef)
    local result = Database.SetProfilePetRef and Database.SetProfilePetRef(petRef) or nil
    refreshVisibleProfileWindow()
    return result
end

function Profile.IsPetSelectionValid()
    local selectedPet = Profile.GetSelectedPet()
    return type(selectedPet) == "table" and selectedPet.isActive == true and selectedPet.hasUnit == true
end

function Profile.GetSelectedPetSpellRefs()
    local selectedPet = Profile.GetSelectedPet and Profile.GetSelectedPet() or nil
    local pet = selectedPet and selectedPet.pet or nil
    local spellRefs = {}

    for index = 1, #(pet and pet.spells or {}) do
        local spellRef = ensureString(pet.spells[index])
        if spellRef ~= "" then
            spellRefs[#spellRefs + 1] = spellRef
        end
    end

    return spellRefs
end

function Profile.BuildSelectedPetRuntimeStats()
    local selectedPet = Profile.GetSelectedPet and Profile.GetSelectedPet() or nil
    if type(selectedPet) ~= "table" or selectedPet.isActive ~= true or selectedPet.hasUnit ~= true then
        return {}
    end

    local resolver = Profile.Resolver or nil
    if type(resolver) ~= "table" or type(resolver.BuildUnitRuntimeStatRows) ~= "function" then
        return {}
    end

    local unit = selectedPet.unit or nil
    local equipped = Profile.ListEquippedSlotsByScope and Profile.ListEquippedSlotsByScope("pet") or {}
    return resolver.BuildUnitRuntimeStatRows(unit and unit.stats or {}, equipped)
end

function Profile.IsMounted()
    return Database.GetProfileMounted and Database.GetProfileMounted() == true or false
end

function Profile.SetMounted(mounted)
    local desiredMounted = mounted == true
    local result = false
    if Database.SetProfileMounted then
        Database.SetProfileMounted(desiredMounted)
        local currentMounted = Database.GetProfileMounted and Database.GetProfileMounted() == true or false
        result = currentMounted == desiredMounted
    end
    refreshMountedUi("profile-mounted")
    return result
end

function Profile.IsMountSelectionValid()
    local selectedMount = Profile.GetSelectedMount()
    return type(selectedMount) == "table" and selectedMount.isActive == true
end

function Profile.CanMount()
    local selectedMount = Profile.GetSelectedMount()
    if not selectedMount or selectedMount.isActive ~= true then
        return false, "no-mount"
    end

    local client = Addon.Client or nil
    local eventState = type(client) == "table" and type(client.GetEventState) == "function" and client:GetEventState() or nil
    local localEventUnit = type(client) == "table" and type(client.ResolveLocalEventUnit) == "function" and client:ResolveLocalEventUnit(eventState) or nil
    if eventState and eventState.active == true and localEventUnit and getMountRuleValue("allow_mount_in_combat", false) ~= true then
        return false, "combat-blocked"
    end

    return true
end

function Profile.ToggleMounted()
    if Profile.IsMounted() then
        local changed = Profile.SetMounted(false)
        if changed then
            bumpProfileTooltipContextRevision()
        end
        return changed, "dismounted"
    end

    local allowed, reason = Profile.CanMount()
    if not allowed then
        return false, reason or "blocked"
    end

    local changed = Profile.SetMounted(true)
    if changed then
        bumpProfileTooltipContextRevision()
    end
    return changed, "mounted"
end

function Profile.ListEquippedSlots()
    return Equipment.ListEquippedSlots and Equipment.ListEquippedSlots() or {}
end

function Profile.ListEquippedSlotsByScope(scope)
    return Equipment.ListEquippedSlotsByScope and Equipment.ListEquippedSlotsByScope(scope) or {}
end

function Profile.GetEquippedItemByScope(scope, slotKey)
    local entry = Equipment.GetEquippedEntryByScope and Equipment.GetEquippedEntryByScope(scope, slotKey) or nil
    if not entry then
        return nil
    end

    local item, dataset = nil, nil
    local slotDefinition, slotDataset = nil, nil
    if Equipment.ResolveItemDefinition then
        item, dataset = Equipment.ResolveItemDefinition(entry.itemRef)
    end
    if Equipment.ResolveSlotDefinition then
        slotDefinition, slotDataset = Equipment.ResolveSlotDefinition(entry.slotRef)
    end

    return {
        slotKey = Equipment.NormalizeSlotKey and Equipment.NormalizeSlotKey(slotKey) or slotKey,
        datasetId = entry.datasetId,
        itemId = entry.itemId,
        itemRef = entry.itemRef,
        slotRef = entry.slotRef,
        modifications = entry.modifications,
        soulbound = entry.soulbound == true,
        item = item,
        dataset = dataset,
        slotDefinition = slotDefinition,
        slotDataset = slotDataset,
        isMissing = item == nil,
        isActive = dataset and Database.IsDatasetActivated and Database.IsDatasetActivated(dataset.id) or false,
    }
end

function Profile.GetEquippedItem(slotKey)
    return Profile.GetEquippedItemByScope("character", slotKey)
end

function Profile.EquipItem(slotKey, itemRef, modifications, slotRef, soulbound)
    return Equipment.EquipItem and Equipment.EquipItem(slotKey, itemRef, modifications, slotRef, soulbound) or nil
end

local function getActiveEquipmentScope()
    local profileWindow = Addon.Client and Addon.Client.UI and Addon.Client.UI.Profile and Addon.Client.UI.Profile.Window or nil
    local activeProfileWindow = profileWindow and profileWindow.Get and profileWindow:Get() or nil
    local equipmentPage = activeProfileWindow and activeProfileWindow.equipmentStatsPage or nil
    if equipmentPage and equipmentPage.GetActiveEquipmentScope then
        return equipmentPage:GetActiveEquipmentScope()
    end

    return "character"
end

local function isVisibleEquipmentTabActive(profileWindow)
    if not profileWindow or not profileWindow.IsVisible or profileWindow:IsVisible() ~= true then
        return false
    end

    local activeTabKey = profileWindow.GetActiveTabKey and profileWindow:GetActiveTabKey() or ""
    return activeTabKey == "equipment"
end

local function getPreferredInventoryEquipScope(options, activeProfileWindow)
    local normalizedOptions = type(options) == "table" and options or nil
    local optionScope = normalizedOptions and ensureString(normalizedOptions.scope) or ""
    local optionTabKey = normalizedOptions and ensureString(normalizedOptions.activeTabKey) or ""
    if optionScope ~= "" and optionTabKey == "equipment" then
        return Equipment.NormalizeSlotType and Equipment.NormalizeSlotType(optionScope) or optionScope
    end

    if isVisibleEquipmentTabActive(activeProfileWindow) then
        return getActiveEquipmentScope()
    end

    return nil
end

local function appendInventoryEquipScopeCandidate(candidates, seen, scope)
    local normalizedScope = Equipment.NormalizeSlotType and Equipment.NormalizeSlotType(scope) or tostring(scope or "character")
    if normalizedScope == "" or seen[normalizedScope] then
        return
    end

    seen[normalizedScope] = true
    candidates[#candidates + 1] = normalizedScope
end

local function buildInventoryEquipScopeCandidates(item, preferredScope)
    local candidates = {}
    local seen = {}
    appendInventoryEquipScopeCandidate(candidates, seen, preferredScope)

    local slotRefs = item and item.validSlotRefs or nil
    for index = 1, #(slotRefs or {}) do
        local slotDefinition = Equipment.ResolveSlotDefinition and Equipment.ResolveSlotDefinition(slotRefs[index]) or nil
        local scope = slotDefinition and slotDefinition.slotType or nil
        appendInventoryEquipScopeCandidate(candidates, seen, scope)
    end

    if #candidates == 0 then
        appendInventoryEquipScopeCandidate(candidates, seen, "character")
    end

    return candidates
end

local function resolveInventoryEquipTarget(item, scope, preferredSlotKey)
    local activeLayout = Profile.GetEquipmentLayoutByScope and Profile.GetEquipmentLayoutByScope(scope) or Profile.GetEquipmentLayout()
    if preferredSlotKey and Equipment.DoesItemFitLayoutEntry then
        for layoutIndex = 1, #(activeLayout and activeLayout.entries or {}) do
            local layoutEntry = activeLayout.entries[layoutIndex]
            if layoutEntry and layoutEntry.slotKey == preferredSlotKey then
                local fits, resolvedSlotRef = Equipment.DoesItemFitLayoutEntry(item, layoutEntry)
                if fits and resolvedSlotRef then
                    return preferredSlotKey, resolvedSlotRef
                end
                break
            end
        end
    end

    if Equipment.FindBestSlotForItemInScope then
        return Equipment.FindBestSlotForItemInScope(item, activeLayout, scope)
    end

    return nil, nil
end

function Profile.EquipInventoryItem(slotIndex, record, options)
    local Inventory = getInventory()
    local profileWindow = Addon.Client and Addon.Client.UI and Addon.Client.UI.Profile and Addon.Client.UI.Profile.Window or nil
    local inventoryRecord = record or (Inventory.GetItem and Inventory.GetItem(slotIndex)) or nil
    local equipOptions = type(options) == "table" and options or nil
    if type(inventoryRecord) ~= "table" then
        return nil, "missing-item"
    end

    local itemRef = inventoryRecord.dataset and inventoryRecord.id and ("%s:%s"):format(tostring(inventoryRecord.dataset), tostring(inventoryRecord.id)) or nil
    if not itemRef then
        return nil, "invalid"
    end

    local item = Equipment.ResolveItemDefinition and Equipment.ResolveItemDefinition(itemRef) or nil
    if not item then
        return nil, "missing-item"
    end

    local activeProfileWindow = profileWindow and profileWindow.Get and profileWindow:Get() or nil
    local preferredScope = getPreferredInventoryEquipScope(equipOptions, activeProfileWindow)
    local preferredSlotKey = equipOptions and equipOptions.slotKey or nil
    if not preferredSlotKey and isVisibleEquipmentTabActive(activeProfileWindow) then
        preferredSlotKey = activeProfileWindow.SelectedSlotKey
    end

    local equipmentScope = nil
    local slotKey, slotRef = nil, nil
    local scopeCandidates = buildInventoryEquipScopeCandidates(item, preferredScope)
    for index = 1, #scopeCandidates do
        local candidateScope = scopeCandidates[index]
        slotKey, slotRef = resolveInventoryEquipTarget(item, candidateScope, preferredSlotKey)
        if slotKey and slotRef then
            equipmentScope = candidateScope
            break
        end
    end

    if not equipmentScope or not slotKey or not slotRef then
        return nil, "invalid-slot"
    end

    return runProfileEquipmentMutation(
        ("profile-%s-equipment-equip"):format(equipmentScope),
        function()
            local previousEntry = Equipment.GetEquippedEntryByScope and Equipment.GetEquippedEntryByScope(equipmentScope, slotKey) or nil
            local clearsOffHand = equipmentScope == "character"
                and (Equipment.NormalizeSlotKey and Equipment.NormalizeSlotKey(slotKey) or tostring(slotKey or "")) == "mainhand"
                and item.isTwoHanded == true
            local offHandEntry = clearsOffHand and Equipment.GetEquippedEntryByScope and Equipment.GetEquippedEntryByScope("character", "offhand") or nil
            if previousEntry and Inventory.AddItem then
                Inventory.AddItem({
                    dataset = previousEntry.datasetId,
                    id = previousEntry.itemId,
                    modifications = previousEntry.modifications,
                    soulbound = previousEntry.soulbound == true,
                }, { suppressLootNotification = true })
            end
            if offHandEntry and Inventory.AddItem then
                Inventory.AddItem({
                    dataset = offHandEntry.datasetId,
                    id = offHandEntry.itemId,
                    modifications = offHandEntry.modifications,
                    soulbound = offHandEntry.soulbound == true,
                }, { suppressLootNotification = true })
            end

            local itemClass = getItemClass()
            local equippedSoulbound = inventoryRecord.soulbound == true
                or (itemClass and itemClass.IsBindOnEquip and itemClass.IsBindOnEquip(item) or false)
            local equipped = Equipment.EquipItemInScope and Equipment.EquipItemInScope(equipmentScope, slotKey, itemRef, inventoryRecord.modifications, slotRef, equippedSoulbound) or nil
            if not equipped then
                return nil, "equip-failed"
            end

            if Inventory.RemoveItem then
                Inventory.RemoveItem(slotIndex)
            end

            return equipped, slotKey
        end
    )
end

function Profile.UnequipItem(slotKey)
    return Equipment.UnequipItem and Equipment.UnequipItem(slotKey) or false
end

function Profile.UnequipSlotToInventoryByScope(scope, slotKey)
    local Inventory = getInventory()
    local equippedEntry = Equipment.GetEquippedEntryByScope and Equipment.GetEquippedEntryByScope(scope, slotKey) or nil
    if not equippedEntry then
        return false
    end

    return runProfileEquipmentMutation(
        ("profile-%s-equipment-unequip"):format(Equipment.NormalizeSlotType and Equipment.NormalizeSlotType(scope) or tostring(scope or "character")),
        function()
            if Inventory.AddItem then
                Inventory.AddItem({
                    dataset = equippedEntry.datasetId,
                    id = equippedEntry.itemId,
                    modifications = equippedEntry.modifications,
                    soulbound = equippedEntry.soulbound == true,
                }, { suppressLootNotification = true })
            end

            return Equipment.UnequipItemInScope and Equipment.UnequipItemInScope(scope, slotKey) or false
        end
    )
end

function Profile.UnequipSlotToInventory(slotKey)
    return Profile.UnequipSlotToInventoryByScope("character", slotKey)
end

function Profile.ListResolvedStats(options)
    local rows = select(1, getCachedResolvedStatLookup(options))
    local cloned = {}
    for index = 1, #(rows or {}) do
        cloned[index] = cloneResolvedStatRow(rows[index])
    end
    return cloned
end

function Profile.GetResolvedStatRow(statRef, options)
    local normalizedRef = ensureString(statRef)
    if normalizedRef == "" then
        return nil
    end

    if canUseDefaultResolvedStatCache(options) then
        local _, rowsByRef = getCachedResolvedStatLookup(options)
        return cloneResolvedStatRow(rowsByRef and rowsByRef[normalizedRef] or nil)
    end

    if Resolver.GetResolvedStatRowsByRefs then
        local rows = Resolver.GetResolvedStatRowsByRefs({ normalizedRef }, options)
        return rows[1]
    end

    local _, rowsByRef = getCachedResolvedStatLookup(options)
    return cloneResolvedStatRow(rowsByRef and rowsByRef[normalizedRef] or nil)
end

function Profile.GetResolvedStatValue(statRef, fallback, options)
    local row = Profile.GetResolvedStatRow(statRef, options)
    local value = row and tonumber(row.value) or nil
    if value ~= nil then
        return value, true, row
    end

    if fallback ~= nil then
        return fallback, false, nil
    end

    return nil, false, nil
end

function Profile.ListResolvedResources(options, resolvedStatRows)
    local rows = getCachedResolvedResourceLookup(options, resolvedStatRows)
    local cloned = {}
    for index = 1, #(rows or {}) do
        cloned[index] = cloneResolvedResourceRow(rows[index])
    end
    return cloned
end

function Profile.GetResolvedResourceRow(resourceRef, options)
    local normalizedRef = ensureString(resourceRef)
    if normalizedRef == "" then
        return nil
    end

    if canUseDefaultResolvedResourceCache(options) then
        local _, rowsByRef = getCachedResolvedResourceLookup(options)
        return cloneResolvedResourceRow(rowsByRef and rowsByRef[normalizedRef] or nil)
    end

    if Resolver.GetResolvedResourceRowsByRefs then
        local rows = Resolver.GetResolvedResourceRowsByRefs({ normalizedRef }, options)
        return rows[1]
    end

    local resources = Profile.ListResolvedResources(options)
    for index = 1, #resources do
        local resourceRow = resources[index]
        if resourceRow and resourceRow.ref == normalizedRef then
            return resourceRow
        end
    end

    return nil
end

function Profile.GetResolvedStatRowsByRefs(statRefs, options)
    if canUseDefaultResolvedStatCache(options) then
        local _, rowsByRef = getCachedResolvedStatLookup(options)
        local rows = {}
        for index = 1, #(statRefs or {}) do
            local statRef = ensureString(statRefs[index])
            local row = rowsByRef and rowsByRef[statRef] or nil
            if row then
                rows[#rows + 1] = cloneResolvedStatRow(row)
            end
        end
        return rows
    end

    if Resolver.GetResolvedStatRowsByRefs then
        return Resolver.GetResolvedStatRowsByRefs(statRefs, options)
    end

    local rows = {}
    for index = 1, #(statRefs or {}) do
        local row = Profile.GetResolvedStatRow(statRefs[index], options)
        if row then
            rows[#rows + 1] = row
        end
    end
    return rows
end

function Profile.GetResolvedResourceRowsByRefs(resourceRefs, options)
    if canUseDefaultResolvedResourceCache(options) then
        local _, rowsByRef = getCachedResolvedResourceLookup(options)
        local rows = {}
        for index = 1, #(resourceRefs or {}) do
            local resourceRef = ensureString(resourceRefs[index])
            local row = rowsByRef and rowsByRef[resourceRef] or nil
            if row then
                rows[#rows + 1] = cloneResolvedResourceRow(row)
            end
        end
        return rows
    end

    if Resolver.GetResolvedResourceRowsByRefs then
        return Resolver.GetResolvedResourceRowsByRefs(resourceRefs, options)
    end

    local rows = {}
    for index = 1, #(resourceRefs or {}) do
        local row = Profile.GetResolvedResourceRow(resourceRefs[index], options)
        if row then
            rows[#rows + 1] = row
        end
    end
    return rows
end

function Profile.ListResolvedSkills(options)
    return Resolver.ListResolvedSkills and Resolver.ListResolvedSkills(options) or {}
end

function Profile.GetResolvedWeaponSkillRowsByWeaponType(options)
    local _, rowsByWeaponTypeRef = getCachedResolvedWeaponSkillLookup(options)
    return rowsByWeaponTypeRef
end

function Profile.GetResolvedSkillRowsByRefs(skillRefs, options)
    if Resolver.GetResolvedSkillRowsByRefs then
        return Resolver.GetResolvedSkillRowsByRefs(skillRefs, options)
    end

    local rows = {}
    for index = 1, #(skillRefs or {}) do
        local row = Profile.GetResolvedSkillRow(skillRefs[index], options)
        if row then
            rows[#rows + 1] = row
        end
    end
    return rows
end

function Profile.GetResolvedSkillRow(skillRef, options)
    local normalizedRef = ensureString(skillRef)
    if normalizedRef == "" then
        return nil
    end

    if Resolver.GetResolvedSkillRowsByRefs then
        local rows = Resolver.GetResolvedSkillRowsByRefs({ normalizedRef }, options)
        return rows[1]
    end

    local rows = Profile.ListResolvedSkills(options)
    for index = 1, #rows do
        local row = rows[index]
        if row and row.ref == normalizedRef then
            return row
        end
    end

    return nil
end

function Profile.ListKnownSpells(options)
    local lightweight = type(options) == "table" and options.lightweight == true
    if lightweight then
        local revision = getProfileConfigurationRevision()
        local cache = Profile.KnownSpellLightweightCache
        if type(cache) == "table" and tonumber(cache.revision) == revision and type(cache.rows) == "table" then
            return cache.rows
        end
    end

    local spellbook = buildKnownSpellRefs()
    local rows = {}

    for index = 1, #spellbook do
        if lightweight then
            local row = buildKnownSpellLightweightRow(spellbook[index], index)
            if row then
                rows[#rows + 1] = row
            end
        else
            local detail = Profile.GetKnownSpellDetails and Profile.GetKnownSpellDetails(spellbook[index]) or nil
            if detail then
                rows[#rows + 1] = {
                    rowIndex = index,
                    spellRef = detail.spellRef,
                    name = detail.name,
                    statusText = detail.statusText,
                    detailText = detail.summaryText,
                    isMissing = detail.isMissing,
                    dataset = detail.dataset,
                    spell = detail.spell,
                    spellbookCategory = detail.spellbookCategory,
                }
            end
        end
    end

    if lightweight then
        Profile.KnownSpellLightweightCache = {
            revision = getProfileConfigurationRevision(),
            rows = rows,
        }
    end

    return rows
end

function Profile.GetTraitCategory(trait)
    return getTraitCategoryFromDefinition(trait)
end

function Profile.GetTraitCountSummary()
    return buildTraitCountSummary()
end

function Profile.ListKnownTraits()
    local traitbook = buildEffectiveKnownTraitRefs()
    local activeTraitRefs = buildEffectiveActiveTraitRefs()
    local activeRefs = {}
    local rows = {}

    for index = 1, #activeTraitRefs do
        activeRefs[activeTraitRefs[index]] = true
    end

    for index = 1, #traitbook do
        local detail = Profile.GetKnownTraitDetails and Profile.GetKnownTraitDetails(traitbook[index]) or nil
        if detail and detail.isEnvironmental ~= true and detail.isVisibleToProfile == true then
            detail.isActive = activeRefs[detail.traitRef] == true
            rows[#rows + 1] = detail
        end
    end

    return rows
end

function Profile.ListActiveTraits()
    local traitbook = buildEffectiveActiveTraitRefs()
    local rows = {}

    for index = 1, #traitbook do
        local detail = Profile.GetKnownTraitDetails and Profile.GetKnownTraitDetails(traitbook[index]) or nil
        if detail and detail.isEnvironmental ~= true and detail.isVisibleToProfile == true then
            detail.isActive = true
            rows[#rows + 1] = detail
        end
    end

    return rows
end

function Profile.ListEquippedItemTraits()
    local rows = {}
    local equipped = Equipment.ListEquippedSlots and Equipment.ListEquippedSlots() or {}
    local modificationService = Profile.Modifications or {}

    local function appendItemTraitRow(rowData)
        local item = rowData and rowData.item or nil
        local entry = rowData and rowData.entry or nil
        local dataset = rowData and rowData.dataset or nil
        local payloadSource = rowData and rowData.payloadSource or nil
        local sourceType = rowData and rowData.sourceType or "equipment"
        local nameFallback = rowData and rowData.nameFallback or "Equipment Trait"
        local payload = type(payloadSource) == "table" and normalizeTraitPayload(payloadSource) or nil
        if not item or type(payload) ~= "table" then
            return
        end

        local itemName = trimString(item.name)
        local authoredDescriptionText = trimString(payload.description)
        local summaryText = getTraitSummaryText(payload, "No effects")
        local conditionOptions = {
            itemRef = rowData and rowData.itemRef or (entry and entry.itemRef or nil),
            item = item,
            equipmentScope = rowData and rowData.equipmentScope or nil,
            sourceItemRef = rowData and rowData.sourceItemRef or nil,
            sourceItem = rowData and rowData.sourceItem or nil,
        }
        local itemConditionState = evaluateDetailConditions("item", item, conditionOptions)
        local payloadConditionState = evaluateDetailConditions("trait", payload, conditionOptions)

        rows[#rows + 1] = {
            sourceType = sourceType,
            category = "equipment",
            slotKey = rowData and rowData.slotKey or nil,
            item = item,
            itemRef = conditionOptions.itemRef,
            itemName = itemName,
            name = itemName ~= "" and itemName or nameFallback,
            payload = payload,
            summaryText = summaryText,
            authoredDescriptionText = authoredDescriptionText,
            descriptionText = authoredDescriptionText ~= "" and authoredDescriptionText or summaryText,
            descriptionSource = authoredDescriptionText ~= "" and "authored" or "summary",
            icon = ensureString(item.icon),
            dataset = dataset,
            datasetId = dataset and dataset.id or nil,
            equipmentTrait = payloadSource,
            isMissing = false,
            conditionFailureText = itemConditionState.passed ~= true and itemConditionState.failureText or (payloadConditionState.passed ~= true and payloadConditionState.failureText or ""),
        }
    end

    for index = 1, #equipped do
        local slotEntry = equipped[index]
        local entry = slotEntry and slotEntry.entry or nil
        local item, dataset = nil, nil
        if entry and Equipment.ResolveItemDefinition then
            item, dataset = Equipment.ResolveItemDefinition(entry.itemRef)
        end

        local equipmentTrait = item and item.equipmentTrait or nil
        if item and type(equipmentTrait) == "table" then
            appendItemTraitRow({
                sourceType = "equipment",
                slotKey = slotEntry and slotEntry.slotKey or nil,
                item = item,
                itemRef = entry and entry.itemRef or nil,
                entry = entry,
                dataset = dataset,
                payloadSource = equipmentTrait,
                nameFallback = "Equipment Trait",
            })
        end

        local appliedMods = type(modificationService.ListAppliedModifications) == "function" and modificationService.ListAppliedModifications(entry and entry.modifications or nil) or {}
        for modIndex = 1, #appliedMods do
            local appliedMod = appliedMods[modIndex]
            local modItem = appliedMod and appliedMod.item or nil
            local modTrait = modItem and modItem.equipmentTrait or nil
            if type(modTrait) == "table" then
                appendItemTraitRow({
                    sourceType = "equipment_modification",
                    slotKey = slotEntry and slotEntry.slotKey or nil,
                    item = modItem,
                    itemRef = appliedMod and appliedMod.itemRef or nil,
                    entry = entry,
                    dataset = appliedMod and appliedMod.dataset or nil,
                    payloadSource = modTrait,
                    nameFallback = "Modification Effect",
                    sourceItemRef = entry and entry.itemRef or nil,
                    sourceItem = item,
                })
            end
        end
    end

    if Profile.IsMounted() and Equipment.ListMountEquippedSlots then
        local mountedEquipped = Equipment.ListMountEquippedSlots()
        for index = 1, #mountedEquipped do
            local slotEntry = mountedEquipped[index]
            local entry = slotEntry and slotEntry.entry or nil
            local item, dataset = nil, nil
            if entry and Equipment.ResolveItemDefinition then
                item, dataset = Equipment.ResolveItemDefinition(entry.itemRef)
            end

            local equipmentTrait = item and item.equipmentTrait or nil
            if item and type(equipmentTrait) == "table" then
                appendItemTraitRow({
                    sourceType = "mount_equipment",
                    slotKey = slotEntry and slotEntry.slotKey or nil,
                    item = item,
                    itemRef = entry and entry.itemRef or nil,
                    entry = entry,
                    dataset = dataset,
                    payloadSource = equipmentTrait,
                    nameFallback = "Mount Equipment Trait",
                    equipmentScope = "mount",
                })
            end

            local appliedMods = type(modificationService.ListAppliedModifications) == "function" and modificationService.ListAppliedModifications(entry and entry.modifications or nil) or {}
            for modIndex = 1, #appliedMods do
                local appliedMod = appliedMods[modIndex]
                local modItem = appliedMod and appliedMod.item or nil
                local modTrait = modItem and modItem.equipmentTrait or nil
                if type(modTrait) == "table" then
                    appendItemTraitRow({
                        sourceType = "mount_equipment_modification",
                        slotKey = slotEntry and slotEntry.slotKey or nil,
                        item = modItem,
                        itemRef = appliedMod and appliedMod.itemRef or nil,
                        entry = entry,
                        dataset = appliedMod and appliedMod.dataset or nil,
                        payloadSource = modTrait,
                        nameFallback = "Mount Modification Effect",
                        equipmentScope = "mount",
                        sourceItemRef = entry and entry.itemRef or nil,
                        sourceItem = item,
                    })
                end
            end
        end
    end

    table.sort(rows, function(left, right)
        local leftName = string.lower(ensureString(left and left.name))
        local rightName = string.lower(ensureString(right and right.name))
        if leftName == rightName then
            return ensureString(left and left.itemRef) < ensureString(right and right.itemRef)
        end
        return leftName < rightName
    end)

    return rows
end

function Profile.GetKnownTraitDetails(traitRef)
    local normalizedRef = ensureString(traitRef)
    if normalizedRef == "" then
        return nil
    end

    local registry = getRegistry()
    local dataset, trait = nil, nil
    if registry.ResolveTraitReference then
        dataset, trait = registry:ResolveTraitReference(normalizedRef)
    end

    local traitName = registry.ResolveTraitName and registry:ResolveTraitName(normalizedRef) or normalizedRef
    local datasetName = dataset and Database.GetDatasetDisplayName and Database.GetDatasetDisplayName(dataset) or "Unknown Dataset"
    local traitPayload = trait and normalizeTraitPayload(trait) or nil
    local authoredDescriptionText = traitPayload and trimString(traitPayload.description) or ""
    local summaryText = getTraitSummaryText(traitPayload, trait and "No effects" or "This trait definition is missing from its dataset.")
    local descriptionText = authoredDescriptionText
    local typeCategory = getTraitSourceCategory(trait)
    local unlockLevel = getTraitUnlockLevel(trait)
    local descriptionSource = authoredDescriptionText ~= "" and "authored" or "summary"
    local origin = getKnownTraitOrigin(normalizedRef) or "manual"
    local category = getTraitDisplayCategory(origin, typeCategory, trait)
    local isVisibleToProfile = false
    local isUnlockedForProfile = false
    local conditionState = evaluateDetailConditions("trait", traitPayload, {
        traitRef = normalizedRef,
    })

    if descriptionText == "" then
        descriptionText = summaryText
    end

    isUnlockedForProfile = unlockLevel <= getProfileLevel()

    local detail = {
        traitRef = normalizedRef,
        name = traitName,
        dataset = dataset,
        trait = trait,
        traitPayload = traitPayload,
        datasetName = datasetName,
        summaryText = summaryText,
        authoredDescriptionText = authoredDescriptionText,
        descriptionText = descriptionText,
        descriptionSource = descriptionSource,
        category = category,
        typeCategory = typeCategory,
        unlockLevel = unlockLevel,
        origin = origin,
        isAutoGranted = origin == "race" or origin == "class",
        isManual = origin == "manual",
        isToggleable = (origin == "manual" and typeCategory == "talent")
            or (origin == "class" and typeCategory == "talent"),
        isRemovable = origin == "manual"
            or (trait == nil and (origin == "race" or origin == "class")),
        icon = trait and trait.icon or "",
        isEnvironmental = trait and trait.isEnvironmental == true or false,
        isMissing = trait == nil,
        conditionFailureText = conditionState.passed ~= true and conditionState.failureText or "",
    }
    detail.isUnlockedForProfile = isUnlockedForProfile
    detail.isVisibleToProfile = isTraitDetailVisibleToProfile(detail)
    return detail
end

function Profile.ListAvailableConsumableTraits()
    local Inventory = getInventory()
    local displayItems = Inventory.GetDisplayItems and Inventory.GetDisplayItems() or {}
    local rows = {}
    local rowsByItemRef = {}
    local preferredConsumables = Database.ListProfilePreferredConsumables and Database.ListProfilePreferredConsumables() or {}
    local preferredLookup = {}

    for index = 1, #preferredConsumables do
        local itemRef = ensureString(preferredConsumables[index])
        if itemRef ~= "" then
            preferredLookup[itemRef] = true
        end
    end

    for index = 1, #displayItems do
        local resolved = displayItems[index]
        local item = resolved and resolved.item or nil
        local consumableTrait = item and item.consumableTrait or nil
        if resolved and resolved.isMissing ~= true and type(consumableTrait) == "table" then
            local itemRef = resolved.datasetId and resolved.itemId and ("%s:%s"):format(tostring(resolved.datasetId), tostring(resolved.itemId)) or ensureString(item and item.name)
            local itemName = trimString(item and item.name)
            local dataset = resolved.datasetId and findActivatedDatasetById(resolved.datasetId) or nil
            local datasetName = dataset and Database.GetDatasetDisplayName and Database.GetDatasetDisplayName(dataset) or "Unknown Dataset"
            local payload = normalizeTraitPayload(consumableTrait)
            local authoredDescriptionText = trimString(payload.description)
            local itemDescriptionText = trimString(item and item.description)
            local summaryText = itemDescriptionText ~= "" and itemDescriptionText or getTraitSummaryText(payload, "No effects")
            local descriptionText = authoredDescriptionText ~= "" and authoredDescriptionText or summaryText
            local descriptionSource = authoredDescriptionText ~= "" and "authored" or "summary"
            local itemIcon = ensureString(item and item.icon)
            local itemConditionState = evaluateDetailConditions("item", item, {
                itemRef = itemRef,
                item = item,
            })
            local payloadConditionState = evaluateDetailConditions("trait", payload, {
                itemRef = itemRef,
                item = item,
            })
            local row = rowsByItemRef[itemRef]
            if not row then
                row = {
                    itemRef = itemRef,
                    sourceIndex = resolved.sourceIndex,
                    sourceIndices = {},
                    resolvedItem = resolved,
                    item = item,
                    category = "consumable",
                    name = itemName ~= "" and itemName or "Consumable Trait",
                    itemName = itemName,
                    traitName = "",
                    dataset = dataset,
                    datasetId = resolved.datasetId,
                    datasetName = datasetName,
                    payload = payload,
                    summaryText = summaryText,
                    authoredDescriptionText = authoredDescriptionText,
                    descriptionText = descriptionText,
                    descriptionSource = descriptionSource,
                    icon = itemIcon,
                    phase = consumableTrait.phase,
                    consumableTrait = consumableTrait,
                    count = 0,
                    isToggleable = true,
                    isActive = preferredLookup[itemRef] == true,
                    conditionFailureText = itemConditionState.passed ~= true and itemConditionState.failureText or (payloadConditionState.passed ~= true and payloadConditionState.failureText or ""),
                }
                rowsByItemRef[itemRef] = row
                rows[#rows + 1] = row
            end

            row.count = (tonumber(row.count) or 0) + math.max(1, math.floor(tonumber(resolved.quantity) or 1))
            row.sourceIndices[#row.sourceIndices + 1] = resolved.sourceIndex
        end
    end

    table.sort(rows, function(left, right)
        local leftName = string.lower(ensureString(left and left.name))
        local rightName = string.lower(ensureString(right and right.name))
        if leftName == rightName then
            return ensureString(left and left.itemRef) < ensureString(right and right.itemRef)
        end
        return leftName < rightName
    end)

    return rows
end

function Profile.ListPreferredConsumableItemRefs()
    return Database.ListProfilePreferredConsumables and Database.ListProfilePreferredConsumables() or {}
end

function Profile.IsConsumableTraitPreferred(itemRef)
    local normalizedRef = ensureString(itemRef)
    if normalizedRef == "" then
        return false
    end

    local preferredConsumables = Profile.ListPreferredConsumableItemRefs and Profile.ListPreferredConsumableItemRefs() or {}
    for index = 1, #preferredConsumables do
        if ensureString(preferredConsumables[index]) == normalizedRef then
            return true
        end
    end

    return false
end

local function findAvailableConsumableTrait(itemRef)
    local normalizedRef = ensureString(itemRef)
    if normalizedRef == "" then
        return nil
    end

    local rows = Profile.ListAvailableConsumableTraits and Profile.ListAvailableConsumableTraits() or {}
    for index = 1, #rows do
        local row = rows[index]
        if ensureString(row and row.itemRef) == normalizedRef then
            return row
        end
    end

    return nil
end

function Profile.ActivateConsumableTrait(itemRef)
    local normalizedRef = ensureString(itemRef)
    if normalizedRef == "" then
        return false
    end

    local selectedRow = findAvailableConsumableTrait(normalizedRef)
    if not selectedRow then
        return false
    end

    if Database.AddProfilePreferredConsumable then
        return Database.AddProfilePreferredConsumable(normalizedRef)
    end

    return false
end

function Profile.DeactivateConsumableTrait(itemRef)
    local normalizedRef = ensureString(itemRef)
    if normalizedRef == "" then
        return false
    end

    if Database.RemoveProfilePreferredConsumable then
        return Database.RemoveProfilePreferredConsumable(normalizedRef)
    end

    return false
end

function Profile.ToggleConsumableTraitActivation(itemRef)
    local normalizedRef = ensureString(itemRef)
    if normalizedRef == "" then
        return nil
    end

    if Profile.IsConsumableTraitPreferred(normalizedRef) then
        return Profile.DeactivateConsumableTrait(normalizedRef) and "deactivated" or nil
    end

    return Profile.ActivateConsumableTrait(normalizedRef) and "activated" or nil
end

function Profile.AddKnownTrait(traitRef)
    local normalizedRef = ensureString(traitRef)
    if normalizedRef == "" then
        return false
    end

    local detail = Profile.GetKnownTraitDetails and Profile.GetKnownTraitDetails(normalizedRef) or nil
    if detail and detail.typeCategory ~= "talent" then
        return false
    end
    if detail and detail.isAutoGranted == true then
        return false
    end
    if detail and detail.isVisibleToProfile ~= true then
        return false
    end

    local summary = buildTraitCountSummary()
    if detail and detail.isEnvironmental ~= true then
        if summary.maxTotalTraits > 0 and summary.manualCount >= summary.maxTotalTraits then
            return false
        end
        if detail.typeCategory == "talent" and summary.maxTalentTraits > 0 and summary.manualTalentCount >= summary.maxTalentTraits then
            return false
        end
    end

    if Database.AddProfileTrait then
        local added = Database.AddProfileTrait(normalizedRef)
        if added and Database.AddProfileActiveTrait then
            Database.AddProfileActiveTrait(normalizedRef)
        end
        return added
    end

    return false
end

function Profile.RemoveKnownTrait(traitRef)
    local detail = Profile.GetKnownTraitDetails and Profile.GetKnownTraitDetails(traitRef) or nil
    if detail and detail.isMissing == true and detail.origin == "race" then
        return pruneSelectedOriginTraitRef("race", detail.traitRef)
    end
    if detail and detail.isMissing == true and detail.origin == "class" then
        return pruneSelectedOriginTraitRef("class", detail.traitRef)
    end

    if Database.RemoveProfileTrait then
        return Database.RemoveProfileTrait(traitRef)
    end

    return false
end

function Profile.IsTraitActive(traitRef)
    local normalizedRef = ensureString(traitRef)
    if normalizedRef == "" then
        return false
    end

    local activeTraitRefs = buildEffectiveActiveTraitRefs()
    for index = 1, #activeTraitRefs do
        if ensureString(activeTraitRefs[index]) == normalizedRef then
            return isTraitRefVisibleToProfileWithoutConditions(normalizedRef)
        end
    end

    return false
end

function Profile.ActivateTrait(traitRef)
    local normalizedRef = ensureString(traitRef)
    if normalizedRef == "" then
        return false
    end

    local detail = Profile.GetKnownTraitDetails and Profile.GetKnownTraitDetails(normalizedRef) or nil
    if detail and detail.isToggleable ~= true then
        return false
    end
    if detail and detail.isVisibleToProfile ~= true then
        return false
    end
    if detail and detail.origin == "manual" then
        local knownTraits = Database.ListProfileTraits and Database.ListProfileTraits() or {}
        local isKnown = false
        for index = 1, #knownTraits do
            if ensureString(knownTraits[index]) == normalizedRef then
                isKnown = true
                break
            end
        end
        if not isKnown then
            return false
        end
    end
    if Profile.IsTraitActive(normalizedRef) then
        return false
    end

    if detail and detail.origin == "class" and detail.typeCategory == "talent" then
        if Database.RemoveProfileInactiveTrait then
            Database.RemoveProfileInactiveTrait(normalizedRef)
        end
        return true
    end

    if Database.AddProfileActiveTrait then
        return Database.AddProfileActiveTrait(normalizedRef)
    end

    return false
end

function Profile.DeactivateTrait(traitRef)
    local detail = Profile.GetKnownTraitDetails and Profile.GetKnownTraitDetails(traitRef) or nil
    if detail and detail.isToggleable ~= true then
        return false
    end

    if detail and detail.origin == "class" and detail.typeCategory == "talent" then
        if Profile.IsTraitActive(traitRef) and Database.AddProfileInactiveTrait then
            Database.AddProfileInactiveTrait(traitRef)
            return true
        end
        return false
    end

    local profile = Database.GetActiveProfile and Database.GetActiveProfile() or nil
    local hasPersistedActiveTraits = type(profile) == "table" and profile.activeTraits ~= nil
    if not hasPersistedActiveTraits then
        local knownTraits = Database.ListProfileTraits and Database.ListProfileTraits() or {}
        if #knownTraits > 0 and Database.AddProfileActiveTrait then
            for index = 1, #knownTraits do
                Database.AddProfileActiveTrait(knownTraits[index])
            end
        end
    end

    if Database.RemoveProfileActiveTrait then
        return Database.RemoveProfileActiveTrait(traitRef)
    end

    return false
end

function Profile.ToggleTraitActivation(traitRef)
    local detail = Profile.GetKnownTraitDetails and Profile.GetKnownTraitDetails(traitRef) or nil
    if detail and detail.isToggleable ~= true then
        return nil
    end

    if Profile.IsTraitActive(traitRef) then
        return Profile.DeactivateTrait(traitRef) and "deactivated" or nil
    end

    if Profile.ActivateTrait(traitRef) then
        return "activated"
    end

    return nil
end

function Profile.RemoveKnownTraitAt(index)
    if Database.RemoveProfileTraitAt then
        return Database.RemoveProfileTraitAt(index)
    end

    return false
end

function Profile.GetKnownSpellDetails(spellRef)
    local normalizedRef = ensureString(spellRef)
    if normalizedRef == "" then
        return nil
    end

    local registry = getRegistry()
    local dataset, spell = nil, nil
    if registry.ResolveSpellReference then
        dataset, spell = registry:ResolveSpellReference(normalizedRef)
    end

    local spellName = registry.ResolveSpellName and registry:ResolveSpellName(normalizedRef) or normalizedRef
    local datasetName = dataset and Database.GetDatasetDisplayName and Database.GetDatasetDisplayName(dataset) or "Unknown Dataset"
    local summaryText = getSpellSummaryText(spell)
    local authoredDescriptionText = spell and trimString(spell.description) or ""
    local descriptionText = authoredDescriptionText
    local descriptionSource = authoredDescriptionText ~= "" and "authored" or "summary"
    local learnMode = spell and tostring(spell.learnMode or "trainer") or "unavailable"
    local conditionState = evaluateDetailConditions("spell", spell, {
        spellRef = normalizedRef,
    })

    if descriptionText == "" then
        descriptionText = summaryText
        descriptionSource = "summary"
    end

    return {
        spellRef = normalizedRef,
        name = spellName,
        dataset = dataset,
        spell = spell,
        datasetName = datasetName,
        statusText = getSpellStatusText(spell),
        cooldownText = getSpellCooldownText(spell),
        summaryText = summaryText,
        authoredDescriptionText = authoredDescriptionText,
        descriptionText = descriptionText,
        descriptionSource = descriptionSource,
        learnMode = learnMode,
        spellbookCategory = isSpellProvidedBySelectedMount(normalizedRef) and "Mounted" or (spell and trimString(spell.spellbookCategory) or ""),
        mountedCombatOnly = spell and spell.mountedCombatOnly == true or false,
        isMissing = spell == nil,
        conditionFailureText = conditionState.passed ~= true and conditionState.failureText or "",
    }
end

function Profile.AddKnownSpell(spellRef)
    if Database.AddProfileSpellbookSpell then
        local changed = Database.AddProfileSpellbookSpell(spellRef)
        if changed then
            bumpProfileTooltipContextRevision()
        end
        return changed
    end

    return false
end

function Profile.RemoveKnownSpell(spellRef)
    if Database.RemoveProfileSpellbookSpell then
        local changed = Database.RemoveProfileSpellbookSpell(spellRef)
        if changed then
            bumpProfileTooltipContextRevision()
        end
        return changed
    end

    return false
end

function Profile.RemoveKnownSpellAt(index)
    if Database.RemoveProfileSpellbookSpellAt then
        local changed = Database.RemoveProfileSpellbookSpellAt(index)
        if changed then
            bumpProfileTooltipContextRevision()
        end
        return changed
    end

    return false
end

function Profile.ListKnownRecipes()
    return getRecipeKnowledgeState().knownRecipeRefs or {}
end

function Profile.IsRecipeKnown(recipeRef)
    local normalizedRef = ensureString(recipeRef)
    if normalizedRef == "" then
        return false
    end

    local state = getRecipeKnowledgeState()
    return state.knownRecipeSet and state.knownRecipeSet[normalizedRef] == true or false
end

function Profile.ListKnownRecipeRefsForSkill(skillRef)
    local normalizedSkillRef = ensureString(skillRef)
    local state = getRecipeKnowledgeState()
    return state.knownRecipeRefsBySkill and state.knownRecipeRefsBySkill[normalizedSkillRef] or {}
end

function Profile.ListUnknownTrainerRecipeRefsForSkill(skillRef)
    local normalizedSkillRef = ensureString(skillRef)
    local state = getRecipeKnowledgeState()
    return state.unknownTrainerRecipeRefsBySkill and state.unknownTrainerRecipeRefsBySkill[normalizedSkillRef] or {}
end

function Profile.AddKnownRecipe(recipeRef)
    if Database.AddProfileRecipebookRecipe then
        local changed = Database.AddProfileRecipebookRecipe(recipeRef)
        if changed then
            Profile.RebuildPersistedRecipeKnowledge()
            bumpProfileTooltipContextRevision()
        end
        return changed
    end

    return false
end

function Profile.RemoveKnownRecipe(recipeRef)
    if Database.RemoveProfileRecipebookRecipe then
        local changed = Database.RemoveProfileRecipebookRecipe(recipeRef)
        if changed then
            Profile.RebuildPersistedRecipeKnowledge()
            bumpProfileTooltipContextRevision()
        end
        return changed
    end

    return false
end

function Profile.RemoveKnownRecipeAt(index)
    if Database.RemoveProfileRecipebookRecipeAt then
        local changed = Database.RemoveProfileRecipebookRecipeAt(index)
        if changed then
            Profile.RebuildPersistedRecipeKnowledge()
            bumpProfileTooltipContextRevision()
        end
        return changed
    end

    return false
end

function Profile.GetActionBarSize()
    return getActionBarSizeFromRuleset()
end

function Profile.GetActionBarLayoutMode()
    local mode = tostring(getInterfaceRuleValue("action_bar_layout", "complex"))
    return mode == "simple" and "simple" or "complex"
end

function Profile.GetActionBarMode()
    if Database.GetProfileActionBarMode then
        return Database.GetProfileActionBarMode()
    end

    return "spells"
end

local function hasSelectedMountActionBarSpells()
    local selectedMount = Profile.GetSelectedMount and Profile.GetSelectedMount() or nil
    local mount = selectedMount and selectedMount.mount or nil
    local spellRefs = mount and mount.spells or nil
    if type(spellRefs) ~= "table" then
        return false
    end

    for index = 1, #spellRefs do
        local spellRef = ensureString(spellRefs[index])
        if spellRef ~= "" then
            if not Profile.IsMountedActionBarRestricted or not Profile.IsMountedActionBarRestricted() then
                return true
            end
            if Profile.IsMountedCombatSpell and Profile.IsMountedCombatSpell(spellRef) then
                return true
            end
        end
    end

    return false
end

function Profile.ShouldUseMountedActionBar()
    return Profile.IsMounted()
        and (
            getInterfaceRuleValue("mounted_action_bar", false) == true
            or hasSelectedMountActionBarSpells()
        )
end

function Profile.IsMountedActionBarRestricted()
    return getInterfaceRuleValue("mounted_action_bar_only_mounted_combat_spells", false) == true
end

function Profile.AreWidgetsUnlocked()
    if Database.GetProfileWidgetsUnlocked then
        return Database.GetProfileWidgetsUnlocked()
    end

    return false
end

function Profile.SetWidgetsUnlocked(unlocked)
    if Database.SetProfileWidgetsUnlocked then
        return Database.SetProfileWidgetsUnlocked(unlocked)
    end

    return false
end

function Profile.SetActionBarMode(mode)
    if Database.SetProfileActionBarMode then
        return Database.SetProfileActionBarMode(mode)
    end

    return "spells"
end

function Profile.ToggleActionBarMode()
    local currentMode = Profile.GetActionBarMode()
    if currentMode == "skills" then
        return Profile.SetActionBarMode("spells")
    end

    return Profile.SetActionBarMode("skills")
end

function Profile.GetActionBarAnchor()
    if Database.GetProfileActionBarAnchor then
        return Database.GetProfileActionBarAnchor()
    end

    return nil
end

function Profile.GetPrimaryResourceRef()
    if Database.GetProfilePrimaryResourceRef then
        return Database.GetProfilePrimaryResourceRef()
    end

    return nil
end

function Profile.SetPrimaryResourceRef(resourceRef)
    if Database.SetProfilePrimaryResourceRef then
        return Database.SetProfilePrimaryResourceRef(resourceRef)
    end

    return nil
end

function Profile.GetSpecialResourceRef()
    if Database.GetProfileSpecialResourceRef then
        return Database.GetProfileSpecialResourceRef()
    end

    return nil
end

function Profile.SetSpecialResourceRef(resourceRef)
    if Database.SetProfileSpecialResourceRef then
        return Database.SetProfileSpecialResourceRef(resourceRef)
    end

    return nil
end

function Profile.GetLevel()
    if Database.GetProfileLevel then
        return Database.GetProfileLevel()
    end

    return 1
end

function Profile.SetLevel(level)
    if Database.SetProfileLevel then
        return Database.SetProfileLevel(level)
    end

    return 1
end

function Profile.GetRaceRef()
    if Database.GetProfileRaceRef then
        return Database.GetProfileRaceRef()
    end

    return nil
end

function Profile.SetRaceRef(raceRef)
    if Database.SetProfileRaceRef then
        return Database.SetProfileRaceRef(raceRef)
    end

    return nil
end

function Profile.GetClassRef()
    if Database.GetProfileClassRef then
        return Database.GetProfileClassRef()
    end

    return nil
end

function Profile.SetClassRef(classRef)
    if Database.SetProfileClassRef then
        return Database.SetProfileClassRef(classRef)
    end

    return nil
end

function Profile.GetSetupWizardState()
    if Database.GetProfileSetupWizardState then
        return Database.GetProfileSetupWizardState()
    end

    return nil
end

function Profile.SetSetupWizardState(state)
    if Database.SetProfileSetupWizardState then
        return Database.SetProfileSetupWizardState(state)
    end

    return nil
end

function Profile.GetResolvedBaseResourceValue(resourceRef, options)
    local row = Profile.GetResolvedResourceRow(resourceRef, options)
    return tonumber(row and row.baseResourceValue) or 0, row
end

function Profile.SetActionBarAnchor(anchor)
    if Database.SetProfileActionBarAnchor then
        return Database.SetProfileActionBarAnchor(anchor)
    end

    return nil
end

function Profile.ListActionBarBindings()
    return Database.ListProfileActionBar and Database.ListProfileActionBar() or {}
end

function Profile.ListSkillActionBarBindings()
    return Database.ListProfileSkillActionBar and Database.ListProfileSkillActionBar() or {}
end

function Profile.ListMountedActionBarBindings()
    return {}
end

function Profile.FindActionBarSlotBySpell(spellRef)
    if Database.FindProfileActionBarSlotBySpell then
        return Database.FindProfileActionBarSlotBySpell(spellRef)
    end

    return nil
end

function Profile.FindActionBarSlotBySkill(skillRef)
    if Database.FindProfileActionBarSlotBySkill then
        return Database.FindProfileActionBarSlotBySkill(skillRef)
    end

    return nil
end

function Profile.FindMountedActionBarSlotBySpell(spellRef)
    local normalizedRef = ensureString(spellRef)
    if normalizedRef == "" then
        return nil
    end

    local rows = Profile.ListMountedActionBarSlots and Profile.ListMountedActionBarSlots() or {}
    for slotIndex = 1, #rows do
        if ensureString(rows[slotIndex] and rows[slotIndex].spellRef) == normalizedRef then
            return slotIndex
        end
    end

    return nil
end

function Profile.BindSpellToActionBarSlot(slotIndex, spellRef)
    if Database.BindProfileActionBarSpell then
        local changed = Database.BindProfileActionBarSpell(slotIndex, spellRef)
        if changed then
            bumpProfileTooltipContextRevision()
        end
        return changed
    end

    return nil
end

function Profile.IsMountedCombatSpell(spellRef)
    local detail = Profile.GetKnownSpellDetails and Profile.GetKnownSpellDetails(spellRef) or nil
    return detail and detail.mountedCombatOnly == true or false
end

function Profile.CanBindSpellToMountedActionBar(spellRef)
    return false
end

function Profile.BindSpellToMountedActionBarSlot(slotIndex, spellRef)
    return nil
end

local function isBindableSkillRow(row)
    return type(row) == "table"
        and tostring(row.skillType or "") == "noncombat"
        and row.rollable == true
end

function Profile.BindSkillToActionBarSlot(slotIndex, skillRef)
    local row = Profile.GetResolvedSkillRow and Profile.GetResolvedSkillRow(skillRef) or nil
    if not isBindableSkillRow(row) then
        return nil
    end

    if Database.BindProfileActionBarSkill then
        local changed = Database.BindProfileActionBarSkill(slotIndex, skillRef)
        if changed then
            bumpProfileTooltipContextRevision()
        end
        return changed
    end

    return nil
end

function Profile.UnbindSpellFromActionBar(spellRef)
    if Database.UnbindProfileActionBarSpell then
        local changed = Database.UnbindProfileActionBarSpell(spellRef)
        if changed then
            bumpProfileTooltipContextRevision()
        end
        return changed
    end

    return false
end

function Profile.UnbindSkillFromActionBar(skillRef)
    if Database.UnbindProfileActionBarSkill then
        local changed = Database.UnbindProfileActionBarSkill(skillRef)
        if changed then
            bumpProfileTooltipContextRevision()
        end
        return changed
    end

    return false
end

function Profile.UnbindSpellFromMountedActionBar(spellRef)
    return false
end

function Profile.ClearActionBarSlot(slotIndex)
    if Database.ClearProfileActionBarSlot then
        return Database.ClearProfileActionBarSlot(slotIndex)
    end

    return false
end

function Profile.ClearSkillActionBarSlot(slotIndex)
    if Database.ClearProfileSkillActionBarSlot then
        return Database.ClearProfileSkillActionBarSlot(slotIndex)
    end

    return false
end

function Profile.ClearMountedActionBarSlot(slotIndex)
    return false
end

function Profile.BindSpellToFirstAvailableActionBarSlot(spellRef)
    local bindings = Profile.ListActionBarBindings()
    local size = Profile.GetActionBarSize()

    for slotIndex = 1, size do
        if bindings[slotIndex] == nil or bindings[slotIndex] == "" then
            return Profile.BindSpellToActionBarSlot(slotIndex, spellRef)
        end
    end

    return nil
end

function Profile.BindSpellToFirstAvailableMountedActionBarSlot(spellRef)
    return nil
end

function Profile.BindSkillToFirstAvailableActionBarSlot(skillRef)
    local row = Profile.GetResolvedSkillRow and Profile.GetResolvedSkillRow(skillRef) or nil
    if not isBindableSkillRow(row) then
        return nil
    end

    local bindings = Profile.ListSkillActionBarBindings()
    local size = Profile.GetActionBarSize()

    for slotIndex = 1, size do
        if bindings[slotIndex] == nil or bindings[slotIndex] == "" then
            return Profile.BindSkillToActionBarSlot(slotIndex, skillRef)
        end
    end

    return nil
end

function Profile.ToggleSpellActionBarBinding(spellRef)
    local boundSlot = Profile.FindActionBarSlotBySpell(spellRef)
    if boundSlot then
        return Profile.UnbindSpellFromActionBar(spellRef) and "unbound" or nil, boundSlot
    end

    local slotIndex = Profile.BindSpellToFirstAvailableActionBarSlot(spellRef)
    if slotIndex then
        return "bound", slotIndex
    end

    return nil, nil
end

function Profile.ToggleSkillActionBarBinding(skillRef)
    local boundSlot = Profile.FindActionBarSlotBySkill(skillRef)
    if boundSlot then
        return Profile.UnbindSkillFromActionBar(skillRef) and "unbound" or nil, boundSlot
    end

    local slotIndex = Profile.BindSkillToFirstAvailableActionBarSlot(skillRef)
    if slotIndex then
        return "bound", slotIndex
    end

    return nil, nil
end

function Profile.ToggleMountedSpellActionBarBinding(spellRef)
    return nil, nil
end

local function getMountedActionBarSpellRefs()
    local selectedMount = Profile.GetSelectedMount and Profile.GetSelectedMount() or nil
    local mount = selectedMount and selectedMount.mount or nil
    local spellRefs = mount and mount.spells or nil
    if type(spellRefs) ~= "table" then
        return {}
    end

    local filtered = {}
    for index = 1, #spellRefs do
        local spellRef = ensureString(spellRefs[index])
        if spellRef ~= "" then
            if not Profile.IsMountedActionBarRestricted() or Profile.IsMountedCombatSpell(spellRef) then
                filtered[#filtered + 1] = spellRef
            end
        end
    end

    return filtered
end

function Profile.GetActionBarSlotDetails(slotIndex)
    local spellRef = Database.GetProfileActionBarSpell and Database.GetProfileActionBarSpell(slotIndex) or nil
    if not spellRef then
        return nil
    end

    local detail = Profile.GetKnownSpellDetails and Profile.GetKnownSpellDetails(spellRef) or nil
    if not detail then
        return nil
    end

    detail.slotIndex = math.floor(tonumber(slotIndex) or 0)
    detail.actionBarKind = "spell"
    return detail
end

function Profile.GetSkillActionBarSlotDetails(slotIndex)
    local skillRef = Database.GetProfileActionBarSkill and Database.GetProfileActionBarSkill(slotIndex) or nil
    if not skillRef then
        return nil
    end

    local row = Profile.GetResolvedSkillRow and Profile.GetResolvedSkillRow(skillRef) or nil
    if not isBindableSkillRow(row) then
        return nil
    end

    local detail = {}
    for key, value in pairs(row) do
        detail[key] = value
    end
    detail.slotIndex = math.floor(tonumber(slotIndex) or 0)
    detail.actionBarKind = "skill"
    return detail
end

function Profile.GetMountedActionBarSlotDetails(slotIndex)
    local mountedSpellRefs = getMountedActionBarSpellRefs()
    local spellRef = mountedSpellRefs[math.floor(tonumber(slotIndex) or 0)]
    if not spellRef then
        return nil
    end

    local detail = Profile.GetKnownSpellDetails and Profile.GetKnownSpellDetails(spellRef) or nil
    if not detail then
        return nil
    end

    detail.slotIndex = math.floor(tonumber(slotIndex) or 0)
    detail.actionBarKind = "mounted-spell"
    return detail
end

local function isAutoHitSpell(spell)
    for componentIndex = 1, #((spell and spell.components) or {}) do
        local component = spell.components[componentIndex]
        local effect = type(component) == "table" and component.effect or nil
        if type(effect) == "table" and tostring(effect.hitType or "ability") == "auto" then
            return true
        end
    end

    return false
end

function Profile.ListEligibleAutoHitSpellDetails()
    local rows = {}
    local spellRefs = buildKnownSpellRefs()

    for index = 1, #spellRefs do
        local detail = Profile.GetKnownSpellDetails and Profile.GetKnownSpellDetails(spellRefs[index]) or nil
        if detail
            and isAutoHitSpell(detail.spell)
            and detail.conditionFailureText == ""
        then
            detail.actionBarKind = "auto-spell"
            rows[#rows + 1] = detail
        end
    end

    return rows
end

function Profile.ListActionBarSlots()
    local size = Profile.GetActionBarSize()
    local rows = {}

    local autoHitRows = Profile.ListEligibleAutoHitSpellDetails()
    for index = 1, #autoHitRows do
        rows[#rows + 1] = autoHitRows[index]
    end
    rows.autoHitSpellCount = #autoHitRows

    for slotIndex = 1, size do
        -- Keep the list dense: action bar rendering uses its length to reserve
        -- every configured slot after the automatic entries.
        rows[#rows + 1] = Profile.GetActionBarSlotDetails(slotIndex) or false
    end

    return rows
end

function Profile.ListSkillActionBarSlots()
    local size = Profile.GetActionBarSize()
    local rows = {}

    for slotIndex = 1, size do
        rows[slotIndex] = Profile.GetSkillActionBarSlotDetails(slotIndex)
    end

    return rows
end

function Profile.ListMountedActionBarSlots()
    local size = Profile.GetActionBarSize()
    local rows = {}

    for slotIndex = 1, size do
        rows[slotIndex] = Profile.GetMountedActionBarSlotDetails(slotIndex)
    end

    return rows
end

function Profile.GetStatBonus(statRef)
    if Database.GetProfileStatBonus then
        return Database.GetProfileStatBonus(statRef)
    end

    return 0
end

function Profile.SetStatBonus(statRef, value)
    if Database.SetProfileStatBonus then
        return Database.SetProfileStatBonus(statRef, value)
    end

    return nil
end

function Profile.ClearStatBonus(statRef)
    if Database.ClearProfileStatBonus then
        return Database.ClearProfileStatBonus(statRef)
    end

    return false
end

function Profile.ListSkillPermanentBonuses()
    if Database.ListProfileSkillPermanentBonuses then
        return Database.ListProfileSkillPermanentBonuses()
    end

    return {}
end

function Profile.GetSkillPermanentBonus(skillRef)
    if Database.GetProfileSkillPermanentBonus then
        return Database.GetProfileSkillPermanentBonus(skillRef)
    end

    return 0
end

function Profile.SetSkillPermanentBonus(skillRef, value)
    if Database.SetProfileSkillPermanentBonus then
        return Database.SetProfileSkillPermanentBonus(skillRef, value)
    end

    return nil
end

function Profile.ClearSkillPermanentBonus(skillRef)
    if Database.ClearProfileSkillPermanentBonus then
        return Database.ClearProfileSkillPermanentBonus(skillRef)
    end

    return false
end

function Profile.ListSkillLevels()
    if Database.ListProfileSkillLevels then
        return Database.ListProfileSkillLevels()
    end

    return {}
end

function Profile.RegisterSkillChangeListener(listener)
    if type(listener) ~= "function" then
        return nil
    end

    Profile._nextSkillChangeListenerId = (tonumber(Profile._nextSkillChangeListenerId) or 0) + 1
    local listenerId = Profile._nextSkillChangeListenerId
    Profile._skillChangeListeners[listenerId] = listener
    return listenerId
end

function Profile.UnregisterSkillChangeListener(listenerId)
    local normalizedId = tonumber(listenerId)
    if not normalizedId or Profile._skillChangeListeners[normalizedId] == nil then
        return false
    end

    Profile._skillChangeListeners[normalizedId] = nil
    return true
end

function Profile.GetSkillLevel(skillRef)
    if Database.GetProfileSkillLevel then
        return Database.GetProfileSkillLevel(skillRef)
    end

    return 0
end

function Profile.SetSkillLevel(skillRef, value)
    if Database.SetProfileSkillLevel then
        local previousLevel = normalizeSkillLevel(Profile.GetSkillLevel(skillRef))
        local updatedLevel = Database.SetProfileSkillLevel(skillRef, value)
        if updatedLevel ~= nil then
            local normalizedUpdatedLevel = normalizeSkillLevel(updatedLevel)
            notifySkillChangeListeners(
                ensureString(skillRef),
                previousLevel,
                normalizedUpdatedLevel
            )
        end
        return updatedLevel
    end

    return nil
end

function Profile.ClearSkillLevel(skillRef)
    if Database.ClearProfileSkillLevel then
        return Database.ClearProfileSkillLevel(skillRef)
    end

    return false
end

function Profile.ListProfileStatRows(options, resolvedStatRows)
    local resolvedStats = resolvedStatRows
    if type(resolvedStats) ~= "table" then
        resolvedStats = Profile.ListResolvedStats(options)
    end
    local grouped = {}
    local rows = {}
    local movementRangeStatRef = Profile.GetMovementRangeStatRef and ensureString(Profile.GetMovementRangeStatRef()) or ""

    for index = 1, #resolvedStats do
        local statRow = resolvedStats[index]
        local stat = statRow and statRow.stat or nil
        if stat and stat.visibility == true and ensureString(statRow and statRow.ref) ~= movementRangeStatRef then
            local categoryName = trimString(stat.category)
            if categoryName ~= "" then
                local bucket = grouped[categoryName]
                if not bucket then
                    bucket = {}
                    grouped[categoryName] = bucket
                end

                bucket[#bucket + 1] = statRow
            end
        end
    end

    local categoryOrder = {}
    for categoryName in pairs(grouped) do
        categoryOrder[#categoryOrder + 1] = categoryName
    end

    table.sort(categoryOrder, function(left, right)
        local leftFallback = string.byte(string.lower(tostring(left)), 1) or 0
        local rightFallback = string.byte(string.lower(tostring(right)), 1) or 0
        local leftOrder = PROFILE_STAT_CATEGORY_ORDER_LOOKUP[left] or (1000 + leftFallback)
        local rightOrder = PROFILE_STAT_CATEGORY_ORDER_LOOKUP[right] or (1000 + rightFallback)
        if leftOrder == rightOrder then
            return string.lower(tostring(left)) < string.lower(tostring(right))
        end
        return leftOrder < rightOrder
    end)

    for index = 1, #categoryOrder do
        local categoryName = categoryOrder[index]
        local bucket = grouped[categoryName] or {}
        if #bucket > 0 then
            rows[#rows + 1] = {
                rowType = "header",
                category = categoryName,
            }

            for statIndex = 1, #bucket do
                local statRow = bucket[statIndex]
                rows[#rows + 1] = {
                    rowType = "stat",
                    category = categoryName,
                    statRow = statRow,
                }
            end
        end
    end

    return rows
end

local function buildProfileItemLevelSummary(equippedBySlot, orderedSlotKeys)
    local itemClass = getItemClass()
    local summary = {
        total = 0,
        count = 0,
        minimum = nil,
        maximum = nil,
    }

    if getRulesetValue("interface", "use_item_level", true) ~= true then
        return summary
    end

    if type(itemClass) ~= "table"
        or type(itemClass.IsItemLevelEligible) ~= "function"
        or type(itemClass.ResolveItemLevel) ~= "function"
    then
        return summary
    end

    for index = 1, #(orderedSlotKeys or {}) do
        local slotInfo = equippedBySlot and equippedBySlot[orderedSlotKeys[index]] or nil
        local item = slotInfo and slotInfo.item or nil
        if slotInfo and slotInfo.isMissing ~= true
            and type(item) == "table"
            and itemClass.IsItemLevelEligible(item)
        then
            local itemLevel = math.max(0, math.floor(tonumber(itemClass.ResolveItemLevel(item)) or 0))
            if itemLevel > 0 then
                summary.total = summary.total + itemLevel
                summary.count = summary.count + 1
                summary.minimum = summary.minimum and math.min(summary.minimum, itemLevel) or itemLevel
                summary.maximum = summary.maximum and math.max(summary.maximum, itemLevel) or itemLevel
            end
        end
    end

    return summary
end

function Profile.GetPresentationSnapshot(scope)
    local normalizedScope = Equipment.NormalizeSlotType and Equipment.NormalizeSlotType(scope) or tostring(scope or "character")
    if normalizedScope ~= "mount" and normalizedScope ~= "pet" then
        normalizedScope = "character"
    end

    local configurationRevision = getProfileConfigurationRevision()
    local profileStatsRevision = getProfileRevision("ProfileStatsRevision")
    local profileResourcesRevision = getProfileRevision("ProfileResourcesRevision")
    local equipmentRevision = getProfileRevision("EquipmentRevision")
    local resolvedProfileRevision = getProfileRevision("ResolvedProfileRevision")
    local profileRuntimeRevision = getProfileRuntimeRevision()
    local resolverRevisionKey = getProfileResolverRevisionKey()
    local identityKey = getProfileIdentityKey()
    local cacheKey = table.concat({
        tostring(configurationRevision),
        tostring(profileStatsRevision),
        tostring(profileResourcesRevision),
        tostring(equipmentRevision),
        tostring(resolvedProfileRevision),
        tostring(profileRuntimeRevision),
        resolverRevisionKey,
        tostring(identityKey),
        normalizedScope,
    }, ":")

    local cached = Profile.ProfilePresentationSnapshotCache
    if type(cached) == "table" and tostring(cached.key or "") == cacheKey then
        return cached
    end

    local layout = Profile.GetEquipmentLayoutByScope(normalizedScope) or {
        left = {},
        right = {},
        bottom = {},
        ordered = {},
        entries = {},
    }
    local equippedBySlot = {}
    for index = 1, #(layout.ordered or {}) do
        local slotKey = layout.ordered[index]
        equippedBySlot[slotKey] = Profile.GetEquippedItemByScope(normalizedScope, slotKey)
    end

    local resolvedStatRows = Profile.ListResolvedStats()
    local statRows = Profile.ListProfileStatRows(nil, resolvedStatRows)
    local resourceRows = Profile.ListResolvedResources(nil, resolvedStatRows)
    local healthResourceRef = getRulesetValue("resources", "health_stat", nil)
    if type(healthResourceRef) ~= "string" then
        healthResourceRef = nil
    end
    local movementStatRef = Profile.GetMovementRangeStatRef and Profile.GetMovementRangeStatRef() or nil
    local movementStatRow = movementStatRef and Profile.GetResolvedStatRow(movementStatRef) or nil

    local snapshot = {
        key = cacheKey,
        revisions = {
            configurationRevision = configurationRevision,
            profileStatsRevision = profileStatsRevision,
            profileResourcesRevision = profileResourcesRevision,
            equipmentRevision = equipmentRevision,
            resolvedProfileRevision = resolvedProfileRevision,
            profileRuntimeRevision = profileRuntimeRevision,
            resolverRevisionKey = resolverRevisionKey,
        },
        scope = normalizedScope,
        layout = layout,
        equippedBySlot = equippedBySlot,
        statRows = statRows,
        resourceRows = resourceRows,
        healthResourceRef = healthResourceRef,
        movementStatRow = movementStatRow,
        raceRef = Profile.GetRaceRef and Profile.GetRaceRef() or nil,
        classRef = Profile.GetClassRef and Profile.GetClassRef() or nil,
        level = Profile.GetLevel and Profile.GetLevel() or 1,
        primaryResourceRef = Profile.GetPrimaryResourceRef and Profile.GetPrimaryResourceRef() or nil,
        specialResourceRef = Profile.GetSpecialResourceRef and Profile.GetSpecialResourceRef() or nil,
        mountRef = Profile.GetMountRef and Profile.GetMountRef() or nil,
        petRef = Profile.GetPetRef and Profile.GetPetRef() or nil,
        itemLevelSummary = buildProfileItemLevelSummary(equippedBySlot, layout.ordered),
    }

    Profile.ProfilePresentationSnapshotCache = snapshot
    return snapshot
end

function Profile.ListEquipableItemsForSlot(slotKey)
    return Equipment.ListEquipableItemsForSlot and Equipment.ListEquipableItemsForSlot(slotKey) or {}
end

function Profile.ListEquipableItemsForScopeSlot(scope, slotKey)
    local rows = Equipment.ListEquipableItemsForScopeSlot and Equipment.ListEquipableItemsForScopeSlot(scope, slotKey) or {}
    local normalizedScope = Equipment.NormalizeSlotType and Equipment.NormalizeSlotType(scope) or tostring(scope or "character")
    if normalizedScope ~= "pet" then
        return rows
    end

    local filtered = {}
    local layout = Profile.GetPetLayout and Profile.GetPetLayout() or nil
    local slotEntries = layout and layout.entries or {}
    local allowedSlotRefs = {}
    local normalizedSlotKey = Equipment.NormalizeSlotKey and Equipment.NormalizeSlotKey(slotKey) or ensureString(slotKey)

    for index = 1, #slotEntries do
        local entry = slotEntries[index]
        if entry and entry.slotKey == normalizedSlotKey then
            allowedSlotRefs[ensureString(entry.slotRef)] = true
        end
    end

    for index = 1, #rows do
        local row = rows[index]
        if allowedSlotRefs[ensureString(row and row.slotRef)] == true then
            filtered[#filtered + 1] = row
        end
    end

    return filtered
end

function Profile.ListMountEquippedSlots()
    return Profile.ListEquippedSlotsByScope("mount")
end

function Profile.GetEquippedMountItem(slotKey)
    return Profile.GetEquippedItemByScope("mount", slotKey)
end

function Profile.EquipMountItem(slotKey, itemRef, modifications, slotRef, soulbound)
    local layout = Profile.GetEquipmentLayoutByScope and Profile.GetEquipmentLayoutByScope("mount") or Profile.GetMountLayout()
    local normalizedSlotKey = Equipment.NormalizeSlotKey and Equipment.NormalizeSlotKey(slotKey) or ensureString(slotKey)
    local allowed = false
    for index = 1, #(layout.entries or {}) do
        local entry = layout.entries[index]
        if entry and entry.slotKey == normalizedSlotKey then
            allowed = true
            if ensureString(slotRef) == "" then
                slotRef = entry.slotRef
            end
            break
        end
    end
    if not allowed then
        return nil, "invalid-slot"
    end

    return Equipment.EquipItemInScope and Equipment.EquipItemInScope("mount", slotKey, itemRef, modifications, slotRef, soulbound) or nil
end

function Profile.UnequipMountItem(slotKey)
    return Equipment.UnequipItemInScope and Equipment.UnequipItemInScope("mount", slotKey) or false
end

function Profile.ListEquipableMountItemsForSlot(slotKey)
    return Profile.ListEquipableItemsForScopeSlot("mount", slotKey)
end

function Profile.ListPetEquippedSlots()
    return Profile.ListEquippedSlotsByScope("pet")
end

function Profile.GetEquippedPetItem(slotKey)
    return Profile.GetEquippedItemByScope("pet", slotKey)
end

function Profile.EquipPetItem(slotKey, itemRef, modifications, slotRef, soulbound)
    local layout = Profile.GetPetLayout and Profile.GetPetLayout() or buildSlotLayoutFromRefs({})
    local normalizedSlotKey = Equipment.NormalizeSlotKey and Equipment.NormalizeSlotKey(slotKey) or ensureString(slotKey)
    local allowed = false
    for index = 1, #(layout.entries or {}) do
        local entry = layout.entries[index]
        if entry and entry.slotKey == normalizedSlotKey then
            allowed = true
            if ensureString(slotRef) == "" then
                slotRef = entry.slotRef
            end
            break
        end
    end
    if not allowed then
        return nil, "invalid-slot"
    end

    return Equipment.EquipItemInScope and Equipment.EquipItemInScope("pet", slotKey, itemRef, modifications, slotRef, soulbound) or nil
end

function Profile.UnequipPetItem(slotKey)
    return Equipment.UnequipItemInScope and Equipment.UnequipItemInScope("pet", slotKey) or false
end

function Profile.ListEquipablePetItemsForSlot(slotKey)
    return Profile.ListEquipableItemsForScopeSlot("pet", slotKey)
end

function Profile.GetMovementRangeStatRef()
    local value = getMountRuleValue("movement_range_stat", "")
    return type(value) == "string" and value or ""
end

function Profile.GetMovementRangeValue()
    local statRef = Profile.GetMovementRangeStatRef()
    local baseValue = nil
    if statRef ~= "" then
        baseValue = Profile.GetResolvedStatValue and Profile.GetResolvedStatValue(statRef, 0) or 0
    end

    local auraManager = Addon.Client and Addon.Client.Spellcasting and Addon.Client.Spellcasting.AuraManager or nil
    if auraManager and type(auraManager.GetLocalPlayerMovementRangeOverride) == "function" then
        local overrideValue = auraManager:GetLocalPlayerMovementRangeOverride()
        if overrideValue ~= nil then
            return overrideValue
        end
    end

    return baseValue
end

function Profile.GetMaximumHealthRow(options)
    local rulesetLogic = getRuleset()
    local ruleset = rulesetLogic.GetActiveRuleset and rulesetLogic.GetActiveRuleset() or nil
    local ruleDefinition = rulesetLogic.GetRulesetRuleDefinition and rulesetLogic.GetRulesetRuleDefinition("resources", "health_stat") or nil
    local healthResourceRef = rulesetLogic.GetRulesetRuleValue and rulesetLogic.GetRulesetRuleValue(ruleset, "resources", ruleDefinition) or nil
    if type(healthResourceRef) ~= "string" or healthResourceRef == "" then
        return nil
    end

    local resources = Profile.ListResolvedResources(options)
    for index = 1, #resources do
        local resourceRow = resources[index]
        if resourceRow and resourceRow.ref == healthResourceRef then
            return resourceRow
        end
    end

    return nil
end

function Profile.GetHealthResourceRef(options)
    local healthRow = Profile.GetMaximumHealthRow(options)
    return healthRow and healthRow.ref or nil
end

function Profile.GetSlotLabel(slotKey)
    if Equipment.PrettySlotLabel then
        return Equipment.PrettySlotLabel(slotKey)
    end

    local label = ensureString(slotKey)
    if label == "" then
        return "Slot"
    end

    return label
end

function Profile.GetSlotTexture(slotKey)
    return Equipment.GetSlotTexture and Equipment.GetSlotTexture(slotKey) or "Interface\\Icons\\INV_Misc_QuestionMark"
end

return Profile
