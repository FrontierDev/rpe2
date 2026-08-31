# RPE 2 — Loot System
## Implementation Plan

**Status:** Proposed implementation sequence  
**Target:** RPEngine 2.0 (`FrontierDev/rpe2`)  
**Product source:** `.docs/RPE2-Loot-System-PDD.md`  
**Implementation target:** current `dev` branch at the start of each task  
**Source snapshot inspected for this plan:** `dev` at `6e4a16ac8e6e74816bae435dfa73d589ebf69ae5`  
**Coding model:** 5.6-Luna-ExtraHigh  
**Scope:** loot-table authoring, direct loot, item/currency rewards, Group/Personal distribution, recipient delivery/idempotence, end-of-event rewards, ad-hoc Event Manager distribution  
**Explicitly out of scope:** Need/Greed, player loot rolls, bidding, master-looter voting, corpse/chest looting, offline mail, non-item/non-currency rewards

---

# 1. Implementation Objective

Implement one loot pipeline in which the following dimensions remain independent:

```text
Source
  Direct reward | Loot Table

Reward
  RPE Item | RPE Currency

Distribution
  Group | Personal

Timing
  End of Event | Ad Hoc
```

Both Event-end rewards and Event Manager ad-hoc rewards must converge on the same host-side grant execution service and the same recipient delivery service.

Canonical runtime path:

```text
Authored/ad-hoc LootGrant
        ↓
Host validates source + eligible players
        ↓
Host resolves concrete reward stack(s)
        ↓
Host assigns recipient(s)
        ↓
One targeted delivery per recipient/grant
        ↓
Recipient validates all rewards
        ↓
Recipient transactionally applies Inventory/Currency changes
        ↓
Recipient persists duplicate-protection receipt
        ↓
Recipient acknowledges actual applied result
        ↓
Host records/presents delivery status
```

No task in this project should introduce a player loot-roll state machine.

---

# 2. Current-Code Findings

The implementation must start from the live `dev` tree rather than assuming the PDD's proposed filenames are still exact.

## 2.1 `Loot` already exists but is not yet a usable weighted table

`core/classes/Loot.lua` currently stores:

```lua
{
    id,
    name,
    description,
    items = {},
    conditions = {},
    tags = {},
}
```

No current code search found a runtime consumer of `loot.items`, and the current Data Editor has no Loot inspector. Therefore the implementation should evolve this existing class/collection rather than create a second `LootTable` collection.

Because imported datasets may still contain the legacy `items` field, migration must be non-destructive. Do not silently reinterpret unknown legacy record shapes. Preserve legacy data through normalization until a record can be converted safely; canonical new authoring uses `entries`.

## 2.2 The Database already registers the `loot` collection

`core/internal/database/Database.lua` already contains a dataset entry definition for `loot`. Dataset schema is already versioned. The task which changes canonical Loot serialization must inspect the current schema on `dev` and increment it exactly once if required by the final migration.

## 2.3 Event-end loot is currently only a list of references

`core/classes/Event.lua` currently owns:

```lua
lootRefs = {}
```

and serializes it as a reference list through the Event network payload.

`server/server_Event.lua` copies `lootRefs` into live Event state.

There is no implemented distribution runtime behind this field.

## 2.4 Event Manager Settings already exposes `Global Loot`

`server/ui/eventmanage/page_EventManageSettings.lua` currently lets the host add/remove `datasetId:lootId` references under a `Global Loot` settings section.

The new design must replace/upgrade that authoring surface to structured **End of Event Loot** grants containing source + distribution, while retaining safe compatibility for existing `lootRefs` data.

Because the old field had no runtime distribution semantics, compatibility primarily means preserving authored references rather than preserving a non-existent execution result. Legacy `lootRefs` should normalize to Loot Table grants using the conservative `group` distribution default unless the live source at implementation time proves a different historical contract.

## 2.5 Loot Data Editor authoring is incomplete

`client/ui/editor/pages/page_Loot.lua` currently provides only the Loot list and generic create/delete toolbar.

`client/ui/editor/windows/window_DataEditor.lua` includes `loot` in entry definitions and page refresh routing, but currently has no Loot inspector mapping and does not include `loot` in dependency-recompute collections.

A dedicated Loot inspector is therefore required.

## 2.6 Event Manager Actions is already implemented

