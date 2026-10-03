# Dark Iron Dwarf Race Import Code

Standalone `RPE_DATASET_ENTRY_V1` import code for the Dark Iron Dwarf race in the Core dataset.

- Base attributes (STR / AGI / STA / INT / SPI): 22 / 16 / 23 / 19 / 19
- Trait import codes: `.docs/import-codes/bfa-race-traits.md`
- RPE deliberately uses the Dwarf base-stat chassis for this allied-race variant.

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
        icon = "interface/icons/achievement_alliedrace_darkirondwarf.blp",
        id = "darkiron",
        name = "Dark Iron Dwarf",
        resourceProgressions = {  },
        skillBonuses = {  },
        statProgressions = {
            {
                initialValue = 22,
                perLevelValue = 0,
                statRef = "f82db71a:zfqm8dxp",
            },
            {
                initialValue = 16,
                perLevelValue = 0,
                statRef = "f82db71a:xqz0daz2",
            },
            {
                initialValue = 23,
                perLevelValue = 0,
                statRef = "f82db71a:ygjno50i",
            },
            {
                initialValue = 19,
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
            "f82db71a:didung05",
            "f82db71a:diforge1",
            "f82db71a:dimass15",
            "f82db71a:difire15",
        },
    },
}
```
