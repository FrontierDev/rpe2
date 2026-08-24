# RPE 2 — Phase 5 Remaining Achievement Features
## GPT-5.6 Luna ExtraHigh / Codex Implementation Plan

**Repository:** `FrontierDev/rpe2`  
**Baseline commit:** `271e9683de4cd60df1a2df2f1d5fbd8d4a9cc199` (`8-23 Revision Task Final`)  
**Primary design source:** `RPE2-Achievements-Guild-Systems-PDD.md`  
**Previous implementation plan:** `RPE2-Guild-Rank-Revision-Codex-Implementation-Plan.md`  
**Completed scope:** PDD Phases 1–4 / GitHub issues #1–#21  
**Phase 5 scope:** one PDD compliance cleanup, the six explicitly deferred Achievement triggers, and a deliberately narrow Achievement Reward system.

---

# 1. Current implementation baseline

The current codebase already implements the PDD's required Phase 1–4 systems:

- normalized Achievement definitions and stable criterion IDs;
- Profile Achievement state and `completedAt`;
- initial Achievement runtime:
  - `manual`
  - `currency_gain`
  - `rpe_kill`
  - `rpe_event_complete`
  - `achievement_earned`
- Profile → Achievements UI;
- Achievement authoring UI;
- RPE Guild Rank dataset/editor/profile/catalogue;
- officer-only manual rank assignment with receiver-side validation;
- rank-scoped Requisitions;
- rank-scoped Daily Rewards;
- general Guild Admin Achievement/Skill/Item mutations;
- rank-scoped Guild Progression and Progression administration;
- Dataset/Profile schema versions 16 / 6;
- final integration audit.

The remaining PDD-backed Achievement triggers are explicitly listed in the PDD as future triggers:

```text
item_gain
skill_gain
rpe_boss_kill
rpe_damage
rpe_healing
rpe_event_started
```

Achievement `rewards` currently exists as opaque Dataset data. The current Data Editor preserves it but does not define a reward schema or execute rewards.

There is also one current PDD/code divergence: the PDD calls for one stable Guild identity key using the best stable Blizzard guild identity available with fallback, while `client/client_Guild.lua` currently keys Guild Profile state by `guildName` alone.

---

# 2. Phase 5 design boundaries

## 2.1 Source-backed work

The following work is directly supported by the current PDD:

- fix the stable per-guild identity key;
- implement the six explicitly deferred Achievement triggers;
- keep criterion progress keyed by stable criterion IDs;
- use authoritative committed RPE state for combat/event progression;
- continue using existing Profile, Inventory, Registry, Runtime and Comms systems.

## 2.2 New design extension: Achievement Rewards

The PDD reserves:

```lua
Achievement {
    ...
    rewards = {},
}
```

but deliberately does not define execution semantics.

Phase 5 therefore introduces the smallest practical reward model:

```lua
rewards = {
    {
        id = "reward_1",
        type = "item",
        ref = "campaign:medal",
        amount = 1,
    },
    {
        id = "reward_2",
        type = "currency",
        ref = "campaign:commendation",
        amount = 5,
    },
}
```

Only `item` and `currency` rewards are in scope.

Do not add:

- arbitrary executable Lua rewards;
- spells as rewards;
- Skills as rewards;
- Guild Rank assignment as rewards;
- Progression changes as rewards;
- offline/mail delivery;
- account-wide rewards.

## 2.3 Reward safety policy

Achievement completion remains authoritative and transition-based:

```text
incomplete
   ↓
complete
```

`completedAt` must be persisted before reward execution.

Reward delivery must be separately persistent and idempotent. A reward failure does **not** un-complete the Achievement.

Existing completed Achievements created before the reward runtime is introduced must **not** automatically receive retroactive rewards during migration/login.

---

# 3. Coding-agent rules for GPT-5.6 Luna ExtraHigh

For every task:

1. Read `TASK.MD`.
2. Read the relevant sections of `RPE2-Achievements-Guild-Systems-PDD.md`.
3. Inspect the current repository before editing; do not implement from this document alone.
4. Treat current `FrontierDev/rpe2` APIs and architecture as authoritative.
5. Implement the current task only.
6. Do not begin the next task.
7. Preserve backward compatibility unless the task explicitly changes behavior.
8. Search adjacent call sites, explicit maps, TOC ordering and persistence normalization before adding a new hook.
9. Prefer the existing canonical mutation path over adding a parallel path.
10. Never derive Achievement combat credit from preview/predicted spell state when committed resource state exists.
11. Use actual applied positive deltas, not requested values, for gain triggers.
12. Do not trust client-supplied sender/authority fields where transport/runtime authority already exists.
13. Do not create another SavedVariable root.
14. Do not create another Inventory, Currency, Achievement runtime, Event authority layer or Guild Admin protocol.
15. Do not silently delete unknown future/legacy fields during normalization.
16. At task completion, compare the diff against every acceptance criterion and report:
    - changed files;
    - validation performed;
    - any deviation or unresolved concern.

