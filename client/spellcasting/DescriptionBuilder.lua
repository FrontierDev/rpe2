local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Client.Spellcasting = Addon.Client.Spellcasting or {}
Addon.Internal = Addon.Internal or {}
Addon.Internal.Comms = Addon.Internal.Comms or {}

local Client = Addon.Client or {}
local Spellcasting = Addon.Client.Spellcasting or {}
local Combat = Addon.Client and Addon.Client.Combat or {}
local Profile = Addon.Internal and Addon.Internal.Profile or {}
local Database = Addon.Internal and Addon.Internal.Database or {}
local Registry = Addon.Internal and Addon.Internal.Registry or {}
local Dependencies = Database and Database.Dependecies or {}
local ResourceSync = Addon.Internal and Addon.Internal.Comms and Addon.Internal.Comms.ResourceSync or {}
local Common = Addon.Utils and Addon.Utils.Common or {}
local UI = Addon.UI or {}
local AuraDescriptionBuilder = Spellcasting.AuraDescriptionBuilder or {}

local DescriptionBuilder = Spellcasting.DescriptionBuilder or {}
Spellcasting.DescriptionBuilder = DescriptionBuilder
DescriptionBuilder.ProfileTooltipContextRevision = math.max(1, math.floor(tonumber(DescriptionBuilder.ProfileTooltipContextRevision) or 1))
DescriptionBuilder.EventTooltipContextRevisions = DescriptionBuilder.EventTooltipContextRevisions or {}
DescriptionBuilder.PseudoCasterUnitCache = DescriptionBuilder.PseudoCasterUnitCache or nil

local MIN_VARIANCE = 0.9
local MAX_VARIANCE = 1.1

local function getTasks()
    return Addon.Internal and Addon.Internal.Tasks or nil
end

local function enqueueDescriptionWork(fn, ...)
    local tasks = getTasks()
    if tasks and tasks.Enqueue then
        tasks:Enqueue(fn, ...)
        return true
    end

    return false
end

local function trimText(value)
    local text = tostring(value or "")
    text = string.gsub(text, "^%s+", "")
    text = string.gsub(text, "%s+$", "")
    return text
end

local function normalizeName(value)
    if type(Common.NormalizeName) == "function" then
        return Common.NormalizeName(value)
    end

    return type(value) == "string" and value or ""
end

local function ensureString(value, fallback)
    local text = trimText(value)
    if text == "" then
        return fallback or ""
    end

    return text
end

local function formatTurnLabel(turns)
    local numericTurns = math.max(1, math.floor(tonumber(turns) or 1))
    if numericTurns == 1 then
        return "1 turn"
    end

    return ("%d turns"):format(numericTurns)
end

local function formatValueRange(minimum, maximum)
    local minValue = math.max(0, tonumber(minimum) or 0)
    local maxValue = math.max(0, tonumber(maximum) or 0)
    if minValue > maxValue then
        minValue, maxValue = maxValue, minValue
    end

    if minValue == maxValue then
        return tostring(minValue)
    end

    return ("%d to %d"):format(minValue, maxValue)
end

local function buildDeterministicRandom(mode)
    return function(_, minimum, maximum)
        if minimum ~= nil and maximum ~= nil then
            if mode == "min" then
                return minimum
            end
            return maximum
        end

        if mode == "min" then
            return 0
        end
        return 1
    end
end

local function buildValueContext(casterUnit, variance, randomMode)
    return {
        casterUnit = casterUnit,
        attackerUnit = casterUnit,
        caster = casterUnit,
        variance = variance,
        random = buildDeterministicRandom(randomMode),
    }
end

local function resolveLocalPlayerName()
    if type(Common.GetPlayerName) == "function" then
        return tostring(Common.GetPlayerName() or "")
    end

    return ""
end

local function isLocalPlayerUnit(unit)
    if type(unit) ~= "table" or unit.isPlayer ~= true then
        return false
    end

    local localPlayerName = normalizeName(resolveLocalPlayerName())
    if localPlayerName == "" then
        return false
    end

    local unitPlayerName = normalizeName(unit.ownerID or unit.controllerID or unit.name)
    return unitPlayerName ~= "" and unitPlayerName == localPlayerName
end

local function buildPseudoCasterUnit()
    local cacheToken = table.concat({
        tostring(math.max(0, math.floor(tonumber(Addon.Internal and Addon.Internal.ConfigurationRevision) or 0))),
        tostring(math.max(1, math.floor(tonumber(DescriptionBuilder.ProfileTooltipContextRevision) or 1))),
    }, "\31")
    local cached = DescriptionBuilder.PseudoCasterUnitCache
    if type(cached) == "table" and cached.token == cacheToken and type(cached.unit) == "table" then
        return cached.unit
    end

    local localPlayerName = resolveLocalPlayerName()
    local stats = type(Profile.ListResolvedStats) == "function" and Profile.ListResolvedStats({
        includeAuraBonuses = true,
    }) or {}
    local resources = type(Profile.ListResolvedResources) == "function" and Profile.ListResolvedResources({
        includeAuraBonuses = true,
    }) or {}
    local pseudoStats = {}
    local pseudoResources = {}

    for index = 1, #stats do
        local row = stats[index]
        if type(row) == "table" and type(row.ref) == "string" and row.ref ~= "" then
            pseudoStats[#pseudoStats + 1] = {
                statRef = row.ref,
                value = tonumber(row.value) or 0,
                currentValue = tonumber(row.value) or 0,
            }
        end
    end

    for index = 1, #resources do
        local row = resources[index]
        if type(row) == "table" and type(row.ref) == "string" and row.ref ~= "" then
            local currentValue = tonumber(row.value)
            local maxValue = tonumber(row.value)
            pseudoResources[#pseudoResources + 1] = {
                resourceRef = row.ref,
                currentValue = currentValue or 0,
                maxValue = maxValue or currentValue or 0,
            }
        end
    end

    local mainHand = type(Profile.GetEquippedItem) == "function" and Profile.GetEquippedItem("mainhand") or nil
    local offHand = type(Profile.GetEquippedItem) == "function" and Profile.GetEquippedItem("offhand") or nil
    local ranged = type(Profile.GetEquippedItem) == "function" and Profile.GetEquippedItem("ranged") or nil

    local pseudoUnit = {
        isPlayer = true,
        name = localPlayerName ~= "" and localPlayerName or "Player",
        ownerID = localPlayerName ~= "" and localPlayerName or nil,
        controllerID = localPlayerName ~= "" and localPlayerName or nil,
        stats = pseudoStats,
        resources = pseudoResources,
        mainHandWeapon = mainHand and mainHand.itemRef or nil,
        offHandWeapon = offHand and offHand.itemRef or nil,
        rangedWeapon = ranged and ranged.itemRef or nil,
    }
    DescriptionBuilder.PseudoCasterUnitCache = {
        token = cacheToken,
        unit = pseudoUnit,
    }
    return pseudoUnit
