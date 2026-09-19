local function assertEqual(actual, expected, message)
    if actual ~= expected then
        error(("%s: expected %s, got %s"):format(message, tostring(expected), tostring(actual)), 2)
    end
end

local auraDataset = {
    id = "ranktest",
    auras = {
        { id = "ward", name = "Ward", duration = 4, maxStacks = 1, effects = {} },
        { id = "legacy", name = "Legacy", duration = 4, maxStacks = 1, effects = {} },
        {
            id = "ranked-dot",
            name = "Ranked Dot",
            duration = 3,
            maxStacks = 5,
            effects = {
                {
                    type = "damage",
                    baseDamage = 10,
                    amountMode = "base_percent",
                    resourceRef = "health",
                    statScaling = { { statRef = "might", coefficient = 1 } },
                },
            },
        },
    },
}

local eventState
local spellRankResolverCalls = 0
local caster
local weaponDefinitions = {
    ["ranktest:sword"] = { damageMode = "range", minDamagePerTurn = 10, maxDamagePerTurn = 20 },
}
local activeRuleset = { rules = { character = { dismount_on_direct_damage = false } } }
local tasks = {
    Enqueue = function()
        return true
    end,
}
local combat = {
    BumpCombatRuntimeRevision = function() end,
    CreateEffectContract = function(_, definition)
        return definition
    end,
    ResolveDefenceSystem = function()
        return "ac"
    end,
    ResolveEffectResultType = function()
        return "hit"
    end,
    GetCombatRule = function()
        return ""
    end,
    IsUnitDead = function()
        return false
    end,
    ApplyResourceDelta = function()
        return true, { currentValue = 50, maxValue = 100 }, 1
    end,
    ResolveHitCheckAttackType = function(_, effect)
        return effect and effect.damageType or "melee"
    end,
    ResolveWeaponItemRef = function(_, unit, slotKey, fallbackField)
        return unit and unit[fallbackField] or nil
    end,
    ResolveItemDefinition = function(_, itemRef)
        return weaponDefinitions[itemRef]
    end,
    EmitDamageTypeEvent = function()
        return true
    end,
}

local Addon = {
    Client = {
        Spellcasting = {
            GetLocalPlayerName = function()
                return ""
            end,
            GetActiveSpellcastContext = function()
                return { active = true, channelName = "ranktest" }, eventState
            end,
            NormalizeName = function(value)
                return tostring(value or "")
            end,
            ApplySpellRankMultiplier = function(context, amount)
                return amount * (tonumber(context and (context.spellRankMultiplier or context.multiplier)) or 1)
            end,
            ResolveSpellRankContext = function(spell, options)
                spellRankResolverCalls = spellRankResolverCalls + 1
                assertEqual(type(spell), "table", "shared rank resolver receives the Spell")
                assertEqual(options and options.casterUnit == caster, true, "shared rank resolver receives the caster")
                assertEqual(options and options.eventState == eventState, true, "shared rank resolver receives event state")
                if spell.usesRanks == false then
                    return { rank = 1, multiplier = 1, usesRanks = false }
                end
                return { rank = 3, multiplier = 1.2 }
            end,
        },
        Combat = combat,
        GetEventState = function()
            return eventState
        end,
        ResolveLocalEventUnit = function()
            return nil
        end,
    },
    Internal = {
        Tasks = tasks,
        Comms = { Operations = {
            GetOpcode = function(_, key)
                return ({ AURA_APPLY = 17, AURA_DISPEL = 18, AURA_APPLY_BATCH = 20, AURA_DISPEL_BATCH = 21 })[key]
            end,
        } },
        Database = {
            Classes = {},
            GetDatasetByID = function(datasetId)
                return datasetId == auraDataset.id and auraDataset or nil
            end,
            GetActiveRuleset = function()
                return activeRuleset
            end,
        },
        Registry = {},
    },
    Utils = {
        Common = {
            Round = function(value)
                return math.floor(value + 0.5)
            end,
        },
        Dice = { RollVariance = function() return 1 end },
        Lookup = {
            GetStatValue = function(unit, statRef)
                return tonumber(unit and unit.stats and unit.stats[statRef]) or 0
            end,
            FindEventUnitById = function(units, eventId)
                for index = 1, #(units or {}) do
                    if tonumber(units[index].eventID) == tonumber(eventId) then
                        return units[index]
                    end
                end
                return nil
            end,
        },
    },
}

