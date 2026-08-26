## Goal
Establish the **measurement and diagnostic baseline** required for the Runtime Performance and Hitch Elimination project before changing runtime behavior.

Authoritative documents:

- `.docs/RPE2-Runtime-Performance-Hitch-Elimination-PDD.md`
- `.docs/RPE2-Runtime-Performance-Hitch-Elimination-Implementation-Plan.md`

This task is instrumentation-only. Do not optimize or reorder gameplay logic here except where a tiny non-semantic hook is required to measure it.

## Primary files

- `core/debug/Timings.lua`
- `Commands.lua`
- `core/internal/tasks/TaskQueue.lua`
- `core/internal/database/Database.lua`
- `client/character/inventory/Inventory.lua`
- `client/character/inventory/page_Inventory.lua`
- `client/character/inventory/window_Inventory.lua`
- `client/character/profile/window_Profile.lua`
- `client/character/profile/page_ProfileEquipmentStats.lua`
- `client/client_Achievements.lua`
- `client/client_Session.lua`
- `client/client_Event.lua`
- `client/spellcasting/Core.lua`
- `client/spellcasting/Lifecycle.lua`
- `client/spellcasting/Cooldowns.lua`
- `client/spellcasting/AuraManager.lua`

Inspect current timing hooks before adding new ones. Extend `Addon.Debug.Timings`; do not introduce a second profiling framework.

## 1. Add required timing scopes

Add timings for at least:

```text
Inventory.AddItem
Inventory bulk commit / SetItems
Inventory.GetDisplayItems or display snapshot build path
InventoryGridPage:Refresh
InventoryWindow:Show
ProfileWindow:Show
EquipmentStatsPage refresh/view-model work
Achievements:ProcessTrigger
Achievement reward-chain execution
Client:HandleLocalConfigurationChanged
event start total + startup phases
event end total + teardown phases
event-state immediate handler
spellcast advancement
cooldown advancement
aura advancement
spell start
spell completion
spell component execution
visual refresh flush where an existing flush exists
network/resource flush where an existing flush exists
```

Use thresholds consistent with the PDD:

```text
normally-cheap mutation: >4ms slow
user-action immediate path: >8ms slow
cooperative slice later: >2ms slow
single-frame hard concern: >16ms
```

Do not force timing output when debug timings are disabled.

## 2. Include cardinality/context with slow operations

Where available, slow logs must include the scale of the operation rather than only elapsed time.

Examples:

```text
inventoryStacks
resolvedItems
achievementCriteria
changedAchievements
eventUnits
activeAuras
dueAuras
activeCooldowns
activeCasts
spellComponents
targetCount
queuedTasks
```

Use concise context strings or structured helper arguments consistent with the existing `Timings` API.

## 3. Add recent slow-operation diagnostics

Extend the existing timing/debug system with a bounded in-memory record of recent slow operations suitable for development diagnosis.

Requirements:

- bounded size; do not grow indefinitely;
- records contain label, elapsed time, threshold, context/cardinality where supplied, and timestamp/order information;
- disabled timing mode should have negligible overhead;
- expose a small read/print API rather than making callers inspect private tables.

Add a `/rpe` debug command to print recent slow operations and TaskQueue summary state. Keep the existing `/rpe debug timings on|off` command intact.

A command shape such as:

```text
/rpe debug perf
```

is acceptable if it matches the current command router cleanly.

## 4. Add TaskQueue diagnostics only

Expose diagnostic state for the existing queue without changing queue scheduling semantics yet.

At minimum report:

```text
pending jobs
jobs executed in last flush if readily available
last/max flush elapsed time if readily available
current configured job/time budgets
```

Do **not** implement cooperative slicing in this issue; that is a later task.

## 5. Instrument configuration invalidation entry points

Add timing/context around the global configuration refresh path so later tasks can prove runtime state no longer reaches it.

At minimum make it possible to identify:

```text
notifyConfigurationChanged(reason)
QueueLocalConfigurationRefresh(reason)
HandleLocalConfigurationChanged(reason)
```

and see the `reason` in timing/debug output.

Do not change which reasons currently enter the path in this task.

## Acceptance criteria

- [ ] Every reported hitch category has a timing scope or timed sub-phases sufficient to locate the cost.
- [ ] Slow logs include useful cardinality/context where the code already knows it.
- [ ] Existing spellcast timing output remains functional.
- [ ] `HandleLocalConfigurationChanged` is timed with its reason.
- [ ] Recent slow operations are kept in a bounded debug buffer.
- [ ] A `/rpe` debug command prints recent slow operations and TaskQueue diagnostics.
- [ ] Existing `/rpe debug timings on|off` behavior remains intact.
- [ ] TaskQueue execution behavior is unchanged.
- [ ] No gameplay, persistence, UI refresh, or networking semantics are intentionally changed.

## Validation matrix

```text
/rpe debug timings off
-> normal gameplay produces no timing spam

/rpe debug timings on
-> add item -> Inventory timing appears
-> add currency -> profile/config-related timings appear
-> open Inventory -> Show/Refresh timings appear
-> open Profile -> Show/page timings appear
-> start/end/advance event -> event phase timings appear
-> cast/complete spell -> lifecycle/component timings appear

/rpe debug perf
-> prints bounded recent slow operations
-> prints TaskQueue diagnostic summary

repeat many slow operations
-> diagnostic buffer remains bounded
```

## Constraints

- Do not optimize code paths yet.
- Do not add a second profiler/debug framework.
- Do not enable profiling permanently for normal users.
- Do not materially increase allocations on hot paths when timings are disabled.
- Do not change TaskQueue scheduling behavior.
- Do not change spell/event ordering.

## Coding-agent instructions
Use current `FrontierDev/rpe2` as authoritative. This task is intended for **5.6-Luna-ExtraHigh**. Read both runtime-performance documents first, then inspect existing `core/debug/Timings.lua`, spellcast timing helpers, and `/rpe` command routing before editing. Keep this task instrumentation-only. Report exact timing scopes added, the debug command added, cardinality fields captured, files changed, and baseline observations obtainable from the new instrumentation.