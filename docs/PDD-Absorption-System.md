# Product Design Document: Absorption System

**Status:** Proposed  
**Branch:** `dev`  
**Scope:** Combat damage resolution, aura runtime state, synchronization, data editor, combat presentation, and unit health bars

## 1. Summary

RPE needs a first-class **absorption** mechanic for temporary damage shields such as **Power Word: Shield** and school-restricted wards such as **Fire Ward**.

Absorption is temporary effective health that is consumed by otherwise-valid incoming damage before that damage reaches the target's health resource. Absorption is not a health resource, not permanent mitigation, and not a single aggregate field stored on the unit.

Each absorption source is owned by the aura that created it. Sources therefore retain their own:

- aura identity;
- caster and target;
- maximum absorption;
- remaining absorption;
- duration;
- damage-school restrictions;
- runtime revision/state.

Multiple sources can coexist and expire independently. For example, a target may simultaneously have:

- **Power Word: Shield:** 100 universal absorption, 2 turns remaining;
- **Fire Ward:** 50 Fire-only absorption, 3 turns remaining.

The aggregate absorption shown by the UI is derived from those independent sources. It is never the authoritative state.

## 2. Goals

The system must:

1. Add an Aura effect capable of absorbing damage.
2. Support universal absorption and absorption restricted to one or more damage schools.
3. Keep simultaneous absorption sources independent.
4. Track remaining capacity separately from aura duration.
5. Consume absorption after ordinary damage mitigation but before health loss.
6. Produce deterministic source-consumption ordering on every client.
7. Synchronize depleted/partially depleted absorption correctly across the event.
8. Preserve absorption state across `/reload`, event resynchronization, and players joining an event in progress.
9. Display total absorption on unit health bars without changing the meaning of current/max health.
10. Expose exact source information through unit/aura tooltips.
11. Represent fully and partially absorbed hits correctly in combat log/combat text.
12. Integrate with the existing Aura editor and generated description system.

## 3. Non-goals

This design does **not** introduce:

- a new character resource named Absorption;
- permanent damage reduction;
- healing absorption / anti-heal shields;
- per-school sub-components within a single mixed-school damage amount;
- absorb effects outside active RPE event combat;
- arbitrary transfer of shield capacity between aura sources;
- a new general-purpose temporary-health stat.

The current damage model resolves one damage amount with zero or more `damageSchoolRefs`. It does not represent separate Fire/Frost/etc. portions of the same component. Accordingly, a school-restricted shield tests whether the incoming component contains an eligible school; it does not absorb only a fractional school share of the damage.

## 4. Existing Architecture

The current implementation already provides most of the required lifetime and presentation infrastructure:

- Aura instances are stored per event and keyed independently by aura/caster/target identity.
- Aura entries already track remaining duration and are advanced independently.
- Aura runtime data is cached separately from definitions.
- Damage resolution calculates a final rounded amount after school mitigation and other damage modifiers before previewing a negative health `RESOURCE_DELTA`.
- Event portraits receive a health-state object and render it through `UnitPortrait:SetProgressState()`.
- `ProgressBar` already supports multiple texture layers, but its existing secondary value is clamped to the normal min/max range and is not sufficient by itself for an absorption overlay.

The absorption system should extend these existing systems rather than introduce a parallel buff or temporary-resource subsystem.

## 5. Core Design Principle

> **Individual aura-owned absorption pools are authoritative. Aggregate absorption is derived presentation.**

The unit must not store a field such as:

```lua
unit.absorption = 150
```

Instead, the Aura Manager derives the total from the target's active absorption sources.

This is required because two shields can have different eligibility and different expiry times. Collapsing them into a single value would lose information necessary to resolve later hits correctly.

## 6. Aura Data Model

Add a new Aura effect type:

```lua
{
    type = "absorb",
    baseAbsorption = 100,
    amountMode = "flat",
    statScaling = {},
    damageSchoolRefs = {},
}
```

### 6.1 Fields

`baseAbsorption`
: Base absorption supplied by the effect before scaling.

