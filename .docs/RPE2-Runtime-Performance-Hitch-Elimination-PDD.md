# RPE 2 — Runtime Performance and Hitch Elimination
## Product Design Document

**Status:** Proposed  
**Target:** RPEngine 2.0 (`FrontierDev/rpe2`)  
**Scope:** Runtime mutation architecture, Profile/Inventory refresh behavior, Achievements, event lifecycle, turn advancement, spellcasting, auras, cooldowns, task scheduling, UI invalidation, runtime synchronization, performance instrumentation  
**Primary objective:** Eliminate user-visible freezes and lag spikes caused by RPE runtime operations while preserving gameplay behavior and data compatibility  
**Out of scope:** New gameplay features, visual redesigns, ruleset changes, dataset schema redesign unrelated to performance

---

# 1. Purpose

RPE 2 currently produces noticeable game freezes or frame-time spikes during several common operations:

- starting an event;
- ending an event;
- advancing an event turn/tick;
- starting spellcasting;
- completing spellcasting;
- opening Inventory;
- opening Profile;
- receiving items;
- receiving currencies.

These are not independent problems. They are manifestations of the same architectural issue: **small runtime changes frequently trigger work at a much broader scope than the data that actually changed**.

Examples in the current codebase include:

- a currency balance mutation being routed through the global configuration-change pipeline;
- Achievement progress persistence being routed through the same global configuration-change pipeline;
- an Inventory mutation causing complete inventory normalization, complete display re-resolution and synchronous listener fan-out;
- Inventory refresh resolving the same inventory several times in one refresh pass;
- Profile pages refreshing repeatedly during one window-open operation;
- event state advancement synchronously advancing spellcasts, cooldowns and aura state together;
- spell completion executing every component and its downstream effects synchronously;
- deferred TaskQueue jobs still being indivisible functions which may themselves block the frame for tens of milliseconds.

The required fix is therefore not to add isolated `C_Timer.After(0, ...)` calls around individual slow functions. The runtime must be changed so that:

1. authored configuration and mutable character/gameplay state have separate invalidation domains;
2. state mutations emit narrow, typed change information;
3. dependent systems refresh only what is actually dirty;
4. repeated read-side work is revision-cached;
5. related mutations are committed and notified as one transaction;
6. potentially unbounded work can be cooperatively sliced across frames;
7. authoritative gameplay ordering remains deterministic while presentation and derived-state work are deferred safely;
8. every critical user action has a measurable frame-time budget.

This document defines that target architecture and the changes required to reach it.

---

# 2. Product Goals

## 2.1 Primary goals

The implementation must:

- remove visible freezes from the listed user interactions under normal and high-content test cases;
- prevent runtime state changes from rebuilding unrelated configuration-derived systems;
- keep user input, camera movement and normal WoW rendering responsive while RPE performs large operations;
- make Inventory and Profile opening effectively constant-cost when their underlying state has not changed;
- prevent the cost of a single item or currency grant from scaling with unrelated RPE systems;
- prevent event turn advancement from performing unnecessary scans over inactive runtime state;
- preserve the exact logical ordering of spell, aura, cooldown, resource and Achievement effects;
- batch downstream UI and synchronization work so one gameplay transaction produces one coherent refresh;
- provide profiling data sufficient to prove that the hitching has been removed.

## 2.2 Non-goals

The implementation must not:

- change spell damage, healing, targeting, resource cost or cooldown rules;
- change Achievement criteria or reward semantics;
- change Inventory item ownership or stacking semantics;
- change event authority or network authority rules;
- change Profile or Inventory persistence formats unless required for a backwards-compatible cache/index field;
- hide slow work behind artificial loading screens where the same work can instead be made incremental;
- rely on increasing the TaskQueue frame budget as the primary solution.

---

# 3. Performance Success Criteria

Performance must be treated as a product requirement rather than a subjective improvement.

## 3.1 Frame-time budgets

The following budgets apply on a typical supported WoW client with RPE internal debug logging disabled:

| Operation | Required synchronous main-thread cost | Completion requirement |
|---|---:|---|
| Add one inventory item | <= 4 ms target, <= 8 ms hard threshold | State committed immediately; presentation may update on the next frame |
| Add one currency value | <= 2 ms target, <= 4 ms hard threshold | Balance committed immediately; dependent Achievement/UI updates may be queued |
| Open already-built Inventory with unchanged state | <= 4 ms | Window visible in the same frame |
| Open already-built Profile with unchanged state | <= 4 ms | Window visible in the same frame |
| First Inventory/Profile construction | No individual frame may exceed 16 ms because of RPE | Construction may span multiple frames |
| Start/end event | No individual frame may exceed 16 ms because of RPE | Event may enter a short `transitioning` state while chunked work completes |
| Advance event step | <= 8 ms immediate work; no RPE frame > 16 ms | Ordered runtime consequences may complete across subsequent frames |
| Start/complete spellcast | <= 8 ms immediate work; no RPE frame > 16 ms | Authoritative transaction completes before another conflicting RPE action is accepted |
| TaskQueue slice | <= 2 ms target | Incomplete jobs continue on a later frame |

A 16 ms hard threshold is used because a single RPE operation exceeding one 60 Hz frame budget is directly capable of producing visible hitching. Normal target costs are lower to leave headroom for WoW itself and other addons.

## 3.2 Scaling requirements

Performance must degrade with the amount of data directly relevant to the operation, not with total unrelated addon state.

Examples:

- changing `valor` must not scan Inventory, rebuild recipe knowledge or rebuild the Action Bar;
- adding an item must not re-resolve every visible Inventory category more than once for the resulting inventory revision;
- refreshing the Equipment page must not enumerate mounts while the character scope is selected;
- advancing a turn must not inspect cooldown entries which cannot change on that step;
- an aura tick must not require scanning all auras to find those attached to an unrelated target if an index already identifies the relevant entries.

---

# 4. Current Architecture and Root Causes

# 4.1 Global configuration invalidation is used for runtime state

The highest-impact current path is in `core/internal/database/Database.lua`.

