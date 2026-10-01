# August Acolyte — Windwalker DPS

Invented RPE Tier 2 Windwalker set using the existing Bloodfang Thrill leather-DPS stat budget.

Each block below is a standalone `RPE_DATASET_ENTRY_V1` import code for the Monk dataset (`monkdata`).

## Vest of the August Acolyte

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
        icon = "interface/icons/inv_leather_raidmonkt2_d_01_chest.blp",
        id = "mn2dvest",
        isTwoHanded = false,
        itemLevel = 75,
        itemSetKey = "t2_monk_dps",
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
        name = "Vest of the August Acolyte",
        prismaticSockets = 0,
        quality = "epic",
        redSockets = 2,
        sellPrice = 0,
        skillBonuses = { },
        socketTypes = { },
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
                value = 225,
            },
            {
                sourceStatRef = "f82db71a:zfqm8dxp",
                value = 12,
            },
            {
                sourceStatRef = "f82db71a:xqz0daz2",
                value = 26,
            },
            {
                sourceStatRef = "f82db71a:ygjno50i",
                value = 17,
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
                sourceStatRef = "f82db71a:jslmczbi",
                value = 1,
            },
            {
                sourceStatRef = "f82db71a:wbj4zuf3",
                value = 2,
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

## Talons of the August Acolyte

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
        id = "mn2dtaln",
        isTwoHanded = false,
        itemLevel = 75,
        itemSetKey = "t2_monk_dps",
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
        name = "Talons of the August Acolyte",
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
                value = 25,
            },
            {
                sourceStatRef = "f82db71a:ygjno50i",
                value = 17,
            },
            {
                sourceStatRef = "f82db71a:pg0ytacb",
                value = 10,
            },
            {
                sourceStatRef = "f82db71a:jslmczbi",
                value = 1,
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

## Grips of the August Acolyte

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
        id = "mn2dgrip",
        isTwoHanded = false,
        itemLevel = 75,
        itemSetKey = "t2_monk_dps",
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
        name = "Grips of the August Acolyte",
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
                sourceStatRef = "f82db71a:zfqm8dxp",
                value = 16,
            },
            {
                sourceStatRef = "f82db71a:xqz0daz2",
                value = 20,
            },
            {
                sourceStatRef = "f82db71a:ygjno50i",
                value = 13,
            },
            {
                sourceStatRef = "f82db71a:pg0ytacb",
                value = 10,
            },
            {
                sourceStatRef = "f82db71a:jslmczbi",
                value = 1,
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

## Helm of the August Acolyte

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
        icon = "interface/icons/inv_leather_raidmonkt2_d_01_helm.blp",
        id = "mn2dhelm",
        isTwoHanded = false,
        itemLevel = 75,
        itemSetKey = "t2_monk_dps",
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
        name = "Helm of the August Acolyte",
        prismaticSockets = 0,
        quality = "epic",
        redSockets = 1,
        sellPrice = 0,
        skillBonuses = { },
        socketTypes = { },
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
                sourceStatRef = "f82db71a:zfqm8dxp",
                value = 16,
            },
            {
                sourceStatRef = "f82db71a:xqz0daz2",
                value = 34,
            },
            {
                sourceStatRef = "f82db71a:ygjno50i",
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
                sourceStatRef = "f82db71a:wbj4zuf3",
                value = 2,
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

## Pants of the August Acolyte

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
        icon = "interface/icons/inv_leather_raidmonkt2_d_01_pant.blp",
        id = "mn2dpant",
        isTwoHanded = false,
        itemLevel = 75,
        itemSetKey = "t2_monk_dps",
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
        name = "Pants of the August Acolyte",
        prismaticSockets = 0,
        quality = "epic",
        redSockets = 1,
        sellPrice = 0,
        skillBonuses = { },
        socketTypes = { },
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
                value = 197,
            },
            {
                sourceStatRef = "f82db71a:zfqm8dxp",
                value = 11,
            },
            {
                sourceStatRef = "f82db71a:xqz0daz2",
                value = 34,
            },
            {
                sourceStatRef = "f82db71a:ygjno50i",
                value = 17,
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
                sourceStatRef = "f82db71a:jslmczbi",
                value = 1,
            },
            {
                sourceStatRef = "f82db71a:wbj4zuf3",
                value = 1,
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

## Spaulders of the August Acolyte

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
        id = "mn2dspau",
        isTwoHanded = false,
        itemLevel = 75,
        itemSetKey = "t2_monk_dps",
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
        name = "Spaulders of the August Acolyte",
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
                sourceStatRef = "f82db71a:zfqm8dxp",
                value = 10,
            },
            {
                sourceStatRef = "f82db71a:xqz0daz2",
                value = 25,
            },
            {
                sourceStatRef = "f82db71a:ygjno50i",
                value = 15,
            },
            {
                sourceStatRef = "f82db71a:jjn0my8k",
                value = 10,
            },
            {
                sourceStatRef = "f82db71a:jslmczbi",
                value = 1,
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

## Cord of the August Acolyte

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
        icon = "interface/icons/inv_leather_raidmonkt2_d_01_belt.blp",
        id = "mn2dcord",
        isTwoHanded = false,
        itemLevel = 75,
        itemSetKey = "t2_monk_dps",
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
        name = "Cord of the August Acolyte",
        prismaticSockets = 0,
        quality = "epic",
        redSockets = 0,
        sellPrice = 0,
        skillBonuses = { },
        socketTypes = { },
        sockets = {
            {
                color = "yellow",
            },
        },
        stats = {
            {
                sourceStatRef = "f82db71a:v42albuv",
                value = 126,
            },
            {
                sourceStatRef = "f82db71a:zfqm8dxp",
                value = 15,
            },
            {
                sourceStatRef = "f82db71a:xqz0daz2",
                value = 20,
            },
            {
                sourceStatRef = "f82db71a:ygjno50i",
                value = 13,
            },
            {
                sourceStatRef = "f82db71a:jjn0my8k",
                value = 10,
            },
            {
                sourceStatRef = "f82db71a:jslmczbi",
                value = 1,
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
        yellowSockets = 1,
    },
}
```

## Bindings of the August Acolyte

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
        id = "mn2dbind",
        isTwoHanded = false,
        itemLevel = 75,
        itemSetKey = "t2_monk_dps",
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
        name = "Bindings of the August Acolyte",
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
                value = 24,
            },
            {
                sourceStatRef = "f82db71a:ygjno50i",
                value = 10,
            },
            {
                sourceStatRef = "f82db71a:wbj4zuf3",
                value = 1,
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

