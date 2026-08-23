## Goal
Create the Phase 1 `GuildSetting` dataset class and normalize all guild configuration structures **without implementing gameplay behavior**.

Task 1 (`Achievement` normalization) is already complete on `main`; preserve its conventions and the current RPE2 architecture.

## Primary files
- `core/classes/GuildSetting.lua` **new**
- `RPEngine_Dev.toc`

## Required data model
```lua
GuildSetting {
    id = nil,
    name = "",
    description = "",
    guildName = "",
    general = {
        enableRequisitions = false,
        enableDailyRewards = false,
        enableProgression = false,
    },
    requisitions = {},
    dailyRewards = {},
    progression = {
        slotCount = 3,
        entries = {},
    },
    tags = {},
}
```

### Requisitions
Normalize each definition to:
```lua
{
    id = "stable_id",
    itemRef = "dataset:item",
    quantity = 1,
    costs = {
        { currencyRef = "copper", amount = 1 },
    },
    requiredGuildRankIndex = nil,
    characterLimit = 1,
}
```
Requirements:
- stable non-empty IDs with deterministic duplicate handling;
- string `itemRef`;
- `quantity >= 1` integer;
- cost amounts `>= 0`;
- guild rank index nil or non-negative integer;
- `characterLimit >= 1`, default 1.

### Daily rewards
Normalize:
```lua
{
    id = "stable_id",
    type = "item", -- item | currency
    ref = "dataset:item-or-currency",
    amount = 1,
}
```
Requirements:
- stable/duplicate-safe IDs;
- type restricted to `item` or `currency`;
- string ref;
- amount integer `>= 1`.

### Progression
Phase 1 stores configuration only:
```lua
progression = {
    slotCount = 3,
    entries = {
        {
            id = "entry_id",
            name = "",
            description = "",
            icon = "",
            lockedText = "",
            spellRefs = {},
        },
    },
}
```
Normalize stable entry IDs, strings, and unique non-empty spell refs.

## Constraints
- Follow existing class patterns (`Currency.lua`, `Skill.lua`, `Achievement.lua`).
- Do not add character-specific state to `GuildSetting`.
- Do not add purchase, reward-claim, progression-unlock, or other runtime behavior.
- Do not hard-code guild rank names or Holy Order terminology.
- Add the class to the TOC in dependency-safe order before any future consumer.

## Acceptance criteria
- [ ] `GuildSetting:New()` returns a complete safe default.
- [ ] `FromTable(ToTable(x))` is stable for normalized data.
- [ ] Missing nested tables never error.
- [ ] Nested IDs are deterministic and duplicate-safe.
- [ ] Spell refs are unique/non-empty after normalization.
- [ ] `RPEngine_Dev.toc` loads the class before consumers.
- [ ] No Phase 2/3/4 behavior is introduced.

## Coding-agent instructions
Inspect current adjacent class patterns before editing. Make the smallest coherent change. Report changed files, validation performed, and any deviation from this issue.