# Felhunter Unit Import Code

Standalone `RPE_DATASET_ENTRY_V1` import code for a base Felhunter unit in the Core dataset (`f82db71a`).

## Level-60 calibration

| Stat | Initial | Per level | Level 60 |
|---|---:|---:|---:|
| Health | 160 | 39.661017 | 2,500 |
| Mana | 120 | 33.559322 | 2,100 |
| Armor | 75 | 24.152542 | 1,500 |
| Melee Attack Power | 55 | 5.423729 | 375 |
| Ranged Attack Power | 0 | 0 | 0 |
| Spell Power | 25 | 2.542373 | 175 |
| Healing Power | 0 | 0 | 0 |
| Melee Hit Chance | 0 | 0 | 0 |
| Ranged Hit Chance | 0 | 0 | 0 |
| Spell Hit Chance | 0 | 0 | 0 |
| Melee Crit Chance | 5 | 0 | 5 |
| Ranged Crit Chance | 0 | 0 | 0 |
| Spell Crit Chance | 5 | 0 | 5 |
| Parry Chance | 0 | 0 | 0 |
| Dodge Chance | 3 | 0 | 3 |
| Block Chance | 0 | 0 | 0 |
| Magic Resistance | 10 | 0 | 10 |
| Fire Resistance | 1.666667 | 1.666667 | 100 |
| Frost Resistance | 1.666667 | 1.666667 | 100 |
| Nature Resistance | 1.666667 | 1.666667 | 100 |
| Arcane Resistance | 1.666667 | 1.666667 | 100 |
| Shadow Resistance | 1.666667 | 1.666667 | 100 |
| Holy Resistance | 0 | 0 | 0 |
| Resource Regeneration | 0 | 0 | 0 |
| Movement Speed | 30 | 0 | 30 |

Under the current Core `level_scaled_percent` mitigation model, a school-resistance rating of approximately `1.666667 × level` corresponds to approximately **25% damage mitigation**. Fire, Frost, Nature, Arcane and Shadow therefore remain at approximately 25% mitigation from level 1 through level 60.

Holy Resistance remains 0 because Holy currently uses direct mitigation rather than the percentage-reference model.

The Felhunter also has **10 Magic Resistance**. Unlike the elemental school-resistance ratings, Magic Resistance participates directly in the active percent-based spell defence check, so it is intentionally not level-scaled.

## Base appearance

The base Felhunter uses the classic Felhunter model:

- DisplayID `850`.

No FileDataID is authored because one has not been verified for the current client data. DisplayID-only appearances are valid in the Unit schema.

## Role

The base Felhunter is an anti-magic melee/spell hybrid:

- tougher than the Imp and broadly comparable to the Sayaad in raw durability, but less durable than the Voidwalker or Felguard;
- lower raw melee and spell offence than the Sayaad, because its strength is utility rather than damage;
- enough Melee Attack Power to remain a credible melee attacker;
- enough Spell Power to support magical pet abilities;
- substantially stronger innate anti-magic defence than the other demons.

## Presets

All three presets inherit the base Felhunter challenge level, stats, resources and appearance. Their spell lists are explicit replacements.

### Spellbreaker

Reactive anti-caster variant.

Spells:

- Pet Attack — `f82db71a:6uix049h`
- Spell Lock — `e8f3b2c6:wlspklk1`

### Devourer

Sustained mana-pressure/anti-caster variant.

Spells:

- Pet Attack — `f82db71a:6uix049h`
- Devour Mana — `e8f3b2c6:wldevmn1`
- Spell Lock — `e8f3b2c6:wlspklk1`

### Nullifier

Anti-magic debuff variant.

Spells:

- Pet Attack — `f82db71a:6uix049h`
- Curse of Tongues — `e8f3b2c6:wlctngs1`
- Curse of Shadows — `e8f3b2c6:wlcshads`

## Authoring notes

- Creature type: `demon`
- Creature size: `medium`
- Base challenge level: `normal`
- Uses Health and Mana.
- Damage Done and Damage Reduction are not seeded on the base unit.
- Fire, Frost, Nature, Arcane and Shadow Resistance use level-scaled stat rows rather than fixed values.
- The base unit deliberately contains no spells. Warlock Pet abilities should be defined on the Warlock Pet definition, while NPC variants use the explicit Unit preset spell lists above.
- The Spellbreaker and Devourer variants use the Felhunter-specific Spell Lock and Devour Mana import entries from the Warlock spell import sheet.
- Curse of Tongues in the Nullifier preset is the current 5-turn Spell Hit Chance reduction, not a casting lockout.

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
                displayId = 850,
            },
        },
        attributes = {  },
        challengeLevel = "normal",
        creatureSize = "medium",
        creatureType = "demon",
        id = "felhnt01",
        name = "Felhunter",
        presets = {
            {
                name = "Spellbreaker",
                resourceModifiers = {  },
                statModifiers = {  },
                spells = {
                    "f82db71a:6uix049h",
                    "e8f3b2c6:wlspklk1",
                },
                equipment = {  },
            },
            {
                name = "Devourer",
                resourceModifiers = {  },
                statModifiers = {  },
                spells = {
                    "f82db71a:6uix049h",
                    "e8f3b2c6:wldevmn1",
                    "e8f3b2c6:wlspklk1",
                },
                equipment = {  },
            },
            {
                name = "Nullifier",
                resourceModifiers = {  },
                statModifiers = {  },
                spells = {
                    "f82db71a:6uix049h",
                    "e8f3b2c6:wlctngs1",
                    "e8f3b2c6:wlcshads",
                },
                equipment = {  },
            },
        },
        resistances = {  },
        resources = {
            {
                initialValue = 160,
                perLevelValue = 39.661017,
                resourceRef = "f82db71a:q2ktkztt",
            },
            {
                initialValue = 120,
                perLevelValue = 33.559322,
                resourceRef = "f82db71a:4c8mfm99",
            },
        },
        spells = {  },
        stats = {
            {
                initialValue = 75,
                perLevelValue = 24.152542,
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
                initialValue = 3,
                perLevelValue = 0,
                statRef = "f82db71a:o6113cir",
            },
            {
                initialValue = 0,
                perLevelValue = 0,
                statRef = "f82db71a:p8syz5ba",
            },
            {
                initialValue = 10,
                perLevelValue = 0,
                statRef = "f82db71a:zs1nbz13",
            },
            {
                initialValue = 55,
                perLevelValue = 5.423729,
                statRef = "f82db71a:u7b49vs9",
            },
            {
                initialValue = 0,
                perLevelValue = 0,
                statRef = "f82db71a:v2rs9cpy",
            },
            {
                initialValue = 25,
                perLevelValue = 2.542373,
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
                initialValue = 1.666667,
                perLevelValue = 1.666667,
                statRef = "f82db71a:0w7c7p09",
            },
            {
                initialValue = 0,
                perLevelValue = 0,
                statRef = "f82db71a:hj6d4kvy",
            },
            {
                initialValue = 1.666667,
                perLevelValue = 1.666667,
                statRef = "f82db71a:jjn0my8k",
            },
            {
                initialValue = 1.666667,
                perLevelValue = 1.666667,
                statRef = "f82db71a:pg0ytacb",
            },
            {
                initialValue = 1.666667,
                perLevelValue = 1.666667,
                statRef = "f82db71a:954yunb9",
            },
            {
                initialValue = 1.666667,
                perLevelValue = 1.666667,
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
