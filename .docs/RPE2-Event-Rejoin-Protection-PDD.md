# RPE2 Event Rejoin Protection — Product Design Document

**Status:** Proposed  
**Repository:** `FrontierDev/rpe2`  
**Target branch:** `dev`  
**Scope:** Client late-join, reconnect, and `/reload` recovery during an event  

---

## 1. Summary

RPE2 already supports rediscovering an active RPE server and reconciling a client with an event in progress. The existing flow is sufficient to recover the basic event definition, event-unit roster, current resources embedded in event units, and current turn/tick state.

It is not sufficient to guarantee that a player who joins late, temporarily disconnects from the RPE session, or runs `/reload` returns to the event with exactly the same gameplay state as players who remained connected.

The main issue is that the current rejoin flow reuses the event-start path and transmits only the existing `EVENT_START`, `EVENT_UNITS`, and `EVENT_STATE` snapshot. Important gameplay runtime state exists outside that snapshot, including active runtime auras, active spellcasts, cooldown/GCD state, and turn-scoped defensive-reaction usage. In addition, ordinary event mutations do not carry a monotonic event revision, so an older queued mutation can theoretically be applied after a newer recovery snapshot.

This feature introduces a dedicated **event rejoin synchronization path**. The active host remains authoritative while it is running. A rejoining client requests or receives a complete snapshot of the current committed gameplay state, atomically installs it, rejects stale mutations, and resumes play without replaying event-start semantics.

This is a client recovery feature only. It does not attempt to recover an event after the host reloads or loses its in-memory server state.

---

## 2. Current Behaviour

### 2.1 Session rediscovery already exists

On `PLAYER_ENTERING_WORLD`, the client queues server discovery. An active host can respond with `SERVER_START`, after which the client rejoins the RPE channel and sends `CLIENT_CONNECT`.

Relevant code:

- `core/internal/Runtime.lua`
- `client/client_Session.lua`
- `server/server_Session.lua`

This is the correct foundation for `/reload` and reconnect recovery.

### 2.2 The server already reconciles clients against an active event

`Server:HandleClientConnect()` calls `Server:ReconcileClientEventSession(clientName)`.

If an event is already active, reconciliation currently:

- verifies client hashes;
- adds a new player event unit when required;
- updates the live roster when the player is genuinely joining mid-event;
- sends an event snapshot to the connecting client;
- broadcasts roster changes to other clients when required.

Relevant code:

- `server/server_Session.lua`
- `server/server_Event.lua`

### 2.3 Current event snapshot is incomplete

The current event snapshot contains three logical messages:

1. `EVENT_START`
2. `EVENT_UNITS`
3. `EVENT_STATE`

`EVENT_UNITS` is substantial and already contains current event-unit data such as resources, initiative, active/hidden status, spell/stat state, summoned-unit relationships, boss state, and threat tables.

However, several gameplay systems maintain event runtime state outside the `Event` / `EventUnit` serialized representation.

### 2.4 Rejoin is currently treated like event startup

After a real UI reload, local Lua runtime state has been destroyed. When the server sends `EVENT_START`, `Client:HandleEventStart()` cannot distinguish a restored existing event from a newly started event.

The startup path can therefore perform work that should only occur once at the beginning of an event, including resetting transient combat state and executing event-start presentation and gameplay hooks.

A rejoin must instead mean:

> Replace local runtime state with the host's current committed event state.

It must not mean:

> Start the event again on this client.

---

## 3. Problem Statement

A player must be able to join an event already in progress, recover after transient session loss, or run `/reload` without gaining or losing gameplay state relative to players who remained connected.

After synchronization completes, the recovered client must agree with the host on all gameplay-relevant committed state required to determine:

- whose turn it is;
- current resources and health;
- unit activation/death/visibility and threat state;
- active runtime auras and their remaining state;
- active persistent spellcasts and their progress;
- spell cooldowns, cooldown groups, charges, and GCD state where applicable;
- turn-scoped defensive-reaction usage;
- the legality and result of subsequent actions.

The client must also be protected against stale messages that were queued before the synchronization snapshot was captured.

---

## 4. Goals

The rejoin protection system must:

1. **Support genuine mid-event joins.** A player who connects after the event has started receives the current event state rather than an approximation of event startup state.
2. **Support client `/reload`.** A player may reload the WoW UI and return to the same event without resetting gameplay restrictions or losing active effects.
3. **Support reconnect/session repair.** If the client drops out of the RPE session while the host remains active, reconnecting must restore current committed state.
4. **Use the active host as the authority.** The recovered client must not attempt to infer missing authoritative state from its own profile or from replaying historical messages.
5. **Hydrate atomically.** The client must not become interactive while only part of the snapshot has been applied.
6. **Prevent stale mutation application.** Messages older than the installed snapshot must not modify recovered state.
7. **Avoid replaying event-start semantics.** Rejoin synchronization must not replay one-time event-start gameplay or presentation behaviour.
8. **Preserve existing late-roster behaviour.** A genuinely new player may still be added to the active event and propagated to other clients.
9. **Keep presentation/derived caches reconstructible.** UI and derived caches should rebuild from recovered authoritative state rather than becoming synchronized state themselves.
10. **Fail safely.** Missing, incomplete, out-of-order, or invalid synchronization must keep the client non-interactive until repaired rather than allowing uncertain gameplay state.

---

## 5. Non-Goals

The following are explicitly outside this PDD:

### 5.1 Host reload recovery

If the event host reloads the UI or otherwise loses `Server.State` / `Server.EventState`, this feature does not restore the event.

No SavedVariable checkpoint of the active event is introduced by this design.

### 5.2 Host migration

There is no transfer of event authority to another client if the host disconnects.

### 5.3 Combat-log history retention

The combat log is presentation/history rather than required authoritative combat state for this feature. A client that rejoins may begin with an empty local combat-log history.

### 5.4 Retaining uncommitted local actions through reload

Pending local resource changes, aura operations, unresolved targeting state, pending reaction prompts, or other client-side work that has not been committed to the event are not restored.

The rejoining client returns to the host's last committed event state.

### 5.5 General network transport replacement

The existing addon-message transport, chunking, message queue, channel discovery, and hash-verification systems remain in place. This feature adds synchronization semantics above them.

---

## 6. Design Principles

### 6.1 Rejoin is state synchronization, not message replay

Recovery must transmit the current state required to continue the event. It must not replay every historical damage, aura, cast, or turn message that led to the current state.

### 6.2 Gameplay state is authoritative; presentation state is derived

A value belongs in the synchronized runtime if losing it can alter which actions are legal or what future combat resolution does.

Examples of synchronized state:

- resources;
- runtime auras;
- casts;
- cooldowns;
- turn-scoped defensive usage.

Examples of derived/local state:

- event widget frames;
- tooltip caches;
- targeting-widget display cache;
- action-bar presentation cache;
- task-queue jobs;
- timing diagnostics.

### 6.3 Snapshot + revision, not snapshot alone

A snapshot is only safe if the client can distinguish mutations created before it from mutations created after it.

The active event therefore requires a monotonically increasing runtime revision.

### 6.4 The host only needs authority while it remains alive

Because host reload recovery is out of scope, the authoritative rejoin state may remain entirely in memory. The design does not require persistence to SavedVariables.

---

## 7. Authoritative Event Runtime

The server should maintain an in-memory runtime record for every active event it hosts.

Conceptually:

```lua
EventRuntime = {
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

This runtime supplements rather than replaces `Server.EventState`.

`Server.EventState` remains the source for event and event-unit state already represented there:

- event identity and metadata;
- turn/tick state;
- units;
- resources;
- stats/spells serialized on event units;
- activation/visibility/boss state;
- threat tables;
- summon relationships;
- teams and event configuration.

The additional runtime exists only for gameplay state that currently cannot be reconstructed from `EventState`.

### 7.1 Runtime revision

The host maintains one event-wide integer revision.

The revision increments whenever a committed synchronized gameplay mutation changes the authoritative event runtime. Examples include:

- event-unit/resource mutation;
- active aura apply/update/remove;
- persistent cast start/progress/complete/interrupt;
- cooldown/GCD state mutation;
- defensive-reaction consumption;
- turn/tick advance;
- roster or unit structural mutation.

Several related changes committed as one logical transaction should share one resulting revision rather than generating arbitrary revisions for internal helper calls.

The revision is a synchronization ordering primitive, not a replacement for the existing runtime/cache revision system used for local invalidation.

---

## 8. State Included in a Rejoin Snapshot

A rejoin snapshot must represent the host's committed state at one captured revision.

### 8.1 Event state

Include the current equivalent of the existing event start/state data:

- event ID;
- channel/session identity required by validation;
- name/subtext/description;
- host;
- started timestamp;
- difficulty and level;
- turn mode;
- current turn number;
- current tick number;
- total ticks;
- teams/team configuration;
- configured event auras;
- other event configuration already serialized today.

### 8.2 Event units

Include the existing full event-unit network state, including at minimum:

- event ID per unit;
- player/NPC identity;
- registry reference where applicable;
- raid marker and team;
- owner/controller;
- name/description;
- initiative;
- current resources and maxima;
- active/hidden state;
- spells;
- stats;
- pet/summon relationships;
- boss state;
- threat table.

The existing `Event:SerializeUnitsForNetwork()` format should remain the baseline rather than defining a competing unit schema solely for rejoin.

### 8.3 Active runtime auras

The snapshot must include all currently active gameplay auras with enough information to reproduce their present state without replaying their original application.

Required information includes:

- caster event ID;
- target event ID;
- aura reference;
- current stacks;
- remaining duration/turns;
- current power level or equivalent authored runtime scalar;
- any identity fields required to reconstruct the existing aura key.

Hydration must use replacement/full-state semantics. It must not increment stacks as if the aura were newly applied.

The existing aura `fullState` behaviour should be reused where practical.

### 8.4 Active persistent spellcasts

The snapshot must include each currently active persistent cast with enough information to continue from its actual progress point.

Required information includes:

- caster event ID;
- spell reference;
- authority type where required by current lifecycle validation;
- original cast start turn/tick or another canonical progress representation;
- total cast duration;
- target selections/focused target where those are required for completion;
- any committed start-cost state required by completion logic.

Hydration must not invoke ordinary "cast started now" behaviour.

### 8.5 Cooldowns, GCDs, charges, and cooldown groups

Any spell-use restriction that would be cleared by losing client runtime must be recoverable.

The synchronized representation must cover whichever concepts are present in the active cooldown implementation, including as applicable:

- spell cooldown remaining state;
- cooldown group state;
- global cooldown state;
- charge state;
- caster/event-unit ownership of that cooldown state.

The exact serialized fields should follow the current `client/spellcasting/Cooldowns.lua` runtime model at implementation time rather than creating a second cooldown model.

### 8.6 Turn-scoped defensive-reaction usage

The current one-defensive-per-turn implementation stores its usage ledger as transient client runtime state. This must be represented in host-authoritative synchronized state.

The network/state model should be generic enough to describe which restricted defensive actions/stat categories have already been consumed by an event unit in the current turn.

This prevents `/reload` from restoring a defensive action that has already been used.

### 8.7 Excluded state

The snapshot must not include:

- combat-log history;
- local UI state;
- open tooltips;
- current targeting widgets;
- pending local turn changes;
- pending addon-message queue contents;
- local cache revisions whose only purpose is invalidation;
- profiling/timing diagnostics.

---

## 9. Rejoin Protocol

The rejoin flow must be distinct from normal event startup.

### 9.1 Discovery and connect

Existing session rediscovery remains responsible for finding the active host and joining the private RPE channel.

A client may enter rejoin synchronization when any of the following occurs:

- the client connects while the host already has an active event;
- the client returns after `/reload`;
- the client reconnects to the RPE session after losing it;
- the client detects a revision gap while an event is active.

### 9.2 Synchronizing state

Before applying the snapshot, the client enters an explicit `syncing` event state.

While syncing:

- event gameplay controls are unavailable;
- no local turn action may be committed;
- normal event mutations newer than the snapshot may be buffered;
- stale mutations must not be applied directly;
- existing partial event runtime must not be treated as authoritative.

### 9.3 Snapshot capture

The host captures one coherent snapshot at revision `R`.

The snapshot must not be assembled from event state at several different logical revisions. If the underlying send is chunked or split into several transport messages, all pieces belong to the same synchronization snapshot identity and revision.

### 9.4 Snapshot installation

The client validates the snapshot identity, then installs it as one logical transition:

1. cancel/clear pending local uncommitted event work;
2. clear previous synchronized gameplay runtime for that event;
3. hydrate event metadata;
4. hydrate units/resources;
5. hydrate runtime auras;
6. hydrate persistent casts;
7. hydrate cooldown/GCD state;
8. hydrate turn-scoped defensive state;
9. set the applied event revision to `R`;
10. rebuild derived gameplay caches;
11. rebuild/refresh event UI;
12. apply buffered mutations newer than `R` in revision order;
13. leave `syncing` state only when the client is caught up.

The ordering inside hydration may be implemented differently if dependency analysis requires it, but the snapshot must not become playable in a partially hydrated state.

### 9.5 Acknowledgement

Once the client has installed the snapshot and applied any contiguous buffered revisions, it should acknowledge the event ID and latest applied revision.

The host may use this for diagnostics and for determining whether a client is currently synchronized.

An acknowledgement is not required to stall the whole event for every other player unless existing event rules already require all clients to be ready.

---

## 10. Revision Rules for Live Mutations

Every synchronized live mutation must carry:

- event ID;
- event runtime revision.

The client tracks `appliedRevision` for the current event.

### 10.1 Incoming revision is older or equal

If:

```text
incomingRevision <= appliedRevision
```

then the mutation is stale or duplicate and is ignored.

### 10.2 Incoming revision is exactly next

If:

```text
incomingRevision == appliedRevision + 1
```

then the mutation may be applied and becomes the new `appliedRevision`.

### 10.3 Revision gap

If:

```text
incomingRevision > appliedRevision + 1
```

then the client cannot prove it has all previous authoritative changes.

The client must:

- stop accepting event gameplay input;
- enter or remain in `syncing`/repair state;
- request a fresh event snapshot;
- resume only after a valid snapshot is installed.

This is preferable to attempting to guess whether the missing revision mattered.

### 10.4 Snapshot versus queued old mutations

A snapshot at revision `R` supersedes all event mutations with revision `<= R`.

This prevents an older queued resource delta, event-state update, aura operation, or other message from corrupting freshly restored state.

---

## 11. Event Start Versus Event Rejoin

The product must treat these as separate lifecycle concepts.

### 11.1 Genuine event start

A genuine event start may continue to perform one-time behaviour such as:

- event-start sound;
- event-start achievement trigger;
- startup consumable prompts;
- creation/reset of event runtime;
- other one-time start presentation.

### 11.2 Rejoin synchronization

A rejoin must not execute one-time event-start semantics.

Specifically, rejoin must not:

- process `rpe_event_started` again;
- treat existing casts as newly started casts;
- apply existing auras as new additive applications;
- reset valid cooldown state;
- reset defensive-reaction usage;
- trigger duplicate event-start sounds/prompts merely because state was restored.

The client may still rebuild visual widgets after hydration.

### 11.3 Existing `EVENT_START`

Implementation may either introduce a dedicated synchronization opcode/payload or extend the protocol with an explicit lifecycle mode, but the semantic distinction must be explicit and testable.

A rejoining client must never need to infer "this is a rejoin" merely from whether some local `Client.EventState` happens to exist, because `/reload` removes that runtime state.

---

## 12. New Player Join Versus Returning Player Rejoin

The server already supports adding a player event unit when a client joins an event and no matching player unit exists.

This behaviour remains, but synchronization must distinguish the two cases.

### 12.1 Returning player

If the active event already has the player's event unit:

- preserve the existing event-unit identity;
- preserve current resources and other host-authoritative state;
- do not rebuild the player as a new event unit;
- send the current rejoin snapshot.

### 12.2 New mid-event player

If the player is genuinely absent from the active event roster:

- create the new event unit using existing roster rules;
- normalize the active turn schedule as required;
- commit that structural change as an authoritative revision;
- propagate the new roster state/delta to existing clients;
- capture/send the joining player's snapshot after the new player state is authoritative.

The joining player's synchronization snapshot must therefore represent the event *after* their roster insertion.

---

## 13. Resource Synchronization During Join

A genuinely new player's own current profile resources may not yet be available to the host at the instant `CLIENT_CONNECT` is processed.

The rejoin system should avoid exposing a partially initialized player unit as synchronized.

Before marking the joining client fully synchronized, the host must have the authoritative resource values required for that player's event unit.

This can be achieved either by:

- including the client's current resource snapshot in the rejoin/connect handshake; or
- making resource synchronization an explicit prerequisite before the final event snapshot is captured.

The product requirement is the ordering guarantee, not a specific packet layout.

A returning player's existing host-authoritative event resources must not be overwritten by fresh profile defaults merely because the client reloaded.

---

## 14. Pending and In-Flight Local Work

A client may reload or lose the session while it has local work that has not yet become committed event state.

Examples include:

- pending resource deltas waiting for End Turn;
- pending aura operations;
- unresolved target selection;
- local reaction prompts;
- queued local presentation tasks.

On rejoin:

- such pending client work is discarded;
- the host's committed snapshot wins;
- the player resumes from the committed event state.

This gives the system a clear transaction boundary and avoids attempting to reconstruct half-completed local interactions.

Any action already accepted and committed by the host before the snapshot revision must be represented in the snapshot even if the originating client never received its echo before reloading.

---

## 15. UI and User Experience

### 15.1 During synchronization

The event UI should clearly indicate that the event is synchronizing/rejoining rather than showing normal interactive controls against partial state.

The exact visual treatment may reuse the existing event transition/loading treatment.

Required behaviour:

- portraits and controls must not imply stale state is playable;
- action-bar event actions must not execute until synchronization is complete;
- no new combat action may be sent from the recovering client;
- synchronization should complete automatically without manual intervention under normal conditions.

### 15.2 After synchronization

The client should return directly to the current event state:

- current turn/tick is displayed;
- current portraits/resources are correct;
- current auras/casts/cooldowns are represented;
- action legality matches the host state;
- no duplicate event-start effects are shown.

Combat-log history may be empty after a rejoin; this is intentional and in scope as acceptable behaviour.

---

## 16. Failure Handling

### 16.1 Snapshot assembly failure

If the host cannot build or queue a valid snapshot, the client must remain unsynchronized. Existing transport retry/fallback behaviour may be reused.

### 16.2 Incomplete/chunked snapshot

The client must not expose partial snapshot state as playable. Missing chunks eventually result in retry/resync rather than partial activation.

### 16.3 Invalid event identity

A snapshot or mutation for a different event ID is ignored.

### 16.4 Revision gap

Any detected revision gap triggers a new rejoin synchronization attempt.

### 16.5 Host no longer active

If server discovery cannot find the original active host, this feature cannot recover the event. Host recovery/migration is explicitly out of scope.

### 16.6 Dataset/ruleset mismatch

Existing dataset/ruleset hash protection remains authoritative. A mismatched client must not be marked synchronized simply because it received a snapshot.

---

## 17. Diagnostics

The system should expose sufficient INTERNAL diagnostics to verify recovery behaviour in-game.

At minimum log or record:

- rejoin requested;
- reason: late join, `/reload` discovery, reconnect, or revision gap;
- event ID;
- snapshot revision;
- snapshot section counts where useful (units, auras, casts, cooldown records, defensive-use records);
- snapshot accepted/rejected;
- current applied revision;
- buffered live-mutation count;
- stale mutation discarded;
- revision gap detected;
- synchronization completed;
- synchronization failed/retried.

These diagnostics should not add combat-log entries.

---

## 18. Compatibility and Protocol Evolution

The implementation must continue to respect current dataset/ruleset hash validation.

Because synchronization changes event protocol semantics, mixed client versions must fail safely rather than allowing an old client to join with incomplete runtime state.

A protocol/capability marker should therefore allow the host to determine whether a client supports the rejoin snapshot/revision model.

The product requirement is:

> A client that cannot understand the authoritative rejoin state must not be treated as fully synchronized in an event that depends on it.

The exact version field may reuse an existing communications/version mechanism if one exists at implementation time.

---

## 19. Architectural Boundaries

The feature should primarily touch the existing event/session/spellcasting/combat synchronization boundaries rather than introducing a parallel event framework.

Current code areas expected to define the design boundary include:

- `client/client_Session.lua`
- `client/client_Event.lua`
- `client/client_Resources.lua`
- `server/server_Session.lua`
- `server/server_Event.lua`
- `core/classes/Event.lua`
- `core/internal/comms/Operations.lua`
- `core/internal/comms/Serialization.lua`
- `client/spellcasting/Core.lua`
- `client/spellcasting/Cooldowns.lua`
- `client/spellcasting/Lifecycle.lua`
- `client/spellcasting/AuraManager.lua`
- `client/combat/Reaction.lua`

The eventual implementation must read the current versions and trace exact call sites before modifying them; this PDD describes product behaviour and architectural ownership, not a frozen patch plan.

---

## 20. Required Invariants

The feature is correct only if all of the following remain true:

1. **Single active host authority:** while the host server remains alive, its committed event state is the source of truth for rejoin.
2. **No rejoin-as-start:** recovering an existing event cannot execute event-start-only gameplay semantics.
3. **No stale mutation after snapshot:** a mutation at revision `<= snapshotRevision` cannot alter a client after snapshot hydration.
4. **No silent gaps:** a client cannot continue gameplay after detecting a missing authoritative revision.
5. **Atomic playability:** the client is not interactable with only part of a rejoin snapshot installed.
6. **No cooldown reset exploit:** `/reload` cannot clear a committed cooldown/GCD/charge restriction.
7. **No aura reset exploit:** `/reload` cannot remove or duplicate an active committed aura.
8. **No cast reset exploit:** `/reload` cannot cancel, restart, or incorrectly advance an existing committed persistent cast.
9. **No defensive reset exploit:** `/reload` cannot restore a defensive reaction already consumed for the current turn.
10. **Committed resources survive:** `/reload` cannot reset event health/resources to profile defaults.
11. **Uncommitted local work does not become committed by recovery:** pending local changes are discarded unless already present in host-authoritative state.
12. **Late join is current-state join:** a genuinely new participant receives the current event after their roster insertion, not a historical event-start approximation.

---

## 21. Acceptance Criteria

The feature is complete when the following scenarios pass with no gameplay desynchronization.

### A. Client reload with ordinary combat state

1. Start an event.
2. Advance several turns/ticks.
3. Damage/heal multiple units and modify threat.
4. Client runs `/reload`.
5. Client rediscovers the same host and rejoins.

Expected:

- same event unit IDs;
- same current resources;
- same threat tables;
- same turn/tick;
- client becomes interactive only after synchronization;
- no event-start-only behaviour is repeated.

### B. Reload with active aura

1. Apply an aura with multiple remaining turns and/or stacks.
2. Client reloads.

Expected:

- aura still exists once;
- stacks are unchanged;
- remaining duration is unchanged relative to the host;
- derived control/stat effects match clients that never reloaded.

### C. Reload with persistent cast

1. Begin a multi-turn spellcast.
2. Advance part-way through the cast.
3. Client reloads.

Expected:

- cast remains active;
- progress is unchanged;
- it does not restart at full duration;
- it does not disappear;
- eventual completion occurs on the same authoritative turn as other clients.

### D. Reload with active cooldown

1. Use an ability with a cooldown/GCD/charge restriction.
2. Client reloads before the restriction expires.

Expected:

- restriction remains active after synchronization;
- action bar/legal activation state matches a non-reloaded client.

### E. Reload after defensive reaction use

1. Enable the one-defensive-reaction-per-turn rule.
2. Consume the restricted defensive reaction.
3. Reload during the same turn.

Expected:

- the restricted reaction remains unavailable after rejoin.

### F. New player joins mid-event

1. Start an event without Player B.
2. Advance combat and establish active auras/casts/cooldowns.
3. Player B joins the RPE session.

Expected:

- Player B is inserted according to existing roster rules;
- existing clients receive the new roster state;
- Player B receives the event state after insertion;
- Player B receives active runtime aura/cast/cooldown state;
- Player B's event resources are valid before synchronization completes.

### G. Stale queued mutation after snapshot

1. Arrange for an older event/resource mutation to remain queued/delayed.
2. Send/install a newer recovery snapshot.
3. Deliver the older mutation afterward.

Expected:

- older mutation is discarded due to revision;
- state remains equal to host state.

### H. Revision gap

1. Apply revision `R`.
2. Cause revision `R+1` to be absent.
3. Deliver `R+2`.

Expected:

- client does not apply `R+2` as if state were complete;
- client enters repair/sync state;
- fresh snapshot restores current host state.

### I. Pending local changes during reload

1. Create local pending End Turn resource/aura changes.
2. Reload before committing them.

Expected:

- pending changes are gone;
- recovered state equals the host's last committed state;
- no duplicate or phantom mutation is transmitted after recovery.

### J. Host reload

Host reload recovery is not an acceptance criterion. The active event may be lost if the host reloads.

### K. Combat-log history

Combat-log history retention is not an acceptance criterion. A recovered client may have an empty local combat-log history.

---

## 22. Product Decision

RPE2 will protect active events against **client-side rejoin and reload desynchronization** by treating recovery as a host-authoritative, revisioned state synchronization operation.

The system will not attempt to persist or restore host event authority, and it will not synchronize historical combat-log entries.

The key product guarantee is:

> If the host remains active, a client may join late, reconnect, or reload the UI and return to the event at the host's current committed gameplay state without gaining, losing, replaying, or duplicating gameplay effects.