`amountMode`
: Uses the same normalized amount-mode conventions as other resolved aura amounts where applicable. The initial implementation should support `flat` and reuse existing scaling helpers rather than create a separate arithmetic pipeline.

`statScaling`
: Uses the existing `{ statRef, coefficient }` structure.

`damageSchoolRefs`
: Optional list of qualified damage-school references.

Semantics:

```text
empty list        => absorbs all damage schools
one or more refs  => absorbs an incoming component if at least one incoming school matches
```

### 6.2 Examples

Universal shield:

```lua
{
    type = "absorb",
    baseAbsorption = 100,
    amountMode = "flat",
    statScaling = {},
    damageSchoolRefs = {},
}
```

Fire Ward:

```lua
{
    type = "absorb",
    baseAbsorption = 50,
    amountMode = "flat",
    statScaling = {},
    damageSchoolRefs = {
        "<core-dataset>:<fire-school-id>",
    },
}
```

## 7. Runtime Absorption State

The authored Aura definition describes how large the pool is when the aura is applied. Consumption is event runtime state and must not be written back into the dataset definition.

Each absorption effect on an active aura entry needs runtime state equivalent to:

```lua
entry.effectState = entry.effectState or {}
entry.effectState[effectIndex] = {
    kind = "absorb",
    maximum = 100,
    remaining = 73,
    revision = 4,
}
```

The exact field/container names may follow existing Aura Manager conventions, but the following values are required:

- stable effect identity within the aura;
- snapshotted maximum capacity;
- current remaining capacity;
- monotonically increasing runtime revision or equivalent stale-update guard.

### 7.1 Snapshot semantics

Absorption capacity is resolved **when the aura is applied/refreshed**.

For example, if a shield scales from the caster's Spell Power, later changes to Spell Power do not retroactively change an already-applied shield.

This means:

```text
cast shield at 100 capacity
caster later gains +20% relevant stat
existing shield remains 100 maximum
next application is recalculated from the new caster state
```

This is consistent with the fact that absorption is a consumable pool, not a continuously-derived stat modifier.

### 7.2 Reapplication

The existing aura identity remains the source identity.

For the same aura, same caster, and same target:

- reapplication follows the existing Aura `UpsertAura` / refresh path;
- duration is refreshed according to normal aura semantics;
- maximum absorption is recalculated from the new application;
- remaining absorption is reset to that newly resolved maximum.

Different auras or the same aura from different casters remain independent sources.

## 8. Stacking Constraint

The first implementation should support absorption effects on **single-source, refresh-duration auras**.

Absorption auras should therefore use:

```text
maxStacks = 1
stackBehavior = "refresh_duration"
```

Reason: `independent_duration` currently represents multiple stacks inside one aura entry. Correctly supporting consumable capacity on independently expiring stacks would require per-stack absorption pools, consumption order within those stacks, and additional synchronization state. That is a separate feature and should not be approximated by one aggregate pool because it would produce incorrect expiry behaviour.

The editor/runtime should reject or clearly flag an absorption effect combined with `independent_duration` or `maxStacks > 1` until explicit stacked-absorb semantics are implemented.

This constraint does **not** prevent multiple simultaneous shields. Distinct aura sources remain fully supported.

## 9. Damage-School Eligibility

An absorption source is eligible when either:

1. its `damageSchoolRefs` list is empty; or
2. at least one source school matches at least one incoming `damageSchoolRef`.

Example:

```text
Fire Ward schools:       Fire
Incoming component:      Fire + Arcane
Result:                  eligible
```

```text
Fire Ward schools:       Fire
Incoming component:      Frost
Result:                  not eligible
```

### 9.1 Mixed-school limitation

An incoming component currently has one final damage amount and a list of schools, not independent amounts per school.

Therefore:

```text
100 Fire/Frost damage
```

cannot currently be interpreted as, for example, `40 Fire + 60 Frost`.

For this implementation, a matching school makes the **entire component** eligible for that absorption source.

