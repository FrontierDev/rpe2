local function assertEqual(actual, expected, message)
    if actual ~= expected then
        error(("%s: expected %s, got %s"):format(message, tostring(expected), tostring(actual)), 2)
    end
end

local Addon = {
    Internal = {
        Database = { Classes = {} },
        Ruleset = { Rules = {} },
    },
}

local spellChunk, spellLoadError = loadfile("core/classes/Spell.lua")
assert(spellChunk, spellLoadError)
spellChunk(nil, Addon)
local Spell = Addon.Internal.Database.Classes.Spell

local rulesChunk, rulesLoadError = loadfile("core/internal/ruleset/Rules.lua")
assert(rulesChunk, rulesLoadError)
rulesChunk(nil, Addon)

local function findRule(categoryKey, ruleKey)
    local definitions = Addon.Internal.Ruleset.Rules.Definitions
    for categoryIndex = 1, #definitions do
        local category = definitions[categoryIndex]
        if category.key == categoryKey then
            for ruleIndex = 1, #category.rules do
                local rule = category.rules[ruleIndex]
                if rule.key == ruleKey then
                    return rule
                end
            end
        end
    end
    return nil
end

local function assertRank(spell, level, eligible, rank, nextRankLevel)
    local result = Spell.ResolveRankForLevel(spell, level)
    assertEqual(result.eligible, eligible, ("eligibility at level %s"):format(tostring(level)))
    assertEqual(result.rank, rank, ("rank at level %s"):format(tostring(level)))
    assertEqual(result.nextRankLevel, nextRankLevel, ("next rank level at level %s"):format(tostring(level)))
end

local legacySpell = Spell:New({ name = "Legacy Spell" })
assertEqual(legacySpell.learnLevel, 1, "default learn level")
assertEqual(legacySpell.rankInterval, 8, "default rank interval")
assertEqual(legacySpell.usesRanks, true, "rank progression defaults on")
local legacyTable = legacySpell:ToTable()
assertEqual(legacyTable.learnLevel, 1, "serialized default learn level")
assertEqual(legacyTable.rankInterval, 8, "serialized default rank interval")
assertEqual(legacyTable.usesRanks, true, "serialized rank progression default")

local legacyImported = Spell.FromTable({ name = "Imported Legacy Spell" })
assertEqual(legacyImported.learnLevel, 1, "legacy import learn level")
assertEqual(legacyImported.rankInterval, 8, "legacy import rank interval")
assertEqual(legacyImported.usesRanks, true, "legacy imports remain ranked")

local roundTrip = Spell.FromTable(Spell:New({ learnLevel = 5, rankInterval = 4, usesRanks = false }):ToTable())
assertEqual(roundTrip.learnLevel, 5, "serialized learn level round trip")
assertEqual(roundTrip.rankInterval, 4, "serialized rank interval round trip")
assertEqual(roundTrip.usesRanks, false, "serialized rank opt-out round trip")

local invalidValues = { "invalid", 0, -1, 1.5, math.huge, -math.huge }
for index = 1, #invalidValues do
    local invalidValue = invalidValues[index]
    local invalidLearnLevel = Spell:New({ learnLevel = invalidValue })
    assertEqual(invalidLearnLevel.learnLevel, 1, "invalid learn level fallback " .. tostring(invalidValue))

    local invalidRankInterval = Spell:New({ rankInterval = invalidValue })
    assertEqual(invalidRankInterval.rankInterval, 8, "invalid rank interval fallback " .. tostring(invalidValue))
end

local rankOneSpell = Spell:New({ learnLevel = 1, rankInterval = 8 })
assertRank(rankOneSpell, 0, false, nil, nil)
assertRank(rankOneSpell, -1, false, nil, nil)
assertRank(rankOneSpell, 1, true, 1, 9)
assertRank(rankOneSpell, 8, true, 1, 9)
assertRank(rankOneSpell, 9, true, 2, 17)
assertRank(rankOneSpell, 16, true, 2, 17)
assertRank(rankOneSpell, 17, true, 3, 25)

