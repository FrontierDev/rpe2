# Demon Hunter Class Import Code

Standalone `RPE_DATASET_ENTRY_V1` import code for the synthetic Classic-style Demon Hunter class chassis.

## Chassis

- Archetype: Rogue-derived
- Primary stats: Rogue progression
- Base Health: Rogue progression
- Base Mana: none
- Resource refs relevant to Demon Hunter setup:
  - Fury: `f82db71a:fury0001`
  - Soul Fragments: `dhunter1:dhsoul01` (special resource; import from the Demon Hunter spell sheet)

Armor, weapon proficiencies, passive traits, talents, and spells are intentionally left unassigned.

- Trait import codes: `.docs/import-codes/demon-hunter-traits.md`
- Tier 2 import codes: `.docs/import-codes/demon-hunter-tier-2-sod/README.md`\n- Spell and Soul Fragment import codes: `.docs/import-codes/demon-hunter-spells.md`

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
        icon = "interface/icons/classicon_demonhunter.blp",
        id = "dhclass1",
        name = "Demon Hunter",
        passiveTraitRefs = {  },
        resourceProgressions = {
            {
                initialValue = 25,
                perLevelValue = 25.39,
                resourceRef = "f82db71a:q2ktkztt",
            },
        },
        skillBonuses = {  },
        statProgressions = {
            {
                initialValue = 1,
                perLevelValue = 1,
                statRef = "f82db71a:zfqm8dxp",
            },
            {
                initialValue = 3,
                perLevelValue = 1.81,
                statRef = "f82db71a:xqz0daz2",
            },
            {
                initialValue = 1,
                perLevelValue = 0.92,
                statRef = "f82db71a:ygjno50i",
            },
            {
                initialValue = 0,
                perLevelValue = 0.25,
                statRef = "f82db71a:75y3a8ib",
            },
            {
                initialValue = 0,
                perLevelValue = 0.51,
                statRef = "f82db71a:kec9rhli",
            },
        },
        talentTraitRefs = {  },
        weaponTypeRefs = {  },
    },
}
```
