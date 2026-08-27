## Rev 6 in-game validation: FAIL — `aura-derived-state` stale check passes a multi-return into `tonumber`

Validated commit `22725f82aa10c8b044a30d2ac7dfc6d2afcacb80` (`Issue #65 rev 6`). `TASK.MD` is intentionally ignored.

In-game failure when applying an aura that modifies player stats:

```text
Task queue sliceable stale check failed for 'aura-derived-state':
.../client/spellcasting/AuraManager.lua:1545: bad argument #2 to '?' (number expected, got table)
```

### Root cause

`resolveLocalEventId(eventState)` returns two values:

```lua
return tonumber(localUnit and localUnit.eventID) or 0, localUnit
```

But the `aura-derived-state` stale check currently does:

```lua
or tonumber(resolveLocalEventId(currentEventState)) ~= tonumber(state and state.localEventId)
```

In Lua, because `resolveLocalEventId(currentEventState)` is the sole argument expression to `tonumber`, **both** return values are forwarded. The call therefore becomes effectively:

```lua
tonumber(numericEventId, localUnitTable)
```

The second argument to `tonumber` is its optional numeric base, so passing the local-unit table produces exactly the observed error: `bad argument #2 ... (number expected, got table)`.

The TaskQueue catches this as a stale-check error, so the derived-state job is cancelled instead of refreshing the stat-modifying aura state.

### Required fix

Capture only the first return value before comparing it. Prefer the explicit local form:

```lua
isStale = function(state)
    local targetClient = state and state.client or nil
    local currentEventState = type(targetClient) == "table" and type(targetClient.GetEventState) == "function"
        and targetClient:GetEventState()
        or nil
    local currentLocalEventId = currentEventState and resolveLocalEventId(currentEventState) or 0

    return type(currentEventState) ~= "table"
        or currentEventState.active ~= true
        or tostring(currentEventState.id or "") ~= tostring(state and state.eventId or "")
        or tonumber(currentLocalEventId) ~= tonumber(state and state.localEventId)
        or (type(Profile.IsResolvedStateContinuationCurrent) == "function"
            and Profile.IsResolvedStateContinuationCurrent(state and state.continuation and state.continuation.profileContinuation) ~= true)
end
```

Alternatively, `(resolveLocalEventId(currentEventState))` can force a single return value, but the named local is clearer and less error-prone.

Also audit this file/repo for any other calls that pass a multi-return helper directly into `tonumber(...)` or another function with optional trailing arguments. Code search currently finds this `tonumber(resolveLocalEventId(...))` occurrence as the relevant one.

### Revalidation

After the fix:

1. `/reload` with no Lua errors.
2. Enable timings and enter an event.
3. Apply/remove a stat-modifying aura to the local player.
4. Confirm no `aura-derived-state` stale-check error, stats/resources update correctly, and the derived-state job completes.
5. Re-run the remaining #65 gate: bounded slice timings and stale event restart/cancellation without stale publication.

#65 remains open.