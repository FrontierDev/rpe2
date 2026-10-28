local function assertEqual(actual, expected, message)
    if type(actual) == "number" and type(expected) == "number" and math.abs(actual - expected) < 0.000001 then
        return
    end
    if actual ~= expected then
        error(("%s: expected %s, got %s"):format(message, tostring(expected), tostring(actual)), 2)
    end
end

local function assertTrue(value, message)
    if value ~= true then
        error(message, 2)
    end
end

local TestSupport = dofile("tests/support/RuntimeStubs.lua")
local Addon = TestSupport.CreateAddon({
    Client = {
        Combat = {},
        Spellcasting = {
            ApplySpellRankMultiplier = function(context, amount)
                return amount * (tonumber(context and context.spellRankMultiplier) or 1)
            end,
            GetHealthResourceRef = function()
                return "f82db71a:health"
            end,
            GetLocalPlayerName = function()
                return "Alice"
            end,
            GetUnitPageIndex = function()
                return 1
            end,
            NormalizeName = function(value)
                return tostring(value or "")
            end,
        },
    },
    Debug = {
        Internal = function() end,
    },
    Internal = {
        Comms = {
            Operations = {
                GetOpcode = function()
                    return nil
                end,
            },
        },
        Profile = {
            GetResolvedBaseResourceValue = function(resourceRef)
                if resourceRef == "f82db71a:4c8mfm99" then
                    return 400
                end
                return 0
            end,
        },
        Registry = {},
    },
    Utils = {
        Common = {
            Round = function(value)
                return math.floor((tonumber(value) or 0) + 0.5)
            end,
        },
        Lookup = {
            GetResourceEntry = function(unit, resourceRef)
                for index = 1, #(unit and unit.resources or {}) do
                    local entry = unit.resources[index]
                    if type(entry) == "table" and entry.resourceRef == resourceRef then
                        return entry
                    end
                end
                return nil
            end,
            GetStatValue = function(unit, statRef, defaultValue)
                return tonumber(unit and unit.stats and unit.stats[statRef]) or defaultValue or 0
            end,
        },
    },
})

local definitions = TestSupport.LoadPackagedDefaultData(Addon)
Addon.Internal.Database.GetDatasetByID = function(datasetId)
    local definition = definitions[tostring(datasetId)]
    return definition and definition.dataset or nil
end

TestSupport.LoadAddonFile("core/classes/Aura.lua", Addon)
TestSupport.LoadAddonFile("client/combat/Normalization.lua", Addon)
TestSupport.LoadAddonFile("client/combat/Helpers.lua", Addon)
TestSupport.LoadAddonFile("client/spellcasting/AuraManager.lua", Addon)
TestSupport.LoadAddonFile("client/spellcasting/effects/Heal.lua", Addon)
TestSupport.LoadAddonFile("client/spellcasting/effects/Resource.lua", Addon)

local Client = Addon.Client
local AuraManager = Client.Spellcasting.AuraManager
local Combat = Client.Combat
local healthRef = "f82db71a:health"
local manaRef = "f82db71a:4c8mfm99"
local paladinDataset = definitions.b0211ab3.dataset

local casterAutoAttackHooks = Combat:FilterHookEventIds(
    { "on_auto_attack_hit", "on_auto_attack_taken" },
    { role = "caster", effectType = "damage", hitType = "auto" }
)
assertEqual(#casterAutoAttackHooks, 1, "successful basic attack emits only the caster hit hook")
assertEqual(casterAutoAttackHooks[1], "on_auto_attack_hit", "successful basic attack emits hit hook")
assertEqual(#Combat:FilterHookEventIds({ "on_auto_attack_hit" }, {
    role = "caster",
    effectType = "damage",
    hitType = "spell",
}), 0, "non-basic attacks do not emit the basic attack hit hook")
assertEqual(#Combat:FilterHookEventIds({ "on_auto_attack_hit" }, {
    role = "caster",
    effectType = "damage",
    hitType = "miss",
    outcome = "miss",
}), 0, "missed attacks do not emit the basic attack hit hook")

function Client:ResolveLocalEventUnit()
    return self.testLocalUnit
end

function Client:GetState()
    return { active = true }
end

function Client:QueueClientResourceDeltas(_, _, deltas, targetEventId)
    self.queuedDeltas = self.queuedDeltas or {}
    self.queuedDeltas[#self.queuedDeltas + 1] = {
        deltas = deltas,
        targetEventId = targetEventId,
    }
end

function Client:MarkEventUnitInteraction()
end

Client.Spellcasting.ShowLocalResourceDeltaCombatText = function()
end

local function findAura(id)
    for index = 1, #(paladinDataset.auras or {}) do
        if paladinDataset.auras[index].id == id then
            return paladinDataset.auras[index]
        end
    end
    error("missing Paladin Aura " .. tostring(id), 2)
