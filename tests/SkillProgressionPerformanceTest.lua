local function assertEqual(actual, expected, message)
    if actual ~= expected then
        error(("%s: expected %s, got %s"):format(message, tostring(expected), tostring(actual)), 2)
    end
end

local TestSupport = dofile("tests/support/RuntimeStubs.lua")
local metadataCalls = 0
local resolvedRowCalls = 0
local resolvedBatchCalls = 0
local setCalls = 0
local actionBarRefreshes = 0

local rows = {
    ["skills:sword"] = {
        ref = "skills:sword",
        name = "Sword",
        skillId = "sword",
        skillType = "weapon",
        storedValue = 1,
        maxValue = 100,
        weaponTypeRef = "weapon:sword",
    },
    ["skills:axe"] = {
        ref = "skills:axe",
        name = "Axe",
        skillId = "axe",
        skillType = "weapon",
        storedValue = 2,
        maxValue = 100,
        weaponTypeRef = "weapon:axe",
    },
    ["skills:roll"] = {
        ref = "skills:roll",
        name = "Rollable",
        skillId = "roll",
        skillType = "noncombat",
        storedValue = 3,
        maxValue = 100,
    },
}

local Addon = TestSupport.CreateAddon({
    Client = {
        ResolveLocalEventUnit = function()
            return { eventID = 7 }
        end,
        RefreshActionBarWidget = function()
            actionBarRefreshes = actionBarRefreshes + 1
        end,
    },
    Internal = {
        Profile = {
            GetSkillMetadataByRefs = function(refs)
                metadataCalls = metadataCalls + 1
                local result = {}
                for index = 1, #refs do
                    local row = rows[refs[index]]
                    if row then
                        result[#result + 1] = row
                    end
                end
                return result
            end,
            GetResolvedSkillRow = function(ref)
                resolvedRowCalls = resolvedRowCalls + 1
                return rows[ref]
            end,
            GetResolvedSkillRowsByRefs = function(refs)
                resolvedBatchCalls = resolvedBatchCalls + 1
                local result = {}
                for index = 1, #refs do
                    result[#result + 1] = rows[refs[index]]
                end
                return result
            end,
            GetResolvedWeaponSkillRowsByWeaponType = function()
                return {}
            end,
            GetSkillMetadataByWeaponType = function()
                return {
                    ["weapon:sword"] = { rows["skills:sword"] },
                    ["weapon:axe"] = { rows["skills:axe"] },
                }
            end,
            GetSkillLevel = function(ref)
                return rows[ref] and rows[ref].storedValue or 0
            end,
            SetSkillLevel = function(ref, value)
                setCalls = setCalls + 1
                rows[ref].storedValue = value
                return value
            end,
        },
        Ruleset = {
            GetActiveRuleset = function()
                return {}
            end,
            GetRulesetRuleDefinition = function()
                return nil
            end,
            GetRulesetRuleValue = function()
                return nil
            end,
        },
    },
    Utils = {
        Dice = {
            RollRandom = function()
                return 1
            end,
        },
    },
})

TestSupport.LoadAddonFile("client/client_SkillProgression.lua", Addon)
local progression = Addon.Client.SkillProgression

local result = progression:TryGain("skills:roll", "test", 0, nil)
assertEqual(result.reason, "chance-zero", "zero chance is rejected from metadata")
assertEqual(metadataCalls, 1, "zero chance uses the metadata lookup")
assertEqual(resolvedRowCalls, 0, "zero chance does not resolve a full skill row")

result = progression:TryGain("skills:roll", "test", 100, nil)
assertEqual(result.granted, true, "successful gain is granted")
assertEqual(metadataCalls, 2, "successful gain uses metadata before row resolution")
assertEqual(resolvedRowCalls, 1, "successful gain resolves one full skill row")
assertEqual(setCalls, 1, "successful gain persists once")

local resolvedRow = rows["skills:roll"]
result = progression:TryGain("skills:roll", "test", 100, nil, resolvedRow)
assertEqual(result.granted, true, "resolved row can be reused by the roll path")
assertEqual(resolvedRowCalls, 1, "reused resolved row avoids another full resolution")

local results = progression:TryGainWeaponSkillsForHit({
    eventState = { active = true },
    attackerUnit = { isPlayer = true, eventID = 7 },
    weaponSkillContext = {
        contributingWeapons = {
            { weaponTypeRef = "weapon:sword" },
            { weaponTypeRef = "weapon:axe" },
        },
    },
})
assertEqual(#results, 2, "weapon contributors produce two results")
assertEqual(resolvedBatchCalls, 1, "weapon contributors use one batched full resolution")
assertEqual(setCalls, 4, "each successful weapon contributor is persisted")
assertEqual(actionBarRefreshes, 4, "each successful gain refreshes the action bar")

print("SkillProgressionPerformanceTest passed")
