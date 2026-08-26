## Goal
Add the shared **runtime transaction / ChangeSet / revision foundation** required by the performance refactor, without yet rewriting individual subsystems to use it extensively.

Authoritative documents:

- `.docs/RPE2-Runtime-Performance-Hitch-Elimination-PDD.md`
- `.docs/RPE2-Runtime-Performance-Hitch-Elimination-Implementation-Plan.md`

Depends on: #58

This task establishes the common infrastructure that later currency, Achievement, Inventory, Profile, event, aura, cooldown and spell tasks will consume.

## Primary files

- `core/internal/Runtime.lua`
- `RPEngine_Dev.toc`
- new runtime transaction/revision module in `core/internal/` at a location consistent with the existing namespace/load order

Inspect the current `Addon.Internal` runtime organization before choosing the exact filename. Prefer one focused module rather than spreading transaction state across unrelated files.

## 1. Introduce in-memory revision domains

Add explicit monotonic runtime revision domains for at least:

```text
ProfileStateRevision
CurrencyRevision
AchievementRevision
InventoryRevision
EquipmentRevision
SkillRevision
ActionBarBindingRevision
ResolvedProfileRevision
EventRuntimeRevision
AuraRevisionByEventId
CooldownRevisionByEventId
SpellcastRevisionByEventId
```

Requirements:

- `ConfigurationRevision` remains owned by the existing configuration system and is not replaced;
- new revisions are in-memory only unless the existing architecture has a compelling reason otherwise;
- expose stable getter/bump APIs rather than allowing arbitrary modules to mutate private counters directly;
- event-scoped revisions must be cleanly removable when an event ends;
- revision values reset safely on `/reload`.

The exact API may differ, but callers need operations equivalent to:

```lua
Runtime.GetRevision(domain, key)
Runtime.BumpRevision(domain, key)
Runtime.GetRevisionTuple(...)
```

Do not over-engineer a generic dependency graph.

## 2. Add lightweight Runtime transactions

Implement an API equivalent to:

```lua
Runtime.BeginTransaction(reason, options)
Runtime.GetCurrentTransaction()
Runtime.MarkChanged(scope, detail)
Runtime.CommitTransaction(transaction)
Runtime.RunTransaction(reason, fn, options)
```

Requirements:

- nested calls participate in the existing outer transaction by default;
- only the outermost successful commit publishes the consolidated result;
- independent subsystem calls still work through short implicit transactions once later tasks adopt the API;
- transaction identity/reason is available for diagnostics;
- transaction state must not be persisted;
- no coroutine or actual concurrency requirement exists.

## 3. Define a typed ChangeSet contract

Create a compact ChangeSet shape sufficient for later tasks to mark only changed scopes.

It must support at least:

```text
inventory
currencies
achievements
profile equipment/stats/resources/skills
event units/auras/cooldowns/spellcasts/structural state
UI profile tabs
UI inventory pages
UI action-bar slots/structural state
UI event portraits
targeting
```

Do not require every field to be eagerly allocated. Prefer lazy bucket creation so cheap mutations do not create large temporary tables.

Provide narrow helpers for common patterns such as:

```text
mark key in set
mark boolean scope
mark event unit
merge child ChangeSet into parent
```

## 4. Add commit listeners / post-commit hooks

Provide a small subscription API so UI/runtime systems can react to a committed ChangeSet in later tasks.

Requirements:

- listeners receive one committed consolidated payload;
- listeners are not called for every nested mutation;
- listener iteration is safe if a listener errors;
- listener registration/unregistration is explicit;
- no broad UI refresh behavior should be wired in this issue yet.

If the existing codebase already has a generic event/listener mechanism that cleanly satisfies this requirement, reuse it rather than creating a duplicate bus.

## 5. Define failure/re-entrancy behavior

Transactions must behave predictably when a wrapped function errors.

At minimum:

- do not publish a successful post-commit ChangeSet after an uncaught transaction error;
- always clear/restore the current transaction pointer/depth;
- surface the original error through the existing debug/error conventions;
- do not claim full database rollback unless the implementation actually provides rollback.

The transaction system is primarily a **notification/invalidation batching boundary**, not a general ACID database.

## 6. Add diagnostics

Integrate with #58 diagnostics.

Expose at least:

```text
current transaction id/reason/depth
last committed transaction summary
change-scope counts
revision bump counts if practical
```

Do not print by default.

## Acceptance criteria

- [ ] A focused runtime transaction/revision module is loaded before consumers that require it.
- [ ] Required revision domains have stable getter/bump APIs.
- [ ] `ConfigurationRevision` is not replaced or repurposed.
- [ ] Nested `RunTransaction` calls produce one outer commit.
- [ ] ChangeSet buckets are typed/narrow and lazily allocated where practical.
- [ ] Commit listeners receive one consolidated payload per outer transaction.
- [ ] Listener errors do not abort unrelated listeners or corrupt transaction state.
- [ ] Event-scoped revision state can be cleared by event ID.
- [ ] Error paths restore transaction state cleanly.
- [ ] No existing gameplay behavior changes merely because the infrastructure exists.

## Validation matrix

```text
RunTransaction("outer")
 -> MarkChanged currency:valor
 -> nested RunTransaction("inner")
    -> MarkChanged achievement:A
-> one commit listener call
-> ChangeSet contains both scopes

transaction with no changes
-> completes safely
-> does not create spurious UI/config refresh

transaction callback errors
-> current transaction state clears
-> no successful commit event is published
-> error remains visible through existing debug behavior

bump CurrencyRevision
-> ConfigurationRevision unchanged

clear event runtime revisions for event X
-> event X scoped counters removed/reset
-> unrelated event Y untouched
```

## Constraints

- Do not migrate currency/Achievement/Inventory/event call sites in bulk yet.
- Do not implement UI refresh policy here.
- Do not persist runtime revisions.
- Do not build a generalized reactive framework beyond what the PDD requires.
- Do not change networking, spell ordering, Achievement semantics, or SavedVariables.

## Coding-agent instructions
Use current `FrontierDev/rpe2` as authoritative. This task is intended for **5.6-Luna-ExtraHigh**. Read both runtime-performance documents and completed #58. Inspect `core/internal/Runtime.lua` and TOC ordering before choosing the new module location. Keep the infrastructure minimal and explicit because many later tasks depend on its API. Report the exact public/internal transaction API, revision domains, ChangeSet representation, load-order change, diagnostics added, and validation performed.