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
local TooltipTemplate = Spellcasting.TooltipTemplate or {}

local DescriptionBuilder = Spellcasting.DescriptionBuilder or {}
Spellcasting.DescriptionBuilder = DescriptionBuilder
DescriptionBuilder.ProfileTooltipContextRevision = math.max(1, math.floor(tonumber(DescriptionBuilder.ProfileTooltipContextRevision) or 1))
DescriptionBuilder.EventTooltipContextRevisions = DescriptionBuilder.EventTooltipContextRevisions or {}
DescriptionBuilder.PseudoCasterUnitCache = DescriptionBuilder.PseudoCasterUnitCache or nil

local prependBasicAttackPrefix
local appendThreatDescription

local MIN_VARIANCE = 0.9
local MAX_VARIANCE = 1.1
local RAID_MARKER_TOOLTIP_NOTE = "|cff999999Targets must share the same raid marker.|r"

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

local function getCachedResolvedTemplateTooltipPayload(detail, cacheKey)
    if type(detail) ~= "table" or type(cacheKey) ~= "string" or cacheKey == "" then
        return nil
    end

    if tostring(detail.resolvedTooltipTemplateCacheKey or "") ~= cacheKey then
        return nil
    end

    return type(detail.resolvedTooltipTemplateData) == "table" and detail.resolvedTooltipTemplateData or nil
end

local function storeResolvedTemplateTooltipPayload(detail, tooltipData, cacheKey)
    if type(detail) ~= "table" or type(tooltipData) ~= "table" or type(cacheKey) ~= "string" or cacheKey == "" then
        return nil
    end

    local cached = {
        descriptionText = trimText(tooltipData.descriptionText or ""),
        descriptionSource = ensureString(tooltipData.descriptionSource, "template"),
        auraSections = type(tooltipData.auraSections) == "table" and tooltipData.auraSections or {},
    }
    local errorText = trimText(tooltipData.errorText or "")
    if errorText ~= "" then
        cached.errorText = errorText
    end

    detail.resolvedTooltipTemplateData = cached
    detail.resolvedTooltipTemplateCacheKey = cacheKey
    detail.descriptionText = cached.descriptionText
    detail.descriptionSource = cached.descriptionSource
    return cached
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

local function resolveCurrentSpellDefinition(detail)
    if type(detail) ~= "table" then
        return nil, nil
    end

    local spellRef = type(detail.spellRef) == "string" and detail.spellRef or ""
    if spellRef ~= "" and type(Registry.ResolveSpellReference) == "function" then
        local dataset, spell = Registry:ResolveSpellReference(spellRef)
        if type(dataset) == "table" then
            detail.dataset = dataset
        end
        if type(spell) == "table" then
            detail.spell = spell
            return spell, dataset
        end
    end

    return type(detail.spell) == "table" and detail.spell or nil, type(detail.dataset) == "table" and detail.dataset or nil
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
            unresolved = false,
        }
    end

    local detailDataset = type(detail) == "table" and detail.dataset or nil
    local detailDatasetId = resolveDatasetId(detail)
    local localAuraId = auraRef
    if type(Dependencies.ParseSourceStatRef) == "function" then
        local parsedDatasetId, parsedAuraId = Dependencies.ParseSourceStatRef(auraRef)
        if type(parsedDatasetId) == "string" and parsedDatasetId ~= "" then
            detailDatasetId = parsedDatasetId
        end
        if type(parsedAuraId) == "string" and parsedAuraId ~= "" then
            localAuraId = parsedAuraId
        end
    end

    if type(detailDataset) == "table" and tostring(detailDataset.id or "") == tostring(detailDatasetId or "") then
        for index = 1, #((detailDataset and detailDataset.auras) or {}) do
            local auraDefinition = detailDataset.auras[index]
            if type(auraDefinition) == "table" and tostring(auraDefinition.id or "") == tostring(localAuraId or "") then
                local auraName = trimText(auraDefinition.name)
                return {
                    name = auraName ~= "" and auraName or defaultName,
                    duration = tonumber(auraDefinition.duration) or nil,
                    unresolved = false,
                }
            end
        end
    end

    local auraManager = Spellcasting.AuraManager or nil
    if type(auraManager) == "table" and type(auraManager.ResolveAuraDefinition) == "function" then
        local _, auraDefinition = auraManager:ResolveAuraDefinition(auraRef, {
            dataset = type(detail) == "table" and detail.dataset or nil,
            datasetId = resolveDatasetId(detail),
            spellDatasetId = resolveDatasetId(detail),
        })
        if type(auraDefinition) == "table" then
            local auraName = trimText(auraDefinition.name)
            return {
                name = auraName ~= "" and auraName or defaultName,
                duration = tonumber(auraDefinition.duration) or nil,
                unresolved = false,
            }
        end
    end

    if type(detail) == "table"
        and type(detail.spell) == "table"
        and detail.spell.tooltipTemplate == true
    then
        return {
            name = nil,
            duration = nil,
            unresolved = true,
            auraRef = auraRef,
        }
    end

    local _, auraId = nil, nil
    if type(Dependencies.ParseSourceStatRef) == "function" then
        _, auraId = Dependencies.ParseSourceStatRef(auraRef)
    end
    return {
        name = ensureString(auraId or auraRef, defaultName),
        duration = nil,
        unresolved = false,
    }
