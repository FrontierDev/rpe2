## Goal
Add backward-compatible per-guild Profile state and thin Profile APIs for the officer-assigned RPE Guild Rank.

Depends on: #10

## Primary files
- `core/internal/database/Database.lua`
- `core/internal/profile/Guild.lua`

## Required Profile state
Within each guild bucket support:

```lua
profile.guild.byGuild[guildKey] = {
    assignedRankRef = nil,
    assignedRankAt = nil,
    assignedRankBy = nil,
    ...existing/future fields...
}
```

The Profile continues to store one guild bucket per guild. A character may have at most one assigned RPE Guild Rank in a guild at a time.

Normalization must preserve unknown/future nested Guild state, including existing/future Requisition and Progression data. Do not destructively replace the guild bucket with only the assignment fields.

## Schema
Increment only the Profile schema:

```text
5 -> 6
```

Old Profiles without assignment fields must normalize safely. Follow the existing monotonic schema behavior and do not lower any future higher schema marker.

## Thin Profile API
Add narrow helpers such as:

```lua
Profile.GetGuildBucket(guildKey)
Profile.GetAssignedGuildRank(guildKey)
Profile.SetAssignedGuildRank(guildKey, guildRankRef, metadata)
Profile.ClearAssignedGuildRank(guildKey)
```

Exact naming may follow current Profile conventions, but callers must not need to mutate the raw `profile.guild` table directly.

`SetAssignedGuildRank` should normalize:
- `guildRankRef` as a non-empty string/reference;
- optional assignment timestamp;
- optional assigning officer display identity.

Returned state should follow existing Database/Profile copy semantics so callers cannot accidentally bypass persistence/notification paths.

## Scope boundary
This task deliberately does **not** decide whether a requested rank is valid for a particular WoW guild rank. Catalogue eligibility and receiver-side validation belong to later tasks.

Setting assignment state must not itself:
- award Daily Rewards;
- enable/claim a Requisition;
- unlock Progression;
- grant an Achievement;
- send Comms;
- infer assignment from the local WoW rank.

## Constraints
- Preserve all existing `profile.guild.byGuild` nested data.
- Do not introduce another SavedVariable root.
- Do not automatically assign, remap or clear a rank during normalization, login or guild events.
- Do not add UI or Comms behavior.
- Keep this module a persistence primitive, not Guild business logic.

## Acceptance criteria
- [ ] Old Profiles without assignment fields normalize safely.
- [ ] Existing Guild nested state is preserved.
- [ ] Assignment set/get/clear survives `/reload` through SavedVariables.
- [ ] Reads do not expose mutable internal tables unnecessarily.
- [ ] Profile schema becomes 6 without lowering a future higher marker.
- [ ] Setting a rank does not award rewards, unlock progression or perform a requisition.
- [ ] No automatic assignment occurs on initialization or normalization.
- [ ] No Comms/UI behavior is added.

## Coding-agent instructions
Read the revised PDD and implementation plan, then inspect all current Guild Profile normalization/default-state/accessor paths before editing. Implement Task 3 only. Keep the new APIs thin and persistence-focused; report changed files, validation performed and any deviation from this issue.