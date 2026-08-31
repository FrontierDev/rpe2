# RPE 2 — Loot System
## Product Design Document

**Status:** Proposed  
**Target:** RPEngine 2.0 (`FrontierDev/rpe2`)  
**Scope:** Reusable loot tables, direct loot, item/currency rewards, group/personal distribution, event-end rewards, ad-hoc host distribution, reliable recipient delivery  
**Primary objective:** Provide one composable loot pipeline that can resolve either authored loot tables or explicit rewards and distribute the resulting RPE items/currencies to event participants without introducing a player loot-rolling system  
**Explicitly out of scope:** Need/Greed, player loot rolls, master-looter bidding, loot voting, trade windows, corpse/chest looting, world drops, offline mail, arbitrary non-item/non-currency rewards

---

# 1. Purpose

RPE needs a loot system that supports two different ways of producing rewards:

1. **Loot tables** — reusable dataset objects containing weighted item/currency entries with variable quantities.
2. **Direct loot** — an explicitly selected item or currency awarded without random table resolution.

The same produced loot must then support two different distribution models:

1. **Personal loot** — each eligible player receives loot independently of what any other player receives.
2. **Group loot** — each produced reward can be awarded to only one eligible player.

Finally, loot must be distributable at two different times:

1. **End of event** — configured as part of the event and resolved when the host ends it.
2. **Ad hoc** — triggered by the event host on demand during an active event, using either direct loot or a loot table and either all participants or a selected subset.

These are independent dimensions and must not become separate implementations.

Canonical model:

```text
Loot Source
  ├─ Direct reward
  └─ Loot table
        ↓
Resolve concrete reward stack(s)
        ↓
Eligible players
        ↓
Distribution mode
  ├─ Personal
  └─ Group
        ↓
Recipient assignment
        ↓
Reliable per-recipient delivery
        ↓
Existing Inventory / Currency APIs
```

The system must not implement any form of player-controlled rolling for loot.

---

# 2. Product Terminology

## 2.1 Loot table

A reusable dataset object containing weighted reward entries.

A loot-table entry describes:

- an RPE item or RPE currency;
- a relative weight;
- a minimum quantity;
- a maximum quantity.

A table roll selects one or more entries according to their relative weights and resolves each selected entry into a concrete quantity.

---

## 2.2 Direct loot

A concrete reward selected explicitly by the host or event definition.

Examples:

```text
1 × campaign:blackrock_key
25 × campaign:commendation
500 × copper
```

Direct loot does not perform weighted selection.

---

## 2.3 Concrete reward

The normalized runtime result of either direct loot or a loot-table roll.

```lua
{
    type = "item",
    ref = "campaign:blackrock_key",
    amount = 1,
}
```

or:

```lua
{
    type = "currency",
    ref = "campaign:commendation",
    amount = 25,
}
```

Distribution operates only on concrete rewards. It does not need to know how those rewards were produced.

---

## 2.4 Eligible players

The set of event participants who may receive a particular loot grant.

Eligibility and distribution mode are separate concerns.

For example:

```text
Eligible players: A, B, C
Distribution: Group
```

means that each produced reward is assigned to exactly one of A/B/C.

Whereas:

```text
Eligible players: A, B, C
Distribution: Personal
```

means that A, B and C each resolve/receive their own loot independently.

---

## 2.5 Loot grant

A runtime or authored instruction which combines:

- loot source;
- distribution mode;
- eligible-target policy.

A `LootGrant` is not itself the reward. It is the instruction used to produce and distribute rewards.

---

# 3. Existing RPE Architecture

## 3.1 RPE already has a Loot dataset collection

`core/internal/database/Database.lua` currently registers:

```lua
loot = { className = "Loot", singular = "Loot", assignsId = true }
```

and RPE already defines:

```text
core/classes/Loot.lua
```

The current `Loot` object contains:

```lua
Loot {
    id
    name
    description
    items
    conditions
    tags
}
```

Therefore this design should **evolve the existing `Loot` dataset object into the reusable loot-table definition** rather than add a parallel `LootTable` collection.

The underlying collection may remain named:

```text
loot
```

for schema and compatibility purposes while the Data Editor and user-facing terminology call these objects:

```text
Loot Tables
```

---

## 3.2 Items already have a canonical award path

RPE character inventory is managed through the existing Inventory service.

Loot item delivery must use:

```lua
Addon.Client.Inventory.AddItem(...)
```

rather than writing directly to inventory SavedVariables.

This preserves existing item-reference, stacking, modification and bind behavior.

---

## 3.3 Currencies already have a canonical award path

RPE supports both built-in and dataset currencies through the Profile currency APIs.

Loot currency delivery must resolve references through the existing currency system and award through:

```lua
Profile.AddCurrencyAmount(currencyRef, amount)
```

This preserves:

- built-in currencies such as `copper`;
- dataset-qualified currencies such as `campaign:commendation`;
- configured currency caps;
- existing currency-driven Achievement triggers.

If a currency cap prevents the full amount being added, the loot delivery result should report the actual amount applied rather than treating the request as if the full amount was granted.

---

## 3.4 Achievement rewards already provide transaction precedent

`client/client_AchievementRewards.lua` already validates and applies item/currency reward records and contains transaction/rollback handling around existing Inventory and Profile APIs.

Loot should follow the same low-level reward semantics:

```text
item     -> Registry item reference -> Inventory.AddItem()
currency -> currency reference      -> Profile.AddCurrencyAmount()
```

Loot must not call Achievement completion/reward APIs directly, because Achievement reward state and loot delivery state are different product concepts.

Implementation may extract generic reward-validation/application helpers if that can be done without expanding the loot task into an Achievement-system rewrite. Reusing existing low-level award paths is required; refactoring Achievement rewards is not.

---

## 3.5 Loot awarded to another player must be delivered to that player's client

Another player's Profile and Inventory SavedVariables exist on that player's WoW client.

The event host cannot directly mutate them.

Therefore multiplayer loot distribution must use the existing RPE Comms layer:

```text
Host resolves loot
        ↓
Host selects recipient(s)
        ↓
Targeted RPE addon message
        ↓
Recipient validates request
        ↓
Recipient applies local reward
        ↓
Recipient acknowledges result
```

The current operation table already contains event, combat and guild-admin request/response operations. Loot should extend this same system using the next available operation IDs at implementation time rather than introducing a new addon prefix or messaging layer.

---

# 4. Core Product Principles

## 4.1 Source, eligibility, distribution and timing are independent

The system must not encode combinations such as:

```text
PersonalEventLootTable
GroupDirectLoot
AdHocPersonalLoot
```

as separate object types.

Instead:

```text
Source       = DIRECT | TABLE
Eligibility  = participant set
Distribution = PERSONAL | GROUP
Timing       = EVENT_END | AD_HOC
```

Timing is the caller of the loot pipeline, not a property that changes how rewards are resolved.

---

## 4.2 Direct loot and table loot converge to one reward format

Both source types must produce the same normalized concrete reward records before distribution.

```text
Direct item
        ┐
Direct currency
        ├──> ConcreteReward[]
Loot table
        ┘
```

This prevents item/currency award logic from being duplicated between direct and random loot.

---

## 4.3 Personal loot is independently resolved per player

For a loot-table grant using Personal distribution, every eligible player performs an independent conceptual table roll.

Example:

```text
Loot table: Blackrock Cache
Eligible: A, B, C
Distribution: Personal
```

may resolve as:

```text
A -> 1 × Sword
B -> 25 × Gold
C -> 2 × Potion
```

Player A's result does not consume, replace or otherwise affect B or C's result.

For direct personal loot, the concrete reward is copied to every eligible player:

```text
Direct: 5 × campaign:commendation
Eligible: A, B, C
Distribution: Personal
```

becomes:

```text
A -> 5 × campaign:commendation
B -> 5 × campaign:commendation
C -> 5 × campaign:commendation
```

---

## 4.4 Group loot is resolved once

For a loot-table grant using Group distribution, the table is resolved exactly once for the eligible group.

Each resulting concrete reward stack is then assigned to exactly one randomly selected eligible player.

Example:

```text
Resolved table:
1 × Sword
3 × Potion
20 × Gold
```

may become:

```text
Sword      -> Player B
3 Potions  -> Player A
20 Gold    -> Player C
```

A stack remains atomic for recipient assignment.

`3 × Potion` is one reward stack and is not automatically divided into three one-item awards.

---

## 4.5 No player loot rolls

There is no Need/Greed stage and no player prompt deciding the owner.

For Group distribution:

```text
host resolves reward
        ↓
system randomly selects one eligible recipient
        ↓
reward is delivered
```

This is the complete ownership rule for the initial system.

---

## 4.6 The host is authoritative for loot resolution

Only the active event host may initiate event loot distribution.

The host determines:

- which loot grant is being executed;
- which players are eligible;
- table random results;
- group-recipient assignment;
- unique delivery IDs.

Recipients apply only the already-resolved concrete reward assigned to them.

Recipients must not reroll tables locally. Otherwise clients could resolve different outcomes.

---

## 4.7 Delivery must be idempotent

A lost acknowledgement must not create duplicate loot when the host retries delivery.

Every per-recipient delivery therefore needs a stable unique `deliveryId`.

The same `deliveryId` retried to the same player must return the previous result without applying the reward again.

---

# 5. Loot Table Data Model

