# RPE 2 — Event Startup Communications Optimisation
## Product Design Document

**Status:** Proposed  
**Target:** RPEngine 2.0 (`FrontierDev/rpe2`), `dev` branch  
**Scope:** Event-start snapshot transmission, event-unit network representation, chunk sizing, outbound message scheduling, addon-message throttle handling, queue priority/coalescing, startup diagnostics, late-join/resync compatibility  
**Primary objective:** Reduce the time between the host starting an event and all clients becoming event-ready by reducing startup message volume and replacing fixed comms pacing with throttle-aware scheduling  
**Out of scope:** Gameplay rule changes, event-authority changes, spell/action semantics, general data-model redesign, unrelated runtime performance work

---

# 1. Purpose

Event startup is currently bottlenecked by communications rather than by event-state construction alone.

The current startup path sends a snapshot to each client using three messages:

```text
EVENT_START
EVENT_UNITS
EVENT_STATE
```

`server/server_Event.lua::sendEventSnapshotToClient()` sends all three as individual `WHISPER` messages to each target client.

The snapshot is then chunked by `core/internal/comms/Core.lua` and each physical addon packet is placed into the single global FIFO queue in `core/internal/comms/MessageQueue.lua`.

Two independent effects compound:

1. **The startup snapshot is heavier than it needs to be.** Dataset-backed NPCs can transmit information that clients already possess from the activated datasets/ruleset, despite event start already being blocked when connected clients have dataset or ruleset hash mismatches.
2. **The transport deliberately delays every packet.** `MessageQueue.lua` imposes a minimum delay of 0.2 seconds between all addon-message attempts, regardless of whether Blizzard would currently permit an immediate burst.

The result is that event startup time scales with:

```text
serialized startup data
    × chunk count
    × number of repeated recipients
    × queue delay / throttle recovery
```

This document defines a combined redesign of the **startup payload** and the **outbound transport scheduler**. Neither part should be implemented in isolation: a smaller snapshot reduces pressure on the transport, while a better scheduler allows the remaining packets to use the available communications allowance efficiently.

---

# 2. Product Goals

## 2.1 Primary goals

The implementation must:

- materially reduce the number of physical addon messages required to start an event;
- avoid retransmitting dataset-derived NPC state that a hash-matched client can reconstruct locally;
- preserve all event-specific and runtime-specific unit state exactly;
- make event-start communications higher priority than unrelated background traffic;
- remove the unconditional 0.2-second gap between every message;
- use available burst capacity when the API permits it;
- back off intelligently when `C_ChatInfo.SendAddonMessage()` reports throttling instead of repeatedly polling the throttle;
- distinguish prefix/addon-message throttling from channel-specific throttling;
- use as much of the 255-byte addon-message payload limit as is safely available after RPE packet headers;
- preserve deterministic ordering of chunked logical messages;
- retain working late-join and resynchronisation paths;
- instrument bytes, packet counts, queue time, throttle responses and end-to-end startup readiness so improvements can be measured.

## 2.2 Non-goals

The implementation must not:

- change event gameplay semantics;
- change unit scaling, difficulty scaling, variants, presets, resources, stats or spells;
- assume that a client may reconstruct data when its dataset/ruleset hashes do not match the host;
- increase the chance of disconnects by blindly sending at an unrestricted rate;
- solve the problem merely by changing `SendDelay` from `0.2` to a smaller constant;
- allow lower-priority traffic to starve indefinitely;
- interleave chunks in a way that breaks the existing sender/opcode-based inbound reassembly model;
- require a new third-party communications dependency for the first implementation.

---

# 3. Current Architecture

# 3.1 Startup snapshot

The current server startup helper performs:

```text
sendEventSnapshotToClient(eventState, clientName)
    -> EVENT_START  via WHISPER
    -> EVENT_UNITS  via WHISPER
    -> EVENT_STATE  via WHISPER
```

This is repeated for each target client.

`buildStartArguments()` already calls:

