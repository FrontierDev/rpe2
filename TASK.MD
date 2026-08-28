## Goal

Add an optional Ruleset combat rule that limits each defensive reaction/stat to **one use per Event turn**, while allowing selected defensive stats to bypass that limit and remain unlimited.

Example with the rule enabled:

```text
Dodge  -> usable once this turn
Parry  -> usable once this turn
Block  -> configured bypass -> unlimited this turn
Magic Resistance -> configured bypass -> unlimited this turn
```

The limit is **per defensive action/stat**, not one global defensive reaction total. A character may therefore Dodge once and Parry once in the same turn.

The limit must span the whole Event turn, including all Event ticks/pages within that turn.

## Current-code investigation / root cause

### Ruleset configuration

`core/internal/ruleset/Rules.lua` currently defines defensive configuration under `combat`, including:

```text
complex_defence_stats_melee
complex_defence_stats_ranged
complex_defence_stats_spell
percent_melee_resistance_stat
percent_ranged_resistance_stat
percent_spell_resistance_stat
```

The percent resistance fields are multi-select stat-reference rules and are the current source of reactions such as dodge/parry/block/resist in percent combat.

There is no rule governing how many times one of those defensive actions can be used in a turn.

### Reaction actions are already stat-reference based

`client/combat/Reaction.lua` builds reaction choices in `Combat:BuildReactionActions(entry)`.

Complex and percent reactions are grouped by stat reference. A grouped action is conceptually:

```lua
{
    id = ("%s:%s"):format(resolutionSystem, statRef),
    resolutionSystem = resolutionSystem,
    statRef = statRef,
    enabled = ...,
    allowedAttackTypes = {...},
}
```

This gives the system a stable semantic identity for a defensive reaction without inventing separate hard-coded concepts for Dodge, Parry, Block, etc.

### Player and NPC resolution paths

Player-selected reactions ultimately pass through:

```text
Client:ResolveCombatReactionAction(actionId)
-> Combat:FindReactionAction(...)
-> Combat:ResolveHitCheckOutcome(entry, action)
```

NPC defenders use `Combat:ChooseAutomaticReactionAction(entry)` and then resolve the selected action through the same hit-check outcome machinery.

There is currently no turn-scoped reaction-use ledger in either path, so a configured resistance/defence stat can be selected repeatedly for every incoming attack in the same turn.

## Required Ruleset additions

Add under `combat`:

```lua
{
    key = "limit_defensive_reactions_per_turn",
    label = "Limit Defensive Reactions Per Turn",
    type = "checkbox",
    default = false,
    description = "When enabled, each defensive reaction/stat may be used once per Event turn unless it is configured to bypass the limit.",
}
```

and a multi-select rule such as:

```lua
{
    key = "defensive_reaction_limit_bypass_stats",
    label = "Unlimited Defensive Reactions",
    type = "dropdown",
    default = {},
    multiSelect = true,
    optionsSource = "statReference",
    description = "Defensive stats that remain usable without limit when the per-turn defensive reaction limit is enabled.",
}
```

The exact key name may follow existing naming conventions, but the persisted values must be **stat references**, not display labels.

If practical, filter the bypass dropdown to stats currently configured as complex defence or percent resistance stats. If the generic stat-reference source is retained, invalid/non-defensive selections must simply have no effect.

The bypass selector is ignored when the limit toggle is disabled.

## Required runtime model

Maintain a runtime-only use ledger. Do not persist this state in Profile or Dataset data.

A defensive use must be keyed strongly enough to distinguish:

```text
event
turn
specific defender EventUnit
defensive action/stat
```

Recommended canonical identity:

```text
(eventId, turnNumber, defenderEventId, resolutionSystem, statRef)
```

Equivalent normalized storage is acceptable.

Important: **do not include `tickNumber` as the reset boundary.** RPE Event turns can contain several ticks/pages; one Dodge used on tick/page 1 must remain spent on later ticks/pages of the same turn.

The ledger must be invalidated/cleared when:

```text
the Event ends;
the Event is replaced;
the tracked Event identity changes.
```

Turn rollover may be handled by using `turnNumber` in the key rather than eagerly clearing every previous-turn entry, provided stale entries are bounded/cleaned at normal lifecycle boundaries.

## Availability helper

Centralize the rule in Combat rather than duplicating it in widgets and automatic resolution.

Recommended conceptual helpers:

```lua
Combat:CanUseDefensiveReaction(entry, action)
Combat:ConsumeDefensiveReactionUse(entry, action)
```

or an equivalent API.

`CanUseDefensiveReaction` should return true when any of these apply:

```text
limit rule disabled;
action is Pass/no defence;
action has no meaningful statRef to limit;
statRef is in the bypass list;
this defender has not used this action/stat during the current turn.
```

Otherwise it returns false and, where useful, a reason such as:

```text
used-this-turn
```

## Player reaction UI/enforcement

`Combat:BuildReactionActions(entry)` should mark spent non-bypass actions unavailable so the reaction widget communicates the real state before the user clicks.

However, UI disablement is not authoritative enforcement.

`Client:ResolveCombatReactionAction(actionId)` must independently re-check availability immediately before resolving/consuming the action. A stale/replayed UI action must not bypass the turn limit.

The row/button should expose a useful unavailable reason/tooltip if the existing reaction widget supports one, e.g.:

```text
Already used this turn
```

