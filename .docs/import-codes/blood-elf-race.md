# Blood Elf Race Import Code

Standalone `RPE_DATASET_ENTRY_V1` import code for the Blood Elf race in the Core dataset.

- Base attributes (STR / AGI / STA / INT / SPI): 17 / 22 / 18 / 24 / 19
- Trait import codes: `.docs/import-codes/tbc-race-traits.md`
- Active racial abilities are intentionally omitted.

Import the supporting Aura and racial Traits before importing this Race entry.

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "races",
    datasetId = "f82db71a",
    entry = {
        description = "",
        icon = "interface/icons/achievement_character_bloodelf_male.blp",
        id = "bloodelf",
        name = "Blood Elf",
        resourceProgressions = {  },
        skillBonuses = {  },
        statProgressions = {
            {
                initialValue = 17,
                perLevelValue = 0,
                statRef = "f82db71a:zfqm8dxp",
            },
            {
                initialValue = 22,
                perLevelValue = 0,
                statRef = "f82db71a:xqz0daz2",
            },
            {
                initialValue = 18,
                perLevelValue = 0,
                statRef = "f82db71a:ygjno50i",
            },
            {
                initialValue = 24,
                perLevelValue = 0,
                statRef = "f82db71a:75y3a8ib",
            },
            {
                initialValue = 19,
                perLevelValue = 0,
                statRef = "f82db71a:kec9rhli",
            },
        },
        traitRefs = {
            "f82db71a:bearc010",
            "f82db71a:bemagic5",
        },
    },
}
```
