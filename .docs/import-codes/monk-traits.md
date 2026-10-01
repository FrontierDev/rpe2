# Monk Trait Import Codes

Standalone `RPE_DATASET_ENTRY_V1` import codes for launch-era Mists of Pandaria Monk traits that can currently be represented faithfully by RPE.

## Authoring rules applied

- The three Monk stances are **Traits**, not spells, and are mutually exclusive.
- **Stance of the Sturdy Ox** implements the supported launch-era defensive effects: +25 Damage Reduction, +20% Stamina, and +10 Resource Regeneration. Stagger and critical-hit suppression are omitted because RPE does not currently model them faithfully.
- **Stance of the Fierce Tiger** implements +20 Damage Done. Its launch-era +1 Chi generation from Jab and Expel Harm is omitted because each spell name is assigned to one specialization and the Trait schema cannot modify a specific spell resource component.
- **Stance of the Wise Serpent** implements +20 Healing Done. AP/SP conversion, Spirit-to-Hit/Expertise conversion, and Eminence are omitted.
- **Swift Reflexes** implements its supported +5 Parry Chance. The reactive counterattack is omitted because RPE cannot specifically trigger it from a parry while preserving the original weapon-damage behavior.
- **Mana Meditation** grants +50 Resource Regeneration only when Mana is an allowed/current resource. This is the closest supported translation of retaining 50% Spirit-derived Mana regeneration in combat.
- **Brewmaster Training** is not authored as a separate trait. Tiger Palm and Blackout Kick are assigned to Windwalker to avoid duplicate spell names, while Brewmaster retains its own Chi generators and tank toolkit.
- **Teachings of the Monastery** is not authored separately because the supported Spinning Crane Kick healing is already encoded in the Mistweaver spell import.
- **Ascension** is deferred because the current Trait schema cannot increase maximum Chi.
- Way of the Monk, Leather Specialization, Sparring, Tiger Strikes, Combo Breaker, Power Strikes, Afterlife, Gift of the Ox, Gift of the Serpent, Tigereye Brew/Brewing, Eminence, Combat Conditioning, and Dematerialize are intentionally omitted rather than approximated with generic bonuses.

## Stance of the Sturdy Ox

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "traits",
    datasetId = "monkdata",
    entry = {
        automaticAuras = { },
        category = "Brewmaster",
        conditions = { },
        description = "",
        events = { },
        icon = "interface/icons/monk_stance_drunkenox.blp",
        id = "mnoxst01",
        isEnvironmental = false,
        mutuallyExclusiveTraitRefs = {
            "monkdata:mntigr01",
            "monkdata:mnserp01",
        },
        name = "Stance of the Sturdy Ox",
        skillBonuses = { },
        statBonuses = {
            {
                operation = "flat",
                statRef = "f82db71a:pu05li08",
                value = 25,
            },
            {
                operation = "percent",
                statRef = "f82db71a:ygjno50i",
                value = 20,
            },
            {
                operation = "flat",
                statRef = "f82db71a:rgnrtg01",
                value = 10,
            },
        },
        unlockLevel = 1,
    },
}
```

## Stance of the Fierce Tiger

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "traits",
    datasetId = "monkdata",
    entry = {
        automaticAuras = { },
        category = "Windwalker",
        conditions = { },
        description = "",
        events = { },
        icon = "interface/icons/monk_stance_whitetiger.blp",
        id = "mntigr01",
        isEnvironmental = false,
        mutuallyExclusiveTraitRefs = {
            "monkdata:mnoxst01",
            "monkdata:mnserp01",
        },
        name = "Stance of the Fierce Tiger",
        skillBonuses = { },
        statBonuses = {
            {
                operation = "flat",
                statRef = "f82db71a:gj9wxb0x",
                value = 20,
            },
        },
        unlockLevel = 1,
    },
}
```

## Stance of the Wise Serpent

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "traits",
    datasetId = "monkdata",
    entry = {
        automaticAuras = { },
        category = "Mistweaver",
        conditions = { },
        description = "",
        events = { },
        icon = "interface/icons/monk_stance_wiseserpent.blp",
        id = "mnserp01",
        isEnvironmental = false,
        mutuallyExclusiveTraitRefs = {
            "monkdata:mnoxst01",
            "monkdata:mntigr01",
        },
        name = "Stance of the Wise Serpent",
        skillBonuses = { },
        statBonuses = {
            {
                operation = "flat",
                statRef = "f82db71a:5pxmfw02",
                value = 20,
            },
        },
        unlockLevel = 1,
    },
}
```

## Swift Reflexes

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "traits",
    datasetId = "monkdata",
    entry = {
        automaticAuras = { },
        category = "General",
        conditions = { },
        description = "",
        events = { },
        icon = "interface/icons/ability_monk_parry.blp",
        id = "mnswref1",
        isEnvironmental = false,
        mutuallyExclusiveTraitRefs = { },
        name = "Swift Reflexes",
        skillBonuses = { },
        statBonuses = {
            {
                operation = "flat",
                statRef = "f82db71a:tcn0s8kx",
                value = 5,
            },
        },
        unlockLevel = 1,
    },
}
```

## Mana Meditation

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "traits",
    datasetId = "monkdata",
    entry = {
        automaticAuras = { },
        category = "Mistweaver",
        conditions = {
            {
                allowHealth = false,
                invert = false,
                resourceRef = "f82db71a:4c8mfm99",
                showOnTooltip = true,
                tooltipTextOverride = "Requires Mana",
                type = "resource_type",
            },
        },
        description = "",
        events = { },
        icon = "interface/icons/spell_monk_manatea.blp",
        id = "mnmanmed",
        isEnvironmental = false,
        mutuallyExclusiveTraitRefs = { },
        name = "Mana Meditation",
        skillBonuses = { },
        statBonuses = {
            {
                operation = "flat",
                statRef = "f82db71a:rgnrtg01",
                value = 50,
            },
        },
        unlockLevel = 1,
    },
}
```

