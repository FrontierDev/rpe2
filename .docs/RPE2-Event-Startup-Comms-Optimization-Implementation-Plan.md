# RPE 2 — Event Startup Communications Optimisation
## Implementation Plan

**Status:** Proposed implementation sequence  
**Target:** RPEngine 2.0 (`FrontierDev/rpe2`), `dev` branch  
**Source design:** `.docs/RPE2-Event-Startup-Comms-Optimization-PDD.md`  
**Implementation tasks:** #164–#174  
**Target implementation model:** GPT-5.6 Sol High working directly against the current GitHub repository/files in this conversation

---

# 1. Objective

Reduce Event startup communication latency by improving both sides of the problem:

1. **reduce the number of physical messages required to describe the startup state**; and
2. **make the outbound transport use available communications capacity efficiently instead of imposing a fixed delay on every packet**.

The final architecture should therefore combine:

```text
smaller EVENT_UNITS payload
        +
larger safe physical chunks
        +
one logical-message queue
        +
priority / safe replacement
        +
adaptive throttle-aware pacing
        +
common initial snapshot delivery where safe
```

while preserving existing Event authority, dataset/ruleset hash validation, late-join/resync behavior, local CHANNEL echo behavior, and all non-Event protocols using the same Comms layer.

---

# 2. Current-Source Findings Which Shape the Plan

The task split is based on the current `dev` implementation, not only the PDD.

## 2.1 Current startup payload split is already reasonably narrow

`server/server_Event.lua::sendEventSnapshotToClient()` sends:

```text
EVENT_START
EVENT_UNITS
EVENT_STATE
```

`buildStartArguments()` already calls:

```lua
eventState:ToStartArguments(false)
```

so the full unit roster is not duplicated inside `EVENT_START`.

`Event:ToStateArguments()` is currently only:

```text
channelName
eventId
turnNumber
tickNumber
totalTicks
```

Therefore this plan does **not** create a separate task to invent a smaller startup-only `EVENT_STATE` format. Final integration will re-check it, but the current five-field message is too small to justify protocol churn without evidence.

## 2.2 `EVENT_UNITS` is the main semantic payload target

Current `buildEventUnitsArguments()` calls:

```lua
eventState:SerializeUnitsForNetwork()
```

for the full roster.

The repository already has a compact registry-backed pattern for summoned units in `buildCompactSummonedUnitDelta()`, using inherited spell/resource state and stat bonuses. The startup work should generalize that architecture rather than create a second wire model.

## 2.3 Resource inheritance needs a new delta primitive first

Normal Event NPCs may have difficulty/player-count scaling or runtime resource values which differ from their dataset base. Plain `resources = inherit` is therefore not sufficient for general startup compaction.

A small resource-delta hydration task is separated from startup compaction so the protocol behavior can be proven independently.

## 2.4 The current packet queue is the wrong abstraction for priority scheduling

`Comms:SendMessage()` currently enqueues every physical chunk independently into one FIFO `MessageQueue.Items` list.

The inbound reassembly key is primarily:

```text
sender + opcode
```

so arbitrary chunk interleaving is unsafe. The queue must first become a logical-message queue where a started message retains ownership until all of its chunks complete.

Only after that foundation exists should priority, replacement and adaptive throttle behavior be added.

## 2.5 The current fixed-delay scheduler should be replaced, not tuned

Current `MessageQueue.lua` hard-clamps every send attempt to at least `0.2` seconds apart and handles both AddonMessageThrottle and ChannelThrottle through the same exponential retry path.

The final scheduler instead uses an adaptive allowance estimate, actual send results as authoritative feedback, and separate prefix/channel throttle state.

---

# 3. Non-Negotiable Implementation Rules

Every issue in this plan must follow these rules.

1. **Current `dev` is authoritative.** Read the current version of every affected file immediately before editing.
2. **Trace the real call path before changing it.** Do not implement conceptual API names from this plan if current source has moved or renamed the seam.
3. **Implement one issue only.** Do not pre-implement later tasks merely because an adjacent refactor makes it tempting.
4. **Search all changed APIs/call sites.** Generic Comms changes have repo-wide blast radius.
5. **Exercise pure logic deterministically.** Mock time, `C_ChatInfo.SendAddonMessage`, Registry definitions and EventUnit fixtures where possible.
6. **Do not claim multiplayer/in-game validation that cannot be performed from the repository environment.** List remaining WoW checks explicitly.
7. **Review each diff for architectural expansion.** In particular, do not add a second router/prefix, polling loops, unbounded queues, or a parallel Event serialization model.
8. **Do not close a task until its own acceptance criteria are validated.** Stop after the current issue; do not proceed automatically to the next issue.

