# RPE 2 — Runtime Performance and Hitch Elimination Implementation Plan

**Status:** Implementation plan  
**Target:** `FrontierDev/rpe2`  
**Authoritative product design:** `.docs/RPE2-Runtime-Performance-Hitch-Elimination-PDD.md`  
**Primary objective:** Eliminate the reported RPE-caused freezes/lag spikes without changing gameplay semantics, persistence compatibility, or network authority  
**Coding environment:** VSCode + Codex plugin  
**Target coding model:** `5.6-Luna-ExtraHigh`

---

# 1. Objective

Implement the architecture defined by the Runtime Performance and Hitch Elimination PDD so that normal RPE gameplay mutations do not trigger broad configuration rebuilds, expensive read-side work is revision-cached, UI refreshes are dirty/coalesced, and all potentially unbounded runtime work can be processed in bounded slices.

The reported problem areas are:

- event start;
- event end;
- advance turn/tick;
- spellcast start;
- spellcast completion;
- Inventory opening;
- Profile opening;
- receiving items;
- receiving currencies.

This is a cross-cutting runtime refactor. Do **not** treat the task as nine unrelated local optimizations. The shared fix is:

```text
runtime mutation
 -> one runtime transaction
 -> narrow revisions / typed changes
 -> bounded derived work
 -> one post-commit UI/network flush
```

The existing `ConfigurationRevision`/`HandleLocalConfigurationChanged()` pipeline remains for genuine authored/configuration changes only.

---

# 2. Coding-agent execution contract

This implementation plan is intended to be read directly by Codex in VSCode using `5.6-Luna-ExtraHigh`.

Before editing:

1. Read this implementation plan completely.
2. Read `.docs/RPE2-Runtime-Performance-Hitch-Elimination-PDD.md` completely.
3. Inspect the **current** versions of every file named in the active phase before modifying it.
4. Search all callers of any function whose behavior/signature is changed.
5. Treat the current repository as authoritative when it differs from examples in this document.

During implementation:

- Implement phases in order. Later phases depend on the revision/transaction infrastructure established earlier.
- Keep each phase internally complete before moving to the next phase.
- Do not perform opportunistic gameplay redesigns, UI redesigns, schema redesigns, or unrelated cleanup.
- Preserve existing public/internal function return values wherever practical.
- Preserve spell effect ordering, random-roll ordering, resource amounts, aura semantics, cooldown semantics, Achievement semantics, Inventory stacking semantics, and authority rules.
- Do not replace the solution with widespread `C_Timer.After(0, ...)` calls. Deferring an unbounded function does not make it bounded.
- Do not increase the TaskQueue frame budget to conceal slow jobs.
- Do not make SavedVariable caches/indexes persistent unless unavoidable. Runtime revisions/indexes should normally rebuild in memory after `/reload`.
- Do not claim frame-time targets pass unless they were measured inside WoW. Static/syntax validation is not a substitute for runtime profiling.
- When a phase cannot be fully performance-validated outside WoW, finish the implementation and instrumentation, then clearly report the exact in-game validation still required.

When deleting/replacing broad behavior, search for stale callers and dead helpers before ending the phase.

The transaction system introduced here is a **batching, ordering and invalidation boundary**, not a general ACID rollback engine. Existing feature-specific rollback behavior, especially Achievement reward and Guild transaction rollback, must remain intact unless deliberately replaced by an equally safe mechanism.

---

# 3. Current repository anchors

The current load order in `RPEngine_Dev.toc` is important:

```text
core/debug/Timings.lua
...
core/internal/tasks/TaskQueue.lua
core/internal/comms/MessageQueue.lua
...
core/internal/Runtime.lua
core/internal/database/Database.lua
core/internal/profile/Definitions.lua
...
core/internal/profile/Currencies.lua
core/internal/profile/Achievements.lua
core/internal/profile/Guild.lua
core/internal/profile/Profile.lua
...
client/client_Session.lua
client/client_Resources.lua
client/client_Achievements.lua
client/client_Guild.lua
client/client_Commands.lua
client/character/inventory/Inventory.lua
client/client_AchievementRewards.lua
...
client/client_Traits.lua
...
client/client_Event.lua
...
client/spellcasting/Helpers.lua
client/spellcasting/Core.lua
client/spellcasting/Cooldowns.lua
client/spellcasting/Lifecycle.lua
client/spellcasting/AuraManager.lua
...
client/character/inventory/page_Inventory.lua
client/character/inventory/page_Consumables.lua
client/character/inventory/page_Reagents.lua
client/character/inventory/window_Inventory.lua
client/character/profile/page_ProfileEquipmentStats.lua
client/character/profile/page_ProfileSpellbook.lua
client/character/profile/page_ProfileTraits.lua
client/character/profile/page_ProfileSkills.lua
client/character/profile/page_ProfileAchievements.lua
client/character/profile/window_Profile.lua
```

Important current architecture:

- `core/internal/Runtime.lua` currently owns WoW event dispatch/initialization; do not overload it with a large transaction implementation.
- `core/internal/tasks/TaskQueue.lua` already has count/time budgets but normal jobs are indivisible.
- `core/debug/Timings.lua` already provides `Start`, `Stop`, `Measure` and `LogParts`.
- `Commands.lua` already provides `/rpe debug timings`.
- `client/spellcasting/Helpers.lua` already contains dirty/coalesced visual refresh infrastructure. Extend this pattern rather than replacing it with another competing event loop.
- `client/character/inventory/page_Inventory.lua` defines the shared `InventoryGridPage` used by Inventory/Consumables/Reagents.
- `core/internal/profile/Profile.lua` already contains resolved-state caches. Reuse them rather than duplicating equivalent stat/resource resolvers.

---

# 4. Target runtime primitives

## 4.1 New runtime transaction module

Create:

```text
core/internal/runtime/RuntimeTransaction.lua
```

Add it to `RPEngine_Dev.toc` **after** `core/internal/tasks/TaskQueue.lua` and **before** `core/internal/Runtime.lua` / `core/internal/database/Database.lua` so Database/Profile/Client code can use it during normal load.

Expose it under:

```lua
Addon.Internal.Runtime
```

Do not rename the existing `core/internal/Runtime.lua`; that file remains the runtime event dispatcher.

## 4.2 Required transaction behavior

