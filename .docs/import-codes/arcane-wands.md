# Arcane Wand Import Codes

Standalone `RPE_DATASET_ENTRY_V1` **item** import codes for RPEngine2's `dev` branch.

The level-1 starter wand belongs to the Core dataset (`f82db71a`); the four Classic Enchanting wands belong to the Enchanting dataset (`732368d4`). Import each block individually into its indicated dataset through the Data Editor.

| Wand | Equip level | Item level | Arcane damage / turn | Classic Enchanting skill |
| --- | ---: | ---: | ---: | ---: |
| Worn Arcane Wand | 1 | 1 | 1–3 | — |
| Lesser Magic Wand | 5 | 15 | 12–22 | 10 |
| Greater Magic Wand | 13 | 23 | 22–41 | 70 |
| Lesser Mystic Wand | 26 | 31 | 23–43 | 155 |
| Greater Mystic Wand | 30 | 35 | 40–76 | 175 |

## Implementation notes

- The **Worn Arcane Wand** is a new item; it does not modify the existing Physical-damage `Worn Wand` (`f82db71a:stwwnd01`). Its 1–3 Arcane damage matches the Worn Wand's starter damage range.
- All five are RPE **weapons**, using Core's Wand weapon type (`f82db71a:s4q9t5f3`), Ranged slot (`f82db71a:q8ve6n6t`) and Arcane school (`f82db71a:dtxhglqg`).
- The Classic wands preserve the **Classic Era item levels, required character levels and Arcane tooltip damage ranges**. RPE's `minDamagePerTurn`/`maxDamagePerTurn` are per-turn damage values rather than WoW weapon speed/DPS. Therefore this is a direct damage-range port, **not** a speed-normalized RPE balance pass.
- Enchanting skill values below describe the Classic crafting profession levels; they are **not equip requirements**. Item codes alone do **not** teach recipes or enable crafting. The repository's Enchanting dataset currently uses generic Magic/Mystic Essence materials and does not contain Simple Wood or Star Wood, so implementing genuine Classic reagent-based recipes requires separate material and recipe entries.
- Crafted Enchanting wands are Bind on Equip and cannot be disenchanted. They intentionally have no later-expansion Intellect/Stamina/Spell Power bonuses.
- Classic Enchanting has **four wand formulas** through profession skill 300. The last unlocks at **175**; none unlock at 200–300.

