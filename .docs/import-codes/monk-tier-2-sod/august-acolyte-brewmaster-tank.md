# August Acolyte — Brewmaster Tank

Invented RPE Tier 2 Brewmaster set using the existing Bloodfang Battlearmor leather-tank stat budget.

Each block below is a standalone `RPE_DATASET_ENTRY_V1` import code for the Monk dataset (`monkdata`).

## Chestguard of the August Acolyte

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "items",
    datasetId = "monkdata",
    entry = {
        allowWowConversion = false,
        armorWeight = "leather",
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
                    "monkdata:monk0001",
                },
                invert = false,
                showOnTooltip = true,
                tooltipTextOverride = "Classes: Monk",
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
        icon = "interface/icons/inv_leather_raidmonkt2_d_01_chest.blp",
        id = "mn2tchst",
        isTwoHanded = false,
        itemLevel = 75,
        itemSetKey = "t2_monk_tank",
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
        name = "Chestguard of the August Acolyte",
        prismaticSockets = 0,
        quality = "epic",
        redSockets = 0,
        sellPrice = 0,
        skillBonuses = { },
        socketTypes = { },
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
                value = 225,
            },
            {
                sourceStatRef = "f82db71a:xqz0daz2",
                value = 17,
            },
            {
                sourceStatRef = "f82db71a:ygjno50i",
                value = 32,
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
                sourceStatRef = "f82db71a:wbj4zuf3",
                value = 2,
            },
            {
                sourceStatRef = "f82db71a:0wyp78x9",
                value = 11,
            },
        },
        tags = { },
        targetArmorWeight = "none",
        targetSlotRefs = { },
        targetTwoHandedOnly = false,
        uniqueFlag = "none",
        validSlotRefs = {
            "f82db71a:nwfvxbto",
        },
        yellowSockets = 1,
    },
}
```

## Treads of the August Acolyte

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "items",
    datasetId = "monkdata",
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
                    "monkdata:monk0001",
                },
                invert = false,
                showOnTooltip = true,
                tooltipTextOverride = "Classes: Monk",
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
        icon = "interface/icons/inv_leather_raidmonkt2_d_01_boot.blp",
        id = "mn2ttrds",
        isTwoHanded = false,
        itemLevel = 75,
        itemSetKey = "t2_monk_tank",
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
        name = "Treads of the August Acolyte",
        prismaticSockets = 0,
        quality = "epic",
        redSockets = 0,
        sellPrice = 0,
        skillBonuses = { },
        socketTypes = { },
        sockets = { },
        stats = {
            {
                sourceStatRef = "f82db71a:v42albuv",
                value = 154,
            },
            {
                sourceStatRef = "f82db71a:zfqm8dxp",
                value = 8,
            },
            {
                sourceStatRef = "f82db71a:xqz0daz2",
                value = 12,
            },
            {
                sourceStatRef = "f82db71a:ygjno50i",
                value = 27,
            },
            {
                sourceStatRef = "f82db71a:pg0ytacb",
                value = 10,
            },
            {
                sourceStatRef = "f82db71a:0wyp78x9",
                value = 11,
            },
        },
        tags = { },
        targetArmorWeight = "none",
        targetSlotRefs = { },
        targetTwoHandedOnly = false,
        uniqueFlag = "none",
        validSlotRefs = {
            "f82db71a:raiu9t05",
        },
        yellowSockets = 0,
    },
}
```

