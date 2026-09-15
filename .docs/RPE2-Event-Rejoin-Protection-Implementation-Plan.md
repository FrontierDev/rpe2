# RPE2 Event Rejoin Protection — Implementation Plan

**Status:** Proposed implementation plan  
**Repository:** `FrontierDev/rpe2`  
**Target branch:** `dev`  
**Companion PDD:** `.docs/RPE2-Event-Rejoin-Protection-PDD.md`  
**Scope:** Client late-join, reconnect, and `/reload` recovery while the existing host remains active

---

## 1. Implementation Objective

Implement the PDD's host-authoritative rejoin protection without replacing the existing session, event, spellcasting, or communications frameworks.

The implementation must make the following guarantee:

> If the host remains active, a client can join late, reconnect, or run `/reload` and return to the host's current committed gameplay state without replaying event startup or clearing/duplicating gameplay restrictions and effects.

The implementation must explicitly **not** add:

- host `/reload` recovery;
- host migration;
- SavedVariable persistence for active event runtime;
- combat-log history recovery;
- restoration of uncommitted local actions.

The work should be implemented incrementally. Do not attempt to add snapshot hydration before live event mutations have a host-owned ordering model, otherwise a new snapshot can still be corrupted by older queued messages.

---

## 2. Current Code Paths Being Changed

The current `dev` branch already has most of the session and event-start plumbing needed for discovery and reconnection.

### 2.1 Session reconnect path

Current path:

```text
PLAYER_ENTERING_WORLD / GROUP_ROSTER_UPDATE
  -> Client:QueueServerQuery()
  -> Client:SendServerQuery()
  -> SERVER_START
  -> channel join
  -> Client:SendClientConnect()
  -> Server:HandleClientConnect()
  -> Server:ReconcileClientEventSession()
```

Relevant files:

- `core/internal/Runtime.lua`
- `client/client_Session.lua`
- `server/server_Session.lua`

`Client:SendClientConnect()` currently sends channel name, player name, dataset hash, and ruleset hash. `Server:HandleClientConnect()` stores the hashes and immediately calls `ReconcileClientEventSession()`.

### 2.2 Current event reconciliation path

`Server:ReconcileClientEventSession()` in `server/server_Event.lua` currently:

1. verifies the client/session;
2. inserts a new player event unit if no matching player unit exists;
3. copies the live event to the draft;
4. sends the current three-message snapshot to the connecting client;
5. broadcasts an event-unit delta if the roster changed.

The current rejoin snapshot is built by `buildEventSnapshot()` as:

```text
EVENT_START
EVENT_UNITS
EVENT_STATE
```

That sequence is valid for genuine event startup but is not sufficient for recovery because it omits gameplay runtime and routes a reloaded client through `Client:HandleEventStart()`.

### 2.3 Current client startup path

`client/client_Event.lua` owns the event-start transition and `Client:CanPerformEventAction()` gating.

The startup transition intentionally performs one-time work such as:

- startup trait/runtime setup;
- automatic/event aura setup;
- initial resource synchronization;
- consumable prompting;
- event-start presentation;
- startup readiness gating.

Rejoin hydration must not invoke this lifecycle as a substitute for state restoration.

### 2.4 Runtime state currently outside `EventState`

The current branch stores additional gameplay state in runtime tables:

- casts: `Client.ActiveSpellcastsByEventId` and `Server.ActiveSpellcastsByEventId`;
- auras: `Client.ActiveAurasByEventId`;
- cooldowns: `Client.CooldownsByEventId`;
- defensive usage: `Combat.DefensiveReactionUseLedger`.

`Client:ResetSpellcastingState()` currently clears casts, cooldowns, and auras. A true `/reload` clears all of these naturally.

The implementation must make the host retain the authoritative recovery representation for these values while the event is alive.

---

## 3. Protocol Design Decision

Use a dedicated synchronization protocol and a host-stamped live mutation envelope.

### 3.1 New operations

Append new operations after the current highest opcode in `core/internal/comms/Operations.lua`. At the time this plan was written, the current highest opcode is `27`; do not renumber existing operations.

Add:

- `EVENT_SYNC_REQUEST`
- `EVENT_SYNC_SNAPSHOT`
- `EVENT_SYNC_ACK`
- `EVENT_MUTATION_REQUEST`
- `EVENT_MUTATION_COMMIT`

If another change consumes one of the next numeric opcodes before implementation, allocate the next free values instead.

### 3.2 Why a commit envelope is required

The PDD requires one host-owned monotonically increasing revision and permits several related state changes to be one logical committed revision.