---

# 4. Delivery Sequence

The tasks are intentionally small and dependency-ordered:

```text
#164 Diagnostics baseline
   ├───────────────┬───────────────────────┐
   v               v                       v
#165 Chunk size   #166 Resource delta     #168 Logical-message queue
                   |                       |
                   v                       v
                #167 NPC compaction      #169 Priority/fairness
                                           |
                                           ├───────────┐
                                           v           v
                                        #170        #171
                                     Coalescing   Adaptive throttle
                                                     |
                                                     v
                                                  #172
                                             Startup priority policy
                   |                                 |
                   └──────────────┬──────────────────┘
                                  v
                               #173
                       Common initial snapshot
                                  |
                                  v
                               #174
                    Final integration/perf audit
```

Notes:

- #165 and #166 can proceed independently after #164 if desired.
- #168–#171 are transport foundations and should be validated before Event-specific priority/distribution changes.
- #173 deliberately comes late because it changes the number/distribution of startup sends and should be evaluated on top of the final compact payload and scheduler.
- #174 is a real integration task, not merely documentation.

---

# 5. Task 1 — Issue #164: Baseline Transport and Startup Diagnostics

## Goal

Make the current communications bottleneck measurable before changing behavior.

## Primary files

```text
core/internal/comms/Core.lua
core/internal/comms/MessageQueue.lua
core/internal/comms/Diagnostics.lua
server/server_Event.lua                         [only narrow startup aggregation if needed]
core/debug/*                                    [reuse existing timing helpers]
```

## Work

Add diagnostics for:

```text
logical argument bytes
physical packet bytes/count
queue wait
enqueue-to-delivery duration
queue high-water
throttle result split (3 vs 8)
Event startup opcode totals
```

No chunk-size, pacing, queue-order, throttle or Event payload behavior changes.

## Acceptance summary

The later tasks can quantify exactly how many bytes/packets/time they remove without relying on subjective observations.

---

# 6. Task 2 — Issue #165: Maximum Safe Chunk Payload

## Goal

Remove the current `SafeChunkLength = 180` default ceiling and use the largest actual header-adjusted payload that remains within the 255-byte addon-message limit.

## Primary files

```text
core/internal/comms/Core.lua
core/internal/comms/Serialization.lua           [read; modify only if required]
core/internal/comms/Diagnostics.lua             [small measurement extension]
```

## Work

- derive payload capacity from the serialized packet header;
- converge correctly when chunk-count digit width changes;
- preserve byte-length semantics;
- keep all emitted packets <=255 bytes;
- measure packet-count reduction.

## Scope boundary

Do not change MessageQueue scheduling or Event serialization.

---

# 7. Task 3 — Issue #166: Resource-Delta EventUnit Hydration

## Goal

Add one backward-compatible EventUnit resource network mode capable of resolving local base resources then applying sparse `resourceRef` current/max overrides.

## Primary files

```text
core/classes/EventUnit.lua
core/classes/Event.lua
```

## Work

Introduce/reuse `_networkResourceMode = "delta"` or the final equivalent and prove:

```text
base local resources + sparse host delta == host authoritative startup resources
```

Preserve old explicit and `inherit` modes.

## Scope boundary

No server Event startup compaction yet.

---

# 8. Task 4 — Issue #167: Compact Dataset-Backed NPC Startup Units

## Goal

Reduce `EVENT_UNITS` by sending registry identity plus runtime/event deltas for reconstructible NPCs.

## Primary files

```text
server/server_Event.lua
core/classes/Event.lua                           [only serializer seam if needed]
core/classes/EventUnit.lua                       [only shared delta helper if needed]
```

## Work

For eligible registry-backed NPCs:

```text
inherit reconstructible base definitions
transmit resource deltas
transmit stat bonuses/deltas
inherit spells only where exact
retain all event/runtime identity and modifications
```

Players stay on the existing full representation. Missing/unprovable registry resolution falls back to full data.

Generalize the existing summoned-unit compaction logic where semantics overlap rather than maintaining two independent delta systems.

## Acceptance summary

Client-hydrated unit state must match host state field-for-field for scaled, variant, summoned, hidden/dead and mixed-roster fixtures while `EVENT_UNITS` packet count falls materially for NPC-heavy Events.

