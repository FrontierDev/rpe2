# RPE 2 — Guild Rank Revision Implementation Plan
## VS Codex / 5.4-Luna-ExtraHigh

**Repository:** `FrontierDev/rpe2`  
**Design source of truth:** `RPE2-Achievements-Guild-Systems-PDD.md`  
**Baseline:** Phase 1 Tasks 1–10 are complete.  
**Purpose:** Refactor the completed Guild data/UI shell to the revised **RPE Guild Rank** model, then implement the remaining Guild/Achievement runtime phases against that model.

---

# Coding-agent operating rules

For every task:

1. Read the current repository before editing.
2. Read the revised `RPE2-Achievements-Guild-Systems-PDD.md` sections relevant to the task.
3. Treat `FrontierDev/rpe2` as the only implementation source of truth.
4. Do not use the predecessor repository as an architectural or API source.
5. Implement only the current task. Do not begin later tasks because adjacent code is convenient to edit.
6. Preserve existing Phase 1 behavior unless the task explicitly replaces it.
7. Prefer additive/backward-compatible migrations over destructive conversion.
8. Keep the current internal `GuildSetting` / `guildSettings` names unless the task explicitly says otherwise. The **external/user-facing name is Guild Rank**.
9. Never automatically assign, remap or clear a character's RPE Guild Rank from WoW guild rank state.
10. A character has at most one assigned RPE Guild Rank per guild.
11. One WoW guild rank may make multiple RPE Guild Ranks eligible for officer assignment.
12. WoW officer permission controls administration. An RPE Guild Rank does not confer officer permission.
13. Remote mutations are applied by the target member's own client after receiver-side validation.
14. Requisitions, Daily Rewards and Progression are scoped to the character's valid assigned RPE Guild Rank.
15. After implementation, review the diff against every acceptance criterion in the task and report deviations.

Recommended Codex prompt for each issue copied into `TASK.MD`:

```text
Read TASK.MD and RPE2-Achievements-Guild-Systems-PDD.md.
Inspect the current repository before making changes.
Implement TASK.MD only.
Do not begin the next task.
Preserve backward compatibility unless TASK.MD explicitly changes behavior.
When finished, review the diff against every acceptance criterion in TASK.MD and report any deviations.
```

---

# Task order

```text
1  Guild Rank dataset model/migration
   ↓
2  Guild Rank Data Editor terminology + WoW-rank mapping authoring
   ↓
3  Profile assigned-rank state APIs
   ↓
4  Guild Rank catalogue + eligibility facade
   ↓
5  Assigned-rank Guild window/read-only UI
   ↓
6  Officer Guild Rank assignment protocol + Admin UI
   ↓
7  Rank-scoped Requisition runtime
   ↓
8  Rank-scoped Daily Reward runtime

9  Achievement runtime ───────────────────────────┐
                                                  ↓
10 General Guild Admin Achievement/Skill/Item operations

3 + 4 + 6 ──> 11 Rank-scoped Progression runtime/admin

1–11 ───────> 12 Integration audit and completion validation
```

Tasks 9 and 10 may be developed after Task 6 independently of Tasks 7/8, but the numbered order is recommended for a linear Codex workflow.

---

# Task 1 — Extend the internal GuildSetting model for RPE Guild Ranks

## Goal

Make the existing internal `GuildSetting` dataset object capable of representing an RPE Guild Rank while preserving existing Phase 1 datasets.

## Primary files

- `core/classes/GuildSetting.lua`
- `core/internal/database/Database.lua`
- `RPEngine_Dev.toc` only if load order requires correction

## Required changes

Add normalized:

```lua
wowGuildRankIndices = {}
```

to `GuildSetting`.

Normalization contract:

- array of non-negative integers;
- invalid/non-finite/negative values are dropped;
- duplicates are removed;
- preserve deterministic input order for surviving values;
- missing field normalizes to `{}`;
- empty array means unrestricted by WoW guild rank.

Keep the internal class and dataset collection names:

```text
GuildSetting
guildSettings
```

Do **not** rename SavedVariable keys, collection keys, class registration keys or existing file names merely for terminology.

Increment Dataset schema:

```text
15 → 16
```

Old datasets without `wowGuildRankIndices` must normalize safely to unrestricted RPE Guild Ranks.

### Legacy Requisition rank field

The existing Requisition field:

```lua
requiredGuildRankIndex
```

