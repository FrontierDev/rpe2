# Corrupted Nemesis — DPS

Season of Discovery Warlock Tier 2 Draconic DPS set.

Each block below is a standalone `RPE_DATASET_ENTRY_V1` import code for the Warlock dataset (`e8f3b2c6`).

The WoW Season of Discovery Draconic item stats are translated into RPE's existing Core stats. RPE Tier 2 convention normalizes item level 76 source items to item level 75. Combined magical damage/healing is represented as Spell Power, and all-spells-and-attacks hit/crit is specialized to spell hit/crit for Warlock.

## Nemesis Robes

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "items",
    datasetId = "e8f3b2c6",
    entry = {
        allowWowConversion = false,
        armorWeight = "cloth",
        bindingFlag = "bind_on_pickup",
        blueSockets = 0,
        canDisenchant = true,
        canSell = true,
        canStack = false,
        canTrade = true,
        cogSockets = 0,
        conditions = {
            {
                invert = false,
                minimumValue = 60,
                showOnTooltip = true,
                tooltipTextOverride = "",
                type = "level",
            },
            {
                classRefs = {
                    "e8f3b2c6:warlock1",
                },
                invert = false,
                showOnTooltip = true,
                tooltipTextOverride = "Classes: Warlock",
                type = "class",
            },
        },
        consumableElixirType = "",
        consumableType = "",
        damageMode = "fixed",
        damagePerTurn = 0,
        description = "",
        gemColor = "none",
        genericModificationKey = "",
        greenSockets = 0,
        icon = "interface/icons/inv_chest_leather_01.blp",
        id = "wl2drobe",
        isTwoHanded = false,
        itemLevel = 75,
        itemSetKey = "t2_warlock_dps",
        itemType = "armor",
        maxDamagePerTurn = 0,
        maxGenericModificationCounts = {
            mod = 1,
        },
        maxModificationCounts = {
            mod = 1,
        },
        maxStackSize = 1,
        metaSockets = 0,
        minDamagePerTurn = 0,
        modificationKind = "generic",
        name = "Nemesis Robes",
        prismaticSockets = 0,
        quality = "epic",
        redSockets = 2,
        sellPrice = 0,
        skillBonuses = {  },
        socketTypes = {  },
        sockets = {
            {
                color = "red",
            },
            {
                color = "red",
            },
            {
                color = "yellow",
            },
        },
        stats = {
            {
                sourceStatRef = "f82db71a:v42albuv",
                value = 116,
            },
            {
                sourceStatRef = "f82db71a:75y3a8ib",
                value = 12,
            },
            {
                sourceStatRef = "f82db71a:ygjno50i",
                value = 12,
            },
            {
                sourceStatRef = "f82db71a:kec9rhli",
                value = 15,
            },
            {
                sourceStatRef = "f82db71a:pg0ytacb",
                value = 10,
            },
            {
                sourceStatRef = "f82db71a:jjn0my8k",
                value = 10,
            },
            {
                sourceStatRef = "f82db71a:v2g0tw0o",
                value = 2,
            },
            {
                sourceStatRef = "f82db71a:7t7xgzcx",
                value = 32,
            },
        },
        tags = {  },
        targetArmorWeight = "none",
        targetSlotRefs = {  },
        targetTwoHandedOnly = false,
        uniqueFlag = "none",
        validSlotRefs = {
            "f82db71a:nwfvxbto",
        },
        yellowSockets = 1,
    },
}
```

## Nemesis Boots

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "items",
    datasetId = "e8f3b2c6",
    entry = {
        allowWowConversion = false,
        armorWeight = "cloth",
        bindingFlag = "bind_on_pickup",
        blueSockets = 0,
        canDisenchant = true,
        canSell = true,
        canStack = false,
        canTrade = true,
        cogSockets = 0,
        conditions = {
            {
                invert = false,
                minimumValue = 60,
                showOnTooltip = true,
                tooltipTextOverride = "",
                type = "level",
            },
            {
                classRefs = {
                    "e8f3b2c6:warlock1",
                },
                invert = false,
                showOnTooltip = true,
                tooltipTextOverride = "Classes: Warlock",
                type = "class",
            },
        },
        consumableElixirType = "",
        consumableType = "",
        damageMode = "fixed",
        damagePerTurn = 0,
        description = "",
        gemColor = "none",
        genericModificationKey = "",
        greenSockets = 0,
        icon = "interface/icons/inv_boots_05.blp",
        id = "wl2dboot",
        isTwoHanded = false,
        itemLevel = 75,
        itemSetKey = "t2_warlock_dps",
        itemType = "armor",
        maxDamagePerTurn = 0,
        maxGenericModificationCounts = {
            mod = 1,
        },
        maxModificationCounts = {
            mod = 1,
        },
        maxStackSize = 1,
        metaSockets = 0,
        minDamagePerTurn = 0,
        modificationKind = "generic",
        name = "Nemesis Boots",
        prismaticSockets = 0,
        quality = "epic",
        redSockets = 0,
        sellPrice = 0,
        skillBonuses = {  },
        socketTypes = {  },
        sockets = {  },
        stats = {
            {
                sourceStatRef = "f82db71a:v42albuv",
                value = 80,
            },
            {
                sourceStatRef = "f82db71a:75y3a8ib",
                value = 10,
            },
            {
                sourceStatRef = "f82db71a:ygjno50i",
                value = 14,
            },
            {
                sourceStatRef = "f82db71a:kec9rhli",
                value = 8,
            },
            {
                sourceStatRef = "f82db71a:pg0ytacb",
                value = 10,
            },
            {
                sourceStatRef = "f82db71a:69hfqhne",
                value = 1,
            },
            {
                sourceStatRef = "f82db71a:7t7xgzcx",
                value = 23,
            },
        },
        tags = {  },
        targetArmorWeight = "none",
        targetSlotRefs = {  },
        targetTwoHandedOnly = false,
        uniqueFlag = "none",
        validSlotRefs = {
            "f82db71a:raiu9t05",
        },
        yellowSockets = 0,
    },
}
```