local laterLearnSpell = Spell:New({ learnLevel = 5, rankInterval = 8 })
assertRank(laterLearnSpell, 4, false, nil, nil)
assertRank(laterLearnSpell, 5, true, 1, 13)
assertRank(laterLearnSpell, 12, true, 1, 13)
assertRank(laterLearnSpell, 13, true, 2, 21)
assertEqual(Spell.ResolveNextRankLevel(laterLearnSpell, 3), 37, "resolve next rank level")

local highLevel = Spell.ResolveRankForLevel(rankOneSpell, 1000000000)
assertEqual(highLevel.eligible, true, "high level eligibility")
assertEqual(highLevel.rank, 125000000, "rank has no cap")

local unrankedSpell = Spell:New({ learnLevel = 5, rankInterval = 8, usesRanks = false })
local unrankedAtLearnLevel = Spell.ResolveRankForLevel(unrankedSpell, 5)
assertEqual(unrankedAtLearnLevel.eligible, true, "unranked Spell remains eligible at its learn level")
assertEqual(unrankedAtLearnLevel.usesRanks, false, "unranked Spell exposes its opt-out")
assertEqual(unrankedAtLearnLevel.rank, 1, "unranked Spell keeps the compatibility Rank 1")
assertEqual(unrankedAtLearnLevel.nextRankLevel, nil, "unranked Spell has no next rank")
assertEqual(Spell.ResolveRankForLevel(unrankedSpell, 60).rank, 1, "unranked Spell remains at compatibility Rank 1")
assertEqual(Spell.ResolveNextRankLevel(unrankedSpell, 1), nil, "unranked next-rank query is empty")
local unrankedBelowLearnLevel = Spell.ResolveRankForLevel(unrankedSpell, 4)
assertEqual(unrankedBelowLearnLevel.eligible, false, "unranked Spell still enforces learn level")
assertEqual(unrankedBelowLearnLevel.learnLevel, 5, "unranked Spell retains its learn level")

local legacyResourceSpell = Spell.FromTable({ components = {
    { effect = { type = "resource", resourceRef = "mana", amount = 10 } },
} })
assertEqual(legacyResourceSpell.components[1].effect.scaleWithRank, false, "legacy Resource effects default to unscaled")
local scaledResourceSpell = Spell.FromTable({ components = {
    { effect = { type = "resource", resourceRef = "mana", amount = 10, scaleWithRank = true } },
} })
assertEqual(scaledResourceSpell.components[1].effect.scaleWithRank, true, "Resource opt-in normalizes")
assertEqual(Spell.FromTable(scaledResourceSpell:ToTable()).components[1].effect.scaleWithRank, true,
    "Resource opt-in serializes")

local useSpellRanksRule = findRule("character", "use_spell_ranks")
assertEqual(useSpellRanksRule ~= nil, true, "Use Spell Ranks rule exists")
assertEqual(useSpellRanksRule.label, "Use Spell Ranks", "Use Spell Ranks label")
assertEqual(useSpellRanksRule.type, "checkbox", "Use Spell Ranks control type")
assertEqual(useSpellRanksRule.default, true, "Use Spell Ranks default")

local rankGainRule = findRule("character", "spell_rank_effect_gain_percent")
assertEqual(rankGainRule ~= nil, true, "Spell Rank Effect Gain rule exists")
assertEqual(rankGainRule.label, "Spell Rank Effect Gain (%)", "Spell Rank Effect Gain label")
assertEqual(rankGainRule.type, "text", "Spell Rank Effect Gain control type")
assertEqual(rankGainRule.default, "10", "Spell Rank Effect Gain default")

