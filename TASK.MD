## Problem

The current Taunt implementation stores runtime Taunt state directly on the target NPC `EventUnit`:

```lua
targetUnit.tauntState = {
    sourceEventId = ...,
    remainingTurns = ...,
}
```

and then synchronizes that change through the normal EventUnit delta path:

```text
client casts Taunt
-> EVENT_UNIT_TAUNT
-> server validates
-> mutate targetUnit.tauntState
-> copy live event to draft
-> EVENT_UNIT_DELTA_BATCH full-unit upsert
-> every client receives/replaces the NPC EventUnit
```

This is unnecessary for the intended behavior and causes a disproportionate comms spike. A Taunt only needs to influence the **host client's Autopilot targeting**. Other clients do not need synchronized Taunt state in their EventUnit model.

The current EventUnit upsert is especially wasteful because an upsert serializes the complete unit record, including resources, spells, stats, threat table, description, etc., merely to communicate `sourceEventId` and `remainingTurns`.

The existing ticker-tape and combat-log presentation are correct and must remain unchanged.

## Desired architecture

Taunt should be a small client -> host gameplay instruction followed by **host-local runtime state only**:

```text
player casts Taunt
-> existing EVENT_UNIT_TAUNT request
-> host validates source, target and duration
-> host stores Taunt in host-local event/Autopilot runtime state
-> host planner snapshots the Taunt state when planning that NPC
-> TargetSelector applies the Taunt override
-> host-local turn lifecycle decrements/expires the state
```

There should be **no EventUnit mutation, EventUnit serialization, EventUnit delta broadcast, draft-state copy, or client-side EventUnit Taunt hydration** involved.

## Implementation requirements

### 1. Remove Taunt from persistent/synchronized EventUnit data

Remove `tauntState` from the EventUnit data contract and network representation.

Inspect and clean the current paths in at least:

- `core/classes/EventUnit.lua`
  - remove Taunt normalization/cloning from the EventUnit model where it only exists for synchronized state;
  - remove `tauntState` from `ToTable()` / merge/new/from-table paths if present solely for this feature;
  - remove `SerializeTauntStateForNetwork` / `DeserializeTauntStateFromNetwork` if no other feature uses them.

- `core/classes/Event.lua`
  - remove `tauntState` from full EventUnit serialization/deserialization;
  - restore the EventUnit wire format to exclude this runtime-only state;
  - ensure compatibility handling is considered for any sessions created by the immediately preceding implementation if necessary, but do not keep permanent dead fields simply for compatibility unless required.

Do **not** move Taunt into another globally synchronized unit/status table.

### 2. Replace `Server:SetEventUnitTauntState()` EventUnit mutation with host-local runtime state

The host should own Taunt runtime state separately from `EventState.units`.

Use a narrow per-event/per-NPC runtime structure, e.g. conceptually:

```lua
Server.EventTauntRuntimeByEventId[eventId] = {
    [npcEventId] = {
        sourceEventId = playerEventId,
        remainingTurns = 2,
        -- any lifecycle bookkeeping needed by the existing duration semantics
    },
}
```

The exact location may instead be an existing Autopilot runtime/state object if that is cleaner, but it must remain host-local and transient.

The state must:

- be scoped to the active event;
- be keyed by target NPC EventUnit ID;
- store the Taunt source EventUnit ID and remaining duration;
- replace an existing Taunt when a different valid caster Taunts the same NPC;
- refresh/update the duration when the same caster reapplies Taunt;
- be cleared when the event ends/resets;
- not be written into `Server.EventState.units` or `Server.EventDraftState.units`.

### 3. Keep the existing `EVENT_UNIT_TAUNT` request, but stop rebroadcasting EventUnit data

The current small client -> host request is appropriate.

`client/client_EventUnitTaunt.lua` should continue sending only the information required to validate/apply Taunt, e.g.:

```text
channelName
eventId
sourceEventId
targetEventId
duration
```

`server/server_EventUnitTaunt.lua` should continue validating:

- active session/event;
- correct event/channel;
- valid source and target EventUnits;
- sender controls the source unit;
- target is an active NPC;
- duration is valid.

After validation it should update the host-local Taunt runtime state directly or call a host-local Taunt runtime helper.

It must **not** call a path that:

- mutates `targetUnit.tauntState`;
- calls `copyLiveEventToDraft()`;
- calls `BroadcastEventDeltaBatch()`;
- sends `EVENT_STATE`, `EVENT_UNITS`, or any other roster/state synchronization message.

A successful Taunt should generate no network traffic beyond the original client -> host Taunt request and any already-existing presentation/log messages that are independently required.

### 4. Feed host-local Taunt state into the Autopilot planner snapshot

