## Validation result: revision required

The core unlimited-requisition implementation is mostly correct, but there is one backward-compatibility defect that should be fixed before closing #37.

### Blocking defect: malformed/sub-1 limits can become unlimited

Before #37, `characterLimit` was normalized with a minimum of `1`, so values such as `-1` or `0.5` became `1`.

The current implementation changes normalization to a minimum of `0`, which means:

```text
-1   -> 0 -> unlimited
-50  -> 0 -> unlimited
0.5  -> 0 -> unlimited
```

That violates this issue's backward-compatibility requirement that absent/invalid existing values continue to behave as `1`, and it can accidentally turn malformed legacy data into an infinitely repeatable Guild Shop purchase.

### Required revision

Make **only an explicitly authored numeric `0`** mean unlimited.

Apply the same semantic rule consistently in:

- `core/classes/GuildSetting.lua`
- `client/ui/editor/inspectors/page_InspectorGuildSetting.lua`
- defensive runtime normalization in `client/client_Guild.lua`

A suitable contract is:

```lua
local function normalizeCharacterLimit(value)
    local numeric = tonumber(value)

    if not numeric
        or numeric ~= numeric
        or numeric == math.huge
        or numeric == -math.huge then
        return 1
    end

    if numeric == 0 then
        return 0
    end

    return math.max(1, math.floor(numeric))
end
```

The inspector must use equivalent semantics before committing, otherwise e.g. `-1` could be coerced to `0` by the editor and then become indistinguishable from an intentionally authored unlimited value.

### Re-validation required

After revision, verify at minimum:

```text
nil/absent -> 1
invalid text -> 1
NaN/inf -> 1
-1 -> 1
0.5 -> 1
0 -> 0
1 -> 1
3 -> 3
```

Then verify:

- `characterLimit = 0` bypasses `GetGuildRequisitionUsage()`;
- unlimited purchases do not call `IncrementGuildRequisitionUsage()` or write the ledger;
- repeated unlimited purchases still succeed while otherwise eligible/affordable;
- positive limits retain existing usage-limit and rollback behavior.

### Scope note

The #37 commit also removed `RPE2-Phase-5-Remaining-Achievement-Features-Implementation-Plan.md` and moved the PDD into `.docs`. Those changes are outside this task's stated scope. They are not a gameplay blocker, but they should be confirmed as intentional rather than incidental Codex changes.

Everything else in the #37 gameplay change is consistent with the issue: unlimited eligibility bypasses the ledger, unlimited transactions skip ledger writes, limited requisitions retain the existing transaction path, and no new Profile/shop persistence system was introduced.