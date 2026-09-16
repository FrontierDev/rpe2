## Summary

Review and complete the **partial descriptor templates** used to generate spell tooltip text so every supported spell targeter/effect type has accurate player-facing wording.

This issue is specifically about the composable tooltip fragments used by `client/spellcasting/DescriptionBuilder.lua`, e.g.:

```text
Deal {damage information} {damage school} damage to {target information}.
Heal {target information} for {healing information} health.
Apply {aura} to {target information}.
```

It is **not** a general tooltip architecture rewrite.

## Current gaps

### Target descriptors

`resolveTargetPhrase()` currently has special handling for `caster`, `pet`, and `last_attackers`, with ordinary `single`/`multi` targets falling through to disposition/count wording.

The new targeters being added need explicit descriptor behaviour where their semantics differ from ordinary `single`/`multi` targeting.

#### `all_allies`

New targeter.

Use:

```text
all allies
```

Examples:

```text
Heal all allies for {amount} health.
Apply {Aura} to all allies.
```

Do not render this as `up to N allies`.

#### `raid_marker`

New targeter.

The main target phrase should deliberately use the normal multi-target wording:

```text
up to {N} allies
up to {N} enemies
up to {N} targets
```

Do **not** mention the raid marker inside the main effect sentence.

Instead, add a separate grey informational line at the bottom of the spell tooltip:

```text
Targets must share the same raid marker.
```

This should appear once per spell where a raid-marker targeter is used, not once per component sentence.

#### last melee attacker targeter

The planned targeter for "the unit that last attacked the caster with a melee attack" needs dedicated wording matching its actual semantics.

Use:

```text
the last enemy to attack you with a melee attack
```

Do not reuse the existing vague `last_attackers` phrase `the last attacker of the target` for this targeter.

## Spell effect descriptors

### Existing `remove_aura`

`remove_aura` is already an executable/editor-supported spell effect but is missing from the spell description dispatcher.

Add player-facing templates that include aura name, stack count when relevant, and target phrase.

Examples:

```text
Remove {Aura} from {target}.
Remove {N} stacks of {Aura} from {target}.
```

### Existing `hide`

`hide` is already supported by the spell runtime/editor but has no spell tooltip descriptor.

Use player-facing wording such as:

```text
Cause {target} to become hidden.
```

Do not expose implementation terminology such as "set hidden status" in the normal tooltip.

### New `remove_aura_by_tag`

Add the new effect type for removing auras by one or more authored tags and add its tooltip descriptor at the same time.

The descriptor must use:

```text
Remove all {tag, tag, tag, tag} effect(s) from {target}.
```

Requirements:

- render the complete authored tag list in the effect sentence;
- preserve authored tag names;
- comma-separate multiple tags;
- use the normal resolved target phrase for `{target}`;
- the effect operates on all matching aura effects, rather than naming a specific aura reference.

If the implementation also supports an optional maximum number of removals, extend the descriptor consistently rather than silently omitting that limit.

### Existing `revert`

`revert` already has a descriptor:

```text
Reverse the effects of the last spell that affected {target}.
```

Retain this unless the runtime semantics change.

## Aura-event descriptor gaps

### Existing `remove_hidden`

`remove_hidden` is already supported as an aura event effect but is not handled by the aura-event description builder.

Use player-facing wording based on the resolved event target, e.g.:

```text
reveal {target}
```

rather than `remove hidden`.

## Passive aura descriptor gaps

### Existing passive `apply_aura`

The aura schema/editor permits passive `apply_aura` effects, but the passive aura description dispatcher does not currently emit text for them.

Add the equivalent aura application descriptor so authorable passive effects are not silently omitted from generated aura text.

## Effect/target types covered by this work

### New target types

- `all_allies`
- `raid_marker`
- dedicated targeter for the unit that last attacked the caster with a melee attack

### New spell effect types

- `remove_aura_by_tag`

### Existing types whose descriptor coverage must be completed/fixed

- target: `last_attackers` / replacement dedicated last-melee-attacker semantics
- spell effect: `remove_aura`
- spell effect: `hide`
- spell effect: `revert` — verify existing text remains correct
- aura event effect: `remove_hidden`
- passive aura effect: `apply_aura`

## Implementation guidance

Keep the implementation centred on the existing descriptor composition in `client/spellcasting/DescriptionBuilder.lua` and `client/spellcasting/AuraDescriptionBuilder.lua`.

The main spell sentence should continue to be assembled from an effect descriptor plus a resolved target phrase. Special targeting constraints that do not belong grammatically inside the sentence, such as `raid_marker`, should be emitted as supplementary grey tooltip lines.

Avoid introducing spell-specific hard-coded descriptions. The templates must remain generic and data-driven.

## Acceptance criteria

- Every target/effect type listed above produces complete generated tooltip text.
- `all_allies` renders as `all allies`.
- `raid_marker` renders the ordinary `up to N allies/enemies/targets` main phrase plus exactly one grey `Targets must share the same raid marker.` line.
- the last-melee-attacker targeter describes the caster's last melee attacker, not `the last attacker of the target`.
- `remove_aura` no longer disappears from generated spell descriptions.
- `hide` no longer disappears from generated spell descriptions.
- `remove_aura_by_tag` renders `Remove all {tags} effect(s) from {target}.` with the authored tag list.
- `remove_hidden` is represented in aura-event descriptions with player-facing `reveal` wording.
- passive aura `apply_aura` effects are represented rather than omitted.
- existing damage/heal/resource/apply-aura/interrupt/revert/summon-pet descriptors continue to generate normally.