## Context

Depends on #333.

This is the final implementation chunk split out of superseded #331.

After #333, authoritative damage should already contain the simple contract:

```lua
result.preAbsorbAmount
result.absorbedAmount
result.amount -- post-absorb health damage
```

This issue is limited to making sure that `result.amount` is actually applied to health correctly, invalid states do not masquerade as full absorption, and INTERNAL diagnostics expose the live values needed for in-game verification.

## Goal

If authoritative damage resolves to:

```text
preAbsorbAmount = 200
absorbedAmount = 65
amount = 135
```

the normal health resource path must queue/apply exactly `-135` health damage.

A genuinely fully absorbed hit is only:

```text
amount = 0
```

## Required changes

### 1. Remove the silent invalid-state fallback in `ApplyResolvedDamage()`

Current logic effectively conflates:

```text
finalDamage == 0
```

with:

```text
finalDamage > 0 but healthResourceRef == nil
```

because health application is gated by both conditions and the fallback branch treats the result as an absorbed landed hit.

That must be removed.

Required structure:

```lua
if finalDamage > 0 then
    if not healthResourceRef then
        Debug.Error(...)
        result.applied = false
        result.appliedDelta = 0
        return false, result
    end

    -- Build the ordinary health resource delta from -finalDamage.
else
    -- This is the only fully absorbed/no-health-delta path.
    result.applied = true
    result.appliedDelta = 0
end
```

Do not add another fallback that silently converts missing/invalid health state into success.

### 2. Preserve the normal resource-delta path

For `result.amount > 0`, use the existing health-resource lookup and existing `PreviewResourceDelta()` / resource-delta queue path.

Do not create a new absorption-specific health transport.

The absorption mechanic should end before resource application. From this point onward, `result.amount` is ordinary health damage.

Expected example:

```text
result.amount = 135
PreviewResourceDelta(..., -135)
result.appliedDelta = -135
result.resourceDeltas[1].delta = -135
```

### 3. Audit `FinalizeLocalDamageResult()` handoff

Trace the authoritative result from `ApplyResolvedDamage()` through `FinalizeLocalDamageResult()` into `QueueClientResourceDeltas()`.

Confirm that:

- partial absorption does not suppress a non-empty health delta;
- fully absorbed hits may have no health delta but can still retain absorption presentation;
- the existing resource queue receives the post-absorb remainder unchanged;
- no coalescing or presentation branch overwrites `result.amount` or `result.appliedDelta`.

Only change code where a concrete problem is found. Do not redesign resource synchronization.

### 4. Add a real INTERNAL debug line

#327 added transient `absorptionDiagnostics` fields but did not emit them.

Add an actual INTERNAL diagnostic from the authoritative damage path after absorption has been consumed and the health delta has been built.

It should contain at least:

```text
target event id
pre-absorb/post-mitigation damage
live absorption consumed
post-absorb remainder
health resource ref
health delta
```

Example:

```text
Absorption resolve: target=4 preAbsorb=200 absorbed=65 remainder=135 healthRef=f82db71a:... healthDelta=-135
```

If useful, also include the live source capacities consumed, but keep the line concise enough to use during an event.

If `result.amount > 0` and the health ref cannot be resolved, emit an ERROR/INTERNAL diagnostic that makes that failure explicit.

### 5. Keep combat presentation compatible

Do not redesign the combat log/ticker in this issue.

Ensure the existing presentation receives the authoritative fields from #333:

```lua
result.amount
result.absorbedAmount
```

so partial absorption can present equivalent to:

```text
135 Physical damage (Absorbed 65)
```

and a full absorb can still present 0 health damage with the absorbed amount.

## Scope

Primary files to inspect:

- `client/combat/effects/Damage.lua`
- `client/combat/Reaction.lua`
- `client/client_Resources.lua` only to trace/repair an actual post-absorb resource-delta handoff problem
- `client/combat/Helpers.lua` only if required for the existing presentation fields

Do not modify AuraManager consumption logic from #332 unless a direct integration defect is discovered.

## Manual verification criteria

There is no executable automated test harness. Do not add regression-test files.

In-game verification should cover:

- 200 post-mitigation damage + 65 absorb -> shield loses 65 and health loses 135;
- INTERNAL output shows `preAbsorb≈200`, `absorbed=65`, `remainder≈135`, `healthDelta≈-135`;
- 50 damage + 65 absorb -> health delta 0, shield retains 15;
- no shield -> ordinary damage behaviour unchanged;
- missing/invalid health ref with non-zero remainder produces an explicit failure diagnostic rather than appearing as a full absorb;
- partial absorption still reaches the ordinary RESOURCE_DELTA path.

## Completion requirements

Before closing:

- trace the full authoritative handoff through `FinalizeLocalDamageResult()` and `QueueClientResourceDeltas()`;
- identify every modified API/call site and review for regressions;
- review the resulting diff for unrelated changes;
- verify the diagnostic is an actual `Debug.Internal(...)`/appropriate error call, not just a stored table field;
- do not claim automated tests were run.