is superseded by the new rank-scoped model.

For this task:

- preserve it during normalization/serialization so old data is not silently destroyed;
- mark it as compatibility/legacy in code comments where useful;
- do not use it to populate `wowGuildRankIndices` automatically;
- do not add runtime behavior.

The old minimum-rank rule cannot reliably infer the author's intended new RPE Guild Rank mapping.

## Acceptance criteria

- [ ] Existing Phase 1 datasets load without errors.
- [ ] Existing GuildSetting entries gain `wowGuildRankIndices = {}` when absent.
- [ ] Multiple integer indexes normalize and round-trip.
- [ ] Duplicate indexes are removed deterministically.
- [ ] Invalid/negative indexes cannot survive normalization.
- [ ] Existing Requisitions/Daily Rewards/Progression/tags survive normalization.
- [ ] Legacy `requiredGuildRankIndex` data is not destroyed.
- [ ] Dataset export/import preserves `wowGuildRankIndices`.
- [ ] Dataset schema becomes 16 without lowering any future higher schema marker.
- [ ] No Profile assignment, Guild UI, Comms or gameplay behavior is added.

---

# Task 2 — Expose GuildSetting entries as Guild Ranks in the Data Editor

## Goal

Change all user-facing Data Editor terminology from **Guild Setting** to **Guild Rank** and allow authors to configure the WoW guild ranks that may be assigned to each RPE Guild Rank.

## Primary files

- `client/ui/editor/windows/window_DataEditor.lua`
- `client/ui/editor/pages/page_GuildSetting.lua`
- `client/ui/editor/inspectors/page_InspectorGuildSetting.lua`
- `client/ui/editor/pages/page_Datasets.lua` if user-facing collection labels/status text require changes
- related editor helpers found by repository search

## Required changes

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

Do not rename internal Lua identifiers solely for display terminology.

### Eligible WoW Guild Ranks editor

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

### Requisition UI change

Remove the user-facing `Minimum Guild Rank` / `requiredGuildRankIndex` editor from new authoring flow.

Do not delete legacy stored values merely because the field is no longer shown.

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

---

# Task 3 — Add assigned RPE Guild Rank state to Profile

## Goal

Add backward-compatible per-guild Profile state and thin Profile APIs for the officer-assigned RPE Guild Rank.

## Primary files

- `core/internal/database/Database.lua`
- `core/internal/profile/Guild.lua`

## Required Profile shape

Within each guild bucket support:

```lua
profile.guild.byGuild[guildKey] = {
    assignedRankRef = nil,
    assignedRankAt = nil,
    assignedRankBy = nil,
    ...existing/future fields...
}
```

Increment Profile schema:

```text
5 → 6
```

Normalization must preserve unknown/future nested Guild state, including existing Requisition and Progression data.

### Thin API

Add narrow helpers such as:

```lua
Profile.GetGuildBucket(guildKey)
Profile.GetAssignedGuildRank(guildKey)
Profile.SetAssignedGuildRank(guildKey, guildRankRef, metadata)
Profile.ClearAssignedGuildRank(guildKey)
```

Exact naming may follow current conventions, but callers must not need to mutate the raw `profile.guild` table directly.

`SetAssignedGuildRank` should normalize:

- `guildRankRef` string;
- optional assignment timestamp;
- optional assigning officer display identity.

This task deliberately does not decide whether a rank is valid for a particular WoW guild rank. That belongs to the Guild facade/receiver validation tasks.

## Acceptance criteria

- [ ] Old Profiles without assignment fields normalize safely.
- [ ] Existing Guild nested state is preserved.
- [ ] Assignment set/get/clear survives `/reload` through SavedVariables.
- [ ] Reads do not expose mutable internal tables unnecessarily.
- [ ] Profile schema becomes 6 without lowering a future higher marker.
- [ ] Setting a rank does not award rewards, unlock progression or perform a requisition.
- [ ] No automatic assignment occurs on initialization or normalization.
- [ ] No Comms/UI behavior is added.

---

# Task 4 — Replace single GuildSetting resolution with a Guild Rank catalogue

## Goal

Refactor `client/client_Guild.lua` from the Phase 1 single-setting/conflict model to the revised multi-rank catalogue and assignment eligibility model.

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

Compatibility wrappers may remain temporarily if existing UI still calls them during this task, but new behavior must not return a conflict merely because multiple Guild Rank entries apply.