## Nemesis Gloves

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "items",
    datasetId = "e8f3b2c6",
    entry = {
        allowWowConversion = false,
        armorWeight = "cloth",
        bindingFlag = "bind_on_pickup",
        blueSockets = 0,
        canDisenchant = true,
        canSell = true,
        canStack = false,
        canTrade = true,
        cogSockets = 0,
        conditions = {
            {
                invert = false,
                minimumValue = 60,
                showOnTooltip = true,
                tooltipTextOverride = "",
                type = "level",
            },
            {
                classRefs = {
                    "e8f3b2c6:warlock1",
                },
                invert = false,
                showOnTooltip = true,
                tooltipTextOverride = "Classes: Warlock",
                type = "class",
            },
        },
        consumableElixirType = "",
        consumableType = "",
        damageMode = "fixed",
        damagePerTurn = 0,
        description = "",
        gemColor = "none",
        genericModificationKey = "",
        greenSockets = 0,
        icon = "interface/icons/inv_gauntlets_19.blp",
        id = "wl2dglov",
        isTwoHanded = false,
        itemLevel = 75,
        itemSetKey = "t2_warlock_dps",
        itemType = "armor",
        maxDamagePerTurn = 0,
        maxGenericModificationCounts = {
            mod = 1,
        },
        maxModificationCounts = {
            mod = 1,
        },
        maxStackSize = 1,
        metaSockets = 0,
        minDamagePerTurn = 0,
        modificationKind = "generic",
        name = "Nemesis Gloves",
        prismaticSockets = 0,
        quality = "epic",
        redSockets = 0,
        sellPrice = 0,
        skillBonuses = {  },
        socketTypes = {  },
        sockets = {  },
        stats = {
            {
                sourceStatRef = "f82db71a:v42albuv",
                value = 72,
            },
            {
                sourceStatRef = "f82db71a:75y3a8ib",
                value = 10,
            },
            {
                sourceStatRef = "f82db71a:ygjno50i",
                value = 8,
            },
            {
                sourceStatRef = "f82db71a:kec9rhli",
                value = 13,
            },
            {
                sourceStatRef = "f82db71a:pg0ytacb",
                value = 10,
            },
            {
                sourceStatRef = "f82db71a:69hfqhne",
                value = 1,
            },
            {
                sourceStatRef = "f82db71a:7t7xgzcx",
                value = 25,
            },
        },
        tags = {  },
        targetArmorWeight = "none",
        targetSlotRefs = {  },
        targetTwoHandedOnly = false,
        uniqueFlag = "none",
        validSlotRefs = {
            "f82db71a:wasvuom2",
        },
        yellowSockets = 0,
    },
}
```

## Nemesis Skullcap

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "items",
    datasetId = "e8f3b2c6",
    entry = {
        allowWowConversion = false,
        armorWeight = "cloth",
        bindingFlag = "bind_on_pickup",
        blueSockets = 0,
        canDisenchant = true,
        canSell = true,
        canStack = false,
        canTrade = true,
        cogSockets = 0,
        conditions = {
            {
                invert = false,
                minimumValue = 60,
                showOnTooltip = true,
                tooltipTextOverride = "",
                type = "level",
            },
            {
                classRefs = {
                    "e8f3b2c6:warlock1",
                },
                invert = false,
                showOnTooltip = true,
                tooltipTextOverride = "Classes: Warlock",
                type = "class",
            },
        },
        consumableElixirType = "",
        consumableType = "",
        damageMode = "fixed",
        damagePerTurn = 0,
        description = "",
        gemColor = "none",
        genericModificationKey = "",
        greenSockets = 0,
        icon = "interface/icons/inv_helmet_08.blp",
        id = "wl2dhead",
        isTwoHanded = false,
        itemLevel = 75,
        itemSetKey = "t2_warlock_dps",
        itemType = "armor",
        maxDamagePerTurn = 0,
        maxGenericModificationCounts = {
            mod = 1,
        },
        maxModificationCounts = {
            mod = 1,
        },
        maxStackSize = 1,
        metaSockets = 1,
        minDamagePerTurn = 0,
        modificationKind = "generic",
        name = "Nemesis Skullcap",
        prismaticSockets = 0,
        quality = "epic",
        redSockets = 1,
        sellPrice = 0,
        skillBonuses = {  },
        socketTypes = {  },
        sockets = {
            {
                color = "meta",
            },
            {
                color = "red",
            },
        },
        stats = {
            {
                sourceStatRef = "f82db71a:v42albuv",
                value = 94,
            },
            {
                sourceStatRef = "f82db71a:75y3a8ib",
                value = 15,
            },
            {
                sourceStatRef = "f82db71a:ygjno50i",
                value = 17,
            },
            {
                sourceStatRef = "f82db71a:kec9rhli",
                value = 12,
            },
            {
                sourceStatRef = "f82db71a:pg0ytacb",
                value = 10,
            },
            {
                sourceStatRef = "f82db71a:jjn0my8k",
                value = 10,
            },
            {
                sourceStatRef = "f82db71a:v2g0tw0o",
                value = 1,
            },
            {
                sourceStatRef = "f82db71a:7t7xgzcx",
                value = 37,
            },
        },
        tags = {  },
        targetArmorWeight = "none",
        targetSlotRefs = {  },
        targetTwoHandedOnly = false,
        uniqueFlag = "none",
        validSlotRefs = {
            "f82db71a:bgvs1zx6",
        },
        yellowSockets = 0,
    },
}
```