local alternateResourceEffect
local EffectAddon = {
    Client = {
        Combat = {},
        Spellcasting = {
            ApplySpellRankMultiplier = function(context, amount)
                local multiplier = tonumber(context and context.spellRankMultiplier) or 1
                return amount * multiplier
            end,
            AuraManager = {
                RegisterEffect = function(_, definition)
                    alternateResourceEffect = definition
                end,
            },
        },
    },
    Internal = { Profile = {} },
    Utils = {
        Common = {
            Round = function(value)
                return math.floor((tonumber(value) or 0) + 0.5)
            end,
        },
        Dice = {
            RollVariance = function(context)
                return tonumber(context and context.variance) or 1
            end,
        },
        Lookup = {
            GetStatValue = function(unit, statRef, defaultValue)
                return tonumber(unit and unit.stats and unit.stats[statRef]) or defaultValue or 0
            end,
            GetResourceEntry = function(unit, resourceRef)
                for index = 1, #(unit and unit.resources or {}) do
                    local entry = unit.resources[index]
                    if entry.resourceRef == resourceRef then
                        return entry
                    end
                end
                return nil
            end,
        },
    },
}

local EffectCombat = EffectAddon.Client.Combat

local function loadEffectFile(path)
    local chunk, loadError = loadfile(path)
    assert(chunk, loadError)
    chunk(nil, EffectAddon)
end

loadEffectFile("client/combat/Helpers.lua")
function EffectCombat:CreateEffectContract(definition)
    return definition
end
function EffectCombat:ApplyResourceDelta(_, resourceRef, amount)
    local entry = { resourceRef = resourceRef, currentValue = amount, maxValue = 100 }
    return true, entry, amount
end
loadEffectFile("client/combat/effects/Damage.lua")
loadEffectFile("client/combat/effects/Heal.lua")
loadEffectFile("client/combat/effects/Resource.lua")
loadEffectFile("client/spellcasting/effects/Resource.lua")

local damageEffect = {
    baseDamage = 50,
    weaponDamageCoefficient = 1.5,
    statScaling = { { statRef = "power", coefficient = 2 } },
}
local damageContext = {
    casterUnit = { stats = { power = 10 } },
    hitResolutionContext = {
        weaponContext = { totalDamage = 20, weaponDamageCoefficient = 1.5 },
    },
    spellRankMultiplier = 1.2,
}
assertEqual(EffectCombat:ResolveDamageAmount(damageContext, damageEffect), 120, "Rank 3 scales base, weapon, and stat damage")
assertEqual(EffectCombat:ResolveDamageAmount({ hitResolutionContext = damageContext.hitResolutionContext }, damageEffect), 100, "Rank 1 damage baseline")
assertEqual(EffectCombat:ResolveDamageAmount({ spellRankMultiplier = 1.2, variance = 1 }, { baseDamage = 100 }), 120, "Ranked raw damage")

local healingEffect = {
    baseHealing = 50,
    statScaling = { { statRef = "power", coefficient = 5 } },
}
local healingContext = { casterUnit = { stats = { power = 10 } }, spellRankMultiplier = 1.2 }
assertEqual(EffectCombat:ResolveHealingAmount(healingContext, healingEffect), 120, "Rank 3 scales base and stat healing")
assertEqual(EffectCombat:ResolveHealingAmount({ casterUnit = healingContext.casterUnit }, healingEffect), 100, "Rank 1 healing baseline")
assertEqual(EffectCombat:ResolveHealingAmount({ spellRankMultiplier = 1.2 }, { baseHealing = 100 }), 120, "Ranked raw healing")

local resourceTarget = { resources = { { resourceRef = "mana", currentValue = 50, maxValue = 100 } } }
local positiveResourceEffect = { resourceRef = "mana", amount = 50, scaleWithRank = false }
local negativeResourceEffect = { resourceRef = "mana", amount = -50, scaleWithRank = true }
local scaledPositiveResourceEffect = { resourceRef = "mana", amount = 50, scaleWithRank = true }
assertEqual(EffectCombat:ResolveResourceEffectAmount({ targetUnit = resourceTarget, spellRankMultiplier = 1.1 }, positiveResourceEffect), 50,
    "direct Resource effect defaults to authored magnitude")
