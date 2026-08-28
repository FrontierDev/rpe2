# RPE 2 — Unit Authoring, Presets and Appearances Implementation Plan

**Status:** Implementation plan  
**Target:** `FrontierDev/rpe2`  
**Authoritative product document:** `.docs/RPE2-Unit-Authoring-Presets-Appearances-PDD.md`

---

# 1. Objective

Implement the Unit authoring overhaul described in the PDD so one Base Unit can define multiple lightweight Presets and multiple appearances.

The final runtime model must support:

```text
Base Unit: Brigand

Preset 0: Base
Preset 1: Marauder
Preset 2: Hedge Wizard
```

with Presets applying flat and percentage Stat/Resource modifiers and optionally replacing the Base Unit appearance pool.

NPC creation must remain host-authoritative:

```text
registryID
+ presetIndex
+ host-selected appearanceIndex
+ host-materialized runtime stats/resources
-> EventUnit
-> full Event snapshot / EventUnit delta
-> identical result on every client
```

The implementation must preserve the existing Event runtime, EventUnit synchronization, Unit editor, summoning and UnitPortrait systems rather than introducing a parallel NPC system.

---

# 2. Current repository state

The current tree already contains the required integration points.

## 2.1 Unit definition

`core/classes/Unit.lua` currently owns:

```text
name
creatureType
creatureSize
displayId
fileDataId
cam
rot
z
equipment
spells
stats
resources
resistances
attributes
tags
```

Stats are normalized as:

```lua
{
    statRef = ...,
    value = ...,
}
```

Resources are normalized as:

```lua
{
    resourceRef = ...,
    value = ...,
    perPlayer = ...,
}
```

The overhaul should extend this class rather than add a separate top-level Preset dataset collection.

## 2.2 Unit editor

The Unit editor is already split across focused inspector files:

```text
client/ui/editor/inspectors/page_InspectorUnit.lua
client/ui/editor/inspectors/unit/page_InspectorUnitShared.lua
client/ui/editor/inspectors/unit/page_InspectorUnitGeneral.lua
client/ui/editor/inspectors/unit/page_InspectorUnitModel.lua
client/ui/editor/inspectors/unit/page_InspectorUnitStats.lua
client/ui/editor/inspectors/unit/page_InspectorUnitResources.lua
...
```

`page_InspectorUnitModel.lua` currently edits one `displayId` / `fileDataId` and global `cam`, `rot`, `z` values.

The Stats and Resources pages already contain useful reference-selector/table/editor patterns which should be reused for Preset modifier editing.

## 2.3 Event NPC selection

`server/ui/window_EventUnit.lua` currently:

```text
selects one Unit registryID
selects team/flags/raid marker
previews the selected Unit
passes registryID + options to AddEventNpcUnitFromDefinition
```

There is no Preset selector.

## 2.4 Event NPC materialization

`server/server_Event.lua` already centralizes NPC definition resolution and contains the important paths:

```text
BuildEventNpcUnitDataFromDefinition(...)
AddEventNpcUnitFromDefinition(...)
AddEventNpcUnit(...)
SummonEventPetUnit(...)
buildNpcUnit(...)
```

This is the correct authority boundary for resolving a Preset into runtime Stats/Resources and selecting a concrete appearance.

Do not perform random appearance selection independently on clients.

## 2.5 EventUnit and network serialization

`core/classes/EventUnit.lua` owns runtime NPC fields and definition fallback resolution.

`core/classes/Event.lua` serializes each EventUnit into the Event units payload. The current modern record contains fields through boss/threat state and already uses append-compatible field-count checks during deserialization.

The new `presetIndex` and `appearanceIndex` should therefore be appended to the modern unit record rather than inserted into the middle of existing fields.

The same `serializeUnit(...)` path is used by full Event unit snapshots and EventUnit delta records, so adding the fields there covers both protocol forms, subject to auditing compact summoned-unit builders.

## 2.6 Portrait model resolution

`core/ui/prefabs/UnitPortrait.lua` currently resolves NPC model state from the resolved Unit definition's single:

```text
displayId
fileDataId
cam
rot
z
```

This must be replaced with shared Base Unit / Preset / appearance-index resolution.

---

# 3. Dependency and sequencing with existing Unit/Event work

The following existing issues overlap this work:

```text
#81 Unit challenge level
#82 challenge-level-gated per-player NPC resource scaling
#83 Heroic/Mythic NPC health/damage/hit/defence bonuses
```

Preferred implementation order:

```text
#81 challengeLevel data model
-> this Unit Preset/Appearance overhaul
-> #82 player-count resource scaling integration
-> #83 difficulty integration
```

If #82/#83 land first, adapt the shared NPC resource materializer rather than layering a second formula around them.

The final required Health/resource order is authoritative:

```text
Base Unit resource
-> player-count scaling when enabled for challengeLevel
-> Preset resource modifier
-> Event difficulty Health modifier
-> EventUnit runtime resource
```

Do not accidentally implement:

```text
Preset -> player count
```

