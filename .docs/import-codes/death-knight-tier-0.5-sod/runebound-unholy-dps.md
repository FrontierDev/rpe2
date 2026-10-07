# Runebound Battlegear — Unholy DPS

Invented Death Knight Dungeon Set 2 / Tier 0.5 Unholy variant using the existing Battlegear of Heroism DPS budget, with two existing hit points assigned to Spell Hit and two retained as Melee Hit.

Each block below is a standalone `RPE_DATASET_ENTRY_V1` import code for the Death Knight dataset (`dknight1`).

All pieces are normalized to RPE item level **60**. Chest, feet, hands and head are **epic**; legs, shoulders, waist and wrists are **rare**. No sockets are added.

## Runebound Cuirass

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
        id = "dk05uchs",
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
        name = "Runebound Cuirass",
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
                value = 25,
            },
            {
                sourceStatRef = "f82db71a:xqz0daz2",
                value = 13,
            },
            {
                sourceStatRef = "f82db71a:ygjno50i",
                value = 24,
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
            "f82db71a:nwfvxbto",
        },
        yellowSockets = 0,
    },
}
```

## Runebound Greaves

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
        id = "dk05ugre",
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
        name = "Runebound Greaves",
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
                value = 23,
            },
            {
                sourceStatRef = "f82db71a:ygjno50i",
                value = 16,
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

## Runebound Handguards

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
        id = "dk05uhan",
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
        name = "Runebound Handguards",
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
                sourceStatRef = "f82db71a:zfqm8dxp",
                value = 19,
            },
            {
                sourceStatRef = "f82db71a:ygjno50i",
                value = 14,
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

## Runebound Helm

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
        id = "dk05uhel",
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
        name = "Runebound Helm",
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
                value = 27,
            },
            {
                sourceStatRef = "f82db71a:ygjno50i",
                value = 24,
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

## Runebound Leggings

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
        id = "dk05uleg",
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
        name = "Runebound Leggings",
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
                value = 28,
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
            "f82db71a:obmt4ntq",
        },
        yellowSockets = 0,
    },
}
```

## Runebound Pauldrons

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
        id = "dk05upau",
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
        name = "Runebound Pauldrons",
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
                value = 18,
            },
            {
                sourceStatRef = "f82db71a:xqz0daz2",
                value = 10,
            },
            {
                sourceStatRef = "f82db71a:ygjno50i",
                value = 7,
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

## Runebound Girdle

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
        id = "dk05ugir",
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
        name = "Runebound Girdle",
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
                value = 17,
            },
            {
                sourceStatRef = "f82db71a:ygjno50i",
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
        yellowSockets = 0,
    },
}
```

## Runebound Vambraces

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
        id = "dk05uvam",
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
        name = "Runebound Vambraces",
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
                value = 15,
            },
            {
                sourceStatRef = "f82db71a:xqz0daz2",
                value = 8,
            },
            {
                sourceStatRef = "f82db71a:ygjno50i",
                value = 6,
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

