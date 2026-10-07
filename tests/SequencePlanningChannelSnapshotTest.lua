local function assertEqual(actual, expected, message)
    if actual ~= expected then
        error(("%s: expected %s, got %s"):format(message, tostring(expected), tostring(actual)), 2)
    end
end

local function assertTrue(value, message)
    if value ~= true then error(message, 2) end
end

local function loadAddonFile(path, addon)
    local chunk, loadError = loadfile(path)
    assert(chunk, loadError)
    chunk("RPEngine2", addon)
end

local eventState = { active = true, id = "sequence-channel-snapshot", units = {} }
local caster = { eventID = 1, isPlayer = false, active = true, resources = {} }
local spells = {
    free = { cooldown = 0, components = {}, cooldownChannel = 4 },
    reaction = { cooldown = 0, components = {}, cooldownChannel = 5 },
    invalid = { cooldown = 0, components = {}, invalidChannel = true },
}
eventState.units = { caster }

local resolverCalls = 0
local channels = {
    [4] = { enabled = true, name = "Free Action", triggersGCD = false, canUseOffTurn = false },
    [5] = { enabled = true, name = "Reaction", triggersGCD = true, canUseOffTurn = true },
}

local Addon = {
    Client = {
        Spellcasting = {
            NormalizeTurnCount = function(value)
                local turns = tonumber(value)
                return turns and math.max(0, math.floor(turns)) or nil
            end,
            ResolvePersistentCastTurns = function()
                return nil
            end,
            ResolveSpellCooldownChannel = function(spell)
                resolverCalls = resolverCalls + 1
                if spell.invalidChannel == true then
                    return nil, nil, nil, "invalid-cooldown-channel"
                end
                local channel = channels[spell.cooldownChannel]
                return spell.cooldownChannel, channel
            end,
            ResolveSpellRankContext = function()
                return { eligible = true, multiplier = 1, usesRanks = false }
            end,
            IsCasterTurnOnTick = function()
                return true
            end,
            GetSpellResourceCostsForPhase = function()
                return {}
            end,
            CanAffordResourceCosts = function()
                return true
            end,
            ResolveSpellResourceCostAmount = function()
                return 0
            end,
        },
        AutopilotSpellEvaluator = {
            CompareCandidates = function()
                return 0
            end,
        },
        GetState = function()
            return { active = true }
        end,
        GetEventState = function()
            return eventState
        end,
        GetSpellcastEntry = function()
            return nil
        end,
        ResolveSpellActivation = function(_, spellRef)
            local spell = spells[spellRef]
            if not spell then return nil end
            return {
                sessionState = { active = true },
                eventState = eventState,
                casterUnit = caster,
                spell = spell,
                spellRef = spellRef,
                policy = { type = "caster", requiresTarget = false, maxTargets = 1 },
                targetUnit = caster,
                targetGroups = {},
            }
        end,
    },
    Internal = { Database = { Classes = {} }, Ruleset = {}, Registry = {} },
}

loadAddonFile("client/spellcasting/Cooldowns.lua", Addon)
loadAddonFile("client/autopilot/ActionEconomy.lua", Addon)
loadAddonFile("client/autopilot/SequencePlanning.lua", Addon)

local Spellcasting = Addon.Client.Spellcasting
local plannerProxy = setmetatable({}, { __index = Addon.Client })
local snapshots = {}
for _, spellRef in ipairs({ "free", "reaction", "invalid" }) do
    snapshots[spellRef] = Spellcasting.BuildSpellActivationSnapshot(plannerProxy, spellRef, {
        casterEventId = caster.eventID,
    })
end

assertEqual(snapshots.free.cooldownChannelId, 4, "Free Action channel ID is captured")
assertEqual(snapshots.free.cooldownChannelTriggersGCD, false, "Free Action GCD behavior is captured")
assertEqual(snapshots.free.cooldownChannelCanUseOffTurn, false, "Free Action turn behavior is captured")
assertEqual(snapshots.reaction.cooldownChannelId, 5, "Reaction channel ID is captured")
assertEqual(snapshots.reaction.cooldownChannelTriggersGCD, true, "Reaction GCD behavior is captured")
assertEqual(snapshots.reaction.cooldownChannelCanUseOffTurn, true, "Reaction turn behavior is captured")
assertEqual(snapshots.invalid.reason, "invalid-cooldown-channel", "invalid channel is rejected canonically")
assertEqual(snapshots.invalid.cooldownChannelReason, "invalid-cooldown-channel", "invalid channel reason is canonical")