```lua
eventState:ToStartArguments(false)
```

so the full unit roster is not redundantly embedded inside `EVENT_START`. The main payload cost is therefore concentrated in `EVENT_UNITS`, plus any fields in the initial `EVENT_STATE` that duplicate information already established by `EVENT_START`/`EVENT_UNITS`.

The current architecture also blocks `Server:StartEvent()` when connected clients have dataset or ruleset hash mismatches. That invariant is important: when startup is allowed to proceed, the client already has the same authored definitions as the host and can safely resolve a dataset-backed unit from its registry identifier.

---

# 3.2 Event-unit network representation

`core/classes/Event.lua` serialises event units into compact delimiter-based records, but the unit record can still contain resources, spells, stats and other definition-derived values.

There is already an important precedent in the current codebase. `server/server_Event.lua::buildCompactSummonedUnitDelta()` creates a compact representation for eligible summoned units by transmitting the registry identity and switching network hydration to inherited/bonus modes:

```lua
compactUnit.resources = {}
compactUnit.spells = {}
compactUnit.stats = buildStatBonusRows(...)
compactUnit._networkResourceMode = "inherit"
compactUnit._networkSpellMode = "inherit"
compactUnit._networkStatMode = "bonus"
```

`core/classes/EventUnit.lua` already understands inherited spell data and inherited/merge/bonus stat hydration.

This means RPE already contains the basis of the required optimisation. The design should generalise this idea to ordinary dataset-backed event NPCs instead of inventing an unrelated second network representation.

---

# 3.3 Chunk sizing

`core/internal/comms/Core.lua` defines:

```lua
Comms.MaxAddonMessageLength = 255
Comms.SafeChunkLength = 180
```

`ResolveChunkPlan()` already calculates the actual packet payload limit after accounting for the RPE packet header, but still caps the normal chunk size at 180 bytes.

This leaves a significant fraction of every allowed addon message unused. For large `EVENT_UNITS` payloads, the unused space directly increases physical packet count.

---

# 3.4 Current outbound queue

`core/internal/comms/MessageQueue.lua` currently provides one global FIFO queue.

The important runtime defaults are:

```lua
DefaultSendDelay = 0.2
DefaultMaxSendDelay = 2
DefaultMaxAttempts = 0
DefaultMaxQueueLength = 256
```

`getMinimumSendDelay()` hard-clamps the configured delay to at least 0.2 seconds. Every send attempt therefore advances `NextSendAt` by at least 0.2 seconds.

All traffic competes in the same FIFO. A startup packet can therefore wait behind unrelated queued traffic even when the player is blocked waiting for event readiness.

---

# 3.5 Current throttle recovery

When `C_ChatInfo.SendAddonMessage()` returns either:

```text
3 = AddonMessageThrottle
8 = ChannelThrottle
```

RPE currently routes both through the same `HandleThrottle()` path.

That path retries the head item using exponential delays derived from the normal send delay:

```text
0.2s -> 0.4s -> 0.8s -> 1.6s -> 2.0s cap
```

This has several problems:

- a prefix throttle and a channel throttle do not represent the same blocked resource;
- the same head item blocks the entire FIFO even when other queued traffic could be eligible;
- early 0.2/0.4-second retries can be wasted when the server has not replenished allowance yet;
- the scheduler does not learn from successful or throttled sends;
- the fixed 0.2-second spacing also applies when the API would permit immediate sending.

Current WoW API documentation describes a default per-prefix allowance of 10 messages, replenishing at approximately one message per second, with values dynamically configurable by the server. It also documents that the per-prefix restriction does not apply to whispers outside instanced content. RPE must therefore treat the documented values as **initial scheduling assumptions, not hard protocol guarantees**, and must react to the actual `SendAddonMessage` result code.

Reference: https://warcraft.wiki.gg/wiki/API_C_ChatInfo.SendAddonMessage

---

# 4. Design Principles

The combined design follows six rules.

## 4.1 Do not transmit data the receiver already has