The exact implementation may differ, but the service must provide equivalent behavior to:

```lua
Runtime:GetRevision(scope, key)
Runtime:BumpRevision(scope, key)

Runtime:BeginTransaction(reason, options)
Runtime:GetCurrentTransaction()
Runtime:MarkChanged(scope, detail)
Runtime:EmitMutationEvent(kind, payload)
Runtime:QueueAfterCommit(fn, ...)
Runtime:CommitTransaction(transaction)
Runtime:RunTransaction(reason, fn, options, ...)

Runtime:RegisterBeforeCommitProcessor(kind, handler)
Runtime:RegisterPostCommitListener(handler)
```

Naming may be adjusted to repository conventions, but do not omit the capabilities.

### Nested transactions

Nested feature calls must join the outer transaction.

Example:

```text
Achievement completes
 -> reward grants item
    -> Inventory.AddItem()
 -> reward grants currency
    -> Profile.AddCurrencyAmount()
 -> dependent Achievement progresses
```

This must remain one outer transaction and one final presentation flush.

A nested `RunTransaction()` must not commit independently when an outer transaction is already active.

### Before-commit processors

Before-commit processors are for authoritative dependent behavior which must participate in the same logical action, for example:

- `item_gain` Achievement triggers;
- `currency_gain` Achievement triggers;
- `skill_gain` Achievement triggers where the current behavior requires it.

They consume typed mutation events from the transaction. A processor may append further mutations/events. The transaction must drain these events deterministically before final commit.

Do not use before-commit processors for UI refreshes.

### Post-commit listeners

Post-commit listeners consume the finalized ChangeSet and may:

- mark UI surfaces dirty;
- queue targeted visual refreshes;
- queue allowed network delta flushes;
- perform non-authoritative announcements.

They must not cause per-mutation refresh storms.

### Transaction failure

A transaction error must:

- clear the active transaction/transition state safely;
- avoid running post-commit UI/network callbacks for a failed transaction;
- preserve existing operation-specific rollback semantics where those already exist;
- report the failing transaction reason through existing Debug error handling.

Do not attempt to snapshot/rollback the entire addon state generically.

---

# 5. Revision ownership

Implement monotonic in-memory revisions. `ConfigurationRevision` remains the existing authored-configuration revision.

Required logical revisions:

```text
ConfigurationRevision
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

Subsystems may expose convenience accessors such as:

```lua
Inventory.GetRevision()
Profile.GetStateRevision()
Profile.GetCurrencyRevision()
Profile.GetAchievementRevision()
```

but there should be one clear owner for incrementing each revision.

Rules:

- a revision increments once per committed transaction, even if the transaction performs ten changes in the same domain;
- keyed event revisions increment once per affected event;
- read-only calls never increment revisions;
- cache keys must list all revisions which affect their result;
- `ConfigurationRevision` must not change for ordinary currency/Achievement/Inventory/event/cooldown/aura/spellcast progress.

---

# 6. ChangeSet contract

Use a deduplicating ChangeSet. The exact shape is implementation-specific, but it must be able to represent at least:

```lua
{
    inventory = {
        changed = true,
        slots = {},
        addedRefs = {},
        removedRefs = {},
        mutationCount = 0,
    },
    currencies = {
        changed = true,
        keys = {},
        gains = {},
    },
    achievements = {
        changed = true,
        refs = {},
        completedRefs = {},
    },
    profile = {
        equipment = false,
        stats = false,
        resources = false,
        skills = {},
    },
    event = {
        eventIds = {},
        units = {},
        auraUnits = {},
        cooldownUnits = {},
        spellcastUnits = {},
        structural = false,
    },
    ui = {
        profileTabs = {},
        inventoryPages = {},
        actionBarSlots = {},
        eventPortraits = {},
        targeting = false,
    },
}
```

Use set-like tables for refs/keys/IDs so repeated mutations coalesce naturally.

Do not make low-level Database code depend directly on UI modules. Database/Profile/Inventory should record typed state changes; client UI code should consume committed changes.

---

# 7. Phase 1 — Performance instrumentation and baseline hooks

## Files

At minimum inspect/modify as required:

```text
core/debug/Timings.lua
Commands.lua
core/internal/tasks/TaskQueue.lua
client/character/inventory/Inventory.lua
client/character/inventory/page_Inventory.lua
client/character/inventory/window_Inventory.lua
client/character/profile/window_Profile.lua
client/character/profile/page_ProfileEquipmentStats.lua
client/client_Achievements.lua
client/client_Event.lua
client/spellcasting/Core.lua
client/spellcasting/Cooldowns.lua
client/spellcasting/Lifecycle.lua
client/spellcasting/AuraManager.lua
client/spellcasting/Helpers.lua
```

## 7.1 Extend `Debug.Timings`

Keep the existing API. Add a small bounded recent-record buffer for development diagnostics.

A timing record should be able to retain:

```lua
{
    label = ...,
    context = ...,
    elapsedMs = ...,
    thresholdMs = ...,
    slow = true/false,
    cardinality = {...},
}
```

Requirements:

- bounded ring/list, e.g. last 50–100 records;
- no unbounded SavedVariable or memory growth;
- cardinality tables are only created while timings are enabled;
- debug-disabled hot paths should avoid constructing expensive log strings/tables;
- retain existing `Start`, `Stop`, `Measure`, `LogParts` compatibility.

Add helpers equivalent to:

```lua
Timings:GetRecentRecords(options)
Timings:ClearRecentRecords()
```

## 7.2 Add diagnostics commands

Retain `/rpe debug timings on|off`.

Add development commands, preferably:

```text
/rpe debug perf
/rpe debug tasks
```

`debug perf` should print recent slow timing records and key cardinalities.

`debug tasks` should print `TaskQueue:GetStats()` including the sliceable-job fields added later. It may initially print existing stats and expand in Phase 6.

Do not create a separate debug window for this task.

## 7.3 Instrument required hot paths

Add timing scopes/cardinality for:

- `Inventory.AddItem`;
- Inventory bulk mutation;
- Inventory display snapshot/re-resolution path;
- `InventoryGridPage:Refresh`;
- Inventory window show;
- Profile window show;
- active Profile page refresh;
- Equipment/Stats view-model resolution;
- `Achievements:ProcessTrigger`;
- Achievement reward-chain completion;
- `Client:HandleLocalConfigurationChanged`;
- event start/end and startup phases;
- event-state immediate handling;
- cast advancement;
- cooldown advancement;
- aura advancement;
- spell start/complete;
- component execution;
- visual flush;
- network delta flush where practical.

Include relevant counts such as inventory stacks, criteria, event units, active/due auras, active cooldowns, casts, spell components and targets.

## Phase 1 validation

- Existing behavior is unchanged.
- `/rpe debug timings` still works.
- New diagnostics do not error when timings are disabled.
- Timing cardinality collection is guarded behind debug/timing activation.
- No benchmark claims are made without WoW measurements.

---

# 8. Phase 2 — Runtime transactions and separation from configuration

This is the highest-value phase and a prerequisite for the rest.

## Files

```text
RPEngine_Dev.toc
core/internal/runtime/RuntimeTransaction.lua          # new
core/internal/database/Database.lua
core/internal/profile/Profile.lua
core/internal/profile/Currencies.lua
core/internal/profile/Achievements.lua
client/client_Session.lua
client/client_Achievements.lua
client/character/inventory/Inventory.lua              # transaction integration only in this phase
```

## 8.1 Add runtime transaction/revision service

Implement the service described in sections 4–6.

Keep it free of UI-specific dependencies.

It may depend on:

- `Addon.Debug`;
- `Addon.Internal.Tasks` for post-commit scheduling where needed.

It must load before Database/Profile.

## 8.2 Exhaustively classify `notifyConfigurationChanged(...)`

Search all current call sites of:

```lua
notifyConfigurationChanged(...)
```

Do not only patch the three known strings.

Create a temporary working classification while editing:

```text
reason/caller
 -> authored configuration
 -> structural profile change
 -> runtime/profile state