Current client-originated mutations are commonly sent directly to the event channel. A client cannot safely assign the next global revision because two clients can act concurrently and only the host can serialize authoritative commits.

Therefore synchronized client-originated changes must become:

```text
client proposal
  -> EVENT_MUTATION_REQUEST to host
  -> host validates/applies proposal
  -> host increments event revision once
  -> host broadcasts EVENT_MUTATION_COMMIT(revision, operations...)
  -> clients apply committed operations in revision order
```

A commit may contain one or more typed domain operations. All operations inside the same commit are applied atomically before `appliedRevision` advances.

This avoids the ambiguity that would occur if several ordinary addon messages shared one revision but the first message advanced `appliedRevision` before the remaining messages arrived.

### 3.3 Existing opcodes remain useful internally

Do not discard the existing domain schemas unnecessarily.

The mutation envelope should carry typed operation records whose payloads reuse the existing serialization formats where practical, for example:

- event state arguments;
- event-unit delta batch payload;
- resource delta batch payload;
- aura apply/dispel payloads;
- spellcast lifecycle payloads.

The client-side committed-operation dispatcher should call the existing domain handlers or extracted pure helpers rather than reimplementing their semantics.

### 3.4 Initial event start remains separate

A genuine new event may continue to use the existing initial `EVENT_START` / `EVENT_UNITS` / `EVENT_STATE` startup sequence.

Once an event is active, rejoin/repair uses `EVENT_SYNC_SNAPSHOT`, not `EVENT_START`.

---

## 4. New Shared Event Sync Module

Add a focused shared module, recommended path:

`core/internal/comms/EventSync.lua`

Load it from `RPEngine2.toc` after the base comms serialization/operations modules and before event runtime code depends on it.

This module must contain protocol/data helpers only. It must not own UI or SavedVariables.

### 4.1 Responsibilities

Implement pure helpers for:

- normalizing revisions;
- serializing/deserializing a synchronization snapshot;
- serializing/deserializing mutation requests;
- serializing/deserializing mutation commits;
- encoding a list of committed domain operations without separator collisions;
- serializing/deserializing aura runtime records;
- serializing/deserializing cast runtime records;
- serializing/deserializing cooldown runtime records;
- serializing/deserializing defensive-use records;
- validating required event ID/revision fields;
- protocol version/capability constant.

### 4.2 Encoding requirement

Do not depend on arbitrary nested separator characters without an escaping or length-prefix scheme.

`core/internal/comms/Serialization.lua` currently serializes top-level arguments using a control-character separator and string conversion. Event-sync sections can themselves contain existing serialized payloads, so the new codec must either:

- use length-prefixed sections/records; or
- provide explicit escaping/unescaping.

Prefer length-prefixed records because existing unit/aura/resource serializers already use their own separators.

### 4.3 Protocol version

Add a small event-sync protocol version/capability value to the client connect handshake.

Recommended:

```text
CLIENT_CONNECT:
channelName, playerName, datasetHash, rulesetHash, eventSyncProtocolVersion
```

Update:

- `client/client_Session.lua`
- `server/server_Session.lua`

The server must not treat an incompatible client as synchronized with an active event.

Do not use addon version text as the synchronization contract unless the current codebase already introduces an appropriate protocol-version field before implementation.

---

## 5. Host Event Runtime

Add a focused server runtime module, recommended path:

`server/server_EventRuntime.lua`

This module owns in-memory authoritative recovery state while an event is active.

### 5.1 Runtime shape

Implement a runtime equivalent to:

```lua
Server.EventRuntime = {
    eventId = "...",
    revision = 0,
    auras = {},
    spellcasts = {},
    cooldowns = {},
    turnState = {
        defensiveReactions = {},
    },
}
```

`Server.EventState` remains authoritative for the state it already represents:

- event identity/configuration;
- roster;
- event-unit resources;
- active/hidden/dead state;
- stats/spells carried on event units;
- threat;
- summons/pets;
- turn/tick.

Do not duplicate full `EventState` inside `EventRuntime`.

### 5.2 Lifecycle

Initialize the runtime only when a genuine event successfully starts.

Clear it when the event ends or the server stops.

Do not persist it in `RPEngine2.toc` SavedVariables.

Host `/reload` therefore still destroys the active event, as required by the PDD.

### 5.3 Revision allocator

Expose a single host API for committed event revisions, e.g.:

```lua
Server:GetEventRuntimeRevision(eventId)
Server:CommitEventMutation(eventId, operations, applyFn)
```

Required behaviour:

1. verify active event identity;
2. apply the host-authoritative state change;
3. increment the revision exactly once if the commit succeeded;
4. build one `EVENT_MUTATION_COMMIT` containing all domain operations for that logical commit;
5. broadcast it;
6. return the committed revision.

Never increment the revision for rejected/no-op proposals.

Do not reuse `RuntimeTransaction.lua` cache revisions as the network revision. They serve a different purpose and are intentionally transient cache/transaction helpers.

---

## 6. Convert Live Event Mutations to Host-Stamped Commits

This phase must be completed before snapshot recovery is enabled.

### 6.1 Client-originated mutations

Route gameplay mutations that affect synchronized event state through `EVENT_MUTATION_REQUEST` instead of allowing clients to apply an unstamped channel message as authoritative state.

The request must contain:

- channel name;
- event ID;
- proposal/domain type;
- serialized proposal payload.

The host must validate the sender using the same ownership/controller rules already used by the affected subsystem.

### 6.2 Host-originated mutations

Host-owned changes such as:

- `EVENT_STATE` changes;
- `EVENT_UNIT_DELTA_BATCH` roster/unit changes;
- host event-manager direct actions;
- NPC/autopilot authoritative mutations;

must also be emitted as committed operations with a host revision once the event is active.

The existing helper functions in `server/server_Event.lua`, such as `broadcastEventDeltaBatch()`, should be adapted to build commit operations instead of bypassing the revision layer.

### 6.3 Client mutation gate

Add a single client-side gate, recommended in `client/client_EventSync.lua`:

```lua
Client:HandleCommittedEventMutation(...)
```

Rules:

```text
revision <= appliedRevision
    discard as stale/duplicate

revision == appliedRevision + 1
    apply entire commit atomically

revision > appliedRevision + 1
    buffer commit
    enter repair/sync state
    request fresh snapshot
```

When the client is already synchronizing, commits are buffered by revision rather than applied directly.

All synchronized domain handlers invoked from a commit must run under an `applyingCommittedMutation` context so they cannot accidentally emit a new proposal in response to the host's committed echo.

### 6.4 Scope of revisioned mutations

At minimum route the following state changes through the commit layer:

- event-state turn/tick changes;
- event-unit delta batches;
- resource/resource-delta changes that modify active `EventState`;
- threat changes carried with resource operations;
- aura apply/update/remove;
- spellcast start/complete/interrupt;
- cooldown state changes;
- defensive-reaction consumption.

Combat-log messages are explicitly excluded.

---

## 7. Resource and Event-Unit Integration

Primary files:

- `server/server_Session.lua`
- `server/server_Event.lua`
- `client/client_Resources.lua`
- `core/internal/comms/ResourceSync.lua`

### 7.1 Preserve server `EventState` as the resource authority

The server already applies incoming resource/resource-delta operations to `Server.EventState` and tracks client resources in session state. Keep that ownership.

After validation/application, emit the committed client-facing resource operation through `EVENT_MUTATION_COMMIT` with the new revision.

Clients must no longer treat an unstamped resource proposal as authoritative event state.

### 7.2 Eliminate stale additive-delta replay

The current resource delta application is additive. Revision gating therefore has to happen **before** applying `ResourceSync.ApplyResourceDeltas...` on a client.

A stale `RESOURCE_DELTA` equivalent from revision `<= appliedRevision` must never reach the additive apply function.

### 7.3 New-player resource prerequisite

For a genuinely new mid-event player, `ReconcileClientEventSession()` currently can construct a player unit before the host has received useful session resources.

Change the join flow so roster insertion is not considered synchronized until current player resources are known.

Recommended implementation:

- include the joining client's current resource snapshot in `CLIENT_CONNECT` when an event sync-capable client connects; or
- send it as an explicit pre-snapshot join prerequisite and defer roster insertion/snapshot capture until received.

Prefer including it in the connect handshake to avoid an extra synchronization round trip.

For a returning player whose event unit already exists, do **not** replace event resources with freshly loaded profile defaults.

### 7.4 Roster insertion ordering

For a genuinely new player:

1. validate hashes/protocol/resources;
2. create the new event unit;
3. normalize turn state;
4. commit roster/state change as one revision;
5. broadcast that commit to already-synchronized clients;
6. capture the joining client's snapshot **after** the insertion commit.

The snapshot revision must therefore include the roster insertion.

---

## 8. Aura Runtime Integration

Primary files:

- `client/spellcasting/AuraManager.lua`
- `client/spellcasting/Handles.lua`
- `client/client_PendingChanges.lua`
- `core/internal/comms/Operations.lua`
- new `server/server_EventRuntime.lua`