Dataset/ruleset identity is already validated before startup. Dataset-backed NPCs should therefore transmit identity plus runtime delta, not a second copy of their authored definition.

## 4.2 Optimise physical message count, not only serialized bytes

Blizzard throttling is message-oriented. Reducing a payload from 3,000 bytes to 2,500 bytes matters only insofar as it reduces the number of physical addon messages. Chunk sizing must therefore be part of the same optimisation.

## 4.3 Treat event startup as latency-sensitive traffic

A player is actively waiting for startup completion. Event-start messages must not sit behind background synchronization that can safely arrive later.

## 4.4 Use available burst capacity, then pace sustained traffic

The queue should not voluntarily impose a 200 ms delay when the API is currently accepting immediate messages. Conversely, it must not keep hammering the API after a throttle response.

## 4.5 Let observed API results override estimates

Server throttle values can change. Local token/budget estimates are only scheduling aids. A real throttle response immediately overrides the estimate and causes backoff.

## 4.6 Preserve logical-message atomicity

The current inbound chunk key is based primarily on sender/opcode. Until a transfer identifier is added, chunks from two concurrent logical messages with the same opcode must not be interleaved.

---

# 5. Event Startup Snapshot Redesign

# 5.1 Keep the existing startup phases initially

The first implementation should retain the current logical startup sequence:

```text
EVENT_START
EVENT_UNITS
EVENT_STATE
```

This limits protocol churn and keeps existing readiness logic intact.

The contents of those messages should become narrower:

- `EVENT_START` — event identity/configuration required before roster hydration;
- `EVENT_UNITS` — compact roster identity and event-specific deltas;
- `EVENT_STATE` — runtime state not already conveyed by the first two messages.

After instrumentation confirms which initial `EVENT_STATE` fields duplicate startup data, redundant fields should be removed from the startup form. If the startup `EVENT_STATE` message eventually becomes empty/redundant, it may be eliminated in a later protocol revision, but elimination is not required for the first pass.

---

# 5.2 Generalise compact dataset-backed NPC transmission

Introduce a common compacting helper for any event NPC whose base definition can be resolved from a stable `registryID` on a hash-matched client.

Conceptually:

```text
Full event NPC
    = authored dataset definition
    + event placement/configuration
    + difficulty/scaling adjustments
    + variant/preset adjustments
    + mutable runtime values

Network startup NPC
    = registry identity
    + event placement/configuration
    + authored-definition deltas only where necessary
    + runtime values only where they differ from the resolved base
```

The compact representation should reuse/extend the existing `_network*Mode` hydration mechanism.

Required categories include:

### Always transmit

- event unit ID;
- `registryID`;
- team assignment;
- initiative/order information;
- raid marker;
- active/hidden/dead or equivalent event flags when relevant;
- variant/preset identity required to reproduce the host's resolved unit;
- any event-only identity or ownership relationship that does not exist in the base dataset.

### Inherit from local registry when unchanged

- name/description and other authored presentation fields;
- base spell list;
- base resource definitions;
- base stat definitions/values;
- other dataset-derived fields already guaranteed by the hash check.

### Transmit as sparse delta when changed

- difficulty/player-count stat scaling;
- event-editor stat overrides;
- current/max resource overrides caused by scaling or event setup;
- variant/preset modifications that cannot be reconstructed from an identity reference alone;
- spell additions/removals not implied by the resolved variant/preset;
- any runtime value which must differ from the base unit at the instant startup completes.

The implementation must not blindly set resources to `inherit` for all NPCs. Unlike the existing summoned-unit optimisation, normal event NPCs may have difficulty or player-count scaling that changes resource maxima/current values. Resource delta semantics must preserve those changes exactly.

---

# 5.3 Extend EventUnit network hydration only as required

The preferred approach is to extend the existing modes rather than create a parallel serializer.

Possible modes:

```text
resources: inherit | override | delta
spells:    inherit | override | delta
stats:     inherit | override | bonus/merge
```

