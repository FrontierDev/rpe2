# RPE 2 — Damage, Healing and Threat Meters
## Implementation Plan

**Status:** Planned  
**Target:** `dev` branch  
**Scope:** Event damage meter, healing meter, threat meter, Event Widget access, event/rejoin synchronization

---

# 1. Goal

Add an event-scoped **Meters** panel to the Event Widget with three views:

- **Damage** — total damage dealt by each Event Unit during the current event.
- **Healing** — total healing done by each Event Unit during the current event.
- **Threat** — the current threat table for a selected NPC Event Unit.

The feature should behave like a conventional combat meter:

- rows sorted from highest to lowest;
- proportional horizontal bars;
- rank, unit name, total and percentage;
- live updates while the event runs;
- all event participants see the same damage/healing totals;
- threat is shown per NPC because RPE threat is target-specific rather than a single global value;
- the meter resets when the event changes/ends;
- a player joining or rejoining an event receives the current damage/healing meter snapshot.

The system should reuse RPE's existing combat-log and threat synchronization instead of creating a second combat-reporting pipeline.

---

# 2. Current Architecture Findings

## 2.1 The Event Widget already has the correct access point

`client/ui/widgets/widget_Event_CombatLogHistory.lua` creates the button row immediately below the Event Widget header banner:

```text
Combat Log
DM Helper        [host only]
NPC/Combat Mode  [host only]
```

`widget_Event_DMHelper.lua` already extends that same row through:

```lua
self.combatLogHistoryButtonRow:AddChild(...)
```

The new **Meters** button should be added to this row rather than creating another control strip.

Recommended order for normal players:

```text
Combat Log | Meters
```

Recommended host order:

```text
Combat Log | Meters | DM Helper | NPC/Combat Mode
```

---

## 2.2 The combat log is already distributed event-wide

`client/client_CombatLog.lua` already:

1. normalizes damage/heal/status entries;
2. queues the local copy;
3. broadcasts the entry to PARTY/RAID through the existing `COMBAT_LOG` opcode;
4. ignores the physical self-copy from PARTY/RAID so the sender does not receive the same entry twice.

This makes the combat-log stream the correct fan-out mechanism for the damage/healing meter.

A separate `METER_UPDATE` opcode is not required.

---

## 2.3 The visible ticker payload is presentation-oriented

The meter must **not** calculate totals by parsing the ticker text or by multiplying `amountMin`/`amountMax` by `targetCount`.

Current combat-log aggregation deliberately collapses multi-target results for display.

Examples:

- `Combat:RegisterActionDamageCombatLog()` stores the minimum and maximum damage across targets and later emits one aggregate entry.
- `emitResolvedHealCombatLog()` stores target count plus minimum/maximum healing and emits one aggregate entry.

Therefore this is valid presentation data:

```text
Caster -> 5 targets    16-24 Healing
```

but it is insufficient to reconstruct the exact total healing done to all five targets.

The implementation should preserve an additional hidden exact amount on the combat-log entry before the values are collapsed for presentation.

---

## 2.4 Threat already has a synchronized authoritative model

Threat does not need to be rebuilt from combat-log entries.

RPE already stores threat on each NPC Event Unit:

```lua
npcEventUnit.threatTable[sourceEventId] = threat
```

Damage resolution produces explicit threat updates containing:

```lua
{
    targetEventId = npcEventId,
    sourceEventId = sourceEventId,
    amount = generatedThreat,
}
```

`client/client_Resources.lua` normalizes/coalesces these threat updates and the server applies them to authoritative Event Unit state.

The Event Widget already reads `eventUnit.threatTable` for threat tooltip information.

Therefore the Threat meter should render the selected NPC's **current threat table directly** rather than maintaining a second cumulative threat ledger.

This is also closer to a conventional threat meter: threat against NPC A is not interchangeable with threat against NPC B.

---

# 3. Meter Semantics

## 3.1 Damage

Damage is accumulated for the Event Unit which caused the combat-log entry.

