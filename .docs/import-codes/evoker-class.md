# Evoker Class Import Code

Standalone `RPE_DATASET_ENTRY_V1` import code for the synthetic Classic-style Evoker class chassis.

## Chassis

- Archetype: Mage-derived
- Primary stats: Mage progression
- Base Health: Mage progression
- Base Mana: Mage progression
- Core resource refs relevant to Evoker setup:
  - Mana: `f82db71a:4c8mfm99`
  - Essence: `f82db71a:essence1`

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
        icon = "interface/icons/classicon_evoker.blp",
        id = "evoker01",
        name = "Evoker",
        passiveTraitRefs = {  },
        resourceProgressions = {
            {
                initialValue = 31,
                perLevelValue = 22.53,
                resourceRef = "f82db71a:q2ktkztt",
            },
            {
                initialValue = 100,
                perLevelValue = 19.88,
                resourceRef = "f82db71a:4c8mfm99",
            },
        },
        skillBonuses = {  },
        statProgressions = {
            {
                initialValue = 0,
                perLevelValue = 0.17,
                statRef = "f82db71a:zfqm8dxp",
            },
            {
                initialValue = 0,
                perLevelValue = 0.25,
                statRef = "f82db71a:xqz0daz2",
            },
            {
                initialValue = 0,
                perLevelValue = 0.42,
                statRef = "f82db71a:ygjno50i",
            },
            {
                initialValue = 3,
                perLevelValue = 1.73,
                statRef = "f82db71a:75y3a8ib",
            },
            {
                initialValue = 2,
                perLevelValue = 1.66,
                statRef = "f82db71a:kec9rhli",
            },
        },
        talentTraitRefs = {  },
        weaponTypeRefs = {  },
    },
}
```
