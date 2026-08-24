## Goal
Audit Tasks 0–12 as one coherent Phase 5 extension and fix **concrete defects only**.

Depends on: #22, #23, #24, #25, #26, #27, #28, #29, #30, #31, #32, #33, #34

Do not start until all preceding Phase 5 tasks are implemented and pushed.

## Required audit
### Stable Guild identity
Verify:
- existing name-keyed Guild state remains accessible/migrates safely;
- new key resolution does not split the current guild's Profile state;
- assignment/Requisition/Daily Reward/Progression nested data survives;
- migration never automatically assigns/remaps/clears an RPE Guild Rank.

### Schema and backward compatibility
Verify:

```text
Dataset schema 16 -> 17
Profile schema 6 -> 7
```

Test at minimum:
- old Achievement with original triggers only;
- old Achievement with opaque/unknown `rewards` entries;
- old completed Achievement Profile state;
- old incomplete Achievement Profile state;
- existing Guild Profile state.

Confirm:
- criterion progress is preserved;
- `completedAt` is preserved;
- existing completed Achievements do not re-announce;
- existing completed Achievements do not receive automatic retroactive rewards;
- unsupported reward data survives Dataset round-trip;
- future higher schema markers are not lowered.

### Trigger index and configuration rebuild
Verify indexed support for:

```text
manual
currency_gain
item_gain
skill_gain
rpe_kill
rpe_boss_kill
rpe_damage
rpe_healing
rpe_event_started
rpe_event_complete
achievement_earned
```

Configuration/index rebuild itself must never mutate progress.

### `item_gain` smoke matrix
Verify:

```text
Inventory.AddItem -> counts
stack merge -> actual quantity exactly once
Requisition item -> counts
Daily Reward item -> counts
Guild Admin Give Item -> counts
Achievement Item reward -> counts
Inventory load -> no count
SetItems/state replacement -> no count
RemoveItem -> no count
```

### `skill_gain` smoke matrix
Verify:

```text
positive increase -> actual persisted delta counts
decrease -> no count
same value -> no count
Guild Admin increase -> counts
Guild Admin decrease -> no count
Profile load/normalization -> no count
```

### Event-start smoke matrix
Verify:

```text
authoritative accepted Event start -> one count
duplicate/replayed same Event instance -> no second count
Event Manager/UI preview -> no count
rpe_event_complete remains separate and unchanged
```

### Damage/healing smoke matrix
Verify:

```text
committed health damage -> actual health lost
committed healing -> actual health restored
overkill -> only actual health lost
overheal -> only actual health restored
non-health Resource -> no count
preview/uncommitted effect -> no count
other player's action -> no local credit
single/batch Resource Delta -> no duplicate
```

### Boss-kill smoke matrix
Verify:

```text
boss kill -> rpe_kill + rpe_boss_kill
ordinary kill -> rpe_kill only
already-dead update -> neither repeats
boss=false -> no boss trigger
```

Confirm boss state comes from EventUnit state and kill ownership remains transport-bound.

### Achievement Reward authoring/dependencies
Verify:
- Item reward authoring/export/import;
- built-in Currency reward authoring/export/import;
- dataset Currency reward authoring/export/import;
- stable reward IDs;
- unsupported legacy reward preservation;
- Item/Currency dependency extraction;
- built-in Currency exclusion from Dataset dependencies.

### Reward transaction smoke matrix
Verify:

```text
single Item reward
single built-in Currency reward
single dataset Currency reward
multiple mixed supported rewards
currency cap behavior
Achievement Item reward -> item_gain
Achievement Currency reward -> currency_gain
prevalidation failure -> no mutation
mid-transaction failure + verified full rollback -> safe failed
rollback failure/unverifiable rollback -> recovery-required
/reload after complete -> no duplicate
/reload/relog with in-progress -> no blind replay
explicit safe retry -> no reannouncement/recompletion
Guild Admin Achievement Grant -> normal reward path
legacy completed Achievement -> no automatic retroactive reward
unsupported reward entry -> not executed accidentally
```

### Profile Achievement UI
Verify:
- supported rewards display;
- Item/Currency labels resolve with safe fallback;
- pending/complete/failed/recovery/legacy state is clear;
- ordinary page view/refresh is read-only;
- only safe failed state permits retry;
- existing tags/progress/completion date remain functional.

### Load order and explicit integration maps
Review `RPEngine_Dev.toc`, Runtime hooks/listeners, Data Editor maps, Registry/dependency paths and Profile modules.

Verify:
- classes load before normalization/instantiation;
- Profile Achievement APIs load before runtime/UI consumers;
- Inventory/Skill listeners attach only after providers exist;
- any new reward runtime loads before callers require it;
- Data Editor inspector integration is complete;
- no duplicated event frame/runtime exists.

### Non-goal / duplicate-system audit
Ensure Phase 5 did **not** introduce:

```text
Bestiary
Quest Log
offline Guild Admin
account-wide Achievement aggregation
arbitrary executable Lua criteria/rewards
automatic RPE Guild Rank assignment/remap/clear
RPE Guild Rank hierarchy/inheritance
multiple simultaneous assigned RPE Guild Ranks
second Achievement runtime
second Inventory store
second Currency store
second Event authority path
second Guild Admin protocol
new SavedVariable root
preview-state combat Achievement credit
mail/offline reward delivery
```

## Definition of done
- [ ] Stable Guild identity discrepancy is resolved safely.
- [ ] Six deferred Achievement triggers are implemented and authorable.
- [ ] Gain/combat/event triggers use canonical authoritative committed state.
- [ ] Item/Skill gain uses actual applied positive deltas.
- [ ] Damage/Healing uses actual committed health deltas.
- [ ] Boss kill is additive to ordinary kill and exactly-once.
- [ ] Event start is idempotent per Event instance.
- [ ] Structured Item/Currency rewards are authorable and dependency-aware.
- [ ] Reward delivery is persistent and idempotent.
- [ ] Unsafe reward recovery cannot blindly replay/duplicate rewards.
- [ ] Existing completed Achievements do not re-announce or receive automatic retroactive rewards.
- [ ] Existing Guild Rank/Requisition/Daily Reward/Admin/Progression behavior remains intact.
- [ ] Dataset/Profile migrations, export/import, dependencies and TOC load order remain coherent.

## Coding-agent instructions
Treat current `FrontierDev/rpe2`, `RPE2-Achievements-Guild-Systems-PDD.md`, the Phase 5 implementation plan, and completed issues #22–#34 as authoritative. Inspect the actual final repository rather than assuming earlier task reports are correct. Execute every smoke matrix above, search explicit maps/load-order paths, and fix concrete Phase 5 defects only. Do not redesign working systems or expand into non-goals. Before marking complete, report the audit performed, files changed, validation results, and any unresolved deviation.