References: [Classic Enchanting formulas](https://www.wowhead.com/classic/guide/enchanting-leveling-1-300-wow-classic), [Lesser Magic Wand](https://www.wowhead.com/classic/item=11287), [Greater Magic Wand](https://www.wowhead.com/classic/item=11288), [Lesser Mystic Wand](https://www.wowhead.com/classic/item=11289), [Greater Mystic Wand](https://www.wowhead.com/classic/item=11290).

## Worn Arcane Wand

Core starter item, usable at character level 1.

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "items",
    datasetId = "f82db71a",
    entry = {
        allowWowConversion = false,
        armorWeight = "cosmetic",
        bindingFlag = "none",
        blueSockets = 0,
        canDisenchant = false,
        canSell = true,
        canStack = false,
        canTrade = true,
        cogSockets = 0,
        conditions = {
            {
                invert = false,
                minimumValue = 1,
                showOnTooltip = true,
                tooltipTextOverride = "",
                type = "level",
            },
        },
        consumableElixirType = "",
        consumableType = "",
        damageMode = "range",
        damagePerTurn = 0,
        damageSchoolRef = "f82db71a:dtxhglqg",
        description = "",
        gemColor = "none",
        genericModificationKey = "",
        greenSockets = 0,
        icon = "interface/icons/inv_wand_01.blp",
        id = "wrnarca1",
        isTwoHanded = false,
        itemLevel = 1,
        itemSetKey = "",
        itemType = "weapon",
        maxDamagePerTurn = 3,
        maxGenericModificationCounts = { mod = 1 },
        maxModificationCounts = { mod = 1 },
        maxStackSize = 1,
        metaSockets = 0,
        minDamagePerTurn = 1,
        modificationKind = "generic",
        name = "Worn Arcane Wand",
        prismaticSockets = 0,
        quality = "poor",
        redSockets = 0,
        sellPrice = 0,
        skillBonuses = {  },
        socketTypes = {  },
        sockets = {  },
        stats = {  },
        tags = { "starter" },
        targetArmorWeight = "none",
        targetSlotRefs = {  },
        uniqueFlag = "none",
        validSlotRefs = {
            "f82db71a:q8ve6n6t",
        },
        weaponTypeRef = "f82db71a:s4q9t5f3",
        yellowSockets = 0,
    },
}
```

## Lesser Magic Wand

Classic Enchanting skill **10**; usable at character level **5**.

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "items",
    datasetId = "732368d4",
    entry = {
        allowWowConversion = false,
        armorWeight = "cosmetic",
        bindingFlag = "bind_on_equip",
        blueSockets = 0,
        canDisenchant = false,
        canSell = true,
        canStack = false,
        canTrade = true,
        cogSockets = 0,
        conditions = {
            {
                invert = false,
                minimumValue = 5,
                showOnTooltip = true,
                tooltipTextOverride = "",
                type = "level",
            },
        },
        consumableElixirType = "",
        consumableType = "",
        damageMode = "range",
        damagePerTurn = 0,
        damageSchoolRef = "f82db71a:dtxhglqg",
        description = "",
        gemColor = "none",
        genericModificationKey = "",
        greenSockets = 0,
        icon = "interface/icons/inv_staff_02.blp",
        id = "enlmag01",
        isTwoHanded = false,
        itemLevel = 15,
        itemSetKey = "",
        itemType = "weapon",
        maxDamagePerTurn = 22,
        maxGenericModificationCounts = { mod = 1 },
        maxModificationCounts = { mod = 1 },
        maxStackSize = 1,
        metaSockets = 0,
        minDamagePerTurn = 12,
        modificationKind = "generic",
        name = "Lesser Magic Wand",
        prismaticSockets = 0,
        quality = "uncommon",
        redSockets = 0,
        sellPrice = 0,
        skillBonuses = {  },
        socketTypes = {  },
        sockets = {  },
        stats = {  },
        tags = {  },
        targetArmorWeight = "none",
        targetSlotRefs = {  },
        uniqueFlag = "none",
        validSlotRefs = {
            "f82db71a:q8ve6n6t",
        },
        weaponTypeRef = "f82db71a:s4q9t5f3",
        yellowSockets = 0,
    },
}
```

## Greater Magic Wand

