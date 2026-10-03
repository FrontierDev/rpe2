# Dracthyr Race Import Code

Standalone `RPE_DATASET_ENTRY_V1` import code for the Dracthyr race in the Core dataset.

- Base attributes (STR / AGI / STA / INT / SPI): 20 / 20 / 20 / 20 / 20
- Trait import codes: `.docs/import-codes/dragonflight-race-traits.md`
- RPE deliberately uses the balanced Human base-stat chassis for Dracthyr. Modern WoW does not provide a comparable pre-6.0 five-stat racial table for Dracthyr, so this is an explicit RPE balance mapping rather than a historical racial stat record.

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
        icon = "interface/icons/achievement_character_dracthyr_male.blp",
        id = "dracthyr",
        name = "Dracthyr",
        resourceProgressions = {  },
        skillBonuses = {  },
        statProgressions = {
            {
                initialValue = 20,
                perLevelValue = 0,
                statRef = "f82db71a:zfqm8dxp",
            },
            {
                initialValue = 20,
                perLevelValue = 0,
                statRef = "f82db71a:xqz0daz2",
            },
            {
                initialValue = 20,
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
            "f82db71a:drctawak",
            "f82db71a:drcteye5",
            "f82db71a:drctglid",
            "f82db71a:drctvis5",
        },
    },
}
```