Recommended handoff prompt:

```text
Read TASK.MD and RPE2-Achievements-Guild-Systems-PDD.md.
Inspect the current FrontierDev/rpe2 repository before making changes.
Implement TASK.MD only. Do not begin the next task.
Preserve backward compatibility unless TASK.MD explicitly changes behavior.
Use the repository's existing canonical persistence/runtime/authority APIs rather than introducing parallel systems.
When finished, review the diff against every acceptance criterion in TASK.MD and report changed files, validation performed, and any deviation.
```

---

# 4. Task sequence

```text
Task 0  Stable Guild identity key cleanup
   ↓
Task 1  Extend Achievement trigger/filter contract
   ↓
Task 2  Data Editor authoring for new triggers
   ↓
Task 3  item_gain runtime
   ↓
Task 4  skill_gain runtime
   ↓
Task 5  rpe_event_started runtime
   ↓
Task 6  authoritative rpe_damage / rpe_healing runtime
   ↓
Task 7  rpe_boss_kill runtime
   ↓
Task 8  Structured Achievement Reward model + Dataset schema 17
   ↓
Task 9  Achievement Reward authoring UI
   ↓
Task 10 Persistent reward-delivery Profile state + Profile schema 7
   ↓
Task 11 Idempotent Achievement Reward execution
   ↓
Task 12 Profile Achievement reward/status UI
   ↓
Task 13 Phase 5 integration audit
```

---

# Task 0 — Replace guild-name-only Profile keys with a stable Guild identity key

## Goal

Bring the existing Guild Profile key into line with the PDD: use one centralized Guild identity helper based on the best stable Blizzard guild identity currently available, with a deterministic fallback, instead of `guildName` alone.

## Primary files

- `client/client_Guild.lua`
- `core/internal/profile/Guild.lua`
- `core/internal/database/Database.lua` only if migration/normalization needs support
- current Guild Runtime/UI call sites found by repository search

## Current issue

Current code conceptually does:

```lua
local function getGuildKey(identity)
    return trimText(identity and identity.guildName)
end
```

This can theoretically collide for separate guild identities sharing the same display name.

## Required behavior

Before editing, inspect currently available Blizzard guild identity APIs used elsewhere in the addon and select the strongest stable identity available on the target WoW interface.

Use one helper for every Guild subsystem.

Fallback must remain deterministic and backward-compatible enough to recover existing name-keyed state.

## Migration

Existing:

```lua
profile.guild.byGuild[oldGuildName]
```

must not be abandoned.

When a stable new key can be resolved for the current guild:

- migrate or alias the old bucket into the new key only when the source/target relationship is unambiguous;
- preserve every nested field;
- do not overwrite a populated new bucket destructively;
- do not automatically assign/remap/clear `assignedRankRef`.

Preserve at least:

```text
assignedRankRef
assignedRankAt
assignedRankBy
dailyRewardDate
dailyRewardRankRef
dailyRewardTransaction
requisitions
progression
future/unknown nested fields
```

## Constraints

- Do not redesign Guild Rank catalogue semantics.
- Do not change officer eligibility.
- Do not alter Requisition/Daily Reward/Progression business rules.
- Do not introduce a new SavedVariable.
- Do not guess a stable Blizzard ID if the target API does not expose one; use the strongest supported identity plus documented fallback.

## Acceptance criteria

- [ ] All Guild Profile lookups use one centralized key helper.
- [ ] The key is stronger than guild name alone when the WoW API exposes stronger identity.
- [ ] Existing name-keyed Guild Profile state remains accessible/migrates safely.
- [ ] Nested Guild state is preserved.
- [ ] Migration never automatically assigns/remaps/clears an RPE Guild Rank.
- [ ] Requisitions, Daily Rewards and Progression still resolve the same current guild bucket after migration.
- [ ] No unrelated gameplay behavior changes.

---

# Task 1 — Extend the Achievement trigger and filter contract

## Goal

Add the six PDD-deferred Achievement trigger tokens to the normalized Achievement model and runtime trigger index contract without implementing the actual event hooks yet.

## Primary files

- `core/classes/Achievement.lua`
- `client/client_Achievements.lua`
- `core/internal/database/Dependecies.lua`
- `core/internal/Registry.lua` only if an existing resolver needs a narrow semantic helper

