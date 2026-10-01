# Sayaad Unit Import Code

Standalone `RPE_DATASET_ENTRY_V1` import code for a base Sayaad (Succubus) unit in the Core dataset (`f82db71a`).

## Level-60 calibration

| Stat | Initial | Per level | Level 60 |
|---|---:|---:|---:|
| Health | 150 | 34.745763 | 2,200 |
| Mana | 120 | 28.474576 | 1,800 |
| Armor | 50 | 24.576271 | 1,500 |
| Melee Attack Power | 50 | 5.932203 | 400 |
| Ranged Attack Power | 0 | 0 | 0 |
| Spell Power | 30 | 3.728814 | 250 |
| Healing Power | 0 | 0 | 0 |
| Melee Hit Chance | 0 | 0 | 0 |
| Ranged Hit Chance | 0 | 0 | 0 |
| Spell Hit Chance | 0 | 0 | 0 |
| Melee Crit Chance | 5 | 0 | 5 |
| Ranged Crit Chance | 0 | 0 | 0 |
| Spell Crit Chance | 5 | 0 | 5 |
| Parry Chance | 0 | 0 | 0 |
| Dodge Chance | 5 | 0 | 5 |
| Block Chance | 0 | 0 | 0 |
| Magic Resistance | 0 | 0 | 0 |
| Fire Resistance | 1.333333 | 1.333333 | 80 |
| Frost Resistance | 1.333333 | 1.333333 | 80 |
| Nature Resistance | 1.333333 | 1.333333 | 80 |
| Arcane Resistance | 1.333333 | 1.333333 | 80 |
| Shadow Resistance | 1.333333 | 1.333333 | 80 |
| Holy Resistance | 0 | 0 | 0 |
| Resource Regeneration | 0 | 0 | 0 |
| Movement Speed | 30 | 0 | 30 |

Under the current Core `level_scaled_percent` mitigation model, a school-resistance rating of approximately `1.333333 × level` corresponds to approximately **20% damage mitigation**. Fire, Frost, Nature, Arcane and Shadow Resistance therefore remain at approximately 20% from level 1 through level 60.

Holy Resistance is left at 0 because Holy currently uses direct mitigation rather than the percentage-reference model.

## Base appearances

The base Sayaad uses two Succubus appearances:

- DisplayID `77396` — modern Succubus display used by NPC 1863 in post-Legion data.
- DisplayID `159` — classic `succubus2.m2` magenta appearance.

No FileDataID is authored because a current FileDataID for these display records has not been verified. DisplayID-only appearances are valid in the Unit appearance schema.

## Presets

All three presets inherit the base Sayaad challenge level, stats, resources and appearances. Their spell lists are explicit replacements.

### Temptress

Crowd-control focused.

Spells:

- Whiplash — `e8f3b2c6:wlwhipl1`
- Charm — `e8f3b2c6:wlcharm1`

### Seductress

Sustained Shadow-pressure/debuff variant.

Spells:

- Whiplash — `e8f3b2c6:wlwhipl1`
- Corruption — `e8f3b2c6:wlcorru1`
- Curse of Shadows — `e8f3b2c6:wlcshads`

### Tormentor

Aggressive melee/control variant.

Spells:

- Whiplash — `e8f3b2c6:wlwhipl1`
- Fear — `e8f3b2c6:wlfear01`

## Authoring notes