The meter value for a multi-target damage entry is the exact sum represented by that entry, calculated before the combat-log presentation collapses the results to min/max.

Triggered/bonus damage represented by the same resolved damage action must also be included in the exact meter amount.

Absorbed damage should **not** be added to Damage Done. The meter represents health damage dealt, while absorption remains presentation/detail information.

---

## 3.2 Healing

Healing is accumulated for the Event Unit which caused the heal entry.

For the first version, the meter should use the same resolved healing values represented by the event combat-log/ticker path. For multi-target healing, sum the individual result amounts before min/max presentation aggregation.

Do not attempt to infer a total from the final ticker entry.

**Out of scope for this implementation:** a separate overhealing statistic. If effective-healing/overhealing breakdown is later desired, it should be added explicitly from `appliedDelta`/authoritative health deltas rather than changing the meaning of the initial meter silently.

---

## 3.3 Threat

Threat is displayed **per hostile NPC Event Unit**.

The Threat view should contain a target selector listing active NPC units that can own threat tables. Selecting a unit renders:

```lua
selectedNpc.threatTable
```

as ranked rows.

The displayed value is current threat, not "threat generated during the event".

Taunt state does not itself become fake numerical threat. Any actual threat values changed by existing threat mechanics are naturally reflected by the NPC's synchronized `threatTable`.

---

# 4. Combat-Log Metadata Extension

Extend the normalized combat-log entry with meter metadata which is transported but not displayed by the ticker.

Proposed fields:

```lua
casterEventId = 12,
meterAmount = 57,
```

Where:

- `casterEventId` is the Event Unit ID responsible for the damage/healing;
- `meterAmount` is the exact total represented by this combat-log entry.

For ordinary single-target entries:

```lua
meterAmount = amount
```

For aggregate multi-target entries:

```lua
meterAmount = sum(all represented target results)
```

The meter metadata must be optional so status entries and older/internal callers remain valid.

### Required `client/client_CombatLog.lua` changes

Update:

```text
NormalizeCombatLogEntry()
BuildCombatLogArguments()
HandleCombatLog()
```

so `casterEventId` and `meterAmount` survive PARTY/RAID transport.

Append these fields to the existing argument list rather than reordering existing positions.

Do not change `BuildCombatLogDisplayText()`; meter metadata is not ticker text.

---

# 5. Producing Exact Damage Totals

## 5.1 Aggregate spell damage

In `client/combat/Helpers.lua`, extend the aggregate created by:

```lua
Combat:RegisterActionDamageCombatLog()
```

with:

```lua
casterEventId
meterAmount
```

Each resolved target adds its represented damage to `meterAmount`.

`Combat:RegisterTriggeredActionBonusDamage()` must add represented triggered bonus damage to the same `meterAmount` so the meter and the action's actual output remain consistent.

`Combat:FlushActionDamageCombatLog()` then passes the final exact total and caster Event Unit ID into `EmitCombatLogEntry()`.

## 5.2 Single-target remote-defender damage

`emitSingleTargetDamageCombatLog()` should include:

```lua
casterEventId = attackerUnit.eventID
meterAmount = damageResult.amount
```

This preserves the existing remote-defender path without requiring special meter handling.

## 5.3 Periodic/aura/trait damage

Any damage emission path which bypasses `RegisterActionDamageCombatLog()` must include the same optional fields when the source Event Unit is known.

Likely affected call sites include damage entries emitted by:

```text
client/spellcasting/AuraManager.lua
client/client_Traits.lua
```

The implementation should search all `entryType = "damage"` emission sites and ensure attributable damage includes `casterEventId` and `meterAmount`.

Damage entries without a valid source Event Unit ID remain visible in the combat log but are not attributed to a meter row.

---

# 6. Producing Exact Healing Totals

In `client/spellcasting/Helpers.lua`, update `emitResolvedHealCombatLog()`.

While iterating `targetResults`, accumulate:

```lua
meterAmount = meterAmount + result.amount
```

for each represented valid heal result.

Emit:

```lua
casterEventId = casterUnit.eventID
meterAmount = meterAmount
```