## Trigger additions

```text
item_gain
skill_gain
rpe_boss_kill
rpe_damage
rpe_healing
rpe_event_started
```

Preserve all existing trigger values unchanged.

## Supported filter semantics

Formalize these optional filter fields:

```text
item_gain
  itemRef

skill_gain
  skillRef

rpe_boss_kill
  unitRef
  enemyOnly

rpe_damage
  unitRef
  enemyOnly

rpe_healing
  unitRef
  enemyOnly

rpe_event_started
  eventId
```

Do not interpret arbitrary filter strings as executable logic.

Unknown filter keys must survive unrelated normalization/editing.

## Trigger index

Extend the existing `CriteriaByTrigger` / equivalent indexed runtime design so the new trigger tokens can be indexed.

Do not add event integration in this task.

## Dependency extraction

Add known dataset-qualified references:

- `itemRef` → Item dependency;
- `skillRef` → Skill dependency;
- `unitRef` → Unit dependency.

`eventId` is not automatically a Dataset dependency unless the current Event model uses a dataset-qualified reference and the repository provides an existing dependency convention for it.

## Acceptance criteria

- [ ] All six trigger tokens normalize and round-trip.
- [ ] Existing five trigger tokens remain unchanged.
- [ ] Existing stable criterion IDs remain stable.
- [ ] New filters normalize without deleting unknown filter data.
- [ ] New qualified reference filters participate in dependency extraction.
- [ ] Runtime trigger index accepts the six new trigger keys.
- [ ] No item/skill/event/combat progress is emitted in this task.

---

# Task 2 — Add Data Editor authoring for Phase 5 Achievement triggers

## Goal

Expose the six new trigger types and their supported filters through the existing Achievement Data Editor.

## Primary files

- `client/ui/editor/inspectors/page_InspectorAchievement.lua`
- related Achievement editor helpers discovered by repository inspection

## Trigger dropdown additions

```text
Item Gain
Skill Gain
RPE Boss Kill
RPE Damage
RPE Healing
RPE Event Started
```

Stored values must use the canonical Task 1 trigger tokens.

## Filter controls

Expose only the structured controls relevant to the selected trigger:

```text
Item Gain
  Item Ref

Skill Gain
  Skill Ref

RPE Boss Kill
  Unit Ref
  Enemy Only

RPE Damage
  Unit Ref
  Enemy Only

RPE Healing
  Unit Ref
  Enemy Only

RPE Event Started
  Event ID
```

Use current RPE Data Editor primitives and existing reference-input conventions.

## Preservation rule

Changing a trigger or editing one supported filter must not silently erase unknown filter keys or IDs belonging to unaffected criteria.

## Acceptance criteria

- [ ] All six Phase 5 triggers can be authored.
- [ ] Existing trigger authoring remains functional.
- [ ] Correct filter controls appear for each new trigger.
- [ ] Stable criterion IDs survive unrelated edits.
- [ ] Unknown filter fields survive unrelated edits/export/import.
- [ ] No Profile Achievement state is mutated by editor actions.

---

# Task 3 — Implement `item_gain` Achievement progression

## Goal

Advance `item_gain` criteria from actual successful canonical RPE item additions.

## Primary files

- `client/client_Achievements.lua`
- `client/character/inventory/Inventory.lua` only if a narrow post-add notification/hook is required
- `core/internal/Runtime.lua` only if listener registration must be deferred
- `RPEngine_Dev.toc` only if load order needs correction

## Authority

The canonical gain source is successful:

```lua
Client.Inventory.AddItem(...)
```

Use the existing Inventory change notification if it exposes sufficient information; otherwise add the smallest post-success callback/listener at the canonical `AddItem` boundary.

Do not count:

```text
Inventory load
SetItems state replacement
normalization
RemoveItem
Delete
UI refresh
```

## Context

Provide enough data for matching/progress:

```lua
{
    itemRef = "dataset:item",
    datasetId = "dataset",
    itemId = "item",
    amount = actualAddedQuantity,
    source = "inventory-add",
}
```

`amount` is the actual successful quantity added.

## Intentional sources

These should count because they use the canonical Inventory grant path:

- Guild Requisition;
- Daily Reward;
- Guild Admin Give Item;
- future Achievement Item reward.

## Acceptance criteria

- [ ] Successful `AddItem()` advances matching `item_gain`.
- [ ] Quantity >1 advances by actual quantity once.
- [ ] `itemRef` filter uses exact qualified-reference match.
- [ ] Nonmatching item does not progress.
- [ ] Inventory load/normalization does not progress.
- [ ] Item removal does not progress.
- [ ] Existing stacking/max-stack/BOP behavior is unchanged.
- [ ] No duplicate progress occurs from one successful add.

