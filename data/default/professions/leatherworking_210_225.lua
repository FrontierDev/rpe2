local _, Addon = ...

local definitions = Addon.Data and Addon.Data.DefaultDatasets and Addon.Data.DefaultDatasets.Definitions or nil
local definition = definitions and definitions["538a54a0"] or nil
if type(definition) ~= "table" or type(definition.dataset) ~= "table" then
    error("Leatherworking default dataset must be registered before loading this recipe extension.")
end

local dataset = definition.dataset
dataset.recipes = dataset.recipes or {}

local recipeUpdates = {
    {
        category = "",
        description = "",
        id = "7bbvb9l0",
        inputs = {
            {
                itemRef = "538a54a0:u0wy9jz1",
                kind = "rpe_item",
                quantity = 5,
            },
        },
        learnMode = "trainer",
        name = "Nightscape Headband",
        output = {
            itemRef = "538a54a0:znxtc7he",
            maxQuantity = 1,
            minQuantity = 1,
        },
        reagents = {},
        requiredSkillLevel = 205,
        results = {},
        skillRef = "f82db71a:x9qez6bu",
        tags = {},
        trainerCostCopper = 73055,
    },
    {
        category = "",
        description = "",
        id = "q2h9kugh",
        inputs = {
            {
                itemRef = "538a54a0:u0wy9jz1",
                kind = "rpe_item",
                quantity = 20,
            },
        },
        learnMode = "trainer",
        name = "Turtle Scale Bracers",
        output = {
            itemRef = "538a54a0:bq7947yq",
            maxQuantity = 1,
            minQuantity = 1,
        },
        reagents = {},
        requiredSkillLevel = 210,
        results = {},
        skillRef = "f82db71a:x9qez6bu",
        tags = {},
        trainerCostCopper = 76515,
    },
    {
        category = "",
        description = "",
        id = "r9u3ezse",
        inputs = {
            {
                itemRef = "538a54a0:u0wy9jz1",
                kind = "rpe_item",
                quantity = 18,
            },
        },
        learnMode = "trainer",
        name = "Turtle Scale Breastplate",
        output = {
            itemRef = "538a54a0:jlnq2160",
            maxQuantity = 1,
            minQuantity = 1,
        },
        reagents = {},
        requiredSkillLevel = 210,
        results = {},
        skillRef = "f82db71a:x9qez6bu",
        tags = {},
        trainerCostCopper = 76515,
    },
    {
        category = "",
        description = "",
        id = "n8m9etlq",
        inputs = {
            {
                itemRef = "538a54a0:u0wy9jz1",
                kind = "rpe_item",
                quantity = 10,
            },
        },
        learnMode = "trainer",
        name = "Big Voodoo Robe",
        output = {
            itemRef = "538a54a0:n9lzzkem",
            maxQuantity = 1,
            minQuantity = 1,
        },
        reagents = {},
        requiredSkillLevel = 215,
        results = {},
        skillRef = "f82db71a:x9qez6bu",
        tags = {},
        trainerCostCopper = 80055,
    },
    {
        category = "",
        description = "",
        id = "gjq6rolm",
        inputs = {
            {
                itemRef = "538a54a0:u0wy9jz1",
                kind = "rpe_item",
                quantity = 8,
            },
        },
        learnMode = "trainer",
        name = "Big Voodoo Mask",
        output = {
            itemRef = "538a54a0:ctzht4zc",
            maxQuantity = 1,
            minQuantity = 1,
        },
        reagents = {},
        requiredSkillLevel = 220,
        results = {},
        skillRef = "f82db71a:x9qez6bu",
        tags = {},
        trainerCostCopper = 83675,
    },
    {
        category = "",
        description = "",
        id = "bpqp64ev",
        inputs = {
            {
                itemRef = "538a54a0:u0wy9jz1",
                kind = "rpe_item",
                quantity = 14,
            },
        },
        learnMode = "trainer",
        name = "Tough Scorpid Bracers",
        output = {
            itemRef = "538a54a0:riyhi71p",
            maxQuantity = 1,
            minQuantity = 1,
        },
        reagents = {},
        requiredSkillLevel = 220,
        results = {},
        skillRef = "f82db71a:x9qez6bu",
        tags = {},
        trainerCostCopper = 83675,
    },
    {
        category = "",
        description = "",
        id = "klt42m3d",
        inputs = {
            {
                itemRef = "538a54a0:u0wy9jz1",
                kind = "rpe_item",
                quantity = 24,
            },
        },
        learnMode = "trainer",
        name = "Tough Scorpid Breastplate",
        output = {
            itemRef = "538a54a0:aku0bj87",
            maxQuantity = 1,
            minQuantity = 1,
        },
        reagents = {},
        requiredSkillLevel = 220,
        results = {},
        skillRef = "f82db71a:x9qez6bu",
        tags = {},
        trainerCostCopper = 83675,
    },
    {
        category = "",
        description = "",
        id = "9nhuou23",
        inputs = {
            {
                itemRef = "538a54a0:u0wy9jz1",
                kind = "rpe_item",
                quantity = 14,
            },
        },
        learnMode = "trainer",
        name = "Wild Leather Shoulders",
        output = {
            itemRef = "538a54a0:qfmdvqn9",
            maxQuantity = 1,
            minQuantity = 1,
        },
        reagents = {},
        requiredSkillLevel = 220,
        results = {},
        skillRef = "f82db71a:x9qez6bu",
        tags = {},
        trainerCostCopper = 83675,
    },
    {
        category = "",
        description = "",
        id = "49lnm4es",
        inputs = {
            {
                itemRef = "538a54a0:u0wy9jz1",
                kind = "rpe_item",
                quantity = 14,
            },
        },
        learnMode = "trainer",
        name = "Tough Scorpid Gloves",
        output = {
            itemRef = "538a54a0:pou2vmn4",
            maxQuantity = 1,
            minQuantity = 1,
        },
        reagents = {},
        requiredSkillLevel = 225,
        results = {},
        skillRef = "f82db71a:x9qez6bu",
        tags = {},
        trainerCostCopper = 87375,
    },
    {
        category = "",
        description = "",
        id = "ka863p8y",
        inputs = {
            {
                itemRef = "538a54a0:u0wy9jz1",
                kind = "rpe_item",
                quantity = 16,
            },
        },
        learnMode = "trainer",
        name = "Wild Leather Vest",
        output = {
            itemRef = "538a54a0:xaci9gkt",
            maxQuantity = 1,
            minQuantity = 1,
        },
        reagents = {},
        requiredSkillLevel = 225,
        results = {},
        skillRef = "f82db71a:x9qez6bu",
        tags = {},
        trainerCostCopper = 87375,
    },
    {
        category = "",
        description = "",
        id = "zy896fsa",
        inputs = {
            {
                itemRef = "538a54a0:u0wy9jz1",
                kind = "rpe_item",
                quantity = 14,
            },
        },
        learnMode = "trainer",
        name = "Wild Leather Helmet",
        output = {
            itemRef = "538a54a0:ws0amunv",
            maxQuantity = 1,
            minQuantity = 1,
        },
        reagents = {},
        requiredSkillLevel = 225,
        results = {},
        skillRef = "f82db71a:x9qez6bu",
        tags = {},
        trainerCostCopper = 87375,
    },
    {
        category = "",
        description = "",
        id = "lkjl70vm",
        inputs = {
            {
                itemRef = "538a54a0:u0wy9jz1",
                kind = "rpe_item",
                quantity = 44,
            },
        },
        learnMode = "trainer",
        name = "Dragonscale Gauntlets",
        output = {
            itemRef = "538a54a0:3a4bi80s",
            maxQuantity = 1,
            minQuantity = 1,
        },
        reagents = {},
        requiredSkillLevel = 225,
        results = {},
        skillRef = "f82db71a:x9qez6bu",
        tags = {},
        trainerCostCopper = 87375,
    },
    {
        category = "",
        description = "",
        id = "8osam5m8",
        inputs = {
            {
                itemRef = "538a54a0:u0wy9jz1",
                kind = "rpe_item",
                quantity = 34,
            },
        },
        learnMode = "trainer",
        name = "Wolfshead Helm",
        output = {
            itemRef = "538a54a0:dibi20pl",
            maxQuantity = 1,
            minQuantity = 1,
        },
        reagents = {},
        requiredSkillLevel = 225,
        results = {},
        skillRef = "f82db71a:x9qez6bu",
        tags = {},
        trainerCostCopper = 87375,
    },
}
local function matches(existing, update)
    local updateId = tostring(update and update.id or "")
    local existingId = tostring(existing and existing.id or "")
    if updateId ~= "" and existingId == updateId then
        return true
    end
    local updateName = tostring(update and update.name or "")
    return updateName ~= "" and tostring(existing and existing.name or "") == updateName
end

for updateIndex = 1, #recipeUpdates do
    local update = recipeUpdates[updateIndex]
    local replaced = false
    for recipeIndex = 1, #dataset.recipes do
        if matches(dataset.recipes[recipeIndex], update) then
            dataset.recipes[recipeIndex] = update
            replaced = true
            break
        end
    end
    if not replaced then
        dataset.recipes[#dataset.recipes + 1] = update
    end
end
