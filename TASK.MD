## Context

Depends on #325 (and therefore #324/#323).

Implement the player-facing presentation layer for the absorption system described in [`docs/PDD-Absorption-System.md`](../blob/dev/docs/PDD-Absorption-System.md).

The authoritative runtime state and damage-result fields must come from the earlier absorption issues. This issue must not create a second UI-owned shield state.

## Core presentation rule

> Health remains health. Absorption is a derived overlay on top of it.

Do **not** change health values or health maximums to represent shielding.

Incorrect:

```lua
maxHealth = maxHealth + totalAbsorption
```

That would make a full-health unit appear to lose health percentage when gaining a shield.

Instead, derive total absorption from Aura Manager runtime sources and render it separately.

## Derived portrait state

Extend the event portrait health-state construction in `client/ui/widgets/widget_Event.lua` (or the appropriate shared helper) with derived absorption information equivalent to:

```lua
{
    currentValue = 80,
    maxValue = 100,
    ...,
    absorption = 130,
    absorptionRevision = 7,
}
```

`absorption` is the current sum of all non-depleted active absorb sources for that target.

Do not store this aggregate on the unit.

The display key/signature used to skip redundant portrait refreshes must include absorption amount/revision so a shield-only hit redraws the portrait even when health is unchanged.

## UnitPortrait absorb overlay

Extend `core/ui/prefabs/UnitPortrait.lua` with a dedicated health-bar absorption layer/state.

Do not repurpose the portrait's existing secondary resource bar: that is a separate resource below health.

Do not rely on `ProgressBar.secondaryValue` as the only implementation if it cannot represent the required visual semantics cleanly; the current progress bar clamps secondary values to its normal min/max and draws both fills from the left.

Required presentation:

- normal health fill continues to represent `currentHealth / maxHealth`;
- absorption is a distinct overlay texture on the health bar;
- overlay width is based on `min(totalAbsorption / maxHealth, 1)`;
- recommended anchoring is from the **right edge** so shielding remains visible even at full health;
- use a visually distinct shield/absorb treatment without obscuring the underlying health state;
- zero absorption hides the overlay.

The common `UnitPortrait` implementation should be used by all event-unit portrait contexts, including the NPC talking-head portrait when it displays an event unit.

## Overshield

When:

```text
totalAbsorption > maxHealth
```

then:

- cap the overlay at 100% of the normal health-bar width;
- show a lightweight overshield/full-bar indicator such as an edge glow or equivalent treatment;
- exact numeric value is supplied by the tooltip;
- do not expand the bar or alter `maxHealth`.

The visual treatment should remain readable at the event widget's small portrait bar heights.

## Unit tooltip

Extend event-unit/portrait tooltip presentation so it provides both aggregate and source-level information.

Example:

```text
Health: 80 / 100
Absorption: 130

Power Word: Shield
80 / 100 absorption
2 turns

Fire Ward
50 / 50 absorption
3 turns
Fire
```

Requirements:

- aggregate total is shown once;
- individual sources remain separate;
- include current/maximum capacity;
- include remaining aura duration;
- include school restriction for restricted shields;
- universal shields do not need an `All damage` line unless that improves existing tooltip consistency;
- do not merge sources with the same name if they are independently keyed/cast, because duration/caster/state can differ;
- depleted absorb effects on compound auras do not contribute to the aggregate total;
- a depleted component may remain visible as `0 / X` only in detailed aura information if useful, but should not look like active shield capacity.

Reuse Aura Manager source-query/tooltip data rather than re-deriving effect definitions in the UI.

## Combat log

Use the damage-result fields from #325 to distinguish incoming, absorbed and health damage.

Partial absorption should communicate both actual health damage and absorbed amount, for example following the existing combat-log style:

```text
Enemy hits Player for 20 Fire damage. (100 absorbed)
```

Fully absorbed hits must still produce meaningful output, e.g.:

```text
Enemy hits Player for 0 Fire damage. (120 absorbed)
```

or an equivalent existing-style message such as:

```text
Enemy's Fire damage is fully absorbed by Player. (120 absorbed)
```

The exact copy should follow current combat-log conventions, but these requirements are mandatory:

- a fully absorbed attack must not disappear from the combat log;
- absorbed amount must be visible;
- health damage must not be misreported as the pre-absorb amount;
- existing icon/school presentation must remain intact.

