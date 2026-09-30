# Bounty of Stormrage — Restoration Healer

Season of Discovery Druid Tier 2 Draconic Restoration healer set.

Each block below is a standalone `RPE_DATASET_ENTRY_V1` import code for the Druid dataset (`6e4d2a91`).

## Stormrage Chestguard

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "items",
    datasetId = "6e4d2a91",
    entry = {
        allowWowConversion = false,
        armorWeight = "leather",
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
                    "6e4d2a91:drdcls01",
                },
                invert = false,
                showOnTooltip = true,
                tooltipTextOverride = "Classes: Druid",
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
        icon = "interface/icons/inv_chest_chain_16.blp",
        id = "dr2hchst",
        isTwoHanded = false,
        itemLevel = 75,
        itemSetKey = "t2_druid_healer",
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
        name = "Stormrage Chestguard",
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
            {
                color = "blue",
            },
        },
        stats = {
            {
                sourceStatRef = "f82db71a:v42albuv",
                value = 225,
            },
            {
                sourceStatRef = "f82db71a:75y3a8ib",
                value = 15,
            },
            {
                sourceStatRef = "f82db71a:ygjno50i",
                value = 14,
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
                sourceStatRef = "f82db71a:jjn0my8k",
                value = 10,
            },
            {
                sourceStatRef = "f82db71a:69hfqhne",
                value = 1,
            },
            {
                sourceStatRef = "f82db71a:hj6d4kvy",
                value = 66,
            },
            {
                sourceStatRef = "f82db71a:7t7xgzcx",
                value = 22,
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

## Stormrage Boots

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "items",
    datasetId = "6e4d2a91",
    entry = {
        allowWowConversion = false,
        armorWeight = "leather",
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
                    "6e4d2a91:drdcls01",
                },
                invert = false,
                showOnTooltip = true,
                tooltipTextOverride = "Classes: Druid",
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
        icon = "interface/icons/inv_boots_08.blp",
        id = "dr2hboot",
        isTwoHanded = false,
        itemLevel = 75,
        itemSetKey = "t2_druid_healer",
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
        name = "Stormrage Boots",
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
                value = 154,
            },
            {
                sourceStatRef = "f82db71a:75y3a8ib",
                value = 17,
            },
            {
                sourceStatRef = "f82db71a:ygjno50i",
                value = 12,
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
                sourceStatRef = "f82db71a:hj6d4kvy",
                value = 42,
            },
            {
                sourceStatRef = "f82db71a:7t7xgzcx",
                value = 14,
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

## Stormrage Handguards

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "items",
    datasetId = "6e4d2a91",
    entry = {
        allowWowConversion = false,
        armorWeight = "leather",
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
                    "6e4d2a91:drdcls01",
                },
                invert = false,
                showOnTooltip = true,
                tooltipTextOverride = "Classes: Druid",
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
        icon = "interface/icons/inv_gauntlets_25.blp",
        id = "dr2hhand",
        isTwoHanded = false,
        itemLevel = 75,
        itemSetKey = "t2_druid_healer",
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
        name = "Stormrage Handguards",
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
                value = 140,
            },
            {
                sourceStatRef = "f82db71a:75y3a8ib",
                value = 16,
            },
            {
                sourceStatRef = "f82db71a:ygjno50i",
                value = 14,
            },
            {
                sourceStatRef = "f82db71a:kec9rhli",
                value = 11,
            },
            {
                sourceStatRef = "f82db71a:pg0ytacb",
                value = 10,
            },
            {
                sourceStatRef = "f82db71a:hj6d4kvy",
                value = 48,
            },
            {
                sourceStatRef = "f82db71a:7t7xgzcx",
                value = 16,
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

## Stormrage Cover

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "items",
    datasetId = "6e4d2a91",
    entry = {
        allowWowConversion = false,
        armorWeight = "leather",
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
                    "6e4d2a91:drdcls01",
                },
                invert = false,
                showOnTooltip = true,
                tooltipTextOverride = "Classes: Druid",
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
        icon = "interface/icons/inv_helmet_09.blp",
        id = "dr2hcove",
        isTwoHanded = false,
        itemLevel = 75,
        itemSetKey = "t2_druid_healer",
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
        name = "Stormrage Cover",
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
                value = 183,
            },
            {
                sourceStatRef = "f82db71a:75y3a8ib",
                value = 16,
            },
            {
                sourceStatRef = "f82db71a:ygjno50i",
                value = 14,
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
                sourceStatRef = "f82db71a:jjn0my8k",
                value = 10,
            },
            {
                sourceStatRef = "f82db71a:69hfqhne",
                value = 1,
            },
            {
                sourceStatRef = "f82db71a:hj6d4kvy",
                value = 66,
            },
            {
                sourceStatRef = "f82db71a:7t7xgzcx",
                value = 22,
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

## Stormrage Legguards

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "items",
    datasetId = "6e4d2a91",
    entry = {
        allowWowConversion = false,
        armorWeight = "leather",
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
                    "6e4d2a91:drdcls01",
                },
                invert = false,
                showOnTooltip = true,
                tooltipTextOverride = "Classes: Druid",
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
        icon = "interface/icons/inv_pants_06.blp",
        id = "dr2hlegg",
        isTwoHanded = false,
        itemLevel = 75,
        itemSetKey = "t2_druid_healer",
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
        name = "Stormrage Legguards",
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
                color = "blue",
            },
        },
        stats = {
            {
                sourceStatRef = "f82db71a:v42albuv",
                value = 197,
            },
            {
                sourceStatRef = "f82db71a:75y3a8ib",
                value = 15,
            },
            {
                sourceStatRef = "f82db71a:ygjno50i",
                value = 13,
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
                sourceStatRef = "f82db71a:69hfqhne",
                value = 1,
            },
            {
                sourceStatRef = "f82db71a:hj6d4kvy",
                value = 59,
            },
            {
                sourceStatRef = "f82db71a:7t7xgzcx",
                value = 20,
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
        yellowSockets = 0,
    },
}
```

## Stormrage Pauldrons

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "items",
    datasetId = "6e4d2a91",
    entry = {
        allowWowConversion = false,
        armorWeight = "leather",
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
                    "6e4d2a91:drdcls01",
                },
                invert = false,
                showOnTooltip = true,
                tooltipTextOverride = "Classes: Druid",
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
        icon = "interface/icons/inv_shoulder_07.blp",
        id = "dr2hpaul",
        isTwoHanded = false,
        itemLevel = 75,
        itemSetKey = "t2_druid_healer",
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
        name = "Stormrage Pauldrons",
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
                value = 169,
            },
            {
                sourceStatRef = "f82db71a:75y3a8ib",
                value = 13,
            },
            {
                sourceStatRef = "f82db71a:ygjno50i",
                value = 10,
            },
            {
                sourceStatRef = "f82db71a:kec9rhli",
                value = 11,
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
                sourceStatRef = "f82db71a:hj6d4kvy",
                value = 44,
            },
            {
                sourceStatRef = "f82db71a:7t7xgzcx",
                value = 15,
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

## Stormrage Belt

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "items",
    datasetId = "6e4d2a91",
    entry = {
        allowWowConversion = false,
        armorWeight = "leather",
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
                    "6e4d2a91:drdcls01",
                },
                invert = false,
                showOnTooltip = true,
                tooltipTextOverride = "Classes: Druid",
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
        icon = "interface/icons/inv_belt_06.blp",
        id = "dr2hbelt",
        isTwoHanded = false,
        itemLevel = 75,
        itemSetKey = "t2_druid_healer",
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
        name = "Stormrage Belt",
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
                value = 126,
            },
            {
                sourceStatRef = "f82db71a:75y3a8ib",
                value = 12,
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
                sourceStatRef = "f82db71a:hj6d4kvy",
                value = 42,
            },
            {
                sourceStatRef = "f82db71a:7t7xgzcx",
                value = 14,
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

## Stormrage Bracers

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "items",
    datasetId = "6e4d2a91",
    entry = {
        allowWowConversion = false,
        armorWeight = "leather",
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
                    "6e4d2a91:drdcls01",
                },
                invert = false,
                showOnTooltip = true,
                tooltipTextOverride = "Classes: Druid",
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
        icon = "interface/icons/inv_bracer_03.blp",
        id = "dr2hbrac",
        isTwoHanded = false,
        itemLevel = 75,
        itemSetKey = "t2_druid_healer",
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
        name = "Stormrage Bracers",
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
                value = 98,
            },
            {
                sourceStatRef = "f82db71a:75y3a8ib",
                value = 10,
            },
            {
                sourceStatRef = "f82db71a:ygjno50i",
                value = 13,
            },
            {
                sourceStatRef = "f82db71a:69hfqhne",
                value = 1,
            },
            {
                sourceStatRef = "f82db71a:hj6d4kvy",
                value = 31,
            },
            {
                sourceStatRef = "f82db71a:7t7xgzcx",
                value = 11,
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