Per-school fractional absorption requires a future change to the underlying damage representation and is outside this PDD.

## 10. Absorption Consumption Order

When multiple sources are eligible, ordering must be deterministic.

Use the following priority:

1. **More-specific school-restricted sources before universal sources.**
2. Among sources of equal specificity, consume the source with the **fewest turns remaining** first.
3. If still tied, use a stable source key order (`auraKey`, then effect index) as the final deterministic tiebreaker.

For V1, where school restrictions are either an explicit set or unrestricted, "more specific" means restricted before unrestricted. If later features introduce more complex matching, fewer eligible school refs may be treated as more specific.

### 10.1 Example

Target has:

```text
Power Word: Shield   100 remaining   all damage   2 turns
Fire Ward             50 remaining   Fire only    3 turns
```

Incoming:

```text
120 Fire damage after mitigation
```

Resolve:

```text
Fire Ward            absorbs 50 -> 0
Power Word: Shield   absorbs 70 -> 30
Health damage        0
```

A subsequent `40 Frost` hit resolves as:

```text
Fire Ward            ineligible
Power Word: Shield   absorbs 30 -> 0
Health damage        10
```

## 11. Position in Damage Resolution

Absorption occurs after ordinary mitigation and reduction but before the health delta is produced.

Required sequence:

```text
raw damage
-> hit/critical/crushing resolution
-> school resistance/mitigation
-> attacker damage modifiers
-> defender damage reduction
-> critical-damage mitigation
-> final rounding
-> ABSORPTION
-> remaining health damage
-> health RESOURCE_DELTA
```

Absorption is therefore temporary effective health, not another resistance percentage.

Damage already prevented by armour/resistance/etc. must not consume shield capacity.

## 12. Damage Result Contract

Damage results need to retain the distinction between damage arriving at absorption and damage reaching health.

Add fields equivalent to:

```lua
result.preAbsorbAmount = 120
result.absorbedAmount = 100
result.amount = 20
```

`result.amount` should continue to mean the amount that actually reaches health so existing resource-delta consumers do not treat absorbed damage as health loss.

Also expose source-level consumption:

```lua
result.absorptionChanges = {
    {
        auraKey = "...",
        effectIndex = 1,
        absorbed = 50,
        previousRemaining = 50,
        remaining = 0,
        maximum = 50,
        revision = 3,
    },
    {
        auraKey = "...",
        effectIndex = 1,
        absorbed = 50,
        previousRemaining = 100,
        remaining = 50,
        maximum = 100,
        revision = 2,
    },
}
```

The exact shape may be normalized into a shared helper, but the combat layer must be able to tell which sources changed.

## 13. Preview Versus Commit

The damage system currently previews resource damage before the authoritative resource change returns through synchronization. Absorption must preserve that distinction.

Provide separate logic equivalent to:

```text
ResolveAbsorptionPreview(...)
CommitAbsorptionChanges(...)
```

A preview may calculate which sources would be consumed, but it must not permanently mutate aura state multiple times if the same damage result is inspected more than once.

The authoritative damage path commits each source change exactly once.

Required invariant:

> Rebuilding a damage preview or tooltip must never consume absorption.

## 14. Depletion and Aura Lifetime

Absorption capacity and aura duration are independent.

A source can end because:

1. its aura expires/dispelled; or
2. its absorption reaches zero.

### 14.1 Aura expiry/dispel

If the aura expires or is removed, any unused absorption disappears with it.

No separate cleanup timer is needed; the absorption state is owned by the aura entry.

### 14.2 Pool depletion

When an absorption effect reaches zero:

- the effect remains at `remaining = 0` for runtime consistency;
- if the aura contains **only absorption effects**, the aura may be removed immediately as depleted;
- if the aura contains additional effects, the aura remains active until its normal expiry and only the absorb component is exhausted.

This prevents depletion from accidentally removing unrelated stat/control/resource effects on a compound aura.

A helper should determine whether an aura has any meaningful non-depleted continuing effects before auto-removing it.

