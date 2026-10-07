# Wyrmbound Raiment — Preservation

Invented RPE Tier 0.5 Preservation Evoker set using the existing Shaman The Five Thunders Restoration mail-healer armor, primary-stat, quality, Healing Power, Spell Crit, and Resource Regeneration budget slot-for-slot.

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
        id = "ev05pchst",
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
                value = 18,
            },
            {
                sourceStatRef = "f82db71a:ygjno50i",
                value = 17,
            },
            {
                sourceStatRef = "f82db71a:hj6d4kvy",
                value = 55,
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
        id = "ev05pboot",
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
                value = 18,
            },
            {
                sourceStatRef = "f82db71a:ygjno50i",
                value = 11,
            },
            {
                sourceStatRef = "f82db71a:hj6d4kvy",
                value = 35,
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
        id = "ev05pglov",
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
                value = 11,
            },
            {
                sourceStatRef = "f82db71a:hj6d4kvy",
                value = 42,
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
        id = "ev05phelm",
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
                value = 21,
            },
            {
                sourceStatRef = "f82db71a:ygjno50i",
                value = 22,
            },
            {
                sourceStatRef = "f82db71a:69hfqhne",
                value = 1,
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
        id = "ev05plegs",
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
                value = 16,
            },
            {
                sourceStatRef = "f82db71a:ygjno50i",
                value = 15,
            },
            {
                sourceStatRef = "f82db71a:hj6d4kvy",
                value = 44,
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
        id = "ev05pspau",
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
                value = 14,
            },
            {
                sourceStatRef = "f82db71a:ygjno50i",
                value = 13,
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
        id = "ev05pbelt",
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
                sourceStatRef = "f82db71a:hj6d4kvy",
                value = 31,
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
        id = "ev05pwris",
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
                value = 10,
            },
            {
                sourceStatRef = "f82db71a:ygjno50i",
                value = 10,
            },
            {
                sourceStatRef = "f82db71a:hj6d4kvy",
                value = 29,
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