end

local function buildTemplateResolutionError(detail, auraRef)
    local spellName = trimText(type(detail) == "table" and detail.name or "")
    if spellName == "" then
        spellName = trimText(type(detail) == "table" and type(detail.spell) == "table" and detail.spell.name or "")
    end
    if spellName == "" then
        spellName = ensureString(type(detail) == "table" and detail.spellRef or "", "Unknown Spell")
    end

    return ("Tooltip template error: %s could not resolve aura '%s'."):format(spellName, ensureString(auraRef, "unknown"))
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
    if targetType == "last_melee_attacker" then
        return "the last enemy to attack you with a melee attack"
    end
    if targetType == "all_allies" then
        return "all allies"
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
    if targetType == "raid_marker" then
        return ("up to %d %s"):format(math.max(1, maxTargets), plural)
    end
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
    if targetType == "last_melee_attacker" then
        return {
            subject = "the last enemy to attack you with a melee attack",
            object = "the last enemy to attack you with a melee attack",
            possessive = "the last enemy to attack you with a melee attack's",
            reflexive = "itself",
        }
    end
    if targetType == "all_allies" then
        return {
            subject = "all allies",
            object = "all allies",
            possessive = "all allies'",
            reflexive = "themselves",
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
    if metadata.unresolved == true then
        error(buildTemplateResolutionError(detail, metadata.auraRef or auraRef))
    end
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
    local amountMode = tostring(effect.amountMode or "flat")
    local amountText = ""
    local reduceAmountText = ""
    
    if amountMode == "base_percent" then
        amountText = ("%g%% of Base %s"):format(amount, resourceName)
        reduceAmountText = ("%g%% of Base"):format(amount)
    elseif amountMode == "max_percent" then
        amountText = ("%g%% of Max %s"):format(amount, resourceName)
        reduceAmountText = ("%g%% of Max"):format(amount)
    else
        amountText = ("%d %s"):format(math.floor(amount), resourceName)
        reduceAmountText = tostring(math.floor(math.abs(amount)))
    end
    
    local targetPhrase = resolveTargetPhrase(component.target)
    if amount > 0 then
        return ("Restore %s to %s."):format(amountText, targetPhrase)
    end

    local possessive = resolveTargetPossessivePhrase(targetPhrase)
    if possessive then
        return ("Reduce %s %s by %s."):format(possessive, resourceName, reduceAmountText)
    end

    return ("Reduce %s for %s by %s."):format(resourceName, targetPhrase, reduceAmountText)
end

local function buildApplyAuraSentence(detail, component)
    local effect = component and component.effect or nil
    if type(effect) ~= "table" then
        return nil
    end

    local metadata = resolveAuraMetadata(detail, effect.auraRef)
    if metadata.unresolved == true then
        error(buildTemplateResolutionError(detail, metadata.auraRef or effect.auraRef))
    end
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

local function buildHideSentence(component)
    local targetPhrase = resolveTargetPhrase(component and component.target or nil)
    return ("Cause %s to become hidden."):format(targetPhrase)
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

local function buildTauntSentence(component)
    local effect = component and component.effect or nil
    if type(effect) ~= "table" then
        return nil
    end

    local targetPhrase = resolveTargetPhrase(component.target)
    local duration = math.max(1, math.floor(tonumber(effect.duration) or 2))
    return ("Taunt %s for %s."):format(targetPhrase, formatTurnLabel(duration))
end

local function buildRevertSentence(component)
    local targetPhrase = resolveTargetPhrase(component and component.target or nil)
    return ("Reverse the effects of the last reversible spell received by %s this turn."):format(targetPhrase)
end

local function formatAuraTagLabel(tag)
    local normalizedTag = trimText(tag)
    if normalizedTag == "" then
        return nil
    end

    return string.upper(normalizedTag:sub(1, 1)) .. normalizedTag:sub(2)
end

local function formatAuraTagList(tags, fallbackTag)
    local values = {}
    if type(tags) == "table" then
        for index = 1, #tags do
            local value = trimText(tags[index])
            if value ~= "" then
                values[#values + 1] = value
            end
        end
    elseif type(tags) == "string" then
        for tag in tags:gmatch("[^,]+") do
            tag = trimText(tag)
            if tag ~= "" then
                values[#values + 1] = tag
            end
        end
    end

    if #values == 0 and fallbackTag ~= nil then
        local value = trimText(fallbackTag)
        if value ~= "" then
            values[1] = value
        end
    end

    return table.concat(values, ", ")
end

local function buildRemoveAuraSentence(detail, component)
    local effect = component and component.effect or nil
    if type(effect) ~= "table" then
        return nil
    end

    if tostring(effect.match or "aura") == "tag" then
        local tagLabel = formatAuraTagLabel(effect.tag)
        if not tagLabel then
            return nil
        end

        local targetPhrase = resolveTargetPhrase(component.target)

        local maxAuras = tonumber(effect.maxAuras)
        if maxAuras and maxAuras > 0 and maxAuras < math.huge and math.floor(maxAuras) == maxAuras then
            return ("Remove up to %d auras tagged %s from %s."):format(maxAuras, tagLabel, targetPhrase)
        end

        return ("Remove all auras tagged %s from %s."):format(tagLabel, targetPhrase)
    end

    local auraRef = effect.auraRef
    if type(auraRef) ~= "string" or auraRef == "" then
        return ("Remove an aura from %s."):format(resolveTargetPhrase(component.target))
    end

    local metadata = resolveAuraMetadata(detail, auraRef)
    if metadata.unresolved == true then
        error(buildTemplateResolutionError(detail, metadata.auraRef or auraRef))
    end
    local targetPhrase = resolveTargetPhrase(component.target)
    local stacks = math.max(1, math.floor(tonumber(effect.stacks) or 1))
    if stacks > 1 then
        return ("Remove %d stacks of %s from %s."):format(stacks, metadata.name, targetPhrase)
    end

    return ("Remove %s from %s."):format(metadata.name, targetPhrase)
end

local function buildRemoveAuraByTagSentence(component)
    local effect = component and component.effect or nil
    if type(effect) ~= "table" then
        return nil
    end

    local tagList = formatAuraTagList(effect.tags, effect.tag)
    if tagList == "" then
        return nil
    end

    local targetPhrase = resolveTargetPhrase(component.target)
    local maxAuras = tonumber(effect.maxAuras)
    if maxAuras and maxAuras > 0 and maxAuras < math.huge and math.floor(maxAuras) == maxAuras then
        return ("Remove up to %d %s effects from %s."):format(maxAuras, tagList, targetPhrase)
    end

    return ("Remove all %s effects from %s."):format(tagList, targetPhrase)
end

local function hasRaidMarkerTarget(components)
    for index = 1, #(components or {}) do
        local target = components[index] and components[index].target or nil
        if tostring(target and target.type or "") == "raid_marker" then
            return true
        end
    end
    return false
end

local function appendRaidMarkerTooltipNote(description, components)
    if not hasRaidMarkerTarget(components) then
        return description
    end

    local text = trimText(description)
    if text == "" then
        return RAID_MARKER_TOOLTIP_NOTE
    end

    return text .. "\n" .. RAID_MARKER_TOOLTIP_NOTE
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
    if effectType == "hide" then
        return buildHideSentence(component)
    end
    if effectType == "summon_pet" then
        return buildSummonPetSentence()
    end
    if effectType == "interrupt" then
        return buildInterruptSentence(component)
    end
    if effectType == "taunt" then
        return buildTauntSentence(component)
    end
    if effectType == "revert" then
        return buildRevertSentence(component)
    end
    if effectType == "remove_aura" then
        return buildRemoveAuraSentence(detail, component)
    end
    if effectType == "remove_aura_by_tag" then
        return buildRemoveAuraByTagSentence(component)
    end

    return nil
end

local function buildSpellTemplateError(detail, message)
    local spellName = trimText(type(detail) == "table" and detail.name or "")
    if spellName == "" then
        spellName = trimText(type(detail) == "table" and type(detail.spell) == "table" and detail.spell.name or "")
    end
    if spellName == "" then
        spellName = ensureString(type(detail) == "table" and detail.spellRef or "", "Unknown Spell")
    end

    local suffix = trimText(message)
    if suffix == "" then
        suffix = "template payload is missing."
    end
    return ("Tooltip template error: %s %s"):format(spellName, suffix)
end

local function buildSpellTemplateToken(state, baseKey, tokenType, metadata)
    if type(TooltipTemplate.AddToken) ~= "function" then
        return ""
    end

    return TooltipTemplate.AddToken(state, baseKey, tokenType, metadata)
end

local function buildDamageSentenceTemplate(detail, componentIndex, component, state)
    local effect = component and component.effect or nil
    if type(effect) ~= "table" then
        return nil
    end

    local schoolLabel = resolveDamageSchoolLabel(detail, effect)
    local targetPhrase = resolveTargetPhrase(component.target)
    local amountMode = tostring(effect.amountMode or "flat")
    if amountMode == "base_percent" then
        local sentence = ("Deal %g%% of Base %s damage to %s"):format(tonumber(effect.baseDamage) or 0, schoolLabel, targetPhrase)
        local auraClause = effect.applyAura == true and buildAuraClause(detail, effect, false) or nil
        if auraClause then
            sentence = ("%s %s"):format(sentence, auraClause)
        end
        return sentence .. "."
    end
    if amountMode == "max_percent" then
        local sentence = ("Deal %g%% of Max %s damage to %s"):format(tonumber(effect.baseDamage) or 0, schoolLabel, targetPhrase)
        local auraClause = effect.applyAura == true and buildAuraClause(detail, effect, false) or nil
        if auraClause then
            sentence = ("%s %s"):format(sentence, auraClause)
        end
        return sentence .. "."
    end
    local amountToken = buildSpellTemplateToken(state, "DAMAGE", "spell_damage_range", {
        componentIndex = componentIndex,
        applyMode = "damage_range",
    })
    local sentence = ("Deal %s %s damage to %s"):format(amountToken, schoolLabel, targetPhrase)
    local auraClause = effect.applyAura == true and buildAuraClause(detail, effect, false) or nil
    if auraClause then
        sentence = ("%s %s"):format(sentence, auraClause)
    end

    return sentence .. "."
end

local function buildHealSentenceTemplate(detail, componentIndex, component, state)
    local effect = component and component.effect or nil
    if type(effect) ~= "table" then
        return nil
    end

    local targetPhrase = resolveTargetPhrase(component.target)
    local amountMode = tostring(effect.amountMode or "flat")
    if amountMode == "base_percent" then
        local sentence = ("Heal %s for %g%% of Base health"):format(targetPhrase, tonumber(effect.baseHealing) or 0)
        local auraClause = effect.applyAura == true and buildAuraClause(detail, effect, false) or nil
        if auraClause then
            sentence = ("%s %s"):format(sentence, auraClause)
        end
        return sentence .. "."
    end
    if amountMode == "max_percent" then
        local sentence = ("Heal %s for %g%% of Max health"):format(targetPhrase, tonumber(effect.baseHealing) or 0)
        local auraClause = effect.applyAura == true and buildAuraClause(detail, effect, false) or nil
        if auraClause then
            sentence = ("%s %s"):format(sentence, auraClause)
        end
        return sentence .. "."
    end
    local amountToken = buildSpellTemplateToken(state, "HEAL", "spell_heal_range", {
        componentIndex = componentIndex,
        applyMode = "heal_range",
    })
    local sentence = ("Heal %s for %s health"):format(targetPhrase, amountToken)
    local auraClause = effect.applyAura == true and buildAuraClause(detail, effect, false) or nil
    if auraClause then
        sentence = ("%s %s"):format(sentence, auraClause)
    end

    return sentence .. "."
end

local function buildResourceSentenceTemplate(detail, componentIndex, component, state)
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
    local amountMode = tostring(effect.amountMode or "flat")
    if amount > 0 then
        if amountMode == "base_percent" then
            return ("Restore %g%% of Base %s to %s."):format(amount, resourceName, targetPhrase)
        end
        if amountMode == "max_percent" then
            return ("Restore %g%% of Max %s to %s."):format(amount, resourceName, targetPhrase)
        end
        local amountToken = buildSpellTemplateToken(state, "RESOURCE_AMOUNT", "spell_resource_amount", {
            componentIndex = componentIndex,
            applyMode = "resource_gain_amount",
        })
        return ("Restore %s to %s."):format(amountToken, targetPhrase)
    end

    local possessive = resolveTargetPossessivePhrase(targetPhrase)
    if amountMode == "base_percent" then
        if possessive then
            return ("Reduce %s %s by %g%% of Base."):format(possessive, resourceName, math.abs(amount))
        end
        return ("Reduce %s for %s by %g%% of Base."):format(resourceName, targetPhrase, math.abs(amount))
    end
    if amountMode == "max_percent" then
        if possessive then
            return ("Reduce %s %s by %g%% of Max."):format(possessive, resourceName, math.abs(amount))
        end
        return ("Reduce %s for %s by %g%% of Max."):format(resourceName, targetPhrase, math.abs(amount))
    end
    local amountToken = buildSpellTemplateToken(state, "RESOURCE_LOSS", "spell_resource_amount", {
        componentIndex = componentIndex,
        applyMode = "resource_loss_amount",
    })
    if possessive then
        return ("Reduce %s %s by %s."):format(possessive, resourceName, amountToken)
    end

    return ("Reduce %s for %s by %s."):format(resourceName, targetPhrase, amountToken)
end

local function buildTemplateSentence(detail, componentIndex, component, state)
    local effectType = tostring(component and component.effect and component.effect.type or "")
    if effectType == "damage" then
        return buildDamageSentenceTemplate(detail, componentIndex, component, state)
    end
    if effectType == "heal" then
        return buildHealSentenceTemplate(detail, componentIndex, component, state)
    end
    if effectType == "resource" then
        return buildResourceSentenceTemplate(detail, componentIndex, component, state)
    end
    if effectType == "apply_aura" then
        return buildApplyAuraSentence(detail, component)
    end
    if effectType == "hide" then
        return buildHideSentence(component)
    end
    if effectType == "summon_pet" then
        return buildSummonPetSentence()
    end
    if effectType == "interrupt" then
        return buildInterruptSentence(component)
    end
    if effectType == "taunt" then
        return buildTauntSentence(component)
    end
    if effectType == "revert" then
        return buildRevertSentence(component)
    end
    if effectType == "remove_aura" then
        return buildRemoveAuraSentence(detail, component)
    end
    if effectType == "remove_aura_by_tag" then
        return buildRemoveAuraByTagSentence(component)
    end

    return nil
end

local function resolveSpellTemplateComponent(detail, token)
    local spell = resolveCurrentSpellDefinition(detail)
    local componentIndex = math.floor(tonumber(type(token) == "table" and token.componentIndex or 0) or 0)
    if type(spell) ~= "table" or componentIndex <= 0 then
        return nil
    end

    local rawComponent = (spell.components or {})[componentIndex]
    return type(Combat.NormalizeComponent) == "function" and Combat:NormalizeComponent(rawComponent) or rawComponent
end

local function resolveSpellResourceTemplateToken(detail, token)
    local component = resolveSpellTemplateComponent(detail, token)
    local effect = type(component) == "table" and component.effect or nil
    if type(effect) ~= "table" then
        return nil
    end

    local amount = tonumber(effect.amount) or 0
    local amountMode = tostring(effect.amountMode or "flat")
    local resourceName = resolveResourceName(effect.resourceRef)
    local applyMode = tostring(token and token.applyMode or "")
    if applyMode == "resource_gain_amount" then
        if amountMode == "base_percent" then
            return ("%g%% of Base %s"):format(amount, resourceName)
        end
        if amountMode == "max_percent" then
            return ("%g%% of Max %s"):format(amount, resourceName)
        end
        return ("%d %s"):format(math.floor(amount), resourceName)
    end

    local lossAmount = math.abs(amount)
    if amountMode == "base_percent" then
        return ("%g%% of Base"):format(lossAmount)
    end
    if amountMode == "max_percent" then
        return ("%g%% of Max"):format(lossAmount)
    end
    return tostring(math.floor(lossAmount))
end

local function resolveSpellTemplateToken(detail, casterUnit, token)
    local applyMode = tostring(token and token.applyMode or "")
    if applyMode == "damage_range" then
        local component = resolveSpellTemplateComponent(detail, token)
        local effect = type(component) == "table" and component.effect or nil
        if type(effect) ~= "table" or type(Combat.ResolveDamageAmount) ~= "function" then
            return nil
        end
        local minimum = Combat:ResolveDamageAmount(buildValueContext(casterUnit, MIN_VARIANCE, "min"), effect)
        local maximum = Combat:ResolveDamageAmount(buildValueContext(casterUnit, MAX_VARIANCE, "max"), effect)
        return formatValueRange(minimum, maximum)
    end
    if applyMode == "heal_range" then
        local component = resolveSpellTemplateComponent(detail, token)
        local effect = type(component) == "table" and component.effect or nil
        if type(effect) ~= "table" or type(Combat.ResolveHealingAmount) ~= "function" then
            return nil
        end
        local minimum = Combat:ResolveHealingAmount(buildValueContext(casterUnit, MIN_VARIANCE, "min"), effect)
        local maximum = Combat:ResolveHealingAmount(buildValueContext(casterUnit, MAX_VARIANCE, "max"), effect)
        return formatValueRange(minimum, maximum)
    end
    if applyMode == "resource_gain_amount" or applyMode == "resource_loss_amount" then
        return resolveSpellResourceTemplateToken(detail, token)
    end

    return nil
end

local function resolveTooltipTargetUnit(detail)
    if type(detail) == "table" and type(detail.activationState) == "table" and type(detail.activationState.targetUnit) == "table" then
        return detail.activationState.targetUnit
    end
    if type(detail) == "table" and type(detail.spellRef) == "string" and detail.spellRef ~= "" and type(Client.ResolveSpellActivationState) == "function" then
        local activationState = Client:ResolveSpellActivationState(detail.spellRef, {
            includeTargetCandidates = false,
        })
        if type(activationState) == "table" and type(activationState.targetUnit) == "table" then
            return activationState.targetUnit
        end
    end

    return nil
end

function DescriptionBuilder:BuildTooltipTemplatePayload(detail)
    local spell = type(detail) == "table" and detail.spell or nil
    if type(spell) ~= "table" or type(TooltipTemplate.CreateBuildState) ~= "function" then
        return nil
    end

    local normalizedComponents = {}
    local componentIndices = {}
    local hasNonDefaultPhase = false
    for index = 1, #(spell.components or {}) do
        local rawComponent = spell.components[index]
        local component = type(Combat.NormalizeComponent) == "function" and Combat:NormalizeComponent(rawComponent) or rawComponent
        if type(component) == "table" and type(component.effect) == "table" then
            normalizedComponents[#normalizedComponents + 1] = component
            componentIndices[#componentIndices + 1] = index
            if tostring(component.castPhase or "on_cast_end") ~= "on_cast_end" then
                hasNonDefaultPhase = true
            end
        end
    end

    local state = TooltipTemplate.CreateBuildState()
    local sentences = {}
    for index = 1, #normalizedComponents do
        local component = normalizedComponents[index]
        local sentence = buildTemplateSentence(detail, componentIndices[index], component, state)
        if sentence and sentence ~= "" then
            if hasNonDefaultPhase then
                sentence = buildPhasePrefix(component.castPhase) .. sentence
            end
            sentences[#sentences + 1] = sentence
        end
    end

    local mainText = appendThreatDescription(detail, prependBasicAttackPrefix(detail, table.concat(sentences, " ")))
    mainText = appendRaidMarkerTooltipNote(mainText, normalizedComponents)
    local casterUnit = resolveCasterUnit(detail)
    local targetUnit = resolveTooltipTargetUnit(detail)
    local auraSections = {}
    local seen = {}
    for index = 1, #normalizedComponents do
        local component = normalizedComponents[index]
        local effect = component and component.effect or nil
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
                    local sectionTemplate, templateError = AuraDescriptionBuilder:BuildTooltipSectionTemplate(auraRef, {
                        dataset = type(detail) == "table" and detail.dataset or nil,
                        datasetId = resolveDatasetId(detail),
                        spellDatasetId = resolveDatasetId(detail),
                        casterUnit = casterUnit,
                        targetUnit = targetUnit,
                        powerLevel = powerLevel,
                        stacks = stacks,
                        duration = duration,
                        targetContext = targetContext,
                    })
                    if type(sectionTemplate) ~= "table" then
                        error(trimText(templateError or buildSpellTemplateError(detail, "could not build linked aura section template.")))
                    end
                    auraSections[#auraSections + 1] = sectionTemplate
                end
            end
        end
    end

    return TooltipTemplate.NormalizeSpellPayload({
        mainText = mainText,
        tokens = state.tokens,
        auraSections = auraSections,
    })
end

function DescriptionBuilder:ResolveTooltipTemplatePayload(detail, payload, casterUnit)
    local normalizedPayload = type(TooltipTemplate.NormalizeSpellPayload) == "function"
        and TooltipTemplate.NormalizeSpellPayload(payload)
        or nil
    if type(normalizedPayload) ~= "table" then
        return nil, buildSpellTemplateError(detail, "template payload is missing.")
    end

    casterUnit = casterUnit or resolveCasterUnit(detail)
    local resolvedMainText, resolveError = TooltipTemplate.ResolveText(normalizedPayload.mainText, normalizedPayload.tokens, function(token)
        return resolveSpellTemplateToken(detail, casterUnit, token)
    end)
    if resolvedMainText == nil then
        return nil, buildSpellTemplateError(detail, resolveError)
    end

    local targetUnit = resolveTooltipTargetUnit(detail)
    local auraSections = {}
    for index = 1, #(normalizedPayload.auraSections or {}) do
        local section = normalizedPayload.auraSections[index]
        local resolvedDescriptionText = nil
        local sectionError = nil
        local auraBuilder = AuraDescriptionBuilder
        if type(auraBuilder) == "table" and type(auraBuilder.ResolveTooltipSectionTemplate) == "function" then
            resolvedDescriptionText, sectionError = auraBuilder:ResolveTooltipSectionTemplate(section, {
                dataset = type(detail) == "table" and detail.dataset or nil,
                datasetId = resolveDatasetId(detail),
                spellDatasetId = resolveDatasetId(detail),
                casterUnit = casterUnit,
                targetUnit = targetUnit,
            })
        end
        resolvedDescriptionText = trimText(resolvedDescriptionText)
        if resolvedDescriptionText == "" then
            return nil, buildSpellTemplateError(detail, trimText(sectionError or "could not resolve linked aura section template."))
        end
        auraSections[#auraSections + 1] = {
            auraRef = section.auraRef,
            name = ensureString(section.nameText, "Aura"),
            icon = ensureString(section.icon, ""),
            descriptionText = resolvedDescriptionText,
            descriptionSource = "template",
        }
    end

    return {
        descriptionText = resolvedMainText,
        descriptionSource = "template",
        auraSections = auraSections,
    }, nil
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

prependBasicAttackPrefix = function(detail, descriptionText)
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

appendThreatDescription = function(detail, descriptionText)
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

    local description = appendThreatDescription(detail, prependBasicAttackPrefix(detail, table.concat(sentences, " ")))
    return appendRaidMarkerTooltipNote(description, normalizedComponents)
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
    local currentSpell = resolveCurrentSpellDefinition(detail)
    local rawAuthoredDescriptionText = trimText(
        type(detail) == "table" and detail.authoredDescriptionText
            or type(currentSpell) == "table" and currentSpell.description
            or ""
    )
    local useTooltipTemplate = type(detail) == "table"
        and type(currentSpell) == "table"
        and currentSpell.tooltipTemplate == true
    if useTooltipTemplate then
        local spell = currentSpell
        local casterUnit = resolveCasterUnit(detail)
        local cacheKey = buildGeneratedDescriptionCacheKey(detail, casterUnit)
        local cachedTooltipData = getCachedResolvedTemplateTooltipPayload(detail, cacheKey)
        if type(cachedTooltipData) == "table" then
            detail.descriptionText = trimText(cachedTooltipData.descriptionText or "")
            detail.descriptionSource = ensureString(cachedTooltipData.descriptionSource, "template")
            return cachedTooltipData
        end
        local payload = type(spell) == "table" and spell.tooltipTemplateData or nil
        local tooltipData, resolveError = self:ResolveTooltipTemplatePayload(detail, payload, casterUnit)
        if type(tooltipData) ~= "table" then
            local errorText = trimText(resolveError or buildSpellTemplateError(detail, "template payload is missing."))
            return storeResolvedTemplateTooltipPayload(detail, {
                descriptionText = "",
                descriptionSource = "error",
                auraSections = {},
                errorText = errorText,
            }, cacheKey)
        end
        return storeResolvedTemplateTooltipPayload(detail, tooltipData, cacheKey)
    end
    local authoredDescriptionText = rawAuthoredDescriptionText
    local requiresGeneratedDescription = authoredDescriptionText == ""
    local cacheKey = buildGeneratedDescriptionCacheKey(detail, nil)
    local hasCachedGeneratedDescription = type(detail) == "table"
        and tostring(detail.generatedDescriptionCacheKey or "") == cacheKey
        and detail.generatedDescriptionText ~= nil
    local hasCachedAuraSections = type(detail) == "table"
        and tostring(detail.generatedAuraSectionsCacheKey or "") == cacheKey
        and type(detail.generatedAuraSections) == "table"

    local allowDeferredBuild = not (type(options) == "table" and options.deferGeneration == false)
    local tooltipOwner = type(options) == "table" and options.tooltipOwner or nil
    if requiresGeneratedDescription
        and (not hasCachedGeneratedDescription or not hasCachedAuraSections)
        and allowDeferredBuild
        and self:QueueDescriptionBuild(detail, cacheKey, tooltipOwner)
    then
        local fallbackDescriptionText = authoredDescriptionText
        local fallbackSource = useTooltipTemplate and "summary" or "authored"
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

    if (requiresGeneratedDescription and not hasCachedGeneratedDescription) or not hasCachedAuraSections then
        local casterUnit = resolveCasterUnit(detail)
        if requiresGeneratedDescription then
            local generatedDescriptionText, generatedAuraSections = nil, nil
            local generatedSuccessfully, generationError = pcall(function()
                generatedDescriptionText, generatedAuraSections = self:BuildGeneratedTooltipPayload(detail, casterUnit)
            end)
            if not generatedSuccessfully then
                local errorText = trimText(generationError or "")
                if errorText == "" then
                    errorText = "Tooltip template error."
                end
                detail.descriptionText = ""
                detail.descriptionSource = "error"
                detail.generatedDescriptionText = nil
                detail.generatedDescriptionCacheKey = nil
                detail.generatedAuraSections = nil
                detail.generatedAuraSectionsCacheKey = nil
                clearPendingDescriptionKey(detail, cacheKey)
                return {
                    descriptionText = "",
                    descriptionSource = "error",
                    auraSections = {},
                    errorText = errorText,
                }
            end
            storeGeneratedTooltipPayload(detail, generatedDescriptionText, generatedAuraSections, cacheKey)
            hasCachedGeneratedDescription = true
            hasCachedAuraSections = true
        else
            local generatedAuraSections = nil
            local generatedSuccessfully, generationError = pcall(function()
                generatedAuraSections = self:BuildGeneratedAuraSections(detail, casterUnit)
            end)
            if not generatedSuccessfully then
                local errorText = trimText(generationError or "")
                if errorText == "" then
                    errorText = "Tooltip template error."
                end
                clearPendingDescriptionKey(detail, cacheKey)
                if useTooltipTemplate then
                    return {
                        descriptionText = "",
                        descriptionSource = "error",
                        auraSections = {},
                        errorText = errorText,
                    }
                end
                detail.generatedAuraSections = {}
            else
                detail.generatedAuraSections = type(generatedAuraSections) == "table" and generatedAuraSections or {}
            end
            detail.generatedAuraSectionsCacheKey = cacheKey
            hasCachedAuraSections = true
        end
        clearPendingDescriptionKey(detail, cacheKey)
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