```

The following are definitely runtime state and must leave the global configuration path:

```text
profile-currency
profile-achievements
profile-achievement-rewards
```

Also classify every other `profile-*` mutation individually. Prefer the narrow runtime path for mutable character state. Only retain a Profile mutation on the configuration path when it genuinely changes the derivation/configuration graph and the PDD permits it.

At the end of the phase, ordinary gameplay currency/Achievement state changes must not increment `ConfigurationRevision`.

## 8.3 Add narrow Database/Profile state notification

Replace runtime uses of `notifyConfigurationChanged()` with a private narrow mutation path which:

1. mutates the SavedVariable-backed Profile field;
2. marks the relevant Runtime transaction domain;
3. emits a typed mutation event when required;
4. does **not** call `HandleLocalConfigurationChanged()`;
5. does **not** queue client-connect refresh by itself.

For currency changes:

```text
SetProfileCurrencyAmount
 -> write balance
 -> mark profile/currency changed
 -> emit currency mutation information
 -> return
```

For Achievement state/reward changes:

```text
SetProfileAchievementState / reward state
 -> write state
 -> mark achievement/profile changed
 -> return
```

## 8.4 Restrict `HandleLocalConfigurationChanged()`

In `client/client_Session.lua`:

- keep the heavyweight handler for real configuration changes;
- prevent ordinary runtime ChangeSets from reaching it;
- retain recipe knowledge rebuild, activated-dataset Achievement index rebuild, trait configuration rebuild, action-bar definition rebuild, and reconnect/hash behavior only when their actual inputs changed;
- where practical, split internal work into named configuration scopes (`dataset`, `ruleset`, `profile-structure`) so genuine configuration changes can also be narrower;
- add a development warning/assertion path if known runtime-only reasons such as `profile-currency` or `profile-achievements` somehow reach the handler again.

## 8.5 Runtime post-commit routing

Register one client-side post-commit listener or a small number of subsystem listeners which translate ChangeSets into:

- dirty Profile tabs;
- dirty Inventory pages;
- targeted event/action-bar/tooltip dirty state;
- required resource/network delta work.

Do not directly `Refresh()` windows from Database/Profile setters.

## Phase 2 validation

Search/verify:

```text
profile-currency          -> no notifyConfigurationChanged
profile-achievements      -> no notifyConfigurationChanged
profile-achievement-rewards -> no notifyConfigurationChanged
```

Test conceptually/in WoW:

```text
grant currency
 -> CurrencyRevision changes
 -> ConfigurationRevision does not
 -> no recipe knowledge rebuild
 -> no client-connect refresh
 -> only currency/Achievement-dependent UI becomes dirty
```

---

# 9. Phase 3 — Transactional Achievement processing and rewards

## Files

```text
core/internal/database/Database.lua
core/internal/profile/Achievements.lua
client/client_Achievements.lua
client/client_AchievementRewards.lua
client/character/profile/page_ProfileAchievements.lua
```

## 9.1 Keep the criterion index configuration-derived

`Achievements:RebuildIndex()` must run when Achievement definitions/activated datasets change, not when Achievement progress changes.

`EnsureIndex()` should use the configuration/dataset signature already present and must not be invalidated by `AchievementRevision`.

## 9.2 Batch one trigger chain

Refactor `Achievements:ProcessTrigger()` so one incoming trigger runs inside the current/implicit Runtime transaction:

```text
read CriteriaByTrigger bucket
 -> evaluate matching criteria
 -> accumulate changed states
 -> detect completions
 -> enqueue/process achievement_earned dependencies
 -> accumulate rewards
 -> persist changed states in batch
 -> deliver rewards inside same transaction
 -> mark AchievementRevision once
 -> queue announcements after commit
```

Avoid calling the Profile UI from `_CommitState()`.

Prefer replacing recursive `achievement_earned` calls with an explicit deterministic work queue so cycle detection and continuation state are clear.

## 9.3 Add batch persistence

Add Database/Profile batch APIs if needed, for example:

```lua
Database.SetProfileAchievementStates(statesByRef)
Profile.SetAchievementStates(statesByRef)
```

Requirements:

- normalize affected states;
- access the active Profile once;
- write all affected refs;
- mark Achievement/Profile state once;
- do not call global configuration invalidation per ref.

Keep single-state APIs for compatibility and implement them via the same narrow mutation primitive.

## 9.4 Transactional item/currency/skill triggers

Achievements must observe item/currency/skill gain **before final transaction commit** so reward chains remain one logical action.

Use the Runtime before-commit mutation processor mechanism rather than UI-style post-commit listeners.

Each emitted mutation event must be processed once. If a reward creates another mutation event, append it to the same transaction queue and continue deterministically.

## 9.5 Cycle guard

Protect malformed dependency graphs such as:

```text
Achievement A completion
 -> achievement_earned B
 -> reward/progress completes A again