Exact names may follow existing conventions, but behavior must be explicit.

A `delta` resource mode should mean:

1. resolve the base resource list locally;
2. apply only transmitted changes by resource reference;
3. preserve current and maximum/value semantics exactly.

A spell delta should be used only if required. If variant/preset identity already determines the spell set, the network should transmit the identity rather than a repeated spell-ref list.

---

# 5.4 Player units are not assumed to be reconstructible from NPC registry data

The compact NPC path must not be applied to player units unless a separate proof shows that the client's locally available profile state is an authoritative reconstruction source.

Player units may legitimately have unique:

- equipment-derived stats;
- profile resources;
- learned spells;
- character-specific modifiers;
- temporary runtime state.

The first implementation should therefore optimise dataset-backed NPCs and keep the existing player-unit representation unless a narrower player-specific optimisation is independently validated.

---

# 5.5 Conditional one-to-many startup delivery

The host currently sends the same startup snapshot separately to each client by whisper.

Once payload compaction and the new scheduler are in place, add a conditional common-snapshot delivery path for sessions where all intended recipients are already listening on the event/session channel.

Conceptually:

```text
Common initial snapshot
    -> send once to event/session channel

Client-specific repair / late join
    -> send snapshot by WHISPER
```

This can reduce host packet count approximately from:

```text
snapshot packets × client count
```

to:

```text
snapshot packets
```

for the common initial snapshot.

However, channel delivery must be **conditional**, not unconditional. The current API documentation indicates that whispers outside instanced content are exempt from the normal per-prefix throttle, while channel traffic can be channel-throttled. The sender should therefore choose the lower-cost valid path for the current session rather than always replacing whispers with channel traffic.

The initial implementation may retain whispers if channel readiness/session-authority validation is not yet sufficiently proven. The PDD requirement is that the transport API support one-to-many common startup delivery without forcing all later resync traffic onto the channel.

---

# 6. Packet Sizing

Remove the fixed 180-byte normal chunk ceiling as the primary chunk size.

`ResolveChunkPlan()` already has enough information to calculate the actual payload available after the RPE header:

```lua
packetPayloadLimit = MaxAddonMessageLength - #serializedHeader
```

The sender should choose the largest safe payload that fits the current packet header rather than:

```lua
min(SafeChunkLength, packetPayloadLimit)
```

with `SafeChunkLength = 180`.

A small explicit safety margin may be retained if testing demonstrates a real need, but it must be justified and substantially smaller than the current 75-byte unused allowance.

Requirements:

- no emitted addon message may exceed 255 bytes;
- multi-digit chunk indexes/counts must be included when calculating header size;
- UTF-8/byte length must be measured using the same byte semantics used by the actual WoW Lua string/API boundary;
- chunk planning must remain deterministic for sender and diagnostics;
- tests must cover transitions such as 9 -> 10 and 99 -> 100 chunks because chunk-token header length changes.

Increasing a typical data chunk from 180 bytes to approximately 235–245 usable bytes should reduce physical message count by roughly one quarter for sufficiently large payloads, before any semantic unit compaction is counted.

---

# 7. Outbound Scheduler Redesign

# 7.1 Replace packet FIFO with logical-message scheduling

The queue should schedule **logical messages**, each containing one or more physical chunks.

Conceptual structure:

```lua
QueuedMessage = {
    id = ...,
    opcode = ...,
    priority = ...,
    distribution = ...,
    target = ...,
    chunks = {...},
    nextChunkIndex = 1,
    replaceKey = nil,
    callbacks = ...,
}
```

Priority applies when choosing which logical message begins next.

Once a chunked logical message starts, its chunks should remain contiguous until it completes or fails. This preserves compatibility with the current inbound chunk-reassembly key and avoids interleaving two transfers of the same opcode.

---

# 7.2 Priority classes

Introduce three traffic classes:

```text
CRITICAL
NORMAL
BACKGROUND
```

### CRITICAL