---

# Task 4 — Implement `skill_gain` Achievement progression

## Goal

Advance `skill_gain` criteria from actual positive persisted Skill increases.

## Primary files

- `core/internal/profile/Profile.lua`
- `core/internal/database/Database.lua` only if the canonical setter must expose the final applied value more clearly
- `client/client_Achievements.lua`
- existing direct Skill mutation call sites found by repository search

## Canonical change boundary

Prefer a small Profile-level Skill change listener/callback rather than making Profile persistence depend directly on `Client.Achievements`.

Emit only after a successful canonical `Profile.SetSkillLevel()` mutation.

Calculate:

```text
previousLevel
updatedLevel
actualGain = updatedLevel - previousLevel
```

Dispatch only when:

```text
actualGain > 0
```

Do not use the requested delta if normalization/bounds changed the applied result.

## Runtime call-site audit

Search for direct gameplay/Admin use of:

```lua
Database.SetProfileSkillLevel(...)
```

and route gameplay mutations through `Profile.SetSkillLevel()` where necessary so there is one canonical gain boundary.

Database normalization/loading must not emit Skill gain events.

## Context

```lua
{
    skillRef = "dataset:skill",
    previousLevel = 4,
    updatedLevel = 6,
    amount = 2,
    source = "profile-skill-change",
}
```

## Acceptance criteria

- [ ] Positive actual Skill increase advances matching criteria.
- [ ] Decrease does not progress.
- [ ] Same-value set does not progress.
- [ ] Progress amount equals actual persisted positive difference.
- [ ] `skillRef` filter uses exact match.
- [ ] Profile load/normalization does not emit gain.
- [ ] Guild Admin increase counts.
- [ ] Guild Admin decrease remains valid but does not count.
- [ ] Existing Skill bounds remain authoritative.

---

# Task 5 — Implement `rpe_event_started` Achievement progression

## Goal

Advance event-start criteria once from the accepted authoritative RPE event-start path.

## Primary files

- `client/client_Event.lua`
- `client/client_Achievements.lua`

## Authority

Use the existing accepted `Client:HandleEventStart(...)` path only after the message/session validation and real active Event state are established.

Do not emit from:

- Event Manager preview;
- local Event construction;
- UI opening/refresh;
- repeated Event visual refresh.

## Idempotency

The same Event instance must not increment twice if the start path is replayed/reprocessed.

Use a transient runtime marker associated with the active Event instance or existing Event startup runtime.

Do not persist this marker into Dataset/Profile state.

## Context

```lua
{
    eventId = eventState.id,
    eventName = eventState.name,
    source = "rpe-event-start",
    authoritative = true,
}
```

Optional `filters.eventId` requires exact match.

## Acceptance criteria

- [ ] One accepted Event start advances matching criteria once.
- [ ] Replayed/duplicate start handling does not double-count the same Event instance.
- [ ] Event UI preview/open does not count.
- [ ] `eventId` filter is respected.
- [ ] Existing Event startup synchronization is unchanged.
- [ ] Existing `rpe_event_complete` behavior is unchanged.

---

# Task 6 — Implement authoritative `rpe_damage` and `rpe_healing`

## Goal

Advance Damage/Healing criteria from actual committed health changes attributed to the authoritative local action owner.

## Primary files

- `client/client_Resources.lua`
- `client/client_Achievements.lua`
- existing Resource/EventUnit helpers used by authoritative kill detection

## Authority

Use the same committed:

```text
RESOURCE_DELTA
RESOURCE_DELTA_BATCH
```

processing boundary already used for `rpe_kill`.

Do not use:

- spell tooltip estimates;
- spell component preview;
- locally predicted effect amounts;
- outbound request values before committed state is received.

## Health delta

Reuse the existing canonical health/death Resource semantics.

For the authoritative health Resource:

```text
actualDamage  = max(0, previousHealth - updatedHealth)
actualHealing = max(0, updatedHealth - previousHealth)
```

This naturally excludes overkill and overheal beyond the committed state transition.

## Ownership/security

Use the same transport-bound action-owner rule already required by `rpe_kill`.

Do not trust a payload actor field unless it matches the authoritative transport/action context.

Only the local player's own Achievements should be progressed for their attributed action.

## Context

```lua
{
    unitRef = "dataset:unit",
    amount = actualAppliedAmount,
    isEnemy = true,
    actionOwnerName = trustedActor,
    authoritative = true,
}
```

## Single/batch parity

Single and batched resource-delta paths must generate equivalent Achievement semantics and must not both count one committed state change.

