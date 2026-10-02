local function assertEqual(actual, expected, message)
    if actual ~= expected then
        error(("%s: expected %s, got %s"):format(message, tostring(expected), tostring(actual)), 2)
    end
end

local function assertTrue(value, message)
    if value ~= true then
        error(message, 2)
    end
end

local function loadAddonFile(path, addon)
    local chunk, loadError = loadfile(path)
    assert(chunk, loadError)
    chunk(nil, addon)
end

local function normalize(value)
    local text = tostring(value or ""):gsub("^%s+", ""):gsub("%s+$", "")
    return text ~= "" and string.lower(text) or nil
end

local function splitList(value)
    if type(value) == "table" then
        return value
    end
    local values = {}
    for token in tostring(value or ""):gmatch("[^,]+") do
        values[#values + 1] = token
    end
    return values
end

local function findRule(definitions, categoryKey, ruleKey)
    for categoryIndex = 1, #definitions do
        local category = definitions[categoryIndex]
        if category.key == categoryKey then
            for ruleIndex = 1, #(category.rules or {}) do
                local rule = category.rules[ruleIndex]
                if rule.key == ruleKey then
                    return rule
                end
            end
        end
    end
    return nil
end

local rulesAddon = {
    Internal = {
        Ruleset = { Rules = {} },
    },
}
loadAddonFile("core/internal/ruleset/Rules.lua", rulesAddon)
local shieldRule = findRule(rulesAddon.Internal.Ruleset.Rules.Definitions, "combat", "shield_block_value_stat")
assertTrue(shieldRule ~= nil, "Shield Block Value combat rule exists")
assertEqual(shieldRule.label, "Shield Block Value Stat", "Shield Block Value combat rule label")
assertEqual(shieldRule.type, "dropdown", "Shield Block Value combat rule type")
assertEqual(shieldRule.optionsSource, "statReference", "Shield Block Value combat rule source")
assertEqual(shieldRule.default, "", "Shield Block Value combat rule defaults disabled")

local dataAddon = {
    Data = {},
}
loadAddonFile("data/default/Datasets.lua", dataAddon)
loadAddonFile("data/default/core.lua", dataAddon)
local coreDefinition = dataAddon.Data.DefaultDatasets.Definitions["f82db71a"]
assertEqual(coreDefinition.version, 58, "Core dataset version increments for Shield Block Value")
local shieldStat
for index = 1, #(coreDefinition.dataset.stats or {}) do
    local stat = coreDefinition.dataset.stats[index]
    if stat.name == "Shield Block Value" then
        shieldStat = stat
        break
    end
end
assertTrue(shieldStat ~= nil, "Core Shield Block Value stat exists")
assertEqual(shieldStat.category, "Defense", "Shield Block Value category")
assertEqual(shieldStat.baseValue, 0, "Shield Block Value base value")
assertEqual(shieldStat.valueMode, "derived", "Shield Block Value value mode")
assertEqual(shieldStat.displayMode, "equip", "Shield Block Value display mode")
assertEqual(#(shieldStat.derivedSources or {}), 1, "Shield Block Value derives from Strength")
assertEqual(shieldStat.derivedSources[1].sourceStatRef, "f82db71a:zfqm8dxp", "Shield Block Value Strength source")
assertEqual(shieldStat.derivedSources[1].coefficient, 0.05, "Shield Block Value Strength coefficient")
assertEqual(shieldStat.seedNPCStat, false, "Shield Block Value is not seeded on new NPCs")

local wornShield
for index = 1, #(coreDefinition.dataset.items or {}) do
    local item = coreDefinition.dataset.items[index]
    if item.id == "stshld01" then
        wornShield = item
        break
    end
end
assertTrue(wornShield ~= nil, "Core Worn Shield item exists")
local wornShieldBlockValue
for index = 1, #(wornShield.stats or {}) do
    local stat = wornShield.stats[index]
    if stat.sourceStatRef == "f82db71a:sblkval1" then
        wornShieldBlockValue = stat.value
        break
    end
end
assertEqual(wornShieldBlockValue, 3, "Worn Shield grants Shield Block Value")

local shieldStatRef = "test:shield-block-value"
local activeRuleset = {
    rules = {
        combat = {
            block_chance_stat = "test:block-chance",
            shield_block_value_stat = "",
        },
    },
}

local function getStatValue(unit, statRef, fallback)
    for index = 1, #(unit and unit.stats or {}) do
        local row = unit.stats[index]
        if row.statRef == statRef then
            return tonumber(row.currentValue or row.value or row.initialValue) or fallback or 0
        end
    end
    return fallback or 0
end

local Addon = {
    Client = {
        Combat = {
            Normalization = {
                TrimText = function(value)
                    return tostring(value or ""):gsub("^%s+", ""):gsub("%s+$", "")
                end,
                NormalizeToken = normalize,
                NormalizeResultToken = normalize,
                NormalizeEffectType = normalize,
                SplitList = splitList,
            },
        },
        Spellcasting = {},
    },
    Internal = {
        Comms = {},
        Database = { Classes = {}, Dependecies = {} },
        Profile = {},
        Registry = {},
        Ruleset = {
            Rules = rulesAddon.Internal.Ruleset.Rules,
            GetActiveRuleset = function()
                return activeRuleset
            end,
            GetRulesetRuleDefinition = function(categoryKey, ruleKey)
                return findRule(rulesAddon.Internal.Ruleset.Rules.Definitions, categoryKey, ruleKey)
            end,
            GetRulesetRuleValue = function(ruleset, categoryKey, ruleDefinition)
                local category = ruleset and ruleset.rules and ruleset.rules[categoryKey] or nil
                local value = category and category[ruleDefinition.key] or nil
                return value ~= nil and value or ruleDefinition.default
            end,
        },
    },
    Utils = {
        Common = {
            Round = function(value)
                return math.floor((tonumber(value) or 0) + 0.5)
            end,
        },
        Dice = {
            RollVariance = function()
                return 1
            end,
        },
        Lookup = {
            GetStatValue = getStatValue,
        },
    },
}

local Combat = Addon.Client.Combat
local createEffectContract = function(_, definition)
    return definition
end
Combat.CreateEffectContract = createEffectContract

loadAddonFile("client/combat/Reaction.lua", Addon)
Combat = Addon.Client.Combat
Combat.CreateEffectContract = createEffectContract
loadAddonFile("client/combat/effects/Damage.lua", Addon)

Combat.CloneValue = function(_, value)
    return value
end
Combat.PreviewResourceDelta = function(_, _, resourceRef, delta)
    return true, { resourceRef = resourceRef, maxValue = 100, currentValue = 100 + delta }, delta
end

local function makeEntry(rawDamage, shieldValue, mitigationFlat, isPlayer)
    local attacker = {
        eventID = 1,
        isPlayer = true,
        stats = {},
    }
    local defender = {
        eventID = 2,
        isPlayer = isPlayer == true,
        stats = {
            { statRef = shieldStatRef, currentValue = shieldValue },
        },
    }
    local effect = {
        hitType = "ability",
        damageSchoolRefs = {},
    }
    local hitContext = {
        initialized = true,
        rawDamage = rawDamage,
        effect = effect,
        component = {},
        combatRules = {
            crushingDamageMultiplier = 1.5,
            criticalDamageMultiplier = 2,
            criticalDamageMitigationStat = nil,
            damageDealtStat = nil,
            spellDamageVsCreatureTypeStats = {},
            damageReductionStat = nil,
            shieldBlockValueStat = activeRuleset.rules.combat.shield_block_value_stat,
            threatGeneratedStat = nil,
        },
        schoolContexts = mitigationFlat and {
            { mitigation = { mode = "direct", flat = mitigationFlat } },
        } or {},
        schoolNames = {},
        healthResourceContext = { healthResourceRef = "test:health" },
    }
    return {
        attackerUnit = attacker,
        defenderUnit = defender,
        attackerEventId = attacker.eventID,
        defenderEventId = defender.eventID,
        eventState = { active = true, id = "shield-block-test", units = { attacker, defender } },
        context = {},
        effect = effect,
        component = {},
        attackType = "melee",
        resultType = "hit",
        hitResolutionContext = hitContext,
    }
end

local function markBlock(entry, statRef)
    return Combat:MarkShieldBlockValueDamageContext(
        entry,
        { id = "percent:" .. statRef, statRef = statRef, enabled = true },
        "fail",
        { defenceSystem = "percent", defenceStatRef = statRef }
    )
end

local blockChanceRef = activeRuleset.rules.combat.block_chance_stat
activeRuleset.rules.combat.shield_block_value_stat = ""
local disabledEntry = makeEntry(100, 30, 0, true)
assertEqual(markBlock(disabledEntry, blockChanceRef), false, "empty Shield Block Value rule leaves Block unmarked")
local disabledResult = Combat:BuildDamagePreview(disabledEntry)
assertEqual(disabledResult.preAbsorbAmount, 100, "disabled Shield Block Value does not reduce damage")
assertEqual(disabledResult.blocked, false, "disabled Shield Block Value result is not partial")

activeRuleset.rules.combat.shield_block_value_stat = shieldStatRef
local fullDamageEntry = makeEntry(100, 30, 0, true)
assertEqual(markBlock(fullDamageEntry, blockChanceRef), true, "configured full-damage Block is marked")
local fullDamageResult = Combat:BuildDamagePreview(fullDamageEntry)
assertEqual(fullDamageResult.preAbsorbAmount, 70, "Shield Block Value reduces post-mitigation 100 damage to 70")

local blockedEntry = makeEntry(100, 30, 20, true)
assertEqual(markBlock(blockedEntry, blockChanceRef), true, "configured Block is marked for partial mitigation")
local blockedResult = Combat:BuildDamagePreview(blockedEntry)
assertEqual(blockedResult.preAbsorbAmount, 50, "Shield Block Value applies after ordinary mitigation")
assertEqual(blockedResult.amount, 50, "configured Shield Block Value applies 30 reduction")
assertEqual(blockedResult.blocked, true, "resolved damage records partial Block")
assertEqual(blockedResult.shieldBlockValueStatRef, shieldStatRef, "resolved damage records Shield Block Value stat")
assertEqual(blockedResult.shieldBlockValue, 30, "resolved damage records Shield Block Value")
assertEqual(blockedResult.blockedAmount, 30, "resolved damage records prevented Block amount")

local defenceEventCount = 0
Combat.Events = {
    Run = function()
        defenceEventCount = defenceEventCount + 1
        return true
    end,
}
assertEqual(Combat:EmitSuccessfulDefenceEvent(
    Addon.Client,
    blockedEntry,
    { id = "percent:" .. blockChanceRef, statRef = blockChanceRef, enabled = true },
    "fail",
    { defenceSystem = "percent", defenceStatRef = blockChanceRef }
), true, "partial Block emits the existing successful-defence event")
assertEqual(defenceEventCount, 1, "partial Block emits one successful-defence event")

local absorbedInput
Addon.Client.Spellcasting.AuraManager = {
    PreviewAbsorption = function(_, _, _, amount)
        absorbedInput = amount
        return { absorbedAmount = 10, remainingDamage = amount - 10, changes = {} }
    end,
}
local absorbedEntry = makeEntry(100, 30, 20, true)
assertEqual(markBlock(absorbedEntry, blockChanceRef), true, "Aura test Block is marked")
local absorbedResult = Combat:BuildDamagePreview(absorbedEntry)
assertEqual(absorbedInput, 50, "Aura absorption receives post-Block damage")
assertEqual(absorbedResult.preAbsorbAmount, 50, "Block reduction remains outside Aura absorption")
assertEqual(absorbedResult.absorbedAmount, 10, "Aura absorption remains separately accounted")
assertEqual(absorbedResult.amount, 40, "Aura absorption applies after Shield Block Value")

Addon.Client.Spellcasting.AuraManager = nil
local clampedEntry = makeEntry(100, 30, 80, true)
assertEqual(markBlock(clampedEntry, blockChanceRef), true, "low-damage Block is marked")
local clampedResult = Combat:BuildDamagePreview(clampedEntry)
assertEqual(clampedResult.preAbsorbAmount, 0, "Shield Block Value clamps damage at zero")
assertEqual(clampedResult.blockedAmount, 20, "blocked amount is capped at post-mitigation damage")

local dodgeEntry = makeEntry(100, 30, 20, true)
assertEqual(markBlock(dodgeEntry, "test:dodge"), false, "Dodge is not identified as Block by display text")
local dodgeResult = Combat:BuildDamagePreview(dodgeEntry)
assertEqual(dodgeResult.preAbsorbAmount, 80, "other defences remain ordinary damage outcomes")

local failedBlockEntry = makeEntry(100, 30, 20, true)
assertEqual(Combat:MarkShieldBlockValueDamageContext(
    failedBlockEntry,
    { id = "percent:" .. blockChanceRef, statRef = blockChanceRef, enabled = true },
    "pass",
    { defenceSystem = "percent", defenceStatRef = blockChanceRef }
), false, "failed Block is not marked for Shield Block Value")
local failedBlockResult = Combat:BuildDamagePreview(failedBlockEntry)
assertEqual(failedBlockResult.preAbsorbAmount, 80, "failed Block receives no Shield Block Value reduction")

local npcEntry = makeEntry(100, 30, 20, false)
assertEqual(markBlock(npcEntry, blockChanceRef), true, "NPC Block is marked")
local npcResult = Combat:BuildDamagePreview(npcEntry)
assertEqual(npcResult.preAbsorbAmount, blockedResult.preAbsorbAmount, "NPC defenders use the same resolved Stat lookup")

local remoteEntry = makeEntry(100, 30, 20, true)
remoteEntry.checkId = "remote-shield-block"
remoteEntry.eventId = remoteEntry.eventState.id
local remoteClient = {
    GetPendingCombatHitCheck = function(_, checkId)
        return checkId == remoteEntry.checkId and remoteEntry or nil
    end,
}
local remotePending, remoteResult = Combat:HandleDamageHitCheckResponse(remoteClient, {
    remoteEntry.checkId,
    remoteEntry.eventId,
    "fail",
    "defended",
    blockChanceRef,
    "",
    "",
    "",
    "blocked",
    shieldStatRef,
}, nil)
assertTrue(remotePending, "remote Block response remains pending for damage hand-off")
assertTrue(remoteEntry.blocked, "remote Block response preserves explicit blocked context")
assertEqual(remoteResult.blocked, true, "remote pending result preserves blocked metadata")

local authoritativeEntry = makeEntry(100, 30, 20, true)
assertEqual(markBlock(authoritativeEntry, blockChanceRef), true, "authoritative Block is marked")
local previewResult = Combat:BuildDamagePreview(authoritativeEntry)
local applied, authoritativeResult = Combat:ApplyResolvedDamage(authoritativeEntry, true)
assertEqual(applied, true, "authoritative preview resolves")
assertEqual(authoritativeResult.preAbsorbAmount, previewResult.preAbsorbAmount, "preview and application share blocked pre-absorb damage")

print("ShieldBlockValueTest passed")