Examples:

- `EVENT_START`;
- `EVENT_UNITS` during initial startup;
- initial startup `EVENT_STATE`;
- required startup readiness/resource bootstrap messages;
- explicit resync/repair responses when a client is blocked waiting for them.

### NORMAL

Examples:

- active combat/event mutations;
- spellcast lifecycle communications;
- live resource/state changes that affect current gameplay.

### BACKGROUND

Examples:

- non-urgent synchronization;
- bulk administrative/state replication which can tolerate delay;
- periodic refreshes not blocking an active user action.

Priority must not mean permanent starvation. After a bounded amount of critical traffic, normal/background traffic must eventually be serviced if it remains queued.

A weighted policy is preferable to strict permanent priority once startup completes.

---

# 7.3 Adaptive prefix throttle controller

Replace `SendDelay`/`NextSendAt` as the primary mechanism with an allowance controller.

Initial default assumptions may follow the currently documented WoW behavior:

```text
capacity estimate:       10 messages
refill estimate:          1 message / second
```

These are estimates only.

Conceptual state:

```lua
PrefixThrottleState = {
    capacity = 10,
    tokens = 10,
    refillInterval = 1.0,
    lastRefillAt = ...,
    blockedUntil = 0,
    consecutiveThrottles = 0,
}
```

The queue pump should:

1. refill estimated tokens according to elapsed time;
2. send immediately while eligible budget exists;
3. cap work per pump/frame so a queue flush itself cannot become a CPU hitch;
4. decrement local allowance when a send is accepted;
5. stop sending from that prefix when the API returns `AddonMessageThrottle`;
6. schedule the next useful attempt near the estimated replenishment time rather than retrying at 0.2/0.4 seconds;
7. increase the recovery delay if repeated throttle results prove that the server's current policy is stricter than the default estimate;
8. slowly recover toward the default estimate after sustained successful sending.

No scheduler estimate may override a real throttle result.

---

# 7.4 Distribution-aware behavior

The scheduler must retain the message distribution with every logical message and apply appropriate policy.

Current API documentation states that the normal per-prefix restriction does not apply to whispers outside instanced content. Therefore:

- `WHISPER` outside an instance may use an optimistic policy and continue sending accepted messages without imposing the normal one-token-per-second sustained pace;
- the sender must still cap sends per pump/frame and must immediately fall back to throttled behavior if the API returns `AddonMessageThrottle`;
- inside instances, or for distributions subject to the prefix throttle, the normal estimated allowance applies.

The implementation should use WoW's current instance/context APIs rather than infer the context from RPE event type.

---

# 7.5 Separate AddonMessageThrottle and ChannelThrottle

Result code `3` and result code `8` must no longer share one undifferentiated backoff state.

## AddonMessageThrottle

Treat as a prefix-wide allowance exhaustion signal.

Effects:

- stop other sends using the same RPE prefix until the next estimated useful attempt;
- set estimated prefix allowance to zero;
- update throttle diagnostics;
- retry the blocked logical message after recovery without discarding/reordering its already-sent chunks.

## ChannelThrottle

Treat as a channel/distribution-specific block.

Effects:

- pause sends to the affected channel;
- do not automatically block eligible whispers or other distributions unless they separately encounter prefix throttling;
- retain the logical message in place for that channel;
- allow the scheduler to choose other eligible work while the channel is blocked.

This distinction prevents a channel-specific problem from unnecessarily freezing all RPE communications.

---

# 7.6 Remove exponential polling from ordinary throttle handling

The current sequence based on `SendDelay * 2^attempts` should be removed from the normal throttle path.

Throttle recovery should instead be based on:

```text
estimated allowance replenishment
+ observed repeated-throttle penalty when necessary
```

Exponential backoff remains appropriate only as a secondary safety response when the estimated recovery time repeatedly proves too short, not as the first response to every throttle.

---

# 7.7 Coalescing replaceable pending state

Some queued messages represent snapshots where only the newest unsent state matters.

