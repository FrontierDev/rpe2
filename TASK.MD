## Goal
Refactor Achievement runtime processing so one trigger/reward chain produces **one deterministic transaction and one consolidated notification**, rather than per-Achievement persistence/UI/configuration fan-out.

Authoritative documents:

- `.docs/RPE2-Runtime-Performance-Hitch-Elimination-PDD.md`
- `.docs/RPE2-Runtime-Performance-Hitch-Elimination-Implementation-Plan.md`

Depends on: #60

This task owns Achievement trigger/reward batching. Inventory runtime internals are optimized separately; use their existing public APIs inside the outer transaction until that work lands.

## Primary files

- `client/client_Achievements.lua`
- `client/client_AchievementRewards.lua`
- `core/internal/profile/Achievements.lua`
- `core/internal/profile/Currencies.lua`
- runtime transaction/revision module added by #59

Inspect current trigger indexing, `_CommitState`, recursive `achievement_earned` handling, and reward rollback/verification behavior before editing.

## 1. Keep Achievement definition indexing configuration-derived

Preserve the existing criteria-by-trigger indexing concept.

`Achievements:RebuildIndex()` / `EnsureIndex()` may rebuild when activated Achievement definitions genuinely change, but must not rebuild merely because:

```text
criterion progress changed
reward state changed
item gained
currency gained
event started/ended
Achievement completed
```

Use `ConfigurationRevision` or the existing dataset signature only for definition invalidation.

## 2. Batch one trigger evaluation

Refactor `Achievements:ProcessTrigger(...)` so one trigger does conceptually:

```text
read CriteriaByTrigger bucket
-> evaluate matching criteria
-> accumulate changed Achievement states
-> resolve newly completed Achievements
-> resolve achievement_earned dependencies
-> accumulate reward actions
-> persist changed states
-> execute rewards in the same outer Runtime transaction
-> mark AchievementRevision once per logical transaction
-> publish one consolidated Achievement ChangeSet
-> queue presentation/announcements after commit
```

Do not call a broad Profile/UI refresh from `_CommitState()` for every changed Achievement.

It is acceptable to replace `_CommitState()` with narrower helpers if that makes transaction ownership clearer.

## 3. Preserve deterministic recursive Achievement behavior

`achievement_earned` criteria can cause dependent Achievements to progress/complete.

Requirements:

- preserve the current logical order of completion and rewards;
- process dependent Achievement triggers within the same outer transaction;
- avoid re-evaluating already finalized state unnecessarily;
- add a cycle/re-entry guard so malformed definitions cannot recurse indefinitely;
- report/skip cycles through existing debug behavior rather than freezing the client.

Do not change criteria semantics.

## 4. Batch state persistence

Persist all changed Achievement states/reward states through the narrow runtime persistence path introduced by #60.

Requirements:

- no `notifyConfigurationChanged("profile-achievements")` path;
- no per-Achievement Profile-window refresh;
- no definition-index rebuild because progress changed;
- one logical trigger/reward chain should produce one `AchievementRevision` commit even if several Achievement refs changed;
- ChangeSet must contain the affected/completed refs for downstream UI.

If the lower-level persistence API currently bumps a revision on every setter call, adapt transaction-aware revision bumping so the published revision represents the logical transaction rather than N separate visible invalidations.

## 5. Execute rewards inside the outer transaction

Achievement rewards may grant multiple items/currencies.

Keep the existing validation, rollback, verification and unsupported-reward behavior, but ensure supported rewards participate in the current Runtime transaction.

Required outcome:

```text
Achievement completes
-> reward item(s)
-> reward currency(s)
-> downstream item_gain/currency_gain Achievement effects
-> all authoritative changes settle
-> one outer commit
```

Nested calls must not flush UI/listeners/configuration between each reward.

Preserve existing reward-delivery idempotence so a reload/retry does not duplicate already-completed rewards.

## 6. Queue announcements after commit

Guild/Raid achievement broadcasting remains supported.

Do not send an announcement until the Achievement state has successfully committed. Multiple announcements from multiple legitimate completions may still be sent, but their dispatch must not sit inside low-level persistence setters or force UI refresh between rewards.

## 7. Narrow UI invalidation

Mark only the Achievement/Profile surfaces that need updating.

At this stage it is sufficient to emit the proper ChangeSet/revision data; later Profile UI work will consume it efficiently.

Do not call `ProfileWindow:Refresh()` broadly from Achievement internals.

## Acceptance criteria

- [ ] `ProcessTrigger` batches all state changes for one trigger in one outer transaction.
- [ ] Multiple changed Achievements do not cause multiple global/Profile refreshes.
- [ ] `achievement_earned` dependencies resolve deterministically inside the same transaction.
- [ ] A cycle/re-entry guard prevents infinite recursive Achievement chains.
- [ ] Reward items/currencies execute inside the outer Achievement transaction.
- [ ] Achievement reward idempotence/rollback behavior remains intact.
- [ ] Achievement progress/reward persistence never reaches global configuration refresh.
- [ ] `AchievementRevision` is published once per logical trigger/reward chain.
- [ ] ChangeSet identifies affected and newly completed Achievement refs.
- [ ] Achievement broadcasts happen only after successful commit.

## Validation matrix

```text
currency gain advances no Achievement
-> no Achievement state write

currency gain advances one criterion
-> one Achievement state transaction
-> one Achievement revision publish

one trigger advances 3 Achievements
-> all three persisted correctly
-> one outer commit
-> no per-Achievement Profile refresh

Achievement A completes -> achievement_earned progresses B
-> A then B resolve deterministically
-> both state changes in same transaction

Achievement reward = 2 items + 2 currencies
-> all rewards delivered exactly once
-> no global configuration refresh between rewards

reward currency completes dependent Achievement
-> dependent completion is processed in the same outer chain

malformed A -> B -> A dependency
-> cycle is detected/guarded
-> client does not freeze
-> debug output identifies the cycle

announcement enabled
-> message is sent only after successful completion commit
```

## Constraints

- Do not change Achievement criteria definitions or completion semantics.
- Do not redesign Inventory storage here.
- Do not remove existing reward verification/rollback safeguards merely for speed.
- Do not make broadcasts part of low-level persistence.
- Do not rebuild Achievement indexes after progress changes.
- Do not introduce asynchronous ordering that changes authoritative results.

## Coding-agent instructions
Use current `FrontierDev/rpe2` as authoritative. This task is intended for **5.6-Luna-ExtraHigh**. Read both runtime-performance documents and completed #60. Trace `ProcessTrigger`, `_CommitState`, `achievement_earned`, reward delivery, and item/currency trigger recursion end-to-end before editing. Preserve exact criteria/reward semantics while changing notification/commit ownership. Report the new trigger transaction flow, cycle guard, reward-chain behavior, files changed, and validation results.