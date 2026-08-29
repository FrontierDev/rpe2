## Goal

Add a Ruleset -> Resources option that enables or disables automatic resource regeneration at the start of a unit's turn.

Required default:

```text
Enable Resource Regeneration Per Turn = true
```

Existing rulesets must therefore retain the current regeneration behavior unless explicitly disabled.

## Current-code investigation / root cause

### Resource definitions already own regeneration formulas

`core/classes/Resource.lua` currently stores authored regeneration configuration such as:

```lua
regenMode
regenPerSecond
regenSourceStatRef
regenMultiplier
```

This issue must not change those Resource definition fields or their formula semantics.

### Turn regeneration is already centralized

`client/client_Resources.lua` owns the current turn-regeneration application path.

The client tracks:

```lua
Client.LastAppliedTurnRegenKey
```

and builds a key from:

```text
eventState.id
turnNumber
activeEventId
```

so the same actor's regeneration is not applied repeatedly for one turn occurrence.

When the turn is eligible, the code calls:

```lua
ResourceSync.BuildPlayerTurnRegenResourceDeltas(activeEventUnit.resources, ...)
```

and queues the result as:

```text
reason = "turn-regen"
scope  = "turn"
```

through the normal resource-delta path.

`core/internal/comms/ResourceSync.lua` contains the actual `BuildPlayerTurnRegenResourceDeltas(...)` formula builder.

There is currently no Ruleset-level switch before this work is generated, so authored resource regeneration always participates in turn processing.

## Required Ruleset addition

Add under the existing `resources` section in `core/internal/ruleset/Rules.lua`:

```lua
{
    key = "enable_resource_regeneration_per_turn",
    label = "Enable Resource Regeneration Per Turn",
    type = "checkbox",
    default = true,
    description = "Automatically apply configured resource regeneration when an eligible unit's turn begins.",
}
```

The exact internal key may follow repository naming conventions, but the default must be `true`.

The normal Ruleset editor should expose the new field through the existing rule-definition-driven UI. Do not add a separate bespoke settings control if the generic Ruleset UI already handles checkbox rules.

## Required runtime behavior

Gate the existing centralized turn-regeneration application path before regeneration deltas are calculated/queued.

Conceptually:

```text
eligible actor turn
-> build event/turn/actor regen key
-> rule enabled?
     yes -> existing BuildPlayerTurnRegenResourceDeltas path
     no  -> no regeneration deltas
-> mark this turn occurrence handled
```

When the rule is disabled:

- do not call/queue automatic turn-regeneration resource deltas;
- do not change the actor's current resources;
- do not alter maximum-resource calculations;
- do not mutate the authored `Resource.regen*` definition fields;
- do not interfere with explicit spell/effect/resource changes;
- do not send a fake zero-delta packet merely to represent disabled regeneration.

The existing `LastAppliedTurnRegenKey` idempotency behavior should remain intact. The disabled path should still mark the current `(event, turn, actor)` occurrence as handled so repeated event-state refreshes do not repeatedly revisit the same turn-regeneration decision.

## Scope of the toggle

This rule controls **automatic per-turn regeneration only**.

It must not disable unrelated resource changes such as:

```text
spell costs;
damage/healing;
resource-gain spell effects;
resource losses;
manual/server resource changes;
resource initialization at Event start;
maximum-resource recalculation.
```

If a resource has no configured regeneration already, behavior remains unchanged regardless of the toggle.

## Primary files

- `core/internal/ruleset/Rules.lua`
- `client/client_Resources.lua`

Supporting code should normally remain unchanged:

- `core/internal/comms/ResourceSync.lua`
- `core/classes/Resource.lua`

Only modify the latter files if a concrete shared helper is required; do not move the regeneration formula merely for this toggle.

## Backward compatibility

No Dataset/Profile schema change should be necessary because this is a Ruleset rule with a default value resolved through the existing Ruleset system.

Legacy rulesets without the new key must resolve it as:

```text
true
```

and therefore behave exactly as before.

## Acceptance criteria

- [ ] Ruleset -> Resources contains an `Enable Resource Regeneration Per Turn` checkbox.
- [ ] The checkbox defaults to `true`.
- [ ] Existing/legacy rulesets without an explicit value continue regenerating resources per turn.
- [ ] When enabled, current regeneration calculations and amounts are unchanged.
- [ ] When disabled, automatic turn regeneration produces no resource delta and no resource-value change.
- [ ] Disabling regeneration does not disable spell/resource effects or resource costs.
- [ ] Disabling regeneration does not alter Resource definition data.
- [ ] The same Event/turn/actor occurrence remains idempotent and cannot repeatedly apply/check regeneration because of repeated state refreshes.
- [ ] Re-enabling the rule affects subsequent eligible turn occurrences without requiring Resource definitions to be edited.
- [ ] No fake network resource packet is emitted for a disabled regeneration occurrence.

## Validation matrix

```text
legacy ruleset; no stored new key
-> regeneration works exactly as today

new ruleset; toggle true
-> resource with fixed regen gains existing expected amount on turn

new ruleset; toggle false
-> same resource gains 0 from automatic turn regeneration

rule false; cast spell that restores resource
-> spell resource gain still applies

rule false; cast spell with resource cost
-> resource cost still applies

rule false; receive damage/healing
-> health/resource changes still apply normally

same turn state delivered/refreshed repeatedly
-> no duplicate regen when enabled
-> no repeated queued work when disabled

advance to next turn with rule true
-> next normal regeneration occurrence is processed once
```

## Constraints

- Do not remove or reinterpret `regenMode`, `regenPerSecond`, `regenSourceStatRef`, or `regenMultiplier`.
- Do not implement this as a per-Resource definition toggle; the requested control is Ruleset-wide under Resources.
- Do not disable all resource mutation when the rule is false.
- Do not introduce a second regeneration calculation path.
- Preserve the existing resource-delta authority/synchronization flow and `LastAppliedTurnRegenKey` guard.

## Coding-agent instructions

Use current `FrontierDev/rpe2` as authoritative. Trace the turn-regeneration call in `client/client_Resources.lua` through `ResourceSync.BuildPlayerTurnRegenResourceDeltas()` before editing. Add the rule at the single highest-level turn-regeneration decision point so all current formulas remain untouched. Report the exact gate location, legacy/default behavior, files changed, and validation results.