alongside the existing display fields:

```lua
targetCount
amountMin
amountMax
```

Any other direct heal combat-log emission path should receive the same treatment.

Healing entries without a valid source Event Unit ID remain visible but are not attributed to a meter row.

---

# 7. Meter Runtime

Add:

```text
client/client_EventMeters.lua
```

Recommended namespace:

```lua
Addon.Client.EventMeters
```

The runtime owns event-scoped damage/healing totals only.

Suggested shape:

```lua
EventMeters.ByEventId[eventId] = {
    damage = {
        [casterEventId] = {
            eventId = casterEventId,
            name = "Player A",
            team = 1,
            amount = 123,
        },
    },

    healing = {
        [casterEventId] = {
            eventId = casterEventId,
            name = "Player B",
            team = 1,
            amount = 86,
        },
    },
}
```

Store the last known name/team with the row so a unit which becomes inactive can still be represented correctly for the rest of that event.

Recommended API:

```lua
EventMeters:ResetEvent(eventId)
EventMeters:ClearAll()
EventMeters:RecordCombatLogEntry(entry, eventState)
EventMeters:GetRows(eventId, meterType)
EventMeters:GetSnapshot(eventId)
EventMeters:InstallSnapshot(eventId, snapshot, replaceExisting)
```

`GetRows()` should return display-ready rows sorted descending by amount, then by Event Unit ID for deterministic ties.

---

# 8. Hook Point

The cleanest integration point is `Client:QueueCombatLogEntry()` in `client/client_CombatLog.lua`.

Flow:

```text
combat result
    ↓
NormalizeCombatLogEntry
    ↓
Client:QueueCombatLogEntry
    ├─ EventMeters:RecordCombatLogEntry(...)
    └─ EventWidget:QueueCombatLogEntry(...)
```

This has several advantages:

- local emitters count once;
- remote PARTY/RAID entries count once;
- the existing self-copy guard prevents double counting;
- ticker coalescing occurs later and therefore cannot destroy meter totals;
- status/aura messages are naturally ignored by the meter runtime.

Only entries satisfying all of the following should be recorded:

```text
entry.eventId == active event ID
entry.entryType == damage or heal
casterEventId > 0
meterAmount > 0
```

---

# 9. Damage/Healing Synchronization and Rejoin

Live participants automatically remain synchronized because every accepted `COMBAT_LOG` entry is distributed through the existing group transport.

A late join/reload needs a snapshot because it did not receive earlier combat-log messages.

Extend the existing event rejoin snapshot rather than adding another request/response protocol.

Current `EventRejoinState` protocol serializes:

```text
auras
casts
```

Extend it to include:

```text
meters
```

Recommended protocol change:

```text
ProtocolVersion 2 -> 3
```

Snapshot content only needs cumulative damage/healing rows:

```lua
{
    damage = {
        { eventId = 1, amount = 123, name = "...", team = 1 },
    },
    healing = {
        ...
    },
}
```

Threat does not need a meter snapshot because it is already represented by Event Unit threat state.

### Required files

```text
core/internal/comms/EventRejoinState.lua
server/server_EventRejoinState.lua
client/client_EventRejoinState.lua
```

### Compatibility

The deserializer should continue accepting the existing supported v1/v2 snapshots and treat their meter state as empty.

For v3:

1. deserialize meter rows;
2. validate non-negative values and positive Event Unit IDs;
3. install/replace meter state during rejoin;
4. refresh the Meters panel if it is visible.

The host should source the rejoin meter snapshot from the same EventMeters runtime that receives the complete combat-log stream.

---

# 10. Event Lifecycle

Damage/healing meter data is an **event segment**, not permanent character data.

Do not add SavedVariables or Profile schema fields.

Required lifecycle behavior:

```text
new event ID
    -> create/reset meter bucket

event ends
    -> hide meter panel and clear active bucket

same event refresh/rejoin
    -> retain/install current event snapshot
```

The meter must never leak totals between Event IDs.

---

# 11. Event Widget UI

Add:

```text
client/ui/widgets/widget_Event_Meters.lua
```

Load it after:

```text
widget_Event_CombatLogHistory.lua
```

because it uses the existing utility-button row.

## 11.1 Meters button

Add a normal-player-visible button:

```text
Meters
```

using the same dimensions and visual style as `Combat Log`.

The Meters panel and Combat Log/DM Helper side panel should not overlap.

Opening Meters should hide the Combat Log/DM Helper panel if it is open.

Opening Combat Log or DM Helper should hide the Meters panel.

---

## 11.2 Panel layout

Recommended side panel:

```text
┌──────────────────────────────────────────────┐
│ Meters                                       │
│ [ Damage ] [ Healing ] [ Threat ]            │
├──────────────────────────────────────────────┤
│ 1. Player A   █████████████████  1,248  42% │
│ 2. Player B   ███████████          824  28% │
│ 3. NPC 3      ███████              566  19% │
│ ...                                          │
└──────────────────────────────────────────────┘
```

Use existing RPE UI primitives rather than Blizzard templates:

```text
Panel
HorizontalLayoutGroup
TextButton
ScrollLayout
Text / frame textures for bars
Dropdown (Threat target selector)
```

The meter should refresh rows without rebuilding the entire Event Widget.

---

## 11.3 Damage/Healing row behavior

Rows should contain:

```text
rank
unit name
total
percentage of all displayed damage/healing
bar proportional to the highest row
```

Recommended formatting:

```text
1. Player Name          1,248   42.3%
```

The bar width is relative to the highest value, not the percentage of group total.

Use Event team color for the unit label/bar when available.

Highlighting the local player's row is optional UI polish, not required for correctness.

Do not display DPS/HPS: RPE combat is turn-based and a wall-clock throughput value would be misleading.

---

## 11.4 Threat view

Threat view adds an NPC selector above the rows:

```text
Target: [ Boss Name v ]
```

Eligible targets:

- active non-player Event Units;
- preferably units with a non-empty `threatTable`;
- bosses first, then normal NPCs in deterministic Event Unit order.

If exactly one eligible NPC exists, select it automatically.

Rows come directly from:

```lua
selectedNpc.threatTable
```

For each `sourceEventId`:

1. resolve the source Event Unit from `eventState.units`;
2. read current threat;
3. discard zero/negative values;
4. sort descending;
5. show total and percentage relative to the highest threat holder.

Recommended threat display:

```text
1. Tank       █████████████████  842   100%
2. Mage       ███████████        611    73%
3. Priest     ███████            402    48%
```

For Threat, the percentage is relative to the current leader on that NPC, which is more useful than percentage of total threat.

---

# 12. Refresh Strategy

Do not refresh the Meters UI on every frame.

Damage/healing:

```text
accepted combat-log entry
    -> update EventMeters data
    -> if Meters panel visible and current tab affected:
         queue one deferred refresh
```

Threat:

Threat changes already flow through resource/threat synchronization and Event Widget refresh paths.

Add a small `QueueMetersRefresh(reason)` helper which coalesces repeated updates within the same frame/task queue.

The panel should also refresh when:

```text
Meters panel opens
meter tab changes
Threat target changes
event state refreshes
rejoin meter snapshot installs
```

---

# 13. File Changes

## New

```text
client/client_EventMeters.lua
client/ui/widgets/widget_Event_Meters.lua
```

## Modify

```text
RPEngine2.toc
client/client_CombatLog.lua
client/combat/Helpers.lua
client/spellcasting/Helpers.lua
client/spellcasting/AuraManager.lua        [if its damage emission lacks metadata]
client/client_Traits.lua                   [if its damage emission lacks metadata]
core/internal/comms/EventRejoinState.lua
server/server_EventRejoinState.lua
client/client_EventRejoinState.lua
client/ui/widgets/widget_Event_CombatLogHistory.lua
client/ui/widgets/widget_Event_DMHelper.lua
```

The last two UI files only need small mutual-exclusion hooks so their side panel cannot overlap the Meters panel.

---

# 14. Implementation Stages