## 15. Damage-Dependent Mechanics

The system must distinguish a successful hit from health damage actually taken.

Use these semantics:

```text
preAbsorbAmount > 0   => valid damage reached the absorption stage
absorbedAmount > 0   => absorption was consumed
amount > 0           => target actually lost health
```

Mechanics described as triggering on **damage taken** should use post-absorption `result.amount`.

Consequences:

- a fully absorbed hit does not count as health damage taken;
- `cancelOnDamage` should not cancel solely because shield capacity was consumed if zero health damage was taken;
- conditions that care about being successfully hit should continue to use hit/combat-event state rather than `result.amount`;
- death/kill handling continues to depend on resulting health, not pre-absorb damage.

If a future mechanic needs to trigger specifically on "damage absorbed", it can use `absorbedAmount` or a dedicated combat event added later.

## 16. Threat

Existing damage-derived threat should use the post-absorption health damage amount unless a rule explicitly specifies otherwise.

Thus a fully absorbed hit produces zero damage-derived threat from the damage amount itself, while any separately-authored threat effect continues to work normally.

This keeps `result.amount` semantically consistent as actual health damage.

## 17. Runtime Query API

Add Aura Manager helpers with responsibilities equivalent to:

```lua
AuraManager:GetAbsorptionSources(client, eventState, targetEventId)
AuraManager:GetEligibleAbsorptionSources(client, eventState, targetEventId, damageSchoolRefs)
AuraManager:GetTotalAbsorption(client, eventState, targetEventId)
AuraManager:PreviewAbsorption(client, eventState, targetEventId, damageAmount, damageSchoolRefs)
AuraManager:CommitAbsorptionChanges(client, eventState, targetEventId, changes, options)
```

Exact naming may follow repository conventions.

### 17.1 Returned source data

A normalized source should expose enough information for both combat and UI:

```lua
{
    auraKey = "...",
    auraRef = "...",
    auraName = "Power Word: Shield",
    icon = "...",
    casterEventId = 1,
    targetEventId = 2,
    effectIndex = 1,
    maximum = 100,
    remaining = 73,
    turnsRemaining = 2,
    damageSchoolRefs = {},
    revision = 4,
}
```

The underlying aura entry remains authoritative; the query object is a derived view.

## 18. Synchronization

Shield consumption changes persistent event state even when no health is lost.

Example:

```text
incoming damage      60
shield               100 -> 40
health               unchanged
```

There may be no health `RESOURCE_DELTA`, so absorption changes require their own synchronization path.

### 18.1 New runtime synchronization message

Introduce dedicated operations equivalent to:

```text
AURA_RUNTIME_UPDATE
AURA_RUNTIME_UPDATE_BATCH
```

or a more specifically named absorb-state operation if the implementation intentionally limits the protocol to absorption.

Prefer the generic Aura runtime name if runtime effect state is likely to be reused later.

Each entry should carry absolute state rather than only a subtraction delta:

```lua
{
    eventId = "...",
    targetEventId = 2,
    auraKey = "...",
    effectIndex = 1,
    kind = "absorb",
    maximum = 100,
    remaining = 40,
    revision = 3,
}
```

Absolute remaining values make duplicate delivery idempotent and simplify recovery.

### 18.2 Revision handling

Each runtime absorption state has a monotonically increasing revision.

Receivers must:

- accept a newer revision;
- ignore a duplicate revision carrying the same state;
- ignore an older revision;
- request/use full state if an impossible/conflicting newer state is detected.

This protects against duplicate or stale addon messages.

### 18.3 Authority

The same runtime actor that is authoritative for applying the target's health damage must be authoritative for consuming the target's shields for that damage transaction.

Do not allow every observing client to consume its local copy independently and then broadcast competing results.

For normal player-target damage this should follow the existing damage/resource ownership route. For host-controlled NPC state it should follow the corresponding host-authoritative path already used by event damage.

### 18.4 Ordering with health updates

Absorption runtime updates and the resulting health resource delta are one logical damage outcome.

