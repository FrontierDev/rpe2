# Vulpera Race Import Code

Standalone `RPE_DATASET_ENTRY_V1` import code for the Vulpera race in the Core dataset.

- Base attributes (STR / AGI / STA / INT / SPI): 17 / 22 / 20 / 23 / 18
- Trait import codes: `.docs/import-codes/bfa-race-traits.md`
- RPE deliberately uses the Goblin base-stat chassis as the closest existing small Horde-race baseline; this is an RPE balance mapping, not a historical WoW racial stat table.

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
        icon = "interface/icons/achievement_alliedrace_vulpera.blp",
        id = "vulpera1",
        name = "Vulpera",
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
                initialValue = 20,
                perLevelValue = 0,
                statRef = "f82db71a:ygjno50i",
            },
            {
                initialValue = 23,
                perLevelValue = 0,
                statRef = "f82db71a:75y3a8ib",
            },
            {
                initialValue = 18,
                perLevelValue = 0,
                statRef = "f82db71a:kec9rhli",
            },
        },
        traitRefs = {
            "f82db71a:vulfire15",
            "f82db71a:vulnose1",
            "f82db71a:vulcamp5",
            "f82db71a:vultrik5",
        },
    },
}
```