For those message types, define a `replaceKey` and replace an older queued logical message if:

- the older message has not started transmitting;
- both messages have compatible target/distribution/session identity;
- protocol semantics say the newer snapshot supersedes the older snapshot.

Potential candidates include selected state/resource snapshot messages.

Do not coalesce:

- ordered combat actions;
- spell lifecycle transitions where every transition is semantically relevant;
- already-started chunked messages;
- initial `EVENT_START`/`EVENT_UNITS` messages unless the entire startup attempt is explicitly cancelled and restarted.

This prevents temporary throttling from building a queue of stale state that must be sent before the client can catch up.

---

# 8. Startup Priority and Queue Interaction

Event startup should be represented as one high-level transport operation with ordered logical messages:

```text
StartupTransfer(client/session)
    1. EVENT_START
    2. EVENT_UNITS
    3. EVENT_STATE (minimal startup runtime state)
```

Requirements:

- the three messages retain their required logical order;
- chunks within each message remain contiguous;
- the transfer is CRITICAL while the recipient is not ready;
- unrelated background messages must not be inserted between chunks of the same logical startup message;
- normal traffic may be serviced between complete logical startup messages only if fairness/budget rules require it and doing so does not delay readiness materially;
- cancellation of an event start must invalidate unsent startup messages via `shouldSkip`/generation identity rather than allowing stale snapshots to transmit later.

For one-to-many channel startup, the same ordering applies once to the shared session transfer.

---

# 9. Diagnostics and Performance Evidence

Existing comms diagnostics should be extended so the effect of these changes is measurable.

For every logical send, record at minimum:

```text
opcode
scope
priority
serialized payload bytes
physical packet count
largest packet bytes
queue-enter timestamp
first-send timestamp
last-send timestamp
queue wait time
transport duration
throttle count
retry count
distribution/target
coalesced/replaced status
```

For event startup, record a single summary containing:

```text
EVENT_START bytes / packets
EVENT_UNITS bytes / packets
EVENT_STATE bytes / packets
startup total bytes / packets
recipient count
shared-channel vs per-client delivery mode
time from Server:StartEvent to first packet
time from Server:StartEvent to final startup packet accepted
time to client rosterReady
time to client unitsReady
time to client resourcesReady
time to fully event-ready
number of AddonMessageThrottle results
number of ChannelThrottle results
```

Diagnostics should also identify the largest unit records in `EVENT_UNITS` during debug/profiling so future regressions can be traced to a particular unit type or field category.

---

# 10. Success Criteria

The change is complete only when both payload and scheduler improvements are demonstrated.

## 10.1 Functional correctness

- Event startup produces the same resolved unit state on host and clients as before.
- Dataset-backed NPC resources, stats and spells remain correct under normal, heroic and mythic scaling where applicable.
- Player-count scaling remains correct.
- Unit variants/presets remain correct.
- Summoned/pet units continue to hydrate correctly.
- Player units remain correct.
- Unit current health/resources at the moment readiness completes match the host.
- Late join and explicit resync produce the same state as initial startup.
- Dataset/ruleset hash mismatch continues to block event startup.
- No stale startup transfer may complete after the event was cancelled/replaced.

## 10.2 Network efficiency

For representative NPC-heavy events using dataset-backed units:

- semantic compaction must materially reduce `EVENT_UNITS` bytes versus the current full representation;
- physical startup packet count should be reduced by at least 25% from chunk-size improvement alone for payloads large enough to span several chunks;
- the combined unit compaction + chunk-size changes should target at least a 50% reduction in `EVENT_UNITS` packet count for typical dataset-backed NPC rosters, with actual result reported by diagnostics rather than assumed;
- no packet may exceed the WoW addon-message limit;
- common channel startup, when selected, must emit only one common snapshot rather than one identical snapshot per client.

## 10.3 Scheduler behavior

