## Summary

Add support for a **Resource Regeneration** percentage stat that acts as a final modifier to automatic resource regeneration ticks, in the same way that stats such as Damage Done, Damage Reduction, Healing Done, etc. modify their corresponding mechanics.

For example:

```
Base resource regeneration: 20
Resource Regeneration: +5

Final regeneration: 21
```

because:

```
20 × 1.05 = 21
```

The modifier must apply to **all regenerating resources except the configured Health resource**.

## Required behaviour

Add a ruleset-configurable stat reference:

```
resources.resource_regeneration_stat
```

Label:

```
Resource Regeneration Stat
```

This should be a normal `statReference` dropdown, consistent with the existing modifier-stat mappings.

When a resource regeneration tick is calculated:

```lua
finalRegen = baseRegen * (1 + resourceRegenerationStat / 100)
```

Examples:

```
Base regen 20, stat +5   -> 21
Base regen 20, stat +25  -> 25
Base regen 20, stat -10  -> 18
Base regen 20, stat 0    -> 20
```

Use the existing resource regeneration rounding/clamping conventions.

The modifier should be applied **after the resource's normal regeneration value has been calculated**, regardless of whether that regeneration came from:

- fixed regeneration (`regenPerSecond`);
- derived regeneration (`regenSourceStatRef × regenMultiplier`).

This is therefore a modifier to the resulting regeneration tick, not another source of base regeneration.

## Health exclusion

The resource identified by:

```
resources.health_stat
```

must explicitly bypass the Resource Regeneration modifier.

For example:

```
Health regen: 10
Mana regen:   20
Resource Regeneration: +25%
```

must produce:

```
Health: +10
Mana:   +25
```

The exclusion must be based on the configured Health resource reference, not resource names or hard-coded IDs.

## Do not modify other resource changes

Resource Regeneration must affect **automatic regeneration ticks only**.

It must not modify:

- direct resource restoration from spells/effects;
- resource costs;
- resource refunds;
- resource gains from other mechanics;
- maximum resource values;
- Health regeneration.

For example, a spell which directly restores 20 Mana must still restore exactly 20 Mana regardless of this stat.

## Implementation

### `core/internal/ruleset/Rules.lua`

Add to the `resources` rules:

```lua
{
    key = "resource_regeneration_stat",
    label = "Resource Regeneration Stat",
    type = "dropdown",
    default = "",
    description = "Select the stat reference used for final non-health resource regeneration modifiers.",
    optionsSource = "statReference",
}
```

Keep this alongside the existing resource-regeneration rules.

### `core/internal/comms/ResourceSync.lua`

Update:

```lua
ResourceSync.BuildPlayerTurnRegenResourceDeltas(...)
```

The existing function already calculates each Resource's regeneration value.

After calculating the normal/base `regenValue`:

1. determine whether the current `resourceRef` is the configured Health resource;
2. if it is Health, leave `regenValue` unchanged;
3. otherwise resolve the configured Resource Regeneration stat;
4. apply it as a final percentage modifier;
5. continue through the existing rounding, cap and delta-generation behaviour.

Do not duplicate the fixed/derived regeneration calculations.

Conceptually:

```lua
regenValue = resolveNormalResourceRegen(...)

if resourceRef ~= healthResourceRef then
    regenValue = regenValue * (1 + resourceRegenModifier / 100)
end
```

### `client/client_Resources.lua`

`Client:ApplyLocalTurnStartResourceRegeneration()` already supplies `BuildPlayerTurnRegenResourceDeltas()` with the active EventUnit resources, `healthResourceRef`, and a stat-resolution callback.

Extend this path to resolve/use the ruleset's `resource_regeneration_stat`.

Prefer passing the stat reference/value into the existing pure regeneration calculation rather than introducing a second regeneration path.

NPC/EventUnit stats must work through the same mechanism as player stats.

### `data/default/core.lua`

Add a default stat:

```
Resource Regeneration
```

Semantics:

```
1 stat = +1% resource regeneration
```

Configure the default ruleset to use this stat for `resource_regeneration_stat`.

It must be usable by the existing stat systems, including equipment bonuses, traits, auras, class/race bonuses, and EventUnit stats.

Do **not** repurpose the existing stat used as a Resource's `regenSourceStatRef`. A resource's source stat determines its **base regeneration**; Resource Regeneration modifies the resulting tick.

## Validation

Add deterministic coverage around `BuildPlayerTurnRegenResourceDeltas()`.

At minimum verify:

1. Fixed regen: base 20, Resource Regeneration +5 -> 21.
2. Derived regen: source stat 100, `regenMultiplier = 0.2`, Resource Regeneration +25 -> 25.
3. Health exclusion: Health base regen 20, modifier +50 -> Health remains 20.
4. Multiple resources: modifier applies independently to Mana/Energy while Health remains unchanged.
5. Negative modifier: base 20, modifier -10 -> 18.
6. Zero/unconfigured modifier preserves current behaviour.
7. Direct resource restoration is unaffected.
8. The modifier works for both player-controlled EventUnits and NPC EventUnits where the stat is present.

## Acceptance criteria

- A `Resource Regeneration` stat exists in the default Core dataset.
- The active ruleset can select which stat represents Resource Regeneration.
- +5 Resource Regeneration increases every non-health automatic regeneration tick by 5%.
- Fixed and derived regeneration are both affected.
- The configured Health resource is never affected.
- Direct resource gains/restores are not affected.
- Resource costs and refunds are not affected.
- Existing regeneration behaviour is unchanged when the stat is zero or unconfigured.
- The implementation uses the existing EventUnit/stat resolution and resource-delta pipeline rather than creating a parallel regeneration system.
