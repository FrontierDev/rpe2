## Goal

Allow a Unit entry in one dataset to **extend another Unit**, including a Unit defined by a different dataset.

Primary use case:

- Core defines `Human`.
- Another dataset defines a Unit entry that extends Core Human and adds campaign-specific presets.
- The extension reuses the parent's base stats/resources/spells/equipment/appearances instead of copying them.

The parent Unit must not be mutated. The extending Unit has its own registry ref and resolves deterministically from parent + child data.

## Canonical schema

Add an optional Unit field:

```lua
{
    id = "campaignHuman",
    name = "Human",
    extendsUnitRef = "f82db71a:7i40epa5",
    presets = {
        -- additional presets
    },
}
```

`extendsUnitRef` uses the normal `datasetId:entryId` format.

A Unit without `extendsUnitRef` behaves exactly as it does today.

## Resolution model

Introduce one canonical Unit-definition resolver. Do not make each consumer implement inheritance independently.

The resolver must accept a Unit ref and return the **effective resolved Unit definition** while preserving the child Unit's identity/ref.

Suggested ownership:

- Registry/Database resolves refs across activated datasets.
- `Unit.lua` owns deterministic parent/child merge semantics.

Consumers such as event startup, NPC summoning, EventUnit hydration, skill targeting, UI previews, etc. must receive the effective Unit rather than raw child data where gameplay fields are required.

### Identity

If `campaign:human2` extends `f82db71a:7i40epa5`:

- runtime/event `registryID` remains `campaign:human2`;
- inherited data comes from the Core Human;
- Core Human remains unchanged;
- selecting Core Human directly does **not** implicitly gain child presets.

This avoids activation-order-dependent mutation of another dataset.

## Merge semantics

Resolve recursively from oldest ancestor to child.

### Scalars

For ordinary scalar Unit properties, an explicitly authored child value overrides the inherited value; otherwise inherit.

This includes, as applicable:

- name / description
- creatureType
- creatureSize
- challengeLevel
- equipment refs

The implementation must preserve **field presence** for extending Units. Current Unit defaults must not accidentally count as authored overrides. Do not resolve inheritance by simply normalizing the child with all default values first and then overlaying it.

### Stats and resources

Merge by ref:

- matching child `statRef` replaces the inherited progression for that stat;
- matching child `resourceRef` replaces the inherited progression for that resource;
- new refs append;
- final lists contain no duplicate refs.

Do not numerically add parent and child progression records.

### Presets

**Append** child presets after inherited presets, preserving stable order:

1. parent presets;
2. child presets.

This is the key initial use case.

Do not mutate the parent preset list.

Preset indices on the effective child Unit are therefore deterministic.

### Spells

Parent spells are inherited.

Child-authored spells are appended and deduplicated by ref.

If a future replace/remove mode is needed, add that separately; do not infer destructive replacement from an empty child list in this issue.

### Appearances

Parent appearances are inherited.

Child-authored appearances append to the inherited list.

### Resistances

Merge by `damageSchoolRef`; child entries replace matching parent entries and append new ones.

### Attributes and tags

Union parent then child while preserving order and removing duplicates.

### Preset spell/equipment overrides

Inherited and child presets must retain the existing semantics implemented by `UnitPresetSpellEquipment.lua`.

## Dependency integration

Update:

- `core/internal/database/Dependecies.lua`
  - `getUnitSourceRefs()`

`extendsUnitRef` must be treated as a dataset reference so cross-dataset extension automatically records the parent dataset as a dependency.

A dataset extending Core Human must therefore depend on the Core dataset through the existing dependency system.

If the parent dataset/unit cannot be resolved, fail clearly. Do not silently fall back to the child as a standalone Unit.

## Cycles and chains

Support inheritance chains:

`A -> B -> C`

Detect and reject cycles:

`A -> B -> A`

Requirements:

- deterministic visited-ref cycle detection;
- clear error/debug message identifying the chain;
- no infinite recursion;
- missing parent and cyclic parent are hard resolution failures, not silent fallbacks.

## Data Editor

Update the Unit inspector General page with an optional **Extends Unit** selector.

Requirements:

- list Units from available datasets using full refs;
- allow clearing the parent;
- prevent selecting the Unit itself;
- surface invalid/missing parent refs clearly;
- when a parent is selected, inherited presets should be visible in the preset UI as inherited/read-only, with child presets separately editable;
- adding a preset to the extending Unit adds it to the child only.

Do not copy inherited data into the child record merely to display it.

## Import/export and normalization

Update the Unit canonical serializer/normalizer so `extendsUnitRef` round-trips without loss.

Dataset-entry export/import must preserve it.

Do not materialize the full inherited Unit into exported child data.

Compatibility hashing must include `extendsUnitRef` and the child's authored overlay so a changed parent reference is a gameplay-definition change.

## Runtime integration audit

At minimum audit all raw Unit lookup paths that currently find a Unit directly in `dataset.units`, including:

- `server/server_EventVariants.lua::resolveActivatedUnitDefinition()`
- `server/server_EventSpellEquipmentVariants.lua`
- `core/classes/EventUnit.lua`
- `client/client_Skills.lua`
- Event Manager Unit selectors/previews

Centralize lookup/resolution rather than teaching each of these call sites a different inheritance implementation.

## Validation

Add deterministic tests covering:

1. A child with only `extendsUnitRef` resolves identically to its parent for gameplay fields.
2. Child presets append after parent presets.
3. Parent record remains byte-for-byte/logically unchanged after child resolution.
4. Child stat/resource entries replace matching parent refs without duplicates.
5. Child spells/appearances/tags/attributes append deterministically.
6. Resistance override by damage-school ref works.
7. Cross-dataset `extendsUnitRef` adds the parent dataset dependency.
8. Missing parent fails clearly.
9. Self-reference fails clearly.
10. Multi-level inheritance resolves correctly.
11. Cyclic inheritance fails without recursion.
12. Export/import preserves only authored child data and `extendsUnitRef`.
13. Event creation and summoning from an extending Unit use inherited stats/resources/spells/equipment/presets.
14. Runtime/event registry identity remains the child ref.
15. Existing non-extending Units are unchanged.

## Scope

This issue implements **Unit inheritance/extension**, not generic inheritance for every dataset entry type. Do not generalize the framework to items, spells, classes, etc. as part of this change.