end

local function resolveCasterUnit(detail)
    if type(detail) ~= "table" then
        return buildPseudoCasterUnit()
    end

    if type(detail.casterUnit) == "table" then
        return detail.casterUnit
    end

    if type(detail.spellRef) == "string" and type(Client.ResolveSpellActivationState) == "function" then
        local activationState = Client:ResolveSpellActivationState(detail.spellRef)
        if type(activationState) == "table" and type(activationState.casterUnit) == "table" then
            return activationState.casterUnit
        end
    end

    return buildPseudoCasterUnit()
end

local function normalizeEventId(value)
    local eventId = tostring(value or "")
    if eventId == "" then
        return ""
    end

    return eventId
end

local function normalizeUnitEventId(value)
    local numericValue = tonumber(value)
    if numericValue == nil then
        return nil
    end

    numericValue = math.floor(numericValue)
    if numericValue <= 0 then
        return nil
    end

    return numericValue
end

local function ensureEventTooltipRevisionBucket(eventId, createIfMissing)
    local normalizedEventId = normalizeEventId(eventId)
    if normalizedEventId == "" then
        return nil
    end

    local buckets = DescriptionBuilder.EventTooltipContextRevisions
    local bucket = type(buckets) == "table" and buckets[normalizedEventId] or nil
    if type(bucket) == "table" then
        bucket.global = math.max(1, math.floor(tonumber(bucket.global) or 1))
        bucket.byCaster = type(bucket.byCaster) == "table" and bucket.byCaster or {}
        buckets[normalizedEventId] = bucket
        return bucket
    end

    if createIfMissing ~= true then
        return nil
    end

    bucket = {
        global = 1,
        byCaster = {},
    }
    buckets[normalizedEventId] = bucket
    return bucket
end

local function resolveTooltipContextIdentity(detail, casterUnit)
    local eventId = normalizeEventId(
        type(detail) == "table" and (
            detail.eventId
            or type(detail.eventState) == "table" and detail.eventState.id
            or type(detail.activationState) == "table" and type(detail.activationState.eventState) == "table" and detail.activationState.eventState.id
        ) or nil
    )
    local unit = type(casterUnit) == "table" and casterUnit or type(detail) == "table" and detail.casterUnit or nil
    local casterEventId = normalizeUnitEventId(
        type(unit) == "table" and unit.eventID
            or type(detail) == "table" and detail.casterEventId
            or nil
    )

    if eventId ~= "" and casterEventId then
        return "event", eventId, casterEventId
    end

    if type(unit) == "table" then
        if isLocalPlayerUnit(unit) or (unit.isPlayer == true and casterEventId == nil) then
            return "profile", "", nil
        end

        return "unit", tostring(casterEventId or unit.ownerID or unit.controllerID or unit.name or "unit"), nil
    end

    return "profile", "", nil
end

local function getTooltipContextRevision(detail, casterUnit)
    local contextType, contextValue, casterEventId = resolveTooltipContextIdentity(detail, casterUnit)
    if contextType == "event" then
        local bucket = ensureEventTooltipRevisionBucket(contextValue, false)
        local globalRevision = math.max(1, math.floor(tonumber(bucket and bucket.global) or 1))
        local casterRevision = math.max(1, math.floor(tonumber(bucket and bucket.byCaster and bucket.byCaster[casterEventId]) or 1))
        return ("%d:%d"):format(globalRevision, casterRevision), contextType, contextValue, casterEventId
    end

    if contextType == "profile" then
        return tostring(math.max(1, math.floor(tonumber(DescriptionBuilder.ProfileTooltipContextRevision) or 1))), contextType, contextValue, casterEventId
    end

    return "1", contextType, contextValue, casterEventId
end

local function buildGeneratedDescriptionCacheKey(detail, casterUnit)
    local revision, contextType, contextValue, casterEventId = getTooltipContextRevision(detail, casterUnit)
    local configurationRevision = math.max(0, math.floor(tonumber(Addon.Internal and Addon.Internal.ConfigurationRevision) or 0))
    local datasetHash = type(Registry.GenerateActivatedDatasetsHash) == "function" and tostring(Registry:GenerateActivatedDatasetsHash() or "") or ""
    local rulesetHash = type(Registry.GenerateActiveRulesetHash) == "function" and tostring(Registry:GenerateActiveRulesetHash() or "") or ""

    return table.concat({
        tostring(contextType or "profile"),
        tostring(contextValue or ""),
        tostring(casterEventId or ""),
        tostring(revision or "1"),
        tostring(configurationRevision),
        datasetHash,
        rulesetHash,
        tostring(type(detail) == "table" and detail.spellRef or ""),
        tostring(type(detail) == "table" and detail.traitRef or ""),
        tostring(type(detail) == "table" and type(detail.item) == "table" and detail.item.id or ""),
        tostring(type(detail) == "table" and detail.detailName or ""),
    }, "\31")
