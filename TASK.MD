## Summary

Add a new parameterised combat event:

**On Damage Type**

This should allow Aura/Trait event triggers such as:

- **When you deal Fire damage...**
- **When the target deals Fire damage...**
- **When you deal Frost damage...**

Internally, the event should filter on a single **damage school** reference (Fire, Frost, Physical, Holy, etc.). The repository's schema calls these **damage schools**, so use a field such as:

```lua
damageSchoolRef = "datasetId:damageSchoolId"
```

even though the editor-facing label should be **Damage Type**.

Suggested combat event ID:

```lua
on_damage_type
```

## Intended semantics

`on_damage_type` fires when the event recipient **deals actual damage of the configured damage school**.

For a configured Fire event:

```lua
{
    combatEventId = "on_damage_type",
    damageSchoolRef = "<Fire damage school ref>",
    triggerTarget = "event_other",
    chance = 100,
    effects = { ... },
}
```

The event should be source/dealer-oriented:

- **event source** = unit that dealt the damage;
- **event other** = unit that took the damage;
- event recipient = the damage dealer.

This is analogous to `on_defence` being a normal combat event with an additional event-specific filter field, but `on_damage_type` filters on `damageSchoolRef` instead of `defenceStatRef`.

### Damage requirement

The event should fire only when the resolved damage actually causes a **non-zero health loss**.

Use the authoritative resolved damage result rather than the authored effect definition alone.

A hit that is completely absorbed and produces no health loss should **not** count as "deals damage".

A missed/failed attack should not fire it.

The trigger should use the **resolved damage school** carried by the damage result, not infer school from melee/ranged/spell attack type.

## Existing architecture

### Combat event registry

`client/combat/Events.lua` defines combat events through `EVENT_DEFINITIONS`.

`on_defence` currently demonstrates the parameterised-event pattern:

```lua
{
    id = "on_defence",
    label = "On Defence",
    recipientRole = "target",
}
```

The new event should be registered here with the damage dealer as recipient, i.e. equivalent to a caster/source-oriented event.

### Parameter filtering

Aura events already support `defenceStatRef`:

- `core/classes/Aura.lua` normalizes it only for `on_defence`;
- `client/spellcasting/AuraManager.lua` uses `matchesCombatEvent()` to match the runtime `context.defenceStatRef`.

Trait events have the parallel implementation:

- `core/classes/Trait.lua`;
- `client/client_Traits.lua`.

Implement `damageSchoolRef` using the same architecture rather than creating a separate proc system.

### Damage resolution

`client/combat/Reaction.lua::FinalizeLocalDamageResult(entry, damageResult)` receives the resolved damage result after damage calculation/absorption.

The resolved damage payload already exposes the damage school used elsewhere by the combat log:

```lua
damageResult.damageSchoolRef
```

and the actual health loss is available through the resolved resource delta / `appliedDelta`.

This is the appropriate level at which to emit a generic damage-school event. Do not require individual spells to manually add `on_damage_type` to their `casterEvents`.

## Required changes

### 1. Register the combat event

Update `client/combat/Events.lua`:

```lua
{
    id = "on_damage_type",
    label = "On Damage Type",
    recipientRole = "caster",
}
```

Use the existing source/target routing:

- source/caster = damage dealer;
- target/event-other = damaged unit.

Ensure the event context can carry:

```lua
damageSchoolRef = ...
```

through `Events:Run()` into Aura/Trait combat-event handlers, analogous to `defenceStatRef`.

### 2. Emit it from resolved damage

Add a focused helper in the combat layer, e.g.:

```lua
Combat:EmitDamageTypeEvent(client, entry, damageResult)
```

Call it from the authoritative damage-finalization path.

It should return without dispatching unless all of the following are true:

- attacker/source unit exists;
- defender/target unit exists;
- damage resolved successfully;
- actual health loss is greater than zero;
- `damageResult.damageSchoolRef` is a valid non-empty ref.

Dispatch:

```lua
Events:Run(client, {
    eventState = entry.eventState,
    sessionState = ...,
    combatEventId = "on_damage_type",
    sourceEventId = attackerEventId,
    targetEventIds = { defenderEventId },
    eventSourceUnit = entry.attackerUnit,
    eventOtherUnit = entry.defenderUnit,
    damageSchoolRef = damageResult.damageSchoolRef,
    actionContext = entry.context,
})
```

Do not infer the damage school from `entry.attackType`.

Do not emit once per authored `damageSchoolRefs` entry. Emit from the **resolved** damage result.

Avoid double-emission across local/remote damage resolution. The authoritative finalization path must produce one logical `on_damage_type` event for one applied damage result.

### 3. Pass the damage-school parameter through the event dispatcher

Update `client/combat/Events.lua::Run()` so the AuraManager/Trait runtime context includes:

```lua
damageSchoolRef = context.damageSchoolRef
```

alongside the existing:

```lua
defenceStatRef = context.defenceStatRef
```

### 4. Extend Aura event schema

Update `core/classes/Aura.lua`.

Add a normalizer for the event's selected damage school, e.g.:

```lua
local function normalizeDamageSchoolRef(value)
    ...
end
```

The normalized event should contain:

```lua
damageSchoolRef =
    combatEventId == "on_damage_type"
    and normalizeDamageSchoolRef(value.damageSchoolRef)
    or nil
```

