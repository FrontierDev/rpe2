local _, Addon = ...

Addon.Data.DefaultDatasets:Register({
    version = 1,
    dataset = {
        achievements = {},
        auras = {},
        authorName = "Ortellus-ArgentDawn",
        classes = {
            {
                description = "Warlocks wield fel and shadow magic, commanding demons and draining life from their enemies.",
                icon = "interface/icons/classicon_warlock.blp",
                id = "warlock1",
                name = "Warlock",
                armorWeights = {
                    "cloth",
                },
                weaponTypeRefs = {
                    "f82db71a:z6nh3znw",
                    "f82db71a:y0dnlo8g",
                    "f82db71a:3y1v01e4",
                    "f82db71a:s4q9t5f3",
                },
                resourceProgressions = {
                    {
                        initialValue = 23,
                        perLevelValue = 23.58,
                        resourceRef = "f82db71a:q2ktkztt",
                    },
                    {
                        initialValue = 59,
                        perLevelValue = 22.27,
                        resourceRef = "f82db71a:4c8mfm99",
                    },
                },
                skillBonuses = {},
                statProgressions = {
                    {
                        initialValue = 0,
                        perLevelValue = 0.42,
                        statRef = "f82db71a:zfqm8dxp",
                    },
                    {
                        initialValue = 0,
                        perLevelValue = 0.51,
                        statRef = "f82db71a:xqz0daz2",
                    },
                    {
                        initialValue = 1,
                        perLevelValue = 0.75,
                        statRef = "f82db71a:ygjno50i",
                    },
                    {
                        initialValue = 2,
                        perLevelValue = 1.49,
                        statRef = "f82db71a:75y3a8ib",
                    },
                    {
                        initialValue = 2,
                        perLevelValue = 1.58,
                        statRef = "f82db71a:kec9rhli",
                    },
                },
                passiveTraitRefs = {},
                talentTraitRefs = {},
            },
        },
        currencies = {},
        damageSchools = {},
        datasetType = "class",
        dependencies = {
            "f82db71a",
        },
        description = "",
        groupName = "Core",
        guildSettings = {},
        id = "e8f3b2c6",
        interactions = {},
        itemSlots = {},
        items = {},
        loot = {},
        mounts = {},
        name = "Warlock",
        pets = {},
        races = {},
        recipes = {},
        resources = {},
        skills = {},
        spells = {},
        stats = {},
        tags = {},
        traits = {},
        units = {},
        weaponTypes = {},
    },
})
