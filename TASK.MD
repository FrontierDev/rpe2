## Goal
Add the six PDD-deferred Achievement trigger tokens to the normalized Achievement model and runtime trigger-index contract without implementing their actual event hooks yet.

Depends on: #22

## Primary files
- `core/classes/Achievement.lua`
- `client/client_Achievements.lua`
- `core/internal/database/Dependecies.lua`
- `core/internal/Registry.lua` only if an existing resolver needs a narrow helper

## Trigger additions
Add support for:

```text
item_gain
skill_gain
rpe_boss_kill
rpe_damage
rpe_healing
rpe_event_started
```

Preserve the existing trigger values unchanged:

```text
manual
currency_gain
rpe_kill
rpe_event_complete
achievement_earned
```

## Supported filter contract
Formally support these optional filter keys:

```text
item_gain
  itemRef

skill_gain
  skillRef

rpe_boss_kill
  unitRef
  enemyOnly

rpe_damage
  unitRef
  enemyOnly

rpe_healing
  unitRef
  enemyOnly

rpe_event_started
  eventId
```

Treat filters as data comparisons only. Do not make arbitrary filter strings executable.

Unknown/future filter keys must survive unrelated normalization/editing.

## Trigger index
Extend the current indexed Achievement runtime (`CriteriaByTrigger` or equivalent) so criteria using the new trigger tokens are indexed correctly.

Do **not** wire Inventory, Skill, Event or Resource runtime events in this task.

## Dependency extraction
Extend known-reference extraction for:
- `filters.itemRef` -> Item dependency;
- `filters.skillRef` -> Skill dependency;
- `filters.unitRef` -> Unit dependency.

Do not automatically treat `eventId` as a Dataset dependency unless current Event definitions use dataset-qualified references and the existing dependency system already provides that semantic contract.

Preserve current dependency behavior for `currencyRef` and `achievementRef`.

## Constraints
- Preserve stable criterion IDs.
- Do not change Achievement completion semantics.
- Do not change Profile Achievement state.
- Do not introduce new runtime listeners/event frames.
- Do not implement Achievement Rewards yet.
- Preserve unknown filter fields rather than destructively constraining the table.

## Acceptance criteria
- [ ] All six new trigger tokens normalize and round-trip.
- [ ] Existing trigger tokens remain unchanged.
- [ ] Existing stable criterion IDs remain stable.
- [ ] New supported filters normalize without deleting unknown filter data.
- [ ] New qualified-reference filter fields participate in dependency extraction.
- [ ] The runtime trigger index accepts/indexes all six new trigger keys.
- [ ] No item/skill/event/combat progress is emitted in this task.

## Coding-agent instructions
Read `RPE2-Achievements-Guild-Systems-PDD.md` and inspect the current `Achievement.lua`, Achievement trigger-index construction, criterion filter matching, Registry resolvers and dependency extraction before editing. Implement Task 1 only. Do not add speculative runtime hooks: this task defines and indexes the contract only. Preserve unknown data and stable IDs. When finished, review every acceptance criterion and report changed files, validation performed, and any deviation.