Like `defenceStatRef`, this field must not remain populated on unrelated combat event types.

### 5. Filter Aura events by damage school

Extend `client/spellcasting/AuraManager.lua::matchesCombatEvent()`.

Current `on_defence` behaviour filters by `defenceStatRef`.

Add equivalent handling for `on_damage_type`:

- if the Aura event has no valid `damageSchoolRef`, it should not become an unfiltered "all damage" event accidentally;
- otherwise, compare the requested event `damageSchoolRef` with the resolved runtime `context.damageSchoolRef`;
- use the repository's existing ref-normalization / dataset-qualified-ref comparison conventions where appropriate.

The selected damage type is a required parameter for this event.

### 6. Extend Trait event schema/runtime

Apply the same behaviour to Trait events.

Update:

- `core/classes/Trait.lua::normalizeEvent()`;
- `client/client_Traits.lua::matchesTraitCombatEvent()` and its call sites.

Trait/Aura semantics must be identical.

Embedded item traits that use the Trait event schema should inherit this functionality automatically rather than requiring a separate implementation.

### 7. Aura editor support

Update the Aura event editor:

- `client/ui/editor/inspectors/aura/page_InspectorAuraEvents.lua`;
- `client/ui/editor/inspectors/page_InspectorAura.lua`;
- shared helpers as appropriate.

Add an event-specific dropdown:

**Damage Type**

Populate it using the existing cross-dataset damage-school list:

```lua
BuildSpellInspectorDamageSchoolsAcrossDatasets()
```

For `on_damage_type`:

- show/enable the Damage Type dropdown;
- store exactly one `damageSchoolRef`;
- require a selection.

For all other event types:

- hide/disable it;
- normalization must clear stale `damageSchoolRef` values.

Keep the existing **Defence Type** selector exclusive to `on_defence`.

### 8. Trait editor support

Add the same **Damage Type** selector to the Trait event editor in:

`client/ui/editor/inspectors/page_InspectorTrait.lua`

It should behave identically to the Aura editor.

### 9. Generated descriptions/tooltips

Update:

- `client/spellcasting/AuraDescriptionBuilder.lua`;
- `client/traits/DescriptionBuilder.lua`.

The generated trigger text must include the selected damage-school name.

Examples:

```text
When you deal Fire damage, ...
When the target deals Fire damage, ...
```

Use the existing damage-school name resolution; do not show raw refs.

Preserve current `triggerTarget` language for where the triggered effect is applied. The damage dealer/recipient wording and the effect's trigger target are separate concepts.

### 10. Validation

If the editor/schema has a validation mechanism for event-specific required fields, make `damageSchoolRef` required for `on_damage_type`.

Do not silently interpret an empty selection as "any damage".

## Expected files

At minimum:

- `client/combat/Events.lua`
- `client/combat/Reaction.lua` and/or the central damage-finalization helper location
- `core/classes/Aura.lua`
- `core/classes/Trait.lua`
- `client/spellcasting/AuraManager.lua`
- `client/client_Traits.lua`
- `client/ui/editor/inspectors/aura/page_InspectorAuraEvents.lua`
- `client/ui/editor/inspectors/page_InspectorAura.lua`
- `client/ui/editor/inspectors/page_InspectorTrait.lua`
- `client/spellcasting/AuraDescriptionBuilder.lua`
- `client/traits/DescriptionBuilder.lua`

Only modify additional files if tracing the current damage/event call paths proves they are required.

## Acceptance criteria

- [ ] **On Damage Type** appears in Aura combat-event selection.
- [ ] **On Damage Type** appears in Trait combat-event selection.
- [ ] Selecting it exposes a single **Damage Type** dropdown populated from current damage schools.
- [ ] A damage type is required; an empty selection does not mean "all damage".
- [ ] Aura/Trait normalization preserves `damageSchoolRef` only for `on_damage_type`.
- [ ] Switching away from `on_damage_type` removes/ignores the stale damage-school parameter.
- [ ] Dealing non-zero Fire damage fires an event configured for Fire.
- [ ] Fire damage does not fire an event configured for Frost.
- [ ] Frost damage fires a Frost-configured event.
- [ ] Physical damage can be selected and matched in the same way.
- [ ] Melee/ranged/spell delivery type does not matter; matching is by resolved damage school.
- [ ] A missed attack does not fire the event.
- [ ] A completely absorbed hit that causes zero health loss does not fire the event.
- [ ] A partially absorbed hit that still causes non-zero health loss does fire it.
- [ ] The damage dealer is the event source/recipient.
- [ ] The damaged unit is `event_other`.
- [ ] `triggerTarget = "event_source"` can target the dealer.
- [ ] `triggerTarget = "event_other"` can target the damaged unit.
- [ ] Existing `on_defence` / `defenceStatRef` filtering remains unchanged.
- [ ] Existing On Melee Hit / On Spell Hit / On Critical Hit hooks remain unchanged.
- [ ] A single resolved damage application produces no duplicate `on_damage_type` proc.
- [ ] Trait and Aura implementations have identical filtering semantics.
- [ ] Generated descriptions resolve the damage-school name, e.g. **"When you deal Fire damage..."**, rather than exposing a raw ref.
- [ ] No spell needs to manually opt into `on_damage_type` through its existing `casterEvents` list.
