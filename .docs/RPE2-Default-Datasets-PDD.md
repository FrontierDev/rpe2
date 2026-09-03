# RPE 2 — Packaged Default Datasets
## Product Design Document

**Status:** Proposed  
**Target:** RPEngine 2.0 (`FrontierDev/rpe2`), `dev` branch  
**Scope:** `data/default`, packaged dataset formatting, startup installation/update behaviour, version tracking, activation preservation  
**Out of scope:** Changing the normal dataset import/export format, automatically merging user edits into updated defaults, locking default datasets in the Data Editor

---

# 1. Purpose

RPE 2 now contains a collection of first-party datasets under `data/default/`. These datasets are intended to ship with the addon and always be available in `RPEngineDatasetDB`.

The files added in the current commit are not yet usable as packaged Lua data. The individual files contain the text-export representation beginning with `RPE_DATASET_V1`, rather than valid Lua which registers a dataset with the addon. `data/default/Datasets.lua` currently lists paths, but WoW does not dynamically load addon Lua files from those path strings, and the files are not currently included in `RPEngine_Dev.toc`.

The default-dataset system must therefore provide two things:

1. a valid, explicit packaged-data format; and
2. startup synchronisation which installs or updates only the affected default dataset records.

---

# 2. Product Behaviour

Each packaged default dataset has:

- a stable, reserved dataset ID;
- an integer packaged-content version;
- the normal RPE dataset table.

On addon startup, RPE compares every packaged default against the saved dataset database.

```text
Default not previously installed
    -> write dataset
    -> record packaged version
    -> activate by default

Default already installed at same version
    -> do nothing

Default exists but packaged version changed
    -> replace only db.datasets[id]
    -> update recorded packaged version
    -> preserve its current activated/inactive state

Default record is missing but was installed previously
    -> restore db.datasets[id]
    -> preserve its current activated/inactive state
```

No operation may replace `RPEngineDatasetDB` as a whole or modify unrelated user datasets.

---

# 3. Packaged Dataset Format

`RPE_DATASET_V1` remains the clipboard/file import-export format used by `Database.ImportDataset()` and must not be used as executable addon source.

The packaged files should instead register native Lua data, conceptually:

```lua
local _, Addon = ...

Addon.Data.DefaultDatasets:Register({
    version = 1,
    dataset = {
        id = "alchemy",
        name = "Alchemy",
        -- normal dataset fields/collections
    },
})
```

`data/default/Datasets.lua` should provide the small registration container/API. All current files under `data/default/core.lua`, `data/default/classes/` and `data/default/professions/` should be converted by taking the inner `dataset` table from the current export wrapper and registering it as native Lua data.

The packaged `version` is deliberately **not** the same as:

- the dataset database schema version; or
- `Database.DATASET_SERIALIZATION_VERSION` used by import/export.

It represents only the revision of that specific first-party dataset shipped with the addon. Any future content change to a default dataset must increment that dataset's packaged version.

---

# 4. Saved Version Tracking

Add additive metadata to the dataset database root:

```lua
defaultDatasetVersions = {
    ["default"] = 1,
    ["alchemy"] = 1,
    -- ...
}
```

This ledger is kept outside the dataset itself because it is installation metadata, not authored dataset content. It must not appear in normal dataset exports.

It also provides the distinction required for activation behaviour:

- no recorded version means the default has never been installed and should initially be activated;
- a recorded version means the dataset is an update/recovery, so `activatedDatasets[id]` must not be changed.

Packaged default IDs are reserved. On a packaged version change, the packaged copy is authoritative and replaces the saved dataset with that ID. Users who want to customise a shipped default should copy it to a different dataset ID.

---

# 5. Database Synchronisation

Add one internal batch operation, e.g.:

```lua
Database.SyncDefaultDatasets(defaultDefinitions)
```

For each definition it must:

1. validate the dataset ID and positive integer packaged version;
2. compare `root.datasets[id]` and `root.defaultDatasetVersions[id]`;
3. deep-copy and normalize the packaged dataset when installation/update is required;
4. replace only `root.datasets[id]`;
5. update `root.defaultDatasetVersions[id]`;
6. activate only on first installation;
7. leave `root.activatedDatasets[id]` untouched on every later update or restoration.

After the batch, changed datasets should have dependencies recomputed and registry/configuration caches refreshed once, rather than performing a full refresh for every packaged file.

Malformed or duplicate packaged definitions should be rejected and logged without replacing unrelated database state.

---

# 6. Loading

The packaged files must be loaded explicitly through `RPEngine_Dev.toc`; `Datasets.lua` must not be treated as a runtime filesystem loader.

The registration layer must load before the individual dataset files. Synchronisation should occur only after the database and dataset entry classes required for normalization are available, then refresh the Registry once if anything changed.

---

# 7. Acceptance Criteria

The feature is complete when:

- every current `data/default` dataset file is valid addon Lua and registers exactly one dataset;
- a fresh database receives all packaged defaults and they are activated;
- restarting with identical packaged versions performs no dataset replacement;
- increasing one packaged version replaces only that dataset;
- an inactive default remains inactive after an update;
- an active default remains active after an update;
- a previously installed but missing default is restored without being reactivated;
- unrelated/custom datasets and database sections are unchanged;
- normal `RPE_DATASET_V1` import/export continues to work unchanged;
- updated default content is visible through the Registry on the same startup.