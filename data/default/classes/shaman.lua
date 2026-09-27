local _, Addon = ...

Addon.Data.DefaultDatasets:Register({
    version = 1,
    dataset = {
        achievements = {},
        auras = {},
        authorName = "Ortellus-ArgentDawn",
        classes = {
            {
                description = "Shamans call on the elements to protect their allies and punish their foes.",
                icon = "interface/icons/classicon_shaman.blp",
                id = "shaman01",
                name = "Shaman",
                armorWeights = {
                    "cloth",
                    "leather",
                    "mail",
                },
                weaponTypeRefs = {
                    "f82db71a:i4pivdig",
                    "f82db71a:9ni3vfas",
                    "f82db71a:y0dnlo8g",
                    "f82db71a:3y1v01e4",
                },
                resourceProgressions = {
                    {
                        initialValue = 27,
                        perLevelValue = 21.24,
                        resourceRef = "f82db71a:q2ktkztt",
                    },
                    {
                        initialValue = 53,
                        perLevelValue = 24.86,
                        resourceRef = "f82db71a:4c8mfm99",
                    },
                },
                skillBonuses = {},
                statProgressions = {
                    {
                        initialValue = 1,
                        perLevelValue = 1.08,
                        statRef = "f82db71a:zfqm8dxp",
                    },
                    {
                        initialValue = 0,
                        perLevelValue = 0.59,
                        statRef = "f82db71a:xqz0daz2",
                    },
                    {
                        initialValue = 1,
                        perLevelValue = 1.25,
                        statRef = "f82db71a:ygjno50i",
                    },
                    {
                        initialValue = 1,
                        perLevelValue = 1.17,
                        statRef = "f82db71a:75y3a8ib",
                    },
                    {
                        initialValue = 2,
                        perLevelValue = 1.32,
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
        id = "c4a91e7d",
        interactions = {},
        itemSlots = {},
        items = {},
        loot = {},
        mounts = {},
        name = "Shaman",
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