On current `dev`, `server/ui/eventmanage/page_EventManageActions.lua` is no longer a stub. It already contains host/action readiness validation and sections for direct health/life changes, Aura management and Skill-roll requests.

Ad-hoc loot should extend this existing page and reuse its live-event/host validation seam. It must not create a second Event Manager action window.

## 2.7 Existing item/currency mutation APIs are authoritative

Item rewards must use:

```lua
Addon.Client.Inventory.AddItem(...)
```

Currency rewards must use:

```lua
Addon.Internal.Profile.AddCurrencyAmount(...)
```

The current Achievement reward implementation already demonstrates item/currency reference validation, snapshots, rollback verification and currency-cap handling. Loot should reuse those low-level semantics, not route loot through Achievement completion.

## 2.8 Comms opcode allocation must be checked at implementation time

`core/internal/comms/Operations.lua` statically owns opcodes through the Guild Admin operations, while the current Event Manager Skill Roll implementation dynamically registers `SKILL_ROLL_REQUEST` at opcode 28.

Loot delivery must allocate the next genuinely free operation IDs at implementation time. Do not assume 28 is free and do not hard-code IDs from this plan without re-reading the live table and dynamic registrations.

---

# 3. Canonical Data Contracts

## 3.1 Loot Table

Canonical new Loot data:

```lua
Loot {
    id = "blackrock_cache",
    name = "Blackrock Cache",
    description = "...",
    drawCount = 2,

    entries = {
        {
            id = "sword",
            type = "item",
            ref = "campaign:blackrock_sword",
            weight = 10,
            minQuantity = 1,
            maxQuantity = 1,
        },
        {
            id = "marks",
            type = "currency",
            ref = "campaign:commendation",
            weight = 40,
            minQuantity = 2,
            maxQuantity = 5,
        },
    },

    conditions = {},
    tags = {},
}
```

Validation rules:

- `drawCount` is a positive integer;
- entry IDs are stable/non-empty within one table;
- type is only `item` or `currency`;
- ref is non-empty and resolvable when executing;
- weight is finite and `> 0`;
- quantities are positive integers;
- `maxQuantity >= minQuantity`.

Unknown/invalid entries are not silently removed from probability calculations at runtime. A table containing an invalid executable entry fails validation before drawing.

## 3.2 Concrete Reward

```lua
{
    type = "item" | "currency",
    ref = "dataset:id" | builtinCurrencyId,
    amount = 1,
}
```

Duplicate concrete rewards of the same normalized type/ref from one resolution are merged where safe.

## 3.3 Loot Grant

Use one normalized grant contract for both Event-end and ad-hoc execution:

```lua
{
    sourceType = "direct" | "loot_table",

    -- direct
    reward = {
        type = "item" | "currency",
        ref = "...",
        amount = 1,
    },

    -- table
    lootRef = "dataset:lootId",

    distribution = "group" | "personal",
}
```

The runtime caller supplies the eligible player set separately. Event-end grants use all participating player EventUnits. Ad-hoc grants use the host-selected subset.

## 3.4 Delivery

Per recipient:

```lua
{
    protocolVersion = 1,
    deliveryId = "...",
    eventSessionId = "...",
    grantId = "...",
    recipientName = "...",
    rewards = {
        { type = "item", ref = "campaign:item", amount = 1 },
    },
}
```

A delivery is concrete. Recipients never receive a Loot Table reference to roll themselves.

---

# 4. Core Behavioral Rules

## 4.1 Personal

Direct Personal:

```text
one concrete direct reward copied to every eligible player
```

Loot Table Personal:

```text
resolve the Loot Table independently for every eligible player
```

One player's result cannot affect another player's result.

## 4.2 Group

Direct Group:

```text
select exactly one eligible player for the direct reward stack
```

Loot Table Group:

```text
resolve the Loot Table once
-> for each resulting concrete reward stack, select exactly one eligible player
```

Do not split one resolved quantity stack across several players.

## 4.3 Randomness

Use injected RNG seams in pure resolution functions. Relative weights do not need to total 100.

Do not add fairness systems, bad-luck protection, round-robin state or prior-loot weighting.

## 4.4 Recipient failure does not reroll Group assignment

Once Group loot assigns a reward to Player B, an unavailable/failed Player B remains the authoritative assignment.

Do not automatically assign the same reward to Player C after failure because the first delivery may actually have succeeded with only its acknowledgement lost.