`Database.SetProfileCurrencyAmount()` currently performs:

```text
SetProfileCurrencyAmount
  -> mutate profile.currencies
  -> notifyConfigurationChanged("profile-currency")
  -> ConfigurationRevision++
  -> QueueLocalConfigurationRefresh
  -> Client:HandleLocalConfigurationChanged
```

`Client:HandleLocalConfigurationChanged()` in `client/client_Session.lua` performs broad work including:

- recipe skill index access/rebuild;
- persisted recipe knowledge rebuild;
- resolved Profile bootstrap warming;
- active-event trait activation/refresh;
- automatic trait aura synchronization;
- resolved trait state refresh;
- Achievement index rebuild;
- visible Profile refresh;
- Inventory refresh;
- Action Bar build/show/refresh;
- client resource synchronization;
- client-connect refresh.

The same global invalidation is currently used by:

- `profile-currency`;
- `profile-achievements`;
- `profile-achievement-rewards`;
- other mutable Profile fields which do not necessarily represent authored configuration.

This makes ordinary gameplay state changes invalidate caches whose inputs have not changed.

## Required correction

`ConfigurationRevision` must represent **configuration/definition changes only**.

Mutable runtime/profile state must use independent revisions and typed change notifications.

---

# 4.2 Inventory mutation repeatedly normalizes and scans the complete inventory

`client/character/inventory/Inventory.lua` currently performs several whole-list passes for a normal add:

```text
Inventory.AddItem
  -> NormalizeInventoryItem(new record)
  -> resolveItemDefinition
  -> Inventory.GetItems
       -> normalize every stored record
  -> canStackRecord
       -> resolve item definition
  -> scan stacks
       -> normalize records repeatedly
       -> deepEqual modifications
  -> Inventory.SetItems
       -> normalize every record again
  -> notifyChangeListeners synchronously
```

The read APIs also mutate/normalize storage repeatedly. This makes a read operation proportional to total inventory size even when nothing has changed.

## Required correction

Inventory records must be canonicalized at migration/load and mutation boundaries, not every read. Mutation must be incremental, and display resolution must be cached by revision.

---

# 4.3 Inventory UI recomputes the same display data repeatedly

`InventoryGridPage:Refresh()` currently obtains Inventory-derived state separately for:

- filter item construction;
- category item count;
- filtered display item construction;
- currency/UI refresh.

`GetCategoryDisplayItems()` calls `Inventory.GetDisplayItems()`, while `GetFilteredDisplayItems()` calls `GetCategoryDisplayItems()` again. The same complete inventory can therefore be normalized/resolved multiple times in one page refresh.

`InventoryWindow:Refresh()` also refreshes every built Inventory/Consumables/Reagents page rather than only the visible page or pages whose data is dirty.

## Required correction

One immutable/revisioned Inventory display snapshot must be built per relevant revision and shared by all page computations. Hidden pages must be marked dirty and refreshed only when shown.

---

# 4.4 Profile opening performs redundant refreshes

The Profile window already benefits from lazy tab building through `TabContainer`, but the active page can still refresh several times during one open:

```text
Tab builder
  -> page:Build()
       -> page:Refresh()
  -> builder page:Refresh()

ProfileWindow:Show()
  -> ProfileWindow:Refresh()

page OnShow
  -> RefreshTab()
```

`page_ProfileEquipmentStats.lua` then resolves stat rows, resources, layout data, equipment headers, slot presentation and other derived state.

## Required correction

There must be one owner for initial refresh. `Build()` constructs controls only; visibility/tab activation decides whether a refresh is required from revision state.

---

# 4.5 TaskQueue time limits do not protect against a slow individual job

`core/internal/tasks/TaskQueue.lua` currently limits:

- number of jobs executed per flush;
- elapsed time checked between jobs.

A job is nevertheless executed as:

```lua
job.fn(...)
```

and cannot be interrupted. A queued 80 ms function still stalls the game for 80 ms before the scheduler observes that the time budget was exceeded.

## Required correction

Potentially unbounded jobs need a cooperative continuation/slice API. The scheduler must call a bounded `Step()` which processes only part of the work and returns whether it is complete.

---

# 4.6 Event step handling combines several runtime systems

`client/client_Event.lua::HandleEventState()` currently advances:

```text
AdvanceSpellcastState
AdvanceCooldownState
AdvanceAuraState
turn announcements
local-turn cues
resource regeneration
movement synchronization
Tooltip/context invalidation
visual refresh work
```

`AdvanceSpellcastState()` can call `OnSpellcastComplete()` during this process. The apparent "Advance Turn" spike can therefore include full spell completion and all effects caused by the spell.

Cooldown advancement scans tracked cooldown state. Aura advancement scans active aura entries to determine which work is due.

## Required correction

Event-step processing must become a deterministic transaction with sparse indexes for work due on the current step. Expensive work must be sliceable while the transaction prevents conflicting RPE actions until completion.

---

# 4.7 Spell completion executes an unbounded effect graph synchronously

`client/spellcasting/Lifecycle.lua::ExecuteSpellComponentsForPhase()` iterates spell components for the relevant phase. Each component can resolve targets and dispatch effects which may cause further:

- damage/healing;
- resource changes;
- aura application/removal;
- trait dispatch;
- combat log entries;
- death processing;
- Achievement progress;
- UI invalidation;
- network synchronization.

Although presentation work has already begun moving toward dirty/targeted refreshes in `client/spellcasting/Helpers.lua`, the authoritative effect graph and downstream mutations still produce too much immediate fan-out.

## Required correction

Spell resolution must operate inside a mutation transaction. Components may be evaluated in ordered slices, but dependent notifications/UI/network flushes must occur once after the authoritative transaction is complete.

---

# 4.8 Achievement processing amplifies runtime mutations

`client/client_Achievements.lua` correctly indexes criteria by trigger, but committing progress currently persists state per affected Achievement. Persistence calls `notifyConfigurationChanged("profile-achievements")`.

Achievement completion can then:

- process `achievement_earned` criteria recursively;
- announce the achievement;
- deliver rewards;
- grant items/currencies;
- cause further runtime mutations.

Event start, event end, currency gain and item gain all interact with this path.

## Required correction

Achievement runtime progress is mutable Profile state, not configuration. Processing must batch all progress changes for one trigger transaction, persist them without global configuration invalidation, recursively resolve dependent achievements, deliver rewards in the same transaction, then emit one consolidated dirty-state notification.

---

# 5. Target Architecture

The target runtime architecture consists of five layers:

```text
Authoritative mutation
        |
        v
Runtime Transaction / ChangeSet
        |
        +--> narrow state revisions
        +--> narrow typed notifications
        +--> derived-cache invalidation
        |
        v
Deferred/sliced derived-state work
        |
        v
Coalesced presentation + network flush
```

The key rule is:

> **A runtime mutation must never invoke a global configuration rebuild unless the mutation actually changes authored configuration or a definition that is an input to that configuration.**

---

# 6. Revision Domains

Introduce explicit revision domains. These may be held under a new internal runtime table or on the owning subsystem, but they must have stable accessors and clear ownership.

Required domains:

```lua
ConfigurationRevision       -- existing; authored definitions/configuration only
ProfileStateRevision        -- generic character runtime/profile state
CurrencyRevision
AchievementRevision
InventoryRevision
EquipmentRevision
SkillRevision
ActionBarBindingRevision
ResolvedProfileRevision     -- derived snapshot version
EventRuntimeRevision
AuraRevisionByEventId
CooldownRevisionByEventId
SpellcastRevisionByEventId
```

Not every revision needs to be persisted. Most should be in-memory monotonic counters reset on `/reload`.

## 6.1 ConfigurationRevision may change for

Examples:

- dataset activation/deactivation;
- imported/edited dataset definitions;
- active ruleset changes;
- spell/trait/stat/resource definition changes;
- structural Profile choices which genuinely change the derivation graph and cannot be represented by a narrower revision.

## 6.2 ConfigurationRevision must not change for

Examples:

- currency amount changes;
- Achievement criterion progress;
- Achievement reward-delivery state;
- Inventory stack quantity changes;
- receiving/removing an item;
- current event resource values;
- cooldown countdown;
- active aura duration/stack changes;
- active spellcast progress;
- transient event unit health/resource changes.

---

# 7. Runtime Transactions and ChangeSets

Introduce a lightweight transaction/change accumulator shared by runtime systems.

A conceptual change set contains only changed scopes:

```lua
ChangeSet = {
    inventory = {
        changed = false,
        slots = {},
        addedRefs = {},
        removedRefs = {},
    },
    currencies = {
        changed = false,
        keys = {},
    },
    achievements = {
        changed = false,
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
        eventId = nil,
        units = {},
        auras = {},
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

The exact table shape may differ, but the following behavior is required:

1. nested systems can append changes to the current transaction;
2. a transaction can contain item + currency + Achievement reward effects without notifying listeners between each mutation;
3. commit increments only relevant revisions;
4. listeners receive one consolidated payload;
5. presentation refresh is queued after commit;
6. network synchronization is batched after commit where protocol semantics allow it;
7. recursive Achievement reward processing remains in the same outer transaction;
8. transaction failure must not leave the UI presenting a partially committed state.

A minimal API may be:

```lua
Runtime.BeginTransaction(reason)
Runtime.GetCurrentTransaction()
Runtime.MarkChanged(scope, detail)
Runtime.CommitTransaction()
Runtime.RunTransaction(reason, fn)
```

Subsystems must still be usable independently; if no transaction is active, they may create a short implicit transaction around the mutation.

---

# 8. Database and Profile State Changes

## 8.1 `Database.lua`

Refactor `notifyConfigurationChanged()` usage.

Create a narrow Profile/runtime notification path, for example:

```lua
notifyProfileStateChanged(reason, detail)
```

This path must **not** increment `ConfigurationRevision` and must **not** call `HandleLocalConfigurationChanged()`.

`SetProfileCurrencyAmount()` must:

```text
normalize value
mutate profile.currencies[key]
mark CurrencyRevision/ProfileStateRevision
append currency key to current ChangeSet
return
```

It must not rebuild recipe knowledge, traits, Achievement definitions, Inventory or Action Bar configuration.

The same rule applies to Achievement progress/reward state setters.

## 8.2 `client/client_Session.lua`

`HandleLocalConfigurationChanged()` must remain the heavyweight path for genuine configuration changes only.

It should no longer be part of normal gameplay mutation flows.

Where possible, split the current handler internally into named configuration refresh scopes so even genuine configuration changes can avoid unnecessary work where the cause is known.

For example:

```text
configuration.dataset
configuration.ruleset
configuration.profile-structure
```

This is secondary to removing runtime mutations from the handler, but should be completed during the same refactor to prevent future regression.

---

# 9. Inventory Runtime Redesign

## 9.1 Canonical stored records

`Inventory.GetItems()` must become a read operation.

Inventory normalization must happen during:

- SavedVariable initialization/migration;
- `SetItems()` bulk replacement;
- `AddItem()` input normalization;
- explicit record mutation functions.

It must not rewrite/renormalize the entire stored list on every read.

## 9.2 Incremental stack index

Maintain an in-memory stack index keyed by a stable stack identity:

```text
dataset:id | soulbound | modificationSignature
```

The modification signature must be computed deterministically once per normalized record or mutation, avoiding recursive `deepEqual()` comparisons against every stack during every add.

Index lifecycle:

- build once after inventory load/migration;
- update on add/remove/split/merge/modification/bind operations;
- invalidate/rebuild only after `SetItems()` or detected external/corrupt state replacement.

## 9.3 Incremental AddItem

`AddItem()` must:

1. normalize incoming record once;
2. resolve item definition once;
3. compute stack behavior/signature once;
4. query matching stack candidates from the index;
5. mutate only affected stack records;
6. append new stacks when required;
7. increment `InventoryRevision` once;
8. append one inventory change to the current transaction;
9. avoid a full `SetItems()` round trip.

## 9.4 Display snapshot cache

Create a cached display snapshot keyed by:

```text
InventoryRevision + ConfigurationRevision
```

The snapshot should resolve each inventory record to its dataset/item definition once and contain commonly used presentation/filter values.

Example:

```lua
{
    sourceIndex,
    record,
    datasetId,
    itemId,
    dataset,
    item,
    isActive,
    isMissing,
    soulbound,
    modifications,
    quantity,
    normalizedSearchText,
    quality,
    itemType,
    tags,
}
```

Search text should be built once per snapshot entry, not every search/refresh pass.

## 9.5 Listener behavior

Inventory listeners must be asynchronous/coalesced unless they are required to participate in the authoritative transaction.

Achievement item-gain handling should consume the transaction payload rather than force Inventory to synchronously execute every unrelated listener before `AddItem()` returns.

---

# 10. Inventory UI Redesign

## 10.1 One snapshot per refresh

`InventoryGridPage:Refresh()` must obtain the current display snapshot once and pass it to:

- category filtering;
- filter-facet construction;
- search filtering;
- empty-state calculation;
- slot presentation.

No helper called by one refresh may independently call `Inventory.GetDisplayItems()` again unless the revision changed during the operation.

## 10.2 Active-page refresh only

`InventoryWindow:Refresh()` must refresh only the active page.

For hidden built pages:

```text
Inventory mutation
  -> mark page dirty
  -> do not refresh hidden page