```

Use a per-transaction visited/processed key appropriate to the trigger/achievement pair. Do not silently suppress legitimate distinct criteria updates in the same transaction.

## 9.6 Reward delivery

Preserve the current recovery/rollback safety in `client_AchievementRewards.lua`.

In this phase:

- stop reward-state persistence from causing global configuration invalidation;
- ensure reward item/currency grants join the outer Runtime transaction;
- queue chat announcements only after successful commit;
- do not refresh Profile/Inventory after each reward entry.

After Phase 4 introduces efficient Inventory variant/index APIs, return to this file and remove any remaining full-inventory scans used only for reward verification/rollback where an incremental mutation token/API can provide the same safety.

## Phase 3 validation

Test:

- item gain with no Achievement;
- item gain advancing one Achievement;
- currency gain completing multiple Achievements;
- completion granting multiple items/currencies;
- dependent `achievement_earned` criteria;
- malformed dependency cycle;
- event start/end Achievement triggers.

Verify one outer transaction and one post-commit UI notification set.

---

# 10. Phase 4 — Inventory canonicalization, stack index and display snapshots

## Files

```text
client/character/inventory/Inventory.lua
client/client_AchievementRewards.lua
client/client_Crafting.lua                         # only if current Inventory listener/use requires adaptation
client/character/inventory/window_ItemModification.lua
```

Audit all callers of:

```lua
Inventory.GetItems
Inventory.SetItems
Inventory.GetItem
Inventory.AddItem
Inventory.RemoveItem
Inventory.DeleteItem
Inventory.SetItemSoulbound
Inventory.ApplyModification
Inventory.GetDisplayItems
Inventory.RegisterChangeListener
```

before changing semantics.

## 10.1 Canonicalize once

`Inventory.GetItems()` must become a read operation.

Create per-character in-memory runtime state, conceptually:

```lua
Inventory.RuntimeByCharacter[characterKey] = {
    canonicalized = false,
    stackIndex = {},
    indexByRecord = {},
    displaySnapshot = nil,
    displaySnapshotInventoryRevision = -1,
    displaySnapshotConfigurationRevision = -1,
}
```

Do not persist this table.

On first access after login/reload:

- normalize the stored list once;
- replace invalid/migrated records once;
- build runtime indexes once;
- mark `canonicalized = true`.

Subsequent `GetItems()` calls return the canonical list without rebuilding it.

## 10.2 Stable modification signature

Implement a deterministic modification signature for stack identity.

Stack identity must include:

```text
dataset
item id
soulbound state
modification signature
```

The signature function must:

- be deterministic for nested tables used by modifications;
- sort map keys;
- avoid recursive `deepEqual()` against every existing stack;
- be recomputed only when the record's modification state changes.

Keep the signature/index in runtime memory unless a compelling reason exists to persist it.

## 10.3 Stack index

Maintain matching-stack buckets from stack identity to candidate record/index references.

Update the index during:

- add;
- remove/delete;
- split;
- merge;
- soulbind changes;
- modification application;
- bulk `SetItems()`.

Appending or filling an existing stack should not require a complete inventory scan.

When `table.remove` shifts indices, repair the affected index range; do not renormalize every record.

## 10.4 Incremental `AddItem()`

Refactor to:

```text
normalize incoming record once
 -> resolve item definition once
 -> compute stackability/max stack once
 -> compute stack key once
 -> query stack index
 -> mutate matching stacks
 -> append overflow stacks
 -> record inventory mutation in transaction
 -> return
```

Do not call the normal `GetItems()` + `SetItems()` full-normalization round trip.

Keep bind-on-pickup behavior unchanged.

## 10.5 Bulk `SetItems()`

Retain `SetItems()` for explicit bulk replacement/migration.

It may perform a complete normalization, but it must:

- do so once;
- rebuild indexes once;
- invalidate the display snapshot once;
- emit one bulk mutation/ChangeSet entry.

## 10.6 Display snapshot cache

Add an Inventory display snapshot keyed by:

```text
InventoryRevision + ConfigurationRevision
```

Each source record is resolved once into a read-only presentation entry containing the values required by the Inventory UI, including prebuilt normalized search text and filter values.

Expose an API such as:

```lua
Inventory.GetDisplaySnapshot()
```

For compatibility, `Inventory.GetDisplayItems()` may delegate to this snapshot if all callers treat the returned entries as read-only. Audit callers before doing so.

Do not rebuild the snapshot during an uncommitted transaction merely because stored records have changed. Presentation work occurs after commit/revision bump.

## 10.7 Efficient variant APIs for rewards/modifications

Where `client_AchievementRewards.lua` or item-modification code currently scans/normalizes the full Inventory to locate variants, add narrow Inventory APIs backed by the index, for example:

```lua
Inventory.GetVariantQuantity(recordOrKey)
Inventory.RemoveVariantQuantity(recordOrKey, quantity)
```

Use them only where they preserve existing rollback/recovery semantics.

## 10.8 Listener split

Preserve `RegisterChangeListener()` compatibility if other modules use it, but change semantics so presentation/general listeners receive consolidated post-commit changes.

Authoritative dependent systems such as Achievements must use the before-commit mutation-event path from Phase 2/3.

## Phase 4 validation

With 10 / 50 / 150+ stacks, validate:

- add to existing stack;
- overflow stack;
- non-stackable add;
- partial remove;
- delete;
- bind/split;
- modification;
- bulk reward grant;
- inactive/missing dataset item.

Search the final `GetItems()` path and verify it does not normalize/rewrite all items on a normal read.

---

# 11. Phase 5 — Inventory/Profile dirty UI and revision-cached presentation

## Files

```text
client/character/inventory/page_Inventory.lua
client/character/inventory/page_Consumables.lua
client/character/inventory/page_Reagents.lua
client/character/inventory/window_Inventory.lua
core/ui/prefabs/CurrencyPanel.lua
client/character/profile/window_Profile.lua
client/character/profile/page_ProfileEquipmentStats.lua
client/character/profile/page_ProfileSpellbook.lua
client/character/profile/page_ProfileTraits.lua
client/character/profile/page_ProfileSkills.lua
client/character/profile/page_ProfileAchievements.lua
core/internal/profile/Profile.lua
client/spellcasting/DescriptionBuilder.lua              # only where tooltip cache invalidation requires it
client/traits/DescriptionBuilder.lua                    # same
```

## 11.1 Inventory page consumes one snapshot

Refactor shared `InventoryGridPage` so one `Refresh()` obtains one snapshot and reuses it for:

- category filtering;
- facet/filter construction;
- search filtering;
- empty-state calculation;
- slot rendering.

Methods such as `BuildFilterItems()` and `GetFilteredDisplayItems()` should accept the already-resolved category/snapshot input instead of independently calling `Inventory.GetDisplayItems()`.

Precompute/carry `normalizedSearchText` in the display snapshot. Do not rebuild the item search index on every refresh.

## 11.2 Inventory active-page ownership

`InventoryWindow:Refresh()` must refresh only the active tab/page.

Each page tracks the Inventory/configuration/currency revisions relevant to it.

Hidden pages:

```text
mutation
 -> mark dirty
 -> no render