A retry reuses the same `deliveryId`, concrete rewards and recipient.

---

# 5. Persistence and Idempotence

Add bounded Profile-owned loot receipt state:

```lua
profile.loot = {
    receipts = {
        [deliveryId] = {
            status = "in-progress" | "complete" | "failed" | "recovery-required",
            completedAt = ...,
            result = ...,
            snapshots = ...,
        },
    },
}
```

The exact internal shape may follow the existing Achievement reward transaction state.

Required rules:

1. Persist an `in-progress` receipt before mutating rewards where needed to protect against reload/crash duplication.
2. Validate every reward before any mutation.
3. Snapshot affected inventory variants/currency balances.
4. Apply and verify each reward.
5. Roll back earlier applied rewards on failure where existing APIs safely support it.
6. Persist `complete` only after verified application.
7. A repeated completed `deliveryId` returns the previous acknowledgement and applies nothing.
8. An interrupted `in-progress` delivery must become/recover as `recovery-required`; it must not blindly reapply.
9. Bound/prune the receipt ledger. Use a documented fixed maximum and/or age policy; unbounded SavedVariables are forbidden.

---

# 6. Event-Session Authority

Recipient validation must use the transport sender, not a claimed host field.

For active events, compare sender with the active Event host.

For Event-end loot, a delivery may arrive after `EVENT_END` teardown. Before clearing the active Event, retain a small bounded **runtime-only recent event session authority record** sufficient to validate late loot delivery:

```text
eventSessionId
hostName
ended/active state
```

Do not persist this as character progression. Keep only a bounded number of recent sessions and clear naturally on reload.

This prevents accepting arbitrary post-event loot while avoiding a race between `LOOT_DELIVERY` and `EVENT_END` network ordering.

---

# 7. Host Grant/Delivery State

The host service should retain transient execution state for the current/recent grant:

```lua
GrantExecution {
    grantId,
    eventSessionId,
    sourceSnapshot,
    assignments,
    deliveriesById,
    status,
}
```

This state is needed to:

- avoid rerolling on retry;
- distinguish assigned from acknowledged loot;
- expose host result summaries;
- retry the exact same recipient delivery;
- prevent duplicate event-end execution.

Do not persist a global loot history unless a later product requirement asks for it.

---

# 8. Event-End Lifecycle

The implementation task must trace the then-current `Server:EndEvent()` and `Client:HandleEventEnd()` paths before editing.

Required semantic sequence:

```text
host requests End Event
        ↓
validate event / existing end-transition rules
        ↓
snapshot event participants + end-loot grants
        ↓
resolve each end grant exactly once
        ↓
dispatch concrete deliveries
        ↓
continue normal EVENT_END broadcast/teardown
        ↓
recipients may ack before or after local EVENT_END teardown
        ↓
host retains transient delivery statuses for result/retry
```

End Event must not block indefinitely waiting for acknowledgements from offline/unreachable players.

An invalid loot definition should fail that grant and be reported, but must not trap the Event in an active state.

Repeated/re-entrant end handling must never reroll or redeliver a completed end grant under a new ID.

Use stable source identity based on the Event session plus end-grant index/identity.

---

# 9. Ad-Hoc Event Manager Flow

The existing Event Manager Actions page should add a Loot section with:

```text
Source
  Direct | Loot Table

Direct Type
  Item | Currency

Reward/Table selector
Quantity (Direct only)

Distribution
  Group | Personal

Eligible Players
  selectable subset of current player EventUnits

[Distribute]
```

After execution show host state such as:

```text
Player A — delivered
Player B — pending acknowledgement
Player C — failed: unknown-item
```

Where an acknowledgement is missing/failed in a retryable way, expose an explicit retry action which reuses the exact same delivery; retry must never reroll the source.

No UI control should be called Roll/Need/Greed or ask players to compete for loot.

---

# 10. Data Editor / Event Authoring

## Loot Tables

Add a Loot inspector supporting:

```text
General
  Name
  Description
  Draw Count
  Tags

Entries
  Add/Remove/Reorder
  Entry ID
  Type
  Reference
  Weight
  Min Quantity
  Max Quantity

Conditions
  preserve existing Condition data/authoring only if current generic infrastructure supports it
```

Use Item reference selection for Item entries and the existing built-in + dataset currency definition model for Currency entries.

Invalid authoring state should be visibly indicated rather than discovered only during Event end.

