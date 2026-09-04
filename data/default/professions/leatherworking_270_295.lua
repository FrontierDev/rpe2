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
        id = "dhvy1twu",
        inputs = {
            {
                itemRef = "538a54a0:4gnkyr9f",
                kind = "rpe_item",
                quantity = 12,
            },
        },
        name = "Wicked Leather Headband",
        output = {
            itemRef = "538a54a0:9ftjlomf",
            maxQuantity = 1,
            minQuantity = 1,
        },
        reagents = {},
        requiredSkillLevel = 280,
        results = {},
        skillRef = "f82db71a:x9qez6bu",
        tags = {},
        trainerCostCopper = 133355,
    },
    {
        category = "",
        description = "",
        id = "waagfwba",
        inputs = {
            {
                itemRef = "538a54a0:4gnkyr9f",
                kind = "rpe_item",
                quantity = 20,
            },
        },
        name = "Wicked Leather Pants",
        output = {
            itemRef = "538a54a0:ynfyug9o",
            maxQuantity = 1,
            minQuantity = 1,
        },
        reagents = {},
        requiredSkillLevel = 290,
        results = {},
        skillRef = "f82db71a:x9qez6bu",
        tags = {},
        trainerCostCopper = 142755,
    },
    {
        category = "",
        description = "",
        id = "xm8l9f5z",
        inputs = {
            {
                itemRef = "538a54a0:4gnkyr9f",
                kind = "rpe_item",
                quantity = 14,
            },
        },
        learnMode = "trainer",
        name = "Heavy Scorpid Gauntlet",
        output = {
            itemRef = "538a54a0:2q7dgadx",
            maxQuantity = 1,
            minQuantity = 1,
        },
        reagents = {},
        requiredSkillLevel = 275,
        results = {},
        skillRef = "f82db71a:x9qez6bu",
        tags = {},
        trainerCostCopper = 128775,
    },
    {
        category = "",
        description = "",
        id = "w4fgi0t2",
        inputs = {
            {
                itemRef = "538a54a0:4gnkyr9f",
                kind = "rpe_item",
                quantity = 6,
            },
            {
                itemRef = "4999dcec:6b4o47go",
                kind = "rpe_item",
                quantity = 1,
            },
        },
        learnMode = "trainer",
        name = "Runic Leather Bracers",
        output = {
            itemRef = "538a54a0:hclssw0e",
            maxQuantity = 1,
            minQuantity = 1,
        },
        reagents = {},
        requiredSkillLevel = 275,
        results = {},
        skillRef = "f82db71a:x9qez6bu",
        tags = {},
        trainerCostCopper = 128775,
    },
    {
        category = "",
        description = "",
        id = "uelugxmz",
        inputs = {
            {
                itemRef = "538a54a0:4gnkyr9f",
                kind = "rpe_item",
                quantity = 16,
            },
            {
                itemRef = "732368d4:vlwvpmfx",
                kind = "rpe_item",
                quantity = 2,
            },
            {
                itemRef = "732368d4:2616xh4v",
                kind = "rpe_item",
                quantity = 2,
            },
        },
        learnMode = "trainer",
        name = "Stormshroud Pants",
        output = {
            itemRef = "538a54a0:tmv0pu1u",
            maxQuantity = 1,
            minQuantity = 1,
        },
        reagents = {},
        requiredSkillLevel = 275,
        results = {},
        skillRef = "f82db71a:x9qez6bu",
        tags = {},
        trainerCostCopper = 128775,
    },
    {
        category = "",
        description = "",
        id = "vds6pvf4",
        inputs = {
            {
                itemRef = "538a54a0:4gnkyr9f",
                kind = "rpe_item",
                quantity = 40,
            },
        },
        learnMode = "trainer",
        name = "Warbear Harness",
        output = {
            itemRef = "538a54a0:9oubdxly",
            maxQuantity = 1,
            minQuantity = 1,
        },
        reagents = {},
        requiredSkillLevel = 275,
        results = {},
        skillRef = "f82db71a:x9qez6bu",
        tags = {},
        trainerCostCopper = 128775,
    },
    {
        category = "",
        description = "",
        id = "tp4yc2yk",
        inputs = {
            {
                itemRef = "538a54a0:4gnkyr9f",
                kind = "rpe_item",
                quantity = 24,
            },
            {
                itemRef = "538a54a0:9vp6roos",
                kind = "rpe_item",
                quantity = 30,
            },
        },
        learnMode = "trainer",
        name = "Green Dragonscale Gauntlets",
        output = {
            itemRef = "538a54a0:hiaxkufq",
            maxQuantity = 1,
            minQuantity = 1,
        },
        reagents = {},
        requiredSkillLevel = 280,
        results = {},
        skillRef = "f82db71a:x9qez6bu",
        tags = {},
        trainerCostCopper = 133355,
    },
    {
        category = "",
        description = "",
        id = "kmbe6hwp",
        inputs = {
            {
                itemRef = "538a54a0:4gnkyr9f",
                kind = "rpe_item",
                quantity = 14,
            },
        },
        learnMode = "trainer",
        name = "Heavy Scorpid Belt",
        output = {
            itemRef = "538a54a0:xvi3ut31",
            maxQuantity = 1,
            minQuantity = 1,
        },
        reagents = {},
        requiredSkillLevel = 280,
        results = {},
        skillRef = "f82db71a:x9qez6bu",
        tags = {},
        trainerCostCopper = 133355,
    },
    {
        category = "",
        description = "",
        id = "uriphvw2",
        inputs = {
            {
                itemRef = "538a54a0:4gnkyr9f",
                kind = "rpe_item",
                quantity = 12,
            },
        },
        learnMode = "trainer",
        name = "Runic Leather Belt",
        output = {
            itemRef = "538a54a0:03tc8aq5",
            maxQuantity = 1,
            minQuantity = 1,
        },
        reagents = {},
        requiredSkillLevel = 280,
        results = {},
        skillRef = "f82db71a:x9qez6bu",
        tags = {},
        trainerCostCopper = 133355,
    },
    {
        category = "",
        description = "",
        id = "rbenmzxp",
        inputs = {
            {
                itemRef = "538a54a0:4gnkyr9f",
                kind = "rpe_item",
                quantity = 32,
            },
            {
                itemRef = "538a54a0:n7ad1th5",
                kind = "rpe_item",
                quantity = 30,
            },
        },
        learnMode = "trainer",
        name = "Blue Dragonscale Breastplate",
        output = {
            itemRef = "538a54a0:ra69ai5u",
            maxQuantity = 1,
            minQuantity = 1,
        },
        reagents = {},
        requiredSkillLevel = 285,
        results = {},
        skillRef = "f82db71a:x9qez6bu",
        tags = {},
        trainerCostCopper = 138015,
    },
    {
        category = "",
        description = "",
        id = "i7lp9jtr",
        inputs = {
            {
                itemRef = "538a54a0:4gnkyr9f",
                kind = "rpe_item",
                quantity = 20,
            },
            {
                itemRef = "732368d4:lxqnh3pp",
                kind = "rpe_item",
                quantity = 6,
            },
        },
        learnMode = "trainer",
        name = "Living Leggings",
        output = {
            itemRef = "538a54a0:oewffbj4",
            maxQuantity = 1,
            minQuantity = 1,
        },
        reagents = {},
        requiredSkillLevel = 285,
        results = {},
        skillRef = "f82db71a:x9qez6bu",
        tags = {},
        trainerCostCopper = 138015,
    },
    {
        category = "",
        description = "",
        id = "akay3rx4",
        inputs = {
            {
                itemRef = "538a54a0:4gnkyr9f",
                kind = "rpe_item",
                quantity = 20,
            },
            {
                itemRef = "732368d4:vlwvpmfx",
                kind = "rpe_item",
                quantity = 3,
            },
            {
                itemRef = "732368d4:2616xh4v",
                kind = "rpe_item",
                quantity = 3,
            },
        },
        learnMode = "trainer",
        name = "Stormshroud Armor",
        output = {
            itemRef = "538a54a0:nanqe7nt",
            maxQuantity = 1,
            minQuantity = 1,
        },
        reagents = {},
        requiredSkillLevel = 285,
        results = {},
        skillRef = "f82db71a:x9qez6bu",
        tags = {},
        trainerCostCopper = 138015,
    },
    {
        category = "",
        description = "",
        id = "6xyq22ju",
        inputs = {
            {
                itemRef = "538a54a0:4gnkyr9f",
                kind = "rpe_item",
                quantity = 38,
            },
        },
        learnMode = "trainer",
        name = "Warbear Woolies",
        output = {
            itemRef = "538a54a0:l0m62g4z",
            maxQuantity = 1,
            minQuantity = 1,
        },
        reagents = {},
        requiredSkillLevel = 285,
        results = {},
        skillRef = "f82db71a:x9qez6bu",
        tags = {},
        trainerCostCopper = 138015,
    },
    {
        category = "",
        description = "",
        id = "xb3h5tvh",
        inputs = {
            {
                itemRef = "538a54a0:4gnkyr9f",
                kind = "rpe_item",
                quantity = 44,
            },
            {
                itemRef = "538a54a0:zocsjdj1",
                kind = "rpe_item",
                quantity = 60,
            },
        },
        learnMode = "trainer",
        name = "Black Dragonscale Breastplate",
        output = {
            itemRef = "538a54a0:bitqvvq4",
            maxQuantity = 1,
            minQuantity = 1,
        },
        reagents = {},
        requiredSkillLevel = 290,
        results = {},
        skillRef = "f82db71a:x9qez6bu",
        tags = {},
        trainerCostCopper = 142755,
    },
    {
        category = "",
        description = "",
        id = "33kc1u12",
        inputs = {
            {
                itemRef = "538a54a0:4gnkyr9f",
                kind = "rpe_item",
                quantity = 38,
            },
            {
                itemRef = "3eb7e9bb:hq608hly",
                kind = "rpe_item",
                quantity = 2,
            },
            {
                itemRef = "732368d4:vlwvpmfx",
                kind = "rpe_item",
                quantity = 4,
            },
        },
        learnMode = "trainer",
        name = "Dawn Treaders",
        output = {
            itemRef = "538a54a0:fvqbcdu6",
            maxQuantity = 1,
            minQuantity = 1,
        },
        reagents = {},
        requiredSkillLevel = 290,
        results = {},
        skillRef = "f82db71a:x9qez6bu",
        tags = {},
        trainerCostCopper = 142755,
    },
    {
        category = "",
        description = "",
        id = "lcwx2hvt",
        inputs = {
            {
                itemRef = "538a54a0:4gnkyr9f",
                kind = "rpe_item",
                quantity = 38,
            },
        },
        learnMode = "trainer",
        name = "Devilsaur Gauntlets",
        output = {
            itemRef = "538a54a0:ks88fs1b",
            maxQuantity = 1,
            minQuantity = 1,
        },
        reagents = {},
        requiredSkillLevel = 290,
        results = {},
        skillRef = "f82db71a:x9qez6bu",
        tags = {},
        trainerCostCopper = 142755,
    },
    {
        category = "",
        description = "",
        id = "s5mqalkw",
        inputs = {
            {
                itemRef = "538a54a0:4gnkyr9f",
                kind = "rpe_item",
                quantity = 44,
            },
            {
                itemRef = "4999dcec:qgjc3m5m",
                kind = "rpe_item",
                quantity = 1,
            },
        },
        learnMode = "trainer",
        name = "Ironfeather Breastplate",
        output = {
            itemRef = "538a54a0:x87dzazi",
            maxQuantity = 1,
            minQuantity = 1,
        },
        reagents = {},
        requiredSkillLevel = 290,
        results = {},
        skillRef = "f82db71a:x9qez6bu",
        tags = {},
        trainerCostCopper = 142755,
    },
    {
        category = "",
        description = "",
        id = "bnwh5pwg",
        inputs = {
            {
                itemRef = "538a54a0:4gnkyr9f",
                kind = "rpe_item",
                quantity = 38,
            },
            {
                itemRef = "732368d4:lxqnh3pp",
                kind = "rpe_item",
                quantity = 4,
            },
        },
        learnMode = "trainer",
        name = "Might of the Timbermaw",
        output = {
            itemRef = "538a54a0:tdwjdyz6",
            maxQuantity = 1,
            minQuantity = 1,
        },
        reagents = {},
        requiredSkillLevel = 290,
        results = {},
        skillRef = "f82db71a:x9qez6bu",
        tags = {},
        trainerCostCopper = 142755,
    },
    {
        category = "",
        description = "",
        id = "ie4mursx",
        inputs = {
            {
                itemRef = "538a54a0:4gnkyr9f",
                kind = "rpe_item",
                quantity = 14,
            },
        },
        learnMode = "trainer",
        name = "Runic Leather Headband",
        output = {
            itemRef = "538a54a0:tw0g1cvc",
            maxQuantity = 1,
            minQuantity = 1,
        },
        reagents = {},
        requiredSkillLevel = 290,
        results = {},
        skillRef = "f82db71a:x9qez6bu",
        tags = {},
        trainerCostCopper = 142755,
    },
    {
        category = "",
        description = "",
        id = "yqhccg08",
        inputs = {
            {
                itemRef = "538a54a0:4gnkyr9f",
                kind = "rpe_item",
                quantity = 32,
            },
            {
                itemRef = "538a54a0:n7ad1th5",
                kind = "rpe_item",
                quantity = 30,
            },
            {
                itemRef = "732368d4:x5hz6tby",
                kind = "rpe_item",
                quantity = 2,
            },
        },
        learnMode = "trainer",
        name = "Blue Dragonscale Shoulders",
        output = {
            itemRef = "538a54a0:rkpmrmia",
            maxQuantity = 1,
            minQuantity = 1,
        },
        reagents = {},
        requiredSkillLevel = 295,
        results = {},
        skillRef = "f82db71a:x9qez6bu",
        tags = {},
        trainerCostCopper = 147575,
    },
    {
        category = "",
        description = "",
        id = "iux26h8b",
        inputs = {
            {
                itemRef = "538a54a0:4gnkyr9f",
                kind = "rpe_item",
                quantity = 100,
            },
            {
                itemRef = "3eb7e9bb:e0tarf0p",
                kind = "rpe_item",
                quantity = 6,
            },
            {
                itemRef = "3eb7e9bb:g3ytywfw",
                kind = "rpe_item",
                quantity = 2,
            },
        },
        learnMode = "trainer",
        name = "Corehound Boots",
        output = {
            itemRef = "538a54a0:a2c6cukq",
            maxQuantity = 1,
            minQuantity = 1,
        },
        reagents = {},
        requiredSkillLevel = 295,
        results = {},
        skillRef = "f82db71a:x9qez6bu",
        tags = {},
        trainerCostCopper = 147575,
    },
    {
        category = "",
        description = "",
        id = "rf6c00uo",
        inputs = {
            {
                itemRef = "538a54a0:4gnkyr9f",
                kind = "rpe_item",
                quantity = 24,
            },
        },
        learnMode = "trainer",
        name = "Heavy Scorpid Helm",
        output = {
            itemRef = "538a54a0:4uu60rsl",
            maxQuantity = 1,
            minQuantity = 1,
        },
        reagents = {},
        requiredSkillLevel = 295,
        results = {},
        skillRef = "f82db71a:x9qez6bu",
        tags = {},
        trainerCostCopper = 147575,
    },
    {
        category = "",
        description = "",
        id = "yh7x0i34",
        inputs = {
            {
                itemRef = "538a54a0:4gnkyr9f",
                kind = "rpe_item",
                quantity = 12,
            },
            {
                itemRef = "732368d4:vlwvpmfx",
                kind = "rpe_item",
                quantity = 3,
            },
            {
                itemRef = "732368d4:2616xh4v",
                kind = "rpe_item",
                quantity = 3,
            },
            {
                itemRef = "732368d4:x5hz6tby",
                kind = "rpe_item",
                quantity = 2,
            },
        },
        learnMode = "trainer",
        name = "Stormshroud Shoulders",
        output = {
            itemRef = "538a54a0:ei28au20",
            maxQuantity = 1,
            minQuantity = 1,
        },
        reagents = {},
        requiredSkillLevel = 295,
        results = {},
        skillRef = "f82db71a:x9qez6bu",
        tags = {},
        trainerCostCopper = 147575,
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
