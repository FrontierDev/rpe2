# Gnome Race Import Code

Standalone `RPE_DATASET_ENTRY_V1` import code for the Gnome race in the Core dataset.

The base attributes come from `.docs/RPE2_WoW_Classic_Base_Stats_Reference.md`.

- Base attributes (STR / AGI / STA / INT / SPI): 15 / 23 / 19 / 23 / 20
- Trait import codes: `.docs/import-codes/classic-race-traits.md`
- Human and Dwarf are intentionally not modified by this import sheet.

Import the referenced racial Traits before importing this Race entry.

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "races",
    datasetId = "f82db71a",
    entry = {
        description = "",
        icon = "interface/icons/achievement_character_gnome_male.blp",
        id = "gnome001",
        name = "Gnome",
        resourceProgressions = {  },
        skillBonuses = {  },
        statProgressions = {
            {
                initialValue = 15,
                perLevelValue = 0,
                statRef = "f82db71a:zfqm8dxp",
            },
            {
                initialValue = 23,
                perLevelValue = 0,
                statRef = "f82db71a:xqz0daz2",
            },
            {
                initialValue = 19,
                perLevelValue = 0,
                statRef = "f82db71a:ygjno50i",
            },
            {
                initialValue = 23,
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
            "f82db71a:gnexp005",
            "f82db71a:racarc10",
            "f82db71a:gneng015",
        },
    },
}
```
