# Cataclysm Race Trait Import Codes

Standalone `RPE_DATASET_ENTRY_V1` import codes for Worgen and Goblin racial passives in the Core dataset.

## Authoring rules applied

- Only passive racial mechanics that RPE currently supports cleanly are authored.
- All crafting skill bonuses use +15; all non-combat skill bonuses use +5.
- Racial resistance bonuses are standardized at +15 for one school or +8/+8 when split across two schools.
- Active racial abilities are omitted.
- Worgen **Viciousness** grants +1 Melee Crit. Chance, +1 Ranged Crit. Chance, and +1 Spell Crit. Chance.
- Worgen **Aberration** is represented as +8 Nature Resistance and +8 Shadow Resistance.
- Worgen **Flayer** is omitted because Core does not currently define a Skinning skill.
- Goblin **Better Living Through Chemistry** grants +15 Alchemy, matching its Cataclysm-era profession bonus.
- Goblin **Time is Money** is omitted because Core does not currently expose attack-speed, cast-speed, or haste stats.
- Goblin vendor and active racials are omitted.

Import the Traits before the corresponding Race entries:

- `.docs/import-codes/worgen-race.md`
- `.docs/import-codes/goblin-race.md`

## Worgen

### Viciousness

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "traits",
    datasetId = "f82db71a",
    entry = {
        automaticAuras = {  },
        category = "",
        conditions = {  },
        description = "",
        events = {  },
        icon = "interface/icons/ability_worgen_viciousness.blp",
        id = "worgcrit",
        isEnvironmental = false,
        mutuallyExclusiveTraitRefs = {  },
        name = "Viciousness",
        skillBonuses = {  },
        statBonuses = {
            {
                operation = "flat",
                statRef = "f82db71a:jslmczbi",
                value = 1,
            },
            {
                operation = "flat",
                statRef = "f82db71a:fercjhm5",
                value = 1,
            },
            {
                operation = "flat",
                statRef = "f82db71a:69hfqhne",
                value = 1,
            },
        },
        unlockLevel = 1,
    },
}
```

### Aberration

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "traits",
    datasetId = "f82db71a",
    entry = {
        automaticAuras = {  },
        category = "",
        conditions = {  },
        description = "",
        events = {  },
        icon = "interface/icons/ability_racial_cannibalize.blp",
        id = "worgaber",
        isEnvironmental = false,
        mutuallyExclusiveTraitRefs = {  },
        name = "Aberration",
        skillBonuses = {  },
        statBonuses = {
            {
                operation = "flat",
                statRef = "f82db71a:pg0ytacb",
                value = 8,
            },
            {
                operation = "flat",
                statRef = "f82db71a:itpo751d",
                value = 8,
            },
        },
        unlockLevel = 1,
    },
}
```

## Goblin

### Better Living Through Chemistry

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "traits",
    datasetId = "f82db71a",
    entry = {
        automaticAuras = {  },
        category = "",
        conditions = {  },
        description = "",
        events = {  },
        icon = "interface/icons/trade_alchemy.blp",
        id = "gobalch15",
        isEnvironmental = false,
        mutuallyExclusiveTraitRefs = {  },
        name = "Better Living Through Chemistry",
        skillBonuses = {
            {
                skillRef = "f82db71a:pdyzyudy",
                value = 15,
            },
        },
        statBonuses = {  },
        unlockLevel = 1,
    },
}
```
