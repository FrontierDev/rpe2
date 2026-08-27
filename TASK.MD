## Rev 3 static validation: FAIL — rev-2 Profile.lua login blocker is unchanged

Validated commit `2678b71f8e3a2836d127f7d0ac325ca474c11714` (`Issue #64 rev 3`) against #64 and the previous rev-2 static/runtime failure. `TASK.MD` is intentionally ignored per user instruction.

### Rev 3 changes reviewed

Rev 3 changes only `core/internal/database/Database.lua` relative to rev 2. Those changes are reasonable:

- `runProfileRuntimeMutation()` now allows a mutation closure to return `changed=false`, avoiding false Runtime revision/ChangeSet publication for no-op equipment operations;
- equipment set/clear bucket lookup and mutation now happen inside the Runtime transaction;
- failed pet-bucket lookup / clear of an already-empty slot can return without marking `profile.equipment` changed.

These changes improve transaction correctness but do not address the blocker that prevented rev 2 from loading cleanly.

### Blocking defect remains unchanged

`core/internal/profile/Profile.lua` is unchanged from rev 2. It still defines:

```lua
local function canUseDefaultResolvedResourceCache(options)
    return canUseDefaultResolvedStatCache(options)
end

local function canUseDefaultResolvedStatCache(options)
    ...
end
```

In Lua, because `canUseDefaultResolvedStatCache` has not been locally declared at the point the first function is defined, that reference resolves to the global name rather than the later local function. The global is nil.

This is the same defect already observed in-game as:

```text
Profile.lua:576: attempt to call a nil value
```

and it is reachable from the login/bootstrap warm path through `getCachedResolvedResourceLookup(nil)`.

### Required fix

Fix the local declaration ordering in `Profile.lua`. The minimal correct solution is either:

```lua
local function canUseDefaultResolvedStatCache(options)
    ...
end

local function canUseDefaultResolvedResourceCache(options)
    return canUseDefaultResolvedStatCache(options)
end
```

or explicitly forward-declare `canUseDefaultResolvedStatCache` and assign it before the resource helper can execute.

Do not work around this with a global function.

### Re-validation after fix

1. `/reload` / login with no `Profile.lua:576` error.
2. Static review that the rev-2 Runtime equipment path and one-stat-resolution presentation snapshot remain intact.
3. Then run the existing #64 in-game performance gate: first Profile open, unchanged reopen, equip/unequip with Profile hidden (no `HandleLocalConfigurationChanged [profile-*-equipment]`), targeted visible Equipment/Traits updates, and no Profile frame >16 ms.

#64 remains open.