## Summary

Implement the user-facing and lifecycle behavior for temporary datasets introduced by #320:

1. expose a simple **Lifetime** field in dataset metadata editing;
2. show the resulting absolute expiry for temporary datasets;
3. automatically remove expired temporary datasets during addon/database initialization;
4. ensure expired datasets are removed from activation/configuration state cleanly and in one batched operation.

Target branch: `dev`.

Depends on: #320.

## Existing architecture

The Data Editor already has a dataset-level inspector (`client/ui/editor/inspectors/page_InspectorDataset.lua`) which directs the user to edit dataset metadata from the dataset entry in the left pane. Extend the existing dataset metadata editing flow rather than adding a separate temporary-dataset window.

`core/internal/database/Database.lua` already owns `Database.Initialize()`, `Database.EnsureDatasets()`, activation state and `Database.DeleteDataset()`. Expiry cleanup belongs in this existing database lifecycle.

## Data Editor: Lifetime field

Add a dataset metadata field:

```text
Lifetime: [ Permanent v ]
```

`Permanent` is the default.

Provide a small fixed set of practical temporary durations. The exact labels can follow the existing dropdown conventions; a suitable initial set is:

```text
Permanent
1 Hour
6 Hours
12 Hours
24 Hours
3 Days
7 Days
```

The dropdown must call the central lifetime mutation API from #320. Do not calculate/write `expiresAt` independently in the UI.

When a temporary lifetime is selected, also display the resolved absolute expiry as read-only information, e.g.:

```text
Expires: 17 Sep 2026 18:00 (server time)
```

The display is informational only; the persisted `expiresAt` timestamp remains authoritative.

Changing unrelated dataset fields must not alter the expiry.

## Expiry cleanup API

Add a database operation equivalent to:

```lua
Database.PurgeExpiredDatasets(now)
```

Behavior:

1. inspect normalized datasets;
2. identify temporary datasets where `expiresAt <= now`;
3. remove each expired dataset using the same underlying deletion semantics as normal dataset deletion;
4. remove stale references from all relevant dataset activation/selection state;
5. leave permanent datasets untouched;
6. return the IDs/count of datasets removed for diagnostics/tests.

`now` may be optional in production and default to `GetServerTime()`, but allowing it to be supplied makes deterministic testing straightforward.

## Do not call full public deletion repeatedly

Avoid implementing purge as a simple loop over:

```lua
Database.DeleteDataset(id)
```

if that causes a complete configuration refresh/notification for every expired dataset.

Instead, factor the existing dataset removal mechanics into an internal helper if necessary, for example:

```lua
removeDatasetRecord(root, datasetId, options)
```

Then use it from both:

- `Database.DeleteDataset()` for normal interactive deletion;
- `Database.PurgeExpiredDatasets()` for batched startup cleanup.

The purge should issue at most one configuration invalidation/refresh after all expired datasets have been removed.

## Activation/state cleanup

Expiry is deletion, not merely deactivation.

For every expired dataset, ensure cleanup covers all places that can keep a dataset logically present, including the current structures used by the database such as:

- `root.datasets`;
- `root.activatedDatasets`;
- character-scoped active/selected dataset references where applicable;
- dependency bookkeeping/caches that normal dataset deletion currently updates;
- registry/configuration state that must be rebuilt after deletion.

Do not leave an expired dataset hidden in storage but still referenced by activation or compatibility hashes.

## Addon-load ordering

Run expiry cleanup during the normal database/addon initialization path after dataset SavedVariables have been loaded/normalized, but **before expired datasets can be treated as active configuration for the session**.

The intended startup flow is conceptually:

```text
load SavedVariables
    ↓
Ensure/normalize datasets
    ↓
PurgeExpiredDatasets(GetServerTime())
    ↓
continue normal registry/configuration startup
```

This is specifically an addon-load/login cleanup. No background timer is required for this issue.

A dataset that expires while the player remains logged in may remain until the next addon load unless another existing configuration boundary naturally invokes the purge. Do not add periodic polling solely for this feature.

## Import interaction

Coordinate with #320 so an already-expired dataset cannot survive just because it is imported after initialization.

Either:

- reject an expired import before installation; or
- run the same expiry predicate/removal immediately as part of import.

In either case, the expired dataset must not appear as activated usable content.

## UI refresh behavior

If cleanup occurs before the Data Editor is opened, expired datasets simply must not appear.

If the purge function is invoked while the editor is already open for any reason, existing configuration refresh behavior should safely clear invalid dataset/entry selections rather than leaving references to the removed object.

No special archive/trash view is required: expiry means permanent local removal.

## Diagnostics

Add an `RPE INTERNAL` diagnostic entry when cleanup removes datasets, preferably summarized rather than one line per dataset, e.g.:

```text
Purged 3 expired temporary datasets: event_foo, event_bar, event_baz
```

Do not log anything on every login when nothing expired.

## Tests / validation

Exercise at minimum:

- Permanent dataset survives startup purge.
- Temporary dataset with future expiry survives startup purge.
- Temporary dataset with `expiresAt == now` is removed.
- Temporary dataset with past expiry is removed.
- Multiple expired datasets are removed in one purge.
- Purging removes activation references as well as the dataset records.
- Purging several datasets emits only one configuration refresh/invalidation.
- Non-expired activated datasets remain activated.
- Data Editor does not list an expired dataset after startup.
- Lifetime dropdown updates through the database API and shows the new expiry.
- Reopening the editor does not recalculate/extend expiry.
- `/reload` after the expiry removes the dataset.
- An imported dataset whose absolute expiry is already in the past is not left installed/active.

## Acceptance criteria

- [ ] Dataset metadata exposes a `Lifetime` selector with `Permanent` as the default.
- [ ] Temporary selections show the absolute server-time expiry.
- [ ] UI changes use the central lifetime API from #320.
- [ ] Expired temporary datasets are deleted during addon/database initialization.
- [ ] Cleanup uses the normal dataset deletion semantics for activation/dependency state.
- [ ] Multiple expired datasets are cleaned in one batched configuration change.
- [ ] Permanent and non-expired temporary datasets are untouched.
- [ ] No periodic expiry polling is introduced.
- [ ] Expired imports cannot remain active/usable.
- [ ] Cleanup produces concise INTERNAL diagnostics only when something was removed.