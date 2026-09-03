# RPE 2 — Packaged Default Datasets
## Implementation Plan

**Target:** `dev` branch  
**Companion document:** `.docs/RPE2-Default-Datasets-PDD.md`

---

# 1. Current State to Preserve

The implementation should work with the current architecture rather than introducing a second dataset system:

- saved datasets live under `RPEngineDatasetDB.datasets`;
- activation is independently stored in `RPEngineDatasetDB.activatedDatasets`;
- `Database.ImportDataset()` consumes the `RPE_DATASET_V1` text format and should remain unchanged for user imports;
- `Database.EnsureDatasets()` is the normalization boundary for the saved dataset root;
- dataset references/dependencies and the Registry already have refresh paths which should be reused.

The new behaviour is a packaged-content installation layer above these existing mechanisms.

---

# 2. Reformat the Default Dataset Files

## 2.1 Replace the current export blobs

For every dataset under:

```text
data/default/core.lua
data/default/classes/*.lua
data/default/professions/*.lua
```

remove:

```text
RPE_DATASET_V1
{ serializationVersion=..., format="rpe-dataset", dataset=... }
```

and preserve the inner `dataset` object as native Lua data.

Each file should register one definition with:

```lua
{
    version = 1,
    dataset = { ... },
}
```

Do not manually rewrite or reinterpret the dataset contents while converting them; the formatting change should be mechanical apart from adding the packaged version.

## 2.2 Replace `data/default/Datasets.lua`

Turn the current path table into the package registry. It should:

- create `Addon.Data.DefaultDatasets`;
- expose a `Register(definition)` function;
- retain definitions keyed by dataset ID;
- reject duplicate IDs and invalid definitions early;
- expose the final registered definitions to the installer.

The path strings are not needed as a runtime loader once the files are explicitly listed in the TOC.

---

# 3. Add the Database Sync Boundary

Modify `core/internal/database/Database.lua`.

## 3.1 Normalize package-version metadata

Extend `Database.EnsureDatasets()` so the root always contains:

```lua
root.defaultDatasetVersions = root.defaultDatasetVersions or {}
```

Keep this outside individual dataset records. It is package-installation metadata and should not participate in normal dataset export/import.

A dataset schema increment is not required solely for this ledger because the authored/serialized dataset shape is unchanged; the field can be introduced additively at the database-root normalization boundary.

## 3.2 Add `Database.SyncDefaultDatasets()`

Implement a batch helper inside `Database.lua` so it can reuse the existing private normalization/deep-copy helpers.

Per definition:

```text
id = definition.dataset.id
packagedVersion = definition.version
installedVersion = root.defaultDatasetVersions[id]
existing = root.datasets[id]
firstInstall = installedVersion == nil
needsWrite = existing == nil or installedVersion ~= packagedVersion
```

If `needsWrite == false`, skip the dataset entirely.

If a write is required:

1. deep-copy the packaged dataset;
2. normalize it through the same dataset normalization path used elsewhere;
3. assign only `root.datasets[id]`;
4. set `root.defaultDatasetVersions[id] = packagedVersion`;
5. if `firstInstall`, set `root.activatedDatasets[id] = true`;
6. otherwise do not write to `root.activatedDatasets[id]` at all.

This handles the important recovery case correctly: if a default was installed previously, disabled, and its dataset record later disappears, restoring it must not activate it again.

Return a changed-ID list/count so follow-up work can be batched.

---

# 4. Dependency and Registry Refresh

For every changed default dataset:

- recompute its dataset dependencies through the existing `Database.Dependecies` helpers;
- ensure any dependency data stored on the replaced dataset is current.

After all changed defaults have been processed:

- advance/invalidate the configuration revision once if required by the existing cache contract;
- rebuild the Registry once, not once per dataset.

Do not call `Database.SetDatasetActivated(id, true)` for updates. That API intentionally mutates activation and would re-enable a dataset the user disabled.

Avoid routing every packaged replacement through `Database.ImportDataset()`; the package already contains trusted native tables and should not serialize and deserialize its own data at startup.

---

# 5. Load the Package

Update `RPEngine_Dev.toc` so the default package is actually loaded.

Recommended order after the database and dataset entry classes are available:

```text
data/default/Datasets.lua

data/default/core.lua
data/default/classes/...
data/default/professions/...

data/default/Install.lua
```

Add `data/default/Install.lua` as the small final integration point. It should pass the registered definitions to:

```lua
Addon.Internal.Database.SyncDefaultDatasets(...)
```

This keeps package declaration separate from database mutation and guarantees all definitions have registered before the batch runs.

The installer should do nothing when no definitions require installation/update.

---

# 6. Validation and Failure Handling

Before replacing a saved dataset, validate at minimum:

- definition is a table;
- `dataset` is a table;
- `dataset.id` is non-empty;
- `version` is a positive integer;
- no packaged duplicate uses the same dataset ID.

A malformed packaged dataset should produce an internal debug/error message identifying the dataset and should be skipped. It must not clear the dataset database or prevent unrelated defaults from being evaluated.

Default dataset IDs should be treated as reserved first-party IDs. If a saved dataset has one of these IDs but its installed package version is absent/stale, the packaged definition is authoritative.

---

# 7. Deterministic Validation Cases

Exercise the sync helper with isolated/mocked database roots before in-game validation.

| Case | Expected result |
|---|---|
| Empty dataset DB | All defaults written, versions recorded, all activated |
| Same datasets + same versions | No writes; activation unchanged |
| One packaged version increments | Only that dataset replaced |
| Updated default currently active | Remains active |
| Updated default currently inactive | Remains inactive |
| Previously installed default missing + inactive | Dataset restored, remains inactive |
| Previously installed default missing + active | Dataset restored, remains active |
| Unrelated custom dataset | Byte-for-byte/logically unchanged |
| Invalid packaged definition | Rejected without unrelated mutation |
| Duplicate packaged ID | Rejected deterministically |

Also verify:

1. `/reload` does not repeatedly rewrite defaults;
2. the Data Editor can see the installed defaults;
3. Registry resolution uses updated content immediately after a packaged version change;
4. dataset activation toggles continue to work normally;
5. `Database.ExportDataset()` / `ImportDataset()` still round-trip the normal `RPE_DATASET_V1` format without package metadata.

---

# 8. Implementation Sequence

1. Add the packaged-dataset registry and registration contract.
2. Mechanically convert all current `data/default` files to native registered tables with version `1`.
3. Add `defaultDatasetVersions` normalization to the saved dataset root.
4. Implement and unit-exercise `Database.SyncDefaultDatasets()`.
5. Add dependency/cache refresh after the batch.
6. Add `data/default/Install.lua` and TOC entries.
7. Validate fresh install, update, disabled-update and missing-record recovery scenarios in game.
8. Review the final diff specifically for accidental changes to user import/export, dataset activation, unrelated datasets, or whole-database replacement.

For future content changes, increment only the `version` of each packaged dataset whose contents changed.