## 5.1 Evolve the existing Loot class

Proposed normalized model:

```lua
Loot {
    id = nil,
    name = "",
    description = "",

    drawCount = 1,

    entries = {
        ...
    },

    conditions = {},
    tags = {},
}
```

User-facing name:

```text
Loot Table
```

Dataset collection:

```text
loot
```

Existing `conditions` and `tags` remain valid class-level metadata unless implementation review finds they are unused/dead and should be handled separately.

---

## 5.2 Loot table entry

```lua
{
    id = "blackrock_sword",
    type = "item",
    ref = "campaign:blackrock_sword",
    weight = 10,
    minQuantity = 1,
    maxQuantity = 1,
}
```

Currency example:

```lua
{
    id = "commendations",
    type = "currency",
    ref = "campaign:commendation",
    weight = 40,
    minQuantity = 2,
    maxQuantity = 5,
}
```

Supported `type` values in the initial system:

```text
item
currency
```

Unsupported reward types must fail validation at authoring/runtime boundaries rather than being silently ignored.

---

## 5.3 Stable entry IDs

Every entry should have a stable ID.

The ID is useful for:

- editor identity;
- deterministic test fixtures;
- diagnostics;
- future analytics/debug output;
- avoiding dependence on array positions.

Entry order may change without changing entry identity.

---

## 5.4 Relative weights

Weights are relative values, not percentages.

Example:

```text
Sword       10
Potion      40
Gold        50
```

has the same probabilities as:

```text
Sword        1
Potion       4
Gold         5
```

The Data Editor must not require weights to total 100.

Rules:

```text
weight > 0
```

Entries with zero/negative/invalid weight are invalid and must not participate in resolution.

---

## 5.5 Quantity range

Each selected entry rolls an integer amount inclusively between:

```text
minQuantity
maxQuantity
```

Validation:

```text
minQuantity >= 1
maxQuantity >= minQuantity
```

A fixed quantity is represented as:

```text
minQuantity = maxQuantity
```

---

## 5.6 Draw count

A loot table controls how many weighted selections occur per table roll:

```lua
drawCount = 1
```

Example:

```text
drawCount = 3
```

means that resolving the table produces three selected entries before any optional normalization/stack combining.

Initial semantics:

- each draw uses the complete valid weighted-entry set;
- draws are independent;
- the same entry may therefore be selected more than once;
- identical resulting reward refs/types should be combined into one concrete reward stack where safe.

Example:

```text
Draw 1 -> Potion ×2
Draw 2 -> Sword ×1
Draw 3 -> Potion ×3
```

normalizes to:

```text
Potion ×5
Sword ×1
```

This keeps distribution stack-based and avoids needless duplicate delivery records.

---

# 6. Compatibility With the Existing Loot Schema

The existing `Loot` class currently stores:

```lua
items = {}
```

The implementation must inspect whether any shipped/user datasets currently rely on this field before finalizing migration.

Preferred normalized direction:

```text
legacy items[]
    ↓ normalization/migration
entries[]
```

If legacy `items` already contains meaningful authored data, migration must preserve it rather than dropping it.

A dataset schema increment is appropriate if persisted serialized shape changes.

The implementation plan should determine the exact legacy item record shape before specifying the conversion algorithm.

---

# 7. Concrete Reward Model

Once a source is resolved, distribution receives records shaped conceptually as:

```lua
{
    type = "item",
    ref = "campaign:blackrock_sword",
    amount = 1,
}
```

or:

```lua
{
    type = "currency",
    ref = "copper",
    amount = 500,
}
```

Required invariants:

```text
type is supported
ref resolves
amount is a positive integer
```

A direct reward is already concrete.

A loot-table entry becomes concrete after weighted selection and quantity resolution.

---

# 8. Loot Grant Model

Conceptual source model:

```lua
{
    source = {
        type = "direct",
        reward = {
            type = "item",
            ref = "campaign:blackrock_key",
            amount = 1,
        },
    },

    distribution = "group",

    targetPolicy = "all-participants",
}
```

Loot-table source:

```lua
{
    source = {
        type = "table",
        lootRef = "campaign:blackrock_cache",
    },

    distribution = "personal",

    targetPolicy = "all-participants",
}
```

For ad-hoc runtime grants the eligible target list can instead be supplied explicitly after the host chooses players in the UI.

---

# 9. Eligible Target Rules

## 9.1 Event-end grants

Authored event-end loot cannot sensibly store concrete player names because the participants are not known when the event is authored.

Initial event-end target policy:

```text
all event participants
```

The distribution mode then decides whether that participant set is Personal or Group loot.

Example:

```text
Event-end direct reward: 5 Commendations
Distribution: Personal
```

means every participant receives 5 Commendations.

Example:

```text
Event-end table: Boss Cache
Distribution: Group
```

means the table is rolled once and each produced stack is assigned to one event participant.

Team-based or role-based authored eligibility can be added later if required; it is not part of the initial system.

---

## 9.2 Ad-hoc grants

The Event Manager must allow the host to choose:

```text
All participants
```

or an explicit subset such as:

```text
[x] Player A
[ ] Player B
[x] Player C
```

That selected set becomes the eligible-player list.

The same subset-selection UI works for both Personal and Group distribution.

---

## 9.3 Empty eligible set

A grant with no eligible players must not roll a table or consume any state.

It should fail before resolution with a clear host-facing reason:

```text
No eligible loot recipients.
```

---

# 10. Personal Distribution Semantics

## 10.1 Direct + Personal

Resolve once because the source is already concrete, then clone the reward assignment to every eligible player.

```text
Direct reward: Potion ×2
Eligible: A, B, C
```

assigns:

```text
A -> Potion ×2
B -> Potion ×2
C -> Potion ×2
```

---

## 10.2 Loot Table + Personal

Resolve the table independently once per eligible player.

Pseudo-flow:

```text
for each eligible player:
    rewards = ResolveLootTable(table)
    assign all rewards to that player
```

All random resolution occurs on the host.

The recipient receives only the resulting concrete rewards.

---

# 11. Group Distribution Semantics

## 11.1 Direct + Group

A direct reward is one concrete stack.

The system randomly selects one eligible player and assigns the stack to that player.

```text
Direct reward: Sword ×1
Eligible: A, B, C
```

may produce:

```text
B -> Sword ×1
```

---

## 11.2 Loot Table + Group

Resolve the table once.

For each resulting normalized concrete reward stack:

```text
recipient = random eligible player
```

Different stacks can go to different players.

Example:

```text
Table result:
Sword ×1
Potion ×3
Gold ×20
```

may assign:

```text
A -> Potion ×3
B -> Sword ×1
C -> Gold ×20
```

There is no requirement to balance the number or value of rewards across recipients.

Random assignment is independent per concrete reward stack.

---

# 12. Event-End Loot

## 12.1 Event data

Extend the Event definition with an authored ordered collection such as:

```lua
endLoot = {
    ...LootGrant definitions...
}
```

The exact field name can follow existing Event serialization conventions, but it must represent **event-end grants**, not arbitrary runtime loot history.

Example:

```lua
endLoot = {
    {
        source = {
            type = "table",
            lootRef = "campaign:blackrock_boss",
        },
        distribution = "group",
        targetPolicy = "all-participants",
    },
    {
        source = {
            type = "direct",
            reward = {
                type = "currency",
                ref = "campaign:commendation",
                amount = 5,
            },
        },
        distribution = "personal",
        targetPolicy = "all-participants",
    },
}
```

Meaning:

```text
Roll Blackrock Boss loot once for the group.
Every participant also receives 5 Commendations.
```

---

## 12.2 Event-end ordering

When the host ends an event:

```text
Capture final participant set
        ↓
Resolve configured endLoot grants
        ↓
Resolve recipients
        ↓
Dispatch per-recipient deliveries
        ↓
End event lifecycle continues
```

The implementation must trace the current event-end call path before choosing the exact hook.

Loot resolution must happen while the host still has authoritative access to the event/session participant state required to validate recipients.

The design does not require that every recipient acknowledgement block the entire event UI from closing. Delivery state may complete immediately around the event-end transition as long as host-side dispatch and recipient validation retain enough session identity to finish safely.

---

## 12.3 End-event idempotency

The same event-end action must not produce duplicate rewards if the host-side end path is invoked twice accidentally or a delivery is retried.

Each configured grant execution therefore needs a stable execution identity for that event session.

Conceptually:

```text
eventSessionId + endLootIndex
```

can identify one source resolution, while each recipient delivery additionally receives its own unique `deliveryId`.

---

# 13. Ad-Hoc Loot

Ad-hoc loot belongs in the Event Manager host tooling.

It should use the same distribution pipeline as event-end loot.

The Event Manager provides two source modes:

```text
Direct Loot
Loot Table
```

Direct fields:

```text
Reward Type: Item | Currency
Reward:      [selector]
Quantity:    [number]
```

Loot-table fields:

```text
Loot Table:  [selector]
```

Common fields:

```text
Distribution:
  ( ) Group
  ( ) Personal

Targets:
  ( ) All participants
  ( ) Selected participants

  [x] Player A
  [x] Player B
  [ ] Player C

[ Distribute Loot ]
```

The action must clearly preview what the selected combination means.

Examples:

```text
Personal: every selected player receives direct loot or an independent table roll.
Group: loot is resolved once and each reward is assigned to one selected player.
```

