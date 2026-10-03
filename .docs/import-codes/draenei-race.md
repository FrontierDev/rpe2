# Draenei Race Import Code

Standalone `RPE_DATASET_ENTRY_V1` import code for the Draenei race in the Core dataset.

- Base attributes (STR / AGI / STA / INT / SPI): 21 / 17 / 19 / 21 / 22
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
        icon = "interface/icons/achievement_character_draenei_male.blp",
        id = "draenei1",
        name = "Draenei",
        resourceProgressions = {  },
        skillBonuses = {  },
        statProgressions = {
            {
                initialValue = 21,
                perLevelValue = 0,
                statRef = "f82db71a:zfqm8dxp",
            },
            {
                initialValue = 17,
                perLevelValue = 0,
                statRef = "f82db71a:xqz0daz2",
            },
            {
                initialValue = 19,
                perLevelValue = 0,
                statRef = "f82db71a:ygjno50i",
            },
            {
                initialValue = 21,
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
            "f82db71a:drhero01",
            "f82db71a:drgem005",
            "f82db71a:drshd010",
        },
    },
}
```