### 8.1 Host mirror

Add host handling for aura proposals so every committed aura operation updates `Server.EventRuntime.auras`.

Store canonical aura entries using the same identity semantics as the client aura bucket:

- caster event ID;
- target event ID;
- aura reference/aura key identity;
- stacks;
- remaining turns;
- power level;
- any additional field required by the current aura network identity.

### 8.2 Full-state semantics

Recovery data must be replacement state, not a new aura application.

Reuse the existing `fullState` semantics already present in `AuraManager`.

Add explicit import/export helpers so hydration can install an aura bucket without running ordinary combat-log, application, or proc semantics.

Recommended APIs:

```lua
AuraManager:ExportEventAuraState(client, eventId)
AuraManager:ReplaceEventAuraState(client, eventState, records, options)
```

The replacement path should:

- clear the event aura bucket;
- install canonical entries;
- rebuild target indexes/runtime caches;
- invalidate derived/control-state caches;
- avoid emitting gameplay operations;
- refresh derived state only after the complete snapshot is installed.

### 8.3 Aura ticking

Ensure the host mirror receives the resulting committed full-state aura update whenever duration/stacks change during normal aura progression.

Do not attempt to reconstruct current remaining duration by replaying historical aura applications.

---

## 9. Persistent Spellcast Integration

Primary files:

- `server/server_Spellcasting.lua`
- `client/spellcasting/Core.lua`
- `client/spellcasting/Lifecycle.lua`
- `client/spellcasting/Helpers.lua` as required by the current cast model

### 9.1 Extend server cast entries

`Server.ActiveSpellcastsByEventId` already exists, but current entries are too small for complete recovery.

Extend the canonical server entry to include the current client runtime fields required for continuation, including:

- `spellRef`;
- `authorityType`;
- `casterEventId`;
- `turnsTotal`;
- `turnsElapsed`;
- `startedOnTurnNumber`;
- `lastAdvancedTurnNumber`;
- target selections/order;
- target event IDs;
- focused target event ID;
- target policy if required at completion;
- resolved start-cost data required by completion.

### 9.2 Cast-start proposal

Extend the client cast-start proposal so the host receives the canonical committed cast entry rather than only spell ref + cast turns.

Validate that the supplied caster/event/spell/authority still matches the existing server validation path.

### 9.3 Host progress

Advance host cast progress whenever the authoritative event turn advances, using the same turn/schedule rules as the client.

Prefer extracting the pure `turnsElapsed` advancement calculation so server and client use the same helper rather than maintaining two near-identical algorithms.

A turn advance and the resulting cast-progress change belong to the same event commit revision when they occur together.

### 9.4 Client hydration

Add a replacement/import path that writes cast entries directly into `ActiveSpellcastsByEventId` and bumps the local cast cache revision without invoking `HandleSpellcastStart()`.

This is required so a restored cast does not:

- restart at zero progress;
- replay start logging/presentation;
- repay start costs;
- lose committed target selections.

---

## 10. Cooldown / GCD / Charge Integration

Primary files:

- `client/spellcasting/Cooldowns.lua`
- `client/spellcasting/Core.lua`
- new `server/server_EventRuntime.lua`
- optional new shared pure helper file if extraction is cleaner

### 10.1 Canonical data shape

Use the current cooldown bucket shape rather than inventing a separate recovery model.

The current unit state already represents the needed concepts:

- `globalCooldownRemaining`;
- `lastAdvancedTurnNumber`;
- per-spell `remainingTurns`;
- `lockoutRemainingTurns`;
- `currentCharges`;
- `maxCharges`;
- `usesCharges`;
- `cooldownTurns`.

Add pure clone/serialize/deserialize helpers for this state.

### 10.2 Seed host cooldown state on committed spell use

When a cast/use is accepted, include the caster's resulting cooldown unit state in the mutation request or derive it using shared cooldown logic.

Preferred implementation is to extract the data-only cooldown mutation helpers used by `ApplyLocalSpellCooldown()` so both client and server can apply the same deterministic cooldown transition from spell metadata.

Avoid trusting a completely arbitrary client-provided cooldown bucket if the host can derive the same result.

### 10.3 Host cooldown advancement

Extract the data-only part of cooldown advancement from `Client:AdvanceCooldownState()` into a shared helper that accepts:

- event state/turn context;
- caster event ID;
- one cooldown unit state.

The host applies it to `Server.EventRuntime.cooldowns` during authoritative turn advancement.

