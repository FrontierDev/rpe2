# Wyrmbound Raiment — Devastation / Augmentation

Invented RPE Tier 0.5 caster Evoker set shared by Devastation and Augmentation, using the existing Shaman The Five Thunders Elemental mail caster-DPS armor, primary-stat, quality, Spell Power, Spell Crit, Spell Hit, and Resource Regeneration budget slot-for-slot.

Each block below is a standalone `RPE_DATASET_ENTRY_V1` import code for the Evoker class dataset (`evokdata`).

All pieces are normalized to RPE item level **60**, use the shared Evoker Tier 0.5 set key `t05_evoker_wyrmbound`, and add no sockets.

## Wyrmbound Hauberk

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "items",
    datasetId = "evokdata",
    entry = {
        allowWowConversion = false,
        armorWeight = "mail",
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
                    "f82db71a:evoker01",
                },
                invert = false,
                showOnTooltip = true,
                tooltipTextOverride = "Classes: Evoker",
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
        icon = "interface/icons/inv_chest_chain_11.blp",
        id = "ev05cchst",
        isTwoHanded = false,
        itemLevel = 60,
        itemSetKey = "t05_evoker_wyrmbound",
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
        name = "Wyrmbound Hauberk",
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
                value = 387,
            },
            {
                sourceStatRef = "f82db71a:75y3a8ib",
                value = 17,
            },
            {
                sourceStatRef = "f82db71a:ygjno50i",
                value = 19,
            },
            {
                sourceStatRef = "f82db71a:69hfqhne",
                value = 1,
            },
            {
                sourceStatRef = "f82db71a:7t7xgzcx",
                value = 27,
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

## Wyrmbound Greaves

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "items",
    datasetId = "evokdata",
    entry = {
        allowWowConversion = false,
        armorWeight = "mail",
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
                    "f82db71a:evoker01",
                },
                invert = false,
                showOnTooltip = true,
                tooltipTextOverride = "Classes: Evoker",
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
        icon = "interface/icons/inv_boots_plate_06.blp",
        id = "ev05cboot",
        isTwoHanded = false,
        itemLevel = 60,
        itemSetKey = "t05_evoker_wyrmbound",
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
        name = "Wyrmbound Greaves",
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
                value = 266,
            },
            {
                sourceStatRef = "f82db71a:75y3a8ib",
                value = 13,
            },
            {
                sourceStatRef = "f82db71a:ygjno50i",
                value = 12,
            },
            {
                sourceStatRef = "f82db71a:7t7xgzcx",
                value = 25,
            },
            {
                sourceStatRef = "f82db71a:rgnrtg01",
                value = 4,
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

## Wyrmbound Gauntlets

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "items",
    datasetId = "evokdata",
    entry = {
        allowWowConversion = false,
        armorWeight = "mail",
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
                    "f82db71a:evoker01",
                },
                invert = false,
                showOnTooltip = true,
                tooltipTextOverride = "Classes: Evoker",
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
        icon = "interface/icons/inv_gauntlets_11.blp",
        id = "ev05cglov",
        isTwoHanded = false,
        itemLevel = 60,
        itemSetKey = "t05_evoker_wyrmbound",
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
        name = "Wyrmbound Gauntlets",
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
                value = 223,
            },
            {
                sourceStatRef = "f82db71a:75y3a8ib",
                value = 10,
            },
            {
                sourceStatRef = "f82db71a:ygjno50i",
                value = 10,
            },
            {
                sourceStatRef = "f82db71a:v2g0tw0o",
                value = 1,
            },
            {
                sourceStatRef = "f82db71a:7t7xgzcx",
                value = 23,
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

## Wyrmbound Crown

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "items",
    datasetId = "evokdata",
    entry = {
        allowWowConversion = false,
        armorWeight = "mail",
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
                    "f82db71a:evoker01",
                },
                invert = false,
                showOnTooltip = true,
                tooltipTextOverride = "Classes: Evoker",
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
        icon = "interface/icons/inv_helmet_04.blp",
        id = "ev05chelm",
        isTwoHanded = false,
        itemLevel = 60,
        itemSetKey = "t05_evoker_wyrmbound",
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
        name = "Wyrmbound Crown",
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
                value = 314,
            },
            {
                sourceStatRef = "f82db71a:75y3a8ib",
                value = 19,
            },
            {
                sourceStatRef = "f82db71a:ygjno50i",
                value = 18,
            },
            {
                sourceStatRef = "f82db71a:69hfqhne",
                value = 1,
            },
            {
                sourceStatRef = "f82db71a:7t7xgzcx",
                value = 27,
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

## Wyrmbound Legguards

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "items",
    datasetId = "evokdata",
    entry = {
        allowWowConversion = false,
        armorWeight = "mail",
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
                    "f82db71a:evoker01",
                },
                invert = false,
                showOnTooltip = true,
                tooltipTextOverride = "Classes: Evoker",
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
        icon = "interface/icons/inv_pants_03.blp",
        id = "ev05clegs",
        isTwoHanded = false,
        itemLevel = 60,
        itemSetKey = "t05_evoker_wyrmbound",
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
        name = "Wyrmbound Legguards",
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
                value = 339,
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
                sourceStatRef = "f82db71a:v2g0tw0o",
                value = 1,
            },
            {
                sourceStatRef = "f82db71a:7t7xgzcx",
                value = 29,
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

## Wyrmbound Mantle

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "items",
    datasetId = "evokdata",
    entry = {
        allowWowConversion = false,
        armorWeight = "mail",
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
                    "f82db71a:evoker01",
                },
                invert = false,
                showOnTooltip = true,
                tooltipTextOverride = "Classes: Evoker",
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
        icon = "interface/icons/inv_shoulder_29.blp",
        id = "ev05cspau",
        isTwoHanded = false,
        itemLevel = 60,
        itemSetKey = "t05_evoker_wyrmbound",
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
        name = "Wyrmbound Mantle",
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
                value = 286,
            },
            {
                sourceStatRef = "f82db71a:75y3a8ib",
                value = 9,
            },
            {
                sourceStatRef = "f82db71a:ygjno50i",
                value = 8,
            },
            {
                sourceStatRef = "f82db71a:v2g0tw0o",
                value = 1,
            },
            {
                sourceStatRef = "f82db71a:7t7xgzcx",
                value = 22,
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

## Wyrmbound Girdle

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "items",
    datasetId = "evokdata",
    entry = {
        allowWowConversion = false,
        armorWeight = "mail",
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
                    "f82db71a:evoker01",
                },
                invert = false,
                showOnTooltip = true,
                tooltipTextOverride = "Classes: Evoker",
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
        icon = "interface/icons/inv_belt_16.blp",
        id = "ev05cbelt",
        isTwoHanded = false,
        itemLevel = 60,
        itemSetKey = "t05_evoker_wyrmbound",
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
        name = "Wyrmbound Girdle",
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
                value = 214,
            },
            {
                sourceStatRef = "f82db71a:75y3a8ib",
                value = 11,
            },
            {
                sourceStatRef = "f82db71a:ygjno50i",
                value = 10,
            },
            {
                sourceStatRef = "f82db71a:v2g0tw0o",
                value = 1,
            },
            {
                sourceStatRef = "f82db71a:7t7xgzcx",
                value = 18,
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

## Wyrmbound Bracers

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "items",
    datasetId = "evokdata",
    entry = {
        allowWowConversion = false,
        armorWeight = "mail",
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
                    "f82db71a:evoker01",
                },
                invert = false,
                showOnTooltip = true,
                tooltipTextOverride = "Classes: Evoker",
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
        icon = "interface/icons/inv_bracer_02.blp",
        id = "ev05cwris",
        isTwoHanded = false,
        itemLevel = 60,
        itemSetKey = "t05_evoker_wyrmbound",
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
        name = "Wyrmbound Bracers",
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
                value = 167,
            },
            {
                sourceStatRef = "f82db71a:75y3a8ib",
                value = 8,
            },
            {
                sourceStatRef = "f82db71a:ygjno50i",
                value = 8,
            },
            {
                sourceStatRef = "f82db71a:v2g0tw0o",
                value = 1,
            },
            {
                sourceStatRef = "f82db71a:7t7xgzcx",
                value = 13,
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

