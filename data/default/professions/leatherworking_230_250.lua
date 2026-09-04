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
        id = "59k34zl0",
        inputs = {
            {
                itemRef = "538a54a0:u0wy9jz1",
                kind = "rpe_item",
                quantity = 38,
            },
            {
                itemRef = "538a54a0:55k8gjup",
                kind = "rpe_item",
                quantity = 8,
            },
            {
                itemRef = "4999dcec:6b4o47go",
                kind = "rpe_item",
                quantity = 2,
            },
            {
                itemRef = "4999dcec:l3c8nzh7",
                kind = "rpe_item",
                quantity = 4,
            },
        },
        learnMode = "trainer",
        name = "Shadowskin Gloves",
        output = {
            itemRef = "538a54a0:lu2f3kfd",
            maxQuantity = 1,
            minQuantity = 1,
        },
        reagents = {},
        requiredSkillLevel = 200,
        results = {},
        skillRef = "f82db71a:x9qez6bu",
        tags = {},
        trainerCostCopper = 69675,
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
            {
                itemRef = "3eb7e9bb:2hbdmyj4",
                kind = "rpe_item",
                quantity = 1,
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
        id = "ka863p8y",
        inputs = {
            {
                itemRef = "538a54a0:u0wy9jz1",
                kind = "rpe_item",
                quantity = 16,
            },
            {
                itemRef = "3eb7e9bb:2hbdmyj4",
                kind = "rpe_item",
                quantity = 2,
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
            {
                itemRef = "3eb7e9bb:2hbdmyj4",
                kind = "rpe_item",
                quantity = 2,
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
                quantity = 32,
            },
            {
                itemRef = "538a54a0:wd5k2n7q",
                kind = "rpe_item",
                quantity = 12,
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
        id = "j7qm2v5x",
        inputs = {
            {
                itemRef = "538a54a0:u0wy9jz1",
                kind = "rpe_item",
                quantity = 14,
            },
        },
        learnMode = "trainer",
        name = "Nightscape Pants",
        output = {
            itemRef = "538a54a0:k8j2vh4m",
            maxQuantity = 1,
            minQuantity = 1,
        },
        reagents = {},
        requiredSkillLevel = 230,
        results = {},
        skillRef = "f82db71a:x9qez6bu",
        tags = {},
        trainerCostCopper = 91155,
    },
    {
        category = "",
        description = "",
        id = "r4ck8n1p",
        inputs = {
            {
                itemRef = "538a54a0:u0wy9jz1",
                kind = "rpe_item",
                quantity = 38,
            },
        },
        learnMode = "trainer",
        name = "Turtle Scale Helm",
        output = {
            itemRef = "538a54a0:rq6b9x2c",
            maxQuantity = 1,
            minQuantity = 1,
        },
        reagents = {},
        requiredSkillLevel = 230,
        results = {},
        skillRef = "f82db71a:x9qez6bu",
        tags = {},
        trainerCostCopper = 91155,
    },
    {
        category = "",
        description = "",
        id = "z2wh6f9m",
        inputs = {
            {
                itemRef = "538a54a0:u0wy9jz1",
                kind = "rpe_item",
                quantity = 24,
            },
            {
                itemRef = "732368d4:vlwvpmfx",
                kind = "rpe_item",
                quantity = 8,
            },
            {
                itemRef = "732368d4:ku9j8vhw",
                kind = "rpe_item",
                quantity = 2,
            },
        },
        learnMode = "trainer",
        name = "Gauntlets of the Sea",
        output = {
            itemRef = "538a54a0:m3fp7zq1",
            maxQuantity = 1,
            minQuantity = 1,
        },
        reagents = {},
        requiredSkillLevel = 230,
        results = {},
        skillRef = "f82db71a:x9qez6bu",
        tags = {},
        trainerCostCopper = 91155,
    },
    {
        category = "",
        description = "",
        id = "c5tb9x3q",
        inputs = {
            {
                itemRef = "538a54a0:u0wy9jz1",
                kind = "rpe_item",
                quantity = 16,
            },
        },
        learnMode = "trainer",
        name = "Nightscape Boots",
        output = {
            itemRef = "538a54a0:v7cn4j2s",
            maxQuantity = 1,
            minQuantity = 1,
        },
        reagents = {},
        requiredSkillLevel = 235,
        results = {},
        skillRef = "f82db71a:x9qez6bu",
        tags = {},
        trainerCostCopper = 95015,
    },
    {
        category = "",
        description = "",
        id = "m8pk1d6v",
        inputs = {
            {
                itemRef = "538a54a0:u0wy9jz1",
                kind = "rpe_item",
                quantity = 42,
            },
        },
        learnMode = "trainer",
        name = "Turtle Scale Leggings",
        output = {
            itemRef = "538a54a0:h5kw8p3d",
            maxQuantity = 1,
            minQuantity = 1,
        },
        reagents = {},
        requiredSkillLevel = 235,
        results = {},
        skillRef = "f82db71a:x9qez6bu",
        tags = {},
        trainerCostCopper = 95015,
    },
    {
        category = "",
        description = "",
        id = "q6nr4y2h",
        inputs = {
            {
                itemRef = "538a54a0:u0wy9jz1",
                kind = "rpe_item",
                quantity = 24,
            },
        },
        learnMode = "trainer",
        name = "Tough Scorpid Boots",
        output = {
            itemRef = "538a54a0:t2gx9m6r",
            maxQuantity = 1,
            minQuantity = 1,
        },
        reagents = {},
        requiredSkillLevel = 235,
        results = {},
        skillRef = "f82db71a:x9qez6bu",
        tags = {},
        trainerCostCopper = 95015,
    },
    {
        category = "",
        description = "",
        id = "v3hs7k8e",
        inputs = {
            {
                itemRef = "538a54a0:u0wy9jz1",
                kind = "rpe_item",
                quantity = 10,
            },
        },
        learnMode = "trainer",
        name = "Big Voodoo Pants",
        output = {
            itemRef = "538a54a0:b4ny7q1e",
            maxQuantity = 1,
            minQuantity = 1,
        },
        reagents = {},
        requiredSkillLevel = 240,
        results = {},
        skillRef = "f82db71a:x9qez6bu",
        tags = {},
        trainerCostCopper = 98955,
    },
    {
        category = "",
        description = "",
        id = "x9fj2m5a",
        inputs = {
            {
                itemRef = "538a54a0:u0wy9jz1",
                kind = "rpe_item",
                quantity = 14,
            },
        },
        learnMode = "trainer",
        name = "Big Voodoo Cloak",
        output = {
            itemRef = "538a54a0:c8pv3k5a",
            maxQuantity = 1,
            minQuantity = 1,
        },
        reagents = {},
        requiredSkillLevel = 240,
        results = {},
        skillRef = "f82db71a:x9qez6bu",
        tags = {},
        trainerCostCopper = 98955,
    },
    {
        category = "",
        description = "",
        id = "b7qw1t4n",
        inputs = {
            {
                itemRef = "538a54a0:u0wy9jz1",
                kind = "rpe_item",
                quantity = 28,
            },
        },
        learnMode = "trainer",
        name = "Tough Scorpid Shoulders",
        output = {
            itemRef = "538a54a0:u6mf2z9w",
            maxQuantity = 1,
            minQuantity = 1,
        },
        reagents = {},
        requiredSkillLevel = 240,
        results = {},
        skillRef = "f82db71a:x9qez6bu",
        tags = {},
        trainerCostCopper = 98955,
    },
    {
        category = "",
        description = "",
        id = "h2vc8r6k",
        inputs = {
            {
                itemRef = "538a54a0:u0wy9jz1",
                kind = "rpe_item",
                quantity = 22,
            },
            {
                itemRef = "3eb7e9bb:2hbdmyj4",
                kind = "rpe_item",
                quantity = 4,
            },
        },
        learnMode = "trainer",
        name = "Wild Leather Boots",
        output = {
            itemRef = "538a54a0:e3jr8x4n",
            maxQuantity = 1,
            minQuantity = 1,
        },
        reagents = {},
        requiredSkillLevel = 245,
        results = {},
        skillRef = "f82db71a:x9qez6bu",
        tags = {},
        trainerCostCopper = 102975,
    },
    {
        category = "",
        description = "",
        id = "n5mz3p9w",
        inputs = {
            {
                itemRef = "538a54a0:u0wy9jz1",
                kind = "rpe_item",
                quantity = 22,
            },
        },
        learnMode = "trainer",
        name = "Tough Scorpid Leggings",
        output = {
            itemRef = "538a54a0:p7hd5v2q",
            maxQuantity = 1,
            minQuantity = 1,
        },
        reagents = {},
        requiredSkillLevel = 245,
        results = {},
        skillRef = "f82db71a:x9qez6bu",
        tags = {},
        trainerCostCopper = 102975,
    },
    {
        category = "",
        description = "",
        id = "p1gx7c4j",
        inputs = {
            {
                itemRef = "538a54a0:u0wy9jz1",
                kind = "rpe_item",
                quantity = 30,
            },
        },
        learnMode = "trainer",
        name = "Tough Scorpid Helm",
        output = {
            itemRef = "538a54a0:g9sk1m6c",
            maxQuantity = 1,
            minQuantity = 1,
        },
        reagents = {},
        requiredSkillLevel = 250,
        results = {},
        skillRef = "f82db71a:x9qez6bu",
        tags = {},
        trainerCostCopper = 107075,
    },
    {
        category = "",
        description = "",
        id = "s8kr2v5d",
        inputs = {
            {
                itemRef = "538a54a0:u0wy9jz1",
                kind = "rpe_item",
                quantity = 24,
            },
            {
                itemRef = "3eb7e9bb:2hbdmyj4",
                kind = "rpe_item",
                quantity = 6,
            },
        },
        learnMode = "trainer",
        name = "Wild Leather Leggings",
        output = {
            itemRef = "538a54a0:w4zt8r3b",
            maxQuantity = 1,
            minQuantity = 1,
        },
        reagents = {},
        requiredSkillLevel = 250,
        results = {},
        skillRef = "f82db71a:x9qez6bu",
        tags = {},
        trainerCostCopper = 107075,
    },
    {
        category = "",
        description = "",
        id = "u4bn9h1q",
        inputs = {
            {
                itemRef = "538a54a0:u0wy9jz1",
                kind = "rpe_item",
                quantity = 24,
            },
            {
                itemRef = "3eb7e9bb:2hbdmyj4",
                kind = "rpe_item",
                quantity = 6,
            },
        },
        learnMode = "trainer",
        name = "Wild Leather Cloak",
        output = {
            itemRef = "538a54a0:a2vx6n9j",
            maxQuantity = 1,
            minQuantity = 1,
        },
        reagents = {},
        requiredSkillLevel = 250,
        results = {},
        skillRef = "f82db71a:x9qez6bu",
        tags = {},
        trainerCostCopper = 107075,
    },
    {
        category = "",
        description = "",
        id = "y6td3m8f",
        inputs = {
            {
                itemRef = "538a54a0:u0wy9jz1",
                kind = "rpe_item",
                quantity = 48,
            },
            {
                itemRef = "732368d4:sclalidn",
                kind = "rpe_item",
                quantity = 8,
            },
            {
                itemRef = "732368d4:ku9j8vhw",
                kind = "rpe_item",
                quantity = 4,
            },
        },
        learnMode = "trainer",
        name = "Helm of Fire",
        output = {
            itemRef = "538a54a0:f5qc7k1u",
            maxQuantity = 1,
            minQuantity = 1,
        },
        reagents = {},
        requiredSkillLevel = 250,
        results = {},
        skillRef = "f82db71a:x9qez6bu",
        tags = {},
        trainerCostCopper = 107075,
    },
    {
        category = "",
        description = "",
        id = "e9wp5k2r",
        inputs = {
            {
                itemRef = "538a54a0:u0wy9jz1",
                kind = "rpe_item",
                quantity = 56,
            },
            {
                itemRef = "4999dcec:6b4o47go",
                kind = "rpe_item",
                quantity = 2,
            },
        },
        learnMode = "trainer",
        name = "Feathered Breastplate",
        output = {
            itemRef = "538a54a0:d8mp3h4y",
            maxQuantity = 1,
            minQuantity = 1,
        },
        reagents = {},
        requiredSkillLevel = 250,
        results = {},
        skillRef = "f82db71a:x9qez6bu",
        tags = {},
        trainerCostCopper = 107075,
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