## Nemesis Leggings

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "items",
    datasetId = "e8f3b2c6",
    entry = {
        allowWowConversion = false,
        armorWeight = "cloth",
        bindingFlag = "bind_on_pickup",
        blueSockets = 0,
        canDisenchant = true,
        canSell = true,
        canStack = false,
        canTrade = true,
        cogSockets = 0,
        conditions = {
            {
                invert = false,
                minimumValue = 60,
                showOnTooltip = true,
                tooltipTextOverride = "",
                type = "level",
            },
            {
                classRefs = {
                    "e8f3b2c6:warlock1",
                },
                invert = false,
                showOnTooltip = true,
                tooltipTextOverride = "Classes: Warlock",
                type = "class",
            },
        },
        consumableElixirType = "",
        consumableType = "",
        damageMode = "fixed",
        damagePerTurn = 0,
        description = "",
        gemColor = "none",
        genericModificationKey = "",
        greenSockets = 0,
        icon = "interface/icons/inv_pants_07.blp",
        id = "wl2dlegs",
        isTwoHanded = false,
        itemLevel = 75,
        itemSetKey = "t2_warlock_dps",
        itemType = "armor",
        maxDamagePerTurn = 0,
        maxGenericModificationCounts = {
            mod = 1,
        },
        maxModificationCounts = {
            mod = 1,
        },
        maxStackSize = 1,
        metaSockets = 0,
        minDamagePerTurn = 0,
        modificationKind = "generic",
        name = "Nemesis Leggings",
        prismaticSockets = 0,
        quality = "epic",
        redSockets = 1,
        sellPrice = 0,
        skillBonuses = {  },
        socketTypes = {  },
        sockets = {
            {
                color = "red",
            },
            {
                color = "yellow",
            },
        },
        stats = {
            {
                sourceStatRef = "f82db71a:v42albuv",
                value = 101,
            },
            {
                sourceStatRef = "f82db71a:75y3a8ib",
                value = 10,
            },
            {
                sourceStatRef = "f82db71a:ygjno50i",
                value = 15,
            },
            {
                sourceStatRef = "f82db71a:kec9rhli",
                value = 10,
            },
            {
                sourceStatRef = "f82db71a:pg0ytacb",
                value = 10,
            },
            {
                sourceStatRef = "f82db71a:jjn0my8k",
                value = 10,
            },
            {
                sourceStatRef = "f82db71a:69hfqhne",
                value = 2,
            },
            {
                sourceStatRef = "f82db71a:7t7xgzcx",
                value = 28,
            },
        },
        tags = {  },
        targetArmorWeight = "none",
        targetSlotRefs = {  },
        targetTwoHandedOnly = false,
        uniqueFlag = "none",
        validSlotRefs = {
            "f82db71a:obmt4ntq",
        },
        yellowSockets = 1,
    },
}
```

## Nemesis Spaulders

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "items",
    datasetId = "e8f3b2c6",
    entry = {
        allowWowConversion = false,
        armorWeight = "cloth",
        bindingFlag = "bind_on_pickup",
        blueSockets = 0,
        canDisenchant = true,
        canSell = true,
        canStack = false,
        canTrade = true,
        cogSockets = 0,
        conditions = {
            {
                invert = false,
                minimumValue = 60,
                showOnTooltip = true,
                tooltipTextOverride = "",
                type = "level",
            },
            {
                classRefs = {
                    "e8f3b2c6:warlock1",
                },
                invert = false,
                showOnTooltip = true,
                tooltipTextOverride = "Classes: Warlock",
                type = "class",
            },
        },
        consumableElixirType = "",
        consumableType = "",
        damageMode = "fixed",
        damagePerTurn = 0,
        description = "",
        gemColor = "none",
        genericModificationKey = "",
        greenSockets = 0,
        icon = "interface/icons/inv_shoulder_19.blp",
        id = "wl2dshld",
        isTwoHanded = false,
        itemLevel = 75,
        itemSetKey = "t2_warlock_dps",
        itemType = "armor",
        maxDamagePerTurn = 0,
        maxGenericModificationCounts = {
            mod = 1,
        },
        maxModificationCounts = {
            mod = 1,
        },
        maxStackSize = 1,
        metaSockets = 0,
        minDamagePerTurn = 0,
        modificationKind = "generic",
        name = "Nemesis Spaulders",
        prismaticSockets = 0,
        quality = "epic",
        redSockets = 0,
        sellPrice = 0,
        skillBonuses = {  },
        socketTypes = {  },
        sockets = {  },
        stats = {
            {
                sourceStatRef = "f82db71a:v42albuv",
                value = 87,
            },
            {
                sourceStatRef = "f82db71a:75y3a8ib",
                value = 11,
            },
            {
                sourceStatRef = "f82db71a:ygjno50i",
                value = 13,
            },
            {
                sourceStatRef = "f82db71a:kec9rhli",
                value = 13,
            },
            {
                sourceStatRef = "f82db71a:jjn0my8k",
                value = 10,
            },
            {
                sourceStatRef = "f82db71a:v2g0tw0o",
                value = 1,
            },
            {
                sourceStatRef = "f82db71a:7t7xgzcx",
                value = 23,
            },
        },
        tags = {  },
        targetArmorWeight = "none",
        targetSlotRefs = {  },
        targetTwoHandedOnly = false,
        uniqueFlag = "none",
        validSlotRefs = {
            "f82db71a:66i80qm1",
        },
        yellowSockets = 0,
    },
}
```

