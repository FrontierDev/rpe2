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
        id = "ln12wms9",
        inputs = {
            {
                itemRef = "538a54a0:55k8gjup",
                kind = "rpe_item",
                quantity = 8,
            },
            {
                itemRef = "538a54a0:9vp6roos",
                kind = "rpe_item",
                quantity = 1,
            },
        },
        learnMode = "trainer",
        name = "Green Whelp Bracers",
        output = {
            itemRef = "538a54a0:8rdifxt5",
            maxQuantity = 1,
            minQuantity = 1,
        },
        reagents = {},
        requiredSkillLevel = 190,
        results = {},
        skillRef = "f82db71a:x9qez6bu",
        tags = {},
        trainerCostCopper = 63155,
    },
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
        id = "yyd0yjsb",
        inputs = {
            {
                itemRef = "538a54a0:55k8gjup",
                kind = "rpe_item",
                quantity = 14,
            },
            {
                itemRef = "61fdf3df:ov027km6",
                kind = "rpe_item",
                quantity = 1,
            },
        },
        learnMode = "trainer",
        name = "Barbaric Belt",
        output = {
            itemRef = "538a54a0:0lboph96",
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
        id = "jf0j3x6w",
        inputs = {
            {
                itemRef = "538a54a0:55k8gjup",
                kind = "rpe_item",
                quantity = 20,
            },
        },
        learnMode = "trainer",
        name = "Comfortable Leather Hat",
        output = {
            itemRef = "538a54a0:zxaispjx",
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
        id = "fdm1u0ed",
        inputs = {
            {
                itemRef = "538a54a0:55k8gjup",
                kind = "rpe_item",
                quantity = 8,
            },
            {
                itemRef = "538a54a0:u0wy9jz1",
                kind = "rpe_item",
                quantity = 8,
            },
        },
        learnMode = "trainer",
        name = "Dusky Boots",
        output = {
            itemRef = "538a54a0:kh5as5nc",
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
        id = "qkffy7be",
        inputs = {
            {
                itemRef = "538a54a0:55k8gjup",
                kind = "rpe_item",
                quantity = 10,
            },
        },
        learnMode = "trainer",
        name = "Swift Boots",
        output = {
            itemRef = "538a54a0:xwmucx64",
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
        id = "aru40ght",
        inputs = {
            {
                itemRef = "538a54a0:u0wy9jz1",
                kind = "rpe_item",
                quantity = 14,
            },
        },
        learnMode = "trainer",
        name = "Turtle Scale Gloves",
        output = {
            itemRef = "538a54a0:alwzv0yi",
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
        id = "6npqubrj",
        inputs = {
            {
                itemRef = "538a54a0:u0wy9jz1",
                kind = "rpe_item",
                quantity = 7,
            },
        },
        learnMode = "trainer",
        name = "Nightscape Tunic",
        output = {
            itemRef = "538a54a0:bp7hqyc1",
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
        id = "3oo6sxuy",
        inputs = {
            {
                itemRef = "538a54a0:u0wy9jz1",
                kind = "rpe_item",
                quantity = 8,
            },
        },
        learnMode = "trainer",
        name = "Nightscape Shoulders",
        output = {
            itemRef = "538a54a0:bhfwi0g1",
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
