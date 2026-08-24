## Goal
Advance `rpe_damage` and `rpe_healing` criteria from actual committed health changes attributed to the authoritative local action owner.

Depends on: #23, #24

## Primary files
- `client/client_Resources.lua`
- `client/client_Achievements.lua`
- existing Resource/EventUnit helpers already used by authoritative kill detection

## Authoritative source
Use the same committed inbound Resource processing boundary already used for `rpe_kill`:

```text
RESOURCE_DELTA
RESOURCE_DELTA_BATCH
```

Do not trigger from:
- spell tooltip estimates;
- spell-component preview;
- locally predicted effect amounts;
- outbound/requested values before committed state arrives.

## Health identification
Inspect the current Resource/death helpers and reuse the repository's canonical health Resource semantics. Do not hard-code a parallel health identifier if a resolver/helper already exists.

For the committed health value:

```text
actualDamage  = max(0, previousHealth - updatedHealth)
actualHealing = max(0, updatedHealth - previousHealth)
```

This must naturally limit progress to the amount actually applied, excluding overkill/overheal beyond the committed state transition.

## Ownership/security
Reuse the transport-bound action-owner rule already established for `rpe_kill`.

Do not trust a payload actor field unless it matches the authoritative transport/action context used by the current resource protocol.

Only credit the local player's own Achievement Profile for actions authoritatively attributed to that player.

## Trigger context
Conceptually:

```lua
{
    unitRef = "dataset:unit",
    amount = actualAppliedAmount,
    isEnemy = true,
    actionOwnerName = trustedActor,
    authoritative = true,
}
```

## Filters
Apply optional:
- exact `unitRef`;
- `enemyOnly` where configured.

Determine enemy/friendly status from the same Event/team semantics already used by `rpe_kill`; do not invent name-based allegiance logic.

## Single/batch parity
Single and batched Resource Delta handlers must produce equivalent Achievement semantics and must not both count the same committed state change.

## Constraints
- Preserve existing Resource synchronization behavior.
- Preserve exactly-once `rpe_kill` alive->dead behavior.
- Do not change server combat calculation merely to expose an Achievement hook.
- Do not implement boss-specific semantics in this task.

## Acceptance criteria
- [ ] Committed health loss advances `rpe_damage` by actual loss.
- [ ] Committed health gain advances `rpe_healing` by actual restoration.
- [ ] Overkill/overheal cannot inflate progress beyond committed health change.
- [ ] Non-health Resource changes do not count.
- [ ] Preview/uncommitted effects do not count.
- [ ] Another player's action cannot credit the local Profile.
- [ ] `unitRef` and `enemyOnly` filters work.
- [ ] Single/batch paths do not double-count one committed delta.
- [ ] Existing `rpe_kill` remains exactly once per authoritative alive->dead transition.

## Coding-agent instructions
Read the PDD and completed issues #23–#24, then inspect the current authoritative Resource Delta single/batch handlers, health/death detection, EventUnit/team resolution, and transport-bound kill ownership before editing. Implement Task 6 only. Derive progress from before/after committed health state, not requested or preview values. Preserve Resource protocol behavior and kill semantics. Review every acceptance criterion and report changed files, validation performed, and deviations.