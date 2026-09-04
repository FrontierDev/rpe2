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
        id = "6038aq60",
        inputs = {
            {
                itemRef = "538a54a0:4gnkyr9f",
                kind = "rpe_item",
                quantity = 8,
            },
        },
        name = "Wicked Leather Bracers",
        output = {
            itemRef = "538a54a0:b1fmw5tb",
            maxQuantity = 1,
            minQuantity = 1,
        },
        reagents = {},
        requiredSkillLevel = 265,
        results = {},
        skillRef = "f82db71a:x9qez6bu",
        tags = {},
        trainerCostCopper = 119855,
    },
    {
        category = "",
        description = "",
        id = "6aokease",
        inputs = {
            {
                itemRef = "538a54a0:4gnkyr9f",
                kind = "rpe_item",
                quantity = 8,
            },
        },
        name = "Wicked Leather Gauntlets",
        output = {
            itemRef = "538a54a0:0bnp5n0m",
            maxQuantity = 1,
            minQuantity = 1,
        },
        reagents = {},
        requiredSkillLevel = 260,
        results = {},
        skillRef = "f82db71a:x9qez6bu",
        tags = {},
        trainerCostCopper = 115515,
    },
    {
        category = "",
        description = "",
        id = "y0sijcyd",
        inputs = {
            {
                itemRef = "538a54a0:4gnkyr9f",
                kind = "rpe_item",
                quantity = 8,
            },
        },
        learnMode = "trainer",
        name = "Heavy Scorpid Bracers",
        output = {
            itemRef = "538a54a0:eo5iira2",
            maxQuantity = 1,
            minQuantity = 1,
        },
        reagents = {},
        requiredSkillLevel = 255,
        results = {},
        skillRef = "f82db71a:x9qez6bu",
        tags = {},
        trainerCostCopper = 111255,
    },
    {
        category = "",
        description = "",
        id = "x5u9d1n2",
        inputs = {
            {
                itemRef = "538a54a0:u0wy9jz1",
                kind = "rpe_item",
                quantity = 56,
            },
            {
                itemRef = "538a54a0:wd5k2n7q",
                kind = "rpe_item",
                quantity = 30,
            },
        },
        learnMode = "trainer",
        name = "Dragonscale Breastplate",
        output = {
            itemRef = "538a54a0:8l5byojg",
            maxQuantity = 1,
            minQuantity = 1,
        },
        reagents = {},
        requiredSkillLevel = 255,
        results = {},
        skillRef = "f82db71a:x9qez6bu",
        tags = {},
        trainerCostCopper = 111255,
    },
    {
        category = "",
        description = "",
        id = "pjj8djmq",
        inputs = {
            {
                itemRef = "538a54a0:4gnkyr9f",
                kind = "rpe_item",
                quantity = 20,
            },
            {
                itemRef = "538a54a0:9vp6roos",
                kind = "rpe_item",
                quantity = 25,
            },
        },
        learnMode = "trainer",
        name = "Green Dragonscale Breastplate",
        output = {
            itemRef = "538a54a0:a2b45s22",
            maxQuantity = 1,
            minQuantity = 1,
        },
        reagents = {},
        requiredSkillLevel = 260,
        results = {},
        skillRef = "f82db71a:x9qez6bu",
        tags = {},
        trainerCostCopper = 115515,
    },
    {
        category = "",
        description = "",
        id = "iecknb7y",
        inputs = {
            {
                itemRef = "538a54a0:4gnkyr9f",
                kind = "rpe_item",
                quantity = 12,
            },
        },
        learnMode = "trainer",
        name = "Chimeric Gloves",
        output = {
            itemRef = "538a54a0:sm7pymht",
            maxQuantity = 1,
            minQuantity = 1,
        },
        reagents = {},
        requiredSkillLevel = 265,
        results = {},
        skillRef = "f82db71a:x9qez6bu",
        tags = {},
        trainerCostCopper = 119855,
    },
    {
        category = "",
        description = "",
        id = "pbk8u14g",
        inputs = {
            {
                itemRef = "538a54a0:4gnkyr9f",
                kind = "rpe_item",
                quantity = 12,
            },
        },
        learnMode = "trainer",
        name = "Heavy Scorpid Vest",
        output = {
            itemRef = "538a54a0:5us114e3",
            maxQuantity = 1,
            minQuantity = 1,
        },
        reagents = {},
        requiredSkillLevel = 265,
        results = {},
        skillRef = "f82db71a:x9qez6bu",
        tags = {},
        trainerCostCopper = 119855,
    },
    {
        category = "",
        description = "",
        id = "i5e4ona0",
        inputs = {
            {
                itemRef = "538a54a0:4gnkyr9f",
                kind = "rpe_item",
                quantity = 10,
            },
        },
        learnMode = "trainer",
        name = "Runic Leather Gauntlets",
        output = {
            itemRef = "538a54a0:pq3fcbga",
            maxQuantity = 1,
            minQuantity = 1,
        },
        reagents = {},
        requiredSkillLevel = 270,
        results = {},
        skillRef = "f82db71a:x9qez6bu",
        tags = {},
        trainerCostCopper = 124275,
    },
    {
        category = "",
        description = "",
        id = "5bn80xh5",
        inputs = {
            {
                itemRef = "538a54a0:4gnkyr9f",
                kind = "rpe_item",
                quantity = 20,
            },
            {
                itemRef = "538a54a0:9vp6roos",
                kind = "rpe_item",
                quantity = 25,
            },
        },
        learnMode = "trainer",
        name = "Green Dragonscale Leggings",
        output = {
            itemRef = "538a54a0:8ei6gxrk",
            maxQuantity = 1,
            minQuantity = 1,
        },
        reagents = {},
        requiredSkillLevel = 270,
        results = {},
        skillRef = "f82db71a:x9qez6bu",
        tags = {},
        trainerCostCopper = 124275,
    },
    {
        category = "",
        description = "",
        id = "7ly5zi5s",
        inputs = {
            {
                itemRef = "538a54a0:4gnkyr9f",
                kind = "rpe_item",
                quantity = 12,
            },
            {
                itemRef = "732368d4:lxqnh3pp",
                kind = "rpe_item",
                quantity = 4,
            },
        },
        learnMode = "trainer",
        name = "Living Shoulders",
        output = {
            itemRef = "538a54a0:lwysa14u",
            maxQuantity = 1,
            minQuantity = 1,
        },
        reagents = {},
        requiredSkillLevel = 270,
        results = {},
        skillRef = "f82db71a:x9qez6bu",
        tags = {},
        trainerCostCopper = 124275,
    },
    {
        category = "",
        description = "",
        id = "cup9drtq",
        inputs = {
            {
                itemRef = "538a54a0:4gnkyr9f",
                kind = "rpe_item",
                quantity = 6,
            },
            {
                itemRef = "732368d4:sclalidn",
                kind = "rpe_item",
                quantity = 1,
            },
            {
                itemRef = "732368d4:ku9j8vhw",
                kind = "rpe_item",
                quantity = 1,
            },
        },
        learnMode = "trainer",
        name = "Volcanic Leggings",
        output = {
            itemRef = "538a54a0:6ej1bpa6",
            maxQuantity = 1,
            minQuantity = 1,
        },
        reagents = {},
        requiredSkillLevel = 270,
        results = {},
        skillRef = "f82db71a:x9qez6bu",
        tags = {},
        trainerCostCopper = 124275,
    },
    {
        category = "",
        description = "",
        id = "n5k9uzfn",
        inputs = {
            {
                itemRef = "538a54a0:4gnkyr9f",
                kind = "rpe_item",
                quantity = 24,
            },
            {
                itemRef = "4999dcec:qgjc3m5m",
                kind = "rpe_item",
                quantity = 2,
            },
        },
        learnMode = "trainer",
        name = "Ironfeather Shoulders",
        output = {
            itemRef = "538a54a0:2op3v3cw",
            maxQuantity = 1,
            minQuantity = 1,
        },
        reagents = {},
        requiredSkillLevel = 270,
        results = {},
        skillRef = "f82db71a:x9qez6bu",
        tags = {},
        trainerCostCopper = 124275,
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