local function loadAddonFile(path)
    local chunk, loadError = loadfile(path)
    assert(chunk, loadError)
    return chunk(nil, Addon)
end

loadAddonFile("client/spellcasting/AuraManager.lua")
local AuraManager = Addon.Client.Spellcasting.AuraManager
AuraManager.QueueAuraApply = function()
    return true
end

caster = {
    eventID = 1,
    level = 17,
    name = "Caster",
    isPlayer = true,
    stats = { might = 5 },
    resources = {},
    mainHandWeapon = "ranktest:sword",
}
local target = {
    eventID = 2,
    resources = { { ref = "health", currentValue = 100, maxValue = 200 } },
}
eventState = {
    active = true,
    id = "rank-aura-event",
    turnNumber = 1,
    tickNumber = 1,
    units = { caster, target },
}

local function buildContext(multiplier)
    return {
        sessionState = { active = true, channelName = "ranktest", channelId = 1 },
        eventState = eventState,
        dataset = auraDataset,
        datasetId = auraDataset.id,
        casterUnit = caster,
        targetUnit = target,
        spellRankMultiplier = multiplier,
    }
end

loadAddonFile("client/spellcasting/effects/Aura.lua")
local dedicatedAuraEffect = AuraManager:GetEffect("apply_aura")
local applied, dedicatedResult = dedicatedAuraEffect.Execute(AuraManager, buildContext(1.2), {
    auraRef = "ranktest:ward",
    basePower = 20,
    stacks = 1,
    duration = 4,
})
assertEqual(applied, true, "dedicated Aura application succeeds")
local activeAura = dedicatedResult.auraEntry
assertEqual(activeAura.rankMultiplier, 1.2, "dedicated Aura snapshots spell rank")
assertEqual(activeAura.powerLevel, 20, "flat Aura power remains additive")

local scaledEffect = { baseAmount = 100, statScaling = { { statRef = "might", coefficient = 2 } } }
assertEqual(AuraManager:ResolveEffectAmount({ aura = activeAura, casterUnit = caster }, scaledEffect, "baseAmount"), 156,
    "base, power, and stat scaling are multiplied by rank")
assertEqual(AuraManager:ResolveEffectAmount({ aura = { powerLevel = 20, rankMultiplier = 1, stacks = 1 }, casterUnit = caster }, scaledEffect, "baseAmount"), 130,
    "rank one preserves additive amount")
activeAura.stacks = 2
assertEqual(AuraManager:ResolveEffectAmount({ aura = activeAura, casterUnit = caster }, scaledEffect, "baseAmount"), 312,
    "ranked amount is multiplied by stacks after scaling")
activeAura.stacks = 1

local percentageEffect = { amountMode = "base_percent", resourceRef = "health", baseAmount = 10, statScaling = {} }
assertEqual(AuraManager:ResolveEffectAmount({
    aura = { powerLevel = 0, rankMultiplier = 1.2, stacks = 2 },
    targetUnit = target,
}, percentageEffect, "baseAmount"), 48, "percentage conversion follows rank scaling and precedes stacks")

caster.level = 90
assertEqual(activeAura.rankMultiplier, 1.2, "level changes do not change an active Aura snapshot")
local refreshed, refreshedResult = dedicatedAuraEffect.Execute(AuraManager, buildContext(1.4), {
    auraRef = "ranktest:ward",
    basePower = 20,
    stacks = 1,
    duration = 4,
})
assertEqual(refreshed, true, "Aura refresh succeeds")
assertEqual(refreshedResult.auraEntry.rankMultiplier, 1.4, "refresh replaces the stored rank multiplier")