---

# 14. Event Manager Placement

The current Event Manager Actions work already groups host-driven direct gameplay operations such as damage/healing, aura changes and requested skill rolls.

Loot distribution is also an ad-hoc host action and should be surfaced in that same host-oriented Event Manager area unless the final implementation finds that the page has become too dense.

Recommended section:

```text
Loot
```

with source/distribution/target controls as described above.

Do not create a separate loot window solely for ad-hoc event distribution in the initial implementation.

---

# 15. Loot Table Authoring UI

The Data Editor should present the existing `loot` collection as:

```text
Loot Tables
```

A Loot Table inspector/page should support:

```text
General
  Name
  Description
  Draw Count
  Tags

Entries
  Add Entry

  Entry
    ID
    Type: Item | Currency
    Item/Currency Reference
    Weight
    Minimum Quantity
    Maximum Quantity

Conditions
  Existing condition authoring, if still applicable
```

The selector must change based on entry type:

```text
Item     -> item reference selector
Currency -> built-in + dataset currency selector
```

Authoring validation should make invalid table state visible before runtime use.

---

# 16. Event Authoring UI

The Event editor/settings surface should add an:

```text
End of Event Loot
```

collection.

Each row/card should support:

```text
Source
  Direct Loot | Loot Table

Direct reward fields OR Loot Table selector

Distribution
  Group | Personal
```

The initial event-end target policy is always all participants, so there is no need to expose a meaningless static player-name selector in the Dataset editor.

Example presentation:

```text
END OF EVENT LOOT

1. [Blackrock Boss Cache]
   Loot Table
   Group

2. [Guild Commendation] ×5
   Direct Currency
   Personal

[ + Add Reward ]
```

---

# 17. Host-Side Resolution Service

Introduce one authoritative loot service, conceptually:

```lua
Addon.Server.Loot
```

or an equivalent location consistent with current server/client responsibility boundaries.

Responsibilities:

```text
Resolve loot references
Validate source definitions
Resolve weighted tables
Resolve quantity ranges
Normalize/merge concrete rewards
Validate eligible participants
Resolve Personal/Group assignments
Create delivery IDs
Dispatch recipient messages
Track acknowledgements/results
Provide host-facing result summaries
```

Conceptual API:

```lua
Loot:ExecuteGrant(grant, eligiblePlayers, context)
```

where `context` includes event/session/host information needed for validation and idempotency.

Event-end and ad-hoc callers both call this service.

---

# 18. Deterministic Logic Boundaries

Random resolution should be isolated into pure functions wherever practical.

Examples:

```lua
ResolveWeightedEntry(entries, randomValue)
ResolveQuantity(minQuantity, maxQuantity, randomValue)
ResolveLootTable(table, rng)
AssignGroupRecipients(rewards, eligiblePlayers, rng)
```

This allows deterministic tests with injected/mocked RNG values.

Required deterministic tests include:

```text
weight boundaries select the expected entry;
invalid weights are rejected;
quantity min/max are inclusive;
drawCount produces the correct number of draws;
duplicate reward refs normalize correctly;
personal table loot resolves once per player;
group table loot resolves only once;
each group reward stack gets exactly one recipient;
direct personal loot reaches every eligible player;
direct group loot reaches exactly one eligible player;
empty eligibility fails before resolution.
```

---

# 19. Network Delivery Model

## 19.1 Proposed operations

Extend `core/internal/comms/Operations.lua` using the next available opcodes at implementation time.

Conceptually:

```text
LOOT_DELIVERY
LOOT_DELIVERY_RESPONSE
```

A separate table-roll network operation is unnecessary because table resolution occurs only on the host.

---

## 19.2 Delivery payload

Conceptual payload:

```lua
{
    protocolVersion = 1,
    deliveryId = "...",
    eventSessionId = "...",
    grantId = "...",

    rewards = {
        {
            type = "item",
            ref = "campaign:blackrock_sword",
            amount = 1,
        },
        {
            type = "currency",
            ref = "campaign:commendation",
            amount = 5,
        },
    },
}
```

The host should batch all rewards assigned to the same recipient from one logical grant into one delivery where practical.

This reduces addon-message overhead and gives the recipient one transaction boundary.

---

## 19.3 Sender identity

Recipient validation must use the sender identity supplied by the addon-message transport.

The payload must not be trusted if it contains a claimed:

```lua
host = "SomePlayer"
```

field.

The recipient compares the actual message sender with the authoritative host recorded for the relevant active/recent event session.

---

# 20. Recipient-Side Validation

Before applying loot, the recipient must verify:

```text
message sender is the relevant RPE event host;
protocol version is supported;
deliveryId is valid;
event/session identity is relevant;
this client is the intended recipient;
all reward types are supported;
all reward references resolve;
all reward amounts are positive integers.
```

