local _, Addon = ...

Addon.Internal = Addon.Internal or {}
Addon.Internal.Loot = Addon.Internal.Loot or {}

local Loot = Addon.Internal.Loot
local Registry = Addon.Internal.Registry or {}
local Profile = Addon.Internal.Profile or {}

local function trim(value)
    return tostring(value or ""):match("^%s*(.-)%s*$")
end

local function finiteNumber(value)
    local numeric = tonumber(value)
    if numeric == nil
        or numeric ~= numeric
        or numeric == math.huge
        or numeric == -math.huge
    then
        return nil
    end
    return numeric
end

local function positiveInteger(value)
    local numeric = finiteNumber(value)
    if numeric == nil or numeric < 1 or numeric ~= math.floor(numeric) then
        return nil
    end
    return numeric
end

local function positiveNumber(value)
    local numeric = finiteNumber(value)
    if numeric == nil or numeric <= 0 then
        return nil
    end
    return numeric
end

local function copyReward(reward)
    return {
        type = reward.type,
        ref = reward.ref,
        amount = reward.amount,
    }
end

local function normalizeRewardType(value)
    local rewardType = string.lower(trim(value))
    if rewardType == "item" or rewardType == "currency" or rewardType == "nothing" then
        return rewardType
    end
    return nil
end

local function readRandomSample(rng)
    local callOk = false
    local sample = nil

    if rng == nil then
        if type(math.random) ~= "function" then
            return nil, "invalid-rng", { reason = "random-api-unavailable" }
        end
        callOk, sample = pcall(math.random)
    elseif type(rng) == "function" then
        callOk, sample = pcall(rng)
    elseif type(rng) == "table" and type(rng.Next) == "function" then
        callOk, sample = pcall(rng.Next, rng)
    elseif type(rng) == "table" and type(rng.next) == "function" then
        callOk, sample = pcall(rng.next, rng)
    else
        return nil, "invalid-rng", { reason = "unsupported-rng" }
    end

    if not callOk then
        return nil, "invalid-rng", { reason = "rng-call-failed" }
    end

    sample = finiteNumber(sample)
    if sample == nil or sample < 0 or sample >= 1 then
        return nil, "invalid-rng", {
            reason = "sample-out-of-range",
            sample = sample,
        }
    end

    return sample
end

local function collectOrderedEntries(entries)
    local ordered = {}
    if type(entries) ~= "table" then
        return ordered
    end

    for key, entry in pairs(entries) do
        if type(key) == "number" then
            ordered[#ordered + 1] = {
                index = key,
                entry = entry,
            }
        end
    end

    table.sort(ordered, function(left, right)
        return left.index < right.index
    end)
    return ordered
end

local function canonicalizeItemReference(reference)
    local normalizedRef = trim(reference)
    if normalizedRef == "" then
        return nil, "invalid-reward", { field = "ref" }
    end
    if type(Registry.ResolveItemReference) ~= "function" then
        return nil, "unknown-item", {
            ref = normalizedRef,
            reason = "item-api-unavailable",
        }
    end

    local ok, dataset, item = pcall(Registry.ResolveItemReference, Registry, normalizedRef)
    if not ok or type(dataset) ~= "table" or type(item) ~= "table" then
        return nil, "unknown-item", { ref = normalizedRef }
    end

    local datasetId = trim(dataset.id)
    local itemId = trim(item.id)
    if datasetId == "" or itemId == "" then
        return nil, "unknown-item", { ref = normalizedRef }
    end

    return ("%s:%s"):format(datasetId, itemId)
end

local function canonicalizeCurrencyReference(reference)
    local normalizedRef = trim(reference)
    if normalizedRef == "" then
        return nil, "invalid-reward", { field = "ref" }
    end
    if type(Profile.NormalizeCurrencyKey) ~= "function"
        or type(Profile.ResolveCurrencyDefinition) ~= "function"
    then
        return nil, "unknown-currency", {
            ref = normalizedRef,
            reason = "currency-api-unavailable",
        }
    end

    local normalizeOk, canonicalRef = pcall(Profile.NormalizeCurrencyKey, normalizedRef)
    canonicalRef = normalizeOk and trim(canonicalRef) or ""
    if canonicalRef == "" then
        return nil, "unknown-currency", { ref = normalizedRef }
    end

    local resolveOk, definition = pcall(Profile.ResolveCurrencyDefinition, canonicalRef)
    if not resolveOk or type(definition) ~= "table" or definition.isMissing == true then
        return nil, "unknown-currency", { ref = canonicalRef }
    end

    return canonicalRef
end