assertEqual(EffectCombat:ResolveResourceEffectAmount({ targetUnit = resourceTarget, spellRankMultiplier = 1.1 }, scaledPositiveResourceEffect), 55,
    "Rank 2 opted-in resource gain")
assertEqual(EffectCombat:ResolveResourceEffectAmount({ targetUnit = resourceTarget, spellRankMultiplier = 1.1 }, negativeResourceEffect), -55,
    "Rank 2 opted-in resource loss")
assertEqual(EffectCombat:ResolveResourceEffectAmount({ targetUnit = resourceTarget }, scaledPositiveResourceEffect), 50,
    "unranked opt-in Resource effect keeps authored magnitude")
assertEqual(EffectCombat:ResolveResourceEffectAmount({ targetUnit = resourceTarget, spellRankMultiplier = 1 }, scaledPositiveResourceEffect), 50,
    "Rank 1 Resource baseline")

local percentageEffect = { resourceRef = "mana", amount = 10, amountMode = "base_percent", scaleWithRank = true }
local unscaledPercentageEffect = { resourceRef = "mana", amount = 10, amountMode = "base_percent", scaleWithRank = false }
assertEqual(EffectCombat:ResolveResourceEffectAmount({ targetUnit = resourceTarget, spellRankMultiplier = 1.1 }, percentageEffect), 11,
    "opted-in percentage Resource effect scales once")
assertEqual(EffectCombat:ResolveResourceEffectAmount({ targetUnit = resourceTarget, spellRankMultiplier = 1.7 }, unscaledPercentageEffect), 10,
    "opted-out percentage Resource effect retains authored percentage")
local _, directResourceResult = EffectCombat:ExecuteResourceEffect({ targetUnit = resourceTarget, spellRankMultiplier = 1.1 }, scaledPositiveResourceEffect)
assertEqual(directResourceResult.amount, 55, "direct Resource execution applies opt-in rank once")
local _, auraResourceResult = alternateResourceEffect.Execute(alternateResourceEffect, {
    targetUnit = resourceTarget,
    aura = { rankMultiplier = 1.1 },
}, positiveResourceEffect)
assertEqual(auraResourceResult.amount, 55, "Aura Resource effect keeps source Aura rank propagation")
local resourceContract = loadEffectFile("client/combat/effects/Resource.lua")
assertEqual(resourceContract.defaults.scaleWithRank, false, "Resource contract defaults rank scaling off")

local authoredSpell = {
    resourceCosts = { { resourceRef = "mana", amount = 30 } },
    cooldown = 60,
    castTime = 4,
    range = 20,
    auraDuration = 8,
    auraStacks = 3,
}
EffectCombat:ResolveDamageAmount(damageContext, damageEffect)
EffectCombat:ResolveHealingAmount(healingContext, healingEffect)
EffectCombat:ResolveResourceEffectAmount({ targetUnit = resourceTarget, spellRankMultiplier = 1.2 }, percentageEffect)
assertEqual(damageEffect.baseDamage, 50, "Authored damage is immutable")
assertEqual(healingEffect.baseHealing, 50, "Authored healing is immutable")
assertEqual(percentageEffect.amount, 10, "Authored resource amount is immutable")
assertEqual(authoredSpell.resourceCosts[1].amount, 30, "Resource cost is not rank scaled")
assertEqual(authoredSpell.cooldown, 60, "Cooldown is unchanged")
assertEqual(authoredSpell.castTime, 4, "Cast time is unchanged")
assertEqual(authoredSpell.range, 20, "Range is unchanged")
assertEqual(authoredSpell.auraDuration, 8, "Aura duration is unchanged")
assertEqual(authoredSpell.auraStacks, 3, "Aura stacks are unchanged")

print("Spell rank tests passed")