## Acceptance criteria

- [ ] Committed health loss advances `rpe_damage` by actual loss.
- [ ] Committed health gain advances `rpe_healing` by actual gain.
- [ ] Overkill/overheal do not inflate progress.
- [ ] Non-health Resource changes do not count.
- [ ] Preview/uncommitted effects do not count.
- [ ] Other players' actions do not credit the local Profile.
- [ ] `unitRef` and `enemyOnly` filters work.
- [ ] Single/batch paths do not double-count.
- [ ] Existing `rpe_kill` remains exactly-once alive→dead.

---

# Task 7 — Implement `rpe_boss_kill` Achievement progression

## Goal

Emit a boss-specific kill trigger while preserving ordinary `rpe_kill`.

## Primary files

- `client/client_Resources.lua`
- `client/client_Achievements.lua`
- `core/classes/EventUnit.lua` only if a narrow boss-state accessor is useful

## Boss authority

Use the normalized authoritative EventUnit `boss` state.

Do not infer boss state from:

- name;
- raid marker;
- health quantity;
- Achievement filters.

## Semantics

A boss killed by an authoritative local-player action should emit:

```text
rpe_kill
rpe_boss_kill
```

A non-boss kill emits:

```text
rpe_kill
```

only.

Reuse the existing alive→dead and action-owner security rules.

## Acceptance criteria

- [ ] Boss alive→dead triggers `rpe_boss_kill` once.
- [ ] Boss kill still triggers ordinary `rpe_kill`.
- [ ] Non-boss kill never triggers `rpe_boss_kill`.
- [ ] Already-dead updates cannot repeat either trigger.
- [ ] Boss state comes from EventUnit state.
- [ ] `unitRef` and `enemyOnly` filters work.
- [ ] Transport-bound kill ownership remains intact.

---

# Task 8 — Define structured Achievement Rewards and Dataset schema 17

## Goal

Replace the undefined/opaque-only reward model with a backward-compatible structured schema for Item and Currency rewards while preserving unknown existing reward records.

## Primary files

- `core/classes/Achievement.lua`
- `core/internal/database/Database.lua`
- `core/internal/database/Dependecies.lua`

## Supported reward schema

```lua
{
    id = "reward_1",
    type = "item", -- item | currency
    ref = "dataset:item-or-currency",
    amount = 1,
}
```

## Normalization

For supported reward entries:

- stable, non-empty duplicate-safe `id`;
- `type` is `item` or `currency`;
- trimmed non-empty `ref`;
- positive integer `amount`;
- deterministic order.

## Unknown legacy reward records

Do not silently destroy unknown reward tables/types that already round-trip through the opaque field.

Preserve them as authored data.

The runtime introduced later must not execute unsupported reward types.

## Schema

Increment only Dataset schema:

```text
16 -> 17
```

Use existing monotonic schema behavior; never lower a higher future schema marker.

## Dependencies

Supported reward references:

- Item reward → Item dataset dependency;
- dataset Currency reward → Currency dataset dependency;
- built-in Currency (`copper`, `valor`, `justice`, `honor`, `conquest`) → no dataset dependency.

## Acceptance criteria

- [ ] Existing Achievement definitions load without reward data loss.
- [ ] Supported Item/Currency rewards normalize and round-trip.
- [ ] Reward IDs are stable/duplicate-safe.
- [ ] Unsupported legacy reward records are preserved.
- [ ] Supported reward refs participate in dependency extraction.
- [ ] Built-in currency refs do not create bogus dependencies.
- [ ] Dataset schema becomes 17 without lowering future markers.
- [ ] No reward gameplay mutation occurs in this task.

---

# Task 9 — Add structured Achievement Reward authoring

## Goal

Replace the current read-only Achievement Rewards summary with editing support for supported Item/Currency rewards while preserving unsupported legacy records.

## Primary files

- `client/ui/editor/inspectors/page_InspectorAchievement.lua`
- adjacent Data Editor list/repeater helpers if useful

## UI requirements

Support:

```text
Add Reward
Delete Reward
Reward ID
Reward Type: Item | Currency
Reference
Amount
```

Use current Data Editor primitives.

Reward ID should remain stable under unrelated edits.

## Reference semantics

Item:

```text
datasetId:itemId
```

Currency:

```text
copper
valor
justice
honor
conquest
datasetId:currencyId
```

Follow existing editor behavior for unresolved references; do not invent a new global validation framework.

## Legacy records

Unsupported reward records must be preserved and clearly treated as unsupported/legacy rather than rewritten as a supported type.

## Acceptance criteria

