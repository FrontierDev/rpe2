## Summary

Add two new spell targeter types to the canonical spell targeting system:

- `all_allies`
- `raid_marker`

These are target-selection behaviours. They must work through the same target-policy, targeting UI and spellcasting resolution paths as the existing targeters.

This issue supersedes #313.

Target branch: `dev`.

## 1. All Allies targeter

`all_allies` automatically selects all eligible allied event units for the cast.

### Behaviour

- The spell author selects **All Allies** as the targeter type.
- No individual target clicking is required.
- At targeting time, resolve the set of event units which satisfy the spell's normal ally-targeting rules.
- Respect the existing eligibility rules, including dead-target policy, hidden/targetability rules, self-target restrictions and active event membership.
- Respect `maxTargets` if the target policy defines one.
- The resulting unit IDs must enter the normal queued target-selection/cast pipeline; the targeter must not directly execute spell effects.

## 2. Raid Marker targeter

`raid_marker` is a distinct spell targeter. It is **not** a multi-target spell authored against a particular marker.

No raid marker is stored on the spell.

### Player targeting behaviour

1. The targeting UI shows the normal individually eligible units for the spell.
2. The player clicks one eligible unit.
3. Read that unit's current raid marker from the event unit.
4. Automatically select the clicked unit and the other eligible units which currently have the same raid marker.
5. Stop once `maxTargets` is reached.
6. Pass that selected set through the normal cast-confirmation and spellcasting pipeline.

Example:

- targeter: `raid_marker`
- disposition: `enemy`
- `maxTargets = 5`
- units 2, 4, 7 and 9 have `{skull}`
- units 3 and 6 have `{cross}`
- the player clicks unit 7
- units 2, 4, 7 and 9 are selected automatically

The player does **not** manually select the rest of the units after choosing the first target.

### Raid-marker rules

- The clicked unit is the anchor and must always be included.
- Only units with exactly the same raid marker as the anchor may be added.
- Units on different markers must never enter the same resolved target set.
- If there are more matching units than `maxTargets`, cap the automatic selection at `maxTargets` while retaining the clicked unit.
- Normal target eligibility remains authoritative for every automatically added unit.
- Clicking an unmarked unit must not cause all unmarked units to be treated as one raid-marker group. The target selection should fail cleanly for an unmarked anchor.
- The relevant raid marker is evaluated at targeting time, so the same spell can target different marker groups on different casts.

## Data model / normalization

Extend the existing target `type` contract with the new targeter values, following the current serialization conventions.

Conceptually:

```lua
target = {
    type = "raid_marker",
    targetDisposition = "enemy",
    minTargets = 1,
    maxTargets = 5,
    ...
}
```

and:

```lua
target = {
    type = "all_allies",
    targetDisposition = "ally",
    ...
}
```

There must be no `raidMarker`/marker-ID field on the spell.

Update both persisted spell normalization and runtime combat normalization so the new targeter values survive the existing serialization/import/export and cast paths.

## Targeting UI

Update the spell targeting flow to understand the new targeter types.

### `all_allies`

- Resolve the target set automatically.
- Do not require the player to click each target individually.
- Show the resolved selection through the existing targeting presentation where appropriate before the cast is confirmed.

### `raid_marker`

- Initially allow the player to choose any individually eligible anchor target.
- On the first click, derive the anchor's raid marker and build the full same-marker target set automatically.
- Show the automatically selected targets in the targeting UI.
- Do not enter the normal manual multi-select flow after the anchor is clicked.

## Spellcasting resolution

Update the component target-resolution path so these targeter types resolve from the queued target selection produced by the targeting system.

Do not add special handling in individual spell effects. Once the targeter has produced the target event IDs, downstream effect execution should remain unchanged.

## Spell editor

Expose the two new targeter types in the spell targeter dropdown:

- **All Allies**
- **Raid Marker**

For **Raid Marker**, do not show any field for choosing a particular marker.

Keep the normal disposition, minimum/maximum target and other eligibility controls where they are applicable.

## Autopilot / NPC casting

Support the same semantics for NPC/autopilot casts:

- `all_allies`: resolve eligible allied units automatically.
- `raid_marker`: choose an eligible anchor target through the existing NPC target-selection logic, then expand that anchor to eligible same-marker units up to `maxTargets`.

The marker must always come from the chosen anchor unit, never from spell configuration.

## Acceptance criteria

- **All Allies** is available as a spell targeter and automatically selects eligible allies.
- **Raid Marker** is available as a spell targeter.
- No raid marker is authored or stored on a spell using `raid_marker`.
- Clicking one eligible marked unit automatically selects eligible units with that same marker.
- The clicked unit is always included.
- Automatic selection stops at `maxTargets`.
- Units with other markers are excluded.
- Unmarked anchor units do not expand into an implicit unmarked group.
- Both targeters use the existing canonical target-selection and spellcasting paths.
- Existing targeters continue to behave as before.