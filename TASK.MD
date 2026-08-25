## Validation result: revision required

The core Task 1 implementation is structurally correct, but there is one blocking backward-compatibility defect in the reset-cycle key transition. Do not close #38 yet.

### What passes

Static inspection of commit `04101931299bda2b0c7c6b53343491b316993a0f` confirms:

- `PLAYER_ENTERING_WORLD`, `PLAYER_GUILD_UPDATE`, and `GUILD_ROSTER_UPDATE` no longer call `ProcessDailyRewards()` automatically;
- those runtime events still re-evaluate assigned Guild Rank state and refresh the Guild window;
- `Guild:TryClaimDailyReward()` delegates to the existing `ProcessDailyRewards()` transaction instead of duplicating award logic;
- existing transaction markers, award verification, rollback, claim persistence, duplicate protection, and refresh behavior remain in the central transaction path;
- `Guild:GetDailyRewardResetState()` is the single new source of `secondsRemaining` and `cycleKey`;
- missing/invalid `C_DateAndTime.GetSecondsUntilDailyReset()` cleanly returns `calendar-unavailable` rather than falling back to local midnight;
- no Profile schema/root change was introduced;
- #36's configuration-refresh coalescing code was not modified by this task.

### Blocking defect: existing claims can become claimable again after upgrading

Before #38, a successful Daily Reward stored:

```text
dailyRewardDate = date("%Y-%m-%d", claimTime)
```

The new code stores/compares:

```text
cycleKey = date("%Y-%m-%d", nextResetTimestamp)
```

Those two `YYYY-MM-DD` strings have the same storage shape but **different semantics**.

Example with a 10:00 local daily reset:

```text
Old client claims at 11:00 on Aug 25
-> stored dailyRewardDate = 2026-08-25

Upgrade to #38 at 11:05 on Aug 25
-> next reset is Aug 26 10:00
-> new cycleKey = 2026-08-26

2026-08-25 ~= 2026-08-26
-> GetDailyRewardStatus() reports available-today
-> the same reset-cycle reward can be claimed a second time
```

This violates the requirement to preserve duplicate-claim protection and means the existing `YYYY-MM-DD` claim persistence is not semantically backward-compatible even though it still passes the Profile date validator.

### Required revision

Add an explicit one-time compatibility path for pre-#38 Daily Reward claims so an already-claimed **current reset cycle** cannot become claimable simply because the meaning of `dailyRewardDate` changed.

The implementation should:

1. distinguish legacy calendar-day claim semantics from the new reset-cycle semantics;
2. on first use after upgrade, determine conservatively whether the legacy claim belongs to the current reset cycle;
3. if it does, migrate/translate it to the current reset `cycleKey` before returning `available-today`;
4. persist enough state to know that this claim/bucket now uses reset-cycle semantics, so later cycles are compared only against the new key and are not accidentally blocked by legacy compatibility logic;
5. keep the existing `YYYY-MM-DD` claim value format if practical and avoid a Profile schema bump/new SavedVariable root unless repository inspection shows that is genuinely necessary.

A narrow version/semantics marker inside the existing per-guild Profile bucket is acceptable if the current Profile normalization/preservation rules support it. Do not solve this by permanently accepting both `current calendar date` and `cycleKey` on every future comparison: after a new-format claim, that can block the next reset cycle because yesterday's `cycleKey` may equal today's calendar date.

### Re-validation matrix

After revision, verify at minimum:

```text
legacy claim after previous reset, upgrade before next reset
-> remains claimed; no duplicate

legacy claim before today's reset, upgrade before that reset
-> remains claimed for the current cycle

legacy claim from an older cycle
-> current cycle remains available

new-format claim
-> remains claimed through reload/relog until reset

next reset
-> becomes available exactly once

subsequent new-format cycles
-> legacy compatibility path no longer causes false blocking
```

Also test the reset boundary around:

```text
secondsRemaining = 1
secondsRemaining = 0 (if the Blizzard API can expose it)
first value after reset
```

and confirm `cycleKey` changes coherently with the timer boundary.

Everything else in #38 is consistent with the issue from static source inspection. The legacy-claim transition is the remaining blocker.