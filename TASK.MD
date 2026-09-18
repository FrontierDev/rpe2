## Verification against `dev` @ `5e72e58`

#370 is **not ready to close**.

Most schema/editor/filtering work is present, but three functional blockers remain.

### Verified

- `on_damage_type` is registered as a source/caster-recipient event.
- `damageSchoolRef` is passed through `Events:Run()`.
- Aura and Trait schemas retain it only for `on_damage_type`.
- Aura/Trait matching requires a configured damage school and compares it with the resolved school.
- Aura and Trait editors expose a single **Damage Type** dropdown only for this event.
- Existing `on_defence` filtering remains separate.
- Generated trigger text resolves the school name.
- The event is generic; spells do not need to opt into it through `casterEvents`.

### Blocker 1 — remote player damage uses a preview, not the authoritative post-absorb result

For a remote player defender, `HandleDamageHitCheckResponse()` on the attacker calls:

```lua
Combat:ApplyResolvedDamage(entry, true)
```

then immediately:

```lua
Combat:EmitDamageTypeEvent(client, entry, damageResult)
```

That is preview mode.

The defender owns the authoritative post-absorb resolution, but defender-side `EmitDamageTypeEvent()` is prevented from executing the source-owned proc by:

```lua
isLocalAuthorityForUnit(entry.eventState, entry.attackerUnit)
```

So player-vs-player `on_damage_type` is currently decided from the attacker's predicted damage state, not the defender's authoritative applied damage.

This violates the issue requirement to use actual post-absorb health loss and can misfire around full/partial absorption or state divergence.

The fix needs an explicit authority hand-off:

```text
authoritative target damage resolution
    -> authoritative non-zero-health-loss outcome
    -> source authority
    -> on_damage_type dispatch
```

Do not fix this by simply running source-owned Aura/Trait effects on the defender client.

### Blocker 2 — ordinary periodic Aura damage does not emit `on_damage_type`

Direct combat damage reaches `EmitDamageTypeEvent()` through `Reaction.lua`.

Periodic Aura damage instead follows:

```text
AuraManager:AdvanceAuraEntry()
 -> TickAura()
 -> contract.Execute(...)
 -> HandleLocalAuraTickResult()
```

That path never emits `on_damage_type`.

Therefore a Fire DoT tick that causes actual health loss does not currently satisfy **“When you deal Fire damage”**.

Ordinary periodic Aura damage should participate. Triggered proc damage can retain the existing `suppressCombatEvents = true` recursion protection unless the design explicitly changes that policy.

### Blocker 3 — Aura description target wording is wrong for `triggerTarget = "event_other"`

The trigger prefix is generated separately and can correctly say:

```text
When the target deals Fire damage...
```

But Aura event effect clauses still resolve their target through:

```lua
resolveTriggeredTargetContext(combatEventId, triggerTarget, auraTargetContext)
```

There is no `on_damage_type` branch for `event_other`, so the Aura builder falls back to `auraTargetContext`.

Runtime semantics are:

- `event_source` = damage dealer
- `event_other` = damaged unit

So the generated Aura text can describe the effect as applying to the Aura-bearing target/dealer while runtime applies it to the damaged unit.

Add explicit `on_damage_type` target-context handling in the Aura description/template builder:

- `event_source` -> damage dealer
- `event_other` -> damaged unit
- `aura_target` -> Aura-bearing unit
- `aura_caster` -> Aura caster

Trait wording already handles `event_other` as the other unit.

### Additional review note

Commit `5e72e58` is not isolated to #370. It also includes #369-related condition work, Warrior dataset changes, and `TASK.MD` changes. That is not itself a #370 functional failure, but it expands regression surface.

### Re-verification required

After the blockers are fixed, re-test:

- player -> NPC;
- NPC -> player;
- player -> player;
- no / partial / full absorption;
- matching and non-matching schools;
- Fire DoT tick;
- Aura and Trait `event_source` / `event_other`;
- duplicate suppression.

No CI/workflow result exists for `5e72e58`, so this is a static code-path verification rather than an in-game runtime pass.