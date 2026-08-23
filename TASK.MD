## Goal
Make Achievement and GuildSetting references participate correctly in the existing RPE2 Registry/dependency system.

Depends on: #1, #2

## Primary files
- `core/internal/Registry.lua`
- `core/internal/database/Dependecies.lua`

## Registry additions
Add resolvers using the existing dataset-qualified reference parser/cache path:
- `Registry:ResolveAchievementReference(achievementRef)`
- `Registry:ResolveAchievementName(achievementRef)`
- `Registry:ResolveGuildSettingReference(guildSettingRef)`

Do not create a second resolution mechanism.

## Dependency extraction
### Achievement criteria filters
Recognize known dataset-qualified refs from:
- `currencyRef`
- `unitRef`
- `achievementRef`

Do not treat every arbitrary filter string as a dependency.

### GuildSetting
Collect refs from:
- `requisitions[].itemRef`
- `requisitions[].costs[].currencyRef`
- `dailyRewards[].ref`
- `progression.entries[].spellRefs[]`

Built-in currencies such as `copper` must not create dataset dependencies.

## Rewrite/prune/deletion handling
Inspect all existing dependency recalculation, referenced-dataset deletion, source-pruning and reference-rewrite paths. Extend the relevant explicit collection handling for Achievement/GuildSetting references so they do not become a blind spot.

Do not broadly rewrite arbitrary strings.

## Acceptance criteria
Using conceptual datasets A/B where B references entries in A:
- [ ] B detects A as a dependency through Achievement filters.
- [ ] B detects A through GuildSetting item/currency/spell refs.
- [ ] Same-dataset refs do not create self-dependencies.
- [ ] Built-in `copper` does not create a dependency.
- [ ] Deletion/recompute behavior is consistent with existing Item/Spell/etc. handling.
- [ ] Existing dependency behavior is unchanged.

## Coding-agent instructions
Search all explicit collection maps/branches in `Dependecies.lua` before editing. Keep the implementation narrow and aligned with existing reference semantics.