Do not silently remove the action if the normal UI pattern is to show disabled choices; preserve enough information for the player to understand why it is unavailable.

## Consumption semantics

A defensive reaction is consumed when the defender actually chooses/commits that defensive attempt.

A failed Dodge/Parry/Block/Resistance roll **still consumes its one use for the turn**. The limit is on attempts, not successful defenses.

The following do not consume a use:

```text
Pass / no defensive action;
disabled action that is rejected before resolution;
invalid/stale reaction request that never resolves.
```

A normal committed defense must be consumed exactly once even if later presentation/network callbacks are retried.

For local-only and remote combat flows, use the same consumption helper rather than maintaining separate counters.

## NPC automatic reactions

NPCs must obey the same rule.

`Combat:ChooseAutomaticReactionAction(entry)` must not select a spent non-bypass defensive action. If its preferred reaction is unavailable, it may choose another available configured reaction according to the existing automatic-selection semantics; if none is available, resolve as Pass/no defence.

After an automatic defensive attempt is selected, consume it through the same runtime ledger used by player reactions.

This prevents NPCs from silently bypassing the rule while players are limited.

## Percent and complex combat compatibility

The implementation must support both current reaction-producing systems:

```text
complex defence stats
percent resistance stats
```

The feature should not be hard-coded specifically to the words Dodge/Parry/Block/Resist. Those are authored Stat definitions/labels.

If the same stat reference is valid against multiple attack types, using it against one attack type consumes that defensive stat for the remainder of the turn unless it bypasses the limit.

Example:

```text
statRef = core:dodge
configured against melee + ranged

use Dodge against melee
-> Dodge is also unavailable against a later ranged attack this turn
```

## Primary files

- `core/internal/ruleset/Rules.lua`
- `client/combat/Reaction.lua`
- `client/combat/effects/Damage.lua` only where the NPC automatic-reaction entry point needs shared consumption/availability integration
- Event teardown/reset code only if needed to clear the bounded runtime ledger

Do not add Profile/Dataset schema state for reaction uses.

## Acceptance criteria

- [ ] Rulesets expose `Limit Defensive Reactions Per Turn`, default `false`.
- [ ] Rulesets expose a multi-select bypass list of defensive stat references, default empty.
- [ ] Existing rulesets retain current unlimited defensive-reaction behavior unless the new toggle is enabled.
- [ ] With the rule enabled, each non-bypass defensive stat can be attempted once per Event turn per defender.
- [ ] Different defensive stats have independent limits: one Dodge does not consume Parry.
- [ ] The limit spans all ticks/pages within one Event turn.
- [ ] A failed defensive attempt still consumes that defensive stat for the turn.
- [ ] Pass does not consume a defensive use.
- [ ] A bypass stat remains unlimited for the whole turn.
- [ ] A stat configured for several attack types is still one defensive reaction identity for limit purposes.
- [ ] Player reaction UI shows/marks a spent defensive choice unavailable.
- [ ] Runtime enforcement rejects a stale/replayed attempt even if the UI state was not refreshed.
- [ ] NPC automatic defenses obey the same limit and bypass rules.
- [ ] New turn -> non-bypass defensive actions become available again.
- [ ] Event replacement/end cannot leak old reaction-use state into another Event.
- [ ] No defensive-use state is persisted to Profile or Dataset SavedVariables.

## Validation matrix

```text
rule disabled
-> Dodge/Parry/Block can be used repeatedly exactly as today

rule enabled; no bypasses
-> first Dodge this turn resolves
-> second Dodge this turn unavailable/rejected
-> Parry still available

Dodge attempt fails
-> second Dodge still unavailable this turn

Dodge used on tick/page 1
-> still unavailable on tick/page 2 of same turn

advance to next Event turn
-> Dodge available again

bypass = Block
-> Dodge once
-> Parry once
-> Block repeatedly

bypass = magic resistance stat
-> magic resistance can be used repeatedly
-> other percent resistance stats remain once-per-turn

same Dodge stat configured against melee and ranged
-> Dodge melee attack
-> later ranged Dodge unavailable in same turn

NPC receives several attacks in one turn
-> automatic resolver cannot reuse spent non-bypass reaction
-> can reuse bypass reaction

Event A ends; Event B starts at turn 1
-> Event A ledger has no effect on Event B
```

## Constraints

- Do not implement a single global `one reaction total per turn` counter; the requested model is one use **per defensive stat/action** with independent bypasses.
- Do not reset on Event tick/page changes.
- Do not infer defense identity from localized display text.
- Do not hard-code Dodge/Parry/Block/Resist names.
- Do not persist transient combat-use state in Profile/Dataset data.
- Do not rely on UI disabled state as the only enforcement.
- Preserve existing hit-check formulas and reaction outcomes; this task changes availability/frequency only.

## Coding-agent instructions

Use current `FrontierDev/rpe2` as authoritative. Before editing, trace `Combat:BuildReactionActions`, `Combat:FindReactionAction`, `Client:ResolveCombatReactionAction`, `Combat:ChooseAutomaticReactionAction`, `Combat:ResolveHitCheckOutcome`, Event turn/tick lifecycle, and event teardown. Keep one availability/consumption contract shared by player and automatic NPC defense flows. Report the final runtime key/ledger shape, exact consumption point, bypass lookup behavior, reset lifecycle, files changed, and validation results.