Tab becomes visible
  -> compare page revision with InventoryRevision
  -> refresh once if stale
```

## 10.3 Incremental slot updates

If a mutation payload identifies affected slots and filter/search membership cannot have changed globally, update only those visible slots.

A full page refresh is allowed when:

- an item is added/removed and sorting/filter membership may change;
- search/filter selection changes;
- ConfigurationRevision changes;
- a bulk Inventory replacement occurs.

Even a full page refresh must consume the cached display snapshot rather than re-resolve definitions.

## 10.4 First construction

Creation of the 48 grid slots may remain eager if profiling shows it is under budget. If not, create the window chrome immediately and build slots in bounded batches across frames before first interaction.

---

# 11. Profile UI Redesign

## 11.1 Single refresh ownership

Adopt the following lifecycle contract for every Profile page:

```text
Build(parent, owner)
  -> create controls only

On page activation / ShowTab
  -> RefreshIfDirty()
```

`Build()` must not call `Refresh()` unless the caller explicitly asks it to.

The window builder must not call a second refresh immediately after a page build.

`OnShow` must not cause an additional refresh if the page already refreshed for the current revision during the same activation.

## 11.2 Page revision tracking

Each page stores the revisions which affect it.

Examples:

- Equipment & Stats: `EquipmentRevision`, relevant Profile state revision, `ConfigurationRevision`;
- Spellbook: spellbook/action-bar/configuration revisions;
- Traits: trait/profile/configuration revisions;
- Skills: `SkillRevision`, `ConfigurationRevision`;
- Achievements: `AchievementRevision`, `ConfigurationRevision`.

`RefreshIfDirty()` returns immediately when all relevant revisions match the page's last-rendered revisions.

## 11.3 Profile presentation snapshot

Build and cache a Profile presentation/view-model snapshot containing expensive derived information used by multiple widgets:

- equipped item resolution;
- resolved stat rows;
- resolved resource rows;
- current race/class/level selectors;
- item-level summary;
- active scope presentation data.

Key the snapshot to the revisions that actually affect it.

## 11.4 Scope-specific work

`EquipmentStatsPage:RefreshEquipmentHeader()` must not construct mount choices while character scope is selected, nor pet choices while another scope is selected.

Mount/pet lists may be separately cached by their own collection/selection revisions.

## 11.5 Tooltip work

Expensive item/stat/trait/spell tooltip descriptions should be built lazily when the user hovers a control, or cached by the same stable revisions used by the description builders.

Opening Profile must not eagerly build tooltip descriptions that are not visible.

---

# 12. Achievement Runtime Redesign

## 12.1 Index lifecycle

`Achievements:RebuildIndex()` should remain configuration-derived.

The index may rebuild when:

- `ConfigurationRevision` changes in a way that affects activated datasets/Achievement definitions;
- explicit editor/import actions invalidate Achievement definitions.

It must not rebuild after Achievement progress, item gain or currency gain.

## 12.2 Batched trigger processing

For one trigger:

```text
ProcessTrigger
  -> read CriteriaByTrigger bucket
  -> evaluate matching criteria
  -> accumulate all changed Achievement states
  -> recursively resolve achievement_earned dependencies
  -> accumulate reward actions
  -> persist all changed state
  -> deliver rewards inside same outer Runtime transaction
  -> increment AchievementRevision once
  -> mark Achievements page dirty once
  -> queue announcements after commit
