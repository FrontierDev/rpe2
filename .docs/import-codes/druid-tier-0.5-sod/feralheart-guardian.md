# Feralheart Raiment — Guardian / Feral Tank

Season of Discovery Druid Dungeon Set 2 / Tier 0.5 Guardian pieces.

Each block below is a standalone `RPE_DATASET_ENTRY_V1` import code for the Druid dataset (`6e4d2a91`).

All included pieces are normalized to RPE item level **60** while retaining their verified Season of Discovery Guardian Feralheart stats.

Guardian translation follows the existing RPE Druid tank convention:
- generic hit is mapped to **Melee Hit Chance**;
- source Defense is mapped to **Defense Rating**;
- source Dodge is mapped to **Dodge Chance**;
- the shared item-set key is `t05_druid_feralheart`.

This document currently contains the six Guardian pieces whose SoD stats were verified for import. Feralheart Faceguard and Feralheart Legguards are intentionally not included here until their SoD tooltip values are verified.

## Feralheart Armor

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "items",
    datasetId = "6e4d2a91",
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
                    "6e4d2a91:drdcls01",
                },
                invert = false,
                showOnTooltip = true,
                tooltipTextOverride = "Classes: Druid",
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
        icon = "interface/icons/inv_chest_plate06.blp",
        id = "d05tarmo",
        isTwoHanded = false,
        itemLevel = 60,
        itemSetKey = "t05_druid_feralheart",
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
        name = "Feralheart Armor",
        prismaticSockets = 0,
        quality = "epic",
        redSockets = 0,
        sellPrice = 0,
        skillBonuses = {  },
        socketTypes = {  },
        sockets = {  },
        stats = {
            {
                sourceStatRef = "f82db71a:v42albuv",
                value = 185,
            },
            {
                sourceStatRef = "f82db71a:xqz0daz2",
                value = 10,
            },
            {
                sourceStatRef = "f82db71a:ygjno50i",
                value = 30,
            },
            {
                sourceStatRef = "f82db71a:jslmczbi",
                value = 2,
            },
            {
                sourceStatRef = "f82db71a:0wyp78x9",
                value = 7,
            },
        },
        tags = {  },
        targetArmorWeight = "none",
        targetSlotRefs = {  },
        targetTwoHandedOnly = false,
        uniqueFlag = "none",
        validSlotRefs = {
            "f82db71a:nwfvxbto",
        },
        yellowSockets = 0,
    },
}
```

## Feralheart Treads

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "items",
    datasetId = "6e4d2a91",
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
                    "6e4d2a91:drdcls01",
                },
                invert = false,
                showOnTooltip = true,
                tooltipTextOverride = "Classes: Druid",
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
        id = "d05ttred",
        isTwoHanded = false,
        itemLevel = 60,
        itemSetKey = "t05_druid_feralheart",
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
        name = "Feralheart Treads",
        prismaticSockets = 0,
        quality = "epic",
        redSockets = 0,
        sellPrice = 0,
        skillBonuses = {  },
        socketTypes = {  },
        sockets = {  },
        stats = {
            {
                sourceStatRef = "f82db71a:v42albuv",
                value = 127,
            },
            {
                sourceStatRef = "f82db71a:xqz0daz2",
                value = 9,
            },
            {
                sourceStatRef = "f82db71a:ygjno50i",
                value = 22,
            },
            {
                sourceStatRef = "f82db71a:o6113cir",
                value = 1,
            },
            {
                sourceStatRef = "f82db71a:0wyp78x9",
                value = 9,
            },
        },
        tags = {  },
        targetArmorWeight = "none",
        targetSlotRefs = {  },
        targetTwoHandedOnly = false,
        uniqueFlag = "none",
        validSlotRefs = {
            "f82db71a:raiu9t05",
        },
        yellowSockets = 0,
    },
}
```