They should be queued under the same reaction/turn scope and source turn/tick metadata. Presentation code must tolerate either network message arriving first, but the sending path should preserve a consistent order.

Recommended send order:

```text
1. absorption runtime update batch
2. health resource delta batch
3. combat presentation/log emission as already scheduled
```

Local preview may update presentation immediately, but authoritative echoes must remain idempotent.

## 19. Full-State Synchronization and Mid-event Join

A new/reloading client must not reconstruct every shield at full capacity.

The event's full aura state must therefore include the current absorption runtime state.

For every absorption effect include at minimum:

```text
maximum
remaining
revision
```

This may be implemented by:

- extending the full `AURA_APPLY_BATCH` state record with an optional serialized runtime section; or
- sending a dedicated full `AURA_RUNTIME_STATE_BATCH` immediately after the full aura topology is restored.

The second approach is preferable if it keeps the existing aura-application wire format simpler.

Required restore order:

```text
aura topology/definitions restored
-> absorption runtime state applied
-> aura/event widget marked ready
```

A client must not briefly present all shields as full while startup is still incomplete.

## 20. Health Bar Presentation

Absorption must be visible on the existing unit health bar without modifying actual health values.

Do **not** render:

```text
maxHealth = maxHealth + absorption
```

because gaining a shield would otherwise make an unchanged health value appear to fall.

### 20.1 UnitPortrait absorb overlay

Add a dedicated absorption overlay texture/state to `UI.UnitPortrait`'s primary health bar.

Derived portrait health state should contain:

```lua
{
    currentValue = 80,
    maxValue = 100,
    absorption = 50,
    ...
}
```

The normal health fill remains `80 / 100`.

The absorption overlay is visually distinct and represents:

```text
min(totalAbsorption / maxHealth, 1.0)
```

of the health-bar width, anchored consistently (recommended: from the right edge) so it remains visible even when the unit is at full health.

This overlay is presentation only; exact source capacities remain in Aura Manager state.

### 20.2 Overshield

If total absorption is greater than maximum health:

- cap the overlay at the full bar width;
- show an overshield/full-absorb edge glow or equivalent visual indicator;
- rely on the tooltip for the exact numeric amount.

Do not expand the health bar beyond its normal width.

### 20.3 Refresh keys

`widget_Event.lua` currently uses display signatures to skip redundant portrait work. The portrait display key must include the derived absorption total/revision.

Otherwise a hit that consumes only shield capacity and changes no health would not necessarily redraw the portrait.

The NPC talking-head portrait should use the same common `UnitPortrait` absorption presentation when it is showing an event unit.

## 21. Unit Tooltip Presentation

The unit tooltip should expose both the aggregate and individual sources.

Example:

```text
Health: 80 / 100
Absorption: 130

Power Word: Shield
80 / 100 absorption | 2 turns
All damage

Fire Ward
50 / 50 absorption | 3 turns
Fire
```

Source lines should use the aura icon and existing aura colour conventions where practical.

Do not merge sources in the tooltip because their durations and school restrictions matter.

An exhausted absorption component remaining on a compound aura should either be omitted from the aggregate source list or shown as `0 / X` only inside the aura's detailed tooltip, not counted toward total absorption.

## 22. Combat Log and Combat Text

Absorption must not make a successful attack look as if nothing happened.

### 22.1 Partial absorption

Example:

```text
Enemy hits Player for 20 Fire damage. (100 absorbed)
```

Represent:

```text
preAbsorbAmount = 120
absorbedAmount = 100
amount = 20
```

### 22.2 Full absorption

Example:

```text
Enemy hits Player for 0 Fire damage. (120 absorbed)
```

or an equivalent display such as:

```text
Enemy's Fire damage is fully absorbed by Player. (120 absorbed)
```

The exact copy should follow existing combat-log style, but the absorbed amount must be visible.

### 22.3 Floating reaction/combat text

Add an absorption presentation path so a shield-only hit produces visible feedback even when there is no negative health resource delta.

