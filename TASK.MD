## Purpose

Implement `remove_dataset` execution for the Phase 2 external-management protocol.

Depends on FrontierDev/rpe-manager#10 and the RPE external-management runtime issue created for Phase 2.

## Current canonical path

The current addon already exposes:

```lua
Database.DeleteDataset(datasetId)
```

in:

```text
core/internal/database/Database.lua
```

The external Manager must request deletion through this API rather than deleting tables from `RPEngineDatasetDB`.

## Scope

For a valid protocol-v1 `remove_dataset` request:

1. Validate the operation envelope and package/dataset identity.
2. Resolve the installed package manifest entry for `catalogueId`.
3. Ensure the request cannot delete an unrelated dataset by presenting a mismatched catalogue ID/dataset ID pair.
4. Call `Database.DeleteDataset(datasetId)` for the canonical removal.
5. On successful removal:
   - remove the corresponding `installedPackages[catalogueId]` manifest entry;
   - write a terminal success result.
6. On failure:
   - preserve the manifest unless the protocol explicitly defines reconciliation for an already-absent dataset;
   - write an explicit terminal failure result.

## Already-absent datasets

Define and implement deterministic behaviour consistent with protocol v1 for:

- package manifest exists but dataset has already been removed manually;
- no package manifest exists;
- request references the wrong dataset ID for a catalogue entry.

Do not silently report success for identity mismatches.

If an already-absent but correctly identified dataset is treated as an idempotent success, that behaviour must be explicit in the result code/contract.

## Idempotency

A completed removal request ID must never invoke `Database.DeleteDataset` again after `/reload`.

## Regression requirements

Canonical deletion must retain the existing `Database.DeleteDataset` behaviour, including dependency cleanup and configuration-change notification owned by the database layer.

Do not duplicate those side effects in the Manager integration module.

## Validation

Verify:

- Manager-installed dataset -> removal succeeds through `Database.DeleteDataset`;
- package manifest entry is removed only after successful canonical deletion/reconciliation;
- dependent/internal database cleanup remains identical to manual deletion;
- mismatched catalogue/dataset identity is rejected;
- unrelated datasets cannot be removed by forged/malformed manifest metadata;
- duplicate completed request ID does not re-run deletion;
- manual Data Editor deletion remains unchanged.