The client may call the same helper for local live advancement, preserving current presentation refresh behaviour outside the shared pure function.

### 10.4 Snapshot hydration

Add a replacement API that installs the entire event cooldown bucket before the action bar is enabled.

After replacement:

- invalidate cooldown/action-bar signatures/caches;
- refresh action-bar legality once;
- do not treat restored cooldowns as newly triggered cooldowns.

---

## 11. Defensive-Reaction Usage Integration

Primary file:

- `client/combat/Reaction.lua`

Add server runtime storage under:

```lua
Server.EventRuntime.turnState.defensiveReactions
```

### 11.1 Replace local-only commitment

`Combat:ConsumeDefensiveReactionUse()` currently writes directly to transient `Combat.DefensiveReactionUseLedger`.

Refactor the flow so a restricted defensive use produces a host mutation request containing:

- event ID;
- turn number;
- defender event ID;
- resolution system;
- normalized stat ref.

The host verifies:

- active event/turn;
- defender identity;
- sender ownership/control;
- that the use is not already committed;
- current ruleset bypass/limit behaviour as necessary.

On success, store the use and broadcast a committed defensive-use operation.

### 11.2 Client ledger remains the fast lookup

Keep `Combat.DefensiveReactionUseLedger` as the local lookup used by `CanUseDefensiveReaction()`, but hydrate/update it only from committed host state while an event is active.

Add import/export helpers so snapshot hydration can replace the active-turn ledger without simulating reactions.

Clear previous-turn records when the authoritative turn changes.

---

## 12. Build the Rejoin Snapshot

Primary files:

- `server/server_Event.lua`
- new `server/server_EventRuntime.lua`
- shared `core/internal/comms/EventSync.lua`

### 12.1 Snapshot contents

Build one logical `EVENT_SYNC_SNAPSHOT` payload containing:

- protocol version;
- channel name;
- event ID;
- snapshot revision `R`;
- current event start/configuration representation;
- current event state/turn representation;
- serialized full event-unit state;
- active runtime aura state;
- active cast state;
- cooldown/GCD/charge state;
- defensive-use state for the active turn.

Do not include combat-log history.

Do not include task queues, targeting widgets, UI state, local pending changes, cache revisions, or diagnostics buffers.

### 12.2 Snapshot capture consistency

Snapshot construction must read one committed host state at revision `R`.

Lua execution is single-threaded, so the implementation should build the snapshot synchronously from `Server.EventState` + `Server.EventRuntime` before queueing it. Do not yield part-way through snapshot capture.

Transport chunking may happen after the logical payload is built; chunking does not change the snapshot revision.

### 12.3 Replace active-event reconcile send

Change `Server:ReconcileClientEventSession()` so an active event sends `EVENT_SYNC_SNAPSHOT` rather than calling the current `sendEventSnapshotToClient()` path that emits `EVENT_START` / `EVENT_UNITS` / `EVENT_STATE`.

Retain the existing initial-event-start snapshot path for the moment an event genuinely begins.

---

## 13. Client Synchronization State Machine

Add a focused client module, recommended path:

`client/client_EventSync.lua`

### 13.1 Runtime state

Maintain a transient structure equivalent to:

```lua
Client.EventSyncState = {
    status = "idle" | "syncing",
    eventId = nil,
    reason = nil,
    appliedRevision = 0,
    bufferedCommits = {},
    requestedAt = nil,
}
```

This is not a SavedVariable.

### 13.2 Entering sync

Enter synchronization when:

- an active host sends a snapshot after connect;
- the client explicitly requests repair;
- a revision gap is detected.

While syncing:

- `Client:CanPerformEventAction()` returns false with `event-syncing`;
- pending local turn work is cancelled/discarded;
- incoming committed mutations are buffered;
- partial/stale event state is not treated as playable.

### 13.3 Pending-work cleanup

Add a single cleanup entry point in `client/client_PendingChanges.lua`, for example:

```lua
Client:AbortPendingEventWork(eventId, reason)
```

It should clear only uncommitted local event work, including current pending resource/aura batches and targeting/reaction interaction state that would otherwise survive within the same Lua session during a reconnect repair.

Do not send those discarded operations during cleanup.

### 13.4 Snapshot hydration

Implement a dedicated hydration method. Do not call `Client:HandleEventStart()`.

Recommended sequence:

1. validate sender is the current host;
2. validate channel/event/protocol/hash readiness;
3. enter `syncing`;
4. abort pending local work;
5. cancel stale event-scoped queued tasks/transitions;
6. construct/replace `Client.EventState` from snapshot event data;
7. replace event units/resources;
8. replace aura runtime;
9. replace cast runtime;
10. replace cooldown runtime;
11. replace defensive-use runtime;
12. set `appliedRevision = R`;
13. rebuild derived trait/control/stat caches;
14. rebuild event UI/action-bar presentation;
15. discard buffered commits `<= R`;
16. apply contiguous buffered commits `R+1`, `R+2`, ...;
17. if a gap remains, request another snapshot and stay non-interactive;
18. otherwise mark the event ready and send `EVENT_SYNC_ACK`.

### 13.5 No event-start side effects

The hydration path must not execute:

- event-start achievements;
- event-start sound;
- consumable prompt;
- fresh automatic/event aura application;
- fresh cast-start logic;
- cooldown reset;
- combat-log clearing as a synchronization requirement.

The local combat-log UI may naturally be empty after `/reload`; do not repopulate it.

---

## 14. Rejoin Request / Ack Integration

Primary files:

- `client/client_Session.lua`
- `server/server_Session.lua`
- `server/server_Event.lua`
- new client/server EventSync modules

### 14.1 Connect-time rejoin

After a compatible `CLIENT_CONNECT` reaches an active host:

- verify dataset/ruleset hashes;
- verify event-sync protocol capability;
- establish resource prerequisite for a new player;
- reconcile roster if required;
- send the authoritative snapshot.

A returning player's existing event unit must be preserved.

### 14.2 Explicit repair request

`EVENT_SYNC_REQUEST` must be available for revision-gap recovery without forcing the entire session/channel discovery flow to restart.

Request arguments should include at minimum:

- channel name;
- event ID if known;
- client's last applied revision;
- reason code (`late-join`, `reload`, `reconnect`, `revision-gap`).

The host should respond with a fresh full snapshot rather than attempting to send only the missing revision.

### 14.3 Ack

`EVENT_SYNC_ACK` contains:

- channel name;
- event ID;
- latest applied revision.

Store lightweight per-client sync diagnostics in `Server.State.clientsByName[clientName]`, for example:

- last acknowledged event ID;
- last acknowledged revision;
- synchronized boolean.

Do not make the entire event wait for every acknowledgement unless an existing gameplay flow already has such a readiness requirement.

---

## 15. UI / Transition Gating

Primary files:

- `client/client_Event.lua`
- event widget/action-bar refresh code only where necessary

### 15.1 Reuse existing playability gate

Extend `Client:CanPerformEventAction()` to check `Client.EventSyncState.status == "syncing"` before allowing actions.

Do not create a second independent action-permission system.

### 15.2 Loading presentation

Reuse the current event transition/loading treatment where practical.

During sync:

- portraits should not present stale state as playable;
- action-bar event actions remain disabled/unavailable;
- no local action should send a mutation request.

After hydration, perform one consolidated visual refresh rather than refreshing after every restored aura/cooldown/cast entry.

---

## 16. Diagnostics

Add INTERNAL-level event-sync diagnostics rather than combat-log entries.

At minimum record/log:

- sync requested + reason;
- snapshot captured revision;
- snapshot section counts;
- snapshot queued/sent;
- snapshot accepted/rejected;
- applied revision before/after;
- commit buffered;
- stale commit discarded;
- revision gap detected;
- pending-work abort;
- sync completed;
- sync retry/failure;
- ack received.

Use the existing debug/timing infrastructure. Do not add permanent chat spam.

Add timing around:

- snapshot serialization;
- snapshot hydration;
- derived-state rebuild.

This is especially important because the current event startup work has already required slice/timing optimization.

---

## 17. File-Level Change Map

Expected files to add:

- `core/internal/comms/EventSync.lua`
- `server/server_EventRuntime.lua`
- `client/client_EventSync.lua`

Expected files to modify:

- `RPEngine2.toc`
- `core/internal/comms/Operations.lua`
- `client/client_Session.lua`
- `server/server_Session.lua`
- `server/server_Event.lua`
- `client/client_Event.lua`
- `client/client_Resources.lua`
- `core/internal/comms/ResourceSync.lua` only if shared helper/export changes are needed
- `server/server_Spellcasting.lua`
- `client/spellcasting/Core.lua`
- `client/spellcasting/Lifecycle.lua`
- `client/spellcasting/Cooldowns.lua`
- `client/spellcasting/AuraManager.lua`
- `client/spellcasting/Handles.lua` if aura routing remains through wrapper handlers
- `client/combat/Reaction.lua`
- `client/client_PendingChanges.lua`