because a percentage Preset is intended to scale the already player-scaled Unit value.

Do not accidentally implement:

```text
difficulty -> Preset
```

because Event difficulty is the final encounter-level NPC Health multiplier.

If #81 has already advanced the Dataset schema, this overhaul increments from that new schema. Never hard-code a stale expected schema number.

---

# 4. Phase 1 — Extend `Unit.lua` definition model

Primary file:

```text
core/classes/Unit.lua
```

## 4.1 Add appearance normalization

Add a pure normalizer for one Appearance:

```lua
{
    displayId = number|nil,
    fileDataId = number|nil,
    cam = number,
    rot = number,
    z = number,
}
```

Use the current defaults:

```text
cam = 1
rot = 0
z   = -0.35
```

An Appearance is valid when at least one model identity is usable:

```text
displayId
or
fileDataId
```

Do not retain empty placeholder records in serialized definitions.

Add:

```text
normalizeUnitAppearances(values)
```

which preserves authored order.

## 4.2 Legacy single-model migration

`Unit:Merge(data)` must distinguish:

```text
data.appearances == nil
```

from:

```text
data.appearances exists but is intentionally empty
```

For a legacy Unit where `appearances` is absent, synthesize one Appearance from:

```text
displayId
fileDataId
cam
rot
z
```

when a legacy model ID is present.

Important:

```text
explicit appearances = {}
```

must stay empty and must not be silently rebuilt from stale legacy fields.

After normalization, `ToTable()` should write the canonical `appearances` collection. Do not continue writing the old single-model fields as the new canonical schema unless a temporary compatibility bridge is proven necessary.

## 4.3 Add modifier normalization

Add two equivalent modifier normalizers:

```lua
statModifier = {
    statRef = string,
    percentBonus = number,
    flatBonus = number,
}

resourceModifier = {
    resourceRef = string,
    percentBonus = number,
    flatBonus = number,
}
```

Normalization requirements:

- blank/missing refs are discarded;
- numeric strings are accepted through `tonumber`;
- invalid numbers resolve to `0`;
- negative values are retained;
- order is retained;
- duplicate refs should not be generated by the editor, but class loading should normalize deterministically rather than error.

Recommended malformed duplicate behavior on load: keep the first occurrence and ignore later duplicates. This produces a single unambiguous modifier per target and matches the editor constraint.

## 4.4 Add Preset normalization

Canonical Preset:

```lua
{
    name = "Marauder",
    statModifiers = {},
    resourceModifiers = {},
    appearances = {},
}
```

Normalize:

```text
name -> trim leading/trailing whitespace
modifier lists -> canonical structures
appearances -> canonical appearance records
```

Blank Preset names should remain load-safe but should not be authorable through the editor. Runtime name resolution must fall back safely if malformed legacy/imported data contains a blank name.

Add:

```text
Unit.presets = {}
Unit.appearances = {}
```

to new Unit defaults.

## 4.5 Preserve challenge level

If #81 has landed, retain and normalize `challengeLevel` exactly as defined there.

Do not allow Presets to override `challengeLevel` in this task.

## 4.6 Serialization

`Unit:ToTable()` must serialize:

```text
appearances
presets
```

alongside all existing canonical Unit fields.

Do not mutate `stats`, `resources`, `presets` or `appearances` during read-only resolution.

---

# 5. Phase 2 — Add pure Unit variant-resolution helpers

Keep definition-only variant logic in `core/classes/Unit.lua` or a narrowly scoped Unit-owned helper module loaded immediately after it.

Do not make the pure Unit resolver depend on:

```text
active Event
active Ruleset
player count
Event difficulty
network state
UI
```

Recommended public helpers:

```lua
Unit.NormalizePresetIndex(unit, presetIndex)
Unit.ResolvePreset(unit, presetIndex)
Unit.ResolveVariantName(unit, presetIndex)
Unit.ResolveEffectiveAppearances(unit, presetIndex)
Unit.ResolveAppearance(unit, presetIndex, appearanceIndex)
Unit.ApplyStatModifiers(stats, preset)
Unit.ApplyResourceModifiers(resources, preset)
```

Equivalent naming is acceptable, but use one shared implementation.

## 5.1 Preset index semantics

Canonical runtime semantics:

```text
0 = Base Unit
1..#presets = specific Preset
```

Any invalid/non-numeric/out-of-range value normalizes to `0`.

Do not use negative values or one-based `nil means first preset` conventions.

## 5.2 Variant name resolution

Required:

```text
presetIndex 0
-> Base Unit name

valid named Preset
-> <Base Name> <Preset Name>

invalid Preset
-> Base Unit name
```

Do not permanently rewrite the Base Unit definition name.

## 5.3 Effective appearance pool

Required resolver:

```text
valid Preset AND #preset.appearances > 0
-> preset.appearances

otherwise
-> unit.appearances
```

Do not merge the pools.

## 5.4 Appearance index resolution

Pure resolution accepts an already-selected index:

```text
pool empty
-> nil appearance

valid index
-> exact entry

invalid positive index
-> appearance 1 for presentation fallback

0
-> nil unless caller explicitly requests a default preview
```

Random selection does **not** belong in this pure resolver.

## 5.5 Numeric modifier application

Formula:

```text
result = base × (1 + percentBonus / 100) + flatBonus
```

Use the same helper for both Stat and Resource numeric values.

### Stats

Resolve by `statRef`:

1. copy Base Unit Stats;
2. build `statRef -> index` lookup;
3. apply each Preset modifier exactly once;
4. if modifier target is absent, use base `0` and append a new runtime Stat entry.

Do not reorder existing Base Unit Stats merely because a lookup map is used.

Append modifier-only Stats in Preset modifier order.

Do not round Stat values unless the existing Stat system already requires it at the later consumer boundary.

### Resources

The pure modifier helper should operate on already-materialized resource values passed by the Event layer.

Do **not** make `Unit.ApplyResourceModifiers()` calculate `perPlayer` itself.

Conceptually it accepts entries equivalent to:

```lua
{
    resourceRef = ...,
    value = alreadyScaledValue,
    ...
}
```

and modifies the numeric current/max/base field chosen by the caller.

The Event layer owns composition with player-count and difficulty rules.

Resource results used as maxima must be clamped to `>= 0`.

---

# 6. Phase 3 — Dataset schema migration

Primary file:

```text
core/internal/database/Database.lua
```

At implementation time:

1. inspect current `SCHEMA.datasets`;
2. increment by one through the existing migration/normalization convention;
3. preserve every migration introduced by #81 or other already-landed work;
4. rely on `Unit.FromTable()` normalization to convert legacy model fields into `appearances` where appropriate.

Migration expectations:

```text
legacy Unit with one model
-> appearances = { legacy model }
-> presets = {}

legacy Unit with no model
-> appearances = {}
-> presets = {}

new Unit
-> canonical appearances/presets serialized
```

No Profile schema change is required.

No Event persistent schema change is required unless Event drafts are persisted elsewhere in the implementation branch; current Event runtime serialization is handled separately below.

---

# 7. Phase 4 — Replace Unit Model editor with Appearance Pool editor

Primary existing files:

```text
client/ui/editor/inspectors/unit/page_InspectorUnitModel.lua
client/ui/editor/inspectors/page_InspectorUnit.lua
client/ui/editor/inspectors/unit/page_InspectorUnitShared.lua
RPEngine_Dev.toc
```

Recommended result:

```text
Unit inspector page key: appearances
Label: Appearances
```

The implementation may rename `page_InspectorUnitModel.lua` to `page_InspectorUnitAppearances.lua`; if renamed, update `RPEngine_Dev.toc` and all load references in the same change.

## 7.1 Appearance list

Build an ordered `ScrollLayout`/table with rows such as:

```text
# | Model | Display ID / FileData ID
```

Required actions:

```text
Add
Remove
Move Up
Move Down
```

Left-click selects one Appearance for editing.

Do not use array index as a permanent identity outside the Unit definition; reordering is intentional authoring behavior.

## 7.2 Appearance editor

Reuse `UI.EditorModelField` and the Model Finder.

For the selected Appearance edit:

```text
displayId
fileDataId
cam
rot
z
```

The existing slider constraints/defaults from `page_InspectorUnitModel.lua` should be reused.

All edits must pass through the normal `CommitSelectedUnit(...)` path.

Do not directly mutate the Dataset object from widget callbacks without that commit path.

## 7.3 Add behavior

`Add Appearance` should create a canonical record with default transforms and open/select it for editing.

If the Model Finder returns a model during creation, initialize the selected record immediately.

## 7.4 Preview

The selected Appearance preview must show its own transform rather than the old global Unit transform.

Switching selected Unit or selected Appearance must clear stale UI state.

---

# 8. Phase 5 — Add Unit Presets editor page

Create:

```text
client/ui/editor/inspectors/unit/page_InspectorUnitPresets.lua
```

Update:

```text
client/ui/editor/inspectors/unit/page_InspectorUnitShared.lua
client/ui/editor/inspectors/page_InspectorUnit.lua
RPEngine_Dev.toc
```

Add Unit inspector page definition:

```text
Presets
```

Recommended page order:

```text
General
Appearances
Equipment
Spells
Stats
Resources
Presets
```

Exact position may be adjusted for available layout space, but Presets must be directly reachable through the existing Unit inspector page selector.

## 8.1 Preset selector and lifecycle

Maintain editor-only state:

```text
SelectedUnitInspectorPresetIndex
```

Controls:

```text
Preset dropdown/list
Add
Duplicate
Delete
Move Up
Move Down
Name
```

Changing selected Unit must validate/reset the selected Preset index.

### Add

Create:

```lua
{
    name = "New Preset",
    statModifiers = {},
    resourceModifiers = {},
    appearances = {},
}
```

If `New Preset` already exists, generate a non-conflicting display name or allow immediate rename while still preventing a blank final value.

### Duplicate