tab shown
 -> RefreshIfDirty()
 -> render once
```

Do not refresh Consumables/Reagents just because Inventory is active.

## 11.3 Currency panel

`CurrencyPanel` must track `CurrencyRevision` and configuration revision and implement a cheap `RefreshIfDirty()`/equivalent fast path.

An Inventory item-only mutation must not force currency definition/balance rebuilding.

## 11.4 Profile single-refresh ownership

For every Profile page adopt:

```text
Build(parent, owner)
 -> construct controls only

page becomes active/visible
 -> RefreshIfDirty()
```

Remove the current duplicate combinations of:

- `Build()` calling `Refresh()`;
- tab builder calling `Refresh()` again;
- `ProfileWindow:Show()` calling another refresh;
- `OnShow` triggering the same current-revision refresh again.

Choose one activation path and make it authoritative.

`TabContainer` already builds tabs lazily. Do not replace that architecture.

## 11.5 Profile page revision signatures

Each Profile page must define the revision tuple which affects it.

At minimum:

```text
Equipment & Stats
 -> ConfigurationRevision
 -> ProfileStateRevision
 -> EquipmentRevision
 -> ResolvedProfileRevision

Spellbook
 -> ConfigurationRevision
 -> ProfileStateRevision / spellbook revision
 -> ActionBarBindingRevision where relevant

Traits
 -> ConfigurationRevision
 -> relevant Profile/Trait revision

Skills
 -> ConfigurationRevision
 -> SkillRevision

Achievements
 -> ConfigurationRevision
 -> AchievementRevision
```

Store the last rendered signature. `RefreshIfDirty()` returns immediately when unchanged.

## 11.6 Profile presentation snapshot

Reuse existing resolved-stat/resource caches in `core/internal/profile/Profile.lua` and add a higher-level presentation snapshot only for data still repeatedly regrouped/reformatted by the UI.

The snapshot should provide read-only resolved data such as:

- equipment layout/slot resolution;
- stat rows;
- resource rows;
- current race/class/level selector values;
- item-level summary;
- selected equipment scope data.

Key it by the exact revisions which affect those values.

Do not deep-copy the full snapshot merely for read-only rendering.

## 11.7 Scope-specific work

In `page_ProfileEquipmentStats.lua`:

- character scope must not build mount choices;
- mount scope must not build pet choices;
- pet scope must not build mount choices;
- cache mount/pet lists independently where appropriate.

## 11.8 Lazy tooltip descriptions

Do not eagerly build expensive item/stat/trait/spell tooltip descriptions while opening a window if they are not visible.

Use existing tooltip/description-builder revision caches and build on hover or first request.

## 11.9 First construction fallback

The PDD permits the Inventory 48-slot pool and Profile control creation to remain eager **only if** in-game timing shows each first construction frame remains under the 16 ms hard limit.

If first construction exceeds the limit, convert control-pool construction to Phase 6 sliceable jobs:

```text
show window chrome
 -> build fixed batches of slots/rows
 -> populate when ready
