# Pale Rider's Eternal Armor — Unholy DPS

Invented RPE Tier 2 Unholy Death Knight set using the existing Warrior Tier 2 melee-DPS primary-stat budget, with two existing hit points assigned to Spell Hit and one retained as Melee Hit.

Each block below is a standalone `RPE_DATASET_ENTRY_V1` import code for the Death Knight dataset (`dknight1`).

## Pale Rider's Eternal Cuirass

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
        icon = "interface/icons/inv_chest_plate_raiddeathknightt2_d_01.blp",
        id = "dk2uchst",
        isTwoHanded = false,
        itemLevel = 75,
        itemSetKey = "t2_dk_unholy",
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
        name = "Pale Rider's Eternal Cuirass",
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
                value = 857,
            },
            {
                sourceStatRef = "f82db71a:zfqm8dxp",
                value = 32,
            },
            {
                sourceStatRef = "f82db71a:xqz0daz2",
                value = 30,
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
                sourceStatRef = "f82db71a:jjn0my8k",
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

## Pale Rider's Eternal Greaves

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
        id = "dk2ugrev",
        isTwoHanded = false,
        itemLevel = 75,
        itemSetKey = "t2_dk_unholy",
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
        name = "Pale Rider's Eternal Greaves",
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
                value = 26,
            },
            {
                sourceStatRef = "f82db71a:xqz0daz2",
                value = 16,
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
                sourceStatRef = "f82db71a:v2g0tw0o",
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

## Pale Rider's Eternal Gauntlets

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
        id = "dk2ugaun",
        isTwoHanded = false,
        itemLevel = 75,
        itemSetKey = "t2_dk_unholy",
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
        name = "Pale Rider's Eternal Gauntlets",
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
                value = 27,
            },
            {
                sourceStatRef = "f82db71a:xqz0daz2",
                value = 11,
            },
            {
                sourceStatRef = "f82db71a:ygjno50i",
                value = 16,
            },
            {
                sourceStatRef = "f82db71a:pg0ytacb",
                value = 10,
            },
            {
                sourceStatRef = "f82db71a:v2g0tw0o",
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

## Pale Rider's Eternal Crown

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
        icon = "interface/icons/inv_helm_plate_raiddeathknightt2_d_01.blp",
        id = "dk2ucrow",
        isTwoHanded = false,
        itemLevel = 75,
        itemSetKey = "t2_dk_unholy",
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
        name = "Pale Rider's Eternal Crown",
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
                value = 696,
            },
            {
                sourceStatRef = "f82db71a:zfqm8dxp",
                value = 36,
            },
            {
                sourceStatRef = "f82db71a:xqz0daz2",
                value = 24,
            },
            {
                sourceStatRef = "f82db71a:ygjno50i",
                value = 18,
            },
            {
                sourceStatRef = "f82db71a:pg0ytacb",
                value = 10,
            },
            {
                sourceStatRef = "f82db71a:jjn0my8k",
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

## Pale Rider's Eternal Legplates

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
        icon = "interface/icons/inv_pant_plate_raiddeathknightt2_d_01.blp",
        id = "dk2ulegs",
        isTwoHanded = false,
        itemLevel = 75,
        itemSetKey = "t2_dk_unholy",
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
        name = "Pale Rider's Eternal Legplates",
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
                value = 749,
            },
            {
                sourceStatRef = "f82db71a:zfqm8dxp",
                value = 33,
            },
            {
                sourceStatRef = "f82db71a:xqz0daz2",
                value = 26,
            },
            {
                sourceStatRef = "f82db71a:ygjno50i",
                value = 19,
            },
            {
                sourceStatRef = "f82db71a:pg0ytacb",
                value = 10,
            },
            {
                sourceStatRef = "f82db71a:jjn0my8k",
                value = 10,
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

## Pale Rider's Eternal Spaulders

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
        id = "dk2uspau",
        isTwoHanded = false,
        itemLevel = 75,
        itemSetKey = "t2_dk_unholy",
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
        name = "Pale Rider's Eternal Spaulders",
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
                value = 27,
            },
            {
                sourceStatRef = "f82db71a:xqz0daz2",
                value = 14,
            },
            {
                sourceStatRef = "f82db71a:ygjno50i",
                value = 12,
            },
            {
                sourceStatRef = "f82db71a:jjn0my8k",
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
            "f82db71a:66i80qm1",
        },
        yellowSockets = 0,
    },
}
```

## Pale Rider's Eternal Belt

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
        icon = "interface/icons/inv_belt_plate_raiddeathknightt2_d_01.blp",
        id = "dk2ubelt",
        isTwoHanded = false,
        itemLevel = 75,
        itemSetKey = "t2_dk_unholy",
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
        name = "Pale Rider's Eternal Belt",
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
                value = 482,
            },
            {
                sourceStatRef = "f82db71a:zfqm8dxp",
                value = 30,
            },
            {
                sourceStatRef = "f82db71a:ygjno50i",
                value = 11,
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

## Pale Rider's Eternal Bracers

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
        id = "dk2ubrac",
        isTwoHanded = false,
        itemLevel = 75,
        itemSetKey = "t2_dk_unholy",
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
        name = "Pale Rider's Eternal Bracers",
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
                value = 20,
            },
            {
                sourceStatRef = "f82db71a:xqz0daz2",
                value = 14,
            },
            {
                sourceStatRef = "f82db71a:ygjno50i",
                value = 14,
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