local legacyApplied, legacyEntry = AuraManager:UpsertAura(Addon.Client, {
    eventState = eventState,
    dataset = auraDataset,
    auraRef = "ranktest:legacy",
    casterEventId = caster.eventID,
    targetEventId = target.eventID,
    stacks = 1,
    turns = 4,
})
assertEqual(legacyApplied, true, "legacy Aura payload applies")
assertEqual(legacyEntry.rankMultiplier, 1, "missing legacy multiplier defaults to rank one")
local legacyWireApplied = AuraManager:HandleAuraApply(Addon.Client, {
    "ranktest",
    eventState.id,
    caster.eventID,
    target.eventID,
    "ranktest:legacy",
    1,
    4,
    0,
}, "Caster")
assertEqual(legacyWireApplied, true, "old single-apply packet remains valid")
assertEqual(legacyEntry.rankMultiplier, 1, "old single-apply packet defaults to rank one")

local previousRankAura = refreshedResult.auraEntry
local healingContext = buildContext(1.6)
healingContext.healthResourceRef = "health"
local healDefinition = loadAddonFile("client/combat/effects/Heal.lua")
local healEffect = {
    baseHealing = 1,
    statScaling = {},
    applyAura = true,
    auraRef = "ranktest:ward",
    auraStacks = 1,
}
local healed, healResult = healDefinition.Execute(healDefinition, healingContext, healEffect)
assertEqual(healed, true, "heal with embedded Aura applies")
assertEqual(healResult.auraEntry.rankMultiplier, 1.6, "heal Aura snapshots its spell rank")

loadAddonFile("client/combat/Reaction.lua")
local damageContext = buildContext(1.8)
local damageFinalized = combat:FinalizeLocalDamageResult({
    context = damageContext,
    eventState = eventState,
    attackerUnit = caster,
    defenderUnit = target,
    attackerEventId = caster.eventID,
    defenderEventId = target.eventID,
    effect = { applyAura = true, auraRef = "ranktest:ward", auraStacks = 1 },
}, { amount = 0, appliedDelta = 0, resourceDeltas = {} })
assertEqual(damageFinalized, true, "damage with embedded Aura finalizes")
local bucket = AuraManager:GetEventAuraBucket(Addon.Client, eventState.id, false)
local damageAura = bucket.byKey[previousRankAura.auraKey]
assertEqual(damageAura.rankMultiplier, 1.8, "damage Aura snapshots its spell rank")

loadAddonFile("core/internal/comms/EventRejoinState.lua")
local rejoin = Addon.Internal.Comms.EventRejoinState
local encoded = rejoin.SerializeSnapshot({
    auras = { damageAura },
    casts = {},
    meters = { currentTurn = 1, damage = {}, healing = {}, threat = {} },
})
local decoded, decodeError = rejoin.DeserializeSnapshot(encoded)
assert(decoded, decodeError)
assertEqual(decoded.auras[1].rankMultiplier, 1.8, "rejoin snapshots preserve Aura rank")

