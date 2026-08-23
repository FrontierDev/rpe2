## Goal
Change all user-facing Data Editor terminology from **Guild Setting** to **Guild Rank** and allow authors to configure the WoW guild ranks that may be assigned to each RPE Guild Rank.

Depends on: #10

## Primary files
- `client/ui/editor/windows/window_DataEditor.lua`
- `client/ui/editor/pages/page_GuildSetting.lua`
- `client/ui/editor/inspectors/page_InspectorGuildSetting.lua`
- `client/ui/editor/pages/page_Datasets.lua` if user-facing collection labels/status text require changes
- related editor helpers found by repository search

## Data Editor terminology
Search every user-facing occurrence of:

```text
Guild Setting
Guild Settings
New Guild Setting
```

in the Data Editor and replace the product terminology with:

```text
Guild Rank
Guild Ranks
New Guild Rank
```

Do not rename internal Lua identifiers solely for display terminology. The underlying collection remains `guildSettings` and the class remains `GuildSetting`.

## Eligible WoW Guild Ranks editor
Add an editor for:

```lua
wowGuildRankIndices
```

under the General section.

Use existing RPE UI primitives and keep the control simple. A compact validated text/list editor is acceptable if no reusable multi-select exists.

Requirements:
- allow multiple non-negative indexes;
- explain `0 = highest WoW guild rank`;
- explain blank/empty means any WoW guild rank;
- normalize through `GuildSetting` rather than implementing a competing normalization path;
- multiple Guild Rank entries may contain the same WoW rank index.

One WoW guild rank mapping to several RPE Guild Ranks is intentional and must not be treated as an editor conflict.

## Requisition UI change
Remove the user-facing:

```text
Minimum Guild Rank
Minimum Guild Rank Index
```

editor backed by legacy `requiredGuildRankIndex` from the new authoring flow.

Do not delete or clear legacy stored `requiredGuildRankIndex` values merely because the field is no longer shown.

Keep the existing editors for:
- Requisition Item Ref;
- Quantity;
- Character Limit;
- Currency costs;
- Daily Rewards;
- Progression definitions;
- General feature flags/tags.

## Constraints
- Do not rename `GuildSetting`, `guildSettings`, files or SavedVariable structures for display terminology.
- Do not add Profile rank assignment.
- Do not change Guild runtime resolution in this task.
- Do not add officer Comms, Requisition transactions, Daily Reward grants or Progression mutation.
- Preserve generic create/select/delete/export/import behavior.

## Acceptance criteria
- [ ] Data Editor collection/button/empty-state/inspector text says Guild Rank(s), not Guild Setting(s).
- [ ] Internal `guildSettings` collection behavior remains intact.
- [ ] A Guild Rank can be authored with multiple WoW guild rank indexes.
- [ ] Empty mapping round-trips as unrestricted.
- [ ] Two different RPE Guild Ranks can both map to the same WoW rank.
- [ ] Requisition-level Minimum Guild Rank is no longer exposed for new authoring.
- [ ] Existing Requisition costs/limits and Daily Reward/Progression editors still work.
- [ ] Export/import preserves authored Guild Rank mappings.
- [ ] No Profile assignment or runtime Guild behavior is added.

## Coding-agent instructions
Read the revised PDD and implementation plan, then inspect all Data Editor collection labels, page mappings, inspector mappings and explicit strings before editing. Implement Task 2 only. Preserve internal compatibility identifiers and existing editor architecture; report changed files, validation performed and any deviation from this issue.