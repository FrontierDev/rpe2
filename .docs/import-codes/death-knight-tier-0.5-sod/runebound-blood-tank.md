# Runebound Battlegear — Blood Tank

Invented Death Knight Dungeon Set 2 / Tier 0.5 Blood variant using the existing Soulforge Protection budget. Its five shield-only Block points are converted one-for-one to Parry Chance.

Each block below is a standalone `RPE_DATASET_ENTRY_V1` import code for the Death Knight dataset (`dknight1`).

All pieces are normalized to RPE item level **60**. Chest, feet, hands and head are **epic**; legs, shoulders, waist and wrists are **rare**. No sockets are added.

## Runebound Chestguard

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "items",
    datasetId = "dknight1",
    entry = {
        allowWowConversion = false,
        armorWeight = "plate",
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
                    "dknight1:dkclass1",
                },
                invert = false,
                showOnTooltip = true,
                tooltipTextOverride = "Classes: Death Knight",
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
        icon = "interface/icons/inv_chest_plate03.blp",
        id = "dk05bchs",
        isTwoHanded = false,
        itemLevel = 60,
        itemSetKey = "t05_dk_runebound",
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
        name = "Runebound Chestguard",
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
                value = 684,
            },
            {
                sourceStatRef = "f82db71a:zfqm8dxp",
                value = 16,
            },
            {
                sourceStatRef = "f82db71a:ygjno50i",
                value = 31,
            },
            {
                sourceStatRef = "f82db71a:wbj4zuf3",
                value = 1,
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

## Runebound Sabatons

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "items",
    datasetId = "dknight1",
    entry = {
        allowWowConversion = false,
        armorWeight = "plate",
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
                    "dknight1:dkclass1",
                },
                invert = false,
                showOnTooltip = true,
                tooltipTextOverride = "Classes: Death Knight",
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
        icon = "interface/icons/inv_boots_plate_03.blp",
        id = "dk05bsab",
        isTwoHanded = false,
        itemLevel = 60,
        itemSetKey = "t05_dk_runebound",
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
        name = "Runebound Sabatons",
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
                value = 470,
            },
            {
                sourceStatRef = "f82db71a:zfqm8dxp",
                value = 13,
            },
            {
                sourceStatRef = "f82db71a:ygjno50i",
                value = 20,
            },
            {
                sourceStatRef = "f82db71a:wbj4zuf3",
                value = 1,
            },
            {
                sourceStatRef = "f82db71a:v2g0tw0o",
                value = 1,
            },
            {
                sourceStatRef = "f82db71a:0wyp78x9",
                value = 8,
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

## Runebound Grips

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "items",
    datasetId = "dknight1",
    entry = {
        allowWowConversion = false,
        armorWeight = "plate",
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
                    "dknight1:dkclass1",
                },
                invert = false,
                showOnTooltip = true,
                tooltipTextOverride = "Classes: Death Knight",
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
        icon = "interface/icons/inv_gauntlets_26.blp",
        id = "dk05bgri",
        isTwoHanded = false,
        itemLevel = 60,
        itemSetKey = "t05_dk_runebound",
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
        name = "Runebound Grips",
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
                value = 393,
            },
            {
                sourceStatRef = "f82db71a:ygjno50i",
                value = 18,
            },
            {
                sourceStatRef = "f82db71a:tcn0s8kx",
                value = 3,
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

## Runebound Faceguard

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "items",
    datasetId = "dknight1",
    entry = {
        allowWowConversion = false,
        armorWeight = "plate",
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
                    "dknight1:dkclass1",
                },
                invert = false,
                showOnTooltip = true,
                tooltipTextOverride = "Classes: Death Knight",
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
        icon = "interface/icons/inv_helmet_02.blp",
        id = "dk05bfac",
        isTwoHanded = false,
        itemLevel = 60,
        itemSetKey = "t05_dk_runebound",
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
        name = "Runebound Faceguard",
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
                value = 556,
            },
            {
                sourceStatRef = "f82db71a:zfqm8dxp",
                value = 13,
            },
            {
                sourceStatRef = "f82db71a:ygjno50i",
                value = 32,
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

## Runebound Legguards

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "items",
    datasetId = "dknight1",
    entry = {
        allowWowConversion = false,
        armorWeight = "plate",
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
                    "dknight1:dkclass1",
                },
                invert = false,
                showOnTooltip = true,
                tooltipTextOverride = "Classes: Death Knight",
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
        icon = "interface/icons/inv_pants_04.blp",
        id = "dk05bleg",
        isTwoHanded = false,
        itemLevel = 60,
        itemSetKey = "t05_dk_runebound",
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
        name = "Runebound Legguards",
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
                value = 601,
            },
            {
                sourceStatRef = "f82db71a:zfqm8dxp",
                value = 8,
            },
            {
                sourceStatRef = "f82db71a:ygjno50i",
                value = 26,
            },
            {
                sourceStatRef = "f82db71a:tcn0s8kx",
                value = 1,
            },
            {
                sourceStatRef = "f82db71a:0wyp78x9",
                value = 8,
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

## Runebound Shoulderguards

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "items",
    datasetId = "dknight1",
    entry = {
        allowWowConversion = false,
        armorWeight = "plate",
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
                    "dknight1:dkclass1",
                },
                invert = false,
                showOnTooltip = true,
                tooltipTextOverride = "Classes: Death Knight",
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
        icon = "interface/icons/inv_shoulder_30.blp",
        id = "dk05bsho",
        isTwoHanded = false,
        itemLevel = 60,
        itemSetKey = "t05_dk_runebound",
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
        name = "Runebound Shoulderguards",
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
                value = 507,
            },
            {
                sourceStatRef = "f82db71a:zfqm8dxp",
                value = 12,
            },
            {
                sourceStatRef = "f82db71a:ygjno50i",
                value = 18,
            },
            {
                sourceStatRef = "f82db71a:0wyp78x9",
                value = 9,
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

## Runebound Waistguard

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "items",
    datasetId = "dknight1",
    entry = {
        allowWowConversion = false,
        armorWeight = "plate",
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
                    "dknight1:dkclass1",
                },
                invert = false,
                showOnTooltip = true,
                tooltipTextOverride = "Classes: Death Knight",
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
        icon = "interface/icons/inv_belt_34.blp",
        id = "dk05bwai",
        isTwoHanded = false,
        itemLevel = 60,
        itemSetKey = "t05_dk_runebound",
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
        name = "Runebound Waistguard",
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
                value = 380,
            },
            {
                sourceStatRef = "f82db71a:zfqm8dxp",
                value = 12,
            },
            {
                sourceStatRef = "f82db71a:ygjno50i",
                value = 15,
            },
            {
                sourceStatRef = "f82db71a:tcn0s8kx",
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

## Runebound Wristguards

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "items",
    datasetId = "dknight1",
    entry = {
        allowWowConversion = false,
        armorWeight = "plate",
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
                    "dknight1:dkclass1",
                },
                invert = false,
                showOnTooltip = true,
                tooltipTextOverride = "Classes: Death Knight",
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
        icon = "interface/icons/inv_bracer_17.blp",
        id = "dk05bwri",
        isTwoHanded = false,
        itemLevel = 60,
        itemSetKey = "t05_dk_runebound",
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
        name = "Runebound Wristguards",
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
                value = 296,
            },
            {
                sourceStatRef = "f82db71a:zfqm8dxp",
                value = 8,
            },
            {
                sourceStatRef = "f82db71a:ygjno50i",
                value = 14,
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

