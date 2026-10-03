# Nightborne Race Import Code

Standalone `RPE_DATASET_ENTRY_V1` import code for the Nightborne race in the Core dataset.

- Base attributes (STR / AGI / STA / INT / SPI): 17 / 25 / 19 / 20 / 20
- Trait import codes: `.docs/import-codes/bfa-race-traits.md`
- RPE deliberately uses the Night Elf base-stat chassis because the Nightborne are a direct kaldorei offshoot.

Import the racial Traits before importing this Race entry.

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "races",
    datasetId = "f82db71a",
    entry = {
        description = "",
        icon = "interface/icons/achievement_alliedrace_nightborne.blp",
        id = "nightbrn",
        name = "Nightborne",
        resourceProgressions = {  },
        skillBonuses = {  },
        statProgressions = {
            {
                initialValue = 17,
                perLevelValue = 0,
                statRef = "f82db71a:zfqm8dxp",
            },
            {
                initialValue = 25,
                perLevelValue = 0,
                statRef = "f82db71a:xqz0daz2",
            },
            {
                initialValue = 19,
                perLevelValue = 0,
                statRef = "f82db71a:ygjno50i",
            },
            {
                initialValue = 20,
                perLevelValue = 0,
                statRef = "f82db71a:75y3a8ib",
            },
            {
                initialValue = 20,
                perLevelValue = 0,
                statRef = "f82db71a:kec9rhli",
            },
        },
        traitRefs = {
            "f82db71a:nbanc15",
            "f82db71a:nbmagic1",
            "f82db71a:nbarc15",
            "f82db71a:nbcantr5",
        },
    },
}
```