- Creature type: `demon`
- Creature size: `medium`
- Base challenge level: `normal`
- The Sayaad is an agile melee/spell hybrid with less durability than Felguard or Voidwalker.
- It has sufficient Melee Attack Power for physical pet attacks and sufficient Spell Power for Shadow/control-oriented abilities.
- The base unit intentionally has no spells; the presets provide explicit NPC spell loadouts while Warlock Pet definitions provide player-pet abilities.
- Damage Done and Damage Reduction are not seeded on the base unit.
- Fire, Frost, Nature, Arcane and Shadow Resistance use level-scaled stat rows rather than fixed values.
- The base appearance list is intentionally limited to Succubus forms. Incubus/Shivarra appearances can be added separately if required.

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "units",
    datasetId = "f82db71a",
    entry = {
        appearances = {
            {
                displayId = 77396,
            },
            {
                displayId = 159,
            },
        },
        attributes = {  },
        challengeLevel = "normal",
        creatureSize = "medium",
        creatureType = "demon",
        id = "sayaad01",
        name = "Sayaad",
        presets = {
            {
                name = "Temptress",
                resourceModifiers = {  },
                statModifiers = {  },
                spells = {
                    "e8f3b2c6:wlwhipl1",
                    "e8f3b2c6:wlcharm1",
                },
                equipment = {  },
            },
            {
                name = "Seductress",
                resourceModifiers = {  },
                statModifiers = {  },
                spells = {
                    "e8f3b2c6:wlwhipl1",
                    "e8f3b2c6:wlcorru1",
                    "e8f3b2c6:wlcshads",
                },
                equipment = {  },
            },
            {
                name = "Tormentor",
                resourceModifiers = {  },
                statModifiers = {  },
                spells = {
                    "e8f3b2c6:wlwhipl1",
                    "e8f3b2c6:wlfear01",
                },
                equipment = {  },
            },
        },
        resistances = {  },
        resources = {
            {
                initialValue = 150,
                perLevelValue = 34.745763,
                resourceRef = "f82db71a:q2ktkztt",
            },
            {
                initialValue = 120,
                perLevelValue = 28.474576,
                resourceRef = "f82db71a:4c8mfm99",
            },
        },
        spells = {  },
        stats = {
            {
                initialValue = 50,
                perLevelValue = 24.576271,
                statRef = "f82db71a:v42albuv",
            },
            {
                initialValue = 0,
                perLevelValue = 0,
                statRef = "f82db71a:wbj4zuf3",
            },
            {
                initialValue = 0,
                perLevelValue = 0,
                statRef = "f82db71a:dd88li4c",
            },
            {
                initialValue = 0,
                perLevelValue = 0,
                statRef = "f82db71a:v2g0tw0o",
            },
            {
                initialValue = 0,
                perLevelValue = 0,
                statRef = "f82db71a:tcn0s8kx",
            },
            {
                initialValue = 5,
                perLevelValue = 0,
                statRef = "f82db71a:o6113cir",
            },
            {
                initialValue = 0,
                perLevelValue = 0,
                statRef = "f82db71a:p8syz5ba",
            },
            {
                initialValue = 0,
                perLevelValue = 0,
                statRef = "f82db71a:zs1nbz13",
            },
            {
                initialValue = 50,
                perLevelValue = 5.932203,
                statRef = "f82db71a:u7b49vs9",
            },
            {
                initialValue = 0,
                perLevelValue = 0,
                statRef = "f82db71a:v2rs9cpy",
            },
            {
                initialValue = 30,
                perLevelValue = 3.728814,
                statRef = "f82db71a:7t7xgzcx",
            },
            {
                initialValue = 5,
                perLevelValue = 0,
                statRef = "f82db71a:jslmczbi",
            },
            {
                initialValue = 0,
                perLevelValue = 0,
                statRef = "f82db71a:fercjhm5",
            },
            {
                initialValue = 5,
                perLevelValue = 0,
                statRef = "f82db71a:69hfqhne",
            },
            {
                initialValue = 1.333333,
                perLevelValue = 1.333333,
                statRef = "f82db71a:0w7c7p09",
            },
            {
                initialValue = 0,
                perLevelValue = 0,
                statRef = "f82db71a:hj6d4kvy",
            },
            {
                initialValue = 1.333333,
                perLevelValue = 1.333333,
                statRef = "f82db71a:jjn0my8k",
            },
            {
                initialValue = 1.333333,
                perLevelValue = 1.333333,
                statRef = "f82db71a:pg0ytacb",
            },
            {
                initialValue = 1.333333,
                perLevelValue = 1.333333,
                statRef = "f82db71a:954yunb9",
            },
            {
                initialValue = 1.333333,
                perLevelValue = 1.333333,
                statRef = "f82db71a:itpo751d",
            },
            {
                initialValue = 0,
                perLevelValue = 0,
                statRef = "f82db71a:hlyrsstn",
            },
            {
                initialValue = 0,
                perLevelValue = 0,
                statRef = "f82db71a:rgnrtg01",
            },
            {
                initialValue = 30,
                perLevelValue = 0,
                statRef = "f82db71a:s1mt6jh9",
            },
        },
        tags = {  },
    },
}
```