## Feralheart Grips

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "items",
    datasetId = "6e4d2a91",
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
                    "6e4d2a91:drdcls01",
                },
                invert = false,
                showOnTooltip = true,
                tooltipTextOverride = "Classes: Druid",
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
        icon = "interface/icons/inv_gauntlets_17.blp",
        id = "d05tgrip",
        isTwoHanded = false,
        itemLevel = 60,
        itemSetKey = "t05_druid_feralheart",
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
        name = "Feralheart Grips",
        prismaticSockets = 0,
        quality = "epic",
        redSockets = 0,
        sellPrice = 0,
        skillBonuses = {  },
        socketTypes = {  },
        sockets = {  },
        stats = {
            {
                sourceStatRef = "f82db71a:v42albuv",
                value = 108,
            },
            {
                sourceStatRef = "f82db71a:xqz0daz2",
                value = 14,
            },
            {
                sourceStatRef = "f82db71a:ygjno50i",
                value = 22,
            },
            {
                sourceStatRef = "f82db71a:0wyp78x9",
                value = 5,
            },
        },
        tags = {  },
        targetArmorWeight = "none",
        targetSlotRefs = {  },
        targetTwoHandedOnly = false,
        uniqueFlag = "none",
        validSlotRefs = {
            "f82db71a:wasvuom2",
        },
        yellowSockets = 0,
    },
}
```

## Feralheart Pauldrons

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "items",
    datasetId = "6e4d2a91",
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
                    "6e4d2a91:drdcls01",
                },
                invert = false,
                showOnTooltip = true,
                tooltipTextOverride = "Classes: Druid",
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
        icon = "interface/icons/inv_shoulder_01.blp",
        id = "d05tpaul",
        isTwoHanded = false,
        itemLevel = 60,
        itemSetKey = "t05_druid_feralheart",
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
        name = "Feralheart Pauldrons",
        prismaticSockets = 0,
        quality = "rare",
        redSockets = 0,
        sellPrice = 0,
        skillBonuses = {  },
        socketTypes = {  },
        sockets = {  },
        stats = {
            {
                sourceStatRef = "f82db71a:v42albuv",
                value = 136,
            },
            {
                sourceStatRef = "f82db71a:xqz0daz2",
                value = 8,
            },
            {
                sourceStatRef = "f82db71a:ygjno50i",
                value = 18,
            },
            {
                sourceStatRef = "f82db71a:jslmczbi",
                value = 1,
            },
            {
                sourceStatRef = "f82db71a:0wyp78x9",
                value = 7,
            },
        },
        tags = {  },
        targetArmorWeight = "none",
        targetSlotRefs = {  },
        targetTwoHandedOnly = false,
        uniqueFlag = "none",
        validSlotRefs = {
            "f82db71a:66i80qm1",
        },
        yellowSockets = 0,
    },
}
```

## Feralheart Waistguard

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "items",
    datasetId = "6e4d2a91",
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
                    "6e4d2a91:drdcls01",
                },
                invert = false,
                showOnTooltip = true,
                tooltipTextOverride = "Classes: Druid",
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
        icon = "interface/icons/inv_belt_15.blp",
        id = "d05twais",
        isTwoHanded = false,
        itemLevel = 60,
        itemSetKey = "t05_druid_feralheart",
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
        name = "Feralheart Waistguard",
        prismaticSockets = 0,
        quality = "rare",
        redSockets = 0,
        sellPrice = 0,
        skillBonuses = {  },
        socketTypes = {  },
        sockets = {  },
        stats = {
            {
                sourceStatRef = "f82db71a:v42albuv",
                value = 102,
            },
            {
                sourceStatRef = "f82db71a:xqz0daz2",
                value = 10,
            },
            {
                sourceStatRef = "f82db71a:ygjno50i",
                value = 19,
            },
            {
                sourceStatRef = "f82db71a:0wyp78x9",
                value = 9,
            },
        },
        tags = {  },
        targetArmorWeight = "none",
        targetSlotRefs = {  },
        targetTwoHandedOnly = false,
        uniqueFlag = "none",
        validSlotRefs = {
            "f82db71a:haks0gz4",
        },
        yellowSockets = 0,
    },
}
```

## Feralheart Wristguards

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "items",
    datasetId = "6e4d2a91",
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
                    "6e4d2a91:drdcls01",
                },
                invert = false,
                showOnTooltip = true,
                tooltipTextOverride = "Classes: Druid",
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
        icon = "interface/icons/inv_bracer_09.blp",
        id = "d05twris",
        isTwoHanded = false,
        itemLevel = 60,
        itemSetKey = "t05_druid_feralheart",
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
        name = "Feralheart Wristguards",
        prismaticSockets = 0,
        quality = "rare",
        redSockets = 0,
        sellPrice = 0,
        skillBonuses = {  },
        socketTypes = {  },
        sockets = {  },
        stats = {
            {
                sourceStatRef = "f82db71a:v42albuv",
                value = 129,
            },
            {
                sourceStatRef = "f82db71a:ygjno50i",
                value = 16,
            },
            {
                sourceStatRef = "f82db71a:0wyp78x9",
                value = 6,
            },
        },
        tags = {  },
        targetArmorWeight = "none",
        targetSlotRefs = {  },
        targetTwoHandedOnly = false,
        uniqueFlag = "none",
        validSlotRefs = {
            "f82db71a:crezt6ix",
        },
        yellowSockets = 0,
    },
}
```