## Stage 1 — Meter data model

Implement `client_EventMeters.lua` with:

- per-event buckets;
- damage/healing accumulation;
- row sorting;
- snapshot export/import;
- lifecycle reset helpers;
- deterministic tests for aggregation and replacement/merge behavior.

No UI yet.

---

## Stage 2 — Combat-log metadata

Add `casterEventId` and `meterAmount` to the combat-log contract.

Update all damage/healing emission paths so exact totals survive multi-target presentation aggregation.

Hook `Client:QueueCombatLogEntry()` into EventMeters.

Validate:

- single-target damage;
- multi-target damage with different target values;
- triggered bonus damage;
- periodic/aura damage;
- single-target healing;
- multi-target healing;
- duplicate PARTY/RAID self-copy does not double count.

---

## Stage 3 — Meters UI

Add the Meters button and side panel.

Implement:

- Damage tab;
- Healing tab;
- Threat tab;
- NPC threat target selector;
- proportional bars;
- sorted rows;
- live refresh;
- side-panel mutual exclusion.

---

## Stage 4 — Rejoin snapshot

Bump `EventRejoinState` to v3 and serialize damage/healing meter rows.

Install meter state when a client rejoins before the final Event Widget refresh.

Threat requires no additional snapshot field.

---

# 15. Acceptance Criteria

The feature is complete when all of the following are true.

## Damage

```text
A 20-damage single-target hit adds 20 to the caster.

A multi-target hit dealing 20, 25 and 30 adds 75, even if the ticker
shows the compact presentation "20-30" against 3 targets.

Triggered bonus damage is included exactly once.

Absorbed damage is not counted as Damage Done.

Periodic/aura damage is attributed to the correct caster Event Unit.
```

## Healing

```text
A 30-heal adds 30 to the healer.

A multi-target heal of 20, 25 and 30 adds 75, even if the ticker only
shows "20-30" against 3 targets.

Healing is attributed by Event Unit ID, not by display-name string.
```

## Threat

```text
Selecting NPC A shows NPC A's threatTable.

Selecting NPC B shows NPC B's independent threatTable.

Rows update when synchronized threat values change.

Taunt state does not fabricate a numerical threat value.
```

## Synchronization

```text
Every current event participant sees the same damage/healing totals.

The sender does not double count its own COMBAT_LOG transport echo.

A client joining/rejoining mid-event receives the current damage/healing
snapshot.

Threat is immediately correct from synchronized Event Unit state.

Starting a different event clears the previous event's meters.
```

## UI

```text
A Meters button appears under the Event Widget for all participants.

Damage, Healing and Threat can be switched without closing the panel.

Rows are sorted highest-first and use proportional bars.

Opening Meters hides the Combat Log/DM Helper side panel.

Opening Combat Log or DM Helper hides Meters.

No DPS/HPS values are shown.
```

---

# 16. Explicit Non-Goals

This implementation does not add:

```text
DPS/HPS calculations
per-spell breakdowns
per-target damage/healing breakdowns
overhealing statistics
damage-taken/healing-taken views
pet-to-owner roll-up
persistent historical event segments
meter exports
meter reset controls during an active event
new combat-log chat output
new meter-specific addon-message opcodes
```

These can be layered on later because the runtime keeps exact event-unit totals and the combat-log transport now carries stable source identity plus exact aggregate amounts.

---

# 17. Principal Design Decisions

**Use the existing `COMBAT_LOG` stream as the live damage/healing meter transport.**

**Add hidden exact-total/source-ID metadata rather than parsing compact ticker presentation text.**

**Aggregate damage/healing by Event Unit ID, not display name.**

**Use the existing synchronized NPC `threatTable` directly for Threat.**

**Threat is per selected NPC, not one meaningless global sum across enemies.**

**Use the existing event rejoin snapshot for meter catch-up instead of adding another synchronization protocol.**

**Keep meters event-scoped and out of Profile/SavedVariables.**

This keeps the implementation small and aligned with RPE's current event, combat-log, threat and rejoin architecture.