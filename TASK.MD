## Goal
Convert Guild Daily Rewards from automatic runtime processing to explicit player click-to-claim behavior, and make both claim eligibility and the visible countdown use the same Blizzard daily-reset boundary.

Authoritative plan: `.docs/RPE2-Final-Guild-Requisitions-Page-Implementation-Plan.md`.

Depends on: #37

The existing Daily Reward transaction/rollback implementation remains authoritative. This task changes **when a claim is initiated** and **how the daily cycle is keyed**, not how rewards are awarded.

## Primary files
- `client/client_Guild.lua`
- `core/internal/profile/Guild.lua` only if a narrow compatibility adjustment is actually required after inspection

## Stop automatic claiming
The current runtime calls Daily Reward processing from Guild runtime events.

Change `Guild:HandleRuntimeEvent(...)` so:

```text
PLAYER_ENTERING_WORLD
PLAYER_GUILD_UPDATE
GUILD_ROSTER_UPDATE
```

continue to refresh/re-evaluate Guild state and visible Guild UI, but do **not** automatically award Daily Rewards.

Do not move award logic into event handlers elsewhere.

## Public manual-claim operation
Retain the existing transactional implementation as the single award path.

Expose a clear page-facing method such as:

```lua
function Guild:TryClaimDailyReward()
    return self:ProcessDailyRewards()
end
```

If the current public API already provides an equally clear callable claim operation after inspection, reuse it rather than introducing a redundant alias.

A manual claim must preserve the existing:

- eligibility checks;
- transaction marker persistence;
- item/currency prevalidation;
- award verification;
- rollback behavior;
- claim persistence;
- duplicate-claim protection;
- window/configuration refresh behavior.

## Daily reset helper
Replace the current calendar-day-only claim boundary with one centralized Guild helper based on Blizzard's daily reset timing.

Use the target-client API when available:

```lua
C_DateAndTime.GetSecondsUntilDailyReset()
```

Create one helper conceptually equivalent to:

```lua
Guild:GetDailyRewardResetState()
-- {
--     secondsRemaining = ...,
--     cycleKey = "YYYY-MM-DD",
-- }
```

The helper must be the source for both:

1. the runtime Daily Reward claim cycle key;
2. the later UI countdown.

## Cycle-key compatibility
The current Profile daily-claim field accepts a `YYYY-MM-DD` date key. Preserve that storage shape if practical; do not introduce a Profile schema change just to represent reset cycles.

A suitable contract is to derive the key from the **next reset timestamp**:

```lua
local now = Common.GetNow()
local secondsRemaining = C_DateAndTime.GetSecondsUntilDailyReset()
local nextResetTimestamp = now + secondsRemaining
local cycleKey = date("%Y-%m-%d", nextResetTimestamp)
```

Inspect edge behavior around an exact reset before finalizing; the essential requirement is that the key changes at the same reset boundary represented by `secondsRemaining`.

## Daily Reward status
Update `Guild:GetDailyRewardStatus()` / its internal helper so the current claim comparison uses the centralized reset-cycle key rather than a separate `date("%Y-%m-%d", now)` calculation.

Return/reset-state information where useful so the page can consume it without recreating reset calculations independently.

If the Blizzard reset API is unavailable, fail cleanly with an unavailable/calendar-style status. Do not silently use a different time boundary for claims than the future UI timer.

## Existing hotfix behavior
Issue #36 already changed Profile configuration refresh scheduling. Preserve that coalesced/deferred behavior. Do not reintroduce synchronous full-refresh-per-write behavior while modifying the Daily Reward call path.

## Constraints
- Do not implement the Daily Reward ImageButton/UI in this task.
- Do not duplicate the award/rollback transaction.
- Do not alter configured Daily Reward schema.
- Do not add a new SavedVariable/Profile root.
- Do not alter Requisition transaction semantics.
- Do not change Guild Rank assignment semantics.
- Do not use local midnight as a second fallback claim boundary if the displayed timer would use Blizzard reset time.

## Acceptance criteria
- [ ] Login/world-entry no longer automatically grants an available Daily Reward.
- [ ] Guild update/roster events no longer automatically grant Daily Rewards.
- [ ] Runtime Guild events still refresh Guild state/UI as before.
- [ ] A public manual claim operation reaches the existing authoritative Daily Reward transaction.
- [ ] Manual claim preserves existing validation, transaction markers, rollback and duplicate protection.
- [ ] One centralized helper provides reset seconds and claim cycle key.
- [ ] Daily Reward eligibility uses that reset-cycle key.
- [ ] The cycle key changes at the same Blizzard daily reset boundary represented by the helper countdown.
- [ ] Existing `YYYY-MM-DD` claim persistence remains compatible without a Profile schema bump, unless repository inspection proves that impossible.
- [ ] Missing reset API fails cleanly rather than silently mixing reset semantics.
- [ ] Issue #36 refresh coalescing behavior remains intact.

## Coding-agent instructions
Read `.docs/RPE2-Final-Guild-Requisitions-Page-Implementation-Plan.md`, issue #36, and completed Task 0 (#37). Inspect the current Daily Reward status builder, `ProcessDailyRewards()`, `HandleRuntimeEvent()`, `Common.GetNow()`, Profile Daily Reward claim normalization/accessors, and target Blizzard reset API usage before editing. Implement Task 1 only. Keep one Daily Reward transaction and one reset-boundary helper. Review every acceptance criterion and report changed files, validation performed, and any deviation.