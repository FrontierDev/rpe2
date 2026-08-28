## Goal

Handle the remaining aura-progression edge case that was deliberately moved out of #72 after #72 passed in-game validation.

## Problem

Aura progression now uses a stable logical owner-turn cursor (`lastAdvancedOwnerTurnNumber`) rather than the old `totalTicks`-multiplied scalar. That fixes the main progression instability, but a same-step roster/page topology change can still make an aura newly due without triggering aura advancement.

`AuraManager:AdvanceAuraState(...)` normally short-circuits when `turnNumber` and `tickNumber` have not changed. `Client:HandleEventUnitDeltaBatch()` can, however, change roster ordering/page ownership while leaving the current turn/tick unchanged.

Example:

```text
turn 6, tick 1
caster owner is on page 2
lastAdvancedOwnerTurnNumber = 5
EVENT_UNIT_DELTA_BATCH changes roster topology
caster owner moves to page 1
turnNumber remains 6
tickNumber remains 1
```

The turn-6 owner occurrence is now due exactly once, but no aura progression recheck is scheduled. If the next authoritative event state is already turn 7, the turn-6 tick/duration decrement can be skipped.

This is separate from the original #72 regression. #72's in-game validation passed and should remain closed.

## Required fix

Keep the existing owner-turn cursor and normal same-step short-circuit, but add a bounded topology-triggered owner-occurrence recheck.

1. After a changed `EVENT_UNIT_DELTA_BATCH` has been applied, request aura owner-occurrence reconciliation for the current `(turnNumber, tickNumber)`.
2. Implement either a narrow dedicated recheck helper or an explicit `forceTopologyRecheck` mode. Do not globally disable the same-step guard in `AdvanceAuraState(...)`.
3. During the recheck, an aura is due only when:
   - its resolved current owner page is `<= currentTick`; and
   - `lastAdvancedOwnerTurnNumber < currentTurn`.
4. Reuse `pendingAdvancedOwnerTurnNumber` / existing queued-entry protection so repeated topology updates cannot double-tick an aura for the same owner turn.
5. Do not re-upsert, refresh, restack, or reset aura duration/cursor. This is progression reconciliation only.
6. Keep the work bounded/sliceable and consistent with the TaskQueue model already used by aura advancement.

## Primary files

- `client/client_Event.lua`
- `client/spellcasting/AuraManager.lua`

## Acceptance criteria

- [ ] Owner page 2 -> 1 at the same turn/tick causes exactly one current-turn tick/decrement when the owner occurrence becomes due.
- [ ] Page-count shrink that moves the owner earlier causes exactly one due occurrence, not zero or multiple.
- [ ] Owner page 1 -> 2 before the occurrence does not tick early; it waits for page 2.
- [ ] Repeated `EVENT_UNIT_DELTA_BATCH` updates after the recheck do not double-tick the same owner turn.
- [ ] Existing aura duration, stacks, and refresh semantics are unchanged except for the missing progression occurrence being processed.
- [ ] Ordinary turn/tick advancement continues to use the existing fast path and same-step short-circuit.
- [ ] No dependence on mutable `totalTicks` is reintroduced.

## Validation

```text
owner page 2 -> 1, same turn/tick, same totalTicks
-> exactly one current-turn tick/decrement

owner page 2 -> 1 through page-count shrink
-> exactly one current-turn tick/decrement

owner page 1 -> 2 before occurrence
-> no early tick; waits for page 2

repeated unit deltas after recheck
-> no duplicate tick for the same owner turn
```

Reference: this issue is the topology follow-up previously documented in #72.