Deep-copy the selected Preset, including nested modifier/appearance lists.

Do not retain shared table references.

### Delete

Delete only the selected Preset and select the nearest remaining Preset.

### Reorder

Move the complete Preset record. Array order is the authored Preset-index order used for future Event spawns.

Existing live EventUnits are runtime snapshots and must not be rewritten merely because the Dataset is edited.

## 8.2 Preset name

Trim on commit.

Reject blank names in the UI.

Duplicate Preset names are technically resolvable by index but create poor authoring UX; prevent duplicate names within one Unit unless an existing editor convention strongly prefers warning rather than rejection.

---

# 9. Phase 6 — Preset Stat modifier editor

Reuse the design of:

```text
client/ui/editor/inspectors/unit/page_InspectorUnitStats.lua
```

but operate on:

```text
selectedPreset.statModifiers
```

Columns:

```text
Stat | Percent | Flat
```

Editor row:

```text
Stat reference dropdown
Percent input
Flat input
Add/Apply button
```

Requirements:

- use `BuildUnitInspectorReferencesAcrossDatasets("stats")` / current shared reference helpers;
- prevent duplicate `statRef` entries in one Preset;
- accept negative numeric values;
- `0 / 0` is valid but may be omitted if the editor chooses to remove no-op modifiers explicitly;
- left-click edits an existing row;
- right-click removes through existing ContextMenu patterns;
- selection resets correctly after row removal or Preset change.

Do not edit Base Unit `stats` from the Presets page.

---

# 10. Phase 7 — Preset Resource modifier editor

Reuse the design of:

```text
client/ui/editor/inspectors/unit/page_InspectorUnitResources.lua
```

but operate on:

```text
selectedPreset.resourceModifiers
```

Columns:

```text
Resource | Percent | Flat
```

Requirements mirror Stat modifiers:

- cross-Dataset Resource selector;
- no duplicate `resourceRef` in one Preset;
- negative/positive Percent and Flat values;
- edit/remove behavior consistent with Unit Resource editor;
- no `perPlayer` field on the Preset modifier itself.

`perPlayer` remains authored only on the Base Unit Resource.

This distinction is important:

```text
Base Unit defines scaling coefficient
Preset modifies the player-scaled result
```

---

# 11. Phase 8 — Preset appearance override editor

The Presets page should include an appearance subsection using the same underlying appearance-record helpers as the Base Unit Appearances page.

Do not duplicate appearance normalization or Model Finder plumbing in two incompatible forms.

Recommended reusable Data Editor helpers:

```lua
BuildUnitAppearanceRows(appearances)
AddUnitAppearance(targetList)
RemoveUnitAppearance(targetList, index)
MoveUnitAppearance(targetList, index, delta)
BindUnitAppearanceEditor(targetList, index)
```

Equivalent organization is acceptable.

Presentation states:

```text
#preset.appearances == 0
-> "Using Base Unit appearance pool"

#preset.appearances > 0
-> "Preset appearance pool overrides Base Unit appearances"
```

Do not add a separate override checkbox.

---

# 12. Phase 9 — Add Preset selection to Event Unit window

Primary file:

```text
server/ui/window_EventUnit.lua
```

## 12.1 Add selected Preset state

Add:

```text
self.selectedPresetIndex
```

Base/default:

```text
0
```

Reset it when selecting a different Unit.

## 12.2 Add Preset dropdown

After a Unit is selected, build items from that Unit:

```text
Base       -> 0
Marauder   -> 1
Hedge Wizard -> 2
...
```

Preserve authored order.

When no Unit is selected, disable/reset the Preset dropdown.

## 12.3 Preview resolved variant

Do not preview the raw Base Unit once a Preset is selected.

Use the shared pure resolver for:

```text
variant name
Preset-modified Stats for preview
Preset-modified Resources for preview where player-count context is unavailable
appearance pool
```

The Add-NPC preview does not need to reproduce every Event scaling rule exactly if it lacks final player count/difficulty context, but it must clearly show the selected Preset's authored effect. If the Event draft already provides player count/difficulty, prefer the same server preview helper used for materialization.

For Health preview, use one shared server-side preview calculation if possible so authors do not see a number that differs from what Add To Event creates.

## 12.4 Preview appearance choice

The preview must not consume the eventual EventUnit's random selection merely by refreshing UI.

Use one of these approaches:

```text
preview appearance 1 deterministically
```

or maintain a preview-only index.

The authoritative random `appearanceIndex` is selected only when Add To Event commits the NPC.

## 12.5 Callback options

Extend `ApplySelection()` callback options with:

```lua
presetIndex = normalizedPresetIndex
```

Do not pass a deep-copied fully resolved Unit as the authoritative source of truth. The server should resolve from `registryID + presetIndex` during materialization.

---

# 13. Phase 10 — Centralize server-side variant materialization

Primary file:

```text
server/server_Event.lua
```

This is the most important runtime phase.

Add one central helper equivalent to:

```lua
Server:BuildResolvedNpcVariant(registryId, options)
```