The UI should be able to distinguish:

- health damage;
- absorbed damage;
- fully absorbed damage.

Do not fabricate a health `RESOURCE_DELTA` merely to obtain combat text.

## 23. Aura Tooltip / Description Generation

Extend `AuraDescriptionBuilder` and tooltip-template generation for `absorb` effects.

Generated text examples:

```text
Absorbs 100 damage.
```

```text
Absorbs 50 Fire damage.
```

```text
Absorbs 75 Fire or Frost damage.
```

When stat scaling is present, generated descriptions should use the same resolved-value context used for existing aura effects.

Aura duration remains a property of the aura and does not need to be duplicated into the absorb sentence when the surrounding aura tooltip already displays duration.

## 24. Data Editor

Add `Absorb` to the Aura Inspector effect type selector.

When selected, show:

```text
Effect Type       Absorb
Base Absorption   [number]
Amount Mode       [supported modes]
Damage Schools    [multi-select]
Stat Scaling      [existing scaling editor]
```

Rules:

- empty Damage Schools means **All Damage**;
- damage-school selector uses the same cross-dataset school source as damage effects;
- irrelevant damage/heal/stat/control fields are disabled/hidden following existing inspector conventions;
- `independent_duration` or `maxStacks > 1` with an absorb effect must produce a validation warning/error for V1.

Normalization in `core/classes/Aura.lua` must preserve the new effect fields through `New`, `Merge`, `ToTable`, and `FromTable`.

## 25. Dataset Dependency Tracking

Because `damageSchoolRefs` on an absorb effect reference dataset objects, dependency scanning must treat them the same way as damage-effect school references.

This applies to:

- dataset dependency discovery;
- reference validation;
- deletion/reference checks;
- activated-dataset consistency/hash behaviour where applicable.

An absorption aura must not silently keep a broken school reference after its source dataset is removed.

## 26. Cache and Revision Invalidation

Changing absorption runtime state can affect:

- health-bar presentation;
- unit tooltips;
- combat previews;
- targeting/AI decisions if they later query effective durability.

On committed absorption mutation:

1. bump the owning aura bucket/runtime revision;
2. invalidate any derived absorption-total cache for that target;
3. mark the target portrait dirty;
4. refresh visible unit/aura tooltips as needed;
5. bump combat runtime revision where cached combat lookup/results depend on aura state.

Do not perform a full event-widget refresh when a targeted portrait refresh is sufficient.

## 27. Autopilot / AI Semantics

Initial absorption support does not require the NPC autopilot to value shields strategically.

However, runtime queries must be exposed cleanly enough that later AI work can ask for:

```text
current total absorption
eligible absorption for a given school set
effective health = health + eligible absorption
```

Do not bake AI-specific policy into the Aura Manager.

## 28. Example End-to-End Flow

### 28.1 Apply Power Word: Shield

Spell applies aura:

```text
Power Word: Shield
Duration: 2 turns
Absorb effect: 100 universal
```

Aura Manager:

```text
creates/refreshed aura entry
resolves absorption maximum = 100
sets remaining = 100
sets runtime revision = 1
syncs full/new aura state
portrait derives +100 absorption
```

### 28.2 Apply Fire Ward

Spell applies second aura:

```text
Fire Ward
Duration: 3 turns
Absorb effect: 50 Fire
```

Derived target state:

```text
Health                 100 / 100
Total absorption       150
Power Word: Shield     100 / 100, 2 turns
Fire Ward               50 / 50, 3 turns
```

### 28.3 Receive 120 Fire damage after mitigation

Eligible sources:

```text
Fire Ward              yes, restricted
Power Word: Shield     yes, universal
```

Consumption:

```text
Fire Ward              50 -> 0
Power Word: Shield     100 -> 30
Health                 unchanged
absorbedAmount         120
amount                 0
```

Runtime absorption updates are synchronized despite no health resource delta.

### 28.4 Receive 40 Frost damage

Eligible sources:

```text
Fire Ward              no
Power Word: Shield     yes
```

Consumption:

```text
Power Word: Shield     30 -> 0
Health                 100 -> 90
absorbedAmount         30
amount                 10
```

### 28.5 Duration expiry

Fire Ward's aura may already have been removed because it was absorption-only and depleted. Any non-depleted absorption aura disappearing from duration expiry or dispel loses its remaining capacity automatically.

## 29. Error Handling and Defensive Rules

Normalize invalid authored/runtime values defensively:

- negative maximum/remaining -> `0`;
- remaining greater than maximum -> clamp to maximum;
- NaN/infinite amount -> reject/normalize to `0`;
- unknown damage-school ref -> source should fail validation; runtime must not crash;
- missing runtime state during a normal new application -> initialize from resolved definition;
- missing runtime state during an explicit full-state restore -> do **not** silently refill a previously-consumed shield if the synchronization protocol says runtime state should follow; keep startup pending until state is resolved or apply a documented fallback.

No malformed absorption state should be allowed to produce negative health damage or healing.

## 30. Performance Requirements

Absorption lookup runs on every damaging hit, so it must use the existing target aura index rather than scan all event auras globally.

For a target:

```text
get target aura keys
-> inspect only active aura entries on that target
-> use cached runtime metadata to locate absorb effects
-> filter eligible sources
-> stable-sort only the small eligible set
```

The Aura Manager may cache aggregate absorption per target keyed by the aura bucket revision, but correctness must not depend on the cache.

No per-frame absorption polling should be introduced. UI refreshes should remain event/mutation driven.

## 31. Implementation Areas

Primary implementation areas are expected to include:

### Data / normalization

- `core/classes/Aura.lua`
- dataset dependency/reference scanning

### Aura runtime

- `client/spellcasting/AuraManager.lua`
- aura serialization/full-state synchronization
- comms operation registry for runtime updates

### Combat

- `client/combat/effects/Damage.lua`
- damage finalization / resource-delta queue path
- combat log and combat reaction presentation

### UI

- `core/ui/prefabs/UnitPortrait.lua`
- `core/ui/elements/ProgressBar.lua` only if a reusable overlay primitive is preferable
- `client/ui/widgets/widget_Event.lua`
- tooltip presentation

### Authoring / descriptions

- `client/ui/editor/inspectors/page_InspectorAura.lua`
- `client/spellcasting/AuraDescriptionBuilder.lua`
- tooltip-template handling where effect fields are enumerated

### Load-order registration

- `RPEngine2.toc` if new Lua modules are introduced rather than extending existing ones

## 32. Recommended Implementation Sequence

1. **Schema and editor**
   - normalize `absorb` effects;
   - dependency tracking;
   - editor fields;
   - generated descriptions.

2. **Aura runtime state**
   - snapshot maximum/remaining on application;
   - source query helpers;
   - V1 stacking validation;
   - reset/depletion rules.

3. **Damage integration**
   - preview eligible sources;
   - deterministic consumption;
   - produce `preAbsorbAmount`, `absorbedAmount`, and source changes;
   - commit exactly once before health delta generation.

4. **Synchronization**
   - runtime update batch;
   - revision handling;
   - full-state restore;
   - mid-event join/reload validation.

5. **Presentation**
   - portrait absorption overlay;
   - target refresh signature;
   - unit tooltip source breakdown;
   - combat log/text handling.

6. **Regression validation**
   - active-event sync;
   - aura expiry/dispel;
   - zero-health-damage hits;
   - multi-source ordering;
   - school filtering;
   - startup/reload/join-in-progress.

## 33. Test Matrix

At minimum exercise deterministic cases for:

### Basic universal absorption

```text
shield 100
incoming 60
expected shield 40, health damage 0
```

```text
shield 100
incoming 140
expected shield 0, health damage 40
```

### School filtering

```text
Fire shield 50
incoming Fire 40
expected shield 10, health damage 0
```

```text
Fire shield 50
incoming Frost 40
expected shield 50, health damage 40
```

