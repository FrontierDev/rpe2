## Goal

Create the read-only planning foundation required for periodic, control, and interrupt evaluation without changing current tactical selection behavior yet.

**Source design:** `.docs/RPE2-NPC-Autopilot-Advanced-Spell-Utility-Action-Economy-PDD.md`  
**Implementation plan:** `.docs/RPE2-NPC-Autopilot-Advanced-Spell-Utility-Action-Economy-Implementation-Plan.md`  
**Depends on:** current Autopilot implementation only.

## Implementation-agent rules

This task is sized for **5.6-Luna-ExtraHigh**.

Before editing:

1. work from the current `dev` branch;
2. read the current version of every affected file;
3. trace the exact current callers/callees being modified;
4. do not assume the PDD source snapshot is still current;
5. implement **only this issue**;
6. do not pre-implement #142–#148;
7. search every changed API/helper for all call sites;
8. exercise pure logic with deterministic Lua fixtures/mocks where possible;
9. review the final diff for accidental architectural expansion;
10. close this issue only after its acceptance criteria are validated, then stop.

Preserve manual mode, host-only planning, canonical spell/aura semantics, sliceability, and the same-marker no-split invariant.

## Primary current files to inspect

- `client/autopilot/PlannerIntegration.lua`
- `client/autopilot/SpellEvaluator.lua`
- `client/spellcasting/AuraManager.lua`
- `core/classes/Aura.lua`
- `core/classes/Spell.lua`
- `RPEngine_Dev.toc`

Expected new module if current source supports it:

- `client/autopilot/AuraEvaluator.lua`

Do not force this exact file split if the current load/dependency graph demonstrates a narrower existing home, but do not fold the work into generic AuraManager mutation paths merely for convenience.

## Required changes

### 1. Freeze relevant aura state for the planning snapshot

Extend planner snapshot/scratch state so later utility evaluation can inspect immutable aura information relevant to candidate targets.

At minimum retain enough information to derive:

```text
aura identity/ref
dataset context where required
aura caster event ID
aura target event ID
current stacks
remaining duration/turns
stack behavior
max stacks
resolved definition/ref
current target control state where relevant
```

Do not blindly clone the entire live AuraManager runtime if a narrower immutable representation is sufficient.

The snapshot must not mutate when live aura state changes later during planning.

### 2. Freeze active spellcast summary for later interrupt evaluation

Capture the current active-cast information needed to answer whether a potential target is casting and, where the canonical runtime exposes it, remaining/urgency information.

Do **not** add Autopilot plan/action identity to persistent casts.

### 3. Add per-plan Aura definition resolution/cache

Provide a read-only resolver/cache that maps spell-applied `auraRef` values through the same registry/dataset semantics used by normal spell/aura execution.

Support both existing spell patterns:

```text
component.effect.type = apply_aura
```

and:

```text
damage/heal component with applyAura = true and auraRef = ...
```

Repeated resolution of the same Aura definition inside one plan should use the planning cache rather than repeatedly walking registry/dataset state.

### 4. Add a normalized Aura planning profile

Expose a deterministic, side-effect-free API conceptually equivalent to:

```lua
AuraEvaluator.BuildAuraProfile(...)
```

The exact name may follow current conventions.

The normalized profile should make later issues able to inspect:

- direct Aura damage/heal effects present;
- control effects present;
- triggered-event descriptors;
- duration;
- stack behavior;
- max stacks;
- any other existing immutable information needed by #142/#143.

This issue does **not** assign tactical utility values yet.

### 5. Preserve sliceability/load order

Inspect the current TOC and module dependencies before adding the new module.

Current source loads `SpellEvaluator.lua` before `AuraManager.lua`, while `PlannerIntegration.lua` loads later. Do not create a load-time dependency on an API that does not yet exist at that point.

Any scan over active auras or Aura event definitions which can grow with event/dataset size must be bounded/cached or integrated into the existing resumable planner.

## Explicitly out of scope

Do not implement in this issue:

- periodic future-value math;
- DoT/HoT scoring;
- aura refresh/stack tactical value;
- projected aura reservations;
- control score coefficients;
- interrupt prioritization;
- multiple actions per NPC;
- action-economy ledgers;
- authorization/execution changes;
- DM Helper UI changes;
- new Spell/Aura AI metadata.

## Deterministic regression coverage

Validate at minimum:

1. A pure `apply_aura` spell resolves its canonical Aura definition.
2. A damage/heal component using `applyAura = true` resolves through the same canonical path.
3. Frozen active-aura records preserve caster/target/stacks/duration identity.
4. `refresh_duration` and `independent_duration` remain distinguishable.
5. `maxStacks` is available to later planning.
6. Control flags are readable without mutating live AuraManager control state.
7. Current active-cast state can be frozen/read without changing the cast entry.
8. Repeated Aura refs use the per-plan definition cache.
9. A planner-side Aura profile call never applies, removes, advances, or rolls an Aura effect.
10. Existing direct-damage/direct-heal Autopilot selection remains unchanged by this foundation-only issue.
11. Manual spell/aura behavior remains unchanged.

## Acceptance criteria

- [ ] Advanced planning can inspect a frozen, immutable subset of relevant active Aura state.
- [ ] Advanced planning can inspect current active-cast summaries without taking ownership of casts.
- [ ] Applied Aura definitions are resolved through canonical registry/dataset semantics.
- [ ] Both pure `apply_aura` and damage/heal `applyAura` spell patterns are supported.
- [ ] A per-plan Aura-definition cache prevents repeated equivalent resolution work.
- [ ] The normalized Aura profile exposes effect/event/control/stacking metadata but performs no tactical scoring.
- [ ] No planning call mutates canonical Aura, cast, resource, cooldown, or combat state.
- [ ] Current direct-only Autopilot decisions remain behaviorally unchanged.
- [ ] New work remains bounded/sliceable and does not increase the global TaskQueue budget.
- [ ] Manual mode and normal Aura behavior remain unchanged.