## Summary

The default Paladin dataset's **Light of the Protector** spell has incorrect caster/target trigger semantics.

Target branch: `dev`.

## Current definition

The spell is defined in:

- `data/default/classes/paladin.lua`
- spell id: `x2qgj4wy`
- name: `Light of the Protector`

Its authored tooltip describes a self-heal: `Heal yourself for {HEAL_1} health.` The runtime target/trigger metadata must therefore be consistent with a caster/self heal rather than resolving the effect against an unrelated selected target or the wrong event participant.

## Required work

Inspect the complete spell component and its generated/authored caster/target trigger fields and correct them using the existing canonical self-target/self-heal spell conventions in the Core/default datasets.

Verify both:

1. **Targeting policy** — whether the spell requires/selects a target and which event unit becomes the component target.
2. **Effect/condition trigger context** — which unit is exposed as caster/source/target when resolving the heal and any conditions/scaling.

Do not patch the tooltip to match incorrect runtime behavior. The intended behavior is the self-heal described by the spell.

Because this is a packaged default dataset, increment the Paladin dataset package `version` so existing installations receive the corrected definition through the normal default-dataset synchronization path.

## Acceptance criteria

1. Light of the Protector always heals the casting event unit.
2. It does not heal an arbitrary selected ally/enemy because of incorrect target metadata.
3. It does not require an external target unless another intentional mechanic explicitly requires one.
4. Caster/source/target context used for conditions and stat scaling is the same as other canonical self-heal spells.
5. Tooltip text and actual runtime behavior agree.
6. The corrected spell works for both player-controlled and host-controlled event units where applicable.
7. The Paladin packaged dataset version is incremented so existing users receive the correction.
8. Add or extend a deterministic spell-resolution test covering the self-heal target identity.