or a local pure/server helper invoked by every NPC creation path.

It should return enough information for EventUnit construction:

```lua
{
    dataset = ...,
    baseUnit = ...,
    presetIndex = ...,
    preset = ...,
    name = ...,
    spells = ...,
    stats = ...,
    resources = ...,
    effectiveAppearances = ...,
    appearanceIndex = ...,
    appearance = ...,
    challengeLevel = ...,
}
```

Do not expose Dataset tables as mutable runtime state.

## 13.1 Resolution inputs

Inputs must include:

```text
registryID
presetIndex
playerCount
Event difficulty / Event state where required
whether random appearance should be selected
```

## 13.2 Stats

Resolve:

```text
copy Base Unit stats
-> apply Preset stat modifiers
-> runtime stats
```

The Base Unit definition is never changed.

## 13.3 Resources

Use the existing resource materialization path rather than building a second one.

Final order:

```text
Base resource value
-> challenge-level-gated `perPlayer * playerCount` addition (#82 when present)
-> Preset percentage/flat modifier
-> difficulty Health percentage (#83 when present)
-> runtime current/max value
```

Preset Resource modifiers apply to every referenced Resource, not only Health.

Difficulty Health modifier applies only to the Ruleset health resource as specified by #83.

### Missing resource target

If a Preset references a Resource absent from the Base Unit:

```text
base = 0
perPlayer = 0
-> apply Preset modifier
```

A flat modifier can therefore create a runtime Resource.

If the result remains zero and no Base Unit resource exists, omitting the no-op runtime entry is acceptable as long as lookup semantics remain equivalent to zero.

## 13.4 Random appearance selection

After resolving the effective appearance pool:

```text
empty -> appearanceIndex = 0
non-empty -> math.random(1, #pool)
```

Select exactly once when an EventUnit is materially added/spawned.

Do not reroll during:

```text
copy live Event to draft
Event refresh
network broadcast
client reconnect snapshot
portrait refresh
EventUnit delta resend
```

For a draft NPC added before Event start, the chosen `appearanceIndex` should be stored in the draft EventUnit and retained into the live Event rather than rerolled at start.

## 13.5 Variant name

Write the resolved name into runtime EventUnit `name`:

```text
Brigand Marauder
```

This remains useful even if the definition cannot be resolved later.

---

# 14. Phase 11 — Thread Preset identity through all NPC creation paths

Audit every call that creates an NPC definition/runtime Unit.

At minimum:

```text
Server:BuildEventNpcUnitDataFromDefinition
Server:AddEventNpcUnitFromDefinition
Server:AddEventNpcUnit
Server:SummonEventPetUnit
buildNpcUnit
```

## 14.1 Manual Event NPC

`BuildEventNpcUnitDataFromDefinition(registryId, options)` must preserve normalized:

```text
presetIndex
```

and the materialization path must select/store `appearanceIndex` once.

## 14.2 Existing Base behavior

Callers which provide no Preset continue to resolve:

```text
presetIndex = 0
```

with identical Base Unit mechanical behavior.

## 14.3 Summoned units

Extend summon options to accept optional:

```text
presetIndex
```

Default `0`.

Do not create a summon-specific modifier implementation.

`SummonEventPetUnit()` should call the same Base Unit + Preset materializer and then apply its existing summon-specific owner/controller/pet/spell/stat overrides in the same semantic order as today.

Audit carefully if summoned options currently replace/merge Stats. Preset resolution must happen before summon-specific explicit runtime overrides so an explicitly supplied summon override remains authoritative.

## 14.4 Compact summon delta

Audit `buildCompactSummonedUnitDelta(...)`.

If it manually selects EventUnit fields, add:

```text
presetIndex
appearanceIndex
```

or stop omitting them if safe.

A summoned Preset NPC must render with the same appearance after remote delta hydration.

---

# 15. Phase 12 — Extend `EventUnit.lua`

Primary file:

```text
core/classes/EventUnit.lua
```

Add defaults:

```lua
presetIndex = 0,
appearanceIndex = 0,
```

Normalize both as non-negative integers.

Add to `ToTable()`.

## 15.1 Resolved Preset helper

Add definition-facing helpers where useful:

```lua
EventUnit:GetResolvedPreset()
EventUnit:GetResolvedVariantName()
EventUnit:GetResolvedAppearance()
```

These should delegate to `Unit` pure resolver logic rather than duplicate it.

`GetResolvedAppearance()` should resolve:

```text
GetResolvedUnit()
-> presetIndex
-> effective pool
-> appearanceIndex
```

For an invalid incoming appearance index, use the documented presentation fallback.

## 15.2 Runtime values remain authoritative

`GetResolvedValue("stats")` / `GetResolvedValue("resources")` must continue preferring explicit runtime values when present.

Do not recalculate Preset combat Stats every time `GetResolvedValue` is called if the server has already materialized them.

If a network optimization still uses `_networkStatMode = inherit` or `_networkResourceMode = inherit` for NPCs, audit it carefully. Preset variants should not silently rely on client-side recomputation when the PDD requires host-materialized authoritative combat values.

