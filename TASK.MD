## Goal
Refactor `client/client_Guild.lua` from the Phase 1 single-setting/conflict model to the revised multi-rank catalogue and assignment eligibility model.

Depends on: #10, #12

## Primary files
- `client/client_Guild.lua`
- `core/internal/Registry.lua` if a semantic resolver alias is useful
- `core/internal/Runtime.lua` only if refresh routing requires a small adjustment

## Required facade behavior
Replace the semantic dependence on:

```lua
ResolveActiveGuildSetting()
GetActiveGuildSetting()
```

with catalogue-oriented helpers, for example:

```lua
Guild:GetApplicableGuildRanks()
Guild:GetEligibleGuildRanksForWoWRank(wowRankIndex)
Guild:GetAssignedGuildRankRef()
Guild:GetAssignedGuildRank()
Guild:GetAssignedGuildRankStatus()
```

Exact naming may follow current conventions. Compatibility wrappers may remain temporarily if existing UI still calls them during this task, but new behavior must not return a conflict merely because multiple Guild Rank entries apply.

## Applicable Guild Rank catalogue
Use activated datasets from the existing Registry path.

Resolution rules:
1. Player must currently be in a WoW guild.
2. Search Guild Rank definitions in activated datasets (`guildSettings` internally).
3. Collect all exact `guildName` matches.
4. If at least one exact match exists, the complete exact-match set is the applicable catalogue.
5. Otherwise use all blank/generic `guildName` entries.
6. Multiple applicable entries are expected and are **not** a conflict.
7. Preserve each rank's qualified `datasetId:guildSettingId` reference.

Do not silently collapse the catalogue to one rank.

## WoW rank eligibility
For a target WoW guild rank index:

```text
wowGuildRankIndices empty -> eligible
otherwise -> eligible only if exact integer index is present
```

Do **not** infer a hierarchy using `<=`, `>=`, rank names or array order.

A single WoW guild rank may make several RPE Guild Ranks eligible at the same time.

## Assigned-rank validation
Resolve the Profile `assignedRankRef` against the applicable catalogue and the local player's current WoW guild rank.

Return explicit status for at least:

```text
valid
unassigned
unknown-rank
not-applicable
not-eligible-for-current-wow-rank
guild-loading
not-in-guild
```

The exact representation may follow current result-table patterns, but callers must be able to distinguish these states.

Do not automatically fix, replace or clear an invalid/stale assignment.

## Officer state
Preserve the centralized:

```lua
Client.Guild:IsLocalPlayerOfficer()
```

behavior from Phase 1. RPE Guild Rank assignment/eligibility must not confer officer permission.

## Constraints
- Do not write Profile assignment state during catalogue resolution or runtime refresh.
- Do not reintroduce the old equal-priority conflict model for multiple ranks.
- Do not infer implicit RPE Guild Rank hierarchy/inheritance.
- Do not add Requisition transactions, Daily Reward grants or Progression writes.
- Keep guild event integration on the existing centralized Runtime frame.

## Acceptance criteria
- [ ] Multiple exact Guild Ranks for one guild are returned without conflict.
- [ ] Multiple generic Guild Ranks are returned when no exact catalogue exists.
- [ ] Exact catalogue takes priority over generic catalogue as a set.
- [ ] One WoW rank can return multiple eligible RPE Guild Ranks.
- [ ] Eligibility is set membership, not `<=` hierarchy logic.
- [ ] Assigned rank resolves from Profile state.
- [ ] Invalid/stale assignments produce explicit status.
- [ ] No assignment is written or changed by catalogue/runtime refresh.
- [ ] `IsLocalPlayerOfficer()` remains centralized and intact.
- [ ] No Requisition/Daily Reward/Progression transaction behavior is added.

## Coding-agent instructions
Read the revised PDD and implementation plan, then inspect the current Phase 1 Guild facade and Runtime event routing before editing. Implement Task 4 only. Prefer a coherent catalogue/result API over scattered special cases, preserve existing officer detection, and report changed files, validation performed and any deviation from this issue.