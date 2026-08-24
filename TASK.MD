## Goal
Execute supported Item/Currency Achievement rewards exactly once after a newly completed Achievement, using canonical mutation APIs and persistent transaction state.

Depends on: #25, #30, #31, #32

## Primary files
- `client/client_Achievements.lua`
- optionally a focused new `client/client_AchievementRewards.lua` if that fits current organization better
- `core/internal/profile/Achievements.lua`
- existing `core/internal/profile/Currencies.lua`
- existing `client/character/inventory/Inventory.lua`
- `RPEngine_Dev.toc` if a new runtime file is introduced

## Completion ordering
Do not rewrite existing Achievement completion semantics.

Required ordering is conceptually:

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

Reward failure does **not** un-complete the Achievement.

Reward retry/recovery must not re-announce or re-complete the Achievement.

## Prevalidation
Before the first gameplay mutation:
- validate every supported reward record;
- resolve every Item reference;
- resolve every Currency reference;
- validate positive amounts;
- ensure required canonical APIs exist.

Unsupported/legacy reward records preserved by #30 must never be executed accidentally. If supported and unsupported records coexist, expose/report that coherently rather than pretending unsupported records were granted.

## Canonical mutation paths
Item reward:

```lua
Client.Inventory.AddItem(...)
```

Currency reward:

```lua
Profile.AddCurrencyAmount(...)
```

Do not write underlying Inventory/Profile currency tables directly.

Respect existing currency caps and actual applied changes.

## Transaction marker and snapshots
Before applying any supported reward, persist:

```text
rewardState.status = in-progress
```

Snapshot enough pre-transaction Item/Currency state to verify mutations and roll back this transaction only.

Track enough per-reward state for diagnostics/recovery without introducing another persistence root.

## Failure/rollback policy
If a mutation fails after the transaction begins:
1. remove Item quantity awarded by this transaction where possible;
2. restore affected Currency balances through canonical APIs;
3. verify restored state;
4. persist final transaction state.

Use:

```text
failed
```

only when the pre-transaction state has been coherently restored and explicit retry is safe.

Use:

```text
recovery-required
```

when rollback cannot be proven complete/coherent.

If a later addon load finds:

```text
in-progress
```

never blindly replay it. Treat as recovery-required unless the implementation can prove no mutation occurred.

## Explicit retry
Provide an explicit runtime operation such as:

```lua
Achievements:RetryRewards(achievementRef)
```

Allow retry only when:
- Achievement is complete;
- state is safely `failed`;
- it is not `in-progress` or `recovery-required`;
- current reward definitions still prevalidate.

## Trigger cascades
Because rewards use canonical APIs, these cascades are intentional:

```text
Achievement Item reward -> item_gain
Achievement Currency reward -> currency_gain
```

The source Achievement must already be durably complete, so those gains cannot re-complete it.

Guild Admin `Achievements:Grant()` must use the same normal completion/reward path rather than bypassing reward delivery.

## Legacy completion behavior
Achievements completed before this reward system, represented by `completedAt` with no original reward-delivery state, must not receive automatic retroactive rewards on login/index rebuild.

## Constraints
- Do not create another Inventory/Currency store.
- Do not create another Achievement completion path.
- Do not automatically retry unsafe transactions.
- Do not re-announce completed Achievements during retry/recovery.
- Do not implement additional reward types.

## Acceptance criteria
- [ ] Newly completed Achievement executes supported rewards exactly once.
- [ ] Item reward uses `Client.Inventory.AddItem()`.
- [ ] Currency reward uses canonical Profile Currency APIs.
- [ ] All supported rewards prevalidate before mutation begins.
- [ ] `/reload`, relog, repeated trigger dispatch and index rebuild cannot duplicate completed delivery.
- [ ] Full verified rollback produces safe `failed` state.
- [ ] Incomplete/unverifiable rollback produces `recovery-required`.
- [ ] `in-progress` found after restart is never blindly replayed.
- [ ] Safe retry does not re-complete or re-announce the Achievement.
- [ ] Guild Admin Grant follows normal reward behavior.
- [ ] Legacy completed Achievements are not automatically rewarded.
- [ ] Unsupported reward types are never executed accidentally.
- [ ] Reward-generated Item/Currency gains may progress other Achievements without duplicate source completion.

## Coding-agent instructions
Read issues #25 and #30–#32, then inspect the current Achievement completion/Grant path, Profile reward-state APIs, Currency transaction semantics, Inventory AddItem/RemoveItem behavior, and the rollback patterns already used by Guild Requisitions/Daily Rewards before editing. Implement Task 11 only. Persist completion before rewards, persist an in-progress marker before mutation, verify rollback, and prefer a blocked recovery state over any unsafe automatic retry. Do not create parallel storage or completion systems. Review every acceptance criterion and report changed files, validation performed, and deviations.