- There is no unconditional 0.2-second delay between burst-eligible packets.
- When allowance is available, multiple startup packets may be accepted in one scheduler pump, subject to a bounded per-frame send cap.
- A real `AddonMessageThrottle` result pauses prefix traffic until a useful retry time instead of retrying at 0.2/0.4 seconds.
- A `ChannelThrottle` does not unnecessarily block eligible whisper traffic.
- CRITICAL startup traffic begins ahead of queued BACKGROUND traffic.
- BACKGROUND traffic eventually progresses after critical pressure subsides.
- Pending replaceable state messages coalesce instead of accumulating stale snapshots.

## 10.4 User-visible result

- The event startup loading/readiness period should be substantially shorter for multi-unit events.
- Startup time should scale primarily with **unavoidable runtime delta data**, not with the full authored NPC definitions or an arbitrary fixed delay per physical packet.
- Increasing the number of clients should have much less impact when shared startup delivery is available.

---

# 11. Affected Code Areas

Primary files expected to change:

```text
server/server_Event.lua
core/classes/Event.lua
core/classes/EventUnit.lua
core/internal/comms/Core.lua
core/internal/comms/MessageQueue.lua
core/internal/comms/Diagnostics.lua
```

Likely integration/validation areas:

```text
client/client_Event.lua
server/server_EventVariants.lua
server/server_EventSpellEquipmentVariants.lua
server/server_EventResourceIntegration.lua
core/internal/comms/Operations.lua
core/internal/comms/Serialization.lua
```

Session/channel code may also require changes if conditional shared startup delivery is implemented.

The implementation must read the current versions and trace the exact call paths before editing; the file list above is architectural guidance, not permission to change every listed file.

---

# 12. Regression Matrix

The following cases must be explicitly exercised.

| Area | Required cases |
|---|---|
| NPC hydration | Base NPC, scaled NPC, NPC with overridden stats, NPC with resource overrides, NPC with spell changes |
| Variants | No variant, resource variant, stat variant, spell/equipment variant |
| Players | Single player, multiple players, player with custom resources/stats/spells |
| Summons | Existing compact pet/summon path remains compatible |
| Event sizes | 1 unit, one full portrait page, multi-page roster, large NPC-heavy roster |
| Clients | 1 client, several clients, late join, reconnect/resync |
| Distribution | WHISPER outside instance, WHISPER inside instance, CHANNEL where supported |
| Throttle results | success, `AddonMessageThrottle`, `ChannelThrottle`, permanent failure code |
| Chunk boundaries | single packet, 2 chunks, 9/10 chunks, 99/100 chunks if practical |
| Queue | critical ahead of background, fairness, coalescing, cancellation/skip, queue-full behavior |
| Ordering | no chunk interleaving corruption; startup opcodes received in valid order |
| Local echo | channel startup does not duplicate host-side delivery |

Host/client resolved event-unit snapshots should be compared structurally in deterministic tests wherever WoW API calls can be mocked.

---

# 13. Implementation Sequence

This PDD defines one combined feature, but implementation should be staged to isolate regressions.

## Phase A — Measurement and packet sizing

- Extend diagnostics with bytes, chunk counts and queue timing.
- Remove/reduce the arbitrary 180-byte chunk ceiling using the computed packet payload limit.
- Validate all boundary sizes.

This creates an immediate packet-count reduction and establishes a baseline for later phases.

## Phase B — Compact startup unit payloads

- Generalise registry-backed NPC inheritance/delta serialization.
- Preserve scaling, resource, stat and spell deltas.
- Validate host/client resolved state equivalence.
- Inspect and trim redundant initial `EVENT_STATE` fields.

## Phase C — Adaptive scheduler

- Introduce logical-message queue entries and priorities.
- Replace fixed pacing with the prefix allowance controller.
- Separate `AddonMessageThrottle` and `ChannelThrottle` recovery.
- Add bounded burst pumping and fairness.

## Phase D — Coalescing and cancellation

- Add replacement keys only to protocol messages proven to be supersedable.
- Preserve ordered gameplay messages.
- Ensure cancelled startup snapshots are skipped.

