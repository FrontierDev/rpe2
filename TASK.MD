## Problem

The Phase 2 external-management runtime is not initializing at addon startup, so:

```lua
RPEngineManagerDB == nil
```

after logging in and exiting WoW.

This blocks the Phase 2 end-to-end Manager integration test.

## Root cause

In `RPEngine2.toc`, the files are currently loaded in this order:

```text
core/internal/Runtime.lua
...
core/internal/manager/ExternalManager.lua
```

But `core/internal/Runtime.lua` captures the Manager module at file load time:

```lua
local ExternalManager = Addon.Internal.ExternalManager or {}
```

At that point `ExternalManager.lua` has not yet been loaded, so this local refers to an empty placeholder table.

Later, `ExternalManager.lua` creates/assigns the real:

```lua
Addon.Internal.ExternalManager
```

but the local captured in `Runtime.lua` still points at the earlier empty table.

As a result, on `ADDON_LOADED`:

```lua
if ExternalManager and ExternalManager.Initialize then
    safeCall(ExternalManager.Initialize, ExternalManager)
end
```

does not call the real initializer.

Therefore the absent protocol root is never initialized and `RPEngineManagerDB` remains nil.

## Required fix

Ensure `Runtime.lua` invokes the actual loaded `Addon.Internal.ExternalManager` module.

Preferred approaches:

1. Load `core/internal/manager/ExternalManager.lua` before `core/internal/Runtime.lua` in `RPEngine2.toc`, **if its dependencies permit that order**; or
2. Resolve `Addon.Internal.ExternalManager` dynamically inside the `ADDON_LOADED` handler rather than capturing it before the module is loaded.

Do not add a fallback duplicate initialization path elsewhere.

The final architecture should have one canonical initialization path.

## Dependency check

Before changing TOC order, verify `ExternalManager.lua` dependencies.

It currently relies on dataset/database APIs such as:

```lua
Database.GetDatasetImportPayloadIdentity
Database.ImportDataset
Database.GetDatasetByID
Database.DeleteDataset
```

If those APIs require `Database.lua` to have loaded first, prefer resolving `Addon.Internal.ExternalManager` at event dispatch time instead of moving the Manager module ahead of its dependencies.

## Expected behaviour

On first startup with no existing Manager SavedVariable:

```lua
RPEngineManagerDB = {
    protocolVersion = 1,
    pendingOperations = {},
    installedPackages = {},
    operationResults = {},
}
```

must be created by the addon.

After normal WoW logout/exit, that exact root must be persisted into:

```text
WTF/Account/<account>/SavedVariables/RPEngine2.lua
```

## Regression requirements

Verify that:

- `ExternalManager.Initialize()` runs exactly once during normal addon startup;
- absent root initializes to protocol v1;
- valid existing root is processed normally;
- malformed/unsupported root still follows the protocol-v1 fail-closed behaviour;
- pending operations are processed at startup;
- no duplicate Manager initialization occurs;
- existing Runtime initialization for Tasks, Comms, Achievements, etc. is unchanged.

## Validation

The issue is complete when:

1. Delete/rename the test account's existing `RPEngineManagerDB` state while WoW is closed.
2. Start WoW with the current addon.
3. Confirm in-memory:
   ```lua
   RPEngineManagerDB ~= nil
   ```
4. Exit WoW normally.
5. Confirm `RPEngine2.lua` contains the protocol-v1 root.
6. Queue a Phase 2 Manager request and verify it is consumed on the next addon startup.