If any required reward definition is invalid, the delivery should fail cleanly rather than partially applying an unvalidated payload.

The recipient should return an explicit reason code.

Examples:

```text
invalid-sender
unknown-event-session
invalid-delivery-id
unsupported-protocol
invalid-reward
unknown-item
unknown-currency
reward-application-failed
```

---

# 21. Recipient Transaction Semantics

A per-recipient delivery may contain multiple concrete rewards.

The recipient should treat that delivery as one transaction as far as practical:

```text
validate every reward
        ↓
capture required item/currency state
        ↓
apply rewards
        ↓
verify actual application
        ↓
record delivery receipt
        ↓
acknowledge success
```

If a failure occurs after partial application, rollback should restore earlier rewards where existing APIs make this safely possible.

The Achievement reward implementation provides precedent for inventory/currency snapshots and rollback.

Loot should not knowingly leave a player with an undocumented partial grant while reporting total failure.

---

# 22. Delivery Receipt / Duplicate Protection

Add a small Profile-owned loot receipt state, conceptually:

```lua
profile.loot = {
    receipts = {
        [deliveryId] = {
            status = "complete",
            completedAt = 1788200000,
            result = {
                ...
            },
        },
    },
}
```

Purpose:

```text
host sends delivery
recipient applies rewards
ack is lost
host retries same deliveryId
recipient sees receipt
recipient does not apply again
recipient returns previous acknowledgement
```

The receipt ledger must be bounded/pruned so ad-hoc events cannot grow Profile state forever.

Implementation may use either:

- a fixed recent-entry limit; or
- an age-based retention window plus a maximum cap.

Exact retention is an implementation choice, but unbounded storage is not acceptable.

---

# 23. Delivery Response

Success response:

```lua
{
    protocolVersion = 1,
    deliveryId = "...",
    success = true,
    rewards = {
        {
            type = "currency",
            ref = "campaign:commendation",
            requestedAmount = 5,
            appliedAmount = 5,
        },
    },
}
```

Currency-cap example:

```lua
{
    success = true,
    rewards = {
        {
            type = "currency",
            ref = "campaign:commendation",
            requestedAmount = 5,
            appliedAmount = 2,
            reason = "currency-capped",
        },
    },
}
```

Failure response:

```lua
{
    protocolVersion = 1,
    deliveryId = "...",
    success = false,
    reason = "unknown-item",
}
```

The host UI must distinguish assigned loot from acknowledged delivery.

---

# 24. Host-Facing Result Summary

After a grant is resolved, the host should be able to see what happened.

Example:

```text
Loot distributed:
Player A received [Blackrock Sword].
Player B received 5 [Guild Commendations].
Player C received 3 [Healing Potions].
```

If delivery fails:

```text
Player B could not receive [Blackrock Sword]: item unavailable.
```

For Personal loot:

```text
Player A received [Blackrock Sword].
Player B received 25 Copper.
Player C received 2 [Healing Potions].
```

This is a host result surface, not a player loot-roll interface.

---

# 25. Recipient Feedback

A recipient should receive clear confirmation when loot is successfully applied.

The existing event widget ticker/combat-log conventions can be reused where appropriate, but loot should not flood combat-only logs with low-value implementation details.

Minimum user-facing feedback:

```text
You received [Blackrock Sword].
You received 5 [Guild Commendations].
```

The implementation plan should inspect the current Event Widget / Combat Log ownership before choosing the exact presentation path.

---

# 26. Randomness and Fairness

The initial system requires random weighted table resolution and random Group recipient assignment.

It does **not** require:

```text
bad-luck protection;
round-robin ownership;
value balancing;
prior-loot weighting;
class/spec eligibility;
Need/Greed preference;
player-selected priority.
```

Every eligible Group recipient has equal selection weight for each concrete reward stack.

Loot-table entry probability is determined only by entry weights.

---

# 27. Dataset Dependencies

Loot tables introduce dataset references which must participate in dependency extraction and rewrite/pruning logic.

Dependency analysis must inspect:

```text
Loot entry item refs
Loot entry currency refs
```

Event definitions must also expose dependencies for:

```text
end-loot Loot refs
end-loot direct item refs
end-loot direct currency refs
```

This is required so dataset activation/import/export remains correct when an Event or Loot Table references content from another dataset.

The implementation must update every relevant dependency discovery and reference rewrite/pruning path, not only the primary scanner.

---

# 28. Registry Additions

The Registry should provide a canonical resolver for Loot references consistent with other dataset-qualified references.

Conceptually:

```lua
Registry:ResolveLootReference(lootRef)
```

with:

```text
datasetId:lootId
```

references.

Callers should not repeatedly hand-parse loot references.