- [ ] Item reward can be authored.
- [ ] Built-in Currency reward can be authored.
- [ ] Dataset Currency reward can be authored.
- [ ] Positive integer amount is normalized.
- [ ] Reward IDs remain stable through unrelated edits.
- [ ] Multiple rewards survive export/import.
- [ ] Unsupported legacy reward records survive.
- [ ] Editing never grants a reward.
- [ ] Existing General/Criteria editor pages remain functional.

---

# Task 10 — Add persistent Achievement reward-delivery state and Profile schema 7

## Goal

Add Profile state required for idempotent reward execution while preserving existing Achievement completion/progress state.

## Primary files

- `core/internal/database/Database.lua`
- `core/internal/profile/Achievements.lua`

## Schema

Increment only Profile schema:

```text
6 -> 7
```

Use monotonic schema behavior.

## Proposed state

Exact field names may follow current conventions, but the persisted state must represent:

```lua
profile.achievements[achievementRef] = {
    criteria = { ... },
    completedAt = 1787481200,

    rewardState = {
        status = "pending",
        startedAt = nil,
        completedAt = nil,
        failedAt = nil,
        reason = nil,
        entries = {
            [rewardId] = {
                status = "applied",
                amount = 1,
            },
        },
    },
}
```

Required status semantics:

```text
pending
in-progress
complete
failed
recovery-required
legacy-skipped
```

## Narrow Profile API

Provide accessors equivalent to:

```lua
Profile.GetAchievementRewardState(achievementRef)
Profile.SetAchievementRewardState(achievementRef, state)
Profile.ClearAchievementRewardState(achievementRef)
```

Do not require callers to mutate raw Profile tables.

## Legacy completion policy

Existing Profile state with:

```text
completedAt exists
rewardState absent
```

must not automatically receive rewards on migration/login.

Treat it as a pre-reward-system completion.

Migration itself must not execute gameplay mutations.

## Acceptance criteria

- [ ] Existing criteria progress/completedAt survive schema migration.
- [ ] Reward delivery state persists across `/reload`/relog.
- [ ] Profile schema becomes 7 without lowering future markers.
- [ ] Existing completed Achievements are not automatically rewarded.
- [ ] Existing incomplete Achievements remain eligible for future normal reward execution after completion.
- [ ] Narrow Profile APIs are available.
- [ ] No Item/Currency reward is executed in this task.

---

# Task 11 — Implement idempotent Achievement Reward execution

## Goal

Execute supported Item/Currency rewards exactly once after a newly completed Achievement, using canonical APIs and persistent transaction state.

## Primary files

- `client/client_Achievements.lua`
- optionally new `client/client_AchievementRewards.lua` if a focused module fits current organization better
- `core/internal/profile/Achievements.lua`
- existing `core/internal/profile/Currencies.lua`
- existing `client/character/inventory/Inventory.lua`
- `RPEngine_Dev.toc` if a new runtime file is introduced

## Completion ordering

Do not rewrite existing Achievement completion semantics.

Required ordering:

```text
criterion progress persisted
        ↓
completedAt persisted
        ↓
existing completion/meta/UI/announcement processing
        ↓
reward transaction state persisted
        ↓
reward mutation
```

Reward failure does not undo Achievement completion.

Reward retry/recovery must not re-announce or re-complete the Achievement.

## Prevalidation

Before first mutation:

- validate all supported reward records;
- resolve every Item;
- resolve every Currency;
- validate positive amounts;
- ensure required canonical APIs exist.

Unsupported preserved legacy reward records must never be executed accidentally.

## Canonical mutations

Item:

```lua
Client.Inventory.AddItem(...)
```

Currency:

```lua
Profile.AddCurrencyAmount(...)
```

Do not write Inventory/Profile currency storage directly.

## Transaction safety

Before mutation:

```text
rewardState.status = in-progress
```

Snapshot sufficient pre-state to verify/rollback supported rewards.

On success:

```text
rewardState.status = complete
```

On failure after mutation begins:

1. roll back any Item quantity added by this transaction;
2. restore affected Currency balances through canonical APIs;
3. verify restored state;
4. persist:
   - `failed` only when pre-transaction state is restored and explicit retry is safe;
   - `recovery-required` when coherent rollback cannot be guaranteed.

If a later load finds `in-progress`, do **not** blindly replay it. Treat it as recovery-required unless the implementation can prove no reward mutation occurred.

## Explicit retry

Provide an explicit runtime operation such as:

```lua
Achievements:RetryRewards(achievementRef)
```

Allow retry only for a complete Achievement in safe `failed` state.

Do not allow blind retry for `recovery-required`.

## Trigger cascades

Because rewards use canonical gain APIs:

