# Druid Trait Import Codes

Standalone `RPE_DATASET_ENTRY_V1` import codes for Druid class passives and class talents in dataset `6e4d2a91`.

## Authoring notes

- **Force of Nature** is a class passive. After importing it, add `6e4d2a91:drfornat` to the Druid class's `passiveTraitRefs`.
- **Cat Form**, **Bear Form**, **Moonkin Form**, and **Tree of Life Form** are class talents. Add their refs to the Druid class's `talentTraitRefs`.
- The four forms are mutually exclusive through `mutuallyExclusiveTraitRefs`, preventing their stat packages from stacking.
- Trait `description` fields are intentionally empty. The trait tooltip generator must derive the displayed description from `statBonuses`.
- Percentage-point stats such as Melee Crit. Chance, Spell Crit. Chance, Threat Generated, Healing Done, and Damage vs. Mechanical use `operation = "flat"`.
- Multiplicative increases to Melee Attack Power, Armor, Stamina, and Spirit use `operation = "percent"`.

## Class Passive

### Force of Nature

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "traits",
    datasetId = "6e4d2a91",
    entry = {
        automaticAuras = {  },
        category = "Class Passive",
        conditions = {  },
        description = "",
        events = {  },
        icon = "interface/icons/ability_druid_forceofnature.blp",
        id = "drfornat",
        isEnvironmental = false,
        mutuallyExclusiveTraitRefs = {  },
        name = "Force of Nature",
        skillBonuses = {  },
        statBonuses = {
            {
                operation = "flat",
                statRef = "f82db71a:k66l7jr4",
                value = 5,
            },
        },
        unlockLevel = 1,
    },
}
```

## Feral

### Cat Form

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "traits",
    datasetId = "6e4d2a91",
    entry = {
        automaticAuras = {  },
        category = "Feral",
        conditions = {  },
        description = "",
        events = {  },
        icon = "interface/icons/ability_druid_catform.blp",
        id = "drcatfrm",
        isEnvironmental = false,
        mutuallyExclusiveTraitRefs = {
            "6e4d2a91:drbearfm",
            "6e4d2a91:drmoonkn",
            "6e4d2a91:drtreelf",
        },
        name = "Cat Form",
        skillBonuses = {  },
        statBonuses = {
            {
                operation = "percent",
                statRef = "f82db71a:u7b49vs9",
                value = 10,
            },
            {
                operation = "flat",
                statRef = "f82db71a:jslmczbi",
                value = 3,
            },
        },
        unlockLevel = 1,
    },
}
```

### Bear Form

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "traits",
    datasetId = "6e4d2a91",
    entry = {
        automaticAuras = {  },
        category = "Feral",
        conditions = {  },
        description = "",
        events = {  },
        icon = "interface/icons/ability_racial_bearform.blp",
        id = "drbearfm",
        isEnvironmental = false,
        mutuallyExclusiveTraitRefs = {
            "6e4d2a91:drcatfrm",
            "6e4d2a91:drmoonkn",
            "6e4d2a91:drtreelf",
        },
        name = "Bear Form",
        skillBonuses = {  },
        statBonuses = {
            {
                operation = "percent",
                statRef = "f82db71a:u7b49vs9",
                value = 5,
            },
            {
                operation = "percent",
                statRef = "f82db71a:v42albuv",
                value = 180,
            },
            {
                operation = "percent",
                statRef = "f82db71a:ygjno50i",
                value = 20,
            },
            {
                operation = "flat",
                statRef = "f82db71a:j8n012e6",
                value = 80,
            },
        },
        unlockLevel = 1,
    },
}
```

## Balance

### Moonkin Form

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "traits",
    datasetId = "6e4d2a91",
    entry = {
        automaticAuras = {  },
        category = "Balance",
        conditions = {  },
        description = "",
        events = {  },
        icon = "interface/icons/spell_nature_forceofnature.blp",
        id = "drmoonkn",
        isEnvironmental = false,
        mutuallyExclusiveTraitRefs = {
            "6e4d2a91:drcatfrm",
            "6e4d2a91:drbearfm",
            "6e4d2a91:drtreelf",
        },
        name = "Moonkin Form",
        skillBonuses = {  },
        statBonuses = {
            {
                operation = "percent",
                statRef = "f82db71a:v42albuv",
                value = 360,
            },
            {
                operation = "flat",
                statRef = "f82db71a:69hfqhne",
                value = 3,
            },
            {
                operation = "flat",
                statRef = "f82db71a:j8n012e6",
                value = -10,
            },
        },
        unlockLevel = 1,
    },
}
```

## Restoration

### Tree of Life Form

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "traits",
    datasetId = "6e4d2a91",
    entry = {
        automaticAuras = {  },
        category = "Restoration",
        conditions = {  },
        description = "",
        events = {  },
        icon = "interface/icons/ability_druid_treeoflife.blp",
        id = "drtreelf",
        isEnvironmental = false,
        mutuallyExclusiveTraitRefs = {
            "6e4d2a91:drcatfrm",
            "6e4d2a91:drbearfm",
            "6e4d2a91:drmoonkn",
        },
        name = "Tree of Life Form",
        skillBonuses = {  },
        statBonuses = {
            {
                operation = "flat",
                statRef = "f82db71a:5pxmfw02",
                value = 10,
            },
            {
                operation = "flat",
                statRef = "f82db71a:j8n012e6",
                value = -10,
            },
            {
                operation = "percent",
                statRef = "f82db71a:kec9rhli",
                value = 25,
            },
            {
                operation = "percent",
                statRef = "f82db71a:v42albuv",
                value = 200,
            },
        },
        unlockLevel = 1,
    },
}
```