function Loot.ValidateConcreteReward(reward)
    if type(reward) ~= "table" then
        return nil, "invalid-reward", { reason = "reward-not-table" }
    end

    local rewardType = normalizeRewardType(reward.type)
    if not rewardType or rewardType == "nothing" then
        return nil, "invalid-reward", {
            field = "type",
            value = reward.type,
        }
    end

    local amount = positiveInteger(reward.amount)
    if not amount then
        return nil, "invalid-reward", {
            field = "amount",
            value = reward.amount,
        }
    end

    local reference, err, detail = nil, nil, nil
    if rewardType == "item" then
        reference, err, detail = canonicalizeItemReference(reward.ref)
    else
        reference, err, detail = canonicalizeCurrencyReference(reward.ref)
    end
    if not reference then
        return nil, err, detail
    end

    return {
        type = rewardType,
        ref = reference,
        amount = amount,
    }
end

function Loot.ValidateLootTable(loot)
    if type(loot) ~= "table" then
        return nil, "invalid-loot-table", { reason = "loot-not-table" }
    end

    local drawCount = positiveInteger(loot.drawCount)
    if not drawCount then
        return nil, "invalid-draw-count", { value = loot.drawCount }
    end

    local orderedEntries = collectOrderedEntries(loot.entries)
    if #orderedEntries == 0 then
        return nil, "no-loot-entries", {}
    end

    local normalizedEntries = {}
    local entryIds = {}
    local totalWeight = 0

    for position = 1, #orderedEntries do
        local sourceIndex = orderedEntries[position].index
        local entry = orderedEntries[position].entry
        if type(entry) ~= "table" then
            return nil, "invalid-entry", {
                entryIndex = sourceIndex,
                reason = "entry-not-table",
            }
        end

        local entryId = trim(entry.id)
        if entryId == "" then
            return nil, "invalid-entry", {
                entryIndex = sourceIndex,
                field = "id",
                reason = "blank-entry-id",
            }
        end
        if entryIds[entryId] then
            return nil, "duplicate-entry-id", {
                entryIndex = sourceIndex,
                entryId = entryId,
            }
        end
        entryIds[entryId] = true

        local rewardType = normalizeRewardType(entry.type)
        if not rewardType then
            return nil, "invalid-entry", {
                entryIndex = sourceIndex,
                entryId = entryId,
                field = "type",
                value = entry.type,
            }
        end

        local weight = positiveNumber(entry.weight)
        if not weight then
            return nil, "invalid-weight", {
                entryIndex = sourceIndex,
                entryId = entryId,
                value = entry.weight,
            }
        end

        totalWeight = totalWeight + weight
        if finiteNumber(totalWeight) == nil then
            return nil, "invalid-weight", {
                entryIndex = sourceIndex,
                entryId = entryId,
                reason = "total-weight-not-finite",
            }
        end

        local normalizedEntry = {
            id = entryId,
            type = rewardType,
            weight = weight,
            sourceIndex = sourceIndex,
        }
        if rewardType ~= "nothing" then
            local minimum = positiveInteger(entry.minQuantity)
            local maximum = positiveInteger(entry.maxQuantity)
            if not minimum or not maximum or maximum < minimum then
                return nil, "invalid-quantity-range", {
                    entryIndex = sourceIndex,
                    entryId = entryId,
                    minQuantity = entry.minQuantity,
                    maxQuantity = entry.maxQuantity,
                }
            end

            local concrete, err, detail = Loot.ValidateConcreteReward({
                type = rewardType,
                ref = entry.ref,
                amount = 1,
            })
            if not concrete then
                detail = type(detail) == "table" and detail or {}
                detail.entryIndex = sourceIndex
                detail.entryId = entryId
                return nil, err, detail
            end
            normalizedEntry.type = concrete.type
            normalizedEntry.ref = concrete.ref
            normalizedEntry.minQuantity = minimum
            normalizedEntry.maxQuantity = maximum
        end
        normalizedEntries[#normalizedEntries + 1] = normalizedEntry
    end

    return {
        id = trim(loot.id),
        drawCount = drawCount,
        entries = normalizedEntries,
        totalWeight = totalWeight,
    }
end

function Loot.ResolveWeightedEntry(entries, rng)
    local orderedEntries = collectOrderedEntries(entries)
    if #orderedEntries == 0 then
        return nil, "no-loot-entries", {}
    end

    local totalWeight = 0
    local normalized = {}
    for position = 1, #orderedEntries do
        local sourceIndex = orderedEntries[position].index
        local entry = orderedEntries[position].entry
        local weight = type(entry) == "table" and positiveNumber(entry.weight) or nil
        if not weight then
            return nil, "invalid-weight", {
                entryIndex = sourceIndex,
                value = type(entry) == "table" and entry.weight or nil,
            }
        end
        totalWeight = totalWeight + weight
        if finiteNumber(totalWeight) == nil then
            return nil, "invalid-weight", {
                entryIndex = sourceIndex,
                reason = "total-weight-not-finite",
            }
        end
        normalized[#normalized + 1] = entry
    end

    local sample, err, detail = readRandomSample(rng)
    if sample == nil then
        return nil, err, detail
    end

    local target = sample * totalWeight
    local cumulative = 0
    for index = 1, #normalized do
        cumulative = cumulative + normalized[index].weight
        if target < cumulative then
            return normalized[index]
        end
    end

    -- A valid sample is in [0,1). This fallback only covers floating-point edge
    -- behavior and deliberately does not consume another random sample.
    return normalized[#normalized]
end

function Loot.ResolveQuantity(minQuantity, maxQuantity, rng)
    local minimum = positiveInteger(minQuantity)
    local maximum = positiveInteger(maxQuantity)
    if not minimum or not maximum or maximum < minimum then
        return nil, "invalid-quantity-range", {
            minQuantity = minQuantity,
            maxQuantity = maxQuantity,
        }
    end

    if minimum == maximum then
        return minimum
    end

    local sample, err, detail = readRandomSample(rng)
    if sample == nil then
        return nil, err, detail
    end

    local span = maximum - minimum + 1
    return minimum + math.floor(sample * span)
end

local function mergeValidatedRewards(rewards)
    local merged = {}
    local indexByKey = {}
    for index = 1, #(rewards or {}) do
        local reward = rewards[index]
        local key = reward.type .. "\0" .. reward.ref
        local existingIndex = indexByKey[key]
        if existingIndex then
            merged[existingIndex].amount = merged[existingIndex].amount + reward.amount
        else
            indexByKey[key] = #merged + 1
            merged[#merged + 1] = copyReward(reward)
        end
    end
    return merged
end

function Loot.MergeConcreteRewards(rewards)
    if type(rewards) ~= "table" then
        return nil, "invalid-reward", { reason = "rewards-not-table" }
    end

    local validated = {}
    for index = 1, #rewards do
        local concrete, err, detail = Loot.ValidateConcreteReward(rewards[index])
        if not concrete then
            detail = type(detail) == "table" and detail or {}
            detail.rewardIndex = index
            return nil, err, detail
        end
        validated[#validated + 1] = concrete
    end

    return mergeValidatedRewards(validated)
end

function Loot.ResolveValidatedLootTable(validatedLoot, rng)
    if type(validatedLoot) ~= "table"
        or positiveInteger(validatedLoot.drawCount) == nil
        or type(validatedLoot.entries) ~= "table"
        or #validatedLoot.entries == 0
    then
        return nil, "invalid-loot-table", { reason = "validated-table-required" }
    end

    local rewards = {}
    for drawIndex = 1, validatedLoot.drawCount do
        local entry, err, detail = Loot.ResolveWeightedEntry(validatedLoot.entries, rng)
        if not entry then
            detail = type(detail) == "table" and detail or {}
            detail.drawIndex = drawIndex
            return nil, err, detail
        end

        if entry.type ~= "nothing" then
            local amount = nil
            amount, err, detail = Loot.ResolveQuantity(entry.minQuantity, entry.maxQuantity, rng)
            if not amount then
                detail = type(detail) == "table" and detail or {}
                detail.drawIndex = drawIndex
                detail.entryId = entry.id
                return nil, err, detail
            end

            rewards[#rewards + 1] = {
                type = entry.type,
                ref = entry.ref,
                amount = amount,
            }
        end
    end

    return mergeValidatedRewards(rewards)
end

function Loot.ResolveLootTable(loot, rng)
    local validated, err, detail = Loot.ValidateLootTable(loot)
    if not validated then
        return nil, err, detail
    end
    return Loot.ResolveValidatedLootTable(validated, rng)
end

function Loot.ResolveDirectReward(reward)
    local concrete, err, detail = Loot.ValidateConcreteReward(reward)
    if not concrete then
        return nil, err, detail
    end
    return { concrete }
end

function Loot.ResolveLootReference(lootRef)
    local normalizedRef = trim(lootRef)
    if normalizedRef == "" then
        return nil, "invalid-loot-table", { field = "lootRef" }
    end
    if type(Registry.ResolveLootReference) ~= "function" then
        return nil, "unknown-loot-table", {
            lootRef = normalizedRef,
            reason = "loot-api-unavailable",
        }
    end

    local ok, dataset, loot = pcall(Registry.ResolveLootReference, Registry, normalizedRef)
    if not ok or type(dataset) ~= "table" or type(loot) ~= "table" then
        return nil, "unknown-loot-table", { lootRef = normalizedRef }
    end

    return Loot.ValidateLootTable(loot)
end

function Loot.PrepareSource(source)
    if type(source) ~= "table" then
        return nil, "unsupported-source", { reason = "source-not-table" }
    end

    local sourceType = string.lower(trim(source.type))
    if sourceType == "direct" then
        local reward, err, detail = Loot.ValidateConcreteReward(source.reward)
        if not reward then
            return nil, err, detail
        end
        return {
            type = "direct",
            reward = reward,
        }
    end

    if sourceType == "table" then
        local validated, err, detail = Loot.ResolveLootReference(source.lootRef)
        if not validated then
            return nil, err, detail
        end
        return {
            type = "table",
            lootRef = trim(source.lootRef),
            loot = validated,
        }
    end

    return nil, "unsupported-source", {
        sourceType = source.type,
    }
end

function Loot.NormalizeEligiblePlayers(players)
    local normalized = {}
    local seen = {}
    local orderedPlayers = collectOrderedEntries(players)

    for index = 1, #orderedPlayers do
        local value = orderedPlayers[index].entry
        local identity = type(value) == "string" and trim(value) or ""
        if identity ~= "" and not seen[identity] then
            seen[identity] = true
            normalized[#normalized + 1] = identity
        end
    end

    if #normalized == 0 then
        return nil, "empty-eligibility", {}
    end
    return normalized
end

function Loot.ResolveUniformPlayer(players, rng)
    local normalized, err, detail = Loot.NormalizeEligiblePlayers(players)
    if not normalized then
        return nil, err, detail
    end

    if #normalized == 1 then
        return normalized[1]
    end

    local sample = nil
    sample, err, detail = readRandomSample(rng)
    if sample == nil then
        return nil, err, detail
    end

    local index = math.floor(sample * #normalized) + 1
    return normalized[index]
end

local function appendAssignment(assignments, assignmentByPlayer, player, rewards)
    local assignment = assignmentByPlayer[player]
    if not assignment then
        assignment = {
            player = player,
            rewards = {},
        }
        assignmentByPlayer[player] = assignment
        assignments[#assignments + 1] = assignment
    end

    for index = 1, #rewards do
        assignment.rewards[#assignment.rewards + 1] = copyReward(rewards[index])
    end
end

local function resolvePreparedTable(preparedSource, rng)
    return Loot.ResolveValidatedLootTable(preparedSource.loot, rng)
end

function Loot.BuildAssignments(source, distribution, eligiblePlayers, rng)
    local players, err, detail = Loot.NormalizeEligiblePlayers(eligiblePlayers)
    if not players then
        return nil, err, detail
    end

    local distributionType = string.lower(trim(distribution))
    if distributionType ~= "personal" and distributionType ~= "group" then
        return nil, "unsupported-distribution", {
            distribution = distribution,
        }
    end

    local prepared = nil
    prepared, err, detail = Loot.PrepareSource(source)
    if not prepared then
        return nil, err, detail
    end

    local assignments = {}
    local assignmentByPlayer = {}

    if distributionType == "personal" then
        for playerIndex = 1, #players do
            local rewards = nil
            if prepared.type == "direct" then
                rewards = { prepared.reward }
            else
                rewards, err, detail = resolvePreparedTable(prepared, rng)
                if not rewards then
                    detail = type(detail) == "table" and detail or {}
                    detail.player = players[playerIndex]
                    return nil, err, detail
                end
            end
            if #rewards > 0 then
                appendAssignment(assignments, assignmentByPlayer, players[playerIndex], rewards)
            end
        end
        return assignments
    end

    if prepared.type == "direct" then
        local player = nil
        player, err, detail = Loot.ResolveUniformPlayer(players, rng)
        if not player then
            return nil, err, detail
        end
        appendAssignment(assignments, assignmentByPlayer, player, { prepared.reward })
        return assignments
    end

    local rewards = nil
    rewards, err, detail = resolvePreparedTable(prepared, rng)
    if not rewards then
        return nil, err, detail
    end

    for rewardIndex = 1, #rewards do
        local player = nil
        player, err, detail = Loot.ResolveUniformPlayer(players, rng)
        if not player then
            detail = type(detail) == "table" and detail or {}
            detail.rewardIndex = rewardIndex
            return nil, err, detail
        end
        appendAssignment(assignments, assignmentByPlayer, player, { rewards[rewardIndex] })
    end

    return assignments
end

-- Loot.conditions remains inert here. #150 confirmed no existing Loot-specific
-- condition evaluator contract, so probability math does not invent semantics.