local callsBeforePlanning = resolverCalls
Spellcasting.ResolveSpellCooldownChannel = function()
    error("planner must not resolve cooldown channels after snapshot creation")
end

local function candidate(spellRef)
    return {
        spellRef = spellRef,
        totalUtility = 1,
        activationSnapshot = snapshots[spellRef],
    }
end

local sequence = Addon.Client.AutopilotSequencePlanning.BuildSequence({
    candidate("free"),
    candidate("reaction"),
}, caster)

assertEqual(resolverCalls, callsBeforePlanning, "planner reuses captured channel metadata")
assertEqual(sequence.status, "ready", "captured channels remain legal after resolver changes")
assertEqual(#sequence.actions, 2, "Free Action and Reaction can both be selected")

local actionsByRef = {}
for _, action in ipairs(sequence.actions) do
    actionsByRef[action.spellRef] = action
end
assertEqual(actionsByRef.free.cooldownChannelId, 4, "Free Action ID reaches action economy")
assertEqual(actionsByRef.free.actionClass, "action", "Free Action keeps its action classification")
assertEqual(actionsByRef.free.cooldownChannelTriggersGCD, false, "Free Action remains non-GCD")
assertEqual(actionsByRef.free.cooldownChannelCanUseOffTurn, false, "Free Action remains on-turn")
assertEqual(actionsByRef.reaction.cooldownChannelId, 5, "Reaction ID reaches action economy")
assertEqual(actionsByRef.reaction.actionClass, "action", "Reaction keeps its action classification")
assertEqual(actionsByRef.reaction.cooldownChannelTriggersGCD, true, "Reaction remains GCD-triggering")
assertEqual(actionsByRef.reaction.cooldownChannelCanUseOffTurn, true, "Reaction remains off-turn legal")

local function copySnapshot(snapshot)
    local copied = {}
    for key, value in pairs(snapshot) do
        copied[key] = value
    end
    return copied
end

local optionalMetadataSnapshot = copySnapshot(snapshots.free)
optionalMetadataSnapshot.cooldownChannelName = nil
optionalMetadataSnapshot.cooldownChannelConfigured = nil
optionalMetadataSnapshot.cooldownChannelCanUseOffTurn = nil
optionalMetadataSnapshot.cooldownChannelReason = nil
local optionalMetadataSequence = Addon.Client.AutopilotSequencePlanning.BuildSequence({
    {
        spellRef = "free",
        totalUtility = 1,
        activationSnapshot = optionalMetadataSnapshot,
    },
}, caster)
assertEqual(#optionalMetadataSequence.actions, 1, "optional channel metadata does not reject a legal activation")

local malformedSnapshot = copySnapshot(snapshots.free)
malformedSnapshot.cooldownChannelId = nil
local malformedSequence = Addon.Client.AutopilotSequencePlanning.BuildSequence({
    {
        spellRef = "free",
        totalUtility = 1,
        activationSnapshot = malformedSnapshot,
    },
}, caster)
assertEqual(#malformedSequence.actions, 0, "legal activation without channel ID is not planned")
assertEqual(
    malformedSequence.rejected[1].reason,
    "activation-action-economy-metadata-missing",
    "missing action-economy metadata has an internal invariant reason"
)

local invalidSequence = Addon.Client.AutopilotSequencePlanning.BuildSequence({ candidate("invalid") }, caster)
assertEqual(#invalidSequence.actions, 0, "canonical invalid snapshot is not planned")
assertEqual(#invalidSequence.rejected, 1, "canonical invalid snapshot is rejected")
assertEqual(invalidSequence.rejected[1].reason, "illegal-activation", "invalid activation is rejected by sequence planning")
assertTrue(resolverCalls == callsBeforePlanning, "invalid snapshot does not trigger another resolver call")

print("SequencePlanningChannelSnapshotTest passed")
