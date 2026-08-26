## Goal
Remove the **data-layer foundation** of Guild Progression while preserving every unrelated Guild and character-progression system.

Authoritative plan: `.docs/RPE2-Remove-Guild-Progression-Implementation-Plan.md`.

This task covers only:

- `GuildSetting` schema/normalization/serialization;
- Guild-specific Profile progression APIs/state access;
- GuildSetting progression dependency discovery/pruning.

Do **not** remove runtime/UI callers in this task; those are handled by follow-up issues.

## Primary files

- `core/classes/GuildSetting.lua`
- `core/internal/profile/Guild.lua`
- `core/internal/database/Dependecies.lua`

## Critical scope boundary
RPE 2 contains unrelated progression systems. Preserve generic character progression code including concepts such as:

```text
statProgressions
resourceProgressions
```

and generic helpers used by class/race/stat/resource progression.

Only remove **Guild-specific** progression concepts such as:

```text
GuildSetting.progression
general.enableProgression
profile.guild.byGuild[...].progression
Guild Progression spellRefs
```

Before deleting any helper named `progression`, inspect its callers and prove it belongs only to Guild Progression.

## 1. Remove Guild Progression from `GuildSetting`

In `core/classes/GuildSetting.lua`:

- remove `general.enableProgression` from defaults and normalization;
- remove the `progression = { slotCount = ..., entries = ... }` definition;
- remove Guild Progression-only normalization helpers such as the current progression-entry/spell-ref normalization chain;
- remove progression normalization from `Merge()`;
- remove progression from `ToTable()` serialization.

### Legacy definition handling
`GuildSetting:Merge()` currently accepts incoming table keys before normalization. Do not leave legacy input able to reintroduce active `self.progression` state simply because the normalizer was deleted.

After merge/normalization, a live GuildSetting object must not expose active Guild Progression data. Explicitly discard legacy:

```text
progression
general.enableProgression
```

where necessary in the existing normalization path.

Do not introduce a new schema migration framework for this removal.

Newly serialized GuildSettings must contain neither field.

## 2. Remove Guild Profile progression APIs

In `core/internal/profile/Guild.lua`, remove Guild Progression-only helpers and public APIs, including the current equivalents of:

```text
normalizeProgressionEntryId
normalizeProgressionState
getGuildProgressionState
updateGuildProgressionState

Profile.GetGuildProgression
Profile.SetGuildProgression
Profile.SetGuildProgressionSlot
Profile.SetGuildProgressionEntryUnlocked
Profile.SetGuildProgressionSelectedSpell
Profile.ClearGuildProgressionSelectedSpell
```

Remove aliases/wrappers whose only purpose is Guild Progression.

Preserve all remaining Guild profile behavior, especially:

```text
assignedRankRef
assignedRankAt
assignedRankBy
requisition usage
daily reward claim state
daily reward transaction state
guild identity migration
```

### Legacy SavedVariables
Do **not** add permanent migration code solely to erase an already-saved:

```lua
profile.guild.byGuild[guildKey].progression
```

Legacy progression state may remain physically present in SavedVariables as inert data. The requirement is that no active Profile API reads or writes it after the full removal.

## 3. Remove GuildSetting progression dependency handling

In `core/internal/database/Dependecies.lua`, remove only the dependency logic that traverses:

```text
GuildSetting.progression.entries[*].spellRefs
```

This includes both:

- source-reference discovery;
- reference rewrite/pruning for GuildSetting progression spell refs.

### Do not remove the generic progression dependency helper
The file also contains progression-reference logic used by unrelated class/race/stat/resource definitions. Inspect callers carefully and preserve generic logic such as the helper that handles:

```text
statProgressions
resourceProgressions
traitRefs
skillBonuses
```

Do not delete that generic helper wholesale merely because its name contains `Progression`.

## Acceptance criteria

- [ ] `GuildSetting.general` no longer contains `enableProgression`.
- [ ] `GuildSetting` no longer defines or serializes `progression`.
- [ ] Legacy GuildSetting input cannot leave active `self.progression` or `general.enableProgression` state after normalization/merge.
- [ ] Newly serialized GuildSettings contain no Guild Progression fields.
- [ ] Guild Profile exposes no Guild Progression get/set/mutation APIs.
- [ ] Existing legacy profile progression SavedVariables can remain inert without causing load errors.
- [ ] GuildSetting dependency discovery no longer adds progression `spellRefs`.
- [ ] GuildSetting dependency rewrite/pruning no longer traverses progression entries.
- [ ] Requisition, Daily Reward, Guild Rank and guild-identity Profile state remain unchanged.
- [ ] Generic class/race/stat/resource progression dependency logic remains intact.

## Validation matrix

```text
new GuildSetting
-> no enableProgression
-> no progression table

legacy GuildSetting table containing progression + enableProgression
-> merge/load succeeds
-> live normalized object does not expose active Guild Progression state
-> ToTable() omits both legacy fields

existing character profile containing guild.progression SavedVariables
-> profile loads without error
-> unrelated Guild state remains readable

GuildSetting requisition/item/currency dependencies
-> still discovered normally

GuildSetting Daily Reward dependencies
-> still discovered normally

GuildSetting legacy progression spellRefs
-> no longer contribute dependencies

generic class/race/stat/resource progression definition
-> dependency behavior unchanged
```

## Constraints

- Do not edit `client/client_Guild.lua` in this task unless compilation/load requires a tiny transitional fix; runtime removal is the next task.
- Do not edit Guild window/Admin/editor UI here.
- Do not remove generic progression systems.
- Do not add a migration framework solely to purge old SavedVariables.
- Do not change requisition, Daily Reward, Achievement, Skill, Item or Guild Rank semantics.

## Coding-agent instructions
Use current `FrontierDev/rpe2` as authoritative. This task is intended for **5.6-Luna-ExtraHigh**. Read `.docs/RPE2-Remove-Guild-Progression-Implementation-Plan.md` first. Inspect every progression helper's callers before deletion, especially in `Dependecies.lua`, because generic non-Guild progression code must survive. Keep the change narrowly data-layer focused. Report exact files changed, legacy-input behavior, serialization results, dependency validation, and any unavoidable transitional edits.