## Phase E — Shared startup fan-out

- Validate event/session channel readiness and sender authority.
- Send the common initial snapshot once when channel delivery is advantageous and safe.
- Keep WHISPER for late join, repair and contexts where whisper is the better transport.

Each phase must be benchmarked before proceeding so packet-size improvements and scheduler improvements can be measured independently.

---

# 14. Risks and Mitigations

## Risk: client reconstructs a different NPC than the host

**Mitigation:** preserve the existing dataset/ruleset hash gate; compare fully resolved unit state in deterministic tests; fall back to explicit override data for fields that cannot be reproduced from identity.

## Risk: resource scaling is lost by overusing inheritance

**Mitigation:** implement resource deltas rather than assuming all registry-backed resource state is identical to the base dataset.

## Risk: burst sending causes more throttle errors

**Mitigation:** use a bounded local allowance estimate and immediately obey real API throttle results. Do not implement an unrestricted send loop.

## Risk: dynamic server throttle differs from documented defaults

**Mitigation:** treat 10-message capacity/1-second refill only as initial estimates; repeated throttle results adapt the controller to stricter conditions.

## Risk: priority starves background traffic

**Mitigation:** use bounded/weighted priority and restore fair scheduling after startup-critical work is complete.

## Risk: chunk interleaving corrupts reassembly

**Mitigation:** make chunked logical messages atomic until a transfer ID exists in the wire protocol.

## Risk: channel broadcast is slower than whisper in some contexts

**Mitigation:** make shared channel delivery conditional and distribution-aware; retain whisper fallback rather than replacing it globally.

## Risk: larger chunks expose an overlooked header-size edge case

**Mitigation:** calculate actual serialized header size for the final part count and add deterministic boundary tests.

---

# 15. Decisions

The following decisions are part of this design:

1. **Do not tune the current 0.2-second delay; replace fixed-delay pacing.**
2. **Optimise startup payload before attempting to brute-force throughput.**
3. **Reuse registry identity and the existing EventUnit inheritance/bonus concepts for dataset-backed NPCs.**
4. **Preserve runtime/scaling deltas explicitly; inheritance must never silently change gameplay state.**
5. **Use the actual 255-byte packet budget instead of an arbitrary 180-byte normal payload cap.**
6. **Schedule logical messages with priority, while keeping chunks of one logical message contiguous.**
7. **Treat `AddonMessageThrottle` and `ChannelThrottle` separately.**
8. **Use documented throttle values only as adaptive starting estimates.**
9. **Keep WHISPER-based late join/resync even if common initial startup can be broadcast once.**
10. **Require diagnostics to prove byte, packet and readiness-time improvements before the optimisation is considered complete.**

---

# 16. Expected Outcome

After implementation, event startup should no longer spend most of its time transmitting duplicated definition data through a queue that intentionally sleeps between every packet.

The expected flow becomes:

```text
Server:StartEvent
    |
    +--> verify client dataset/ruleset hashes
    |
    +--> build compact startup snapshot
    |       EVENT_START: event identity/config
    |       EVENT_UNITS: registry IDs + runtime deltas
    |       EVENT_STATE: minimal remaining runtime state
    |
    +--> serialize into maximum-safe-size packets
    |
    +--> enqueue as CRITICAL logical messages
    |
    +--> adaptive scheduler
            |
            +--> use immediately available burst capacity
            +--> pace sustained traffic from estimated allowance
            +--> obey actual throttle responses
            +--> isolate channel throttles
            +--> prefer shared one-to-many delivery when advantageous
    |
    v
Clients hydrate dataset-backed NPCs locally
    |
    v
rosterReady / unitsReady / resourcesReady
    |
    v
Event becomes interactive
```

The key product change is that startup latency becomes proportional to **the information that genuinely must cross the network**, while the transport uses the bandwidth Blizzard actually makes available instead of enforcing a fixed artificial delay of its own.
