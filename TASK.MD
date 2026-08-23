## Goal
Make `guildSettings` a first-class Dataset collection and add persistent Achievement/Guild character state using the existing centralized Database normalization model.

Depends on: #1

## Primary file
- `core/internal/database/Database.lua`

## Required changes
### Schema
Increment only:
- profiles `4 -> 5`
- datasets `14 -> 15`

### Dataset integration
Add `guildSettings` to `DATASET_ENTRY_DEFINITIONS` using class `GuildSetting`, singular `Guild Setting`, `assignsId = true`.

Add `guildSettings = ensureTable(data.guildSettings)` to normalized Dataset records and ensure generic create/import/export/update/delete flows accept it.

### Profile state
Add normalized fields:
```lua
achievements = {}
guild = { byGuild = {} }
```
They must be included anywhere Profile defaults/normalization/default-profile checks enumerate fields.

Normalize Achievement state to:
```lua
profile.achievements = {
    [achievementRef] = {
        criteria = { [criterionId] = 0 },
        completedAt = nil,
    },
}
```
Rules:
- non-empty achievement keys;
- non-empty criterion keys;
- criterion progress integer `>= 0`;
- `completedAt` nil or non-negative number.

Guild state normalization should preserve nested future fields instead of destructively constraining them; guarantee the outer `{ byGuild = {} }` shape only.

### Database accessors
Add thin persistence helpers consistent with current Profile DB patterns:
- `ListProfileAchievementStates()`
- `GetProfileAchievementState(achievementRef)`
- `SetProfileAchievementState(achievementRef, state)`
- `ClearProfileAchievementState(achievementRef)`
- `GetProfileGuildState()`
- `SetProfileGuildState(state)`

Use copies where adjacent APIs return copies and existing configuration-change notification for mutations.

## Constraints
- No Achievement completion semantics.
- No requisition/reward/progression behavior.
- Existing inventory/currencies/skills/equipment/spells must remain untouched.
- Preserve backward compatibility with schema-4 Profiles and schema-14 Datasets.

## Acceptance criteria
- [ ] Existing Profiles normalize safely to schema 5 without data loss.
- [ ] Existing Datasets normalize safely to schema 15 with empty `guildSettings`.
- [ ] Generic Dataset APIs create/import/export GuildSettings.
- [ ] Achievement/Guild Profile state persists.
- [ ] Existing Profile behavior is unchanged.

## Coding-agent instructions
Inspect all Profile normalization/default/migration paths before editing; do not assume one constructor is sufficient. Keep this issue bounded to Database persistence and Dataset collection integration.