The current `TargetSelector` expects Taunt state on the acting NPC snapshot. Refactor this boundary so that the planner receives the same semantic information without reading synchronized EventUnit state.

Preferred pattern:

```text
live EventUnit snapshot
+ host-local Taunt runtime for this NPC
-> frozen planner unit/runtime snapshot
-> TargetSelector
```

The planner may attach a temporary snapshot-only field such as:

```lua
snapshotUnit.tauntState = {
    sourceEventId = ...,
    remainingTurns = ...,
}
```

if this minimizes changes to `TargetSelector`, provided that field exists **only on the planner's frozen/local snapshot**, not on authoritative/synchronized EventUnit state.

Alternatively, pass Taunt metadata separately through planner state if cleaner.

Preserve the existing targeting rule:

```text
valid active Taunt source
-> overrides hostile primary threat selection
otherwise
-> normal threat/distance/eventID ordering
```

Do not change target legality rules; continue relying on the canonical candidate set.

### 5. Move Taunt lifetime advancement to the host-local runtime

The existing duration semantics from the Taunt implementation should remain the same, but duration progression must operate on the new host-local runtime table rather than NPC EventUnits.

Preserve the established invariant:

> A 1-turn Taunt active before the NPC's next planning opportunity affects that plan once, then expires before a later planning opportunity.

The lifetime logic must remain bound to the canonical event turn/page lifecycle and must **not** decrement because of:

- UI refreshes;
- planner retries;
- planner yields;
- replans within the same logical step;
- duplicate comms;
- log/ticker rendering.

When Taunt duration changes or expires, update only the host-local runtime state.

Do **not** send an EventUnit delta on decrement or expiry.

### 6. Preserve ticker tape and combat log behavior exactly

The existing Taunt ticker-tape and combat-log output are explicitly correct and should not be redesigned as part of this cleanup.

Ensure the refactor preserves:

- the same successful-cast ticker entry;
- the same combat-log entry and spell icon/format;
- exactly-once presentation behavior;
- no success presentation for rejected/invalid Taunts.

If presentation currently derives its data from `targetUnit.tauntState`, refactor it to use the resolved Taunt result/context instead. Do not retain EventUnit mutation solely to support presentation.

## Remove the current comms amplification

After this change, a single Taunt must **not** result in any of the following solely because Taunt state changed:

```text
EVENT_UNIT_DELTA_BATCH
EVENT_UNITS
EVENT_STATE
full EventUnit serialization
live -> draft EventUnit cloning
```

The expected gameplay-state comms for a normal player-cast Taunt should be approximately:

```text
1x client -> host EVENT_UNIT_TAUNT
```

plus any existing combat-log/ticker presentation messages that are already part of those systems.

## Validation

Trace the exact current call paths before modifying them; do not assume the implementation still matches the original Taunt issues.

Validate at minimum:

1. Player A Taunts NPC 12 for 2 turns.
   - host-local runtime contains `{sourceEventId=A, remainingTurns=2}` for NPC 12;
   - `Server.EventState.units[NPC12]` contains no Taunt runtime field;
   - no `EVENT_UNIT_DELTA_BATCH` is sent.

2. Autopilot plans NPC 12's hostile action.
   - planner sees the host-local Taunt snapshot;
   - Player A is selected as primary if still a legal candidate regardless of threat.

3. Taunt source becomes illegal/dead/inactive/hidden/wrong disposition.
   - selector falls back to normal threat-first selection;
   - runtime state may remain until normal expiry unless existing semantics explicitly clear it.

4. Same caster reapplies Taunt.
   - duration refreshes;
   - no EventUnit mutation or broadcast occurs.

5. Different caster Taunts the same NPC.
   - source is replaced;
   - no EventUnit mutation or broadcast occurs.

6. Duration advances/expires at the canonical lifecycle boundary.
   - state decrements exactly once per applicable logical turn;
   - expiry produces no EventUnit comms.

7. Event ends/restarts.
   - host-local Taunt runtime is cleared and cannot bleed into another event.

8. Ticker tape and combat log remain identical to current behavior.

9. With comms diagnostics enabled, compare one Taunt before/after the change.
   - after cleanup there must be no full-unit Taunt synchronization burst.

## Scope constraints

Do not:

- redesign the combat log or ticker tape;
- alter general EventUnit delta behavior used by legitimate synchronized unit state;
- introduce a generic synchronized status system;
- encode Taunt as fake/infinite threat;
- change threat ordering itself;
- change unrelated Autopilot targeting behavior;
- persist Taunt to the character/database layer.

This issue is specifically an architectural cleanup of Taunt runtime ownership and synchronization.