### Applicable catalogue rules

1. Player must be in a guild.
2. Search activated datasets.
3. Collect exact `guildName` matches.
4. If at least one exact match exists, use the complete exact-match set.
5. Otherwise use all blank/generic `guildName` entries.
6. Multiple entries are expected.
7. Keep each rank's qualified `datasetId:guildSettingId` ref.

### Eligibility rules

For a target WoW rank index:

- empty `wowGuildRankIndices` → eligible;
- otherwise eligible only when the exact integer index is present.

Do not infer hierarchy from numeric comparison.

### Assigned-rank validation

Resolve Profile `assignedRankRef` against the applicable catalogue.

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

Do not automatically fix an invalid assignment.

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

---

# Task 5 — Refactor the Guild window to display the assigned Guild Rank

## Goal

Update the existing read-only Guild window to use the revised assigned-rank model before any transactions are enabled.

## Primary files

- `client/character/guild/window_Guild.lua`
- `client/character/guild/page_GuildRequisitions.lua`
- `client/character/guild/page_GuildProgression.lua`
- `client/character/guild/page_GuildAdmin.lua`
- `client/client_Guild.lua` only for small facade support required by the pages

## Required behavior

Show local assignment status prominently:

```text
Guild Rank: Medic
Guild Rank: Not assigned
Guild Rank: Medic (no longer valid for current WoW rank)
```

### Requisitions page

Display only the Requisitions and Daily Rewards belonging to the valid assigned RPE Guild Rank.

If no valid rank is assigned, show a clean explanatory state and no active buttons.

Remove any displayed `Minimum Guild Rank` field derived from legacy `requiredGuildRankIndex`.

### Progression page

Display only the progression definition belonging to the valid assigned RPE Guild Rank.

Still read-only in this task.

### Admin page

Continue to show the live WoW guild roster and officer gating.

Add read-only/planned presentation for the selected member's RPE Guild Rank where useful, but do not implement remote assignment yet.

Remove the old Phase 1 `multiple active Guild Settings conflict` UX because multiple Guild Ranks are expected.

## Acceptance criteria

- [ ] Guild window still opens from Launcher and `/rpe guild`.
- [ ] All three tabs still render.
- [ ] Local assigned Guild Rank is displayed.
- [ ] Unassigned state is clear.
- [ ] Invalid assignment state is clear and does not mutate Profile.
- [ ] Requisitions/Daily Rewards displayed come only from the valid assigned rank.
- [ ] Progression displayed comes only from the valid assigned rank.
- [ ] Multiple catalogue ranks do not show a conflict error.
- [ ] Admin roster still refreshes on guild events.
- [ ] No purchases, reward grants, assignment writes or progression writes occur.

---

# Task 6 — Implement officer RPE Guild Rank assignment over existing Comms

## Goal

Allow a WoW guild officer to set or clear an online member's RPE Guild Rank, with the target client's own RPE instance validating and persisting the assignment.

## Primary files

- `core/internal/comms/Operations.lua`
- existing Comms send/dispatch files as required by current patterns
- `client/client_Guild.lua`
- `client/character/guild/page_GuildAdmin.lua`
- `core/internal/profile/Guild.lua`
- `core/internal/Runtime.lua` only if needed for refresh after acknowledgement

## Protocol

Inspect the current operation table before allocating opcodes. Do not assume 24+ if the repository has changed.

Implement request/response support sufficient for:

```text
Guild Admin member query
set_guild_rank
clear_guild_rank
mutation acknowledgement
```

Use existing targeted addon `WHISPER` transport and serialization/chunking.

### Officer UI

When an officer selects an online roster member:

- show the member's WoW guild rank;
- query current RPE Guild Rank state;
- show all RPE Guild Ranks eligible for that member's WoW guild rank according to the officer's current catalogue;
- allow Set and Clear actions;
- do not optimistically display success before acknowledgement.

### Receiver validation

The target client independently validates:

```text
sender identity came from transport
sender is in the same guild
sender currently has WoW officer capability
target is this client's own active character
requested Guild Rank exists
requested Guild Rank is applicable to this guild
requested Guild Rank allows this client's live WoW guild rank index
```

Do not trust a sender-supplied target rank index or officer flag.

On success, store assignment through Profile/Guild APIs with assignment metadata and refresh local Guild UI.

## Acceptance criteria