```

Do not call Profile UI refresh for every `_CommitState()`.

## 12.3 Reward transactions

Achievement rewards may grant multiple items/currencies.

All rewards from one completion chain must participate in one transaction so that:

- Inventory receives one consolidated change notification;
- currencies receive one consolidated change payload;
- dependent Achievements process deterministically;
- UI refresh occurs once;
- recursive reward completion cannot cause a refresh storm.

A cycle guard must prevent malformed Achievement dependency chains from recursively processing indefinitely.

---

# 13. TaskQueue Cooperative Slicing

## 13.1 Preserve existing bounded-job API

Existing `Tasks:Enqueue(fn, ...)` remains valid for known-small jobs.

## 13.2 Add sliceable jobs

Add a cooperative API, conceptually:

```lua
Tasks:EnqueueSliceable({
    label = "trait-runtime-refresh",
    state = state,
    step = function(jobState, deadlineMs)
        -- perform bounded work
        -- return true when complete
        return completed
    end,
})
```

Alternative iterator/continuation syntax is acceptable if it provides the same guarantees.

## 13.3 Scheduler guarantees

- a slice receives or can query its frame deadline;
- a slice should stop near 2 ms of RPE work;
- incomplete work is requeued for a later frame;
- priority/order can preserve gameplay sequencing;
- errors identify the job label and retained state;
- one sliceable job cannot monopolize the frame by processing its complete dataset;
- queue statistics expose both normal and sliceable pending work.

## 13.4 Convert unbounded loops

At minimum, evaluate and convert large loops in:

- event startup trait runtime compilation;
- automatic/event aura synchronization;
- resolved trait state refresh;
- aura advancement/ticks where many entries are due;
- spell component execution where authored spells contain many components/targets;
- first-time Inventory display snapshot construction;
- first-time complex Profile presentation construction;
- any bulk reward grant/import operation.

---

# 14. Event Lifecycle Redesign

## 14.1 Explicit transition state

Event startup, step advancement and teardown may require several frames. Introduce an explicit local runtime transition state:

```lua
EventTransition = {
    kind = "starting" | "advancing" | "ending",
    eventId = ...,
    transactionId = ...,
    phase = ...,
}
```

While a gameplay-critical transition is incomplete:

- the WoW client remains responsive;
- RPE controls which could produce conflicting authoritative actions are disabled;
- harmless UI remains interactive where possible;
- the event widget can show its existing state without rebuilding repeatedly;
- completion atomically publishes the resulting runtime/UI changes.

This is not a loading screen. Under normal conditions the transition should complete within a small number of frames.

## 14.2 Startup phases

Retain the current startup sequencing but make each potentially large phase sliceable:

1. parse/apply event state;
2. prime action bar metadata;
3. compile/refresh trait runtime;
4. synchronize automatic trait auras;
5. synchronize event auras;
6. refresh resolved state;
7. queue initial resource sync;
8. process consumable prompts;
9. mark event ready.

Do not repeatedly rebuild shared derived data between phases. Pass one startup context/snapshot forward where possible.

## 14.3 End event

End-event processing must:

1. mark the event as ending to reject new gameplay actions;
2. process `rpe_event_complete` Achievements in the same transaction;
3. resolve consumable/end-phase effects;
4. commit reward/inventory/currency/Profile changes once;
5. clear spellcast/cooldown/aura/trait runtime state using direct bucket removal, not broad scans where indexes permit;
6. queue one final visual teardown;
7. release the transition lock.

Achievement state changes during event end must not invoke `HandleLocalConfigurationChanged()`.

---

# 15. Turn Advancement Redesign

## 15.1 Separate state receipt from consequence processing

`HandleEventState()` should perform only bounded immediate work:

- validate the packet/state;
- update turn/tick identifiers;
- determine whether the step changed;
- determine which runtime work is due;
- begin an ordered event-step transaction.

It must not synchronously run every potentially expensive consequence to completion in the packet handler.

## 15.2 Sparse due-work indexes

Replace broad scans where practical with due-step indexes.

### Spellcasts

Maintain entries indexed by the turn/step on which they complete. Advancing a step should retrieve casts due now rather than scan every cast entry.

### Cooldowns

Track only cooldown units/spells with active countdown state. Maintain next-change/due information sufficient to avoid scanning inactive spell metadata.

### Auras

Maintain indexes by:

- target unit;
- next tick/expiry step;
- aura key.

The current `auraKeysByTarget` index should be retained and extended rather than replaced.

## 15.3 Ordered step phases

A step transaction must preserve current gameplay ordering. The exact order should be validated against existing behavior, but should conceptually include:

```text
receive step
 -> advance casts due on step
 -> complete casts due now
 -> apply spell effects
 -> advance/tick/expire auras due now
 -> advance relevant cooldowns
 -> apply turn-start resource regeneration where applicable
 -> movement/turn ownership updates
 -> commit ChangeSet
 -> queue UI/combat-text/announcement presentation
```

The implementation must preserve existing semantic order where it differs from this illustrative sequence.

---

# 16. Spellcasting Redesign

## 16.1 Activation snapshot reuse

The existing spell activation snapshot path should be retained and expanded so a cast start does not repeat:

- spell reference resolution;
- caster lookup;
- condition context construction;
- unchanged resource/stat resolution;
- target-policy metadata construction.

A valid snapshot should be reused through the start operation and invalidated only by revisions which affect cast eligibility.

## 16.2 Spell transaction

Starting/completing a spell must run inside a runtime transaction.

During completion:

1. resolve caster/spell/targets from cached or indexed state;
2. evaluate conditions once per required context;
3. apply end costs;
4. execute ordered components;
5. collect all resulting unit/resource/aura/trait/Achievement changes;
6. complete dependent authoritative effects;
7. commit once;
8. send consolidated resource/event deltas where possible;
9. queue targeted visuals once.

## 16.3 Sliceable component execution

`ExecuteSpellComponentsForPhase()` must be converted so authored component count and target count cannot create one unbounded frame.

A component execution state should retain:

```lua
{
    componentIndex,
    targetIndex,
    resolvedTargets,
    combatEventState,
    pendingDamage,
    accumulatedResults,
}
```

A slice processes work until its time budget is reached, then resumes next frame without changing component order.

Conflicting RPE casts/actions by that actor remain disabled until completion of the transaction.

## 16.4 Presentation isolation

Combat log, floating combat text, portrait refresh, Action Bar refresh, tooltip refresh and targeting refresh must not execute repeatedly inside component dispatch.

Component dispatch marks dirty scopes. Presentation consumes those dirty scopes after commit using the existing targeted refresh infrastructure in `client/spellcasting/Helpers.lua`.

---

# 17. Aura and Cooldown Runtime Redesign

## 17.1 Aura indexes

Retain:

- `byKey`;
- `runtimeByKey`;
- `auraKeysByTarget`.

Add/maintain a due-step structure for timed aura work. The precise structure may be a map from absolute event step to aura keys, a min-heap, or another ordered bucket appropriate for the small event size.

Requirements:

- applying/removing an aura updates the due index;
- stack/duration changes update the due index;
- step advancement queries the due bucket directly;
- aura definition/runtime resolution remains cached;
- target control-state caches invalidate only for affected targets;
- stat modifier totals invalidate only for affected aura bucket/target where possible.

## 17.2 Cooldown indexes

Cooldown state should track only spells with active relevant state:

- GCD remaining;
- cooldown remaining;
- charge recovery;
- lockout remaining.

Do not enumerate all known spells merely to advance existing cooldown state.

Action Bar spell metadata may remain separately cached for display/initialization.

---

# 18. UI Dirty-State Model

Extend the existing dirty-state approach in `client/spellcasting/Helpers.lua` into a common convention.

Every UI surface should have:

- an owning data revision or revision tuple;
- a dirty flag/set for targeted changes;
- one queued refresh token;
- coalescing behavior;
- a `RefreshIfDirty()` fast path.

Required behavior:

```text
10 mutations in one transaction
    -> 1 queued Inventory refresh
    -> 1 queued Achievement refresh
    -> targeted Event portraits
    -> 1 Action Bar refresh if required
