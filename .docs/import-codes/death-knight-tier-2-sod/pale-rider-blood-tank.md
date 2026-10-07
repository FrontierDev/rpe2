# Pale Rider's Eternal Armor — Blood Tank

Invented RPE Tier 2 Blood Death Knight set using the existing Warrior Tier 2 tank primary/defense budget, with the five existing hit points split between Melee Hit and Spell Hit.

Each block below is a standalone `RPE_DATASET_ENTRY_V1` import code for the Death Knight dataset (`dknight1`).

## Pale Rider's Eternal Chestguard

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
        icon = "interface/icons/inv_chest_plate_raiddeathknightt2_d_01.blp",
        id = "dk2bchst",
        isTwoHanded = false,
        itemLevel = 75,
        itemSetKey = "t2_dk_blood",
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
        name = "Pale Rider's Eternal Chestguard",
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
                value = 857,
            },
            {
                sourceStatRef = "f82db71a:zfqm8dxp",
                value = 18,
            },
            {
                sourceStatRef = "f82db71a:xqz0daz2",
                value = 11,
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
        yellowSockets = 1,
    },
}
```

## Pale Rider's Eternal Warboots

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
        icon = "interface/icons/inv_boot_plate_raiddeathknightt2_d_01.blp",
        id = "dk2bboot",
        isTwoHanded = false,
        itemLevel = 75,
        itemSetKey = "t2_dk_blood",
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
        name = "Pale Rider's Eternal Warboots",
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
                value = 589,
            },
            {
                sourceStatRef = "f82db71a:zfqm8dxp",
                value = 10,
            },
            {
                sourceStatRef = "f82db71a:xqz0daz2",
                value = 10,
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

## Pale Rider's Eternal Handguards

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
        icon = "interface/icons/inv_glove_plate_raiddeathknightt2_d_01.blp",
        id = "dk2bhand",
        isTwoHanded = false,
        itemLevel = 75,
        itemSetKey = "t2_dk_blood",
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
        name = "Pale Rider's Eternal Handguards",
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
                value = 535,
            },
            {
                sourceStatRef = "f82db71a:zfqm8dxp",
                value = 19,
            },
            {
                sourceStatRef = "f82db71a:ygjno50i",
                value = 24,
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
            "f82db71a:wasvuom2",
        },
        yellowSockets = 0,
    },
}
```

## Pale Rider's Eternal Faceguard

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
        icon = "interface/icons/inv_helm_plate_raiddeathknightt2_d_01.blp",
        id = "dk2bface",
        isTwoHanded = false,
        itemLevel = 75,
        itemSetKey = "t2_dk_blood",
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
        name = "Pale Rider's Eternal Faceguard",
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
                value = 696,
            },
            {
                sourceStatRef = "f82db71a:zfqm8dxp",
                value = 23,
            },
            {
                sourceStatRef = "f82db71a:xqz0daz2",
                value = 13,
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
                value = 10,
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

## Pale Rider's Eternal Legguards

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
        icon = "interface/icons/inv_pant_plate_raiddeathknightt2_d_01.blp",
        id = "dk2blegs",
        isTwoHanded = false,
        itemLevel = 75,
        itemSetKey = "t2_dk_blood",
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
        name = "Pale Rider's Eternal Legguards",
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
                value = 749,
            },
            {
                sourceStatRef = "f82db71a:zfqm8dxp",
                value = 15,
            },
            {
                sourceStatRef = "f82db71a:ygjno50i",
                value = 28,
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
                value = 1,
            },
            {
                sourceStatRef = "f82db71a:0wyp78x9",
                value = 19,
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

## Pale Rider's Eternal Shoulderguards

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
        icon = "interface/icons/inv_shoulder_plate_raiddeathknightt2_d_01.blp",
        id = "dk2bshld",
        isTwoHanded = false,
        itemLevel = 75,
        itemSetKey = "t2_dk_blood",
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
        name = "Pale Rider's Eternal Shoulderguards",
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
                value = 642,
            },
            {
                sourceStatRef = "f82db71a:zfqm8dxp",
                value = 12,
            },
            {
                sourceStatRef = "f82db71a:xqz0daz2",
                value = 10,
            },
            {
                sourceStatRef = "f82db71a:ygjno50i",
                value = 24,
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

## Pale Rider's Eternal Waistguard

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
        icon = "interface/icons/inv_belt_plate_raiddeathknightt2_d_01.blp",
        id = "dk2bwast",
        isTwoHanded = false,
        itemLevel = 75,
        itemSetKey = "t2_dk_blood",
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
        name = "Pale Rider's Eternal Waistguard",
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
                value = 482,
            },
            {
                sourceStatRef = "f82db71a:zfqm8dxp",
                value = 15,
            },
            {
                sourceStatRef = "f82db71a:xqz0daz2",
                value = 7,
            },
            {
                sourceStatRef = "f82db71a:ygjno50i",
                value = 24,
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

## Pale Rider's Eternal Wristguards

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
        icon = "interface/icons/inv_bracer_plate_raiddeathknightt2_d_01.blp",
        id = "dk2bwris",
        isTwoHanded = false,
        itemLevel = 75,
        itemSetKey = "t2_dk_blood",
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
        name = "Pale Rider's Eternal Wristguards",
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
                value = 375,
            },
            {
                sourceStatRef = "f82db71a:zfqm8dxp",
                value = 12,
            },
            {
                sourceStatRef = "f82db71a:xqz0daz2",
                value = 10,
            },
            {
                sourceStatRef = "f82db71a:ygjno50i",
                value = 20,
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

