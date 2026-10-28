local function assertEqual(actual, expected, message)
    if actual ~= expected then
        error(("%s: expected %s, got %s"):format(message, tostring(expected), tostring(actual)), 2)
    end
end

local TestSupport = dofile("tests/support/RuntimeStubs.lua")
local Addon = TestSupport.CreateAddon({
    Client = {
        Inventory = {
            GetItems = function()
                return {}
            end,
            RegisterChangeListener = function()
                return 1
            end,
        },
    },
    Internal = {
        Database = {
            GetActiveProfile = function()
                return { characterKey = "crafting-skill-test" }
            end,
        },
        Profile = {},
        Registry = {},
        Tasks = {},
    },
    Utils = {
        Common = {},
    },
})

TestSupport.LoadAddonFile("client/client_Crafting.lua", Addon)
local Crafting = Addon.Client.Crafting

local function detail(skillLevel, requiredLevel, skillCap)
    return {
        recipeRef = "recipes:boundary",
        skillLevel = skillLevel,
        requiredSkillLevel = requiredLevel,
        skillCap = skillCap,
        isKnown = true,
        isSkillMet = (tonumber(skillLevel) or 0) >= (tonumber(requiredLevel) or 0),
    }
end

local cases = {
    { name = "below required", detail = detail(9, 10, 100), chance = 0, band = "unavailable" },
    { name = "exactly required", detail = detail(10, 10, 100), chance = 100, band = "orange" },
    { name = "orange upper boundary", detail = detail(20, 10, 100), chance = 100, band = "orange" },
    { name = "yellow lower boundary", detail = detail(21, 10, 100), chance = 75, band = "yellow" },
    { name = "yellow upper boundary", detail = detail(30, 10, 100), chance = 75, band = "yellow" },
    { name = "green lower boundary", detail = detail(31, 10, 100), chance = 35, band = "green" },
    { name = "green upper boundary", detail = detail(35, 10, 100), chance = 35, band = "green" },
    { name = "grey lower boundary", detail = detail(36, 10, 100), chance = 0, band = "grey" },
    { name = "at cap", detail = detail(100, 10, 100), chance = 0, band = "capped" },
    { name = "above cap", detail = detail(101, 10, 100), chance = 0, band = "capped" },
    { name = "unlearned", detail = detail(10, 10, 100), chance = 0, band = "unavailable", isKnown = false },
    { name = "missing required level", detail = detail(0, nil, 100), chance = 100, band = "orange" },
    { name = "zero required level trivial", detail = detail(26, 0, 100), chance = 0, band = "grey" },
}

for index = 1, #cases do
    local testCase = cases[index]
    if testCase.isKnown == false then
        testCase.detail.isKnown = false
    end
    local info = Crafting:GetRecipeSkillUpInfo(testCase.detail)
    assertEqual(info.chance, testCase.chance, testCase.name .. " chance")
    assertEqual(info.band, testCase.band, testCase.name .. " band")
    assertEqual(Crafting:GetRecipeSkillUpChance(testCase.detail), testCase.chance,
        testCase.name .. " public chance matches shared result")
end

print("CraftingSkillUpChanceTest passed")
