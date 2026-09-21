## Purpose

Make RPE2 root handling conform to the protocol-v1 fail-closed rules.

Protocol contract:

```text
FrontierDev/rpe-manager/docs/protocol.md
```

The current `ensureRoot()` function repairs/replaces malformed protocol state. That contradicts the v1 contract and can destroy evidence/state written by a newer Manager version.

## Required behaviour

### Root absent

If `RPEngineManagerDB` is completely absent:

initialize exactly:

```lua
RPEngineManagerDB = {
    protocolVersion = 1,
    pendingOperations = {},
    installedPackages = {},
    operationResults = {},
}
```

This is the only automatic initialization case.

### Root present but malformed

If `RPEngineManagerDB` exists but any of the following are invalid:

- root is not a table;
- missing required root field;
- unknown root field;
- wrong root field type;
- malformed pending queue;
- malformed installed manifest map;
- malformed operation result map;

then:

- do not rewrite/repair the root;
- do not consume pending operations;
- do not mutate datasets;
- emit an explicit diagnostic.

### Unsupported version

If:

```lua
protocolVersion ~= 1
```

then:

- leave the complete root unchanged;
- do not append request-level failures;
- do not consume operations;
- do not initialize/normalize child tables;
- emit an unsupported-version diagnostic.

The addon cannot safely write a v1 result into an unknown future contract.

## Closed root schema

Protocol v1 permits exactly:

```text
protocolVersion
pendingOperations
installedPackages
operationResults
```

Unknown root fields are malformed.

Do not silently discard or preserve-and-ignore them while processing.

## Validation helpers

Create explicit read-only validation helpers rather than using normalization as validation.

Separate responsibilities clearly:

```text
initialize absent root
validate existing root
process valid root
```

Avoid one `ensureRoot()` function that both repairs and returns state.

## Startup behaviour

`ExternalManager.Initialize()` must:

1. detect absent vs present root;
2. initialize only if absent;
3. validate present root;
4. return without mutation on validation/version failure;
5. process pending operations only after successful validation.

## Diagnostics

Use the existing addon debug/diagnostic surface.

Do not create a fake `operationResults` entry for root-level incompatibility.

## Validation

The issue is complete when:

- absent root initializes to exact v1 shape;
- `protocolVersion = 2` survives startup byte-equivalent in semantic content;
- malformed child tables are not replaced with `{}`;
- unknown root fields stop processing;
- no queued operation is consumed under malformed/unsupported state;
- no dataset mutation occurs under malformed/unsupported state;
- a valid v1 root still processes normally;
- Manager subsequently reports unsupported/malformed state rather than seeing a silently repaired v1 root.