## End of Event Loot

Upgrade Event Manager Settings from `Global Loot` reference rows to `End of Event Loot` grant rows.

Initial Event-end eligibility is all participating player EventUnits, so no static player-name selector belongs in authoring.

Preserve legacy `lootRefs` safely and migrate/normalize them to group Loot Table grants when no structured grant data exists.

---

# 11. Dependency / Registry Work

Add:

```lua
Registry:ResolveLootReference(lootRef)
```

following current dataset-qualified resolver conventions.

Extend `core/internal/database/Dependecies.lua` across **all** relevant discovery/rewrite/prune paths for:

```text
Loot.entries[].ref (item/currency)
Event end grant lootRef
direct end grant reward.ref
```

Do not update only the primary scanner and leave import/reference-rewrite paths stale.

Add `loot` to Data Editor dependency recomputation where appropriate.

---

# 12. Conditions Decision

Current code search found no runtime consumer of `Loot.conditions`.

Therefore this project must **not invent a new loot-specific condition language**.

Task 1 should re-check current `dev` and generic Condition APIs. If a well-defined generic evaluator already accepts the context required by Loot, it may be wired in explicitly. Otherwise:

- preserve `conditions` in data;
- keep current generic authoring where available;
- document it as not yet participating in Loot resolution;
- do not silently assign new semantics.

---

# 13. Task Decomposition

The implementation is deliberately split so each task has one architectural responsibility and can be executed by 5.6-Luna-ExtraHigh without requiring a repository-wide rewrite.

## Task 1 — Canonical Loot data model, resolver, migration, dependencies

Owns:

- `Loot.lua` normalization/serialization;
- canonical `entries` + `drawCount`;
- safe preservation/migration of legacy `items`;
- dataset schema bump if required;
- `Registry:ResolveLootReference`;
- dependency extraction/rewrite/prune for Loot entry refs;
- no runtime random resolution yet.

## Task 2 — Loot Table Data Editor authoring

Owns:

- Loot inspector mapping;
- General + Entries authoring UI;
- Item/Currency reference selectors;
- validation feedback;
- dependency recompute integration;
- no distribution/event execution.

## Task 3 — Pure deterministic Loot resolution and assignment engine

Owns:

- source validation;
- weighted selection;
- quantity resolution;
- duplicate reward normalization;
- Direct/Table resolution;
- Group/Personal assignment logic;
- injectable RNG + deterministic test seams;
- no networking/persistence/UI.

## Task 4 — Recipient delivery, transactions, duplicate receipts and Comms

Owns:

- `LOOT_DELIVERY` / `LOOT_DELIVERY_RESPONSE` operations;
- recipient event-host validation;
- recent Event-session authority cache;
- item/currency validation/application;
- transaction snapshots/rollback;
- persisted bounded receipt ledger;
- duplicate response behavior;
- recipient feedback seam.

## Task 5 — Host Loot grant coordinator and acknowledgement tracking

Owns:

- eligible player normalization;
- grant execution using Task 3;
- stable grant/delivery identities;
- targeted message dispatch using Task 4;
- transient grant/delivery tracking;
- acknowledgement validation;
- exact retry without reroll;
- host result summary API;
- no Event Manager UI/end-event hook yet.

## Task 6 — Structured End-of-Event grant data and authoring

Owns:

- replace/augment `Event.lootRefs` with canonical structured end grants;
- Event serialization/network compatibility;
- preset/editable state copy paths;
- `Global Loot` -> `End of Event Loot` Settings UI;
- Direct/Table + Group/Personal authoring;
- legacy `lootRefs` normalization;
- no execution on End Event yet.

## Task 7 — Execute authored Loot when an Event ends

Owns:

- exact `Server:EndEvent` integration;
- participant snapshot before teardown;
- one execution per end grant;
- non-blocking acknowledgement behavior;
- stable retry/no-reroll behavior after Event end;
- late response handling through recent session authority;
- normal Event teardown remains intact.

## Task 8 — Ad-hoc Loot distribution in Event Manager Actions

Owns:

- Loot section in existing Actions page;
- Direct/Table selection;
- Group/Personal selection;
- player subset selection;
- call Task 5 coordinator;
- host result/pending/failure presentation;
- explicit same-delivery retry;
- no separate distribution implementation.

## Task 9 — Integration audit, migration/regression hardening and sign-off