local function encodeFields(values)
    local parts = {}
    for index = 1, #values do
        local value = tostring(values[index] or "")
        parts[#parts + 1] = tostring(#value) .. ":" .. value
    end
    return table.concat(parts)
end

local function toHex(value)
    return (value:gsub(".", function(character)
        return ("%02x"):format(string.byte(character))
    end))
end

local emptyRecordList = encodeFields({ "0" })
local legacyAuraRuntime = encodeFields({ "0", "" })
local legacyAuraRecord = encodeFields({ caster.eventID, target.eventID, "ranktest:legacy", 1, 4, 0, legacyAuraRuntime })
local emptyMeterGroup = encodeFields({ emptyRecordList, emptyRecordList, emptyRecordList })
local legacyMeters = encodeFields({ 1, emptyMeterGroup })
local legacySnapshot = encodeFields({
    4,
    encodeFields({ "1", legacyAuraRecord }),
    emptyRecordList,
    legacyMeters,
})
local decodedLegacy, legacyDecodeError = rejoin.DeserializeSnapshot(toHex(legacySnapshot))
assert(decodedLegacy, legacyDecodeError)
assertEqual(decodedLegacy.auras[1].rankMultiplier, 1, "protocol four Aura snapshots default to rank one")

-- Autopilot uses the shared live rank resolver for direct values and carries
-- that same snapshot through Aura application and future-value projection.
Addon.Client.Spellcasting.AuraManager.ResolveAuraDefinition = function(_, auraRef)
    local auraId = tostring(auraRef):match("^[^:]+:(.+)$") or tostring(auraRef)
    for index = 1, #auraDataset.auras do
        if auraDataset.auras[index].id == auraId then
            return auraDataset, auraDataset.auras[index], "ranktest:" .. auraId
        end
    end
    return nil, nil, nil
end
loadAddonFile("client/autopilot/AuraEvaluator.lua")
loadAddonFile("client/autopilot/AuraEvaluatorPerformance.lua")
loadAddonFile("client/combat/Helpers.lua")
loadAddonFile("client/autopilot/SpellEvaluator.lua")
local AutoAura = Addon.Client.AutopilotAuraEvaluator
local AutoSpell = Addon.Client.AutopilotSpellEvaluator
local rankedSpell = {
    id = "ranked-spell",
    components = {
        {
            key = "damage",
            effect = {
                type = "damage",
                baseDamage = 10,
                damageType = "melee",
                weaponDamageMode = "main_hand",
                weaponDamageCoefficient = 2,
                statScaling = { { statRef = "might", coefficient = 2 } },
                applyAura = true,
                auraRef = "ranktest:ranked-dot",
                auraStacks = 2,
                duration = 3,
                basePower = 4,
            },
        },
        {
            key = "healing",
            effect = {
                type = "heal",
                baseHealing = 20,
                statScaling = { { statRef = "might", coefficient = 2 } },
                applyAura = true,
                auraRef = "ranktest:ranked-dot",
                auraStacks = 1,
                duration = 3,
                basePower = 4,
            },
        },
        {
            key = "dedicated-aura",
            effect = {
                type = "apply_aura",
                auraRef = "ranktest:ranked-dot",
                stacks = 1,
                duration = 3,
                basePower = 4,
            },
        },
        {
            key = "resource-unscaled",
            effect = { type = "resource", resourceRef = "mana", amount = 1, scaleWithRank = false },
        },
        {
            key = "resource-scaled",
            effect = { type = "resource", resourceRef = "mana", amount = 10, scaleWithRank = true },
        },
    },
}
spellRankResolverCalls = 0
local autopilotProfile = AutoSpell.BuildSpellProfile({
    canCast = true,
    spell = rankedSpell,
    spellRef = "ranktest:ranked-spell",
    casterUnit = caster,
    eventState = eventState,
    dataset = auraDataset,
}, {})
assertEqual(spellRankResolverCalls, 1, "autopilot uses shared rank resolver once per profile")
assertEqual(autopilotProfile.spellRank, 3, "autopilot profile exposes the resolved rank")
assertEqual(autopilotProfile.spellRankMultiplier, 1.2, "autopilot profile exposes the resolved multiplier")
assertEqual(autopilotProfile.immediateDamage, 60, "autopilot damage scales weapon and stat contributions")
assertEqual(autopilotProfile.immediateHealing, 36, "autopilot healing scales base and stat contributions")
assertEqual(#autopilotProfile.auraApplications, 3, "dedicated, damage, and healing Aura applications are collected")
assertEqual(autopilotProfile.auraApplications[1].powerLevel, 4, "Aura power remains additive")
assertEqual(autopilotProfile.auraApplications[1].rankMultiplier, 1.2, "Aura application carries source Spell rank")
assertEqual(autopilotProfile.auraApplications[3].rankMultiplier, 1.2, "dedicated Aura carries source Spell rank")
assertEqual(autopilotProfile.expectedResourceEffects[1].amount, 1,
    "Autopilot preserves authored amount for opted-out Resource effects")
assertEqual(autopilotProfile.expectedResourceEffects[2].amount, 12,
    "Autopilot uses live Resource resolver for opted-in effects")

rankedSpell.usesRanks = false
local unrankedAutopilotProfile = AutoSpell.BuildSpellProfile({
    canCast = true,
    spell = rankedSpell,
    spellRef = "ranktest:ranked-spell",
    casterUnit = caster,
    eventState = eventState,
    dataset = auraDataset,
}, {})
assertEqual(unrankedAutopilotProfile.spellRankMultiplier, 1, "Autopilot applies per-Spell rank opt-out")
assertEqual(unrankedAutopilotProfile.immediateDamage, 50, "unranked Autopilot damage matches Rank 1 value")
assertEqual(unrankedAutopilotProfile.immediateHealing, 30, "unranked Autopilot healing matches Rank 1 value")
assertEqual(unrankedAutopilotProfile.expectedResourceEffects[2].amount, 10,
    "unranked Spell keeps opted-in Resource effect at authored amount")
rankedSpell.usesRanks = true

local auraEffect = {
    type = "damage",
    baseDamage = 10,
    amountMode = "base_percent",
    resourceRef = "health",
    statScaling = { { statRef = "might", coefficient = 1 } },
}
assertEqual(AutoAura.ResolvePeriodicEffectMagnitude(caster, target, auraEffect, 5, 2, 1.2), 96,
    "Aura power and stat scale by rank before percentage conversion and stacks")

local copiedRankedAura = AutoAura.CopyAuraEntry({
    auraRef = "ranktest:ranked-dot",
    datasetId = "ranktest",
    casterEventId = caster.eventID,
    targetEventId = target.eventID,
    stacks = 2,
    turnsRemaining = 3,
    powerLevel = 5,
    rankMultiplier = 1.2,
}, { dataset = auraDataset })
assertEqual(copiedRankedAura.rankMultiplier, 1.2, "active Aura rank snapshot is copied")
caster.level = 90
assertEqual(copiedRankedAura.rankMultiplier, 1.2, "caster level changes do not rescale active Aura snapshot")
local projectedRankedAura = AutoAura.ProjectPeriodicAuraValue(copiedRankedAura, caster, target)
assertEqual(math.floor(projectedRankedAura.periodicDamage * 1000 + 0.5), 187392,
    "Autopilot future Aura value retains the applied rank snapshot")
local legacyCopiedAura = AutoAura.CopyAuraEntry({
    auraRef = "ranktest:ranked-dot",
    datasetId = "ranktest",
    casterEventId = caster.eventID,
    targetEventId = target.eventID,
    stacks = 1,
    turnsRemaining = 3,
}, { dataset = auraDataset })
assertEqual(legacyCopiedAura.rankMultiplier, 1, "legacy active Aura defaults to rank one")

local projectedLedger = AutoAura.CreateProjectedAuraLedger({ copiedRankedAura })
local refreshedApplication = autopilotProfile.auraApplications[1]
refreshedApplication.rankMultiplier = 1.4
local nextLedger, _, refreshedState = AutoAura.ReserveProjectedAura(
    projectedLedger,
    refreshedApplication,
    caster.eventID,
    target.eventID,
    { datasetId = "ranktest" }
)
assertEqual(refreshedState.rankMultiplier, 1.4, "higher-rank refresh replaces projected Aura snapshot")
assertEqual(AutoAura.GetProjectedAuraState(projectedLedger, {
    auraRef = "ranktest:ranked-dot",
    casterEventId = caster.eventID,
    targetEventId = target.eventID,
}).rankMultiplier, 1.2, "refresh leaves prior projected Aura branch unchanged")
assertEqual(AutoAura.GetProjectedAuraState(nextLedger, {
    auraRef = "ranktest:ranked-dot",
    casterEventId = caster.eventID,
    targetEventId = target.eventID,
}).rankMultiplier, 1.4, "performance ledger clone preserves refreshed Aura rank")

print("Spell rank Aura tests passed")