- [ ] Officer can query an online RPE member's assigned rank.
- [ ] Officer can set one of multiple eligible RPE Guild Ranks.
- [ ] Officer can clear the assignment.
- [ ] Non-officer UI cannot perform active assignment.
- [ ] Receiver rejects spoofed/non-officer senders.
- [ ] Receiver rejects a rank not applicable to its guild.
- [ ] Receiver rejects a rank not eligible for its own live WoW rank.
- [ ] Sender payload cannot override receiver-derived permission/rank state.
- [ ] Successful mutation persists in the target Profile.
- [ ] Explicit success/failure acknowledgement is returned.
- [ ] No rank is automatically assigned outside this officer operation.
- [ ] No Achievement/Skill/Item mutation is implemented yet.

---

# Task 7 — Implement rank-scoped Requisition transactions

## Goal

Activate Requisition purchasing using only the character's valid assigned RPE Guild Rank.

## Primary files

- `client/client_Guild.lua` or a focused Guild transaction module consistent with current organization
- `core/internal/profile/Guild.lua`
- `core/internal/profile/Currencies.lua`
- `client/character/inventory/Inventory.lua` only as a consumer, not a replacement
- `client/character/guild/page_GuildRequisitions.lua`

## Required transaction API

Use one central operation such as:

```lua
Guild:TryRequisition(guildRankRef, requisitionId)
```

Validation:

```text
valid assigned rank exists
requested guildRankRef equals assigned rank
enableRequisitions is true
requisition exists in assigned rank
item resolves
character limit not reached
all currency refs resolve
all costs are affordable
inventory award is possible
```

Only then commit.

### Commit

- spend every required currency through existing Profile currency APIs;
- grant item through `Client.Inventory.AddItem()`;
- increment Profile Guild requisition ledger keyed by `guildRankRef` and Requisition ID;
- refresh UI.

Implement rollback/restoration if a failure occurs after spending begins. Never leave a partial currency transaction.

Do not use legacy `requiredGuildRankIndex` for eligibility.

## Acceptance criteria

- [ ] No assigned rank → cannot requisition.
- [ ] Invalid assigned rank → cannot requisition.
- [ ] Requisition from another rank → rejected.
- [ ] Disabled Requisitions → rejected.
- [ ] Multiple arbitrary currency costs work.
- [ ] Built-in `copper` works without dataset dependency assumptions.
- [ ] Insufficient currency causes no spending.
- [ ] Character lifetime limit is enforced per rank/requisition.
- [ ] Item grant uses `Client.Inventory.AddItem()`.
- [ ] Failed transaction cannot leave partial currency deductions.
- [ ] Successful usage persists through reload.
- [ ] Legacy minimum WoW-rank field is ignored.

---

# Task 8 — Implement rank-scoped Daily Rewards

## Goal

Award the assigned RPE Guild Rank's Daily Rewards once per character, per guild, per calendar day without automatically assigning a rank.

## Primary files

- `client/client_Guild.lua` or focused Guild reward module
- `core/internal/Runtime.lua`
- `core/internal/profile/Guild.lua`
- `core/internal/profile/Currencies.lua`
- `client/character/inventory/Inventory.lua` as award path
- `client/character/guild/page_GuildRequisitions.lua`

## Required behavior

Trigger/retry from the existing centralized runtime on appropriate login/guild-context events.

Eligibility:

```text
in guild
guild context loaded
valid assigned RPE Guild Rank
enableDailyRewards = true
not already claimed for current guild/calendar day
all reward definitions valid
```

Award only the assigned rank's rewards.

Use:

- `Client.Inventory.AddItem()` for items;
- existing Profile currency add API for currencies.

Store:

```lua
dailyRewardDate
dailyRewardRankRef
```

in the per-guild Profile bucket.

The claim key is calendar-day based, not rolling 24 hours.

Changing RPE Guild Rank after claiming must not permit another reward that day.

Design the award/claim sequence so `/reload` cannot duplicate an already completed claim. Do not record success before required awards have been applied.

## Acceptance criteria

- [ ] No assigned rank → no reward and no auto-assignment.
- [ ] Invalid assigned rank → no reward.
- [ ] Disabled Daily Rewards → no reward.
- [ ] Item and currency rewards use canonical APIs.
- [ ] One claim per guild/calendar day survives reload/relog.
- [ ] Changing rank after claim does not yield a second reward.
- [ ] `dailyRewardRankRef` records which rank supplied the claimed reward.
- [ ] Guild context loading races do not duplicate rewards.
- [ ] UI accurately reports claimed/not-eligible state.