```text
Fire shield 50
incoming Fire/Frost 40
expected shield 10, health damage 0
```

### Multiple sources

```text
universal 100 / 2 turns
Fire 50 / 3 turns
incoming Fire 120
expected Fire 0, universal 30, health damage 0
```

### Equal-priority expiry ordering

```text
universal A 40 / 1 turn
universal B 40 / 3 turns
incoming 50
expected A 0, B 30
```

### Stable tiebreak

Two otherwise-identical eligible sources must be consumed in the same source-key order on every client.

### Fully absorbed hit

- no negative health resource delta;
- absorption runtime update still sent;
- combat feedback still shown;
- `cancelOnDamage` does not fire if it specifically means health damage taken.

### Partial hit

- shield runtime update and health delta both sent once;
- combat log displays health and absorbed amounts correctly.

### Aura expiry

- unused capacity disappears;
- aggregate UI updates even without health change.

### Dispel

- removed source no longer contributes to aggregate or future absorption.

### Reapplication

- same source recalculates maximum;
- remaining resets to new maximum;
- duration follows normal refresh behaviour.

### Different casters

Same aura from two different casters must remain two independent sources if current aura identity rules permit those entries separately.

### Reload / join-in-progress

Given a 100 shield consumed to 37 before synchronization:

```text
expected restored remaining = 37
not 100
```

### Duplicate/stale runtime messages

- duplicate revision is idempotent;
- older revision cannot restore previously consumed capacity.

### UI

- full-health unit with absorption visibly shows shield overlay;
- partially injured unit shows unchanged health proportion plus absorption overlay;
- absorption-only change invalidates portrait display key;
- >100% max-health absorption shows capped overlay + overflow indicator;
- tooltip lists exact independent sources.

## 34. Acceptance Criteria

- [ ] Aura definitions support an `absorb` effect with base amount, scaling, and optional damage schools.
- [ ] Universal shields absorb eligible damage before health loss.
- [ ] School-restricted shields only absorb matching damage components.
- [ ] Mixed-school components use any-school-match eligibility and are documented as one indivisible damage amount.
- [ ] Multiple shield sources remain independent.
- [ ] Restricted shields are consumed before universal shields.
- [ ] Equal-specificity sources are consumed by earliest expiry, then stable key order.
- [ ] Absorption occurs after normal mitigation and before health resource delta generation.
- [ ] Fully absorbed attacks produce no health delta but still mutate/synchronize shield state.
- [ ] Damage results expose pre-absorb, absorbed, and health-damage amounts.
- [ ] Absorption preview cannot consume a pool more than once.
- [ ] Reapplying the same source refreshes/recalculates its pool without creating an unintended duplicate.
- [ ] Aura expiry or dispel removes unused capacity.
- [ ] Depleting an absorption-only aura may remove it immediately; compound auras retain their other effects.
- [ ] Remaining/max absorption survives event resync, `/reload`, and mid-event join.
- [ ] Stale/duplicate runtime updates cannot refill a shield.
- [ ] Unit health bars visibly show aggregate absorption without changing health max/current semantics.
- [ ] Unit tooltips show aggregate absorption and independent source details.
- [ ] Combat log/combat text represents partial and full absorption.
- [ ] Aura editor exposes the new effect cleanly.
- [ ] Aura generated descriptions include absorption amount and school restrictions.
- [ ] Dataset dependency tracking includes absorption damage-school refs.
- [ ] No global aura scan or per-frame polling is added to damage/UI hot paths.

## 35. Future Extensions

The source-based model intentionally leaves room for later features without changing the core representation:

- stacked absorption with per-stack capacities/durations;
- healing absorption;
- absorption priority authored per effect;
- absorption-triggered combat events;
- reflection/conversion of absorbed damage;
- shields restricted by attack type as well as school;
- percentage-of-incoming-damage absorption;
- AI valuation of effective health by school;
- separate visual colouring for school-specific shields.

These should build on the authoritative aura-owned pool model rather than replace it.
