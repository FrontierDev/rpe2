# Wicked Nemesis — Tank

Season of Discovery Warlock Tier 2 Draconic tank set.

Each block below is a standalone `RPE_DATASET_ENTRY_V1` import code for the Warlock dataset (`e8f3b2c6`).

The WoW Season of Discovery Draconic item stats are translated into RPE's existing Core stats. RPE Tier 2 convention normalizes item level 76 source items to item level 75. Combined magical damage/healing is represented as Spell Power, and all-spells-and-attacks hit/crit is specialized to spell hit/crit for Warlock.

## Nemesis Garb

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
        blueSockets = 2,
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
        id = "wl2tgarb",
        isTwoHanded = false,
        itemLevel = 75,
        itemSetKey = "t2_warlock_tank",
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
        name = "Nemesis Garb",
        prismaticSockets = 0,
        quality = "epic",
        redSockets = 0,
        sellPrice = 0,
        skillBonuses = {  },
        socketTypes = {  },
        sockets = {
            {
                color = "blue",
            },
            {
                color = "blue",
            },
            {
                color = "yellow",
            },
        },
        stats = {
            {
                sourceStatRef = "f82db71a:v42albuv",
                value = 216,
            },
            {
                sourceStatRef = "f82db71a:ygjno50i",
                value = 32,
            },
            {
                sourceStatRef = "f82db71a:kec9rhli",
                value = 14,
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
                value = 12,
            },
            {
                sourceStatRef = "f82db71a:0wyp78x9",
                value = 10,
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

## Nemesis Treads

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
        id = "wl2ttrds",
        isTwoHanded = false,
        itemLevel = 75,
        itemSetKey = "t2_warlock_tank",
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
        name = "Nemesis Treads",
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
                value = 120,
            },
            {
                sourceStatRef = "f82db71a:ygjno50i",
                value = 26,
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
                sourceStatRef = "f82db71a:v2g0tw0o",
                value = 1,
            },
            {
                sourceStatRef = "f82db71a:7t7xgzcx",
                value = 14,
            },
            {
                sourceStatRef = "f82db71a:0wyp78x9",
                value = 7,
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

## Nemesis Handguards

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
        id = "wl2thand",
        isTwoHanded = false,
        itemLevel = 75,
        itemSetKey = "t2_warlock_tank",
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
        name = "Nemesis Handguards",
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
                value = 152,
            },
            {
                sourceStatRef = "f82db71a:ygjno50i",
                value = 24,
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
                sourceStatRef = "f82db71a:v2g0tw0o",
                value = 1,
            },
            {
                sourceStatRef = "f82db71a:7t7xgzcx",
                value = 12,
            },
            {
                sourceStatRef = "f82db71a:0wyp78x9",
                value = 7,
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

## Nemesis Cowl

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
        blueSockets = 1,
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
        id = "wl2tcowl",
        isTwoHanded = false,
        itemLevel = 75,
        itemSetKey = "t2_warlock_tank",
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
        name = "Nemesis Cowl",
        prismaticSockets = 0,
        quality = "epic",
        redSockets = 0,
        sellPrice = 0,
        skillBonuses = {  },
        socketTypes = {  },
        sockets = {
            {
                color = "meta",
            },
            {
                color = "blue",
            },
        },
        stats = {
            {
                sourceStatRef = "f82db71a:v42albuv",
                value = 184,
            },
            {
                sourceStatRef = "f82db71a:75y3a8ib",
                value = 10,
            },
            {
                sourceStatRef = "f82db71a:ygjno50i",
                value = 35,
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
                sourceStatRef = "f82db71a:7t7xgzcx",
                value = 12,
            },
            {
                sourceStatRef = "f82db71a:0wyp78x9",
                value = 10,
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

## Nemesis Pants

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
        blueSockets = 1,
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
        id = "wl2tpant",
        isTwoHanded = false,
        itemLevel = 75,
        itemSetKey = "t2_warlock_tank",
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
        name = "Nemesis Pants",
        prismaticSockets = 0,
        quality = "epic",
        redSockets = 0,
        sellPrice = 0,
        skillBonuses = {  },
        socketTypes = {  },
        sockets = {
            {
                color = "blue",
            },
            {
                color = "yellow",
            },
        },
        stats = {
            {
                sourceStatRef = "f82db71a:v42albuv",
                value = 181,
            },
            {
                sourceStatRef = "f82db71a:75y3a8ib",
                value = 7,
            },
            {
                sourceStatRef = "f82db71a:ygjno50i",
                value = 35,
            },
            {
                sourceStatRef = "f82db71a:kec9rhli",
                value = 6,
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
                value = 12,
            },
            {
                sourceStatRef = "f82db71a:0wyp78x9",
                value = 10,
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

## Nemesis Shoulderpads

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
        id = "wl2tshld",
        isTwoHanded = false,
        itemLevel = 75,
        itemSetKey = "t2_warlock_tank",
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
        name = "Nemesis Shoulderpads",
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
                value = 137,
            },
            {
                sourceStatRef = "f82db71a:75y3a8ib",
                value = 8,
            },
            {
                sourceStatRef = "f82db71a:ygjno50i",
                value = 26,
            },
            {
                sourceStatRef = "f82db71a:kec9rhli",
                value = 10,
            },
            {
                sourceStatRef = "f82db71a:jjn0my8k",
                value = 10,
            },
            {
                sourceStatRef = "f82db71a:7t7xgzcx",
                value = 12,
            },
            {
                sourceStatRef = "f82db71a:0wyp78x9",
                value = 7,
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

## Nemesis Cord

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
        blueSockets = 1,
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
        id = "wl2tcord",
        isTwoHanded = false,
        itemLevel = 75,
        itemSetKey = "t2_warlock_tank",
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
        name = "Nemesis Cord",
        prismaticSockets = 0,
        quality = "epic",
        redSockets = 0,
        sellPrice = 0,
        skillBonuses = {  },
        socketTypes = {  },
        sockets = {
            {
                color = "blue",
            },
        },
        stats = {
            {
                sourceStatRef = "f82db71a:v42albuv",
                value = 125,
            },
            {
                sourceStatRef = "f82db71a:75y3a8ib",
                value = 6,
            },
            {
                sourceStatRef = "f82db71a:ygjno50i",
                value = 26,
            },
            {
                sourceStatRef = "f82db71a:kec9rhli",
                value = 6,
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
                sourceStatRef = "f82db71a:0wyp78x9",
                value = 10,
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
        yellowSockets = 0,
    },
}
```

## Nemesis Wraps

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
        id = "wl2twrap",
        isTwoHanded = false,
        itemLevel = 75,
        itemSetKey = "t2_warlock_tank",
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
        name = "Nemesis Wraps",
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
                value = 131,
            },
            {
                sourceStatRef = "f82db71a:ygjno50i",
                value = 15,
            },
            {
                sourceStatRef = "f82db71a:7t7xgzcx",
                value = 9,
            },
            {
                sourceStatRef = "f82db71a:0wyp78x9",
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