Preferred implementation:

```text
Preset NPC mechanical stats/resources transmitted explicitly
```

unless the existing protocol can prove identical authority while retaining a compact mode.

---

# 16. Phase 13 — Extend Event network serialization

Primary file:

```text
core/classes/Event.lua
```

Append to the modern EventUnit record after all existing fields:

```text
presetIndex
appearanceIndex
```

Do **not** insert them before existing resource/stat/boss/threat positions.

Conceptual modern record tail:

```text
...
boss
threatTable
presetIndex
appearanceIndex
```

## 16.1 Deserialization

Use field-count checks:

```text
legacy/older modern payload
-> presetIndex = 0
-> appearanceIndex = 0

new payload
-> read appended fields
```

Normalize through `EventUnit.FromTable()`.

## 16.2 Full snapshots and deltas

Validate both:

```text
Event:SerializeUnitsForNetwork()
Event.SerializeUnitDeltaBatchForNetwork(...)
```

because both rely on unit serialization.

## 16.3 Draft/live cloning

Audit:

```text
cloneUnits(...)
copyLiveEventToDraft(...)
Event:ToTable()
Event:Merge()
```

so the new values survive:

```text
draft -> live
live -> draft
Event normalization
client snapshot
```

---

# 17. Phase 14 — Update `UnitPortrait` to use resolved Appearance

Primary file:

```text
core/ui/prefabs/UnitPortrait.lua
```

Replace the current fixed-definition model selection in `ResolveModelPortraitState(...)`.

For NPC EventUnits:

```text
EventUnit:GetResolvedAppearance()
-> displayId/fileDataId/cam/rot/z
```

For non-Event Unit preview objects where no EventUnit helper exists, allow a direct Appearance object or canonical Unit fallback.

Do not randomize inside `UnitPortrait`.

Do not choose a different appearance when the portrait refreshes.

## 17.1 Backward safety

Legacy runtime Units with no `presetIndex` / `appearanceIndex` normalize to Base/0.

Legacy definitions loaded through new `Unit` normalization have their old single model represented as `appearances[1]`.

Therefore old NPCs continue rendering their existing model.

---

# 18. Phase 15 — Update Event Manager presentation

Primary files:

```text
server/ui/window_EventUnit.lua
server/ui/eventmanage/page_EventManageUnits.lua
server/ui/eventmanage/page_EventManageShared.lua
```

The unit table already displays `rowData.name`, so host-materialized variant names should flow naturally.

Audit row-building code to ensure it does not replace the EventUnit name with the Base Unit definition name.

For the EventUnit view window, add contextual display where practical:

```text
Base Unit: Brigand
Preset: Marauder
```

Do not overload the main Event table with extra columns unless the current width allows it without degrading the existing layout. The resolved Name is the primary list presentation.

The Event Unit view preview must use the selected runtime `appearanceIndex`, not a freshly chosen preview model.

---

# 19. Phase 16 — Reconcile `EventUnit.BuildResolvedResources` fallback

`core/classes/EventUnit.lua` currently contains a fallback definition-resource resolver which can apply Unit `perPlayer` values when explicit runtime resources are absent.

This path must not diverge from the new Preset semantics.

Preferred final rule:

```text
normal authoritative Event NPC
-> explicit runtime resources already present
-> fallback not responsible for normal variant mechanics
```

However, if hydration/legacy paths can still legitimately call `EventUnit.BuildResolvedResources(eventUnit, playerCount)`, add enough options/context to reproduce:

```text
Base resource
-> perPlayer policy
-> Preset modifier
```

without reading active Event difficulty inside the Unit class.

Do not leave a hidden path where a Preset NPC uses Base resources because the fallback ignores `presetIndex`.

This audit must be coordinated with #82.

---

# 20. Phase 17 — Interaction with difficulty combat modifiers

Preset Stats are materialized into the NPC's runtime Stat list before combat.

Therefore #83's combat-time modifiers remain separate:

```text
Preset modifies Attack Power / Spell Power / Armour / Crit etc.
-> normal combat formulas use resolved runtime Stats
-> Heroic/Mythic outgoing damage/hit/defence modifiers apply at their existing Event difficulty layer
```

Do not make the Preset resolver know about Heroic/Mythic hit or damage rules.

Only difficulty **Health** belongs in NPC resource materialization.

---

# 21. Phase 18 — Load order

If `page_InspectorUnitModel.lua` is replaced/renamed and `page_InspectorUnitPresets.lua` is added, update:

```text
RPEngine_Dev.toc
```

Required ordering:

```text
core/classes/Unit.lua
core/classes/EventUnit.lua
core/classes/Event.lua
...
Unit editor shared helpers
Unit appearance editor
Unit presets editor
page_InspectorUnit.lua
...
UnitPortrait before windows/pages that instantiate it
```

Follow the existing precise TOC organization rather than moving unrelated modules.

---

# 22. Implementation invariants

