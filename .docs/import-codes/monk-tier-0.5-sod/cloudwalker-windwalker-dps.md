# Cloudwalker Raiment — Windwalker DPS

Invented Monk Dungeon Set 2 / Tier 0.5 Windwalker variant using the existing Darkmantle DPS leather stat budget.

Each block below is a standalone `RPE_DATASET_ENTRY_V1` import code for the Monk dataset (`monkdata`).

All pieces are normalized to RPE item level **60**. Chest, feet, hands and head are **epic**; legs, shoulders, waist and wrists are **rare**. No sockets are added.

## Cloudwalker Tunic

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
        icon = "interface/icons/inv_chest_leather_07.blp",
        id = "mn05dtun",
        isTwoHanded = false,
        itemLevel = 60,
        itemSetKey = "t05_monk_cloudwalker",
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
        name = "Cloudwalker Tunic",
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
                value = 185,
            },
            {
                sourceStatRef = "f82db71a:xqz0daz2",
                value = 31,
            },
            {
                sourceStatRef = "f82db71a:ygjno50i",
                value = 15,
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
        yellowSockets = 0,
    },
}
```

## Cloudwalker Footpads

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
        icon = "interface/icons/inv_boots_08.blp",
        id = "mn05dft1",
        isTwoHanded = false,
        itemLevel = 60,
        itemSetKey = "t05_monk_cloudwalker",
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
        name = "Cloudwalker Footpads",
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
                value = 127,
            },
            {
                sourceStatRef = "f82db71a:zfqm8dxp",
                value = 7,
            },
            {
                sourceStatRef = "f82db71a:xqz0daz2",
                value = 24,
            },
            {
                sourceStatRef = "f82db71a:ygjno50i",
                value = 10,
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

## Cloudwalker Grips

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
        icon = "interface/icons/inv_gauntlets_24.blp",
        id = "mn05dgrp",
        isTwoHanded = false,
        itemLevel = 60,
        itemSetKey = "t05_monk_cloudwalker",
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
        name = "Cloudwalker Grips",
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
                value = 108,
            },
            {
                sourceStatRef = "f82db71a:zfqm8dxp",
                value = 13,
            },
            {
                sourceStatRef = "f82db71a:xqz0daz2",
                value = 22,
            },
            {
                sourceStatRef = "f82db71a:ygjno50i",
                value = 9,
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

## Cloudwalker Cap

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
        icon = "interface/icons/inv_helmet_41.blp",
        id = "mn05dcap",
        isTwoHanded = false,
        itemLevel = 60,
        itemSetKey = "t05_monk_cloudwalker",
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
        name = "Cloudwalker Cap",
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
                value = 150,
            },
            {
                sourceStatRef = "f82db71a:zfqm8dxp",
                value = 16,
            },
            {
                sourceStatRef = "f82db71a:xqz0daz2",
                value = 29,
            },
            {
                sourceStatRef = "f82db71a:ygjno50i",
                value = 15,
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
            "f82db71a:bgvs1zx6",
        },
        yellowSockets = 0,
    },
}
```

## Cloudwalker Pants

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
        icon = "interface/icons/inv_pants_02.blp",
        id = "mn05dpnt",
        isTwoHanded = false,
        itemLevel = 60,
        itemSetKey = "t05_monk_cloudwalker",
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
        name = "Cloudwalker Pants",
        prismaticSockets = 0,
        quality = "rare",
        redSockets = 0,
        sellPrice = 0,
        skillBonuses = { },
        socketTypes = { },
        sockets = { },
        stats = {
            {
                sourceStatRef = "f82db71a:v42albuv",
                value = 160,
            },
            {
                sourceStatRef = "f82db71a:zfqm8dxp",
                value = 14,
            },
            {
                sourceStatRef = "f82db71a:xqz0daz2",
                value = 25,
            },
            {
                sourceStatRef = "f82db71a:ygjno50i",
                value = 13,
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
            "f82db71a:obmt4ntq",
        },
        yellowSockets = 0,
    },
}
```

## Cloudwalker Spaulders

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
        icon = "interface/icons/inv_shoulder_07.blp",
        id = "mn05dspa",
        isTwoHanded = false,
        itemLevel = 60,
        itemSetKey = "t05_monk_cloudwalker",
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
        name = "Cloudwalker Spaulders",
        prismaticSockets = 0,
        quality = "rare",
        redSockets = 0,
        sellPrice = 0,
        skillBonuses = { },
        socketTypes = { },
        sockets = { },
        stats = {
            {
                sourceStatRef = "f82db71a:v42albuv",
                value = 136,
            },
            {
                sourceStatRef = "f82db71a:xqz0daz2",
                value = 22,
            },
            {
                sourceStatRef = "f82db71a:ygjno50i",
                value = 5,
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
            "f82db71a:66i80qm1",
        },
        yellowSockets = 0,
    },
}
```

## Cloudwalker Belt

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
        icon = "interface/icons/inv_belt_03.blp",
        id = "mn05dbel",
        isTwoHanded = false,
        itemLevel = 60,
        itemSetKey = "t05_monk_cloudwalker",
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
        name = "Cloudwalker Belt",
        prismaticSockets = 0,
        quality = "rare",
        redSockets = 0,
        sellPrice = 0,
        skillBonuses = { },
        socketTypes = { },
        sockets = { },
        stats = {
            {
                sourceStatRef = "f82db71a:v42albuv",
                value = 102,
            },
            {
                sourceStatRef = "f82db71a:zfqm8dxp",
                value = 13,
            },
            {
                sourceStatRef = "f82db71a:xqz0daz2",
                value = 19,
            },
            {
                sourceStatRef = "f82db71a:ygjno50i",
                value = 10,
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

## Cloudwalker Bindings

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
        icon = "interface/icons/inv_bracer_07.blp",
        id = "mn05dbnd",
        isTwoHanded = false,
        itemLevel = 60,
        itemSetKey = "t05_monk_cloudwalker",
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
        name = "Cloudwalker Bindings",
        prismaticSockets = 0,
        quality = "rare",
        redSockets = 0,
        sellPrice = 0,
        skillBonuses = { },
        socketTypes = { },
        sockets = { },
        stats = {
            {
                sourceStatRef = "f82db71a:v42albuv",
                value = 79,
            },
            {
                sourceStatRef = "f82db71a:xqz0daz2",
                value = 14,
            },
            {
                sourceStatRef = "f82db71a:ygjno50i",
                value = 8,
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

