## Rev 3 static validation: FAIL — rev 2 Resolver scoping blocker is still present

Validated commit `949b96a87ffbfcf88ca9fc5c1105e23867e18dd7` (`Issue #65 rev 3`) against #65, the runtime-performance plan, and the previous rev-2 failure. `TASK.MD` is intentionally ignored per user instruction.

### What rev 3 improves

The event-startup changes are directionally correct: startup now requires the continuation APIs explicitly instead of silently falling back to monolithic trait/aura work. That reduces the chance of reintroducing an unsliced path.

### Blocking defect: `Resolver.lua` still has the rev-2 local-function declaration-order bug

Rev 3 does not modify `core/internal/profile/Resolver.lua` at all. The current file still defines `stepResolvedStatComponents(...)` before `shouldYieldResolvedStateContinuation(...)` and calls the latter inside the earlier function:

```lua
local function stepResolvedStatComponents(continuation, context, entry, deadlineMs)
    ...
    if shouldYieldResolvedStateContinuation(deadlineMs) then
        return false
    end
    ...
end

...

local function shouldYieldResolvedStateContinuation(deadlineMs)
    ...
end
```

In Lua, because `shouldYieldResolvedStateContinuation` has not been locally declared at the point where `stepResolvedStatComponents` is defined, that reference resolves as a global lookup. The later `local function` declaration does not retroactively bind the earlier function body. The first continuation path that reaches this yield check can therefore attempt to call a nil global.

This is the same blocker identified in rev 2 and it prevents in-game validation.

## Required fix

Make the helper local binding visible before `stepResolvedStatComponents` is defined. Either:

1. move the complete `local function shouldYieldResolvedStateContinuation(deadlineMs)` definition above `stepResolvedStatComponents`, or
2. forward-declare it first:

```lua
local shouldYieldResolvedStateContinuation

local function stepResolvedStatComponents(...)
    ...
end

shouldYieldResolvedStateContinuation = function(deadlineMs)
    ...
end
```

Do not rely on a global definition elsewhere.

After this minimal fix, re-run static validation. If no further blocker appears, proceed to the existing required in-game high-content event/startup gate with timings enabled.

#65 remains open.