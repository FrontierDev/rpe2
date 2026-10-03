# Mechagnome Race Import Code

Standalone `RPE_DATASET_ENTRY_V1` import code for the Mechagnome race in the Core dataset.

- Base attributes (STR / AGI / STA / INT / SPI): 15 / 23 / 19 / 23 / 20
- Trait import codes: `.docs/import-codes/bfa-race-traits.md`
- RPE deliberately uses the Gnome base-stat chassis for this allied-race variant.

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
        icon = "interface/icons/achievement_alliedrace_mechagnome.blp",
        id = "mechagnm",
        name = "Mechagnome",
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
            "f82db71a:mgcombat",
            "f82db71a:mgmast15",
            "f82db71a:mgfails5",
            "f82db71a:mgpinkie",
        },
    },
}
```