end

local function applySummaryFallback(detail)
    local summaryText = trimText(type(detail) == "table" and detail.summaryText or "")
    if type(detail) == "table" then
        detail.descriptionText = summaryText
        detail.descriptionSource = "summary"
    end

    return summaryText, "summary"
end

local function applyLoadingFallback(detail)
    local loadingText = "Loading description..."
    if type(detail) == "table" then
        detail.descriptionText = loadingText
        detail.descriptionSource = "loading"
    end

    return loadingText, "loading"
end

local function ensurePendingDescriptionState(detail)
    if type(detail) ~= "table" then
        return nil, nil
    end

    detail.generatedDescriptionPendingByKey = detail.generatedDescriptionPendingByKey or {}
    detail.generatedDescriptionPendingOwnersByKey = detail.generatedDescriptionPendingOwnersByKey or {}
    return detail.generatedDescriptionPendingByKey, detail.generatedDescriptionPendingOwnersByKey
end

local function addPendingDescriptionOwner(detail, cacheKey, owner)
    if type(detail) ~= "table" or type(cacheKey) ~= "string" or cacheKey == "" or owner == nil then
        return
    end

    local _, ownersByKey = ensurePendingDescriptionState(detail)
    if type(ownersByKey) ~= "table" then
        return
    end

    local owners = ownersByKey[cacheKey]
    if type(owners) ~= "table" then
        owners = {}
        ownersByKey[cacheKey] = owners
    end

    for index = 1, #owners do
        if owners[index] == owner then
            return
        end
    end

    owners[#owners + 1] = owner
end

local function takePendingDescriptionOwners(detail, cacheKey)
    if type(detail) ~= "table" or type(cacheKey) ~= "string" or cacheKey == "" then
        return nil
    end

    local pendingByKey, ownersByKey = ensurePendingDescriptionState(detail)
    local owners = type(ownersByKey) == "table" and ownersByKey[cacheKey] or nil
    if type(pendingByKey) == "table" then
        pendingByKey[cacheKey] = nil
    end
    if type(ownersByKey) == "table" then
        ownersByKey[cacheKey] = nil
    end

    return owners
end

local function clearPendingDescriptionKey(detail, cacheKey)
    if type(detail) ~= "table" or type(cacheKey) ~= "string" or cacheKey == "" then
        return false
    end

    local pendingByKey, ownersByKey = ensurePendingDescriptionState(detail)
    if type(pendingByKey) == "table" then
        pendingByKey[cacheKey] = nil
    end
    if type(ownersByKey) == "table" then
        ownersByKey[cacheKey] = nil
    end
    return true
end

local function collectPendingDescriptionOwners(detail, requestedCacheKey, currentCacheKey)
    local owners = {}
    local sources = {
        requestedCacheKey,
    }
    if type(currentCacheKey) == "string" and currentCacheKey ~= "" and currentCacheKey ~= requestedCacheKey then
        sources[#sources + 1] = currentCacheKey
    end

    for index = 1, #sources do
        local pendingOwners = takePendingDescriptionOwners(detail, sources[index])
        for ownerIndex = 1, #(pendingOwners or {}) do
            owners[#owners + 1] = pendingOwners[ownerIndex]
        end
    end

    return owners
end

local function refreshTooltipOwners(owners)
    if type(owners) ~= "table" or type(UI.Tooltip) ~= "table" or type(UI.Tooltip.RefreshForElement) ~= "function" then
        return
    end

    for index = 1, #owners do
        UI.Tooltip:RefreshForElement(owners[index])
    end
end

local function storeGeneratedDescription(detail, generatedDescriptionText, cacheKey)
    if type(detail) ~= "table" then
        return
    end

    local normalizedGeneratedDescriptionText = trimText(generatedDescriptionText or "")
    detail.generatedDescriptionText = normalizedGeneratedDescriptionText
    detail.generatedDescriptionCacheKey = cacheKey

    if normalizedGeneratedDescriptionText ~= "" then
        detail.descriptionText = normalizedGeneratedDescriptionText
        detail.descriptionSource = "generated"
        return
    end

    applySummaryFallback(detail)
end

local function storeGeneratedTooltipPayload(detail, generatedDescriptionText, generatedAuraSections, cacheKey)
    if type(detail) ~= "table" then
        return
    end

    storeGeneratedDescription(detail, generatedDescriptionText, cacheKey)
    detail.generatedAuraSections = type(generatedAuraSections) == "table" and generatedAuraSections or {}
    detail.generatedAuraSectionsCacheKey = cacheKey
end

local function resolveDatasetId(detail)
    if type(detail) ~= "table" then
        return nil
    end

    if type(detail.datasetId) == "string" and detail.datasetId ~= "" then
        return detail.datasetId
    end

    local dataset = detail.dataset
    if type(dataset) == "table" and type(dataset.id) == "string" and dataset.id ~= "" then
        return dataset.id
    end

    local spellRef = type(detail.spellRef) == "string" and detail.spellRef or ""
    local datasetId = spellRef:match("^([^:]+):.+$")
    if datasetId and datasetId ~= "" then
        return datasetId
    end

    return nil
end

local function resolveDamageSchoolName(detail, schoolRef)
    if type(schoolRef) ~= "string" or schoolRef == "" then
        return nil
    end

    local datasetId, schoolId = nil, nil
    if type(Dependencies.ParseSourceStatRef) == "function" then
        datasetId, schoolId = Dependencies.ParseSourceStatRef(schoolRef)
    end

    if not datasetId or not schoolId then
        return schoolRef
    end

    local dataset = type(Database.GetDatasetByID) == "function" and Database.GetDatasetByID(datasetId) or nil
    for index = 1, #((dataset and dataset.damageSchools) or {}) do
        local damageSchool = dataset.damageSchools[index]
        if tostring(damageSchool and damageSchool.id or "") == tostring(schoolId) then
            local name = trimText(damageSchool and damageSchool.name or "")
            if name ~= "" then
                return name
            end
            break
        end
    end

    return schoolId
end

local function resolveDamageSchoolLabel(detail, effect)
    local names = {}

    for index = 1, #(effect and effect.damageSchoolRefs or {}) do
        local name = resolveDamageSchoolName(detail, effect.damageSchoolRefs[index])
        if name and name ~= "" then
            names[#names + 1] = name
        end
    end

    if #names == 0 then
        return "True"
    end

    return table.concat(names, "/")
end

local function resolveResourceName(resourceRef)
    local resolvedRow = type(Profile.GetResolvedResourceRow) == "function" and Profile.GetResolvedResourceRow(resourceRef) or nil
    local resolvedName = resolvedRow and resolvedRow.name or nil
    if type(resolvedName) == "string" and resolvedName ~= "" then
        return resolvedName
    end

    if type(ResourceSync.ResolveResourceName) == "function" then
        local syncName = tostring(ResourceSync.ResolveResourceName(resourceRef) or "")
        if syncName ~= "" then
            return syncName
        end
    end

    local resourceId = nil
    if type(Dependencies.ParseSourceStatRef) == "function" then
        _, resourceId = Dependencies.ParseSourceStatRef(resourceRef)
    end

    return ensureString(resourceId or resourceRef, "Resource")
end

local function resolveAuraMetadata(detail, auraRef)
    local defaultName = "an aura"
    if type(auraRef) ~= "string" or auraRef == "" then
        return {
            name = defaultName,
            duration = nil,
        }
    end

    local auraManager = Spellcasting.AuraManager or nil
    if type(auraManager) == "table" and type(auraManager.ResolveAuraDefinition) == "function" then
        local _, auraDefinition = auraManager:ResolveAuraDefinition(auraRef, {
            datasetId = resolveDatasetId(detail),
            spellDatasetId = resolveDatasetId(detail),
        })
        if type(auraDefinition) == "table" then
            local auraName = trimText(auraDefinition.name)
            return {
                name = auraName ~= "" and auraName or defaultName,
                duration = tonumber(auraDefinition.duration) or nil,
            }
        end
    end

    local _, auraId = nil, nil
    if type(Dependencies.ParseSourceStatRef) == "function" then
        _, auraId = Dependencies.ParseSourceStatRef(auraRef)
    end
    return {
        name = ensureString(auraId or auraRef, defaultName),
        duration = nil,
    }
end

local function resolveTargetPhrase(target)
    local targetType = tostring(target and target.type or "single")
    if targetType == "caster" then
        return "yourself"
    end
    if targetType == "pet" then
        return "your current pet"
    end
    if targetType == "last_attackers" then
        return "the last attacker of the target"
    end

    local disposition = tostring(target and target.targetDisposition or "enemy")
    local singular = "a target"
    local plural = "targets"
    if disposition == "ally" then
        singular = "an ally"
        plural = "allies"
    elseif disposition == "enemy" then
        singular = "an enemy"
        plural = "enemies"
    end

    local minTargets = math.max(0, tonumber(target and target.minTargets) or 0)
    local maxTargets = math.max(minTargets, tonumber(target and target.maxTargets) or 0)
    if maxTargets <= 1 and minTargets <= 1 then
        return singular
    end

    if minTargets > 1 and minTargets == maxTargets then
        return ("%d %s"):format(maxTargets, plural)
    end

    return ("up to %d %s"):format(math.max(1, maxTargets), plural)
end

local function buildAuraTargetContext(target)
    local targetType = tostring(target and target.type or "single")
    if targetType == "caster" then
        return {
            subject = "you",
            object = "you",
            possessive = "your",
            reflexive = "yourself",
        }
    end
    if targetType == "pet" then
        return {
            subject = "your current pet",
            object = "your current pet",
            possessive = "your current pet's",
            reflexive = "itself",
        }
    end
    if targetType == "last_attackers" then
        return {
            subject = "the last attacker of the target",
            object = "the last attacker of the target",
            possessive = "the last attacker of the target's",
            reflexive = "itself",
        }
    end

    local disposition = tostring(target and target.targetDisposition or "enemy")
    if disposition == "ally" then
        return {
            subject = "the affected ally",
            object = "the affected ally",
            possessive = "the affected ally's",
            reflexive = "itself",
        }
    end
    if disposition == "enemy" then
        return {
            subject = "the affected enemy",
            object = "the affected enemy",
            possessive = "the affected enemy's",
            reflexive = "itself",
        }
    end

    return {
        subject = "the affected target",
        object = "the affected target",
        possessive = "the affected target's",
        reflexive = "itself",
    }
end

local function resolveTargetPossessivePhrase(targetPhrase)
    if targetPhrase == "yourself" then
        return "your"
    end
    if targetPhrase == "an ally" then
        return "an ally's"
    end
    if targetPhrase == "an enemy" then
        return "an enemy's"
    end
    if targetPhrase == "a target" then
        return "a target's"
    end
    if targetPhrase == "your current pet" then
        return "your current pet's"
    end
    if targetPhrase == "the last attacker of the target" then
        return "the last attacker of the target's"
    end

    return nil
end

local function buildPhasePrefix(phase)
    local phaseKey = tostring(phase or "on_cast_end")
    if phaseKey == "on_cast_start" then
        return "On cast start, "
    end
    if phaseKey == "on_channel_tick" then
        return "On each channel tick, "
    end
    return "On cast end, "
end

local function buildAuraClause(detail, effect, standalone)
    local auraRef = type(effect) == "table" and effect.auraRef or nil
    if type(auraRef) ~= "string" or auraRef == "" then
        return standalone == true and "Apply an aura" or nil
    end

    local metadata = resolveAuraMetadata(detail, auraRef)
    local clause = standalone == true and ("Apply %s"):format(metadata.name) or ("and apply %s"):format(metadata.name)
    local stacks = math.max(1, math.floor(tonumber(effect and (effect.stacks or effect.auraStacks) or 1)))
    local duration = tonumber(effect and effect.duration) or metadata.duration

    if stacks > 1 then
        clause = ("%s with %d stacks"):format(clause, stacks)
    end
    if duration and duration > 0 then
        clause = ("%s for %s"):format(clause, formatTurnLabel(duration))
    end

    return clause
end

local function buildDamageSentence(detail, casterUnit, component)
    local effect = component and component.effect or nil
    if type(effect) ~= "table" or type(Combat.ResolveDamageAmount) ~= "function" then
        return nil
    end

    local minimum = Combat:ResolveDamageAmount(buildValueContext(casterUnit, MIN_VARIANCE, "min"), effect)
    local maximum = Combat:ResolveDamageAmount(buildValueContext(casterUnit, MAX_VARIANCE, "max"), effect)
    local schoolLabel = resolveDamageSchoolLabel(detail, effect)
    local targetPhrase = resolveTargetPhrase(component.target)
    local sentence = ("Deal %s %s damage to %s"):format(formatValueRange(minimum, maximum), schoolLabel, targetPhrase)
    local auraClause = effect.applyAura == true and buildAuraClause(detail, effect, false) or nil
    if auraClause then
        sentence = ("%s %s"):format(sentence, auraClause)
    end

    return sentence .. "."
end

local function buildHealSentence(detail, casterUnit, component)
    local effect = component and component.effect or nil
    if type(effect) ~= "table" or type(Combat.ResolveHealingAmount) ~= "function" then
        return nil
    end

    local minimum = Combat:ResolveHealingAmount(buildValueContext(casterUnit, MIN_VARIANCE, "min"), effect)
    local maximum = Combat:ResolveHealingAmount(buildValueContext(casterUnit, MAX_VARIANCE, "max"), effect)
    local targetPhrase = resolveTargetPhrase(component.target)
    local sentence = ("Heal %s for %s health"):format(targetPhrase, formatValueRange(minimum, maximum))
    local auraClause = effect.applyAura == true and buildAuraClause(detail, effect, false) or nil
    if auraClause then
        sentence = ("%s %s"):format(sentence, auraClause)
    end

    return sentence .. "."
end

local function buildResourceSentence(detail, component)
    local effect = component and component.effect or nil
    if type(effect) ~= "table" then
        return nil
    end

    local amount = tonumber(effect.amount) or 0
    if amount == 0 then
        return nil
    end

    local resourceName = resolveResourceName(effect.resourceRef)
    local targetPhrase = resolveTargetPhrase(component.target)
    if amount > 0 then
        return ("Restore %d %s to %s."):format(amount, resourceName, targetPhrase)
    end

    local possessive = resolveTargetPossessivePhrase(targetPhrase)
    if possessive then
        return ("Reduce %s %s by %d."):format(possessive, resourceName, math.abs(amount))
    end

    return ("Reduce %s for %s by %d."):format(resourceName, targetPhrase, math.abs(amount))
end

local function buildApplyAuraSentence(detail, component)
    local effect = component and component.effect or nil
    if type(effect) ~= "table" then
        return nil
    end

    local metadata = resolveAuraMetadata(detail, effect.auraRef)
    local targetPhrase = resolveTargetPhrase(component.target)
    local sentence = ("Apply %s to %s"):format(metadata.name, targetPhrase)
    local stacks = math.max(1, math.floor(tonumber(effect.stacks) or 1))
    local duration = tonumber(effect.duration) or metadata.duration
    if stacks > 1 then
        sentence = ("%s with %d stacks"):format(sentence, stacks)
    end
    if duration and duration > 0 then
        sentence = ("%s for %s"):format(sentence, formatTurnLabel(duration))
    end
    return sentence .. "."
end

local function buildSummonPetSentence()
    return "Summon the selected unit under your control."
end

local function buildInterruptSentence(component)
    local targetPhrase = resolveTargetPhrase(component and component.target or nil)
    local possessive = resolveTargetPossessivePhrase(targetPhrase)
    if possessive then
        return ("Interrupt %s spellcasting."):format(possessive)
    end

    return ("Interrupt the spellcasting of %s."):format(targetPhrase)
end

local function buildRevertSentence(component)
    local targetPhrase = resolveTargetPhrase(component and component.target or nil)
    return ("Reverse the effects of the last spell that affected %s."):format(targetPhrase)
end

local function buildSentence(detail, casterUnit, component)
    local effectType = tostring(component and component.effect and component.effect.type or "")
    if effectType == "damage" then
        return buildDamageSentence(detail, casterUnit, component)
    end
    if effectType == "heal" then
        return buildHealSentence(detail, casterUnit, component)
    end
    if effectType == "resource" then
        return buildResourceSentence(detail, component)
    end
    if effectType == "apply_aura" then
        return buildApplyAuraSentence(detail, component)
    end
    if effectType == "summon_pet" then
        return buildSummonPetSentence()
    end
    if effectType == "interrupt" then
        return buildInterruptSentence(component)
    end
    if effectType == "revert" then
        return buildRevertSentence(component)
    end

    return nil
end

local function hasAutoAttackDamageComponent(detail)
    local spell = type(detail) == "table" and detail.spell or nil
    if type(spell) ~= "table" then
        return false
    end

    for index = 1, #(spell.components or {}) do
        local rawComponent = spell.components[index]
        local component = type(Combat.NormalizeComponent) == "function" and Combat:NormalizeComponent(rawComponent) or rawComponent
        local effect = type(component) == "table" and component.effect or nil
        if type(effect) == "table"
            and tostring(effect.type or "") == "damage"
            and tostring(effect.hitType or "ability") == "auto"
        then
            return true
        end
    end

    return false
end

local function prependBasicAttackPrefix(detail, descriptionText)
    local trimmedDescription = trimText(descriptionText or "")
    if not hasAutoAttackDamageComponent(detail) then
        return trimmedDescription
    end

    if trimmedDescription == "" then
        return "Basic attack."
    end

    if trimmedDescription:sub(1, 13) == "Basic attack." then
        return trimmedDescription
    end

    return "Basic attack. " .. trimmedDescription
end

local function resolveThreatDescription(detail)
    local spell = type(detail) == "table" and detail.spell or nil
    if type(spell) ~= "table" then
        return ""
    end

    local hasHighThreat = false
    local hasModerateThreat = false
    local hasLowThreat = false

    for index = 1, #(spell.components or {}) do
        local rawComponent = spell.components[index]
        local component = type(Combat.NormalizeComponent) == "function" and Combat:NormalizeComponent(rawComponent) or rawComponent
        local effect = type(component) == "table" and component.effect or nil
        if type(effect) == "table" and tostring(effect.type or "") == "damage" then
            local threatCoefficient = tonumber(effect.threatCoefficient) or 1
            if threatCoefficient > 1.8 then
                hasHighThreat = true
            elseif threatCoefficient > 1.2 then
                hasModerateThreat = true
            elseif threatCoefficient < 0.5 then
                hasLowThreat = true
            end
        end
    end

    if hasHighThreat then
        return "Generates a high amount of threat."
    end
    if hasModerateThreat then
        return "Generates a moderate amount of threat."
    end
    if hasLowThreat then
        return "Generates a low amount of threat."
    end

    return ""
end

local function appendThreatDescription(detail, descriptionText)
    local trimmedDescription = trimText(descriptionText or "")
    local threatDescription = resolveThreatDescription(detail)
    if threatDescription == "" then
        return trimmedDescription
    end
    if trimmedDescription == "" then
        return threatDescription
    end
    if trimmedDescription:sub(-#threatDescription) == threatDescription then
        return trimmedDescription
    end

    return trimText(("%s %s"):format(trimmedDescription, threatDescription))
end

function DescriptionBuilder:BuildGeneratedDescription(detail, casterUnit)
    local spell = type(detail) == "table" and detail.spell or nil
    if type(spell) ~= "table" then
        return ""
    end

    casterUnit = casterUnit or resolveCasterUnit(detail)
    local normalizedComponents = {}
    local hasNonDefaultPhase = false

    for index = 1, #(spell.components or {}) do
        local rawComponent = spell.components[index]
        local component = type(Combat.NormalizeComponent) == "function" and Combat:NormalizeComponent(rawComponent) or rawComponent
        if type(component) == "table" and type(component.effect) == "table" then
            normalizedComponents[#normalizedComponents + 1] = component
            if tostring(component.castPhase or "on_cast_end") ~= "on_cast_end" then
                hasNonDefaultPhase = true
            end
        end
    end

    local sentences = {}
    for index = 1, #normalizedComponents do
        local component = normalizedComponents[index]
        local sentence = buildSentence(detail, casterUnit, component)
        if sentence and sentence ~= "" then
            if hasNonDefaultPhase then
                sentence = buildPhasePrefix(component.castPhase) .. sentence
            end
            sentences[#sentences + 1] = sentence
        end
    end

    return appendThreatDescription(detail, prependBasicAttackPrefix(detail, table.concat(sentences, " ")))
end

function DescriptionBuilder:BuildGeneratedAuraSections(detail, casterUnit)
    local spell = type(detail) == "table" and detail.spell or nil
    if type(spell) ~= "table" or type(AuraDescriptionBuilder) ~= "table" or type(AuraDescriptionBuilder.BuildTooltipSection) ~= "function" then
        return {}
    end

    casterUnit = casterUnit or resolveCasterUnit(detail)
    local sections = {}
    local seen = {}
    for index = 1, #(spell.components or {}) do
        local rawComponent = spell.components[index]
        local component = type(Combat.NormalizeComponent) == "function" and Combat:NormalizeComponent(rawComponent) or rawComponent
        local effect = type(component) == "table" and component.effect or nil
        if type(effect) == "table" then
            local auraRef = nil
            local stacks = 1
            local duration = nil
            local powerLevel = 0
            if tostring(effect.type or "") == "apply_aura" then
                auraRef = effect.auraRef
                stacks = math.max(1, math.floor(tonumber(effect.stacks) or 1))
                duration = tonumber(effect.duration) or nil
                powerLevel = tonumber(effect.basePower) or 0
            elseif effect.applyAura == true then
                auraRef = effect.auraRef
                stacks = math.max(1, math.floor(tonumber(effect.auraStacks) or 1))
                duration = tonumber(effect.duration) or nil
                powerLevel = tonumber(effect.basePower) or 0
            end

            if type(auraRef) == "string" and auraRef ~= "" then
                local targetContext = buildAuraTargetContext(component.target)
                local sectionKey = table.concat({
                    auraRef,
                    tostring(stacks),
                    tostring(duration or ""),
                    tostring(powerLevel),
                    tostring(targetContext.subject or ""),
                }, "\31")
                if not seen[sectionKey] then
                    seen[sectionKey] = true
                    local section = AuraDescriptionBuilder:BuildTooltipSection(auraRef, {
                        dataset = type(detail) == "table" and detail.dataset or nil,
                        datasetId = resolveDatasetId(detail),
                        spellDatasetId = resolveDatasetId(detail),
                        casterUnit = casterUnit,
                        powerLevel = powerLevel,
                        stacks = stacks,
                        duration = duration,
                        targetContext = targetContext,
                    })
                    if type(section) == "table" and trimText(section.descriptionText or "") ~= "" then
                        sections[#sections + 1] = section
                    end
                end
            end
        end
    end

    return sections
end

function DescriptionBuilder:BuildGeneratedTooltipPayload(detail, casterUnit)
    casterUnit = casterUnit or resolveCasterUnit(detail)
    return self:BuildGeneratedDescription(detail, casterUnit), self:BuildGeneratedAuraSections(detail, casterUnit)
end

local function runQueuedDescriptionBuildResolve(state)
    if type(state) ~= "table" or type(state.detail) ~= "table" then
        return false
    end

    state.casterUnit = resolveCasterUnit(state.detail)
    return true
end

local function runQueuedDescriptionBuildDescription(state)
    if type(state) ~= "table" or type(state.builder) ~= "table" then
        return false
    end

    state.generatedDescriptionText = state.builder:BuildGeneratedDescription(state.detail, state.casterUnit)
    return true
end

local function runQueuedDescriptionBuildAuras(state)
    if type(state) ~= "table" or type(state.builder) ~= "table" then
        return false
    end

    state.generatedAuraSections = state.builder:BuildGeneratedAuraSections(state.detail, state.casterUnit)
    return true
end

local function finalizeQueuedDescriptionBuild(state)
    if type(state) ~= "table" or type(state.builder) ~= "table" or type(state.detail) ~= "table" then
        return false
    end

    local casterUnit = resolveCasterUnit(state.detail)
    local currentCacheKey = buildGeneratedDescriptionCacheKey(state.detail, casterUnit)
    local generatedDescriptionText = state.generatedDescriptionText
    local generatedAuraSections = state.generatedAuraSections
    if currentCacheKey ~= state.requestedCacheKey then
        generatedDescriptionText, generatedAuraSections = state.builder:BuildGeneratedTooltipPayload(state.detail, casterUnit)
    end

    storeGeneratedTooltipPayload(state.detail, generatedDescriptionText, generatedAuraSections, currentCacheKey)
    refreshTooltipOwners(collectPendingDescriptionOwners(state.detail, state.requestedCacheKey, currentCacheKey))
    return true
end

local function enqueueQueuedDescriptionBuildPhase(nextPhase, state)
    if enqueueDescriptionWork(nextPhase, state) then
        return true
    end

    nextPhase(state)
    return false
end

local runQueuedDescriptionBuildPhaseDescription
local runQueuedDescriptionBuildPhaseAuras
local runQueuedDescriptionBuildPhaseFinalize

local function runQueuedDescriptionBuildPhaseResolve(state)
    if not runQueuedDescriptionBuildResolve(state) then
        return
    end

    enqueueQueuedDescriptionBuildPhase(runQueuedDescriptionBuildPhaseDescription, state)
end

runQueuedDescriptionBuildPhaseDescription = function(state)
    if not runQueuedDescriptionBuildDescription(state) then
        return
    end

    enqueueQueuedDescriptionBuildPhase(runQueuedDescriptionBuildPhaseAuras, state)
end

runQueuedDescriptionBuildPhaseAuras = function(state)
    if not runQueuedDescriptionBuildAuras(state) then
        return
    end

    enqueueQueuedDescriptionBuildPhase(runQueuedDescriptionBuildPhaseFinalize, state)
end

runQueuedDescriptionBuildPhaseFinalize = function(state)
    finalizeQueuedDescriptionBuild(state)
end

function DescriptionBuilder:QueueDescriptionBuild(detail, cacheKey, owner)
    if type(detail) ~= "table" or type(cacheKey) ~= "string" or cacheKey == "" then
        return false
    end

    local pendingByKey = ensurePendingDescriptionState(detail)
    if type(pendingByKey) ~= "table" then
        return false
    end

    addPendingDescriptionOwner(detail, cacheKey, owner)
    if pendingByKey[cacheKey] then
        return true
    end

    pendingByKey[cacheKey] = true
    local state = {
        builder = self,
        detail = detail,
        requestedCacheKey = cacheKey,
        casterUnit = nil,
        generatedDescriptionText = nil,
        generatedAuraSections = nil,
    }

    local enqueued = enqueueDescriptionWork(runQueuedDescriptionBuildPhaseResolve, state)
    if enqueued then
        return true
    end

    local casterUnit = resolveCasterUnit(detail)
    local currentCacheKey = buildGeneratedDescriptionCacheKey(detail, casterUnit)
    local generatedDescriptionText, generatedAuraSections = self:BuildGeneratedTooltipPayload(detail, casterUnit)
    storeGeneratedTooltipPayload(detail, generatedDescriptionText, generatedAuraSections, currentCacheKey)
    refreshTooltipOwners(collectPendingDescriptionOwners(detail, cacheKey, currentCacheKey))
    return false
end

function DescriptionBuilder:BuildTooltipData(detail, options)
    local authoredDescriptionText = trimText(
        type(detail) == "table" and detail.authoredDescriptionText
            or type(detail) == "table" and type(detail.spell) == "table" and detail.spell.description
            or ""
    )
    local cacheKey = buildGeneratedDescriptionCacheKey(detail, nil)
    local hasCachedGeneratedDescription = type(detail) == "table"
        and tostring(detail.generatedDescriptionCacheKey or "") == cacheKey
        and detail.generatedDescriptionText ~= nil
    local hasCachedAuraSections = type(detail) == "table"
        and tostring(detail.generatedAuraSectionsCacheKey or "") == cacheKey
        and type(detail.generatedAuraSections) == "table"

    local allowDeferredBuild = not (type(options) == "table" and options.deferGeneration == false)
    local tooltipOwner = type(options) == "table" and options.tooltipOwner or nil
    if (not hasCachedGeneratedDescription or not hasCachedAuraSections)
        and allowDeferredBuild
        and self:QueueDescriptionBuild(detail, cacheKey, tooltipOwner)
    then
        local fallbackDescriptionText = authoredDescriptionText
        local fallbackSource = "authored"
        if fallbackDescriptionText ~= "" then
            detail.descriptionText = fallbackDescriptionText
            detail.descriptionSource = fallbackSource
        elseif hasCachedGeneratedDescription and trimText(detail.generatedDescriptionText or "") ~= "" then
            fallbackDescriptionText = trimText(detail.generatedDescriptionText or "")
            fallbackSource = "generated"
            detail.descriptionText = fallbackDescriptionText
            detail.descriptionSource = fallbackSource
        else
            fallbackDescriptionText, fallbackSource = applyLoadingFallback(detail)
        end
        fallbackDescriptionText = prependBasicAttackPrefix(detail, fallbackDescriptionText)
        fallbackDescriptionText = appendThreatDescription(detail, fallbackDescriptionText)
        return {
            descriptionText = fallbackDescriptionText,
            descriptionSource = fallbackSource,
            auraSections = {},
        }
    end

    if not hasCachedGeneratedDescription or not hasCachedAuraSections then
        local casterUnit = resolveCasterUnit(detail)
        local generatedDescriptionText, generatedAuraSections = self:BuildGeneratedTooltipPayload(detail, casterUnit)
        storeGeneratedTooltipPayload(detail, generatedDescriptionText, generatedAuraSections, cacheKey)
        clearPendingDescriptionKey(detail, cacheKey)
        hasCachedGeneratedDescription = true
        hasCachedAuraSections = true
    end

    local descriptionText = authoredDescriptionText
    local descriptionSource = "authored"
    if descriptionText == "" then
        local generatedDescriptionText = hasCachedGeneratedDescription and trimText(detail.generatedDescriptionText or "") or ""
        if generatedDescriptionText ~= "" then
            descriptionText = generatedDescriptionText
            descriptionSource = "generated"
            detail.descriptionText = descriptionText
            detail.descriptionSource = descriptionSource
        else
            descriptionText, descriptionSource = applySummaryFallback(detail)
        end
    else
        detail.descriptionText = descriptionText
        detail.descriptionSource = descriptionSource
    end

    descriptionText = prependBasicAttackPrefix(detail, descriptionText)
    descriptionText = appendThreatDescription(detail, descriptionText)

    return {
        descriptionText = descriptionText,
        descriptionSource = descriptionSource,
        auraSections = hasCachedAuraSections and detail.generatedAuraSections or {},
    }
end

function DescriptionBuilder:BuildDescription(detail, options)
    local tooltipData = self:BuildTooltipData(detail, options)
    return trimText(type(tooltipData) == "table" and tooltipData.descriptionText or ""), type(tooltipData) == "table" and tooltipData.descriptionSource or "summary"
end

function DescriptionBuilder.ResolveCasterUnit(detail)
    return resolveCasterUnit(detail)
end

function DescriptionBuilder.BuildPseudoCasterUnit()
    return buildPseudoCasterUnit()
end

function DescriptionBuilder.ResolveGeneratedTooltipCacheKey(detail, casterUnit)
    return buildGeneratedDescriptionCacheKey(detail, casterUnit)
end

function DescriptionBuilder.BumpProfileTooltipContextRevision()
    DescriptionBuilder.ProfileTooltipContextRevision = math.max(1, math.floor(tonumber(DescriptionBuilder.ProfileTooltipContextRevision) or 1) + 1)
    DescriptionBuilder.PseudoCasterUnitCache = nil
    return DescriptionBuilder.ProfileTooltipContextRevision
end

function DescriptionBuilder.BumpEventTooltipContextRevision(eventId, casterEventId)
    local bucket = ensureEventTooltipRevisionBucket(eventId, true)
    if type(bucket) ~= "table" then
        return false
    end

    bucket.global = math.max(1, math.floor(tonumber(bucket.global) or 1) + 1)
    local numericCasterEventId = normalizeUnitEventId(casterEventId)
    if numericCasterEventId then
        bucket.byCaster[numericCasterEventId] = math.max(1, math.floor(tonumber(bucket.byCaster[numericCasterEventId]) or 1) + 1)
    end
    return true
end

function DescriptionBuilder.BumpEventTooltipContextRevisionForAllUnits(eventState)
    local eventId = normalizeEventId(type(eventState) == "table" and eventState.id or nil)
    if eventId == "" then
        return false
    end

    local bucket = ensureEventTooltipRevisionBucket(eventId, true)
    if type(bucket) ~= "table" then
        return false
    end

    bucket.global = math.max(1, math.floor(tonumber(bucket.global) or 1) + 1)
    return true
end

function DescriptionBuilder:PrewarmTooltipData(detail)
    if type(detail) ~= "table" then
        return false
    end

    local cacheKey = buildGeneratedDescriptionCacheKey(detail, nil)
    local hasCachedGeneratedDescription = tostring(detail.generatedDescriptionCacheKey or "") == cacheKey
        and detail.generatedDescriptionText ~= nil
    local hasCachedAuraSections = tostring(detail.generatedAuraSectionsCacheKey or "") == cacheKey
        and type(detail.generatedAuraSections) == "table"
    if hasCachedGeneratedDescription and hasCachedAuraSections then
        return false
    end

    return self:QueueDescriptionBuild(detail, cacheKey, nil)
end

return DescriptionBuilder
