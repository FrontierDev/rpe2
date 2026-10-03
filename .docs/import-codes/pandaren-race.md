# Pandaren Race Import Code

Standalone `RPE_DATASET_ENTRY_V1` import code for the Pandaren race in the Core dataset.

- Base attributes (STR / AGI / STA / INT / SPI): 20 / 18 / 21 / 19 / 22
- Trait import codes: `.docs/import-codes/mop-race-traits.md`
- Active or unsupported racial mechanics are intentionally omitted or translated into supported non-combat skills.

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
        icon = "interface/icons/achievement_character_pandaren_male.blp",
        id = "pandaren",
        name = "Pandaren",
        resourceProgressions = {  },
        skillBonuses = {  },
        statProgressions = {
            {
                initialValue = 20,
                perLevelValue = 0,
                statRef = "f82db71a:zfqm8dxp",
            },
            {
                initialValue = 18,
                perLevelValue = 0,
                statRef = "f82db71a:xqz0daz2",
            },
            {
                initialValue = 21,
                perLevelValue = 0,
                statRef = "f82db71a:ygjno50i",
            },
            {
                initialValue = 19,
                perLevelValue = 0,
                statRef = "f82db71a:75y3a8ib",
            },
            {
                initialValue = 22,
                perLevelValue = 0,
                statRef = "f82db71a:kec9rhli",
            },
        },
        traitRefs = {
            "f82db71a:pangrm15",
            "f82db71a:panboun5",
            "f82db71a:paninr05",
            "f82db71a:panepic5",
        },
    },
}
```