Item and currency references continue to use their existing resolvers/APIs.

---

# 29. Conditions

The existing Loot class already contains:

```lua
conditions = {}
```

This PDD does not introduce new condition semantics beyond what the current class already claims to support.

Before implementation, trace whether Loot conditions are currently authored or evaluated anywhere.

If existing Condition infrastructure can meaningfully evaluate Loot Table eligibility using available event/player context, it may remain supported.

Do not invent a second loot-specific condition language.

If the field is currently dead/unimplemented, that should be documented during implementation planning rather than silently assigning new semantics to it.

---

# 30. Failure Handling

## 30.1 Invalid Loot Table

A table with no valid weighted entries cannot resolve.

Host-facing error:

```text
Loot table contains no valid entries.
```

No recipient assignment occurs.

---

## 30.2 Missing referenced dataset content

If a table/direct reward references a missing item/currency, grant execution fails before delivery.

Do not randomly skip the invalid entry and alter authored probabilities without warning.

---

## 30.3 Recipient unavailable

If a selected recipient is no longer reachable, the host should report the delivery as failed/unacknowledged.

The initial system does not reroll Group loot to another player automatically after recipient assignment, because that would change the authoritative resolved result after the fact and could duplicate loot if the original delivery actually succeeded but its acknowledgement was lost.

The host may retry the same delivery ID.

Offline mail/storage is out of scope.

---

## 30.4 Partial currency cap

A currency cap may cause:

```text
requestedAmount > appliedAmount
```

This is still a successful delivery if the existing currency system correctly applied the maximum possible amount.

The acknowledgement must record the actual amount.

---

# 31. Security / Trust Boundary

RPE SavedVariables remain player-controlled and the system is not cryptographically secure.

Within the addon trust model, however, loot messages must still enforce normal authoritative boundaries.

Recipient must not accept arbitrary loot messages from any addon user.

At minimum:

```text
actual transport sender must be the event host;
event/session identity must be relevant;
reward definitions must validate locally;
delivery IDs must be duplicate-protected.
```

The host remains authoritative for random results.

---

# 32. Proposed Module Responsibilities

Exact file placement should follow the codebase at implementation time, but responsibilities should remain separated conceptually.

```text
core/
  classes/
    Loot.lua                         [modify: loot-table schema]
    Event.lua                        [modify: end-of-event grants]

  internal/
    database/
      Database.lua                   [dataset/profile schema if required]
      Dependecies.lua                [loot/event reference support]

    Registry.lua                     [Loot reference resolver]
    comms/
      Operations.lua                 [loot delivery operations]

client/
  client_Loot.lua                    [recipient validation/application]

server/
  server_Loot.lua                    [host resolution/distribution]
  server_Event.lua                   [event-end integration]

server/ui/eventmanage/
  ...                                [ad-hoc Loot section]

client/ui/editor/
  ...                                [Loot Table + Event end-loot authoring]
```

Do not treat this list as permission to create parallel services if equivalent current modules already own the relevant responsibility when implementation begins.

---

# 33. Core Runtime Flow — Direct Personal Loot

```text
Host chooses direct reward
        ↓
Host chooses Personal
        ↓
Host chooses eligible players A/B/C
        ↓
Validate reward reference/amount
        ↓
Create assignments:
  A -> reward
  B -> reward
  C -> reward
        ↓
Create unique delivery per recipient
        ↓
Send targeted messages
        ↓
Each client validates + applies locally
        ↓
Each client records receipt + acknowledges
        ↓
Host presents result summary
```

---

# 34. Core Runtime Flow — Direct Group Loot

```text
Host chooses direct reward
        ↓
Host chooses Group
        ↓
Host chooses eligible players A/B/C
        ↓
Validate reward
        ↓
Randomly select one recipient
        ↓
Send one delivery
        ↓
Recipient validates + applies
        ↓
Recipient acknowledges
        ↓
Host presents recipient/result
```

---

# 35. Core Runtime Flow — Table Personal Loot

```text
Host chooses Loot Table
        ↓
Host chooses Personal
        ↓
Host chooses eligible players A/B/C
        ↓
Validate table
        ↓
Roll table independently for A
Roll table independently for B
Roll table independently for C
        ↓
Normalize each player's rewards
        ↓
Send one delivery batch per player
        ↓
Recipients apply + acknowledge
```

---

# 36. Core Runtime Flow — Table Group Loot

```text
Host chooses Loot Table
        ↓
Host chooses Group
        ↓
Host chooses eligible players A/B/C
        ↓
Validate table
        ↓
Roll table once
        ↓
Normalize concrete reward stacks
        ↓
For each stack:
  randomly choose A/B/C
        ↓
Group stacks by recipient
        ↓
Send one delivery batch per recipient
        ↓
Recipients apply + acknowledge
```

