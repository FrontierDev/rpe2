## Rev 5 static validation: FAIL — nested resolver stale signal is swallowed by Profile wrapper

Validated commit `961e04c04c993e5d95ca3fdc66bd51488ce8f16e` (`Issue #65 rev 5`) against #65 and the existing runtime-performance contract. `TASK.MD` is intentionally ignored.

### What rev 5 fixes correctly

Rev 5 addresses the rev-4 cold aura aggregation blocker:

- local-player aura stat modifiers now have a continuation-owned aggregate path;
- aura/effect-key traversal is incremental and checks the supplied deadline;
- the aggregate is published to the shared bucket cache only after completion and after a final current/stale check;
- resolved stat completion now reads `context.auraModifiersByStat[statRef]` in O(1) instead of calling the cold `BuildStatModifierTotals(...)` path per stat;
- the previous explicit derived-stat dependency stack, incremental item/equipment preparation, TaskQueue slicing, event-start continuations, and outbound aura batching remain intact.

No configured commit-status checks are present.

### Blocking defect: `Profile.StepResolvedStateContinuation()` loses `nil, reason` from the Resolver

The new resolver path correctly treats a nested aura-modifier continuation becoming stale as a terminal stale result:

```lua
local completed, reason = auraContext.auraManager:StepStatModifierTotalsContinuation(
    auraContinuation,
    deadlineMs
)
if completed == nil then
    return nil, reason or "aura-stale"
end
```

However `core/internal/profile/Profile.lua` currently wraps the resolver like this:

```lua
local completed = Resolver.StepResolvedStateContinuation(
    continuation.resolverContinuation,
    deadlineMs
) == true
if not completed then
    return false
end
```

That boolean coercion discards the resolver's terminal stale signal. `nil, "aura-stale"` becomes ordinary `false`.

The outer local-player derived-state continuation explicitly depends on `Profile.StepResolvedStateContinuation(...)` preserving `nil, reason`:

```lua
local completed, reason = Profile.StepResolvedStateContinuation(...)
if completed == nil then
    return nil, reason or "profile-stale"
end
if completed ~= true then
    return false
end
```

So the newly added nested stale contract is broken at the Profile layer. Instead of aborting/discarding stale work, the parent can treat the stale resolver as merely incomplete and attempt to resume it again. This violates #65's requirements that stale event/config/runtime work be rejected safely and that cancelled/stale continuation state not be allowed to continue toward publication.

## Required fix

Preserve the Resolver's tri-state result in `Profile.StepResolvedStateContinuation()` instead of coercing it immediately to boolean. For example:

```lua
local completed, reason = Resolver.StepResolvedStateContinuation(
    continuation.resolverContinuation,
    deadlineMs
)
if completed == nil then
    return nil, reason or "resolver-stale"
end
if completed ~= true then
    return false
end
```

Then continue the existing successful-completion path unchanged.

Do not convert terminal/stale resolver results to ordinary incomplete results. The outer `AuraManager:StepLocalPlayerDerivedStateContinuation()` already has the correct tri-state handling and should receive the propagated reason.

After this fix, re-run static validation. If no additional blocker appears, #65 should proceed to the mandatory in-game high-content event/startup gate with timings enabled, including a stale/cancel restart check.

#65 remains open.