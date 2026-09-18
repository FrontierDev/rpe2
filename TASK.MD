## Rev 1 verification — `dev` @ `0b044ee`

Rev 1 fixes two of the three previous blockers and substantially improves the third, but **#370 is still not ready to close** because the new remote-player authority hand-off introduces a combat-state regression.

### Fixed from previous review

#### ✅ Periodic Aura damage now participates

`AuraManager:HandleLocalAuraTickResult()` now emits `on_damage_type` for ordinary damage ticks when:

- `suppressCombatEvents ~= true`;
- `result.applied == true`;
- `appliedDelta < 0`.

The Aura damage effect now also resolves and carries a `damageSchoolRef`.

This fixes the missing DoT/periodic path while preserving recursion suppression for triggered proc damage.

#### ✅ Aura event-target wording now distinguishes source/other

`AuraDescriptionBuilder.resolveTriggeredTargetContext()` now has explicit `on_damage_type` mappings:

- `event_source` -> the damage dealer;
- `event_other` -> the damaged unit.

This fixes the prior mismatch between generated text and runtime targeting.

#### ✅ Remote player path now carries the defender-resolved outcome

The hit-check response now carries:

- authoritative `damageSchoolRef`;
- authoritative `appliedDelta`;
- authoritative `applied` state.

The attacker uses those values when calling `EmitDamageTypeEvent()`, rather than deciding the proc from its own preview result. This addresses the core problem identified in blocker 1.

---

### Remaining blocker — side-effectful authoritative resolution now happens before response send succeeds

In `Client:ResolveCombatReactionAction()`, rev 1 now does:

```lua
local _, resolvedDamageResult = Combat:ApplyResolvedDamage(entry)
```

**before**:

```lua
sendCombatWhisper(attackerName, HIT_CHECK_RESPONSE_OPCODE, responseArguments)
```

This is not a pure calculation.

`ApplyResolvedDamage(entry)` can call `AuraManager:ConsumeAbsorption()`, which mutates live absorption state, increments revisions, queues aura runtime updates, and may remove depleted absorb auras. It also stores `entry.authoritativeDamageResult`.

If the hit-check response send then fails, `ResolveCombatReactionAction()` returns immediately:

```lua
if attackerName == "" or not sendCombatWhisper(...) then
    return false
end
```

and therefore never reaches the normal post-send path that:

- records resolved attack history;
- calls `FinalizeLocalDamageResult()`;
- queues the health resource delta;
- completes the normal combat presentation/bookkeeping.

That leaves a possible state where an absorb shield has already been consumed/removed even though the damage action was not finalized.

This is a regression introduced by the rev-1 authority fix.

### Required correction

Do not obtain the source-side proc result by moving the side-effectful target damage application ahead of the existing response-send success boundary.

Prefer a post-finalization authoritative outcome hand-off, for example:

```text
hit-check response succeeds
    -> defender resolves/finalizes authoritative damage
    -> defender sends authoritative damage outcome to source authority
    -> source authority emits on_damage_type
```

A dedicated post-damage-resolution message is cleaner than overloading the pre-finalization hit-check response.

If the existing protocol can be restructured safely without a second opcode, the same invariant still applies: **no live absorption/resource/threat mutation should be stranded when the response send fails.**

### Static verification status

Aside from that failure-path regression, rev 1 now satisfies the previously identified #370 implementation gaps:

- source-oriented event registration;
- damage-school parameter propagation;
- Aura/Trait schema filtering;
- editor selectors;
- matching/non-matching school handling;
- zero-health-loss guard;
- periodic Aura damage support;
- Aura target wording;
- recursion suppression for triggered effects;
- duplicate guard via `damageTypeEventEmitted`.

No workflow/CI run or commit status exists for `0b044ee`, so this remains static code-path verification rather than an in-game multiplayer pass.

### Re-verification after fix

At minimum exercise:

- player -> player hit with no absorb;
- partial absorb;
- full absorb;
- failed addon-message send / response failure path;
- Fire DoT tick;
- matching vs non-matching school;
- `event_source` and `event_other` targets;
- no duplicate proc.