end

local function findSpell(id)
    for index = 1, #(paladinDataset.spells or {}) do
        if paladinDataset.spells[index].id == id then
            return paladinDataset.spells[index]
        end
    end
    error("missing Paladin spell " .. tostring(id), 2)
end

local function firstAuraEffect(aura)
    return aura.events[1].effects[1]
end

local sealOfLight = findAura("gw8r1b8l")
local sealOfWisdom = findAura("zwad020u")
local judgementOfLight = findAura("3m31fk9l")
local judgementOfWise = findAura("1q22o5fg")

assertEqual(firstAuraEffect(sealOfLight).scaleWithRank, false, "Seal of Light disables Aura rank scaling")
assertEqual(firstAuraEffect(sealOfLight).statScaling[1].statRef, "f82db71a:hj6d4kvy", "Seal of Light scales with Healing Power")
assertEqual(firstAuraEffect(sealOfLight).statScaling[1].coefficient, 0.1, "Seal of Light Healing Power coefficient")
assertEqual(firstAuraEffect(sealOfWisdom).scaleWithRank, false, "Seal of Wisdom disables Aura rank scaling")
assertEqual(firstAuraEffect(sealOfWisdom).statScaling[1].statRef, "f82db71a:u7b49vs9", "Seal of Wisdom scales with Spell Power")
assertEqual(firstAuraEffect(sealOfWisdom).statScaling[1].coefficient, 0.01, "Seal of Wisdom Spell Power coefficient")
assertEqual(firstAuraEffect(judgementOfLight).scaleWithRank, false, "Judgement of Light disables Aura rank scaling")
assertEqual(firstAuraEffect(judgementOfWise).scaleWithRank, false, "Judgement of the Wise disables Aura rank scaling")
assertEqual(sealOfLight.events[1].triggerTarget, "aura_caster", "Seal of Light heals its wearer")
assertEqual(sealOfWisdom.events[1].triggerTarget, "aura_caster", "Seal of Wisdom restores its wearer")
assertEqual(judgementOfLight.events[1].triggerTarget, "event_source", "Judgement of Light heals the attacker")
assertEqual(judgementOfWise.events[1].triggerTarget, "event_source", "Judgement of the Wise restores the attacker")

local judgementOfWisdom = findSpell("j1my2871")
local judgementDirectResource
for index = 1, #(judgementOfWisdom.components or {}) do
    local component = judgementOfWisdom.components[index]
    if component.effect and component.effect.type == "resource" then
        judgementDirectResource = component.effect
        break
    end
end
assertEqual(judgementDirectResource.amount, 10, "Judgement of Wisdom restores 10% base mana")
assertEqual(judgementDirectResource.amountMode, "base_percent", "Judgement of Wisdom uses base mana")
assertEqual(judgementDirectResource.statScaling[1].statRef, "f82db71a:u7b49vs9", "Judgement of Wisdom scales with Spell Power")
assertEqual(judgementDirectResource.statScaling[1].coefficient, 0.01, "Judgement of Wisdom Spell Power coefficient")
assertTrue(string.find(judgementOfWisdom.tooltipTemplateData.mainText, "{RESOURCE_1}", 1, true) ~= nil,
    "Judgement of Wisdom tooltip uses a dynamic resource token")