---

# 9. Task 5 — Issue #168: Logical-Message Queue Foundation

## Goal

Change the queue abstraction from one item per physical packet to one item per logical `SendMessage()` call containing all chunks.

## Primary files

```text
core/internal/comms/Core.lua
core/internal/comms/MessageQueue.lua
core/internal/comms/Diagnostics.lua
```

## Work

- prebuild/validate all chunks;
- enqueue one logical message;
- send its chunks contiguously once started;
- keep callback semantics once per logical message;
- keep queue capacity bounded in physical pending work;
- preserve current FIFO and 0.2-second pacing for this task.

## Why separate

Priority/adaptive throttle work should not also have to debug a packet-to-logical-message queue conversion.

---

# 10. Task 6 — Issue #169: Priority and Starvation Protection

## Goal

Add generic:

```text
CRITICAL
NORMAL
BACKGROUND
```

logical-message priorities.

## Primary files

```text
core/internal/comms/MessageQueue.lua
core/internal/comms/Core.lua
core/internal/comms/Diagnostics.lua
```

## Work

- priority selects which not-yet-started logical message begins;
- started message remains atomic;
- stable FIFO inside equal priority;
- deterministic starvation protection for lower priorities;
- old callers default to NORMAL.

No Event-specific priority assignment yet.

---

# 11. Task 7 — Issue #170: Safe Latest-State Coalescing

## Goal

Allow explicitly replaceable unsent latest-state messages to supersede older queued state.

## Primary files

```text
core/internal/comms/MessageQueue.lua
core/internal/comms/Core.lua
core/internal/comms/Diagnostics.lua
server/server_Event.lua                        [expected EVENT_STATE opt-in]
other send call sites only when current receiver semantics prove replacement safe
```

## Work

Introduce an explicit `replaceKey` or equivalent. Only not-yet-started messages can be replaced.

`EVENT_STATE` is the primary current candidate. Never infer replacement globally from opcode.

Do not coalesce ordered action/delta/spell/Loot/request-response traffic.

---

# 12. Task 8 — Issue #171: Adaptive Throttle-Aware Scheduling

## Goal

Replace fixed 0.2-second pacing and generic exponential throttle probing.

## Primary files

```text
core/internal/comms/MessageQueue.lua
core/internal/comms/Diagnostics.lua
core/internal/comms/Core.lua                    [metadata/config seam only where required]
```

## Work

Implement a runtime-only adaptive allowance estimate:

```text
initial burst estimate
elapsed-time refill
actual result-code feedback
```

Separate:

```text
AddonMessageThrottle -> prefix allowance/backoff
ChannelThrottle      -> affected channel backoff
```

Allow an initial accepted burst without artificial 200 ms spacing, then pace sustained work from allowance/refill.

Actual API throttle results override estimates. Do not add polling or unrestricted send loops.

## Acceptance summary

Mocked-clock tests must prove burst, exhaustion, refill, result-3 recovery, result-8 channel isolation, logical-message resume, priority composition and absence of retry storms.

---

# 13. Task 9 — Issue #172: Event Startup Priority Policy

## Goal

Use the generic scheduler to make Event startup latency-sensitive without globally elevating every Event opcode occurrence.

## Primary files

```text
server/server_Event.lua
server/server_Session.lua                       [only exact snapshot/reconnect metadata call sites]
core/internal/comms/Core.lua                    [only narrow metadata/ordering seam if needed]
```

## Work

Initial:

```text
EVENT_START
EVENT_UNITS
initial EVENT_STATE
```

are CRITICAL.

Targeted repair/resync which blocks readiness receives corresponding high priority.

Ordinary recurring `EVENT_STATE` remains NORMAL and may retain replacement behavior.

Preserve per-snapshot ordering:

```text
START -> UNITS -> initial STATE
```

and do not allow initial state to be replaced by a later normal state before startup readiness.

---

# 14. Task 10 — Issue #173: Common Initial Snapshot Delivery

## Goal

Stop sending the same initial snapshot N times when the existing session channel can safely deliver one common copy to all initial recipients.

## Primary files

```text
server/server_Event.lua
server/server_Session.lua                       [readiness/accessor only if required]
client/client_Session.lua                       [only if current handshake lacks truthful ready acknowledgement]
core/internal/comms/Channel.lua                 [readiness helper only if required]
core/internal/comms/Core.lua                    [local echo correction only if current behavior requires it]
core/internal/comms/Diagnostics.lua
```