The implementation must preserve these invariants throughout all phases.

## Definition immutability

```text
resolving/spawning a variant
!= mutating Unit definition
```

No runtime path writes resolved values back into:

```text
unit.stats
unit.resources
unit.presets
unit.appearances
```

## Host authority

```text
Preset selection -> host input
appearance randomization -> host only
runtime mechanical materialization -> host
```

Clients receive state and render it.

## Index meaning

```text
presetIndex 0 = Base
appearanceIndex 0 = no selected model
```

## Appearance fallback

```text
Preset pool non-empty -> override
Preset pool empty -> Base pool
```

No merging.

## Modifier formula

```text
base * (1 + percent/100) + flat
```

Percentage first; flat second.

## Resource composition

```text
base
-> player count
-> Preset
-> difficulty Health
```

## No duplicated variant engines

Editor preview, manual Event add, summon path, EventUnit resolution and portraits consume shared resolvers rather than reimplementing formulas independently.

---

# 23. Static validation

At the end of each relevant phase:

1. run the repository's normal Lua syntax/static checks if present;
2. load all modified Lua files in the normal TOC order where the project's test harness permits;
3. inspect Dataset export/import of new Unit definitions;
4. inspect one old Dataset containing legacy Unit model fields;
5. search for remaining direct Unit `displayId/fileDataId/cam/rot/z` assumptions.

Repository-wide searches required before completion:

```text
.displayId
.fileDataId
.cam
.rot
.z
BuildEventNpcUnitDataFromDefinition
AddEventNpcUnitFromDefinition
buildNpcUnit
SummonEventPetUnit
BuildResolvedResources
SerializeUnitsForNetwork
SerializeUnitDeltaBatchForNetwork
ResolveModelPortraitState
```

Inspect matches rather than mechanically replacing unrelated model fields belonging to other classes.

---

# 24. Required validation matrix

## Legacy Unit loading

```text
old Unit:
  displayId = 123
  cam = 1.2
  rot = 0.1
  z = -0.3
  no appearances
  no presets

load
-> appearances[1] contains same model/transforms
-> presets = {}
-> editor shows one Appearance
-> Base spawn looks/mechanically behaves as before
```

## New Base Unit

```text
Brigand
Health 100
Attack Power 50
Spell Power 20
Armour 40
Spell Crit 5

spawn Base
-> name Brigand
-> presetIndex 0
-> no Preset modifiers
```

## Marauder

```text
Health +10%
Attack Power +10%
Spell Power -10%
Armour +10%

spawn
-> name Brigand Marauder
-> Health 110 before player-count/difficulty composition where those are absent
-> AP 55
-> Spell Power 18
-> Armour 44
```

## Hedge Wizard flat-percent distinction

```text
Health -10%
Spell Power +30%
Spell Crit +5 flat

-> Health 90
-> Spell Power 26
-> Spell Crit 10
```

Verify `Spell Crit +5%` would instead yield `5.25`, proving Percent and Flat are distinct.

## Missing Stat

```text
Base has no Spell Crit
Preset flat Spell Crit +5
-> runtime Spell Crit 5

Preset percent Spell Crit +30%, no flat
-> effective value 0
```

## Player scaling composition

Assume:

```text
Base Health 100
perPlayer 20
playerCount 5
Marauder +10%
```

Expected:

```text
100 + 20*5 = 200
200 * 1.10 = 220
```

If Heroic +10% Health is enabled:

```text
220 * 1.10 = 242
```

## Flat Resource modifier

```text
Base Health resolves to 200 after player scaling
Preset Health +25 flat
-> 225
```

## Negative Resource floor

```text
Base resource 10
Preset -200% and -5 flat
-> runtime max clamps to 0, never negative
```

## Appearance inheritance

```text
Base appearances A/B/C/D
Preset appearances empty
-> effective A/B/C/D
```

## Appearance override

```text
Base appearances A/B/C/D
Marauder appearances E/F
-> effective E/F only
```

## Host appearance authority

```text
host adds Marauder
-> host selects appearanceIndex 2
-> local portrait = F
-> remote client = F
-> reconnect snapshot = F
-> Event refresh = F
-> no reroll
```

## Multiple copies

```text
add same Marauder three times
-> each EventUnit independently selects/stores appearance index
-> all clients agree on each individual result
```

## Preset reorder authoring

```text
Unit presets: Marauder, Hedge Wizard
spawn Marauder -> live EventUnit snapshot exists
reorder Dataset presets in editor
-> existing runtime Stats/name remain unchanged
-> future spawn indexes follow new authored order
```

Appearance rendering of already-live units should remain stable under normal gameplay assumptions; do not proactively rewrite live EventUnits from editor changes.

## Full snapshot

```text
start/reconnect Event with Preset NPC
-> presetIndex preserved
-> appearanceIndex preserved
-> resolved name preserved
-> explicit runtime Stats/Resources preserved
```

## Delta

```text
add Preset NPC to active Event
-> delta contains presetIndex + appearanceIndex
-> remote client uses correct appearance
```