## Handguards of the August Acolyte

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "items",
    datasetId = "monkdata",
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
                    "monkdata:monk0001",
                },
                invert = false,
                showOnTooltip = true,
                tooltipTextOverride = "Classes: Monk",
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
        icon = "interface/icons/inv_leather_raidmonkt2_d_01_glove.blp",
        id = "mn2thand",
        isTwoHanded = false,
        itemLevel = 75,
        itemSetKey = "t2_monk_tank",
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
        name = "Handguards of the August Acolyte",
        prismaticSockets = 0,
        quality = "epic",
        redSockets = 0,
        sellPrice = 0,
        skillBonuses = { },
        socketTypes = { },
        sockets = { },
        stats = {
            {
                sourceStatRef = "f82db71a:v42albuv",
                value = 140,
            },
            {
                sourceStatRef = "f82db71a:xqz0daz2",
                value = 20,
            },
            {
                sourceStatRef = "f82db71a:ygjno50i",
                value = 23,
            },
            {
                sourceStatRef = "f82db71a:pg0ytacb",
                value = 10,
            },
            {
                sourceStatRef = "f82db71a:wbj4zuf3",
                value = 1,
            },
            {
                sourceStatRef = "f82db71a:0wyp78x9",
                value = 10,
            },
        },
        tags = { },
        targetArmorWeight = "none",
        targetSlotRefs = { },
        targetTwoHandedOnly = false,
        uniqueFlag = "none",
        validSlotRefs = {
            "f82db71a:wasvuom2",
        },
        yellowSockets = 0,
    },
}
```

## Headguard of the August Acolyte

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "items",
    datasetId = "monkdata",
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
                    "monkdata:monk0001",
                },
                invert = false,
                showOnTooltip = true,
                tooltipTextOverride = "Classes: Monk",
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
        icon = "interface/icons/inv_leather_raidmonkt2_d_01_helm.blp",
        id = "mn2thead",
        isTwoHanded = false,
        itemLevel = 75,
        itemSetKey = "t2_monk_tank",
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
        name = "Headguard of the August Acolyte",
        prismaticSockets = 0,
        quality = "epic",
        redSockets = 0,
        sellPrice = 0,
        skillBonuses = { },
        socketTypes = { },
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
                value = 183,
            },
            {
                sourceStatRef = "f82db71a:xqz0daz2",
                value = 25,
            },
            {
                sourceStatRef = "f82db71a:ygjno50i",
                value = 35,
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
                sourceStatRef = "f82db71a:0wyp78x9",
                value = 13,
            },
        },
        tags = { },
        targetArmorWeight = "none",
        targetSlotRefs = { },
        targetTwoHandedOnly = false,
        uniqueFlag = "none",
        validSlotRefs = {
            "f82db71a:bgvs1zx6",
        },
        yellowSockets = 0,
    },
}
```

## Legguards of the August Acolyte

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "items",
    datasetId = "monkdata",
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
                    "monkdata:monk0001",
                },
                invert = false,
                showOnTooltip = true,
                tooltipTextOverride = "Classes: Monk",
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
        icon = "interface/icons/inv_leather_raidmonkt2_d_01_pant.blp",
        id = "mn2tlegs",
        isTwoHanded = false,
        itemLevel = 75,
        itemSetKey = "t2_monk_tank",
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
        name = "Legguards of the August Acolyte",
        prismaticSockets = 0,
        quality = "epic",
        redSockets = 0,
        sellPrice = 0,
        skillBonuses = { },
        socketTypes = { },
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
                value = 197,
            },
            {
                sourceStatRef = "f82db71a:xqz0daz2",
                value = 23,
            },
            {
                sourceStatRef = "f82db71a:ygjno50i",
                value = 34,
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
                sourceStatRef = "f82db71a:0wyp78x9",
                value = 14,
            },
        },
        tags = { },
        targetArmorWeight = "none",
        targetSlotRefs = { },
        targetTwoHandedOnly = false,
        uniqueFlag = "none",
        validSlotRefs = {
            "f82db71a:obmt4ntq",
        },
        yellowSockets = 1,
    },
}
```

## Shoulderguards of the August Acolyte

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "items",
    datasetId = "monkdata",
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
                    "monkdata:monk0001",
                },
                invert = false,
                showOnTooltip = true,
                tooltipTextOverride = "Classes: Monk",
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
        icon = "interface/icons/inv_leather_raidmonkt2_d_01_shoulder.blp",
        id = "mn2tshld",
        isTwoHanded = false,
        itemLevel = 75,
        itemSetKey = "t2_monk_tank",
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
        name = "Shoulderguards of the August Acolyte",
        prismaticSockets = 0,
        quality = "epic",
        redSockets = 0,
        sellPrice = 0,
        skillBonuses = { },
        socketTypes = { },
        sockets = { },
        stats = {
            {
                sourceStatRef = "f82db71a:v42albuv",
                value = 169,
            },
            {
                sourceStatRef = "f82db71a:xqz0daz2",
                value = 13,
            },
            {
                sourceStatRef = "f82db71a:ygjno50i",
                value = 28,
            },
            {
                sourceStatRef = "f82db71a:jjn0my8k",
                value = 10,
            },
            {
                sourceStatRef = "f82db71a:0wyp78x9",
                value = 11,
            },
        },
        tags = { },
        targetArmorWeight = "none",
        targetSlotRefs = { },
        targetTwoHandedOnly = false,
        uniqueFlag = "none",
        validSlotRefs = {
            "f82db71a:66i80qm1",
        },
        yellowSockets = 0,
    },
}
```

