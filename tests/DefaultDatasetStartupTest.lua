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

local savedDatasetRoot = rawget(_G, "RPEngineDatasetDB")
local savedManagerRoot = rawget(_G, "RPEngineManagerDB")
local savedSlashCmdList = rawget(_G, "SlashCmdList")
local diagnostics = {}
local TestSupport = dofile("tests/support/RuntimeStubs.lua")
local Addon = TestSupport.CreateAddon({
    Debug = {
        Internal = function(message, ...)
            diagnostics[#diagnostics + 1] = select("#", ...) > 0
                and string.format(message, ...)
                or tostring(message)
        end,
    },
})

-- The helper reads the packaged TOC, so this smoke test automatically covers
-- a newly added default-data file without maintaining a parallel file list.
local definitions = TestSupport.LoadPackagedDefaultData(Addon)

TestSupport.LoadAddonFile("data/default/Install.lua", Addon)
rawset(_G, "SlashCmdList", {})
TestSupport.LoadAddonFile("Commands.lua", Addon)
TestSupport.LoadAddonFile("core/internal/manager/ExternalManager.lua", Addon)
TestSupport.LoadAddonFile("core/internal/Runtime.lua", Addon)

local Database = Addon.Internal.Database
local Dependecies = Database.Dependecies
assertTrue(type(Addon.Data.SyncDefaultDatasets) == "function", "installer exposes the runtime dataset synchronizer")

local expectedDefinitionCount = 0
for datasetId, definition in pairs(definitions) do
    assertTrue(type(definition) == "table" and type(definition.dataset) == "table", "packaged definition is valid: " .. tostring(datasetId))
    expectedDefinitionCount = expectedDefinitionCount + 1
end

local coreDefinition = definitions["f82db71a"]
assertTrue(type(coreDefinition) == "table" and type(coreDefinition.dataset) == "table", "Core packaged definition exists")

local paladinDefinition = definitions["b0211ab3"]
assertTrue(type(paladinDefinition) == "table" and type(paladinDefinition.dataset) == "table", "Paladin packaged definition exists")

local soulforgeSet
for index = 1, #(paladinDefinition.dataset.itemSets or {}) do
    local itemSet = paladinDefinition.dataset.itemSets[index]
    if itemSet and itemSet.key == "t05_pala_soulforge" then
        soulforgeSet = itemSet
        break
    end
end
assertTrue(type(soulforgeSet) == "table", "Paladin Soulforge Item Set exists")
local expectedSoulforgeBonuses = {
    { requiredPieces = 2 },
    { requiredPieces = 4 },
    { requiredPieces = 6, statRef = "f82db71a:zs1nbz13", value = 2 },
    { requiredPieces = 8, statRef = "f82db71a:v42albuv", value = 200 },
}
assertEqual(#soulforgeSet.bonuses, #expectedSoulforgeBonuses, "Paladin Soulforge bonus tier count")
for index = 1, #expectedSoulforgeBonuses do
    local actual = soulforgeSet.bonuses[index]
    local expected = expectedSoulforgeBonuses[index]
    assertEqual(actual.requiredPieces, expected.requiredPieces, "Paladin Soulforge bonus threshold " .. index)
    if expected.statRef then
        assertEqual(actual.statBonuses[1].statRef, expected.statRef, "Paladin Soulforge bonus stat " .. index)
        assertEqual(actual.statBonuses[1].value, expected.value, "Paladin Soulforge bonus value " .. index)
    end
end
assertEqual(#soulforgeSet.bonuses[1].statBonuses, 2, "Paladin Soulforge two-piece stat count")
assertEqual(soulforgeSet.bonuses[1].statBonuses[1].statRef, "f82db71a:u7b49vs9", "Paladin Soulforge two-piece attack power")
assertEqual(soulforgeSet.bonuses[1].statBonuses[1].value, 40, "Paladin Soulforge two-piece attack power value")
assertEqual(soulforgeSet.bonuses[1].statBonuses[2].statRef, "f82db71a:hj6d4kvy", "Paladin Soulforge two-piece healing power")
assertEqual(soulforgeSet.bonuses[1].statBonuses[2].value, 40, "Paladin Soulforge two-piece healing power value")

local soulforgeProc = soulforgeSet.bonuses[2].equipmentBonuses[1]
assertEqual(soulforgeProc.name, "Soulforge Empowerment", "Paladin Soulforge four-piece equipment bonus name")
assertEqual(#soulforgeProc.events, 2, "Paladin Soulforge four-piece event count")
assertEqual(soulforgeProc.events[1].combatEventId, "on_auto_attack_hit", "Paladin Soulforge melee proc event")
assertEqual(soulforgeProc.events[1].chance, 6, "Paladin Soulforge melee proc chance")
assertEqual(soulforgeProc.events[1].triggerTarget, "event_source", "Paladin Soulforge melee proc target")
assertEqual(soulforgeProc.events[2].combatEventId, "on_spell_hit", "Paladin Soulforge spell proc event")
assertEqual(soulforgeProc.events[2].chance, 4, "Paladin Soulforge spell proc chance")
assertEqual(soulforgeProc.events[2].triggerTarget, "event_source", "Paladin Soulforge spell proc target")
assertEqual(soulforgeProc.events[1].effects[1].auraRef, "b0211ab3:sfempwr1", "Paladin Soulforge proc aura reference")

local soulforgeAura
for index = 1, #(paladinDefinition.dataset.auras or {}) do
    local aura = paladinDefinition.dataset.auras[index]
    if aura and aura.id == "sfempwr1" then
        soulforgeAura = aura
        break
    end
end
assertTrue(type(soulforgeAura) == "table", "Paladin Soulforge empowerment aura exists")
assertEqual(soulforgeAura.duration, 2, "Paladin Soulforge empowerment duration")
assertEqual(soulforgeAura.effects[1].statRef, "f82db71a:7t7xgzcx", "Paladin Soulforge empowerment spell power")
assertEqual(soulforgeAura.effects[1].baseAmount, 95, "Paladin Soulforge empowerment spell power value")
assertEqual(soulforgeAura.effects[2].statRef, "f82db71a:hj6d4kvy", "Paladin Soulforge empowerment healing power")
assertEqual(soulforgeAura.effects[2].baseAmount, 95, "Paladin Soulforge empowerment healing power value")

local soulforgeItemCount = 0
for index = 1, #(paladinDefinition.dataset.items or {}) do
    if paladinDefinition.dataset.items[index].itemSetKey == "t05_pala_soulforge" then
        soulforgeItemCount = soulforgeItemCount + 1
    end
end
assertEqual(soulforgeItemCount, 24, "Paladin Soulforge variants share one Item Set")

local layOnHandsSpell
local judgementOfWisdomSpell
for index = 1, #(paladinDefinition.dataset.spells or {}) do
    local spell = paladinDefinition.dataset.spells[index]
    if spell and spell.id == "lohs3c8f" then
        layOnHandsSpell = spell
    elseif spell and spell.id == "j1my2871" then
        judgementOfWisdomSpell = spell
    end
end
assertTrue(type(layOnHandsSpell) == "table", "Paladin Lay on Hands spell exists")
assertEqual(layOnHandsSpell.resourceCosts[1].amount, 100, "Paladin Lay on Hands mana cost")
assertEqual(layOnHandsSpell._resourceCostsByPhase.on_cast_end[1].amount, 100, "Paladin Lay on Hands cached mana cost")
assertTrue(type(judgementOfWisdomSpell) == "table", "Paladin Judgement of Wisdom spell exists")
assertEqual(judgementOfWisdomSpell.components[1].effect.amount, 10, "Paladin Judgement of Wisdom mana gain")
assertTrue(judgementOfWisdomSpell.tooltipTemplateData.mainText:find("Restore 10%% of Base Mana", 1, false) ~= nil, "Paladin Judgement of Wisdom tooltip mana gain")

local holyShockSpell
for index = 1, #(paladinDefinition.dataset.spells or {}) do
    local spell = paladinDefinition.dataset.spells[index]
    if spell and spell.id == "hlyshck1" then
        holyShockSpell = spell
        break
    end
end
assertTrue(type(holyShockSpell) == "table", "Paladin Holy Shock spell exists")
assertEqual(holyShockSpell.name, "Holy Shock", "Paladin Holy Shock name")
assertEqual(holyShockSpell.spellbookCategory, "Holy", "Paladin Holy Shock category")
assertEqual(holyShockSpell.icon, "interface/icons/spell_holy_searinglight.blp", "Paladin Holy Shock icon")
assertEqual(holyShockSpell.cooldownChannel, 2, "Paladin Holy Shock Bonus Action channel")
assertEqual(holyShockSpell.cooldown, 3, "Paladin Holy Shock cooldown")
assertEqual(holyShockSpell.casterEvents[1], "on_heal", "Paladin Holy Shock heal event")
assertEqual(holyShockSpell.casterEvents[2], "on_critical_heal", "Paladin Holy Shock critical heal event")
assertEqual(holyShockSpell.components[1].effect.type, "heal", "Paladin Holy Shock effect type")
assertEqual(holyShockSpell.components[1].effect.baseHealing, 84.5, "Paladin Holy Shock base healing")
assertEqual(holyShockSpell.components[1].effect.statScaling[1].coefficient, 0.507, "Paladin Holy Shock Healing Power scaling")
assertEqual(holyShockSpell.resourceCosts[1].amount, 6.3, "Paladin Holy Shock mana cost")
assertEqual(holyShockSpell.components[1].target.targetDisposition, "ally", "Paladin Holy Shock target disposition")
assertTrue(holyShockSpell.tooltipTemplateData.mainText:find("Heal an ally", 1, true) ~= nil, "Paladin Holy Shock healing tooltip")

local warriorDefinition = definitions["7bbb4cb9"]
assertTrue(type(warriorDefinition) == "table" and type(warriorDefinition.dataset) == "table", "Warrior packaged definition exists")

local heroismSet
for index = 1, #(warriorDefinition.dataset.itemSets or {}) do
    local itemSet = warriorDefinition.dataset.itemSets[index]
    if itemSet and itemSet.key == "t05_warrior_heroism" then
        heroismSet = itemSet
        break
    end
end
assertTrue(type(heroismSet) == "table", "Warrior Heroism Item Set exists")
assertEqual(#heroismSet.bonuses, 4, "Warrior Heroism bonus tier count")
assertEqual(heroismSet.bonuses[1].requiredPieces, 2, "Warrior Heroism two-piece threshold")
assertEqual(heroismSet.bonuses[1].statBonuses[1].statRef, "f82db71a:u7b49vs9", "Warrior Heroism attack power stat")
assertEqual(heroismSet.bonuses[1].statBonuses[1].value, 40, "Warrior Heroism attack power value")

local heroismProc = heroismSet.bonuses[2].equipmentBonuses[1]
assertEqual(heroismProc.name, "Heroism's Resolve", "Warrior Heroism four-piece equipment bonus name")
assertEqual(#heroismProc.events, 2, "Warrior Heroism four-piece event count")
assertEqual(heroismProc.events[1].combatEventId, "on_melee_hit", "Warrior Heroism melee proc event")
assertEqual(heroismProc.events[1].chance, 10, "Warrior Heroism melee proc chance")
assertEqual(heroismProc.events[1].triggerTarget, "event_source", "Warrior Heroism melee proc target")
assertEqual(heroismProc.events[1].effects[1].type, "heal", "Warrior Heroism melee proc healing effect")
assertEqual(heroismProc.events[1].effects[1].baseHealing, 125, "Warrior Heroism melee proc healing value")
assertEqual(heroismProc.events[1].effects[2].resourceRef, "f82db71a:e2tfklq7", "Warrior Heroism melee proc rage resource")
assertEqual(heroismProc.events[1].effects[2].amount, 10, "Warrior Heroism melee proc rage value")
assertEqual(heroismProc.events[2].combatEventId, "on_auto_attack_hit", "Warrior Heroism basic attack proc event")
assertEqual(heroismProc.events[2].chance, 10, "Warrior Heroism basic attack proc chance")
assertEqual(heroismProc.events[2].triggerTarget, "event_source", "Warrior Heroism basic attack proc target")
assertEqual(heroismProc.events[2].effects[1].baseHealing, 125, "Warrior Heroism basic attack healing value")
assertEqual(heroismProc.events[2].effects[2].amount, 10, "Warrior Heroism basic attack rage value")
assertEqual(heroismSet.bonuses[3].statBonuses[1].statRef, "f82db71a:zs1nbz13", "Warrior Heroism magic resistance stat")
assertEqual(heroismSet.bonuses[3].statBonuses[1].value, 2, "Warrior Heroism magic resistance value")
assertEqual(heroismSet.bonuses[4].statBonuses[1].statRef, "f82db71a:v42albuv", "Warrior Heroism armor stat")
assertEqual(heroismSet.bonuses[4].statBonuses[1].value, 200, "Warrior Heroism armor value")

local heroismItemCount = 0
for index = 1, #(warriorDefinition.dataset.items or {}) do
    if warriorDefinition.dataset.items[index].itemSetKey == "t05_warrior_heroism" then
        heroismItemCount = heroismItemCount + 1
    end
end
assertEqual(heroismItemCount, 16, "Warrior Heroism variants share one Item Set")

local mageDefinition = definitions["d7c874c4"]
assertTrue(type(mageDefinition) == "table" and type(mageDefinition.dataset) == "table", "Mage packaged definition exists")

local sorcerersSet
for index = 1, #(mageDefinition.dataset.itemSets or {}) do
    local itemSet = mageDefinition.dataset.itemSets[index]
    if itemSet and itemSet.key == "t05_mage_sorcerers" then
        sorcerersSet = itemSet
        break
    end
end
assertTrue(type(sorcerersSet) == "table", "Mage Sorcerer's Regalia Item Set exists")
assertEqual(#sorcerersSet.bonuses, 4, "Mage Sorcerer's Regalia bonus tier count")
assertEqual(sorcerersSet.bonuses[1].requiredPieces, 2, "Mage Sorcerer's Regalia two-piece threshold")
assertEqual(sorcerersSet.bonuses[1].statBonuses[1].statRef, "f82db71a:7t7xgzcx", "Mage Sorcerer's Regalia spell power stat")
assertEqual(sorcerersSet.bonuses[1].statBonuses[1].value, 23, "Mage Sorcerer's Regalia spell power value")
assertEqual(sorcerersSet.bonuses[1].statBonuses[2].statRef, "f82db71a:hj6d4kvy", "Mage Sorcerer's Regalia healing power stat")
assertEqual(sorcerersSet.bonuses[1].statBonuses[2].value, 23, "Mage Sorcerer's Regalia healing power value")

local sorcerersProc = sorcerersSet.bonuses[2].equipmentBonuses[1]
assertEqual(sorcerersProc.name, "Sorcerer's Focus", "Mage Sorcerer's Regalia four-piece equipment bonus name")
assertEqual(#sorcerersProc.events, 1, "Mage Sorcerer's Regalia four-piece event count")
assertEqual(sorcerersProc.events[1].combatEventId, "on_spell_hit", "Mage Sorcerer's Regalia spell proc event")
assertEqual(sorcerersProc.events[1].chance, 6, "Mage Sorcerer's Regalia spell proc chance")
assertEqual(sorcerersProc.events[1].triggerTarget, "event_source", "Mage Sorcerer's Regalia spell proc target")
assertEqual(sorcerersProc.events[1].effects[1].resourceRef, "f82db71a:4c8mfm99", "Mage Sorcerer's Regalia mana resource")
assertEqual(sorcerersProc.events[1].effects[1].amount, 125, "Mage Sorcerer's Regalia mana value")
assertEqual(sorcerersSet.bonuses[3].statBonuses[1].statRef, "f82db71a:zs1nbz13", "Mage Sorcerer's Regalia magic resistance stat")
assertEqual(sorcerersSet.bonuses[3].statBonuses[1].value, 2, "Mage Sorcerer's Regalia magic resistance value")
assertEqual(sorcerersSet.bonuses[4].statBonuses[1].statRef, "f82db71a:v42albuv", "Mage Sorcerer's Regalia armor stat")
assertEqual(sorcerersSet.bonuses[4].statBonuses[1].value, 200, "Mage Sorcerer's Regalia armor value")

local sorcerersItemCount = 0
for index = 1, #(mageDefinition.dataset.items or {}) do
    if mageDefinition.dataset.items[index].itemSetKey == "t05_mage_sorcerers" then
        sorcerersItemCount = sorcerersItemCount + 1
    end
end
assertEqual(sorcerersItemCount, 16, "Mage Sorcerer's Regalia variants share one Item Set")

local rogueDefinition = definitions["23d5dce2"]
assertTrue(type(rogueDefinition) == "table" and type(rogueDefinition.dataset) == "table", "Rogue packaged definition exists")

local darkmantleSet
for index = 1, #(rogueDefinition.dataset.itemSets or {}) do
    local itemSet = rogueDefinition.dataset.itemSets[index]
    if itemSet and itemSet.key == "t05_rogue_darkmantle" then
        darkmantleSet = itemSet
        break
    end
end
assertTrue(type(darkmantleSet) == "table", "Rogue Darkmantle Item Set exists")
assertEqual(#darkmantleSet.bonuses, 4, "Rogue Darkmantle bonus tier count")
assertEqual(darkmantleSet.bonuses[1].requiredPieces, 2, "Rogue Darkmantle two-piece threshold")
assertEqual(darkmantleSet.bonuses[1].statBonuses[1].statRef, "f82db71a:u7b49vs9", "Rogue Darkmantle attack power stat")
assertEqual(darkmantleSet.bonuses[1].statBonuses[1].value, 40, "Rogue Darkmantle attack power value")

local darkmantleProc = darkmantleSet.bonuses[2].equipmentBonuses[1]
assertEqual(darkmantleProc.name, "Darkmantle Energy", "Rogue Darkmantle four-piece equipment bonus name")
assertEqual(#darkmantleProc.events, 1, "Rogue Darkmantle four-piece event count")
assertEqual(darkmantleProc.events[1].combatEventId, "on_auto_attack_hit", "Rogue Darkmantle basic attack proc event")
assertEqual(darkmantleProc.events[1].chance, 3, "Rogue Darkmantle basic attack proc chance")
assertEqual(darkmantleProc.events[1].triggerTarget, "event_source", "Rogue Darkmantle basic attack proc target")
assertEqual(darkmantleProc.events[1].effects[1].resourceRef, "f82db71a:c3gaf7dd", "Rogue Darkmantle energy resource")
assertEqual(darkmantleProc.events[1].effects[1].amount, 35, "Rogue Darkmantle energy value")
assertEqual(darkmantleSet.bonuses[3].statBonuses[1].statRef, "f82db71a:zs1nbz13", "Rogue Darkmantle magic resistance stat")
assertEqual(darkmantleSet.bonuses[3].statBonuses[1].value, 2, "Rogue Darkmantle magic resistance value")
assertEqual(darkmantleSet.bonuses[4].statBonuses[1].statRef, "f82db71a:v42albuv", "Rogue Darkmantle armor stat")
assertEqual(darkmantleSet.bonuses[4].statBonuses[1].value, 200, "Rogue Darkmantle armor value")

local darkmantleItemCount = 0
for index = 1, #(rogueDefinition.dataset.items or {}) do
    if rogueDefinition.dataset.items[index].itemSetKey == "t05_rogue_darkmantle" then
        darkmantleItemCount = darkmantleItemCount + 1
    end
end
assertEqual(darkmantleItemCount, 16, "Rogue Darkmantle variants share one Item Set")

local coreGuildSetting = coreDefinition.dataset.guildSettings and coreDefinition.dataset.guildSettings[1]
assertTrue(type(coreGuildSetting) == "table", "Core packaged Guild Shop setting exists")

local guildShopArmourByItemRef = {}
for index = 1, #(coreGuildSetting.requisitions or {}) do
    local requisition = coreGuildSetting.requisitions[index]
    if requisition.shopCategoryId == "a6r4m2ur" then
        guildShopArmourByItemRef[requisition.itemRef] = requisition
    end
end

local function endsWithAny(value, suffixes)
    for index = 1, #suffixes do
        local suffix = suffixes[index]
        if value:sub(-#suffix) == suffix then
            return true
        end
    end
    return false
end

local function expectedGuildShopArmourCost(itemId)
    if endsWithAny(itemId, { "belt", "brac", "bind", "cord", "wais", "wris", "wrst", "wrap" }) then
        return 1250
    end
    if endsWithAny(itemId, { "boot", "feet", "glov", "hand", "hnds", "grsp", "sand", "trds" }) then
        return 1750
    end
    return 2250
end

local excludedGuildShopArmourPrefixes = {
    c4a91e7d = "s2",
    e8f3b2c6 = "wl2",
    dhunter1 = "dh2",
    evokdata = "ev2",
}

for _, datasetId in ipairs({ "c4a91e7d", "e8f3b2c6", "dhunter1", "evokdata" }) do
    local classDataset = definitions[datasetId].dataset
    for index = 1, #(classDataset.items or {}) do
        local item = classDataset.items[index]
        local itemRef = datasetId .. ":" .. item.id
        local requisition = guildShopArmourByItemRef[itemRef]
        local excludedPrefix = excludedGuildShopArmourPrefixes[datasetId]
        if excludedPrefix and item.id:sub(1, #excludedPrefix) == excludedPrefix then
            assertTrue(requisition == nil, "Guild Shop excludes " .. itemRef)
        else
            assertTrue(type(requisition) == "table", "Guild Shop includes " .. itemRef)
            assertEqual(requisition.quantity, 1, "Guild Shop quantity for " .. itemRef)
            assertEqual(requisition.costs[1].currencyRef, "justice", "Guild Shop currency for " .. itemRef)
            assertEqual(requisition.costs[1].amount, expectedGuildShopArmourCost(item.id), "Guild Shop price for " .. itemRef)
        end
    end
end

local function assertCoreGuildDependency(datasetId)
    for index = 1, #(coreDefinition.dataset.dependencies or {}) do
        if coreDefinition.dataset.dependencies[index] == datasetId then
            return
        end
    end
    error("Core Guild Shop dependency is missing: " .. datasetId, 2)
end
assertCoreGuildDependency("c4a91e7d")
assertCoreGuildDependency("e8f3b2c6")
assertCoreGuildDependency("dhunter1")
assertCoreGuildDependency("evokdata")

local function findCoreSpell(spellId)
    for index = 1, #(coreDefinition.dataset.spells or {}) do
        local spell = coreDefinition.dataset.spells[index]
        if spell and spell.id == spellId then
            return spell
        end
    end
end

local function assertBasicWeaponAttack(spellId, expectedDamageType, expectedStatRef, expectedStatCoefficient, label)
    local spell = findCoreSpell(spellId)
    assertTrue(type(spell) == "table", label .. " exists in Core")
    assertEqual(spell.cooldownChannel, 4, label .. " remains a Free Action")
    local component = spell.components and spell.components[1]
    local effect = component and component.effect
    assertTrue(type(effect) == "table", label .. " has a damage effect")
    assertEqual(effect.hitType, "auto", label .. " remains a basic auto attack")
    assertEqual(effect.damageType, expectedDamageType, label .. " uses the correct attack type")
    assertEqual(effect.weaponDamageMode, "main_hand", label .. " includes its equipped ranged-slot weapon")
    assertEqual(effect.weaponDamageCoefficient, 1, label .. " uses full weapon damage")
    assertEqual(effect.statScaling and effect.statScaling[1] and effect.statScaling[1].statRef, expectedStatRef, label .. " uses the correct offensive stat")
    assertEqual(effect.statScaling and effect.statScaling[1] and effect.statScaling[1].coefficient, expectedStatCoefficient, label .. " uses the correct basic-attack stat coefficient")
end

assertBasicWeaponAttack("shoota01", "ranged", "f82db71a:v2rs9cpy", 0.5, "Shoot")
assertBasicWeaponAttack("throwa01", "ranged", "f82db71a:v2rs9cpy", 0.5, "Throw")
assertBasicWeaponAttack("wandauto", "spell", "f82db71a:7t7xgzcx", 1.0, "Wand")

local dependencyRecomputations = 0
local originalRecompute = Dependecies.RecomputeDatasetDependencies
Dependecies.RecomputeDatasetDependencies = function(datasetId)
    dependencyRecomputations = dependencyRecomputations + 1
    return originalRecompute(datasetId)
end

local managerSawSynchronizedDefaults = false
local manager = Addon.Internal.ExternalManager
local originalManagerInitialize = manager.Initialize
manager.Initialize = function(...)
    local root = rawget(_G, "RPEngineDatasetDB")
    managerSawSynchronizedDefaults = type(root) == "table"
        and type(root.datasets) == "table"
        and next(root.datasets) ~= nil
    return originalManagerInitialize(...)
end

rawset(_G, "RPEngineDatasetDB", nil)
rawset(_G, "RPEngineManagerDB", nil)
Database.Datasets = nil
Addon.Internal.DispatchEvent("ADDON_LOADED", Addon.Name)

local root = rawget(_G, "RPEngineDatasetDB")
assertTrue(type(root) == "table", "clean startup creates RPEngineDatasetDB")
assertEqual(managerSawSynchronizedDefaults, true, "Manager runs after default dataset synchronization")
assertTrue(Addon.Internal.ConfigurationRevision > 0, "default synchronization emits a configuration change")
assertTrue(dependencyRecomputations >= expectedDefinitionCount, "default synchronization recomputes dataset dependencies")
for datasetId, definition in pairs(definitions) do
    assertTrue(type(root.datasets[datasetId]) == "table", "clean startup installs " .. datasetId)
    assertEqual(root.defaultDatasetVersions[datasetId], definition.version, "clean startup records version for " .. datasetId)
    assertEqual(Database.IsDatasetActivated(datasetId), true, "clean startup activates " .. datasetId)
end

local installedCoreSetting = root.datasets["f82db71a"].guildSettings[1]
installedCoreSetting.requisitions[#installedCoreSetting.requisitions + 1] = {
    id = "stale_dh_t2",
    itemRef = "dhunter1:dh2vchst",
}
installedCoreSetting.requisitions[#installedCoreSetting.requisitions + 1] = {
    id = "stale_evoker_t2",
    itemRef = "evokdata:ev2cchst",
}
Addon.Data.SyncDefaultDatasets()
for index = 1, #installedCoreSetting.requisitions do
    local itemRef = installedCoreSetting.requisitions[index].itemRef or ""
    assertTrue(not itemRef:match("^dhunter1:dh2") and not itemRef:match("^evokdata:ev2"), "stale Core Tier 2 shop rows are migrated")
end

local installedCount = 0
for _ in pairs(root.datasets) do
    installedCount = installedCount + 1
end
Addon.Internal.DispatchEvent("ADDON_LOADED", Addon.Name)
local secondStartupCount = 0
for _ in pairs(root.datasets) do
    secondStartupCount = secondStartupCount + 1
end
assertEqual(secondStartupCount, installedCount, "second startup is idempotent")

local updatedDatasetId = "f82db71a"
local updatedDefinition = definitions[updatedDatasetId]
assertTrue(updatedDefinition ~= nil, "Core packaged definition exists for update coverage")
assertTrue(Database.SetDatasetActivated(updatedDatasetId, false), "user can deactivate a packaged dataset")
local originalVersion = updatedDefinition.version
updatedDefinition.version = originalVersion + 1
Addon.Internal.DispatchEvent("ADDON_LOADED", Addon.Name)
assertEqual(root.defaultDatasetVersions[updatedDatasetId], originalVersion + 1, "package version update rewrites its dataset")
assertEqual(Database.IsDatasetActivated(updatedDatasetId), false, "package update preserves user deactivation")

local packagedName = updatedDefinition.dataset.name
root.datasets[updatedDatasetId].name = "Locally modified default dataset"
assertEqual(Addon.Data.SyncDefaultDatasets({ force = true }), true, "explicit force sync succeeds")
assertEqual(root.datasets[updatedDatasetId].name, packagedName, "explicit force sync rewrites unchanged packaged datasets")
assertEqual(Database.IsDatasetActivated(updatedDatasetId), false, "explicit force sync preserves user deactivation")

local unchangedDataset = root.datasets[updatedDatasetId]
unchangedDataset.name = "Unchanged-version sentinel"
assertEqual(Addon.Data.SyncDefaultDatasets(), true, "unchanged-version synchronization succeeds")
assertEqual(root.datasets[updatedDatasetId], unchangedDataset, "unchanged package version does not rewrite its dataset")
assertEqual(root.datasets[updatedDatasetId].name, "Unchanged-version sentinel", "unchanged package version preserves saved contents")
unchangedDataset.name = packagedName

root.datasets[updatedDatasetId].name = "Command reinstall sentinel"
assertEqual(Addon.Commands:Run("data reinstall"), true, "manual data reinstall command succeeds")
assertEqual(root.datasets[updatedDatasetId].name, packagedName, "manual data reinstall restores packaged contents")
assertEqual(Database.IsDatasetActivated(updatedDatasetId), false, "manual data reinstall preserves user deactivation")

definitions["malformed-default-regression"] = {
    version = 0,
    dataset = { id = "malformed-default-regression", name = "Malformed" },
}
assertEqual(Addon.Data.SyncDefaultDatasets(), false, "malformed packaged data fails synchronization")
local foundPreciseDiagnostic = false
for index = 1, #diagnostics do
    if diagnostics[index]:find("malformed%-default%-regression") then
        foundPreciseDiagnostic = true
        break
    end
end
assertTrue(foundPreciseDiagnostic, "malformed packaged data identifies the offending definition")
definitions["malformed-default-regression"] = nil

Dependecies.RecomputeDatasetDependencies = originalRecompute
manager.Initialize = originalManagerInitialize
rawset(_G, "RPEngineDatasetDB", savedDatasetRoot)
rawset(_G, "RPEngineManagerDB", savedManagerRoot)
rawset(_G, "SlashCmdList", savedSlashCmdList)
Database.Datasets = savedDatasetRoot

print("DefaultDatasetStartupTest passed")
