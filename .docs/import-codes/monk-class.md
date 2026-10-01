# Monk Class Import Code

Standalone `RPE_DATASET_ENTRY_V1` import code for the synthetic Classic-style Monk class chassis.

## Chassis

- Archetype: Druid-derived hybrid
- Primary stats: Druid progression
- Base Health: Druid progression
- Base Mana: Druid progression
- Core resource refs relevant to Monk setup:
  - Energy: `f82db71a:c3gaf7dd`
  - Chi: `f82db71a:p8kik0ep`

Armor, weapon proficiencies, passive traits, talents, and spells are intentionally left unassigned.

- Spell import codes: `.docs/import-codes/monk-spells.md`
- Trait import codes: `.docs/import-codes/monk-traits.md`
- Tier 2 import codes: `.docs/import-codes/monk-tier-2-sod/README.md`

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
        icon = "interface/icons/classicon_monk.blp",
        id = "monk0001",
        name = "Monk",
        passiveTraitRefs = {  },
        resourceProgressions = {
            {
                initialValue = 33,
                perLevelValue = 24.58,
                resourceRef = "f82db71a:q2ktkztt",
            },
            {
                initialValue = 17,
                perLevelValue = 20.8,
                resourceRef = "f82db71a:4c8mfm99",
            },
        },
        skillBonuses = {  },
        statProgressions = {
            {
                initialValue = 1,
                perLevelValue = 0.75,
                statRef = "f82db71a:zfqm8dxp",
            },
            {
                initialValue = 0,
                perLevelValue = 0.68,
                statRef = "f82db71a:xqz0daz2",
            },
            {
                initialValue = 0,
                perLevelValue = 0.85,
                statRef = "f82db71a:ygjno50i",
            },
            {
                initialValue = 2,
                perLevelValue = 1.32,
                statRef = "f82db71a:75y3a8ib",
            },
            {
                initialValue = 2,
                perLevelValue = 1.49,
                statRef = "f82db71a:kec9rhli",
            },
        },
        talentTraitRefs = {  },
        weaponTypeRefs = {  },
    },
}
```
