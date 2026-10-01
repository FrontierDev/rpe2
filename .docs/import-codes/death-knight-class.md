# Death Knight Class Import Code

Standalone `RPE_DATASET_ENTRY_V1` import code for the synthetic Classic-style Death Knight class chassis.

## Chassis

- Archetype: Warrior-derived
- Primary stats: Warrior progression
- Base Health: Warrior progression
- Base Mana: none
- Core resource refs relevant to Death Knight setup:
  - Runes: `f82db71a:runes001`
  - Runic Power: `f82db71a:jolh6o6e`

Armor, weapon proficiencies, passive traits, talents, and spells are intentionally left unassigned.

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "classes",
    datasetId = "f82db71a",
    entry = {
        armorWeights = {  },
        description = "",
        icon = "interface/icons/classicon_deathknight.blp",
        id = "dkclass1",
        name = "Death Knight",
        passiveTraitRefs = {  },
        resourceProgressions = {
            {
                initialValue = 20,
                perLevelValue = 28.29,
                resourceRef = "f82db71a:q2ktkztt",
            },
        },
        skillBonuses = {  },
        statProgressions = {
            {
                initialValue = 3,
                perLevelValue = 1.64,
                statRef = "f82db71a:zfqm8dxp",
            },
            {
                initialValue = 0,
                perLevelValue = 1.02,
                statRef = "f82db71a:xqz0daz2",
            },
            {
                initialValue = 2,
                perLevelValue = 1.49,
                statRef = "f82db71a:ygjno50i",
            },
            {
                initialValue = 0,
                perLevelValue = 0.17,
                statRef = "f82db71a:75y3a8ib",
            },
            {
                initialValue = 0,
                perLevelValue = 0.42,
                statRef = "f82db71a:kec9rhli",
            },
        },
        talentTraitRefs = {  },
        weaponTypeRefs = {  },
    },
}
```