## Nemesis Belt

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "items",
    datasetId = "e8f3b2c6",
    entry = {
        allowWowConversion = false,
        armorWeight = "cloth",
        bindingFlag = "bind_on_pickup",
        blueSockets = 0,
        canDisenchant = true,
        canSell = true,
        canStack = false,
        canTrade = true,
        cogSockets = 0,
        conditions = {
            {
                invert = false,
                minimumValue = 60,
                showOnTooltip = true,
                tooltipTextOverride = "",
                type = "level",
            },
            {
                classRefs = {
                    "e8f3b2c6:warlock1",
                },
                invert = false,
                showOnTooltip = true,
                tooltipTextOverride = "Classes: Warlock",
                type = "class",
            },
        },
        consumableElixirType = "",
        consumableType = "",
        damageMode = "fixed",
        damagePerTurn = 0,
        description = "",
        gemColor = "none",
        genericModificationKey = "",
        greenSockets = 0,
        icon = "interface/icons/inv_belt_13.blp",
        id = "wl2dbelt",
        isTwoHanded = false,
        itemLevel = 75,
        itemSetKey = "t2_warlock_dps",
        itemType = "armor",
        maxDamagePerTurn = 0,
        maxGenericModificationCounts = {
            mod = 1,
        },
        maxModificationCounts = {
            mod = 1,
        },
        maxStackSize = 1,
        metaSockets = 0,
        minDamagePerTurn = 0,
        modificationKind = "generic",
        name = "Nemesis Belt",
        prismaticSockets = 0,
        quality = "epic",
        redSockets = 0,
        sellPrice = 0,
        skillBonuses = {  },
        socketTypes = {  },
        sockets = {
            {
                color = "yellow",
            },
        },
        stats = {
            {
                sourceStatRef = "f82db71a:v42albuv",
                value = 65,
            },
            {
                sourceStatRef = "f82db71a:75y3a8ib",
                value = 10,
            },
            {
                sourceStatRef = "f82db71a:ygjno50i",
                value = 10,
            },
            {
                sourceStatRef = "f82db71a:kec9rhli",
                value = 12,
            },
            {
                sourceStatRef = "f82db71a:jjn0my8k",
                value = 10,
            },
            {
                sourceStatRef = "f82db71a:69hfqhne",
                value = 1,
            },
            {
                sourceStatRef = "f82db71a:7t7xgzcx",
                value = 25,
            },
        },
        tags = {  },
        targetArmorWeight = "none",
        targetSlotRefs = {  },
        targetTwoHandedOnly = false,
        uniqueFlag = "none",
        validSlotRefs = {
            "f82db71a:haks0gz4",
        },
        yellowSockets = 1,
    },
}
```

## Nemesis Bracers

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "items",
    datasetId = "e8f3b2c6",
    entry = {
        allowWowConversion = false,
        armorWeight = "cloth",
        bindingFlag = "bind_on_pickup",
        blueSockets = 0,
        canDisenchant = true,
        canSell = true,
        canStack = false,
        canTrade = true,
        cogSockets = 0,
        conditions = {
            {
                invert = false,
                minimumValue = 60,
                showOnTooltip = true,
                tooltipTextOverride = "",
                type = "level",
            },
            {
                classRefs = {
                    "e8f3b2c6:warlock1",
                },
                invert = false,
                showOnTooltip = true,
                tooltipTextOverride = "Classes: Warlock",
                type = "class",
            },
        },
        consumableElixirType = "",
        consumableType = "",
        damageMode = "fixed",
        damagePerTurn = 0,
        description = "",
        gemColor = "none",
        genericModificationKey = "",
        greenSockets = 0,
        icon = "interface/icons/inv_bracer_07.blp",
        id = "wl2dwrst",
        isTwoHanded = false,
        itemLevel = 75,
        itemSetKey = "t2_warlock_dps",
        itemType = "armor",
        maxDamagePerTurn = 0,
        maxGenericModificationCounts = {
            mod = 1,
        },
        maxModificationCounts = {
            mod = 1,
        },
        maxStackSize = 1,
        metaSockets = 0,
        minDamagePerTurn = 0,
        modificationKind = "generic",
        name = "Nemesis Bracers",
        prismaticSockets = 0,
        quality = "epic",
        redSockets = 0,
        sellPrice = 0,
        skillBonuses = {  },
        socketTypes = {  },
        sockets = {  },
        stats = {
            {
                sourceStatRef = "f82db71a:v42albuv",
                value = 51,
            },
            {
                sourceStatRef = "f82db71a:75y3a8ib",
                value = 11,
            },
            {
                sourceStatRef = "f82db71a:ygjno50i",
                value = 11,
            },
            {
                sourceStatRef = "f82db71a:kec9rhli",
                value = 8,
            },
            {
                sourceStatRef = "f82db71a:69hfqhne",
                value = 1,
            },
            {
                sourceStatRef = "f82db71a:7t7xgzcx",
                value = 13,
            },
        },
        tags = {  },
        targetArmorWeight = "none",
        targetSlotRefs = {  },
        targetTwoHandedOnly = false,
        uniqueFlag = "none",
        validSlotRefs = {
            "f82db71a:crezt6ix",
        },
        yellowSockets = 0,
    },
}
```