```

Never:

```text
mutation
 -> refresh
mutation
 -> refresh
mutation
 -> refresh
```

for changes within the same transaction/frame.

Hidden windows/pages should become dirty but should not perform rendering work until visible.

---

# 19. Network Synchronization

This performance work must not weaken authoritative synchronization.

However, outbound state should be coalesced where existing protocol semantics permit it.

Requirements:

- one transaction may aggregate multiple resource deltas for the same unit;
- multiple event-unit changes should prefer existing delta-batch opcodes;
- UI-only cache invalidation must never produce network traffic;
- currency/Profile local persistence changes must not cause an unrelated client-connect refresh;
- configuration reconnect/hash refresh remains tied only to actual configuration changes;
- packet handlers should validate and stage heavy work rather than execute unbounded runtime graphs synchronously.

If a protocol currently requires several ordered packets, preserve packet order but construct/send them after authoritative transaction completion rather than interleaving expensive presentation refreshes between sends.

---

# 20. Memory and Garbage Collection

CPU work is not the only source of hitching. The current code frequently creates temporary normalized copies, arrays and strings which may produce garbage-collection spikes.

Required changes:

- do not deep-copy immutable dataset definitions on hot read paths;
- do not normalize already canonical Inventory records repeatedly;
- cache stable item modification signatures;
- reuse cached display/search strings until revision changes;
- reuse scratch arrays/tables in high-frequency runtime code where ownership is clear;
- avoid cloning complete resolved stat/resource lists solely for read-only UI consumption if an immutable snapshot can safely be shared;
- clear large transition/snapshot tables after completion so memory is reclaimable at predictable boundaries;
- do not force garbage collection manually during gameplay operations.

Instrumentation should record allocation-sensitive hot paths indirectly through call frequency/cardinality and optional Lua memory deltas during development builds.

---

# 21. Performance Instrumentation

The refactor must add enough timing coverage to detect regressions.

## 21.1 Required timed operations

Add timing scopes for:

- `Inventory.AddItem`;
- Inventory bulk mutation commit;
- Inventory display snapshot rebuild;
- `InventoryGridPage:Refresh`;
- `InventoryWindow:Show`;
- `ProfileWindow:Show`;
- each Profile page `RefreshIfDirty`;
- `EquipmentStatsPage` view-model rebuild;
- `Achievements:ProcessTrigger`;
- Achievement reward-chain completion;
- `Client:HandleLocalConfigurationChanged`;
- event start total and each startup phase;
- event end total and phases;
- event-step immediate handler;
- cast advancement;
- cooldown advancement;
- aura advancement;
- spell start;
- spell complete;
- spell component execution slices;
- visual refresh flush;
- network delta flush.

## 21.2 Cardinality data

Slow-operation logs must include relevant size information, for example:

```text
inventoryStacks=142
resolvedItems=142
achievementCriteria=18
changedAchievements=3
eventUnits=10
activeAuras=24
dueAuras=2
activeCooldowns=7
activeCasts=2
spellComponents=6
targetCount=5
queuedTasks=12
```

Without cardinality, elapsed-time logs are insufficient to identify scaling regressions.

## 21.3 Slow thresholds

Development instrumentation should flag:

- > 4 ms for normally cheap runtime mutations;
- > 8 ms for user-action immediate paths;
- > 2 ms for a cooperative task slice;
- > 16 ms for any single RPE-induced frame of work.

Existing `Debug.Timings` and spellcast timing infrastructure should be extended rather than replaced.

---

# 22. Required Code Areas

The implementation is expected to touch at least the following areas.

## Core/runtime

```text
core/internal/database/Database.lua
core/internal/profile/Profile.lua
core/internal/profile/Currencies.lua
core/internal/tasks/TaskQueue.lua
```

Potential new module:

```text
core/internal/runtime/RuntimeTransaction.lua
```

or an equivalent location consistent with existing internal architecture.

## Inventory

```text
client/character/inventory/Inventory.lua
client/character/inventory/window_Inventory.lua
client/character/inventory/page_Inventory*.lua
```

The actual shared page module used by Inventory/Consumables/Reagents should own the snapshot-based refresh logic.

## Profile

```text
client/character/profile/window_Profile.lua
client/character/profile/page_ProfileEquipmentStats.lua
client/character/profile/page_ProfileTraits.lua
client/character/profile/page_ProfileSkills.lua
client/character/profile/page_ProfileAchievements.lua
client/character/profile/page_ProfileSpellbook.lua
```

Only files present/used by the current repository should be modified; names above describe the logical pages and should be mapped to the actual current paths.

## Achievements

```text
client/client_Achievements.lua
client/client_AchievementRewards.lua
```

## Events / combat runtime

```text
client/client_Event.lua
client/client_Traits.lua
client/client_Resources.lua
client/spellcasting/Core.lua
client/spellcasting/Lifecycle.lua
client/spellcasting/Helpers.lua
client/spellcasting/Cooldowns.lua
client/spellcasting/AuraManager.lua
```

Server event code should be modified only where profiling shows host-side synchronous construction/broadcast work is a contributor:

```text
server/server_Event.lua
server/server_Session.lua
```

Use the repository's actual current file names when implementing.

---

# 23. Compatibility Requirements

## 23.1 SavedVariables

Existing Profile and Inventory data must continue to load without user migration steps.

Runtime indexes/revisions should normally be rebuilt in memory and not persisted.

If a persisted schema change is unavoidable:

- increment the relevant schema version;
- migrate old data automatically;
- preserve all item quantities, soulbound state, modifications, currencies and Achievement progress;
- make migration idempotent.

## 23.2 Addon API behavior

Existing public/internal call sites such as `Inventory.AddItem()` and `Profile.AddCurrencyAmount()` should preserve their return values unless a change is explicitly required and all callers are updated.

Do not force feature code to understand the full transaction system. Implicit short transactions should keep ordinary call sites simple.

## 23.3 Gameplay semantics

For a given input state and random-roll sequence, the refactored runtime must produce the same authoritative gameplay result as the current implementation.

Frame slicing may change when presentation becomes visible by a small number of frames, but must not change:

- effect ordering;
- target selection;
- proc chance results;
- damage/healing results;
- aura ordering;
- resource amounts;
- cooldown results;
- Achievement progression;
- reward quantities;
- network authority.

Random rolls must not be re-evaluated because a job yielded. State required to resume a sliced operation must include any already-resolved random result.

---

# 24. Failure and Re-entrancy Rules

Performance fixes must not introduce race-like behavior within the single-threaded Lua runtime.

Required rules:

- only one gameplay-critical transaction for a given event/caster may mutate the same authoritative state at a time;
- queued presentation work may coalesce freely;
- a sliceable authoritative operation must retain a stable transaction/context until completion;
- event end cancels or safely drains obsolete queued event presentation jobs;
- stale jobs must verify expected event ID/revision before applying work;
- an Inventory/Profile window opened while a snapshot rebuild is in progress may display the previous valid snapshot briefly, then refresh on commit; it must never read a half-built snapshot;
- configuration changes invalidate runtime-derived snapshots atomically and may cancel/restart incompatible background rebuild work.

---

# 25. Implementation Phases

The work should be implemented in the following order because later phases depend on the invalidation model established earlier.

## Phase 1 — Instrumentation and baselines

- add missing timers/cardinality logs;
- record current timings for all reported lag-spike operations;
- add a development command or debug helper to print recent slow operations and TaskQueue stats;
- do not optimize behavior yet except where instrumentation requires safe hooks.

**Exit condition:** every reported hitch can be attributed to timed phases rather than inferred from user perception.

## Phase 2 — Separate runtime state from configuration

- remove currency/Achievement runtime state from `notifyConfigurationChanged()`;
- add narrow runtime/Profile revisions;
- add typed ChangeSet notification infrastructure;
- ensure `HandleLocalConfigurationChanged()` runs only for genuine configuration changes;
- remove unrelated client-connect/resource-sync work from ordinary Profile runtime mutations.

**Expected impact:** major reduction in item/currency/Achievement/event start/end spikes.

## Phase 3 — Transactional Achievements and rewards

- batch criteria updates;
- remove per-Achievement UI refresh;
- keep reward chains in one outer transaction;
- add cycle protection;
- emit one post-commit Achievement/UI notification.

**Expected impact:** prevents reward and event-completion refresh storms.

## Phase 4 — Inventory canonicalization and snapshot cache

- make `GetItems()` read-only;
- normalize on mutation/load only;
- add stack index/signature;
- make `AddItem()` incremental;
- add `InventoryRevision`;
- build/cache one display snapshot per revision;
- consume one snapshot per UI refresh.

**Expected impact:** removes Inventory open and item-receive scaling problems.

## Phase 5 — Profile/Inventory UI dirty refresh

- remove duplicate build/show/OnShow refreshes;
- refresh only active pages;
- add page revision tracking;
- add cached Profile presentation snapshot;
- lazily build expensive tooltip/pet/mount data.

**Expected impact:** removes window-open hitching.

## Phase 6 — Cooperative TaskQueue

- add sliceable jobs/continuations;
- enforce per-slice timing;
- expose queue diagnostics;
- convert existing large deferred jobs.

**Expected impact:** prevents a single queued startup/runtime job from freezing a frame.

## Phase 7 — Event-step sparse scheduling

- add explicit transition state;
- index due spellcasts/cooldowns/auras;
- remove broad scans where possible;
- execute ordered consequences through sliceable event transactions;
- keep visuals coalesced until commit.

**Expected impact:** removes Advance Turn hitching and large event-start/end stalls.

## Phase 8 — Spell component transaction and slicing

- convert component execution to resumable ordered state;
- accumulate effect/UI/network deltas;
- flush once after completion;
- preserve random/effect ordering across yields.

**Expected impact:** removes cast start/end spikes for complex spells and multi-target effects.

## Phase 9 — Cleanup and regression hardening

- remove obsolete broad refresh helpers/call sites;
- remove duplicate caches made unnecessary by the new revision model;
- document revision ownership;
- add performance regression tests/manual scenarios;
- verify no normal runtime action reaches `HandleLocalConfigurationChanged()` unexpectedly.

---

# 26. Test Matrix

Testing must cover correctness and frame-time behavior together.

## 26.1 Currency tests

- grant one builtin currency;
- grant one custom dataset currency;
- grant currency which advances no Achievement;
- grant currency which advances one Achievement;
- grant currency which completes several criteria/Achievements;
- Achievement completion grants additional currency;
- repeat while Profile is open;
- repeat while Inventory is open;
- repeat during an active event.

Verify:

- exact balances;
- exact Achievement progress;
- no `ConfigurationRevision` change;
- no recipe knowledge rebuild;
- no unrelated Inventory refresh;
- no client-connect refresh;
- timings within budget.

## 26.2 Inventory tests

Use inventories with approximately:

- 10 stacks;
- 50 stacks;
- 150+ stacks;
- many stackable identical items;
- many modification variants;
- inactive/missing dataset items.

Test:

- add to existing stack;
- overflow into a new stack;
- add non-stackable item;
- remove partial stack;
- delete stack;
- bind/split stack;
- apply modification;
- bulk reward grant;
- open/search/filter Inventory.

Verify one display snapshot build per revision and no repeated normalization on reads.

## 26.3 Profile tests

Test first and repeated opens for every Profile tab.

Verify:

- one refresh per dirty activation;
- zero expensive refresh on repeated unchanged show/hide/show;
- hidden tabs do not refresh because unrelated state changed;
- equipment/stat values remain correct;
- mount/pet choices resolve only when relevant.

## 26.4 Event tests

Test events with increasing numbers of:

- units;
- active traits;
- automatic auras;
- event auras;
- active cooldowns;
- simultaneous spellcasts;
- effects due on the same step.

Verify:

- start/end/advance does not exceed frame budget;
- transition locks prevent conflicting actions without freezing WoW;
- event state is identical to pre-refactor expected results.

## 26.5 Spell tests

Test:

- instant spell;
- multi-turn spell;
- start-cost and end-cost spells;
- multi-component spell;
- multi-target spell;
- component causing aura application;
- component causing proc/trait effects;
- spell completion caused by Advance Turn;
- spell causing kill and Achievement completion;
- spell producing item/currency rewards through downstream systems if supported.

Verify deterministic ordering across slice boundaries.

## 26.6 Stress transaction

Construct a development scenario which in one logical action causes:

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

The result must be correct while producing:

- one authoritative outer transaction;
- one consolidated Inventory notification;
- one consolidated Achievement notification;
- one currency payload;
- targeted event visuals;
- no global configuration refresh.

---

# 27. Acceptance Criteria

The performance project is complete only when all of the following are true.

1. `profile-currency`, `profile-achievements`, Achievement reward state and normal Inventory mutations no longer invoke the global configuration refresh pipeline.
2. `ConfigurationRevision` remains unchanged during ordinary gameplay state changes.
3. Inventory reads no longer normalize/rewrite the complete inventory.
4. `Inventory.AddItem()` no longer performs a complete `GetItems()` + `SetItems()` normalization round trip for a normal add.
5. Inventory display resolution occurs at most once per `InventoryRevision + ConfigurationRevision` snapshot.
6. Inventory window refreshes only the active page; hidden pages remain dirty until shown.
7. Profile page build/show does not perform duplicate refreshes for the same revision.
8. Reopening unchanged Profile or Inventory is effectively a visibility operation rather than a data rebuild.
9. Achievement trigger processing batches commits and UI refreshes for one trigger/reward chain.
10. The TaskQueue supports genuinely sliceable jobs; a large queued operation cannot monopolize one frame merely because it was deferred.
11. Event startup's large phases are sliceable.
12. Event turn advancement does not broadly scan inactive spell/cooldown/aura state when due-work indexes can identify relevant entries.
13. Spell completion can process large component/target sets without a single-frame freeze while preserving effect ordering.
14. Combat/UI presentation is dirty/coalesced and does not refresh after every individual component/effect mutation.
15. No listed user interaction produces an RPE-caused frame over the 16 ms hard threshold in the defined normal/high-content test matrix.
16. SavedVariables remain backwards compatible.
17. Automated/manual correctness tests show no gameplay-result regression.
18. Slow-operation instrumentation remains available for future regression detection.

---

# 28. Architectural Rules for Future Features

To prevent reintroduction of these problems, the following rules become part of RPE 2's engineering contract.

1. **Runtime state is not configuration.** Do not call `notifyConfigurationChanged()` for changing quantities, progress, cooldowns, resources or other mutable gameplay state.
2. **Reads do not normalize whole persistent collections.** Normalize on load/mutation boundaries.
3. **One logical action produces one mutation transaction.** Nested systems append to it rather than immediately refreshing the world.
4. **UI refresh is revision/dirty driven.** Do not call broad window `Refresh()` methods from low-level data mutation code.
5. **Hidden UI does no presentation work.** Mark it dirty and update when visible.
6. **Cache immutable/derived data by explicit revision inputs.** Do not rebuild it because an unrelated field changed.
7. **Deferring a slow function is not sufficient.** If its runtime scales with authored/runtime collection size, it must be sliceable or proven bounded.
8. **Authoritative effect order must survive yielding.** Store continuation state and resolved random outcomes.
9. **Network traffic follows authoritative changes, not UI invalidation.**
10. **Every new hot-path feature must have a timing/cardinality story.** If a new system subscribes to item/currency/event/spell changes, it must describe its invalidation scope and whether it participates in the current transaction.

---

# 29. Expected Outcome

After this work, the reported operations should behave differently at an architectural level:

```text
BEFORE
currency +1
 -> global configuration changed
 -> rebuild unrelated systems
 -> refresh multiple windows/widgets
 -> network refresh
 -> visible hitch

AFTER
currency +1
 -> mutate currency
 -> mark currency + matching Achievement criteria dirty
 -> commit transaction
 -> update visible currency/Achievement UI once
 -> no unrelated work
```

```text
BEFORE
open Inventory
 -> repeatedly normalize/resolve full inventory
 -> rebuild filters
 -> resolve inventory again
 -> refresh all built pages
 -> visible hitch

AFTER
open Inventory
 -> compare revisions
 -> reuse cached display snapshot
 -> update active page only if dirty
 -> show
```

```text
BEFORE
advance turn
 -> advance casts
 -> spell completes synchronously
 -> execute all components
 -> scan cooldowns
 -> scan auras
 -> downstream refresh fan-out
 -> visible hitch

AFTER
advance turn
 -> stage deterministic step transaction
 -> process only due runtime entries
 -> execute large effect graphs in bounded ordered slices
 -> commit one ChangeSet
 -> flush targeted presentation once
 -> client remains responsive
```

This redesign removes the common cause of the current freezes rather than masking individual symptoms. It also establishes a performance architecture that remains stable as RPE gains more Achievements, items, auras, spells, guild systems and other runtime features.