```

Do not invent benchmark results in Codex; leave this as an explicit runtime-gated subtask if WoW profiling is unavailable.

## Phase 5 validation

Verify:

- repeated unchanged Inventory show/hide/show does not rebuild display snapshot;
- repeated unchanged Profile show/hide/show does not recompute active page data;
- tab switching refreshes a stale page once;
- hidden pages do no rendering work on unrelated mutation;
- Equipment page does no mount/pet enumeration in character scope;
- UI values remain identical to pre-refactor behavior.

---

# 12. Phase 6 — Cooperative TaskQueue slicing

## Files

```text
core/internal/tasks/TaskQueue.lua
core/debug/Timings.lua
Commands.lua
client/client_Event.lua
client/client_Traits.lua
client/spellcasting/AuraManager.lua
client/spellcasting/Lifecycle.lua
core/internal/profile/Profile.lua
client/character/inventory/Inventory.lua
```

## 12.1 Preserve normal jobs

Keep:

```lua
Tasks:Enqueue(fn, ...)
```

for work proven to be small/bounded.

Do not automatically wrap every existing task in the new API.

## 12.2 Add explicit sliceable jobs

Implement an API equivalent to:

```lua
Tasks:EnqueueSliceable({
    label = "trait-runtime-refresh",
    state = state,
    step = function(jobState, deadlineMs)
        -- bounded work
        -- return true when complete
    end,
})
```

Also expose a helper equivalent to:

```lua
Tasks:ShouldYield(deadlineMs)
```

The scheduler still cannot pre-empt Lua. Therefore each converted step function must check its deadline inside collection loops and return continuation state before the budget is substantially exceeded.

## 12.3 Queue semantics

A sliceable job must retain:

```lua
kind = "sliceable"
label
state
step
```

On a slice:

- calculate the deadline from `MaxMilliseconds` / current time;
- invoke `step(state, deadline)`;
- if complete, remove the job;
- if incomplete, requeue it without losing state;
- preserve deterministic ordering/priority for gameplay-critical transitions;
- never run the complete unbounded loop merely because the job was deferred.

Normal queued jobs remain compatible.

## 12.4 Diagnostics

Expand `Tasks:GetStats()` with:

- total queued jobs;
- normal queued jobs;
- sliceable queued jobs;
- current/last slice label;
- total slices executed;
- optionally longest recent slice when timing diagnostics are active.

## 12.5 Convert known unbounded work

Convert, after tracing exact current functions:

- event startup trait runtime refresh/compilation;
- automatic trait aura synchronization;
- event aura synchronization;
- resolved trait/profile state refresh where collection size is unbounded;
- aura advancement when many entries are due;
- spell component/target execution in Phase 8;
- first-time Inventory snapshot construction if runtime profiling requires it;
- first-time Profile presentation construction if runtime profiling requires it;
- bulk reward work where a single authored reward set can be unbounded.

Do not use Lua coroutine yielding as a substitute for explicit retained operation state. Continuation state must be inspectable and must preserve deterministic effect/random ordering.

## Phase 6 validation

Create a development-only sliceable test job which processes a large synthetic count and verify through TaskQueue stats/timings that:

- it spans multiple flushes;
- each slice returns near the configured budget;
- normal jobs still execute;
- cancellation/error handling does not leave `Tasks.IsFlushing` or transition state stuck.

Remove any disposable synthetic command/test if it is not useful as ongoing diagnostics.

---

# 13. Phase 7 — Event lifecycle transitions and sparse step scheduling

## Files

```text
client/client_Event.lua
client/client_Traits.lua
client/client_Resources.lua
client/spellcasting/Core.lua
client/spellcasting/Cooldowns.lua
client/spellcasting/AuraManager.lua
client/spellcasting/Lifecycle.lua
client/spellcasting/Helpers.lua
client/client_Targeting.lua
client/ui/widgets/widget_ActionBar.lua
client/ui/widgets/widget_Event.lua
server/server_Event.lua          # only where host-side profiling identifies synchronous contribution
server/server_Session.lua        # only if required by actual current call path
```

## 13.1 Explicit client transition state

Add a local event transition record equivalent to:

```lua
Client.EventTransition = {
    kind = "starting" | "advancing" | "ending",
    eventId = ...,
    transactionId = ...,
    phase = ...,
}
```

Provide helpers rather than scattered table checks, e.g.:

```lua
Client:BeginEventTransition(kind, eventId, transaction)
Client:IsEventTransitionActive(eventId)
Client:EndEventTransition(eventId, transaction)
```

While a gameplay-critical transition is active:

- block new conflicting casts/targeting/action submissions;
- keep ordinary WoW/UI rendering responsive;
- do not rebuild the Event widget every slice;
- stale queued work must verify event ID/transition identity before mutating state.

Do not show a blocking loading screen.

## 13.2 Event startup

Keep the existing startup sequencing, but convert heavy phases to bounded sliceable work.

Required logical sequence:

```text
parse/apply event state
 -> prime action-bar metadata
 -> compile/refresh trait runtime
 -> sync automatic trait auras
 -> sync event auras
 -> refresh resolved state
 -> queue initial resource sync
 -> process consumable prompts
 -> mark ready / release transition
```

Reuse one startup context/snapshot across phases where possible. Do not recompute the same resolved Profile/trait data in each phase.

## 13.3 Event end

End processing must run in one outer Runtime transaction:

```text
mark ending
 -> process rpe_event_complete Achievement trigger
 -> resolve end-phase/consumable work
 -> finish reward/Profile/Inventory/currency mutations
 -> clear event runtime buckets
 -> commit
 -> queue one visual teardown
 -> release transition
```

Achievement updates/rewards must not enter `HandleLocalConfigurationChanged()`.

Cancel or ignore stale presentation jobs for the ended event.

## 13.4 Separate packet receipt from expensive consequences

Refactor `Client:HandleEventState()` so the addon-message handler performs only bounded immediate work:

- validate state;
- update/stage turn/tick numbers;
- determine whether the step changed;
- determine due work;
- begin the step transaction/transition;
- queue continuation.

Do not synchronously execute an unbounded spell/effect graph from the addon-message callback.

## 13.5 Preserve current ordering first

The current client order is approximately:

```text
AdvanceSpellcastState
 -> AdvanceCooldownState
 -> AdvanceAuraState
 -> turn presentation/cues
 -> turn-start resource regeneration
 -> movement synchronization
 -> tooltip/visual invalidation