---

# 37. Acceptance Criteria — Data Model

The loot data layer is complete when:

```text
The existing loot dataset collection is represented to users as Loot Tables.

A Loot Table can contain RPE item and RPE currency entries.

Every entry has a stable ID, positive weight and valid quantity range.

Relative weights do not need to total 100.

A table can configure more than one weighted draw.

Loot references use dataset-qualified references.

Loot item/currency references participate in dataset dependency analysis.

Event-end Loot Table/direct reward references participate in dependency analysis.

Existing serialized Loot data is migrated or normalized without silent data loss.
```

---

# 38. Acceptance Criteria — Resolution

```text
Direct loot does not perform random table resolution.

A Loot Table produces the configured number of weighted draws.

Quantity rolls are integer and inclusive of min/max.

Personal Loot Table distribution rolls independently for every eligible player.

Group Loot Table distribution rolls the table exactly once.

Direct Personal loot assigns the reward to every eligible player.

Direct Group loot assigns the reward to exactly one eligible player.

Every Group concrete reward stack has exactly one recipient.

One reward stack is not automatically split between recipients.

No Need/Greed or other player loot roll occurs.
```

---

# 39. Acceptance Criteria — Event Integration

```text
An Event can author one or more end-of-event Loot Grants.

Event-end grants use all event participants as the initial eligible set.

Ending an event executes each configured grant once per event session.

The Event Manager can distribute Direct loot ad hoc.

The Event Manager can distribute a Loot Table ad hoc.

The Event Manager can select Group or Personal distribution.

The Event Manager can target all participants or a selected subset.

Ad-hoc and event-end loot use the same underlying execution pipeline.
```

---

# 40. Acceptance Criteria — Delivery

```text
The host resolves all random loot results and Group recipients.

Recipients never reroll a Loot Table locally.

Items are awarded through the existing Inventory API.

Currencies are awarded through existing Profile currency APIs.

The recipient verifies that the network sender is the relevant event host.

Every per-recipient delivery has a stable unique delivery ID.

Retrying the same delivery ID does not duplicate loot.

Recipients acknowledge success/failure.

Currency acknowledgements include actual amount applied when capped.

A multi-reward delivery does not knowingly report total failure after leaving untracked partial rewards.

Receipt history is bounded/pruned.
```

---

# 41. Acceptance Criteria — Deterministic Tests

Pure logic must be testable without a live WoW group.

At minimum exercise deterministic cases for:

```text
weighted selection boundaries;
quantity range boundaries;
duplicate table selections;
concrete reward normalization;
Personal vs Group source-resolution counts;
Group recipient assignment;
subset eligibility;
empty eligibility;
invalid entry definitions;
missing references;
delivery duplicate detection;
recipient sender validation;
currency cap acknowledgement;
transaction failure/rollback behavior where applicable.
```

---

# 42. Explicit Non-Goals

This project does not implement:

```text
Need/Greed
player /roll-based loot
master-looter bidding
loot council voting
round-robin loot rules
class/spec restrictions
item-quality-based loot rules
trade windows
corpse/chest interaction
physical world loot objects
offline loot delivery/mail
Blizzard inventory items
Blizzard currencies
arbitrary Lua reward effects
XP/skill/achievement rewards through the loot table
quest reward systems
bad-luck protection
cross-event loot balancing
```

The initial reward types are deliberately limited to:

```text
RPE Item
RPE Currency
```

---

# 43. Principal Architectural Decisions

**The existing `Loot` dataset object becomes the reusable Loot Table model; do not create a parallel LootTable collection.**

**Direct loot is an inline concrete reward source, not another reusable dataset object.**

**Both Direct and Loot Table sources normalize to the same concrete item/currency reward representation.**

**Eligible targets and distribution mode are separate.**

**Personal loot is independent per eligible player.**

**Group loot resolves once and each concrete reward stack is assigned to exactly one random eligible player.**

**There is no Need/Greed or player loot-rolling phase.**

**Event-end and ad-hoc loot call one shared loot execution pipeline.**

**Event-end loot initially targets all event participants; ad-hoc loot may target all participants or an explicit subset.**

**The event host is authoritative for table rolls and Group recipient assignment.**

**Recipients receive only already-resolved concrete rewards and never reroll tables locally.**

**Items are granted through `Client.Inventory.AddItem()`.**

**Currencies are granted through `Profile.AddCurrencyAmount()`.**

**Multiplayer delivery extends the existing RPE Comms operation system.**

**Every delivery is idempotent through a stable delivery ID and bounded recipient receipt history.**

**Loot dependency references participate in the existing dataset dependency system.**

**Random resolution and recipient assignment are isolated behind deterministic-testable logic.**