---

# Task 9 — Implement the Achievement runtime

## Goal

Activate automatic Achievement progression and completion using the Phase 1 Achievement model without coupling it to Guild Rank assignment.

## Primary files

- new `client/client_Achievements.lua` or equivalent focused module
- `core/internal/profile/Achievements.lua`
- `core/internal/profile/Currencies.lua`
- `client/client_Resources.lua`
- event-completion integration point identified from current repository
- `client/character/profile/page_ProfileAchievements.lua`
- `RPEngine_Dev.toc`

## Trigger contract

Implement:

```text
manual
currency_gain
rpe_kill
rpe_event_complete
achievement_earned
```

Build an index from activated dataset Achievement criteria rather than scanning all criteria on every event.

### Currency

Trigger from actual positive applied gain in `Profile.AddCurrencyAmount()`, not absolute set/spend operations.

### Kill

Trigger only from the authoritative committed alive → dead EventUnit transition. Do not award from preliminary damage preview. Do not double-count already-dead units.

### Completion

On incomplete → complete transition:

- persist criterion progress;
- set `completedAt` once;
- process `achievement_earned` dependents;
- refresh Profile UI;
- announce to Guild and Raid when appropriate.

Already-completed state loaded from Profile must never re-announce.

Provide an explicit manual `Grant()` path for Task 10 Guild Admin.

## Acceptance criteria

- [ ] Currency gain uses actual applied positive delta after cap.
- [ ] Currency spending/absolute set does not count as earning.
- [ ] Kill progression uses authoritative alive→dead transition only.
- [ ] Dead-unit repeats do not count again.
- [ ] Filters select only matching criteria.
- [ ] Meta Achievements progress from `achievement_earned`.
- [ ] `completedAt` is set exactly once per completion transition.
- [ ] Reloading completed state does not announce again.
- [ ] Guild/Raid announcements are visible chat, not addon synchronization.
- [ ] Manual `Grant()` uses normal completion handling.

---

# Task 10 — Extend Guild Admin to Achievement, Skill and Item mutations

## Goal

Build the remaining Guild Admin operations on the receiver-validated request/response protocol introduced by Task 6.

## Primary files

- `core/internal/comms/Operations.lua`
- existing Comms send/dispatch files as required
- `client/client_Guild.lua`
- `client/character/guild/page_GuildAdmin.lua`
- Achievement runtime from Task 9
- Profile skill APIs
- Inventory APIs

## Required operations

```text
grant_achievement
adjust_skill
give_item
```

Extend member query response as needed for the Admin UI to display:

- Achievement earned state;
- relevant Skill levels;
- assigned RPE Guild Rank.

Do not transmit inventory merely to give an item.

### Receiver validation

Every mutation validates sender same-guild/officer status and target-self state again. Do not rely only on prior query success or UI gating.

### Mutation paths

Achievement:

```lua
Achievements:Grant(...)
```

Skill:

```lua
Profile.GetSkillLevel(...)
Profile.SetSkillLevel(...)
```

Item:

```lua
Registry:ResolveItemReference(...)
Client.Inventory.AddItem(...)
```

## Acceptance criteria

- [ ] Officer can grant a valid Achievement to an online RPE member.
- [ ] Achievement uses normal completion/announcement behavior.
- [ ] Officer can increase/decrease a valid Skill within valid numeric bounds.
- [ ] Officer can give a valid Item/quantity through Inventory.
- [ ] Invalid references/quantities are rejected by receiver.
- [ ] Non-officer/spoofed senders are rejected.
- [ ] Each mutation receives explicit acknowledgement.
- [ ] Officer UI does not optimistically report success.
- [ ] Existing Guild Rank set/clear operations still work.

---

# Task 11 — Implement rank-scoped Guild Progression and officer progression admin

## Goal

Activate the existing structural Progression definitions as character state scoped to the assigned valid RPE Guild Rank.

## Primary files

- `client/client_Guild.lua` or focused Guild progression module
- `core/internal/profile/Guild.lua`
- `client/character/guild/page_GuildProgression.lua`
- `client/character/guild/page_GuildAdmin.lua`
- `core/internal/comms/Operations.lua` / Guild Admin protocol handlers

