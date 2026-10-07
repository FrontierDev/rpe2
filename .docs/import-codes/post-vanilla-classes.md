# Post-Vanilla Class Import Codes

Standalone `RPE_DATASET_ENTRY_V1` import codes for the four synthetic Classic-style RPE class chassis:

- Death Knight — Warrior-derived
- Monk — Druid-derived
- Demon Hunter — Rogue-derived
- Evoker — Mage-derived

These entries implement the stat and base-resource mappings defined in:

- `.docs/RPE2_WoW_Classic_Base_Stats_Reference.md`
- `.docs/RPE2_Class_Stat_Authoring_Specification.md`

## Authoring notes

- These are **RPE synthetic Classic-style classes**, not historical Vanilla / Classic data.
- The entries intentionally contain no passive traits or talent traits.
- Armor and weapon proficiencies are intentionally left empty; they were not defined by the stat-mapping design and should be authored separately.
- Class-specific combat resources such as Runic Power, Energy, Chi, Fury, etc. are not part of these base-resource progressions.
- The `datasetId` in the payload is provenance only for entry exports; the Data Editor imports the entry into the currently selected target dataset.
- All stat and resource references use the Core dataset `f82db71a`.

---

# Death Knight

Warrior-derived: Strength melee/tank chassis, Warrior Health progression, no base Mana progression.

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

---

# Monk

Druid-derived: hybrid Agility DPS/tank/healer chassis, with Druid Health and Mana progression.

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

---

# Demon Hunter

Rogue-derived: Agility-heavy melee DPS/tank chassis, Rogue Health progression, no base Mana progression.

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

---

# Evoker

Mage-derived: Intellect caster chassis with Mage Health and Mana progression.

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