## Waistguard of the August Acolyte

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "items",
    datasetId = "monkdata",
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
                    "monkdata:monk0001",
                },
                invert = false,
                showOnTooltip = true,
                tooltipTextOverride = "Classes: Monk",
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
        icon = "interface/icons/inv_leather_raidmonkt2_d_01_belt.blp",
        id = "mn2twast",
        isTwoHanded = false,
        itemLevel = 75,
        itemSetKey = "t2_monk_tank",
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
        name = "Waistguard of the August Acolyte",
        prismaticSockets = 0,
        quality = "epic",
        redSockets = 0,
        sellPrice = 0,
        skillBonuses = { },
        socketTypes = { },
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
                sourceStatRef = "f82db71a:xqz0daz2",
                value = 18,
            },
            {
                sourceStatRef = "f82db71a:ygjno50i",
                value = 26,
            },
            {
                sourceStatRef = "f82db71a:jjn0my8k",
                value = 10,
            },
            {
                sourceStatRef = "f82db71a:wbj4zuf3",
                value = 1,
            },
            {
                sourceStatRef = "f82db71a:0wyp78x9",
                value = 7,
            },
        },
        tags = { },
        targetArmorWeight = "none",
        targetSlotRefs = { },
        targetTwoHandedOnly = false,
        uniqueFlag = "none",
        validSlotRefs = {
            "f82db71a:haks0gz4",
        },
        yellowSockets = 0,
    },
}
```

## Wristguards of the August Acolyte

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "items",
    datasetId = "monkdata",
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
                    "monkdata:monk0001",
                },
                invert = false,
                showOnTooltip = true,
                tooltipTextOverride = "Classes: Monk",
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
        icon = "interface/icons/inv_leather_raidmonkt2_d_01_bracer.blp",
        id = "mn2twris",
        isTwoHanded = false,
        itemLevel = 75,
        itemSetKey = "t2_monk_tank",
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
        name = "Wristguards of the August Acolyte",
        prismaticSockets = 0,
        quality = "epic",
        redSockets = 0,
        sellPrice = 0,
        skillBonuses = { },
        socketTypes = { },
        sockets = { },
        stats = {
            {
                sourceStatRef = "f82db71a:v42albuv",
                value = 98,
            },
            {
                sourceStatRef = "f82db71a:xqz0daz2",
                value = 11,
            },
            {
                sourceStatRef = "f82db71a:ygjno50i",
                value = 21,
            },
            {
                sourceStatRef = "f82db71a:wbj4zuf3",
                value = 1,
            },
            {
                sourceStatRef = "f82db71a:0wyp78x9",
                value = 7,
            },
        },
        tags = { },
        targetArmorWeight = "none",
        targetSlotRefs = { },
        targetTwoHandedOnly = false,
        uniqueFlag = "none",
        validSlotRefs = {
            "f82db71a:crezt6ix",
        },
        yellowSockets = 0,
    },
}
```

