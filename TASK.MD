## Goal
Add backward-compatible persistent Profile state required for idempotent Achievement reward delivery without changing existing Achievement completion semantics.

Depends on: #30

## Primary files
- `core/internal/database/Database.lua`
- `core/internal/profile/Achievements.lua`

## Profile schema
Increment only:

```text
Profile schema 6 -> 7
```

Follow the existing monotonic schema pattern. Do not lower any future higher marker.

## Persisted reward-delivery state
Exact field names may follow current Profile conventions, but each Achievement state must be able to persist reward-delivery status conceptually equivalent to:

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

Preserve unknown/future reward-state fields where practical rather than destructively constraining nested tables.

## Narrow Profile API
Provide thin persistence helpers equivalent to:

```lua
Profile.GetAchievementRewardState(achievementRef)
Profile.SetAchievementRewardState(achievementRef, state)
Profile.ClearAchievementRewardState(achievementRef)
```

Use current Database/Profile copy semantics and mutation notification conventions. Callers should not need to edit raw `profile.achievements` tables directly.

## Legacy completion policy
This is critical:

```text
completedAt exists
rewardState absent
```

means the Achievement predates the Phase 5 reward-delivery runtime.

Migration/login must **not** automatically grant rewards to those already-completed Achievements.

Representing that state as `legacy-skipped` is acceptable, but schema normalization itself must not perform gameplay mutations.

Existing incomplete Achievements remain ordinary incomplete states and can receive normal rewards if they complete after the reward runtime is introduced.

## Constraints
- Do not execute Item/Currency rewards.
- Do not change existing criterion progress semantics.
- Do not re-announce completed Achievements.
- Do not introduce another SavedVariable root.
- Do not modify Guild state/schema.

## Acceptance criteria
- [ ] Existing Achievement criterion progress survives schema migration.
- [ ] Existing `completedAt` survives unchanged.
- [ ] Reward-delivery state persists through `/reload` and relog.
- [ ] Profile schema becomes 7 without lowering future markers.
- [ ] Existing completed Achievements are not automatically rewarded by migration/login.
- [ ] Existing incomplete Achievements remain eligible for future normal reward delivery after completion.
- [ ] Thin Profile reward-state APIs are available.
- [ ] No Item/Currency reward is executed in this task.

## Coding-agent instructions
Read issue #30 and inspect current Achievement Profile normalization/default-state/accessor patterns throughout `Database.lua` and `core/internal/profile/Achievements.lua` before editing. Implement Task 10 only. Preserve criteria/completedAt exactly, make reward state durable through existing Profile persistence, and enforce the no-retroactive-reward migration policy without performing gameplay mutations. Review every acceptance criterion and report changed files, validation performed, and deviations.