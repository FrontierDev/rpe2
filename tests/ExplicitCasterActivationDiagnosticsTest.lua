local function assertEqual(actual, expected, message)
    if actual ~= expected then
        error(("%s: expected %s, got %s"):format(message, tostring(expected), tostring(actual)), 2)
    end
end

local function assertTrue(value, message)
    if value ~= true then error(message, 2) end
end

local function assertContains(value, expected, message)
    if type(value) ~= "string" or not string.find(value, expected, 1, true) then
        error(("%s: expected '%s' in '%s'"):format(message, expected, tostring(value)), 2)
    end
end

local function loadAddonFile(path, addon)
    local chunk, loadError = loadfile(path)
    assert(chunk, loadError)
    chunk("RPEngine2", addon)
end

local eventState
local onCasterTurn = true
local spells = {}
local npc

local Addon = {
    Client = {
        Spellcasting = {
            NormalizeTurnCount = function(value)
                local turns = tonumber(value)
                return turns and math.max(0, math.floor(turns)) or nil
            end,
            ResolveSpellCooldownChannel = function(spell)
                if spell.invalidChannel == true then
                    return nil, nil, nil, "invalid-cooldown-channel"
                end
                return 4, {
                    enabled = true,
                    name = "Global Action",
                    triggersGCD = spell.channelTriggersGCD == true,
                    canUseOffTurn = false,
                }
            end,
            ResolveSpellRankContext = function()
                return { eligible = true, multiplier = 1, usesRanks = false }
            end,
            IsCasterTurnOnTick = function()
                return onCasterTurn
            end,
            GetSpellResourceCostsForPhase = function(spell, phase)
                return spell.costs and spell.costs[phase] or {}
            end,
            CanAffordResourceCosts = function(unit)
                return unit.canAfford ~= false
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
                casterUnit = npc,
                spell = spell,
                spellRef = spellRef,
                policy = { type = "caster", requiresTarget = false, maxTargets = 1 },
                targetUnit = npc,
                targetGroups = {},
            }
        end,
    },
    Internal = { Database = { Classes = {} }, Ruleset = {}, Registry = {} },
}

Addon.Client.Conditions = {
    BuildContext = function(_, _, owner)
        return { owner = owner }
    end,
    EvaluateList = function(_, _, context)
        if context.owner and context.owner.conditionFailure then
            return { passed = false, failureText = context.owner.conditionFailure }
        end
        return { passed = true, failureText = "" }
    end,
}

npc = {
    eventID = 2,
    isPlayer = false,
    active = true,
    resources = {},
    spells = { "channel", "cooldown", "turn", "charges", "resources", "conditions", "invalid" },
}
eventState = {
    active = true,
    id = "explicit-activation-diagnostics",
    turnNumber = 1,
    tickNumber = 1,
    units = { npc },
}

local function spell()
    return { cooldown = 0, components = {} }
end

spells.channel = spell()
spells.channel.channelTriggersGCD = true
spells.cooldown = spell()
spells.turn = spell()
spells.charges = spell()
spells.charges.useCooldownCharges = true
spells.charges.charges = 2
spells.resources = spell()
spells.resources.costs = {
    on_cast_start = { { resourceRef = "mana", amount = 10 } },
}
spells.conditions = spell()
spells.conditions.conditionFailure = "Requires the Militant stance"
spells.conditions.conditions = { { type = "test" } }
spells.invalid = spell()
spells.invalid.invalidChannel = true

loadAddonFile("client/spellcasting/Cooldowns.lua", Addon)
loadAddonFile("client/spellcasting/ExplicitCasterActivation.lua", Addon)

local Spellcasting = Addon.Client.Spellcasting
local plannerProxy = setmetatable({}, { __index = Addon.Client })

local function assertFailed(ref, expectedReason)
    local snapshot = Spellcasting.BuildSpellActivationSnapshot(
        plannerProxy,
        ref,
        { casterEventId = npc.eventID }
    )
    assertTrue(type(snapshot) == "table", ref .. " returns a structured explicit-caster snapshot")
    assertEqual(snapshot.canCast, false, ref .. " is rejected")
    assertEqual(snapshot.reason, expectedReason, ref .. " preserves the canonical reason")
    return snapshot
end

local function resetState()
    Addon.Client.CooldownsByEventId = {}
    onCasterTurn = true
end

resetState()
Addon.Client.CooldownsByEventId[eventState.id] = {
    [npc.eventID] = { spells = {}, channelCooldowns = { [4] = 2 } },
}
local channel = assertFailed("channel", "channel-cooldown")
assertEqual(channel.channelCooldownRemaining, 2, "channel cooldown details are preserved")

resetState()
Addon.Client.CooldownsByEventId[eventState.id] = {
    [npc.eventID] = {
        spells = { cooldown = { remainingTurns = 2, lockoutRemainingTurns = 2 } },
        channelCooldowns = {},
    },
}
local cooldown = assertFailed("cooldown", "cooldown")
assertEqual(cooldown.cooldownRemaining, 2, "personal cooldown details are preserved")

resetState()
onCasterTurn = false
assertFailed("turn", "not-your-turn")

resetState()
Addon.Client.CooldownsByEventId[eventState.id] = {
    [npc.eventID] = {
        spells = { charges = { currentCharges = 0, maxCharges = 2, usesCharges = true } },
        channelCooldowns = {},
    },
}
local charges = assertFailed("charges", "no-charges")
assertEqual(charges.currentCharges, 0, "charge state is preserved")

resetState()
npc.canAfford = false
local resources = assertFailed("resources", "insufficient-resources")
assertEqual(resources.canAffordStartCosts, false, "resource affordability is preserved")
npc.canAfford = nil

resetState()
local conditions = assertFailed("conditions", "conditions")
assertEqual(conditions.conditionState.failureText, "Requires the Militant stance", "condition failure detail is preserved")

resetState()
assertFailed("invalid", "invalid-cooldown-channel")

Addon.Client.AutopilotPlanner = {}
Addon.Internal.Database.Classes.Event = {}
loadAddonFile("client/autopilot/PlannerIntegration.lua", Addon)
local Planner = Addon.Client.AutopilotPlanner
assertTrue(type(Planner.RecordPlannerRejection) == "function", "planner rejection recorder is available")

local plannerState = {
    scratch = {
        plannerRejectionsByEventId = {},
        spellDefinitionByRef = {
            channel = { name = "Channel Spell" },
            conditions = { name = "Condition Spell" },
        },
    },
}
Planner.RecordPlannerRejection(plannerState, npc.eventID, "channel", "channel-cooldown", channel)
Planner.RecordPlannerRejection(plannerState, npc.eventID, "conditions", "conditions", conditions)
local plannerDiagnostic = Planner.BuildNoActionDiagnostic(plannerState, npc, {})
assertContains(plannerDiagnostic, "cooldown channel is on cooldown", "planner preserves channel rejection text")
assertContains(plannerDiagnostic, "Requires the Militant stance", "planner preserves condition failure detail")
assertTrue(
    not string.find(plannerDiagnostic, "activation snapshot could not be built", 1, true),
    "canonical activation failures are not relabeled as unavailable"
)

print("ExplicitCasterActivationDiagnosticsTest passed")