```

Do **not** reorder these systems based only on the illustrative order in the PDD. Trace existing semantics and preserve the actual current authoritative order. Any intentional ordering change requires separate justification and correctness tests.

## 13.6 Spellcast due index

Replace full active-cast scans on every step with due scheduling.

When a cast entry is created/advanced, retain enough information to identify the turn/tick/absolute event step on which it next requires work/completes.

Do not invent a duration formula. Derive the schedule from the existing `IsCasterTurnOnTick`, `turnsElapsed`, `lastAdvancedTurnNumber`, `startedOnTurnNumber` behavior and validate against instant/multi-turn/NPC/player casts.

## 13.7 Cooldown active/due index

Track only units/spells with active:

- GCD;
- cooldown;
- charge recovery;
- lockout.

Do not enumerate all known/action-bar spell definitions merely to decrement active cooldown state.

Keep display metadata caches separate from runtime countdown state.

## 13.8 Aura due index

Retain current:

```text
byKey
runtimeByKey
auraKeysByTarget
```

Add due scheduling keyed by absolute event step or an equivalent deterministic key.

Applying/removing/refreshing an aura must update the due index. A step should query only auras due on that step.

When an aura's target-derived/control state changes, invalidate only the affected target/bucket where possible.

## Phase 7 validation

Test increasing counts of:

- units;
- traits;
- automatic/event auras;
- active cooldowns;
- simultaneous casts;
- many effects due on one step.

Verify transition locks reject conflicting RPE actions without freezing WoW and all stale jobs are event/revision guarded.

---

# 14. Phase 8 — Spell transaction and sliceable component execution

## Files

```text
client/spellcasting/Lifecycle.lua
client/spellcasting/Helpers.lua
client/spellcasting/Core.lua
client/spellcasting/Cooldowns.lua
client/spellcasting/AuraManager.lua
client/combat/Core.lua
client/combat/Events.lua
client/combat/Helpers.lua
client/combat/effects/*.lua            # only where direct presentation/network fan-out must be converted to ChangeSet marking
client/spellcasting/effects/*.lua      # same
client/client_CombatLog.lua
client/client_Resources.lua
client/client_Achievements.lua
```

Do not rewrite every effect module pre-emptively. Trace `DispatchComponentEffect` and modify only modules that currently trigger immediate broad presentation/network/state fan-out.

## 14.1 Reuse activation snapshot

Retain the existing activation snapshot machinery.

During a single cast start, do not repeat stable work such as:

- spell reference resolution;
- caster resolution;
- unchanged condition context;
- stable resource/stat resolution;
- target policy metadata.

Expand the snapshot only where current timing proves duplicate resolution.

Invalidate it using the narrow revisions which affect cast eligibility, not unrelated Profile state.

## 14.2 Cast start transaction

`OnSpellcastStart()` must join/create one Runtime transaction.

Authoritative start work remains ordered:

- validate active context;
- use activation snapshot;
- evaluate required conditions/aura cast restrictions;
- apply start costs;
- apply cooldown/GCD state;
- create cast entry or dispatch instant completion;
- record ChangeSet/network deltas;
- commit/continue.

Do not interleave broad UI refreshes between these steps.

## 14.3 Resumable component execution state

Refactor `ExecuteSpellComponentsForPhase()` into explicit operation state.

Conceptually retain:

```lua
{
    eventId,
    spellRef,
    phase,
    casterEventId,
    componentIndex,
    targetIndex,
    resolvedTargets,
    combatEventState,
    pendingDamage,
    accumulatedResults,
    transactionId,
}
```

Requirements:

- component order is identical to current behavior;
- target order is identical;
- already-resolved random/proc/dice outcomes are stored if a slice yields after resolving them;
- a component is never re-applied because a continuation resumes;
- a multi-target component resumes at the correct target;
- the operation stops near the TaskQueue deadline;
- the actor/event remains transition-locked until authoritative completion.

Provide a synchronous compatibility wrapper only for call sites proven bounded or tests; gameplay completion should use the sliceable path when authored component/target count can grow.

## 14.4 Completion transaction

Spell completion must conceptually execute:

```text
resolve caster/spell/targets
 -> validate completion context
 -> apply end costs
 -> execute ordered component slices
 -> process resulting auras/traits/Achievements/resources/deaths
 -> drain transaction mutation events
 -> commit once
 -> send allowed consolidated deltas
 -> queue targeted presentation once
```

If completion is triggered by `AdvanceSpellcastState()`, it must remain part of the enclosing event-step transaction rather than creating a second independently committed transaction.

## 14.5 Presentation isolation

Replace immediate repeated presentation inside effect dispatch with ChangeSet dirty marking for:

- Event portraits;
- Action Bar slots/resources;
- targeting widget;
- visible tooltips;
- floating combat text;
- combat log flush where aggregation is semantically valid.

Continue using the existing dirty/targeted refresh mechanisms in `client/spellcasting/Helpers.lua`.

Do not delay combat-log ordering in a way which reorders entries. Queueing is acceptable; semantic order must remain stable.

## 14.6 Network batching

Where existing protocol semantics support it:

- combine multiple resource deltas for the same unit/transaction;
- prefer existing event delta-batch opcodes;
- send after the authoritative transaction result exists;
- keep required packet order stable.

UI-only dirtiness must never generate network traffic.

## Phase 8 validation

Test:

- instant spell;
- multi-turn spell;
- start-cost/end-cost spell;
- multi-component spell;
- multi-target spell;
- aura application/removal;
- interrupt;
- proc/trait effects;
- cast completion caused by Advance Turn;
- kill -> Achievement completion -> item/currency reward chain.

For deterministic comparison, use the same input state and random-roll sequence before/after where practical.

---

# 15. Phase 9 — Memory/GC cleanup and hot-path allocation reduction

Do this after the architectural phases so allocation cleanup does not obscure correctness changes.

## Audit targets

Search hot paths for:

- `deepCopy` of immutable definitions;
- repeated normalization of already canonical data;
- repeated construction of temporary arrays solely for filtering;
- repeated search-index string creation;
- repeated cloned stat/resource row lists consumed read-only;
- large transition/snapshot tables retained after completion.

Required changes:

- share immutable cached dataset definitions safely;
- cache stable modification/search signatures;
- reuse scratch tables only where ownership is clear and no caller retains them;
- clear completed transition continuation state;
- do not manually force Lua garbage collection during gameplay.

Do not micro-optimize unrelated editor paths.

---

# 16. Phase 10 — Cleanup, regression guards and final acceptance

## 16.1 Remove obsolete broad refresh paths

After all call sites are migrated:

- remove helpers used only by old synchronous Inventory/Profile refresh storms;
- remove redundant caches superseded by explicit revision caches;
- remove stale immediate listener fan-out;
- remove unused timing compatibility helpers only if no caller remains.

Do not remove `HandleLocalConfigurationChanged()`; it is still required for genuine configuration changes.

## 16.2 Add regression guards

In development/debug paths, detect obvious violations such as:

- runtime-only reason reaching global configuration change;
- UI refresh requested while owning window/page is hidden without merely marking dirty;
- sliceable step repeatedly exceeding its target budget;
- stale event transition continuation trying to apply to a different event/revision.

Warnings must not spam normal users when debug timing/internal logging is disabled.

## 16.3 Repository-wide searches

Before considering implementation complete, search for:

```text
notifyConfigurationChanged("profile-currency")
notifyConfigurationChanged("profile-achievements")
notifyConfigurationChanged("profile-achievement-rewards")
HandleLocalConfigurationChanged(
Inventory.GetDisplayItems(
Inventory.GetItems(
:Refresh()
C_Timer.After(0
```

For the broad searches, inspect results rather than blindly deleting them. The goal is to identify old hot-path usage, not prohibit valid calls globally.

Also search Profile page `Build()` implementations and verify they no longer perform duplicate refreshes.

## 16.4 Static validation

If `luac` is installed in the development environment, run `luac -p` over every modified Lua file.

If not, use VSCode Lua Language Server diagnostics and manually inspect:

- unmatched `end`;
- accidental method/function calling-convention changes (`.` vs `:`);
- load-order references;
- renamed functions with stale callers;
- nil module access during TOC initialization.

Do not add a new external build/test dependency solely for this task.

---

# 17. Manual in-game performance validation

Codex cannot legitimately mark the performance acceptance criteria complete unless these scenarios are run in WoW.

Enable diagnostics:

```text
/rpe debug timings on
/rpe debug perf
/rpe debug tasks
```

Use the PDD budgets as the acceptance thresholds.

## 17.1 Currency matrix

Test:

- builtin currency;
- custom currency;
- no matching Achievement;
- one matching Achievement;
- multiple completions;
- reward grants more currency;
- Profile open;
- Inventory open;
- active event.

Verify:

- exact balances/progress;
- `ConfigurationRevision` unchanged;
- no recipe knowledge rebuild;
- no client-connect refresh;
- immediate currency mutation <= PDD budget.

## 17.2 Inventory matrix

Use approximately 10, 50 and 150+ stacks.

Test add/overflow/non-stack/remove/delete/bind/modification/bulk reward/open/search/filter.

Verify:

- normal read does not normalize all records;
- one display snapshot build per revision;
- unchanged reopen reuses snapshot;
- normal single add remains within budget.

## 17.3 Profile matrix

For every tab:

- first open;
- close/reopen unchanged;
- mutate relevant state;
- mutate unrelated state;
- switch tabs.

Verify one dirty refresh and no hidden-tab render work.

## 17.4 Event matrix

Increase:

- units;
- traits;
- automatic/event auras;
- cooldowns;
- casts;
- simultaneous due effects.

Verify no RPE-caused frame exceeds 16 ms and transition controls reject conflicting actions cleanly.

## 17.5 Spell matrix

Test all cases listed in Phase 8 and compare final authoritative state/log order.

## 17.6 Stress transaction

Construct the PDD stress chain:

```text
spell completion
 -> damage
 -> kill
 -> Achievement completion
 -> item reward
 -> currency reward
 -> dependent Achievement progress
 -> aura removal
 -> cooldown update
```

Verify:

- one outer transaction;
- one consolidated Inventory post-commit notification;
- one consolidated Achievement post-commit notification;
- one currency ChangeSet;
- targeted event visuals;
- no global configuration refresh;
- deterministic final state.

---

# 18. Performance acceptance gates

The implementation is not complete until the PDD acceptance criteria are satisfied.

Critical gates for Codex to preserve during every phase:

- [ ] Ordinary currency changes do not reach global configuration refresh.
- [ ] Achievement progress/reward state does not reach global configuration refresh.
- [ ] Ordinary Inventory mutations do not reach global configuration refresh.
- [ ] `ConfigurationRevision` remains authored/configuration-scoped.
- [ ] Inventory reads do not normalize/write the full Inventory.
- [ ] Normal `AddItem()` does not `GetItems()` + `SetItems()` the full list.
- [ ] Inventory display resolution occurs once per relevant revision snapshot.
- [ ] Hidden Inventory/Profile pages do not render on unrelated mutation.
- [ ] Unchanged Inventory/Profile reopen is a fast revision check + visibility operation.
- [ ] Achievement reward chains commit/notify once.
- [ ] TaskQueue has genuine cooperative sliceable jobs.
- [ ] No converted slice processes an unbounded collection without deadline checks.
- [ ] Event startup heavy phases use sliceable continuation state.
- [ ] Event-step runtime uses due-work indexes instead of broad inactive-state scans where designed.
- [ ] Spell component/target processing can resume across frames without reordering/reapplying effects.
- [ ] Random/proc results are not rerolled after yielding.
- [ ] UI presentation is coalesced after authoritative changes.
- [ ] UI-only dirtiness does not create network traffic.
- [ ] SavedVariables remain backwards compatible.
- [ ] Existing gameplay results remain unchanged.
- [ ] Runtime timings meet the PDD budgets in the manual matrix.

---

# 19. Recommended Codex phase workflow

Do not ask Codex to make the entire cross-cutting refactor as one undifferentiated patch. Use this document as the source of truth and execute one phase at a time in the same working tree.

For each phase, Codex should:

1. re-read the phase and the corresponding PDD section;
2. inspect current target files and callers;
3. state the concrete call path being changed before editing;
4. implement the smallest complete architecture for that phase;
5. search for stale old-path callers;
6. run available static validation;
7. report manual WoW validation still outstanding;
8. only then proceed to the next phase.

Suggested phase boundaries for commits/PRs, if commits are being used:

```text
1. performance instrumentation
2. runtime transactions + revision domains + config separation
3. transactional Achievements/rewards
4. Inventory canonicalization/index/snapshot
5. Inventory/Profile dirty UI
6. cooperative TaskQueue
7. event transitions + due scheduling
8. spell component transaction/slicing
9. memory/GC cleanup
10. regression hardening
```

Do not squash the reasoning boundaries while implementing locally; if a later phase regresses behavior, these boundaries make the source of the regression much easier to isolate.

---

# 20. Coding-agent completion report format

At the end of each phase, report:

```text
Phase completed:

Files changed:
- ...

Exact old hot path removed/replaced:
- ...

New runtime/revision/transaction behavior:
- ...

Gameplay invariants preserved:
- ...

Static validation performed:
- ...

Repository searches performed:
- ...

Manual WoW validation still required:
- ...
```

Do not report a performance target as passed unless measured in the WoW client.

---

# 21. Final coding-agent instruction

Use current `FrontierDev/rpe2` as authoritative. This implementation is intended for **5.6-Luna-ExtraHigh** in the VSCode Codex plugin. Read both `.docs/RPE2-Runtime-Performance-Hitch-Elimination-PDD.md` and this implementation plan before editing.

The central invariant is:

> **Runtime state changes must remain narrow, transactional and revision-driven. They must not rebuild unrelated configuration or synchronously fan out presentation work.**

Trace callers before changing APIs. Preserve gameplay/network ordering. Extend the existing TaskQueue, timing infrastructure, resolved Profile caches, and spellcasting dirty-UI system rather than replacing them with parallel frameworks. Implement explicit continuation state for any loop whose cost scales with authored/runtime collection size. Keep SavedVariables compatible. Do not claim in-game performance acceptance until the defined timing matrix has actually been run.