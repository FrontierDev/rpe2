local function assertEqual(actual, expected, message)
    if actual ~= expected then
        error(("%s: expected %s, got %s"):format(message, tostring(expected), tostring(actual)), 2)
    end
end

local profileLevel = 1
local profileSpellbook = { "ranktest:manual" }
local spellbookWrites = 0
local activeRuleset = { rules = { character = {} } }
local registryDataset = { id = "ranktest", spells = {} }
local spellsByRef = {}
local runtimeEventState = nil
local runtimeCasterUnit = nil
local runtimeSessionState = { active = true, channelName = "ranktest" }
local Addon = {
    Client = {
        Spellcasting = {},
        UI = { Profile = {} },
        GetState = function()
            return runtimeSessionState
        end,
        GetEventState = function()
            return runtimeEventState
        end,
        GetSpellcastEntry = function()
            return nil
        end,
        ResolveSpellActivation = function(_, ref)
            local spell = spellsByRef[ref]
            if not spell or not runtimeEventState or not runtimeCasterUnit then
                return nil
            end
            return {
                sessionState = runtimeSessionState,
                eventState = runtimeEventState,
                casterUnit = runtimeCasterUnit,
                dataset = registryDataset,
                spell = spell,
                spellRef = ref,
                policy = { type = "caster", requiresTarget = false, maxTargets = 1 },
                targetGroups = {},
                targetUnit = runtimeCasterUnit,
            }
        end,
        Combat = {
            GetUnitLevel = function(_, unit, eventState)
                local level = tonumber(unit and (unit.level or unit.actorLevel or unit.effectiveLevel))
                    or tonumber(unit and unit.stats and unit.stats.level)
                if level ~= nil then
                    return math.max(1, math.floor(level))
                end
                if unit and unit.isPlayer == true then
                    return profileLevel
                end
                return math.max(1, math.floor(tonumber(eventState and eventState.level) or 1))
            end,
        },
    },
    Internal = {
        Database = {
            Classes = {},
            GetActiveRuleset = function()
                return activeRuleset
            end,
            GetProfileLevel = function()
                return profileLevel
            end,
            ListProfileSpellbook = function()
                local refs = {}
                for index = 1, #profileSpellbook do
                    refs[index] = profileSpellbook[index]
                end
                return refs
            end,
            AddProfileSpellbookSpell = function(ref)
                for index = 1, #profileSpellbook do
                    if profileSpellbook[index] == ref then
                        return false
                    end
                end
                profileSpellbook[#profileSpellbook + 1] = ref
                spellbookWrites = spellbookWrites + 1
                return true
            end,
            GetProfileMountRef = function()
                return nil
            end,
        },
        Profile = {
            GetLevel = function()
                return profileLevel
            end,
        },
        Ruleset = { Rules = {} },
        Comms = {},
        Registry = {
            GetActivatedDatasets = function()
                return { registryDataset }
            end,
            ResolveSpellReference = function(_, ref)
                if spellsByRef[ref] then
                    return registryDataset, spellsByRef[ref]
                end
                return nil, nil
            end,
            ResolveSpellName = function(_, ref)
                local spell = spellsByRef[ref]
                return spell and spell.name or ref
            end,
        },
    },
    Utils = { Common = {}, Lookup = {} },
}

local function loadAddonFile(path)
    local chunk, loadError = loadfile(path)
    assert(chunk, loadError)
    chunk(nil, Addon)
end

loadAddonFile("core/classes/Spell.lua")
loadAddonFile("core/internal/ruleset/Rules.lua")
loadAddonFile("core/internal/ruleset/Ruleset.lua")
loadAddonFile("client/spellcasting/Helpers.lua")

local Spell = Addon.Internal.Database.Classes.Spell
local Spellcasting = Addon.Client.Spellcasting
local spell = Spell:New({ learnLevel = 1, rankInterval = 8 })
local eventState = { active = true, level = 4 }

local player = Spellcasting.ResolveSpellRankContext(spell, {
    casterUnit = { isPlayer = true, level = 17 },
    eventState = eventState,
})
assertEqual(player.casterLevel, 17, "player event caster level")
assertEqual(player.rank, 3, "player event caster rank")
assertEqual(player.multiplier, 1.1, "player event caster multiplier uses the 5 percent default")

local function resolveAtLevel(testSpell, level)
    return Spellcasting.ResolveSpellRankContext(testSpell, {
        casterUnit = { isPlayer = false, level = level },
        eventState = eventState,
    })
end

local levelOneSpell = Spell:New({ learnLevel = 1, rankInterval = 8 })
local levelOneAtForty = resolveAtLevel(levelOneSpell, 40)
assertEqual(levelOneAtForty.rank, 5, "level-one Spell keeps its displayed Rank 5")
assertEqual(levelOneAtForty.multiplier, 1.2, "level-one Spell scaling Rank 5 multiplier")

local levelThirtySpell = Spell:New({ learnLevel = 30, rankInterval = 8 })
local levelThirtyAtThirty = resolveAtLevel(levelThirtySpell, 30)
assertEqual(levelThirtyAtThirty.rank, 1, "newly learned Spell displays Rank 1")
assertEqual(levelThirtyAtThirty.multiplier, 1.15, "newly learned level-thirty Spell starts at scaling Rank 4")
local levelThirtyAtForty = resolveAtLevel(levelThirtySpell, 40)
assertEqual(levelThirtyAtForty.rank, 2, "level-thirty Spell displays Rank 2 at level 40")
assertEqual(levelThirtyAtForty.nextRankLevel, 46, "next rank still follows displayed-rank progression")
assertEqual(levelThirtyAtForty.multiplier, 1.2, "level-thirty Spell matches level-one multiplier at level 40")

local levelTwentyFiveSpell = Spell:New({ learnLevel = 25, rankInterval = 6 })
local levelTwentyFiveAtTwentyFive = resolveAtLevel(levelTwentyFiveSpell, 25)
assertEqual(levelTwentyFiveAtTwentyFive.rank, 1, "level-twenty-five Spell displays Rank 1 on learn level")
assertEqual(levelTwentyFiveAtTwentyFive.multiplier, 1.2, "interval-aligned intercept gives scaling Rank 5")
local levelTwentyFiveAtThirtyOne = resolveAtLevel(levelTwentyFiveSpell, 31)
assertEqual(levelTwentyFiveAtThirtyOne.rank, 2, "interval boundary advances displayed rank")
assertEqual(levelTwentyFiveAtThirtyOne.nextRankLevel, 37, "interval boundary next rank remains display-based")
assertEqual(levelTwentyFiveAtThirtyOne.multiplier, 1.25, "interval boundary advances scaling rank once")

local unrankedSpell = Spell:New({ learnLevel = 1, rankInterval = 4, usesRanks = false })
local unrankedAtLevelOne = Spellcasting.ResolveSpellRankContext(unrankedSpell, {
    casterUnit = { isPlayer = false, level = 1 },
    eventState = eventState,
})
local unrankedAtLevelSixty = Spellcasting.ResolveSpellRankContext(unrankedSpell, {
    casterUnit = { isPlayer = false, level = 60 },
    eventState = eventState,
})
assertEqual(unrankedAtLevelOne.usesRanks, false, "rank context exposes Spell opt-out")
assertEqual(unrankedAtLevelOne.rank, 1, "unranked Spell uses compatibility Rank 1")
assertEqual(unrankedAtLevelOne.multiplier, 1, "unranked Spell multiplier at level 1")
assertEqual(unrankedAtLevelSixty.rank, 1, "unranked Spell stays at Rank 1 at level 60")
assertEqual(unrankedAtLevelSixty.multiplier, 1, "unranked Spell multiplier at level 60")
assertEqual(unrankedAtLevelSixty.nextRankLevel, nil, "unranked Spell has no next rank")
local unrankedWithOffset = Spellcasting.ResolveSpellRankContext(Spell:New({
    learnLevel = 25,
    rankInterval = 6,
    usesRanks = false,
}), {
    casterUnit = { isPlayer = false, level = 60 },
    eventState = eventState,
})
assertEqual(unrankedWithOffset.rank, 1, "unranked Spell keeps the compatibility display rank")
assertEqual(unrankedWithOffset.multiplier, 1, "unranked Spell does not apply its derived scaling offset")
local unrankedBelowLearnLevel = Spellcasting.ResolveSpellRankContext(Spell:New({
    learnLevel = 10,
    usesRanks = false,
}), {
    casterUnit = { isPlayer = false, level = 9 },
    eventState = eventState,
})
assertEqual(unrankedBelowLearnLevel.eligible, false, "unranked Spell still enforces learn level")
assertEqual(unrankedBelowLearnLevel.learnLevel, 10, "unranked Spell still reports learn level")

local npc = Spellcasting.ResolveSpellRankContext(spell, {
    casterUnit = { isPlayer = false, stats = { level = 25 } },
    eventState = eventState,
})
assertEqual(npc.casterLevel, 25, "NPC event caster level")
assertEqual(npc.rank, 4, "NPC event caster rank")

activeRuleset.rules.character.use_spell_ranks = false
local disabled = resolveAtLevel(levelThirtySpell, 40)
assertEqual(disabled.rank, 2, "disabled ranks retain displayed rank")
assertEqual(disabled.multiplier, 1, "disabled rank multiplier")
assertEqual(disabled.useSpellRanks, false, "disabled rank setting")

activeRuleset.rules.character.use_spell_ranks = true
activeRuleset.rules.character.spell_rank_effect_gain_percent = "25"
local customGain = Spellcasting.ResolveSpellRankContext(spell, {
    casterUnit = { isPlayer = false, level = 17 },
    eventState = eventState,
})
assertEqual(customGain.multiplier, 1.5, "custom linear percentage gain")

activeRuleset.rules.character.spell_rank_effect_gain_percent = "invalid"
local invalidGain = Spellcasting.ResolveSpellRankContext(spell, {
    casterUnit = { isPlayer = false, level = 17 },
    eventState = eventState,
})
assertEqual(invalidGain.multiplier, 1.1, "invalid percentage uses the configured default")

activeRuleset.rules.character.spell_rank_effect_gain_percent = "-25"
local negativeGain = Spellcasting.ResolveSpellRankContext(spell, {
    casterUnit = { isPlayer = false, level = 17 },
    eventState = eventState,
})
assertEqual(negativeGain.multiplier, 1, "negative percentage is normalized to zero")

local belowLearnLevel = Spellcasting.ResolveSpellRankContext(Spell:New({ learnLevel = 10 }), {
    casterUnit = { isPlayer = false, level = 9 },
    eventState = eventState,
})
assertEqual(belowLearnLevel.eligible, false, "level eligibility")
assertEqual(belowLearnLevel.rank, nil, "below-level result has no Rank 0")

profileLevel = 21
local profileFallback = Spellcasting.ResolveSpellRankContext(spell)
assertEqual(profileFallback.casterLevel, 21, "out-of-event Profile level fallback")
assertEqual(profileFallback.rank, 3, "out-of-event Profile rank")

local negativeAmount = Spellcasting.ApplySpellRankMultiplier({ spellRankMultiplier = 1.5 }, -20)
assertEqual(negativeAmount, -30, "multiplier preserves sign")
assertEqual(Spellcasting.ApplySpellRankMultiplier({}, 12), 12, "missing multiplier defaults to one")
assertEqual(Spellcasting.ApplySpellRankMultiplier({ spellRankMultiplier = math.huge }, 12), 12, "non-finite multiplier defaults to one")
assertEqual(Spellcasting.ApplySpellRankMultiplier({}, math.huge), nil, "non-finite amount is rejected")

local castSnapshot = {
    spellRank = customGain.rank,
    spellRankMultiplier = customGain.multiplier,
}
activeRuleset.rules.character.spell_rank_effect_gain_percent = "90"
profileLevel = 80
assertEqual(castSnapshot.spellRank, 3, "cast rank snapshot remains stable")
assertEqual(castSnapshot.spellRankMultiplier, 1.5, "cast multiplier snapshot remains stable")

local manualSpell = Spell:New({ id = "manual", name = "Manual Spell", learnMode = "book", learnLevel = 10 })
local alwaysLearnedSpell = Spell:New({ id = "always", name = "Always Spell", learnMode = "always_learned", learnLevel = 10 })
local bookSpell = Spell:New({ id = "book", name = "Book Spell", learnMode = "book", learnLevel = 10 })
registryDataset.spells = { manualSpell, alwaysLearnedSpell, bookSpell }
spellsByRef = {
    ["ranktest:manual"] = manualSpell,
    ["ranktest:always"] = alwaysLearnedSpell,
    ["ranktest:book"] = bookSpell,
}

loadAddonFile("core/internal/profile/Profile.lua")
loadAddonFile("client/spellcasting/Cooldowns.lua")
local Profile = Addon.Internal.Profile
profileLevel = 9
Addon.Internal.ConfigurationRevision = 1
local knownAtNine = Profile.ListKnownSpells({ lightweight = true })
local function findKnown(ref, rows)
    for index = 1, #rows do
        if rows[index].spellRef == ref then
            return rows[index]
        end
    end
    return nil
end

assertEqual(findKnown("ranktest:always", knownAtNine), nil, "below-level always-learned Spell is absent")
local preservedManual = findKnown("ranktest:manual", knownAtNine)
assertEqual(preservedManual ~= nil, true, "stored manual reference remains in spellbook")
assertEqual(preservedManual.isAvailable, false, "below-level manual reference is unavailable")
assertEqual(preservedManual.requiredLevel, 10, "below-level manual reference reports requirement")
assertEqual(Profile.AddKnownSpell("ranktest:book"), false, "book acquisition is rejected below learn level")
assertEqual(spellbookWrites, 0, "below-level acquisition does not write Profile spellbook")

profileLevel = 10
Addon.Internal.ConfigurationRevision = 2
local knownAtTen = Profile.ListKnownSpells({ lightweight = true })
assertEqual(findKnown("ranktest:always", knownAtTen) ~= nil, true, "always-learned Spell appears at learn level")
assertEqual(findKnown("ranktest:manual", knownAtTen).isAvailable, true, "stored manual Spell becomes available at learn level")
assertEqual(findKnown("ranktest:book", knownAtTen), nil, "book Spell is not added without acquisition")
assertEqual(spellbookWrites, 0, "level threshold does not write Profile spellbook")
assertEqual(Profile.AddKnownSpell("ranktest:book"), true, "book acquisition succeeds at learn level")
assertEqual(spellbookWrites, 1, "eligible acquisition writes once")

runtimeCasterUnit = { eventID = 1, isPlayer = false, level = 9, resources = {} }
runtimeEventState = {
    active = true,
    id = "ranktest-event",
    turnNumber = 1,
    tickNumber = 1,
    totalTicks = 1,
    units = { runtimeCasterUnit },
}
local belowLevelActivation = Spellcasting.BuildSpellActivationSnapshot(Addon.Client, "ranktest:always")
assertEqual(belowLevelActivation.canCast, false, "live activation rejects below-level cast")
assertEqual(belowLevelActivation.reason, "level-required", "live activation reports level requirement")

runtimeCasterUnit.level = 18
activeRuleset.rules.character.spell_rank_effect_gain_percent = "25"
Addon.Internal.ConfigurationRevision = 3
local activeCastSnapshot = Spellcasting.BuildSpellActivationSnapshot(Addon.Client, "ranktest:always")
assertEqual(activeCastSnapshot.canCast, true, "live activation accepts eligible cast")
assertEqual(activeCastSnapshot.spellRank, 2, "activation snapshot contains rank")
assertEqual(activeCastSnapshot.spellRankMultiplier, 1.5, "activation snapshot contains offset-adjusted multiplier")

local unrankedAlwaysLearned = Spell:New({
    id = "unranked",
    name = "Unranked Spell",
    learnMode = "always_learned",
    learnLevel = 1,
    usesRanks = false,
})
spellsByRef["ranktest:unranked"] = unrankedAlwaysLearned
registryDataset.spells[#registryDataset.spells + 1] = unrankedAlwaysLearned
Addon.Internal.ConfigurationRevision = 4
runtimeCasterUnit.level = 60
local unrankedActivation = Spellcasting.BuildSpellActivationSnapshot(Addon.Client, "ranktest:unranked")
assertEqual(unrankedActivation.canCast, true, "unranked Spell can be activated above learn level")
assertEqual(unrankedActivation.usesRanks, false, "activation snapshot preserves Spell rank opt-out")
assertEqual(unrankedActivation.spellRankMultiplier, 1, "unranked activation snapshots multiplier one")

runtimeCasterUnit.level = 26
activeRuleset.rules.character.spell_rank_effect_gain_percent = "90"
Addon.Internal.ConfigurationRevision = 5
assertEqual(activeCastSnapshot.spellRank, 2, "cast rank snapshot remains stable after state change")
assertEqual(activeCastSnapshot.spellRankMultiplier, 1.5, "cast multiplier snapshot remains stable after state change")

print("Spell rank runtime tests passed")