assertEqual(#sealOfLight.tooltipTemplateData.bodyTokens, 1, "Seal of Light Aura tooltip uses an amount token")
assertEqual(#sealOfWisdom.tooltipTemplateData.bodyTokens, 1, "Seal of Wisdom Aura tooltip uses an amount token")

local function newUnit(eventID, name, healthCurrent, healthMax, manaCurrent, manaMax)
    return {
        active = true,
        eventID = eventID,
        isPlayer = true,
        name = name,
        resources = {
            { resourceRef = manaRef, currentValue = manaCurrent, maxValue = manaMax },
            { resourceRef = healthRef, currentValue = healthCurrent, maxValue = healthMax },
        },
        stats = {
            ["f82db71a:hj6d4kvy"] = 10,
            ["f82db71a:u7b49vs9"] = 20,
        },
    }
end

local function executeAuraEffect(aura, targetUnit, casterUnit, eventState, rankMultiplier)
    local effect = firstAuraEffect(aura)
    local contract = AuraManager:GetEffect(effect.type)
    assertTrue(contract ~= nil, "registered contract exists for " .. tostring(effect.type))
    return contract.Execute(AuraManager, {
        client = Client,
        eventState = eventState,
        aura = {
            auraRef = "b0211ab3:" .. aura.id,
            rankMultiplier = rankMultiplier or 1.8,
            stacks = 1,
        },
        casterUnit = casterUnit,
        targetUnit = targetUnit,
        healthResourceRef = healthRef,
    }, effect)
end

local paladin = newUnit(1, "Alice", 900, 1000, 400, 2000)
local enemy = newUnit(2, "Enemy", 900, 1000, 400, 2000)
local eventState = {
    active = true,
    healthResourceRef = healthRef,
    id = "paladin-aura-procs",
    units = { paladin, enemy },
}
Client.testLocalUnit = paladin

local applied, sealLightResult = executeAuraEffect(sealOfLight, paladin, paladin, eventState)
assertTrue(applied, "Seal of Light applies a heal")
assertEqual(sealLightResult.amount, 40, "Seal of Light uses wearer max health and Healing Power without rank scaling")
assertEqual(sealLightResult.resourceDeltas[1].resourceRef, healthRef, "Seal of Light targets health")
assertEqual(paladin.resources[2].currentValue, 940, "Seal of Light heals the wearer")

local _, sealWisdomResult = executeAuraEffect(sealOfWisdom, paladin, paladin, eventState)
assertEqual(sealWisdomResult.amount, 64, "Seal of Wisdom uses wearer max mana and Spell Power without rank scaling")
assertEqual(sealWisdomResult.resourceDeltas[1].resourceRef, manaRef, "Seal of Wisdom targets mana")
assertEqual(paladin.resources[1].currentValue, 464, "Seal of Wisdom restores the wearer")

local _, judgementLightResult = executeAuraEffect(judgementOfLight, paladin, enemy, eventState)
assertEqual(judgementLightResult.amount, 20, "Judgement of Light uses attacker max health")
assertEqual(paladin.resources[2].currentValue, 960, "Judgement of Light heals the attacker")

local _, judgementWiseResult = executeAuraEffect(judgementOfWise, paladin, enemy, eventState)
assertEqual(judgementWiseResult.amount, 40, "Judgement of the Wise uses attacker max mana")
assertEqual(paladin.resources[1].currentValue, 504, "Judgement of the Wise restores the attacker")

local directApplied, directResult = AuraManager:GetEffect("resource").Execute(AuraManager, {
    client = Client,
    casterUnit = paladin,
    eventState = eventState,
    targetUnit = paladin,
}, judgementDirectResource)
assertTrue(directApplied, "Judgement of Wisdom direct mana effect applies")
assertEqual(directResult.amount, 41, "Judgement of Wisdom uses base mana and Spell Power rather than max mana")
assertEqual(paladin.resources[1].currentValue, 545, "Judgement of Wisdom restores 10% of base mana with Spell Power scaling")

local unsupportedTarget = newUnit(3, "Controlled NPC", 900, 1000, 100, 1000)
unsupportedTarget.isPlayer = false
local unsupportedApplied, unsupportedResult = AuraManager:GetEffect("resource").Execute(AuraManager, {
    client = Client,
    eventState = eventState,
    targetUnit = unsupportedTarget,
}, judgementDirectResource)
assertEqual(unsupportedApplied, false, "unsupported non-player base mana effect is a no-op")
assertEqual(unsupportedResult.amount, 0, "unsupported base mana does not fall back to max mana")

local function installAura(aura, auraKey, casterEventId, targetEventId)
    local bucket = AuraManager:GetEventAuraBucket(Client, eventState.id, true)
    bucket.byKey[auraKey] = {
        auraKey = auraKey,
        auraRef = "b0211ab3:" .. aura.id,
        casterEventId = casterEventId,
        datasetId = "b0211ab3",
        definition = aura,
        rankMultiplier = 1.8,
        stacks = 1,
        targetEventId = targetEventId,
        turnsRemaining = aura.duration,
    }
end

local function runCombatEvent(aura, auraKey, recipientEventId, combatEventId, eventSourceUnit, eventOtherUnit)
    installAura(aura, auraKey, 1, recipientEventId)
    return AuraManager:HandleCombatEvent(Client, {
        actionContext = {},
        combatEventId = combatEventId,
        eventOtherUnit = eventOtherUnit,
        eventSourceUnit = eventSourceUnit,
        eventState = eventState,
        recipientEventId = recipientEventId,
        sessionState = { active = true },
    })
end

paladin.resources[2].currentValue = 900
assertTrue(runCombatEvent(sealOfLight, "seal-light-hit", 1, "on_auto_attack_hit", paladin, enemy),
    "Seal of Light hit proc executes")
assertEqual(paladin.resources[2].currentValue, 940, "Seal of Light hit proc targets the wearer")

paladin.resources[2].currentValue = 900
assertTrue(runCombatEvent(judgementOfLight, "judgement-light-taken", 2, "on_auto_attack_taken", paladin, enemy),
    "Judgement of Light taken proc executes")
assertEqual(paladin.resources[2].currentValue, 920, "Judgement of Light taken proc targets event source")

print("PaladinAuraProcTest passed")