Classic Enchanting skill **70**; usable at character level **13**.

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "items",
    datasetId = "732368d4",
    entry = {
        allowWowConversion = false,
        armorWeight = "cosmetic",
        bindingFlag = "bind_on_equip",
        blueSockets = 0,
        canDisenchant = false,
        canSell = true,
        canStack = false,
        canTrade = true,
        cogSockets = 0,
        conditions = {
            {
                invert = false,
                minimumValue = 13,
                showOnTooltip = true,
                tooltipTextOverride = "",
                type = "level",
            },
        },
        consumableElixirType = "",
        consumableType = "",
        damageMode = "range",
        damagePerTurn = 0,
        damageSchoolRef = "f82db71a:dtxhglqg",
        description = "",
        gemColor = "none",
        genericModificationKey = "",
        greenSockets = 0,
        icon = "interface/icons/inv_staff_07.blp",
        id = "engmag01",
        isTwoHanded = false,
        itemLevel = 23,
        itemSetKey = "",
        itemType = "weapon",
        maxDamagePerTurn = 41,
        maxGenericModificationCounts = { mod = 1 },
        maxModificationCounts = { mod = 1 },
        maxStackSize = 1,
        metaSockets = 0,
        minDamagePerTurn = 22,
        modificationKind = "generic",
        name = "Greater Magic Wand",
        prismaticSockets = 0,
        quality = "uncommon",
        redSockets = 0,
        sellPrice = 0,
        skillBonuses = {  },
        socketTypes = {  },
        sockets = {  },
        stats = {  },
        tags = {  },
        targetArmorWeight = "none",
        targetSlotRefs = {  },
        uniqueFlag = "none",
        validSlotRefs = {
            "f82db71a:q8ve6n6t",
        },
        weaponTypeRef = "f82db71a:s4q9t5f3",
        yellowSockets = 0,
    },
}
```

## Lesser Mystic Wand

Classic Enchanting skill **155**; usable at character level **26**.

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "items",
    datasetId = "732368d4",
    entry = {
        allowWowConversion = false,
        armorWeight = "cosmetic",
        bindingFlag = "bind_on_equip",
        blueSockets = 0,
        canDisenchant = false,
        canSell = true,
        canStack = false,
        canTrade = true,
        cogSockets = 0,
        conditions = {
            {
                invert = false,
                minimumValue = 26,
                showOnTooltip = true,
                tooltipTextOverride = "",
                type = "level",
            },
        },
        consumableElixirType = "",
        consumableType = "",
        damageMode = "range",
        damagePerTurn = 0,
        damageSchoolRef = "f82db71a:dtxhglqg",
        description = "",
        gemColor = "none",
        genericModificationKey = "",
        greenSockets = 0,
        icon = "interface/icons/inv_wand_06.blp",
        id = "enlmys01",
        isTwoHanded = false,
        itemLevel = 31,
        itemSetKey = "",
        itemType = "weapon",
        maxDamagePerTurn = 43,
        maxGenericModificationCounts = { mod = 1 },
        maxModificationCounts = { mod = 1 },
        maxStackSize = 1,
        metaSockets = 0,
        minDamagePerTurn = 23,
        modificationKind = "generic",
        name = "Lesser Mystic Wand",
        prismaticSockets = 0,
        quality = "uncommon",
        redSockets = 0,
        sellPrice = 0,
        skillBonuses = {  },
        socketTypes = {  },
        sockets = {  },
        stats = {  },
        tags = {  },
        targetArmorWeight = "none",
        targetSlotRefs = {  },
        uniqueFlag = "none",
        validSlotRefs = {
            "f82db71a:q8ve6n6t",
        },
        weaponTypeRef = "f82db71a:s4q9t5f3",
        yellowSockets = 0,
    },
}
```

## Greater Mystic Wand

Classic Enchanting skill **175**; usable at character level **30**.

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "items",
    datasetId = "732368d4",
    entry = {
        allowWowConversion = false,
        armorWeight = "cosmetic",
        bindingFlag = "bind_on_equip",
        blueSockets = 0,
        canDisenchant = false,
        canSell = true,
        canStack = false,
        canTrade = true,
        cogSockets = 0,
        conditions = {
            {
                invert = false,
                minimumValue = 30,
                showOnTooltip = true,
                tooltipTextOverride = "",
                type = "level",
            },
        },
        consumableElixirType = "",
        consumableType = "",
        damageMode = "range",
        damagePerTurn = 0,
        damageSchoolRef = "f82db71a:dtxhglqg",
        description = "",
        gemColor = "none",
        genericModificationKey = "",
        greenSockets = 0,
        icon = "interface/icons/inv_wand_07.blp",
        id = "engmys01",
        isTwoHanded = false,
        itemLevel = 35,
        itemSetKey = "",
        itemType = "weapon",
        maxDamagePerTurn = 76,
        maxGenericModificationCounts = { mod = 1 },
        maxModificationCounts = { mod = 1 },
        maxStackSize = 1,
        metaSockets = 0,
        minDamagePerTurn = 40,
        modificationKind = "generic",
        name = "Greater Mystic Wand",
        prismaticSockets = 0,
        quality = "uncommon",
        redSockets = 0,
        sellPrice = 0,
        skillBonuses = {  },
        socketTypes = {  },
        sockets = {  },
        stats = {  },
        tags = {  },
        targetArmorWeight = "none",
        targetSlotRefs = {  },
        uniqueFlag = "none",
        validSlotRefs = {
            "f82db71a:q8ve6n6t",
        },
        weaponTypeRef = "f82db71a:s4q9t5f3",
        yellowSockets = 0,
    },
}
```
