## Summary

Datasets imported by the user should become active automatically as part of the import transaction.

Observed during a 6-player live RPE event: users could successfully import the required datasets but still had to manually activate them before their configuration matched the event host.

Target branch: `dev`.

## Current behavior

`Database.ImportDataset()` imports/replaces the dataset, recomputes dependencies, and emits `notifyConfigurationChanged("dataset-import")`, but the imported dataset is not added to the activated-dataset set automatically.

Packaged default datasets already have distinct first-install activation behavior; this issue is specifically about user imports.

Relevant code:

- `core/internal/database/Database.lua`
  - `Database.ImportDataset()`
  - `Database.ImportDatasets()` / batch import path
  - `Database.SetDatasetActivated()`
- dataset import UI callers

## Required behavior

- A successfully imported dataset is active immediately after import.
- Batch imports activate every successfully imported dataset.
- Re-importing/updating a dataset that is already active leaves it active.
- Import/replacement must not accidentally deactivate unrelated datasets.
- Activation must go through the canonical activation/configuration invalidation path so Registry hashes and live session compatibility state are refreshed.
- Failed imports must not leave partial activation state behind.

## Implementation notes

Do not implement this only in the Data Editor UI. The policy belongs in the database/import layer so every import entrypoint behaves consistently.

Prefer making activation part of the successful import commit, then perform dependency recomputation/configuration notification once in a deterministic order. Avoid emitting redundant refresh storms for batch imports if the existing import transaction can coalesce them.

## Acceptance criteria

1. Import a previously absent dataset: it is immediately present in `ListActivatedDatasetIds()`.
2. Import multiple datasets in one batch: all successfully imported datasets are active.
3. Re-import an active dataset: it remains active.
4. Existing unrelated active/inactive dataset states are unchanged.
5. The Data Editor reflects the active state immediately without `/reload`.
6. If connected to an RPE session, the resulting dataset hash refresh is queued immediately through the normal configuration-change path.
7. Import failure does not alter activation state.