Audit both direct damage and triggered/aura damage log paths if they share or duplicate formatting.

## Floating combat / reaction text

Add absorb-aware local combat feedback.

Required cases:

```text
partial: health damage + absorbed amount
full:    absorbed feedback even though no health RESOURCE_DELTA exists
```

Do **not** fabricate a health resource delta just to trigger floating text.

Use `damageResult.absorbedAmount` / `amount` (or their final implemented equivalents) as the presentation source of truth.

The system should be able to visually distinguish:

- ordinary health damage;
- partial absorption;
- fully absorbed damage.

Keep this narrowly integrated with the current reaction/combat-text system rather than introducing a new independent ticker mechanism.

## Refresh/invalidation behaviour

A synchronized or locally committed shield change must refresh only the affected target where possible.

Verify that:

- target portrait refreshes when absorption changes but health does not;
- visible unit tooltip refreshes if open;
- NPC talking-head portrait refreshes through common portrait state;
- no full event-widget rebuild is required for one shield change;
- repeated unchanged absorption state does not trigger needless redraw work.

## Loading/resync behaviour

During event startup, reload or mid-event resynchronization, do not briefly display an absorption aura as full before its authoritative runtime capacity has arrived.

The event UI should become ready using the same synchronization readiness/order established by #325 so the first visible shield state is the authoritative current state.

Regression example:

```text
shield maximum 100
actual remaining 40
/reload
first stable UI state must show 40, not 100 then 40
```

## Primary files/call paths to inspect

At minimum:

- `client/ui/widgets/widget_Event.lua`
  - portrait health-state builders
  - portrait display/signature keys
  - tooltip builders
  - NPC speech/talking-head portrait state
- `core/ui/prefabs/UnitPortrait.lua`
  - health progress state
  - shared tooltip construction
  - status layout
- `core/ui/elements/ProgressBar.lua`
  - inspect current layering before deciding whether to extend or use a dedicated UnitPortrait texture
- combat log formatting/emission paths for damage
- local reaction/combat-text presentation helpers
- Aura Manager source/tooltip APIs from #324

Read the current `dev` versions and trace all current portrait consumers before changing the common prefab.

## Out of scope

Do not implement here:

- absorption data schema/editor;
- aura runtime consumption rules;
- network protocol;
- new spell definitions;
- strategic NPC/autopilot valuation of shields;
- stacked independent-duration absorption.

## Acceptance criteria

- [ ] Health current/max values remain unchanged by absorption.
- [ ] Event-unit health bars visibly show current absorption as a distinct overlay.
- [ ] Full-health units still visibly show a shield.
- [ ] Overshield is capped visually at one bar width with an overflow/full indicator.
- [ ] Shield-only consumption redraws the affected portrait even when health is unchanged.
- [ ] Zero absorption removes/hides the overlay.
- [ ] Aggregate tooltip absorption equals the sum of current active source capacities.
- [ ] Tooltip lists independent absorption sources with current/max, duration and school restrictions.
- [ ] Partial absorption combat log shows post-absorb health damage plus absorbed amount.
- [ ] Fully absorbed hits still produce combat-log output.
- [ ] Floating/reaction feedback works for fully absorbed hits without a fake health delta.
- [ ] NPC talking-head/event portraits use the same common absorb presentation.
- [ ] Reload/resync does not visibly flash shields back to their original maximum.
- [ ] Targeted absorption refreshes do not require a full event-widget rebuild.

## Regression tests / visual checks

1. 100/100 health, no shield -> normal full health bar; no absorb layer.
2. 100/100 health + 50 shield -> health still visually full, distinct absorb overlay visible.
3. 50/100 health + 50 shield -> health remains 50%; absorb overlay independently visible.
4. 50/100 health + 150 shield -> absorb layer capped at full width, overshield indicator shown; tooltip says 150.
5. Shield 100 -> 40 with no health change -> portrait refreshes and tooltip updates to 40.
6. Two sources (100 universal, 50 Fire) -> aggregate 150 and two separate tooltip entries.
7. Partial hit 120 with 100 absorbed -> combat log reports 20 health damage and 100 absorbed.
8. Fully absorbed 80 hit -> no health delta, but combat log and floating/reaction feedback are shown.
9. Exhausted absorb component on compound aura contributes zero to aggregate.
10. `/reload` with 40/100 remaining -> first stable rendered state shows 40/100.