Owns:

- full matrix across Tasks 1–8;
- schema/import/export compatibility;
- deterministic RNG checks;
- duplicate/reload/retry safety;
- Event-end ordering;
- ad-hoc UI behavior;
- offline/unacknowledged handling;
- currency caps;
- dependency rewrite validation;
- explicit audit that no player loot-roll mechanics were introduced.

---

# 14. Dependency Order

```text
Task 1
  ├─> Task 2
  └─> Task 3
        └─> Task 5

Task 4 ────────> Task 5

Task 1 ────────> Task 6
Task 5 + Task 6 -> Task 7
Task 5 ────────> Task 8

Tasks 1–8 -> Task 9
```

Task 4 can proceed in parallel with Tasks 2–3 once Task 1 has established the canonical reward/reference terminology, provided it does not depend on weighted resolution internals.

---

# 15. Cross-Task Coding Rules for Luna

Every issue must repeat these instructions because the working tree can change between tasks:

1. Use current `dev` as authoritative at task start.
2. Read the current version of every affected file; do not assume this plan's source snapshot is unchanged.
3. Trace the exact existing call paths being modified before editing.
4. Implement only the current issue's scope; do not pre-implement later tasks.
5. Reuse current Inventory, Currency, Runtime transaction, Comms, Registry, Event and UI abstractions.
6. Review the diff specifically for accidental parallel architecture.
7. Identify regressions for every modified API/call site.
8. Exercise pure logic with deterministic tests/mocks where possible.
9. Preserve existing event authority and addon-message sender validation.
10. Do not introduce Need/Greed/player rolling under any name.

---

# 16. Required End-to-End Validation Matrix

The final integration task must cover at least:

```text
Loot Table authoring
-> item + currency entries save/reload/export/import
-> weights and quantities retained
-> cross-dataset dependencies discovered

weighted resolver
-> deterministic weight boundaries
-> inclusive quantities
-> invalid entries fail before RNG application
-> duplicate rewards normalize

Direct Personal / A,B,C
-> A/B/C each receive reward

Direct Group / A,B,C
-> exactly one assigned recipient

Table Personal / A,B,C
-> table resolved independently three times

Table Group / A,B,C
-> table resolved once
-> each concrete reward stack assigned once

currency at cap
-> appliedAmount may be less than requested
-> delivery remains successful with reason

item/currency mixed delivery
-> all validate before mutation
-> verified transaction/rollback semantics

lost acknowledgement
-> host retries same deliveryId
-> recipient applies nothing twice
-> previous success response returned

reload during in-progress delivery
-> cannot blindly duplicate reward
-> recovery-required handling is explicit

recipient unavailable
-> assignment does not reroll
-> host reports pending/failed
-> explicit retry preserves recipient/result

End Event with 2 grants
-> grants resolve once
-> deliveries dispatch before/through teardown safely
-> Event ends without waiting forever for ack
-> late valid acknowledgement still accepted

repeat/re-entrant End Event
-> no second random resolution/delivery

ad-hoc subset B,C
-> only B/C eligible
-> Group selects one of B/C
-> Personal resolves independently for B and C

manual/non-host client
-> cannot invoke host distribution path

forged LOOT_DELIVERY from non-host
-> rejected

unknown item/currency
-> rejected before partial application

no active/recent matching event
-> delivery rejected

UI audit
-> no Need/Greed/Roll/bidding controls
```

---

# 17. Final Definition of Done

The Loot System is complete when:

- the existing `loot` dataset collection is a functional weighted Loot Table system;
- Loot Tables can contain RPE items and currencies with relative weights and quantity ranges;
- direct item/currency rewards use the same concrete reward contract;
- Personal and Group behavior matches the PDD exactly;
- Group rewards have exactly one recipient per concrete stack;
- Event-end and ad-hoc distribution share one host execution service;
- recipient clients validate host authority and apply through existing Inventory/Currency APIs;
- delivery retries cannot duplicate successfully applied loot;
- interrupted delivery cannot blindly reapply after reload;
- Event-end delivery remains valid across local Event teardown ordering;
- Event Manager supports ad-hoc target subsets;
- host can see assigned vs acknowledged/failed delivery results;
- dataset dependency discovery/rewrite understands Loot references;
- existing `lootRefs` data is preserved/migrated safely;
- no player loot-roll system exists.