Potentially affected call sites that must be audited before editing:

- autopilot/server code that wraps or calls `Server:StartEvent()`;
- all callers of `Server:BroadcastEventDeltaBatch()`;
- all client senders of resource deltas;
- all senders of aura apply/dispel operations;
- all senders of spellcast lifecycle operations;
- direct Event Manager actions that change resources/auras/units;
- turn advance code paths in manual and autopilot modes.

Do not mechanically patch only the files listed above. Before each phase, re-read the current `dev` version and trace the exact active call path because several event APIs are wrapped by later-loaded modules.

---

## 18. Implementation Sequence

Implement in the following order.

### Phase 1 — Shared protocol and pure codecs

- add EventSync codec;
- add protocol version;
- add new opcodes;
- add deterministic codec tests;
- no gameplay behaviour change yet.

**Exit criterion:** snapshots/commit envelopes round-trip arbitrary existing serialized payloads without separator corruption.

### Phase 2 — Host runtime + revision allocator

- add `Server.EventRuntime` lifecycle;
- initialize/clear with event lifecycle;
- add revision commit API;
- add diagnostics.

**Exit criterion:** a test commit increments exactly once; rejected/no-op commit does not increment.

### Phase 3 — Host-stamped mutation pipeline

- add request/commit handlers;
- route event-state/unit/resource changes first;
- add client revision gate/buffering;
- preserve genuine startup behaviour.

**Exit criterion:** delayed duplicate/stale resource/unit/state commits cannot alter current client state.

### Phase 4 — Aura authority

- mirror committed aura state on host;
- add export/import replacement APIs;
- route aura live mutations through commit layer.

**Exit criterion:** active aura bucket can be exported, cleared, re-imported, and produce identical gameplay-derived aura state.

### Phase 5 — Cast authority

- expand server cast entries;
- carry target/progress runtime state;
- advance server cast progress with authoritative turn state;
- add direct hydration path.

**Exit criterion:** a partially progressed persistent cast survives export/import without replaying start semantics.

### Phase 6 — Cooldown authority

- extract/shared pure cooldown state operations;
- maintain server cooldown mirror;
- add serialization/replacement hydration.

**Exit criterion:** cooldown, GCD, lockout, and charge state survive export/import and advance identically on server/client.

### Phase 7 — Defensive-use authority

- convert reaction-use consumption to host commit;
- store current-turn use ledger on host;
- add hydration.

**Exit criterion:** a consumed limited reaction remains unavailable after local ledger destruction/replacement.

### Phase 8 — Full rejoin snapshot

- build `EVENT_SYNC_SNAPSHOT`;
- change active-event reconciliation to snapshot sync;
- implement atomic client hydration;
- add request/ack flow;
- discard pending local work.

**Exit criterion:** a client with no local event runtime can hydrate from a single host snapshot and reach the same gameplay state.

### Phase 9 — Join resource ordering + compatibility

- enforce resource prerequisite for new participants;
- block incompatible protocol clients from being marked synchronized;
- finalize diagnostics/error paths.

**Exit criterion:** a genuinely new mid-event player is inserted with valid resources before their snapshot is considered complete.

### Phase 10 — In-game regression validation

Run the PDD acceptance matrix plus the regressions below before considering the feature complete.

---

## 19. Deterministic Validation

Where possible, test synchronization as pure data without WoW UI dependencies.

### 19.1 Codec tests

Test round trips for:

- empty snapshot sections;
- multiple units;
- multiple aura records with stacks/remaining turns;
- cast entries with target selections;
- cooldown entries with charges/lockouts/GCD;
- defensive-use records;
- embedded existing serialized strings containing control separators;
- large payload that requires transport chunking after logical serialization.

### 19.2 Revision tests

Use mocked commits/snapshots:

```text
snapshot R=10
commit 9  -> discard
commit 10 -> discard
commit 11 -> apply
commit 13 -> detect gap / request sync
commit 12 while syncing -> buffer
snapshot R=13 -> discard buffered <=13 and resume
```

Also test:

- duplicate `R+1` delivery;
- two domain operations in one commit advance revision once;
- failed host proposal leaves revision unchanged.

### 19.3 Hydration idempotence

Install the same snapshot twice in a test client runtime.

Expected:

- one aura instance per canonical key;
- same casts/progress;
- same cooldown values;
- same defensive ledger;
- no duplicated derived effects;
- no event-start hooks.

---

## 20. In-Game Acceptance Matrix

Run at minimum the companion PDD scenarios:

### Client `/reload`

