## In-game validation: FAIL — equipment mutations still take the global configuration path; cold Profile view-model remains far over budget

Validated #64 rev 1 (`a22f4e8a3437c1367be99cca13b1101d054ff887`) in WoW with timings enabled.

### What passed

- Unchanged Profile reopen was effectively instant.
- Adding a consumable-trait item was reported as instant.
- Lazy item tooltip generation is behaving reasonably in the captured sample: `ItemTooltip:Build = 6.93 ms`.
- The rev-1 Traits invalidation fix is statically correct and there was no reported correctness regression in the consumable/equipment-trait checks.

### Blocking runtime failures

#### 1. First Profile open is still far over budget

Captured first-open timings:

```text
EquipmentStatsPage:ViewModel = 570.25 ms
  equipmentSlots=17
  resourceRows=9
  statRows=39

EquipmentStatsPage:Refresh = 692.55 ms
TaskQueue.Flush = 707.39 ms
```

This is not just control creation; the dominant cost is the Equipment/Stats view-model itself.

The current cold `Profile.GetPresentationSnapshot()` path builds `statRows` with `Profile.ListProfileStatRows()` and then builds `resourceRows` with `Profile.ListResolvedResources()`.

`Profile.ListProfileStatRows()` calls `Profile.ListResolvedStats(nil)`. The current resolved-stat cache only treats `{ includeAuraBonuses = false }` as the cacheable default; `nil` falls through to a fresh `Resolver.ListResolvedStats(nil)` calculation.

Then, on a resource-cache miss, `Resolver.ListResolvedResources(nil)` performs another `Resolver.ListResolvedStats(nil)` internally. Therefore one cold Profile presentation snapshot can resolve the expensive stat graph more than once.

#### 2. Equipping an item while Profile is closed still triggers the heavyweight configuration refresh

Captured equip timings:

```text
Client:HandleLocalConfigurationChanged [profile-character-equipment]
= 5354.52 ms

TaskQueue.Flush = 5354.59 ms
```

A second equipment-trait equip reproduced it:

```text
Client:HandleLocalConfigurationChanged [profile-character-equipment]
= 5467.76 ms

TaskQueue.Flush = 5467.84 ms
```

The cause is architectural: `Database.SetProfileEquipmentSlotByScope()` / `ClearProfileEquipmentSlotByScope()` still call:

```lua
notifyConfigurationChanged(("profile-%s-equipment"):format(normalizedScope))
```

That increments `ConfigurationRevision` and queues the full `HandleLocalConfigurationChanged()` path. It bypasses the Runtime `profile.equipment` ChangeSet path that #64's `ProfileWindow:HandleRuntimeChange()` is designed to consume.

This directly violates #64's intended path:

```text
equipment change
-> EquipmentRevision changes
-> relevant Profile snapshots/pages become dirty
-> hidden Profile does no rendering
```

and the project-wide rule that ordinary mutable character state must not invoke the heavyweight configuration rebuild unless it genuinely changes authored/configuration state.

### Secondary observation

The equip path also produced:

```text
Inventory.GetDisplaySnapshot = 30.36–31.36 ms
InventoryGridPage:Refresh = 90.29–91.61 ms
```

Those are above the prior Inventory frame budget, but they are secondary to the 5.3–5.5 second configuration refresh and should not be used to mask the #64 failure.

## Required fix

### A. Move ordinary equipment mutations onto Runtime transactions/revisions

For normal character/mount/pet equip and unequip mutations:

1. Persist the same SavedVariable data as today.
2. Do **not** call `notifyConfigurationChanged("profile-*-equipment")`.
3. Use the existing Runtime transaction service and mark `profile.equipment` with narrow detail (scope/slot/item as useful).
4. Let the transaction produce `EquipmentRevision` and `ResolvedProfileRevision` once per logical mutation.
5. Let `ProfileWindow:HandleRuntimeChange()` dirty Equipment/Stats and Traits through the existing post-commit ChangeSet path.
6. If any non-UI subsystem genuinely needs work after an equipment mutation (trait resolved state, resource/widget state, etc.), extract that exact work into a targeted equipment post-commit consumer. Do **not** retain the full `HandleLocalConfigurationChanged()` pipeline for normal equip/unequip.
7. Preserve all equipment persistence, equip/unequip return values, inventory transfer semantics, mount/pet behavior, trait behavior and tooltip-context invalidation.

### B. Eliminate duplicate cold stat derivation in the Profile presentation snapshot

The cold Equipment/Stats view-model must resolve expensive stat data at most once per relevant revision tuple.

A valid fix should:

1. Add/reuse a revision-keyed resolved-stat cache for the **actual Profile UI stat semantics** (including aura/event context if those values are meant to appear in Profile). Do not simply drop aura bonuses to hit the timing target.
2. Make `Profile.GetPresentationSnapshot()` reuse that same resolved-stat result when constructing resource rows, rather than causing `Resolver.ListResolvedResources()` to recalculate the stat graph again.
3. Key the cache to every state source that affects the displayed values (at minimum the existing configuration/profile/equipment/resolved revisions plus the current dynamic tooltip/event/aura context revision where applicable).
4. Preserve exact displayed stat/resource values and ordering.
5. Keep the snapshot atomic/read-only from the UI's perspective.

If the cold view-model remains above the hard frame budget after eliminating redundant derivation, the remaining work must be made bounded rather than merely deferred as one indivisible TaskQueue job.

## Re-validation required

After the fix, rerun with timings enabled:

- first Profile open on Equipment: no Profile/view-model frame >16 ms;
- unchanged reopen: remain effectively instant / <=4 ms target;
- equip and unequip with Profile hidden: **no `Client:HandleLocalConfigurationChanged [profile-*-equipment]` at all**;
- confirm `EquipmentRevision`-driven targeted refresh when Profile/Traits is visible;
- consumable/equipment trait correctness unchanged;
- tab switching remains fast and hidden tabs do no rendering.

#64 remains open.