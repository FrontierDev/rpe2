## In-game validation: FAIL — `pending-turn-commit` crashes immediately

The new in-game error is a direct runtime blocker in the #72 implementation:

```text
Task queue sliceable job pending-turn-commit failed:
client/client_Event.lua:2101: attempt to call a nil value
```

The failing line on current `main` is:

```lua
if shouldYieldTaskSlice(deadlineMs) then
    return false
end
```

`client/client_Event.lua` does **not define** `shouldYieldTaskSlice`; this is the only reference to that symbol in the file. The same helper already exists in `client/client_Traits.lua` and shows the intended pattern:

```lua
local function shouldYieldTaskSlice(deadlineMs)
    local tasks = getTasks()
    return deadlineMs ~= nil
        and type(tasks) == "table"
        and type(tasks.ShouldYield) == "function"
        and tasks:ShouldYield(deadlineMs) == true
end
```

### Required immediate fix

Add the equivalent narrow helper to `client/client_Event.lua` near its existing TaskQueue helpers, or call the existing TaskQueue `ShouldYield` API directly using the same guards. Do **not** bypass/remove the yield check and do not redesign the turn-commit state machine for this fix.

Then re-test the basic commit path before doing any further #72 validation:

```text
cast/apply one aura
-> Pending Changes contains one aura apply
-> Advance
-> pending-turn-commit runs without Lua error
-> resource phase completes
-> aura phase completes
-> EVENT_STATE advances exactly once
```

The previously reported owner-page topology defect is still outstanding after this crash is fixed. #72 must remain open.