Verify after several turns with resource/threat changes:

- same event ID/unit IDs;
- same resources;
- same threat;
- same turn/tick;
- no event-start sound/achievement/consumable prompt replay.

### Active aura

Reload while an aura has remaining turns/stacks.

Verify:

- one aura instance;
- same stacks/duration;
- same stat/control effects.

### Persistent cast

Reload during a multi-turn cast.

Verify:

- same spell/caster/targets;
- same elapsed/remaining progress;
- same completion turn.

### Cooldown/GCD/charges

Reload after ability use.

Verify all restrictions remain and the action bar agrees with a non-reloaded client.

### Defensive reaction

Consume a limited defensive reaction, reload in the same turn, verify it remains unavailable.

### Genuine late join

Join after combat state has changed.

Verify the new player is inserted once, has valid resources, and receives current aura/cast/cooldown state.

### Stale queued commit

Artificially delay an old commit until after a newer snapshot.

Verify it is discarded.

### Revision gap

Drop one revision and deliver a later revision.

Verify gameplay input locks and automatic full resync occurs.

### Pending local work

Create pending End Turn resource/aura work and reload/repair before commit.

Verify it is discarded and not transmitted after synchronization.

---

## 21. Regression Checklist

Because this work changes replication semantics, explicitly check the following existing behaviours:

- normal fresh event startup still completes;
- host's own local client still receives startup correctly;
- manual turn advancement still advances spells/auras/cooldowns once;
- autopilot turn advancement still advances them once;
- NPC simultaneous marker turns do not double-advance runtime state;
- player and NPC persistent casts still complete/interrupt normally;
- instant casts are not accidentally retained as active snapshot casts;
- resource delta combat text still appears once;
- aura application/removal presentation still appears once;
- cooldown action-bar refresh does not run twice per commit;
- Event Manager direct damage/heal/aura actions still synchronize;
- summoned unit insertion/removal still propagates;
- threat changes still propagate;
- dataset/ruleset mismatch remains blocking;
- existing channel/chunk retry behaviour still works;
- fresh event start achievement fires once;
- reconnect/reload does not fire that achievement;
- combat log continues normally after rejoin but old history is not restored.

---

## 22. Performance Constraints

Do not replace one startup lag source with a rejoin lag source.

Requirements:

- snapshot **capture/serialization** is synchronous and coherent, but should avoid expensive derived-state work;
- transport uses existing chunking/queue infrastructure;
- hydration may schedule/slice expensive derived cache/UI rebuild work after the authoritative data has been installed, while remaining in `syncing` state;
- avoid one UI refresh per restored aura/cooldown/cast;
- rebuild derived state once at the end;
- retain INTERNAL timing instrumentation for large events.

The host runtime should store compact gameplay state, not duplicated UI/cache state.

---

## 23. Completion Criteria

This implementation is complete only when all of the following are true:

1. active-event reconciliation no longer uses fresh `EVENT_START` semantics for a rejoining client;
2. the host owns one monotonic active-event revision;
3. clients never apply synchronized live mutations without a host commit revision;
4. one logical commit can contain multiple domain operations and advances revision once;
5. snapshot revision supersedes all older queued commits;
6. revision gaps force automatic repair before further gameplay input;
7. resources/roster/threat restore correctly;
8. active auras restore exactly once with current stacks/duration;
9. persistent casts restore with current progress and target state;
10. cooldown/GCD/charge state restores and advances correctly;
11. limited defensive-reaction usage restores for the current turn;
12. pending uncommitted client work is discarded during repair;
13. new mid-event players have valid resources before synchronization completes;
14. incompatible clients fail safely;
15. no host persistence/SavedVariable recovery has been introduced;
16. no combat-log history synchronization has been introduced;
17. the full PDD acceptance matrix and regression checklist pass.

---

## 24. Final Implementation Review

Before merge, review the resulting diff specifically for accidental architectural expansion.

Reject or remove any change that introduces, without being required by the PDD:

- host event persistence;
- generic distributed-database abstractions;
- combat-log replay/history replication;
- unrelated transport replacement;
- UI state synchronization;
- recovery of uncommitted user interactions;
- broad spellcasting rewrites that are not required to expose/import authoritative runtime state.

The intended architecture remains:

```text
existing session discovery
        |
        v
host-authoritative event runtime + revision
        |
        +---- live mutation requests -> committed revisioned mutations
        |
        +---- rejoin request -> one current-state snapshot
                                |
                                v
                        atomic client hydration
                                |
                                v
                         normal event resumes
```

That is the complete scope of this work.