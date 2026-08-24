## Goal
Replace the current read-only Achievement Rewards summary with editing support for supported Item/Currency reward records while preserving unsupported legacy reward data.

Depends on: #30

## Primary files
- `client/ui/editor/inspectors/page_InspectorAchievement.lua`
- adjacent Data Editor list/repeater helpers only if they match current architecture

## Reward editor
Support authoring for:

```text
Add Reward
Delete Reward
Reward ID
Reward Type: Item | Currency
Reference
Amount
```

Use the normalized reward contract from #30. Reward IDs must remain stable during unrelated edits.

## Reference semantics
Item reward:

```text
datasetId:itemId
```

Currency reward:

```text
copper
valor
justice
honor
conquest
datasetId:currencyId
```

Follow existing Data Editor conventions for unresolved references. A warning/display fallback is acceptable; do not build a new global reference-validation framework solely for this task.

## Unsupported legacy records
Unknown reward records/types preserved by #30 must not be silently rewritten as supported Item/Currency rewards.

Expose them as preserved/unsupported where practical, or otherwise ensure ordinary edits to supported records cannot delete them.

## Persistence/normalization
Commit through the existing Achievement normalization/Data Editor change-notification path. Do not create an editor-only reward schema.

## Constraints
- Editing rewards must never execute rewards.
- Do not modify Profile reward-delivery state.
- Do not implement reward runtime.
- Preserve existing General/Criteria pages and stable criterion IDs.
- Preserve unsupported legacy reward data.

## Acceptance criteria
- [ ] Item rewards can be authored.
- [ ] Built-in Currency rewards can be authored.
- [ ] Dataset Currency rewards can be authored.
- [ ] Amount normalizes to a positive integer.
- [ ] Reward IDs remain stable across unrelated edits.
- [ ] Multiple supported rewards survive export/import.
- [ ] Unsupported legacy reward records survive unrelated edits/export/import.
- [ ] Editing a reward never grants it.
- [ ] Existing Achievement General/Criteria editor behavior remains functional.

## Coding-agent instructions
Read issue #30 and inspect the current Achievement Rewards summary, inspector page architecture, nested list editors, commit/normalization flow and export/import behavior before editing. Implement Task 9 only. Use the canonical Achievement reward schema and preserve unknown reward records; do not add runtime execution or a separate editor framework. Review every acceptance criterion and report changed files, validation performed, and deviations.