## Summon

```text
summon Base Unit without preset option
-> presetIndex 0

summon with presetIndex
-> same variant formulas and appearance behavior as manual Event add
```

## Invalid indices

```text
presetIndex 999
-> Base Unit fallback, no Lua error

appearanceIndex 999 with non-empty pool
-> presentation safely falls back to first appearance

empty pool
-> appearanceIndex 0/no model fallback
```

---

# 25. Definition of done

- [ ] PDD data model is represented canonically in `Unit.lua`.
- [ ] Legacy single-model Units migrate to one-entry appearance pools.
- [ ] Dataset schema is incremented from the authoritative current value.
- [ ] Unit definitions support ordered Presets and appearances.
- [ ] Preset Stat and Resource modifiers support flat and percentage bonuses.
- [ ] Percentage-before-flat formula is implemented once and reused.
- [ ] Base Unit Stats/Resources are never mutated during variant resolution.
- [ ] Unit editor has a functional Appearance Pool page.
- [ ] Unit editor has a functional Presets page.
- [ ] Presets support add/duplicate/delete/reorder.
- [ ] Preset Stat/Resource modifier editors use proper reference selectors.
- [ ] Presets support their own override appearance pool.
- [ ] Event Unit add window exposes Base + Preset selection.
- [ ] Server uses one shared NPC variant materializer.
- [ ] Host chooses appearance exactly once per NPC creation.
- [ ] Runtime EventUnit stores `presetIndex` and `appearanceIndex`.
- [ ] Runtime variant name is materialized as `<Base> <Preset>`.
- [ ] Runtime Stats/Resources contain resolved Preset mechanics.
- [ ] Full Event unit snapshots transport Preset/appearance identity.
- [ ] EventUnit delta packets transport Preset/appearance identity.
- [ ] Draft/live cloning preserves both values.
- [ ] Summoned NPCs use the same variant resolver.
- [ ] UnitPortrait renders the host-selected effective Appearance.
- [ ] Client portrait refresh never randomizes an NPC appearance.
- [ ] Player-count -> Preset -> difficulty Health ordering is validated.
- [ ] Challenge level remains a Base Unit property and is not Preset-overridden.
- [ ] Existing EventUnit `boss` semantics remain independent.
- [ ] Legacy Base Units still spawn and display correctly.
- [ ] Static validation and the full matrix above pass.

---

# 26. Recommended implementation breakdown

This is large enough to implement in bounded tasks while keeping the repository buildable after each merge.

Recommended sequence:

```text
Task 1 — Unit schema + pure resolver
  Unit appearances
  Presets/modifiers
  legacy normalization
  Dataset schema

Task 2 — Data Editor Appearance Pool
  replace single Model page
  appearance list/editor/reorder

Task 3 — Data Editor Presets
  Preset lifecycle
  Stat modifiers
  Resource modifiers
  Preset appearances

Task 4 — Event runtime + network
  preset selection in Event Unit window
  central server materialization
  EventUnit fields
  Event serialization/deltas
  summons

Task 5 — Portrait/presentation integration
  UnitPortrait appearance resolution
  Event Unit preview/view
  Event Manager validation

Task 6 — Scaling/difficulty integration audit
  #82 per-player ordering
  #83 Health ordering
  regression/static/in-game matrix
```

Do not start Task 4 with a second temporary Preset formula if Task 1's shared resolver is not yet available.

---

# 27. Coding-agent handoff requirements

Before implementation, inspect the authoritative current versions of:

```text
core/classes/Unit.lua
core/classes/EventUnit.lua
core/classes/Event.lua
core/internal/database/Database.lua
client/ui/editor/inspectors/page_InspectorUnit.lua
client/ui/editor/inspectors/unit/page_InspectorUnitShared.lua
client/ui/editor/inspectors/unit/page_InspectorUnitModel.lua
client/ui/editor/inspectors/unit/page_InspectorUnitStats.lua
client/ui/editor/inspectors/unit/page_InspectorUnitResources.lua
server/ui/window_EventUnit.lua
server/server_Event.lua
core/ui/prefabs/UnitPortrait.lua
server/ui/eventmanage/page_EventManageUnits.lua
server/ui/eventmanage/page_EventManageShared.lua
RPEngine_Dev.toc
```

Also inspect the final implementations of #81/#82/#83 if they have landed.

At handoff, report:

1. the final Unit/Preset/Appearance serialized shapes;
2. exact legacy migration behavior;
3. final Dataset schema transition;
4. pure modifier formula/helper API;
5. authoritative NPC materialization sequence;
6. exact player-count/Preset/difficulty Resource order;
7. host appearance selection point and reroll guards;
8. EventUnit field additions;
9. network record additions and backward-read behavior;
10. every NPC creation path audited;
11. editor files/pages added or renamed;
12. portrait resolution changes;
13. files changed;
14. static validation results;
15. validation-matrix results.

Use current `FrontierDev/rpe2` as authoritative rather than implementing from this plan against stale line numbers or assumptions.