- Item reward may progress `item_gain`;
- Currency reward may progress `currency_gain`.

This is intentional.

The source Achievement is already durably complete, so it must not re-complete from its own rewards.

Guild Admin `Achievements:Grant()` must naturally use this same completion/reward path.

## Acceptance criteria

- [ ] Newly completed Achievement executes supported rewards once.
- [ ] Item reward uses `Client.Inventory.AddItem()`.
- [ ] Currency reward uses canonical Profile Currency API.
- [ ] All supported rewards prevalidate before mutation begins.
- [ ] `/reload`, relog, repeated triggers and index rebuild cannot duplicate a completed reward.
- [ ] Full rollback produces a safe `failed` state.
- [ ] Incomplete rollback produces `recovery-required`.
- [ ] `in-progress` found after restart is never blindly replayed.
- [ ] Safe retry does not re-complete/re-announce the Achievement.
- [ ] Guild Admin Grant uses normal reward behavior.
- [ ] Legacy completed Achievements are not retroactively auto-rewarded.
- [ ] Unsupported reward types are never accidentally executed.
- [ ] Reward-generated item/currency gains may progress other Achievements without duplicate source completion.

---

# Task 12 — Extend Profile → Achievements with reward and delivery state

## Goal

Show configured Achievement rewards and their delivery state in the existing Profile Achievements UI without making ordinary viewing mutate state.

## Primary files

- `client/character/profile/page_ProfileAchievements.lua`
- `client/client_Achievements.lua` only for read-only presentation helpers / explicit safe retry

## Display

Show, where present:

- reward type;
- resolved Item/Currency name;
- amount;
- delivery status;
- delivery/failure timestamp where available;
- recovery reason where available.

Suggested user-facing states:

```text
Rewards: Pending
Rewards: Received
Rewards: Delivery failed
Rewards: Recovery required
Rewards: Not retroactively granted (legacy completion)
Rewards: Contains unsupported legacy reward data
```

## Retry UI

If Task 11 implements safe retry, show a `Retry Rewards` action only for a safe `failed` state.

Do not expose blind retry for:

```text
in-progress
recovery-required
```

Ordinary page construction/refresh must not invoke reward delivery.

## Acceptance criteria

- [ ] Supported rewards are visible.
- [ ] Resolved Item/Currency labels display where possible.
- [ ] Pending/complete/failed/recovery/legacy states are distinguishable.
- [ ] Viewing/refreshing does not mutate Achievement/Profile/Inventory/Currency state.
- [ ] Safe retry is offered only for explicitly safe failed state.
- [ ] Recovery-required cannot be blindly retried.
- [ ] Existing tag filtering, progress and completion-date UI remain functional.

---

# Task 13 — Phase 5 integration audit and completion validation

## Goal

Audit Tasks 0–12 as one coherent extension and fix concrete defects only.

Do not redesign already-working Guild/Achievement systems during this task.

## Required audit

### A. Stable Guild identity

Verify:

- old name-keyed Guild state remains accessible;
- new stable Guild identity does not split the current character's state;
- nested assignment/requisition/daily/progression data survives;
- no automatic RPE Guild Rank mutation occurs.

### B. Schema/backward compatibility

Verify:

```text
Dataset schema 16 -> 17
Profile schema 6 -> 7
```

Test:

- existing Achievement definitions;
- existing opaque reward records;
- existing completed Achievement state;
- existing incomplete Achievement state;
- existing Guild state.

Confirm future higher schema markers are not lowered.

### C. Trigger index

Verify indexed support for:

```text
manual
currency_gain
item_gain
skill_gain
rpe_kill
rpe_boss_kill
rpe_damage
rpe_healing
rpe_event_started
rpe_event_complete
achievement_earned
```

Index/configuration rebuild itself must not mutate progress.

### D. `item_gain`

Smoke test:

```text
Inventory.AddItem -> counts
stack merge -> actual quantity once
Requisition item -> counts
Daily Reward item -> counts
Guild Admin Give Item -> counts
Achievement Item reward -> counts
Inventory load -> no count
SetItems -> no count
RemoveItem -> no count
```

### E. `skill_gain`

Smoke test:

```text
positive increase -> actual delta counts
decrease -> no count
same value -> no count
Guild Admin increase -> counts
Guild Admin decrease -> no count
Profile load -> no count
```

### F. Event start

Smoke test:

```text
accepted authoritative event start -> one count
duplicate/replayed start -> no second count
Event Manager/UI preview -> no count
event complete remains separate
```

### G. Damage/healing

Smoke test:

