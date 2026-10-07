# Cloudwalker Raiment — Mistweaver Healer

Invented Monk Dungeon Set 2 / Tier 0.5 Mistweaver variant using the existing Feralheart Restoration leather stat budget.

Each block below is a standalone `RPE_DATASET_ENTRY_V1` import code for the Monk dataset (`monkdata`).

All pieces are normalized to RPE item level **60**. Chest, feet, hands and head are **epic**; legs, shoulders, waist and wrists are **rare**. No sockets are added.

## Cloudwalker Embrace

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
        id = "mn05hemb",
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
        name = "Cloudwalker Embrace",
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
                sourceStatRef = "f82db71a:75y3a8ib",
                value = 20,
            },
            {
                sourceStatRef = "f82db71a:ygjno50i",
                value = 11,
            },
            {
                sourceStatRef = "f82db71a:kec9rhli",
                value = 17,
            },
            {
                sourceStatRef = "f82db71a:hj6d4kvy",
                value = 55,
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

## Cloudwalker Sandals

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
        id = "mn05hsan",
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
        name = "Cloudwalker Sandals",
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
                sourceStatRef = "f82db71a:75y3a8ib",
                value = 16,
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
                sourceStatRef = "f82db71a:hj6d4kvy",
                value = 31,
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

## Cloudwalker Gauntlets

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
        id = "mn05hgau",
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
        name = "Cloudwalker Gauntlets",
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
                sourceStatRef = "f82db71a:75y3a8ib",
                value = 15,
            },
            {
                sourceStatRef = "f82db71a:ygjno50i",
                value = 12,
            },
            {
                sourceStatRef = "f82db71a:hj6d4kvy",
                value = 40,
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

## Cloudwalker Headdress

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
        id = "mn05hhea",
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
        name = "Cloudwalker Headdress",
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
                sourceStatRef = "f82db71a:75y3a8ib",
                value = 21,
            },
            {
                sourceStatRef = "f82db71a:ygjno50i",
                value = 19,
            },
            {
                sourceStatRef = "f82db71a:hj6d4kvy",
                value = 37,
            },
            {
                sourceStatRef = "f82db71a:rgnrtg01",
                value = 6,
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

## Cloudwalker Leggings

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
        id = "mn05hleg",
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
        name = "Cloudwalker Leggings",
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
                sourceStatRef = "f82db71a:75y3a8ib",
                value = 23,
            },
            {
                sourceStatRef = "f82db71a:ygjno50i",
                value = 18,
            },
            {
                sourceStatRef = "f82db71a:kec9rhli",
                value = 14,
            },
            {
                sourceStatRef = "f82db71a:hj6d4kvy",
                value = 42,
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

## Cloudwalker Mantle

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
        id = "mn05hman",
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
        name = "Cloudwalker Mantle",
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
                sourceStatRef = "f82db71a:75y3a8ib",
                value = 12,
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
                sourceStatRef = "f82db71a:hj6d4kvy",
                value = 35,
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

## Cloudwalker Cord

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
        id = "mn05hcor",
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
        name = "Cloudwalker Cord",
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
                sourceStatRef = "f82db71a:75y3a8ib",
                value = 15,
            },
            {
                sourceStatRef = "f82db71a:ygjno50i",
                value = 11,
            },
            {
                sourceStatRef = "f82db71a:hj6d4kvy",
                value = 35,
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

## Cloudwalker Cuffs

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
        id = "mn05hcuf",
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
        name = "Cloudwalker Cuffs",
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
                sourceStatRef = "f82db71a:75y3a8ib",
                value = 11,
            },
            {
                sourceStatRef = "f82db71a:ygjno50i",
                value = 7,
            },
            {
                sourceStatRef = "f82db71a:kec9rhli",
                value = 9,
            },
            {
                sourceStatRef = "f82db71a:hj6d4kvy",
                value = 24,
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