## Runtime/state model

Persist under:

```lua
profile.guild.byGuild[guildKey].progression[guildRankRef]
```

with state for:

```text
slots
unlocked entries
selected spells
```

Only the currently assigned valid rank's progression is active/displayed.

Changing rank does not delete previous rank-scoped progression state.

Validate selected spells against the configured entry's `spellRefs`.

### UI

Render the assigned rank's configured slots/entries using existing RPE UI primitives. Support more entries/slots than fit in a fixed three-column view through scrolling/pagination.

### Officer administration

Extend the existing Guild Admin protocol/UI to allow an officer to:

- assign an entry to a progression slot;
- lock/unlock an entry;
- clear an invalid/undesired selected spell.

Receiver validates the mutation against its own currently assigned RPE Guild Rank and dataset definition.

## Acceptance criteria

- [ ] No assigned/valid rank → no active progression.
- [ ] Progression state is keyed by RPE Guild Rank ref.
- [ ] Switching ranks preserves prior rank state but activates only the current rank.
- [ ] Progression survives reload/relog.
- [ ] Locked entries cannot be selected.
- [ ] Selected spell must exist in configured `spellRefs`.
- [ ] UI is not hard-coded to exactly three entries.
- [ ] Officer remote mutations are receiver-validated and acknowledged.
- [ ] Core contains no campaign-specific rank/oath terminology.

---

# Task 12 — Guild Rank revision integration audit and completion validation

## Goal

Audit Tasks 1–11 as one coherent implementation, fixing only concrete defects discovered by the audit.

## Required audit

### Terminology

Search user-facing UI for stale:

```text
Guild Setting
Guild Settings
Minimum Guild Rank
```

Internal compatibility identifiers may remain, but the product UI should use Guild Rank terminology.

### Migration

Smoke-test conceptual/current-code normalization for:

```text
Profile schema 5 → 6
Dataset schema 15 → 16
old GuildSetting without wowGuildRankIndices
old requisitions containing requiredGuildRankIndex
existing Profile.guild nested data
```

No automatic character assignment may occur during migration.

### Catalogue/assignment

Verify:

- exact-vs-generic catalogue set precedence;
- multiple ranks in one catalogue;
- multiple RPE ranks for one WoW rank;
- unrestricted mapping;
- manual assignment only;
- stale assignment status without auto-fix;
- receiver-side rank validation.

### Rank-scoped runtime

Verify:

- Requisition definitions from assigned rank only;
- Daily Rewards from assigned rank only;
- one Daily Reward per guild/day even after rank change;
- Progression from assigned rank only;
- old rank progression/requisition state remains preserved.

### Guild Admin security boundary

Verify every remote mutation derives sender from transport and independently checks same-guild/officer status on the target client.

### Achievement runtime

Verify currency, authoritative kill, completion/meta and announcement behavior.

### Phase/non-goal audit

Ensure the implementation has not introduced:

```text
automatic RPE Guild Rank assignment
automatic rank remapping/clearing
multiple simultaneous assigned RPE Guild Ranks
implicit RPE rank hierarchy/inheritance
offline remote Profile mutation
direct remote SavedVariable writes
```

## Definition of done

- [ ] Existing Phase 1 data remains loadable.
- [ ] Guild Rank is the external terminology.
- [ ] Dataset mappings support many RPE ranks per WoW rank.
- [ ] Character rank is officer-assigned only.
- [ ] Rank assignment is stored per guild and receiver-validated.
- [ ] Requisitions are rank-scoped and transactional.
- [ ] Daily Rewards are rank-scoped and once-per-guild/day.
- [ ] Achievement runtime works without rank coupling.
- [ ] General Guild Admin mutations are receiver-validated.
- [ ] Progression is rank-scoped and persistent.
- [ ] No prohibited automatic rank behavior exists.
- [ ] Load order, schemas, exports/imports and dependency handling remain coherent.

---

# Recommended Codex execution workflow

For each task:

1. Open the corresponding GitHub issue.
2. Copy the full issue body into repository-root `TASK.MD`.
3. Run VS Codex with **5.4-Luna-ExtraHigh** using the standard task prompt from this document.
4. Review Codex's diff and acceptance-criterion report.
5. Commit and push that task only.
6. Review the pushed repository before closing the issue.
7. Move to the next task only after the current issue is accepted.