## Work

Separate:

```text
common initial snapshot
        vs
targeted late-join / reconnect / repair snapshot
```

Use CHANNEL only when existing session state proves all intended initial recipients are channel-ready and the distribution is appropriate. Otherwise use complete WHISPER fallback.

Do not infer membership from the host merely having a channel ID.

Preserve:

- current host/session sender validation;
- dataset/ruleset hash gate;
- exact host local echo once;
- delayed local-echo duplicate suppression;
- late join after broadcast via targeted snapshot;
- roster reconciliation ordering.

Build/serialize the common compact roster once per startup operation rather than once per recipient.

---

# 15. Task 11 — Issue #174: Final Integration and Performance Audit

## Goal

Validate the combined system and fix narrow integration defects only.

## Required final audit areas

```text
packet sizing
EventUnit resource delta hydration
NPC compact startup equivalence
logical-message atomicity
queue capacity/callbacks
priority/fairness
coalescing safety
adaptive throttle behavior
initial CHANNEL vs WHISPER fallback
late join/resync
local echo/duplicate suppression
all major non-Event protocols sharing Comms
```

Explicit regressions include:

```text
EVENT_UNIT_DELTA_BATCH
resource sync
spellcast lifecycle
combat/reactions
Loot delivery
Skill Roll requests
Event end
Autopilot lifecycle
manual Events
```

The final report must quantify contributions from:

```text
larger chunks
NPC compaction
common initial snapshot
priority scheduling
adaptive pacing
```

and must clearly distinguish deterministic/mock measurements from real WoW multiplayer measurements.

The audit also re-checks `EVENT_STATE`. If it remains the current five fields, no additional startup-specific protocol should be added merely to save negligible bytes.

---

# 16. Issue Map

| Task | Issue | Scope | Primary dependency |
|---|---:|---|---|
| 1 | #164 | Baseline diagnostics | — |
| 2 | #165 | Maximum safe chunk payload | #164 |
| 3 | #166 | EventUnit resource delta mode | — |
| 4 | #167 | Compact dataset-backed NPC startup | #166 |
| 5 | #168 | Logical-message queue | #164 |
| 6 | #169 | Priority + starvation protection | #168 |
| 7 | #170 | Safe state coalescing | #168, #169 |
| 8 | #171 | Adaptive throttle scheduler | #168, #169 |
| 9 | #172 | Event startup priority policy | #169, #171 |
| 10 | #173 | Common initial snapshot delivery | #165, #167, #171, #172 |
| 11 | #174 | Final integration/performance sign-off | #164–#173 |

---

# 17. Recommended Execution Prompt

For each issue, use a prompt equivalent to:

> Implement Issue #NNN on the `dev` branch. Read the current version of each affected file and do not assume the code is unchanged from when the PDD/implementation plan/issue was written. Trace the exact existing call paths being modified and implement only the current issue's scope. Review the resulting diff for accidental architectural expansion. Identify regressions for every modified API/call site. Exercise pure logic with deterministic test cases/mocks where possible. Compare against the diagnostics/baseline required by the issue. Once fully validated, close the issue and report the exact files changed, tests/results, remaining in-game validation, and commit SHA. Do not proceed with the next task until instructed.

This project is deliberately split so each issue can be completed in one focused GPT-5.6 Sol High conversation turn/workflow without relying on uncommitted changes from another issue.

---

# 18. Final Definition of Done

The project is complete only when #174 validates that:

1. Event startup sends materially fewer physical packets for NPC-heavy Events;
2. no physical packet exceeds the WoW addon-message limit;
3. dataset-backed NPC compaction is lossless for gameplay state;
4. player units and unresolved registry units remain safe;
5. the outbound queue is logical-message-based and preserves chunk reassembly invariants;
6. Event startup is prioritized without starving normal/background traffic;
7. only explicitly supersedable state is coalesced;
8. fixed 0.2-second pacing and rapid exponential throttle probing no longer drive the transport;
9. prefix and channel throttles are handled separately and adaptively;
10. common initial delivery is used only when session readiness proves it safe, with targeted fallback retained;
11. late join/reconnect/resync still receives a complete authoritative snapshot;
12. all major protocols sharing Comms retain correct ordering/callback behavior;
13. performance improvements are demonstrated with diagnostics rather than asserted subjectively;
14. remaining WoW multiplayer/in-instance validation is explicitly documented rather than assumed.
