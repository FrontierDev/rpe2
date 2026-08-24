## Goal
Fix the immediate runtime crash where assigning an RPE Guild Rank causes multiple expensive full local-configuration rebuilds in sequence, eventually hitting WoW's `script ran too long` watchdog.

This is a **hotfix** and should be addressed before continuing Phase 5 feature work.

## Observed failure
Assigning a player's RPE Guild Rank produces repeated internal traces such as:

```text
Session: HandleLocalConfigurationChanged reason=profile-guild took=6634.75ms
Session: HandleLocalConfigurationChanged reason=profile-currency took=6785.50ms
Session: HandleLocalConfigurationChanged reason=profile-guild took=6859.78ms
Session: HandleLocalConfigurationChanged reason=profile-guild took=6922.93ms
...
Database.lua:57: script ran too long
```

The watchdog location in `Database.lua` is incidental; line 56/57 is near the generic table-normalization helpers. The real problem is the repeated synchronous full refreshes consuming many seconds of Lua execution.

## Root cause identified from current code
`core/internal/database/Database.lua` uses:

```lua
local function notifyConfigurationChanged(reason)
    markConfigurationChanged()
    local client = Addon.Client or nil
    if client and type(client.TryDeferLocalConfigurationChanged) == "function"
        and client:TryDeferLocalConfigurationChanged(reason) then
        return
    end
    if client and type(client.HandleLocalConfigurationChanged) == "function" then
        client:HandleLocalConfigurationChanged(reason)
    end
end
```

Therefore every Profile mutation synchronously executes the entire:

```lua
Client:HandleLocalConfigurationChanged(reason)
```

path.

That handler performs expensive global work including recipe/bootstrap rebuilds, trait/profile refresh, Inventory/Profile UI refresh, Action Bar rebuild/refresh, possible resource sync and client-connect refresh.

`client/client_Session.lua` already has a coalescing API:

```lua
Client:QueueLocalConfigurationRefresh(reason)
```

using:

```lua
Client.LocalConfigurationRefreshQueued
Client.PendingLocalConfigurationRefreshReason
```

but `Database.notifyConfigurationChanged()` bypasses it and calls `HandleLocalConfigurationChanged()` directly.

## Why Guild Rank assignment exposes the bug
The receiver-side `set_guild_rank` path calls:

```lua
Profile.SetAssignedGuildRank(...)
```

which persists through `Profile.SetGuildState()` / `Database.SetProfileGuildState()` and emits:

```text
profile-guild
```

A valid newly assigned rank can then participate in automatic Daily Reward processing. A single Daily Reward transaction can generate several additional Profile mutations:

```text
SetDailyRewardTransaction("in-progress") -> profile-guild
AddCurrencyAmount(...)                  -> profile-currency
SetDailyRewardClaim(...)                -> profile-guild
ClearDailyRewardTransaction(...)        -> profile-guild
```

Each currently causes a separate synchronous full `HandleLocalConfigurationChanged()` call. With the observed ~6.5–7 s per refresh, one logical operation can spend tens of seconds rebuilding the same derived state before WoW aborts execution.

## Required fix
Use the existing queued/coalesced refresh path for runtime Profile mutations instead of synchronously rebuilding the entire local configuration for every write.

### Preferred minimal approach
After preserving the existing Data Editor deferral behavior, `notifyConfigurationChanged()` should route Profile-originated notifications through:

```lua
Client:QueueLocalConfigurationRefresh(reason)
```

when available, falling back safely only when the queue API is unavailable.

At minimum, reasons beginning with:

```text
profile-
```

must not directly execute `HandleLocalConfigurationChanged()` synchronously one time per mutation.

Inspect whether routing **all** normal Database configuration notifications through the queue is semantically safe; do not broaden the change blindly if editor/dataset operations rely on different timing.

### Coalescing requirement
Back-to-back Profile writes in one transaction/tick must collapse into one deferred local-configuration refresh rather than N complete rebuilds.

Persistence itself remains synchronous: a setter must still have written its Profile state before returning. Only the expensive derived-state/UI/session rebuild should be deferred/coalesced.

## Re-entrancy protection
Inspect `HandleLocalConfigurationChanged()` and all functions it invokes for Profile setters/notifications.

The final design must prevent a refresh already in progress from recursively causing another immediate full refresh. If necessary, add a narrow `LocalConfigurationRefreshInProgress`/equivalent guard in addition to queue coalescing, but do not create a second refresh system.

## Preserve transaction behavior
Do **not** change the semantics of:

- Guild Rank assignment/validation;
- Daily Reward claim uniqueness;
- Daily Reward transaction markers;
- currency caps;
- Requisition transactions;
- Achievement completion;
- Guild Admin acknowledgement.

The bug is notification/refresh scheduling, not Guild Rank eligibility or Daily Reward business logic.

## Primary files

- `core/internal/database/Database.lua`
- `client/client_Session.lua`
- `client/client_Guild.lua` only for validation/instrumentation if required
- `core/internal/Runtime.lua` only if necessary to verify scheduling; avoid unrelated event changes

## Required validation
Reproduce/inspect these cases after the fix:

### Guild Rank assignment
```text
set_guild_rank
-> Profile state persists
-> no repeated synchronous full configuration rebuilds
-> target acknowledgement still succeeds
```

### Rank assignment with an available Daily Reward
For a reward containing at least one Currency:

```text
rank assignment
daily transaction marker
currency award
claim persistence
marker cleanup
```

must complete without one full rebuild per mutation.

Expected behavior: the writes are persisted normally and their derived refresh work is coalesced.

### Multiple Profile mutations in one call stack
Exercise at least:

```text
profile-guild
profile-currency
profile-achievement
profile-skill
```

where practical and confirm queued refresh state prevents repeated immediate rebuilds.

### Existing editor/configuration behavior
Verify Dataset/Data Editor changes still refresh correctly and existing `TryDeferLocalConfigurationChanged()` behavior has not been broken.

## Acceptance criteria

- [ ] Assigning an RPE Guild Rank no longer causes multiple synchronous `HandleLocalConfigurationChanged()` executions.
- [ ] A Daily Reward transaction with several Profile writes does not run a full configuration rebuild once per write.
- [ ] Back-to-back Profile notifications coalesce through the existing local-configuration refresh queue (or an equally narrow existing mechanism).
- [ ] Profile persistence remains synchronous and correct before setter return.
- [ ] No `script ran too long` occurs from the reproduced Guild Rank/Daily Reward flow.
- [ ] No immediate refresh recursion/re-entry remains possible.
- [ ] Daily Reward transaction/rollback/claim semantics are unchanged.
- [ ] Guild Rank assignment acknowledgement still succeeds.
- [ ] Data Editor configuration refresh/defer behavior remains functional.
- [ ] No second notification/refresh subsystem is introduced.

## Coding-agent instructions
Read this issue, inspect the current `Database.notifyConfigurationChanged`, `Client:QueueLocalConfigurationRefresh`, `Client:HandleLocalConfigurationChanged`, Profile Guild/Currency setters, and Daily Reward transaction path before editing. Treat the repository as authoritative. Fix this hotfix only; do not begin Phase 5 tasks. Prefer the smallest scheduling/coalescing change that removes repeated synchronous full rebuilds while preserving persistence and editor semantics. Report the exact call chain found, changed files, before/after refresh behavior, validation performed, and any remaining expensive single-refresh path.