```text
committed health damage -> actual loss
committed heal -> actual restoration
overkill -> capped by actual loss
overheal -> capped by actual restoration
non-health resource -> no count
preview effect -> no count
other actor -> no local credit
single/batch -> no duplicate
```

### H. Boss kill

Smoke test:

```text
boss kill -> rpe_kill + rpe_boss_kill
normal kill -> rpe_kill only
already-dead update -> no repeat
boss=false -> no boss trigger
```

### I. Reward authoring/dependencies

Verify:

- Item reward authoring/export/import;
- built-in Currency reward authoring/export/import;
- dataset Currency reward authoring/export/import;
- unsupported reward preservation;
- dependency extraction;
- built-in currency exclusions.

### J. Reward transaction

Smoke test:

```text
single Item reward
single built-in Currency reward
single dataset Currency reward
multiple mixed rewards
currency cap behavior
Achievement Item reward -> item_gain
Achievement Currency reward -> currency_gain
prevalidation failure -> no mutation
mid-transaction failure + full rollback -> safe failed
rollback failure -> recovery-required
/reload after complete -> no duplicate
/reload with in-progress -> no blind replay
manual safe retry -> no reannouncement
Guild Admin Grant -> normal reward path
legacy completed Achievement -> no automatic reward
```

### K. Profile UI

Verify:

- reward definitions display;
- delivery statuses display;
- ordinary refresh is read-only;
- only safe failed state can retry;
- existing Achievement filtering/progress/completion date remains correct.

### L. Load order and duplicate-system audit

Review `RPEngine_Dev.toc`, Runtime hooks and listeners.

Ensure Phase 5 introduced no:

```text
second Achievement runtime
second Inventory store
second Currency store
second Event authority path
second Guild Admin protocol
new SavedVariable root
preview-state combat credit
automatic Guild Rank behavior
```

## Definition of done

- [ ] Stable Guild identity discrepancy is resolved safely.
- [ ] Six deferred Achievement triggers are implemented and authorable.
- [ ] New gain/combat/event triggers use canonical authoritative committed state.
- [ ] Structured Item/Currency rewards are authorable.
- [ ] Reward delivery is persistent, idempotent and recoverable without blind replay.
- [ ] Existing completions do not receive surprise retroactive rewards.
- [ ] Existing Guild Rank/Requisition/Daily Reward/Admin/Progression behavior remains intact.
- [ ] Dataset/Profile migrations and dependencies remain coherent.
- [ ] No prohibited parallel subsystem was introduced.

---

# 5. Recommended GitHub issue titles

```text
[Phase 5][Task 0] Replace guild-name-only Profile keys with stable Guild identity
[Phase 5][Task 1] Extend Achievement trigger and filter contract
[Phase 5][Task 2] Add Data Editor authoring for Phase 5 Achievement triggers
[Phase 5][Task 3] Implement item_gain Achievement progression
[Phase 5][Task 4] Implement skill_gain Achievement progression
[Phase 5][Task 5] Implement rpe_event_started Achievement progression
[Phase 5][Task 6] Implement authoritative rpe_damage and rpe_healing progression
[Phase 5][Task 7] Implement rpe_boss_kill Achievement progression
[Phase 5][Task 8] Define structured Achievement Rewards and Dataset schema 17
[Phase 5][Task 9] Add structured Achievement Reward authoring
[Phase 5][Task 10] Add Achievement reward-delivery Profile state and schema 7
[Phase 5][Task 11] Implement idempotent Achievement Reward execution
[Phase 5][Task 12] Extend Profile Achievements with reward delivery state
[Phase 5][Task 13] Integration audit and completion validation
```

---

# 6. Dependency order

Recommended linear implementation:

```text
Task 0
  ↓
Task 1
  ↓
Task 2
  ↓
Task 3
  ↓
Task 4
  ↓
Task 5
  ↓
Task 6
  ↓
Task 7
  ↓
Task 8
  ↓
Task 9
  ↓
Task 10
  ↓
Task 11
  ↓
Task 12
  ↓
Task 13
```

The implementation is intentionally linear for Codex review discipline, even where some tasks are technically independent.

---

# 7. Phase 5 non-goals

Do not implement:

```text
Bestiary
Quest Log
CrusadeToolkit quest synchronization
offline Guild Admin
account-wide Achievements
cross-character Achievement aggregation
Native Blizzard Achievements
arbitrary executable Lua criteria/rewards
automatic RPE Guild Rank assignment/remap/clear
RPE Guild Rank hierarchy/inheritance
multiple simultaneous assigned RPE Guild Ranks
new Inventory/Currency persistence
mail/offline reward delivery
combat/resource synchronization redesign
```

These require separate design work.
